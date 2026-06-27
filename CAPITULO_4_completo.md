# CAPÍTULO 4 — ANÁLISIS COMPARATIVO DEL CONTROLADOR GPC FRENTE AL CONTROL PI CON DESACOPLADOR EN EL SISTEMA DE CUATRO TANQUES ACOPLADOS

> **Instrucciones de uso:**
> - Para cada fórmula tienes el **preview renderizado** y el **código LaTeX** para Word.
> - Pega el código en Word con `Insertar → Ecuación → modo LaTeX`.
> - Reglas: cada fórmula en una sola línea LaTeX · `\|...\|` en vez de `\left\|...\right\|` · `\bar{X}` en vez de `\overline{X}`.

---

## 4.1 Introducción

En el presente capítulo se desarrolla un análisis comparativo entre un controlador clásico con el controlador GPC desarrollado en el capítulo anterior, implementado sobre la misma planta no lineal de cuatro tanques acoplados. El diseño para la comparativa del controlador de contraste busca evidenciar las diferentes respuestas del sistema con control clásico y con algoritmos de control avanzado GPC en nuestro sistema industrial.

Para la comparativa, se ha optado por diseñar un controlador PI en vez de un PID. Esto debido a que en el sistema de cuatro tanques, la dinámica vista por cada lazo es dominantemente de primer orden con constante de tiempo del orden de las decenas de segundos. En estas condiciones, el aporte del término derivativo es marginal, mientras que su efecto sobre la amplificación del ruido de los transmisores de presión es considerable. Por esta razón, la práctica industrial recomienda omitir el término derivativo en aplicaciones de control de nivel y trabajar con la formulación PI (`T_d = 0`) [Åström & Hägglund, 2006].

Existen estrategias aplicables a un controlador clásico PI para enfrentarnos a un sistema multivariable, como por ejemplo el PI descentralizado puro (sin desacoplador), que deja sin compensar la interacción cruzada entre lazos, lo que en un sistema TITO acoplado es significativo y es justo lo que se desea disminuir, puesto que el cambio de una referencia provoca una perturbación inmediata en la salida opuesta. La estrategia industrial estándar consiste en incorporar un desacoplador estático entre las salidas de los PI y las entradas a la planta para cancelar la interacción del acople en estado estacionario, mejorando notablemente el comportamiento global del lazo. Sin este componente la comparación con el GPC sería ventajosamente sesgada hacia el predictivo; con desacoplador, en cambio, se garantiza que el contraste se realice contra la mejor configuración clásica practicable.

El capítulo se organiza en seis secciones. La sección 4.2 desarrolla el diseño completo del PI con desacoplador. La sección 4.3 describe el escenario integrado de simulación. La sección 4.4 reporta el análisis cuantitativo de los resultados. La sección 4.5 discute los hallazgos y valida la hipótesis del trabajo. La sección 4.6 cierra con las conclusiones del capítulo.

---

## 4.2 Diseño del controlador PI con desacoplador estático

### 4.2.1 Emparejamiento entrada–salida

En el sistema de cuatro tanques acoplados, cada bomba afecta directamente al tanque inferior de su rama y, de manera indirecta, al tanque inferior opuesto a través del acoplamiento cruzado de los tanques superiores. Al examinar la matriz `B_c` del modelo linealizado se identifican los caminos directos, que son los rápidos: `u₁ → h₄` con ganancia `γ₁·k₁/A₄` y `u₂ → h₃` con ganancia `γ₂·k₂/A₃`. En consecuencia, el emparejamiento natural adoptado es que `PI_1` controle `h₄` a través de `u₁`, y que `PI_2` controle `h₃` a través de `u₂`. Esta selección coincide con la recomendada por Johansson [8] para configuraciones de fase mínima `(γ₁+γ₂ > 1)`, que es justamente el caso de la planta del Laboratorio de Control Avanzado de la PUCP.

### 4.2.2 Sintonización por Internal Model Control (IMC)

Cada PI se diseña de forma independiente, considerando que la otra entrada permanece constante en su valor estacionario. Bajo este supuesto, el subproceso visto por cada lazo se aproxima a un sistema de primer orden con ganancia `K` y constante de tiempo `τ`:

**Preview:**

$$ G_{loop}(s) = \frac{K}{\tau\,s + 1} $$

**LaTeX para Word:**

```latex
G_{loop}(s) = \frac{K}{\tau\,s + 1}
```

