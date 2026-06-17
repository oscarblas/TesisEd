%% ========================================================================
%  simulaciones_cap4.m
%  Simulaciones de los 6 escenarios del Capitulo 4 para la comparacion
%  cuantitativa entre el controlador GPC (Cap. 3) y un PID descentralizado
%  sintonizado por Internal Model Control (Cap. 4.2).
%
%  Los 6 escenarios son:
%    1) Caso nominal con cambios de referencia independientes
%    2) Referencias cruzadas (cambios simultaneos opuestos)
%    3) Perturbacion externa: fuga en TK-03
%    4) Ruido de medicion en sensores
%    5) Saturacion de actuadores
%    6) Cambio del punto de operacion
%
%  Para cada escenario se calculan IAE, ISE, ITAE, tiempo de establecimiento,
%  sobrepico, esfuerzo de control y tiempo de ejecucion. Adicionalmente, en
%  el Escenario 2 se calcula la metrica de acoplamiento cruzado INT_ij.
% ========================================================================

clear; clc; close all;

%% ========================================================================
%  PLANTA: parametros fisicos y punto de operacion (mismos del Cap. 2)
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

T1=A1/a1*sqrt(2*h10/g);
T2=A2/a2*sqrt(2*h20/g);
T3=A3/a3*sqrt(2*h30/g);
T4=A4/a4*sqrt(2*h40/g);

% Modelo lineal continuo (para el GPC)
Ac = [-1/T1 0 0 0; 0 -1/T2 0 0;
       0 A2/(A3*T2) -1/T3 0; A1/(A4*T1) 0 0 -1/T4];
Bc = [0 (1-y2)*k2/A1; (1-y1)*k1/A2 0;
      0 y2*k2/A3; y1*k1/A4 0];
Cc = [0 0 1 0; 0 0 0 1];
Dc = zeros(2,2);

% Limites fisicos
u_max = [u10*2; u20*2];
u_min = [0; 0];

% Empaquetar parametros para las funciones
P.A1=A1; P.A2=A2; P.A3=A3; P.A4=A4;
P.a1=a1; P.a2=a2; P.a3=a3; P.a4=a4;
P.k1=k1; P.k2=k2; P.y1=y1; P.y2=y2; P.g=g;
P.u10=u10; P.u20=u20; P.h0=h0; P.h30=h30; P.h40=h40;
P.u_max=u_max; P.u_min=u_min;
P.Ac=Ac; P.Bc=Bc; P.Cc=Cc; P.Dc=Dc;
P.T1=T1; P.T2=T2; P.T3=T3; P.T4=T4;

%% ========================================================================
%  CONTROLADOR GPC: parametros (ganadores del analisis de sintonizacion)
% ========================================================================
GPC.Ts     = 1;
GPC.N      = 50;
GPC.Nu     = 5;
GPC.delta  = [10 10];
GPC.lambda = [0.0076803 0.0076803];
GPC.Du_max = [100; 100];

%% ========================================================================
%  CONTROLADOR PID: sintonizacion IMC (seccion 4.2.2)
% ========================================================================
PID.Ts = 1;
PID.K1   = y1*k1*T4/A4;
PID.tau1 = T4;
PID.lam1 = PID.tau1/3;
PID.Kp1  = PID.tau1/(PID.K1*PID.lam1);
PID.Ti1  = PID.tau1;

PID.K2   = y2*k2*T3/A3;
PID.tau2 = T3;
PID.lam2 = PID.tau2/3;
PID.Kp2  = PID.tau2/(PID.K2*PID.lam2);
PID.Ti2  = PID.tau2;

fprintf('=== Sintonizacion PID por IMC ===\n');
fprintf('  Lazo 1 (u1 -> h4): Kp = %.3f,  Ti = %.2f s\n', PID.Kp1, PID.Ti1);
fprintf('  Lazo 2 (u2 -> h3): Kp = %.3f,  Ti = %.2f s\n\n', PID.Kp2, PID.Ti2);

%% ========================================================================
%  DEFINICION DE LOS 6 ESCENARIOS
% ========================================================================
escenarios = cell(6,1);

