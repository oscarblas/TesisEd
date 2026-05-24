# ÍNDICE — Capítulo 3

**Diseño del Controlador Predictivo GPC para el Sistema Hidráulico de Cuatro Tanques Acoplados (TITO)**

---

**3.1** Introducción

**3.2** Criterios de desempeño
- 3.2.1 Sobrepico y tiempo de establecimiento
- 3.2.2 Criterios integrales del error
- 3.2.3 Esfuerzo de control y costo computacional

**3.3** Diseño del sistema de control GPC MIMO
- 3.3.1 Discretización del modelo y matriz de funciones de transferencia
- 3.3.2 Selección del horizonte del modelo y del tiempo de muestreo
- 3.3.3 Construcción de la matriz dinámica G
- 3.3.4 Cálculo de la respuesta libre F
- 3.3.5 Vector de referencia futura
- 3.3.6 Función de costo y ley de control sin restricciones
- 3.3.7 Tratamiento de restricciones (formulación QP)
- 3.3.8 Diagrama de flujo del controlador GPC

**3.4** Sintonización del controlador GPC MIMO
- 3.4.1 Generalidades y necesidad de sintonización
- 3.4.2 Método de Clarke-Mohtadi
- 3.4.3 Método de Shridhar-Cooper extendido a MIMO
- 3.4.4 Método PSO (Particle Swarm Optimization)
- 3.4.5 Método de Nelder-Mead (optimización numérica directa)
- 3.4.6 Comparación de métodos y selección

**3.5** Resumen de ecuaciones e implementación

**3.6** Conclusiones del capítulo

---

## Tablas del capítulo

| Tabla | Sección | Contenido |
|---|---|---|
| Tabla 3.1 | 3.3.2 | Parámetros del modelo del controlador GPC fijados a priori (`T_s`, `N`) |
| Tabla 3.2 | 3.3.3 | Coeficientes de respuesta al escalón `g_{ij}[k]` |
| Tabla 3.A | 3.4.1 | Métodos de sintonización considerados |
| Tabla 3.X | 3.4.2 | Parámetros obtenidos por Clarke-Mohtadi |
| Tabla 3.Y | 3.4.3 | Parámetros obtenidos por Shridhar-Cooper |
| Tabla 3.Z | 3.4.4 | Parámetros obtenidos por PSO |
| Tabla 3.W | 3.4.5 | Parámetros obtenidos por Nelder-Mead |
| Tabla 3.W2 | 3.4.6 | Comparación de los cuatro métodos |
| Tabla 3.V | 3.4.6 | Parámetros finales del controlador GPC seleccionados |

---

## Figuras del capítulo

| Figura | Sección | Contenido |
|---|---|---|
| Figura 3.X | 3.3.3 | Coeficientes de respuesta al escalón de cada subproceso (4 curvas) |
| Figura 3.Y | 3.4.6 | Respuestas comparativas en h₃ para los cuatro métodos |
| Figura 3.Z | 3.4.6 | Respuestas comparativas en h₄ para los cuatro métodos |
| Figura 3.W3 | 3.4.6 | Gráfica de barras del score combinado |
| Figura 3.diag | 3.3.8 | Diagrama de flujo del controlador GPC MIMO |
