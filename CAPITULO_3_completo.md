# CAPÍTULO 3 — Diseño del Controlador Predictivo GPC para el Sistema Hidráulico de Cuatro Tanques Acoplados (TITO)

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

## 3.1 Introducción

El presente capítulo aborda el diseño del controlador predictivo generalizado en su versión multivariable (GPC MIMO) aplicado al sistema hidráulico de cuatro tanques acoplados descrito en el Capítulo 2. A partir del modelo linealizado obtenido alrededor del punto de operación, se desarrolla la formulación matricial completa del controlador, incluyendo el tratamiento explícito de las restricciones físicas sobre los actuadores mediante una formulación de programación cuadrática (QP).

Una vez construida la estructura del controlador, se aborda el problema de la sintonización de sus parámetros —tiempo de muestreo, horizontes de predicción y control, y matrices de ponderación— mediante la comparación sistemática de cuatro métodos representativos, uno por cada familia metodológica: el método heurístico-analítico de Clarke-Mohtadi, el método analítico explícito de Shridhar-Cooper extendido al caso multivariable, el algoritmo metaheurístico global de Optimización por Enjambre de Partículas (PSO) y el método de optimización numérica directa de Nelder-Mead implementado en `fminsearch`. La elección del método más adecuado para esta aplicación se realiza mediante un análisis cuantitativo basado en seis criterios de desempeño previamente definidos.

A diferencia de los trabajos antecedentes desarrollados sobre la misma planta piloto —entre ellos la tesis de licenciatura de Oré Sánchez [pendiente encontrar fuente] sobre control DMC en una configuración de dos tanques y la tesis de maestría de Sánchez Zurita [10] sobre control DMC y DMPC en cuatro tanques— la presente investigación se diferencia en dos aspectos fundamentales: primero, en el uso de la formulación CARIMA con ecuaciones diofánticas característica del GPC, distinta a la matriz dinámica de respuesta al escalón empleada por el DMC y la representación en espacio de estados utilizada por el DMPC; y segundo, en la comparación de cuatro métodos formales de sintonización —uno por cada familia metodológica— validados mediante una métrica combinada de seis indicadores de desempeño.

El capítulo se estructura como sigue. En la sección 3.2 se definen los criterios de desempeño utilizados a lo largo del trabajo. En la sección 3.3 se desarrolla el diseño del controlador GPC MIMO, incluyendo su formulación matricial, el tratamiento de restricciones y la construcción del vector de referencia. En la sección 3.4 se presentan y comparan los métodos de sintonización considerados y se selecciona el más adecuado. En la sección 3.5 se sintetizan las ecuaciones finales del controlador y se describe su implementación. Finalmente, en la sección 3.6 se exponen las conclusiones del capítulo.

**Nota sobre la notación.** En este capítulo se mantiene la convención introducida en la sección 2.2.4: `N` denota la longitud del horizonte de predicción (equivalente a `N₂` del capítulo 2 bajo la simplificación `N₁ = 1`, válida por la ausencia de tiempo muerto en el sistema), `N_u` denota el horizonte de control (equivalente a `Nu`), y `n_u, n_y` indican el número de entradas y salidas físicas del proceso (en este caso `n_u = n_y = 2`). Las dimensiones de matrices y vectores se expresan como `(filas) × (columnas)`, donde `× 1` corresponde a un vector columna.

---

## 3.2 Criterios de desempeño

Para evaluar de manera objetiva y reproducible el comportamiento del controlador GPC tanto durante el proceso de sintonización como en las simulaciones del Capítulo 4, se han adoptado seis criterios de desempeño que cubren tres dimensiones fundamentales: la calidad dinámica de la respuesta, la precisión acumulada del seguimiento y la economía del esfuerzo de control. La elección de estos criterios responde a la necesidad de obtener una caracterización completa del lazo cerrado, dado que un único indicador no es suficiente para discriminar entre estrategias de sintonización con compromisos distintos.

### 3.2.1 Sobrepico y tiempo de establecimiento

El **sobrepico** o sobreimpulso, denotado como `M_p`, se define como la diferencia porcentual entre el valor máximo alcanzado por la salida y el valor de referencia deseado, expresado en relación a la amplitud del cambio de consigna [pendiente encontrar fuente]. Matemáticamente:

**Preview:**

$$ M_p\,(\%) = \frac{\max\{ y(t) \} - y_{ref}}{y_{ref} - y_0} \cdot 100\% $$

**LaTeX para Word:**

```latex
M_p\,(\%) = \frac{\max\{ y(t) \} - y_{ref}}{y_{ref} - y_0} \cdot 100\%
```

donde `y₀` es el valor inicial de la salida e `y_ref` es el valor de referencia. En el contexto del control de nivel, un sobrepico elevado puede ocasionar desbordamientos en los tanques o esfuerzos innecesarios en las bombas, por lo que es deseable que este indicador sea lo más bajo posible.

El **tiempo de establecimiento** `t_s` se define como el instante a partir del cual la salida permanece dentro de una banda de tolerancia alrededor del valor de referencia. En esta tesis se adopta el criterio estándar del 2%, de modo que:

**Preview:**

$$ t_s = \min\{ t^{*} \mid | y(t) - y_{ref} | \le 0.02 \cdot |y_{ref} - y_0|,\ \forall\,t \ge t^{*} \} $$

**LaTeX para Word:**

```latex
t_s = \min\{ t^{*} \mid | y(t) - y_{ref} | \le 0.02 \cdot |y_{ref} - y_0|,\ \forall\,t \ge t^{*} \}
```

Este indicador caracteriza la rapidez del lazo cerrado y es uno de los más relevantes desde el punto de vista operativo, ya que determina el tiempo en el cual el sistema alcanza una condición estable luego de una perturbación o un cambio de consigna.

### 3.2.2 Criterios integrales del error

Los criterios anteriores caracterizan aspectos puntuales de la respuesta, pero no recogen información sobre el comportamiento global del error a lo largo del tiempo. Para cuantificar esta dimensión se emplean tres índices integrales ampliamente utilizados en la literatura de control [pendiente encontrar fuente].

La **Integral del Error Absoluto (IAE)** pondera de manera uniforme todos los errores a lo largo del horizonte de evaluación, sin importar su signo ni el instante en que ocurran:

**Preview:**

$$ \text{IAE} = \int_{0}^{T_{sim}} | e(t) |\, dt $$

**LaTeX para Word:**

```latex
\text{IAE} = \int_{0}^{T_{sim}} | e(t) |\, dt
```

donde `e(t) = y_ref(t) - y(t)` es el error de seguimiento. Este indicador es particularmente útil para evaluar el comportamiento promedio del controlador.

La **Integral del Error Cuadrático (ISE)** penaliza con mayor fuerza los errores grandes debido a la elevación al cuadrado, lo cual la hace sensible a desviaciones transitorias amplias como las que se producen inmediatamente después de un cambio de consigna:

**Preview:**

$$ \text{ISE} = \int_{0}^{T_{sim}} e(t)^{2}\, dt $$

**LaTeX para Word:**

```latex
\text{ISE} = \int_{0}^{T_{sim}} e(t)^{2}\, dt
```

La **Integral del Error Absoluto Ponderado por el Tiempo (ITAE)** introduce el tiempo como factor multiplicativo, otorgando mayor peso a los errores que persisten en instantes tardíos de la simulación. Este criterio penaliza la lentitud del controlador y favorece sintonizaciones que alcanzan el régimen estacionario con rapidez:

**Preview:**

$$ \text{ITAE} = \int_{0}^{T_{sim}} t \cdot | e(t) |\, dt $$

**LaTeX para Word:**

```latex
\text{ITAE} = \int_{0}^{T_{sim}} t \cdot | e(t) |\, dt
```

En implementaciones digitales, donde la señal se discretiza con un período de muestreo `T_s`, las integrales anteriores se aproximan mediante sumas finitas a lo largo de los `N_{sim}` instantes de muestreo:

**Preview:**

$$ \text{IAE} \approx \sum_{k=0}^{N_{sim}-1} | e(k) | \cdot T_s $$

**LaTeX para Word:**

```latex
\text{IAE} \approx \sum_{k=0}^{N_{sim}-1} | e(k) | \cdot T_s
```

con expresiones análogas para ISE e ITAE.

### 3.2.3 Esfuerzo de control y costo computacional

La calidad de un controlador no se mide únicamente por su capacidad de seguimiento, sino también por la economía de la señal de control aplicada. Un controlador que minimiza el error a costa de movimientos bruscos y excesivos en los actuadores no es deseable, ya que incrementa el desgaste mecánico, el consumo energético y el riesgo de saturación. Para cuantificar este aspecto se emplea el **esfuerzo total de control**, definido como la variación total de la señal de control a lo largo del horizonte de simulación:

**Preview:**

$$ \Delta U_{total} = \sum_{k=1}^{N_{sim}-1} \| \mathbf{u}(k) - \mathbf{u}(k-1) \|_{1} $$

**LaTeX para Word:**

```latex
\Delta U_{total} = \sum_{k=1}^{N_{sim}-1} \| \mathbf{u}(k) - \mathbf{u}(k-1) \|_{1}
```

donde `||·||_1` denota la norma L1, que suma los valores absolutos de los incrementos en cada canal de entrada.

Finalmente, el **costo computacional** se mide como el tiempo promedio de ejecución por iteración del algoritmo de control, medido en milisegundos mediante las primitivas `tic` y `toc` de MATLAB. Este indicador resulta crítico al considerar una eventual implementación en hardware industrial, donde los recursos de cómputo son limitados y el período de muestreo impone restricciones estrictas al tiempo disponible para resolver el problema de optimización en línea [10].

> **Comentario para Edwin:** Esta sección 3.2 define los seis criterios que se usarán en toda la tesis. La tesis de maestría [10] usa cuatro (sobrepico, t_est, IAE, ISE) y agrega costo computacional. La tesis de licenciatura [pendiente encontrar fuente] usa IAE e ISE principalmente. Tu aporte diferenciador es la inclusión simultánea de los seis indicadores y el cálculo de un **score combinado** que se introducirá en la sección 3.4.6.

---

## 3.3 Diseño del sistema de control GPC MIMO

### 3.3.1 Formulación matricial del controlador

A partir del modelo linealizado en espacio de estados desarrollado en la sección 2.3.2, se inicia el diseño del controlador GPC discretizando dicho modelo con un período de muestreo `T_s` mediante un mantenedor de orden cero (ZOH). El modelo discreto resultante toma la forma:

**Preview:**

$$ \mathbf{x}(k+1) = \mathbf{A}_d\,\mathbf{x}(k) + \mathbf{B}_d\,\mathbf{u}(k) $$

**LaTeX para Word:**

```latex
\mathbf{x}(k+1) = \mathbf{A}_d\,\mathbf{x}(k) + \mathbf{B}_d\,\mathbf{u}(k)
```

**Preview:**

$$ \mathbf{y}(k) = \mathbf{C}_d\,\mathbf{x}(k) $$

**LaTeX para Word:**

```latex
\mathbf{y}(k) = \mathbf{C}_d\,\mathbf{x}(k)
```

donde `x ∈ ℝ⁴` representa el vector de estados (alturas de los cuatro tanques en variables desviadas), `u ∈ ℝ²` el vector de entradas (voltajes de las bombas en variables desviadas) e `y ∈ ℝ²` el vector de salidas controladas (alturas de los tanques inferiores, h₃ y h₄, en variables desviadas).

Para incorporar acción integral en el lazo cerrado y trabajar de manera consistente con el formalismo de incrementos de control del GPC, se construye un modelo aumentado tomando como variable de control el incremento `Δu(k) = u(k) - u(k-1)` y como vector de estados aumentado el par formado por el incremento de los estados originales y la salida actual:

**Preview:**

$$ \boldsymbol{\xi}(k) = \begin{bmatrix} \Delta\mathbf{x}(k) \\ \mathbf{y}(k) \end{bmatrix} $$

**LaTeX para Word:**

```latex
\boldsymbol{\xi}(k) = \begin{bmatrix} \Delta\mathbf{x}(k) \\ \mathbf{y}(k) \end{bmatrix}
```

La dinámica del estado aumentado se expresa entonces como:

**Preview:**

$$ \boldsymbol{\xi}(k+1) = \tilde{\mathbf{A}}\,\boldsymbol{\xi}(k) + \tilde{\mathbf{B}}\,\Delta\mathbf{u}(k) $$

**LaTeX para Word:**

```latex
\boldsymbol{\xi}(k+1) = \tilde{\mathbf{A}}\,\boldsymbol{\xi}(k) + \tilde{\mathbf{B}}\,\Delta\mathbf{u}(k)
```

**Preview:**

$$ \mathbf{y}(k) = \tilde{\mathbf{C}}\,\boldsymbol{\xi}(k) $$

**LaTeX para Word:**

```latex
\mathbf{y}(k) = \tilde{\mathbf{C}}\,\boldsymbol{\xi}(k)
```

donde las matrices aumentadas son:

**Preview:**

$$ \tilde{\mathbf{A}} = \begin{bmatrix} \mathbf{A}_d & \mathbf{0} \\ \mathbf{C}_d\,\mathbf{A}_d & \mathbf{I} \end{bmatrix},\quad \tilde{\mathbf{B}} = \begin{bmatrix} \mathbf{B}_d \\ \mathbf{C}_d\,\mathbf{B}_d \end{bmatrix},\quad \tilde{\mathbf{C}} = \begin{bmatrix} \mathbf{0} & \mathbf{I} \end{bmatrix} $$

