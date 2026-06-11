%% ========================================================================
%  controlador_PID.m
%  Control PI Descentralizado (Multilazo) para el Sistema TITO de
%  Cuatro Tanques Acoplados.
%
%  Estructura (conforme a la seccion 4.2 de la tesis):
%    Lazo 1:  PI_1  -->  u_1  -->  controla  h_4
%    Lazo 2:  PI_2  -->  u_2  -->  controla  h_3
%
%  Cada lazo opera de forma INDEPENDIENTE, ignorando el acoplamiento
%  cruzado interno de la planta. Este es el caso de referencia para la
%  comparacion contra el GPC en el Capitulo 4.
%
%  Sintonizacion: Internal Model Control (IMC) con lambda_imc = tau/3.
%  Algoritmo:     PI discreto en forma incremental (forma de velocidad).
%  Anti-windup:   saturacion directa de u(k) a los limites fisicos
%                 (consecuencia natural de la forma incremental).
% ========================================================================

clear; clc; close all;

%% ========================================================================
%  1) PARAMETROS FISICOS Y PUNTO DE OPERACION (mismos del Cap. 2)
% ========================================================================
A1=706.85; A2=706.85; A3=706.85; A4=706.85;
a1=1.89;   a2=1.89;   a3=5.39;   a4=5.39;
k1=1;      k2=1;
y1=0.7;    y2=0.7;
g=981;

h30=25; h40=25;
M_A = [(1-y1)*k1   y2*k2;
       y1*k1       (1-y2)*k2];
M_B = [a3*sqrt(2*g*h30); a4*sqrt(2*g*h40)];
u0  = M_A\M_B;
u10 = u0(1); u20 = u0(2);

h10 = ((1-y2)*k2*u20/a1)^2/(2*g);
h20 = ((1-y1)*k1*u10/a2)^2/(2*g);
h0  = [h10; h20; h30; h40];

% Constantes de tiempo (para sintonizacion IMC)
T1 = A1/a1*sqrt(2*h10/g);
T2 = A2/a2*sqrt(2*h20/g);
T3 = A3/a3*sqrt(2*h30/g);
T4 = A4/a4*sqrt(2*h40/g);

fprintf('=== Punto de operacion ===\n');
fprintf('  h0 = [%.2f, %.2f, %.2f, %.2f] cm\n', h0);
fprintf('  u0 = [%.2f, %.2f]\n\n', u10, u20);

%% ========================================================================
%  2) SINTONIZACION IMC (Internal Model Control)  -- Seccion 4.2.2
%  ------------------------------------------------------------------------
%  Cada lazo se aproxima a un modelo de primer orden:
%        G(s) = K / (tau*s + 1)
%
%  Reglas IMC para PI (con tiempo muerto despreciable):
%        Kp = tau / (K * lambda_imc)
%        Ti = tau
%
%  lambda_imc es la constante de tiempo deseada en lazo cerrado:
%        lambda_imc = tau/3  -> control rapido (lo que usamos)
%        lambda_imc = tau    -> control balanceado
%        lambda_imc = 2*tau  -> control conservador
% ========================================================================

% Lazo 1: u1 -> h4
K1   = y1*k1*T4/A4;
tau1 = T4;
lam1 = tau1/3;
Kp1  = tau1/(K1*lam1);
Ti1  = tau1;
Td1  = 0;                % se usa PI (sin termino derivativo)

% Lazo 2: u2 -> h3
K2   = y2*k2*T3/A3;
tau2 = T3;
lam2 = tau2/3;
Kp2  = tau2/(K2*lam2);
Ti2  = tau2;
Td2  = 0;

fprintf('=== Sintonizacion IMC (lambda_imc = tau/3) ===\n');
fprintf('  Lazo 1 (u1 -> h4):  K = %.4f,  tau = %.2f s\n', K1, tau1);
fprintf('                      Kp = %.3f,  Ti = %.2f s\n', Kp1, Ti1);
fprintf('  Lazo 2 (u2 -> h3):  K = %.4f,  tau = %.2f s\n', K2, tau2);
fprintf('                      Kp = %.3f,  Ti = %.2f s\n\n', Kp2, Ti2);

