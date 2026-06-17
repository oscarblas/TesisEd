%% ========================================================================
%  controlador_PID.m
%  Control PI Descentralizado CON DESACOPLADOR ESTATICO para el sistema
%  TITO de cuatro tanques acoplados.
%
%  ESTRUCTURA (conforme a la seccion 4.2 de la tesis):
%    Lazo 1:  PI_1  -->  v_1  --[D]-->  u_1  -->  controla  h_4
%    Lazo 2:  PI_2  -->  v_2  --[D]-->  u_2  -->  controla  h_3
%
%  El desacoplador estatico D (Skogestad, matriz constante 2x2) actua
%  entre las salidas de los PI y las entradas a la planta para cancelar
%  el acoplamiento cruzado en estado estacionario.
%
%  Escenario de simulacion (evidencia el efecto del acoplamiento):
%    t = 0    : arranque, planta en h = 0
%    t = 0..400 : transitorio hacia el punto estacionario (h3=h4=25)
%    t = 400  : cambio de set point  h3 25->30  (afecta a h4 por acople)
%    t = 800  : cambio de set point  h4 25->20  (afecta a h3 por acople)
%    t = 1100 : se inyecta ruido gaussiano en las mediciones
%    t = 1500 : fin de simulacion
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
u0  = M_A\M_B;
u10 = u0(1); u20 = u0(2);

h10 = ((1-y2)*k2*u20/a1)^2/(2*g);
h20 = ((1-y1)*k1*u10/a2)^2/(2*g);
h0  = [h10; h20; h30; h40];

T1=A1/a1*sqrt(2*h10/g); T2=A2/a2*sqrt(2*h20/g);
T3=A3/a3*sqrt(2*h30/g); T4=A4/a4*sqrt(2*h40/g);

% Modelo lineal continuo (necesario para calcular el desacoplador estatico)
Ac = [-1/T1 0 0 0; 0 -1/T2 0 0;
       0 A2/(A3*T2) -1/T3 0; A1/(A4*T1) 0 0 -1/T4];
Bc = [0 (1-y2)*k2/A1; (1-y1)*k1/A2 0;
      0 y2*k2/A3; y1*k1/A4 0];
Cc = [0 0 1 0; 0 0 0 1];   % fila 1 = h3,  fila 2 = h4

fprintf('=== Punto de operacion ===\n');
fprintf('  h0 = [%.2f, %.2f, %.2f, %.2f] cm\n', h0);
fprintf('  u0 = [%.2f, %.2f]\n\n', u10, u20);

%% ========================================================================
%  2) SINTONIZACION IMC DE LOS DOS PI
% ========================================================================
% Lazo 1: PI_1 controla h4 mediante u1
K1   = y1*k1*T4/A4;
tau1 = T4;
lam1 = tau1/3;
Kp1  = tau1/(K1*lam1);
Ti1  = tau1;

% Lazo 2: PI_2 controla h3 mediante u2
K2   = y2*k2*T3/A3;
tau2 = T3;
lam2 = tau2/3;
Kp2  = tau2/(K2*lam2);
Ti2  = tau2;

fprintf('=== Sintonizacion IMC (lambda_imc = tau/3) ===\n');
fprintf('  PI_1 (u1->h4): Kp = %.3f,  Ti = %.2f s\n', Kp1, Ti1);
fprintf('  PI_2 (u2->h3): Kp = %.3f,  Ti = %.2f s\n', Kp2, Ti2);

%% ========================================================================
%  3) DESACOPLADOR ESTATICO (matriz constante 2x2)
%  ------------------------------------------------------------------------
%  Matriz de ganancia DC del sistema linealizado:
%     G_dc = -C * A^-1 * B   (2x2)
%       G_dc(1,1) = u1 -> h3 (cruzado)
%       G_dc(1,2) = u2 -> h3 (directo)
%       G_dc(2,1) = u1 -> h4 (directo)
%       G_dc(2,2) = u2 -> h4 (cruzado)
%
%  Reordenamos segun el pairing usado (PI_1 controla h4 con u1, PI_2
%  controla h3 con u2):
%     G_pair = [g14 g24; g13 g23]
%  Diagonal = caminos directos, off-diagonal = caminos cruzados.
%
%  Desacoplador simplificado de Skogestad:
%      [u1] = [ 1    -k12 ] [v1]
%      [u2]   [-k21    1  ] [v2]
%
%  con k12 = G_pair(1,2)/G_pair(1,1)  y  k21 = G_pair(2,1)/G_pair(2,2).
% ========================================================================
G_dc = -Cc*(Ac\Bc);
G_pair = [G_dc(2,1) G_dc(2,2);    % fila 1: h4 con (u1,u2)
          G_dc(1,1) G_dc(1,2)];   % fila 2: h3 con (u1,u2)

