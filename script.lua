local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
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

-- === 2. НАСТРОЙКИ ЧИТА (ВСЕ ВЫКЛЮЧЕНО ПО УМОЛЧАНИЮ) ===
local Mono = {
    Aimbot = { Enabled = false, Key = Enum.KeyCode.C },
    AutoTap = { Enabled = false, Key = Enum.KeyCode.V, Delay = 0.05 },
    
    -- НОВОЕ: НАСТРОЙКИ КРУГА FOV
    FOV = { Enabled = true, Radius = 150, Color = Color3.fromRGB(180, 130, 255) },
    
    ESP = { Enabled = false, MaxDistance = 350 },
    ESPColor = Color3.fromRGB(180, 130, 255),
    TeamCheck = false,
    
    TargetObjEnabled = false,
    OrbitEmoji = "🦋",
    
    KillEffect = false,
    KillEmoji = "💀", 
    KillColor = Color3.fromRGB(255, 50, 50), 
    
    TeammateNotifs = false,
    DeathNotifDistance = 150, 
    
    TintEnabled = false,
    TintColor = Color3.fromRGB(110, 60, 220),
    TimeOfDay = "Default", 
    Weather = "None",      
    WeatherEmoji = "💸",
    
    MenuOpen = true
}

local LastShootTime = 0
local BindWait = nil 
local PlayerData = {} 
local LastTargetHit = nil
local LastTargetTime = 0

-- === ОПТИМИЗАЦИЯ ЛУЧЕЙ ===
local GlobalRayParams = RaycastParams.new()
GlobalRayParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRayParams.IgnoreWater = true

task.spawn(function()
    while true do
        pcall(function()
            local ignoreList = {}
            if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
            if Camera then table.insert(ignoreList, Camera) end
            for _, v in pairs(workspace:GetChildren()) do
                if v and v.Name then
                    local name = string.lower(v.Name)
                    if string.match(name, "viewmodel") or string.match(name, "arm") or string.match(name, "gun") or string.match(name, "weapon") then
                        table.insert(ignoreList, v)
                    end
                end
            end
            GlobalRayParams.FilterDescendantsInstances = ignoreList
        end)
        task.wait(1)
    end
end)

-- === 3. СОЗДАНИЕ ИНТЕРФЕЙСА ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonogrammaKlient"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true 
screenGui.Parent = targetParent

-- === НОВОЕ: КРУГ FOV НА ЭКРАНЕ ===
local fovFrame = Instance.new("Frame", screenGui)
fovFrame.BackgroundTransparency = 1
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
fovFrame.ZIndex = 50
local fovCorner = Instance.new("UICorner", fovFrame)
fovCorner.CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovFrame)
fovStroke.Thickness = 1.5
fovStroke.Color = Mono.FOV.Color

-- === ЭФФЕКТЫ МИРА ===
local tintFrame = Instance.new("Frame", screenGui)
tintFrame.Size = UDim2.new(1, 0, 1, 0)
tintFrame.BackgroundColor3 = Mono.TintColor
tintFrame.BackgroundTransparency = 1
tintFrame.BorderSizePixel = 0
tintFrame.ZIndex = -100 

local weatherContainer = Instance.new("Frame", screenGui)
weatherContainer.Size = UDim2.new(1, 0, 1, 0)
weatherContainer.BackgroundTransparency = 1
weatherContainer.ZIndex = -90
weatherContainer.ClipsDescendants = true

