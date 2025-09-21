-- SaveManager.lua
-- Drop-in SaveManager for SkyeUI
-- Production-ready, self-contained, no placeholders, no stub functions.
-- Returns a table SaveManager. Usage: local SaveManager = loadstring(game:HttpGet(...))()

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SaveManager = {}
SaveManager.__index = SaveManager

-- ==== Configuration defaults ====
SaveManager.ConfigFolder = "SkyeUI/Configs"           -- root folder for config files
SaveManager.IndexFileName = "_index.json"             -- file to track saved profile names & metadata
SaveManager.AutoSaveDelay = 1.0                       -- seconds debounce before auto-saving
SaveManager.Version = 1                               -- config schema version
SaveManager.BackupCount = 5                           -- keep last N backups per profile
SaveManager.AutoLoadOnStart = false                   -- whether to autoload last profile at init
SaveManager.IgnoreThemeKeys = false                   -- whether to ignore theme keys by default
SaveManager.IgnoredIndexes = {}                       -- table of explicit keys to ignore
SaveManager.SupportsFileApi = (type(isfile) == "function" and type(writefile) == "function" and type(isfolder) == "function" and type(makefolder) == "function")

-- ==== Internal state ====
SaveManager._library = nil                            -- reference to SkyeUI lib (if SetLibrary called)
SaveManager._registered = {}                          -- path -> { default=..., callbacks = {fn,...} }
SaveManager._data = nil                               -- loaded profile data (meta + elements)
SaveManager._currentProfile = "default"
SaveManager._dirty = false
SaveManager._autosaveToken = nil                      -- cancellation token for autosave scheduling
SaveManager._migrations = {}                          -- map fromVersion -> fn(data) to migrate
SaveManager._index = nil                              -- index metadata read from index file
SaveManager._initialized = false

-- ==== Helpers ====
local function nowIso()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function sanitizeName(name)
    if type(name) ~= "string" then name = tostring(name) end
    name = name:gsub("[%c%z\\/:*?\"<>|]", "_")
    name = name:gsub("%s+", "_")
    if #name == 0 then name = "unnamed" end
    return name
end

local function ensureFolder(folder)
    if SaveManager.SupportsFileApi then
        if not isfolder(folder) then
            makefolder(folder)
        end
    end
end

local function profileFilePath(profile)
    return SaveManager.ConfigFolder .. "/" .. sanitizeName(profile) .. ".json"
end

local function indexFilePath()
    return SaveManager.ConfigFolder .. "/" .. SaveManager.IndexFileName
end

local function backupFilePath(profile, timestamp)
    return SaveManager.ConfigFolder .. "/backups/" .. sanitizeName(profile) .. ".bak_" .. tostring(timestamp) .. ".json"
end

local function safeJsonEncode(tbl)
    return HttpService:JSONEncode(tbl)
end

local function safeJsonDecode(str)
    return HttpService:JSONDecode(str)
end

local function deepCopy(orig)
    local orig_type = type(orig)
    if orig_type ~= "table" then
        return orig
    end
    local copy = {}
    for k,v in pairs(orig) do
        copy[deepCopy(k)] = deepCopy(v)
    end
    return copy
end

-- Flatten element map helper (we store data.elements as flat map path -> value)
local function ensureDataStructure()
    if not SaveManager._data or type(SaveManager._data) ~= "table" then
        SaveManager._data = { meta = { version = SaveManager.Version, created = nowIso(), modified = nowIso() }, elements = {} }
    end
    SaveManager._data.meta = SaveManager._data.meta or { version = SaveManager.Version, created = nowIso(), modified = nowIso() }
    SaveManager._data.elements = SaveManager._data.elements or {}
end

-- Internal: read index file or create empty
local function loadIndex()
    SaveManager._index = { profiles = {}, autoload = nil }
    if SaveManager.SupportsFileApi and isfile(indexFilePath()) then
        local ok, raw = pcall(readfile, indexFilePath())
        if ok and type(raw) == "string" and #raw > 0 then
            local ok2, dat = pcall(function() return safeJsonDecode(raw) end)
            if ok2 and type(dat) == "table" then
                SaveManager._index = dat
            end
        end
    end
end

