# TESIS 20212444 — BLOQUES LISTOS PARA COPIAR Y PEGAR

Cada bloque está delimitado por `#_NN_NOMBRE`. Copia entre delimitadores y pega en Word.

---

#_01_RESUMEN

RESUMEN

El presente trabajo de tesis desarrolla el diseño, la implementación en un entorno de simulación y el análisis comparativo de un controlador Predictivo Generalizado (GPC) multivariable aplicado al sistema hidráulico de cuatro tanques acoplados propuesto por Johansson, empleado como banco de pruebas del Laboratorio de Control Avanzado de la Pontificia Universidad Católica del Perú. El estudio se justifica en la necesidad industrial de contar con estrategias de control capaces de gestionar sistemas multivariables con acoplamiento cruzado, restricciones físicas sobre los actuadores y operación en regiones alejadas del punto de linealización, condiciones ante las cuales los controladores clásicos presentan limitaciones estructurales.

El objetivo general es diseñar e implementar en simulación un controlador GPC multivariable para la regulación coordinada de los niveles de los tanques inferiores, garantizando un desempeño superior al de las estrategias clásicas. El marco teórico se sustenta en la formulación CARIMA con ecuaciones diofánticas para la construcción del modelo de predicción, en la formulación de programación cuadrática (QP) para el tratamiento explícito de restricciones y en el análisis comparativo de cuatro métodos de sintonización mediante un score combinado de seis métricas de desempeño.

La metodología comprende la caracterización dinámica del sistema, la linealización en torno al punto de operación nominal, el diseño del algoritmo GPC MIMO con los parámetros T_s = 1 s, N = 50 y N_u = 5, y su comparación frente a un controlador PI descentralizado con desacoplador estático sintonizado por Internal Model Control sobre un escenario integrado que incluye arranque, cambios de referencia, ruido gaussiano y operación lejos del punto nominal. Los resultados evidencian que el GPC reduce significativamente la interacción cruzada, presenta menor amplificación del ruido y alcanza referencias inalcanzables por el PI clásico, validando empíricamente la hipótesis del trabajo.

---

#_02_INDICE_GENERAL

ÍNDICE GENERAL

Pág.

RESUMEN ......................................................................................................... i

ÍNDICE DE TABLAS ...................................................................................... iv

ÍNDICE DE FIGURAS ..................................................................................... v

INTRODUCCIÓN .............................................................................................. 1

CAPÍTULO 1. ESTUDIO DEL CONTROL DE NIVEL EN SISTEMAS DE TANQUES ACOPLADOS ...... 3

1.1 Importancia del control de nivel en procesos industriales ........................... 3

1.1.1 Relevancia del estudio del sistema de tanques acoplados ................... 4

1.1.2 Problemática en el control de nivel en tanques acoplados ................. 5

1.2 Descripción del sistema de cuatro tanques acoplados ................................. 6

1.2.1 Definición de un sistema multivariable (MIMO/TITO) ...................... 6

1.2.2 Configuración y características del sistema de cuatro tanques ......... 7

1.3 Control de nivel en tanques acoplados ......................................................... 9

1.4 Justificación del estudio .............................................................................. 11

1.5 Objetivos del trabajo de investigación ........................................................ 12

1.5.1 Objetivo general ................................................................................. 12

1.5.2 Objetivos específicos .......................................................................... 13

CAPÍTULO 2. FUNDAMENTOS DEL CONTROL PREDICTIVO GPC Y MODELADO DEL SISTEMA HIDRÁULICO DE CUATRO TANQUES ACOPLADOS ...... 14

2.1 Introducción al MPC ................................................................................... 14

2.2 Control Predictivo Generalizado (GPC) ..................................................... 15

2.2.1 Introducción ........................................................................................ 15

2.2.2 Modelo de predicción ......................................................................... 16

2.2.3 Función costo y algoritmo de control ................................................ 18

2.2.4 GPC en sistemas multivariables ......................................................... 20

2.3 Modelado del sistema hidráulico de cuatro tanques acoplados .................. 22

2.3.1 Modelamiento matemático de la configuración de tanques ............... 22

2.3.2 Modelo linealizado alrededor de un punto de operación ................... 25

2.4 Simulación del modelo ............................................................................... 27

2.4.1 Metodología de simulación ................................................................ 27

2.4.2 Escenario de prueba ........................................................................... 28

2.4.3 Métrica de validación ......................................................................... 29

2.4.4 Análisis de resultados ......................................................................... 30

CAPÍTULO 3. DISEÑO DEL CONTROLADOR PREDICTIVO GPC PARA EL SISTEMA HIDRÁULICO DE CUATRO TANQUES ACOPLADOS (TITO) ...... 32

3.1 Introducción ................................................................................................ 32

3.2 Criterios de desempeño ............................................................................... 33

3.2.1 Sobrepico y tiempo de establecimiento .............................................. 33

3.2.2 Criterios integrales del error .............................................................. 34

3.2.3 Esfuerzo de control y costo computacional ....................................... 35

3.3 Diseño del sistema de control GPC MIMO ................................................ 36

3.3.1 Discretización del modelo y matriz de funciones de transferencia .... 36

3.3.2 Selección del horizonte del modelo y del tiempo de muestreo .......... 38

3.3.3 Construcción de la matriz dinámica G ............................................... 40

3.3.4 Cálculo de la respuesta libre F ........................................................... 42

3.3.5 Vector de referencia futura ................................................................ 43

3.3.6 Función de costo y ley de control sin restricciones ........................... 44

3.3.7 Tratamiento de restricciones (formulación QP) ................................. 46

3.3.8 Diagrama de flujo del controlador GPC ............................................. 48

3.4 Sintonización del controlador GPC MIMO ................................................ 49

3.4.1 Generalidades y necesidad de sintonización ...................................... 49

3.4.2 Método de Clarke-Mohtadi ................................................................ 50

3.4.3 Método de Shridhar-Cooper extendido a MIMO ............................... 52

3.4.4 Método PSO (Particle Swarm Optimization) ..................................... 54

3.4.5 Método de Nelder-Mead ..................................................................... 56

3.4.6 Comparación de métodos y selección ................................................ 57

3.5 Conclusiones del capítulo ........................................................................... 59

CAPÍTULO 4. ANÁLISIS COMPARATIVO DEL CONTROLADOR GPC FRENTE AL CONTROL PI CON DESACOPLADOR EN EL SISTEMA DE CUATRO TANQUES ACOPLADOS ...... 61

4.1 Introducción ................................................................................................ 61

4.2 Diseño del controlador PI con desacoplador estático ................................. 63

4.2.1 Emparejamiento entrada-salida .......................................................... 63

4.2.2 Sintonización por Internal Model Control (IMC) .............................. 64

4.2.3 Desacoplador estático ......................................................................... 66

4.2.4 Algoritmo discreto con anti-windup .................................................. 68

4.2.5 Verificación adicional en Simulink .................................................... 70

4.3 Escenario integrado de simulación ............................................................. 71

4.3.1 Configuración común ......................................................................... 71

4.3.2 Trayectoria de referencias y eventos .................................................. 72

4.3.3 Inyección de ruido en sensores .......................................................... 73

