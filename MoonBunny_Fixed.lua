-- ╔══════════════════════════════════════╗
-- ║   MAIN SCRIPT by bdaircool           ║
-- ║   Wird automatisch vom LOADER        ║
-- ║   via GitHub geladen — updatebar!    ║
-- ╚══════════════════════════════════════╝

local _HttpService = game:GetService("HttpService")
local _Players = game:GetService("Players")
local _player = _Players.LocalPlayer

local keyURL = (getgenv and getgenv().MOONBUNNY_KEY_URL)
    or "https://raw.githubusercontent.com/MoonBunny-art/meine-keys/main/Keys.txt"

local _result = (getgenv and getgenv().MOONBUNNY_KEY_RESULT)

if not _result then
    local ok, res = pcall(function() return game:HttpGet(keyURL) end)
    if not ok then error("❌ Konnte Keys nicht laden!") end
    _result = res

    if _player.UserId ~= 3664472992 then
        if _result:find("DEACTIVATED") or _result:find("DEAKTIVIERT") then
            _player:Kick("This script may have been disabled by its owner!")
            return
        end
    end
end

if getgenv then
    getgenv().MOONBUNNY_KEY_RESULT = nil
    getgenv().MOONBUNNY_KEY_URL    = nil
end

local validKeys = {}
for key in _result:gmatch("[^\n]+") do
    validKeys[key:gsub("%s+", "")] = true
end

local KEY_SAVE_FILE = "moonbunny_key.txt"
local ADMIN_ID = 3664472992

local function safeWritefile(path, content)
    pcall(function()
        if writefile then writefile(path, content) end
    end)
end

local function safeReadfile(path)
    local ok, result = pcall(function()
        if isfile and isfile(path) then
            return readfile(path)
        end
        return nil
    end)
    if ok then return result end
    return nil
end

local function safeIsfile(path)
    local ok, result = pcall(function()
        if isfile then return isfile(path) end
        return false
    end)
    return ok and result
end

local function saveKey(key)
    safeWritefile(KEY_SAVE_FILE, key)
end

local function loadSavedKey()
    if not safeIsfile(KEY_SAVE_FILE) then return nil end
    local data = safeReadfile(KEY_SAVE_FILE)
    if data then return data:gsub("%s+", "") end
    return nil
end

local selfKick = false

local function startMainScript()

local savedKeyForCheck = loadSavedKey()
task.spawn(function()
    while task.wait(1) do
        local ok, freshResult = pcall(function()
            return game:HttpGet(keyURL)
        end)
        if ok then
            if _player.UserId ~= 3664472992 then
                if freshResult:find("DEACTIVATED") or freshResult:find("DEAKTIVIERT") then
                    safeWritefile(KEY_SAVE_FILE, "")
                    selfKick = true
                    _player:Kick("Script wurde deaktiviert!")
                    break
                end
                local freshKeys = {}
                for k in freshResult:gmatch("[^\n]+") do
                    freshKeys[k:gsub("%s+", "")] = true
                end
                if not freshKeys[savedKeyForCheck] then
                    safeWritefile(KEY_SAVE_FILE, "")
                    selfKick = true
                    _player:Kick("Dein Key wurde entfernt!")
                    break
                end
            end
        end
    end
end)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local SAVE_FILE = "bdaircool_settings.json"

local function persistSave(data)
    pcall(function()
        safeWritefile(SAVE_FILE, HttpService:JSONEncode(data))
    end)
end

local function persistLoad()
    if not safeIsfile(SAVE_FILE) then return nil end
    local ok, result = pcall(function()
        local raw = safeReadfile(SAVE_FILE)
        if raw then return HttpService:JSONDecode(raw) end
        return nil
    end)
    if ok then return result end
    return nil
end

local godmodeActive = false
local godmodeHeartbeatConn = nil
local godmodeHealthConn = nil
local godmodeStateConn  = nil

local function applyGodmodeToChar(char)
    if not godmodeActive then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.MaxHealth = math.huge
    hum.Health    = math.huge
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    if godmodeHealthConn then godmodeHealthConn:Disconnect() end
    if godmodeStateConn  then godmodeStateConn:Disconnect()  end
    godmodeHealthConn = hum.HealthChanged:Connect(function()
        if godmodeActive and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
    end)
    godmodeStateConn = hum.StateChanged:Connect(function(_, new)
        if godmodeActive and new == Enum.HumanoidStateType.Dead then
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            hum.Health = hum.MaxHealth
        end
    end)
end

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    task.wait(0.3)
    applyGodmodeToChar(newChar)
end)

local pauseResetCooldown = false

local function doReset()
    if pauseResetCooldown then return end
    pauseResetCooldown = true
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum then
        local wasGodmode = godmodeActive
        godmodeActive = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        hum.Health = 0
        task.delay(0.2, function()
            godmodeActive = wasGodmode
            pauseResetCooldown = false
        end)
    else
        task.delay(2, function() pauseResetCooldown = false end)
    end
end

pcall(function()
    player:GetPropertyChangedSignal("GameplayPaused"):Connect(function()
        if player.GameplayPaused then doReset() end
    end)
end)

local function containsPausedText(instance)
    local ok, result = pcall(function()
        for _, obj in ipairs(instance:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local t = obj.Text:lower()
                if t:find("gameplay paused") or t:find("game paused") or t:find("gameplay has been paused") then
                    return true
                end
            end
        end
        return false
    end)
    return ok and result
end

local pauseCheckTimer = 0
RunService.Heartbeat:Connect(function(dt)
    pauseCheckTimer = pauseCheckTimer + dt
    if pauseCheckTimer < 0.5 then return end
    pauseCheckTimer = 0
    pcall(function()
        if containsPausedText(game:GetService("CoreGui")) then doReset(); return end
    end)
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui")
               and gui.Name ~= "ExploitGui" and gui.Name ~= "FlyGui"
               and gui.Name ~= "LeaveGui"
               and gui.Name ~= "TracerGui"  and gui.Name ~= "SpeedGui"
               and gui.Name ~= "AIChatGui" and gui.Name ~= "CrashGui" then
                if containsPausedText(gui) then doReset(); return end
            end
        end
    end
end)

pcall(function()
    local mt = getrawmetatable and getrawmetatable(player)
    if mt then
        setreadonly(mt, false)
        local origNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if self == player and method == "Kick" then
                if not selfKick then return end
            end
            return origNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

pcall(function()
    local mt = getrawmetatable and getrawmetatable(game)
    if not mt then return end
    setreadonly(mt, false)
    local origNamecall2 = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            local name = (self and self.Name or ""):lower()
            if name:find("kick") or name:find("ban") or name:find("anticheat")
            or name:find("anti_cheat") or name:find("cheat") or name:find("report") then
                return
            end
        end
        return origNamecall2(self, ...)
    end)
    setreadonly(mt, true)
end)

local function makeDraggable(frame)
    local dragging = false
    local dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
end

local C_BG_MAIN  = Color3.fromRGB(0,   5,  20)
local C_BG_PANEL = Color3.fromRGB(8,  15,  35)
local C_BG_TITLE = Color3.fromRGB(12, 22,  55)
local C_BG_ROW   = Color3.fromRGB(15, 25,  60)
local C_ACCENT   = Color3.fromRGB(80, 130, 255)
local C_ACCENT2  = Color3.fromRGB(60, 100, 255)
local C_TEXT     = Color3.fromRGB(220, 230, 255)
local C_DIM      = Color3.fromRGB(120, 140, 190)
local C_GREEN    = Color3.fromRGB(60,  220, 120)
local C_RED      = Color3.fromRGB(200,  50,  60)
local TRANS      = 0.4

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ExploitGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0, 46, 0, 46)
toggleBtn.Position = UDim2.new(0.5, -23, 0, 14)
toggleBtn.BackgroundColor3 = C_BG_MAIN
toggleBtn.BackgroundTransparency = TRANS
toggleBtn.BorderSizePixel = 0
toggleBtn.Image = "rbxassetid://6031075938"
toggleBtn.ScaleType = Enum.ScaleType.Fit
toggleBtn.ZIndex = 999
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)
local btnStroke = Instance.new("UIStroke", toggleBtn)
btnStroke.Color = C_ACCENT
btnStroke.Thickness = 2
toggleBtn.Parent = screenGui
TweenService:Create(toggleBtn, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Size = UDim2.new(0, 50, 0, 50),
    Position = UDim2.new(0.5, -25, 0, 12)
}):Play()

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 420, 0, 290)
container.Position = UDim2.new(0.5, -105, 0.5, -145)
container.BackgroundTransparency = 1
container.ZIndex = 50
container.ClipsDescendants = false
container.Parent = screenGui

local leftPanel = Instance.new("Frame")
leftPanel.Size = UDim2.new(0, 210, 0, 290)
leftPanel.BackgroundColor3 = C_BG_PANEL
leftPanel.BackgroundTransparency = TRANS
leftPanel.BorderSizePixel = 0
leftPanel.ZIndex = 51
leftPanel.ClipsDescendants = true
Instance.new("UICorner", leftPanel).CornerRadius = UDim.new(0, 12)
local leftStroke = Instance.new("UIStroke", leftPanel)
leftStroke.Color = C_ACCENT2
leftStroke.Thickness = 1.5
leftPanel.Parent = container

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = C_BG_TITLE
titleBar.BackgroundTransparency = TRANS
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 52
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)
titleBar.Parent = leftPanel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🔐 Logg Acc"
titleLabel.TextColor3 = C_ACCENT
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 53
titleLabel.Parent = titleBar

local featBtn = Instance.new("TextButton")
featBtn.Size = UDim2.new(0, 30, 0, 24)
featBtn.Position = UDim2.new(1, -60, 0, 5)
featBtn.Text = "⚙️"
featBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 160)
featBtn.BackgroundTransparency = TRANS
featBtn.TextColor3 = C_TEXT
featBtn.TextScaled = true
featBtn.Font = Enum.Font.GothamBold
featBtn.BorderSizePixel = 0
featBtn.ZIndex = 53
Instance.new("UICorner", featBtn).CornerRadius = UDim.new(0, 5)
featBtn.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0, 5)
closeBtn.Text = "✕"
closeBtn.BackgroundColor3 = C_RED
closeBtn.BackgroundTransparency = TRANS
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 53
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)
closeBtn.Parent = titleBar

local madeByLabel = Instance.new("TextLabel")
madeByLabel.Size = UDim2.new(1, -16, 0, 16)
madeByLabel.Position = UDim2.new(0, 8, 0, 36)
madeByLabel.BackgroundTransparency = 1
madeByLabel.Text = "Made by bdaircool"
madeByLabel.TextColor3 = C_DIM
madeByLabel.TextScaled = true
madeByLabel.Font = Enum.Font.Gotham
madeByLabel.TextXAlignment = Enum.TextXAlignment.Left
madeByLabel.ZIndex = 53
madeByLabel.Parent = leftPanel