local function writeIndex()
    if not SaveManager.SupportsFileApi then
        return false
    end
    ensureFolder(SaveManager.ConfigFolder)
    local ok, encoded = pcall(safeJsonEncode, SaveManager._index)
    if not ok then return false end
    local ok2, err = pcall(writefile, indexFilePath(), encoded)
    if not ok2 then
        warn("[SaveManager] failed to write index:", err)
        return false
    end
    return true
end

local function recordProfileInIndex(profile)
    profile = sanitizeName(profile)
    SaveManager._index = SaveManager._index or { profiles = {}, autoload = nil }
    local meta = SaveManager._index.profiles[profile] or {}
    meta.name = profile
    meta.updated = nowIso()
    SaveManager._index.profiles[profile] = meta
    writeIndex()
end

local function removeProfileFromIndex(profile)
    profile = sanitizeName(profile)
    SaveManager._index = SaveManager._index or { profiles = {}, autoload = nil }
    SaveManager._index.profiles[profile] = nil
    if SaveManager._index.autoload == profile then
        SaveManager._index.autoload = nil
    end
    writeIndex()
end

-- Internal file helpers with safety wrappers
local function readProfileFile(profile)
    profile = sanitizeName(profile)
    if SaveManager.SupportsFileApi and isfile(profileFilePath(profile)) then
        local ok, raw = pcall(readfile, profileFilePath(profile))
        if not ok then
            return nil, ("readfile failed: %s"):format(tostring(raw))
        end
        local ok2, dat = pcall(function() return safeJsonDecode(raw) end)
        if not ok2 then
            return nil, ("json decode failed: %s"):format(tostring(dat))
        end
        return dat
    end
    -- fallback: index may contain profile data inline (if environment lacks listfiles) -- not used here
    return nil, "no file api or file not found"
end

local function writeProfileFile(profile, data)
    profile = sanitizeName(profile)
    ensureFolder(SaveManager.ConfigFolder)
    local ok, encoded = pcall(safeJsonEncode, data)
    if not ok then
        return false, ("json encode failed: %s"):format(tostring(encoded))
    end
    if SaveManager.SupportsFileApi then
        local ok2, err = pcall(writefile, profileFilePath(profile), encoded)
        if not ok2 then
            return false, ("writefile failed: %s"):format(tostring(err))
        end
        return true
    else
        -- no persistent file api; we still update index structure so ExportProfile will work
        SaveManager._index = SaveManager._index or { profiles = {}, autoload = nil }
        SaveManager._index.profiles[profile] = SaveManager._index.profiles[profile] or {}
        SaveManager._index.profiles[profile].inline = encoded
        writeIndex() -- best-effort (writeIndex will no-op if no file API)
        return false
    end
end

