-- Plot Application Screen
local PlotApplication = {}
local Network = require("network")
local Utils = require("utils")

function PlotApplication.create(mainFrame, account, onBack)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Simple header (no logout for citizen client)
    screen:addLabel()
        :setText("Rotaria City")
        :setPosition(2, 1)
        :setForeground(colors.orange)
    
    screen:addLabel()
        :setText("powered by CogCorp")
        :setPosition(2, 2)
        :setForeground(colors.lightGray)
    
    -- Content area (scrollable)
    local content = screen:addScrollFrame()
        :setSize("{parent.width}", "{parent.height - 3}")
        :setPosition(1, 4)
        :setBackground(colors.black)
        :setScrollBarBackgroundColor(colors.gray)
        :setScrollBarColor(colors.lightGray)
    
    local yPos = 2
    
    -- Title
    content:addLabel()
        :setText("Plot Application Form")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- In-game name
    content:addLabel()
        :setText("In-game name:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local inGameNameInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 2
    
    -- Plot number/location
    content:addLabel()
        :setText("Plot number / location:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local plotNumberInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 2
    
    -- What the build will be
    content:addLabel()
        :setText("What the build will be:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local buildDescriptionInput = content:addTextBox()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 3)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 4
    
    -- Estimated size & style
    content:addLabel()
        :setText("Estimated size & style:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local estimatedSizeInput = content:addTextBox()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 2)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 3
    
    -- Why they want that specific plot
    content:addLabel()
        :setText("Why you want that specific plot:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local reasonInput = content:addTextBox()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 3)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 4
    
    -- Status label
    local statusLabel = content:addLabel()
        :setText("")
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setForeground(colors.red)
    yPos = yPos + 2
    
    -- Submit button
    local submitBtn = content:addButton()
        :setText("Submit Application")
        :setPosition(layout.margin, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.green)
        :setForeground(colors.white)
        :onClick(function()
            local inGameName = inGameNameInput:getText() or ""
            local plotNumber = plotNumberInput:getText() or ""
            local buildDescription = buildDescriptionInput:getText() or ""
            local estimatedSize = estimatedSizeInput:getText() or ""
            local reason = reasonInput:getText() or ""
            
            if not inGameName or inGameName == "" then
                statusLabel:setText("In-game name cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            if not plotNumber or plotNumber == "" then
                statusLabel:setText("Plot number/location cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            statusLabel:setText("Submitting application...")
                :setForeground(colors.yellow)
            
            local basalt = require("basalt")
            basalt.schedule(function()
                -- No authentication required for citizen plot applications
                local success, result = Network.createPlotApplicationPublic(
                    inGameName,
                    plotNumber,
                    buildDescription,
                    estimatedSize,
                    reason
                )
                
                if success then
                    statusLabel:setText("Application submitted successfully!")
                        :setForeground(colors.green)
                    sleep(2)
                    if screen and screen.destroy then
                        screen:destroy()
                    end
                    if onBack then
                        onBack()
                    end
                else
                    local errorMsg = tostring(result or "Unknown error")
                    statusLabel:setText("Error: " .. errorMsg)
                        :setForeground(colors.red)
                end
            end)
        end)
    
    -- Back button
    local backBtn = content:addButton()
        :setText("Back")
        :setPosition(layout.margin + layout.buttonWidth + 2, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :onClick(function()
            if screen and screen.destroy then
                screen:destroy()
            end
            if onBack then
                onBack()
            end
        end)
    
    return screen
end

return PlotApplication

