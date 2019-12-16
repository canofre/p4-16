#!/usr/bin/env python
import sys
import time
from probe_hdrs import *

def main():
    e="S"
    probe_pkt = Ether(dst='ff:ff:ff:ff:ff:ff', src=get_if_hwaddr('eth0')) / \
                Probe(hop_cnt=0) / \
                ProbeFwd(egress_spec=4) / \
                ProbeFwd(egress_spec=1) / \
                ProbeFwd(egress_spec=4) / \
                ProbeFwd(egress_spec=1) / \
                ProbeFwd(egress_spec=3) / \
                ProbeFwd(egress_spec=2) / \
                ProbeFwd(egress_spec=3) / \
                ProbeFwd(egress_spec=2) / \
                ProbeFwd(egress_spec=2)       

    
    while (e.upper() != 'N' ):
        try:
            sendp(probe_pkt, iface='eth0')
            time.sleep(1)
        except KeyboardInterrupt:
            sys.exit()
        e = str(raw_input("Enviar (S/N)?"))

if __name__ == '__main__':
    main()
