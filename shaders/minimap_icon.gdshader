shader_type canvas_item;
render_mode unshaded;

uniform float saturation : hint_range(0.0, 1.0) = 1.0;
uniform float icon_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = vec3(gray);
	vec3 final_rgb = mix(desaturated, tex.rgb, saturation);

	COLOR = vec4(final_rgb, tex.a * icon_alpha);
}