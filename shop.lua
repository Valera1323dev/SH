-----------------------------------------------------------------------------------------
-- Shop Scene
-- Allows player to purchase weapons, modules, drones, and consumables
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()

local widget = require("widget")
local json = require("json")

-- Import modules
local constants = require("gamelogic.constants")
local player = require("gamelogic.player")
local weapons = require("gamelogic.weapons")
local drones = require("gamelogic.drones")
local itemDatabase = require("gamelogic.item_database")
local shopGenerator = require("gamelogic.shop_generator")
local saveManager = require("utils.save_manager")
local localization = require("utils.localization")
local utils = require("utils.utils")

-- Import UI components
local button = require("ui.button")
local panel = require("ui.panel")
local progressBar = require("ui.progress_bar")
local tooltip = require("ui.tooltip")

-- Local variables
local background
local mainPanel
local categoryPanel
local itemListGroup
local itemDetailPanel
local playerCurrencyText
local selectedCategory = "weapons"
local selectedItem = nil
local shopInventory = nil
local specialDealItem = nil
local specialDealType = nil
local refreshCount = 0
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
        text = localization.getText("shop"),
        x = display.contentCenterX,
        y = 70,
        font = native.systemFontBold,
        fontSize = 44
    })
    title:setFillColor(0.9, 0.7, 0) -- Gold title
    
    -- Create main shop panel
    mainPanel = panel.create({
        parent = sceneGroup,
        x = display.contentCenterX,
        y = display.contentHeight * 0.52,
        width = display.contentWidth - 40,
        height = display.contentHeight - 160,
        cornerRadius = 12
    })
    
    -- Create category selection panel
    categoryPanel = panel.create({
        parent = sceneGroup,
        x = display.contentWidth * 0.25,
        y = 150,
        width = display.contentWidth - 60,
        height = 80,
        cornerRadius = 8
    })
    
    -- Create category buttons
    local categoryWidth = (display.contentWidth - 80) / 4
    local categoryX = -categoryPanel.width/2 + categoryWidth/2 + 10
    
    local categoryButtons = {
        weapons = button.create({
            parent = categoryPanel,
            x = categoryX,
            y = 0,
            width = categoryWidth,
            height = 60,
            label = localization.getText("weapons"),
            fontSize = 20,
            fillColor = selectedCategory == "weapons" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
            onRelease = function()
                self:selectCategory("weapons")
            end
        }),
        
        modules = button.create({
            parent = categoryPanel,
            x = categoryX + categoryWidth,
            y = 0,
            width = categoryWidth,
            height = 60,
            label = localization.getText("modules"),
            fontSize = 20,
            fillColor = selectedCategory == "modules" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
            onRelease = function()
                self:selectCategory("modules")
            end
        }),
        
        drones = button.create({
            parent = categoryPanel,
            x = categoryX + categoryWidth * 2,
            y = 0,
            width = categoryWidth,
            height = 60,
            label = localization.getText("drones"),
            fontSize = 20,
            fillColor = selectedCategory == "drones" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
            onRelease = function()
                self:selectCategory("drones")
            end
        }),
        
        consumables = button.create({
            parent = categoryPanel,
            x = categoryX + categoryWidth * 3,
            y = 0,
            width = categoryWidth,
            height = 60,
            label = localization.getText("consumables"),
            fontSize = 20,
            fillColor = selectedCategory == "consumables" and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY,
            onRelease = function()
                self:selectCategory("consumables")
            end
        })
    }
    self.categoryButtons = categoryButtons
    
    -- Create scrollable item list
    local itemListPanel = panel.createScrollable({
        parent = mainPanel,
        x = 0,
        y = -mainPanel.height/2 + 210,
        width = mainPanel.width * 0.45,
        height = 380,
        cornerRadius = 8
    })
    scrollView = itemListPanel.scrollView
    
    -- Create item detail panel
    itemDetailPanel = panel.create({
        parent = mainPanel,
        x = mainPanel.width * 0.25,
        y = 30,
        width = mainPanel.width * 0.4,
        height = 350,
        cornerRadius = 8
    })
    
    -- Create player currency display
    playerCurrencyText = display.newText({
        parent = sceneGroup,
        text = localization.getText("tech_fragments") .. ": " .. (_G.playerData.techFragments or 0),
        x = display.contentWidth - 150,
        y = 150,
        font = native.systemFontBold,
        fontSize = 24,
        align = "right"
    })
    playerCurrencyText:setFillColor(0.9, 0.7, 0)
    
    -- Create refresh shop button
    local refreshCost = constants.SHOP.STOCK_REFRESH_COST + (refreshCount * 10)
    local refreshButton = button.create({
        parent = mainPanel,
        x = -mainPanel.width * 0.2,
        y = mainPanel.height * 0.4,
        width = 200,
        height = 60,
        label = localization.getText("refresh_shop") .. " (" .. refreshCost .. ")",
        fontSize = 20,
        onRelease = function()
            self:refreshShop()
        end
    })
    self.refreshButton = refreshButton
    
    -- Create special deal section
    local specialDealPanel = panel.create({
        parent = mainPanel,
        x = -mainPanel.width * 0.2,
        y = -mainPanel.height * 0.35,
        width = mainPanel.width * 0.5,
        height = 120,
        cornerRadius = 8,
        fillColor = {0.3, 0.2, 0.3, 0.9}
    })
    
    -- Special deal title
    local specialDealTitle = display.newText({
        parent = specialDealPanel,
        text = localization.getText("special_deal"),
        x = 0,
        y = -40,
        font = native.systemFontBold,
        fontSize = 24
    })
    specialDealTitle:setFillColor(0.9, 0.7, 0)
    
    self.specialDealPanel = specialDealPanel
    
    -- Back button
    local backButton = button.create({
        parent = sceneGroup,
        x = 100,
        y = display.contentHeight - 80,
        width = 160,
        height = 60,
        label = localization.getText("back"),
        onRelease = function()
            -- Save shop state
            _G.shopState = {
                inventory = shopInventory,
                specialDeal = specialDealItem,
                specialDealType = specialDealType,
                refreshCount = refreshCount
            }
            composer.gotoScene("scenes.hub", { effect = "slideRight", time = 500 })
        end
    })
    
    -- Initialize shop inventory if not already loaded
    if not shopInventory then
        -- Check if we have saved shop state
        if _G.shopState then
            shopInventory = _G.shopState.inventory
            specialDealItem = _G.shopState.specialDeal
            specialDealType = _G.shopState.specialDealType
            refreshCount = _G.shopState.refreshCount
        else
            -- Generate new inventory
            self:generateShopInventory()
        end
    end
    
    -- Update the display
    self:selectCategory(selectedCategory)
    self:updateSpecialDeal()
