-- SkyeUI (cleaned)
local SkyeUI = {}
SkyeUI.__index = SkyeUI

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Themes (unchanged keys you had)
local Themes = {
    Sky = {
        Background = Color3.fromRGB(240, 248, 255),
        TabBackground = Color3.fromRGB(225, 240, 250),
        SectionBackground = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(25, 25, 35),
        SubText = Color3.fromRGB(100, 125, 150),
        Accent = Color3.fromRGB(65, 170, 230),
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
    -- (other theme definitions unchanged; omitted in snippet for brevity) ...
}

-- Utility create & tween
local function Create(instanceType, properties, children)
    local instance = Instance.new(instanceType)
    if properties then
        for property, value in pairs(properties) do
            if property ~= "Parent" then
                instance[property] = value
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function Tween(inst, props, duration, style, dir)
    local info = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(inst, info, props)
    tw:Play()
    return tw
end

-- Theme system (reliable)
local currentTheme = "Sky"
local themeConnections = {} -- [instance] = { PropertyName = "ThemeKey", ... }

local function ApplyTheme(themeName)
    if not Themes[themeName] then return end
    currentTheme = themeName
    local theme = Themes[themeName]

    -- update all registered instances
    for inst, props in pairs(themeConnections) do
        if inst and inst.Parent then
            for propName, key in pairs(props) do
                -- If the instance has the property, set it
                pcall(function()
                    if theme[key] ~= nil then
                        inst[propName] = theme[key]
                    end
                end)
            end
        else
            -- queue for removal (can't remove while iterating safely)
            themeConnections[inst] = nil
        end
    end
end

local function AddThemeConnection(instance, properties)
    if not instance or type(properties) ~= "table" then return end
    themeConnections[instance] = properties
    -- apply initial
    local theme = Themes[currentTheme] or Themes.Sky
    for propName, key in pairs(properties) do
        if theme[key] ~= nil then
            pcall(function() instance[propName] = theme[key] end)
        end
    end
end

-- small helper to bind textchildren to theme tokens if they exist
local function AddTextIfExists(parent, themeKey)
    if parent and parent:IsA("TextLabel") or parent:IsA("TextButton") or parent:IsA("TextBox") then
        AddThemeConnection(parent, {TextColor3 = themeKey})
    end
end

-- Drag implementation (replaces Draggable)
local function MakeDraggable(rootFrame, handle)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local startMouse = UserInputService:GetMouseLocation()
            local startPos = rootFrame.Position
            local dragging
            local moveConn
            local upConn

            moveConn = UserInputService.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
                    local currentMouse = UserInputService:GetMouseLocation()
                    local delta = currentMouse - startMouse
                    local newX = startPos.X.Scale + (delta.X / rootFrame.Parent.AbsoluteSize.X)
                    local newY = startPos.Y.Scale + (delta.Y / rootFrame.Parent.AbsoluteSize.Y)
                    rootFrame.Position = UDim2.new(newX, startPos.X.Offset, newY, startPos.Y.Offset)
                end
            end)

            upConn = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
                    if moveConn then moveConn:Disconnect() end
                    if upConn then upConn:Disconnect() end
                end
            end)
        end
    end)
end

