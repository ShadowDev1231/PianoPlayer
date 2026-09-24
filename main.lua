--!strict

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DEFAULT_KEY_DELAY = 0.05

local GITHUB_SONGS_URL =
	"https://api.github.com/repos/ShadowDev1231/PianoPlayer/contents/songs?ref=main"

local PIANO_MODULE_URL =
	"https://raw.githubusercontent.com/ShadowDev1231/PianoPlayer/refs/heads/main/PianoModule.lua"

--==================================================
-- HTTP
--==================================================

local function getRequestFunction()
	return (typeof(request) == "function" and request)
		or (typeof(http_request) == "function" and http_request)
		or (syn and syn.request)
		or (http and http.request)
end

local function httpGet(url: string): string
	local requestFunction = getRequestFunction()

	if not requestFunction then
		error("No supported HTTP request function was found.")
	end

	local response = requestFunction({
		Url = url,
		Method = "GET"
	})

	if not response then
		error("HTTP request returned no response.")
	end

	if response.StatusCode and response.StatusCode ~= 200 then
		error(
			"HTTP "
				.. tostring(response.StatusCode)
				.. " while requesting "
				.. url
		)
	end

	local body = response.Body

	if type(body) ~= "string" or body == "" then
		error("HTTP request returned an empty response.")
	end

	return body
end

--==================================================
-- Piano Module
--==================================================

local PianoPlayer = nil

local function loadPianoModule()
	local source = httpGet(PIANO_MODULE_URL)

	local compiled, compileError = loadstring(source)

	if not compiled then
		error(
			"Failed to compile PianoModule.lua: "
				.. tostring(compileError)
		)
	end

	local success, module = pcall(compiled)

	if not success then
		error(
			"Failed to execute PianoModule.lua: "
				.. tostring(module)
		)
	end

	if type(module) ~= "table" then
		error("PianoModule.lua did not return a table.")
	end

	if type(module.playKey) ~= "function" then
		error("PianoModule.lua does not contain playKey().")
	end

	return module
end

do
	local success, result = pcall(loadPianoModule)

	if success then
		PianoPlayer = result
	else
		warn("PianoPlayer:", result)
	end
end

--==================================================
-- State
--==================================================

local isPlaying = false
local stopRequested = false
local playbackThread: thread? = nil
local playbackId = 0

local songs: {Song} = {}
local selectedCategory = "All"

--==================================================
-- Song type
--==================================================

type Song = {
	Name: string?,
	Category: string?,
	Type: string?,

	playKey: ((self: any, key: string, keyDelay: number?) -> ())?,
	play: ((self: any, piano: any) -> ())?,
	Play: ((self: any, piano: any) -> ())?,

	Keys: string?,
	KeyDelay: number?
}

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SongUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = playerGui

--==================================================
-- Main glass window
--==================================================

local Frame = Instance.new("Frame")
Frame.Name = "Frame"
Frame.Size = UDim2.fromScale(0.58, 0.68)
Frame.Position = UDim2.fromScale(0.21, 0.16)
Frame.BackgroundColor3 = Color3.fromRGB(15, 19, 29)
Frame.BackgroundTransparency = 0.08
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 20)
FrameCorner.Parent = Frame

local FrameGradient = Instance.new("UIGradient")
FrameGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(
		0,
		Color3.fromRGB(40, 48, 70)
	),

	ColorSequenceKeypoint.new(
		0.5,
		Color3.fromRGB(22, 27, 42)
	),

	ColorSequenceKeypoint.new(
		1,
		Color3.fromRGB(12, 16, 25)
	)
})
FrameGradient.Rotation = 135
FrameGradient.Parent = Frame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color = Color3.fromRGB(155, 180, 255)
FrameStroke.Transparency = 0.72
FrameStroke.Thickness = 1.3
FrameStroke.Parent = Frame

--==================================================
-- Shadow
--==================================================

local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 18, 1, 18)
Shadow.Position = UDim2.new(0, -9, 0, 10)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.6
Shadow.BorderSizePixel = 0
Shadow.ZIndex = 0
Shadow.Parent = Frame

local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 23)
ShadowCorner.Parent = Shadow

--==================================================
-- TOP MUSIC PLAYER
--==================================================

local PlayerBar = Instance.new("Frame")
PlayerBar.Name = "MusicPlayer"
PlayerBar.Size = UDim2.new(1, -24, 0, 78)
PlayerBar.Position = UDim2.new(0, 12, 0, 12)
PlayerBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PlayerBar.BackgroundTransparency = 0.91
PlayerBar.BorderSizePixel = 0
PlayerBar.Parent = Frame