%% ========================================================================
%  3) PARAMETROS DE SIMULACION
% ========================================================================
Ts = 2;                      % mismo Ts que el GPC para comparacion justa
t_sim = 1500;
N_steps = round(t_sim/Ts);
t_vec = (0:N_steps-1)*Ts;

% Setpoint del escenario nominal (referencias cruzadas en t=500s)
ref = zeros(2, N_steps);
ref(:,1:round(500/Ts))     = repmat([25; 25], 1, round(500/Ts));
ref(:,round(500/Ts)+1:end) = repmat([30; 20], 1, N_steps - round(500/Ts));

% Limites fisicos de las bombas
u_max = [u10*2; u20*2];
u_min = [0; 0];

%% ========================================================================
%  4) IMPLEMENTACION PI DISCRETO CON ANTI-WINDUP   -- Seccion 4.2.3
%  ------------------------------------------------------------------------
%  Forma incremental (forma de velocidad):
%
%      Du(k) = Kp * (e(k) - e(k-1)) + (Kp*Ts/Ti) * e(k)
%      u(k)  = u(k-1) + Du(k)
%      u(k)  = sat(u(k), [u_min, u_max])    <- anti-windup natural
%
%  La forma incremental + saturacion directa de u(k) garantiza que el
%  termino integral NO acumule durante la saturacion, eliminando el
%  efecto de windup sin necesidad de back-calculation.
% ========================================================================

h_real   = h0;                  % planta no lineal en variables absolutas
u_actual = [u10; u20];
u_prev   = u_actual;

% Memoria de errores para la forma incremental
e1_k1=0;  e2_k1=0;               % e(k-1) inicial = 0

% Historial para graficas y metricas
H_log = zeros(4, N_steps); H_log(:,1) = h_real;
U_log = zeros(2, N_steps);

params = struct('A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
                'a1',a1,'a2',a2,'a3',a3,'a4',a4, ...
                'k1',k1,'k2',k2,'y1',y1,'y2',y2,'g',g);

for k = 1:N_steps-1
    % --- Errores actuales (cada lazo SOLO conoce su salida emparejada) ---
    e1 = ref(2,k) - h_real(4);     % PID1: error en h4
    e2 = ref(1,k) - h_real(3);     % PID2: error en h3

    % --- Forma incremental PI ---
    Du1 = Kp1*(e1 - e1_k1) + (Kp1*Ts/Ti1)*e1;
    Du2 = Kp2*(e2 - e2_k1) + (Kp2*Ts/Ti2)*e2;

    % --- Actualizar control ---
    u_actual(1) = u_prev(1) + Du1;
    u_actual(2) = u_prev(2) + Du2;

    % --- Anti-windup por saturacion directa ---
    u_actual = max(min(u_actual, u_max), u_min);

    U_log(:,k) = u_actual;

    % --- Simular planta no lineal durante un periodo de muestreo ---
    [~, h_traj] = ode45(@(t,h) modelo_nolineal(t,h,u_actual,params), ...
                        [0 Ts], h_real);
    h_real = h_traj(end,:)';

    % --- Actualizar memoria ---
    e1_k1 = e1;
    e2_k1 = e2;
    u_prev = u_actual;

    H_log(:,k+1) = h_real;
end
U_log(:,end) = u_actual;

%% ========================================================================
%  5) METRICAS DE DESEMPENO (mismas del Cap. 3.2)
% ========================================================================
e_h3 = ref(1,:) - H_log(3,:);
e_h4 = ref(2,:) - H_log(4,:);

IAE  = sum(abs(e_h3) + abs(e_h4)) * Ts;
ISE  = sum(e_h3.^2 + e_h4.^2) * Ts;
ITAE = sum((abs(e_h3) + abs(e_h4)).*t_vec) * Ts;

% Tiempo de establecimiento al 2% (referido al cambio de setpoint)
k_chg = round(500/Ts);
band = 0.02 * 5;
ts3 = tiempo_estab(H_log(3,k_chg:end), ref(1,k_chg:end), band, t_vec(k_chg:end)) - 500;
ts4 = tiempo_estab(H_log(4,k_chg:end), ref(2,k_chg:end), band, t_vec(k_chg:end)) - 500;
t_est = max(ts3, ts4);

