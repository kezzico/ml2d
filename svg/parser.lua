local eval_units = require "ml2d.gui.eval_units"
local base64 = (require "ml2d.web.base64")
local xmlSimple = require "ml2d.svg.xml_simple"

--some patterns for re-use
local number_match = "%-?%d+%.?%d*"
local number_capture = "(" .. number_match .. ")"
local comma_match = "%s-,%s-"

local svg_parser = {
	scale_factor = 1,
	decimal_precision = 2,
	curve_detail = 5,
	fills = { },
	path_vars = {
		coords = "",
		sub_coords = {},
		path_x = 0,
		path_y = 0,
		path_x2 = 0,
		path_y2 = 0,
		first_x = 0,
		first_y = 0,
		curr_poly = {}
	}
}

function svg_parser:round (num)
	local mult = 10^(self.decimal_precision)
	return math.floor(num * mult + 0.5) / mult
end

function svg_parser:join_paths (path_1, path_2)
	if self:round(path_1[#path_1 - 1]) == self:round(path_2[1]) and self:round(path_1[#path_1]) == self:round(path_2[2]) then
		table.remove(path_2, 1)
		table.remove(path_2, 1)
	end
	for i = 1, #path_2 do
		path_1[#path_1 + 1] = path_2[i]
	end
	return path_1
end

function svg_parser:remove_double_points (path)
	for i = 1, #path - 2, 4 do
		local x, y = path[i], path[i + 1]
		local x2, y2 = path[i + 2], path[i + 3]
		if x and y and x2 and y2 then
			if self:round(x) == self:round(x2) and self:round(y) == self:round(y2) then
				table.remove(path, i)
				table.remove(path, i)
			end
		end
	end
	return path
end

function svg_parser:reset_path_vars ()
	self.path_vars = {
		coords = "",
		sub_coords = {},
		path_x = 0,
		path_y = 0,
		path_x2 = 0,
		path_y2 = 0,
		first_x = 0,
		first_y = 0,
		curr_poly = {}
	}
end

function svg_parser:iterator_to_table (iterator)
	local table = {}
	if iterator then
		local i = 1
		for value in iterator do
			table[i] = value
			i = i + 1
		end
	end
	return table
end

function svg_parser.split (str, sep)
	if str and sep then
		local sep, fields = sep or ":", {}
		local pattern = string.format("([^%s]+)", sep)
		str:gsub(pattern, function(c) fields[#fields+1] = c end)
		return fields
	end
	return nil
end

function svg_parser.path_next_number (str)
	--[[
		this marks the end of the pattern, which means either:
		a space,
		any regular letter except for e, (since that is used for scientific notation in this format: 1.3241+15),
		or a comma.
	]]--
	local delimiter_match = "[ a-df-zA-DF-Z,]"
	return tonumber(str:match(number_capture .. delimiter_match))
end

--just returns the INDEX of the next svg command (a single letter) in the string
function svg_parser.next_svg_command (str)
	return str:find("[MmLlVvHhZzAaSsCcQqTt]")
end

function svg_parser:is_value_list (attr)
	return attr:find(number_match .. comma_match .. number_match)
end

function svg_parser:is_number (attr)
	return type(tonumber(attr)) == "number"
end

--currently not taking stroke into account, because that's a whole different beast
function svg_parser:is_valid_color (color_string)
	local is_color = false
	color_string = color_string:gsub("^%s*(.*)%s*$", "%1")
	if color_string:find("#") and color_string:find("#") == 1 then
		is_color = true
	elseif color_string:find("rgb(") and color_string:find(")") then
		is_color = true
	elseif color_string == "none" or color_string == "" then
		is_color = true
	end
	return is_color
end

function svg_parser:parse(text)
	self.fills = { }
	self.clippaths = { }

	if text == nil then
		print("[parser] WARNING! missing SVG file")
		
		return { }
	end
	local svg_xml = xmlSimple.newParser():ParseXmlText(text)
	local dom = { }

	self:traverse_tree(dom, nil, svg_xml, 0, 0)

	return dom
end

function svg_parser:get_fill(fill_url)
	self.fills[fill_url] = self.fills[fill_url] or { type = "" }
	return self.fills[fill_url]
end

function svg_parser:traverse_tree (dom, group, parent_tag, origin_x, origin_y)
	local tags = parent_tag:children()

	if tags == nil then return end

	for i = 1, #tags do
		local tag = tags[i]
		local id = tag["@id"]
		if type(id) == "table" then id = id[1] end

		local style = tag["@style"]
		local fill_color = (style or ""):match("fill:#([%x]+)")
		-- fill-opacity:0.13;
		local fill_opacity = (style or ""):match("fill%-opacity:([%d%.]+)")
		local fill_url = (style or ""):match("fill:url%(([^%)]+)%)")
		
		local object = { }
		-- if we have a parser for it, assume the tag is a drawable
		if tag:name() == "svg" then
			local viewbox = tag["@viewBox"]

			if type(viewbox) == "string" then
				local parts = viewbox:split(" ")
				dom.width = tonumber(parts[3])
				dom.height = tonumber(parts[4])
			end

			-- object = { id = id, type = "svg" }
			self:traverse_tree(dom, dom, tag, 0, 0)

		elseif self["parse_" .. tag:name()] ~= nil then
			object = self["parse_" .. tag:name()](self, tag)
			object.type = tag:name()
			if fill_color ~= nil or fill_opacity ~= nil then
				object.fill = { type = "color", color = self.hex_to_color(fill_color or "000", fill_opacity or 1.0) }
			elseif fill_url ~= nil then
				object.fill = self:get_fill(fill_url)
				-- store the width and height of the object in the fill 
				-- so the shader knows the gradient bounds
				object.fill.width = tag["@width"] or dom.width
				object.fill.height = tag["@height"] or dom.height
			else
				object.fill = { type = "color", color = {0,0,0,1}}
			end

		elseif tag:name() == "use" then
			object = svg_parser:parse_rect(tag)
			object.type = "rect"
			object.fill = self:get_fill(tag["@xlink:href"])

		elseif tag:name() == "linearGradient" then
			local fill = self:get_fill("#"..id)
			local stops = { }

			stops = filter(tag:children(), function(t) return t:name() == "stop" end)
			fill.stop_colors = flatten(map(stops, function(t) 
				local color = self.hex_to_color(t["@style"]:match("stop%-color:#([%x]+)"))
				local opacity = tonumber(t["@style"]:match("stop%-opacity:([%d%.]+)")) or 1.0

				color = { color[1] or 1.0, color[2] or 1.0, color[3] or 1.0, opacity or 1.0 }
				return color
			end))
			
			fill.stop_offsets = map(stops, function(t) 
				return tonumber(t["@offset"])
			end)

			fill.type = "linear_gradient"
			fill.transform = map(tag["@gradientTransform"]
				:match("matrix%((.-)%)")
				:split(","), 
				function(v) return tonumber(v) end)
			
			-- sending the matrix to the shader as *row major*
			-- eg: shader:send("transform", "row", fill.transform)
			-- OPTIMIZE: take the matrix inverse here (seems to be okay, getting solid 60 on device tests)
			fill.transform = {
				fill.transform[1], fill.transform[3], fill.transform[5],
				fill.transform[2], fill.transform[4], fill.transform[6],
				0,                 0,                 1
			}

			
			
        -- <linearGradient id="_Linear2" x1="0" y1="0" x2="1" y2="0" gradientUnits="userSpaceOnUse" gradientTransform="matrix(1.95982,738.929,-11.2585,0.0298601,2126,27.6651)">
        --     <stop offset="0" style="stop-color:#ffdad2;stop-opacity:1"/>
        --     <stop offset="1" style="stop-color:#ff6c6d;stop-opacity:1"/>
        -- </linearGradient>
		elseif tag:name() == "image" then
			local fill = self:get_fill("#"..id)
			fill.type = "image"
			fill.image = base64.decode_png(tag["@xlink:href"])
			-- todo: decode b64 image
		elseif tag:name() == "clipPath" then
			object = { }
			object.id = id
			object.type = "group"

			self:traverse_tree(dom, object, tag, 0, 0)
			-- return
		else 
			object = { }
			object.id = id
			object.type = "group"
			object.clip_path = dom[(tag["@clip-path"] or ""):match("url%(#([^%)]+)%)")]
			self:traverse_tree(dom, object, tag, 0, 0)
		end

		if id ~= nil then
			dom[id] = object
		end

		if group ~= nil then
			table.insert(group, object)
		end
	end
end

-- function svg_parser:apply_parent_origin (object, style, origin_x, origin_y)
-- 	--parse paths and objects
-- 	if type(object[1]) == "table" then 
-- 		for i = 1, #object do
-- 			for j = 1, #object[i], 2 do
-- 				object[i][j] = object[i][j] + origin_x
-- 				object[i][j + 1] = object[i][j + 1] + origin_y
-- 			end
-- 		end
-- 	elseif object[1] and object[2] then
-- 		object[1] = object[1] + origin_x
-- 		object[2] = object[2] + origin_y
-- 	end
-- 	return object
-- end

function svg_parser:merge_styles (style, style_to_inherit)
	return style
end

function svg_parser:parse_style_value (val_string)
	local value = val_string
	if value == "none" or value == "" then
		value = nil
	elseif self:is_number(val_string) then
		value = tonumber(val_string)
	elseif self:is_value_list(value) then
		value = self.split(value, ",")
	elseif self:is_valid_color(val_string) then
		value = self:parse_color(val_string)
	elseif val_string:find(number_match) then
		value = val_string:match(number_match)
		value = tonumber(value)
	else
		value = {0, 0, 0, 0}
	end
	return value
end

function svg_parser:parse_circle (tag)
	local x = tonumber(tag["@cx"])
	local y = tonumber(tag["@cy"])
	local radius = tonumber(tag["@r"])

	return {
		x,
		y,
		radius
	}
end

function svg_parser:parse_ellipse (tag)
	local x = tonumber(tag["@cx"])
	local y = tonumber(tag["@cy"])
	local rx = tonumber(tag["@rx"])
	local ry = tonumber(tag["@ry"])

	return {
		x,
		y,
		rx,
		ry
	}
end

function svg_parser:parse_rect (tag)

	local box = { }

	box.x = eval_units(tag["@x"], 1)
	box.y = eval_units(tag["@y"], 1)
	box.w = eval_units(tag["@width"], 1)
	box.h = eval_units(tag["@height"], 1)

	if tag["@transform"] ~= nil then
		local transform = flatten(
			map(tag["@transform"]:match("matrix%((.-)%)"):split(","), function(v) return tonumber(v) end),
			0, 0, 1
		)
		local function apply_transform(transform, x, y)
			return transform[1] * x + transform[3] * y + transform[5], transform[2] * x + transform[4] * y + transform[6]
		end

		local x1, y1 = apply_transform(transform, box.x, box.y)
		local x2, y2 = apply_transform(transform, box.x + box.w, box.y)
		local x3, y3 = apply_transform(transform, box.x + box.w, box.y + box.h)
		local x4, y4 = apply_transform(transform, box.x, box.y + box.h)
		
		box.x = math.min(x1, x2, x3, x4)
		box.y = math.min(y1, y2, y3, y4)
		box.w = math.max(x1, x2, x3, x4) - box.x
		box.h = math.max(y1, y2, y3, y4) - box.y
	end

	-- print("Parsed rect:", table_to_string(box, true))

	return { box.x, box.y, box.w, box.h }
end

function svg_parser:parse_path_m (path, char)
    self.path_vars.path_x2 = self.path_next_number(self.path_vars.coords)
    self.path_vars.coords = path:sub(path:find(self.path_vars.path_x2) + #tostring(self.path_vars.path_x2), self.next_svg_command(path))
    
    -- Absolute or relative initial moveto
    if char == "m" and #self.path_vars.curr_poly > 0 then
        self.path_vars.path_x = self.path_vars.path_x + self.path_vars.path_x2
    else
        self.path_vars.path_x = self.path_vars.path_x2
    end

    self.path_vars.path_y2 = self.path_next_number(self.path_vars.coords)
    self.path_vars.coords = path:sub(path:find(self.path_vars.path_y2) + #tostring(self.path_vars.path_y2), self.next_svg_command(path))
    
    if char == "m" and #self.path_vars.curr_poly > 0 then
        self.path_vars.path_y = self.path_vars.path_y + self.path_vars.path_y2
    else
        self.path_vars.path_y = self.path_vars.path_y2
    end

    -- Deduplicate consecutive points
    if self.path_vars.path_y ~= self.path_vars.curr_poly[#self.path_vars.curr_poly] or 
       self.path_vars.path_x ~= self.path_vars.curr_poly[#self.path_vars.curr_poly - 1] then
        self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_x
        self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_y
    end

    self.path_vars.first_x = self.path_vars.path_x
    self.path_vars.first_y = self.path_vars.path_y

    -- Sub-coordinates following 'm' or 'M' act as implicit 'l' or 'L'
    self.path_vars.coords = path:sub(path:find(self.path_vars.path_x2) + #tostring(self.path_vars.path_x2), self.next_svg_command(path))

    if self.path_next_number(self.path_vars.coords) then
        self.path_vars.sub_coords = self.path_vars.coords:gmatch(number_match .. comma_match .. number_match)
        for coord in self.path_vars.sub_coords do
            local dx = tonumber(self.split(coord, ",")[1])
            local dy = tonumber(self.split(coord, ",")[2])

            if char == "m" then
                -- Relative lineto (add delta to current position)
                self.path_vars.path_x = self.path_vars.path_x + dx
                self.path_vars.path_y = self.path_vars.path_y + dy
            else
                -- Absolute lineto
                self.path_vars.path_x = dx
                self.path_vars.path_y = dy
            end

            -- Deduplicate points
            if self.path_vars.path_y ~= self.path_vars.curr_poly[#self.path_vars.curr_poly] or 
               self.path_vars.path_x ~= self.path_vars.curr_poly[#self.path_vars.curr_poly - 1] then
                self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_x
                self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_y
            end
        end
    end
end

function svg_parser:parse_path_v (char)
    self.path_vars.sub_coords = self.path_vars.coords:gmatch(number_match)
    for coord in self.path_vars.sub_coords do
        local dy = tonumber(coord)
        if char == "v" then
            self.path_vars.path_y = self.path_vars.path_y + dy
        else
            self.path_vars.path_y = dy
        end

        -- Push current path_x and updated path_y
        if self.path_vars.path_y ~= self.path_vars.curr_poly[#self.path_vars.curr_poly] or 
           self.path_vars.path_x ~= self.path_vars.curr_poly[#self.path_vars.curr_poly - 1] then
            self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_x
            self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_y
        end
    end
end

function svg_parser:parse_path_h (char)
    self.path_vars.sub_coords = self.path_vars.coords:gmatch(number_match)
    for coord in self.path_vars.sub_coords do
        local dx = tonumber(coord)
        if char == "h" then
            self.path_vars.path_x = self.path_vars.path_x + dx
        else
            self.path_vars.path_x = dx
        end

        -- Push updated path_x and current path_y
        if self.path_vars.path_y ~= self.path_vars.curr_poly[#self.path_vars.curr_poly] or 
           self.path_vars.path_x ~= self.path_vars.curr_poly[#self.path_vars.curr_poly - 1] then
            self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_x
            self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_y
        end
    end
end

function svg_parser:parse_path_l (char)
	self.path_vars.sub_coords = self.path_vars.coords:gmatch(number_match .. comma_match .. number_match)

	for coord in self.path_vars.sub_coords do
		self.path_vars.path_x2 = tonumber(self.split(coord, ",")[1])
		self.path_vars.path_y2 = tonumber(self.split(coord, ",")[2])
		if char == "l" then
			self.path_vars.path_x2 = self.path_vars.path_x + self.path_vars.path_x2
			self.path_vars.path_y2 = self.path_vars.path_y + self.path_vars.path_y2
		end
		if self.path_vars.path_y2 ~= self.path_vars.curr_poly[#self.path_vars.curr_poly] or self.path_vars.path_x2 ~= self.path_vars.curr_poly[#self.path_vars.curr_poly - 1] then
			self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_x2
			self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.path_y2
			self.path_vars.path_x = self.path_vars.path_x2
			self.path_vars.path_y = self.path_vars.path_y2
		end
	end
end

function svg_parser:parse_path_c (char)
	self.path_vars.sub_coords = self:iterator_to_table(self.path_vars.coords:gmatch(number_match .. comma_match .. number_match))
	local control_points = {}
	local curve = {}

	--get the control points for the curve
	for i = 1, #self.path_vars.sub_coords do
		self.path_vars.path_x2 = tonumber(self.split(self.path_vars.sub_coords[i], ",")[1])
		self.path_vars.path_y2 = tonumber(self.split(self.path_vars.sub_coords[i], ",")[2])

		if char == "c" then
			self.path_vars.path_x2 = self.path_vars.path_x + self.path_vars.path_x2
			self.path_vars.path_y2 = self.path_vars.path_y + self.path_vars.path_y2
		end
		control_points[#control_points + 1] = self.path_vars.path_x2
		control_points[#control_points + 1] = self.path_vars.path_y2
		if #control_points == 6 then
			curve = love.math.newBezierCurve(self.path_vars.path_x, self.path_vars.path_y, unpack(control_points)):render(self.curve_detail)
			curve = self:remove_double_points(curve)
			self.path_vars.curr_poly = self:join_paths(self.path_vars.curr_poly, curve)
			self.path_vars.path_x = self.path_vars.path_x2
			self.path_vars.path_y = self.path_vars.path_y2
			control_points = {}
		end
		self.path_vars.path_x = self.path_vars.curr_poly[#self.path_vars.curr_poly - 1]
		self.path_vars.path_y = self.path_vars.curr_poly[#self.path_vars.curr_poly]
	end
end

function svg_parser:parse_path_z ()
	local return_path = nil
	self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.first_x
	self.path_vars.curr_poly[#self.path_vars.curr_poly + 1] = self.path_vars.first_y
	self.path_vars.curr_poly = self:remove_double_points(self.path_vars.curr_poly)
	return_path = self.path_vars.curr_poly
	self.path_vars.curr_poly = {}
	self.path_vars.path_x = self.path_vars.first_x
	self.path_vars.path_y = self.path_vars.first_y
	if #return_path > 3 then
		return return_path
	end
end

function svg_parser:parse_path (tag)
	self:reset_path_vars()
	local char = ""
	local return_paths = {}
	--if there's no tag_type then we just make it an edge shape
	local path = tag["@d"]
	if path then
		self.path_vars.coords = path
		local i = self.next_svg_command(path)
		while i do
			char = path:sub(i, i)
			path = path:sub(i + 1)
			self.path_vars.coords = path:sub(0, self.next_svg_command(path))
			self.path_vars.coords = self.path_vars.coords:gsub("% *[MmLlVvHhZz]", "")
			if char == "M" or char == "m" then
				if #self.path_vars.curr_poly > 4 then
					return_paths[#return_paths + 1] = self.path_vars.curr_poly
					self.path_vars.curr_poly = {}
				end
				self:parse_path_m(path, char)
			elseif char == "v" or char == "V" then
				self:parse_path_v(char)
			elseif char == "h" or char == "H" then
				self:parse_path_h(char)
			elseif char == "l" or char == "L" then
				self:parse_path_l(char)
			elseif char == "c" or char == "C" then
				self:parse_path_c(char)
			elseif char == "s" or char == "S" then
			elseif char == "q" or char == "Q" then
			elseif char == "a" or char == "A" then
			elseif char == "t" or char == "T" then
			elseif char == "z" or char == "Z" then
				return_paths[#return_paths + 1] = self:parse_path_z()
			end
			i = self.next_svg_command(path)
		end
	end
	if #self.path_vars.curr_poly > 3 then
		return_paths[#return_paths + 1] = self.path_vars.curr_poly
	end
	return return_paths
end


function svg_parser.rgb_to_color (rgb_string)
	if rgb_string and rgb_string:find("rgb%(") then
		rgb = rgb_string:gmatch("rgb%((%d-)[,)%)]")
		local color = {}
		for val in rgb do
			color[#color + 1] = tonumber(val) / 255
		end
		return color
	end
	return {0, 0, 0, 0}
end

function svg_parser.hex_to_color (hex_string, opacity)
	if hex_string then
		hex_string = hex_string:gsub("#", "")
		opacity = opacity or 1.0

		-- there was an issue with 3 digit colors
		if #hex_string == 3 then
			hex_string =
				hex_string:sub(1,1) .. hex_string:sub(1,1) ..
				hex_string:sub(2,2) .. hex_string:sub(2,2) ..
				hex_string:sub(3,3) .. hex_string:sub(3,3)
		end

		local color = {}
		local step_size = math.floor(#hex_string / 3)

		for i = 1, #hex_string, step_size do
			local hex_part = hex_string:sub(i, i + step_size - 1)
			color[#color + 1] = tonumber(hex_part, 16) / 255
		end
		color[#color + 1] = opacity
		return color
	end
	return {0, 0, 0, 0}
end

function svg_parser:parse_color (color_string)
	if color_string == nil then return nil end

	local color = {0, 0, 0, 0}
	if color_string:find("#") then
		color = self.hex_to_color(color_string)
	else
		color = self.rgb_to_color(color_string)
	end
	if color and #color < 4 then
		color[#color + 1] = 1
	end
	return color
end

return svg_parser
