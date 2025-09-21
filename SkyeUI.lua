-- Skye UI Library
local SkyeUI = {}
SkyeUI.__index = SkyeUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Default Sky Theme
local Themes = {
    Sky = {
        Background = Color3.fromRGB(240, 248, 255), -- AliceBlue
        TabBackground = Color3.fromRGB(225, 240, 250),
        SectionBackground = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(25, 25, 35),
        SubText = Color3.fromRGB(100, 125, 150),
        Accent = Color3.fromRGB(65, 170, 230), -- Sky blue
        InElementBorder = Color3.fromRGB(200, 220, 235),
        DropdownFrame = Color3.fromRGB(245, 250, 255),
        DropdownHolder = Color3.fromRGB(255, 255, 255),
        DropdownBorder = Color3.fromRGB(220, 235, 245),
        DropdownOption = Color3.fromRGB(245, 250, 255),
        Keybind = Color3.fromRGB(245, 250, 255),
        ToggleSlider = Color3.fromRGB(200, 220, 235),
        ToggleToggled = Color3.fromRGB(255, 255, 255),
        SliderRail = Color3.fromRGB(225, 235, 245),
        DialogInput = Color3.fromRGB(240, 248, 255),
    },
    Dark = {
        Background = Color3.fromRGB(30, 30, 40),
        TabBackground = Color3.fromRGB(25, 25, 35),
        SectionBackground = Color3.fromRGB(40, 40, 50),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 190),
        Accent = Color3.fromRGB(65, 170, 230),
        InElementBorder = Color3.fromRGB(60, 60, 70),
        DropdownFrame = Color3.fromRGB(45, 45, 55),
        DropdownHolder = Color3.fromRGB(50, 50, 60),
        DropdownBorder = Color3.fromRGB(70, 70, 80),
        DropdownOption = Color3.fromRGB(55, 55, 65),
        Keybind = Color3.fromRGB(45, 45, 55),
        ToggleSlider = Color3.fromRGB(70, 70, 80),
        ToggleToggled = Color3.fromRGB(255, 255, 255),
        SliderRail = Color3.fromRGB(60, 60, 70),
        DialogInput = Color3.fromRGB(40, 40, 50),
    },
    Midnight = {
        Background = Color3.fromRGB(15, 15, 25),
        TabBackground = Color3.fromRGB(10, 10, 20),
        SectionBackground = Color3.fromRGB(25, 25, 35),
        Text = Color3.fromRGB(230, 230, 240),
        SubText = Color3.fromRGB(150, 150, 170),
        Accent = Color3.fromRGB(110, 90, 220),
        InElementBorder = Color3.fromRGB(40, 40, 50),
        DropdownFrame = Color3.fromRGB(30, 30, 40),
        DropdownHolder = Color3.fromRGB(35, 35, 45),
        DropdownBorder = Color3.fromRGB(55, 55, 65),
        DropdownOption = Color3.fromRGB(40, 40, 50),
        Keybind = Color3.fromRGB(30, 30, 40),
        ToggleSlider = Color3.fromRGB(55, 55, 65),
        ToggleToggled = Color3.fromRGB(255, 255, 255),
        SliderRail = Color3.fromRGB(45, 45, 55),
        DialogInput = Color3.fromRGB(25, 25, 35),
    },
    Neon = {
        Background = Color3.fromRGB(15, 20, 30),
        TabBackground = Color3.fromRGB(10, 15, 25),
        SectionBackground = Color3.fromRGB(25, 30, 40),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 180, 200),
        Accent = Color3.fromRGB(0, 255, 200),
        InElementBorder = Color3.fromRGB(40, 50, 70),
        DropdownFrame = Color3.fromRGB(30, 35, 45),
        DropdownHolder = Color3.fromRGB(35, 40, 50),
        DropdownBorder = Color3.fromRGB(60, 70, 90),
        DropdownOption = Color3.fromRGB(40, 45, 55),
        Keybind = Color3.fromRGB(30, 35, 45),
        ToggleSlider = Color3.fromRGB(60, 70, 90),
        ToggleToggled = Color3.fromRGB(255, 255, 255),
        SliderRail = Color3.fromRGB(50, 60, 80),
        DialogInput = Color3.fromRGB(25, 30, 40),
    },
    Ocean = {
        Background = Color3.fromRGB(235, 245, 255),
        TabBackground = Color3.fromRGB(220, 235, 245),
        SectionBackground = Color3.fromRGB(245, 250, 255),
        Text = Color3.fromRGB(25, 35, 45),
        SubText = Color3.fromRGB(100, 135, 165),
        Accent = Color3.fromRGB(0, 150, 200),
        InElementBorder = Color3.fromRGB(200, 220, 235),
        DropdownFrame = Color3.fromRGB(235, 245, 255),
        DropdownHolder = Color3.fromRGB(245, 250, 255),
        DropdownBorder = Color3.fromRGB(210, 225, 240),
        DropdownOption = Color3.fromRGB(240, 248, 255),
        Keybind = Color3.fromRGB(235, 245, 255),
        ToggleSlider = Color3.fromRGB(200, 220, 235),
        ToggleToggled = Color3.fromRGB(255, 255, 255),
        SliderRail = Color3.fromRGB(215, 230, 240),
        DialogInput = Color3.fromRGB(235, 245, 255),
    },
    Forest = {
        Background = Color3.fromRGB(240, 250, 240),
        TabBackground = Color3.fromRGB(225, 240, 225),
        SectionBackground = Color3.fromRGB(250, 255, 250),
        Text = Color3.fromRGB(25, 35, 25),
        SubText = Color3.fromRGB(100, 135, 100),
        Accent = Color3.fromRGB(80, 180, 80),
        InElementBorder = Color3.fromRGB(200, 220, 200),
        DropdownFrame = Color3.fromRGB(235, 245, 235),
        DropdownHolder = Color3.fromRGB(245, 250, 245),
        DropdownBorder = Color3.fromRGB(210, 225, 210),
        DropdownOption = Color3.fromRGB(240, 248, 240),
        Keybind = Color3.fromRGB(235, 245, 235),
        ToggleSlider = Color3.fromRGB(200, 220, 200),
        ToggleToggled = Color3.fromRGB(255, 255, 255),
        SliderRail = Color3.fromRGB(215, 230, 215),
        DialogInput = Color3.fromRGB(235, 245, 235),
    },
    Crimson = {
        Background = Color3.fromRGB(255, 240, 240),
        TabBackground = Color3.fromRGB(250, 225, 225),
        SectionBackground = Color3.fromRGB(255, 250, 250),
        Text = Color3.fromRGB(35, 25, 25),
        SubText = Color3.fromRGB(165, 100, 100),
        Accent = Color3.fromRGB(220, 80, 80),
        InElementBorder = Color3.fromRGB(235, 200, 200),
        DropdownFrame = Color3.fromRGB(255, 235, 235),
        DropdownHolder = Color3.fromRGB(255, 245, 245),
        DropdownBorder = Color3.fromRGB(240, 210, 210),
        DropdownOption = Color3.fromRGB(255, 240, 240),
        Keybind = Color3.fromRGB(255, 235, 235),
        ToggleSlider = Color3.fromRGB(235, 200, 200),
        ToggleToggled = Color3.fromRGB(255, 255, 255),
        SliderRail = Color3.fromRGB(240, 215, 215),
        DialogInput = Color3.fromRGB(255, 235, 235),
    }
}

