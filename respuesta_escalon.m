%%% respuesta_escalon.m
%%% Validacion del modelo linealizado vs no lineal del sistema de 4 tanques.
%%%
%%% Se realizan DOS pruebas complementarias:
%%%   PRUEBA A: Llenado completo desde h=0 con entrada estacionaria.
%%%             Muestra la coherencia global entre modelos. FIT esperado ~80-90%.
%%%
%%%   PRUEBA B: Pequena perturbacion (5%) desde el punto de operacion.
%%%             Muestra la fidelidad del modelo lineal en la region donde
%%%             operara el controlador GPC. FIT esperado >95%.

clear; clc; close all;

%% Parametros de simulacion
Ts = 1;
t_f = 2000;
t = (0:Ts:t_f-1)';

%% Parametros fisicos
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

%% Modelo linealizado
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
sys_lin = ss(A_mat, B_mat, C_mat, D_mat);

params = struct('A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
                'a1',a1,'a2',a2,'a3',a3,'a4',a4, ...
                'k1',k1,'k2',k2,'y1',y1,'y2',y2,'g',g);

%% =====================================================================
%  PRUEBA A: Llenado completo desde h = 0
%  ---------------------------------------------------------------------
%  Inicio: tanques vacios.
%  Entrada: escalon a los valores estacionarios u10, u20.
%  Esperado: ambos modelos convergen a h0, pero la linealizacion es
%            menos precisa lejos del punto de operacion.
% =====================================================================
fprintf('=== PRUEBA A: Llenado desde h = 0 ===\n');

h_init_A = [0; 0; 0; 0];
u1_A = u10 * ones(length(t),1);
u2_A = u20 * ones(length(t),1);

% No lineal
[~, h_nolin_A] = ode45(@(t_ode,h) modelo_nolineal(t_ode,h,t,u1_A,u2_A,params), t, h_init_A);

% Lineal (con condicion inicial en desviacion)
delta_h0_A = h_init_A - h0;
delta_u_A  = zeros(length(t), 2);
delta_h_A  = lsim(sys_lin, delta_u_A, t, delta_h0_A);
h_lin_A    = delta_h_A + h0';

% FIT por tanque
FIT_A = zeros(4,1);
for i = 1:4
    FIT_A(i) = 100*(1 - norm(h_nolin_A(:,i) - h_lin_A(:,i)) / ...
                       norm(h_nolin_A(:,i) - mean(h_nolin_A(:,i))));
    fprintf('  FIT h%d = %.2f%%\n', i, FIT_A(i));
end
fprintf('  FIT promedio: %.2f%%\n\n', mean(FIT_A));

%% =====================================================================
%  PRUEBA B: Pequena perturbacion (5%) desde el punto de operacion
%  ---------------------------------------------------------------------
%  Inicio: tanques en el punto de operacion h0.
%  Entrada: escalon +5% en u1 (t=100s) y +5% en u2 (t=500s).
%  Esperado: ambos modelos casi identicos. FIT > 95%.
%  Esta es la prueba RELEVANTE para validar el modelo de prediccion
%  del controlador GPC.
% =====================================================================
fprintf('=== PRUEBA B: Perturbacion 5%% desde h = h0 ===\n');

pct = 0.05;
h_init_B = h0;

u1_B = u10 * ones(length(t),1);
u2_B = u20 * ones(length(t),1);
u1_B(101:end) = u10 * (1 + pct);
u2_B(501:end) = u20 * (1 + pct);

% No lineal
[~, h_nolin_B] = ode45(@(t_ode,h) modelo_nolineal(t_ode,h,t,u1_B,u2_B,params), t, h_init_B);

% Lineal (sistema arranca en el punto de operacion -> delta_h0 = 0)
delta_h0_B = h_init_B - h0;             % = [0;0;0;0]
delta_u_B  = [u1_B - u10, u2_B - u20];
delta_h_B  = lsim(sys_lin, delta_u_B, t, delta_h0_B);
h_lin_B    = delta_h_B + h0';

% FIT por tanque
FIT_B = zeros(4,1);
for i = 1:4
    FIT_B(i) = 100*(1 - norm(h_nolin_B(:,i) - h_lin_B(:,i)) / ...
                       norm(h_nolin_B(:,i) - mean(h_nolin_B(:,i))));
    fprintf('  FIT h%d = %.2f%%\n', i, FIT_B(i));
end
fprintf('  FIT promedio: %.2f%%\n\n', mean(FIT_B));

%% =====================================================================
%  TABLA RESUMEN
% =====================================================================
fprintf('=========================================================\n');
fprintf('  RESUMEN COMPARATIVO DE FIT%%\n');
fprintf('=========================================================\n');
fprintf('  Tanque  |  Prueba A (llenado)  |  Prueba B (perturb)  \n');
fprintf('---------------------------------------------------------\n');
for i = 1:4
    fprintf('   h%d    |       %6.2f%%        |       %6.2f%%        \n', ...
            i, FIT_A(i), FIT_B(i));
