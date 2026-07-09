from PIL import Image
import collections
import os

def crop_screen_only():
    img_path = "mac-frames/image combined.png"
    dest_path = "backend/public/landing/mac-frames/combined.png"
    
    if not os.path.exists(img_path):
        print(f"ERROR: No se encontró la imagen en {img_path}")
        return
        
    img = Image.open(img_path).convert("RGBA")
    width, height = img.size
    
    # Recortar la parte inferior exactamente por encima de la bisagra plateada y base (y=848)
    new_height = 848
    cropped_img = img.crop((0, 0, width, new_height))
    pixels = cropped_img.load()
    
    # Flood-fill para remover el fondo cuadriculado en la imagen recortada
    queue = collections.deque()
    visited = set()
    
    # Iniciar desde bordes
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, new_height - 1))
        visited.add((x, 0))
        visited.add((x, new_height - 1))
        
    for y in range(new_height):
        queue.append((0, y))
        queue.append((width - 1, y))
        visited.add((0, y))
        visited.add((width - 1, y))
        
    print("Iniciando flood-fill de transparencia en imagen recortada a la altura de la pantalla...")
    
    while queue:
        x, y = queue.popleft()
        r, g, b, a = pixels[x, y]
        
        is_neutral = abs(r - g) < 15 and abs(r - b) < 15 and abs(g - b) < 15
        is_light = r > 140 and g > 140 and b > 140
        
        if is_neutral and is_light and a > 0:
            pixels[x, y] = (r, g, b, 0)
            
            for dx, dy in [(-1,0), (1,0), (0,-1), (0,1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < new_height:
                    if (nx, ny) not in visited:
                        visited.add((nx, ny))
                        queue.append((nx, ny))
                        
    # Limpieza final del borde inferior para asegurar corte perfecto
    for x in range(width):
        for y in range(new_height - 3, new_height):
            r, g, b, a = pixels[x, y]
            if r > 100 and g > 100 and b > 100 and abs(r-g) < 20:
                pixels[x, y] = (r, g, b, 0)
                
    cropped_img.save(dest_path, "PNG")
    print(f"OK: Imagen recortada a la altura de pantalla guardada en {dest_path}")

if __name__ == "__main__":
    crop_screen_only()
