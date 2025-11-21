-- Bundled Rotaria City Server
-- This file contains all server modules bundled together

-- Version Information
local VERSION = "1.0.0"

-- ============================================================================
-- Encryption Module
-- ============================================================================
local Encryption = {}

-- Define and load encryption key from settings (same as CogMail)
settings.define("email.encryption_key", {
    description = "Encryption key for city server data",
    default = "email_server_key_2024",
    type = "string"
})
settings.load()

function Encryption.encrypt(data, key)
    key = key or settings.get("email.encryption_key")
    if type(data) ~= "string" then
        data = textutils.serialize(data)
    end
    local encrypted = {}
    local keyLen = #key
    for i = 1, #data do
        local byte = string.byte(data, i)
        local keyByte = string.byte(key, ((i - 1) % keyLen) + 1)
        encrypted[i] = string.char((byte + keyByte) % 256)
    end
    return table.concat(encrypted)
end

function Encryption.decrypt(encrypted, key)
    key = key or settings.get("email.encryption_key")
    local decrypted = {}
    local keyLen = #key
    for i = 1, #encrypted do
        local byte = string.byte(encrypted, i)
        local keyByte = string.byte(key, ((i - 1) % keyLen) + 1)
        decrypted[i] = string.char((byte - keyByte) % 256)
    end
    local data = table.concat(decrypted)
    return textutils.unserialize(data) or data
end

-- ============================================================================
-- Accounts Module
-- ============================================================================
local Accounts = {}

local ACCOUNTS_FILE = "accounts.dat"
local accounts = {}
local nextAccountId = 1

-- Define and load password salt from settings (same as CogMail)
settings.define("email.password_salt", {
    description = "Salt key for password hashing",
    default = "email_server_salt_2024",
    type = "string"
})
settings.load()

