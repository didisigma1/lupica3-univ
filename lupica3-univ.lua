--[[
    Script: lupica3-univ
    Author: lupica3 - me
    Date: 2026
]]

-- Load library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/didisigma1/lupica3scripts/refs/heads/main/lupica3-univ-lib.lua"))()

-- Variables
local connections = {}
local isUnloaded = false
local espEnabled = false
local espObjects = {}
local player = game.Players.LocalPlayer

-- Skeleton variables
local skeletonEnabled = false
local skeletonColor = Color3.fromRGB(0, 255, 0)
local skeletonThickness = 2
local skeletonTransparency = 1
local skeletonConnections = {}
local skeletonRenderConnection = nil

-- ESP Refresh variables
local espRefreshConnection = nil
local espRefreshTimer = 0
local espRefreshInterval = 0.8

-- Watermark variables
local watermarkEnabled = false
local watermarkColor = Color3.fromRGB(255, 255, 255)
local watermarkUnlocked = false
local watermarkGui = nil
local watermarkFrame = nil
local watermarkTextLabel = nil
local watermarkUpdateConnection = nil
local watermarkPosition = UDim2.new(0.02, 0, 0.02, 0)
local watermarkSizeConnection = nil

-- Combat variables
local hitboxEnabled = false
local hitboxSize = 5
local hitboxConnection = nil

-- Aimbot variables
local aimbotEnabled = false
local aimbotKey = Enum.KeyCode.E
local aimbotMode = "Toggle"
local aimbotTargetPart = "Head"
local aimbotTeamCheck = false
local aimbotFOV = 80
local aimbotFOVColor = Color3.fromRGB(255, 0, 0)
local aimbotFOVCircle = nil
local aimbotFOVVisible = false
local aimbotConnection = nil
local aimbotRenderConnection = nil
local aimbotKeyConnections = {}

-- Movement variables
local infiniteJumpEnabled = false
local walkSpeed = 16

-- Visual Effects variables
local noFogEnabled = false
local noShadowsEnabled = false
local fullBrightEnabled = false

-- Config variables
local configEditorVisible = false
local configEditorGui = nil
local configEditorFrame = nil
local configTextbox = nil
local configStatusLabel = nil

-- ==================== FUNKCJA DRAGIFY Z LIB.LUA ====================
local function WatermarkDragify(frame, parent)
    parent = parent or frame

    local dragging = false
    local dragInput, mousePos, framePos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if watermarkEnabled and watermarkUnlocked then
                dragging = true
                mousePos = input.Position
                framePos = parent.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            parent.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
            watermarkPosition = parent.Position
        end
    end)
end

-- ==================== FUNKCJA DO NATYCHMIASTOWEJ AKTUALIZACJI ESP ====================
function RefreshESPNOW()
    if espEnabled then
        ClearESP()
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr ~= player then
                CreatePlayerESP(plr)
            end
        end
    end
end

-- ==================== FUNKCJE HITBOX EXPANDER ====================
function ToggleHitbox(state)
    hitboxEnabled = state
    if hitboxConnection then
        hitboxConnection:Disconnect()
        hitboxConnection = nil
    end
    
    if state then
        hitboxConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if not hitboxEnabled then return end
            for _, plr in pairs(game.Players:GetPlayers()) do
                if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local root = plr.Character.HumanoidRootPart
                    root.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    root.Transparency = 0.8
                    root.CanCollide = false
                end
            end
        end)
        table.insert(connections, hitboxConnection)
    end
end

function SetHitboxSize(size)
    hitboxSize = size
    if hitboxEnabled then
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local root = plr.Character.HumanoidRootPart
                root.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
            end
        end
    end
end

-- ==================== FUNKCJE AIMBOT ====================
function CreateAimbotFOV()
    if aimbotFOVCircle then
        aimbotFOVCircle:Remove()
        aimbotFOVCircle = nil
    end
    
    aimbotFOVCircle = Drawing.new("Circle")
    aimbotFOVCircle.Color = aimbotFOVColor
    aimbotFOVCircle.Thickness = 2
    aimbotFOVCircle.Radius = aimbotFOV
    aimbotFOVCircle.Filled = false
    aimbotFOVCircle.Visible = aimbotFOVVisible
    aimbotFOVCircle.Transparency = 0.5
    aimbotFOVCircle.NumSides = 60
    aimbotFOVCircle.Position = workspace.CurrentCamera.ViewportSize / 2
end

function UpdateAimbotFOV()
    if aimbotFOVCircle then
        aimbotFOVCircle.Radius = aimbotFOV
        aimbotFOVCircle.Color = aimbotFOVColor
        aimbotFOVCircle.Visible = aimbotFOVVisible
        aimbotFOVCircle.Position = workspace.CurrentCamera.ViewportSize / 2
    end
end

function ClearAimbotKeyConnections()
    for _, conn in ipairs(aimbotKeyConnections) do
        pcall(function() conn:Disconnect() end)
    end
    aimbotKeyConnections = {}
end

function ToggleAimbot(state)
    aimbotEnabled = state
    
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    
    if aimbotRenderConnection then
        aimbotRenderConnection:Disconnect()
        aimbotRenderConnection = nil
    end
    
    ClearAimbotKeyConnections()
    
    if state then
        CreateAimbotFOV()
        StartAimbot()
    else
        if aimbotFOVCircle then
            aimbotFOVCircle.Visible = false
        end
    end
end

function StartAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    
    if aimbotRenderConnection then
        aimbotRenderConnection:Disconnect()
        aimbotRenderConnection = nil
    end
    
    ClearAimbotKeyConnections()
    
    local UserInputService = game:GetService("UserInputService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = game.Players.LocalPlayer
    
    local isHolding = false
    local isToggled = false
    
    local beganConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        local keyMatches = false
        if typeof(aimbotKey) == "EnumItem" and input.KeyCode == aimbotKey then
            keyMatches = true
        elseif typeof(aimbotKey) == "EnumItem" and input.UserInputType == aimbotKey then
            keyMatches = true
        end
        
        if keyMatches then
            if aimbotMode == "Toggle" then
                isToggled = not isToggled
            elseif aimbotMode == "Hold" then
                isHolding = true
            end
        end
    end)
    table.insert(aimbotKeyConnections, beganConn)
    
    local endedConn = UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end
        
        local keyMatches = false
        if typeof(aimbotKey) == "EnumItem" and input.KeyCode == aimbotKey then
            keyMatches = true
        elseif typeof(aimbotKey) == "EnumItem" and input.UserInputType == aimbotKey then
            keyMatches = true
        end
        
        if keyMatches and aimbotMode == "Hold" then
            isHolding = false
        end
    end)
    table.insert(aimbotKeyConnections, endedConn)
    
    aimbotRenderConnection = game:GetService("RunService").RenderStepped:Connect(function()
        local shouldLock = false
        if aimbotMode == "Toggle" then
            shouldLock = isToggled and aimbotEnabled
        elseif aimbotMode == "Hold" then
            shouldLock = isHolding and aimbotEnabled
        end
        
        if aimbotFOVCircle then
            aimbotFOVCircle.Position = Camera.ViewportSize / 2
            aimbotFOVCircle.Visible = aimbotFOVVisible and aimbotEnabled
        end
        
        if not shouldLock then return end
        
        local target = nil
        local closestDistance = aimbotFOV
        local screenCenter = Camera.ViewportSize / 2
        
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local targetPart = plr.Character:FindFirstChild(aimbotTargetPart)
                local humanoid = plr.Character:FindFirstChild("Humanoid")
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if targetPart and humanoid and humanoid.Health > 0 and myRoot then
                    if aimbotTeamCheck and plr.Team == LocalPlayer.Team then
                        continue
                    end
                    
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if distance < closestDistance then
                            closestDistance = distance
                            target = targetPart
                        end
                    end
                end
            end
        end
        
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end)
    table.insert(connections, aimbotRenderConnection)
end

function StopAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    
    if aimbotRenderConnection then
        aimbotRenderConnection:Disconnect()
        aimbotRenderConnection = nil
    end
    
    ClearAimbotKeyConnections()
    
    if aimbotFOVCircle then
        aimbotFOVCircle:Remove()
        aimbotFOVCircle = nil
    end
end

-- ==================== FUNKCJE MOVEMENT ====================
function ToggleInfiniteJump(state)
    infiniteJumpEnabled = state
end

function SetWalkSpeed(speed)
    walkSpeed = speed
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = walkSpeed
        end
    end
end

local function SetupInfiniteJump()
    local UserInputService = game:GetService("UserInputService")
    local jumpConnection = UserInputService.JumpRequest:Connect(function()
        if infiniteJumpEnabled then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState("Jumping")
                end
            end
        end
    end)
    table.insert(connections, jumpConnection)
end

local function SetupWalkSpeed()
    local function ApplyWalkSpeed()
        local char = player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = walkSpeed
            end
        end
    end
    
    local charAddedConn = player.CharacterAdded:Connect(function()
        task.wait(0.1)
        ApplyWalkSpeed()
    end)
    table.insert(connections, charAddedConn)
    
    local heartbeatConn = game:GetService("RunService").Heartbeat:Connect(function()
        if walkSpeed ~= 16 then
            local char = player.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum and hum.WalkSpeed ~= walkSpeed then
                    hum.WalkSpeed = walkSpeed
                end
            end
        end
    end)
    table.insert(connections, heartbeatConn)
end

-- ==================== FUNKCJE EFEKTÓW WIZUALNYCH ====================
function ToggleNoFog(state)
    noFogEnabled = state
    local lighting = game:GetService("Lighting")
    
    if state then
        lighting.FogEnd = 999999
        lighting.FogStart = 0
    else
        lighting.FogEnd = 1000
        lighting.FogStart = 0
    end
end

function ToggleNoShadows(state)
    noShadowsEnabled = state
    local lighting = game:GetService("Lighting")
    
    if state then
        lighting.ShadowSoftness = 0
        lighting.Brightness = 2
        lighting.GlobalShadows = false
    else
        lighting.ShadowSoftness = 1
        lighting.Brightness = 1
        lighting.GlobalShadows = true
    end
end

function ToggleFullBright(state)
    fullBrightEnabled = state
    local lighting = game:GetService("Lighting")
    
    if state then
        lighting.Brightness = 10
        lighting.Ambient = Color3.fromRGB(255, 255, 255)
        lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        lighting.Brightness = 1
        lighting.Ambient = Color3.fromRGB(127, 127, 127)
        lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    end
end

-- ==================== FUNKCJE SYSTEMU CONFIGÓW ====================
function GetCurrentConfig()
    local config = {
        -- Ratio
        currentRatio = currentRatio,
        
        -- ESP Settings
        espEnabled = espEnabled,
        teamCheckEnabled = teamCheckEnabled,
        showOutline = showOutline,
        showFill = showFill,
        showNicknames = showNicknames,
        showHealth = showHealth,
        
        -- ESP Colors
        teamOutlineColor = {teamOutlineColor.R, teamOutlineColor.G, teamOutlineColor.B},
        teamFillColor = {teamFillColor.R, teamFillColor.G, teamFillColor.B},
        enemyOutlineColor = {enemyOutlineColor.R, enemyOutlineColor.G, enemyOutlineColor.B},
        enemyFillColor = {enemyFillColor.R, enemyFillColor.G, enemyFillColor.B},
        nicknameColor = {nicknameColor.R, nicknameColor.G, nicknameColor.B},
        
        -- Skeleton
        skeletonEnabled = skeletonEnabled,
        skeletonColor = {skeletonColor.R, skeletonColor.G, skeletonColor.B},
        
        -- Combat
        hitboxEnabled = hitboxEnabled,
        hitboxSize = hitboxSize,
        
        -- Aimbot
        aimbotEnabled = aimbotEnabled,
        aimbotKey = tostring(aimbotKey),
        aimbotMode = aimbotMode,
        aimbotTargetPart = aimbotTargetPart,
        aimbotTeamCheck = aimbotTeamCheck,
        aimbotFOV = aimbotFOV,
        aimbotFOVColor = {aimbotFOVColor.R, aimbotFOVColor.G, aimbotFOVColor.B},
        aimbotFOVVisible = aimbotFOVVisible,
        
        -- Movement
        infiniteJumpEnabled = infiniteJumpEnabled,
        walkSpeed = walkSpeed,
        
        -- Visual Effects
        noFogEnabled = noFogEnabled,
        noShadowsEnabled = noShadowsEnabled,
        fullBrightEnabled = fullBrightEnabled,
        
        -- Watermark
        watermarkEnabled = watermarkEnabled,
        watermarkColor = {watermarkColor.R, watermarkColor.G, watermarkColor.B},
        watermarkPosition = {watermarkPosition.X.Scale, watermarkPosition.X.Offset, watermarkPosition.Y.Scale, watermarkPosition.Y.Offset}
    }
    
    return game:GetService("HttpService"):JSONEncode(config)
