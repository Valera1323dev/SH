-----------------------------------------------------------------------------------------
-- Missions Scene
-- Allows player to select and launch missions
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()

local widget = require("widget")

-- Import modules
local constants = require("gamelogic.constants")
local missionGenerator = require("gamelogic.mission_generator")
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
local difficultyButtons = {}
local missionTypeButtons = {}
local missionPanel
local selectedDifficulty = "medium"
local selectedMissionType = "cleanup"
local availableMissions = {}
local scrollView

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
        text = localization.getText("missions"),
        x = display.contentCenterX,
        y = 70,
        font = native.systemFontBold,
        fontSize = 44
    })
    title:setFillColor(0.9, 0.6, 0.2) -- Orange title
    
    -- Create main panel
    mainPanel = panel.create({
        parent = sceneGroup,
        x = display.contentCenterX,
        y = display.contentCenterY,
        width = display.contentWidth - 40,
        height = display.contentHeight - 160,
        cornerRadius = 12
    })
    
    -- Create mission selection controls
    
    -- Create difficulty selector panel
    local difficultyPanel = panel.createWithTitle({
        parent = mainPanel,
        x = -mainPanel.width/4,
        y = -mainPanel.height/2 + 90,
        width = mainPanel.width/2 - 20,
        height = 140,
        cornerRadius = 8,
        title = localization.getText("difficulty")
    })
    
    -- Create difficulty buttons
    local difficultyWidth = (difficultyPanel.contentWidth - 40) / 4
    local difficultyX = -difficultyPanel.contentWidth/2 + difficultyWidth/2 + 10
    
    -- Easy difficulty
    difficultyButtons.easy = button.create({
        parent = difficultyPanel,
        x = difficultyX,
        y = 0,
        width = difficultyWidth,
        height = 50,
        label = localization.getText("easy"),
        fontSize = 18,
        fillColor = selectedDifficulty == "easy" and constants.UI.COLORS.GREEN or constants.UI.COLORS.DARK_GRAY,
        onRelease = function()
            self:selectDifficulty("easy")
        end
    })
    
    -- Medium difficulty
    difficultyButtons.medium = button.create({
        parent = difficultyPanel,
        x = difficultyX + difficultyWidth + 5,
        y = 0,
        width = difficultyWidth,
        height = 50,
        label = localization.getText("medium"),
        fontSize = 18,
        fillColor = selectedDifficulty == "medium" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
        onRelease = function()
            self:selectDifficulty("medium")
        end
    })
    
    -- Hard difficulty
    difficultyButtons.hard = button.create({
        parent = difficultyPanel,
        x = difficultyX + (difficultyWidth + 5) * 2,
        y = 0,
        width = difficultyWidth,
        height = 50,
        label = localization.getText("hard"),
        fontSize = 18,
        fillColor = selectedDifficulty == "hard" and constants.UI.COLORS.ORANGE or constants.UI.COLORS.DARK_GRAY,
        onRelease = function()
            self:selectDifficulty("hard")
        end
    })
    
    -- Extreme difficulty
    difficultyButtons.extreme = button.create({
        parent = difficultyPanel,
        x = difficultyX + (difficultyWidth + 5) * 3,
        y = 0,
        width = difficultyWidth,
        height = 50,
        label = localization.getText("extreme"),
        fontSize = 18,
        fillColor = selectedDifficulty == "extreme" and constants.UI.COLORS.RED or constants.UI.COLORS.DARK_GRAY,
        onRelease = function()
            self:selectDifficulty("extreme")
        end
    })
    
    -- Create mission type selector panel
    local typePanel = panel.createWithTitle({
        parent = mainPanel,
        x = mainPanel.width/4,
        y = -mainPanel.height/2 + 90,
        width = mainPanel.width/2 - 20,
        height = 140,
        cornerRadius = 8,
        title = localization.getText("mission_type")
    })
    
    -- Create mission type buttons
    local typeWidth = (typePanel.contentWidth - 50) / 3
    local typeX = -typePanel.contentWidth/2 + typeWidth/2 + 10
    
    -- Cleanup mission type
    missionTypeButtons.cleanup = button.create({
        parent = typePanel,
        x = typeX,
        y = -20,
        width = typeWidth,
        height = 40,
        label = localization.getText("mission_cleanup"),
        fontSize = 16,
        fillColor = selectedMissionType == "cleanup" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
        onRelease = function()
            self:selectMissionType("cleanup")
        end
    })
    
    -- Defense mission type
    missionTypeButtons.defense = button.create({
        parent = typePanel,
        x = typeX + typeWidth + 5,
        y = -20,
        width = typeWidth,
        height = 40,
        label = localization.getText("mission_defense"),
        fontSize = 16,
        fillColor = selectedMissionType == "defense" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
        onRelease = function()
            self:selectMissionType("defense")
        end
    })
    
    -- Escort mission type
    missionTypeButtons.escort = button.create({
        parent = typePanel,
        x = typeX + (typeWidth + 5) * 2,
        y = -20,
        width = typeWidth,
        height = 40,
        label = localization.getText("mission_escort"),
        fontSize = 16,
        fillColor = selectedMissionType == "escort" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
        onRelease = function()
            self:selectMissionType("escort")
        end
    })
    
    -- Recon mission type
    missionTypeButtons.recon = button.create({
        parent = typePanel,
        x = typeX,
        y = 30,
        width = typeWidth,
        height = 40,
        label = localization.getText("mission_recon"),
        fontSize = 16,
        fillColor = selectedMissionType == "recon" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
        onRelease = function()
            self:selectMissionType("recon")
        end
    })
    
    -- Boss hunt mission type
    missionTypeButtons.boss = button.create({
        parent = typePanel,
        x = typeX + typeWidth + 5,
        y = 30,
        width = typeWidth,
        height = 40,
        label = localization.getText("mission_boss"),
        fontSize = 16,
        fillColor = selectedMissionType == "boss" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
        onRelease = function()
            self:selectMissionType("boss")
        end
    })
    
    -- Survival mission type
    missionTypeButtons.survival = button.create({
        parent = typePanel,
        x = typeX + (typeWidth + 5) * 2,
        y = 30,
        width = typeWidth,
        height = 40,
        label = localization.getText("mission_survival"),
        fontSize = 16,
        fillColor = selectedMissionType == "survival" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
        onRelease = function()
            self:selectMissionType("survival")
        end
    })
    
    -- Create missions list panel
    missionPanel = panel.createWithTitle({
        parent = mainPanel,
        x = 0,
        y = mainPanel.height/6,
        width = mainPanel.width - 40,
        height = mainPanel.height * 0.6,
        cornerRadius = 8,
        title = localization.getText("available_missions")
    })
    
    -- Create scrollable mission list
    scrollView = widget.newScrollView({
        x = 0,
        y = 0,
        width = missionPanel.contentWidth - 20,
        height = missionPanel.contentHeight - 20,
        hideBackground = true,
        horizontalScrollDisabled = true
    })
    missionPanel:insert(scrollView)
    
    -- Player fuel display
    local fuelDisplay = display.newText({
        parent = mainPanel,
        text = localization.getText("fuel") .. ": " .. _G.playerData.missions.availableFuel .. "/10",
        x = mainPanel.width/2 - 80,
        y = -mainPanel.height/2 + 20,
        font = native.systemFontBold,
        fontSize = 24
    })
    fuelDisplay:setFillColor(0.9, 0.7, 0)
    fuelDisplay.anchorX = 1
    
    -- Create refresh button
    local refreshButton = button.create({
        parent = mainPanel,
        x = 0,
        y = mainPanel.height/2 - 40,
        width = 200,
        height = 50,
        label = localization.getText("refresh_missions"),
        fontSize = 20,
        onRelease = function()
            self:generateMissions()
        end
    })
    
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
    
    -- Generate initial missions
    self:generateMissions()
