local pianoplayermodule = {}

local VirtualInputManager = game:GetService("VirtualInputManager")

local keys = {
    -- Letters
    ["a"] = Enum.KeyCode.A,
    ["b"] = Enum.KeyCode.B,
    ["c"] = Enum.KeyCode.C,
    ["d"] = Enum.KeyCode.D,
    ["e"] = Enum.KeyCode.E,
    ["f"] = Enum.KeyCode.F,
    ["g"] = Enum.KeyCode.G,
    ["h"] = Enum.KeyCode.H,
    ["i"] = Enum.KeyCode.I,
    ["j"] = Enum.KeyCode.J,
    ["k"] = Enum.KeyCode.K,
    ["m"] = Enum.KeyCode.M,
    ["n"] = Enum.KeyCode.N,
    ["o"] = Enum.KeyCode.O,
    ["p"] = Enum.KeyCode.P,
    ["q"] = Enum.KeyCode.Q,
    ["r"] = Enum.KeyCode.R,
    ["s"] = Enum.KeyCode.S,
    ["t"] = Enum.KeyCode.T,
    ["u"] = Enum.KeyCode.U,
    ["v"] = Enum.KeyCode.V,
    ["w"] = Enum.KeyCode.W,
    ["x"] = Enum.KeyCode.X,
    ["y"] = Enum.KeyCode.Y,
    ["z"] = Enum.KeyCode.Z,

    ["A"] = Enum.KeyCode.A,
    ["B"] = Enum.KeyCode.B,
    ["C"] = Enum.KeyCode.C,
    ["D"] = Enum.KeyCode.D,
    ["E"] = Enum.KeyCode.E,
    ["F"] = Enum.KeyCode.F,
    ["G"] = Enum.KeyCode.G,
    ["H"] = Enum.KeyCode.H,
    ["I"] = Enum.KeyCode.I,
    ["J"] = Enum.KeyCode.J,
    ["K"] = Enum.KeyCode.K,
    ["M"] = Enum.KeyCode.M,
    ["N"] = Enum.KeyCode.N,
    ["O"] = Enum.KeyCode.O,
    ["P"] = Enum.KeyCode.P,
    ["Q"] = Enum.KeyCode.Q,
    ["R"] = Enum.KeyCode.R,
    ["S"] = Enum.KeyCode.S,
    ["T"] = Enum.KeyCode.T,
    ["U"] = Enum.KeyCode.U,
    ["V"] = Enum.KeyCode.V,
    ["W"] = Enum.KeyCode.W,
    ["X"] = Enum.KeyCode.X,
    ["Y"] = Enum.KeyCode.Y,
    ["Z"] = Enum.KeyCode.Z,

    -- Numbers
    ["1"] = Enum.KeyCode.One,
    ["2"] = Enum.KeyCode.Two,
    ["3"] = Enum.KeyCode.Three,
    ["4"] = Enum.KeyCode.Four,
    ["5"] = Enum.KeyCode.Five,
    ["6"] = Enum.KeyCode.Six,
    ["7"] = Enum.KeyCode.Seven,
    ["8"] = Enum.KeyCode.Eight,
    ["9"] = Enum.KeyCode.Nine,
    ["0"] = Enum.KeyCode.Zero,

    -- Shift + number characters
    ["!"] = Enum.KeyCode.One,
    ['"'] = Enum.KeyCode.Two,
    ["§"] = Enum.KeyCode.Three,
    ["$"] = Enum.KeyCode.Four,
    ["%"] = Enum.KeyCode.Five,
    ["&"] = Enum.KeyCode.Six,
    ["/"] = Enum.KeyCode.Seven,
    ["("] = Enum.KeyCode.Eight,
    [")"] = Enum.KeyCode.Nine,
    ["="] = Enum.KeyCode.Zero,
}

local shiftCharacters = {
    ["A"] = true, ["B"] = true, ["C"] = true, ["D"] = true,
    ["E"] = true, ["F"] = true, ["G"] = true, ["H"] = true,
    ["I"] = true, ["J"] = true, ["K"] = true, ["M"] = true,
    ["N"] = true, ["O"] = true, ["P"] = true, ["Q"] = true,
    ["R"] = true, ["S"] = true, ["T"] = true, ["U"] = true,
    ["V"] = true, ["W"] = true, ["X"] = true, ["Y"] = true,
    ["Z"] = true,

    ["!"] = true, ['"'] = true, ["§"] = true, ["$"] = true,
    ["%"] = true, ["&"] = true, ["/"] = true, ["("] = true,
    [")"] = true, ["="] = true,
}

function pianoplayermodule:playKey(key, keyDelay)
    local keyCode = keys[key]

    if not keyCode then
        warn("Unknown piano key:", key)
        return
    end

    local needsShift = shiftCharacters[key] == true

    if needsShift then
        VirtualInputManager:SendKeyEvent(
            true,
            Enum.KeyCode.LeftShift,
            false,
            game
        )
    end

    VirtualInputManager:SendKeyEvent(
        true,
        keyCode,
        false,
        game
    )

    task.wait(keyDelay or 0.05)

    VirtualInputManager:SendKeyEvent(
        false,
        keyCode,
        false,
        game
    )

    if needsShift then
        VirtualInputManager:SendKeyEvent(
            false,
            Enum.KeyCode.LeftShift,
            false,
            game
        )
    end
end
function pianoplayermodule:sleep(sleeptime)
    task.wait(sleeptime)
end
return pianoplayermodule
