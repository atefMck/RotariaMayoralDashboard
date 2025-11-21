-- Plot Applications Management Module
local Plots = {}
local Encryption = require("encryption")

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

return Plots

