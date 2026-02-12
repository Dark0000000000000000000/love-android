-- conf.lua
-- Конфигурация для LOVE2D

function love.conf(t)
    t.identity = "playplayground"              -- Имя папки для сохранений
    t.appendidentity = false                    
    t.version = "11.4"                         -- Версия LOVE2D
    t.console = false                          -- Консоль для отладки (только Windows)
    t.accelerometerjoystick = true             -- Акселерометр как джойстик (Android)
    t.externalstorage = false                  
    t.gammacorrect = false                     

    t.audio.mic = false                        -- Микрофон не нужен
    t.audio.mixwithsystem = true               -- Микшировать с системными звуками

    t.window.title = "PlayPlayground"          -- Название окна
    t.window.icon = nil                        -- Иконка
    t.window.width = 800                       -- Ширина окна
    t.window.height = 600                      -- Высота окна
    t.window.borderless = false                -- Без рамки
    t.window.resizable = false                 -- Изменение размера
    t.window.minwidth = 1                      
    t.window.minheight = 1                     
    t.window.fullscreen = false                -- Полноэкранный режим (на Android автоматически)
    t.window.fullscreentype = "desktop"        
    t.window.vsync = 1                         -- Вертикальная синхронизация
    t.window.msaa = 0                          -- Сглаживание
    t.window.depth = nil                       
    t.window.stencil = nil                     
    t.window.display = 1                       
    t.window.highdpi = false                   -- Высокий DPI
    t.window.usedpiscale = true                
    t.window.x = nil                           
    t.window.y = nil                           

    t.modules.audio = true                     -- Включить аудио (для будущих звуков)
    t.modules.data = true                      
    t.modules.event = true                     
    t.modules.font = true                      
    t.modules.graphics = true                  
    t.modules.image = true                     
    t.modules.joystick = true                  
    t.modules.keyboard = true                  
    t.modules.math = true                      
    t.modules.mouse = true                     
    t.modules.physics = false                  -- Физика Box2D не нужна
    t.modules.sound = true                     
    t.modules.system = true                    
    t.modules.thread = true                    
    t.modules.timer = true                     
    t.modules.touch = true                     -- Touch для Android
    t.modules.video = false                    -- Видео не нужно
    t.modules.window = true                    
    t.window.resizable = true -- Позволяет менять размер
    t.window.highdpi = true    -- Важно для четкости на телефонах
end