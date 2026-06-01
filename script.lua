local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- === 1. БЕЗОПАСНАЯ ЗАГРУЗКА И ОЧИСТКА ===
local targetParent = nil
pcall(function() 
    if type(gethui) == "function" then 
        targetParent = gethui() 
    end
end)
if not targetParent then pcall(function() targetParent = game:GetService("CoreGui") end) end
if not targetParent then targetParent = LocalPlayer:WaitForChild("PlayerGui") end

pcall(function()
    local oldGui = targetParent:FindFirstChild("MonogrammaKlient")
    if oldGui then oldGui:Destroy() end
    local oldBlur = Lighting:FindFirstChild("MonoMenuBlur")
    if oldBlur then oldBlur:Destroy() end
end)

-- === 2. НАСТРОЙКИ ЧИТА ===
local Mono = {
    Aimbot = { Enabled = false, Key = Enum.KeyCode.C, Mode = "Rage 😡", Smoothness = 0.2 },
    TriggerBot = { Enabled = false, Key = Enum.KeyCode.V, Delay = 0.05 },
    
    FOV = { Enabled = false, Radius = 150, Color = Color3.fromRGB(180, 130, 255) },
    ESP = { Enabled = false, MaxDistance = 350 },
    ESPColor = Color3.fromRGB(180, 130, 255),
    
    -- НОВЫЕ ФУНКЦИИ KNIFE
    Speed = { Enabled = false, Value = 50 },
    Push = { Enabled = false, Key = Enum.KeyCode.F },
    
    TargetObjEnabled = false,
    OrbitEmoji = "🦋",
    OffScreenArrows = { Enabled = false, Radius = 100, Color = Color3.fromRGB(255, 50, 50) }, 
    Crosshair = { Enabled = false, Size = 8, Gap = 4, Thickness = 2, Color = Color3.fromRGB(180, 130, 255), HideDefault = false, Key = Enum.KeyCode.Unknown }, 
    KillEffect = false,
    KillEmoji = "💀", 
    KillColor = Color3.fromRGB(255, 50, 50), 
    TeammateNotifs = false,
    DeathNotifDistance = 150, 
    TintEnabled = false,
    TintColor = Color3.fromRGB(110, 60, 220),
    TimeOfDay = "Default", 
    WeatherEnabled = false,
    WeatherType = "Rain 🌧️",       
    WeatherEmoji = "💸",
    ConfigNames = {"Config 1", "Config 2", "Config 3", "Config 4", "Config 5", "Config 6"},
    SelectedConfigSlot = 1,
    WatermarkEnabled = true, 
    MenuOpen = true
}

local LastShootTime = 0
local BindWait = nil 
local PlayerData = {} 
local LastTargetHit = nil
local LastTargetTime = 0

-- БЕЗОПАСНАЯ РАБОТА С ФАЙЛАМИ
local safeReadFile = function(file)
    local s, r = pcall(function() 
        if type(readfile) == "function" then return readfile(file) end 
    end)
    return s and r or nil
end
local safeWriteFile = function(file, data)
    pcall(function() 
        if type(writefile) == "function" then writefile(file, data) end 
    end)
end

pcall(function()
    local content = safeReadFile("MonoSlotNames.txt")
    if content and content ~= "" then
        local names = {}
        for name in string.gmatch(content, "([^|]+)") do
            table.insert(names, name)
        end
        if #names == 6 then
            Mono.ConfigNames = names
        end
    end
end)

local function SaveSlotNames()
    safeWriteFile("MonoSlotNames.txt", table.concat(Mono.ConfigNames, "|"))
end

-- === УНИВЕРСАЛЬНАЯ БЕЗОПАСНАЯ ФУНКЦИЯ ПЕРЕТАСКИВАНИЯ ===
local function makeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

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

-- === BLUR ФОНА ===
local menuBlur = Instance.new("BlurEffect")
menuBlur.Name = "MonoMenuBlur"
menuBlur.Size = 15
menuBlur.Parent = Lighting

-- === ПЛАВАЮЩАЯ КНОПКА МЕНЮ ===
local mobileToggle = Instance.new("TextButton")
mobileToggle.Size = UDim2.new(0, 45, 0, 45)
mobileToggle.Position = UDim2.new(0, 10, 0, 10)
mobileToggle.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
mobileToggle.Text = "⬟"
mobileToggle.TextColor3 = Color3.fromRGB(180, 130, 255)
mobileToggle.TextSize = 24
mobileToggle.Font = Enum.Font.GothamBlack
mobileToggle.Active = true
Instance.new("UICorner", mobileToggle).CornerRadius = UDim.new(1, 0)
local toggleStroke = Instance.new("UIStroke", mobileToggle)
toggleStroke.Color = Color3.fromRGB(180, 130, 255)
toggleStroke.Thickness = 2
mobileToggle.Parent = screenGui
makeDraggable(mobileToggle)

-- === ВОТЕРМАРКА (FPS / PING) ===
local watermarkFrame = Instance.new("Frame", screenGui)
watermarkFrame.Size = UDim2.new(0, 250, 0, 25)
watermarkFrame.Position = UDim2.new(1, -260, 0, 10)
watermarkFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
watermarkFrame.BackgroundTransparency = 0.2
watermarkFrame.BorderSizePixel = 0
watermarkFrame.Active = true 
Instance.new("UICorner", watermarkFrame).CornerRadius = UDim.new(0, 6)
local watermarkStroke = Instance.new("UIStroke", watermarkFrame)
watermarkStroke.Color = Color3.fromRGB(180, 130, 255)
watermarkStroke.Thickness = 1
makeDraggable(watermarkFrame) 

local watermarkText = Instance.new("TextLabel", watermarkFrame)
watermarkText.Size = UDim2.new(1, 0, 1, 0)
watermarkText.BackgroundTransparency = 1
watermarkText.Text = "MONOGRAMMA | FPS: -- | Ping: --ms"
watermarkText.TextColor3 = Color3.fromRGB(255, 255, 255)
watermarkText.Font = Enum.Font.GothamBold
watermarkText.TextSize = 12

-- === КРУГ FOV ===
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

-- === КАСТОМНЫЙ ПРИЦЕЛ ===
local crosshairFolder = Instance.new("Folder", screenGui)
local chTop = Instance.new("Frame", crosshairFolder); chTop.BorderSizePixel = 0; chTop.AnchorPoint = Vector2.new(0.5, 1)
local chBot = Instance.new("Frame", crosshairFolder); chBot.BorderSizePixel = 0; chBot.AnchorPoint = Vector2.new(0.5, 0)
local chLeft = Instance.new("Frame", crosshairFolder); chLeft.BorderSizePixel = 0; chLeft.AnchorPoint = Vector2.new(1, 0.5)
local chRight = Instance.new("Frame", crosshairFolder); chRight.BorderSizePixel = 0; chRight.AnchorPoint = Vector2.new(0, 0.5)

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
            if Mono.WeatherEnabled then
                local isRain = (Mono.WeatherType == "Rain 🌧️")
                local wDrop = Instance.new("TextLabel", weatherContainer)
                wDrop.BackgroundTransparency = 1
                wDrop.Size = UDim2.new(0, 30, 0, 30)
                wDrop.Position = UDim2.new(math.random(), 0, -0.1, 0)
                wDrop.Text = isRain and "💧" or Mono.WeatherEmoji
                wDrop.TextSize = isRain and math.random(15, 20) or math.random(20, 35)
                wDrop.TextTransparency = 0.2
                
                local duration = math.random(30, 60) / 10 
                local targetX = wDrop.Position.X.Scale + (math.random(-10, 10) / 100) 
                
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