end

function scene:selectCategory(category)
    -- Update selected category
    selectedCategory = category
    
    -- Update button appearance
    for cat, btn in pairs(self.categoryButtons) do
        btn:setFillColor(unpack(cat == category and constants.UI.COLORS.BLUE or constants.UI.COLORS.DARK_GRAY))
    end
    
    -- Clear the scrollView
    for i = scrollView.numChildren, 1, -1 do
        scrollView[i]:removeSelf()
    end
    
    -- Clear item detail
    self:clearItemDetail()
    
    -- Display items for the selected category
    self:displayCategoryItems(category)
end

function scene:displayCategoryItems(category)
    -- Get items for the category
    local items = shopInventory[category] or {}
    
    -- Create item list
    local yPos = 30
    local itemHeight = 80
    local padding = 10
    
    for i, item in ipairs(items) do
        -- Create item panel
        local itemPanel = display.newRect(
            scrollView, 
            scrollView.width/2, 
            yPos, 
            scrollView.width - 20, 
            itemHeight
        )
        itemPanel:setFillColor(0.15, 0.15, 0.2)
        itemPanel.strokeWidth = 1
        
        -- Set stroke color based on rarity
        local rarityColors = {
            common = {0.7, 0.7, 0.7},
            rare = {0.3, 0.5, 1.0},
            epic = {0.8, 0.3, 1.0}
        }
        local strokeColor = rarityColors[item.rarity] or {1, 1, 1}
        itemPanel:setStrokeColor(unpack(strokeColor))
        
        -- Item name
        local itemName = display.newText({
            parent = scrollView,
            text = item.name,
            x = padding * 2,
            y = yPos - 15,
            font = native.systemFont,
            fontSize = 18,
            align = "left",
            width = scrollView.width - 120
        })
        itemName.anchorX = 0
        
        -- Set text color based on rarity
        itemName:setFillColor(unpack(strokeColor))
        
        -- Item type/description
        local typeName = ""
        if category == "weapons" then
            typeName = localization.getText("weapon_type_" .. item.type)
        elseif category == "modules" then
            typeName = localization.getText("module_type_" .. item.type)
        elseif category == "drones" then
            typeName = localization.getText("drone_type_" .. item.type)
        elseif category == "consumables" then
            typeName = item.description or localization.getText("consumable_type_" .. item.type)
        end
        
        local itemType = display.newText({
            parent = scrollView,
            text = typeName,
            x = padding * 2,
            y = yPos + 15,
            font = native.systemFont,
            fontSize = 16,
            align = "left",
            width = scrollView.width - 120
        })
        itemType.anchorX = 0
        itemType:setFillColor(0.7, 0.7, 0.7)
        
        -- Item price
        local itemPrice = display.newText({
            parent = scrollView,
            text = item.price .. "",
            x = scrollView.width - 50,
            y = yPos,
            font = native.systemFontBold,
            fontSize = 18
        })
        itemPrice:setFillColor(0.9, 0.7, 0)
        
        -- Store reference to item
        itemPanel.item = item
        
        -- Make panel selectable
        itemPanel:addEventListener("tap", function()
            self:selectItem(item)
            return true
        end)
        
        -- Increment position for next item
        yPos = yPos + itemHeight + padding
    end
    
    -- Update scrollview content height
    scrollView:setScrollHeight(yPos + 20)