%% --- Escenario 1: Caso nominal (cambios independientes) ---------------
e1.nombre = 'Escenario 1: Caso nominal';
e1.t_sim  = 1500;
e1.ref_fun = @(t) ref_indep_h3_h4(t, 300, 900);   % cambia h3 en 300, h4 en 900
e1.fuga    = false;
e1.ruido   = 0;
e1.sat_ref = false;
escenarios{1} = e1;

%% --- Escenario 2: Referencias cruzadas --------------------------------
e2.nombre = 'Escenario 2: Referencias cruzadas';
e2.t_sim  = 1500;
e2.ref_fun = @(t) ref_cruzada(t, 500);            % h3:25->30 y h4:25->20 simultaneo
e2.fuga    = false;
e2.ruido   = 0;
e2.sat_ref = false;
escenarios{2} = e2;

%% --- Escenario 3: Fuga en TK-03 ---------------------------------------
e3.nombre = 'Escenario 3: Fuga en TK-03';
e3.t_sim  = 1500;
e3.ref_fun = @(t) [25; 25];                       % setpoint nominal constante
e3.fuga    = true;     % d(t) = 1/60 cm/s para t >= 600
e3.t_fuga  = 600;
e3.d_fuga  = 1/60;
e3.ruido   = 0;
e3.sat_ref = false;
escenarios{3} = e3;

%% --- Escenario 4: Ruido en sensor (cruzadas + ruido) ------------------
e4.nombre = 'Escenario 4: Ruido en sensores';
e4.t_sim  = 1500;
e4.ref_fun = @(t) ref_cruzada(t, 500);
e4.fuga    = false;
e4.ruido   = 0.3;       % desviacion estandar del ruido en cm
e4.sat_ref = false;
escenarios{4} = e4;

%% --- Escenario 5: Saturacion de actuadores ----------------------------
e5.nombre = 'Escenario 5: Saturacion de actuadores';
e5.t_sim  = 1500;
e5.ref_fun = @(t) ref_saturacion(t, 500);         % h3 -> 45cm (agresivo)
e5.fuga    = false;
e5.ruido   = 0;
e5.sat_ref = true;
escenarios{5} = e5;

%% --- Escenario 6: Cambio del punto de operacion -----------------------
e6.nombre = 'Escenario 6: Cambio del punto de operacion';
e6.t_sim  = 1500;
e6.ref_fun = @(t) ref_punto_operacion(t, 500);    % h3 y h4 a 35cm
e6.fuga    = false;
e6.ruido   = 0;
e6.sat_ref = false;
escenarios{6} = e6;

%% ========================================================================
%  EJECUCION DE LOS 6 ESCENARIOS
% ========================================================================
resultados = struct();

for s = 1:6
    fprintf('\n========================================================\n');
    fprintf('  %s\n', escenarios{s}.nombre);
    fprintf('========================================================\n');

    % --- Simular GPC ---
    fprintf('  Ejecutando GPC...\n');
    [t_g, H_g, U_g, te_g] = simular_GPC(escenarios{s}, P, GPC);
    m_g = calcular_metricas(t_g, H_g, U_g, escenarios{s}, te_g);
    fprintf('    GPC: IAE=%.2f  t_est=%.1f  M_p=%.2f%%  Esf=%.1f\n', ...
            m_g.IAE, m_g.t_est, m_g.M_p, m_g.esfuerzo);

    % --- Simular PID ---
    fprintf('  Ejecutando PID...\n');
    [t_p, H_p, U_p, te_p] = simular_PID(escenarios{s}, P, PID);
    m_p = calcular_metricas(t_p, H_p, U_p, escenarios{s}, te_p);
    fprintf('    PID: IAE=%.2f  t_est=%.1f  M_p=%.2f%%  Esf=%.1f\n', ...
            m_p.IAE, m_p.t_est, m_p.M_p, m_p.esfuerzo);

    % --- Almacenar resultados ---
    resultados(s).nombre = escenarios{s}.nombre;
    resultados(s).t      = t_g;
    resultados(s).H_gpc  = H_g; resultados(s).U_gpc = U_g;
    resultados(s).H_pid  = H_p; resultados(s).U_pid = U_p;
    resultados(s).m_gpc  = m_g; resultados(s).m_pid = m_p;
    resultados(s).ref    = cell2mat(arrayfun(@(tt) escenarios{s}.ref_fun(tt), ...
                                             t_g, 'UniformOutput', false));

    % --- Graficar comparacion ---
    graficar_comparacion(t_g, H_g, U_g, H_p, U_p, ...
                         resultados(s).ref, escenarios{s}.nombre, P.u_max);
