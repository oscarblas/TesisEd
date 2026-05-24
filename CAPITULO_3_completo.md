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

El presente capítulo aborda el diseño del controlador predictivo generalizado en su versión multivariable (GPC MIMO) aplicado al sistema hidráulico de cuatro tanques acoplados descrito en el Capítulo 2. Tomando como base la formulación CARIMA y las ecuaciones diofánticas presentadas en la sección 2.2, se obtiene la matriz dinámica del sistema a partir de la matriz de funciones de transferencia discreta y se construye la ley de control resolviendo, en cada periodo de muestreo, un problema de programación cuadrática (QP) que incorpora las restricciones físicas sobre las bombas.

Una vez establecida la estructura del controlador, se aborda el problema de la sintonización de sus parámetros —tiempo de muestreo, horizontes de predicción y control, y matrices de ponderación— mediante la comparación sistemática de cuatro métodos representativos, uno por cada familia metodológica: el método heurístico-analítico de Clarke-Mohtadi, el método analítico explícito de Shridhar-Cooper extendido al caso multivariable, el algoritmo metaheurístico global de Optimización por Enjambre de Partículas (PSO) y el método de optimización numérica directa de Nelder-Mead implementado en `fminsearch`. La elección del método más adecuado para esta aplicación se realiza mediante un análisis cuantitativo basado en seis criterios de desempeño previamente definidos.

A diferencia de los trabajos antecedentes desarrollados sobre la misma planta piloto —entre ellos la tesis de licenciatura de Oré Sánchez [pendiente encontrar fuente] sobre control DMC en una configuración de dos tanques y la tesis de maestría de Sánchez Zurita [10] sobre control DMC y DMPC en cuatro tanques— la presente investigación se diferencia en dos aspectos fundamentales: primero, en el uso de la formulación CARIMA con ecuaciones diofánticas característica del GPC, distinta a la matriz dinámica de respuesta al escalón sin modelo paramétrico empleada por el DMC y a la representación en espacio de estados utilizada por el DMPC; y segundo, en la comparación de cuatro métodos formales de sintonización —uno por cada familia metodológica— validados mediante una métrica combinada de seis indicadores de desempeño.

El capítulo se estructura como sigue. En la sección 3.2 se definen los criterios de desempeño utilizados a lo largo del trabajo. En la sección 3.3 se desarrolla el diseño del controlador GPC MIMO, incluyendo la obtención de la matriz dinámica, el cálculo de la respuesta libre, la formulación de la ley de control y el tratamiento de restricciones. En la sección 3.4 se presentan y comparan los métodos de sintonización considerados y se selecciona el más adecuado. En la sección 3.5 se sintetizan las ecuaciones finales del controlador y se describe su implementación. Finalmente, en la sección 3.6 se exponen las conclusiones del capítulo.

**Nota sobre la notación.** En este capítulo se mantiene la convención introducida en la sección 2.2.4: `N` denota la longitud del horizonte de predicción (equivalente a `N₂` del capítulo 2 bajo la simplificación `N₁ = 1`, válida por la ausencia de tiempo muerto en el sistema), `N_u` denota el horizonte de control (equivalente a `Nu`), y `n_u, n_y` indican el número de entradas y salidas físicas del proceso (en este caso `n_u = n_y = 2`). Las dimensiones de matrices y vectores se expresan como `(filas) × (columnas)`, donde `× 1` corresponde a un vector columna.

---

## 3.2 Criterios de desempeño

Para evaluar de manera objetiva y reproducible el comportamiento del controlador GPC tanto durante el proceso de sintonización como en las simulaciones del Capítulo 4, se han adoptado seis criterios de desempeño que cubren tres dimensiones fundamentales: la calidad dinámica de la respuesta, la precisión acumulada del seguimiento y el uso moderado de los actuadores. La elección de estos criterios responde a la necesidad de obtener una caracterización completa del lazo cerrado, dado que un único indicador no es suficiente para discriminar entre estrategias de sintonización con compromisos distintos.

### 3.2.1 Sobrepico y tiempo de establecimiento

El **sobrepico** o sobreimpulso, denotado como `M_p`, se define como la diferencia porcentual entre el valor máximo alcanzado por la salida y el valor de referencia deseado, expresado en relación a la amplitud del cambio de consigna [pendiente encontrar fuente]:

**Preview:**

$$ M_p\,(\%) = \frac{\max\{ y(t) \} - y_{ref}}{y_{ref} - y_0} \cdot 100\% $$

**LaTeX para Word:**

```latex
M_p\,(\%) = \frac{\max\{ y(t) \} - y_{ref}}{y_{ref} - y_0} \cdot 100\%
```

donde `y₀` es el valor inicial de la salida e `y_ref` es el valor de referencia. En el contexto del control de nivel, un sobrepico elevado puede ocasionar desbordamientos en los tanques o esfuerzos innecesarios en las bombas, por lo que es deseable que este indicador sea lo más bajo posible.

El **tiempo de establecimiento** `t_s` se define como el instante a partir del cual la salida permanece dentro de una banda de tolerancia alrededor del valor de referencia. En esta tesis se adopta el criterio estándar del 2%:

**Preview:**

$$ t_s = \min\{ t^{*} \mid | y(t) - y_{ref} | \le 0.02 \cdot |y_{ref} - y_0|,\ \forall\,t \ge t^{*} \} $$

**LaTeX para Word:**

```latex
t_s = \min\{ t^{*} \mid | y(t) - y_{ref} | \le 0.02 \cdot |y_{ref} - y_0|,\ \forall\,t \ge t^{*} \}
```

### 3.2.2 Criterios integrales del error

Para cuantificar el comportamiento global del error se emplean tres índices integrales ampliamente utilizados en la literatura de control [pendiente encontrar fuente].

La **Integral del Error Absoluto (IAE)**:

**Preview:**

$$ \text{IAE} = \int_{0}^{T_{sim}} | e(t) |\, dt $$

**LaTeX para Word:**

```latex
\text{IAE} = \int_{0}^{T_{sim}} | e(t) |\, dt
```

