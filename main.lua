--!strict

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DEFAULT_KEY_DELAY = 0.05
local GITHUB_SONGS_URL = "https://api.github.com/repos/ShadowDev1231/PianoPlayer/contents/songs?ref=main"

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

    local response = requestFunction({Url = url, Method = "GET"})
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

--//==================================================
--// PianoModule
--//==================================================

local PIANO_MODULE_URL = "https://raw.githubusercontent.com/ShadowDev1231/PianoPlayer/refs/heads/main/PianoModule.lua"
local PianoPlayer = nil

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

local isPlaying = false
local stopRequested = false

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SongUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

local Frame = Instance.new("Frame")
Frame.Name = "Frame"
Frame.Size = UDim2.fromScale(0.381, 0.514)
Frame.Position = UDim2.fromScale(0.232, 0.259)
Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.Parent = Frame
local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color = Color3.fromRGB(0, 0, 0)
FrameStroke.Thickness = 1
FrameStroke.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.fromScale(0.467, 0.0716)
Title.Position = UDim2.fromScale(0.252, 0.0289)
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BorderSizePixel = 0
Title.Text = "Piano Player"
Title.TextColor3 = Color3.fromRGB(27, 42, 53)
Title.TextSize = 14
Title.Font = Enum.Font.SourceSansBold
Title.Parent = Frame
local TitleCorner = Instance.new("UICorner")
TitleCorner.Parent = Title
local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color = Color3.fromRGB(0, 0, 0)
TitleStroke.Thickness = 1
TitleStroke.Parent = Title

local Tab = Instance.new("ScrollingFrame")
Tab.Name = "Tab"
Tab.Size = UDim2.fromScale(0.2974, 0.774)
Tab.Position = UDim2.fromScale(0.0123, 0.1654)
Tab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Tab.BorderSizePixel = 0
Tab.ScrollBarThickness = 5
Tab.AutomaticCanvasSize = Enum.AutomaticSize.Y
Tab.ScrollingDirection = Enum.ScrollingDirection.Y
Tab.Parent = Frame
local TabCorner = Instance.new("UICorner")
TabCorner.Parent = Tab
local TabStroke = Instance.new("UIStroke")
TabStroke.Color = Color3.fromRGB(0, 0, 0)
TabStroke.Thickness = 1
TabStroke.Parent = Tab
local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 5)
TabPadding.PaddingBottom = UDim.new(0, 5)
TabPadding.PaddingLeft = UDim.new(0, 5)
TabPadding.PaddingRight = UDim.new(0, 5)
TabPadding.Parent = Tab
local TabLayout = Instance.new("UIListLayout")
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = Tab

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.fromScale(0.6334, 0.774)
Content.Position = UDim2.fromScale(0.336, 0.1654)
Content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 5
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollingDirection = Enum.ScrollingDirection.Y
Content.Parent = Frame
local ContentCorner = Instance.new("UICorner")
ContentCorner.Parent = Content
local ContentStroke = Instance.new("UIStroke")
ContentStroke.Color = Color3.fromRGB(0, 0, 0)
ContentStroke.Thickness = 1
ContentStroke.Parent = Content
local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 5)
ContentPadding.PaddingBottom = UDim.new(0, 5)
ContentPadding.PaddingLeft = UDim.new(0, 5)
ContentPadding.PaddingRight = UDim.new(0, 5)
ContentPadding.Parent = Content
local ContentLayout = Instance.new("UIListLayout")
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 5)
ContentLayout.Parent = Content

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.fromScale(0.0718, 0.1224)
CloseButton.Position = UDim2.fromScale(0.9263, -0.00195)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 96, 96)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(118, 3, 3)
CloseButton.TextScaled = true
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Parent = Frame
local CloseCorner = Instance.new("UICorner")
CloseCorner.Parent = CloseButton

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(0.55, 0, 0, 25)
StatusLabel.Position = UDim2.new(0.36, 0, 0.95, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready"
StatusLabel.TextColor3 = Color3.fromRGB(27, 42, 53)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Frame

local StopButton = Instance.new("TextButton")
StopButton.Name = "StopButton"
StopButton.Size = UDim2.new(0, 70, 0, 25)
StopButton.Position = UDim2.new(0.72, 0, 0.95, 0)
StopButton.BackgroundColor3 = Color3.fromRGB(255, 96, 96)
StopButton.BorderSizePixel = 0
StopButton.Text = "STOP"
StopButton.TextColor3 = Color3.fromRGB(118, 3, 3)
StopButton.TextSize = 13
StopButton.Font = Enum.Font.SourceSansBold
StopButton.Parent = Frame
local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 5)
StopCorner.Parent = StopButton

