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

### 🟧 BLOQUE DESACOPLADOR (pasos 7, 8, 9, 10) 🟧

Esto es el detalle que más cuesta entender. Los 4 bloques actúan así:

```
v1 ─────────────────────────► (+) ─────► u1_pre
                               ▲
                          (−k12·v2)
                               │
v2 ───────► Gain(−k12) ────────┘

v1 ───────► Gain(−k21) ────────┐
                               │
                          (−k21·v1)
                               ▼
v2 ─────────────────────────► (+) ─────► u2_pre
```

### Paso 7 — Gain `−k12`
- Biblioteca: `Simulink → Math Operations → Gain`
- Parámetro: Gain = `-k12`
- Entrada: `v2` (sale del PID 6)
- Salida: va al **Sum 9**

### Paso 8 — Gain `−k21`
- Mismo bloque
- Parámetro: Gain = `-k21`
- Entrada: `v1` (sale del PID 3)
- Salida: va al **Sum 10**

### Paso 9 — Sum (genera `u1_pre`)
- Tipo: `Sum`, signos: `++`
- Entradas:
  - `v1` directo (desde PID 3)
  - `−k12·v2` (salida del Gain 7)
- Salida: `u1_pre`

### Paso 10 — Sum (genera `u2_pre`)
- Tipo: `Sum`, signos: `++`
- Entradas:
  - `v2` directo (desde PID 6)
  - `−k21·v1` (salida del Gain 8)
- Salida: `u2_pre`

---

### Paso 11 — Saturation (límites de u1)
- Biblioteca: `Simulink → Discontinuities → Saturation`
- Parámetros:
  - Upper limit: `u_max(1)`
  - Lower limit: `u_min(1)`
- Entrada: `u1_pre`
- Salida: `u1` (señal final que va a la bomba 1)

### Paso 12 — Saturation (límites de u2)
- Análogo al 11 pero con `u_max(2)`, `u_min(2)`
- Salida: `u2`

### Paso 13 — Mux (combina u1 y u2 en vector)
- Biblioteca: `Simulink → Signal Routing → Mux`
- Parámetro: Number of inputs: `2`
- Entradas: `u1`, `u2`
- Salida: vector `u` de dimensión 2×1

### Paso 14 — MATLAB Function (planta no lineal)
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

### Paso 15 — Unit Delay (memoria del estado)
- Biblioteca: `Simulink → Discrete → Unit Delay`
- Parámetros:
  - Initial condition: `h0` (vector 4×1)
  - Sample time: `Ts`
- Entrada: `h_next` (de la planta)
- Salida: `h_prev` (vuelve a la planta como entrada y se ramifica a los Selectores)

### Pasos 16 y 17 — Selectores para extraer h₃ y h₄
- Biblioteca: `Simulink → Signal Routing → Selector`
- Parámetros del Selector h₃ (paso 16):
  - Number of input dimensions: `1`
  - Index Option: `Index vector (dialog)`
  - Index: `3`
- Parámetros del Selector h₄ (paso 17):
  - Index: `4`
- Entradas: vector `h` del Unit Delay
- Salidas: `h3` → al Sum 5 (entrada −) | `h4` → al Sum 2 (entrada −)

### Paso 18 — Scope
- Biblioteca: `Simulink → Sinks → Scope`
- Conecta: salidas de los Selectores 16 y 17

---

# PARTE B — Implementación del GPC

> **Mira la imagen `simulink_GPC_detallado.png` mientras lees esto.**

El GPC es **más simple visualmente** que el PID porque toda la complejidad vive dentro de UN solo bloque MATLAB Function (`gpc_step`).

### Paso 1 y 2 — Steps de referencia
- Igual que los Step del PID:
  - Step 1: `ref_h3` (25→30 en t=400)
  - Step 2: `ref_h4` (25→20 en t=800)

### Paso 3 — Mux (combina referencias)
- Number of inputs: `2`
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

**Importante: las matrices (Ad, Bd, Cd, G_din, Q, H_qp, A_ineq, h0, u0, etc.) son parámetros del bloque, no entradas.** Para configurarlos:
1. En el editor del MATLAB Function, ve a `Model Explorer`
2. Selecciona cada variable y cambia su Scope a **`Parameter`**
3. Marca **Tunable: false**

### Paso 5 — Saturation
- Igual que en el PID (límites `u_min`, `u_max` ya están dentro del `gpc_step`, este Saturation es una protección adicional)

### Paso 6 — MATLAB Function `planta_no_lineal`
- **Es el mismo bloque** que el del PID (Paso 14 de la Parte A). Puedes copiar/pegar.

### Paso 7 — Unit Delay (memoria del estado h)
- Initial condition: `h0`
- Salida: `y_med` (vector 4×1) que vuelve a `gpc_step`

### Paso 8 — Unit Delay (memoria de u_prev)
- Initial condition: `u0`
- Salida: `u_prev` (vector 2×1) que vuelve a `gpc_step`

### Paso 9 — Scope
- Conecta a `h3` y `h4` (puedes extraer con Selectores como en el PID)

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
