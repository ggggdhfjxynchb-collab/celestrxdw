local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

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
    Aimbot = { Enabled = false, Key = Enum.KeyCode.C },
    AutoTap = { Enabled = false, Key = Enum.KeyCode.V, Delay = 0.05 },
    ESP = { Enabled = false, MaxDistance = 350 },
    TeamCheck = false,
    ShootFlash = true,
    TargetObj = "None", 
    MenuOpen = true
}

local LastShootTime = 0
local BindWait = nil 
local DeadCache = {} 

-- === 3. СОЗДАНИЕ ИНТЕРФЕЙСА ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonogrammaKlient"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true 
screenGui.Parent = targetParent

local LavenderGradient = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(180, 130, 255)), 
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(110, 60, 220))   
})

-- === ЭФФЕКТ ВЫСТРЕЛА (FLASH) ===
local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel = 0
flashFrame.ZIndex = 9999 
flashFrame.Parent = screenGui

local function doShootFlash()
    if Mono.ShootFlash then
        flashFrame.BackgroundTransparency = 0.7
        TweenService:Create(flashFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
    end
end

-- === ДИНАМИЧНЫЙ STATUS HUD ===
local hudFrame = Instance.new("Frame")
hudFrame.Size = UDim2.new(0, 150, 0, 0)
hudFrame.Position = UDim2.new(1, -160, 0, 10)
hudFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
hudFrame.BackgroundTransparency = 0.2
hudFrame.BorderSizePixel = 0
hudFrame.ClipsDescendants = true 
hudFrame.Parent = screenGui
Instance.new("UICorner", hudFrame).CornerRadius = UDim.new(0, 6)

local hudList = Instance.new("UIListLayout", hudFrame)
hudList.Padding = UDim.new(0, 5)
hudList.HorizontalAlignment = Enum.HorizontalAlignment.Center
hudList.SortOrder = Enum.SortOrder.LayoutOrder

local hudTitle = Instance.new("TextLabel")
hudTitle.Name = "0_Title"
hudTitle.Size = UDim2.new(1, 0, 0, 30)
hudTitle.BackgroundTransparency = 1
hudTitle.Text = "MONOGRAMMA"
hudTitle.TextColor3 = Color3.fromRGB(180, 130, 255)
hudTitle.Font = Enum.Font.GothamBlack
hudTitle.TextSize = 12
hudTitle.Parent = hudFrame

local function updateHUD()
    for _, v in pairs(hudFrame:GetChildren()) do
        if v:IsA("TextLabel") and v.Name ~= "0_Title" then v:Destroy() end
    end

    local activeCount = 0

    local function addActiveFeature(name)
        activeCount = activeCount + 1
        local lbl = Instance.new("TextLabel")
        lbl.Name = "1_" .. name
        lbl.Size = UDim2.new(1, -20, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = hudFrame
        
        local dot = Instance.new("Frame", lbl)
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.Position = UDim2.new(1, -10, 0.5, -3)
        dot.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    end

    if Mono.Aimbot.Enabled then addActiveFeature("Aimbot") end
    if Mono.AutoTap.Enabled then addActiveFeature("Auto Tap") end
    if Mono.ESP.Enabled then addActiveFeature("Wallhack") end
    if Mono.TargetObj ~= "None" then 
        local objName = Mono.TargetObj:gsub(" .*", "") 
        addActiveFeature("Obj: " .. objName) 
    end

    local targetHeight = (activeCount > 0) and (activeCount * 25 + 35) or 0
    TweenService:Create(hudFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 150, 0, targetHeight)}):Play()
end

-- === ГЛАВНОЕ МЕНЮ ===
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 320)
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25) 
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local unlockMouseBtn = Instance.new("TextButton")
unlockMouseBtn.Size = UDim2.new(0, 0, 0, 0)
unlockMouseBtn.BackgroundTransparency = 1
unlockMouseBtn.Text = ""
unlockMouseBtn.Modal = true
unlockMouseBtn.Parent = mainFrame

local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Thickness = 2
local strokeGrad = Instance.new("UIGradient", uiStroke)
strokeGrad.Color = LavenderGradient
strokeGrad.Rotation = 45

