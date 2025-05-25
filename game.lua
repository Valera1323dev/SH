-----------------------------------------------------------------------------------------
-- Game Scene - Main gameplay scene Игровая сцена - Основная сцена геймплея
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()
local physics = require("physics")
local widget = require("widget")

-- Import game modules
local player = require("gamelogic.player")
local enemies = require("gamelogic.enemies")
local weapons = require("gamelogic.weapons")
local drones = require("gamelogic.drones")
local progression = require("gamelogic.progression")
local saveManager = require("utils.save_manager")
local constants = require("gamelogic.constants")
local localization = require("utils.localization")
local utils = require("utils.utils")

-- Set up physics
physics.start()
physics.setGravity(0, 0)
physics.setScale(60)
-- physics.setDrawMode("hybrid") -- Раскомментируйте для отладки

-- Локальные переменные
local gameGroup
local uiGroup
local playerShip
local playerDrones = {}
local enemyList = {}
local bulletList = {}
local particleList = {}
local gameTimer
local spawnTimer
local missionTimer
local missionTime = 0
local missionComplete = false
local missionFailed = false
local missionType
local missionDifficulty
local escortObject
local defenseObject
local bossEnemy
local score = 0
local kills = 0
local currentWave = 0
local totalWaves = 0
local lastFireTime = 0
local autoFireActive = false
local pauseButton
local controls = {}
local statusBars = {}
local pauseOverlay
local gameActive = false
local missionTimeLimit = 0
local missionTimePassed = 0
local gameLoopTimer

-- Game parameters
local PLAYER_SPEED = 12
local ENEMY_BASE_SPAWN_RATE = 1500 -- milliseconds
local MAX_ENEMIES_ON_SCREEN = 30
local AUTO_FIRE_DELAY = 200 -- milliseconds
-- Исправленный модуль создания игрока
-- Добавьте в начало файла после локальных переменных
local function onCollision(event)
    if event.phase == "began" then
        local obj1 = event.object1
        local obj2 = event.object2
        
        -- Проверяем валидность объектов
        if not obj1 or not obj2 or not obj1.objectType or not obj2.objectType then
            return
        end
        
        print("Collision detected:", obj1.objectType, "vs", obj2.objectType)
        
        -- Пуля игрока попадает во врага
        if (obj1.objectType == "playerBullet" and obj2.objectType == "enemy") then
            CollisionManager.handleBulletHit(obj1, obj2)
            
        elseif (obj2.objectType == "playerBullet" and obj1.objectType == "enemy") then
            CollisionManager.handleBulletHit(obj2, obj1)
            
        -- Пуля врага попадает в игрока
        elseif (obj1.objectType == "enemyBullet" and obj2.objectType == "player") then
            CollisionManager.handleBulletHit(obj1, obj2)
            
        elseif (obj2.objectType == "enemyBullet" and obj1.objectType == "player") then
            CollisionManager.handleBulletHit(obj2, obj1)
            
        -- Игрок сталкивается с врагом
        elseif (obj1.objectType == "player" and obj2.objectType == "enemy") then
            CollisionManager.handlePlayerEnemyContact(obj1, obj2)
            
        elseif (obj2.objectType == "player" and obj1.objectType == "enemy") then
            CollisionManager.handlePlayerEnemyContact(obj2, obj1)
        end
    elseif event.phase == "ended" then
        local obj1 = event.object1
        local obj2 = event.object2
        
        if not obj1 or not obj2 or not obj1.objectType or not obj2.objectType then
            return
        end
        
        -- Завершение контакта игрока с врагом
        if (obj1.objectType == "player" and obj2.objectType == "enemy") then
            CollisionManager.endPlayerEnemyContact(obj1, obj2)
        elseif (obj2.objectType == "player" and obj1.objectType == "enemy") then
            CollisionManager.endPlayerEnemyContact(obj2, obj1)
        end
    end
end

