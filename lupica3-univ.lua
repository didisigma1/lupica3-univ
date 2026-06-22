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

-- Main window
local Window = Library:Window({
    text = "lupica3-univ"
})

-- Tab section
local TabSection = Window:TabSection({
    text = "Menu"
})

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
            CreateESP()
        else
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
        if espEnabled then
            RefreshESP()
        end
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
        if espEnabled then
            RefreshESP()
        end
    end
})

OutlineSection:Colorpicker({
    text = "Team - Outline Color",
    color = teamOutlineColor,
    callback = function(color)
        teamOutlineColor = color
        if espEnabled then
            RefreshESP()
        end
    end
})

OutlineSection:Colorpicker({
    text = "Enemy - Outline Color",
    color = enemyOutlineColor,
    callback = function(color)
        enemyOutlineColor = color
        if espEnabled then
            RefreshESP()
        end
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
        if espEnabled then
            RefreshESP()
        end
    end
})

FillSection:Colorpicker({
    text = "Team - Fill Color",
    color = teamFillColor,
    callback = function(color)
        teamFillColor = color
        if espEnabled then
            RefreshESP()
        end
    end
})

FillSection:Colorpicker({
    text = "Enemy - Fill Color",
    color = enemyFillColor,
    callback = function(color)
        enemyFillColor = color
        if espEnabled then
            RefreshESP()
        end
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
        if espEnabled then
            RefreshESP()
        end
    end
})

NicknameSection:Colorpicker({
    text = "Nickname Color",
    color = nicknameColor,
    callback = function(color)
        nicknameColor = color
        if espEnabled then
            RefreshESP()
        end
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
        if espEnabled then
            RefreshESP()
        end
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
function CreateESP()
    ClearESP()
    
    local function CreatePlayerESP(targetPlayer)
        if targetPlayer == player then return end
        if not targetPlayer.Character then return end
        if not targetPlayer.Character:FindFirstChild("Humanoid") then return end
        if targetPlayer.Character.Humanoid.Health <= 0 then return end
        
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
            
            local humanoid = targetPlayer.Character.Humanoid
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
        
        local espData = {
            highlight = highlight,
            nameTag = nameTag,
            healthBar = healthBar,
            healthConnection = healthConnection,
            player = targetPlayer
        }
        table.insert(espObjects, espData)
    end
    
    for _, targetPlayer in pairs(game.Players:GetPlayers()) do
        CreatePlayerESP(targetPlayer)
    end
    
    local playerAddedConnection = game.Players.PlayerAdded:Connect(function(newPlayer)
        task.wait(0.5)
        if espEnabled then
            CreatePlayerESP(newPlayer)
        end
    end)
    table.insert(connections, playerAddedConnection)
    
    local characterAddedConnection = game.Players.PlayerAdded:Connect(function(newPlayer)
        newPlayer.CharacterAdded:Connect(function(character)
            task.wait(0.5)
            if espEnabled then
                for i, espData in ipairs(espObjects) do
                    if espData.player == newPlayer then
                        pcall(function()
                            if espData.highlight then espData.highlight:Destroy() end
                            if espData.nameTag then espData.nameTag:Destroy() end
                            if espData.healthBar then espData.healthBar:Destroy() end
                            if espData.healthConnection then espData.healthConnection:Disconnect() end
                        end)
                        table.remove(espObjects, i)
                        break
                    end
                end
                CreatePlayerESP(newPlayer)
            end
        end)
    end)
    table.insert(connections, characterAddedConnection)
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

function RefreshESP()
    if espEnabled then
        ClearESP()
        CreateESP()
    end
end

-- ==================== MISC TAB ====================
local MiscTab = TabSection:Tab({
    text = "Misc",
    icon = "rbxassetid://7999345313",
})

local MiscSection = MiscTab:Section({
    text = "Misc Options"
})

-- Unload
MiscSection:Button({
    text = "Unload",
    callback = function()
        if isUnloaded then return end
        isUnloaded = true
        
        espEnabled = false
        ClearESP()
        StopSkeletonESP()
        
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        connections = {}
        ratioConnection = nil
        skeletonRenderConnection = nil
        
        pcall(function()
            for _, v in pairs(game.CoreGui:GetChildren()) do
                if v:IsA("ScreenGui") and v.Name == "Neverlose" then
                    v:Destroy()
                end
            end
        end)
        
        print("unloaded")
    end
})

-- RightShift to toggle
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift and not isUnloaded then
        Library:Toggle()
    end
end)

print("lupica3-univ injected")