local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundTransparency = 1

local logoText = Instance.new("TextLabel", header)
logoText.Size = UDim2.new(0, 40, 0, 40)
logoText.Position = UDim2.new(0, 5, 0, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "⬟"
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

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 45, 0, 0)
title.BackgroundTransparency = 1
title.Text = "MONOGRAMMA  |  Press ']' to hide"
title.TextColor3 = Color3.fromRGB(230, 230, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

local headerLine = Instance.new("Frame", mainFrame)
headerLine.Size = UDim2.new(1, 0, 0, 2)
headerLine.Position = UDim2.new(0, 0, 0, 40)
headerLine.BorderSizePixel = 0
local lineGrad = Instance.new("UIGradient", headerLine)
lineGrad.Color = LavenderGradient

-- ПАНЕЛЬ НАВИГАЦИИ (СЛЕВА)
local sidebar = Instance.new("Frame", mainFrame)
sidebar.Size = UDim2.new(0, 130, 1, -42)
sidebar.Position = UDim2.new(0, 0, 0, 42)
sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)
local sidebarCover = Instance.new("Frame", sidebar)
sidebarCover.Size = UDim2.new(0, 10, 1, 0)
sidebarCover.Position = UDim2.new(1, -10, 0, 0)
sidebarCover.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
sidebarCover.BorderSizePixel = 0

local sidebarList = Instance.new("UIListLayout", sidebar)
sidebarList.Padding = UDim.new(0, 5)
sidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarList.SortOrder = Enum.SortOrder.LayoutOrder

local tabPadding = Instance.new("UIPadding", sidebar)
tabPadding.PaddingTop = UDim.new(0, 10)

-- ЗОНА КОНТЕНТА (СПРАВА)
local contentArea = Instance.new("Frame", mainFrame)
contentArea.Size = UDim2.new(1, -140, 1, -42)
contentArea.Position = UDim2.new(0, 140, 0, 42)
contentArea.BackgroundTransparency = 1

local Pages = {}
local activeBtn = nil

local function createTab(name, icon)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    btn.Text = " " .. icon .. " " .. name
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("ScrollingFrame", contentArea)
    page.Size = UDim2.new(1, -10, 1, -10)
    page.Position = UDim2.new(0, 0, 0, 10)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(180, 130, 255)
    page.Visible = false
    
    local pLayout = Instance.new("UIListLayout", page)
    pLayout.Padding = UDim.new(0, 10)
    
    Pages[name] = page

    btn.MouseButton1Click:Connect(function()
        if activeBtn then
            activeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            activeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
        for _, p in pairs(Pages) do p.Visible = false end
        
        btn.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        page.Visible = true
        activeBtn = btn
    end)

    return page, btn
end

local combatPage, combatBtn = createTab("Combat", "⚔️")
local visualsPage, visualsBtn = createTab("Visuals", "👁️")

-- === ФУНКЦИИ GUI ДЛЯ ВКЛАДОК ===
local function createToggle(parent, text, defaultState, onToggle)
    local frame = Instance.new("Frame", parent)
    frame.Name = text
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local btn = Instance.new("TextButton", frame)
    btn.Name = "MainBtn"
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. text
    btn.TextColor3 = defaultState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local status = Instance.new("Frame", frame)
    status.Name = "Status"
    status.Size = UDim2.new(0, 14, 0, 14)
    status.Position = UDim2.new(1, -30, 0.5, -7)
    status.BackgroundColor3 = defaultState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)
    
    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        status.BackgroundColor3 = state and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
        btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        onToggle(state)
        updateHUD()
    end)
end

