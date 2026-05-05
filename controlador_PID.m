%% ========================================================================
%  controlador_PID.m
%  Control PID descentralizado (multilazo) para el sistema de 4 tanques
%
%  ESTRATEGIA DE EMPAREJAMIENTO (pairing):
%  En el sistema de 4 tanques, cada entrada tiene un efecto DIRECTO sobre
%  un tanque inferior y un efecto INDIRECTO (cruzado) sobre el otro:
%
%      u1 -> h4  (directo, ganancia y1*k1/A4)
%      u1 -> h2 -> h3  (cruzado, lento)
%      u2 -> h3  (directo, ganancia y2*k2/A3)
%      u2 -> h1 -> h4  (cruzado, lento)
%
%  Por eso emparejamos:
%      PID1:  u1  controla  h4
%      PID2:  u2  controla  h3
%
%  Esta estrategia se llama "control descentralizado" o "multi-loop".
%  IGNORA el acoplamiento cruzado, lo cual es la principal limitacion
%  frente al GPC multivariable.
% ========================================================================

clear; clc; close all;

%% ========================================================================
%  PARAMETROS DE LA PLANTA (mismos que GPC)
% ========================================================================
A1=706.85; A2=706.85; A3=706.85; A4=706.85;
a1=1.89;   a2=1.89;   a3=5.39;   a4=5.39;
k1=1; k2=1; y1=0.7; y2=0.7; g=981;

% Punto de operacion
h30=25; h40=25;
M_A = [(1-y1)*k1 y2*k2; y1*k1 (1-y2)*k2];
M_B = [a3*sqrt(2*g*h30); a4*sqrt(2*g*h40)];
u0  = M_A\M_B; u10=u0(1); u20=u0(2);
h10 = ((1-y2)*k2*u20/a1)^2/(2*g);
h20 = ((1-y1)*k1*u10/a2)^2/(2*g);
h0  = [h10; h20; h30; h40];

% Constantes de tiempo (para sintonizacion IMC)
T1=A1/a1*sqrt(2*h10/g);
T2=A2/a2*sqrt(2*h20/g);
T3=A3/a3*sqrt(2*h30/g);
T4=A4/a4*sqrt(2*h40/g);

%% ========================================================================
%  SINTONIZACION IMC (Internal Model Control)
%  ------------------------------------------------------------------------
%  Para el lazo u1 -> h4 (con u2 fijo en u20):
%     dh4/dt = -h4/T4 + (A1/(A4*T1))*h1 + (y1*k1/A4)*u1
%  Despues del transitorio de h1, queda una FOPDT aproximada:
%     G(s) = K / (tau*s + 1)
%  con K = y1*k1*T4/A4  y tau = T4
%
%  Reglas IMC para PI:
%     Kp = tau / (K * lambda_imc)
%     Ti = tau
%
%  lambda_imc = constante de tiempo deseada en lazo cerrado.
%  Mas pequeno => mas rapido pero menos robusto.
%  Tipico: lambda_imc = tau/3 (agresivo) hasta lambda_imc = 2*tau (suave).
% ========================================================================

% Lazo 1: u1 -> h4
K1   = y1*k1*T4/A4;          % ganancia estatica del lazo
tau1 = T4;                    % constante de tiempo
lam1 = tau1/3;                % CL deseado (agresivo)
Kp1  = tau1/(K1*lam1);
Ti1  = tau1;

% Lazo 2: u2 -> h3
K2   = y2*k2*T3/A3;
tau2 = T3;
lam2 = tau2/3;
Kp2  = tau2/(K2*lam2);
Ti2  = tau2;

% PID -> usamos PI (Td=0). El derivativo amplifica ruido y el sistema
% es de primer orden dominante, asi que PI es suficiente.
Td1 = 0;
Td2 = 0;

fprintf('=== Sintonizacion IMC ===\n');
fprintf('  Lazo 1 (u1 -> h4): Kp = %.3f  Ti = %.2f s\n', Kp1, Ti1);
fprintf('  Lazo 2 (u2 -> h3): Kp = %.3f  Ti = %.2f s\n\n', Kp2, Ti2);

