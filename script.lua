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

-- Главное окно
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 550, 0, 420)
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15) 
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.ZIndex = 10
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- ГРАДИЕНТ
local gradientOverlay = Instance.new("Frame")
gradientOverlay.Size = UDim2.new(1, 0, 1, 0)
gradientOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
gradientOverlay.BackgroundTransparency = 0.85 
gradientOverlay.ZIndex = 10
gradientOverlay.Parent = mainFrame
Instance.new("UICorner", gradientOverlay).CornerRadius = UDim.new(0, 12)

local mainBgGradient = Instance.new("UIGradient")
mainBgGradient.Color = MainGradientScheme
mainBgGradient.Rotation = 45
mainBgGradient.Parent = gradientOverlay

-- Сайдбар
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 150, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 11
sidebar.Parent = mainFrame
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

local sidebarGradientLine = Instance.new("Frame")
sidebarGradientLine.Size = UDim2.new(0, 4, 1, -20)
sidebarGradientLine.Position = UDim2.new(0, 5, 0, 10)
sidebarGradientLine.BorderSizePixel = 0
sidebarGradientLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sidebarGradientLine.ZIndex = 12
sidebarGradientLine.Parent = sidebar

local sideGrad = Instance.new("UIGradient")
sideGrad.Color = MainGradientScheme
sideGrad.Rotation = 90
sideGrad.Parent = sidebarGradientLine

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 0, 50); titleLabel.Position = UDim2.new(0, 20, 0, 0); titleLabel.BackgroundTransparency = 1; titleLabel.Text = "duck klient"; titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); titleLabel.Font = Enum.Font.GothamBlack; titleLabel.TextSize = 22; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.ZIndex = 12; titleLabel.Parent = sidebar

local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"; contentFrame.Size = UDim2.new(1, -170, 1, -20); contentFrame.Position = UDim2.new(0, 160, 0, 10); contentFrame.BackgroundTransparency = 1; contentFrame.ZIndex = 11; contentFrame.Parent = mainFrame

local combatPage = Instance.new("ScrollingFrame")
combatPage.Size = UDim2.new(1, 0, 1, 0); combatPage.BackgroundTransparency = 1; combatPage.ScrollBarThickness = 2; combatPage.Visible = true; combatPage.Parent = contentFrame
Instance.new("UIListLayout", combatPage).Padding = UDim.new(0, 10)

local visualPage = Instance.new("ScrollingFrame")
visualPage.Size = UDim2.new(1, 0, 1, 0); visualPage.BackgroundTransparency = 1; visualPage.ScrollBarThickness = 2; visualPage.Visible = false; visualPage.Parent = contentFrame
Instance.new("UIListLayout", visualPage).Padding = UDim.new(0, 10)

local settingsPage = Instance.new("ScrollingFrame")
settingsPage.Size = UDim2.new(1, 0, 1, 0); settingsPage.BackgroundTransparency = 1; settingsPage.ScrollBarThickness = 2; settingsPage.Visible = false; settingsPage.Parent = contentFrame
Instance.new("UIListLayout", settingsPage).Padding = UDim.new(0, 10)

-- === 3. ПАНЕЛИ НАСТРОЕК ===

local function createRightPanel(name, height)
    local panel = Instance.new("Frame")
    panel.Name = name; panel.Size = UDim2.new(0, 200, 0, height or 220); panel.Position = UDim2.new(1, 10, 0, 0); panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25); panel.Visible = false; panel.ZIndex = 10; panel.Parent = mainFrame
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    local go = Instance.new("Frame"); go.Size = UDim2.new(1, 0, 1, 0); go.BackgroundColor3 = Color3.fromRGB(255, 255, 255); go.BackgroundTransparency = 0.85; go.ZIndex = 10; go.Parent = panel; Instance.new("UICorner", go).CornerRadius = UDim.new(0, 8)
    local pg = Instance.new("UIGradient"); pg.Color = MainGradientScheme; pg.Rotation = 45; pg.Parent = go
    return panel, pg
end

local ParticlesRightPanel, pGrad1 = createRightPanel("ParticlesConfig", 220)
local TargetRightPanel, pGrad2 = createRightPanel("TargetConfig", 90)
local DroneRightPanel, pGrad3 = createRightPanel("DroneConfig", 250)

local function closeAllRightPanels()
    ParticlesRightPanel.Visible = false; TargetRightPanel.Visible = false; DroneRightPanel.Visible = false
end

