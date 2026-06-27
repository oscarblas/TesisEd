# CAPÍTULO 4 — Análisis Comparativo del Controlador GPC frente al Control PI con Desacoplador en el Sistema de Cuatro Tanques Acoplados

> **Instrucciones de uso:**
> - Para cada fórmula tienes el **preview renderizado** y el **código LaTeX** para Word.
> - Pega el código en Word con `Insertar → Ecuación → modo LaTeX`.
> - Reglas: cada fórmula en una sola línea LaTeX · `\|...\|` en vez de `\left\|...\right\|` · `\bar{X}` en vez de `\overline{X}`.

---

## 4.1 Introducción

El control proporcional-integral (PI) constituye, hasta la fecha, la estrategia de control más empleada en la industria moderna, abarcando entre el 90% y el 95% de los lazos de control implementados en procesos hidráulicos, químicos, energéticos y de manufactura [16]. Su éxito se sustenta en la simplicidad de su formulación, la disponibilidad nativa en cualquier autómata programable industrial y la familiaridad del personal técnico con su operación y sintonización. Frente a esta estrategia clásica, el Control Predictivo Generalizado (GPC) diseñado en el Capítulo 3 considera de manera explícita la naturaleza multivariable del proceso, las restricciones físicas sobre los actuadores y la dinámica conjunta de las salidas.

El presente capítulo desarrolla un análisis comparativo entre ambos enfoques sobre la misma planta no lineal de cuatro tanques acoplados. El controlador de contraste se selecciona y diseña bajo las consideraciones que se detallan a continuación, de modo que la comparación responda fielmente a la pregunta central del trabajo: **¿en qué condiciones se justifica el GPC frente al control clásico utilizado de forma habitual en la industria?**

**Por qué PI y no PID.** En el sistema de cuatro tanques, la dinámica vista por cada lazo es dominantemente de primer orden con constante de tiempo del orden de las decenas de segundos. En estas condiciones, el aporte del término derivativo es marginal y, en cambio, su efecto sobre la amplificación del ruido de los transmisores de presión es considerable. Por esta razón, la práctica industrial recomienda omitir el término derivativo en aplicaciones de control de nivel y trabajar con la formulación PI (`T_d = 0`) [Åström & Hägglund, 2006].

**Por qué con desacoplador.** Un controlador PI descentralizado puro (sin desacoplador) deja sin compensar la interacción cruzada entre lazos, que en un sistema TITO acoplado es significativa: el cambio de una referencia provoca una perturbación inmediata en la salida opuesta. La estrategia industrial estándar consiste en incorporar un **desacoplador estático** entre las salidas de los PI y las entradas a la planta para cancelar el acople en estado estacionario, mejorando notablemente el comportamiento global del lazo. Sin este componente la comparación con el GPC sería ventajosamente sesgada hacia el predictivo; con desacoplador, en cambio, se garantiza que el contraste se realice contra la mejor configuración clásica practicable.

El capítulo se organiza en seis secciones. La sección 4.2 desarrolla el diseño completo del PI con desacoplador. La sección 4.3 describe el escenario integrado de simulación. La sección 4.4 reporta el análisis cuantitativo de los resultados. La sección 4.5 discute los hallazgos y valida la hipótesis del trabajo. La sección 4.6 cierra con las conclusiones del capítulo.

---

## 4.2 Diseño del controlador PI con desacoplador estático

### 4.2.1 Emparejamiento entrada–salida

En el sistema de cuatro tanques acoplados, cada bomba afecta directamente al tanque inferior de su rama y, de manera indirecta, al tanque inferior opuesto a través del acoplamiento cruzado de los tanques superiores. Examinando la matriz `B_c` del modelo linealizado se identifican los caminos directos (rápidos):

- `u₁ → h₄` con ganancia `γ₁·k₁/A₄`
- `u₂ → h₃` con ganancia `γ₂·k₂/A₃`