-- === УВЕДОМЛЕНИЯ И TOOLTIPS ===
local tooltipGui = Instance.new("Frame", screenGui)
tooltipGui.BackgroundColor3 = Color3.fromRGB(15, 10, 20)
tooltipGui.BackgroundTransparency = 0.1
tooltipGui.BorderSizePixel = 0
tooltipGui.ZIndex = 1000
tooltipGui.Visible = false
Instance.new("UICorner", tooltipGui).CornerRadius = UDim.new(0, 6)
local ttStroke = Instance.new("UIStroke", tooltipGui)
ttStroke.Color = Color3.fromRGB(180, 130, 255)
ttStroke.Thickness = 1
local ttText = Instance.new("TextLabel", tooltipGui)
ttText.Size = UDim2.new(1, -10, 1, -10)
ttText.Position = UDim2.new(0, 5, 0, 5)
ttText.BackgroundTransparency = 1
ttText.TextColor3 = Color3.fromRGB(220, 220, 220)
ttText.Font = Enum.Font.Gotham
ttText.TextSize = 12
ttText.TextWrapped = true

local function handleTooltip(uiElement, text)
    if not text then return end
    uiElement.MouseEnter:Connect(function()
        ttText.Text = text
        local textBounds = ttText.TextBounds
        tooltipGui.Size = UDim2.new(0, textBounds.X + 20, 0, textBounds.Y + 20)
        tooltipGui.Visible = true
    end)
    uiElement.MouseLeave:Connect(function()
        tooltipGui.Visible = false
    end)
end

RunService.RenderStepped:Connect(function()
    if tooltipGui.Visible then
        local mousePos = UserInputService:GetMouseLocation()
        tooltipGui.Position = UDim2.new(0, mousePos.X + 15, 0, mousePos.Y + 15)
    end
end)

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

-- === STATUS HUD ===
local hudFrame = Instance.new("Frame", screenGui)
hudFrame.Size = UDim2.new(0, 150, 0, 0)
hudFrame.Position = UDim2.new(1, -160, 0, 60)
hudFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
hudFrame.BackgroundTransparency = 0.2
hudFrame.BorderSizePixel = 0
hudFrame.ClipsDescendants = true 
hudFrame.Active = true
Instance.new("UICorner", hudFrame).CornerRadius = UDim.new(0, 8)
makeDraggable(hudFrame)

local hudList = Instance.new("UIListLayout", hudFrame)
hudList.Padding = UDim.new(0, 5)
hudList.HorizontalAlignment = Enum.HorizontalAlignment.Center
hudList.SortOrder = Enum.SortOrder.LayoutOrder

local hudTitle = Instance.new("TextLabel", hudFrame)
hudTitle.Name = "0_Title"
hudTitle.Size = UDim2.new(1, 0, 0, 30)
hudTitle.BackgroundTransparency = 1
hudTitle.Text = "MONOGRAMMA"
hudTitle.TextColor3 = Color3.fromRGB(180, 130, 255)
hudTitle.Font = Enum.Font.GothamBlack
hudTitle.TextSize = 12

local function updateHUD()
    pcall(function()
        for _, v in pairs(hudFrame:GetChildren()) do
            if v:IsA("TextLabel") and v.Name ~= "0_Title" then 
                v:Destroy() 
            end
        end

        local activeCount = 0
        local function addActiveFeature(name)
            activeCount = activeCount + 1
            local lbl = Instance.new("TextLabel", hudFrame)
            lbl.Name = "1_" .. name
            lbl.Size = UDim2.new(1, -20, 0, 20)
            lbl.BackgroundTransparency = 1
            lbl.Text = name
            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            
            local dot = Instance.new("Frame", lbl)
            dot.Size = UDim2.new(0, 6, 0, 6)
            dot.Position = UDim2.new(1, -10, 0.5, -3)
            dot.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        end

        if Mono.Aimbot.Enabled then addActiveFeature("Aimbot (".. Mono.Aimbot.Mode ..")") end
        if Mono.TriggerBot.Enabled then addActiveFeature("TriggerBot") end
        if Mono.Speed.Enabled then addActiveFeature("Speeds") end
        if Mono.Push.Enabled then addActiveFeature("Push (Fly)") end
        if Mono.ESP.Enabled then addActiveFeature("Wallhack") end
        if Mono.TargetObjEnabled then addActiveFeature("Orbits") end
        if Mono.TintEnabled then addActiveFeature("Screen Tint") end
        if Mono.WeatherEnabled then addActiveFeature("Weather") end

        local targetHeight = (activeCount > 0) and (activeCount * 25 + 35) or 0
        TweenService:Create(hudFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 150, 0, targetHeight)}):Play()
    end)
end

-- === ГЛАВНОЕ МЕНЮ С АНИМАЦИЕЙ ИЗ ЦЕНТРА ===
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 340)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
makeDraggable(mainFrame) 

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
        for _, p in pairs(Pages) do 
            p.Visible = false 
        end
        
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

-- === ФУНКЦИИ GUI: ЭЛЕМЕНТЫ ===
local function createSectionHeader(parent, text)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 20)
    frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  --- " .. text .. " ---"
    lbl.TextColor3 = Color3.fromRGB(180, 130, 255)
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    return frame
end

local function createButton(parent, text, callback, tooltip)
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
    
    handleTooltip(btn, tooltip)
    
    btn.MouseButton1Click:Connect(function()
        local ts = TweenService:Create(frame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(180, 130, 255)})
        ts:Play()
        ts.Completed:Wait()
        local tsBack = TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 30, 60)})
        tsBack:Play()
        callback()
    end)
end

local function createInput(parent, text, defaultText, callback, uiName)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BackgroundTransparency = 0.4
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  " .. text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(0, 120, 0, 24)
    box.Position = UDim2.new(1, -130, 0.5, -12)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    box.Text = defaultText
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    
    if uiName then 
        box.Name = uiName 
    end

    box.FocusLost:Connect(function()
        if box.Text == "" then 
            box.Text = defaultText 
        end
        callback(box.Text)
    end)
    return 35
end

local function createSubInput(parent, text, defaultText, callback, uiName)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "    -> " .. text
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
    
    if uiName then box.Name = uiName end

    box.FocusLost:Connect(function()
        if box.Text == "" then box.Text = defaultText end
        callback(box.Text)
    end)
    return 35
end

local function createSubToggle(parent, text, defaultState, callback, uiName)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "    -> " .. text
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -55, 0.5, -10)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = defaultState and "ON" or "OFF"
    btn.TextColor3 = defaultState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    if uiName then btn.Name = uiName end

    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.TextColor3 = state and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(200, 200, 200)
        callback(state)
    end)
    
    return 35
end

local function createSubCycleButton(parent, text, options, defaultIndex, callback, uiName)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "    -> " .. text
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 80, 0, 24)
    btn.Position = UDim2.new(1, -95, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = options[defaultIndex]
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    if uiName then btn.Name = uiName end

    local currentIndex = defaultIndex
    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #options then currentIndex = 1 end
        btn.Text = options[currentIndex]
        callback(options[currentIndex])
    end)
    
    return 35
end

local function createSubColorPicker(parent, text, defaultColor, callback, uiName)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6, 0, 0, 20)
    lbl.Position = UDim2.new(0, 0, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = "    -> " .. text
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local colorPreview = Instance.new("Frame", frame)
    colorPreview.Size = UDim2.new(0, 30, 0, 16)
    colorPreview.Position = UDim2.new(1, -45, 0, 7)
    colorPreview.BackgroundColor3 = defaultColor
    Instance.new("UICorner", colorPreview).CornerRadius = UDim.new(0, 4)
    
    if uiName then colorPreview.Name = uiName end

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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingHue = true
            updateHue(input.Position.X)
        end
    end)
    hueFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDraggingHue = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingHue and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateHue(input.Position.X) end
    end)
    return 50
