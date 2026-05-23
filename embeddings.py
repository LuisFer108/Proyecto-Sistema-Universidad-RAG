import psycopg2
from sentence_transformers import SentenceTransformer

# ==========================================
# 1. CONEXIÓN POSTGRESQL
# ==========================================
print("Conectando a la base de datos...")
conn = psycopg2.connect(
    host="localhost",
    database="sistema_universidad",
    user="profesor",
    password="prueba"
)
cursor = conn.cursor()

# ==========================================
# 2. CARGAR MODELO
# ==========================================
print("Cargando modelo de embeddings (all-MiniLM-L6-v2)...")
model = SentenceTransformer('all-MiniLM-L6-v2')

# ==========================================
# 3. LIMPIEZA (RESET)
# ==========================================
print("Borrando embeddings antiguos o corruptos...")
cursor.execute("UPDATE reglamento_articulos SET embedding = NULL;")
conn.commit()

# ==========================================
# 4. OBTENER TEXTOS
# ==========================================
cursor.execute("SELECT articulo_id, contenido FROM reglamento_articulos;")
articulos = cursor.fetchall()

print(f"Se encontraron {len(articulos)} artículos en la base de datos.")
print("Generando nuevos vectores matemáticos. Esto puede tomar unos segundos...")

# ==========================================
# 5. GENERAR Y GUARDAR
# ==========================================
for articulo_id, contenido in articulos:
    # Convertir texto a vector
    vector = model.encode(contenido).tolist()
    
    # Guardar en la base de datos asegurando el formato string
    cursor.execute("""
        UPDATE reglamento_articulos 
        SET embedding = %s::vector 
        WHERE articulo_id = %s;
    """, (str(vector), articulo_id))

# ==========================================
# 6. COMMIT FINAL Y CIERRE
# ==========================================
conn.commit() # ¡Este es el paso crítico que guarda los cambios!
cursor.close()
conn.close()

print("\nTodos los embeddings fueron generados y guardados correctamente")