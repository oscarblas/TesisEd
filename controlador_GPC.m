%% ========================================================================
%  controlador_GPC.m
%  Control Predictivo Generalizado (GPC) Multivariable
%  Aplicado al sistema de 4 tanques acoplados
%
%  Estructura:
%    1. Definicion de la planta (parametros y punto de operacion)
%    2. Modelo lineal continuo y discretizacion
%    3. Modelo aumentado para accion integral (formulacion en Delta_u)
%    4. Matrices de prediccion (F y Phi)
%    5. Funcion de costo y matrices de ponderacion (Q, R)
%    6. Restricciones (formulacion QP)
%    7. Lazo de control con horizonte deslizante (sobre planta no lineal)
%    8. Graficas y analisis
% ========================================================================

clear; clc; close all;

%% ========================================================================
%  1) PARAMETROS FISICOS Y PUNTO DE OPERACION
%  ------------------------------------------------------------------------
%  Mismo modelo del sistema de 4 tanques que usamos en respuesta_escalon.m
% ========================================================================

% Parametros fisicos
A1=706.85; A2=706.85; A3=706.85; A4=706.85;   % Areas de tanques [cm^2]
a1=1.89;   a2=1.89;   a3=5.39;   a4=5.39;     % Areas de salida [cm^2]
k1=1;      k2=1;                              % Ganancias de bombas
y1=0.7;    y2=0.7;                            % Posicion de valvulas (0-1)
g=981;                                        % Gravedad [cm/s^2]

% Punto de operacion (alturas deseadas en tanques inferiores)
h30 = 25; h40 = 25;

% Calculo de entradas estacionarias resolviendo equilibrio
M_A = [(1-y1)*k1   y2*k2;
       y1*k1       (1-y2)*k2];
M_B = [a3*sqrt(2*g*h30); a4*sqrt(2*g*h40)];
u0  = M_A\M_B;
u10 = u0(1); u20 = u0(2);

% Alturas estacionarias de tanques superiores
h10 = ((1-y2)*k2*u20/a1)^2/(2*g);
h20 = ((1-y1)*k1*u10/a2)^2/(2*g);
h0  = [h10; h20; h30; h40];

fprintf('Punto de operacion:\n');
fprintf('  h0 = [%.2f, %.2f, %.2f, %.2f] cm\n', h0);
fprintf('  u0 = [%.2f, %.2f]\n\n', u10, u20);

%% ========================================================================
%  2) MODELO LINEAL CONTINUO Y DISCRETIZACION
%  ------------------------------------------------------------------------
%  El GPC trabaja en tiempo discreto, asi que tomamos las matrices A,B,C,D
%  del modelo linealizado y las convertimos a tiempo discreto con periodo
%  de muestreo Ts.
% ========================================================================

% Matrices del modelo lineal continuo (linealizacion alrededor de h0)
T1 = A1/a1*sqrt(2*h10/g);
T2 = A2/a2*sqrt(2*h20/g);
T3 = A3/a3*sqrt(2*h30/g);
T4 = A4/a4*sqrt(2*h40/g);

Ac = [-1/T1        0           0      0;
       0          -1/T2        0      0;
       0           A2/(A3*T2) -1/T3   0;
       A1/(A4*T1)  0           0     -1/T4];

Bc = [0            (1-y2)*k2/A1;
      (1-y1)*k1/A2  0;
      0             y2*k2/A3;
      y1*k1/A4      0];

% Solo controlamos h3 y h4 (tanques inferiores) -> 2 salidas
Cc = [0 0 1 0;
      0 0 0 1];

Dc = zeros(2,2);

% Discretizacion con ZOH (zero-order hold)
% Ts obtenido del analisis comparativo de sintonizacion (analisis_sintonizacion_GPC.m)
% Metodo ganador: Optimizacion numerica via fminsearch
%   Score = 0.0733 | IAE = 213.7 | t_est = 18s | overshoot = 0.05%
Ts = 2;                                % Periodo de muestreo [s]
sys_c = ss(Ac, Bc, Cc, Dc);
sys_d = c2d(sys_c, Ts, 'zoh');
[Ad, Bd, Cd, Dd] = ssdata(sys_d);

% Dimensiones del sistema
nx = size(Ad,1);   % numero de estados (4)
nu = size(Bd,2);   % numero de entradas (2)
ny = size(Cd,1);   % numero de salidas (2)

fprintf('Modelo discretizado con Ts = %d s\n', Ts);
fprintf('  Estados: %d  |  Entradas: %d  |  Salidas: %d\n\n', nx, nu, ny);

