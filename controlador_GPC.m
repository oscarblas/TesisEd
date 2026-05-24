%% ========================================================================
%  controlador_GPC.m
%  Control Predictivo Generalizado (GPC) Multivariable
%  Formulacion CARIMA + ecuaciones diofanticas, aplicada al sistema de
%  cuatro tanques acoplados.
%
%  Estructura del archivo:
%   1) Parametros fisicos y punto de operacion
%   2) Modelo lineal continuo y discretizacion
%   3) Matriz de funciones de transferencia G(z) y coeficientes de
%      respuesta al escalon (g_ij[k]) que conforman la matriz dinamica
%   4) Construccion de la matriz dinamica G por bloques (formato GPC)
%   5) Matrices de ponderacion Q, R y Hessiano H del QP
%   6) Restricciones (formulacion QP)
%   7) Bucle de control con horizonte deslizante sobre la planta no lineal
%   8) Graficas y analisis
% ========================================================================

clear; clc; close all;

%% ========================================================================
%  1) PARAMETROS FISICOS Y PUNTO DE OPERACION
% ========================================================================
A1=706.85; A2=706.85; A3=706.85; A4=706.85;
a1=1.89;   a2=1.89;   a3=5.39;   a4=5.39;
k1=1;      k2=1;
y1=0.7;    y2=0.7;
g=981;

h30 = 25; h40 = 25;
M_A = [(1-y1)*k1 y2*k2;
       y1*k1    (1-y2)*k2];
M_B = [a3*sqrt(2*g*h30); a4*sqrt(2*g*h40)];
u0  = M_A\M_B;
u10 = u0(1); u20 = u0(2);

h10 = ((1-y2)*k2*u20/a1)^2/(2*g);
h20 = ((1-y1)*k1*u10/a2)^2/(2*g);
h0  = [h10; h20; h30; h40];

fprintf('Punto de operacion:\n');
fprintf('  h0 = [%.2f, %.2f, %.2f, %.2f] cm\n', h0);
fprintf('  u0 = [%.2f, %.2f]\n\n', u10, u20);

%% ========================================================================
%  2) MODELO LINEAL CONTINUO Y DISCRETIZACION
% ========================================================================
% Constantes de tiempo
T1 = A1/a1*sqrt(2*h10/g);
T2 = A2/a2*sqrt(2*h20/g);
T3 = A3/a3*sqrt(2*h30/g);
T4 = A4/a4*sqrt(2*h40/g);

% Modelo lineal continuo en espacio de estados (alrededor de h0)
Ac = [-1/T1        0           0      0;
       0          -1/T2        0      0;
       0           A2/(A3*T2) -1/T3   0;
       A1/(A4*T1)  0           0     -1/T4];

Bc = [0            (1-y2)*k2/A1;
      (1-y1)*k1/A2  0;
      0             y2*k2/A3;
      y1*k1/A4      0];

% Salidas controladas: h3 (TK-03) y h4 (TK-04)
Cc = [0 0 1 0;
      0 0 0 1];
Dc = zeros(2,2);

% Discretizacion con ZOH (parametro de sintonizacion)
Ts = 2;
sys_c = ss(Ac, Bc, Cc, Dc);
sys_d = c2d(sys_c, Ts, 'zoh');

ny = 2;   % numero de salidas controladas (h3, h4)
nu = 2;   % numero de entradas (u1, u2)

%% ========================================================================
%  3) MATRIZ DE FUNCIONES DE TRANSFERENCIA Y RESPUESTAS AL ESCALON
%  ------------------------------------------------------------------------
%  Para cada par entrada(j) - salida(i) se obtiene la funcion de transfe-
%  rencia discreta G_ij(z) y, a partir de ella, los coeficientes de la
%  respuesta al escalon g_ij[k] = y_step_ij(k*Ts), para k = 1..N.
%
%  Estos coeficientes son los que aparecen en el desarrollo CARIMA + dio-
%  fantico al construir la matriz dinamica G: el bloque G_ij es triangular
%  inferior y contiene los coeficientes de la respuesta al escalon de
%  cada subproceso.
% ========================================================================
N  = 50;   % horizonte de prediccion (N2 con N1 = 1, d = 0)
Nu = 9;    % horizonte de control

G_z = tf(sys_d);   % matriz de funciones de transferencia discretas

