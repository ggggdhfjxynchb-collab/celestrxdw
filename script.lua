local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- === 1. АБСОЛЮТНО БЕЗОПАСНАЯ ОЧИСТКА ===
pcall(function()
    local oldGui = PlayerGui:FindFirstChild("DuckKlientGui")
    if oldGui then oldGui:Destroy() end
end)

-- === 2. СОЗДАНИЕ GUI ===

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DuckKlientGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Дефолтная тема: Лазурно-Желтая
local CurrentGradient = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 170, 255)),   -- Лазурный (Голубой)
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 215, 0))    -- Желтый
})

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

local mainBgGradient = Instance.new("UIGradient")
mainBgGradient.Color = CurrentGradient
mainBgGradient.Rotation = 45
mainBgGradient.Transparency = NumberSequence.new(0.85)
mainBgGradient.Parent = mainFrame

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
sidebarGradientLine.ZIndex = 12
sidebarGradientLine.Parent = sidebar

local sideGrad = Instance.new("UIGradient")
sideGrad.Color = CurrentGradient
sideGrad.Rotation = 90
sideGrad.Parent = sidebarGradientLine

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 0, 50)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "duck klient"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 20
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
combatPage.Size = UDim2.new(1, 0, 1, 0)
combatPage.BackgroundTransparency = 1
combatPage.ScrollBarThickness = 2
combatPage.Visible = true
combatPage.Parent = contentFrame
Instance.new("UIListLayout", combatPage).Padding = UDim.new(0, 10)

local visualPage = Instance.new("ScrollingFrame")
visualPage.Size = UDim2.new(1, 0, 1, 0)
visualPage.BackgroundTransparency = 1
visualPage.ScrollBarThickness = 2
visualPage.Visible = false
visualPage.Parent = contentFrame
Instance.new("UIListLayout", visualPage).Padding = UDim.new(0, 10)

local settingsPage = Instance.new("ScrollingFrame")
settingsPage.Size = UDim2.new(1, 0, 1, 0)
settingsPage.BackgroundTransparency = 1
settingsPage.ScrollBarThickness = 2
settingsPage.Visible = false
settingsPage.Parent = contentFrame
Instance.new("UIListLayout", settingsPage).Padding = UDim.new(0, 10)

-- === 3. ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ЧИТА ===
local Modules = {
    SafeZone = false,
    PlayerEsp = false,
    Tracers = false,
    Target = false,
    HitParticles = false
}
local TargetPlayerName = ""
local ParticleConfig = {
    Color = Color3.fromRGB(255, 50, 50),
    Texture = "rbxassetid://243098098" -- Искры по умолчанию
}
local PreviousHealths = {} -- Для отслеживания урона

-- Функция обновления темы меню
local function updateTheme(color1, color2)
    CurrentGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, color1),
        ColorSequenceKeypoint.new(1.00, color2)
    })
    mainBgGradient.Color = CurrentGradient
    sideGrad.Color = CurrentGradient
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
        combatPage.Visible = false
        visualPage.Visible = false
        settingsPage.Visible = false
        page.Visible = true
        
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

-- === 4. ДОБАВЛЕНИЕ КНОПОК ===

-- COMBAT
createModuleButton(combatPage, "Safe Zone", "Отталкивает врагов. Выключится через 15 сек", function(state, stroke)
    Modules.SafeZone = state
    if state then
        task.spawn(function()
            task.wait(15)
            if Modules.SafeZone then
                Modules.SafeZone = false
                stroke.Color = Color3.fromRGB(40, 40, 40)
            end
        end)
    end
end)

-- VISUALS: ESP
createModuleButton(visualPage, "Player ESP", "Показывает 2D квадраты сквозь стены", function(state) Modules.PlayerEsp = state end)
createModuleButton(visualPage, "Tracers", "Рисует линии до игроков", function(state) Modules.Tracers = state end)

