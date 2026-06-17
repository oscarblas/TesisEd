# CAPÍTULO 4 — Análisis Comparativo del Controlador GPC frente al PID Convencional en el Sistema de Cuatro Tanques Acoplados

> **Instrucciones de uso:**
> - Para cada fórmula tienes el **preview renderizado** (lo que se debe ver) y el **código LaTeX** para Word.
> - Pega el código en Word con `Insertar → Ecuación → modo LaTeX`.
> - Si una fórmula no funciona en Word, **toma captura del preview** y continúa.
>
> **Reglas aplicadas a todas las fórmulas:**
> - Cada fórmula en **una sola línea** de código LaTeX
> - **`\|...\|`** en vez de `\left\|...\right\|`
> - **`\bar{X}`** en vez de `\overline{X}`

---

## 4.1 Introducción

El control proporcional-integral (PI) constituye, hasta la fecha, la estrategia de control más empleada en la industria moderna, abarcando entre el 90% y el 95% de los lazos de control implementados en procesos hidráulicos, químicos, energéticos y de manufactura [16]. Su éxito se sustenta en la simplicidad de su formulación, la disponibilidad nativa en cualquier autómata programable industrial y la familiaridad del personal técnico con su operación y sintonización. No obstante, la formulación clásica del PI está concebida para sistemas de una entrada y una salida (SISO), lo cual restringe su capacidad de manejar de forma natural procesos multivariables con acoplamiento cruzado. En sistemas industriales reales esta limitación suele abordarse mediante el uso de **desacopladores estáticos**, que cancelan el acople cruzado en estado estacionario y permiten que cada lazo SISO opere casi de forma independiente.

Frente a esta estrategia clásica, el Control Predictivo Generalizado (GPC) diseñado en el Capítulo 3 considera de manera explícita la naturaleza multivariable del proceso, las restricciones físicas sobre los actuadores y la dinámica conjunta de las salidas. Para validar empíricamente la superioridad del GPC frente al PI descentralizado con desacoplador, el presente capítulo desarrolla un análisis comparativo sistemático sobre un escenario operativo que evidencia los aspectos donde cada estrategia muestra sus fortalezas y limitaciones.

El escenario diseñado integra en una sola simulación los desafíos más representativos: (i) el arranque del sistema desde tanques vacíos hasta el punto estacionario, (ii) cambios de referencia simultáneos que activan el acoplamiento cruzado del sistema, (iii) la inyección de ruido gaussiano en las mediciones de los sensores y (iv) la operación en regiones alejadas del punto de linealización empleado en el diseño del controlador clásico. Esta integración permite comparar ambos controladores bajo condiciones que reproducen la operación industrial real y poner en evidencia el comportamiento dinámico, el rechazo de perturbaciones, la robustez ante ruido y la capacidad de operación extendida.

El capítulo se estructura como sigue. La sección 4.2 describe el diseño y la sintonización del controlador PI descentralizado con desacoplador estático utilizado como referencia. La sección 4.3 detalla el escenario integrado de simulación. La sección 4.4 presenta el análisis cuantitativo de los resultados, incluyendo la métrica específica de acoplamiento cruzado introducida en este trabajo. La sección 4.5 discute los hallazgos y valida las hipótesis del trabajo. La sección 4.6 describe la implementación en Simulink de ambos controladores como complemento al análisis. Finalmente, la sección 4.7 expone las conclusiones del capítulo.

---

## 4.2 Implementación del controlador PI descentralizado con desacoplador estático

Para que la comparación con el GPC sea justa y representativa, el controlador de referencia se diseña bajo las mejores prácticas reportadas en la literatura industrial. Se adopta una estrategia de **control descentralizado** (multilazo) con sintonización analítica por Internal Model Control (IMC) y se complementa con un **desacoplador estático** que cancela el acople cruzado en estado estacionario, configuración estándar en aplicaciones industriales de sistemas MIMO de baja dimensión [14] [16].

### 4.2.1 Estrategia de emparejamiento entrada-salida

