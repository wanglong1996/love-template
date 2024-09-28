Menu = {}
class = require('lib.middleclass')
function Menu:init()
    self.camera = Camera()
end

function Menu:enter(from, args)
    
    
end
local function myStencilFunction()
    love.graphics.rectangle("fill", 225, 200, 350, 300)
end

function Menu:update(dt)
    self.camera:update(dt)
    if input:pressed('left_click') then
        print('ok')
        self.camera:shake(0.4, 5, 120, "Y")
    end
end

function Menu:draw()
    self.camera:attach()
    -- love.graphics.circle('line', 400, 300, 50)

    -- draw a rectangle as a stencil. Each pixel touched by the rectangle will have its stencil value set to 1. The rest will be 0.
    love.graphics.stencil(myStencilFunction, "replace", 1)


    -- Only allow rendering on pixels which have a stencil value greater than 0.
    love.graphics.setStencilTest("greater", 0)

    love.graphics.setColor(1, 0, 0, 0.45)
    love.graphics.circle("fill", 300, 300, 150, 50)

    -- love.graphics.setColor(0, 1, 0, 0.45)
    -- love.graphics.circle("fill", 500, 300, 150, 50)

    -- love.graphics.setColor(0, 0, 1, 0.45)
    -- love.graphics.circle("fill", 400, 400, 150, 50)

    love.graphics.setStencilTest()
    self.camera:detach()
end

function Menu:leave()
    
end



