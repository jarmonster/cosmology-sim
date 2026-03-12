uniform float uTime;
uniform vec2 uResolution;
uniform vec3 uCamPos;
uniform mat4 uCamRot;
uniform int uMetricType; // 0: Schwarzschild, 1: RN, 2: Kerr
uniform float uMass;
uniform float uCharge;
uniform float uSpin;

varying vec2 vUv;

#define MAX_STEPS 150
#define STEP_SIZE 0.15
#define MAX_STEP  2.5
#define MIN_STEP  0.05
#define MAX_DIST  100.0
#define PI 3.14159265359

// ─── Hash / Noise (no sin — cheaper on GPU) ──────────────────────────────────

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    // Unique z encoding prevents correlation across z slices
    vec2 z0 = vec2(i.z * 127.1,         i.z * 311.7);
    vec2 z1 = vec2((i.z + 1.0) * 127.1, (i.z + 1.0) * 311.7);
    return mix(
        mix(mix(hash(i.xy + vec2(0,0) + z0), hash(i.xy + vec2(1,0) + z0), f.x),
            mix(hash(i.xy + vec2(0,1) + z0), hash(i.xy + vec2(1,1) + z0), f.x), f.y),
        mix(mix(hash(i.xy + vec2(0,0) + z1), hash(i.xy + vec2(1,0) + z1), f.x),
            mix(hash(i.xy + vec2(0,1) + z1), hash(i.xy + vec2(1,1) + z1), f.x), f.y),
        f.z);
}

// ─── Background ──────────────────────────────────────────────────────────────

vec3 getBackground(vec3 dir) {
    float n    = hash(floor(dir.xy * 300.0) + floor(dir.zx * 300.0));
    float star = step(0.998, n);
    float band = pow(max(0.0, 1.0 - abs(dir.y)), 8.0);
    vec3 galaxy = vec3(0.05, 0.1, 0.3) * band
                + vec3(0.2, 0.1, 0.2) * noise(dir * 8.0) * band;
    return galaxy + vec3(star);
}

// ─── Accretion Disk (called at crossing points only) ─────────────────────────

vec4 getAccretionDisk(vec3 pos) {
    float r = length(pos);
    float innerR = 3.0 * uMass;
    float outerR = 15.0 * uMass;
    if (r < innerR || r > outerR) return vec4(0.0);

    float doppler  = 1.0 + 0.3 * pos.x / r;
    float angle    = atan(pos.z, pos.x);
    float speed    = 2.0 / sqrt(r);
    float n        = noise(vec3(pos.x, pos.y * 5.0, pos.z) * 1.5
                         + vec3(angle * 3.0 + uTime * speed, 0.0, 0.0));
    float intensity = (1.0 / (r * r * 0.1)) * n * 2.0 * doppler;
    vec3  col       = mix(vec3(1.0, 0.2, 0.1), vec3(0.2, 0.4, 1.0), 5.0 / r);
    float alpha     = smoothstep(0.0, 1.0, intensity) * 0.2;
    return vec4(col * intensity, alpha);
}

// ─── GR: Kerr-Schild radius ───────────────────────────────────────────────────

float getRadius(vec3 p, float a) {
    float B = dot(p, p) - a * a;
    float C = a * a * p.z * p.z;
    return sqrt((B + sqrt(B * B + 4.0 * C)) * 0.5);
}

// ─── GR: Inverse metric (used for Kerr / RN paths only) ──────────────────────

mat4 getInverseMetric(vec4 X) {
    vec3  pos = X.yzw;
    float a   = (uMetricType == 2) ? uSpin   : 0.0;
    float Q   = (uMetricType == 1) ? uCharge : 0.0;
    float M   = uMass;

    float r   = getRadius(pos, a);
    float r2  = r * r;
    float a2  = a * a;
    float rho2 = r2 + a2 * pos.z * pos.z / r2;
    float f   = (2.0 * M * r - Q * Q) / rho2;
    float div = 1.0 / (r2 + a2);

    vec3 l = vec3((r * pos.x + a * pos.y) * div,
                  (r * pos.y - a * pos.x) * div,
                  pos.z / r);
    vec4 k = vec4(1.0, l);

    mat4 eta = mat4(-1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1);
    // Explicit outer product avoids loop; each column = -f * k[col] * k
    mat4 mod = mat4(-f*k[0]*k, -f*k[1]*k, -f*k[2]*k, -f*k[3]*k);
    return eta + mod;
}

// ─── Geodesic derivatives: Schwarzschild (fully analytical) ──────────────────
//
// For Schwarzschild: a=0, Q=0, r = |pos3|
//   f        = 2M/r
//   k^mu     = (1, pos3/r)                     null vector
//   A        = k^mu p_mu = p_0 + (pos3/r)·p_3  contracted momentum
//
// dx^mu/dlambda = g^{mu nu} p_nu = eta*p - f*A*k
//   dx.t   = -p_0  - f*A
//   dx.xyz =  p_3  - f*A*(pos3/r)
//
// dH/dx^i = 0.5*( -df/dx^i * A^2  -  2f*A * dA/dx^i )
//   df/dx^i  = -2M x_i / r^3
//   dA/dx^i  = p_i/r  -  x_i*(pos3·p_3)/r^3

