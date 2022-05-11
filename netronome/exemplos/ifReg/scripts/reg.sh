#!/bin/bash
## script que acessa um registrador chamado "latency" que guarda 
## esse timestamp e guarda em log.

#Nome do registrador
PORTAS=( `nfp-config.sh ns | grep STATUS | cut -d" " -f3` )

# @param nome do registrador a ser lido 
# @return saida em decimal 
getReg8(){
    #valid=true
    while [ true ] 
    do
        # Considera que exite um path setado para execucao do rtecli
        regBin="$(rtecli -p 20206 registers get -r $1 -i 0)"
        # 8 bits - ['0x00', '0x00'] - Posicao anterior + 2 + 6
        regDec="$1[0]="$(( 16#${regBin:4:2} ))" $1[1]="$(( 16#${regBin:12:2} ))" $1[2]="$(( 16#${regBin:20:2} ))
        #" PKTs="$(( 16#${regBin:28:2} ))

        #printf "$regBin $regDec \n"
        printf "$regDec \n"
        sleep 1
    done
}

# @param nome do registrador a ser lido 
# @return saida em decimal 
getReg32(){
    #valid=true
    while [ true ] 
    do
        # Considera que exite um path setado para execucao do rtecli
        regBin="$(rtecli -p 20206 registers get -r $1 -i 0)"
        
        # 32 bits - ['0x00000000', '0x00000000', '0x00000000']
        # Posicao anterior + 8 + 6
        regDec="$1> [0]:"$(( 16#${regBin:4:8} )) " [1]:"$(( 16#${regBin:18:8} ))" [2]:"$(( 16#${regBin:32:8} ))" [3]:"$(( 16#${regBin:46:8} ))

        #printf "$regBin $regDec \n"
        printf "$regDec \n"
        sleep 1

        #Nao sei se funciona
        #[[ $count -eq 100 ]] && break || ((count++))
    done
}

# @param nome do registrador a ser lido 
# @return saida em decimal 
getReg64(){
    #valid=true
    while [ true ] 
    do
        # Considera que exite um path setado para execucao do rtecli
        regBin="$(rtecli -p 20206 registers get -r $1 -i 0)"
        
        # 64 bits - ['0x0000000000002d75', '0x0000000000000000'] 
        # Posicao anterior + 16 + 6
        regDec="P0="$(( 16#${regBin:4:16} ))" P1="$(( 16#${regBin:26:16} ))

        printf "$regBin $regDec \n"
        sleep 1
        #Nao sei se funciona
        #[[ $count -eq 100 ]] && break || ((count++))
    done
}

uso(){
    echo "$0 tamanhoRegistrador nomeRegistrador"
}

case $1 in
    8) getReg8 $2 ;;
    32) getReg32 $2 ;;
    64) getReg64 $2 ;;
    *) uso ;;
esac