%% ========================================================================
%  PARAMETROS DE SIMULACION
% ========================================================================
Ts = 2;                          % mismo Ts que el GPC para comparacion justa
t_sim = 1500;
N_steps = round(t_sim/Ts);
t_vec = (0:N_steps-1)*Ts;

% Setpoint (mismo escenario que el GPC)
ref = zeros(2, N_steps);
ref(:,1:round(500/Ts))     = repmat([25; 25], 1, round(500/Ts));
ref(:,round(500/Ts)+1:end) = repmat([30; 20], 1, N_steps - round(500/Ts));

% Limites fisicos (mismos que GPC)
u_max = [u10*2; u20*2];
u_min = [0; 0];

%% ========================================================================
%  IMPLEMENTACION PID DISCRETO CON ANTI-WINDUP
%  ------------------------------------------------------------------------
%  Forma de velocidad (recomendada para evitar saltos al cambiar SP):
%
%      Du(k) = Kp*(e(k)-e(k-1)) + (Kp*Ts/Ti)*e(k) + (Kp*Td/Ts)*(e(k)-2*e(k-1)+e(k-2))
%      u(k) = u(k-1) + Du(k)
%
%  Anti-windup: si u satura, no acumular el termino integral (back-calculation).
% ========================================================================

% Inicializacion
h_real = h0;
u_actual = [u10; u20];
u_prev   = u_actual;

% Memoria de errores para forma incremental
e1_k1=0; e1_k2=0; e2_k1=0; e2_k2=0;

% Historial
H_log = zeros(4, N_steps); H_log(:,1) = h_real;
U_log = zeros(2, N_steps);

params = struct('A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
                'a1',a1,'a2',a2,'a3',a3,'a4',a4, ...
                'k1',k1,'k2',k2,'y1',y1,'y2',y2,'g',g);

for k = 1:N_steps-1
    % --- Errores actuales ---
    e1 = ref(2,k) - h_real(4);   % PID1: error en h4 (ref(2) = ref de h4)
    e2 = ref(1,k) - h_real(3);   % PID2: error en h3 (ref(1) = ref de h3)

    % --- PID forma incremental ---
    Du1 = Kp1*(e1 - e1_k1) + (Kp1*Ts/Ti1)*e1 + (Kp1*Td1/Ts)*(e1 - 2*e1_k1 + e1_k2);
    Du2 = Kp2*(e2 - e2_k1) + (Kp2*Ts/Ti2)*e2 + (Kp2*Td2/Ts)*(e2 - 2*e2_k1 + e2_k2);

    u_actual(1) = u_prev(1) + Du1;
    u_actual(2) = u_prev(2) + Du2;

    % --- Anti-windup por saturacion ---
    u_actual = max(min(u_actual, u_max), u_min);

    U_log(:,k) = u_actual;

    % --- Simular planta no lineal un paso de Ts ---
    [~, h_traj] = ode45(@(t,h) modelo_nl(t,h,u_actual,params), [0 Ts], h_real);
    h_real = h_traj(end,:)';

    % --- Actualizar memoria ---
    e1_k2 = e1_k1; e1_k1 = e1;
    e2_k2 = e2_k1; e2_k1 = e2;
    u_prev = u_actual;

    H_log(:,k+1) = h_real;
end
U_log(:,end) = u_actual;

%% ========================================================================
%  METRICAS DE DESEMPENO
% ========================================================================
e_h3 = ref(1,:) - H_log(3,:);
e_h4 = ref(2,:) - H_log(4,:);

IAE  = sum(abs(e_h3) + abs(e_h4))*Ts;
ISE  = sum(e_h3.^2 + e_h4.^2)*Ts;
ITAE = sum((abs(e_h3) + abs(e_h4)).*t_vec)*Ts;

% Tiempo de establecimiento al 2%
k_chg = round(500/Ts);
band = 0.02 * max(abs([5;-5]));
ts3 = tiempo_estab(H_log(3,k_chg:end), ref(1,k_chg:end), band, t_vec(k_chg:end)) - 500;
ts4 = tiempo_estab(H_log(4,k_chg:end), ref(2,k_chg:end), band, t_vec(k_chg:end)) - 500;
t_est = max(ts3, ts4);

