-- linear gradient shader
-- available data needed to render the linear gradient
-- {["type"]="linear_gradient",["transform"]={[1]=1.95982,[2]=738.929,[3]=-11.2585,[4]=0.0298601,[5]=2126,[6]=27.6651,},["stops"]={[1]={["offset"]="0",["color"]="ffdad2",},[2]={["offset"]="1",["color"]="ff6c6d",},},}

-- the transformation matrix of the shader is used to transform the position of the fragment coordinates so that the gradient can be applied correctly according to the specified transform.
-- the stops define the color stops of the gradient. index 0 is the first stop, index 1 is the next stop. each stop is divided evenly over the range from 0 to 1, where 0 represents the start of the gradient and 1 represents the end of the gradient.

-- the parameters needed by the shader to do this are the transformation matrix and the color stops, which will be used to calculate the color of each fragment based on its position relative to the gradient.


local shader_source =[[
extern Image svg_image;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc)
{
    vec4 image_color = Texel(svg_image, uv);

    return image_color;
}
]]
love.graphics.validateShader(true, shader_source)
local shader = love.graphics.newShader(shader_source)

return shader
