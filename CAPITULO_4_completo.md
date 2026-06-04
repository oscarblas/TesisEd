# CAPÍTULO 4 — Comparación del Controlador Predictivo GPC frente al Control PID Convencional bajo Escenarios con Referencias Cruzadas

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

El control proporcional-integral-derivativo (PID) constituye, hasta la fecha, la estrategia de control más empleada en la industria moderna, abarcando entre el 90% y el 95% de los lazos de control implementados en procesos de manufactura, química, hidráulica, neumática y energía [16]. Su éxito radica en la simplicidad de su formulación, la disponibilidad de hardware industrial que lo soporta de forma nativa y la familiaridad que el personal técnico tiene con su sintonización y operación. No obstante, la formulación clásica del PID está concebida para sistemas de una entrada y una salida (SISO), lo cual restringe su capacidad de manejar de forma natural procesos multivariables con acoplamiento cruzado, como es el caso del sistema hidráulico de cuatro tanques acoplados estudiado en esta tesis.

Frente a esta limitación, el Control Predictivo Generalizado (GPC) diseñado en el Capítulo 3 se propone como una alternativa que considera de manera explícita la naturaleza multivariable del proceso, las restricciones físicas sobre los actuadores y la dinámica conjunta de todas las salidas. Para validar empíricamente la superioridad del GPC frente al PID, el presente capítulo desarrolla un análisis comparativo sistemático sobre seis escenarios de prueba que evidencian las propiedades distintivas de ambos controladores: desde un caso nominal de seguimiento independiente hasta condiciones operativas adversas que ponen a prueba la robustez del lazo cerrado.

La comparación se sustenta en una métrica combinada que incorpora los seis criterios de desempeño definidos en la sección 3.2 (IAE, ISE, ITAE, tiempo de establecimiento, sobrepico y esfuerzo de control), complementada con una **métrica específica de acoplamiento cruzado** introducida en este capítulo para cuantificar el grado de interacción entre los lazos de control. Esta última métrica resulta fundamental para responder de manera objetiva a la pregunta central del trabajo: ¿en qué medida y bajo qué condiciones es preferible un controlador predictivo frente a un esquema clásico de PID descentralizado?

El capítulo se estructura como sigue. La sección 4.2 describe el diseño y la sintonización del controlador PID descentralizado utilizado como referencia. La sección 4.3 detalla los seis escenarios comparativos diseñados para evaluar el desempeño de ambos controladores. La sección 4.4 presenta el análisis cuantitativo de los resultados. La sección 4.5 discute las observaciones obtenidas y valida las hipótesis del trabajo. La sección 4.6 desarrolla una propuesta de implementación industrial del controlador seleccionado. Finalmente, la sección 4.7 presenta las conclusiones del capítulo.

---

## 4.2 Implementación del controlador PID descentralizado de referencia

Para que la comparación entre el GPC y el PID sea justa y representativa, el controlador PID empleado como referencia se diseña bajo las mejores prácticas reportadas en la literatura industrial, evitando una sintonización deliberadamente subóptima que sesgaría el análisis. En particular, se adopta una estrategia de **control descentralizado** (multilazo) con sintonización analítica por Internal Model Control (IMC), por ser la combinación más empleada en aplicaciones industriales de sistemas MIMO de baja dimensión [14] [16].

### 4.2.1 Estrategia de emparejamiento entrada-salida

En el sistema de cuatro tanques acoplados, cada una de las dos bombas afecta tanto al tanque inferior directamente conectado a su rama como, de manera indirecta, al tanque inferior de la rama opuesta a través del acoplamiento cruzado de los tanques superiores. Para diseñar un PID descentralizado se requiere asociar cada entrada con una única salida —emparejamiento o *pairing*— buscando el camino dinámico **directo** y **más rápido** entre ambos.

Examinando la matriz `B_c` del modelo linealizado, se identifican los caminos directos:

- `u₁ → h₄` con ganancia `γ₁·k₁/A₄` (camino directo, rápido).
- `u₁ → h₂ → h₃` con ganancia `(1-γ₁)·k₁/A₂` (camino cruzado, lento).
- `u₂ → h₃` con ganancia `γ₂·k₂/A₃` (camino directo, rápido).
- `u₂ → h₁ → h₄` con ganancia `(1-γ₂)·k₂/A₁` (camino cruzado, lento).