local function makeRow(yPos, labelText, valueText)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -16, 0, 38)
    row.Position = UDim2.new(0, 8, 0, yPos)
    row.BackgroundColor3 = C_BG_ROW
    row.BackgroundTransparency = TRANS
    row.BorderSizePixel = 0
    row.ZIndex = 52
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)
    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Color = C_ACCENT2
    rowStroke.Thickness = 1
    rowStroke.Transparency = 0.6
    row.Parent = leftPanel

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.44, 0, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = C_DIM
    lbl.TextScaled = true
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 53
    lbl.Parent = row

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0.54, -6, 1, 0)
    val.Position = UDim2.new(0.44, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = valueText
    val.TextColor3 = C_TEXT
    val.TextScaled = true
    val.Font = Enum.Font.GothamBold
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.ClipsDescendants = true
    val.ZIndex = 53
    val.Parent = row
end

makeRow(56,  "🆔 ID",      tostring(player.UserId))
makeRow(100, "👤 User",    player.Name)
makeRow(144, "📛 Display", player.DisplayName)
makeRow(188, "📅 Age",     player.AccountAge .. "d")

local leaveRow = Instance.new("Frame")
leaveRow.Size = UDim2.new(1, -16, 0, 38)
leaveRow.Position = UDim2.new(0, 8, 0, 244)
leaveRow.BackgroundColor3 = C_BG_ROW
leaveRow.BackgroundTransparency = TRANS
leaveRow.BorderSizePixel = 0
leaveRow.ZIndex = 52
Instance.new("UICorner", leaveRow).CornerRadius = UDim.new(0, 7)
local leaveRowStroke = Instance.new("UIStroke", leaveRow)
leaveRowStroke.Color = C_ACCENT2
leaveRowStroke.Thickness = 1
leaveRowStroke.Transparency = 0.6
leaveRow.Parent = leftPanel

local leaveRowLbl = Instance.new("TextLabel")
leaveRowLbl.Size = UDim2.new(0.55, 0, 1, 0)
leaveRowLbl.Position = UDim2.new(0, 6, 0, 0)
leaveRowLbl.BackgroundTransparency = 1
leaveRowLbl.Text = "🚪 Leave Btn"
leaveRowLbl.TextColor3 = C_DIM
leaveRowLbl.TextScaled = true
leaveRowLbl.Font = Enum.Font.Gotham
leaveRowLbl.TextXAlignment = Enum.TextXAlignment.Left
leaveRowLbl.ZIndex = 53
leaveRowLbl.Parent = leaveRow

local leaveActivateBtn = Instance.new("TextButton")
leaveActivateBtn.Size = UDim2.new(0, 70, 0, 26)
leaveActivateBtn.Position = UDim2.new(1, -76, 0.5, -13)
leaveActivateBtn.Text = "Activate"
leaveActivateBtn.BackgroundColor3 = C_RED
leaveActivateBtn.BackgroundTransparency = TRANS
leaveActivateBtn.TextColor3 = Color3.new(1, 1, 1)
leaveActivateBtn.TextScaled = true
leaveActivateBtn.Font = Enum.Font.GothamBold
leaveActivateBtn.BorderSizePixel = 0
leaveActivateBtn.ZIndex = 54
Instance.new("UICorner", leaveActivateBtn).CornerRadius = UDim.new(0, 5)
leaveActivateBtn.Parent = leaveRow

local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(0, 200, 0, 290)
rightPanel.Position = UDim2.new(0, 215, 0, 0)
rightPanel.BackgroundColor3 = C_BG_PANEL
rightPanel.BackgroundTransparency = TRANS
rightPanel.BorderSizePixel = 0
rightPanel.ZIndex = 51
rightPanel.Visible = false
Instance.new("UICorner", rightPanel).CornerRadius = UDim.new(0, 12)
local rightStroke = Instance.new("UIStroke", rightPanel)
rightStroke.Color = C_ACCENT2
rightStroke.Thickness = 1.5
rightPanel.Parent = container

local rightTitle = Instance.new("TextLabel")
rightTitle.Size = UDim2.new(1, 0, 0, 34)
rightTitle.BackgroundColor3 = C_BG_TITLE
rightTitle.BackgroundTransparency = TRANS
rightTitle.BorderSizePixel = 0
rightTitle.Text = "⚙️  Features"
rightTitle.TextColor3 = C_ACCENT
rightTitle.TextScaled = true
rightTitle.Font = Enum.Font.GothamBold
rightTitle.ZIndex = 52
Instance.new("UICorner", rightTitle).CornerRadius = UDim.new(0, 12)
rightTitle.Parent = rightPanel

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -44)
scroll.Position = UDim2.new(0, 5, 0, 40)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = C_ACCENT
scroll.ZIndex = 52
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = rightPanel
local listLayout = Instance.new("UIListLayout", scroll)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

local menuOpen = true
local featOpen = false

local function openMenu()
    menuOpen = true
    leftPanel.Visible = true
    leftPanel.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(leftPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Size = UDim2.new(0, 210, 0, 290)}):Play()
    btnStroke.Color = C_GREEN
end

local function closeMenu()
    menuOpen = false
    featOpen = false
    rightPanel.Visible = false
    TweenService:Create(leftPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
    task.wait(0.35)
    leftPanel.Visible = false
    btnStroke.Color = C_ACCENT
end

local function openFeatures()
    featOpen = true
    rightPanel.Visible = true
    featBtn.BackgroundColor3 = Color3.fromRGB(20, 100, 50)
end

local function closeFeatures()
    featOpen = false
    rightPanel.Visible = false
    featBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 160)
end

closeBtn.MouseButton1Click:Connect(closeMenu)
toggleBtn.MouseButton1Click:Connect(function()
    if menuOpen then closeMenu() else openMenu() end
end)
featBtn.MouseButton1Click:Connect(function()
    if featOpen then closeFeatures() else openFeatures() end
end)

local featureButtonRefs = {}

local function makeFeatureBtn(name, icon, onEnable, onDisable)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 36)
    btn.BackgroundColor3 = C_BG_ROW
    btn.BackgroundTransparency = TRANS
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 53
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.Parent = scroll

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(0, 28, 1, 0)
    iconLbl.Position = UDim2.new(0, 4, 0, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = icon
    iconLbl.TextScaled = true
    iconLbl.Font = Enum.Font.Gotham
    iconLbl.ZIndex = 54
    iconLbl.Parent = btn

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -70, 1, 0)
    nameLbl.Position = UDim2.new(0, 36, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = name
    nameLbl.TextColor3 = C_DIM
    nameLbl.TextScaled = true
    nameLbl.Font = Enum.Font.Gotham
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 54
    nameLbl.Parent = btn

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 12, 0, 12)
    statusDot.Position = UDim2.new(1, -18, 0.5, -6)
    statusDot.BackgroundColor3 = Color3.fromRGB(50, 60, 100)
    statusDot.BorderSizePixel = 0
    statusDot.ZIndex = 54
    Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
    statusDot.Parent = btn

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = C_ACCENT2
    stroke.Thickness = 1
    stroke.Transparency = 0.7

    local active = false

    local function setOn()
        active = true
        statusDot.BackgroundColor3 = C_GREEN
        stroke.Color = C_GREEN
        stroke.Transparency = 0
        nameLbl.TextColor3 = C_GREEN
        btn.BackgroundColor3 = Color3.fromRGB(10, 40, 30)
        onEnable()
    end

    local function setOff()
        active = false
        statusDot.BackgroundColor3 = Color3.fromRGB(50, 60, 100)
        stroke.Color = C_ACCENT2
        stroke.Transparency = 0.7
        nameLbl.TextColor3 = C_DIM
        btn.BackgroundColor3 = C_BG_ROW
        onDisable()
    end

    featureButtonRefs[name] = {
        getActive = function() return active end,
        turnOn    = setOn,
        turnOff   = setOff,
    }

    btn.MouseButton1Click:Connect(function()
        if active then
            featureButtonRefs[name].turnOff()
        else
            featureButtonRefs[name].turnOn()
        end
    end)

    return btn
end

local function makeToolboxGui(titleText, xPos, yPos, height, accentColor, isDraggable)
    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, height)
    frame.Position = UDim2.new(0, xPos, 0, yPos)
    frame.BackgroundColor3 = C_BG_PANEL
    frame.BackgroundTransparency = TRANS
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 200
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local fStroke = Instance.new("UIStroke", frame)
    fStroke.Color = accentColor
    fStroke.Thickness = 2
    frame.Parent = gui

    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(1, 0, 0, 36)
    titleFrame.BackgroundColor3 = C_BG_TITLE
    titleFrame.BackgroundTransparency = TRANS
    titleFrame.BorderSizePixel = 0
    titleFrame.ZIndex = 201
    Instance.new("UICorner", titleFrame).CornerRadius = UDim.new(0, 12)
    titleFrame.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -44, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = titleText
    lbl.TextColor3 = accentColor
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 202
    lbl.Parent = titleFrame

    local closeB = Instance.new("TextButton")
    closeB.Size = UDim2.new(0, 26, 0, 26)
    closeB.Position = UDim2.new(1, -30, 0, 5)
    closeB.Text = "✕"
    closeB.BackgroundColor3 = C_RED
    closeB.BackgroundTransparency = TRANS
    closeB.TextColor3 = Color3.new(1, 1, 1)
    closeB.TextScaled = true
    closeB.Font = Enum.Font.GothamBold
    closeB.BorderSizePixel = 0
    closeB.ZIndex = 202
    Instance.new("UICorner", closeB).CornerRadius = UDim.new(0, 5)
    closeB.Parent = titleFrame
    closeB.MouseButton1Click:Connect(function() frame.Visible = false end)

    if isDraggable then makeDraggable(frame) end

    return frame
end

local currentSpeed = 16
local flyBox = makeToolboxGui("🚀 Fly", 270, 200, 60, C_ACCENT, false)
local currentFlySpeed = 60

local aimlockBox = makeToolboxGui("🎯 Aimlock", 270, 320, 130, C_RED, true)
local aimlockActive = false
local aimlockTarget = nil
local aimlockConn = nil

local aimlockStatusLbl = Instance.new("TextLabel")
aimlockStatusLbl.Size = UDim2.new(1, -16, 0, 20)
aimlockStatusLbl.Position = UDim2.new(0, 8, 0, 44)
aimlockStatusLbl.BackgroundTransparency = 1
aimlockStatusLbl.Text = "Status: OFF"
aimlockStatusLbl.TextColor3 = C_RED
aimlockStatusLbl.TextScaled = true
aimlockStatusLbl.Font = Enum.Font.Gotham
aimlockStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
aimlockStatusLbl.ZIndex = 202
aimlockStatusLbl.Parent = aimlockBox

local function getNearestPlayer()
    local nearest, minDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local root   = p.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = character and character:FindFirstChild("HumanoidRootPart")
            if root and myRoot then
                local dist = (root.Position - myRoot.Position).Magnitude
                if dist < minDist then minDist = dist; nearest = p end
            end
        end
    end
    return nearest
end

local function stopAimlock()
    aimlockActive = false
    aimlockTarget = nil
    if aimlockConn then aimlockConn:Disconnect(); aimlockConn = nil end
    aimlockStatusLbl.Text = "Status: OFF"
    aimlockStatusLbl.TextColor3 = C_RED
end

local aimlockBtnRow = Instance.new("Frame")
aimlockBtnRow.Size = UDim2.new(1, -16, 0, 34)
aimlockBtnRow.Position = UDim2.new(0, 8, 0, 70)
aimlockBtnRow.BackgroundTransparency = 1
aimlockBtnRow.ZIndex = 202
aimlockBtnRow.Parent = aimlockBox

local lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.new(0.48, 0, 1, 0)
lockBtn.Text = "🎯 Lock"
lockBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 160)
lockBtn.BackgroundTransparency = TRANS
lockBtn.TextColor3 = C_TEXT
lockBtn.TextScaled = true
lockBtn.Font = Enum.Font.GothamBold
lockBtn.BorderSizePixel = 0
lockBtn.ZIndex = 203
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 7)
lockBtn.Parent = aimlockBtnRow