donde `e(t) = y_ref(t) - y(t)`.

La **Integral del Error Cuadrático (ISE)**:

**Preview:**

$$ \text{ISE} = \int_{0}^{T_{sim}} e(t)^{2}\, dt $$

**LaTeX para Word:**

```latex
\text{ISE} = \int_{0}^{T_{sim}} e(t)^{2}\, dt
```

La **Integral del Error Absoluto Ponderado por el Tiempo (ITAE)**:

**Preview:**

$$ \text{ITAE} = \int_{0}^{T_{sim}} t \cdot | e(t) |\, dt $$

**LaTeX para Word:**

```latex
\text{ITAE} = \int_{0}^{T_{sim}} t \cdot | e(t) |\, dt
```

En implementaciones digitales, las integrales se aproximan como sumas finitas, por ejemplo para IAE:

**Preview:**

$$ \text{IAE} \approx \sum_{k=0}^{N_{sim}-1} | e(k) | \cdot T_s $$

**LaTeX para Word:**

```latex
\text{IAE} \approx \sum_{k=0}^{N_{sim}-1} | e(k) | \cdot T_s
```

### 3.2.3 Esfuerzo de control y costo computacional

Para cuantificar el uso de los actuadores se emplea el **esfuerzo total de control**, definido como la variación total acumulada de la señal de control:

**Preview:**

$$ \Delta U_{total} = \sum_{k=1}^{N_{sim}-1} \| \mathbf{u}(k) - \mathbf{u}(k-1) \|_{1} $$

**LaTeX para Word:**

```latex
\Delta U_{total} = \sum_{k=1}^{N_{sim}-1} \| \mathbf{u}(k) - \mathbf{u}(k-1) \|_{1}
```

donde `||·||_1` denota la norma L1. El **costo computacional** se mide como el tiempo promedio de ejecución por iteración del algoritmo de control en milisegundos, indicador crítico al considerar una eventual implementación en hardware industrial [10].

---

## 3.3 Diseño del sistema de control GPC MIMO

### 3.3.1 Discretización del modelo y matriz de funciones de transferencia

El controlador GPC opera en tiempo discreto, por lo que el primer paso consiste en discretizar el modelo lineal continuo obtenido en la sección 2.3.2. Aplicando un mantenedor de orden cero (ZOH) con período de muestreo `T_s`, las matrices del modelo en espacio de estados continuo `(A_c, B_c, C_c)` se transforman en su contraparte discreta `(A_d, B_d, C_d)`:

**Preview:**

$$ (\mathbf{A}_d, \mathbf{B}_d, \mathbf{C}_d) = \text{c2d}(\mathbf{A}_c, \mathbf{B}_c, \mathbf{C}_c,\,T_s,\,\text{ZOH}) $$

**LaTeX para Word:**

```latex
(\mathbf{A}_d, \mathbf{B}_d, \mathbf{C}_d) = \text{c2d}(\mathbf{A}_c, \mathbf{B}_c, \mathbf{C}_c,\,T_s,\,\text{ZOH})
```

A partir de este modelo discreto se construye la **matriz de funciones de transferencia** `G(z⁻¹)`, de dimensión `n_y × n_u`, cuyos elementos `G_{ij}(z⁻¹)` relacionan la entrada `j` con la salida `i`:

**Preview:**

$$ \mathbf{G}(z^{-1}) = \begin{bmatrix} G_{11}(z^{-1}) & G_{12}(z^{-1}) \\ G_{21}(z^{-1}) & G_{22}(z^{-1}) \end{bmatrix},\quad G_{ij}(z^{-1}) = \frac{B_{ij}(z^{-1})}{A_{ij}(z^{-1})} $$

**LaTeX para Word:**

```latex
\mathbf{G}(z^{-1}) = \begin{bmatrix} G_{11}(z^{-1}) & G_{12}(z^{-1}) \\ G_{21}(z^{-1}) & G_{22}(z^{-1}) \end{bmatrix},\quad G_{ij}(z^{-1}) = \frac{B_{ij}(z^{-1})}{A_{ij}(z^{-1})}
```

Esta forma polinomial es la que permite identificar directamente los polinomios `A_{ij}(z⁻¹)` y `B_{ij}(z⁻¹)` requeridos por el modelo CARIMA introducido en la sección 2.2.2, los cuales se emplean en los siguientes subapartados para construir la matriz dinámica del controlador.

### 3.3.2 Selección del horizonte del modelo y del tiempo de muestreo

Antes de proceder a la construcción de la matriz dinámica **G** y al cálculo de los coeficientes de respuesta al escalón, resulta imprescindible fijar dos parámetros del modelo del controlador: el **tiempo de muestreo** `T_s` y el **horizonte del modelo** `N`. Estos parámetros, a diferencia de los pesos `λ` y los horizontes `N_u`, **no son objeto del proceso de sintonización** abordado en la sección 3.4: se derivan directamente del análisis de la dinámica de la planta y permanecen fijos durante todo el diseño del controlador. Esta separación es estándar en la literatura del control predictivo basado en modelo y se observa tanto en el método clásico de Shridhar y Cooper [pendiente encontrar fuente — Shridhar & Cooper 1997] como en las implementaciones reportadas para la misma planta piloto [10] [pendiente encontrar fuente — Oré Sánchez].

**Selección del tiempo de muestreo.** El criterio empleado es el propuesto por Shridhar y Cooper, según el cual el tiempo de muestreo debe ser una fracción de la constante de tiempo más rápida de los subprocesos del sistema, garantizando así que la dinámica más veloz quede capturada con resolución suficiente:

**Preview:**

$$ T_s = \min\left( 0.1 \cdot \tau_{ij} \right) $$

**LaTeX para Word:**

```latex
T_s = \min\left( 0.1 \cdot \tau_{ij} \right)
```

donde `τ_{ij}` es la constante de tiempo dominante de cada subproceso `(i, j)` obtenida de la matriz de funciones de transferencia. Para el sistema de cuatro tanques acoplados, las constantes de tiempo `τ_{ij}` calculadas a partir del modelo linealizado se encuentran en el rango de los segundos, lo cual conduce a un valor `T_s = 2 s` adoptado en esta tesis.