-- === 4. ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
local Modules = { SafeZone = false, TargetAim = false, PlayerEsp = false, Tracers = false, Target = false, HitParticles = false, Scope = false, AutoDrone = false }
local TargetPlayerName = ""
local ParticleConfig = { Color = Color3.fromRGB(255, 50, 50), Texture = "rbxassetid://243098098" }
local DroneConfig = { Target = "", Type = "Stealth", Flight = "Pulse" }
local PreviousHealths = {}
local DroneForwardVec = Vector3.new(0,0,-1)

local function updateTheme(color1, color2)
    local newGrad = ColorSequence.new({ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)})
    mainBgGradient.Color = newGrad; sideGrad.Color = newGrad; pGrad1.Color = newGrad; pGrad2.Color = newGrad; pGrad3.Color = newGrad
end

-- === 5. ФУНКЦИИ GUI ===
local function createDropdown(parent, titleText, yPos, options, defaultIndex, callback)
    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(0.9, 0, 0, 30); mainBtn.Position = UDim2.new(0.05, 0, 0, yPos); mainBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); mainBtn.Text = titleText .. ": " .. options[defaultIndex].Name; mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255); mainBtn.Font = Enum.Font.GothamBold; mainBtn.TextSize = 12; mainBtn.ZIndex = 14; mainBtn.Parent = parent
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 6)
    local dropFrame = Instance.new("Frame"); dropFrame.Size = UDim2.new(1, 0, 0, #options * 30); dropFrame.Position = UDim2.new(0, 0, 1, 2); dropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); dropFrame.Visible = false; dropFrame.ZIndex = 20; dropFrame.Parent = mainBtn; Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIListLayout", dropFrame).SortOrder = Enum.SortOrder.LayoutOrder
    mainBtn.MouseButton1Click:Connect(function() dropFrame.Visible = not dropFrame.Visible end)
    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 30); optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); optBtn.Text = opt.Name; optBtn.TextColor3 = Color3.fromRGB(200, 200, 200); optBtn.Font = Enum.Font.Gotham; optBtn.TextSize = 12; optBtn.ZIndex = 21; optBtn.Parent = dropFrame
        optBtn.MouseButton1Click:Connect(function() mainBtn.Text = titleText .. ": " .. opt.Name; dropFrame.Visible = false; callback(opt.Value) end)
    end
end

local function createModuleButton(parent, title, description, lmbCallback, rmbCallback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 60); button.BackgroundColor3 = Color3.fromRGB(25, 25, 25); button.Text = ""; button.AutoButtonColor = false; button.ZIndex = 12; button.Parent = parent
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
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

local function createTab(title, page, y, selected)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -25, 0, 35); btn.Position = UDim2.new(0, 15, 0, y); btn.BackgroundColor3 = selected and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(20, 20, 20); btn.Text = title; btn.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150); btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.ZIndex = 12; btn.Parent = sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        combatPage.Visible = false; visualPage.Visible = false; settingsPage.Visible = false; page.Visible = true
        closeAllRightPanels()
        for _, v in pairs(sidebar:GetChildren()) do if v:IsA("TextButton") then v.BackgroundColor3 = Color3.fromRGB(20, 20, 20); v.TextColor3 = Color3.fromRGB(150, 150, 150) end end
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end

createTab("Combat", combatPage, 60, true)
createTab("Visuals", visualPage, 105, false)
createTab("Settings", settingsPage, 150, false)

-- ВЫДВИЖНЫЕ СПИСКИ
createDropdown(ParticlesRightPanel, "Цвет", 50, {{Name="Красный", Value=Color3.fromRGB(255,0,0)}, {Name="Синий", Value=Color3.fromRGB(0,150,255)}, {Name="Желтый", Value=Color3.fromRGB(255,255,0)}, {Name="Белый", Value=Color3.fromRGB(255,255,255)}}, 1, function(val) ParticleConfig.Color = val end)
createDropdown(ParticlesRightPanel, "Тип", 90, {{Name="Искры", Value="rbxassetid://243098098"}, {Name="Звезды", Value="rbxassetid://2173499710"}, {Name="Дым", Value="rbxassetid://243098118"}}, 1, function(val) ParticleConfig.Texture = val end)

local TargetInput = Instance.new("TextBox"); TargetInput.Size = UDim2.new(0.9, 0, 0, 30); TargetInput.Position = UDim2.new(0.05, 0, 0, 45); TargetInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TargetInput.Text = "Введи ник сюда"; TargetInput.TextColor3 = Color3.fromRGB(200, 200, 200); TargetInput.Font = Enum.Font.Gotham; TargetInput.TextSize = 12; TargetInput.ZIndex = 13; TargetInput.ClearTextOnFocus = true; TargetInput.Parent = TargetRightPanel
TargetInput.FocusLost:Connect(function() TargetPlayerName = string.lower(TargetInput.Text) end)