% g_step{i,j} contiene el vector [g_ij(1); g_ij(2); ...; g_ij(N)]
g_step = cell(ny, nu);
t_step = (0:N)*Ts;
for i = 1:ny
    for j = 1:nu
        [y_step_ij, ~] = step(G_z(i,j), t_step);
        g_step{i,j} = y_step_ij(2:end);     % descarta y(0)
    end
end

%% ========================================================================
%  4) MATRIZ DINAMICA G POR BLOQUES (FORMULACION GPC MIMO)
%  ------------------------------------------------------------------------
%  Convencion de apilado (consistente con el formalismo GPC clasico):
%     Y_pred = [y_1(k+1); ...; y_1(k+N); y_2(k+1); ...; y_2(k+N)]
%     Delta_U = [Du_1(k); ...; Du_1(k+Nu-1); Du_2(k); ...; Du_2(k+Nu-1)]
%
%  La matriz G tiene tamaño (ny*N) x (nu*Nu) y se construye con bloques
%  G_ij (cada uno triangular inferior, dimensiones N x Nu):
%
%     G = [G_11  G_12]
%         [G_21  G_22]
% ========================================================================
G = zeros(ny*N, nu*Nu);
for i = 1:ny
    for j = 1:nu
        G_block = zeros(N, Nu);
        for r = 1:N
            for c = 1:Nu
                if r >= c
                    G_block(r,c) = g_step{i,j}(r - c + 1);
                end
            end
        end
        G((i-1)*N + (1:N), (j-1)*Nu + (1:Nu)) = G_block;
    end
end

%% ========================================================================
%  5) MATRICES DE PONDERACION Y HESSIANO
% ========================================================================
% Pesos (sintonizacion ganadora del analisis comparativo)
delta  = [10, 10];                    % peso de seguimiento [h3, h4]
lambda = [0.0076803, 0.0076803];      % peso de esfuerzo    [Du1, Du2]

% Matrices Q y R en el formato apilado por salida / por entrada:
Q = blkdiag(delta(1)*eye(N),  delta(2)*eye(N));        % (ny*N) x (ny*N)
R = blkdiag(lambda(1)*eye(Nu), lambda(2)*eye(Nu));     % (nu*Nu) x (nu*Nu)

% Hessiano del QP (constante)
H_qp = 2*(G'*Q*G + R);
H_qp = (H_qp + H_qp')/2;

%% ========================================================================
%  6) RESTRICCIONES (FORMULACION QP)
%  ------------------------------------------------------------------------
%  Tipos de restriccion:
%   - sobre el incremento de control: Du_min <= Du(k+i) <= Du_max
%   - sobre el valor absoluto:        u_min  <= u(k+i)  <= u_max
%
%  Para el formato de apilado por entrada, la matriz T que expresa
%  u(k+i) = u(k-1) + sum_{j=0..i} Du(k+j) es bloque-diagonal con bloques
%  triangulares inferiores de unos (uno por entrada).
% ========================================================================
Du_max = [100; 100];     % maximo incremento por paso (por canal)
Du_min = -Du_max;
u_max  = [u10*2; u20*2]; % limite superior de las bombas
u_min  = [0; 0];

% Vectorizar limites (por canal: Nu valores de Du, Nu valores de u)
Du_max_vec = [repmat(Du_max(1), Nu, 1); repmat(Du_max(2), Nu, 1)];
Du_min_vec = [repmat(Du_min(1), Nu, 1); repmat(Du_min(2), Nu, 1)];
u_max_vec  = [repmat(u_max(1),  Nu, 1); repmat(u_max(2),  Nu, 1)];
u_min_vec  = [repmat(u_min(1),  Nu, 1); repmat(u_min(2),  Nu, 1)];

% Matriz T bloque-diagonal (triangular inferior por canal)
Tri_one = tril(ones(Nu));
T_mat   = blkdiag(Tri_one, Tri_one);

A_ineq_static = [ eye(nu*Nu);
                 -eye(nu*Nu);
                  T_mat;
                 -T_mat ];

%% ========================================================================
%  7) BUCLE DE CONTROL CON HORIZONTE DESLIZANTE
% ========================================================================
[Ad, Bd, Cd, Dd] = ssdata(sys_d);

% Tiempo de simulacion y vector de referencia
t_sim   = 1500;
N_steps = round(t_sim/Ts);
t_vec   = (0:N_steps-1)*Ts;

ref = zeros(ny, N_steps);
k_ch = round(500/Ts);
ref(:, 1:k_ch)       = repmat([25; 25], 1, k_ch);
ref(:, k_ch+1:end)   = repmat([30; 20], 1, N_steps - k_ch);

