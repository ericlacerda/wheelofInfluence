shader_type canvas_item;

uniform vec4 burn_color1 : source_color = vec4(0.851, 0.169, 0.169, 1.0); // #D92B2B
uniform vec4 burn_color2 : source_color = vec4(0.651, 0.106, 0.204, 1.0); // #A61B34
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale = 15.0;  // Reduzido ainda mais para padrões maiores
uniform float edge_width = 0.25;   // Aumentado para bordas mais largas

// Função de ruído 2D
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Ruído de valor simplex
float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    // Quatro cantos no quadrado de inteiros
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    // Interpolação cúbica
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Ruído de turbulência (usado para o efeito de fogo)
float turbulence(vec2 uv, float size) {
    float value = 0.0;
    float scale = 1.0;
    
    for (int i = 0; i < 6; i++) {
        value += noise(uv * scale) * (1.0 / scale);
        scale *= 2.0;
    }
    
    return value;
}

void fragment() {
    // Obter coordenadas UV normalizadas (0 a 1) com centro na carta
    vec2 uv = UV * 2.0 - 1.0;
    
    // Calcular distância do centro
    float distance_from_center = length(uv);
    
    // Calcular ruído baseado na posição
    float noise_value = turbulence(UV * noise_scale + vec2(TIME * 0.3, TIME * 0.2), 8.0);
    
    // Calcular borda do efeito de dissolução baseado no progresso
    float dissolution_edge = progress + noise_value * 0.5;  // Aumentado para ainda mais variação
    
    // Criar o efeito de borda
    float edge_factor = smoothstep(dissolution_edge - edge_width, dissolution_edge, distance_from_center);
    
    // Misturar cores para o efeito de fogo
    vec4 fire_color = mix(burn_color1, burn_color2, noise_value);
    
    // Aplicar pulso para parecer que está queimando
    float pulse = sin(TIME * 4.0 + UV.y * 8.0) * 0.2 + 0.8;  // Pulso mais intenso
    fire_color *= pulse;
    
    // Aumentar o brilho do fogo
    fire_color.rgb *= 1.3;  // 30% mais brilhante
    
    // Definir transparência baseada na borda da dissolução
    float alpha = (1.0 - edge_factor) * (1.0 - progress * 0.5);  // Reduzido para manter mais opacidade
    
    // Adicionar um pouco de brilho no centro do fogo
    fire_color += vec4(0.4, 0.15, 0.0, 0.0) * (1.0 - distance_from_center) * (1.0 - progress);
    
    // Saída final
    COLOR = fire_color;
    COLOR.a *= alpha;
} 