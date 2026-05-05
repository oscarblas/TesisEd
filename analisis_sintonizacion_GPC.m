%% ========================================================================
%  analisis_sintonizacion_GPC.m
%  Comparacion y ranking de metodos de sintonizacion para el GPC MIMO
%  Sistema de 4 tanques acoplados
%
%  Metodos comparados:
%   1. Clarke-Mohtadi (1989)        - reglas clasicas conservadoras
%   2. Shridhar-Cooper (1997)       - lambda analitico via modelo FOPDT
%   3. Trierweiler-Farina           - basado en numero de condicion
%   4. Heuristico empirico          - reglas practicas con buen trade-off
%   5. Sintonizacion agresiva       - lambda muy bajo, alta velocidad
%   6. Optimizacion numerica        - fminsearch sobre indice IAE+esfuerzo
%
%  Indices de desempeno calculados para cada metodo:
%   - IAE  (Integral del Absolute Error)
%   - ISE  (Integral Squared Error)
%   - ITAE (Integral Time-weighted Absolute Error)
%   - Tiempo de establecimiento (al 2%)
%   - Sobreoscilacion maxima
%   - Esfuerzo total de control (variacion)
%
%  Ranking: cada metrica se normaliza a [0,1] (1 = peor), se ponderan y
%  se suma -> score (menor = mejor).
% ========================================================================

clear; clc; close all;

%% ========================================================================
%  PARAMETROS DE LA PLANTA (igual que controlador_GPC.m)
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

% Modelo lineal continuo
T1=A1/a1*sqrt(2*h10/g); T2=A2/a2*sqrt(2*h20/g);
T3=A3/a3*sqrt(2*h30/g); T4=A4/a4*sqrt(2*h40/g);

Ac = [-1/T1 0 0 0; 0 -1/T2 0 0;
       0 A2/(A3*T2) -1/T3 0; A1/(A4*T1) 0 0 -1/T4];
Bc = [0 (1-y2)*k2/A1; (1-y1)*k1/A2 0;
      0 y2*k2/A3; y1*k1/A4 0];
Cc = [0 0 1 0; 0 0 0 1];
Dc = zeros(2,2);

% Para metodos que requieren tiempo de subida o constante dominante:
% T_dom = mayor constante de tiempo del sistema
T_dom = max([T1 T2 T3 T4]);
fprintf('Constante de tiempo dominante: %.2f s\n', T_dom);

% Estructura comun de la planta (la pasamos a la funcion simular_GPC)
planta = struct('Ac',Ac,'Bc',Bc,'Cc',Cc,'Dc',Dc, ...
                'h0',h0,'u0',u0,'T_dom',T_dom, ...
                'A1',A1,'A2',A2,'A3',A3,'A4',A4, ...
                'a1',a1,'a2',a2,'a3',a3,'a4',a4, ...
                'k1',k1,'k2',k2,'y1',y1,'y2',y2,'g',g);

%% ========================================================================
%  ESCENARIO DE PRUEBA (mismo para todos los metodos)
% ========================================================================
t_sim   = 1500;   % duracion total
t_cambio = 500;   % instante donde cambia la referencia
ref_ini = [25; 25];
ref_fin = [30; 20];

escenario = struct('t_sim',t_sim,'t_cambio',t_cambio, ...
                   'ref_ini',ref_ini,'ref_fin',ref_fin);

%% ========================================================================
%  DEFINICION DE LOS METODOS DE SINTONIZACION
% ------------------------------------------------------------------------
%  Cada metodo devuelve una struct con: Ts, N, Nu, delta, lambda
% ========================================================================
metodos = {};

% --- Metodo 1: Clarke-Mohtadi (1989) ----------------------------------
% N1=1, N2 = ~ tiempo de subida, Nu = 1-3, lambda heuristico
% Para tanques: tiempo de subida ~ T_dom * 2.2, asi que N2 cubre eso
Ts_cm = round(T_dom/15);  if Ts_cm<1, Ts_cm=1; end
metodos{1} = struct('nombre','Clarke-Mohtadi', ...
    'Ts', Ts_cm, ...
    'N',  round(2.2*T_dom/Ts_cm), ...
    'Nu', 2, ...
    'delta',  [1 1], ...
    'lambda', [0.5 0.5]);

% --- Metodo 2: Shridhar-Cooper (1997) ---------------------------------
% lambda analitico:  lambda = (g_p^2)/(N * tr^2 * factor)
% Para MIMO usamos ganancia maxima de B
g_p = max(abs(Cc*(-Ac\Bc)),[],'all');   % ganancia estacionaria aproximada
tr_des = T_dom*0.5;   % tiempo de subida deseado (mas rapido que abierto)
Ts_sc = round(T_dom/20); if Ts_sc<1, Ts_sc=1; end
N_sc  = round(tr_des/Ts_sc);
lambda_sc = (g_p^2)/(N_sc * (tr_des/Ts_sc)^2 * 10);
metodos{2} = struct('nombre','Shridhar-Cooper', ...
    'Ts', Ts_sc, ...
    'N',  N_sc, ...
    'Nu', max(round(N_sc/5),3), ...
    'delta',  [1 1], ...
    'lambda', [lambda_sc lambda_sc]);

% --- Metodo 3: Trierweiler-Farina --------------------------------------
% Usa el numero de condicion de la matriz dinamica para escoger lambda
% lambda ~ k_cond_objetivo  (regla simplificada)
Ts_tf = round(T_dom/10); if Ts_tf<1, Ts_tf=1; end
metodos{3} = struct('nombre','Trierweiler-Farina', ...
    'Ts', Ts_tf, ...
    'N',  round(1.5*T_dom/Ts_tf), ...
    'Nu', 5, ...
    'delta',  [1 1], ...
    'lambda', [0.1 0.1]);

% --- Metodo 4: Heuristico empirico (lo que tenias antes) --------------
metodos{4} = struct('nombre','Heuristico empirico', ...
    'Ts', 2, ...
    'N',  50, ...
    'Nu', 10, ...
    'delta',  [10 10], ...
    'lambda', [0.01 0.01]);

% --- Metodo 5: Sintonizacion agresiva ---------------------------------
metodos{5} = struct('nombre','Agresivo', ...
    'Ts', 1, ...
    'N',  60, ...
    'Nu', 15, ...
    'delta',  [50 50], ...
    'lambda', [0.001 0.001]);

% --- Metodo 6: Optimizacion numerica (fminsearch) ---------------------
% Optimizamos [log10(lambda), Nu] minimizando un costo combinado
fprintf('Ejecutando optimizacion numerica (puede tardar)...\n');
Ts_opt = 2;
N_opt  = 50;
delta_opt = [10 10];

obj = @(x) costo_optimizacion(x, Ts_opt, N_opt, delta_opt, planta, escenario);
x0 = [log10(0.01), 10];                % [log10(lambda), Nu]
opciones = optimset('Display','off','MaxIter',15,'TolX',0.5);
x_opt = fminsearch(obj, x0, opciones);

lambda_optim = 10^x_opt(1);
Nu_optim = max(round(x_opt(2)),1);

metodos{6} = struct('nombre','Optimizacion numerica', ...
    'Ts', Ts_opt, ...
    'N',  N_opt, ...
    'Nu', Nu_optim, ...
    'delta',  delta_opt, ...
    'lambda', [lambda_optim lambda_optim]);

%% ========================================================================
%  EJECUCION DE TODOS LOS METODOS Y CALCULO DE METRICAS
% ========================================================================
n_met = length(metodos);
resultados = struct();

