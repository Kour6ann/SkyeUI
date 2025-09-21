-- ConfigManager.lua for Skye UI Library
local ConfigManager = {}
ConfigManager.__index = ConfigManager

-- Services
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Default configuration path
local CONFIG_FOLDER = "SkyeUI_Configs"
local DEFAULT_CONFIG_NAME = "default"

-- Initialize config folder
local function ensureConfigFolder()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

-- Initialize ConfigManager
function ConfigManager.new()
    ensureConfigFolder()
    
    local self = setmetatable({
        Configs = {},
        CurrentConfig = DEFAULT_CONFIG_NAME,
        AutoSave = true,
        AutoSaveInterval = 60, -- seconds
        SaveCallbacks = {},
        LoadCallbacks = {}
    }, ConfigManager)
    
    -- Start auto-save thread if enabled
    if self.AutoSave then
        self:StartAutoSave()
    end
    
    return self
end

-- Get config file path
function ConfigManager:GetConfigPath(configName)
    configName = configName or self.CurrentConfig
    return CONFIG_FOLDER .. "/" .. configName .. ".json"
end

-- Register callback for when config is saved
function ConfigManager:OnSave(callbackId, callback)
    self.SaveCallbacks[callbackId] = callback
end

-- Register callback for when config is loaded
function ConfigManager:OnLoad(callbackId, callback)
    self.LoadCallbacks[callbackId] = callback
end

-- Remove save callback
function ConfigManager:RemoveSaveCallback(callbackId)
    self.SaveCallbacks[callbackId] = nil
end

-- Remove load callback
function ConfigManager:RemoveLoadCallback(callbackId)
    self.LoadCallbacks[callbackId] = nil
end

-- Execute all save callbacks
function ConfigManager:ExecuteSaveCallbacks()
    for _, callback in pairs(self.SaveCallbacks) do
        pcall(callback)
    end
end

-- Execute all load callbacks
function ConfigManager:ExecuteLoadCallbacks()
    for _, callback in pairs(self.LoadCallbacks) do
        pcall(callback)
    end
end

-- Save configuration to file
function ConfigManager:Save(configName)
    configName = configName or self.CurrentConfig
    local configPath = self:GetConfigPath(configName)
    
    -- Collect configuration data from registered callbacks
    local configData = {
        Metadata = {
            Name = configName,
            SaveDate = os.date("%Y-%m-%d %H:%M:%S"),
            Version = "1.0"
        },
        Settings = {}
    }
    
    -- Let all registered components save their settings
    self:ExecuteSaveCallbacks()
    
    -- Try to save the file
    local success, err = pcall(function()
        writefile(configPath, HttpService:JSONEncode(configData))
    end)
    
    if success then
        print("Config saved successfully:", configName)
        return true
    else
        warn("Failed to save config:", err)
        return false
    end
end

-- Load configuration from file
function ConfigManager:Load(configName)
    configName = configName or self.CurrentConfig
    local configPath = self:GetConfigPath(configName)
    
    -- Check if config exists
    if not isfile(configPath) then
        warn("Config file does not exist:", configName)
        return false
    end
    
    -- Try to load the file
    local success, configData = pcall(function()
        return HttpService:JSONDecode(readfile(configPath))
    end)
    
    if not success then
        warn("Failed to load config:", configName)
        return false
    end
    
    -- Update current config name
    self.CurrentConfig = configName
    
    -- Let all registered components load their settings
    self:ExecuteLoadCallbacks()
    
    print("Config loaded successfully:", configName)
    return true
end

-- Delete a configuration
function ConfigManager:Delete(configName)
    local configPath = self:GetConfigPath(configName)
    
    if isfile(configPath) then
        local success, err = pcall(function()
            delfile(configPath)
        end)
        
        if success then
            print("Config deleted successfully:", configName)
            return true
        else
            warn("Failed to delete config:", err)
            return false
        end
    else
        warn("Config file does not exist:", configName)
        return false
    end
end

-- Get list of all saved configurations
function ConfigManager:ListConfigs()
    ensureConfigFolder()
    
    local configs = {}
    local files = listfiles(CONFIG_FOLDER)
    
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            local name = file:match("^.+/(.+)%..+$")
            table.insert(configs, name)
        end
    end
    
    return configs