**Selección del horizonte del modelo.** El horizonte del modelo `N` define cuántos coeficientes de respuesta al escalón conforman cada bloque de la matriz dinámica **G**. Su valor debe ser lo suficientemente grande para que las respuestas al escalón de todos los subprocesos hayan alcanzado prácticamente su valor asintótico, condición necesaria para que el modelo de predicción no trunque información dinámica relevante. La regla de Shridhar y Cooper establece:

**Preview:**

$$ N = \max\left( \frac{5\,\tau_{ij}}{T_s} + 1 \right) $$

**LaTeX para Word:**

```latex
N = \max\left( \frac{5\,\tau_{ij}}{T_s} + 1 \right)
```

evaluado sobre todas las constantes de tiempo del sistema. Sustituyendo los valores de la planta se obtiene `N = 50`, valor adoptado en esta tesis.

**Tabla 3.1 — Parámetros del modelo del controlador GPC fijados a priori**

| Parámetro | Símbolo | Valor adoptado | Criterio |
|---|---|---|---|
| Tiempo de muestreo | `T_s` | 2 s | `min(0.1 · τ_{ij})` |
| Horizonte del modelo | `N` | 50 | `max(5·τ_{ij}/T_s + 1)` |

Conviene enfatizar que estos valores se mantienen **constantes** durante todo el diseño y la sintonización del controlador: en la sección 3.4 únicamente se ajustan los parámetros propiamente de sintonización, a saber, el horizonte de control `N_u` y los pesos `δ` y `λ`. Con `T_s` y `N` ya definidos, el siguiente subapartado aborda la construcción de la matriz dinámica **G**.

### 3.3.3 Construcción de la matriz dinámica G

De acuerdo con la formulación CARIMA y la aplicación de las ecuaciones diofánticas presentada en la sección 2.2.2, la predicción de las salidas futuras se expresa de forma matricial como:

**Preview:**

$$ \hat{\mathbf{Y}} = \mathbf{G}\,\Delta\mathbf{U} + \mathbf{F} $$

**LaTeX para Word:**

```latex
\hat{\mathbf{Y}} = \mathbf{G}\,\Delta\mathbf{U} + \mathbf{F}
```

donde **G** es la matriz dinámica del proceso y **F** es la respuesta libre del sistema. Los coeficientes que conforman la matriz **G** se obtienen, en el desarrollo diofántico, como los coeficientes del polinomio producto `G_j(z⁻¹) = E_j(z⁻¹)·B(z⁻¹)`. Una propiedad fundamental establecida por la teoría del GPC [pendiente encontrar fuente — Camacho & Bordons] es que **estos coeficientes coinciden con los de la respuesta al escalón del subproceso** correspondiente, lo cual permite calcularlos de manera directa a partir del modelo discreto sin necesidad de resolver explícitamente las recursiones diofánticas en cada iteración.

Para cada par entrada-salida `(i, j)`, se obtiene el vector de coeficientes de respuesta al escalón:

**Preview:**

$$ g_{ij}[k] = \text{respuesta al escalon de } G_{ij}(z^{-1}) \text{ evaluada en } t = k\,T_s,\quad k = 1, 2, \ldots, N $$

**LaTeX para Word:**

```latex
g_{ij}[k] = \text{respuesta al escalon de } G_{ij}(z^{-1}) \text{ evaluada en } t = k\,T_s,\quad k = 1, 2, \ldots, N
```

Con estos coeficientes se construye la **matriz dinámica** del sistema MIMO, organizada en bloques. Adoptando la convención de apilado consistente con [10] —vector de predicciones agrupado por salida y vector de incrementos agrupado por entrada—:

**Preview:**

$$ \hat{\mathbf{Y}} = [\hat{y}_1(k+1),\ldots,\hat{y}_1(k+N),\hat{y}_2(k+1),\ldots,\hat{y}_2(k+N)]^{T} $$

**LaTeX para Word:**

```latex
\hat{\mathbf{Y}} = [\hat{y}_1(k+1),\ldots,\hat{y}_1(k+N),\hat{y}_2(k+1),\ldots,\hat{y}_2(k+N)]^{T}
```

**Preview:**

$$ \Delta\mathbf{U} = [\Delta u_1(k),\ldots,\Delta u_1(k+N_u-1),\Delta u_2(k),\ldots,\Delta u_2(k+N_u-1)]^{T} $$

**LaTeX para Word:**

```latex
\Delta\mathbf{U} = [\Delta u_1(k),\ldots,\Delta u_1(k+N_u-1),\Delta u_2(k),\ldots,\Delta u_2(k+N_u-1)]^{T}
```

la matriz dinámica resulta:

**Preview:**

$$ \mathbf{G} = \begin{bmatrix} \mathbf{G}_{11} & \mathbf{G}_{12} \\ \mathbf{G}_{21} & \mathbf{G}_{22} \end{bmatrix} $$

**LaTeX para Word:**

```latex
\mathbf{G} = \begin{bmatrix} \mathbf{G}_{11} & \mathbf{G}_{12} \\ \mathbf{G}_{21} & \mathbf{G}_{22} \end{bmatrix}
```

donde cada bloque `G_{ij}` es de dimensión `N × N_u` y posee estructura triangular inferior:

**Preview:**

$$ \mathbf{G}_{ij} = \begin{bmatrix} g_{ij}[1] & 0 & 0 & \cdots & 0 \\ g_{ij}[2] & g_{ij}[1] & 0 & \cdots & 0 \\ g_{ij}[3] & g_{ij}[2] & g_{ij}[1] & \cdots & 0 \\ \vdots & \vdots & \vdots & \ddots & \vdots \\ g_{ij}[N] & g_{ij}[N-1] & g_{ij}[N-2] & \cdots & g_{ij}[N-N_u+1] \end{bmatrix} $$

**LaTeX para Word:**

