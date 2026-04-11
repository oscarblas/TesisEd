function planta_piloto_nolineal(block)
% S-Function Nivel 2 - Modelo no lineal del sistema de 4 tanques acoplados
    setup(block);
end

%% Configuracion del bloque
function setup(block)
    % Entrada: [u1, u2]
    block.NumInputPorts  = 1;
    block.InputPort(1).Dimensions        = 2;
    block.InputPort(1).DirectFeedthrough  = false;
    block.InputPort(1).SamplingMode       = 'Sample';

    % Salida: [h1, h2, h3, h4]
    block.NumOutputPorts = 1;
    block.OutputPort(1).Dimensions   = 4;
    block.OutputPort(1).SamplingMode = 'Sample';

    % 4 estados continuos (alturas)
    block.NumContStates = 4;

    % 1 parametro: h_inic (condiciones iniciales)
    block.NumDialogPrms = 1;

    % Tiempo de muestreo continuo
    block.SampleTimes = [0 0];

    % Registrar metodos
    block.RegBlockMethod('InitializeConditions', @InitConditions);
    block.RegBlockMethod('Outputs',              @Output);
    block.RegBlockMethod('Derivatives',          @Derivatives);
end

%% Condiciones iniciales
function InitConditions(block)
    h_inic = block.DialogPrm(1).Data;
    for i = 1:4
        block.ContStates.Data(i) = h_inic(i);
    end
end

%% Salidas: las alturas de los 4 tanques
function Output(block)
    block.OutputPort(1).Data = block.ContStates.Data;
end

%% Derivadas: modelo no lineal dh/dt
function Derivatives(block)
    % Estados actuales
    h = block.ContStates.Data;
    h1 = max(h(1), 0);
    h2 = max(h(2), 0);
    h3 = max(h(3), 0);
    h4 = max(h(4), 0);

    % Entradas
    u1 = block.InputPort(1).Data(1);
    u2 = block.InputPort(1).Data(2);

    % Parametros fisicos
    A1 = 706.85;  A2 = 706.85;  A3 = 706.85;  A4 = 706.85;
    a1 = 1.89;    a2 = 1.89;    a3 = 5.39;    a4 = 5.39;
    k1 = 1;       k2 = 1;
    y1 = 0.70;    y2 = 0.70;
    g  = 981;

    % Ecuaciones no lineales
    dh1dt = -a1/A1*sqrt(2*g*h1) + (1-y2)*k2*u2/A1;
    dh2dt = -a2/A2*sqrt(2*g*h2) + (1-y1)*k1*u1/A2;
    dh3dt = -a3/A3*sqrt(2*g*h3) + a2/A3*sqrt(2*g*h2) + y2*k2*u2/A3;
    dh4dt = -a4/A4*sqrt(2*g*h4) + a1/A4*sqrt(2*g*h1) + y1*k1*u1/A4;

    block.Derivatives.Data(1) = dh1dt;
    block.Derivatives.Data(2) = dh2dt;
    block.Derivatives.Data(3) = dh3dt;
    block.Derivatives.Data(4) = dh4dt;
end
