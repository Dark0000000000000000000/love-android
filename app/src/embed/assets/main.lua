-- PlayPlayground
-- main.lua

-- ============================================
-- 1. КОНСТАНТЫ И ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ============================================

local SCREEN_WIDTH = 800
local SCREEN_HEIGHT = 600

-- Цвета
local WHITE = {1, 1, 1}
local RED = {1, 0, 0}
local BLACK = {0, 0, 0}
local YELLOW = {1, 0.84, 0}

-- Физические параметры
local FRICTION = 0.93
local BOUNCE_COEFF = -0.7
local HIT_FORCE_MULTIPLIER = 0.3
local MAX_DAMAGE = 20

-- Игровые переменные
local coins = 0
local gameState = "MENU"
local screenFlashTimer = 0

-- Ресурсы (изображения)
local bgImage
local playerImage
local coinImage

-- Шрифты
local fontSmall
local fontLarge

-- Игровые объекты
local player
local coin

-- Управление перетаскиванием
local dragging = false
local dragStartX, dragStartY = 0, 0
local playerStartX, playerStartY = 0, 0

-- Кнопки меню
local btnStart = {x = 50, y = 50, width = 150, height = 50}
local btnExit = {x = 50, y = 120, width = 150, height = 50}

-- ============================================
-- 2. КЛАСС ИГРОКА (Player)
-- ============================================

Player = {}
Player.__index = Player

function Player:new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.size = 100
    self.hp = 100
    self.isAlive = true
    self.velocityX = 0
    self.velocityY = 0
    self.respawnTimer = 0
    self.respawnDelay = 2.0 -- секунды
    return self
end

function Player:respawn()
    self.hp = 100
    self.isAlive = true
    self.x = SCREEN_WIDTH / 2 - self.size / 2
    self.y = SCREEN_HEIGHT / 2 - self.size / 2
    self.velocityX = 0
    self.velocityY = 0
end

function Player:onPlayerHit(damage)
    if not self.isAlive or damage == 0 then
        return
    end

    self.hp = self.hp - damage
    screenFlashTimer = 0.25 -- четверть секунды вспышки

    if self.hp <= 0 then
        self.hp = 0
        self.isAlive = false
        coins = coins + 10
        saveCoins(coins)
        self.respawnTimer = self.respawnDelay
    end
end

function Player:updatePhysics(dt)
    if not self.isAlive then
        self.respawnTimer = self.respawnTimer - dt
        if self.respawnTimer <= 0 then
            self:respawn()
        end
        return
    end

    -- Обновление позиции
    self.x = self.x + self.velocityX
    self.y = self.y + self.velocityY

    -- Применение трения
    self.velocityX = self.velocityX * FRICTION
    self.velocityY = self.velocityY * FRICTION

    -- Остановка при малой скорости
    if math.abs(self.velocityX) < 0.1 then self.velocityX = 0 end
    if math.abs(self.velocityY) < 0.1 then self.velocityY = 0 end

    -- Проверка столкновений со стенами
    local hitOccurred = false
    local prevVX = self.velocityX
    local prevVY = self.velocityY

    -- Левая и правая стены
    if self.x < 0 then
        self.x = 0
        self.velocityX = self.velocityX * BOUNCE_COEFF
        hitOccurred = true
    elseif self.x + self.size > SCREEN_WIDTH then
        self.x = SCREEN_WIDTH - self.size
        self.velocityX = self.velocityX * BOUNCE_COEFF
        hitOccurred = true
    end

    -- Верхняя и нижняя стены
    if self.y < 0 then
        self.y = 0
        self.velocityY = self.velocityY * BOUNCE_COEFF
        hitOccurred = true
    elseif self.y + self.size > SCREEN_HEIGHT then
        self.y = SCREEN_HEIGHT - self.size
        self.velocityY = self.velocityY * BOUNCE_COEFF
        hitOccurred = true
    end

    -- Урон от столкновения
    if hitOccurred then
        local forceAtImpact = math.sqrt(prevVX * prevVX + prevVY * prevVY)
        local damage = math.floor(forceAtImpact * 2)
        self:onPlayerHit(math.min(damage, MAX_DAMAGE))
    end
end

function Player:draw()
    if self.isAlive then
        if playerImage then
            -- Вычисляем масштаб (нужный размер / размер картинки)
            local scaleX = self.size / playerImage:getWidth()
            local scaleY = self.size / playerImage:getHeight()
            
            -- Рисуем с масштабом
            love.graphics.draw(playerImage, self.x, self.y, 0, scaleX, scaleY)
        else
            love.graphics.setColor(RED)
            love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)
            love.graphics.setColor(WHITE)
        end
    end
