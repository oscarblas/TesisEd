# Guía de integración — Tesis final PUCP

Este documento explica cómo integrar los dos archivos generados para producir la versión final de tu tesis que cumpla el instructivo PUCP.

---

## Archivos generados

| Archivo | Propósito |
|---|---|
| `TESIS_20212444_reformateada.docx` | Tu tesis actual con el **formato PUCP aplicado** (márgenes 2.54 cm, Times New Roman 12, doble espacio). Preserva todas tus figuras, ecuaciones y contenido. |
| `TESIS_20212444_secciones_nuevas.docx` | Contiene las **secciones nuevas** que debes insertar/reemplazar: Introducción, Objetivos, Cap. 4, Conclusiones, Recomendaciones, Bibliografía APA y Anexos con códigos MATLAB. |

---

## Flujo de trabajo recomendado

### Paso 1 — Abrir la tesis reformateada
Abre `TESIS_20212444_reformateada.docx`. Verifica visualmente que:
- Los márgenes son de 2.54 cm en los 4 lados.
- La fuente es Times New Roman 12 en todo el texto principal.
- El interlineado es doble.

Si algo del formato quedó incorrecto en algún párrafo específico, corrígelo manualmente.

### Paso 2 — Reemplazar la Introducción y los Objetivos
Abre `TESIS_20212444_secciones_nuevas.docx`. Copia el contenido de:
- **Introducción** (nueva versión) → reemplaza tu introducción actual.
- **1.5 Objetivos del trabajo de investigación** → reemplaza tu sección 1.5 actual.

### Paso 3 — Reemplazar el Capítulo 4
Copia todo el **Capítulo 4** del archivo de secciones nuevas y reemplaza el Capítulo 4 actual de tu tesis. Este capítulo tiene 6 secciones:
- 4.1 Introducción
- 4.2 Diseño del controlador PI con desacoplador estático
- 4.3 Escenario integrado de simulación
- 4.4 Análisis comparativo cuantitativo
- 4.5 Discusión y validación de la hipótesis
- 4.6 Conclusiones del capítulo

**Ecuaciones:** Cada fórmula está marcada con `[Insertar en Word con editor de ecuaciones — modo LaTeX]` seguida del código LaTeX. Para convertirlo en ecuación real:
1. Selecciona el código LaTeX.
2. Insertar → Ecuación (o `Alt` + `=`).
3. En el ribbon superior, elige modo **LaTeX**.
4. Pega el código y presiona Espacio para que Word lo renderice.

**Figuras y tablas:** Están marcadas con `[IMAGEN 4.X — ...]` y `[TABLA 4.X — ...]`. Ejecuta el script MATLAB indicado y pega la figura resultante.

### Paso 4 — Agregar Conclusiones y Recomendaciones
Después del Capítulo 4, copia las secciones:
- **Conclusiones** (8 conclusiones enumeradas)
- **Recomendaciones** (5 líneas de trabajo futuro)

Según el instructivo PUCP, estas secciones NO se numeran como capítulos (no llevan "Capítulo 5"), sino que van como secciones independientes con título centrado.

### Paso 5 — Reemplazar la Bibliografía
Copia toda la sección **Bibliografía** del archivo de secciones nuevas y reemplaza tu bibliografía actual. El formato aplicado cumple con el instructivo:
- Sangría francesa
- Orden numerado según aparición en el texto
- Incluye DOI o URL donde corresponda

**Novedad importante:** Se incorporaron 3 nuevas referencias que estaban citadas en el Cap. 4 pero no aparecían en tu bibliografía anterior:
- [17] Rivera, Morari & Skogestad (1986) — IMC
- [18] Åström & Hägglund (2006) — Advanced PID Control
- [19] Skogestad & Postlethwaite (2005) — Multivariable Feedback Control

Y también:
- [20] Shridhar & Cooper (1997)
- [21] Eberhart & Kennedy (1995) — PSO
- [22] Åström & Wittenmark (1997)
- [23] Camacho & Bordons (2007)
- [26] Nelder & Mead (1965)

### Paso 6 — Agregar los Anexos con códigos MATLAB
Al final del documento, después de la Bibliografía, copia los 5 anexos:
- **Anexo A:** `controlador_GPC.m`
- **Anexo B:** `controlador_PID.m`
- **Anexo C:** `comparacion_GPC_vs_PID.m`
- **Anexo D:** `analisis_sintonizacion_GPC.m`, `analisis_lambda_imc.m`, `trayectoria_referencias.m`
- **Anexo E:** `gpc_step_simulink.m`, `desacoplador_simulink.m`, `planta_no_lineal_simulink.m`

Los códigos están en Courier New tamaño 9 con interlineado simple (permitido por el instructivo para contenido de tablas/figuras/referencias).

### Paso 7 — Generar Índice General, Índice de Tablas e Índice de Figuras

Word puede generarlos automáticamente si tus títulos usan estilos:
- **Índice General:** Referencias → Tabla de contenido → Tabla automática.
- **Índice de Tablas:** Referencias → Insertar índice de ilustraciones → Rótulo: "Tabla".
- **Índice de Figuras:** Referencias → Insertar índice de ilustraciones → Rótulo: "Figura".

Para que esto funcione, cada título de capítulo/sección debe estar marcado con estilos **Título 1**, **Título 2**, **Título 3**, y cada tabla/figura debe llevar su rótulo (Referencias → Insertar título).

### Paso 8 — Renombrar el archivo final
Según el instructivo:
- Nombre del archivo PDF final: `20212444_Trabajo de suficiencia profesional.pdf`
  (o `20212444_Tesis.pdf` si aplica ese régimen)

---

## Cumplimiento del instructivo PUCP

| Requisito del instructivo | Estado |
|---|---|
| Carátula PUCP obligatoria | Ya la tienes — verifica que cumpla el Anexo A del instructivo |
| Resumen (200–300 palabras) | Ya lo tienes — verifica extensión |
| Índice general | Regenerar con Word (Paso 7) |
| Índice de Tablas | Generar con Word (Paso 7) |
| Índice de Figuras | Generar con Word (Paso 7) |
| Márgenes 2.54 cm | ✅ Aplicado en `_reformateada.docx` |
| Times New Roman 12 | ✅ Aplicado |
| Doble espacio | ✅ Aplicado |
| Justificado | Aplicado en secciones nuevas |
| Capítulos 1-4 | Presente en tu tesis (contenido conservado) |
| Conclusiones | ✅ Añadido |
| Recomendaciones (opcional) | ✅ Añadido |
| Bibliografía APA con sangría francesa | ✅ Añadido |
| Anexos con códigos | ✅ Añadido (A–E) |
| Numeración correlativa de tablas y figuras | Verificar en Word tras copiar |
| Citas en el texto con [n] | ✅ Cap. 4 usa el mismo esquema [n] que Cap. 1-3 |

---

## Advertencia importante

Los archivos generados **preservan tu contenido original de los Capítulos 1, 2 y 3** (con sus figuras y ecuaciones). Solo la Introducción, Objetivos, Cap. 4, Conclusiones, Bibliografía y Anexos han sido modificados o creados.

Si detectas alguna incongruencia entre lo que hay en Cap. 1-3 y las nuevas secciones (por ejemplo, referencias o nomenclatura), corrígelas manualmente.