end

%% ========================================================================
%  METRICA DE ACOPLAMIENTO CRUZADO (solo Escenario 2)
% ========================================================================
fprintf('\n========================================================\n');
fprintf('  METRICA DE ACOPLAMIENTO CRUZADO (Escenario 2)\n');
fprintf('========================================================\n');

% Ventana de evaluacion: desde el cambio (t=500) hasta t=500 + DT
DT = 300;     % ventana de 300 segundos despues del cambio
t = resultados(2).t;
ref = resultados(2).ref;
delta_r3 = 5;   delta_r4 = 5;     % cambios nominales en cm

idx_window = (t >= 500) & (t <= 500 + DT);

% Calcular INT para GPC
e3_gpc = ref(1,:) - resultados(2).H_gpc(3,:);
e4_gpc = ref(2,:) - resultados(2).H_gpc(4,:);
INT_3_gpc = sum(abs(e3_gpc(idx_window))) * GPC.Ts / delta_r4;
INT_4_gpc = sum(abs(e4_gpc(idx_window))) * GPC.Ts / delta_r3;

% Calcular INT para PID
e3_pid = ref(1,:) - resultados(2).H_pid(3,:);
e4_pid = ref(2,:) - resultados(2).H_pid(4,:);
INT_3_pid = sum(abs(e3_pid(idx_window))) * PID.Ts / delta_r4;
INT_4_pid = sum(abs(e4_pid(idx_window))) * PID.Ts / delta_r3;

fprintf('  INT_3 (afectacion de h3 por cambio de r4):\n');
fprintf('    GPC = %.2f      PID = %.2f      Razon PID/GPC = %.2f\n', ...
        INT_3_gpc, INT_3_pid, INT_3_pid/INT_3_gpc);
fprintf('  INT_4 (afectacion de h4 por cambio de r3):\n');
fprintf('    GPC = %.2f      PID = %.2f      Razon PID/GPC = %.2f\n', ...
        INT_4_gpc, INT_4_pid, INT_4_pid/INT_4_gpc);

%% ========================================================================
%  TABLA RESUMEN FINAL DE METRICAS (Tabla 4.2)
%  --- GLOBALES (incluyen el arranque desde h = 0) ---
% ========================================================================
fprintf('\n========================================================\n');
fprintf('  TABLA 4.2.A: METRICAS GLOBALES POR ESCENARIO\n');
fprintf('========================================================\n');
fprintf('%-15s %10s %10s %10s %10s %10s %10s\n', ...
        'Escenario', 'IAE_GPC', 'IAE_PID', 't_GPC', 't_PID', 'M_p_GPC', 'M_p_PID');
for s = 1:6
    fprintf('%-15s %10.2f %10.2f %10.1f %10.1f %10.2f %10.2f\n', ...
            sprintf('Esc. %d', s), ...
            resultados(s).m_gpc.IAE, resultados(s).m_pid.IAE, ...
            resultados(s).m_gpc.t_est, resultados(s).m_pid.t_est, ...
            resultados(s).m_gpc.M_p,   resultados(s).m_pid.M_p);
end

%% ========================================================================
%  TABLA RESUMEN FINAL DE METRICAS (Tabla 4.2)
%  --- OPERACION NORMAL (t >= 400 s, EXCLUYE el arranque) ---
%  Esta es la tabla relevante para evaluar el desempeno del controlador
%  en regimen operativo, donde se aprecian los efectos de acoplamiento.
% ========================================================================
fprintf('\n========================================================\n');
fprintf('  TABLA 4.2.B: METRICAS EN OPERACION NORMAL (t >= 400 s)\n');
fprintf('========================================================\n');
fprintf('%-15s %12s %12s %12s %12s\n', ...
        'Escenario', 'IAE_op_GPC', 'IAE_op_PID', 'ISE_op_GPC', 'ISE_op_PID');
