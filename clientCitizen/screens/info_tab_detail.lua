-- Info Tab Detail Screen
local InfoTabDetail = {}
local Utils = require("utils")

function InfoTabDetail.create(mainFrame, tab, onBack)
    local layout = Utils.getResponsiveLayout()
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
    
    -- Content area (scrollable)
    local content = screen:addScrollFrame()
        :setSize("{parent.width}", "{parent.height - 3}")
        :setPosition(1, 4)
        :setBackground(colors.black)
        :setScrollBarBackgroundColor(colors.gray)
        :setScrollBarColor(colors.lightGray)
    
    local yPos = 2
    
    -- Title
    local titleLabel = content:addLabel()
        :setText(tab.title or "City Information")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- Content text (with wrapping and scrolling)
    local contentLabel = content:addLabel()
        :setText(tab.content or "No information available.")
        :setPosition(layout.margin, yPos)
        :setSize(layout.width - 4, 1)
        :setForeground(colors.white)
        :setAutoSize(false)  -- Wrap text and expand vertically
    
    -- Back button (positioned dynamically after text)
    local backBtn = content:addButton()
        :setText("Back")
        :setPosition(layout.margin, yPos + 10)  -- Initial position, will be updated
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
            return true
        end)
    
    -- Update back button position based on text height
    local basalt = require("basalt")
    basalt.schedule(function()
        local wrappedLines = contentLabel:getWrappedText()
        local textHeight = #wrappedLines
        backBtn:setPosition(layout.margin, yPos + textHeight + 2)
    end)
    
    return screen
end

return InfoTabDetail

