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
                #    IntField("operand_a", 0),
                #    IntField("operand_b", 0),
                    IntField("result", 0xDEADBAB)]

bind_layers(Ether, P4calc, type=0x1234)

def main():
    iface = 'eth0'
    while True:
        s = str(raw_input(': '))
        pkt = Ether(dst='00:04:00:00:00:00', type=0x1234) / P4calc(op=s)
        resp = srp1(pkt, iface=iface, timeout=1, verbose=False)
        if resp:
            p4calc=resp[P4calc]
            if p4calc:
                print 'Saida:',p4calc.result
                pkt.show()
                #print type(p4calc.result)
            else:
                print "cannot find P4calc header in the packet"
        else:
            print "Didn't receive response"

if __name__ == '__main__':
    main()