void getDerivsSchwarzschild(vec4 x, vec4 p,
                            out vec4 dx, out vec4 dp, out float r_out) {
    vec3  pos3 = x.yzw;
    float r    = length(pos3);
    r_out      = r;

    float M   = uMass;
    float r3  = r * r * r;
    float f   = 2.0 * M / r;
    vec3  l   = pos3 / r;                          // unit radial direction

    float A   = p.x + dot(l, p.yzw);              // k^mu p_mu

    // Position derivative
    dx.x   = -p.x - f * A;
    dx.yzw =  p.yzw - f * A * l;

    // Momentum derivative (analytical Hamiltonian gradient)
    vec3 df_dx = -2.0 * M * pos3 / r3;
    vec3 dK_dx = p.yzw / r - pos3 * dot(pos3, p.yzw) / r3;
    vec3 gradH = 0.5 * (-df_dx * A * A - 2.0 * f * A * dK_dx);
    dp = vec4(0.0, -gradH);
}

// ─── Geodesic derivatives: Kerr / RN (numerical gradient, kept for generality)

void getDerivsNumerical(vec4 x, vec4 p,
                        out vec4 dx, out vec4 dp, out float r_out) {
    mat4 gInv = getInverseMetric(x);
    dx    = gInv * p;
    r_out = getRadius(x.yzw, (uMetricType == 2) ? uSpin : 0.0);

    float eps  = 0.01;
    vec4  eps1 = vec4(0, eps, 0, 0);
    vec4  eps2 = vec4(0, 0, eps, 0);
    vec4  eps3 = vec4(0, 0, 0, eps);

    float dHdx = 0.5 * dot(p, (getInverseMetric(x+eps1) - getInverseMetric(x-eps1)) * p) / (2.0*eps);
    float dHdy = 0.5 * dot(p, (getInverseMetric(x+eps2) - getInverseMetric(x-eps2)) * p) / (2.0*eps);
    float dHdz = 0.5 * dot(p, (getInverseMetric(x+eps3) - getInverseMetric(x-eps3)) * p) / (2.0*eps);

    dp = vec4(0.0, -dHdx, -dHdy, -dHdz);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

void main() {
    vec2 uv      = (vUv - 0.5) * uResolution / uResolution.y;
    vec3 rdLocal = normalize(vec3(uv, -2.0));
    vec3 rd      = (uCamRot * vec4(rdLocal, 0.0)).xyz;

    vec4 x = vec4(0.0, uCamPos);
    vec4 p = vec4(-1.0, rd);

    vec3  accumCol   = vec3(0.0);
    float accumAlpha = 0.0;
    bool  hitHorizon = false;

    float rh = uMass + sqrt(max(0.0, uMass*uMass - uSpin*uSpin - uCharge*uCharge));

    // Track equatorial (y) component for disk-crossing detection
    float prevY = x.z;   // x.z = py in world coords (y is up)

    for (int i = 0; i < MAX_STEPS; i++) {

        // ── Stage 1 of RK2 ──────────────────────────────────────────────────
        vec4  k1_x, k1_p;
        float r_pre;
        if (uMetricType == 0) {
            getDerivsSchwarzschild(x, p, k1_x, k1_p, r_pre);
        } else {
            getDerivsNumerical(x, p, k1_x, k1_p, r_pre);
        }

        // Adaptive step: large in flat region, small near horizon
        float step = clamp(STEP_SIZE * (r_pre - rh) * 0.4, MIN_STEP, MAX_STEP);

        // ── Stage 2 of RK2 (midpoint) ───────────────────────────────────────
        vec4  k2_x, k2_p;
        float dummy;
        vec4  xMid = x + k1_x * 0.5 * step;
        vec4  pMid = p + k1_p * 0.5 * step;
        if (uMetricType == 0) {
            getDerivsSchwarzschild(xMid, pMid, k2_x, k2_p, dummy);
        } else {
            getDerivsNumerical(xMid, pMid, k2_x, k2_p, dummy);
        }

        x += k2_x * step;
        p += k2_p * step;

        // ── Termination checks ───────────────────────────────────────────────
        float r_post = (uMetricType == 0) ? length(x.yzw)
                                           : getRadius(x.yzw, (uMetricType == 2) ? uSpin : 0.0);

        if (r_post < rh * 1.05) { hitHorizon = true; break; }
        if (r_post > MAX_DIST)   { break; }

        // ── Accretion disk: crossing detection (not volumetric) ──────────────
        float currY = x.z;
        if (prevY * currY < 0.0) {
            vec4 disk = getAccretionDisk(x.yzw);
            if (disk.a > 0.0) {
                accumCol   += disk.rgb * disk.a * (1.0 - accumAlpha);
                accumAlpha += disk.a;
                if (accumAlpha >= 1.0) break;
            }
        }
        prevY = currY;
    }

    vec3 col;
    if (hitHorizon) {
        col = vec3(0.0);
    } else {
        vec3 bg = getBackground(normalize(p.yzw));
        col = mix(bg, accumCol, accumAlpha);
    }

    col = smoothstep(0.0, 1.0, col);
    gl_FragColor = vec4(col, 1.0);
}
