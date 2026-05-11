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

    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 170, 255)),   -- Лазурный

    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 215, 0))    -- Желтый

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

titleLabel.Size = UDim2.new(1, -20, 0, 50)

titleLabel.Position = UDim2.new(0, 20, 0, 0)

titleLabel.BackgroundTransparency = 1

titleLabel.Text = "duck klient"

titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

titleLabel.Font = Enum.Font.GothamBlack

titleLabel.TextSize = 22

titleLabel.TextXAlignment = Enum.TextXAlignment.Left

titleLabel.ZIndex = 12

titleLabel.Parent = sidebar



local contentFrame = Instance.new("Frame")

contentFrame.Name = "Content"

contentFrame.Size = UDim2.new(1, -170, 1, -20)

contentFrame.Position = UDim2.new(0, 160, 0, 10)

contentFrame.BackgroundTransparency = 1

contentFrame.ZIndex = 11

contentFrame.Parent = mainFrame



local combatPage = Instance.new("ScrollingFrame")

combatPage.Size = UDim2.new(1, 0, 1, 0); combatPage.BackgroundTransparency = 1; combatPage.ScrollBarThickness = 2; combatPage.Visible = true; combatPage.Parent = contentFrame

Instance.new("UIListLayout", combatPage).Padding = UDim.new(0, 10)



local visualPage = Instance.new("ScrollingFrame")

visualPage.Size = UDim2.new(1, 0, 1, 0); visualPage.BackgroundTransparency = 1; visualPage.ScrollBarThickness = 2; visualPage.Visible = false; visualPage.Parent = contentFrame

Instance.new("UIListLayout", visualPage).Padding = UDim.new(0, 10)



local settingsPage = Instance.new("ScrollingFrame")

settingsPage.Size = UDim2.new(1, 0, 1, 0); settingsPage.BackgroundTransparency = 1; settingsPage.ScrollBarThickness = 2; settingsPage.Visible = false; settingsPage.Parent = contentFrame

Instance.new("UIListLayout", settingsPage).Padding = UDim.new(0, 10)



-- === 3. ПАНЕЛИ НАСТРОЕК СПРАВА ОТ МЕНЮ ===



local function createRightPanel(name, height)

    local panel = Instance.new("Frame")

    panel.Name = name

    panel.Size = UDim2.new(0, 200, 0, height or 220)

    panel.Position = UDim2.new(1, 10, 0, 0) 

    panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

    panel.Visible = false

    panel.ZIndex = 10

    panel.Parent = mainFrame

    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

    

    local gradOverlay = Instance.new("Frame")

    gradOverlay.Size = UDim2.new(1, 0, 1, 0)

    gradOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

    gradOverlay.BackgroundTransparency = 0.85

    gradOverlay.ZIndex = 10

    gradOverlay.Parent = panel

    Instance.new("UICorner", gradOverlay).CornerRadius = UDim.new(0, 8)



    local pGrad = Instance.new("UIGradient")

    pGrad.Color = MainGradientScheme

    pGrad.Rotation = 45

    pGrad.Parent = gradOverlay



    return panel, pGrad

end



local ParticlesRightPanel, pGrad1 = createRightPanel("ParticlesConfig", 220)

local TargetRightPanel, pGrad2 = createRightPanel("TargetConfig", 90)

local DroneRightPanel, pGrad3 = createRightPanel("DroneConfig", 250)



local function closeAllRightPanels()

    ParticlesRightPanel.Visible = false

    TargetRightPanel.Visible = false

    DroneRightPanel.Visible = false

end



-- === 4. ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ЧИТА ===

local Modules = {

    SafeZone = false,

    TargetAim = false,

    PlayerEsp = false,

    Tracers = false,

    Target = false,

    HitParticles = false,

    Scope = false,

    AutoDrone = false

}

local TargetPlayerName = ""

local ParticleConfig = {

    Color = Color3.fromRGB(255, 50, 50),

    Texture = "rbxassetid://243098098"

}

local DroneConfig = {

    Target = "",

    Type = "Stealth",

    Flight = "Pulse"

}

local PreviousHealths = {}



local function updateTheme(color1, color2)

    CurrentGradient = ColorSequence.new({

        ColorSequenceKeypoint.new(0.00, color1),

        ColorSequenceKeypoint.new(1.00, color2)

    })

    mainBgGradient.Color = CurrentGradient

    sideGrad.Color = CurrentGradient

    pGrad1.Color = CurrentGradient

    pGrad2.Color = CurrentGradient

    pGrad3.Color = CurrentGradient

