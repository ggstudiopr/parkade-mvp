shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
// Shader parameters
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.015;
uniform float noise_intensity : hint_range(0.0, 0.2) = 0.03;
uniform float noise_speed : hint_range(0.0, 10.0) = 1.0;
uniform float color_aberration : hint_range(0.0, 0.1) = 0.00175;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.6;
// Monotone settings
uniform vec3 tint_color : source_color = vec3(0.2, 0.5, 0.7); // Default blue-ish tone
uniform float monotone_strength : hint_range(0.0, 1.0) = 0.2; // How strong the monotone effect is

// Pseudo-random function for noise with time-based variation
float random(vec2 st, float time) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233)) + time) * 43758.5453123);
}

void fragment() {
    // Get centered UV coordinates
    vec2 uv = UV * 2.0 - 1.0;
    // Fisheye-like distortion (slightly more pronounced)
    float r = length(uv);
    float distortion = 1.0 + r * r * distortion_strength;
    vec2 distorted_uv = uv / distortion;
    // Convert back to 0-1 range
    distorted_uv = distorted_uv * 0.5 + 0.5;
    // Color aberration effect
    vec2 red_uv = distorted_uv + vec2(color_aberration, 0.0);
    vec2 blue_uv = distorted_uv - vec2(color_aberration, 0.0);
    // Sample screen texture with color channels slightly offset
    float red = texture(SCREEN_TEXTURE, red_uv).r;
    float green = texture(SCREEN_TEXTURE, distorted_uv).g;
    float blue = texture(SCREEN_TEXTURE, blue_uv).b;
    // Combine color channels
    vec3 color = vec3(red, green, blue);

    // Convert to grayscale using luminance values
    float gray = dot(color, vec3(0.299, 0.587, 0.114));

    // Apply monotone tint
    vec3 monotone = gray * tint_color;

    // Mix between original color and monotone based on strength
    color = mix(color, monotone, monotone_strength);

    // Add dynamic noise with time variation
    float noise = random(distorted_uv * 10.0, TIME * noise_speed) * noise_intensity;
    color += noise;
    // Vignette effect
    float vignette = 1.0 - length(uv) * vignette_strength;
    color *= vignette;
    // Final color output
    COLOR = vec4(color, 1.0);
}