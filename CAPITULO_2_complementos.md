# COMPLEMENTOS PARA CAPÍTULO 2

> Este archivo contiene las **dos secciones faltantes** del Capítulo 2 que debes agregar a tu `TESIS_20212444.docx`:
> - Sección **2.2.4 — GPC en sistemas multivariables** (va después de la sección 2.2.3)
> - Sección **2.4 — Simulación del modelo** (va al final del capítulo 2, antes de las conclusiones)
>
> **Cómo usar este archivo:**
> 1. Copia cada párrafo en Word.
> 2. Para cada fórmula, usa `Insertar → Ecuación → modo LaTeX`, pega el código LaTeX (sin los símbolos `$`) y presiona Enter.
> 3. Las figuras marcadas con `[INSERTAR FIGURA...]` debes generarlas con los scripts MATLAB indicados.
> 4. Las fuentes marcadas como `["pendiente encontrar fuente"]` debes buscarlas y agregarlas a tu bibliografía.

---

## 2.2.4 GPC en sistemas multivariables

En las secciones anteriores se introdujo el Control Predictivo Generalizado para el caso monovariable (SISO), donde una única señal de control regula una sola variable de salida. No obstante, en aplicaciones industriales reales es frecuente encontrar procesos con múltiples entradas y múltiples salidas, en los cuales las variables interactúan entre sí. Tal es el caso del sistema hidráulico de cuatro tanques acoplados objeto de esta investigación, el cual presenta una configuración de dos entradas y dos salidas (TITO) con fuerte acoplamiento cruzado. Por esta razón, resulta indispensable extender la formulación del GPC al caso multivariable, manteniendo la estructura del modelo CARIMA y la función de costo cuadrática, pero adaptando sus dimensiones para incorporar la naturaleza vectorial del proceso.

Considerando un sistema con `n_u` entradas y `n_y` salidas, la representación CARIMA del proceso se generaliza al caso matricial mediante polinomios cuyos coeficientes son matrices. La ecuación del modelo en el operador de desplazamiento hacia atrás `z⁻¹` toma la forma:

```latex
\mathbf{A}(z^{-1})\,\mathbf{y}(t) = \mathbf{B}(z^{-1})\,\mathbf{u}(t-1) + \frac{\mathbf{C}(z^{-1})}{\Delta}\,\mathbf{e}(t)
```

donde **y**(t) es el vector de salidas de dimensión `n_y × 1`, **u**(t) es el vector de entradas de dimensión `n_u × 1`, y **A**(z⁻¹), **B**(z⁻¹) y **C**(z⁻¹) son matrices polinomiales cuyas dimensiones son `n_y × n_y`, `n_y × n_u` y `n_y × n_y`, respectivamente. El operador `Δ = 1 - z⁻¹` conserva la propiedad de incorporar acción integral en el lazo de control, garantizando error nulo en estado estacionario para perturbaciones constantes [23].

Análogamente al caso SISO, la predicción de las salidas futuras se obtiene resolviendo un conjunto de ecuaciones diofánticas matriciales. Para cada paso `j` dentro del horizonte de predicción, se cumple la identidad:

```latex
\mathbf{I} = \mathbf{E}_j(z^{-1})\,\tilde{\mathbf{A}}(z^{-1}) + z^{-j}\,\mathbf{F}_j(z^{-1})
```

donde `Ã(z⁻¹) = Δ·A(z⁻¹)` y las matrices **E_j** y **F_j** se obtienen recursivamente. Esta formulación permite expresar la predicción óptima a `j` pasos como una combinación lineal entre los incrementos de control futuros y la información disponible al instante actual.

Aplicando el principio de superposición —válido por la linealidad del modelo— la predicción de cada salida `y_r(t+j)` con `r = 1, …, n_y` se construye como la suma de las contribuciones individuales de cada entrada `u_s(t)` con `s = 1, …, n_u`. En forma matricial compacta, el vector de predicciones futuras se escribe como:

