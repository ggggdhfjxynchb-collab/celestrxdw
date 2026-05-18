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
    local oldGui = targetParent:FindFirstChild("DuckShooterKlient")
    if oldGui then oldGui:Destroy() end
end)

-- === 2. НАСТРОЙКИ ЧИТА ===
local Duck = {
    Aimbot = { Enabled = false, Key = Enum.KeyCode.C, Smoothness = 0.5, TargetPart = "Head" },
    Triggerbot = { Enabled = false, Delay = 0.05 },
    ESP = { Enabled = true },
    Friends = {},
    MenuOpen = true
}

local LastShootTime = 0

-- === 3. СОЗДАНИЕ ИНТЕРФЕЙСА ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DuckShooterKlient"
screenGui.ResetOnSpawn = false
screenGui.Parent = targetParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 300)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
local uiStroke = Instance.new("UIStroke", mainFrame); uiStroke.Color = Color3.fromRGB(0, 170, 255); uiStroke.Thickness = 2

-- МАГИЯ РАЗБЛОКИРОВКИ МЫШИ (MODAL)
local unlockMouseBtn = Instance.new("TextButton")
unlockMouseBtn.Size = UDim2.new(0, 0, 0, 0)
unlockMouseBtn.BackgroundTransparency = 1
unlockMouseBtn.Text = ""
unlockMouseBtn.Modal = true -- Это свойство отвязывает мышь от центра экрана, пока меню открыто
unlockMouseBtn.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "  DUCK SHOOTER KLIENT [Press P]"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(0, 120, 1, -30)
tabContainer.Position = UDim2.new(0, 0, 0, 30)
tabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -120, 1, -30)
contentContainer.Position = UDim2.new(0, 120, 0, 30)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local function createToggle(parent, yPos, text, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 30); btn.Position = UDim2.new(0.05, 0, 0, yPos); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); btn.Text = ""; btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel", btn); lbl.Size = UDim2.new(1, -40, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local status = Instance.new("Frame", btn); status.Size = UDim2.new(0, 16, 0, 16); status.Position = UDim2.new(1, -26, 0.5, -8); status.BackgroundColor3 = defaultState and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50); Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)
    
    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        status.BackgroundColor3 = state and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
        lbl.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        callback(state)
    end)
    return btn
end

-- Вкладка: Combat
local combatPage = Instance.new("Frame", contentContainer); combatPage.Size = UDim2.new(1, 0, 1, 0); combatPage.BackgroundTransparency = 1
createToggle(combatPage, 10, "Auto Aim", Duck.Aimbot.Enabled, function(s) Duck.Aimbot.Enabled = s end)
createToggle(combatPage, 50, "Auto Shoot (Triggerbot)", Duck.Triggerbot.Enabled, function(s) Duck.Triggerbot.Enabled = s end)

local bindBtn = Instance.new("TextButton", combatPage); bindBtn.Size = UDim2.new(0.9, 0, 0, 30); bindBtn.Position = UDim2.new(0.05, 0, 0, 90); bindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); bindBtn.Text = "Aim Bind: " .. Duck.Aimbot.Key.Name; bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255); bindBtn.Font = Enum.Font.Gotham; bindBtn.TextSize = 12; Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)
local binding = false
bindBtn.MouseButton1Click:Connect(function() bindBtn.Text = "Press any key..."; binding = true end)

-- Вкладка: Visuals & Friends
local visPage = Instance.new("Frame", contentContainer); visPage.Size = UDim2.new(1, 0, 1, 0); visPage.BackgroundTransparency = 1; visPage.Visible = false
createToggle(visPage, 10, "Player ESP", Duck.ESP.Enabled, function(s) Duck.ESP.Enabled = s end)

local friendInput = Instance.new("TextBox", visPage); friendInput.Size = UDim2.new(0.9, 0, 0, 30); friendInput.Position = UDim2.new(0.05, 0, 0, 50); friendInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40); friendInput.Text = "Enter friend's exact name..."; friendInput.TextColor3 = Color3.fromRGB(200, 200, 200); friendInput.Font = Enum.Font.Gotham; friendInput.TextSize = 12; friendInput.ClearTextOnFocus = true; Instance.new("UICorner", friendInput).CornerRadius = UDim.new(0, 4)
local addFriendBtn = Instance.new("TextButton", visPage); addFriendBtn.Size = UDim2.new(0.9, 0, 0, 30); addFriendBtn.Position = UDim2.new(0.05, 0, 0, 90); addFriendBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255); addFriendBtn.Text = "Add Friend"; addFriendBtn.TextColor3 = Color3.fromRGB(255, 255, 255); addFriendBtn.Font = Enum.Font.GothamBold; addFriendBtn.TextSize = 12; Instance.new("UICorner", addFriendBtn).CornerRadius = UDim.new(0, 4)
local friendsListLbl = Instance.new("TextLabel", visPage); friendsListLbl.Size = UDim2.new(0.9, 0, 0, 100); friendsListLbl.Position = UDim2.new(0.05, 0, 0, 130); friendsListLbl.BackgroundTransparency = 1; friendsListLbl.Text = "Friends: None"; friendsListLbl.TextColor3 = Color3.fromRGB(0, 255, 100); friendsListLbl.Font = Enum.Font.Gotham; friendsListLbl.TextSize = 12; friendsListLbl.TextYAlignment = Enum.TextYAlignment.Top; friendsListLbl.TextWrapped = true