end

local function createDropdown(parent, text, options, defaultIndex, callback, uiName)
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
    if uiName then mainBtn.Name = uiName end

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
        end)
    end
end

local function createToggle(parent, text, defaultState, onToggle, tooltip)
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

    handleTooltip(btn, tooltip)

    local status = Instance.new("Frame", frame)
    status.Name = "Status"
    status.Size = UDim2.new(0, 14, 0, 14)
    status.Position = UDim2.new(1, -30, 0.5, -7)
    status.BackgroundColor3 = defaultState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)
    
    btn.MouseButton1Click:Connect(function()
        local newState = (status.BackgroundColor3 == Color3.fromRGB(60, 60, 70))
        status.BackgroundColor3 = newState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
        btn.TextColor3 = newState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        onToggle(newState)
        updateHUD()
    end)
end

local function createToggleWithBind(parent, text, defaultState, defaultBind, onToggle, bindTable, bindKeyName, tooltip)
    local frame = Instance.new("Frame", parent)
    frame.Name = text
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BackgroundTransparency = 0.4
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local topBar = Instance.new("Frame", frame)
    topBar.Size = UDim2.new(1, 0, 0, 35)
    topBar.BackgroundTransparency = 1

    local btn = Instance.new("TextButton", topBar)
    btn.Name = "MainBtn"
    btn.Size = UDim2.new(1, -160, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. text
    btn.TextColor3 = defaultState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left

    handleTooltip(btn, tooltip)

    local status = Instance.new("Frame", topBar)
    status.Name = "Status"
    status.Size = UDim2.new(0, 14, 0, 14)
    status.Position = UDim2.new(1, -60, 0.5, -7)
    status.BackgroundColor3 = defaultState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)

    local bindBtn = Instance.new("TextButton", topBar)
    bindBtn.Name = "BindBtn"
    bindBtn.Size = UDim2.new(0, 80, 0, 24)
    bindBtn.Position = UDim2.new(1, -150, 0.5, -12)
    bindBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    bindBtn.Text = (defaultBind and defaultBind ~= Enum.KeyCode.Unknown) and defaultBind.Name or "None"
    bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bindBtn.Font = Enum.Font.Gotham
    bindBtn.TextSize = 12
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        local newState = (status.BackgroundColor3 == Color3.fromRGB(60, 60, 70))
        status.BackgroundColor3 = newState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
        btn.TextColor3 = newState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        onToggle(newState)
        updateHUD()
    end)

    bindBtn.MouseButton1Click:Connect(function()
        if BindWait then return end
        bindBtn.Text = "..."
        BindWait = function(key)
            bindTable[bindKeyName] = key
            local kn = key.Name
            if key == Enum.UserInputType.MouseButton1 then kn = "LMB"
            elseif key == Enum.UserInputType.MouseButton2 then kn = "RMB"
            elseif key == Enum.KeyCode.Unknown then kn = "None"
            end
            bindBtn.Text = kn
            BindWait = nil
        end
    end)
end

local function createToggleWithBindAndSettings(parent, text, defaultState, defaultBind, onToggle, bindTable, bindKeyName, buildSettingsFunc, tooltip)
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
    btn.Size = UDim2.new(1, -160, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. text
    btn.TextColor3 = defaultState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left

    handleTooltip(btn, tooltip)

    local gearBtn = Instance.new("TextButton", topBar)
    gearBtn.Size = UDim2.new(0, 24, 0, 24)
    gearBtn.Position = UDim2.new(1, -30, 0.5, -12)
    gearBtn.BackgroundTransparency = 1
    gearBtn.Text = "⚙️"
    gearBtn.TextSize = 14

    local status = Instance.new("Frame", topBar)
    status.Name = "Status"
    status.Size = UDim2.new(0, 14, 0, 14)
    status.Position = UDim2.new(1, -60, 0.5, -7)
    status.BackgroundColor3 = defaultState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)
    
    local bindBtn = Instance.new("TextButton", topBar)
    bindBtn.Name = "BindBtn"
    bindBtn.Size = UDim2.new(0, 80, 0, 24)
    bindBtn.Position = UDim2.new(1, -150, 0.5, -12)
    bindBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    bindBtn.Text = (defaultBind and defaultBind ~= Enum.KeyCode.Unknown) and defaultBind.Name or "None"
    bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bindBtn.Font = Enum.Font.Gotham
    bindBtn.TextSize = 12
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)

    local settingsFrame = Instance.new("Frame", container)
    settingsFrame.Size = UDim2.new(1, 0, 0, 200) 
    settingsFrame.Position = UDim2.new(0, 0, 0, 35)
    settingsFrame.BackgroundTransparency = 1
    
    local sLayout = Instance.new("UIListLayout", settingsFrame)
    sLayout.Padding = UDim.new(0, 5)
    
    local totalSettingsHeight = buildSettingsFunc(settingsFrame)

    btn.MouseButton1Click:Connect(function() 
        local newState = (status.BackgroundColor3 == Color3.fromRGB(60, 60, 70))
        status.BackgroundColor3 = newState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
        btn.TextColor3 = newState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        onToggle(newState) 
        updateHUD()
    end)

    bindBtn.MouseButton1Click:Connect(function()
        if BindWait then return end 
        bindBtn.Text = "..."
        BindWait = function(key)
            bindTable[bindKeyName] = key
            local kn = key.Name
            if key == Enum.UserInputType.MouseButton1 then kn = "LMB" 
            elseif key == Enum.UserInputType.MouseButton2 then kn = "RMB" 
            elseif key == Enum.KeyCode.Unknown then kn = "None"
            end
            bindBtn.Text = kn
            BindWait = nil 
        end
    end)

    local isOpen = false
    gearBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        TweenService:Create(gearBtn, TweenInfo.new(0.3), {Rotation = isOpen and 90 or 0}):Play()
        local targetSize = isOpen and (35 + totalSettingsHeight + 5) or 35
        TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetSize)}):Play()
    end)
end

