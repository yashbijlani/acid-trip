#version 300 es
// Acid Trip full-screen shader: slow continuous hue rotation + gentle UV warp.
// No strobe / no high-contrast flashing -- everything is a slow sine.
precision mediump float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;
uniform float time; // needs debug:damage_tracking = 0 (set by the theme)

vec3 hueShift(vec3 color, float hue) {
    const vec3 k = vec3(0.57735);
    float cosAngle = cos(hue);
    return color * cosAngle + cross(k, color) * sin(hue)
         + k * dot(k, color) * (1.0 - cosAngle);
}

void main() {
    vec2 uv = v_texcoord;

    // Gentle, slow liquid warp (sub-pixel scale, so text stays crisp).
    uv.x += 0.0030 * sin(uv.y * 26.0 + time * 0.55);
    uv.y += 0.0030 * sin(uv.x * 26.0 + time * 0.47);

    vec4 pixColor = texture(tex, uv);

    // Slow colour drift; mixed back with the original so it stays readable
    // and never turns into a hard colour flash.
    vec3 shifted = hueShift(pixColor.rgb, time * 0.18);
    pixColor.rgb = mix(pixColor.rgb, shifted, 0.55);

    fragColor = pixColor;
}
