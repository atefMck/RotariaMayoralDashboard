-- Protocol Handler Module
local Protocol = {}
local Accounts = require("accounts")
local Plots = require("plots")
local CityInfo = require("cityinfo")

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
    local Accounts = require("accounts")
    
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

return Protocol