local function createToggleWithSettings(parent, text, defaultState, onToggle, buildSettingsFunc, tooltip)
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

    handleTooltip(btn, tooltip)

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

    btn.MouseButton1Click:Connect(function() 
        local newState = (status.BackgroundColor3 == Color3.fromRGB(60, 60, 70))
        status.BackgroundColor3 = newState and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(60, 60, 70)
        btn.TextColor3 = newState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        onToggle(newState) 
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

local function createSubBind(parent, text, defaultBind, bindTable, bindKeyName, uiName)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "    -> " .. text
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 80, 0, 24)
    btn.Position = UDim2.new(1, -95, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = (defaultBind and defaultBind ~= Enum.KeyCode.Unknown) and defaultBind.Name or "None"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    if uiName then btn.Name = uiName end

    btn.MouseButton1Click:Connect(function()
        if BindWait then return end 
        btn.Text = "..."
        BindWait = function(key)
            bindTable[bindKeyName] = key
            local kn = key.Name
            if key == Enum.UserInputType.MouseButton1 then kn = "LMB" 
            elseif key == Enum.UserInputType.MouseButton2 then kn = "RMB" 
            elseif key == Enum.KeyCode.Unknown then kn = "None"
            end
            btn.Text = kn
            BindWait = nil 
        end
    end)
    return 35
end

-- === СИСТЕМА КОНФИГОВ ===

local function GetConfigTable()
    return {
        AimbotE = Mono.Aimbot.Enabled, AimbotK = Mono.Aimbot.Key.Name, AimMode = Mono.Aimbot.Mode, AimSmooth = Mono.Aimbot.Smoothness,
        TrigE = Mono.TriggerBot.Enabled, TrigK = Mono.TriggerBot.Key.Name,
        SpeedE = Mono.Speed.Enabled, SpeedV = Mono.Speed.Value,
        PushE = Mono.Push.Enabled, PushK = Mono.Push.Key.Name,
        FOVE = Mono.FOV.Enabled, FOVRad = Mono.FOV.Radius,
        FOV_R = Mono.FOV.Color.R, FOV_G = Mono.FOV.Color.G, FOV_B = Mono.FOV.Color.B,
        ESPE = Mono.ESP.Enabled, ESPMaxDist = Mono.ESP.MaxDistance,
        ESP_R = Mono.ESPColor.R, ESP_G = Mono.ESPColor.G, ESP_B = Mono.ESPColor.B,
        TargetObjE = Mono.TargetObjEnabled, ObjEmoji = Mono.OrbitEmoji,
        OffArrE = Mono.OffScreenArrows.Enabled, OffArrRad = Mono.OffScreenArrows.Radius, 
        OffArr_R = Mono.OffScreenArrows.Color.R, OffArr_G = Mono.OffScreenArrows.Color.G, OffArr_B = Mono.OffScreenArrows.Color.B,
        CrossE = Mono.Crosshair.Enabled, CrossS = Mono.Crosshair.Size, CrossG = Mono.Crosshair.Gap, CrossT = Mono.Crosshair.Thickness,
        Cross_R = Mono.Crosshair.Color.R, Cross_G = Mono.Crosshair.Color.G, Cross_B = Mono.Crosshair.Color.B,
        CrossHide = Mono.Crosshair.HideDefault,
        CrossK = (Mono.Crosshair.Key and Mono.Crosshair.Key ~= Enum.KeyCode.Unknown) and Mono.Crosshair.Key.Name or "Unknown",
        KillEffE = Mono.KillEffect, KillEmoji = Mono.KillEmoji,
        Kill_R = Mono.KillColor.R, Kill_G = Mono.KillColor.G, Kill_B = Mono.KillColor.B,
        TeamNotifE = Mono.TeammateNotifs, DeathDist = Mono.DeathNotifDistance,
        TintE = Mono.TintEnabled,
        Tint_R = Mono.TintColor.R, Tint_G = Mono.TintColor.G, Tint_B = Mono.TintColor.B,
        Time = Mono.TimeOfDay,
        WeatherEnabled = Mono.WeatherEnabled, WeatherType = Mono.WeatherType, WeathEmoji = Mono.WeatherEmoji,
        WatermarkE = Mono.WatermarkEnabled
    }
end

local function EncodeTXT(tbl)
    local str = ""
    for k, v in pairs(tbl) do
        str = str .. tostring(k) .. "=" .. tostring(v) .. "\n"
    end
    return str
end

local function DecodeTXT(str)
    local tbl = {}
    for line in string.gmatch(str, "[^\r\n]+") do
        local k, v = string.match(line, "^([^=]+)=(.+)$")
        if k and v then
            if v == "true" then tbl[k] = true
            elseif v == "false" then tbl[k] = false
            elseif tonumber(v) then tbl[k] = tonumber(v)
            else tbl[k] = v end
        end
    end
    return tbl
end

local function ApplyConfigToUI()
    setToggleStateUI("Aimbot (Toggle)", Mono.Aimbot.Enabled)
    setToggleStateUI("TriggerBot (Toggle)", Mono.TriggerBot.Enabled)
    setToggleStateUI("Speeds", Mono.Speed.Enabled)
    setToggleStateUI("Push", Mono.Push.Enabled)
    setToggleStateUI("Draw FOV Circle", Mono.FOV.Enabled)
    setToggleStateUI("Wallhack (ESP)", Mono.ESP.Enabled)
    setToggleStateUI("Teammate Death Notifs", Mono.TeammateNotifs)
    setToggleStateUI("Enemy Orbits", Mono.TargetObjEnabled)
    setToggleStateUI("Off-Screen Arrows", Mono.OffScreenArrows.Enabled)
    setToggleStateUI("Custom Crosshair", Mono.Crosshair.Enabled)
    setToggleStateUI("Kill Effect", Mono.KillEffect)
    setToggleStateUI("Screen Tint", Mono.TintEnabled)
    setToggleStateUI("Weather Event", Mono.WeatherEnabled)
    setToggleStateUI("Show Watermark", Mono.WatermarkEnabled)
    
    tintFrame.BackgroundTransparency = Mono.TintEnabled and 0.85 or 1
    tintFrame.BackgroundColor3 = Mono.TintColor
    
    pcall(function()
        for _, v in pairs(contentArea:GetDescendants()) do
            if v:IsA("TextButton") and v.Name == "BindBtn" then
                if v.Parent.Parent.Name == "Aimbot (Toggle)" then v.Text = Mono.Aimbot.Key.Name end
                if v.Parent.Parent.Name == "TriggerBot (Toggle)" then v.Text = Mono.TriggerBot.Key.Name end
                if v.Parent.Name == "Push" then v.Text = (Mono.Push.Key and Mono.Push.Key ~= Enum.KeyCode.Unknown) and Mono.Push.Key.Name or "None" end
            end
            if v:IsA("TextBox") then
                if v.Name == "FOVRadInput" then v.Text = tostring(Mono.FOV.Radius) end
                if v.Name == "ESPMaxInput" then v.Text = tostring(Mono.ESP.MaxDistance) end
                if v.Name == "DeathDistInput" then v.Text = tostring(Mono.DeathNotifDistance) end
                if v.Name == "OrbitEmojiInput" then v.Text = Mono.OrbitEmoji end
                if v.Name == "KillEmojiInput" then v.Text = Mono.KillEmoji end
                if v.Name == "WeathEmojiInput" then v.Text = Mono.WeatherEmoji end
                if v.Name == "ArrRadInput" then v.Text = tostring(Mono.OffScreenArrows.Radius) end
                if v.Name == "CrossSInput" then v.Text = tostring(Mono.Crosshair.Size) end
                if v.Name == "CrossGInput" then v.Text = tostring(Mono.Crosshair.Gap) end
                if v.Name == "CrossTInput" then v.Text = tostring(Mono.Crosshair.Thickness) end
                if v.Name == "AimSmoothInput" then v.Text = tostring(Mono.Aimbot.Smoothness) end
                if v.Name == "SpeedValInput" then v.Text = tostring(Mono.Speed.Value) end
            end
            if v:IsA("Frame") then
                if v.Name == "FOVCol" then v.BackgroundColor3 = Mono.FOV.Color end
                if v.Name == "ESPCol" then v.BackgroundColor3 = Mono.ESPColor end
                if v.Name == "KillCol" then v.BackgroundColor3 = Mono.KillColor end
                if v.Name == "TintCol" then v.BackgroundColor3 = Mono.TintColor end
                if v.Name == "ArrCol" then v.BackgroundColor3 = Mono.OffScreenArrows.Color end
                if v.Name == "CrossCol" then v.BackgroundColor3 = Mono.Crosshair.Color end
            end
            if v:IsA("TextButton") and v.Name == "TimeDrop" then v.Text = "  Time of Day: " .. Mono.TimeOfDay end
            if v:IsA("TextButton") and v.Name == "AimModeBtn" then v.Text = Mono.Aimbot.Mode end
            if v:IsA("TextButton") and v.Name == "CrossHideToggle" then
                v.Text = Mono.Crosshair.HideDefault and "ON" or "OFF"
                v.TextColor3 = Mono.Crosshair.HideDefault and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(200, 200, 200)
            end
            if v:IsA("TextButton") and v.Name == "CrossBindBtn" then
                v.Text = (Mono.Crosshair.Key and Mono.Crosshair.Key ~= Enum.KeyCode.Unknown) and Mono.Crosshair.Key.Name or "None"
            end
        end
    end)
    updateHUD()
end

local function LoadConfigFromTable(dec)
    Mono.Aimbot.Enabled = dec.AimbotE or false
    Mono.Aimbot.Mode = dec.AimMode or "Rage 😡"
    Mono.Aimbot.Smoothness = dec.AimSmooth or 0.2
    pcall(function() Mono.Aimbot.Key = Enum.KeyCode[dec.AimbotK] or Enum.UserInputType[dec.AimbotK] end)
    
    Mono.TriggerBot.Enabled = dec.TrigE or false
    pcall(function() Mono.TriggerBot.Key = Enum.KeyCode[dec.TrigK] or Enum.UserInputType[dec.TrigK] end)

    Mono.Speed.Enabled = dec.SpeedE or false
    Mono.Speed.Value = dec.SpeedV or 50
    Mono.Push.Enabled = dec.PushE or false
    pcall(function() Mono.Push.Key = Enum.KeyCode[dec.PushK] or Enum.UserInputType[dec.PushK] end)

    Mono.FOV.Enabled = dec.FOVE or false
    Mono.FOV.Radius = dec.FOVRad or 150
    Mono.FOV.Color = Color3.new(dec.FOV_R or 1, dec.FOV_G or 1, dec.FOV_B or 1)

    Mono.ESP.Enabled = dec.ESPE or false
    Mono.ESP.MaxDistance = dec.ESPMaxDist or 350
    Mono.ESPColor = Color3.new(dec.ESP_R or 1, dec.ESP_G or 1, dec.ESP_B or 1)
    
    Mono.TargetObjEnabled = dec.TargetObjE or false
    Mono.OrbitEmoji = dec.ObjEmoji or "🦋"
    
    Mono.OffScreenArrows.Enabled = dec.OffArrE or false
    Mono.OffScreenArrows.Radius = dec.OffArrRad or 100
    Mono.OffScreenArrows.Color = Color3.new(dec.OffArr_R or 1, dec.OffArr_G or 0, dec.OffArr_B or 0)
    
    Mono.Crosshair.Enabled = dec.CrossE or false
    Mono.Crosshair.Size = dec.CrossS or 8
    Mono.Crosshair.Gap = dec.CrossG or 4
    Mono.Crosshair.Thickness = dec.CrossT or 2
    Mono.Crosshair.Color = Color3.new(dec.Cross_R or 1, dec.Cross_G or 1, dec.Cross_B or 1)
    Mono.Crosshair.HideDefault = dec.CrossHide or false
    pcall(function() Mono.Crosshair.Key = Enum.KeyCode[dec.CrossK] or Enum.UserInputType[dec.CrossK] end)
    
    Mono.KillEffect = dec.KillEffE or false
    Mono.KillEmoji = dec.KillEmoji or "💀"
    Mono.KillColor = Color3.new(dec.Kill_R or 1, dec.Kill_G or 0, dec.Kill_B or 0)
    
    Mono.TeammateNotifs = dec.TeamNotifE or false
    Mono.DeathNotifDistance = dec.DeathDist or 150
    
    Mono.TintEnabled = dec.TintE or false
    Mono.TintColor = Color3.new(dec.Tint_R or 1, dec.Tint_G or 1, dec.Tint_B or 1)
    
    Mono.TimeOfDay = dec.Time or "Default"
    Mono.WeatherEnabled = dec.WeatherEnabled or false
    Mono.WeatherType = dec.WeatherType or "Rain 🌧️"
    Mono.WeatherEmoji = dec.WeathEmoji or "💸"
    
    Mono.WatermarkEnabled = dec.WatermarkE
    if Mono.WatermarkEnabled == nil then Mono.WatermarkEnabled = true end

    ApplyConfigToUI()
end

local function GetCurrentFileName()
    return Mono.ConfigNames[Mono.SelectedConfigSlot] .. ".txt"
end

local function SaveConfig()
    pcall(function()
        local fileName = GetCurrentFileName()
        if type(writefile) == "function" then
            local textData = EncodeTXT(GetConfigTable())
            writefile(fileName, textData)
            showNotification("💾 Saved as " .. fileName, Color3.fromRGB(0, 255, 100))
        end
    end)
end

local function LoadConfig()
    local fileName = GetCurrentFileName()
    local success, content = pcall(function()
        if type(readfile) == "function" then
            return readfile(fileName)
        end
        return nil
    end)
    
    if success and content and content ~= "" then
        local decoded = DecodeTXT(content)
        LoadConfigFromTable(decoded)
        showNotification("📂 Loaded " .. fileName, Color3.fromRGB(0, 255, 100))
    else
        showNotification("❌ Config not found!", Color3.fromRGB(255, 50, 50))
    end
end

local function ExportConfig()
    pcall(function()
        if type(setclipboard) == "function" then
            local textData = EncodeTXT(GetConfigTable())
            setclipboard(textData)
            showNotification("📋 Copied to Clipboard!", Color3.fromRGB(100, 150, 255))
        end
    end)
end

-- === ЗАПОЛНЯЕМ ВКЛАДКИ ===

-- 1. COMBAT
createSectionHeader(combatPage, "GUN")

createToggleWithBindAndSettings(combatPage, "Aimbot (Toggle)", Mono.Aimbot.Enabled, Mono.Aimbot.Key, function(s) Mono.Aimbot.Enabled = s end, Mono.Aimbot, "Key", function(container)
    local h1 = createSubCycleButton(container, "Mode", {"Rage 😡", "Legit 🎯"}, Mono.Aimbot.Mode == "Rage 😡" and 1 or 2, function(val) Mono.Aimbot.Mode = val end, "AimModeBtn")
    local h2 = createSubInput(container, "Smoothness", tostring(Mono.Aimbot.Smoothness), function(val) Mono.Aimbot.Smoothness = tonumber(val) or 0.2 end, "AimSmoothInput")
    return h1 + h2 + 5
end, "Automatically aims at enemies.")

createToggleWithBind(combatPage, "TriggerBot (Toggle)", Mono.TriggerBot.Enabled, Mono.TriggerBot.Key, function(s) Mono.TriggerBot.Enabled = s end, Mono.TriggerBot, "Key", "Automatically shoots when your crosshair is exactly on an enemy.")

createToggleWithSettings(combatPage, "Draw FOV Circle", Mono.FOV.Enabled, function(s) Mono.FOV.Enabled = s end, function(container)
    local h1 = createSubInput(container, "Radius", tostring(Mono.FOV.Radius), function(val) Mono.FOV.Radius = tonumber(val) or 150 end, "FOVRadInput")
    local h2 = createSubColorPicker(container, "Circle Color", Mono.FOV.Color, function(c) Mono.FOV.Color = c end, "FOVCol")
    return h1 + h2 + 5
end, "Shows the area where Aimbot and TriggerBot work.")

createSectionHeader(combatPage, "KNIFE")

createToggleWithSettings(combatPage, "Speeds", Mono.Speed.Enabled, function(s) 
    Mono.Speed.Enabled = s 
    if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end, function(container)
    local h1 = createSubInput(container, "Value", tostring(Mono.Speed.Value), function(val) Mono.Speed.Value = tonumber(val) or 50 end, "SpeedValInput")
    return h1 + 5
end, "Увеличивает вашу скорость.")

createToggleWithBind(combatPage, "Push", Mono.Push.Enabled, Mono.Push.Key, function(s) Mono.Push.Enabled = s end, Mono.Push, "Key", "Подбрасывает вас вверх (можно спамить в воздухе).")


-- 2. VISUALS
createToggleWithSettings(visualsPage, "Wallhack (ESP)", Mono.ESP.Enabled, function(s) Mono.ESP.Enabled = s end, function(container)
    local h1 = createSubColorPicker(container, "ESP Color", Mono.ESPColor, function(c) Mono.ESPColor = c end, "ESPCol")
    local h2 = createSubInput(container, "Max Distance", tostring(Mono.ESP.MaxDistance), function(val) Mono.ESP.MaxDistance = tonumber(val) or 350 end, "ESPMaxInput")
    return h1 + h2 + 5
end, "Highlights enemies through walls with distance info.")

createToggleWithSettings(visualsPage, "Off-Screen Arrows", Mono.OffScreenArrows.Enabled, function(s) Mono.OffScreenArrows.Enabled = s end, function(container)
    local h1 = createSubInput(container, "Ring Radius", tostring(Mono.OffScreenArrows.Radius), function(val) Mono.OffScreenArrows.Radius = tonumber(val) or 100 end, "ArrRadInput")
    local h2 = createSubColorPicker(container, "Arrow Color", Mono.OffScreenArrows.Color, function(c) Mono.OffScreenArrows.Color = c end, "ArrCol")
    return h1 + h2 + 5
end, "Shows a radar ring pointing to enemies off-screen.")

createToggleWithSettings(visualsPage, "Custom Crosshair", Mono.Crosshair.Enabled, function(s) Mono.Crosshair.Enabled = s end, function(container)
    local h1 = createSubInput(container, "Line Size", tostring(Mono.Crosshair.Size), function(val) Mono.Crosshair.Size = tonumber(val) or 8 end, "CrossSInput")
    local h2 = createSubInput(container, "Center Gap", tostring(Mono.Crosshair.Gap), function(val) Mono.Crosshair.Gap = tonumber(val) or 4 end, "CrossGInput")
    local h3 = createSubInput(container, "Thickness", tostring(Mono.Crosshair.Thickness), function(val) Mono.Crosshair.Thickness = tonumber(val) or 2 end, "CrossTInput")
    local h4 = createSubColorPicker(container, "Color", Mono.Crosshair.Color, function(c) Mono.Crosshair.Color = c end, "CrossCol")
    local h5 = createSubToggle(container, "Hide Default Mouse", Mono.Crosshair.HideDefault, function(s) Mono.Crosshair.HideDefault = s end, "CrossHideToggle")
    local h6 = createSubBind(container, "Hide Mouse Key", Mono.Crosshair.Key, Mono.Crosshair, "Key", "CrossBindBtn")
    return h1 + h2 + h3 + h4 + h5 + h6 + 5
end, "Draws a custom crosshair in the center of your screen.")

createToggleWithSettings(visualsPage, "Enemy Orbits", Mono.TargetObjEnabled, function(s) Mono.TargetObjEnabled = s end, function(container)
    local h1 = createSubInput(container, "Orbit Emoji", Mono.OrbitEmoji, function(val) Mono.OrbitEmoji = val end, "OrbitEmojiInput")
    return h1
end, "Flying emojis spin around enemies like orbits.")

createToggleWithSettings(visualsPage, "Teammate Death Notifs", Mono.TeammateNotifs, function(s) Mono.TeammateNotifs = s end, function(container)
    local h1 = createSubInput(container, "Max Distance", tostring(Mono.DeathNotifDistance), function(val) Mono.DeathNotifDistance = tonumber(val) or 150 end, "DeathDistInput")
    return h1
end, "Notifies you when a teammate dies nearby.")

createToggleWithSettings(visualsPage, "Kill Effect", Mono.KillEffect, function(s) Mono.KillEffect = s end, function(container)
    local h1 = createSubInput(container, "Kill Emoji", Mono.KillEmoji, function(val) Mono.KillEmoji = val end, "KillEmojiInput")
    local h2 = createSubColorPicker(container, "Flash Color", Mono.KillColor, function(c) Mono.KillColor = c end, "KillCol")
    return h1 + h2 + 5
end, "Creates a screen flash and emoji explosion when you get a kill.")

-- 3. WORLD
createToggleWithSettings(worldPage, "Screen Tint", Mono.TintEnabled, function(s) 
    Mono.TintEnabled = s 
    tintFrame.BackgroundTransparency = s and 0.85 or 1
end, function(container)
    local h1 = createSubColorPicker(container, "Tint Color", Mono.TintColor, function(c) Mono.TintColor = c; tintFrame.BackgroundColor3 = c end, "TintCol")
    return h1
end, "Applies a colored filter over the whole game.")

createDropdown(worldPage, "Time of Day", {"Default", "Day ☀️", "Night 🌙"}, 1, function(val) Mono.TimeOfDay = val end, "TimeDrop")

createToggleWithSettings(worldPage, "Weather Event", Mono.WeatherEnabled, function(s) Mono.WeatherEnabled = s end, function(container)
    local h1 = createSubCycleButton(container, "Type", {"Rain 🌧️", "Custom ❄️"}, Mono.WeatherType == "Rain 🌧️" and 1 or 2, function(val) Mono.WeatherType = val end)
    local h2 = createSubInput(container, "Custom Emoji", Mono.WeatherEmoji, function(val) Mono.WeatherEmoji = val end, "WeathEmojiInput")
    return h1 + h2 + 5
end, "Creates falling emojis (like rain or snow).")

-- 4. SETTINGS
createToggle(settingsPage, "Show Watermark", Mono.WatermarkEnabled, function(s) Mono.WatermarkEnabled = s; watermarkFrame.Visible = s end, "Displays Ping and FPS in the top right corner.")

local configTitle = Instance.new("TextLabel", settingsPage)
configTitle.Size = UDim2.new(1, 0, 0, 20)
configTitle.BackgroundTransparency = 1
configTitle.Text = "  Select & Rename Config Slot (.txt):"
configTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
configTitle.Font = Enum.Font.GothamBold
configTitle.TextSize = 12
configTitle.TextXAlignment = Enum.TextXAlignment.Left

local gridFrame = Instance.new("Frame", settingsPage)
gridFrame.Size = UDim2.new(1, 0, 0, 140) 
gridFrame.BackgroundTransparency = 1

local gridLayout = Instance.new("UIGridLayout", gridFrame)
gridLayout.CellSize = UDim2.new(0, 105, 0, 65)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

local slotGuis = {}

local function updateSlotSelection()
    for i, slot in ipairs(slotGuis) do
        if Mono.SelectedConfigSlot == i then
            slot.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
        else
            slot.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
        end
    end
end

for i = 1, 6 do
    local slotFrame = Instance.new("TextButton", gridFrame)
    slotFrame.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
    slotFrame.Text = ""
    Instance.new("UICorner", slotFrame).CornerRadius = UDim.new(0, 6)
    
    local icon = Instance.new("TextLabel", slotFrame)
    icon.Size = UDim2.new(1, 0, 0, 35)
    icon.BackgroundTransparency = 1
    icon.Text = "📄"
    icon.TextSize = 24
    
    local nameBox = Instance.new("TextBox", slotFrame)
    nameBox.Size = UDim2.new(1, -10, 0, 20)
    nameBox.Position = UDim2.new(0, 5, 0, 38)
    nameBox.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
    nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameBox.Font = Enum.Font.Gotham
    nameBox.TextSize = 11
    nameBox.Text = Mono.ConfigNames[i]
    Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 4)
    
    nameBox.FocusLost:Connect(function()
        if nameBox.Text == "" then 
            nameBox.Text = "Config " .. i 
        end
        Mono.ConfigNames[i] = nameBox.Text
        SaveSlotNames()
    end)
    
    slotFrame.MouseButton1Click:Connect(function()
        Mono.SelectedConfigSlot = i
        updateSlotSelection()
    end)
    
    table.insert(slotGuis, slotFrame)