task.spawn(function()
    while true do
        task.wait(0.08) 
        pcall(function()
            if Mono.Weather ~= "None" then
                local wDrop = Instance.new("TextLabel", weatherContainer)
                wDrop.BackgroundTransparency = 1
                wDrop.Size = UDim2.new(0, 30, 0, 30)
                wDrop.Position = UDim2.new(math.random(), 0, -0.1, 0)
                wDrop.Text = (Mono.Weather == "Rain 🌧️") and "💧" or Mono.WeatherEmoji
                wDrop.TextSize = (Mono.Weather == "Rain 🌧️") and math.random(15, 20) or math.random(20, 35)
                wDrop.TextTransparency = 0.2
                
                local duration = math.random(30, 60) / 10 
                local targetX = wDrop.Position.X.Scale + (math.random(-10, 10)/100) 
                
                local ts = TweenService:Create(wDrop, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(targetX, 0, 1.1, 0),
                    Rotation = math.random(-90, 90)
                })
                ts:Play()
                game.Debris:AddItem(wDrop, duration + 0.1)
            end
        end)
    end
end)

-- === УВЕДОМЛЕНИЯ ===
local notifContainer = Instance.new("Frame", screenGui)
notifContainer.Size = UDim2.new(0, 400, 0, 300)
notifContainer.Position = UDim2.new(0.5, -200, 0.12, 0)
notifContainer.BackgroundTransparency = 1
local notifLayout = Instance.new("UIListLayout", notifContainer)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notifLayout.Padding = UDim.new(0, 8)

local function showNotification(text, color)
    pcall(function()
        local notif = Instance.new("TextLabel")
        notif.Text = text 
        notif.TextColor3 = color or Mono.KillColor
        notif.Size = UDim2.new(1, 0, 0, 40)
        notif.BackgroundTransparency = 1
        notif.Font = Enum.Font.GothamBlack
        notif.TextSize = 24 
        notif.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        notif.TextStrokeTransparency = 1 
        notif.TextTransparency = 1
        notif.Parent = notifContainer
        
        local ts = TweenService
        ts:Create(notif, TweenInfo.new(0.3), {TextTransparency = 0, TextStrokeTransparency = 0}):Play()
        task.delay(3, function()
            pcall(function()
                local fade = ts:Create(notif, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1})
                fade:Play()
                fade.Completed:Connect(function() notif:Destroy() end)
            end)
        end)
    end)
end

-- === КАСТОМНЫЙ ЭФФЕКТ УБИЙСТВА ===
local flashFrame = Instance.new("Frame")
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3 = Mono.KillColor
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel = 0
flashFrame.ZIndex = 9999 
flashFrame.Parent = screenGui

local function doKillEffect()
    pcall(function()
        if not Mono.KillEffect then return end
        flashFrame.BackgroundColor3 = Mono.KillColor
        flashFrame.BackgroundTransparency = 0.3
        TweenService:Create(flashFrame, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        
        for i = 1, 25 do
            local emoji = Instance.new("TextLabel", screenGui)
            emoji.Text = Mono.KillEmoji
            emoji.BackgroundTransparency = 1
            emoji.Size = UDim2.new(0, 50, 0, 50)
            emoji.Position = UDim2.new(0.5, -25, 0.5, -25)
            emoji.TextSize = math.random(25, 60)
            emoji.ZIndex = 10000
            
            local angle = math.rad(math.random(0, 360))
            local distance = math.random(150, 800)
            local targetX = 0.5 + (math.cos(angle) * (distance / Camera.ViewportSize.X))
            local targetY = 0.5 + (math.sin(angle) * (distance / Camera.ViewportSize.Y))
            
            local ts = TweenService:Create(emoji, TweenInfo.new(math.random(6, 12)/10, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
                Position = UDim2.new(targetX, -25, targetY, -25),
                TextTransparency = 1,
                Rotation = math.random(-360, 360)
            })
            ts:Play()
            game.Debris:AddItem(emoji, 1.5)
        end
    end)
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
Instance.new("UICorner", hudFrame).CornerRadius = UDim.new(0, 8)

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
    pcall(function()
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
        if Mono.TargetObjEnabled then addActiveFeature("Orbits") end
        if Mono.TintEnabled then addActiveFeature("Screen Tint") end

        local targetHeight = (activeCount > 0) and (activeCount * 25 + 35) or 0
        TweenService:Create(hudFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 150, 0, targetHeight)}):Play()
    end)
