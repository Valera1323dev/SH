-------------------------------------------------------------------------------------------
-- Panel UI Component
-- Creates styled content panels and containers
-- Компонент UI панели
-- Создает стилизованные панели содержимого и контейнеры
-------------------------------------------------------------------------------------------
-- В начале файла panel.lua добавьте:
local widget = require("widget")
local constants = require("gamelogic.constants")
local panel = {}

-- Create a basic panel with standard styling
-- Создание базовой панели со стандартным стилем
function panel.create(options)
    local params = options or {}
    
    -- Apply default values for missing options
    -- Применяем значения по умолчанию для отсутствующих опций
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local width = params.width or 300
    local height = params.height or 200
    local cornerRadius = params.cornerRadius or 12
    local fillColor = params.fillColor or {0.15, 0.15, 0.2, 0.9}
    local strokeColor = params.strokeColor or {1, 1, 1, 0.3}
    local strokeWidth = params.strokeWidth or 2
    
    -- Create the panel container
    -- Создаем контейнер панели
    local panelGroup = display.newGroup()
    
    -- Create the background rectangle
    -- Создаем фоновый прямоугольник
    local bg = display.newRoundedRect(panelGroup, 0, 0, width, height, cornerRadius)
    bg:setFillColor(unpack(fillColor))
    bg:setStrokeColor(unpack(strokeColor))
    bg.strokeWidth = strokeWidth
    
    -- Position the panel
    -- Позиционируем панель
    panelGroup.x = x
    panelGroup.y = y
    panelGroup.width = width
    panelGroup.height = height
    
    -- Add to parent group if specified
    -- Добавляем в родительскую группу, если указана
    if parent then
        parent:insert(panelGroup)
    end
    
    return panelGroup
end

-- Create a panel with a title
-- Создание панели с заголовком
function panel.createWithTitle(options)
    local params = options or {}
    
    -- Apply default values for missing options
    -- Применяем значения по умолчанию для отсутствующих опций
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local width = params.width or 300
    local height = params.height or 200
    local title = params.title or "Panel Title"
    local titleColor = params.titleColor or constants.UI.COLORS.WHITE
    local titleFont = params.titleFont or constants.UI.FONTS.BOLD
    local titleFontSize = params.titleFontSize or 24
    local cornerRadius = params.cornerRadius or 12
    local fillColor = params.fillColor or {0.15, 0.15, 0.2, 0.9}
    local strokeColor = params.strokeColor or {1, 1, 1, 0.3}
    local strokeWidth = params.strokeWidth or 2
    
    -- Create the panel group
    -- Создаем группу панели
    local panelGroup = display.newGroup()
    
    -- Create the background rectangle
    -- Создаем фоновый прямоугольник
    local bg = display.newRoundedRect(panelGroup, 0, 0, width, height, cornerRadius)
    bg:setFillColor(unpack(fillColor))
    bg:setStrokeColor(unpack(strokeColor))
    bg.strokeWidth = strokeWidth
    
    -- Create title background
    -- Создаем фон заголовка
    local titleHeight = titleFontSize * 2
    -- ИСПРАВЛЕНО: Передаем cornerRadius как число, а не таблицу
    local titleBg = display.newRoundedRect(
        panelGroup, 
        0, 
        -height/2 + titleHeight/2, 
        width, 
        titleHeight, 
        cornerRadius -- Было: {cornerRadius, cornerRadius, 0, 0}
    )
    titleBg:setFillColor(unpack(strokeColor))
    
    -- Create title text
    -- Создаем текст заголовка
    local titleText = display.newText({
        parent = panelGroup,
        text = title,
        x = 0,
        y = -height/2 + titleHeight/2,
        font = titleFont,
        fontSize = titleFontSize
    })
    titleText:setFillColor(unpack(titleColor))
    
    -- Store content area measurements
    -- Сохраняем размеры области содержимого
    panelGroup.contentWidth = width
    panelGroup.contentHeight = height - titleHeight
    panelGroup.contentY = titleHeight/2
    
    -- Position the panel
    -- Позиционируем панель
    panelGroup.x = x
    panelGroup.y = y
    panelGroup.width = width
    panelGroup.height = height
    
    -- Store reference to title for later updates
    -- Сохраняем ссылку на заголовок для последующих обновлений
    panelGroup.title = titleText
    
    -- Add to parent group if specified
    -- Добавляем в родительскую группу, если указана
    if parent then
        parent:insert(panelGroup)
    end
    
    return panelGroup
