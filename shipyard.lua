-----------------------------------------------------------------------------------------
-- Shipyard Scene
-- Allows player to customize their ship, install modules and drones
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()

local widget = require("widget")

-- Import modules
local constants = require("gamelogic.constants")
local player = require("gamelogic.player")
local weapons = require("gamelogic.weapons")
local drones = require("gamelogic.drones")
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
local shipDisplay
local equipmentPanel
local statsPanel

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
        text = localization.getText("shipyard"),
        x = display.contentCenterX,
        y = 70,
        font = native.systemFontBold,
        fontSize = 44
    })
    title:setFillColor(0.3, 0.7, 0.9) -- Blue title
    
    -- Create main panel
    mainPanel = panel.create({
        parent = sceneGroup,
        x = display.contentCenterX,
        y = display.contentCenterY,
        width = display.contentWidth - 40,
        height = display.contentHeight - 160,
        cornerRadius = 12
    })
    
    -- Create ship display panel
    shipDisplay = panel.create({
        parent = mainPanel,
        x = 0,
        y = -mainPanel.height/4,
        width = mainPanel.width * 0.9,
        height = mainPanel.height * 0.4,
        cornerRadius = 8
    })
    
    -- Draw player ship
    local ship = display.newPolygon(shipDisplay, 0, 0, {0, -30, 20, 30, 0, 15, -20, 30})
    ship:setFillColor(0.2, 0.8, 0.2) -- Green ship
    
    -- Create weapon slots
    local primarySlot = display.newCircle(shipDisplay, 0, -10, 10)
    primarySlot:setFillColor(0.8, 0.2, 0.2, 0.6) -- Red slot
    primarySlot.strokeWidth = 2
    primarySlot:setStrokeColor(1, 1, 1, 0.8)
    
    local secondarySlot = display.newCircle(shipDisplay, 0, 10, 8)
    secondarySlot:setFillColor(0.2, 0.2, 0.8, 0.6) -- Blue slot
    secondarySlot.strokeWidth = 2
    secondarySlot:setStrokeColor(1, 1, 1, 0.8)
    
    -- Create drone slots
    local droneSlot1 = display.newCircle(shipDisplay, -30, 0, 6)
    droneSlot1:setFillColor(0.8, 0.8, 0.2, 0.6) -- Yellow slot
    droneSlot1.strokeWidth = 2
    droneSlot1:setStrokeColor(1, 1, 1, 0.8)
    
    local droneSlot2 = display.newCircle(shipDisplay, 30, 0, 6)
    droneSlot2:setFillColor(0.8, 0.8, 0.2, 0.6) -- Yellow slot
    droneSlot2.strokeWidth = 2
    droneSlot2:setStrokeColor(1, 1, 1, 0.8)
    
    -- Add equipped items
    self:updateEquippedItems()
    
    -- Create tabbed equipment panel
    equipmentPanel = panel.createTabbed({
        parent = mainPanel,
        x = 0,
        y = mainPanel.height/4,
        width = mainPanel.width * 0.9,
        height = mainPanel.height * 0.45,
        cornerRadius = 8,
        tabs = {
            localization.getText("weapons"),
            localization.getText("modules"),
            localization.getText("drones")
        },
        onTabChange = function(index)
            self:populateEquipmentTab(index)
        end
    })
    
    -- Сохраняем ссылку на панель оборудования в объекте сцены
    self.equipmentPanel = equipmentPanel
    
    -- Populate initial tab
    self:populateEquipmentTab(1)
    
    -- Create stats panel on the right
    statsPanel = panel.createWithTitle({
        parent = mainPanel,
        x = 0,
        y = 0,
        width = mainPanel.width * 0.9,
        height = mainPanel.height * 0.25,
        cornerRadius = 8,
        title = localization.getText("ship_stats")
    })
    
    -- Update stats display
    self:updateStatsDisplay()
    
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

function scene:updateEquippedItems()
    -- Function to update ship display with equipped items
    -- Will be implemented as needed
end