k12 = G_pair(1,2)/G_pair(1,1);    % cancela el cruzado de u2 sobre h4
k21 = G_pair(2,1)/G_pair(2,2);    % cancela el cruzado de u1 sobre h3
D = [1, -k12; -k21, 1];

fprintf('\n=== Desacoplador estatico ===\n');
fprintf('  k12 = %.4f,  k21 = %.4f\n', k12, k21);
fprintf('  D = [ 1   %+.4f ]\n', -k12);
fprintf('      [ %+.4f   1 ]\n\n', -k21);

%% ========================================================================
%  4) PARAMETROS DE SIMULACION Y ESCENARIO
%  ------------------------------------------------------------------------
%  Escenario que evidencia el efecto del acoplamiento + ruido.
% ========================================================================
Ts = 2;
t_sim = 1500;
N_steps = round(t_sim/Ts);
t_vec = (0:N_steps-1)*Ts;

% --- Setpoint por tramos ---
ref = zeros(2, N_steps);             % fila 1 = ref h3, fila 2 = ref h4
ref(1,:) = 25;                       % h3 nominal todo el tiempo
ref(2,:) = 25;                       % h4 nominal todo el tiempo
ref(1, t_vec>=400) = 30;             % cambio h3: 25 -> 30 en t = 400
ref(2, t_vec>=800) = 20;             % cambio h4: 25 -> 20 en t = 800

% --- Activacion del ruido ---
t_ruido = 1100;                      % desde t=1100 se inyecta ruido
sigma_ruido = 0.3;                   % desviacion estandar (cm)

% --- Limites fisicos ---
u_max = [u10*2; u20*2];
u_min = [0; 0];

%% ========================================================================
%  5) BUCLE DE CONTROL: PI + DESACOPLADOR sobre la planta NO LINEAL
%  ------------------------------------------------------------------------
%  Arranque desde h = 0 (tanques vacios) para visualizar tambien el
%  llenado del sistema hacia el estacionario.
% ========================================================================
h_real = [0; 0; 0; 0];               % planta arranca vacia
u_prev = [0; 0];                     % bombas apagadas al inicio

e1_k1 = 0; e2_k1 = 0;

H_log = zeros(4, N_steps); H_log(:,1) = h_real;
U_log = zeros(2, N_steps);
V_log = zeros(2, N_steps);           % salidas internas de los PI antes del desacoplador

params = struct('A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
                'a1',a1,'a2',a2,'a3',a3,'a4',a4, ...
                'k1',k1,'k2',k2,'y1',y1,'y2',y2,'g',g);

rng(1);   % semilla para reproducibilidad del ruido

for k = 1:N_steps-1
    % --- Medicion (con ruido a partir de t = t_ruido) ---
    if t_vec(k) >= t_ruido
        y_med = h_real + [0;0; sigma_ruido*randn; sigma_ruido*randn];
    else
        y_med = h_real;
    end

    % --- Errores ---
    e1 = ref(2,k) - y_med(4);        % PI_1: error en h4
    e2 = ref(1,k) - y_med(3);        % PI_2: error en h3

    % --- Salidas de los PI (forma incremental) ---
    Dv1 = Kp1*(e1 - e1_k1) + (Kp1*Ts/Ti1)*e1;
    Dv2 = Kp2*(e2 - e2_k1) + (Kp2*Ts/Ti2)*e2;

    % --- DESACOPLADOR: combina ambas salidas y aplica a las bombas ---
    Du = D * [Dv1; Dv2];             % [Du1; Du2]
    u_actual = u_prev + Du;

    % --- Anti-windup por saturacion directa ---
    u_actual = max(min(u_actual, u_max), u_min);
    U_log(:,k) = u_actual;
    V_log(:,k) = [Dv1; Dv2];

    % --- Avanzar la planta NO LINEAL un periodo de muestreo ---
    [~, h_traj] = ode45(@(t,h) modelo_nolineal(t,h,u_actual,params), ...
                        [0 Ts], h_real);
    h_real = h_traj(end,:)';

    e1_k1 = e1; e2_k1 = e2;
    u_prev = u_actual;
    H_log(:,k+1) = h_real;
