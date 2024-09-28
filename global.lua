---@diagnostic disable: deprecated
PI = math.pi
TAU = math.pi*2


_G.C = {
    -- common
    MULT = HEX('#FE5F55'),
    CHIPS = HEX("#009dff"),
    MONEY = HEX('#f3b958'),
    XMULT = HEX('#FE5F55'),
    FILTER = HEX('#ff9a00'),
    BLUE = HEX("#009dff"),
    RED = HEX('#FE5F55'),
    GREEN = HEX("#4BC292"),
    PALE_GREEN = HEX("#56a887"),
    WHITE = HEX("#ffffff"),
    BLACK = HEX("#000000"),
    BG3 = HEX("#2d1600"),

    -- ui
    DISABLED_TINT_COLOR = HEX("#969696")
}

(function()
    local log = require('lib.log')
    table.unpack = table.unpack or unpack
    _G.sin = math.sin
    _G.cos = math.cos
    _G.log = log
end)()