4.4 Análisis comparativo cuantitativo ............................................................... 74

4.4.1 Métricas y ventanas de evaluación ..................................................... 74

4.4.2 Métrica de acoplamiento cruzado ...................................................... 75

4.4.3 Resultados gráficos ............................................................................. 76

4.5 Discusión y validación de la hipótesis ........................................................ 78

4.5.1 Comportamiento ante acoplamiento cruzado ..................................... 78

4.5.2 Robustez ante ruido de medición ....................................................... 79

4.5.3 Operación lejos del punto de linealización ........................................ 80

4.5.4 Trade-offs identificados ...................................................................... 81

4.6 Conclusiones del capítulo ........................................................................... 82

CONCLUSIONES ........................................................................................... 84

RECOMENDACIONES .................................................................................. 86

BIBLIOGRAFÍA .............................................................................................. 88

ANEXO A. CÓDIGO MATLAB DEL CONTROLADOR GPC ..................... 92

ANEXO B. CÓDIGO MATLAB DEL CONTROLADOR PI CON DESACOPLADOR ..................... 97

ANEXO C. CÓDIGO MATLAB DE LA COMPARACIÓN GPC vs PI ......... 101

ANEXO D. CÓDIGOS MATLAB DE LOS ANÁLISIS AUXILIARES ....... 107

ANEXO E. CÓDIGOS MATLAB FUNCTION DE LOS BLOQUES DE SIMULINK ...... 114

---

#_03_INDICE_TABLAS

ÍNDICE DE TABLAS

Pág.

Tabla 2.1 Parámetros físicos del sistema de cuatro tanques acoplados ............. 23

Tabla 2.2 Punto de operación nominal y variables asociadas ........................... 26

Tabla 2.3 Resultados de la métrica FIT% para la validación del modelo lineal ......... 31

Tabla 3.1 Parámetros del controlador GPC MIMO adoptados ......................... 39

Tabla 3.2 Métodos de sintonización considerados ........................................... 50

Tabla 3.3 Parámetros del GPC obtenidos por el método de Clarke-Mohtadi ... 51

Tabla 3.4 Parámetros del GPC obtenidos por el método de Shridhar-Cooper .. 53

Tabla 3.5 Parámetros del GPC obtenidos por el método PSO .......................... 55

Tabla 3.6 Parámetros del GPC obtenidos por el método Nelder-Mead ........... 56

Tabla 3.7 Score combinado y comparación de los cuatro métodos .................. 58

Tabla 4.1 Parámetros de los controladores PI descentralizados sintonizados por IMC ..... 65

Tabla 4.2 Coeficientes del desacoplador estático ............................................. 67

Tabla 4.3 Métricas globales por controlador (0 ≤ t ≤ T_sim) ........................... 74

Tabla 4.4 Métricas en operación normal por controlador (t ≥ 400 s) ............... 75

Tabla 4.5 Métrica de acoplamiento cruzado INT_h₃ e INT_h₄ ........................ 76

---

#_04_INDICE_FIGURAS

ÍNDICE DE FIGURAS

Pág.

Figura 1.1 Sistema de control de nivel de un sistema de 4 tanques .................... 3

Figura 1.2 Diagrama del sistema de cuatro tanques propuesto por Johansson ... 7

Figura 1.3 Diagrama P&ID de la planta de laboratorio ...................................... 8

Figura 1.4 Proceso TITO con desacoplador ........................................................ 9

Figura 1.5 Proceso TITO con sistema de control híbrido PI-NN y multi PID-NN .......... 10

Figura 1.6 Estructura básica del MPC ............................................................... 10

Figura 1.7 Entrada de respuesta y control para el tanque 1 .............................. 11

Figura 1.8 Entrada de respuesta y control para el tanque 2 .............................. 12

Figura 2.1 Estructura general del control predictivo basado en modelo .......... 14

Figura 2.2 Esquema físico del sistema de cuatro tanques acoplados ................ 22

Figura 2.3 Diagrama del modelo linealizado en Simulink ................................ 27

Figura 2.4 Comparación de respuesta lineal vs no lineal ................................. 30

Figura 3.1 Coeficientes de respuesta al escalón g_ij[k] del sistema TITO ...... 41

Figura 3.2 Diagrama de flujo del controlador GPC .......................................... 48

Figura 3.3 Score combinado por método de sintonización ............................... 58

Figura 4.1 Respuesta en lazo cerrado del PI para tres valores de λ_imc .......... 65

Figura 4.2 Trayectoria de referencias r_h₃(t) y r_h₄(t) del escenario integrado ......... 73

Figura 4.3 Respuesta comparativa de h₃ durante toda la simulación ............... 76

Figura 4.4 Respuesta comparativa de h₄ durante toda la simulación ............... 77

Figura 4.5 Señales de control u₁ y u₂ aplicadas a las bombas .......................... 77

---

#_05_INTRODUCCION

INTRODUCCIÓN

El control automático de nivel en sistemas de tanques acoplados constituye uno de los desafíos clásicos y a la vez más recurrentes en la ingeniería de procesos industriales. Se encuentra presente en sectores tan diversos como el petroquímico, el farmacéutico, el minero, el alimentario y el energético, donde una regulación precisa del nivel de los tanques resulta indispensable para garantizar la calidad del producto final, la seguridad de la operación y la eficiencia del proceso. La complejidad de esta tarea se incrementa notablemente cuando los tanques se encuentran acoplados entre sí, dado que las variables del sistema dejan de ser independientes y las estrategias de control convencionales pierden efectividad.

El sistema de cuatro tanques acoplados, propuesto por Karl Henrik Johansson a finales de los años noventa, se ha consolidado como una plataforma de referencia para el estudio de procesos multivariables. Su principal virtud radica en que, mediante la variación de un único parámetro físico, es posible modificar la posición de los ceros del sistema, lo que permite estudiar en un mismo montaje comportamientos de fase mínima y fase no mínima. Esta propiedad lo convierte en un banco de pruebas ideal para evaluar estrategias de control clásico y avanzado en un mismo entorno experimental.

Frente a las limitaciones de los controladores clásicos ante procesos multivariables con acoplamiento cruzado, restricciones físicas y operación fuera del punto nominal, el Control Predictivo Basado en Modelo (MPC, por sus siglas en inglés) se ha erigido como una alternativa robusta y versátil. Dentro de esta familia, el Control Predictivo Generalizado (GPC) destaca por su formulación matemática elegante, su capacidad para gestionar de manera natural los sistemas multivariables mediante el modelo CARIMA y las ecuaciones diofánticas, y por su compatibilidad con la incorporación explícita de restricciones a través de una formulación de programación cuadrática.

La presente investigación se enfoca en el diseño, la implementación en un entorno de simulación y el análisis comparativo de un controlador GPC multivariable aplicado al sistema hidráulico de cuatro tanques acoplados. El desempeño del controlador diseñado se contrasta con el de un esquema de control PI descentralizado con desacoplador estático, considerado la mejor configuración clásica practicable para un sistema TITO acoplado en la industria. La comparación se sustenta en un escenario integrado de simulación que combina, en una sola secuencia operativa, los principales desafíos del control multivariable: arranque desde tanques vacíos, cambios secuenciales y simultáneos de referencia, inyección de ruido gaussiano en los sensores y operación significativamente alejada del punto de linealización.