fprintf('\nEjecutando los %d metodos de sintonizacion...\n', n_met);
for i = 1:n_met
    fprintf('  [%d/%d] %s ...', i, n_met, metodos{i}.nombre);
    [hist, m] = simular_GPC(metodos{i}, planta, escenario);
    resultados(i).nombre  = metodos{i}.nombre;
    resultados(i).params  = metodos{i};
    resultados(i).hist    = hist;
    resultados(i).metricas= m;
    fprintf(' OK\n');
end

%% ========================================================================
%  RANKING: NORMALIZAR METRICAS Y COMBINAR EN UN SCORE
% ------------------------------------------------------------------------
%  Cada metrica: 0 = mejor, 1 = peor (normalizacion min-max)
%  Score combinado:
%    score = w1*IAE + w2*ISE + w3*ITAE + w4*ts + w5*overshoot + w6*esfuerzo
% ========================================================================
campos = {'IAE','ISE','ITAE','ts','overshoot','esfuerzo'};
pesos  = [0.20  0.15  0.15  0.20  0.15      0.15];

M = zeros(n_met, length(campos));
for i = 1:n_met
    for j = 1:length(campos)
        M(i,j) = resultados(i).metricas.(campos{j});
    end
end

% Normalizacion min-max por columna
M_norm = (M - min(M)) ./ (max(M) - min(M) + eps);

% Score ponderado (menor = mejor)
score = M_norm * pesos';

% Ordenar de mejor a peor
[score_sort, idx_sort] = sort(score, 'ascend');

%% ========================================================================
%  TABLA DE RESULTADOS
% ========================================================================
fprintf('\n========================================================\n');
fprintf('  RANKING DE METODOS DE SINTONIZACION (mejor a peor)\n');
fprintf('========================================================\n');

T_res = table();
for k = 1:n_met
    i = idx_sort(k);
    fila = table(k, ...
                 string(resultados(i).nombre), ...
                 resultados(i).params.Ts, ...
                 resultados(i).params.N, ...
                 resultados(i).params.Nu, ...
                 resultados(i).params.lambda(1), ...
                 resultados(i).metricas.IAE, ...
                 resultados(i).metricas.ts, ...
                 resultados(i).metricas.overshoot, ...
                 score(i), ...
        'VariableNames', {'Pos','Metodo','Ts','N','Nu','lambda','IAE','t_est','overshoot_pct','Score'});
    T_res = [T_res; fila];
end
disp(T_res);

%% ========================================================================
%  GRAFICAS COMPARATIVAS
% ========================================================================
colores = lines(n_met);

figure('Name','Comparacion - h_3','NumberTitle','off')
for k = 1:n_met
    i = idx_sort(k);
    plot(resultados(i).hist.t, resultados(i).hist.H(3,:), ...
         'Color', colores(k,:), 'LineWidth', 1.4); hold on;
end
stairs(resultados(1).hist.t, resultados(1).hist.ref(1,:), 'k--', 'LineWidth', 1.5);
ylabel('h_3 (cm)'); xlabel('Tiempo (s)'); grid on;
legend([{resultados(idx_sort).nombre}, {'Referencia'}], 'Location','best');
title('Respuesta en h_3 (ordenado de mejor a peor)');

figure('Name','Comparacion - h_4','NumberTitle','off')
for k = 1:n_met
    i = idx_sort(k);
    plot(resultados(i).hist.t, resultados(i).hist.H(4,:), ...
         'Color', colores(k,:), 'LineWidth', 1.4); hold on;
end
stairs(resultados(1).hist.t, resultados(1).hist.ref(2,:), 'k--', 'LineWidth', 1.5);
ylabel('h_4 (cm)'); xlabel('Tiempo (s)'); grid on;
legend([{resultados(idx_sort).nombre}, {'Referencia'}], 'Location','best');
title('Respuesta en h_4 (ordenado de mejor a peor)');

figure('Name','Comparacion - Esfuerzo de control','NumberTitle','off')
subplot(2,1,1)
for k = 1:n_met
    i = idx_sort(k);
    stairs(resultados(i).hist.t, resultados(i).hist.U(1,:), ...
           'Color', colores(k,:), 'LineWidth', 1.2); hold on;
