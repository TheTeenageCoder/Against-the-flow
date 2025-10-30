shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_disabled, fog_disabled;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.2);
uniform float grid_size = 0.01; // 1 unit per cube grid

void fragment() {
    // UV repeats to create the grid pattern
    vec2 grid = fract(UV * (1.0 / grid_size));
    float line_x = step(grid.x, 0.01) + step(0.98, grid.x);
    float line_y = step(grid.y, 0.01) + step(0.98, grid.y);
    float line = clamp(line_x + line_y, 0.0, 1.0);

    vec4 color = line_color;
    color.a *= line;
    ALBEDO = color.rgb;
    ALPHA = color.a;
}