El documento se organiza en cuatro capítulos. El Capítulo 1 presenta el estudio del control de nivel en sistemas de tanques acoplados, incluyendo la descripción del sistema, el estado del arte, la justificación del estudio y los objetivos de la investigación. El Capítulo 2 desarrolla los fundamentos teóricos del Control Predictivo Generalizado y el modelado matemático del sistema de cuatro tanques. El Capítulo 3 aborda el diseño del controlador GPC MIMO, incluyendo la selección de sus parámetros, la construcción de sus matrices características, el tratamiento de restricciones y el análisis comparativo de cuatro métodos de sintonización. El Capítulo 4 desarrolla el análisis comparativo del GPC diseñado frente al controlador PI con desacoplador. Finalmente, se presentan las conclusiones generales del trabajo, las recomendaciones para líneas futuras de investigación, la bibliografía consultada y los anexos que contienen los códigos MATLAB desarrollados.

---

#_06_OBJETIVO_GENERAL

1.5.1 Objetivo general

Diseñar e implementar en un entorno de simulación un controlador predictivo generalizado (GPC) multivariable para el sistema hidráulico de cuatro tanques acoplados, orientado a la regulación coordinada de los niveles de los tanques inferiores en presencia de acoplamiento cruzado, perturbaciones externas y restricciones físicas sobre los actuadores, garantizando un desempeño superior al de las estrategias de control clásicas empleadas habitualmente en la industria.

---

#_07_OBJETIVOS_ESPECIFICOS

1.5.2 Objetivos específicos

1. Caracterizar la dinámica multivariable del sistema de cuatro tanques acoplados, identificando sus propiedades estructurales, sus modos de operación de fase mínima y fase no mínima, y los caminos directos y cruzados entre entradas y salidas.

2. Obtener el modelo linealizado del sistema en espacio de estados y su correspondiente matriz de funciones de transferencia MIMO en torno a un punto de operación nominal, y validar la fidelidad del modelo lineal respecto al modelo no lineal mediante la métrica de ajuste porcentual (FIT%).

3. Diseñar el algoritmo del controlador Predictivo Generalizado para el sistema TITO, lo cual incluye la construcción de la matriz dinámica, la definición de los horizontes de predicción y control, la ponderación de la función de costo y el tratamiento de las restricciones físicas mediante una formulación de programación cuadrática.

4. Implementar el controlador GPC diseñado en el entorno MATLAB/Simulink y evaluar su desempeño mediante los criterios integrales del error, el tiempo de establecimiento, el sobrepico y el esfuerzo de control.

5. Realizar un análisis comparativo entre el desempeño del controlador GPC diseñado y el de un controlador PI descentralizado con desacoplador estático sintonizado por Internal Model Control, identificando las condiciones bajo las cuales el GPC justifica su adopción frente a la alternativa clásica.

---

#_08_CAP4_TITULO

CAPÍTULO 4. ANÁLISIS COMPARATIVO DEL CONTROLADOR GPC FRENTE AL CONTROL PI CON DESACOPLADOR EN EL SISTEMA DE CUATRO TANQUES ACOPLADOS

---

#_09_CAP4_4.1

4.1 Introducción

En el presente capítulo se desarrolla un análisis comparativo entre un controlador clásico con el controlador GPC desarrollado en el capítulo anterior, implementado sobre la misma planta no lineal de cuatro tanques acoplados. El diseño para la comparativa del controlador de contraste busca evidenciar las diferentes respuestas del sistema con control clásico y con algoritmos de control avanzado GPC en nuestro sistema industrial.

Para la comparativa, se ha optado por diseñar un controlador PI en vez de un PID. Esto debido a que en el sistema de cuatro tanques, la dinámica vista por cada lazo es dominantemente de primer orden con constante de tiempo del orden de las decenas de segundos. En estas condiciones, el aporte del término derivativo es marginal, mientras que su efecto sobre la amplificación del ruido de los transmisores de presión es considerable. Por esta razón, la práctica industrial recomienda omitir el término derivativo en aplicaciones de control de nivel y trabajar con la formulación PI (T_d = 0) [18].

Existen estrategias aplicables a un controlador clásico PI para enfrentarnos a un sistema multivariable, como por ejemplo el PI descentralizado puro (sin desacoplador), que deja sin compensar la interacción cruzada entre lazos, lo que en un sistema TITO acoplado es significativo y es justo lo que se desea disminuir, puesto que el cambio de una referencia provoca una perturbación inmediata en la salida opuesta. La estrategia industrial estándar consiste en incorporar un desacoplador estático entre las salidas de los PI y las entradas a la planta para cancelar la interacción del acople en estado estacionario, mejorando notablemente el comportamiento global del lazo. Sin este componente la comparación con el GPC sería ventajosamente sesgada hacia el predictivo; con desacoplador, en cambio, se garantiza que el contraste se realice contra la mejor configuración clásica practicable.

El capítulo se organiza en seis secciones. La sección 4.2 desarrolla el diseño completo del PI con desacoplador. La sección 4.3 describe el escenario integrado de simulación. La sección 4.4 reporta el análisis cuantitativo de los resultados. La sección 4.5 discute los hallazgos y valida la hipótesis del trabajo. La sección 4.6 cierra con las conclusiones del capítulo.

---

#_10_CAP4_4.2.1

4.2 Diseño del controlador PI con desacoplador estático

4.2.1 Emparejamiento entrada-salida

En el sistema de cuatro tanques acoplados, cada bomba afecta directamente al tanque inferior de su rama y, de manera indirecta, al tanque inferior opuesto a través del acoplamiento cruzado de los tanques superiores. Al examinar la matriz B_c del modelo linealizado se identifican los caminos directos, que son los rápidos: u₁ → h₄ con ganancia γ₁·k₁/A₄ y u₂ → h₃ con ganancia γ₂·k₂/A₃. En consecuencia, el emparejamiento natural adoptado es que PI_1 controle h₄ a través de u₁, y que PI_2 controle h₃ a través de u₂. Esta selección coincide con la recomendada por Johansson [8] para configuraciones de fase mínima (γ₁+γ₂ > 1), que es justamente el caso de la planta del Laboratorio de Control Avanzado de la PUCP.

---

#_11_CAP4_4.2.2

4.2.2 Sintonización por Internal Model Control (IMC)

Cada PI se diseña de forma independiente, considerando que la otra entrada permanece constante en su valor estacionario. Bajo este supuesto, el subproceso visto por cada lazo se aproxima a un sistema de primer orden con ganancia K y constante de tiempo τ:

[INSERTAR ECUACIÓN — pegar en Word con Alt+= modo LaTeX]
G_{loop}(s) = \frac{K}{\tau s + 1}

Se ha optado por el método de Internal Model Control debido a que sus reglas son analíticas y cerradas, lo cual elimina la subjetividad de los métodos heurísticos y permite una sintonización reproducible para cualquier planta del mismo tipo. Adicionalmente, la sintonización queda parametrizada por un único valor λ_imc que posee un significado físico directo como constante de tiempo deseada en lazo cerrado, característica que facilita el ajuste por parte del personal técnico. Los parámetros del PI resultan:

[INSERTAR ECUACIÓN]
K_p = \frac{\tau}{K \cdot \lambda_{imc}}, \quad T_i = \tau

Para el valor de λ_imc se adopta la regla λ_imc = τ/3, recomendada por la literatura industrial como ajuste por defecto en procesos de nivel y temperatura [17]. Valores menores que τ/3 aceleran el seguimiento, mientras que erosionan los márgenes de estabilidad; valores mayores incrementan la robustez, en cambio elevan considerablemente el tiempo de establecimiento. La regla adoptada constituye un compromiso entre ambos extremos.

[INSERTAR FIGURA 4.1 — Respuesta en lazo cerrado del PI para tres valores de λ_imc. Generar con analisis_lambda_imc.m]

Figura 4.1. Respuesta en lazo cerrado del PI para tres valores de λ_imc (τ/2, τ/3, τ).
Fuente: Elaboración propia.

[INSERTAR TABLA 4.1 — Parámetros de los PI descentralizados sintonizados por IMC]

Tabla 4.1
Parámetros de los controladores PI descentralizados sintonizados por IMC.

Nota. Elaboración propia. Datos generados con el script controlador_PID.m.

---

#_12_CAP4_4.2.3

4.2.3 Desacoplador estático

Para mitigar el efecto del acoplamiento cruzado, se incorpora un desacoplador estático entre las salidas de los PI y las entradas a la planta. Se adopta la formulación simplificada de Skogestad [19], que mantiene la diagonal unitaria y emplea las ganancias DC cruzadas para cancelar la interacción:

[INSERTAR ECUACIÓN]
\mathbf{D} = \begin{bmatrix} 1 & -k_{12} \\ -k_{21} & 1 \end{bmatrix}

Esta formulación se prefiere a un desacoplador dinámico debido a que requiere únicamente la matriz de ganancias DC del modelo, mucho más sencilla de obtener y notablemente más robusta a la incertidumbre paramétrica que un modelo dinámico completo. Adicionalmente, la cancelación estacionaria suele ser suficiente cuando los lazos individuales son moderadamente rápidos respecto al acople cruzado, condición que se cumple en el sistema piloto bajo estudio.

Los coeficientes k₁₂ y k₂₁ se calculan a partir de la matriz de ganancias DC del sistema linealizado:

[INSERTAR ECUACIÓN]
\mathbf{G}_{dc} = -\mathbf{C}_c \mathbf{A}_c^{-1} \mathbf{B}_c

[INSERTAR ECUACIÓN]
k_{12} = \frac{G_{dc}(h_4, u_2)}{G_{dc}(h_4, u_1)}, \quad k_{21} = \frac{G_{dc}(h_3, u_1)}{G_{dc}(h_3, u_2)}

La aplicación del desacoplador convierte las salidas v = [v_1, v_2]ᵀ de los PI en las señales u = [u_1, u_2]ᵀ que efectivamente alimentan las bombas:

[INSERTAR ECUACIÓN]
\mathbf{u} = \mathbf{D}\,\mathbf{v}

Conviene anticipar una limitación que se verá reflejada en los resultados: el desacoplador estático cancela el acople únicamente en estado estacionario y alrededor del punto de operación nominal. Cuando el sistema opera en regiones alejadas, las ganancias reales de la planta cambian debido a la dependencia con √h, mientras que el desacoplador conserva sus coeficientes fijados a partir del punto nominal y, en consecuencia, pierde efectividad.

[INSERTAR TABLA 4.2 — Coeficientes del desacoplador estático]

Tabla 4.2
Coeficientes del desacoplador estático calculados en el punto de operación nominal.

Nota. Elaboración propia. Datos generados con el script controlador_PID.m.

---

#_13_CAP4_4.2.4

4.2.4 Algoritmo discreto con anti-windup

La implementación digital del controlador se realiza en forma incremental, también llamada forma de velocidad:

[INSERTAR ECUACIÓN]
\Delta v(k) = K_p \left( e(k) - e(k-1) \right) + \frac{K_p\,T_s}{T_i}\,e(k)

Se ha optado por esta formulación en lugar de la posicional por dos motivos prácticos. El primero es que ante cambios bruscos de setpoint la forma incremental no provoca saltos abruptos en la salida, problema conocido en la literatura industrial como bumpless transfer. El segundo es que simplifica drásticamente la incorporación del anti-windup, puesto que no requiere mantener una variable de integración explícita: el efecto integral está distribuido en la acumulación de los Δv aplicados a lo largo del tiempo.

Las salidas incrementales Δv de los dos PI pasan por el desacoplador para producir los incrementos sobre las bombas, que se acumulan y se saturan:

[INSERTAR ECUACIÓN]
\mathbf{u}(k) = \text{sat}\left( \mathbf{u}(k-1) + \mathbf{D}\,\Delta\mathbf{v}(k),\ \mathbf{u}_{min},\ \mathbf{u}_{max} \right)

La razón para incorporar una estrategia anti-windup es directa: las bombas tienen límites físicos u_min = 0 y u_max = 2·u_s, lo que implica que el actuador puede saturarse cuando el error es grande. Sin anti-windup, mientras el actuador permanece saturado el término integral del PI sigue acumulándose sin efecto real sobre la planta, puesto que la señal aplicada está fijada por el límite físico. Al desaparecer la causa de la saturación, el controlador necesita consumir toda la integral acumulada antes de revertir su acción, lo cual provoca sobrepicos importantes y, en el peor caso, oscilaciones sostenidas, fenómeno conocido como integrator windup. En la formulación incremental adoptada, esta estrategia se implementa de forma natural saturando directamente la señal u(k) antes de aplicarla al actuador: el incremento que excede el rango simplemente no se acumula porque no se aplica. Esta variante se conoce como saturación condicional y es la solución más robusta, además de no requerir parámetros adicionales para su ajuste.

---

#_14_CAP4_4.2.5

4.2.5 Verificación adicional en Simulink

Como verificación adicional al análisis basado en scripts de MATLAB, el controlador PI con desacoplador se replica en el entorno MATLAB/Simulink. La estructura emplea los bloques de PI discretos del propio entorno, sintonizados con los parámetros obtenidos por IMC, un bloque que implementa el desacoplador estático y una representación de la planta no lineal con realimentación de estado. El solver se configura como ode45 de paso variable con el fin de preservar la precisión numérica en regiones alejadas del punto de operación, donde las no linealidades son más pronunciadas. Esta réplica reproduce los resultados de los scripts, lo cual confirma que las estrategias propuestas son trasladables a entornos de simulación gráfica ampliamente utilizados en la industria y constituye un primer paso hacia una eventual implementación en hardware.

---

#_15_CAP4_4.3

4.3 Escenario integrado de simulación

A diferencia de los trabajos que evalúan el desempeño en escenarios separados (caso nominal, perturbaciones e incertidumbre), en el presente trabajo se ha diseñado un escenario integrado que combina, en una sola simulación, los desafíos más representativos del control multivariable. Esta integración permite comparar el comportamiento global de ambos controladores en una secuencia operativa coherente y observar cómo cada uno responde a la sucesión de eventos típicos en una planta industrial real, donde los eventos no se presentan de manera aislada sino superpuestos.

