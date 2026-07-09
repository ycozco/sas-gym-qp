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

replacements = [
    ("SaasGym", "CodeFit"),
    ("SaaSGYM", "CODEFIT"),
    ("Saas Gym", "Code Fit"),
    ("GymSmart", "CodeFit")
]

print("=== INICIANDO RENOMBRADO DE MARCA A CODEFIT ===")

for filepath in files_to_update:
    if not os.path.exists(filepath):
        print(f"WARN: Archivo no encontrado: {filepath}")
        continue
        
    print(f"Procesando: {filepath}...")
    
    # Intentar leer en utf-8 o utf-16 (para archivos de Windows)
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
    else:
        print(f"INFO: Sin cambios necesarios en: {filepath}")

print("=== FINALIZADO ===")