end
function Player:containsPoint(px, py)
    return px >= self.x and px <= self.x + self.size and
           py >= self.y and py <= self.y + self.size
end

function Player:collidesWith(other)
    return self.x < other.x + other.size and
           self.x + self.size > other.x and
           self.y < other.y + other.size and
           self.y + self.size > other.y
end

-- ============================================
-- 3. КЛАСС МОНЕТЫ (Coin)
-- ============================================

Coin = {}
Coin.__index = Coin

function Coin:new()
    local self = setmetatable({}, Coin)
    self.size = 80
    self:spawn()
    return self
end

function Coin:spawn()
    local maxX = SCREEN_WIDTH - self.size
    local maxY = SCREEN_HEIGHT - self.size
    self.x = math.random(0, maxX)
    self.y = math.random(0, maxY)
end

function Coin:draw()
    if coinImage then
        -- Вычисляем масштаб: игровой размер (80) делим на реальную ширину картинки
        local scaleX = self.size / coinImage:getWidth()
        local scaleY = self.size / coinImage:getHeight()
        
        love.graphics.setColor(WHITE) -- Сбрасываем цвет в белый, чтобы картинка была яркой
        love.graphics.draw(coinImage, self.x, self.y, 0, scaleX, scaleY)
    else
        -- Если картинки нет, рисуем желтый круг
        love.graphics.setColor(YELLOW)
        love.graphics.circle("fill", self.x + self.size/2, self.y + self.size/2, self.size/2)
        love.graphics.setColor(WHITE)
    end
end
-- ============================================
-- 4. ФУНКЦИИ СОХРАНЕНИЯ
-- ============================================

function loadCoins()
    local saveData = love.filesystem.read("savegame.txt")
    if saveData then
        local value = tonumber(saveData)
        return value or 0
    end
    return 0
end

function saveCoins(amount)
    love.filesystem.write("savegame.txt", tostring(amount))
end

-- ============================================
-- 5. ФУНКЦИИ UI
-- ============================================

function drawHPBar(x, y, hp, maxHP)
    maxHP = maxHP or 100
    local barMaxWidth = 200
    local barHeight = 20
    local fill = (hp / maxHP) * barMaxWidth

    -- Обводка
    love.graphics.setColor(BLACK)
    love.graphics.rectangle("line", x, y, barMaxWidth, barHeight)
    
    -- Заполнение
    love.graphics.setColor(RED)
    love.graphics.rectangle("fill", x, y, fill, barHeight)
    
    love.graphics.setColor(WHITE)
end

function drawButton(btn, text)
    love.graphics.setColor(WHITE)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)
    love.graphics.setColor(BLACK)
    love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height)
    love.graphics.printf(text, fontSmall, btn.x, btn.y + 15, btn.width, "center")
    love.graphics.setColor(WHITE)
end

function isPointInButton(btn, x, y)
    return x >= btn.x and x <= btn.x + btn.width and
           y >= btn.y and y <= btn.y + btn.height
end

-- ============================================
-- 6. LOVE2D CALLBACKS
-- ============================================

function love.load()
    -- Установка размера окна
   local windowWidth, windowHeight = love.graphics.getDimensions()
    
    -- 2. Обновляем наши глобальные константы
    SCREEN_WIDTH = windowWidth
    SCREEN_HEIGHT = windowHeight

    -- 3. Если хочешь, чтобы игра всегда была альбомной (горизонтальной)
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, {
        resizable = true,
        vsync = true,
        fullscreentype = "desktop"
    })
    love.window.setTitle("PlayPlayground")
    
    -- Загрузка изображений (если они есть)
    -- Для Android нужно положить файлы в папку с игрой
    local success
    
    success, bgImage = pcall(love.graphics.newImage, "bg_room.png")
    if not success then bgImage = nil end
    
    success, playerImage = pcall(love.graphics.newImage, "player_texture.jpg")
    if success then
        -- Масштабирование текстуры игрока
        local scale = 100 / playerImage:getWidth()
        playerImage = love.graphics.newImage("player_texture.jpg")
        -- Для правильного масштабирования создадим новый Image
    else
        playerImage = nil
    end
    
    success, coinImage = pcall(love.graphics.newImage, "coin_texture.png")
    if not success then coinImage = nil end
    
    -- Загрузка шрифтов
    fontSmall = love.graphics.newFont(24)
    fontLarge = love.graphics.newFont(48)
    
    -- Инициализация игровых объектов
    coins = loadCoins()
    player = Player:new(SCREEN_WIDTH / 2 - 50, SCREEN_HEIGHT / 2 - 50)
    coin = Coin:new()
    
    -- Для Android: включить тач-ввод
    -- love.touch.setTapDelay(0)
