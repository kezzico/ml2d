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

extern mat3 transform;
varying vec2 svg_position;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    svg_position = vertex_position.xy;
    return transform_projection * vertex_position;
}
#endif

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
    vec3 local_pos = inverse(transform) * vec3(svg_position, 1.0);

    // affinity gradients always runs on the X axis,
    // so assume local_pos.y will be 0 after applying the inverse transform
    float t = clamp(local_pos.x, 0.0, 1.0);

    // look through the stops and mix the right color based on t
    return gradient_color(t);
}

]]
love.graphics.validateShader(true, shader_source)
local shader = love.graphics.newShader(shader_source)

return shader