end



-- === УТИЛИТЫ И КНОПКИ ===

local function createModuleButton(parent, title, description, lmbCallback, rmbCallback)

    local button = Instance.new("TextButton")

    button.Size = UDim2.new(1, -10, 0, 60)

    button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

    button.Text = ""

    button.AutoButtonColor = false

    button.ZIndex = 12

    button.Parent = parent

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    

    local uistroke = Instance.new("UIStroke")

    uistroke.Thickness = 2

    uistroke.Color = Color3.fromRGB(40, 40, 40)

    uistroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    uistroke.Parent = button



    local titleText = Instance.new("TextLabel")

    titleText.Size = UDim2.new(1, -20, 0, 30)

    titleText.Position = UDim2.new(0, 10, 0, 5)

    titleText.BackgroundTransparency = 1

    titleText.Text = title

    titleText.TextColor3 = Color3.fromRGB(200, 200, 200)

    titleText.Font = Enum.Font.GothamBold

    titleText.TextSize = 16

    titleText.TextXAlignment = Enum.TextXAlignment.Left

    titleText.ZIndex = 13

    titleText.Parent = button



    local descText = Instance.new("TextLabel")

    descText.Size = UDim2.new(1, -20, 0, 20)

    descText.Position = UDim2.new(0, 10, 0, 30)

    descText.BackgroundTransparency = 1

    descText.Text = description

    descText.TextColor3 = Color3.fromRGB(130, 130, 130)

    descText.Font = Enum.Font.Gotham

    descText.TextSize = 12

    descText.TextXAlignment = Enum.TextXAlignment.Left

    descText.ZIndex = 13

    descText.Parent = button



    local active = false

    button.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1 then

            active = not active

            if active then

                uistroke.Color = Color3.fromRGB(255, 255, 255)

                titleText.TextColor3 = Color3.fromRGB(255, 255, 255)

            else

                uistroke.Color = Color3.fromRGB(40, 40, 40)

                titleText.TextColor3 = Color3.fromRGB(200, 200, 200)

            end

            if lmbCallback then lmbCallback(active, uistroke) end

            

        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then

            if rmbCallback then rmbCallback() end

        end

    end)

    return button

end



local function createTab(title, page, y, selected)

    local btn = Instance.new("TextButton")

    btn.Size = UDim2.new(1, -25, 0, 35)

    btn.Position = UDim2.new(0, 15, 0, y)

    btn.BackgroundColor3 = selected and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(20, 20, 20)

    btn.Text = title

    btn.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)

    btn.Font = Enum.Font.GothamBold

    btn.TextSize = 14

    btn.ZIndex = 12

    btn.Parent = sidebar

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)



    btn.MouseButton1Click:Connect(function()

        combatPage.Visible = false; visualPage.Visible = false; settingsPage.Visible = false

        page.Visible = true

        closeAllRightPanels()

        

        for _, v in pairs(sidebar:GetChildren()) do

            if v:IsA("TextButton") then

                v.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

                v.TextColor3 = Color3.fromRGB(150, 150, 150)

            end

        end

        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

        btn.TextColor3 = Color3.fromRGB(255, 255, 255)

    end)

end



createTab("Combat", combatPage, 60, true)

createTab("Visuals", visualPage, 105, false)

createTab("Settings", settingsPage, 150, false)



-- === 5. ВЫДВИЖНЫЕ СПИСКИ (DROPDOWNS) ===

