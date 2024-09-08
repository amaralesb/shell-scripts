#!/bin/bash

# Este script está diseñado para ejecutar la migración manual en TSM.
# Evalua las siguientes condiciones. 1.Que no exista otro proceso en ejecucion 2. Que no existan requisitos antes de la migracion.
# Envia toda la informacion del proceso al log de manera estructurada para luego agendar en SSI.
# Se puede ejecutar en el shell del usuario donde imprime en pantalla progreso cada 3 minutos.
# Se puede agendar para ejecutar de manera programada con Cron.
# Queda pendiente el envio automatico de alguna notificacion a correo u otro medio.
# Solo defina las variables, evite modificar el script. 

############################################################
# Definir variables
ID="maykel.amarales"
PASSWORD="tsmmaykel"
LOG_DIR="/home/mamarales/autom/logs"
CURRENT_LOG="$LOG_DIR/$(hostname)_$(date +%Y-%m-%d).log"
STG="DKDB"
##########################################################



###############################
# Definir flag
FLAG_PROCESO_EN_EJECUCION=0

# Procedimiento para verificar si hay procesos en ejecución
verificar_procesos_en_ejecucion() {
    # Ejecutar el comando para verificar procesos activos
    PROCESO_ACTIVO=$(dsmadmc -id=$ID -password=$PASSWORD q pro | sed 's/ \+/|/g' | awk -F '|' 'NR==11 {print $2}')

    # Si el resultado es "Process", activar la flag
    if [[ "$PROCESO_ACTIVO" == "Process" ]]; then
        echo -e "\e[1;31m Hay otros procesos en ejecución  \e[0m"
        FLAG_PROCESO_EN_EJECUCION=1
    fi
}

# Llamar al procedimiento para verificar si hay procesos en ejecución
verificar_procesos_en_ejecucion

# Verificar  flag y decidir si detener el script
if [[ "$FLAG_PROCESO_EN_EJECUCION" -eq 1 ]]; then
    exit 0  # Detener la ejecución del script sin error
fi

# Continuar con el script si no hay otros procesos en ejecución
echo "-----------------------------------------"
echo "    SCRIPT PARA MIGRAR DATOS EN TSM      "
echo "-----------------------------------------"
echo "No existen otros procesos en ejecución."
echo "No hay requisitos previos a la migración."
echo ""
echo "Continuando..."
sleep 3

# Procedimiento para ejecutar comandos iniciales y guardar la salida en el log
ejecutar_comandos_iniciales() {
    {
        echo ""
        echo "INICIANDO PROCESO DE MIGRACIÓN DIARIA - $(date)."
        echo "======================================================================="
        echo ""
        
        # Comando para obtener el volumen montado
        MOUNT_OUTPUT=$(dsmadmc -id=$ID -password=$PASSWORD q mount)
        echo "Comprobando si está montado el volumen."
        echo "======================================="
        echo "$MOUNT_OUTPUT"
        
        # Extraer el nombre del Volume montado
        VOLUME=$(echo "$MOUNT_OUTPUT" | grep -oP 'LTO volume \K\w+')
        echo ""
        echo "Volumen montado: $VOLUME"
        echo ""
        echo ""

        # Comprobar Storage pools
        STG_OUTPUT=$(dsmadmc -id=$ID -password=$PASSWORD q stg)
        echo "Comprobando Storage Pools."
        echo "=========================="
        echo "$STG_OUTPUT"
        echo ""
        echo ""

        # Comprobar Volumenes        
        VOL_OUTPUT=$(dsmadmc -id=$ID -password=$PASSWORD q v) 
        echo "Comprobando Volúmenes."
        echo "======================="
        echo "$VOL_OUTPUT"
        echo ""
        echo ""

        # Verificar Procesos
        PRO_OUTPUT=$(dsmadmc -id=$ID -password=$PASSWORD q pro) 
        echo "Comprobando que no existan otros procesos en ejecución."
        echo "======================================================="
        echo "$PRO_OUTPUT"
        echo ""
        echo ""

        # Verificar Requisitos
        REQ_OUTPUT=$(dsmadmc -id=$ID -password=$PASSWORD q pro)
        echo "Comprobando requisitos previos a la migración."
        echo "=============================================="
        echo "$REQ_OUTPUT"
        echo ""
        echo ""

    } >> "$CURRENT_LOG" 2>&1
}

# Procedimiento para iniciar la migración
iniciar_migracion() {
    echo ""
    echo "*** INICIANDO MIGRACIÓN ***"
    sleep 3
    echo " " 
    echo "*** Migrando datos desde $STG a $VOLUME ***"
    sleep 3
    echo "......MIGRANDO......" >> "$CURRENT_LOG" 2>&1
    echo "====================" >> "$CURRENT_LOG" 2>&1
    dsmadmc -id=$ID -password=$PASSWORD migrate stgpool $STG lowmig=0 >> "$CURRENT_LOG" 2>&1
}