En consecuencia se adopta el emparejamiento natural:

- **PI_1:** `u₁` controla `h₄`
- **PI_2:** `u₂` controla `h₃`

Esta selección coincide con el emparejamiento recomendado por Johansson [8] para configuraciones de fase mínima `(γ₁+γ₂ > 1)`, que es el caso de la planta del Laboratorio de Control Avanzado de la PUCP.

### 4.2.2 Sintonización por Internal Model Control (IMC)

Cada PI se diseña de forma independiente, considerando que la otra entrada permanece constante en su valor estacionario. Bajo este supuesto, el subproceso visto por cada lazo se aproxima a un sistema de primer orden con ganancia `K` y constante de tiempo `τ`:

**Preview:**

$$ G_{loop}(s) = \frac{K}{\tau\,s + 1} $$

**LaTeX para Word:**

```latex
G_{loop}(s) = \frac{K}{\tau\,s + 1}
```

Se adopta IMC por dos razones: (i) sus reglas son **analíticas y cerradas**, lo cual elimina la subjetividad de los métodos heurísticos y permite una sintonización reproducible para cualquier planta del mismo tipo; (ii) la sintonización queda parametrizada por un único valor `λ_imc`, que tiene un significado físico directo como constante de tiempo deseada en lazo cerrado. Los parámetros del PI resultan:

**Preview:**

$$ K_p = \frac{\tau}{K \cdot \lambda_{imc}},\quad T_i = \tau $$

**LaTeX para Word:**

```latex
K_p = \frac{\tau}{K \cdot \lambda_{imc}},\quad T_i = \tau
```

Se adopta `λ_imc = τ/3` como compromiso entre velocidad de respuesta y robustez ante incertidumbre del modelo. Valores menores aceleran el seguimiento pero erosionan los márgenes de estabilidad; valores mayores incrementan la robustez al costo de tiempos de establecimiento elevados. La regla `τ/3` es ampliamente recomendada en la literatura industrial como ajuste por defecto para procesos de nivel y temperatura [Rivera, Morari & Skogestad, 1986].

[**IMAGEN 4.1** — Respuesta en lazo cerrado de cada PI sobre su subproceso aproximado de primer orden, comparando tres valores de `λ_imc` (τ/2, τ/3, τ). Justifica visualmente la elección.]

[**TABLA 4.1** — Parámetros de los PI descentralizados sintonizados por IMC. Columnas: Lazo, K, τ (s), λ_imc (s), K_p, T_i (s). Filas: PI_1 (u₁→h₄), PI_2 (u₂→h₃). Datos generados con `controlador_PID.m`.]

### 4.2.3 Desacoplador estático

Para mitigar el efecto del acoplamiento cruzado, se incorpora un **desacoplador estático** entre las salidas de los PI y las entradas a la planta. Se adopta la formulación simplificada de Skogestad [Skogestad & Postlethwaite, 2005], que mantiene la diagonal unitaria y emplea las ganancias DC cruzadas para cancelar la interacción:

**Preview:**

$$ \mathbf{D} = \begin{bmatrix} 1 & -k_{12} \\ -k_{21} & 1 \end{bmatrix} $$

**LaTeX para Word:**

```latex
\mathbf{D} = \begin{bmatrix} 1 & -k_{12} \\ -k_{21} & 1 \end{bmatrix}
```

Esta formulación se prefiere a un desacoplador dinámico por dos motivos. Primero, requiere únicamente la matriz de ganancias DC del modelo, mucho más sencilla de obtener y más robusta a la incertidumbre paramétrica que un modelo dinámico completo. Segundo, la cancelación estacionaria suele ser suficiente cuando los lazos individuales son moderadamente rápidos respecto al acople cruzado, como ocurre en el sistema piloto bajo estudio.

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

