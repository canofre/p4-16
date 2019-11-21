#!/usr/bin/env python

#from scapy.all import sendp, send, srp1
#from scapy.all import Packet, hexdump, bind_layers
#from scapy.all import Ether, StrFixedLenField, XByteField, IntField,
#from scapy.all import Ether, StrFixedLenField, XByteField, IntField,
#from scapy.all import bind_layers
from scapy.all import *
from datetime import datetime

import time
class P4get(Packet):
    name = "P4get"
    fields_desc = [ StrFixedLenField("p", "C", length=1),
                    StrFixedLenField("op", "+", length=1),
                    IntField("result", 0xDEADBABA),
                    BitField("result48", 0,48)]
                    #LongField("result48", 0x00)]

def ml():
    milli_sec = int(round(time.time() * 1000))
    print(milli_sec)

bind_layers(Ether, P4get, type=0x1234)

def main():
    iface = 'eth0'
    while True:    
        s = str(raw_input(': '))
        if int(s) <= 9 :
            pkt = Ether(dst='00:04:00:00:00:00', type=0x1234) / P4get(op=s)
            resp = srp1(pkt, iface=iface, timeout=1, verbose=False)
#            resp.show()
#           pkt.show()
            if resp:
                ml()
                p4get=resp[P4get]
                if p4get:
                    print 'Result 48:',p4get.result48
                    print 'Result 32:',p4get.result
                else:
                    print "cannot find P4get header in the packet"
            else:
                print "Didn't receive response"
        else:
            print "Op [0-9]"

if __name__ == '__main__':
    main()
