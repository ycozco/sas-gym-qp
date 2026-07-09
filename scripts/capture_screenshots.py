import time
import os
import sys
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

# Forzar salida en UTF-8 en Windows
sys.stdout.reconfigure(encoding='utf-8')

def capture_screenshots():
    print("=== INICIANDO CAPTURA AUTOMÁTICA DE PANTALLAS ===")
    
    os.makedirs("mac-frames", exist_ok=True)
    
    chrome_options = webdriver.ChromeOptions()
    chrome_options.add_argument("--headless=new")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    # Habilitar logs del navegador
    chrome_options.set_capability('goog:loggingPrefs', {'browser': 'ALL'})
    
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=chrome_options)
    
    try:
        # --- 1. CAPTURA DEL WEB ADMIN (REACT) ---
        print("\n1. Abriendo Panel Web Admin...")
        driver.set_window_size(1440, 900)
        driver.get("http://localhost:8282/admin/")
        
        # Esperar 4 segundos y tomar captura inicial
        time.sleep(4)
        driver.save_screenshot("mac-frames/web_initial_load.png")
        print("Captura inicial guardada en mac-frames/web_initial_load.png")
        
        # Imprimir logs de la consola por si hay errores de JS
        print("--- LOGS DE CONSOLA DEL NAVEGADOR (WEB ADMIN) ---")
        for entry in driver.get_log('browser'):
            print(f"[{entry['level']}] {entry['message']}")
        print("-------------------------------------------------")
        
        # Intentar login
        wait = WebDriverWait(driver, 10)
        email_input = wait.until(EC.presence_of_element_located((By.ID, "lg-email")))
        pass_input = driver.find_element(By.ID, "lg-pass")
        
        print("Ingresando credenciales de Administrador...")
        email_input.clear()
        email_input.send_keys("admin1.surco@test.sasgym.com")
        pass_input.clear()
        pass_input.send_keys("admin_secure_pass")
        
        submit_btn = driver.find_element(By.XPATH, "//button[@type='submit']")
        submit_btn.click()
        
        print("Esperando renderizado del Dashboard del Web Admin...")
        time.sleep(5)
        
        screenshot_web_path = os.path.abspath("mac-frames/web_dashboard.png")
        driver.save_screenshot(screenshot_web_path)
        print(f"Captura del Dashboard Web guardada en: {screenshot_web_path}")
        
        # --- 2. CAPTURA DEL FLUTTER WEB APP ---
        print("\n2. Abriendo Flutter Web App...")
        driver.set_window_size(390, 950)
        # Utilizar autologin=true para iniciar sesión automáticamente mediante la lógica integrada en Flutter Web
        driver.get("http://localhost:3000/app/?autologin=true")
        
        print("Esperando inicialización y autologin de Flutter Web App (10 segundos)...")
        time.sleep(10)
        
        # Tomar captura inicial de la app
        driver.save_screenshot("mac-frames/app_initial_load.png")
        print("Captura inicial de la App guardada en mac-frames/app_initial_load.png")
        
        print("--- LOGS DE CONSOLA DEL NAVEGADOR (FLUTTER APP) ---")
        for entry in driver.get_log('browser'):
            print(f"[{entry['level']}] {entry['message']}")
        print("---------------------------------------------------")
        
        screenshot_app_path = os.path.abspath("mac-frames/flutter_app.png")
        driver.save_screenshot(screenshot_app_path)
        print(f"Captura de la App Flutter guardada en: {screenshot_app_path}")
        
    except Exception as e:
        print(f"Error durante la captura: {e}")
        driver.save_screenshot("mac-frames/error_fallback.png")
    finally:
        driver.quit()
        print("\n=== FINALIZADO ===")

if __name__ == "__main__":
    capture_screenshots()
