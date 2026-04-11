%%% respuesta_escalon.m
%%% Respuesta escalon - Comparacion lineal vs no lineal con calculo de FIT%
%%% Sistema de 4 tanques acoplados
%%% Todo en MATLAB puro (sin Simulink)

clear; clc; close all;

%% Parametros de simulacion
Ts = 1;
t_f = 2000;
t = (0:Ts:t_f-1)';

%% Parametros fisicos de la planta piloto
A1 = 706.85; A2 = 706.85; A3 = 706.85; A4 = 706.85;
a1 = 1.89;   a2 = 1.89;   a3 = 5.39;   a4 = 5.39;
k1 = 1;      k2 = 1;
y1 = 0.7;    y2 = 0.7;
g  = 981;

%% Punto de operacion
h30 = 25; h40 = 25;

M_A = [(1-y1)*k1   y2*k2;
       y1*k1       (1-y2)*k2];
M_B = [a3*sqrt(2*g*h30);
       a4*sqrt(2*g*h40)];

u0  = M_A\M_B;
u10 = u0(1);
u20 = u0(2);

h10 = ((1-y2)*k2*u20/a1)^2 / (2*g);
h20 = ((1-y1)*k1*u10/a2)^2 / (2*g);
h0  = [h10; h20; h30; h40];

fprintf('=== Punto de operacion ===\n');
fprintf('h0 = [%.4f, %.4f, %.4f, %.4f] cm\n', h0);
fprintf('u0 = [%.4f, %.4f]\n\n', u10, u20);

%% Matrices del modelo linealizado
T1 = A1/a1 * sqrt(2*h10/g);
T2 = A2/a2 * sqrt(2*h20/g);
T3 = A3/a3 * sqrt(2*h30/g);
T4 = A4/a4 * sqrt(2*h40/g);

A_mat = [-1/T1        0           0      0;
          0          -1/T2        0      0;
          0           A2/(A3*T2) -1/T3   0;
          A1/(A4*T1)  0           0     -1/T4];

B_mat = [0            (1-y2)*k2/A1;
         (1-y1)*k1/A2  0;
         0             y2*k2/A3;
         y1*k1/A4      0];

C_mat = eye(4);
D_mat = zeros(4,2);

%% Entrada escalon
% Escalon del 30% en u1 a partir de t = 100s
% Escalon del 30% en u2 a partir de t = 500s
u1_vec = u10 * ones(length(t), 1);
u2_vec = u20 * ones(length(t), 1);

u1_vec(101:end) = u10 * 1.3;   % +30% en u1
u2_vec(501:end) = u20 * 1.3;   % +30% en u2

%% Simulacion del modelo NO LINEAL (ode45)
params = struct('A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
               'a1',a1,'a2',a2,'a3',a3,'a4',a4, ...
               'k1',k1,'k2',k2,'y1',y1,'y2',y2,'g',g);

[~, h_nolin] = ode45(@(t_ode, h) modelo_nolineal(t_ode, h, t, u1_vec, u2_vec, params), t, h0);

%% Simulacion del modelo LINEAL (lsim)
sys_lin = ss(A_mat, B_mat, C_mat, D_mat);
delta_u = [u1_vec - u10, u2_vec - u20];
delta_h = lsim(sys_lin, delta_u, t);
h_lin   = delta_h + h0';

%% Graficas de respuesta
figure('Name','Respuesta Escalon','NumberTitle','off')
titulos = {'Tanque 1 (superior)', 'Tanque 2 (superior)', ...
           'Tanque 3 (inferior)', 'Tanque 4 (inferior)'};

for i = 1:4
    subplot(2,2,i)
    plot(t, h_nolin(:,i), 'b', 'LineWidth', 1.5); hold on;
    plot(t, h_lin(:,i), 'r--', 'LineWidth', 1.5);
    ylabel(['h_' num2str(i) ' (cm)']);
    xlabel('Tiempo (s)');
    legend('No lineal', 'Lineal', 'Location', 'best');
    title(titulos{i});
    grid on;
end
sgtitle('Respuesta escalon: Modelo no lineal vs linealizado');

%% Graficas de entradas
figure('Name','Entradas','NumberTitle','off')
subplot(2,1,1)
stairs(t, u1_vec, 'b', 'LineWidth', 1.5);
ylabel('u_1'); xlabel('Tiempo (s)');
title('Entrada u_1 (escalon +30% en t=100s)');
grid on;

subplot(2,1,2)
stairs(t, u2_vec, 'r', 'LineWidth', 1.5);
ylabel('u_2'); xlabel('Tiempo (s)');
title('Entrada u_2 (escalon +30% en t=500s)');
grid on;
sgtitle('Senales de entrada');

%% Calculo de FIT%
fprintf('=== FIT%% ===\n');
for i = 1:4
    FIT = 100 * (1 - norm(h_nolin(:,i) - h_lin(:,i)) / ...
                     norm(h_nolin(:,i) - mean(h_nolin(:,i))));
    fprintf('FIT h%d = %.2f%%\n', i, FIT);
end

%% Error maximo y minimo en tanques inferiores (h3, h4)
fprintf('\n=== Error maximo en h3, h4 (respecto al punto de operacion) ===\n');
fprintf('Error max h3 = %.2f%%\n', max(h_nolin(:,3))/h30*100 - 100);
fprintf('Error max h4 = %.2f%%\n', max(h_nolin(:,4))/h40*100 - 100);

fprintf('\n=== Error minimo en h3, h4 ===\n');
fprintf('Error min h3 = %.2f%%\n', 100 - min(h_nolin(:,3))/h30*100);
fprintf('Error min h4 = %.2f%%\n', 100 - min(h_nolin(:,4))/h40*100);

%% ====================================================================
%  Funcion del modelo no lineal
%  ====================================================================
function dhdt = modelo_nolineal(t_ode, h, t_vec, u1_vec, u2_vec, p)
    % Interpolacion de entradas (zero-order hold)
    u1 = interp1(t_vec, u1_vec, t_ode, 'previous', u1_vec(end));
    u2 = interp1(t_vec, u2_vec, t_ode, 'previous', u2_vec(end));

    % Evitar alturas negativas
    h1 = max(h(1), 0);
    h2 = max(h(2), 0);
    h3 = max(h(3), 0);
    h4 = max(h(4), 0);

    % Ecuaciones diferenciales no lineales
    dh1dt = -p.a1/p.A1*sqrt(2*p.g*h1) + (1-p.y2)*p.k2*u2/p.A1;
    dh2dt = -p.a2/p.A2*sqrt(2*p.g*h2) + (1-p.y1)*p.k1*u1/p.A2;
    dh3dt = -p.a3/p.A3*sqrt(2*p.g*h3) + p.a2/p.A3*sqrt(2*p.g*h2) + p.y2*p.k2*u2/p.A3;
    dh4dt = -p.a4/p.A4*sqrt(2*p.g*h4) + p.a1/p.A4*sqrt(2*p.g*h1) + p.y1*p.k1*u1/p.A4;

    dhdt = [dh1dt; dh2dt; dh3dt; dh4dt];
end