end

-- === ГЛАВНОЕ МЕНЮ С ИДЕАЛЬНЫМИ ЗАКРУГЛЕНИЯМИ ===
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 340)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -170)
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local bgGradient = Instance.new("UIGradient", mainFrame)
bgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(130, 80, 200)), 
    ColorSequenceKeypoint.new(0.70, Color3.fromRGB(15, 15, 15)),   
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(10, 10, 10))
})
bgGradient.Rotation = 45

local uiScale = Instance.new("UIScale", mainFrame)
uiScale.Scale = 1

local unlockMouseBtn = Instance.new("TextButton")
unlockMouseBtn.Size = UDim2.new(0, 0, 0, 0)
unlockMouseBtn.BackgroundTransparency = 1
unlockMouseBtn.Text = ""
unlockMouseBtn.Modal = true
unlockMouseBtn.Parent = mainFrame

local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Thickness = 1
uiStroke.Color = Color3.fromRGB(180, 130, 255)

local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundTransparency = 1

local logoText = Instance.new("TextLabel", header)
logoText.Size = UDim2.new(0, 40, 0, 40)
logoText.Position = UDim2.new(0, 5, 0, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "⬟"
logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
logoText.Font = Enum.Font.GothamBlack
logoText.TextSize = 24

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 45, 0, 0)
title.BackgroundTransparency = 1
title.Text = "MONOGRAMMA  |  Press RShift"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

local headerLine = Instance.new("Frame", mainFrame)
headerLine.Size = UDim2.new(1, 0, 0, 1)
headerLine.Position = UDim2.new(0, 0, 0, 40)
headerLine.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
headerLine.BorderSizePixel = 0
headerLine.BackgroundTransparency = 0.5

-- Прозрачный сайдбар
local sidebar = Instance.new("Frame", mainFrame)
sidebar.Size = UDim2.new(0, 130, 1, -41)
sidebar.Position = UDim2.new(0, 0, 0, 41)
sidebar.BackgroundTransparency = 1 

local sidebarList = Instance.new("UIListLayout", sidebar)
sidebarList.Padding = UDim.new(0, 5)
sidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local tabPadding = Instance.new("UIPadding", sidebar)
tabPadding.PaddingTop = UDim.new(0, 10)

local contentArea = Instance.new("Frame", mainFrame)
contentArea.Size = UDim2.new(1, -140, 1, -41)
contentArea.Position = UDim2.new(0, 140, 0, 41)
contentArea.BackgroundTransparency = 1

local Pages = {}
local activeBtn = nil

local function createTab(name, icon)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.BackgroundTransparency = 0.5
    btn.Text = " " .. icon .. " " .. name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
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
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local pLayout = Instance.new("UIListLayout", page)
    pLayout.Padding = UDim.new(0, 8) 
    
    Pages[name] = page

    btn.MouseButton1Click:Connect(function()
        if activeBtn then
            activeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            activeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
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
local worldPage, worldBtn = createTab("World", "🌍")
local settingsPage, settingsBtn = createTab("Settings", "⚙️")

-- === ФУНКЦИИ GUI: ЭЛЕМЕНТЫ ===
local function createButton(parent, text, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
    frame.BackgroundTransparency = 0.2
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    
    btn.MouseButton1Click:Connect(function()
        local ts = TweenService:Create(frame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(180, 130, 255)})
        ts:Play()
        ts.Completed:Wait()
        TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 30, 60)}):Play()
        callback()
    end)
end

