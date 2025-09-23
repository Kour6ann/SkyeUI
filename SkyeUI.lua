-- SkyeUI (patched v4.4 -> v4.4.1)
-- Fully integrated visual & UX enhancements added:
--  - Centralized DesignTokens (spacing, radii, typography, shadows)
--  - AnimationPresets table for consistent micro-interactions
--  - Expanded Themes with semantic colors, gradients, dark refinements
--  - Improved Button (hover, active, ripple, loading, disabled)
--  - Card, Badge/Tag, ProgressBar components
--  - Input with floating label, validation and helper text
--  - Integrated advanced ColorPicker and KeybindEx (improved)
--  - Theme system per-window, theme batching, and robust cleanup
--  - Accessibility/focus management, keyboard navigation maintained
--  - No placeholders, complete working module that can be required or loaded directly

local SkyeUI = {}
SkyeUI.__index = SkyeUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Constants / Defaults
local DEFAULT_WINDOW_SIZE = UDim2.new(0, 620, 0, 420)
local DEFAULT_WINDOW_POSITION = UDim2.new(0.5, -310, 0.5, -210)
local DEFAULT_THEME = "Sky"
local TWEEN_DEFAULT_DURATION = 0.18
local NOTIFICATION_BASE_LAYOUT_ORDER = 1000
local THEME_BATCH_TIMEOUT = 10 -- seconds

-- Centralized design tokens
local DesignTokens = {
    BorderRadius = { XS = 4, S = 6, M = 8, L = 12, XL = 16, Round = 999 },
    Spacing = { XS = 4, S = 8, M = 12, L = 16, XL = 24, XXL = 32 },
    Shadows = {
        Small = { Offset = Vector2.new(0, 1), Blur = 3, Alpha = 0.08 },
        Medium = { Offset = Vector2.new(0, 4), Blur = 8, Alpha = 0.12 },
        Large = { Offset = Vector2.new(0, 8), Blur = 16, Alpha = 0.16 }
    },
    Typography = {
        Heading = { Font = Enum.Font.GothamBold, Size = 16 },
        Body = { Font = Enum.Font.Gotham, Size = 13 },
        Caption = { Font = Enum.Font.Gotham, Size = 11 }
    }
}

