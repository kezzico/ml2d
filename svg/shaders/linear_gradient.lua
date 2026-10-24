-- linear gradient shader
-- available data needed to render the linear gradient
-- {["type"]="linear_gradient",["transform"]={[1]=1.95982,[2]=738.929,[3]=-11.2585,[4]=0.0298601,[5]=2126,[6]=27.6651,},["stops"]={[1]={["offset"]="0",["color"]="ffdad2",},[2]={["offset"]="1",["color"]="ff6c6d",},},}

-- the transformation matrix of the shader is used to transform the position of the fragment coordinates so that the gradient can be applied correctly according to the specified transform.
-- the stops define the color stops of the gradient. index 0 is the first stop, index 1 is the next stop. each stop is divided evenly over the range from 0 to 1, where 0 represents the start of the gradient and 1 represents the end of the gradient.

-- the parameters needed by the shader to do this are the transformation matrix and the color stops, which will be used to calculate the color of each fragment based on its position relative to the gradient.


local shader_source =[[
extern float stop_offsets[8];
extern float stop_colors[32];
extern int stop_count;

extern vec2 gradient_bounds; // e.g., the total SVG canvas width & height
extern mat3 transform;

// returns vec4 with rgba from index i*4
vec4 get_stop_color(int i) {
    return vec4(
        stop_colors[i * 4 + 0],
        stop_colors[i * 4 + 1],
        stop_colors[i * 4 + 2],
        stop_colors[i * 4 + 3]
    );
}

// max of 4 color stops
vec4 gradient_color(float t) {
    // Before first stop
    if (t <= stop_offsets[0])
        return get_stop_color(0);

    // Find the pair containing t
    for (int i = 0; i < stop_count - 1; i++) {
        float a = stop_offsets[i];
        float b = stop_offsets[i + 1];

        if (t <= b) {
            float f = (t - a) / (b - a);
            return mix(
                get_stop_color(i),
                get_stop_color(i + 1),
                f
            );
        }
    }

    // After last stop
    return get_stop_color(stop_count - 1);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    // size of the svg image (2413x800 in my test graphic) as gradient_bounds.
    // but we send every triangle to the shader individually... so this breaks
    vec2 canvas_pixels = uv * gradient_bounds;

    // then get the position on the gradient by reversing the transform
    // and applying it to canvas_pixel
    vec3 local_pos = inverse(transform) * vec3(canvas_pixels, 1.0);

    // affinity gradients always runs on the X axis,
    // so assume local_pos.y will be 0 after applying the inverse transform
    float t = clamp(local_pos.x, 0.0, 1.0);

    // look through the stops and mix the right color based on t
    return gradient_color(t);
}

]]

-- local shader_source =[[
-- extern vec4 color_stop_1;
-- extern vec4 color_stop_2;
-- extern vec2 gradient_bounds; // e.g., the total SVG canvas width & height
-- extern mat3 transform;

-- vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
--     //mat3 svg_matrix = mat3(
--     //        5.63357e-14,  920.032,      0.0,  // Column 1 (a, b, 0)
--     //       -5621.72,      3.44231e-13,  0.0,  // Column 2 (c, d, 0)
--     //        2296.32,      677.0,        1.0   // Column 3 (e, f, 1)
--     //    );
--     // 1. Convert local shape UV (0-1) to absolute SVG canvas pixel coordinates
--     vec2 canvas_pixels = uv * gradient_bounds;
    
--     // 2. Bring those canvas pixels into the gradient's local 0-1 space using the inverse matrix
--     vec3 local_pos = inverse(transform) * vec3(canvas_pixels, 1.0);
    
--     // 3. Sample along the Y axis of the gradient space (or whichever axis the matrix targets)
--     float t = clamp(local_pos.x, 0.0, 1.0);
    
--     return mix(color_stop_1, color_stop_2, t);
-- }
-- ]]
love.graphics.validateShader(true, shader_source)
local shader = love.graphics.newShader(shader_source)

return shader