local function createToggleWithBind(parent, text, defaultState, defaultBind, onToggle, bindTable, bindKeyName)
    local frame = Instance.new("Frame", parent)
    frame.Name = text
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local btn = Instance.new("TextButton", frame)
    btn.Name = "MainBtn"
    btn.Size = UDim2.new(0, 200, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. text
    btn.TextColor3 = defaultState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local status = Instance.new("Frame", frame)
    status.Name = "Status"
    status.Size = UDim2.new(0, 14, 0, 14)
    status.Position = UDim2.new(0, 180, 0.5, -7)
    status.BackgroundColor3 = defaultState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)
    
    local bindBtn = Instance.new("TextButton", frame)
    bindBtn.Size = UDim2.new(0, 100, 0, 24)
    bindBtn.Position = UDim2.new(1, -110, 0.5, -12)
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
        updateHUD()
    end)

    bindBtn.MouseButton1Click:Connect(function()
        if BindWait then return end 
        bindBtn.Text = "..."
        BindWait = function(key)
            bindTable[bindKeyName] = key
            local keyName = key.Name
            if key == Enum.UserInputType.MouseButton1 then keyName = "LMB" end
            if key == Enum.UserInputType.MouseButton2 then keyName = "RMB" end
            bindBtn.Text = keyName
            BindWait = nil
        end
    end)
end

local function createDropdown(parent, text, options, defaultIndex, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.ClipsDescendants = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local mainBtn = Instance.new("TextButton", frame)
    mainBtn.Size = UDim2.new(1, 0, 0, 35)
    mainBtn.BackgroundTransparency = 1
    mainBtn.Text = "  " .. text .. ": " .. options[defaultIndex]
    mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainBtn.Font = Enum.Font.GothamMedium
    mainBtn.TextSize = 13
    mainBtn.TextXAlignment = Enum.TextXAlignment.Left

    local arrow = Instance.new("TextLabel", mainBtn)
    arrow.Size = UDim2.new(0, 30, 1, 0)
    arrow.Position = UDim2.new(1, -30, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Color3.fromRGB(180, 130, 255)
    arrow.Font = Enum.Font.Gotham

    local dropList = Instance.new("Frame", frame)
    dropList.Size = UDim2.new(1, 0, 0, #options * 30)
    dropList.Position = UDim2.new(0, 0, 0, 35)
    dropList.BackgroundTransparency = 1

    local dLayout = Instance.new("UIListLayout", dropList)
    
    local isOpen = false
    mainBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        arrow.Rotation = isOpen and 180 or 0
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = isOpen and UDim2.new(1, 0, 0, 35 + #options * 30) or UDim2.new(1, 0, 0, 35)
        }):Play()
    end)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", dropList)
        optBtn.Size = UDim2.new(1, 0, 0, 30)
        optBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        optBtn.BorderSizePixel = 0
        optBtn.Text = "   " .. opt
        optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.TextXAlignment = Enum.TextXAlignment.Left

        optBtn.MouseButton1Click:Connect(function()
            mainBtn.Text = "  " .. text .. ": " .. opt
            isOpen = false
            arrow.Rotation = 0
            TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, 35)
            }):Play()
            callback(opt)
            updateHUD()
        end)
    end
end

local function setToggleStateUI(frameName, state)
    for _, v in pairs(contentArea:GetDescendants()) do
        if v:IsA("Frame") and v.Name == frameName then
            local status = v:FindFirstChild("Status")
            local btn = v:FindFirstChild("MainBtn")
            if status and btn then
                status.BackgroundColor3 = state and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
                btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
            end
        end
    end
end

-- Вкладка COMBAT
createToggleWithBind(combatPage, "Aimbot (Toggle)", Mono.Aimbot.Enabled, Mono.Aimbot.Key, function(s) Mono.Aimbot.Enabled = s end, Mono.Aimbot, "Key")
createToggleWithBind(combatPage, "Auto Tap (Toggle)", Mono.AutoTap.Enabled, Mono.AutoTap.Key, function(s) Mono.AutoTap.Enabled = s end, Mono.AutoTap, "Key")
createToggle(combatPage, "Team Check", Mono.TeamCheck, function(s) Mono.TeamCheck = s end)

-- Вкладка VISUALS
createToggle(visualsPage, "Wallhack (ESP)", Mono.ESP.Enabled, function(s) Mono.ESP.Enabled = s end)
createDropdown(visualsPage, "Target Obj", {"None", "Moon 🌙", "Butterflies 🦋", "Lavender 💜", "Bananas 🍌"}, 1, function(val) Mono.TargetObj = val end)
createToggle(visualsPage, "Shoot Flash Effect", Mono.ShootFlash, function(s) Mono.ShootFlash = s end)

