---@class love
local love = require('love')
require('project001.scene.menu')
require('project001.scene.game')
require('project001.game.asset_db')

function love.load()
    Fontdb:load()
    signal = Signal()
    trigger = Trigger()


    GS.registerEvents()
    GS.switch(Menu, 'hello')

end


function love.update(dt)
    trigger:update(dt)
end

function love.draw()

end