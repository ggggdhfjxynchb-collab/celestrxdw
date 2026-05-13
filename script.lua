local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- === 1. СКРЫТАЯ ЗАГРУЗКА (CORE GUI) ===
local targetParent = nil
pcall(function() targetParent = gethui() end)
if not targetParent then pcall(function() targetParent = game:GetService("CoreGui") end) end
if not targetParent then targetParent = LocalPlayer:WaitForChild("PlayerGui") end

pcall(function()
    local oldGui = targetParent:FindFirstChild("DuckKlientGui")
    if oldGui then oldGui:Destroy() end
end)

-- === 2. СОЗДАНИЕ ГЛАВНОГО GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DuckKlientGui"; screenGui.ResetOnSpawn = false; screenGui.Parent = targetParent

local MainGradientScheme = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 170, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 215, 0))
})

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Duck_MainFrame"; mainFrame.Size = UDim2.new(0, 550, 0, 420); mainFrame.Position = UDim2.new(0.5, -275, 0.5, -210); mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); mainFrame.BorderSizePixel = 0; mainFrame.Visible = true; mainFrame.ZIndex = 10; mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local gradientOverlay = Instance.new("Frame")
gradientOverlay.Size = UDim2.new(1, 0, 1, 0); gradientOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255); gradientOverlay.BackgroundTransparency = 0.85; gradientOverlay.ZIndex = 10; gradientOverlay.Parent = mainFrame
Instance.new("UICorner", gradientOverlay).CornerRadius = UDim.new(0, 12)
local mainBgGradient = Instance.new("UIGradient"); mainBgGradient.Color = MainGradientScheme; mainBgGradient.Rotation = 45; mainBgGradient.Parent = gradientOverlay

local sidebar = Instance.new("Frame")
sidebar.Name = "Duck_Sidebar"; sidebar.Size = UDim2.new(0, 150, 1, 0); sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20); sidebar.BorderSizePixel = 0; sidebar.ZIndex = 11; sidebar.Parent = mainFrame
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

-- ЛОГОТИП
local duckLogo = Instance.new("ImageLabel")
duckLogo.Size = UDim2.new(0, 26, 0, 26); duckLogo.Position = UDim2.new(0, 12, 0, 12); duckLogo.BackgroundTransparency = 1; duckLogo.Image = "rbxassetid://132764620616937"; duckLogo.ZIndex = 12; duckLogo.Parent = sidebar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -45, 0, 50); titleLabel.Position = UDim2.new(0, 45, 0, 0); titleLabel.BackgroundTransparency = 1; titleLabel.Text = "duck klient"; titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); titleLabel.Font = Enum.Font.GothamBlack; titleLabel.TextSize = 18; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.ZIndex = 12; titleLabel.Parent = sidebar

local contentFrame = Instance.new("Frame")
contentFrame.Name = "Duck_Content"; contentFrame.Size = UDim2.new(1, -170, 1, -20); contentFrame.Position = UDim2.new(0, 160, 0, 10); contentFrame.BackgroundTransparency = 1; contentFrame.ZIndex = 11; contentFrame.Parent = mainFrame

local visualPage = Instance.new("ScrollingFrame"); visualPage.Name="Duck_VisPage"; visualPage.Size = UDim2.new(1, 0, 1, 0); visualPage.BackgroundTransparency = 1; visualPage.ScrollBarThickness = 2; visualPage.Visible = true; visualPage.Parent = contentFrame; Instance.new("UIListLayout", visualPage).Padding = UDim.new(0, 10)

-- === 3. TARGET INFO ПАНЕЛЬ (С ПОЛОСКОЙ ХП) ===
local targetInfoFrame = Instance.new("Frame")
targetInfoFrame.Name = "Duck_TargetInfo"; targetInfoFrame.Size = UDim2.new(0, 250, 0, 100); targetInfoFrame.Position = UDim2.new(1, -270, 0.5, -50); targetInfoFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); targetInfoFrame.Visible = false; targetInfoFrame.ZIndex = 10; targetInfoFrame.Parent = screenGui
Instance.new("UICorner", targetInfoFrame).CornerRadius = UDim.new(0, 8)
local tiStroke = Instance.new("UIStroke"); tiStroke.Color = Color3.fromRGB(0, 255, 255); tiStroke.Thickness = 2; tiStroke.Parent = targetInfoFrame
local tiGrad = Instance.new("UIGradient"); tiGrad.Color = MainGradientScheme; tiGrad.Rotation = 45; tiGrad.Parent = tiStroke