end

function scene:selectItem(item)
    -- Store selected item
    selectedItem = item
    
    -- Clear previous detail view
    self:clearItemDetail()
    
    -- Create item detail view based on category
    if selectedCategory == "weapons" then
        self:displayWeaponDetail(item)
    elseif selectedCategory == "modules" then
        self:displayModuleDetail(item)
    elseif selectedCategory == "drones" then
        self:displayDroneDetail(item)
    elseif selectedCategory == "consumables" then
        self:displayConsumableDetail(item)
    end
end

function scene:clearItemDetail()
    -- Remove all children from item detail panel
    for i = itemDetailPanel.numChildren, 1, -1 do
        itemDetailPanel[i]:removeSelf()
    end
    
    selectedItem = nil
end

function scene:displayWeaponDetail(weapon)
    -- Weapon name
    local weaponName = display.newText({
        parent = itemDetailPanel,
        text = weapon.name,
        x = 0,
        y = -itemDetailPanel.height/2 + 30,
        font = native.systemFontBold,
        fontSize = 22,
        align = "center",
        width = itemDetailPanel.width - 40
    })
    
    -- Set color based on rarity
    local rarityColors = {
        common = {0.7, 0.7, 0.7},
        rare = {0.3, 0.5, 1.0},
        epic = {0.8, 0.3, 1.0}
    }
    weaponName:setFillColor(unpack(rarityColors[weapon.rarity] or {1, 1, 1}))
    
    -- Weapon type
    local weaponType = display.newText({
        parent = itemDetailPanel,
        text = localization.getText("weapon_type_" .. weapon.type),
        x = 0,
        y = -itemDetailPanel.height/2 + 60,
        font = native.systemFont,
        fontSize = 18
    })
    weaponType:setFillColor(0.7, 0.7, 0.7)
    
    -- Weapon stats
    local statsY = -itemDetailPanel.height/2 + 100
    local statsGap = 30
    
    -- Damage
    local damageText = display.newText({
        parent = itemDetailPanel,
        text = localization.getText("damage") .. ":",
        x = -itemDetailPanel.width/2 + 30,
        y = statsY,
        font = native.systemFont,
        fontSize = 18
    })
    damageText.anchorX = 0
    damageText:setFillColor(1, 0.5, 0.5)
    
    local damageValue = display.newText({
        parent = itemDetailPanel,
        text = weapon.damage,
        x = itemDetailPanel.width/2 - 30,
        y = statsY,
        font = native.systemFontBold,
        fontSize = 18
    })
    damageValue.anchorX = 1
    damageValue:setFillColor(1, 1, 1)
    
    -- Fire rate
    statsY = statsY + statsGap
    local fireRateText = display.newText({
        parent = itemDetailPanel,
        text = localization.getText("fire_rate") .. ":",
        x = -itemDetailPanel.width/2 + 30,
        y = statsY,
        font = native.systemFont,
        fontSize = 18
    })
    fireRateText.anchorX = 0
    fireRateText:setFillColor(0.5, 0.8, 1)
    
    local fireRateValue = display.newText({
        parent = itemDetailPanel,
        text = weapon.fireRate .. " " .. localization.getText("per_second"),
        x = itemDetailPanel.width/2 - 30,
        y = statsY,
        font = native.systemFontBold,
        fontSize = 18
    })
    fireRateValue.anchorX = 1
    fireRateValue:setFillColor(1, 1, 1)
    
    -- Energy cost
    statsY = statsY + statsGap
    local energyText = display.newText({
        parent = itemDetailPanel,
        text = localization.getText("energy_cost") .. ":",
        x = -itemDetailPanel.width/2 + 30,
        y = statsY,
        font = native.systemFont,
        fontSize = 18
    })
    energyText.anchorX = 0
    energyText:setFillColor(0.3, 0.8, 0.3)
    
    local energyValue = display.newText({
        parent = itemDetailPanel,
        text = weapon.energyCost,
        x = itemDetailPanel.width/2 - 30,
        y = statsY,
        font = native.systemFontBold,
        fontSize = 18
    })
    energyValue.anchorX = 1
    energyValue:setFillColor(1, 1, 1)
    
    -- Heat generation
    statsY = statsY + statsGap
    local heatText = display.newText({
        parent = itemDetailPanel,
        text = localization.getText("heat_generation") .. ":",
        x = -itemDetailPanel.width/2 + 30,
        y = statsY,
        font = native.systemFont,
        fontSize = 18
    })
    heatText.anchorX = 0
    heatText:setFillColor(1, 0.6, 0.3)
    
    local heatValue = display.newText({
        parent = itemDetailPanel,
        text = weapon.heatGeneration,
        x = itemDetailPanel.width/2 - 30,
        y = statsY,
        font = native.systemFontBold,
        fontSize = 18
    })
    heatValue.anchorX = 1
    heatValue:setFillColor(1, 1, 1)
    
    -- Special effects (if any)
    if weapon.effect then
        statsY = statsY + statsGap
        local effectText = display.newText({
            parent = itemDetailPanel,
            text = localization.getText("special_effect") .. ":",
            x = -itemDetailPanel.width/2 + 30,
            y = statsY,
            font = native.systemFont,
            fontSize = 18
        })
        effectText.anchorX = 0
        effectText:setFillColor(0.8, 0.8, 0.2)
        
        local effectValue = display.newText({
            parent = itemDetailPanel,
            text = localization.getText("effect_" .. weapon.effect),
            x = itemDetailPanel.width/2 - 30,
            y = statsY,
            font = native.systemFontBold,
            fontSize = 18
        })
        effectValue.anchorX = 1
        effectValue:setFillColor(0.8, 0.8, 0.2)
    end
    
    -- Buy button
    local buyButton = button.create({
        parent = itemDetailPanel,
        x = 0,
        y = itemDetailPanel.height/2 - 40,
        width = 200,
        height = 60,
        label = localization.getText("buy") .. " (" .. weapon.price .. ")",
        onRelease = function()
            self:buyItem(weapon)
        end
    })
    
    -- Disable buy button if can't afford
    if not player.canAfford(weapon.price) then
        buyButton.alpha = 0.5
        buyButton:setEnabled(false)
    end
