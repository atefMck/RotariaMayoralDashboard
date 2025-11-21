-- Header Component
local Header = {}
local Utils = require("utils")

function Header.create(parent, onLogout)
    local layout = Utils.getResponsiveLayout()
    
    local header = parent:addFrame()
        :setSize("{parent.width}", 3)
        :setPosition(1, 1)
        :setBackground(colors.gray)
    
    -- Rotaria City title in orange
    local title = header:addLabel()
        :setText("Rotaria City")
        :setPosition(2, 2)
        :setForeground(colors.orange)
        :setBackground(colors.gray)
    
    -- Powered by CogCorp
    local poweredBy = header:addLabel()
        :setText("powered by CogCorp")
        :setPosition(2, 3)
        :setForeground(colors.lightGray)
        :setBackground(colors.gray)
    
    -- Logout button
    local logoutBtn = header:addButton()
        :setText("Logout")
        :setPosition("{parent.width - 9}", 2)
        :setSize(8, 1)
        :setBackground(colors.red)
        :setForeground(colors.white)
        :onClick(function()
            if onLogout then
                onLogout()
            end
            return true
        end)
    
    return header
end

return Header

