local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- === 1. ОЧИСТКА СТАРОГО ===
local targetParent = nil
pcall(function() targetParent = gethui and gethui() or CoreGui end)
if not targetParent then targetParent = LocalPlayer:WaitForChild("PlayerGui") end

pcall(function()
    if targetParent:FindFirstChild("ResellerPro") then
        targetParent.ResellerPro:Destroy()
    end
end)

-- === 2. НАСТРОЙКИ ФАРМА ===
local Settings = {
    AutoBuy = false,
    AutoSell = false
}
local Waypoints = {}
local waypointCounter = 0
local BindWait = nil

-- === 3. СОЗДАНИЕ ИНТЕРФЕЙСА ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ResellerPro"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = targetParent

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(255, 215, 0)
Stroke.Thickness = 1.5

-- Перетаскивание
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = MainFrame.Position end
end)
MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Шапка
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = " 💸 RESELLER PRO"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

-- === ФУНКЦИИ КНОПОК МЕНЮ ===
local function CreateToggle(yPos, text, callback)
    local frame = Instance.new("Frame", MainFrame)
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local status = Instance.new("Frame", frame)
    status.Size = UDim2.new(0, 14, 0, 14)
    status.Position = UDim2.new(1, -25, 0.5, -7)
    status.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        status.BackgroundColor3 = state and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(60, 60, 70)
        btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        callback(state)
    end)
end

CreateToggle(45, "Auto Buy Legendary", function(s) Settings.AutoBuy = s end)
CreateToggle(85, "Auto Sell to Baryga", function(s) Settings.AutoSell = s end)

-- Разделитель
local Line = Instance.new("Frame", MainFrame)
Line.Size = UDim2.new(1, 0, 0, 1)
Line.Position = UDim2.new(0, 0, 0, 130)
Line.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
Line.BackgroundTransparency = 0.5
Line.BorderSizePixel = 0

local TPTitle = Instance.new("TextLabel", MainFrame)
TPTitle.Size = UDim2.new(1, -50, 0, 30)
TPTitle.Position = UDim2.new(0, 10, 0, 135)
TPTitle.BackgroundTransparency = 1
TPTitle.Text = "CUSTOM TELEPORTS"
TPTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TPTitle.Font = Enum.Font.GothamBold
TPTitle.TextSize = 12
TPTitle.TextXAlignment = Enum.TextXAlignment.Left

local AddBtn = Instance.new("TextButton", MainFrame)
AddBtn.Size = UDim2.new(0, 30, 0, 30)
AddBtn.Position = UDim2.new(1, -40, 0, 135)
AddBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 100)
AddBtn.Text = "+"
AddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AddBtn.Font = Enum.Font.GothamBlack
AddBtn.TextSize = 20
Instance.new("UICorner", AddBtn).CornerRadius = UDim.new(0, 6)

local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, -20, 1, -175)
ScrollFrame.Position = UDim2.new(0, 10, 0, 170)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 2
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIListLayout = Instance.new("UIListLayout", ScrollFrame)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

-- === 4. УТИЛИТЫ ДЛЯ ВЗАИМОДЕЙСТВИЯ ===

-- Физический клик по интерфейсу игры
local function ClickUI(uiElement)
    pcall(function()
        if getconnections then
            for _, conn in pairs(getconnections(uiElement.MouseButton1Click)) do conn:Fire() end
        else
            local absPos = uiElement.AbsolutePosition
            local absSize = uiElement.AbsoluteSize
            local cx = absPos.X + (absSize.X / 2)
            local cy = absPos.Y + (absSize.Y / 2) + 36
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
        end
    end)
end

-- Активация E (ProximityPrompt)
local function FirePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(prompt, 1, true)
            else
                prompt.HoldDuration = 0
                prompt:InputHoldBegin()
                task.wait(0.1)
                prompt:InputHoldEnd()
            end
        end)
    end
end

-- === 5. ЛОГИКА АВТО-ФАРМА ===

-- АВТО ПОКУПКА
task.spawn(function()
    while task.wait(0.5) do
        if not Settings.AutoBuy then continue end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- 1. ИЩЕМ ЛЕГУ И ТЭПАЕМСЯ К НЕЙ
        local itemTaken = false
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Parent and obj.Parent:IsA("BillboardGui") then
                if string.match(string.lower(obj.Text), "legendary") or (obj.TextColor3.R > 0.8 and obj.TextColor3.G > 0.8 and obj.TextColor3.B < 0.2) then
                    local itemRoot = obj.Parent.Parent
                    if itemRoot and itemRoot:IsA("BasePart") then
                        local prompt = itemRoot:FindFirstChildOfClass("ProximityPrompt")
                        if prompt and prompt.ActionText == "Взять" then
                            -- Тэпаемся к шмотке
                            hrp.CFrame = itemRoot.CFrame * CFrame.new(0, 2, 0)
                            task.wait(0.3)
                            FirePrompt(prompt)
                            task.wait(0.5)
                            itemTaken = true
                            break
                        end
                    end
                end
            end
        end

        -- 2. ТЭПАЕМСЯ К КАССЕ ОПЛАЧИВАТЬ
        if itemTaken and Settings.AutoBuy then
            for _, prompt in pairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Поговорить" or prompt.ObjectText == "Продавец") then
                    if prompt.Parent and prompt.Parent:IsA("BasePart") then
                        hrp.CFrame = prompt.Parent.CFrame * CFrame.new(0, 3, 0)
                        task.wait(0.3)
                        FirePrompt(prompt)
                        task.wait(1)
                        break
                    end
                end
            end
        end
    end
end)

