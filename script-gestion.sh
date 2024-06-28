#!/bin/bash
clear

aniadir_usuario() { 
    read -p "Introduce el nombre de usuario: " usuario
    read -s -p "Introduce la contrasenia: " contrasenia
    echo
    read -p "Introduce el grupo de este usuario: " grupo
    
    if id "$usuario" >/dev/null 2>&1; then
        clear
        echo "Error: Este usuario ya existe."
        echo "EAU , $(date +"%T") , $usuario , $grupo , Razón : El usuario ya existe." >> Gestion_usuario.log
        echo "==========================================" >> Gestion_usuario.log
        echo "Pulsa una tecla para continuar."
        read -n 1 -s
        clear
        inicio
        return
    fi

    if grep "^$grupo:" /etc/group >/dev/null ; then
        sudo useradd -m -g "$grupo" -d "/home/$usuario" "$usuario"
        echo "$usuario:$contrasenia" | sudo chpasswd
        echo "Usuario: $usuario , Grupo: $grupo ." >> usuarios.txt
        echo "$usuario $grupo" >> eliminar_grupo.txt
        echo "AU , $(date +"%T") , $usuario , $grupo" >> Gestion_usuario.log
        echo "==========================================" >> Gestion_usuario.log
        clear
        echo "Usuario aniadido con éxito."
        echo "Pulsa una tecla para continuar."
        read -n 1 -s
        clear
        inicio
    else
        clear
        echo "Error: No hay un grupo con el nombre $grupo."
        echo "EAU , $(date +"%T") , $usuario , $grupo , Razón : No hay un grupo con el nombre $grupo." >> Gestion_usuario.log
        echo "==========================================" >> Gestion_usuario.log
        read -p "¿Quieres crear un grupo? S/N: " eleccion
        eleccion=$(echo "$eleccion" | tr '[:upper:]' '[:lower:]')
        if [ "$eleccion" == "s" ]; then 
            clear
            crear_grupo
        else
            clear
            inicio
        fi
    fi 
}

crear_grupo() {
    read -p "Indica el nombre del grupo a crear: " grupo1
    if grep "^$grupo1:" /etc/group >/dev/null ; then
        clear
        echo "Error: Este grupo ya existe."
        echo "EAG , $(date +"%T") , $grupo1 , Razón : Este grupo ya existe." >> Gestion_usuario.log
        echo "===========================================" >> Gestion_usuario.log
        echo "Pulsa una tecla para continuar."
        read -n 1 -s
        clear
        inicio
    else
        clear
        sudo groupadd "$grupo1"
        echo "AG , $(date +"%T") , $grupo1" >> Gestion_usuario.log
        echo "============================================" >> Gestion_usuario.log
        echo "¡Grupo aniadido con éxito!"
        echo "Pulsa una tecla para continuar."
        read -n 1 -s
        clear
        inicio
    fi
}

listar_usuarios(){
    if [ ! -s usuarios.txt ]; then
        clear
        echo "Error: La lista está vacía, no hay usuarios."
        read -p "¿Quieres aniadir un usuario? S/N: " eleccion
        eleccion=$(echo "$eleccion" | tr '[:upper:]' '[:lower:]')
        if [ "$eleccion" == "s" ] ; then
            clear
            aniadir_usuario
        else
            clear
            inicio
        fi
    else
        clear
        echo "Aquí está la lista de usuarios:"
        cat usuarios.txt
        echo "Pulsa una tecla para continuar."
        read -n 1 -s
        clear
        inicio
    fi	      
}

eliminar_usuario(){
    read -p "Introduce el nombre de usuario a eliminar: " usuario_eliminar
    if id "$usuario_eliminar" >/dev/null 2>&1; then
        sudo userdel -f -r "$usuario_eliminar"
        clear
        echo "Usuario eliminado con éxito."
        echo "DU , $(date +"%T") , $usuario_eliminar" >> Gestion_usuario.log
        echo "============================================" >> Gestion_usuario.log
        sed -i "/$usuario_eliminar/d" usuarios.txt
        sed -i "/$usuario_eliminar/d" eliminar_grupo.txt
        echo "Pulsa una tecla para continuar."
        read -n 1 -s
        clear
        inicio
    else
        clear
        echo "Error: Este usuario no existe."
        echo "EDU , $(date +"%T") , $usuario_eliminar , Razón : El usuario no existe." >> Gestion_usuario.log
        echo "============================================" >> Gestion_usuario.log
        echo "Pulsa una tecla para continuar."
        read -n 1 -s
        inicio
    fi
}

eliminar_grupo_usuario(){
    read -p "Introduce el nombre del grupo a eliminar: " grupo_eliminar
    if grep "^$grupo_eliminar:" /etc/group >/dev/null ; then
        sudo groupdel "$grupo_eliminar"
        echo "DG , $(date +"%T") , $grupo_eliminar" >> Gestion_usuario.log
        echo "============================================" >> Gestion_usuario.log
        while IFS='' read -r linea ; do
            usuario=$(echo "$linea" | awk '{print $1}')
            grupo=$(echo "$linea" | awk '{print $2}')
            if [ "$grupo" == "$grupo_eliminar" ]; then
                sudo userdel -f -r "$usuario"
                echo "DU , $(date +"%T") , $usuario , $grupo_eliminar" >> Gestion_usuario.log
                echo "============================================" >> Gestion_usuario.log
                sed -i "/$usuario/d" usuarios.txt
                sed -i "/$usuario/d" eliminar_grupo.txt
            fi
        done < eliminar_grupo.txt
        clear
        echo "Grupo y sus usuarios eliminados con éxito."
        echo "Pulsa una tecla para continuar."
        read -n 1 -s
        clear
        inicio
    else
        clear
        echo "Error: Este grupo no existe."
        echo "EDG , $(date +"%T") , $grupo_eliminar , Razón : Grupo no existe." >> Gestion_usuario.log
        echo "============================================" >> Gestion_usuario.log
        echo "Pulsa una tecla para continuar."
        read -n 1 -s
        clear
        inicio
    fi
}

