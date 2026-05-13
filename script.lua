local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- === 1. БЕЗОПАСНАЯ ОЧИСТКА ===
pcall(function()
    local oldGui = PlayerGui:FindFirstChild("DuckKlientGui")
    if oldGui then oldGui:Destroy() end
end)

-- === 2. СОЗДАНИЕ GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DuckKlientGui"; screenGui.ResetOnSpawn = false; screenGui.Parent = PlayerGui

local MainGradientScheme = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 170, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 215, 0))
})

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"; mainFrame.Size = UDim2.new(0, 550, 0, 420); mainFrame.Position = UDim2.new(0.5, -275, 0.5, -210); mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); mainFrame.BorderSizePixel = 0; mainFrame.Visible = true; mainFrame.ZIndex = 10; mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local gradientOverlay = Instance.new("Frame")
gradientOverlay.Size = UDim2.new(1, 0, 1, 0); gradientOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255); gradientOverlay.BackgroundTransparency = 0.85; gradientOverlay.ZIndex = 10; gradientOverlay.Parent = mainFrame
Instance.new("UICorner", gradientOverlay).CornerRadius = UDim.new(0, 12)
local mainBgGradient = Instance.new("UIGradient"); mainBgGradient.Color = MainGradientScheme; mainBgGradient.Rotation = 45; mainBgGradient.Parent = gradientOverlay

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"; sidebar.Size = UDim2.new(0, 150, 1, 0); sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20); sidebar.BorderSizePixel = 0; sidebar.ZIndex = 11; sidebar.Parent = mainFrame
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)
local sidebarGradientLine = Instance.new("Frame"); sidebarGradientLine.Size = UDim2.new(0, 4, 1, -20); sidebarGradientLine.Position = UDim2.new(0, 5, 0, 10); sidebarGradientLine.BorderSizePixel = 0; sidebarGradientLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255); sidebarGradientLine.ZIndex = 12; sidebarGradientLine.Parent = sidebar
local sideGrad = Instance.new("UIGradient"); sideGrad.Color = MainGradientScheme; sideGrad.Rotation = 90; sideGrad.Parent = sidebarGradientLine

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 0, 50); titleLabel.Position = UDim2.new(0, 20, 0, 0); titleLabel.BackgroundTransparency = 1; titleLabel.Text = "duck klient"; titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); titleLabel.Font = Enum.Font.GothamBlack; titleLabel.TextSize = 22; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.ZIndex = 12; titleLabel.Parent = sidebar

local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"; contentFrame.Size = UDim2.new(1, -170, 1, -20); contentFrame.Position = UDim2.new(0, 160, 0, 10); contentFrame.BackgroundTransparency = 1; contentFrame.ZIndex = 11; contentFrame.Parent = mainFrame

local carPage = Instance.new("ScrollingFrame"); carPage.Size = UDim2.new(1, 0, 1, 0); carPage.BackgroundTransparency = 1; carPage.ScrollBarThickness = 2; carPage.Visible = false; carPage.Parent = contentFrame; Instance.new("UIListLayout", carPage).Padding = UDim.new(0, 10)
local visualPage = Instance.new("ScrollingFrame"); visualPage.Size = UDim2.new(1, 0, 1, 0); visualPage.BackgroundTransparency = 1; visualPage.ScrollBarThickness = 2; visualPage.Visible = true; visualPage.Parent = contentFrame; Instance.new("UIListLayout", visualPage).Padding = UDim.new(0, 10)
local settingsPage = Instance.new("ScrollingFrame"); settingsPage.Size = UDim2.new(1, 0, 1, 0); settingsPage.BackgroundTransparency = 1; settingsPage.ScrollBarThickness = 2; settingsPage.Visible = false; settingsPage.Parent = contentFrame; Instance.new("UIListLayout", settingsPage).Padding = UDim.new(0, 10)

-- === 3. ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ЧИТА ===
local Modules = { CarSpeed = false, AutoEscape = false, EngineEsp = false, Tracers = false, EngineChams = false, Nametags = false, Fullbright = false }

local function updateTheme(color1, color2)
    local newGrad = ColorSequence.new({ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)})
    mainBgGradient.Color = newGrad; sideGrad.Color = newGrad
end