local function createDropdown(parent, titleText, yPos, options, defaultIndex, callback)

    local mainBtn = Instance.new("TextButton")

    mainBtn.Size = UDim2.new(0.9, 0, 0, 30)

    mainBtn.Position = UDim2.new(0.05, 0, 0, yPos)

    mainBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

    mainBtn.Text = titleText .. ": " .. options[defaultIndex].Name

    mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

    mainBtn.Font = Enum.Font.GothamBold

    mainBtn.TextSize = 12

    mainBtn.ZIndex = 14

    mainBtn.Parent = parent

    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 6)



    local dropFrame = Instance.new("Frame")

    dropFrame.Size = UDim2.new(1, 0, 0, #options * 30)

    dropFrame.Position = UDim2.new(0, 0, 1, 2)

    dropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

    dropFrame.Visible = false

    dropFrame.ZIndex = 20

    dropFrame.Parent = mainBtn

    Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 6)

    

    local layout = Instance.new("UIListLayout", dropFrame)

    layout.SortOrder = Enum.SortOrder.LayoutOrder



    mainBtn.MouseButton1Click:Connect(function() dropFrame.Visible = not dropFrame.Visible end)



    for i, opt in ipairs(options) do

        local optBtn = Instance.new("TextButton")

        optBtn.Size = UDim2.new(1, 0, 0, 30)

        optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

        optBtn.Text = opt.Name

        optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)

        optBtn.Font = Enum.Font.Gotham

        optBtn.TextSize = 12

        optBtn.ZIndex = 21

        optBtn.Parent = dropFrame



        optBtn.MouseButton1Click:Connect(function()

            mainBtn.Text = titleText .. ": " .. opt.Name

            dropFrame.Visible = false

            callback(opt.Value)

        end)

    end

end



-- НАСТРОЙКИ ПАРТИКЛОВ

local pTitle = Instance.new("TextLabel", ParticlesRightPanel)

pTitle.Size = UDim2.new(1, 0, 0, 40); pTitle.BackgroundTransparency = 1; pTitle.Text = "Настройки Партиклов"; pTitle.TextColor3 = Color3.fromRGB(255, 255, 255); pTitle.Font = Enum.Font.GothamBold; pTitle.ZIndex = 13



createDropdown(ParticlesRightPanel, "Цвет", 50, {

    {Name = "Красный", Value = Color3.fromRGB(255, 50, 50)},

    {Name = "Синий", Value = Color3.fromRGB(50, 150, 255)},

    {Name = "Желтый", Value = Color3.fromRGB(255, 215, 0)},

    {Name = "Белый", Value = Color3.fromRGB(255, 255, 255)}

}, 1, function(val) ParticleConfig.Color = val end)



createDropdown(ParticlesRightPanel, "Тип", 90, {

    {Name = "Искры", Value = "rbxassetid://243098098"},

    {Name = "Звезды", Value = "rbxassetid://2173499710"},

    {Name = "Дым", Value = "rbxassetid://243098118"}

}, 1, function(val) ParticleConfig.Texture = val end)





-- НАСТРОЙКИ TARGET

local tTitle = Instance.new("TextLabel", TargetRightPanel)

tTitle.Size = UDim2.new(1, 0, 0, 40); tTitle.BackgroundTransparency = 1; tTitle.Text = "Настройка Target"; tTitle.TextColor3 = Color3.fromRGB(255, 255, 255); tTitle.Font = Enum.Font.GothamBold; tTitle.ZIndex = 13



local TargetInput = Instance.new("TextBox")

TargetInput.Size = UDim2.new(0.9, 0, 0, 30)

TargetInput.Position = UDim2.new(0.05, 0, 0, 45)

TargetInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

TargetInput.Text = "Введи ник сюда"

TargetInput.TextColor3 = Color3.fromRGB(200, 200, 200)

TargetInput.Font = Enum.Font.Gotham

TargetInput.TextSize = 12

TargetInput.ZIndex = 13

TargetInput.ClearTextOnFocus = true

TargetInput.Parent = TargetRightPanel

Instance.new("UICorner", TargetInput).CornerRadius = UDim.new(0, 6)



TargetInput.FocusLost:Connect(function() TargetPlayerName = string.lower(TargetInput.Text) end)



-- НАСТРОЙКИ AUTO DRONE

local dTitle = Instance.new("TextLabel", DroneRightPanel)

dTitle.Size = UDim2.new(1, 0, 0, 40); dTitle.BackgroundTransparency = 1; dTitle.Text = "Настройка Auto Drone"; dTitle.TextColor3 = Color3.fromRGB(255, 255, 255); dTitle.Font = Enum.Font.GothamBold; dTitle.ZIndex = 13



local DroneInput = Instance.new("TextBox")

DroneInput.Size = UDim2.new(0.9, 0, 0, 30)

DroneInput.Position = UDim2.new(0.05, 0, 0, 40)

DroneInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

DroneInput.Text = "Ник цели для дрона"

DroneInput.TextColor3 = Color3.fromRGB(200, 200, 200)

DroneInput.Font = Enum.Font.Gotham