end

function LoadConfig(jsonString)
    if not jsonString or jsonString == "" then return false end
    
    local data = game:GetService("HttpService"):JSONDecode(jsonString)
    if not data then return false end
    
    -- Ratio
    if data.currentRatio then
        currentRatio = data.currentRatio
    end
    
    -- ESP Settings
    espEnabled = data.espEnabled or false
    teamCheckEnabled = data.teamCheckEnabled or false
    showOutline = data.showOutline or false
    showFill = data.showFill or false
    showNicknames = data.showNicknames or false
    showHealth = data.showHealth or false
    
    -- ESP Colors
    if data.teamOutlineColor then
        teamOutlineColor = Color3.new(data.teamOutlineColor[1], data.teamOutlineColor[2], data.teamOutlineColor[3])
    end
    if data.teamFillColor then
        teamFillColor = Color3.new(data.teamFillColor[1], data.teamFillColor[2], data.teamFillColor[3])
    end
    if data.enemyOutlineColor then
        enemyOutlineColor = Color3.new(data.enemyOutlineColor[1], data.enemyOutlineColor[2], data.enemyOutlineColor[3])
    end
    if data.enemyFillColor then
        enemyFillColor = Color3.new(data.enemyFillColor[1], data.enemyFillColor[2], data.enemyFillColor[3])
    end
    if data.nicknameColor then
        nicknameColor = Color3.new(data.nicknameColor[1], data.nicknameColor[2], data.nicknameColor[3])
    end
    
    -- Skeleton
    if data.skeletonEnabled ~= nil then
        skeletonEnabled = data.skeletonEnabled
    end
    if data.skeletonColor then
        skeletonColor = Color3.new(data.skeletonColor[1], data.skeletonColor[2], data.skeletonColor[3])
    end
    
    -- Combat
    if data.hitboxEnabled ~= nil then
        hitboxEnabled = data.hitboxEnabled
    end
    if data.hitboxSize then
        hitboxSize = data.hitboxSize
    end
    
    -- Aimbot
    if data.aimbotEnabled ~= nil then
        aimbotEnabled = data.aimbotEnabled
    end
    if data.aimbotKey then
        pcall(function()
            aimbotKey = Enum.KeyCode[data.aimbotKey]
        end)
    end
    if data.aimbotMode then
        aimbotMode = data.aimbotMode
    end
    if data.aimbotTargetPart then
        aimbotTargetPart = data.aimbotTargetPart
    end
    if data.aimbotTeamCheck ~= nil then
        aimbotTeamCheck = data.aimbotTeamCheck
    end
    if data.aimbotFOV then
        aimbotFOV = data.aimbotFOV
    end
    if data.aimbotFOVColor then
        aimbotFOVColor = Color3.new(data.aimbotFOVColor[1], data.aimbotFOVColor[2], data.aimbotFOVColor[3])
    end
    if data.aimbotFOVVisible ~= nil then
        aimbotFOVVisible = data.aimbotFOVVisible
    end
    
    -- Movement
    if data.infiniteJumpEnabled ~= nil then
        infiniteJumpEnabled = data.infiniteJumpEnabled
    end
    if data.walkSpeed then
        walkSpeed = data.walkSpeed
    end
    
    -- Visual Effects
    if data.noFogEnabled ~= nil then
        noFogEnabled = data.noFogEnabled
    end
    if data.noShadowsEnabled ~= nil then
        noShadowsEnabled = data.noShadowsEnabled
    end
    if data.fullBrightEnabled ~= nil then
        fullBrightEnabled = data.fullBrightEnabled
    end
    
    -- Watermark
    if data.watermarkEnabled ~= nil then
        watermarkEnabled = data.watermarkEnabled
    end
    if data.watermarkColor then
        watermarkColor = Color3.new(data.watermarkColor[1], data.watermarkColor[2], data.watermarkColor[3])
    end
    if data.watermarkPosition then
        watermarkPosition = UDim2.new(
            data.watermarkPosition[1],
            data.watermarkPosition[2],
            data.watermarkPosition[3],
            data.watermarkPosition[4]
        )
    end
    
    -- Apply all settings
    if espEnabled then
        StartESPRefresh()
    else
        StopESPRefresh()
        ClearESP()
    end
    
    if skeletonEnabled then
        StartSkeletonESP()
    else
        StopSkeletonESP()
    end
    
    if hitboxEnabled then
        ToggleHitbox(true)
    else
        ToggleHitbox(false)
    end
    
    if aimbotEnabled then
        ToggleAimbot(true)
    else
        ToggleAimbot(false)
    end
    
    if watermarkEnabled then
        ToggleWatermark(true)
    else
        ToggleWatermark(false)
    end
    
    if noFogEnabled then
        ToggleNoFog(true)
    else
        ToggleNoFog(false)
    end
    
    if noShadowsEnabled then
        ToggleNoShadows(true)
    else
        ToggleNoShadows(false)
    end
    
    if fullBrightEnabled then
        ToggleFullBright(true)
    else
        ToggleFullBright(false)
    end
    
    SetWalkSpeed(walkSpeed)
    
    RefreshESPNOW()
    UpdateAimbotFOV()
    UpdateWatermarkSize()
    
    return true
end