-- === 4. ФУНКЦИИ GUI ===
local function createModuleButton(parent, title, description, lmbCallback)
    local button = Instance.new("TextButton"); button.Size = UDim2.new(1, -10, 0, 60); button.BackgroundColor3 = Color3.fromRGB(25, 25, 25); button.Text = ""; button.AutoButtonColor = false; button.ZIndex = 12; button.Parent = parent; Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    local uistroke = Instance.new("UIStroke"); uistroke.Thickness = 2; uistroke.Color = Color3.fromRGB(40, 40, 40); uistroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; uistroke.Parent = button
    local titleText = Instance.new("TextLabel"); titleText.Size = UDim2.new(1, -20, 0, 30); titleText.Position = UDim2.new(0, 10, 0, 5); titleText.BackgroundTransparency = 1; titleText.Text = title; titleText.TextColor3 = Color3.fromRGB(200, 200, 200); titleText.Font = Enum.Font.GothamBold; titleText.TextSize = 16; titleText.TextXAlignment = Enum.TextXAlignment.Left; titleText.ZIndex = 13; titleText.Parent = button
    local descText = Instance.new("TextLabel"); descText.Size = UDim2.new(1, -20, 0, 20); descText.Position = UDim2.new(0, 10, 0, 30); descText.BackgroundTransparency = 1; descText.Text = description; descText.TextColor3 = Color3.fromRGB(130, 130, 130); descText.Font = Enum.Font.Gotham; descText.TextSize = 12; descText.TextXAlignment = Enum.TextXAlignment.Left; descText.ZIndex = 13; descText.Parent = button
    local active = false
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            active = not active
            uistroke.Color = active and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(40, 40, 40)
            titleText.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
            if lmbCallback then lmbCallback(active, uistroke) end
        end
    end)
    return button
end

local function createTab(title, page, y)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -25, 0, 35); btn.Position = UDim2.new(0, 15, 0, y); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); btn.Text = title; btn.TextColor3 = Color3.fromRGB(150, 150, 150); btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.ZIndex = 12; btn.Parent = sidebar; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        carPage.Visible = false; visualPage.Visible = false; settingsPage.Visible = false; page.Visible = true
        for _, v in pairs(sidebar:GetChildren()) do if v:IsA("TextButton") then v.BackgroundColor3 = Color3.fromRGB(20, 20, 20); v.TextColor3 = Color3.fromRGB(150, 150, 150) end end
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end
createTab("Visuals", visualPage, 60); createTab("Car Mods", carPage, 105); createTab("Settings", settingsPage, 150)

-- === 5. КНОПКИ ОСНОВНОГО МЕНЮ ===
createModuleButton(carPage, "Auto Escape (Meltdown)", "Телепортирует вверх при взрыве ядра", function(s) Modules.AutoEscape = s end)

-- ВИЗУАЛЫ ДЛЯ МОТОРОВ
createModuleButton(visualPage, "Engine Chams", "Подсвечивает мотор тачки сквозь стены", function(state) Modules.EngineChams = state end)
createModuleButton(visualPage, "Engine ESP Box", "Рисует бокс вокруг мотора", function(state) Modules.EngineEsp = state end)
createModuleButton(visualPage, "Nametags", "Показывает владельца тачки над мотором", function(state) Modules.Nametags = state end)
createModuleButton(visualPage, "Tracers", "Рисует линии до моторов", function(state) Modules.Tracers = state end)
createModuleButton(visualPage, "Fullbright", "Вечный день без теней", function(state) Modules.Fullbright = state end)

createModuleButton(settingsPage, "Theme: Azure & Gold", "Лазурный и Желтый", function() updateTheme(Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 215, 0)) end)
createModuleButton(settingsPage, "Theme: Toxic Slime", "Кислотный Зеленый", function() updateTheme(Color3.fromRGB(50, 255, 50), Color3.fromRGB(0, 50, 0)) end)

-- Перетаскивание
local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = mainFrame.Position; local c; c = UserInputService.InputEnded:Connect(function(e) if e.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false; c:Disconnect() end end) end end)
mainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputBegan:Connect(function(input, gp) if not gp and input.KeyCode == Enum.KeyCode.RightBracket then mainFrame.Visible = not mainFrame.Visible end end)

-- === 6. ЯДРО ЧИТА (ПОИСК МОТОРОВ) ===
local EspObjects = {}

