local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Очистка от старых версий (чтобы меню не дублировалось при перезапуске)
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("CelestialMenuGui")
if oldGui then oldGui:Destroy() end

-- Основной экран интерфейса
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CelestialMenuGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Главное окно меню
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 650, 0, 450)
mainFrame.Position = UDim2.new(0.5, -325, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18) -- Темный фон
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false -- Скрыто по умолчанию
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Боковая панель (Сайдбар)
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 180, 1, 0)
sidebar.Position = UDim2.new(0, 0, 0, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 12)
sidebarCorner.Parent = sidebar

-- Заголовок меню
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Celestial"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 24
titleLabel.Parent = sidebar

-- Контейнер для контента (правая часть)
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -190, 1, -20)
contentFrame.Position = UDim2.new(0, 190, 0, 10)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Вкладка Combat
local combatPage = Instance.new("ScrollingFrame")
combatPage.Name = "CombatPage"
combatPage.Size = UDim2.new(1, 0, 1, 0)
combatPage.BackgroundTransparency = 1
combatPage.ScrollBarThickness = 4
combatPage.Visible = true -- Открыта по умолчанию
combatPage.Parent = contentFrame

local combatLayout = Instance.new("UIListLayout")
combatLayout.Padding = UDim.new(0, 10)
combatLayout.SortOrder = Enum.SortOrder.LayoutOrder
combatLayout.Parent = combatPage

-- Вкладка Visuals
local visualPage = Instance.new("ScrollingFrame")
visualPage.Name = "VisualPage"
visualPage.Size = UDim2.new(1, 0, 1, 0)
visualPage.BackgroundTransparency = 1
visualPage.ScrollBarThickness = 4
visualPage.Visible = false
visualPage.Parent = contentFrame

local visualLayout = Instance.new("UIListLayout")
visualLayout.Padding = UDim.new(0, 10)
visualLayout.SortOrder = Enum.SortOrder.LayoutOrder
visualLayout.Parent = visualPage

-- УЛУЧШЕННАЯ Функция для создания кнопок (теперь поддерживает логику работы)
local function createModuleButton(parent, title, description, isEnabled, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 60)
    button.BackgroundColor3 = isEnabled and Color3.fromRGB(180, 80, 180) or Color3.fromRGB(30, 30, 35)
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -20, 0, 30)
    titleText.Position = UDim2.new(0, 10, 0, 5)
    titleText.BackgroundTransparency = 1
    titleText.Text = title
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = button

    local descText = Instance.new("TextLabel")
    descText.Size = UDim2.new(1, -20, 0, 20)
    descText.Position = UDim2.new(0, 10, 0, 30)
    descText.BackgroundTransparency = 1
    descText.Text = description
    descText.TextColor3 = Color3.fromRGB(170, 170, 170)
    descText.Font = Enum.Font.Gotham
    descText.TextSize = 12
    descText.TextWrapped = true
    descText.TextXAlignment = Enum.TextXAlignment.Left
    descText.Parent = button

    -- Логика переключения кнопки
    local active = isEnabled
    button.MouseButton1Click:Connect(function()
        active = not active
        if active then
            button.BackgroundColor3 = Color3.fromRGB(180, 80, 180) -- Розовый (включено)
        else
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 35) -- Темный (выключено)
        end
        
        -- Вызываем рабочую функцию чита, если она передана
        if callback then
            callback(active, button)
        end
    end)

    return button
end

-- === РАБОЧИЕ ФУНКЦИИ ЧИТА ===

local SafeMomentActive = false

-- Наполнение вкладки Combat
createModuleButton(combatPage, "Safe Moment", "Отталкивает игроков вокруг (Авто-отключение через 15 сек)", false, function(state, btn)
    SafeMomentActive = state
    
    if state then
        -- Запускаем таймер на 15 секунд в отдельном потоке
        task.spawn(function()
            task.wait(15)
            if SafeMomentActive then
                SafeMomentActive = false
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35) -- Возвращаем темный цвет кнопке
                print("Safe Moment автоматически отключен")
            end
        end)
    end
end)

createModuleButton(combatPage, "Ragdoll Aura", "Каждые 3 сек роняет игроков в радиусе (нужен серверный скрипт)", false)
createModuleButton(combatPage, "Attack Aura", "Автоматически атакует врагов рядом", false)
createModuleButton(combatPage, "Auto Heal", "Использует лечение при низком HP", false)

-- Наполнение вкладки Visuals (пустышки для будущих обновлений)
createModuleButton(visualPage, "Player ESP", "Показывает рамки и ники сквозь стены", false)
createModuleButton(visualPage, "Hit Particles", "Настраиваемые эффекты при нанесении урона", false)
createModuleButton(visualPage, "Tracers", "Рисует линии до других игроков", false)
createModuleButton(visualPage, "Chams", "Заливает модельки игроков цветом", false)
createModuleButton(visualPage, "Night Vision", "Делает карту светлой в темноте", false)
createModuleButton(visualPage, "No Fog", "Убирает туман на карте", false)
createModuleButton(visualPage, "Crosshair", "Кастомный прицел по центру экрана", false)

-- Кнопки переключения вкладок (Сайдбар)
local function createTabButton(title, targetPage, isSelected, positionY)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, -20, 0, 40)
    tabBtn.Position = UDim2.new(0, 10, 0, positionY)
    tabBtn.BackgroundColor3 = isSelected and Color3.fromRGB(180, 80, 180) or Color3.fromRGB(20, 20, 24)
    tabBtn.Text = title
    tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 14
    tabBtn.Parent = sidebar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = tabBtn

    tabBtn.MouseButton1Click:Connect(function()
        -- Скрываем все страницы
        combatPage.Visible = false
        visualPage.Visible = false
        
        -- Показываем нужную
        targetPage.Visible = true

        -- Сбрасываем цвета всех кнопок вкладок
        for _, child in ipairs(sidebar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
            end
        end
        -- Красим активную
        tabBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 180)
    end)
end

createTabButton("Combat", combatPage, true, 70)
createTabButton("Visuals", visualPage, false, 120)

-- ЛОГИКА ОТКРЫТИЯ/ЗАКРЫТИЯ НА КНОПКУ "Ъ" (Правая квадратная скобка)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 

    -- Enum.KeyCode.RightBracket = Кнопка "Ъ" на русской раскладке
    if input.KeyCode == Enum.KeyCode.RightBracket then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- === ГЛОБАЛЬНЫЙ ЦИКЛ ЧИТА (Здесь работает Safe Moment) ===
RunService.RenderStepped:Connect(function()
    -- Логика Safe Moment
    if SafeMomentActive then
        local character = LocalPlayer.Character
        local myRoot = character and character:FindFirstChild("HumanoidRootPart")
        
        if myRoot then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                    
                    if targetRoot then
                        local distance = (targetRoot.Position - myRoot.Position).Magnitude
                        
                        -- Если игрок ближе чем на 30 стадов (метров)
                        if distance < 30 then
                            -- Вычисляем направление от нас к нему и откидываем с силой 150
                            local pushDirection = (targetRoot.Position - myRoot.Position).Unit
                            targetRoot.AssemblyLinearVelocity = pushDirection * 150
                        end
                    end
                end
            end
        end
    end
end)