-- Utility functions
local function Create(instanceType, properties, children)
    local instance = Instance.new(instanceType)
    
    for property, value in pairs(properties) do
        if property ~= "Parent" then
            instance[property] = value
        end
    end
    
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    
    return instance
end

local function Tween(instance, properties, duration, easingStyle, easingDirection)
    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    
    return tween
end

-- Theme management
local currentTheme = "Sky"
local themeConnections = {}

local function ApplyTheme(themeName)
    currentTheme = themeName
    local theme = Themes[themeName]
    
    for instance, properties in pairs(themeConnections) do
        if instance and instance.Parent then
            for property, colorKey in pairs(properties) do
                instance[property] = theme[colorKey]
            end
        else
            themeConnections[instance] = nil
        end
    end
end

local function AddThemeConnection(instance, properties)
    themeConnections[instance] = properties
    local theme = Themes[currentTheme]
    
    for property, colorKey in pairs(properties) do
        instance[property] = theme[colorKey]
    end
end

-- Main Window Creation
function SkyeUI:CreateWindow(title)
    local screenGui = Create("ScreenGui", {
        Name = "SkyeUI",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false
    })
    
    local mainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = screenGui,
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -300, 0.5, -200),
        BackgroundColor3 = Themes.Sky.Background,
        ClipsDescendants = true,
        Active = true,
        Draggable = true
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {
            Color = Themes.Sky.InElementBorder,
            Thickness = 1
        })
    })
    
    -- Topbar
    local topbar = Create("Frame", {
        Name = "Topbar",
        Parent = mainFrame,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Themes.Sky.TabBackground,
        BorderSizePixel = 0
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Name = "TopbarCorner"
        })
    })
    
    -- Topbar title
    local titleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = topbar,
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "Skye UI",
        TextColor3 = Themes.Sky.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 14
    })
    
    -- Topbar buttons
    local buttonContainer = Create("Frame", {
        Name = "ButtonContainer",
        Parent = topbar,
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundTransparency = 1
    })
    
    local minimizeButton = Create("TextButton", {
        Name = "MinimizeButton",
        Parent = buttonContainer,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 4, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "-",
        TextColor3 = Themes.Sky.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16
    })
    
    local closeButton = Create("TextButton", {
        Name = "CloseButton",
        Parent = buttonContainer,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 32, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = Themes.Sky.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14
    })
    
    -- Tab container (left sidebar)
    local tabContainer = Create("ScrollingFrame", {
        Name = "TabContainer",
        Parent = mainFrame,
        Size = UDim2.new(0, 140, 1, -40),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Themes.Sky.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4)
        }),
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8)
        })
    })
    
    -- Content container
    local contentContainer = Create("ScrollingFrame", {
        Name = "ContentContainer",
        Parent = mainFrame,
        Size = UDim2.new(1, -148, 1, -40),
        Position = UDim2.new(0, 148, 0, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Themes.Sky.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12)
        }),
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8)
        })
    })
    
    -- Minimize functionality
    local isMinimized = false
    local originalSize = mainFrame.Size
    
    minimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        
        if isMinimized then
            Tween(mainFrame, {Size = UDim2.new(0, 600, 0, 32)}, 0.2)
            Tween(tabContainer, {Size = UDim2.new(0, 140, 0, 0)}, 0.2)
            Tween(contentContainer, {Size = UDim2.new(1, -148, 0, 0)}, 0.2)
        else
            Tween(mainFrame, {Size = originalSize}, 0.2)
            Tween(tabContainer, {Size = UDim2.new(0, 140, 1, -40)}, 0.2)
            Tween(contentContainer, {Size = UDim2.new(1, -148, 1, -40)}, 0.2)
        end
    end)
    
    -- Close functionality
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Button hover animations
    local function setupButtonHover(button)
        button.MouseEnter:Connect(function()
            Tween(button, {TextColor3 = Themes.Sky.Accent, Size = UDim2.new(0, 26, 0, 26)}, 0.2)
        end)
        
        button.MouseLeave:Connect(function()
            Tween(button, {TextColor3 = Themes.Sky.Text, Size = UDim2.new(0, 24, 0, 24)}, 0.2)
        end)
        
        button.MouseButton1Down:Connect(function()
            Tween(button, {TextColor3 = Themes.Sky.SubText, Size = UDim2.new(0, 22, 0, 22)}, 0.1)
        end)
        
        button.MouseButton1Up:Connect(function()
            Tween(button, {TextColor3 = Themes.Sky.Accent, Size = UDim2.new(0, 26, 0, 26)}, 0.1)
        end)
    end
    
    setupButtonHover(minimizeButton)
    setupButtonHover(closeButton)
    
    -- Window object
    local window = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        TabContainer = tabContainer,
        ContentContainer = contentContainer,
        Tabs = {},
        CurrentTab = nil
    }
    
    -- Add tabs
    function window:AddTab(name)
        local tabButton = Create("TextButton", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Themes.Sky.TabBackground,
            Text = "",
            AutoButtonColor = false
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Create("TextLabel", {
                Text = name,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3 = Themes.Sky.Text,
                Font = Enum.Font.Gotham,
                TextSize = 13
            })
        })
        
        local tabContent = Create("ScrollingFrame", {
            Name = name,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false
        }, {
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8)
            }),
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8)
            })
        })
        
        tabButton.Parent = tabContainer
        tabContent.Parent = contentContainer
        
        -- Tab button hover animation
        tabButton.MouseEnter:Connect(function()
            if window.CurrentTab ~= name then
                Tween(tabButton, {BackgroundColor3 = Color3.fromRGB(215, 230, 245)}, 0.2)
            end
        end)
        
        tabButton.MouseLeave:Connect(function()
            if window.CurrentTab ~= name then
                Tween(tabButton, {BackgroundColor3 = Themes.Sky.TabBackground}, 0.2)
            end
        end)
        
        -- Tab selection
        tabButton.MouseButton1Click:Connect(function()
            if window.CurrentTab then
                window.Tabs[window.CurrentTab].Button.BackgroundColor3 = Themes.Sky.TabBackground
                window.Tabs[window.CurrentTab].Content.Visible = false
            end
            
            window.CurrentTab = name
            window.Tabs[name].Button.BackgroundColor3 = Themes.Sky.Accent
            window.Tabs[name].Content.Visible = true
            
            -- Update text color for active tab
            for _, child in ipairs(tabButton:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.TextColor3 = window.CurrentTab == name and Color3.fromRGB(255, 255, 255) or Themes.Sky.Text
                end
            end
        end)
        
        -- Store tab reference
        window.Tabs[name] = {
            Button = tabButton,
            Content = tabContent
        }
        
        -- Select first tab by default
        if not window.CurrentTab then
            window.CurrentTab = name
            tabButton.BackgroundColor3 = Themes.Sky.Accent
            tabContent.Visible = true
            
            for _, child in ipairs(tabButton:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        end
        
        return {
            Button = tabButton,
            Content = tabContent
        }
    end
    
    -- Add section to tab
    function window:AddSection(tabName, title)
        local tab = window.Tabs[tabName]
        if not tab then return end
        
        local section = Create("Frame", {
            Name = title,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = Themes.Sky.SectionBackground,
            AutomaticSize = Enum.AutomaticSize.Y
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Create("UIStroke", {
                Color = Themes.Sky.InElementBorder,
                Thickness = 1
            }),
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8)
            }),
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12)
            })
        })
        
        local sectionHeader = Create("TextLabel", {
            Text = title,
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            TextColor3 = Themes.Sky.SubText,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        sectionHeader.Parent = section
        section.Parent = tab.Content
        
        return section
    end
    
    -- Notification system
    local notificationContainer = Create("Frame", {
        Name = "NotificationContainer",
        Parent = screenGui,
        Size = UDim2.new(0, 300, 0, 0),
        Position = UDim2.new(1, -320, 1, -20),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, {
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom
        })
    })
    
    function window:Notify(options)
        local title = options.Title or "Notification"
        local content = options.Content or ""
        local duration = options.Duration or 5
        
        local notification = Create("Frame", {
            Name = "Notification",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = Themes.Sky.SectionBackground,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 999
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Create("UIStroke", {
                Color = Themes.Sky.InElementBorder,
                Thickness = 1
            }),
            Create("Frame", {
                Name = "Accent",
                Size = UDim2.new(0, 4, 1, 0),
                BackgroundColor3 = Themes.Sky.Accent,
                BorderSizePixel = 0
            }, {
                Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Name = "AccentCorner"
                })
            }),
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder
            }),
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 16),
                PaddingRight = UDim.new(0, 12)
            })
        })
        
        local titleLabel = Create("TextLabel", {
            Text = title,
            Size = UDim2.new(1, -4, 0, 18),
            BackgroundTransparency = 1,
            TextColor3 = Themes.Sky.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local contentLabel = Create("TextLabel", {
            Text = content,
            Size = UDim2.new(1, -4, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = Themes.Sky.SubText,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y
        })
        
        titleLabel.Parent = notification
        contentLabel.Parent = notification
        notification.Parent = notificationContainer
        
        -- Animate in
        notification.Size = UDim2.new(0, 0, 0, 0)
        Tween(notification, {Size = UDim2.new(1, 0, 0, notification.AbsoluteContentSize.Y)}, 0.3)
        
        -- Auto remove after duration
        task.delay(duration, function()
            Tween(notification, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
            task.wait(0.3)
            notification:Destroy()
        end)
    end
    
    -- Theme switching
    function window:SetTheme(themeName)
        if Themes[themeName] then
            ApplyTheme(themeName)
        end
    end
    
    -- Apply initial theme
    ApplyTheme("Sky")
    
    return window
end

-- Create button element
function SkyeUI:CreateButton(parent, text, callback)
    local button = Create("TextButton", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Themes.Sky.SectionBackground,
        AutoButtonColor = false,
        Text = ""
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Create("UIStroke", {
            Color = Themes.Sky.InElementBorder,
            Thickness = 1
        }),
        Create("TextLabel", {
            Text = text,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            TextColor3 = Themes.Sky.Text,
            Font = Enum.Font.Gotham,
            TextSize = 13
        }),
        Create("ImageLabel", {
            Image = "rbxassetid://10709791437",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(1, -10, 0.5, -8),
            BackgroundTransparency = 1,
            ImageColor3 = Themes.Sky.Text
        })
    })
    
    -- Button animations
    button.MouseEnter:Connect(function()
        Tween(button, {BackgroundColor3 = Color3.fromRGB(245, 250, 255)}, 0.2)
        Tween(button.UIStroke, {Color = Themes.Sky.Accent}, 0.2)
    end)
    
    button.MouseLeave:Connect(function()
        Tween(button, {BackgroundColor3 = Themes.Sky.SectionBackground}, 0.2)
        Tween(button.UIStroke, {Color = Themes.Sky.InElementBorder}, 0.2)
    end)
    
    button.MouseButton1Down:Connect(function()
        Tween(button, {Size = UDim2.new(0.98, 0, 0, 30)}, 0.1)
    end)
    
    button.MouseButton1Up:Connect(function()
        Tween(button, {Size = UDim2.new(1, 0, 0, 32)}, 0.1)
        if callback then
            callback()
        end
    end)
    
    button.Parent = parent
    
    return button
end

-- Create toggle element
function SkyeUI:CreateToggle(parent, text, default, callback)
    local toggle = {
        Value = default or false
    }
    
    local toggleFrame = Create("Frame", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4)
        })
    })
    
    local label = Create("TextLabel", {
        Text = text,
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        TextColor3 = Themes.Sky.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local toggleContainer = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1
    })
    
    local toggleButton = Create("TextButton", {
        Size = UDim2.new(0, 50, 1, 0),
        Position = UDim2.new(1, -50, 0, 0),
        BackgroundColor3 = Themes.Sky.SectionBackground,
        AutoButtonColor = false,
        Text = ""
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 12)}),
        Create("UIStroke", {
            Color = Themes.Sky.InElementBorder,
            Thickness = 1
        })
    })
    
    local toggleKnob = Create("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 3, 0.5, -10),
        BackgroundColor3 = Themes.Sky.ToggleSlider,
        Name = "ToggleKnob"
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 10)})
    })
    
    local stateLabel = Create("TextLabel", {
        Text = toggle.Value and "ON" or "OFF",
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -35, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Themes.Sky.SubText,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    label.Parent = toggleFrame
    toggleKnob.Parent = toggleButton
    stateLabel.Parent = toggleButton
    toggleButton.Parent = toggleContainer
    toggleContainer.Parent = toggleFrame
    toggleFrame.Parent = parent
    
    -- Update toggle appearance
    local function updateToggle()
        if toggle.Value then
            Tween(toggleButton, {BackgroundColor3 = Themes.Sky.Accent}, 0.2)
            Tween(toggleKnob, {
                Position = UDim2.new(1, -23, 0.5, -10),
                BackgroundColor3 = Themes.Sky.ToggleToggled
            }, 0.2)
            stateLabel.Text = "ON"
            stateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            Tween(toggleButton, {BackgroundColor3 = Themes.Sky.SectionBackground}, 0.2)
            Tween(toggleKnob, {
                Position = UDim2.new(0, 3, 0.5, -10),
                BackgroundColor3 = Themes.Sky.ToggleSlider
            }, 0.2)
            stateLabel.Text = "OFF"
            stateLabel.TextColor3 = Themes.Sky.SubText
        end
    end
    
    -- Toggle functionality
    toggleButton.MouseButton1Click:Connect(function()
        toggle.Value = not toggle.Value
        updateToggle()
        if callback then
            callback(toggle.Value)
        end
    end)
    
    -- Initialize
    updateToggle()
    
    return toggle
end

-- Create slider element
function SkyeUI:CreateSlider(parent, text, min, max, default, callback)
    local slider = {
        Value = default or min
    }
    
    local sliderFrame = Create("Frame", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1
    })
    
    local label = Create("TextLabel", {
        Text = text,
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        TextColor3 = Themes.Sky.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local valueLabel = Create("TextLabel", {
        Text = tostring(slider.Value),
        Size = UDim2.new(0, 60, 0, 18),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Themes.Sky.SubText,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    local sliderTrack = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = Themes.Sky.SliderRail,
        Name = "SliderTrack"
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 3)})
    })
    
    local sliderFill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Themes.Sky.Accent,
        Name = "SliderFill"
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 3)})
    })
    
    local sliderKnob = Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, -8, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Name = "SliderKnob"
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {
            Color = Themes.Sky.Accent,
            Thickness = 2
        })
    })
    
    label.Parent = sliderFrame
    valueLabel.Parent = sliderFrame
    sliderFill.Parent = sliderTrack
    sliderKnob.Parent = sliderTrack
    sliderTrack.Parent = sliderFrame
    sliderFrame.Parent = parent
    
    -- Calculate initial position
    local function updateSlider(value)
        slider.Value = math.clamp(value, min, max)
        valueLabel.Text = tostring(slider.Value)
        
        local percentage = (slider.Value - min) / (max - min)
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        sliderKnob.Position = UDim2.new(percentage, -8, 0.5, -8)
        
        if callback then
            callback(slider.Value)
        end
    end
    
    -- Slider interaction
    local isDragging = false
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            
            local position = Vector2.new(input.Position.X, input.Position.Y)
            local relativeX = (position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
            local value = min + (max - min) * relativeX
            
            updateSlider(value)
        end
    end)
    
    sliderTrack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local position = input.Position
            local relativeX = (position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
            local value = min + (max - min) * math.clamp(relativeX, 0, 1)
            
            updateSlider(value)
        end
    end)
    
    -- Initialize
    updateSlider(slider.Value)
    
    return slider
