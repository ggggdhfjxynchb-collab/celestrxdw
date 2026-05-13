-- Duck Klient - GUI Script
-- Gotov k relizu!

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- === Check for existing GUI and destroy if present ===
local oldGui = CoreGui:FindFirstChild("DuckKlientGui")
if oldGui then
    oldGui:Destroy()
end

-- === Base Setup ===
local DuckKlientGui = Instance.new("ScreenGui")
DuckKlientGui.Name = "DuckKlientGui"
DuckKlientGui.Parent = CoreGui
DuckKlientGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- === Main Frame ===
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = DuckKlientGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Dark background
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -180) -- Centered
MainFrame.Size = UDim2.new(0, 500, 0, 360)
MainFrame.ClipsDescendants = true

-- Stylish Border Outline (Teal/Cyan)
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 150, 150)
UIStroke.Thickness = 2
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = MainFrame

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = MainFrame
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -25, 0, 5)
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 16
CloseButton.MouseButton1Click:Connect(function()
    DuckKlientGui:Destroy()
end)

-- === Header Section ===
-- Client Logo (Added and made visible as requested)
local LogoLabel = Instance.new("ImageLabel")
LogoLabel.Name = "LogoLabel"
LogoLabel.Parent = MainFrame
LogoLabel.BackgroundTransparency = 1
LogoLabel.Position = UDim2.new(0, 10, 0, 10)
LogoLabel.Size = UDim2.new(0, 30, 0, 30)
LogoLabel.Image = "rbxassetid://132764620616937" -- ID provided by user
LogoLabel.ScaleType = Enum.ScaleType.Fit

-- Client Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 50, 0, 10)
TitleLabel.Size = UDim2.new(0, 150, 0, 30)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "duck klient"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 20
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- === Sidebar Section ===
local TabPanel = Instance.new("Frame")
TabPanel.Name = "TabPanel"
TabPanel.Parent = MainFrame
TabPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TabPanel.BorderSizePixel = 0
TabPanel.Position = UDim2.new(0, 0, 0, 50)
TabPanel.Size = UDim2.new(0, 120, 1, -50)

-- Visuals Tab Button
local VisualsTabButton = Instance.new("TextButton")
VisualsTabButton.Name = "VisualsTabButton"
VisualsTabButton.Parent = TabPanel
VisualsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Darker for active tab
VisualsTabButton.BorderSizePixel = 0
VisualsTabButton.Position = UDim2.new(0, 0, 0, 0)
VisualsTabButton.Size = UDim2.new(1, 0, 0, 40)
VisualsTabButton.Font = Enum.Font.GothamMedium
VisualsTabButton.Text = "Visuals"
VisualsTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
VisualsTabButton.TextSize = 16

-- Car Mods Tab Button
local CarModsTabButton = Instance.new("TextButton")
CarModsTabButton.Name = "CarModsTabButton"
CarModsTabButton.Parent = TabPanel
CarModsTabButton.BackgroundTransparency = 1 -- Lighter for inactive tab
CarModsTabButton.BorderSizePixel = 0
CarModsTabButton.Position = UDim2.new(0, 0, 0, 40)
CarModsTabButton.Size = UDim2.new(1, 0, 0, 40)
CarModsTabButton.Font = Enum.Font.GothamMedium
CarModsTabButton.Text = "Car Mods"
CarModsTabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
CarModsTabButton.TextSize = 16

-- === Content Section ===
local ContentPanel = Instance.new("Frame")
ContentPanel.Name = "ContentPanel"
ContentPanel.Parent = MainFrame
ContentPanel.BackgroundTransparency = 1
ContentPanel.BorderSizePixel = 0
ContentPanel.Position = UDim2.new(0, 120, 0, 50)
ContentPanel.Size = UDim2.new(1, -120, 1, -50)

-- === VISUALS CONTENT ===
local VisualsContent = Instance.new("ScrollingFrame")
VisualsContent.Name = "VisualsContent"
VisualsContent.Parent = ContentPanel
VisualsContent.BackgroundTransparency = 1
VisualsContent.BorderSizePixel = 0
VisualsContent.Size = UDim2.new(1, 0, 1, 0)
VisualsContent.ScrollBarThickness = 2
VisualsContent.Active = true
VisualsContent.Visible = true -- Shown by default

-- UIListLayout for easy adding of functions
local UIListLayout_Visuals = Instance.new("UIListLayout")
UIListLayout_Visuals.Parent = VisualsContent
UIListLayout_Visuals.Padding = UDim.new(0, 10)
UIListLayout_Visuals.SortOrder = Enum.SortOrder.LayoutOrder

