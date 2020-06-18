#!/usr/bin/env python

from probe_hdrs import *

def expand(x):
    yield x
    while x.payload:
        x = x.payload
        yield x

def handle_pkt(pkt):
    pkt.show()
    print '>>> Tamanho: ',len(pkt)
    if ProbeData in pkt:
        print ""
        print "-----------------------------------------------------\n"
        print "Total de saltos: {}".format(pkt[Probe].hop_cnt)

        data_layers = [l for l in expand(pkt) if l.name=='ProbeData']
        for sw in data_layers:
            #utilization = 0 if sw.cur_time == sw.last_time else 8.0*sw.byte_cnt/(sw.cur_time - sw.last_time)
            print "Switch {} - Port ig {}: Port eg {} - ".format(sw.swid, sw.port_ig, sw.port_eg)
            print "  ---- IG_Tmp {}: CG_Tmp {} - ".format(sw.ig_tmp, sw.cg_tmp)


def main():
    iface=IFACE
    print "sniffing on {}".format(iface)
    sniff(iface = iface,
          prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
