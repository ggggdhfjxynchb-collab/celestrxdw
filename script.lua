local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
screenGui.Name = "DuckKlientGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

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

local combatPage = Instance.new("ScrollingFrame"); combatPage.Size = UDim2.new(1, 0, 1, 0); combatPage.BackgroundTransparency = 1; combatPage.ScrollBarThickness = 2; combatPage.Visible = true; combatPage.Parent = contentFrame; Instance.new("UIListLayout", combatPage).Padding = UDim.new(0, 10)
local visualPage = Instance.new("ScrollingFrame"); visualPage.Size = UDim2.new(1, 0, 1, 0); visualPage.BackgroundTransparency = 1; visualPage.ScrollBarThickness = 2; visualPage.Visible = false; visualPage.Parent = contentFrame; Instance.new("UIListLayout", visualPage).Padding = UDim.new(0, 10)
local settingsPage = Instance.new("ScrollingFrame"); settingsPage.Size = UDim2.new(1, 0, 1, 0); settingsPage.BackgroundTransparency = 1; settingsPage.ScrollBarThickness = 2; settingsPage.Visible = false; settingsPage.Parent = contentFrame; Instance.new("UIListLayout", settingsPage).Padding = UDim.new(0, 10)

-- === 3. ПАНЕЛИ НАСТРОЕК СПРАВА ===
local function createRightPanel(name, height)
    local panel = Instance.new("Frame"); panel.Name = name; panel.Size = UDim2.new(0, 200, 0, height or 220); panel.Position = UDim2.new(1, 10, 0, 0); panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25); panel.Visible = false; panel.ZIndex = 10; panel.Parent = mainFrame; Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    local go = Instance.new("Frame"); go.Size = UDim2.new(1, 0, 1, 0); go.BackgroundColor3 = Color3.fromRGB(255, 255, 255); go.BackgroundTransparency = 0.85; go.ZIndex = 10; go.Parent = panel; Instance.new("UICorner", go).CornerRadius = UDim.new(0, 8)
    local pg = Instance.new("UIGradient"); pg.Color = MainGradientScheme; pg.Rotation = 45; pg.Parent = go
    return panel, pg
end

local ParticlesRightPanel, pGrad1 = createRightPanel("ParticlesConfig", 180)
local TargetRightPanel, pGrad2 = createRightPanel("TargetConfig", 160)
local DroneRightPanel, pGrad3 = createRightPanel("DroneConfig", 180)

local function closeAllRightPanels()
    ParticlesRightPanel.Visible = false; TargetRightPanel.Visible = false; DroneRightPanel.Visible = false
end

-- === 4. ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ЧИТА ===
local Modules = { SafeZone = false, TargetAim = false, PlayerEsp = false, Tracers = false, Target = false, HitParticles = false, Scope = false, AutoDrone = false }
local TargetMode = "None" -- "None", "All", "Attackers", "Defenders", "Player"
local TargetPlayerName = ""
local ParticleConfig = { Color = Color3.fromRGB(255, 50, 50), Texture = "rbxassetid://243098098" }
local DroneConfig = { Type = "Stealth", Flight = "Pulse" }
local PreviousHealths = {}

local function updateTheme(color1, color2)
    local newGrad = ColorSequence.new({ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)})
    mainBgGradient.Color = newGrad; sideGrad.Color = newGrad; pGrad1.Color = newGrad; pGrad2.Color = newGrad; pGrad3.Color = newGrad
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
            uistroke.Color = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 40, 40)
            titleText.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
            if lmbCallback then lmbCallback(active, uistroke) end
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            if rmbCallback then rmbCallback() end
        end
    end)
    return button
end