end

function scene:displayModuleDetail(module)
    -- Module name
    local moduleName = display.newText({
        parent = itemDetailPanel,
        text = module.name,
        x = 0,
        y = -itemDetailPanel.height/2 + 30,
        font = native.systemFontBold,
        fontSize = 22,
        align = "center",
        width = itemDetailPanel.width - 40
    })
    
    -- Set color based on rarity
    local rarityColors = {
        common = {0.7, 0.7, 0.7},
        rare = {0.3, 0.5, 1.0},
        epic = {0.8, 0.3, 1.0}
    }
    moduleName:setFillColor(unpack(rarityColors[module.rarity] or {1, 1, 1}))
    
    -- Module type
    local moduleType = display.newText({
        parent = itemDetailPanel,
        text = localization.getText("module_type_" .. module.type),
        x = 0,
        y = -itemDetailPanel.height/2 + 60,
        font = native.systemFont,
        fontSize = 18
    })
    moduleType:setFillColor(0.7, 0.7, 0.7)
    
    -- Module level
    local moduleLevel = display.newText({
        parent = itemDetailPanel,
        text = localization.getText("level") .. ": " .. module.level,
        x = 0,
        y = -itemDetailPanel.height/2 + 90,
        font = native.systemFontBold,
        fontSize = 18
    })
    moduleLevel:setFillColor(0.5, 0.8, 1)
    
    -- Primary stat bonus
    local statName = localization.getText("stat_" .. module.statAffected)
    local primaryStat = display.newText({
        parent = itemDetailPanel,
        text = statName .. ": +" .. module.bonus,
        x = 0,
        y = -itemDetailPanel.height/2 + 130,
        font = native.systemFont,
        fontSize = 20
    })
    primaryStat:setFillColor(0.3, 0.8, 0.3)
    
    -- Secondary stat bonus (for epic modules)
    if module.secondaryStatAffected then
        local secondaryStatName = localization.getText("stat_" .. module.secondaryStatAffected)
        local secondaryStat = display.newText({
            parent = itemDetailPanel,
            text = secondaryStatName .. ": +" .. module.secondaryBonus,
            x = 0,
            y = -itemDetailPanel.height/2 + 170,
            font = native.systemFont,
            fontSize = 20
        })
        secondaryStat:setFillColor(0.8, 0.8, 0.2)
    end
    
    -- Description based on module type
    local descriptions = {
        engine = localization.getText("module_desc_engine"),
        reactor = localization.getText("module_desc_reactor"),
        shield = localization.getText("module_desc_shield"),
        cooler = localization.getText("module_desc_cooler"),
        targeting = localization.getText("module_desc_targeting"),
        armor = localization.getText("module_desc_armor")
    }
    
    local descText = display.newText({
        parent = itemDetailPanel,
        text = descriptions[module.type] or "",
        x = 0,
        y = 0,
        width = itemDetailPanel.width - 40,
        font = native.systemFont,
        fontSize = 16,
        align = "center"
    })
    descText:setFillColor(0.7, 0.7, 0.7)
    
    -- Buy button
    local buyButton = button.create({
        parent = itemDetailPanel,
        x = 0,
        y = itemDetailPanel.height/2 - 40,
        width = 200,
        height = 60,
        label = localization.getText("buy") .. " (" .. module.price .. ")",
        onRelease = function()
            self:buyItem(module)
        end
    })
    
    -- Disable buy button if can't afford
    if not player.canAfford(module.price) then
        buyButton.alpha = 0.5
        buyButton:setEnabled(false)
    end
