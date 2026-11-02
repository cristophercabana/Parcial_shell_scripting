#!/bin/bash
# Modulo 4 - Programacion de tareas con crontab
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ESTADO="$BASE/.cron_mod4"
LOGS="$BASE/logs"
MARCA='PROYECTO_SHELL_MOD4'
mkdir -p "$ESTADO" "$LOGS"

# Suma meses de calendario (ajustando el dia al ultimo dia del mes destino),
# despues dias, horas y minutos. Recibe fecha Unix en segundos.
siguiente_fecha() {
    local inicio=$1 meses=$2 dias=$3 horas=$4 minutos=$5
    local anio mes dia destino_anio destino_mes ultimo base
    if (( meses > 0 )); then
        read -r anio mes dia < <(date -d "@$inicio" '+%Y %-m %-d')
        local indice=$((anio * 12 + mes - 1 + meses))
        destino_anio=$((indice / 12))
        destino_mes=$((indice % 12 + 1))
        ultimo=$(date -d "${destino_anio}-$(printf '%02d' "$destino_mes")-01 +1 month -1 day" '+%-d')
        (( dia > ultimo )) && dia=$ultimo
        base=$(date -d "$(printf '%04d-%02d-%02d' "$destino_anio" "$destino_mes" "$dia") $(date -d "@$inicio" '+%H:%M:%S')" '+%s') || return 1
    else
        base=$inicio
    fi
    echo $((base + dias * 86400 + horas * 3600 + minutos * 60))
}

# Invocado por cron cada minuto. El bloqueo evita ejecuciones simultaneas.
ejecutar_programada() {
    local id=$1 config="$ESTADO/$1.conf" bloqueo="$ESTADO/$1.lock"
    [[ "$id" =~ ^[0-9]+$ && -f "$config" ]] || exit 0
    exec 9>"$bloqueo"
    flock -n 9 || exit 0
    local script meses dias horas minutos proxima ahora nueva
    IFS='|' read -r script meses dias horas minutos proxima < "$config"
    [[ -f "$script" && "$proxima" =~ ^[0-9]+$ ]] || exit 1
    ahora=$(date +%s)
    (( ahora >= proxima )) || exit 0
    # Avanzar el proximo vencimiento antes de ejecutar, para evitar duplicados.
    nueva=$(siguiente_fecha "$proxima" "$meses" "$dias" "$horas" "$minutos") || exit 1
    while (( nueva <= ahora )); do
        nueva=$(siguiente_fecha "$nueva" "$meses" "$dias" "$horas" "$minutos") || exit 1
    done
    printf '%s|%s|%s|%s|%s|%s\n' "$script" "$meses" "$dias" "$horas" "$minutos" "$nueva" > "$config"
    (cd "$BASE" && /bin/bash "$script") >> "$LOGS/$(basename "${script%.sh}")_$id.log" 2>&1
}

if [[ "${1:-}" == '--run' ]]; then
    ejecutar_programada "${2:-}"
    exit
fi

