# GUÍA PASO A PASO — Implementación en Simulink del PI+Desacoplador y del GPC

> Tutorial completo para reproducir en Simulink las simulaciones de los controladores PI+Desacoplador y GPC del Capítulo 4 de la tesis.
> El objetivo es que la respuesta en Simulink coincida con la de los scripts de MATLAB.

---

## 0. Setup común a ambos controladores

### 0.1 Crear un archivo de inicialización

Antes de abrir Simulink, crea un script `init_simulink.m` con todos los parámetros físicos y de sintonización. Este script se debe ejecutar **antes** de simular en Simulink, porque los bloques leen las variables del workspace.

```matlab
%% init_simulink.m - cargar parametros antes de correr Simulink

clear; clc;

% --- Parametros fisicos de la planta ---
A1=706.85; A2=706.85; A3=706.85; A4=706.85;
a1=1.89;   a2=1.89;   a3=5.39;   a4=5.39;
k1=1; k2=1; y1=0.7; y2=0.7; g=981;

% --- Punto de operacion ---
h30=25; h40=25;
M_A = [(1-y1)*k1 y2*k2; y1*k1 (1-y2)*k2];
M_B = [a3*sqrt(2*g*h30); a4*sqrt(2*g*h40)];
u0  = M_A\M_B; u10=u0(1); u20=u0(2);
h10 = ((1-y2)*k2*u20/a1)^2/(2*g);
h20 = ((1-y1)*k1*u10/a2)^2/(2*g);
h0  = [h10; h20; h30; h40];

% Constantes de tiempo
T1=A1/a1*sqrt(2*h10/g); T2=A2/a2*sqrt(2*h20/g);
T3=A3/a3*sqrt(2*h30/g); T4=A4/a4*sqrt(2*h40/g);

% --- Modelo lineal continuo (para el GPC) ---
Ac = [-1/T1 0 0 0; 0 -1/T2 0 0;
       0 A2/(A3*T2) -1/T3 0; A1/(A4*T1) 0 0 -1/T4];
Bc = [0 (1-y2)*k2/A1; (1-y1)*k1/A2 0;
      0 y2*k2/A3; y1*k1/A4 0];
Cc = [0 0 1 0; 0 0 0 1]; Dc = zeros(2,2);

% --- Periodo de muestreo y horizontes del GPC ---
Ts = 1;
N  = 50;
Nu = 5;

% --- PI: sintonizacion IMC ---
K1=y1*k1*T4/A4; tau1=T4; lam1=tau1/3; Kp1=tau1/(K1*lam1); Ti1=tau1;
K2=y2*k2*T3/A3; tau2=T3; lam2=tau2/3; Kp2=tau2/(K2*lam2); Ti2=tau2;

% --- Desacoplador estatico ---
G_dc = -Cc*(Ac\Bc);
G_pair = [G_dc(2,1) G_dc(2,2);    % h4 con (u1,u2)
          G_dc(1,1) G_dc(1,2)];   % h3 con (u1,u2)
k12 = G_pair(1,2)/G_pair(1,1);
k21 = G_pair(2,1)/G_pair(2,2);
D = [1 -k12; -k21 1];

% --- GPC: discretizacion y matriz dinamica G ---
sys_d = c2d(ss(Ac,Bc,Cc,Dc), Ts, 'zoh');
[Ad, Bd, Cd, ~] = ssdata(sys_d);

G_z = tf(sys_d); t_step = (0:N)*Ts;
g_step = cell(2,2);
for i=1:2
    for j=1:2
        ys = step(G_z(i,j), t_step);
        g_step{i,j} = ys(2:end);
    end
end

G_din = zeros(2*N, 2*Nu);
for i=1:2
    for j=1:2
        Gb = zeros(N,Nu);
        for r=1:N
            for c=1:Nu
                if r>=c, Gb(r,c) = g_step{i,j}(r-c+1); end
            end
        end
        G_din((i-1)*N+(1:N), (j-1)*Nu+(1:Nu)) = Gb;
    end
end

delta  = [10 10];
lambda = [0.0076803 0.0076803];
Q = blkdiag(delta(1)*eye(N), delta(2)*eye(N));
R = blkdiag(lambda(1)*eye(Nu), lambda(2)*eye(Nu));
H_qp = 2*(G_din'*Q*G_din + R); H_qp = (H_qp+H_qp')/2;

Du_max=[100;100]; Du_min=-Du_max;
u_max=[u10*2; u20*2]; u_min=[0;0];

T_mat = blkdiag(tril(ones(Nu)), tril(ones(Nu)));
A_ineq = [eye(2*Nu); -eye(2*Nu); T_mat; -T_mat];

disp('Parametros cargados al workspace. Ya puedes simular en Simulink.');
```

