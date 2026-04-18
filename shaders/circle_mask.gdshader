shader_type canvas_item;

uniform sampler2D viewport_tex : source_color;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.5;
uniform float edge_softness = 0.002;

void fragment() {
	vec2 uv = UV;
	float dist = distance(uv, center);

	if (dist > radius) {
		discard;
	}

	vec4 viewport_color = texture(viewport_tex, uv);
	COLOR = viewport_color * COLOR;
}