% Sobrepico
ov3 = max(H_log(3,k_chg:end)) - 30;       ov3 = max(ov3,0)/5*100;
ov4 = 20 - min(H_log(4,k_chg:end));       ov4 = max(ov4,0)/5*100;
overshoot = max(ov3, ov4);

esfuerzo = sum(sum(abs(diff(U_log,1,2))));

fprintf('=== Desempeno PI descentralizado (escenario cruzado) ===\n');
fprintf('  IAE       = %.2f\n', IAE);
fprintf('  ISE       = %.2f\n', ISE);
fprintf('  ITAE      = %.2f\n', ITAE);
fprintf('  t_est     = %.1f s\n', t_est);
fprintf('  Overshoot = %.2f %%\n', overshoot);
fprintf('  Esfuerzo  = %.2f\n\n', esfuerzo);

%% ========================================================================
%  6) GRAFICAS
% ========================================================================
figure('Name','PI descentralizado','NumberTitle','off')
subplot(2,1,1)
plot(t_vec, H_log(3,:), 'b', 'LineWidth', 1.5); hold on;
stairs(t_vec, ref(1,:), 'r--', 'LineWidth', 1.2);
ylabel('h_3 (cm)'); xlabel('Tiempo (s)');
legend('h_3 medido','Referencia','Location','best');
title('Tanque 3 (controlado por u_2 -- PI_2)'); grid on;

subplot(2,1,2)
plot(t_vec, H_log(4,:), 'b', 'LineWidth', 1.5); hold on;
stairs(t_vec, ref(2,:), 'r--', 'LineWidth', 1.2);
ylabel('h_4 (cm)'); xlabel('Tiempo (s)');
legend('h_4 medido','Referencia','Location','best');
title('Tanque 4 (controlado por u_1 -- PI_1)'); grid on;
sgtitle('Control PI descentralizado sobre planta no lineal');

figure('Name','PI - Senales de control','NumberTitle','off')
subplot(2,1,1)
stairs(t_vec, U_log(1,:), 'b', 'LineWidth', 1.5); hold on;
yline(u_max(1),'k--','LineWidth',1.0); yline(u_min(1),'k--','LineWidth',1.0);
ylabel('u_1'); xlabel('Tiempo (s)');
title('u_1 (PI_1 controla h_4)'); grid on;

subplot(2,1,2)
stairs(t_vec, U_log(2,:), 'r', 'LineWidth', 1.5); hold on;
yline(u_max(2),'k--','LineWidth',1.0); yline(u_min(2),'k--','LineWidth',1.0);
ylabel('u_2'); xlabel('Tiempo (s)');
title('u_2 (PI_2 controla h_3)'); grid on;

%% Guardar resultados para comparacion con GPC
save('resultados_PID.mat','t_vec','H_log','U_log','ref', ...
     'IAE','ISE','ITAE','t_est','overshoot','esfuerzo', ...
     'Kp1','Ti1','Kp2','Ti2','K1','K2','tau1','tau2','lam1','lam2');
fprintf('Resultados guardados en resultados_PID.mat\n');

%% ========================================================================
%  FUNCIONES AUXILIARES
% ========================================================================
function ts = tiempo_estab(y, r, band, t)
    err = abs(y - r);
    idx = find(err > band, 1, 'last');
    if isempty(idx), ts = t(1); else, ts = t(idx); end
end

function dhdt = modelo_nolineal(~, h, u, p)
    h1 = max(h(1),0); h2 = max(h(2),0);
    h3 = max(h(3),0); h4 = max(h(4),0);
    u1 = u(1); u2 = u(2);

    dhdt = [-p.a1/p.A1*sqrt(2*p.g*h1) + (1-p.y2)*p.k2*u2/p.A1;
            -p.a2/p.A2*sqrt(2*p.g*h2) + (1-p.y1)*p.k1*u1/p.A2;
            -p.a3/p.A3*sqrt(2*p.g*h3) + p.a2/p.A3*sqrt(2*p.g*h2) + p.y2*p.k2*u2/p.A3;
            -p.a4/p.A4*sqrt(2*p.g*h4) + p.a1/p.A4*sqrt(2*p.g*h1) + p.y1*p.k1*u1/p.A4];
end
