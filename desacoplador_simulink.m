function u_pre = desacoplador(v, k12, k21)
% ========================================================================
%  desacoplador.m
%  Codigo del bloque MATLAB Function del desacoplador estatico para Simulink.
%
%  Implementa el desacoplador simplificado de Skogestad: una matriz 2x2
%  con unos en la diagonal y las ganancias cruzadas negativas en las
%  posiciones off-diagonal.
%
%      [u1_pre]   [  1    -k12 ] [v1]
%      [u2_pre] = [ -k21    1  ] [v2]
%
%  Entradas (cableables en Simulink):
%    v   (2x1) -> vector con las salidas de los dos PI [v1; v2]
%                 (sale del Mux que combina las salidas de PI_1 y PI_2)
%
%  Parametros (declarados como Parameter en el Symbols Pane, NO cableados):
%    k12 (1x1) -> ganancia cruzada que cancela el efecto de u2 sobre h4
%    k21 (1x1) -> ganancia cruzada que cancela el efecto de u1 sobre h3
%
%  Salida:
%    u_pre (2x1) -> vector con las senales antes de la saturacion
%                   [u1_pre; u2_pre]
% ========================================================================

u1_pre = v(1) - k12 * v(2);
u2_pre = -k21 * v(1) + v(2);
u_pre  = [u1_pre; u2_pre];

end