%% ========================================================================
%  3) MODELO AUMENTADO PARA ACCION INTEGRAL
%  ------------------------------------------------------------------------
%  En GPC se trabaja con incrementos de control Du(k) = u(k) - u(k-1)
%  para garantizar accion integral (error nulo en estado estacionario
%  ante perturbaciones constantes).
%
%  Definimos un nuevo estado aumentado:
%       xi(k) = [Dx(k); y(k)]
%  donde Dx(k) = x(k) - x(k-1)
%
%  Modelo aumentado:
%       xi(k+1) = A_t*xi(k) + B_t*Du(k)
%       y(k)    = C_t*xi(k)
%
%  De este modo la entrada del problema de optimizacion son los incrementos
%  Du(k), Du(k+1), ..., Du(k+Nu-1)
% ========================================================================

A_t = [Ad        zeros(nx,ny);
       Cd*Ad    eye(ny)];

B_t = [Bd;
       Cd*Bd];

C_t = [zeros(ny,nx)  eye(ny)];

n_xi = size(A_t,1);   % dimension del estado aumentado

%% ========================================================================
%  4) MATRICES DE PREDICCION
%  ------------------------------------------------------------------------
%  Horizontes:
%    N  = horizonte de prediccion (cuantos pasos al futuro miramos)
%    Nu = horizonte de control    (cuantos Du futuros optimizamos)
%
%  Ecuacion de prediccion en forma matricial:
%       Y = F*xi(k) + Phi*DU
%
%  Donde:
%    Y   = [y(k+1); y(k+2); ...; y(k+N)]      vector de predicciones
%    DU  = [Du(k); Du(k+1); ...; Du(k+Nu-1)]  vector de incrementos
%    F   = matriz que captura el efecto del estado actual
%    Phi = matriz que captura el efecto de los Du futuros (lower-triangular)
% ========================================================================

% Horizontes obtenidos del analisis de sintonizacion (metodo ganador: optimizacion numerica)
N  = 50;   % Horizonte de prediccion
Nu = 9;    % Horizonte de control (optimo encontrado por fminsearch)

% Matriz F (apila C_t * A_t^j)
F = zeros(N*ny, n_xi);
for j = 1:N
    F((j-1)*ny+1:j*ny, :) = C_t * A_t^j;
end

% Matriz Phi (lower-triangular block matrix)
Phi = zeros(N*ny, Nu*nu);
for i = 1:N
    for j = 1:Nu
        if i >= j
            Phi((i-1)*ny+1:i*ny, (j-1)*nu+1:j*nu) = C_t * A_t^(i-j) * B_t;
        end
    end
end

%% ========================================================================
%  5) FUNCION DE COSTO Y MATRICES DE PONDERACION
%  ------------------------------------------------------------------------
%  Funcion de costo cuadratica:
%
%       J = (Y - W)' * Q * (Y - W)  +  DU' * R * DU
%
%  donde:
%    W = vector de referencias futuras [w(k+1); w(k+2); ...; w(k+N)]
%    Q = matriz que pondera errores de seguimiento (delta en GPC clasico)
%    R = matriz que pondera esfuerzo de control (lambda en GPC clasico)
%
%  Sustituyendo Y = F*xi + Phi*DU:
%
%       J = DU'*(Phi'*Q*Phi + R)*DU - 2*(W - F*xi)'*Q*Phi*DU + const
%
%  Forma estandar para quadprog:  min  0.5*DU'*H*DU + f'*DU
% ========================================================================

% Pesos optimos del analisis comparativo (metodo: optimizacion numerica fminsearch)
delta  = [10, 10];                    % peso de seguimiento para [h3, h4]
lambda = [0.0076803, 0.0076803];      % peso de esfuerzo de control [Du1, Du2] (optimo)

% Matrices de ponderacion (block-diagonales)
Q = kron(eye(N),  diag(delta));    % size: (N*ny) x (N*ny)
R = kron(eye(Nu), diag(lambda));   % size: (Nu*nu) x (Nu*nu)