local targetAvatar = Instance.new("ImageLabel")
targetAvatar.Size = UDim2.new(0, 70, 0, 70); targetAvatar.Position = UDim2.new(0, 10, 0, 15); targetAvatar.BackgroundColor3 = Color3.fromRGB(30, 30, 30); targetAvatar.ZIndex = 11; targetAvatar.Parent = targetInfoFrame
Instance.new("UICorner", targetAvatar).CornerRadius = UDim.new(0, 8)

local targetName = Instance.new("TextLabel")
targetName.Size = UDim2.new(0, 150, 0, 25); targetName.Position = UDim2.new(0, 90, 0, 15); targetName.BackgroundTransparency = 1; targetName.Text = "PlayerName"; targetName.TextColor3 = Color3.fromRGB(255, 255, 255); targetName.Font = Enum.Font.GothamBold; targetName.TextSize = 14; targetName.TextXAlignment = Enum.TextXAlignment.Left; targetName.ZIndex = 11; targetName.Parent = targetInfoFrame

local targetAdvice = Instance.new("TextLabel")
targetAdvice.Size = UDim2.new(0, 150, 0, 20); targetAdvice.Position = UDim2.new(0, 90, 0, 40); targetAdvice.BackgroundTransparency = 1; targetAdvice.Text = "Анализ..."; targetAdvice.TextColor3 = Color3.fromRGB(0, 255, 255); targetAdvice.Font = Enum.Font.Gotham; targetAdvice.TextSize = 12; targetAdvice.TextXAlignment = Enum.TextXAlignment.Left; targetAdvice.ZIndex = 11; targetAdvice.Parent = targetInfoFrame

local hpBg = Instance.new("Frame")
hpBg.Size = UDim2.new(0, 140, 0, 14); hpBg.Position = UDim2.new(0, 90, 0, 65); hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40); hpBg.ZIndex = 11; hpBg.Parent = targetInfoFrame
Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 4)

local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.new(1, 0, 1, 0); hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0); hpFill.ZIndex = 12; hpFill.Parent = hpBg
Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 4)

local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.new(1, 0, 1, 0); hpText.BackgroundTransparency = 1; hpText.Text = "100%"; hpText.TextColor3 = Color3.fromRGB(255, 255, 255); hpText.Font = Enum.Font.GothamBold; hpText.TextSize = 10; hpText.ZIndex = 13; hpText.Parent = hpBg

-- === 4. ФУНКЦИЯ ПЕРЕТАСКИВАНИЯ ===
local function makeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = gui.Position
            local c; c = UserInputService.InputEnded:Connect(function(e)
                if e.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false; c:Disconnect() end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(mainFrame)
makeDraggable(targetInfoFrame)

UserInputService.InputBegan:Connect(function(input, gp) 
    if not gp and input.KeyCode == Enum.KeyCode.RightBracket then mainFrame.Visible = not mainFrame.Visible end 
end)

-- === 5. ПАНЕЛИ НАСТРОЕК ===
local function createRightPanel(name, height)
    local panel = Instance.new("Frame"); panel.Name = "Duck_" .. name; panel.Size = UDim2.new(0, 200, 0, height or 220); panel.Position = UDim2.new(1, 10, 0, 0); panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25); panel.Visible = false; panel.ZIndex = 10; panel.Parent = mainFrame; Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    local go = Instance.new("Frame"); go.Size = UDim2.new(1, 0, 1, 0); go.BackgroundColor3 = Color3.fromRGB(255, 255, 255); go.BackgroundTransparency = 0.85; go.ZIndex = 10; go.Parent = panel; Instance.new("UICorner", go).CornerRadius = UDim.new(0, 8)
    local pg = Instance.new("UIGradient"); pg.Color = MainGradientScheme; pg.Rotation = 45; pg.Parent = go
    return panel, pg
