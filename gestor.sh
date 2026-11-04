#!/usr/bin/env bash
# Gestor de archivos interactivo - Rocky Linux

# El directorio inicial es el directorio donde se encuentra el script.
BASE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)" || exit 1
cd -- "$BASE" || exit 1
PORTAPAPELES=""

listar() {
    echo ""
    echo "Contenido de: $PWD"
    ls -CF --color=auto
}

navegar() {
    local opcion ruta
    while true; do
        echo ""
        echo "===== NAVEGAR ====="
        echo "Directorio: $PWD"
        echo "1. Listar archivos y carpetas"
        echo "2. Entrar a una carpeta o ruta"
        echo "3. Subir un nivel"
        echo "4. Volver al menu principal"
        read -r -p "Opcion: " opcion || return
        case "$opcion" in
            1) listar ;;
            2)
                listar
                read -r -p "Carpeta o ruta (admite /ruta, .., ~): " ruta || return
                [[ -n "$ruta" ]] || { echo "Ruta vacia."; continue; }
                if [[ "$ruta" == "~" ]]; then ruta="$HOME";
                elif [[ "$ruta" == ~/* ]]; then ruta="$HOME/${ruta#~/}"; fi
                if [[ -d "$ruta" ]]; then
                    cd -- "$ruta" || echo "No se pudo entrar."
                else
                    echo "La carpeta no existe o no es accesible."
                fi
                ;;
            3) cd .. || echo "No se pudo subir." ;;
            4) return ;;
            *) echo "Opcion incorrecta." ;;
        esac
    done
}

nombre_valido() {
    [[ -n "$1" && "$1" != '.' && "$1" != '..' && "$1" != */* ]]
}

crear() {
    local nombre
    listar
    read -r -p "Nombre del nuevo archivo: " nombre || return
    if ! nombre_valido "$nombre"; then
        echo "Nombre invalido (sin barras)."
    elif [[ -e "$nombre" || -L "$nombre" ]]; then
        echo "Ya existe un archivo o carpeta con ese nombre."
    elif touch -- "$nombre"; then
        echo "Creado: $PWD/$nombre"
    else
        echo "No se pudo crear el archivo."
    fi
}

copiar() {
    local nombre origen
    listar
    read -r -p "Archivo a copiar (nombre o ruta): " nombre || return
    if [[ ! -f "$nombre" || -L "$nombre" ]]; then
        echo "Selecciona un archivo regular existente (no enlace simbolico)."
        return
    fi
    origen="$(realpath -e -- "$nombre")" || { echo "Ruta invalida."; return; }
    [[ -r "$origen" ]] || { echo "No se puede leer el archivo."; return; }
    PORTAPAPELES="$origen"
    echo "Copiado al portapapeles: $PORTAPAPELES"
    echo "Navega a otra carpeta y elige Pegar."
}

pegar() {
    local destino respuesta nombre
    if [[ -z "$PORTAPAPELES" ]]; then
        echo "Primero selecciona un archivo con la opcion Copiar."
        return
    fi
    if [[ ! -f "$PORTAPAPELES" || ! -r "$PORTAPAPELES" ]]; then
        echo "El archivo de origen ya no existe o no se puede leer."
        PORTAPAPELES=""
        return
    fi
    echo "Origen: $PORTAPAPELES"
    echo "Destino: $PWD"
    listar
    nombre="$(basename -- "$PORTAPAPELES")"
    read -r -p "Nombre para pegar [$nombre]: " respuesta || return
    [[ -n "$respuesta" ]] && nombre="$respuesta"
    if ! nombre_valido "$nombre"; then
        echo "Nombre invalido."
        return
    fi
    destino="$PWD/$nombre"
    if [[ -e "$destino" || -L "$destino" ]]; then
        echo "El destino ya existe. No se sobrescribio."
    elif cp --no-clobber -- "$PORTAPAPELES" "$destino" && [[ -f "$destino" ]]; then
        echo "Archivo pegado: $destino"
    else
        echo "No se pudo pegar el archivo."
    fi
}


permisos() {
    local nombre modo

    listar

    read -r -p "Archivo para cambiar permisos: " nombre || return

    if [[ ! -f "$nombre" || -L "$nombre" ]]; then
        echo "Archivo no valido o inexistente."
        return
    fi

    echo ""
    echo "===== GUIA DE PERMISOS chmod ====="
    echo "0 = Sin permisos"
    echo "1 = Ejecucion"
    echo "2 = Escritura"
    echo "3 = Escritura + ejecucion"
    echo "4 = Lectura"
    echo "5 = Lectura + ejecucion"
    echo "6 = Lectura + escritura"
    echo "7 = Lectura + escritura + ejecucion"
    echo ""
    echo "Orden de los numeros:"
    echo "Primer numero  : Propietario"
    echo "Segundo numero : Grupo"
    echo "Tercer numero  : Otros"
    echo ""
    echo "Ejemplo: 644"
    echo "6 = Propietario: lectura y escritura"
    echo "4 = Grupo: lectura"
    echo "4 = Otros: lectura"
    echo ""

    read -r -p "Introduce los permisos: " modo || return

    if [[ ! "$modo" =~ ^[0-7]{3,4}$ ]]; then
        echo "Formato de permisos invalido."
        return
    fi

    if chmod "$modo" -- "$nombre"; then
        echo "Permisos actualizados:"
        ls -l -- "$nombre"
    else
        echo "No se pudieron cambiar los permisos."
    fi
}


eliminar() {
    local nombre respuesta
    listar
    read -r -p "Archivo a eliminar (nombre o ruta): " nombre || return
    if [[ ! -f "$nombre" || -L "$nombre" ]]; then
        echo "Solo se pueden eliminar archivos regulares, no carpetas ni enlaces."
        return
    fi
    echo "Se eliminara: $(realpath -e -- "$nombre")"
    read -r -p "Confirmar eliminacion (s/n): " respuesta || return
    if [[ "$respuesta" == 's' || "$respuesta" == 'S' ]]; then
        rm -- "$nombre" && echo "Archivo eliminado." || echo "No se pudo eliminar."
    else
        echo "Operacion cancelada."
    fi
}

while true; do
    echo ""
    echo "===== GESTOR DE ARCHIVOS ====="
    echo "Directorio actual: $PWD"
    if [[ -n "$PORTAPAPELES" ]]; then
        echo "Archivo copiado: $PORTAPAPELES"
    fi
    echo "1. Navegar"
    echo "2. Crear archivo"
    echo "3. Copiar archivo"
    echo "4. Pegar archivo"
    echo "5. Cambiar permisos"
    echo "6. Eliminar archivo"
    echo "7. Salir"
    read -r -p "Selecciona una opcion: " opcion || break
    case "$opcion" in
        1) navegar ;;
        2) crear ;;
        3) copiar ;;
        4) pegar ;;
        5) permisos ;;
        6) eliminar ;;
        7) echo "Saliendo..."; break ;;
        *) echo "Opcion incorrecta." ;;
    esac
done