local function createEspForPlayer(plr)
    if plr == LocalPlayer then return end
    local sBox, box = pcall(function() return Drawing.new("Square") end)
    local sLine, tracer = pcall(function() return Drawing.new("Line") end)
    local sTxt, nametag = pcall(function() return Drawing.new("Text") end)
    if not sBox or not sLine or not sTxt then return end
    
    box.Visible = false; box.Color = Color3.fromRGB(0, 200, 255); box.Thickness = 1.5; box.Filled = false; box.Transparency = 1
    tracer.Visible = false; tracer.Color = Color3.fromRGB(255, 255, 255); tracer.Thickness = 1; tracer.Transparency = 0.5
    nametag.Visible = false; nametag.Color = Color3.fromRGB(255, 255, 255); nametag.Text = plr.Name; nametag.Size = 16; nametag.Center = true; nametag.Outline = true; nametag.Transparency = 1

    EspObjects[plr] = {Box = box, Tracer = tracer, Nametag = nametag}
end

for _, plr in pairs(Players:GetPlayers()) do createEspForPlayer(plr) end
Players.PlayerAdded:Connect(createEspForPlayer)

Players.PlayerRemoving:Connect(function(plr)
    if EspObjects[plr] then 
        pcall(function() EspObjects[plr].Box:Remove() end)
        pcall(function() EspObjects[plr].Tracer:Remove() end)
        pcall(function() EspObjects[plr].Nametag:Remove() end)
        EspObjects[plr] = nil
    end
end)

-- ИЩЕМ МОТОР ТАЧКИ
local function getEngineFromPlayer(plr)
    if not plr.Character then return nil end
    local hum = plr.Character:FindFirstChild("Humanoid")
    if hum and hum.SeatPart then
        -- Если игрок сидит, находим его машину
        local car = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if car then
            -- Ищем мотор. В CC2 обычно это "Engine", "Core" или "Motor"
            local engine = car:FindFirstChild("Engine", true) or car:FindFirstChild("Core", true) or car:FindFirstChild("Motor", true)
            -- Если прям мотора нет, берем саму сидушку, чтобы хоть куда-то светить
            return engine or hum.SeatPart 
        end
    end
    return nil
end

-- ПОДСВЕТКА МОТОРА (Chams)
local function applyEngineChams(enginePart, plr)
    if not enginePart then return end
    local highlight = enginePart:FindFirstChild("DuckEngineChams")
    if Modules.EngineChams then
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "DuckEngineChams"
            highlight.FillColor = Color3.fromRGB(0, 255, 255)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.3
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = enginePart
        end
    else
        if highlight then highlight:Destroy() end
    end
end

-- === ОСНОВНОЙ ЦИКЛ ОБНОВЛЕНИЯ ===
RunService.RenderStepped:Connect(function()
    -- Fullbright (Вечный день)
    if Modules.Fullbright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
    end

    -- Авто-побег
    if Modules.AutoEscape and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        -- Если включен побег, просто висим высоко в небе
        myRoot.CFrame = CFrame.new(myRoot.Position.X, 1500, myRoot.Position.Z)
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        
        local enginePart = getEngineFromPlayer(plr)
        
        -- Применяем Chams к мотору
        applyEngineChams(enginePart, plr)
        
        local esp = EspObjects[plr]
        if esp then
            if enginePart then
                local pos, onScreen = Camera:WorldToViewportPoint(enginePart.Position)
                
                if onScreen then
                    local dist = (enginePart.Position - Camera.CFrame.Position).Magnitude
                    
                    -- Box (Вокруг мотора)
                    if Modules.EngineEsp then
                        local scaleFactor = 1000 / dist
                        local boxSize = Vector2.new(4 * scaleFactor, 4 * scaleFactor) -- Квадратный бокс
                        if boxSize.Y > 150 then boxSize = Vector2.new(150, 150) end
                        
                        esp.Box.Size = boxSize
                        esp.Box.Position = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)
                        esp.Box.Visible = true
                    else
                        esp.Box.Visible = false
                    end

                    -- Nametags (Ник над мотором)
                    if Modules.Nametags then
                        esp.Nametag.Text = plr.Name .. " [Car]"
                        esp.Nametag.Position = Vector2.new(pos.X, pos.Y - (esp.Box.Size.Y / 2) - 15)
                        esp.Nametag.Visible = true
                    else
                        esp.Nametag.Visible = false
                    end

                    -- Tracers (Линия до мотора)
                    if Modules.Tracers then
                        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                        esp.Tracer.Visible = true
                    else
                        esp.Tracer.Visible = false
                    end
                else
                    esp.Box.Visible = false
                    esp.Nametag.Visible = false
                    esp.Tracer.Visible = false
                end
            else
                -- Если игрок не в тачке / мотор не найден
                esp.Box.Visible = false
                esp.Nametag.Visible = false
                esp.Tracer.Visible = false
            end
        end
    end
end)