function scene:populateEquipmentTab(tabIndex)
    -- Проверяем существование панели и вкладок
    if not self.equipmentPanel or not self.equipmentPanel.tabContents then
        print("Панель оборудования не инициализирована")
        return
    end
    
    -- Проверяем существование запрошенной вкладки
    local tabContent = self.equipmentPanel.tabContents[tabIndex]
    if not tabContent then
        print("Вкладка #" .. tabIndex .. " не найдена")
        return
    end
    
    -- Clear current tab content
    for i = tabContent.numChildren, 1, -1 do
        tabContent[i]:removeSelf()
    end
    
    -- Add scrollable container for items
    local scrollView = widget.newScrollView({
        x = 0,
        y = 0,
        width = equipmentPanel.contentWidth - 20,
        height = equipmentPanel.contentHeight - 20,
        hideBackground = true,
        horizontalScrollDisabled = true
    })
    tabContent:insert(scrollView)
    
    local itemY = 30
    local itemHeight = 80
    local padding = 10
    
    -- Populate based on tab
    if tabIndex == 1 then -- Weapons
        -- Show available weapons from inventory
        local weapons = _G.playerData.inventory.weapons or {}
        for i, weapon in ipairs(weapons) do
            self:createEquipmentItem(scrollView, weapon, itemY, "weapon")
            itemY = itemY + itemHeight + padding
        end
    elseif tabIndex == 2 then -- Modules
        -- Show available modules from inventory
        local modules = _G.playerData.inventory.modules or {}
        for i, module in ipairs(modules) do
            self:createEquipmentItem(scrollView, module, itemY, "module")
            itemY = itemY + itemHeight + padding
        end
    elseif tabIndex == 3 then -- Drones
        -- Show available drones from inventory
        local drones = _G.playerData.inventory.drones or {}
        for i, drone in ipairs(drones) do
            self:createEquipmentItem(scrollView, drone, itemY, "drone")
            itemY = itemY + itemHeight + padding
        end
    end
    
    -- Set content height
    scrollView:setScrollHeight(itemY + 30)
end

function scene:createEquipmentItem(parent, item, yPos, itemType)
    -- Create item container
    local itemWidth = parent.width - 20
    
    local itemBg = display.newRect(parent, parent.width/2, yPos, itemWidth, 75)
    itemBg:setFillColor(0.15, 0.15, 0.2)
    itemBg.strokeWidth = 2
    
    -- Set stroke color based on rarity
    local rarityColors = {
        common = {0.7, 0.7, 0.7},
        rare = {0.3, 0.5, 1.0},
        epic = {0.8, 0.3, 1.0}
    }
    local strokeColor = rarityColors[item.rarity] or {1, 1, 1}
    itemBg:setStrokeColor(unpack(strokeColor))
    
    -- Item name
    local nameText = display.newText({
        parent = parent,
        text = item.name,
        x = 20,
        y = yPos - 20,
        font = native.systemFont,
        fontSize = 18
    })
    nameText.anchorX = 0
    nameText:setFillColor(unpack(strokeColor))
    
    -- Item description/type
    local description = ""
    if itemType == "weapon" then
        description = localization.getText("weapon_type_" .. item.type)
    elseif itemType == "module" then
        description = localization.getText("module_type_" .. item.type)
    elseif itemType == "drone" then
        description = localization.getText("drone_type_" .. item.type)
    end
    
    local descText = display.newText({
        parent = parent,
        text = description,
        x = 20,
        y = yPos + 10,
        font = native.systemFont,
        fontSize = 16
    })
    descText.anchorX = 0
    descText:setFillColor(0.7, 0.7, 0.7)
    
    -- Equip button
    local equipBtn = button.create({
        parent = parent,
        x = parent.width - 80,
        y = yPos,
        width = 120,
        height = 50,
        label = localization.getText("equip"),
        fontSize = 18,
        onRelease = function()
            self:equipItem(item, itemType)
        end
    })
    
    -- Check if item is already equipped and update button accordingly
    local isEquipped = false
    
    if itemType == "weapon" and (_G.playerData.equippedWeapons.primary == item.id or _G.playerData.equippedWeapons.secondary == item.id) then
        isEquipped = true
    elseif itemType == "module" and _G.playerData.equippedModules[item.id] then
        isEquipped = true
    elseif itemType == "drone" and _G.playerData.equippedDrones[item.id] then
        isEquipped = true
    end
    
    if isEquipped then
        equipBtn:setLabel(localization.getText("unequip"))
        equipBtn:setFillColor(unpack(constants.UI.COLORS.RED))
    end
