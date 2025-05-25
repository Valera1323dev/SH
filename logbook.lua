-----------------------------------------------------------------------------------------
-- Logbook Scene
-- Shows story entries and information about alien races
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
local tooltip = require("ui.tooltip")

-- Local variables
local background
local mainPanel
local tabsPanel
local entriesScroll
local selectedCategory = "story"

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
        text = localization.getText("logbook"),
        x = display.contentCenterX,
        y = 70,
        font = native.systemFontBold,
        fontSize = 44
    })
    title:setFillColor(0.7, 0.5, 0.3) -- Brown/orange title
    
    -- Create main panel
    mainPanel = panel.create({
        parent = sceneGroup,
        x = display.contentCenterX,
        y = display.contentCenterY,
        width = display.contentWidth - 40,
        height = display.contentHeight - 160,
        cornerRadius = 12
    })
    
    -- Create tabbed interface
    tabsPanel = panel.createTabbed({
        parent = mainPanel,
        x = 0,
        y = 0,
        width = mainPanel.width - 40,
        height = mainPanel.height - 40,
        cornerRadius = 8,
        tabs = {
            localization.getText("story_logs"),
            localization.getText("alien_races"),
            localization.getText("artifacts")
        },
        onTabChange = function(tabIndex)
            self:selectCategory(tabIndex)
        end
    })
    
    -- Сохраняем ссылку на панель вкладок в объекте сцены
    self.tabsPanel = tabsPanel
    
    -- Create scrollable content area
    for i = 1, 3 do
        local scrollView = widget.newScrollView({
            x = 0,
            y = 20,
            width = tabsPanel.contentWidth - 20,
            height = tabsPanel.contentHeight - 40,
            hideBackground = true,
            horizontalScrollDisabled = true
        })
        tabsPanel.tabContents[i]:insert(scrollView)
    end
    
    -- Populate initial tab
    self:selectCategory(1)
    
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

function scene:selectCategory(tabIndex)
    -- Update selected category based on tab
    if tabIndex == 1 then
        selectedCategory = "story"
    elseif tabIndex == 2 then
        selectedCategory = "races"
    elseif tabIndex == 3 then
        selectedCategory = "artifacts"
    end
    
    -- Populate content
    self:populateContent(tabIndex)
end

function scene:populateContent(tabIndex)
    -- Get scroll view from current tab
    local scrollView = tabsPanel.tabContents[tabIndex][1]
    
    -- Clear current content
    for i = scrollView.numChildren, 1, -1 do
        scrollView[i]:removeSelf()
    end
    
    if selectedCategory == "story" then
        self:populateStoryEntries(scrollView)
    elseif selectedCategory == "races" then
        self:populateAlienRaces(scrollView)
    elseif selectedCategory == "artifacts" then
        self:populateArtifacts(scrollView)
    end
end

