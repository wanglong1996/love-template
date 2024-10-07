Menu = {}

function Menu:init()
    self.camera = Camera()
end

function Menu:enter(from, args)
    log.info("hello %s man", "hello")
    self.font = Fontdb:get('Verdana', 32)
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
    love.graphics.setFont(self.font)
    love.graphics.print('hello')
    self.camera:detach()
end

function Menu:leave()
    
end



