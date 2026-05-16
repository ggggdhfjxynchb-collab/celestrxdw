local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

print("[DUCK SCANNER] Пытаюсь загрузить меню...")

-- === 1. ЖЕЛЕЗОБЕТОННАЯ ЗАГРУЗКА GUI ===
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
local targetParent = nil

-- Пробуем все варианты по очереди
pcall(function() targetParent = gethui() end)
if not targetParent then pcall(function() targetParent = game:GetService("CoreGui") end) end
if not targetParent then targetParent = PlayerGui end

print("[DUCK SCANNER] Меню загружается в: " .. tostring(targetParent))

-- Удаляем старое, если есть
pcall(function()
    for _, v in pairs(targetParent:GetChildren()) do
        if v.Name == "DuckMinigameScanner" then v:Destroy() end
    end
end)

-- === 2. СОЗДАНИЕ МЕНЮ ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DuckMinigameScanner"
screenGui.ResetOnSpawn = false -- ЧТОБЫ НЕ ПРОПАДАЛО ПРИ СМЕРТИ
screenGui.Parent = targetParent

local mainFrame = Instance.new("Frame")
mainFrame.Name = "ScannerFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Position = UDim2.new(0.5, -125, 0.4, 0) -- По центру экрана
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(0, 255, 150)
uiStroke.Thickness = 2
uiStroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "Duck Scanner (Нажми ']' чтобы скрыть)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.Parent = mainFrame

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0.9, 0, 0, 45)
scanBtn.Position = UDim2.new(0.05, 0, 0, 45)
scanBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scanBtn.Text = "СКАНИРОВАТЬ ПЛИТКИ"
scanBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 14
scanBtn.Parent = mainFrame
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.9, 0, 0, 30)
clearBtn.Position = UDim2.new(0.05, 0, 0, 105)
clearBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
clearBtn.Text = "Очистить подсветку"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Font = Enum.Font.Gotham
clearBtn.TextSize = 14
clearBtn.Parent = mainFrame
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 6)

-- === 3. ПЕРЕТАСКИВАНИЕ И СКРЫТИЕ ===
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

-- Скрыть/Показать на правую квадратную скобку "]"
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightBracket then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- === 4. ЛОГИКА РЕНТГЕНА ===
local activeHighlights = {}

local function clearHighlights()
    for _, hl in pairs(activeHighlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    activeHighlights = {}
end

local function applyHighlight(part, color)
    local hl = Instance.new("Highlight")
    hl.Parent = part
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0.1
    table.insert(activeHighlights, hl)
end

scanBtn.MouseButton1Click:Connect(function()
    clearHighlights()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then 
        scanBtn.Text = "ОШИБКА: ПЕРСОНАЖ НЕ НАЙДЕН"
        task.wait(2)
        scanBtn.Text = "СКАНИРОВАТЬ ПЛИТКИ"
        return 
    end

    local count = 0
    scanBtn.Text = "СКАНИРУЮ..."
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 0)
    task.wait(0.1) 
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            -- Игнорируем игроков
            if not obj.Parent:FindFirstChild("Humanoid") then
                local dist = (obj.Position - root.Position).Magnitude
                if dist <= 50 then 
                    
                    local isBomb = false
                    local isSafe = false
                    local hasHiddenData = false

                    -- Ищем в Атрибутах
                    local attrs = obj:GetAttributes()
                    for name, value in pairs(attrs) do
                        local lowerName = string.lower(name)
                        if string.find(lowerName, "bomb") or string.find(lowerName, "bad") or string.find(lowerName, "mine") then
                            isBomb = true; hasHiddenData = true
                        elseif string.find(lowerName, "safe") or string.find(lowerName, "good") then
                            isSafe = true; hasHiddenData = true
                        else
                            hasHiddenData = true
                        end
                    end

                    -- Ищем во Values
                    for _, child in pairs(obj:GetChildren()) do
                        if child:IsA("ValueBase") then
                            local lowerName = string.lower(child.Name)
                            if string.find(lowerName, "bomb") or string.find(lowerName, "bad") then
                                isBomb = true; hasHiddenData = true
                            elseif string.find(lowerName, "safe") or string.find(lowerName, "good") then
                                isSafe = true; hasHiddenData = true
                            else
                                hasHiddenData = true
                            end
                        end
                        -- Ищем скрытые картинки
                        if child:IsA("SurfaceGui") or child:IsA("BillboardGui") or child:IsA("Decal") then
                            if child:IsA("Decal") and child.Transparency == 1 then
                                hasHiddenData = true
                            end
                            for _, elem in pairs(child:GetDescendants()) do
                                if (elem:IsA("ImageLabel") or elem:IsA("ImageButton")) and not elem.Visible then
                                    hasHiddenData = true
                                end
                            end
                        end
                    end

                    -- КРАСИМ
                    if hasHiddenData then
                        if isBomb then
                            applyHighlight(obj, Color3.fromRGB(255, 0, 0)) -- Красный
                        elseif isSafe then
                            applyHighlight(obj, Color3.fromRGB(0, 255, 0)) -- Зеленый
                        else
                            applyHighlight(obj, Color3.fromRGB(0, 150, 255)) -- Синий
                        end
                        count = count + 1
                    end
                end
            end
        end
    end
    
    if count == 0 then
        scanBtn.Text = "СЕРВЕРНАЯ ИГРА (ДАННЫХ НЕТ)"
        scanBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    else
        scanBtn.Text = "НАЙДЕНО ДАННЫХ: " .. count
        scanBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
    end
    
    task.wait(3)
    scanBtn.Text = "СКАНИРОВАТЬ ПЛИТКИ"
    scanBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
end)

clearBtn.MouseButton1Click:Connect(clearHighlights)

print("[DUCK SCANNER] Успешно загружен! Если меню не видно, нажми ']'")
