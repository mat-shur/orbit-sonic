shader_type canvas_item;

uniform float progress = 0.0; // Прогрес, пов'язаний зі score
uniform float edge_fade = 0.2; // Ширина фейду країв (можна регулювати)

void fragment() {
    // Зсув UV координат на основі прогресу
    vec2 new_uv = vec2(UV.x, UV.y + progress);
    vec4 tex_color = texture(TEXTURE, new_uv);

    // Обчислення фейду країв
    // Визначаємо відстань до краю
    float fade = 1.0;
    fade *= smoothstep(0.0, edge_fade, UV.x); // Ліва грань
    fade *= smoothstep(0.0, edge_fade, UV.x); // Права грань
    fade *= smoothstep(0.0, edge_fade, 0.85 - UV.y); // Нижня грань
    fade *= smoothstep(0.0, edge_fade,  UV.y - 0.15); // Верхня грань

    // Застосування фейду до альфа-каналу
    tex_color.a *= fade;

    COLOR = tex_color;
}
