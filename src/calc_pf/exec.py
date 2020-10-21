#!/usr/bin/env python

import argparse
import sys
import socket
import random
import struct
import re

from scapy.all import sendp, send, srp1
from scapy.all import Packet, hexdump
from scapy.all import Ether, StrFixedLenField, XByteField, IntField
from scapy.all import bind_layers
import readline

class P4calc(Packet):
    name = "P4calc"
    fields_desc = [ StrFixedLenField("P", "P", length=1),
                    StrFixedLenField("Four", "4", length=1),
                    XByteField("version", 0x01),
                    StrFixedLenField("op", "+", length=1),
                    IntField("operand_a", 0),
                    IntField("operand_b", 0),
                    IntField("result", 0xDEADBABE)]

bind_layers(Ether, P4calc, type=0x1234)


def main(args):
    if ( len(sys.argv) != 4):
        print "Executar: ",str(sys.argv[0])," V1 OP V2"
        exit()


    iface = 'eth0'
    v1=10
    v2=10
    op='+'
    print "Operacao",int(sys.argv[1]), str(sys.argv[2]), int(sys.argv[3])
 
    pkt= Ether(dst='00:04:00:00:00:00', type=0x1234) / P4calc(op=sys.argv[2],
		operand_a=int(sys.argv[1]),operand_b=int(sys.argv[3]))
    pkt = pkt/' '
   
    pkt.show()
    resp = srp1(pkt, iface=iface, timeout=1, verbose=False)
    if resp:
        p4calc=resp[P4calc]
        if p4calc:
            print p4calc.result
        else:
            print "cannot find P4calc header in the packet"
    else:
        print "Didn't receive response"


if __name__ == '__main__':
    sys.exit(main(sys.argv))