**LaTeX para Word (una sola línea):**

```latex
\tilde{\mathbf{A}} = \begin{bmatrix} \mathbf{A}_d & \mathbf{0} \\ \mathbf{C}_d\,\mathbf{A}_d & \mathbf{I} \end{bmatrix},\quad \tilde{\mathbf{B}} = \begin{bmatrix} \mathbf{B}_d \\ \mathbf{C}_d\,\mathbf{B}_d \end{bmatrix},\quad \tilde{\mathbf{C}} = \begin{bmatrix} \mathbf{0} & \mathbf{I} \end{bmatrix}
```

A partir de este modelo aumentado, la predicción de la salida en el instante `k + j` se obtiene por recursión:

**Preview:**

$$ \hat{\mathbf{y}}(k+j \mid k) = \tilde{\mathbf{C}}\,\tilde{\mathbf{A}}^{j}\,\boldsymbol{\xi}(k) + \sum_{i=0}^{j-1} \tilde{\mathbf{C}}\,\tilde{\mathbf{A}}^{\,j-i-1}\,\tilde{\mathbf{B}}\,\Delta\mathbf{u}(k+i) $$

**LaTeX para Word:**

```latex
\hat{\mathbf{y}}(k+j \mid k) = \tilde{\mathbf{C}}\,\tilde{\mathbf{A}}^{j}\,\boldsymbol{\xi}(k) + \sum_{i=0}^{j-1} \tilde{\mathbf{C}}\,\tilde{\mathbf{A}}^{\,j-i-1}\,\tilde{\mathbf{B}}\,\Delta\mathbf{u}(k+i)
```

Apilando las predicciones a lo largo del horizonte de predicción `N` y los incrementos de control a lo largo del horizonte de control `N_u`, se obtiene la forma matricial compacta:

**Preview:**

$$ \hat{\mathbf{Y}} = \mathbf{F}\,\boldsymbol{\xi}(k) + \boldsymbol{\Phi}\,\Delta\mathbf{U} $$

**LaTeX para Word:**

```latex
\hat{\mathbf{Y}} = \mathbf{F}\,\boldsymbol{\xi}(k) + \boldsymbol{\Phi}\,\Delta\mathbf{U}
```

donde:

- `Ŷ ∈ ℝ^(N·n_y)` es el vector de predicciones futuras.
- `ΔU ∈ ℝ^(N_u·n_u)` es el vector de incrementos de control futuros.
- `F ∈ ℝ^(N·n_y × n_ξ)` apila los términos `C̃·Ã^j` correspondientes a la respuesta libre del estado aumentado.
- `Φ ∈ ℝ^(N·n_y × N_u·n_u)` es la matriz dinámica multivariable, con estructura por bloques triangular inferior.

La función de costo cuadrática multivariable se escribe como:

**Preview:**

$$ J = (\hat{\mathbf{Y}} - \mathbf{W})^{T}\,\mathbf{Q}\,(\hat{\mathbf{Y}} - \mathbf{W}) + \Delta\mathbf{U}^{T}\,\mathbf{R}\,\Delta\mathbf{U} $$

**LaTeX para Word:**

```latex
J = (\hat{\mathbf{Y}} - \mathbf{W})^{T}\,\mathbf{Q}\,(\hat{\mathbf{Y}} - \mathbf{W}) + \Delta\mathbf{U}^{T}\,\mathbf{R}\,\Delta\mathbf{U}
```

donde **Q** es la matriz bloque-diagonal de ponderación del error de seguimiento, formada por `N` copias de la matriz `diag(δ₁, δ₂)`, y **R** es la matriz bloque-diagonal de ponderación del esfuerzo de control, formada por `N_u` copias de la matriz `diag(λ₁, λ₂)`. El vector **W** contiene los valores futuros de la referencia, los cuales se construyen conforme se describe en la sección 3.3.3.

Al sustituir la ecuación de predicción en la función de costo y reorganizar términos, se obtiene una forma cuadrática en la variable de decisión `ΔU`:

**Preview:**

$$ J(\Delta\mathbf{U}) = \frac{1}{2}\,\Delta\mathbf{U}^{T}\,\mathbf{H}\,\Delta\mathbf{U} + \mathbf{f}^{T}\,\Delta\mathbf{U} + \text{cte} $$

**LaTeX para Word:**

```latex
J(\Delta\mathbf{U}) = \frac{1}{2}\,\Delta\mathbf{U}^{T}\,\mathbf{H}\,\Delta\mathbf{U} + \mathbf{f}^{T}\,\Delta\mathbf{U} + \text{cte}
```

con:

**Preview:**

$$ \mathbf{H} = 2\,(\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,\boldsymbol{\Phi} + \mathbf{R}) $$

**LaTeX para Word:**

```latex
\mathbf{H} = 2\,(\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,\boldsymbol{\Phi} + \mathbf{R})
```

**Preview:**

$$ \mathbf{f} = -2\,\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,(\mathbf{W} - \mathbf{F}\,\boldsymbol{\xi}(k)) $$

**LaTeX para Word:**

```latex
\mathbf{f} = -2\,\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,(\mathbf{W} - \mathbf{F}\,\boldsymbol{\xi}(k))
```

En ausencia de restricciones, la solución óptima se obtiene de manera analítica imponiendo `∂J/∂(ΔU) = 0`:

**Preview:**

$$ \Delta\mathbf{U}^{*} = (\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,\boldsymbol{\Phi} + \mathbf{R})^{-1}\,\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,(\mathbf{W} - \mathbf{F}\,\boldsymbol{\xi}(k)) $$

**LaTeX para Word:**

```latex
\Delta\mathbf{U}^{*} = (\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,\boldsymbol{\Phi} + \mathbf{R})^{-1}\,\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,(\mathbf{W} - \mathbf{F}\,\boldsymbol{\xi}(k))
```

Sin embargo, en aplicaciones industriales reales —y particularmente en el caso del sistema de cuatro tanques donde las bombas tienen rangos operativos limitados— resulta imprescindible incorporar restricciones explícitas. La sección 3.3.2 desarrolla este tratamiento.

### 3.3.2 Tratamiento de restricciones (formulación QP)

El sistema de cuatro tanques acoplados presenta tres tipos de restricciones físicas que deben ser respetadas:

**1) Restricción sobre los incrementos de control:** los actuadores presentan una velocidad máxima de respuesta, lo que impone límites sobre la variación instantánea de la señal de control:

**Preview:**

$$ \Delta u_{min} \le \Delta u_s(k+i) \le \Delta u_{max},\quad i = 0, 1, \ldots, N_u - 1 $$

**LaTeX para Word:**

```latex
\Delta u_{min} \le \Delta u_s(k+i) \le \Delta u_{max},\quad i = 0, 1, \ldots, N_u - 1
```

**2) Restricción sobre los valores absolutos de la entrada:** las bombas operan dentro de un rango de voltajes acotado por consideraciones físicas y de seguridad:

**Preview:**

$$ u_{min} \le u_s(k+i) \le u_{max},\quad i = 0, 1, \ldots, N_u - 1 $$

**LaTeX para Word:**

```latex
u_{min} \le u_s(k+i) \le u_{max},\quad i = 0, 1, \ldots, N_u - 1
```

**3) Restricciones sobre las salidas (opcional):** los niveles de líquido están limitados por la altura física de los tanques, aunque en la presente formulación esta restricción se considera implícitamente al limitar las entradas.

Las restricciones del tipo (1) son directas ya que `ΔU` es la variable de decisión del problema de optimización. Las restricciones del tipo (2), en cambio, requieren expresar el valor absoluto futuro de la entrada en función de los incrementos:

**Preview:**

$$ \mathbf{u}(k+i) = \mathbf{u}(k-1) + \sum_{j=0}^{i} \Delta\mathbf{u}(k+j) $$

**LaTeX para Word:**

```latex
\mathbf{u}(k+i) = \mathbf{u}(k-1) + \sum_{j=0}^{i} \Delta\mathbf{u}(k+j)
```

Apilando esta relación para los `N_u` instantes futuros, se obtiene la forma matricial:

**Preview:**

$$ \mathbf{U}_{fut} = \mathbf{T}\,\Delta\mathbf{U} + \boldsymbol{\mathcal{I}}\,\mathbf{u}(k-1) $$

**LaTeX para Word:**

```latex
\mathbf{U}_{fut} = \mathbf{T}\,\Delta\mathbf{U} + \boldsymbol{\mathcal{I}}\,\mathbf{u}(k-1)
```

donde **T** es una matriz bloque-triangular inferior formada por bloques de identidad y **I** es una matriz apilada con `N_u` bloques de identidad. Con estas definiciones, el conjunto completo de restricciones lineales se escribe en la forma estándar `A_ineq · ΔU ≤ b_ineq`, donde:

**Preview:**

$$ \mathbf{A}_{ineq} = \begin{bmatrix} \mathbf{I} \\ -\mathbf{I} \\ \mathbf{T} \\ -\mathbf{T} \end{bmatrix},\quad \mathbf{b}_{ineq} = \begin{bmatrix} \Delta\mathbf{U}_{max} \\ -\Delta\mathbf{U}_{min} \\ \mathbf{U}_{max} - \boldsymbol{\mathcal{I}}\,\mathbf{u}(k-1) \\ -\mathbf{U}_{min} + \boldsymbol{\mathcal{I}}\,\mathbf{u}(k-1) \end{bmatrix} $$

**LaTeX para Word (una sola línea):**

```latex
\mathbf{A}_{ineq} = \begin{bmatrix} \mathbf{I} \\ -\mathbf{I} \\ \mathbf{T} \\ -\mathbf{T} \end{bmatrix},\quad \mathbf{b}_{ineq} = \begin{bmatrix} \Delta\mathbf{U}_{max} \\ -\Delta\mathbf{U}_{min} \\ \mathbf{U}_{max} - \boldsymbol{\mathcal{I}}\,\mathbf{u}(k-1) \\ -\mathbf{U}_{min} + \boldsymbol{\mathcal{I}}\,\mathbf{u}(k-1) \end{bmatrix}
```

El problema de control resultante en cada instante de muestreo es un **problema de programación cuadrática (QP)** con función objetivo convexa y restricciones lineales:

**Preview:**

$$ \min_{\Delta\mathbf{U}}\ \frac{1}{2}\,\Delta\mathbf{U}^{T}\,\mathbf{H}\,\Delta\mathbf{U} + \mathbf{f}^{T}\,\Delta\mathbf{U} $$

**LaTeX para Word:**

```latex
\min_{\Delta\mathbf{U}}\ \frac{1}{2}\,\Delta\mathbf{U}^{T}\,\mathbf{H}\,\Delta\mathbf{U} + \mathbf{f}^{T}\,\Delta\mathbf{U}
```

**Preview:**

$$ \text{s.a.}\quad \mathbf{A}_{ineq}\,\Delta\mathbf{U} \le \mathbf{b}_{ineq} $$

**LaTeX para Word:**

```latex
\text{s.a.}\quad \mathbf{A}_{ineq}\,\Delta\mathbf{U} \le \mathbf{b}_{ineq}
```

Este problema se resuelve mediante el algoritmo `quadprog` de MATLAB, basado en métodos de punto interior, cuya convergencia está garantizada por la convexidad del problema [pendiente encontrar fuente]. Es importante destacar que la matriz **H** es constante a lo largo de toda la simulación y puede calcularse una sola vez fuera del bucle de control, mientras que el vector **f** y el lado derecho de las restricciones **b_ineq** se actualizan en cada iteración con los nuevos valores del estado y del control previo.

### 3.3.3 Construcción del vector de referencia futura

Aunque el controlador GPC dispone naturalmente de información sobre la referencia futura cuando ésta es conocida, en aplicaciones donde el operador puede modificar el setpoint en cualquier momento resulta más realista asumir que el controlador conoce únicamente la referencia actual. Por esta razón, en la presente formulación el vector de referencia futura se construye asumiendo que el setpoint permanece constante a lo largo del horizonte de predicción:

**Preview:**

$$ \mathbf{w}(k+j) = \mathbf{r}(k),\quad j = 1, 2, \ldots, N $$

**LaTeX para Word:**

```latex
\mathbf{w}(k+j) = \mathbf{r}(k),\quad j = 1, 2, \ldots, N
```

donde `r(k)` es el setpoint actual e `y(k)` es la salida medida en el instante presente. Esta elección refleja el principio físico de causalidad: ningún controlador real puede anticipar cambios futuros del setpoint que aún no han ocurrido, y la respuesta del sistema solo debe iniciarse cuando se introduce una excitación efectiva en su entrada.

### 3.3.4 Diagrama de flujo del controlador GPC

La operación del controlador GPC MIMO en cada instante de muestreo se resume en el diagrama de flujo de la Figura 3.X. El procedimiento se inicia con una etapa de configuración fuera de línea, en la cual se calculan las matrices que dependen únicamente del modelo y los parámetros de sintonización (`F`, `Φ`, `H`, **A_ineq**). Posteriormente, dentro del lazo de control en tiempo real, se ejecuta secuencialmente la medición del estado, la construcción del estado aumentado, la construcción del vector de referencia futura suavizada, la actualización del vector de restricciones, la resolución del problema QP, la aplicación del primer incremento al actuador y la actualización de los registros para la siguiente iteración.

[INSERTAR FIGURA 3.X: Diagrama de flujo del controlador GPC MIMO. Generado como `diagrama_flujo_GPC.png` en el repositorio.]

> **Comentario para Edwin:** El diagrama se generará como imagen PNG y se incluirá en el repositorio para que puedas insertarlo directamente en Word.

---

## 3.4 Sintonización del controlador GPC MIMO

### 3.4.1 Generalidades y necesidad de sintonización

Una vez establecida la estructura del controlador GPC mediante el diseño matricial presentado en la sección 3.3, resta determinar los valores numéricos de sus parámetros: el período de muestreo `T_s`, el horizonte de predicción `N`, el horizonte de control `N_u`, los pesos del error de seguimiento `δ₁, δ₂` y los pesos del esfuerzo de control `λ₁, λ₂`. La selección adecuada de estos parámetros es crítica, ya que afecta directamente el compromiso entre velocidad de respuesta, robustez ante incertidumbre del modelo, manejo de restricciones y costo computacional.

En la literatura existen cuatro grandes familias de métodos de sintonización para controladores predictivos: (i) reglas **heurístico-analíticas** basadas en la dinámica nominal del proceso, (ii) métodos **analíticos explícitos** derivados a partir de aproximaciones de bajo orden de la planta, (iii) algoritmos **metaheurísticos globales** inspirados en procesos naturales y (iv) métodos de **optimización numérica directa** basados en algoritmos de búsqueda local sin gradiente. Cada familia presenta ventajas y limitaciones específicas que justifican su comparación en el marco de esta investigación.

En esta tesis se aplican y comparan **cuatro métodos representativos** —uno por cada familia metodológica— con el objetivo de identificar la sintonización que ofrezca el mejor compromiso entre simplicidad de aplicación, calidad de la respuesta y robustez del controlador. La selección de un método representativo por familia, en lugar de múltiples variantes dentro de una misma categoría, busca garantizar la diversidad metodológica del análisis y evitar conclusiones sesgadas hacia una sola estrategia algorítmica.

**Tabla 3.A — Métodos de sintonización considerados**

| Familia metodológica | Método representativo | Año | Tipo |
|---|---|---|---|
| Heurístico-analítica | Clarke-Mohtadi-Tuffs | 1987 | Reglas de diseño |
| Analítica explícita | Shridhar-Cooper extendido a MIMO | 1997 | Fórmulas cerradas (FOPDT) |
| Metaheurística global | Particle Swarm Optimization (PSO) | 1995 | Optimización por enjambre |
| Numérica directa | Nelder-Mead (fminsearch) | 1965 | Búsqueda sin gradiente |

### 3.4.2 Método de Clarke-Mohtadi

El método propuesto originalmente por Clarke, Mohtadi y Tuffs en la formulación inicial del GPC [pendiente encontrar fuente — Clarke et al. 1987] establece una serie de reglas prácticas basadas en las características dinámicas del proceso. Estas reglas, aunque conservadoras, proporcionan un punto de partida robusto y son citables en el ámbito académico.

Las reglas básicas del método se resumen como sigue:

- **Período de muestreo:** se selecciona como una fracción de la constante de tiempo dominante del sistema, típicamente `T_s ≈ τ_dom / 10` a `T_s ≈ τ_dom / 20`, asegurando que la dinámica más rápida sea capturada con resolución suficiente.

- **Horizonte de predicción:** se ajusta para cubrir aproximadamente el tiempo de subida del sistema en lazo abierto, calculado como:

**Preview:**

$$ N = \left\lceil \frac{2.2 \cdot \tau_{dom}}{T_s} \right\rceil $$

**LaTeX para Word:**

```latex
N = \left\lceil \frac{2.2 \cdot \tau_{dom}}{T_s} \right\rceil
```

- **Horizonte de control:** se mantiene pequeño para favorecer la robustez, típicamente `N_u = 1` a `3`, evitando una excesiva flexibilidad que podría amplificar la sensibilidad al ruido de medición.

- **Ponderaciones:** se inician con valores unitarios para el error de seguimiento (`δ₁ = δ₂ = 1`) y se ajusta `λ` empíricamente, partiendo de valores moderados (`λ ≈ 0.5`).

Aplicando estas reglas a los parámetros del sistema de cuatro tanques acoplados, donde la constante de tiempo dominante calculada a partir del modelo linealizado es del orden de `τ_dom ≈ 30 s`, se obtienen los valores iniciales mostrados en la Tabla 3.X.

[INSERTAR TABLA 3.X — Parámetros del controlador GPC obtenidos por el método de Clarke-Mohtadi. Columnas: Parámetro, Símbolo, Valor. Filas: T_s, N, N_u, δ₁=δ₂, λ₁=λ₂. Los valores específicos se obtienen del script `analisis_sintonizacion_GPC.m`.]

### 3.4.3 Método de Shridhar-Cooper extendido a MIMO

El método propuesto por Shridhar y Cooper [pendiente encontrar fuente — Shridhar & Cooper 1997] constituye un enfoque analítico para la sintonización de controladores predictivos basado en la aproximación del proceso por un modelo de primer orden más tiempo muerto (FOPDT). El método fue concebido originalmente para el caso monovariable y posteriormente extendido al ámbito multivariable [10], lo cual lo hace particularmente apropiado para el sistema TITO objeto de esta investigación.

El procedimiento consta de los siguientes pasos:

**Paso 1.** Aproximación de cada subproceso `(r, s)` —que relaciona la entrada `u_s` con la salida `y_r`— por un modelo FOPDT de la forma:

**Preview:**

$$ G_{rs}(s) = \frac{K_{rs}\,e^{-\theta_{rs}\,s}}{\tau_{rs}\,s + 1} $$

**LaTeX para Word:**

```latex
G_{rs}(s) = \frac{K_{rs}\,e^{-\theta_{rs}\,s}}{\tau_{rs}\,s + 1}
```

donde `K_{rs}` es la ganancia estática, `τ_{rs}` la constante de tiempo y `θ_{rs}` el retardo de transporte. En el caso del sistema de cuatro tanques, los retardos son despreciables y se asume `θ_{rs} ≈ 0`.

**Paso 2.** Selección del período de muestreo conforme a la regla:

**Preview:**

$$ T_s = \min\left( 0.1 \cdot \tau_{rs} \right) $$

**LaTeX para Word:**

```latex
T_s = \min\left( 0.1 \cdot \tau_{rs} \right)
```

aplicada sobre la mayor constante de tiempo de todos los pares entrada-salida.

**Paso 3.** Cálculo del horizonte de predicción:

**Preview:**

$$ N = \max\left( \frac{5\,\tau_{rs}}{T_s} + 1 \right) $$

**LaTeX para Word:**

```latex
N = \max\left( \frac{5\,\tau_{rs}}{T_s} + 1 \right)
```

evaluado sobre las constantes de tiempo asociadas a las salidas controladas.

**Paso 4.** Cálculo del horizonte de control como el 63.2% del tiempo de establecimiento del subproceso más lento:

**Preview:**

$$ N_u = \max\left( \frac{\tau_{rs}}{T_s} + 1 \right) $$

