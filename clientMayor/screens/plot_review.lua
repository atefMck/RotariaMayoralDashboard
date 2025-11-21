-- Plot Review Screen (Admin only)
local PlotReview = {}
local Network = require("network")
local Utils = require("utils")

function PlotReview.create(mainFrame, account, onBack)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Simple header (same as plot_application.lua)
    screen:addLabel()
        :setText("Rotaria City")
        :setPosition(2, 1)
        :setForeground(colors.orange)
    
    screen:addLabel()
        :setText("powered by CogCorp")
        :setPosition(2, 2)
        :setForeground(colors.lightGray)
    
    -- Logout button
    local logoutBtn = screen:addButton()
        :setText("Logout")
        :setPosition("{parent.width - 9}", 2)
        :setSize(8, 1)
        :setBackground(colors.red)
        :setForeground(colors.white)
        :onClick(function()
            if onBack then
                onBack()
            end
            return true
        end)
    
    -- Content area (scrollable, positioned below header which is 3 lines tall)
    local content = screen:addScrollFrame()
        :setSize("{parent.width}", "{parent.height - 3}")
        :setPosition(1, 4)
        :setBackground(colors.black)
        :setScrollBarBackgroundColor(colors.gray)
        :setScrollBarColor(colors.lightGray)
    
    local yPos = 2
    
    -- Title (positioned at top of content area)
    content:addLabel()
        :setText("Plot Applications Review")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- Plot list
    local plotList = content:addList()
        :setPosition(layout.margin, yPos)
        :setSize(layout.width - 4, math.max(8, layout.height - 20))
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + math.max(8, layout.height - 20) + 2
    
    -- Details frame (not scrollable - parent handles scrolling)
    local detailsFrame = content:addFrame()
        :setPosition(layout.margin, yPos)
        :setSize(layout.width - 4, 12)
        :setBackground(colors.black)
        :addBorder(colors.gray)
    yPos = yPos + 12 + 2
    
    -- Details label with text wrapping (autoSize false = wrap text and expand vertically)
    local detailsLabel = detailsFrame:addLabel()
        :setText("Select an application to view details")
        :setPosition(2, 2)
        :setSize(layout.width - 6, 1)  -- Fixed width, height auto-adjusts (no scrollbar needed)
        :setForeground(colors.lightGray)
        :setAutoSize(false)  -- false = wrap text and expand height
    
    -- Action buttons (initially hidden) - positioned dynamically
    local acceptBtn = detailsFrame:addButton()
        :setText("Accept")
        :setPosition(2, "{parent.height - 2}")
        :setSize(10, 1)
        :setBackground(colors.green)
        :setForeground(colors.white)
        :setVisible(false)
    
    local rejectBtn = detailsFrame:addButton()
        :setText("Reject")
        :setPosition(14, "{parent.height - 2}")
        :setSize(10, 1)
        :setBackground(colors.red)
        :setForeground(colors.white)
        :setVisible(false)
    
    -- Status label
    local statusLabel = content:addLabel()
        :setText("Loading applications...")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.yellow)
    yPos = yPos + 2
    
    -- Back button
    local backBtn = content:addButton()
        :setText("Back")
        :setPosition(layout.margin, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :onClick(function()
            if onBack then
                onBack()
            end
            return true
        end)
    
    local selectedPlot = nil
    local plots = {}
    
    -- Function to display plot details
    local function showPlotDetails(plot)
        selectedPlot = plot
        local details = "Applicant: " .. (plot.applicantUsername or "Unknown") .. "\n"
        details = details .. "In-game name: " .. (plot.inGameName or "N/A") .. "\n"
        details = details .. "Plot: " .. (plot.plotNumber or "N/A") .. "\n"
        details = details .. "Build: " .. (plot.buildDescription or "N/A") .. "\n"
        details = details .. "Size & Style: " .. (plot.estimatedSize or "N/A") .. "\n"
        details = details .. "Reason: " .. (plot.reason or "N/A")
        
        -- Update label with wrapped text (autoSize false wraps and expands height)
        detailsLabel:setText(details)
            :setForeground(colors.white)
            :setSize(layout.width - 6, 1)  -- Fixed width for wrapping
            :setAutoSize(false)  -- Wrap text and expand vertically
        
        -- Position buttons below the text
        local wrappedLines = detailsLabel:getWrappedText()
        local textHeight = #wrappedLines
        acceptBtn:setPosition(2, textHeight + 3)
        rejectBtn:setPosition(14, textHeight + 3)
        
        if plot.status == "pending" then
            acceptBtn:setVisible(true)
            rejectBtn:setVisible(true)
        else
            acceptBtn:setVisible(false)
            rejectBtn:setVisible(false)
        end
    end
    
    -- Handle plot selection
    plotList:onSelect(function(self, index, item)
        if index and type(index) == "number" and plots[index] then
            showPlotDetails(plots[index])
        end
    end)
    
    -- Accept button handler
    acceptBtn:onClick(function()
        if not selectedPlot then return end
        
        statusLabel:setText("Processing...")
            :setForeground(colors.yellow)
        
        local basalt = require("basalt")
        basalt.schedule(function()
            local success, result = Network.updatePlotStatus(account.id, selectedPlot.id, "approved")
            
            if success then
                    statusLabel:setText("Application approved!")
                        :setForeground(colors.green)
                    sleep(1)
                    -- Reload applications
                    local success2, newPlots = Network.getPlotApplications(account.id)
                    if success2 then
                        plots = {}
                        plotList:clear()
                        for _, plot in ipairs(newPlots) do
                            table.insert(plots, plot)
                            plotList:addItem("Plot " .. plot.plotNumber .. " - " .. plot.applicantUsername)
                        end
                        statusLabel:setText("Total pending: " .. #newPlots)
                            :setForeground(colors.green)
                        detailsLabel:setText("Select an application to view details")
                            :setForeground(colors.lightGray)
                            :setSize(layout.width - 6, 1)
                            :setAutoSize(false)
                        acceptBtn:setVisible(false)
                        rejectBtn:setVisible(false)
                        acceptBtn:setPosition(2, 3)
                        rejectBtn:setPosition(14, 3)
                        selectedPlot = nil
                    end
            else
                statusLabel:setText("Error: " .. tostring(result or "Unknown error"))
                    :setForeground(colors.red)
            end
        end)
    end)
    
    -- Reject button handler
    rejectBtn:onClick(function()
        if not selectedPlot then return end
        
        statusLabel:setText("Processing...")
            :setForeground(colors.yellow)
        
        local basalt = require("basalt")
        basalt.schedule(function()
            local success, result = Network.updatePlotStatus(account.id, selectedPlot.id, "rejected")
            
            if success then
                    statusLabel:setText("Application rejected!")
                        :setForeground(colors.green)
                    sleep(1)
                    -- Reload applications
                    local success2, newPlots = Network.getPlotApplications(account.id)
                    if success2 then
                        plots = {}
                        plotList:clear()
                        for _, plot in ipairs(newPlots) do
                            table.insert(plots, plot)
                            plotList:addItem("Plot " .. plot.plotNumber .. " - " .. plot.applicantUsername)
                        end
                        statusLabel:setText("Total pending: " .. #newPlots)
                            :setForeground(colors.green)
                        detailsLabel:setText("Select an application to view details")
                            :setForeground(colors.lightGray)
                            :setSize(layout.width - 6, 1)
                            :setAutoSize(false)
                        acceptBtn:setVisible(false)
                        rejectBtn:setVisible(false)
                        acceptBtn:setPosition(2, 3)
                        rejectBtn:setPosition(14, 3)
                        selectedPlot = nil
                    end
            else
                statusLabel:setText("Error: " .. tostring(result or "Unknown error"))
                    :setForeground(colors.red)
            end
        end)
    end)
    
    -- Load plot applications
    local basalt = require("basalt")
    basalt.schedule(function()
        local success, plotApplications = Network.getPlotApplications(account.id)
        
        if success and plotApplications then
            plots = {}
            plotList:clear()
            for _, plot in ipairs(plotApplications) do
                table.insert(plots, plot)
                plotList:addItem("Plot " .. plot.plotNumber .. " - " .. plot.applicantUsername)
            end
            statusLabel:setText("Total pending: " .. #plotApplications)
                :setForeground(colors.green)
        else
            statusLabel:setText("Failed to load applications: " .. tostring(plotApplications or "Unknown error"))
                :setForeground(colors.red)
        end
    end)
    
    return screen
end

return PlotReview