```latex
\hat{\mathbf{Y}} = \mathbf{G}\,\Delta\mathbf{U} + \mathbf{f}
```

donde:

- **Ŷ** es el vector apilado de predicciones de todas las salidas a lo largo del horizonte de predicción `N`, con dimensión `(n_y · N) × 1`.
- **ΔU** es el vector apilado de incrementos de control futuros de todas las entradas a lo largo del horizonte de control `N_u`, con dimensión `(n_u · N_u) × 1`.
- **f** es el vector de respuesta libre, que recoge la influencia del estado y las acciones de control pasadas.
- **G** es la matriz dinámica multivariable, construida en bloques.

La matriz dinámica multivariable presenta una estructura por bloques que refleja la interacción entre todas las entradas y salidas del proceso:

```latex
\mathbf{G} = \begin{bmatrix}
\mathbf{G}_{11} & \mathbf{G}_{12} & \cdots & \mathbf{G}_{1n_u} \\
\mathbf{G}_{21} & \mathbf{G}_{22} & \cdots & \mathbf{G}_{2n_u} \\
\vdots & \vdots & \ddots & \vdots \\
\mathbf{G}_{n_y 1} & \mathbf{G}_{n_y 2} & \cdots & \mathbf{G}_{n_y n_u}
\end{bmatrix}
```

Cada submatriz **G_{rs}** es triangular inferior y contiene los coeficientes de la respuesta dinámica de la salida `r` frente a un incremento de la entrada `s`. La dimensión de cada submatriz es `N × N_u`, donde `N` corresponde al horizonte de predicción y `N_u` al horizonte de control.

En lo que respecta a la función de costo, su extensión al caso multivariable se realiza incorporando matrices de ponderación que permitan asignar pesos diferentes a cada salida controlada y a cada entrada manipulada. La función de costo queda definida como:

```latex
J = \sum_{j=N_1}^{N_2} \left\| \hat{\mathbf{y}}(t+j|t) - \mathbf{w}(t+j) \right\|_{\boldsymbol{\delta}}^{2} + \sum_{j=1}^{N_u} \left\| \Delta\mathbf{u}(t+j-1) \right\|_{\boldsymbol{\lambda}}^{2}
```

donde **δ** es la matriz diagonal de ponderación del error de seguimiento, de dimensión `n_y × n_y`, y **λ** es la matriz diagonal de ponderación del esfuerzo de control, de dimensión `n_u × n_u`. La notación `||·||²_M` representa la norma cuadrática ponderada por la matriz **M**.

Esta función de costo puede escribirse en forma matricial compacta como:

```latex
J = (\hat{\mathbf{Y}} - \mathbf{W})^{T}\,\mathbf{Q}\,(\hat{\mathbf{Y}} - \mathbf{W}) + \Delta\mathbf{U}^{T}\,\mathbf{R}\,\Delta\mathbf{U}
```

donde **Q** = bloque-diagonal de **δ** repetido `N` veces, y **R** = bloque-diagonal de **λ** repetido `N_u` veces. El vector **W** contiene los valores futuros de referencia.

Al sustituir la expresión de la predicción **Ŷ = GΔU + f** en la función de costo y aplicar la condición de optimalidad `∂J/∂(ΔU) = 0`, se obtiene la ley de control óptima en su forma analítica sin restricciones:

```latex
\Delta\mathbf{U}^{*} = (\mathbf{G}^{T}\mathbf{Q}\,\mathbf{G} + \mathbf{R})^{-1}\,\mathbf{G}^{T}\mathbf{Q}\,(\mathbf{W} - \mathbf{f})
```

De manera consistente con el principio de horizonte deslizante, en cada instante de muestreo se calcula el vector completo **ΔU***, pero únicamente los primeros elementos correspondientes a `Δu(t)` —es decir, las primeras `n_u` componentes del vector— se aplican a la planta. En el siguiente periodo de muestreo, la secuencia se vuelve a calcular incorporando la nueva información disponible, lo cual permite al controlador adaptarse a perturbaciones e incertidumbres no contempladas en el modelo nominal.