end

-- Set auto-save interval
function ConfigManager:SetAutoSaveInterval(seconds)
    self.AutoSaveInterval = math.max(10, seconds) -- Minimum 10 seconds
    
    -- Restart auto-save if it's running
    if self.AutoSave then
        self:StopAutoSave()
        self:StartAutoSave()
    end
end

-- Start auto-save
function ConfigManager:StartAutoSave()
    self.AutoSave = true
    
    if self.AutoSaveThread then
        self:StopAutoSave()
    end
    
    self.AutoSaveThread = task.spawn(function()
        while self.AutoSave do
            task.wait(self.AutoSaveInterval)
            self:Save()
        end
    end)
end

-- Stop auto-save
function ConfigManager:StopAutoSave()
    self.AutoSave = false
    if self.AutoSaveThread then
        task.cancel(self.AutoSaveThread)
        self.AutoSaveThread = nil
    end
end

-- Export configuration as a string (for sharing)
function ConfigManager:ExportConfig(configName)
    configName = configName or self.CurrentConfig
    local configPath = self:GetConfigPath(configName)
    
    if not isfile(configPath) then
        return nil
    end
    
    local success, configString = pcall(function()
        return readfile(configPath)
    end)
    
    if success then
        return configString
    else
        return nil
    end
end

-- Import configuration from a string
function ConfigManager:ImportConfig(configString, configName)
    configName = configName or self.CurrentConfig
    
    local success, configData = pcall(function()
        return HttpService:JSONDecode(configString)
    end)
    
    if not success then
        return false
    end
    
    local configPath = self:GetConfigPath(configName)
    
    local writeSuccess, err = pcall(function()
        writefile(configPath, HttpService:JSONEncode(configData))
    end)
    
    if writeSuccess then
        return true
    else
        warn("Failed to import config:", err)
        return false
    end
end

-- Reset to default configuration
function ConfigManager:ResetToDefault()
    local defaultPath = self:GetConfigPath(DEFAULT_CONFIG_NAME)
    
    if isfile(defaultPath) then
        return self:Load(DEFAULT_CONFIG_NAME)
    else
        -- Create a new default config
        self.CurrentConfig = DEFAULT_CONFIG_NAME
        self:ExecuteSaveCallbacks()
        return self:Save(DEFAULT_CONFIG_NAME)
    end
end