```latex
\mathbf{G}_{ij} = \begin{bmatrix} g_{ij}[1] & 0 & 0 & \cdots & 0 \\ g_{ij}[2] & g_{ij}[1] & 0 & \cdots & 0 \\ g_{ij}[3] & g_{ij}[2] & g_{ij}[1] & \cdots & 0 \\ \vdots & \vdots & \vdots & \ddots & \vdots \\ g_{ij}[N] & g_{ij}[N-1] & g_{ij}[N-2] & \cdots & g_{ij}[N-N_u+1] \end{bmatrix}
```

La triangularidad inferior refleja el principio de causalidad: un incremento aplicado en el instante `k+c` no puede afectar predicciones de instantes anteriores `k+r` con `r < c`.

[INSERTAR TABLA 3.2 — Coeficientes de respuesta al escalón `g_{ij}[k]` calculados para el sistema de cuatro tanques. Columnas: `k`, `g_{11}`, `g_{12}`, `g_{21}`, `g_{22}`. Filas: primeros 10 valores más el asintótico. Datos generados con el script `controlador_GPC.m` —específicamente las celdas `g_step{i,j}`—.]

### 3.3.4 Cálculo de la respuesta libre F

La respuesta libre **F** representa la trayectoria que seguiría la salida del proceso si **no se aplicaran nuevos incrementos de control** durante el horizonte de predicción, es decir, manteniendo `Δu(k+j) = 0` para todo `j ≥ 0`. En el desarrollo diofántico, esta respuesta corresponde al término `F_j(z⁻¹)·y(t)` más la contribución de incrementos pasados, y depende exclusivamente de información disponible al instante actual.

En la presente implementación, **F** se calcula de manera equivalente propagando el modelo discreto en espacio de estados a partir del estado actual con la entrada congelada en su último valor aplicado `u(k-1)`. Esta equivalencia se justifica por el hecho de que tanto el modelo CARIMA polinomial como su contraparte en espacio de estados representan la misma dinámica del proceso, y por tanto la propagación natural del modelo con `Δu = 0` produce exactamente la trayectoria libre [pendiente encontrar fuente — Camacho & Bordons]. La recursión es:

**Preview:**

$$ \mathbf{x}(k+j) = \mathbf{A}_d\,\mathbf{x}(k+j-1) + \mathbf{B}_d\,\mathbf{u}(k-1),\quad j = 1, 2, \ldots, N $$

**LaTeX para Word:**

```latex
\mathbf{x}(k+j) = \mathbf{A}_d\,\mathbf{x}(k+j-1) + \mathbf{B}_d\,\mathbf{u}(k-1),\quad j = 1, 2, \ldots, N
```

**Preview:**

$$ \hat{y}_{free,i}(k+j) = \mathbf{C}_{d,i}\,\mathbf{x}(k+j),\quad i = 1, 2 $$

**LaTeX para Word:**

```latex
\hat{y}_{free,i}(k+j) = \mathbf{C}_{d,i}\,\mathbf{x}(k+j),\quad i = 1, 2
```

donde **C_{d,i}** denota la `i`-ésima fila de la matriz **C_d**. Apilando estas predicciones libres se forma el vector:

**Preview:**

$$ \mathbf{F} = [\hat{y}_{free,1}(k+1),\ldots,\hat{y}_{free,1}(k+N),\hat{y}_{free,2}(k+1),\ldots,\hat{y}_{free,2}(k+N)]^{T} $$

**LaTeX para Word:**

```latex
\mathbf{F} = [\hat{y}_{free,1}(k+1),\ldots,\hat{y}_{free,1}(k+N),\hat{y}_{free,2}(k+1),\ldots,\hat{y}_{free,2}(k+N)]^{T}
```

Es importante destacar que **F** se actualiza en cada periodo de muestreo, incorporando la información más reciente del estado del proceso, lo cual permite al controlador adaptarse de manera continua a perturbaciones y discrepancias entre el modelo nominal y la planta real.

### 3.3.5 Vector de referencia futura

El vector de referencia futura **W** apila los valores deseados de las salidas controladas a lo largo del horizonte de predicción. En la presente formulación se asume que el setpoint `r(k)` permanece constante durante todo el horizonte:

**Preview:**

$$ \mathbf{w}(k+j) = \mathbf{r}(k),\quad j = 1, 2, \ldots, N $$

**LaTeX para Word:**

```latex
\mathbf{w}(k+j) = \mathbf{r}(k),\quad j = 1, 2, \ldots, N
```

Esta elección refleja el principio físico de causalidad: ningún controlador real puede anticipar cambios futuros del setpoint que aún no han ocurrido, y la respuesta del sistema solo debe iniciarse cuando se introduce una excitación efectiva. El vector **W** se construye con la misma convención de apilado de **Ŷ**:

**Preview:**

$$ \mathbf{W} = [r_1(k),\ldots,r_1(k),r_2(k),\ldots,r_2(k)]^{T} $$

**LaTeX para Word:**

```latex
\mathbf{W} = [r_1(k),\ldots,r_1(k),r_2(k),\ldots,r_2(k)]^{T}
```

donde cada componente se repite `N` veces.

### 3.3.6 Función de costo y ley de control sin restricciones

La función de costo cuadrática multivariable, definida en la sección 2.2.4, se expresa en forma matricial como:

**Preview:**

$$ J = (\hat{\mathbf{Y}} - \mathbf{W})^{T}\,\mathbf{Q}\,(\hat{\mathbf{Y}} - \mathbf{W}) + \Delta\mathbf{U}^{T}\,\mathbf{R}\,\Delta\mathbf{U} $$

**LaTeX para Word:**

```latex
J = (\hat{\mathbf{Y}} - \mathbf{W})^{T}\,\mathbf{Q}\,(\hat{\mathbf{Y}} - \mathbf{W}) + \Delta\mathbf{U}^{T}\,\mathbf{R}\,\Delta\mathbf{U}
```

donde, conforme a la convención de apilado por salida y por entrada, las matrices de ponderación son bloque-diagonales:

**Preview:**

$$ \mathbf{Q} = \text{blkdiag}(\delta_1 \mathbf{I}_N,\, \delta_2 \mathbf{I}_N),\quad \mathbf{R} = \text{blkdiag}(\lambda_1 \mathbf{I}_{N_u},\, \lambda_2 \mathbf{I}_{N_u}) $$