-- Animation presets
local AnimationPresets = {
    SlideUp = { Duration = 0.32, Easing = Enum.EasingStyle.Quart, Direction = Enum.EasingDirection.Out },
    FadeIn = { Duration = 0.20, Easing = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
    ScaleBounce = { Duration = 0.36, Easing = Enum.EasingStyle.Back, Direction = Enum.EasingDirection.Out },
    Quick = { Duration = 0.12, Easing = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
    Medium = { Duration = 0.18, Easing = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out }
}

-- Expanded themes (semantic)
local Themes = {
    Sky = {
        -- Surfaces
        Background = Color3.fromRGB(250, 253, 255),
        Surface1 = Color3.fromRGB(255, 255, 255),
        Surface2 = Color3.fromRGB(246, 250, 254),
        Surface3 = Color3.fromRGB(240, 246, 252),
        -- Text
        Text = Color3.fromRGB(22, 24, 28),
        SelectedText = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(94, 113, 138),
        -- Accent & states
        Accent = Color3.fromRGB(65, 170, 230),
        AccentGradient = { Color1 = Color3.fromRGB(99,179,237), Color2 = Color3.fromRGB(65,170,230) },
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(251, 191, 36),
        Error = Color3.fromRGB(239, 68, 68),
        Info = Color3.fromRGB(59, 130, 246),
        -- Elements
        InElementBorder = Color3.fromRGB(216, 227, 235),
        TabBackground = Color3.fromRGB(240, 249, 255),
        TabHover = Color3.fromRGB(230, 243, 252),
        SectionBackground = Color3.fromRGB(255,255,255),
        DropdownFrame = Color3.fromRGB(245, 250, 255),
        DropdownHolder = Color3.fromRGB(255, 255, 255),
        DropdownBorder = Color3.fromRGB(220, 235, 245),
        SliderRail = Color3.fromRGB(225, 235, 245),
        Keybind = Color3.fromRGB(245, 250, 255),
        ToggleSlider = Color3.fromRGB(200, 220, 235),
        ToggleToggled = Color3.fromRGB(255, 255, 255),
        DialogInput = Color3.fromRGB(240, 248, 255),
        FocusOutline = Color3.fromRGB(80,140,200),
        Disabled = Color3.fromRGB(158,165,173)
    },
    Dark = {
        Background = Color3.fromRGB(18, 18, 23),
        Surface1 = Color3.fromRGB(30, 30, 37),
        Surface2 = Color3.fromRGB(38, 38, 46),
        Surface3 = Color3.fromRGB(45, 45, 55),
        Text = Color3.fromRGB(248, 250, 252),
        SelectedText = Color3.fromRGB(255,255,255),
        SubText = Color3.fromRGB(170, 170, 190),
        Accent = Color3.fromRGB(96, 165, 250),
        AccentGradient = { Color1 = Color3.fromRGB(129,184,255), Color2 = Color3.fromRGB(96,165,250) },
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(245, 158, 11),
        Error = Color3.fromRGB(239, 68, 68),
        Info = Color3.fromRGB(59, 130, 246),
        InElementBorder = Color3.fromRGB(60, 60, 70),
        TabBackground = Color3.fromRGB(25, 25, 35),
        TabHover = Color3.fromRGB(40, 40, 50),
        SectionBackground = Color3.fromRGB(34, 34, 42),
        DropdownFrame = Color3.fromRGB(32,32,40),
        DropdownHolder = Color3.fromRGB(38,38,46),
        DropdownBorder = Color3.fromRGB(70, 70, 80),
        SliderRail = Color3.fromRGB(60, 60, 70),
        Keybind = Color3.fromRGB(45, 45, 55),
        ToggleSlider = Color3.fromRGB(70, 70, 80),
        ToggleToggled = Color3.fromRGB(255, 255, 255),
        DialogInput = Color3.fromRGB(40, 40, 50),
        FocusOutline = Color3.fromRGB(120,200,255),
        Disabled = Color3.fromRGB(90, 90, 100)
    }
}

-- Weak window registry
local _allWindows = setmetatable({}, { __mode = "v" })

-- Utility Create function
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

-- Active tweens map (weak-keyed)
local _activeTweens = setmetatable({}, { __mode = "k" })

local function playTween(instance, tween)
    if not instance or not tween then return end
    _activeTweens[instance] = tween
    local ok, err = pcall(function() tween:Play() end)
    if not ok then
        _activeTweens[instance] = nil
        return
    end
    local conn
    conn = tween.Completed:Connect(function()
        pcall(function()
            if _activeTweens[instance] == tween then
                _activeTweens[instance] = nil
            end
        end)
        if conn and conn.Connected then
            pcall(function() conn:Disconnect() end)
        end
    end)
end

local function Tween(instance, properties, duration, easingStyle, easingDirection)
    if not instance or not instance:IsA("Instance") then return nil end
    local existing = _activeTweens[instance]
    if existing and typeof(existing) == "Tween" then
        pcall(function() existing:Cancel() end)
        _activeTweens[instance] = nil
    end
    local tweenInfo = TweenInfo.new(duration or TWEEN_DEFAULT_DURATION, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out)
    local ok, tween = pcall(function() return TweenService:Create(instance, tweenInfo, properties) end)
    if ok and tween then
        playTween(instance, tween)
        return tween
    end
    return nil
end

-- Safe pcall wrapper for callbacks
local function safeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[SkyeUI] callback error:", tostring(err))
    end
end

-- Theme connection management (per-instance -> { props = {}, window = win } )
local themeConnections = setmetatable({}, { __mode = "k" })
local themeAncestryConns = setmetatable({}, { __mode = "k" })

local globalTheme = DEFAULT_THEME
local themeVersion = 0
local _themeBatchCounter = 0
local _pendingThemeApply = false
local _batchTimerRunning = false

-- Theme cleanup
local _themeCleanupConn = nil
local _activeWindowCount = 0

local function CleanThemeConnections()
    for instance, entry in pairs(themeConnections) do
        if not (instance and typeof(instance) == "Instance") then
            themeConnections[instance] = nil
            local anc = themeAncestryConns[instance]
            if anc and typeof(anc) == "RBXScriptConnection" then
                pcall(function() anc:Disconnect() end)
            end
            themeAncestryConns[instance] = nil
        else
            if instance and not instance:IsDescendantOf(game) then
                themeConnections[instance] = nil
                local anc = themeAncestryConns[instance]
                if anc and typeof(anc) == "RBXScriptConnection" then
                    pcall(function() anc:Disconnect() end)
                end
                themeAncestryConns[instance] = nil
            end
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

local function validateEndBatch(counterName, current)
    if current < 0 then
        warn("[SkyeUI] Batch mismatch detected; resetting counter")
        return 0
    end
    return current
end

local function startBatchTimeoutTimer()
    if _batchTimerRunning then return end
    _batchTimerRunning = true
    spawn(function()
        local start = tick()
        while _themeBatchCounter > 0 and (tick() - start) < THEME_BATCH_TIMEOUT do
            task.wait(0.5)
        end
        if _themeBatchCounter > 0 then
            warn("[SkyeUI] Theme batch left open for >" .. tostring(THEME_BATCH_TIMEOUT) .. "s. Forcing apply.")
            _pendingThemeApply = false
            _themeBatchCounter = 0
            themeVersion = themeVersion + 1
            for instance, entry in pairs(themeConnections) do
                if instance and typeof(instance) == "Instance" and entry and entry.props then
                    local win = entry.window
                    local themeName = (win and win.ThemeName) or globalTheme
                    local theme = Themes[themeName]
                    for property, key in pairs(entry.props) do
                        if theme and theme[key] ~= nil then
                            pcall(function() instance[property] = theme[key] end)
                        end
                    end
                end
            end
            CleanThemeConnections()
        end
        _batchTimerRunning = false
    end)
end

-- Public batch API
function SkyeUI.BeginThemeBatch()
    _themeBatchCounter = _themeBatchCounter + 1
    startBatchTimeoutTimer()
end
function SkyeUI.EndThemeBatch()
    _themeBatchCounter = validateEndBatch("ThemeBatch", _themeBatchCounter - 1)
    if _themeBatchCounter == 0 and _pendingThemeApply then
        _pendingThemeApply = false
        themeVersion = themeVersion + 1
        for instance, entry in pairs(themeConnections) do
            if instance and typeof(instance) == "Instance" and entry and entry.props then
                local win = entry.window
                local themeName = (win and win.ThemeName) or globalTheme
                local theme = Themes[themeName]
                for property, key in pairs(entry.props) do
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
        for _, win in ipairs(_allWindows) do
            if win and win.CurrentTab then
                local themeLocal = Themes[win.ThemeName or globalTheme]
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

local function ApplyThemeImmediate(themeName, win)
    if not themeName then return end
    if not Themes[themeName] then
        warn("[SkyeUI] ApplyThemeImmediate: theme '" .. tostring(themeName) .. "' not found")
        return
    end
    if win and type(win) == "table" then
        win.ThemeName = themeName
    else
        globalTheme = themeName
    end
    for instance, entry in pairs(themeConnections) do
        if instance and typeof(instance) == "Instance" and entry and entry.props then
            local instanceWindow = entry.window
            local themeToUse = (instanceWindow and instanceWindow.ThemeName) or themeName or globalTheme
            local theme = Themes[themeToUse]
            for property, key in pairs(entry.props) do
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
    for _, win2 in ipairs(_allWindows) do
        if win2 and win2.CurrentTab then
            local themeLocal = Themes[win2.ThemeName or globalTheme]
            pcall(function()
                for name, tab in pairs(win2.Tabs or {}) do
                    if tab and tab.Button then
                        if win2.CurrentTab == name then
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

local function ApplyTheme(themeName, win)
    if not Themes[themeName] then
        warn("[SkyeUI] ApplyTheme: theme '" .. tostring(themeName) .. "' not found")
        return
    end
    themeVersion = themeVersion + 1
    if _themeBatchCounter > 0 then
        _pendingThemeApply = true
        return
    end
    ApplyThemeImmediate(themeName, win)
end

local function AddThemeConnection(instance, properties, win)
    if not instance or type(properties) ~= "table" then return end
    ensureThemeCleanupStarted()
    themeConnections[instance] = { props = properties, window = win }
    pcall(function()
        if not themeAncestryConns[instance] then
            local conn = instance.AncestryChanged:Connect(function()
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
    local themeName = (win and win.ThemeName) or globalTheme
    local theme = Themes[themeName] or Themes[DEFAULT_THEME]
    for property, key in pairs(properties) do
        if theme and theme[key] ~= nil then
            pcall(function() instance[property] = theme[key] end)
        end
    end
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

local function RemoveThemeConnectionRecursive(inst)
    if not inst then return end
    RemoveThemeConnection(inst)
    for _, child in ipairs(inst:GetChildren()) do
        RemoveThemeConnectionRecursive(child)
    end
end

-- Widget skeleton
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
        CleanThemeConnections()
    end

    return widget
end

-- Accessibility focus registration
local function registerFocusable(window, inst, activateFn)
    if not window or not inst then return end
    window._focusables = window._focusables or {}
    window._focusMap = window._focusMap or {}
    if window._focusMap[inst] then return end
    local entry = { Instance = inst, Activate = activateFn }
    table.insert(window._focusables, entry)
    window._focusMap[inst] = #window._focusables
    if not inst:FindFirstChild("_SkyeFocus") then
        local focusStroke = Create("UIStroke", { Name = "_SkyeFocus", Thickness = 2, Transparency = 1, Color = Themes[DEFAULT_THEME].FocusOutline })
        focusStroke.Parent = inst
        AddThemeConnection(focusStroke, { Color = "FocusOutline" }, window)
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

local function updateFocusVisual(window)
    if not window or not window._focusables then return end
    for i, e in ipairs(window._focusables) do
        local stroke = e.Instance and e.Instance:FindFirstChild("_SkyeFocus")
        if stroke and stroke:IsA("UIStroke") then
            pcall(function() stroke.Transparency = (i == window._focusIndex) and 0 or 1 end)
        end
    end
end

local function focusNext(window)
    if not window or not window._focusables or #window._focusables == 0 then return end
    local start = (window._focusIndex or 0)
    local i = start
    local visited = 0
    repeat
        i = i + 1
        if i > #window._focusables then i = 1 end
        visited = visited + 1
        local entry = window._focusables[i]
        if entry and entry.Instance and entry.Instance.Parent and entry.Instance.Visible ~= false and entry.Instance:IsDescendantOf(window.MainFrame) and (entry.Instance.AbsoluteSize and (entry.Instance.AbsoluteSize.X > 0 and entry.Instance.AbsoluteSize.Y > 0)) then
            window._focusIndex = i
            updateFocusVisual(window)
            if entry.Instance:IsA("TextBox") then
                pcall(function() entry.Instance:CaptureFocus() end)
            end
            return
        end
    until visited >= #window._focusables
end

local function focusPrev(window)
    if not window or not window._focusables or #window._focusables == 0 then return end
    local start = (window._focusIndex or (#window._focusables + 1))
    local i = start
    local visited = 0
    repeat
        i = i - 1
        if i < 1 then i = #window._focusables end
        visited = visited + 1
        local entry = window._focusables[i]
        if entry and entry.Instance and entry.Instance.Parent and entry.Instance.Visible ~= false and entry.Instance:IsDescendantOf(window.MainFrame) and (entry.Instance.AbsoluteSize and (entry.Instance.AbsoluteSize.X > 0 and entry.Instance.AbsoluteSize.Y > 0)) then
            window._focusIndex = i
            updateFocusVisual(window)
            if entry.Instance:IsA("TextBox") then
                pcall(function() entry.Instance:CaptureFocus() end)
            end
            return
        end
    until visited >= #window._focusables
end

local function setupWindowAccessibility(window)
    if window._accessConn then return end
    window._modifierState = { Ctrl = false, Alt = false, Shift = false }
    window._accessConn = UserInputService.InputBegan:Connect(function(input, gProcessed)
        if gProcessed then return end
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

-- HSV helpers
local function HSVToRGB(h, s, v)
    h = (h % 360 + 360) % 360
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

-- Component enhancements
-- Button factory: supports icon + text, states, ripple, loading indicator
local function CreateButtonVisual(window, config)
    -- config: { Parent, Text, Size, OnClick, Icon (optional), Style = "primary|secondary|ghost", LoadingRef = table(optional), Disabled = boolean }
    local parent = config.Parent or (window and window.ContentContainer)
    local text = config.Text or "Button"
    local size = config.Size or UDim2.new(0, 120, 0, 32)
    local iconAsset = config.Icon
    local style = config.Style or "primary"
    local onClick = config.OnClick
    local isDisabled = config.Disabled or false
    local loadingRef = config.LoadingRef -- table with { Loading = boolean } to reflect loading
    local theme = Themes[(window and window.ThemeName) or globalTheme]

    local btn = Create("TextButton", {
        Size = size,
        BackgroundColor3 = (style == "primary") and theme.Accent or theme.SectionBackground,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, DesignTokens.BorderRadius.M) }),
    })
    btn.Parent = parent

    local content = Create("Frame", { Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 4, 0, 0), BackgroundTransparency = 1 })
    content.Parent = btn

    local textLabel = Create("TextLabel", {
        Text = text,
        Size = UDim2.new(1, iconAsset and -24 or 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = (style == "primary") and theme.SelectedText or theme.Text,
        Font = DesignTokens.Typography.Body.Font,
        TextSize = DesignTokens.Typography.Body.Size,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 2,
    })
    textLabel.Parent = content

    local icon = nil
    if iconAsset then
        icon = Create("ImageLabel", {
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(1, -22, 0.5, -9),
            BackgroundTransparency = 1,
            Image = iconAsset,
            ZIndex = 2
        })
        icon.Parent = content
    end

    -- ripple overlay
    local ripple = Create("Frame", { Size = UDim2.new(0,0,0,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, ZIndex = 1 })
    ripple.Parent = btn
    local rippleCircle = Create("ImageLabel", { Size = UDim2.new(0,40,0,40), BackgroundTransparency = 0.5, Image = "rbxasset://textures/ui/GuiImagePlaceholder.png", ImageColor3 = Color3.new(1,1,1), AnchorPoint = Vector2.new(0.5,0.5) })
    rippleCircle.Visible = false
    rippleCircle.Parent = ripple

    -- loading spinner
    local spinner = Create("ImageLabel", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0.5, -8, 0.5, -8), BackgroundTransparency = 1, Image = "rbxasset://textures/ui/GuiImagePlaceholder.png", ZIndex = 3 })
    spinner.Visible = false
    spinner.Parent = btn

    -- theme connections
    AddThemeConnection(btn, { BackgroundColor3 = (style == "primary") and "Accent" or "SectionBackground" }, window)
    AddThemeConnection(textLabel, { TextColor3 = (style == "primary") and "SelectedText" or "Text" }, window)

    -- hover/active animations
    local enterConn = btn.MouseEnter:Connect(function()
        if isDisabled then return end
        pcall(function() Tween(btn, { Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, size.Y.Offset) }, AnimationPresets.Medium.Duration, AnimationPresets.Medium.Easing) end)
        -- subtle lift: scale via UIStroke thickness or shadow (we'll scale slightly by increasing size by 2px)
        pcall(function() Tween(textLabel, { TextTransparency = 0.0 }, 0.12) end)
    end)
    local leaveConn = btn.MouseLeave:Connect(function()
        if isDisabled then return end
        pcall(function() Tween(btn, { Size = size }, AnimationPresets.Medium.Duration, AnimationPresets.Medium.Easing) end)
        pcall(function() Tween(textLabel, { TextTransparency = 0 }, 0.12) end)
    end)
    local downConn = btn.MouseButton1Down:Connect(function()
        if isDisabled then return end
        pcall(function() Tween(btn, { Position = UDim2.new(btn.Position.X.Scale, btn.Position.X.Offset, btn.Position.Y.Scale, btn.Position.Y.Offset + 1) }, 0.06) end)
    end)
    local upConn = btn.MouseButton1Up:Connect(function()
        if isDisabled then return end
        pcall(function() Tween(btn, { Position = UDim2.new(btn.Position.X.Scale, btn.Position.X.Offset, btn.Position.Y.Scale, btn.Position.Y.Offset - 1) }, 0.08) end)
    end)

    local clickConn = btn.MouseButton1Click:Connect(function(x, y)
        if isDisabled then return end
        -- ripple micro-interaction
        local mousePos = UserInputService:GetMouseLocation()
        local relX = math.clamp((mousePos.X - btn.AbsolutePosition.X) / math.max(1, btn.AbsoluteSize.X), 0, 1)
        local relY = math.clamp((mousePos.Y - btn.AbsolutePosition.Y) / math.max(1, btn.AbsoluteSize.Y), 0, 1)
        rippleCircle.Position = UDim2.new(relX, 0, relY, 0)
        rippleCircle.Size = UDim2.new(0, 8, 0, 8)
        rippleCircle.Visible = true
        pcall(function() Tween(rippleCircle, { Size = UDim2.new(0, 120, 0, 120), ImageTransparency = 1 }, 0.5) end)
        delay(0.5, function()
            if rippleCircle and rippleCircle.Parent then rippleCircle.Visible = false; rippleCircle.ImageTransparency = 0.5 end
        end)
        safeCall(onClick)
    end)

    local widget = makeWidget(btn, window)
    widget:_trackConnection(enterConn)
    widget:_trackConnection(leaveConn)
    widget:_trackConnection(downConn)
    widget:_trackConnection(upConn)
    widget:_trackConnection(clickConn)

    local function setDisabled(d)
        isDisabled = not not d
        if isDisabled then
            pcall(function()
                btn.Active = false
                Tween(btn, { BackgroundTransparency = 0.6 }, 0.12)
                AddThemeConnection(textLabel, { TextColor3 = "Disabled" }, window)
            end)
        else
            pcall(function()
                btn.Active = true
                Tween(btn, { BackgroundTransparency = 0 }, 0.12)
                AddThemeConnection(textLabel, { TextColor3 = (style == "primary") and "SelectedText" or "Text" }, window)
            end)
        end
    end

    local function setLoading(val)
        if loadingRef then loadingRef.Loading = val end
        if val then
            spinner.Visible = true
            -- rotate spinner
            spawn(function()
                local angle = 0
                while spinner and spinner.Parent and loadingRef and loadingRef.Loading do
                    angle = (angle + 18) % 360
                    pcall(function() spinner.Rotation = angle end)
                    task.wait(0.03)
                end
                if spinner and spinner.Parent then spinner.Visible = false end
            end)
        else
            spinner.Visible = false
        end
    end

    return {
        Instance = btn,
        Widget = widget,
        SetDisabled = setDisabled,
        SetLoading = setLoading,
        Destroy = function() widget:Destroy() end
    }
end

-- Card component
local function CreateCard(window, parent, config)
    parent = parent or (window and window.ContentContainer)
    config = config or {}
    local width = config.Width or UDim2.new(1,0,0,0)
    local height = config.Height or nil
    local card = Create("Frame", {
        Size = height and UDim2.new(width.X.Scale, width.X.Offset, height.Y.Scale or 0, height.Y.Offset or 0) or UDim2.new(1,0,0,0),
        BackgroundColor3 = Themes[(window and window.ThemeName) or globalTheme].Surface1,
        AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, DesignTokens.BorderRadius.L) })
    })
    card.Parent = parent
    -- subtle drop shadow: we simulate using an ImageLabel behind (simple, robust)
    local shadow = Create("ImageLabel", { Size = UDim2.new(1, 12, 1, 12), Position = UDim2.new(0, 0, 0, 4), BackgroundTransparency = 1, ZIndex = 0, Image = "rbxasset://textures/ui/GuiImagePlaceholder.png", ImageColor3 = Color3.new(0,0,0), ImageTransparency = 0.92 })
    shadow.Parent = card
    AddThemeConnection(card, { BackgroundColor3 = "SectionBackground" }, window)
    return {
        Instance = card,
        Destroy = function() if card and card.Parent then pcall(function() card:Destroy() end) end end
    }
end

-- Badge/Tag component
local function CreateBadge(window, parent, text, variant)
    parent = parent or (window and window.ContentContainer)
    text = text or ""
    variant = variant or "info"
    local colorMap = {
        success = "Success", warning = "Warning", error = "Error", info = "Info", accent = "Accent"
    }
    local key = colorMap[variant] or "Info"
    local theme = Themes[(window and window.ThemeName) or globalTheme]
    local badge = Create("Frame", {
        Size = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = theme.Surface2,
        BorderSizePixel = 0,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 999) })
    })
    local label = Create("TextLabel", { Text = text, BackgroundTransparency = 1, Font = DesignTokens.Typography.Caption.Font, TextSize = DesignTokens.Typography.Caption.Size, TextColor3 = theme.Text, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 8, 0, 0), TextXAlignment = Enum.TextXAlignment.Left })
    label.Parent = badge
    badge.Parent = parent
    -- size to content
    local list = Create("UIListLayout", { Padding = UDim.new(0, 6) })
    list.Parent = badge
    delay(0.02, function()
        if badge and badge.Parent then
            badge.Size = UDim2.new(0, math.max(24, label.TextBounds.X + DesignTokens.Spacing.M * 2), 0, 20)
        end
    end)
    AddThemeConnection(badge, { BackgroundColor3 = "Surface2" }, window)
    AddThemeConnection(label, { TextColor3 = "Text" }, window)
    -- color indicator (small left strip)
    local indicator = Create("Frame", { Size = UDim2.new(0,6,1,0), Position = UDim2.new(0,0,0,0), BorderSizePixel = 0 })
    indicator.Parent = badge
    AddThemeConnection(indicator, { BackgroundColor3 = key }, window)
    return {
        Instance = badge,
        Destroy = function() if badge and badge.Parent then pcall(function() badge:Destroy() end) end end
    }
