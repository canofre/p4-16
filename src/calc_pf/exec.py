#!/usr/bin/env python

import argparse
import sys
import socket
import random
import struct
import re

from scapy.all import *
import readline

class P4calc(Packet):
    name = "P4calc"
    fields_desc = [ StrFixedLenField("P", "P", length=1),
                    StrFixedLenField("Four", "4", length=1),
                    XByteField("version", 0x01),
                    StrFixedLenField("op", "+", length=1),
                    BitField("operand_a",0, 32),
                    BitField("operand_b",0, 32),
                    BitField("result",0,32)]
                    #IEEEFloatField("operand_a", 0),
                    #IEEEFloatField("operand_b", 0),
                    #IEEEFloatField("result",0)]

bind_layers(Ether, P4calc, type=0x1234)


def main(args):
    if ( len(sys.argv) != 4):
        print "Executar: ",str(sys.argv[0])," V1 OP V2"
        exit()


    iface = 'eth0'
    
    get_bin = lambda x, n: format(x, 'b').zfill(n) 
    print get_bin(12, 32)
    pkt= Ether(dst='00:04:00:00:00:00', type=0x1234) / P4calc(op=sys.argv[2],
		operand_a=int(sys.argv[1]),operand_b=int(sys.argv[3]))
    pkt = pkt/' '
   
    pkt.show()
    resp = srp1(pkt, iface=iface, timeout=1, verbose=False)
    print "======================="
    print "Operacao",int(sys.argv[1]), str(sys.argv[2]), int(sys.argv[3])
    resp.show()
    if resp:
        p4calc=resp[P4calc]
        if p4calc:
            print get_bin(p4calc.result, 32)
        else:
            print "cannot find P4calc header in the packet"
    else:
        print "Didn't receive response"


if __name__ == '__main__':
    sys.exit(main(sys.argv))
