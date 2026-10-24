SVG_POLYGON_MODE = "fill"

local prepare_for_triangulation = require "ml2d.svg.prepare_for_triangulation"
local fill_vector = require "ml2d.svg.fill_vector"

-- refactor to use meshes
-- https://github.com/Clemapfel/love-cookbook/blob/main/content/guides/advanced/meshes.md#03-creating-a-polygon-mesh-using-triangulation
local function svg_render(v)
	if v.type == "group" or v.type == nil then
		local stencil_value = 1

		if v.clip_path then
			love.graphics.clear(false, true)   -- clear stencil, not color
			love.graphics.setStencilMode("draw", stencil_value)
			love.graphics.setColorMask(false, false, false, false)

			for ic = 1, #v.clip_path do
				svg_render(v.clip_path[ic])
			end
			
			love.graphics.setStencilMode("test", stencil_value)
			love.graphics.setColorMask(true, true, true, true)
		end

		for i = 1, #v do
			svg_render(v[i])
		end

		if v.clip_path then
			love.graphics.setStencilMode("off")
		end
		-- render clippath for debug mode
		if v.clip_path then
			SVG_POLYGON_MODE = "line"
			for ic = 1, #v.clip_path do
				svg_render(v.clip_path[ic])
			end
			SVG_POLYGON_MODE = "fill"
		end
		
	elseif v.type == "circle" then
		fill_vector(v.fill, function()
			love.graphics.circle(SVG_POLYGON_MODE, v[1], v[2], v[3], 48)
		end)
	elseif v.type == "ellipse" then
		fill_vector(v.fill, function()
			love.graphics.ellipse(SVG_POLYGON_MODE, v[1], v[2], v[3], v[4], 48)
		end)
	elseif v.type == "rect" then
		fill_vector(v.fill, function() 
			love.graphics.rectangle(SVG_POLYGON_MODE, v[1], v[2], v[3], v[4])
		end)
	elseif v.type == "path" then
		for i = 1, #v do 
			local path = v[i]
			if path.triangles == nil then 
				-- print("[renderer] triangulating path", path.triangles)
				path.triangles = love.math.triangulate(prepare_for_triangulation(path))
			end

			fill_vector(v.fill, function()
				for k = 1, #path.triangles do
					love.graphics.polygon(SVG_POLYGON_MODE, path.triangles[k])
				end
			end)
		end
	end
end

return svg_render