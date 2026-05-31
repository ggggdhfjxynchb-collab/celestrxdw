local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- === 1. ЗАГРУЗКА И ОЧИСТКА ===
local targetParent = nil
pcall(function() targetParent = gethui() end)
if not targetParent then pcall(function() targetParent = game:GetService("CoreGui") end) end
if not targetParent then targetParent = LocalPlayer:WaitForChild("PlayerGui") end

pcall(function()
    local oldGui = targetParent:FindFirstChild("MonogrammaKlient")
    if oldGui then oldGui:Destroy() end
end)

-- === 2. НАСТРОЙКИ ЧИТА ===
local Mono = {
    Aimbot = { Enabled = false, Key = Enum.KeyCode.C, TargetPart = "Head" },
    AutoTap = { Enabled = false, Key = Enum.KeyCode.V, Delay = 0.05 },
    ESP = { Enabled = false },
    MenuOpen = true
}

local LastShootTime = 0
local BindingAimbot = false
local BindingAutoTap = false

-- === 3. СОЗДАНИЕ ИНТЕРФЕЙСА (ЛАВАНДОВЫЙ СТИЛЬ) ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonogrammaKlient"
screenGui.ResetOnSpawn = false
screenGui.Parent = targetParent

-- Цветовая схема Monogramma
local LavenderGradient = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(180, 130, 255)), -- Светло-лавандовый
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(110, 60, 220))   -- Темно-фиолетовый
})

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 280)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -140)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25) -- Темно-фиолетовый фон
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- Разблокировка мыши
local unlockMouseBtn = Instance.new("TextButton")
unlockMouseBtn.Size = UDim2.new(0, 0, 0, 0)
unlockMouseBtn.BackgroundTransparency = 1
unlockMouseBtn.Text = ""
unlockMouseBtn.Modal = true
unlockMouseBtn.Parent = mainFrame

-- Обводка
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Thickness = 2
local strokeGrad = Instance.new("UIGradient", uiStroke)
strokeGrad.Color = LavenderGradient
strokeGrad.Rotation = 45

-- Шапка
local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundTransparency = 1

local logoText = Instance.new("TextLabel", header)
logoText.Size = UDim2.new(0, 40, 0, 40)
logoText.Position = UDim2.new(0, 5, 0, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "⬟" -- Символ пентагона
logoText.TextColor3 = Color3.fromRGB(180, 130, 255)
logoText.Font = Enum.Font.GothamBlack
logoText.TextSize = 24

local logoDot = Instance.new("TextLabel", logoText)
logoDot.Size = UDim2.new(1, 0, 1, 0)
logoDot.BackgroundTransparency = 1
logoDot.Text = "•"
logoDot.TextColor3 = Color3.fromRGB(255, 255, 255)
logoDot.Font = Enum.Font.GothamBlack
logoDot.TextSize = 14

-- ТУТ МОЖЕШЬ ВСТАВИТЬ СВОЮ КАРТИНКУ ПЕНТАГОНА
local logoImage = Instance.new("ImageLabel", header)
logoImage.Size = UDim2.new(0, 26, 0, 26)
logoImage.Position = UDim2.new(0, 12, 0, 7)
logoImage.BackgroundTransparency = 1
logoImage.Image = "" -- ВСТАВЬ СЮДА ID КАРТИНКИ (например: "rbxassetid://12345678")
logoImage.ZIndex = 2

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 45, 0, 0)
title.BackgroundTransparency = 1
title.Text = "MONOGRAMMA  |  Press ']' to hide"
title.TextColor3 = Color3.fromRGB(230, 230, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

-- Линия под шапкой
local headerLine = Instance.new("Frame", mainFrame)
headerLine.Size = UDim2.new(1, -20, 0, 2)
headerLine.Position = UDim2.new(0, 10, 0, 40)
headerLine.BorderSizePixel = 0
local lineGrad = Instance.new("UIGradient", headerLine)
lineGrad.Color = LavenderGradient

-- Контейнер контента
local content = Instance.new("ScrollingFrame", mainFrame)
content.Size = UDim2.new(1, -20, 1, -60)
content.Position = UDim2.new(0, 10, 0, 50)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 2
content.ScrollBarImageColor3 = Color3.fromRGB(180, 130, 255)
local listLayout = Instance.new("UIListLayout", content)
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- === ФУНКЦИИ GUI ===
local function createToggleWithBind(parent, text, defaultState, defaultBind, onToggle, onBind)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 200, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local status = Instance.new("Frame", frame)
    status.Size = UDim2.new(0, 16, 0, 16)
    status.Position = UDim2.new(0, 200, 0.5, -8)
    status.BackgroundColor3 = defaultState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)
    
    local bindBtn = Instance.new("TextButton", frame)
    bindBtn.Size = UDim2.new(0, 100, 0, 26)
    bindBtn.Position = UDim2.new(1, -110, 0.5, -13)
    bindBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    bindBtn.Text = defaultBind and defaultBind.Name or "None"
    bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bindBtn.Font = Enum.Font.Gotham
    bindBtn.TextSize = 12
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)

    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        status.BackgroundColor3 = state and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
        btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        onToggle(state)
    end)

    bindBtn.MouseButton1Click:Connect(function()
        bindBtn.Text = "..."
        onBind(bindBtn)
    end)