end

function love.update(dt)
    if gameState == "PLAYING" then
        player:updatePhysics(dt)
        
        -- Проверка коллизии с монетой
        if player.isAlive and player:collidesWith(coin) then
            coins = coins + 1
            saveCoins(coins)
            coin:spawn()
        end
        
        -- Обновление вспышки
        if screenFlashTimer > 0 then
            screenFlashTimer = screenFlashTimer - dt
        end
    end
end

function love.draw()
    -- Рисуем фон
    if bgImage then
        love.graphics.draw(bgImage, 0, 0, 0, SCREEN_WIDTH / bgImage:getWidth(), SCREEN_HEIGHT / bgImage:getHeight())
    else
        love.graphics.clear(0.9, 0.9, 0.9)
    end
    
    if gameState == "PLAYING" then
        -- Рисуем монету
        coin:draw()
        
        -- Рисуем игрока
        player:draw()
        
        -- UI
        drawHPBar(16, 16, player.hp)
        love.graphics.setColor(BLACK)
        love.graphics.print("Coins: " .. coins, fontSmall, SCREEN_WIDTH - 150, 16)
        love.graphics.setColor(WHITE)
        
        -- Красная вспышка при уроне
        if screenFlashTimer > 0 then
            local alpha = screenFlashTimer / 0.25
            love.graphics.setColor(1, 0, 0, alpha * 0.5)
            love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
            love.graphics.setColor(WHITE)
        end
        
        -- Сообщение о возрождении
        if not player.isAlive then
            love.graphics.setColor(BLACK)
            love.graphics.printf("", fontLarge, 0, SCREEN_HEIGHT / 2 - 24, SCREEN_WIDTH, "center")
            love.graphics.setColor(WHITE)
        end
        
    elseif gameState == "MENU" then
        -- Главное меню
        love.graphics.setColor(BLACK)
        love.graphics.printf("PlayPlayground", fontLarge, 0, SCREEN_HEIGHT / 4 - 24, SCREEN_WIDTH, "center")
        love.graphics.setColor(WHITE)
        
        -- Кнопки
        drawButton(btnStart, "Start")
        drawButton(btnExit, "Exit")
    end
end

-- ============================================
-- 7. ОБРАБОТКА ВВОДА (МЫШЬ И ТАЧ)
-- ============================================

function love.mousepressed(x, y, button)
    if button == 1 then -- Левая кнопка мыши
        handleTouchPress(x, y)
    end
end

function love.mousemoved(x, y, dx, dy)
    if dragging then
        handleTouchMove(x, y)
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        handleTouchRelease(x, y)
    end
end

-- Для Android: обработка тач-событий
function love.touchpressed(id, x, y)
    handleTouchPress(x, y)
end

function love.touchmoved(id, x, y)
    if dragging then
        handleTouchMove(x, y)
    end
end

function love.touchreleased(id, x, y)
    handleTouchRelease(x, y)
end

-- Универсальные функции обработки
function handleTouchPress(x, y)
    if gameState == "MENU" then
        if isPointInButton(btnStart, x, y) then
            gameState = "PLAYING"
        elseif isPointInButton(btnExit, x, y) then
            love.event.quit()
        end
    elseif gameState == "PLAYING" then
        if player.isAlive and player:containsPoint(x, y) then
            dragging = true
            player.velocityX = 0
            player.velocityY = 0
            dragStartX = x
            dragStartY = y
            playerStartX = player.x
            playerStartY = player.y
        end
    end
end

function handleTouchMove(x, y)
    if dragging and gameState == "PLAYING" then
        local deltaX = x - dragStartX
        local deltaY = y - dragStartY
        
        local newX = playerStartX + deltaX
        local newY = playerStartY + deltaY
        
        -- Ограничение движения в пределах экрана
        player.x = math.max(0, math.min(newX, SCREEN_WIDTH - player.size))
        player.y = math.max(0, math.min(newY, SCREEN_HEIGHT - player.size))
    end
end

function handleTouchRelease(x, y)
    if dragging and gameState == "PLAYING" then
        dragging = false
        player.velocityX = (x - dragStartX) * HIT_FORCE_MULTIPLIER
        player.velocityY = (y - dragStartY) * HIT_FORCE_MULTIPLIER
    end
end

-- ============================================
-- 8. ВЫХОД ИЗ ИГРЫ
-- ============================================

function love.quit()
    saveCoins(coins)
end