-- Main window creation
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
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = Themes.Sky.InElementBorder, Thickness = 1})
    })

    -- Topbar
    local topbar = Create("Frame", {
        Name = "Topbar",
        Parent = mainFrame,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Themes.Sky.TabBackground,
        BorderSizePixel = 0
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8), Name = "TopbarCorner"})
    })

    local titleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = topbar,
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "Skye UI",
        TextColor3 = Themes.Sky.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 14
    })

    local buttonContainer = Create("Frame", {
        Name = "ButtonContainer",
        Parent = topbar,
        Size = UDim2.new(0, 70, 1, 0),
        Position = UDim2.new(1, -70, 0, 0),
        BackgroundTransparency = 1
    })

    local minimizeButton = Create("TextButton", {
        Name = "MinimizeButton",
        Parent = buttonContainer,
        Size = UDim2.new(0, 28, 0, 20),
        Position = UDim2.new(0, 4, 0.5, -10),
        BackgroundTransparency = 1,
        Text = "-",
        TextColor3 = Themes.Sky.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        AutoButtonColor = false
    })

    local closeButton = Create("TextButton", {
        Name = "CloseButton",
        Parent = buttonContainer,
        Size = UDim2.new(0, 28, 0, 20),
        Position = UDim2.new(0, 36, 0.5, -10),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = Themes.Sky.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        AutoButtonColor = false
    })

    -- sidebar and content
    local tabContainer = Create("ScrollingFrame", {
        Name = "TabContainer",
        Parent = mainFrame,
        Size = UDim2.new(0, 140, 1, -40),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Themes.Sky.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}),
        Create("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
    })

    local contentContainer = Create("ScrollingFrame", {
        Name = "ContentContainer",
        Parent = mainFrame,
        Size = UDim2.new(1, -148, 1, -40),
        Position = UDim2.new(0, 148, 0, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Themes.Sky.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12)}),
        Create("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
    })

    -- register theme connections for the main surfaces + text
    AddThemeConnection(mainFrame, {BackgroundColor3 = "Background"})
    AddThemeConnection(topbar, {BackgroundColor3 = "TabBackground"})
    AddThemeConnection(tabContainer, {BackgroundColor3 = "Background"})
    AddThemeConnection(contentContainer, {BackgroundColor3 = "Background"})
    AddThemeConnection(titleLabel, {TextColor3 = "Text"})
    AddThemeConnection(minimizeButton, {TextColor3 = "Text"})
    AddThemeConnection(closeButton, {TextColor3 = "Text"})
    -- UIStroke color
    for _, child in ipairs(mainFrame:GetChildren()) do
        if child:IsA("UIStroke") then
            AddThemeConnection(child, {Color = "InElementBorder"})
        end
    end

    -- drag (use topbar as handle)
    MakeDraggable(mainFrame, topbar)

    -- minimize / close logic (minimize keeps position centered visually)
    local isMinimized = false
    local originalSize = mainFrame.Size
    local originalPos = mainFrame.Position

    minimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            Tween(mainFrame, {Size = UDim2.new(0, 600, 0, 32)}, 0.18)
            Tween(tabContainer, {Size = UDim2.new(0, 140, 0, 0)}, 0.18)
            Tween(contentContainer, {Size = UDim2.new(1, -148, 0, 0)}, 0.18)
        else
            Tween(mainFrame, {Size = originalSize}, 0.18)
            Tween(tabContainer, {Size = UDim2.new(0, 140, 1, -40)}, 0.18)
            Tween(contentContainer, {Size = UDim2.new(1, -148, 1, -40)}, 0.18)
        end
    end)

    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- small hover helper using current theme token values (no hard-coded colors)
    local function setupSmallHover(btn, hoverBgKey, normalBgKey, stroke)
        btn.MouseEnter:Connect(function()
            local theme = Themes[currentTheme] or Themes.Sky
            if hoverBgKey and theme[hoverBgKey] then
                pcall(function() Tween(btn, {TextColor3 = theme[hoverBgKey]}, 0.12) end)
            end
        end)
        btn.MouseLeave:Connect(function()
            local theme = Themes[currentTheme] or Themes.Sky
            pcall(function() Tween(btn, {TextColor3 = theme[normalBgKey] or theme.Text}, 0.12) end)
        end)
    end

    setupSmallHover(minimizeButton, "Accent", "Text")
    setupSmallHover(closeButton, "Accent", "Text")

    -- object we return
    local window = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        TabContainer = tabContainer,
        ContentContainer = contentContainer,
        Tabs = {},
        CurrentTab = nil,
        _connections = {},
    }

    -- AddTab method
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
                Name = "Label",
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
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false
        }, {
            Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)}),
            Create("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)})
        })

        tabButton.Parent = tabContainer
        tabContent.Parent = contentContainer

        -- theme register
        AddThemeConnection(tabButton, {BackgroundColor3 = "TabBackground"})
        AddThemeConnection(tabButton.Label, {TextColor3 = "Text"})
        AddThemeConnection(tabContent, {BackgroundColor3 = "Background"})

        -- hover backed by theme
        tabButton.MouseEnter:Connect(function()
            if window.CurrentTab ~= name then
                local theme = Themes[currentTheme] or Themes.Sky
                Tween(tabButton, {BackgroundColor3 = theme.TabBackground}, 0.15)
            end
        end)
        tabButton.MouseLeave:Connect(function()
            if window.CurrentTab ~= name then
                local theme = Themes[currentTheme] or Themes.Sky
                Tween(tabButton, {BackgroundColor3 = theme.TabBackground}, 0.15)
            end
        end)

        tabButton.MouseButton1Click:Connect(function()
            if window.CurrentTab then
                local prev = window.Tabs[window.CurrentTab]
                if prev and prev.Button then
                    prev.Button.BackgroundColor3 = Themes[currentTheme].TabBackground
                    AddThemeConnection(prev.Button, {BackgroundColor3 = "TabBackground"})
                    prev.Content.Visible = false
                end
            end

            window.CurrentTab = name
            window.Tabs[name].Button.BackgroundColor3 = Themes[currentTheme].Accent
            -- ensure active tab's label turns to contrast (white)
            for _, child in ipairs(tabButton:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.TextColor3 = Color3.fromRGB(255,255,255)
                end
            end
            tabContent.Visible = true
        end)

        window.Tabs[name] = {Button = tabButton, Content = tabContent}

        if not window.CurrentTab then
            window.CurrentTab = name
            tabButton.BackgroundColor3 = Themes[currentTheme].Accent
            for _, child in ipairs(tabButton:GetChildren()) do
                if child:IsA("TextLabel") then child.TextColor3 = Color3.fromRGB(255,255,255) end
            end
            tabContent.Visible = true
        end

        return {Button = tabButton, Content = tabContent}
    end

    -- AddSection method
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
            Create("UIStroke", {Color = Themes.Sky.InElementBorder, Thickness = 1}),
            Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)}),
            Create("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})
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

        AddThemeConnection(section, {BackgroundColor3 = "SectionBackground"})
        for _, child in ipairs(section:GetChildren()) do
            if child:IsA("UIStroke") then
                AddThemeConnection(child, {Color = "InElementBorder"})
            end
        end
        AddThemeConnection(sectionHeader, {TextColor3 = "SubText"})

        return section
    end

    -- Notifications container (register theme)
    local notificationContainer = Create("Frame", {
        Name = "NotificationContainer",
        Parent = screenGui,
        Size = UDim2.new(0, 300, 0, 0),
        Position = UDim2.new(1, -320, 1, -20),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, {
        Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom})
    })
    AddThemeConnection(notificationContainer, {BackgroundColor3 = "Background"})

    function window:Notify(options)
        local title = options.Title or "Notification"
        local content = options.Content or ""
        local duration = options.Duration or 5

        local notification = Create("Frame", {
            Name = "Notification",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = Themes[currentTheme].SectionBackground,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 999
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Create("UIStroke", {Color = Themes[currentTheme].InElementBorder, Thickness = 1}),
            Create("Frame", {Name = "Accent", Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = Themes[currentTheme].Accent, BorderSizePixel = 0}),
            Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}),
            Create("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 12)})
        })

        local titleLabel = Create("TextLabel", {Text = title, Size = UDim2.new(1, -4, 0, 18), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
        local contentLabel = Create("TextLabel", {Text = content, Size = UDim2.new(1, -4, 0, 0), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].SubText, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y})
        titleLabel.Parent = notification
        contentLabel.Parent = notification
        notification.Parent = notificationContainer

        -- register theme connections
        AddThemeConnection(notification, {BackgroundColor3 = "SectionBackground"})
        for _, child in ipairs(notification:GetChildren()) do
            if child:IsA("Frame") and child.Name == "Accent" then
                AddThemeConnection(child, {BackgroundColor3 = "Accent"})
            elseif child:IsA("UIStroke") then
                AddThemeConnection(child, {Color = "InElementBorder"})
            end
        end
        AddThemeConnection(titleLabel, {TextColor3 = "Text"})
        AddThemeConnection(contentLabel, {TextColor3 = "SubText"})

        -- Wait for layout to settle, then measure content height safely
RunService.Heartbeat:Wait()

local contentHeight = 0
local listLayout = notification:FindFirstChildOfClass("UIListLayout") or notification:FindFirstChildOfClass("UIGridLayout")

if listLayout and listLayout.AbsoluteContentSize then
    -- Preferred: read size from layout
    contentHeight = listLayout.AbsoluteContentSize.Y
else
    -- Fallback: give a few frames for Roblox to compute sizes, then sum children heights
    for i = 1, 3 do RunService.Heartbeat:Wait() end
    for _, child in ipairs(notification:GetChildren()) do
        if child:IsA("GuiObject") and child.Visible then
            contentHeight = contentHeight + (child.AbsoluteSize.Y or 0)
        end
    end
    -- If UIPadding exists, include its offsets (works if padding uses Offset values)
    local pad = notification:FindFirstChildOfClass("UIPadding")
    if pad then
        local top = (pad.PaddingTop and pad.PaddingTop.Offset) or 0
        local bottom = (pad.PaddingBottom and pad.PaddingBottom.Offset) or 0
        contentHeight = contentHeight + top + bottom
    end
end

-- Ensure at least 1px so tween target is valid
local targetSize = UDim2.new(1, 0, 0, math.max(1, math.ceil(contentHeight)))
Tween(notification, {Size = targetSize}, 0.28)
        task.delay(duration, function()
            Tween(notification, {Size = UDim2.new(0, 0, 0, 0)}, 0.28)
            task.wait(0.28)
            if notification and notification.Parent then notification:Destroy() end
        end)
    end

    -- Theme switch method
    function window:SetTheme(name)
        if Themes[name] then
            ApplyTheme(name)
        end
    end

    -- apply initial theme
    ApplyTheme(currentTheme)

    setmetatable(window, SkyeUI)
    return window
end

-- Create button
function SkyeUI:CreateButton(parent, text, callback)
    local button = Create("TextButton", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Themes[currentTheme].SectionBackground,
        AutoButtonColor = false,
        Text = ""
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Create("UIStroke", {Color = Themes[currentTheme].InElementBorder, Thickness = 1}),
        Create("TextLabel", {Name = "Label", Text = text, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].Text, Font = Enum.Font.Gotham, TextSize = 13}),
        Create("ImageLabel", {Name = "Icon", Image = "rbxassetid://10709791437", Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -26, 0.5, -8), BackgroundTransparency = 1, ImageColor3 = Themes[currentTheme].Text})
    })

    -- register theme
    AddThemeConnection(button, {BackgroundColor3 = "SectionBackground"})
    for _, child in ipairs(button:GetChildren()) do
        if child:IsA("UIStroke") then AddThemeConnection(child, {Color = "InElementBorder"}) end
        if child:IsA("TextLabel") then AddThemeConnection(child, {TextColor3 = "Text"}) end
        if child:IsA("ImageLabel") then AddThemeConnection(child, {ImageColor3 = "Text"}) end
    end

    -- hover & press (use theme tokens)
    button.MouseEnter:Connect(function()
        local t = Themes[currentTheme] or Themes.Sky
        Tween(button, {BackgroundColor3 = t.DropdownFrame}, 0.16)
        for _, c in ipairs(button:GetChildren()) do
            if c:IsA("UIStroke") then Tween(c, {Color = t.Accent}, 0.16) end
        end
    end)
    button.MouseLeave:Connect(function()
        local t = Themes[currentTheme] or Themes.Sky
        Tween(button, {BackgroundColor3 = t.SectionBackground}, 0.16)
        for _, c in ipairs(button:GetChildren()) do
            if c:IsA("UIStroke") then Tween(c, {Color = t.InElementBorder}, 0.16) end
        end
    end)
    button.MouseButton1Down:Connect(function()
        Tween(button, {Size = UDim2.new(0.98, 0, 0, 30)}, 0.08)
    end)
    button.MouseButton1Up:Connect(function()
        Tween(button, {Size = UDim2.new(1, 0, 0, 32)}, 0.08)
        if callback then pcall(callback) end
    end)

    button.Parent = parent
    return button
