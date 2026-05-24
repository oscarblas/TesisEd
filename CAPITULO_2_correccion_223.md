# CORRECCIÓN — Sección 2.2.3 Función de costo y algoritmo de control

> **Problema detectado:** la sección 2.2.3 actual de tu tesis formula la solución en términos de `u` (estilo DMC clásico) en lugar de `Δu` (estilo GPC). Aunque la forma matemática es la misma, el GPC trabaja **siempre con incrementos de control** porque el modelo CARIMA incorpora el operador `Δ = 1 - z⁻¹` que aporta la acción integral.
>
> **Cómo usar este archivo:** reemplaza la sección 2.2.3 completa de tu .docx con el contenido que sigue. Las fórmulas vienen en formato preview + LaTeX como en los demás archivos.

---

## 2.2.3 Función de costo y algoritmo de control

El objetivo del Control Predictivo Generalizado consiste en determinar una secuencia futura de **incrementos de control** `Δu(t), Δu(t+1), … , Δu(t+N_u-1)` que minimice la desviación entre la salida predicha del sistema y la referencia deseada a lo largo del horizonte de predicción, manteniendo además un esfuerzo de control acotado. Esta tarea se formaliza mediante la minimización de una función de costo cuadrática que pondera de manera explícita ambos objetivos:

**Preview:**

$$ J(N_1, N_2, N_u) = \sum_{j=N_1}^{N_2} \delta(j)\,[\hat{y}(t+j|t) - w(t+j)]^{2} + \sum_{j=1}^{N_u} \lambda(j)\,[\Delta u(t+j-1)]^{2} $$

**LaTeX para Word:**

```latex
J(N_1, N_2, N_u) = \sum_{j=N_1}^{N_2} \delta(j)\,[\hat{y}(t+j|t) - w(t+j)]^{2} + \sum_{j=1}^{N_u} \lambda(j)\,[\Delta u(t+j-1)]^{2}
```

donde `ŷ(t+j|t)` corresponde a la predicción óptima de la salida obtenida en la sección 2.2.2, `w(t+j)` es la trayectoria futura de referencia, `N_1` y `N_2` representan los horizontes mínimo y máximo de predicción —usualmente `N_1 = d + 1` y `N_2 = N` donde `d` es el tiempo muerto del proceso—, y `N_u` denota el horizonte de control. Las funciones `δ(j)` y `λ(j)` constituyen secuencias de ponderación: la primera pondera el error de seguimiento en cada paso del horizonte de predicción y la segunda penaliza la magnitud de los incrementos de control.

Es importante destacar una diferencia fundamental respecto a estrategias predictivas clásicas como el Control por Matriz Dinámica (DMC). Mientras que el DMC, en su formulación original, optimiza directamente la señal de control `u(t)` y requiere añadir externamente la acción integral, el GPC realiza la optimización sobre los **incrementos `Δu(t+j-1)`**. Esta elección no es casual: el modelo CARIMA empleado en la sección 2.2.2 incluye el operador `Δ = 1 - z⁻¹` en el denominador, lo cual incorpora un integrador en el lazo de control de manera natural y garantiza error nulo en estado estacionario ante perturbaciones constantes [23].

Para obtener la solución óptima, conviene expresar la función de costo en forma matricial. Definiendo los vectores apilados:

**Preview:**

$$ \hat{\mathbf{y}} = [\hat{y}(t+N_1|t),\,\hat{y}(t+N_1+1|t),\,\ldots,\,\hat{y}(t+N_2|t)]^{T} $$

**LaTeX para Word:**

```latex
\hat{\mathbf{y}} = [\hat{y}(t+N_1|t),\,\hat{y}(t+N_1+1|t),\,\ldots,\,\hat{y}(t+N_2|t)]^{T}
```

**Preview:**

$$ \mathbf{w} = [w(t+N_1),\,w(t+N_1+1),\,\ldots,\,w(t+N_2)]^{T} $$

**LaTeX para Word:**

```latex
\mathbf{w} = [w(t+N_1),\,w(t+N_1+1),\,\ldots,\,w(t+N_2)]^{T}
```

**Preview:**

$$ \Delta\mathbf{u} = [\Delta u(t),\,\Delta u(t+1),\,\ldots,\,\Delta u(t+N_u-1)]^{T} $$

**LaTeX para Word:**

```latex
\Delta\mathbf{u} = [\Delta u(t),\,\Delta u(t+1),\,\ldots,\,\Delta u(t+N_u-1)]^{T}
```

y empleando la relación de predicción `ŷ = G·Δu + f` obtenida en la sección 2.2.2, la función de costo puede reescribirse como:

**Preview:**

$$ J = (\mathbf{G}\,\Delta\mathbf{u} + \mathbf{f} - \mathbf{w})^{T}\,(\mathbf{G}\,\Delta\mathbf{u} + \mathbf{f} - \mathbf{w}) + \lambda\,\Delta\mathbf{u}^{T}\,\Delta\mathbf{u} $$

**LaTeX para Word:**