local function createSubInput(parent, text, defaultText, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "    ↳ " .. text
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(0, 80, 0, 24)
    box.Position = UDim2.new(1, -95, 0.5, -12)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    box.Text = defaultText
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    box.FocusLost:Connect(function()
        if box.Text == "" then box.Text = defaultText end
        callback(box.Text)
        updateHUD()
    end)
    return 35
end

local function createSubColorPicker(parent, text, defaultColor, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6, 0, 0, 20)
    lbl.Position = UDim2.new(0, 0, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = "    ↳ " .. text
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local colorPreview = Instance.new("Frame", frame)
    colorPreview.Size = UDim2.new(0, 30, 0, 16)
    colorPreview.Position = UDim2.new(1, -45, 0, 7)
    colorPreview.BackgroundColor3 = defaultColor
    Instance.new("UICorner", colorPreview).CornerRadius = UDim.new(0, 4)

    local hueFrame = Instance.new("Frame", frame)
    hueFrame.Size = UDim2.new(0.9, 0, 0, 10)
    hueFrame.Position = UDim2.new(0.05, 0, 0, 30)
    Instance.new("UICorner", hueFrame).CornerRadius = UDim.new(0, 4)
    
    local rainbowGrad = Instance.new("UIGradient", hueFrame)
    rainbowGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0))
    })

    local isDraggingHue = false
    local function updateHue(inputX)
        local posX = math.clamp(inputX - hueFrame.AbsolutePosition.X, 0, hueFrame.AbsoluteSize.X)
        local hue = posX / hueFrame.AbsoluteSize.X
        local newColor = Color3.fromHSV(hue, 1, 1)
        colorPreview.BackgroundColor3 = newColor
        callback(newColor)
    end

    hueFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingHue = true
            updateHue(input.Position.X)
        end
    end)
    hueFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDraggingHue = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingHue and input.UserInputType == Enum.UserInputType.MouseMovement then updateHue(input.Position.X) end
    end)
    return 50
end

local function createDropdown(parent, text, options, defaultIndex, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BackgroundTransparency = 0.4
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

    local isOpen = false
    mainBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        arrow.Rotation = isOpen and 180 or 0
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = isOpen and UDim2.new(1, 0, 0, 35 + #options * 30) or UDim2.new(1, 0, 0, 35)
        }):Play()
    end)

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", dropList)
        optBtn.Size = UDim2.new(1, 0, 0, 30)
        optBtn.Position = UDim2.new(0, 0, 0, (i-1)*30)
        optBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        optBtn.BackgroundTransparency = 0.2
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

local function createToggle(parent, text, defaultState, onToggle)
    local frame = Instance.new("Frame", parent)
    frame.Name = text
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BackgroundTransparency = 0.4
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
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BackgroundTransparency = 0.4
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

local function createToggleWithSettings(parent, text, defaultState, onToggle, buildSettingsFunc)
    local container = Instance.new("Frame", parent)
    container.Name = text
    container.Size = UDim2.new(1, 0, 0, 35) 
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    container.BackgroundTransparency = 0.4
    container.ClipsDescendants = true 
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

    local topBar = Instance.new("Frame", container)
    topBar.Size = UDim2.new(1, 0, 0, 35)
    topBar.BackgroundTransparency = 1

    local btn = Instance.new("TextButton", topBar)
    btn.Name = "MainBtn"
    btn.Size = UDim2.new(1, -70, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. text
    btn.TextColor3 = defaultState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local gearBtn = Instance.new("TextButton", topBar)
    gearBtn.Size = UDim2.new(0, 24, 0, 24)
    gearBtn.Position = UDim2.new(1, -60, 0.5, -12)
    gearBtn.BackgroundTransparency = 1
    gearBtn.Text = "⚙️"
    gearBtn.TextSize = 14

    local status = Instance.new("Frame", topBar)
    status.Name = "Status"
    status.Size = UDim2.new(0, 14, 0, 14)
    status.Position = UDim2.new(1, -30, 0.5, -7)
    status.BackgroundColor3 = defaultState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)

    local settingsFrame = Instance.new("Frame", container)
    settingsFrame.Size = UDim2.new(1, 0, 0, 200) 
    settingsFrame.Position = UDim2.new(0, 0, 0, 35)
    settingsFrame.BackgroundTransparency = 1
    
    local sLayout = Instance.new("UIListLayout", settingsFrame)
    sLayout.Padding = UDim.new(0, 5)
    
    local totalSettingsHeight = buildSettingsFunc(settingsFrame)

    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        status.BackgroundColor3 = state and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
        btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        onToggle(state)
        updateHUD()
    end)

    local isOpen = false
    gearBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        TweenService:Create(gearBtn, TweenInfo.new(0.3), {Rotation = isOpen and 90 or 0}):Play()
        local targetSize = isOpen and (35 + totalSettingsHeight + 5) or 35
        TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetSize)}):Play()
    end)
