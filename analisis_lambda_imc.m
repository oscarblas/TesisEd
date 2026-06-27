%% ========================================================================
%  analisis_lambda_imc.m
%  Justificacion visual de la eleccion de lambda_imc = tau/3 (Seccion 4.2.2)
%
%  Genera la IMAGEN 4.1 del Capitulo 4: respuesta al escalon en lazo
%  cerrado de cada PI sobre su subproceso aproximado de primer orden,
%  comparando tres valores de lambda_imc.
%
%  Para cada lazo se construye:
%     G_loop(s) = K / (tau*s + 1)
%     PI(s)     = Kp * (1 + 1/(Ti*s))   con Kp = tau/(K*lambda),  Ti = tau
%
%  Se simulan tres valores:
%     - lambda_imc = tau/2  (mas rapido, menos robusto)
%     - lambda_imc = tau/3  (compromiso adoptado)
%     - lambda_imc = tau    (mas robusto, mas lento)
% ========================================================================

clear; clc; close all;

%% ========================================================================
%  1) PARAMETROS FISICOS Y PUNTO DE OPERACION (mismos del Cap. 2)
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

T1=A1/a1*sqrt(2*h10/g); T2=A2/a2*sqrt(2*h20/g);
T3=A3/a3*sqrt(2*h30/g); T4=A4/a4*sqrt(2*h40/g);

%% ========================================================================
%  2) SUBPROCESOS DE PRIMER ORDEN APROXIMADOS PARA CADA LAZO
%  ------------------------------------------------------------------------
%  Lazo 1: PI_1 controla h4 mediante u1
%  Lazo 2: PI_2 controla h3 mediante u2
% ========================================================================
K1   = y1*k1*T4/A4;     tau1 = T4;
K2   = y2*k2*T3/A3;     tau2 = T3;

s = tf('s');
G1 = K1 / (tau1*s + 1);     % subproceso del lazo 1 (u1 -> h4)
G2 = K2 / (tau2*s + 1);     % subproceso del lazo 2 (u2 -> h3)

%% ========================================================================
%  3) FACTORES DE lambda_imc QUE SE COMPARAN
% ========================================================================
factores = [1/2, 1/3, 1];
etiquetas = {'\lambda_{imc} = \tau/2', ...
             '\lambda_{imc} = \tau/3  (adoptado)', ...
             '\lambda_{imc} = \tau'};
colores = [0.85 0.33 0.10;     % naranja
           0.00 0.45 0.74;     % azul (adoptado)
           0.47 0.67 0.19];    % verde

%% ========================================================================
%  4) SIMULACION DE LAS TRES RESPUESTAS POR LAZO
% ========================================================================
t_sim_lazo = 5*max(tau1, tau2);     % cubre al menos 5 tau
t = 0:0.5:t_sim_lazo;

fprintf('=== Parametros PI para cada lambda_imc ===\n');
fprintf('LAZO 1 (PI_1: u1 -> h4)   K = %.4f   tau = %.2f s\n', K1, tau1);
for i = 1:3
    lam = factores(i)*tau1;
    Kp  = tau1/(K1*lam);
    Ti  = tau1;
    fprintf('  %s   Kp = %7.3f   Ti = %6.2f s\n', etiquetas{i}, Kp, Ti);
end
fprintf('\nLAZO 2 (PI_2: u2 -> h3)   K = %.4f   tau = %.2f s\n', K2, tau2);
for i = 1:3
    lam = factores(i)*tau2;
    Kp  = tau2/(K2*lam);
    Ti  = tau2;
    fprintf('  %s   Kp = %7.3f   Ti = %6.2f s\n', etiquetas{i}, Kp, Ti);
end
fprintf('\n');

%% ========================================================================
%  5) GRAFICA COMPARATIVA  (IMAGEN 4.1)
% ========================================================================
fig = figure('Name','IMAGEN 4.1 - Justificacion de lambda_imc', ...
             'NumberTitle','off','Position',[80 80 1100 460]);

% --- Subplot 1: lazo 1 (PI_1, u1 -> h4) ---------------------------------
subplot(1,2,1)
hold on;
for i = 1:3
    lam = factores(i)*tau1;
    Kp  = tau1/(K1*lam);
    Ti  = tau1;
    PI  = Kp*(1 + 1/(Ti*s));
    LC  = feedback(PI*G1, 1);
    y   = step(LC, t);
    plot(t, y, 'LineWidth', 1.8, 'Color', colores(i,:));
end
yline(1, 'k--', 'LineWidth', 0.8);
xlabel('Tiempo (s)');
ylabel('Respuesta (cm)');
title('Lazo 1:  PI_1  controla  h_4');
legend(etiquetas, 'Location','southeast');
grid on; box on;

% --- Subplot 2: lazo 2 (PI_2, u2 -> h3) ---------------------------------
subplot(1,2,2)
hold on;
for i = 1:3
    lam = factores(i)*tau2;
    Kp  = tau2/(K2*lam);
    Ti  = tau2;
    PI  = Kp*(1 + 1/(Ti*s));
    LC  = feedback(PI*G2, 1);
    y   = step(LC, t);
    plot(t, y, 'LineWidth', 1.8, 'Color', colores(i,:));
end
yline(1, 'k--', 'LineWidth', 0.8);
xlabel('Tiempo (s)');
ylabel('Respuesta (cm)');
title('Lazo 2:  PI_2  controla  h_3');
legend(etiquetas, 'Location','southeast');
grid on; box on;

sgtitle('Respuesta en lazo cerrado para tres valores de \lambda_{imc}', ...
        'FontWeight','bold');

% Guardar como PNG con buena resolucion para la tesis
exportgraphics(fig, 'IMAGEN_4_1_lambda_imc.png', 'Resolution', 200);
fprintf('Figura guardada como IMAGEN_4_1_lambda_imc.png\n');
