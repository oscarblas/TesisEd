%% ========================================================================
%  trayectoria_referencias.m
%  Genera la IMAGEN 4.2 del Capitulo 4: trayectoria de referencias
%  r_h3(t) y r_h4(t) durante toda la simulacion del escenario integrado.
%
%  Formato: subplot vertical de dos paneles (uno por cada trayectoria),
%  con ejes equivalentes a los usados en controlador_PID.m / controlador_GPC.m
%  pero mostrando unicamente la trayectoria de referencia.
%
%  Eventos del escenario (Seccion 4.3.2):
%    t = 0    s  Arranque desde tanques vacios
%    t = 400  s  SP de h3:  25 -> 30 cm
%    t = 800  s  SP de h4:  25 -> 20 cm
%    t = 1100 s  Activacion de ruido gaussiano (sigma = 0.3 cm)
%    t = 1200 s  SP de h3:  30 -> 25  y  SP de h4:  20 -> 35 cm
% ========================================================================

clear; clc; close all;

%% ========================================================================
%  1) DEFINICION DE LA TRAYECTORIA DE REFERENCIAS
% ========================================================================
Ts    = 1;
t_sim = 2000;
N     = round(t_sim/Ts);
t     = (0:N-1)*Ts;

ref_h3 = 25*ones(1,N);
ref_h4 = 25*ones(1,N);

ref_h3(t >= 400)  = 30;     % cambio h3: 25 -> 30
ref_h4(t >= 800)  = 20;     % cambio h4: 25 -> 20
ref_h3(t >= 1200) = 25;     % h3 regresa a 25
ref_h4(t >= 1200) = 35;     % h4 sube a 35 (lejos del punto de linealizacion)

t_ruido = 1100;

%% ========================================================================
%  2) GRAFICA  (IMAGEN 4.2)
% ========================================================================
fig = figure('Name','IMAGEN 4.2 - Trayectoria de referencias', ...
             'NumberTitle','off','Position',[80 80 950 700]);

% --- Subplot 1: trayectoria de referencia para h3 -----------------------
subplot(2,1,1)
stairs(t, ref_h3, 'r--', 'LineWidth', 1.5); hold on;
xline(400, 'k:', 'SP h_3', 'LabelHorizontalAlignment','center');
xline(800, 'k:', 'SP h_4');
xline(t_ruido, 'm:', 'RUIDO');
xline(1200, 'k:', 'SP h_3 y h_4', 'LabelHorizontalAlignment','center');
ylabel('h_3 (cm)'); xlabel('Tiempo (s)'); grid on;
legend('Referencia','Location','best');
title('Trayectoria de referencia del tanque 3');
ylim([0 40]); xlim([0 t_sim]);

% --- Subplot 2: trayectoria de referencia para h4 -----------------------
subplot(2,1,2)
stairs(t, ref_h4, 'r--', 'LineWidth', 1.5); hold on;
xline(400, 'k:', 'SP h_3', 'LabelHorizontalAlignment','center');
xline(800, 'k:', 'SP h_4');
xline(t_ruido, 'm:', 'RUIDO');
xline(1200, 'k:', 'SP h_3 y h_4', 'LabelHorizontalAlignment','center');
ylabel('h_4 (cm)'); xlabel('Tiempo (s)'); grid on;
legend('Referencia','Location','best');
title('Trayectoria de referencia del tanque 4');
ylim([0 40]); xlim([0 t_sim]);

sgtitle('Trayectoria de referencias del escenario integrado de simulacion');

% Guardar como PNG con buena resolucion para la tesis
exportgraphics(fig, 'IMAGEN_4_2_trayectoria_referencias.png', 'Resolution', 200);
fprintf('Figura guardada como IMAGEN_4_2_trayectoria_referencias.png\n');