for s = 1:6
    fprintf('%-15s %12.2f %12.2f %12.2f %12.2f\n', ...
            sprintf('Esc. %d', s), ...
            resultados(s).m_gpc.IAE_op, resultados(s).m_pid.IAE_op, ...
            resultados(s).m_gpc.ISE_op, resultados(s).m_pid.ISE_op);
end

%% ========================================================================
%  COSTO COMPUTACIONAL (Tabla 4.4)
% ========================================================================
fprintf('\n========================================================\n');
fprintf('  TABLA 4.4: COSTO COMPUTACIONAL (ms por iteracion)\n');
fprintf('========================================================\n');
fprintf('%-30s %15s %15s\n', 'Controlador', 't_exec_prom (ms)', 't_exec_max (ms)');
% Tomar el promedio sobre los 6 escenarios
te_g_avg = mean(arrayfun(@(s) mean(resultados(s).m_gpc.t_exec)*1000, 1:6));
te_g_max = max (arrayfun(@(s) max (resultados(s).m_gpc.t_exec)*1000, 1:6));
te_p_avg = mean(arrayfun(@(s) mean(resultados(s).m_pid.t_exec)*1000, 1:6));
te_p_max = max (arrayfun(@(s) max (resultados(s).m_pid.t_exec)*1000, 1:6));
fprintf('%-30s %15.4f %15.4f\n', 'GPC', te_g_avg, te_g_max);
fprintf('%-30s %15.4f %15.4f\n', 'PID', te_p_avg, te_p_max);

% Guardar todo para post-procesamiento
save('resultados_cap4.mat', 'resultados', 'GPC', 'PID', 'P', ...
     'INT_3_gpc','INT_4_gpc','INT_3_pid','INT_4_pid');
fprintf('\nResultados guardados en resultados_cap4.mat\n');


%% ========================================================================
%  ============= FUNCIONES DE REFERENCIA ==================================
%  ========================================================================
function r = ref_indep_h3_h4(t, t1, t2)
    r = [25; 25];
    if t >= t1, r(1) = 30; end
    if t >= t2, r(2) = 20; end
end

function r = ref_cruzada(t, tc)
    r = [25; 25];
    if t >= tc, r = [30; 20]; end
end

function r = ref_saturacion(t, tc)
    r = [25; 25];
    if t >= tc, r(1) = 45; end    % setpoint agresivo
end

function r = ref_punto_operacion(t, tc)
    r = [25; 25];
    if t >= tc, r = [35; 35]; end
end


