# PROPUESTA — Índice del Capítulo 4

**Tentativa: Comparación del Controlador Predictivo GPC frente al Control PID Convencional bajo Escenarios con Referencias Cruzadas**

> **Objetivo del capítulo:** Demostrar de forma cuantitativa y reproducible la superioridad del controlador GPC diseñado en el Capítulo 3 sobre un esquema PID descentralizado tradicional, especialmente en aspectos donde la naturaleza multivariable del sistema de cuatro tanques acoplados pone en evidencia las limitaciones del control clásico.

---

## Diferenciación respecto a antecedentes

| Aspecto | LICENCIATURA (Oré, 2022) | MAESTRÍA (Sánchez Zurita, 2018) | **Este trabajo** |
|---|---|---|---|
| Foco del Cap. 4 | Pruebas de DMC con dos métodos de sintonización + LabView | Comparación DMC vs DMPC + implementación en PLC | **GPC vs PID descentralizado** |
| Naturaleza de la comparación | Mismo controlador, distinto método de sintonización | Dos predictivos entre sí | **Predictivo vs clásico** |
| Escenarios | Set-point + perturbaciones + incertidumbre | Set-point + falla de sensores + alejamiento del punto | **Referencias cruzadas + acoplamiento + restricciones + perturbaciones + incertidumbre** |
| Implementación práctica | LabView con planta simulada | PLC Allen Bradley + HMI | **Propuesta de implementación industrial (no experimental)** |

---

## Índice tentativo

**4.1** Introducción

**4.2** Implementación del controlador PID descentralizado de referencia
- 4.2.1 Estrategia de emparejamiento entrada-salida (input-output pairing)
- 4.2.2 Sintonización por Internal Model Control (IMC)
- 4.2.3 Algoritmo discreto con anti-windup y saturación

**4.3** Escenarios de prueba comparativos
- 4.3.1 Configuración común de simulación (planta no lineal, tiempo, ruido)
- 4.3.2 Caso nominal: seguimiento de referencias independientes
- 4.3.3 **Referencias cruzadas: cambios simultáneos opuestos en `h₃` y `h₄`**
- 4.3.4 Rechazo a perturbaciones externas (fugas, cambios en `γ_i`)
- 4.3.5 Robustez ante incertidumbre paramétrica del modelo (±20% en ganancias)
- 4.3.6 Manejo de restricciones físicas y saturación de actuadores

**4.4** Análisis comparativo cuantitativo
- 4.4.1 Métricas aplicadas: IAE, ISE, ITAE, `t_s`, sobrepico, esfuerzo de control
- 4.4.2 Cuantificación del efecto del acoplamiento cruzado
- 4.4.3 Análisis del esfuerzo de control y desgaste de actuadores
- 4.4.4 Costo computacional y viabilidad en tiempo real

**4.5** Discusión de resultados y validación de la hipótesis
- 4.5.1 Limitaciones intrínsecas del PID descentralizado en sistemas MIMO acoplados
- 4.5.2 Ventajas del GPC en el manejo coordinado de las entradas
- 4.5.3 Trade-offs identificados (complejidad, sintonización, cómputo)

**4.6** Propuesta de implementación en entorno industrial
- 4.6.1 Consideraciones de hardware: PLC industrial vs PC industrial
- 4.6.2 Arquitectura del software de control (resolución del QP en línea)
- 4.6.3 Integración con la instrumentación existente del Laboratorio de Control Avanzado PUCP
- 4.6.4 Limitaciones prácticas y trabajo futuro

**4.7** Conclusiones del capítulo

---

## Aportes diferenciadores del Capítulo 4

1. **Comparación predictivo vs clásico:** ninguna de las dos tesis referencia hace esta comparación de manera explícita en la misma planta de cuatro tanques. Mientras Oré compara dos sintonizaciones del mismo DMC y Sánchez Zurita compara dos predictivos (DMC vs DMPC), esta tesis aborda la pregunta más relevante para la industria: **¿vale la pena pasarse del PID a un predictivo?**

2. **Escenarios de referencias cruzadas:** se diseña específicamente un conjunto de pruebas donde los cambios de consigna de `h₃` y `h₄` ocurren en direcciones opuestas y simultáneamente. Este escenario maximiza el acoplamiento cruzado del sistema TITO y es el punto donde el PID descentralizado tiende a fallar (interacciones entre lazos que el controlador ignora). En cambio, el GPC, al considerar todo el sistema en su formulación, las gestiona de forma coordinada.

3. **Cuantificación del acoplamiento:** se introduce una métrica específica para medir cuánto se desvía una salida cuando el otro lazo cambia su referencia. Esta métrica no se utiliza en las tesis referencia y refuerza el argumento principal del trabajo.

4. **Discusión de costo computacional:** se incluye una comparación del tiempo de ejecución por iteración entre el GPC y el PID, abordando explícitamente el trade-off entre desempeño y coste computacional —un argumento típico que se esgrime en contra del MPC industrial—. Esto permite justificar si el GPC es realmente viable en hardware comparable al actual de la planta piloto.

5. **Propuesta de implementación (no experimental):** a diferencia de Sánchez Zurita que llega a la implementación en PLC, este trabajo se queda en una **propuesta razonada** de implementación, lo cual es coherente con el alcance de tesis de bachiller y deja abierta una continuación natural en futuros trabajos.

---

## Vínculo con capítulos anteriores

- **Cap. 1:** justifica que el control de nivel multivariable es un reto donde el PID muestra limitaciones; el Cap. 4 demuestra empíricamente esa limitación.
- **Cap. 2:** introduce la teoría del GPC y modela el sistema; el Cap. 4 valida la utilidad del modelo y la teoría.
- **Cap. 3:** diseña y sintoniza el GPC; el Cap. 4 lo pone a prueba contra el PID en escenarios realistas.

---

## Tablas y figuras previstas

| Elemento | Sección | Contenido |
|---|---|---|
| Tabla 4.1 | 4.2.2 | Parámetros de los PID descentralizados sintonizados por IMC |
| Figura 4.1 | 4.3.2 | Respuestas comparativas GPC vs PID — caso nominal |
| Figura 4.2 | 4.3.3 | Respuestas comparativas — referencias cruzadas (escenario clave) |
| Figura 4.3 | 4.3.4 | Comportamiento ante perturbaciones |
| Figura 4.4 | 4.3.5 | Comportamiento bajo incertidumbre paramétrica |
| Figura 4.5 | 4.3.6 | Respuesta bajo saturación de actuadores |
| Tabla 4.2 | 4.4.1 | Resumen de métricas por escenario y por controlador |
| Tabla 4.3 | 4.4.2 | Métrica de acoplamiento cruzado por controlador |
| Tabla 4.4 | 4.4.4 | Tiempo de ejecución por iteración (GPC vs PID) |
| Figura 4.6 | 4.6.2 | Arquitectura propuesta del software de control |

---

> **Nota:** este índice es **tentativo**. Es deseable revisar la propuesta antes de comenzar la redacción, especialmente para confirmar:
> 1. Si se mantiene la propuesta de implementación (4.6) o si se omite para enfocar todo el capítulo en la comparación.
> 2. Si los escenarios propuestos en 4.3 cubren los aspectos clave que se desean evidenciar.
> 3. Si se desea agregar algún escenario adicional (por ejemplo, ruido de sensor o fallo de actuador).