-- АВТО ПРОДАЖА БАРЫГЕ
task.spawn(function()
    while task.wait(2) do
        if not Settings.AutoSell then continue end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- 1. ТЭПАЕМСЯ К БАРЫГЕ
        local barygaFound = false
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name == "Барыга" or string.match(string.lower(obj.Name), "huckster")) then
                local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
                if prompt then
                    hrp.CFrame = obj:GetModelCFrame() * CFrame.new(0, 0, 3)
                    task.wait(0.5)
                    FirePrompt(prompt)
                    barygaFound = true
                    break
                end
            end
        end

        if not barygaFound then continue end
        task.wait(1) -- Ждем пока откроется кастомное меню продажи

        -- 2. КЛИКАЕМ В МЕНЮШКЕ
        pcall(function()
            local pg = LocalPlayer:WaitForChild("PlayerGui")
            
            -- Выбираем все предметы (кликаем по иконкам)
            for _, ui in pairs(pg:GetDescendants()) do
                if (ui:IsA("TextButton") or ui:IsA("ImageButton")) and ui.AbsoluteSize.X > 40 and ui.AbsoluteSize.Y > 40 then
                    ClickUI(ui)
                    task.wait(0.05)
                end
            end
            task.wait(0.5)

            -- Нажимаем "Предложить"
            for _, ui in pairs(pg:GetDescendants()) do
                if ui:IsA("TextLabel") or ui:IsA("TextButton") then
                    if string.match(string.lower(ui.Text), "предложить") then
                        ClickUI(ui.Parent:IsA("TextButton") and ui.Parent or ui)
                        break
                    end
                end
            end
            task.wait(0.5)

            -- Нажимаем "Да" / "Продать"
            for _, ui in pairs(pg:GetDescendants()) do
                if ui:IsA("TextLabel") or ui:IsA("TextButton") then
                    if string.match(string.lower(ui.Text), "да") or string.match(string.lower(ui.Text), "продать") then
                        ClickUI(ui.Parent:IsA("TextButton") and ui.Parent or ui)
                        task.wait(0.2)
                    end
                end
            end
        end)
    end
end)

-- === 6. ЛОГИКА ТЕЛЕПОРТОВ (МЕТКИ) ===
local function CreateWaypointUI(id, cframeData)
    local frame = Instance.new("Frame", ScrollFrame)
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local nameLabel = Instance.new("TextLabel", frame)
    nameLabel.Size = UDim2.new(0, 90, 1, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "TP Point " .. tostring(id)
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local bindBtn = Instance.new("TextButton", frame)
    bindBtn.Size = UDim2.new(0, 60, 0, 24)
    bindBtn.Position = UDim2.new(1, -140, 0.5, -12)
    bindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bindBtn.Text = "Bind"
    bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bindBtn.Font = Enum.Font.Gotham
    bindBtn.TextSize = 11
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)

    local tpBtn = Instance.new("TextButton", frame)
    tpBtn.Size = UDim2.new(0, 40, 0, 24)
    tpBtn.Position = UDim2.new(1, -75, 0.5, -12)
    tpBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    tpBtn.Text = "TP"
    tpBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 11
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)

    local delBtn = Instance.new("TextButton", frame)
    delBtn.Size = UDim2.new(0, 24, 0, 24)
    delBtn.Position = UDim2.new(1, -30, 0.5, -12)
    delBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    delBtn.Text = "X"
    delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    delBtn.Font = Enum.Font.GothamBold
    delBtn.TextSize = 11
    Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)

    bindBtn.MouseButton1Click:Connect(function()
        if BindWait then return end
        bindBtn.Text = "..."
        BindWait = function(key)
            Waypoints[id].Key = key
            local kName = key.Name
            if key == Enum.UserInputType.MouseButton1 then kName = "LMB"
            elseif key == Enum.UserInputType.MouseButton2 then kName = "RMB"
            elseif key == Enum.KeyCode.Unknown then kName = "None" end
            bindBtn.Text = kName
            BindWait = nil
        end
    end)

    tpBtn.MouseButton1Click:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = Waypoints[id].CFrame
        end
    end)

    delBtn.MouseButton1Click:Connect(function()
        Waypoints[id] = nil
        frame:Destroy()
    end)
end

AddBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        waypointCounter = waypointCounter + 1
        local currentCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        Waypoints[waypointCounter] = { CFrame = currentCFrame, Key = Enum.KeyCode.Unknown }
        CreateWaypointUI(waypointCounter, currentCFrame)
    end
end)

-- Слушатель нажатий (ТП по биндам)
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

    if Waypoints and key ~= Enum.KeyCode.Unknown then
        for id, data in pairs(Waypoints) do
            if data.Key == key then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = data.CFrame
                end
            end
        end
    end
end)