%% ========================================================================
%  ============= FUNCION DE SIMULACION DEL GPC ===========================
%  ========================================================================
function [t_vec, H_log, U_log, t_exec] = simular_GPC(esc, P, GPC)
    Ts = GPC.Ts; N = GPC.N; Nu = GPC.Nu;
    nu = 2; ny = 2;

    % Discretizacion y construccion de G (formulacion CARIMA)
    sys_d = c2d(ss(P.Ac,P.Bc,P.Cc,P.Dc), Ts, 'zoh');
    [Ad, Bd, Cd, ~] = ssdata(sys_d);
    G_z = tf(sys_d);
    t_step = (0:N)*Ts;
    g_step = cell(ny,nu);
    for i = 1:ny
        for j = 1:nu
            y_step_ij = step(G_z(i,j), t_step);
            g_step{i,j} = y_step_ij(2:end);
        end
    end
    G = zeros(ny*N, nu*Nu);
    for i = 1:ny
        for j = 1:nu
            Gb = zeros(N, Nu);
            for r = 1:N
                for c = 1:Nu
                    if r >= c, Gb(r,c) = g_step{i,j}(r-c+1); end
                end
            end
            G((i-1)*N+(1:N), (j-1)*Nu+(1:Nu)) = Gb;
        end
    end
    Q = blkdiag(GPC.delta(1)*eye(N),  GPC.delta(2)*eye(N));
    R = blkdiag(GPC.lambda(1)*eye(Nu), GPC.lambda(2)*eye(Nu));
    H_qp = 2*(G'*Q*G + R); H_qp = (H_qp+H_qp')/2;

    Du_max_v = [repmat(GPC.Du_max(1),Nu,1); repmat(GPC.Du_max(2),Nu,1)];
    Du_min_v = -Du_max_v;
    u_max_v  = [repmat(P.u_max(1),Nu,1);    repmat(P.u_max(2),Nu,1)];
    u_min_v  = [repmat(P.u_min(1),Nu,1);    repmat(P.u_min(2),Nu,1)];
    T_mat = blkdiag(tril(ones(Nu)), tril(ones(Nu)));
    A_ineq = [eye(nu*Nu); -eye(nu*Nu); T_mat; -T_mat];

    % Tiempo
    N_steps = round(esc.t_sim/Ts);
    t_vec = (0:N_steps-1)*Ts;
    H_log = zeros(4, N_steps);
    U_log = zeros(nu, N_steps);
    t_exec = zeros(N_steps,1);

    h_real = P.h0;
    u_prev = [P.u10; P.u20];
    H_log(:,1) = h_real;

    opts = optimoptions('quadprog','Display','off');

    for k = 1:N_steps-1
        tic_local = tic;

        % Medicion (con ruido si aplica)
        if esc.ruido > 0
            y_med = h_real + [0;0; esc.ruido*randn; esc.ruido*randn];
        else
            y_med = h_real;
        end

        % Variables desviadas (usando medicion ruidosa para realismo)
        x_des = y_med - P.h0;
        u_prev_des = u_prev - [P.u10; P.u20];

        % Respuesta libre F
        F_vec = zeros(ny*N, 1);
        x_temp = x_des;
        for j = 1:N
            x_temp = Ad*x_temp + Bd*u_prev_des;
            y_pred = Cd*x_temp;
            F_vec(j)     = y_pred(1);
            F_vec(N + j) = y_pred(2);
        end

        % Referencia futura constante
        r_act = esc.ref_fun(t_vec(k));
        r_des = r_act - [P.h30; P.h40];
        W = [repmat(r_des(1),N,1); repmat(r_des(2),N,1)];

        % QP
        f_qp = 2*G'*Q*(F_vec - W);
        u_prev_stack = [repmat(u_prev(1),Nu,1); repmat(u_prev(2),Nu,1)];
        b_ineq = [Du_max_v; -Du_min_v;
                  u_max_v - u_prev_stack;
                 -u_min_v + u_prev_stack];
        [DU,~,ef] = quadprog(H_qp, f_qp, A_ineq, b_ineq, [],[],[],[],[],opts);
        if ef<=0 || isempty(DU), DU = zeros(nu*Nu,1); end

        Du_aplicado = [DU(1); DU(Nu+1)];
        u_act = u_prev + Du_aplicado;
        u_act = max(min(u_act, P.u_max), P.u_min);
        U_log(:,k) = u_act;

        % Simular planta no lineal (con fuga si aplica)
        if esc.fuga && t_vec(k) >= esc.t_fuga
            dfun = @(t,h) modelo_nl(t,h,u_act,P) - [0;0; esc.d_fuga;0];
        else
            dfun = @(t,h) modelo_nl(t,h,u_act,P);
        end
        [~, h_traj] = ode45(dfun, [0 Ts], h_real);
        h_real = h_traj(end,:)';

        u_prev = u_act;
        H_log(:,k+1) = h_real;

        t_exec(k) = toc(tic_local);
    end
    U_log(:,end) = u_prev;
end


