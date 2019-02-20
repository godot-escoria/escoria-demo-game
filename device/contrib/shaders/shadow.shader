shader_type canvas_item;
render_mode blend_mix;

uniform float alpha_value = 0.5;

void fragment() {
	float v = texture(TEXTURE, UV).a;
	COLOR = vec4(vec3(0), v*alpha_value);
}

