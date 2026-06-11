%% ========================================================================
%  comparacion_GPC_vs_PID.m
%  Comparacion 1 a 1 entre el controlador GPC (Cap. 3) y el PI
%  descentralizado (Cap. 4.2) en el escenario de referencias cruzadas.
%
%  REQUISITOS PREVIOS:
%    1. Ejecutar primero  controlador_PID.m   -> genera resultados_PID.mat
%    2. Ejecutar despues  este script          -> corre el GPC y compara
%
%  Para una comparacion completa sobre los 6 escenarios del Cap. 4,
%  usar el script  simulaciones_cap4.m  en su lugar. Este archivo sirve
%  como referencia rapida del caso de referencias cruzadas.
% ========================================================================

clear; clc; close all;

%% Cargar resultados del PID
if ~isfile('resultados_PID.mat')
    error('Falta resultados_PID.mat. Ejecuta primero controlador_PID.m');
end
PID = load('resultados_PID.mat');
fprintf('Resultados PID cargados.\n');

%% ========================================================================
%  Parametros de la planta (mismos del Cap. 2)
% ========================================================================
A1=706.85; A2=706.85; A3=706.85; A4=706.85;
a1=1.89;   a2=1.89;   a3=5.39;   a4=5.39;
k1=1; k2=1; y1=0.7; y2=0.7; g=981;

h30=25; h40=25;
M_A = [(1-y1)*k1 y2*k2; y1*k1 (1-y2)*k2];
M_B = [a3*sqrt(2*g*h30); a4*sqrt(2*g*h40)];
u0  = M_A\M_B; u10=u0(1); u20=u0(2);
h10 = ((1-y2)*k2*u20/a1)^2/(2*g);
h20 = ((1-y1)*k1*u10/a2)^2/(2*g);
h0  = [h10; h20; h30; h40];

T1=A1/a1*sqrt(2*h10/g); T2=A2/a2*sqrt(2*h20/g);
T3=A3/a3*sqrt(2*h30/g); T4=A4/a4*sqrt(2*h40/g);

% Modelo lineal continuo (para el GPC)
Ac = [-1/T1 0 0 0; 0 -1/T2 0 0;
       0 A2/(A3*T2) -1/T3 0; A1/(A4*T1) 0 0 -1/T4];
Bc = [0 (1-y2)*k2/A1; (1-y1)*k1/A2 0;
      0 y2*k2/A3; y1*k1/A4 0];
Cc = [0 0 1 0; 0 0 0 1];
Dc = zeros(2,2);

%% ========================================================================
%  Parametros del GPC (sintonizacion ganadora del analisis comparativo)
% ========================================================================
Ts = 2; N = 50; Nu = 9;
delta  = [10 10];
lambda = [0.0076803 0.0076803];

%% ========================================================================
%  Discretizacion y construccion de la matriz dinamica G (formulacion GPC)
% ========================================================================
sys_d = c2d(ss(Ac,Bc,Cc,Dc), Ts, 'zoh');
[Ad, Bd, Cd, ~] = ssdata(sys_d);
nu = size(Bd,2); ny = size(Cd,1);

G_z = tf(sys_d);
t_step = (0:N)*Ts;
g_step = cell(ny, nu);
for i = 1:ny
    for j = 1:nu
        y_step_ij = step(G_z(i,j), t_step);
        g_step{i,j} = y_step_ij(2:end);
    end
end

G = zeros(ny*N, nu*Nu);
for i = 1:ny
    for j = 1:nu
        G_block = zeros(N, Nu);
        for r = 1:N
            for c = 1:Nu
                if r >= c
                    G_block(r,c) = g_step{i,j}(r-c+1);
                end
            end
        end
        G((i-1)*N + (1:N), (j-1)*Nu + (1:Nu)) = G_block;
    end
end

% Pesos y Hessiano
Q = blkdiag(delta(1)*eye(N),  delta(2)*eye(N));
R = blkdiag(lambda(1)*eye(Nu), lambda(2)*eye(Nu));
H_qp = 2*(G'*Q*G + R); H_qp = (H_qp+H_qp')/2;

% Restricciones
Du_max=[100;100]; u_max=u0*2; u_min=[0;0];
Du_min = -Du_max;

Du_max_vec = [repmat(Du_max(1),Nu,1); repmat(Du_max(2),Nu,1)];
Du_min_vec = [repmat(Du_min(1),Nu,1); repmat(Du_min(2),Nu,1)];
u_max_vec  = [repmat(u_max(1),Nu,1);  repmat(u_max(2),Nu,1)];
u_min_vec  = [repmat(u_min(1),Nu,1);  repmat(u_min(2),Nu,1)];

T_mat = blkdiag(tril(ones(Nu)), tril(ones(Nu)));
A_ineq = [eye(nu*Nu); -eye(nu*Nu); T_mat; -T_mat];

