-----------------------------------------------------------------------------------------
-- Settings Scene
-- Allows player to configure game settings
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
local volumeSlider
local musicSlider
local languageSelector
local languages = {"en", "ru"}

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
        text = localization.getText("settings"),
        x = display.contentCenterX,
        y = 70,
        font = native.systemFontBold,
        fontSize = 44
    })
    title:setFillColor(0.9, 0.7, 0) -- Gold title
    
    -- Create main panel
    mainPanel = panel.create({
        parent = sceneGroup,
        x = display.contentCenterX,
        y = display.contentCenterY,
        width = display.contentWidth - 80,
        height = display.contentHeight - 200,
        cornerRadius = 12
    })
    
    -- Create settings options
    local yPos = -mainPanel.height/2 + 70
    local padding = 40
    
    -- Sound volume setting
    local soundLabel = display.newText({
        parent = mainPanel,
        text = localization.getText("sound_volume"),
        x = -mainPanel.width/4,
        y = yPos,
        font = native.systemFont,
        fontSize = 24
    })
    
    volumeSlider = widget.newSlider({
        x = mainPanel.width/4,
        y = yPos,
        width = mainPanel.width/2,
        value = _G.gameSettings and _G.gameSettings.soundVolume or 75,
        listener = function(event)
            if _G.gameSettings then
                _G.gameSettings.soundVolume = event.value
            end
        end
    })
    mainPanel:insert(volumeSlider)
    
    -- Music volume setting
    yPos = yPos + padding
    local musicLabel = display.newText({
        parent = mainPanel,
        text = localization.getText("music_volume"),
        x = -mainPanel.width/4,
        y = yPos,
        font = native.systemFont,
        fontSize = 24
    })
    
    musicSlider = widget.newSlider({
        x = mainPanel.width/4,
        y = yPos,
        width = mainPanel.width/2,
        value = _G.gameSettings and _G.gameSettings.musicVolume or 50,
        listener = function(event)
            if _G.gameSettings then
                _G.gameSettings.musicVolume = event.value
            end
        end
    })
    mainPanel:insert(musicSlider)
    
    -- Language setting
    yPos = yPos + padding * 1.5
    local languageLabel = display.newText({
        parent = mainPanel,
        text = localization.getText("language"),
        x = -mainPanel.width/4,
        y = yPos,
        font = native.systemFont,
        fontSize = 24
    })
    
    -- Create language selector buttons
    local buttonWidth = 120
    local buttonSpacing = 20
    local startX = -buttonWidth/2 - buttonSpacing/2
    
    for i, lang in ipairs(languages) do
        local isSelected = _G.language == lang
        local langButton = button.create({
            parent = mainPanel,
            x = mainPanel.width/4 + startX + (i-1) * (buttonWidth + buttonSpacing),
            y = yPos,
            width = buttonWidth,
            height = 50,
            label = localization.getLanguageName(lang),
            fillColor = isSelected and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
            onRelease = function()
                self:selectLanguage(lang)
            end
        })
    end
    
    -- Create back button
    local backButton = button.create({
        parent = sceneGroup,
        x = display.contentCenterX,
        y = display.contentHeight - 80,
        width = 200,
        height = 60,
        label = localization.getText("back"),
        onRelease = function()
            -- Save settings
            if _G.gameSettings then
                -- Пока сохраняем настройки в глобальной переменной
                -- Так как метод saveSettings может отсутствовать
                _G.gameSettings.saved = true
            end
            composer.gotoScene("scenes.menu", { effect = "slideRight", time = 500 })
        end
    })
    
    -- Initialize game settings if needed
    if not _G.gameSettings then
        _G.gameSettings = saveManager.loadSettings() or {
            soundVolume = 75,
            musicVolume = 50,
            language = _G.language or "en"
        }
    end
end

function scene:selectLanguage(lang)
    -- Set new language
    _G.language = lang
    if _G.gameSettings then
        _G.gameSettings.language = lang
    end
    
    -- Reload current scene to apply language change
    composer.removeScene("scenes.settings")
    composer.gotoScene("scenes.settings", { effect = "fade", time = 300 })
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
    if volumeSlider then
        volumeSlider:removeSelf()
        volumeSlider = nil
    end
    
    if musicSlider then
        musicSlider:removeSelf()
        musicSlider = nil
    end
end

-- Add scene event listeners
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene