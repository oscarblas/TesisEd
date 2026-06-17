# GUÍA PASO A PASO — Implementación en Simulink

> Material visual y explicado bloque por bloque para implementar el PI+Desacoplador y el GPC en Simulink, replicando los scripts MATLAB del repositorio.

---

## ANTES DE EMPEZAR

### Paso 0.1 — Crear el script de inicialización

En MATLAB, crea un archivo llamado **`init_simulink.m`** y pega este código. **Ejecútalo cada vez que vayas a simular en Simulink** (los bloques leen las variables del workspace):

```matlab
%% init_simulink.m
clear; clc;

% Parametros fisicos
A1=706.85; A2=706.85; A3=706.85; A4=706.85;
a1=1.89;   a2=1.89;   a3=5.39;   a4=5.39;
k1=1; k2=1; y1=0.7; y2=0.7; g=981;

% Punto de operacion
h30=25; h40=25;
M_A = [(1-y1)*k1 y2*k2; y1*k1 (1-y2)*k2];
M_B = [a3*sqrt(2*g*h30); a4*sqrt(2*g*h40)];
u0 = M_A\M_B; u10=u0(1); u20=u0(2);
h10 = ((1-y2)*k2*u20/a1)^2/(2*g);
h20 = ((1-y1)*k1*u10/a2)^2/(2*g);
h0 = [h10; h20; h30; h40];

T1=A1/a1*sqrt(2*h10/g); T2=A2/a2*sqrt(2*h20/g);
T3=A3/a3*sqrt(2*h30/g); T4=A4/a4*sqrt(2*h40/g);

Ac=[-1/T1 0 0 0; 0 -1/T2 0 0;
     0 A2/(A3*T2) -1/T3 0; A1/(A4*T1) 0 0 -1/T4];
Bc=[0 (1-y2)*k2/A1; (1-y1)*k1/A2 0;
     0 y2*k2/A3; y1*k1/A4 0];
Cc=[0 0 1 0; 0 0 0 1]; Dc=zeros(2,2);

Ts=1; N=50; Nu=5;

% PI: sintonizacion IMC
K1=y1*k1*T4/A4; tau1=T4; lam1=tau1/3;
Kp1=tau1/(K1*lam1); Ti1=tau1;
K2=y2*k2*T3/A3; tau2=T3; lam2=tau2/3;
Kp2=tau2/(K2*lam2); Ti2=tau2;

% Desacoplador
G_dc=-Cc*(Ac\Bc);
G_pair=[G_dc(2,1) G_dc(2,2); G_dc(1,1) G_dc(1,2)];
k12=G_pair(1,2)/G_pair(1,1);
k21=G_pair(2,1)/G_pair(2,2);

% Limites
u_max=[u10*2; u20*2]; u_min=[0;0];

% GPC: discretizacion y matriz dinamica
sys_d=c2d(ss(Ac,Bc,Cc,Dc),Ts,'zoh');
[Ad,Bd,Cd,~]=ssdata(sys_d);
G_z=tf(sys_d); t_step=(0:N)*Ts;
g_step=cell(2,2);
for i=1:2, for j=1:2
    ys=step(G_z(i,j),t_step);
    g_step{i,j}=ys(2:end);
end, end

G_din=zeros(2*N,2*Nu);
for i=1:2, for j=1:2
    Gb=zeros(N,Nu);
    for r=1:N, for c=1:Nu
        if r>=c, Gb(r,c)=g_step{i,j}(r-c+1); end
    end, end
    G_din((i-1)*N+(1:N),(j-1)*Nu+(1:Nu))=Gb;
end, end

delta=[10 10]; lambda=[0.0076803 0.0076803];
Q=blkdiag(delta(1)*eye(N),delta(2)*eye(N));
R=blkdiag(lambda(1)*eye(Nu),lambda(2)*eye(Nu));
H_qp=2*(G_din'*Q*G_din+R); H_qp=(H_qp+H_qp')/2;

Du_max=[100;100]; Du_min=-Du_max;
T_mat=blkdiag(tril(ones(Nu)),tril(ones(Nu)));
A_ineq=[eye(2*Nu); -eye(2*Nu); T_mat; -T_mat];

disp('Variables cargadas. Abre Simulink y simula.');
```

### Paso 0.2 — Configurar el solver de Simulink

Abre tu modelo en Simulink y ve a **`Simulation → Model Configuration Parameters`**:

- **Solver type:** `Fixed-step`
- **Fixed-step size:** `Ts` (escribe la palabra `Ts`, leerá el valor del workspace)
- **Solver:** `ode4 (Runge-Kutta)`
- **Stop time:** `1500`

