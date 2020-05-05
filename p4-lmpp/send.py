#!/usr/bin/env python
import sys
import time
from probe_hdrs import *

def main():
    e="S"
    pkt_154 = Ether(dst='ff:ff:ff:ff:ff:ff', src=get_if_hwaddr('eth0')) / \
                Probe(hop_cnt=0) / \
                ProbeFwd(egress_spec=5,op=3) / \
                ProbeFwd(egress_spec=4,op=2) / \
                ProbeFwd(egress_spec=1,op=4) 

    pkt_135 = Ether(dst='ff:ff:ff:ff:ff:ff', src=get_if_hwaddr('eth0')) / \
                Probe(hop_cnt=0) / \
                ProbeFwd(egress_spec=3,op=0) / \
                ProbeFwd(egress_spec=5,op=2) / \
                ProbeFwd(egress_spec=1,op=4) 
    
    pkt_135b = Ether(dst='ff:ff:ff:ff:ff:ff', src=get_if_hwaddr('eth0')) / \
                Probe(hop_cnt=0) / \
                ProbeFwd(egress_spec=3,op=2) / \
                ProbeFwd(egress_spec=13,op=4) / \
                ProbeFwd(egress_spec=5,op=4) / \
                ProbeFwd(egress_spec=1,op=1) 
   
    probe_pkt = pkt_135
    while (e.upper() != 'N' ):
        try:
            sendp(probe_pkt, iface='eth0')
            time.sleep(1)
        except KeyboardInterrupt:
            sys.exit()
        e = str(raw_input("Enviar (S/N)?"))

if __name__ == '__main__':
    main()
