#!/usr/bin/env python
import sys
import time
from probe_hdrs import *

def main():
    e="S"
    pkt_154 = Ether(dst='ff:ff:ff:ff:ff:ff', src=get_if_hwaddr(IFACE)) / \
                Probe(hop_cnt=0) / \
                ProbeFwd(egress_spec=5) / \
                ProbeFwd(egress_spec=4) / \
                ProbeFwd(egress_spec=1) / \
                ProbeFwd(egress_spec=1,fim=1)

    pkt_001 = Ether(dst='ff:ff:ff:ff:ff:ff', src=get_if_hwaddr(IFACE)) / \
                Probe(hop_cnt=0) / \
                ProbeFwd(egress_spec=0,fim=1) 
    
    probe_pkt = pkt_001 
    #probe_pkt = pkt_154
    probe_pkt.show()
    while (e.upper() != 'N' ):
        try:
            sendp(probe_pkt, iface=IFACE)
            time.sleep(1)
        except KeyboardInterrupt:
            sys.exit()
        e = str(raw_input("Enviar (S/N)?"))

if __name__ == '__main__':
    main()