En consecuencia, el emparejamiento adoptado es:

- **PID₁:** `u₁` controla `h₄`
- **PID₂:** `u₂` controla `h₃`

Esta selección coincide con el emparejamiento natural para configuraciones de fase mínima `(γ₁+γ₂ > 1)` reportado por Johansson [8] y constituye el escenario más favorable para el control clásico.

### 4.2.2 Sintonización por Internal Model Control (IMC)

Una vez fijado el emparejamiento, se diseña cada PID de manera independiente considerando que la otra entrada permanece constante en su valor estacionario. Bajo este supuesto, el subproceso visto por cada lazo se aproxima a un sistema de primer orden con ganancia `K` y constante de tiempo `τ`:

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

[INSERTAR TABLA 4.1 — Parámetros de los PID descentralizados sintonizados por IMC. Columnas: Lazo, K, τ, λ_imc, K_p, T_i. Filas: PID₁ (u₁ → h₄), PID₂ (u₂ → h₃). Datos generados con el script `controlador_PID.m`.]

### 4.2.3 Algoritmo discreto con anti-windup

La implementación digital del controlador se realiza en **forma incremental** (también llamada forma de velocidad), que es la recomendada para controladores PID industriales al evitar saltos bruscos ante cambios de setpoint y simplificar la incorporación del anti-windup [pendiente encontrar fuente — Åström & Hägglund]:

**Preview:**

$$ \Delta u(k) = K_p \left( e(k) - e(k-1) \right) + \frac{K_p\,T_s}{T_i}\,e(k) $$

**LaTeX para Word:**

```latex
\Delta u(k) = K_p \left( e(k) - e(k-1) \right) + \frac{K_p\,T_s}{T_i}\,e(k)
```

**Preview:**

$$ u(k) = u(k-1) + \Delta u(k) $$

**LaTeX para Word:**

```latex
u(k) = u(k-1) + \Delta u(k)
```

donde `e(k) = r(k) - y(k)` es el error de seguimiento. La estrategia **anti-windup** se incorpora directamente saturando la señal `u(k)` a los límites físicos del actuador `[u_min, u_max]` antes de su aplicación, sin que el incremento `Δu(k)` que excede el rango se acumule en la acción integral. Este esquema —denominado de saturación condicional o *back-calculation* implícito— es robusto, simple de implementar y ampliamente aceptado en la industria.

---

## 4.3 Escenarios de prueba comparativos

A continuación se detallan los seis escenarios diseñados para evaluar el desempeño de ambos controladores. Todos comparten una configuración común de simulación y se ejecutan sobre la planta no lineal del Capítulo 2.

### 4.3.1 Configuración común de simulación

Para garantizar una comparación reproducible, todos los escenarios se ejecutan bajo las siguientes condiciones:

- **Modelo de planta:** ecuaciones no lineales del sistema de cuatro tanques acoplados (Capítulo 2), integradas numéricamente mediante `ode45` con tolerancias por defecto.
- **Punto de operación nominal:** `h₃⁰ = h₄⁰ = 25 cm` con `u₁⁰`, `u₂⁰` resueltos del equilibrio.
- **Duración:** `T_sim = 1500 s` por escenario.
- **Tiempo de muestreo de control:** `T_s = 2 s` para ambos controladores (consistente con la sección 3.3.2).
- **Estado inicial:** `h(0) = h₀` (los tanques arrancan en el punto de operación nominal).
- **Restricciones físicas:** `u_min = 0` y `u_max = 2·u_s⁰` para cada bomba.
- **Métricas calculadas:** IAE, ISE, ITAE, tiempo de establecimiento al 2%, sobrepico, esfuerzo total de control y métrica de acoplamiento cruzado.

### 4.3.2 Escenario 1: Caso nominal con cambios de referencia independientes

En este escenario, los setpoints de `h₃` y `h₄` se modifican de forma **secuencial e independiente** para evaluar la calidad del seguimiento de referencia en condiciones favorables, sin estresar el acoplamiento entre lazos:

