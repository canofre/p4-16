/* -*- P4_16 -*- */
/* 
 * Nesse arquivo os dados obtidos nao sao tratados com tabelas de match-action,
 * mas sim por condicionais no momento da execucao da action no egress.
 */
#include <core.p4>
#include <v1model.p4>

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

const bit<16> TYPE_IPV4  = 0x800;
const bit<16> TYPE_PROBE = 0x812;
const egressSpec_t  PORT_RECIRCULATE = 13;

#define MAX_HOPS 10
#define MAX_PORTS 8

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/


header ethernet_t {
    macAddr_t   dstAddr;
    macAddr_t   srcAddr;
    bit<16>     etherType;
}

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
}

// Cabecalho probe Top-level. Indica a quantidade de saltos do pkt
header probe_t {
    bit<8>  hop_cnt;
    bit<8>  end_swid;
    bit<48> hop_data;
}

// Os dados adicionados ao probe em cada switche
header probe_data_t {
    bit<1>  bos;        // bottom of stack
    bit<7>  swid;       // ID do sw
    bit<8>  port;       // porta de saida
    bit<48> data;       // informacao solicitada no pacote
}

/* Indica a porta de saida para qual o switch deve enviar o pacote. Existe um
 * cabecalho destes para cada switch.
 */
header probe_fwd_t {
    bit<8>  egress_spec;
    bit<8>  op;  
}

struct parser_metadata_t {
    bit<8>  remaining;
}

struct metadata {
    bit<8> egress_spec;
    bit<8> op;
    parser_metadata_t parser_metadata;
}

struct headers {
    ethernet_t              ethernet;
    ipv4_t                  ipv4;
    probe_t                 probe;
    probe_data_t[MAX_HOPS]  probe_data;
    probe_fwd_t[MAX_HOPS]   probe_fwd;
}

/*************************************************************************
************************* P A R S E R  ***********************************
*************************************************************************/
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
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
        meta.parser_metadata.remaining = hdr.probe.hop_cnt + 1;
        transition select(hdr.probe.hop_cnt) {
            0: parse_probe_fwd;
            default: parse_probe_data;
        }
    }

    state parse_probe_data {
        packet.extract(hdr.probe_data.next);
        transition select(hdr.probe_data.last.bos) {
            1: parse_probe_fwd;
            default: parse_probe_data;
        }
    }

    state parse_probe_fwd {
        packet.extract(hdr.probe_fwd.next);
        meta.parser_metadata.remaining = meta.parser_metadata.remaining - 1;
        meta.egress_spec = hdr.probe_fwd.last.egress_spec;
        meta.op = hdr.probe_fwd.last.op;
        transition select(meta.parser_metadata.remaining) {
            0: accept;
            default: parse_probe_fwd;
        }
    }
}

/*************************************************************************
*************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/
control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
***************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t smt) {
    
    action drop() {
        mark_to_drop(smt);
    }
    
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        smt.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
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
            // atualiza a porta de saida e o numero de hops
            smt.egress_spec = (bit<9>)meta.egress_spec;
            hdr.probe.hop_cnt = hdr.probe.hop_cnt + 1;
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   ********************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t smt) {

    register<bit<48>>(1) reg_data;

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
        bit<48> hops;
        bit<48> tmp;
        
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
            hdr.probe_data[0].port = (bit<8>)smt.egress_port;
            if (meta.op == 0){
                hdr.probe_data[0].data = smt.ingress_global_timestamp;
            }else if (meta.op == 1){
                hdr.probe_data[0].data = smt.egress_global_timestamp;
            }else if (meta.op == 2){
                hdr.probe_data[0].data = (bit<48>)smt.enq_timestamp;
            }else if (meta.op == 3){
                hdr.probe_data[0].data = (bit<48>)smt.enq_qdepth;
            }else if (meta.op == 4){
                hdr.probe_data[0].data = (bit<48>)smt.deq_timedelta;
            }else if (meta.op == 5){
                hdr.probe_data[0].data = (bit<48>)smt.deq_qdepth;
            }else{
                hdr.probe_data[0].data = 0;
            }

            //tmp = smt.egress_global_timestamp - smt.ingress_global_timestamp;
            //hdr.probe.hop_tmp = hdr.probe.hop_tmp + tmp;
                        
            /* Se estiver no sw indicado para somar, le o valor do registrador,
             * se for zero atualiza com a quantidade de saltos do pacote atual.
             * Se for diferente de zero, soma o valor com o do registrador e
             * zera o registrador.
             */
            if ( hdr.probe.end_swid == (bit<8>)hdr.probe_data[0].swid ){
                reg_data.read(hops,0);
                if (hops == 0 ){
                   reg_data.write(0,(bit<48>)hdr.probe.hop_cnt);
                }else {
                    hdr.probe.hop_data = (bit<48>)hdr.probe.hop_cnt + hops;
                    reg_data.write(0,0);
                }
            }
        }
        /* Se a porta de saida for a de recirculacao marca o pacote para ser
         * enviado para a entrada so sw novamente, após obter as informações.
         * Essa marcacao pode ser realizada tambem no ingress, pois o pacote
         * somente sera enviado para recircular apos o processamento completo do
         * pipeline.
         */
        if ( smt.egress_port == PORT_RECIRCULATE ) {
            recirculate(smt);
        }
    }
}

/************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   ***************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
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