% Hessiano (constante, se calcula una sola vez)
H = 2*(Phi'*Q*Phi + R);
H = (H + H')/2;   % asegurar simetria numerica

%% ========================================================================
%  6) RESTRICCIONES (FORMULACION PARA QP)
%  ------------------------------------------------------------------------
%  En sistemas reales tenemos limites fisicos:
%
%   (a) En el incremento de control:    Du_min <= Du(k+i) <= Du_max
%   (b) En la entrada absoluta:         u_min  <= u(k+i)  <= u_max
%   (c) En la salida (opcional):        y_min  <= y(k+i)  <= y_max
%
%  La restriccion (a) es directa porque DU es la variable de decision.
%  La restriccion (b) requiere expresar u(k+i) como acumulado de Du:
%       u(k+i) = u(k-1) + sum_{j=0..i} Du(k+j)
%  Lo cual se escribe matricialmente como:  u_futuro = T*DU + 1*u(k-1)
% ========================================================================

% Limites fisicos (tu los ajustas segun la planta real)
Du_max = [100; 100];         % maximo cambio por paso (mas margen para respuesta rapida)
Du_min = -Du_max;

u_max = [u10*2; u20*2];      % limite superior absoluto (100% sobre estacionario)
u_min = [0; 0];              % las bombas no pueden dar caudal negativo

% Matriz T: u_futuro = T*DU + ones*u(k-1)
% T es lower-triangular de bloques identidad
T_mat = kron(tril(ones(Nu)), eye(nu));
ones_blk = repmat(eye(nu), Nu, 1);

% Construccion de A_ineq * DU <= b_ineq
%   Du_min <= DU <= Du_max
%   u_min  <= T*DU + ones*u(k-1) <= u_max
%
% Note: parte que depende de u(k-1) se actualiza cada iteracion
A_ineq_static = [ eye(Nu*nu);
                 -eye(Nu*nu);
                  T_mat;
                 -T_mat ];

% Limites para Du y u (la parte dependiente de u(k-1) la ponemos en el lazo)
Du_max_vec = repmat(Du_max, Nu, 1);
Du_min_vec = repmat(Du_min, Nu, 1);
u_max_vec  = repmat(u_max,  Nu, 1);
u_min_vec  = repmat(u_min,  Nu, 1);

%% ========================================================================
%  7) LAZO DE CONTROL CON HORIZONTE DESLIZANTE
%  ------------------------------------------------------------------------
%  En cada instante k:
%    1. Medir/estimar el estado actual x(k)
%    2. Construir xi(k) = [Dx(k); y(k)]
%    3. Construir referencia futura W
%    4. Resolver QP -> obtener DU optimo
%    5. Aplicar SOLO el primer incremento: u(k) = u(k-1) + Du(k)
%    6. Avanzar la planta NO LINEAL un paso de Ts
%    7. Repetir
% ========================================================================

% Tiempo total y referencia
t_sim = 1500;                  % tiempo total de simulacion [s]
N_steps = round(t_sim/Ts);     % numero de pasos de control
t_vec = (0:N_steps-1)*Ts;

% Setpoint para [h3; h4] (dentro del rango de operacion)
% Cambio de referencia en t = 500s
ref = zeros(ny, N_steps);
ref(:,1:round(500/Ts))     = repmat([25; 25], 1, round(500/Ts));      % inicial
ref(:,round(500/Ts)+1:end) = repmat([30; 20], 1, N_steps - round(500/Ts));  % nuevo SP

% Inicializacion
h_real    = h0;                % planta NO lineal arranca en el punto de operacion
u_actual  = [u10; u20];        % entrada actual = entrada estacionaria
u_prev    = u_actual;          % u(k-1)

x_lin     = zeros(nx,1);       % estado del modelo lineal en desviacion (Dx = x - x0)
x_lin_ant = x_lin;             % x(k-1) en desviacion
y_lin_ant = Cd*x_lin;          % y(k-1) en desviacion

% Historial para graficas
H_log     = zeros(4, N_steps); H_log(:,1) = h_real;
U_log     = zeros(nu, N_steps);
Du_log    = zeros(nu, N_steps);
ref_log   = ref;

% Parametros del modelo no lineal (para ode45)
params = struct('A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
                'a1',a1,'a2',a2,'a3',a3,'a4',a4, ...
                'k1',k1,'k2',k2,'y1',y1,'y2',y2,'g',g);

opts_qp = optimoptions('quadprog','Display','off');

for k = 1:N_steps-1
    % ---- (1) Estado del modelo lineal en desviacion ---------------------
    % Asumimos medicion completa del estado (puede sustituirse por un
    % observador/Kalman si solo se mide y).
    x_lin     = h_real - h0;                    % Dx_actual
    Dx_lin    = x_lin - x_lin_ant;              % delta del estado
    y_lin     = Cd*x_lin;                       % y en desviacion
    xi        = [Dx_lin; y_lin];                % estado aumentado

    % ---- (2) Vector de referencia futuro (en desviacion) ----------------
    % El modelo lineal trabaja en desviaciones, asi que la referencia
    % tambien se debe expresar como w - y0  (donde y0 = [h30; h40]).
    W = zeros(N*ny,1);
    for j = 1:N
        idx = min(k+j, N_steps);
        w_j = ref(:,idx) - [h30; h40];
        W((j-1)*ny+1:j*ny) = w_j;
    end

    % ---- (3) Construir restricciones que dependen de u_prev -------------
    %   u_prev en desviacion (porque trabajamos con el modelo lineal)
    Du_prev_dev = u_prev - u0;
    b_ineq = [ Du_max_vec;
              -Du_min_vec;
               u_max_vec - ones_blk*u_prev;
              -u_min_vec + ones_blk*u_prev ];

    % ---- (4) Resolver QP -----------------------------------------------
    %   J = 0.5*DU'*H*DU + f'*DU
    f_qp = -2*(W - F*xi)'*Q*Phi;
    f_qp = f_qp(:);

    [DU, ~, exitflag] = quadprog(H, f_qp, A_ineq_static, b_ineq, ...
                                 [], [], [], [], [], opts_qp);

    if exitflag ~= 1
        warning('QP no convergio en el paso %d (exitflag=%d)', k, exitflag);
        DU = zeros(Nu*nu,1);
    end

    % ---- (5) Aplicar SOLO el primer incremento --------------------------
    Du_aplicado = DU(1:nu);
    u_actual    = u_prev + Du_aplicado;

    % Saturacion de seguridad (defensiva; QP ya respeto los limites)
    u_actual = max(min(u_actual, u_max), u_min);

    U_log(:,k)  = u_actual;
    Du_log(:,k) = Du_aplicado;

    % ---- (6) Simular la planta NO LINEAL un paso (de t a t+Ts) ----------
    [~, h_traj] = ode45(@(t,h) modelo_nolineal(t,h,u_actual,params), ...
                        [0 Ts], h_real);
    h_real = h_traj(end,:)';

    % ---- (7) Actualizar variables para la siguiente iteracion -----------
    x_lin_ant = x_lin;
    u_prev    = u_actual;
    H_log(:,k+1) = h_real;