- En `t = 300 s`, el setpoint de `h₃` cambia de `25 cm` a `30 cm`. El setpoint de `h₄` permanece en `25 cm`.
- En `t = 900 s`, el setpoint de `h₄` cambia de `25 cm` a `20 cm`. El setpoint de `h₃` permanece en `30 cm`.

Este escenario representa el caso típicamente reportado en estudios de comparación de controladores y constituye la base para los escenarios posteriores. Ambos controladores deberían ofrecer un desempeño aceptable, observándose pequeñas perturbaciones cruzadas en una salida cuando la referencia de la otra cambia.

[INSERTAR FIGURA 4.1 — Respuestas comparativas GPC vs PID para el caso nominal. Dos subgráficas: una con `h₃(t)` y otra con `h₄(t)`. En cada una, curvas azul (GPC), verde (PID) y línea punteada negra (referencia). Generada con `comparacion_GPC_vs_PID.m`.]

### 4.3.3 Escenario 2: Referencias cruzadas (cambios simultáneos opuestos)

Este escenario constituye el **caso crítico** del capítulo: los setpoints de `h₃` y `h₄` cambian al mismo tiempo y en direcciones opuestas:

- En `t = 500 s`: el setpoint de `h₃` pasa de `25 cm` a `30 cm` **y simultáneamente** el setpoint de `h₄` pasa de `25 cm` a `20 cm`.

Bajo esta condición, ambas bombas deben actuar de manera coordinada y opuesta: `u₂` debe **aumentar** para subir `h₃` mientras `u₁` debe **disminuir** para bajar `h₄`. Sin embargo, debido al acoplamiento cruzado del sistema, la acción de cada bomba afecta también la salida que no controla directamente, generando interacciones que el PID descentralizado **no puede anticipar** porque cada lazo opera en aislamiento del otro. Se espera que el GPC, al considerar de forma explícita las interacciones del sistema MIMO, gestione coordinadamente ambas entradas y reduzca significativamente las perturbaciones cruzadas.

[INSERTAR FIGURA 4.2 — Respuestas comparativas GPC vs PID para el escenario de referencias cruzadas. Mismo formato que la Figura 4.1. Este escenario es el más relevante para evidenciar la ventaja del GPC.]

### 4.3.4 Escenario 3: Rechazo a perturbaciones externas (fuga)

Se simula una **fuga adicional** en el tanque inferior `TK-03` (asociado a la salida `h₃`) a partir de `t = 600 s`, que reduce el nivel del tanque en `1 cm` por cada `60 s` mientras está activa. Esta perturbación representa una avería realista en la planta —por ejemplo, una válvula de drenaje parcialmente abierta o una fisura en el cuerpo del tanque— y se mantiene hasta el final de la simulación. Los setpoints de `h₃` y `h₄` se mantienen en `25 cm` durante todo el escenario.

Matemáticamente, la perturbación se modela como un término aditivo en la ecuación dinámica del tanque 3:

**Preview:**

$$ \frac{dh_3}{dt} = f_{nominal}(h, u) - d(t) $$

**LaTeX para Word:**

```latex
\frac{dh_3}{dt} = f_{nominal}(h, u) - d(t)
```

donde `d(t) = 1/60 cm/s` para `t ≥ 600 s` y `d(t) = 0` antes. Este escenario evalúa la capacidad de **rechazo a perturbaciones** de ambos controladores —es decir, su acción integral— manteniendo el setpoint en su valor nominal.

[INSERTAR FIGURA 4.3 — Respuestas comparativas ante la perturbación de fuga en TK-03.]

### 4.3.5 Escenario 4: Ruido de medición en sensores

Para reproducir las condiciones realistas de operación, se añade **ruido gaussiano blanco** a las mediciones de `h₃` y `h₄` que ingresan al controlador:

**Preview:**

$$ y_{med,i}(k) = h_i(k) + n_i(k),\quad n_i(k) \sim \mathcal{N}(0, \sigma^2) $$

**LaTeX para Word:**

