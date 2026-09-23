shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform sampler2D noise_texture : repeat_enable;
uniform vec2 scroll_speed = vec2(0.05, 0.05);

varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    // Coordenadas globais para que a névoa não se mova com a câmera de forma bizarra
    vec2 uv = (world_pos / 1500.0) + (TIME * scroll_speed);
    
    // Amostra do ruído (assumindo uma textura em preto e branco)
    float noise_val = texture(noise_texture, uv).r;
    
    // Aplica o ruído ao alpha para criar a transparência da névoa
    // Usamos um smoothstep para aumentar o contraste da névoa (deixar mais encorpada)
    float fog_alpha = smoothstep(0.2, 0.8, noise_val);
    
    COLOR = fog_color;
    COLOR.a *= fog_alpha;
}