local stopAimlockBtn = Instance.new("TextButton")
stopAimlockBtn.Size = UDim2.new(0.48, 0, 1, 0)
stopAimlockBtn.Position = UDim2.new(0.52, 0, 0, 0)
stopAimlockBtn.Text = "⛔ Stop"
stopAimlockBtn.BackgroundColor3 = C_RED
stopAimlockBtn.BackgroundTransparency = TRANS
stopAimlockBtn.TextColor3 = Color3.new(1, 1, 1)
stopAimlockBtn.TextScaled = true
stopAimlockBtn.Font = Enum.Font.GothamBold
stopAimlockBtn.BorderSizePixel = 0
stopAimlockBtn.ZIndex = 203
Instance.new("UICorner", stopAimlockBtn).CornerRadius = UDim.new(0, 7)
stopAimlockBtn.Parent = aimlockBtnRow

lockBtn.MouseButton1Click:Connect(function()
    local target = getNearestPlayer()
    if not target or not target.Character then
        aimlockStatusLbl.Text = "Kein Ziel!"
        aimlockStatusLbl.TextColor3 = Color3.fromRGB(255, 200, 0)
        return
    end
    aimlockTarget = target
    aimlockActive = true
    aimlockStatusLbl.Text = "Locked: " .. target.Name
    aimlockStatusLbl.TextColor3 = C_GREEN
    if aimlockConn then aimlockConn:Disconnect() end
    aimlockConn = RunService.Heartbeat:Connect(function(dt)
        if not aimlockActive then return end
        if not aimlockTarget or not aimlockTarget.Character then stopAimlock(); return end
        local targetRoot = aimlockTarget.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then stopAimlock(); return end
        local myRoot = character and character:FindFirstChild("HumanoidRootPart")
        local myHum  = character and character:FindFirstChildOfClass("Humanoid")
        if not myRoot or not myHum then return end
        local behindTarget = targetRoot.Position + targetRoot.CFrame.LookVector * -0.5
        local dir = (behindTarget - myRoot.Position)
        local dist = dir.Magnitude
        if dist > 1.5 then
            local bv = myRoot:FindFirstChild("AimlockBV")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "AimlockBV"
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Parent = myRoot
            end
            bv.Velocity = dir.Unit * 85
        else
            local bv = myRoot:FindFirstChild("AimlockBV")
            if bv then bv.Velocity = Vector3.zero end
        end
        local lookDir = (targetRoot.Position - myRoot.Position)
        if lookDir.Magnitude > 0 then
            local bg = myRoot:FindFirstChild("AimlockBG")
            if not bg then
                bg = Instance.new("BodyGyro")
                bg.Name = "AimlockBG"
                bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bg.P = 5e4
                bg.D = 100
                bg.Parent = myRoot
            end
            bg.CFrame = CFrame.new(myRoot.Position, myRoot.Position + Vector3.new(lookDir.X, 0, lookDir.Z))
        end
    end)
end)

stopAimlockBtn.MouseButton1Click:Connect(function()
    stopAimlock()
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        local bv = myRoot:FindFirstChild("AimlockBV")
        local bg = myRoot:FindFirstChild("AimlockBG")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
end)

local flyGui = Instance.new("ScreenGui")
flyGui.Name = "FlyGui"
flyGui.ResetOnSpawn = false
flyGui.IgnoreGuiInset = true
flyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
flyGui.Enabled = false
flyGui.Parent = player:WaitForChild("PlayerGui")

local flyPad = Instance.new("Frame")
flyPad.Size = UDim2.new(0, 220, 0, 170)
flyPad.Position = UDim2.new(0, 10, 1, -190)
flyPad.BackgroundColor3 = C_BG_PANEL
flyPad.BackgroundTransparency = TRANS
flyPad.BorderSizePixel = 0
Instance.new("UICorner", flyPad).CornerRadius = UDim.new(0, 12)
local flyPadStroke = Instance.new("UIStroke", flyPad)
flyPadStroke.Color = C_ACCENT
flyPadStroke.Thickness = 2
flyPad.Parent = flyGui

local flyDir = {fwd = 0, right = 0, up = 0}
local BTN = 66

local function makeFlyBtn(parent, text, cx, cy, onDown, onUp)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, BTN, 0, BTN)
    b.Position = UDim2.new(0, cx - BTN / 2, 0, cy - BTN / 2)
    b.Text = text
    b.BackgroundColor3 = C_BG_ROW
    b.BackgroundTransparency = TRANS
    b.TextColor3 = C_TEXT
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.ZIndex = 10
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    b.Parent = parent
    b.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            b.BackgroundColor3 = Color3.fromRGB(20, 80, 40)
            onDown()
        end
    end)
    b.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            b.BackgroundColor3 = C_BG_ROW
            onUp()
        end
    end)
    return b
end

makeFlyBtn(flyPad, "▲", 110, 38,  function() flyDir.fwd = 1 end,    function() flyDir.fwd = 0 end)
makeFlyBtn(flyPad, "▼", 110, 132, function() flyDir.fwd = -1 end,   function() flyDir.fwd = 0 end)
makeFlyBtn(flyPad, "◀",  38, 85,  function() flyDir.right = -1 end, function() flyDir.right = 0 end)
makeFlyBtn(flyPad, "▶", 182, 85,  function() flyDir.right = 1 end,  function() flyDir.right = 0 end)

local vPad = Instance.new("Frame")
vPad.Size = UDim2.new(0, 80, 0, 150)
vPad.Position = UDim2.new(1, -100, 1, -170)
vPad.BackgroundColor3 = C_BG_PANEL
vPad.BackgroundTransparency = TRANS
vPad.BorderSizePixel = 0
Instance.new("UICorner", vPad).CornerRadius = UDim.new(0, 12)
local vPadStroke = Instance.new("UIStroke", vPad)
vPadStroke.Color = C_ACCENT
vPadStroke.Thickness = 2
vPad.Parent = flyGui

makeFlyBtn(vPad, "⬆", 40, 38,  function() flyDir.up = 1 end,  function() flyDir.up = 0 end)
makeFlyBtn(vPad, "⬇", 40, 112, function() flyDir.up = -1 end, function() flyDir.up = 0 end)

local function setJumpBtnVisible(visible)
    local touchGui = player:WaitForChild("PlayerGui"):FindFirstChild("TouchGui")
    if touchGui then
        local tf = touchGui:FindFirstChild("TouchControlFrame")
        if tf then
            local jb = tf:FindFirstChild("JumpButton")
            if jb then jb.Visible = visible end
        end
    end
end

local leaveGui = Instance.new("ScreenGui")
leaveGui.Name = "LeaveGui"
leaveGui.ResetOnSpawn = false
leaveGui.IgnoreGuiInset = true
leaveGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
leaveGui.Enabled = false
leaveGui.Parent = player:WaitForChild("PlayerGui")

local leaveBtn = Instance.new("TextButton")
leaveBtn.Size = UDim2.new(0, 54, 0, 54)
leaveBtn.Position = UDim2.new(0, 8, 0, 56)
leaveBtn.BackgroundColor3 = C_RED
leaveBtn.BackgroundTransparency = TRANS
leaveBtn.BorderSizePixel = 0
leaveBtn.Text = "🚪"
leaveBtn.TextColor3 = Color3.new(1, 1, 1)
leaveBtn.TextScaled = true
leaveBtn.Font = Enum.Font.GothamBold
leaveBtn.ZIndex = 400
leaveBtn.AutoButtonColor = false
Instance.new("UICorner", leaveBtn).CornerRadius = UDim.new(1, 0)
local leaveStroke = Instance.new("UIStroke", leaveBtn)
leaveStroke.Color = Color3.fromRGB(255, 60, 60)
leaveStroke.Thickness = 2
leaveBtn.Parent = leaveGui

leaveBtn.MouseButton1Click:Connect(function()
    selfKick = true
    Players.LocalPlayer:Kick("You left the game.")
end)

local leavePopup = Instance.new("Frame")
leavePopup.Size = UDim2.new(0, 300, 0, 160)
leavePopup.AnchorPoint = Vector2.new(0.5, 0.5)
leavePopup.Position = UDim2.new(0.5, 0, 0.5, 0)
leavePopup.BackgroundColor3 = C_BG_PANEL
leavePopup.BackgroundTransparency = TRANS
leavePopup.BorderSizePixel = 0
leavePopup.Visible = false
leavePopup.ZIndex = 500
Instance.new("UICorner", leavePopup).CornerRadius = UDim.new(0, 12)
local leavePopupStroke = Instance.new("UIStroke", leavePopup)
leavePopupStroke.Color = C_RED
leavePopupStroke.Thickness = 2
leavePopup.Parent = screenGui

local leavePopupTitle = Instance.new("TextLabel")
leavePopupTitle.Size = UDim2.new(1, -10, 0, 60)
leavePopupTitle.Position = UDim2.new(0, 5, 0, 8)
leavePopupTitle.BackgroundTransparency = 1
leavePopupTitle.Text = "ARE U SURE U WANT TO\nGET THE LEAVE BUTTON?!"
leavePopupTitle.TextColor3 = C_RED
leavePopupTitle.TextScaled = true
leavePopupTitle.Font = Enum.Font.GothamBold
leavePopupTitle.ZIndex = 501
leavePopupTitle.Parent = leavePopup

local leavePopupSub = Instance.new("TextLabel")
leavePopupSub.Size = UDim2.new(1, -10, 0, 22)
leavePopupSub.Position = UDim2.new(0, 5, 0, 72)
leavePopupSub.BackgroundTransparency = 1
leavePopupSub.Text = "⚠️ Pressing the button will kick you!"
leavePopupSub.TextColor3 = Color3.fromRGB(255, 180, 0)
leavePopupSub.TextScaled = true
leavePopupSub.Font = Enum.Font.Gotham
leavePopupSub.ZIndex = 501
leavePopupSub.Parent = leavePopup

local leaveYes = Instance.new("TextButton")
leaveYes.Size = UDim2.new(0.44, 0, 0, 36)
leaveYes.Position = UDim2.new(0.04, 0, 1, -44)
leaveYes.Text = "✅ Yes"
leaveYes.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
leaveYes.BackgroundTransparency = TRANS
leaveYes.TextColor3 = Color3.new(1, 1, 1)
leaveYes.TextScaled = true
leaveYes.Font = Enum.Font.GothamBold
leaveYes.BorderSizePixel = 0
leaveYes.ZIndex = 501
Instance.new("UICorner", leaveYes).CornerRadius = UDim.new(0, 7)
leaveYes.Parent = leavePopup

local leaveNo = Instance.new("TextButton")
leaveNo.Size = UDim2.new(0.44, 0, 0, 36)
leaveNo.Position = UDim2.new(0.52, 0, 1, -44)
leaveNo.Text = "❌ No"
leaveNo.BackgroundColor3 = C_RED
leaveNo.BackgroundTransparency = TRANS
leaveNo.TextColor3 = Color3.new(1, 1, 1)
leaveNo.TextScaled = true
leaveNo.Font = Enum.Font.GothamBold
leaveNo.BorderSizePixel = 0
leaveNo.ZIndex = 501
Instance.new("UICorner", leaveNo).CornerRadius = UDim.new(0, 7)
leaveNo.Parent = leavePopup

local leavePopupOpen = false

