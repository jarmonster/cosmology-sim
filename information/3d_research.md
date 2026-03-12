# 3D Extension Reference — n(q, η) and f(q, p, η)

Source: Bachelor Thesis, Nicola Valenzano, Heidelberg 2026.
Key equations: Eq. (7.8) for f₀, Eq. (7.11) for full f, Eq. (2.1) for n = ∫f dp.

---

## 1. What n(q, η) is

n(q, η) is the zeroth momentum moment of the phase-space distribution f:

    n(q, η) := ∫ d³p  f(q, p, η)       [Thesis Eq. (2.1)]

---

## 2. Full phase-space distribution f(q, p, η) — Eq. (7.11)

The approximate f is built from three terms around the Zel'dovich background:

    f ≈ f₀(q, p)
        + ∂_q f₀ · δq(q, η)
        + ∂_p f₀ · δp(q, η)

### 2a. Initial Gaussian background f₀  [Thesis Eq. (7.8)]

    f₀(q, p) = ρ̄(1 + δ^(i)(q)) / (2π σ̄²)^(3/2)
               · exp(-p² / 2σ̄²)
               · (1 + p · ∇_q ψ^(i)(q) / σ̄²)

This is the Gaussian closure truncated at first order in perturbations.

### 2b. Spatial derivative of f₀  [Thesis Eq. (7.9)]

    ∂_{q_i} f₀ = ρ̄ / (2π σ̄²)^(3/2)  · exp(-p²/2σ̄²)
                 · [ ∂_{q_i} δ^(i)  +  p_j ∂_{q_i} ∂_{q_j} ψ^(i) / σ̄² ]

                = ρ̄ / (2π σ̄²)^(3/2)  · exp(-p²/2σ̄²)
                 · [ (∇δ^(i))_i  +  (p · H_ini)_i / σ̄² ]

### 2c. Momentum derivative of f₀  [Thesis Eq. (7.10)]

    ∂_{p_i} f₀ = ρ̄ / (2π σ̄²)^(3/2)  · exp(-p²/2σ̄²)
                 · [ (∇_q ψ^(i))_i / σ̄²
                     - p_i / σ̄² · (1 + δ^(i)  +  p · ∇_q ψ^(i) / σ̄²) ]

### 2d. Perturbed displacements δq, δp  [Thesis Eq. (7.9)-(7.10) final result; Eq. (7.11)]

The Born approximation along Zel'dovich trajectories gives:

    δq = [C₁(η) · H_ini  +  D₁(η) · I] · F_ini
    δp = [C₂(η) · H_ini  +  D₂(η) · I] · F_ini

where the time coefficients from Eq. (7.11) are:

    C₁(η) = (4/m) [ 1/9 e^{3η}  -  16/9 e^{3η/2}  -  (9/30) e^{2η}
                    + 1/6  +  2/15 e^{-η/2}  +  11/3 e^η  -  2 e^{η/2} ]

    D₁(η) = (4/m) [ 2/3 e^η  -  2  +  4/3 e^{-η/2} ]

    C₂(η) = (2/m) [ 12/15 e^{2η}  -  4/3 e^η  -  2/15 e^{-η/2}  +  2/3 e^{η/2} ]

    D₂(η) = (2/m) [ 2/3 e^η  -  2/3 e^{-η/2} ]

All four coefficients vanish at η = 0.

---

## 3. n(q, η) — the projected density (2D and 3D identical structure)

When f is integrated over all momenta p, Term 3 (∂_p f₀ · δp) vanishes exactly
because the integrand is odd in p (it has a factor of p multiplied by exp(-p²/2σ̄²)).
Likewise the p · ∇ψ^(i)/σ̄² part of Term 1 vanishes.

What survives is:

    n(q, η) = ρ̄(1 + δ^(i)(q))
              + ρ̄ · ∇δ^(i)(q) · [ C₁(η) · H_ini(q) · F_ini(q)  +  D₁(η) · F_ini(q) ]