4.3.1 Configuración común

La planta corresponde al modelo no lineal de los cuatro tanques acoplados desarrollado en el Capítulo 2, integrado numéricamente mediante ode45. La simulación arranca con el estado inicial h(0) = [0, 0, 0, 0]ᵀ, es decir, con los tanques vacíos, y con las bombas apagadas u(0) = [0, 0]ᵀ. Para ambos controladores se adopta el mismo tiempo de muestreo T_s = 1 s, lo que garantiza que el contraste se realice bajo idénticas condiciones de discretización. La duración total de la simulación es T_sim = 2000 s y el punto de operación nominal se mantiene en h₃⁰ = h₄⁰ = 25 cm, mientras que las restricciones físicas sobre las bombas se fijan en u_min = 0 y u_max = 2·u_s⁰ por canal.

4.3.2 Trayectoria de referencias y eventos

La secuencia de eventos activa, en orden, los aspectos relevantes del control multivariable. Durante el primer tramo (0 ≤ t < 400 s) el sistema se llena desde tanques vacíos y se aproxima al punto estacionario, etapa que evalúa la capacidad del controlador para gestionar el arranque del proceso. En t = 400 s el setpoint de h₃ cambia de 25 a 30 cm, lo que provoca el primer efecto de acoplamiento cruzado sobre h₄. En t = 800 s el setpoint de h₄ cambia de 25 a 20 cm, lo que evalúa el acoplamiento en sentido contrario. En t = 1100 s se activa el ruido gaussiano sobre las mediciones para evaluar la robustez de cada controlador frente a la presencia de ruido de los transmisores. Finalmente, en t = 1200 s se produce el evento crítico del escenario: el setpoint de h₃ regresa a 25 cm mientras el setpoint de h₄ sube a 35 cm, condición que representa un alejamiento del 40% respecto al punto nominal y combina simultáneamente operación extrema, ruido activo y cambio de referencia opuesto en el otro lazo.

4.3.3 Inyección de ruido en sensores

Para reproducir las condiciones realistas de operación industrial, a partir del instante t = 1100 s se añade ruido gaussiano blanco a las mediciones de h₃ y h₄ que ingresan a los controladores:

[INSERTAR ECUACIÓN]
y_{med,i}(k) = h_i(k) + n_i(k), \quad n_i(k) \sim \mathcal{N}(0, \sigma^2)

La desviación estándar se fija en σ = 0.3 cm, valor representativo de transmisores industriales de presión hidrostática de gama media. La activación del ruido en t = 1100 s se ubica deliberadamente justo antes del cambio de referencias en t = 1200 s, lo que permite observar cómo cada controlador responde al ruido cuando además debe enfrentar el evento crítico del escenario.

[INSERTAR FIGURA 4.2 — Trayectoria de referencias. Generar con trayectoria_referencias.m]

Figura 4.2. Trayectoria de referencias r_h₃(t) y r_h₄(t) del escenario integrado de simulación.
Fuente: Elaboración propia.

---

#_16_CAP4_4.4

4.4 Análisis comparativo cuantitativo

4.4.1 Métricas y ventanas de evaluación

Para cada controlador se calculan los seis criterios de desempeño definidos en la sección 3.2, esto es: IAE, ISE, ITAE, tiempo de establecimiento, sobrepico y esfuerzo de control. Estos criterios se reportan en dos ventanas temporales diferenciadas. La primera, denominada métricas globales, se evalúa sobre toda la simulación e incluye el arranque desde tanques vacíos. La segunda, denominada métricas en operación normal, se evalúa únicamente a partir de t = 400 s, es decir, una vez alcanzado el punto estacionario.

Esta distinción resulta metodológicamente importante puesto que el arranque desde tanques vacíos representa una fase transitoria de llenado del sistema, no un escenario de operación normal. Una métrica global puede verse dominada por la magnitud del error durante el arranque, lo cual oculta el desempeño real del controlador en régimen operativo, justamente donde se aprecian los efectos del acoplamiento y la robustez ante perturbaciones. Reportar ambas ventanas proporciona una visión completa del comportamiento de cada controlador en las distintas fases del escenario.

[INSERTAR TABLA 4.3]

Tabla 4.3
Métricas globales por controlador evaluadas sobre toda la simulación (0 ≤ t ≤ T_sim).

Nota. Elaboración propia. Datos generados con el script comparacion_GPC_vs_PID.m.

[INSERTAR TABLA 4.4]

Tabla 4.4
Métricas en operación normal por controlador evaluadas a partir de t ≥ 400 s.

Nota. Elaboración propia. Datos generados con el script comparacion_GPC_vs_PID.m.

4.4.2 Métrica de acoplamiento cruzado

Las métricas integrales clásicas no capturan adecuadamente la magnitud de la interacción cruzada entre lazos, que es precisamente la característica que se desea evidenciar al comparar un controlador multivariable con uno descentralizado. Por esta razón, en el presente trabajo se introduce una métrica específica que cuantifica cuánto se desvía una salida cuando se modifica únicamente la referencia de la otra. Para el cambio de referencia en h₃ en t = 400 s, la métrica se define como la integral del error de h₄ durante una ventana posterior al cambio:

[INSERTAR ECUACIÓN]
\text{INT}_{h_4} = \frac{1}{|\Delta r_3|} \int_{t_c}^{t_c + \Delta T} \left| e_{h_4}(t) \right|\, dt

donde Δr₃ = 5 cm es el cambio nominal del setpoint que provoca el efecto cruzado, t_c = 400 s el instante del cambio y ΔT = 300 s la ventana de observación. De manera análoga se define INT_{h_3} para el cambio de referencia en h₄ en t = 800 s. Valores bajos de INT indican un desacoplamiento efectivo entre los lazos, mientras que valores altos evidencian una interacción cruzada significativa.

[INSERTAR TABLA 4.5]

Tabla 4.5
Métrica de acoplamiento cruzado INT_h₃ e INT_h₄ para los dos controladores.

Nota. Elaboración propia. Datos generados con el script comparacion_GPC_vs_PID.m.

4.4.3 Resultados gráficos

[INSERTAR FIGURA 4.3 — Respuesta comparativa de h₃]

Figura 4.3. Respuesta comparativa de h₃ durante toda la simulación: GPC vs PI+Desacoplador.
Fuente: Elaboración propia.

[INSERTAR FIGURA 4.4 — Respuesta comparativa de h₄]

Figura 4.4. Respuesta comparativa de h₄ durante toda la simulación: GPC vs PI+Desacoplador.
Fuente: Elaboración propia.

[INSERTAR FIGURA 4.5 — Señales de control]

Figura 4.5. Señales de control u₁ y u₂ aplicadas a las bombas: GPC vs PI+Desacoplador.
Fuente: Elaboración propia.

---

#_17_CAP4_4.5

4.5 Discusión y validación de la hipótesis

4.5.1 Comportamiento ante acoplamiento cruzado