Se ha optado por el método de Internal Model Control debido a que sus reglas son analíticas y cerradas, lo cual elimina la subjetividad de los métodos heurísticos y permite una sintonización reproducible para cualquier planta del mismo tipo. Adicionalmente, la sintonización queda parametrizada por un único valor `λ_imc` que posee un significado físico directo como constante de tiempo deseada en lazo cerrado, característica que facilita el ajuste por parte del personal técnico. Los parámetros del PI resultan:

**Preview:**

$$ K_p = \frac{\tau}{K \cdot \lambda_{imc}},\quad T_i = \tau $$

**LaTeX para Word:**

```latex
K_p = \frac{\tau}{K \cdot \lambda_{imc}},\quad T_i = \tau
```

Para el valor de `λ_imc` se adopta la regla `λ_imc = τ/3`, recomendada por la literatura industrial como ajuste por defecto en procesos de nivel y temperatura [Rivera, Morari & Skogestad, 1986]. Valores menores que `τ/3` aceleran el seguimiento, mientras que erosionan los márgenes de estabilidad; valores mayores incrementan la robustez, en cambio elevan considerablemente el tiempo de establecimiento. La regla adoptada constituye un compromiso entre ambos extremos.

[**IMAGEN 4.1** — Respuesta en lazo cerrado de cada PI sobre su subproceso aproximado de primer orden, comparando tres valores de `λ_imc` (τ/2, τ/3, τ). Justifica visualmente la elección.]

[**TABLA 4.1** — Parámetros de los PI descentralizados sintonizados por IMC. Columnas: Lazo, K, τ (s), λ_imc (s), K_p, T_i (s). Filas: PI_1 (u₁→h₄), PI_2 (u₂→h₃). Datos generados con `controlador_PID.m`.]

### 4.2.3 Desacoplador estático

Para mitigar el efecto del acoplamiento cruzado, se incorpora un desacoplador estático entre las salidas de los PI y las entradas a la planta. Se adopta la formulación simplificada de Skogestad [Skogestad & Postlethwaite, 2005], que mantiene la diagonal unitaria y emplea las ganancias DC cruzadas para cancelar la interacción:

**Preview:**

$$ \mathbf{D} = \begin{bmatrix} 1 & -k_{12} \\ -k_{21} & 1 \end{bmatrix} $$

**LaTeX para Word:**

```latex
\mathbf{D} = \begin{bmatrix} 1 & -k_{12} \\ -k_{21} & 1 \end{bmatrix}
```

Esta formulación se prefiere a un desacoplador dinámico debido a que requiere únicamente la matriz de ganancias DC del modelo, mucho más sencilla de obtener y notablemente más robusta a la incertidumbre paramétrica que un modelo dinámico completo. Adicionalmente, la cancelación estacionaria suele ser suficiente cuando los lazos individuales son moderadamente rápidos respecto al acople cruzado, condición que se cumple en el sistema piloto bajo estudio.

Los coeficientes `k₁₂` y `k₂₁` se calculan a partir de la matriz de ganancias DC del sistema linealizado:

**Preview:**

$$ \mathbf{G}_{dc} = -\mathbf{C}_c \mathbf{A}_c^{-1} \mathbf{B}_c $$

**LaTeX para Word:**

```latex
\mathbf{G}_{dc} = -\mathbf{C}_c \mathbf{A}_c^{-1} \mathbf{B}_c
```

**Preview:**

$$ k_{12} = \frac{G_{dc}(h_4, u_2)}{G_{dc}(h_4, u_1)},\quad k_{21} = \frac{G_{dc}(h_3, u_1)}{G_{dc}(h_3, u_2)} $$

**LaTeX para Word:**

```latex
k_{12} = \frac{G_{dc}(h_4, u_2)}{G_{dc}(h_4, u_1)},\quad k_{21} = \frac{G_{dc}(h_3, u_1)}{G_{dc}(h_3, u_2)}
```

La aplicación del desacoplador convierte las salidas `v = [v_1, v_2]ᵀ` de los PI en las señales `u = [u_1, u_2]ᵀ` que efectivamente alimentan las bombas:

**Preview:**

$$ \mathbf{u} = \mathbf{D}\,\mathbf{v} $$

**LaTeX para Word:**

```latex
\mathbf{u} = \mathbf{D}\,\mathbf{v}
```