end

-- Create a scrollable panel
-- Создание прокручиваемой панели
function panel.createScrollable(options)
    local params = options or {}
    
    -- Apply default values for missing options
    -- Применяем значения по умолчанию для отсутствующих опций
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local width = params.width or 300
    local height = params.height or 200
    local cornerRadius = params.cornerRadius or 12
    local fillColor = params.fillColor or {0.15, 0.15, 0.2, 0.9}
    local strokeColor = params.strokeColor or {1, 1, 1, 0.3}
    local strokeWidth = params.strokeWidth or 2
    local topPadding = params.topPadding or 10
    local bottomPadding = params.bottomPadding or 10
    local horizontalScrollingEnabled = params.horizontalScrollingEnabled or false
    
    -- Create the panel container
    -- Создаем контейнер панели
    local panelGroup = display.newGroup()
    
    -- Create the background rectangle
    -- Создаем фоновый прямоугольник
    local bg = display.newRoundedRect(panelGroup, 0, 0, width, height, cornerRadius)
    bg:setFillColor(unpack(fillColor))
    bg:setStrokeColor(unpack(strokeColor))
    bg.strokeWidth = strokeWidth
    
    -- Create the scroll view container
    -- Создаем контейнер прокрутки
    local scrollView = widget.newScrollView({
        x = 0,
        y = 0,
        width = width - 20, -- Subtract for padding / Вычитаем для отступа
        height = height - 20, -- Subtract for padding / Вычитаем для отступа
        scrollWidth = width - 20,
        horizontalScrollDisabled = not horizontalScrollingEnabled,
        hideBackground = true,
        hideScrollBar = false,
        topPadding = topPadding,
        bottomPadding = bottomPadding,
        verticalScrollingEnabled = true
    })
    
    panelGroup:insert(scrollView)
    
    -- Position the panel
    -- Позиционируем панель
    panelGroup.x = x
    panelGroup.y = y
    panelGroup.width = width
    panelGroup.height = height
    
    -- Store the scroll view for content insertion
    -- Сохраняем scrollView для вставки содержимого
    panelGroup.scrollView = scrollView
    
    -- Add to parent group if specified
    -- Добавляем в родительскую группу, если указана
    if parent then
        parent:insert(panelGroup)
    end
    
    return panelGroup
end