end

function scene:selectDifficulty(difficulty)
    -- Update selected difficulty
    selectedDifficulty = difficulty
    
    -- Update button colors
    difficultyButtons.easy:setFillColor(unpack(difficulty == "easy" and constants.UI.COLORS.GREEN or constants.UI.COLORS.DARK_GRAY))
    difficultyButtons.medium:setFillColor(unpack(difficulty == "medium" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY))
    difficultyButtons.hard:setFillColor(unpack(difficulty == "hard" and constants.UI.COLORS.ORANGE or constants.UI.COLORS.DARK_GRAY))
    difficultyButtons.extreme:setFillColor(unpack(difficulty == "extreme" and constants.UI.COLORS.RED or constants.UI.COLORS.DARK_GRAY))
    
    -- Regenerate missions
    self:generateMissions()
end

function scene:selectMissionType(missionType)
    -- Update selected mission type
    selectedMissionType = missionType
    
    -- Update button colors
    for type, button in pairs(missionTypeButtons) do
        button:setFillColor(unpack(type == missionType and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY))
    end
    
    -- Regenerate missions
    self:generateMissions()
end

function scene:generateMissions()
    -- Generate new missions based on selected criteria
    availableMissions = missionGenerator.generateMissions(selectedDifficulty, selectedMissionType, 5)
    
    -- Display generated missions
    self:displayMissions()
