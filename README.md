Sistema Universitario con RAG

Este repositorio contiene la implementación de una base de datos relacional para un Sistema Universitario, complementada con un sistema RAG (Retrieval-Augmented Generation) para la consulta inteligente de reglamentos institucionales. Este proyecto corresponde a la Actividad evaluativa final de la materia Sistemas de Gestión de Bases de Datos · DatAI.

**Profesor:** Santiago Jiménez Londoño

**Integrantes del equipo:**

- Luis Fernando Bernal Ramirez
  
-Ashly Sofia Robayo Parra

-Kelvin Javier Restrepo Villalonga

-Miguel Martinez Gallego

---

## Requisitos Previos

Para garantizar que el sistema funcione correctamente, es necesario contar con el siguiente software instalado en la máquina local:

* **PostgreSQL (15+):** Motor de base de datos.
* **Extensión `pgvector`:** Necesaria para el almacenamiento y búsqueda vectorial de los embeddings.
* **Python (3.8+):** Entorno de ejecución para los scripts.
* **Ollama:** Motor local para ejecutar modelos de lenguaje (LLM).

### Librerías de Python requeridas

Instala las dependencias necesarias ejecutando el siguiente comando en tu terminal:

```bash
pip install sentence-transformers psycopg2-binary ollama
```

---

## Paso 1: Configuración de la Base de Datos

El sistema espera conectarse a una base de datos específica con credenciales predefinidas. Sigue estos pasos en tu cliente de PostgreSQL (pgAdmin, DBeaver, psql, etc.):

1. **Crear la base de datos y el usuario:**
   Ejecuta los siguientes comandos, uno por uno, como administrador de Postgres:
```sql
    CREATE DATABASE sistema_universidad;
    CREATE USER profesor WITH PASSWORD 'prueba';
    GRANT ALL PRIVILEGES ON DATABASE sistema_universidad TO profesor;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO profesor;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO profesor;
   ```

2. **Habilitar extensiones requeridas:**
   Conéctate a la base de datos `sistema_universidad` y ejecuta:
```sql
   CREATE EXTENSION IF NOT EXISTS pgcrypto;
   CREATE EXTENSION IF NOT EXISTS vector;
   ```

3. **Ejecutar los scripts SQL (en orden estricto):**
   Para evitar problemas con las llaves foráneas y dependencias, ejecuta los archivos en este orden:
   * `sistema_universidad.sql` (Crea el esquema principal, usuarios, facultades, carreras, etc.).
   * `reglamentos.sql` (Crea las tablas de normativas e inserta los artículos).
   * `triggers.sql` (Implementa la lógica de negocio y restricciones transaccionales).
   * `datos.sql` (Puebla la base de datos con información sintética de prueba).

4. **Preparar la tabla para Embeddings:**
   Dado que los scripts `embeddings.py` y `rag.py` hacen uso de una columna vectorial, asegúrate de añadirla a la tabla de reglamentos ejecutando:
```sql
   ALTER TABLE reglamento_articulos ADD COLUMN embedding vector(384);
   ```

---

## Paso 2: Generación del Modelo y Embeddings

El sistema utiliza el modelo `all-MiniLM-L6-v2` de HuggingFace para convertir los textos de los reglamentos en vectores.

1. Asegúrate de estar en el mismo directorio donde se encuentran los scripts de Python.
2. Ejecuta el script de preparación en el terminal:
```bash
   python3 embeddings.py
   ```
3. *Nota:* Este proceso descargará el modelo de embeddings (si es la primera vez que se ejecuta) y actualizará la base de datos local guardando las representaciones vectoriales en la tabla `reglamento_articulos`. Al finalizar, verás en consola el mensaje `"Embeddings generados correctamente"`.

---

## Paso 3: Configuración del LLM (Ollama)

El script `rag.py` utiliza el modelo **LLaMA 3** a través de la librería de Ollama para formular las respuestas. 

1. Abre una terminal y asegúrate de que el servicio de Ollama esté corriendo.
2. Descarga e inicializa el modelo ejecutando en otra terminal:
```bash
   ollama run llama3
   ```
3. Una vez que el modelo haya descargado e iniciado en la terminal, puedes salir de esa interfaz (usualmente con `/bye`). El servicio quedará corriendo en segundo plano y listo para ser consumido por Python.

---

## Paso 4: Ejecución del Sistema Principal

Una vez que la base de datos tiene los datos y los embeddings, y Ollama está listo, puedes iniciar el sistema interactivo.

Ejecuta el archivo principal:
```bash
python rag.py
```

### Uso del Menú Interactivo
El script desplegará un menú en la terminal con tres opciones:

1. **Preguntar reglamento:** Activa el flujo RAG. Puedes hacer preguntas en lenguaje natural (ej. *"¿Qué pasa si pierdo una materia teniendo la Beca Talento?"*). El sistema buscará vectorialmente los artículos más relevantes en PostgreSQL y generará una respuesta usando LLaMA 3.
2. **Consultar base de datos:** Ejecuta consultas SQL puras para validar el esquema. Permite ver estudiantes, materias, becas y docentes cargados previamente por `datos.sql`.
3. **Salir:** Cierra de manera segura la conexión con PostgreSQL y termina la ejecución del programa.