end

local function setToggleStateUI(frameName, state)
    pcall(function()
        for _, v in pairs(contentArea:GetDescendants()) do
            if v:IsA("Frame") and v.Name == frameName then
                local status = v:FindFirstChild("Status", true)
                local btn = v:FindFirstChild("MainBtn", true)
                if status and btn then
                    status.BackgroundColor3 = state and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
                    btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
                end
            end
        end
    end)
end

-- === СИСТЕМА СОХРАНЕНИЯ ===
local cfgName = "MonogrammaConfig.json"

local function SaveConfig()
    pcall(function()
        local data = {
            TeamCheck = Mono.TeamCheck,
            MaxDist = Mono.ESP.MaxDistance,
            FOVRad = Mono.FOV.Radius,
            ESP_R = Mono.ESPColor.R, ESP_G = Mono.ESPColor.G, ESP_B = Mono.ESPColor.B,
            ObjEmoji = Mono.OrbitEmoji,
            KillEmoji = Mono.KillEmoji,
            Kill_R = Mono.KillColor.R, Kill_G = Mono.KillColor.G, Kill_B = Mono.KillColor.B,
            Tint_R = Mono.TintColor.R, Tint_G = Mono.TintColor.G, Tint_B = Mono.TintColor.B,
            Time = Mono.TimeOfDay,
            Weather = Mono.Weather,
            WeathEmoji = Mono.WeatherEmoji
        }
        if writefile then
            writefile(cfgName, HttpService:JSONEncode(data))
            showNotification("💾 Config Saved!", Color3.fromRGB(0, 255, 100))
        end
    end)
end

local function LoadConfig()
    pcall(function()
        if readfile and isfile and isfile(cfgName) then
            local decoded = HttpService:JSONDecode(readfile(cfgName))
            Mono.TeamCheck = decoded.TeamCheck or false
            Mono.ESP.MaxDistance = decoded.MaxDist or 350
            Mono.FOV.Radius = decoded.FOVRad or 150
            Mono.ESPColor = Color3.new(decoded.ESP_R or 1, decoded.ESP_G or 1, decoded.ESP_B or 1)
            Mono.OrbitEmoji = decoded.ObjEmoji or "🦋"
            Mono.KillEmoji = decoded.KillEmoji or "💀"
            Mono.KillColor = Color3.new(decoded.Kill_R or 1, decoded.Kill_G or 0, decoded.Kill_B or 0)
            Mono.TintColor = Color3.new(decoded.Tint_R or 1, decoded.Tint_G or 1, decoded.Tint_B or 1)
            Mono.TimeOfDay = decoded.Time or "Default"
            Mono.Weather = decoded.Weather or "None"
            Mono.WeatherEmoji = decoded.WeathEmoji or "💸"
            showNotification("📂 Config Loaded! Re-open tabs.", Color3.fromRGB(0, 255, 100))
        end
    end)
end

-- === ЗАПОЛНЯЕМ ВКЛАДКИ ===

-- 1. COMBAT
createToggleWithBind(combatPage, "Aimbot (Toggle)", Mono.Aimbot.Enabled, Mono.Aimbot.Key, function(s) Mono.Aimbot.Enabled = s end, Mono.Aimbot, "Key")
createToggleWithBind(combatPage, "Auto Tap (Toggle)", Mono.AutoTap.Enabled, Mono.AutoTap.Key, function(s) Mono.AutoTap.Enabled = s end, Mono.AutoTap, "Key")
createToggle(combatPage, "Team Check", Mono.TeamCheck, function(s) Mono.TeamCheck = s end)

