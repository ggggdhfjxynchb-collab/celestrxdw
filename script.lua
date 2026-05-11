local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Очистка старых версий GUI и ESP
local function cleanup()
    local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("DuckKlientGui")
    if oldGui then oldGui:Destroy() end
    
    local oldEspContainer = CoreGui:FindFirstChild("EspContainer")
    if oldEspContainer then oldEspContainer:Destroy() end
end
cleanup()

-- === СОЗДАНИЕ GUI (Дизайн "duck klient") ===

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DuckKlientGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Тема чита: Желто-оранжевый градиент
local MainGradientScheme = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 215, 0)), -- Золотой (желтый)
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 120, 0))  -- Оранжевый
})

-- Главное окно
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 550, 0, 400) -- Немного компактнее
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Глубокий черный фон
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false -- Скрыто по умолчанию
mainFrame.ZIndex = 10
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Добавляем градиент на главный фон (Стиль чита)
local mainBgGradient = Instance.new("UIGradient")
mainBgGradient.Color = MainGradientScheme
mainBgGradient.Rotation = 45
mainBgGradient.Transparency = NumberSequence.new(0.9) -- Очень прозрачный градиент на фоне
mainBgGradient.Parent = mainFrame

-- Сайдбар
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 150, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 11
sidebar.Parent = mainFrame

Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

-- Градиентная полоска слева (Стиль!)
local sidebarGradientLine = Instance.new("Frame")
sidebarGradientLine.Size = UDim2.new(0, 4, 1, -20)
sidebarGradientLine.Position = UDim2.new(0, 5, 0, 10)
sidebarGradientLine.BorderSizePixel = 0
sidebarGradientLine.ZIndex = 12
sidebarGradientLine.Parent = sidebar

local sideGrad = Instance.new("UIGradient")
sideGrad.Color = MainGradientScheme
sideGrad.Rotation = 90
sideGrad.Parent = sidebarGradientLine

-- Заголовок duck klient
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

-- Контейнер контента
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -170, 1, -20)
contentFrame.Position = UDim2.new(0, 160, 0, 10)
contentFrame.BackgroundTransparency = 1
contentFrame.ZIndex = 11
contentFrame.Parent = mainFrame

-- Страницы
local combatPage = Instance.new("ScrollingFrame")
combatPage.Name = "CombatPage"
combatPage.Size = UDim2.new(1, 0, 1, 0)
combatPage.BackgroundTransparency = 1
combatPage.ScrollBarThickness = 2
combatPage.Visible = true
combatPage.Parent = contentFrame

Instance.new("UIListLayout", combatPage).Padding = UDim.new(0, 10)

local visualPage = Instance.new("ScrollingFrame")
visualPage.Name = "VisualPage"
visualPage.Size = UDim2.new(1, 0, 1, 0)
visualPage.BackgroundTransparency = 1
visualPage.ScrollBarThickness = 2
visualPage.Visible = false
visualPage.Parent = contentFrame

Instance.new("UIListLayout", visualPage).Padding = UDim.new(0, 10)

-- Функция создания кнопок (Желто-оранжевая тема)
local function createModuleButton(parent, title, description, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 60)
    button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    button.Text = ""
    button.AutoButtonColor = false
    button.ZIndex = 12
    button.Parent = parent

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    
    -- Градиент обводки (включено/выключено)
    local uistroke = Instance.new("UIStroke")
    uistroke.Thickness = 2
    uistroke.Color = Color3.fromRGB(40, 40, 40) -- Цвет выключенной обводки
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
    button.MouseButton1Click:Connect(function()
        active = not active
        if active then
            -- Включено: Красим обводку в оранжевый
            uistroke.Color = Color3.fromRGB(255, 140, 0)
            titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            -- Выключено
            uistroke.Color = Color3.fromRGB(40, 40, 40)
            titleText.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        if callback then callback(active, uistroke) end
    end)
end

-- Вкладки саидбара
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

-- === ЛОГИКА ФУНКЦИЙ ЧИТА (РАБОЧАЯ ЧАСТЬ) ===

local Modules = {
    SafeZone = false,
    PlayerEsp = false,
    Tracers = false
}

-- 1. COMBAT: Safe Zone (РАБОТАЕТ, отталкивает)
createModuleButton(combatPage, "Safe Zone", "Физически отталкивает врагов (15 сек)", function(state, stroke)
    Modules.SafeZone = state
    if state then
        task.spawn(function()
            task.wait(15)
            if Modules.SafeZone then
                Modules.SafeZone = false
                stroke.Color = Color3.fromRGB(40, 40, 40) -- Гасим кнопку
                print("Safe Zone отключена по таймеру")
            end
        end)
    end
end)

