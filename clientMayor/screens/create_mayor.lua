-- Create Mayor Account Screen
local CreateMayor = {}
local Header = require("components.header")
local Network = require("network")
local Utils = require("utils")

function CreateMayor.create(mainFrame, account, onBack)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Create header
    local header = Header.create(screen, function()
        if onBack then
            onBack()
        end
    end)
    
    -- Content area (positioned below header which is 3 lines tall)
    local content = screen:addScrollFrame()
        :setSize("{parent.width}", "{parent.height - 3}")
        :setPosition(1, 4)
        :setBackground(colors.black)
        :setScrollBarBackgroundColor(colors.gray)
        :setScrollBarColor(colors.lightGray)
    
    local yPos = 2
    
    -- Title
    content:addLabel()
        :setText("Create Mayor Account")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- Username input
    content:addLabel()
        :setText("Username:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local usernameInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 2
    
    -- Password input
    content:addLabel()
        :setText("Password:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local passwordInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setReplaceChar("*")
    yPos = yPos + 2
    
    -- Confirm Password input
    content:addLabel()
        :setText("Confirm Password:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local confirmPasswordInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setReplaceChar("*")
    yPos = yPos + 3
    
    -- Status label
    local statusLabel = content:addLabel()
        :setText("")
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 2)
        :setForeground(colors.red)
    yPos = yPos + 3
    
    -- Create button
    local createBtn = content:addButton()
        :setText("Create Mayor Account")
        :setPosition(layout.margin, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.green)
        :setForeground(colors.white)
        :onClick(function()
            local username = usernameInput:getText() or ""
            local password = passwordInput:getText() or ""
            local confirmPassword = confirmPasswordInput:getText() or ""
            
            if not username or username == "" then
                statusLabel:setText("Username cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            if not password or password == "" then
                statusLabel:setText("Password cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            if password ~= confirmPassword then
                statusLabel:setText("Passwords do not match")
                    :setForeground(colors.red)
                return
            end
            
            statusLabel:setText("Creating account...")
                :setForeground(colors.yellow)
            
            local basalt = require("basalt")
            basalt.schedule(function()
                local success, result = Network.createAccount(username, password, "admin")
                
                if success then
                    statusLabel:setText("Mayor account created successfully!")
                        :setForeground(colors.green)
                    usernameInput:setText("")
                    passwordInput:setText("")
                    confirmPasswordInput:setText("")
                    sleep(2)
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
            if onBack then
                onBack()
            end
        end)
    
    return screen
end

return CreateMayor