-- ==================== CONFIG EDITOR GUI ====================
function ToggleConfigEditor(state)
    configEditorVisible = state
    
    if state then
        if configEditorGui then
            configEditorGui:Destroy()
            configEditorGui = nil
        end
        
        configEditorGui = Instance.new("ScreenGui")
        configEditorGui.Name = "ConfigEditor"
        configEditorGui.Parent = game.CoreGui
        configEditorGui.ResetOnSpawn = false
        
        configEditorFrame = Instance.new("Frame")
        configEditorFrame.Name = "ConfigEditorFrame"
        configEditorFrame.Parent = configEditorGui
        configEditorFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        configEditorFrame.BorderSizePixel = 0
        configEditorFrame.Size = UDim2.new(0, 500, 0, 400)
        configEditorFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
        configEditorFrame.Active = true
        configEditorFrame.Draggable = true
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 8)
        frameCorner.Parent = configEditorFrame
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Parent = configEditorFrame
        title.Size = UDim2.new(1, 0, 0, 40)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        title.BorderSizePixel = 0
        title.Text = "Config Editor"
        title.TextColor3 = Color3.fromRGB(220, 220, 230)
        title.TextSize = 20
        title.Font = Enum.Font.GothamBold
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 8)
        titleCorner.Parent = title
        
        -- Close button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Parent = configEditorFrame
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.Position = UDim2.new(1, -40, 0, 5)
        closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "X"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextSize = 16
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.MouseButton1Click:Connect(function()
            ToggleConfigEditor(false)
        end)
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 4)
        closeCorner.Parent = closeBtn
        
        -- Status label
        configStatusLabel = Instance.new("TextLabel")
        configStatusLabel.Parent = configEditorFrame
        configStatusLabel.Size = UDim2.new(0.9, 0, 0, 30)
        configStatusLabel.Position = UDim2.new(0.05, 0, 0.12, 0)
        configStatusLabel.BackgroundTransparency = 1
        configStatusLabel.Text = "Ready"
        configStatusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
        configStatusLabel.TextSize = 14
        configStatusLabel.Font = Enum.Font.Gotham
        configStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Save Config Button
        local saveBtn = Instance.new("TextButton")
        saveBtn.Parent = configEditorFrame
        saveBtn.Size = UDim2.new(0, 120, 0, 40)
        saveBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
        saveBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        saveBtn.BorderSizePixel = 0
        saveBtn.Text = "Save Config"
        saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        saveBtn.TextSize = 14
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.MouseButton1Click:Connect(function()
            local config = GetCurrentConfig()
            configTextbox.Text = config
            configStatusLabel.Text = "✅ Config generated! Copy it manually."
            configStatusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
        end)
        
        local saveCorner = Instance.new("UICorner")
        saveCorner.CornerRadius = UDim.new(0, 4)
        saveCorner.Parent = saveBtn
        
        -- Load Config Button
        local loadBtn = Instance.new("TextButton")
        loadBtn.Parent = configEditorFrame
        loadBtn.Size = UDim2.new(0, 120, 0, 40)
        loadBtn.Position = UDim2.new(0.05, 0, 0.3, 0)
        loadBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 200)
        loadBtn.BorderSizePixel = 0
        loadBtn.Text = "Load Config"
        loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        loadBtn.TextSize = 14
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.MouseButton1Click:Connect(function()
            local json = configTextbox.Text
            if json and json ~= "" then
                local success = LoadConfig(json)
                if success then
                    configStatusLabel.Text = "✅ Config loaded successfully!"
                    configStatusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
                else
                    configStatusLabel.Text = "❌ Invalid config! Check the format."
                    configStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                end
            else
                configStatusLabel.Text = "❌ Paste a config first!"
                configStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end)
        
        local loadCorner = Instance.new("UICorner")
        loadCorner.CornerRadius = UDim.new(0, 4)
        loadCorner.Parent = loadBtn
        
        -- Config Textbox
        configTextbox = Instance.new("TextBox")
        configTextbox.Parent = configEditorFrame
        configTextbox.Size = UDim2.new(0.9, 0, 0.45, 0)
        configTextbox.Position = UDim2.new(0.05, 0, 0.4, 0)
        configTextbox.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        configTextbox.BorderSizePixel = 0
        configTextbox.Text = ""
        configTextbox.TextColor3 = Color3.fromRGB(180, 180, 190)
        configTextbox.TextSize = 12
        configTextbox.Font = Enum.Font.Code
        configTextbox.TextWrapped = true
        configTextbox.TextXAlignment = Enum.TextXAlignment.Left
        configTextbox.TextYAlignment = Enum.TextYAlignment.Top
        configTextbox.MultiLine = true
        configTextbox.ClearTextOnFocus = false
        
        local textboxCorner = Instance.new("UICorner")
        textboxCorner.CornerRadius = UDim.new(0, 4)
        textboxCorner.Parent = configTextbox
    else
        if configEditorGui then
            configEditorGui:Destroy()
            configEditorGui = nil
            configEditorFrame = nil
            configTextbox = nil
            configStatusLabel = nil
        end
    end
end

-- Main window
local Window = Library:Window({
    text = "lupica3-univ"
})

-- Tab section
local TabSection = Window:TabSection({
    text = "Menu"
})

-- ==================== ZMIANA STYLU NA CIEMNY SZARO-CZARNY ====================
task.wait(0.1)
pcall(function()
    for _, v in pairs(game.CoreGui:GetDescendants()) do
        if v:IsA("Frame") or v:IsA("TextLabel") or v:IsA("TextButton") then
            if v.Name == "Body" then
                v.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
            elseif v.Name == "SideBar" then
                v.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            elseif v.Name == "sectionFrame" then
                v.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
            elseif v.Name == "sbLine" or v.Name == "tbLine" or v.Name == "sLine" then
                v.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            elseif v:IsA("TextLabel") and v.Name == "Title" then
                v.TextColor3 = Color3.fromRGB(220, 220, 230)
            elseif v:IsA("TextButton") and v.Name == "tabButton" then
                v.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                v.TextColor3 = Color3.fromRGB(200, 200, 210)
            elseif v:IsA("TextLabel") and v.Name == "sectionLabel" then
                v.TextColor3 = Color3.fromRGB(200, 200, 210)
            elseif v:IsA("TextLabel") and v.Name == "tabSectionLabel" then
                v.TextColor3 = Color3.fromRGB(130, 130, 140)
            end
        end
    end
end)

-- VISUALS TAB
local VisualsTab = TabSection:Tab({
    text = "Visuals",
    icon = "rbxassetid://7999345313",
})

-- ==================== RATIO CHANGER ====================
local RatioSection = VisualsTab:Section({
    text = "Ratio Changer"
})

local currentRatio = 1
local ratioConnection = nil
local ratioValues = {"0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9", "1.0"}

RatioSection:Dropdown({
    text = "Ratio Changer",
    list = ratioValues,
    default = "1.0",
    callback = function(selected)
        currentRatio = tonumber(selected)
        
        if ratioConnection then
            ratioConnection:Disconnect()
            ratioConnection = nil
        end
        
        local Camera = workspace.CurrentCamera
        ratioConnection = game:GetService("RunService").RenderStepped:Connect(function()
            Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, currentRatio, 0, 0, 0, 1)
        end)
        
        if not isUnloaded then
            table.insert(connections, ratioConnection)
        end
    end
})