### 0.2 Configurar el solver

En Simulink: `Simulation → Model Configuration Parameters`:

- **Solver:** Fixed-step
- **Fixed-step size:** `Ts` (el del workspace, será 1 s)
- **Stop time:** 1500
- **Solver:** `ode4 (Runge-Kutta)`

### 0.3 Crear un bloque MATLAB Function para la PLANTA NO LINEAL

Este bloque será **común** a ambos controladores. Lo creas una sola vez:

1. Arrastra al modelo el bloque **MATLAB Function** (de `Simulink/User-Defined Functions`)
2. Doble clic. Pega este código:

```matlab
function h_next = planta_no_lineal(h, u, Ts)
% Integra el modelo no lineal de los 4 tanques durante un periodo Ts.
% Entrada:  h = estado actual [h1;h2;h3;h4],  u = entradas [u1;u2]
% Salida:   h_next = estado al final del periodo

A1=706.85; A2=706.85; A3=706.85; A4=706.85;
a1=1.89;   a2=1.89;   a3=5.39;   a4=5.39;
k1=1; k2=1; y1=0.7; y2=0.7; g=981;

% Integracion de Euler con paso pequeño dentro del periodo
n_steps = 20;
dt = Ts/n_steps;
for i = 1:n_steps
    h1 = max(h(1),0); h2 = max(h(2),0);
    h3 = max(h(3),0); h4 = max(h(4),0);
    u1 = u(1); u2 = u(2);

    dh = [-a1/A1*sqrt(2*g*h1) + (1-y2)*k2*u2/A1;
          -a2/A2*sqrt(2*g*h2) + (1-y1)*k1*u1/A2;
          -a3/A3*sqrt(2*g*h3) + a2/A3*sqrt(2*g*h2) + y2*k2*u2/A3;
          -a4/A4*sqrt(2*g*h4) + a1/A4*sqrt(2*g*h1) + y1*k1*u1/A4];

    h = h + dt*dh;
end
h_next = h;
```

3. En las propiedades de los puertos: declarar que `h` es un **vector 4×1** y `u` es **2×1**.

> Para implementar este bloque como una iteración por muestreo se usa una realimentación con un bloque **`Unit Delay`** que mantiene el estado entre ciclos. Es el patrón estándar para modelar plantas discretas en Simulink.

---

## PARTE A — Implementación del PI + Desacoplador

### A.1 Bloques necesarios

| Bloque | Cantidad | Ubicación en biblioteca |
|---|---|---|
| `Step` | 2 | Simulink/Sources |
| `Sum` | 4 | Simulink/Math Operations |
| `Discrete PID Controller` | 2 | Simulink/Discrete |
| `Gain` | 2 | Simulink/Math Operations |
| `Saturation` | 2 | Simulink/Discontinuities |
| `MATLAB Function (planta)` | 1 | (la creada en 0.3) |
| `Unit Delay` | 1 | Simulink/Discrete |
| `Selector` | 2 | Simulink/Signal Routing |
| `Scope` | 1-2 | Simulink/Sinks |
| `To Workspace` | varios | Simulink/Sinks |

### A.2 Parámetros de cada bloque

**Step (ref_h3):**
- Step time: `400`
- Initial value: `25`
- Final value: `30`

**Step (ref_h4):**
- Step time: `800`
- Initial value: `25`
- Final value: `20`

