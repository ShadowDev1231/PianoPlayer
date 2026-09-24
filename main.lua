--!strict

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DEFAULT_KEY_DELAY = 0.05
local GITHUB_SONGS_URL = "https://api.github.com/repos/ShadowDev1231/PianoPlayer/contents/songs?ref=main"

--//==================================================
--// PianoModule
--//==================================================

local PIANO_MODULE_URL = "https://raw.githubusercontent.com/ShadowDev1231/PianoPlayer/refs/heads/main/PianoModule.lua"
local PianoPlayer = nil

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
		error("HTTP " .. tostring(response.StatusCode) .. " while requesting " .. url)
	end

	local body = response.Body

	if type(body) ~= "string" or body == "" then
		error("HTTP request returned an empty response for " .. url)
	end

	return body
end

local function loadPianoModule()
	local source = httpGet(PIANO_MODULE_URL)

	local compiled, compileError = loadstring(source)

	if not compiled then
		error("Failed to compile PianoModule.lua: " .. tostring(compileError))
	end

	local success, module = pcall(compiled)

	if not success then
		error("Failed to execute PianoModule.lua: " .. tostring(module))
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

--//==================================================
--// Playback state
--//==================================================

local isPlaying = false
local stopRequested = false
local playbackThread: thread? = nil
local playbackId = 0

--//==================================================
--// ScreenGui
--//==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SongUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = playerGui

--//==================================================
--// Main glass window
--//==================================================

local Frame = Instance.new("Frame")
Frame.Name = "Frame"
Frame.Size = UDim2.fromScale(0.52, 0.63)
Frame.Position = UDim2.fromScale(0.24, 0.185)
Frame.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
Frame.BackgroundTransparency = 0.14
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = false
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 18)
FrameCorner.Parent = Frame

local FrameGradient = Instance.new("UIGradient")
FrameGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 42, 58)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(22, 28, 42)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 18, 28))
})
FrameGradient.Rotation = 135
FrameGradient.Parent = Frame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color = Color3.fromRGB(150, 180, 255)
FrameStroke.Transparency = 0.72
FrameStroke.Thickness = 1.25
FrameStroke.Parent = Frame

--// Soft shadow
local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 16, 1, 16)
Shadow.Position = UDim2.new(0, -8, 0, 10)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.65
Shadow.BorderSizePixel = 0
Shadow.ZIndex = Frame.ZIndex - 1
Shadow.Parent = Frame

local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 22)
ShadowCorner.Parent = Shadow

--//==================================================
--// Header
--//==================================================

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, -24, 0, 58)
Header.Position = UDim2.new(0, 12, 0, 10)
Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Header.BackgroundTransparency = 0.93
Header.BorderSizePixel = 0
Header.Parent = Frame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 13)
HeaderCorner.Parent = Header

local HeaderStroke = Instance.new("UIStroke")
HeaderStroke.Color = Color3.fromRGB(255, 255, 255)
HeaderStroke.Transparency = 0.9
HeaderStroke.Thickness = 1
HeaderStroke.Parent = Header

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -90, 0, 28)
Title.Position = UDim2.new(0, 16, 0, 7)
Title.BackgroundTransparency = 1
Title.Text = "Piano Player"
Title.TextColor3 = Color3.fromRGB(245, 248, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.Size = UDim2.new(1, -90, 0, 18)
Subtitle.Position = UDim2.new(0, 17, 0, 32)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Your songs • Your piano • Your performance"
Subtitle.TextColor3 = Color3.fromRGB(160, 170, 190)
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

--//==================================================
--// Close button
--//==================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.fromOffset(34, 34)
CloseButton.Position = UDim2.new(1, -45, 0, 12)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 85, 105)
CloseButton.BackgroundTransparency = 0.2
CloseButton.BorderSizePixel = 0
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 235, 240)
CloseButton.TextSize = 22
CloseButton.Font = Enum.Font.GothamBold
CloseButton.AutoButtonColor = false
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 10)
CloseCorner.Parent = CloseButton

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Color = Color3.fromRGB(255, 130, 145)
CloseStroke.Transparency = 0.45
CloseStroke.Parent = CloseButton