Written componentwise (3D):

    n(q, η) = ρ̄(1 + δ^(i))
              + ρ̄ · Σ_i (∂_{q_i} δ^(i)) · [ C₁(η) · (H_ini · F_ini)_i  +  D₁(η) · (F_ini)_i ]

This formula is dimension-agnostic in structure — the same form holds in 2D and 3D.
The dimension enters only through the initial fields δ^(i), ψ^(i), H_ini, F_ini.

---

## 4. Initial fields — 2D (current simulation)

    δ^(i)(q) = δ₀ cos(k q_x) cos(k q_y)

    ψ^(i)(q) = δ₀/(2k²) · cos(k q_x) cos(k q_y)
               [because ∇²_{2D} ψ = -2k² ψ · (1/ψ) · ψ = -δ^(i); i.e. -∂²_x - ∂²_y of ψ = δ^(i)]

    ∇δ^(i) = [ -δ₀ k sin(kq_x) cos(kq_y),
               -δ₀ k cos(kq_x) sin(kq_y) ]

    H_ini (2×2 Hessian of ψ^(i)):
      H11 = H22 = -(δ₀/2) cos(kq_x) cos(kq_y)
      H12 = H21 =  (δ₀/2) sin(kq_x) sin(kq_y)

    F_ini(q) = A_F · ∇δ^(i)(q)      [2-vector]

---

## 5. Initial fields — 3D extension (VERIFIED)

    δ^(i)(q) = δ₀ cos(k q_x) cos(k q_y) cos(k q_z)

    ψ^(i)(q) = δ₀/(3k²) · cos(k q_x) cos(k q_y) cos(k q_z)
               [because ∇²_{3D} ψ = -3k² ψ · (1/ψ) · ψ = -δ^(i);
                i.e. -∂²_x - ∂²_y - ∂²_z of ψ = δ^(i)  -->  denominator is 3k², NOT 2k²]

    ∇δ^(i) = [ -δ₀ k sin(kq_x) cos(kq_y) cos(kq_z),
               -δ₀ k cos(kq_x) sin(kq_y) cos(kq_z),
               -δ₀ k cos(kq_x) cos(kq_y) sin(kq_z) ]

    H_ini (3×3 Hessian of ψ^(i)), computed as ∂²ψ/∂q_i ∂q_j:

      H11 = H22 = H33 = -(δ₀/3) cos(kq_x) cos(kq_y) cos(kq_z)

      H12 = H21 =  (δ₀/3) sin(kq_x) sin(kq_y) cos(kq_z)
      H13 = H31 =  (δ₀/3) sin(kq_x) cos(kq_y) sin(kq_z)
      H23 = H32 =  (δ₀/3) cos(kq_x) sin(kq_y) sin(kq_z)

    Derivation check for H11:
      ψ^(i) = δ₀/(3k²) cos(kq_x) cos(kq_y) cos(kq_z)
      ∂²ψ/∂q_x² = δ₀/(3k²) · (-k²) cos(kq_x) cos(kq_y) cos(kq_z)
                 = -(δ₀/3) cos(kq_x) cos(kq_y) cos(kq_z)   CONFIRMED

    Derivation check for H12:
      ∂²ψ/∂q_x ∂q_y = δ₀/(3k²) · (-k sin(kq_x)) · (-k sin(kq_y)) · cos(kq_z)
                     = δ₀/(3k²) · k² sin(kq_x) sin(kq_y) cos(kq_z)
                     = (δ₀/3) sin(kq_x) sin(kq_y) cos(kq_z)   CONFIRMED

    F_ini(q) = A_F · ∇δ^(i)(q)      [3-vector]

---

## 6. Variable definitions

