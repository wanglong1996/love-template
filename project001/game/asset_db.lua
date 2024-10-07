local graphics = love.graphics

Fontdb = {}

function Fontdb:init(path)
    self.path = path
end

function Fontdb:load(font_sizes)
    self.fonts = {}
    self.ascents = {}
    self.font_files = {}
    self.font_subst = {}
    self.font_adj = {}

    local path = self.path or "resources/fonts"

    -- image font todo

    local font_files = love.filesystem.getDirectoryItems(path)

    for i = 1, #font_files do
        local f = font_files[i]

        font_files[i] = path .. "/" .. f
    end

    for _, f in pairs(font_files) do
        if love.filesystem.getInfo(f) then
            if string.match(f, ".TTF$") or string.match(f, ".ttf$") or string.match(f, '.otf$') then
                local key = f:match("([^%/]+)%.%w+$")
                self.font_files[key] = f
            end
        end
    end

    log.debug("Font files\n:%s", getfulldump(self.font_files))
	log.debug("Fonts loaded\n%s", getfulldump(self.fonts))
end

function Fontdb:get(name, size)
    local real_size = tonumber(self.font_adj[name] and self.font_adj[name].size * size or size)

    if real_size > 6 then
        real_size = math.round(real_size)
    end

    local name_size = name .. "-" .. real_size
    local tf = self.fonts[name_size]

    if tf then
        local fh = tf:getHeight()

        return tf, fh
    else
        local font_file = self.font_files[name]
        log.debug("creating font %s-%s (orig size:%s) from file %s ", name, real_size, size, font_file)

        if font_file then
            local font = graphics.newFont(font_file, tonumber(real_size), 'light')

            self.fonts[name_size] = font

            local fh = font:getHeight()

            return font, fh
        else
            log.error("Font %s not found", name)
        end
    end
end

-- origin 
function Fontdb:set_locale(orig, subst, adj)
    log.info("------------------------- orig:%s subst:%s %s", orig, subst, getfulldump(adj))

    self.font_subst[orig] = subst
    self.font_adj[orig] = adj or {
        size = 1
    }

    local to_clean = {}

    for k, v in pairs(self.fonts) do
        -- 1表示从位置1开始，true 表示使用明文，不使用正则表达式
        if string.find(k, subst, 1, true) then
            table.insert(to_clean, k)
        end
    end

    for i, v in ipairs(to_clean) do
        self.fonts[v] = nil
    end
end

function Fontdb:get_ext_info(name, size)
    local fm = {}

    if self.font_adj[name] then
        local font_size = self.font_adj[name].size or 1

        for k, v in pairs(self.font_adj[name]) do
            if k == "top" then
                fm[k] = (0.5 * (1 - font_size) + v * font_size) * size
            elseif k == "middle" then
                fm[k] = v * size *font_size
            end
        end
    end
    return fm
end