--//==================================================
--// Content area
--//==================================================

local Tab = Instance.new("ScrollingFrame")
Tab.Name = "Tab"
Tab.Size = UDim2.new(0.30, -8, 1, -145)
Tab.Position = UDim2.new(0, 12, 0, 80)
Tab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Tab.BackgroundTransparency = 0.94
Tab.BorderSizePixel = 0
Tab.ScrollBarThickness = 3
Tab.ScrollBarImageColor3 = Color3.fromRGB(130, 155, 220)
Tab.ScrollBarImageTransparency = 0.35
Tab.AutomaticCanvasSize = Enum.AutomaticSize.Y
Tab.ScrollingDirection = Enum.ScrollingDirection.Y
Tab.CanvasSize = UDim2.new()
Tab.Parent = Frame

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 13)
TabCorner.Parent = Tab

local TabStroke = Instance.new("UIStroke")
TabStroke.Color = Color3.fromRGB(255, 255, 255)
TabStroke.Transparency = 0.9
TabStroke.Thickness = 1
TabStroke.Parent = Tab

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 8)
TabPadding.PaddingBottom = UDim.new(0, 8)
TabPadding.PaddingLeft = UDim.new(0, 8)
TabPadding.PaddingRight = UDim.new(0, 8)
TabPadding.Parent = Tab

local TabLayout = Instance.new("UIListLayout")
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 6)
TabLayout.Parent = Tab

--//==================================================
--// Song content panel
--//==================================================

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(0.70, -20, 1, -145)
Content.Position = UDim2.new(0.30, 8, 0, 80)
Content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Content.BackgroundTransparency = 0.94
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(130, 155, 220)
Content.ScrollBarImageTransparency = 0.35
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollingDirection = Enum.ScrollingDirection.Y
Content.CanvasSize = UDim2.new()
Content.Parent = Frame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 13)
ContentCorner.Parent = Content

local ContentStroke = Instance.new("UIStroke")
ContentStroke.Color = Color3.fromRGB(255, 255, 255)
ContentStroke.Transparency = 0.9
ContentStroke.Thickness = 1
ContentStroke.Parent = Content

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 10)
ContentPadding.PaddingBottom = UDim.new(0, 10)
ContentPadding.PaddingLeft = UDim.new(0, 12)
ContentPadding.PaddingRight = UDim.new(0, 12)
ContentPadding.Parent = Content

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 7)
ContentLayout.Parent = Content

--//==================================================
--// Bottom control bar
--//==================================================

local BottomBar = Instance.new("Frame")
BottomBar.Name = "BottomBar"
BottomBar.Size = UDim2.new(1, -24, 0, 42)
BottomBar.Position = UDim2.new(0, 12, 1, -54)
BottomBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BottomBar.BackgroundTransparency = 0.94
BottomBar.BorderSizePixel = 0
BottomBar.Parent = Frame

local BottomCorner = Instance.new("UICorner")
BottomCorner.CornerRadius = UDim.new(0, 12)
BottomCorner.Parent = BottomBar

local BottomStroke = Instance.new("UIStroke")
BottomStroke.Color = Color3.fromRGB(255, 255, 255)
BottomStroke.Transparency = 0.9
BottomStroke.Parent = BottomBar