Conviene anticipar una limitación que se verá reflejada en los resultados: el desacoplador estático cancela el acople únicamente en estado estacionario y alrededor del punto de operación nominal. Cuando el sistema opera en regiones alejadas, las ganancias reales de la planta cambian debido a la dependencia con `√h`, mientras que el desacoplador conserva sus coeficientes fijados a partir del punto nominal y, en consecuencia, pierde efectividad.

[**TABLA 4.2** — Coeficientes del desacoplador: `k₁₂`, `k₂₁`. Datos generados con `controlador_PID.m`.]

### 4.2.4 Algoritmo discreto con anti-windup

La implementación digital del controlador se realiza en forma incremental, también llamada forma de velocidad:

**Preview:**

$$ \Delta v(k) = K_p \left( e(k) - e(k-1) \right) + \frac{K_p\,T_s}{T_i}\,e(k) $$

**LaTeX para Word:**

```latex
\Delta v(k) = K_p \left( e(k) - e(k-1) \right) + \frac{K_p\,T_s}{T_i}\,e(k)
```

Se ha optado por esta formulación en lugar de la posicional por dos motivos prácticos. El primero es que ante cambios bruscos de setpoint la forma incremental no provoca saltos abruptos en la salida, problema conocido en la literatura industrial como *bumpless transfer*. El segundo es que simplifica drásticamente la incorporación del anti-windup, puesto que no requiere mantener una variable de integración explícita: el efecto integral está distribuido en la acumulación de los `Δv` aplicados a lo largo del tiempo.

Las salidas incrementales `Δv` de los dos PI pasan por el desacoplador para producir los incrementos sobre las bombas, que se acumulan y se saturan:

**Preview:**

$$ \mathbf{u}(k) = \text{sat}\left( \mathbf{u}(k-1) + \mathbf{D}\,\Delta\mathbf{v}(k),\ \mathbf{u}_{min},\ \mathbf{u}_{max} \right) $$

**LaTeX para Word:**

```latex
\mathbf{u}(k) = \text{sat}\left( \mathbf{u}(k-1) + \mathbf{D}\,\Delta\mathbf{v}(k),\ \mathbf{u}_{min},\ \mathbf{u}_{max} \right)
```

La razón para incorporar una estrategia anti-windup es directa: las bombas tienen límites físicos `u_min = 0` y `u_max = 2·u_s`, lo que implica que el actuador puede saturarse cuando el error es grande. Sin anti-windup, mientras el actuador permanece saturado el término integral del PI sigue acumulándose sin efecto real sobre la planta, puesto que la señal aplicada está fijada por el límite físico. Al desaparecer la causa de la saturación, el controlador necesita consumir toda la integral acumulada antes de revertir su acción, lo cual provoca sobrepicos importantes y, en el peor caso, oscilaciones sostenidas, fenómeno conocido como *integrator windup*. En la formulación incremental adoptada, esta estrategia se implementa de forma natural saturando directamente la señal `u(k)` antes de aplicarla al actuador: el incremento que excede el rango simplemente no se acumula porque no se aplica. Esta variante se conoce como saturación condicional y es la solución más robusta, además de no requerir parámetros adicionales para su ajuste.

### 4.2.5 Verificación adicional en Simulink

Como verificación adicional al análisis basado en scripts de MATLAB, el controlador PI con desacoplador se replica en el entorno MATLAB/Simulink. La estructura emplea los bloques de PI discretos del propio entorno, sintonizados con los parámetros obtenidos por IMC, un bloque que implementa el desacoplador estático y una representación de la planta no lineal con realimentación de estado. El solver se configura como `ode45` de paso variable con el fin de preservar la precisión numérica en regiones alejadas del punto de operación, donde las no linealidades son más pronunciadas. Esta réplica reproduce los resultados de los scripts, lo cual confirma que las estrategias propuestas son trasladables a entornos de simulación gráfica ampliamente utilizados en la industria y constituye un primer paso hacia una eventual implementación en hardware.

---

## 4.3 Escenario integrado de simulación

A diferencia de los trabajos que evalúan el desempeño en escenarios separados (caso nominal, perturbaciones e incertidumbre), en el presente trabajo se ha diseñado un escenario integrado que combina, en una sola simulación, los desafíos más representativos del control multivariable. Esta integración permite comparar el comportamiento global de ambos controladores en una secuencia operativa coherente y observar cómo cada uno responde a la sucesión de eventos típicos en una planta industrial real, donde los eventos no se presentan de manera aislada sino superpuestos.

