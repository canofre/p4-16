/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

typedef bit<16> egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

const bit<16> TYPE_IPV4  = 0x800;
const bit<16> TYPE_PROBE = 0x812;

#define MAX_HOPS 6
//#define MAX_PORTS 8

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

header ethernet_t { 
    macAddr_t   dstAddr;
    macAddr_t   srcAddr;
    bit<16>     etherType;
}//112 bits / 14 bytes

header ipv4_t {     
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     totalLen;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     fragOffset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdrChecksum;
    ip4Addr_t   srcAddr;
    ip4Addr_t   dstAddr;
}//160 bits / 20 bytes

// Cabecalho probe Top-level. Indica a quantidade de saltos do pkt
header probe_t {
    bit<8>  hop_cnt;
}

// Os dados adicionados ao probe em cada switch
header probe_data_t {   
    bit<1>  bos;        // bottom of stack
    bit<7>  swid;       // ID do sw
    bit<8>  port_ig;    // porta de entrada
    bit<8>  port_eg;    // porta de saida
    bit<64> ig_tmp;     // ingress global timestamp
    bit<64> cg_tmp;     // current global timestamp
}//152 bits / 19 bytes

/* Indica a porta de saida para qual o switch deve enviar o pacote. Existe um
 * cabecalho destes para cada switch.
 */
header probe_fwd_t {
    bit<8>  egress_spec;
    bit<8>  fim;
}


header intrinsic_metadata_t {
    //sec[63:32], nsec[31:0]
    bit<64> ingress_global_timestamp;
    bit<64> current_global_timestamp;
}//96 bits / 12 bytes

struct meta_t {
    bit<8>  porta_saida;
    bit<8>  i;
}

struct metadata_t {
    meta_t meta;        
}

struct headers {
    ethernet_t              ethernet;
    ipv4_t                  ipv4;
    probe_t                 probe;
    probe_data_t[MAX_HOPS]  probe_data;
    probe_fwd_t[MAX_HOPS]   probe_fwd;
    intrinsic_metadata_t    intrinsic_metadata;
}

/*************************************************************************
************************* P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata_t meta,
                inout standard_metadata_t smt) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            TYPE_PROBE: parse_probe;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }

    state parse_probe {
        packet.extract(hdr.probe);        
        transition select(hdr.probe.hop_cnt) {
            0: parse_probe_fwd;
            default: parse_probe_data;
        }
    }

    state parse_probe_data {
        // Adiciona o probe atual na próxima posição
        packet.extract(hdr.probe_data.next);
        transition select(hdr.probe_data.last.bos) {
            1: parse_probe_fwd;
            default: parse_probe_data;
        }
    }
    
    state parse_probe_fwd {
        packet.extract(hdr.probe_fwd.next);
        meta.meta.i = meta.meta.i +1;
        transition select(hdr.probe_fwd.last.fim) {
            1: accept;
            default: parse_probe_fwd;
        }
    }
    
}

/*************************************************************************
*************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata_t meta) {   
    apply {  }
}


/*************************************************************************
***************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t smt) {
    
    action drop() {
        mark_to_drop();
    }
    
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        smt.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    
     action atualiza_fwd(){
        smt.egress_spec = (bit<16>)hdr.probe_fwd[0].egress_spec;
        hdr.probe.hop_cnt = hdr.probe.hop_cnt + 1;
        hdr.probe_fwd.pop_front(1);
    }
    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }
    
    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
        } else if (hdr.probe.isValid()) {
              atualiza_fwd();
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   ********************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata_t meta,
                 inout standard_metadata_t smt) {
   // apply{ }

    action set_swid(bit<7> swid) {
        hdr.probe_data[0].swid = swid;
    }
   
    table swid {
        actions = {
            set_swid;
            NoAction;
        }
        default_action = NoAction();
    }

    apply {
        if (hdr.probe.isValid()) {
            // fill out probe fields
            hdr.probe_data.push_front(1);
            hdr.probe_data[0].setValid();
            // Seta bos=1 se for o primeiro salto
            if (hdr.probe.hop_cnt == 1) {
                hdr.probe_data[0].bos = 1;
            }else {
                hdr.probe_data[0].bos = 0;
            }
            // set switch ID and data field
            swid.apply();
            hdr.probe_data[0].port_ig = meta.meta.i; //(bit<8>)smt.ingress_port;
            hdr.probe_data[0].port_eg = (bit<8>)smt.egress_port;
            hdr.probe_data[0].ig_tmp =  hdr.intrinsic_metadata.ingress_global_timestamp >> 32;
            hdr.probe_data[0].cg_tmp =  hdr.intrinsic_metadata.current_global_timestamp;

        }
    }

}

/************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   ***************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata_t meta) {
    apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
    	      hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.probe);
        packet.emit(hdr.probe_data);
        packet.emit(hdr.probe_fwd);
        packet.emit(hdr.intrinsic_metadata);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;