**LaTeX para Word:**

```latex
\mathbf{Q} = \text{blkdiag}(\delta_1 \mathbf{I}_N,\, \delta_2 \mathbf{I}_N),\quad \mathbf{R} = \text{blkdiag}(\lambda_1 \mathbf{I}_{N_u},\, \lambda_2 \mathbf{I}_{N_u})
```

con `δ_i` el peso del error de seguimiento de la salida `i` y `λ_j` el peso del esfuerzo de control de la entrada `j`.

Sustituyendo la relación de predicción `Ŷ = G·ΔU + F` y aplicando la condición de optimalidad `∂J/∂(ΔU) = 0`, se obtiene la solución óptima sin restricciones:

**Preview:**

$$ \Delta\mathbf{U}^{*} = (\mathbf{G}^{T}\,\mathbf{Q}\,\mathbf{G} + \mathbf{R})^{-1}\,\mathbf{G}^{T}\,\mathbf{Q}\,(\mathbf{W} - \mathbf{F}) $$

**LaTeX para Word:**

```latex
\Delta\mathbf{U}^{*} = (\mathbf{G}^{T}\,\mathbf{Q}\,\mathbf{G} + \mathbf{R})^{-1}\,\mathbf{G}^{T}\,\mathbf{Q}\,(\mathbf{W} - \mathbf{F})
```

Por el principio de horizonte deslizante, únicamente el primer incremento de cada canal se aplica efectivamente a la planta, y el problema se resuelve nuevamente en el siguiente periodo de muestreo con la información actualizada.

### 3.3.7 Tratamiento de restricciones (formulación QP)

En aplicaciones industriales reales, el GPC debe respetar restricciones físicas sobre los actuadores. En el sistema de cuatro tanques se consideran dos tipos:

**1) Restricción sobre los incrementos de control:**

**Preview:**

$$ \Delta u_{min} \le \Delta u_s(k+i) \le \Delta u_{max},\quad i = 0, 1, \ldots, N_u - 1 $$

**LaTeX para Word:**

```latex
\Delta u_{min} \le \Delta u_s(k+i) \le \Delta u_{max},\quad i = 0, 1, \ldots, N_u - 1
```

**2) Restricción sobre los valores absolutos de la entrada (rango operativo de las bombas):**

**Preview:**

$$ u_{min} \le u_s(k+i) \le u_{max},\quad i = 0, 1, \ldots, N_u - 1 $$

**LaTeX para Word:**

```latex
u_{min} \le u_s(k+i) \le u_{max},\quad i = 0, 1, \ldots, N_u - 1
```

Las restricciones del tipo (1) son directas. Las del tipo (2) requieren expresar el valor absoluto como acumulación de incrementos:

**Preview:**

$$ u_s(k+i) = u_s(k-1) + \sum_{j=0}^{i} \Delta u_s(k+j) $$

**LaTeX para Word:**

```latex
u_s(k+i) = u_s(k-1) + \sum_{j=0}^{i} \Delta u_s(k+j)
```

Apilando ambas relaciones para los `N_u` instantes futuros y ambas entradas, el conjunto completo de restricciones lineales adopta la forma estándar `A_ineq · ΔU ≤ b_ineq`, con:

**Preview:**

$$ \mathbf{A}_{ineq} = \begin{bmatrix} \mathbf{I} \\ -\mathbf{I} \\ \mathbf{T} \\ -\mathbf{T} \end{bmatrix},\quad \mathbf{b}_{ineq} = \begin{bmatrix} \Delta\mathbf{U}_{max} \\ -\Delta\mathbf{U}_{min} \\ \mathbf{U}_{max} - \mathbf{1}\,\mathbf{u}(k-1) \\ -\mathbf{U}_{min} + \mathbf{1}\,\mathbf{u}(k-1) \end{bmatrix} $$

**LaTeX para Word:**

```latex
\mathbf{A}_{ineq} = \begin{bmatrix} \mathbf{I} \\ -\mathbf{I} \\ \mathbf{T} \\ -\mathbf{T} \end{bmatrix},\quad \mathbf{b}_{ineq} = \begin{bmatrix} \Delta\mathbf{U}_{max} \\ -\Delta\mathbf{U}_{min} \\ \mathbf{U}_{max} - \mathbf{1}\,\mathbf{u}(k-1) \\ -\mathbf{U}_{min} + \mathbf{1}\,\mathbf{u}(k-1) \end{bmatrix}
```

donde **T** es bloque-diagonal con bloques triangulares inferiores de unos (un bloque por cada entrada). El problema de control en cada instante de muestreo se transforma así en un **problema de programación cuadrática (QP)** convexo:

**Preview:**

$$ \min_{\Delta\mathbf{U}}\ \frac{1}{2}\,\Delta\mathbf{U}^{T}\,\mathbf{H}\,\Delta\mathbf{U} + \mathbf{f}^{T}\,\Delta\mathbf{U}\quad \text{s.a.}\quad \mathbf{A}_{ineq}\,\Delta\mathbf{U} \le \mathbf{b}_{ineq} $$

**LaTeX para Word:**

```latex
\min_{\Delta\mathbf{U}}\ \frac{1}{2}\,\Delta\mathbf{U}^{T}\,\mathbf{H}\,\Delta\mathbf{U} + \mathbf{f}^{T}\,\Delta\mathbf{U}\quad \text{s.a.}\quad \mathbf{A}_{ineq}\,\Delta\mathbf{U} \le \mathbf{b}_{ineq}
```

con:

**Preview:**

$$ \mathbf{H} = 2\,(\mathbf{G}^{T}\,\mathbf{Q}\,\mathbf{G} + \mathbf{R}),\quad \mathbf{f} = 2\,\mathbf{G}^{T}\,\mathbf{Q}\,(\mathbf{F} - \mathbf{W}) $$

**LaTeX para Word:**

