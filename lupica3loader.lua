-- Skrypt uruchamiający dla lupica3-univ i lup3shootout
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Zmienna do śledzenia czy loader został zamknięty
local loaderDestroyed = false

-- Funkcja ładująca skrypt i zamykająca loader
local function loadScriptAndClose(scriptUrl, scriptName)
    if loaderDestroyed then
        return
    end

    local success, err = pcall(function()
        loadstring(game:HttpGet(scriptUrl))()
    end)

    if success then
        -- Wyświetl powiadomienie przed zamknięciem
        Rayfield:Notify({
            Title = scriptName .. " Loaded",
            Content = "Loader will now close automatically.",
            Duration = 2
        })
        
        -- Krótkie opóźnienie aby powiadomienie zdążyło się wyświetlić
        task.wait(0.5)
        
        -- Zamknij loader
        loaderDestroyed = true
        Rayfield:Destroy()
    else
        Rayfield:Notify({
            Title = "Load Failed",
            Content = "Error: " .. tostring(err),
            Duration = 5
        })
    end
end

-- Tworzenie okna głównego
local Window = Rayfield:CreateWindow({
    Name = "lupica3 Script Loader",
    LoadingTitle = "lupica3 Script Loader",
    LoadingSubtitle = "Select a script to load",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

-- Główna zakładka
local MainTab = Window:CreateTab("Scripts", 4483362458)

-- Przycisk do załadowania lupica3-univ (zamyka loader)
MainTab:CreateButton({
    Name = "Load lupica3-univ",
    Callback = function()
        loadScriptAndClose(
            "https://raw.githubusercontent.com/didisigma1/lupica3scripts/refs/heads/main/lupica3-univ.lua",
            "lupica3-univ"
        )
    end,
})

-- Przycisk do załadowania lup3shootout (zamyka loader)
MainTab:CreateButton({
    Name = "Load lup3shootout",
    Callback = function()
        loadScriptAndClose(
            "https://raw.githubusercontent.com/didisigma1/lupica3scripts/refs/heads/main/lup3shootout.lua",
            "lup3shootout"
        )
    end,
})

-- Przycisk do zamknięcia UI bez ładowania skryptu
MainTab:CreateButton({
    Name = "Close UI (Without Loading)",
    Callback = function()
        loaderDestroyed = true
        Rayfield:Destroy()
    end,
})

-- Dodatkowa informacja
MainTab:CreateParagraph({
    Title = "How to use",
    Content = "1. Click the button with the script you want to load.\n2. The script will load and the loader will close automatically.\n3. Use 'Close UI (Without Loading)' if you want to close without loading anything."
})

-- Dodatkowa zakładka z informacjami
local InfoTab = Window:CreateTab("Info", 4483362458)

InfoTab:CreateParagraph({
    Title = "Scripts Available",
    Content = "• lupica3-univ - Universal script with ESP, Aimbot, Hitbox, etc.\n• lup3shootout - Auto Fake Check Method for Cali Shootout"
})

InfoTab:CreateParagraph({
    Title = "Auto-Close Feature",
    Content = "After loading a script, the loader will automatically close to prevent conflicts and free up resources."
})