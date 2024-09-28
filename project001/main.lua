---@class love
local love = require('love')
require('project001.scene.menu')
require('project001.scene.game')

function love.load()
    print('hello')
    local arr = {}
    for i = 1, 10000 do
        local x = random:weighted_choice({A=30, B=20, C=50})
        table.insert(arr, x)
    end
    log.info(table.count(arr, 'A'))
    log.info(table.count(arr, 'B'))
    log.info(table.count(arr, 'C'))
    local _meta = {
        name = 'parent'
    }
    _meta.__index = _meta
    local tb1 = setmetatable({}, _meta)
    
    rawset(tb1, 'name', 'child')
    print(tb1.name)

    signal = Signal()

    signal:register('shoot', function ()
        print('shoot')
    end)

    signal:emitPattern('^sho.')
    print(string.len('中国'))
    print(utf8.len("中国"))
    print(utf8.sub("中国文字!", 2,-3))
    print(string.sub("中国文字", 1, 4))
    local tb1 = {x='name',2,3}
    lume.push(tb1, 4,"a",6)
    print(tb1)
    print(select(3, unpack(tb1)))
    print(math.in_polygon(150,51, 100,0,200,0,100,100))
    curve = love.math.newBezierCurve({100,0,200,0,100,100})

    trigger = Trigger()
    trigger:after(1.2, function ()
        print("hello world")
    end)

    GS.registerEvents()
    GS.switch(Menu, 'hello')

end


function love.update(dt)
    trigger:update(dt)
end

function love.draw()
    love.graphics.line(curve:render())
end