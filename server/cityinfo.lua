-- City Info Management Module (Tabbed System)
local CityInfo = {}
local Encryption = require("encryption")

local CITYINFO_FILE = "cityinfo.dat"
local nextTabId = 1
local infoTabs = {
    {
        id = 1,
        title = "Welcome to Rotaria City",
        content = "Rotaria City is a thriving community built with care and dedication. This is where citizens come together to build, create, and prosper.\n\nStay tuned for updates and announcements from the mayor's office."
    }
}

function CityInfo.load()
    if fs.exists(CITYINFO_FILE) then
        local file = fs.open(CITYINFO_FILE, "r")
        if file then
            local encryptedData = file.readAll()
            file.close()
            if encryptedData and #encryptedData > 0 then
                local success, data = pcall(Encryption.decrypt, encryptedData)
                if success and data then
                    infoTabs = data.tabs or infoTabs
                    nextTabId = data.nextTabId or (#infoTabs + 1)
                    print("Loaded " .. #infoTabs .. " info tabs from file")
                else
                    print("Error: Failed to decrypt city info file")
                end
            end
        end
    else
        print("No city info file found, using defaults")
    end
end

function CityInfo.save()
    local data = {
        tabs = infoTabs,
        nextTabId = nextTabId
    }
    local encryptedData = Encryption.encrypt(data)
    local file = fs.open(CITYINFO_FILE, "w")
    if file then
        file.write(encryptedData)
        file.close()
        print("City info saved successfully")
        return true
    else
        print("Error: Failed to save city info")
        return false
    end
end

-- Get all tabs (public)
function CityInfo.getAllTabs()
    return infoTabs
end

-- Get a specific tab by ID
function CityInfo.getTab(tabId)
    for _, tab in ipairs(infoTabs) do
        if tab.id == tabId then
            return tab
        end
    end
    return nil
end

-- Create a new tab
function CityInfo.createTab(title, content)
    local newTab = {
        id = nextTabId,
        title = title or "Untitled",
        content = content or ""
    }
    table.insert(infoTabs, newTab)
    nextTabId = nextTabId + 1
    
    if CityInfo.save() then
        return true, newTab
    else
        return false, "Failed to save tab"
    end
end

-- Update an existing tab
function CityInfo.updateTab(tabId, title, content)
    for i, tab in ipairs(infoTabs) do
        if tab.id == tabId then
            if title then tab.title = title end
            if content then tab.content = content end
            
            if CityInfo.save() then
                return true, tab
            else
                return false, "Failed to save tab"
            end
        end
    end
    return false, "Tab not found"
end

-- Delete a tab
function CityInfo.deleteTab(tabId)
    for i, tab in ipairs(infoTabs) do
        if tab.id == tabId then
            table.remove(infoTabs, i)
            if CityInfo.save() then
                return true
            else
                return false, "Failed to save after deletion"
            end
        end
    end
    return false, "Tab not found"
end

-- Legacy support: Get first tab (for backward compatibility)
function CityInfo.get()
    if #infoTabs > 0 then
        return infoTabs[1]
    else
        return {
            title = "Welcome to Rotaria City",
            content = "No information available."
        }
    end
end

-- Legacy support: Update first tab (for backward compatibility)
function CityInfo.update(title, content)
    if #infoTabs > 0 then
        return CityInfo.updateTab(infoTabs[1].id, title, content)
    else
        return CityInfo.createTab(title, content)
    end
end

return CityInfo