Conviene anticipar una limitación que se verá reflejada en los resultados: el desacoplador estático cancela el acople **solo en estado estacionario** y alrededor del punto de operación nominal. Cuando el sistema opera en regiones alejadas, las ganancias reales de la planta cambian (por la dependencia con `√h`) y el desacoplador pierde efectividad.

[**TABLA 4.2** — Coeficientes del desacoplador: `k₁₂`, `k₂₁`. Datos generados con `controlador_PID.m`.]

### 4.2.4 Algoritmo discreto con anti-windup

La implementación digital se realiza en **forma incremental** (también llamada forma de velocidad):

**Preview:**

$$ \Delta v(k) = K_p \left( e(k) - e(k-1) \right) + \frac{K_p\,T_s}{T_i}\,e(k) $$

**LaTeX para Word:**

```latex
\Delta v(k) = K_p \left( e(k) - e(k-1) \right) + \frac{K_p\,T_s}{T_i}\,e(k)
```

La forma incremental se prefiere a la posicional por dos motivos prácticos. Primero, ante cambios bruscos de setpoint no provoca saltos abruptos en la salida (problema conocido como *bumpless transfer*). Segundo, simplifica drásticamente la incorporación del anti-windup, pues no requiere mantener una variable de integración explícita: el efecto integral está distribuido en la acumulación de los `Δv` aplicados.

Las salidas incrementales `Δv` de los dos PI pasan por el desacoplador para producir los incrementos sobre las bombas, que se acumulan y saturan:

**Preview:**

$$ \mathbf{u}(k) = \text{sat}\left( \mathbf{u}(k-1) + \mathbf{D}\,\Delta\mathbf{v}(k),\ \mathbf{u}_{min},\ \mathbf{u}_{max} \right) $$

**LaTeX para Word:**

```latex
\mathbf{u}(k) = \text{sat}\left( \mathbf{u}(k-1) + \mathbf{D}\,\Delta\mathbf{v}(k),\ \mathbf{u}_{min},\ \mathbf{u}_{max} \right)
```

**Por qué se incorpora anti-windup.** Las bombas tienen límites físicos `u_min = 0` y `u_max = 2·u_s` (saturación inferior y superior). Sin anti-windup, cuando el actuador se satura y el error persiste, el término integral del PI sigue acumulándose sin efecto real sobre la planta. Al desaparecer la causa de la saturación, el controlador necesita "consumir" toda la integral acumulada antes de revertir su acción, lo cual provoca sobrepicos importantes y, en el peor caso, oscilaciones sostenidas (efecto *integrator windup*). En la formulación incremental, el anti-windup se implementa de forma natural saturando directamente la señal `u(k)` antes de aplicarla al actuador: el incremento que excede el rango simplemente no se acumula porque no se aplica. Esta variante, denominada de **saturación condicional**, es la solución más robusta y la única que no requiere parámetros adicionales.

### 4.2.5 Verificación adicional en Simulink

Como verificación adicional al análisis basado en scripts de MATLAB, el controlador PI con desacoplador se replica en el entorno **MATLAB/Simulink** utilizando bloques `Discrete PID Controller` configurados como PI con sintonización IMC, un bloque que implementa el desacoplador estático y una representación de la planta no lineal con realimentación de estado. El solver se configura como `ode45` de paso variable para preservar la precisión numérica en regiones alejadas del punto de operación, donde las no linealidades son más pronunciadas. Esta réplica reproduce los resultados de los scripts, lo cual confirma que las estrategias propuestas son trasladables a entornos de simulación gráfica ampliamente utilizados en la industria y constituye un primer paso hacia una eventual implementación en hardware.

---

## 4.3 Escenario integrado de simulación

A diferencia de los trabajos que evalúan el desempeño en escenarios separados (caso nominal, perturbaciones e incertidumbre), en el presente trabajo se ha diseñado un **escenario integrado** que combina, en una sola simulación, los desafíos más representativos del control multivariable. Esta integración permite comparar el comportamiento global de ambos controladores en una secuencia operativa coherente y observar cómo cada uno responde a la sucesión de eventos típicos en una planta industrial.