end

function scene:displayDroneDetail(drone)
    -- Drone name
    local droneName = display.newText({
        parent = itemDetailPanel,
        text = drone.name,
        x = 0,
        y = -itemDetailPanel.height/2 + 30,
        font = native.systemFontBold,
        fontSize = 22,
        align = "center",
        width = itemDetailPanel.width - 40
    })
    
    -- Set color based on rarity
    local rarityColors = {
        common = {0.7, 0.7, 0.7},
        rare = {0.3, 0.5, 1.0},
        epic = {0.8, 0.3, 1.0}
    }
    droneName:setFillColor(unpack(rarityColors[drone.rarity] or {1, 1, 1}))
    
    -- Drone type and level
    local droneType = display.newText({
        parent = itemDetailPanel,
        text = localization.getText("drone_type_" .. drone.type) .. " - " ..
               localization.getText("level") .. " " .. drone.level,
        x = 0,
        y = -itemDetailPanel.height/2 + 60,
        font = native.systemFont,
        fontSize = 18
    })
    droneType:setFillColor(0.7, 0.7, 0.7)
    
    -- Drone stats
    local statsY = -itemDetailPanel.height/2 + 100
    local statsGap = 30
    
    -- Health
    local healthText = display.newText({
        parent = itemDetailPanel,
        text = localization.getText("health") .. ":",
        x = -itemDetailPanel.width/2 + 30,
        y = statsY,
        font = native.systemFont,
        fontSize = 18
    })
    healthText.anchorX = 0
    healthText:setFillColor(1, 0.5, 0.5)
    
    local healthValue = display.newText({
        parent = itemDetailPanel,
        text = math.floor(drone.health),
        x = itemDetailPanel.width/2 - 30,
        y = statsY,
        font = native.systemFontBold,
        fontSize = 18
    })
    healthValue.anchorX = 1
    healthValue:setFillColor(1, 1, 1)
    
    -- Type-specific stats
    statsY = statsY + statsGap
    
    if drone.type == "combat" then
        -- Damage
        local damageText = display.newText({
            parent = itemDetailPanel,
            text = localization.getText("damage") .. ":",
            x = -itemDetailPanel.width/2 + 30,
            y = statsY,
            font = native.systemFont,
            fontSize = 18
        })
        damageText.anchorX = 0
        damageText:setFillColor(0.5, 0.8, 1)
        
        local damageValue = display.newText({
            parent = itemDetailPanel,
            text = math.floor(drone.damage),
            x = itemDetailPanel.width/2 - 30,
            y = statsY,
            font = native.systemFontBold,
            fontSize = 18
        })
        damageValue.anchorX = 1
        damageValue:setFillColor(1, 1, 1)
        
        -- Fire rate
        statsY = statsY + statsGap
        local fireRateText = display.newText({
            parent = itemDetailPanel,
            text = localization.getText("fire_rate") .. ":",
            x = -itemDetailPanel.width/2 + 30,
            y = statsY,
            font = native.systemFont,
            fontSize = 18
        })
        fireRateText.anchorX = 0
        fireRateText:setFillColor(0.3, 0.8, 0.3)
        
        local fireRateValue = display.newText({
            parent = itemDetailPanel,
            text = drone.fireRate .. " " .. localization.getText("per_second"),
            x = itemDetailPanel.width/2 - 30,
            y = statsY,
            font = native.systemFontBold,
            fontSize = 18
        })
        fireRateValue.anchorX = 1
        fireRateValue:setFillColor(1, 1, 1)
        
    elseif drone.type == "defense" then
        -- Damage reduction
        local reductionText = display.newText({
            parent = itemDetailPanel,
            text = localization.getText("damage_reduction") .. ":",
            x = -itemDetailPanel.width/2 + 30,
            y = statsY,
            font = native.systemFont,
            fontSize = 18
        })
        reductionText.anchorX = 0
        reductionText:setFillColor(0.5, 0.8, 1)
        
        local reductionValue = display.newText({
            parent = itemDetailPanel,
            text = math.floor(drone.damageReduction * 100) .. "%",
            x = itemDetailPanel.width/2 - 30,
            y = statsY,
            font = native.systemFontBold,
            fontSize = 18
        })
        reductionValue.anchorX = 1
        reductionValue:setFillColor(1, 1, 1)
        
    elseif drone.type == "support" then
        -- Heal rate
        local healRateText = display.newText({
            parent = itemDetailPanel,
            text = localization.getText("heal_rate") .. ":",
            x = -itemDetailPanel.width/2 + 30,
            y = statsY,
            font = native.systemFont,
            fontSize = 18
        })
        healRateText.anchorX = 0
        healRateText:setFillColor(0.5, 0.8, 1)
        
        local healRateValue = display.newText({
            parent = itemDetailPanel,
            text = drone.healRate .. " " .. localization.getText("per_second"),
            x = itemDetailPanel.width/2 - 30,
            y = statsY,
            font = native.systemFontBold,
            fontSize = 18
        })
        healRateValue.anchorX = 1
        healRateValue:setFillColor(1, 1, 1)
        
        -- Heal interval
        statsY = statsY + statsGap
        local healIntervalText = display.newText({
            parent = itemDetailPanel,
            text = localization.getText("heal_interval") .. ":",
            x = -itemDetailPanel.width/2 + 30,
            y = statsY,
            font = native.systemFont,
            fontSize = 18
        })
        healIntervalText.anchorX = 0
        healIntervalText:setFillColor(0.3, 0.8, 0.3)
        
        local healIntervalValue = display.newText({
            parent = itemDetailPanel,
            text = drone.healInterval .. " " .. localization.getText("seconds"),
            x = itemDetailPanel.width/2 - 30,
            y = statsY,
            font = native.systemFontBold,
            fontSize = 18
        })
        healIntervalValue.anchorX = 1
        healIntervalValue:setFillColor(1, 1, 1)
    end
    
    -- Special ability for epic drones
    if drone.rarity == "epic" then
        statsY = statsY + statsGap + 10
        local specialTitle = display.newText({
            parent = itemDetailPanel,
            text = localization.getText("special_ability") .. ":",
            x = 0,
            y = statsY,
            font = native.systemFontBold,
            fontSize = 18
        })
        specialTitle:setFillColor(0.8, 0.3, 1.0)
        
        statsY = statsY + 25
        local specialText
        
        if drone.type == "combat" and drone.specialAttack then
            specialText = localization.getText("drone_special_" .. drone.specialAttack)
        elseif drone.type == "defense" and drone.reflectChance then
            specialText = localization.getText("drone_special_reflect") .. " (" .. 
                         math.floor(drone.reflectChance * 100) .. "%)"
        elseif drone.type == "support" and drone.bonusType then
            specialText = localization.getText("drone_special_bonus") .. " " ..
                         localization.getText("stat_" .. drone.bonusType)
        else
            specialText = localization.getText("drone_special_generic")
        end
        
        local specialDesc = display.newText({
            parent = itemDetailPanel,
            text = specialText,
            x = 0,
            y = statsY,
            width = itemDetailPanel.width - 40,
            font = native.systemFont,
            fontSize = 16,
            align = "center"
        })
        specialDesc:setFillColor(0.8, 0.8, 0.2)
    end
    
    -- Buy button
    local buyButton = button.create({
        parent = itemDetailPanel,
        x = 0,
        y = itemDetailPanel.height/2 - 40,
        width = 200,
        height = 60,
        label = localization.getText("buy") .. " (" .. drone.price .. ")",
        onRelease = function()
            self:buyItem(drone)
        end
    })
    
    -- Disable buy button if can't afford
    if not player.canAfford(drone.price) then
        buyButton.alpha = 0.5
        buyButton:setEnabled(false)
    end