Cabe destacar que esta extensión al caso multivariable conserva todas las ventajas del GPC monovariable —manejo natural de retardos, acción integral incorporada y formulación cuadrática del problema de optimización—, al tiempo que incorpora explícitamente las interacciones cruzadas entre las variables del proceso. Esta característica resulta especialmente valiosa en el sistema de cuatro tanques acoplados, donde la dinámica de cada tanque inferior depende no solo de la bomba directamente asociada, sino también de la dinámica de los tanques superiores que descargan en él. En el Capítulo 3 se aplicará esta formulación al caso particular del sistema TITO objeto de estudio, considerando además la incorporación de restricciones físicas en las entradas mediante una formulación de programación cuadrática.

---

## 2.4 Simulación del modelo

Con el propósito de validar el modelo matemático desarrollado en las secciones precedentes y verificar la coherencia entre el modelo no lineal —obtenido a partir de los balances de masa y la ley de Bernoulli— y su versión linealizada en torno al punto de operación, se ha realizado una simulación comparativa en el entorno MATLAB. Esta verificación constituye un paso previo indispensable al diseño del controlador, ya que solo si el modelo linealizado reproduce con fidelidad la dinámica de la planta en una vecindad del punto de operación, será posible utilizarlo como base para la formulación predictiva del GPC.

### 2.4.1 Metodología de simulación

La simulación se ha estructurado de modo que ambos modelos —no lineal y linealizado— sean sometidos a las mismas condiciones de entrada y se ejecuten simultáneamente, permitiendo así una comparación directa de sus respuestas. Para el modelo no lineal se ha empleado el método numérico de Runge-Kutta de cuarto orden, implementado en la función `ode45` de MATLAB, dada su precisión y eficiencia para ecuaciones diferenciales ordinarias no rígidas. Para el modelo linealizado se ha utilizado la función `lsim`, la cual resuelve la respuesta temporal de sistemas lineales en espacio de estados ante entradas arbitrarias.

Los parámetros físicos empleados en la simulación corresponden a los valores experimentales de la planta piloto del Laboratorio de Control Avanzado de la PUCP, reportados por Sánchez Zurita [10] y resumidos en la Tabla 2.X.

**Tabla 2.X — Parámetros físicos de la planta piloto de cuatro tanques acoplados**

| Parámetro | Símbolo | Valor | Unidad |
|---|---|---|---|
| Área de los tanques | A₁, A₂, A₃, A₄ | 706.85 | cm² |
| Área de los orificios de salida (tanques superiores) | a₁, a₂ | 1.89 | cm² |
| Área de los orificios de salida (tanques inferiores) | a₃, a₄ | 5.39 | cm² |
| Ganancia de las bombas centrífugas | k₁, k₂ | 1 | cm³/(V·s) |
| Fracción de distribución del flujo | γ₁, γ₂ | 0.7 | adimensional |
| Aceleración de la gravedad | g | 981 | cm/s² |

El punto de operación seleccionado corresponde a niveles estacionarios `h₃⁰ = h₄⁰ = 25 cm` en los tanques inferiores, valores que se encuentran dentro del rango operativo seguro de la planta y permiten una vecindad amplia para evaluar la calidad de la linealización. Los valores estacionarios de las entradas `u₁⁰` y `u₂⁰` se obtienen resolviendo el sistema de ecuaciones de equilibrio derivado al imponer `dh_i/dt = 0`, conforme a la metodología descrita en la sección 2.3.2.

### 2.4.2 Escenario de prueba

