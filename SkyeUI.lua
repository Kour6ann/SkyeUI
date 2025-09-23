-- SkyeUI (patched v4.3)
-- Patched changes applied in v4.3:
-- - Explicitly initialize ScreenGui.Enabled to true on window creation.
-- - Add AncestryChanged listeners to theme connections to auto-clean when instances leave hierarchy.
-- - Maintain a map of ancillary cleanup connections and ensure they are disconnected on removal.
-- - Tween wrapper now cancels any existing tween on the same instance before creating a new one (prevents flicker).
-- - Tab/background/text changes use Tween for smooth transitions and reuse the Tween helper.
-- - Added reverse focus navigation (Shift+Tab) via focusPrev().
-- - widget:Destroy now removes theme connections recursively for the instance and its children.
-- - window:Destroy removes the window reference from _allWindows to avoid stale entries.
-- - Various small safety checks and more consistent use of RemoveThemeConnectionRecursive.

local SkyeUI = {}
SkyeUI.__index = SkyeUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Constants / Defaults
local DEFAULT_WINDOW_SIZE = UDim2.new(0, 600, 0, 400)
local DEFAULT_WINDOW_POSITION = UDim2.new(0.5, -300, 0.5, -200)
local DEFAULT_THEME = "Sky"
local TWEEN_DEFAULT_DURATION = 0.18
local NOTIFICATION_BASE_LAYOUT_ORDER = 1000

-- Track windows (weak values)
local _allWindows = setmetatable({}, { __mode = "v" })

-- Themes
local Themes = {
    Sky = {
        Background = Color3.fromRGB(240, 248, 255),
        TabBackground = Color3.fromRGB(225, 240, 250),
        TabHover = Color3.fromRGB(215, 230, 245),
        SectionBackground = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(25, 25, 35),
        SelectedText = Color3.fromRGB(255, 255, 255),
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
        FocusOutline = Color3.fromRGB(80,140,200)
    },
    Dark = {
        Background = Color3.fromRGB(30, 30, 40),
        TabBackground = Color3.fromRGB(25, 25, 35),
        TabHover = Color3.fromRGB(45, 45, 55),
        SectionBackground = Color3.fromRGB(40, 40, 50),
        Text = Color3.fromRGB(240, 240, 240),
        SelectedText = Color3.fromRGB(255, 255, 255),
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
        FocusOutline = Color3.fromRGB(120,200,255)
    }
}

-- Utility: Create instance quickly and set properties; children attach after
local function Create(instanceType, properties, children)
    assert(type(instanceType) == "string", "Create: instanceType must be string")
    properties = properties or {}
    local instance = Instance.new(instanceType)
    for property, value in pairs(properties) do
        if property ~= "Parent" then
            pcall(function() instance[property] = value end)
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

-- Active tweens map (weak-keyed) to track and cancel existing tweens per-instance
local _activeTweens = setmetatable({}, { __mode = "k" })

