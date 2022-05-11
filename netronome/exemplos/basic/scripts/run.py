#!/usr/bin/env python
import sys
import os
from scapy.all import *

ETH_SRC='enp3s0np0s0'   # AAAA
ETH_DST='enp3s0np0s2'   # CCC
IP_SRC='10.1.0.10'      
IP_DST='10.2.0.10'      


def send(n):
    pkt_ether = Ether(dst=get_if_hwaddr(ETH_DST),src=get_if_hwaddr(ETH_SRC)) 
    #pkt_ip = IP(src=IP_SRC,dst=IP_DST,ttl=(1,n))/ICMP()
    pkt_ip = IP(src=IP_SRC,dst=IP_DST)/ICMP()
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

def main(args):
    n=5
    p = len(sys.argv)

    if( p == 1 ):
        print str(sys.argv[0])+"s [n] : send [n|5] pacotes."
        print str(sys.argv[0])+"[rt|rs] : recive rt:tcpdum, rs:scapy"
    else:
        op = str(sys.argv[1])    # tem que passar n ou r
        #depois automativas erros de nao passar argumento    
        if ( op == 's' ):
            if( len(sys.argv) == 3 ):
                n = int(sys.argv[2])
            send(n)
        elif ( op == 'rt' ):
            recive_t()
        else:
            recive_s()
    
    return 0;

if __name__ == '__main__':
    sys.exit(main(sys.argv)) 