end

function scene:equipItem(item, itemType)
    -- Function to equip/unequip selected item
    -- Will be implemented as needed with logic to handle each type
    -- Save changes to player data
    saveManager.saveGame(_G.playerData)
    
    -- Update display
    self:updateEquippedItems()
    self:updateStatsDisplay()
    self:populateEquipmentTab(self.equipmentPanel.activeTab)
end

function scene:updateStatsDisplay()
    -- Clear current stats
    for i = statsPanel.numChildren, 1, -1 do
        if statsPanel[i] ~= statsPanel.title then
            statsPanel[i]:removeSelf()
        end
    end
    
    -- Player stats
    local stats = _G.playerData.stats
    local statY = -statsPanel.contentHeight/2 + 30
    local statGap = 25
    local leftMargin = -statsPanel.contentWidth/2 + 20
    
    -- Health
    local healthLabel = display.newText({
        parent = statsPanel,
        text = localization.getText("health") .. ":",
        x = leftMargin,
        y = statY,
        font = native.systemFont,
        fontSize = 18
    })
    healthLabel.anchorX = 0
    
    local healthValue = display.newText({
        parent = statsPanel,
        text = stats.health,
        x = leftMargin + 200,
        y = statY,
        font = native.systemFontBold,
        fontSize = 18
    })
    healthValue.anchorX = 0
    healthValue:setFillColor(0.2, 0.8, 0.2)
    
    -- Shields
    statY = statY + statGap
    local shieldsLabel = display.newText({
        parent = statsPanel,
        text = localization.getText("shields") .. ":",
        x = leftMargin,
        y = statY,
        font = native.systemFont,
        fontSize = 18
    })
    shieldsLabel.anchorX = 0
    
    local shieldsValue = display.newText({
        parent = statsPanel,
        text = stats.shields,
        x = leftMargin + 200,
        y = statY,
        font = native.systemFontBold,
        fontSize = 18
    })
    shieldsValue.anchorX = 0
    shieldsValue:setFillColor(0.3, 0.7, 0.9)
    
    -- Energy
    statY = statY + statGap
    local energyLabel = display.newText({
        parent = statsPanel,
        text = localization.getText("energy") .. ":",
        x = leftMargin,
        y = statY,
        font = native.systemFont,
        fontSize = 18
    })
    energyLabel.anchorX = 0
    
    local energyValue = display.newText({
        parent = statsPanel,
        text = stats.energy,
        x = leftMargin + 200,
        y = statY,
        font = native.systemFontBold,
        fontSize = 18
    })
    energyValue.anchorX = 0
    energyValue:setFillColor(0.9, 0.7, 0.1)
    
    -- Add more stats on the right side
    local rightMargin = 20
    
    -- Maneuverability
    statY = -statsPanel.contentHeight/2 + 30
    local maneuverLabel = display.newText({
        parent = statsPanel,
        text = localization.getText("maneuverability") .. ":",
        x = rightMargin,
        y = statY,
        font = native.systemFont,
        fontSize = 18
    })
    maneuverLabel.anchorX = 0
    
    local maneuverValue = display.newText({
        parent = statsPanel,
        text = stats.maneuverability,
        x = rightMargin + 200,
        y = statY,
        font = native.systemFontBold,
        fontSize = 18
    })
    maneuverValue.anchorX = 0
    maneuverValue:setFillColor(1, 1, 1)
    
    -- Heat capacity
    statY = statY + statGap
    local heatLabel = display.newText({
        parent = statsPanel,
        text = localization.getText("heat_capacity") .. ":",
        x = rightMargin,
        y = statY,
        font = native.systemFont,
        fontSize = 18
    })
    heatLabel.anchorX = 0
    
    local heatValue = display.newText({
        parent = statsPanel,
        text = stats.heatCapacity,
        x = rightMargin + 200,
        y = statY,
        font = native.systemFontBold,
        fontSize = 18
    })
    heatValue.anchorX = 0
    heatValue:setFillColor(0.9, 0.3, 0.2)
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