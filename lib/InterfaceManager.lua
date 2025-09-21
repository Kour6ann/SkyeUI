-- InterfaceManager.lua for SkyeUI
-- Author: Kour6an + GPT
-- Purpose: Manage windows, layouts, and global UI toggles for SkyeUI.

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local InterfaceManager = {}
InterfaceManager.Library = nil
InterfaceManager.Windows = {}
InterfaceManager.Folder = "interfaces"
InterfaceManager.ToggleKey = Enum.KeyCode.RightControl
InterfaceManager.ConfigFile = "interface_layout.json"
InterfaceManager.Visible = true

--// Utility
local function SafeWriteFile(path, data)
    local encoded = HttpService:JSONEncode(data)
    writefile(path, encoded)
end

local function SafeReadFile(path)
    if isfile(path) then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if ok and decoded then
            return decoded
        end
    end
    return nil
end

local function EnsureFolder(path)
    if not isfolder(path) then
        makefolder(path)
    end
end

--// API
function InterfaceManager:SetLibrary(lib)
    assert(lib, "InterfaceManager:SetLibrary() requires SkyeUI library reference")
    self.Library = lib
end

function InterfaceManager:SetFolder(folder)
    self.Folder = folder
    EnsureFolder(self.Folder)
end

function InterfaceManager:AddWindow(window)
    table.insert(self.Windows, window)
end

function InterfaceManager:RemoveWindow(window)
    for i, w in ipairs(self.Windows) do
        if w == window then
            table.remove(self.Windows, i)
            break
        end
    end
end

function InterfaceManager:SetToggleKey(keycode)
    self.ToggleKey = keycode
end

function InterfaceManager:BindToggle()
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.ToggleKey then
            self.Visible = not self.Visible
            for _, win in ipairs(self.Windows) do
                if win.SetVisible then
                    win:SetVisible(self.Visible)
                elseif win.Instance then
                    win.Instance.Visible = self.Visible
                end
            end
        end
    end)
end

function InterfaceManager:SaveLayout()
    local layout = {}
    for _, win in ipairs(self.Windows) do
        if win.GetLayout then
            layout[win.Title or ("Window".._)] = win:GetLayout()
        end
    end
    SafeWriteFile(self.Folder.."/"..self.ConfigFile, layout)
end

function InterfaceManager:LoadLayout()
    local data = SafeReadFile(self.Folder.."/"..self.ConfigFile)
    if not data then return end
    for _, win in ipairs(self.Windows) do
        local key = win.Title or ("Window".._)
        if data[key] and win.ApplyLayout then
            win:ApplyLayout(data[key])
        end
    end
end

function InterfaceManager:BuildInterfaceSection(tab)
    assert(self.Library, "InterfaceManager:BuildInterfaceSection requires library to be set")
    assert(tab, "InterfaceManager:BuildInterfaceSection requires a tab")

    local section = tab:AddSection("Interface Manager")

    -- Toggle Key
    section:AddDropdown("UI_ToggleKey", {
        Title = "Toggle Key",
        Values = {"RightControl", "LeftControl", "Insert", "Delete"},
        Default = "RightControl",
        Callback = function(val)
            self.ToggleKey = Enum.KeyCode[val]
        end
    })

    -- Save Layout Button
    section:AddButton({
        Title = "Save Layout",
        Callback = function()
            self:SaveLayout()
            self.Library:Notify({Title = "Interface", Content = "Layout saved."})
        end
    })

    -- Load Layout Button
    section:AddButton({
        Title = "Load Layout",
        Callback = function()
            self:LoadLayout()
            self.Library:Notify({Title = "Interface", Content = "Layout loaded."})
        end
    })

    -- Reset Visibility
    section:AddButton({
        Title = "Reset Visibility",
        Callback = function()
            self.Visible = true
            for _, win in ipairs(self.Windows) do
                if win.SetVisible then
                    win:SetVisible(true)
                elseif win.Instance then
                    win.Instance.Visible = true
                end
            end
        end
    })
end

return InterfaceManager
