%% ========================================================================
%  johansson_fase_minima_vs_no_minima.m
%
%  Comparacion del sistema de 4 tanques acoplados de Johansson (2000)
%  ante una entrada escalon, configurado en:
%     (a) Fase MINIMA       gamma1 + gamma2 en (1, 2)
%     (b) Fase NO MINIMA    gamma1 + gamma2 en (0, 1)
%
%  Referencia:
%   K. H. Johansson, "The quadruple-tank process: A multivariable laboratory
%   process with an adjustable zero", IEEE Trans. on Control Systems
%   Technology, vol. 8, no. 3, pp. 456-465, 2000.
%
%  NOTACION DE JOHANSSON (distinta a la del resto de tu codigo):
%     Tanques 1 y 2 -> INFERIORES (controlados)
%     Tanques 3 y 4 -> SUPERIORES
%     Bomba 1 envia flujo a:  tanque 1 (fraccion gamma1) y tanque 4 (1-gamma1)
%     Bomba 2 envia flujo a:  tanque 2 (fraccion gamma2) y tanque 3 (1-gamma2)
%     Tanque 3 drena en tanque 1
%     Tanque 4 drena en tanque 2
%
%  Ecuaciones no lineales:
%     dh1/dt = -a1/A1*sqrt(2g*h1) + a3/A1*sqrt(2g*h3) + gamma1*k1*v1/A1
%     dh2/dt = -a2/A2*sqrt(2g*h2) + a4/A2*sqrt(2g*h4) + gamma2*k2*v2/A2
%     dh3/dt = -a3/A3*sqrt(2g*h3) + (1-gamma2)*k2*v2/A3
%     dh4/dt = -a4/A4*sqrt(2g*h4) + (1-gamma1)*k1*v1/A4
% ========================================================================

clear; clc; close all;

%% ========================================================================
%  PARAMETROS COMUNES (Tabla 1 del articulo de Johansson)
% ========================================================================
A1 = 28;   A3 = 28;     % areas de tanques [cm^2]
A2 = 32;   A4 = 32;
a1 = 0.071; a3 = 0.071; % areas de orificios de salida [cm^2]
a2 = 0.057; a4 = 0.057;
kc = 0.50;              % ganancia de sensor [V/cm] (no usado aqui)
g  = 981;               % gravedad [cm/s^2]

%% ========================================================================
%  CONFIGURACION P- : FASE MINIMA  (gamma1 + gamma2 = 1.30)
%  Tabla 2 del articulo (operating point P-)
% ========================================================================
P_min.gamma1 = 0.70;
P_min.gamma2 = 0.60;
P_min.k1 = 3.33;          % cm^3/(V*s)
P_min.k2 = 3.35;
P_min.v10 = 3.00;         % V (entrada en estacionario)
P_min.v20 = 3.00;
% Alturas estacionarias reportadas:
P_min.h10 = 12.4; P_min.h20 = 12.7;
P_min.h30 =  1.8; P_min.h40 =  1.4;
P_min.nombre = sprintf('Fase MINIMA (\\gamma_1+\\gamma_2 = %.2f)', ...
                        P_min.gamma1 + P_min.gamma2);

%% ========================================================================
%  CONFIGURACION P+ : FASE NO MINIMA  (gamma1 + gamma2 = 0.77)
%  Tabla 2 del articulo (operating point P+)
% ========================================================================
P_nomin.gamma1 = 0.43;
P_nomin.gamma2 = 0.34;
P_nomin.k1 = 3.14;
P_nomin.k2 = 3.29;
P_nomin.v10 = 3.15;
P_nomin.v20 = 3.15;
P_nomin.h10 = 12.6; P_nomin.h20 = 13.0;
P_nomin.h30 =  4.8; P_nomin.h40 =  4.9;
P_nomin.nombre = sprintf('Fase NO MINIMA (\\gamma_1+\\gamma_2 = %.2f)', ...
                          P_nomin.gamma1 + P_nomin.gamma2);

% Empacar parametros fisicos comunes
fisico = struct('A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
                'a1',a1,'a2',a2,'a3',a3,'a4',a4,'g',g);