local PlayerCorner = Instance.new("UICorner")
PlayerCorner.CornerRadius = UDim.new(0, 15)
PlayerCorner.Parent = PlayerBar

local PlayerStroke = Instance.new("UIStroke")
PlayerStroke.Color = Color3.fromRGB(255, 255, 255)
PlayerStroke.Transparency = 0.88
PlayerStroke.Parent = PlayerBar

-- Piano icon
local PianoIcon = Instance.new("TextLabel")
PianoIcon.Name = "PianoIcon"
PianoIcon.Size = UDim2.fromOffset(42, 42)
PianoIcon.Position = UDim2.new(0, 12, 0.5, -21)
PianoIcon.BackgroundColor3 = Color3.fromRGB(105, 135, 220)
PianoIcon.BackgroundTransparency = 0.2
PianoIcon.BorderSizePixel = 0
PianoIcon.Text = "♫"
PianoIcon.TextColor3 = Color3.fromRGB(240, 245, 255)
PianoIcon.TextSize = 22
PianoIcon.Font = Enum.Font.GothamBold
PianoIcon.Parent = PlayerBar

local PianoIconCorner = Instance.new("UICorner")
PianoIconCorner.CornerRadius = UDim.new(0, 11)
PianoIconCorner.Parent = PianoIcon

local PlayerTitle = Instance.new("TextLabel")
PlayerTitle.Name = "PlayerTitle"
PlayerTitle.Size = UDim2.new(0.45, 0, 0, 25)
PlayerTitle.Position = UDim2.new(0, 66, 0, 14)
PlayerTitle.BackgroundTransparency = 1
PlayerTitle.Text = "PIANO PLAYER"
PlayerTitle.TextColor3 = Color3.fromRGB(240, 244, 255)
PlayerTitle.TextSize = 14
PlayerTitle.Font = Enum.Font.GothamBold
PlayerTitle.TextXAlignment = Enum.TextXAlignment.Left
PlayerTitle.Parent = PlayerBar

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(0.45, 0, 0, 23)
StatusLabel.Position = UDim2.new(0, 66, 0, 38)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready"
StatusLabel.TextColor3 = Color3.fromRGB(160, 170, 195)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Parent = PlayerBar

--==================================================
-- STOP
--==================================================

local StopButton = Instance.new("TextButton")
StopButton.Name = "StopButton"
StopButton.Size = UDim2.fromOffset(72, 34)
StopButton.Position = UDim2.new(1, -162, 0.5, -17)
StopButton.BackgroundColor3 = Color3.fromRGB(225, 75, 100)
StopButton.BackgroundTransparency = 0.12
StopButton.BorderSizePixel = 0
StopButton.Text = "STOP"
StopButton.TextColor3 = Color3.fromRGB(255, 235, 240)
StopButton.TextSize = 11
StopButton.Font = Enum.Font.GothamBold
StopButton.AutoButtonColor = false
StopButton.Parent = PlayerBar

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 9)
StopCorner.Parent = StopButton

--==================================================
-- REFRESH
--==================================================

local RefreshButton = Instance.new("TextButton")
RefreshButton.Name = "RefreshButton"
RefreshButton.Size = UDim2.fromOffset(82, 34)
RefreshButton.Position = UDim2.new(1, -80, 0.5, -17)
RefreshButton.BackgroundColor3 = Color3.fromRGB(100, 135, 220)
RefreshButton.BackgroundTransparency = 0.12
RefreshButton.BorderSizePixel = 0
RefreshButton.Text = "REFRESH"
RefreshButton.TextColor3 = Color3.fromRGB(235, 242, 255)
RefreshButton.TextSize = 10
RefreshButton.Font = Enum.Font.GothamBold
RefreshButton.AutoButtonColor = false
RefreshButton.Parent = PlayerBar

local RefreshCorner = Instance.new("UICorner")
RefreshCorner.CornerRadius = UDim.new(0, 9)
RefreshCorner.Parent = RefreshButton

--==================================================
-- CLOSE
--==================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.fromOffset(30, 30)
CloseButton.Position = UDim2.new(1, -40, 0, -2)
CloseButton.BackgroundColor3 = Color3.fromRGB(230, 75, 100)
CloseButton.BackgroundTransparency = 0.1
CloseButton.BorderSizePixel = 0
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 240, 245)
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.AutoButtonColor = false
CloseButton.ZIndex = 20
CloseButton.Parent = Frame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 9)
CloseCorner.Parent = CloseButton