local DroneInput = Instance.new("TextBox"); DroneInput.Size = UDim2.new(0.9, 0, 0, 30); DroneInput.Position = UDim2.new(0.05, 0, 0, 40); DroneInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30); DroneInput.Text = "Ник цели для дрона"; DroneInput.TextColor3 = Color3.fromRGB(200, 200, 200); DroneInput.Font = Enum.Font.Gotham; DroneInput.TextSize = 12; DroneInput.ZIndex = 13; DroneInput.ClearTextOnFocus = true; DroneInput.Parent = DroneRightPanel
DroneInput.FocusLost:Connect(function() DroneConfig.Target = string.lower(DroneInput.Text) end)

createDropdown(DroneRightPanel, "Тип", 80, {{Name="Аркада", Value="Stealth"}, {Name="ТП", Value="TP"}, {Name="Авто", Value="Auto"}}, 1, function(val) DroneConfig.Type = val end)
createDropdown(DroneRightPanel, "Полет", 120, {{Name="Пульс", Value="Pulse"}, {Name="Серкл", Value="Circle"}, {Name="Рандом", Value="Random"}}, 1, function(val) DroneConfig.Flight = val end)

-- === 6. КНОПКИ ===
createModuleButton(combatPage, "Safe Zone", "Отталкивает врагов. (15 сек)", function(state, stroke)
    Modules.SafeZone = state
    if state then task.spawn(function() task.wait(15); if Modules.SafeZone then Modules.SafeZone = false; stroke.Color = Color3.fromRGB(40, 40, 40) end end) end
end)
createModuleButton(combatPage, "Target Aim", "Наводит камеру на твой Target", function(state) Modules.TargetAim = state end)

-- ВШИТАЯ ЛОГИКА ДРОНА (ИЗ ВИДЕО)
createModuleButton(combatPage, "Auto Drone", "ЛКМ: Вкл | ПКМ: Настройки", 
    function(state) 
        Modules.AutoDrone = state 
        if state then
            local camC = Camera.CFrame
            DroneForwardVec = Vector3.new(camC.LookVector.X, 0, camC.LookVector.Z).Unit
            if DroneForwardVec.Magnitude < 0.1 then DroneForwardVec = Vector3.new(0,0,-1) end
        else
            Camera.CameraType = Enum.CameraType.Custom
        end
    end,
    function() closeAllRightPanels(); DroneRightPanel.Visible = true end
)

createModuleButton(visualPage, "Player ESP", "Боксы сквозь стены", function(state) Modules.PlayerEsp = state end)
createModuleButton(visualPage, "Tracers", "Линии до игроков", function(state) Modules.Tracers = state end)
createModuleButton(visualPage, "Scope", "Прицел по центру экрана", function(state) Modules.Scope = state end)
createModuleButton(visualPage, "Hit Particles", "ЛКМ: Вкл | ПКМ: Настройки", function(state) Modules.HitParticles = state end, function() closeAllRightPanels(); ParticlesRightPanel.Visible = true end)
createModuleButton(visualPage, "Target", "ЛКМ: Вкл | ПКМ: Указать ник", function(state) Modules.Target = state end, function() closeAllRightPanels(); TargetRightPanel.Visible = true end)

createModuleButton(settingsPage, "Theme: Azure & Gold", "Голубой и Желтый", function(s) updateTheme(Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 215, 0)) end)
createModuleButton(settingsPage, "Theme: Blood", "Красный и Темный", function(s) updateTheme(Color3.fromRGB(255, 20, 20), Color3.fromRGB(40, 40, 40)) end)

-- === 7. ЯДРО ЧИТА ===
local function getMyDrone()
    for _, v in pairs(workspace:GetChildren()) do
        if (v:IsA("Model") or v:IsA("BasePart")) and v:FindFirstChild("Mainpart") then
            if (v:FindFirstChild("Mainpart").Position - Camera.CFrame.Position).Magnitude < 150 then return v.Mainpart end
        end
    end
    return nil
end

local EspObjects = {}
local function createEspForPlayer(plr)
    if plr == LocalPlayer then return end
    local sBox, box = pcall(function() return Drawing.new("Square") end); local sLine, tracer = pcall(function() return Drawing.new("Line") end); local sTxt, targetText = pcall(function() return Drawing.new("Text") end)
    if not sBox or not sLine or not sTxt then return end
    box.Visible = false; box.Color = Color3.fromRGB(255, 170, 0); box.Thickness = 1; box.Transparency = 1; tracer.Visible = false; tracer.Color = Color3.fromRGB(255, 255, 255); tracer.Thickness = 1; tracer.Transparency = 0.6; targetText.Visible = false; targetText.Color = Color3.fromRGB(255, 0, 0); targetText.Text = "TARGET"; targetText.Size = 20; targetText.Center = true; targetText.Outline = true
    EspObjects[plr] = {Box = box, Tracer = tracer, Txt = targetText}