end

-- Create toggle
function SkyeUI:CreateToggle(parent, text, default, callback)
    local toggle = { Value = default or false }
    local toggleFrame = Create("Frame", {Name = text, Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1}, {
        Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)})
    })
    local label = Create("TextLabel", {Text = text, Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
    local toggleContainer = Create("Frame", {Size = UDim2.new(1,0,0,24), BackgroundTransparency = 1})
    local toggleButton = Create("TextButton", {Size = UDim2.new(0,50,1,0), Position = UDim2.new(1,-50,0,0), BackgroundColor3 = Themes[currentTheme].SectionBackground, AutoButtonColor = false, Text = ""}, {
        Create("UICorner", {CornerRadius = UDim.new(0,12)}),
        Create("UIStroke", {Color = Themes[currentTheme].InElementBorder, Thickness = 1})
    })
    local toggleKnob = Create("Frame", {Size = UDim2.new(0,20,0,20), Position = UDim2.new(0,3,0.5,-10), BackgroundColor3 = Themes[currentTheme].ToggleSlider, Name = "ToggleKnob"}, { Create("UICorner", {CornerRadius = UDim.new(0,10)}) })
    local stateLabel = Create("TextLabel", {Text = toggle.Value and "ON" or "OFF", Size = UDim2.new(0,30,1,0), Position = UDim2.new(1,-35,0,0), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].SubText, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right})

    label.Parent = toggleFrame
    toggleKnob.Parent = toggleButton
    stateLabel.Parent = toggleButton
    toggleButton.Parent = toggleContainer
    toggleContainer.Parent = toggleFrame
    toggleFrame.Parent = parent

    -- register theme
    AddThemeConnection(toggleButton, {BackgroundColor3 = "SectionBackground"})
    AddThemeConnection(toggleKnob, {BackgroundColor3 = "ToggleSlider"})
    AddThemeConnection(stateLabel, {TextColor3 = "SubText"})
    for _,c in ipairs(toggleButton:GetChildren()) do if c:IsA("UIStroke") then AddThemeConnection(c, {Color = "InElementBorder"}) end end
    AddThemeConnection(label, {TextColor3 = "Text"})

    local function updateToggle()
        local t = Themes[currentTheme] or Themes.Sky
        if toggle.Value then
            Tween(toggleButton, {BackgroundColor3 = t.Accent}, 0.18)
            Tween(toggleKnob, {Position = UDim2.new(1, -23, 0.5, -10), BackgroundColor3 = t.ToggleToggled}, 0.18)
            stateLabel.Text = "ON"
            stateLabel.TextColor3 = Color3.fromRGB(255,255,255)
        else
            Tween(toggleButton, {BackgroundColor3 = t.SectionBackground}, 0.18)
            Tween(toggleKnob, {Position = UDim2.new(0, 3, 0.5, -10), BackgroundColor3 = t.ToggleSlider}, 0.18)
            stateLabel.Text = "OFF"
            stateLabel.TextColor3 = t.SubText
        end
    end

    toggleButton.MouseButton1Click:Connect(function()
        toggle.Value = not toggle.Value
        updateToggle()
        if callback then pcall(callback, toggle.Value) end
    end)

    updateToggle()
    return toggle
end

-- Create slider (with proper connection cleanup)
function SkyeUI:CreateSlider(parent, text, min, max, default, callback)
    min = min or 0
    max = max or 100
    local slider = { Value = default or min }

    local sliderFrame = Create("Frame", {Name = text, Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1})
    local label = Create("TextLabel", {Text = text, Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
    local valueLabel = Create("TextLabel", {Text = tostring(slider.Value), Size = UDim2.new(0,60,0,18), Position = UDim2.new(1,-60,0,0), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].SubText, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right})
    local sliderTrack = Create("Frame", {Size = UDim2.new(1,0,0,6), Position = UDim2.new(0,0,0,30), BackgroundColor3 = Themes[currentTheme].SliderRail, Name = "SliderTrack"}, { Create("UICorner", {CornerRadius = UDim.new(0,3)}) })
    local sliderFill = Create("Frame", {Size = UDim2.new(0,0,1,0), BackgroundColor3 = Themes[currentTheme].Accent, Name = "SliderFill"}, { Create("UICorner", {CornerRadius = UDim.new(0,3)}) })
    local sliderKnob = Create("Frame", {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,-8,0.5,-8), BackgroundColor3 = Color3.fromRGB(255,255,255), Name = "SliderKnob"}, { Create("UICorner", {CornerRadius = UDim.new(0,8)}), Create("UIStroke", {Color = Themes[currentTheme].Accent, Thickness = 2}) })

    label.Parent = sliderFrame
    valueLabel.Parent = sliderFrame
    sliderFill.Parent = sliderTrack
    sliderKnob.Parent = sliderTrack
    sliderTrack.Parent = sliderFrame
    sliderFrame.Parent = parent

    AddThemeConnection(label, {TextColor3 = "Text"})
    AddThemeConnection(valueLabel, {TextColor3 = "SubText"})
    AddThemeConnection(sliderTrack, {BackgroundColor3 = "SliderRail"})
    AddThemeConnection(sliderFill, {BackgroundColor3 = "Accent"})
    AddThemeConnection(sliderKnob, {BackgroundColor3 = "DialogInput"})
    for _,c in ipairs(sliderKnob:GetChildren()) do if c:IsA("UIStroke") then AddThemeConnection(c, {Color = "Accent"}) end end

    local function updateSlider(value)
        slider.Value = math.clamp(value, min, max)
        valueLabel.Text = tostring(math.floor(slider.Value*100)/100)
        local percent = (slider.Value - min) / math.max((max - min), 1)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        sliderKnob.Position = UDim2.new(percent, -8, 0.5, -8)
        if callback then pcall(callback, slider.Value) end
    end

    local dragging = false
    local inputConn, endConn

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local mouse = UserInputService:GetMouseLocation()
            local rel = (mouse.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
            updateSlider(min + (max - min) * math.clamp(rel, 0, 1))
            inputConn = UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    local m = UserInputService:GetMouseLocation()
                    local r = (m.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
                    updateSlider(min + (max - min) * math.clamp(r, 0, 1))
                end
            end)
            endConn = UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    if inputConn then inputConn:Disconnect(); inputConn = nil end
                    if endConn then endConn:Disconnect(); endConn = nil end
                end
            end)
        end
    end)

    -- cleanup (if slider is destroyed)
    sliderFrame.Destroying:Connect(function()
        if inputConn then inputConn:Disconnect() end
        if endConn then endConn:Disconnect() end
    end)

    updateSlider(slider.Value)
    return slider