--==================================================
-- CATEGORY PANEL
--==================================================

local CategoryPanel = Instance.new("ScrollingFrame")
CategoryPanel.Name = "Categories"
CategoryPanel.Size = UDim2.new(0.28, -8, 1, -106)
CategoryPanel.Position = UDim2.new(0, 12, 0, 102)
CategoryPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CategoryPanel.BackgroundTransparency = 0.94
CategoryPanel.BorderSizePixel = 0
CategoryPanel.ScrollBarThickness = 3
CategoryPanel.ScrollBarImageColor3 = Color3.fromRGB(120, 150, 220)
CategoryPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
CategoryPanel.ScrollingDirection = Enum.ScrollingDirection.Y
CategoryPanel.Parent = Frame

local CategoryCorner = Instance.new("UICorner")
CategoryCorner.CornerRadius = UDim.new(0, 14)
CategoryCorner.Parent = CategoryPanel

local CategoryStroke = Instance.new("UIStroke")
CategoryStroke.Color = Color3.fromRGB(255, 255, 255)
CategoryStroke.Transparency = 0.9
CategoryStroke.Parent = CategoryPanel

local CategoryPadding = Instance.new("UIPadding")
CategoryPadding.PaddingTop = UDim.new(0, 9)
CategoryPadding.PaddingBottom = UDim.new(0, 9)
CategoryPadding.PaddingLeft = UDim.new(0, 8)
CategoryPadding.PaddingRight = UDim.new(0, 8)
CategoryPadding.Parent = CategoryPanel

local CategoryLayout = Instance.new("UIListLayout")
CategoryLayout.Padding = UDim.new(0, 6)
CategoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
CategoryLayout.Parent = CategoryPanel

--==================================================
-- SONG PANEL
--==================================================

local SongPanel = Instance.new("ScrollingFrame")
SongPanel.Name = "Songs"
SongPanel.Size = UDim2.new(0.72, -20, 1, -106)
SongPanel.Position = UDim2.new(0.28, 8, 0, 102)
SongPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SongPanel.BackgroundTransparency = 0.94
SongPanel.BorderSizePixel = 0
SongPanel.ScrollBarThickness = 3
SongPanel.ScrollBarImageColor3 = Color3.fromRGB(120, 150, 220)
SongPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
SongPanel.ScrollingDirection = Enum.ScrollingDirection.Y
SongPanel.Parent = Frame

local SongCorner = Instance.new("UICorner")
SongCorner.CornerRadius = UDim.new(0, 14)
SongCorner.Parent = SongPanel

local SongStroke = Instance.new("UIStroke")
SongStroke.Color = Color3.fromRGB(255, 255, 255)
SongStroke.Transparency = 0.9
SongStroke.Parent = SongPanel

local SongPadding = Instance.new("UIPadding")
SongPadding.PaddingTop = UDim.new(0, 9)
SongPadding.PaddingBottom = UDim.new(0, 9)
SongPadding.PaddingLeft = UDim.new(0, 9)
SongPadding.PaddingRight = UDim.new(0, 9)
SongPadding.Parent = SongPanel

local SongLayout = Instance.new("UIListLayout")
SongLayout.Padding = UDim.new(0, 7)
SongLayout.SortOrder = Enum.SortOrder.LayoutOrder
SongLayout.Parent = SongPanel

--==================================================
-- Helpers
--==================================================

local function setStatus(text: string)
	StatusLabel.Text = text
end