%% ========================================================================
%  ESCALON DE PRUEBA
%  Aplicamos un escalon pequeno en v1 a partir de t = 100s
%  para observar la respuesta de h1 y h2.
% ========================================================================
Ts = 0.5;
t_f = 800;
t = (0:Ts:t_f)';

% Magnitud del escalon (1V sobre v1, segun el articulo)
delta_v1 = 1.0;     % V
delta_v2 = 0;       % la otra entrada se mantiene constante

% Senal de entrada
v1_vec = ones(length(t),1);
v2_vec = ones(length(t),1);
idx_step = find(t >= 100, 1);

%% ========================================================================
%  SIMULACION CASO P-  (FASE MINIMA)
% ========================================================================
v1_p = P_min.v10 * v1_vec;
v2_p = P_min.v20 * v2_vec;
v1_p(idx_step:end) = P_min.v10 + delta_v1;

h0_min = [P_min.h10; P_min.h20; P_min.h30; P_min.h40];

[~, h_min] = ode45(@(t_ode, h) modelo(t_ode, h, t, v1_p, v2_p, P_min, fisico), ...
                   t, h0_min);

%% ========================================================================
%  SIMULACION CASO P+  (FASE NO MINIMA)
% ========================================================================
v1_n = P_nomin.v10 * v1_vec;
v2_n = P_nomin.v20 * v2_vec;
v1_n(idx_step:end) = P_nomin.v10 + delta_v1;

h0_nomin = [P_nomin.h10; P_nomin.h20; P_nomin.h30; P_nomin.h40];

[~, h_nomin] = ode45(@(t_ode, h) modelo(t_ode, h, t, v1_n, v2_n, P_nomin, fisico), ...
                     t, h0_nomin);

%% ========================================================================
%  GRAFICAS COMPARATIVAS
% ========================================================================

% --- Tanques inferiores (controlados): h1 y h2 -----------------------
figure('Name','Johansson - h1 y h2 (tanques inferiores)','NumberTitle','off')

subplot(2,1,1)
plot(t, h_min(:,1)   - P_min.h10,   'b', 'LineWidth', 1.6); hold on;
plot(t, h_nomin(:,1) - P_nomin.h10, 'r', 'LineWidth', 1.6);
xline(100,'k:','escalon en v_1');
ylabel('\Delta h_1 (cm)'); xlabel('Tiempo (s)');
legend(P_min.nombre, P_nomin.nombre, 'Location','best');
title('Respuesta de h_1 ante escalon en v_1 (variacion respecto al estacionario)');
grid on;

subplot(2,1,2)
plot(t, h_min(:,2)   - P_min.h20,   'b', 'LineWidth', 1.6); hold on;
plot(t, h_nomin(:,2) - P_nomin.h20, 'r', 'LineWidth', 1.6);
xline(100,'k:','escalon en v_1');
ylabel('\Delta h_2 (cm)'); xlabel('Tiempo (s)');
legend(P_min.nombre, P_nomin.nombre, 'Location','best');
title('Respuesta de h_2 ante escalon en v_1');
grid on;

% --- Tanques superiores: h3 y h4 -------------------------------------
figure('Name','Johansson - h3 y h4 (tanques superiores)','NumberTitle','off')

subplot(2,1,1)
plot(t, h_min(:,3)   - P_min.h30,   'b', 'LineWidth', 1.6); hold on;
plot(t, h_nomin(:,3) - P_nomin.h30, 'r', 'LineWidth', 1.6);
xline(100,'k:','escalon en v_1');
ylabel('\Delta h_3 (cm)'); xlabel('Tiempo (s)');
legend(P_min.nombre, P_nomin.nombre, 'Location','best');
title('Respuesta de h_3'); grid on;

subplot(2,1,2)
plot(t, h_min(:,4)   - P_min.h40,   'b', 'LineWidth', 1.6); hold on;
plot(t, h_nomin(:,4) - P_nomin.h40, 'r', 'LineWidth', 1.6);
xline(100,'k:','escalon en v_1');
ylabel('\Delta h_4 (cm)'); xlabel('Tiempo (s)');
legend(P_min.nombre, P_nomin.nombre, 'Location','best');
title('Respuesta de h_4'); grid on;