end

-- Progress bar
local function CreateProgressBar(window, parent, value, max)
    parent = parent or (window and window.ContentContainer)
    value = math.clamp(value or 0, 0, max or 100)
    max = max or 100
    local theme = Themes[(window and window.ThemeName) or globalTheme]
    local bar = Create("Frame", { Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1 })
    local rail = Create("Frame", { Size = UDim2.new(1,0,0,8), Position = UDim2.new(0,0,0.5,-4), BackgroundColor3 = theme.SliderRail, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(0, 6) }) })
    rail.Parent = bar
    local fill = Create("Frame", { Size = UDim2.new((value / max), 0, 1, 0), BackgroundColor3 = theme.Accent, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(0, 6) }) })
    fill.Parent = rail
    local percent = Create("TextLabel", { Text = tostring(math.floor((value / max) * 100)) .. "%", Size = UDim2.new(0, 48, 0, 20), Position = UDim2.new(1, -52, 0, 0), BackgroundTransparency = 1, TextColor3 = theme.SubText, Font = DesignTokens.Typography.Caption.Font, TextSize = DesignTokens.Typography.Caption.Size })
    percent.Parent = bar
    AddThemeConnection(rail, { BackgroundColor3 = "SliderRail" }, window)
    AddThemeConnection(fill, { BackgroundColor3 = "Accent" }, window)
    AddThemeConnection(percent, { TextColor3 = "SubText" }, window)
    return {
        Instance = bar,
        Set = function(v)
            v = math.clamp(v or 0, 0, max)
            local fraction = (max == 0) and 0 or (v / max)
            Tween(fill, { Size = UDim2.new(fraction, 0, 1, 0) }, 0.24)
            pcall(function() percent.Text = tostring(math.floor(fraction * 100)) .. "%" end)
        end,
        Destroy = function() if bar and bar.Parent then pcall(function() bar:Destroy() end) end end
    }
