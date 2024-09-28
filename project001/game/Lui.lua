local class = require('lib.middleclass')
local _last_id = 9999
local graphics = love.graphics

table.unpack = table.unpack or unpack

local function vround(x, y)
	return math.round(x), math.round(y)
end

LObject = class("LObject")
LObject.static.serialize_keys = {
	"id"
}
LObject.static.serialize_children = true
LObject.static.init_arg_names = {}

function LObject.static:append_serialize_keys(...)
	local new_keys = {
		...
	}

	if self.super and self.super.serialize_keys then
		self.serialize_keys = table.append(new_keys, self.super.serialize_keys)
	else
		self.serialize_keys = new_keys
	end
end

function LObject.static:get_init_args(t)
	local function nil_unpack(tt, i, maxi)
		i = i or 1

		if i == maxi then
			return tt[i]
		elseif i < maxi then
			return tt[i], nil_unpack(tt, i + 1, maxi)
		end
	end

	local args = {}

	for i, n in ipairs(self.static.init_arg_names) do
		args[i] = t[n]
	end

	return nil_unpack(args, 1, #self.static.init_arg_names)
end

function LObject:initialize()
	_last_id = _last_id + 1
	self.id = tostring(_last_id)
	self.children = {}
	self.parent = nil

	self:deserialize()
end


function LObject.static:new_from_table(t)
	local v = self:allocate()

	v._deserialize_table = t

	v:initialize(v.class:get_init_args(t))

	v._deserialize_table = nil

	return v
end

function LObject:deserialize()
	local t = self._deserialize_table

	if not t then
		return
	end

	for k, v in pairs(t) do
		if k == "children" then
			for _, ct in pairs(v) do
				local klass_name = ct.class

				if not klass_name then
					log.error("class param not found for %s", pretty_print(ct))
				else
					local klass = _G[klass_name]

					if not klass then
						log.error("class not found %s", klass_name)
					else
						local c = klass:new_from_table(ct)

						self:add_child(c)
					end
				end
			end
		elseif k == "class" then
			-- block empty
		elseif type(v) == "table" then
			if not self[k] then
				self[k] = {}
			end

			table.deepmerge(self[k], v)
		else
			self[k] = v
		end
	end
end

function LObject:serialize(doing_template)
	local out = {}
	local doing_template_instance = self.template_name and not doing_template

	if doing_template_instance then
		local out_t = self:serialize(true)

		out._template_table = out_t
	end

	out.class = self.class.name

	local keys = doing_template_instance and self.class.static.instance_keys or self.class.static.serialize_keys

	for _, k in pairs(keys) do
		local v = self[k]

		if type(v) == "table" then
			out[k] = table.copy(v)
		else
			out[k] = v
		end
	end

	if not doing_template_instance and self.class.static.serialize_children and self.children and #self.children > 0 then
		local children = {}

		for _, c in pairs(self.children) do
			if not c.ephemeral then
				table.insert(children, c:serialize())
			end
		end

		out.children = children
	end

	return out
end

function LObject:add_child(c, idx)
    c.parent = self

    if idx then
        table.insert(self.children, idx, c)
    else
        table.insert(self.children, c)
    end
end

function LObject:remove_child(c)
    if not c then
        log.error('Remove nil child from '..self)
        return
    end
    table.remove_object(self.children, c)

    c.parent = nil
end

function LObject:remove_children()
    for i = #self.children, 1,-1 do
        local o = self.children[i]
        o.parent = nil
        table.remove(self.children, i)
    end
end

function LObject:remove_from_parent()
    if self.parent ~= nil then
        self.parent:remove_child(self)
    end
end

function LObject:is_child_of(ancestor)
    if self.parent == nil then
        return false
    elseif self.parent == ancestor then
        return true
    else
        return self.parent:is_child_of(ancestor)
    end
end

-- 获取当前节点在父容器的索引
function LObject:get_order()
    if not self.parent then
        return nil
    end

    for i = 1, #self.parent.children do
        if self.parent.children[i] == self then
            return i
        end
    end
    return nil
end

function LObject:order_to_front()
    if self.parent then
        local p = self.parent

        p:remove_child(self)
        p:add_child(self)
    end
end

function LObject:order_to_back()
    if self.parent and #self.parent.children > 1 then
        self:order_below(self.parent.children[1])
    end
end

-- c:i  self:i+1
function LObject:order_above(c)
	local p = self.parent

	if not p or c.parent ~= p then
		return
	end

	p:remove_child(self)

	local idx = c:get_order()

	if idx then
		p:add_child(self, idx + 1)
	end
end

-- c:i self:i c:i+1
function LObject:order_below(c)
	local p = self.parent

	if not p or c.parent ~= p then
		return
	end

	p:remove_child(self)

	local idx = c:get_order()

	if idx then
		p:add_child(self, idx)
	end
end

function LObject:clone()
    return table.copy(self)
end

-- 按filter 条件获取当前节点和其子节点
function LObject:flatten(filter, trim_filter)
    local out = {}

    if trim_filter and not trim_filter(self) then
        return out
    end

    if not filter or filter(self) then
        table.insert(out, self)
    end

    if self.children and #self.children > 0 then
        for _, child in pairs(self.children) do
            local l = child:flatten(filter, trim_filter)

            if l and #l > 0 then
                table.append(out, l)
            end
        end
    end

    return out
end

LView = class("LView", LObject)

LView:append_serialize_keys("pos", "size", "padding", "anchor", "scale", "base_scale", "r", "hit_rect", "clip", "alpha", "disabled_tint_color", "colors", "image_scale", "image_name", "image_offset", "focus_nav_offset", "focus_nav_dir", "animation")

LView.static.serialize_children = true
LView.static.init_arg_names = {
	"size"
}

function LView:initialize(size, image)
    self.pos = vec2(0, 0)
    self.size = vec2(0, 0)
    self.padding = vec2(0, 0)
    self.anchor = vec2(0, 0) -- 轴心点
    self.scale = vec2(1, 1)
    self.base_scale = vec2(1, 1)
    self.rotation = 0
    self.hidden = false
    self.can_drag = false
    self.elasticity = 10
    self.elastic_limits = false
    -- 弹性阻力
    self.elastic_resistance = 0.4
    self.drag_threshold = nil
    self.clip = false
    self.clip_view = nil
    self.alpha = 1
    self.disabled_tint_color = C.DISABLED_TINT_COLOR
    self.hit_rect = nil
    self.focus_order = 0
    self.focus_nav_dir = nil
    self.focus_nav_offset = nil
	self.focus_nav_ignore = nil
	self.focus_nav_override = nil
	self.propagate_on_up = false
	self.propagate_on_down = false
	self.propagate_on_click = false
	self.propagate_on_drop = true
	self.propagate_on_scroll = true
	self.propagate_on_enter = true
	self.propagate_drag = true
	self.propagate_on_touch_down = true
	self.propagate_on_touch_up = true
	self.propagate_on_touch_move = true
	self.scroll_origin_y = 0
	self.colors = {}
	self.image_scale = 1
	self.image_offset = nil
	self.animation = nil
	self.ts = 0
	self._disabled = false
	self._focused = false

    self:set_image(image, size)
    LView.super.initialize(self)
end

function LView:deserialize()
	local t = self._deserialize_table

	if not t then
		return
	end

	t.image_name = nil

	LView.super.deserialize(self)
end

function LView:set_image(image, size)
    local w, h = 0, 0
    if image and type(image) == "userdata" then
        self.image = image
        
        if size then
            w, h = size.x, size.y
        else
            w, h = self.image:getDimensions()
        end
    elseif image and type(image) == 'string' then
        -- 加载图片
    end
end

function LView:destroy()
	if self.children ~= nil then
		for i = #self.children, 1, -1 do
			self.children[i]:destroy()
		end
	end

	self.children = nil
	self.parent = nil
	self.image = nil
	self.image_ss = nil
	self.colors = nil
	self.on_click = nil
	self.on_down = nil
	self.on_up = nil
	self.on_drop = nil
	self.on_scroll = nil
	self.on_enter = nil
	self.hit_rect = nil
end

function LView:update(dt)
	if not self.animation or not self.animation.paused then
		self.ts = self.ts + dt
	end

	for _, c in pairs(self.children) do
		c:update(dt)
	end
end

function LView:draw()
    if self.hidden then
        return
    end

    local r, g, b, a = graphics.getColor()
    local current_alpha = a * self.alpha

    graphics.setColor({
        1,1,1, current_alpha
    })
    graphics.push()
    graphics.scale(self.scale.x * self.base_scale.x, self.scale.y * self.base_scale.y)
    graphics.rotate(-self.r)
    graphics.translate(-self.anchor.x, -self.anchor.y)

    if self.clip then
        local this = self

        if self.clip_fn then
            self._stencil_fn = self.clip_fn
        else
            function self._stencil_fn()
                graphics.rectangle('fill', 0, 0, this.size.x, this.size.y)
            end
        end

        graphics.stencil(self._stencil_fn)
        graphics.setStencilTest("greater", 0)
    end

end

function LView:_draw_self()
    local r, b, g, a = graphics.getColor()
    local current_alpha = a

    if self.colors.background then
        local new_c = {
            self.colors.background[1],
			self.colors.background[2],
			self.colors.background[3],
			self.colors.background[4] * current_alpha
        }

        graphics.setColor(new_c)

        if self.shape then
            local fn = graphics[self.shape.name]

            if fn then
                fn(table.unpack(self.shape.args))
            else
                log.error('Error shape %s ', self.shape.name)
            end
        else
            graphics.rectangle('fill', 0, 0, self.size.x, self.size.y)
        end
    end
    -- 着色
    if self.colors.tint then
        local tint = self.colors.tint

        graphics.setColor({
            tint[1],
			tint[2],
			tint[3],
			tint[4] * current_alpha
        })
    end

    -- shader
    if self.shader then
        if self.shader_args then

            for k, v in pairs(self.shader_args) do
                self.shader:send(k, v)
            end
        end

        graphics.setShader(self.shader)
    end

    -- animation
    if self.animation then
        
    end

    if self.image_offset then
        graphics.push()
        graphics.translate(self.image_offset.x, self.image_offset.y)
    end



    if self.image_offset then
        graphics.pop()
    end

    graphics.setColor(r,g,b,a)
    -- end shader
    if self.shader then
        graphics.setShader()
    end

end

function LView:_draw_children()
    local clip_x, clip_y, clip_xw, clip_yh
    local cv = self.clip_view

    if cv then
        clip_x, clip_y = self.clip_view:view_to_view(0, 0, self)
        clip_xw, clip_yh = self.clip_view:view_to_view(cv.size.x, cv.size.y, self)
    end

    graphics.push()
    graphics.translate(self.padding.x, self.padding.y)

    for _, child in pairs(self.children) do
        if clip_x ~= nil then
            local bb = child:get_bounds_rect(true, 2)
        end
    end
end

-- 屏幕坐标转局部坐标
function LView:screen_to_view(x, y)
    local ox, oy = 0, 0
    local this = self
    local view_list = {}

    repeat
        table.insert(view_list, this)

        this = this.parent
    until not this

    for i = #view_list, 1, -1 do
        local v = view_list[i]

        x = (x - v.pos.x) / (v.scale.x * v.base_scale.x) + v.anchor.x
        y = (y - v.pos.y) / (v.scale.y * v.base_scale.y) + v.anchor.y

        -- if v.parent and v.parent:isInstanceOf(KScrollList) then
        --     y = y + v.scroll_origin_y / (v.scale.y * v.base_scale.y)
        -- end
    end

    return vround(x, y)
end

function LView:view_to_screen(x, y)
	local ox, oy = 0, 0
	local this = self

	repeat
		x = (x - this.anchor.x) * (this.scale.x * this.base_scale.x) + this.pos.x
		y = (y - this.anchor.y) * (this.scale.y * this.base_scale.y) + this.pos.y

		-- if this.parent and this.parent:isInstanceOf(KScrollList) then
		-- 	y = y - this.scroll_origin_y
		-- end

		this = this.parent
	until not this

	return vround(x, y)
end

function LView:view_to_view(x, y, dest_view)
	local ix, iy = self:view_to_screen(x, y)

	return dest_view:screen_to_view(ix, iy)
end

function LView:get_real_scale()
	return self.scale.x * self.base_scale.x, self.scale.y * self.base_scale.y
end

function LView:get_real_size()
	local sx, sy = self:get_real_scale()

	return self.size.x * sx, self.size.y * sy
end

function LView:get_bounds_rect(only_visible, depth)
    local initial = depth and "     " or "root:"

    depth = depth or 0
    depth = depth + 1

    local left = 0
    local top = 0
    local right = self.size.x
    local bottom = self.size.y

    for _, c in pairs(self.children) do
		if not only_visible or not c.hidden then
			local cr = c:get_bounds_rect(only_visible, depth)

			left = math.min(left, cr.pos.x)
			top = math.min(top, cr.pos.y)
			right = math.max(right, cr.pos.x + cr.size.x)
			bottom = math.max(bottom, cr.pos.y + cr.size.y)
		end
	end

	local sx, sy = self:get_real_scale()
	local px = self.pos.x - self.anchor.x * sx + left * sx
	local py = self.pos.y - self.anchor.y * sy + top * sy
	local zx = (right - left) * sx
	local zy = (bottom - top) * sy
	local r = {
        pos = vec2(px, py),
        size = vec2(zx, zy)
    }

    return r
end

function LView:get_window()
	return self:get_parent_of_class(LWindow)
end

function LView:get_parent_of_class(clazz)
	local this = self

	while this do
		if this:isInstanceOf(clazz) then
			return this
		else
			this = this.parent
		end
	end
end

function LView:get_child_by_id(id)
	if self.id == id then
		return self
	else
		for _, c in ipairs(self.children) do
			local found = c:get_child_by_id(id)

			if found then
				return found
			end
		end
	end

	return nil
end

LView.ci = LView.get_child_by_id

function LView:disable(tint, color)
    self._disabled = true

    if tint then
        self:apply_disabled_tint(color)
    end
end

function LView:enable(untint)
    self._disabled = false

    if untint then
        self:remove_disabled_tint()
    end
end

function LView:is_disabled()
    return self._disabled == true
end

function LView:focus(silent)
    local w = self:get_window()

    if w then
        w:focus_view(self, silent)
    end
end

function LView:defocus()
	local w = self:get_window()

	if w then
		w:focus_view(nil)
	end
end

function LView:is_focused()
	return self._focused == true
end

function LView:apply_disabled_tint(color)
    self.colors.tint = color or self.disabled_tint_color

    for _, child in ipairs(self.children) do
        child:apply_disabled_tint(color)
    end
end

function LView:remove_disabled_tint()
	if not self._disabled then
		self.colors.tint = nil
	end

	for _, c in ipairs(self.children) do
		c:remove_disabled_tint()
	end
end

function LView:get_bounds()
    if self.ignore_bounds then
        return vec2.ps(0, 0, 0, 0)
    end

    local xmin, xmax, ymin, ymax = 0, self.size.x, 0, self.size.y

    for _, c in pairs(self.children) do
		if not c.ignore_bounds then
			local b = c:get_bounds()

			xmin = xmin > b.pos.x and b.pos.x or xmin
			ymin = ymin > b.pos.y and b.pos.y or ymin
			xmax = xmax < b.pos.x + b.size.x and b.pos.x + b.size.x or xmax
			ymax = ymax < b.pos.y + b.size.y and b.pos.y + b.size.y or ymax
		end
	end

    local w, h = (xmax - xmin) * self.scale.x * self.base_scale.x, (ymax - ymin) * self.scale.y * self.base_scale.y
	local x, y

	if self.parent then
		x, y = self:view_to_view(xmin, ymin, self.parent)
	else
		x, y = xmin, ymin
	end

    return vec2.ps(x, y, w, h)
end



---动画播放
---@param animation table -- from/to 开始/结束 pre/post 开始/结束额外帧
---@param time_offset any
---@param loop any
---@param fps any
function LView:animation_frame(animation, time_offset, loop, fps)
    local a = animation
    fps = fps or 30

    local frames = a.frames

    if not frames then
        frames = {}

        if a.pre then
            table.append(frames, a.pre)
        end

        a.from = a.from or 1

        if a.from and a.to then
            local inc = a.from > a.to and -1 or 1

            for i = a.from, a.to, inc do
                table.insert(frames, i)
            end
        end

        if a.post then
            table.append(frames, a.post)
        end

        a.frames = frames
    end

    local len = #frames
    local elapsed = math.ceil(time_offset * fps)
    local runs = math.floor(elapsed / len)
    local idx
    if loop then
        idx = math.zmod(elapsed, len)
    else
        idx = math.clamp(elapsed, 1, len)
    end

    local frame = frames[idx]
    return string.format("%s_%04i", a.prefix, frame), runs
end

-- x, y 局部坐标？
function LView:hit_all(x, y, filter)
    local hits = {}

    if self._disabled then
        return hits
    end

    if self.clip and (x < 0 or x >self.size.x or y < 0 or y > self.size.y) then
        return hits
    end

    for i = #self.children, 1, -1 do
        local child = self.children[i]

        if child.hidden or child._disabled then
            -- block
        else
            local cx = (x - child.pos.x + child.anchor.x * child.scale.x * child.base_scale.x) / (child.scale.x * child.base_scale.x)
            local cy = (y - child.pos.y + child.anchor.y * child.scale.y * child.base_scale.y - self.scroll_origin_y) / (child.scale.y * child.base_scale.y)
            local c_hits = child:hit_all(cx, cy, filter)

            table.append(hits, c_hits)
        end
    end

    local hr = self.hit_rect

    if not self.hidden and not self._disabled and (hr and x >= hr.pos.x and x <= hr.pos.x + hr.size.x and y >= hr.pos.y and y <= hr.pos.y + hr.size.y or not hr and x >= 0 and x <= self.size.x and y >= 0 and y <= self.size.y) and (filter == nil or filter(self)) then
		table.insert(hits, self)
	end

	return hits
end


function LView:hit_topmost(x, y, filter)
	local result = self:hit_all(x, y, filter)

	if #result > 0 then
		return result[1]
	else
		return nil
	end
end


LImageView = class("LImageView", LView)
LImageView.static.init_arg_names = {
    "image_name",
    "size"
}

function LImageView:initialize(image_name, size)
    LView.initialize(self, size, image_name)

    -- new_from_table 使用_deserialize_table内容覆盖self
    local dt = self._deserialize_table
    
    for _, v in pairs({
		"up",
		"down",
		"click"
	}) do
		local k = "propagate_on_" .. v

		if dt and dt[k] ~= nil then
			self[k] = dt[k]
		else
			self[k] = true
		end
	end
end

LWindow = class("LWindow", LView)

LWindow:append_serialize_keys("origin")

function LWindow:initialize(size)
    LWindow.super.initialize(self, size)

    self.origin = vec2.ps(0, 0)
    self.drag_threshold = 4
    self.focused = nil
end

function LWindow:draw()
    graphics.push()
    graphics.translate(self.origin.x, self.origin.y)
    graphics.setColor(1,1,1,1)
    LView.draw(self)
    graphics.pop()
end

function LWindow:draw_child(child)
    graphics.push()
	graphics.translate(self.origin.x, self.origin.y)
	graphics.scale(self.scale.x, self.scale.y)
	graphics.rotate(-self.r)
	graphics.translate(-self.anchor.x, -self.anchor.y)
	child:draw()
	graphics.pop()
end

-- 是否支持鼠标
function LWindow:has_mouse()
    return love.mouse.isCursorSupported()
end

function LWindow:get_mouse_pos()
    local x, y = love.mouse.getPosition()

    x, y = x - self.origin.x, y - self.origin.y

    return x, y, love.mouse.isDown(1, 2)
end

function LWindow:mousepressed(x, y, button, istouch)
    x, y = x - self.origin.x, y - self.origin.y
    self._mouse_down_pos = vec2.ps(x, y)

    local wx, wy = self:screen_to_view(x, y)

    log.info("x,y:%s,%s  button:%s, istouch:%s, wx,wy:%s,%s  ", x, y, button, istouch, wx, wy)

    local event_name

    if button == 1 or button == 2 then
        event_name = 'on_down'

        local dv = self:hit_topmost(wx, wy, function (v)
            return not v.propagate_drag or v.can_drag
        end)
        -- (dv and dv.can_drag) and dv or nil
        self._drag_view = dv and dv.can_drag and dv or nil

        log.info("  _drag_view:%s", self._drag_view)
    elseif button == "wheel_up" or button == "wheel_down" then
        event_name = "on_scroll"
    else
        log.info("button press not handled: %s", button)

		return
    end

    local hl = self:hit_all(wx, wy)

    self._click_start_view = nil

    for _, v in pairs(hl) do
        if v.on_click then
            self._click_start_view = v

            break
        elseif not v.propagate_on_click then
            break
        end
    end

    for _, v in pairs(hl) do
        log.info(" checking event %s in view %s[%s]", event_name, tostring(v), v.id)

        if v[event_name] then
            log.info(" > handling event %s in view %s[%s]", event_name, tostring(v), v.id)

            local vx, vy = v:screen_to_view(x, y)

            if not v[event_name](v, button, vx, vy, istouch) then
                break
            end
        elseif not v["propagate_"..event_name] then
            break
        end
    end

end

function LWindow:wheelmoved(dx, dy)
    local x, y = love.mouse.getPosition()

    log.debug("dx:%s dy:%s", dx, dy)

    local button

    button = dy > 0 and "wheel_up" or "wheel_down"

    self:mousepressed(x, y, button)
end


function LWindow:mousereleased(x, y, button, istouch)
    x, y = x - self.origin.x, y - self.origin.y
    
end