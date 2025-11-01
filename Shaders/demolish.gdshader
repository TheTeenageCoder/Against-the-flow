// Filename: vertex_corners.gdshader
shader_type spatial;

// 'unshaded' for that sci-fi look
// 'blend_mix' to allow for transparency
// 'cull_disabled' lets you see the wires from inside, which can be cool.
// Use 'cull_back' if you only want to see the outside.
render_mode unshaded, blend_mix, cull_disabled;

// The color of your corner wires
uniform vec4 wire_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Red, like your image

// --- IMPORTANT ---
// A default Godot BoxMesh is 1x1x1, so its vertices
// are at +/- 0.5. Set this to 0.5.
// If you use a 2x2x2 BoxMesh, set this to 1.0.
uniform float cube_half_size : hint_range(0.1, 10.0) = 0.5;

// How thick the wire lines are (in 3D units)
uniform float wire_thickness : hint_range(0.001, 0.2) = 0.02;

// How long the wire segments are (as a percentage of half_size)
uniform float corner_length_pct : hint_range(0.0, 1.0) = 0.3; // 30%

// We need to pass the vertex's 3D local position to the fragment shader.
// 'varying' is the keyword for that.
varying vec3 v_local_pos;

void vertex() {
	// Pass the untransformed vertex position to the fragment function.
	// This will be interpolated for every pixel.
	v_local_pos = VERTEX;
}

void fragment() {
	// 1. --- Define our boundaries ---

	// 'v_local_pos' is the 3D position of *this specific pixel*
	// in the cube's local space. We use abs() because a
	// cube is symmetrical.
	vec3 abs_pos = abs(v_local_pos);

	// 'edge_pos' is the 3D coordinate where the "wire" starts.
	// e.g., if half_size is 0.5 and thickness is 0.02,
	// this will be 0.48.
	float edge_pos = cube_half_size - wire_thickness;

	// 'corner_limit' is how far the wire extends from the vertex.
	// e.g., if half_size is 0.5 and length_pct is 0.3,
	// this will be 0.5 - (0.5 * 0.3) = 0.5 - 0.15 = 0.35.
	float corner_limit = cube_half_size - (cube_half_size * corner_length_pct);


	// 2. --- Find the wires ---

	// A pixel is on a wire *parallel to the X-axis* if:
	// 1. Its Y-position is on the "edge" (abs_pos.y > edge_pos)
	// 2. Its Z-position is also on the "edge" (abs_pos.z > edge_pos)
	// 3. Its X-position is within the "corner zone" (abs_pos.x > corner_limit)
	bool x_seg = (abs_pos.y > edge_pos && abs_pos.z > edge_pos) &&
	             (abs_pos.x > corner_limit);

	// A pixel is on a wire *parallel to the Y-axis* if:
	// 1. Its X-position is on the "edge"
	// 2. Its Z-position is on the "edge"
	// 3. Its Y-position is within the "corner zone"
	bool y_seg = (abs_pos.x > edge_pos && abs_pos.z > edge_pos) &&
	             (abs_pos.y > corner_limit);

	// A pixel is on a wire *parallel to the Z-axis* if:
	// 1. Its X-position is on the "edge"
	// 2. Its Y-position is on the "edge"
	// 3. Its Z-position is within the "corner zone"
	bool z_seg = (abs_pos.x > edge_pos && abs_pos.y > edge_pos) &&
	             (abs_pos.z > corner_limit);

	// 3. --- Draw or Discard ---
	if (x_seg || y_seg || z_seg) {
		// This pixel is part of a corner wire. Draw it.
		ALBEDO = wire_color.rgb;
		ALPHA = wire_color.a;
	} else {
		// This pixel is not part of a wire. Make it invisible.
		discard;
	}
}