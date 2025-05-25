-----------------------------------------------------------------------------------------
-- Tooltip UI Component
-- Creates informational tooltips and hover boxes
-----------------------------------------------------------------------------------------

local constants = require("gamelogic.constants")

local tooltip = {}

-- Create a simple tooltip
function tooltip.create(options)
    local params = options or {}
    
    -- Apply default values for missing options
    local parent = params.parent
    local text = params.text or "Tooltip text"
    local width = params.width or 200
    local fontSize = params.fontSize or 16
    local padding = params.padding or 10
    local cornerRadius = params.cornerRadius or 8
    local fillColor = params.fillColor or {0.1, 0.1, 0.15, 0.9}
    local textColor = params.textColor or constants.UI.COLORS.WHITE
    local borderColor = params.borderColor or {1, 1, 1, 0.3}
    local borderWidth = params.borderWidth or 1
    local direction = params.direction or "up" -- up, down, left, right
    local arrow = params.arrow ~= false -- show arrow by default
    local arrowSize = params.arrowSize or 10
    
    -- Create the tooltip group
    local tooltipGroup = display.newGroup()
    
    -- Create the text object to determine height
    local textObj = display.newText({
        text = text,
        width = width - (padding * 2),
        fontSize = fontSize,
        font = constants.UI.FONTS.REGULAR,
        align = "center"
    })
    
    -- Calculate tooltip dimensions
    local textHeight = textObj.height
    local boxHeight = textHeight + (padding * 2)
    local boxWidth = width
    
    -- Create the background
    local background = display.newRoundedRect(tooltipGroup, 0, 0, boxWidth, boxHeight, cornerRadius)
    background:setFillColor(unpack(fillColor))
    
    if borderWidth > 0 then
        background:setStrokeColor(unpack(borderColor))
        background.strokeWidth = borderWidth
    end
    
    -- Add the arrow if requested
    if arrow then
        local arrowShape
        
        -- Create arrow shape based on direction
        if direction == "up" then
            arrowShape = {0, -arrowSize, arrowSize, 0, -arrowSize, 0}
            background.y = background.y + arrowSize/2
        elseif direction == "down" then
            arrowShape = {0, arrowSize, arrowSize, 0, -arrowSize, 0}
            background.y = background.y - arrowSize/2
        elseif direction == "left" then
            arrowShape = {-arrowSize, 0, 0, arrowSize, 0, -arrowSize}
            background.x = background.x + arrowSize/2
        elseif direction == "right" then
            arrowShape = {arrowSize, 0, 0, arrowSize, 0, -arrowSize}
            background.x = background.x - arrowSize/2
        end
        
        local arrowPolygon = display.newPolygon(tooltipGroup, 0, 0, arrowShape)
        arrowPolygon:setFillColor(unpack(fillColor))
        
        -- Position arrow based on direction
        if direction == "up" then
            arrowPolygon.y = -boxHeight/2 - arrowSize/2
        elseif direction == "down" then
            arrowPolygon.y = boxHeight/2 + arrowSize/2
        elseif direction == "left" then
            arrowPolygon.x = -boxWidth/2 - arrowSize/2
        elseif direction == "right" then
            arrowPolygon.x = boxWidth/2 + arrowSize/2
        end
        
        tooltipGroup.arrow = arrowPolygon
    end
    
    -- Add the text to the tooltip
    textObj.parent = nil
    tooltipGroup:insert(textObj)
    textObj:setFillColor(unpack(textColor))
    tooltipGroup.textObj = textObj
    
    -- Store the dimensions
    tooltipGroup.width = boxWidth
    tooltipGroup.height = boxHeight
    tooltipGroup.background = background
    
    -- Store the direction
    tooltipGroup.direction = direction
    tooltipGroup.arrowSize = arrowSize
    
    -- Add to parent group if specified
    if parent then
        parent:insert(tooltipGroup)
    end
    
    return tooltipGroup
end