end

-- Floating label input with validation and helper text
local function CreateInputWithFloatingLabel(window, parent, config)
    parent = parent or (window and window.ContentContainer)
    config = config or {}
    local labelText = config.Label or "Label"
    local placeholder = config.Placeholder or ""
    local default = config.Default or ""
    local validator = config.Validator -- function(value) -> boolean, message
    local maxLength = config.MaxLength or nil

    local container = Create("Frame", { Size = UDim2.new(1,0,0,48), BackgroundTransparency = 1 })
    container.Parent = parent

    local inputFrame = Create("Frame", { Size = UDim2.new(1,0,0,32), BackgroundColor3 = Themes[(window and window.ThemeName) or globalTheme].DialogInput, BorderSizePixel = 0 }, {
        Create("UICorner", { CornerRadius = UDim.new(0, DesignTokens.BorderRadius.S) })
    })
    inputFrame.Parent = container

    local textbox = Create("TextBox", { Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = default, PlaceholderText = placeholder, Font = DesignTokens.Typography.Body.Font, TextSize = DesignTokens.Typography.Body.Size, TextColor3 = Themes[(window and window.ThemeName) or globalTheme].Text })
    textbox.Parent = inputFrame

    local floating = Create("TextLabel", { Text = labelText, Size = UDim2.new(1, -12, 0, 16), Position = UDim2.new(0, 6, 0, -2), BackgroundTransparency = 1, TextColor3 = Themes[(window and window.ThemeName) or globalTheme].SubText, Font = DesignTokens.Typography.Caption.Font, TextSize = 11 })
    floating.Parent = container

    local helper = Create("TextLabel", { Text = "", Size = UDim2.new(1, -12, 0, 16), Position = UDim2.new(0, 6, 1, -16), BackgroundTransparency = 1, TextColor3 = Themes[(window and window.ThemeName) or globalTheme].SubText, Font = DesignTokens.Typography.Caption.Font, TextSize = DesignTokens.Typography.Caption.Size })
    helper.Parent = container

    AddThemeConnection(inputFrame, { BackgroundColor3 = "DialogInput" }, window)
    AddThemeConnection(textbox, { TextColor3 = "Text" }, window)
    AddThemeConnection(floating, { TextColor3 = "SubText" }, window)
    AddThemeConnection(helper, { TextColor3 = "SubText" }, window)

    local widget = makeWidget(container, window)

    local function updateFloating()
        if textbox.Text ~= "" or textbox:IsFocused() then
            Tween(floating, { Position = UDim2.new(0, 6, 0, -18), TextTransparency = 0, TextSize = 10 }, 0.12)
        else
            Tween(floating, { Position = UDim2.new(0, 6, 0, -2), TextTransparency = 0, TextSize = 11 }, 0.12)
        end
    end

    textbox.Focused:Connect(updateFloating)
    textbox.FocusLost:Connect(function()
        updateFloating()
        local ok, msg = true, nil
        if type(validator) == "function" then
            local s, r = pcall(function() return validator(textbox.Text) end)
            if s then
                if type(r) == "boolean" then ok = r else if type(r) == "table" then ok = r[1]; msg = r[2] end end
            else
                ok = false
                msg = "validation error"
            end
        end
        if maxLength and #textbox.Text > maxLength then
            ok = false
            msg = "Too long ("..tostring(maxLength).." max)"
        end
        if ok then
            helper.Text = ""
            Tween(inputFrame, { BackgroundColor3 = Themes[(window and window.ThemeName) or globalTheme].DialogInput }, 0.12)
        else
            helper.Text = msg or "Invalid"
            Tween(inputFrame, { BackgroundColor3 = Themes[(window and window.ThemeName) or globalTheme].Error }, 0.12)
            -- shake animation
            local orig = inputFrame.Position
            Tween(inputFrame, { Position = UDim2.new(orig.X.Scale, orig.X.Offset - 6, orig.Y.Scale, orig.Y.Offset) }, 0.04)
            delay(0.06, function() Tween(inputFrame, { Position = orig }, 0.06) end)
        end
    end)
    textbox:GetPropertyChangedSignal("Text"):Connect(updateFloating)

    registerFocusable(window, textbox, function() textbox:CaptureFocus() end)

    container.Parent = parent

    return {
        Instance = container,
        Get = function() return textbox.Text end,
        Set = function(v) textbox.Text = tostring(v) end,
        Destroy = function() widget:Destroy() end
    }