-- VISUALS: HIT PARTICLES (С ПКМ МЕНЮ)
local HitParticlesFrame = Instance.new("Frame")
HitParticlesFrame.Size = UDim2.new(1, -10, 0, 70)
HitParticlesFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
HitParticlesFrame.Visible = false
HitParticlesFrame.ZIndex = 12
HitParticlesFrame.Parent = visualPage
Instance.new("UICorner", HitParticlesFrame).CornerRadius = UDim.new(0, 8)

local function makeConfigBtn(parent, text, pos, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.3, 0, 0, 25)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.ZIndex = 13
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(callback)
end

-- Кнопки настройки партиклов
local clrLabel = Instance.new("TextLabel", HitParticlesFrame)
clrLabel.Size = UDim2.new(1, 0, 0, 20); clrLabel.Position = UDim2.new(0, 5, 0, 5); clrLabel.BackgroundTransparency = 1
clrLabel.Text = "Цвет: | Тип: "; clrLabel.TextColor3 = Color3.fromRGB(200, 200, 200); clrLabel.Font = Enum.Font.Gotham; clrLabel.TextSize = 12; clrLabel.TextXAlignment = Enum.TextXAlignment.Left; clrLabel.ZIndex = 13

makeConfigBtn(HitParticlesFrame, "Красный", UDim2.new(0.02, 0, 0, 30), function() ParticleConfig.Color = Color3.fromRGB(255, 50, 50) end)
makeConfigBtn(HitParticlesFrame, "Синий", UDim2.new(0.34, 0, 0, 30), function() ParticleConfig.Color = Color3.fromRGB(50, 150, 255) end)
makeConfigBtn(HitParticlesFrame, "Искры", UDim2.new(0.66, 0, 0, 5), function() ParticleConfig.Texture = "rbxassetid://243098098" end)
makeConfigBtn(HitParticlesFrame, "Звезды", UDim2.new(0.66, 0, 0, 35), function() ParticleConfig.Texture = "rbxassetid://2173499710" end)

createModuleButton(visualPage, "Hit Particles", "ЛКМ: Вкл/Выкл | ПКМ: Настройки партиклов", 
    function(state) Modules.HitParticles = state end,
    function() HitParticlesFrame.Visible = not HitParticlesFrame.Visible end
)

-- VISUALS: TARGET
local TargetSettingsFrame = Instance.new("Frame")
TargetSettingsFrame.Size = UDim2.new(1, -10, 0, 40)
TargetSettingsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TargetSettingsFrame.Visible = false
TargetSettingsFrame.ZIndex = 12
TargetSettingsFrame.Parent = visualPage
Instance.new("UICorner", TargetSettingsFrame).CornerRadius = UDim.new(0, 8)

local TargetInput = Instance.new("TextBox")
TargetInput.Size = UDim2.new(1, -20, 1, 0)
TargetInput.Position = UDim2.new(0, 10, 0, 0)
TargetInput.BackgroundTransparency = 1
TargetInput.Text = "Введи ник и нажми Enter"
TargetInput.TextColor3 = Color3.fromRGB(200, 200, 200)
TargetInput.Font = Enum.Font.Gotham
TargetInput.TextSize = 14
TargetInput.ZIndex = 13
TargetInput.ClearTextOnFocus = true
TargetInput.Parent = TargetSettingsFrame

TargetInput.FocusLost:Connect(function()
    TargetPlayerName = string.lower(TargetInput.Text)
end)

createModuleButton(visualPage, "Target", "ЛКМ: Вкл/Выкл | ПКМ: Настроить ник цели", 
    function(state) Modules.Target = state end,
    function() TargetSettingsFrame.Visible = not TargetSettingsFrame.Visible end
)

-- SETTINGS: Изменение визуала
createModuleButton(settingsPage, "Theme: Azure & Gold", "Голубой и Желтый (Дефолт)", function(s)
    updateTheme(Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 215, 0))
