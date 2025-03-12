local SleekUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Utility Functions
local Utility = {}

function Utility:Create(instanceType, properties, children)
    local instance = Instance.new(instanceType)
    
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    
    return instance
end

function Utility:Tween(instance, properties, duration, style, direction)
    style = style or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out
    
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration, style, direction),
        properties
    )
    
    tween:Play()
    return tween
end

function Utility:Ripple(parent, startPos)
    local ripple = Utility:Create("Frame", {
        Name = "Ripple",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7,
        Position = UDim2.fromOffset(startPos.X - parent.AbsolutePosition.X, startPos.Y - parent.AbsolutePosition.Y),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 10,
        Parent = parent
    })
    
    local corner = Utility:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = ripple
    })
    
    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    
    Utility:Tween(ripple, {
        Size = UDim2.fromOffset(maxSize, maxSize),
        BackgroundTransparency = 1
    }, 0.5)
    
    task.spawn(function()
        task.wait(0.5)
        ripple:Destroy()
    end)
end

function Utility:DarkenColor(color, percent)
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, v * (1 - percent))
end

function Utility:LightenColor(color, percent)
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, v + (1 - v) * percent)
end

function Utility:GetTextBounds(text, font, size)
    return TextService:GetTextSize(text, size, font, Vector2.new(math.huge, math.huge))
end

function Utility:MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    
    handle = handle or frame
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Theme
local DefaultTheme = {
    Primary = Color3.fromRGB(30, 30, 45),
    Secondary = Color3.fromRGB(45, 45, 60),
    Accent = Color3.fromRGB(100, 120, 255),
    Text = Color3.fromRGB(240, 240, 255),
    DarkText = Color3.fromRGB(180, 180, 200),
    Placeholder = Color3.fromRGB(120, 120, 140),
    
    ElementBackground = Color3.fromRGB(40, 40, 55),
    ElementBackgroundHover = Color3.fromRGB(50, 50, 65),
    
    Success = Color3.fromRGB(70, 200, 120),
    Warning = Color3.fromRGB(255, 180, 70),
    Error = Color3.fromRGB(255, 70, 70),
    
    ToggleOn = Color3.fromRGB(100, 120, 255),
    ToggleOff = Color3.fromRGB(80, 80, 100),
    
    SliderBackground = Color3.fromRGB(60, 60, 75),
    SliderFill = Color3.fromRGB(100, 120, 255),
    
    DropdownOption = Color3.fromRGB(50, 50, 65),
    DropdownOptionHover = Color3.fromRGB(60, 60, 75),
    
    InputBackground = Color3.fromRGB(50, 50, 65),
    InputBackgroundFocused = Color3.fromRGB(60, 60, 75),
    
    NotificationBackground = Color3.fromRGB(40, 40, 55),
    NotificationAccent = Color3.fromRGB(100, 120, 255)
}