end

local ParticlesRightPanel = createRightPanel("ParticlesConfig", 180)
local SoundRightPanel = createRightPanel("SoundConfig", 100)
local TargetRightPanel = createRightPanel("TargetConfig", 160)

local function closeAllRightPanels()
    ParticlesRightPanel.Visible = false; SoundRightPanel.Visible = false; TargetRightPanel.Visible = false
end

-- === 6. ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ЧИТА ===
local Modules = { TargetInfo = false, EngineEsp = false, Tracers = false, WeakSpot = false, EngineChams = false, HitParticles = false, HitSound = false }
local TargetMode = "All" 
local TargetPlayerName = ""
local ParticleConfig = { Color = Color3.fromRGB(255, 50, 50), Texture = "rbxassetid://243098098" }
local SoundConfig = { Id = "rbxassetid://130972023" } 
local PreviousVelocities = {}

local LastHitPlayer = nil
local LastHitTime = 0
local CurrentTargetPlr = nil
local CarMaxPartsCache = {}

-- === 7. ФУНКЦИИ GUI ===
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
        closeAllRightPanels()
        for _, v in pairs(sidebar:GetChildren()) do if v:IsA("TextButton") then v.BackgroundColor3 = Color3.fromRGB(20, 20, 20); v.TextColor3 = Color3.fromRGB(150, 150, 150) end end
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end
createTab("Visuals", visualPage, 60)

createDropdown(ParticlesRightPanel, "Цвет", 40, {{Name="Красный", Value=Color3.fromRGB(255,0,0)}, {Name="Синий", Value=Color3.fromRGB(0,150,255)}, {Name="Желтый", Value=Color3.fromRGB(255,255,0)}}, 1, function(v) ParticleConfig.Color = v end)
createDropdown(ParticlesRightPanel, "Тип", 80, {{Name="Искры", Value="rbxassetid://243098098"}, {Name="Звезды", Value="rbxassetid://2173499710"}}, 1, function(v) ParticleConfig.Texture = v end)
createDropdown(SoundRightPanel, "Звук", 40, {{Name="Колокольчик", Value="rbxassetid://130972023"}, {Name="Удар 1", Value="rbxassetid://12222084"}, {Name="Металл", Value="rbxassetid://160432334"}}, 1, function(v) SoundConfig.Id = v end)
createDropdown(TargetRightPanel, "Кого бить", 40, {{Name = "Никто", Value = "None"}, {Name = "Все машины", Value = "All"}, {Name = "По нику", Value = "Player"}}, 2, function(v) TargetMode = v end)

local TargetInput = Instance.new("TextBox"); TargetInput.Size = UDim2.new(0.9, 0, 0, 30); TargetInput.Position = UDim2.new(0.05, 0, 0, 80); TargetInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TargetInput.Text = "Ник (если выбран)"; TargetInput.TextColor3 = Color3.fromRGB(200, 200, 200); TargetInput.Font = Enum.Font.Gotham; TargetInput.TextSize = 12; TargetInput.ZIndex = 13; TargetInput.ClearTextOnFocus = true; TargetInput.Parent = TargetRightPanel; Instance.new("UICorner", TargetInput).CornerRadius = UDim.new(0, 6)
TargetInput.FocusLost:Connect(function() TargetPlayerName = string.lower(TargetInput.Text) end)

