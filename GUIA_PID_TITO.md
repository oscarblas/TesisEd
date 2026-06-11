# GUÍA COMPLETA — Control PID Descentralizado para Sistemas TITO

> Material de estudio para presentación del avance del controlador PID en la tesis.
> Sistema objetivo: cuatro tanques acoplados (TITO: 2 entradas, 2 salidas).

---

## 1. ¿Qué es un PID y cuáles son sus tres componentes?

El **PID** (Proporcional - Integral - Derivativo) es el controlador más usado en la industria. Su filosofía es simple: **calcula un error** entre lo que quieres (`setpoint`) y lo que tienes (`medición`), y aplica una corrección basada en **tres cosas distintas que hacer con ese error**.

| Componente | Símbolo | Qué hace | Analogía intuitiva |
|---|---|---|---|
| **Proporcional** | `P` | Reacciona al error **actual** | "Si el agua está 5 cm por debajo del objetivo, abro la válvula proporcionalmente" |
| **Integral** | `I` | Reacciona al error **acumulado en el tiempo** | "Si llevo mucho tiempo con error, aunque sea pequeño, voy a corregir más fuerte" |
| **Derivativo** | `D` | Reacciona a la **velocidad de cambio** del error | "Si el error está creciendo rápido, anticipo y reacciono antes" |

**Fórmula clásica del PID en tiempo continuo:**

$$ u(t) = K_p \cdot e(t) + \frac{K_p}{T_i} \int_0^t e(\tau)\,d\tau + K_p \cdot T_d \cdot \frac{de(t)}{dt} $$

donde:
- `e(t) = r(t) - y(t)` → error (referencia menos salida medida)
- `K_p` → ganancia proporcional
- `T_i` → tiempo integral (cuánto pesa el integrador)
- `T_d` → tiempo derivativo (cuánto pesa el derivador)

---

## 2. PID, PI, P — ¿Cuándo usar cuál?

| Tipo | Cuándo se usa |
|---|---|
| **P** | Sistemas muy rápidos donde el offset (error permanente) no importa |
| **PI** | La mayoría de procesos industriales (lentos, con offset) ← **el que usaremos** |
| **PID** | Cuando se necesita anticipación, sistemas con dinámicas rápidas variables |

**En nuestra tesis usamos PI (sin término derivativo, `T_d = 0`).** Por dos razones:

1. **El derivativo amplifica ruido:** las mediciones de los sensores PIT-108 y PIT-109 tienen ruido pequeño pero constante, y el derivador lo amplifica.
2. **El sistema es de primer orden dominante:** la dinámica de los tanques es esencialmente exponencial, condición en la cual el aporte del derivador es marginal.

---

## 3. ¿Por qué necesitamos el integrador?

Es la parte más importante de entender. **Sin integrador, todo controlador tiene un error permanente** cuando hay perturbaciones o cuando el modelo no es perfecto.

**Ejemplo intuitivo:**

Imagina que controlas la temperatura de una ducha con un controlador puramente proporcional. Si abres la ducha y la temperatura debe ser 40°C pero te llega 38°C, el controlador P abre más la válvula caliente. Pero si la presión de la tubería caliente bajó (perturbación), el agua nunca llega a 40°C exactos — siempre habrá un error pequeño.

El integrador elimina ese error porque **acumula el error pequeño y aumenta la corrección hasta que el error se vaya a cero**. Por eso `e(t) → 0` en estado estacionario.

---

## 4. PID en forma discreta (lo que se implementa en código)

En MATLAB el control es **digital**: se ejecuta cada `T_s = 2 s`. Hay dos formas equivalentes:

### Forma de posición (calcula `u(k)` directo):

$$ u(k) = K_p \cdot e(k) + \frac{K_p \cdot T_s}{T_i} \sum_{i=0}^{k} e(i) + \frac{K_p \cdot T_d}{T_s}\,(e(k) - e(k-1)) $$

### Forma de velocidad o incremental (la que usamos):

$$ \Delta u(k) = K_p\,(e(k) - e(k-1)) + \frac{K_p \cdot T_s}{T_i}\,e(k) $$

