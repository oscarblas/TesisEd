function [sys,x0,str,ts] = planta_piloto_nolineal(t,x,u,flag,h_inic)

switch flag
    
    %% =====================
    case 0 % Inicializacion
    %% =====================
        sizes = simsizes;
        sizes.NumContStates  = 4;
        sizes.NumDiscStates  = 0;
        sizes.NumOutputs     = 4;
        sizes.NumInputs      = 2;
        sizes.DirFeedthrough = 0;
        sizes.NumSampleTimes = 1;
        
        sys = simsizes(sizes);
        str = [];
        ts  = [0 0];
        
        x0 = h_inic;

    %% =====================
    case 1 % Derivadas
    %% =====================
        % Estados
        h1 = x(1);
        h2 = x(2);
        h3 = x(3);
        h4 = x(4);

        % Entradas
        u1 = u(1);
        u2 = u(2);

        % Parametros
        A1 = 706.85; 
        A2 = 706.85; 
        A3 = 706.85; 
        A4 = 706.85; 

        a1 = 1.89; 
        a2 = 1.89; 
        a3 = 5.39; 
        a4 = 5.39; 

        k1 = 1; 
        k2 = 1; 

        y1 = 0.70;
        y2 = 0.70;

        g = 981; 

        % Evitar negativos
        h1 = max(h1,0);
        h2 = max(h2,0);
        h3 = max(h3,0);
        h4 = max(h4,0);

        % Modelo no lineal
        dh1dt = -a1/A1*sqrt(2*g*h1) + (1-y2)*k2*u2/A1;
        dh2dt = -a2/A2*sqrt(2*g*h2) + (1-y1)*k1*u1/A2;
        dh3dt = -a3/A3*sqrt(2*g*h3) + a2/A3*sqrt(2*g*h2) + y2*k2*u2/A3;
        dh4dt = -a4/A4*sqrt(2*g*h4) + a1/A4*sqrt(2*g*h1) + y1*k1*u1/A4;

        sys = [dh1dt; dh2dt; dh3dt; dh4dt];

    %% =====================
    case 3 % Salidas
    %% =====================
        sys = x; % más limpio

    %% =====================
    case {2,4,9} % No usados
    %% =====================
        sys = [];

    %% =====================
    otherwise
    %% =====================
        error(['Unhandled flag = ', num2str(flag)]);
end