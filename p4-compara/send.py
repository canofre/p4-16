#!/usr/bin/env python
import sys
import time
from probe_hdrs import *

def main():
    e="S"
    
    probe_pkt_124 = Ether(dst='ff:ff:ff:ff:ff:ff', src=get_if_hwaddr('eth0')) / \
                Probe(hop_cnt=0,end_swid=4) / \
                ProbeFwd(egress_spec=2,op=4) / \
                ProbeFwd(egress_spec=4,op=4) / \
                ProbeFwd(egress_spec=5,op=4) / \
                ProbeFwd(egress_spec=7,op=4)  

    probe_pkt_124r = Ether(dst='ff:ff:ff:ff:ff:ff', src=get_if_hwaddr('eth0')) / \
                Probe(hop_cnt=0,end_swid=4) / \
                ProbeFwd(egress_spec=2,op=4) / \
                ProbeFwd(egress_spec=13,op=4) / \
                ProbeFwd(egress_spec=4,op=4) / \
                ProbeFwd(egress_spec=5,op=4) / \
                ProbeFwd(egress_spec=7,op=4)  

    probe_pkt_134 = Ether(dst='ff:ff:ff:ff:ff:ff', src=get_if_hwaddr('eth0')) / \
                Probe(hop_cnt=0,end_swid=4) / \
                ProbeFwd(egress_spec=3,op=4) / \
                ProbeFwd(egress_spec=4,op=4) / \
                ProbeFwd(egress_spec=5,op=4) / \
                ProbeFwd(egress_spec=8,op=4) 
    
    while (e.upper() != 'N' ):
        try:
            sendp(probe_pkt_124r, iface='eth0')
            time.sleep(1)
            sendp(probe_pkt_134, iface='eth0')
            time.sleep(1)
        except KeyboardInterrupt:
            sys.exit()
        e = str(raw_input("Enviar (S/N)?"))

if __name__ == '__main__':
    main()