-- Attach a tooltip to a display object
function tooltip.attach(targetObject, options)
    local params = options or {}
    
    -- Apply default values for missing options
    local text = params.text or "Tooltip text"
    local width = params.width or 200
    local showDelay = params.showDelay or 500
    local hideDelay = params.hideDelay or 100
    local offsetX = params.offsetX or 0
    local offsetY = params.offsetY or 0
    local autoPosition = params.autoPosition ~= false -- auto position by default
    
    -- Store initial tooltip state
    targetObject.tooltipVisible = false
    targetObject.tooltipOptions = params
    
    -- Create the tooltip function that will be called on first hover
    targetObject.createTooltip = function(self)
        -- Create the tooltip
        local tooltipOptions = {
            text = text,
            width = width,
            fontSize = params.fontSize,
            padding = params.padding,
            cornerRadius = params.cornerRadius,
            fillColor = params.fillColor,
            textColor = params.textColor,
            borderColor = params.borderColor,
            borderWidth = params.borderWidth,
            direction = params.direction or "up",
            arrow = params.arrow,
            arrowSize = params.arrowSize
        }
        
        local tooltipObj = tooltip.create(tooltipOptions)
        tooltipObj.alpha = 0
        
        -- Add the tooltip to the stage (to avoid clipping)
        local stage = targetObject.parent
        while stage.parent do
            stage = stage.parent
        end
        stage:insert(tooltipObj)
        
        -- Position the tooltip relative to target object
        if autoPosition then
            -- Convert target object position to global coordinates
            local globalX, globalY = targetObject:localToContent(0, 0)
            
            -- Position based on direction
            local direction = tooltipOptions.direction or "up"
            local arrowSizeOffset = (tooltipOptions.arrow ~= false) and (tooltipOptions.arrowSize or 10) or 0
            
            if direction == "up" then
                tooltipObj.x = globalX + offsetX
                tooltipObj.y = globalY - targetObject.height/2 - tooltipObj.height/2 - arrowSizeOffset + offsetY
            elseif direction == "down" then
                tooltipObj.x = globalX + offsetX
                tooltipObj.y = globalY + targetObject.height/2 + tooltipObj.height/2 + arrowSizeOffset + offsetY
            elseif direction == "left" then
                tooltipObj.x = globalX - targetObject.width/2 - tooltipObj.width/2 - arrowSizeOffset + offsetX
                tooltipObj.y = globalY + offsetY
            elseif direction == "right" then
                tooltipObj.x = globalX + targetObject.width/2 + tooltipObj.width/2 + arrowSizeOffset + offsetX
                tooltipObj.y = globalY + offsetY
            end
            
            -- Check if tooltip goes off screen and adjust
            local bounds = tooltipObj.contentBounds
            local screenBounds = {
                xMin = 0,
                yMin = 0,
                xMax = display.contentWidth,
                yMax = display.contentHeight
            }
            
            if bounds.xMin < screenBounds.xMin then
                tooltipObj.x = tooltipObj.x + (screenBounds.xMin - bounds.xMin)
            elseif bounds.xMax > screenBounds.xMax then
                tooltipObj.x = tooltipObj.x - (bounds.xMax - screenBounds.xMax)
            end
            
            if bounds.yMin < screenBounds.yMin then
                tooltipObj.y = tooltipObj.y + (screenBounds.yMin - bounds.yMin)
            elseif bounds.yMax > screenBounds.yMax then
                tooltipObj.y = tooltipObj.y - (bounds.yMax - screenBounds.yMax)
            end
        else
            -- Use manual positioning if auto-positioning is disabled
            tooltipObj.x = params.x or display.contentCenterX
            tooltipObj.y = params.y or display.contentCenterY
        end
        
        -- Store the tooltip
        self.tooltip = tooltipObj
    end
    
    -- Add show tooltip function
    targetObject.showTooltip = function(self)
        if not self.tooltip then
            self:createTooltip()
        end
        
        -- Cancel any pending hide timer
        if self.hideTimer then
            timer.cancel(self.hideTimer)
            self.hideTimer = nil
        end
        
        -- Show with delay
        self.showTimer = timer.performWithDelay(showDelay, function()
            if self.tooltip then
                transition.to(self.tooltip, {
                    alpha = 1,
                    time = 200
                })
                self.tooltipVisible = true
            end
        end)
    end
    
    -- Add hide tooltip function
    targetObject.hideTooltip = function(self)
        -- Cancel any pending show timer
        if self.showTimer then
            timer.cancel(self.showTimer)
            self.showTimer = nil
        end
        
        -- Hide with delay
        self.hideTimer = timer.performWithDelay(hideDelay, function()
            if self.tooltip then
                transition.to(self.tooltip, {
                    alpha = 0,
                    time = 200,
                    onComplete = function()
                        if self.tooltip then
                            display.remove(self.tooltip)
                            self.tooltip = nil
                        end
                    end
                })
                self.tooltipVisible = false
            end
        end)
    end
    
    -- Update tooltip text
    targetObject.updateTooltipText = function(self, newText)
        text = newText
        
        if self.tooltip then
            self.tooltip.textObj.text = newText
            
            -- Adjust tooltip size if needed
            -- This would require recreating the tooltip
            display.remove(self.tooltip)
            self.tooltip = nil
            
            if self.tooltipVisible then
                self:createTooltip()
                self.tooltip.alpha = 1
            end
        end
    end
    
    -- Add touch/hover detection
    targetObject.tooltipTouch = function(self, event)
        if event.phase == "began" then
            self:showTooltip()
        elseif event.phase == "ended" or event.phase == "cancelled" then
            self:hideTooltip()
        end
        
        -- Don't consume the touch event so object's original touch function still works
        return false
    end
    
    targetObject:addEventListener("touch", targetObject.tooltipTouch)
    
    return targetObject
end

-- Create an info button with tooltip
function tooltip.createInfoButton(options)
    local params = options or {}
    
    -- Apply default values for missing options
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local size = params.size or 24
    local text = params.text or "Information tooltip"
    local fillColor = params.fillColor or constants.UI.COLORS.BLUE
    local textColor = params.textColor or constants.UI.COLORS.WHITE
    
    -- Create button group
    local infoButton = display.newGroup()
    
    -- Create circle background
    local circle = display.newCircle(infoButton, 0, 0, size/2)
    circle:setFillColor(unpack(fillColor))
    
    -- Create "i" text
    local iText = display.newText({
        parent = infoButton,
        text = "i",
        x = 0,
        y = 0,
        font = constants.UI.FONTS.BOLD,
        fontSize = size * 0.7
    })
    iText:setFillColor(unpack(textColor))
    
    -- Position the button
    infoButton.x = x
    infoButton.y = y
    
    -- Add tooltip
    tooltip.attach(infoButton, {
        text = text,
        width = params.tooltipWidth or 200,
        direction = params.direction or "up"
    })
    
    -- Add to parent group if specified
    if parent then
        parent:insert(infoButton)
    end
    
    return infoButton
end

return tooltip
