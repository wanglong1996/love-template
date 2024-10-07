// #pragma language glsl3
#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 amount;


// tc 纹理坐标左上角(0,0)，右下角(1,1)
// pc 屏幕像素坐标，非归一化坐标
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    return color * vec4( Texel(texture, tc-amount).r, Texel(texture, tc).g,
    Texel(texture, tc + amount).b, Texel(texture, tc).a);
}