DroneInput.TextSize = 12

DroneInput.ZIndex = 13

DroneInput.ClearTextOnFocus = true

DroneInput.Parent = DroneRightPanel

Instance.new("UICorner", DroneInput).CornerRadius = UDim.new(0, 6)



DroneInput.FocusLost:Connect(function() DroneConfig.Target = string.lower(DroneInput.Text) end)



createDropdown(DroneRightPanel, "Тип", 80, {

    {Name = "Скрытная", Value = "Stealth"},

    {Name = "ТП", Value = "TP"},

    {Name = "Авто", Value = "Auto"}

}, 1, function(val) DroneConfig.Type = val end)



createDropdown(DroneRightPanel, "Полет", 120, {

    {Name = "Пульс", Value = "Pulse"},

    {Name = "Серкл", Value = "Circle"},

    {Name = "Рандом", Value = "Random"}

}, 1, function(val) DroneConfig.Flight = val end)





-- === 6. ДОБАВЛЕНИЕ КНОПОК ===



-- COMBAT

createModuleButton(combatPage, "Safe Zone", "Отталкивает врагов. Выключится через 15 сек", function(state, stroke)

    Modules.SafeZone = state

    if state then task.spawn(function() task.wait(15); if Modules.SafeZone then Modules.SafeZone = false; stroke.Color = Color3.fromRGB(40, 40, 40) end end) end

end)

createModuleButton(combatPage, "Target Aim", "Намертво наводит камеру на твой Target", function(state) Modules.TargetAim = state end)



createModuleButton(combatPage, "Auto Drone", "ЛКМ: Вкл/Выкл | ПКМ: Панель ИИ", 

    function(state) Modules.AutoDrone = state end,

    function() closeAllRightPanels(); DroneRightPanel.Visible = true end

)



-- VISUALS

createModuleButton(visualPage, "Player ESP", "Показывает 2D квадраты сквозь стены", function(state) Modules.PlayerEsp = state end)

createModuleButton(visualPage, "Tracers", "Рисует линии до игроков", function(state) Modules.Tracers = state end)

createModuleButton(visualPage, "Scope", "Рисует удобный прицел в центре экрана", function(state) Modules.Scope = state end)



createModuleButton(visualPage, "Hit Particles", "ЛКМ: Вкл/Выкл | ПКМ: Настройки", 

    function(state) Modules.HitParticles = state end,

    function() closeAllRightPanels(); ParticlesRightPanel.Visible = true end

)

createModuleButton(visualPage, "Target", "ЛКМ: Вкл/Выкл | ПКМ: Указать ник", 

    function(state) Modules.Target = state end,

    function() closeAllRightPanels(); TargetRightPanel.Visible = true end

)



-- SETTINGS

createModuleButton(settingsPage, "Theme: Azure & Gold", "Голубой и Желтый (Дефолт)", function(s) updateTheme(Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 215, 0)) end)

createModuleButton(settingsPage, "Theme: Blood & Night", "Красный и Темно-серый", function(s) updateTheme(Color3.fromRGB(255, 20, 20), Color3.fromRGB(40, 40, 40)) end)

createModuleButton(settingsPage, "Theme: Toxic Slime", "Кислотно-зеленый", function(s) updateTheme(Color3.fromRGB(50, 255, 50), Color3.fromRGB(0, 100, 0)) end)



-- Перетаскивание

local dragging, dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1 then

        dragging = true; dragStart = input.Position; startPos = mainFrame.Position

        local conn; conn = UserInputService.InputEnded:Connect(function(e)

            if e.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false; conn:Disconnect() end

        end)

    end

end)

mainFrame.InputChanged:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end

end)

UserInputService.InputChanged:Connect(function(input)

    if input == dragInput and dragging then

        local delta = input.Position - dragStart

        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)

    end

end)



UserInputService.InputBegan:Connect(function(input, gameProcessed)

    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.RightBracket then mainFrame.Visible = not mainFrame.Visible end

end)



-- === 7. ЯДРО ЧИТА ===



local ScopeGui = Instance.new("ScreenGui", screenGui)

local function createLine(size, pos)

    local l = Instance.new("Frame", ScopeGui)

    l.BackgroundColor3 = Color3.fromRGB(0, 255, 255)

    l.BorderSizePixel = 0; l.Size = size; l.Position = pos; l.AnchorPoint = Vector2.new(0.5, 0.5)

    l.Visible = false

    return l