end
ylabel('u_1'); xlabel('Tiempo (s)'); grid on;
legend({resultados(idx_sort).nombre},'Location','best');
title('Senal de control u_1');

subplot(2,1,2)
for k = 1:n_met
    i = idx_sort(k);
    stairs(resultados(i).hist.t, resultados(i).hist.U(2,:), ...
           'Color', colores(k,:), 'LineWidth', 1.2); hold on;
end
ylabel('u_2'); xlabel('Tiempo (s)'); grid on;

% Grafica de barras del score
figure('Name','Score combinado','NumberTitle','off')
bar(score(idx_sort));
set(gca, 'XTickLabel', {resultados(idx_sort).nombre}, 'XTickLabelRotation', 30);
ylabel('Score (menor = mejor)'); grid on;
title('Ranking final de metodos de sintonizacion');

fprintf('\nMejor metodo: %s\n', resultados(idx_sort(1)).nombre);
fprintf('Peor metodo: %s\n\n', resultados(idx_sort(end)).nombre);


%% ========================================================================
%  ============= FUNCIONES AUXILIARES =====================================
%  ========================================================================

function [hist, m] = simular_GPC(p, planta, esc)
% Simula el GPC con los parametros dados sobre la planta no lineal.
% Retorna historial e indices de desempeno.

    % Discretizar
    Ts = p.Ts;
    sys_d = c2d(ss(planta.Ac, planta.Bc, planta.Cc, planta.Dc), Ts, 'zoh');
    [Ad, Bd, Cd, ~] = ssdata(sys_d);
    nx = size(Ad,1); nu = size(Bd,2); ny = size(Cd,1);

    % Modelo aumentado
    A_t = [Ad zeros(nx,ny); Cd*Ad eye(ny)];
    B_t = [Bd; Cd*Bd];
    C_t = [zeros(ny,nx) eye(ny)];

    % Matrices de prediccion
    N = p.N; Nu = p.Nu;
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

    % Pesos
    Q = kron(eye(N),  diag(p.delta));
    R = kron(eye(Nu), diag(p.lambda));
    H = 2*(Phi'*Q*Phi + R); H = (H+H')/2;

    % Restricciones
    Du_max=[100;100]; u_max = planta.u0*2; u_min=[0;0];
    T_mat = kron(tril(ones(Nu)), eye(nu));
    ones_blk = repmat(eye(nu), Nu, 1);
    A_ineq = [eye(Nu*nu); -eye(Nu*nu); T_mat; -T_mat];
    Du_max_v = repmat(Du_max,Nu,1); Du_min_v = -Du_max_v;
    u_max_v = repmat(u_max,Nu,1); u_min_v = repmat(u_min,Nu,1);

    % Tiempo
    N_steps = round(esc.t_sim/Ts);
    t_vec = (0:N_steps-1)*Ts;
    ref = zeros(ny, N_steps);
    k_chg = round(esc.t_cambio/Ts);
    ref(:,1:k_chg)     = repmat(esc.ref_ini, 1, k_chg);
    ref(:,k_chg+1:end) = repmat(esc.ref_fin, 1, N_steps-k_chg);

    % Inicializacion
    h_real = planta.h0; u_prev = planta.u0;
    x_lin_ant = zeros(nx,1);
    H_log = zeros(4,N_steps); H_log(:,1) = h_real;
    U_log = zeros(nu,N_steps);

    pn = struct('A1',planta.A1,'A2',planta.A2,'A3',planta.A3,'A4',planta.A4,...
                'a1',planta.a1,'a2',planta.a2,'a3',planta.a3,'a4',planta.a4,...
                'k1',planta.k1,'k2',planta.k2,'y1',planta.y1,'y2',planta.y2,'g',planta.g);

    opts = optimoptions('quadprog','Display','off');
    y0 = planta.h0(3:4);

    for k=1:N_steps-1
        x_lin = h_real - planta.h0;
        Dx = x_lin - x_lin_ant;
        y_lin = Cd*x_lin;
        xi = [Dx; y_lin];

        W = zeros(N*ny,1);
        for j=1:N
            idx = min(k+j, N_steps);
            W((j-1)*ny+1:j*ny) = ref(:,idx) - y0;
        end

        b_ineq = [Du_max_v; -Du_min_v;
                  u_max_v - ones_blk*u_prev;
                  -u_min_v + ones_blk*u_prev];

        f_qp = -2*(W - F*xi)'*Q*Phi; f_qp = f_qp(:);
        [DU,~,ef] = quadprog(H, f_qp, A_ineq, b_ineq, [],[],[],[],[],opts);
        if ef~=1, DU = zeros(Nu*nu,1); end

        u_act = u_prev + DU(1:nu);
        u_act = max(min(u_act,u_max),u_min);
        U_log(:,k) = u_act;

        [~, h_traj] = ode45(@(tt,h) modelo_nl(tt,h,u_act,pn), [0 Ts], h_real);
        h_real = h_traj(end,:)';

        x_lin_ant = x_lin;
        u_prev = u_act;
        H_log(:,k+1) = h_real;
    end
    U_log(:,end) = u_prev;

    hist = struct('t',t_vec,'H',H_log,'U',U_log,'ref',ref);
    m = calcular_metricas(hist, esc);
