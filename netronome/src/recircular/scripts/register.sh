#!/bin/bash
## script que acessa um registrador chamado "latency" que guarda 
## esse timestamp e guarda em log.


valid=true
count=1

function getReg(){
    while [ $valid ] 
    do       
	    n206="$(sudo /opt/netronome/p4/bin/rtecli -p 20206 registers get -r $1 -i 0)"
	    n207="$(sudo /opt/netronome/p4/bin/rtecli -p 20207 registers get -r $1 -i 0)"

        #echo $n206 $n207
        #['0xc8', '0x14', '0xd0']
        r_206=$(( 16#${n206:4:8} ))
        r_207=$(( 16#${n207:4:8} ))
	    
        printf "$n206 $r_206 \t | $n207 $r_207 \n"

    	#if [ $count -eq 100 ] 
	    #then
		#    break
    	#fi
	    #((count++))
    done
}

function ver(){
    startValueStr=${nPackets:12:8}
	endValueStr=${nPackets:34:8}
	
	startValue=$(( 16#$startValueStr ))
	endValue=$(( 16#$endValueStr ))

	latency=$[endValue-startValue]
	latencyVector[$count]=$latency
	#echo "${latency}"
	

    for i in "${latencyVector[@]}"
    do
    	#echo ${latencyVector[@]} > latency.dat 
	    echo $i >> latency.dat
    done
}

function main(){

    getReg $1
}

main $*