-- === 8. КНОПКИ ОСНОВНОГО МЕНЮ ===
createModuleButton(visualPage, "Target Info (AI)", "Показывает ХП и инфу ПРИ ТАРАНЕ", function(state) Modules.TargetInfo = state; if not state then targetInfoFrame.Visible = false end end)
createModuleButton(visualPage, "Engine Chams", "Свечение самого мотора сквозь машину", function(state) Modules.EngineChams = state end)
createModuleButton(visualPage, "Weak Spot ESP", "Вычисляет идеальное место для тарана", function(state) Modules.WeakSpot = state end)
createModuleButton(visualPage, "Car Box ESP", "Рисует 2D боксы на машинах", function(state) Modules.EngineEsp = state end)
createModuleButton(visualPage, "Tracers", "Рисует линии до машин", function(state) Modules.Tracers = state end)
createModuleButton(visualPage, "Hit Particles", "ЛКМ: Вкл | ПКМ: Настройки", function(state) Modules.HitParticles = state end, function() closeAllRightPanels(); ParticlesRightPanel.Visible = true end)
createModuleButton(visualPage, "Hit Sounds", "ЛКМ: Звук при ударе | ПКМ: Выбрать", function(state) Modules.HitSound = state end, function() closeAllRightPanels(); SoundRightPanel.Visible = true end)
createModuleButton(visualPage, "Target Config", "ПКМ: Настроить авто-цель", function(state) Modules.Target = state end, function() closeAllRightPanels(); TargetRightPanel.Visible = true end)

-- === 9. ЯДРО ЧИТА ===
local EspObjects = {}

local function createEspForPlayer(plr)
    if plr == LocalPlayer then return end
    local sBox, box = pcall(function() return Drawing.new("Square") end); local sLine, tracer = pcall(function() return Drawing.new("Line") end)
    local sTxt, nametag = pcall(function() return Drawing.new("Text") end); local sWeak, weakTxt = pcall(function() return Drawing.new("Text") end)
    local sCirc, weakCirc = pcall(function() return Drawing.new("Circle") end)
    if not sBox or not sLine or not sTxt then return end
    box.Visible = false; box.Color = Color3.fromRGB(0, 200, 255); box.Thickness = 1.5; box.Transparency = 1
    tracer.Visible = false; tracer.Color = Color3.fromRGB(255, 255, 255); tracer.Thickness = 1; tracer.Transparency = 0.5
    nametag.Visible = false; nametag.Color = Color3.fromRGB(255, 255, 255); nametag.Size = 16; nametag.Center = true; nametag.Outline = true
    weakTxt.Visible = false; weakTxt.Color = Color3.fromRGB(255, 0, 0); weakTxt.Text = "[WEAK SPOT]"; weakTxt.Size = 18; weakTxt.Center = true; weakTxt.Outline = true
    weakCirc.Visible = false; weakCirc.Color = Color3.fromRGB(255, 0, 0); weakCirc.Thickness = 2; weakCirc.Radius = 15
    EspObjects[plr] = {Box = box, Tracer = tracer, Nametag = nametag, WeakTxt = weakTxt, WeakCirc = weakCirc}
end

for _, plr in pairs(Players:GetPlayers()) do createEspForPlayer(plr) end
Players.PlayerAdded:Connect(createEspForPlayer)

Players.PlayerRemoving:Connect(function(plr)
    if CurrentTargetPlr == plr then CurrentTargetPlr = nil; targetInfoFrame.Visible = false end
    if LastHitPlayer == plr then LastHitPlayer = nil end
    if EspObjects[plr] then pcall(function() EspObjects[plr].Box:Remove(); EspObjects[plr].Tracer:Remove(); EspObjects[plr].Nametag:Remove(); EspObjects[plr].WeakTxt:Remove(); EspObjects[plr].WeakCirc:Remove() end); EspObjects[plr] = nil; PreviousVelocities[plr] = nil end
end)

local function getCarData(plr)
    if not plr.Character then return nil, nil, nil end
    local hum = plr.Character:FindFirstChild("Humanoid")
    if hum and hum.SeatPart then
        local car = hum.SeatPart:FindFirstAncestorOfClass("Model")
        local rootPart = hum.SeatPart
        if car and car.PrimaryPart then rootPart = car.PrimaryPart end
        local engine = car and (car:FindFirstChild("Engine", true) or car:FindFirstChild("Core", true) or car:FindFirstChild("Motor", true))
        return car, rootPart, engine
    end
    return nil, nil, nil
