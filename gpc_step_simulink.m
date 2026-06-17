function u_new = gpc_step(y_med, u_prev, r_act, Ad, Bd, Cd, ...
    G_din, Q, H_qp, A_ineq, h0, u0, h30, h40, ...
    N, Nu, Du_max, Du_min, u_max, u_min)
% ========================================================================
%  gpc_step.m
%  Codigo del bloque MATLAB Function del GPC para Simulink.
%
%  Calcula la accion de control u_new del GPC en cada periodo de muestreo
%  resolviendo el problema QP (quadprog).
%
%  Entradas (cableables en Simulink):
%    y_med   (4x1) -> estado medido (sale del Unit Delay 1)
%    u_prev  (2x1) -> entrada anterior (sale del Unit Delay 2)
%    r_act   (2x1) -> setpoint actual (sale del Mux de referencias)
%
%  Parametros (declarados como Parameter en el Symbols Pane, NO cableados):
%    Ad, Bd, Cd       -> modelo lineal discreto
%    G_din            -> matriz dinamica
%    Q, H_qp, A_ineq  -> matrices del QP
%    h0, u0           -> punto de operacion
%    h30, h40         -> alturas estacionarias de las salidas controladas
%    N, Nu            -> horizontes
%    Du_max, Du_min   -> limites de incremento
%    u_max, u_min     -> limites absolutos
%
%  Salida:
%    u_new   (2x1) -> nueva senal de control (entra a la saturacion)
%
%  IMPORTANTE: quadprog y optimoptions se declaran como coder.extrinsic
%  para que Simulink las ejecute en MATLAB en lugar de intentar
%  compilarlas (lo que produciria errores).
% ========================================================================

% Declarar funciones extrinsecas: se evaluan en MATLAB, no en C generado
coder.extrinsic('quadprog', 'optimoptions');

% Estado en variables desviadas
x_des      = y_med  - h0;
u_prev_des = u_prev - u0;

% --------------------------------------------------------------------
% Respuesta libre F (propagacion del modelo con Delta_u = 0)
% --------------------------------------------------------------------
F_vec = zeros(2*N, 1);
x_temp = x_des;
for j = 1:N
    x_temp = Ad*x_temp + Bd*u_prev_des;
    y_pred = Cd*x_temp;
    F_vec(j)     = y_pred(1);   % h3 en desviacion
    F_vec(N + j) = y_pred(2);   % h4 en desviacion
end

% --------------------------------------------------------------------
% Referencia futura constante (setpoint actual, sin preview)
% --------------------------------------------------------------------
r_des = r_act - [h30; h40];
W = [repmat(r_des(1), N, 1);
     repmat(r_des(2), N, 1)];

% --------------------------------------------------------------------
% Vector lineal del QP
% --------------------------------------------------------------------
f_qp = 2 * G_din' * Q * (F_vec - W);

% --------------------------------------------------------------------
% Vector de cotas del QP (depende de u_prev)
% --------------------------------------------------------------------
Du_max_v = [repmat(Du_max(1), Nu, 1); repmat(Du_max(2), Nu, 1)];
Du_min_v = [repmat(Du_min(1), Nu, 1); repmat(Du_min(2), Nu, 1)];
u_max_v  = [repmat(u_max(1),  Nu, 1); repmat(u_max(2),  Nu, 1)];
u_min_v  = [repmat(u_min(1),  Nu, 1); repmat(u_min(2),  Nu, 1)];
u_prev_stack = [repmat(u_prev(1), Nu, 1);
                repmat(u_prev(2), Nu, 1)];

b_ineq = [ Du_max_v;
          -Du_min_v;
           u_max_v - u_prev_stack;
          -u_min_v + u_prev_stack ];

% --------------------------------------------------------------------
% Resolucion del QP en Simulink
%
% Requisitos importantes:
%   - Pre-declarar DU con sus dimensiones (para que Simulink Coder
%     conozca el tamano de la salida).
%   - Usar el algoritmo 'active-set' (el por defecto interior-point-convex
%     no es compatible con Simulink Code Generation).
%   - Pasar los 10 argumentos completos a quadprog. Los vacios []
%     reemplazan a las restricciones de igualdad, lower bound y upper
%     bound que no usamos.
% --------------------------------------------------------------------
DU = zeros(2*Nu, 1);   % pre-declaracion de tamano

opts = optimoptions('quadprog', ...
                    'Algorithm', 'active-set', ...
                    'Display',   'off');

DU = quadprog(H_qp, f_qp, A_ineq, b_ineq, ...
              [], [], [], [], zeros(2*Nu,1), opts);

% --------------------------------------------------------------------
% Aplicacion del primer incremento de cada canal (horizonte deslizante)
% --------------------------------------------------------------------
Du_aplicado = [DU(1); DU(Nu+1)];
u_new = u_prev + Du_aplicado;
u_new = max(min(u_new, u_max), u_min);  % saturacion adicional

end