En el sistema de cuatro tanques acoplados, cada bomba afecta directamente al tanque inferior de su rama y, de manera indirecta, al tanque inferior opuesto a través del acoplamiento cruzado de los tanques superiores. Examinando la matriz `B_c` del modelo linealizado se identifican los caminos directos:

- `u₁ → h₄` con ganancia `γ₁·k₁/A₄` (camino directo, rápido)
- `u₂ → h₃` con ganancia `γ₂·k₂/A₃` (camino directo, rápido)

En consecuencia, el emparejamiento adoptado es:

- **PI_1:** `u₁` controla `h₄`
- **PI_2:** `u₂` controla `h₃`

Esta selección coincide con el emparejamiento natural para configuraciones de fase mínima `(γ₁+γ₂ > 1)` reportado por Johansson [8].

### 4.2.2 Sintonización por Internal Model Control (IMC)

Cada PI se diseña de forma independiente, considerando que la otra entrada permanece constante en su valor estacionario. Bajo este supuesto, el subproceso visto por cada lazo se aproxima a un sistema de primer orden con ganancia `K` y constante de tiempo `τ`:

**Preview:**

$$ G_{loop}(s) = \frac{K}{\tau\,s + 1} $$

**LaTeX para Word:**

```latex
G_{loop}(s) = \frac{K}{\tau\,s + 1}
```

Aplicando las reglas analíticas del Internal Model Control [pendiente encontrar fuente — Rivera, Morari & Skogestad 1986], los parámetros del controlador PI resultante son:

**Preview:**

$$ K_p = \frac{\tau}{K \cdot \lambda_{imc}},\quad T_i = \tau $$

**LaTeX para Word:**

```latex
K_p = \frac{\tau}{K \cdot \lambda_{imc}},\quad T_i = \tau
```

donde `λ_imc` es la constante de tiempo deseada en lazo cerrado. Se adopta `λ_imc = τ/3` como compromiso entre velocidad de respuesta y robustez ante incertidumbre del modelo. Se omite el término derivativo (`T_d = 0`) por su elevada sensibilidad al ruido de medición y porque la dinámica del subproceso es dominantemente de primer orden, condición en la cual el aporte del término derivativo es marginal.

[INSERTAR TABLA 4.1 — Parámetros de los PI descentralizados sintonizados por IMC. Columnas: Lazo, K, τ, λ_imc, Kp, Ti. Filas: PI_1 (u₁→h₄), PI_2 (u₂→h₃). Datos generados con el script `controlador_PID.m`.]

### 4.2.3 Diseño del desacoplador estático

Para mitigar el efecto del acoplamiento cruzado, se incorpora un **desacoplador estático** entre las salidas de los PI y las entradas a la planta. Se adopta la formulación simplificada de Skogestad [pendiente encontrar fuente — Skogestad & Postlethwaite 2005], que mantiene la diagonal unitaria y emplea las ganancias DC cruzadas para cancelar la interacción:

**Preview:**

$$ \mathbf{D} = \begin{bmatrix} 1 & -k_{12} \\ -k_{21} & 1 \end{bmatrix} $$

**LaTeX para Word:**

```latex
\mathbf{D} = \begin{bmatrix} 1 & -k_{12} \\ -k_{21} & 1 \end{bmatrix}
```

donde los coeficientes `k₁₂` y `k₂₁` se calculan a partir de la matriz de ganancias DC del sistema:

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

Conviene destacar dos características importantes de esta formulación. Primero, el desacoplador estático cancela el acople **solo en estado estacionario** y alrededor del punto de operación nominal; cuando el sistema opera en regiones alejadas, las ganancias reales de la planta cambian (por la dependencia con `√h`) y el desacoplador pierde efectividad. Segundo, el desacoplador requiere conocer la matriz de ganancias estáticas del modelo, lo cual lo asemeja al GPC en su dependencia del modelo, aunque sin las ventajas de la predicción explícita ni del manejo óptimo de restricciones.

[INSERTAR TABLA 4.2 — Coeficientes del desacoplador estático: `k₁₂`, `k₂₁`. Datos generados con `controlador_PID.m`.]

### 4.2.4 Algoritmo discreto con anti-windup

La implementación digital del controlador se realiza en **forma incremental** (también llamada forma de velocidad), recomendada para controladores PI industriales al evitar saltos bruscos ante cambios de setpoint y simplificar la incorporación del anti-windup [pendiente encontrar fuente — Åström & Hägglund]:

**Preview:**

$$ \Delta v(k) = K_p \left( e(k) - e(k-1) \right) + \frac{K_p\,T_s}{T_i}\,e(k) $$

**LaTeX para Word:**

```latex
\Delta v(k) = K_p \left( e(k) - e(k-1) \right) + \frac{K_p\,T_s}{T_i}\,e(k)
```

La salida incremental `Δv` de cada PI alimenta el desacoplador, cuya salida `Δu` se acumula y satura:

**Preview:**

$$ \mathbf{u}(k) = \text{sat}\left( \mathbf{u}(k-1) + \mathbf{D}\,\Delta\mathbf{v}(k),\ \mathbf{u}_{min},\ \mathbf{u}_{max} \right) $$

**LaTeX para Word:**

```latex
\mathbf{u}(k) = \text{sat}\left( \mathbf{u}(k-1) + \mathbf{D}\,\Delta\mathbf{v}(k),\ \mathbf{u}_{min},\ \mathbf{u}_{max} \right)
```

La estrategia **anti-windup** se incorpora directamente saturando la señal `u(k)` a los límites físicos del actuador antes de su aplicación, sin que el incremento que excede el rango se acumule en la acción integral. Este esquema —denominado de saturación condicional— es robusto, simple de implementar y ampliamente aceptado en la industria.

---

## 4.3 Escenario integrado de simulación

A diferencia de los trabajos de Oré Sánchez [pendiente encontrar fuente] y Sánchez Zurita [10], que evalúan el desempeño en escenarios separados (caso nominal, perturbaciones e incertidumbre), en el presente trabajo se ha diseñado un **escenario integrado** que combina, en una sola simulación, los desafíos más representativos del control multivariable. Esta integración permite comparar el comportamiento global de ambos controladores en una secuencia operativa coherente y observar cómo cada uno responde a la sucesión de eventos típicos en una planta industrial.

### 4.3.1 Configuración común de simulación

Todos los experimentos se ejecutan bajo las siguientes condiciones:

- **Planta:** modelo no lineal de los cuatro tanques acoplados (Capítulo 2), integrado numéricamente mediante `ode45` en MATLAB y `ode45` variable-step en Simulink.
- **Estado inicial:** `h(0) = [0, 0, 0, 0]ᵀ` (tanques vacíos).
- **Entradas iniciales:** `u(0) = [0, 0]ᵀ` (bombas apagadas).
- **Tiempo de muestreo:** `T_s = 1 s` para ambos controladores.
- **Duración:** `T_sim = 1500 s` (extensible si las dinámicas no han converso).
- **Punto de operación nominal:** `h₃⁰ = h₄⁰ = 25 cm`.
- **Restricciones:** `u_min = 0` y `u_max = 2·u_s⁰` por canal.

### 4.3.2 Trayectoria de referencias

Se aplican cambios de setpoint en cuatro instantes distintos que activan secuencialmente los distintos aspectos del control multivariable:

**Para `h₃`:**

| Tiempo | Valor de `ref_h₃` |
|---|---|
| `0 ≤ t < 400 s` | 25 cm |
| `400 ≤ t < 1200 s` | 30 cm |
| `t ≥ 1200 s` | 25 cm |

**Para `h₄`:**

| Tiempo | Valor de `ref_h₄` |
|---|---|
| `0 ≤ t < 800 s` | 25 cm |
| `800 ≤ t < 1200 s` | 20 cm |
| `t ≥ 1200 s` | 35 cm |

Esta secuencia evalúa cuatro situaciones de interés:

1. **Arranque (0 ≤ t ≤ 400 s):** llenado del sistema desde tanques vacíos hasta el punto estacionario.
2. **Cambio aislado en `h₃` (400 ≤ t ≤ 800 s):** primera prueba de seguimiento, con perturbación cruzada esperada en `h₄`.
3. **Cambio aislado en `h₄` (800 ≤ t ≤ 1200 s):** segunda prueba de seguimiento, con perturbación cruzada esperada en `h₃`.
4. **Cambios simultáneos opuestos (t ≥ 1200 s):** `h₃` desciende a su valor nominal mientras `h₄` se aleja significativamente del punto de operación (a 35 cm). Esta condición es el caso crítico del capítulo, ya que combina acoplamiento cruzado, operación lejos del punto de linealización y máxima exigencia para el control coordinado.

### 4.3.3 Inyección de ruido en sensores

Para reproducir las condiciones realistas de operación industrial, a partir del instante `t = 1100 s` se añade **ruido gaussiano blanco** a las mediciones de `h₃` y `h₄` que ingresan a los controladores:

**Preview:**

$$ y_{med,i}(k) = h_i(k) + n_i(k),\quad n_i(k) \sim \mathcal{N}(0, \sigma^2) $$

**LaTeX para Word:**

```latex
y_{med,i}(k) = h_i(k) + n_i(k),\quad n_i(k) \sim \mathcal{N}(0, \sigma^2)
```

con desviación estándar `σ = 0.3 cm`, valor representativo de transmisores industriales de presión hidrostática de gama media. La activación del ruido en `t = 1100 s` permite observar cómo cada controlador responde al ruido **justo antes** del cambio simultáneo de referencias en `t = 1200 s`, evaluando si el ruido degrada la capacidad de respuesta del lazo cerrado.

### 4.3.4 Justificación del escenario

La integración de los cuatro eventos en una sola simulación responde a la necesidad de evaluar el desempeño global del controlador, no solo su comportamiento ante perturbaciones aisladas. En una planta industrial real, los eventos no ocurren de forma desacoplada: las perturbaciones, los cambios de setpoint y el ruido coexisten y se superponen. El escenario propuesto reproduce esta realidad y permite responder a la pregunta central del trabajo: ¿qué controlador exhibe mejor desempeño cuando todos los factores operativos actúan simultáneamente?

---

## 4.4 Análisis comparativo cuantitativo

### 4.4.1 Métricas adoptadas y ventanas de evaluación

Para cada controlador se calculan los seis criterios de desempeño definidos en la sección 3.2 (IAE, ISE, ITAE, tiempo de establecimiento, sobrepico y esfuerzo de control), pero reportados en **dos ventanas temporales** diferenciadas:

- **(a) Métricas globales:** evaluadas sobre toda la simulación (0 ≤ t ≤ T_sim). Incluyen el arranque desde tanques vacíos.
- **(b) Métricas en operación normal:** evaluadas únicamente a partir de `t = 400 s`, es decir, una vez alcanzado el punto estacionario. Estas son las métricas relevantes para evaluar el desempeño del controlador en régimen operativo industrial, donde se aprecian los efectos del acoplamiento y la robustez ante perturbaciones.

Esta distinción es metodológicamente importante porque el arranque desde tanques vacíos representa una fase transitoria de llenado del sistema, no un escenario de operación normal. Una métrica global puede verse dominada por la magnitud del error durante el arranque, ocultando el desempeño real del controlador en régimen operativo. Reportar ambas métricas proporciona una visión completa y permite al lector identificar dónde se manifiestan las diferencias entre los controladores.

[INSERTAR TABLA 4.3 — Métricas globales por controlador. Columnas: Métrica, GPC, PI+Desacoplador. Filas: IAE, ISE, ITAE, esfuerzo. Datos generados con `comparacion_GPC_vs_PID.m`.]

[INSERTAR TABLA 4.4 — Métricas en operación normal (t ≥ 400 s) por controlador. Mismo formato que la Tabla 4.3.]