-- ==================== PLAYER ESP ====================
local PlayerESPSection = VisualsTab:Section({
    text = "Player ESP"
})

-- Main ESP toggle
local teamCheckEnabled = false
local showOutline = false
local showFill = false
local showNicknames = false
local showHealth = false

-- Colors
local teamOutlineColor = Color3.fromRGB(0, 255, 0)
local teamFillColor = Color3.fromRGB(0, 255, 0)
local enemyOutlineColor = Color3.fromRGB(255, 0, 0)
local enemyFillColor = Color3.fromRGB(255, 0, 0)
local nicknameColor = Color3.fromRGB(255, 255, 255)

PlayerESPSection:Toggle({
    text = "Player ESP",
    state = false,
    callback = function(state)
        espEnabled = state
        if state then
            StartESPRefresh()
        else
            StopESPRefresh()
            ClearESP()
        end
    end
})

-- Team Check
PlayerESPSection:Toggle({
    text = "Team Check",
    state = false,
    callback = function(state)
        teamCheckEnabled = state
        RefreshESPNOW()
    end
})

-- ==================== OUTLINE SECTION ====================
local OutlineSection = VisualsTab:Section({
    text = "Outline"
})

OutlineSection:Toggle({
    text = "Outline",
    state = false,
    callback = function(state)
        showOutline = state
        RefreshESPNOW()
    end
})

OutlineSection:Colorpicker({
    text = "Team - Outline Color",
    color = teamOutlineColor,
    callback = function(color)
        teamOutlineColor = color
        RefreshESPNOW()
    end
})

OutlineSection:Colorpicker({
    text = "Enemy - Outline Color",
    color = enemyOutlineColor,
    callback = function(color)
        enemyOutlineColor = color
        RefreshESPNOW()
    end
})

-- ==================== FILL SECTION ====================
local FillSection = VisualsTab:Section({
    text = "Fill"
})

FillSection:Toggle({
    text = "Fill",
    state = false,
    callback = function(state)
        showFill = state
        RefreshESPNOW()
    end
})

FillSection:Colorpicker({
    text = "Team - Fill Color",
    color = teamFillColor,
    callback = function(color)
        teamFillColor = color
        RefreshESPNOW()
    end
})

FillSection:Colorpicker({
    text = "Enemy - Fill Color",
    color = enemyFillColor,
    callback = function(color)
        enemyFillColor = color
        RefreshESPNOW()
    end
})

-- ==================== NICKNAME SECTION ====================
local NicknameSection = VisualsTab:Section({
    text = "Nickname"
})

NicknameSection:Toggle({
    text = "Nicknames",
    state = false,
    callback = function(state)
        showNicknames = state
        RefreshESPNOW()
    end
})

NicknameSection:Colorpicker({
    text = "Nickname Color",
    color = nicknameColor,
    callback = function(color)
        nicknameColor = color
        RefreshESPNOW()
    end
})

-- ==================== HEALTH SECTION ====================
local HealthSection = VisualsTab:Section({
    text = "Health Bar"
})

HealthSection:Toggle({
    text = "Health Bar",
    state = false,
    callback = function(state)
        showHealth = state
        RefreshESPNOW()
    end
})

-- ==================== SKELETON SECTION ====================
local SkeletonSection = VisualsTab:Section({
    text = "Skeleton"
})

SkeletonSection:Toggle({
    text = "Skeleton ESP",
    state = false,
    callback = function(state)
        skeletonEnabled = state
        if state then
            StartSkeletonESP()
        else
            StopSkeletonESP()
        end
    end
})

SkeletonSection:Colorpicker({
    text = "Skeleton Color",
    color = skeletonColor,
    callback = function(color)
        skeletonColor = color
        if skeletonEnabled then
            for _, data in pairs(skeletonConnections) do
                for _, line in pairs(data.lines) do
                    if line then
                        line.Color = skeletonColor
                    end
                end
            end
        end
    end
})

-- ==================== COMBAT TAB ====================
local CombatTab = TabSection:Tab({
    text = "Combat",
    icon = "rbxassetid://7999345313",
})

-- ==================== HITBOX EXPANDER ====================
local HitboxSection = CombatTab:Section({
    text = "Hitbox Expander"
})

local hitboxValues = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"}

HitboxSection:Dropdown({
    text = "Hitbox Size",
    list = hitboxValues,
    default = "5",
    callback = function(selected)
        SetHitboxSize(tonumber(selected))
    end
})

HitboxSection:Toggle({
    text = "Hitbox Expander",
    state = false,
    callback = function(state)
        ToggleHitbox(state)
    end
})

-- ==================== AIMBOT SECTION ====================
local AimbotSection = CombatTab:Section({
    text = "Aimbot"
})

AimbotSection:Toggle({
    text = "Aimbot",
    state = false,
    callback = function(state)
        ToggleAimbot(state)
    end
})

local keyOptions = {"E", "Q", "R", "T", "F", "G", "C", "X", "Z", "V", "LeftControl", "RightControl", "LeftShift", "RightShift", "MouseButton1", "MouseButton2"}
AimbotSection:Dropdown({
    text = "Activation Key",
    list = keyOptions,
    default = "E",
    callback = function(selected)
        if selected == "LeftControl" then
            aimbotKey = Enum.KeyCode.LeftControl
        elseif selected == "RightControl" then
            aimbotKey = Enum.KeyCode.RightControl
        elseif selected == "LeftShift" then
            aimbotKey = Enum.KeyCode.LeftShift
        elseif selected == "RightShift" then
            aimbotKey = Enum.KeyCode.RightShift
        elseif selected == "MouseButton1" then
            aimbotKey = Enum.UserInputType.MouseButton1
        elseif selected == "MouseButton2" then
            aimbotKey = Enum.UserInputType.MouseButton2
        else
            aimbotKey = Enum.KeyCode[selected]
        end
    end
})

AimbotSection:Dropdown({
    text = "Mode",
    list = {"Toggle", "Hold"},
    default = "Toggle",
    callback = function(selected)
        aimbotMode = selected
    end
})