% --- Comparacion alturas absolutas -----------------------------------
figure('Name','Johansson - Alturas absolutas','NumberTitle','off')
nombres = {'h_1 (inferior)','h_2 (inferior)','h_3 (superior)','h_4 (superior)'};
for i = 1:4
    subplot(2,2,i)
    plot(t, h_min(:,i),   'b', 'LineWidth', 1.5); hold on;
    plot(t, h_nomin(:,i), 'r', 'LineWidth', 1.5);
    xline(100,'k:');
    ylabel([nombres{i} ' (cm)']); xlabel('Tiempo (s)');
    legend('Fase minima','Fase no minima','Location','best');
    title(nombres{i}); grid on;
end
sgtitle('Sistema de Johansson - Respuesta al escalon (alturas absolutas)');

%% ========================================================================
%  ANALISIS DE LA RESPUESTA INVERSA (sello de la fase no minima)
% ========================================================================
fprintf('=========================================================\n');
fprintf('  ANALISIS DE FASE MINIMA vs NO MINIMA - Johansson 2000\n');
fprintf('=========================================================\n\n');

fprintf('Caso P- (fase minima):\n');
fprintf('  gamma1+gamma2 = %.2f  (en (1,2) -> fase minima)\n', ...
        P_min.gamma1+P_min.gamma2);
dh1_inicial = h_min(idx_step+10,1) - P_min.h10;
dh1_final   = h_min(end,1)         - P_min.h10;
fprintf('  Variacion h1 a +5s del escalon: %+.4f cm\n', dh1_inicial);
fprintf('  Variacion h1 al final:          %+.4f cm\n', dh1_final);
fprintf('  -> Movimiento DIRECTO (mismo signo desde el inicio).\n\n');

fprintf('Caso P+ (fase no minima):\n');
fprintf('  gamma1+gamma2 = %.2f  (en (0,1) -> fase no minima)\n', ...
        P_nomin.gamma1+P_nomin.gamma2);
dh1_inicial_n = h_nomin(idx_step+10,1) - P_nomin.h10;
dh1_final_n   = h_nomin(end,1)         - P_nomin.h10;
fprintf('  Variacion h1 a +5s del escalon: %+.4f cm\n', dh1_inicial_n);
fprintf('  Variacion h1 al final:          %+.4f cm\n', dh1_final_n);
if sign(dh1_inicial_n) ~= sign(dh1_final_n)
    fprintf('  -> RESPUESTA INVERSA: h1 se mueve primero al lado contrario\n');
    fprintf('     antes de subir. Es la firma de la fase no minima.\n');
else
    fprintf('  -> No se observa respuesta inversa clara (verificar dt o magnitud).\n');
end
fprintf('\n=========================================================\n');

%% ====================== Funcion del modelo no lineal ====================
function dhdt = modelo(t_ode, h, t_vec, v1_vec, v2_vec, P, F)
    % Interpolar entradas
    v1 = interp1(t_vec, v1_vec, t_ode, 'previous', v1_vec(end));
    v2 = interp1(t_vec, v2_vec, t_ode, 'previous', v2_vec(end));

    % Evitar negativos numericamente
    h1 = max(h(1),0); h2 = max(h(2),0);
    h3 = max(h(3),0); h4 = max(h(4),0);

    % Ecuaciones de Johansson (2000)
    dh1 = -F.a1/F.A1*sqrt(2*F.g*h1) + F.a3/F.A1*sqrt(2*F.g*h3) ...
          + P.gamma1*P.k1*v1/F.A1;
    dh2 = -F.a2/F.A2*sqrt(2*F.g*h2) + F.a4/F.A2*sqrt(2*F.g*h4) ...
          + P.gamma2*P.k2*v2/F.A2;
    dh3 = -F.a3/F.A3*sqrt(2*F.g*h3) + (1-P.gamma2)*P.k2*v2/F.A3;
    dh4 = -F.a4/F.A4*sqrt(2*F.g*h4) + (1-P.gamma1)*P.k1*v1/F.A4;

    dhdt = [dh1; dh2; dh3; dh4];
end