end)
createModuleButton(settingsPage, "Theme: Blood & Night", "Красный и Темно-серый", function(s)
    updateTheme(Color3.fromRGB(255, 20, 20), Color3.fromRGB(40, 40, 40))
end)
createModuleButton(settingsPage, "Theme: Toxic Slime", "Кислотно-зеленый", function(s)
    updateTheme(Color3.fromRGB(50, 255, 50), Color3.fromRGB(0, 100, 0))
end)

-- Перетаскивание меню
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

-- Управление скрытием
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightBracket then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- === 5. ЯДРО ЧИТА ===

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
        EspObjects[plr] = nil
        PreviousHealths[plr] = nil
    end
end)

-- Функция спавна партиклов
local function spawnHitParticle(targetPart)
    local att = Instance.new("Attachment", targetPart)
    local pe = Instance.new("ParticleEmitter", att)
    pe.Texture = ParticleConfig.Texture
    pe.Color = ColorSequence.new(ParticleConfig.Color)
    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
    pe.Speed = NumberRange.new(10, 20)
    pe.SpreadAngle = Vector2.new(360, 360)
    pe.Lifetime = NumberRange.new(0.5, 1)
    pe.Rate = 0
    pe:Emit(20)
    Debris:AddItem(att, 2)
end

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    
    if not myRoot then
        for _, obj in pairs(EspObjects) do
            obj.Box.Visible = false; obj.Tracer.Visible = false; obj.Txt.Visible = false
        end
        return 
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        
        local enemyChar = plr.Character
        local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
        local enemyHum = enemyChar and enemyChar:FindFirstChild("Humanoid")
        
        if enemyRoot and enemyHum and enemyHum.Health > 0 then
            
            -- HIT PARTICLES LOGIC
            if Modules.HitParticles then
                local oldHp = PreviousHealths[plr] or enemyHum.MaxHealth
                if enemyHum.Health < oldHp then
                    spawnHitParticle(enemyRoot) -- Спавним партиклы при падении ХП
                end
                PreviousHealths[plr] = enemyHum.Health
            end

            local dist = (enemyRoot.Position - myRoot.Position).Magnitude
            
            -- SAFE ZONE
            if Modules.SafeZone and dist < 35 then
                local direction = (enemyRoot.Position - myRoot.Position).Unit
                enemyRoot.AssemblyLinearVelocity = direction * 160
            end

            -- VISUALS ESP
            local esp = EspObjects[plr]
            if not esp then continue end

            local pos, onScreen = Camera:WorldToViewportPoint(enemyRoot.Position)
            
            if Modules.PlayerEsp and onScreen then
                local scaleFactor = 1000 / dist
                local boxSize = Vector2.new(4 * scaleFactor, 6 * scaleFactor)
                if boxSize.Y > 200 then boxSize = Vector2.new(40, 60) end

                esp.Box.Size = boxSize
                esp.Box.Position = Vector2.new(pos.X - boxSize.X/2, pos.Y - boxSize.Y/2)
                esp.Box.Visible = true
                
                if Modules.Target and TargetPlayerName ~= "" and string.find(string.lower(plr.Name), TargetPlayerName) then
                    esp.Txt.Position = Vector2.new(pos.X, pos.Y - boxSize.Y/2 - 25)
                    esp.Txt.Visible = true
                else
                    esp.Txt.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.Txt.Visible = false
            end

            if Modules.Tracers and onScreen then
                esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                esp.Tracer.To = Vector2.new(pos.X, pos.Y + (esp.Box.Size.Y / 2))
                esp.Tracer.Visible = true
            else
                esp.Tracer.Visible = false
            end
        else
            if EspObjects[plr] then
                EspObjects[plr].Box.Visible = false
                EspObjects[plr].Tracer.Visible = false
                EspObjects[plr].Txt.Visible = false
            end
        end
    end
end)