AimbotSection:Dropdown({
    text = "Target Part",
    list = {"Head", "Torso"},
    default = "Head",
    callback = function(selected)
        if selected == "Head" then
            aimbotTargetPart = "Head"
        else
            aimbotTargetPart = "HumanoidRootPart"
        end
    end
})

AimbotSection:Toggle({
    text = "Team Check",
    state = false,
    callback = function(state)
        aimbotTeamCheck = state
    end
})

local fovValues = {"10", "20", "30", "40", "50", "60", "70", "80", "90", "100", "120", "130", "140", "150"}
AimbotSection:Dropdown({
    text = "FOV Size",
    list = fovValues,
    default = "80",
    callback = function(selected)
        aimbotFOV = tonumber(selected)
        UpdateAimbotFOV()
    end
})

AimbotSection:Colorpicker({
    text = "FOV Color",
    color = aimbotFOVColor,
    callback = function(color)
        aimbotFOVColor = color
        UpdateAimbotFOV()
    end
})

AimbotSection:Toggle({
    text = "Show FOV",
    state = false,
    callback = function(state)
        aimbotFOVVisible = state
        UpdateAimbotFOV()
    end
})

-- ==================== MOVEMENT TAB ====================
local MovementTab = TabSection:Tab({
    text = "Movement",
    icon = "rbxassetid://7999345313",
})

local MovementSection = MovementTab:Section({
    text = "Movement Options"
})

-- WalkSpeed Dropdown
local walkSpeedValues = {"10", "20", "30", "40", "50", "60", "70", "80", "90", "100"}
MovementSection:Dropdown({
    text = "WalkSpeed",
    list = walkSpeedValues,
    default = "16",
    callback = function(selected)
        SetWalkSpeed(tonumber(selected))
    end
})

-- Infinite Jump Toggle
MovementSection:Toggle({
    text = "Infinite Jump",
    state = false,
    callback = function(state)
        ToggleInfiniteJump(state)
    end
})

-- ==================== SKELETON ESP FUNCTIONS ====================
local function createLine()
    local line = Drawing.new("Line")
    line.Thickness = skeletonThickness
    line.Transparency = skeletonTransparency
    line.Color = skeletonColor
    line.Visible = false
    return line
end

local function GetJoints(character)
    local humanoid = character:FindFirstChild("Humanoid")
    local joints = {}
    
    if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
        joints = {
            Head = character:FindFirstChild("Head"),
            UpperTorso = character:FindFirstChild("UpperTorso"),
            LowerTorso = character:FindFirstChild("LowerTorso"),
            LeftUpperArm = character:FindFirstChild("LeftUpperArm"),
            LeftLowerArm = character:FindFirstChild("LeftLowerArm"),
            LeftHand = character:FindFirstChild("LeftHand"),
            RightUpperArm = character:FindFirstChild("RightUpperArm"),
            RightLowerArm = character:FindFirstChild("RightLowerArm"),
            RightHand = character:FindFirstChild("RightHand"),
            LeftUpperLeg = character:FindFirstChild("LeftUpperLeg"),
            LeftLowerLeg = character:FindFirstChild("LeftLowerLeg"),
            LeftFoot = character:FindFirstChild("LeftFoot"),
            RightUpperLeg = character:FindFirstChild("RightUpperLeg"),
            RightLowerLeg = character:FindFirstChild("RightLowerLeg"),
            RightFoot = character:FindFirstChild("RightFoot"),
        }
    elseif humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
        joints = {
            Head = character:FindFirstChild("Head"),
            Torso = character:FindFirstChild("Torso"),
            LeftLeg = character:FindFirstChild("Left Leg"),
            RightLeg = character:FindFirstChild("Right Leg"),
            LeftArm = character:FindFirstChild("Left Arm"),
            RightArm = character:FindFirstChild("Right Arm"),
        }
    end
    
    return joints, humanoid
end

local function GetConnections(humanoid)
    if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
        return {
            { "Head", "UpperTorso" },
            { "UpperTorso", "LowerTorso" },
            { "LowerTorso", "LeftUpperLeg" },
            { "LeftUpperLeg", "LeftLowerLeg" },
            { "LeftLowerLeg", "LeftFoot" },
            { "LowerTorso", "RightUpperLeg" },
            { "RightUpperLeg", "RightLowerLeg" },
            { "RightLowerLeg", "RightFoot" },
            { "UpperTorso", "LeftUpperArm" },
            { "LeftUpperArm", "LeftLowerArm" },
            { "LeftLowerArm", "LeftHand" },
            { "UpperTorso", "RightUpperArm" },
            { "RightUpperArm", "RightLowerArm" },
            { "RightLowerArm", "RightHand" },
        }
    elseif humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
        return {
            { "Head", "Torso" },
            { "Torso", "LeftArm" },
            { "Torso", "RightArm" },
            { "Torso", "LeftLeg" },
            { "Torso", "RightLeg" },
        }
    end
    return {}
end

function StartSkeletonESP()
    StopSkeletonESP()
    local camera = workspace.CurrentCamera
    
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player then
            TrackPlayer(plr)
        end
    end
    
    local playerAddedConnection = game.Players.PlayerAdded:Connect(function(plr)
        if plr ~= player then
            TrackPlayer(plr)
        end
    end)
    table.insert(connections, playerAddedConnection)
    
    local playerRemovingConnection = game.Players.PlayerRemoving:Connect(function(plr)
        UntrackPlayer(plr)
    end)
    table.insert(connections, playerRemovingConnection)
    
    skeletonRenderConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if not skeletonEnabled then return end
        
        for plr, data in pairs(skeletonConnections) do
            if not plr or not plr.Parent then
                UntrackPlayer(plr)
                continue
            end
            
            local character = plr.Character
            if not character then
                for _, line in pairs(data.lines) do
                    if line then line.Visible = false end
                end
                continue
            end
            
            local joints, humanoid = GetJoints(character)
            local connectionsList = GetConnections(humanoid)
            
            if not humanoid or humanoid.Health <= 0 then
                for _, line in pairs(data.lines) do
                    if line then line.Visible = false end
                end
                continue
            end
            
            for index, connection in ipairs(connectionsList) do
                local jointA = joints[connection[1]]
                local jointB = joints[connection[2]]
                
                if jointA and jointB then
                    local posA, onScreenA = camera:WorldToViewportPoint(jointA.Position)
                    local posB, onScreenB = camera:WorldToViewportPoint(jointB.Position)
                    
                    local line = data.lines[index]
                    if not line then
                        line = createLine()
                        data.lines[index] = line
                    end
                    
                    if onScreenA and onScreenB then
                        line.From = Vector2.new(posA.X, posA.Y)
                        line.To = Vector2.new(posB.X, posB.Y)
                        line.Visible = true
                        line.Color = skeletonColor
                        line.Thickness = skeletonThickness
                        line.Transparency = skeletonTransparency
                    else
                        line.Visible = false
                    end
                elseif data.lines[index] then
                    data.lines[index].Visible = false
                end
            end
        end
    end)
    table.insert(connections, skeletonRenderConnection)
