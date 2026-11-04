# Proyecto Shell Scripting – Rocky Linux

## Descripción

Proyecto desarrollado en Bash para automatizar tareas de administración en Rocky Linux. Incluye herramientas para monitorear recursos del sistema, gestionar archivos, analizar información de servidores y programar tareas mediante Crontab.

## Requisitos

- Rocky Linux 9.
- Bash.
- Acceso a una terminal Linux.
- Permisos de ejecución.
- `crontab` y `flock` para el módulo de automatización.

## Instalación y ejecución

Clonar el repositorio y acceder al directorio:

```bash
git clone URL_DEL_REPOSITORIO
cd Proyecto_Shell
```

Dar permisos de ejecución:

```bash
chmod +x *.sh
```

## Módulos

### 1. Reporte del sistema (`reporte.sh`)

Genera un reporte con información del servidor, incluyendo sistema operativo, espacio del disco raíz, memoria RAM y porcentaje de utilización de CPU durante cinco segundos.

**Ejecución:**

```bash
./reporte.sh
```

El reporte se guarda automáticamente en `reportes/`, con la fecha y hora en el nombre del archivo.

### 2. Gestor de archivos (`gestor.sh`)

Permite administrar archivos y directorios mediante un menú interactivo.

Sus funcionalidades incluyen:

- Navegar entre directorios.
- Crear archivos.
- Copiar y pegar archivos.
- Modificar permisos mediante `chmod`.
- Eliminar archivos con confirmación.

**Ejecución:**

```bash
./gestor.sh
```

Seleccionar la operación deseada introduciendo el número correspondiente en el menú.

### 3. Análisis de servidores (`analisis.sh`)

Procesa la información almacenada en `datos/servidores.txt` para identificar servidores cuyo uso de disco supere el 70 %.

Utiliza AWK para analizar los datos y SED para modificar el texto de los resultados.

**Ejecución:**

Primero generar los datos:

```bash
./generar_datos.sh
```

Después ejecutar el análisis:

```bash
./analisis.sh
```

El resultado se guarda en `reportes/reporte_analisis.txt`.

### 4. Automatización de tareas (`automatizacion.sh`)

Permite programar la ejecución automática de otros scripts mediante Crontab.

Sus funcionalidades incluyen:

- Programar tareas por meses, días, horas y minutos.
- Consultar tareas programadas.
- Eliminar tareas.
- Ejecutar scripts manualmente.
- Guardar registros de ejecución.

**Ejecución:**

```bash
./automatizacion.sh
```

Seleccionar una opción del menú y, para programar una tarea, elegir el script e introducir el intervalo deseado.

Las configuraciones se almacenan en `.cron_mod4/` y los registros de ejecución en `logs/`.

## Estructura del proyecto

```text
Proyecto_Shell/
├── reporte.sh
├── gestor.sh
├── analisis.sh
├── automatizacion.sh
│
├── datos/
│   └── servidores.txt
├── reportes/
├── .cron_mod4/
└── logs/
```

Los directorios de reportes, configuraciones y registros se crean automáticamente cuando se ejecutan los módulos correspondientes.

## Autor

Proyecto académico de Shell Scripting desarrollado en Rocky Linux.
