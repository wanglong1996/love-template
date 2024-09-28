local input = {}
input.__index = input
table.unpack = table.unpack or unpack
local function new()
    love.joystick.loadGamepadMappings('resources/gamecontrollerdb.txt')
    return setmetatable({
        input_actions = {},
        input_state = {},
        input_sequence_state = {},
        input_keyboard_state = {},
        input_previous_keyboard_state = {},
        input_mouse_state = {},
        input_previous_mouse_state = {},
        input_gamepad_state = {},
        input_previous_gamepad_state = {},
        input_last_type = nil,
        input_gamepad = love.joystick.getJoysticks()[1],
        input_deadzone = 0.5,
        key_repeat_state = {},
        mouse_repeat_state = {},
        gamepad_repeat_state = {},
    }, input)
end

function input:update(dt)

    for _, action in ipairs(self.input_actions) do
        self.input_state[action].pressed = false
        self.input_state[action].down = false
        self.input_state[action].released = false
    end

    for _, s in ipairs({self.key_repeat_state, self.mouse_repeat_state, self.gamepad_repeat_state}) do
        for _, v in pairs(s) do
            if v then
                v.pressed = false
                local t = love.timer.getTime() - v.pressed_time
                if t > v.interval then
                    v.pressed = true
                    v.pressed_time = love.timer.getTime()
                end
            end
        end
    end

    for _, action in ipairs(self.input_actions) do
        for _,control in ipairs(self.input_state[action].controls) do
            local action_type, key = table.unpack(control)
            if action_type == 'key' then
                -- pressed，即使长按也算一次，可手动设置.pressed为true模拟，多个按键其一触发即可
                self.input_state[action].pressed = self.input_state[action].pressed or 
                    (self.input_keyboard_state[key] and not self.input_previous_keyboard_state[key])
                self.input_state[action].down = self.input_state[action].down or
                    self.input_keyboard_state[key]
                -- 上一帧为true，当前帧为false，视为
                self.input_state[action].released = self.input_state[action].released or
                    (not self.input_keyboard_state[key] and self.input_previous_keyboard_state[key])
                if self.input_state[action].released then self.key_repeat_state[key] = false end
            elseif action_type == 'mouse' then
                if key == 'wheel_up' or key == 'wheel_down' then
                    self.input_state[action].pressed = self.input_mouse_state[key]
                else
                    self.input_state[action].pressed = self.input_state[action].pressed or
                        (self.input_mouse_state[tonumber(key)] and not self.input_previous_mouse_state[tonumber(key)])
                    self.input_state[action].down = self.input_state[action].down or
                        self.input_mouse_state[tonumber(key)]
                    self.input_state[action].released = self.input_state[action].released or
                        (not self.input_mouse_state[tonumber(key)] and self.input_previous_mouse_state[tonumber(key)])
                    if self.input_state[action].released then self.mouse_repeat_state[tonumber(key)]=false end 
                end
            elseif action_type == 'axis' then
                if self.input_gamepad then
                    self.input_gamepad_state[key] = false
                    local real_key, sign
                    if key:find('%+') then
                        real_key = lume.split(key, '%+')[1]
                        local value = self.input_gamepad:getGamepadAxis(real_key)
                        if value >= self.input_deadzone then
                            self.input_gamepad_state[key] = value
                        end
                    else
                        real_key = lume.split(key, '%-')[1]
                        local value = self.input_gamepad:getGamepadAxis(real_key)
                        if value <= -self.input_deadzone then
                            self.input_gamepad_state[key] = value
                        end
                    end
                    
                    self.input_state[action].pressed = self.input_state[action].pressed or  
                        (self.input_gamepad_state[key] and not self.input_previous_gamepad_state[key])
                    self.input_state[action].down = self.input_state[action].down or
                        (self.input_gamepad_state[key])
                    self.input_state[action].released = self.input_state[action].released or (
                        not self.input_gamepad_state[key] and self.input_previous_gamepad_state[key]
                    )
                    -- if self.input_state[action].released then self.gamepad_repeat_state[key]=false
                    -- end
                end
            elseif action_type == 'button' then
                if self.input_gamepad then
                    self.input_state[action].pressed = self.input_state[action].pressed or (
                        self.input_gamepad_state[key] and not self.input_previous_gamepad_state[key]
                    )
                    self.input_state[action].down = self.input_state[action].down or 
                        self.input_gamepad_state[key]
                    self.input_state[action].released = self.input_state[action].released or (
                        not self.input_gamepad_state[key] and self.input_previous_gamepad_state[key]
                    )
                    if self.input_state[action].released then self.gamepad_repeat_state[key]=false end
                end
            end
        end
    end
    
