-----------------------------------------------------------------------------------------
-- Terminal Scene
-- Allows player to watch ads for rewards, refill fuel, etc.
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()

local widget = require("widget")

-- Import modules
local constants = require("gamelogic.constants")
local saveManager = require("utils.save_manager")
local localization = require("utils.localization")

-- Import UI components
local button = require("ui.button")
local panel = require("ui.panel")
local progressBar = require("ui.progress_bar")
local tooltip = require("ui.tooltip")

-- Local variables
local background
local mainPanel
local rewardOptions = {}

function scene:create(event)
    local sceneGroup = self.view
    
    -- Create background
    background = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    background:setFillColor(0.05, 0.05, 0.1) -- Dark background
    
    -- Add some stars in the background
    for i = 1, 50 do
        local star = display.newCircle(sceneGroup, math.random(display.contentWidth), math.random(display.contentHeight), math.random(1, 3))
        star:setFillColor(1, 1, 1, math.random(0.3, 0.9))
        
        -- Make stars twinkle
        local function twinkle()
            transition.to(star, {
                alpha = math.random(0.3, 0.9),
                time = math.random(1000, 3000),
                onComplete = twinkle
            })
        end
        twinkle()
    end
    
    -- Create title
    local title = display.newText({
        parent = sceneGroup,
        text = localization.getText("terminal"),
        x = display.contentCenterX,
        y = 70,
        font = native.systemFontBold,
        fontSize = 44
    })
    title:setFillColor(0.3, 0.9, 0.3) -- Green title
    
    -- Create main panel
    mainPanel = panel.create({
        parent = sceneGroup,
        x = display.contentCenterX,
        y = display.contentCenterY,
        width = display.contentWidth - 40,
        height = display.contentHeight - 160,
        cornerRadius = 12
    })
    
    -- Create terminal title
    local terminalTitle = display.newText({
        parent = mainPanel,
        text = localization.getText("reward_terminal"),
        x = 0,
        y = -mainPanel.height/2 + 40,
        font = native.systemFontBold,
        fontSize = 32
    })
    terminalTitle:setFillColor(0.3, 0.9, 0.3)
    
    -- Create terminal description
    local terminalDesc = display.newText({
        parent = mainPanel,
        text = localization.getText("terminal_description"),
        x = 0,
        y = -mainPanel.height/2 + 90,
        font = native.systemFont,
        fontSize = 20,
        align = "center",
        width = mainPanel.width - 60
    })
    terminalDesc:setFillColor(0.9, 0.9, 0.9)
    
    -- Create reward options
    
    -- Fuel refill option
    local fuelPanel = panel.create({
        parent = mainPanel,
        x = -mainPanel.width/4,
        y = -mainPanel.height/6,
        width = mainPanel.width/2 - 30,
        height = 200,
        cornerRadius = 10,
        fillColor = {0.1, 0.15, 0.2, 0.9}
    })
    
    local fuelTitle = display.newText({
        parent = fuelPanel,
        text = localization.getText("refill_fuel"),
        x = 0,
        y = -70,
        font = native.systemFontBold,
        fontSize = 24
    })
    fuelTitle:setFillColor(0.9, 0.7, 0)
    
    local fuelIcon = display.newImageRect(fuelPanel, "assets/fuel_icon.png", 64, 64)
    if not fuelIcon then
        -- Create placeholder if image is missing
        fuelIcon = display.newRect(fuelPanel, 0, -20, 64, 64)
        fuelIcon:setFillColor(0.9, 0.7, 0)
    else
        fuelIcon.x, fuelIcon.y = 0, -20
    end
    
    local fuelDesc = display.newText({
        parent = fuelPanel,
        text = localization.getText("fuel_reward_desc"),
        x = 0,
        y = 30,
        font = native.systemFont,
        fontSize = 18,
        align = "center",
        width = fuelPanel.width - 30
    })
    
    local fuelButton = button.create({
        parent = fuelPanel,
        x = 0,
        y = 70,
        width = fuelPanel.width - 40,
        height = 50,
        label = localization.getText("watch_ad_for_fuel"),
        fontSize = 18,
        onRelease = function()
            self:watchAdForReward("fuel")
        end
    })
    
    rewardOptions.fuel = {
        panel = fuelPanel,
        button = fuelButton
    }
    
    -- Tech fragments option
    local techPanel = panel.create({
        parent = mainPanel,
        x = mainPanel.width/4,
        y = -mainPanel.height/6,
        width = mainPanel.width/2 - 30,
        height = 200,
        cornerRadius = 10,
        fillColor = {0.1, 0.15, 0.2, 0.9}
    })
    
    local techTitle = display.newText({
        parent = techPanel,
        text = localization.getText("tech_fragments"),
        x = 0,
        y = -70,
        font = native.systemFontBold,
        fontSize = 24
    })
    techTitle:setFillColor(0.3, 0.7, 0.9)
    
    local techIcon = display.newImageRect(techPanel, "assets/tech_icon.png", 64, 64)
    if not techIcon then
        -- Create placeholder if image is missing
        techIcon = display.newRect(techPanel, 0, -20, 64, 64)
        techIcon:setFillColor(0.3, 0.7, 0.9)
    else
        techIcon.x, techIcon.y = 0, -20
    end
    
    local techDesc = display.newText({
        parent = techPanel,
        text = localization.getText("tech_reward_desc"),
        x = 0,
        y = 30,
        font = native.systemFont,
        fontSize = 18,
        align = "center",
        width = techPanel.width - 30
    })
    
    local techButton = button.create({
        parent = techPanel,
        x = 0,
        y = 70,
        width = techPanel.width - 40,
        height = 50,
        label = localization.getText("watch_ad_for_tech"),
        fontSize = 18,
        onRelease = function()
            self:watchAdForReward("tech")
        end
    })
    
    rewardOptions.tech = {
        panel = techPanel,
        button = techButton
    }
    
    -- Special item option
    local itemPanel = panel.create({
        parent = mainPanel,
        x = -mainPanel.width/4,
        y = mainPanel.height/4,
        width = mainPanel.width/2 - 30,
        height = 200,
        cornerRadius = 10,
        fillColor = {0.1, 0.15, 0.2, 0.9}
    })
    
    local itemTitle = display.newText({
        parent = itemPanel,
        text = localization.getText("special_item"),
        x = 0,
        y = -70,
        font = native.systemFontBold,
        fontSize = 24
    })
    itemTitle:setFillColor(0.8, 0.3, 0.8)
    
    local itemIcon = display.newImageRect(itemPanel, "assets/item_icon.png", 64, 64)
    if not itemIcon then
        -- Create placeholder if image is missing
        itemIcon = display.newRect(itemPanel, 0, -20, 64, 64)
        itemIcon:setFillColor(0.8, 0.3, 0.8)
    else
        itemIcon.x, itemIcon.y = 0, -20
    end
    
    local itemDesc = display.newText({
        parent = itemPanel,
        text = localization.getText("item_reward_desc"),
        x = 0,
        y = 30,
        font = native.systemFont,
        fontSize = 18,
        align = "center",
        width = itemPanel.width - 30
    })
    
    local itemButton = button.create({
        parent = itemPanel,
        x = 0,
        y = 70,
        width = itemPanel.width - 40,
        height = 50,
        label = localization.getText("watch_ad_for_item"),
        fontSize = 18,
        onRelease = function()
            self:watchAdForReward("item")
        end
    })
    
    rewardOptions.item = {
        panel = itemPanel,
        button = itemButton
    }
    
    -- XP boost option
    local xpPanel = panel.create({
        parent = mainPanel,
        x = mainPanel.width/4,
        y = mainPanel.height/4,
        width = mainPanel.width/2 - 30,
        height = 200,
        cornerRadius = 10,
        fillColor = {0.1, 0.15, 0.2, 0.9}
    })
    
    local xpTitle = display.newText({
        parent = xpPanel,
        text = localization.getText("xp_boost"),
        x = 0,
        y = -70,
        font = native.systemFontBold,
        fontSize = 24
    })
    xpTitle:setFillColor(0.9, 0.5, 0.2)
    
    local xpIcon = display.newImageRect(xpPanel, "assets/xp_icon.png", 64, 64)
    if not xpIcon then
        -- Create placeholder if image is missing
        xpIcon = display.newRect(xpPanel, 0, -20, 64, 64)
        xpIcon:setFillColor(0.9, 0.5, 0.2)
    else
        xpIcon.x, xpIcon.y = 0, -20
    end
    
    local xpDesc = display.newText({
        parent = xpPanel,
        text = localization.getText("xp_boost_desc"),
        x = 0,
        y = 30,
        font = native.systemFont,
        fontSize = 18,
        align = "center",
        width = xpPanel.width - 30
    })
    
    local xpButton = button.create({
        parent = xpPanel,
        x = 0,
        y = 70,
        width = xpPanel.width - 40,
        height = 50,
        label = localization.getText("watch_ad_for_xp"),
        fontSize = 18,
        onRelease = function()
            self:watchAdForReward("xp")
        end
    })
    
    rewardOptions.xp = {
        panel = xpPanel,
        button = xpButton
    }
    
    -- Create back button
    local backButton = button.create({
        parent = sceneGroup,
        x = 100,
        y = display.contentHeight - 80,
        width = 160,
        height = 60,
        label = localization.getText("back"),
        onRelease = function()
            composer.gotoScene("scenes.hub", { effect = "slideRight", time = 500 })
        end
    })