local function openLeavePopup()
    if leavePopupOpen then return end
    leavePopupOpen = true
    leavePopup.Size = UDim2.new(0, 0, 0, 0)
    leavePopup.Visible = true
    TweenService:Create(leavePopup, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 300, 0, 160)}):Play()
end

local function closeLeavePopup()
    if not leavePopupOpen then return end
    leavePopupOpen = false
    TweenService:Create(leavePopup, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}):Play()
    task.wait(0.22)
    leavePopup.Visible = false
    leavePopup.Size = UDim2.new(0, 300, 0, 160)
end

leaveYes.MouseButton1Click:Connect(function()
    closeLeavePopup()
    task.wait(0.1)
    leaveGui.Enabled = true
end)
leaveNo.MouseButton1Click:Connect(closeLeavePopup)
leaveActivateBtn.MouseButton1Click:Connect(openLeavePopup)

local function enableGodmode()
    godmodeActive = true
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.MaxHealth = math.huge
        hum.Health    = math.huge
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
    if godmodeHeartbeatConn then godmodeHeartbeatConn:Disconnect() end
    godmodeHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not godmodeActive then return end
        local h = character and character:FindFirstChildOfClass("Humanoid")
        if not h then return end
        if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
        if h:GetState() == Enum.HumanoidStateType.Dead then
            h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            h.Health = h.MaxHealth
        end
    end)
    applyGodmodeToChar(character)
end

local function disableGodmode()
    godmodeActive = false
    if godmodeHeartbeatConn then godmodeHeartbeatConn:Disconnect(); godmodeHeartbeatConn = nil end
    if godmodeHealthConn    then godmodeHealthConn:Disconnect();    godmodeHealthConn    = nil end
    if godmodeStateConn     then godmodeStateConn:Disconnect();     godmodeStateConn     = nil end
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.MaxHealth = 100
        hum.Health    = 100
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
    end
end

local espGui = Instance.new("ScreenGui")
espGui.Name = "ESPGui"
espGui.ResetOnSpawn = false
espGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
espGui.IgnoreGuiInset = true
espGui.Parent = player:WaitForChild("PlayerGui")

local espConn
local function enableESP()
    local function addESP(p)
        if p == player then return end
        local function applyToChar(char)
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    local sel = Instance.new("SelectionBox")
                    sel.Name = "ESP_SEL"
                    sel.Adornee = part
                    sel.Color3 = Color3.fromRGB(255, 0, 0)
                    sel.LineThickness = 0.05
                    sel.SurfaceTransparency = 0.7
                    sel.SurfaceColor3 = Color3.fromRGB(255, 0, 0)
                    sel.Parent = espGui
                end
            end
            local head = char:FindFirstChild("Head")
            if head then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ESP_TAG"
                bb.Size = UDim2.new(0, 100, 0, 30)
                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                bb.AlwaysOnTop = true
                bb.Adornee = head
                bb.Parent = espGui
                local lbl = Instance.new("TextLabel", bb)
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = p.Name
                lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
                lbl.TextStrokeTransparency = 0
                lbl.TextScaled = true
                lbl.Font = Enum.Font.GothamBold
            end
        end
        if p.Character then applyToChar(p.Character) end
        p.CharacterAdded:Connect(applyToChar)
    end
    for _, p in pairs(Players:GetPlayers()) do addESP(p) end
    espConn = Players.PlayerAdded:Connect(addESP)
end
local function disableESP()
    if espConn then espConn:Disconnect(); espConn = nil end
    for _, obj in pairs(espGui:GetChildren()) do obj:Destroy() end
end

