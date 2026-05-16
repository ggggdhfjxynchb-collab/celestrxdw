local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- === БЕЗОПАСНАЯ ОЧИСТКА ===
local targetParent = nil
pcall(function() targetParent = gethui() end)
if not targetParent then pcall(function() targetParent = CoreGui end) end
if not targetParent then targetParent = LocalPlayer:WaitForChild("PlayerGui") end

pcall(function()
    local oldGui = targetParent:FindFirstChild("DuckXRay")
    if oldGui then oldGui:Destroy() end
end)

-- === СОЗДАНИЕ GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DuckXRay"
screenGui.ResetOnSpawn = false
screenGui.Parent = targetParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 120)
mainFrame.Position = UDim2.new(0.5, -100, 0.8, -60)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(0, 255, 150)
uiStroke.Thickness = 2
uiStroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Duck X-Ray"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = mainFrame

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0.9, 0, 0, 40)
scanBtn.Position = UDim2.new(0.05, 0, 0, 40)
scanBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scanBtn.Text = "SCAN BOARD (X-Ray)"
scanBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
scanBtn.Font = Enum.Font.GothamBlack
scanBtn.TextSize = 14
scanBtn.Parent = mainFrame
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.9, 0, 0, 25)
clearBtn.Position = UDim2.new(0.05, 0, 0, 85)
clearBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
clearBtn.Text = "Clear ESP"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Font = Enum.Font.Gotham
clearBtn.TextSize = 12
clearBtn.Parent = mainFrame
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 6)

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

-- === ЛОГИКА РЕНТГЕНА ===
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
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    table.insert(activeHighlights, hl)
end

scanBtn.MouseButton1Click:Connect(function()
    clearHighlights()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local radius = 30 -- Ищем детали стола в радиусе 30 стадов
    local count = 0

    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Проверяем, близко ли деталь
            if (part.Position - root.Position).Magnitude <= radius then
                -- Фильтруем: нам нужны только квадратные плитки стола (игнорим пол, стены и игроков)
                if part.Size.Y < 2 and part.Size.X > 0.5 and part.Size.Z > 0.5 and not part.Parent:FindFirstChild("Humanoid") then
                    
                    local isBomb = false
                    local isSafe = false
                    local hasData = false

                    -- ШАГ 1: Сканируем Атрибуты
                    local attributes = part:GetAttributes()
                    for name, value in pairs(attributes) do
                        local lowName = string.lower(name)
                        if string.find(lowName, "bomb") or string.find(lowName, "bad") or string.find(lowName, "mine") then
                            isBomb = (value == true or value == 1)
                            hasData = true
                        elseif string.find(lowName, "safe") or string.find(lowName, "good") or string.find(lowName, "reward") then
                            isSafe = (value == true or value == 1)
                            hasData = true
                        end
                    end

                    -- ШАГ 2: Сканируем вложенные Value (BoolValue, IntValue, StringValue)
                    for _, child in pairs(part:GetChildren()) do
                        if child:IsA("ValueBase") then
                            local lowName = string.lower(child.Name)
                            if string.find(lowName, "bomb") or string.find(lowName, "bad") or string.find(lowName, "mine") then
                                isBomb = (child.Value == true or child.Value == 1 or child.Value == "true")
                                hasData = true
                            elseif string.find(lowName, "safe") or string.find(lowName, "good") then
                                isSafe = (child.Value == true or child.Value == 1)
                                hasData = true
                            end
                        end
                        -- ШАГ 3: Сканируем картинки (Decal / SurfaceGui)
                        if child:IsA("SurfaceGui") or child:IsA("Decal") then
                            for _, uiElement in pairs(child:GetDescendants()) do
                                if uiElement:IsA("ImageLabel") or uiElement:IsA("Decal") then
                                    local tex = uiElement.Image or uiElement.Texture
                                    -- Если есть картинка бомбы, но она скрыта
                                    if tex and tex ~= "" and uiElement.Visible == false then
                                        -- Помечаем как подозрительную (вероятно бомба)
                                        isBomb = true
                                        hasData = true
                                    end
                                end
                            end
                        end
                    end

                    -- КРАСИМ ПЛИТКИ
                    -- Если нашли инфу: Зеленый = безопасно, Красный = бомба
                    if hasData then
                        if isBomb then
                            applyHighlight(part, Color3.fromRGB(255, 0, 0)) -- КРАСНЫЙ (БОМБА)
                        else
                            applyHighlight(part, Color3.fromRGB(0, 255, 0)) -- ЗЕЛЕНЫЙ (СЕЙФ)
                        end
                        count = count + 1
                    else
                        -- Если это деталь стола, но инфы в ней НЕТ вообще
                        -- Красим в желтый (означает, что данные лежат на сервере)
                        -- Раскомментируй строку ниже, если хочешь видеть желтые плитки
                        -- applyHighlight(part, Color3.fromRGB(255, 255, 0)) 
                    end
                end
            end
        end
    end
    
    if count == 0 then
        scanBtn.Text = "DATA HIDDEN ON SERVER"
        scanBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.wait(2)
        scanBtn.Text = "SCAN BOARD (X-Ray)"
        scanBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
    else
        scanBtn.Text = "FOUND " .. count .. " TILES!"
        task.wait(2)
        scanBtn.Text = "SCAN BOARD (X-Ray)"
    end
end)

clearBtn.MouseButton1Click:Connect(clearHighlights)