aniadir_usuarios_csv(){
    clear
    read -p "Introduce la ruta del archivo CSV que contiene la información de los usuarios: " ruta
    if [[ ! -e "$ruta" ]]; then
        clear
        echo "No hay un archivo con el nombre '$ruta', verifica tu ruta."
        echo "EF , $(date +"%T") , $ruta , Razón : No hay un archivo CSV con el nombre '$ruta'." >> Gestion_usuario.log
        echo "===========================================" >> Gestion_usuario.log
        echo "Pulsa una tecla para continuar."
        read -n 1 -s
        inicio
        return
    fi

    clear
    while IFS=',' read -r usuario1 contrasenia1 grupo1; do
        if id "$usuario1" >/dev/null 2>&1; then
            echo "El usuario '$usuario1' ya existe."
            echo "EAU , $(date +"%T") , $usuario1 , $grupo1 , Razón : El usuario ya existe." >> Gestion_usuario.log
            echo "===========================================" >> Gestion_usuario.log
            continue
        fi

        if grep "^$grupo1:" /etc/group >/dev/null ; then
            sudo useradd -m -g "$grupo1" -d "/home/$usuario1" "$usuario1"
            echo "$usuario1:$contrasenia1" | sudo chpasswd
            echo "AU , $(date +"%T") , $usuario1 , $grupo1" >> Gestion_usuario.log
            echo "===========================================" >> Gestion_usuario.log
            echo "Usuario: $usuario1 , Grupo: $grupo1 ." >> usuarios.txt
            echo "$usuario1 $grupo1" >> eliminar_grupo.txt
        else
            echo "El grupo '$grupo1' donde deseas aniadir el usuario '$usuario1' no existe."
            echo "EAG , $(date +"%T") , $grupo1 , Razón : El grupo no existe." >> Gestion_usuario.log
            echo "===========================================" >> Gestion_usuario.log
        fi
    done < "$ruta"
    clear
    echo "Todos los usuarios del archivo CSV se han aniadido con éxito."
    echo "Pulsa una tecla para continuar."
    read -n 1 -s
    clear
    inicio
}

eliminar_usuarios_csv(){
    clear
    read -p "Introduce la ruta del archivo CSV que contiene la información de los usuarios: " ruta2
    if [[ ! -e "$ruta2" ]]; then
        clear
        echo "No hay un archivo con el nombre '$ruta2', verifica tu ruta."
        echo "EF , $(date +"%T") , $ruta2 , Razón : No hay un archivo CSV con el nombre '$ruta2'." >> Gestion_usuario.log
        echo "===========================================" >> Gestion_usuario.log
        echo "Pulsa una tecla para continuar."
        read -n 1 -s
        clear
        inicio
        return
    fi

    clear
    while IFS=',' read -r usuario2 grupo2; do
        if id "$usuario2" >/dev/null 2>&1; then
            sudo userdel -f -r "$usuario2"
            echo "DU , $(date +"%T") , $usuario2 , $grupo2" >> Gestion_usuario.log
            echo "============================================" >> Gestion_usuario.log
            sed -i "/$usuario2/d" usuarios.txt
            sed -i "/$usuario2/d" eliminar_grupo.txt
            echo "El usuario '$usuario2' ha sido eliminado con éxito."
        else
            echo "El usuario '$usuario2' no existe."
            echo "EDU , $(date +"%T") , $usuario2 , $grupo2 Razón : El usuario '$usuario2' no existe." >> Gestion_usuario.log
            echo "============================================" >> Gestion_usuario.log
        fi
    done < "$ruta2"
    echo "Pulsa una tecla para continuar."
    read -n 1 -s
    clear
    inicio
}

inicio(){
clear
     echo "Bienvenido a la gestión de usuarios y grupos"
     echo
     echo "1. Para añadir un usuario"
     echo "2. Para añadir usuarios desde un archivo CSV."
     echo "3. Para crear un grupo"
     echo "4. Listar usuarios y grupos"
     echo "5. Eliminar un usuario"
     echo "6. Eliminar un grupo y sus usuarios"
     echo "7. Eliminar usuarios desde un archivo CSV"
     echo "0. Salir"
     read -p "Elige una opción: " eleccion

            case "$eleccion" in
                1) clear; aniadir_usuario ;;
                2) clear; aniadir_usuarios_csv ;;
                3) clear; crear_grupo ;;
                4) clear; listar_usuarios ;;
                5) clear; eliminar_usuario ;;
                6) clear; eliminar_grupo_usuario ;;
                7) clear; eliminar_usuarios_csv ;;
                0) exit ;;
                *) clear; inicio ;;
            esac
}

inicio