--//==================================================
--// Status
--//==================================================

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -190, 1, 0)
StatusLabel.Position = UDim2.new(0, 13, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready"
StatusLabel.TextColor3 = Color3.fromRGB(185, 195, 215)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Parent = BottomBar

--//==================================================
--// Buttons
--//==================================================

local RefreshButton = Instance.new("TextButton")
RefreshButton.Name = "RefreshButton"
RefreshButton.Size = UDim2.fromOffset(70, 28)
RefreshButton.Position = UDim2.new(1, -150, 0.5, -14)
RefreshButton.BackgroundColor3 = Color3.fromRGB(105, 140, 220)
RefreshButton.BackgroundTransparency = 0.18
RefreshButton.BorderSizePixel = 0
RefreshButton.Text = "REFRESH"
RefreshButton.TextColor3 = Color3.fromRGB(235, 242, 255)
RefreshButton.TextSize = 10
RefreshButton.Font = Enum.Font.GothamBold
RefreshButton.AutoButtonColor = false
RefreshButton.Parent = BottomBar

local RefreshCorner = Instance.new("UICorner")
RefreshCorner.CornerRadius = UDim.new(0, 8)
RefreshCorner.Parent = RefreshButton

local RefreshStroke = Instance.new("UIStroke")
RefreshStroke.Color = Color3.fromRGB(150, 180, 255)
RefreshStroke.Transparency = 0.5
RefreshStroke.Parent = RefreshButton

local StopButton = Instance.new("TextButton")
StopButton.Name = "StopButton"
StopButton.Size = UDim2.fromOffset(60, 28)
StopButton.Position = UDim2.new(1, -76, 0.5, -14)
StopButton.BackgroundColor3 = Color3.fromRGB(225, 75, 100)
StopButton.BackgroundTransparency = 0.12
StopButton.BorderSizePixel = 0
StopButton.Text = "STOP"
StopButton.TextColor3 = Color3.fromRGB(255, 235, 240)
StopButton.TextSize = 10
StopButton.Font = Enum.Font.GothamBold
StopButton.AutoButtonColor = false
StopButton.Parent = BottomBar

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 8)
StopCorner.Parent = StopButton

local StopStroke = Instance.new("UIStroke")
StopStroke.Color = Color3.fromRGB(255, 130, 150)
StopStroke.Transparency = 0.45
StopStroke.Parent = StopButton

--//==================================================
--// Button hover effects
--//==================================================

local function addHover(button: TextButton, normalTransparency: number)
	button.MouseEnter:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundTransparency = math.max(0, normalTransparency - 0.1)
			}
		):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundTransparency = normalTransparency
			}
		):Play()
	end)
end

addHover(CloseButton, 0.2)
addHover(RefreshButton, 0.18)
addHover(StopButton, 0.12)

--//==================================================
--// Helpers
--//==================================================

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

type Song = {
	Name: string?,
	playKey: ((self: any, key: string, keyDelay: number?) -> ())?,
	play: ((self: any, piano: any) -> ())?,
	Play: ((self: any, piano: any) -> ())?,
	Keys: string?,
	KeyDelay: number?
}

local function loadSongSource(source: string, displayName: string): (Song?, string?)
	if source == "" then
		return nil, "Song file is empty: " .. displayName
	end

	local compiled, compileError = loadstring(source)

	if not compiled then
		return nil, "Compile error in " .. displayName .. ": " .. tostring(compileError)
	end

	local success, result = pcall(compiled)

	if not success then
		return nil, "Runtime error in " .. displayName .. ": " .. tostring(result)
	end

	if type(result) ~= "table" then
		return nil, "Song must return a table: " .. displayName
	end

	return result :: Song, nil
end

--//==================================================
--// FIXED STOP FUNCTION
--//==================================================

local function stopSong()
	if not isPlaying and not playbackThread then
		setStatus("Ready")
		return
	end

	stopRequested = true

	-- Invalidate the current playback.
	playbackId += 1

	-- Cancel the actual playback task.
	-- This fixes songs that use their own play() function
	-- and do not check stopRequested themselves.
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
					if stopRequested or currentPlaybackId ~= playbackId then
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

		-- Only the currently active playback is allowed
		-- to update the UI/state.
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

--//==================================================
--// Song buttons
--//==================================================