local function createTab(title, page, y)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -25, 0, 35); btn.Position = UDim2.new(0, 15, 0, y); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); btn.Text = title; btn.TextColor3 = Color3.fromRGB(150, 150, 150); btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.ZIndex = 12; btn.Parent = sidebar; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        combatPage.Visible = false; visualPage.Visible = false; settingsPage.Visible = false; page.Visible = true; closeAllRightPanels()
        for _, v in pairs(sidebar:GetChildren()) do if v:IsA("TextButton") then v.BackgroundColor3 = Color3.fromRGB(20, 20, 20); v.TextColor3 = Color3.fromRGB(150, 150, 150) end end
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end
createTab("Combat", combatPage, 60); createTab("Visuals", visualPage, 105); createTab("Settings", settingsPage, 150)

-- НАСТРОЙКИ ПАРТИКЛОВ (ПКМ)
createDropdown(ParticlesRightPanel, "Цвет", 40, {{Name="Красный", Value=Color3.fromRGB(255,0,0)}, {Name="Синий", Value=Color3.fromRGB(0,150,255)}, {Name="Желтый", Value=Color3.fromRGB(255,255,0)}, {Name="Белый", Value=Color3.fromRGB(255,255,255)}}, 1, function(v) ParticleConfig.Color = v end)
createDropdown(ParticlesRightPanel, "Тип", 80, {{Name="Искры", Value="rbxassetid://243098098"}, {Name="Звезды", Value="rbxassetid://2173499710"}, {Name="Дым", Value="rbxassetid://243098118"}}, 1, function(v) ParticleConfig.Texture = v end)

-- НАСТРОЙКИ TARGET (ПКМ)
createDropdown(TargetRightPanel, "Кого бить", 40, {
    {Name = "Никто", Value = "None"},
    {Name = "Все подряд", Value = "All"},
    {Name = "Attackers", Value = "Attackers"},
    {Name = "Defenders", Value = "Defenders"},
    {Name = "По нику", Value = "Player"}
}, 1, function(v) TargetMode = v end)

local TargetInput = Instance.new("TextBox"); TargetInput.Size = UDim2.new(0.9, 0, 0, 30); TargetInput.Position = UDim2.new(0.05, 0, 0, 80); TargetInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TargetInput.Text = "Ник (если выбран)"; TargetInput.TextColor3 = Color3.fromRGB(200, 200, 200); TargetInput.Font = Enum.Font.Gotham; TargetInput.TextSize = 12; TargetInput.ZIndex = 13; TargetInput.ClearTextOnFocus = true; TargetInput.Parent = TargetRightPanel; Instance.new("UICorner", TargetInput).CornerRadius = UDim.new(0, 6)
TargetInput.FocusLost:Connect(function() TargetPlayerName = string.lower(TargetInput.Text) end)

-- НАСТРОЙКИ ИИ ДРОНА (ПКМ)
createDropdown(DroneRightPanel, "Тип", 40, {{Name="Скрытная", Value="Stealth"}, {Name="ТП", Value="TP"}, {Name="Авто", Value="Auto"}}, 1, function(v) DroneConfig.Type = v end)
createDropdown(DroneRightPanel, "Полет", 80, {{Name="Пульс", Value="Pulse"}, {Name="Серкл", Value="Circle"}, {Name="Рандом", Value="Random"}}, 1, function(v) DroneConfig.Flight = v end)

-- === 6. КНОПКИ ОСНОВНОГО МЕНЮ ===
createModuleButton(combatPage, "Safe Zone", "Отталкивает врагов. Выключится через 15 сек", function(s, stroke) Modules.SafeZone = s; if s then task.spawn(function() task.wait(15); if Modules.SafeZone then Modules.SafeZone = false; stroke.Color = Color3.fromRGB(40, 40, 40) end end) end end)
createModuleButton(combatPage, "Target Aim", "Наводит камеру на выбранные цели", function(state) Modules.TargetAim = state end)
createModuleButton(combatPage, "Auto Drone (AI)", "ЛКМ: Вкл автопилот | ПКМ: Настроить полет", function(state) Modules.AutoDrone = state end, function() closeAllRightPanels(); DroneRightPanel.Visible = true end)