**Discrete PID Controller (PI_1, controla h4):**
- Controller form: `Parallel`
- Time domain: `Discrete-time`
- Sample time: `Ts`
- Proportional (P): `Kp1`
- Integral (I): `Kp1/Ti1`
- Derivative (D): `0`
- **Marcar "Use anti-windup" → "back-calculation"** (Kb = 1)
- Limit output: marcar `u_min(1)` y `u_max(1)`

**Discrete PID Controller (PI_2, controla h3):**
- Igual al anterior pero con `Kp2`, `Kp2/Ti2`, `u_min(2)`, `u_max(2)`

**Gain k12:** Valor: `-k12`
**Gain k21:** Valor: `-k21`

**Saturation 1 (u1):** Upper: `u_max(1)`, Lower: `u_min(1)`
**Saturation 2 (u2):** Upper: `u_max(2)`, Lower: `u_min(2)`

**Selector 1 (extrae h3 del vector h):** Index: `3`
**Selector 2 (extrae h4 del vector h):** Index: `4`

**Unit Delay:** Initial condition: `h0` (vector 4×1)

### A.3 Conexiones (diagrama lógico)

```
ref_h4 ──► (+)──► PI_1 ──► v1 ──┬─────────────────► (+) ──► u1_sat ──┐
            ▲                    │                    ▲                │
            │                    │                 (-k12)              │
            │                    │                    │                │
            │                    │                    │                │
            │                    │                    v2 (cruzado)     │
            │                    │                                     │
            │                    │                    v1 (cruzado)     │
            │                    │                                     │
            │                    │                    │                ▼
            │                    │                 (-k21)         ┌────────┐
            │                    │                    │           │ PLANTA │
            │                    │                    ▼           │ (no    │
            │                    │                                │ lineal │── h3, h4
            │                    │                                └────────┘
            │                    └──────────────► (+) ──► u2_sat ──┘ │
            │                                                       │
            │                                                       │
ref_h3 ──► (+)──► PI_2 ──► v2 ─────────────────────► ...             │
            ▲                                                       │
            │                                                       │
            └────────────────[h4]◄──────────────────────────────────┤
                            [h3]◄──────────────────────────────────┘
                              (realimentaciones)
```

### A.4 Procedimiento de armado

1. **Arrastra los bloques** según la lista de A.1
2. **Conecta las referencias** a los sumadores de error (entradas (+))
3. **Conecta las salidas de la planta** (h3, h4) a los Selector y luego a los sumadores con signo (−)
4. **Cablea PI_1 → v1** y **PI_2 → v2**
5. **Construye el desacoplador:**
   - De `v2` sale un cable que pasa por `Gain k12 (-k12)` y entra a un Sum junto con `v1` → produce `u1_pre`
   - De `v1` sale otro cable que pasa por `Gain k21 (-k21)` y entra a un Sum junto con `v2` → produce `u2_pre`
6. **Conecta `u1_pre, u2_pre`** a sus respectivos bloques `Saturation`
7. **Conecta las dos salidas saturadas** a un bloque `Mux` (de 2 entradas) que produce el vector `u = [u1; u2]`
8. **Conecta `u` y `h` (vía Unit Delay)** al bloque `planta_no_lineal`
9. **Cablea Scope** a `h3, h4, u1, u2` para visualizar

### A.5 Verificación contra MATLAB

Ejecuta `init_simulink.m`, luego corre la simulación en Simulink. Compara las trayectorias de `h3` y `h4` con las que produce `controlador_PID.m`. Deben ser **prácticamente idénticas** (pequeñas diferencias por el solver).

---

## PARTE B — Implementación del GPC

### B.1 Estrategia

El GPC requiere resolver un QP en cada periodo de muestreo. Esto **no se puede representar con bloques visuales** simples; se debe usar **un solo bloque MATLAB Function** que contiene todo el algoritmo.

### B.2 Bloques necesarios