addFriendBtn.MouseButton1Click:Connect(function()
    local name = friendInput.Text
    if name ~= "" and name ~= LocalPlayer.Name then
        Duck.Friends[string.lower(name)] = true
        friendInput.Text = ""
        local fStr = "Friends: "
        for f, _ in pairs(Duck.Friends) do fStr = fStr .. f .. ", " end
        friendsListLbl.Text = fStr
    end
end)

-- Вкладки кнопок
local function createTabBtn(yPos, text, page)
    local btn = Instance.new("TextButton", tabContainer); btn.Size = UDim2.new(1, 0, 0, 40); btn.Position = UDim2.new(0, 0, 0, yPos); btn.BackgroundTransparency = 1; btn.Text = text; btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    btn.MouseButton1Click:Connect(function()
        combatPage.Visible = false; visPage.Visible = false; page.Visible = true
    end)
end
createTabBtn(0, "Combat", combatPage)
createTabBtn(40, "Visuals & Friends", visPage)

-- Перетаскивание меню
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

-- Горячие клавиши (Открытие меню и бинд аима)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if binding and input.UserInputType == Enum.UserInputType.Keyboard then
        Duck.Aimbot.Key = input.KeyCode
        bindBtn.Text = "Aim Bind: " .. Duck.Aimbot.Key.Name
        binding = false
        return
    end

    if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
        Duck.MenuOpen = not Duck.MenuOpen
        mainFrame.Visible = Duck.MenuOpen
    end
end)

-- === 4. ЯДРО ЧИТА (АЛГОРИТМЫ) ===

-- Проверка: друг ли это?
local function isFriend(plr)
    return Duck.Friends[string.lower(plr.Name)] or Duck.Friends[string.lower(plr.DisplayName)]
end

-- Проверка: враг ли это? (Команды и Друзья)
local function isEnemy(plr)
    if plr == LocalPlayer then return false end
    if isFriend(plr) then return false end
    -- Если игра командная и вы в одной команде
    if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
    return true
end

-- Проверка: Виден ли игрок за стеной (Visibility Check)
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
            return true -- Луч попал во врага (стен нет)
        end
    end
    return false -- Луч попал в стену
end

-- Найти ближайшего врага к центру экрана
local function getClosestPlayerToCrosshair()
    local closestTarget = nil
    local shortestDistance = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in pairs(Players:GetPlayers()) do
        if isEnemy(plr) and plr.Character and plr.Character:FindFirstChild(Duck.Aimbot.TargetPart) and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local targetPart = plr.Character[Duck.Aimbot.TargetPart]
            local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < shortestDistance and dist < 200 then -- 200 = радиус захвата (FOV)
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
            
            local isFr = isFriend(plr)
            local isEn = isEnemy(plr)
            
            if Duck.ESP.Enabled and (isFr or isEn) then
                if not espCache[plr] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "DuckESP"
                    hl.FillTransparency = 0.6
                    hl.OutlineTransparency = 0.1
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "DuckName"
                    bb.Size = UDim2.new(0, 100, 0, 20)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true
                    local tl = Instance.new("TextLabel", bb)
                    tl.Size = UDim2.new(1, 0, 1, 0); tl.BackgroundTransparency = 1; tl.Font = Enum.Font.GothamBold; tl.TextSize = 10; tl.TextStrokeTransparency = 0
                    
                    espCache[plr] = {Highlight = hl, Billboard = bb, Text = tl}
                end
                
                local esp = espCache[plr]
                esp.Highlight.Parent = char
                esp.Billboard.Parent = char.HumanoidRootPart
                
                -- Друзья зеленые, Враги красные
                local color = isFr and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
                esp.Highlight.FillColor = color
                esp.Highlight.OutlineColor = color
                esp.Text.Text = plr.Name
                esp.Text.TextColor3 = color
            else
                -- Если ESP выключен или это тиммейт
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

-- === 5. ОСНОВНОЙ ЦИКЛ ОБНОВЛЕНИЯ ===
RunService.RenderStepped:Connect(function()
    -- 1. Обновляем ESP
    updateESP()

    -- 2. AUTO AIM (Аимбот)
    if Duck.Aimbot.Enabled and UserInputService:IsKeyDown(Duck.Aimbot.Key) then
        local target = getClosestPlayerToCrosshair()
        if target then
            -- Плавно наводим камеру на цель
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, target.Position)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, Duck.Aimbot.Smoothness)
        end
    end

    -- 3. AUTO SHOOT (Triggerbot)
    if Duck.Triggerbot.Enabled then
        local target = Mouse.Target
        if target and target.Parent then
            -- Если мышка смотрит на игрока
            local model = target.Parent
            if not model:FindFirstChild("Humanoid") then model = target.Parent.Parent end -- Защита от шляп/брони
            
            if model and model:FindFirstChild("Humanoid") then
                local plr = Players:GetPlayerFromCharacter(model)
                if plr and isEnemy(plr) then
                    -- Проверяем кулдаун выстрела, чтобы не крашнуть клиент спамом
                    if tick() - LastShootTime > Duck.Triggerbot.Delay then
                        LastShootTime = tick()
                        -- Эмулируем нажатие левой кнопки мыши (Только для мощных экзекуторов!)
                        if mouse1click then
                            mouse1click()
                        else
                            warn("Твой инжектор не поддерживает mouse1click! Triggerbot не сработает.")
                        end
                    end
                end
            end
        end
    end
end)