$$ u(k) = u(k-1) + \Delta u(k) $$

**¿Por qué incremental?** Porque:
- Evita saltos bruscos al cambiar el setpoint
- Hace el anti-windup más fácil
- Es la forma estándar industrial

---

## 5. Sistemas Multivariables TITO — el reto

Hasta aquí, todo asume **una entrada y una salida** (SISO). Pero el sistema de 4 tanques tiene **dos entradas (bombas u₁, u₂)** y **dos salidas (niveles h₃, h₄)** que están **acopladas**:

```
                ┌─────────────┐
   u₁ ─────────►│             ├──────► h₃   (sale por dos caminos)
                │   PLANTA    │
   u₂ ─────────►│   ACOPLADA  ├──────► h₄   (sale por dos caminos)
                └─────────────┘
```

**El acoplamiento es el problema central.** Cuando muevo `u₁`, no solo afecta a `h₄` (camino directo), también afecta a `h₃` indirectamente vía el tanque superior `h₂`. Lo mismo para `u₂`.

Hay **dos estrategias clásicas** para manejarlo:

| Estrategia | Cómo funciona | Complejidad |
|---|---|---|
| **Centralizada** | Un solo controlador maneja todas las entradas y salidas a la vez (lo hace el GPC) | Alta |
| **Descentralizada** | Cada entrada tiene su propio controlador SISO independiente, **ignorando** los acoplamientos | **Baja** ← lo que hacemos con el PID |

---

## 6. Control PID Descentralizado (Multilazo)

Para controlar el sistema TITO con PID, partimos en **dos lazos independientes**:

```
         ┌─────────┐
ref_h₄ ─►│  PID₁   ├─► u₁ ─┐
         └─────────┘       │
                           ├──► PLANTA ──► h₄ ─► PID₁
         ┌─────────┐       │              └──► h₃ ─► PID₂
ref_h₃ ─►│  PID₂   ├─► u₂ ─┘
         └─────────┘
```

**Cada PID actúa como si no existiera el otro lazo.** Esto funciona razonablemente bien cuando:
- El acoplamiento es **débil** (los caminos cruzados son lentos)
- Los cambios de setpoint no son simultáneos
- No hay perturbaciones grandes

Y falla cuando:
- Hay **referencias cruzadas simultáneas** (el caso clave que pone en evidencia la ventaja del GPC)
- El acoplamiento es **fuerte**
- Hay perturbaciones cruzadas que afectan ambos lazos a la vez

---

## 7. ¿Cómo decidir qué bomba controla qué tanque? — El pairing

Esta es la decisión **más importante** del control descentralizado. Se llama **emparejamiento** o **pairing entrada-salida**.

**Regla práctica:** cada entrada debe controlar la salida con la que tiene el **camino dinámico más directo y rápido**.

En el sistema de 4 tanques (fase mínima, γ₁+γ₂ > 1):

| Bomba | Camino directo | Camino cruzado |
|---|---|---|
| `u₁` | → `h₄` (rápido, ganancia γ₁·k₁/A₄) | → `h₂` → `h₃` (lento) |
| `u₂` | → `h₃` (rápido, ganancia γ₂·k₂/A₃) | → `h₁` → `h₄` (lento) |

Por eso emparejamos:
- **`PID₁`:** `u₁` controla `h₄`
- **`PID₂`:** `u₂` controla `h₃`

**¿Cómo se justifica formalmente?** Mediante el **RGA (Relative Gain Array)** de Bristol — un análisis matemático que dice cuál par tiene el mínimo acoplamiento esperado. Para nuestro sistema en fase mínima, el RGA confirma el pairing directo.

---

## 8. Sintonización — el corazón del PID

Sintonizar significa **elegir los valores de `K_p` y `T_i`**. Hay decenas de métodos. Los más conocidos:

| Método | Idea | Cuándo se usa |
|---|---|---|
| **Ziegler-Nichols** | Inducir oscilación crítica y ajustar | Sistemas simples, sin modelo |
| **Cohen-Coon** | Identificación FOPDT manual + reglas | Procesos químicos |
| **IMC (Internal Model Control)** | Diseñar el lazo basado en el modelo | **Cuando tienes el modelo del sistema** ← lo que hacemos |
| **Lambda tuning** | Variante de IMC con un solo parámetro de ajuste | Industria petroquímica |

