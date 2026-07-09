from PIL import Image
import collections
import os

def clean_background():
    img_path = "mac-frames/image combined.png"
    dest_path = "backend/public/landing/mac-frames/combined.png"
    
    if not os.path.exists(img_path):
        print(f"ERROR: No se encontró la imagen en {img_path}")
        return
        
    img = Image.open(img_path).convert("RGBA")
    width, height = img.size
    pixels = img.load()
    
    # Cola para flood-fill
    queue = collections.deque()
    visited = set()
    
    # Iniciar desde las 4 esquinas y bordes
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
        visited.add((x, 0))
        visited.add((x, height - 1))
        
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))
        visited.add((0, y))
        visited.add((width - 1, y))
        
    print("Iniciando flood-fill de transparencia...")
    
    # Definición de color de fondo (neutrales muy claros)
    # Checkerboard suele ser blanco (255,255,255) y gris claro (200-240)
    while queue:
        x, y = queue.popleft()
        r, g, b, a = pixels[x, y]
        
        # Verificar si es color neutro claro (blanco o gris claro)
        is_neutral = abs(r - g) < 8 and abs(r - b) < 8 and abs(g - b) < 8
        is_light = r > 180 and g > 180 and b > 180
        
        if is_neutral and is_light and a > 0:
            # Hacer transparente
            pixels[x, y] = (r, g, b, 0)
            
            # Agregar vecinos
            for dx, dy in [(-1,0), (1,0), (0,-1), (0,1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height:
                    if (nx, ny) not in visited:
                        visited.add((nx, ny))
                        queue.append((nx, ny))
                        
    img.save(dest_path, "PNG")
    print(f"OK: Imagen transparente guardada en {dest_path}")

if __name__ == "__main__":
    clean_background()