%% ========================================================================
%  ============= FUNCION DE SIMULACION DEL PID ===========================
%  ========================================================================
function [t_vec, H_log, U_log, t_exec] = simular_PID(esc, P, PID)
    Ts = PID.Ts;
    N_steps = round(esc.t_sim/Ts);
    t_vec = (0:N_steps-1)*Ts;
    H_log = zeros(4, N_steps);
    U_log = zeros(2, N_steps);
    t_exec = zeros(N_steps,1);

    h_real = P.h0;
    u_prev = [P.u10; P.u20];
    H_log(:,1) = h_real;

    e1_k1=0; e2_k1=0;

    for k = 1:N_steps-1
        tic_local = tic;

        % Medicion (con ruido si aplica)
        if esc.ruido > 0
            y_med = h_real + [0;0; esc.ruido*randn; esc.ruido*randn];
        else
            y_med = h_real;
        end

        % Referencias
        r_act = esc.ref_fun(t_vec(k));
        ref_h3 = r_act(1);  ref_h4 = r_act(2);

        % Errores
        e1 = ref_h4 - y_med(4);   % PID1: u1 -> h4
        e2 = ref_h3 - y_med(3);   % PID2: u2 -> h3

        % Forma incremental (PI, Td=0)
        Du1 = PID.Kp1*(e1 - e1_k1) + (PID.Kp1*Ts/PID.Ti1)*e1;
        Du2 = PID.Kp2*(e2 - e2_k1) + (PID.Kp2*Ts/PID.Ti2)*e2;

        u_act = u_prev + [Du1; Du2];
        u_act = max(min(u_act, P.u_max), P.u_min);  % anti-windup
        U_log(:,k) = u_act;

        % Simular planta no lineal (con fuga si aplica)
        if esc.fuga && t_vec(k) >= esc.t_fuga
            dfun = @(t,h) modelo_nl(t,h,u_act,P) - [0;0; esc.d_fuga;0];
        else
            dfun = @(t,h) modelo_nl(t,h,u_act,P);
        end
        [~, h_traj] = ode45(dfun, [0 Ts], h_real);
        h_real = h_traj(end,:)';

        e1_k1 = e1;  e2_k1 = e2;
        u_prev = u_act;
        H_log(:,k+1) = h_real;

        t_exec(k) = toc(tic_local);
    end
    U_log(:,end) = u_prev;
end


%% ========================================================================
%  ============= CALCULO DE METRICAS =====================================
%  ========================================================================
function m = calcular_metricas(t, H, U, esc, t_exec)
    Ts = t(2) - t(1);
    ref = cell2mat(arrayfun(@(tt) esc.ref_fun(tt), t, 'UniformOutput', false));
    e3 = ref(1,:) - H(3,:);
    e4 = ref(2,:) - H(4,:);

    % Metricas globales (toda la simulacion)
    m.IAE  = sum(abs(e3) + abs(e4))*Ts;
    m.ISE  = sum(e3.^2 + e4.^2)*Ts;
    m.ITAE = sum((abs(e3) + abs(e4)).*t)*Ts;

    % Metricas en operacion normal (a partir de t = 400 s)
    t_eval = 400;
    k_ev = find(t >= t_eval, 1, 'first');
    if ~isempty(k_ev)
        m.IAE_op  = sum(abs(e3(k_ev:end)) + abs(e4(k_ev:end)))*Ts;
        m.ISE_op  = sum(e3(k_ev:end).^2 + e4(k_ev:end).^2)*Ts;
        m.ITAE_op = sum((abs(e3(k_ev:end)) + abs(e4(k_ev:end))) ...
                        .*(t(k_ev:end) - t_eval))*Ts;
        m.esfuerzo_op = sum(sum(abs(diff(U(:,k_ev:end),1,2))));
    else
        m.IAE_op = m.IAE; m.ISE_op = m.ISE; m.ITAE_op = m.ITAE;
        m.esfuerzo_op = sum(sum(abs(diff(U,1,2))));
    end

    % Detectar instante del cambio de referencia
    dref = sum(abs(diff(ref,1,2)),1);
    idx_chg = find(dref > 0.1, 1, 'first');
    if isempty(idx_chg), idx_chg = 1; end
    t_chg = t(idx_chg);

    band = 0.02 * 5;
    ts3 = tiempo_estab_(H(3,idx_chg:end), ref(1,idx_chg:end), band, t(idx_chg:end)) - t_chg;
    ts4 = tiempo_estab_(H(4,idx_chg:end), ref(2,idx_chg:end), band, t(idx_chg:end)) - t_chg;
    m.t_est = max(ts3, ts4);

    % Sobrepico
    ref_end3 = ref(1,end); ref_end4 = ref(2,end);
    if ref_end3 > ref(1,1)
        ov3 = max(H(3,idx_chg:end)) - ref_end3;
    else
        ov3 = ref_end3 - min(H(3,idx_chg:end));
    end
    if ref_end4 > ref(2,1)
        ov4 = max(H(4,idx_chg:end)) - ref_end4;
    else
        ov4 = ref_end4 - min(H(4,idx_chg:end));
    end
    delta_ref = max(abs([ref_end3 - ref(1,1); ref_end4 - ref(2,1); 1]));
    m.M_p = max([ov3, ov4, 0])/delta_ref*100;

    m.esfuerzo = sum(sum(abs(diff(U,1,2))));
    m.t_exec = t_exec;
