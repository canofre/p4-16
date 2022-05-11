#!/usr/bin/env python
import sys
import os
# Suprimir warning ipv6 causado pelo scapy
import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
from scapy.all import *

ETH_SRC='enp8s0np0'
ETH_DST='enp8s0np1'
IP_SRC='10.0.1.10'      
IP_DST='10.0.4.10'      

def send(n,t):
    pkt_ether = Ether(dst=get_if_hwaddr(ETH_DST),src=get_if_hwaddr(ETH_SRC)) 
    #pkt_ip = IP(src=IP_SRC,dst=IP_DST,ttl=(1,n))/ICMP()
    pkt_ip = IP(src=IP_SRC,dst=IP_DST,tos=t)/ICMP()
    for i in range(n):
        sendp(pkt_ether/pkt_ip,iface=ETH_SRC)

def recive_t():
    print ("Recive tcpdump")
    os.system("tcpdump -vi -X -i"+ETH_DST+" icmp")

def recive_s():
    print ("Recive scapy")
    sniff(iface=ETH_DST,prn=lambda x:pkt_show(x) )
    p = sniff(iface=ETH_DST )
    p.summary()

def pkt_show(pkt):
    pkt.show()

def uso():
    print "USO Pyton: "
    print "  "+str(sys.argv[0])+" s nPkts 10(E2I)|20(E2E)"
    print "  "+str(sys.argv[0])+" [rt|rs] : recive rt:tcpdum, rs:scapy"

def main(args):
    n=5
    p = len(sys.argv)

    if( p == 1 ):
        uso()
    else:
        op = str(sys.argv[1])    
        #depois automativas erros de nao passar argumento    
        if ( op == 's' ):
            if ( p == 4 ):
                send(int(sys.argv[2]),int(sys.argv[3]))
            else:
                uso()
        elif ( op == 'rt' ):
            recive_t()
        else:
            recive_s()
    
    return 0;

if __name__ == '__main__':
    sys.exit(main(sys.argv)) 