-- НОВОЕ: Настройка круга FOV во вкладке Combat
createToggleWithSettings(combatPage, "Draw FOV Circle", Mono.FOV.Enabled, function(s) Mono.FOV.Enabled = s end, function(container)
    local h1 = createSubInput(container, "Radius", tostring(Mono.FOV.Radius), function(val) Mono.FOV.Radius = tonumber(val) or 150 end)
    local h2 = createSubColorPicker(container, "Circle Color", Mono.FOV.Color, function(c) Mono.FOV.Color = c end)
    return h1 + h2 + 5
end)

-- 2. VISUALS
createToggleWithSettings(visualsPage, "Wallhack (ESP)", Mono.ESP.Enabled, function(s) Mono.ESP.Enabled = s end, function(container)
    local h1 = createSubColorPicker(container, "ESP Color", Mono.ESPColor, function(c) Mono.ESPColor = c end)
    local h2 = createSubInput(container, "Max Distance", tostring(Mono.ESP.MaxDistance), function(val) Mono.ESP.MaxDistance = tonumber(val) or 350 end)
    return h1 + h2 + 5
end)

createToggleWithSettings(visualsPage, "Teammate Death Notifs", Mono.TeammateNotifs, function(s) Mono.TeammateNotifs = s end, function(container)
    local h1 = createSubInput(container, "Max Distance", tostring(Mono.DeathNotifDistance), function(val) Mono.DeathNotifDistance = tonumber(val) or 150 end)
    return h1
end)

createToggleWithSettings(visualsPage, "Enemy Orbits", Mono.TargetObjEnabled, function(s) Mono.TargetObjEnabled = s end, function(container)
    local h1 = createSubInput(container, "Orbit Emoji", Mono.OrbitEmoji, function(val) Mono.OrbitEmoji = val end)
    return h1
end)

createToggleWithSettings(visualsPage, "Kill Effect", Mono.KillEffect, function(s) Mono.KillEffect = s end, function(container)
    local h1 = createSubInput(container, "Kill Emoji", Mono.KillEmoji, function(val) Mono.KillEmoji = val end)
    local h2 = createSubColorPicker(container, "Flash Color", Mono.KillColor, function(c) Mono.KillColor = c end)
    return h1 + h2 + 5
end)

-- 3. WORLD
createToggleWithSettings(worldPage, "Screen Tint", Mono.TintEnabled, function(s) 
    Mono.TintEnabled = s 
    tintFrame.BackgroundTransparency = s and 0.85 or 1
end, function(container)
    local h1 = createSubColorPicker(container, "Tint Color", Mono.TintColor, function(c) Mono.TintColor = c; tintFrame.BackgroundColor3 = c end)
    return h1
end)

createDropdown(worldPage, "Time of Day", {"Default", "Day ☀️", "Night 🌙"}, 1, function(val) Mono.TimeOfDay = val end)
createDropdown(worldPage, "Weather Event", {"None", "Rain 🌧️", "Custom Snow ❄️"}, 1, function(val) Mono.Weather = val end)
createSubInput(worldPage, "Custom Snow Emoji", Mono.WeatherEmoji, function(val) Mono.WeatherEmoji = val end)