createModuleButton(visualPage, "Player ESP", "Показывает боксы сквозь стены", function(state) Modules.PlayerEsp = state end)
createModuleButton(visualPage, "Tracers", "Рисует линии до игроков", function(state) Modules.Tracers = state end)
createModuleButton(visualPage, "Scope", "Рисует прицел в центре экрана", function(state) Modules.Scope = state end)
createModuleButton(visualPage, "Hit Particles", "ЛКМ: Вкл | ПКМ: Настройки", function(state) Modules.HitParticles = state end, function() closeAllRightPanels(); ParticlesRightPanel.Visible = true end)
createModuleButton(visualPage, "Target Config", "ЛКМ: Вкл (ESP) | ПКМ: Выбор цели", function(state) Modules.Target = state end, function() closeAllRightPanels(); TargetRightPanel.Visible = true end)

createModuleButton(settingsPage, "Theme: Azure & Gold", "Голубой и Желтый", function() updateTheme(Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 215, 0)) end)
createModuleButton(settingsPage, "Theme: Blood & Night", "Красный и Темно-серый", function() updateTheme(Color3.fromRGB(255, 20, 20), Color3.fromRGB(40, 40, 40)) end)

-- Перетаскивание
local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = mainFrame.Position; local c; c = UserInputService.InputEnded:Connect(function(e) if e.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false; c:Disconnect() end end) end end)
mainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputBegan:Connect(function(input, gp) if not gp and input.KeyCode == Enum.KeyCode.RightBracket then mainFrame.Visible = not mainFrame.Visible end end)

-- === 7. ЯДРО ЧИТА ===
local ScopeGui = Instance.new("ScreenGui", screenGui)
local function createLine(size, pos) local l = Instance.new("Frame", ScopeGui); l.BackgroundColor3 = Color3.fromRGB(0, 255, 255); l.BorderSizePixel = 0; l.Size = size; l.Position = pos; l.AnchorPoint = Vector2.new(0.5, 0.5); l.Visible = false; return l end
local scopeDot = createLine(UDim2.new(0, 4, 0, 4), UDim2.new(0.5, 0, 0.5, 0)); local scopeTop = createLine(UDim2.new(0, 2, 0, 10), UDim2.new(0.5, 0, 0.5, -10)); local scopeBot = createLine(UDim2.new(0, 2, 0, 10), UDim2.new(0.5, 0, 0.5, 10)); local scopeLeft = createLine(UDim2.new(0, 10, 0, 2), UDim2.new(0.5, -10, 0.5, 0)); local scopeRight = createLine(UDim2.new(0, 10, 0, 2), UDim2.new(0.5, 10, 0.5, 0))

local EspObjects = {}
local function createEspForPlayer(plr)
    if plr == LocalPlayer then return end
    local sBox, box = pcall(function() return Drawing.new("Square") end); local sLine, tracer = pcall(function() return Drawing.new("Line") end); local sTxt, targetText = pcall(function() return Drawing.new("Text") end)
    if not sBox or not sLine or not sTxt then return end
    box.Visible = false; box.Color = Color3.fromRGB(255, 170, 0); box.Thickness = 1; box.Filled = false; box.Transparency = 1; tracer.Visible = false; tracer.Color = Color3.fromRGB(255, 255, 255); tracer.Thickness = 1; tracer.Transparency = 0.6; targetText.Visible = false; targetText.Color = Color3.fromRGB(255, 0, 0); targetText.Text = "TARGET"; targetText.Size = 20; targetText.Center = true; targetText.Outline = true; targetText.Transparency = 1
    EspObjects[plr] = {Box = box, Tracer = tracer, Txt = targetText}
end
for _, plr in pairs(Players:GetPlayers()) do createEspForPlayer(plr) end
Players.PlayerAdded:Connect(createEspForPlayer)