function scene:populateStoryEntries(scrollView)
    -- Check if player has any logs
    if not _G.playerData.logEntries or #_G.playerData.logEntries == 0 then
        local noEntriesText = display.newText({
            parent = scrollView,
            text = localization.getText("no_log_entries"),
            x = scrollView.width/2,
            y = 100,
            font = native.systemFontBold,
            fontSize = 22,
            align = "center",
            width = scrollView.width - 40
        })
        noEntriesText:setFillColor(0.7, 0.7, 0.7)
        
        return
    end
    
    -- Display log entries
    local yPos = 30
    local entryHeight = 150
    local padding = 20
    
    for i, entry in ipairs(_G.playerData.logEntries) do
        -- Create entry panel
        local entryPanel = panel.create({
            parent = scrollView,
            x = scrollView.width/2,
            y = yPos + entryHeight/2,
            width = scrollView.width - 40,
            height = entryHeight,
            cornerRadius = 8,
            fillColor = {0.15, 0.12, 0.1, 0.9}
        })
        
        -- Entry date
        local dateText = display.newText({
            parent = scrollView,
            text = entry.date,
            x = 40,
            y = yPos + 20,
            font = native.systemFontBold,
            fontSize = 16
        })
        dateText.anchorX = 0
        dateText:setFillColor(0.7, 0.6, 0.4)
        
        -- Entry title
        local titleText = display.newText({
            parent = scrollView,
            text = entry.title,
            x = 40,
            y = yPos + 50,
            font = native.systemFontBold,
            fontSize = 20
        })
        titleText.anchorX = 0
        titleText:setFillColor(0.9, 0.8, 0.6)
        
        -- Entry content (preview)
        local contentPreview = string.sub(entry.content, 1, 80) .. "..."
        local contentText = display.newText({
            parent = scrollView,
            text = contentPreview,
            x = 40,
            y = yPos + 90,
            font = native.systemFont,
            fontSize = 16,
            align = "left",
            width = scrollView.width - 100
        })
        contentText.anchorX = 0
        contentText:setFillColor(0.8, 0.8, 0.8)
        
        -- Read more button
        local readButton = button.createText({
            parent = scrollView,
            x = scrollView.width - 60,
            y = yPos + entryHeight - 30,
            text = localization.getText("read_more"),
            fontSize = 16,
            color = {0.7, 0.6, 0.4},
            onRelease = function()
                self:showEntryDetail(entry)
            end
        })
        
        -- Increment position for next entry
        yPos = yPos + entryHeight + padding
    end
    
    -- Set content height
    scrollView:setScrollHeight(yPos)
end

function scene:populateAlienRaces(scrollView)
    -- Alien race data
    local races = {
        {
            name = localization.getText("race_insects"),
            description = localization.getText("race_insects_desc"),
            strength = localization.getText("race_insects_strength"),
            weakness = localization.getText("race_insects_weakness"),
            color = {0.7, 0.9, 0.2}
        },
        {
            name = localization.getText("race_robots"),
            description = localization.getText("race_robots_desc"),
            strength = localization.getText("race_robots_strength"),
            weakness = localization.getText("race_robots_weakness"),
            color = {0.5, 0.5, 0.9}
        },
        {
            name = localization.getText("race_parasites"),
            description = localization.getText("race_parasites_desc"),
            strength = localization.getText("race_parasites_strength"),
            weakness = localization.getText("race_parasites_weakness"),
            color = {0.9, 0.3, 0.5}
        },
        {
            name = localization.getText("race_pirates"),
            description = localization.getText("race_pirates_desc"),
            strength = localization.getText("race_pirates_strength"),
            weakness = localization.getText("race_pirates_weakness"),
            color = {0.9, 0.6, 0.3}
        }
    }
    
    -- Display race entries
    local yPos = 30
    local raceHeight = 200
    local padding = 20
    
    for i, race in ipairs(races) do
        -- Create race panel
        local racePanel = panel.create({
            parent = scrollView,
            x = scrollView.width/2,
            y = yPos + raceHeight/2,
            width = scrollView.width - 40,
            height = raceHeight,
            cornerRadius = 8,
            fillColor = {0.1, 0.1, 0.15, 0.9}
        })
        
        -- Race name
        local nameText = display.newText({
            parent = scrollView,
            text = race.name,
            x = 40,
            y = yPos + 30,
            font = native.systemFontBold,
            fontSize = 24
        })
        nameText.anchorX = 0
        nameText:setFillColor(unpack(race.color))
        
        -- Race picture placeholder
        local racePic = display.newRect(scrollView, scrollView.width - 80, yPos + 50, 80, 80)
        racePic:setFillColor(unpack(race.color), 0.3)
        racePic.strokeWidth = 2
        racePic:setStrokeColor(unpack(race.color))
        
        -- Race description
        local descText = display.newText({
            parent = scrollView,
            text = race.description,
            x = 40,
            y = yPos + 80,
            font = native.systemFont,
            fontSize = 16,
            align = "left",
            width = scrollView.width - 150
        })
        descText.anchorX = 0
        descText:setFillColor(0.9, 0.9, 0.9)
        
        -- Strength and weakness
        local strengthLabel = display.newText({
            parent = scrollView,
            text = localization.getText("strength") .. ": ",
            x = 40,
            y = yPos + 140,
            font = native.systemFontBold,
            fontSize = 16
        })
        strengthLabel.anchorX = 0
        strengthLabel:setFillColor(0.3, 0.9, 0.3)
        
        local strengthText = display.newText({
            parent = scrollView,
            text = race.strength,
            x = strengthLabel.x + strengthLabel.width + 5,
            y = yPos + 140,
            font = native.systemFont,
            fontSize = 16,
            align = "left",
            width = scrollView.width - 200
        })
        strengthText.anchorX = 0
        
        local weaknessLabel = display.newText({
            parent = scrollView,
            text = localization.getText("weakness") .. ": ",
            x = 40,
            y = yPos + 170,
            font = native.systemFontBold,
            fontSize = 16
        })
        weaknessLabel.anchorX = 0
        weaknessLabel:setFillColor(0.9, 0.3, 0.3)
        
        local weaknessText = display.newText({
            parent = scrollView,
            text = race.weakness,
            x = weaknessLabel.x + weaknessLabel.width + 5,
            y = yPos + 170,
            font = native.systemFont,
            fontSize = 16,
            align = "left",
            width = scrollView.width - 200
        })
        weaknessText.anchorX = 0
        
        -- Increment position for next race
        yPos = yPos + raceHeight + padding
    end
    
    -- Set content height
    scrollView:setScrollHeight(yPos)