end

-- Create dropdown (keeps most of your logic, registered for theme updates)
function SkyeUI:CreateDropdown(parent, text, options, default, callback)
    local dropdown = { Value = default or options[1], Options = options }
    local dropdownFrame = Create("Frame", {Name = text, Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y}, { Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)}) })
    local label = Create("TextLabel", {Text = text, Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
    local dropdownButton = Create("TextButton", {Size = UDim2.new(1,0,0,32), BackgroundColor3 = Themes[currentTheme].DropdownFrame, AutoButtonColor = false, Text = ""}, { Create("UICorner", {CornerRadius = UDim.new(0,6)}), Create("UIStroke", {Color = Themes[currentTheme].InElementBorder, Thickness = 1}) })
    local selectedLabel = Create("TextLabel", {Text = dropdown.Value, Size = UDim2.new(1,-30,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
    local dropdownIcon = Create("ImageLabel", {Image = "rbxassetid://10709790948", Size = UDim2.new(0,16,0,16), Position = UDim2.new(1,-20,0.5,-8), BackgroundTransparency = 1, ImageColor3 = Themes[currentTheme].SubText, Rotation = 0})
    local optionsFrame = Create("Frame", {Size = UDim2.new(1,0,0,0), BackgroundColor3 = Themes[currentTheme].DropdownHolder, Visible = false, AutomaticSize = Enum.AutomaticSize.Y}, { Create("UICorner", {CornerRadius = UDim.new(0,6)}), Create("UIStroke", {Color = Themes[currentTheme].DropdownBorder, Thickness = 1}), Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}) })

    label.Parent = dropdownFrame
    selectedLabel.Parent = dropdownButton
    dropdownIcon.Parent = dropdownButton
    dropdownButton.Parent = dropdownFrame
    optionsFrame.Parent = dropdownFrame
    dropdownFrame.Parent = parent

    AddThemeConnection(dropdownButton, {BackgroundColor3 = "DropdownFrame"})
    AddThemeConnection(optionsFrame, {BackgroundColor3 = "DropdownHolder"})
    AddThemeConnection(dropdownIcon, {ImageColor3 = "SubText"})
    AddThemeConnection(selectedLabel, {TextColor3 = "Text"})
    -- UIStroke
    for _, c in ipairs(dropdownFrame:GetChildren()) do if c:IsA("UIStroke") then AddThemeConnection(c, {Color = "DropdownBorder"}) end end

    local function createOptions()
        for _, child in ipairs(optionsFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for idx, option in ipairs(options) do
            local optionButton = Create("TextButton", {Size = UDim2.new(1,0,0,28), BackgroundColor3 = Themes[currentTheme].DropdownOption, AutoButtonColor = false, Text = "", LayoutOrder = idx}, {
                Create("TextLabel", {Name = "Label", Text = option, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = dropdown.Value == option and Themes[currentTheme].Accent or Themes[currentTheme].Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
            })
            optionButton.MouseEnter:Connect(function() Tween(optionButton, {BackgroundColor3 = Themes[currentTheme].DropdownFrame}, 0.12) end)
            optionButton.MouseLeave:Connect(function() Tween(optionButton, {BackgroundColor3 = Themes[currentTheme].DropdownOption}, 0.12) end)
            optionButton.MouseButton1Click:Connect(function()
                dropdown.Value = option
                selectedLabel.Text = option
                for _, child in ipairs(optionsFrame:GetChildren()) do
                    if child:IsA("TextButton") and child:FindFirstChild("Label") then
                        child.Label.TextColor3 = dropdown.Value == child.Label.Text and Themes[currentTheme].Accent or Themes[currentTheme].Text
                    end
                end
                optionsFrame.Visible = false
                Tween(dropdownIcon, {Rotation = 0}, 0.18)
                if callback then pcall(callback, dropdown.Value) end
            end)
            optionButton.Parent = optionsFrame
            AddThemeConnection(optionButton, {BackgroundColor3 = "DropdownOption"})
            if optionButton:FindFirstChild("Label") then AddThemeConnection(optionButton.Label, {TextColor3 = "Text"}) end
        end
    end

    -- Replace existing dropdownButton.MouseButton1Click handler with this block
dropdownButton.MouseButton1Click:Connect(function()
    if optionsFrame.Visible then
        -- close
        optionsFrame.Visible = false
        Tween(dropdownIcon, {Rotation = 0}, 0.16)
        return
    end

    -- (re)build options
    createOptions()

    -- Wait one heartbeat so UIListLayout can compute AbsoluteContentSize
    RunService.Heartbeat:Wait()

    -- Try to size the optionsFrame to match its layout content
    local listLayout = optionsFrame:FindFirstChildOfClass("UIListLayout") or optionsFrame:FindFirstChildOfClass("UIGridLayout")
    if listLayout and listLayout.AbsoluteContentSize then
        optionsFrame.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y)
    else
        -- Fallback: wait a couple frames and sum child heights
        for i = 1, 2 do RunService.Heartbeat:Wait() end
        local total = 0
        for _, child in ipairs(optionsFrame:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible then
                total = total + (child.AbsoluteSize.Y or 0)
            end
        end
        -- include possible UIPadding offsets if present
        local pad = optionsFrame:FindFirstChildOfClass("UIPadding")
        if pad then
            total = total + ((pad.PaddingTop and pad.PaddingTop.Offset) or 0) + ((pad.PaddingBottom and pad.PaddingBottom.Offset) or 0)
        end
        optionsFrame.Size = UDim2.new(1, 0, 0, math.max(1, math.ceil(total)))
    end

    -- show the options and rotate the chevron
    optionsFrame.Visible = true
    Tween(dropdownIcon, {Rotation = 180}, 0.16)
end)

-- Create Input
function SkyeUI:CreateInput(parent, text, placeholder, callback)
    local input = { Value = "" }
    local inputFrame = Create("Frame", {Name = text, Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y}, { Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)}) })
    local label = Create("TextLabel", {Text = text, Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
    local textBoxFrame = Create("Frame", {Size = UDim2.new(1,0,0,32), BackgroundColor3 = Themes[currentTheme].SectionBackground}, { Create("UICorner", {CornerRadius = UDim.new(0,6)}), Create("UIStroke", {Color = Themes[currentTheme].InElementBorder, Thickness = 1}) })
    local textBox = Create("TextBox", {Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, Text = "", PlaceholderText = placeholder or "", TextColor3 = Themes[currentTheme].Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})

    label.Parent = inputFrame
    textBox.Parent = textBoxFrame
    textBoxFrame.Parent = inputFrame
    inputFrame.Parent = parent

    AddThemeConnection(label, {TextColor3 = "Text"})
    AddThemeConnection(textBoxFrame, {BackgroundColor3 = "SectionBackground"})
    for _,c in ipairs(textBoxFrame:GetChildren()) do if c:IsA("UIStroke") then AddThemeConnection(c, {Color = "InElementBorder"}) end end
    AddThemeConnection(textBox, {TextColor3 = "Text"})

    textBox.Focused:Connect(function() 
        Tween(textBoxFrame.UIStroke, {Color = Themes[currentTheme].Accent}, 0.16)
    end)
    textBox.FocusLost:Connect(function()
        Tween(textBoxFrame.UIStroke, {Color = Themes[currentTheme].InElementBorder}, 0.16)
        input.Value = textBox.Text
        if callback then pcall(callback, input.Value) end
    end)

    return input
end

-- Create label
function SkyeUI:CreateLabel(parent, text, isSubText)
    local label = Create("TextLabel", {
        Text = text,
        Size = UDim2.new(1,0,0,isSubText and 14 or 16),
        BackgroundTransparency = 1,
        TextColor3 = isSubText and Themes[currentTheme].SubText or Themes[currentTheme].Text,
        Font = isSubText and Enum.Font.Gotham or Enum.Font.GothamBold,
        TextSize = isSubText and 12 or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = isSubText and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
    })
    AddThemeConnection(label, {TextColor3 = isSubText and "SubText" or "Text"})
    label.Parent = parent
    return label
end

return SkyeUI