end

function ts = tiempo_estab_(y, r, band, t)
    err = abs(y - r);
    idx = find(err > band, 1, 'last');
    if isempty(idx), ts = t(1); else, ts = t(idx); end
end


%% ========================================================================
%  ============= GRAFICAS DE COMPARACION ==================================
%  ========================================================================
function graficar_comparacion(t, H_g, U_g, H_p, U_p, ref, nombre, u_max_v)
    figure('Name', nombre, 'NumberTitle', 'off', 'Position',[100 100 1000 700])

    subplot(2,2,1)
    plot(t, H_g(3,:), 'b', 'LineWidth', 1.4); hold on;
    plot(t, H_p(3,:), 'g', 'LineWidth', 1.4);
    stairs(t, ref(1,:), 'k--', 'LineWidth', 1.2);
    ylabel('h_3 (cm)'); xlabel('Tiempo (s)'); grid on;
    legend('GPC','PID','Referencia','Location','best');
    title('Tanque 3 (h_3)');

    subplot(2,2,2)
    plot(t, H_g(4,:), 'b', 'LineWidth', 1.4); hold on;
    plot(t, H_p(4,:), 'g', 'LineWidth', 1.4);
    stairs(t, ref(2,:), 'k--', 'LineWidth', 1.2);
    ylabel('h_4 (cm)'); xlabel('Tiempo (s)'); grid on;
    legend('GPC','PID','Referencia','Location','best');
    title('Tanque 4 (h_4)');

    subplot(2,2,3)
    stairs(t, U_g(1,:), 'b', 'LineWidth', 1.3); hold on;
    stairs(t, U_p(1,:), 'g', 'LineWidth', 1.3);
    yline(u_max_v(1),'k--'); yline(0,'k--');
    ylabel('u_1'); xlabel('Tiempo (s)'); grid on;
    legend('GPC','PID','Location','best');
    title('Senal de control u_1');

    subplot(2,2,4)
    stairs(t, U_g(2,:), 'b', 'LineWidth', 1.3); hold on;
    stairs(t, U_p(2,:), 'g', 'LineWidth', 1.3);
    yline(u_max_v(2),'k--'); yline(0,'k--');
    ylabel('u_2'); xlabel('Tiempo (s)'); grid on;
    legend('GPC','PID','Location','best');
    title('Senal de control u_2');

    sgtitle(nombre, 'FontSize', 12, 'FontWeight', 'bold');
end


%% ========================================================================
%  ============= MODELO NO LINEAL DE LA PLANTA ===========================
%  ========================================================================
function dhdt = modelo_nl(~, h, u, p)
    h1=max(h(1),0); h2=max(h(2),0); h3=max(h(3),0); h4=max(h(4),0);
    u1=u(1); u2=u(2);
    dhdt = [-p.a1/p.A1*sqrt(2*p.g*h1) + (1-p.y2)*p.k2*u2/p.A1;
            -p.a2/p.A2*sqrt(2*p.g*h2) + (1-p.y1)*p.k1*u1/p.A2;
            -p.a3/p.A3*sqrt(2*p.g*h3) + p.a2/p.A3*sqrt(2*p.g*h2) + p.y2*p.k2*u2/p.A3;
            -p.a4/p.A4*sqrt(2*p.g*h4) + p.a1/p.A4*sqrt(2*p.g*h1) + p.y1*p.k1*u1/p.A4];
end
