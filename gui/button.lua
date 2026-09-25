local Clickable = require 'app.gui.clickable'
local TextView = require 'app.gui.text_view'
local styles = require 'app.styles'

local function Button(button_state_or_text, style, onclick)
    if type(style) == "function" then
        onclick = style
        style = { }
    elseif type(style) == "table" then
        -- clone style so that state and style cannot become the same object
        style = table.clone(style)
    elseif style == nil then
        style = { }
    end

    local button_state = style or { text = "" }

    if type(button_state_or_text) == "string" then
        button_state.text = button_state_or_text
    else
        button_state = button_state_or_text
    end

    button_state.color = button_state.color or style.color or styles.colors.text or hexToColor(0xFFFFFF) 
    button_state.padding = button_state.padding or 20
    button_state.backgroundColor = button_state.backgroundColor or hexToColor(0xFF00FF) 
    button_state.size = button_state.size or 16

    local clickable = Clickable(onclick, {
        TextView(button_state), 
    })

    clickable.id = button_state.id or button_state.text or "button"
    
    return clickable
end

return Button