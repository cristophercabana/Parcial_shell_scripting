#!/bin/bash

BASE="$(cd "$(dirname "$0")" && pwd)"
FECHA=$(date '+%Y-%m-%d_%H-%M-%S')
REPORTE="$BASE/reportes/reporte_sistema_$FECHA.txt"

mkdir -p "$BASE/reportes"

# Medir uso de CPU durante un segundo
read -r _ u n s i w irq sirq steal _ < /proc/stat
total1=$((u+n+s+i+w+irq+sirq+steal))
idle1=$((i+w))

sleep 5

read -r _ u n s i w irq sirq steal _ < /proc/stat
total2=$((u+n+s+i+w+irq+sirq+steal))
idle2=$((i+w))

delta=$((total2-total1))
idle=$((idle2-idle1))

if (( delta > 0 )); then
    cpu=$((100*(delta-idle)/delta))
else
    cpu=0
fi
{
    echo "===== REPORTE DEL SISTEMA ====="
    echo "Fecha y hora: $(date '+%Y-%m-%d %H:%M:%S')"

    echo ""
    echo "SISTEMA OPERATIVO:"
    grep '^PRETTY_NAME=' /etc/os-release

    echo ""
    echo "DISCO RAIZ:"
    df -h /

    echo ""
    echo "MEMORIA RAM:"
    free -h

    echo ""
    echo "USO DE CPU:"
    echo "CPU utilizada: ${cpu}%"

} > "$REPORTE"

echo "Reporte guardado en: $REPORTE"
