local _, styles = pcall(require, 'app.styles')
local ShelfView = require "ml2d.gui.shelf_view"
local StackView = require "ml2d.gui.stack_view"
local Button = require "ml2d.gui.button"
local TextView = require "ml2d.gui.text_view"
local View = require "ml2d.gui.view"

local function HeaderLayout(title, child)
    return StackView {
        heights = { 80, nil },
        backgroundColor = styles.colors.menu_background,

        ShelfView { widths = { "80px", nil, "80px" }, 
        backgroundColor = styles.colors.header_background,
            Button("<", { backgroundColor = styles.colors.clear }, function() navigator:pop() end), 
            TextView(title, { size = 11, }), View { } },
        --
        child
    }
end

return HeaderLayout