```latex
\mathbf{H} = 2\,(\mathbf{G}^{T}\,\mathbf{Q}\,\mathbf{G} + \mathbf{R}),\quad \mathbf{f} = 2\,\mathbf{G}^{T}\,\mathbf{Q}\,(\mathbf{F} - \mathbf{W})
```

Este problema se resuelve mediante el algoritmo `quadprog` de MATLAB, basado en métodos de punto interior, cuya convergencia está garantizada por la convexidad del problema [pendiente encontrar fuente]. La matriz **H** y la matriz de restricciones **A_ineq** son constantes y se calculan una sola vez fuera de línea, mientras que **f** y **b_ineq** se actualizan en cada iteración con los nuevos valores de **F** y `u(k-1)`.

### 3.3.8 Diagrama de flujo del controlador GPC

La operación del controlador GPC MIMO en cada instante de muestreo se resume en el diagrama de flujo de la Figura 3.X. El procedimiento se inicia con una etapa de configuración fuera de línea, en la cual se calculan los coeficientes de respuesta al escalón, la matriz dinámica **G**, las matrices de ponderación **Q** y **R**, el Hessiano **H** y la matriz de restricciones **A_ineq**. Posteriormente, en el lazo de control en tiempo real, se ejecuta secuencialmente la medición del estado, el cálculo de la respuesta libre **F**, la construcción del vector de referencia **W**, la actualización del vector lineal **f** y del lado derecho **b_ineq** de las restricciones, la resolución del problema QP y la aplicación del primer incremento de cada canal.

[INSERTAR FIGURA 3.X: Diagrama de flujo del controlador GPC MIMO. Generado como `diagrama_flujo_GPC.png` en el repositorio.]

---

## 3.4 Sintonización del controlador GPC MIMO

### 3.4.1 Generalidades y necesidad de sintonización

Una vez establecida la estructura del controlador GPC mediante el diseño matricial presentado en la sección 3.3, resta determinar los valores numéricos de sus parámetros: el período de muestreo `T_s`, el horizonte de predicción `N`, el horizonte de control `N_u`, los pesos del error de seguimiento `δ₁, δ₂` y los pesos del esfuerzo de control `λ₁, λ₂`. La selección adecuada de estos parámetros es crítica, ya que afecta directamente el compromiso entre velocidad de respuesta, robustez ante incertidumbre del modelo, manejo de restricciones y costo computacional.

En la literatura existen cuatro grandes familias de métodos de sintonización para controladores predictivos: (i) reglas **heurístico-analíticas** basadas en la dinámica nominal del proceso, (ii) métodos **analíticos explícitos** derivados a partir de aproximaciones de bajo orden de la planta, (iii) algoritmos **metaheurísticos globales** inspirados en procesos naturales y (iv) métodos de **optimización numérica directa** basados en algoritmos de búsqueda local sin gradiente.

En esta tesis se aplican y comparan **cuatro métodos representativos** —uno por cada familia metodológica— con el objetivo de identificar la sintonización que ofrezca el mejor compromiso entre simplicidad de aplicación, calidad de la respuesta y robustez del controlador.

**Tabla 3.A — Métodos de sintonización considerados**

| Familia metodológica | Método representativo | Año | Tipo |
|---|---|---|---|
| Heurístico-analítica | Clarke-Mohtadi-Tuffs | 1987 | Reglas de diseño |
| Analítica explícita | Shridhar-Cooper extendido a MIMO | 1997 | Fórmulas cerradas (FOPDT) |
| Metaheurística global | Particle Swarm Optimization (PSO) | 1995 | Optimización por enjambre |
| Numérica directa | Nelder-Mead (fminsearch) | 1965 | Búsqueda sin gradiente |

### 3.4.2 Método de Clarke-Mohtadi

El método propuesto originalmente por Clarke, Mohtadi y Tuffs en la formulación inicial del GPC [pendiente encontrar fuente — Clarke et al. 1987] establece reglas prácticas basadas en las características dinámicas del proceso. Las reglas básicas son:

- **Período de muestreo:** `T_s ≈ τ_dom / 10` a `T_s ≈ τ_dom / 20`, donde `τ_dom` es la constante de tiempo dominante del sistema.

- **Horizonte de predicción** que cubra el tiempo de subida en lazo abierto:

**Preview:**

$$ N = \left\lceil \frac{2.2 \cdot \tau_{dom}}{T_s} \right\rceil $$

**LaTeX para Word:**

```latex
N = \left\lceil \frac{2.2 \cdot \tau_{dom}}{T_s} \right\rceil
```

- **Horizonte de control pequeño** para favorecer la robustez (típicamente `N_u = 1` a `3`).

- **Ponderaciones** iniciales con `δ₁ = δ₂ = 1` y `λ` moderado (`λ ≈ 0.5`).

[INSERTAR TABLA 3.X — Parámetros del controlador GPC obtenidos por el método de Clarke-Mohtadi. Datos generados con `analisis_sintonizacion_GPC.m`.]

### 3.4.3 Método de Shridhar-Cooper extendido a MIMO

El método propuesto por Shridhar y Cooper [pendiente encontrar fuente — Shridhar & Cooper 1997] es un enfoque analítico basado en la aproximación del proceso por un modelo de primer orden más tiempo muerto (FOPDT). El método fue concebido originalmente para el caso monovariable y extendido al ámbito multivariable [10].

**Paso 1.** Aproximación de cada subproceso `(r, s)` por un modelo FOPDT:

**Preview:**

$$ G_{rs}(s) = \frac{K_{rs}\,e^{-\theta_{rs}\,s}}{\tau_{rs}\,s + 1} $$

**LaTeX para Word:**

```latex
G_{rs}(s) = \frac{K_{rs}\,e^{-\theta_{rs}\,s}}{\tau_{rs}\,s + 1}
```

**Paso 2.** Período de muestreo:

**Preview:**

$$ T_s = \min\left( 0.1 \cdot \tau_{rs} \right) $$

**LaTeX para Word:**

```latex
T_s = \min\left( 0.1 \cdot \tau_{rs} \right)
```

**Paso 3.** Horizonte de predicción:

**Preview:**

$$ N = \max\left( \frac{5\,\tau_{rs}}{T_s} + 1 \right) $$