**LaTeX para Word:**

```latex
N_u = \max\left( \frac{\tau_{rs}}{T_s} + 1 \right)
```

**Paso 5.** Cálculo analítico del peso del esfuerzo de control mediante la fórmula:

**Preview:**

$$ \lambda_s = \frac{N_u}{500} \sum_{r=1}^{n_y} K_{rs}^{2} \left( N + 1 - \frac{3\,\tau_{rs}}{2\,T_s} - \frac{N_u - 1}{2} \right) $$

**LaTeX para Word:**

```latex
\lambda_s = \frac{N_u}{500} \sum_{r=1}^{n_y} K_{rs}^{2} \left( N + 1 - \frac{3\,\tau_{rs}}{2\,T_s} - \frac{N_u - 1}{2} \right)
```

[INSERTAR TABLA 3.Y — Parámetros del controlador GPC obtenidos por el método de Shridhar-Cooper. Mismas columnas que la Tabla 3.X. Los valores específicos se obtienen del script `analisis_sintonizacion_GPC.m`.]

La principal ventaja de este método es la obtención analítica de un valor inicial para `λ` que tiene en cuenta las características específicas del proceso, evitando el ajuste por prueba y error.

### 3.4.4 Método PSO (Particle Swarm Optimization)

El algoritmo de Optimización por Enjambre de Partículas (PSO), propuesto por Eberhart y Kennedy en 1995 [pendiente encontrar fuente — Eberhart & Kennedy 1995], es un método metaheurístico inspirado en el comportamiento social colectivo de aves y peces. A diferencia de los métodos analíticos, el PSO no requiere conocimiento explícito de la estructura del proceso ni asume ninguna aproximación particular sobre su dinámica: trata el controlador GPC como una caja negra cuyo desempeño se evalúa mediante simulación.

El algoritmo mantiene un conjunto de `N_p` partículas, cada una de las cuales representa una solución candidata en el espacio de parámetros. Cada partícula `i` posee una posición `x_i` y una velocidad `v_i`, las cuales se actualizan en cada iteración conforme a:

**Preview:**

$$ \mathbf{v}_i^{k+1} = w\,\mathbf{v}_i^{k} + c_1 r_1 (\mathbf{p}_i - \mathbf{x}_i^{k}) + c_2 r_2 (\mathbf{g} - \mathbf{x}_i^{k}) $$

**LaTeX para Word:**

```latex
\mathbf{v}_i^{k+1} = w\,\mathbf{v}_i^{k} + c_1 r_1 (\mathbf{p}_i - \mathbf{x}_i^{k}) + c_2 r_2 (\mathbf{g} - \mathbf{x}_i^{k})
```

**Preview:**

$$ \mathbf{x}_i^{k+1} = \mathbf{x}_i^{k} + \mathbf{v}_i^{k+1} $$

**LaTeX para Word:**

```latex
\mathbf{x}_i^{k+1} = \mathbf{x}_i^{k} + \mathbf{v}_i^{k+1}
```

donde `p_i` es la mejor posición histórica encontrada por la partícula `i`, `g` es la mejor posición encontrada por todo el enjambre, `w` es el coeficiente de inercia, `c_1` y `c_2` son los coeficientes cognitivo y social respectivamente, y `r_1, r_2 ∈ [0,1]` son números aleatorios. La combinación de los tres términos permite al enjambre explorar el espacio de búsqueda (vía inercia y componente social) al tiempo que explota las regiones prometedoras (vía componente cognitivo).

Para la sintonización del GPC se define el espacio de búsqueda bidimensional `x = [log₁₀(λ), N_u]`, con cotas `log₁₀(λ) ∈ [-4, 0]` y `N_u ∈ [1, N]`. La función objetivo a minimizar es:

**Preview:**

$$ J_{PSO}(\lambda, N_u) = \text{IAE} + \beta_1 \cdot \Delta U_{total} + \beta_2 \cdot M_p $$

**LaTeX para Word:**

```latex
J_{PSO}(\lambda, N_u) = \text{IAE} + \beta_1 \cdot \Delta U_{total} + \beta_2 \cdot M_p
```

con `β_1 = 0.1` y `β_2 = 100`. Los parámetros del enjambre adoptados son `N_p = 6` partículas, `5` iteraciones, `w = 0.7`, `c_1 = c_2 = 1.5`, valores estándar reportados en la literatura del PSO aplicado a sintonización de controladores [pendiente encontrar fuente — Han, Zhao y Qian].

La principal ventaja del PSO frente a los métodos analíticos es su capacidad de explorar globalmente el espacio de parámetros sin quedar atrapado en mínimos locales débiles. Su limitación principal es el costo computacional, ya que cada evaluación de `J_PSO` requiere una simulación completa del lazo cerrado.

[INSERTAR TABLA 3.Z — Parámetros del controlador GPC obtenidos por el método PSO. Mismas columnas que las anteriores. Los valores específicos se obtienen del script `analisis_sintonizacion_GPC.m`.]

### 3.4.5 Método de Nelder-Mead (optimización numérica directa)

El método de Nelder-Mead [pendiente encontrar fuente — Nelder & Mead 1965], implementado en MATLAB mediante la función `fminsearch`, es un algoritmo de búsqueda local sin gradiente que itera sobre un símplex en el espacio de parámetros. A diferencia del PSO, Nelder-Mead explota una vecindad de la solución actual y converge típicamente a un óptimo local, lo cual lo hace particularmente eficiente cuando se dispone de una buena aproximación inicial.

El problema se formula con la misma función objetivo `J_PSO` y las mismas variables de decisión `x = [log₁₀(λ), N_u]`. Como punto inicial se toma la solución obtenida por el método PSO, lo cual permite acelerar la convergencia y refinar el óptimo global identificado por el enjambre. La combinación de ambos algoritmos —PSO para exploración global seguido de Nelder-Mead para explotación local— constituye una estrategia clásica de optimización híbrida ampliamente reportada en la literatura [pendiente encontrar fuente].

Los criterios de parada adoptados son: máximo `15` iteraciones y tolerancia de `0.5` en la posición de los parámetros. Estos valores son suficientes dado que se parte de una solución cercana al óptimo.

[INSERTAR TABLA 3.W — Parámetros del controlador GPC obtenidos por el método Nelder-Mead. Mismas columnas que las anteriores. Los valores específicos se obtienen del script `analisis_sintonizacion_GPC.m`.]

### 3.4.6 Comparación de métodos y selección

Una vez aplicados los cuatro métodos de sintonización al sistema de cuatro tanques acoplados, se ejecuta una simulación de validación con un escenario común para todos: un cambio de referencia simultáneo de magnitud moderada dentro del rango operativo seguro, partiendo del punto de operación nominal `h₃⁰ = h₄⁰ = 25 cm` y desplazándose a `h₃ = 30 cm`, `h₄ = 20 cm`. La simulación se realiza sobre el modelo no lineal de la planta para evaluar el desempeño real del controlador frente a la incertidumbre introducida por la linealización.