end

local function getSafePosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then return obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetBoundingBox().Position end
    return nil
end

-- АЛГОРИТМ ЗДОРОВЬЯ (ПО ВИДИМЫМ ДЕТАЛЯМ КУЗОВА)
local function getCarHealth(carModel)
    if not carModel then return 100, 100 end
    local currentParts = 0
    for _, p in pairs(carModel:GetDescendants()) do
        -- Считаем только физические и видимые куски металла
        if p:IsA("BasePart") and p.Transparency < 0.8 and p.Name ~= "VehicleSeat" then 
            currentParts = currentParts + 1 
        end
    end
    if not CarMaxPartsCache[carModel] or currentParts > CarMaxPartsCache[carModel] then
        CarMaxPartsCache[carModel] = currentParts
    end
    return currentParts, CarMaxPartsCache[carModel]
end

local function getWeakSpotData(carRoot, enginePart)
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return carRoot.Position, "Нет данных" end
    local enginePos = getSafePosition(enginePart) or carRoot.Position
    local engineOffset = (enginePos - carRoot.Position):Dot(carRoot.CFrame.LookVector)
    local advice = "[БИТЬ В ДВЕРИ (T-BONE)]"
    local weakSpotPos = carRoot.Position
    if engineOffset > 3 then advice = "[БИТЬ В КАПОТ]"; weakSpotPos = carRoot.Position + (carRoot.CFrame.LookVector * 8)
    elseif engineOffset < -3 then advice = "[БИТЬ В БАГАЖНИК]"; weakSpotPos = carRoot.Position - (carRoot.CFrame.LookVector * 8)
    else
        local toEnemy = (carRoot.Position - myRoot.Position).Unit
        local sideMultiplier = (toEnemy:Dot(carRoot.CFrame.RightVector) > 0) and -1 or 1
        weakSpotPos = carRoot.Position + (carRoot.CFrame.RightVector * (6 * sideMultiplier))
    end
    return weakSpotPos, advice
end

local function updateTargetInfoPanel(plr, advice, health, maxHealth)
    if not Modules.TargetInfo then targetInfoFrame.Visible = false; return end
    targetInfoFrame.Visible = true
    if CurrentTargetPlr ~= plr then
        CurrentTargetPlr = plr; targetName.Text = plr.Name
        task.spawn(function() local t, r = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420); if r then targetAvatar.Image = t end end)
    end
    targetAdvice.Text = "Анализ ИИ: " .. advice
    local hpP = math.clamp(health / maxHealth, 0, 1)
    hpFill.Size = UDim2.new(hpP, 0, 1, 0)
    hpText.Text = "INTEGRITY: " .. math.floor(hpP * 100) .. "%"
    hpFill.BackgroundColor3 = hpP > 0.6 and Color3.new(0,1,0) or hpP > 0.3 and Color3.new(1,1,0) or Color3.new(1,0,0)
end

local function isPlayerTarget(plr)
    if TargetMode == "None" then return false end
    if TargetMode == "All" then return true end
    if TargetMode == "Player" and TargetPlayerName ~= "" and string.find(string.lower(plr.Name), TargetPlayerName) then return true end
    return false
end