-- UI integration for configuration management
function ConfigManager:CreateConfigUI(parentWindow)
    local configTab = parentWindow:AddTab("Configuration")
    local configSection = parentWindow:AddSection("Configuration", "Settings Management")
    
    -- Config selection dropdown
    local configs = self:ListConfigs()
    local currentConfig = self.CurrentConfig
    
    local configDropdown = parentWindow:CreateDropdown(configSection, "Active Configuration", configs, currentConfig, function(value)
        self.CurrentConfig = value
        self:Load(value)
    end)
    
    -- New config button
    local newConfigInput = parentWindow:CreateInput(configSection, "New Config Name", "Enter config name", function(value)
        -- This will be used when creating new config
    end)
    
    local createButton = parentWindow:CreateButton(configSection, "Create New Config", function()
        local newName = newConfigInput.Value
        if newName and newName ~= "" then
            if not table.find(configs, newName) then
                self.CurrentConfig = newName
                self:Save(newName)
                
                -- Refresh dropdown
                configs = self:ListConfigs()
                configDropdown.Options = configs
                configDropdown.Value = newName
            else
                parentWindow:Notify({
                    Title = "Config Exists",
                    Content = "A configuration with this name already exists.",
                    Duration = 3
                })
            end
        end
    end)
    
    -- Save button
    local saveButton = parentWindow:CreateButton(configSection, "Save Current Config", function()
        if self:Save() then
            parentWindow:Notify({
                Title = "Config Saved",
                Content = "Configuration saved successfully.",
                Duration = 3
            })
        else
            parentWindow:Notify({
                Title = "Save Failed",
                Content = "Failed to save configuration.",
                Duration = 3
            })
        end
    end)
    
    -- Delete button
    local deleteButton = parentWindow:CreateButton(configSection, "Delete Current Config", function()
        if self.CurrentConfig ~= DEFAULT_CONFIG_NAME then
            if self:Delete(self.CurrentConfig) then
                -- Switch to default config
                self.CurrentConfig = DEFAULT_CONFIG_NAME
                self:Load(DEFAULT_CONFIG_NAME)
                
                -- Refresh dropdown
                configs = self:ListConfigs()
                configDropdown.Options = configs
                configDropdown.Value = DEFAULT_CONFIG_NAME
                
                parentWindow:Notify({
                    Title = "Config Deleted",
                    Content = "Configuration deleted successfully.",
                    Duration = 3
                })
            else
                parentWindow:Notify({
                    Title = "Delete Failed",
                    Content = "Failed to delete configuration.",
                    Duration = 3
                })
            end
        else
            parentWindow:Notify({
                Title = "Cannot Delete",
                Content = "Cannot delete the default configuration.",
                Duration = 3
            })
        end
    end)
    
    -- Auto-save toggle
    local autoSaveToggle = parentWindow:CreateToggle(configSection, "Enable Auto-Save", self.AutoSave, function(value)
        self.AutoSave = value
        if value then
            self:StartAutoSave()
        else
            self:StopAutoSave()
        end
    end)
    
    -- Auto-save interval slider
    local intervalSlider = parentWindow:CreateSlider(configSection, "Auto-Save Interval (seconds)", 10, 300, self.AutoSaveInterval, function(value)
        self:SetAutoSaveInterval(value)
    end)
    
    -- Export/Import section
    local importExportSection = parentWindow:AddSection("Configuration", "Import & Export")
    
    local exportInput = parentWindow:CreateInput(importExportSection, "Export Config Name", "Enter config name to export", function(value)
        -- This will be used for export
    end)
    
    local exportButton = parentWindow:CreateButton(importExportSection, "Export Configuration", function()
        local configName = exportInput.Value ~= "" and exportInput.Value or self.CurrentConfig
        local configString = self:ExportConfig(configName)
        
        if configString then
            -- In a real implementation, you might copy to clipboard or show the string
            parentWindow:Notify({
                Title = "Config Exported",
                Content = "Configuration exported successfully.",
                Duration = 3
            })
            
            -- For demonstration, we'll just print it
            print("Exported config:", configString)
        else
            parentWindow:Notify({
                Title = "Export Failed",
                Content = "Failed to export configuration.",
                Duration = 3
            })
        end
    end)
    
    local importInput = parentWindow:CreateInput(importExportSection, "Import Config Data", "Paste config data here", function(value)
        -- This will be used for import
    end)
    
    local importNameInput = parentWindow:CreateInput(importExportSection, "Import As", "Name for imported config", function(value)
        -- This will be the name for the imported config
    end)
    
    local importButton = parentWindow:CreateButton(importExportSection, "Import Configuration", function()
        local configString = importInput.Value
        local configName = importNameInput.Value
        
        if configString and configString ~= "" and configName and configName ~= "" then
            if self:ImportConfig(configString, configName) then
                -- Refresh dropdown
                configs = self:ListConfigs()
                configDropdown.Options = configs
                
                parentWindow:Notify({
                    Title = "Config Imported",
                    Content = "Configuration imported successfully.",
                    Duration = 3
                })
            else
                parentWindow:Notify({
                    Title = "Import Failed",
                    Content = "Failed to import configuration.",
                    Duration = 3
                })
            end
        end
    end)
    
    -- Reset button
    local resetButton = parentWindow:CreateButton(importExportSection, "Reset to Default", function()
        if self:ResetToDefault() then
            -- Refresh dropdown
            configs = self:ListConfigs()
            configDropdown.Options = configs
            configDropdown.Value = DEFAULT_CONFIG_NAME
            
            parentWindow:Notify({
                Title = "Config Reset",
                Content = "Configuration reset to default.",
                Duration = 3
            })
        else
            parentWindow:Notify({
                Title = "Reset Failed",
                Content = "Failed to reset configuration.",
                Duration = 3
            })
        end
    end)
    
    return {
        Tab = configTab,
        Section = configSection,
        Dropdown = configDropdown,
        AutoSaveToggle = autoSaveToggle,
        IntervalSlider = intervalSlider
    }
end

return ConfigManager