end
updateSlotSelection()

createButton(settingsPage, "💾 Save Selected Config", SaveConfig)
createButton(settingsPage, "📂 Load Selected Config", LoadConfig)

local importTitle = Instance.new("TextLabel", settingsPage)
importTitle.Size = UDim2.new(1, 0, 0, 20)
importTitle.BackgroundTransparency = 1
importTitle.Text = "  Share & Import (Paste text below to import):"
importTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
importTitle.Font = Enum.Font.GothamBold
importTitle.TextSize = 12
importTitle.TextXAlignment = Enum.TextXAlignment.Left

local importBoxFrame = Instance.new("Frame", settingsPage)
importBoxFrame.Size = UDim2.new(1, 0, 0, 35)
importBoxFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
Instance.new("UICorner", importBoxFrame).CornerRadius = UDim.new(0, 6)

local importBox = Instance.new("TextBox", importBoxFrame)
importBox.Size = UDim2.new(1, -20, 1, 0)
importBox.Position = UDim2.new(0, 10, 0, 0)
importBox.BackgroundTransparency = 1
importBox.Text = ""
importBox.PlaceholderText = "Paste your friend's config text here..."
importBox.TextColor3 = Color3.fromRGB(255, 255, 255)
importBox.Font = Enum.Font.Gotham
importBox.TextSize = 12
importBox.TextXAlignment = Enum.TextXAlignment.Left
importBox.ClearTextOnFocus = false
importBox.TextTruncate = Enum.TextTruncate.AtEnd

