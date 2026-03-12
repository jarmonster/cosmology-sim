import * as THREE from 'three';

let renderer, scene, camera, mesh;
let uniforms;
let isPaused = false;
let isDragging = false;
let previousMousePosition = { x: 0, y: 0 };
let camPos = new THREE.Vector3(0, 0, -15);

async function init() {
    const container = document.getElementById('canvas-container');

    renderer = new THREE.WebGLRenderer({ antialias: false });
    // Cap pixel ratio at 1.0 — Retina DPR=2 quadruples pixel count for no visible gain
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.0));
    renderer.setSize(window.innerWidth, window.innerHeight);
    container.appendChild(renderer.domElement);

    scene  = new THREE.Scene();
    camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);

    const response       = await fetch('blackhole.glsl');
    const fragmentShader = await response.text();
    const vertexShader   = `
        varying vec2 vUv;
        void main() { vUv = uv; gl_Position = vec4(position, 1.0); }
    `;

    uniforms = {
        uTime:       { value: 0 },
        uResolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
        uCamPos:     { value: camPos },
        uCamRot:     { value: new THREE.Matrix4() },
        uMetricType: { value: 0 },   // Default: Schwarzschild
        uMass:       { value: 0.5 },
        uCharge:     { value: 0.0 },
        uSpin:       { value: 0.0 }
    };

    const geometry = new THREE.PlaneGeometry(2, 2);
    const material = new THREE.ShaderMaterial({ vertexShader, fragmentShader, uniforms });
    mesh = new THREE.Mesh(geometry, material);
    scene.add(mesh);

    window.addEventListener('resize', onWindowResize);
    container.addEventListener('mousedown', e => { isDragging = true; previousMousePosition = { x: e.clientX, y: e.clientY }; });
    container.addEventListener('mousemove', onMouseMove);
    container.addEventListener('mouseup',   () => { isDragging = false; });

    // UI controls
    document.getElementById('metric-select').addEventListener('change', e => {
        const type = parseInt(e.target.value);
        uniforms.uMetricType.value = type;
        updateUIForMetric(type);
    });
    document.getElementById('mass-slider').addEventListener('input', e => {
        uniforms.uMass.value = parseFloat(e.target.value);
        document.getElementById('mass-val').textContent = e.target.value;
    });
    document.getElementById('charge-slider').addEventListener('input', e => {
        uniforms.uCharge.value = parseFloat(e.target.value);
        document.getElementById('charge-val').textContent = e.target.value;
    });
    document.getElementById('spin-slider').addEventListener('input', e => {
        uniforms.uSpin.value = parseFloat(e.target.value);
        document.getElementById('spin-val').textContent = e.target.value;
    });
    document.getElementById('pause-btn').addEventListener('click', e => {
        isPaused = !isPaused;
        e.target.textContent = isPaused ? 'Resume Simulation' : 'Pause Simulation';
    });

    updateUIForMetric(0);
    animate();
}

function updateUIForMetric(type) {
    const chargeGroup = document.getElementById('charge-group');
    const spinGroup   = document.getElementById('spin-group');
    const disable     = el => { el.style.opacity = '0.3'; el.style.pointerEvents = 'none'; };
    const enable      = el => { el.style.opacity = '1';   el.style.pointerEvents = 'auto'; };

    disable(chargeGroup); disable(spinGroup);
    uniforms.uCharge.value = 0.0;
    uniforms.uSpin.value   = 0.0;

    if (type === 1) { enable(chargeGroup); }
    if (type === 2) { enable(spinGroup);   }
}

function onMouseMove(e) {
    if (!isDragging) return;
    const dx = e.clientX - previousMousePosition.x;
    const dy = e.clientY - previousMousePosition.y;

    const rotY = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0,1,0), -dx * 0.005);
    camPos.applyQuaternion(rotY);

    const forward = camPos.clone().normalize().negate();
    const right   = new THREE.Vector3().crossVectors(forward, new THREE.Vector3(0,1,0)).normalize();
    const rotX    = new THREE.Quaternion().setFromAxisAngle(right, -dy * 0.005);
    camPos.applyQuaternion(rotX);

    previousMousePosition = { x: e.clientX, y: e.clientY };
}

function onWindowResize() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    uniforms.uResolution.value.set(window.innerWidth, window.innerHeight);
}

const statElev = document.getElementById('stat-elev');
const statAz   = document.getElementById('stat-az');
const statR    = document.getElementById('stat-r');

function animate() {
    requestAnimationFrame(animate);
    if (!isPaused) uniforms.uTime.value += 0.01;

    uniforms.uCamPos.value.copy(camPos);

    // Camera angle readout
    const r    = camPos.length();
    const elev = Math.asin(Math.max(-1, Math.min(1, camPos.y / r))) * 180 / Math.PI;
    const az   = Math.atan2(camPos.z, camPos.x) * 180 / Math.PI;
    statElev.textContent = elev.toFixed(1);
    statAz.textContent   = az.toFixed(1);
    statR.textContent    = r.toFixed(2);

    const forward = new THREE.Vector3().sub(camPos).normalize();
    const up      = new THREE.Vector3(0, 1, 0);
    const right   = new THREE.Vector3().crossVectors(forward, up).normalize();
    const realUp  = new THREE.Vector3().crossVectors(right, forward).normalize();
    uniforms.uCamRot.value.makeBasis(right, realUp, forward.negate());

    renderer.render(scene, camera);
}

init();