-- Main Library
function SleekUI:CreateWindow(config)
    config = config or {}
    local window = {}
    
    -- Default configuration
    local windowConfig = {
        Title = config.Title or "SleekUI",
        Size = config.Size or UDim2.new(0, 550, 0, 400),
        Position = config.Position or UDim2.new(0.5, -275, 0.5, -200),
        Theme = config.Theme or DefaultTheme,
        Blur = config.Blur ~= nil and config.Blur or true,
        BlurStrength = config.BlurStrength or 10,
        BackgroundTransparency = config.BackgroundTransparency or 0.2,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        ConfigurationSaving = config.ConfigurationSaving or {
            Enabled = false,
            FolderName = "SleekUI",
            FileName = "config"
        }
    }
    
    -- Create ScreenGui
    local sleekUI = Utility:Create("ScreenGui", {
        Name = "SleekUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    
    -- Handle protection
    if syn and syn.protect_gui then
        syn.protect_gui(sleekUI)
        sleekUI.Parent = CoreGui
    elseif gethui then
        sleekUI.Parent = gethui()
    else
        sleekUI.Parent = CoreGui
    end
    
    -- Main Frame
    local mainFrame = Utility:Create("Frame", {
        Name = "MainFrame",
        Size = windowConfig.Size,
        Position = windowConfig.Position,
        BackgroundColor3 = windowConfig.Theme.Primary,
        BackgroundTransparency = windowConfig.BackgroundTransparency,
        BorderSizePixel = 0,
        Parent = sleekUI
    })
    
    -- Blur Effect
    if windowConfig.Blur then
        local blurEffect = Utility:Create("BlurEffect", {
            Name = "SleekBlur",
            Size = windowConfig.BlurStrength,
            Parent = mainFrame
        })
    end
    
    -- Corner Radius
    local corner = Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = mainFrame
    })
    
    -- Shadow
    local shadow = Utility:Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 30, 1, 30),
        ZIndex = -1,
        Image = "rbxassetid://6014054955",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(128, 128, 128, 128),
        SliceScale = 1,
        Parent = mainFrame
    })
    
    -- Topbar
    local topbar = Utility:Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = windowConfig.Theme.Secondary,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Parent = mainFrame
    })
    
    -- Topbar Corner
    local topbarCorner = Utility:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = topbar
    })
    
    -- Corner Fix
    local cornerFix = Utility:Create("Frame", {
        Name = "CornerFix",
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = windowConfig.Theme.Secondary,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = topbar
    })
    
    -- Title
    local title = Utility:Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = windowConfig.Title,
        TextColor3 = windowConfig.Theme.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topbar
    })
    
    -- Close Button
    local closeButton = Utility:Create("ImageButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -32, 0, 8),
        BackgroundTransparency = 1,
        Image = "rbxassetid://10734898835",
        ImageColor3 = windowConfig.Theme.Text,
        ImageTransparency = 0.2,
        Parent = topbar
    })
    
    closeButton.MouseEnter:Connect(function()
        Utility:Tween(closeButton, {ImageColor3 = windowConfig.Theme.Error, ImageTransparency = 0}, 0.3)
    end)
    
    closeButton.MouseLeave:Connect(function()
        Utility:Tween(closeButton, {ImageColor3 = windowConfig.Theme.Text, ImageTransparency = 0.2}, 0.3)
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        Utility:Tween(mainFrame, {Size = UDim2.new(0, windowConfig.Size.X.Offset, 0, 0), Position = UDim2.new(windowConfig.Position.X.Scale, windowConfig.Position.X.Offset, windowConfig.Position.Y.Scale, windowConfig.Position.Y.Offset + windowConfig.Size.Y.Offset/2)}, 0.5)
        task.wait(0.5)
        sleekUI:Destroy()
    end)
    
    -- Minimize Button
    local minimizeButton = Utility:Create("ImageButton", {
        Name = "MinimizeButton",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -64, 0, 8),
        BackgroundTransparency = 1,
        Image = "rbxassetid://10734950020",
        ImageColor3 = windowConfig.Theme.Text,
        ImageTransparency = 0.2,
        Parent = topbar
    })
    
    minimizeButton.MouseEnter:Connect(function()
        Utility:Tween(minimizeButton, {ImageColor3 = windowConfig.Theme.Accent, ImageTransparency = 0}, 0.3)
    end)
    
    minimizeButton.MouseLeave:Connect(function()
        Utility:Tween(minimizeButton, {ImageColor3 = windowConfig.Theme.Text, ImageTransparency = 0.2}, 0.3)
    end)
    
    local minimized = false
    minimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Utility:Tween(mainFrame, {Size = UDim2.new(0, windowConfig.Size.X.Offset, 0, 40)}, 0.5)
        else
            Utility:Tween(mainFrame, {Size = windowConfig.Size}, 0.5)
        end
    end)
    
    -- Make window draggable
    Utility:MakeDraggable(mainFrame, topbar)
    
    -- Container
    local container = Utility:Create("Frame", {
        Name = "Container",
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = mainFrame
    })
    
    -- Tab Container
    local tabContainer = Utility:Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(0, 140, 1, 0),
        BackgroundColor3 = windowConfig.Theme.Secondary,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = container
    })
    
    -- Tab List
    local tabList = Utility:Create("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = windowConfig.Theme.Accent,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = tabContainer
    })
    
    -- Tab List Layout
    local tabListLayout = Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabList
    })
    
    -- Tab List Padding
    local tabListPadding = Utility:Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = tabList
    })
    
    -- Content Container
    local contentContainer = Utility:Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -140, 1, 0),
        Position = UDim2.new(0, 140, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = container
    })
    
    -- Tab Content
    local tabContent = Utility:Create("Folder", {
        Name = "TabContent",
        Parent = contentContainer
    })
    
    -- Notification Container
    local notificationContainer = Utility:Create("Frame", {
        Name = "NotificationContainer",
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, 10, 0, 0),
        BackgroundTransparency = 1,
        Parent = sleekUI
    })
    
    -- Notification List
    local notificationList = Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Parent = notificationContainer
    })
    
    -- Tab System
    local tabs = {}
    local selectedTab = nil
    
    -- Window Methods
    function window:CreateTab(name, icon)
        local tab = {}
        
        -- Tab Button
        local tabButton = Utility:Create("Frame", {
            Name = name .. "Button",
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = windowConfig.Theme.ElementBackground,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Parent = tabList
        })
        
        -- Tab Button Corner
        local tabButtonCorner = Utility:Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = tabButton
        })
        
        -- Tab Icon
        local tabIcon = Utility:Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 10, 0.5, -10),
            BackgroundTransparency = 1,
            Image = icon and ("rbxassetid://" .. icon) or "",
            ImageColor3 = windowConfig.Theme.Text,
            ImageTransparency = 0.2,
            Visible = icon ~= nil,
            Parent = tabButton
        })
        
        -- Tab Title
        local tabTitle = Utility:Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, icon and -40 or -20, 1, 0),
            Position = UDim2.new(0, icon and 40 or 10, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = windowConfig.Theme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tabButton
        })
        
        -- Tab Content Frame
        local tabFrame = Utility:Create("ScrollingFrame", {
            Name = name .. "Frame",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = windowConfig.Theme.Accent,
            ScrollBarImageTransparency = 0.5,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            Parent = tabContent
        })
        
        -- Tab Content Layout
        local tabContentLayout = Utility:Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tabFrame
        })
        
        -- Tab Content Padding
        local tabContentPadding = Utility:Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingBottom = UDim.new(0, 10),
            Parent = tabFrame
        })
        
        -- Auto-size canvas
        tabContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, tabContentLayout.AbsoluteContentSize.Y + 20)
        end)
        
        -- Tab Selection
        tabButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                window:SelectTab(name)
            end
        end)
        
        -- Tab Methods
        function tab:CreateSection(sectionName)
            local section = {}
            
            -- Section Frame
            local sectionFrame = Utility:Create("Frame", {
                Name = sectionName .. "Section",
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Parent = tabFrame
            })
            
            -- Section Title
            local sectionTitle = Utility:Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Text = sectionName,
                TextColor3 = windowConfig.Theme.Accent,
                TextSize = 16,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = sectionFrame
            })
            
            -- Section Divider
            local sectionDivider = Utility:Create("Frame", {
                Name = "Divider",
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 0, 30),
                BackgroundColor3 = windowConfig.Theme.Accent,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Parent = sectionFrame
            })
            
            return section
        end
        
        function tab:CreateButton(config)
            config = config or {}
            local buttonConfig = {
                Name = config.Name or "Button",
                Callback = config.Callback or function() end
            }
            
            -- Button Frame
            local buttonFrame = Utility:Create("Frame", {
                Name = buttonConfig.Name .. "Button",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = windowConfig.Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Parent = tabFrame
            })
            
            -- Button Corner
            local buttonCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = buttonFrame
            })
            
            -- Button Title
            local buttonTitle = Utility:Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = buttonConfig.Name,
                TextColor3 = windowConfig.Theme.Text,
                TextSize = 14,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = buttonFrame
            })
            
            -- Button Interaction
            local buttonInteraction = Utility:Create("TextButton", {
                Name = "Interaction",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = buttonFrame
            })
            
            -- Button Hover & Click Effects
            buttonInteraction.MouseEnter:Connect(function()
                Utility:Tween(buttonFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackgroundHover}, 0.3)
            end)
            
            buttonInteraction.MouseLeave:Connect(function()
                Utility:Tween(buttonFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackground}, 0.3)
            end)
            
            buttonInteraction.MouseButton1Down:Connect(function()
                Utility:Tween(buttonFrame, {BackgroundColor3 = Utility:DarkenColor(windowConfig.Theme.ElementBackgroundHover, 0.1)}, 0.1)
                Utility:Ripple(buttonFrame, Mouse.X, Mouse.Y)
            end)
            
            buttonInteraction.MouseButton1Up:Connect(function()
                Utility:Tween(buttonFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackgroundHover}, 0.1)
            end)
            
            buttonInteraction.MouseButton1Click:Connect(function()
                task.spawn(buttonConfig.Callback)
            end)
            
            local button = {}
            
            function button:SetText(text)
                buttonTitle.Text = text
            end
            
            return button
        end
        
        function tab:CreateToggle(config)
            config = config or {}
            local toggleConfig = {
                Name = config.Name or "Toggle",
                Default = config.Default or false,
                Callback = config.Callback or function() end
            }
            
            -- Toggle Frame
            local toggleFrame = Utility:Create("Frame", {
                Name = toggleConfig.Name .. "Toggle",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = windowConfig.Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Parent = tabFrame
            })
            
            -- Toggle Corner
            local toggleCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = toggleFrame
            })
            
            -- Toggle Title
            local toggleTitle = Utility:Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = toggleConfig.Name,
                TextColor3 = windowConfig.Theme.Text,
                TextSize = 14,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = toggleFrame
            })
            
            -- Toggle Switch
            local toggleSwitch = Utility:Create("Frame", {
                Name = "Switch",
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10),
                BackgroundColor3 = toggleConfig.Default and windowConfig.Theme.ToggleOn or windowConfig.Theme.ToggleOff,
                BorderSizePixel = 0,
                Parent = toggleFrame
            })
            
            -- Toggle Switch Corner
            local toggleSwitchCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = toggleSwitch
            })
            
            -- Toggle Indicator
            local toggleIndicator = Utility:Create("Frame", {
                Name = "Indicator",
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(toggleConfig.Default and 1 or 0, toggleConfig.Default and -18 or 2, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = toggleSwitch
            })
            
            -- Toggle Indicator Corner
            local toggleIndicatorCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = toggleIndicator
            })
            
            -- Toggle Interaction
            local toggleInteraction = Utility:Create("TextButton", {
                Name = "Interaction",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = toggleFrame
            })
            
            -- Toggle State
            local toggleState = toggleConfig.Default
            
            -- Toggle Function
            local function updateToggle()
                toggleState = not toggleState
                
                Utility:Tween(toggleSwitch, {BackgroundColor3 = toggleState and windowConfig.Theme.ToggleOn or windowConfig.Theme.ToggleOff}, 0.3)
                Utility:Tween(toggleIndicator, {Position = UDim2.new(toggleState and 1 or 0, toggleState and -18 or 2, 0.5, -8)}, 0.3)
                
                task.spawn(function()
                    toggleConfig.Callback(toggleState)
                end)
            end
            
            -- Toggle Hover & Click Effects
            toggleInteraction.MouseEnter:Connect(function()
                Utility:Tween(toggleFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackgroundHover}, 0.3)
            end)
            
            toggleInteraction.MouseLeave:Connect(function()
                Utility:Tween(toggleFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackground}, 0.3)
            end)
            
            toggleInteraction.MouseButton1Click:Connect(function()
                updateToggle()
                Utility:Ripple(toggleFrame, Mouse.X, Mouse.Y)
            end)
            
            local toggle = {}
            
            function toggle:Set(value)
                if toggleState ~= value then
                    toggleState = value
                    Utility:Tween(toggleSwitch, {BackgroundColor3 = toggleState and windowConfig.Theme.ToggleOn or windowConfig.Theme.ToggleOff}, 0.3)
                    Utility:Tween(toggleIndicator, {Position = UDim2.new(toggleState and 1 or 0, toggleState and -18 or 2, 0.5, -8)}, 0.3)
                    
                    task.spawn(function()
                        toggleConfig.Callback(toggleState)
                    end)
                end
            end
            
            return toggle
        end
        
        function tab:CreateSlider(config)
            config = config or {}
            local sliderConfig = {
                Name = config.Name or "Slider",
                Min = config.Min or 0,
                Max = config.Max or 100,
                Default = config.Default or 50,
                Increment = config.Increment or 1,
                Suffix = config.Suffix or "",
                Callback = config.Callback or function() end
            }
            
            -- Validate default value
            sliderConfig.Default = math.clamp(sliderConfig.Default, sliderConfig.Min, sliderConfig.Max)
            
            -- Slider Frame
            local sliderFrame = Utility:Create("Frame", {
                Name = sliderConfig.Name .. "Slider",
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = windowConfig.Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Parent = tabFrame
            })
            
            -- Slider Corner
            local sliderCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = sliderFrame
            })
            
            -- Slider Title
            local sliderTitle = Utility:Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 10, 0, 5),
                BackgroundTransparency = 1,
                Text = sliderConfig.Name,
                TextColor3 = windowConfig.Theme.Text,
                TextSize = 14,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = sliderFrame
            })
            
            -- Slider Value
            local sliderValue = Utility:Create("TextLabel", {
                Name = "Value",
                Size = UDim2.new(0, 60, 0, 20),
                Position = UDim2.new(1, -70, 0, 5),
                BackgroundTransparency = 1,
                Text = tostring(sliderConfig.Default) .. sliderConfig.Suffix,
                TextColor3 = windowConfig.Theme.Text,
                TextSize = 14,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = sliderFrame
            })
            
            -- Slider Background
            local sliderBackground = Utility:Create("Frame", {
                Name = "Background",
                Size = UDim2.new(1, -20, 0, 6),
                Position = UDim2.new(0, 10, 0, 35),
                BackgroundColor3 = windowConfig.Theme.SliderBackground,
                BorderSizePixel = 0,
                Parent = sliderFrame
            })
            
            -- Slider Background Corner
            local sliderBackgroundCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = sliderBackground
            })
            
            -- Slider Fill
            local sliderFill = Utility:Create("Frame", {
                Name = "Fill",
                Size = UDim2.new((sliderConfig.Default - sliderConfig.Min) / (sliderConfig.Max - sliderConfig.Min), 0, 1, 0),
                BackgroundColor3 = windowConfig.Theme.SliderFill,
                BorderSizePixel = 0,
                Parent = sliderBackground
            })
            
            -- Slider Fill Corner
            local sliderFillCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = sliderFill
            })
            
            -- Slider Interaction
            local sliderInteraction = Utility:Create("TextButton", {
                Name = "Interaction",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = sliderFrame
            })
            
            -- Slider Variables
            local isDragging = false
            local currentValue = sliderConfig.Default
            
            -- Slider Functions
            local function updateSlider(input)
                local sizeX = math.clamp((input.Position.X - sliderBackground.AbsolutePosition.X) / sliderBackground.AbsoluteSize.X, 0, 1)
                Utility:Tween(sliderFill, {Size = UDim2.new(sizeX, 0, 1, 0)}, 0.1)
                
                local value = sliderConfig.Min + ((sliderConfig.Max - sliderConfig.Min) * sizeX)
                value = math.floor(value / sliderConfig.Increment + 0.5) * sliderConfig.Increment
                value = math.clamp(value, sliderConfig.Min, sliderConfig.Max)
                
                if value ~= currentValue then
                    currentValue = value
                    sliderValue.Text = tostring(math.floor(value * 100) / 100) .. sliderConfig.Suffix
                    
                    task.spawn(function()
                        sliderConfig.Callback(value)
                    end)
                end
            end
            
            -- Slider Events
            sliderInteraction.MouseButton1Down:Connect(function()
                isDragging = true
                updateSlider({Position = {X = Mouse.X, Y = Mouse.Y}})
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
                    updateSlider({Position = {X = Mouse.X, Y = Mouse.Y}})
                end
            end)
            
            -- Slider Hover Effects
            sliderInteraction.MouseEnter:Connect(function()
                Utility:Tween(sliderFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackgroundHover}, 0.3)
            end)
            
            sliderInteraction.MouseLeave:Connect(function()
                Utility:Tween(sliderFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackground}, 0.3)
            end)
            
            local slider = {}
            
            function slider:Set(value)
                value = math.clamp(value, sliderConfig.Min, sliderConfig.Max)
                local sizeX = (value - sliderConfig.Min) / (sliderConfig.Max - sliderConfig.Min)
                
                Utility:Tween(sliderFill, {Size = UDim2.new(sizeX, 0, 1, 0)}, 0.3)
                
                currentValue = value
                sliderValue.Text = tostring(math.floor(value * 100) / 100) .. sliderConfig.Suffix
                
                task.spawn(function()
                    sliderConfig.Callback(value)
                end)
            end
            
            return slider
        end
        
        function tab:CreateDropdown(config)
            config = config or {}
            local dropdownConfig = {
                Name = config.Name or "Dropdown",
                Options = config.Options or {},
                Default = config.Default or nil,
                Callback = config.Callback or function() end
            }
            
            -- Dropdown Frame
            local dropdownFrame = Utility:Create("Frame", {
                Name = dropdownConfig.Name .. "Dropdown",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = windowConfig.Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = tabFrame
            })
            
            -- Dropdown Corner
            local dropdownCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = dropdownFrame
            })
            
            -- Dropdown Title
            local dropdownTitle = Utility:Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -40, 0, 40),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = dropdownConfig.Name,
                TextColor3 = windowConfig.Theme.Text,
                TextSize = 14,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = dropdownFrame
            })
            
            -- Dropdown Selected
            local dropdownSelected = Utility:Create("TextLabel", {
                Name = "Selected",
                Size = UDim2.new(0, 200, 0, 40),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = dropdownConfig.Default or "Select...",
                TextColor3 = windowConfig.Theme.DarkText,
                TextSize = 14,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = dropdownFrame
            })
            
            -- Dropdown Arrow
            local dropdownArrow = Utility:Create("ImageLabel", {
                Name = "Arrow",
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -30, 0, 10),
                BackgroundTransparency = 1,
                Image = "rbxassetid://6031091004",
                ImageColor3 = windowConfig.Theme.Text,
                Parent = dropdownFrame
            })
            
            -- Dropdown List
            local dropdownList = Utility:Create("Frame", {
                Name = "List",
                Size = UDim2.new(1, -20, 0, 0),
                Position = UDim2.new(0, 10, 0, 45),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Parent = dropdownFrame
            })
            
            -- Dropdown List Layout
            local dropdownListLayout = Utility:Create("UIListLayout", {
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = dropdownList
            })
            
            -- Dropdown Interaction
            local dropdownInteraction = Utility:Create("TextButton", {
                Name = "Interaction",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundTransparency = 1,
                Text = "",
                Parent = dropdownFrame
            })
            
            -- Dropdown Variables
            local isOpen = false
            local selectedOption = dropdownConfig.Default
            
            -- Create Dropdown Options
            for i, option in ipairs(dropdownConfig.Options) do
                local optionButton = Utility:Create("TextButton", {
                    Name = option .. "Option",
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = windowConfig.Theme.DropdownOption,
                    BackgroundTransparency = 0.2,
                    BorderSizePixel = 0,
                    Text = option,
                    TextColor3 = windowConfig.Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    Parent = dropdownList
                })
                
                -- Option Corner
                local optionCorner = Utility:Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = optionButton
                })
                
                -- Option Hover & Click Effects
                optionButton.MouseEnter:Connect(function()
                    Utility:Tween(optionButton, {BackgroundColor3 = windowConfig.Theme.DropdownOptionHover}, 0.3)
                end)
                
                optionButton.MouseLeave:Connect(function()
                    Utility:Tween(optionButton, {BackgroundColor3 = windowConfig.Theme.DropdownOption}, 0.3)
                end)
                
                optionButton.MouseButton1Click:Connect(function()
                    selectedOption = option
                    dropdownSelected.Text = option
                    
                    isOpen = false
                    Utility:Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.3)
                    Utility:Tween(dropdownArrow, {Rotation = 0}, 0.3)
                    
                    task.spawn(function()
                        dropdownConfig.Callback(option)
                    end)
                end)
            end
            
            -- Update List Size
            dropdownListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if isOpen then
                    Utility:Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, 45 + dropdownListLayout.AbsoluteContentSize.Y + 5)}, 0.3)
                end
            end)
            
            -- Toggle Dropdown
            dropdownInteraction.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                
                if isOpen then
                    Utility:Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, 45 + dropdownListLayout.AbsoluteContentSize.Y + 5)}, 0.3)
                    Utility:Tween(dropdownArrow, {Rotation = 180}, 0.3)
                else
                    Utility:Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.3)
                    Utility:Tween(dropdownArrow, {Rotation = 0}, 0.3)
                end
                
                Utility:Ripple(dropdownFrame, Mouse.X, Mouse.Y)
            end)
            
            -- Dropdown Hover Effects
            dropdownInteraction.MouseEnter:Connect(function()
                Utility:Tween(dropdownFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackgroundHover}, 0.3)
            end)
            
            dropdownInteraction.MouseLeave:Connect(function()
                Utility:Tween(dropdownFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackground}, 0.3)
            end)
            
            local dropdown = {}
            
            function dropdown:Set(option)
                if table.find(dropdownConfig.Options, option) then
                    selectedOption = option
                    dropdownSelected.Text = option
                    
                    task.spawn(function()
                        dropdownConfig.Callback(option)
                    end)
                end
            end
            
            function dropdown:Refresh(options)
                dropdownConfig.Options = options
                
                -- Clear existing options
                for _, child in ipairs(dropdownList:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                
                -- Create new options
                for i, option in ipairs(options) do
                    local optionButton = Utility:Create("TextButton", {
                        Name = option .. "Option",
                        Size = UDim2.new(1, 0, 0, 30),
                        BackgroundColor3 = windowConfig.Theme.DropdownOption,
                        BackgroundTransparency = 0.2,
                        BorderSizePixel = 0,
                        Text = option,
                        TextColor3 = windowConfig.Theme.Text,
                        TextSize = 14,
                        Font = Enum.Font.Gotham,
                        Parent = dropdownList
                    })
                    
                    -- Option Corner
                    local optionCorner = Utility:Create("UICorner", {
                        CornerRadius = UDim.new(0, 6),
                        Parent = optionButton
                    })
                    
                    -- Option Hover & Click Effects
                    optionButton.MouseEnter:Connect(function()
                        Utility:Tween(optionButton, {BackgroundColor3 = windowConfig.Theme.DropdownOptionHover}, 0.3)
                    end)
                    
                    optionButton.MouseLeave:Connect(function()
                        Utility:Tween(optionButton, {BackgroundColor3 = windowConfig.Theme.DropdownOption}, 0.3)
                    end)
                    
                    optionButton.MouseButton1Click:Connect(function()
                        selectedOption = option
                        dropdownSelected.Text = option
                        
                        isOpen = false
                        Utility:Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.3)
                        Utility:Tween(dropdownArrow, {Rotation = 0}, 0.3)
                        
                        task.spawn(function()
                            dropdownConfig.Callback(option)
                        end)
                    end)
                end
                
                -- Reset selected option if it's no longer in the options
                if not table.find(options, selectedOption) then
                    selectedOption = nil
                    dropdownSelected.Text = "Select..."
                end
            end
            
            return dropdown
        end
        
        function tab:CreateColorPicker(config)
            config = config or {}
            local colorPickerConfig = {
                Name = config.Name or "Color Picker",
                Default = config.Default or Color3.fromRGB(255, 255, 255),
                Callback = config.Callback or function() end
            }
            
            -- Color Picker Frame
            local colorPickerFrame = Utility:Create("Frame", {
                Name = colorPickerConfig.Name .. "ColorPicker",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = windowConfig.Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = tabFrame
            })
            
            -- Color Picker Corner
            local colorPickerCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = colorPickerFrame
            })
            
            -- Color Picker Title
            local colorPickerTitle = Utility:Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = colorPickerConfig.Name,
                TextColor3 = windowConfig.Theme.Text,
                TextSize = 14,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = colorPickerFrame
            })
            
            -- Color Display
            local colorDisplay = Utility:Create("Frame", {
                Name = "ColorDisplay",
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -40, 0.5, -15),
                BackgroundColor3 = colorPickerConfig.Default,
                BorderSizePixel = 0,
                Parent = colorPickerFrame
            })
            
            -- Color Display Corner
            local colorDisplayCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = colorDisplay
            })
            
            -- Color Picker Interaction
            local colorPickerInteraction = Utility:Create("TextButton", {
                Name = "Interaction",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = colorPickerFrame
            })
            
            -- Color Picker Variables
            local isOpen = false
            local currentColor = colorPickerConfig.Default
            
            -- Color Picker Expanded
            local colorPickerExpanded = Utility:Create("Frame", {
                Name = "Expanded",
                Size = UDim2.new(1, -20, 0, 120),
                Position = UDim2.new(0, 10, 0, 45),
                BackgroundColor3 = windowConfig.Theme.ElementBackground,
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                Visible = false,
                Parent = colorPickerFrame
            })
            
            -- Color Picker Expanded Corner
            local colorPickerExpandedCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = colorPickerExpanded
            })
            
            -- Color Picker Hue Slider
            local hueSlider = Utility:Create("Frame", {
                Name = "HueSlider",
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = colorPickerExpanded
            })
            
            -- Hue Slider Corner
            local hueSliderCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = hueSlider
            })
            
            -- Hue Slider Gradient
            local hueSliderGradient = Utility:Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                }),
                Parent = hueSlider
            })
            
            -- Hue Slider Interaction
            local hueSliderInteraction = Utility:Create("TextButton", {
                Name = "Interaction",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = hueSlider
            })
            
            -- Hue Slider Indicator
            local hueSliderIndicator = Utility:Create("Frame", {
                Name = "Indicator",
                Size = UDim2.new(0, 5, 1, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = hueSlider
            })
            
            -- Hue Slider Indicator Corner
            local hueSliderIndicatorCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 2),
                Parent = hueSliderIndicator
            })
            
            -- Color Picker Color Field
            local colorField = Utility:Create("Frame", {
                Name = "ColorField",
                Size = UDim2.new(1, -20, 0, 80),
                Position = UDim2.new(0, 10, 0, 40),
                BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                BorderSizePixel = 0,
                Parent = colorPickerExpanded
            })
            
            -- Color Field Corner
            local colorFieldCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = colorField
            })
            
            -- Color Field Saturation Gradient
            local colorFieldSaturation = Utility:Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 0)
                }),
                Parent = colorField
            })
            
            -- Color Field Value Gradient
            local colorFieldValue = Utility:Create("Frame", {
                Name = "Value",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Parent = colorField
            })
            
            -- Color Field Value Corner
            local colorFieldValueCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = colorFieldValue
            })
            
            -- Color Field Value Gradient
            local colorFieldValueGradient = Utility:Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                }),
                Rotation = 90,
                Parent = colorFieldValue
            })
            
            -- Color Field Interaction
            local colorFieldInteraction = Utility:Create("TextButton", {
                Name = "Interaction",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = colorField
            })
            
            -- Color Field Indicator
            local colorFieldIndicator = Utility:Create("Frame", {
                Name = "Indicator",
                Size = UDim2.new(0, 10, 0, 10),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = colorField
            })
            
            -- Color Field Indicator Corner
            local colorFieldIndicatorCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = colorFieldIndicator
            })
            
            -- Color Picker Variables
            local hue, saturation, value = 0, 1, 1
            
            -- Color Picker Functions
            local function updateColor()
                local color = Color3.fromHSV(hue, saturation, value)
                colorDisplay.BackgroundColor3 = color
                colorField.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                currentColor = color
                
                task.spawn(function()
                    colorPickerConfig.Callback(color)
                end)
            end
            
            -- Hue Slider Interaction
            local hueDragging = false
            
            hueSliderInteraction.MouseButton1Down:Connect(function()
                hueDragging = true
                local relativeX = math.clamp(Mouse.X - hueSlider.AbsolutePosition.X, 0, hueSlider.AbsoluteSize.X)
                hue = relativeX / hueSlider.AbsoluteSize.X
                hueSliderIndicator.Position = UDim2.new(hue, -2, 0, 0)
                updateColor()
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueDragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement and hueDragging then
                    local relativeX = math.clamp(Mouse.X - hueSlider.AbsolutePosition.X, 0, hueSlider.AbsoluteSize.X)
                    hue = relativeX / hueSlider.AbsoluteSize.X
                    hueSliderIndicator.Position = UDim2.new(hue, -2, 0, 0)
                    updateColor()
                end
            end)
            
            -- Color Field Interaction
            local colorDragging = false
            
            colorFieldInteraction.MouseButton1Down:Connect(function()
                colorDragging = true
                local relativeX = math.clamp(Mouse.X - colorField.AbsolutePosition.X, 0, colorField.AbsoluteSize.X)
                local relativeY = math.clamp(Mouse.Y - colorField.AbsolutePosition.Y, 0, colorField.AbsoluteSize.Y)
                saturation = relativeX / colorField.AbsoluteSize.X
                value = 1 - (relativeY / colorField.AbsoluteSize.Y)
                colorFieldIndicator.Position = UDim2.new(saturation, 0, 1 - value, 0)
                updateColor()
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    colorDragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement and colorDragging then
                    local relativeX = math.clamp(Mouse.X - colorField.AbsolutePosition.X, 0, colorField.AbsoluteSize.X)
                    local relativeY = math.clamp(Mouse.Y - colorField.AbsolutePosition.Y, 0, colorField.AbsoluteSize.Y)
                    saturation = relative  0, colorField.AbsoluteSize.Y)
                    saturation = relativeX / colorField.AbsoluteSize.X
                    value = 1 - (relativeY / colorField.AbsoluteSize.Y)
                    colorFieldIndicator.Position = UDim2.new(saturation, 0, 1 - value, 0)
                    updateColor()
                end
            end)
            
            -- Toggle Color Picker
            colorPickerInteraction.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                
                if isOpen then
                    colorPickerExpanded.Visible = true
                    Utility:Tween(colorPickerFrame, {Size = UDim2.new(1, 0, 0, 170)}, 0.3)
                else
                    Utility:Tween(colorPickerFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.3)
                    task.wait(0.3)
                    colorPickerExpanded.Visible = false
                end
                
                Utility:Ripple(colorPickerFrame, Mouse.X, Mouse.Y)
            end)
            
            -- Color Picker Hover Effects
            colorPickerInteraction.MouseEnter:Connect(function()
                Utility:Tween(colorPickerFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackgroundHover}, 0.3)
            end)
            
            colorPickerInteraction.MouseLeave:Connect(function()
                Utility:Tween(colorPickerFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackground}, 0.3)
            end)
            
            -- Initialize color picker with default color
            local h, s, v = colorPickerConfig.Default:ToHSV()
            hue, saturation, value = h, s, v
            hueSliderIndicator.Position = UDim2.new(hue, -2, 0, 0)
            colorFieldIndicator.Position = UDim2.new(saturation, 0, 1 - value, 0)
            updateColor()
            
            local colorPicker = {}
            
            function colorPicker:Set(color)
                local h, s, v = color:ToHSV()
                hue, saturation, value = h, s, v
                hueSliderIndicator.Position = UDim2.new(hue, -2, 0, 0)
                colorFieldIndicator.Position = UDim2.new(saturation, 0, 1 - value, 0)
                updateColor()
            end
            
            return colorPicker
        end
        
        function tab:CreateInput(config)
            config = config or {}
            local inputConfig = {
                Name = config.Name or "Input",
                PlaceholderText = config.PlaceholderText or "Enter text...",
                Default = config.Default or "",
                Callback = config.Callback or function() end
            }
            
            -- Input Frame
            local inputFrame = Utility:Create("Frame", {
                Name = inputConfig.Name .. "Input",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = windowConfig.Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Parent = tabFrame
            })
            
            -- Input Corner
            local inputCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = inputFrame
            })
            
            -- Input Title
            local inputTitle = Utility:Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = inputConfig.Name,
                TextColor3 = windowConfig.Theme.Text,
                TextSize = 14,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = inputFrame
            })
            
            -- Input Box Background
            local inputBoxBackground = Utility:Create("Frame", {
                Name = "InputBoxBackground",
                Size = UDim2.new(1, -20, 0, 20),
                Position = UDim2.new(0, 10, 0, 20),
                BackgroundColor3 = windowConfig.Theme.InputBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Parent = inputFrame
            })
            
            -- Input Box Corner
            local inputBoxCorner = Utility:Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = inputBoxBackground
            })
            
            -- Input Box
            local inputBox = Utility:Create("TextBox", {
                Name = "InputBox",
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundTransparency = 1,
                Text = inputConfig.Default,
                PlaceholderText = inputConfig.PlaceholderText,
                TextColor3 = windowConfig.Theme.Text,
                PlaceholderColor3 = windowConfig.Theme.Placeholder,
                TextSize = 14,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = inputBoxBackground
            })
            
            -- Input Hover & Focus Effects
            inputFrame.MouseEnter:Connect(function()
                Utility:Tween(inputFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackgroundHover}, 0.3)
            end)
            
            inputFrame.MouseLeave:Connect(function()
                Utility:Tween(inputFrame, {BackgroundColor3 = windowConfig.Theme.ElementBackground}, 0.3)
            end)
            
            inputBox.Focused:Connect(function()
                Utility:Tween(inputBoxBackground, {BackgroundColor3 = windowConfig.Theme.InputBackgroundFocused}, 0.3)
            end)
            
            inputBox.FocusLost:Connect(function(enterPressed)
                Utility:Tween(inputBoxBackground, {BackgroundColor3 = windowConfig.Theme.InputBackground}, 0.3)
                
                task.spawn(function()
                    inputConfig.Callback(inputBox.Text)
                end)
            end)
            
            local input = {}
            
            function input:Set(text)
                inputBox.Text = text
                
                task.spawn(function()
                    inputConfig.Callback(text)
                end)
            end
            
            function input:GetText()
                return inputBox.Text
            end
            
            return input
        end
        
        function tab:CreateLabel(text)
            -- Label Frame
            local labelFrame = Utility:Create("Frame", {
                Name = "Label",
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Parent = tabFrame
            })
            
            -- Label Text
            local labelText = Utility:Create("TextLabel", {
                Name = "Text",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = windowConfig.Theme.Text,
                TextSize = 14,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = labelFrame
            })
            
            local label = {}
            
            function label:Set(newText)
                labelText.Text = newText
            end
            
            return label
        end
        
        -- Add tab to tabs table
        table.insert(tabs, tab)
        
        -- Select this tab if it's the first one
        if #tabs == 1 then
            window:SelectTab(name)
        end
        
        return tab
    end
    
    function window:SelectTab(tabName)
        for _, tab in ipairs(tabList:GetChildren()) do
            if tab:IsA("Frame") and tab.Name == tabName .. "Button" then
                Utility:Tween(tab, {BackgroundColor3 = windowConfig.Theme.Accent, BackgroundTransparency = 0}, 0.3)
                Utility:Tween(tab.Title, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.3)
                if tab:FindFirstChild("Icon") then
                    Utility:Tween(tab.Icon, {ImageColor3 = Color3.fromRGB(255, 255, 255), ImageTransparency = 0}, 0.3)
                end
            else
                if tab:IsA("Frame") and tab.Name:find("Button") then
                    Utility:Tween(tab, {BackgroundColor3 = windowConfig.Theme.ElementBackground, BackgroundTransparency = 0.5}, 0.3)
                    Utility:Tween(tab.Title, {TextColor3 = windowConfig.Theme.Text}, 0.3)
                    if tab:FindFirstChild("Icon") then
                        Utility:Tween(tab.Icon, {ImageColor3 = windowConfig.Theme.Text, ImageTransparency = 0.2}, 0.3)
                    end
                end
            end
        end
        
        for _, page in ipairs(tabContent:GetChildren()) do
            if page.Name == tabName .. "Frame" then
                page.Visible = true
            else
                page.Visible = false
            end
        end
        
        selectedTab = tabName
    end
    
    function window:Notify(config)
        config = config or {}
        local notificationConfig = {
            Title = config.Title or "Notification",
            Content = config.Content or "This is a notification",
            Duration = config.Duration or 5,
            Type = config.Type or "Info" -- Info, Success, Warning, Error
        }
        
        -- Determine notification color based on type
        local notificationColor
        if notificationConfig.Type == "Success" then
            notificationColor = windowConfig.Theme.Success
        elseif notificationConfig.Type == "Warning" then
            notificationColor = windowConfig.Theme.Warning
        elseif notificationConfig.Type == "Error" then
            notificationColor = windowConfig.Theme.Error
        else
            notificationColor = windowConfig.Theme.Accent
        end
        
        -- Notification Frame
        local notificationFrame = Utility:Create("Frame", {
            Name = "Notification",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = windowConfig.Theme.NotificationBackground,
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = notificationContainer
        })
        
        -- Notification Corner
        local notificationCorner = Utility:Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = notificationFrame
        })
        
        -- Notification Accent
        local notificationAccent = Utility:Create("Frame", {
            Name = "Accent",
            Size = UDim2.new(0, 4, 1, 0),
            BackgroundColor3 = notificationColor,
            BorderSizePixel = 0,
            Parent = notificationFrame
        })
        
        -- Notification Title
        local notificationTitle = Utility:Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 14, 0, 5),
            BackgroundTransparency = 1,
            Text = notificationConfig.Title,
            TextColor3 = windowConfig.Theme.Text,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = notificationFrame
        })
        
        -- Notification Content
        local notificationContent = Utility:Create("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, -20, 0, 0),
            Position = UDim2.new(0, 14, 0, 25),
            BackgroundTransparency = 1,
            Text = notificationConfig.Content,
            TextColor3 = windowConfig.Theme.DarkText,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Parent = notificationFrame
        })
        
        -- Calculate content height
        local textSize = TextService:GetTextSize(
            notificationConfig.Content,
            14,
            Enum.Font.Gotham,
            Vector2.new(notificationContainer.AbsoluteSize.X - 40, math.huge)
        )
        
        local contentHeight = math.min(textSize.Y, 100)
        notificationContent.Size = UDim2.new(1, -20, 0, contentHeight)
        
        -- Set notification frame size
        notificationFrame.Size = UDim2.new(1, 0, 0, contentHeight + 35)
        
        -- Animate notification
        Utility:Tween(notificationFrame, {Size = UDim2.new(1, -10, 0, contentHeight + 35)}, 0.3)
        
        -- Close notification after duration
        task.spawn(function()
            task.wait(notificationConfig.Duration)
            Utility:Tween(notificationFrame, {Size = UDim2.new(0, 0, 0, contentHeight + 35)}, 0.3)
            task.wait(0.3)
            notificationFrame:Destroy()
        end)
    end
    
    -- Toggle UI visibility with keybind
    local visible = true
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == windowConfig.ToggleKey then
            visible = not visible
            mainFrame.Visible = visible
        end
    end)
    
    return window
end

return SleekUI

