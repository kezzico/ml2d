local styles = require "app.styles"
local ShelfView = require "app.gui.shelf_view"
local StackView = require "app.gui.stack_view"
local Button = require "app.gui.button"
local TextView = require "app.gui.text_view"
local View = require "app.gui.view"

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