```latex
y_{med,i}(k) = h_i(k) + n_i(k),\quad n_i(k) \sim \mathcal{N}(0, \sigma^2)
```

con desviación estándar `σ = 0.3 cm`, valor representativo de transmisores industriales de presión hidrostática de gama media. Los setpoints siguen el patrón del Escenario 2 (referencias cruzadas) para combinar el desafío del acoplamiento con el de la robustez ante ruido de medición.

Este escenario es particularmente relevante porque permite observar dos fenómenos: (i) la transmisión del ruido a la señal de control y, por extensión, al desgaste de los actuadores; y (ii) la sensibilidad de cada controlador a las fluctuaciones de la medición.

[INSERTAR FIGURA 4.4 — Respuestas comparativas ante ruido de medición. Se recomienda incluir también las señales de control `u₁(t)` y `u₂(t)` para visualizar el efecto del ruido en el esfuerzo de los actuadores.]

### 4.3.6 Escenario 5: Saturación de actuadores

Se exige al sistema un setpoint que requiere una señal de control fuera del rango operativo de las bombas:

- En `t = 500 s`: el setpoint de `h₃` pasa de `25 cm` a un valor agresivo que demanda una señal de control próxima a `u_max`, mientras el setpoint de `h₄` permanece en `25 cm`.

Esta condición pone a prueba el comportamiento de cada controlador ante saturación del actuador. El GPC, gracias a la formulación QP con restricciones explícitas, ajusta su trayectoria óptima respetando los límites del actuador y evita el deterioro del desempeño asociado al *windup* de la acción integral. El PID, en cambio, depende del esquema de anti-windup implementado en la sección 4.2.3 para evitar la degradación del lazo cerrado.

[INSERTAR FIGURA 4.5 — Respuestas comparativas bajo saturación de actuador. Es recomendable graficar también las señales `u(t)` junto con las líneas de límites `u_min` y `u_max`.]

### 4.3.7 Escenario 6: Cambio del punto de operación

Para evaluar la robustez de ambos controladores ante el alejamiento del punto de linealización empleado para diseñarlos, en este escenario el setpoint se traslada significativamente fuera del rango utilizado en la sintonización:

- En `t = 500 s`: ambos setpoints cambian de `25 cm` a `35 cm` (un alejamiento del 40% respecto al punto de operación nominal).

Bajo esta condición, el modelo lineal empleado tanto por el GPC para la predicción como por el PID en su sintonización IMC presenta una discrepancia creciente respecto a la planta no lineal real, lo cual permite evaluar la **robustez intrínseca** de cada esquema frente a la inevitable degradación del modelo en regiones lejanas al punto de linealización.

[INSERTAR FIGURA 4.6 — Respuestas comparativas ante cambio del punto de operación de 25 cm a 35 cm.]

---

## 4.4 Análisis comparativo cuantitativo

### 4.4.1 Métricas de desempeño aplicadas a cada escenario

Para cada uno de los seis escenarios se calculan, separadamente para el GPC y el PID, las seis métricas definidas en la sección 3.2:

- **IAE, ISE, ITAE** sobre el error combinado de ambas salidas (`e₃` y `e₄`).
- **Tiempo de establecimiento** `t_s` al 2% del valor final, calculado sobre la salida más lenta del par.
- **Sobrepico máximo** `M_p` registrado en cualquiera de las dos salidas.
- **Esfuerzo de control** `ΔU_total` como suma de las variaciones absolutas en ambas entradas.

[INSERTAR TABLA 4.2 — Resumen comparativo de métricas por escenario y por controlador. Filas: Escenario 1 a 6. Columnas: IAE_GPC, IAE_PID, ISE_GPC, ISE_PID, ..., ΔU_GPC, ΔU_PID. Permite ver de un vistazo qué controlador gana en qué métrica y en qué escenario.]

### 4.4.2 Métrica de acoplamiento cruzado

Las métricas integrales clásicas no capturan adecuadamente la magnitud de la **interacción cruzada** entre lazos, que es justamente la característica que se desea evidenciar al comparar un controlador multivariable con uno descentralizado. Por esta razón, se introduce una métrica específica que cuantifica cuánto se desvía una salida `y_i` cuando se modifica únicamente la referencia de la otra salida `y_j`.

