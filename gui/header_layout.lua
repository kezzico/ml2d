local _, styles = pcall(require, 'app.styles')
local ShelfView = require "ml2d.gui.shelf_view"
local StackView = require "ml2d.gui.stack_view"
local SvgButton = require "ml2d.gui.svg_button"
local TextView = require "ml2d.gui.text_view"
local View = require "ml2d.gui.view"
local SafeAreaView = require "ml2d.gui.safearea_view"

local function HeaderLayout(title, child)
    local default_header_color = hexToColor(0xAAAAAA, 1.0)
    return SafeAreaView {
        backgroundColor = styles.colors.header_background or default_header_color,

        StackView {
            heights = { 80, nil },
            backgroundColor = hexToColor(0x0, 1.0),
            ShelfView { 
                widths = { "80px", nil, "80px" }, 
                backgroundColor = styles.colors.header_background or default_header_color,
                SvgButton({ "ml2d/assets/gfx/nav_back.svg#back" , padding = { 27, 27 } }, function() navigator:pop() end), 
                TextView(title, {
                    font = styles.fonts.header or styles.fonts.default
                }), View { }
            },

            child
        }
    }
    
end

return HeaderLayout