end

function scene:displayConsumableDetail(consumable)
    -- Consumable name
    local consumableName = display.newText({
        parent = itemDetailPanel,
        text = consumable.name,
        x = 0,
        y = -itemDetailPanel.height/2 + 30,
        font = native.systemFontBold,
        fontSize = 22,
        align = "center",
        width = itemDetailPanel.width - 40
    })
    consumableName:setFillColor(1, 1, 1)
    
    -- Consumable icon (using a colored shape as placeholder)
    local iconColors = {
        health = {1, 0.3, 0.3},
        shield = {0.3, 0.5, 1.0},
        energy = {0.3, 0.8, 0.3},
        bomb = {1, 0.5, 0},
        emp = {0.8, 0.3, 1.0},
        support = {0.8, 0.8, 0.2},
        fuel = {0.7, 0.7, 0.7}
    }
    
    local iconColor = iconColors[consumable.type] or {1, 1, 1}
    local icon
    
    if consumable.type == "health" or consumable.type == "energy" or consumable.type == "shield" then
        icon = display.newCircle(itemDetailPanel, 0, -itemDetailPanel.height/2 + 90, 30)
    elseif consumable.type == "bomb" then
        icon = display.newPolygon(itemDetailPanel, 0, -itemDetailPanel.height/2 + 90, 
            {0,-30, 20,-10, 30,0, 20,20, 0,30, -20,20, -30,0, -20,-10})
    elseif consumable.type == "emp" then
        icon = display.newCircle(itemDetailPanel, 0, -itemDetailPanel.height/2 + 90, 30)
        local ring = display.newCircle(itemDetailPanel, 0, -itemDetailPanel.height/2 + 90, 40)
        ring:setFillColor(0, 0, 0, 0)
        ring:setStrokeColor(unpack(iconColor))
        ring.strokeWidth = 3
    elseif consumable.type == "support" then
        icon = display.newRect(itemDetailPanel, 0, -itemDetailPanel.height/2 + 90, 50, 30)
    elseif consumable.type == "fuel" then
        icon = display.newRoundedRect(itemDetailPanel, 0, -itemDetailPanel.height/2 + 90, 40, 50, 8)
    end
    
    if icon then
        icon:setFillColor(unpack(iconColor))
    end
    
    -- Description
    local descText = display.newText({
        parent = itemDetailPanel,
        text = consumable.description,
        x = 0,
        y = -itemDetailPanel.height/2 + 150,
        width = itemDetailPanel.width - 40,
        font = native.systemFont,
        fontSize = 18,
        align = "center"
    })
    descText:setFillColor(0.7, 0.7, 0.7)
    
    -- Usage instructions
    local usageText = display.newText({
        parent = itemDetailPanel,
        text = localization.getText("consumable_usage_" .. consumable.type) or 
               localization.getText("consumable_usage_generic"),
        x = 0,
        y = 0,
        width = itemDetailPanel.width - 40,
        font = native.systemFont,
        fontSize = 16,
        align = "center"
    })
    usageText:setFillColor(0.6, 0.6, 0.6)
    
    -- Buy button
    local buyButton = button.create({
        parent = itemDetailPanel,
        x = 0,
        y = itemDetailPanel.height/2 - 40,
        width = 200,
        height = 60,
        label = localization.getText("buy") .. " (" .. consumable.price .. ")",
        onRelease = function()
            self:buyItem(consumable)
        end
    })
    
    -- Disable buy button if can't afford
    if not player.canAfford(consumable.price) then
        buyButton.alpha = 0.5
        buyButton:setEnabled(false)
    end
