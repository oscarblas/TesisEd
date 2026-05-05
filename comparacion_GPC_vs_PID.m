%% ========================================================================
%  comparacion_GPC_vs_PID.m
%  Comparacion lado a lado: GPC multivariable vs PID descentralizado
%  Sistema de 4 tanques acoplados
%
%  REQUISITOS DE EJECUCION:
%   1. Ejecutar primero  controlador_PID.m   (genera resultados_PID.mat)
%   2. Ejecutar despues  este script         (corre el GPC y compara)
% ========================================================================

clear; clc; close all;

%% Cargar resultados del PID
if ~isfile('resultados_PID.mat')
    error('Falta resultados_PID.mat. Ejecuta primero controlador_PID.m');
end
PID = load('resultados_PID.mat');
fprintf('Resultados PID cargados.\n');

%% ========================================================================
%  Ejecutar GPC con misma configuracion (parametros optimos)
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

Ac = [-1/T1 0 0 0; 0 -1/T2 0 0;
       0 A2/(A3*T2) -1/T3 0; A1/(A4*T1) 0 0 -1/T4];
Bc = [0 (1-y2)*k2/A1; (1-y1)*k1/A2 0;
      0 y2*k2/A3; y1*k1/A4 0];
Cc = [0 0 1 0; 0 0 0 1]; Dc = zeros(2,2);

% Parametros optimos del GPC
Ts = 2; N = 50; Nu = 9;
delta  = [10 10];
lambda = [0.0076803 0.0076803];
alpha = 0.7;          % trayectoria de referencia (sin preview)

% Discretizacion
sys_d = c2d(ss(Ac,Bc,Cc,Dc), Ts, 'zoh');
[Ad, Bd, Cd, ~] = ssdata(sys_d);
nx = size(Ad,1); nu = size(Bd,2); ny = size(Cd,1);

% Modelo aumentado
A_t = [Ad zeros(nx,ny); Cd*Ad eye(ny)];
B_t = [Bd; Cd*Bd];
C_t = [zeros(ny,nx) eye(ny)];

% Matrices de prediccion
F   = zeros(N*ny, nx+ny);
Phi = zeros(N*ny, Nu*nu);
for j=1:N, F((j-1)*ny+1:j*ny,:) = C_t*A_t^j; end
for ii=1:N
    for jj=1:Nu
        if ii>=jj
            Phi((ii-1)*ny+1:ii*ny, (jj-1)*nu+1:jj*nu) = C_t*A_t^(ii-jj)*B_t;
        end
    end
end

Q = kron(eye(N), diag(delta));
R = kron(eye(Nu), diag(lambda));
H = 2*(Phi'*Q*Phi + R); H = (H+H')/2;

% Restricciones
Du_max=[100;100]; u_max=u0*2; u_min=[0;0];
T_mat = kron(tril(ones(Nu)), eye(nu));
ones_blk = repmat(eye(nu), Nu, 1);
A_ineq = [eye(Nu*nu); -eye(Nu*nu); T_mat; -T_mat];
Du_max_v = repmat(Du_max,Nu,1); Du_min_v = -Du_max_v;
u_max_v = repmat(u_max,Nu,1); u_min_v = repmat(u_min,Nu,1);

% Mismo escenario que el PID
t_sim = 1500; N_steps = round(t_sim/Ts);
t_vec = (0:N_steps-1)*Ts;
ref = zeros(2,N_steps);
ref(:,1:round(500/Ts))     = repmat([25;25],1,round(500/Ts));
ref(:,round(500/Ts)+1:end) = repmat([30;20],1,N_steps - round(500/Ts));

h_real = h0; u_prev = u0; x_lin_ant = zeros(nx,1);
H_log_GPC = zeros(4,N_steps); H_log_GPC(:,1) = h_real;
U_log_GPC = zeros(2,N_steps);

params = struct('A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
                'a1',a1,'a2',a2,'a3',a3,'a4',a4, ...
                'k1',k1,'k2',k2,'y1',y1,'y2',y2,'g',g);
opts = optimoptions('quadprog','Display','off');

fprintf('Ejecutando GPC...\n');
for k=1:N_steps-1
    x_lin = h_real - h0;
    Dx = x_lin - x_lin_ant;
    y_lin = Cd*x_lin;
    xi = [Dx; y_lin];

    y_act_dev = h_real(3:4) - [h30;h40];
    r_act_dev = ref(:,k) - [h30;h40];
    W = zeros(N*ny,1);
    for j=1:N
        w_j = alpha^j*y_act_dev + (1-alpha^j)*r_act_dev;
        W((j-1)*ny+1:j*ny) = w_j;
    end

    b_ineq = [Du_max_v; -Du_min_v;
              u_max_v - ones_blk*u_prev;
              -u_min_v + ones_blk*u_prev];

    f_qp = -2*(W - F*xi)'*Q*Phi; f_qp = f_qp(:);
    [DU,~,ef] = quadprog(H, f_qp, A_ineq, b_ineq, [],[],[],[],[],opts);
    if ef~=1, DU = zeros(Nu*nu,1); end

    u_act = u_prev + DU(1:nu);
    u_act = max(min(u_act,u_max),u_min);
    U_log_GPC(:,k) = u_act;

    [~, h_traj] = ode45(@(t,h) modelo_nl(t,h,u_act,params), [0 Ts], h_real);
    h_real = h_traj(end,:)';

    x_lin_ant = x_lin;
    u_prev = u_act;
    H_log_GPC(:,k+1) = h_real;
end
U_log_GPC(:,end) = u_prev;
fprintf('GPC OK\n\n');

%% Calcular metricas del GPC
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
%  TABLA COMPARATIVA
% ========================================================================
fprintf('=========================================================\n');
fprintf('       COMPARACION GPC vs PID DESCENTRALIZADO\n');
fprintf('=========================================================\n');
fprintf('Metrica         PID            GPC          Ganador\n');
fprintf('---------------------------------------------------------\n');
fprintf('IAE         %10.2f   %10.2f      %s\n', PID.IAE, GPC.IAE, ...
        ganador(PID.IAE, GPC.IAE));
fprintf('ISE         %10.2f   %10.2f      %s\n', PID.ISE, GPC.ISE, ...
        ganador(PID.ISE, GPC.ISE));
fprintf('ITAE        %10.2f   %10.2f      %s\n', PID.ITAE, GPC.ITAE, ...
        ganador(PID.ITAE, GPC.ITAE));
fprintf('t_est (s)   %10.2f   %10.2f      %s\n', PID.t_est, GPC.t_est, ...
        ganador(PID.t_est, GPC.t_est));
fprintf('Overshoot%% %10.2f   %10.2f      %s\n', PID.overshoot, GPC.overshoot, ...
        ganador(PID.overshoot, GPC.overshoot));
fprintf('Esfuerzo    %10.2f   %10.2f      %s\n', PID.esfuerzo, GPC.esfuerzo, ...
        ganador(PID.esfuerzo, GPC.esfuerzo));
fprintf('=========================================================\n\n');

%% ========================================================================
%  GRAFICAS COMPARATIVAS
% ========================================================================

% Salidas controladas
figure('Name','Comparacion GPC vs PID - Salidas','NumberTitle','off')
subplot(2,1,1)
plot(t_vec, H_log_GPC(3,:), 'b', 'LineWidth', 1.6); hold on;
plot(PID.t_vec, PID.H_log(3,:), 'g', 'LineWidth', 1.6);
stairs(t_vec, ref(1,:), 'k--', 'LineWidth', 1.2);
ylabel('h_3 (cm)'); xlabel('Tiempo (s)');
legend('GPC','PID','Referencia','Location','best');
title('Tanque 3 - Respuesta'); grid on;

subplot(2,1,2)
plot(t_vec, H_log_GPC(4,:), 'b', 'LineWidth', 1.6); hold on;
plot(PID.t_vec, PID.H_log(4,:), 'g', 'LineWidth', 1.6);
stairs(t_vec, ref(2,:), 'k--', 'LineWidth', 1.2);
ylabel('h_4 (cm)'); xlabel('Tiempo (s)');
legend('GPC','PID','Referencia','Location','best');
title('Tanque 4 - Respuesta'); grid on;
sgtitle('Comparacion GPC vs PID descentralizado');

% Senales de control
figure('Name','Comparacion GPC vs PID - Control','NumberTitle','off')
subplot(2,1,1)
stairs(t_vec, U_log_GPC(1,:), 'b', 'LineWidth', 1.4); hold on;
stairs(PID.t_vec, PID.U_log(1,:), 'g', 'LineWidth', 1.4);
ylabel('u_1'); xlabel('Tiempo (s)');
legend('GPC','PID','Location','best'); grid on;
title('Senal de control u_1');

subplot(2,1,2)
stairs(t_vec, U_log_GPC(2,:), 'b', 'LineWidth', 1.4); hold on;
stairs(PID.t_vec, PID.U_log(2,:), 'g', 'LineWidth', 1.4);
ylabel('u_2'); xlabel('Tiempo (s)');
legend('GPC','PID','Location','best'); grid on;
title('Senal de control u_2');

% Error en cada canal
figure('Name','Errores comparados','NumberTitle','off')
subplot(2,1,1)
plot(t_vec, ref(1,:) - H_log_GPC(3,:), 'b', 'LineWidth', 1.4); hold on;
plot(PID.t_vec, PID.ref(1,:) - PID.H_log(3,:), 'g', 'LineWidth', 1.4);
ylabel('e_{h_3} (cm)'); xlabel('Tiempo (s)');
legend('GPC','PID','Location','best'); grid on;
title('Error de seguimiento en h_3');
yline(0,'k:');

subplot(2,1,2)
plot(t_vec, ref(2,:) - H_log_GPC(4,:), 'b', 'LineWidth', 1.4); hold on;
plot(PID.t_vec, PID.ref(2,:) - PID.H_log(4,:), 'g', 'LineWidth', 1.4);
ylabel('e_{h_4} (cm)'); xlabel('Tiempo (s)');
legend('GPC','PID','Location','best'); grid on;
title('Error de seguimiento en h_4');
yline(0,'k:');

% Barras de metricas
figure('Name','Resumen de metricas','NumberTitle','off')
metricas = {'IAE','ISE','ITAE/1000','t_{est}','Overshoot %','Esfuerzo'};
val_PID = [PID.IAE, PID.ISE, PID.ITAE/1000, PID.t_est, PID.overshoot, PID.esfuerzo];
val_GPC = [GPC.IAE, GPC.ISE, GPC.ITAE/1000, GPC.t_est, GPC.overshoot, GPC.esfuerzo];
bar([val_PID; val_GPC]');
set(gca,'XTickLabel',metricas);
legend('PID','GPC','Location','best');
ylabel('Valor (menor = mejor)'); grid on;
title('Comparacion de metricas (escalado)');

%% ====================== Funciones auxiliares ============================

function s = ganador(pid_v, gpc_v)
    if abs(pid_v - gpc_v) < 1e-6
        s = 'EMPATE';
    elseif pid_v < gpc_v
        s = 'PID';
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