end
for _, plr in pairs(Players:GetPlayers()) do createEspForPlayer(plr) end
Players.PlayerAdded:Connect(createEspForPlayer)

local function spawnHitParticle(targetPart)
    local att = Instance.new("Attachment", targetPart); local pe = Instance.new("ParticleEmitter", att); pe.Texture = ParticleConfig.Texture; pe.Color = ColorSequence.new(ParticleConfig.Color); pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 0)}); pe.Speed = NumberRange.new(20, 50); pe.SpreadAngle = Vector2.new(360, 360); pe.LightEmission = 1; pe.Rate = 500
    task.delay(0.5, function() pe.Enabled = false end); Debris:AddItem(att, 2)
end

local sX = Instance.new("Frame", screenGui); sX.Size = UDim2.new(0,20,0,2); sX.Position = UDim2.new(0.5,0,0.5,0); sX.BackgroundColor3 = Color3.fromRGB(0,255,255); sX.Visible = false; sX.BorderSizePixel = 0; sX.AnchorPoint = Vector2.new(0.5,0.5)
local sY = Instance.new("Frame", screenGui); sY.Size = UDim2.new(0,2,0,20); sY.Position = UDim2.new(0.5,0,0.5,0); sY.BackgroundColor3 = Color3.fromRGB(0,255,255); sY.Visible = false; sY.BorderSizePixel = 0; sY.AnchorPoint = Vector2.new(0.5,0.5)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
    sX.Visible = Modules.Scope; sY.Visible = Modules.Scope

    -- АРКАДНЫЙ ДРОН (ЛОГИКА ИЗ ВИДЕО)
    if Modules.AutoDrone then
        local d = getMyDrone()
        if d then
            Camera.CameraType = Enum.CameraType.Scriptable
            local vVel = 0; local hVel = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then vVel = 60 end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then vVel = -60 end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then hVel = -50 end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then hVel = 50 end
            d.AssemblyLinearVelocity = (DroneForwardVec * 85) + Vector3.new(0, vVel, 0) + (workspace.CurrentCamera.CFrame.RightVector * hVel)
            d.CFrame = CFrame.new(d.Position, d.Position + DroneForwardVec)
            Camera.CFrame = CFrame.lookAt(d.Position - (DroneForwardVec * 35) + Vector3.new(0, 15, 0), d.Position)
        end
    end

    local aimT = nil
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not plr.Character then continue end
        local eRoot = plr.Character:FindFirstChild("HumanoidRootPart"); local eHum = plr.Character:FindFirstChild("Humanoid")
        if eRoot and eHum and eHum.Health > 0 then
            if Modules.HitParticles then
                local old = PreviousHealths[plr] or eHum.MaxHealth
                if eHum.Health < old then spawnHitParticle(eRoot) end
                PreviousHealths[plr] = eHum.Health
            end
            local isT = Modules.Target and TargetPlayerName ~= "" and string.find(string.lower(plr.Name), TargetPlayerName)
            if isT then aimT = eRoot end
            local esp = EspObjects[plr]; local pos, onS = Camera:WorldToViewportPoint(eRoot.Position)
            if esp then
                if Modules.PlayerEsp and onS then
                    local dist = (eRoot.Position - Camera.CFrame.Position).Magnitude
                    esp.Box.Size = Vector2.new(2000/dist, 3000/dist); esp.Box.Position = Vector2.new(pos.X - esp.Box.Size.X/2, pos.Y - esp.Box.Size.Y/2); esp.Box.Visible = true
                    if isT then esp.Txt.Position = Vector2.new(pos.X, pos.Y - esp.Box.Size.Y/2 - 20); esp.Txt.Visible = true else esp.Txt.Visible = false end
                else esp.Box.Visible = false; esp.Txt.Visible = false end
                if Modules.Tracers and onS then esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); esp.Tracer.To = Vector2.new(pos.X, pos.Y); esp.Tracer.Visible = true else esp.Tracer.Visible = false end
            end
            if Modules.SafeZone and root and (eRoot.Position - root.Position).Magnitude < 30 then eRoot.AssemblyLinearVelocity = (eRoot.Position - root.Position).Unit * 100 end
        end
    end
    if Modules.TargetAim and aimT then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, aimT.Position) end
end)

-- Перетаскивание и Ъ
local dragging, dStart, sPos; mainFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dStart = i.Position; sPos = mainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dStart; mainFrame.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.RightBracket then mainFrame.Visible = not mainFrame.Visible end end)