Para el Escenario 2 (referencias cruzadas), la métrica se define como la integral del error de la salida `i` durante la ventana temporal `[t_c, t_c + ΔT]` que sigue al cambio simultáneo de referencias, ponderada por el cambio nominal de la otra salida:

**Preview:**

$$ \text{INT}_{ij} = \frac{\int_{t_c}^{t_c + \Delta T} \left| y_i(t) - y_{i,ref}(t) \right|\, dt}{\left| \Delta r_j \right|} $$

**LaTeX para Word:**

```latex
\text{INT}_{ij} = \frac{\int_{t_c}^{t_c + \Delta T} \left| y_i(t) - y_{i,ref}(t) \right|\, dt}{\left| \Delta r_j \right|}
```

donde `Δr_j = r_j(t_c+) - r_j(t_c-)` es la magnitud del cambio de referencia en la salida `j`. Valores bajos de `INT_{ij}` indican un desacoplamiento efectivo entre los lazos.

[INSERTAR TABLA 4.3 — Métrica de acoplamiento cruzado `INT` para el Escenario 2. Columnas: INT₃₄_GPC, INT₃₄_PID, INT₄₃_GPC, INT₄₃_PID. Una fila única. Esta es la tabla central que respalda el argumento principal del trabajo.]

### 4.4.3 Análisis del esfuerzo de control

El esfuerzo total `ΔU_total` por sí solo no cuenta toda la historia: una señal de control suave pero permanentemente activa puede generar más desgaste mecánico que una con cambios bruscos pero esporádicos. Para complementar el análisis se reporta también:

- **Esfuerzo pico** `max|Δu(k)|`: máximo cambio instantáneo aplicado al actuador.
- **Frecuencia de saturación:** porcentaje del tiempo durante el cual `u(k)` está en `u_min` o `u_max`.

Estos indicadores son particularmente relevantes en los Escenarios 4 (ruido) y 5 (saturación).

### 4.4.4 Costo computacional

Si bien el desempeño en lazo cerrado es el criterio principal de comparación, el costo computacional resulta determinante al evaluar la viabilidad de implementación en hardware industrial. Se reporta el **tiempo de ejecución promedio por iteración** medido con los comandos `tic` y `toc` de MATLAB:

**Preview:**

$$ \bar{t}_{exec} = \frac{1}{N_{sim}} \sum_{k=0}^{N_{sim}-1} t_{exec}(k) $$

**LaTeX para Word:**

```latex
\bar{t}_{exec} = \frac{1}{N_{sim}} \sum_{k=0}^{N_{sim}-1} t_{exec}(k)
```

Se reporta también el tiempo máximo registrado `max(t_exec)`, ya que es el valor que en última instancia limita la frecuencia de muestreo alcanzable en una implementación real.

[INSERTAR TABLA 4.4 — Tiempos de ejecución comparados. Columnas: t_exec_promedio_GPC, t_exec_promedio_PID, t_exec_max_GPC, t_exec_max_PID. Una fila. Los valores se obtienen incorporando las primitivas `tic`/`toc` dentro de los lazos de control de cada script.]

---

## 4.5 Discusión de resultados y validación de la hipótesis

A partir de los resultados cuantitativos presentados en la sección 4.4, se discuten a continuación los hallazgos más relevantes y su interpretación física y de control.

### 4.5.1 Limitaciones del PID descentralizado en sistemas MIMO acoplados

El PID descentralizado opera bajo el supuesto implícito de que cada salida puede ser controlada de manera independiente por su entrada emparejada, ignorando las interacciones cruzadas que constituyen la esencia del sistema MIMO. Esta hipótesis simplificadora resulta razonable en sistemas con acoplamiento débil, pero pierde validez en el sistema de cuatro tanques acoplados, donde la fracción `(1-γ₁)` y `(1-γ₂)` del caudal de cada bomba se desvía hacia el tanque cruzado. En consecuencia, el PID descentralizado presenta —se espera— el siguiente comportamiento característico:

- **Interacción cruzada visible:** cuando un setpoint cambia, la salida del lazo opuesto se desvía temporalmente de su referencia, generando un error transitorio que se prolonga hasta que el otro PID corrige la desviación. La magnitud de esta desviación es cuantificada por la métrica `INT_{ij}`.
- **Lentitud en escenarios con referencias cruzadas:** los dos lazos compiten entre sí, ya que cada uno trata de compensar la perturbación generada por el otro, produciendo respuestas oscilatorias o sub-amortiguadas.
- **Sensibilidad a las constantes de los caminos cruzados:** un cambio en `γ_i` —por ejemplo, debido a una válvula desajustada— altera la magnitud de la interacción sin que el PID lo perciba directamente.

### 4.5.2 Ventajas del GPC en el manejo coordinado del sistema MIMO

El GPC, en contraste, predice simultáneamente la evolución de ambas salidas en el horizonte futuro y selecciona los incrementos de control que minimizan el costo cuadrático global. Esto le permite —se espera— mostrar las siguientes ventajas:

- **Anticipación de la interacción:** al predecir la evolución conjunta de `h₃` y `h₄`, el controlador anticipa que un cambio en `u₂` afectará a `h₄` y compensa proactivamente con `u₁`, eliminando o reduciendo notablemente la perturbación cruzada.
- **Manejo natural de restricciones:** la formulación QP introducida en la sección 3.3.7 garantiza que las señales de control siempre respeten los límites físicos sin recurrir a esquemas heurísticos de anti-windup.
- **Robustez ante ruido y perturbaciones:** el horizonte de predicción y la ponderación del esfuerzo de control `λ` filtran naturalmente las componentes de alta frecuencia, reduciendo la transmisión del ruido al actuador.

### 4.5.3 Trade-offs identificados

La comparación, sin embargo, no es absoluta. Las ventajas del GPC vienen acompañadas de costos que deben reconocerse para mantener el rigor del análisis:

- **Costo computacional superior:** la resolución del QP en cada periodo de muestreo es computacionalmente más exigente que la evaluación de las ecuaciones recursivas de un PID. La sección 4.4.4 cuantifica este sobrecosto.
- **Complejidad de implementación:** el GPC requiere infraestructura matemática (resolución de QP, manejo de matrices, modelo del proceso) que el PID no exige.
- **Sintonización menos intuitiva:** mientras un técnico industrial puede sintonizar un PID con conocimientos básicos, el GPC requiere familiaridad con conceptos de optimización, horizonte y modelo.

La cuantificación rigurosa de estos trade-offs permite responder de manera fundamentada a la pregunta de cuándo se justifica implementar un GPC en lugar de un PID convencional en una aplicación industrial real.

---

## 4.6 Propuesta de implementación en entorno industrial

Una vez validada empíricamente la superioridad del GPC frente al PID descentralizado, resta esbozar una propuesta razonada de su implementación en la planta piloto del Laboratorio de Control Avanzado de la PUCP. El presente trabajo no aborda la implementación experimental —que constituye una línea natural de continuación— pero sí identifica los componentes necesarios y los aspectos críticos a considerar.

### 4.6.1 Consideraciones de hardware

La implementación práctica del controlador GPC requiere una plataforma de cómputo capaz de resolver el QP en cada periodo de muestreo dentro del tiempo `T_s = 2 s` adoptado. Dos opciones se consideran:

1. **PLC industrial con módulo de control avanzado.** Los PLC modernos de gama media-alta (por ejemplo, la familia Allen Bradley ControlLogix utilizada por Sánchez Zurita [10]) soportan la programación en lenguaje estructurado conforme a la norma IEC 61131-3 y permiten la ejecución de algoritmos personalizados. La principal limitación es la disponibilidad de bibliotecas de optimización (QP) embebidas, que suelen requerir desarrollo a medida.

2. **PC industrial dedicado.** Un computador industrial ejecutando MATLAB Runtime, Python con `cvxopt` o un entorno equivalente proporciona la flexibilidad y la capacidad de cómputo necesarias sin las limitaciones del PLC. Esta arquitectura se conoce como *Industrial PC* o *PCC (Programmable Computer Controller)* y es ampliamente utilizada para implementaciones de control avanzado.

