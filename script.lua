local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
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

-- === 3. ПАНЕЛИ НАСТРОЕК СПРАВА ===
local function createRightPanel(name, height)
    local panel = Instance.new("Frame"); panel.Name = name; panel.Size = UDim2.new(0, 200, 0, height or 220); panel.Position = UDim2.new(1, 10, 0, 0); panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25); panel.Visible = false; panel.ZIndex = 10; panel.Parent = mainFrame; Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    local go = Instance.new("Frame"); go.Size = UDim2.new(1, 0, 1, 0); go.BackgroundColor3 = Color3.fromRGB(255, 255, 255); go.BackgroundTransparency = 0.85; go.ZIndex = 10; go.Parent = panel; Instance.new("UICorner", go).CornerRadius = UDim.new(0, 8)
    local pg = Instance.new("UIGradient"); pg.Color = MainGradientScheme; pg.Rotation = 45; pg.Parent = go
    return panel, pg
end

local ParticlesRightPanel, pGrad1 = createRightPanel("ParticlesConfig", 180)
local SoundRightPanel, pGrad2 = createRightPanel("SoundConfig", 100)
local SkyRightPanel, pGrad3 = createRightPanel("SkyConfig", 100)
local TargetRightPanel, pGrad4 = createRightPanel("TargetConfig", 160)

local function closeAllRightPanels()
    ParticlesRightPanel.Visible = false; SoundRightPanel.Visible = false; SkyRightPanel.Visible = false; TargetRightPanel.Visible = false
end

-- === 4. ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ЧИТА ===
local Modules = { AutoEscape = false, EngineEsp = false, Tracers = false, WeakSpot = false, Nametags = false, CustomSky = false, HitParticles = false, HitSound = false }
local TargetMode = "None" 
local TargetPlayerName = ""
local ParticleConfig = { Color = Color3.fromRGB(255, 50, 50), Texture = "rbxassetid://243098098" }
local SoundConfig = { Id = "rbxassetid://8111055570" } -- Metal Clank default
local SkyConfig = { Id = "rbxassetid://159454299" } -- Galaxy default
local PreviousHealths = {}
local OriginalSky = nil

local function updateTheme(color1, color2)
    local newGrad = ColorSequence.new({ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)})
    mainBgGradient.Color = newGrad; sideGrad.Color = newGrad; pGrad1.Color = newGrad; pGrad2.Color = newGrad; pGrad3.Color = newGrad; pGrad4.Color = newGrad
end

-- === 5. ФУНКЦИИ GUI ===
local function createDropdown(parent, titleText, yPos, options, defaultIndex, callback)
    local mainBtn = Instance.new("TextButton"); mainBtn.Size = UDim2.new(0.9, 0, 0, 30); mainBtn.Position = UDim2.new(0.05, 0, 0, yPos); mainBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); mainBtn.Text = titleText .. ": " .. options[defaultIndex].Name; mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255); mainBtn.Font = Enum.Font.GothamBold; mainBtn.TextSize = 12; mainBtn.ZIndex = 14; mainBtn.Parent = parent; Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 6)
    local dropFrame = Instance.new("Frame"); dropFrame.Size = UDim2.new(1, 0, 0, #options * 30); dropFrame.Position = UDim2.new(0, 0, 1, 2); dropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); dropFrame.Visible = false; dropFrame.ZIndex = 20; dropFrame.Parent = mainBtn; Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIListLayout", dropFrame).SortOrder = Enum.SortOrder.LayoutOrder
    mainBtn.MouseButton1Click:Connect(function() dropFrame.Visible = not dropFrame.Visible end)
    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton"); optBtn.Size = UDim2.new(1, 0, 0, 30); optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); optBtn.Text = opt.Name; optBtn.TextColor3 = Color3.fromRGB(200, 200, 200); optBtn.Font = Enum.Font.Gotham; optBtn.TextSize = 12; optBtn.ZIndex = 21; optBtn.Parent = dropFrame
        optBtn.MouseButton1Click:Connect(function() mainBtn.Text = titleText .. ": " .. opt.Name; dropFrame.Visible = false; callback(opt.Value) end)
    end
end

local function createModuleButton(parent, title, description, lmbCallback, rmbCallback)
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
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 and rmbCallback then
            rmbCallback()
        end
    end)
    return button
end