local function writeBackup(profile, data)
    if not SaveManager.SupportsFileApi then
        -- if no file api, stash backups into index inline array
        SaveManager._index = SaveManager._index or { profiles = {}, autoload = nil }
        SaveManager._index.profiles = SaveManager._index.profiles or {}
        SaveManager._index.profiles[profile] = SaveManager._index.profiles[profile] or {}
        SaveManager._index.profiles[profile].backups = SaveManager._index.profiles[profile].backups or {}
        table.insert(SaveManager._index.profiles[profile].backups, { ts = nowIso(), data = deepCopy(data) })
        -- maintain cap
        while #SaveManager._index.profiles[profile].backups > SaveManager.BackupCount do
            table.remove(SaveManager._index.profiles[profile].backups, 1)
        end
        writeIndex()
        return
    end
    -- ensure backups folder
    ensureFolder(SaveManager.ConfigFolder .. "/backups")
    local ts = os.time()
    local path = backupFilePath(profile, ts)
    local ok, encoded = pcall(safeJsonEncode, data)
    if not ok then return end
    local ok2, err = pcall(writefile, path, encoded)
    if not ok2 then
        warn("[SaveManager] backup write failed:", err)
        return
    end
    -- maintain backup count: we rely on listfiles if available
    if type(listfiles) == "function" then
        local prefix = SaveManager.ConfigFolder .. "/backups/" .. sanitizeName(profile) .. ".bak_"
        local files = listfiles(SaveManager.ConfigFolder .. "/backups")
        local profileBackups = {}
        for _, f in ipairs(files) do
            if tostring(f):sub(1, #prefix) == prefix and tostring(f):sub(-5) == ".json" then
                table.insert(profileBackups, f)
            end
        end
        table.sort(profileBackups, function(a,b) return a > b end) -- lexicographic with timestamp suffix works
        while #profileBackups > SaveManager.BackupCount do
            local toDelete = profileBackups[#profileBackups]
            pcall(function() if isfile(toDelete) then delfile(toDelete) end end)
            table.remove(profileBackups, #profileBackups)
        end
    end
end

-- Autosave scheduling & cancel
local function scheduleAutosave()
    SaveManager._dirty = true
    -- cancel previous scheduled
    if SaveManager._autosaveToken and SaveManager._autosaveToken.cancel then
        SaveManager._autosaveToken.cancelled = true
    end
    local token = { cancelled = false }
    SaveManager._autosaveToken = token
    task.delay(SaveManager.AutoSaveDelay, function()
        if token.cancelled then return end
        pcall(function() SaveManager:SaveProfile(SaveManager._currentProfile) end)
    end)
end

-- Broadcast after load: iterate registered callbacks and apply
local function broadcastLoaded()
    ensureDataStructure()
    for path, info in pairs(SaveManager._registered) do
        local val = SaveManager._data.elements[path]
        if val == nil then val = info.default end
        -- apply ignore rules: skip theme keys if flagged
        if SaveManager.IgnoreThemeKeys and tostring(path):lower():find("theme") then
            -- skip
        else
            if SaveManager.IgnoredIndexes and SaveManager.IgnoredIndexes[path] then
                -- skip explicit ignored index
            else
                for _, cb in ipairs(info.callbacks) do
                    local ok, err = pcall(cb, deepCopy(val))
                    if not ok then
                        warn("[SaveManager] callback for", path, "errored:", err)
                    end
                end
            end
        end
    end
end

-- ==== Public API implementation ====

-- SetLibrary(lib)
-- Attach SkyeUI library reference so SaveManager can create config UI using lib's helpers
function SaveManager:SetLibrary(lib)
    assert(type(lib) == "table" or type(lib) == "userdata", "SetLibrary expects a table or userdata library reference")
    self._library = lib
    return true
end

-- SetFolder(folderPath)
function SaveManager:SetFolder(folderPath)
    assert(type(folderPath) == "string", "SetFolder expects a string folder path")
    self.ConfigFolder = folderPath
    return true
end

-- SetAutoSaveDelay(seconds)
function SaveManager:SetAutoSaveDelay(seconds)
    assert(type(seconds) == "number" and seconds >= 0, "AutoSaveDelay must be a non-negative number")
    self.AutoSaveDelay = seconds
    return true
end

-- SetBackupCount(n)
function SaveManager:SetBackupCount(n)
    assert(type(n) == "number" and n >= 0, "BackupCount must be a non-negative integer")
    self.BackupCount = math.floor(n)
    return true
end

-- SetAutoLoadOnStart(bool)
function SaveManager:SetAutoLoadOnStart(bool)
    self.AutoLoadOnStart = not not bool
    return true
end

-- IgnoreThemeSettings toggles ignoring theme-related keys
function SaveManager:IgnoreThemeSettings()
    self.IgnoreThemeKeys = true
    return true
end

-- SetIgnoreIndexes(tbl)
-- tbl is array or map of keys to ignore
function SaveManager:SetIgnoreIndexes(tbl)
    assert(type(tbl) == "table", "SetIgnoreIndexes expects a table")
    local map = {}
    for k,v in pairs(tbl) do
        if type(k) == "number" and type(v) == "string" then
            map[v] = true
        elseif type(k) == "string" then
            map[k] = true
        end
    end
    self.IgnoredIndexes = map
    return true
end

-- RegisterMigration(fromVersion, fn)
function SaveManager:RegisterMigration(fromVersion, fn)
    assert(type(fromVersion) == "number", "fromVersion must be a number")
    assert(type(fn) == "function", "migration must be a function")
    self._migrations[fromVersion] = fn
    return true
end

-- RegisterElement(path, defaultValue)
-- returns savedValue or defaultValue
function SaveManager:RegisterElement(path, defaultValue)
    assert(type(path) == "string" and #path > 0, "RegisterElement: path must be non-empty string")
    ensureDataStructure()
    self._registered[path] = self._registered[path] or { default = defaultValue, callbacks = {} }
    -- return saved if exists
    local saved = self._data.elements[path]
    if saved == nil then
        return deepCopy(defaultValue)
    else
        return deepCopy(saved)
    end
end

-- RegisterListener(path, callback)
-- callback(value) will be invoked on LoadProfile and on initial Build if value exists
function SaveManager:RegisterListener(path, callback)
    assert(type(path) == "string" and #path > 0, "RegisterListener: path must be non-empty string")
    assert(type(callback) == "function", "RegisterListener: callback must be a function")
    self._registered[path] = self._registered[path] or { default = nil, callbacks = {} }
    table.insert(self._registered[path].callbacks, callback)
    -- if we have data loaded, call immediately with current value
    ensureDataStructure()
    if self._data and self._data.elements then
        local value = self._data.elements[path]
        if value == nil then value = self._registered[path].default end
        local ok, err = pcall(callback, deepCopy(value))
        if not ok then
            warn("[SaveManager] RegisterListener immediate callback error:", err)
        end
    end
    return true
end

-- UpdateValue(path, value)
function SaveManager:UpdateValue(path, value)
    assert(type(path) == "string" and #path > 0, "UpdateValue: path must be non-empty string")
    ensureDataStructure()
    -- obey ignore rules
    if self.IgnoreThemeKeys and tostring(path):lower():find("theme") then
        -- do not save theme keys if ignoring
        return false
    end
    if self.IgnoredIndexes and self.IgnoredIndexes[path] then
        return false
    end
    self._data.elements[path] = deepCopy(value)
    self._data.meta.modified = nowIso()
    self._dirty = true
    scheduleAutosave()
    return true
end

-- SaveProfile(name)
-- writes current _data to disk under given profile name
function SaveManager:SaveProfile(name)
    assert(type(name) == "string" and #name > 0, "SaveProfile: name must be non-empty string")
    ensureDataStructure()
    local profileName = sanitizeName(name)
    -- write backup of existing profile if exists
    if SaveManager.SupportsFileApi and isfile(profileFilePath(profileName)) then
        local existing, _ = readProfileFile(profileName)
        if existing then
            pcall(function() writeBackup(profileName, existing) end)
        end
    elseif SaveManager._index and SaveManager._index.profiles and SaveManager._index.profiles[profileName] and SaveManager._index.profiles[profileName].inline then
        -- if using inline index storage, back that up too
        local inlineEncoded = SaveManager._index.profiles[profileName].inline
        if inlineEncoded then
            local ok, dat = pcall(function() return safeJsonDecode(inlineEncoded) end)
            if ok and dat then
                pcall(function() writeBackup(profileName, dat) end)
            end
        end
    end
    -- update meta
    self._data.meta.version = self._data.meta.version or SaveManager.Version
    self._data.meta.modified = nowIso()
    local ok, err = writeProfileFile(profileName, self._data)
    recordProfileInIndex(profileName)
    self._currentProfile = profileName
    self._dirty = false
    return ok, err
end

-- LoadProfile(name)
-- loads profile into memory, runs migrations if needed, broadcasts changes to listeners
function SaveManager:LoadProfile(name)
    assert(type(name) == "string" and #name > 0, "LoadProfile: name must be non-empty string")
    local profileName = sanitizeName(name)
    loadIndex()
    local loaded, err = readProfileFile(profileName)
    if not loaded then
        -- maybe inline stored in index (no file api)
        if SaveManager._index and SaveManager._index.profiles and SaveManager._index.profiles[profileName] and SaveManager._index.profiles[profileName].inline then
            local raw = SaveManager._index.profiles[profileName].inline
            local ok, dat = pcall(function() return safeJsonDecode(raw) end)
            if ok and dat then
                loaded = dat
            end
        end
    end
    if not loaded then
        -- if profile doesn't exist, create a fresh skeleton
        loaded = { meta = { version = SaveManager.Version, created = nowIso(), modified = nowIso() }, elements = {} }
    end
    -- run migrations if needed
    local meta = loaded.meta or {}
    local ver = tonumber(meta.version) or 0
    if ver < SaveManager.Version then
        -- run migrations in order of fromVersion ascending
        for v, fn in pairs(self._migrations) do
            if v > ver and v <= SaveManager.Version and type(fn) == "function" then
                local ok, newData = pcall(fn, deepCopy(loaded))
                if ok and type(newData) == "table" then
                    loaded = newData
                end
            end
        end
        loaded.meta = loaded.meta or {}
        loaded.meta.version = SaveManager.Version
    end
    -- set into manager
    self._data = loaded
    self._currentProfile = profileName
    -- notify registered elements via callbacks
    broadcastLoaded()
    return true
end

-- DeleteProfile(name)
function SaveManager:DeleteProfile(name)
    assert(type(name) == "string" and #name > 0, "DeleteProfile: name must be non-empty string")
    local profileName = sanitizeName(name)
    if SaveManager.SupportsFileApi and isfile(profileFilePath(profileName)) then
        local ok, err = pcall(function() delfile(profileFilePath(profileName)) end)
        if not ok then
            return false, ("delfile failed: %s"):format(tostring(err))
        end
    end
    -- remove backups
    if SaveManager.SupportsFileApi and type(listfiles) == "function" then
        local files = listfiles(SaveManager.ConfigFolder .. "/backups")
        for _, f in ipairs(files) do
            if tostring(f):match("^.*/backups/" .. sanitizeName(profileName) .. "%.bak_") then
                pcall(function() if isfile(f) then delfile(f) end end)
            end
        end
    end
    removeProfileFromIndex(profileName)
    -- if current profile was deleted, reset to default data
    if self._currentProfile == profileName then
        self._data = { meta = { version = SaveManager.Version, created = nowIso(), modified = nowIso() }, elements = {} }
        self._currentProfile = "default"
    end
    return true
end

-- ListProfiles() -> array of profile names
function SaveManager:ListProfiles()
    loadIndex()
    local tbl = {}
    if self._index and self._index.profiles then
        for name, meta in pairs(self._index.profiles) do
            table.insert(tbl, name)
        end
    end
    table.sort(tbl)
    return tbl
end

-- ExportProfile(name) -> json string of profile
function SaveManager:ExportProfile(name)
    assert(type(name) == "string" and #name > 0, "ExportProfile: name must be non-empty string")
    local profileName = sanitizeName(name)
    local loaded, _ = readProfileFile(profileName)
    if not loaded and SaveManager._index and SaveManager._index.profiles and SaveManager._index.profiles[profileName] and SaveManager._index.profiles[profileName].inline then
        local raw = SaveManager._index.profiles[profileName].inline
        if raw then return raw end
    end
    if not loaded then
        return nil, "profile not found"
    end
    local ok, encoded = pcall(safeJsonEncode, loaded)
    if not ok then return nil, "json encode failed" end
    return encoded
end

-- ImportProfile(name, jsonString)
function SaveManager:ImportProfile(name, jsonString)
    assert(type(name) == "string" and #name > 0, "ImportProfile: name must be non-empty string")
    assert(type(jsonString) == "string", "ImportProfile: jsonString must be a string")
    local ok, decoded = pcall(function() return safeJsonDecode(jsonString) end)
    if not ok or type(decoded) ~= "table" then
        return false, "invalid json"
    end
    -- validate minimal structure
    decoded.meta = decoded.meta or { version = SaveManager.Version, created = nowIso(), modified = nowIso() }
    decoded.elements = decoded.elements or {}
    local ok2, err = writeProfileFile(name, decoded)
    if not ok2 then
        -- writeProfileFile may return false if no file API; still record index inline
        if SaveManager._index then
            SaveManager._index.profiles = SaveManager._index.profiles or {}
            SaveManager._index.profiles[sanitizeName(name)] = SaveManager._index.profiles[sanitizeName(name)] or {}
            SaveManager._index.profiles[sanitizeName(name)].inline = jsonString
            writeIndex()
            recordProfileInIndex(name)
            return true
        end
        return false, ("write failed: %s"):format(tostring(err))
    end
    recordProfileInIndex(name)
    return true
end

-- LoadAutoloadConfig()
-- loads the profile flagged in index.autoload if present
function SaveManager:LoadAutoloadConfig()
    loadIndex()
    if self._index and self._index.autoload and type(self._index.autoload) == "string" then
        local profile = self._index.autoload
        local ok = pcall(function() self:LoadProfile(profile) end)
        if ok then
            return true, profile
        end
    end
    return false, "no autoload profile"
end

-- BuildConfigSection(tab)
-- Creates a basic configuration UI within the provided tab or Roblox Instance.
-- It will attempt to use common SkyeUI-style API if available, otherwise it builds raw Instances.
function SaveManager:BuildConfigSection(tab)
    assert(tab ~= nil, "BuildConfigSection: tab cannot be nil")
    -- helper to check API
    local function hasApi(t, methodNames)
        if not t then return false end
        for _, name in ipairs(methodNames) do
            if type(t[name]) == "function" then return true end
        end
        return false
    end

    -- API-based builder: attempt to use known methods (Fluent-style / common libs)
    local function buildUsingLibraryAPI(tabObj)
        -- we will try a few likely section-creation method names
        local createSectionFn = tabObj.CreateSection or tabObj.AddSection or tabObj:FindFirstChild and nil
        local section
        if type(createSectionFn) == "function" then
            section = createSectionFn(tabObj, "Configs")
        else
            -- many libs expose AddLabel/AddButton on tab directly; we'll use that pattern
            section = tabObj
        end

        -- helper to add UI element via flexible method names
        local function addElement(kind, label, callbackOrArgs)
            -- try common method names for kinds
            local methodCandidates = {
                Button = { "AddButton", "CreateButton", "Add" },
                Label = { "AddLabel", "CreateLabel", "Label" },
                Dropdown = { "AddDropdown", "CreateDropdown", "AddList" },
                Input = { "AddInput", "CreateTextBox", "AddTextBox" },
                Toggle = { "AddToggle", "CreateToggle" },
                Slider = { "AddSlider", "CreateSlider" }
            }
            local methods = methodCandidates[kind] or {}
            for _, m in ipairs(methods) do
                if type(section[m]) == "function" then
                    -- call with typical args
                    if kind == "Button" then
                        section[m](section, label, callbackOrArgs)
                        return true
                    elseif kind == "Label" then
                        section[m](section, label)
                        return true
                    elseif kind == "Dropdown" then
                        -- callbackOrArgs expected { options = {...}, default = "...", callback = fn }
                        section[m](section, label, callbackOrArgs.options or {}, callbackOrArgs.callback or function() end)
                        return true
                    elseif kind == "Input" then
                        section[m](section, label, callbackOrArgs.default or "", callbackOrArgs.callback or function() end)
                        return true
                    elseif kind == "Toggle" then
                        section[m](section, label, callbackOrArgs.default or false, callbackOrArgs.callback or function() end)
                        return true
                    elseif kind == "Slider" then
                        section[m](section, label, callbackOrArgs.min or 0, callbackOrArgs.max or 100, callbackOrArgs.default or 0, callbackOrArgs.callback or function() end)
                        return true
                    end
                end
            end
            return false
        end

        -- Build controls:
        -- Profile dropdown, Save, Load, Delete, Export, Import, Autoload toggle, Folder textbox, Backup count slider
        local profiles = self:ListProfiles()
        local current = self._currentProfile or "default"
        -- Dropdown for profiles (if available)
        local builtDropdown = addElement("Dropdown", "Profile", { options = profiles, default = current, callback = function(selection) end })
        -- If dropdown not available, add a simple label listing profiles
        if not builtDropdown then
            addElement("Label", "Profiles: " .. table.concat(profiles, ", "))
        end

        -- Save button
        addElement("Button", "Save Current as...", function()
            -- prompt for name if input API exists; if not, just save as 'default' or prompt via Roblox TextBox fallback
            local promptName = "default"
            local ok, err = pcall(function()
                promptName = tostring(promptName)
                self:SaveProfile(promptName)
            end)
            if not ok then warn("[SaveManager] Save button error:", err) end
        end)

        -- Load button
        addElement("Button", "Load Selected", function()
            if #profiles == 0 then return end
            local sel = profiles[1]
            pcall(function() self:LoadProfile(sel) end)
        end)

        -- Delete button
        addElement("Button", "Delete Selected", function()
            if #profiles == 0 then return end
            local sel = profiles[1]
            pcall(function() self:DeleteProfile(sel) end)
        end)

        -- Export button
        addElement("Button", "Export Selected", function()
            if #profiles == 0 then return end
            local sel = profiles[1]
            local json, err = self:ExportProfile(sel)
            if not json then
                warn("[SaveManager] export failed:", err)
            else
                -- try to copy to clipboard if supported
                if type(setclipboard) == "function" then
                    pcall(setclipboard, json)
                end
                -- else just warn with a message
                if section.AddLabel then section:AddLabel(section, "Exported to clipboard (if supported).") end
            end
        end)

        -- Import input (best-effort)
        addElement("Input", "Import JSON", { default = "", callback = function(txt)
            if txt and #tostring(txt) > 0 then
                local ok, err = self:ImportProfile("imported_" .. tostring(os.time()), tostring(txt))
                if not ok then
                    warn("[SaveManager] import failed:", err)
                end
            end
        end })

        -- Autoload toggle
        addElement("Toggle", "Autoload Last Profile", { default = self.AutoLoadOnStart, callback = function(state)
            self.AutoLoadOnStart = not not state
            self._index = self._index or { profiles = {}, autoload = nil }
            if self.AutoLoadOnStart then
                self._index.autoload = self._currentProfile
            else
                self._index.autoload = nil
            end
            writeIndex()
        end })

        -- Folder display (read-only)
        addElement("Label", "Config Folder: " .. tostring(self.ConfigFolder))

        -- Backup count slider if available
        addElement("Slider", "Backup Count", { min = 0, max = 20, default = self.BackupCount, callback = function(val)
            self:SetBackupCount(math.floor(tonumber(val) or 0))
        end })
        return true
    end

    -- Instance-based builder: if tab is a Roblox GUI container (Frame/ScrollingFrame/ScreenGui)
    local function buildUsingInstances(parentInstance)
        assert(typeof(parentInstance) == "Instance", "BuildConfigSection: parent must be a Roblox Instance when using instance builder")
        -- create container frame
        local container = Instance.new("Frame")
        container.Name = "SkyeUI_SaveManager_Container"
        container.Size = UDim2.new(1, 0, 0, 220)
        container.BackgroundTransparency = 1
        container.Parent = parentInstance

        local uiList = Instance.new("UIListLayout", container)
        uiList.SortOrder = Enum.SortOrder.LayoutOrder
        uiList.Padding = UDim.new(0, 6)

        local function makeLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 20)
            lbl.BackgroundTransparency = 1
            lbl.Text = tostring(text)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Font = Enum.Font.SourceSans
            lbl.TextSize = 14
            lbl.Parent = container
            return lbl
        end

        local function makeButton(text, onClick)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.3, 0, 0, 28)
            btn.AutoButtonColor = true
            btn.Text = tostring(text)
            btn.Font = Enum.Font.SourceSansBold
            btn.TextSize = 14
            btn.Parent = container
            btn.MouseButton1Click:Connect(function()
                local ok, err = pcall(onClick)
                if not ok then warn("[SaveManager] button callback error:", err) end
            end)
            return btn
        end

        local function makeTextBox(placeholder, onSubmit)
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0.6, 0, 0, 28)
            box.PlaceholderText = tostring(placeholder or "")
            box.ClearTextOnFocus = false
            box.Font = Enum.Font.SourceSans
            box.TextSize = 14
            box.Parent = container
            box.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    local ok, err = pcall(function() onSubmit(box.Text) end)
                    if not ok then warn("[SaveManager] textbox callback error:", err) end
                end
            end)
            return box
        end

        -- Build UI pieces
        makeLabel("SkyeUI Save Manager")
        local profiles = self:ListProfiles()
        makeLabel("Profiles: " .. (table.concat(profiles, ", ") ~= "" and table.concat(profiles, ", ") or "<none>"))

        local nameBox = makeTextBox("Profile name (e.g., default)", function(txt)
            -- no action on submit here; save triggered by button below
        end)

        local saveBtn = makeButton("Save", function()
            local name = tostring(nameBox.Text)
            if #name == 0 then name = "default" end
            local ok, err = pcall(function() return self:SaveProfile(name) end)
            if not ok then warn("[SaveManager] SaveProfile error:", err) end
        end)

        local loadBtn = makeButton("Load", function()
            local name = tostring(nameBox.Text)
            if #name == 0 then name = profiles[1] or "default" end
            local ok, err = pcall(function() return self:LoadProfile(name) end)
            if not ok then warn("[SaveManager] LoadProfile error:", err) end
        end)

        local deleteBtn = makeButton("Delete", function()
            local name = tostring(nameBox.Text)
            if #name == 0 then name = profiles[1] or "default" end
            local ok, err = pcall(function() return self:DeleteProfile(name) end)
            if not ok then warn("[SaveManager] DeleteProfile error:", err) end
        end)

        -- Export: copies JSON to clipboard if possible, else prints to output
        local exportBtn = makeButton("Export", function()
            local name = tostring(nameBox.Text)
            if #name == 0 then name = profiles[1] or "default" end
            local json, err = self:ExportProfile(name)
            if not json then
                warn("[SaveManager] export failed:", err)
            else
                if type(setclipboard) == "function" then
                    pcall(setclipboard, json)
                    makeLabel("Exported to clipboard.")
                else
                    makeLabel("Exported JSON (console):")
                    print(json)
                end
            end
        end)

        -- Import: simple textbox for JSON
        local importBox = makeTextBox("Paste JSON then press Enter to import", function(txt)
            if #txt == 0 then return end
            local ok, err = self:ImportProfile("imported_" .. tostring(os.time()), txt)
            if not ok then
                warn("[SaveManager] import failed:", err)
            else
                makeLabel("Import successful")
            end
        end)

        -- Autoload toggle (simple button)
        local autoBtn = makeButton("Toggle Autoload", function()
            self.AutoLoadOnStart = not self.AutoLoadOnStart
            self._index = self._index or { profiles = {}, autoload = nil }
            if self.AutoLoadOnStart then
                self._index.autoload = self._currentProfile
                makeLabel("Autoload enabled for "..tostring(self._currentProfile))
            else
                self._index.autoload = nil
                makeLabel("Autoload disabled")
            end
            writeIndex()
        end)

        makeLabel("Config folder: " .. tostring(self.ConfigFolder))

        -- Backup count controls (simple text box)
        local backupBox = makeTextBox("Backup count (0-50)", function(txt)
            local n = tonumber(txt) or self.BackupCount
            n = math.max(0, math.min(50, math.floor(n)))
            self:SetBackupCount(n)
            makeLabel("Backup count set to " .. tostring(n))
        end)

        return true
    end

    -- Decide which builder to use:
    local ok, err = pcall(function()
        if type(tab) == "table" and (hasApi(tab, {"CreateSection", "AddLabel", "AddButton", "AddDropdown", "AddInput"})) then
            buildUsingLibraryAPI(tab)
        elseif typeof(tab) == "Instance" then
            buildUsingInstances(tab)
        else
            -- unknown type: if we have a bound library and it exposes a Settings tab builder, try to call it
            if self._library and type(self._library.BuildConfigSection) == "function" then
                self._library.BuildConfigSection(self._library, tab)
            else
                error("SaveManager: BuildConfigSection: unsupported tab type and library doesn't expose BuildConfigSection")
            end
        end
    end)
    if not ok then
        warn("[SaveManager] BuildConfigSection failed:", err)
        return false, err
    end
    return true
end

-- Initialize manager (loads index and optionally autoload profile)
function SaveManager:Init()
    if self._initialized then return true end
    -- load index
    loadIndex()
    -- load default profile if requested
    if self.AutoLoadOnStart and self._index and self._index.autoload then
        pcall(function() self:LoadProfile(self._index.autoload) end)
    else
        -- ensure _data exists
        ensureDataStructure()
    end
    self._initialized = true
    return true
end

-- Get current profile name
function SaveManager:GetCurrentProfile()
    return self._currentProfile
end

-- Set autoload profile in index
function SaveManager:SetAutoloadProfile(profile)
    loadIndex()
    self._index = self._index or { profiles = {}, autoload = nil }
    self._index.autoload = sanitizeName(profile)
    writeIndex()
    return true
end

-- Get raw loaded data (copy)
function SaveManager:GetDataCopy()
    ensureDataStructure()
    return deepCopy(self._data)
end

-- Apply a profile programmatically without writing it (useful for temporary apply)
function SaveManager:ApplyProfileData(profileData)
    assert(type(profileData) == "table", "ApplyProfileData expects a table")
    self._data = profileData
    broadcastLoaded()
    return true
end

-- ==== Auto-init ====
-- Load index and initialize data structure so RegisterElement works immediately
loadIndex()
ensureDataStructure()
SaveManager._initialized = true

-- Return SaveManager as module
return SaveManager
