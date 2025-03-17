shader_type canvas_item;

uniform vec4 glow_color  = vec4(1.0, 0.8, 0.5, 1.0); // колір підсвічування
uniform float glow_strength : hint_range(0.0, 2.0) = 1.0; // сила підсвічування
uniform float time : hint_range(0.0, 10.0); // час для анімації (оновлюється через GDScript)

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Визначаємо позицію пікселя відносно центру (0.5, 0.5)
    vec2 centered_uv = UV - vec2(0.5);
    float dist = length(centered_uv);
    
    // Обчислюємо легке пульсування (мігання) підсвічування
    float flicker = 0.5 + 0.5 * sin(time * 3.0);
    
    // Використовуємо smoothstep для створення плавного переходу підсвічування по краям
    float glow = smoothstep(0.3, 0.5, dist) * glow_strength * flicker;
    
    // Додаємо підсвічування до базового кольору (емісійним шляхом)
    vec4 result = tex_color + glow_color * glow;
    result.a = tex_color.a; // зберігаємо альфа-канал
    COLOR = result;
}
