-- Edit/Create Info Tab Screen
local EditInfoTab = {}
local Network = require("network")
local Utils = require("utils")

function EditInfoTab.create(mainFrame, account, tab, onBack)
    local layout = Utils.getResponsiveLayout()
    local isEdit = tab ~= nil
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Simple header
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
        :setText(isEdit and "Edit Info Tab" or "Create Info Tab")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- Title input
    content:addLabel()
        :setText("Title:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local titleInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    if tab and tab.title then
        titleInput:setText(tab.title)
    end
    yPos = yPos + 2
    
    -- Content input
    content:addLabel()
        :setText("Content:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local contentInput = content:addTextBox()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 8)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    if tab and tab.content then
        contentInput:setText(tab.content)
    end
    yPos = yPos + 10
    
    -- Status label
    local statusLabel = content:addLabel()
        :setText("")
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setForeground(colors.red)
    yPos = yPos + 2
    
    -- Buttons
    local saveBtn = content:addButton()
        :setText(isEdit and "Update Tab" or "Create Tab")
        :setPosition(layout.margin, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.green)
        :setForeground(colors.white)
    
    local backBtn = content:addButton()
        :setText("Cancel")
        :setPosition(layout.margin + layout.buttonWidth + 2, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :onClick(function()
            if onBack then
                onBack()
            end
            return true
        end)
    
    -- Save button handler
    saveBtn:onClick(function()
        local title = titleInput:getText() or ""
        local contentText = contentInput:getText() or ""
        
        if title == "" then
            statusLabel:setText("Title cannot be empty")
                :setForeground(colors.red)
            return true
        end
        
        statusLabel:setText(isEdit and "Updating tab..." or "Creating tab...")
            :setForeground(colors.yellow)
        
        local basalt = require("basalt")
        basalt.schedule(function()
            local success, result
            if isEdit then
                success, result = Network.updateInfoTab(account.id, tab.id, title, contentText)
            else
                success, result = Network.createInfoTab(account.id, title, contentText)
            end
            
            if success then
                statusLabel:setText(isEdit and "Tab updated successfully!" or "Tab created successfully!")
                    :setForeground(colors.green)
                sleep(1)
                if onBack then
                    onBack()
                end
            else
                statusLabel:setText("Error: " .. tostring(result or "Unknown error"))
                    :setForeground(colors.red)
            end
        end)
        return true
    end)
    
    return screen
end

return EditInfoTab

