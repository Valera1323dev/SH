-----------------------------------------------------------------------------------------
-- Player Hub Scene - Central navigation point between missions
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()

local widget = require("widget")
local localization = require("utils.localization")
local button = require("ui.button")
local panel = require("ui.panel")
local progression = require("gamelogic.progression")
local constants = require("gamelogic.constants")

-- Local variables
local background
local hubGroup
local playerInfoPanel
local menuButtons = {}

function scene:create(event)
    local sceneGroup = self.view
    
    -- Create background
    background = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    background:setFillColor(0.05, 0.05, 0.1) -- Dark background
    
    -- Create starfield effect
    local starfield = display.newGroup()
    sceneGroup:insert(starfield)
    
    -- Add some stars in the background
    for i = 1, 50 do
        local star = display.newCircle(starfield, math.random(display.contentWidth), math.random(display.contentHeight), math.random(1, 3))
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
    
    -- Create hub group
    hubGroup = display.newGroup()
    sceneGroup:insert(hubGroup)
    
    -- Title
    local title = display.newText({
        parent = hubGroup,
        text = localization.getText("command_center"),
        x = display.contentCenterX,
        y = 70,
        font = native.systemFontBold,
        fontSize = 44
    })
    title:setFillColor(0.2, 0.8, 0.2) -- Green title
    
    -- Player info panel (top of the screen)
    playerInfoPanel = panel.create({
        parent = hubGroup,
        x = display.contentCenterX,
        y = 160,
        width = display.contentWidth - 40,
        height = 160,
        cornerRadius = 10
    })
    
    -- Update the player info display
    self:updatePlayerInfo()
    
    -- Create hub navigation buttons
    local buttonWidth = display.contentWidth * 0.45
    local buttonHeight = 180
    local buttonSpacing = 20
    local startX = display.contentWidth * 0.25
    local startY = 350
    
    -- Shipyard button
    menuButtons.shipyard = button.create({
        parent = hubGroup,
        x = startX,
        y = startY,
        width = buttonWidth,
        height = buttonHeight,
        label = localization.getText("shipyard"),
        fontSize = 32,
        onRelease = function()
            composer.gotoScene("scenes.shipyard", { effect = "slideLeft", time = 300 })
        end
    })
    
    -- Shop button
    menuButtons.shop = button.create({
        parent = hubGroup,
        x = startX + buttonWidth + buttonSpacing,
        y = startY,
        width = buttonWidth,
        height = buttonHeight,
        label = localization.getText("shop"),
        fontSize = 32,
        onRelease = function()
            composer.gotoScene("scenes.shop", { effect = "slideLeft", time = 300 })
        end
    })
    
    -- Missions button
    menuButtons.missions = button.create({
        parent = hubGroup,
        x = startX,
        y = startY + buttonHeight + buttonSpacing,
        width = buttonWidth,
        height = buttonHeight,
        label = localization.getText("missions") .. "\nFuel: " .. _G.playerData.missions.availableFuel .. "/10",
        fontSize = 32,
        onRelease = function()
            composer.gotoScene("scenes.missions", { effect = "slideLeft", time = 300 })
        end
    })
    
    -- Terminal button
    menuButtons.terminal = button.create({
        parent = hubGroup,
        x = startX + buttonWidth + buttonSpacing,
        y = startY + buttonHeight + buttonSpacing,
        width = buttonWidth,
        height = buttonHeight,
        label = localization.getText("terminal"),
        fontSize = 32,
        onRelease = function()
            composer.gotoScene("scenes.terminal", { effect = "slideLeft", time = 300 })
        end
    })
    
    -- Logbook button
    menuButtons.logbook = button.create({
        parent = hubGroup,
        x = startX,
        y = startY + (buttonHeight + buttonSpacing) * 2,
        width = buttonWidth,
        height = buttonHeight,
        label = localization.getText("logbook"),
        fontSize = 32,
        onRelease = function()
            composer.gotoScene("scenes.logbook", { effect = "slideLeft", time = 300 })
        end
    })
    
    -- Settings button
    menuButtons.settings = button.create({
        parent = hubGroup,
        x = startX + buttonWidth + buttonSpacing,
        y = startY + (buttonHeight + buttonSpacing) * 2,
        width = buttonWidth,
        height = buttonHeight,
        label = localization.getText("settings"),
        fontSize = 32,
        onRelease = function()
            composer.gotoScene("scenes.settings", { effect = "slideLeft", time = 300 })
        end
    })
    
    -- Back to main menu button
    local backButton = button.create({
        parent = hubGroup,
        x = display.contentCenterX,
        y = display.contentHeight - 80,
        width = 300,
        height = 70,
        label = localization.getText("main_menu"),
        fontSize = 28,
        onRelease = function()
            composer.gotoScene("scenes.menu", { effect = "fade", time = 500 })
        end
    })
    
    -- Ship display (visual representation of player's ship)
    local shipContainer = display.newContainer(hubGroup, 200, 200)
    shipContainer.x = display.contentCenterX
    shipContainer.y = display.contentHeight - 260
    
    local playerShip = display.newPolygon(shipContainer, 0, 0, { 0,-40, -30,40, 0,20, 30,40 })
    playerShip:setFillColor(0.2, 0.8, 0.2) -- Green ship
    
    -- Add equipped drones to the visual representation
    for i = 1, #_G.playerData.equippedDrones do
        local drone = display.newCircle(shipContainer, math.random(-40, 40), math.random(-60, 0), 10)
        drone:setFillColor(0.2, 0.8, 0.2, 0.8) -- Green drones
        
        -- Animate drones
        local function animateDrone()
            transition.to(drone, {
                x = math.random(-40, 40),
                y = math.random(-60, 0),
                time = math.random(2000, 4000),
                transition = easing.inOutQuad,
                onComplete = animateDrone
            })
        end
        animateDrone()
    end
    
    -- Check fuel refill timer
    local currentTime = os.time()
    local lastRefuelTime = _G.playerData.missions.lastRefuelTime
    local timePassed = currentTime - lastRefuelTime
    
    -- Refill fuel if 30 minutes have passed
    if timePassed >= 1800 and _G.playerData.missions.availableFuel < 10 then
        _G.playerData.missions.availableFuel = 10
        _G.playerData.missions.lastRefuelTime = currentTime
        saveManager.saveGame(_G.playerData)
        
        -- Update missions button text
        menuButtons.missions.label.text = localization.getText("missions") .. "\nFuel: " .. _G.playerData.missions.availableFuel .. "/10"
    end
end

function scene:updatePlayerInfo()
    -- Clear previous info
    for i = playerInfoPanel.numChildren, 1, -1 do
        playerInfoPanel[i]:removeSelf()
    end
    
    -- Level and rank
    local levelText = display.newText({
        parent = playerInfoPanel,
        text = localization.getText("level") .. ": " .. _G.playerData.level .. " - " .. _G.playerData.rank,
        x = 0,
        y = -50,
        font = native.systemFontBold,
        fontSize = 28
    })
    levelText:setFillColor(0.9, 0.9, 0.9)
    levelText.anchorX = 0
    levelText.x = -playerInfoPanel.width/2 + 20
    
    -- Tech fragments (currency)
    local fragmentsText = display.newText({
        parent = playerInfoPanel,
        text = localization.getText("tech_fragments") .. ": " .. _G.playerData.techFragments,
        x = 0,
        y = -10,
        font = native.systemFont,
        fontSize = 24
    })
    fragmentsText:setFillColor(0.9, 0.7, 0)
    fragmentsText.anchorX = 0
    fragmentsText.x = -playerInfoPanel.width/2 + 20
    
    -- XP progress
    local xpText = display.newText({
        parent = playerInfoPanel,
        text = localization.getText("xp") .. ": " .. _G.playerData.xp .. "/" .. _G.playerData.xpToNextLevel,
        x = 0,
        y = 25,
        font = native.systemFont,
        fontSize = 22
    })
    xpText:setFillColor(0.6, 0.8, 1)
    xpText.anchorX = 0
    xpText.x = -playerInfoPanel.width/2 + 20
    
    -- Skill points (if available)
    if _G.playerData.skillPoints > 0 then
        local skillPointsText = display.newText({
            parent = playerInfoPanel,
            text = localization.getText("skill_points_available") .. ": " .. _G.playerData.skillPoints,
            x = 0,
            y = 60,
            font = native.systemFontBold,
            fontSize = 22
        })
        skillPointsText:setFillColor(0.2, 1, 0.2)
        skillPointsText.anchorX = 0
        skillPointsText.x = -playerInfoPanel.width/2 + 20
    end
    
    -- Basic stats on the right side
    local healthText = display.newText({
        parent = playerInfoPanel,
        text = localization.getText("health") .. ": " .. _G.playerData.stats.health,
        x = 0,
        y = -30,
        font = native.systemFont,
        fontSize = 20
    })
    healthText:setFillColor(1, 0.4, 0.4)
    healthText.anchorX = 0
    healthText.x = 20
    
    -- Shields
    local shieldText = display.newText({
        parent = playerInfoPanel,
        text = localization.getText("shields") .. ": " .. _G.playerData.stats.shields,
        x = 0,
        y = 0,
        font = native.systemFont,
        fontSize = 20
    })
    shieldText:setFillColor(0.4, 0.6, 1)
    shieldText.anchorX = 0
    shieldText.x = 20
    
    -- Energy
    local energyText = display.newText({
        parent = playerInfoPanel,
        text = localization.getText("energy") .. ": " .. _G.playerData.stats.energy,
        x = 0,
        y = 30,
        font = native.systemFont,
        fontSize = 20
    })
    energyText:setFillColor(0.6, 0.8, 0.2)
    energyText.anchorX = 0
    energyText.x = 20
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase
    
    if phase == "will" then
        -- Called when the scene is about to come on screen
        self:updatePlayerInfo()
        
        -- Просто отключим обновление кнопки для начала, чтобы избежать ошибок
        -- Позже мы сможем добавить корректное обновление текста кнопки
        -- if menuButtons.missions then
        --     menuButtons.missions.text = localization.getText("missions") .. "\nFuel: " .. _G.playerData.missions.availableFuel .. "/10"
        -- end
    elseif phase == "did" then
        -- Called when the scene is now on screen
    end
end

function scene:hide(event)
    local sceneGroup = self.view
    local phase = event.phase
    
    if phase == "will" then
        -- Called when the scene is about to go off screen
    elseif phase == "did" then
        -- Called when the scene is now off screen
    end
end

function scene:destroy(event)
    local sceneGroup = self.view
    -- Clean up any saved references
end

-- Scene event listeners
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