function scene:create(event)
    local sceneGroup = self.view
    
    -- Pause physics engine until needed
    physics.pause()
    
    -- Initialize groups
    gameGroup = display.newGroup()
    sceneGroup:insert(gameGroup)
    
    uiGroup = display.newGroup()
    sceneGroup:insert(uiGroup)
    
    -- Create starfield background
    local background = display.newRect(gameGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    background:setFillColor(0.05, 0.05, 0.1)
    
    -- Add some stars in the background
    for i = 1, 50 do
        local star = display.newCircle(gameGroup, math.random(display.contentWidth), math.random(display.contentHeight), math.random(1, 3))
        star:setFillColor(1, 1, 1, math.random(0.5, 0.9))
        
        -- Make stars slowly move down to create scrolling effect
        local function moveStars()
            transition.to(star, {
                y = star.y + display.contentHeight,
                time = math.random(20000, 40000),
                onComplete = function()
                    star.y = -10
                    moveStars()
                end
            })
        end
        moveStars()
    end
    
    -- Create UI elements
    self:createUI()
end

function scene:createUI()
    -- Top panel background
    local topPanel = display.newRect(uiGroup, display.contentCenterX, 50, display.contentWidth, 100)
    topPanel:setFillColor(0.1, 0.1, 0.15, 0.8)
    
    -- Status bars
    -- Health bar
    statusBars.health = self:createStatusBar(display.contentWidth * 0.25, 50, 0.9, 0.3, 0.3)
    statusBars.healthText = display.newText({
        parent = uiGroup,
        text = localization.getText("health"),
        x = 50,
        y = 50,
        font = native.systemFont,
        fontSize = 20
    })
    statusBars.healthText:setFillColor(1)
    statusBars.healthText.anchorX = 0
    
    -- Shield bar
    statusBars.shield = self:createStatusBar(display.contentWidth * 0.6, 50, 0.3, 0.6, 0.9)
    statusBars.shieldText = display.newText({
        parent = uiGroup,
        text = localization.getText("shields"),
        x = display.contentWidth * 0.4,
        y = 50,
        font = native.systemFont,
        fontSize = 20
    })
    statusBars.shieldText:setFillColor(1)
    statusBars.shieldText.anchorX = 0
    
    -- Energy bar
    statusBars.energy = self:createStatusBar(display.contentWidth * 0.25, 80, 0.3, 0.8, 0.4)
    statusBars.energyText = display.newText({
        parent = uiGroup,
        text = localization.getText("energy"),
        x = 50,
        y = 80,
        font = native.systemFont,
        fontSize = 20
    })
    statusBars.energyText:setFillColor(1)
    statusBars.energyText.anchorX = 0
    
    -- Heat bar
    statusBars.heat = self:createStatusBar(display.contentWidth * 0.6, 80, 0.9, 0.4, 0.3)
    statusBars.heatText = display.newText({
        parent = uiGroup,
        text = localization.getText("heat"),
        x = display.contentWidth * 0.4,
        y = 80,
        font = native.systemFont,
        fontSize = 20
    })
    statusBars.heatText:setFillColor(1)
    statusBars.heatText.anchorX = 0
    
    -- Pause button
    pauseButton = widget.newButton({
        x = display.contentWidth - 50,
        y = 50,
        width = 60,
        height = 60,
        label = "II",
        fontSize = 24,
        onRelease = function()
            self:pauseGame()
        end
    })
    uiGroup:insert(pauseButton)
    
    -- Mission info
    local missionInfoBg = display.newRect(uiGroup, display.contentCenterX, 130, 250, 40)
    missionInfoBg:setFillColor(0.1, 0.1, 0.15, 0.7)
    missionInfoBg.alpha = 0.7
    
    statusBars.missionInfo = display.newText({
        parent = uiGroup,
        text = "",
        x = display.contentCenterX,
        y = 130,
        font = native.systemFont,
        fontSize = 18
    })
    statusBars.missionInfo:setFillColor(1)
    
    -- Bottom panel for controls
    local bottomPanel = display.newRect(uiGroup, display.contentCenterX, display.contentHeight - 100, display.contentWidth, 200)
    bottomPanel:setFillColor(0.1, 0.1, 0.15, 0.7)
    
    -- Fire buttons
    controls.manualFireBtn = widget.newButton({
        x = display.contentWidth * 0.25,
        y = display.contentHeight - 100,
        width = 150,
        height = 150,
        label = localization.getText("manual_fire"),
        fontSize = 22,
        onPress = function()
            self:fireWeapon(false)
        end,
        onRelease = function()
            -- Stop continuous fire on release
            controls.manualFirePressed = false
        end
    })
    uiGroup:insert(controls.manualFireBtn)
    
    controls.autoFireBtn = widget.newButton({
        x = display.contentWidth * 0.75,
        y = display.contentHeight - 100,
        width = 150,
        height = 150,
        label = localization.getText("auto_fire"),
        fontSize = 22,
        onPress = function()
            autoFireActive = not autoFireActive
            controls.autoFireBtn:setLabel(autoFireActive and localization.getText("auto_on") or localization.getText("auto_fire"))
        end
    })
    uiGroup:insert(controls.autoFireBtn)
    
    -- Current weapon indicator
    controls.weaponIndicator = display.newText({
        parent = uiGroup,
        text = "Basic Laser",
        x = display.contentCenterX,
        y = display.contentHeight - 180,
        font = native.systemFontBold,
        fontSize = 22
    })
    controls.weaponIndicator:setFillColor(0.3, 0.9, 0.3)
end

function scene:createStatusBar(x, y, r, g, b)
    local barGroup = display.newGroup()
    uiGroup:insert(barGroup)
    
    local barWidth = display.contentWidth * 0.3
    local barHeight = 20
    
    -- Background
    local barBg = display.newRect(barGroup, x, y, barWidth, barHeight)
    barBg:setFillColor(0.2, 0.2, 0.2)
    barBg.anchorX = 0
    
    -- Foreground (progress)
    local barFg = display.newRect(barGroup, x, y, barWidth, barHeight)
    barFg:setFillColor(r, g, b)
    barFg.anchorX = 0
    
    -- Store original width for calculations
    barFg.originalWidth = barWidth
    
    return barFg
end

function scene:updateStatusBar(bar, value, maxValue)
    local percentage = value / maxValue
    percentage = math.max(0, math.min(1, percentage))
    bar.width = bar.originalWidth * percentage
end


--------------
function scene:createPlayer()
    -- Устанавливаем имя для gameGroup
    gameGroup.name = "gameGroup"
    
    -- Create player ship
    playerShip = display.newPolygon(gameGroup, display.contentCenterX, display.contentHeight - 200, { 0,-30, -20,30, 0,15, 20,30 })
    playerShip:setFillColor(0.2, 0.8, 0.2)
    
    -- Set up physics for player
    physics.addBody(playerShip, "dynamic", { radius=25, isSensor=true })
    playerShip.isFixedRotation = true
    playerShip.gravityScale = 0
    
    -- ВАЖНО: устанавливаем тип объекта
    playerShip.objectType = "player"
    playerShip.isPlayer = true
    playerShip.health = _G.playerData.stats.health
    playerShip.maxHealth = _G.playerData.stats.health
    playerShip.shields = _G.playerData.stats.shields
    playerShip.maxShields = _G.playerData.stats.shields
    playerShip.energy = _G.playerData.stats.energy
    playerShip.maxEnergy = _G.playerData.stats.energy
    playerShip.heat = 0
    playerShip.maxHeat = _G.playerData.stats.heatCapacity
    playerShip.energyRegen = _G.playerData.stats.energyRegen
    playerShip.coolingRate = _G.playerData.stats.coolingRate
    playerShip.shieldRegen = _G.playerData.stats.shieldRegen
    
    -- Флаг инициализации
    playerShip.isInitialized = false
    
    -- Список активных контактов с врагами
    playerShip.enemyContacts = {}
    
    -- УБИРАЕМ обработчик коллизий - теперь используем глобальный
    -- playerShip.collision = ... -- УДАЛИТЕ ЭТУ ФУНКЦИЮ
    
    -- Add damage handling function
    playerShip.takeDamage = function(self, amount)
        if not amount or amount <= 0 then return end
        
        print("Player taking damage:", amount)
        
        -- Урон сначала по щитам
        if self.shields > 0 then
            local shieldDamage = math.min(amount, self.shields)
            self.shields = self.shields - shieldDamage
            amount = amount - shieldDamage
            
            -- Эффект попадания по щиту
            local shieldEffect = display.newCircle(gameGroup, self.x, self.y, 40)
            shieldEffect:setFillColor(0.3, 0.6, 1, 0.5)
            transition.to(shieldEffect, {
                time = 300,
                alpha = 0,
                xScale = 1.5,
                yScale = 1.5,
                onComplete = function() display.remove(shieldEffect) end
            })
        end
        
        -- Оставшийся урон по здоровью
        if amount > 0 then
            self.health = math.max(0, self.health - amount)
            
            if self.health <= 0 and not missionFailed then
                self:destroy()
            end
        end
        
        -- Обновляем UI
        scene:updateStatusBar(statusBars.health, self.health, self.maxHealth)
        scene:updateStatusBar(statusBars.shield, self.shields, self.maxShields)
    end
    
    -- Add destroy function
    playerShip.destroy = function(self)
        scene:createExplosion(self.x, self.y, 20, 0.2, 0.8, 0.2)
        
        missionFailed = true
        gameActive = false
        
        timer.performWithDelay(2000, function()
            scene:showMissionComplete(false)
        end)
    end
    
    -- НЕ ДОБАВЛЯЕМ обработчик коллизий
    -- playerShip:addEventListener("collision") -- УДАЛИТЕ ЭТУ СТРОКУ
    
    -- Инициализация через задержку
    timer.performWithDelay(100, function()
        if playerShip then
            playerShip.isInitialized = true
            print("Debug - Player fully initialized")
        end
    end)
    
    -- Остальной код...
    self:createDrones()
    self:updateStatusBar(statusBars.health, playerShip.health, playerShip.maxHealth)
    self:updateStatusBar(statusBars.shield, playerShip.shields, playerShip.maxShields)
    self:updateStatusBar(statusBars.energy, playerShip.energy, playerShip.maxEnergy)
    self:updateStatusBar(statusBars.heat, playerShip.heat, playerShip.maxHeat)
end
--------------
function scene:createDrones()
    -- Clear any existing drones
    for i = #playerDrones, 1, -1 do
        display.remove(playerDrones[i])
        table.remove(playerDrones, i)
    end
    
    -- Create new drones based on equipped drones
    for i, droneData in ipairs(_G.playerData.equippedDrones) do
        local drone = display.newCircle(gameGroup, playerShip.x + (i % 2 == 0 and 30 or -30), playerShip.y - 20, 10)
        drone:setFillColor(0.2, 0.8, 0.2) -- Green drone
        
        -- Add physics
        physics.addBody(drone, "dynamic", { radius=10, isSensor=true })
        drone.isFixedRotation = true
        drone.isDrone = true
        drone.droneType = droneData.type
        drone.health = droneData.health or 30
        drone.damage = droneData.damage or 5
        
        -- Behavior based on drone type
        if droneData.type == "combat" then
            drone.fireRate = droneData.fireRate or 1.5 -- shots per second
            drone.lastFireTime = 0
        elseif droneData.type == "defense" then
            -- Defense drones fly in front of the ship
            drone.offsetY = -50
            drone.offsetX = (i % 2 == 0) and 20 or -20
        elseif droneData.type == "support" then
            drone.healRate = droneData.healRate or 0.5
            drone.lastHealTime = 0
        end
        
        table.insert(playerDrones, drone)
    end
end

function scene:fireWeapon(isAutoFire)
    local currentTime = system.getTimer()
    
    -- Получаем данные оружия
    local weaponData
    for _, weapon in ipairs(_G.playerData.inventory.weapons) do
        if weapon.id == _G.playerData.equippedWeapons.primary then
            weaponData = weapon
            break
        end
    end
    
    if not weaponData then
        weaponData = {
            id = "basic_laser",
            type = "laser",
            damage = 10,
            fireRate = 0.2,
            energyCost = 5,
            heatGeneration = 5
        }
    end
    
    local typeMultiplier = _G.playerData.weaponStats[weaponData.type] or 1
    local adjustedDamage = weaponData.damage * typeMultiplier
    local fireRateCooldown = 1000 / (weaponData.fireRate * 5)
    
    -- Проверки на возможность стрельбы
    if currentTime - lastFireTime < fireRateCooldown or
       playerShip.energy < weaponData.energyCost or
       playerShip.heat >= playerShip.maxHeat then
        return false
    end
    
    -- Тратим энергию и генерируем тепло
    playerShip.energy = math.max(0, playerShip.energy - weaponData.energyCost)
    playerShip.heat = math.min(playerShip.maxHeat, playerShip.heat + weaponData.heatGeneration)
    
    self:updateStatusBar(statusBars.energy, playerShip.energy, playerShip.maxEnergy)
    self:updateStatusBar(statusBars.heat, playerShip.heat, playerShip.maxHeat)
    
    lastFireTime = currentTime
    
    -- Создаем пулю
    local bullet = self:createBullet(weaponData, adjustedDamage)
    
    return true
end

function scene:createBullet(weaponData, damage)
    local bullet
    
    if weaponData.type == "laser" then
        bullet = display.newRect(gameGroup, playerShip.x, playerShip.y - 30, 4, 20)
        bullet:setFillColor(0, 1, 0)
        physics.addBody(bullet, "dynamic", { width=4, height=20, isSensor=true })
        bullet:setLinearVelocity(0, -800)
        
    elseif weaponData.type == "plasma" then
        bullet = display.newCircle(gameGroup, playerShip.x, playerShip.y - 30, 10)
        bullet:setFillColor(0.5, 0.8, 1)
        physics.addBody(bullet, "dynamic", { radius=10, isSensor=true })
        bullet:setLinearVelocity(0, -600)
        
    elseif weaponData.type == "missile" then
        bullet = display.newRect(gameGroup, playerShip.x, playerShip.y - 30, 6, 15)
        bullet:setFillColor(1, 0.5, 0)
        physics.addBody(bullet, "dynamic", { width=6, height=15, isSensor=true })
        bullet.isMissile = true
        bullet:setLinearVelocity(0, -500)
        
    elseif weaponData.type == "railgun" then
        bullet = display.newRect(gameGroup, playerShip.x, playerShip.y - 30, 3, 40)
        bullet:setFillColor(0.8, 0.8, 1)
        physics.addBody(bullet, "dynamic", { width=3, height=40, isSensor=true })
        bullet.isPiercing = true
        bullet:setLinearVelocity(0, -1200)
    end
    
    bullet.gravityScale = 0
    bullet.isFixedRotation = true
    bullet.isBullet = true
    
    -- ВАЖНО: устанавливаем тип объекта
    bullet.objectType = "playerBullet"
    bullet.isPlayerBullet = true
    bullet.damage = damage
    
    -- НЕ ДОБАВЛЯЕМ обработчик коллизий - используем глобальный
    -- bullet.collision = ... -- УДАЛИТЕ ЭТУ ФУНКЦИЮ
    -- bullet:addEventListener("collision") -- УДАЛИТЕ ЭТУ СТРОКУ
    
    table.insert(bulletList, bullet)
    
    -- Удаление пули через время
    timer.performWithDelay(3000, function()
        if bullet and bullet.removeSelf then
            for i = #bulletList, 1, -1 do
                if bulletList[i] == bullet then
                    table.remove(bulletList, i)
                    break
                end
            end
            bullet:removeSelf()
        end
    end)
    
    return bullet
end


function scene:createImpact(x, y)
    local impact = display.newCircle(gameGroup, x, y, 5)
    impact:setFillColor(1, 1, 1, 0.8)
    
    transition.to(impact, {
        time = 200,
        alpha = 0,
        xScale = 2,
        yScale = 2,
        onComplete = function()
            display.remove(impact)
        end
    })
end

---------------
function scene:createExplosion(x, y, particleCount, r, g, b)
    -- Установка значений по умолчанию
    particleCount = particleCount or 10
    r = r or 1
    g = g or 0.5
    b = b or 0
    
    -- Инициализация списка частиц если его нет
    if not particleList then
        particleList = {}
    end
    
    for i = 1, particleCount do
        local particle = display.newCircle(gameGroup, x, y, math.random(2, 5))
        particle:setFillColor(r, g, b)
        
        local angle = math.random() * math.pi * 2
        local speed = math.random(100, 300)
        local vx = math.cos(angle) * speed * 0.001
        local vy = math.sin(angle) * speed * 0.001
        
        -- Используем только transition анимацию без физики
        transition.to(particle, {
            time = math.random(300, 800),
            x = x + vx,
            y = y + vy,
            alpha = 0,
            xScale = 0.1,
            yScale = 0.1,
            onComplete = function()
                display.remove(particle)
                -- Удаляем из списка
                for j = #particleList, 1, -1 do
                    if particleList[j] == particle then
                        table.remove(particleList, j)
                        break
                    end
                end
            end
        })
        
        table.insert(particleList, particle)
    end
end

------------------

function scene:spawnEnemies()
    -- Debug info
    print("Debug - spawnEnemies called, gameActive:", gameActive, "missionComplete:", missionComplete)
    
    -- Don't spawn if mission is over
    if missionComplete or missionFailed or not gameActive then
        print("Debug - Not spawning: mission over or game inactive")
        return
    end
    
    -- Limit number of enemies
    if #enemyList >= MAX_ENEMIES_ON_SCREEN then
        print("Debug - Not spawning: too many enemies on screen:", #enemyList)
        -- Попробуем снова через короткое время
        timer.performWithDelay(500, function() 
            if scene and scene.spawnEnemies then
                scene:spawnEnemies() 
            end
        end)
        return
    end
    
    -- ИСПРАВЛЕНИЕ: Убеждаемся что difficulty это число
    local difficulty = missionDifficulty or 2
    if type(difficulty) ~= "number" then
        print("Debug - ERROR: difficulty is not a number:", difficulty, type(difficulty))
        difficulty = 2
    end
    
    print("Debug - Using difficulty:", difficulty, "type:", type(difficulty))
    
    -- Determine spawn rate based on difficulty
    local spawnRateMultiplier = 1 / difficulty
    local spawnRate = ENEMY_BASE_SPAWN_RATE * spawnRateMultiplier
    
    print("Debug - Spawn rate:", spawnRate, "multiplier:", spawnRateMultiplier)
    
    -- Schedule next spawn
    if spawnTimer then
        timer.cancel(spawnTimer)
    end
    spawnTimer = timer.performWithDelay(spawnRate, function() 
        if scene and scene.spawnEnemies then
            scene:spawnEnemies() 
        end
    end)
    
    -- Determine enemy type to spawn
    local enemyTypes = {"light", "medium", "heavy"}
    local weights = {70, 25, 5}  -- Probability weights
    
    -- Adjust weights based on mission time
    if missionTimePassed > 180 then  -- After 3 minutes
        weights = {20, 50, 30}
    elseif missionTimePassed > 120 then  -- After 2 minutes
        weights = {30, 50, 20}
    elseif missionTimePassed > 60 then  -- After 1 minute
        weights = {50, 40, 10}
    end
    
    -- Adjust weights based on difficulty
    if difficulty >= 3 then
        for i = 1, #weights do
            weights[i] = weights[i] * (1 + (difficulty - 2) * 0.2)
        end
    end
    
    -- Choose enemy type
    local enemyType = utils.weightedRandom(enemyTypes, weights)
    
    print("Debug - Spawning enemy type:", enemyType)
    
    -- Create enemy based on type
    local enemyX = math.random(50, display.contentWidth - 50)
    local enemyY = -50  -- Spawn above the screen
    
    local enemy
    
    if enemyType == "light" then
        -- Light enemy: small, fast triangle
        enemy = display.newPolygon(gameGroup, enemyX, enemyY, {0,-15, -15,15, 15,15})
        enemy:setFillColor(1, 0.3, 0.3)  -- Red
        physics.addBody(enemy, "dynamic", { radius=15, isSensor=true })
        enemy.health = 20 * difficulty
        enemy.damage = 5 * difficulty
        enemy.speed = 150 + (difficulty * 20)
        enemy.fireRate = 2  -- shots per second
        enemy.scoreValue = 10
        
    elseif enemyType == "medium" then
        -- Medium enemy: medium square
        enemy = display.newRect(gameGroup, enemyX, enemyY, 40, 40)
        enemy:setFillColor(1, 0.4, 0.4)  -- Red
        physics.addBody(enemy, "dynamic", { box={width=40, height=40}, isSensor=true })
        enemy.health = 40 * difficulty
        enemy.damage = 10 * difficulty
        enemy.speed = 100 + (difficulty * 10)
        enemy.fireRate = 1.5  -- shots per second
        enemy.scoreValue = 25
        
    elseif enemyType == "heavy" then
        -- Heavy enemy: large hexagon
        local vertices = {}
        for i = 0, 5 do
            local angle = math.rad(i * 60)
            table.insert(vertices, 30 * math.cos(angle))
            table.insert(vertices, 30 * math.sin(angle))
        end
        enemy = display.newPolygon(gameGroup, enemyX, enemyY, vertices)
        enemy:setFillColor(1, 0.5, 0.5)  -- Red
        physics.addBody(enemy, "dynamic", { radius=30, isSensor=true })
        enemy.health = 80 * difficulty
        enemy.damage = 15 * difficulty
        enemy.speed = 70 + (difficulty * 5)
        enemy.fireRate = 1  -- shots per second
        enemy.scoreValue = 50
    end
    
    -- Set up common enemy properties
    enemy.objectType = "enemy"
    enemy.isEnemy = true
    enemy.lastFireTime = system.getTimer()
    enemy.enemyType = enemyType
    enemy.maxHealth = enemy.health
    
    print("Debug - Created enemy with health:", enemy.health, "damage:", enemy.damage)
    
    -- Movement pattern based on enemy type
    if enemyType == "light" then
        -- Fast, direct approach
        enemy.movementPattern = "direct"
    elseif enemyType == "medium" then
        -- Side-to-side movement
        enemy.movementPattern = "zigzag"
        enemy.zigzagWidth = 100
        enemy.zigzagSpeed = 0.5
    else
        -- Heavy enemies move slowly but are tough
        enemy.movementPattern = "direct"
    end
    
    -- Add damage function
    enemy.takeDamage = function(self, amount)
        if not self or self.removeSelf == nil then
            return
        end
        
        self.health = self.health - amount
        
        -- Visual damage effect
        self.alpha = 0.5
        transition.to(self, { time=200, alpha=1 })
        
        -- Check if enemy is destroyed
        if self.health <= 0 then
            self:destroy()
        end
    end
    
    -- Add destroy function
    enemy.destroy = function(self)
        if not self or self.removeSelf == nil then
            return
        end
        
        -- Create explosion effect
        if scene and scene.createExplosion then
            scene:createExplosion(self.x, self.y, 10, 1, 0.3, 0.3)
        end
        
        -- Add score and register kill
        score = score + self.scoreValue
        kills = kills + 1
        
        print("Debug - Enemy destroyed, kills:", kills, "target:", missionData.targetKills)
        
        -- Add XP
        missionData.xpEarned = missionData.xpEarned + self.scoreValue
        
        -- Random tech fragment drop (20% chance)
        if math.random() < 0.2 then
            missionData.fragmentsEarned = missionData.fragmentsEarned + math.floor(self.scoreValue / 2)
        end
        
        -- Remove from list
        for i = #enemyList, 1, -1 do
            if enemyList[i] == self then
                table.remove(enemyList, i)
                break
            end
        end
        
        -- Remove from display
        display.remove(self)
        
        -- Check mission objectives
        if scene and scene.checkMissionObjectives then
            scene:checkMissionObjectives()
        end
    end
    
    -- УПРОЩЕННАЯ обработка коллизий врага
    enemy.collision = function(self, event)
        if event.phase == "began" then
            local other = event.other
            
            -- Попадание пули игрока
            if other and other.objectType == "playerBullet" then
                if CollisionManager and CollisionManager.handleBulletHit then
                    CollisionManager.handleBulletHit(other, self)
                end
                
            -- Столкновение с игроком (урон себе от столкновения)
            elseif other and other.objectType == "player" then
                self:takeDamage(self.damage * 0.5) -- Урон себе от столкновения
            end
        end
        return true
    end
    
    enemy:addEventListener("collision")
    table.insert(enemyList, enemy)
end

function scene:gameLoop()
    -- Skip if game is not active
    if not gameActive then
        return
    end
    
    -- Update mission time
    missionTimePassed = missionTimePassed + 0.016 -- Approx 60fps
    
    -- Update mission time display
    if statusBars and statusBars.missionInfo then
        if missionTimeLimit and missionTimeLimit > 0 then
            local timeLeft = math.max(0, missionTimeLimit - missionTimePassed)
            statusBars.missionInfo.text = string.format("%s: %.1f", 
                localization.getText("time_left"), timeLeft)
            
            -- Check for time-based failure
            if timeLeft <= 0 and missionType == "survival" then
                -- Survival mode - completed when time runs out
                missionComplete = true
                gameActive = false
                
                timer.performWithDelay(1000, function()
                    if scene and scene.showMissionComplete then
                        scene:showMissionComplete(true)
                    end
                end)
            elseif timeLeft <= 0 and (missionType == "defend" or missionType == "escort") then
                -- These modes complete successfully when time runs out
                missionComplete = true
                gameActive = false
                
                timer.performWithDelay(1000, function()
                    if scene and scene.showMissionComplete then
                        scene:showMissionComplete(true)
                    end
                end)
            end
        else
            -- Показываем прогресс убийств для clearance миссий
            if missionType == "clearance" and missionData and missionData.targetKills then
                statusBars.missionInfo.text = string.format("%s: %d/%d", 
                    localization.getText("kills"), kills, missionData.targetKills)
            else
                statusBars.missionInfo.text = string.format("%s: %d", 
                    localization.getText("kills"), kills)
            end
        end
    end
    
    -- Player automatic systems
    if playerShip and not missionFailed then
        -- Energy regeneration
        playerShip.energy = math.min(playerShip.maxEnergy, 
            playerShip.energy + (playerShip.energyRegen * 0.016))
        
        -- Weapon cooling
        playerShip.heat = math.max(0, 
            playerShip.heat - (playerShip.coolingRate * 0.016))
        
        -- Shield regeneration (only when energy is full)
        if playerShip.energy >= playerShip.maxEnergy and playerShip.shields < playerShip.maxShields then
            playerShip.shields = math.min(playerShip.maxShields, 
                playerShip.shields + (playerShip.shieldRegen * 0.016))
        end
        
        -- Update UI bars
        if statusBars then
            self:updateStatusBar(statusBars.energy, playerShip.energy, playerShip.maxEnergy)
            self:updateStatusBar(statusBars.heat, playerShip.heat, playerShip.maxHeat)
            self:updateStatusBar(statusBars.shield, playerShip.shields, playerShip.maxShields)
        end
    end
    
    -- Auto-fire weapon if activated
    if autoFireActive and playerShip and not missionFailed then
        local currentTime = system.getTimer()
        if currentTime - lastFireTime >= AUTO_FIRE_DELAY then
            self:fireWeapon(true)
        end
    end
    
    -- Update drone behavior
    if playerDrones then
        for i, drone in ipairs(playerDrones) do
            if drone and drone.removeSelf then
                -- Position drones relative to player
                if drone.droneType == "defense" then
                    -- Defense drones position in front of the ship
                    drone.x = playerShip.x + (drone.offsetX or 0)
                    drone.y = playerShip.y + (drone.offsetY or 0)
                else
                    -- Other drones follow in formation
                    local targetX = playerShip.x + (i % 2 == 0 and 30 or -30)
                    local targetY = playerShip.y - 20
                    
                    -- Smoothly move drones toward target position
                    drone.x = drone.x + (targetX - drone.x) * 0.1
                    drone.y = drone.y + (targetY - drone.y) * 0.1
                end
                
                -- Combat drones auto-fire
                if drone.droneType == "combat" then
                    local currentTime = system.getTimer()
                    if currentTime - (drone.lastFireTime or 0) > (1000 / (drone.fireRate or 1)) then
                        -- Create drone bullet
                        local bullet = display.newCircle(gameGroup, drone.x, drone.y - 15, 4)
                        bullet:setFillColor(0, 0.8, 0)
                        physics.addBody(bullet, "dynamic", { radius=4, isSensor=true })
                        bullet.gravityScale = 0
                        bullet.isBullet = true
                        bullet.objectType = "playerBullet"
                        bullet.damage = drone.damage or 10
                        bullet:setLinearVelocity(0, -600)
                        
                        -- Add collision handling
                        bullet.collision = function(self, event)
                            if event.phase == "began" and event.other and event.other.isEnemy then
                                -- Apply damage
                                if event.other.takeDamage then
                                    event.other:takeDamage(self.damage)
                                end
                                
                                -- Remove bullet
                                display.remove(self)
                                for j = #bulletList, 1, -1 do
                                    if bulletList[j] == self then
                                        table.remove(bulletList, j)
                                        break
                                    end
                                end
                            end
                            return true
                        end
                        bullet:addEventListener("collision")
                        
                        table.insert(bulletList, bullet)
                        drone.lastFireTime = currentTime
                    end
                end
                
                -- Support drones heal over time
                if drone.droneType == "support" then
                    local currentTime = system.getTimer()
                    if currentTime - (drone.lastHealTime or 0) > 1000 then
                        -- Heal player
                        if playerShip.health < playerShip.maxHealth then
                            playerShip.health = math.min(playerShip.maxHealth, 
                                playerShip.health + (drone.healRate or 5))
                            
                            if statusBars and statusBars.health then
                                self:updateStatusBar(statusBars.health, playerShip.health, playerShip.maxHealth)
                            end
                            
                            -- Healing effect
                            local healEffect = display.newCircle(gameGroup, playerShip.x, playerShip.y, 20)
                            healEffect:setFillColor(0, 1, 0.5, 0.5)
                            healEffect.alpha = 0.7
                            transition.to(healEffect, {
                                time = 500, 
                                alpha = 0,
                                xScale = 2,
                                yScale = 2,
                                onComplete = function() 
                                    if healEffect and healEffect.removeSelf then
                                        display.remove(healEffect) 
                                    end
                                end
                            })
                            
                            drone.lastHealTime = currentTime
                        end
                    end
                end
            end
        end
    end
    
    -- Update enemy behavior
    if enemyList then
        for i = #enemyList, 1, -1 do
            local enemy = enemyList[i]
            
            if enemy and enemy.removeSelf then
                -- Basic movement based on pattern
                if enemy.movementPattern == "direct" then
                    -- Move straight down
                    enemy.y = enemy.y + (enemy.speed or 100) * 0.016
                elseif enemy.movementPattern == "zigzag" then
                    -- Move in zigzag pattern
                    enemy.y = enemy.y + (enemy.speed or 100) * 0.016
                    enemy.x = enemy.x + math.sin(enemy.y * (enemy.zigzagSpeed or 0.5)) * 2
                end
                
                -- Enemy firing
                local currentTime = system.getTimer()
                if currentTime - (enemy.lastFireTime or 0) > (1000 / (enemy.fireRate or 1)) then
                    -- Create enemy bullet
                    local bullet = display.newCircle(gameGroup, enemy.x, enemy.y + 20, 5)
                    bullet:setFillColor(1, 0.3, 0.3)
                    physics.addBody(bullet, "dynamic", { radius=5, isSensor=true })
                    bullet.gravityScale = 0
                    bullet.objectType = "enemyBullet"
                    bullet.isBullet = true
                    bullet.isEnemyBullet = true
                    bullet.damage = math.max(5, (enemy.damage or 10) / 2) -- Минимальный урон 5
                    bullet:setLinearVelocity(0, 400)
                    
                    table.insert(bulletList, bullet)
                    enemy.lastFireTime = currentTime
                end
                
                -- Remove enemies that go offscreen
                if enemy.y > display.contentHeight + 50 then
                    display.remove(enemy)
                    table.remove(enemyList, i)
                    
                    -- If this was an escort mission, damage the escort object
                    if missionType == "escort" and escortObject and escortObject.takeDamage then
                        escortObject:takeDamage(10)
                    end
                end
            else
                -- Remove invalid enemy from list
                table.remove(enemyList, i)
            end
        end
    end
    
    -- Update boss behavior if present
    if bossEnemy and bossEnemy.removeSelf then
        -- ИСПРАВЛЕНИЕ: Убеждаемся что difficulty это число
        local difficulty = missionDifficulty or 2
        if type(difficulty) ~= "number" then
            difficulty = 2
        end
        
        -- Boss movement pattern
        if bossEnemy.race == "insect" then
            -- Insect boss: Quick side to side movement
            bossEnemy.x = display.contentCenterX + math.sin(system.getTimer() * 0.001) * 200
            if bossEnemy.y < 150 then
                bossEnemy.y = bossEnemy.y + 0.5
            end
        elseif bossEnemy.race == "robot" then
            -- Robot boss: Slow, methodical movement
            bossEnemy.x = bossEnemy.x + math.sin(system.getTimer() * 0.0005) * 1
            if bossEnemy.y < 180 then
                bossEnemy.y = bossEnemy.y + 0.2
            end
        elseif bossEnemy.race == "parasite" then
            -- Parasite boss: Erratic movement
            bossEnemy.x = bossEnemy.x + math.sin(system.getTimer() * 0.002) * 3
            bossEnemy.y = 150 + math.sin(system.getTimer() * 0.001) * 50
        elseif bossEnemy.race == "pirate" then
            -- Pirate boss: Strategic positioning
            bossEnemy.x = display.contentCenterX + math.sin(system.getTimer() * 0.0008) * 150
            if bossEnemy.y < 200 then
                bossEnemy.y = bossEnemy.y + 0.3
            end
        end
        
        -- Boss firing
        local currentTime = system.getTimer()
        if currentTime - (bossEnemy.lastFireTime or 0) > (1000 / (bossEnemy.fireRate or 1)) then
            -- Create boss bullet(s)
            if self.createBossAttack then
                self:createBossAttack(bossEnemy, "normal")
            end
            bossEnemy.lastFireTime = currentTime
        end
        
        -- Boss special attack
        if currentTime - (bossEnemy.lastSpecialTime or 0) > ((bossEnemy.specialAttackRate or 5) * 1000) then
            -- Create special attack
            if self.createBossAttack then
                self:createBossAttack(bossEnemy, "special")
            end
            bossEnemy.lastSpecialTime = currentTime
        end
    end
    
    -- Update escort or defense object if present
    if missionType == "escort" and escortObject and escortObject.removeSelf then
        -- Move escort object slowly up the screen
        escortObject.y = escortObject.y - 10 * 0.016
        
        -- If escort reaches top of screen, mission complete
        if escortObject.y < -50 then
            missionComplete = true
            gameActive = false
            
            timer.performWithDelay(1000, function()
                if scene and scene.showMissionComplete then
                    scene:showMissionComplete(true)
                end
            end)
        end
    elseif missionType == "defend" and defenseObject then
        -- Defense object stays in place
        -- Nothing to update
    end
    
    -- Clean up offscreen bullets
    if bulletList then
        for i = #bulletList, 1, -1 do
            local bullet = bulletList[i]
            if bullet and bullet.removeSelf then
                if bullet.y < -50 or bullet.y > display.contentHeight + 50 then
                    display.remove(bullet)
                    table.remove(bulletList, i)
                end
            else
                -- Remove invalid bullet from list
                table.remove(bulletList, i)
            end
        end
    end
    
    -- ИСПРАВЛЕНИЕ: Продолжаем спавнить врагов для не-босс миссий
    if missionType ~= "boss" and gameActive and not missionComplete and not missionFailed then
        -- Проверяем, нужно ли спавнить больше врагов
        local maxEnemiesForSpawn = math.floor((MAX_ENEMIES_ON_SCREEN or 10) / 2)
        if #enemyList < maxEnemiesForSpawn then
            -- Если врагов мало, спавним еще
            if not spawnTimer then
                self:spawnEnemies()
            end
        end
    end
    
    -- Check mission objectives
    if self.checkMissionObjectives then
        self:checkMissionObjectives()
    end
end

-------------------
function scene:spawnEnemies()
    -- Debug info
    print("Debug - spawnEnemies called, gameActive:", gameActive, "missionComplete:", missionComplete)
    
    -- Don't spawn if mission is over
    if missionComplete or missionFailed or not gameActive then
        print("Debug - Not spawning: mission over or game inactive")
        return
    end
    
    -- Limit number of enemies
    if #enemyList >= MAX_ENEMIES_ON_SCREEN then
        print("Debug - Not spawning: too many enemies on screen:", #enemyList)
        -- Попробуем снова через короткое время
        timer.performWithDelay(500, function() self:spawnEnemies() end)
        return
    end
    
    -- ИСПРАВЛЕНИЕ: Убеждаемся что difficulty это число
    local difficulty = missionDifficulty or 2
    if type(difficulty) ~= "number" then
        print("Debug - ERROR: difficulty is not a number:", difficulty, type(difficulty))
        difficulty = 2
    end
    
    print("Debug - Using difficulty:", difficulty, "type:", type(difficulty))
    
    -- Determine spawn rate based on difficulty
    local spawnRateMultiplier = 1 / difficulty
    local spawnRate = ENEMY_BASE_SPAWN_RATE * spawnRateMultiplier
    
    print("Debug - Spawn rate:", spawnRate, "multiplier:", spawnRateMultiplier)
    
    -- Schedule next spawn
    spawnTimer = timer.performWithDelay(spawnRate, function() self:spawnEnemies() end)
    
    -- Determine enemy type to spawn
    local enemyTypes = {"light", "medium", "heavy"}
    local weights = {70, 25, 5}  -- Probability weights
    
    -- Adjust weights based on mission time
    if missionTimePassed > 60 then  -- After 1 minute
        weights = {50, 40, 10}
    elseif missionTimePassed > 120 then  -- After 2 minutes
        weights = {30, 50, 20}
    elseif missionTimePassed > 180 then  -- After 3 minutes
        weights = {20, 50, 30}
    end
    
    -- Adjust weights based on difficulty
    if difficulty >= 3 then
        for i = 1, #weights do
            weights[i] = weights[i] * (1 + (difficulty - 2) * 0.2)
        end
    end
    
    -- Choose enemy type
    local enemyType = utils.weightedRandom(enemyTypes, weights)
    
    print("Debug - Spawning enemy type:", enemyType)
    
    -- Create enemy based on type
    local enemyX = math.random(50, display.contentWidth - 50)
    local enemyY = -50  -- Spawn above the screen
    
    local enemy
    
    if enemyType == "light" then
        -- Light enemy: small, fast triangle
        enemy = display.newPolygon(gameGroup, enemyX, enemyY, {0,-15, -15,15, 15,15})
        enemy:setFillColor(1, 0.3, 0.3)  -- Red
        physics.addBody(enemy, "dynamic", { radius=15, isSensor=true })
        enemy.health = 20 * difficulty
        enemy.damage = 5 * difficulty
        enemy.speed = 150 + (difficulty * 20)
        enemy.fireRate = 2  -- shots per second
        enemy.scoreValue = 10
        
    elseif enemyType == "medium" then
        -- Medium enemy: medium square
        enemy = display.newRect(gameGroup, enemyX, enemyY, 40, 40)
        enemy:setFillColor(1, 0.4, 0.4)  -- Red
        physics.addBody(enemy, "dynamic", { box={width=40, height=40}, isSensor=true })
        enemy.health = 40 * difficulty
        enemy.damage = 10 * difficulty
        enemy.speed = 100 + (difficulty * 10)
        enemy.fireRate = 1.5  -- shots per second
        enemy.scoreValue = 25
        
    elseif enemyType == "heavy" then
        -- Heavy enemy: large hexagon
        local vertices = {}
        for i = 0, 5 do
            local angle = math.rad(i * 60)
            table.insert(vertices, 30 * math.cos(angle))
            table.insert(vertices, 30 * math.sin(angle))
        end
        enemy = display.newPolygon(gameGroup, enemyX, enemyY, vertices)
        enemy:setFillColor(1, 0.5, 0.5)  -- Red
        physics.addBody(enemy, "dynamic", { radius=30, isSensor=true })
        enemy.health = 80 * difficulty
        enemy.damage = 15 * difficulty
        enemy.speed = 70 + (difficulty * 5)
        enemy.fireRate = 1  -- shots per second
        enemy.scoreValue = 50
    end
    
    -- Set up common enemy properties
    enemy.isEnemy = true
    enemy.lastFireTime = system.getTimer()
    enemy.enemyType = enemyType
    enemy.maxHealth = enemy.health
    
    print("Debug - Created enemy with health:", enemy.health, "damage:", enemy.damage)
    
    -- Movement pattern based on enemy type
    if enemyType == "light" then
        -- Fast, direct approach
        enemy.movementPattern = "direct"
    elseif enemyType == "medium" then
        -- Side-to-side movement
        enemy.movementPattern = "zigzag"
        enemy.zigzagWidth = 100
        enemy.zigzagSpeed = 0.5
    else
        -- Heavy enemies move slowly but are tough
        enemy.movementPattern = "direct"
    end
    
    -- Add damage function
    enemy.takeDamage = function(self, amount)
        self.health = self.health - amount
        
        -- Visual damage effect
        self.alpha = 0.5
        transition.to(self, { time=200, alpha=1 })
        
        -- Check if enemy is destroyed
        if self.health <= 0 then
            self:destroy()
        end
    end
    
    -- Add destroy function
    enemy.destroy = function(self)
        -- Create explosion effect
        scene:createExplosion(self.x, self.y, 10, 1, 0.3, 0.3)
        
        -- Add score and register kill
        score = score + self.scoreValue
        kills = kills + 1
        
        print("Debug - Enemy destroyed, kills:", kills, "target:", missionData.targetKills)
        
        -- Add XP
        missionData.xpEarned = missionData.xpEarned + self.scoreValue
        
        -- Random tech fragment drop (20% chance)
        if math.random() < 0.2 then
            missionData.fragmentsEarned = missionData.fragmentsEarned + math.floor(self.scoreValue / 2)
        end
        
        -- Remove from list
        for i = #enemyList, 1, -1 do
            if enemyList[i] == self then
                table.remove(enemyList, i)
                break
            end
        end
        
        -- Remove from display
        display.remove(self)
        
        -- Check mission objectives
        self:checkMissionObjectives()
    end
    
-- Добавьте эту часть в конец функции spawnEnemies, заменив существующую обработку коллизий:

    -- Set up common enemy properties
    enemy.objectType = "enemy"
    enemy.isEnemy = true
    enemy.lastFireTime = system.getTimer()
    enemy.enemyType = enemyType
    enemy.maxHealth = enemy.health
    
    -- УПРОЩЕННАЯ обработка коллизий врага
    enemy.collision = function(self, event)
        if event.phase == "began" then
            local other = event.other
            
            -- Попадание пули игрока
            if other and other.objectType == "playerBullet" then
                CollisionManager.handleBulletHit(other, self)
                
            -- Столкновение с игроком (урон себе от столкновения)
            elseif other and other.objectType == "player" then
                self:takeDamage(self.damage * 0.5) -- Урон себе от столкновения
            end
        end
        return true
    end
    
    enemy:addEventListener("collision")
    table.insert(enemyList, enemy)
end
-------------------
--------------------
function scene:spawnBoss()
    -- Debug info
    print("Debug - spawnBoss called")
    print("Debug - gameActive:", gameActive, "missionComplete:", missionComplete)
    print("Debug - missionType:", missionType)
    
    -- Don't spawn if mission is over or not boss mission
    if missionComplete or missionFailed or not gameActive or missionType ~= "boss" then
        print("Debug - Not spawning boss: conditions not met")
        return
    end
    
    -- ИСПРАВЛЕНИЕ: Убеждаемся что difficulty это число
    local difficulty = missionDifficulty or 2
    if type(difficulty) ~= "number" then
        print("Debug - ERROR: difficulty is not a number:", difficulty, type(difficulty))
        difficulty = 2
    end
    
    print("Debug - Using difficulty:", difficulty)
    
    -- Determine boss type based on race
    local raceTypes = {"insect", "robot", "parasite", "pirate"}
    local race = missionData.race or raceTypes[math.random(#raceTypes)]
    
    print("Debug - Spawning boss race:", race)
    
    -- Create boss in center top of screen
    local bossX = display.contentCenterX
    local bossY = 100
    
    local boss
    
    if race == "insect" then
        -- Insect boss: Fast, medium health, group attacks
        local verts = {0,-50, -40,-20, -60,20, -40,50, 40,50, 60,20, 40,-20}
        boss = display.newPolygon(gameGroup, bossX, bossY, verts)
        boss:setFillColor(1, 0.5, 0.2)  -- Orange-red
        physics.addBody(boss, "dynamic", { radius=60, isSensor=true })
        boss.health = 500 * difficulty
        boss.damage = 20 * difficulty
        boss.speed = 70
        boss.fireRate = 0.8  -- shots per second
        boss.specialAttackRate = 5  -- seconds between special attacks
        boss.specialAttack = "spawn"  -- Spawns small insect minions
        
    elseif race == "robot" then
        -- Robot boss: Slow, high health, heavy weapons
        boss = display.newRect(gameGroup, bossX, bossY, 120, 120)
        boss:setFillColor(0.6, 0.6, 0.8)  -- Blueish metal
        physics.addBody(boss, "dynamic", { box={width=120, height=120}, isSensor=true })
        boss.health = 800 * difficulty
        boss.damage = 30 * difficulty
        boss.speed = 40
        boss.fireRate = 0.5  -- shots per second
        boss.specialAttackRate = 8  -- seconds between special attacks
        boss.specialAttack = "beam"  -- Powerful laser beam
        
    elseif race == "parasite" then
        -- Parasite boss: Very fast, low health, swarm tactics
        local radius = 70
        local segments = 8
        local verts = {}
        for i = 1, segments do
            local angle = math.rad((i-1) * (360 / segments))
            table.insert(verts, radius * math.cos(angle))
            table.insert(verts, radius * math.sin(angle))
        end
        boss = display.newPolygon(gameGroup, bossX, bossY, verts)
        boss:setFillColor(0.8, 0.2, 0.8)  -- Purple
        physics.addBody(boss, "dynamic", { radius=70, isSensor=true })
        boss.health = 400 * difficulty
        boss.damage = 15 * difficulty
        boss.speed = 100
        boss.fireRate = 1.2  -- shots per second
        boss.specialAttackRate = 4  -- seconds between special attacks
        boss.specialAttack = "rush"  -- Rushes at the player
        
    elseif race == "pirate" then
        -- Pirate boss: Balanced, unpredictable
        local verts = {0,-60, -50,-20, -70,40, 0,60, 70,40, 50,-20}
        boss = display.newPolygon(gameGroup, bossX, bossY, verts)
        boss:setFillColor(0.7, 0.2, 0.2)  -- Dark red
        physics.addBody(boss, "dynamic", { radius=70, isSensor=true })
        boss.health = 600 * difficulty
        boss.damage = 25 * difficulty
        boss.speed = 60
        boss.fireRate = 1  -- shots per second
        boss.specialAttackRate = 6  -- seconds between special attacks
        boss.specialAttack = "barrage"  -- Multi-directional attack
    end
    
    print("Debug - Boss created with health:", boss.health, "damage:", boss.damage)
    
    -- Set up common boss properties
    boss.isEnemy = true
    boss.isBoss = true
    boss.lastFireTime = system.getTimer()
    boss.lastSpecialTime = system.getTimer()
    boss.enemyType = "boss"
    boss.race = race
    boss.maxHealth = boss.health
    boss.scoreValue = 500
    
    -- Add health bar for boss
    boss.healthBar = display.newRect(uiGroup, display.contentCenterX, 20, display.contentWidth - 100, 20)
    boss.healthBar:setFillColor(1, 0.3, 0.3)
    boss.healthBar.anchorX = 0
    boss.healthBar.x = 50
    boss.healthBar.originalWidth = display.contentWidth - 100
    
    local healthBarBg = display.newRect(uiGroup, display.contentCenterX, 20, display.contentWidth - 100, 20)
    healthBarBg:setFillColor(0.2, 0.2, 0.2)
    healthBarBg.anchorX = 0
    healthBarBg.x = 50
    healthBarBg:toBack()
    
    -- Boss name display
    local bossName = display.newText({
        parent = uiGroup,
        text = localization.getText("boss_" .. race),
        x = display.contentCenterX,
        y = 45,
        font = native.systemFontBold,
        fontSize = 22
    })
    bossName:setFillColor(1, 0.5, 0.5)
    
    -- Add damage function
    boss.takeDamage = function(self, amount)
        self.health = self.health - amount
        
        -- Update health bar
        local percentage = self.health / self.maxHealth
        percentage = math.max(0, math.min(1, percentage))
        self.healthBar.width = self.healthBar.originalWidth * percentage
        
        -- Visual damage effect
        self.alpha = 0.5
        transition.to(self, { time=200, alpha=1 })
        
        -- Check if boss is destroyed
        if self.health <= 0 then
            self:destroy()
        end
    end
    
    -- Add destroy function
    boss.destroy = function(self)
        print("Debug - Boss destroyed!")
        
        -- Create large explosion effect
        scene:createExplosion(self.x, self.y, 30, 1, 0.3, 0.3)
        
        -- Add big score and register kill
        score = score + self.scoreValue
        kills = kills + 1
        
        -- Add XP and fragments
        missionData.xpEarned = missionData.xpEarned + self.scoreValue
        missionData.fragmentsEarned = missionData.fragmentsEarned + 100 * difficulty
        
        -- Random artifact drop (boss-only)
        missionData.artifactDropped = true
        
        -- Remove health bar and name
        display.remove(self.healthBar)
        display.remove(bossName)
        
        -- Remove from list
        bossEnemy = nil
        
        -- Remove from display
        display.remove(self)
        
        -- Mission complete
        missionComplete = true
        gameActive = false
        
        print("Debug - Boss mission completed!")
        
        -- Show completion screen after delay
        timer.performWithDelay(2000, function()
            scene:showMissionComplete(true)
        end)
    end
    
    -- Add collision handling
    boss.collision = function(self, event)
        if event.phase == "began" then
            local other = event.other
            
            -- Collision with player bullets
            if other.isBullet and other.isPlayerBullet then
                self:takeDamage(other.damage or 10)
                
                -- Remove bullet unless it's piercing
                if not other.isPiercing then
                    display.remove(other)
                    for i = #bulletList, 1, -1 do
                        if bulletList[i] == other then
                            table.remove(bulletList, i)
                            break
                        end
                    end
                end
            end
            
            -- Collision with player (damage player)
            if other.isPlayer then
                other:takeDamage(self.damage)
            end
        end
        return true
    end
    
    boss:addEventListener("collision")
    
    -- Store boss reference
    bossEnemy = boss
    
    print("Debug - Boss spawned successfully!")
end
-------------
-------------
function scene:spawnEnemies()
    -- Debug info
    print("Debug - spawnEnemies called, gameActive:", gameActive, "missionComplete:", missionComplete)
    
    -- Don't spawn if mission is over
    if missionComplete or missionFailed or not gameActive then
        print("Debug - Not spawning: mission over or game inactive")
        return
    end
    
    -- Limit number of enemies
    if #enemyList >= MAX_ENEMIES_ON_SCREEN then
        print("Debug - Not spawning: too many enemies on screen:", #enemyList)
        -- Попробуем снова через короткое время
        timer.performWithDelay(500, function() 
            if scene and scene.spawnEnemies then
                scene:spawnEnemies() 
            end
        end)
        return
    end
    
    -- ИСПРАВЛЕНИЕ: Убеждаемся что difficulty это число
    local difficulty = missionDifficulty or 2
    if type(difficulty) ~= "number" then
        print("Debug - ERROR: difficulty is not a number:", difficulty, type(difficulty))
        difficulty = 2
    end
    
    print("Debug - Using difficulty:", difficulty, "type:", type(difficulty))
    
    -- Determine spawn rate based on difficulty
    local spawnRateMultiplier = 1 / difficulty
    local spawnRate = ENEMY_BASE_SPAWN_RATE * spawnRateMultiplier
    
    print("Debug - Spawn rate:", spawnRate, "multiplier:", spawnRateMultiplier)
    
    -- Schedule next spawn
    if spawnTimer then
        timer.cancel(spawnTimer)
    end
    spawnTimer = timer.performWithDelay(spawnRate, function() 
        if scene and scene.spawnEnemies then
            scene:spawnEnemies() 
        end
    end)
    
    -- Determine enemy type to spawn
    local enemyTypes = {"light", "medium", "heavy"}
    local weights = {70, 25, 5}  -- Probability weights
    
    -- Adjust weights based on mission time
    if missionTimePassed > 180 then  -- After 3 minutes
        weights = {20, 50, 30}
    elseif missionTimePassed > 120 then  -- After 2 minutes
        weights = {30, 50, 20}
    elseif missionTimePassed > 60 then  -- After 1 minute
        weights = {50, 40, 10}
    end
    
    -- Adjust weights based on difficulty
    if difficulty >= 3 then
        for i = 1, #weights do
            weights[i] = weights[i] * (1 + (difficulty - 2) * 0.2)
        end
    end
    
    -- Choose enemy type
    local enemyType = utils.weightedRandom(enemyTypes, weights)
    
    print("Debug - Spawning enemy type:", enemyType)
    
    -- Create enemy based on type
    local enemyX = math.random(50, display.contentWidth - 50)
    local enemyY = -50  -- Spawn above the screen
    
    local enemy
    
    if enemyType == "light" then
        -- Light enemy: small, fast triangle
        enemy = display.newPolygon(gameGroup, enemyX, enemyY, {0,-15, -15,15, 15,15})
        enemy:setFillColor(1, 0.3, 0.3)  -- Red
        physics.addBody(enemy, "dynamic", { radius=15, isSensor=true })
        enemy.health = 20 * difficulty
        enemy.damage = 5 * difficulty
        enemy.speed = 150 + (difficulty * 20)
        enemy.fireRate = 2  -- shots per second
        enemy.scoreValue = 10
        
    elseif enemyType == "medium" then
        -- Medium enemy: medium square
        enemy = display.newRect(gameGroup, enemyX, enemyY, 40, 40)
        enemy:setFillColor(1, 0.4, 0.4)  -- Red
        physics.addBody(enemy, "dynamic", { box={width=40, height=40}, isSensor=true })
        enemy.health = 40 * difficulty
        enemy.damage = 10 * difficulty
        enemy.speed = 100 + (difficulty * 10)
        enemy.fireRate = 1.5  -- shots per second
        enemy.scoreValue = 25
        
    elseif enemyType == "heavy" then
        -- Heavy enemy: large hexagon
        local vertices = {}
        for i = 0, 5 do
            local angle = math.rad(i * 60)
            table.insert(vertices, 30 * math.cos(angle))
            table.insert(vertices, 30 * math.sin(angle))
        end
        enemy = display.newPolygon(gameGroup, enemyX, enemyY, vertices)
        enemy:setFillColor(1, 0.5, 0.5)  -- Red
        physics.addBody(enemy, "dynamic", { radius=30, isSensor=true })
        enemy.health = 80 * difficulty
        enemy.damage = 15 * difficulty
        enemy.speed = 70 + (difficulty * 5)
        enemy.fireRate = 1  -- shots per second
        enemy.scoreValue = 50
    end
    
    -- Set up common enemy properties
    enemy.objectType = "enemy"
    enemy.isEnemy = true
    enemy.lastFireTime = system.getTimer()
    enemy.enemyType = enemyType
    enemy.maxHealth = enemy.health
    
    print("Debug - Created enemy with health:", enemy.health, "damage:", enemy.damage)
    
    -- Movement pattern based on enemy type
    if enemyType == "light" then
        -- Fast, direct approach
        enemy.movementPattern = "direct"
    elseif enemyType == "medium" then
        -- Side-to-side movement
        enemy.movementPattern = "zigzag"
        enemy.zigzagWidth = 100
        enemy.zigzagSpeed = 0.5
    else
        -- Heavy enemies move slowly but are tough
        enemy.movementPattern = "direct"
    end
    
    -- Add damage function
    enemy.takeDamage = function(self, amount)
        if not self or self.removeSelf == nil then
            return
        end
        
        self.health = self.health - amount
        
        -- Visual damage effect
        self.alpha = 0.5
        transition.to(self, { time=200, alpha=1 })
        
        -- Check if enemy is destroyed
        if self.health <= 0 then
            self:destroy()
        end
    end
    
    -- Add destroy function
    enemy.destroy = function(self)
        if not self or self.removeSelf == nil then
            return
        end
        
        -- Create explosion effect
        if scene and scene.createExplosion then
            scene:createExplosion(self.x, self.y, 10, 1, 0.3, 0.3)
        end
        
        -- Add score and register kill
        score = score + self.scoreValue
        kills = kills + 1
        
        print("Debug - Enemy destroyed, kills:", kills, "target:", missionData.targetKills)
        
        -- Add XP
        missionData.xpEarned = missionData.xpEarned + self.scoreValue
        
        -- Random tech fragment drop (20% chance)
        if math.random() < 0.2 then
            missionData.fragmentsEarned = missionData.fragmentsEarned + math.floor(self.scoreValue / 2)
        end
        
        -- Remove from list
        for i = #enemyList, 1, -1 do
            if enemyList[i] == self then
                table.remove(enemyList, i)
                break
            end
        end
        
        -- Remove from display
        display.remove(self)
        
        -- Check mission objectives
        if scene and scene.checkMissionObjectives then
            scene:checkMissionObjectives()
        end
    end
    
    -- УПРОЩЕННАЯ обработка коллизий врага
    enemy.collision = function(self, event)
        if event.phase == "began" then
            local other = event.other
            
            -- Попадание пули игрока
            if other and other.objectType == "playerBullet" then
                if CollisionManager and CollisionManager.handleBulletHit then
                    CollisionManager.handleBulletHit(other, self)
                end
                
            -- Столкновение с игроком (урон себе от столкновения)
            elseif other and other.objectType == "player" then
                self:takeDamage(self.damage * 0.5) -- Урон себе от столкновения
            end
        end
        return true
    end
    
    enemy:addEventListener("collision")
    table.insert(enemyList, enemy)
end
-------------

function scene:createBossAttack(boss, attackType)
    if not boss or missionComplete or missionFailed then return end
    
    if attackType == "normal" then
        -- Normal attack based on boss race
        if boss.race == "insect" then
            -- Multiple small bullets in a spread
            for i = -2, 2 do
                local bullet = display.newCircle(gameGroup, boss.x + (i * 15), boss.y + 40, 6)
                bullet:setFillColor(1, 0.5, 0.2)
                physics.addBody(bullet, "dynamic", { radius=6, isSensor=true })
                bullet.gravityScale = 0
                bullet.isBullet = true
                bullet.isEnemyBullet = true
                bullet.damage = boss.damage / 3
                bullet:setLinearVelocity(i * 50, 300)
                
                -- Add collision handling
                bullet.collision = function(self, event)
                    if event.phase == "began" and event.other.isPlayer then
                        -- Remove bullet
                        display.remove(self)
                        for i = #bulletList, 1, -1 do
                            if bulletList[i] == self then
                                table.remove(bulletList, i)
                                break
                            end
                        end
                    end
                    return true
                end
                bullet:addEventListener("collision")
                
                table.insert(bulletList, bullet)
            end
            
        elseif boss.race == "robot" then
            -- Heavy, slow bullets
            local bullet = display.newRect(gameGroup, boss.x, boss.y + 70, 20, 20)
            bullet:setFillColor(0.6, 0.6, 0.8)
            physics.addBody(bullet, "dynamic", { box={width=20, height=20}, isSensor=true })
            bullet.gravityScale = 0
            bullet.isBullet = true
            bullet.isEnemyBullet = true
            bullet.damage = boss.damage
            bullet:setLinearVelocity(0, 250)
            
            -- Add collision handling
            bullet.collision = function(self, event)
                if event.phase == "began" and event.other.isPlayer then
                    -- Remove bullet
                    display.remove(self)
                    for i = #bulletList, 1, -1 do
                        if bulletList[i] == self then
                            table.remove(bulletList, i)
                            break
                        end
                    end
                end
                return true
            end
            bullet:addEventListener("collision")
            
            table.insert(bulletList, bullet)
            
        elseif boss.race == "parasite" then
            -- Fast, small bullets in random directions
            for i = 1, 3 do
                local angle = math.random() * math.pi * 2
                local bullet = display.newCircle(gameGroup, boss.x, boss.y, 4)
                bullet:setFillColor(0.8, 0.2, 0.8)
                physics.addBody(bullet, "dynamic", { radius=4, isSensor=true })
                bullet.gravityScale = 0
                bullet.isBullet = true
                bullet.isEnemyBullet = true
                bullet.damage = boss.damage / 4
                
                local vx = math.cos(angle) * 350
                local vy = math.sin(angle) * 350
                if vy < 0 then vy = -vy end  -- Ensure bullets go downward
                
                bullet:setLinearVelocity(vx, vy)
                
                -- Add collision handling
                bullet.collision = function(self, event)
                    if event.phase == "began" and event.other.isPlayer then
                        -- Remove bullet
                        display.remove(self)
                        for i = #bulletList, 1, -1 do
                            if bulletList[i] == self then
                                table.remove(bulletList, i)
                                break
                            end
                        end
                    end
                    return true
                end
                bullet:addEventListener("collision")
                
                table.insert(bulletList, bullet)
            end
            
        elseif boss.race == "pirate" then
            -- Targeted bullet
            local targetX = playerShip.x
            local targetY = playerShip.y
            
            local bullet = display.newCircle(gameGroup, boss.x, boss.y + 50, 8)
            bullet:setFillColor(0.7, 0.2, 0.2)
            physics.addBody(bullet, "dynamic", { radius=8, isSensor=true })
            bullet.gravityScale = 0
            bullet.isBullet = true
            bullet.isEnemyBullet = true
            bullet.damage = boss.damage / 2
            
            -- Calculate velocity to aim at player
            local angle = math.atan2(targetY - boss.y, targetX - boss.x)
            local vx = math.cos(angle) * 300
            local vy = math.sin(angle) * 300
            
            bullet:setLinearVelocity(vx, vy)
            
            -- Add collision handling
            bullet.collision = function(self, event)
                if event.phase == "began" and event.other.isPlayer then
                    -- Remove bullet
                    display.remove(self)
                    for i = #bulletList, 1, -1 do
                        if bulletList[i] == self then
                            table.remove(bulletList, i)
                            break
                        end
                    end
                end
                return true
            end
            bullet:addEventListener("collision")
            
            table.insert(bulletList, bullet)
        end
    
    elseif attackType == "special" then
        -- Special attack based on boss type
        if boss.race == "insect" and boss.specialAttack == "spawn" then
            -- Spawn 3-5 small insect enemies
            local spawnCount = math.random(3, 5)
            
            for i = 1, spawnCount do
                local spawnX = boss.x + math.random(-100, 100)
                local spawnY = boss.y + 50
                
                -- Create small insect enemy
                local enemy = display.newPolygon(gameGroup, spawnX, spawnY, {0,-10, -10,10, 10,10})
                enemy:setFillColor(1, 0.5, 0.2)  -- Orange-red like the boss
                physics.addBody(enemy, "dynamic", { radius=10, isSensor=true })
                enemy.health = 15 * missionDifficulty
                enemy.damage = 5 * missionDifficulty
                enemy.speed = 180
                enemy.fireRate = 1
                enemy.scoreValue = 5
                enemy.isEnemy = true
                enemy.lastFireTime = system.getTimer()
                enemy.enemyType = "light"
                enemy.movementPattern = "direct"
                enemy.maxHealth = enemy.health
                
                -- Copy the enemy methods from spawn enemies
                enemy.takeDamage = enemyList[1] and enemyList[1].takeDamage or function(self, amount)
                    self.health = self.health - amount
                    if self.health <= 0 then self:destroy() end
                end
                
                enemy.destroy = enemyList[1] and enemyList[1].destroy or function(self)
                    scene:createExplosion(self.x, self.y, 5, 1, 0.5, 0.2)
                    score = score + self.scoreValue
                    kills = kills + 1
                    display.remove(self)
                    for i = #enemyList, 1, -1 do
                        if enemyList[i] == self then
                            table.remove(enemyList, i)
                            break
                        end
                    end
                end
                
                enemy.collision = enemyList[1] and enemyList[1].collision
                
                if enemy.collision then
                    enemy:addEventListener("collision")
                end
                
                table.insert(enemyList, enemy)
            end
            
            -- Visual effect for spawning
            local spawnEffect = display.newCircle(gameGroup, boss.x, boss.y, 100)
            spawnEffect:setFillColor(1, 0.5, 0.2, 0.3)
            transition.to(spawnEffect, {
                time = 500,
                alpha = 0,
                xScale = 1.5,
                yScale = 1.5,
                onComplete = function() display.remove(spawnEffect) end
            })
            
        elseif boss.race == "robot" and boss.specialAttack == "beam" then
            -- Powerful vertical beam attack with warning
            local warningBeam = display.newRect(gameGroup, playerShip.x, display.contentCenterY, 20, display.contentHeight)
            warningBeam:setFillColor(1, 0, 0, 0.3)
            
            -- Warning flash
            for i = 1, 3 do
                transition.to(warningBeam, {
                    time = 200,
                    alpha = 0.7,
                    delay = (i-1) * 400,
                    onComplete = function()
                        transition.to(warningBeam, {
                            time = 200,
                            alpha = 0.3
                        })
                    end
                })
            end
            
            -- Fire the beam after warning
            timer.performWithDelay(1200, function()
                -- Create actual beam
                local beam = display.newRect(gameGroup, warningBeam.x, display.contentCenterY, 30, display.contentHeight)
                beam:setFillColor(0.6, 0.6, 1)
                physics.addBody(beam, "dynamic", { box={width=30, height=display.contentHeight}, isSensor=true })
                beam.isBullet = true
                beam.isEnemyBullet = true
                beam.damage = boss.damage * 2
                
                -- Add collision
                beam.collision = function(self, event)
                    if event.phase == "began" and event.other.isPlayer then
                        -- Beam stays, just applies damage
                    end
                    return true
                end
                beam:addEventListener("collision")
                
                -- Remove warning beam
                display.remove(warningBeam)
                
                -- Remove actual beam after short duration
                timer.performWithDelay(500, function()
                    display.remove(beam)
                end)
            end)
            
        elseif boss.race == "parasite" and boss.specialAttack == "rush" then
            -- Quick rush toward player then back
            local targetX = playerShip.x
            local targetY = playerShip.y - 100  -- Aim a bit above player
            
            -- Warning effect
            boss.alpha = 0.5
            transition.to(boss, { time=300, alpha=1 })
            
            -- Flash to indicate rush
            local rushIndicator = display.newLine(gameGroup, boss.x, boss.y, targetX, targetY)
            rushIndicator:setStrokeColor(0.8, 0.2, 0.8, 0.5)
            rushIndicator.strokeWidth = 3
            
            transition.to(rushIndicator, {
                time = 500,
                alpha = 0,
                onComplete = function() display.remove(rushIndicator) end
            })
            
            -- Perform rush after delay
            timer.performWithDelay(500, function()
                transition.to(boss, {
                    time = 300,
                    x = targetX,
                    y = targetY,
                    onComplete = function()
                        -- Return to position
                        transition.to(boss, {
                            time = 1000,
                            x = display.contentCenterX + math.sin(system.getTimer() * 0.002) * 3,
                            y = 150
                        })
                    end
                })
            end)
            
        elseif boss.race == "pirate" and boss.specialAttack == "barrage" then
            -- Circular bullet barrage
            local bulletCount = 16
            local radius = 20
            
            for i = 1, bulletCount do
                local angle = (i-1) * (2 * math.pi / bulletCount)
                local bullet = display.newCircle(gameGroup, boss.x, boss.y, 6)
                bullet:setFillColor(0.7, 0.2, 0.2)
                physics.addBody(bullet, "dynamic", { radius=6, isSensor=true })
                bullet.gravityScale = 0
                bullet.isBullet = true
                bullet.isEnemyBullet = true
                bullet.damage = boss.damage / 3
                
                local vx = math.cos(angle) * 250
                local vy = math.sin(angle) * 250
                
                bullet:setLinearVelocity(vx, vy)
                
                -- Add collision handling
                bullet.collision = function(self, event)
                    if event.phase == "began" and event.other.isPlayer then
                        -- Remove bullet
                        display.remove(self)
                        for i = #bulletList, 1, -1 do
                            if bulletList[i] == self then
                                table.remove(bulletList, i)
                                break
                            end
                        end
                    end
                    return true
                end
                bullet:addEventListener("collision")
                
                table.insert(bulletList, bullet)
            end
            
            -- Visual effect for barrage
            local barageEffect = display.newCircle(gameGroup, boss.x, boss.y, radius)
            barageEffect:setFillColor(1, 0, 0, 0.5)
            transition.to(barageEffect, {
                time = 500,
                alpha = 0,
                xScale = 10,
                yScale = 10,
                onComplete = function() display.remove(barageEffect) end
            })
        end
    end
end

function scene:createEscortObject()
    -- Create an object that needs to be escorted to the top of the screen
    local escort = display.newRect(gameGroup, display.contentCenterX, display.contentHeight + 100, 80, 80)
    escort:setFillColor(0.2, 0.7, 0.2)
    
    -- Add physics
    physics.addBody(escort, "dynamic", { box={width=80, height=80}, isSensor=true })
    escort.isFixedRotation = true
    escort.isEscort = true
    escort.health = 100 * missionDifficulty
    escort.maxHealth = escort.health
    
    -- Add health bar for escort
    local healthBarWidth = 100
    local healthBarHeight = 10
    
    local healthBarBg = display.newRect(gameGroup, escort.x, escort.y - 50, healthBarWidth, healthBarHeight)
    healthBarBg:setFillColor(0.2, 0.2, 0.2)
    
    local healthBar = display.newRect(gameGroup, escort.x - healthBarWidth/2, escort.y - 50, healthBarWidth, healthBarHeight)
    healthBar:setFillColor(0.2, 0.7, 0.2)
    healthBar.anchorX = 0
    healthBar.x = escort.x - healthBarWidth/2
    
    -- Track original width for health calculations
    healthBar.originalWidth = healthBarWidth
    escort.healthBar = healthBar
    escort.healthBarBg = healthBarBg
    
    -- Add damage method
    escort.takeDamage = function(self, amount)
        self.health = math.max(0, self.health - amount)
        
        -- Update health bar
        local percentage = self.health / self.maxHealth
        self.healthBar.width = self.healthBar.originalWidth * percentage
        
        -- Check if destroyed
        if self.health <= 0 then
            self:destroy()
        end
    end
    
    -- Add destroy method
    escort.destroy = function(self)
        -- Create explosion
        scene:createExplosion(self.x, self.y, 15, 0.2, 0.7, 0.2)
        
        -- Mission failed
        missionFailed = true
        gameActive = false
        
        -- Show mission failed screen
        timer.performWithDelay(2000, function()
            scene:showMissionComplete(false)
        end)
        
        -- Remove object
        display.remove(self.healthBar)
        display.remove(self.healthBarBg)
        display.remove(self)
    end
    
    -- Add update method to keep health bar with escort
    escort.update = function(self)
        self.healthBar.x = self.x - self.healthBar.originalWidth/2
        self.healthBar.y = self.y - 50
        self.healthBarBg.x = self.x
        self.healthBarBg.y = self.y - 50
    end
    
    Runtime:addEventListener("enterFrame", function()
        if escort then
            escort:update()
        end
    end)
    
    return escort
end

function scene:createDefenseObject()
    -- Create an object that needs to be defended
    local defense = display.newRect(gameGroup, display.contentCenterX, display.contentHeight/2, 100, 100)
    defense:setFillColor(0.2, 0.7, 0.7)
    
    -- Add physics
    physics.addBody(defense, "dynamic", { box={width=100, height=100}, isSensor=true })
    defense.isFixedRotation = true
    defense.isDefense = true
    defense.health = 200 * missionDifficulty
    defense.maxHealth = defense.health
    
    -- Add health bar for defense object
    local healthBarWidth = 120
    local healthBarHeight = 10
    
    local healthBarBg = display.newRect(gameGroup, defense.x, defense.y - 70, healthBarWidth, healthBarHeight)
    healthBarBg:setFillColor(0.2, 0.2, 0.2)
    
    local healthBar = display.newRect(gameGroup, defense.x - healthBarWidth/2, defense.y - 70, healthBarWidth, healthBarHeight)
    healthBar:setFillColor(0.2, 0.7, 0.7)
    healthBar.anchorX = 0
    healthBar.x = defense.x - healthBarWidth/2
    
    -- Track original width for health calculations
    healthBar.originalWidth = healthBarWidth
    defense.healthBar = healthBar
    defense.healthBarBg = healthBarBg
    
    -- Add damage method
    defense.takeDamage = function(self, amount)
        self.health = math.max(0, self.health - amount)
        
        -- Update health bar
        local percentage = self.health / self.maxHealth
        self.healthBar.width = self.healthBar.originalWidth * percentage
        
        -- Check if destroyed
        if self.health <= 0 then
            self:destroy()
        end
    end
    
    -- Add destroy method
    defense.destroy = function(self)
        -- Create explosion
        scene:createExplosion(self.x, self.y, 20, 0.2, 0.7, 0.7)
        
        -- Mission failed
        missionFailed = true
        gameActive = false
        
        -- Show mission failed screen
        timer.performWithDelay(2000, function()
            scene:showMissionComplete(false)
        end)
        
        -- Remove object
        display.remove(self.healthBar)
        display.remove(self.healthBarBg)
        display.remove(self)
    end
    
    -- Add collision detection
    defense.collision = function(self, event)
        if event.phase == "began" then
            local other = event.other
            
            -- Collision with enemy or enemy bullet
            if other.isEnemy or (other.isBullet and other.isEnemyBullet) then
                self:takeDamage(other.damage or 10)
                
                -- Remove enemy bullet if applicable
                if other.isBullet then
                    display.remove(other)
                    for i = #bulletList, 1, -1 do
                        if bulletList[i] == other then
                            table.remove(bulletList, i)
                            break
                        end
                    end
                end
            end
        end
        return true
    end
    
    defense:addEventListener("collision")
    
    return defense
end

-------------
function scene:startLevel(options)
    -- Debug info - что получили
    print("Debug - Received options in startLevel:")
    for k, v in pairs(options) do
        print("  " .. k .. ": " .. tostring(v))
    end
    
    -- Initialize level parameters
    missionType = options.missionType
    
    -- ИСПРАВЛЕНИЕ: Конвертируем difficulty в число сразу
    local function getDifficultyNumber(difficultyString)
        local difficultyMap = {
            ["easy"] = 1,
            ["medium"] = 2,
            ["hard"] = 3,
            ["extreme"] = 4
        }
        return difficultyMap[difficultyString] or 2
    end
    
    -- Сохраняем как ЧИСЛО, а не строку
    missionDifficulty = getDifficultyNumber(options.difficulty)
    
    -- Для множителей используем отдельную функцию
    local function getDifficultyMultiplier(difficultyNumber)
        local multipliers = {0.7, 1.0, 1.5, 2.0}
        return multipliers[difficultyNumber] or 1.0
    end
    
    local difficultyMultiplier = getDifficultyMultiplier(missionDifficulty)
    
    -- Debug info
    print("Debug - Mission difficulty string:", options.difficulty)
    print("Debug - Mission difficulty number:", missionDifficulty)
    print("Debug - Difficulty multiplier:", difficultyMultiplier)
    
    -- Reset mission state
    missionComplete = false
    missionFailed = false
    score = 0
    kills = 0
    
    -- Initialize mission data for rewards
    missionData = {
        xpEarned = 0,
        fragmentsEarned = 0,
        artifactDropped = false,
        targetKills = 0,  -- будет установлено ниже
        race = options.bossRace or "pirate"  -- ИСПРАВЛЕНИЕ: добавили race
    }
    
    -- Create player
    self:createPlayer()
    
    -- Set mission-specific settings
    if missionType == "clearance" then
        -- Clear all enemies - используем числовой множитель
        missionData.targetKills = math.floor(30 * difficultyMultiplier)
        
        -- Update mission info display
        if statusBars.missionInfo then
            statusBars.missionInfo.text = localization.getText("mission_clearance") ..
                ": 0/" .. missionData.targetKills
        end
        
    elseif missionType == "escort" then
        -- Escort mission
        escortObject = self:createEscortObject()
        missionTimeLimit = math.floor(120 / difficultyMultiplier)  -- Harder = less time
        
        -- Update mission info display
        if statusBars.missionInfo then
            statusBars.missionInfo.text = localization.getText("mission_escort") ..
                ": " .. missionTimeLimit .. "s"
        end
        
    elseif missionType == "defend" then
        -- Defense mission
        defenseObject = self:createDefenseObject()
        missionTimeLimit = math.floor(180 / difficultyMultiplier)  -- Harder = less time
        
        -- Update mission info display
        if statusBars.missionInfo then
            statusBars.missionInfo.text = localization.getText("mission_defend") ..
                ": " .. missionTimeLimit .. "s"
        end
        
    elseif missionType == "boss" then
        -- Boss battle
        print("Debug - Starting boss mission, will spawn boss")
        
        -- Update mission info display
        if statusBars.missionInfo then
            statusBars.missionInfo.text = localization.getText("mission_boss")
        end
        
        -- Спавним босса через небольшую задержку
        timer.performWithDelay(2000, function()
            self:spawnBoss()
        end)
        
    elseif missionType == "survival" then
        -- Survival - last as long as possible
        missionTimeLimit = 240  -- 4 minutes max
        
        -- Make enemies stronger over time - сохраняем числовой множитель
        local survivalMultiplier = difficultyMultiplier * 1.5
        
        -- Update mission info display
        if statusBars.missionInfo then
            statusBars.missionInfo.text = localization.getText("mission_survival") ..
                ": " .. missionTimeLimit .. "s"
        end
    end
    
    -- Start enemy spawning (кроме босс-миссий)
    if missionType ~= "boss" then
        print("Debug - Starting enemy spawning for mission type:", missionType)
        self:spawnEnemies()
    else
        print("Debug - Skipping enemy spawning for boss mission")
    end
    
    -- Start game loop
    gameActive = true
    print("Debug - Game activated, gameActive =", gameActive)
    
    -- Start game loop timer
    if gameLoopTimer then
        timer.cancel(gameLoopTimer)
    end
    gameLoopTimer = timer.performWithDelay(16, function() self:gameLoop() end, 0)
    
    -- Setup touch controls
    self:setupTouchControls()
    
    print("Debug - startLevel completed successfully")
end
-------------
function scene:setupTouchControls()
    -- Remove any previous event listeners
    if self.touchListener then
        Runtime:removeEventListener("touch", self.touchListener)
    end
    
    -- Add touch control for ship movement
    self.touchListener = function(event)
        local phase = event.phase
        
        if phase == "began" or phase == "moved" then
            -- Only process touch in top 2/3 of screen (avoid buttons)
            if event.y < display.contentHeight * 0.7 then
                -- Move ship to touch position with some limits
                local targetX = math.max(30, math.min(display.contentWidth - 30, event.x))
                local targetY = math.max(100, math.min(display.contentHeight - 200, event.y))
                
                playerShip.x = targetX
                playerShip.y = targetY
            end
        end
        
        return true
    end
    
    Runtime:addEventListener("touch", self.touchListener)
end

function scene:pauseGame()
    -- Pause the game
    gameActive = false
    physics.pause()
    
    -- Cancel timers
    if spawnTimer then timer.cancel(spawnTimer) end
    if gameLoopTimer then timer.cancel(gameLoopTimer) end
    
    -- Create pause overlay
    pauseOverlay = display.newRect(uiGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    pauseOverlay:setFillColor(0, 0, 0, 0.7)
    
    -- Pause text
    local pauseText = display.newText({
        parent = uiGroup,
        text = localization.getText("paused"),
        x = display.contentCenterX,
        y = display.contentHeight * 0.3,
        font = native.systemFontBold,
        fontSize = 60
    })
    pauseText:setFillColor(1)
    
    -- Resume button
    local resumeBtn = widget.newButton({
        x = display.contentCenterX,
        y = display.contentHeight * 0.45,
        width = 300,
        height = 80,
        label = localization.getText("resume"),
        fontSize = 30,
        onRelease = function()
            self:resumeGame()
        end
    })
    uiGroup:insert(resumeBtn)
    
    -- Quit button
    local quitBtn = widget.newButton({
        x = display.contentCenterX,
        y = display.contentHeight * 0.6,
        width = 300,
        height = 80,
        label = localization.getText("quit_mission"),
        fontSize = 30,
        onRelease = function()
            -- Clean up and return to hub
            self:cleanupLevel()
            composer.gotoScene("scenes.hub", { effect = "fade", time = 800 })
        end
    })
    uiGroup:insert(quitBtn)
end  -- <-- ВОТ ЭТОТ end ОТСУТСТВОВАЛ!

function scene:resumeGame()
    -- Remove pause overlay elements
    for i = uiGroup.numChildren, 1, -1 do
        local child = uiGroup[i]
        if child == pauseOverlay or child.removePause then
            display.remove(child)
        end
    end
    
    pauseOverlay = nil
    
    -- Resume game activity
    gameActive = true
    physics.start()
    
    -- Restart spawn timer
    self:spawnEnemies()
    
    -- Restart game loop
    gameLoopTimer = timer.performWithDelay(16, function() self:gameLoop() end, 0)
end

function scene:showMissionComplete(success)
    -- Create overlay
    local resultOverlay = display.newRect(uiGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    resultOverlay:setFillColor(0, 0, 0, 0.8)
    
    -- Result text
    local resultText = display.newText({
        parent = uiGroup,
        text = success and localization.getText("mission_complete") or localization.getText("mission_failed"),
        x = display.contentCenterX,
        y = display.contentHeight * 0.25,
        font = native.systemFontBold,
        fontSize = 50
    })
    resultText:setFillColor(success and 0.2 or 1, success and 1 or 0.2, success and 0.2 or 0.2)
    
    -- If successful, show rewards
    if success then
        -- XP earned
        local xpText = display.newText({
            parent = uiGroup,
            text = localization.getText("xp_earned") .. ": " .. missionData.xpEarned,
            x = display.contentCenterX,
            y = display.contentHeight * 0.35,
            font = native.systemFont,
            fontSize = 30
        })
        xpText:setFillColor(0.6, 0.8, 1)
        
        -- Tech fragments earned
        local fragmentsText = display.newText({
            parent = uiGroup,
            text = localization.getText("fragments_earned") .. ": " .. missionData.fragmentsEarned,
            x = display.contentCenterX,
            y = display.contentHeight * 0.42,
            font = native.systemFont,
            fontSize = 30
        })
        fragmentsText:setFillColor(0.9, 0.7, 0)
        
        -- Artifact notification if any was found
        if missionData.artifactDropped then
            local artifactText = display.newText({
                parent = uiGroup,
                text = localization.getText("artifact_found"),
                x = display.contentCenterX,
                y = display.contentHeight * 0.49,
                font = native.systemFontBold,
                fontSize = 30
            })
            artifactText:setFillColor(1, 0.5, 1)
        end
        
        -- Update player data with rewards
        _G.playerData.xp = _G.playerData.xp + missionData.xpEarned
        _G.playerData.techFragments = _G.playerData.techFragments + missionData.fragmentsEarned
        _G.playerData.missions.completed = _G.playerData.missions.completed + 1
        
        -- Reduce available fuel
        _G.playerData.missions.availableFuel = math.max(0, _G.playerData.missions.availableFuel - 1)
        
        -- Check for level up
        if _G.playerData.xp >= _G.playerData.xpToNextLevel then
            _G.playerData.level = _G.playerData.level + 1
            _G.playerData.xp = _G.playerData.xp - _G.playerData.xpToNextLevel
            _G.playerData.xpToNextLevel = math.floor(_G.playerData.xpToNextLevel * 1.5)
            _G.playerData.skillPoints = _G.playerData.skillPoints + 3
            
            -- Show level up notification
            local levelUpText = display.newText({
                parent = uiGroup,
                text = localization.getText("level_up") .. "!",
                x = display.contentCenterX,
                y = display.contentHeight * 0.56,
                font = native.systemFontBold,
                fontSize = 36
            })
            levelUpText:setFillColor(0.2, 1, 0.2)
        end
        
        -- Save game progress
        saveManager.saveGame(_G.playerData)
    end
    
    -- Continue button
    local continueBtn = widget.newButton({
        x = display.contentCenterX,
        y = display.contentHeight * 0.7,
        width = 300,
        height = 80,
        label = localization.getText("continue"),
        fontSize = 30,
        onRelease = function()
            -- Clean up and return to hub
            self:cleanupLevel()
            composer.gotoScene("scenes.hub", { effect = "fade", time = 800 })
        end
    })
    uiGroup:insert(continueBtn)
end

function scene:cleanupLevel()
    -- Cancel all timers
    if spawnTimer then timer.cancel(spawnTimer) end
    if gameLoopTimer then timer.cancel(gameLoopTimer) end
    
    -- Remove event listeners
    if self.touchListener then
        Runtime:removeEventListener("touch", self.touchListener)
        self.touchListener = nil
    end
    
    -- Reset gameplay variables
    gameActive = false
    missionComplete = false
    missionFailed = false
    autoFireActive = false
    
    -- Clean up all game objects
    for i = #enemyList, 1, -1 do
        display.remove(enemyList[i])
    end
    enemyList = {}
    
    for i = #bulletList, 1, -1 do
        display.remove(bulletList[i])
    end
    bulletList = {}
    
    for i = #particleList, 1, -1 do
        display.remove(particleList[i])
    end
    particleList = {}
    
    for i = #playerDrones, 1, -1 do
        display.remove(playerDrones[i])
    end
    playerDrones = {}
    
    -- Remove player ship
    if playerShip then
        display.remove(playerShip)
        playerShip = nil
    end
    
    -- Remove escort/defense objects
    if escortObject then
        if escortObject.healthBar then display.remove(escortObject.healthBar) end
        if escortObject.healthBarBg then display.remove(escortObject.healthBarBg) end
        display.remove(escortObject)
        escortObject = nil
    end
    
    if defenseObject then
        if defenseObject.healthBar then display.remove(defenseObject.healthBar) end
        if defenseObject.healthBarBg then display.remove(defenseObject.healthBarBg) end
        display.remove(defenseObject)
        defenseObject = nil
    end
    
    -- Remove boss-specific UI
    if bossEnemy then
        if bossEnemy.healthBar then display.remove(bossEnemy.healthBar) end
        display.remove(bossEnemy)
        bossEnemy = nil
    end
    
    -- Stop physics
    physics.pause()
end

function scene:show(event)
    local sceneGroup = self.view
    local phase = event.phase
    
    if phase == "will" then
        -- Called when the scene is about to come on screen
        physics.start()
        
    elseif phase == "did" then
        -- Called when the scene is now on screen
        if event.params and event.params.missionType then
            -- Debug info
            print("Debug - Received mission parameters:")
            print("Mission type: " .. tostring(event.params.missionType))
            print("Difficulty: " .. tostring(event.params.difficulty))
            
            -- Validate parameters
            local validatedParams = {
                missionType = event.params.missionType or "clearance",
                difficulty = tonumber(event.params.difficulty) or 2,
                timeLimit = tonumber(event.params.timeLimit) or 0,
                targetKills = tonumber(event.params.targetKills) or 10,
                race = event.params.race or "insect"
            }
            
            print("Debug - Validated parameters:")
            for k, v in pairs(validatedParams) do
                print(k .. ": " .. tostring(v) .. " (" .. type(v) .. ")")
            end
            
            -- Start level with the validated parameters
            self:startLevel(validatedParams)
            
        else
            -- Debug info
            print("Debug - No mission parameters received!")
            
            -- Try using global mission data if available
            if _G.currentMission then
                print("Debug - Using global mission data")
                local validatedParams = {
                    missionType = _G.currentMission.type or "clearance",
                    difficulty = tonumber(_G.currentMission.difficulty) or 2,
                    timeLimit = tonumber(_G.currentMission.timeLimit) or 0,
                    targetKills = tonumber(_G.currentMission.targetKills) or 10,
                    race = _G.currentMission.race or "insect"
                }
                
                self:startLevel(validatedParams)
            else
                -- Fallback to default mission
                print("Debug - Using default mission parameters")
                self:startLevel({
                    missionType = "clearance",
                    difficulty = 2,
                    timeLimit = 0,
                    targetKills = 10,
                    race = "insect"
                })
            end
        end
    end
end


function scene:hide(event)
    local sceneGroup = self.view
    local phase = event.phase
    
    if phase == "will" then
        -- Called when the scene is about to go off screen
        self:cleanupLevel()
    elseif phase == "did" then
        -- Called when the scene is now off screen
    end
end

function scene:destroy(event)
    local sceneGroup = self.view
    
    -- Clean up any saved references
    self:cleanupLevel()
    
    -- Stop physics
    physics.stop()
end

-- Scene event listeners
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
