## COPIA LOCAL DIARIA DEL CATALOGO DE TSM Universal ##

#!/bin/bash

# Definir variables

ORIGEN="/data/tsm/tsmFullBackup"
DESTINO="/home/mamarales/autom/catalogo"
fecha_actual=$(date +"%Y-%m-%d")


# Encontrar el archivo más reciente en el directorio de origen
lastfile=$(ls -t "$ORIGEN" | head -n 1)

# Verificar si se encontró un archivo
if [ -z "$lastfile" ]; then
    echo "No se encontró ningún archivo en '$ORIGEN'."
    exit 1
fi

# Copiar el archivo más reciente al directorio de destino
cp "$ORIGEN/$lastfile" "$DESTINO"

# Verificar si la copia fue exitosa
if [ $? -eq 0 ]; then
    echo "Se ha copiado '$lastfile' a '$DESTINO'."
else
    echo "Hubo un error al copiar el archivo."
    exit 1
fi

echo "Comprimiendo archivo"
gzip "$DESTINO/$lastfile" -c > "$DESTINO/idretail_$fecha_actual.gz"

sleep 10

echo "Eliminando archivo copiado y conservando comprimido"
rm -f "$DESTINO/$lastfile"

echo "Terminado"




