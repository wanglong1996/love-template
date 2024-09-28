
if arg[2] == "debug" then
    require("lldebugger").start()
end

_G.love = require('love')
_G.lume = require('lib.lume')
_G.mlib = require('lib.mlib')
_G.utf8 = require('lib.utf8')
_G.vec2 = require('lib.vector')

require('lib.class')
require('lib.table')
require('lib.math')
require('lib.random')
require('lib.funcs')
require('lib.trigger')
require('global')

-- active project
require('project001.main')


;(function()

    _G.Input = require('lib.input')
    _G.GS = require('lib.gamestate')
    _G.Signal = require('lib.signal')
    _G.Camera = require('lib.camera')
end)()

local timer = love.timer
_G.tick = {
    framerate = 120, -- 每秒可发生最大帧数，draw的调用次数，为nil时无限制。
    rate = .01,      -- 限制love.update的调用次数。是传给update的dt
    timescale = 1,   -- 时间缩放
    sleep = .001,
    dt = 0,
    accum = 0,
    tick = 1,
    frame = 1
}

function love.run()
    _G.input = Input()
    _G.random = Random()
    input:bind('left_click', {'mouse:1'})
    input:bind('right_click', {'mouse:2'})
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
    love.math.setRandomSeed(os.time())
    math.randomseed(os.time())

    local lastframe = 0
    if love.update then love.update(0) end

    _G.TIME = 0
	-- Main loop time.
	return function()
		-- Process events.
        
		tick.dt = timer.step() * tick.timescale
        tick.accum = tick.accum + tick.dt
        
        while tick.accum >= tick.rate do
            tick.accum = tick.accum - tick.rate
            if love.event then
                love.event.pump()
                -- 具体参数意义查看相应回调函数，love.mousepressed(x,y,button,istouch, presses)
                for name, a,b,c,d,e,f in love.event.poll() do
                    if name == "quit" then
                        if not love.quit or not love.quit() then
                            return a or 0
                        end
                    elseif name == 'keypressed' then
                        input.input_keyboard_state[a] = true
                    elseif name == 'keyreleased' then
                        input.input_keyboard_state[a] = false
                    elseif name == 'mousepressed' then
                        input.input_mouse_state[c] = true
                    elseif name == 'mousereleased' then
                        input.input_mouse_state[c] = false
                    elseif name == 'wheelmoved' then --Mouse wheel moved
                        if b >= 1 then input.input_mouse_state.wheel_up = true end
                        if b <= -1 then input.input_mouse_state.wheel_down = true end
                    elseif name == 'gamepadpressed' then
                        input.input_gamepad_state[b] = true
                    elseif name == 'gamepadreleased' then
                        input.input_gamepad_state[b] = false
                    elseif name == 'gamepadaxis' then
                        -- input.input_gamepad_state[b] = math.abs(c) > 0.5 and c or false
                    elseif name == 'joystickadded' then -- 手柄连接
                        input.input_gamepad = a
                    elseif name == 'joystickremoved' then
                        input.input_gamepad = nil
                    end
                    love.handlers[name](a,b,c,d,e,f)
                end
            end
            tick.tick = tick.tick + 1
            if love.update then
                love.update(tick.rate)
            end
            input:update(tick.rate)
            input:input_post_update()
            
            TIME = TIME + tick.rate
        end

        while tick.framerate and timer.getTime() - lastframe < 1/tick.framerate do
            timer.sleep(0.0005)
        end

		lastframe = timer.getTime()

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
            tick.frame = tick.frame + 1
			if love.draw then love.draw() end

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(tick.sleep) end
	end
end