#!/bin/bash
PATH_NFP=/opt/netronome/bin
PATH_P4=/opt/netronome/p4

uso(){
    printf "$0 [opcao]\n"
    printf "    all (arq.p4cfg): compila, carrega e executa\n"
    printf "    comp (arq.p4cfg): compila e carrega;\n"
    printf "    car (arq.nffw) (arq.p4cfg): carrega driver e config; \n"
    printf "    ex: executa\n";
}

# Passar o driver e o arquivo de configuracao
carrega(){
    echo "Carregando driver $1 e $2 ..."
    nfp-config.sh nr $1 $2
}

compila(){
    [[ $(ls *.p4 | wc -l) -ne 1 ]] && { echo "Vários arquivos *.p4"; exit; };   
    dirOut=out
    echo "Compilando *.p4 ..."
    rm -rf *.nffw

    #firmware=`echo *.p4 | cut -d'.' -f1`Firmware.nffw
    firmware=`echo *.p4 | cut -d'.' -f1`.nffw
    
    $PATH_P4/bin/nfp4build --output-nffw-filename $firmware -4 *.p4 \
        --sku nfp-4xxx-b0 --platform hydrogen --reduced-thread-usage \
        --no-shared-codestore --debug-info --nfp4c_p4_version 16 \
        --nfp4c_p4_compiler p4c-nfp --nfirc_default_table_size 65536 \
        --nfirc_no_all_header_ops --nfirc_implicit_header_valid \
        --nfirc_no_zero_new_headers --nfirc_multicast_group_count 16 \
        --nfirc_multicast_group_size 16 --nfirc_mac_ingress_timestamp  \
         -c plugin.c  > nfp4build.log
        #--no-nfcc-ng -c plugin.c  > nfp4build.log
    
    rm -rf $dirOut; mkdir $dirOut;
    mv  pif_* *.list *.json *.yml *.txt Makefile-nfp4build callbackapi/ $dirOut/ 2> /dev/null
    #rm -rf pif_* *.list *.json *.yml *.txt Makefile-nfp4build callbackapi/
    #rm -rf build

    if [[ -f $firmware ]]; then
        read -p "Carregar driver(*/N)?" resp
        if [[ "${resp^}" != "N" ]]; then
            carrega $firmware $1
        fi

    fi
}

execMoonGenRemoto(){
    nohup ssh -t root@200.132.136.67 '/opt/MoonGen/build/MoonGen \
        /opt/MoonGen/examples/netronome-packetgen/packetgen.lua \
        -tx 0 -rx 0 --dst-ip 10.2.0.10 --dst-ip-vary 0.0.0.0 \
        --timeout 10 -fp /tmp/outAux.log ' > nohup.out.log 2>&1 &

    # Tempo para inicializar o DPDK
    echo "Inicializando host remoto ..."; sleep 15
    echo "Executando no host remoto ..."

}

executa(){
    drive_ok=`nfp-config.sh ns | grep false | wc -l`
    [[ $drive_ok -eq 1 ]] && { echo "Drive nao carregado"; exit; };
    execMoonGenRemoto 
    
    echo "Comando local 1"
    echo "Comando local 2"

    # Tempo para finalizar a execução remota
    sleep 20

    # Mover aquivo de logs do nohup para dir de execucao 
}

main(){
    case $1 in
        all)    
            compila $2 $3
            executa ;;
        comp)
            compila $2 $3;;
        ex)
            executa ;;
        car)
            carrega $2 $3
            ;;
        *)
            uso ;;
    esac
    
}

main $*