% Sobreoscilacion
ov3 = max(H_log(3,k_chg:end)) - 30; ov3 = max(ov3,0)/5*100;
ov4 = 20 - min(H_log(4,k_chg:end)); ov4 = max(ov4,0)/5*100;
overshoot = max(ov3, ov4);

esfuerzo = sum(sum(abs(diff(U_log,1,2))));

fprintf('=== Desempeno PID descentralizado ===\n');
fprintf('  IAE       = %.2f\n', IAE);
fprintf('  ISE       = %.2f\n', ISE);
fprintf('  ITAE      = %.2f\n', ITAE);
fprintf('  t_est     = %.1f s\n', t_est);
fprintf('  Overshoot = %.2f %%\n', overshoot);
fprintf('  Esfuerzo  = %.2f\n\n', esfuerzo);

%% ========================================================================
%  GRAFICAS
% ========================================================================
figure('Name','PID descentralizado','NumberTitle','off')
subplot(2,1,1)
plot(t_vec, H_log(3,:), 'b', 'LineWidth', 1.5); hold on;
stairs(t_vec, ref(1,:), 'r--', 'LineWidth', 1.2);
ylabel('h_3 (cm)'); xlabel('Tiempo (s)');
legend('h_3 medido','Referencia','Location','best');
title('Tanque 3 (controlado por u_2)'); grid on;

subplot(2,1,2)
plot(t_vec, H_log(4,:), 'b', 'LineWidth', 1.5); hold on;
stairs(t_vec, ref(2,:), 'r--', 'LineWidth', 1.2);
ylabel('h_4 (cm)'); xlabel('Tiempo (s)');
legend('h_4 medido','Referencia','Location','best');
title('Tanque 4 (controlado por u_1)'); grid on;
sgtitle('Control PID descentralizado sobre planta no lineal');

figure('Name','PID - Senales de control','NumberTitle','off')
subplot(2,1,1)
stairs(t_vec, U_log(1,:), 'b', 'LineWidth', 1.5); hold on;
yline(u_max(1),'k--'); yline(u_min(1),'k--');
ylabel('u_1'); xlabel('Tiempo (s)');
title('u_1 (PID con h_4)'); grid on;

subplot(2,1,2)
stairs(t_vec, U_log(2,:), 'r', 'LineWidth', 1.5); hold on;
yline(u_max(2),'k--'); yline(u_min(2),'k--');
ylabel('u_2'); xlabel('Tiempo (s)');
title('u_2 (PID con h_3)'); grid on;

%% Guardar resultados para comparacion con GPC
save('resultados_PID.mat','t_vec','H_log','U_log','ref', ...
     'IAE','ISE','ITAE','t_est','overshoot','esfuerzo','Kp1','Ti1','Kp2','Ti2');
fprintf('Resultados guardados en resultados_PID.mat\n');

%% ====================== Funciones auxiliares ============================

function ts = tiempo_estab(y, r, band, t)
    err = abs(y - r);
    idx = find(err > band, 1, 'last');
    if isempty(idx), ts = t(1); else, ts = t(idx); end
end

function dhdt = modelo_nl(~, h, u, p)
    h1=max(h(1),0); h2=max(h(2),0); h3=max(h(3),0); h4=max(h(4),0);
    u1=u(1); u2=u(2);
    dhdt = [-p.a1/p.A1*sqrt(2*p.g*h1) + (1-p.y2)*p.k2*u2/p.A1;
            -p.a2/p.A2*sqrt(2*p.g*h2) + (1-p.y1)*p.k1*u1/p.A2;
            -p.a3/p.A3*sqrt(2*p.g*h3) + p.a2/p.A3*sqrt(2*p.g*h2) + p.y2*p.k2*u2/p.A3;
            -p.a4/p.A4*sqrt(2*p.g*h4) + p.a1/p.A4*sqrt(2*p.g*h1) + p.y1*p.k1*u1/p.A4];
end