local flyConn
local flyActive = false
local function enableFly()
    flyActive = true
    flyGui.Enabled = true
    flyDir.fwd = 0; flyDir.right = 0; flyDir.up = 0
    setJumpBtnVisible(false)
    local root = character:WaitForChild("HumanoidRootPart")
    local hum = character:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = true end
    for _, v in pairs(root:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
    end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyBV"; bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = root
    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyBG"
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = 5e4; bg.D = 100
    bg.Parent = root
    local cam = workspace.CurrentCamera
    flyConn = RunService.Heartbeat:Connect(function()
        if not flyActive then return end
        local cf = cam.CFrame
        local look  = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
        if look.Magnitude  > 0 then look  = look.Unit  end
        if right.Magnitude > 0 then right = right.Unit end
        local dir = Vector3.zero
        dir = dir + look  * flyDir.fwd
        dir = dir + right * flyDir.right
        dir = dir + Vector3.new(0, 1, 0) * flyDir.up
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir = dir + look end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir = dir - look end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir = dir - right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir = dir + right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        bv.Velocity = dir * currentFlySpeed
        bg.CFrame = cf
    end)
end
local function disableFly()
    flyActive = false
    flyGui.Enabled = false
    flyDir.fwd = 0; flyDir.right = 0; flyDir.up = 0
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    setJumpBtnVisible(true)
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        local bv = root:FindFirstChild("FlyBV")
        local bg = root:FindFirstChild("FlyBG")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
    local hum = character and character:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
end

local speedOn  = false
local speedGui = Instance.new("ScreenGui")
speedGui.Name           = "SpeedGui"
speedGui.ResetOnSpawn   = false
speedGui.IgnoreGuiInset = true
speedGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
speedGui.Enabled        = false
speedGui.Parent         = player:WaitForChild("PlayerGui")

local spFrame = Instance.new("Frame")
spFrame.Size             = UDim2.new(0, 160, 0, 118)
spFrame.Position         = UDim2.new(0, 10, 0.5, -60)
spFrame.BackgroundColor3 = C_BG_PANEL
spFrame.BackgroundTransparency = TRANS
spFrame.BorderSizePixel  = 0
spFrame.ZIndex           = 400
Instance.new("UICorner", spFrame).CornerRadius = UDim.new(0, 10)
local spStroke = Instance.new("UIStroke", spFrame)
spStroke.Color     = Color3.fromRGB(255, 200, 0)
spStroke.Thickness = 2
spFrame.Parent = speedGui
makeDraggable(spFrame)

local spTitle = Instance.new("TextLabel")
spTitle.Size             = UDim2.new(1, 0, 0, 28)
spTitle.BackgroundColor3 = C_BG_TITLE
spTitle.BackgroundTransparency = TRANS
spTitle.BorderSizePixel  = 0
spTitle.Text             = "⚡ Speed"
spTitle.TextColor3       = Color3.fromRGB(255, 200, 0)
spTitle.TextScaled       = true
spTitle.Font             = Enum.Font.GothamBold
spTitle.ZIndex           = 401
Instance.new("UICorner", spTitle).CornerRadius = UDim.new(0, 10)
spTitle.Parent = spFrame

local spBg = Instance.new("Frame")
spBg.Size             = UDim2.new(1, -16, 0, 32)
spBg.Position         = UDim2.new(0, 8, 0, 34)
spBg.BackgroundColor3 = C_BG_ROW
spBg.BackgroundTransparency = TRANS
spBg.BorderSizePixel  = 0
spBg.ZIndex           = 401
Instance.new("UICorner", spBg).CornerRadius = UDim.new(0, 6)
spBg.Parent = spFrame

local spValLbl = Instance.new("TextLabel")
spValLbl.Size               = UDim2.new(0.35, 0, 1, -8)
spValLbl.Position           = UDim2.new(0, 6, 0, 4)
spValLbl.BackgroundTransparency = 1
spValLbl.Text               = "16"
spValLbl.TextColor3         = C_TEXT
spValLbl.TextScaled         = true
spValLbl.Font               = Enum.Font.GothamBold
spValLbl.ZIndex             = 402
spValLbl.Parent             = spBg

local spBox = Instance.new("TextBox")
spBox.Size               = UDim2.new(0.38, -4, 1, -8)
spBox.Position           = UDim2.new(0.35, 2, 0, 4)
spBox.BackgroundColor3   = C_BG_ROW
spBox.BackgroundTransparency = TRANS
spBox.BorderSizePixel    = 0
spBox.Text               = ""
spBox.PlaceholderText    = "1-999"
spBox.TextColor3         = C_TEXT
spBox.PlaceholderColor3  = C_DIM
spBox.TextScaled         = true
spBox.Font               = Enum.Font.Gotham
spBox.ClearTextOnFocus   = true
spBox.ZIndex             = 402
Instance.new("UICorner", spBox).CornerRadius = UDim.new(0, 4)
spBox.Parent = spBg

local spSetBtn = Instance.new("TextButton")
spSetBtn.Size             = UDim2.new(0.27, -4, 1, -8)
spSetBtn.Position         = UDim2.new(0.73, 2, 0, 4)
spSetBtn.Text             = "Set"
spSetBtn.BackgroundColor3 = Color3.fromRGB(140, 100, 0)
spSetBtn.BackgroundTransparency = TRANS
spSetBtn.TextColor3       = Color3.new(1,1,1)
spSetBtn.TextScaled       = true
spSetBtn.Font             = Enum.Font.GothamBold
spSetBtn.BorderSizePixel  = 0
spSetBtn.ZIndex           = 402
Instance.new("UICorner", spSetBtn).CornerRadius = UDim.new(0, 5)
spSetBtn.Parent = spBg

local spStatus = Instance.new("TextLabel")
spStatus.Size               = UDim2.new(1, -16, 0, 16)
spStatus.Position           = UDim2.new(0, 8, 0, 70)
spStatus.BackgroundTransparency = 1
spStatus.Text               = "Status: AUS"
spStatus.TextColor3         = C_DIM
spStatus.TextScaled         = true
spStatus.Font               = Enum.Font.Gotham
spStatus.TextXAlignment     = Enum.TextXAlignment.Left
spStatus.ZIndex             = 401
spStatus.Parent             = spFrame

local spToggle = Instance.new("TextButton")
spToggle.Size             = UDim2.new(1, -16, 0, 26)
spToggle.Position         = UDim2.new(0, 8, 1, -34)
spToggle.BackgroundColor3 = Color3.fromRGB(100, 70, 0)
spToggle.BackgroundTransparency = TRANS
spToggle.BorderSizePixel  = 0
spToggle.Text             = "▶ Einschalten"
spToggle.TextColor3       = Color3.new(1,1,1)
spToggle.TextScaled       = true
spToggle.Font             = Enum.Font.GothamBold
spToggle.ZIndex           = 402
Instance.new("UICorner", spToggle).CornerRadius = UDim.new(0, 7)
spToggle.Parent = spFrame

local function applySpeed()
    local v = tonumber(spBox.Text)
    if v then
        v = math.clamp(math.floor(v), 1, 999)
        currentSpeed = v
        spValLbl.Text = tostring(v)
        if speedOn then
            local h = character and character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v end
        end
    end
end
spSetBtn.MouseButton1Click:Connect(applySpeed)
spBox.FocusLost:Connect(function(enter) if enter then applySpeed() end end)

spToggle.MouseButton1Click:Connect(function()
    speedOn = not speedOn
    if speedOn then
        spToggle.Text             = "⏹ Ausschalten"
        spToggle.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        spStatus.Text             = "Status: AN ⚡"
        spStatus.TextColor3       = Color3.fromRGB(255, 220, 0)
        spStroke.Color            = Color3.fromRGB(255, 220, 0)
        local h = character and character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = currentSpeed end
    else
        spToggle.Text             = "▶ Einschalten"
        spToggle.BackgroundColor3 = Color3.fromRGB(100, 70, 0)
        spStatus.Text             = "Status: AUS"
        spStatus.TextColor3       = C_DIM
        spStroke.Color            = Color3.fromRGB(255, 200, 0)
        local h = character and character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16 end
    end
end)

local function enableSpeed()  speedGui.Enabled = true  end
local function disableSpeed()
    if speedOn then
        speedOn = false
        local h = character and character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16 end
    end
    speedGui.Enabled = false
end

RunService.Heartbeat:Connect(function()
    if not speedOn then return end
    if currentSpeed <= 16 then return end
    local h = character and character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = currentSpeed end
end)

local jumpConn
local function enableInfJump()
    jumpConn = UserInputService.JumpRequest:Connect(function()
        local h = character and character:FindFirstChild("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end
local function disableInfJump()
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
end

local function enableSpin()
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local bav = Instance.new("BodyAngularVelocity")
    bav.Name = "SpinBAV"
    bav.AngularVelocity = Vector3.new(0, 20, 0)
    bav.MaxTorque = Vector3.new(0, math.huge, 0)
    bav.P = 1e5
    bav.Parent = root
end
local function disableSpin()
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        local b = root:FindFirstChild("SpinBAV")
        if b then b:Destroy() end
    end
end

local function setScale(v)
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local desc = Instance.new("HumanoidDescription")
    local ok, currentDesc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(player.UserId)
    end)
    if ok and currentDesc then desc = currentDesc end
    desc.HeadScale        = v
    desc.BodyHeightScale  = v
    desc.BodyWidthScale   = v
    desc.BodyDepthScale   = v
    desc.BodyTypeScale    = math.min(v, 1)
    pcall(function() hum:ApplyDescription(desc) end)
    pcall(function()
        for _, scaleName in pairs({"HeadScale","BodyHeightScale","BodyWidthScale","BodyDepthScale"}) do
            local scaleVal = hum:FindFirstChild(scaleName) or character:FindFirstChild(scaleName)
            if scaleVal and scaleVal:IsA("NumberValue") then scaleVal.Value = v end
        end
    end)
end
local function enableGiant()  setScale(5) end
local function disableGiant() setScale(1) end

local savedT = {}
local function enableInvisible()
    savedT = {}
    for _, p in pairs(character:GetDescendants()) do
        if p:IsA("BasePart") then
            savedT[p] = p.Transparency
            p.Transparency = 1; p.LocalTransparencyModifier = 1
        end
        if p:IsA("Decal") then
            savedT[p] = p.Transparency; p.Transparency = 1
        end
    end
end
local function disableInvisible()
    for p, t in pairs(savedT) do
        if p and p.Parent then
            p.Transparency = t
            if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
        end
    end
    savedT = {}
end

local rainConn
local rainHue = 0
local function enableRainbow()
    rainConn = RunService.Heartbeat:Connect(function(dt)
        rainHue = (rainHue + dt * 0.5) % 1
        local col = Color3.fromHSV(rainHue, 1, 1)
        for _, p in pairs(character:GetDescendants()) do
            if p:IsA("BasePart") then p.Color = col end
        end
    end)
end
local function disableRainbow()
    if rainConn then rainConn:Disconnect(); rainConn = nil end
end

local tracerGui = Instance.new("ScreenGui")
tracerGui.Name = "TracerGui"
tracerGui.ResetOnSpawn = false
tracerGui.IgnoreGuiInset = true
tracerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
tracerGui.Parent = player:WaitForChild("PlayerGui")
local tracerCanvas = Instance.new("Frame", tracerGui)
tracerCanvas.Size = UDim2.new(1, 0, 1, 0)
tracerCanvas.BackgroundTransparency = 1
tracerCanvas.ZIndex = 1
local tracerConn
local function drawLine(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end
    local line = Instance.new("Frame", tracerCanvas)
    line.Size = UDim2.new(0, len, 0, 2)
    line.Position = UDim2.new(0, (x1 + x2) / 2 - len / 2, 0, (y1 + y2) / 2 - 1)
    line.Rotation = math.deg(math.atan2(dy, dx))
    line.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    line.BorderSizePixel = 0
    line.ZIndex = 2
end
local function enableTracers()
    tracerConn = RunService.Heartbeat:Connect(function()
        for _, f in pairs(tracerCanvas:GetChildren()) do f:Destroy() end
        local cam = workspace.CurrentCamera
        local vp = cam.ViewportSize
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local torso = p.Character:FindFirstChild("HumanoidRootPart")
                    or p.Character:FindFirstChild("UpperTorso")
                    or p.Character:FindFirstChild("Torso")
                if torso then
                    local sp, onScreen = cam:WorldToViewportPoint(torso.Position)
                    if onScreen then drawLine(vp.X / 2, vp.Y, sp.X, sp.Y) end
                end
            end
        end
    end)
end
local function disableTracers()
    if tracerConn then tracerConn:Disconnect(); tracerConn = nil end
    for _, f in pairs(tracerCanvas:GetChildren()) do f:Destroy() end
end

local fpsFrame = Instance.new("Frame")
fpsFrame.Size = UDim2.new(0, 150, 0, 28)
fpsFrame.Position = UDim2.new(1, -158, 0, 10)
fpsFrame.BackgroundColor3 = C_BG_PANEL
fpsFrame.BackgroundTransparency = TRANS
fpsFrame.BorderSizePixel = 0
fpsFrame.ZIndex = 999
fpsFrame.Visible = false
Instance.new("UICorner", fpsFrame).CornerRadius = UDim.new(0, 6)
local fpsFrameStroke = Instance.new("UIStroke", fpsFrame)
fpsFrameStroke.Color = C_ACCENT2
fpsFrameStroke.Thickness = 1
fpsFrame.Parent = screenGui

if player.UserId == 3664472992 then
    local scriptStatusBtn = Instance.new("TextButton")
    scriptStatusBtn.Size             = UDim2.new(0, 130, 0, 32)
    scriptStatusBtn.Position         = UDim2.new(0, 10, 0.5, -16)
    scriptStatusBtn.BackgroundColor3 = C_BG_PANEL
    scriptStatusBtn.BackgroundTransparency = TRANS
    scriptStatusBtn.BorderSizePixel  = 0
    scriptStatusBtn.Text             = "⏳ Checking..."
    scriptStatusBtn.TextColor3       = C_DIM
    scriptStatusBtn.TextScaled       = true
    scriptStatusBtn.Font             = Enum.Font.GothamBold
    scriptStatusBtn.ZIndex           = 1001
    scriptStatusBtn.AutoButtonColor  = false
    Instance.new("UICorner", scriptStatusBtn).CornerRadius = UDim.new(0, 8)
    local scriptStatusStroke = Instance.new("UIStroke", scriptStatusBtn)
    scriptStatusStroke.Color     = C_ACCENT2
    scriptStatusStroke.Thickness = 2
    scriptStatusBtn.Parent = screenGui

    local lastKnownKeys = {}
    for k in pairs(validKeys) do
        lastKnownKeys[k] = true
    end

    local function refreshStatus()
        pcall(function()
            local ok, freshResult = pcall(function()
                return game:HttpGet(keyURL)
            end)
            if not ok then
                scriptStatusBtn.Text       = "⚠️ Fetch Error"
                scriptStatusBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
                scriptStatusStroke.Color   = Color3.fromRGB(255, 200, 0)
                return
            end
            if freshResult:find("DEACTIVATED") or freshResult:find("DEAKTIVIERT") then
                scriptStatusBtn.Text       = "🔘 Disabled"
                scriptStatusBtn.TextColor3 = C_DIM
                scriptStatusStroke.Color   = C_ACCENT2
                return
            end
            local freshKeys = {}
            for k in freshResult:gmatch("[^\n]+") do
                local trimmed = k:gsub("%s+", "")
                if trimmed ~= "" then freshKeys[trimmed] = true end
            end
            local changed = false
            for k in pairs(freshKeys) do
                if not lastKnownKeys[k] then changed = true; break end
            end
            if not changed then
                for k in pairs(lastKnownKeys) do
                    if not freshKeys[k] then changed = true; break end
                end
            end
            if changed then
                lastKnownKeys = {}
                for k in pairs(freshKeys) do lastKnownKeys[k] = true end
                scriptStatusBtn.Text       = "☢️ Key Changed"
                scriptStatusBtn.TextColor3 = Color3.fromRGB(255, 100, 0)
                scriptStatusStroke.Color   = Color3.fromRGB(255, 100, 0)
            else
                scriptStatusBtn.Text       = "✅ Script ON"
                scriptStatusBtn.TextColor3 = C_GREEN
                scriptStatusStroke.Color   = C_GREEN
            end
        end)
    end

    refreshStatus()
    task.spawn(function()
        while task.wait(1) do
            refreshStatus()
        end
    end)
end

local fpsLabel = Instance.new("TextLabel", fpsFrame)
fpsLabel.Size = UDim2.new(1, -8, 1, 0)
fpsLabel.Position = UDim2.new(0, 4, 0, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: -- | 00:00"
fpsLabel.TextColor3 = C_GREEN
fpsLabel.TextScaled = true
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.ZIndex = 1000
local fpsConn, fCount, fLast = nil, 0, tick()
local function enableFPS()
    fpsFrame.Visible = true
    fpsConn = RunService.Heartbeat:Connect(function()
        fCount = fCount + 1
        local now = tick()
        if now - fLast >= 1 then
            local fps = math.floor(fCount / (now - fLast))
            local t = os.date("*t")
            fpsLabel.Text = string.format("FPS: %d | %02d:%02d", fps, t.hour, t.min)
            fCount = 0; fLast = now
        end
    end)
end
local function disableFPS()
    fpsFrame.Visible = false
    if fpsConn then fpsConn:Disconnect(); fpsConn = nil end
end

local noclipConn

local function enableNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end
local function disableNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
end

local function enableAimlock()
    aimlockBox.Visible = true
end
local function disableAimlock()
    stopAimlock()
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")
    if myRoot then
        local bv = myRoot:FindFirstChild("AimlockBV")
        local bg = myRoot:FindFirstChild("AimlockBG")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
    aimlockBox.Visible = false
end

local antiRagdollConn, antiRagdollDescConn
local function applyAntiRagdollToChar(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,    false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics,    false)
    end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then v.Enabled = false end
    end
end
local function enableAntiRagdoll()
    applyAntiRagdollToChar(character)
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        local hum  = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,    false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics,    false)
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Physics then
            root.AssemblyLinearVelocity  = Vector3.new(root.AssemblyLinearVelocity.X * 0.05, root.AssemblyLinearVelocity.Y, root.AssemblyLinearVelocity.Z * 0.05)
            root.AssemblyAngularVelocity = Vector3.zero
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
    antiRagdollDescConn = character.DescendantAdded:Connect(function(v)
        if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then v.Enabled = false end
    end)
end
local function disableAntiRagdoll()
    if antiRagdollConn     then antiRagdollConn:Disconnect();     antiRagdollConn     = nil end
    if antiRagdollDescConn then antiRagdollDescConn:Disconnect(); antiRagdollDescConn = nil end
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,    true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics,    true)
    end
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then v.Enabled = true end
    end
end

local antiKbConn
local antiKbPrevVel = Vector3.zero
local function enableAntiKnockback()
    antiKbPrevVel = Vector3.zero
    antiKbConn = RunService.Heartbeat:Connect(function(dt)
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local hum  = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        local vel = root.AssemblyLinearVelocity
        local horzVel = Vector3.new(vel.X, 0, vel.Z)
        local moveVec = hum.MoveDirection
        local isMoving = moveVec.Magnitude > 0.1
        local prevHorz = Vector3.new(antiKbPrevVel.X, 0, antiKbPrevVel.Z)
        local velocityDelta = (horzVel - prevHorz).Magnitude
        local isKnockbackSpike = velocityDelta > 40 and not isMoving
        local st = hum:GetState()
        local isRagdoll = st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown
        if isKnockbackSpike or isRagdoll then
            root.AssemblyLinearVelocity  = Vector3.new(0, vel.Y, 0)
            root.AssemblyAngularVelocity = Vector3.zero
            if isRagdoll then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
        end
        antiKbPrevVel = vel
    end)
end
local function disableAntiKnockback()
    if antiKbConn then antiKbConn:Disconnect(); antiKbConn = nil end
    antiKbPrevVel = Vector3.zero
end

local function enableLeaveButton()  openLeavePopup() end
local function disableLeaveButton()
    leaveGui.Enabled = false
    closeLeavePopup()
end

local antiLagOn        = false
local antiLagAnimConn  = nil
local antiLagNewConn   = nil
local antiLagSaved     = {}

local function stripTextures(instance)
    for _, obj in pairs(instance:GetDescendants()) do
        pcall(function()
            if obj:IsA("GuiObject") or obj:IsA("ScreenGui") or obj:IsA("SelectionBox")
               or obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then return end
            if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
                table.insert(antiLagSaved, {type="parent", obj=obj, parent=obj.Parent})
                obj.Parent = nil
            elseif obj:IsA("SpecialMesh") then
                table.insert(antiLagSaved, {type="mesh", obj=obj, texId=obj.TextureId, meshId=obj.MeshId})
                obj.TextureId = ""
                obj.MeshId    = ""
            elseif obj:IsA("BasePart") then
                table.insert(antiLagSaved, {type="part", obj=obj,
                    mat=obj.Material, ref=obj.Reflectance, shadow=obj.CastShadow})
                obj.Material     = Enum.Material.SmoothPlastic
                obj.Reflectance  = 0
                obj.CastShadow   = false
            elseif obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
                table.insert(antiLagSaved, {type="parent", obj=obj, parent=obj.Parent})
                obj.Parent = nil
            end
        end)
    end
end

local function enableAntiLag()
    antiLagSaved = {}
    antiLagAnimConn = RunService.Heartbeat:Connect(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p == player then continue end
            if p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local anim = hum and hum:FindFirstChildOfClass("Animator")
                if anim then
                    for _, track in pairs(anim:GetPlayingAnimationTracks()) do
                        pcall(function() track:Stop(0) end)
                    end
                end
            end
        end
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Animator") then
                local isOwnChar = character and obj:IsDescendantOf(character)
                if not isOwnChar then
                    pcall(function()
                        for _, track in pairs(obj:GetPlayingAnimationTracks()) do
                            track:Stop(0)
                        end
                    end)
                end
            end
        end
    end)
    if character then
        for _, obj in pairs(character:GetChildren()) do
            pcall(function()
                if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants")
                or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") then
                    table.insert(antiLagSaved, {type="parent", obj=obj, parent=character})
                    obj.Parent = nil
                end
            end)
        end
        stripTextures(character)
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            for _, obj in pairs(p.Character:GetChildren()) do
                pcall(function()
                    if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
                        table.insert(antiLagSaved, {type="parent", obj=obj, parent=p.Character})
                        obj.Parent = nil
                    end
                end)
            end
            stripTextures(p.Character)
        end
    end
    stripTextures(workspace)
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            for _, obj in pairs(terrain:GetChildren()) do
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    table.insert(antiLagSaved, {type="parent", obj=obj, parent=terrain})
                    obj.Parent = nil
                end
            end
        end
    end)
    pcall(function()
        local lighting = game:GetService("Lighting")
        for _, obj in pairs(lighting:GetChildren()) do
            if obj:IsA("PostEffect") or obj:IsA("Sky") or obj:IsA("Atmosphere") then
                table.insert(antiLagSaved, {type="parent", obj=obj, parent=lighting})
                obj.Parent = nil
            end
        end
        table.insert(antiLagSaved, {type="lighting",
            shadowmap  = lighting.GlobalShadows,
            brightness = lighting.Brightness,
            fog        = lighting.FogEnd,
        })
        lighting.GlobalShadows = false
        lighting.Brightness    = 2
        lighting.FogEnd        = 100000
    end)
    antiLagNewConn = workspace.DescendantAdded:Connect(function(obj)
        task.wait()
        pcall(function()
            if obj:IsA("GuiObject") or obj:IsA("ScreenGui") or obj:IsA("SelectionBox")
               or obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then return end
            if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
                obj.Parent = nil
            elseif obj:IsA("SpecialMesh") then
                obj.TextureId = ""; obj.MeshId = ""
            elseif obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0; obj.CastShadow = false
            end
        end)
    end)
end

local function disableAntiLag()
    if antiLagAnimConn then antiLagAnimConn:Disconnect(); antiLagAnimConn = nil end
    if antiLagNewConn  then antiLagNewConn:Disconnect();  antiLagNewConn  = nil end
    for _, data in pairs(antiLagSaved) do
        pcall(function()
            if data.type == "parent" then
                data.obj.Parent = data.parent
            elseif data.type == "mesh" then
                data.obj.TextureId = data.texId; data.obj.MeshId = data.meshId
            elseif data.type == "part" then
                data.obj.Material = data.mat; data.obj.Reflectance = data.ref; data.obj.CastShadow = data.shadow
            elseif data.type == "lighting" then
                local lighting = game:GetService("Lighting")
                lighting.GlobalShadows = data.shadowmap
                lighting.Brightness    = data.brightness
                lighting.FogEnd        = data.fog
            end
        end)
    end
    antiLagSaved = {}
    pcall(function() player:LoadCharacter() end)
end

-- ============================================================
-- AI CHAT FEATURE
-- ============================================================
local aiChatGui = Instance.new("ScreenGui")
aiChatGui.Name = "AIChatGui"
aiChatGui.ResetOnSpawn = false
aiChatGui.IgnoreGuiInset = true
aiChatGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
aiChatGui.Enabled = false
aiChatGui.Parent = player:WaitForChild("PlayerGui")

local aiChatFrame = Instance.new("Frame")
aiChatFrame.Size = UDim2.new(0, 340, 0, 430)
aiChatFrame.Position = UDim2.new(0.5, -170, 0.5, -215)
aiChatFrame.BackgroundColor3 = C_BG_PANEL
aiChatFrame.BackgroundTransparency = TRANS
aiChatFrame.BorderSizePixel = 0
aiChatFrame.ZIndex = 600
aiChatFrame.ClipsDescendants = true
Instance.new("UICorner", aiChatFrame).CornerRadius = UDim.new(0, 14)
local aiChatStroke = Instance.new("UIStroke", aiChatFrame)
aiChatStroke.Color = C_ACCENT
aiChatStroke.Thickness = 2
aiChatFrame.Parent = aiChatGui
makeDraggable(aiChatFrame)

local aiTitleBar = Instance.new("Frame")
aiTitleBar.Size = UDim2.new(1, 0, 0, 40)
aiTitleBar.BackgroundColor3 = C_BG_TITLE
aiTitleBar.BackgroundTransparency = TRANS
aiTitleBar.BorderSizePixel = 0
aiTitleBar.ZIndex = 601
Instance.new("UICorner", aiTitleBar).CornerRadius = UDim.new(0, 14)
aiTitleBar.Parent = aiChatFrame

local aiTitleLbl = Instance.new("TextLabel")
aiTitleLbl.Size = UDim2.new(1, -50, 1, 0)
aiTitleLbl.Position = UDim2.new(0, 12, 0, 0)
aiTitleLbl.BackgroundTransparency = 1
aiTitleLbl.Text = "🤖 MoonBunny AI"
aiTitleLbl.TextColor3 = C_ACCENT
aiTitleLbl.TextScaled = true
aiTitleLbl.Font = Enum.Font.GothamBold
aiTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
aiTitleLbl.ZIndex = 602
aiTitleLbl.Parent = aiTitleBar

local aiOnlineDot = Instance.new("Frame")
aiOnlineDot.Size = UDim2.new(0, 8, 0, 8)
aiOnlineDot.Position = UDim2.new(1, -42, 0.5, -4)
aiOnlineDot.BackgroundColor3 = C_GREEN
aiOnlineDot.BorderSizePixel = 0
aiOnlineDot.ZIndex = 602
Instance.new("UICorner", aiOnlineDot).CornerRadius = UDim.new(1, 0)
aiOnlineDot.Parent = aiTitleBar

local aiCloseBtn = Instance.new("TextButton")
aiCloseBtn.Size = UDim2.new(0, 26, 0, 26)
aiCloseBtn.Position = UDim2.new(1, -30, 0, 7)
aiCloseBtn.Text = "✕"
aiCloseBtn.BackgroundColor3 = C_RED
aiCloseBtn.BackgroundTransparency = TRANS
aiCloseBtn.TextColor3 = Color3.new(1,1,1)
aiCloseBtn.TextScaled = true
aiCloseBtn.Font = Enum.Font.GothamBold
aiCloseBtn.BorderSizePixel = 0
aiCloseBtn.ZIndex = 602
Instance.new("UICorner", aiCloseBtn).CornerRadius = UDim.new(0, 5)
aiCloseBtn.Parent = aiTitleBar

local aiClearBtn = Instance.new("TextButton")
aiClearBtn.Size = UDim2.new(0, 50, 0, 22)
aiClearBtn.Position = UDim2.new(0, 8, 1, 6)
aiClearBtn.Text = "🗑 Clear"
aiClearBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
aiClearBtn.BackgroundTransparency = TRANS
aiClearBtn.TextColor3 = C_DIM
aiClearBtn.TextScaled = true
aiClearBtn.Font = Enum.Font.Gotham
aiClearBtn.BorderSizePixel = 0
aiClearBtn.ZIndex = 602
Instance.new("UICorner", aiClearBtn).CornerRadius = UDim.new(0, 5)
aiClearBtn.Parent = aiChatFrame

local aiScroll = Instance.new("ScrollingFrame")
aiScroll.Size = UDim2.new(1, -12, 1, -106)
aiScroll.Position = UDim2.new(0, 6, 0, 68)
aiScroll.BackgroundTransparency = 1
aiScroll.BorderSizePixel = 0
aiScroll.ScrollBarThickness = 3
aiScroll.ScrollBarImageColor3 = C_ACCENT
aiScroll.ZIndex = 601
aiScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
aiScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
aiScroll.Parent = aiChatFrame

local aiMsgLayout = Instance.new("UIListLayout", aiScroll)
aiMsgLayout.SortOrder = Enum.SortOrder.LayoutOrder
aiMsgLayout.Padding = UDim.new(0, 8)

local aiMsgPad = Instance.new("UIPadding", aiScroll)
aiMsgPad.PaddingTop    = UDim.new(0, 6)
aiMsgPad.PaddingBottom = UDim.new(0, 6)
aiMsgPad.PaddingLeft   = UDim.new(0, 4)
aiMsgPad.PaddingRight  = UDim.new(0, 4)

local welcomeFrame = Instance.new("Frame")
welcomeFrame.Name = "WelcomeMsg"
welcomeFrame.Size = UDim2.new(1, 0, 0, 70)
welcomeFrame.BackgroundColor3 = C_BG_TITLE
welcomeFrame.BackgroundTransparency = 0.3
welcomeFrame.BorderSizePixel = 0
welcomeFrame.ZIndex = 602
welcomeFrame.LayoutOrder = 0
Instance.new("UICorner", welcomeFrame).CornerRadius = UDim.new(0, 10)
welcomeFrame.Parent = aiScroll

local welcomeLbl = Instance.new("TextLabel")
welcomeLbl.Size = UDim2.new(1, -12, 1, 0)
welcomeLbl.Position = UDim2.new(0, 6, 0, 0)
welcomeLbl.BackgroundTransparency = 1
welcomeLbl.Text = "👋 Hei! Ich bin MoonBunny AI\nFrag mich alles – ich helfe dir!"
welcomeLbl.TextColor3 = C_TEXT
welcomeLbl.TextScaled = true
welcomeLbl.Font = Enum.Font.Gotham
welcomeLbl.ZIndex = 603
welcomeLbl.Parent = welcomeFrame

local aiInputBg = Instance.new("Frame")
aiInputBg.Size = UDim2.new(1, -16, 0, 50)
aiInputBg.Position = UDim2.new(0, 8, 1, -58)
aiInputBg.BackgroundColor3 = C_BG_ROW
aiInputBg.BackgroundTransparency = TRANS
aiInputBg.BorderSizePixel = 0
aiInputBg.ZIndex = 602
Instance.new("UICorner", aiInputBg).CornerRadius = UDim.new(0, 10)
local aiInputStroke = Instance.new("UIStroke", aiInputBg)
aiInputStroke.Color = C_ACCENT2
aiInputStroke.Thickness = 1
aiInputStroke.Transparency = 0.4
aiInputBg.Parent = aiChatFrame

local aiInput = Instance.new("TextBox")
aiInput.Size = UDim2.new(1, -58, 1, -14)
aiInput.Position = UDim2.new(0, 10, 0, 7)
aiInput.BackgroundTransparency = 1
aiInput.BorderSizePixel = 0
aiInput.Text = ""
aiInput.PlaceholderText = "Schreib etwas..."
aiInput.TextColor3 = C_TEXT
aiInput.PlaceholderColor3 = C_DIM
aiInput.TextScaled = true
aiInput.Font = Enum.Font.Gotham
aiInput.ClearTextOnFocus = false
aiInput.MultiLine = false
aiInput.ZIndex = 603
aiInput.Parent = aiInputBg

local aiSendBtn = Instance.new("TextButton")
aiSendBtn.Size = UDim2.new(0, 38, 0, 38)
aiSendBtn.Position = UDim2.new(1, -46, 0, 6)
aiSendBtn.Text = "➤"
aiSendBtn.BackgroundColor3 = C_ACCENT
aiSendBtn.BackgroundTransparency = TRANS
aiSendBtn.TextColor3 = Color3.new(1,1,1)
aiSendBtn.TextScaled = true
aiSendBtn.Font = Enum.Font.GothamBold
aiSendBtn.BorderSizePixel = 0
aiSendBtn.ZIndex = 603
Instance.new("UICorner", aiSendBtn).CornerRadius = UDim.new(0, 8)
aiSendBtn.Parent = aiInputBg

local aiMsgCount = 1
local aiIsTyping = false
local aiHistory  = {}

local function aiScrollToBottom()
    task.wait(0.05)
    aiScroll.CanvasPosition = Vector2.new(0, math.huge)
end

local function addAIMessage(text, isUser)
    local welcome = aiScroll:FindFirstChild("WelcomeMsg")
    if welcome then welcome:Destroy() end
    aiMsgCount = aiMsgCount + 1
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.ZIndex = 602
    row.LayoutOrder = aiMsgCount
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.Size = UDim2.new(1, 0, 0, 0)
    row.Parent = aiScroll
    local bubble = Instance.new("TextLabel")
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.Size = UDim2.new(0, 230, 0, 0)
    bubble.BackgroundColor3 = isUser and Color3.fromRGB(13, 31, 80) or Color3.fromRGB(12, 22, 55)
    bubble.BackgroundTransparency = 0.25
    bubble.BorderSizePixel = 0
    bubble.Text = (isUser and "👤  " or "🤖  ") .. text
    bubble.TextColor3 = C_TEXT
    bubble.TextScaled = false
    bubble.TextSize = 13
    bubble.Font = Enum.Font.Gotham
    bubble.TextWrapped = true
    bubble.TextXAlignment = Enum.TextXAlignment.Left
    bubble.ZIndex = 603
    if isUser then bubble.Position = UDim2.new(1, -236, 0, 0) else bubble.Position = UDim2.new(0, 2, 0, 0) end
    local bPad = Instance.new("UIPadding", bubble)
    bPad.PaddingTop    = UDim.new(0, 7)
    bPad.PaddingBottom = UDim.new(0, 7)
    bPad.PaddingLeft   = UDim.new(0, 9)
    bPad.PaddingRight  = UDim.new(0, 9)
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 9)
    local bStroke = Instance.new("UIStroke", bubble)
    bStroke.Color = isUser and C_ACCENT2 or C_ACCENT
    bStroke.Thickness = 1
    bStroke.Transparency = 0.5
    bubble.Parent = row
    aiScrollToBottom()
    return bubble