Players.PlayerRemoving:Connect(function(plr)
    if EspObjects[plr] then pcall(function() EspObjects[plr].Box:Remove(); EspObjects[plr].Tracer:Remove(); EspObjects[plr].Txt:Remove() end); EspObjects[plr] = nil; PreviousHealths[plr] = nil end
end)

local function spawnHitParticle(targetPart)
    local att = Instance.new("Attachment", targetPart); local pe = Instance.new("ParticleEmitter", att); pe.Texture = ParticleConfig.Texture; pe.Color = ColorSequence.new(ParticleConfig.Color); pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 0)}); pe.Speed = NumberRange.new(15, 30); pe.SpreadAngle = Vector2.new(360, 360); pe.Lifetime = NumberRange.new(0.5, 1); pe.LightEmission = 1; pe.ZOffset = 1; pe.Rate = 200
    task.delay(0.5, function() pe.Enabled = false end); Debris:AddItem(att, 2)
end

local function getMyDrone()
    for _, v in pairs(workspace:GetChildren()) do
        if v:FindFirstChild("Mainpart") and v:IsA("Model") then
            if (v.Mainpart.Position - Camera.CFrame.Position).Magnitude < 150 then return v.Mainpart end
        end
    end
    return nil
end

local function isPlayerTarget(plr)
    if TargetMode == "None" then return false end
    if TargetMode == "All" then return true end
    if TargetMode == "Attackers" and plr.Team and plr.Team.Name == "Attackers" then return true end
    if TargetMode == "Defenders" and plr.Team and plr.Team.Name == "Defenders" then return true end
    if TargetMode == "Player" and TargetPlayerName ~= "" and string.find(string.lower(plr.Name), TargetPlayerName) then return true end
    return false
end