-- === ОБНОВЛЕНИЕ ===
RunService.RenderStepped:Connect(function()
    local myCar, myCarRoot, _ = getCarData(LocalPlayer)
    local myVelChange = 0
    if myCarRoot then
        local curV = myCarRoot.AssemblyLinearVelocity
        local oldV = PreviousVelocities[LocalPlayer] or curV
        myVelChange = (oldV - curV).Magnitude
        PreviousVelocities[LocalPlayer] = curV
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local car, carRoot, engine = getCarData(plr)
        local esp = EspObjects[plr]
        
        -- ENGINE CHAMS (HIGHLIGHT)
        if Modules.EngineChams and engine and (engine:IsA("BasePart") or engine:IsA("Model")) then
            local hl = engine:FindFirstChild("Duck_EngineChams") or Instance.new("Highlight", engine)
            hl.Name = "Duck_EngineChams"; hl.FillColor = Color3.new(0,1,1); hl.FillTransparency = 0.3; hl.OutlineColor = Color3.new(1,1,1); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        elseif engine and engine:FindFirstChild("Duck_EngineChams") then engine.Duck_EngineChams:Destroy() end
        
        if carRoot and esp then
            local isT = isPlayerTarget(plr)
            local curV = carRoot.AssemblyLinearVelocity
            local oldV = PreviousVelocities[plr] or curV
            local velChange = (oldV - curV).Magnitude
            
            -- ДЕТЕКТОР УДАРА
            if velChange > 18 and myVelChange > 18 and (myCarRoot.Position - carRoot.Position).Magnitude < 30 then
                if Modules.HitParticles then
                    local p = Instance.new("Part", workspace); p.Transparency = 1; p.Anchored = true; p.Position = carRoot.Position; local a = Instance.new("Attachment", p); local pe = Instance.new("ParticleEmitter", a); pe.Texture = ParticleConfig.Texture; pe.Color = ColorSequence.new(ParticleConfig.Color); pe.Rate = 500; task.delay(0.4, function() pe.Enabled = false; task.wait(1); p:Destroy() end)
                end
                if Modules.HitSound then local s = Instance.new("Sound", SoundService); s.SoundId = SoundConfig.Id; s.Volume = 0.7; SoundService:PlayLocalSound(s); s:Destroy() end
                LastHitPlayer = plr; LastHitTime = tick()
            end
            PreviousVelocities[plr] = curV
            
            if isT then
                local pos, onS = Camera:WorldToViewportPoint(carRoot.Position)
                if onS then
                    if Modules.EngineEsp then
                        local scale = 1000 / (carRoot.Position - Camera.CFrame.Position).Magnitude
                        esp.Box.Size = Vector2.new(6 * scale, 4 * scale); esp.Box.Position = Vector2.new(pos.X - esp.Box.Size.X/2, pos.Y - esp.Box.Size.Y/2); esp.Box.Visible = true
                        esp.Nametag.Text = plr.Name; esp.Nametag.Position = Vector2.new(pos.X, pos.Y - esp.Box.Size.Y/2 - 15); esp.Nametag.Visible = true
                    else esp.Box.Visible = false; esp.Nametag.Visible = false end

                    if Modules.WeakSpot then
                        local wsP, advice = getWeakSpotData(carRoot, engine)
                        local wPos, wOn = Camera:WorldToViewportPoint(wsP)
                        if wOn then esp.WeakCirc.Position = Vector2.new(wPos.X, wPos.Y); esp.WeakCirc.Visible = true; esp.WeakTxt.Position = Vector2.new(wPos.X, wPos.Y - 25); esp.WeakTxt.Visible = true end
                    else esp.WeakCirc.Visible = false; esp.WeakTxt.Visible = false end

                    if Modules.Tracers then esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); esp.Tracer.To = Vector2.new(pos.X, pos.Y); esp.Tracer.Visible = true else esp.Tracer.Visible = false end
                else esp.Box.Visible = false; esp.Nametag.Visible = false; esp.Tracer.Visible = false; esp.WeakCirc.Visible = false; esp.WeakTxt.Visible = false end
            else esp.Box.Visible = false; esp.Nametag.Visible = false; esp.Tracer.Visible = false; esp.WeakCirc.Visible = false; esp.WeakTxt.Visible = false end
        end
    end

    -- АПДЕЙТ ТАРГЕТ ИНФО
    if LastHitPlayer and (tick() - LastHitTime < 10) then
        local car, carRoot, engine = getCarData(LastHitPlayer)
        if carRoot then
            local hp, max = getCarHealth(car)
            local _, advice = getWeakSpotData(carRoot, engine)
            updateTargetInfoPanel(LastHitPlayer, advice, hp, max)
        else targetInfoFrame.Visible = false end
    else targetInfoFrame.Visible = false; CurrentTargetPlr = nil end
end)