end

% Ultimo paso log
U_log(:,end)  = u_actual;

%% ========================================================================
%  8) GRAFICAS Y ANALISIS
% ========================================================================
figure('Name','GPC - Salidas controladas','NumberTitle','off')

subplot(2,1,1)
plot(t_vec, H_log(3,:), 'b', 'LineWidth', 1.5); hold on;
stairs(t_vec, ref_log(1,:), 'r--', 'LineWidth', 1.2);
ylabel('h_3 (cm)'); xlabel('Tiempo (s)');
legend('h_3 medido','Referencia','Location','best');
title('Tanque 3 (controlado)'); grid on;

subplot(2,1,2)
plot(t_vec, H_log(4,:), 'b', 'LineWidth', 1.5); hold on;
stairs(t_vec, ref_log(2,:), 'r--', 'LineWidth', 1.2);
ylabel('h_4 (cm)'); xlabel('Tiempo (s)');
legend('h_4 medido','Referencia','Location','best');
title('Tanque 4 (controlado)'); grid on;

sgtitle('GPC multivariable sobre planta no lineal');

figure('Name','GPC - Senales de control','NumberTitle','off')
subplot(2,1,1)
stairs(t_vec, U_log(1,:), 'b', 'LineWidth', 1.5); hold on;
yline(u_max(1),'k--'); yline(u_min(1),'k--');
ylabel('u_1'); xlabel('Tiempo (s)');
title('Entrada u_1 (con limites)'); grid on;

subplot(2,1,2)
stairs(t_vec, U_log(2,:), 'r', 'LineWidth', 1.5); hold on;
yline(u_max(2),'k--'); yline(u_min(2),'k--');
ylabel('u_2'); xlabel('Tiempo (s)');
title('Entrada u_2 (con limites)'); grid on;

figure('Name','GPC - Tanques superiores (no controlados)','NumberTitle','off')
subplot(2,1,1)
plot(t_vec, H_log(1,:), 'b', 'LineWidth', 1.5);
ylabel('h_1 (cm)'); xlabel('Tiempo (s)');
title('Tanque 1 (no controlado)'); grid on;

subplot(2,1,2)
plot(t_vec, H_log(2,:), 'b', 'LineWidth', 1.5);
ylabel('h_2 (cm)'); xlabel('Tiempo (s)');
title('Tanque 2 (no controlado)'); grid on;

%% ========================================================================
%  FUNCION DEL MODELO NO LINEAL (planta real para simular)
% ========================================================================
function dhdt = modelo_nolineal(~, h, u, p)
    h1 = max(h(1),0); h2 = max(h(2),0);
    h3 = max(h(3),0); h4 = max(h(4),0);
    u1 = u(1); u2 = u(2);

    dhdt = zeros(4,1);
    dhdt(1) = -p.a1/p.A1*sqrt(2*p.g*h1) + (1-p.y2)*p.k2*u2/p.A1;
    dhdt(2) = -p.a2/p.A2*sqrt(2*p.g*h2) + (1-p.y1)*p.k1*u1/p.A2;
    dhdt(3) = -p.a3/p.A3*sqrt(2*p.g*h3) + p.a2/p.A3*sqrt(2*p.g*h2) + p.y2*p.k2*u2/p.A3;
    dhdt(4) = -p.a4/p.A4*sqrt(2*p.g*h4) + p.a1/p.A4*sqrt(2*p.g*h1) + p.y1*p.k1*u1/p.A4;
end