**LaTeX para Word:**

```latex
N = \max\left( \frac{5\,\tau_{rs}}{T_s} + 1 \right)
```

**Paso 4.** Horizonte de control:

**Preview:**

$$ N_u = \max\left( \frac{\tau_{rs}}{T_s} + 1 \right) $$

**LaTeX para Word:**

```latex
N_u = \max\left( \frac{\tau_{rs}}{T_s} + 1 \right)
```

**Paso 5.** Cálculo analítico del peso del esfuerzo de control:

**Preview:**

$$ \lambda_s = \frac{N_u}{500} \sum_{r=1}^{n_y} K_{rs}^{2} \left( N + 1 - \frac{3\,\tau_{rs}}{2\,T_s} - \frac{N_u - 1}{2} \right) $$

**LaTeX para Word:**

```latex
\lambda_s = \frac{N_u}{500} \sum_{r=1}^{n_y} K_{rs}^{2} \left( N + 1 - \frac{3\,\tau_{rs}}{2\,T_s} - \frac{N_u - 1}{2} \right)
```

[INSERTAR TABLA 3.Y — Parámetros del controlador GPC obtenidos por el método de Shridhar-Cooper. Datos generados con `analisis_sintonizacion_GPC.m`.]

### 3.4.4 Método PSO (Particle Swarm Optimization)

El algoritmo de Optimización por Enjambre de Partículas, propuesto por Eberhart y Kennedy en 1995 [pendiente encontrar fuente — Eberhart & Kennedy 1995], es un método metaheurístico inspirado en el comportamiento social colectivo de aves y peces. Mantiene un conjunto de `N_p` partículas, cada una con posición `x_i` y velocidad `v_i`, que se actualizan en cada iteración:

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

donde `p_i` es la mejor posición histórica encontrada por la partícula, `g` la mejor del enjambre, `w` el coeficiente de inercia, `c_1` y `c_2` los coeficientes cognitivo y social, y `r_1, r_2 ∈ [0,1]` números aleatorios.

Para la sintonización del GPC se define el espacio de búsqueda bidimensional `x = [log₁₀(λ), N_u]`, con cotas `log₁₀(λ) ∈ [-4, 0]` y `N_u ∈ [1, N]`. La función objetivo es:

**Preview:**

$$ J_{PSO}(\lambda, N_u) = \text{IAE} + \beta_1 \cdot \Delta U_{total} + \beta_2 \cdot M_p $$

**LaTeX para Word:**

```latex
J_{PSO}(\lambda, N_u) = \text{IAE} + \beta_1 \cdot \Delta U_{total} + \beta_2 \cdot M_p
```

con `β_1 = 0.1` y `β_2 = 100`. Los parámetros del enjambre adoptados son `N_p = 6`, `5` iteraciones, `w = 0.7`, `c_1 = c_2 = 1.5` [pendiente encontrar fuente — Han, Zhao y Qian].

[INSERTAR TABLA 3.Z — Parámetros del controlador GPC obtenidos por el método PSO.]

### 3.4.5 Método de Nelder-Mead (optimización numérica directa)

El método de Nelder-Mead [pendiente encontrar fuente — Nelder & Mead 1965], implementado en MATLAB como `fminsearch`, es un algoritmo de búsqueda local sin gradiente que itera sobre un símplex en el espacio de parámetros. Se utiliza la misma función objetivo `J_PSO` y las mismas variables de decisión, tomando como punto inicial la solución entregada por el método PSO para combinar exploración global y refinamiento local. Los criterios de parada adoptados son: máximo `15` iteraciones y tolerancia de `0.5`.

[INSERTAR TABLA 3.W — Parámetros del controlador GPC obtenidos por el método Nelder-Mead.]

### 3.4.6 Comparación de métodos y selección

Aplicados los cuatro métodos al sistema de cuatro tanques, se ejecuta una simulación de validación común: cambio de referencia de `h₃⁰ = h₄⁰ = 25 cm` a `h₃ = 30 cm`, `h₄ = 20 cm`, simulada sobre el modelo no lineal de la planta. Para cada sintonización se calculan los seis criterios de desempeño y se construye un **score combinado** mediante normalización min-max:

**Preview:**

$$ \text{Score} = \sum_{i=1}^{6} w_i \cdot \tilde{m}_i $$

**LaTeX para Word:**

```latex
\text{Score} = \sum_{i=1}^{6} w_i \cdot \tilde{m}_i
```

donde `m̃_i` es la i-ésima métrica normalizada a [0, 1] y `w_i` su peso (`w = [0.20, 0.15, 0.15, 0.20, 0.15, 0.15]` para IAE, ISE, ITAE, t_est, sobrepico y esfuerzo respectivamente). El método con menor score se considera el más adecuado.

[INSERTAR TABLA 3.W2 — Comparación de los cuatro métodos de sintonización. Datos generados con `analisis_sintonizacion_GPC.m`.]

[INSERTAR FIGURA 3.Y — Respuestas comparativas en h₃ para los cuatro métodos.]

[INSERTAR FIGURA 3.Z — Respuestas comparativas en h₄ para los cuatro métodos.]

[INSERTAR FIGURA 3.W3 — Gráfica de barras del score combinado.]

Los parámetros adoptados para el controlador final son los obtenidos por el método con menor score combinado, los cuales se sintetizan en la Tabla 3.V.

[INSERTAR TABLA 3.V — Parámetros finales del controlador GPC seleccionados.]

---

## 3.5 Resumen de ecuaciones e implementación

A modo de síntesis, las ecuaciones del controlador GPC MIMO desarrollado se organizan en el orden en que se ejecutan durante el lazo de control.

**Etapa fuera de línea (se ejecuta una sola vez):**

a) Discretización del modelo lineal:

**Preview:**

$$ (\mathbf{A}_d, \mathbf{B}_d, \mathbf{C}_d) = \text{c2d}(\mathbf{A}_c, \mathbf{B}_c, \mathbf{C}_c,\,T_s,\,\text{ZOH}) $$

**LaTeX para Word:**

