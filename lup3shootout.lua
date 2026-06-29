local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local teleportPositions = {
    Check1_Start = Vector3.new(-2392.905273, 109.657051, -218.295471),
    Check1_End = Vector3.new(-2392.849854, 109.655876, -222.808853),
    Cashout = Vector3.new(-2360.978, 5, 132.696),
    Check2_Start = Vector3.new(-2455.421631, 109.668243, -217.274750),
    Check2_End = Vector3.new(-2450.619873, 109.652145, -218.080826),
}

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid")

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:FindFirstChildOfClass("Humanoid")
end)

local VirtualInputManager = game:GetService("VirtualInputManager")

local function pressKey(key, holdDuration)
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            if holdDuration and holdDuration > 0 then
                wait(holdDuration)
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            else
                wait(0.1)
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end
        end)
    else
        warn("VirtualInputManager not available.")
    end
end

local function teleportTo(position)
    if humanoidRootPart and position then
        pcall(function() humanoidRootPart.CFrame = CFrame.new(position) end)
        wait(0.12)
    end
end

-- Function to select second slot (key 2)
local function selectSecondSlot()
    if humanoid then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
            wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
            wait(0.05)
            
            Rayfield:Notify({
                Title = "Slot Selected",
                Content = "Switched to slot 2",
                Duration = 0.5
            })
        end)
    end
end

-- Function to load anti-afk
local function loadAntiAFK()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/evxncodes/mainroblox/main/anti-afk", true))()
        Rayfield:Notify({
            Title = "Anti-AFK Loaded",
            Content = "Anti-AFK script has been successfully loaded!",
            Duration = 3
        })
    end)
end

local isCashFarming = false
local cashFarmLoop = nil

local function startCashFarm()
    isCashFarming = true

    cashFarmLoop = coroutine.create(function()
        while isCashFarming do
            -- Fake Check 1
            teleportTo(teleportPositions.Check1_Start)
            pressKey(Enum.KeyCode.E, 7)

            teleportTo(teleportPositions.Check1_End)
            pressKey(Enum.KeyCode.E, 0)

            -- Before cashout select slot 2
            teleportTo(teleportPositions.Cashout)
            wait(0.2)
            selectSecondSlot()
            wait(0.15)
            pressKey(Enum.KeyCode.E, 0)

            -- Fake Check 2
            teleportTo(teleportPositions.Check2_Start)
            pressKey(Enum.KeyCode.E, 6)

            teleportTo(teleportPositions.Check2_End)
            pressKey(Enum.KeyCode.E, 0)

            -- Before cashout select slot 2
            teleportTo(teleportPositions.Cashout)
            wait(0.2)
            selectSecondSlot()
            wait(0.15)
            pressKey(Enum.KeyCode.E, 0)

            wait(0.5)
        end
    end)

    coroutine.resume(cashFarmLoop)
end

local function stopCashFarm()
    isCashFarming = false
    if cashFarmLoop then
        wait(0.5)
    end
end

local Window = Rayfield:CreateWindow({
    Name = "lup3shootout",
    LoadingTitle = "lup3shootout",
    LoadingSubtitle = "Auto Fake Check Method",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

local CashTab = Window:CreateTab("Auto Fake Check", 4483362458)

CashTab:CreateToggle({
    Name = "Auto Fake Check Method",
    CurrentValue = false,
    Flag = "CashFarmToggle",
    Callback = function(Value)
        if Value then
            startCashFarm()
            Rayfield:Notify({
                Title = "Auto Fake Check Started",
                Content = "Fake check method enabled - Slot 2 will be selected before cashout",
                Duration = 3
            })
        else
            stopCashFarm()
            Rayfield:Notify({
                Title = "Auto Fake Check Stopped",
                Content = "Fake check method disabled",
                Duration = 3
            })
        end
    end,
})

CashTab:CreateButton({
    Name = "Select Slot 2 Manually",
    Callback = function()
        selectSecondSlot()
        Rayfield:Notify({
            Title = "Slot Selected",
            Content = "Switched to slot 2",
            Duration = 2
        })
    end,
})

CashTab:CreateButton({
    Name = "Load Anti-AFK",
    Callback = function()
        loadAntiAFK()
    end,
})

CashTab:CreateButton({
    Name = "Close UI",
    Callback = function()
        stopCashFarm()
        Rayfield:Destroy()
    end,
})