### 4.3.1 Configuración común

La planta corresponde al modelo no lineal de los cuatro tanques acoplados desarrollado en el Capítulo 2, integrado numéricamente mediante `ode45`. La simulación arranca con el estado inicial `h(0) = [0, 0, 0, 0]ᵀ`, es decir, con los tanques vacíos, y con las bombas apagadas `u(0) = [0, 0]ᵀ`. Para ambos controladores se adopta el mismo tiempo de muestreo `T_s = 1 s`, lo que garantiza que el contraste se realice bajo idénticas condiciones de discretización. La duración total de la simulación es `T_sim = 2000 s` y el punto de operación nominal se mantiene en `h₃⁰ = h₄⁰ = 25 cm`, mientras que las restricciones físicas sobre las bombas se fijan en `u_min = 0` y `u_max = 2·u_s⁰` por canal.

### 4.3.2 Trayectoria de referencias y eventos

La secuencia de eventos activa, en orden, los aspectos relevantes del control multivariable. Durante el primer tramo `(0 ≤ t < 400 s)` el sistema se llena desde tanques vacíos y se aproxima al punto estacionario, etapa que evalúa la capacidad del controlador para gestionar el arranque del proceso. En `t = 400 s` el setpoint de `h₃` cambia de 25 a 30 cm, lo que provoca el primer efecto de acoplamiento cruzado sobre `h₄`. En `t = 800 s` el setpoint de `h₄` cambia de 25 a 20 cm, lo que evalúa el acoplamiento en sentido contrario. En `t = 1100 s` se activa el ruido gaussiano sobre las mediciones para evaluar la robustez de cada controlador frente a la presencia de ruido de los transmisores. Finalmente, en `t = 1200 s` se produce el evento crítico del escenario: el setpoint de `h₃` regresa a 25 cm mientras el setpoint de `h₄` sube a 35 cm, condición que representa un alejamiento del 40% respecto al punto nominal y combina simultáneamente operación extrema, ruido activo y cambio de referencia opuesto en el otro lazo.

### 4.3.3 Inyección de ruido en sensores

Para reproducir las condiciones realistas de operación industrial, a partir del instante `t = 1100 s` se añade ruido gaussiano blanco a las mediciones de `h₃` y `h₄` que ingresan a los controladores:

**Preview:**

$$ y_{med,i}(k) = h_i(k) + n_i(k),\quad n_i(k) \sim \mathcal{N}(0, \sigma^2) $$

**LaTeX para Word:**

```latex
y_{med,i}(k) = h_i(k) + n_i(k),\quad n_i(k) \sim \mathcal{N}(0, \sigma^2)
```

La desviación estándar se fija en `σ = 0.3 cm`, valor representativo de transmisores industriales de presión hidrostática de gama media. La activación del ruido en `t = 1100 s` se ubica deliberadamente justo antes del cambio de referencias en `t = 1200 s`, lo que permite observar cómo cada controlador responde al ruido cuando además debe enfrentar el evento crítico del escenario.

[**IMAGEN 4.2** — Trayectoria de referencias `r_h₃(t)` y `r_h₄(t)` durante toda la simulación, con líneas verticales marcando los cinco eventos. Permite al lector ubicar rápidamente cada tramo en las figuras posteriores.]

---

## 4.4 Análisis comparativo cuantitativo

### 4.4.1 Métricas y ventanas de evaluación

Para cada controlador se calculan los seis criterios de desempeño definidos en la sección 3.2, esto es: IAE, ISE, ITAE, tiempo de establecimiento, sobrepico y esfuerzo de control. Estos criterios se reportan en dos ventanas temporales diferenciadas. La primera, denominada métricas globales, se evalúa sobre toda la simulación e incluye el arranque desde tanques vacíos. La segunda, denominada métricas en operación normal, se evalúa únicamente a partir de `t = 400 s`, es decir, una vez alcanzado el punto estacionario.

Esta distinción resulta metodológicamente importante puesto que el arranque desde tanques vacíos representa una fase transitoria de llenado del sistema, no un escenario de operación normal. Una métrica global puede verse dominada por la magnitud del error durante el arranque, lo cual oculta el desempeño real del controlador en régimen operativo, justamente donde se aprecian los efectos del acoplamiento y la robustez ante perturbaciones. Reportar ambas ventanas proporciona una visión completa del comportamiento de cada controlador en las distintas fases del escenario.