updateHUD() 
combatBtn.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
combatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
combatPage.Visible = true
activeBtn = combatBtn

-- === ПЕРЕТАСКИВАНИЕ ===
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

-- === ОБРАБОТКА НАЖАТИЙ ===
UserInputService.InputBegan:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not gp then
        task.spawn(doShootFlash)
    end

    if BindWait then
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.Escape then
            BindWait(input.KeyCode)
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
            BindWait(input.UserInputType)
        end
        return
    end

    if gp then return end
    local key = (input.UserInputType == Enum.UserInputType.Keyboard) and input.KeyCode or input.UserInputType

    if key == Mono.Aimbot.Key then
        Mono.Aimbot.Enabled = not Mono.Aimbot.Enabled
        setToggleStateUI("Aimbot (Toggle)", Mono.Aimbot.Enabled)
        updateHUD()
    end

    if key == Mono.AutoTap.Key then
        Mono.AutoTap.Enabled = not Mono.AutoTap.Enabled
        setToggleStateUI("Auto Tap (Toggle)", Mono.AutoTap.Enabled)
        updateHUD()
    end

    if input.KeyCode == Enum.KeyCode.RightBracket then
        Mono.MenuOpen = not Mono.MenuOpen
        mainFrame.Visible = Mono.MenuOpen
        unlockMouseBtn.Modal = Mono.MenuOpen
    end
end)

-- === 4. ЯДРО ЧИТА ===

local function simulateClick()
    task.spawn(doShootFlash)
    if mouse1click then
        mouse1click()
    else
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end

local function isEnemy(plr)
    if plr == LocalPlayer then return false end
    if Mono.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then 
        return false 
    end
    return true
end

-- === ИСПРАВЛЕННЫЙ ДЕТЕКТОР СМЕРТИ ТИММЕЙТОВ ===
local function showDeathNotification(name)
    local notif = Instance.new("TextLabel", screenGui)
    notif.Text = name .. " умер !"
    notif.TextColor3 = Color3.fromRGB(180, 130, 255)
    notif.Size = UDim2.new(0, 300, 0, 50)
    notif.Position = UDim2.new(0.5, -150, 0.8, 0)
    notif.BackgroundTransparency = 1
    notif.Font = Enum.Font.GothamBlack
    notif.TextSize = 22
    
    local ts = TweenService
    ts:Create(notif, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -150, 0.65, 0), TextTransparency = 1}):Play()
    game.Debris:AddItem(notif, 3)
end

local function getBestTargetPart(char)
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
end

local function raycastFromCamera()
    local origin = Camera.CFrame.Position
    local direction = Camera.CFrame.LookVector * 1500 
    
    local rayParams = RaycastParams.new()
    local ignoreList = {LocalPlayer.Character, Camera}
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name:lower():match("viewmodel") or v.Name:lower():match("arm") or v.Name:lower():match("gun") then
            table.insert(ignoreList, v)
        end
    end
    rayParams.FilterDescendantsInstances = ignoreList
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true

    return workspace:Raycast(origin, direction, rayParams)
end

local function getPlayerFromPart(part)
    if not part then return nil end
    local model = part:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then
        return Players:GetPlayerFromCharacter(model)
    end
    return nil
end

local function getClosestVisibleEnemy()
    local closestTarget = nil
    local shortestDistance = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in pairs(Players:GetPlayers()) do
        local char = plr.Character
        if isEnemy(plr) and char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local targetPart = getBestTargetPart(char)
            if targetPart then
                local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < 400 then 
                        local origin = Camera.CFrame.Position
                        local dir = (targetPart.Position - origin).Unit * 1000
                        local params = RaycastParams.new()
                        params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        local result = workspace:Raycast(origin, dir, params)
                        
                        if result and result.Instance and result.Instance:IsDescendantOf(char) then
                            if dist < shortestDistance then
                                shortestDistance = dist
                                closestTarget = targetPart
                            end
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

