-- SkyeUI.lua (rewritten for SaveManager & InterfaceManager compatibility)
-- Full implementation. No placeholders or stub functions.

local SkyeUI = {}
SkyeUI.__index = SkyeUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Default themes (kept from original, condensed variable used)
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
    }
}
local currentThemeName = "Sky"
local currentTheme = Themes[currentThemeName]

-- Internal manager references (set by SetSaveManager / SetInterfaceManager)
local _SaveManager = nil
local _InterfaceManager = nil

-- Utility: safe sanitize for element ids and path parts
local function sanitize(str)
    str = tostring(str or "")
    -- replace slashes and control chars with underscore
    str = str:gsub("[%c%z\\/:%*%?%\"%<%>%|]", "_")
    str = str:gsub("%s+", "_")
    if #str == 0 then return "unnamed" end
    return str
end

-- Basic Instance builder (keeps original Create behavior)
local function Create(instanceType, properties, children)
    local inst = Instance.new(instanceType)
    if properties then
        for prop, value in pairs(properties) do
            if prop ~= "Parent" then
                inst[prop] = value
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    if properties and properties.Parent then
        inst.Parent = properties.Parent
    end
    return inst
end

local function Tween(instance, properties, duration, easingStyle, easingDirection)
    local tweenInfo = TweenInfo.new(duration or 0.2, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out)
    local tw = TweenService:Create(instance, tweenInfo, properties)
    tw:Play()
    return tw
end

-- Theme application helpers (keep connection map)
local themeConnections = {}
local function ApplyThemeToInstance(instance, map)
    themeConnections[instance] = map
    for prop, key in pairs(map) do
        if currentTheme[key] ~= nil then
            instance[prop] = currentTheme[key]
        end
    end
end

local function ApplyTheme(name)
    if Themes[name] then
        currentThemeName = name
        currentTheme = Themes[name]
        for inst, map in pairs(themeConnections) do
            if inst and inst.Parent then
                for prop, key in pairs(map) do
                    if currentTheme[key] ~= nil then
                        inst[prop] = currentTheme[key]
                    end
                end
            else
                themeConnections[inst] = nil
            end
        end
    end
end

-- Path builder for SaveManager: Window/Tab/Section/ElementID
local function buildPath(windowTitle, tabName, sectionTitle, elementId)
    return table.concat({
        sanitize(windowTitle),
        sanitize(tabName or ""),
        sanitize(sectionTitle or ""),
        sanitize(elementId or "")
    }, "/")
end

-- Notify wrapper used by external managers and internal code
local function notify(window, options)
    if window and type(window.Notify) == "function" then
        window:Notify(options)
    end
end