end

function TrackPlayer(plr)
    if skeletonConnections[plr] then
        UntrackPlayer(plr)
    end
    
    local data = {
        lines = {}
    }
    
    local character = plr.Character
    if character then
        local _, humanoid = GetJoints(character)
        local connectionsList = GetConnections(humanoid)
        for i = 1, #connectionsList do
            data.lines[i] = createLine()
        end
    end
    
    skeletonConnections[plr] = data
end

function UntrackPlayer(plr)
    if skeletonConnections[plr] then
        for _, line in pairs(skeletonConnections[plr].lines) do
            if line then
                pcall(function() line:Remove() end)
            end
        end
        skeletonConnections[plr] = nil
    end
end

function StopSkeletonESP()
    if skeletonRenderConnection then
        skeletonRenderConnection:Disconnect()
        skeletonRenderConnection = nil
    end
    
    for plr, data in pairs(skeletonConnections) do
        for _, line in pairs(data.lines) do
            if line then
                pcall(function() line:Remove() end)
            end
        end
    end
    skeletonConnections = {}
end

-- ==================== PLAYER ESP FUNCTIONS ====================
function CreatePlayerESP(targetPlayer)
    if targetPlayer == player then return end
    if not targetPlayer.Character then return end
    local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    local isTeam = false
    if teamCheckEnabled and player.Team and targetPlayer.Team and player.Team == targetPlayer.Team then
        isTeam = true
    end
    
    local outlineColor = isTeam and teamOutlineColor or enemyOutlineColor
    local fillColor = isTeam and teamFillColor or enemyFillColor
    
    local highlight = Instance.new("Highlight")
    highlight.Adornee = targetPlayer.Character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = showFill and fillColor or Color3.fromRGB(0, 0, 0)
    highlight.FillTransparency = showFill and 0.5 or 1
    highlight.OutlineColor = showOutline and outlineColor or Color3.fromRGB(0, 0, 0)
    highlight.OutlineTransparency = showOutline and 0.3 or 1
    highlight.Parent = targetPlayer.Character
    
    local nameTag = nil
    if showNicknames then
        nameTag = Instance.new("BillboardGui")
        nameTag.Adornee = targetPlayer.Character:FindFirstChild("Head") or targetPlayer.Character
        nameTag.Size = UDim2.new(0, 200, 0, 40)
        nameTag.StudsOffset = Vector3.new(0, 3.5, 0)
        nameTag.AlwaysOnTop = true
        nameTag.Parent = targetPlayer.Character
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = nameTag
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = targetPlayer.Name
        nameLabel.TextColor3 = nicknameColor
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.2
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    end
    
    local healthBar = nil
    local healthConnection = nil
    if showHealth then
        healthBar = Instance.new("BillboardGui")
        healthBar.Adornee = targetPlayer.Character
        healthBar.Size = UDim2.new(0, 60, 0, 6)
        healthBar.StudsOffset = Vector3.new(0, -2.8, 0)
        healthBar.AlwaysOnTop = true
        healthBar.Parent = targetPlayer.Character
        
        local healthFrame = Instance.new("Frame")
        healthFrame.Parent = healthBar
        healthFrame.Size = UDim2.new(1, 0, 1, 0)
        healthFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        healthFrame.BorderSizePixel = 0
        
        local healthFill = Instance.new("Frame")
        healthFill.Parent = healthFrame
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.BorderSizePixel = 0
        
        local updateHealth = function()
            if not humanoid or not healthFill then return end
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
            
            if healthPercent > 0.5 then
                healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            elseif healthPercent > 0.25 then
                healthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
            else
                healthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        end
        
        updateHealth()
        healthConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(updateHealth)
    end
    
    table.insert(espObjects, {
        highlight = highlight,
        nameTag = nameTag,
        healthBar = healthBar,
        healthConnection = healthConnection,
        player = targetPlayer
    })
end

function ClearESP()
    for _, espData in ipairs(espObjects) do
        pcall(function()
            if espData.highlight then espData.highlight:Destroy() end
            if espData.nameTag then espData.nameTag:Destroy() end
            if espData.healthBar then espData.healthBar:Destroy() end
            if espData.healthConnection then espData.healthConnection:Disconnect() end
        end)
    end
    espObjects = {}
end

-- ==================== ESP REFRESH SYSTEM ====================
function StartESPRefresh()
    StopESPRefresh()
    
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player then
            CreatePlayerESP(plr)
        end
    end
    
    espRefreshConnection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        if not espEnabled then return end
        
        espRefreshTimer = espRefreshTimer + deltaTime
        if espRefreshTimer >= espRefreshInterval then
            espRefreshTimer = 0
            RefreshESPNOW()
        end
    end)
    table.insert(connections, espRefreshConnection)
end

function StopESPRefresh()
    if espRefreshConnection then
        espRefreshConnection:Disconnect()
        espRefreshConnection = nil
    end
    espRefreshTimer = 0
end

-- ==================== WATERMARK SYSTEM ====================
function UpdateWatermarkSize()
    if not watermarkTextLabel or not watermarkFrame then return end
    
    local textBounds = watermarkTextLabel.TextBounds
    local padding = 20
    
    local width = math.max(textBounds.X + padding, 180)
    local height = math.max(textBounds.Y + padding, 70)
    
    watermarkFrame.Size = UDim2.new(0, width, 0, height)
end