| Bloque | Cantidad |
|---|---|
| `Step` (referencias) | 2 |
| `Mux` (combina referencias) | 1 |
| `MATLAB Function (algoritmo GPC)` | 1 |
| `Saturation` | 2 |
| `MATLAB Function (planta no lineal)` | 1 |
| `Unit Delay` | 2 (uno para h, uno para u_prev) |
| `Scope`, `To Workspace` | varios |

### B.3 Código del bloque MATLAB Function del GPC

Crea un bloque MATLAB Function llamado `gpc_step` y pega este código:

```matlab
function u_new = gpc_step(y_med, u_prev, r_act)
% Algoritmo GPC: resuelve el QP en un periodo de muestreo.
% Entradas:
%   y_med  = vector 4x1 con el estado medido [h1;h2;h3;h4]
%   u_prev = vector 2x1 con la entrada anterior [u1(k-1);u2(k-1)]
%   r_act  = vector 2x1 con el setpoint actual [ref_h3; ref_h4]
% Salida:
%   u_new  = vector 2x1 con la nueva entrada [u1(k); u2(k)]

% Variables del workspace (declarar como parametros del bloque)
% --> Ver "B.4 Parametros del bloque" para configurar esto

% Estas variables son leidas como "Parameters" del bloque MATLAB Function:
% Ad, Bd, Cd, G_din, Q, H_qp, A_ineq, N, Nu, h0, u0, h30, h40,
% Du_max, Du_min, u_max, u_min

% Estado en variables desviadas
x_des = y_med - h0;
u_prev_des = u_prev - u0;

% Respuesta libre F (propagacion con Du=0)
F_vec = zeros(2*N, 1);
x_temp = x_des;
for j = 1:N
    x_temp = Ad*x_temp + Bd*u_prev_des;
    y_pred = Cd*x_temp;
    F_vec(j)     = y_pred(1);
    F_vec(N + j) = y_pred(2);
end

% Referencia futura constante
r_des = r_act - [h30; h40];
W = [repmat(r_des(1),N,1); repmat(r_des(2),N,1)];

% Vector lineal del QP
f_qp = 2*G_din'*Q*(F_vec - W);

% Vector de restricciones
Du_max_v = [repmat(Du_max(1),Nu,1); repmat(Du_max(2),Nu,1)];
Du_min_v = [repmat(Du_min(1),Nu,1); repmat(Du_min(2),Nu,1)];
u_max_v  = [repmat(u_max(1),Nu,1);  repmat(u_max(2),Nu,1)];
u_min_v  = [repmat(u_min(1),Nu,1);  repmat(u_min(2),Nu,1)];
u_prev_stack = [repmat(u_prev(1),Nu,1); repmat(u_prev(2),Nu,1)];

b_ineq = [Du_max_v; -Du_min_v;
          u_max_v - u_prev_stack;
         -u_min_v + u_prev_stack];

% Resolucion del QP
DU = quadprog(H_qp, f_qp, A_ineq, b_ineq);

% Aplicacion del primer incremento de cada canal
Du_aplicado = [DU(1); DU(Nu+1)];
u_new = u_prev + Du_aplicado;
u_new = max(min(u_new, u_max), u_min);
end
```

### B.4 Parámetros del bloque MATLAB Function (GPC)

En el editor del bloque, ir a `Model Explorer → MATLAB Function → Ports and Data Manager` y declarar las siguientes variables como **`Parameter`** (no `Input`) con tamaño igual al del workspace:

| Variable | Tamaño | Scope |
|---|---|---|
| `Ad` | 4×4 | Parameter |
| `Bd` | 4×2 | Parameter |
| `Cd` | 2×4 | Parameter |
| `G_din` | 100×10 | Parameter |
| `Q` | 100×100 | Parameter |
| `H_qp` | 10×10 | Parameter |
| `A_ineq` | 40×10 | Parameter |
| `N` | 1 | Parameter |
| `Nu` | 1 | Parameter |
| `h0`, `u0` | 4×1, 2×1 | Parameter |
| `h30`, `h40` | 1 | Parameter |
| `Du_max`, `Du_min`, `u_max`, `u_min` | 2×1 | Parameter |