end

-- Создаем элементы
createToggleWithBind(content, "Aimbot (Auto-Aim)", Mono.Aimbot.Enabled, Mono.Aimbot.Key, 
    function(s) Mono.Aimbot.Enabled = s end,
    function(btn) BindingAimbot = true; btn.Text = "Press Key..." end
)

createToggleWithBind(content, "Auto Tap (Auto Shoot)", Mono.AutoTap.Enabled, Mono.AutoTap.Key, 
    function(s) Mono.AutoTap.Enabled = s end,
    function(btn) BindingAutoTap = true; btn.Text = "Press Key..." end
)

local espFrame = Instance.new("Frame", content)
espFrame.Size = UDim2.new(1, 0, 0, 40); espFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35); Instance.new("UICorner", espFrame).CornerRadius = UDim.new(0, 6)
local espBtn = Instance.new("TextButton", espFrame)
espBtn.Size = UDim2.new(1, 0, 1, 0); espBtn.BackgroundTransparency = 1; espBtn.Text = "  Wallhack (ESP)"; espBtn.TextColor3 = Color3.fromRGB(200, 200, 200); espBtn.Font = Enum.Font.GothamMedium; espBtn.TextSize = 14; espBtn.TextXAlignment = Enum.TextXAlignment.Left
local espStatus = Instance.new("Frame", espFrame)
espStatus.Size = UDim2.new(0, 16, 0, 16); espStatus.Position = UDim2.new(1, -30, 0.5, -8); espStatus.BackgroundColor3 = Color3.fromRGB(60, 60, 70); Instance.new("UICorner", espStatus).CornerRadius = UDim.new(1, 0)

espBtn.MouseButton1Click:Connect(function()
    Mono.ESP.Enabled = not Mono.ESP.Enabled
    espStatus.BackgroundColor3 = Mono.ESP.Enabled and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
    espBtn.TextColor3 = Mono.ESP.Enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
end)

