function h_next = planta_no_lineal(u, h_prev, Ts)
% ========================================================================
%  planta_no_lineal.m
%  Codigo del bloque MATLAB Function de la planta no lineal para Simulink.
%
%  Integra las 4 ecuaciones del modelo no lineal de los cuatro tanques
%  acoplados durante un periodo de muestreo Ts mediante integracion de
%  Euler con paso pequeno (n_steps = 20 subpasos).
%
%  Entradas (cableables en Simulink):
%    u       (2x1) -> entradas a las bombas [u1; u2]
%    h_prev  (4x1) -> estado anterior [h1; h2; h3; h4] (sale del Unit Delay)
%    Ts      (1x1) -> periodo de muestreo
%
%  Salida:
%    h_next  (4x1) -> estado al final del periodo [h1; h2; h3; h4]
%
%  Nota: los parametros fisicos (A_i, a_i, k_i, y_i, g) estan hardcodeados
%  porque NO cambian durante la simulacion. Son los valores del Cap. 2
%  de la tesis.
% ========================================================================

% Parametros fisicos de la planta
A1 = 706.85; A2 = 706.85; A3 = 706.85; A4 = 706.85;
a1 = 1.89;   a2 = 1.89;   a3 = 5.39;   a4 = 5.39;
k1 = 1; k2 = 1;
y1 = 0.7; y2 = 0.7;
g  = 981;

% Integracion de Euler con paso pequeno
n_steps = 20;
dt = Ts / n_steps;
h = h_prev;

for i = 1:n_steps
    h1 = max(h(1), 0);
    h2 = max(h(2), 0);
    h3 = max(h(3), 0);
    h4 = max(h(4), 0);

    dh = [-a1/A1*sqrt(2*g*h1) + (1-y2)*k2*u(2)/A1;
          -a2/A2*sqrt(2*g*h2) + (1-y1)*k1*u(1)/A2;
          -a3/A3*sqrt(2*g*h3) + a2/A3*sqrt(2*g*h2) + y2*k2*u(2)/A3;
          -a4/A4*sqrt(2*g*h4) + a1/A4*sqrt(2*g*h1) + y1*k1*u(1)/A4];

    h = h + dt * dh;
end

h_next = h;

end