local function clearContainer(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout")
			and not child:IsA("UIPadding")
			and not child:IsA("UIStroke")
			and not child:IsA("UICorner") then

			child:Destroy()
		end
	end
end

local function getFileName(path: string): string
	local name = path:match("([^\\/]+)$") or path
	return name:gsub("%.lua$", "")
end

local function loadSongSource(
	source: string,
	displayName: string
): (Song?, string?)

	if source == "" then
		return nil, "Song file is empty: " .. displayName
	end

	local compiled, compileError = loadstring(source)

	if not compiled then
		return nil,
			"Compile error in "
				.. displayName
				.. ": "
				.. tostring(compileError)
	end

	local success, result = pcall(compiled)

	if not success then
		return nil,
			"Runtime error in "
				.. displayName
				.. ": "
				.. tostring(result)
	end

	if type(result) ~= "table" then
		return nil, "Song must return a table: " .. displayName
	end

	return result :: Song, nil
end

--==================================================
-- STOP SONG
--==================================================

local function stopSong()
	if not isPlaying and not playbackThread then
		setStatus("Ready")
		return
	end

	stopRequested = true
	playbackId += 1

	local currentThread = playbackThread

	if currentThread then
		pcall(function()
			task.cancel(currentThread)
		end)
	end

	playbackThread = nil
	isPlaying = false
	stopRequested = false

	setStatus("Stopped")
end

--==================================================
-- PLAY SONG
--==================================================

local function playSong(song: Song, fallbackName: string)
	if not PianoPlayer then
		setStatus("PianoModule unavailable")
		return
	end

	if isPlaying or playbackThread then
		stopSong()
		task.wait()
	end

	local songName = song.Name or fallbackName

	playbackId += 1
	local currentPlaybackId = playbackId

	isPlaying = true
	stopRequested = false

	setStatus("Playing: " .. songName)

	local function playback()
		local success, errorMessage = pcall(function()

			local playFunction = song.play or song.Play

			if type(playFunction) == "function" then
				playFunction(song, PianoPlayer)
				return
			end

			if type(song.Keys) == "string" then
				local keyDelay = song.KeyDelay or DEFAULT_KEY_DELAY
				local keys = song.Keys:gsub("%s+", "")

				for index = 1, #keys do
					if stopRequested
						or currentPlaybackId ~= playbackId then
						return
					end

					PianoPlayer:playKey(
						keys:sub(index, index),
						keyDelay
					)
				end

				return
			end

			error(
				"Song has no play()/Play() function or Keys string: "
					.. songName
			)
		end)

		if currentPlaybackId ~= playbackId then
			return
		end

		if not success then
			warn("PianoPlayer song error:", errorMessage)
			setStatus("Error: " .. songName)
		elseif stopRequested then
			setStatus("Stopped: " .. songName)
		else
			setStatus("Finished: " .. songName)
		end

		isPlaying = false
		stopRequested = false
		playbackThread = nil
	end

	playbackThread = task.spawn(playback)
end

--==================================================
-- SONG CATEGORY
--==================================================

local function getSongCategory(song: Song): string
	if type(song.Category) == "string"
		and song.Category ~= "" then
		return song.Category
	end

	if type(song.Type) == "string"
		and song.Type ~= "" then
		return song.Type
	end

	return "Other"
end

--==================================================
-- CATEGORY BUTTON
--==================================================

local function createCategoryButton(
	category: string,
	layoutOrder: number
)

	local button = Instance.new("TextButton")
	button.Name = category
	button.Size = UDim2.new(1, 0, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundTransparency = 0.93
	button.BorderSizePixel = 0
	button.Text = category
	button.TextColor3 = Color3.fromRGB(195, 205, 225)
	button.TextSize = 12
	button.Font = Enum.Font.GothamMedium
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.AutoButtonColor = false
	button.LayoutOrder = layoutOrder
	button.Parent = CategoryPanel

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.Parent = button

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button

	button.Activated:Connect(function()
		selectedCategory = category

		for _, child in ipairs(CategoryPanel:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundTransparency = 0.93
				child.TextColor3 =
					Color3.fromRGB(195, 205, 225)
			end
		end

		button.BackgroundTransparency = 0.78
		button.TextColor3 =
			Color3.fromRGB(235, 242, 255)

		-- Refresh visible songs.
		clearContainer(SongPanel)

		local visibleCount = 0

		for _, songData in ipairs(songs) do
			local songCategory =
				getSongCategory(songData)

			if category == "All"
				or songCategory == category then

				visibleCount += 1

				local songButton = Instance.new("TextButton")
				songButton.Name =
					songData.Name or "Song"

				songButton.Size =
					UDim2.new(1, 0, 0, 46)

				songButton.BackgroundColor3 =
					Color3.fromRGB(255, 255, 255)

				songButton.BackgroundTransparency = 0.91
				songButton.BorderSizePixel = 0

				songButton.Text =
					"  "
						.. (songData.Name or "Unnamed Song")

				songButton.TextColor3 =
					Color3.fromRGB(220, 228, 245)

				songButton.TextSize = 12
				songButton.Font = Enum.Font.GothamMedium
				songButton.TextXAlignment =
					Enum.TextXAlignment.Left

				songButton.AutoButtonColor = false
				songButton.LayoutOrder = visibleCount
				songButton.Parent = SongPanel

				local songCorner = Instance.new("UICorner")
				songCorner.CornerRadius = UDim.new(0, 10)
				songCorner.Parent = songButton

				local songStroke = Instance.new("UIStroke")
				songStroke.Color =
					Color3.fromRGB(255, 255, 255)

				songStroke.Transparency = 0.94
				songStroke.Parent = songButton

				songButton.MouseEnter:Connect(function()
					TweenService:Create(
						songButton,
						TweenInfo.new(0.15),
						{
							BackgroundTransparency = 0.82
						}
					):Play()

					TweenService:Create(
						songStroke,
						TweenInfo.new(0.15),
						{
							Transparency = 0.75
						}
					):Play()
				end)

				songButton.MouseLeave:Connect(function()
					TweenService:Create(
						songButton,
						TweenInfo.new(0.15),
						{
							BackgroundTransparency = 0.91
						}
					):Play()

					TweenService:Create(
						songStroke,
						TweenInfo.new(0.15),
						{
							Transparency = 0.94
						}
					):Play()
				end)

				songButton.Activated:Connect(function()
					task.spawn(function()
						playSong(
							songData,
							songData.Name or "Song"
						)
					end)
				end)
			end
		end

		if visibleCount == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 50)
			empty.BackgroundTransparency = 1
			empty.Text = "No songs in this category."
			empty.TextColor3 =
				Color3.fromRGB(150, 160, 180)
			empty.TextSize = 12
			empty.Font = Enum.Font.Gotham
			empty.Parent = SongPanel
		end
	end)

	return button
end

--==================================================
-- LOAD CATEGORIES
--==================================================

local function rebuildCategories()
	clearContainer(CategoryPanel)

	local categorySet: {[string]: boolean} = {
		All = true
	}

	for _, song in ipairs(songs) do
		categorySet[getSongCategory(song)] = true
	end

	local categories = {}

	for category in pairs(categorySet) do
		table.insert(categories, category)
	end

	table.sort(categories, function(a, b)
		if a == "All" then
			return true
		end

		if b == "All" then
			return false
		end

		return a < b
	end)

	for index, category in ipairs(categories) do
		createCategoryButton(category, index)
	end

	selectedCategory = "All"

	-- Select All automatically.
	local allButton = CategoryPanel:FindFirstChild("All")

	if allButton and allButton:IsA("TextButton") then
		allButton.BackgroundTransparency = 0.78
		allButton.TextColor3 =
			Color3.fromRGB(235, 242, 255)
	end

	-- Populate All songs.
	if allButton and allButton:IsA("TextButton") then
		allButton:Activate()
	end
end

--==================================================
-- LOAD SONGS
--==================================================

local function loadSongs()
	if isPlaying then
		stopSong()
	end

	songs = {}

	clearContainer(CategoryPanel)
	clearContainer(SongPanel)

	setStatus("Loading songs...")

	local success, body =
		pcall(httpGet, GITHUB_SONGS_URL)

	if not success then
		setStatus("GitHub loading failed")
		return
	end

	local decodeSuccess, entries =
		pcall(function()
			return HttpService:JSONDecode(body)
		end)

	if not decodeSuccess
		or type(entries) ~= "table" then

		setStatus("Invalid GitHub response")
		return
	end

	for _, entry in ipairs(entries) do

		if type(entry) == "table"
			and entry.type == "file"
			and type(entry.name) == "string"
			and entry.name:lower():sub(-4) == ".lua" then

			local downloadUrl = entry.download_url

			if type(downloadUrl) == "string"
				and downloadUrl ~= "" then

				local fileSuccess, source =
					pcall(httpGet, downloadUrl)

				if fileSuccess then
					local song, errorMessage =
						loadSongSource(
							source,
							entry.name
						)

					if song then
						table.insert(songs, song)
					else
						warn(errorMessage)
					end
				end
			end
		end
	end

	rebuildCategories()

	setStatus(
		tostring(#songs)
			.. " songs loaded"
	)
end

--==================================================
-- BUTTONS
--==================================================

StopButton.Activated:Connect(function()
	stopSong()
end)

RefreshButton.Activated:Connect(function()
	stopSong()
	task.spawn(loadSongs)
end)

CloseButton.Activated:Connect(function()
	stopSong()
	ScreenGui.Enabled = false
end)

--==================================================
-- INITIAL LOAD
--==================================================

task.spawn(loadSongs)

