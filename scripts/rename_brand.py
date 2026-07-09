import os

files_to_update = [
    "backend/public/landing/index.html",
    "backend/public/landing/sobre-nosotros/index.html",
    "backend/public/landing/descargas/index.html",
    "index.html",
    "web_admin/index.html",
    "web_admin/app.jsx",
    "web_admin/dashboards.jsx"
]

# Agregar todos los archivos .dart de mobile_app/lib de forma recursiva
mobile_lib_path = "mobile_app/lib"
if os.path.exists(mobile_lib_path):
    for root, dirs, files in os.walk(mobile_lib_path):
        for file in files:
            if file.endswith(".dart"):
                files_to_update.append(os.path.join(root, file))

replacements = [
    ("SaasGym", "CodeFit"),
    ("SaaSGYM", "CODEFIT"),
    ("Saas Gym", "Code Fit"),
    ("GymSmart", "CodeFit"),
    ("Saas<em>Gym</em>", "Code<em>Fit</em>"),
    ("Gym<em>Smart</em>", "Code<em>Fit</em>"),
    ("Saas<em data-astro-cid-lcdefpme>Gym</em>", "Code<em data-astro-cid-lcdefpme>Fit</em>"),
    ("Gym<em data-astro-cid-lcdefpme>Smart</em>", "Code<em data-astro-cid-lcdefpme>Fit</em>"),
    ("SaasGym. Todos", "CodeFit. Todos")
]

print("=== INICIANDO RENOMBRADO DE MARCA A CODEFIT ===")

for filepath in files_to_update:
    if not os.path.exists(filepath):
        print(f"WARN: Archivo no encontrado: {filepath}")
        continue
        
    content = None
    encodings = ["utf-8", "utf-16", "cp1252"]
    for enc in encodings:
        try:
            with open(filepath, "r", encoding=enc) as f:
                content = f.read()
            detected_encoding = enc
            break
        except Exception:
            continue
            
    if content is None:
        print(f"ERROR: Al leer la codificación de: {filepath}")
        continue
        
    original_content = content
    for old, new in replacements:
        content = content.replace(old, new)
        
    if content != original_content:
        with open(filepath, "w", encoding=detected_encoding) as f:
            f.write(content)
        print(f"OK: Archivo actualizado: {filepath} ({detected_encoding})")

print("=== FINALIZADO ===")
