from PIL import Image
import collections
import os

def crop_and_clean():
    img_path = "mac-frames/image combined.png"
    dest_path = "backend/public/landing/mac-frames/combined.png"
    
    if not os.path.exists(img_path):
        print(f"ERROR: No se encontró la imagen en {img_path}")
        return
        
    img = Image.open(img_path).convert("RGBA")
    width, height = img.size
    
    # Recortar la parte inferior (descartar las filas de fondo puro por debajo de y=878)
    new_height = 878
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
        
    print("Iniciando flood-fill de transparencia en imagen recortada...")
    
    while queue:
        x, y = queue.popleft()
        r, g, b, a = pixels[x, y]
        
        # Tolerancia ligeramente mayor para limpiar bordes borrosos/fringe (dif < 15, color > 140)
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
                        
    # Opcional: limpieza de borde inferior residual directo para evitar líneas blancas flotantes
    for x in range(width):
        for y in range(new_height - 5, new_height):
            r, g, b, a = pixels[x, y]
            # Si el pixel inferior sigue siendo muy claro y neutral, lo hacemos transparente
            if r > 120 and g > 120 and b > 120 and abs(r-g) < 15:
                pixels[x, y] = (r, g, b, 0)
                
    cropped_img.save(dest_path, "PNG")
    print(f"OK: Imagen perfeccionada guardada en {dest_path}")

if __name__ == "__main__":
    crop_and_clean()
