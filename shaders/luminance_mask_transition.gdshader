shader_type canvas_item;

uniform float progress: hint_range(0.0, 1.0) = 0.0;
uniform bool reverse = false;
uniform sampler2D mask_texture : source_color;
uniform vec4 fill_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 sample_color = texture(mask_texture, UV);
	float luminance = dot(sample_color.rgb, vec3(0.2126, 0.7152, 0.0722));
	float cutoff = reverse ? (1.0 - progress) : progress;
	float alpha = luminance <= cutoff ? 1.0 : 0.0;

	COLOR = vec4(fill_color.rgb, fill_color.a * alpha);
}