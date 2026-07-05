"""
Aplica estilos Titulo 1/2/3 y Caption (Figura/Tabla) automaticamente
al docx, detectando por patron. Despues Word genera los indices
con Referencias -> Tabla de contenido / Insertar indice de ilustraciones.
"""
from docx import Document
from docx.shared import Pt
import re, os, sys

sys.stdout.reconfigure(encoding='utf-8')

IN  = r"C:\Users\HP\OneDrive\Escritorio\edwin\TESIS_20212444_FINAL.docx"
OUT = r"C:\Users\HP\OneDrive\Escritorio\edwin\TESIS_20212444_FINAL_estilos.docx"

doc = Document(IN)

# Verificar/crear estilos
styles = doc.styles

# Patrones (orden importa: mas especifico primero)
PATRONES = [
    # Titulo 1: Capitulos y secciones principales
    (re.compile(r'^(CAP[IÍ]TULO|Cap[ií]tulo)\s+\d+', re.I), 'Heading 1'),
    (re.compile(r'^\d+\.\s+[A-ZÁÉÍÓÚ]', re.I), 'Heading 1'),  # "1. Estudio..."
    (re.compile(r'^(INTRODUCCI[ÓO]N|CONCLUSIONES|RECOMENDACIONES|BIBLIOGRAF[ÍI]A|RESUMEN|[ÍI]NDICE)$', re.I), 'Heading 1'),
    (re.compile(r'^ANEXO\s+[A-Z]', re.I), 'Heading 1'),

    # Titulo 2: subsecciones X.Y
    (re.compile(r'^\d+\.\d+\s+[A-ZÁÉÍÓÚa-záéíóú]'), 'Heading 2'),

    # Titulo 3: sub-subsecciones X.Y.Z
    (re.compile(r'^\d+\.\d+\.\d+\s+[A-ZÁÉÍÓÚa-záéíóú]'), 'Heading 3'),

    # Titulo 3: sub-subsecciones sin espacio: 4.2.1., etc
    (re.compile(r'^\d+\.\d+\.\d+\.\s+'), 'Heading 3'),

    # Caption Figura
    (re.compile(r'^(Fig(ura|\.)\s*)\d+', re.I), 'Caption'),
    (re.compile(r'^\[?IMAGEN\s+\d+', re.I), 'Caption'),

    # Caption Tabla
    (re.compile(r'^Tabla\s+\d+', re.I), 'Caption'),
    (re.compile(r'^\[?TABLA\s+\d+', re.I), 'Caption'),
]

# Aplicar estilos
n_h1 = n_h2 = n_h3 = n_cap = 0
for p in doc.paragraphs:
    txt = p.text.strip()
    if not txt or len(txt) > 200:  # descartar parrafos largos (contenido)
        continue

    for pat, style_name in PATRONES:
        if pat.match(txt):
            try:
                p.style = doc.styles[style_name]
                if style_name == 'Heading 1':
                    n_h1 += 1
                elif style_name == 'Heading 2':
                    n_h2 += 1
                elif style_name == 'Heading 3':
                    n_h3 += 1
                elif style_name == 'Caption':
                    n_cap += 1
            except KeyError:
                pass
            break

print(f"Titulo 1 aplicados: {n_h1}")
print(f"Titulo 2 aplicados: {n_h2}")
print(f"Titulo 3 aplicados: {n_h3}")
print(f"Caption (fig/tab):  {n_cap}")

doc.save(OUT)
print(f"\nGuardado: {OUT}")