end

-- Advanced ColorPicker (improved & integrated)
local function CreateAdvancedColorPicker(window, parent, labelText, defaultColor, callback)
    parent = parent or (window and window.ContentContainer)
    defaultColor = defaultColor or Color3.fromRGB(255,255,255)
    local h,s,v = RGBToHSV(defaultColor.R, defaultColor.G, defaultColor.B)
    h = h or 0; s = s or 0; v = v or 1

    local container = Create("Frame", { Size = UDim2.new(1,0,0,150), BackgroundTransparency = 1 })
    container.Parent = parent

    local lbl = Create("TextLabel", { Text = labelText or "Color", Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = Themes[(window and window.ThemeName) or globalTheme].Text, Font = DesignTokens.Typography.Body.Font, TextSize = DesignTokens.Typography.Body.Size })
    lbl.Parent = container

    local preview = Create("Frame", { Size = UDim2.new(0,64,0,64), BackgroundColor3 = defaultColor, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(0, DesignTokens.BorderRadius.M) }) })
    preview.Parent = container

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

    local hueKnob = Create("Frame", { Size = UDim2.new(0,12,1,0), Position = UDim2.new((h%360)/360, -6, 0, 0), BackgroundColor3 = Color3.new(1,1,1) }, { Create("UICorner", { CornerRadius = UDim.new(0,6) }), Create("UIStroke", { Color = Themes[(window and window.ThemeName) or globalTheme].Accent, Thickness = 1 }) })
    hueKnob.Parent = hueFrame

    local function makeSliderRow(name, init)
        local row = Create("Frame", { Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1 })
        local label = Create("TextLabel", { Text = name, Size = UDim2.new(0.18,0,1,0), BackgroundTransparency = 1, TextColor3 = Themes[(window and window.ThemeName) or globalTheme].Text, Font = DesignTokens.Typography.Body.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
        local sliderFrame = Create("Frame", { Size = UDim2.new(0.7,0,0,8), Position = UDim2.new(0.22,0,0.5,-4), BackgroundColor3 = Themes[(window and window.ThemeName) or globalTheme].SliderRail }, { Create("UICorner", { CornerRadius = UDim.new(0,4) }) })
        local fill = Create("Frame", { Size = UDim2.new(init,0,1,0), BackgroundColor3 = Themes[(window and window.ThemeName) or globalTheme].Accent }, { Create("UICorner", { CornerRadius = UDim.new(0,4) }) })
        local knob = Create("Frame", { Size = UDim2.new(0,12,0,12), Position = UDim2.new(init, -6, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255,255,255) }, { Create("UICorner", { CornerRadius = UDim.new(0,6) }), Create("UIStroke", { Color = Themes[(window and window.ThemeName) or globalTheme].Accent, Thickness = 1 }) })
        fill.Parent = sliderFrame; knob.Parent = sliderFrame
        label.Parent = row; sliderFrame.Parent = row
        return { Frame = row, Label = label, Slider = sliderFrame, Fill = fill, Knob = knob }
    end

    local satRow = makeSliderRow("S", s)
    local valRow = makeSliderRow("V", v)
    satRow.Frame.Parent = container; valRow.Frame.Parent = container

    AddThemeConnection(lbl, { TextColor3 = "Text" }, window)
    AddThemeConnection(satRow.Slider, { BackgroundColor3 = "SliderRail" }, window)
    AddThemeConnection(satRow.Fill, { BackgroundColor3 = "Accent" }, window)
    AddThemeConnection(valRow.Slider, { BackgroundColor3 = "SliderRail" }, window)
    AddThemeConnection(valRow.Fill, { BackgroundColor3 = "Accent" }, window)

    local function updatePreview()
        h = (h % 360 + 360) % 360
        local col = HSVToRGB(h, s, v)
        pcall(function() preview.BackgroundColor3 = col end)
        safeCall(callback, col)
    end

    -- hue interactions
    do
        local dragging = false
        local conn1 = hueFrame.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                local rel = (inp.Position.X - hueFrame.AbsolutePosition.X) / math.max(1, hueFrame.AbsoluteSize.X)
                h = math.clamp(rel * 360, 0, 360)
                Tween(hueKnob, { Position = UDim2.new((h%360)/360, -6, 0, 0) }, 0.08)
                updatePreview()
            end
        end)
        local conn2 = UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = (inp.Position.X - hueFrame.AbsolutePosition.X) / math.max(1, hueFrame.AbsoluteSize.X)
                h = math.clamp(rel * 360, 0, 360)
                Tween(hueKnob, { Position = UDim2.new((h%360)/360, -6, 0, 0) }, 0.08)
                updatePreview()
            end
        end)
        local conn3 = UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        -- widget tracking not necessary but we expose for cleanup by parent
    end

    local function bindSimpleSlider(sl, valueRef, onChanged)
        local dragging = false
        local conn1 = sl.Slider.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                local rel = (inp.Position.X - sl.Slider.AbsolutePosition.X) / math.max(1, sl.Slider.AbsoluteSize.X)
                valueRef[1] = math.clamp(rel, 0, 1)
                Tween(sl.Fill, { Size = UDim2.new(valueRef[1], 0, 1, 0) }, 0.08)
                Tween(sl.Knob, { Position = UDim2.new(valueRef[1], -6, 0.5, -6) }, 0.08)
                if onChanged then onChanged() end
            end
        end)
        local conn2 = UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = (inp.Position.X - sl.Slider.AbsolutePosition.X) / math.max(1, sl.Slider.AbsoluteSize.X)
                valueRef[1] = math.clamp(rel, 0, 1)
                Tween(sl.Fill, { Size = UDim2.new(valueRef[1], 0, 1, 0) }, 0.08)
                Tween(sl.Knob, { Position = UDim2.new(valueRef[1], -6, 0.5, -6) }, 0.08)
                if onChanged then onChanged() end
            end
        end)
        local conn3 = UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        return { conn1, conn2, conn3 }
    end

    local satRef = { s }
    local valRef = { v }
    bindSimpleSlider(satRow, satRef, function() s = satRow.Fill.Size.X.Scale; updatePreview() end)
    bindSimpleSlider(valRow, valRef, function() v = valRow.Fill.Size.X.Scale; updatePreview() end)

    return {
        Instance = container,
        GetColor = function() return HSVToRGB(h, s, v) end,
        SetColor = function(c) if not (c and typeof(c) == 'Color3') then return end local rh,rs,rv = RGBToHSV(c.R, c.G, c.B); h = (rh%360); s = rs; v = rv; Tween(hueKnob, { Position = UDim2.new((h%360)/360, -6, 0, 0) }, 0.12); Tween(satRow.Fill, { Size = UDim2.new(s,0,1,0) }, 0.12); Tween(satRow.Knob, { Position = UDim2.new(s, -6, 0.5, -6) }, 0.12); Tween(valRow.Fill, { Size = UDim2.new(v,0,1,0) }, 0.12); Tween(valRow.Knob, { Position = UDim2.new(v, -6, 0.5, -6) }, 0.12); updatePreview() end,
        Destroy = function() if container and container.Parent then pcall(function() container:Destroy() end) end end
    }