local function createTab(title, page, y)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -25, 0, 35); btn.Position = UDim2.new(0, 15, 0, y); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); btn.Text = title; btn.TextColor3 = Color3.fromRGB(150, 150, 150); btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.ZIndex = 12; btn.Parent = sidebar; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        carPage.Visible = false; visualPage.Visible = false; page.Visible = true; closeAllRightPanels()
        for _, v in pairs(sidebar:GetChildren()) do if v:IsA("TextButton") then v.BackgroundColor3 = Color3.fromRGB(20, 20, 20); v.TextColor3 = Color3.fromRGB(150, 150, 150) end end
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end
createTab("Visuals", visualPage, 60); createTab("Car Mods", carPage, 105)

-- НАСТРОЙКИ ПАНЕЛЕЙ (ПКМ)
createDropdown(ParticlesRightPanel, "Цвет", 40, {{Name="Красный", Value=Color3.fromRGB(255,0,0)}, {Name="Синий", Value=Color3.fromRGB(0,150,255)}, {Name="Желтый", Value=Color3.fromRGB(255,255,0)}}, 1, function(v) ParticleConfig.Color = v end)
createDropdown(ParticlesRightPanel, "Тип", 80, {{Name="Искры", Value="rbxassetid://243098098"}, {Name="Звезды", Value="rbxassetid://2173499710"}}, 1, function(v) ParticleConfig.Texture = v end)

createDropdown(SoundRightPanel, "Звук", 40, {{Name="Глухой Металл", Value="rbxassetid://8111055570"}, {Name="Взрыв", Value="rbxassetid://142070127"}, {Name="Bonk", Value="rbxassetid://1048033230"}}, 1, function(v) SoundConfig.Id = v end)
createDropdown(SkyRightPanel, "Небо", 40, {{Name="Галактика", Value="rbxassetid://159454299"}, {Name="Закат", Value="rbxassetid://264906477"}, {Name="Неон", Value="rbxassetid://1417494030"}}, 1, function(v) SkyConfig.Id = v end)

createDropdown(TargetRightPanel, "Кого бить", 40, {{Name = "Никто", Value = "None"}, {Name = "Все машины", Value = "All"}, {Name = "По нику", Value = "Player"}}, 1, function(v) TargetMode = v end)
local TargetInput = Instance.new("TextBox"); TargetInput.Size = UDim2.new(0.9, 0, 0, 30); TargetInput.Position = UDim2.new(0.05, 0, 0, 80); TargetInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TargetInput.Text = "Ник (если выбран)"; TargetInput.TextColor3 = Color3.fromRGB(200, 200, 200); TargetInput.Font = Enum.Font.Gotham; TargetInput.TextSize = 12; TargetInput.ZIndex = 13; TargetInput.ClearTextOnFocus = true; TargetInput.Parent = TargetRightPanel; Instance.new("UICorner", TargetInput).CornerRadius = UDim.new(0, 6)
TargetInput.FocusLost:Connect(function() TargetPlayerName = string.lower(TargetInput.Text) end)

-- === 6. КНОПКИ ОСНОВНОГО МЕНЮ ===
createModuleButton(carPage, "Auto Escape (Meltdown)", "Телепортирует вверх при взрыве ядра", function(s) Modules.AutoEscape = s end)

createModuleButton(visualPage, "Weak Spot ESP (Авто-Цель)", "Показывает КУДА БИТЬ чтобы взорвать тачку", function(state) Modules.WeakSpot = state end)
createModuleButton(visualPage, "Car Box ESP", "Рисует 2D боксы на машинах", function(state) Modules.EngineEsp = state end)
createModuleButton(visualPage, "Tracers", "Рисует линии до уязвимых точек", function(state) Modules.Tracers = state end)
createModuleButton(visualPage, "Hit Particles", "ЛКМ: Вкл | ПКМ: Настройки", function(state) Modules.HitParticles = state end, function() closeAllRightPanels(); ParticlesRightPanel.Visible = true end)
createModuleButton(visualPage, "Hit Sounds", "ЛКМ: Вкл звук удара | ПКМ: Выбрать", function(state) Modules.HitSound = state end, function() closeAllRightPanels(); SoundRightPanel.Visible = true end)
createModuleButton(visualPage, "Custom Skybox", "ЛКМ: Изменить небо | ПКМ: Выбрать", function(state) 
    Modules.CustomSky = state
    if state then
        OriginalSky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
        local newSky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        newSky.SkyboxBk = SkyConfig.Id; newSky.SkyboxDn = SkyConfig.Id; newSky.SkyboxFt = SkyConfig.Id; newSky.SkyboxLf = SkyConfig.Id; newSky.SkyboxRt = SkyConfig.Id; newSky.SkyboxUp = SkyConfig.Id
    else
        local current = Lighting:FindFirstChildOfClass("Sky")
        if current then current:Destroy() end
    end
end, function() closeAllRightPanels(); SkyRightPanel.Visible = true end)