function CreateWatermark()
    if watermarkGui then
        DestroyWatermark()
    end
    
    watermarkGui = Instance.new("ScreenGui")
    watermarkGui.Name = "Watermark"
    watermarkGui.Parent = game.CoreGui
    watermarkGui.ResetOnSpawn = false
    watermarkGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    watermarkFrame = Instance.new("Frame")
    watermarkFrame.Name = "WatermarkFrame"
    watermarkFrame.Parent = watermarkGui
    watermarkFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    watermarkFrame.BackgroundTransparency = 0.5
    watermarkFrame.BorderSizePixel = 0
    watermarkFrame.Size = UDim2.new(0, 300, 0, 120)
    watermarkFrame.Position = watermarkPosition
    watermarkFrame.Active = true
    watermarkFrame.Draggable = false
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = watermarkFrame
    
    watermarkTextLabel = Instance.new("TextLabel")
    watermarkTextLabel.Name = "WatermarkText"
    watermarkTextLabel.Parent = watermarkFrame
    watermarkTextLabel.Size = UDim2.new(1, -20, 1, -20)
    watermarkTextLabel.Position = UDim2.new(0, 10, 0, 10)
    watermarkTextLabel.BackgroundTransparency = 1
    watermarkTextLabel.TextColor3 = watermarkColor
    watermarkTextLabel.TextSize = 14
    watermarkTextLabel.Font = Enum.Font.Gotham
    watermarkTextLabel.TextXAlignment = Enum.TextXAlignment.Left
    watermarkTextLabel.TextYAlignment = Enum.TextYAlignment.Top
    watermarkTextLabel.TextWrapped = false
    watermarkTextLabel.Text = ""
    
    WatermarkDragify(watermarkFrame, watermarkFrame)
    
    UpdateWatermarkText()
    
    watermarkSizeConnection = watermarkTextLabel:GetPropertyChangedSignal("Text"):Connect(function()
        UpdateWatermarkSize()
    end)
    table.insert(connections, watermarkSizeConnection)
    
    watermarkUpdateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if watermarkEnabled then
            UpdateWatermarkText()
        end
    end)
    table.insert(connections, watermarkUpdateConnection)
end

function UpdateWatermarkText()
    if not watermarkTextLabel then return end
    
    local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown"
    local playerCount = #game.Players:GetPlayers()
    local fps = math.floor(1 / (game:GetService("RunService").Heartbeat:Wait() or 0.001))
    local currentTime = os.date("%H:%M:%S")
    local currentDate = os.date("%d/%m/%Y")
    
    watermarkTextLabel.Text = string.format(
        "lupica3-univ\n%s\nPlayers: %d | FPS: %d\n%s | %s",
        placeName,
        playerCount,
        fps,
        currentTime,
        currentDate
    )
    
    UpdateWatermarkSize()
end

function DestroyWatermark()
    if watermarkUpdateConnection then
        watermarkUpdateConnection:Disconnect()
        watermarkUpdateConnection = nil
    end
    
    if watermarkSizeConnection then
        watermarkSizeConnection:Disconnect()
        watermarkSizeConnection = nil
    end
    
    if watermarkGui then
        watermarkGui:Destroy()
        watermarkGui = nil
        watermarkFrame = nil
        watermarkTextLabel = nil
    end
end

function ToggleWatermark(state)
    watermarkEnabled = state
    if state then
        CreateWatermark()
    else
        DestroyWatermark()
    end
end

-- ==================== MISC TAB ====================
local MiscTab = TabSection:Tab({
    text = "Misc",
    icon = "rbxassetid://7999345313",
})

-- ==================== CONFIG EDITOR ====================
local ConfigSection = MiscTab:Section({
    text = "Config Editor"
})

ConfigSection:Toggle({
    text = "Config Editor",
    state = false,
    callback = function(state)
        ToggleConfigEditor(state)
    end
})

-- ==================== WATERMARK SECTION ====================
local MiscSection = MiscTab:Section({
    text = "Watermark"
})

MiscSection:Toggle({
    text = "Watermark",
    state = false,
    callback = function(state)
        ToggleWatermark(state)
    end
})

MiscSection:Toggle({
    text = "Unlocked",
    state = false,
    callback = function(state)
        watermarkUnlocked = state
    end
})

MiscSection:Colorpicker({
    text = "Watermark Color",
    color = watermarkColor,
    callback = function(color)
        watermarkColor = color
        if watermarkTextLabel then
            watermarkTextLabel.TextColor3 = watermarkColor
        end
    end
})

-- ==================== VISUAL EFFECTS SECTION ====================
local VisualEffectsSection = MiscTab:Section({
    text = "Visual Effects"
})

VisualEffectsSection:Toggle({
    text = "No Fog",
    state = false,
    callback = function(state)
        ToggleNoFog(state)
    end
})

VisualEffectsSection:Toggle({
    text = "No Shadows",
    state = false,
    callback = function(state)
        ToggleNoShadows(state)
    end
})

VisualEffectsSection:Toggle({
    text = "FullBright",
    state = false,
    callback = function(state)
        ToggleFullBright(state)
    end
})

-- ==================== MISC OPTIONS ====================
local MiscOptionsSection = MiscTab:Section({
    text = "Misc Options"
})

MiscOptionsSection:Button({
    text = "Unload",
    callback = function()
        if isUnloaded then return end
        isUnloaded = true
        
        espEnabled = false
        StopESPRefresh()
        ClearESP()
        StopSkeletonESP()
        ToggleWatermark(false)
        ToggleHitbox(false)
        ToggleNoFog(false)
        ToggleNoShadows(false)
        ToggleFullBright(false)
        ToggleAimbot(false)
        ToggleInfiniteJump(false)
        SetWalkSpeed(16)
        ToggleConfigEditor(false)
        
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        connections = {}
        ratioConnection = nil
        skeletonRenderConnection = nil
        hitboxConnection = nil
        aimbotConnection = nil
        aimbotRenderConnection = nil
        
        if aimbotFOVCircle then
            aimbotFOVCircle:Remove()
            aimbotFOVCircle = nil
        end
        
        pcall(function()
            for _, v in pairs(game.CoreGui:GetChildren()) do
                if v:IsA("ScreenGui") and (v.Name == "Neverlose" or v.Name == "Watermark" or v.Name == "ConfigEditor") then
                    v:Destroy()
                end
            end
        end)
        
        print("unloaded")
    end
})

-- RightShift to toggle
local rightShiftConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift and not isUnloaded then
        Library:Toggle()
    end
end)
table.insert(connections, rightShiftConnection)

-- Uruchom movement
SetupInfiniteJump()
SetupWalkSpeed()

print("lupica3-univ injected")