---

# PARTE A — Implementación del PI + Desacoplador

> **Mira la imagen `simulink_PID_detallado.png` mientras lees esto.** Los números rojos en la imagen coinciden con los pasos abajo.
>
> **Esta versión consolida el desacoplador en UN solo bloque MATLAB Function** (en lugar de los 4 bloques Gain+Sum). Es más limpio visualmente y más coherente con el diseño del GPC.

### Paso 1 — Step `ref_h4`
- Biblioteca: `Simulink → Sources → Step`
- Parámetros:
  - Step time: `800`
  - Initial value: `25`
  - Final value: `20`

### Paso 2 — Sum (calcula error e₁)
- Biblioteca: `Simulink → Math Operations → Sum`
- Parámetros:
  - List of signs: `+-` (suma con +, resta con −)
- Conexión:
  - Entrada (+): viene del **Step 1** (`ref_h4`)
  - Entrada (−): viene del **Selector 17** (`h4` realimentado)
  - Salida: `e1` → va al **bloque 3 (PID)**

### Paso 3 — Discrete PID Controller (PI_1)
- Biblioteca: `Simulink → Discrete → Discrete PID Controller`
- Parámetros (doble clic):
  - Controller: `PI`
  - Time domain: `Discrete-time`
  - Sample time: `Ts`
  - **Proportional (P)**: `Kp1`
  - **Integral (I)**: `Kp1/Ti1`
  - **Limit output**: marcar la casilla
  - **Upper limit**: `u_max(1)`
  - **Lower limit**: `u_min(1)`
  - **Anti-windup method**: `back-calculation`
- Entrada: `e1` (del **Sum 2**)
- Salida: `v1` → va al desacoplador

### Pasos 4, 5, 6 — Repetir para el lazo 2
Análogo a 1, 2, 3 pero con:
- **Step 4 (`ref_h3`)**: Step time `400`, Initial value `25`, Final value `30`
- **Sum 5**: igual estructura `+-`
- **PID 6**: con `Kp2`, `Kp2/Ti2`, `u_max(2)`, `u_min(2)`
- Salida: `v2`

---

### Paso 7 — Mux (combina v1 y v2 en un vector)
- Biblioteca: `Simulink → Signal Routing → Mux`
- Parámetro: Number of inputs: `2`
- Entradas: `v1` (del PID 3), `v2` (del PID 6)
- Salida: vector `v` (2×1) que entra al desacoplador

### Paso 8 — 🟧 MATLAB Function `desacoplador` 🟧
- Biblioteca: `Simulink → User-Defined Functions → MATLAB Function`
- Doble clic. Pega este código:

```matlab
function u_pre = desacoplador(v, k12, k21)
% Desacoplador estatico de Skogestad (simplificado).
% Entradas:
%   v   = vector 2x1 con las salidas de los dos PI [v1; v2]
%   k12 = ganancia cruzada (calculada en init_simulink.m)
%   k21 = ganancia cruzada (calculada en init_simulink.m)
% Salida:
%   u_pre = vector 2x1 con [u1_pre; u2_pre] antes de la saturacion

u1_pre = v(1) - k12 * v(2);
u2_pre = -k21 * v(1) + v(2);
u_pre  = [u1_pre; u2_pre];
end
```

**Configuración importante:**
1. En el editor del MATLAB Function, ve a `Model Explorer` (o `Symbols Pane`)
2. Selecciona `k12` y `k21` y cambia su **Scope** a **`Parameter`** (no Input). Así toma sus valores del workspace.
3. Entrada del bloque: `v` (vector 2×1, viene del Mux 7)
4. Salida del bloque: `u_pre` (vector 2×1)

### Paso 9 — Demux (separa u1_pre y u2_pre)
- Biblioteca: `Simulink → Signal Routing → Demux`
- Parámetro: Number of outputs: `2`
- Entrada: `u_pre` (vector 2×1)
- Salidas: `u1_pre` (escalar), `u2_pre` (escalar)

### Paso 10 — Saturation (límites de u1)
- Biblioteca: `Simulink → Discontinuities → Saturation`
- Parámetros:
  - Upper limit: `u_max(1)`
  - Lower limit: `u_min(1)`
- Entrada: `u1_pre`
- Salida: `u1`

### Paso 11 — Saturation (límites de u2)
- Análogo al 10 pero con `u_max(2)` y `u_min(2)`
- Salida: `u2`

