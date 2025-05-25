-----------------------------------------------------------------------------------------
-- Progress Bar UI Component
-- Creates styled progress and status bars
-----------------------------------------------------------------------------------------

local constants = require("gamelogic.constants")

local progressBar = {}

-- Create a basic progress bar
function progressBar.create(options)
    local params = options or {}
    
    -- Apply default values for missing options
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local width = params.width or 200
    local height = params.height or 20
    local cornerRadius = params.cornerRadius or (height / 4)
    local progress = params.progress or 0 -- 0 to 1
    local fillColor = params.fillColor or constants.UI.COLORS.BLUE
    local backgroundColor = params.backgroundColor or constants.UI.COLORS.DARK_GRAY
    local strokeColor = params.strokeColor or {1, 1, 1, 0.3}
    local strokeWidth = params.strokeWidth or 1
    local isAnimated = params.isAnimated or false
    local animationDuration = params.animationDuration or 300
    local showText = params.showText or false
    local textColor = params.textColor or constants.UI.COLORS.WHITE
    local textFont = params.textFont or constants.UI.FONTS.REGULAR
    local textSize = params.textSize or math.floor(height * 0.8)
    local textFormatter = params.textFormatter
    
    -- Create the progress bar group
    local barGroup = display.newGroup()
    
    -- Create the background
    local background = display.newRoundedRect(barGroup, 0, 0, width, height, cornerRadius)
    background:setFillColor(unpack(backgroundColor))
    
    if strokeWidth > 0 then
        background:setStrokeColor(unpack(strokeColor))
        background.strokeWidth = strokeWidth
    end
    
    -- Create the fill rectangle
    local fillWidth = width * progress
    local fill = display.newRoundedRect(barGroup, -width/2 + fillWidth/2, 0, fillWidth, height, cornerRadius)
    fill:setFillColor(unpack(fillColor))
    fill.anchorX = 0
    fill.x = -width/2
    
    -- Create label if required
    local label
    if showText then
        local displayText = ""
        if textFormatter then
            displayText = textFormatter(progress)
        else
            displayText = math.floor(progress * 100) .. "%"
        end
        
        label = display.newText({
            parent = barGroup,
            text = displayText,
            x = 0,
            y = 0,
            font = textFont,
            fontSize = textSize
        })
        label:setFillColor(unpack(textColor))
    end
    
    -- Position the group
    barGroup.x = x
    barGroup.y = y
    
    -- Store properties
    barGroup.progress = progress
    barGroup.width = width
    barGroup.height = height
    barGroup.fill = fill
    barGroup.background = background
    barGroup.label = label
    barGroup.isAnimated = isAnimated
    barGroup.animationDuration = animationDuration
    barGroup.textFormatter = textFormatter
    
    -- Set progress method
    function barGroup:setProgress(newProgress, animate)
        -- Ensure progress is between 0 and 1
        newProgress = math.max(0, math.min(1, newProgress))
        self.progress = newProgress
        
        -- Calculate new fill width
        local newWidth = self.width * newProgress
        
        -- Animate or set immediately
        if (animate or self.isAnimated) and self.progress ~= newProgress then
            transition.to(self.fill, {
                width = newWidth,
                time = self.animationDuration,
                transition = easing.outQuad
            })
        else
            self.fill.width = newWidth
        end
        
        -- Update label if exists
        if self.label then
            local displayText = ""
            if self.textFormatter then
                displayText = self.textFormatter(newProgress)
            else
                displayText = math.floor(newProgress * 100) .. "%"
            end
            self.label.text = displayText
        end
    end
    
    -- Add to parent group if specified
    if parent then
        parent:insert(barGroup)
    end
    
    return barGroup
end

-- Create a segmented progress bar (health bar style)
function progressBar.createSegmented(options)
    local params = options or {}
    
    -- Apply default values for missing options
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local width = params.width or 200
    local height = params.height or 20
    local segments = params.segments or 5
    local cornerRadius = params.cornerRadius or (height / 4)
    local progress = params.progress or 1 -- 0 to 1
    local segmentSpacing = params.segmentSpacing or 2
    local fillColor = params.fillColor or constants.UI.COLORS.GREEN
    local backgroundColor = params.backgroundColor or constants.UI.COLORS.DARK_GRAY
    local strokeColor = params.strokeColor or {1, 1, 1, 0.3}
    local strokeWidth = params.strokeWidth or 1
    local lowHealthColor = params.lowHealthColor or constants.UI.COLORS.RED
    local mediumHealthColor = params.mediumHealthColor or constants.UI.COLORS.YELLOW
    local healthThresholds = params.healthThresholds or {low = 0.3, medium = 0.6}
    
    -- Create the progress bar group
    local barGroup = display.newGroup()
    
    -- Calculate segment width
    local segmentWidth = (width - (segmentSpacing * (segments - 1))) / segments
    
    -- Create all segments
    barGroup.segments = {}
    
    for i = 1, segments do
        local segX = -width/2 + segmentWidth/2 + (i-1) * (segmentWidth + segmentSpacing)
        
        -- Create segment background
        local segBg = display.newRoundedRect(barGroup, segX, 0, segmentWidth, height, cornerRadius)
        segBg:setFillColor(unpack(backgroundColor))
        
        if strokeWidth > 0 then
            segBg:setStrokeColor(unpack(strokeColor))
            segBg.strokeWidth = strokeWidth
        end
        
        -- Create segment fill (initially all filled)
        local segFill = display.newRoundedRect(barGroup, segX, 0, segmentWidth, height, cornerRadius)
        
        -- Set fill color based on health thresholds
        local segProgress = i / segments
        if segProgress <= healthThresholds.low then
            segFill:setFillColor(unpack(lowHealthColor))
        elseif segProgress <= healthThresholds.medium then
            segFill:setFillColor(unpack(mediumHealthColor))
        else
            segFill:setFillColor(unpack(fillColor))
        end
        
        -- Hide fill if beyond progress
        if i > math.ceil(progress * segments) then
            segFill.isVisible = false
        end
        
        -- Store segment
        barGroup.segments[i] = {
            background = segBg,
            fill = segFill
        }
    end
    
    -- Position the group
    barGroup.x = x
    barGroup.y = y
    
    -- Store properties
    barGroup.progress = progress
    barGroup.totalSegments = segments
    
    -- Set progress method
    function barGroup:setProgress(newProgress, animate)
        -- Ensure progress is between 0 and 1
        newProgress = math.max(0, math.min(1, newProgress))
        self.progress = newProgress
        
        -- Calculate visible segments
        local visibleSegments = math.ceil(newProgress * self.totalSegments)
        
        -- Update segment visibility
        for i = 1, self.totalSegments do
            local segFill = self.segments[i].fill
            
            if animate then
                if i <= visibleSegments then
                    if not segFill.isVisible then
                        segFill.alpha = 0
                        segFill.isVisible = true
                        transition.to(segFill, {alpha = 1, time = 200})
                    end
                else
                    if segFill.isVisible then
                        transition.to(segFill, {
                            alpha = 0, 
                            time = 200,
                            onComplete = function() segFill.isVisible = false end
                        })
                    end
                end
            else
                segFill.isVisible = (i <= visibleSegments)
            end
        end
    end
    
    -- Add to parent group if specified
    if parent then
        parent:insert(barGroup)
    end
    
    return barGroup