end


function scene:buyItem(item)
    -- Check if player can afford
    if not player.canAfford(item.price) then
        -- Display not enough fragments message
        local notEnoughText = display.newText({
            parent = self.view,
            text = localization.getText("not_enough_fragments"),
            x = display.contentCenterX,
            y = display.contentHeight * 0.7,
            font = native.systemFontBold,
            fontSize = 24
        })
        notEnoughText:setFillColor(1, 0.3, 0.3)
        
        transition.to(notEnoughText, {
            alpha = 0,
            time = 2000,
            onComplete = function() display.remove(notEnoughText) end
        })
        
        return false
    end

    -- Determine item type from selected category
    local itemType = selectedCategory
    
    -- Spend currency
    player.spendFragments(item.price)
    
    -- Add item to player inventory
    player.addToInventory(itemType, item)
    
    -- Remove item from shop inventory
    for i, shopItem in ipairs(shopInventory[itemType]) do
        if shopItem.id == item.id then
            table.remove(shopInventory[itemType], i)
            break
        end
    end
    
    -- Check if special deal was bought
    if specialDealItem and specialDealItem.id == item.id then
        specialDealItem = nil
        specialDealType = nil
        self:updateSpecialDeal()
    end
    
    -- Update currency display
    playerCurrencyText.text = localization.getText("tech_fragments") .. ": " .. _G.playerData.techFragments
    
    -- Update the display
    self:selectCategory(selectedCategory)
    
    -- Save game
    saveManager.saveGame(_G.playerData)
    
    -- Show purchase confirmation
    local confirmText = display.newText({
        parent = self.view,
        text = localization.getText("purchase_complete"),
        x = display.contentCenterX,
        y = display.contentHeight * 0.7,
        font = native.systemFontBold,
        fontSize = 24
    })
    confirmText:setFillColor(0.2, 0.8, 0.2)
    
    transition.to(confirmText, {
        alpha = 0,
        time = 2000,
        onComplete = function() display.remove(confirmText) end
    })
    
    return true
end