local function createSongButton(song: Song, fileName: string, layoutOrder: number)
	local button = Instance.new("TextButton")
	button.Name = fileName
	button.Size = UDim2.new(1, 0, 0, 38)
	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundTransparency = 0.91
	button.BorderSizePixel = 0
	button.Text = song.Name or fileName
	button.TextColor3 = Color3.fromRGB(220, 228, 245)
	button.TextSize = 12
	button.Font = Enum.Font.GothamMedium
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.AutoButtonColor = false
	button.LayoutOrder = layoutOrder
	button.Parent = Tab

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = button

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.94
	stroke.Thickness = 1
	stroke.Parent = button

	button.MouseEnter:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundTransparency = 0.84
			}
		):Play()

		TweenService:Create(
			stroke,
			TweenInfo.new(0.15),
			{
				Transparency = 0.72
			}
		):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundTransparency = 0.91
			}
		):Play()

		TweenService:Create(
			stroke,
			TweenInfo.new(0.15),
			{
				Transparency = 0.94
			}
		):Play()
	end)

	button.Activated:Connect(function()
		task.spawn(function()
			playSong(song, fileName)
		end)
	end)
end

local function createContentLabel(text: string)
	local label = Instance.new("TextLabel")
	label.Name = "ContentLabel"
	label.Size = UDim2.new(1, 0, 0, 34)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(170, 180, 200)
	label.TextSize = 12
	label.Font = Enum.Font.Gotham
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = Content
end

--//==================================================
--// Load songs
--//==================================================

local function loadSongs()
	if isPlaying then
		stopSong()
	end

	clearContainer(Tab)
	clearContainer(Content)

	setStatus("Loading songs from GitHub...")

	local success, body = pcall(httpGet, GITHUB_SONGS_URL)

	if not success then
		createContentLabel(
			"Could not load songs from GitHub.\n\n"
				.. tostring(body)
		)

		setStatus("GitHub loading failed")
		warn("PianoPlayer GitHub error:", body)
		return
	end

	local decodeSuccess, entries = pcall(function()
		return HttpService:JSONDecode(body)
	end)

	if not decodeSuccess or type(entries) ~= "table" then
		createContentLabel("GitHub returned invalid song folder data.")
		setStatus("Invalid GitHub response")
		return
	end

	local songsLoaded = 0
	local luaFilesFound = 0

	for _, entry in ipairs(entries) do
		if type(entry) == "table"
			and entry.type == "file"
			and type(entry.name) == "string"
			and entry.name:lower():sub(-4) == ".lua" then

			luaFilesFound += 1

			local downloadUrl = entry.download_url

			if type(downloadUrl) == "string" and downloadUrl ~= "" then
				local fileSuccess, source = pcall(httpGet, downloadUrl)

				if fileSuccess then
					local song, errorMessage =
						loadSongSource(source, entry.name)

					if song then
						songsLoaded += 1

						createSongButton(
							song,
							getFileName(entry.name),
							songsLoaded
						)
					else
						warn(errorMessage)
					end
				else
					warn(
						"Could not download "
							.. entry.name
							.. ": "
							.. tostring(source)
					)
				end
			end
		end
	end

	if songsLoaded == 0 then
		createContentLabel(
			"No .lua songs were loaded from the GitHub songs folder."
		)

		setStatus(
			luaFilesFound == 0
				and "No .lua songs found"
				or "No songs loaded"
		)

		return
	end

	createContentLabel(
		tostring(songsLoaded)
			.. " song(s) loaded from GitHub"
	)

	setStatus(
		tostring(songsLoaded)
			.. " songs loaded"
	)
end

--//==================================================
--// Button connections
--//==================================================

StopButton.Activated:Connect(stopSong)

RefreshButton.Activated:Connect(function()
	if isPlaying then
		stopSong()
	end

	task.spawn(loadSongs)
end)

CloseButton.Activated:Connect(function()
	stopSong()
	ScreenGui.Enabled = false
end)

--//==================================================
--// Initial load
--//==================================================

task.spawn(loadSongs)

