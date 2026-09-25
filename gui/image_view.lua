local function ImageView(path, style)
	style = style or { aspect = "fit" }
	local image = cache.image(path)

	return {
		native_width = image:getWidth(),

		native_height = image:getHeight(),

		draw = function(self, w, h)
			local sx = 1
			local sy = 1
			if style.aspect == "fill" then
				sx = math.max(w / self.native_width, h / self.native_height)
				sy = sx
			elseif style.aspect == "fit" then
				sx = math.min(w / self.native_width, h / self.native_height)
				sy = sx
			elseif style.aspect == "stretch" then
				sx = w / self.native_width
				sy = h / self.native_height
			end

			local center_x = (w * 0.5) - (sx * self.native_width * 0.5)
			local center_y = (h * 0.5) - (sy * self.native_height * 0.5)
			local ox = center_x
			local oy = 0

			if style.align == "center" then
				oy = center_y
			elseif style.align == "bottom" then
				oy = h - (self.native_height * sy)
			end

			love.graphics.draw(image, ox, oy, 0, sx, sy)
		end,
	}

end

return ImageView