end

local scopeDot = createLine(UDim2.new(0, 4, 0, 4), UDim2.new(0.5, 0, 0.5, 0))

local scopeTop = createLine(UDim2.new(0, 2, 0, 10), UDim2.new(0.5, 0, 0.5, -10))

local scopeBot = createLine(UDim2.new(0, 2, 0, 10), UDim2.new(0.5, 0, 0.5, 10))

local scopeLeft = createLine(UDim2.new(0, 10, 0, 2), UDim2.new(0.5, -10, 0.5, 0))

local scopeRight = createLine(UDim2.new(0, 10, 0, 2), UDim2.new(0.5, 10, 0.5, 0))



local EspObjects = {}



local function createEspForPlayer(plr)

    if plr == LocalPlayer then return end

    local sBox, box = pcall(function() return Drawing.new("Square") end)

    local sLine, tracer = pcall(function() return Drawing.new("Line") end)

    local sTxt, targetText = pcall(function() return Drawing.new("Text") end)

    if not sBox or not sLine or not sTxt then return end

    

    box.Visible = false; box.Color = Color3.fromRGB(255, 170, 0); box.Thickness = 1; box.Filled = false; box.Transparency = 1

    tracer.Visible = false; tracer.Color = Color3.fromRGB(255, 255, 255); tracer.Thickness = 1; tracer.Transparency = 0.6

    targetText.Visible = false; targetText.Color = Color3.fromRGB(255, 0, 0); targetText.Text = "TARGET"; targetText.Size = 20; targetText.Center = true; targetText.Outline = true; targetText.Transparency = 1



    EspObjects[plr] = {Box = box, Tracer = tracer, Txt = targetText}

end



for _, plr in pairs(Players:GetPlayers()) do createEspForPlayer(plr) end

Players.PlayerAdded:Connect(createEspForPlayer)



Players.PlayerRemoving:Connect(function(plr)

    if EspObjects[plr] then

        pcall(function() EspObjects[plr].Box:Remove() end)

        pcall(function() EspObjects[plr].Tracer:Remove() end)

        pcall(function() EspObjects[plr].Txt:Remove() end)

        EspObjects[plr] = nil; PreviousHealths[plr] = nil

    end

end)



-- УЛЬТИМАТИВНЫЕ ПАРТИКЛЫ (Светятся, непрерывно работают полсекунды)

local function spawnHitParticle(targetPart)

    local att = Instance.new("Attachment", targetPart)

    local pe = Instance.new("ParticleEmitter", att)

    pe.Texture = ParticleConfig.Texture

    pe.Color = ColorSequence.new(ParticleConfig.Color)

    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(10, 0)}) -- Огромные

    pe.Speed = NumberRange.new(100, 100)

    pe.SpreadAngle = Vector2.new(360, 360)

    pe.Lifetime = NumberRange.new(0.5, 1)

    pe.LightEmission = 1 -- Светятся в темноте!

    pe.ZOffset = 1 -- Всегда поверх текстур

    pe.Rate = 100 -- Плотный поток

    

    -- Спавним непрерывно полсекунды, потом плавно тушим

    task.delay(0.5, function()

        pe.Enabled = false

    end)

    Debris:AddItem(att, 2)

end



-- Функция поиска игрока по нику (для дрона)

local function getPlayerByName(nameFragment)

    if nameFragment == "" then return nil end

    for _, plr in pairs(Players:GetPlayers()) do

        if plr ~= LocalPlayer and string.find(string.lower(plr.Name), nameFragment) then

            return plr

        end

    end

    return nil

end



-- === ОСНОВНОЙ ЦИКЛ ОБНОВЛЕНИЯ ===