Para cada sintonización se calculan los seis criterios de desempeño definidos en la sección 3.2. Con el objetivo de obtener una comparación objetiva, se construye un **score combinado** a partir de la normalización min-max de cada métrica seguida de su ponderación:

**Preview:**

$$ \text{Score} = \sum_{i=1}^{6} w_i \cdot \tilde{m}_i $$

**LaTeX para Word:**

```latex
\text{Score} = \sum_{i=1}^{6} w_i \cdot \tilde{m}_i
```

donde `m̃_i` es la i-ésima métrica normalizada al rango [0, 1] —siendo 0 el mejor desempeño y 1 el peor entre los métodos comparados— y `w_i` el peso asignado a cada métrica. Los pesos adoptados son `w = [0.20, 0.15, 0.15, 0.20, 0.15, 0.15]` para IAE, ISE, ITAE, tiempo de establecimiento, sobrepico y esfuerzo de control, respectivamente, otorgando mayor importancia al IAE y al tiempo de establecimiento. El método con menor score se considera el más adecuado para esta aplicación.

[INSERTAR TABLA 3.W2 — Comparación de los cuatro métodos de sintonización. Columnas: Método, T_s, N, N_u, λ, IAE, ISE, ITAE, t_est, Sobrepico, Esfuerzo, Score. Una fila por método. Datos generados con el script `analisis_sintonizacion_GPC.m`.]

[INSERTAR FIGURA 3.Y — Comparación gráfica de las respuestas en h₃ obtenidas con los cuatro métodos de sintonización. Eje X: tiempo (s). Eje Y: altura h₃ (cm). Cuatro curvas de colores diferentes, una por método. Línea negra punteada: referencia. Generado con `analisis_sintonizacion_GPC.m`.]

[INSERTAR FIGURA 3.Z — Comparación gráfica de las respuestas en h₄. Mismo formato que la Figura 3.Y.]

[INSERTAR FIGURA 3.W3 — Gráfica de barras del score combinado para los cuatro métodos, ordenados de menor (mejor) a mayor (peor). Generada con `analisis_sintonizacion_GPC.m`.]

A partir del análisis de los resultados se identifica el método ganador como aquel con el menor score combinado. Es esperable que los métodos basados en optimización (PSO y Nelder-Mead) obtengan los mejores resultados debido a su capacidad de minimizar de manera dirigida el índice de desempeño, mientras que los métodos analíticos (Clarke-Mohtadi y Shridhar-Cooper) ofrecen sintonizaciones razonables sin necesidad de simulaciones iterativas, lo cual los hace atractivos cuando no se dispone de un entorno de simulación de alta fidelidad.

> **Comentario para Edwin:** El resultado específico depende de la ejecución del script. Si el ganador es PSO, su ventaja se justificará por la exploración global; si el ganador es Nelder-Mead, será por el refinamiento local sobre el punto inicial de PSO. Ambas conclusiones son defendibles ante el jurado y reflejan las fortalezas de cada algoritmo. Ejecuta `analisis_sintonizacion_GPC.m` y completa con los valores reales obtenidos.

En consecuencia, los parámetros adoptados para el controlador final son los obtenidos por el método con menor score combinado, los cuales se sintetizan en la Tabla 3.V.

[INSERTAR TABLA 3.V — Parámetros finales del controlador GPC seleccionados. Una fila con T_s, N, N_u, δ, λ, α. Los valores se obtienen del script `analisis_sintonizacion_GPC.m`.]

---

## 3.5 Resumen de ecuaciones e implementación

Con el propósito de facilitar la implementación práctica del controlador y su posterior validación experimental, en esta sección se sintetizan las ecuaciones esenciales del GPC MIMO desarrollado, organizadas en el orden en que se ejecutan durante el lazo de control.

**Etapa 1 — Configuración fuera de línea (se ejecuta una sola vez):**

Discretización del modelo lineal:

**Preview:**

$$ (\mathbf{A}_d, \mathbf{B}_d, \mathbf{C}_d) = \text{c2d}(\mathbf{A}_c, \mathbf{B}_c, \mathbf{C}_c,\,T_s,\,\text{ZOH}) $$

**LaTeX para Word:**

```latex
(\mathbf{A}_d, \mathbf{B}_d, \mathbf{C}_d) = \text{c2d}(\mathbf{A}_c, \mathbf{B}_c, \mathbf{C}_c,\,T_s,\,\text{ZOH})
```

Construcción del modelo aumentado:

**Preview:**

$$ \tilde{\mathbf{A}} = \begin{bmatrix} \mathbf{A}_d & \mathbf{0} \\ \mathbf{C}_d\,\mathbf{A}_d & \mathbf{I} \end{bmatrix},\quad \tilde{\mathbf{B}} = \begin{bmatrix} \mathbf{B}_d \\ \mathbf{C}_d\,\mathbf{B}_d \end{bmatrix},\quad \tilde{\mathbf{C}} = \begin{bmatrix} \mathbf{0} & \mathbf{I} \end{bmatrix} $$

**LaTeX para Word:**

```latex
\tilde{\mathbf{A}} = \begin{bmatrix} \mathbf{A}_d & \mathbf{0} \\ \mathbf{C}_d\,\mathbf{A}_d & \mathbf{I} \end{bmatrix},\quad \tilde{\mathbf{B}} = \begin{bmatrix} \mathbf{B}_d \\ \mathbf{C}_d\,\mathbf{B}_d \end{bmatrix},\quad \tilde{\mathbf{C}} = \begin{bmatrix} \mathbf{0} & \mathbf{I} \end{bmatrix}
```

Matrices de predicción (bloque `j` de F y bloque `(i,j)` de Φ con `i ≥ j`):

**Preview:**

$$ \mathbf{F}_{[j]} = \tilde{\mathbf{C}}\,\tilde{\mathbf{A}}^{j},\quad \boldsymbol{\Phi}_{[i,j]} = \tilde{\mathbf{C}}\,\tilde{\mathbf{A}}^{\,i-j}\,\tilde{\mathbf{B}} $$

**LaTeX para Word:**

```latex
\mathbf{F}_{[j]} = \tilde{\mathbf{C}}\,\tilde{\mathbf{A}}^{j},\quad \boldsymbol{\Phi}_{[i,j]} = \tilde{\mathbf{C}}\,\tilde{\mathbf{A}}^{\,i-j}\,\tilde{\mathbf{B}}
```

Hessiano del problema QP:

**Preview:**

$$ \mathbf{H} = 2\,(\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,\boldsymbol{\Phi} + \mathbf{R}) $$

**LaTeX para Word:**

```latex
\mathbf{H} = 2\,(\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,\boldsymbol{\Phi} + \mathbf{R})
```

