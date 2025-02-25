shader_type canvas_item;

#include "simplex_noise.gdshaderinc"

float simpleNoise(vec3 pos, int numLayers, float scale, float persistence, float lacunarity, float multiplier) {
	float noiseSum = 0.0;
	float amplitude = 1.0;
	float frequency = scale;
	for (int i = 0; i < numLayers; i ++) {
		noiseSum += snoise(vec4(pos * frequency, 1.0)) * amplitude;
		amplitude *= persistence;
		frequency *= lacunarity;
	}
	return noiseSum * multiplier;
}


float simplerNoise(vec3 pos, float scale, float multiplier) {
	const int numLayers = 4;
	const float persistence = .5;
	const float lacunarity = 2.0;

	return simpleNoise(pos, numLayers, scale, persistence, lacunarity, multiplier);
}

float simplestNoise(vec3 pos) {
	const float scale = 1.0;
	const float multiplier = 1.0;

	return simplerNoise(pos, scale, multiplier);
}

float fractalNoise(vec3 pos) {
	int numLayers = 5;
	float noiseSum = 0.0;
	float amplitude = 1.0;
	float frequency = 1.0;
	float lacunarity = 2.0;
	float persistence = 0.5;
    for (int i = 0; i < numLayers; i++) {
        noiseSum += snoise(vec4(pos * frequency, 1.0)) * amplitude;
        frequency *= lacunarity;
        amplitude *= persistence;
    }
    return noiseSum;
}

vec4 fractalNoiseGrad(vec3 pos, int numLayers, float scale, float persistence, float lacunarity) {
    vec4 noise = vec4(0);
    float amplitude = 1.0;
    float frequency = scale;
    for (int i = 0; i < numLayers; i ++) {
        noise += snoise_grad(pos * frequency) * amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return noise;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	int numLayers = 4;
	float scale = 1.0;
	float persistence = 0.5;
	float lacunarity = 2.0;
	float multiplier = 1.0;

	//vec4 value = snoise_grad(vec3(UV.x, UV.y, 0));
	vec4 v0 = fractalNoiseGrad(vec3(UV.x, UV.y, TIME / 16.0), numLayers, scale, persistence, lacunarity);
	//vec4 value0 = vec4(fractalNoise(vec3(UV, 1.0)));

	vec4 v1 = fractalNoiseGrad(vec3(UV.x, UV.y, TIME / 32.0), numLayers * 2, scale * 2.0, persistence * 2.0, lacunarity * 0.8);

	//vec4 v2 = vec4(v0.r + v1.r, v0.g + v1.g, v0.b + v1.b, 1.0);
	vec4 v2 = (v0 + v1) / 2.0;
	v2.r = sin(v2.r) * 0.75 + cos(v2.a) * 0.25;
	v2.a = 1.0;

	COLOR = v2;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