El PI descentralizado, aun con desacoplador estático, presenta perturbaciones notorias en una salida cuando cambia el setpoint de la otra. Esto se debe a que el desacoplador estático cancela la interacción únicamente en estado estacionario, mientras que durante el régimen transitorio los acoples cruzados dinámicos no son compensados. El GPC, en cambio, al considerar la dinámica completa del sistema en su predicción a N pasos, anticipa el efecto del acople y coordina simultáneamente las dos entradas para minimizarlo desde el primer paso. La métrica INT reportada en la Tabla 4.5 cuantifica esta ventaja del GPC frente al esquema clásico.

4.5.2 Robustez ante ruido de medición

Tras la inyección de ruido en t = 1100 s, ambos controladores transmiten parte del ruido a las señales de control. Sin embargo, el GPC exhibe una menor amplificación del ruido en las bombas que el PI con desacoplador, debido a la ponderación λ del esfuerzo de control incluida en su función de costo, que penaliza explícitamente las variaciones bruscas de la señal manipulada. Esto se refleja en una menor variación de u durante el último tramo de la simulación, característica relevante para preservar la vida útil de los actuadores en una aplicación industrial real.

4.5.3 Operación lejos del punto de linealización

El tramo crítico del escenario corresponde a t ≥ 1200 s, cuando el setpoint de h₄ se establece en 35 cm. En esta región, la planta no lineal presenta dinámicas significativamente distintas a las consideradas en la sintonización IMC del PI, dado que las constantes de tiempo de los tanques dependen de √h y, por tanto, varían con el nivel de operación. Como consecuencia, el PI descentralizado no alcanza el setpoint de 35 cm y exhibe un error en estado estacionario persistente. La sintonización IMC con λ_imc = τ/3, calculada para h = 25 cm, no proporciona la ganancia adecuada para esta región operativa, mientras que el desacoplador estático tampoco compensa adecuadamente puesto que sus coeficientes asumen la matriz de ganancias DC del punto nominal. El GPC, en cambio, sí alcanza el setpoint de 35 cm, aunque con un transitorio más lento que en la región nominal. Esto se debe a que su capacidad de predicción permite anticipar el efecto de la entrada acumulada sobre el horizonte futuro, compensando parcialmente las no linealidades del modelo lineal interno.

Este resultado constituye una validación experimental contundente de la hipótesis principal del trabajo: el control predictivo extiende la región de operación admisible del sistema más allá del entorno inmediato del punto de linealización, mientras que el PI con desacoplador queda restringido a una vecindad estrecha de su sintonización original.

4.5.4 Trade-offs identificados

La comparación no es absoluta y conviene reconocer que las ventajas del GPC vienen acompañadas de costos asociados. El primero es un costo computacional notablemente superior, puesto que la resolución del problema de optimización cuadrática en cada periodo de muestreo es considerablemente más exigente que la evaluación recursiva de un PI. Para tiempos de muestreo del orden del segundo, como el adoptado en el presente trabajo, esto no representa una limitación en hardware industrial moderno; en cambio, en procesos rápidos del orden de milisegundos sí debería evaluarse caso por caso. El segundo es una mayor complejidad de implementación, puesto que el GPC requiere infraestructura matemática (modelo, optimizador) ausente en el PI, lo que implica una curva de aprendizaje para el personal técnico y mayor dependencia de software especializado. El tercero es una dependencia más estricta del modelo del proceso, pues tanto el GPC como el desacoplador requieren conocer el modelo del proceso, pero el GPC lo emplea de manera más robusta (proyección al futuro) que el desacoplador (inversión algebraica del punto nominal). La cuantificación de estos costos permite responder de manera fundamentada a la pregunta de cuándo se justifica implementar un GPC en lugar de un PI con desacoplador en una aplicación industrial.

---

#_18_CAP4_4.6

4.6 Conclusiones del capítulo

En el presente capítulo se ha desarrollado un análisis comparativo del controlador predictivo generalizado (GPC) diseñado en el Capítulo 3 frente a un controlador PI descentralizado con desacoplador estático sintonizado por Internal Model Control, aplicado al sistema hidráulico de cuatro tanques acoplados. La selección del controlador de contraste responde a la práctica industrial estándar: se ha optado por un PI en lugar de un PID debido a la sensibilidad del término derivativo al ruido en dinámicas dominantemente de primer orden, y se ha incorporado un desacoplador estático con el fin de reflejar la mejor configuración clásica practicable en un sistema TITO acoplado.

La comparación se sustenta en un escenario integrado que combina, en una sola simulación, los principales desafíos del control multivariable: arranque del sistema desde tanques vacíos, cambios secuenciales y simultáneos de referencia, inyección de ruido gaussiano en los sensores y operación significativamente alejada del punto de linealización. Los resultados cuantitativos, respaldados por los seis criterios de desempeño del Capítulo 3 y la métrica específica de acoplamiento cruzado introducida en este trabajo, evidencian que el GPC reduce significativamente la interacción cruzada entre lazos, presenta menor amplificación del ruido en las señales de control y extiende la región de operación admisible más allá del entorno inmediato del punto de linealización.

El caso más representativo se observa en el tramo final del escenario (t ≥ 1200 s), donde el setpoint de h₄ se establece en 35 cm: el PI con desacoplador no alcanza esta referencia debido a las no linealidades del modelo y a la sintonización fijada para el punto nominal, mientras que el GPC sí lo logra gracias a su capacidad predictiva. Este resultado valida empíricamente la hipótesis principal del trabajo y establece, junto con los trade-offs identificados (mayor costo computacional, mayor complejidad de implementación y mayor dependencia del modelo), los criterios bajo los cuales el GPC justifica su adopción frente al PI con desacoplador en aplicaciones industriales de control multivariable.

---

#_19_CONCLUSIONES

CONCLUSIONES

El presente trabajo desarrolló el diseño, la implementación en simulación y el análisis comparativo de un controlador Predictivo Generalizado (GPC) multivariable aplicado al sistema hidráulico de cuatro tanques acoplados propuesto por Johansson, empleando como referencia comparativa un controlador PI descentralizado con desacoplador estático sintonizado por Internal Model Control. A partir de los resultados obtenidos a lo largo de los cuatro capítulos, se establecen las siguientes conclusiones:

1. Se caracterizó exitosamente la dinámica multivariable del sistema de cuatro tanques acoplados, identificando los caminos directos y cruzados entre entradas y salidas, y verificando el régimen de fase mínima correspondiente al banco de pruebas del Laboratorio de Control Avanzado de la PUCP mediante la condición γ₁ + γ₂ > 1.

2. Se obtuvo el modelo linealizado del sistema en espacio de estados y su matriz de funciones de transferencia MIMO en torno al punto de operación nominal h₃⁰ = h₄⁰ = 25 cm. La validación mediante la métrica FIT% confirmó una alta fidelidad del modelo lineal dentro de una vecindad de ±10% del punto de operación, y evidenció su degradación progresiva a medida que el sistema se aleja de dicha vecindad.

3. Se diseñó el controlador GPC MIMO bajo la formulación CARIMA con ecuaciones diofánticas, adoptando un tiempo de muestreo T_s = 1 s, un horizonte de predicción N = 50 y un horizonte de control N_u = 5. Los pesos de la función de costo (δ = [10, 10] y λ ≈ 0.0077) se obtuvieron mediante un análisis comparativo de cuatro métodos de sintonización (Clarke-Mohtadi, Shridhar-Cooper, PSO y Nelder-Mead) evaluados con un score combinado de seis métricas.