end


-- :input_bind('left', {'key:left', 'key:a', 'axis:leftx-', 'button:dpad_left'})
-- :input_bind('right', {'key:right', 'key:d', 'axis:leftx+', 'button:dpad_right'})
-- :input_bind('up', {'key:up', 'key:w', 'axis:lefty-', 'button:dpad_up'})
-- :input_bind('down', {'key:down', 'key:s', 'axis:lefty+', 'button:dpad_down'})
-- :input_bind('jump', {'key:x', 'key:space', 'button:a'})
function input:bind(action, controls)
    if type(controls) == 'string' then controls = {controls} end
    if not self.input_state[action] then self.input_state[action] = {} end
    if not self.input_state[action].controls then self.input_state[action].controls = {} end
    for _, control in ipairs(controls) do
        local action_type, key = lume.split(control, ':')[1], lume.split(control, ':')[2]
        table.insert(self.input_state[action].controls, {action_type, key})
    end
    if not table.contains(self.input_actions, action) then
        table.insert(self.input_actions, action)
    end
end

function input:unbind_control(action, control)
    local index = table.contains(self.input_state[action].controls, control)
    if index then
        table.remove(self.input_state[action].controls, index)
    end
end

-- 解绑动作
function input:unbind_action(action)
    self.input_state[action] = nil
end

-- 当前帧action是否按下
function input:pressed(action)
    return self.input_state[action].pressed
end

-- 当前帧action是否被释放
function input:released(action)
    return self.input_state[action].released
end

-- 注意正常系统判定down是有interval间隔的，并不是每帧都返回true
function input:down(action, interval)
    if not interval then return self.input_state[action].down end
    for _,control in ipairs(self.input_state[action].controls) do
        local action_type,key,sign = control[1], control[2], control[3]
        if action_type == 'key' then
            if self.input_keyboard_state[key] and not self.input_previous_keyboard_state[key] then
                self.key_repeat_state[key] = {pressed_time = love.timer.getTime(), interval = interval}
                return true
            elseif self.key_repeat_state[key] and self.key_repeat_state[key].pressed then
                return true
            end
        elseif action_type == 'mouse' then
            local key = tonumber(key)
            if self.input_mouse_state[key] and not self.input_previous_mouse_state[key] then
                self.mouse_repeat_state[key] = {pressed_time = love.timer.getTime(), interval = interval}
                return true
            elseif self.mouse_repeat_state[key] and self.mouse_repeat_state[key].pressed then
                return true
            end
        elseif action_type == 'button' then
            if self.input_gamepad_state[key] and not self.input_previous_gamepad_state[key] then
                self.gamepad_repeat_state[key] = {pressed_time = love.timer.getTime(), interval = interval}
                return true
            elseif self.gamepad_repeat_state[key] and self.gamepad_repeat_state[key].pressed then
                return true
            end
        elseif action_type == 'axis' then
            -- todo
        end
    end
    return self.input_state[action].down
end


-- 记录当前帧动作状态，供下一帧判断
function input:input_post_update()
    self.input_previous_keyboard_state = table.copy(self.input_keyboard_state)
    self.input_previous_mouse_state = table.copy(self.input_mouse_state)
    self.input_previous_gamepad_state = table.copy(self.input_gamepad_state)
    self.input_mouse_state.wheel_up = false
    self.input_mouse_state.wheel_down = false
end


-- Returns true if the sequence is completed this frame.
-- The sequence is completed if all actions are pressed within their time intervals, for instance:
--   :sequence_pressed('action_1', 0.5, 'action_2')
-- will return true when 'action_2' is pressed within 0.5 seconds of 'action_1' being pressed.
function input:sequence_pressed(...)
    return self:input_process_sequence('pressed', ...)
end

-- Returns true if the sequence is released this frame.
-- The sequence must be completed first, and then released. True will be returned on release after completion. So, for instance:
--   :input_is_sequence_released('action_1', 0.5, 'action_2')
-- will return true when 'action_2' is released within 0.5 seconds of 'action_1' being pressed.
function input:sequence_released(...)
    return self:input_process_sequence('released', ...)
end

-- Returns true as long as the last action in the sequence is being held down.
-- :input_is_sequence_down('action_1', 0.5, 'action_2') -> returns true as long as 'action_2' is held down, if it was pressed within 0.5 seconds of 'action_1' being pressed.
--  按住action_1，0.5秒内按住action_2就会一直返回true，知道action_2 released
function input:sequence_down(...)
    return self:input_process_sequence('down', ...)
end

