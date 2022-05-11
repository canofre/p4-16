#!/bin/bash
PATH_NFP=/opt/netronome/bin
PATH_P4=/opt/netronome/p4
uso(){
    printf "$0 [opcao]\n"
    printf "    c (arq.p4cfg): compila e carrega;\n"
    printf "    l (arq.nffw) (arq.p4cfg): carrega driver e config; \n"
    printf "    bh: nfp4buld help\n";
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
    
    #--disable-component flowcache \
    $PATH_P4/bin/nfp4build --output-nffw-filename $firmware -4 *.p4 \
        --sku nfp-4xxx-b0 --platform hydrogen --reduced-thread-usage \
        --no-shared-codestore --debug-info --nfp4c_p4_version 16 \
        --nfp4c_p4_compiler p4c-nfp --nfirc_default_table_size 65536 \
        --nfirc_no_all_header_ops --nfirc_implicit_header_valid \
        --nfirc_no_zero_new_headers --nfirc_multicast_group_count 16 \
        --nfirc_multicast_group_size 16 --nfirc_mac_ingress_timestamp  > nfp4build.log
    
    rm -rf $dirOut; mkdir $dirOut;
    mv  pif_* *.list *.json *.yml *.txt *nfp4build* callbackapi/ $dirOut/ 2> /dev/null
    rm -rf $dirOut

    if [[ -f $firmware ]]; then
        read -p "Carregar driver(*/N)?" resp
        if [[ "${resp^}" != "N" ]]; then
            carrega $firmware $1
        fi
    fi
}


main(){
    case $1 in
        c)
            compila $2 ;;
        l)
            carrega $2 $3
            ;;
        bh)
            $PATH_P4/bin/nfp4build -h
            ;;
        *)
            uso ;;
    esac
    
}

main $*
