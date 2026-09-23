--!strict

--//==================================================
--// Services
--//==================================================

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--//==================================================
--// Configuration
--//==================================================

local SONGS_FOLDER = "songs"
local DEFAULT_KEY_DELAY = 0.05

--//==================================================
--// Executor filesystem check
--//==================================================

local filesystemAvailable =
    typeof(isfolder) == "function"
    and typeof(makefolder) == "function"
    and typeof(listfiles) == "function"
    and typeof(readfile) == "function"

if not filesystemAvailable then
    warn("PianoPlayer: executor filesystem functions are unavailable.")
    return
end

-- Create songs folder if it doesn't exist.
if not isfolder(SONGS_FOLDER) then
    makefolder(SONGS_FOLDER)
end

--//==================================================
--// PianoModule
--//
--// This loads the PianoModule from ShadowDev1231's
--// PianoPlayer repository.
--//==================================================

local PIANO_MODULE_URL =
    "https://raw.githubusercontent.com/ShadowDev1231/PianoPlayer/refs/heads/main/PianoModule.lua"

local PianoPlayer = nil

local function loadPianoModule()
    local requestFunction =
        (typeof(request) == "function" and request)
        or (typeof(http_request) == "function" and http_request)
        or (syn and syn.request)
        or (http and http.request)

    if not requestFunction then
        error("No supported HTTP request function was found.")
    end

    local response = requestFunction({
        Url = PIANO_MODULE_URL,
        Method = "GET"
    })

    if not response then
        error("Failed to request PianoModule.lua.")
    end

    if response.StatusCode and response.StatusCode ~= 200 then
        error("PianoModule.lua returned HTTP " .. tostring(response.StatusCode))
    end

    local source = response.Body

    if type(source) ~= "string" or source == "" then
        error("PianoModule.lua returned empty source.")
    end

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
local currentSongName = ""

--//==================================================
--// ScreenGui
--//==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SongUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

--//==================================================
--// Main Frame
--//==================================================

local Frame = Instance.new("Frame")
Frame.Name = "Frame"
Frame.Size = UDim2.fromScale(0.381, 0.514)
Frame.Position = UDim2.fromScale(0.232, 0.259)
Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame.BackgroundTransparency = 0
Frame.BorderSizePixel = 0
Frame.Visible = true
Frame.ZIndex = 1
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.Name = "UICorner"
FrameCorner.Parent = Frame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Name = "UIStroke"
FrameStroke.Color = Color3.fromRGB(0, 0, 0)
FrameStroke.Thickness = 1
FrameStroke.Parent = Frame

--//==================================================
--// Title
--//==================================================

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.fromScale(0.467, 0.0716)
Title.Position = UDim2.fromScale(0.252, 0.0289)
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 0
Title.BorderSizePixel = 0
Title.Text = "Piano Player"
Title.TextColor3 = Color3.fromRGB(27, 42, 53)
Title.TextSize = 14
Title.TextScaled = false
Title.TextWrapped = false
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.TextYAlignment = Enum.TextYAlignment.Center
Title.Font = Enum.Font.SourceSansBold
Title.ZIndex = 2
Title.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.Name = "UICorner"
TitleCorner.Parent = Title

local TitleStroke = Instance.new("UIStroke")
TitleStroke.Name = "UIStroke"
TitleStroke.Color = Color3.fromRGB(0, 0, 0)
TitleStroke.Thickness = 1
TitleStroke.Parent = Title

--//==================================================
--// Song List
--//==================================================

local Tab = Instance.new("ScrollingFrame")
Tab.Name = "Tab"
Tab.Size = UDim2.fromScale(0.2974, 0.774)
Tab.Position = UDim2.fromScale(0.0123, 0.1654)
Tab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Tab.BackgroundTransparency = 0
Tab.BorderSizePixel = 0
Tab.ScrollBarThickness = 5
Tab.CanvasSize = UDim2.fromScale(0, 0)
Tab.AutomaticCanvasSize = Enum.AutomaticSize.Y
Tab.ScrollingDirection = Enum.ScrollingDirection.Y
Tab.ZIndex = 2
Tab.Parent = Frame

local TabCorner = Instance.new("UICorner")
TabCorner.Name = "UICorner"
TabCorner.Parent = Tab

local TabStroke = Instance.new("UIStroke")
TabStroke.Name = "UIStroke"
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

--//==================================================
--// Content
--//==================================================

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.fromScale(0.6334, 0.774)
Content.Position = UDim2.fromScale(0.336, 0.1654)
Content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Content.BackgroundTransparency = 0
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 5
Content.CanvasSize = UDim2.fromScale(0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollingDirection = Enum.ScrollingDirection.Y
Content.ZIndex = 2
Content.Parent = Frame

local ContentCorner = Instance.new("UICorner")
ContentCorner.Name = "UICorner"
ContentCorner.Parent = Content

local ContentStroke = Instance.new("UIStroke")
ContentStroke.Name = "UIStroke"
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

--//==================================================
--// Close Button
--//==================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.fromScale(0.0718, 0.1224)
CloseButton.Position = UDim2.fromScale(0.9263, -0.00195)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 96, 96)
CloseButton.BackgroundTransparency = 0
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(118, 3, 3)
CloseButton.TextScaled = true
CloseButton.TextWrapped = true
CloseButton.TextXAlignment = Enum.TextXAlignment.Center
CloseButton.TextYAlignment = Enum.TextYAlignment.Center
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Active = true
CloseButton.Selectable = true
CloseButton.ZIndex = 3
CloseButton.Parent = Frame