local RefreshButton = Instance.new("TextButton")
RefreshButton.Name = "RefreshButton"
RefreshButton.Size = UDim2.new(0, 70, 0, 25)
RefreshButton.Position = UDim2.new(0.53, 0, 0.95, 0)
RefreshButton.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
RefreshButton.BorderSizePixel = 0
RefreshButton.Text = "REFRESH"
RefreshButton.TextColor3 = Color3.fromRGB(27, 42, 53)
RefreshButton.TextSize = 12
RefreshButton.Font = Enum.Font.SourceSansBold
RefreshButton.Parent = Frame
local RefreshCorner = Instance.new("UICorner")
RefreshCorner.CornerRadius = UDim.new(0, 5)
RefreshCorner.Parent = RefreshButton

local function setStatus(text: string)
    StatusLabel.Text = text
end

local function clearContainer(container: Instance)
    for _, child in ipairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UIStroke") and not child:IsA("UICorner") then
            child:Destroy()
        end
    end
end

local function getFileName(path: string): string
    local name = path:match("([^\/]+)$") or path
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

local function stopSong()
    stopRequested = true
    if isPlaying then
        setStatus("Stopping...")
    end
end

local function playSong(song: Song, fallbackName: string)
    if not PianoPlayer then
        setStatus("PianoModule unavailable")
        return
    end

    if isPlaying then
        stopSong()
        while isPlaying do task.wait() end
    end

    local songName = song.Name or fallbackName
    isPlaying = true
    stopRequested = false
    setStatus("Playing: " .. songName)

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
                if stopRequested then break end
                PianoPlayer:playKey(keys:sub(index, index), keyDelay)
            end
            return
        end

        error("Song has no play()/Play() function or Keys string: " .. songName)
    end)

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
end

local function createSongButton(song: Song, fileName: string, layoutOrder: number)
    local button = Instance.new("TextButton")
    button.Name = fileName
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    button.BorderSizePixel = 0
    button.Text = song.Name or fileName
    button.TextColor3 = Color3.fromRGB(27, 42, 53)
    button.TextSize = 14
    button.Font = Enum.Font.SourceSans
    button.LayoutOrder = layoutOrder
    button.Parent = Tab

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button

    button.Activated:Connect(function()
        task.spawn(function()
            playSong(song, fileName)
        end)
    end)
end

local function createContentLabel(text: string)
    local label = Instance.new("TextLabel")
    label.Name = "ContentLabel"
    label.Size = UDim2.new(1, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(27, 42, 53)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Content
end

--//==================================================
--// Load every .lua file in the GitHub songs folder
--//==================================================

local function loadSongs()
    clearContainer(Tab)
    clearContainer(Content)
    setStatus("Loading songs from GitHub...")

    local success, body = pcall(httpGet, GITHUB_SONGS_URL)
    if not success then
        createContentLabel("Could not load songs from GitHub.\n\n" .. tostring(body))
        setStatus("GitHub song loading failed")
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
        if type(entry) == "table" and entry.type == "file" and type(entry.name) == "string" and entry.name:lower():sub(-4) == ".lua" then
            luaFilesFound += 1

            local downloadUrl = entry.download_url
            if type(downloadUrl) == "string" and downloadUrl ~= "" then
                local fileSuccess, source = pcall(httpGet, downloadUrl)
                if fileSuccess then
                    local song, errorMessage = loadSongSource(source, entry.name)
                    if song then
                        songsLoaded += 1
                        createSongButton(song, getFileName(entry.name), songsLoaded)
                    else
                        warn(errorMessage)
                    end
                else
                    warn("Could not download " .. entry.name .. ": " .. tostring(source))
                end
            end
        end
    end

    if songsLoaded == 0 then
        createContentLabel("No .lua songs were loaded from the GitHub songs folder.")
        setStatus(luaFilesFound == 0 and "No .lua songs found" or "No songs loaded")
        return
    end

    createContentLabel(tostring(songsLoaded) .. " song(s) loaded from GitHub")
    setStatus(tostring(songsLoaded) .. " songs loaded")
end

StopButton.Activated:Connect(stopSong)

RefreshButton.Activated:Connect(function()
    if isPlaying then stopSong() end
    task.spawn(loadSongs)
end)

CloseButton.Activated:Connect(function()
    stopSong()
    ScreenGui.Enabled = false
end)

task.spawn(loadSongs)