listar_scripts() {
    SCRIPTS=()
    local archivo i
    for archivo in "$BASE"/*.sh; do
        [[ -f "$archivo" ]] || continue
        [[ "$(basename "$archivo")" == 'automatizacion.sh' ]] && continue
        SCRIPTS+=("$archivo")
    done
    (( ${#SCRIPTS[@]} )) || { echo 'No hay otros scripts .sh.'; return 1; }
    for i in "${!SCRIPTS[@]}"; do
        printf '%d. %s\n' "$((i+1))" "$(basename "${SCRIPTS[i]}")"
    done
}

seleccionar_script() {
    listar_scripts || return 1
    local numero
    read -r -p 'Numero del script: ' numero
    [[ "$numero" =~ ^[0-9]+$ ]] || { echo 'Seleccion invalida.'; return 1; }
    numero=$((10#$numero))
    (( numero >= 1 && numero <= ${#SCRIPTS[@]} )) || { echo 'Seleccion invalida.'; return 1; }
    ELEGIDO="${SCRIPTS[numero-1]}"
}

pedir_intervalo() {
    local etiqueta=$1 max=$2 entrada
    read -r -p "Cada cuantos $etiqueta (0-$max): " entrada
    [[ "$entrada" =~ ^[0-9]+$ ]] || return 1
    entrada=$((10#$entrada))
    (( entrada <= max )) || return 1
    VALOR=$entrada
}

programar() {
    seleccionar_script || return
    local meses dias horas minutos respuesta id proxima linea actual
    pedir_intervalo 'meses' 120 || { echo 'Meses invalidos.'; return; }; meses=$VALOR
    pedir_intervalo 'dias' 365 || { echo 'Dias invalidos.'; return; }; dias=$VALOR
    pedir_intervalo 'horas' 999 || { echo 'Horas invalidas.'; return; }; horas=$VALOR
    pedir_intervalo 'minutos' 99999 || { echo 'Minutos invalidos.'; return; }; minutos=$VALOR
    (( meses + dias + horas + minutos > 0 )) || { echo 'El intervalo no puede ser cero.'; return; }
    echo "Frecuencia: cada $meses mes(es), $dias dia(s), $horas hora(s), $minutos minuto(s)."
    read -r -p 'Confirmar programacion (s/n): ' respuesta
    [[ "$respuesta" == [sS] ]] || { echo 'Cancelado.'; return; }
    id=$(date +%s%N)
    proxima=$(siguiente_fecha "$(date +%s)" "$meses" "$dias" "$horas" "$minutos") || return
    printf '%s|%s|%s|%s|%s|%s\n' "$ELEGIDO" "$meses" "$dias" "$horas" "$minutos" "$proxima" > "$ESTADO/$id.conf"
    # Se comprueba cada minuto; solo ejecuta al alcanzar el intervalo.
    linea="* * * * * /bin/bash \"$BASE/automatizacion.sh\" --run $id # $MARCA:$id"
    actual=$(crontab -l 2>/dev/null || true)
    if { [[ -z "$actual" ]] || printf '%s\n' "$actual"; printf '%s\n' "$linea"; } | crontab -; then
        echo "Tarea programada. Primera ejecucion aproximada: $(date -d "@$proxima" '+%d/%m/%Y %H:%M')"
    else
        rm -f -- "$ESTADO/$id.conf"
        echo 'No se pudo guardar en crontab.'
    fi
}

ver_tareas() {
    local -a tareas
    local linea i=0

    mapfile -t tareas < <(crontab -l 2>/dev/null || true)

    echo "===== TODAS LAS TAREAS PROGRAMADAS ====="

    for linea in "${tareas[@]}"; do
        [[ -z "${linea//[[:space:]]/}" ]] && continue
        [[ "$linea" =~ ^[[:space:]]*# ]] && continue

        ((i+=1))
        printf '%d. %s\n' "$i" "$linea"
    done

    (( i == 0 )) && echo "No hay tareas programadas."
}


eliminar_tarea() {
    local -a lineas indices restantes
    local indice numero borrar respuesta i=0

    mapfile -t lineas < <(crontab -l 2>/dev/null || true)

    echo "===== ELIMINAR TAREAS ====="

    for indice in "${!lineas[@]}"; do
        [[ -z "${lineas[$indice]//[[:space:]]/}" ]] && continue
        [[ "${lineas[$indice]}" =~ ^[[:space:]]*# ]] && continue

        ((i+=1))
        indices+=("$indice")
        printf '%d. %s\n' "$i" "${lineas[$indice]}"
    done

    if (( i == 0 )); then
        echo "No hay tareas programadas."
        return
    fi

    echo ""
    echo "A. Eliminar TODAS las tareas"
    echo "0. Cancelar"

    read -r -p "Selecciona una opcion: " numero

    if [[ "$numero" == "0" ]]; then
        return
    fi

    if [[ "$numero" == "A" || "$numero" == "a" ]]; then
        read -r -p "¿Eliminar TODAS las tareas? (s/n): " respuesta

        [[ "$respuesta" =~ ^[sS]$ ]] || {
            echo "Operacion cancelada."
            return
        }

        if crontab -r; then
            echo "Todas las tareas eliminadas."
        else
            echo "Error al eliminar tareas."
        fi
        return
    fi

    if [[ ! "$numero" =~ ^[0-9]+$ ]]; then
        echo "Seleccion invalida."
        return
    fi

    numero=$((10#$numero))

    if (( numero < 1 || numero > i )); then
        echo "Seleccion invalida."
        return
    fi

    borrar="${indices[$((numero-1))]}"

    echo "Se eliminara: ${lineas[$borrar]}"
    read -r -p "¿Confirmar eliminacion? (s/n): " respuesta

    [[ "$respuesta" =~ ^[sS]$ ]] || {
        echo "Operacion cancelada."
        return
    }

    restantes=()

    for indice in "${!lineas[@]}"; do
        if [[ "$indice" != "$borrar" ]]; then
            restantes+=("${lineas[$indice]}")
        fi
    done

    if (( ${#restantes[@]} == 0 )); then
        if crontab -r; then
            echo "Tarea eliminada correctamente."
        else
            echo "Error al eliminar tarea."
        fi
    else
        if printf '%s\n' "${restantes[@]}" | crontab -; then
            echo "Tarea eliminada correctamente."
        else
            echo "Error al actualizar crontab."
        fi
    fi
}

ejecutar_ahora() {
    seleccionar_script || return
    echo "Ejecutando $(basename "$ELEGIDO")..."
    (cd "$BASE" && /bin/bash "$ELEGIDO")
}

while true; do
    echo ''
    echo '===== AUTOMATIZACION DE TAREAS ====='
    echo '1. Programar una tarea'
    echo '2. Ver tareas programadas'
    echo '3. Eliminar una tarea programada'
    echo '4. Ejecutar un script ahora'
    echo '5. Salir'
    read -r -p 'Opcion: ' opcion
    case "$opcion" in
        1) programar ;;
        2) ver_tareas ;;
        3) eliminar_tarea ;;
        4) ejecutar_ahora ;;
        5) echo 'Saliendo...'; break ;;
        *) echo 'Opcion incorrecta.' ;;
    esac
done