[**TABLA 4.3** — Métricas globales por controlador. Columnas: Métrica, GPC, PI+Desacoplador. Filas: IAE, ISE, ITAE, esfuerzo. Datos generados con `comparacion_GPC_vs_PID.m`.]

[**TABLA 4.4** — Métricas en operación normal (t ≥ 400 s). Mismo formato que la Tabla 4.3.]

### 4.4.2 Métrica de acoplamiento cruzado

Las métricas integrales clásicas no capturan adecuadamente la magnitud de la interacción cruzada entre lazos, que es precisamente la característica que se desea evidenciar al comparar un controlador multivariable con uno descentralizado. Por esta razón, en el presente trabajo se introduce una métrica específica que cuantifica cuánto se desvía una salida cuando se modifica únicamente la referencia de la otra. Para el cambio de referencia en `h₃` en `t = 400 s`, la métrica se define como la integral del error de `h₄` durante una ventana posterior al cambio:

**Preview:**

$$ \text{INT}_{h_4} = \frac{1}{|\Delta r_3|} \int_{t_c}^{t_c + \Delta T} \left| e_{h_4}(t) \right|\, dt $$

**LaTeX para Word:**

```latex
\text{INT}_{h_4} = \frac{1}{|\Delta r_3|} \int_{t_c}^{t_c + \Delta T} \left| e_{h_4}(t) \right|\, dt
```

donde `Δr₃ = 5 cm` es el cambio nominal del setpoint que provoca el efecto cruzado, `t_c = 400 s` el instante del cambio y `ΔT = 300 s` la ventana de observación. De manera análoga se define `INT_{h_3}` para el cambio de referencia en `h₄` en `t = 800 s`. Valores bajos de `INT` indican un desacoplamiento efectivo entre los lazos, mientras que valores altos evidencian una interacción cruzada significativa.

[**TABLA 4.5** — Métrica de acoplamiento cruzado. Columnas: GPC, PI+Desacoplador. Filas: `INT_{h_4}`, `INT_{h_3}`. Datos generados con `comparacion_GPC_vs_PID.m`.]

### 4.4.3 Resultados gráficos

[**IMAGEN 4.3** — Respuesta comparativa de `h₃` durante toda la simulación. Curvas: GPC, PI+Desacoplador y referencia. Líneas verticales marcan los eventos en t = 400, 800, 1100 y 1200 s.]

[**IMAGEN 4.4** — Respuesta comparativa de `h₄`. Mismo formato que la Imagen 4.3. Esta es la figura clave del capítulo, puesto que evidencia el comportamiento del PI ante el setpoint de 35 cm en el tramo final del escenario.]

[**IMAGEN 4.5** — Señales de control `u₁` y `u₂` aplicadas a las bombas. Permite visualizar el esfuerzo de control, la activación de las saturaciones y la amplificación de ruido en cada controlador.]

---

## 4.5 Discusión y validación de la hipótesis

### 4.5.1 Comportamiento ante acoplamiento cruzado

El PI descentralizado, aun con desacoplador estático, presenta perturbaciones notorias en una salida cuando cambia el setpoint de la otra. Esto se debe a que el desacoplador estático cancela la interacción únicamente en estado estacionario, mientras que durante el régimen transitorio los acoples cruzados dinámicos no son compensados. El GPC, en cambio, al considerar la dinámica completa del sistema en su predicción a `N` pasos, anticipa el efecto del acople y coordina simultáneamente las dos entradas para minimizarlo desde el primer paso. La métrica `INT` reportada en la Tabla 4.5 cuantifica esta ventaja del GPC frente al esquema clásico.

### 4.5.2 Robustez ante ruido de medición

Tras la inyección de ruido en `t = 1100 s`, ambos controladores transmiten parte del ruido a las señales de control. Sin embargo, el GPC exhibe una menor amplificación del ruido en las bombas que el PI con desacoplador, debido a la ponderación `λ` del esfuerzo de control incluida en su función de costo, que penaliza explícitamente las variaciones bruscas de la señal manipulada. Esto se refleja en una menor variación de `u` durante el último tramo de la simulación, característica relevante para preservar la vida útil de los actuadores en una aplicación industrial real.

### 4.5.3 Operación lejos del punto de linealización