# Procedimiento para mostrar resultados de la migración
mostrar_resultados() {

    clear  # Limpiar la pantalla antes de mostrar los resultados
    echo "$(date)"
    echo "----------------------------------"
    echo "ID del proceso"
    dsmadmc -id=$ID -password=$PASSWORD q pro | sed 's/ \+/|/g' | awk -F '|' 'NR==14 {print $2}'  # Muestra número de proceso en el sistema
    echo " "    
    echo -e "\e[1;33mStorage Pool a migrar \e[0m" # Muestra el Storage pool
    dsmadmc -id=$ID -password=$PASSWORD q stg $STG f=d | grep $STG | sed 's/ \+/|/g' | awk -F '|' 'NR==2 {print $1, $5, $6}'
    echo -e "\e[1;33mPorciento a migrar \e[0m" # Muestra el % a migrar desde Storage pool
    dsmadmc -id=$ID -password=$PASSWORD q stg $STG f=d | grep $STG | sed 's/ \+/|/g' | awk -F '|' 'NR==2 {print $8}'
    echo " "
    echo -e "\e[1;32mVolumen en uso: $VOLUME \e[0m" # Muestra el volumen actual montado para recibir la migracion 
    dsmadmc -id=$ID -password=$PASSWORD q v $VOLUME f=d | grep $VOLUME | sed 's/ \+/|/g' | awk -F '|' 'NR==2 {print $4, $5}'
    dsmadmc -id=$ID -password=$PASSWORD q v $VOLUME f=d | grep $VOLUME | sed 's/ \+/|/g' | awk -F '|' 'NR==2 {print $7, $8}'
    echo "----------------------------------"
    echo "Total de archivos movidos"
    dsmadmc -id=$ID -password=$PASSWORD q pro | sed 's/ \+/|/g' | awk -F '|' 'NR==14 {print $10}' # Muestra archivos movidos
    echo "Bytes movidos"
    dsmadmc -id=$ID -password=$PASSWORD q pro | sed 's/ \+/|/g' | awk -F '|' 'NR==15 {print $3, $4}' # Muestra Bytes movidos
    echo -e "\e[1;32m % ocupado en $VOLUME \e[0m"
    dsmadmc -id=$ID -password=$PASSWORD q v $VOLUME f=d | grep $VOLUME | sed 's/ \+/|/g' | awk -F '|' 'NR==2 {print $6}'
    echo "----------------------------------"
	
}

# Procedimiento principal para ejecutar el ciclo de monitoreo
monitorear_migracion() {
    while true; do
        # Ejecutar el comando y enviar su salida solo al log
        dsmadmc -id=$ID -password=$PASSWORD q pro >> "$CURRENT_LOG" 2>&1   # "q pro" al log cada ves q haga el ciclo
        echo "Porciento a migrar desde $STG " >> "$CURRENT_LOG" 2>&1  # Escribe en el log % del storage a migrar
        dsmadmc -id=$ID -password=$PASSWORD q stg $STG f=d | grep $STG | sed 's/ \+/|/g' | awk -F '|' 'NR==2 {print $8}' >> "$CURRENT_LOG" 2>&1
	echo "Porciento ocupado en CINTA: $VOLUME *** " >> "$CURRENT_LOG" 2>&1  # Escribe en el log espacio ocupado en cinta
        dsmadmc -id=$ID -password=$PASSWORD q v $VOLUME f=d | grep $VOLUME | sed 's/ \+/|/g' | awk -F '|' 'NR==2 {print $6}' >> "$CURRENT_LOG" 2>&1
        echo "======================================================================================="
        echo "============================== PROGRESO DE LA MIGRACIÓN ==============================="        

        # Mostrar los resultados
        mostrar_resultados

        # Verificar si el proceso ha finalizado
        ESTADO_PROCESO=$(dsmadmc -id=$ID -password=$PASSWORD q pro | sed 's/ \+/|/g' | awk -F '|' 'NR==11 {print $2}')
        if [[ "$ESTADO_PROCESO" == "Return" ]]; then
            # Mostrar los resultados finales y redirigir al log
            ### mostrar_resultados | tee -a "$CURRENT_LOG"
            echo  "MIGRACIÓN FINALIZADA " | tee -a "$CURRENT_LOG"
            break  # Salir del ciclo y detener el script
        fi

        # Esperar 180 segundos antes de la siguiente iteración
        sleep 300
    done
}

# Llamada a los procedimientos principales
ejecutar_comandos_iniciales
iniciar_migracion
mostrar_resultados
monitorear_migracion