local function ManualImport()
    local clip = importBox.Text
    if clip and clip ~= "" then
        local decoded = DecodeTXT(clip)
        if decoded and next(decoded) ~= nil then
            LoadConfigFromTable(decoded)
            showNotification("📥 Imported successfully!", Color3.fromRGB(100, 150, 255))
            importBox.Text = "" 
        else
            showNotification("❌ Invalid Config Text!", Color3.fromRGB(255, 50, 50))
        end
    else
        showNotification("❌ Paste text first!", Color3.fromRGB(255, 50, 50))
    end
end

createButton(settingsPage, "📥 Import from Textbox", ManualImport)
createButton(settingsPage, "📋 Export to Clipboard", ExportConfig)

updateHUD() 
combatBtn.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
combatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
combatPage.Visible = true
activeBtn = combatBtn

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

    if key == Mono.TriggerBot.Key then
        Mono.TriggerBot.Enabled = not Mono.TriggerBot.Enabled
        setToggleStateUI("TriggerBot (Toggle)", Mono.TriggerBot.Enabled)
        updateHUD()
    end
    
    -- БИНД PUSH (FLYHACK)
    if key == Mono.Push.Key and Mono.Push.Enabled and Mono.Push.Key ~= Enum.KeyCode.Unknown then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Подбрасываем вверх, сохраняя скорость движения
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 50, hrp.AssemblyLinearVelocity.Z)
            end
        end
    end
    
    if Mono.Crosshair.Key and key == Mono.Crosshair.Key and Mono.Crosshair.Key ~= Enum.KeyCode.Unknown then
        Mono.Crosshair.HideDefault = not Mono.Crosshair.HideDefault
        pcall(function()
            for _, v in pairs(contentArea:GetDescendants()) do
                if v:IsA("TextButton") and v.Name == "CrossHideToggle" then
                    v.Text = Mono.Crosshair.HideDefault and "ON" or "OFF"
                    v.TextColor3 = Mono.Crosshair.HideDefault and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(200, 200, 200)
                end
            end
        end)
    end

    if input.KeyCode == Enum.KeyCode.RightShift then
        Mono.MenuOpen = not Mono.MenuOpen
        unlockMouseBtn.Modal = Mono.MenuOpen
        
        if Mono.MenuOpen then
            mainFrame.Visible = true
            menuBlur.Enabled = true
            TweenService:Create(uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
            TweenService:Create(menuBlur, TweenInfo.new(0.3), {Size = 15}):Play()
        else
            local tw = TweenService:Create(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
            tw:Play()
            TweenService:Create(menuBlur, TweenInfo.new(0.3), {Size = 0}):Play()
            tw.Completed:Connect(function()
                if not Mono.MenuOpen then 
                    mainFrame.Visible = false 
                    menuBlur.Enabled = false
                end
            end)
        end
    end
end)

-- ПЛАВАЮЩАЯ КНОПКА (ОТКРЫТЬ/ЗАКРЫТЬ)
mobileToggle.MouseButton1Click:Connect(function()
    Mono.MenuOpen = not Mono.MenuOpen
    unlockMouseBtn.Modal = Mono.MenuOpen
    if Mono.MenuOpen then
        mainFrame.Visible = true
        menuBlur.Enabled = true
        TweenService:Create(uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(menuBlur, TweenInfo.new(0.3), {Size = 15}):Play()
    else
        local tw = TweenService:Create(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
        tw:Play()
        TweenService:Create(menuBlur, TweenInfo.new(0.3), {Size = 0}):Play()
        tw.Completed:Connect(function()
            if not Mono.MenuOpen then 
                mainFrame.Visible = false 
                menuBlur.Enabled = false
            end
        end)
    end
end)

-- === ЧИСТЫЙ БЕЗОПАСНЫЙ КЛИКЕР ROBLOX ===
local function simulateClick()
    coroutine.wrap(function()
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local cx = Camera.ViewportSize.X / 2
            local cy = Camera.ViewportSize.Y / 2
            vim:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.01)
            vim:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        end)
    end)()
end

local function isEnemy(plr)
    if plr == LocalPlayer then return false end
    -- Вшитая проверка на тиму (TeamCheck всегда работает)
    if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then 
        return false 
    end
    return true
end

local function getBestTargetPart(char)
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
end

local function raycastFromCenter()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ray = Camera:ViewportPointToRay(center.X, center.Y)
    return workspace:Raycast(ray.Origin, ray.Direction * 2000, GlobalRayParams)
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
                    
                    if (not Mono.FOV.Enabled) or (dist <= Mono.FOV.Radius) then
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

Players.PlayerRemoving:Connect(function(plr)
    pcall(function()
        if espCache[plr] then
            if espCache[plr].Highlight then espCache[plr].Highlight:Destroy() end
            if espCache[plr].Billboard then espCache[plr].Billboard:Destroy() end
            if espCache[plr].Orbits then
                for _, orb in ipairs(espCache[plr].Orbits) do orb.gui:Destroy() end
            end
            if espCache[plr].Arrow then espCache[plr].Arrow:Destroy() end
            espCache[plr] = nil
        end
        DeadCache[plr] = nil
        PlayerData[plr] = nil
    end)
end)

-- === ESP, РАДАР И ЛОГИКА ===
local espCache = {}

local function updateESP()
    local t = tick()
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
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
            local targetPart = char.HumanoidRootPart
            local distToPlayer = (targetPart.Position - camPos).Magnitude
            local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            
            -- WALLHACK ESP
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
                    tl.Size = UDim2.new(1, 0, 1, 0)
                    tl.BackgroundTransparency = 1
                    tl.Font = Enum.Font.GothamBold
                    tl.TextSize = 12
                    tl.TextStrokeTransparency = 0
                    
                    espCache[plr].Highlight = hl
                    espCache[plr].Billboard = bb
                    espCache[plr].Text = tl
                    
                    hl.Parent = screenGui
                    bb.Parent = screenGui
                end
                
                espCache[plr].Highlight.Enabled = true
                espCache[plr].Billboard.Enabled = true
                
                if espCache[plr].Highlight.Adornee ~= char then 
                    espCache[plr].Highlight.Adornee = char 
                end
                
                if espCache[plr].Billboard.Adornee ~= targetPart then 
                    espCache[plr].Billboard.Adornee = targetPart 
                end
                
                espCache[plr].Text.Text = string.format("%s [%dm]", plr.Name, math.floor(distToPlayer))
                espCache[plr].Highlight.FillColor = Mono.ESPColor
                espCache[plr].Text.TextColor3 = Mono.ESPColor
            else
                if espCache[plr] and espCache[plr].Highlight then
                    espCache[plr].Highlight.Enabled = false
                    espCache[plr].Billboard.Enabled = false
                end
            end

            -- ORBITS
            if Mono.TargetObjEnabled and isEnem then
                if not espCache[plr] then espCache[plr] = {} end
                if not espCache[plr].Orbits then
                    espCache[plr].Orbits = {}
                    for i = 1, 3 do
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
                    if orb.gui.Adornee ~= targetPart then 
                        orb.gui.Adornee = targetPart 
                    end
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
            
            -- OFF-SCREEN ARROWS
            if Mono.OffScreenArrows.Enabled and isEnem and not onScreen and distToPlayer <= 500 then
                if not espCache[plr] then espCache[plr] = {} end
                if not espCache[plr].Arrow then
                    local arr = Instance.new("TextLabel")
                    arr.Text = "▲"
                    arr.Font = Enum.Font.GothamBlack
                    arr.TextSize = 22
                    arr.BackgroundTransparency = 1
                    arr.Size = UDim2.new(0, 20, 0, 20)
                    arr.AnchorPoint = Vector2.new(0.5, 0.5)
                    
                    local stroke = Instance.new("UIStroke", arr)
                    stroke.Color = Color3.fromRGB(0, 0, 0)
                    stroke.Thickness = 1.5
                    stroke.Transparency = 0.2
                    
                    arr.Parent = screenGui
                    espCache[plr].Arrow = arr
                end
                
                local arrow = espCache[plr].Arrow
                arrow.Visible = true
                arrow.TextColor3 = Mono.OffScreenArrows.Color
                
                local proj = Camera.CFrame:PointToObjectSpace(targetPart.Position)
                local angle = math.atan2(proj.X, -proj.Y)
                
                local rX = center.X + math.sin(angle) * Mono.OffScreenArrows.Radius
                local rY = center.Y - math.cos(angle) * Mono.OffScreenArrows.Radius
                
                arrow.Position = UDim2.new(0, rX, 0, rY)
                arrow.Rotation = math.deg(angle)
            else
                if pcall(function() return espCache[plr].Arrow end) and espCache[plr].Arrow then espCache[plr].Arrow.Visible = false end
            end
        else
            if espCache[plr] then
                if espCache[plr].Highlight then espCache[plr].Highlight.Enabled = false; espCache[plr].Billboard.Enabled = false end
                if espCache[plr].Orbits then for _, orb in ipairs(espCache[plr].Orbits) do orb.gui.Enabled = false end end
                if espCache[plr].Arrow then espCache[plr].Arrow.Visible = false end
            end
        end
    end
end

-- === ОСНОВНОЙ ЦИКЛ ===
local frames = 0
local lastUpdate = tick()

RunService:BindToRenderStep("MonoCore", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
    pcall(function()
        updateESP()
        
        frames = frames + 1
        if tick() - lastUpdate >= 1 then
            local fps = frames
            local ping = 0
            pcall(function() ping = math.floor(game:GetService("Stats").PerformanceStats.Ping:GetValue()) end)
            watermarkText.Text = "MONOGRAMMA v37 | FPS: " .. tostring(fps) .. " | Ping: " .. tostring(ping) .. "ms"
            frames = 0
            lastUpdate = tick()
        end
        
        -- ФУНКЦИЯ SPEEDS (РАБОТАЕТ ПОСТОЯННО)
        if Mono.Speed.Enabled then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.WalkSpeed = Mono.Speed.Value
                end
            end
        end
        
        if Mono.FOV.Enabled then
            fovFrame.Visible = true
            fovFrame.Size = UDim2.new(0, Mono.FOV.Radius * 2, 0, Mono.FOV.Radius * 2)
            fovStroke.Color = Mono.FOV.Color
        else
            fovFrame.Visible = false
        end
        
        if Mono.Crosshair.Enabled then
            crosshairFolder.Parent = screenGui
            local cx = Camera.ViewportSize.X / 2
            local cy = Camera.ViewportSize.Y / 2
            local s = Mono.Crosshair.Size
            local g = Mono.Crosshair.Gap
            local t = Mono.Crosshair.Thickness
            local col = Mono.Crosshair.Color
            
            chTop.Size = UDim2.new(0, t, 0, s); chTop.Position = UDim2.new(0, cx, 0, cy - g); chTop.BackgroundColor3 = col
            chBot.Size = UDim2.new(0, t, 0, s); chBot.Position = UDim2.new(0, cx, 0, cy + g); chBot.BackgroundColor3 = col
            chLeft.Size = UDim2.new(0, s, 0, t); chLeft.Position = UDim2.new(0, cx - g, 0, cy); chLeft.BackgroundColor3 = col
            chRight.Size = UDim2.new(0, s, 0, t); chRight.Position = UDim2.new(0, cx + g, 0, cy); chRight.BackgroundColor3 = col
            
            UserInputService.MouseIconEnabled = not Mono.Crosshair.HideDefault
        else
            crosshairFolder.Parent = nil
            UserInputService.MouseIconEnabled = true
        end
        
        if Mono.TimeOfDay == "Day ☀️" then Lighting.ClockTime = 14
        elseif Mono.TimeOfDay == "Night 🌙" then Lighting.ClockTime = 0 end

        if Mono.Aimbot.Enabled then
            local target = getClosestVisibleEnemy()
            if target then
                local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
                if Mono.Aimbot.Mode == "Legit 🎯" then
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Mono.Aimbot.Smoothness)
                else
                    Camera.CFrame = targetCFrame
                end
                local targetPlayer = getPlayerFromPart(target)
                if targetPlayer then
                    LastTargetHit = targetPlayer
                    LastTargetTime = tick()
                end
            end
        end

        if Mono.TriggerBot.Enabled then
            local hitResult = raycastFromCenter()
            if hitResult and hitResult.Instance then
                local targetPlayer = getPlayerFromPart(hitResult.Instance)
                if targetPlayer and isEnemy(targetPlayer) then
                    local char = targetPlayer.Character
                    local targetPart = char and getBestTargetPart(char)
                    if targetPart then
                        local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        
                        if onScreen and ((not Mono.FOV.Enabled) or (dist <= Mono.FOV.Radius)) then
                            LastTargetHit = targetPlayer
                            LastTargetTime = tick()
                            if tick() - LastShootTime > Mono.TriggerBot.Delay then
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