-- === ОСНОВНОЙ ЦИКЛ ОБНОВЛЕНИЯ ===
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    
    local showScope = Modules.Scope and myRoot ~= nil
    scopeDot.Visible = showScope; scopeTop.Visible = showScope; scopeBot.Visible = showScope; scopeLeft.Visible = showScope; scopeRight.Visible = showScope

    -- Поиск лучшей цели
    local bestTargetRoot = nil
    local shortestDist = math.huge
    local originPos = Camera.CFrame.Position
    local d = getMyDrone()
    if d then originPos = d.Position end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not plr.Character then continue end
        local eRoot = plr.Character:FindFirstChild("HumanoidRootPart")
        local eHum = plr.Character:FindFirstChild("Humanoid")
        
        if eRoot and eHum and eHum.Health > 0 then
            if Modules.HitParticles then
                local oldHp = PreviousHealths[plr] or eHum.MaxHealth
                if eHum.Health < oldHp then spawnHitParticle(eRoot) end
                PreviousHealths[plr] = eHum.Health
            end

            if Modules.SafeZone and myRoot and (eRoot.Position - myRoot.Position).Magnitude < 35 then
                eRoot.AssemblyLinearVelocity = (eRoot.Position - myRoot.Position).Unit * 160
            end

            local isT = isPlayerTarget(plr)
            if isT then
                local dToTarget = (eRoot.Position - originPos).Magnitude
                if dToTarget < shortestDist then
                    shortestDist = dToTarget
                    bestTargetRoot = eRoot
                end
            end

            local esp = EspObjects[plr]
            if esp then
                local pos, onScreen = Camera:WorldToViewportPoint(eRoot.Position)
                if Modules.PlayerEsp and onScreen then
                    local dist = (eRoot.Position - Camera.CFrame.Position).Magnitude
                    local boxSize = Vector2.new(4 * (1000/dist), 6 * (1000/dist))
                    if boxSize.Y > 200 then boxSize = Vector2.new(40, 60) end
                    esp.Box.Size = boxSize; esp.Box.Position = Vector2.new(pos.X - boxSize.X/2, pos.Y - boxSize.Y/2); esp.Box.Visible = true
                    if Modules.Target and isT then esp.Txt.Position = Vector2.new(pos.X, pos.Y - boxSize.Y/2 - 25); esp.Txt.Visible = true else esp.Txt.Visible = false end
                else
                    esp.Box.Visible = false; esp.Txt.Visible = false
                end

                if Modules.Tracers and onScreen then
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); esp.Tracer.To = Vector2.new(pos.X, pos.Y + (esp.Box.Size.Y / 2)); esp.Tracer.Visible = true
                else
                    esp.Tracer.Visible = false
                end
            end
        end
    end

    -- === ИСПРАВЛЕННЫЙ AUTO DRONE (С АНТИ-КРАШЕМ И НАСТРОЙКАМИ ПОЛЕТА) ===
    if Modules.AutoDrone and d and bestTargetRoot then
        local t = tick()
        
        -- Базовая точка полета (всегда НАД врагом на 20 стадов, чтобы не биться об пол)
        local baseTargetPos = bestTargetRoot.Position + Vector3.new(0, 20, 0)
        local offset = Vector3.new(0, 0, 0)

        -- ПРИМЕНЯЕМ СТИЛИ ПОЛЕТА (Влияют на оффсет от цели)
        if DroneConfig.Flight == "Pulse" then 
            offset = Vector3.new(0, math.sin(t * 5) * 20, 0) -- Прыгает вверх-вниз
        elseif DroneConfig.Flight == "Circle" then 
            offset = Vector3.new(math.cos(t * 2.5) * 30, 0, math.sin(t * 2.5) * 30) -- Крутится радиусом 30
        elseif DroneConfig.Flight == "Random" then 
            offset = Vector3.new(math.sin(t * 4) * 20, math.cos(t * 3) * 15, math.sin(t * 5) * 20) -- Бешеная муха
        end

        local finalTargetPos = baseTargetPos + offset

        -- АНТИ-КРАШ В СТЕНЫ И ПОЛ: 
        -- Если дрон слишком низко (ниже головы врага + 5 стадов), заставляем его лететь СТРОГО ВВЕРХ
        if d.Position.Y < bestTargetRoot.Position.Y + 5 then
            finalTargetPos = Vector3.new(d.Position.X, bestTargetRoot.Position.Y + 40, d.Position.Z)
        end

        -- ПРИМЕНЯЕМ ТИП ДВИЖЕНИЯ
        local distToTarget = (d.Position - finalTargetPos).Magnitude
        
        if DroneConfig.Type == "TP" then
            d.CFrame = CFrame.lookAt(finalTargetPos, bestTargetRoot.Position)
            d.AssemblyLinearVelocity = Vector3.zero
        else
            -- Stealth / Auto (Используем скорость для полета)
            if DroneConfig.Type == "Auto" and distToTarget > 200 then
                -- Если цель слишком далеко, авто-телепортируемся к ней
                d.CFrame = CFrame.lookAt(finalTargetPos, bestTargetRoot.Position)
            else
                -- Иначе плавно (но быстро) летим к рассчитанной точке
                local flyDirection = (finalTargetPos - d.Position).Unit
                d.AssemblyLinearVelocity = flyDirection * 120 -- Скорость дрона
                d.CFrame = CFrame.lookAt(d.Position, bestTargetRoot.Position) -- Всегда смотрит мордой на врага
            end
        end

        -- Камера летит сзади за дроном, чтобы было удобно смотреть
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = CFrame.lookAt(d.Position - (d.CFrame.LookVector * 25) + Vector3.new(0, 10, 0), bestTargetRoot.Position)
        
    elseif Modules.AutoDrone and not bestTargetRoot then
        -- Если дрон включен, но цель не выбрана в Target -> Возвращаем обычное управление
        Camera.CameraType = Enum.CameraType.Custom
    end

    -- TARGET AIM
    if Modules.TargetAim and bestTargetRoot and not Modules.AutoDrone then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, bestTargetRoot.Position)
    end
end)
