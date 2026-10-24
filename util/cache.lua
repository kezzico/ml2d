local svg_parser = require "ml2d.svg.parser"

function Cache()
	local font_cache = { }

	local image_cache = { }

	local svg_cache = { }
	
	return {
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
			local font = font_cache[params]

			if font == nil then
				-- print("[cache] cache hit for font "..params[1], "key="..params)
				local fontfile = params and params[1]
				if fontfile == nil then
					print("ERROR: font path missing")
					return nil
				end

				local fontsize = params and params.size or 120
				local hinting = params and params.hinting or "normal"
				local dpi = 3 -- params and params.dpi or 3.0
				
				font = love.graphics.newFont(fontfile, fontsize, hinting, dpi)

				font_cache[params] = font
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