end

-- Create a circular progress indicator
function progressBar.createCircular(options)
    local params = options or {}
    
    -- Apply default values for missing options
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local radius = params.radius or 40
    local progress = params.progress or 0 -- 0 to 1
    local thickness = params.thickness or 10
    local startAngle = params.startAngle or 0
    local fillColor = params.fillColor or constants.UI.COLORS.BLUE
    local backgroundColor = params.backgroundColor or constants.UI.COLORS.DARK_GRAY
    local showText = params.showText or false
    local textColor = params.textColor or constants.UI.COLORS.WHITE
    local textFont = params.textFont or constants.UI.FONTS.REGULAR
    local textSize = params.textSize or math.floor(radius * 0.7)
    local textFormatter = params.textFormatter
    
    -- Create the progress indicator group
    local indicatorGroup = display.newGroup()
    
    -- Create background circle
    local background = display.newCircle(indicatorGroup, 0, 0, radius)
    background:setFillColor(unpack(backgroundColor))
    
    -- Create the arc segments for progress
    local segmentsGroup = display.newGroup()
    indicatorGroup:insert(segmentsGroup)
    
    -- Function to draw the progress arc
    local function drawArc(progress)
        -- Remove previous segments
        while segmentsGroup.numChildren > 0 do
            segmentsGroup[1]:removeSelf()
        end
        
        if progress <= 0 then return end
        
        -- Calculate number of segments (more segments = smoother circle)
        local numSegments = 36
        local segmentAngle = (math.pi * 2) / numSegments
        
        -- Calculate how many segments to show based on progress
        local activeSegments = math.floor(progress * numSegments)
        
        for i = 0, activeSegments do
            local startAngleRad = startAngle + (i * segmentAngle)
            local endAngleRad = startAngle + ((i + 1) * segmentAngle)
            
            -- Last segment might be partial
            if i == activeSegments then
                local remainingProgress = progress * numSegments - activeSegments
                if remainingProgress > 0 then
                    endAngleRad = startAngle + (i * segmentAngle) + (remainingProgress * segmentAngle)
                else
                    break
                end
            end
            
            -- Create segment
            local segment = display.newLine(
                segmentsGroup,
                math.cos(startAngleRad) * (radius - thickness/2),
                math.sin(startAngleRad) * (radius - thickness/2),
                math.cos(endAngleRad) * (radius - thickness/2),
                math.sin(endAngleRad) * (radius - thickness/2)
            )
            segment.strokeWidth = thickness
            segment:setStrokeColor(unpack(fillColor))
        end
    end
    
    -- Draw initial arc
    drawArc(progress)
    
    -- Create center label if needed
    local label
    if showText then
        local displayText = ""
        if textFormatter then
            displayText = textFormatter(progress)
        else
            displayText = math.floor(progress * 100) .. "%"
        end
        
        label = display.newText({
            parent = indicatorGroup,
            text = displayText,
            x = 0,
            y = 0,
            font = textFont,
            fontSize = textSize
        })
        label:setFillColor(unpack(textColor))
    end
    
    -- Position the group
    indicatorGroup.x = x
    indicatorGroup.y = y
    
    -- Store properties
    indicatorGroup.progress = progress
    indicatorGroup.radius = radius
    indicatorGroup.label = label
    indicatorGroup.textFormatter = textFormatter
    
    -- Set progress method
    function indicatorGroup:setProgress(newProgress)
        -- Ensure progress is between 0 and 1
        newProgress = math.max(0, math.min(1, newProgress))
        self.progress = newProgress
        
        -- Redraw arc
        drawArc(newProgress)
        
        -- Update label if exists
        if self.label then
            local displayText = ""
            if self.textFormatter then
                displayText = self.textFormatter(newProgress)
            else
                displayText = math.floor(newProgress * 100) .. "%"
            end
            self.label.text = displayText
        end
    end
    
    -- Add to parent group if specified
    if parent then
        parent:insert(indicatorGroup)
    end
    
    return indicatorGroup
end

return progressBar
