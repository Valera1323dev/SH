-----------------------------------------------------------------------------------------
-- Button UI Component
-- Creates styled, reusable buttons
-----------------------------------------------------------------------------------------

local widget = require("widget")
local constants = require("gamelogic.constants")

local button = {}

-- Create a button with standard styling
function button.create(options)
    local params = options or {}
    
    -- Apply default values for missing options
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local width = params.width or 200
    local height = params.height or 60
    local cornerRadius = params.cornerRadius or 8
    local label = params.label or "Button"
    local fontSize = params.fontSize or 24
    local labelColor = params.labelColor or constants.UI.COLORS.WHITE
    local fillColor = params.fillColor or constants.UI.COLORS.BLUE
    local pressedFillColor = params.pressedFillColor or {0.14, 0.28, 0.56}
    local strokeColor = params.strokeColor or {1, 1, 1, 0.3}
    local strokeWidth = params.strokeWidth or 2
    local onPress = params.onPress
    local onRelease = params.onRelease
    
    -- Create button with widget factory
    local btn = widget.newButton({
        x = x,
        y = y,
        width = width,
        height = height,
        shape = "roundedRect",
        cornerRadius = cornerRadius,
        fillColor = {
            default = fillColor,
            over = pressedFillColor
        },
        strokeColor = {
            default = strokeColor,
            over = strokeColor
        },
        strokeWidth = strokeWidth,
        label = label,
        labelColor = {
            default = labelColor,
            over = labelColor
        },
        font = constants.UI.FONTS.BOLD,
        fontSize = fontSize,
        onPress = onPress,
        onRelease = onRelease
    })
    
    -- Add reference to the label for easier text updates
    btn.label = {
        text = label
    }
    
    -- Create a method to update both the widget label and our reference
    function btn:updateLabel(newLabel)
        -- Update Corona SDK's button label
        self._widget.text = newLabel
        -- Update our reference
        self.label.text = newLabel
    end
    
    -- Add to parent group if specified
    if parent then
        parent:insert(btn)
    end
    
    return btn
end

-- Create an icon button (just an icon, no text)
function button.createIcon(options)
    local params = options or {}
    
    -- Apply default values for missing options
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local size = params.size or 50
    local defaultFile = params.defaultFile
    local overFile = params.overFile or defaultFile
    local onPress = params.onPress
    local onRelease = params.onRelease
    
    -- Create icon button
    local btnIcon = widget.newButton({
        x = x,
        y = y,
        width = size,
        height = size,
        defaultFile = defaultFile,
        overFile = overFile,
        onPress = onPress,
        onRelease = onRelease
    })
    
    -- Add to parent group if specified
    if parent then
        parent:insert(btnIcon)
    end
    
    return btnIcon
end

-- Create a text button (just text, no background)
function button.createText(options)
    local params = options or {}
    
    -- Apply default values for missing options
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local text = params.text or "Button"
    local fontSize = params.fontSize or 20
    local color = params.color or constants.UI.COLORS.BLUE
    local pressedColor = params.pressedColor or {0.14, 0.28, 0.56}
    local align = params.align or "center"
    local onPress = params.onPress
    local onRelease = params.onRelease
    
    -- Create text button
    local btnText = display.newText({
        text = text,
        x = x,
        y = y,
        font = constants.UI.FONTS.REGULAR,
        fontSize = fontSize,
        align = align
    })
    btnText:setFillColor(unpack(color))
    
    -- Add touch event listener
    function btnText:touch(event)
        if event.phase == "began" then
            btnText:setFillColor(unpack(pressedColor))
            if onPress then onPress() end
            return true
        elseif event.phase == "ended" or event.phase == "cancelled" then
            btnText:setFillColor(unpack(color))
            if onRelease then onRelease() end
            return true
        end
        return false
    end
    
    btnText:addEventListener("touch")
    
    -- Add to parent group if specified
    if parent then
        parent:insert(btnText)
    end
    
    return btnText
end

-- Create a toggle button (on/off states)
function button.createToggle(options)
    local params = options or {}
    
    -- Apply default values for missing options
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local width = params.width or 80
    local height = params.height or 40
    local initialState = params.initialState or false
    local onColor = params.onColor or constants.UI.COLORS.GREEN
    local offColor = params.offColor or constants.UI.COLORS.GRAY
    local labelOn = params.labelOn or "ON"
    local labelOff = params.labelOff or "OFF"
    local onToggle = params.onToggle
    
    -- Create toggle button group
    local toggleGroup = display.newGroup()
    
    -- Track current state
    toggleGroup.state = initialState
    
    -- Create background
    local bg = display.newRoundedRect(toggleGroup, 0, 0, width, height, height / 2)
    bg:setFillColor(unpack(initialState and onColor or offColor))
    
    -- Create toggle circle
    local circleSize = height - 10
    local circle = display.newCircle(toggleGroup, initialState and (width/2 - 5) or (-width/2 + 5), 0, circleSize / 2)
    circle:setFillColor(1)
    
    -- Create label
    local label = display.newText({
        parent = toggleGroup,
        text = initialState and labelOn or labelOff,
        x = 0,
        y = 0,
        font = constants.UI.FONTS.REGULAR,
        fontSize = height * 0.4
    })
    label:setFillColor(1)
    
    -- Set position
    toggleGroup.x = x
    toggleGroup.y = y
    
    -- Add touch event
    function toggleGroup:touch(event)
        if event.phase == "ended" then
            -- Toggle state
            self.state = not self.state
            
            -- Update visuals
            bg:setFillColor(unpack(self.state and onColor or offColor))
            label.text = self.state and labelOn or labelOff
            
            -- Animate toggle circle
            local targetX = self.state and (width/2 - 5) or (-width/2 + 5)
            transition.to(circle, {
                time = 150,
                x = targetX,
                transition = easing.outQuad
            })
            
            -- Call callback if provided
            if onToggle then
                onToggle(self.state)
            end
        end
        return true
    end
    
    toggleGroup:addEventListener("touch")
    
    -- Add to parent group if specified
    if parent then
        parent:insert(toggleGroup)
    end
    
    return toggleGroup
end

return button
