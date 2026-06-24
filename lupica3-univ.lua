--[[
    Script: lupica3-univ
    Author: lupica3
    Date: 2026
]]

-- Load library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/didisigma1/lupica3-univ/refs/heads/main/lib.lua"))()

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
        RefreshESPNOW() -- Natychmiastowa aktualizacja
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
        RefreshESPNOW() -- Natychmiastowa aktualizacja
    end
})

OutlineSection:Colorpicker({
    text = "Team - Outline Color",
    color = teamOutlineColor,
    callback = function(color)
        teamOutlineColor = color
        RefreshESPNOW() -- Natychmiastowa aktualizacja
    end
})

OutlineSection:Colorpicker({
    text = "Enemy - Outline Color",
    color = enemyOutlineColor,
    callback = function(color)
        enemyOutlineColor = color
        RefreshESPNOW() -- Natychmiastowa aktualizacja
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
        RefreshESPNOW() -- Natychmiastowa aktualizacja
    end
})

FillSection:Colorpicker({
    text = "Team - Fill Color",
    color = teamFillColor,
    callback = function(color)
        teamFillColor = color
        RefreshESPNOW() -- Natychmiastowa aktualizacja
    end
})

FillSection:Colorpicker({
    text = "Enemy - Fill Color",
    color = enemyFillColor,
    callback = function(color)
        enemyFillColor = color
        RefreshESPNOW() -- Natychmiastowa aktualizacja
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
        RefreshESPNOW() -- Natychmiastowa aktualizacja
    end
})

NicknameSection:Colorpicker({
    text = "Nickname Color",
    color = nicknameColor,
    callback = function(color)
        nicknameColor = color
        RefreshESPNOW() -- Natychmiastowa aktualizacja
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
        RefreshESPNOW() -- Natychmiastowa aktualizacja
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
    
    -- Highlight (GLOW)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = targetPlayer.Character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = showFill and fillColor or Color3.fromRGB(0, 0, 0)
    highlight.FillTransparency = showFill and 0.5 or 1
    highlight.OutlineColor = showOutline and outlineColor or Color3.fromRGB(0, 0, 0)
    highlight.OutlineTransparency = showOutline and 0.3 or 1
    highlight.Parent = targetPlayer.Character
    
    -- Name Tag
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
    
    -- Health Bar
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

-- ==================== MISC OPTIONS ====================
local MiscOptionsSection = MiscTab:Section({
    text = "Misc Options"
})

-- Unload
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
        
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        connections = {}
        ratioConnection = nil
        skeletonRenderConnection = nil
        
        pcall(function()
            for _, v in pairs(game.CoreGui:GetChildren()) do
                if v:IsA("ScreenGui") and (v.Name == "Neverlose" or v.Name == "Watermark") then
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

print("lupica3-univ injected")