4. El tratamiento de las restricciones físicas sobre las bombas se incorporó de manera explícita mediante una formulación de programación cuadrática (QP), resuelta en cada periodo de muestreo con el algoritmo active-set. Esta característica constituye una ventaja estructural del GPC frente a las estrategias clásicas, que solo pueden manejar las restricciones mediante saturación posterior.

5. El análisis comparativo del Capítulo 4 evidenció que el GPC reduce significativamente la interacción cruzada entre lazos respecto al PI con desacoplador. La métrica específica de acoplamiento INT introducida en este trabajo cuantifica esta ventaja y establece un criterio objetivo para el contraste entre estrategias multivariables y descentralizadas.

6. El resultado más contundente se observó en el tramo t ≥ 1200 s del escenario integrado, cuando el setpoint de h₄ se establece en 35 cm (40% por encima del punto nominal). En estas condiciones, el PI con desacoplador no alcanza el setpoint debido a la variación de las constantes de tiempo con √h y a la pérdida de efectividad del desacoplador fuera del punto de operación nominal, mientras que el GPC sí lo alcanza gracias a su capacidad predictiva. Este resultado valida empíricamente la hipótesis principal del trabajo.

7. Los trade-offs identificados —mayor costo computacional, mayor complejidad de implementación y mayor dependencia del modelo— no comprometen la aplicabilidad del GPC en el escenario estudiado, dado que el tiempo de muestreo adoptado (T_s = 1 s) es holgado para hardware industrial moderno. En procesos con dinámicas más rápidas, estos costos deberían evaluarse caso por caso.

8. La implementación en Simulink de ambos controladores reprodujo los resultados de los scripts de MATLAB, demostrando la reproducibilidad de las estrategias propuestas en entornos de simulación gráfica ampliamente utilizados en la industria y sentando las bases para una eventual validación experimental sobre la planta piloto del Laboratorio de Control Avanzado de la PUCP.

---

#_20_RECOMENDACIONES

RECOMENDACIONES

A partir del trabajo desarrollado y de las limitaciones identificadas, se plantean las siguientes recomendaciones para líneas futuras de investigación:

1. Validar experimentalmente el controlador GPC diseñado sobre la planta piloto del Laboratorio de Control Avanzado de la PUCP, incorporando las particularidades del hardware real: retardos de comunicación, resolución de los actuadores y características específicas de los transmisores de nivel.

2. Estudiar variantes del GPC que permitan manejar de manera explícita las no linealidades del proceso, como el Nonlinear Model Predictive Control (NMPC) o el GPC adaptativo con actualización del modelo en línea. Estas variantes podrían extender aún más la región de operación admisible del sistema.

3. Evaluar la robustez del controlador frente a incertidumbre paramétrica y envejecimiento del proceso mediante análisis de sensibilidad y experimentos Monte Carlo sobre los parámetros físicos del modelo (áreas, coeficientes de descarga, ganancias de las bombas).

4. Integrar el controlador desarrollado con plataformas SCADA o MES industriales, de modo que sea posible evaluar su desempeño en un entorno operativo cercano al de la industria real, incluyendo la gestión de alarmas y la comunicación con sistemas de supervisión.

5. Extender el análisis comparativo a otros esquemas de control avanzado, como el control robusto H∞ o el control por modos deslizantes, con el fin de completar el mapa de estrategias aplicables al sistema de cuatro tanques y establecer un referente amplio para la selección de la estrategia más adecuada en aplicaciones industriales similares.

---

#_21_BIBLIOGRAFIA

BIBLIOGRAFÍA

[1] Laubwald, E. (2005). Coupled tank system. Control Systems Principles, 1-8.

[2] Yuan, W. (2023). Mathematical Model Analysis and Control Strategy. 2023 International Conference on Mechatronics, Control and Robotics (ICMCR), 94-97. Jeju, Korea: IEEE. https://doi.org/10.1109/ICMCR56776.2023.10181040

[3] Short, M., & Selvakumar, A. (2020). Non-Linear Tank Level Control for Industrial Applications. Applied Mathematics, 11, 876-889.

[4] Numsomran, V., Tipsuwanporn, V., & Tirasesth, K. (2008). Modeling of the Modified Quadruple-Tank Process. 2008 SICE Annual Conference, 818-823. Chofu, Japan: IEEE. https://doi.org/10.1109/SICE.2008.4654768

[5] Azam, S. N. M., & Jørgensen, J. B. (2015). Modeling and simulation of a modified quadruple tank system. 2015 IEEE International Conference on Control System, Computing and Engineering (ICCSCE), 365-370. Penang, Malaysia: IEEE. https://doi.org/10.1109/ICCSCE.2015.7482213

[6] Yu, Y., Yang, H., Wan, S., Liu, Q., & Yan, J. (2024). Un método de control cooperativo y su aplicación para sistemas acoplados multivariables en serie. Scientific Reports, 14. https://doi.org/10.1038/s41598-024-63169-7

[7] Albertos, P., & Sala, A. (2004). Multivariable Control Systems: An Engineering Approach. London, UK: Springer. https://doi.org/10.1007/b97506

[8] Johansson, K. H. (2000). The quadruple-tank process: a multivariable laboratory process with an adjustable zero. IEEE Transactions on Control Systems Technology, 8(3), 456-465. https://doi.org/10.1109/87.845876

[9] Pugliese, L., De Oliveira, T., Da Silva, D., Rodor, F., Braga, R., & Amorim, G. (2022). Modelado y desarrollo de una planta didáctica de bajo coste para la enseñanza en sistemas multivariables. Research, Society and Development, 11(7). https://doi.org/10.33448/rsd-v11i7.30249

[10] Sánchez Zurita, V. A. (2019). Diseño de un sistema de control predictivo multivariable aplicado a un proceso hidráulico de cuatro tanques acoplados. Tesis de Maestría, Pontificia Universidad Católica del Perú, Lima, Perú.

[11] Gouta, H., Haysam Al-Ashek, W., & Saad, B. (2022). Anti-disturbance composite tracking control for a coupled two-tank MIMO process with experimental studies. Automatika, 63(3), 593-604. https://doi.org/10.1080/00051144.2022.2059207

[12] Tang, J., Zhao, S., Fu, Q., Liu, Z., & He, W. (2021). Adaptive fault-tolerant control for a three-tank system with height and rate constraints. 2021 China Automation Congress (CAC), 4020-4024. Beijing, China: IEEE. https://doi.org/10.1109/CAC53003.2021.9728310

[13] Abushokor, A., & Amrr, S. M. (2025). Model-Free Adaptive Time-Delay-Based Estimation Control for Input-Saturated Coupled Tank System: Experimental Validation. IEEE Transactions on Automation Science and Engineering, 22, 19340-19351. https://doi.org/10.1109/TASE.2025.3594752

[14] Santana, H. G., Coelho, S. de S., & de Almeida, O. de M. (2018). Application of Multivariable PID Controllers in a Coupled Tank System. 2018 13th IEEE International Conference on Industry Applications (INDUSCON), 664-671. Sao Paulo, Brazil: IEEE. https://doi.org/10.1109/INDUSCON.2018.8627072