### Paso 12 — Mux (combina u1, u2 en vector u)
- Number of inputs: `2`
- Entradas: `u1`, `u2`
- Salida: vector `u` (2×1) que va a la planta

### Paso 13 — MATLAB Function (planta no lineal)
- Biblioteca: `Simulink → User-Defined Functions → MATLAB Function`
- Doble clic. Pega este código:

```matlab
function h_next = planta_no_lineal(u, h_prev, Ts)
A1=706.85; A2=706.85; A3=706.85; A4=706.85;
a1=1.89;   a2=1.89;   a3=5.39;   a4=5.39;
k1=1; k2=1; y1=0.7; y2=0.7; g=981;

n=20; dt=Ts/n; h=h_prev;
for i=1:n
    h1=max(h(1),0); h2=max(h(2),0);
    h3=max(h(3),0); h4=max(h(4),0);
    dh=[-a1/A1*sqrt(2*g*h1) + (1-y2)*k2*u(2)/A1;
        -a2/A2*sqrt(2*g*h2) + (1-y1)*k1*u(1)/A2;
        -a3/A3*sqrt(2*g*h3) + a2/A3*sqrt(2*g*h2) + y2*k2*u(2)/A3;
        -a4/A4*sqrt(2*g*h4) + a1/A4*sqrt(2*g*h1) + y1*k1*u(1)/A4];
    h=h+dt*dh;
end
h_next=h;
```

- Entradas: `u` (vector 2×1 del Mux), `h_prev` (vector 4×1 del Unit Delay), `Ts` (escalar)
- Salida: `h_next` (vector 4×1)

### Paso 14 — Unit Delay (memoria del estado) ⚠ IMPORTANTE
- Biblioteca: `Simulink → Discrete → Unit Delay`
- Parámetros:
  - **Initial condition: `zeros(4,1)`** ← arranca con tanques vacíos (Opción A)
  - Sample time: `Ts`
- Entrada: `h_next` (de la planta)
- Salida: `h_prev` (vuelve a la planta como entrada y se ramifica a los Selectores)

> **¿Por qué `zeros(4,1)` y no `h0`?** Es para evitar la pequeña bajada inicial. Si pones `h0`, la planta arranca llena al estacionario pero los PI están con integradores en 0, así que las bombas están apagadas y los tanques pierden agua hasta que los PI reaccionen. Con `zeros(4,1)` arranca todo en cero (igual que `controlador_PID.m`) y el sistema se llena suavemente hasta el estacionario antes de t=400 s.

### Pasos 15 y 16 — Selectores para extraer h₃ y h₄
- Biblioteca: `Simulink → Signal Routing → Selector`
- Parámetros del Selector h₃ (paso 15):
  - Number of input dimensions: `1`
  - Index Option: `Index vector (dialog)`
  - Index: `3`
- Parámetros del Selector h₄ (paso 16):
  - Index: `4`
- Entradas: vector `h` del Unit Delay
- Salidas: `h3` → al Sum 5 (entrada −) | `h4` → al Sum 2 (entrada −)

### Paso 17 — Scope
- Biblioteca: `Simulink → Sinks → Scope`
- Conecta: salidas de los Selectores 15 y 16

---

# PARTE B — Implementación del GPC

> **Mira la imagen `simulink_GPC_detallado.png` mientras lees esto.** Los puertos azules son ENTRADAS y los puertos rojos son SALIDAS de cada bloque.

El GPC es **más simple visualmente** que el PID porque toda la complejidad vive dentro de UN solo bloque MATLAB Function (`gpc_step`).

---

## Resumen visual de qué entra y qué sale de cada bloque

### Bloque 4 — `gpc_step` (MATLAB Function)
```
                          ┌─────────────────────────┐
y_med  (4×1) ────────────►│                         │
                          │      gpc_step           │
r_act  (2×1) ────────────►│                         ├────► u_new (2×1)
                          │  (resuelve QP adentro)  │
u_prev (2×1) ────────────►│                         │
                          └─────────────────────────┘
```

| Puerto | Dirección | Nombre | Tamaño | De dónde viene / a dónde va |
|---|---|---|---|---|
| 1 | Entrada | `y_med` | 4×1 | Salida del **Unit Delay 1** (estado medido) |
| 2 | Entrada | `r_act` | 2×1 | Salida del **Mux** de referencias |
| 3 | Entrada | `u_prev` | 2×1 | Salida del **Unit Delay 2** (entrada anterior) |
| 4 | Salida | `u_new` | 2×1 | Va a la **Saturation** |

