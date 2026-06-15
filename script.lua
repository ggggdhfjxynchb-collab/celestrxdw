local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- === 1. БЕЗОПАСНЫЙ ИНТЕРФЕЙС ===
local targetParent = nil
pcall(function() targetParent = gethui and gethui() or CoreGui end)
if not targetParent then targetParent = LocalPlayer:WaitForChild("PlayerGui") end

pcall(function()
    if targetParent:FindFirstChild("ResellerCheat") then
        targetParent.ResellerCheat:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ResellerCheat"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = targetParent

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 130)
MainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Позволяет таскать менюшку
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = " 💸 AUTO RESELLER"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

-- === НАСТРОЙКИ ===
local Settings = {
    AutoBuy = false,
    AutoSell = false
}

-- === УНИВЕРСАЛЬНЫЙ КЛИКЕР UI ===
local function ClickUI(uiElement)
    pcall(function()
        -- Пытаемся использовать эксплойт-функции для точного клика
        if getconnections then
            for _, connection in pairs(getconnections(uiElement.MouseButton1Click)) do
                connection:Fire()
            end
        else
            -- Запасной вариант
            local absPos = uiElement.AbsolutePosition
            local absSize = uiElement.AbsoluteSize
            local center = Vector2.new(absPos.X + (absSize.X / 2), absPos.Y + (absSize.Y / 2) + 36)
            VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
        end
    end)
end

-- === УНИВЕРСАЛЬНЫЙ АКТИВАТОР PROXIMITY PROMPT ===
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

-- === ФУНКЦИЯ АВТО-ПОКУПКИ (ЛЕГЕНДАРКИ) ===
local function DoAutoBuy()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart

    -- 1. Ищем леги
    for _, obj in pairs(workspace:GetDescendants()) do
        if not Settings.AutoBuy then break end
        
        if obj:IsA("TextLabel") and obj.Parent and obj.Parent:IsA("BillboardGui") then
            -- Проверяем желтый текст или слово Legendary
            if string.match(string.lower(obj.Text), "legendary") or (obj.TextColor3.R > 0.8 and obj.TextColor3.G > 0.8 and obj.TextColor3.B < 0.2) then
                local itemRoot = obj.Parent.Parent
                if itemRoot and itemRoot:IsA("BasePart") then
                    local prompt = itemRoot:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and prompt.ActionText == "Взять" then
                        -- Телепортируемся к вещи
                        hrp.CFrame = itemRoot.CFrame * CFrame.new(0, 2, 0)
                        task.wait(0.2)
                        FirePrompt(prompt)
                        task.wait(0.5) -- Ждем пока вещь возьмется
                    end
                end
            end
        end
    end

    -- 2. Идем к кассе оплачивать
    if Settings.AutoBuy then
        for _, prompt in pairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Поговорить" or prompt.ObjectText == "Продавец") then
                if prompt.Parent and prompt.Parent:IsA("BasePart") then
                    hrp.CFrame = prompt.Parent.CFrame * CFrame.new(0, 3, 0)
                    task.wait(0.3)
                    FirePrompt(prompt)
                    task.wait(1) -- Ждем анимацию оплаты
                    break -- Оплатили, выходим из цикла
                end
            end
        end
    end
end

-- === ФУНКЦИЯ АВТО-ПРОДАЖИ (БАРЫГЕ) ===
local function DoAutoSell()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart

    -- 1. Ищем Барыгу
    local barygaFound = false
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name == "Барыга" or obj.Name == "Huckster") then
            local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
            if prompt then
                -- Телепортируемся к Барыге
                hrp.CFrame = obj:GetModelCFrame() * CFrame.new(0, 0, 3)
                task.wait(0.4)
                FirePrompt(prompt)
                barygaFound = true
                break
            end
        end
    end

    if not barygaFound then return end
    task.wait(1) -- Ждем открытия меню продажи

    -- 2. Авто-выбор всех вещей и продажа
    pcall(function()
        local pg = LocalPlayer:WaitForChild("PlayerGui")
        
        -- Кликаем на все предметы (ищем кнопки без текста, обычно это иконки вещей)
        for _, ui in pairs(pg:GetDescendants()) do
            if ui:IsA("TextButton") or ui:IsA("ImageButton") then
                -- Эвристика: если это квадратная кнопка внутри инвентаря барыги
                if ui.AbsoluteSize.X > 40 and ui.AbsoluteSize.X < 150 and ui.AbsoluteSize.Y > 40 and ui.AbsoluteSize.Y < 150 then
                    ClickUI(ui)
                    task.wait(0.05)
                end
            end
        end

        task.wait(0.5)

        -- Ищем и нажимаем кнопку "Предложить"
        for _, ui in pairs(pg:GetDescendants()) do
            if ui:IsA("TextLabel") or ui:IsA("TextButton") then
                if string.match(string.lower(ui.Text), "предложить") then
                    ClickUI(ui.Parent:IsA("TextButton") and ui.Parent or ui)
                    break
                end
            end
        end

        task.wait(0.5)

        -- Ищем и нажимаем кнопку "Продать" -> "Да"
        for _, ui in pairs(pg:GetDescendants()) do
            if ui:IsA("TextLabel") or ui:IsA("TextButton") then
                if string.match(string.lower(ui.Text), "продать") or string.match(string.lower(ui.Text), "да") then
                    ClickUI(ui.Parent:IsA("TextButton") and ui.Parent or ui)
                    task.wait(0.2)
                end
            end
        end
    end)
end

-- === СОЗДАНИЕ КНОПОК ===
local function CreateToggle(parent, text, yPos, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
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

CreateToggle(MainFrame, "Auto Buy Legendary", 40, function(state)
    Settings.AutoBuy = state
end)

CreateToggle(MainFrame, "Auto Sell (Барыга)", 80, function(state)
    Settings.AutoSell = state
end)

-- === ГЛАВНЫЙ ЦИКЛ ===
task.spawn(function()
    while true do
        if Settings.AutoBuy then
            pcall(DoAutoBuy)
        end
        task.wait(1) -- Проверяем магаз раз в секунду
    end
end)

task.spawn(function()
    while true do
        if Settings.AutoSell then
            pcall(DoAutoSell)
        end
        task.wait(5) -- Продаем раз в 5 секунд, чтобы не забаговать UI
    end
end)
