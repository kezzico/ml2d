local svg_parser = require "ml2d.svg.parser"

local function Cache()
	local font_cache = { }

	local image_cache = { }

	local svg_cache = { }

	local json_cache = { }
	
	return {
		json = function(url, json_text)
			local url_as_key = url:gsub("[^%w]", "_")
			local json_file_path = "json/" .. url_as_key
			-- save to cache mode
			if json_text ~= nil then
				print("[CACHE] saving json to cache for url "..url_as_key)
				json_cache[url_as_key] = json_text
				love.filesystem.createDirectory("json")
				love.filesystem.write(json_file_path, json_text)

			-- load from cache mode
			elseif json_cache[url_as_key] ~= nil then
				print("[CACHE] loading json from in memory cache for url "..url_as_key)
				return json_cache[url_as_key]
			else
				json_text = love.filesystem.read("string", json_file_path)

				print("[CACHE] loading json from disk for url "..url_as_key)
				print("[CACHE] json text: "..tostring(json_text))
				return json_text
			end
		end,


		svg = function(svgname)
			if svg_cache[svgname] == nil then
				print("[cache hit]", svgname)
				local svg_text = love.filesystem.read("string", svgname)
				local svg_dom = svg_parser:parse(svg_text)

				svg_cache[svgname] = svg_dom

				return svg_dom
			else
				return svg_cache[svgname]
			end
		end,

		font = function(params)
			local fontfile = params and params[1]
			if fontfile == nil then
				print("[cache] font path missing")
				return nil
			end

			local fontsize = params.size or params[2] or 120
			local hinting = params.hinting or "none"
			local dpi = params.dpi or 1.0
			local key = table.concat({
				fontfile,
				tostring(fontsize),
				hinting,
				tostring(dpi)
			}, "\0")

			local font = font_cache[key]
			if font == nil then
				font = love.graphics.newFont(fontfile, fontsize, hinting, dpi)
				font_cache[key] = font
			end

			return font
		end,

		image = function(imagename)
			local key = imagename

			local image = image_cache[key]

			if image == nil then
				print("[cache] loading key "..key)
				image = love.graphics.newImage(key, { mipmaps = true, linear = true, dpiscale = 1.0 })
				print("[cache] loaded key "..key)
				image_cache[key] = image
			end

			return image
		end,

		quads = function(ent_style)

			print("loading quads for "..ent_style.imagepath)
			local key = ent_style.imagepath

			local image = image_cache[key]

			if image == nil then
				image = love.graphics.newImage(key, { })

				image_cache[key] = image
			end

			local image_width = image:getWidth()

			local image_height = image:getHeight()

			local num_hcells = math.floor(image_width / ent_style.frame_width)

			local num_vcells = math.floor(image_height / ent_style.frame_height)

			local num_quads = num_hcells * num_vcells

			local quads = { }

			for frame = 1, num_quads do
				local offset_x = ((frame-1) % num_hcells) * ent_style.frame_width

				local offset_y = math.floor((frame-1) / num_hcells) * ent_style.frame_height

				-- print('quad frame#'..frame..' x,y:'..offset_x..','..offset_y)
				local quad = love.graphics.newQuad(
					offset_x, offset_y, 
					ent_style.frame_width, ent_style.frame_height,
					image)

				table.insert(quads, quad)
		    end

			return quads
		end
	}
end

return Cache