createModuleButton(visualPage, "Target Config", "ПКМ: Настроить сканер машин", function(state) Modules.Target = state end, function() closeAllRightPanels(); TargetRightPanel.Visible = true end)

-- Перетаскивание
local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = mainFrame.Position; local c; c = UserInputService.InputEnded:Connect(function(e) if e.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false; c:Disconnect() end end) end end)
mainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputBegan:Connect(function(input, gp) if not gp and input.KeyCode == Enum.KeyCode.RightBracket then mainFrame.Visible = not mainFrame.Visible end end)

-- === 7. ЯДРО ЧИТА (УМНЫЙ СКАНЕР WEAK SPOT) ===
local EspObjects = {}

local function createEspForPlayer(plr)
    if plr == LocalPlayer then return end
    local sBox, box = pcall(function() return Drawing.new("Square") end); local sLine, tracer = pcall(function() return Drawing.new("Line") end)
    local sTxt, nametag = pcall(function() return Drawing.new("Text") end); local sWeak, weakTxt = pcall(function() return Drawing.new("Text") end)
    local sCirc, weakCirc = pcall(function() return Drawing.new("Circle") end)
    
    if not sBox or not sLine or not sTxt then return end
    
    box.Visible = false; box.Color = Color3.fromRGB(0, 200, 255); box.Thickness = 1.5; box.Filled = false; box.Transparency = 1
    tracer.Visible = false; tracer.Color = Color3.fromRGB(255, 255, 255); tracer.Thickness = 1; tracer.Transparency = 0.5
    nametag.Visible = false; nametag.Color = Color3.fromRGB(255, 255, 255); nametag.Size = 16; nametag.Center = true; nametag.Outline = true; nametag.Transparency = 1
    
    -- Визуалы Weak Spot
    weakTxt.Visible = false; weakTxt.Color = Color3.fromRGB(255, 0, 0); weakTxt.Text = "[WEAK SPOT]"; weakTxt.Size = 18; weakTxt.Center = true; weakTxt.Outline = true; weakTxt.Transparency = 1
    weakCirc.Visible = false; weakCirc.Color = Color3.fromRGB(255, 0, 0); weakCirc.Thickness = 2; weakCirc.Radius = 15; weakCirc.Filled = false; weakCirc.Transparency = 1

    EspObjects[plr] = {Box = box, Tracer = tracer, Nametag = nametag, WeakTxt = weakTxt, WeakCirc = weakCirc}
end

for _, plr in pairs(Players:GetPlayers()) do createEspForPlayer(plr) end
Players.PlayerAdded:Connect(createEspForPlayer)

Players.PlayerRemoving:Connect(function(plr)
    if EspObjects[plr] then 
        pcall(function() EspObjects[plr].Box:Remove(); EspObjects[plr].Tracer:Remove(); EspObjects[plr].Nametag:Remove(); EspObjects[plr].WeakTxt:Remove(); EspObjects[plr].WeakCirc:Remove() end)
        EspObjects[plr] = nil; PreviousHealths[plr] = nil
    end
end)

-- НОВЫЙ АЛГОРИТМ ПОИСКА УЯЗВИМОСТИ (WEAK SPOT)
local function getWeakSpot(plr)
    if not plr.Character then return nil end
    local hum = plr.Character:FindFirstChild("Humanoid")
    if hum and hum.SeatPart then
        local car = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if car then
            -- 1. Ищем деталь мотора по именам
            local engine = car:FindFirstChild("Engine", true) or car:FindFirstChild("Core", true) or car:FindFirstChild("Motor", true)
            if engine and engine:IsA("BasePart") then return engine.Position end
            
            -- 2. Если мотор скрыт, вычисляем капот (спереди от сиденья)
            local seat = hum.SeatPart
            local hoodPosition = seat.CFrame.Position + (seat.CFrame.LookVector * 5)
            return hoodPosition
        end
    end
    -- Если не в тачке, просто целимся в тело
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if root then return root.Position end
    return nil
end