end

local function removeTypingIndicator()
    local t = aiScroll:FindFirstChild("TypingRow")
    if t then t:Destroy() end
end

local function showTypingIndicator()
    removeTypingIndicator()
    aiMsgCount = aiMsgCount + 1
    local row = Instance.new("Frame")
    row.Name = "TypingRow"
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1
    row.ZIndex = 602
    row.LayoutOrder = aiMsgCount
    row.Parent = aiScroll
    local bubble = Instance.new("TextLabel")
    bubble.Size = UDim2.new(0, 90, 1, 0)
    bubble.BackgroundColor3 = C_BG_TITLE
    bubble.BackgroundTransparency = 0.25
    bubble.BorderSizePixel = 0
    bubble.Text = "🤖  ..."
    bubble.TextColor3 = C_DIM
    bubble.TextScaled = true
    bubble.Font = Enum.Font.Gotham
    bubble.ZIndex = 603
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 9)
    bubble.Parent = row
    aiScrollToBottom()
end

local function getDeltaRequest()
    if typeof(request) == "function" then return request end
    if typeof(http_request) == "function" then return http_request end
    if syn and typeof(syn.request) == "function" then return syn.request end
    return nil
end

local function sendAIMessage()
    if aiIsTyping then return end
    local text = aiInput.Text
    if not text or text:gsub("%s+", "") == "" then return end
    aiInput.Text = ""
    aiIsTyping = true
    aiSendBtn.BackgroundTransparency = 0.75
    aiSendBtn.AutoButtonColor = false
    addAIMessage(text, true)
    table.insert(aiHistory, {role = "user", content = text})
    showTypingIndicator()
    task.spawn(function()
        local systemPrompt = "Du bist MoonBunny AI, ein freundlicher KI-Assistent in einem Roblox-Script. Antworte kurz und freundlich. Deutsch wenn User Deutsch schreibt, Englisch wenn Englisch."
        local messages = {}
        table.insert(messages, {role = "system", content = systemPrompt})
        for _, msg in ipairs(aiHistory) do table.insert(messages, msg) end
        local ok, result = pcall(function()
            local body = HttpService:JSONEncode({model="openai", messages=messages, private=true, seed=math.random(1,99999)})
            local headers = {["Content-Type"] = "application/json"}
            local reqFunc = getDeltaRequest()
            if reqFunc then
                return reqFunc({Url="https://text.pollinations.ai/openai", Method="POST", Headers=headers, Body=body})
            else
                return HttpService:RequestAsync({Url="https://text.pollinations.ai/openai", Method="POST", Headers=headers, Body=body})
            end
        end)
        removeTypingIndicator()
        aiIsTyping = false
        aiSendBtn.BackgroundTransparency = TRANS
        aiSendBtn.AutoButtonColor = true
        if ok and result then
            local statusCode = result.StatusCode or result.status_code or 0
            if statusCode == 200 then
                local parseOk, data = pcall(function() return HttpService:JSONDecode(result.Body or result.body or "") end)
                if parseOk and data and data.choices and data.choices[1] then
                    local reply = data.choices[1].message.content
                    table.insert(aiHistory, {role = "assistant", content = reply})
                    addAIMessage(reply, false)
                else
                    addAIMessage("⚠️ Fehler beim Parsen!", false)
                end
            elseif statusCode == 429 then
                addAIMessage("⏳ Zu viele Anfragen!", false)
            else
                addAIMessage("⚠️ HTTP " .. tostring(statusCode), false)
            end
        else
            addAIMessage("⚠️ Fehler: " .. tostring(result):sub(1,80), false)
        end
    end)