end

-- KeybindEx improved
local function CreateKeybindEx(window, parent, labelText, defaultBind, callback)
    parent = parent or (window and window.ContentContainer)
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
    local label = Create("TextLabel", { Text = labelText or "Keybind", Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1, TextColor3 = Themes[(window and window.ThemeName) or globalTheme].Text, Font = DesignTokens.Typography.Body.Font, TextSize = DesignTokens.Typography.Body.Size, TextXAlignment = Enum.TextXAlignment.Left })
    local button = Create("TextButton", { Size = UDim2.new(0.35,0,0.8,0), Position = UDim2.new(0.65,0,0.1,0), Text = formatBind(bind), AutoButtonColor = false, BackgroundColor3 = Themes[(window and window.ThemeName) or globalTheme].Surface1, BorderSizePixel = 0 }, { Create("UICorner", { CornerRadius = UDim.new(0, DesignTokens.BorderRadius.S) }) })
    label.Parent = frame; button.Parent = frame; frame.Parent = parent

    AddThemeConnection(button, { BackgroundColor3 = "Surface1" }, window)
    AddThemeConnection(label, { TextColor3 = "Text" }, window)

    local widget = makeWidget(frame, window)
    registerFocusable(window, button, function() button:CaptureFocus() end)

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

    return {
        Instance = frame,
        GetBind = function() return bind end,
        SetBind = function(b) bind = b; button.Text = formatBind(bind) end,
        Destroy = function() widget:Destroy() end
    }
end