-- ESP & VISUALS
local espCache = {}
local Emojis = {
    ["Moon 🌙"] = "🌙",
    ["Butterflies 🦋"] = "🦋",
    ["Lavender 💜"] = "💜",
    ["Bananas 🍌"] = "🍌"
}

local function updateESP()
    local t = tick()
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        
        local char = plr.Character
        local isEnem = isEnemy(plr)
        
        -- СТРОГИЙ ДЕТЕКТОР СМЕРТИ ТОЛЬКО ДЛЯ ТИММЕЙТОВ
        local isTeammate = (plr.Team ~= nil and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team)
        if isTeammate and char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                if hum.Health <= 0 and not DeadCache[plr] then
                    DeadCache[plr] = true
                    showDeathNotification(plr.Name)
                elseif hum.Health > 0 then
                    DeadCache[plr] = false
                end
            end
        end

        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            
            local distToPlayer = (char.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
            if Mono.ESP.Enabled and isEnem and distToPlayer <= Mono.ESP.MaxDistance then
                if not espCache[plr] then espCache[plr] = {} end
                if not espCache[plr].Highlight then
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
                    
                    espCache[plr].Highlight = hl
                    espCache[plr].Billboard = bb
                    espCache[plr].Text = tl
                end
                
                espCache[plr].Highlight.Parent = char
                espCache[plr].Billboard.Parent = char.HumanoidRootPart
                espCache[plr].Text.Text = string.format("%s [%dm]", plr.Name, math.floor(distToPlayer))
                espCache[plr].Text.TextColor3 = Color3.fromRGB(180, 130, 255)
            else
                if espCache[plr] and espCache[plr].Highlight then
                    espCache[plr].Highlight.Parent = nil
                    espCache[plr].Billboard.Parent = nil
                end
            end

            if Mono.TargetObj ~= "None" and isEnem then
                if not espCache[plr] then espCache[plr] = {} end
                if not espCache[plr].Orbits then
                    espCache[plr].Orbits = {}
                    for i=1, 3 do
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(2, 0, 2, 0) 
                        bb.AlwaysOnTop = true
                        local tl = Instance.new("TextLabel", bb)
                        tl.Size = UDim2.new(1, 0, 1, 0)
                        tl.BackgroundTransparency = 1
                        tl.TextScaled = true 
                        table.insert(espCache[plr].Orbits, {gui = bb, text = tl})
                    end
                end

                for i, orb in ipairs(espCache[plr].Orbits) do
                    orb.gui.Parent = char.HumanoidRootPart
                    orb.text.Text = Emojis[Mono.TargetObj]
                    
                    local angle = t * 2 + (i * (math.pi * 2 / 3))
                    local radius = 3.5
                    orb.gui.StudsOffset = Vector3.new(math.cos(angle) * radius, math.sin(t * 3) * 1.5, math.sin(angle) * radius)
                end
            else
                if espCache[plr] and espCache[plr].Orbits then
                    for _, orb in ipairs(espCache[plr].Orbits) do
                        orb.gui.Parent = nil
                    end
                end
            end
        else
            if espCache[plr] then
                if espCache[plr].Highlight then
                    espCache[plr].Highlight.Parent = nil
                    espCache[plr].Billboard.Parent = nil
                end
                if espCache[plr].Orbits then
                    for _, orb in ipairs(espCache[plr].Orbits) do
                        orb.gui.Parent = nil
                    end
                end
            end
        end
    end
end

-- === ОСНОВНОЙ ЦИКЛ ===
RunService:BindToRenderStep("MonoCore", Enum.RenderPriority.Camera.Value + 1, function()
    updateESP()

    if Mono.Aimbot.Enabled then
        local target = getClosestVisibleEnemy()
        if target then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
        end
    end

    if Mono.AutoTap.Enabled then
        local hitResult = raycastFromCamera()
        if hitResult and hitResult.Instance then
            local targetPlayer = getPlayerFromPart(hitResult.Instance)
            if targetPlayer and isEnemy(targetPlayer) then
                if tick() - LastShootTime > Mono.AutoTap.Delay then
                    LastShootTime = tick()
                    simulateClick()
                end
            end
        end
    end
end)