end

function scene:watchAdForReward(rewardType)
    -- In a real implementation, this would show an ad
    -- For now, we'll just directly grant the reward
    
    -- Create a spinner to simulate ad loading
    local spinner = display.newGroup()
    mainPanel:insert(spinner)
    
    local spinnerBg = display.newRect(spinner, 0, 0, 200, 200)
    spinnerBg:setFillColor(0, 0, 0, 0.8)
    spinnerBg.strokeWidth = 2
    spinnerBg:setStrokeColor(1, 1, 1)
    
    local loadingText = display.newText({
        parent = spinner,
        text = localization.getText("loading_ad"),
        x = 0,
        y = -50,
        font = native.systemFontBold,
        fontSize = 20
    })
    
    -- Create spinner animation
    local spinnerCircle = display.newCircle(spinner, 0, 0, 30)
    spinnerCircle:setFillColor(0.3, 0.7, 0.9)
    
    local function rotateSpinner()
        transition.to(spinnerCircle, {
            time = 1000,
            rotation = spinnerCircle.rotation + 360,
            onComplete = rotateSpinner
        })
    end
    rotateSpinner()
    
    -- Simulate ad viewing (3 seconds)
    timer.performWithDelay(3000, function()
        -- Remove spinner
        display.remove(spinner)
        
        -- Grant reward based on type
        if rewardType == "fuel" then
            -- Refill fuel
            local previousFuel = _G.playerData.missions.availableFuel
            _G.playerData.missions.availableFuel = math.min(10, previousFuel + 3)
            
            -- Show success message
            self:showRewardMessage(localization.getText("fuel_rewarded"):gsub("%%d", tostring(_G.playerData.missions.availableFuel - previousFuel)))
            
        elseif rewardType == "tech" then
            -- Award tech fragments
            local amount = math.random(50, 150)
            _G.playerData.techFragments = _G.playerData.techFragments + amount
            
            -- Show success message
            self:showRewardMessage(localization.getText("tech_rewarded"):gsub("%%d", tostring(amount)))
            
        elseif rewardType == "item" then
            -- Award a random consumable item
            local consumables = {
                { id = "repair_kit", name = localization.getText("item_repair_kit"), type = "repair", description = localization.getText("item_repair_desc") },
                { id = "shield_boost", name = localization.getText("item_shield_boost"), type = "shield", description = localization.getText("item_shield_desc") },
                { id = "mega_bomb", name = localization.getText("item_mega_bomb"), type = "bomb", description = localization.getText("item_bomb_desc") }
            }
            
            local randomItem = consumables[math.random(#consumables)]
            
            -- Add to inventory
            table.insert(_G.playerData.inventory.consumables, randomItem)
            
            -- Show success message
            self:showRewardMessage(localization.getText("item_rewarded"):gsub("%%s", randomItem.name))
            
        elseif rewardType == "xp" then
            -- Award XP
            local amount = math.random(100, 300)
            local levelsGained = 0
            
            -- Add XP and check for level up
            _G.playerData.xp = _G.playerData.xp + amount
            
            while _G.playerData.xp >= _G.playerData.xpToNextLevel do
                _G.playerData.xp = _G.playerData.xp - _G.playerData.xpToNextLevel
                _G.playerData.level = _G.playerData.level + 1
                _G.playerData.skillPoints = _G.playerData.skillPoints + 1
                _G.playerData.xpToNextLevel = math.floor(_G.playerData.xpToNextLevel * 1.2)
                levelsGained = levelsGained + 1
            end
            
            -- Show success message
            local message = localization.getText("xp_rewarded"):gsub("%%d", tostring(amount))
            if levelsGained > 0 then
                message = message .. "\n" .. localization.getText("level_up"):gsub("%%d", tostring(levelsGained))
            end
            self:showRewardMessage(message)
        end
        
        -- Save the updated player data
        saveManager.saveGame(_G.playerData)
    end)
end

function scene:showRewardMessage(message)
    -- Create reward notification
    local notification = display.newGroup()
    mainPanel:insert(notification)
    
    local notificationBg = display.newRoundedRect(notification, 0, 0, mainPanel.width * 0.7, 150, 12)
    notificationBg:setFillColor(0.1, 0.3, 0.1, 0.9)
    notificationBg.strokeWidth = 3
    notificationBg:setStrokeColor(0.3, 0.9, 0.3)
    
    local successIcon = display.newText({
        parent = notification,
        text = "✓", -- Checkmark
        x = -notificationBg.width/4,
        y = 0,
        font = native.systemFontBold,
        fontSize = 60
    })
    successIcon:setFillColor(0.3, 0.9, 0.3)
    
    local messageText = display.newText({
        parent = notification,
        text = message,
        x = notificationBg.width/8,
        y = 0,
        font = native.systemFont,
        fontSize = 22,
        align = "left",
        width = notificationBg.width * 0.6
    })
    
    -- Add close button
    local closeButton = button.create({
        parent = notification,
        x = 0,
        y = notificationBg.height/2 + 40,
        width = 160,
        height = 50,
        label = localization.getText("close"),
        fontSize = 20,
        onRelease = function()
            transition.to(notification, {
                time = 300,
                alpha = 0,
                onComplete = function()
                    display.remove(notification)
                end
            })
        end
    })
    
    -- Animation
    notification.alpha = 0
    notification.xScale = 0.5
    notification.yScale = 0.5
    
    transition.to(notification, {
        time = 300,
        alpha = 1,
        xScale = 1,
        yScale = 1,
        transition = easing.outBack
    })
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase
    
    if phase == "will" then
        -- Called when the scene is still off screen and is about to move on screen
    elseif phase == "did" then
        -- Called when the scene is now on screen
    end
end

function scene:hide(event)
    local sceneGroup = self.view
    local phase = event.phase
    
    if phase == "will" then
        -- Called when the scene is on screen and is about to move off screen
    elseif phase == "did" then
        -- Called when the scene is now off screen
    end
end

function scene:destroy(event)
    local sceneGroup = self.view
    -- Cleanup
end

-- Add scene event listeners
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene