%% ========================================================================
%  comparacion_GPC_vs_PID.m
%  Comparacion del controlador GPC (Cap. 3) frente al PI descentralizado
%  CON DESACOPLADOR ESTATICO (Cap. 4.2) sobre la planta NO LINEAL.
%
%  Escenario disenado para evidenciar el comportamiento ante acoplamiento
%  y ante ruido (todo se simula sobre la planta no lineal real):
%    t = 0..400 : arranque desde h = 0 hasta el estacionario (h3=h4=25)
%    t = 400    : SP h3 cambia de 25 a 30  (se vera el efecto sobre h4)
%    t = 800    : SP h4 cambia de 25 a 20  (se vera el efecto sobre h3)
%    t = 1100   : se inyecta ruido gaussiano en las mediciones
%    t = 1500   : fin
%
%  Genera una grafica comparativa con ambas respuestas (GPC y PI+desa-
%  coplador) en cada salida controlada para visualizar inmediatamente
%  cual maneja mejor el acoplamiento y el ruido.
% ========================================================================

clear; clc; close all;

%% ========================================================================
%  1) PLANTA y modelo lineal continuo
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

u_max = [u10*2; u20*2]; u_min = [0;0];

params = struct('A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
                'a1',a1,'a2',a2,'a3',a3,'a4',a4, ...
                'k1',k1,'k2',k2,'y1',y1,'y2',y2,'g',g);

%% ========================================================================
%  2) ESCENARIO COMUN
% ========================================================================
Ts = 2;
t_sim = 1500; N_steps = round(t_sim/Ts);
t_vec = (0:N_steps-1)*Ts;

ref = zeros(2, N_steps);
ref(1,:) = 25; ref(2,:) = 25;
ref(1, t_vec>=400) = 30;
ref(2, t_vec>=800) = 20;

t_ruido = 1100;
sigma_ruido = 0.3;

%% ========================================================================
%  3) SIMULACION DEL PI + DESACOPLADOR
% ========================================================================
% Sintonizacion IMC
K1=y1*k1*T4/A4; tau1=T4; lam1=tau1/3; Kp1=tau1/(K1*lam1); Ti1=tau1;
K2=y2*k2*T3/A3; tau2=T3; lam2=tau2/3; Kp2=tau2/(K2*lam2); Ti2=tau2;

% Desacoplador estatico (matriz Skogestad)
G_dc = -Cc*(Ac\Bc);
G_pair = [G_dc(2,1) G_dc(2,2);    % h4 con (u1,u2)
          G_dc(1,1) G_dc(1,2)];   % h3 con (u1,u2)
k12 = G_pair(1,2)/G_pair(1,1);
k21 = G_pair(2,1)/G_pair(2,2);
D = [1 -k12; -k21 1];

fprintf('=== Desacoplador estatico ===\n');
fprintf('  k12 = %.4f,  k21 = %.4f\n\n', k12, k21);

fprintf('Ejecutando PI + desacoplador...\n');
h_real = [0;0;0;0]; u_prev = [0;0];
e1_k1=0; e2_k1=0;
H_pid = zeros(4,N_steps); H_pid(:,1) = h_real;
U_pid = zeros(2,N_steps);
rng(1);

for k = 1:N_steps-1
    if t_vec(k) >= t_ruido
        y_med = h_real + [0;0; sigma_ruido*randn; sigma_ruido*randn];
    else
        y_med = h_real;
    end
    e1 = ref(2,k) - y_med(4);
    e2 = ref(1,k) - y_med(3);
    Dv1 = Kp1*(e1-e1_k1) + (Kp1*Ts/Ti1)*e1;
    Dv2 = Kp2*(e2-e2_k1) + (Kp2*Ts/Ti2)*e2;
    Du = D * [Dv1; Dv2];
    u_act = u_prev + Du;
    u_act = max(min(u_act,u_max),u_min);
    U_pid(:,k) = u_act;
    [~, h_traj] = ode45(@(t,h) modelo_nl(t,h,u_act,params), [0 Ts], h_real);
    h_real = h_traj(end,:)';
    e1_k1=e1; e2_k1=e2; u_prev=u_act;
    H_pid(:,k+1) = h_real;
end
U_pid(:,end) = u_prev;
fprintf('PI + desacoplador OK\n');

%% ========================================================================
%  4) SIMULACION DEL GPC
% ========================================================================
N = 50; Nu = 9;
delta  = [10 10];
lambda = [0.0076803 0.0076803];

sys_d = c2d(ss(Ac,Bc,Cc,Dc), Ts, 'zoh');
[Ad, Bd, Cd, ~] = ssdata(sys_d);
nu = size(Bd,2); ny = size(Cd,1);

% Matriz dinamica G a partir de los coeficientes de respuesta al escalon
G_z = tf(sys_d);
t_step = (0:N)*Ts;
g_step = cell(ny,nu);
for i=1:ny
    for j=1:nu
        ys = step(G_z(i,j), t_step);
        g_step{i,j} = ys(2:end);
    end
end
G = zeros(ny*N, nu*Nu);
for i=1:ny
    for j=1:nu
        Gb = zeros(N,Nu);
        for r=1:N
            for c=1:Nu
                if r>=c, Gb(r,c) = g_step{i,j}(r-c+1); end
            end
        end
        G((i-1)*N+(1:N), (j-1)*Nu+(1:Nu)) = Gb;
    end
end
Q = blkdiag(delta(1)*eye(N), delta(2)*eye(N));
R = blkdiag(lambda(1)*eye(Nu), lambda(2)*eye(Nu));
H_qp = 2*(G'*Q*G + R); H_qp = (H_qp+H_qp')/2;

Du_max=[100;100]; Du_min=-Du_max;
Du_max_v=[repmat(Du_max(1),Nu,1);repmat(Du_max(2),Nu,1)];
Du_min_v=[repmat(Du_min(1),Nu,1);repmat(Du_min(2),Nu,1)];
u_max_v =[repmat(u_max(1),Nu,1); repmat(u_max(2),Nu,1)];
u_min_v =[repmat(u_min(1),Nu,1); repmat(u_min(2),Nu,1)];
T_mat = blkdiag(tril(ones(Nu)), tril(ones(Nu)));
A_ineq = [eye(nu*Nu); -eye(nu*Nu); T_mat; -T_mat];

fprintf('Ejecutando GPC...\n');
h_real = [0;0;0;0]; u_prev = [0;0];
H_gpc = zeros(4,N_steps); H_gpc(:,1) = h_real;
U_gpc = zeros(2,N_steps);
opts = optimoptions('quadprog','Display','off');
rng(1);

for k = 1:N_steps-1
    if t_vec(k) >= t_ruido
        y_med = h_real + [0;0; sigma_ruido*randn; sigma_ruido*randn];
    else
        y_med = h_real;
    end
    x_des = y_med - h0;
    u_prev_des = u_prev - u0;

    F_vec = zeros(ny*N,1);
    x_temp = x_des;
    for j=1:N
        x_temp = Ad*x_temp + Bd*u_prev_des;
        y_pred = Cd*x_temp;
        F_vec(j)     = y_pred(1);
        F_vec(N + j) = y_pred(2);
    end
    r_des = ref(:,k) - [h30;h40];
    W = [repmat(r_des(1),N,1); repmat(r_des(2),N,1)];
    f_qp = 2*G'*Q*(F_vec - W);
    u_prev_stack = [repmat(u_prev(1),Nu,1); repmat(u_prev(2),Nu,1)];
    b_ineq = [Du_max_v; -Du_min_v; u_max_v - u_prev_stack; -u_min_v + u_prev_stack];
    [DU,~,ef] = quadprog(H_qp, f_qp, A_ineq, b_ineq, [],[],[],[],[],opts);
    if ef<=0 || isempty(DU), DU = zeros(nu*Nu,1); end

    Du_aplicado = [DU(1); DU(Nu+1)];
    u_act = u_prev + Du_aplicado;
    u_act = max(min(u_act, u_max), u_min);
    U_gpc(:,k) = u_act;
    [~, h_traj] = ode45(@(t,h) modelo_nl(t,h,u_act,params), [0 Ts], h_real);
    h_real = h_traj(end,:)';
    u_prev = u_act;
    H_gpc(:,k+1) = h_real;
end
U_gpc(:,end) = u_prev;
fprintf('GPC OK\n\n');

%% ========================================================================
%  5) METRICAS COMPARATIVAS
% ========================================================================
e3_gpc = ref(1,:)-H_gpc(3,:); e4_gpc = ref(2,:)-H_gpc(4,:);
e3_pid = ref(1,:)-H_pid(3,:); e4_pid = ref(2,:)-H_pid(4,:);

GPC.IAE = sum(abs(e3_gpc)+abs(e4_gpc))*Ts;
GPC.ISE = sum(e3_gpc.^2 + e4_gpc.^2)*Ts;
GPC.esf = sum(sum(abs(diff(U_gpc,1,2))));
PID.IAE = sum(abs(e3_pid)+abs(e4_pid))*Ts;
PID.ISE = sum(e3_pid.^2 + e4_pid.^2)*Ts;
PID.esf = sum(sum(abs(diff(U_pid,1,2))));

fprintf('=========================================================\n');
fprintf('       COMPARACION GPC vs PI + DESACOPLADOR\n');
fprintf('=========================================================\n');
fprintf('  Metrica       GPC          PI+Desacopl   Ganador\n');
fprintf('---------------------------------------------------------\n');
fprintf('  IAE       %10.2f   %10.2f      %s\n', GPC.IAE, PID.IAE, gan(GPC.IAE,PID.IAE));
fprintf('  ISE       %10.2f   %10.2f      %s\n', GPC.ISE, PID.ISE, gan(GPC.ISE,PID.ISE));
fprintf('  Esfuerzo  %10.2f   %10.2f      %s\n', GPC.esf, PID.esf, gan(GPC.esf,PID.esf));
fprintf('=========================================================\n\n');

%% ========================================================================
%  6) GRAFICAS COMPARATIVAS
% ========================================================================
figure('Name','Comparacion GPC vs PI+Desacoplador','NumberTitle','off', ...
       'Position',[80 60 1100 800])

subplot(3,1,1)
plot(t_vec, H_gpc(3,:), 'b', 'LineWidth', 1.6); hold on;
plot(t_vec, H_pid(3,:), 'g', 'LineWidth', 1.6);
stairs(t_vec, ref(1,:), 'k--', 'LineWidth', 1.1);
xline(400,'k:','SP h_3','LabelHorizontalAlignment','center','LabelVerticalAlignment','bottom');
xline(800,'k:','SP h_4');
xline(t_ruido,'m:','RUIDO');
ylabel('h_3 (cm)'); xlabel('Tiempo (s)'); grid on;
legend('GPC','PI+Desacoplador','Referencia','Location','best');
title('Tanque 3');

subplot(3,1,2)
plot(t_vec, H_gpc(4,:), 'b', 'LineWidth', 1.6); hold on;
plot(t_vec, H_pid(4,:), 'g', 'LineWidth', 1.6);
stairs(t_vec, ref(2,:), 'k--', 'LineWidth', 1.1);
xline(400,'k:','SP h_3');
xline(800,'k:','SP h_4');
xline(t_ruido,'m:','RUIDO');
ylabel('h_4 (cm)'); xlabel('Tiempo (s)'); grid on;
legend('GPC','PI+Desacoplador','Referencia','Location','best');
title('Tanque 4');

subplot(3,1,3)
stairs(t_vec, U_gpc(1,:), 'b', 'LineWidth', 1.3); hold on;
stairs(t_vec, U_pid(1,:), 'g', 'LineWidth', 1.3);
stairs(t_vec, U_gpc(2,:), 'b--', 'LineWidth', 1.3);
stairs(t_vec, U_pid(2,:), 'g--', 'LineWidth', 1.3);
ylabel('u (V)'); xlabel('Tiempo (s)'); grid on;
legend('u_1 GPC','u_1 PI+Desac','u_2 GPC','u_2 PI+Desac','Location','best');
title('Senales de control');

sgtitle('Comparacion GPC vs PI+Desacoplador sobre planta NO lineal');

%% ====================== Funciones auxiliares ============================
function s = gan(a, b)
    if abs(a-b) < 1e-6, s = 'EMPATE';
    elseif a < b,        s = 'GPC';
    else,                s = 'PI+Desac';
    end
end

function dhdt = modelo_nl(~, h, u, p)
    h1=max(h(1),0); h2=max(h(2),0); h3=max(h(3),0); h4=max(h(4),0);
    u1=u(1); u2=u(2);
    dhdt = [-p.a1/p.A1*sqrt(2*p.g*h1) + (1-p.y2)*p.k2*u2/p.A1;
            -p.a2/p.A2*sqrt(2*p.g*h2) + (1-p.y1)*p.k1*u1/p.A2;
            -p.a3/p.A3*sqrt(2*p.g*h3) + p.a2/p.A3*sqrt(2*p.g*h2) + p.y2*p.k2*u2/p.A3;
            -p.a4/p.A4*sqrt(2*p.g*h4) + p.a1/p.A4*sqrt(2*p.g*h1) + p.y1*p.k1*u1/p.A4];
end