-- Utility: Tween wrapper (cancels existing tween on same instance)
local function Tween(instance, properties, duration, easingStyle, easingDirection)
    if not instance or not instance:IsA("Instance") then return nil end
    -- Cancel any existing tween for this instance
    local existing = _activeTweens[instance]
    if existing and typeof(existing) == "Tween" then
        pcall(function() existing:Cancel() end)
        _activeTweens[instance] = nil
    end

    local tweenInfo = TweenInfo.new(
        duration or TWEEN_DEFAULT_DURATION,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    local ok, tween = pcall(function()
        return TweenService:Create(instance, tweenInfo, properties)
    end)
    if ok and tween then
        _activeTweens[instance] = tween
        tween:Play()
        -- remove from active map when finished (safeguarded)
        spawn(function()
            local success, err = pcall(function()
                tween.Completed:Wait()
            end)
            pcall(function() if _activeTweens[instance] == tween then _activeTweens[instance] = nil end end)
        end)
        return tween
    end
    return nil
end

-- Safe callback wrapper (pcall)
local function safeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[SkyeUI] callback error:", tostring(err))
    end
end

-- Theme management: weak-key table so destroyed instances don't keep references
local themeConnections = setmetatable({}, { __mode = "k" })
-- ancillary table for ancestry changed connections so they can be disconnected later
local themeAncestryConns = setmetatable({}, { __mode = "k" })

local currentTheme = DEFAULT_THEME
local themeVersion = 0 -- increments whenever ApplyTheme runs

-- Theme batching
local _themeBatchCounter = 0
local _pendingThemeApply = false

-- Theme cleanup connection tracking
local _themeCleanupConn = nil
local _activeWindowCount = 0

local function CleanThemeConnections()
    for instance, mapping in pairs(themeConnections) do
        if not (instance and typeof(instance) == "Instance") then
            themeConnections[instance] = nil
            -- also cleanup ancestry conn
            local anc = themeAncestryConns[instance]
            if anc and typeof(anc) == "RBXScriptConnection" then
                pcall(function() anc:Disconnect() end)
            end
            themeAncestryConns[instance] = nil
        end
    end
end

local function ensureThemeCleanupStarted()
    if _themeCleanupConn and _themeCleanupConn.Connected then return end
    local accumulator = 0
    _themeCleanupConn = RunService.Heartbeat:Connect(function(dt)
        accumulator = accumulator + dt
        if accumulator >= 5 then
            CleanThemeConnections()
            accumulator = 0
        end
    end)
end

local function stopThemeCleanupIfIdle()
    if _themeCleanupConn and _themeCleanupConn.Connected and _activeWindowCount <= 0 and _themeBatchCounter == 0 then
        pcall(function() _themeCleanupConn:Disconnect() end)
        _themeCleanupConn = nil
    end
end

-- Batch validators for widgets
local function validateEndBatch(counterName, current)
    if current < 0 then
        warn("[SkyeUI] Batch mismatch detected; resetting counter")
        return 0
    end
    return current
end

-- Public API: batch theme operations
function SkyeUI.BeginThemeBatch()
    _themeBatchCounter = _themeBatchCounter + 1
end
function SkyeUI.EndThemeBatch()
    _themeBatchCounter = validateEndBatch("ThemeBatch", _themeBatchCounter - 1)
    if _themeBatchCounter == 0 and _pendingThemeApply then
        _pendingThemeApply = false
        themeVersion = themeVersion + 1
        local theme = Themes[currentTheme]
        for instance, mapping in pairs(themeConnections) do
            if instance and typeof(instance) == "Instance" then
                for property, key in pairs(mapping) do
                    if theme and theme[key] ~= nil then
                        pcall(function() instance[property] = theme[key] end)
                    end
                end
            else
                themeConnections[instance] = nil
                local anc = themeAncestryConns[instance]
                if anc and typeof(anc) == "RBXScriptConnection" then
                    pcall(function() anc:Disconnect() end)
                end
                themeAncestryConns[instance] = nil
            end
        end
        CleanThemeConnections()
        -- reapply per-window selection visuals after batch apply
        for _, win in ipairs(_allWindows) do
            if win and win.CurrentTab then
                local themeLocal = Themes[currentTheme]
                pcall(function()
                    for name, tab in pairs(win.Tabs or {}) do
                        if tab and tab.Button then
                            if win.CurrentTab == name then
                                Tween(tab.Button, { BackgroundColor3 = themeLocal.Accent }, 0.12)
                                for _, child in ipairs(tab.Button:GetChildren()) do
                                    if child:IsA("TextLabel") then
                                        Tween(child, { TextColor3 = themeLocal.SelectedText }, 0.12)
                                    end
                                end
                            else
                                Tween(tab.Button, { BackgroundColor3 = themeLocal.TabBackground }, 0.12)
                                for _, child in ipairs(tab.Button:GetChildren()) do
                                    if child:IsA("TextLabel") then
                                        Tween(child, { TextColor3 = themeLocal.Text }, 0.12)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
end

local function ApplyThemeImmediate(themeName)
    -- Do not mutate themeVersion here (caller handles increments).
    currentTheme = themeName
    local theme = Themes[themeName]
    for instance, mapping in pairs(themeConnections) do
        if instance and typeof(instance) == "Instance" then
            for property, key in pairs(mapping) do
                if theme and theme[key] ~= nil then
                    pcall(function() instance[property] = theme[key] end)
                end
            end
        else
            themeConnections[instance] = nil
            local anc = themeAncestryConns[instance]
            if anc and typeof(anc) == "RBXScriptConnection" then
                pcall(function() anc:Disconnect() end)
            end
            themeAncestryConns[instance] = nil
        end
    end
    CleanThemeConnections()

    -- Reapply per-window selection visuals so selected tab stays highlighted
    for _, win in ipairs(_allWindows) do
        if win and win.CurrentTab then
            pcall(function()
                for name, tab in pairs(win.Tabs or {}) do
                    if tab and tab.Button then
                        if win.CurrentTab == name then
                            Tween(tab.Button, { BackgroundColor3 = theme.Accent }, 0.12)
                            for _, child in ipairs(tab.Button:GetChildren()) do
                                if child:IsA("TextLabel") then
                                    Tween(child, { TextColor3 = theme.SelectedText }, 0.12)
                                end
                            end
                        else
                            Tween(tab.Button, { BackgroundColor3 = theme.TabBackground }, 0.12)
                            for _, child in ipairs(tab.Button:GetChildren()) do
                                if child:IsA("TextLabel") then
                                    Tween(child, { TextColor3 = theme.Text }, 0.12)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end

local function ApplyTheme(themeName)
    if not Themes[themeName] then
        warn("[SkyeUI] ApplyTheme: theme '" .. tostring(themeName) .. "' not found")
        return
    end
    currentTheme = themeName
    themeVersion = themeVersion + 1
    if _themeBatchCounter > 0 then
        _pendingThemeApply = true
        return
    end
    ApplyThemeImmediate(themeName)
end

local function AddThemeConnection(instance, properties)
    if not instance or type(properties) ~= "table" then return end
    ensureThemeCleanupStarted()
    themeConnections[instance] = properties
    -- AncestryChanged listener: auto-clean if removed from hierarchy to avoid longer waits for heartbeat
    pcall(function()
        if not themeAncestryConns[instance] then
            local conn = instance.AncestryChanged:Connect(function()
                -- if instance no longer belongs to game hierarchy, remove connection mapping
                if not instance:IsDescendantOf(game) then
                    themeConnections[instance] = nil
                    local anc = themeAncestryConns[instance]
                    if anc and typeof(anc) == "RBXScriptConnection" then
                        pcall(function() anc:Disconnect() end)
                    end
                    themeAncestryConns[instance] = nil
                end
            end)
            themeAncestryConns[instance] = conn
        end
    end)
    -- always apply current theme immediately so new elements aren't unstyled in batch mode
    local theme = Themes[currentTheme] or Themes[DEFAULT_THEME]
    for property, key in pairs(properties) do
        if theme and theme[key] ~= nil then
            pcall(function() instance[property] = theme[key] end)
        end
    end
    -- if batching, mark pending for future theme changes
    if _themeBatchCounter > 0 then _pendingThemeApply = true end
end

local function RemoveThemeConnection(instance)
    if not instance then return end
    themeConnections[instance] = nil
    local anc = themeAncestryConns[instance]
    if anc and typeof(anc) == "RBXScriptConnection" then
        pcall(function() anc:Disconnect() end)
    end
    themeAncestryConns[instance] = nil
end

-- Standardized widget helper: new widget object skeleton
local function makeWidget(instance, window)
    local widget = {}
    widget.Instance = instance
    widget._connections = {}
    widget._tweens = {}
    widget._window = window
    widget._isDestroyed = false

    function widget:IsValid()
        return (not self._isDestroyed) and self.Instance and typeof(self.Instance) == 'Instance' and self.Instance.Parent
    end

    function widget:_trackConnection(conn)
        if conn and typeof(conn) == "RBXScriptConnection" then
            table.insert(self._connections, conn)
            if self._window and type(self._window._trackConnection) == "function" then
                pcall(function() self._window:_trackConnection(conn) end)
            end
        end
    end

    function widget:_trackTween(t)
        if t and typeof(t) == "Tween" then
            table.insert(self._tweens, t)
        end
    end

    function widget:DisconnectAll()
        if self._isDestroyed then return end
        for _, c in ipairs(self._connections) do
            pcall(function() if c and typeof(c) == 'RBXScriptConnection' then c:Disconnect() end end)
        end
        self._connections = {}
    end

    function widget:CancelTweens()
        if self._isDestroyed then return end
        for _, t in ipairs(self._tweens) do
            pcall(function() if t and typeof(t) == 'Tween' then t:Cancel() end end)
        end
        self._tweens = {}
    end

    function widget:Destroy()
        if self._isDestroyed then return end
        self._isDestroyed = true
        if self.Instance then RemoveThemeConnectionRecursive(self.Instance) end
        self:DisconnectAll()
        self:CancelTweens()
        if self.Instance and typeof(self.Instance) == "Instance" and self.Instance.Parent then
            pcall(function() self.Instance:Destroy() end)
        end
        self.Instance = nil
        self._window = nil
    end

    return widget
end

-- Validate parent argument -- accept either Instance or a window object (and use its ContentContainer)
local function resolveParentArg(parent, window)
    if not parent then
        if window and window.ContentContainer then
            return window.ContentContainer
        end
        error("Missing parent for element creation")
    end
    if typeof(parent) == "Instance" then
        return parent
    end
    if type(parent) == "table" and parent.ContentContainer and typeof(parent.ContentContainer) == "Instance" then
        if parent.ContentContainer and typeof(parent.ContentContainer) == "Instance" then
            return parent.ContentContainer
        end
    end
    error("Invalid parent: must be an Instance or window-like object")
end

-- Helper: register focusable action (accessibility)
local function registerFocusable(window, inst, activateFn)
    if not window or not inst then return end
    window._focusables = window._focusables or {}
    window._focusMap = window._focusMap or {}
    if window._focusMap[inst] then return end
    local entry = { Instance = inst, Activate = activateFn }
    table.insert(window._focusables, entry)
    window._focusMap[inst] = #window._focusables
    if not inst:FindFirstChild("_SkyeFocus") then
        local focusStroke = Create("UIStroke", { Name = "_SkyeFocus", Thickness = 2, Transparency = 1, Color = Themes[currentTheme].FocusOutline })
        focusStroke.Parent = inst
        -- Theme-connect the stroke color so focus outline follows theme
        AddThemeConnection(focusStroke, { Color = "FocusOutline" })
    end
end
local function unregisterFocusable(window, inst)
    if not window or not inst or not window._focusMap then return end
    local idx = window._focusMap[inst]
    if not idx then return end
    window._focusables[idx] = nil
    window._focusMap[inst] = nil
    local new = {}
    local map = {}
    for i, v in ipairs(window._focusables) do
        if v then
            table.insert(new, v)
            map[v.Instance] = #new
        end
    end
    window._focusables = new
    window._focusMap = map
    local f = inst:FindFirstChild("_SkyeFocus")
    if f then pcall(function() f:Destroy() end) end
end

-- update visual state of registered focusables for a window
local function updateFocusVisual(window)
    if not window or not window._focusables then return end
    for i, e in ipairs(window._focusables) do
        local stroke = e.Instance and e.Instance:FindFirstChild("_SkyeFocus")
        if stroke and stroke:IsA("UIStroke") then
            pcall(function() stroke.Transparency = (i == window._focusIndex) and 0 or 1 end)
        end
    end
end

-- Focus management: cycle focus and activate
local function focusNext(window)
    if not window or not window._focusables or #window._focusables == 0 then return end
    -- skip invisible/disabled ones
    local start = (window._focusIndex or 0)
    local i = start
    repeat
        i = i + 1
        if i > #window._focusables then i = 1 end
        local entry = window._focusables[i]
        if entry and entry.Instance and entry.Instance.Parent and entry.Instance.Visible ~= false then
            window._focusIndex = i
            updateFocusVisual(window)
            if entry.Instance:IsA("TextBox") then
                pcall(function() entry.Instance:CaptureFocus() end)
            end
            return
        end
    until i == start
end

-- Focus management: reverse (Shift+Tab)
local function focusPrev(window)
    if not window or not window._focusables or #window._focusables == 0 then return end
    local start = (window._focusIndex or (#window._focusables + 1))
    local i = start
    repeat
        i = i - 1
        if i < 1 then i = #window._focusables end
        local entry = window._focusables[i]
        if entry and entry.Instance and entry.Instance.Parent and entry.Instance.Visible ~= false then
            window._focusIndex = i
            updateFocusVisual(window)
            if entry.Instance:IsA("TextBox") then
                pcall(function() entry.Instance:CaptureFocus() end)
            end
            return
        end
    until i == start
end

-- Global keyboard handler per-window (tab navigation, activate) + modifier tracking
local function setupWindowAccessibility(window)
    if window._accessConn then return end
    window._modifierState = { Ctrl = false, Alt = false, Shift = false }
    window._accessConn = UserInputService.InputBegan:Connect(function(input, gProcessed)
        if gProcessed then return end
        -- modifier tracking
        if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then window._modifierState.Ctrl = true end
        if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then window._modifierState.Alt = true end
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then window._modifierState.Shift = true end

        if input.KeyCode == Enum.KeyCode.Tab then
            if window._modifierState.Shift then
                focusPrev(window)
            else
                focusNext(window)
            end
        elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA then
            if window._focusIndex and window._focusables and window._focusables[window._focusIndex] then
                local act = window._focusables[window._focusIndex].Activate
                if type(act) == "function" then pcall(act) end
            end
        end
    end)
    local releaseConn = UserInputService.InputEnded:Connect(function(input, gProcessed)
        if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then window._modifierState.Ctrl = false end
        if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then window._modifierState.Alt = false end
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then window._modifierState.Shift = false end
    end)
    window:_trackConnection(window._accessConn)
    window:_trackConnection(releaseConn)
end

-- Helper: HSV math
local function HSVToRGB(h, s, v)
    h = (h % 360 + 360) % 360 -- normalize hue
    local c = v * s
    local x = c * (1 - math.abs(((h / 60) % 2) - 1))
    local m = v - c
    local r,g,b = 0,0,0
    if h < 60 then r,g,b = c,x,0
    elseif h < 120 then r,g,b = x,c,0
    elseif h < 180 then r,g,b = 0,c,x
    elseif h < 240 then r,g,b = 0,x,c
    elseif h < 300 then r,g,b = x,0,c
    else r,g,b = c,0,x end
    return Color3.new(r + m, g + m, b + m)
end

local function RGBToHSV(r,g,b)
    local max = math.max(r,g,b)
    local min = math.min(r,g,b)
    local delta = max - min
    local h = 0
    if delta == 0 then h = 0
    elseif max == r then h = 60 * (((g - b) / delta) % 6)
    elseif max == g then h = 60 * (((b - r) / delta) + 2)
    else h = 60 * (((r - g) / delta) + 4) end
    local s = (max == 0) and 0 or (delta / max)
    local v = max
    return h, s, v
end

-- Utility: Remove a previously added theme connection from its instance (useful during Destroy)
local function RemoveThemeConnectionRecursive(inst)
    if not inst then return end
    RemoveThemeConnection(inst)
    for _, child in ipairs(inst:GetChildren()) do
        RemoveThemeConnectionRecursive(child)
    end
end

-- Main window creation
function SkyeUI:CreateWindow(title)
    title = title or "Skye UI"

    -- ScreenGui (parented to CoreGui)
    local screenGui = Create("ScreenGui", {
        Name = "SkyeUI",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false
    })
    -- Ensure Enabled is explicitly set (avoid nil surprises in some runtimes)
    pcall(function() screenGui.Enabled = true end)

    -- Track everything per-window for cleanup
    local window = {
        ScreenGui = screenGui,
        _connections = {},
        _widgets = {},
        _dropdownOpen = nil,
        _notifyCounter = 0,
        Tabs = {},
        CurrentTab = nil,
        _isMinimized = false,
        _dragState = { dragging = false, offset = Vector2.new(0,0) },
        _focusables = {},
        _focusMap = {},
        _focusIndex = nil,
        _widgetBatchCounter = 0,
        _savedFocusIndex = nil
    }

    setmetatable(window._widgets, { __mode = 'v' })
    setmetatable(window, { __index = SkyeUI })

    -- add to global windows list (weak)
    table.insert(_allWindows, window)

    -- increment active window count and ensure theme cleanup running
    _activeWindowCount = _activeWindowCount + 1
    ensureThemeCleanupStarted()

    function window:_trackConnection(c)
        if c and typeof(c) == "RBXScriptConnection" then
            table.insert(self._connections, c)
        end
    end

    local function trackConnectionLocal(c)
        window:_trackConnection(c)
    end

    -- MainFrame
    local mainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = screenGui,
        Size = DEFAULT_WINDOW_SIZE,
        Position = DEFAULT_WINDOW_POSITION,
        BackgroundColor3 = Themes[DEFAULT_THEME].Background,
        ClipsDescendants = true
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Create("UIStroke", { Color = Themes[DEFAULT_THEME].InElementBorder, Thickness = 1 })
    })
    window.MainFrame = mainFrame
    AddThemeConnection(mainFrame, { BackgroundColor3 = "Background" })
    AddThemeConnection(mainFrame.UIStroke, { Color = "InElementBorder" })

    -- Topbar
    local topbar = Create("Frame", {
        Name = "Topbar",
        Parent = mainFrame,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Themes[DEFAULT_THEME].TabBackground,
        BorderSizePixel = 0
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8), Name = "TopbarCorner" })
    })
    AddThemeConnection(topbar, { BackgroundColor3 = "TabBackground" })
    window.Topbar = topbar

    -- Title label
    local titleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = topbar,
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Themes[DEFAULT_THEME].Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 14
    })
    AddThemeConnection(titleLabel, { TextColor3 = "Text" })

    -- Button container
    local buttonContainer = Create("Frame", {
        Name = "ButtonContainer",
        Parent = topbar,
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -80, 0, 0),
        BackgroundTransparency = 1
    })
    buttonContainer.Parent = topbar

    -- Minimize & Close
    local minimizeButton = Create("TextButton", {
        Name = "MinimizeButton",
        Parent = buttonContainer,
        Size = UDim2.new(0, 36, 0, 24),
        Position = UDim2.new(0, 4, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "-",
        TextColor3 = Themes[DEFAULT_THEME].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16
    })
    AddThemeConnection(minimizeButton, { TextColor3 = "Text" })

    local closeButton = Create("TextButton", {
        Name = "CloseButton",
        Parent = buttonContainer,
        Size = UDim2.new(0, 36, 0, 24),
        Position = UDim2.new(0, 44, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = Themes[DEFAULT_THEME].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14
    })
    AddThemeConnection(closeButton, { TextColor3 = "Text" })

    -- Tab container (left)
    local tabContainer = Create("ScrollingFrame", {
        Name = "TabContainer",
        Parent = mainFrame,
        Size = UDim2.new(0, 140, 1, -40),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
        Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
    })
    window.TabContainer = tabContainer

    -- Content container
    local contentContainer = Create("ScrollingFrame", {
        Name = "ContentContainer",
        Parent = mainFrame,
        Size = UDim2.new(1, -148, 1, -40),
        Position = UDim2.new(0, 148, 0, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) }),
        Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
    })
    window.ContentContainer = contentContainer

    -- Replace deprecated Draggable with custom dragging (with bounds checks)
    do
        local dragging = false
        local dragStart = Vector2.new(0, 0)
        local startPixelPos = Vector2.new(0, 0)

        local inputBeganConn = topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
                startPixelPos = Vector2.new(
                    mainFrame.Position.X.Scale * screenSize.X + mainFrame.Position.X.Offset,
                    mainFrame.Position.Y.Scale * screenSize.Y + mainFrame.Position.Y.Offset
                )
            end
        end)
        trackConnectionLocal(inputBeganConn)

        local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
                local newPixelX = startPixelPos.X + delta.X
                local newPixelY = startPixelPos.Y + delta.Y
                -- bounds checking
                local maxX = math.max(0, screenSize.X - mainFrame.AbsoluteSize.X)
                local maxY = math.max(0, screenSize.Y - mainFrame.AbsoluteSize.Y)
                local clampedX = math.clamp(math.floor(newPixelX + 0.5), 0, maxX)
                local clampedY = math.clamp(math.floor(newPixelY + 0.5), 0, maxY)
                -- set as absolute offsets (top-left anchored)
                pcall(function()
                    mainFrame.Position = UDim2.new(0, clampedX, 0, clampedY)
                end)
            end
        end)
        trackConnectionLocal(inputChangedConn)

        local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        trackConnectionLocal(inputEndedConn)
    end

    -- Button hover animations helper (uses Tween which cancels prior tweens)
    local function setupButtonHover(button)
        if not button then return end
        local enter = button.MouseEnter:Connect(function()
            pcall(function() Tween(button, { TextColor3 = Themes[currentTheme].Accent }, 0.18) end)
        end)
        local leave = button.MouseLeave:Connect(function()
            pcall(function() Tween(button, { TextColor3 = Themes[currentTheme].Text }, 0.18) end)
        end)
        trackConnectionLocal(enter)
        trackConnectionLocal(leave)
    end

    setupButtonHover(minimizeButton)
    setupButtonHover(closeButton)

    -- Notification container (bottom-right)
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
    window.NotificationContainer = notificationContainer

    -- Notify
    function window:Notify(options)
        options = options or {}
        local title = options.Title or "Notification"
        local content = options.Content or ""
        local duration = (type(options.Duration) == "number" and options.Duration) or 5

        self._notifyCounter = self._notifyCounter + 1
        local layoutOrder = NOTIFICATION_BASE_LAYOUT_ORDER + self._notifyCounter

        local notification = Create("Frame", {
            Name = "Notification",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = Themes[currentTheme].SectionBackground,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = layoutOrder
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create("UIStroke", { Color = Themes[currentTheme].InElementBorder, Thickness = 1 }),
            Create("Frame", { Name = "Accent", Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = Themes[currentTheme].Accent, BorderSizePixel = 0 }),
            Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
            Create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 12) })
        })

        local titleLabel = Create("TextLabel", {
            Text = title,
            Size = UDim2.new(1, -4, 0, 18),
            BackgroundTransparency = 1,
            TextColor3 = Themes[currentTheme].Text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local contentLabel = Create("TextLabel", {
            Text = content,
            Size = UDim2.new(1, -4, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = Themes[currentTheme].SubText,
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
        notification.Size = UDim2.new(1, 0, 0, 0)
        Tween(notification, { Size = UDim2.new(1, 0, 0, notification.AbsoluteContentSize.Y) }, 0.24)

        -- Auto remove (guarded)
        task.delay(duration, function()
            pcall(function()
                if not notification or not notification.Parent then return end
                Tween(notification, { Size = UDim2.new(0, 0, 0, 0) }, 0.24)
                task.wait(0.26)
                if notification and notification.Parent then
                    notification:Destroy()
                end
            end)
        end)
    end

    -- Tab management
    function window:AddTab(name)
        assert(type(name) == "string" and #name > 0, "AddTab: name must be non-empty string")
        if self.Tabs[name] then
            warn("[SkyeUI] AddTab: Duplicate tab name '" .. name .. "' - returning existing tab")
            return self.Tabs[name]
        end

        -- Tab button
        local tabButton = Create("TextButton", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Themes[currentTheme].TabBackground,
            Text = "",
            AutoButtonColor = false
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create("TextLabel", {
                Text = name,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3 = Themes[currentTheme].Text,
                Font = Enum.Font.Gotham,
                TextSize = 13
            })
        })

        -- Theme-connect the tab button's base background and label text (we reapply selection below)
        AddThemeConnection(tabButton, { BackgroundColor3 = "TabBackground" })
        local textLabel = nil
        for _, c in ipairs(tabButton:GetChildren()) do
            if c:IsA("TextLabel") then textLabel = c; break end
        end
        if textLabel then AddThemeConnection(textLabel, { TextColor3 = "Text" }) end

        -- Tab content
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
            Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
            Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })
        })

        tabButton.Parent = tabContainer
        tabContent.Parent = contentContainer

        -- Hover & selection (use theme Hover key)
        local hoverConn = tabButton.MouseEnter:Connect(function()
            if self.CurrentTab ~= name then
                pcall(function() Tween(tabButton, { BackgroundColor3 = Themes[currentTheme].TabHover }, 0.18) end)
            end
        end)
        trackConnectionLocal(hoverConn)
        local leaveConn = tabButton.MouseLeave:Connect(function()
            if self.CurrentTab ~= name then
                pcall(function() Tween(tabButton, { BackgroundColor3 = Themes[currentTheme].TabBackground }, 0.18) end)
            end
        end)
        trackConnectionLocal(leaveConn)

        local clickConn = tabButton.MouseButton1Click:Connect(function()
            if self.CurrentTab then
                local prev = self.Tabs[self.CurrentTab]
                if prev and prev.Button and prev.Content then
                    pcall(function()
                        Tween(prev.Button, { BackgroundColor3 = Themes[currentTheme].TabBackground }, 0.12)
                        prev.Content.Visible = false
                        for _, child in ipairs(prev.Button:GetChildren()) do
                            if child:IsA("TextLabel") then
                                Tween(child, { TextColor3 = Themes[currentTheme].Text }, 0.12)
                            end
                        end
                    end)
                end
            end

            self.CurrentTab = name
            if self.Tabs[name] and self.Tabs[name].Button then
                pcall(function() Tween(self.Tabs[name].Button, { BackgroundColor3 = Themes[currentTheme].Accent }, 0.12) end)
            end
            if self.Tabs[name] and self.Tabs[name].Content then
                self.Tabs[name].Content.Visible = true
            end

            for _, child in ipairs(tabButton:GetChildren()) do
                if child:IsA("TextLabel") then
                    pcall(function() Tween(child, { TextColor3 = Themes[currentTheme].SelectedText }, 0.12) end)
                end
            end
        end)
        trackConnectionLocal(clickConn)

        local tabObj = { Button = tabButton, Content = tabContent }
        self.Tabs[name] = tabObj

        if not self.CurrentTab then
            self.CurrentTab = name
            pcall(function()
                Tween(tabButton, { BackgroundColor3 = Themes[currentTheme].Accent }, 0.12)
                tabContent.Visible = true
                for _, child in ipairs(tabButton:GetChildren()) do
                    if child:IsA("TextLabel") then
                        Tween(child, { TextColor3 = Themes[currentTheme].SelectedText }, 0.12)
                    end
                end
            end)
        end

        return tabObj
    end

    -- AddSection accepts tab name string or tab object
    function window:AddSection(tabRef, title)
        assert(type(title) == "string" and #title > 0, "AddSection: title must be non-empty string")
        local tab
        if type(tabRef) == "string" then
            tab = self.Tabs[tabRef]
        elseif type(tabRef) == "table" and tabRef.Content then
            tab = tabRef
        else
            tab = self.Tabs[self.CurrentTab]
        end

        if not tab then
            error("AddSection: tab not found")
        end

        local section = Create("Frame", {
            Name = title,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = Themes[currentTheme].SectionBackground,
            AutomaticSize = Enum.AutomaticSize.Y
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create("UIStroke", { Color = Themes[currentTheme].InElementBorder, Thickness = 1 }),
            Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
            Create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
        })

        local sectionHeader = Create("TextLabel", {
            Text = title,
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            TextColor3 = Themes[currentTheme].SubText,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        AddThemeConnection(section, { BackgroundColor3 = "SectionBackground" })
        AddThemeConnection(section.UIStroke, { Color = "InElementBorder" })
        AddThemeConnection(sectionHeader, { TextColor3 = "SubText" })

        sectionHeader.Parent = section
        section.Parent = tab.Content

        return section
    end

    -- Window: SetTheme
    function window:SetTheme(tname)
        if type(tname) ~= "string" or not Themes[tname] then
            error("SetTheme: invalid theme name")
        end
        ApplyTheme(tname)
    end

    function window:GetTheme()
        return currentTheme
    end

    -- Minimize functions with focus persistence
    function window:IsMinimized()
        return self._isMinimized
    end

    function window:SetMinimized(minimized)
        minimized = not not minimized
        if minimized == self._isMinimized then return end
        if minimized then
            -- save focus index
            self._savedFocusIndex = self._focusIndex
        else
            -- restore focus index if available
            if self._savedFocusIndex then
                self._focusIndex = self._savedFocusIndex
            end
            -- update visuals for focusables after restore
            updateFocusVisual(self)
        end
        self._isMinimized = minimized
        if minimized then
            Tween(mainFrame, { Size = UDim2.new(0, DEFAULT_WINDOW_SIZE.X.Offset, 0, 32) }, 0.20)
            Tween(tabContainer, { Size = UDim2.new(0, 140, 0, 0) }, 0.20)
            Tween(contentContainer, { Size = UDim2.new(1, -148, 0, 0) }, 0.20)
        else
            Tween(mainFrame, { Size = DEFAULT_WINDOW_SIZE }, 0.20)
            Tween(tabContainer, { Size = UDim2.new(0, 140, 1, -40) }, 0.20)
            Tween(contentContainer, { Size = UDim2.new(1, -148, 1, -40) }, 0.20)
        end
    end

    -- Minimize button
    local minimConnection = minimizeButton.MouseButton1Click:Connect(function()
        window:SetMinimized(not window._isMinimized)
    end)
    trackConnectionLocal(minimConnection)

    -- Close button: call window:Destroy()
    local closeConn = closeButton.MouseButton1Click:Connect(function()
        window:Destroy()
    end)
    trackConnectionLocal(closeConn)

    -- Dropdown manager helper (ensures only one open dropdown per window)
    function window:_registerOpenDropdown(dropdownWidget)
        if self._dropdownOpen and self._dropdownOpen ~= dropdownWidget and type(self._dropdownOpen.Close) == "function" then
            pcall(function() self._dropdownOpen:Close() end)
        end
        self._dropdownOpen = dropdownWidget
    end
    function window:_clearOpenDropdown(dropdownWidget)
        if self._dropdownOpen == dropdownWidget then
            self._dropdownOpen = nil
        end
    end

    -- Bind a hotkey to toggle visibility
    function window:BindToggleKey(key, allowFocus)
        assert(type(key) == "string", "BindToggleKey: key must be string (e.g., 'RightControl' or 'P')")
        local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed and not allowFocus then return end
            -- support both "P" or Enum.KeyCode.P string forms
            local match = false
            if input.KeyCode and tostring(input.KeyCode) == ("Enum.KeyCode." .. key) then
                match = true
            elseif Enum.KeyCode[key] and input.KeyCode == Enum.KeyCode[key] then
                match = true
            end
            if match then
                -- ensure Enabled exists
                if screenGui.Enabled == nil then
                    screenGui.Enabled = true
                end
                screenGui.Enabled = not screenGui.Enabled
            end
        end)
        trackConnectionLocal(conn)
        return conn
    end

    -- Widget batching API per-window
    function window:BeginWidgetBatch()
        self._widgetBatchCounter = (self._widgetBatchCounter or 0) + 1
        SkyeUI.BeginThemeBatch()
    end
    function window:EndWidgetBatch()
        self._widgetBatchCounter = validateEndBatch("WidgetBatch", (self._widgetBatchCounter or 0) - 1)
        SkyeUI.EndThemeBatch()
    end

    -- Create advanced ColorPicker (HSV controls: Hue strip + Saturation and Value sliders)
    function window:CreateAdvancedColorPicker(parent, labelText, defaultColor, callback)
        parent = resolveParentArg(parent, window)
        defaultColor = defaultColor or Color3.fromRGB(255,255,255)
        local hr,hg,hb = defaultColor.R, defaultColor.G, defaultColor.B
        local h,s,v = RGBToHSV(hr,hg,hb)
        local hue = h or 0
        local sat = s or 0
        local val = v or 1

        local container = Create("Frame", { Size = UDim2.new(1,0,0,140), BackgroundTransparency = 1 }, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6) }) })
        local lbl = Create("TextLabel", { Text = labelText or "Color", Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].Text, Font = Enum.Font.Gotham, TextSize = 13 })
        lbl.Parent = container

        -- preview (NOT theme-connected so user picks persist)
        local preview = Create("Frame", { Size = UDim2.new(0,60,0,60), BackgroundColor3 = defaultColor, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(0,8) }) })
        preview.Parent = container

        -- hue strip (UIGradient rainbow)
        local hueFrame = Create("Frame", { Size = UDim2.new(1,0,0,16), BackgroundTransparency = 0, BorderSizePixel = 0 })
        hueFrame.Parent = container
        local grad = Create("UIGradient", { Rotation = 0 })
        grad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
        }
        grad.Parent = hueFrame

        local hueKnob = Create("Frame", { Size = UDim2.new(0,12,1,0), Position = UDim2.new((hue%360)/360, -6, 0, 0), BackgroundColor3 = Color3.new(1,1,1) }, { Create("UICorner", { CornerRadius = UDim.new(0,6) }), Create("UIStroke", { Color = Themes[currentTheme].Accent, Thickness = 1 }) })
        hueKnob.Parent = hueFrame

        -- saturation & value sliders (0.1)
        local function makeSliderRow(name, init)
            local row = Create("Frame", { Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1 })
            local label = Create("TextLabel", { Text = name, Size = UDim2.new(0.28,0,1,0), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
            local sliderFrame = Create("Frame", { Size = UDim2.new(0.6,0,0,8), Position = UDim2.new(0.3,0,0.5,-4), BackgroundColor3 = Themes[currentTheme].SliderRail }, { Create("UICorner", { CornerRadius = UDim.new(0,4) }) })
            local fill = Create("Frame", { Size = UDim2.new(init,0,1,0), BackgroundColor3 = Themes[currentTheme].Accent }, { Create("UICorner", { CornerRadius = UDim.new(0,4) }) })
            local knob = Create("Frame", { Size = UDim2.new(0,12,0,12), Position = UDim2.new(init, -6, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255,255,255) }, { Create("UICorner", { CornerRadius = UDim.new(0,6) }), Create("UIStroke", { Color = Themes[currentTheme].Accent, Thickness = 1 }) })
            fill.Parent = sliderFrame; knob.Parent = sliderFrame
            label.Parent = row; sliderFrame.Parent = row
            return { Frame = row, Label = label, Slider = sliderFrame, Fill = fill, Knob = knob }
        end

        local satRow = makeSliderRow("S", sat)
        local valRow = makeSliderRow("V", val)
        satRow.Frame.Parent = container; valRow.Frame.Parent = container

        -- create widget early and track all connections
        local widget = makeWidget(container, window)
        table.insert(window._widgets, widget)
        AddThemeConnection(container, { BackgroundColor3 = "SectionBackground" })
        AddThemeConnection(lbl, { TextColor3 = "Text" })
        -- don't theme preview BackgroundColor3 (user-selected color should persist)
        -- Theme-connect hue knob stroke and slider visuals
        local hueStroke = hueKnob:FindFirstChildOfClass("UIStroke")
        if hueStroke then AddThemeConnection(hueStroke, { Color = "Accent" }) end
        -- slider theme connections
        AddThemeConnection(satRow.Slider, { BackgroundColor3 = "SliderRail" })
        AddThemeConnection(satRow.Fill, { BackgroundColor3 = "Accent" })
        local satKnobStroke = satRow.Knob:FindFirstChildOfClass("UIStroke")
        if satKnobStroke then AddThemeConnection(satKnobStroke, { Color = "Accent" }) end
        AddThemeConnection(valRow.Slider, { BackgroundColor3 = "SliderRail" })
        AddThemeConnection(valRow.Fill, { BackgroundColor3 = "Accent" })
        local valKnobStroke = valRow.Knob:FindFirstChildOfClass("UIStroke")
        if valKnobStroke then AddThemeConnection(valKnobStroke, { Color = "Accent" }) end

        -- update preview using HSVToRGB
        local function updatePreview()
            hue = (hue % 360 + 360) % 360
            local col = HSVToRGB(hue, sat, val)
            pcall(function() preview.BackgroundColor3 = col end)
            safeCall(callback, col)
        end

        -- bind hue interactions
        do
            local dragging = false
            local conn1 = hueFrame.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    local rel = (inp.Position.X - hueFrame.AbsolutePosition.X) / math.max(1, hueFrame.AbsoluteSize.X)
                    hue = math.clamp(rel * 360, 0, 360)
                    hueKnob.Position = UDim2.new((hue%360)/360, -6, 0, 0)
                    updatePreview()
                end
            end)
            local conn2 = UserInputService.InputChanged:Connect(function(inp)
                if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local rel = (inp.Position.X - hueFrame.AbsolutePosition.X) / math.max(1, hueFrame.AbsoluteSize.X)
                    hue = math.clamp(rel * 360, 0, 360)
                    hueKnob.Position = UDim2.new((hue%360)/360, -6, 0, 0)
                    updatePreview()
                end
            end)
            local conn3 = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            widget:_trackConnection(conn1); widget:_trackConnection(conn2); widget:_trackConnection(conn3)
        end

        -- bind sat/val sliders
        local function bindSimpleSlider(sl, valueRef, onChanged)
            local dragging = false
            local conn1 = sl.Slider.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    local rel = (inp.Position.X - sl.Slider.AbsolutePosition.X) / math.max(1, sl.Slider.AbsoluteSize.X)
                    valueRef[1] = math.clamp(rel, 0, 1)
                    sl.Fill.Size = UDim2.new(valueRef[1], 0, 1, 0)
                    sl.Knob.Position = UDim2.new(valueRef[1], -6, 0.5, -6)
                    if onChanged then onChanged() end
                end
            end)
            local conn2 = UserInputService.InputChanged:Connect(function(inp)
                if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local rel = (inp.Position.X - sl.Slider.AbsolutePosition.X) / math.max(1, sl.Slider.AbsoluteSize.X)
                    valueRef[1] = math.clamp(rel, 0, 1)
                    sl.Fill.Size = UDim2.new(valueRef[1], 0, 1, 0)
                    sl.Knob.Position = UDim2.new(valueRef[1], -6, 0.5, -6)
                    if onChanged then onChanged() end
                end
            end)
            local conn3 = UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
            widget:_trackConnection(conn1); widget:_trackConnection(conn2); widget:_trackConnection(conn3)
            return { conn1, conn2, conn3 }
        end

        local satChanged = function() sat = satRow.Slider.Fill.Size.X.Scale; updatePreview() end
        local valChanged = function() val = valRow.Slider.Fill.Size.X.Scale; updatePreview() end
        bindSimpleSlider(satRow, {sat}, satChanged)
        bindSimpleSlider(valRow, {val}, valChanged)

        -- register focusable for preview
        registerFocusable(window, preview, function() end)

        container.Parent = parent
        return {
            Instance = container,
            GetColor = function() if container and container.Parent then return HSVToRGB(hue, sat, val) end end,
            SetColor = function(c) if not (c and typeof(c) == 'Color3') then return end local rh,rs,rv = RGBToHSV(c.R, c.G, c.B); hue = (rh%360); sat = rs; val = rv; hueKnob.Position = UDim2.new((hue%360)/360, -6, 0, 0); satRow.Fill.Size = UDim2.new(sat,0,1,0); satRow.Knob.Position = UDim2.new(sat, -6, 0.5, -6); valRow.Fill.Size = UDim2.new(val,0,1,0); valRow.Knob.Position = UDim2.new(val, -6, 0.5, -6); updatePreview() end,
            Destroy = function() widget:Destroy() end
        }
    end

    -- Create enhanced Keybind widget (capture modifiers using window modifier state)
    function window:CreateKeybindEx(parent, labelText, defaultBind, callback)
        parent = resolveParentArg(parent, window)
        local bind = defaultBind or { Key = "None", Ctrl = false, Alt = false, Shift = false }
        local function formatBind(b)
            local parts = {}
            if b.Ctrl then table.insert(parts, "Ctrl") end
            if b.Alt then table.insert(parts, "Alt") end
            if b.Shift then table.insert(parts, "Shift") end
            if b.Key and b.Key ~= "None" then table.insert(parts, tostring(b.Key)) end
            if #parts == 0 then return "None" end
            return table.concat(parts, "+")
        end

        local frame = Create("Frame", { Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1 })
        local label = Create("TextLabel", { Text = labelText or "Keybind", Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1, TextColor3 = Themes[currentTheme].Text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
        local button = Create("TextButton", { Size = UDim2.new(0.35,0,0.8,0), Position = UDim2.new(0.65,0,0.1,0), Text = formatBind(bind), AutoButtonColor = false, BackgroundColor3 = Themes[currentTheme].SectionBackground }, { Create("UICorner", { CornerRadius = UDim.new(0,6) }) })
        label.Parent = frame; button.Parent = frame; frame.Parent = parent

        local widget = makeWidget(frame, window)
        table.insert(window._widgets, widget)
        AddThemeConnection(button, { BackgroundColor3 = "SectionBackground" })
        AddThemeConnection(label, { TextColor3 = "Text" })

        local listening = false
        local conn = nil
        local function startListen()
            if listening then return end
            listening = true
            button.Text = "..."
            conn = UserInputService.InputBegan:Connect(function(input, processed)
                if processed then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    local code = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                    -- use window modifier state for reliability
                    local ctrl = window._modifierState and window._modifierState.Ctrl or (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl))
                    local alt = window._modifierState and window._modifierState.Alt or (UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt))
                    local shift = window._modifierState and window._modifierState.Shift or (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift))
                    bind = { Key = code, Ctrl = ctrl, Alt = alt, Shift = shift }
                    button.Text = formatBind(bind)
                    safeCall(callback, bind)
                    listening = false
                    pcall(function() conn:Disconnect() end)
                end
            end)
            widget:_trackConnection(conn)
        end

        button.MouseButton1Click:Connect(function()
            if listening then
                listening = false
                button.Text = formatBind(bind)
            else
                startListen()
            end
        end)

        registerFocusable(window, button, function() startListen() end)

        return {
            Instance = frame,
            GetBind = function() if widget:IsValid() then return bind end end,
            SetBind = function(b) if widget:IsValid() then bind = b; button.Text = formatBind(bind) end end,
            Destroy = function() widget:Destroy() end
        }
    end

    -- Global Destroy function: destroys screenGui and disconnects everything
    function window:Destroy()
        -- Disconnect window-input handlers and any other connections
        for _, c in ipairs(self._connections) do
            pcall(function() if c and typeof(c) == 'RBXScriptConnection' then c:Disconnect() end end)
        end
        self._connections = {}

        -- Destroy all widgets created for this window
        for _, w in ipairs(self._widgets) do
            if type(w.Destroy) == "function" then
                pcall(function() w:Destroy() end)
            end
        end
        self._widgets = {}

        -- Remove theme connections for window-level instances (MainFrame, etc.)
        -- (this avoids leaking references)
        RemoveThemeConnectionRecursive(self.MainFrame)
        RemoveThemeConnectionRecursive(self.Topbar)
        RemoveThemeConnectionRecursive(self.TabContainer)
        RemoveThemeConnectionRecursive(self.ContentContainer)

        if screenGui and screenGui.Parent then
            pcall(function() screenGui:Destroy() end)
        end

        self._dropdownOpen = nil

        -- Remove this window from _allWindows to avoid stale entries
        for i, w in ipairs(_allWindows) do
            if w == self then
                table.remove(_allWindows, i)
                break
            end
        end

        _activeWindowCount = math.max(0, _activeWindowCount - 1)
        stopThemeCleanupIfIdle()
    end

    -- Apply initial theme
    ApplyTheme(currentTheme)

    -- Setup accessibility + modifier tracking
    setupWindowAccessibility(window)

    return window
end

return SkyeUI
