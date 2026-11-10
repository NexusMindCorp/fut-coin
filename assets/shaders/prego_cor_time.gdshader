shader_type canvas_item;

uniform vec4 cor_time : source_color = vec4(0.55, 0.72, 0.92, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	float t_corpo = clamp((lum - 0.12) / 0.34, 0.0, 1.25);
	vec3 corpo_colorido = clamp(cor_time.rgb * t_corpo, 0.0, 1.0);
	float peso_contorno = smoothstep(0.12, 0.22, lum);
	float peso_brilho = smoothstep(0.76, 0.88, lum);
	vec3 rgb_final = mix(tex.rgb, corpo_colorido, peso_contorno);
	rgb_final = mix(rgb_final, tex.rgb, peso_brilho);
	COLOR = vec4(rgb_final, tex.a);
}