### 4.4.2 Métrica de acoplamiento cruzado

Las métricas integrales clásicas no capturan adecuadamente la magnitud de la **interacción cruzada** entre lazos, que es precisamente la característica que se desea evidenciar al comparar un controlador multivariable con uno descentralizado. Por esta razón, se introduce una métrica específica que cuantifica cuánto se desvía una salida cuando se modifica únicamente la referencia de la otra salida.

Para el cambio de referencia en `h₃` en `t = 400 s`, la métrica se define como la integral del error de `h₄` durante una ventana posterior al cambio:

**Preview:**

$$ \text{INT}_{h_4} = \frac{1}{|\Delta r_3|} \int_{t_c}^{t_c + \Delta T} \left| e_{h_4}(t) \right|\, dt $$

**LaTeX para Word:**

```latex
\text{INT}_{h_4} = \frac{1}{|\Delta r_3|} \int_{t_c}^{t_c + \Delta T} \left| e_{h_4}(t) \right|\, dt
```

donde `Δr₃ = 5 cm` es el cambio nominal del setpoint que provoca el efecto cruzado, `t_c = 400 s` el instante del cambio y `ΔT = 300 s` la ventana de observación. Análogamente se define `INT_{h_3}` para el cambio de referencia en `h₄` en `t = 800 s`. Valores bajos de `INT` indican un desacoplamiento efectivo entre los lazos.

[INSERTAR TABLA 4.5 — Métrica de acoplamiento cruzado. Columnas: GPC, PI+Desacoplador. Filas: INT_h4 (perturbación en h₄ por cambio en r₃), INT_h3 (perturbación en h₃ por cambio en r₄). Datos generados con `comparacion_GPC_vs_PID.m`.]

### 4.4.3 Resultados gráficos

[INSERTAR FIGURA 4.1 — Respuesta comparativa de `h₃` durante toda la simulación. Curvas: GPC (azul), PI+Desacoplador (verde), referencia (línea negra punteada). Líneas verticales marcan los eventos: cambio SP h₃ (t=400 s), cambio SP h₄ (t=800 s), inyección de ruido (t=1100 s), cambios simultáneos (t=1200 s).]

[INSERTAR FIGURA 4.2 — Respuesta comparativa de `h₄`. Mismo formato que la Figura 4.1.]

[INSERTAR FIGURA 4.3 — Señales de control `u₁` y `u₂` aplicadas a las bombas. Permite visualizar el esfuerzo de control y la activación de las saturaciones.]

[INSERTAR FIGURA 4.4 — Detalle del tramo `t ≥ 1200 s` donde se aprecia el comportamiento ante operación lejos del punto de operación. Es el tramo crítico que evidencia las limitaciones del PI+Desacoplador.]

---

## 4.5 Discusión de resultados y validación de la hipótesis

### 4.5.1 Comportamiento ante referencias cruzadas (acoplamiento)

El PI descentralizado, aun con el desacoplador estático, presenta perturbaciones notorias en una salida cuando cambia el setpoint de la otra. Esto se debe a que el desacoplador estático cancela la interacción **únicamente en estado estacionario**: durante el régimen transitorio, los acoples cruzados dinámicos no son compensados. El GPC, al considerar la dinámica completa del sistema en su predicción a `N` pasos, anticipa el efecto del acople y coordina simultáneamente las dos entradas para minimizarlo desde el primer paso. La métrica `INT` (Tabla 4.5) cuantifica esta ventaja del GPC.

### 4.5.2 Robustez ante ruido de medición

Tras la inyección de ruido en `t = 1100 s`, ambos controladores transmiten parte del ruido a las señales de control (Figura 4.3). El GPC, por la naturaleza filtrante de su horizonte de predicción y la ponderación `λ` del esfuerzo de control, presenta una menor amplificación del ruido en las bombas que el PI descentralizado. Esto se refleja en una menor variación de `u` durante el último tramo de la simulación, lo cual es relevante para preservar la vida útil de los actuadores industriales.