end

function scene:populateArtifacts(scrollView)
    -- Check if player has any artifacts
    if not _G.playerData.artifacts or #_G.playerData.artifacts == 0 then
        local noArtifactsText = display.newText({
            parent = scrollView,
            text = localization.getText("no_artifacts"),
            x = scrollView.width/2,
            y = 100,
            font = native.systemFontBold,
            fontSize = 22,
            align = "center",
            width = scrollView.width - 40
        })
        noArtifactsText:setFillColor(0.7, 0.7, 0.7)
        
        local hintText = display.newText({
            parent = scrollView,
            text = localization.getText("artifact_hint"),
            x = scrollView.width/2,
            y = 150,
            font = native.systemFont,
            fontSize = 18,
            align = "center",
            width = scrollView.width - 80
        })
        hintText:setFillColor(0.5, 0.5, 0.5)
        
        return
    end
    
    -- Display artifacts
    local yPos = 30
    local artifactHeight = 180
    local padding = 20
    
    for i, artifact in ipairs(_G.playerData.artifacts) do
        -- Create artifact panel
        local artifactPanel = panel.create({
            parent = scrollView,
            x = scrollView.width/2,
            y = yPos + artifactHeight/2,
            width = scrollView.width - 40,
            height = artifactHeight,
            cornerRadius = 8,
            fillColor = {0.15, 0.1, 0.2, 0.9}
        })
        
        -- Artifact name
        local nameText = display.newText({
            parent = scrollView,
            text = artifact.name,
            x = 40,
            y = yPos + 30,
            font = native.systemFontBold,
            fontSize = 22
        })
        nameText.anchorX = 0
        nameText:setFillColor(0.8, 0.5, 0.9)
        
        -- Artifact icon placeholder
        local artifactIcon = display.newRect(scrollView, scrollView.width - 80, yPos + 50, 70, 70)
        artifactIcon:setFillColor(0.4, 0.2, 0.5)
        artifactIcon.strokeWidth = 2
        artifactIcon:setStrokeColor(0.8, 0.5, 0.9)
        
        -- Artifact description
        local descText = display.newText({
            parent = scrollView,
            text = artifact.description,
            x = 40,
            y = yPos + 90,
            font = native.systemFont,
            fontSize = 16,
            align = "left",
            width = scrollView.width - 150
        })
        descText.anchorX = 0
        descText:setFillColor(0.9, 0.9, 0.9)
        
        -- Artifact effects
        local effectLabel = display.newText({
            parent = scrollView,
            text = localization.getText("effect") .. ": ",
            x = 40,
            y = yPos + 140,
            font = native.systemFontBold,
            fontSize = 16
        })
        effectLabel.anchorX = 0
        effectLabel:setFillColor(0.8, 0.7, 0.9)
        
        local effectText = display.newText({
            parent = scrollView,
            text = artifact.effect,
            x = effectLabel.x + effectLabel.width + 5,
            y = yPos + 140,
            font = native.systemFont,
            fontSize = 16,
            align = "left",
            width = scrollView.width - 200
        })
        effectText.anchorX = 0
        
        -- Increment position for next artifact
        yPos = yPos + artifactHeight + padding
    end
    
    -- Set content height
    scrollView:setScrollHeight(yPos)