El tramo crítico del escenario corresponde a `t ≥ 1200 s`, cuando el setpoint de `h₄` se establece en 35 cm. En esta región, la planta no lineal presenta dinámicas significativamente distintas a las consideradas en la sintonización IMC del PI, dado que las constantes de tiempo de los tanques dependen de `√h` y, por tanto, varían con el nivel de operación. Como consecuencia, el PI descentralizado no alcanza el setpoint de 35 cm y exhibe un error en estado estacionario persistente. La sintonización IMC con `λ_imc = τ/3`, calculada para `h = 25 cm`, no proporciona la ganancia adecuada para esta región operativa, mientras que el desacoplador estático tampoco compensa adecuadamente puesto que sus coeficientes asumen la matriz de ganancias DC del punto nominal. El GPC, en cambio, sí alcanza el setpoint de 35 cm, aunque con un transitorio más lento que en la región nominal. Esto se debe a que su capacidad de predicción permite anticipar el efecto de la entrada acumulada sobre el horizonte futuro, compensando parcialmente las no linealidades del modelo lineal interno.

Este resultado constituye una validación experimental contundente de la hipótesis principal del trabajo: el control predictivo extiende la región de operación admisible del sistema más allá del entorno inmediato del punto de linealización, mientras que el PI con desacoplador queda restringido a una vecindad estrecha de su sintonización original.

### 4.5.4 Trade-offs identificados

La comparación no es absoluta y conviene reconocer que las ventajas del GPC vienen acompañadas de costos asociados. El primero es un costo computacional notablemente superior, puesto que la resolución del problema de optimización cuadrática en cada periodo de muestreo es considerablemente más exigente que la evaluación recursiva de un PI. Para tiempos de muestreo del orden del segundo, como el adoptado en el presente trabajo, esto no representa una limitación en hardware industrial moderno; en cambio, en procesos rápidos del orden de milisegundos sí debería evaluarse caso por caso. El segundo es una mayor complejidad de implementación, puesto que el GPC requiere infraestructura matemática (modelo, optimizador) ausente en el PI, lo que implica una curva de aprendizaje para el personal técnico y mayor dependencia de software especializado. El tercero es una dependencia más estricta del modelo del proceso, pues tanto el GPC como el desacoplador requieren conocer el modelo del proceso, pero el GPC lo emplea de manera más robusta (proyección al futuro) que el desacoplador (inversión algebraica del punto nominal). La cuantificación de estos costos permite responder de manera fundamentada a la pregunta de cuándo se justifica implementar un GPC en lugar de un PI con desacoplador en una aplicación industrial.

---

## 4.6 Conclusiones del capítulo

En el presente capítulo se ha desarrollado un análisis comparativo del controlador predictivo generalizado (GPC) diseñado en el Capítulo 3 frente a un controlador PI descentralizado con desacoplador estático sintonizado por Internal Model Control, aplicado al sistema hidráulico de cuatro tanques acoplados. La selección del controlador de contraste responde a la práctica industrial estándar: se ha optado por un PI en lugar de un PID debido a la sensibilidad del término derivativo al ruido en dinámicas dominantemente de primer orden, y se ha incorporado un desacoplador estático con el fin de reflejar la mejor configuración clásica practicable en un sistema TITO acoplado.

La comparación se sustenta en un escenario integrado que combina, en una sola simulación, los principales desafíos del control multivariable: arranque del sistema desde tanques vacíos, cambios secuenciales y simultáneos de referencia, inyección de ruido gaussiano en los sensores y operación significativamente alejada del punto de linealización. Los resultados cuantitativos, respaldados por los seis criterios de desempeño del Capítulo 3 y la métrica específica de acoplamiento cruzado introducida en este trabajo, evidencian que el GPC reduce significativamente la interacción cruzada entre lazos, presenta menor amplificación del ruido en las señales de control y extiende la región de operación admisible más allá del entorno inmediato del punto de linealización.

El caso más representativo se observa en el tramo final del escenario (`t ≥ 1200 s`), donde el setpoint de `h₄` se establece en 35 cm: el PI con desacoplador no alcanza esta referencia debido a las no linealidades del modelo y a la sintonización fijada para el punto nominal, mientras que el GPC sí lo logra gracias a su capacidad predictiva. Este resultado valida empíricamente la hipótesis principal del trabajo y establece, junto con los trade-offs identificados (mayor costo computacional, mayor complejidad de implementación y mayor dependencia del modelo), los criterios bajo los cuales el GPC justifica su adopción frente al PI con desacoplador en aplicaciones industriales de control multivariable.
