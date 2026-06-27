%% ========================================================================
%  trayectoria_referencias.m
%  Genera la IMAGEN 4.2 del Capitulo 4: trayectoria de referencias
%  r_h3(t) y r_h4(t) durante toda la simulacion del escenario integrado,
%  con lineas verticales que marcan los cinco eventos.
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

%% ========================================================================
%  2) GRAFICA  (IMAGEN 4.2)
% ========================================================================
fig = figure('Name','IMAGEN 4.2 - Trayectoria de referencias', ...
             'NumberTitle','off','Position',[80 80 1100 520]);
hold on;

% --- Trayectorias de referencia ----------------------------------------
stairs(t, ref_h3, 'LineWidth', 2.0, 'Color', [0.00 0.45 0.74]);
stairs(t, ref_h4, 'LineWidth', 2.0, 'Color', [0.85 0.33 0.10]);

% --- Lineas verticales de los eventos -----------------------------------
eventos = [   0,  'Arranque  (h = 0)';
            400,  'SP h_3: 25 -> 30 cm';
            800,  'SP h_4: 25 -> 20 cm';
           1100,  'Ruido gaussiano  (\sigma = 0.3 cm)';
           1200,  'SP h_3 -> 25  y  SP h_4 -> 35 cm'];

t_eventos = [0 400 800 1100 1200];
etiq_eventos = {'Arranque  (h = 0)', ...
                'SP h_3: 25 \rightarrow 30 cm', ...
                'SP h_4: 25 \rightarrow 20 cm', ...
                'Ruido gaussiano (\sigma = 0.3 cm)', ...
                'SP h_3 \rightarrow 25  y  SP h_4 \rightarrow 35 cm'};

for k = 1:length(t_eventos)
    xline(t_eventos(k), 'k:', etiq_eventos{k}, ...
          'LineWidth', 1.1, ...
          'LabelOrientation', 'horizontal', ...
          'LabelVerticalAlignment', 'top', ...
          'FontSize', 9);
end

% --- Formato ------------------------------------------------------------
xlabel('Tiempo (s)', 'FontWeight', 'bold');
ylabel('Referencia (cm)', 'FontWeight', 'bold');
title('Trayectoria de referencias del escenario integrado de simulacion');
legend({'r_{h_3}(t)','r_{h_4}(t)'}, 'Location','northwest','FontSize',11);
ylim([0 40]);
xlim([0 t_sim]);
grid on; box on;
set(gca,'FontSize',11);

% Guardar como PNG con buena resolucion para la tesis
exportgraphics(fig, 'IMAGEN_4_2_trayectoria_referencias.png', 'Resolution', 200);
fprintf('Figura guardada como IMAGEN_4_2_trayectoria_referencias.png\n');