end

aiSendBtn.MouseButton1Click:Connect(sendAIMessage)
aiInput.FocusLost:Connect(function(enter) if enter then sendAIMessage() end end)
aiCloseBtn.MouseButton1Click:Connect(function()
    aiChatGui.Enabled = false
    if featureButtonRefs["ChatGPT 🤖"] then featureButtonRefs["ChatGPT 🤖"].turnOff() end
end)
aiClearBtn.MouseButton1Click:Connect(function()
    for _, child in pairs(aiScroll:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
    end
    aiHistory = {}; aiMsgCount = 1
    local wf = Instance.new("Frame", aiScroll)
    wf.Name = "WelcomeMsg"; wf.Size = UDim2.new(1,0,0,70)
    wf.BackgroundColor3 = C_BG_TITLE; wf.BackgroundTransparency = 0.3
    wf.BorderSizePixel = 0; wf.ZIndex = 602; wf.LayoutOrder = 0
    Instance.new("UICorner", wf).CornerRadius = UDim.new(0,10)
    local wl = Instance.new("TextLabel", wf)
    wl.Size = UDim2.new(1,-12,1,0); wl.Position = UDim2.new(0,6,0,0)
    wl.BackgroundTransparency = 1; wl.Text = "👋 Hei! Ich bin MoonBunny AI\nFrag mich alles – ich helfe dir!"
    wl.TextColor3 = C_TEXT; wl.TextScaled = true; wl.Font = Enum.Font.Gotham; wl.ZIndex = 603
end)

local function enableAIChat()  aiChatGui.Enabled = true; aiInput:CaptureFocus() end
local function disableAIChat() aiChatGui.Enabled = false end

-- ============================================================
-- CRASH YOURSELF FEATURE
-- ============================================================
local crashGui = Instance.new("ScreenGui")
crashGui.Name = "CrashGui"
crashGui.ResetOnSpawn = false
crashGui.IgnoreGuiInset = true
crashGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
crashGui.Enabled = false
crashGui.Parent = player:WaitForChild("PlayerGui")

local crashPopup = Instance.new("Frame")
crashPopup.Size = UDim2.new(0, 360, 0, 180)
crashPopup.AnchorPoint = Vector2.new(0.5, 0.5)
crashPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
crashPopup.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
crashPopup.BackgroundTransparency = 0.1
crashPopup.BorderSizePixel = 0
crashPopup.ZIndex = 800
Instance.new("UICorner", crashPopup).CornerRadius = UDim.new(0, 14)
local crashStroke = Instance.new("UIStroke", crashPopup)
crashStroke.Color = Color3.fromRGB(255, 30, 30)
crashStroke.Thickness = 3
crashPopup.Parent = crashGui

local crashTitle = Instance.new("TextLabel")
crashTitle.Size = UDim2.new(1, -20, 0, 54)
crashTitle.Position = UDim2.new(0, 10, 0, 8)
crashTitle.BackgroundTransparency = 1
crashTitle.Text = "⚠️ DO U WANT TO CRASH YOUR OWN GAME?! ⚠️"
crashTitle.TextColor3 = Color3.fromRGB(255, 50, 50)
crashTitle.TextScaled = true
crashTitle.Font = Enum.Font.GothamBold
crashTitle.ZIndex = 801
crashTitle.Parent = crashPopup

local crashSub = Instance.new("TextLabel")
crashSub.Size = UDim2.new(1, -24, 0, 38)
crashSub.Position = UDim2.new(0, 12, 0, 64)
crashSub.BackgroundTransparency = 1
crashSub.Text = "if you press yes your entire game will freeze and crash\nONLY FOR YOUR GAME!"
crashSub.TextColor3 = Color3.fromRGB(190, 140, 140)
crashSub.TextScaled = true
crashSub.Font = Enum.Font.Gotham
crashSub.ZIndex = 801
crashSub.Parent = crashPopup

local crashYes = Instance.new("TextButton")
crashYes.Size = UDim2.new(0.44, 0, 0, 38)
crashYes.Position = UDim2.new(0.04, 0, 1, -46)
crashYes.Text = "✅ YES CRASH"
crashYes.BackgroundColor3 = Color3.fromRGB(140, 15, 15)
crashYes.BackgroundTransparency = 0.15
crashYes.TextColor3 = Color3.new(1, 1, 1)
crashYes.TextScaled = true
crashYes.Font = Enum.Font.GothamBold
crashYes.BorderSizePixel = 0
crashYes.ZIndex = 802
Instance.new("UICorner", crashYes).CornerRadius = UDim.new(0, 8)
crashYes.Parent = crashPopup

local crashNo = Instance.new("TextButton")
crashNo.Size = UDim2.new(0.44, 0, 0, 38)
crashNo.Position = UDim2.new(0.52, 0, 1, -46)
crashNo.Text = "❌ NO"
crashNo.BackgroundColor3 = Color3.fromRGB(20, 50, 120)
crashNo.BackgroundTransparency = 0.15
crashNo.TextColor3 = Color3.new(1, 1, 1)
crashNo.TextScaled = true
crashNo.Font = Enum.Font.GothamBold
crashNo.BorderSizePixel = 0
crashNo.ZIndex = 802
Instance.new("UICorner", crashNo).CornerRadius = UDim.new(0, 8)
crashNo.Parent = crashPopup

local function runCrashScript()
    local colors = {
        Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(255, 0, 100), Color3.fromRGB(0, 255, 136),
        Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 100, 0),
    }
    for _ = 1, 3 do
        for i = 1, 500000000000000000000000000000000000000000000000000000000000000000000000000000000 do
            local sg = Instance.new("ScreenGui")
            sg.Name = "NeonGui_" .. i
            sg.ResetOnSpawn = false
            sg.Parent = game.Players.LocalPlayer.PlayerGui
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, math.random(80, 280), 0, math.random(40, 120))
            local side = math.random(1, 4)
            if side == 1 then
                frame.Position = UDim2.new(math.random(0,100)/100, 0, -math.random(2,20), 0)
            elseif side == 2 then
                frame.Position = UDim2.new(math.random(2,20), 0, math.random(0,100)/100, 0)
            elseif side == 3 then
                frame.Position = UDim2.new(math.random(0,100)/100, 0, math.random(2,20), 0)
            else
                frame.Position = UDim2.new(-math.random(2,20), 0, math.random(0,100)/100, 0)
            end
            frame.BackgroundColor3 = colors[math.random(1, #colors)]
            frame.BackgroundTransparency = 0.3
            frame.BorderSizePixel = 0
            frame.Parent = sg
        end
    end
end

crashYes.MouseButton1Click:Connect(function()
    crashGui.Enabled = false
    task.spawn(runCrashScript)
end)

crashNo.MouseButton1Click:Connect(function()
    crashGui.Enabled = false
    if featureButtonRefs["CRASH YOURSELF 💀"] then
        featureButtonRefs["CRASH YOURSELF 💀"].turnOff()
    end
end)

local function enableCrash()  crashGui.Enabled = true  end
local function disableCrash() crashGui.Enabled = false end
-- ============================================================

makeFeatureBtn("Godmode",          "❤️",  enableGodmode,       disableGodmode)
makeFeatureBtn("ESP",              "👁️",  enableESP,           disableESP)
makeFeatureBtn("Fly",              "🚀",  enableFly,           disableFly)
makeFeatureBtn("Speed",            "⚡",  enableSpeed,         disableSpeed)
makeFeatureBtn("Infinite Jump",    "🦘",  enableInfJump,       disableInfJump)
makeFeatureBtn("Spin",             "🌀",  enableSpin,          disableSpin)
makeFeatureBtn("Giant",            "👾",  enableGiant,         disableGiant)
makeFeatureBtn("Invisible",        "👻",  enableInvisible,     disableInvisible)
makeFeatureBtn("Rainbow Body",     "🌈",  enableRainbow,       disableRainbow)
makeFeatureBtn("Tracers",          "📡",  enableTracers,       disableTracers)
makeFeatureBtn("FPS + Clock",      "🕐",  enableFPS,           disableFPS)
makeFeatureBtn("Noclip",           "💨",  enableNoclip,        disableNoclip)
makeFeatureBtn("Aimlock",          "🎯",  enableAimlock,       disableAimlock)
makeFeatureBtn("Anti-Ragdoll",     "🛡️",  enableAntiRagdoll,   disableAntiRagdoll)
makeFeatureBtn("Anti-Knockback",   "💥",  enableAntiKnockback, disableAntiKnockback)
makeFeatureBtn("Anti Lag",         "🖥️",  enableAntiLag,       disableAntiLag)
makeFeatureBtn("ChatGPT 🤖",       "🤖",  enableAIChat,        disableAIChat)
makeFeatureBtn("CRASH YOURSELF 💀","💀",  enableCrash,         disableCrash)

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1, -8, 0, 36)
saveBtn.BackgroundColor3 = Color3.fromRGB(10, 50, 30)
saveBtn.BackgroundTransparency = TRANS
saveBtn.BorderSizePixel = 0
saveBtn.Text = "💾 Save"
saveBtn.TextColor3 = C_TEXT
saveBtn.TextScaled = true
saveBtn.Font = Enum.Font.GothamBold
saveBtn.ZIndex = 53
saveBtn.AutoButtonColor = false
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 7)
local saveBtnStroke = Instance.new("UIStroke", saveBtn)
saveBtnStroke.Color = C_GREEN
saveBtnStroke.Thickness = 1
saveBtnStroke.Transparency = 0.5
saveBtn.Parent = scroll