---

## 9. Sintonización IMC — paso a paso (la que usamos)

**Idea:** dado un modelo aproximado del proceso `G(s) = K / (τ·s + 1)`, IMC te da fórmulas cerradas para `K_p` y `T_i`.

**Paso 1.** Aproximar cada subproceso por un modelo FOPDT (primer orden + tiempo muerto, despreciable aquí):

$$ G_{loop}(s) = \frac{K}{\tau\,s + 1} $$

Para el lazo `u₁ → h₄` (asumiendo `u₂` constante):
- `K = γ₁ · k₁ · T₄ / A₄` (ganancia estática)
- `τ = T₄` (constante de tiempo)

Para el lazo `u₂ → h₃` (asumiendo `u₁` constante):
- `K = γ₂ · k₂ · T₃ / A₃`
- `τ = T₃`

**Paso 2.** Elegir `λ_imc`, la **constante de tiempo deseada en lazo cerrado**:
- `λ_imc = τ/3` → control rápido pero menos robusto (lo que usamos)
- `λ_imc = τ` → control balanceado
- `λ_imc = 2·τ` → control conservador, muy robusto

**Paso 3.** Aplicar las **fórmulas IMC**:

$$ K_p = \frac{\tau}{K \cdot \lambda_{imc}},\quad T_i = \tau,\quad T_d = 0 $$

**¡Listo!** Cada PID queda sintonizado con dos números.

**Ventaja clave de IMC:** un único parámetro `λ_imc` controla el trade-off entre velocidad y robustez. Es **mucho más intuitivo** que Ziegler-Nichols.

---

## 10. Anti-windup — qué es y por qué importa

**El problema:** las bombas tienen un rango físico `[u_min, u_max]`. Si el integrador sigue acumulando error mientras la bomba está **saturada** (al máximo), cuando el error finalmente cambia de signo, el integrador tiene un valor enorme acumulado y el controlador **demora mucho** en bajar la bomba. A esto se le llama **windup integral**.

**Resultado del windup:** sobrepicos enormes, oscilaciones, lazos lentos.

**La solución más simple (anti-windup por saturación condicional):**

```
1. Calculas Δu(k) como si no hubiera límites
2. Calculas u_temporal = u(k-1) + Δu(k)
3. Si u_temporal supera u_max o baja de u_min:
      u(k) = clip(u_temporal, u_min, u_max)
      Y NO actualizas el integrador con el exceso
```

En nuestro código, esto se logra usando la **forma incremental** y saturando `u(k)` directo: el integrador no acumula el exceso porque trabajamos con `Δu`, no con la integral explícita.

---

## 11. Alcances del PID descentralizado

**Lo que el PID descentralizado SÍ puede hacer:**

✅ Eliminar error en estado estacionario (gracias al integrador)
✅ Sintonizarse de forma sistemática con IMC
✅ Manejar referencias **secuenciales** (cambiar h₃, esperar, luego cambiar h₄)
✅ Implementarse en cualquier PLC industrial barato
✅ Ser entendido y mantenido por cualquier técnico
✅ Manejar saturación con anti-windup
✅ Funcionar bien con acoplamientos débiles

---

## 12. Limitaciones del PID descentralizado

**Lo que el PID descentralizado NO puede hacer bien:**

❌ **Manejar referencias cruzadas simultáneas** (cada lazo lucha contra la perturbación que el otro le genera)
❌ **Anticipar el efecto cruzado** de su acción sobre la otra salida
❌ Manejar **restricciones explícitas** (solo via anti-windup, no de forma óptima)
❌ Considerar el **futuro** del proceso (es 100% reactivo)
❌ Adaptarse a cambios del **punto de operación** sin re-sintonizar
❌ Coordinar las dos bombas frente a una **perturbación común**

**El argumento central de la tesis** es demostrar empíricamente estas limitaciones en escenarios específicos y mostrar que el GPC las supera todas.

---