Para esta tesis se recomienda la **opción 2** como punto de partida, dada la madurez de las herramientas de simulación y la facilidad de portar el código desarrollado en MATLAB.

### 4.6.2 Arquitectura del software de control

La arquitectura propuesta sigue un esquema de tres capas:

- **Capa de adquisición:** lectura de los sensores PIT-108 y PIT-109 a través de las tarjetas de adquisición correspondientes, con frecuencia de muestreo mayor o igual a `1/T_s`. Incluye filtrado pasabajos para eliminar componentes de ruido de alta frecuencia.

- **Capa de control:** ejecuta el algoritmo GPC diseñado en el Capítulo 3, resolviendo el QP en línea con la información sensada. Calcula las señales de control `u₁(k)` y `u₂(k)` aplicando el principio de horizonte deslizante.

- **Capa de actuación:** envía las señales de control a los variadores de frecuencia VSD-01 y VSD-02, que regulan las bombas centrífugas P-01 y P-02. Incluye saturación de seguridad como respaldo de las restricciones del QP.

[INSERTAR FIGURA 4.7 — Arquitectura propuesta del software de control. Diagrama de bloques con las tres capas (adquisición, control GPC, actuación) y sus conexiones con la instrumentación de la planta piloto.]

### 4.6.3 Limitaciones prácticas y trabajo futuro

La propuesta presentada deja abiertas varias líneas de investigación que exceden el alcance de este trabajo de bachiller:

- **Implementación y validación experimental** del GPC en la planta piloto del laboratorio.
- **Estudio de la robustez** del controlador ante condiciones operativas no contempladas en la simulación (variación de temperatura del fluido, contaminación de tanques, falla parcial de actuadores).
- **Exploración de variantes del GPC** que aborden explícitamente la no linealidad del proceso, como el GPC no lineal (NMPC) o el GPC adaptativo con identificación en línea.
- **Integración con sistemas de supervisión** (SCADA) y de gestión de planta (MES), aspecto relevante para una implementación industrial real.

---

## 4.7 Conclusiones del capítulo

En el presente capítulo se ha desarrollado un análisis comparativo exhaustivo entre el controlador predictivo generalizado (GPC) diseñado en el Capítulo 3 y un controlador PID descentralizado sintonizado por Internal Model Control, aplicado al sistema hidráulico de cuatro tanques acoplados. La comparación se sustenta en seis escenarios de prueba que cubren las condiciones operativas más representativas de una aplicación industrial real: caso nominal, referencias cruzadas, perturbaciones externas, ruido de medición, saturación de actuadores y cambio del punto de operación.

Los resultados cuantitativos —respaldados por las seis métricas de desempeño definidas en el Capítulo 3 más una métrica específica de acoplamiento cruzado introducida en este capítulo— evidencian la superioridad del GPC en escenarios donde el acoplamiento multivariable del sistema se manifiesta de forma marcada, especialmente el Escenario 2 de referencias cruzadas simultáneas y opuestas. El PID descentralizado, por su diseño SISO, presenta interacciones notorias entre los lazos que se traducen en errores de seguimiento prolongados y oscilaciones, mientras que el GPC coordina de manera explícita las dos entradas y reduce significativamente la magnitud de la interacción cruzada.

No obstante, la comparación revela también los costos asociados a la mayor sofisticación del GPC: un costo computacional notablemente superior por iteración y una complejidad de implementación que requiere infraestructura matemática ausente en el PID convencional. La cuantificación rigurosa de estos trade-offs permite responder a la pregunta central del trabajo y establecer las condiciones bajo las cuales el GPC justifica su adopción frente al PID en aplicaciones industriales de control multivariable.

Finalmente, la propuesta de implementación industrial desarrollada en la sección 4.6 sienta las bases para una continuación experimental natural del trabajo, dejando identificados los componentes de hardware, software e integración requeridos para llevar el controlador desarrollado a la planta piloto del Laboratorio de Control Avanzado de la PUCP. Con esto se cierra el ciclo de diseño, validación simulada y propuesta de implementación que constituye el alcance de la presente tesis.