### 4.5.3 Operación lejos del punto de linealización

El tramo crítico del escenario corresponde a `t ≥ 1200 s`, cuando el setpoint de `h₄` se establece en `35 cm` —un alejamiento del **40%** respecto al punto de operación nominal `h₄⁰ = 25 cm`. En esta región, la planta no lineal presenta dinámicas significativamente distintas a las consideradas en la sintonización IMC del PI, dado que las constantes de tiempo de los tanques dependen de `√h`. Como consecuencia:

- El **PI descentralizado no alcanza el setpoint de 35 cm**, exhibiendo un error en estado estacionario persistente. La sintonización IMC con `λ_imc = τ/3`, calculada para `h = 25 cm`, no proporciona la ganancia adecuada para esta región operativa, y el desacoplador estático tampoco compensa adecuadamente porque sus coeficientes asumen la matriz de ganancias DC del punto nominal.
- El **GPC sí alcanza el setpoint de 35 cm**, aunque con un transitorio más lento que en la región nominal. La capacidad de predicción del GPC permite anticipar el efecto de la entrada acumulada sobre el horizonte futuro, compensando parcialmente las no linealidades del modelo lineal interno.

Este resultado constituye una validación experimental contundente de la principal hipótesis del trabajo: **el control predictivo extiende la región de operación admisible del sistema más allá del entorno inmediato del punto de linealización**, mientras que el PI descentralizado queda restringido a una vecindad estrecha de su sintonización original.

### 4.5.4 Trade-offs identificados

La comparación no es absoluta. Las ventajas del GPC vienen acompañadas de costos que conviene reconocer:

- **Costo computacional superior:** la resolución del QP en cada periodo de muestreo es computacionalmente más exigente que la evaluación recursiva de un PI.
- **Complejidad de implementación:** el GPC requiere infraestructura matemática (modelo, optimizador) ausente en el PI.
- **Dependencia del modelo:** tanto el GPC como el desacoplador requieren conocer el modelo dinámico del proceso, pero el GPC lo emplea de forma más robusta (proyección al futuro) que el desacoplador (inversión algebraica).

La cuantificación rigurosa de estos trade-offs permite responder de manera fundamentada a la pregunta de cuándo se justifica implementar un GPC en lugar de un PI convencional con desacoplador en una aplicación industrial.

---

## 4.6 Implementación en Simulink

Como complemento al análisis basado en scripts de MATLAB, ambos controladores se han implementado adicionalmente en el entorno **MATLAB/Simulink**, lo cual permite verificar la consistencia de los resultados y constituye un primer paso hacia una eventual implementación en hardware industrial.

### 4.6.1 Estructura del modelo PI+Desacoplador

El modelo Simulink del controlador PI con desacoplador integra los siguientes bloques:

- Dos bloques `Step` (o un bloque `Signal Editor`) para las referencias `ref_h₃` y `ref_h₄`
- Dos sumadores que generan los errores `e₁` y `e₂`
- Dos bloques `Discrete PID Controller` configurados como PI con sintonización IMC
- Un bloque `MATLAB Function` que implementa el desacoplador estático mediante la matriz `D`
- Dos bloques `Saturation` que aplican los límites físicos a las señales de control
- Un bloque `MATLAB Function` que implementa el modelo no lineal de la planta
- Un `Unit Delay` con condición inicial `zeros(4,1)` para retroalimentar el estado
- Dos `Selectores` que extraen `h₃` y `h₄` del vector de estado para cerrar los lazos

[INSERTAR FIGURA 4.5 — Diagrama del modelo Simulink del PI+Desacoplador. Generado en Simulink.]

### 4.6.2 Estructura del modelo GPC

El modelo Simulink del GPC presenta una estructura sustancialmente más compacta, ya que toda la lógica del controlador —construcción de la respuesta libre, formulación del QP, resolución y aplicación del primer incremento— se encapsula en un único bloque `MATLAB Function` denominado `gpc_step`. Los bloques periféricos son:

