import os
import json
import csv

def extraer_libros():
    lista_libros = []
    
    # Buscamos de forma flexible cualquier archivo que termine en .html
    archivos_html = [f for f in os.listdir(".") if f.lower().endswith(".html")]
    
    if not archivos_html:
        print(r"❌ No se encontró ningún archivo .html en esta carpeta.")
        print(r"Asegúrate de que el archivo HTML esté exactamente en: D:\Codigardos\jorge-luis")
        return []

    for archivo in archivos_html:
        print(f"📂 Leyendo archivo: {archivo}...")
        try:
            with open(archivo, "r", encoding="utf-8", errors="ignore") as f:
                contenido = f.read()
        except Exception as e:
            print(f"   ⚠️ No se pudo leer {archivo}: {e}")
            continue
            
        # Buscamos la variable de Google Analytics / Tiendanube donde están los libros
        inicio_clave = "const googleItems = ["
        inicio = contenido.find(inicio_clave)
        
        if inicio != -1:
            inicio_json = contenido.find("[", inicio)
            fin_json = contenido.find("];", inicio_json)
            
            if inicio_json != -1 and fin_json != -1:
                json_str = contenido[inicio_json:fin_json+1]
                try:
                    items = json.loads(json_str)
                    print(f"   ¡Encontrados {len(items)} elementos en {archivo}!")
                    for item in items:
                        info = item.get("info", {})
                        libro = {
                            "ID": info.get("item_id"),
                            "Titulo": info.get("item_name"),
                            "Editorial/Marca": info.get("item_brand"),
                            "Precio (ARS)": info.get("price"),
                            "Categoria Principal": info.get("item_category"),
                            "Subcategoria": info.get("item_category2"),
                            "Tema/Seccion": info.get("item_category3")
                        }
                        if libro not in lista_libros and libro.get("Titulo"):
                            lista_libros.append(libro)
                except json.JSONDecodeError as e:
                    print(f"   ⚠️ Error al interpretar los datos en {archivo}: {e}")
        else:
            print(f"   ℹ️ El archivo {archivo} no contiene la lista de productos principal de Tiendanube.")

    return lista_libros

# --- EJECUCIÓN ---
print("Iniciando extracción de libros...")
datos_libros = extraer_libros()

if datos_libros:
    nombre_csv = "libros_yenny_ateneo.csv"
    keys = datos_libros[0].keys()
    
    with open(nombre_csv, "w", newline="", encoding="utf-8-sig") as output_file:
        dict_writer = csv.DictWriter(output_file, fieldnames=keys)
        dict_writer.writeheader()
        dict_writer.writerows(datos_libros)
        
    print(r"\n¡Éxito total! Se han extraído " + str(len(datos_libros)) + r" libros y se guardaron en '" + nombre_csv + r"'.")
else:
    print(r"\n❌ No se pudo extraer información. Comprueba que el archivo HTML descargado esté en D:\Codigardos\jorge-luis.")