end


function m = calcular_metricas(hist, esc)
% Calcula los indices de desempeno a partir del historial.
    t = hist.t; ref = hist.ref;
    y = hist.H(3:4,:);              % salidas controladas
    e = ref - y;                    % error

    Ts = t(2)-t(1);
    m.IAE  = sum(sum(abs(e)))*Ts;
    m.ISE  = sum(sum(e.^2))*Ts;
    m.ITAE = sum(sum(abs(e).*t))*Ts;

    % Tiempo de establecimiento (al 2% de la magnitud del cambio)
    k_chg = find(t >= esc.t_cambio, 1);
    delta_ref = abs(esc.ref_fin - esc.ref_ini);
    band = 0.02 * max(delta_ref);
    ts_canal = zeros(2,1);
    for ch=1:2
        err_ch = abs(y(ch,k_chg:end) - ref(ch,k_chg:end));
        idx_fuera = find(err_ch > band, 1, 'last');
        if isempty(idx_fuera), ts_canal(ch) = 0;
        else, ts_canal(ch) = t(k_chg+idx_fuera-1) - esc.t_cambio;
        end
    end
    m.ts = max(ts_canal);

    % Sobreoscilacion (% sobre el cambio)
    overshoot_canal = zeros(2,1);
    for ch=1:2
        if esc.ref_fin(ch) >= esc.ref_ini(ch)
            ov = max(y(ch,k_chg:end)) - esc.ref_fin(ch);
        else
            ov = esc.ref_fin(ch) - min(y(ch,k_chg:end));
        end
        overshoot_canal(ch) = max(ov,0)/max(delta_ref(ch),eps)*100;
    end
    m.overshoot = max(overshoot_canal);

    % Esfuerzo de control: variacion total
    dU = diff(hist.U,1,2);
    m.esfuerzo = sum(sum(abs(dU)));
end


function J = costo_optimizacion(x, Ts, N, delta, planta, esc)
% Costo para fminsearch: combina IAE y esfuerzo
    lambda = 10^x(1);
    Nu = max(round(x(2)),1);
    if Nu > N, Nu = N; end
    p = struct('Ts',Ts,'N',N,'Nu',Nu,'delta',delta,'lambda',[lambda lambda]);
    try
        [~, m] = simular_GPC(p, planta, esc);
        J = m.IAE + 0.1*m.esfuerzo + 100*m.overshoot;
    catch
        J = 1e10;
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