### 4.3.1 Configuración común

Todos los experimentos se ejecutan bajo las siguientes condiciones:

- **Planta:** modelo no lineal de los cuatro tanques acoplados (Capítulo 2), integrado numéricamente mediante `ode45`.
- **Estado inicial:** `h(0) = [0, 0, 0, 0]ᵀ` (tanques vacíos).
- **Entradas iniciales:** `u(0) = [0, 0]ᵀ` (bombas apagadas).
- **Tiempo de muestreo:** `T_s = 1 s` para ambos controladores.
- **Duración:** `T_sim = 2000 s`.
- **Punto de operación nominal:** `h₃⁰ = h₄⁰ = 25 cm`.
- **Restricciones:** `u_min = 0` y `u_max = 2·u_s⁰` por canal.

### 4.3.2 Trayectoria de referencias y eventos

La secuencia activa, en orden, los aspectos relevantes del control multivariable:

| Tiempo | Evento | Aspecto evaluado |
|---|---|---|
| 0 ≤ t < 400 s | Arranque desde tanques vacíos | Llenado y aproximación al estacionario |
| t = 400 s | SP de `h₃` cambia de 25 a 30 cm | Acoplamiento cruzado sobre `h₄` |
| t = 800 s | SP de `h₄` cambia de 25 a 20 cm | Acoplamiento cruzado sobre `h₃` |
| t = 1100 s | Activación de ruido gaussiano (σ = 0.3 cm) | Robustez ante ruido de medición |
| t = 1200 s | SP de `h₃` regresa a 25 cm y SP de `h₄` sube a 35 cm | Operación lejos del punto de linealización |

El último evento (`t = 1200 s`) es el **caso crítico** del capítulo: el setpoint de `h₄` se establece en 35 cm, lo cual representa un alejamiento del 40% respecto al punto nominal y combina simultáneamente operación extrema, ruido activo y cambio de referencia opuesto en el otro lazo.

### 4.3.3 Inyección de ruido en sensores

Para reproducir condiciones realistas de operación industrial, a partir del instante `t = 1100 s` se añade ruido gaussiano blanco a las mediciones de `h₃` y `h₄`:

**Preview:**

$$ y_{med,i}(k) = h_i(k) + n_i(k),\quad n_i(k) \sim \mathcal{N}(0, \sigma^2) $$

**LaTeX para Word:**

```latex
y_{med,i}(k) = h_i(k) + n_i(k),\quad n_i(k) \sim \mathcal{N}(0, \sigma^2)
```

con `σ = 0.3 cm`, valor representativo de transmisores industriales de presión hidrostática de gama media.

[**IMAGEN 4.2** — Trayectoria de referencias `r_h₃(t)` y `r_h₄(t)` durante toda la simulación, con líneas verticales marcando los cinco eventos. Permite al lector ubicar rápidamente cada tramo en las figuras posteriores.]

---

## 4.4 Análisis comparativo cuantitativo

### 4.4.1 Métricas y ventanas de evaluación

Para cada controlador se calculan los seis criterios de desempeño definidos en la sección 3.2 (IAE, ISE, ITAE, tiempo de establecimiento, sobrepico y esfuerzo de control), pero reportados en **dos ventanas temporales**:

- **(a) Métricas globales:** sobre toda la simulación. Incluyen el arranque desde tanques vacíos.
- **(b) Métricas en operación normal:** únicamente a partir de `t = 400 s`, una vez alcanzado el estacionario.

Esta distinción es metodológicamente importante porque el arranque desde tanques vacíos representa una fase transitoria de llenado, no un escenario de operación normal. Una métrica global puede verse dominada por la magnitud del error durante el arranque, ocultando el desempeño real en régimen operativo. Reportar ambas ventanas proporciona una visión completa.