function input:input_process_sequence(action_state, ...)
    local sequence = {...}
    if #sequence == 0 then return end
    if #sequence % 2 == 0 or type(sequence[#sequence]) ~= 'string' then
        error('最后一个参数一定得是action')
    end
    if #sequence == 1 then
        return (action_state == 'pressed' and self:pressed(sequence[1])) or 
            (action_state == 'released' and self:released(sequence[1]))
    end
    table.insert(sequence, 1, 100000)
    local sequence_key = ''
    for _, s in ipairs(sequence) do sequence_key = sequence_key .. tostring(s) end
    if not self.input_sequence_state[sequence_key] then
        self.input_sequence_state[sequence_key] = {sequence=sequence, i=1}
    else
        local s = self.input_sequence_state[sequence_key]
        local delay = s.sequence[s.i]
        local action = s.sequence[s.i + 1]
        local pressed = self:pressed(action)
        local released = self:released(action)
        local last_pressed_time = s.last_pressed_time or love.timer.getTime()
        if s.i < #s.sequence - 1 then
            if pressed and (love.timer.getTime() - last_pressed_time) <= delay then
                s.last_pressed_time = love.timer.getTime()
                s.i = s.i + 2
            elseif pressed and (love.timer.getTime() - last_pressed_time) > delay then
                self.input_sequence_state[sequence_key] = nil
                return false
            end
        elseif s.i == #s.sequence - 1 then
            if pressed and (love.timer.getTime() - last_pressed_time) <= delay then
                s.last_action = true
                s.last_pressed_time = love.timer.getTime()
            elseif pressed and (love.timer.getTime() - last_pressed_time) > delay then
                self.input_sequence_state[sequence_key] = nil
                return false
            end
        end
        if action_state == 'pressed' then
            if s.last_action and pressed then
                self.input_sequence_state[sequence_key] = nil
                return true
            end
        elseif action_state == 'released' then
            if s.last_action and released and (love.timer.getTime() - last_pressed_time) <= delay then
                self.input_sequence_state[sequence_key] = nil
                return true
            elseif s.last_action and released and (love.timer.getTime - last_pressed_time) > delay then
                self.input_sequence_state[sequence_key] = nil
                return false
            end
        elseif action_state == 'down' then
            if s.last_action and self:down(action) then
                return true
            end
            if s.last_action and released then
                self.input_sequence_state[sequence_key] = nil
                return false
            end
        end
    end

end

-- 绑定默认按键
function input:bind_all()
    local controls = {
        'key:a', 'key:b', 'key:c', 'key:d', 'key:e', 'key:f', 'key:g', 'key:h', 'key:i', 'key:j', 'key:k', 'key:l', 'key:m', 'key:n', 'key:o',
        'key:p', 'key:q', 'key:r', 'key:s', 'key:t', 'key:u', 'key:v', 'key:w', 'key:x', 'key:y', 'key:z', 'key:0', 'key:1', 'key:2', 'key:3',
        'key:4', 'key:5', 'key:6', 'key:7', 'key:8', 'key:9', 'key:space', 'key:!', 'key:"', 'key:#', 'key:$', 'key:&', "key:'", 'key:(', 'key:)',
        'key:*', 'key:+', 'key:,', 'key:-', 'key:.', 'key:/', 'key::', 'key:;', 'key:<', 'key:=', 'key:>', 'key:?', 'key:@', 'key:[', 'key:\\',
        'key:^', 'key:_', 'key:`', 'key:kp0', 'key:kp1', 'key:kp2', 'key:kp3', 'key:kp4', 'key:kp5', 'key:kp6', 'key:kp7', 'key:kp8', 'key:kp9',
        'key:kp.', 'key:kp,', 'key:kp/', 'key:kp*', 'key:kp-', 'key:kp+', 'key:kpenter', 'key:kp=', 'key:up', 'key:down', 'key:right', 'key:left',
        'key:home', 'key:end', 'key:pageup', 'key:pagedown', 'key:insert', 'key:backspace', 'key:tab', 'key:clear', 'key:return', 'key:delete',
        'key:f1', 'key:f2', 'key:f3', 'key:f4', 'key:f5', 'key:f6', 'key:f7', 'key:f8', 'key:f9', 'key:f10', 'key:f11', 'key:f12',
        'mouse:1', 'mouse:2', 'mouse:3', 'mouse:4', 'mouse:5', 'mouse:wheel_up', 'mouse:wheel_down',
    }
    for _, control in ipairs(controls) do
        self:bind(lume.split(control, ':')[2], {control})
    end
end

return setmetatable({}, {__call = function(self, ...)
    return new()
end})