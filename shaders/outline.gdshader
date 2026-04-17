shader_type canvas_item;
render_mode unshaded;

uniform float thickness : hint_range(0.0, 100.0);
uniform int ring_count : hint_range(1, 128) = 16;
uniform float ring_offset : hint_range(0.0, 1.0, 0.01);
uniform vec4 outline_color : source_color;
uniform bool border_clipping_fix = true;
uniform float aspect_ratio : hint_range(0.1, 10.0, 0.01) = 1.0;
uniform bool square_border = false;
uniform vec2 offset;
uniform bool max_or_add = false;
uniform vec2 sprite_texture_size = vec2(128.0, 128.0);
uniform float mask_luma_threshold : hint_range(0.0, 1.0) = 0.30;
uniform float fill_alpha_multiplier : hint_range(0.0, 1.0) = 1.0;

float masked_alpha(vec4 c) {
	float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	return c.a * step(luma, mask_luma_threshold);
}

void vertex() {
	if (border_clipping_fix) {
		vec2 o = (UV * 2.0 - 1.0);
		VERTEX += o * thickness - offset;
		VERTEX.x *= 1.0 + (aspect_ratio - 1.0) * (thickness / max(sprite_texture_size.x, 1.0)) * 2.0;
	}
}

vec2 square(float i) {
	i *= 2.0;
	return (vec2(
		clamp(abs(mod(i, 2.0) - 1.0), 0.25, 0.75),
		clamp(abs(mod(i + 0.5, 2.0) - 1.0), 0.25, 0.75)
	) - 0.5) * 4.0;
}

vec4 tex(sampler2D sampler, vec2 uv) {
	if (uv.x > 0.0 && uv.y > 0.0 && uv.x < 1.0 && uv.y < 1.0) {
		return texture(sampler, uv);
	}
	return vec4(0.0);
}

void fragment() {
	vec2 logical_size = max(sprite_texture_size, vec2(1.0));
	vec2 o = offset / logical_size;

	vec2 uv = UV;
	uv -= vec2(0.5);

	if (border_clipping_fix) {
		uv.x *= 1.0 + (aspect_ratio - 1.0) * thickness / logical_size.x * 2.0;
		uv *= (1.0 + (thickness / logical_size) * 2.0);
		uv -= o;
	}

	uv += vec2(0.5);
	vec2 size = vec2(thickness) / logical_size;

	vec4 sprite_color = tex(TEXTURE, uv);
	float sprite_alpha = sprite_color.a;
	float shape_alpha = masked_alpha(sprite_color);
	float alpha = sprite_alpha;

	if (square_border) {
		for (int i = 0; i < ring_count; ++i) {
			float r = float(i) / float(ring_count) + ring_offset;
			alpha = max(
				alpha,
				masked_alpha(tex(TEXTURE, uv + o + size * square(r) * vec2(aspect_ratio, 1.0))) * outline_color.a
			);
		}
	} else {
		for (int i = 0; i < ring_count; ++i) {
			float r = float(i) * 3.14159 / float(ring_count) * 2.0 + ring_offset;
			vec2 sample_offset = vec2(size.x * sin(r) * aspect_ratio, size.y * cos(r));

			if (max_or_add) {
				alpha += masked_alpha(tex(TEXTURE, uv + o + sample_offset)) * outline_color.a;
			} else {
				alpha = max(alpha, masked_alpha(tex(TEXTURE, uv + o + sample_offset)) * outline_color.a);
			}
		}
	}

	alpha = max(alpha, sprite_alpha);

	float outline_alpha = max(alpha - sprite_alpha, 0.0);
	float fill_alpha = sprite_alpha * fill_alpha_multiplier;
	float final_alpha = clamp(outline_alpha + fill_alpha, 0.0, 1.0);

	vec3 final_rgb = outline_color.rgb;
	if (fill_alpha > 0.0) {
		final_rgb = mix(outline_color.rgb, sprite_color.rgb, clamp(fill_alpha, 0.0, 1.0));
	}

	COLOR = vec4(final_rgb, final_alpha);
}