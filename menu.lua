-----------------------------------------------------------------------------------------
-- Main Menu Scene
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()

local widget = require("widget")
local localization = require("utils.localization")
local saveManager = require("utils.save_manager")
local button = require("ui.button")

-- Local variables
local background
local title
local menuGroup

function scene:create(event)
    local sceneGroup = self.view
    
    -- Create background
    background = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    background:setFillColor(0.1, 0.1, 0.2) -- Dark blue background
    
    -- Create title
    title = display.newText({
        parent = sceneGroup,
        text = "SPACE FIGHTER",
        x = display.contentCenterX,
        y = display.contentHeight * 0.15,
        font = native.systemFontBold,
        fontSize = 72
    })
    title:setFillColor(0.2, 0.8, 0.2) -- Green title
    
    -- Subtitle
    local subtitle = display.newText({
        parent = sceneGroup,
        text = "COSMIC DEFENDER",
        x = display.contentCenterX,
        y = display.contentHeight * 0.22,
        font = native.systemFont,
        fontSize = 36
    })
    subtitle:setFillColor(0.7, 0.7, 0.7) -- Light grey
    
    -- Create menu buttons group
    menuGroup = display.newGroup()
    sceneGroup:insert(menuGroup)
    
    -- Check if save data exists
    local hasSaveData = saveManager.saveExists()
    
    -- Create menu buttons
    local buttonY = display.contentHeight * 0.4
    local buttonSpacing = 120
    
    local newGameBtn = button.create({
        parent = menuGroup,
        x = display.contentCenterX,
        y = buttonY,
        width = 400,
        height = 80,
        label = localization.getText("new_game"),
        onRelease = function()
            -- Reset game data and start new game
            _G.playerData = nil
            initializeGame()
            composer.gotoScene("scenes.hub", { effect = "fade", time = 500 })
        end
    })
    
    buttonY = buttonY + buttonSpacing
    
    -- Continue button (only if save data exists)
    local continueBtn = button.create({
        parent = menuGroup,
        x = display.contentCenterX,
        y = buttonY,
        width = 400,
        height = 80,
        label = localization.getText("continue"),
        onRelease = function()
            composer.gotoScene("scenes.hub", { effect = "fade", time = 500 })
        end
    })
    continueBtn.isVisible = hasSaveData
    
    if hasSaveData then
        buttonY = buttonY + buttonSpacing
    end
    
    -- Settings button
    local settingsBtn = button.create({
        parent = menuGroup,
        x = display.contentCenterX,
        y = buttonY,
        width = 400,
        height = 80,
        label = localization.getText("settings"),
        onRelease = function()
            composer.gotoScene("scenes.settings", { effect = "slideLeft", time = 500 })
        end
    })
    
    buttonY = buttonY + buttonSpacing
    
    -- Exit button
    local exitBtn = button.create({
        parent = menuGroup,
        x = display.contentCenterX,
        y = buttonY,
        width = 400,
        height = 80,
        label = localization.getText("exit"),
        onRelease = function()
            -- Save game before exit
            if _G.playerData then
                saveManager.saveGame(_G.playerData)
            end
            native.requestExit()
        end
    })
    
    -- Create a simple ship animation in the background
    local ship = display.newPolygon(sceneGroup, display.contentWidth * 0.8, display.contentHeight * 0.7, { 0,0, -30,50, 0,30, 30,50 })
    ship:setFillColor(0.2, 0.8, 0.2) -- Green ship
    ship.alpha = 0.5
    
    -- Animate the ship
    local function animateShip()
        transition.to(ship, {
            y = ship.y - 200,
            rotation = ship.rotation + math.random(-20, 20),
            time = 2000,
            onComplete = function()
                ship.y = display.contentHeight + 50
                ship.x = display.contentWidth * math.random(0.2, 0.8)
                animateShip()
            end
        })
    end
    animateShip()
    
    -- Version text
    local versionText = display.newText({
        parent = sceneGroup,
        text = "v1.0.0",
        x = display.contentWidth - 50,
        y = display.contentHeight - 30,
        font = native.systemFont,
        fontSize = 16
    })
    versionText:setFillColor(0.5, 0.5, 0.5)
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase
    
    if phase == "will" then
        -- Called when the scene is about to come on screen
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
    -- Called when the scene is destroyed
    
    -- Clean up any saved references to display objects
end

-- Reinitialize player data if needed
function initializeGame()
    _G.playerData = saveManager.loadGame() or {
        level = 1,
        xp = 0,
        xpToNextLevel = 100,
        techFragments = 0,
        fuel = 10,
        skillPoints = 0,
        rank = "Cadet",
        stats = {
            health = 100,
            shields = 0,
            energy = 100,
            heatCapacity = 100,
            maneuverability = 50,
            energyRegen = 5,
            coolingRate = 5,
            shieldStrength = 0,
            shieldRegen = 0
        },
        weaponStats = {
            laser = 1,
            plasma = 1,
            missile = 1,
            railgun = 1
        },
        inventory = {
            weapons = {},
            modules = {},
            drones = {},
            consumables = {}
        },
        equippedWeapons = {
            primary = "basic_laser",
            secondary = nil
        },
        equippedDrones = {},
        equippedModules = {},
        missions = {
            completed = 0,
            availableFuel = 10,
            lastRefuelTime = 0
        },
        artifacts = {},
        logEntries = {},
        tutorialCompleted = false
    }
    
    -- Add starting equipment if new game
    if #_G.playerData.inventory.weapons == 0 then
        table.insert(_G.playerData.inventory.weapons, {
            id = "basic_laser",
            name = localization.getText("weapon_basic_laser"),
            type = "laser",
            damage = 10,
            fireRate = 0.2,
            energyCost = 5,
            heatGeneration = 5,
            rarity = "common"
        })
    end
    
    -- Save initialized data
    saveManager.saveGame(_G.playerData)
end

-- Scene event listeners
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