end

-- Create dropdown element
function SkyeUI:CreateDropdown(parent, text, options, default, callback)
    local dropdown = {
        Value = default or options[1],
        Options = options
    }
    
    local dropdownFrame = Create("Frame", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4)
        })
    })
    
    local label = Create("TextLabel", {
        Text = text,
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        TextColor3 = Themes.Sky.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local dropdownButton = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Themes.Sky.DropdownFrame,
        AutoButtonColor = false,
        Text = ""
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Create("UIStroke", {
            Color = Themes.Sky.InElementBorder,
            Thickness = 1
        })
    })
    
    local selectedLabel = Create("TextLabel", {
        Text = dropdown.Value,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Themes.Sky.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    
    local dropdownIcon = Create("ImageLabel", {
        Image = "rbxassetid://10709790948",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(1, -20, 0.5, -8),
        BackgroundTransparency = 1,
        ImageColor3 = Themes.Sky.SubText,
        Rotation = 0
    })
    
    local optionsFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Themes.Sky.DropdownHolder,
        Visible = false,
        AutomaticSize = Enum.AutomaticSize.Y
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Create("UIStroke", {
            Color = Themes.Sky.DropdownBorder,
            Thickness = 1
        }),
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })
    
    label.Parent = dropdownFrame
    selectedLabel.Parent = dropdownButton
    dropdownIcon.Parent = dropdownButton
    dropdownButton.Parent = dropdownFrame
    optionsFrame.Parent = dropdownFrame
    dropdownFrame.Parent = parent
    
    -- Create option buttons
    local function createOptions()
        for _, child in ipairs(optionsFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for _, option in ipairs(options) do
            local optionButton = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = Themes.Sky.DropdownOption,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = _
            }, {
                Create("TextLabel", {
                    Text = option,
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = dropdown.Value == option and Themes.Sky.Accent or Themes.Sky.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
            })
            
            optionButton.MouseEnter:Connect(function()
                Tween(optionButton, {BackgroundColor3 = Color3.fromRGB(245, 250, 255)}, 0.2)
            end)
            
            optionButton.MouseLeave:Connect(function()
                Tween(optionButton, {BackgroundColor3 = Themes.Sky.DropdownOption}, 0.2)
            end)
            
            optionButton.MouseButton1Click:Connect(function()
                dropdown.Value = option
                selectedLabel.Text = option
                
                for _, child in ipairs(optionsFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.TextLabel.TextColor3 = dropdown.Value == child.TextLabel.Text and Themes.Sky.Accent or Themes.Sky.Text
                    end
                end
                
                -- Close dropdown
                optionsFrame.Visible = false
                Tween(dropdownIcon, {Rotation = 0}, 0.2)
                
                if callback then
                    callback(dropdown.Value)
                end
            end)
            
            optionButton.Parent = optionsFrame
        end
    end
    
    -- Toggle dropdown
    dropdownButton.MouseButton1Click:Connect(function()
        optionsFrame.Visible = not optionsFrame.Visible
        Tween(dropdownIcon, {Rotation = optionsFrame.Visible and 180 or 0}, 0.2)
        
        if optionsFrame.Visible then
            createOptions()
        end
    end)
    
    -- Close dropdown when clicking elsewhere
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and optionsFrame.Visible then
            local mousePos = UserInputService:GetMouseLocation()
            local absolutePos = optionsFrame.AbsolutePosition
            local absoluteSize = optionsFrame.AbsoluteSize
            
            if mousePos.X < absolutePos.X or mousePos.X > absolutePos.X + absoluteSize.X or
               mousePos.Y < absolutePos.Y or mousePos.Y > absolutePos.Y + absoluteSize.Y then
                optionsFrame.Visible = false
                Tween(dropdownIcon, {Rotation = 0}, 0.2)
            end
        end
    end)
    
    -- Clean up connection when dropdown is destroyed
    dropdownFrame.Destroying:Connect(function()
        if connection then
            connection:Disconnect()
        end
    end)
    
    -- Initialize
    createOptions()
    
    return dropdown
end

-- Create text input element
function SkyeUI:CreateInput(parent, text, placeholder, callback)
    local input = {
        Value = ""
    }
    
    local inputFrame = Create("Frame", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4)
        })
    })
    
    local label = Create("TextLabel", {
        Text = text,
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        TextColor3 = Themes.Sky.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local textBoxFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Themes.Sky.SectionBackground
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Create("UIStroke", {
            Color = Themes.Sky.InElementBorder,
            Thickness = 1
        })
    })
    
    local textBox = Create("TextBox", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = placeholder or "",
        TextColor3 = Themes.Sky.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    label.Parent = inputFrame
    textBox.Parent = textBoxFrame
    textBoxFrame.Parent = inputFrame
    inputFrame.Parent = parent
    
    -- Text box focus effects
    textBox.Focused:Connect(function()
        Tween(textBoxFrame.UIStroke, {Color = Themes.Sky.Accent}, 0.2)
    end)
    
    textBox.FocusLost:Connect(function()
        Tween(textBoxFrame.UIStroke, {Color = Themes.Sky.InElementBorder}, 0.2)
        input.Value = textBox.Text
        if callback then
            callback(input.Value)
        end
    end)
    
    return input
end

-- Create label element
function SkyeUI:CreateLabel(parent, text, isSubText)
    local label = Create("TextLabel", {
        Text = text,
        Size = UDim2.new(1, 0, 0, isSubText and 14 : 16),
        BackgroundTransparency = 1,
        TextColor3 = isSubText and Themes.Sky.SubText or Themes.Sky.Text,
        Font = isSubText and Enum.Font.Gotham or Enum.Font.GothamBold,
        TextSize = isSubText and 12 or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = isSubText and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
    })
    
    label.Parent = parent
    
    return label
end

return SkyeUI