| Symbol       | Meaning                                           | Typical value |
|--------------|---------------------------------------------------|---------------|
| q            | Lagrangian (comoving) position vector             | continuous    |
| p            | Canonical momentum in Zel'dovich coordinates      | integrated out|
| η            | Log growth-factor time: η = log(D(τ)/D^(i))      | 0 → 3         |
| ρ̄            | Mean comoving mass density                        | 1.0           |
| σ̄            | Isotropic velocity dispersion (Gaussian closure)  | 0.3           |
| m            | Particle mass (sets units)                        | 1.0           |
| δ₀           | Amplitude of initial density perturbation         | 0.10 (small)  |
| A_F          | Amplitude scale for higher-order force F_ini      | 1.0           |
| k            | Wavenumber of initial perturbation                | 1.0           |
| δ^(i)(q)     | Initial density contrast field                    | see Sec. 4/5  |
| ψ^(i)(q)     | Initial velocity potential: δ^(i) = -∇²ψ^(i)    | see Sec. 4/5  |
| H_ini        | Hessian of ψ^(i) evaluated at initial time        | see Sec. 4/5  |
| F_ini        | A_F · ∇δ^(i), higher-order force field           | see Sec. 4/5  |
| C₁(η), D₁(η) | Time-evolution coefficients for δq              | see Sec. 2d   |
| C₂(η), D₂(η) | Time-evolution coefficients for δp (not needed for n) | see Sec. 2d |

---

## 7. 2D vs 3D model — clarification

The thesis is written in 3D throughout (all vectors and tensors are 3D; phase space is 6D).

The current 2D simulation is NOT a projection or slice of a 3D model. It is the same
mathematical structure applied to a 2D position space: q = (q_x, q_y), with a 2D
Laplacian used to define ψ^(i). This gives the denominator 2k² in ψ^(i) and a 2×2 Hessian.

The 3D extension uses q = (q_x, q_y, q_z), a 3D Laplacian → denominator 3k², and a 3×3
Hessian. The formula for n(q, η) has identical structure; only the spatial fields change.

---

## 8. What to compute numerically for 3D n(q, η)

For each grid point q = (q_x, q_y, q_z) and each time η:

1. Compute δ^(i)(q)             — scalar
2. Compute ∇δ^(i)(q)           — 3-vector
3. Compute H_ini(q)             — 3×3 symmetric matrix
4. Compute F_ini(q) = A_F · ∇δ^(i)(q)   — 3-vector
5. Compute H_ini · F_ini        — 3-vector (matrix-vector product)
6. Evaluate C₁(η), D₁(η)       — two scalars
7. Compute δq = C₁(η)·(H_ini·F_ini) + D₁(η)·F_ini   — 3-vector
8. Compute n(q,η) = ρ̄(1 + δ^(i)) + ρ̄ · ∇δ^(i) · δq   — scalar (dot product)

Steps 1-5 are time-independent and can be precomputed on the full grid.
Step 6 is computed once per frame.
Steps 7-8 are applied element-wise over the grid.

---

## 9. Corrections to user-extracted formulas

All user-extracted formulas are correct. Specific confirmations:

- ψ^(i) denominator 3k² in 3D: CORRECT (from ∇²_{3D}ψ = -3k²·(δ₀/3k²)·coscos·cos = -δ^(i))
- All 6 H_ini entries for 3D: CORRECT (verified by direct differentiation above)
- C₁(η) and D₁(η): CORRECT (match Eq. (7.11) read from page 42 of thesis)
- F_ini = A_F · ∇δ^(i): CORRECT (A_F is a free scalar amplitude)
- n = ∫f dp: CORRECT (Thesis Eq. 2.1, confirmed by parity argument for Term 3)

The only note: the formula in the simulation HTML shows
  n(q,η) = ρ̄(1+δ^(i)) + C₁(η)·ρ̄·∇δ^(i)·(H_ini·F_ini) + D₁(η)·ρ̄·∇δ^(i)·F_ini
which is exactly equivalent to the form in Section 3 above. No correction needed.