local function spawnHitParticle(targetPos)
    local part = Instance.new("Part"); part.Transparency = 1; part.Anchored = true; part.CanCollide = false; part.Position = targetPos; part.Parent = workspace
    local att = Instance.new("Attachment", part); local pe = Instance.new("ParticleEmitter", att); pe.Texture = ParticleConfig.Texture; pe.Color = ColorSequence.new(ParticleConfig.Color); pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 0)}); pe.Speed = NumberRange.new(15, 30); pe.SpreadAngle = Vector2.new(360, 360); pe.Lifetime = NumberRange.new(0.5, 1); pe.LightEmission = 1; pe.ZOffset = 1; pe.Rate = 500
    task.delay(0.5, function() pe.Enabled = false end); Debris:AddItem(part, 2)
end

local function playHitSound()
    local snd = Instance.new("Sound")
    snd.SoundId = SoundConfig.Id
    snd.Volume = 2
    snd.Parent = workspace
    snd:Play()
    Debris:AddItem(snd, 3)
end

local function isPlayerTarget(plr)
    if TargetMode == "None" then return false end
    if TargetMode == "All" then return true end
    if TargetMode == "Player" and TargetPlayerName ~= "" and string.find(string.lower(plr.Name), TargetPlayerName) then return true end
    return false
end

-- === ОСНОВНОЙ ЦИКЛ ОБНОВЛЕНИЯ ===
RunService.RenderStepped:Connect(function()
    if Modules.CustomSky then
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky and sky.SkyboxBk ~= SkyConfig.Id then
            sky.SkyboxBk = SkyConfig.Id; sky.SkyboxDn = SkyConfig.Id; sky.SkyboxFt = SkyConfig.Id; sky.SkyboxLf = SkyConfig.Id; sky.SkyboxRt = SkyConfig.Id; sky.SkyboxUp = SkyConfig.Id
        end
    end

    if Modules.AutoEscape and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        myRoot.CFrame = CFrame.new(myRoot.Position.X, 1500, myRoot.Position.Z)
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        
        local weakSpotPos = getWeakSpot(plr)
        local eChar = plr.Character
        local eHum = eChar and eChar:FindFirstChild("Humanoid")
        
        if weakSpotPos and eHum and eHum.Health > 0 then
            
            -- HIT DETECTION (Партиклы + Звуки)
            local oldHp = PreviousHealths[plr] or eHum.MaxHealth
            if eHum.Health < oldHp then 
                if Modules.HitParticles then spawnHitParticle(weakSpotPos) end
                if Modules.HitSound then playHitSound() end
            end
            PreviousHealths[plr] = eHum.Health

            local esp = EspObjects[plr]
            if esp then
                local pos, onScreen = Camera:WorldToViewportPoint(weakSpotPos)
                
                if onScreen then
                    local dist = (weakSpotPos - Camera.CFrame.Position).Magnitude
                    
                    -- WEAK SPOT (Прицел)
                    if Modules.WeakSpot then
                        esp.WeakCirc.Position = Vector2.new(pos.X, pos.Y)
                        esp.WeakCirc.Visible = true
                        esp.WeakTxt.Position = Vector2.new(pos.X, pos.Y - 25)
                        esp.WeakTxt.Visible = true
                    else
                        esp.WeakCirc.Visible = false
                        esp.WeakTxt.Visible = false
                    end
                    
                    -- Box
                    if Modules.EngineEsp then
                        local scaleFactor = 1000 / dist
                        local boxSize = Vector2.new(4 * scaleFactor, 4 * scaleFactor)
                        if boxSize.Y > 150 then boxSize = Vector2.new(150, 150) end
                        
                        esp.Box.Size = boxSize
                        esp.Box.Position = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)
                        esp.Box.Visible = true
                        
                        esp.Nametag.Text = plr.Name
                        esp.Nametag.Position = Vector2.new(pos.X, pos.Y - (boxSize.Y / 2) - 15)
                        esp.Nametag.Visible = true
                    else
                        esp.Box.Visible = false; esp.Nametag.Visible = false
                    end

                    -- Tracers (Линии идут точно к Weak Spot)
                    if Modules.Tracers then
                        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                        esp.Tracer.Visible = true
                    else
                        esp.Tracer.Visible = false
                    end
                else
                    esp.Box.Visible = false; esp.Nametag.Visible = false; esp.Tracer.Visible = false; esp.WeakCirc.Visible = false; esp.WeakTxt.Visible = false
                end
            end
        else
            if EspObjects[plr] then
                EspObjects[plr].Box.Visible = false; EspObjects[plr].Nametag.Visible = false; EspObjects[plr].Tracer.Visible = false; EspObjects[plr].WeakCirc.Visible = false; EspObjects[plr].WeakTxt.Visible = false
            end
        end
    end
end)