end
fprintf('---------------------------------------------------------\n');
fprintf('  PROMEDIO|       %6.2f%%        |       %6.2f%%        \n', ...
        mean(FIT_A), mean(FIT_B));
fprintf('=========================================================\n\n');

%% =====================================================================
%  GRAFICAS
% =====================================================================

% --- Figura 1: Prueba A (llenado) ---
figure('Name','Prueba A: Llenado desde h=0','NumberTitle','off')
titulos = {'Tanque 1 (superior)','Tanque 2 (superior)', ...
           'Tanque 3 (inferior, controlado)','Tanque 4 (inferior, controlado)'};
for i = 1:4
    subplot(2,2,i)
    plot(t, h_nolin_A(:,i), 'b', 'LineWidth', 1.5); hold on;
    plot(t, h_lin_A(:,i), 'r--', 'LineWidth', 1.5);
    yline(h0(i), 'k:', 'h_0', 'LineWidth', 1);
    ylabel(['h_' num2str(i) ' (cm)']); xlabel('Tiempo (s)');
    legend('No lineal','Lineal','Estacionario','Location','best');
    title(sprintf('%s (FIT = %.2f%%)', titulos{i}, FIT_A(i)));
    grid on;
end
sgtitle('Prueba A: Llenado completo desde h = 0 con u = u_0 (validacion global)');

% --- Figura 2: Prueba B (perturbacion) ---
figure('Name','Prueba B: Perturbacion 5% desde h=h0','NumberTitle','off')
for i = 1:4
    subplot(2,2,i)
    plot(t, h_nolin_B(:,i), 'b', 'LineWidth', 1.5); hold on;
    plot(t, h_lin_B(:,i), 'r--', 'LineWidth', 1.5);
    yline(h0(i), 'k:', 'h_0', 'LineWidth', 1);
    ylabel(['h_' num2str(i) ' (cm)']); xlabel('Tiempo (s)');
    legend('No lineal','Lineal','Estacionario','Location','best');
    title(sprintf('%s (FIT = %.2f%%)', titulos{i}, FIT_B(i)));
    grid on;
end
sgtitle('Prueba B: Perturbacion 5% desde h = h_0 (validacion en region de operacion del GPC)');

% --- Figura 3: Senales de entrada de ambas pruebas ---
figure('Name','Entradas aplicadas','NumberTitle','off')
subplot(2,2,1)
stairs(t, u1_A, 'b', 'LineWidth', 1.5);
ylabel('u_1'); xlabel('Tiempo (s)');
title(sprintf('Prueba A: u_1 = u_{10} = %.2f', u10)); grid on;

subplot(2,2,2)
stairs(t, u2_A, 'r', 'LineWidth', 1.5);
ylabel('u_2'); xlabel('Tiempo (s)');
title(sprintf('Prueba A: u_2 = u_{20} = %.2f', u20)); grid on;

subplot(2,2,3)
stairs(t, u1_B, 'b', 'LineWidth', 1.5);
ylabel('u_1'); xlabel('Tiempo (s)');
title(sprintf('Prueba B: u_1 (escalon +%.0f%% en t=100s)', pct*100)); grid on;

subplot(2,2,4)
stairs(t, u2_B, 'r', 'LineWidth', 1.5);
ylabel('u_2'); xlabel('Tiempo (s)');
title(sprintf('Prueba B: u_2 (escalon +%.0f%% en t=500s)', pct*100)); grid on;
sgtitle('Senales de entrada aplicadas en cada prueba');

%% =====================================================================
%  Funcion del modelo no lineal
%  =====================================================================
function dhdt = modelo_nolineal(t_ode, h, t_vec, u1_vec, u2_vec, p)
    u1 = interp1(t_vec, u1_vec, t_ode, 'previous', u1_vec(end));
    u2 = interp1(t_vec, u2_vec, t_ode, 'previous', u2_vec(end));

    h1 = max(h(1), 0);
    h2 = max(h(2), 0);
    h3 = max(h(3), 0);
    h4 = max(h(4), 0);

    dh1dt = -p.a1/p.A1*sqrt(2*p.g*h1) + (1-p.y2)*p.k2*u2/p.A1;
    dh2dt = -p.a2/p.A2*sqrt(2*p.g*h2) + (1-p.y1)*p.k1*u1/p.A2;
    dh3dt = -p.a3/p.A3*sqrt(2*p.g*h3) + p.a2/p.A3*sqrt(2*p.g*h2) + p.y2*p.k2*u2/p.A3;
    dh4dt = -p.a4/p.A4*sqrt(2*p.g*h4) + p.a1/p.A4*sqrt(2*p.g*h1) + p.y1*p.k1*u1/p.A4;

    dhdt = [dh1dt; dh2dt; dh3dt; dh4dt];
end