> Si Simulink no acepta `quadprog` dentro del MATLAB Function (por restricción de Code Generation), puedes habilitarlo: `Configuration Parameters → Code Generation → Interface → "Support: variable-size signals"`. Si aun así falla, usa un bloque **Level-2 MATLAB S-Function** en su lugar (es prácticamente el mismo código pero envuelto en una estructura S-Function).

### B.5 Conexiones

```
ref_h3 ──┐
         ├──[Mux]──► r_act (2x1) ─┐
ref_h4 ──┘                        │
                                   ▼
   ┌─────────────────────► gpc_step ───► u_new ───► Sat ───► u (2x1) ───┐
   │                          ▲                                          │
   │                          │                                          │
   │       u_prev ◄──[Unit Delay]                                        │
   │           ▲                                                         │
   │           └─────────────────────────────────────────────────────────┘
   │
   │   y_med ◄──[Unit Delay]◄── PLANTA NO LINEAL ◄────────────────────────┘
```

### B.6 Verificación contra MATLAB

Ejecuta `init_simulink.m`, corre la simulación. Compara con `controlador_GPC.m`. Las diferencias pueden ser mayores que en el caso del PI por el solver del QP, pero las trayectorias generales deben ser muy parecidas.

---

## PARTE C — Modelo comparativo (PI+Desacoplador y GPC en paralelo)

Para reproducir el comparativo del `comparacion_GPC_vs_PID.m`:

1. **Duplica** la planta no lineal: una alimentada por el PI+Desacoplador, otra por el GPC
2. Las **referencias son las mismas** para ambos (compartidas)
3. Cablea **Scopes separados** para cada controlador
4. Adicionalmente, un Scope que muestre **ambas respuestas superpuestas** (h3_GPC vs h3_PI, h4_GPC vs h4_PI)

---

## PARTE D — Inyección del ruido

Para reproducir el escenario completo del Cap. 4:

1. Agrega un bloque **`Band-Limited White Noise`** con varianza `0.3^2`
2. Multiplícalo por un bloque **`Step`** que activa desde `t=1100`
3. Suma este ruido a las mediciones `h3` y `h4` antes de entrar a los controladores

---

## RESUMEN — checklist antes de correr la primera simulación

- [ ] Ejecutado `init_simulink.m` en MATLAB → variables en el workspace
- [ ] Solver = `ode4`, Fixed-step = `Ts`, Stop = `1500`
- [ ] Bloque "planta_no_lineal" creado y verificado
- [ ] Para PI: Discrete PID Controllers configurados con `Kp_i, Kp_i/Ti_i`, anti-windup activo
- [ ] Ganancias del desacoplador `-k12, -k21` correctas
- [ ] Bloques de saturación con `u_min, u_max`
- [ ] Mux/Demux para convertir entre vectores y señales escalares
- [ ] Unit Delays con condiciones iniciales correctas (h0 para la planta)
- [ ] (GPC) Bloque MATLAB Function con `quadprog` habilitado
- [ ] (GPC) Parámetros del bloque declarados como Parameters, no Inputs

---

## Errores comunes

| Síntoma | Causa típica | Solución |
|---|---|---|
| La salida no llega al setpoint | Saturación mal configurada o anti-windup desactivado | Revisar límites y activar back-calculation |
| Oscilaciones constantes | `Kp` muy alto o falta el desacoplador | Bajar `Kp` o agregar ganancias `k12, k21` |
| `quadprog` no compila | Code Generation restringido | Usar Level-2 MATLAB S-Function en su lugar |
| Las trayectorias divergen de MATLAB | Solver diferente | Cambiar a `ode4` Fixed-step con `dt = Ts` |
| Error de dimensiones en el Mux | Vectores mal conectados | Verificar que `u` y `h` son 2×1 y 4×1 |

---

## Próximos pasos

1. Reproduce primero la simulación del PI+Desacoplador (más simple).
2. Verifica que coincida con los resultados de MATLAB.
3. Luego implementa el GPC.
4. Finalmente arma el modelo comparativo con ambos.

Cuando termines y tengas Simulink corriendo, podemos hacer ajustes finos comparando los resultados.