### Bloque 7 — `planta_no_lineal` (MATLAB Function)
```
                          ┌─────────────────────────┐
u      (2×1) ────────────►│                         │
                          │     planta_no_lineal    │
h_prev (4×1) ────────────►│                         ├────► h_next (4×1)
                          │  (integra modelo no     │
Ts     (1×1) ────────────►│   lineal con ode4)      │
                          └─────────────────────────┘
```

| Puerto | Dirección | Nombre | Tamaño | De dónde viene / a dónde va |
|---|---|---|---|---|
| 1 | Entrada | `u` | 2×1 | Salida de la **Saturation** |
| 2 | Entrada | `h_prev` | 4×1 | Salida del **Unit Delay 1** (mismo que va al GPC) |
| 3 | Entrada | `Ts` | 1×1 | Bloque **Constant** con valor `Ts` |
| 4 | Salida | `h_next` | 4×1 | Va al **Unit Delay 1** |

### Bloque 8 — Unit Delay 1 (para el estado h)
```
h_next (4×1) ──►│ Unit Delay 1 │──► h_prev (4×1) ─────┬─► entra al GPC como y_med
                │ IC=zeros(4,1)│                       └─► entra a la planta como h_prev
```

| Dirección | Nombre | Tamaño |
|---|---|---|
| Entrada | `h_next` (de la planta) | 4×1 |
| Salida | se llama `h_prev` cuando va a la planta, `y_med` cuando va al GPC | 4×1 |

**Es la MISMA señal con dos nombres distintos según a dónde vaya.**

### Bloque 9 — Unit Delay 2 (para la entrada u)
```
u (2×1, saturada) ──►│ Unit Delay 2 │──► u_prev (2×1) ──► entra al GPC como u_prev
                     │ IC=zeros(2,1)│
```

| Dirección | Nombre | Tamaño |
|---|---|---|
| Entrada | `u` saturada (de la Saturation) | 2×1 |
| Salida | `u_prev` | 2×1 |

---

## Pasos en orden de armado

### Pasos 1 y 2 — Steps de referencia
- Step 1 (`ref_h3`): Initial = 25, Final = 30, Step time = 400
- Step 2 (`ref_h4`): Initial = 25, Final = 20, Step time = 800

### Paso 3 — Mux para `r_act`
- Biblioteca: `Simulink → Signal Routing → Mux`
- Number of inputs: `2`
- Entradas: salidas de Step 1 y Step 2
- Salida: `r_act` (vector 2×1)

### Paso 4 — MATLAB Function `gpc_step`
- Biblioteca: `Simulink → User-Defined Functions → MATLAB Function`
- Doble clic. Pega este código:

```matlab
function u_new = gpc_step(y_med, u_prev, r_act, Ad, Bd, Cd, ...
    G_din, Q, H_qp, A_ineq, h0, u0, h30, h40, ...
    N, Nu, Du_max, Du_min, u_max, u_min)

% Estado en variables desviadas
x_des = y_med - h0;
u_prev_des = u_prev - u0;

% Respuesta libre F
F_vec = zeros(2*N,1);
x_temp = x_des;
for j=1:N
    x_temp = Ad*x_temp + Bd*u_prev_des;
    y_pred = Cd*x_temp;
    F_vec(j)     = y_pred(1);
    F_vec(N+j)   = y_pred(2);
end

% Referencia futura constante
r_des = r_act - [h30; h40];
W = [repmat(r_des(1),N,1); repmat(r_des(2),N,1)];

% QP
f_qp = 2*G_din'*Q*(F_vec - W);

% Vector de cotas (depende de u_prev)
Du_max_v = [repmat(Du_max(1),Nu,1); repmat(Du_max(2),Nu,1)];
Du_min_v = [repmat(Du_min(1),Nu,1); repmat(Du_min(2),Nu,1)];
u_max_v  = [repmat(u_max(1),Nu,1);  repmat(u_max(2),Nu,1)];
u_min_v  = [repmat(u_min(1),Nu,1);  repmat(u_min(2),Nu,1)];
u_prev_stack = [repmat(u_prev(1),Nu,1); repmat(u_prev(2),Nu,1)];

b_ineq = [Du_max_v; -Du_min_v;
          u_max_v - u_prev_stack;
         -u_min_v + u_prev_stack];

% Resolver QP
DU = quadprog(H_qp, f_qp, A_ineq, b_ineq);

% Primer incremento de cada canal
Du_aplicado = [DU(1); DU(Nu+1)];
u_new = u_prev + Du_aplicado;
u_new = max(min(u_new, u_max), u_min);
end
```

**Configuración de los parámetros del bloque:**

