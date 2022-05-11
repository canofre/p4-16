#!/bin/bash
## script que acessa um registrador chamado "latency" que guarda 
## esse timestamp e guarda em log.

#Nome do registrador
REG="reg_tmp"

function getTxRx(){
    p1=20206
    p2=20207
    printf "$p1 \t Tx \t Rx \t | $p2 \t Tx \t Rx \n"
    while :; do
        txRx_p1=`rtecli -p $p1 counters list-system | grep -e "'id': 35," -e "'id': 44," | cut -d":" -f4 | tr '},\n' ' '` 
        txRx_p2=`rtecli -p $p2 counters list-system | grep -e "'id': 35," -e "'id': 44," | cut -d":" -f4 | tr '},\n' ' '` 
        printf "$p1 \t $txRx_p1 \t | $p2 \t $txRx_p2 \n"
        sleep $1
    done
}

# Recebe como entrada o nome do registrador a ser lido e converte para decimal.
# Caso seja alterado o tamanho do registrador no programa, deve ser alterada a
# convercao para decimal.
function getReg(){
    #valid=true
    while [ true ] 
    do
        # Considera que exite um path setado para execucao do rtecli
        n206="$(rtecli -p 20206 registers get -r $1 -i 0)"
        n207="$(rtecli -p 20207 registers get -r $1 -i 0)"

        #echo $n206 $n207
        # 64 bits - ['0x0000000000002d75', '0x0000000000000000'] 
        # 32 bits - ['0x00000000', '0x00000000']
        reg_206="P0="$(( 16#${n206:4:16} ))" P1="$(( 16#${n206:26:16} ))
        reg_207="P0="$(( 16#${n206:4:16} ))" P1="$(( 16#${n207:26:16} ))

        printf "$n206 $reg_206 \t | $n207 $reg_207 \n"

        #if [ $count -eq 100 ] 
        #then
        #    break
        #fi
        #((count++))
    done
}


function drop(){
    while :; do
        drop206=`rtecli -p $P1 counters list-system | grep DROP_META | cut -d":" -f4- | cut -d"}" -f1`
        drop207=`rtecli -p $P2 counters list-system | grep DROP_META | cut -d":" -f4- | cut -d"}" -f1`
        printf "DROP_META - $P1:\t$drop206 \t | $P2: \t$drop207\n"
        sleep 2    
    done
}

function clearAll(){
    p1=20206
    p2=20207
    rtecli -p $p1 registers clear -r $1
    rtecli -p $p2 registers clear -r $1
    
    rtecli -p $p1 counters clear-all-system
    rtecli -p $p2 counters clear-all-system
}

function main(){
    
    if [ "$1" == "r" ]; then
        [[ $# -eq 2 ]] && reg=$2 || reg=$REG ;
        getReg $reg
    elif [ "$1" == "c" ]; then
        [[ $# -eq 2 ]] && seg=$2 || seg=0 ;
        getTxRx $seg
    elif [ "$1" == "clear" ]; then
        [[ $# -eq 2 ]] && reg=$2 || reg=$REG ;
        clearAll $reg
    else
        echo "USO:"
        echo "  reg.sh r    : informaçoes do registrador"
        echo "  reg.sh c [n]: informaçoes do contador a cada n segundos"
        echo "  reg.sh clear: limpa registradores e contadores"
    fi
}

main $*