% Inicializacion
h_real = h0;                 % planta NO lineal en variables absolutas
u_prev = [u10; u20];         % u(k-1) en variables absolutas

H_log = zeros(4, N_steps); H_log(:,1) = h_real;
U_log = zeros(nu, N_steps);

params = struct('A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
                'a1',a1,'a2',a2,'a3',a3,'a4',a4, ...
                'k1',k1,'k2',k2,'y1',y1,'y2',y2,'g',g);

opts_qp = optimoptions('quadprog','Display','off');

for k = 1:N_steps-1
    % ---- (a) Estado en variables desviadas ------------------------------
    x_des = h_real - h0;             % desviacion del estado
    u_prev_des = u_prev - u0;        % desviacion de la entrada anterior

    % ---- (b) Respuesta libre F (en desviacion) --------------------------
    %  Se predice la trayectoria de las salidas asumiendo que NO se
    %  aplican nuevos incrementos (Delta_u = 0 para j >= 0), por lo cual
    %  u(k+i) = u(k-1) durante todo el horizonte.
    %  Esta es la traduccion practica de la formulacion CARIMA, donde:
    %     F_j(z^-1)*y(t) + [contribucion de Delta_u pasadas]
    %  se obtiene como la propagacion del modelo a lazo abierto.
    F_vec = zeros(ny*N, 1);
    x_temp = x_des;
    for j = 1:N
        x_temp = Ad*x_temp + Bd*u_prev_des;
        y_pred = Cd*x_temp;          % en desviacion
        F_vec(j)     = y_pred(1);    % h3 - h30
        F_vec(N + j) = y_pred(2);    % h4 - h40
    end

    % ---- (c) Vector de referencia futura (en desviacion) ----------------
    %  Se usa el setpoint actual r(k); no hay anticipacion de cambios
    %  futuros (principio de causalidad).
    r_des = ref(:,k) - [h30; h40];
    W = [repmat(r_des(1), N, 1); repmat(r_des(2), N, 1)];

    % ---- (d) Vector lineal del QP ---------------------------------------
    %  f_qp = 2*G' * Q * (F - W)
    f_qp = 2*G'*Q*(F_vec - W);

    % ---- (e) Vector de cotas de las restricciones -----------------------
    u_prev_stack = [repmat(u_prev(1), Nu, 1); repmat(u_prev(2), Nu, 1)];
    b_ineq = [ Du_max_vec;
              -Du_min_vec;
               u_max_vec - u_prev_stack;
              -u_min_vec + u_prev_stack ];

    % ---- (f) Resolucion del QP ------------------------------------------
    [DU, ~, exitflag] = quadprog(H_qp, f_qp, A_ineq_static, b_ineq, ...
                                 [], [], [], [], [], opts_qp);
    if exitflag ~= 1
        warning('QP no convergio en k=%d (exitflag=%d)', k, exitflag);
        DU = zeros(nu*Nu, 1);
    end

    % ---- (g) Aplicar SOLO el primer incremento de cada canal -----------
    Du_aplicado = [DU(1); DU(Nu + 1)];   % primer Du1, primer Du2
    u_actual    = u_prev + Du_aplicado;
    u_actual    = max(min(u_actual, u_max), u_min);   % saturacion

    U_log(:,k) = u_actual;

    % ---- (h) Simular planta no lineal un paso de Ts ---------------------
    [~, h_traj] = ode45(@(t,h) modelo_nolineal(t,h,u_actual,params), ...
                        [0 Ts], h_real);
    h_real = h_traj(end,:)';

    u_prev = u_actual;
    H_log(:, k+1) = h_real;
end
U_log(:, end) = u_prev;

%% ========================================================================
%  8) GRAFICAS Y ANALISIS
% ========================================================================
figure('Name','GPC - Salidas controladas','NumberTitle','off')

subplot(2,1,1)
plot(t_vec, H_log(3,:), 'b', 'LineWidth', 1.5); hold on;
stairs(t_vec, ref(1,:), 'r--', 'LineWidth', 1.2);
ylabel('h_3 (cm)'); xlabel('Tiempo (s)');
legend('h_3 medido','Referencia','Location','best');
title('Tanque 3 (controlado)'); grid on;

subplot(2,1,2)
plot(t_vec, H_log(4,:), 'b', 'LineWidth', 1.5); hold on;
stairs(t_vec, ref(2,:), 'r--', 'LineWidth', 1.2);
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
%  FUNCION DEL MODELO NO LINEAL (planta real)
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
