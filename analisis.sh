#!/bin/bash

mkdir -p reportes

ENTRADA="datos/servidores.txt"
SALIDA="reportes/reporte_analisis.txt"

if [[ ! -f "$ENTRADA" ]]; then
    echo "Error: primero ejecuta generar_datos.sh"
    exit 1
fi

{
    echo "===== REPORTE DE ANALISIS ====="
    echo "Fecha: $(date '+%d/%m/%Y %H:%M:%S')"
    echo "Criterio: uso de disco mayor al 70%"
    echo ""
    printf "%-15s %-18s %s\n" "Nombre" "IP" "Disco"

    awk 'NR > 1 {
        uso = $3
        gsub(/%/, "", uso)

        if (uso > 70)
            printf "%-15s %-18s %s\n", $1, $2, $3
    }' "$ENTRADA" | sed 's/Servidor/Equipo/g'
	
} > "$SALIDA"

cat "$SALIDA"

echo ""
echo "Reporte guardado en: $(realpath "$SALIDA")"