-- 4. SETTINGS
createButton(settingsPage, "💾 Save Configuration", SaveConfig)
createButton(settingsPage, "📂 Load Configuration", LoadConfig)

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

    if input.KeyCode == Enum.KeyCode.RightShift then
        Mono.MenuOpen = not Mono.MenuOpen
        unlockMouseBtn.Modal = Mono.MenuOpen
        
        if Mono.MenuOpen then
            mainFrame.Visible = true
            TweenService:Create(uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        else
            local tw = TweenService:Create(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
            tw:Play()
            tw.Completed:Connect(function()
                if not Mono.MenuOpen then mainFrame.Visible = false end
            end)
        end
    end
end)

-- === 4. ЯДРО ЧИТА ===

local function simulateClick()
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

local function getBestTargetPart(char)
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
end

local function raycastFromCamera()
    local origin = Camera.CFrame.Position
    local direction = Camera.CFrame.LookVector * 1500 
    return workspace:Raycast(origin, direction, GlobalRayParams)
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
                    
                    -- НОВОЕ: Проверка радиуса FOV для Аимбота
                    if dist <= Mono.FOV.Radius then 
                        local origin = Camera.CFrame.Position
                        local dir = (targetPart.Position - origin).Unit * 1000
                        local result = workspace:Raycast(origin, dir, GlobalRayParams)
                        
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

-- ОЧИСТКА ПАМЯТИ
Players.PlayerRemoving:Connect(function(plr)
    pcall(function()
        if espCache[plr] then
            if espCache[plr].Highlight then espCache[plr].Highlight:Destroy() end
            if espCache[plr].Billboard then espCache[plr].Billboard:Destroy() end
            if espCache[plr].Orbits then
                for _, orb in ipairs(espCache[plr].Orbits) do orb.gui:Destroy() end
            end
            espCache[plr] = nil
        end
        DeadCache[plr] = nil
        PlayerData[plr] = nil
    end)
end)

-- ESP И ЛОГИКА
local espCache = {}

local function updateESP()
    local t = tick()
    local camPos = Camera.CFrame.Position
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        
        if not PlayerData[plr] then
            PlayerData[plr] = { isDead = false, lastPos = Vector3.zero }
        end
        
        local char = plr.Character
        local isEnem = isEnemy(plr)
        
        if char and char:FindFirstChild("HumanoidRootPart") then
            PlayerData[plr].lastPos = char.HumanoidRootPart.Position
        end
        
        local isDead = false
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health <= 0 then isDead = true end
            if not char.Parent then isDead = true end 
        else
            isDead = true
        end

        if isDead then
            if PlayerData[plr].isDead == false then
                PlayerData[plr].isDead = true
                local distToDeath = (camPos - PlayerData[plr].lastPos).Magnitude
                
                if isEnem then
                    if LastTargetHit == plr and (tick() - LastTargetTime < 3) then
                        doKillEffect()
                    end
                else
                    if Mono.TeammateNotifs and distToDeath <= Mono.DeathNotifDistance then
                        showNotification("☠️ " .. plr.Name .. " УМЕР", Mono.KillColor)
                    end
                end
            end
        else
            PlayerData[plr].isDead = false
        end

        if char and char:FindFirstChild("HumanoidRootPart") and not isDead then
            local distToPlayer = (char.HumanoidRootPart.Position - camPos).Magnitude
            
            if Mono.ESP.Enabled and isEnem and distToPlayer <= Mono.ESP.MaxDistance then
                if not espCache[plr] then espCache[plr] = {} end
                if not espCache[plr].Highlight then
                    local hl = Instance.new("Highlight")
                    hl.Name = "MonoESP"
                    hl.FillColor = Mono.ESPColor
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
                    
                    hl.Parent = screenGui
                    bb.Parent = screenGui
                end
                
                espCache[plr].Highlight.Enabled = true
                espCache[plr].Billboard.Enabled = true
                if espCache[plr].Highlight.Adornee ~= char then espCache[plr].Highlight.Adornee = char end
                if espCache[plr].Billboard.Adornee ~= char.HumanoidRootPart then espCache[plr].Billboard.Adornee = char.HumanoidRootPart end
                
                espCache[plr].Text.Text = string.format("%s [%dm]", plr.Name, math.floor(distToPlayer))
                espCache[plr].Highlight.FillColor = Mono.ESPColor
                espCache[plr].Text.TextColor3 = Mono.ESPColor
            else
                if espCache[plr] and espCache[plr].Highlight then
                    espCache[plr].Highlight.Enabled = false
                    espCache[plr].Billboard.Enabled = false
                end
            end

            if Mono.TargetObjEnabled and isEnem then
                if not espCache[plr] then espCache[plr] = {} end
                if not espCache[plr].Orbits then
                    espCache[plr].Orbits = {}
                    for i=1, 3 do
                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(2, 0, 2, 0) 
                        bb.AlwaysOnTop = true
                        bb.Parent = screenGui
                        local tl = Instance.new("TextLabel", bb)
                        tl.Size = UDim2.new(1, 0, 1, 0)
                        tl.BackgroundTransparency = 1
                        tl.TextScaled = true 
                        table.insert(espCache[plr].Orbits, {gui = bb, text = tl})
                    end
                end

                for i, orb in ipairs(espCache[plr].Orbits) do
                    orb.gui.Enabled = true
                    if orb.gui.Adornee ~= char.HumanoidRootPart then orb.gui.Adornee = char.HumanoidRootPart end
                    orb.text.Text = Mono.OrbitEmoji
                    local angle = t * 2 + (i * (math.pi * 2 / 3))
                    local radius = 3.5
                    orb.gui.StudsOffset = Vector3.new(math.cos(angle) * radius, math.sin(t * 3) * 1.5, math.sin(angle) * radius)
                end
            else
                if espCache[plr] and espCache[plr].Orbits then
                    for _, orb in ipairs(espCache[plr].Orbits) do
                        orb.gui.Enabled = false
                    end
                end
            end
        else
            if espCache[plr] then
                if espCache[plr].Highlight then
                    espCache[plr].Highlight.Enabled = false
                    espCache[plr].Billboard.Enabled = false
                end
                if espCache[plr].Orbits then
                    for _, orb in ipairs(espCache[plr].Orbits) do
                        orb.gui.Enabled = false
                    end
                end
            end
        end
    end
end

-- === ОСНОВНОЙ ЦИКЛ ===
RunService:BindToRenderStep("MonoCore", Enum.RenderPriority.Camera.Value + 1, function()
    pcall(function()
        updateESP()
        
        -- НОВОЕ: Отрисовка круга FOV на экране
        if Mono.FOV.Enabled then
            fovFrame.Visible = true
            fovFrame.Size = UDim2.new(0, Mono.FOV.Radius * 2, 0, Mono.FOV.Radius * 2)
            fovStroke.Color = Mono.FOV.Color
        else
            fovFrame.Visible = false
        end
        
        if Mono.TimeOfDay == "Day ☀️" then
            Lighting.ClockTime = 14
        elseif Mono.TimeOfDay == "Night 🌙" then
            Lighting.ClockTime = 0
        end

        if Mono.Aimbot.Enabled then
            local target = getClosestVisibleEnemy()
            if target then
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
                local targetPlayer = getPlayerFromPart(target)
                if targetPlayer then
                    LastTargetHit = targetPlayer
                    LastTargetTime = tick()
                end
            end
        end

        if Mono.AutoTap.Enabled then
            local hitResult = raycastFromCamera()
            if hitResult and hitResult.Instance then
                local targetPlayer = getPlayerFromPart(hitResult.Instance)
                if targetPlayer and isEnemy(targetPlayer) then
                    
                    -- НОВОЕ: Проверка радиуса FOV для Авто-тапа
                    local char = targetPlayer.Character
                    local targetPart = char and getBestTargetPart(char)
                    if targetPart then
                        local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        
                        if onScreen and dist <= Mono.FOV.Radius then
                            LastTargetHit = targetPlayer
                            LastTargetTime = tick()
                            
                            if tick() - LastShootTime > Mono.AutoTap.Delay then
                                LastShootTime = tick()
                                simulateClick()
                            end
                        end
                    end
                end
            end
        end
    end)
end)