-- Core: CreateWindow (returns window object with expected methods for InterfaceManager)
function SkyeUI:CreateWindow(title)
    local windowTitle = title or "Skye UI"
    -- ScreenGui
    local screenGui = Create("ScreenGui", {
        Name = "SkyeUI_" .. sanitize(windowTitle) .. "_" .. tostring(math.random(100000,999999)),
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false
    })

    -- Main Frame
    local mainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = screenGui,
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -300, 0.5, -200),
        BackgroundColor3 = currentTheme.Background,
        ClipsDescendants = true,
        Active = true,
        Draggable = true
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = currentTheme.InElementBorder, Thickness = 1})
    })

    -- Topbar
    local topbar = Create("Frame", {
        Name = "Topbar",
        Parent = mainFrame,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = currentTheme.TabBackground,
        BorderSizePixel = 0
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    local titleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = topbar,
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = windowTitle,
        TextColor3 = currentTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 14
    })

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
        TextColor3 = currentTheme.Text,
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
        TextColor3 = currentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14
    })

    local tabContainer = Create("ScrollingFrame", {
        Name = "TabContainer",
        Parent = mainFrame,
        Size = UDim2.new(0, 140, 1, -40),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = currentTheme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
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
        ScrollBarImageColor3 = currentTheme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12)}),
        Create("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
    })

    -- minimize state
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

    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- hover effect helper
    local function setupButtonHover(button)
        if not button then return end
        button.MouseEnter:Connect(function()
            Tween(button, {TextColor3 = currentTheme.Accent, Size = UDim2.new(0, 26, 0, 26)}, 0.2)
        end)
        button.MouseLeave:Connect(function()
            Tween(button, {TextColor3 = currentTheme.Text, Size = UDim2.new(0, 24, 0, 24)}, 0.2)
        end)
        button.MouseButton1Down:Connect(function()
            Tween(button, {TextColor3 = currentTheme.SubText, Size = UDim2.new(0, 22, 0, 22)}, 0.1)
        end)
        button.MouseButton1Up:Connect(function()
            Tween(button, {TextColor3 = currentTheme.Accent, Size = UDim2.new(0, 26, 0, 26)}, 0.1)
        end)
    end
    setupButtonHover(minimizeButton)
    setupButtonHover(closeButton)

    -- notification container
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

    -- window object table
    local window = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        TabContainer = tabContainer,
        ContentContainer = contentContainer,
        Tabs = {},
        CurrentTab = nil,
        Title = windowTitle
    }

    -- Helper to tag frames with metadata for SaveManager
    local function tagInstanceWithMeta(inst, meta)
        if type(inst) == "Instance" then
            -- store metadata in a non-Instance table field (safe)
            inst:SetAttribute("__skye_meta", HttpService:JSONEncode(meta))
        end
    end

    local function readMetaFromInstance(inst)
        if type(inst) == "Instance" then
            local json = inst:GetAttribute("__skye_meta")
            if json then
                local ok, tbl = pcall(function() return HttpService:JSONDecode(json) end)
                if ok and type(tbl) == "table" then
                    return tbl
                end
            end
        end
        return nil
    end

    -- Tab creation
    function window:AddTab(name)
        local tabName = name or "Tab"
        local tabButton = Create("TextButton", {
            Name = sanitize(tabName),
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = currentTheme.TabBackground,
            Text = "",
            AutoButtonColor = false
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Create("TextLabel", {
                Text = tabName,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3 = currentTheme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 13
            })
        })

        local tabContent = Create("ScrollingFrame", {
            Name = sanitize(tabName),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false
        }, {
            Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)}),
            Create("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)})
        })

        tabButton.Parent = tabContainer
        tabContent.Parent = contentContainer

        -- store meta on tabContent so child sections/elements can discover window/tab/section path
        tagInstanceWithMeta(tabContent, { window = windowTitle, tab = tabName })

        -- hover
        tabButton.MouseEnter:Connect(function()
            if window.CurrentTab ~= tabName then
                Tween(tabButton, {BackgroundColor3 = Color3.fromRGB(215,230,245)}, 0.2)
            end
        end)
        tabButton.MouseLeave:Connect(function()
            if window.CurrentTab ~= tabName then
                Tween(tabButton, {BackgroundColor3 = currentTheme.TabBackground}, 0.2)
            end
        end)

        -- selection
        tabButton.MouseButton1Click:Connect(function()
            if window.CurrentTab then
                window.Tabs[window.CurrentTab].Button.BackgroundColor3 = currentTheme.TabBackground
                window.Tabs[window.CurrentTab].Content.Visible = false
            end
            window.CurrentTab = tabName
            window.Tabs[tabName].Button.BackgroundColor3 = currentTheme.Accent
            window.Tabs[tabName].Content.Visible = true
            -- update text color for active tab
            for _, child in ipairs(tabButton:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.TextColor3 = window.CurrentTab == tabName and Color3.fromRGB(255,255,255) or currentTheme.Text
                end
            end
        end)

        -- add to registry and select first
        window.Tabs[tabName] = { Button = tabButton, Content = tabContent }
        if not window.CurrentTab then
            window.CurrentTab = tabName
            tabButton.BackgroundColor3 = currentTheme.Accent
            tabContent.Visible = true
            for _, child in ipairs(tabButton:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.TextColor3 = Color3.fromRGB(255,255,255)
                end
            end
        end

        return {
            Button = tabButton,
            Content = tabContent
        }
    end

    -- AddSection (creates a styled section frame inside a tab's Content)
    function window:AddSection(tabName, title)
        local tab = window.Tabs[tabName]
        if not tab then
            error("AddSection: Tab '" .. tostring(tabName) .. "' not found on window '" .. tostring(windowTitle) .. "'")
        end

        local section = Create("Frame", {
            Name = sanitize(title),
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = currentTheme.SectionBackground,
            AutomaticSize = Enum.AutomaticSize.Y
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Create("UIStroke", {Color = currentTheme.InElementBorder, Thickness = 1}),
            Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)}),
            Create("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})
        })

        local header = Create("TextLabel", {
            Text = title,
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            TextColor3 = currentTheme.SubText,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        header.Parent = section
        section.Parent = tab.Content

        -- tag section with metadata so children know their path
        tagInstanceWithMeta(section, { window = windowTitle, tab = tabName, section = title })

        return section
    end

    -- Notification API
    function window:Notify(options)
        local title = options.Title or "Notification"
        local content = options.Content or ""
        local duration = options.Duration or 5

        local notification = Create("Frame", {
            Name = "Notification",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = currentTheme.SectionBackground,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 999
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
            Create("UIStroke", {Color = currentTheme.InElementBorder, Thickness = 1}),
            Create("Frame", {Name = "Accent", Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = currentTheme.Accent, BorderSizePixel = 0}, { Create("UICorner", {CornerRadius = UDim.new(0, 6)}) }),
            Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}),
            Create("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 12)})
        })

        local titleLabel = Create("TextLabel", { Text = title, Size = UDim2.new(1, -4, 0, 18), BackgroundTransparency = 1, TextColor3 = currentTheme.Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
        local contentLabel = Create("TextLabel", { Text = content, Size = UDim2.new(1, -4, 0, 0), BackgroundTransparency = 1, TextColor3 = currentTheme.SubText, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y })

        titleLabel.Parent = notification
        contentLabel.Parent = notification
        notification.Parent = notificationContainer

        -- animate in
        notification.Size = UDim2.new(0, 0, 0, 0)
        Tween(notification, {Size = UDim2.new(1, 0, 0, notification.AbsoluteContentSize.Y)}, 0.3)

        task.delay(duration, function()
            Tween(notification, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
            task.wait(0.3)
            pcall(function() notification:Destroy() end)
        end)
    end

    -- Theme setter on window
    function window:SetTheme(themeName)
        ApplyTheme(themeName)
    end

    -- Layout helpers required by InterfaceManager
    function window:GetLayout()
        if not mainFrame then return nil end
        -- store position and size as text-friendly numbers
        return {
            Position = { X = mainFrame.Position.X.Scale, Y = mainFrame.Position.Y.Scale, OffsetX = mainFrame.Position.X.Offset, OffsetY = mainFrame.Position.Y.Offset },
            Size = { X = mainFrame.Size.X.Scale, Y = mainFrame.Size.Y.Scale, OffsetX = mainFrame.Size.X.Offset, OffsetY = mainFrame.Size.Y.Offset },
            Visible = mainFrame.Visible
        }
    end

    function window:ApplyLayout(layout)
        if not layout then return false end
        local ok, err = pcall(function()
            if layout.Position and layout.Size then
                mainFrame.Position = UDim2.new(layout.Position.X or 0.5, layout.Position.OffsetX or 0, layout.Position.Y or 0.5, layout.Position.OffsetY or 0)
                mainFrame.Size = UDim2.new(layout.Size.X or 0.6, layout.Size.OffsetX or 0, layout.Size.Y or 0.6, layout.Size.OffsetY or 0)
            end
            if type(layout.Visible) == "boolean" then mainFrame.Visible = layout.Visible end
        end)
        if not ok then
            warn("[SkyeUI] ApplyLayout failed:", err)
            return false
        end
        return true
    end

    function window:SetVisible(state)
        mainFrame.Visible = not not state
    end

    -- When window created, register with external InterfaceManager if present
    if _InterfaceManager and type(_InterfaceManager.AddWindow) == "function" then
        pcall(function() _InterfaceManager:AddWindow(window) end)
    end

    setmetatable(window, SkyeUI)
    return window
end

-- Backwards-compatible element creators.
-- These functions accept either (parent, text, ...) OR (parent, optsTable) where optsTable = { id=..., text=..., default=..., callback=..., min=..., max=..., options=... }
-- If parent is a Section (Frame tagged with metadata), the code auto-registers with attached SaveManager.

local function extractArgs(parent, a2, ...)
    -- returns opts: table with fields id, text, default, callback or specific fields for slider/dropdown
    if type(a2) == "table" then
        local opts = a2
        opts.parent = parent
        return opts
    else
        local text = a2
        local rest = {...}
        return { parent = parent, text = text, args = rest }
    end
end

-- Helper to attempt SaveManager registration: parent must be an Instance with __skye_meta attribute
local function tryRegisterWithSaveManager(parent, elementId, defaultValue, applyCallback)
    if not _SaveManager then return end
    if not parent or typeof(parent) ~= "Instance" then return end
    local meta = nil
    local json = parent:GetAttribute("__skye_meta")
    if json then
        local ok, tbl = pcall(function() return HttpService:JSONDecode(json) end)
        if ok and type(tbl) == "table" then meta = tbl end
    end
    -- if parent isn't a section (maybe parent is content or tab), climb ancestors up to find section metadata
    if not meta then
        local ancestor = parent.Parent
        local depth = 0
        while ancestor and depth < 6 do
            local aj = ancestor:GetAttribute("__skye_meta")
            if aj then
                local ok2, t2 = pcall(function() return HttpService:JSONDecode(aj) end)
                if ok2 and type(t2) == "table" then meta = t2; break end
            end
            ancestor = ancestor.Parent
            depth = depth + 1
        end
    end
    if not meta then return end
    -- build path
    local path = buildPath(meta.window, meta.tab, meta.section, elementId)
    -- Register element and get saved value
    local saved = nil
    local success, err = pcall(function()
        saved = _SaveManager:RegisterElement(path, defaultValue)
    end)
    if not success then
        -- registration failed; still return
        return
    end
    -- apply saved value via callback if provided
    if saved ~= nil then
        pcall(function() applyCallback(saved) end)
    end
    -- subscribe to profile changes
    if type(_SaveManager.RegisterListener) == "function" then
        pcall(function()
            _SaveManager:RegisterListener(path, function(v)
                pcall(function() applyCallback(v) end)
            end)
        end)
    end
    -- return a function to report updates
    return function(value)
        if type(_SaveManager.UpdateValue) == "function" then
            pcall(function() _SaveManager:UpdateValue(path, value) end)
        end
    end
end

-- CreateButton (keeps original look & behavior). No SaveManager registration for Button (stateless).
function SkyeUI:CreateButton(parent, text, callback)
    if not parent then error("CreateButton requires parent") end
    local button = Create("TextButton", {
        Name = tostring(text or "Button"),
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = currentTheme.SectionBackground,
        AutoButtonColor = false,
        Text = ""
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Create("UIStroke", {Color = currentTheme.InElementBorder, Thickness = 1}),
        Create("TextLabel", { Text = text or "Button", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextColor3 = currentTheme.Text, Font = Enum.Font.Gotham, TextSize = 13 }),
        Create("ImageLabel", { Image = "rbxassetid://10709791437", Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -10, 0.5, -8), BackgroundTransparency = 1, ImageColor3 = currentTheme.Text })
    })
    -- animations & click
    button.MouseEnter:Connect(function()
        Tween(button, {BackgroundColor3 = Color3.fromRGB(245,250,255)}, 0.2)
        Tween(button.UIStroke, {Color = currentTheme.Accent}, 0.2)
    end)
    button.MouseLeave:Connect(function()
        Tween(button, {BackgroundColor3 = currentTheme.SectionBackground}, 0.2)
        Tween(button.UIStroke, {Color = currentTheme.InElementBorder}, 0.2)
    end)
    button.MouseButton1Down:Connect(function() Tween(button, {Size = UDim2.new(0.98,0,0,30)}, 0.1) end)
    button.MouseButton1Up:Connect(function()
        Tween(button, {Size = UDim2.new(1,0,0,32)}, 0.1)
        if callback then pcall(callback) end
    end)
    button.Parent = parent
    return button
end

-- CreateToggle: supports old signature (parent, text, default, callback) and table signature (parent, {id=..., text=..., default=..., callback=...})
function SkyeUI:CreateToggle(parent, a2, a3, a4)
    if not parent then error("CreateToggle requires parent") end
    local opts = {}
    if type(a2) == "table" then
        opts = a2
    else
        opts.text = a2
        opts.default = a3
        opts.callback = a4
    end
    opts.parent = parent
    opts.text = tostring(opts.text or "Toggle")
    opts.id = sanitize(opts.id or opts.text)

    local toggleState = { Value = not not opts.default }

    local frame = Create("Frame", { Name = opts.id, Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y }, {
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4) })
    })
    local label = Create("TextLabel", { Text = opts.text, Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = currentTheme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
    local toggleContainer = Create("Frame", { Size = UDim2.new(1,0,0,24), BackgroundTransparency = 1 })
    local toggleButton = Create("TextButton", { Size = UDim2.new(0,50,1,0), Position = UDim2.new(1,-50,0,0), BackgroundColor3 = currentTheme.SectionBackground, AutoButtonColor = false, Text = "" }, {
        Create("UICorner", { CornerRadius = UDim.new(0,12) }),
        Create("UIStroke", { Color = currentTheme.InElementBorder, Thickness = 1 })
    })
    local toggleKnob = Create("Frame", { Size = UDim2.new(0,20,0,20), Position = UDim2.new(0,3,0.5,-10), BackgroundColor3 = currentTheme.ToggleSlider, Name = "ToggleKnob" }, {
        Create("UICorner", { CornerRadius = UDim.new(0,10) })
    })
    local stateLabel = Create("TextLabel", { Text = toggleState.Value and "ON" or "OFF", Size = UDim2.new(0,30,1,0), Position = UDim2.new(1,-35,0,0), BackgroundTransparency = 1, TextColor3 = currentTheme.SubText, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })

    label.Parent = frame
    toggleKnob.Parent = toggleButton
    stateLabel.Parent = toggleButton
    toggleButton.Parent = toggleContainer
    toggleContainer.Parent = frame
    frame.Parent = parent

    local function updateVisual()
        if toggleState.Value then
            Tween(toggleButton, {BackgroundColor3 = currentTheme.Accent}, 0.2)
            Tween(toggleKnob, { Position = UDim2.new(1, -23, 0.5, -10), BackgroundColor3 = currentTheme.ToggleToggled }, 0.2)
            stateLabel.Text = "ON"
            stateLabel.TextColor3 = Color3.fromRGB(255,255,255)
        else
            Tween(toggleButton, {BackgroundColor3 = currentTheme.SectionBackground}, 0.2)
            Tween(toggleKnob, { Position = UDim2.new(0, 3, 0.5, -10), BackgroundColor3 = currentTheme.ToggleSlider }, 0.2)
            stateLabel.Text = "OFF"
            stateLabel.TextColor3 = currentTheme.SubText
        end
    end

    -- SaveManager integration: register and get saved value; returns updateFn to report changes
    local updateFn = tryRegisterWithSaveManager(parent, opts.id, toggleState.Value, function(v)
        if type(v) == "boolean" then
            toggleState.Value = v
            pcall(updateVisual)
            if opts.callback then pcall(function() opts.callback(v) end) end
        end
    end)

    toggleButton.MouseButton1Click:Connect(function()
        toggleState.Value = not toggleState.Value
        updateVisual()
        if opts.callback then pcall(function() opts.callback(toggleState.Value) end) end
        if updateFn then pcall(function() updateFn(toggleState.Value) end) end
    end)

    -- initialize visuals after potential SaveManager apply
    updateVisual()
    return toggleState
end

-- CreateSlider: signature supports both styles (parent, text, min, max, default, callback) or (parent, {id=..., text=..., min=..., max=..., default=..., callback=...})
function SkyeUI:CreateSlider(parent, a2, a3, a4, a5, a6)
    if not parent then error("CreateSlider requires parent") end
    local opts = {}
    if type(a2) == "table" then
        opts = a2
    else
        opts.text = a2
        opts.min = a3
        opts.max = a4
        opts.default = a5
        opts.callback = a6
    end
    opts.parent = parent
    opts.text = tostring(opts.text or "Slider")
    opts.min = tonumber(opts.min) or 0
    opts.max = tonumber(opts.max) or 100
    if opts.max <= opts.min then opts.max = opts.min + 1 end
    opts.default = tonumber(opts.default) or opts.min
    opts.id = sanitize(opts.id or opts.text)

    local sliderState = { Value = math.clamp(opts.default, opts.min, opts.max) }

    local sliderFrame = Create("Frame", { Name = opts.id, Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1 })
    local label = Create("TextLabel", { Text = opts.text, Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = currentTheme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
    local valueLabel = Create("TextLabel", { Text = tostring(sliderState.Value), Size = UDim2.new(0,60,0,18), Position = UDim2.new(1,-60,0,0), BackgroundTransparency = 1, TextColor3 = currentTheme.SubText, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
    local sliderTrack = Create("Frame", { Size = UDim2.new(1,0,0,6), Position = UDim2.new(0,0,0,30), BackgroundColor3 = currentTheme.SliderRail, Name = "SliderTrack" }, { Create("UICorner", {CornerRadius = UDim.new(0,3)}) })
    local sliderFill = Create("Frame", { Size = UDim2.new(0,0,1,0), BackgroundColor3 = currentTheme.Accent, Name = "SliderFill" }, { Create("UICorner", {CornerRadius = UDim.new(0,3)}) })
    local sliderKnob = Create("Frame", { Size = UDim2.new(0,16,0,16), Position = UDim2.new(0, -8, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255,255,255), Name = "SliderKnob" }, { Create("UICorner", {CornerRadius = UDim.new(0,8)}), Create("UIStroke", {Color = currentTheme.Accent, Thickness = 2}) })

    label.Parent = sliderFrame
    valueLabel.Parent = sliderFrame
    sliderFill.Parent = sliderTrack
    sliderKnob.Parent = sliderTrack
    sliderTrack.Parent = sliderFrame
    sliderFrame.Parent = parent

    local function applySliderValue(v)
        local num = tonumber(v) or opts.min
        num = math.clamp(num, opts.min, opts.max)
        sliderState.Value = num
        valueLabel.Text = tostring(math.floor(num*100)/100)
        local percentage = (sliderState.Value - opts.min) / (opts.max - opts.min)
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        sliderKnob.Position = UDim2.new(percentage, -8, 0.5, -8)
        if opts.callback then pcall(function() opts.callback(sliderState.Value) end) end
    end

    -- SaveManager integration
    local updateFn = tryRegisterWithSaveManager(parent, opts.id, sliderState.Value, function(v)
        if tonumber(v) then
            applySliderValue(tonumber(v))
        end
    end)

    local isDragging = false
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            local relativeX = (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
            local value = opts.min + (opts.max - opts.min) * relativeX
            applySliderValue(value)
            if updateFn then pcall(function() updateFn(sliderState.Value) end) end
        end
    end)
    sliderTrack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            if sliderTrack.AbsoluteSize.X > 1 then
                local relativeX = (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
                local value = opts.min + (opts.max - opts.min) * math.clamp(relativeX, 0, 1)
                applySliderValue(value)
                if updateFn then pcall(function() updateFn(sliderState.Value) end) end
            end
        end
    end)

    -- initialize
    applySliderValue(sliderState.Value)
    return sliderState
end

-- CreateDropdown (supports table or classic signature)
function SkyeUI:CreateDropdown(parent, a2, a3, a4, a5)
    if not parent then error("CreateDropdown requires parent") end
    local opts = {}
    if type(a2) == "table" then
        opts = a2
    else
        opts.text = a2
        opts.options = a3
        opts.default = a4
        opts.callback = a5
    end
    opts.parent = parent
    opts.text = tostring(opts.text or "Dropdown")
    opts.options = type(opts.options) == "table" and opts.options or {}
    opts.default = opts.default or opts.options[1]
    opts.id = sanitize(opts.id or opts.text)

    local dropdownState = { Value = opts.default, Options = opts.options }

    local dropdownFrame = Create("Frame", { Name = opts.id, Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y }, {
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4) })
    })
    local label = Create("TextLabel", { Text = opts.text, Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = currentTheme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
    local dropdownButton = Create("TextButton", { Size = UDim2.new(1,0,0,32), BackgroundColor3 = currentTheme.DropdownFrame, AutoButtonColor = false, Text = "" }, { Create("UICorner", {CornerRadius = UDim.new(0,6)}), Create("UIStroke", {Color = currentTheme.InElementBorder, Thickness = 1}) })
    local selectedLabel = Create("TextLabel", { Text = dropdownState.Value, Size = UDim2.new(1,-30,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = currentTheme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
    local dropdownIcon = Create("ImageLabel", { Image = "rbxassetid://10709790948", Size = UDim2.new(0,16,0,16), Position = UDim2.new(1,-20,0.5,-8), BackgroundTransparency = 1, ImageColor3 = currentTheme.SubText })
    local optionsFrame = Create("Frame", { Size = UDim2.new(1,0,0,0), BackgroundColor3 = currentTheme.DropdownHolder, Visible = false, AutomaticSize = Enum.AutomaticSize.Y }, { Create("UICorner", {CornerRadius = UDim.new(0,6)}), Create("UIStroke", {Color = currentTheme.DropdownBorder, Thickness = 1}), Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}) })

    label.Parent = dropdownFrame
    selectedLabel.Parent = dropdownButton
    dropdownIcon.Parent = dropdownButton
    dropdownButton.Parent = dropdownFrame
    optionsFrame.Parent = dropdownFrame
    dropdownFrame.Parent = parent

    local function refreshOptions()
        for _, child in ipairs(optionsFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for idx, opt in ipairs(opts.options) do
            local optionButton = Create("TextButton", { Size = UDim2.new(1,0,0,28), BackgroundColor3 = currentTheme.DropdownOption, AutoButtonColor = false, Text = "", LayoutOrder = idx }, {
                Create("TextLabel", { Text = tostring(opt), Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = (dropdownState.Value == opt) and currentTheme.Accent or currentTheme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
            })
            optionButton.MouseEnter:Connect(function() Tween(optionButton, {BackgroundColor3 = Color3.fromRGB(245,250,255)}, 0.2) end)
            optionButton.MouseLeave:Connect(function() Tween(optionButton, {BackgroundColor3 = currentTheme.DropdownOption}, 0.2) end)
            optionButton.MouseButton1Click:Connect(function()
                dropdownState.Value = opt
                selectedLabel.Text = opt
                for _, child in ipairs(optionsFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        local lbl = child:FindFirstChildOfClass("TextLabel")
                        if lbl then lbl.TextColor3 = (lbl.Text == opt) and currentTheme.Accent or currentTheme.Text end
                    end
                end
                optionsFrame.Visible = false
                Tween(dropdownIcon, {Rotation = 0}, 0.2)
                if opts.callback then pcall(function() opts.callback(dropdownState.Value) end) end
            end)
            optionButton.Parent = optionsFrame
        end
    end

    -- close when clicking outside
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and optionsFrame.Visible then
            local mouse = UserInputService:GetMouseLocation()
            local absPos = optionsFrame.AbsolutePosition
            local absSize = optionsFrame.AbsoluteSize
            if mouse.X < absPos.X or mouse.X > absPos.X + absSize.X or mouse.Y < absPos.Y or mouse.Y > absPos.Y + absSize.Y then
                optionsFrame.Visible = false
                Tween(dropdownIcon, {Rotation = 0}, 0.2)
            end
        end
    end)
    dropdownFrame.Destroying:Connect(function() if conn then conn:Disconnect() end end)

    -- SaveManager integration
    local updateFn = tryRegisterWithSaveManager(parent, opts.id, dropdownState.Value, function(v)
        if v ~= nil then dropdownState.Value = v; selectedLabel.Text = tostring(v); refreshOptions(); if opts.callback then pcall(function() opts.callback(v) end) end end
    end)

    dropdownButton.MouseButton1Click:Connect(function()
        optionsFrame.Visible = not optionsFrame.Visible
        Tween(dropdownIcon, {Rotation = optionsFrame.Visible and 180 or 0}, 0.2)
        if optionsFrame.Visible then refreshOptions() end
    end)

    refreshOptions()
    return dropdownState
end

-- CreateInput (text box)
function SkyeUI:CreateInput(parent, a2, a3, a4)
    if not parent then error("CreateInput requires parent") end
    local opts = {}
    if type(a2) == "table" then
        opts = a2
    else
        opts.text = a2
        opts.placeholder = a3
        opts.callback = a4
    end
    opts.parent = parent
    opts.text = tostring(opts.text or "Input")
    opts.placeholder = tostring(opts.placeholder or "")
    opts.id = sanitize(opts.id or opts.text)

    local inputState = { Value = "" }

    local frame = Create("Frame", { Name = opts.id, Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y }, {
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4) })
    })
    local label = Create("TextLabel", { Text = opts.text, Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = currentTheme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
    local textBoxFrame = Create("Frame", { Size = UDim2.new(1,0,0,32), BackgroundColor3 = currentTheme.SectionBackground }, { Create("UICorner", {CornerRadius = UDim.new(0,6)}), Create("UIStroke", {Color = currentTheme.InElementBorder, Thickness = 1}) })
    local textBox = Create("TextBox", { Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, Text = "", PlaceholderText = opts.placeholder, TextColor3 = currentTheme.Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })

    label.Parent = frame
    textBox.Parent = textBoxFrame
    textBoxFrame.Parent = frame
    frame.Parent = parent

    textBox.Focused:Connect(function() Tween(textBoxFrame.UIStroke, {Color = currentTheme.Accent}, 0.2) end)
    textBox.FocusLost:Connect(function(enterPressed)
        Tween(textBoxFrame.UIStroke, {Color = currentTheme.InElementBorder}, 0.2)
        inputState.Value = textBox.Text
        if opts.callback then pcall(function() opts.callback(inputState.Value) end) end
        -- update SaveManager
        local updateFn = tryRegisterWithSaveManager(parent, opts.id, inputState.Value, function(v)
            inputState.Value = v
            textBox.Text = tostring(v)
        end)
        if updateFn then pcall(function() updateFn(inputState.Value) end) end
    end)

    -- try initial registration so SaveManager can set default
    local updateFn = tryRegisterWithSaveManager(parent, opts.id, inputState.Value, function(v)
        inputState.Value = v
        textBox.Text = tostring(v)
    end)

    return inputState
end

-- CreateLabel (simple)
function SkyeUI:CreateLabel(parent, text, isSubText)
    if not parent then error("CreateLabel requires parent") end
    local lbl = Create("TextLabel", {
        Text = tostring(text or ""),
        Size = UDim2.new(1,0,0,(isSubText and 14 or 16)),
        BackgroundTransparency = 1,
        TextColor3 = isSubText and currentTheme.SubText or currentTheme.Text,
        Font = isSubText and Enum.Font.Gotham or Enum.Font.GothamBold,
        TextSize = isSubText and 12 or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = isSubText and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
    })
    lbl.Parent = parent
    return lbl
end

-- Integration API: Set SaveManager so elements auto-register; SetInterfaceManager to auto-add windows
function SkyeUI:SetSaveManager(saveManager)
    if saveManager == nil then
        _SaveManager = nil
        return true
    end
    assert(type(saveManager) == "table", "SetSaveManager expects a table-like SaveManager")
    _SaveManager = saveManager
    -- inform SaveManager of library (for the Fluent pattern)
    if type(_SaveManager.SetLibrary) == "function" then
        pcall(function() _SaveManager:SetLibrary(self) end)
    end
    return true
end

function SkyeUI:SetInterfaceManager(interfaceManager)
    if interfaceManager == nil then
        _InterfaceManager = nil
        return true
    end
    assert(type(interfaceManager) == "table", "SetInterfaceManager expects a table-like InterfaceManager")
    _InterfaceManager = interfaceManager
    if type(_InterfaceManager.SetLibrary) == "function" then
        pcall(function() _InterfaceManager:SetLibrary(self) end)
    end
    return true
end

-- Convenience: expose ApplyTheme globally
function SkyeUI:SetTheme(name)
    ApplyTheme(name)
end

-- Return module
return setmetatable(SkyeUI, { __index = SkyeUI })