[**TABLA 4.3** — Métricas globales por controlador. Columnas: Métrica, GPC, PI+Desacoplador. Filas: IAE, ISE, ITAE, esfuerzo. Datos generados con `comparacion_GPC_vs_PID.m`.]

[**TABLA 4.4** — Métricas en operación normal (t ≥ 400 s). Mismo formato que la Tabla 4.3.]

### 4.4.2 Métrica de acoplamiento cruzado

Las métricas integrales clásicas no capturan adecuadamente la magnitud de la **interacción cruzada** entre lazos. Por esta razón se introduce una métrica específica que cuantifica cuánto se desvía una salida cuando se modifica únicamente la referencia de la otra. Para el cambio de referencia en `h₃` en `t = 400 s`:

**Preview:**

$$ \text{INT}_{h_4} = \frac{1}{|\Delta r_3|} \int_{t_c}^{t_c + \Delta T} \left| e_{h_4}(t) \right|\, dt $$

**LaTeX para Word:**

```latex
\text{INT}_{h_4} = \frac{1}{|\Delta r_3|} \int_{t_c}^{t_c + \Delta T} \left| e_{h_4}(t) \right|\, dt
```

donde `Δr₃ = 5 cm`, `t_c = 400 s` y `ΔT = 300 s`. Análogamente se define `INT_{h_3}` para el cambio en `h₄` en `t = 800 s`. Valores bajos de `INT` indican un desacoplamiento efectivo.

[**TABLA 4.5** — Métrica de acoplamiento cruzado. Columnas: GPC, PI+Desacoplador. Filas: `INT_{h_4}`, `INT_{h_3}`. Datos generados con `comparacion_GPC_vs_PID.m`.]

### 4.4.3 Resultados gráficos

[**IMAGEN 4.3** — Respuesta comparativa de `h₃` durante toda la simulación. Curvas: GPC, PI+Desacoplador y referencia. Líneas verticales marcan los eventos en t = 400, 800, 1100 y 1200 s.]

[**IMAGEN 4.4** — Respuesta comparativa de `h₄`. Mismo formato que la Imagen 4.3. Es la figura clave porque evidencia el comportamiento del PI ante el setpoint de 35 cm en el tramo final.]

[**IMAGEN 4.5** — Señales de control `u₁` y `u₂`. Permite visualizar el esfuerzo, la activación de saturaciones y la amplificación de ruido en cada controlador.]

---

## 4.5 Discusión y validación de la hipótesis

### 4.5.1 Comportamiento ante acoplamiento cruzado

El PI descentralizado, aun con desacoplador estático, presenta perturbaciones notorias en una salida cuando cambia el setpoint de la otra. Esto se debe a que el desacoplador cancela la interacción **únicamente en estado estacionario**: durante el régimen transitorio, los acoples dinámicos no son compensados. El GPC, al considerar la dinámica completa del sistema en su predicción a `N` pasos, anticipa el efecto del acople y coordina simultáneamente las dos entradas para minimizarlo desde el primer paso. La métrica `INT` (Tabla 4.5) cuantifica esta ventaja.

### 4.5.2 Robustez ante ruido de medición

Tras la inyección de ruido en `t = 1100 s`, ambos controladores transmiten parte del ruido a las señales de control. El GPC, gracias a la ponderación `λ` del esfuerzo en la función de costo, exhibe una menor amplificación del ruido en las bombas que el PI. Esto se refleja en una menor variación de `u` durante el último tramo de la simulación, lo cual es relevante para preservar la vida útil de los actuadores industriales.

### 4.5.3 Operación lejos del punto de linealización

El tramo crítico del escenario corresponde a `t ≥ 1200 s`, cuando el setpoint de `h₄` se establece en 35 cm —un alejamiento del 40% respecto al punto nominal—. En esta región, la planta no lineal presenta dinámicas significativamente distintas a las consideradas en la sintonización IMC del PI, dado que las constantes de tiempo de los tanques dependen de `√h`. Como consecuencia:

- El **PI descentralizado no alcanza el setpoint de 35 cm**, exhibiendo un error en estado estacionario persistente. La sintonización IMC con `λ_imc = τ/3`, calculada para `h = 25 cm`, no proporciona la ganancia adecuada para esta región operativa, y el desacoplador estático tampoco compensa adecuadamente porque sus coeficientes asumen la matriz de ganancias DC del punto nominal.
- El **GPC sí alcanza el setpoint de 35 cm**, aunque con un transitorio más lento que en la región nominal. La capacidad de predicción del GPC permite anticipar el efecto de la entrada acumulada sobre el horizonte futuro, compensando parcialmente las no linealidades del modelo lineal interno.

Este resultado constituye una validación experimental contundente de la hipótesis principal del trabajo: **el control predictivo extiende la región de operación admisible del sistema más allá del entorno inmediato del punto de linealización**, mientras que el PI con desacoplador queda restringido a una vecindad estrecha de su sintonización original.

### 4.5.4 Trade-offs identificados

La comparación no es absoluta. Las ventajas del GPC vienen acompañadas de costos que conviene reconocer:

- **Costo computacional superior:** la resolución del QP en cada periodo de muestreo es notablemente más exigente que la evaluación recursiva de un PI. Para tiempos de muestreo del orden del segundo, como el adoptado aquí, esto no representa una limitación en hardware industrial moderno; en procesos rápidos (de milisegundos), sí debería evaluarse caso por caso.
- **Complejidad de implementación:** el GPC requiere infraestructura matemática (modelo, optimizador) ausente en el PI. Esto implica curva de aprendizaje para el personal técnico y mayor dependencia de software especializado.
- **Dependencia del modelo:** tanto el GPC como el desacoplador requieren conocer el modelo del proceso, pero el GPC lo emplea de forma más robusta (proyección al futuro) que el desacoplador (inversión algebraica del punto nominal).

La cuantificación de estos trade-offs permite responder de manera fundamentada a la pregunta de cuándo se justifica implementar un GPC en lugar de un PI con desacoplador en una aplicación industrial.

---

## 4.6 Conclusiones del capítulo

En el presente capítulo se ha desarrollado un análisis comparativo del controlador predictivo generalizado (GPC) frente a un controlador PI descentralizado con desacoplador estático sintonizado por Internal Model Control, aplicado al sistema hidráulico de cuatro tanques acoplados. La selección del controlador de contraste responde a la práctica industrial estándar: PI (no PID) por la sensibilidad del término derivativo al ruido en dinámicas de primer orden, y con desacoplador para reflejar la mejor configuración clásica practicable en un sistema TITO acoplado.

La comparación se sustenta en un escenario integrado que combina, en una sola simulación, los principales desafíos del control multivariable: arranque desde tanques vacíos, cambios secuenciales y simultáneos de referencia, inyección de ruido gaussiano y operación significativamente alejada del punto de linealización. Los resultados cuantitativos —respaldados por los seis criterios de desempeño del Capítulo 3 y la métrica de acoplamiento cruzado introducida en este trabajo— evidencian que el GPC reduce significativamente la interacción cruzada entre lazos, presenta menor amplificación del ruido en las señales de control y extiende la región de operación admisible más allá del entorno inmediato del punto de linealización.

El caso más representativo se observa en el tramo final del escenario (`t ≥ 1200 s`), donde el setpoint de `h₄` se establece en 35 cm: el PI con desacoplador no alcanza esta referencia debido a las no linealidades del modelo y a la sintonización fijada para el punto nominal, mientras que el GPC sí lo logra gracias a su capacidad predictiva. Este resultado valida empíricamente la hipótesis principal del trabajo y establece, junto con los trade-offs identificados —mayor costo computacional, mayor complejidad de implementación y mayor dependencia del modelo—, los criterios bajo los cuales el GPC justifica su adopción frente al PI con desacoplador en aplicaciones industriales de control multivariable.
