shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.02;

void fragment() {
    // Get centered UV coordinates
    vec2 uv = UV * 2.0 - 1.0;

    // Calculate fisheye distortion (much milder)
    float r = length(uv);
    float distortion = 1.0 + r * r * distortion_strength;

    // Apply the distortion
    vec2 distorted_uv = uv / distortion;

    // Convert back to 0-1 range
    distorted_uv = distorted_uv * 0.5 + 0.5;

    // Sample the screen texture with the distorted coordinates
    COLOR = texture(SCREEN_TEXTURE, distorted_uv);
}