-- Template for function buttons
local function CreateFunctionButton(parent, name, description)
    local FunctionButtonFrame = Instance.new("Frame")
    FunctionButtonFrame.Name = name .. "Button"
    FunctionButtonFrame.Parent = parent
    FunctionButtonFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    FunctionButtonFrame.BorderSizePixel = 0
    FunctionButtonFrame.Size = UDim2.new(1, -10, 0, 45) -- Match image style
    FunctionButtonFrame.LayoutOrder = parent:GetChildren() and #parent:GetChildren() or 0

    local FunctionUIStroke = UIStroke:Clone()
    FunctionUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    FunctionUIStroke.Color = Color3.fromRGB(35, 35, 35)
    FunctionUIStroke.Parent = FunctionButtonFrame

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Parent = FunctionButtonFrame
    ToggleButton.BackgroundTransparency = 1
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Position = UDim2.new(0, 5, 0, 5)
    ToggleButton.Size = UDim2.new(1, -10, 1, -10)
    ToggleButton.Font = Enum.Font.GothamMedium
    ToggleButton.Text = name
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 14
    ToggleButton.TextXAlignment = Enum.TextXAlignment.Left

    local DescriptionLabel = Instance.new("TextLabel")
    DescriptionLabel.Parent = FunctionButtonFrame
    DescriptionLabel.BackgroundTransparency = 1
    DescriptionLabel.BorderSizePixel = 0
    DescriptionLabel.Position = UDim2.new(0, 5, 0.6, 0)
    DescriptionLabel.Size = UDim2.new(1, -10, 0.4, 0)
    DescriptionLabel.Font = Enum.Font.Gotham
    DescriptionLabel.Text = description
    DescriptionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    DescriptionLabel.TextSize = 10
    DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescriptionLabel.TextYAlignment = Enum.TextYAlignment.Top

    -- Toggle Logic with color change
    local IsActive = false
    ToggleButton.MouseButton1Click:Connect(function()
        IsActive = not IsActive
        if IsActive then
            FunctionButtonFrame.BackgroundColor3 = Color3.fromRGB(0, 60, 60)
            FunctionUIStroke.Color = Color3.fromRGB(0, 150, 150)
            -- Add logic to activate the function here
        else
            FunctionButtonFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            FunctionUIStroke.Color = Color3.fromRGB(35, 35, 35)
            -- Add logic to deactivate the function here
        end
    end)
end

-- Populate Visuals content based on image_0.png
CreateFunctionButton(VisualsContent, "Weak Spot ESP", "Вычисляет идеальное место для тарана")
CreateFunctionButton(VisualsContent, "Car Box ESP", "Рисует 2D боксы на машинах")
CreateFunctionButton(VisualsContent, "Tracers", "Рисует линии до уязвимых точек")
CreateFunctionButton(VisualsContent, "Hit Particles", "ЛКМ: Вкл | ПКМ: Настройки")
-- CreateFunctionButton(VisualsContent, "Hit Sounds", "ЛКМ: Звук при ударе | ПКМ: Выбрать") -- ID звуков сломаны в оригинале
CreateFunctionButton(VisualsContent, "Custom Skybox", "ЛКМ: Изменить небо | ПКМ: Выбрать")

-- === CAR MODS CONTENT ===
-- This frame is completely empty, as requested to remove the single function.
local CarModsContent = Instance.new("ScrollingFrame")
CarModsContent.Name = "CarModsContent"
CarModsContent.Parent = ContentPanel
CarModsContent.BackgroundTransparency = 1
CarModsContent.BorderSizePixel = 0
CarModsContent.Size = UDim2.new(1, 0, 1, 0)
CarModsContent.ScrollBarThickness = 2
CarModsContent.Active = true
CarModsContent.Visible = false -- Hidden by default

-- UIListLayout for Car Mods
local UIListLayout_CarMods = Instance.new("UIListLayout")
UIListLayout_CarMods.Parent = CarModsContent
UIListLayout_CarMods.Padding = UDim.new(0, 10)
UIListLayout_CarMods.SortOrder = Enum.SortOrder.LayoutOrder

-- === Tab Switching Logic ===
local function SwitchTab(activeTabName)
    if activeTabName == "Visuals" then
        -- Update button appearance
        VisualsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        VisualsTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        CarModsTabButton.BackgroundTransparency = 1
        CarModsTabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        -- Update content visibility
        VisualsContent.Visible = true
        CarModsContent.Visible = false
    elseif activeTabName == "Car Mods" then
        -- Update button appearance
        VisualsTabButton.BackgroundTransparency = 1
        VisualsTabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        CarModsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        CarModsTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        -- Update content visibility
        VisualsContent.Visible = false
        CarModsContent.Visible = true
    end
end

VisualsTabButton.MouseButton1Click:Connect(function() SwitchTab("Visuals") end)
CarModsTabButton.MouseButton1Click:Connect(function() SwitchTab("Car Mods") end)

-- === Add Dragging Logic ===
local Dragging = false
local DragInput
local DragStart
local StartPosition

local function Update(input)
    local Delta = input.Position - DragStart
    MainFrame.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPosition = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        DragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == DragInput and Dragging then
        Update(input)
    end
end)

-- Send notification that it is ready for release
StarterGui:SetCore("SendNotification", {
    Title = "Reliz!",
    Text = "Duck Klient gotov k relizu. Nasladaisya!",
    Duration = 5
})