-- Password hashing function (same as CogMail)
local function hashPassword(password, salt)
    salt = salt or settings.get("email.password_salt")
    local hash = password .. salt
    
    -- Multiple rounds of transformation for better security
    for round = 1, 5 do
        local newHash = ""
        for i = 1, #hash do
            local byte = string.byte(hash, i)
            -- Mix bytes with salt and round number
            local mixed = ((byte + string.byte(salt, ((i - 1) % #salt) + 1) + round) % 256)
            newHash = newHash .. string.char(mixed)
        end
        hash = newHash
    end
    
    -- Convert to hex-like string representation
    local hexHash = ""
    for i = 1, math.min(#hash, 32) do  -- Limit to 32 chars for storage
        local byte = string.byte(hash, i)
        hexHash = hexHash .. string.format("%02x", byte)
    end
    
    return hexHash
end

function Accounts.load()
    if fs.exists(ACCOUNTS_FILE) then
        local file = fs.open(ACCOUNTS_FILE, "r")
        if file then
            local fileData = file.readAll()
            file.close()
            if fileData and #fileData > 0 then
                local success, data = pcall(textutils.unserialize, fileData)
                if success and data then
                    accounts = data.accounts or {}
                    nextAccountId = data.nextId or 1
                    print("Loaded " .. #accounts .. " accounts from file")
                else
                    print("Error: Failed to load accounts file")
                    accounts = {}
                end
            end
        end
    else
        print("No accounts file found, starting fresh")
        accounts = {}
    end
end

function Accounts.save()
    local data = {
        accounts = accounts,
        nextId = nextAccountId
    }
    local serializedData = textutils.serialize(data)
    local file = fs.open(ACCOUNTS_FILE, "w")
    if file then
        file.write(serializedData)
        file.close()
        print("Accounts saved successfully")
        return true
    else
        print("Error: Failed to save accounts")
        return false
    end
end

function Accounts.findByUsername(username)
    for i, account in ipairs(accounts) do
        if account.username == username then
            return account, i
        end
    end
    return nil, nil
end

function Accounts.findById(id)
    for i, account in ipairs(accounts) do
        if account.id == id then
            return account, i
        end
    end
    return nil, nil
end

function Accounts.getAllUsernames()
    local usernames = {}
    for _, account in ipairs(accounts) do
        table.insert(usernames, account.username)
    end
    return usernames
end

function Accounts.getAll()
    return accounts
end

function Accounts.create(username, password, accountType)
    accountType = accountType or "citizen"  -- Default to citizen
    
    -- Validate username
    if not username or username == "" then
        return false, "Username cannot be empty"
    end
    
    if #username < 3 then
        return false, "Username must be at least 3 characters"
    end
    
    if #username > 20 then
        return false, "Username must be at most 20 characters"
    end
    
    -- Check if username already exists
    if Accounts.findByUsername(username) then
        return false, "Username already exists"
    end
    
    -- Validate password
    if not password or password == "" then
        return false, "Password cannot be empty"
    end
    
    if #password < 4 then
        return false, "Password must be at least 4 characters"
    end
    
    -- Validate account type
    if accountType ~= "admin" and accountType ~= "citizen" then
        return false, "Invalid account type"
    end
    
    -- Create new account with hashed password
    local account = {
        id = nextAccountId,
        username = username,
        password = hashPassword(password, username), -- Hash password with username as salt
        accountType = accountType
    }
    
    table.insert(accounts, account)
    nextAccountId = nextAccountId + 1
    
    -- Save to file
    if Accounts.save() then
        print("Account created: " .. username .. " (ID: " .. account.id .. ", Type: " .. accountType .. ")")
        return true, account
    else
        -- Rollback on save failure
        table.remove(accounts)
        nextAccountId = nextAccountId - 1
        return false, "Failed to save account"
    end
end

function Accounts.verify(username, password)
    local account = Accounts.findByUsername(username)
    if account then
        -- Hash the provided password and compare with stored hash
        local hashedPassword = hashPassword(password, username)
        if account.password == hashedPassword then
            return true, account
        end
    end
    return false, "Invalid username or password"
end

function Accounts.verifyAuth(accountId)
    local account = Accounts.findById(accountId)
    if account then
        return true, account
    end
    return false, "Account not found"
end

function Accounts.changeAccountType(accountId, newType)
    if newType ~= "admin" and newType ~= "citizen" then
        return false, "Invalid account type"
    end
    
    local account = Accounts.findById(accountId)
    if not account then
        return false, "Account not found"
    end
    
    account.accountType = newType
    
    if Accounts.save() then
        print("Account " .. account.username .. " type changed to " .. newType)
        return true, account
    else
        return false, "Failed to save account"
    end
end

function Accounts.delete(accountId)
    local account, index = Accounts.findById(accountId)
    if not account then
        return false, "Account not found"
    end
    
    -- Remove account from list
    table.remove(accounts, index)
    
    if Accounts.save() then
        print("Account " .. account.username .. " deleted")
        return true
    else
        -- Rollback on save failure
        table.insert(accounts, index, account)
        return false, "Failed to save after deletion"
    end
end

-- ============================================================================
-- Plots Module
-- ============================================================================
local Plots = {}
-- Encryption module loaded above

local PLOTS_FILE = "plots.dat"
local plots = {}
local nextPlotId = 1

function Plots.load()
    if fs.exists(PLOTS_FILE) then
        local file = fs.open(PLOTS_FILE, "r")
        if file then
            local encryptedData = file.readAll()
            file.close()
            if encryptedData and #encryptedData > 0 then
                local success, data = pcall(Encryption.decrypt, encryptedData)
                if success and data then
                    plots = data.plots or {}
                    nextPlotId = data.nextId or 1
                    print("Loaded " .. #plots .. " plot applications from file")
                else
                    print("Error: Failed to decrypt plots file")
                    plots = {}
                end
            end
        end
    else
        print("No plots file found, starting fresh")
        plots = {}
    end
end

function Plots.save()
    local data = {
        plots = plots,
        nextId = nextPlotId
    }
    local encryptedData = Encryption.encrypt(data)
    local file = fs.open(PLOTS_FILE, "w")
    if file then
        file.write(encryptedData)
        file.close()
        print("Plots saved successfully")
        return true
    else
        print("Error: Failed to save plots")
        return false
    end
end

function Plots.create(applicantId, inGameName, plotNumber, buildDescription, estimatedSize, reason)
    -- applicantId can be 0 or nil for public applications
    applicantId = applicantId or 0
    local plot = {
        id = nextPlotId,
        applicantId = applicantId,
        inGameName = inGameName,
        plotNumber = plotNumber,
        buildDescription = buildDescription,
        estimatedSize = estimatedSize,
        reason = reason,
        status = "pending",  -- pending, approved, rejected
        timestamp = os.time()
    }
    
    table.insert(plots, plot)
    nextPlotId = nextPlotId + 1
    
    if Plots.save() then
        print("Plot application created: ID " .. plot.id .. " by user " .. applicantId)
        return true, plot
    else
        -- Rollback on save failure
        table.remove(plots)
        nextPlotId = nextPlotId - 1
        return false, "Failed to save plot application"
    end
end

function Plots.getAll()
    return plots
end

function Plots.getPending()
    local pending = {}
    for _, plot in ipairs(plots) do
        if plot.status == "pending" then
            table.insert(pending, plot)
        end
    end
    -- Sort by timestamp, oldest first
    table.sort(pending, function(a, b) return a.timestamp < b.timestamp end)
    return pending
end

function Plots.getById(plotId)
    for _, plot in ipairs(plots) do
        if plot.id == plotId then
            return plot
        end
    end
    return nil
end

function Plots.getByApplicant(applicantId)
    local userPlots = {}
    for _, plot in ipairs(plots) do
        if plot.applicantId == applicantId then
            table.insert(userPlots, plot)
        end
    end
    -- Sort by timestamp, newest first
    table.sort(userPlots, function(a, b) return a.timestamp > b.timestamp end)
    return userPlots
end

function Plots.updateStatus(plotId, status)
    if status ~= "approved" and status ~= "rejected" then
        return false, "Invalid status"
    end
    
    local plot = Plots.getById(plotId)
    if not plot then
        return false, "Plot application not found"
    end
    
    plot.status = status
    if Plots.save() then
        print("Plot application " .. plotId .. " updated to " .. status)
        return true, plot
    else
        return false, "Failed to save plot status"
    end
end

-- ============================================================================
-- CityInfo Module
-- ============================================================================
local CityInfo = {}
-- Encryption module loaded above

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

-- ============================================================================
-- Protocol Module
-- ============================================================================
local Protocol = {}
-- Accounts, Plots, CityInfo modules loaded above

function Protocol.handleCreateAccount(replyChannel, modem, data)
    local username = data.username
    local password = data.password
    local accountType = data.accountType or "citizen"
    
    local success, result = Accounts.create(username, password, accountType)
    
    local response = {
        type = "create_account_response",
        success = success,
        message = success and "Account created successfully" or result,
        account = success and {id = result.id, username = result.username, accountType = result.accountType} or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleLogin(replyChannel, modem, data)
    local username = data.username
    local password = data.password
    
    local success, result = Accounts.verify(username, password)
    
    local response = {
        type = "login_response",
        success = success,
        message = success and "Login successful" or result,
        account = success and {id = result.id, username = result.username, accountType = result.accountType} or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleGetAccountInfo(replyChannel, modem, data)
    local accountId = data.accountId
    
    -- Verify authentication
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess then
        local response = {
            type = "account_info_response",
            success = false,
            message = "Authentication required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local response = {
        type = "account_info_response",
        success = true,
        account = {id = account.id, username = account.username, accountType = account.accountType},
        message = "Account found"
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleGetAllUsers(replyChannel, modem, data)
    local accountId = data.accountId
    
    -- Verify authentication and admin status
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess or account.accountType ~= "admin" then
        local response = {
            type = "all_users_response",
            success = false,
            message = "Admin access required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local allAccounts = Accounts.getAll()
    local safeAccounts = {}
    for _, acc in ipairs(allAccounts) do
        table.insert(safeAccounts, {
            id = acc.id,
            username = acc.username,
            accountType = acc.accountType
        })
    end
    
    local response = {
        type = "all_users_response",
        success = true,
        users = safeAccounts
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleCreatePlotApplication(replyChannel, modem, data)
    local accountId = data.accountId
    
    -- Verify authentication
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess then
        local response = {
            type = "create_plot_response",
            success = false,
            message = "Authentication required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local inGameName = data.inGameName
    local plotNumber = data.plotNumber
    local buildDescription = data.buildDescription
    local estimatedSize = data.estimatedSize
    local reason = data.reason
    
    local success, result = Plots.create(accountId, inGameName, plotNumber, buildDescription, estimatedSize, reason)
    
    local response = {
        type = "create_plot_response",
        success = success,
        message = success and "Plot application submitted successfully" or result,
        plot = success and {id = result.id} or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleCreatePlotApplicationPublic(replyChannel, modem, data)
    -- No authentication required for public plot applications
    local inGameName = data.inGameName
    local plotNumber = data.plotNumber
    local buildDescription = data.buildDescription
    local estimatedSize = data.estimatedSize
    local reason = data.reason
    
    local success, result = Plots.create(0, inGameName, plotNumber, buildDescription, estimatedSize, reason)
    
    local response = {
        type = "create_plot_application_public_response",
        success = success,
        message = success and "Plot application submitted successfully" or result,
        plot = success and {id = result.id} or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleGetPlotApplications(replyChannel, modem, data)
    local accountId = data.accountId
    
    -- Verify authentication and admin status
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess or account.accountType ~= "admin" then
        local response = {
            type = "plot_applications_response",
            success = false,
            message = "Admin access required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local pending = Plots.getPending()
    
    -- Add applicant username to each plot
    local safePlots = {}
    for _, plot in ipairs(pending) do
        local applicantUsername = "Public Application"
        if plot.applicantId and plot.applicantId > 0 then
            local applicant = Accounts.findById(plot.applicantId)
            applicantUsername = applicant and applicant.username or "Unknown"
        end
        table.insert(safePlots, {
            id = plot.id,
            applicantId = plot.applicantId or 0,
            applicantUsername = applicantUsername,
            inGameName = plot.inGameName,
            plotNumber = plot.plotNumber,
            buildDescription = plot.buildDescription,
            estimatedSize = plot.estimatedSize,
            reason = plot.reason,
            status = plot.status,
            timestamp = plot.timestamp
        })
    end
    
    local response = {
        type = "plot_applications_response",
        success = true,
        plots = safePlots
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleGetMyPlots(replyChannel, modem, data)
    local accountId = data.accountId
    
    -- Verify authentication
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess then
        local response = {
            type = "my_plots_response",
            success = false,
            message = "Authentication required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local userPlots = Plots.getByApplicant(accountId)
    
    local response = {
        type = "my_plots_response",
        success = true,
        plots = userPlots
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleUpdatePlotStatus(replyChannel, modem, data)
    local accountId = data.accountId
    local plotId = data.plotId
    local status = data.status
    
    -- Verify authentication and admin status
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess or account.accountType ~= "admin" then
        local response = {
            type = "update_plot_status_response",
            success = false,
            message = "Admin access required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local success, result = Plots.updateStatus(plotId, status)
    
    local response = {
        type = "update_plot_status_response",
        success = success,
        message = success and "Plot status updated" or result,
        plot = success and result or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleGetCityInfo(replyChannel, modem, data)
    local accountId = data.accountId
    
    -- Verify authentication
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess then
        local response = {
            type = "city_info_response",
            success = false,
            message = "Authentication required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local info = CityInfo.get()
    
    local response = {
        type = "city_info_response",
        success = true,
        cityInfo = info
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleGetCityInfoPublic(replyChannel, modem, data)
    -- No authentication required - return all tabs
    local tabs = CityInfo.getAllTabs()
    
    local response = {
        type = "get_city_info_public_response",
        success = true,
        tabs = tabs
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleGetAllInfoTabs(replyChannel, modem, data)
    local accountId = data.accountId
    
    -- Verify authentication and admin status
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess or account.accountType ~= "admin" then
        local response = {
            type = "get_all_info_tabs_response",
            success = false,
            message = "Admin access required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local tabs = CityInfo.getAllTabs()
    
    local response = {
        type = "get_all_info_tabs_response",
        success = true,
        tabs = tabs
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleCreateInfoTab(replyChannel, modem, data)
    local accountId = data.accountId
    local title = data.title
    local content = data.content
    
    -- Verify authentication and admin status
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess or account.accountType ~= "admin" then
        local response = {
            type = "create_info_tab_response",
            success = false,
            message = "Admin access required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local success, result = CityInfo.createTab(title, content)
    
    local response = {
        type = "create_info_tab_response",
        success = success,
        message = success and "Tab created successfully" or result,
        tab = success and result or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleUpdateInfoTab(replyChannel, modem, data)
    local accountId = data.accountId
    local tabId = data.tabId
    local title = data.title
    local content = data.content
    
    -- Verify authentication and admin status
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess or account.accountType ~= "admin" then
        local response = {
            type = "update_info_tab_response",
            success = false,
            message = "Admin access required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local success, result = CityInfo.updateTab(tabId, title, content)
    
    local response = {
        type = "update_info_tab_response",
        success = success,
        message = success and "Tab updated successfully" or result,
        tab = success and result or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleDeleteInfoTab(replyChannel, modem, data)
    local accountId = data.accountId
    local tabId = data.tabId
    
    -- Verify authentication and admin status
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess or account.accountType ~= "admin" then
        local response = {
            type = "delete_info_tab_response",
            success = false,
            message = "Admin access required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local success, result = CityInfo.deleteTab(tabId)
    
    local response = {
        type = "delete_info_tab_response",
        success = success,
        message = success and "Tab deleted successfully" or result
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleUpdateCityInfo(replyChannel, modem, data)
    local accountId = data.accountId
    local title = data.title
    local content = data.content
    
    -- Verify authentication and admin status
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess or account.accountType ~= "admin" then
        local response = {
            type = "update_city_info_response",
            success = false,
            message = "Admin access required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local success, result = CityInfo.update(title, content)
    
    local response = {
        type = "update_city_info_response",
        success = success,
        message = success and "City info updated" or result,
        cityInfo = success and result or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleChangeAccountType(replyChannel, modem, data)
    local accountId = data.accountId
    local targetAccountId = data.targetAccountId
    local newType = data.newType
    
    -- Verify authentication and admin status
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess or account.accountType ~= "admin" then
        local response = {
            type = "change_account_type_response",
            success = false,
            message = "Admin access required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local success, result = Accounts.changeAccountType(targetAccountId, newType)
    
    local response = {
        type = "change_account_type_response",
        success = success,
        message = success and "Account type changed" or result,
        account = success and {id = result.id, username = result.username, accountType = result.accountType} or nil
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.handleDeleteAccount(replyChannel, modem, data)
    local accountId = data.accountId
    local targetAccountId = data.targetAccountId
    
    -- Verify authentication and admin status
    local authSuccess, account = Accounts.verifyAuth(accountId)
    if not authSuccess or account.accountType ~= "admin" then
        local response = {
            type = "delete_account_response",
            success = false,
            message = "Admin access required"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    -- Prevent deleting your own account
    if accountId == targetAccountId then
        local response = {
            type = "delete_account_response",
            success = false,
            message = "Cannot delete your own account"
        }
        modem.transmit(replyChannel, 100, response)
        return
    end
    
    local success, result = Accounts.delete(targetAccountId)
    
    local response = {
        type = "delete_account_response",
        success = success,
        message = success and "Account deleted" or result
    }
    
    modem.transmit(replyChannel, 100, response)
end

function Protocol.processMessage(channel, replyChannel, message, distance, modem)
    if type(message) ~= "table" then
        return
    end
    
    local msgType = message.type
    
    if msgType == "create_account" then
        Protocol.handleCreateAccount(replyChannel, modem, message)
    elseif msgType == "login" then
        Protocol.handleLogin(replyChannel, modem, message)
    elseif msgType == "get_account_info" then
        Protocol.handleGetAccountInfo(replyChannel, modem, message)
    elseif msgType == "get_all_users" then
        Protocol.handleGetAllUsers(replyChannel, modem, message)
    elseif msgType == "create_plot_application" then
        Protocol.handleCreatePlotApplication(replyChannel, modem, message)
    elseif msgType == "get_plot_applications" then
        Protocol.handleGetPlotApplications(replyChannel, modem, message)
    elseif msgType == "get_my_plots" then
        Protocol.handleGetMyPlots(replyChannel, modem, message)
    elseif msgType == "update_plot_status" then
        Protocol.handleUpdatePlotStatus(replyChannel, modem, message)
    elseif msgType == "get_city_info" then
        Protocol.handleGetCityInfo(replyChannel, modem, message)
    elseif msgType == "update_city_info" then
        Protocol.handleUpdateCityInfo(replyChannel, modem, message)
    elseif msgType == "get_city_info_public" then
        Protocol.handleGetCityInfoPublic(replyChannel, modem, message)
    elseif msgType == "create_plot_application_public" then
        Protocol.handleCreatePlotApplicationPublic(replyChannel, modem, message)
    elseif msgType == "change_account_type" then
        Protocol.handleChangeAccountType(replyChannel, modem, message)
    elseif msgType == "delete_account" then
        Protocol.handleDeleteAccount(replyChannel, modem, message)
    elseif msgType == "get_all_info_tabs" then
        Protocol.handleGetAllInfoTabs(replyChannel, modem, message)
    elseif msgType == "create_info_tab" then
        Protocol.handleCreateInfoTab(replyChannel, modem, message)
    elseif msgType == "update_info_tab" then
        Protocol.handleUpdateInfoTab(replyChannel, modem, message)
    elseif msgType == "delete_info_tab" then
        Protocol.handleDeleteInfoTab(replyChannel, modem, message)
    else
        local response = {
            type = "error",
            message = "Unknown message type: " .. tostring(msgType)
        }
        modem.transmit(replyChannel, 100, response)
    end
end

-- ============================================================================
-- Main Server Entry Point
-- ============================================================================
local Server = {}

function Server.runServer()
-- Version Information
local VERSION = "1.0.0"

-- Accounts, Plots, CityInfo, Protocol modules loaded above

local modem = peripheral.find("modem") or error("No modem attached", 0)
local SERVER_CHANNEL = 100
local CLIENT_CHANNEL = 200

-- Initialize Server
print("=== Rotaria City Server Starting ===")
print("Computer ID: " .. os.getComputerID())
print("Opening channels " .. SERVER_CHANNEL .. " (server) and " .. CLIENT_CHANNEL .. " (client)")

modem.open(SERVER_CHANNEL)
modem.open(CLIENT_CHANNEL)
Accounts.load()
Plots.load()
CityInfo.load()

-- Create default admin account if it doesn't exist
local defaultAdmin = Accounts.findByUsername("Rotaria City")
if not defaultAdmin then
    print("Creating default admin account...")
    local success, result = Accounts.create("Rotaria City", "Rotaria!0!", "admin")
    if success then
        print("Default admin account created: Rotaria City")
    else
        print("Warning: Failed to create default admin account: " .. tostring(result))
    end
else
    print("Default admin account already exists")
end

print("Server ready. Listening on channel " .. SERVER_CHANNEL)
print("Commands:")
print("  - create_account: Create a new account (admin or citizen)")
print("  - login: Login to an existing account")
print("  - get_all_users: Get all users (admin only)")
print("  - create_plot_application: Submit a plot application")
print("  - get_plot_applications: Get pending plot applications (admin only)")
print("  - update_plot_status: Approve/reject plot application (admin only)")
print("  - get_city_info: Get city information")
print("  - update_city_info: Update city information (admin only)")
print("")

-- Event Loop
while true do
    local success, err = pcall(function()
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        
        if channel == SERVER_CHANNEL then
            print("Received message on channel " .. channel .. " from reply channel " .. replyChannel)
            Protocol.processMessage(channel, replyChannel, message, distance, modem)
        end
    end)
    
    if not success then
        print("Error occurred: " .. tostring(err))
        -- Continue running the server even if there's an error
    end
end

end

return Server