function scene:updateSpecialDeal()
    -- Clear previous special deal
    for i = self.specialDealPanel.numChildren, 1, -1 do
        if i > 1 then -- Keep the title
            self.specialDealPanel[i]:removeSelf()
        end
    end
    
    -- If no special deal, create one
    if not specialDealItem then
        specialDealItem, specialDealType = shopGenerator.generateSpecialDeal(_G.playerData.level)
    end
    
    if specialDealItem then
        -- Item name
        local itemName = display.newText({
            parent = self.specialDealPanel,
            text = specialDealItem.name,
            x = 0,
            y = -10,
            font = native.systemFontBold,
            fontSize = 18,
            align = "center",
            width = self.specialDealPanel.width - 40
        })
        
        -- Set color based on rarity
        local rarityColors = {
            common = {0.7, 0.7, 0.7},
            rare = {0.3, 0.5, 1.0},
            epic = {0.8, 0.3, 1.0}
        }
        itemName:setFillColor(unpack(rarityColors[specialDealItem.rarity] or {1, 1, 1}))
        
        -- Price with discount indicator
        local priceText = display.newText({
            parent = self.specialDealPanel,
            text = specialDealItem.price .. " " .. localization.getText("fragments") .. " (20% " .. localization.getText("discount") .. ")",
            x = 0,
            y = 15,
            font = native.systemFont,
            fontSize = 16
        })
        priceText:setFillColor(0.9, 0.7, 0)
        
        -- View details button
        local viewButton = button.create({
            parent = self.specialDealPanel,
            x = 0,
            y = 40,
            width = 180,
            height = 40,
            label = localization.getText("view_details"),
            fontSize = 16,
            onRelease = function()
                -- Switch to appropriate category and select this item
                self:selectCategory(specialDealType .. "s")
                self:selectItem(specialDealItem)
            end
        })
    else
        -- No special deal available
        local noSpecialText = display.newText({
            parent = self.specialDealPanel,
            text = localization.getText("no_special_deals"),
            x = 0,
            y = 0,
            font = native.systemFont,
            fontSize = 18,
            align = "center"
        })
        noSpecialText:setFillColor(0.7, 0.7, 0.7)
    end
end


function scene:refreshShop()
    -- Check if player can afford to refresh
    local refreshCost = constants.SHOP.STOCK_REFRESH_COST + (refreshCount * 10)
    
    if not player.canAfford(refreshCost) then
        -- Display not enough fragments message
        local notEnoughText = display.newText({
            parent = self.view,
            text = localization.getText("not_enough_fragments"),
            x = display.contentCenterX,
            y = display.contentHeight * 0.7,
            font = native.systemFontBold,
            fontSize = 24
        })
        notEnoughText:setFillColor(1, 0.3, 0.3)
        
        transition.to(notEnoughText, {
            alpha = 0,
            time = 2000,
            onComplete = function() display.remove(notEnoughText) end
        })
        
        return false
    end
    
    -- Spend currency
    player.spendFragments(refreshCost)
    
    -- Update currency display
    playerCurrencyText.text = localization.getText("tech_fragments") .. ": " .. _G.playerData.techFragments
    
    -- Increment refresh count
    refreshCount = refreshCount + 1
    
    -- Update refresh button text
    local newRefreshCost = constants.SHOP.STOCK_REFRESH_COST + (refreshCount * 10)
    self.refreshButton.label.text = localization.getText("refresh_shop") .. " (" .. newRefreshCost .. ")"
    
    -- Generate new inventory
    self:generateShopInventory()
    
    -- Update the display
    self:selectCategory(selectedCategory)
    self:updateSpecialDeal()
    
    -- Save game
    saveManager.saveGame(_G.playerData)
    
    return true
end -- Убедитесь, что здесь есть закрывающий end

function scene:generateShopInventory()
    -- Generate preferences based on player's level and equipment
    local preferences = {}
    
    -- Base inventory generation on player level
    local playerLevel = _G.playerData.level
    
    -- Generate inventory
    shopInventory = shopGenerator.generateShopInventory(playerLevel, preferences)
    
    -- Generate special deal
    specialDealItem, specialDealType = shopGenerator.generateSpecialDeal(playerLevel)
    
    -- Add special deal to appropriate category
    if specialDealItem and specialDealType then
        local category = specialDealType .. "s"
        if shopInventory[category] then
            table.insert(shopInventory[category], specialDealItem)
        end
    end
end -- Убедитесь, что здесь есть закрывающий end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase
    
    if phase == "will" then
        -- Called when the scene is about to come on screen
    elseif phase == "did" then
        -- Called when the scene is now on screen
        -- Update the player currency display
        playerCurrencyText.text = localization.getText("tech_fragments") .. ": " .. (_G.playerData.techFragments or 0)
    end
end

function scene:hide(event)
    local sceneGroup = self.view
    local phase = event.phase
    
    if phase == "will" then
        -- Called when the scene is about to go off screen
        -- Save shop state
        _G.shopState = {
            inventory = shopInventory,
            specialDeal = specialDealItem,
            specialDealType = specialDealType,
            refreshCount = refreshCount
        }
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
