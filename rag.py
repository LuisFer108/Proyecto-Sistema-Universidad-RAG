from sentence_transformers import SentenceTransformer
import psycopg2
import ollama

# ==========================================
# INICIALIZACIÓN
# ==========================================

print("Cargando modelo de inteligencia artificial...")
model = SentenceTransformer('all-MiniLM-L6-v2')

conn = psycopg2.connect(
    host="localhost",
    database="sistema_universidad",
    user="profesor",
    password="prueba"
)
cursor = conn.cursor()

# ==========================================
# FUNCIÓN RAG HÍBRIDO (Vectores + SQL)
# ==========================================

def consultar_asistente_integral():
    pregunta = input("\nPregunta lo que quieras (Reglamentos, Profesores, Materias...): ")

    # --------------------------------------
    # 1. BÚSQUEDA VECTORIAL (REGLAMENTOS)
    # --------------------------------------
    embedding_pregunta = model.encode(pregunta).tolist()
    
    cursor.execute("""
        SELECT tipo, contenido
        FROM reglamento_articulos
        ORDER BY embedding <=> %s::vector
        LIMIT 100;
    """, (str(embedding_pregunta),))
    
    resultados_reglas = cursor.fetchall()
    contexto_texto = "\n--- REGLAMENTOS DE LA UNIVERSIDAD ---\n"
    for tipo, contenido in resultados_reglas:
        contexto_texto += f"- [{tipo.upper()}]: {contenido}\n"

    # --------------------------------------
    # 2. BÚSQUEDA SQL "INTELIGENTE" (DATOS)
    # --------------------------------------
    # --------------------------------------
    # 2. BÚSQUEDA SQL "INTELIGENTE" (DATOS)
    # --------------------------------------
    
    # Buscar Materias mencionadas
    cursor.execute("""
        SELECT nombre, creditos 
        FROM materias 
        WHERE %s ILIKE '%%' || nombre || '%%';
    """, (pregunta,))
    materias_encontradas = cursor.fetchall()

    # Buscar Docentes mencionados (uniendo con usuarios)
    cursor.execute("""
        SELECT u.nombre, u.email 
        FROM docentes d
        JOIN usuarios u ON d.docente_id = u.usuario_id
        WHERE %s ILIKE '%%' || u.nombre || '%%';
    """, (pregunta,))
    docentes_encontrados = cursor.fetchall()

    # NUEVO: Extraer los nombres de todos los reglamentos y becas
    cursor.execute("""
        SELECT DISTINCT reglamento 
        FROM v_reglamentos_completos;
    """)
    nombres_reglamentos = cursor.fetchall()

    contexto_datos = "\n--- DATOS ESTRUCTURADOS (BASE DE DATOS) ---\n"
    
    # Inyectar materias
    if materias_encontradas:
        contexto_datos += "Materias identificadas:\n"
        for nombre, creditos in materias_encontradas:
            contexto_datos += f"  * {nombre} ({creditos} créditos)\n"
            
    # Inyectar docentes
    if docentes_encontrados:
        contexto_datos += "Docentes identificados:\n"
        for nombre, email in docentes_encontrados:
            contexto_datos += f"  * {nombre} (Correo: {email})\n"

    # Inyectar la lista de becas/reglamentos si la pregunta busca opciones
    if "beca" in pregunta.lower() or "lista" in pregunta.lower() or "cuales" in pregunta.lower() or "qué" in pregunta.lower():
        contexto_datos += "\nCategorías de reglamentos y becas existentes en la institución:\n"
        for reg in nombres_reglamentos:
            contexto_datos += f"  * {reg[0]}\n"

    if not materias_encontradas and not docentes_encontrados and "beca" not in pregunta.lower():
         contexto_datos += "No se extrajeron datos estructurados específicos para esta consulta.\n"
    # --------------------------------------
    # 3. UNIÓN DE CONTEXTOS Y PROMPT
    # --------------------------------------
    contexto_total = contexto_texto + contexto_datos

    # Depuración (puedes comentarlo luego)
    print("\n[DEBUG] CONTEXTO ENVIADO A LLaMA:")
    print(contexto_total)

    prompt = f"""
    Eres un asistente universitario experto.
    Usa TODO el CONTEXTO proporcionado a continuación para responder la PREGUNTA.
    El contexto ahora incluye tanto reglamentos (texto) como datos exactos de la base de datos (materias, créditos, profesores).
    Relaciona ambas informaciones si es necesario. Si no tienes la información, dilo.

    CONTEXTO:
    {contexto_total}

    PREGUNTA:
    {pregunta}
    """

    # --------------------------------------
    # 4. LLAMADA A OLLAMA
    # --------------------------------------
    print("\nGenerando respuesta...")
    respuesta = ollama.chat(
        model="llama3",
        messages=[{"role": "user", "content": prompt}]
    )

    print("\n===========================================")
    print("RESPUESTA DEL ASISTENTE:")
    print("===========================================")
    print(respuesta['message']['content'])

# ==========================================
# MENÚ PRINCIPAL
# ==========================================

while True:
    print("\n==============================")
    print("SISTEMA UNIVERSITARIO RAG")
    print("==============================")
    print("1. Asistente Integral")
    print("2. Salir")
    
    opcion = input("\nSeleccione opción: ")
    
    if opcion == "1":
        consultar_asistente_integral()
    elif opcion == "2":
        print("\nSaliendo...")
        break
    else:
        print("\nOpción inválida")

cursor.close()
conn.close()