Las variables `Ad, Bd, Cd, G_din, Q, H_qp, A_ineq, h0, u0, h30, h40, N, Nu, Du_max, Du_min, u_max, u_min` aparecen como argumentos de la función pero NO son entradas (no se cablean): son **parámetros que se leen del workspace**.

Para configurarlos:
1. En el editor del bloque MATLAB Function, abre el **Symbols Pane** (Vista lateral)
2. Para cada variable, cambia el **Scope** de `Input` a **`Parameter`**
3. Después de eso, **solo quedarán 3 entradas cableables**: `y_med`, `u_prev`, `r_act`

### Paso 5 — Saturation
- Biblioteca: `Simulink → Discontinuities → Saturation`
- Upper limit: `u_max`
- Lower limit: `u_min`
- Entrada: `u_new` (del `gpc_step`)
- Salida: `u` (vector 2×1, saturada) → va a la **planta**

### Paso 6 — Constant `Ts`
- Biblioteca: `Simulink → Sources → Constant`
- Value: `Ts`
- Salida: va al puerto `Ts` de la **planta**

### Paso 7 — MATLAB Function `planta_no_lineal`
- **Es el mismo bloque** que el del PID (paso 13 de la Parte A). Puedes copiar/pegar.

### Paso 8 — Unit Delay 1 (para el estado h) ⚠ IMPORTANTE
- Biblioteca: `Simulink → Discrete → Unit Delay`
- **Initial condition: `zeros(4,1)`** ← arranca con tanques vacíos (Opción A)
- Sample time: `Ts`
- Entrada: `h_next` (de la planta)
- Salida: se cablea a **dos sitios**:
  - Al puerto `h_prev` del bloque `planta_no_lineal`
  - Al puerto `y_med` del bloque `gpc_step`

### Paso 9 — Unit Delay 2 (para la entrada u) ⚠ IMPORTANTE
- Initial condition: **`zeros(2,1)`** ← bombas apagadas al inicio
- Sample time: `Ts`
- Entrada: `u` saturada (de la Saturation, paso 5)
- Salida: cableada al puerto `u_prev` del bloque `gpc_step`

### Paso 10 — Scope
- Conecta a la salida del **Unit Delay 1** para visualizar `h3, h4`.
- Si quieres ver solo `h3` y `h4` y no las 4 alturas, usa Selectores con `Index=3` y `Index=4` como en el PID.

---

# DUDAS FRECUENTES

**¿Por qué tanto Unit Delay?**
Porque Simulink necesita romper el bucle algebraico entre el controlador y la planta. El Unit Delay introduce un retraso de un periodo de muestreo, lo cual es físicamente correcto: el controlador del instante `k` usa la medición del instante `k-1`.

**¿Cómo entra `h` (vector 4×1) al desacoplador?**
NO entra al desacoplador. El desacoplador solo opera sobre `v1` y `v2` (salidas de los PI). El vector `h` se realimenta a los **sumadores de error**, pasando por **Selectores** que extraen `h3` y `h4`.

**¿Es importante el `Ts` en `Step time`?**
Sí. Los Step deben tener `Step time = 400` o `800` literal, no múltiplos de `Ts`. Simulink se encarga de discretizar correctamente.

**¿Qué pasa si `quadprog` da error en Simulink?**
Activa `Configuration Parameters → Code Generation → Interface → "Support variable-size signals"`. Si aún así falla, usa **`fmincon`** o implementa el QP manualmente con el método del Lagrangiano.

---

# CHECKLIST FINAL

- [ ] Ejecuté `init_simulink.m` antes de abrir Simulink
- [ ] Solver = `Fixed-step ode4`, Fixed-step size = `Ts`, Stop time = `1500`
- [ ] Para PID: 2 Discrete PID, 2 Gain (`-k12`, `-k21`), 2 Sum (++), 2 Saturation, 1 Mux, 1 Planta, 1 Unit Delay, 2 Selectores
- [ ] Para GPC: 2 Steps, 1 Mux para referencias, 1 `gpc_step` (MATLAB Function), 1 Saturation, 1 Planta, 2 Unit Delays (h y u_prev)
- [ ] Las realimentaciones (h3, h4) van a los sumadores de error con signo `−`
- [ ] Los parámetros del `gpc_step` están declarados como `Parameter`, no `Input`
- [ ] Verifiqué con los Scopes que las respuestas coinciden con las de los scripts `controlador_PID.m` y `controlador_GPC.m`

---

Si en algún paso te atascas, dime exactamente cuál y te ayudo.
