-- Login Screen
local Login = {}
local Network = require("network")
local Utils = require("utils")

function Login.create(mainFrame, onSuccess, onBackToLogin)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Calculate positions
    local titleY = math.max(2, math.floor(layout.height / 4))
    local usernameLabelY = titleY + 2
    local usernameInputY = usernameLabelY + 1
    local passwordLabelY = usernameInputY + 2
    local passwordInputY = passwordLabelY + 1
    local statusY = passwordInputY + 2
    local buttonY = math.max(statusY + 2, layout.height - 3)
    
    -- Title
    screen:addLabel()
        :setText("Rotaria City Login")
        :setPosition(layout.margin, titleY)
        :setForeground(colors.orange)
    
    -- Username input
    screen:addLabel()
        :setText("Username:")
        :setPosition(layout.margin, usernameLabelY)
        :setForeground(colors.lightGray)
    local usernameInput = screen:addInput()
        :setPosition(layout.margin, usernameInputY)
        :setSize(layout.inputWidth, layout.inputHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    
    -- Password input
    screen:addLabel()
        :setText("Password:")
        :setPosition(layout.margin, passwordLabelY)
        :setForeground(colors.lightGray)
    local passwordInput = screen:addInput()
        :setPosition(layout.margin, passwordInputY)
        :setSize(layout.inputWidth, layout.inputHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setReplaceChar("*")
    
    -- Status label
    local statusLabel = screen:addLabel()
        :setText("")
        :setPosition(layout.margin, statusY)
        :setSize(layout.inputWidth, 1)
        :setForeground(colors.red)
    
    -- Login button
    local loginBtn = screen:addButton()
        :setText("Login")
        :setPosition(layout.margin, buttonY)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.green)
        :setForeground(colors.white)
        :onClick(function()
            local username = usernameInput:getText() or ""
            local password = passwordInput:getText() or ""
            
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
            
            statusLabel:setText("Logging in...")
                :setForeground(colors.yellow)
            
            local basalt = require("basalt")
            basalt.schedule(function()
                local success, result = Network.login(username, password)
                
                if success then
                    statusLabel:setText("Login successful!")
                        :setForeground(colors.green)
                    sleep(0.5)
                    if onSuccess then
                        onSuccess(result)
                    end
                else
                    local errorMsg = tostring(result or "Unknown error")
                    statusLabel:setText("Error: " .. errorMsg)
                        :setForeground(colors.red)
                end
            end)
        end)
    
    
    return screen
end

return Login