end

function scene:showEntryDetail(entry)
    -- Create modal panel for full entry display
    local modalGroup = display.newGroup()
    self.view:insert(modalGroup)
    
    -- Overlay for background dimming
    local overlay = display.newRect(modalGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    overlay:setFillColor(0, 0, 0, 0.7)
    
    -- Create detail panel
    local detailPanel = panel.create({
        parent = modalGroup,
        x = display.contentCenterX,
        y = display.contentCenterY,
        width = display.contentWidth - 80,
        height = display.contentHeight - 200,
        cornerRadius = 12,
        fillColor = {0.15, 0.12, 0.1, 0.95}
    })
    
    -- Entry date
    local dateText = display.newText({
        parent = modalGroup,
        text = entry.date,
        x = display.contentCenterX,
        y = display.contentCenterY - detailPanel.height/2 + 30,
        font = native.systemFontBold,
        fontSize = 18
    })
    dateText:setFillColor(0.7, 0.6, 0.4)
    
    -- Entry title
    local titleText = display.newText({
        parent = modalGroup,
        text = entry.title,
        x = display.contentCenterX,
        y = display.contentCenterY - detailPanel.height/2 + 70,
        font = native.systemFontBold,
        fontSize = 26
    })
    titleText:setFillColor(0.9, 0.8, 0.6)
    
    -- Create scrollable content area for the entry text
    local scrollView = widget.newScrollView({
        x = display.contentCenterX,
        y = display.contentCenterY + 20,
        width = detailPanel.width - 40,
        height = detailPanel.height - 150,
        hideBackground = true,
        horizontalScrollDisabled = true
    })
    modalGroup:insert(scrollView)
    
    -- Entry content
    local contentText = display.newText({
        parent = scrollView,
        text = entry.content,
        x = scrollView.width/2,
        y = scrollView.height/3,
        font = native.systemFont,
        fontSize = 18,
        align = "left",
        width = scrollView.width - 40
    })
    contentText:setFillColor(0.9, 0.9, 0.9)
    
    -- Adjust scrollHeight based on text height
    scrollView:setScrollHeight(contentText.height + 40)
    
    -- Close button
    local closeButton = button.create({
        parent = modalGroup,
        x = display.contentCenterX,
        y = display.contentCenterY + detailPanel.height/2 - 30,
        width = 160,
        height = 50,
        label = localization.getText("close"),
        fontSize = 20,
        onRelease = function()
            display.remove(modalGroup)
        end
    })
    
    -- Animation for entry appearance
    detailPanel.alpha = 0
    detailPanel.xScale = 0.8
    detailPanel.yScale = 0.8
    
    transition.to(detailPanel, {
        time = 300,
        alpha = 1,
        xScale = 1,
        yScale = 1,
        transition = easing.outQuad
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