%% ========================================================================
%  Escenario de prueba: referencias cruzadas (mismo del PID)
% ========================================================================
t_sim = 1500; N_steps = round(t_sim/Ts);
t_vec = (0:N_steps-1)*Ts;
ref = zeros(2,N_steps);
ref(:,1:round(500/Ts))     = repmat([25;25],1,round(500/Ts));
ref(:,round(500/Ts)+1:end) = repmat([30;20],1,N_steps - round(500/Ts));

h_real = h0; u_prev = u0;
H_log_GPC = zeros(4,N_steps); H_log_GPC(:,1) = h_real;
U_log_GPC = zeros(2,N_steps);

params = struct('A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
                'a1',a1,'a2',a2,'a3',a3,'a4',a4, ...
                'k1',k1,'k2',k2,'y1',y1,'y2',y2,'g',g);
opts = optimoptions('quadprog','Display','off');

fprintf('Ejecutando GPC...\n');
for k = 1:N_steps-1
    x_des = h_real - h0;
    u_prev_des = u_prev - u0;

    % Respuesta libre F (modelo con Du=0)
    F_vec = zeros(ny*N, 1);
    x_temp = x_des;
    for j = 1:N
        x_temp = Ad*x_temp + Bd*u_prev_des;
        y_pred = Cd*x_temp;
        F_vec(j)     = y_pred(1);
        F_vec(N + j) = y_pred(2);
    end

    % Referencia futura constante
    r_des = ref(:,k) - [h30;h40];
    W = [repmat(r_des(1),N,1); repmat(r_des(2),N,1)];

    % QP
    f_qp = 2*G'*Q*(F_vec - W);
    u_prev_stack = [repmat(u_prev(1),Nu,1); repmat(u_prev(2),Nu,1)];
    b_ineq = [Du_max_vec; -Du_min_vec;
              u_max_vec - u_prev_stack;
             -u_min_vec + u_prev_stack];

    [DU,~,ef] = quadprog(H_qp, f_qp, A_ineq, b_ineq, [],[],[],[],[],opts);
    if ef<=0 || isempty(DU), DU = zeros(nu*Nu,1); end

    % Primer incremento de cada canal
    Du_aplicado = [DU(1); DU(Nu+1)];
    u_act = u_prev + Du_aplicado;
    u_act = max(min(u_act,u_max),u_min);
    U_log_GPC(:,k) = u_act;

    [~, h_traj] = ode45(@(t,h) modelo_nl(t,h,u_act,params), [0 Ts], h_real);
    h_real = h_traj(end,:)';

    u_prev = u_act;
    H_log_GPC(:,k+1) = h_real;
end
U_log_GPC(:,end) = u_prev;
fprintf('GPC OK\n\n');

%% ========================================================================
%  Calcular metricas del GPC
% ========================================================================
e_h3 = ref(1,:) - H_log_GPC(3,:);
e_h4 = ref(2,:) - H_log_GPC(4,:);

GPC.IAE  = sum(abs(e_h3)+abs(e_h4))*Ts;
GPC.ISE  = sum(e_h3.^2 + e_h4.^2)*Ts;
GPC.ITAE = sum((abs(e_h3)+abs(e_h4)).*t_vec)*Ts;

k_chg = round(500/Ts);
band = 0.02*5;
GPC.t_est = max(...
    tiempo_estab(H_log_GPC(3,k_chg:end), ref(1,k_chg:end), band, t_vec(k_chg:end)) - 500, ...
    tiempo_estab(H_log_GPC(4,k_chg:end), ref(2,k_chg:end), band, t_vec(k_chg:end)) - 500);

ov3 = max(H_log_GPC(3,k_chg:end)) - 30; ov3 = max(ov3,0)/5*100;
ov4 = 20 - min(H_log_GPC(4,k_chg:end)); ov4 = max(ov4,0)/5*100;
GPC.overshoot = max(ov3,ov4);
GPC.esfuerzo = sum(sum(abs(diff(U_log_GPC,1,2))));

%% ========================================================================
%  Tabla comparativa
% ========================================================================
fprintf('=========================================================\n');
fprintf('       COMPARACION GPC vs PI DESCENTRALIZADO\n');
fprintf('       (Escenario: referencias cruzadas)\n');
fprintf('=========================================================\n');
fprintf('Metrica         PI             GPC          Ganador\n');
fprintf('---------------------------------------------------------\n');
fprintf('IAE         %10.2f   %10.2f      %s\n', PID.IAE, GPC.IAE, ganador(PID.IAE, GPC.IAE));
fprintf('ISE         %10.2f   %10.2f      %s\n', PID.ISE, GPC.ISE, ganador(PID.ISE, GPC.ISE));
fprintf('ITAE        %10.2f   %10.2f      %s\n', PID.ITAE, GPC.ITAE, ganador(PID.ITAE, GPC.ITAE));
fprintf('t_est (s)   %10.2f   %10.2f      %s\n', PID.t_est, GPC.t_est, ganador(PID.t_est, GPC.t_est));
fprintf('Overshoot%% %10.2f   %10.2f      %s\n', PID.overshoot, GPC.overshoot, ganador(PID.overshoot, GPC.overshoot));
fprintf('Esfuerzo    %10.2f   %10.2f      %s\n', PID.esfuerzo, GPC.esfuerzo, ganador(PID.esfuerzo, GPC.esfuerzo));
fprintf('=========================================================\n\n');

%% ========================================================================
%  Graficas comparativas
% ========================================================================

% Salidas
figure('Name','Comparacion GPC vs PI - Salidas','NumberTitle','off')
subplot(2,1,1)
plot(t_vec, H_log_GPC(3,:), 'b', 'LineWidth', 1.6); hold on;
plot(PID.t_vec, PID.H_log(3,:), 'g', 'LineWidth', 1.6);
stairs(t_vec, ref(1,:), 'k--', 'LineWidth', 1.2);
ylabel('h_3 (cm)'); xlabel('Tiempo (s)');
legend('GPC','PI','Referencia','Location','best');
title('Tanque 3 - Respuesta'); grid on;

subplot(2,1,2)
plot(t_vec, H_log_GPC(4,:), 'b', 'LineWidth', 1.6); hold on;
plot(PID.t_vec, PID.H_log(4,:), 'g', 'LineWidth', 1.6);
stairs(t_vec, ref(2,:), 'k--', 'LineWidth', 1.2);
ylabel('h_4 (cm)'); xlabel('Tiempo (s)');
legend('GPC','PI','Referencia','Location','best');
title('Tanque 4 - Respuesta'); grid on;
sgtitle('Comparacion GPC vs PI descentralizado');

% Senales de control
figure('Name','Comparacion GPC vs PI - Control','NumberTitle','off')
subplot(2,1,1)
stairs(t_vec, U_log_GPC(1,:), 'b', 'LineWidth', 1.4); hold on;
stairs(PID.t_vec, PID.U_log(1,:), 'g', 'LineWidth', 1.4);
ylabel('u_1'); xlabel('Tiempo (s)');
legend('GPC','PI','Location','best'); grid on;
title('Senal de control u_1');

subplot(2,1,2)
stairs(t_vec, U_log_GPC(2,:), 'b', 'LineWidth', 1.4); hold on;
stairs(PID.t_vec, PID.U_log(2,:), 'g', 'LineWidth', 1.4);
ylabel('u_2'); xlabel('Tiempo (s)');
legend('GPC','PI','Location','best'); grid on;
title('Senal de control u_2');

% Errores
figure('Name','Errores comparados','NumberTitle','off')
subplot(2,1,1)
plot(t_vec, ref(1,:) - H_log_GPC(3,:), 'b', 'LineWidth', 1.4); hold on;
plot(PID.t_vec, PID.ref(1,:) - PID.H_log(3,:), 'g', 'LineWidth', 1.4);
ylabel('e_{h_3} (cm)'); xlabel('Tiempo (s)');
legend('GPC','PI','Location','best'); grid on;
yline(0,'k:');
title('Error de seguimiento en h_3');

subplot(2,1,2)
plot(t_vec, ref(2,:) - H_log_GPC(4,:), 'b', 'LineWidth', 1.4); hold on;
plot(PID.t_vec, PID.ref(2,:) - PID.H_log(4,:), 'g', 'LineWidth', 1.4);
ylabel('e_{h_4} (cm)'); xlabel('Tiempo (s)');
legend('GPC','PI','Location','best'); grid on;
yline(0,'k:');
title('Error de seguimiento en h_4');

% Barras de metricas
figure('Name','Resumen de metricas','NumberTitle','off')
metricas = {'IAE','ISE','ITAE/1000','t_{est}','Overshoot %','Esfuerzo'};
val_PID = [PID.IAE, PID.ISE, PID.ITAE/1000, PID.t_est, PID.overshoot, PID.esfuerzo];
val_GPC = [GPC.IAE, GPC.ISE, GPC.ITAE/1000, GPC.t_est, GPC.overshoot, GPC.esfuerzo];
bar([val_PID; val_GPC]');
set(gca,'XTickLabel',metricas);
legend('PI','GPC','Location','best');
ylabel('Valor (menor = mejor)'); grid on;
title('Comparacion de metricas (escenario referencias cruzadas)');

%% ====================== Funciones auxiliares ============================
function s = ganador(pid_v, gpc_v)
    if abs(pid_v - gpc_v) < 1e-6
        s = 'EMPATE';
    elseif pid_v < gpc_v
        s = 'PI';
    else
        s = 'GPC';
    end
end

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