local CloseCorner = Instance.new("UICorner")
CloseCorner.Name = "UICorner"
CloseCorner.Parent = CloseButton

--//==================================================
--// Status
--//==================================================

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

--//==================================================
--// Stop Button
--//==================================================

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

--//==================================================
--// Refresh Button
--//==================================================

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

local function isLuaFile(path: string): boolean
    return path:lower():sub(-4) == ".lua"
end

--//==================================================
--// Song Loading
--//==================================================

type Song = {
    Name: string?,
    playKey: ((self: any, key: string, keyDelay: number?) -> ())?,
    play: ((self: any, piano: any) -> ())?,
    Play: ((self: any, piano: any) -> ())?,
    Keys: string?,
    KeyDelay: number?
}

local function loadSongFile(path: string): (Song?, string?)
    local success, source = pcall(readfile, path)

    if not success then
        return nil, "Could not read file: " .. path
    end

    if type(source) ~= "string" or source == "" then
        return nil, "Song file is empty: " .. path
    end

    local compiled, compileError = loadstring(source)

    if not compiled then
        return nil, "Compile error in " .. path .. ": " .. tostring(compileError)
    end

    local successRun, result = pcall(compiled)

    if not successRun then
        return nil, "Runtime error in " .. path .. ": " .. tostring(result)
    end

    if type(result) ~= "table" then
        return nil,
            "Song must return a table: " .. path
    end

    return result :: Song, nil
end

--//==================================================
--// Playback
--//==================================================

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

        while isPlaying do
            task.wait()
        end
    end

    local songName = song.Name or fallbackName

    isPlaying = true
    stopRequested = false
    currentSongName = songName

    setStatus("Playing: " .. songName)

    local success, errorMessage = pcall(function()
        --================================================
        -- Preferred format:
        -- song:play(PianoPlayer)
        --================================================

        local playFunction = song.play or song.Play

        if type(playFunction) == "function" then
            playFunction(song, PianoPlayer)
            return
        end

        --================================================
        -- Alternative format:
        -- song.Keys = "asdfghj"
        --
        -- The main player calls PianoPlayer:playKey()
        --================================================

        if type(song.Keys) == "string" then
            local keyDelay = song.KeyDelay or DEFAULT_KEY_DELAY
            local keys = song.Keys:gsub("%s+", "")

            for index = 1, #keys do
                if stopRequested then
                    break
                end

                local key = keys:sub(index, index)

                PianoPlayer:playKey(key, keyDelay)
            end

            return
        end

        error(
            "Song has no play()/Play() function or Keys string: "
            .. songName
        )
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
    currentSongName = ""
end

--//==================================================
--// UI
--//==================================================

local function createSongButton(
    song: Song,
    fileName: string,
    layoutOrder: number
)
    local button = Instance.new("TextButton")

    button.Name = fileName
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    button.BorderSizePixel = 0
    button.Text = song.Name or fileName
    button.TextColor3 = Color3.fromRGB(27, 42, 53)
    button.TextSize = 14
    button.Font = Enum.Font.SourceSans
    button.AutoButtonColor = true
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

    return button
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

    return label
end

--//==================================================
--// Load Songs From songs/
--//==================================================

local function loadSongs()
    clearContainer(Tab)

    clearContainer(Content)

    setStatus("Loading songs...")

    local files

    local success, result = pcall(listfiles, SONGS_FOLDER)

    if not success then
        setStatus("Could not read songs folder")
        warn("PianoPlayer listfiles error:", result)
        return
    end

    files = result

    local songsLoaded = 0
    local filesFound = 0

    for _, path in ipairs(files) do
        if isLuaFile(path) then
            filesFound += 1

            local song, errorMessage = loadSongFile(path)

            if song then
                songsLoaded += 1

                createSongButton(
                    song,
                    getFileName(path),
                    songsLoaded
                )
            else
                warn(errorMessage)
            end
        end
    end

    if songsLoaded == 0 then
        createContentLabel(
            "No songs found.\n\nPut .lua song files inside:\n"
            .. SONGS_FOLDER
        )

        setStatus("No songs found")
        return
    end

    createContentLabel(
        tostring(songsLoaded)
        .. " song(s) loaded from "
        .. SONGS_FOLDER
    )

    setStatus(
        tostring(songsLoaded)
        .. " songs loaded"
    )
end

--//==================================================
--// Connections
--//==================================================

StopButton.Activated:Connect(function()
    stopSong()
end)

RefreshButton.Activated:Connect(function()
    if isPlaying then
        stopSong()
    end

    task.spawn(function()
        loadSongs()
    end)
end)

CloseButton.Activated:Connect(function()
    stopSong()
    ScreenGui.Enabled = false
end)

--//==================================================
--// Initial Load
--//==================================================

task.spawn(function()
    loadSongs()
end)