- Dos bloques `Step` y un `Mux` que generan el vector de referencias `r_act` (2×1)
- El bloque `gpc_step` que recibe `y_med`, `u_prev` y `r_act` y produce `u_new`
- Un bloque `Saturation` para aplicar los límites físicos
- El mismo bloque `MATLAB Function` de la planta no lineal
- Dos `Unit Delay`: uno para realimentar el estado `h` (con IC `zeros(4,1)`) y otro para realimentar la entrada `u` (con IC `zeros(2,1)`)

[INSERTAR FIGURA 4.6 — Diagrama del modelo Simulink del GPC. Generado en Simulink.]

### 4.6.3 Configuración del solver

Para garantizar la consistencia entre los resultados de MATLAB y de Simulink, se configura el solver de Simulink como `ode45` con paso variable, equivalente al utilizado por defecto en los scripts. La elección del solver de paso variable es relevante por dos razones: primero, porque adapta automáticamente el tamaño del paso de integración en función de la curvatura local del modelo no lineal, manteniendo precisión incluso en regiones alejadas del punto de operación donde las no linealidades son más pronunciadas; y segundo, porque experimentos preliminares con el solver `ode4` de paso fijo evidenciaron pérdidas de precisión que se manifestaban como errores en estado estacionario en regiones extremas del rango operativo, comportamiento que no reflejaba el desempeño real de los controladores sino una limitación numérica del solver.

Adicionalmente, los Discrete PID Controllers se configuran con **integrator method Forward Euler** y antiwindup **back-calculation** con coeficiente `Kb = 1`, garantizando la equivalencia exacta con la formulación incremental empleada en los scripts.

---

## 4.7 Conclusiones del capítulo

En el presente capítulo se ha desarrollado un análisis comparativo del controlador predictivo generalizado (GPC) diseñado en el Capítulo 3 frente a un controlador PI descentralizado con desacoplador estático sintonizado por Internal Model Control, aplicado al sistema hidráulico de cuatro tanques acoplados. La comparación se sustenta en un escenario integrado que combina en una sola simulación los principales desafíos del control multivariable: arranque del sistema desde tanques vacíos, cambios secuenciales y simultáneos de referencia, inyección de ruido gaussiano en los sensores y operación significativamente alejada del punto de linealización.

Los resultados cuantitativos, respaldados por los seis criterios de desempeño del Capítulo 3 y la métrica específica de acoplamiento cruzado introducida en este trabajo, evidencian la superioridad del GPC en los aspectos donde el sistema multivariable manifiesta sus características más complejas. En particular, el GPC reduce significativamente la magnitud de la interacción cruzada entre los lazos, presenta menor amplificación del ruido en las señales de control y extiende la región de operación admisible más allá del entorno inmediato del punto de linealización. El caso más representativo se observa en el tramo final del escenario (`t ≥ 1200 s`), donde el setpoint de `h₄` se establece en `35 cm`: el PI descentralizado, aun con desacoplador, no alcanza esta referencia debido a las no linealidades del modelo, mientras que el GPC sí lo logra gracias a su capacidad predictiva.

La comparación revela también los costos asociados a la mayor sofisticación del GPC: un costo computacional notablemente superior por iteración, una complejidad de implementación que requiere infraestructura matemática ausente en el PI convencional y una dependencia más estricta del modelo del proceso. La cuantificación de estos trade-offs permite responder a la pregunta central del trabajo y establecer las condiciones bajo las cuales el GPC justifica su adopción frente al PI con desacoplador en aplicaciones industriales de control multivariable.

Finalmente, la implementación adicional en Simulink complementa el análisis basado en scripts de MATLAB, demostrando que las estrategias propuestas son trasladables a entornos de simulación gráfica ampliamente utilizados en la industria. Esto sienta una base concreta para una eventual extensión del trabajo hacia la validación experimental en la planta piloto del Laboratorio de Control Avanzado de la PUCP, que constituye una línea natural de continuación de la presente investigación.