-- Перетаскивание
local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = mainFrame.Position
        local c; c = UserInputService.InputEnded:Connect(function(e)
            if e.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false; c:Disconnect() end
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

-- Обработка биндов и скрытия меню
UserInputService.InputBegan:Connect(function(input, gp)
    if BindingAimbot and input.UserInputType == Enum.UserInputType.Keyboard then
        Mono.Aimbot.Key = input.KeyCode
        BindingAimbot = false
        -- Обновляем текст кнопки вручную через поиск
        for _, v in pairs(content:GetChildren()) do
            if v:IsA("Frame") and v:FindFirstChild("TextButton") and v.TextButton.Text == "  Aimbot (Auto-Aim)" then
                v:GetChildren()[3].Text = input.KeyCode.Name
            end
        end
        return
    end

    if BindingAutoTap and input.UserInputType == Enum.UserInputType.Keyboard then
        Mono.AutoTap.Key = input.KeyCode
        BindingAutoTap = false
        for _, v in pairs(content:GetChildren()) do
            if v:IsA("Frame") and v:FindFirstChild("TextButton") and v.TextButton.Text == "  Auto Tap (Auto Shoot)" then
                v:GetChildren()[3].Text = input.KeyCode.Name
            end
        end
        return
    end

    if not gp and input.KeyCode == Enum.KeyCode.RightBracket then
        Mono.MenuOpen = not Mono.MenuOpen
        mainFrame.Visible = Mono.MenuOpen
        unlockMouseBtn.Modal = Mono.MenuOpen
    end
end)

-- === 4. ЯДРО ЧИТА (АЛГОРИТМЫ) ===

-- Проверка: враг ли это?
local function isEnemy(plr)
    if plr == LocalPlayer then return false end
    if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
    return true
end

-- Проверка: Виден ли игрок (Raycast)
local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 1000
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, rayParams)
    if result and result.Instance then
        if result.Instance:IsDescendantOf(targetPart.Parent) then
            return true -- Стен нет
        end
    end
    return false -- Спрятался
end

-- Поиск цели
local function getClosestVisibleEnemy()
    local closestTarget = nil
    local shortestDistance = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in pairs(Players:GetPlayers()) do
        if isEnemy(plr) and plr.Character and plr.Character:FindFirstChild(Mono.Aimbot.TargetPart) and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local targetPart = plr.Character[Mono.Aimbot.TargetPart]
            local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < shortestDistance and dist < 300 then
                    if isVisible(targetPart) then
                        shortestDistance = dist
                        closestTarget = targetPart
                    end
                end
            end
        end
    end
    return closestTarget
end

-- ESP СИСТЕМА
local espCache = {}

local function updateESP()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            
            if Mono.ESP.Enabled and isEnemy(plr) then
                if not espCache[plr] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "MonoESP"
                    hl.FillColor = Color3.fromRGB(180, 130, 255)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0.2
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "MonoName"
                    bb.Size = UDim2.new(0, 100, 0, 20)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true
                    local tl = Instance.new("TextLabel", bb)
                    tl.Size = UDim2.new(1, 0, 1, 0); tl.BackgroundTransparency = 1; tl.Font = Enum.Font.GothamBold; tl.TextSize = 12; tl.TextStrokeTransparency = 0
                    
                    espCache[plr] = {Highlight = hl, Billboard = bb, Text = tl}
                end
                
                local esp = espCache[plr]
                esp.Highlight.Parent = char
                esp.Billboard.Parent = char.HumanoidRootPart
                esp.Text.Text = plr.Name
                esp.Text.TextColor3 = Color3.fromRGB(180, 130, 255)
            else
                if espCache[plr] then
                    espCache[plr].Highlight.Parent = nil
                    espCache[plr].Billboard.Parent = nil
                end
            end
        else
            if espCache[plr] then
                espCache[plr].Highlight.Parent = nil
                espCache[plr].Billboard.Parent = nil
            end
        end
    end
end

-- === ОСНОВНОЙ ЦИКЛ ===
RunService.RenderStepped:Connect(function()
    -- 1. Отрисовка ESP
    updateESP()

    -- 2. AIMBOT
    if Mono.Aimbot.Enabled and UserInputService:IsKeyDown(Mono.Aimbot.Key) then
        local target = getClosestVisibleEnemy()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end

    -- 3. AUTO TAP
    if Mono.AutoTap.Enabled and UserInputService:IsKeyDown(Mono.AutoTap.Key) then
        local target = getClosestVisibleEnemy()
        -- Если цель найдена рядом с прицелом (почти смотрим на нее)
        if target then
            local pos, _ = Camera:WorldToViewportPoint(target.Position)
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
            
            -- Триггерим выстрел только если прицел прямо на враге (радиус 30)
            if dist < 30 then
                if tick() - LastShootTime > Mono.AutoTap.Delay then
                    LastShootTime = tick()
                    if mouse1click then
                        mouse1click()
                    end
                end
            end
        end
    end
end)
