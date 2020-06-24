from scapy.all import *

TYPE_PROBE = 0x812
IFACE='eth0'
class Probe(Packet):
   fields_desc = [ ByteField("hop_cnt", 0)]

class ProbeData(Packet):
   fields_desc = [ BitField("bos", 0, 1),
                   BitField("swid", 0, 7),
                   ByteField("port_ig", 0),
                   ByteField("port_eg", 0),
                   BitField("ig_tmp",0,64),
                   BitField("cg_tmp",0,64)]

class ProbeFwd(Packet):
   fields_desc = [ ByteField("egress_spec", 0),
                   ByteField("fim", 0)]
   

class ProbeFwd2(Packet):
   fields_desc = [ ByteField("egress_spec", 0),
                   ByteField("last", 0)]

bind_layers(Ether, Probe, type=TYPE_PROBE)
bind_layers(Probe, ProbeFwd, hop_cnt=0)
bind_layers(Probe, ProbeData)
bind_layers(ProbeData, ProbeData, bos=0)
bind_layers(ProbeData, ProbeFwd, bos=1)
bind_layers(ProbeFwd, ProbeFwd)