local function saveSettings()
    local data = {}
    for name, ref in pairs(featureButtonRefs) do
        data[name] = ref.getActive()
    end
    persistSave(data)
end

local autoSaveEnabled = false

local function loadSettings()
    local data = persistLoad()
    if not data then return end
    for name, wasOn in pairs(data) do
        if wasOn and featureButtonRefs[name] then
            pcall(function() featureButtonRefs[name].turnOn() end)
            task.wait(0.05)
        end
    end
end

saveBtn.MouseButton1Click:Connect(function()
    saveSettings()
    saveBtn.Text = "Saved ✅"
    saveBtn.BackgroundColor3 = Color3.fromRGB(10, 80, 40)
    task.delay(2, function()
        saveBtn.Text = "💾 Save"
        saveBtn.BackgroundColor3 = Color3.fromRGB(10, 50, 30)
    end)
end)

task.spawn(function()
    task.wait(1)
    loadSettings()
    autoSaveEnabled = true
    for name, ref in pairs(featureButtonRefs) do
        local origTurnOn  = ref.turnOn
        local origTurnOff = ref.turnOff
        ref.turnOn = function()
            origTurnOn()
            if autoSaveEnabled then saveSettings() end
        end
        ref.turnOff = function()
            origTurnOff()
            if autoSaveEnabled then saveSettings() end
        end
    end
end)
end -- end startMainScript

local savedKey = loadSavedKey()
if _player.UserId == 3664472992 or (savedKey and savedKey ~= "" and validKeys[savedKey]) then
    startMainScript()
else
    safeWritefile(KEY_SAVE_FILE, "")
    local keyGui = Instance.new("ScreenGui")
    keyGui.ResetOnSpawn = false
    keyGui.IgnoreGuiInset = true
    keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    keyGui.Parent = _player:WaitForChild("PlayerGui")

    local keyFrame = Instance.new("Frame")
    keyFrame.Size = UDim2.new(0, 320, 0, 160)
    keyFrame.Position = UDim2.new(0.5, -160, 0.5, -80)
    keyFrame.BackgroundColor3 = Color3.fromRGB(8, 15, 35)
    keyFrame.BackgroundTransparency = 0.4
    keyFrame.BorderSizePixel = 0
    Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 12)
    keyFrame.Parent = keyGui

    local keyStroke = Instance.new("UIStroke", keyFrame)
    keyStroke.Color = Color3.fromRGB(80, 130, 255)
    keyStroke.Thickness = 2

    local keyTitle = Instance.new("TextLabel")
    keyTitle.Size = UDim2.new(1, 0, 0, 44)
    keyTitle.BackgroundTransparency = 1
    keyTitle.Text = "🔑 Key eingeben"
    keyTitle.TextColor3 = Color3.fromRGB(80, 130, 255)
    keyTitle.TextScaled = true
    keyTitle.Font = Enum.Font.GothamBold
    keyTitle.Parent = keyFrame

    local keyInput = Instance.new("TextBox")
    keyInput.Size = UDim2.new(0.9, 0, 0, 38)
    keyInput.Position = UDim2.new(0.05, 0, 0.32, 0)
    keyInput.PlaceholderText = "Key hier eingeben..."
    keyInput.BackgroundColor3 = Color3.fromRGB(15, 25, 60)
    keyInput.BackgroundTransparency = 0.4
    keyInput.TextColor3 = Color3.fromRGB(220, 230, 255)
    keyInput.TextScaled = true
    keyInput.Font = Enum.Font.Gotham
    keyInput.BorderSizePixel = 0
    keyInput.ClearTextOnFocus = false
    Instance.new("UICorner", keyInput).CornerRadius = UDim.new(0, 7)
    keyInput.Parent = keyFrame

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0.9, 0, 0, 34)
    keyBtn.Position = UDim2.new(0.05, 0, 0.68, 0)
    keyBtn.Text = "✅ Bestätigen"
    keyBtn.BackgroundColor3 = Color3.fromRGB(10, 80, 40)
    keyBtn.BackgroundTransparency = 0.4
    keyBtn.TextColor3 = Color3.fromRGB(220, 230, 255)
    keyBtn.TextScaled = true
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.BorderSizePixel = 0
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 7)
    keyBtn.Parent = keyFrame

    keyBtn.MouseButton1Click:Connect(function()
        local entered = keyInput.Text:gsub("%s+", "")
        if validKeys[entered] then
            saveKey(entered)
            keyGui:Destroy()
            startMainScript()
        else
            keyTitle.Text = "❌ Falscher Key!"
            keyTitle.TextColor3 = Color3.fromRGB(200, 50, 60)
            task.delay(2, function()
                keyTitle.Text = "🔑 Key eingeben"
                keyTitle.TextColor3 = Color3.fromRGB(80, 130, 255)
            end)
        end
    end)
end