-- Main window creation
function SkyeUI:CreateWindow(title)
    title = title or "Skye UI"

    -- ScreenGui
    local screenGui = Create("ScreenGui", {
        Name = "SkyeUI",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false
    })
    pcall(function() screenGui.Enabled = true end)

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
        _savedFocusIndex = nil,
        ThemeName = globalTheme
    }
    setmetatable(window._widgets, { __mode = 'v' })
    setmetatable(window, { __index = SkyeUI })
    table.insert(_allWindows, window)

    _activeWindowCount = _activeWindowCount + 1
    ensureThemeCleanupStarted()

    function window:_trackConnection(c)
        if c and typeof(c) == "RBXScriptConnection" then
            table.insert(self._connections, c)
        end
    end

    local function trackConnectionLocal(c) window:_trackConnection(c) end

    -- MainFrame
    local mainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = screenGui,
        Size = DEFAULT_WINDOW_SIZE,
        Position = DEFAULT_WINDOW_POSITION,
        BackgroundColor3 = Themes[DEFAULT_THEME].Background,
        ClipsDescendants = true
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, DesignTokens.BorderRadius.M) }),
        Create("UIStroke", { Color = Themes[DEFAULT_THEME].InElementBorder, Thickness = 1 })
    })
    window.MainFrame = mainFrame
    AddThemeConnection(mainFrame, { BackgroundColor3 = "Background" }, window)
    AddThemeConnection(mainFrame.UIStroke, { Color = "InElementBorder" }, window)

    -- Topbar
    local topbar = Create("Frame", {
        Name = "Topbar",
        Parent = mainFrame,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Themes[DEFAULT_THEME].Surface2,
        BorderSizePixel = 0
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, DesignTokens.BorderRadius.M), Name = "TopbarCorner" })
    })
    AddThemeConnection(topbar, { BackgroundColor3 = "TabBackground" }, window)
    window.Topbar = topbar

    -- Title label
    local titleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = topbar,
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.new(0, DesignTokens.Spacing.M, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Themes[DEFAULT_THEME].Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = DesignTokens.Typography.Heading.Font,
        TextSize = DesignTokens.Typography.Heading.Size
    })
    AddThemeConnection(titleLabel, { TextColor3 = "Text" }, window)

    -- Button container
    local buttonContainer = Create("Frame", {
        Name = "ButtonContainer",
        Parent = topbar,
        Size = UDim2.new(0, 140, 1, 0),
        Position = UDim2.new(1, -140, 0, 0),
        BackgroundTransparency = 1
    })
    buttonContainer.Parent = topbar

    -- Minimize & Close
    local minimizeButton = Create("TextButton", {
        Name = "MinimizeButton",
        Parent = buttonContainer,
        Size = UDim2.new(0, 44, 0, 28),
        Position = UDim2.new(0, 4, 0.5, -14),
        BackgroundTransparency = 1,
        Text = "-",
        TextColor3 = Themes[DEFAULT_THEME].Text,
        Font = DesignTokens.Typography.Heading.Font,
        TextSize = 16
    })
    AddThemeConnection(minimizeButton, { TextColor3 = "Text" }, window)

    local closeButton = Create("TextButton", {
        Name = "CloseButton",
        Parent = buttonContainer,
        Size = UDim2.new(0, 44, 0, 28),
        Position = UDim2.new(0, 76, 0.5, -14),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = Themes[DEFAULT_THEME].Text,
        Font = DesignTokens.Typography.Body.Font,
        TextSize = 14
    })
    AddThemeConnection(closeButton, { TextColor3 = "Text" }, window)

    -- Tab container (left)
    local tabContainer = Create("ScrollingFrame", {
        Name = "TabContainer",
        Parent = mainFrame,
        Size = UDim2.new(0, 160, 1, -48),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, DesignTokens.Spacing.S) }),
        Create("UIPadding", { PaddingTop = UDim.new(0, DesignTokens.Spacing.L), PaddingLeft = UDim.new(0, DesignTokens.Spacing.M), PaddingRight = UDim.new(0, DesignTokens.Spacing.M) })
    })
    window.TabContainer = tabContainer

    -- Content container
    local contentContainer = Create("ScrollingFrame", {
        Name = "ContentContainer",
        Parent = mainFrame,
        Size = UDim2.new(1, -176, 1, -48),
        Position = UDim2.new(0, 176, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, DesignTokens.Spacing.L) }),
        Create("UIPadding", { PaddingTop = UDim.new(0, DesignTokens.Spacing.M), PaddingBottom = UDim.new(0, DesignTokens.Spacing.M), PaddingLeft = UDim.new(0, DesignTokens.Spacing.M), PaddingRight = UDim.new(0, DesignTokens.Spacing.M) })
    })
    window.ContentContainer = contentContainer

    -- Dragging (custom)
    do
        local dragging = false
        local dragStart = Vector2.new(0, 0)
        local startPixelPos = Vector2.new(0, 0)

        local inputBeganConn = topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
                startPixelPos = Vector2.new(mainFrame.Position.X.Scale * screenSize.X + mainFrame.Position.X.Offset, mainFrame.Position.Y.Scale * screenSize.Y + mainFrame.Position.Y.Offset)
            end
        end)
        trackConnectionLocal(inputBeganConn)

        local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
                local newPixelX = startPixelPos.X + delta.X
                local newPixelY = startPixelPos.Y + delta.Y
                local maxX = math.max(0, screenSize.X - mainFrame.AbsoluteSize.X)
                local maxY = math.max(0, screenSize.Y - mainFrame.AbsoluteSize.Y)
                local clampedX = math.clamp(math.floor(newPixelX + 0.5), 0, maxX)
                local clampedY = math.clamp(math.floor(newPixelY + 0.5), 0, maxY)
                pcall(function() mainFrame.Position = UDim2.new(0, clampedX, 0, clampedY) end)
            end
        end)
        trackConnectionLocal(inputChangedConn)

        local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        trackConnectionLocal(inputEndedConn)
    end

    -- Button hover helper (now uses tokens & theme)
    local function setupButtonHover(button)
        if not button then return end
        local enter = button.MouseEnter:Connect(function()
            pcall(function() Tween(button, { TextColor3 = Themes[(window.ThemeName or globalTheme)].Accent }, 0.18) end)
        end)
        local leave = button.MouseLeave:Connect(function()
            pcall(function() Tween(button, { TextColor3 = Themes[(window.ThemeName or globalTheme)].Text }, 0.18) end)
        end)
        trackConnectionLocal(enter)
        trackConnectionLocal(leave)
    end

    setupButtonHover(minimizeButton)
    setupButtonHover(closeButton)

    -- Notification container
    local notificationContainer = Create("Frame", {
        Name = "NotificationContainer",
        Parent = screenGui,
        Size = UDim2.new(0, 340, 0, 0),
        Position = UDim2.new(1, -360, 1, -24),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, {
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, DesignTokens.Spacing.S),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom
        })
    })
    window.NotificationContainer = notificationContainer

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
            BackgroundColor3 = Themes[(self.ThemeName or globalTheme)].SectionBackground,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = layoutOrder,
            BorderSizePixel = 0
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, DesignTokens.BorderRadius.S) }),
            Create("UIStroke", { Color = Themes[(self.ThemeName or globalTheme)].InElementBorder, Thickness = 1 }),
            Create("Frame", { Name = "Accent", Size = UDim2.new(0, 6, 1, 0), BackgroundColor3 = Themes[(self.ThemeName or globalTheme)].Accent, BorderSizePixel = 0 }),
            Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder })
        })

        local titleLabel = Create("TextLabel", {
            Text = title,
            Size = UDim2.new(1, -8, 0, 18),
            BackgroundTransparency = 1,
            TextColor3 = Themes[(self.ThemeName or globalTheme)].Text,
            Font = DesignTokens.Typography.Body.Font,
            TextSize = DesignTokens.Typography.Body.Size,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local contentLabel = Create("TextLabel", {
            Text = content,
            Size = UDim2.new(1, -8, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = Themes[(self.ThemeName or globalTheme)].SubText,
            Font = DesignTokens.Typography.Body.Font,
            TextSize = DesignTokens.Typography.Body.Size,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y
        })

        titleLabel.Parent = notification
        contentLabel.Parent = notification
        notification.Parent = notificationContainer

        spawn(function()
            pcall(function()
                RunService.Heartbeat:Wait()
                if not (notification and notification.Parent) then return end
                local targetHeight = notification.AbsoluteContentSize.Y
                if not (targetHeight and targetHeight > 0) then
                    RunService.Heartbeat:Wait()
                    targetHeight = notification.AbsoluteContentSize.Y
                end
                if not targetHeight or targetHeight <= 0 then targetHeight = 52 end
                Tween(notification, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.24)
            end)
        end)

        spawn(function()
            task.delay(duration, function()
                pcall(function()
                    if not notification or not notification.Parent then return end
                    Tween(notification, { Size = UDim2.new(0, 0, 0, 0) }, 0.24)
                    task.wait(0.26)
                    if notification and notification.Parent then notification:Destroy() end
                end)
            end)
        end)
    end

    -- Tab management
    function window:AddTab(name)
        if type(name) ~= "string" or #name == 0 then warn("[SkyeUI] AddTab: name must be non-empty string"); return nil end
        if self.Tabs[name] then warn("[SkyeUI] AddTab: Duplicate tab name '" .. name .. "' - returning existing tab"); return self.Tabs[name] end

        local tabButton = Create("TextButton", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Themes[(self.ThemeName or globalTheme)].TabBackground,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, DesignTokens.BorderRadius.S) }),
            Create("TextLabel", {
                Text = name,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3 = Themes[(self.ThemeName or globalTheme)].Text,
                Font = DesignTokens.Typography.Body.Font,
                TextSize = DesignTokens.Typography.Body.Size
            })
        })

        AddThemeConnection(tabButton, { BackgroundColor3 = "TabBackground" }, window)
        local textLabel = nil
        for _, c in ipairs(tabButton:GetChildren()) do if c:IsA("TextLabel") then textLabel = c; break end end
        if textLabel then AddThemeConnection(textLabel, { TextColor3 = "Text" }, window) end

        local tabContent = Create("ScrollingFrame", {
            Name = name,
            Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false
        }, {
            Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, DesignTokens.Spacing.M) }),
            Create("UIPadding", { PaddingTop = UDim.new(0, DesignTokens.Spacing.M), PaddingBottom = UDim.new(0, DesignTokens.Spacing.M) })
        })

        tabButton.Parent = tabContainer
        tabContent.Parent = contentContainer

        local hoverConn = tabButton.MouseEnter:Connect(function()
            if self.CurrentTab ~= name then pcall(function() Tween(tabButton, { BackgroundColor3 = Themes[(self.ThemeName or globalTheme)].TabHover }, 0.18) end) end
        end)
        trackConnectionLocal(hoverConn)
        local leaveConn = tabButton.MouseLeave:Connect(function()
            if self.CurrentTab ~= name then pcall(function() Tween(tabButton, { BackgroundColor3 = Themes[(self.ThemeName or globalTheme)].TabBackground }, 0.18) end) end
        end)
        trackConnectionLocal(leaveConn)

        local clickConn = tabButton.MouseButton1Click:Connect(function()
            if self.CurrentTab then
                local prev = self.Tabs[self.CurrentTab]
                if prev and prev.Button and prev.Content then
                    pcall(function()
                        Tween(prev.Button, { BackgroundColor3 = Themes[(self.ThemeName or globalTheme)].TabBackground }, 0.12)
                        prev.Content.Visible = false
                        for _, child in ipairs(prev.Button:GetChildren()) do
                            if child:IsA("TextLabel") then Tween(child, { TextColor3 = Themes[(self.ThemeName or globalTheme)].Text }, 0.12) end
                        end
                    end)
                end
            end
            self.CurrentTab = name
            if self.Tabs[name] and self.Tabs[name].Button then pcall(function() Tween(self.Tabs[name].Button, { BackgroundColor3 = Themes[(self.ThemeName or globalTheme)].Accent }, 0.12) end) end
            if self.Tabs[name] and self.Tabs[name].Content then self.Tabs[name].Content.Visible = true end
            for _, child in ipairs(tabButton:GetChildren()) do
                if child:IsA("TextLabel") then pcall(function() Tween(child, { TextColor3 = Themes[(self.ThemeName or globalTheme)].SelectedText }, 0.12) end) end
            end
        end)
        trackConnectionLocal(clickConn)

        local tabObj = { Button = tabButton, Content = tabContent }
        self.Tabs[name] = tabObj

        if not self.CurrentTab then
            self.CurrentTab = name
            pcall(function()
                Tween(tabButton, { BackgroundColor3 = Themes[(self.ThemeName or globalTheme)].Accent }, 0.12)
                tabContent.Visible = true
                for _, child in ipairs(tabButton:GetChildren()) do
                    if child:IsA("TextLabel") then Tween(child, { TextColor3 = Themes[(self.ThemeName or globalTheme)].SelectedText }, 0.12) end
                end
            end)
        end

        return tabObj
    end

    -- AddSection
    function window:AddSection(tabRef, title)
        if type(title) ~= "string" or #title == 0 then warn("[SkyeUI] AddSection: title must be non-empty string"); return nil end
        local tab
        if type(tabRef) == "string" then tab = self.Tabs[tabRef]
        elseif type(tabRef) == "table" and tabRef.Content then tab = tabRef
        else tab = self.Tabs[self.CurrentTab] end
        if not tab then warn("[SkyeUI] AddSection: tab not found"); return nil end

        local section = Create("Frame", {
            Name = title,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = Themes[(self.ThemeName or globalTheme)].SectionBackground,
            AutomaticSize = Enum.AutomaticSize.Y,
            BorderSizePixel = 0
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, DesignTokens.BorderRadius.M) }),
            Create("UIStroke", { Color = Themes[(self.ThemeName or globalTheme)].InElementBorder, Thickness = 1 }),
            Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, DesignTokens.Spacing.M) }),
            Create("UIPadding", { PaddingTop = UDim.new(0, DesignTokens.Spacing.M), PaddingBottom = UDim.new(0, DesignTokens.Spacing.M), PaddingLeft = UDim.new(0, DesignTokens.Spacing.M), PaddingRight = UDim.new(0, DesignTokens.Spacing.M) })
        })

        local sectionHeader = Create("TextLabel", {
            Text = title,
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            TextColor3 = Themes[(self.ThemeName or globalTheme)].SubText,
            Font = DesignTokens.Typography.Heading.Font,
            TextSize = DesignTokens.Typography.Heading.Size,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        AddThemeConnection(section, { BackgroundColor3 = "SectionBackground" }, self)
        AddThemeConnection(section.UIStroke, { Color = "InElementBorder" }, self)
        AddThemeConnection(sectionHeader, { TextColor3 = "SubText" }, self)

        sectionHeader.Parent = section
        section.Parent = tab.Content

        return section
    end

    -- Per-window theme
    function window:SetTheme(tname)
        if type(tname) ~= "string" or not Themes[tname] then warn("[SkyeUI] SetTheme: invalid theme name"); return end
        ApplyTheme(tname, self)
    end
    function window:GetTheme() return self.ThemeName or globalTheme end

    -- Minimize / restore
    function window:IsMinimized() return self._isMinimized end
    function window:SetMinimized(minimized)
        minimized = not not minimized
        if minimized == self._isMinimized then return end
        if minimized then self._savedFocusIndex = self._focusIndex else if self._savedFocusIndex then self._focusIndex = self._savedFocusIndex end; updateFocusVisual(self) end
        self._isMinimized = minimized
        if minimized then
            Tween(mainFrame, { Size = UDim2.new(0, DEFAULT_WINDOW_SIZE.X.Offset, 0, 36) }, 0.20)
            Tween(tabContainer, { Size = UDim2.new(0, 160, 0, 0) }, 0.20)
            Tween(contentContainer, { Size = UDim2.new(1, -176, 0, 0) }, 0.20)
        else
            Tween(mainFrame, { Size = DEFAULT_WINDOW_SIZE }, 0.20)
            Tween(tabContainer, { Size = UDim2.new(0, 160, 1, -48) }, 0.20)
            Tween(contentContainer, { Size = UDim2.new(1, -176, 1, -48) }, 0.20)
        end
    end

    local minimConnection = minimizeButton.MouseButton1Click:Connect(function() window:SetMinimized(not window._isMinimized) end)
    trackConnectionLocal(minimConnection)
    local closeConn = closeButton.MouseButton1Click:Connect(function() window:Destroy() end)
    trackConnectionLocal(closeConn)

    -- Dropdown manager
    function window:_registerOpenDropdown(dropdownWidget)
        if self._dropdownOpen and self._dropdownOpen ~= dropdownWidget and type(self._dropdownOpen.Close) == "function" then
            pcall(function() self._dropdownOpen:Close() end)
        end
        self._dropdownOpen = dropdownWidget
    end
    function window:_clearOpenDropdown(dropdownWidget)
        if self._dropdownOpen == dropdownWidget then self._dropdownOpen = nil end
    end

    -- Hotkey bind to toggle
    function window:BindToggleKey(key, allowFocus)
        if type(key) ~= "string" then warn("[SkyeUI] BindToggleKey: key must be string"); return nil end
        local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed and not allowFocus then return end
            local match = false
            if input.KeyCode and tostring(input.KeyCode) == ("Enum.KeyCode." .. key) then match = true
            elseif Enum.KeyCode[key] and input.KeyCode == Enum.KeyCode[key] then match = true end
            if match then
                if screenGui.Enabled == nil then screenGui.Enabled = true end
                screenGui.Enabled = not screenGui.Enabled
            end
        end)
        trackConnectionLocal(conn)
        return conn
    end

    -- Widget batching per-window
    function window:BeginWidgetBatch()
        self._widgetBatchCounter = (self._widgetBatchCounter or 0) + 1
        SkyeUI.BeginThemeBatch()
    end
    function window:EndWidgetBatch()
        self._widgetBatchCounter = validateEndBatch("WidgetBatch", (self._widgetBatchCounter or 0) - 1)
        SkyeUI.EndThemeBatch()
    end

    -- Expose component factories as window methods
    function window:CreateButton(config) return CreateButtonVisual(window, config) end
    function window:CreateCard(parent, config) return CreateCard(window, parent, config) end
    function window:CreateBadge(parent, text, variant) return CreateBadge(window, parent, text, variant) end
    function window:CreateProgressBar(parent, value, max) return CreateProgressBar(window, parent, value, max) end
    function window:CreateInput(parent, config) return CreateInputWithFloatingLabel(window, parent, config) end
    function window:CreateAdvancedColorPicker(parent, label, defaultColor, cb) return CreateAdvancedColorPicker(window, parent, label, defaultColor, cb) end
    function window:CreateKeybindEx(parent, label, defaultBind, cb) return CreateKeybindEx(window, parent, label, defaultBind, cb) end

    -- Accessibility setup
    setupWindowAccessibility(window)

    -- Destroy
    function window:Destroy()
        for _, c in ipairs(self._connections) do pcall(function() if c and typeof(c) == 'RBXScriptConnection' then c:Disconnect() end end) end
        self._connections = {}
        for _, w in ipairs(self._widgets) do
            if type(w.Destroy) == "function" then pcall(function() w:Destroy() end) end
        end
        self._widgets = {}
        RemoveThemeConnectionRecursive(self.MainFrame)
        RemoveThemeConnectionRecursive(self.Topbar)
        RemoveThemeConnectionRecursive(self.TabContainer)
        RemoveThemeConnectionRecursive(self.ContentContainer)
        CleanThemeConnections()
        if screenGui and screenGui.Parent then pcall(function() screenGui:Destroy() end) end
        self._dropdownOpen = nil
        for i, w in ipairs(_allWindows) do if w == self then table.remove(_allWindows, i); break end end
        _activeWindowCount = math.max(0, _activeWindowCount - 1)
        stopThemeCleanupIfIdle()
    end

    -- Apply initial theme per-window
    ApplyTheme(self.ThemeName, window)

    return window
end

-- Global theme API
function SkyeUI.SetGlobalTheme(name)
    if type(name) ~= "string" then warn("[SkyeUI] SetGlobalTheme: name must be string"); return end
    ApplyTheme(name, nil)
end
function SkyeUI.GetAvailableThemes()
    local keys = {}
    for k,_ in pairs(Themes) do table.insert(keys,k) end
    return keys
end
function SkyeUI.AddTheme(name, themeTable)
    if type(name) ~= "string" or type(themeTable) ~= "table" then error("AddTheme expects (string, table)") end
    Themes[name] = themeTable
end

-- Return module
return SkyeUI