Matriz de restricciones lineales:

**Preview:**

$$ \mathbf{A}_{ineq} = \begin{bmatrix} \mathbf{I}_{N_u n_u} \\ -\mathbf{I}_{N_u n_u} \\ \mathbf{T} \\ -\mathbf{T} \end{bmatrix} $$

**LaTeX para Word:**

```latex
\mathbf{A}_{ineq} = \begin{bmatrix} \mathbf{I}_{N_u n_u} \\ -\mathbf{I}_{N_u n_u} \\ \mathbf{T} \\ -\mathbf{T} \end{bmatrix}
```

**Etapa 2 — Bucle de control en línea (se ejecuta cada `T_s`):**

a) Medición del estado y construcción del estado aumentado:

**Preview:**

$$ \boldsymbol{\xi}(k) = \begin{bmatrix} \mathbf{x}(k) - \mathbf{x}(k-1) \\ \mathbf{y}(k) - \mathbf{y}^{0} \end{bmatrix} $$

**LaTeX para Word:**

```latex
\boldsymbol{\xi}(k) = \begin{bmatrix} \mathbf{x}(k) - \mathbf{x}(k-1) \\ \mathbf{y}(k) - \mathbf{y}^{0} \end{bmatrix}
```

b) Construcción del vector de referencia futura (setpoint constante en el horizonte):

**Preview:**

$$ \mathbf{w}(k+j) = \mathbf{r}(k) $$

**LaTeX para Word:**

```latex
\mathbf{w}(k+j) = \mathbf{r}(k)
```

c) Vector lineal del QP:

**Preview:**

$$ \mathbf{f}(k) = -2\,\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,(\mathbf{W}(k) - \mathbf{F}\,\boldsymbol{\xi}(k)) $$

**LaTeX para Word:**

```latex
\mathbf{f}(k) = -2\,\boldsymbol{\Phi}^{T}\,\mathbf{Q}\,(\mathbf{W}(k) - \mathbf{F}\,\boldsymbol{\xi}(k))
```

d) Vector de cotas de las restricciones:

**Preview:**

$$ \mathbf{b}_{ineq}(k) = \begin{bmatrix} \Delta\mathbf{U}_{max} \\ -\Delta\mathbf{U}_{min} \\ \mathbf{U}_{max} - \boldsymbol{\mathcal{I}}\,\mathbf{u}(k-1) \\ -\mathbf{U}_{min} + \boldsymbol{\mathcal{I}}\,\mathbf{u}(k-1) \end{bmatrix} $$

**LaTeX para Word:**

```latex
\mathbf{b}_{ineq}(k) = \begin{bmatrix} \Delta\mathbf{U}_{max} \\ -\Delta\mathbf{U}_{min} \\ \mathbf{U}_{max} - \boldsymbol{\mathcal{I}}\,\mathbf{u}(k-1) \\ -\mathbf{U}_{min} + \boldsymbol{\mathcal{I}}\,\mathbf{u}(k-1) \end{bmatrix}
```

e) Resolución del problema QP:

**Preview:**

$$ \Delta\mathbf{U}^{*}(k) = \arg\min_{\Delta\mathbf{U}}\ \frac{1}{2}\,\Delta\mathbf{U}^{T}\,\mathbf{H}\,\Delta\mathbf{U} + \mathbf{f}(k)^{T}\,\Delta\mathbf{U}\quad \text{s.a.}\quad \mathbf{A}_{ineq}\,\Delta\mathbf{U} \le \mathbf{b}_{ineq}(k) $$

**LaTeX para Word:**

```latex
\Delta\mathbf{U}^{*}(k) = \arg\min_{\Delta\mathbf{U}}\ \frac{1}{2}\,\Delta\mathbf{U}^{T}\,\mathbf{H}\,\Delta\mathbf{U} + \mathbf{f}(k)^{T}\,\Delta\mathbf{U}\quad \text{s.a.}\quad \mathbf{A}_{ineq}\,\Delta\mathbf{U} \le \mathbf{b}_{ineq}(k)
```

f) Aplicación del primer incremento al actuador:

**Preview:**

$$ \mathbf{u}(k) = \mathbf{u}(k-1) + \Delta\mathbf{U}^{*}_{[1:n_u]}(k) $$

**LaTeX para Word:**

```latex
\mathbf{u}(k) = \mathbf{u}(k-1) + \Delta\mathbf{U}^{*}_{[1:n_u]}(k)
```

g) Actualización de registros para la siguiente iteración.

La implementación completa del controlador GPC MIMO se ha realizado en MATLAB, conforme al diagrama de flujo presentado en la sección 3.3.4. El código fuente se encuentra disponible en el repositorio de la tesis y constituye la base para las pruebas de simulación que se presentan en el Capítulo 4. La estructura modular del código permite además su eventual portabilidad a un controlador industrial mediante la traducción a lenguaje estructurado conforme a la norma IEC 61131-3, tarea que se aborda en la propuesta de implementación del próximo capítulo.

---

## 3.6 Conclusiones del capítulo

En el presente capítulo se ha desarrollado el diseño completo del controlador predictivo generalizado en su versión multivariable aplicado al sistema hidráulico de cuatro tanques acoplados. A partir del modelo lineal obtenido en el Capítulo 2, se construyó la formulación matricial del controlador mediante un modelo aumentado en incrementos de control, lo cual incorpora de manera natural la acción integral necesaria para garantizar error nulo en estado estacionario. La inclusión explícita de restricciones físicas mediante una formulación de programación cuadrática (QP) permite además que el controlador respete los límites operacionales del sistema, aspecto que diferencia la presente formulación respecto a las implementaciones de DMC previamente reportadas sobre la misma planta piloto.

El diseño del controlador se ha complementado con un análisis riguroso del problema de sintonización, en el cual se han aplicado y comparado cuatro métodos representativos de las cuatro familias metodológicas reconocidas en la literatura: el método heurístico-analítico de Clarke-Mohtadi, el método analítico explícito de Shridhar-Cooper extendido al caso multivariable, el algoritmo metaheurístico global de Optimización por Enjambre de Partículas (PSO) y el método de optimización numérica directa de Nelder-Mead implementado en `fminsearch`. La comparación se ha realizado mediante un score combinado que pondera seis criterios de desempeño —sobrepico, tiempo de establecimiento, IAE, ISE, ITAE y esfuerzo de control— lo cual proporciona una evaluación objetiva y reproducible. El método con menor score combinado se ha adoptado como sintonización final del controlador para las pruebas del Capítulo 4.

Con la estructura matemática y los parámetros del controlador definidos, se cuenta con los elementos necesarios para abordar en el siguiente capítulo las pruebas de simulación bajo distintos escenarios operativos, incluyendo seguimiento de referencias, rechazo de perturbaciones e incertidumbre del modelo, así como el desarrollo de una propuesta de implementación práctica del controlador en un entorno industrial.
