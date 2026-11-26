shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 light_color : source_color = vec4(0.4, 0.7, 0.35, 1.0);
uniform vec4 dark_color : source_color = vec4(0.05, 0.1, 0.08, 1.0);
uniform vec4 stripe_color : source_color = vec4(0.1, 0.15, 0.12, 1.0);
uniform float stripe_width : hint_range(0.01, 1.0) = 0.1;
uniform float stripe_angle : hint_range(0.0, 6.28) = 0.785; // 45 deg
uniform float stripe_scale : hint_range(0.0, 50.0) = 15.0;

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float lit = step(0.0, NdotL); // HARD cutoff, no smoothstep = no blend

    // diagonal stripes using rotated world-space coords
    float c = cos(stripe_angle);
    float s = sin(stripe_angle);
    float diag = world_pos.x * c + world_pos.y * s;
    float stripe = step(stripe_width, fract(diag * stripe_scale));

    vec3 base = mix(dark_color.rgb, light_color.rgb, lit);
    // only apply stripes where it's dark (lit == 0)
    vec3 final_col = mix(mix(stripe_color.rgb, dark_color.rgb, stripe), base, lit);

    DIFFUSE_LIGHT = final_col;
}