end

function scene:displayMissions()
    -- Clear previous mission list
    for i = scrollView.numChildren, 1, -1 do
        scrollView[i]:removeSelf()
    end
    
    -- Check if player has fuel
    if _G.playerData.missions.availableFuel <= 0 then
        local noFuelText = display.newText({
            parent = scrollView,
            text = localization.getText("no_fuel"),
            x = scrollView.width/2,
            y = 100,
            font = native.systemFontBold,
            fontSize = 22,
            align = "center",
            width = scrollView.width - 40
        })
        noFuelText:setFillColor(1, 0.3, 0.3)
        
        local refuelText = display.newText({
            parent = scrollView,
            text = localization.getText("visit_terminal"),
            x = scrollView.width/2,
            y = 150,
            font = native.systemFont,
            fontSize = 18,
            align = "center",
            width = scrollView.width - 40
        })
        
        return
    end
    
    -- Display missions
    local yPos = 30
    local missionHeight = 120
    local padding = 10
    
    for i, mission in ipairs(availableMissions) do
        -- Create mission panel
        local missionBg = display.newRect(scrollView, scrollView.width/2, yPos, scrollView.width - 20, missionHeight)
        missionBg:setFillColor(0.15, 0.15, 0.2)
        missionBg.strokeWidth = 2
        
        -- Set stroke color based on difficulty
        local difficultyColors = {
            easy = constants.UI.COLORS.GREEN,
            medium = constants.UI.COLORS.BLUE,
            hard = constants.UI.COLORS.ORANGE,
            extreme = constants.UI.COLORS.RED
        }
        local strokeColor = difficultyColors[mission.difficulty] or {1, 1, 1}
        missionBg:setStrokeColor(unpack(strokeColor))
        
        -- Mission name
        local nameText = display.newText({
            parent = scrollView,
            text = mission.name,
            x = 20,
            y = yPos - missionHeight/2 + 20,
            font = native.systemFontBold,
            fontSize = 20
        })
        nameText.anchorX = 0
        nameText:setFillColor(unpack(strokeColor))
        
        -- Mission description
        local descText = display.newText({
            parent = scrollView,
            text = mission.description,
            x = 20,
            y = yPos,
            font = native.systemFont,
            fontSize = 16,
            align = "left",
            width = scrollView.width - 160
        })
        descText.anchorX = 0
        descText:setFillColor(0.9, 0.9, 0.9)
        
        -- Rewards text
        local rewardsText = display.newText({
            parent = scrollView,
            text = localization.getText("xp") .. ": " .. mission.rewards.xp .. "\n" .. 
                  localization.getText("tech_fragments") .. ": " .. mission.rewards.techFragments,
            x = 20,
            y = yPos + missionHeight/2 - 20,
            font = native.systemFont,
            fontSize = 16,
            align = "left"
        })
        rewardsText.anchorX = 0
        rewardsText:setFillColor(0.9, 0.7, 0)
        
        -- Launch button
        local launchBtn = button.create({
            parent = scrollView,
            x = scrollView.width - 80,
            y = yPos,
            width = 120,
            height = 50,
            label = localization.getText("launch"),
            fontSize = 18,
            onRelease = function()
                self:launchMission(mission)
            end
        })
        
        -- Increment position for next mission
        yPos = yPos + missionHeight + padding
    end
    
    -- Set content height
    scrollView:setScrollHeight(yPos + 30)
end

function scene:launchMission(mission)
    -- Check if player has fuel
    if _G.playerData.missions.availableFuel <= 0 then
        -- Show error message
        local alertText = display.newText({
            parent = mainPanel,
            text = localization.getText("no_fuel_error"),
            x = 0,
            y = 0,
            font = native.systemFontBold,
            fontSize = 24
        })
        alertText:setFillColor(1, 0.3, 0.3)
        
        -- Fade out after delay
        timer.performWithDelay(2000, function()
            transition.to(alertText, {time = 500, alpha = 0, onComplete = function()
                display.remove(alertText)
            end})
        end)
        
        return
    end
    
    -- Consume fuel
    _G.playerData.missions.availableFuel = _G.playerData.missions.availableFuel - 1
    
    -- Save current mission data for the game scene
    _G.currentMission = mission
    
    -- Save player data
    saveManager.saveGame(_G.playerData)
    
    -- Go to game scene
    composer.gotoScene("scenes.game", {
        effect = "fade",
        time = 800
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