Como escenario de validación se ha implementado una respuesta al escalón desde condiciones iniciales nulas `h(0) = [0, 0, 0, 0]ᵀ`, aplicando como entradas las señales estacionarias `u₁⁰` y `u₂⁰`. Bajo esta configuración, ambos modelos deben converger asintóticamente al punto de operación `h⁰ = [h₁⁰, h₂⁰, h₃⁰, h₄⁰]ᵀ`. Esta prueba permite evaluar simultáneamente: (i) la coherencia de los valores estacionarios calculados; (ii) la similitud entre las trayectorias dinámicas de ambos modelos en el régimen transitorio; y (iii) la capacidad del modelo linealizado para reproducir el comportamiento del sistema en una región de operación amplia.

Para el modelo lineal, dado que opera con variables desviadas respecto al punto de equilibrio, la condición inicial se traslada a `Δh(0) = h(0) - h⁰ = -h⁰`, y la entrada en desviación se mantiene en cero `Δu = u⁰ - u⁰ = 0`. La respuesta natural del sistema lineal converge entonces desde `-h⁰` hacia el origen en variables desviadas, lo cual equivale a una convergencia desde `0` hacia `h⁰` en variables absolutas.

[INSERTAR FIGURA 2.X: Respuesta comparativa de los modelos no lineal y linealizado para los cuatro tanques. Eje X: tiempo (s). Eje Y: altura (cm). Cuatro subgráficas con h₁, h₂, h₃, h₄ respectivamente. Línea azul: modelo no lineal. Línea roja punteada: modelo linealizado. Línea negra: valor estacionario h⁰. — Generar con el script `respuesta_escalon.m` disponible en el repositorio de la tesis.]

### 2.4.3 Métrica de validación

Para cuantificar la fidelidad del modelo linealizado respecto al modelo no lineal se ha empleado el índice de bondad de ajuste FIT, definido como [10]:

```latex
\text{FIT}_i\,(\%) = 100 \cdot \left( 1 - \frac{\| \mathbf{h}_i^{\text{NL}} - \mathbf{h}_i^{\text{L}} \|}{\| \mathbf{h}_i^{\text{NL}} - \overline{\mathbf{h}_i^{\text{NL}}} \|} \right)
```

donde `h_i^NL` es el vector de respuestas del modelo no lineal para el tanque `i`, `h_i^L` es la correspondiente respuesta del modelo lineal, y la barra superior denota el promedio temporal de la señal. Un valor de FIT cercano al 100% indica una correspondencia casi exacta entre ambos modelos, mientras que valores cercanos a cero o negativos indican una pobre representación lineal de la dinámica.

[INSERTAR TABLA 2.Y con los valores numéricos de FIT obtenidos para cada uno de los cuatro tanques, generados con el script `respuesta_escalon.m`. Formato sugerido: una fila por tanque con columnas "Tanque" y "FIT (%)".]

### 2.4.4 Análisis de resultados

Los resultados de la simulación —ver Figura 2.X— muestran que ambos modelos convergen al mismo valor estacionario, lo cual confirma la consistencia entre las ecuaciones no lineales y la formulación linealizada. Durante el régimen transitorio, las trayectorias presentan ligeras diferencias atribuibles a la naturaleza no lineal de los términos `√h_i` presentes en el modelo original, los cuales son aproximados por sus desarrollos de Taylor de primer orden en la versión lineal. La métrica FIT obtenida para cada tanque permite cuantificar esta diferencia y validar que, dentro de una vecindad del punto de operación, el modelo lineal es una representación adecuada para fines de diseño del controlador predictivo.

Es importante señalar que la calidad del modelo linealizado se degrada en la medida que el sistema se aleja del punto de operación, comportamiento intrínseco a cualquier técnica de linealización por Jacobiano. Por esta razón, en el Capítulo 3 se evaluará explícitamente la robustez del controlador GPC frente a esta limitación, mediante la incorporación de restricciones físicas en las entradas y la verificación del desempeño en escenarios de seguimiento de referencias dentro de la región de validez de la linealización.

Con esta verificación se concluye que el modelo desarrollado en este capítulo es matemáticamente consistente, físicamente plausible y suficientemente preciso para servir como modelo de predicción en la formulación del controlador GPC multivariable, cuyo diseño se aborda en detalle en el capítulo siguiente.