-- Create a tabbed panel
-- Создание панели с вкладками
function panel.createTabbed(options)
    local params = options or {}
    
    -- Apply default values for missing options
    -- Применяем значения по умолчанию для отсутствующих опций
    local parent = params.parent
    local x = params.x or display.contentCenterX
    local y = params.y or display.contentCenterY
    local width = params.width or 300
    local height = params.height or 200
    local cornerRadius = params.cornerRadius or 12
    local tabs = params.tabs or {"Tab 1", "Tab 2"}
    local initialTab = params.initialTab or 1
    local fillColor = params.fillColor or {0.15, 0.15, 0.2, 0.9}
    local strokeColor = params.strokeColor or {1, 1, 1, 0.3}
    local strokeWidth = params.strokeWidth or 2
    local tabColor = params.tabColor or constants.UI.COLORS.GRAY
    local activeTabColor = params.activeTabColor or constants.UI.COLORS.BLUE
    local onTabChange = params.onTabChange
    
    -- Create the panel container
    -- Создаем контейнер панели
    local panelGroup = display.newGroup()
    
    -- Create the background rectangle
    -- Создаем фоновый прямоугольник
    local bg = display.newRoundedRect(panelGroup, 0, 0, width, height, cornerRadius)
    bg:setFillColor(unpack(fillColor))
    bg:setStrokeColor(unpack(strokeColor))
    bg.strokeWidth = strokeWidth
    
    -- Create tab container
    -- Создаем контейнер вкладок
    local tabHeight = 40
    local tabsGroup = display.newGroup()
    panelGroup:insert(tabsGroup)
    tabsGroup.y = -height/2 + tabHeight/2
    
    -- Track current active tab
    -- Отслеживаем текущую активную вкладку
    panelGroup.activeTab = initialTab
    
    -- Create content area for each tab
    -- Создаем область содержимого для каждой вкладки
    panelGroup.tabContents = {}
    
    for i = 1, #tabs do
        local tabContent = display.newGroup()
        tabContent.x = 0
        tabContent.y = tabHeight/2
        panelGroup:insert(tabContent)
        
        -- Hide all except initial tab
        -- Скрываем все, кроме начальной вкладки
        tabContent.isVisible = (i == initialTab)
        
        -- Store in tab contents array
        -- Сохраняем в массиве содержимого вкладок
        panelGroup.tabContents[i] = tabContent
    end
    
    -- Create tab buttons
    -- Создаем кнопки вкладок
    panelGroup.tabButtons = {}
    local tabWidth = width / #tabs
    
    for i = 1, #tabs do
        local tabX = -width/2 + tabWidth/2 + (i-1) * tabWidth
        
        -- Create tab background
        -- Создаем фон вкладки
        local tabBg = display.newRect(tabsGroup, tabX, 0, tabWidth, tabHeight)
        tabBg:setFillColor(unpack(i == initialTab and activeTabColor or tabColor))
        
        -- Create tab label
        -- Создаем метку вкладки
        local tabLabel = display.newText({
            parent = tabsGroup,
            text = tabs[i],
            x = tabX,
            y = 0,
            font = constants.UI.FONTS.REGULAR,
            fontSize = 20
        })
        tabLabel:setFillColor(1)
        
        -- Create tab handler
        -- Создаем обработчик вкладки
        tabBg.index = i
        tabBg.touch = function(self, event)
            if event.phase == "ended" then
                panelGroup:switchToTab(self.index)
            end
            return true
        end
        tabBg:addEventListener("touch")
        
        -- Store tab button reference
        -- Сохраняем ссылку на кнопку вкладки
        panelGroup.tabButtons[i] = {bg = tabBg, label = tabLabel}
    end
    
    -- Add tab switching function
    -- Добавляем функцию переключения вкладок
    function panelGroup:switchToTab(index)
        -- Only proceed if this is a different tab
        -- Продолжаем только если это другая вкладка
        if index ~= self.activeTab then
            -- Update tab visuals
            -- Обновляем визуальное отображение вкладок
            for i = 1, #tabs do
                self.tabButtons[i].bg:setFillColor(unpack(i == index and activeTabColor or tabColor))
                self.tabContents[i].isVisible = (i == index)
            end
            
            -- Update active tab
            -- Обновляем активную вкладку
            local oldTab = self.activeTab
            self.activeTab = index
            
            -- Call callback if provided
            -- Вызываем обратный вызов, если он предоставлен
            if onTabChange then
                onTabChange(index, oldTab)
            end
        end
    end
    
    -- Position the panel
    -- Позиционируем панель
    panelGroup.x = x
    panelGroup.y = y
    panelGroup.width = width
    panelGroup.height = height
    
    -- Store content area measurements
    -- Сохраняем размеры области содержимого
    panelGroup.contentWidth = width
    panelGroup.contentHeight = height - tabHeight
    
    -- Add to parent group if specified
    -- Добавляем в родительскую группу, если указана
    if parent then
        parent:insert(panelGroup)
    end
    
    return panelGroup
end

return panel