```latex
J = (\mathbf{G}\,\Delta\mathbf{u} + \mathbf{f} - \mathbf{w})^{T}\,(\mathbf{G}\,\Delta\mathbf{u} + \mathbf{f} - \mathbf{w}) + \lambda\,\Delta\mathbf{u}^{T}\,\Delta\mathbf{u}
```

donde se ha asumido por simplicidad `δ(j) = 1` y `λ(j) = λ` para todos los pasos del horizonte. La generalización al caso con ponderaciones distintas por paso se obtiene reemplazando los productos escalares por formas cuadráticas con matrices de peso, formulación que se detalla en la sección 2.2.4 al abordar el caso multivariable.

Para hallar la secuencia óptima de incrementos de control, se deriva la función de costo respecto al vector `Δu` y se iguala a cero:

**Preview:**

$$ \frac{\partial J}{\partial \Delta\mathbf{u}} = 2\,\mathbf{G}^{T}\,(\mathbf{G}\,\Delta\mathbf{u} + \mathbf{f} - \mathbf{w}) + 2\,\lambda\,\Delta\mathbf{u} = \mathbf{0} $$

**LaTeX para Word:**

```latex
\frac{\partial J}{\partial \Delta\mathbf{u}} = 2\,\mathbf{G}^{T}\,(\mathbf{G}\,\Delta\mathbf{u} + \mathbf{f} - \mathbf{w}) + 2\,\lambda\,\Delta\mathbf{u} = \mathbf{0}
```

Resolviendo esta condición de optimalidad, se obtiene la expresión analítica de la secuencia óptima de **incrementos** de control:

**Preview:**

$$ \Delta\mathbf{u}^{*} = (\mathbf{G}^{T}\,\mathbf{G} + \lambda\,\mathbf{I})^{-1}\,\mathbf{G}^{T}\,(\mathbf{w} - \mathbf{f}) $$

**LaTeX para Word:**

```latex
\Delta\mathbf{u}^{*} = (\mathbf{G}^{T}\,\mathbf{G} + \lambda\,\mathbf{I})^{-1}\,\mathbf{G}^{T}\,(\mathbf{w} - \mathbf{f})
```

Este resultado constituye el **resultado fundamental del GPC sin restricciones**: el vector de incrementos óptimos se obtiene como una transformación lineal del error de seguimiento futuro `(w - f)`. La matriz `(GᵀG + λI)⁻¹·Gᵀ` —cuyo cálculo se realiza una sola vez fuera de línea— concentra toda la información del modelo y los parámetros de sintonización.

Si bien `Δu*` contiene los incrementos óptimos para los próximos `N_u` instantes, en el GPC se aplica el principio de **horizonte deslizante** (receding horizon): únicamente el primer incremento `Δu(t)` se transmite efectivamente al actuador, mientras que el resto se descarta. En el siguiente periodo de muestreo se vuelve a resolver el problema de optimización utilizando la información más reciente del proceso, lo cual permite al controlador incorporar de manera continua las correcciones necesarias frente a perturbaciones e incertidumbres no contempladas en el modelo nominal. Esta diferencia respecto a un controlador clásico de lazo abierto es la que confiere al GPC su robustez y capacidad de adaptación.

Formalmente, definiendo `K` como la primera fila de la matriz `(GᵀG + λI)⁻¹·Gᵀ`, el incremento de control aplicado en cada instante se calcula como:

**Preview:**

$$ \Delta u(t) = \mathbf{K}\,(\mathbf{w} - \mathbf{f}) $$

**LaTeX para Word:**

```latex
\Delta u(t) = \mathbf{K}\,(\mathbf{w} - \mathbf{f})
```

y finalmente la señal de control efectiva que se envía a la planta es:

**Preview:**

$$ u(t) = u(t-1) + \Delta u(t) $$

**LaTeX para Word:**

```latex
u(t) = u(t-1) + \Delta u(t)
```

Esta última expresión es la que materializa la **acción integral** del GPC: la señal de control se actualiza de manera acumulativa instante a instante, garantizando que cualquier desviación persistente del error se traduzca en una corrección sostenida del control, hasta alcanzar el régimen estacionario deseado.

En la sección siguiente se extenderá esta formulación al caso multivariable, donde el proceso presenta múltiples entradas y salidas con interacciones cruzadas, situación que corresponde directamente al sistema hidráulico de cuatro tanques acoplados objeto de esta investigación.

---

> **Resumen de cambios respecto a la versión actual de tu tesis:**
>
> 1. **Variable de optimización:** se reemplazó `u` por `Δu` en la función de costo, la derivada parcial y la solución analítica.
> 2. **Solución óptima:** se aclara que `Δu* = (GᵀG + λI)⁻¹·Gᵀ·(w - f)` entrega los **incrementos óptimos**, no la señal de control absoluta.
> 3. **Acción integral:** se añade la expresión final `u(t) = u(t-1) + Δu(t)` que conecta los incrementos con la señal efectivamente aplicada.
> 4. **Diferenciación explícita respecto a DMC:** se añade un párrafo que destaca por qué el GPC trabaja con `Δu` (por el operador `Δ` del modelo CARIMA) y no con `u` directamente.
> 5. **Vector K:** se aclara que `K` es la primera fila de la matriz, consistente con el principio de horizonte deslizante.