end
U_log(:,end) = u_actual;

%% ========================================================================
%  6) METRICAS DE DESEMPENO
% ========================================================================
e_h3 = ref(1,:) - H_log(3,:);
e_h4 = ref(2,:) - H_log(4,:);

IAE  = sum(abs(e_h3) + abs(e_h4))*Ts;
ISE  = sum(e_h3.^2 + e_h4.^2)*Ts;
ITAE = sum((abs(e_h3) + abs(e_h4)).*t_vec)*Ts;
esfuerzo = sum(sum(abs(diff(U_log,1,2))));

fprintf('=== Desempeno PI descentralizado + DESACOPLADOR ===\n');
fprintf('  IAE      = %.2f\n', IAE);
fprintf('  ISE      = %.2f\n', ISE);
fprintf('  ITAE     = %.2f\n', ITAE);
fprintf('  Esfuerzo = %.2f\n\n', esfuerzo);

%% ========================================================================
%  7) GRAFICAS
% ========================================================================
figure('Name','PI + Desacoplador','NumberTitle','off','Position',[100 100 950 700])

subplot(3,1,1)
plot(t_vec, H_log(3,:), 'b', 'LineWidth', 1.5); hold on;
stairs(t_vec, ref(1,:), 'r--', 'LineWidth', 1.2);
xline(400,'k:','SP h_3','LabelHorizontalAlignment','center');
xline(800,'k:','SP h_4');
xline(t_ruido,'m:','RUIDO');
ylabel('h_3 (cm)'); xlabel('Tiempo (s)'); grid on;
legend('h_3 medido','Referencia','Location','best');
title('Tanque 3 (controlado por PI_2 con desacoplador)');

subplot(3,1,2)
plot(t_vec, H_log(4,:), 'b', 'LineWidth', 1.5); hold on;
stairs(t_vec, ref(2,:), 'r--', 'LineWidth', 1.2);
xline(400,'k:','SP h_3','LabelHorizontalAlignment','center');
xline(800,'k:','SP h_4');
xline(t_ruido,'m:','RUIDO');
ylabel('h_4 (cm)'); xlabel('Tiempo (s)'); grid on;
legend('h_4 medido','Referencia','Location','best');
title('Tanque 4 (controlado por PI_1 con desacoplador)');

subplot(3,1,3)
stairs(t_vec, U_log(1,:), 'b', 'LineWidth', 1.3); hold on;
stairs(t_vec, U_log(2,:), 'r', 'LineWidth', 1.3);
yline(u_max(1),'k--'); yline(0,'k--');
ylabel('u (V)'); xlabel('Tiempo (s)'); grid on;
legend('u_1','u_2','Location','best');
title('Senales de control aplicadas a las bombas');

sgtitle('PI descentralizado + DESACOPLADOR sobre planta no lineal');

%% Guardar resultados para comparacion con GPC
save('resultados_PID.mat','t_vec','H_log','U_log','ref', ...
     'IAE','ISE','ITAE','esfuerzo', ...
     'Kp1','Ti1','Kp2','Ti2','D','t_ruido','sigma_ruido');
fprintf('Resultados guardados en resultados_PID.mat\n');

%% ========================================================================
%  FUNCION DEL MODELO NO LINEAL DE LA PLANTA
% ========================================================================
function dhdt = modelo_nolineal(~, h, u, p)
    h1=max(h(1),0); h2=max(h(2),0);
    h3=max(h(3),0); h4=max(h(4),0);
    u1=u(1); u2=u(2);

    dhdt = [-p.a1/p.A1*sqrt(2*p.g*h1) + (1-p.y2)*p.k2*u2/p.A1;
            -p.a2/p.A2*sqrt(2*p.g*h2) + (1-p.y1)*p.k1*u1/p.A2;
            -p.a3/p.A3*sqrt(2*p.g*h3) + p.a2/p.A3*sqrt(2*p.g*h2) + p.y2*p.k2*u2/p.A3;
            -p.a4/p.A4*sqrt(2*p.g*h4) + p.a1/p.A4*sqrt(2*p.g*h1) + p.y1*p.k1*u1/p.A4];
end