```latex
(\mathbf{A}_d, \mathbf{B}_d, \mathbf{C}_d) = \text{c2d}(\mathbf{A}_c, \mathbf{B}_c, \mathbf{C}_c,\,T_s,\,\text{ZOH})
```

b) Coeficientes de respuesta al escalón `g_{ij}[k]` para cada par `(i,j)` y `k = 1..N`.

c) Construcción de la matriz dinámica **G** por bloques triangulares inferiores.

d) Matrices de ponderación y Hessiano:

**Preview:**

$$ \mathbf{Q} = \text{blkdiag}(\delta_1 \mathbf{I}_N,\, \delta_2 \mathbf{I}_N),\quad \mathbf{R} = \text{blkdiag}(\lambda_1 \mathbf{I}_{N_u},\, \lambda_2 \mathbf{I}_{N_u}) $$

**LaTeX para Word:**

```latex
\mathbf{Q} = \text{blkdiag}(\delta_1 \mathbf{I}_N,\, \delta_2 \mathbf{I}_N),\quad \mathbf{R} = \text{blkdiag}(\lambda_1 \mathbf{I}_{N_u},\, \lambda_2 \mathbf{I}_{N_u})
```

**Preview:**

$$ \mathbf{H} = 2\,(\mathbf{G}^{T}\,\mathbf{Q}\,\mathbf{G} + \mathbf{R}) $$

**LaTeX para Word:**

```latex
\mathbf{H} = 2\,(\mathbf{G}^{T}\,\mathbf{Q}\,\mathbf{G} + \mathbf{R})
```

e) Matriz de restricciones lineales **A_ineq**.

**Etapa en línea (se ejecuta cada `T_s`):**

a) Cálculo de la respuesta libre **F** mediante propagación del modelo con `Δu = 0`:

**Preview:**

$$ \mathbf{x}(k+j) = \mathbf{A}_d\,\mathbf{x}(k+j-1) + \mathbf{B}_d\,\mathbf{u}(k-1) $$

**LaTeX para Word:**

```latex
\mathbf{x}(k+j) = \mathbf{A}_d\,\mathbf{x}(k+j-1) + \mathbf{B}_d\,\mathbf{u}(k-1)
```

b) Construcción del vector de referencia futura:

**Preview:**

$$ \mathbf{w}(k+j) = \mathbf{r}(k) $$

**LaTeX para Word:**

```latex
\mathbf{w}(k+j) = \mathbf{r}(k)
```

c) Vector lineal del QP:

**Preview:**

$$ \mathbf{f} = 2\,\mathbf{G}^{T}\,\mathbf{Q}\,(\mathbf{F} - \mathbf{W}) $$

**LaTeX para Word:**

```latex
\mathbf{f} = 2\,\mathbf{G}^{T}\,\mathbf{Q}\,(\mathbf{F} - \mathbf{W})
```

d) Resolución del QP:

**Preview:**

$$ \Delta\mathbf{U}^{*} = \arg\min_{\Delta\mathbf{U}}\ \frac{1}{2}\,\Delta\mathbf{U}^{T}\,\mathbf{H}\,\Delta\mathbf{U} + \mathbf{f}^{T}\,\Delta\mathbf{U}\quad \text{s.a.}\quad \mathbf{A}_{ineq}\,\Delta\mathbf{U} \le \mathbf{b}_{ineq} $$

**LaTeX para Word:**

```latex
\Delta\mathbf{U}^{*} = \arg\min_{\Delta\mathbf{U}}\ \frac{1}{2}\,\Delta\mathbf{U}^{T}\,\mathbf{H}\,\Delta\mathbf{U} + \mathbf{f}^{T}\,\Delta\mathbf{U}\quad \text{s.a.}\quad \mathbf{A}_{ineq}\,\Delta\mathbf{U} \le \mathbf{b}_{ineq}
```

e) Aplicación del primer incremento de cada canal:

**Preview:**

$$ u_s(k) = u_s(k-1) + \Delta u_s^{*}(k),\quad s = 1, 2 $$

**LaTeX para Word:**

```latex
u_s(k) = u_s(k-1) + \Delta u_s^{*}(k),\quad s = 1, 2
```

La implementación completa se encuentra en el archivo `controlador_GPC.m` del repositorio de la tesis.

---

## 3.6 Conclusiones del capítulo

En el presente capítulo se ha desarrollado el diseño completo del controlador predictivo generalizado en su versión multivariable aplicado al sistema hidráulico de cuatro tanques acoplados, manteniendo la coherencia con la formulación CARIMA y las ecuaciones diofánticas introducidas en el Capítulo 2. A partir de la matriz de funciones de transferencia discreta del proceso se obtuvo la matriz dinámica **G** por bloques triangulares inferiores construidos con los coeficientes de respuesta al escalón de cada subproceso, y se formuló la ley de control resolviendo en cada periodo de muestreo un problema de programación cuadrática que incorpora restricciones físicas sobre los actuadores.

El diseño se complementó con un análisis riguroso del problema de sintonización, en el cual se aplicaron y compararon cuatro métodos representativos de las cuatro familias metodológicas reconocidas en la literatura: el método heurístico-analítico de Clarke-Mohtadi, el método analítico explícito de Shridhar-Cooper extendido al caso multivariable, el algoritmo metaheurístico global de Optimización por Enjambre de Partículas (PSO) y el método de optimización numérica directa de Nelder-Mead. La comparación se realizó mediante un score combinado que pondera seis criterios de desempeño —sobrepico, tiempo de establecimiento, IAE, ISE, ITAE y esfuerzo de control— lo cual proporciona una evaluación objetiva y reproducible. El método con menor score combinado se adoptó como sintonización final del controlador para las pruebas del Capítulo 4.

Con la estructura matemática y los parámetros del controlador definidos, se cuenta con los elementos necesarios para abordar en el siguiente capítulo las pruebas de simulación bajo distintos escenarios operativos, incluyendo seguimiento de referencias, rechazo de perturbaciones e incertidumbre del modelo, así como el desarrollo de una propuesta de implementación práctica del controlador en un entorno industrial.