RunService.Heartbeat:Connect(function()

    local char = LocalPlayer.Character

    local myRoot = char and char:FindFirstChild("HumanoidRootPart")

    local myHum = char and char:FindFirstChild("Humanoid")

    

    local showScope = Modules.Scope and myRoot ~= nil

    scopeDot.Visible = showScope; scopeTop.Visible = showScope; scopeBot.Visible = showScope; scopeLeft.Visible = showScope; scopeRight.Visible = showScope



    if not myRoot then

        for _, obj in pairs(EspObjects) do

            obj.Box.Visible = false; obj.Tracer.Visible = false; obj.Txt.Visible = false

        end

        return 

    end



    -- AUTO DRONE LOGIC

    if Modules.AutoDrone and DroneConfig.Target ~= "" then

        local targetPlr = getPlayerByName(DroneConfig.Target)

        if targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") then

            local tRoot = targetPlr.Character.HumanoidRootPart

            local basePos = tRoot.Position

            local targetPos = basePos

            local t = tick()



            -- Применяем ПОЛЕТ (Модификатор позиции)

            if DroneConfig.Flight == "Pulse" then

                targetPos = targetPos + Vector3.new(0, math.sin(t * 8) * 15, 0)

            elseif DroneConfig.Flight == "Circle" then

                targetPos = targetPos + Vector3.new(math.cos(t * 3) * 15, 5, math.sin(t * 3) * 15)

            elseif DroneConfig.Flight == "Random" then

                targetPos = targetPos + Vector3.new(math.sin(t * 5) * 10, math.cos(t * 4) * 10, math.sin(t * 6) * 10)

            end



            -- Применяем ТИП (Модификатор движения)

            local distToTarget = (myRoot.Position - basePos).Magnitude

            if DroneConfig.Type == "TP" then

                myRoot.CFrame = CFrame.new(targetPos, tRoot.Position)

            elseif DroneConfig.Type == "Stealth" then

                if myHum then myHum:MoveTo(targetPos) end

            elseif DroneConfig.Type == "Auto" then

                if distToTarget > 100 then

                    myRoot.CFrame = CFrame.new(targetPos, tRoot.Position)

                else

                    if myHum then myHum:MoveTo(targetPos) end

                end

            end

        end

    end



    local currentTargetRoot = nil



    for _, plr in pairs(Players:GetPlayers()) do

        if plr == LocalPlayer then continue end

        

        local enemyChar = plr.Character

        local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")

        local enemyHum = enemyChar and enemyChar:FindFirstChild("Humanoid")

        

        if enemyRoot and enemyHum and enemyHum.Health > 0 then

            

            -- HIT PARTICLES

            if Modules.HitParticles then

                local oldHp = PreviousHealths[plr] or enemyHum.MaxHealth

                if enemyHum.Health < oldHp then spawnHitParticle(enemyRoot) end

                PreviousHealths[plr] = enemyHum.Health

            end



            local dist = (enemyRoot.Position - myRoot.Position).Magnitude

            

            -- SAFE ZONE

            if Modules.SafeZone and dist < 35 then

                enemyRoot.AssemblyLinearVelocity = (enemyRoot.Position - myRoot.Position).Unit * 160

            end



            local esp = EspObjects[plr]

            if not esp then continue end



            local pos, onScreen = Camera:WorldToViewportPoint(enemyRoot.Position)

            local isTarget = Modules.Target and TargetPlayerName ~= "" and string.find(string.lower(plr.Name), TargetPlayerName)



            if isTarget then currentTargetRoot = enemyRoot end

            

            -- ESP

            if Modules.PlayerEsp and onScreen then

                local scaleFactor = 1000 / dist

                local boxSize = Vector2.new(4 * scaleFactor, 6 * scaleFactor)

                if boxSize.Y > 200 then boxSize = Vector2.new(40, 60) end



                esp.Box.Size = boxSize

                esp.Box.Position = Vector2.new(pos.X - boxSize.X/2, pos.Y - boxSize.Y/2)

                esp.Box.Visible = true

                

                if isTarget then

                    esp.Txt.Position = Vector2.new(pos.X, pos.Y - boxSize.Y/2 - 25)

                    esp.Txt.Visible = true

                else

                    esp.Txt.Visible = false

                end

            else

                esp.Box.Visible = false; esp.Txt.Visible = false

            end



            -- TRACERS

            if Modules.Tracers and onScreen then

                esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

                esp.Tracer.To = Vector2.new(pos.X, pos.Y + (esp.Box.Size.Y / 2))

                esp.Tracer.Visible = true

            else

                esp.Tracer.Visible = false

            end

        else

            if EspObjects[plr] then

                EspObjects[plr].Box.Visible = false; EspObjects[plr].Tracer.Visible = false; EspObjects[plr].Txt.Visible = false

            end

        end

    end



    -- TARGET AIM (Аимбот камеры)

    if Modules.TargetAim and currentTargetRoot then

        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, currentTargetRoot.Position)

    end

end)