## 13. Resultados esperados del PID descentralizado en cada escenario

| Escenario Cap. 4 | Comportamiento esperado del PID |
|---|---|
| **1. Nominal** | Bueno. Sigue las referencias con sobrepico moderado |
| **2. Cruzadas** | **Malo**. Interacciones notorias, oscilaciones, t_est alto |
| **3. Fuga** | Aceptable. El integrador compensa, pero con desviación temporal |
| **4. Ruido** | Aceptable. Sin derivativo no amplifica ruido, pero el control tiembla |
| **5. Saturación** | Aceptable si el anti-windup funciona, oscilaciones si no |
| **6. Cambio punto operación** | **Malo**. El modelo IMC fue diseñado para `h₀=25`, no para `35`. El K efectivo cambia y la sintonización ya no es óptima |

---

## 14. Resumen visual: PID descentralizado en cinco pasos

```
1. MEDIR  : leer h₃(k) y h₄(k) de los sensores
            ↓
2. ERROR  : calcular e₁ = ref_h₄ - h₄,  e₂ = ref_h₃ - h₃
            ↓
3. CALCULAR: aplicar la formula incremental del PI
              Δu₁(k) = Kp₁·(e₁-e₁_ant) + (Kp₁·Ts/Ti₁)·e₁
              Δu₂(k) = Kp₂·(e₂-e₂_ant) + (Kp₂·Ts/Ti₂)·e₂
            ↓
4. SATURAR: u(k) = u(k-1) + Δu(k), saturada a [u_min, u_max]
            ↓
5. APLICAR: enviar u₁(k), u₂(k) a las bombas
            ↓
        (esperar T_s = 2s y repetir)
```

---

## 15. Preguntas frecuentes que te pueden hacer en la presentación

**¿Por qué no usar PID en cascada en vez de descentralizado?**
> El cascada requiere medir variables intermedias (h₁, h₂). En nuestra planta solo medimos h₃ y h₄, por lo que el cascada no aplica.

**¿Por qué IMC y no Ziegler-Nichols?**
> ZN necesita inducir oscilación en la planta real, lo cual es riesgoso. IMC usa el modelo (que ya tenemos del Cap. 2), es analítico y citable.

**¿Por qué el PID no compensa el acoplamiento si tiene integrador?**
> El integrador elimina error de un lazo aislado, pero no anticipa lo que el otro lazo está haciendo. El integrador es reactivo, no anticipativo. Solo un controlador que conozca el modelo MIMO completo (como el GPC) puede anticipar.

**¿Se podría agregar un desacoplador antes del PID?**
> Sí, es la técnica de **PID con desacoplador estático/dinámico**. Funciona pero requiere conocer perfectamente el modelo y es sensible a incertidumbres. El GPC, al usar el modelo internamente, hace lo mismo de forma natural.

**¿Cuál es el rol del término derivativo si lo descartamos?**
> En sistemas con dinámica de primer orden dominante (como tanques de líquido), el derivativo aporta poco y amplifica ruido. En motores eléctricos o procesos rápidos sí se justifica.

---

## 16. Referencias bibliográficas sugeridas

- **Åström & Hägglund** (1995) — *PID Controllers: Theory, Design and Tuning* — el libro estándar de PID industriales.
- **Rivera, Morari & Skogestad** (1986) — *Internal Model Control: PID Controller Design* — paper original del método IMC.
- **Skogestad & Postlethwaite** (2005) — *Multivariable Feedback Control* — capítulo sobre control descentralizado y RGA.
- **Bristol** (1966) — paper original del RGA (Relative Gain Array).
- Adicionalmente, el libro de **Camacho & Bordons** sobre MPC contiene capítulos comparativos PID vs MPC.

---

## 17. Resumen de una línea para la presentación

> *"El PID descentralizado es el caballo de batalla de la industria por su simplicidad y bajo costo de implementación, pero al tratar al sistema MIMO como dos lazos SISO independientes ignora los acoplamientos cruzados —una limitación intrínseca que se hace evidente en escenarios con cambios de referencia simultáneos, y que motiva la adopción de controladores multivariables como el GPC."*