-- 2. VISUALS: Настройка ESP Системы
createModuleButton(visualPage, "Player ESP", "Показывает 2D квадраты сквозь стены", function(state)
    Modules.PlayerEsp = state
end)

createModuleButton(visualPage, "Tracers", "Рисует линии до игроков", function(state)
    Modules.Tracers = state
end)

-- Управление открытием на Ъ (RightBracket)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightBracket then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- === ЯДРО ЧИТА (CORE LOGIC) ===

-- Создаем контейнер для ESP рисунков (Folder в CoreGui, чтобы не удалялось при спавне)
local EspContainer = Instance.new("Folder")
EspContainer.Name = "EspContainer"
pcall(function() EspContainer.Parent = game:GetService("CoreGui") end) 
if not EspContainer.Parent then EspContainer.Parent = LocalPlayer.PlayerGui end -- Резервный вариант

-- Таблица для хранения Drawing объектов каждого игрока
local EspObjects = {}

local function createEspForPlayer(plr)
    if plr == LocalPlayer then return end
    
    -- Создаем рисунки (Drawing API - работает только в экзекуторах типа Xeno)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 170, 0) -- Желто-оранжевый ESP
    box.Thickness = 1
    box.Filled = false
    box.Transparency = 1

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Color3.fromRGB(255, 255, 255) -- Белые линии
    tracer.Thickness = 1
    tracer.Transparency = 0.6

    EspObjects[plr] = {Box = box, Tracer = tracer}
end

-- Создаем ESP для тех, кто уже на сервере
for _, plr in pairs(Players:GetPlayers()) do createEspForPlayer(plr) end
-- И для новых
Players.PlayerAdded:Connect(createEspForPlayer)
-- Удаляем при выходе
Players.PlayerRemoving:Connect(function(plr)
    if EspObjects[plr] then
        EspObjects[plr].Box:Remove()
        EspObjects[plr].Tracer:Remove()
        EspObjects[plr] = nil
    end
end)

-- ОСНОВНОЙ ЦИКЛ ОБНОВЛЕНИЯ (RenderStepped - 60 раз в секунду)
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    
    if not myRoot then
        -- Если мы мертвы, скрываем весь ESP
        for _, obj in pairs(EspObjects) do
            obj.Box.Visible = false
            obj.Tracer.Visible = false
        end
        return 
    end

    -- Перебираем всех игроков для SafeZone и ESP
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        
        local enemyChar = plr.Character
        local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
        local enemyHum = enemyChar and enemyChar:FindFirstChild("Humanoid")
        
        if enemyRoot and enemyHum and enemyHum.Health > 0 then
            local dist = (enemyRoot.Position - myRoot.Position).Magnitude
            
            -- === ЛОГИКА SAFE ZONE ===
            if Modules.SafeZone and dist < 35 then -- Радиус 35 стадов
                -- Вычисляем направление от нас к нему
                local direction = (enemyRoot.Position - myRoot.Position).Unit
                -- Применяем жесткий импульс, чтобы откинуть врага
                enemyRoot.AssemblyLinearVelocity = direction * 160 -- Сила отталкивания
            end

            -- === ЛОГИКА ESP (Visuals) ===
            local esp = EspObjects[plr]
            if not esp then continue end

            local pos, onScreen = Camera:WorldToViewportPoint(enemyRoot.Position)
            
            -- Обновление Player ESP (Box)
            if Modules.PlayerEsp and onScreen then
                -- Вычисляем размер квадрата в зависимости от дистанции
                local scaleFactor = 1000 / dist
                local boxSize = Vector2.new(4 * scaleFactor, 6 * scaleFactor)
                if boxSize.Y > 200 then boxSize = Vector2.new(40, 60) end -- Ограничиваем макс размер рядом

                esp.Box.Size = boxSize
                esp.Box.Position = Vector2.new(pos.X - boxSize.X/2, pos.Y - boxSize.Y/2)
                esp.Box.Visible = true
            else
                esp.Box.Visible = false
            end

            -- Обновление Tracers (Линии)
            if Modules.Tracers and onScreen then
                esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) -- Центр низа экрана
                esp.Tracer.To = Vector2.new(pos.X, pos.Y + (esp.Box.Size.Y / 2)) -- К ногам врага
                esp.Tracer.Visible = true
            else
                esp.Tracer.Visible = false
            end

        else
            -- Если враг мертв или скрыт, скрываем его ESP
            if EspObjects[plr] then
                EspObjects[plr].Box.Visible = false
                EspObjects[plr].Tracer.Visible = false
            end
        end
    end
end)
