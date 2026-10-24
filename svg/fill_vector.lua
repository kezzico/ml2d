local shaders = { 
	linear_gradient = require "ml2d.svg.shaders.linear_gradient",
	image = require "ml2d.svg.shaders.image"
}

local function fill_vector(fill, render)
	if fill == nil then return end

	if fill.type == "color" then
		love.graphics.push("all")
		love.graphics.setColor(fill.color)
		render()
		love.graphics.pop()
	elseif fill.type == "image" then
		local shader = shaders.image
		shader:send("svg_image", fill.image)
		love.graphics.setShader(shader)
		render()
		love.graphics.setShader()

	elseif fill.type == "linear_gradient" then
		local shader = shaders.linear_gradient
		shader:send("stop_colors", unpack(fill.stop_colors))
		shader:send("stop_offsets", unpack(fill.stop_offsets))
		shader:send("stop_count", #fill.stop_offsets)
		shader:send("transform", "row", fill.transform)
		shader:send("gradient_bounds", {fill.width, fill.height})
		love.graphics.setShader(shader)
		render()
		love.graphics.setShader()
	end
end

return fill_vector