[15] Cartes, D., & Wu, L. (2005). Experimental evaluation of adaptive three-tank level control. ISA Transactions, 44(2), 283-293. https://doi.org/10.1016/S0019-0578(07)60181-5

[16] Choudhary, P. K., Raj, P., & Das, D. K. (2024). Controller Design for Decoupled Two-Input Two-Output Coupled Tank System. 2024 IEEE International Conference on Smart Power Control and Renewable Energy (ICSPCRE), 1-6. Rourkela, India: IEEE. https://doi.org/10.1109/ICSPCRE62303.2024.10675217

[17] Rivera, D. E., Morari, M., & Skogestad, S. (1986). Internal Model Control: PID Controller Design. Industrial & Engineering Chemistry Process Design and Development, 25(1), 252-265. https://doi.org/10.1021/i200032a041

[18] Åström, K. J., & Hägglund, T. (2006). Advanced PID Control. Research Triangle Park, NC: ISA - The Instrumentation, Systems, and Automation Society.

[19] Skogestad, S., & Postlethwaite, I. (2005). Multivariable Feedback Control: Analysis and Design (2nd ed.). Chichester, UK: John Wiley & Sons.

[20] Shridhar, R., & Cooper, D. J. (1997). A Tuning Strategy for Unconstrained Multivariable Model Predictive Control. Industrial & Engineering Chemistry Research, 37(10), 4003-4016. https://doi.org/10.1021/ie980202s

[21] Eberhart, R., & Kennedy, J. (1995). A new optimizer using particle swarm theory. MHS'95 Proceedings of the Sixth International Symposium on Micro Machine and Human Science, 39-43. Nagoya, Japan: IEEE. https://doi.org/10.1109/MHS.1995.494215

[22] Åström, K. J., & Wittenmark, B. (1997). Computer-Controlled Systems: Theory and Design (3rd ed.). Upper Saddle River, NJ: Prentice Hall.

[23] Camacho, E. F., & Bordons, C. (2007). Model Predictive Control (2nd ed.). London, UK: Springer. https://doi.org/10.1007/978-0-85729-398-5

[24] Clarke, D. W. (1988). Application of Generalized Predictive Control to Industrial Processes. IEEE Control Systems Magazine, 8(2), 49-55. https://doi.org/10.1109/37.1961

[25] Cheng, Y. (2007). Predicción de j pasos adelante basada en el modelo CARMA para sistemas MIMO. Frontiers of Electrical and Electronic Engineering in China, 2, 99-103. https://doi.org/10.1007/s11460-007-0018-7

[26] Nelder, J. A., & Mead, R. (1965). A Simplex Method for Function Minimization. The Computer Journal, 7(4), 308-313. https://doi.org/10.1093/comjnl/7.4.308

[27] Ogata, K. (2010). Modern Control Engineering (5th ed.). Upper Saddle River, NJ: Prentice Hall.

---

#_22_ANEXO_A

ANEXO A. CÓDIGO MATLAB DEL CONTROLADOR GPC

El presente anexo contiene el código MATLAB del controlador Predictivo Generalizado (GPC) diseñado en el Capítulo 3, aplicado sobre la planta no lineal de cuatro tanques acoplados. El script implementa la formulación CARIMA + ecuaciones diofánticas, la construcción de la matriz dinámica G por bloques, la matriz de ponderación de la función de costo, el tratamiento de restricciones mediante programación cuadrática y el bucle de control con horizonte deslizante.

Archivo: controlador_GPC.m

[COPIAR EL CONTENIDO COMPLETO DEL ARCHIVO controlador_GPC.m DEL REPOSITORIO]

---

#_23_ANEXO_B

ANEXO B. CÓDIGO MATLAB DEL CONTROLADOR PI CON DESACOPLADOR ESTÁTICO

El presente anexo contiene el código MATLAB del controlador PI descentralizado con desacoplador estático desarrollado en el Capítulo 4. El script implementa la sintonización IMC de los dos PI, el cálculo de los coeficientes del desacoplador a partir de la matriz de ganancias DC del sistema, la forma incremental con anti-windup por saturación condicional y el bucle de control sobre la planta no lineal.

Archivo: controlador_PID.m

[COPIAR EL CONTENIDO COMPLETO DEL ARCHIVO controlador_PID.m DEL REPOSITORIO]

---

#_24_ANEXO_C

ANEXO C. CÓDIGO MATLAB DE LA COMPARACIÓN GPC vs PI + DESACOPLADOR

El presente anexo contiene el código MATLAB que ejecuta el análisis comparativo central del Capítulo 4. El script simula ambos controladores sobre el mismo escenario integrado, calcula las métricas globales, las métricas en operación normal, la métrica de acoplamiento cruzado INT y genera las figuras comparativas.

Archivo: comparacion_GPC_vs_PID.m

[COPIAR EL CONTENIDO COMPLETO DEL ARCHIVO comparacion_GPC_vs_PID.m DEL REPOSITORIO]

---

#_25_ANEXO_D

ANEXO D. CÓDIGOS MATLAB DE LOS ANÁLISIS AUXILIARES DEL CAPÍTULO 3 Y 4

El presente anexo agrupa los códigos MATLAB de los análisis auxiliares. El primero corresponde al análisis comparativo de los cuatro métodos de sintonización del GPC descritos en el Capítulo 3. El segundo justifica la elección de λ_imc = τ/3 para la sintonización del PI. El tercero genera la trayectoria de referencias del escenario integrado del Capítulo 4.

Archivo: analisis_sintonizacion_GPC.m

[COPIAR EL CONTENIDO COMPLETO DEL ARCHIVO analisis_sintonizacion_GPC.m DEL REPOSITORIO]

Archivo: analisis_lambda_imc.m

[COPIAR EL CONTENIDO COMPLETO DEL ARCHIVO analisis_lambda_imc.m DEL REPOSITORIO]

Archivo: trayectoria_referencias.m

[COPIAR EL CONTENIDO COMPLETO DEL ARCHIVO trayectoria_referencias.m DEL REPOSITORIO]

---

#_26_ANEXO_E

ANEXO E. CÓDIGOS MATLAB FUNCTION DE LOS BLOQUES DE SIMULINK

El presente anexo contiene los códigos de los bloques MATLAB Function empleados en los modelos Simulink de los controladores GPC y PI con desacoplador. Corresponden respectivamente a: el paso de control del GPC (formulación QP con coder.extrinsic para quadprog), el desacoplador estático de Skogestad y la planta no lineal integrada mediante Euler subdividido.

Archivo: gpc_step_simulink.m

[COPIAR EL CONTENIDO COMPLETO DEL ARCHIVO gpc_step_simulink.m DEL REPOSITORIO]

Archivo: desacoplador_simulink.m

[COPIAR EL CONTENIDO COMPLETO DEL ARCHIVO desacoplador_simulink.m DEL REPOSITORIO]

Archivo: planta_no_lineal_simulink.m

[COPIAR EL CONTENIDO COMPLETO DEL ARCHIVO planta_no_lineal_simulink.m DEL REPOSITORIO]

---

FIN DEL DOCUMENTO
