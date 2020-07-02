/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#define MAX_HOPS 10

const bit<16> TYPE_IPV4 = 0x800;

typedef bit<48> macAddr_t; 
typedef bit<32> ip4Addr_t;


/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/
header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType; 
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffServ;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

// (?): utilização de array com uma topologia com mais de dois switches e
// avaliar o tamanho do pacote inicializado. 
// (?): como verificar os dados do pacote nas portas do sw
header coletor_t {
    bit<1>  boss;
    bit<7>  swid;
    bit<64> info;
}

struct metadata {
    /* empty */
    bit<32> cont;
    bit<2> encap;
}

struct headers {
    ethernet_t          ethernet;
    ipv4_t              ipv4;
    coletor_t[5]        coletor;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t smt) {

    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            default: accept; 
        }
    }
    
    state parse_ipv4 {
		packet.extract (hdr.ipv4);
		transition select(hdr.ipv4.diffServ) {
            200: parse_coletor;
            default: accept;
       }
	} 

    state parse_coletor{
		packet.extract (hdr.coletor.next);
        transition select (hdr.coletor.last.boss) {
            1: accept;
            default: parse_coletor;
            //default :accept;
        }
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/
control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*******************************************************************************
**************  I N G R E S S   P R O C E S S I N G ****************************
*******************************************************************************/

control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t smt) {
    
    action drop() {
        mark_to_drop(smt);
    }
    
    action ipv4_forward(macAddr_t dstAddr, bit<9> port,bit<2> encap) {
        smt.egress_spec = port;
        meta.encap = encap;
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
        default_action = NoAction();
    }

    apply {
        if ( hdr.ipv4.isValid() ){
            ipv4_lpm.apply();   
        }
    }
}

/*******************************************************************************
****************  E G R E S S   P R O C E S S I N G   **************************
*******************************************************************************/
control MyEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t smt) {
    //(?): tomada de alguma decisao com as informacoes coletadas
    //(?): quais informacoes coletar
    bit<48> diftmp = smt.egress_global_timestamp - smt.ingress_global_timestamp;
    action set_swid(bit<7> swid){
        hdr.coletor[0].swid = swid;
    }

    table swid {
        actions = {
            set_swid;
            NoAction;
        }
        default_action = NoAction();
    }

    apply {
        if ( meta.encap == 1 ){
            //encapsula o pacote na entrada e remove na saida
            if ( hdr.ipv4.diffServ == 200 ){    // ja existe um pacote 
                //hdr.ipv4.diffServ=20;
                hdr.coletor[0].boss=0;
                hdr.coletor.push_front(1);
                hdr.coletor[0].setValid();
            }else{
                hdr.coletor[0].setValid();
                hdr.ipv4.diffServ=200;
            }
            hdr.coletor[0].boss=1;
            hdr.coletor[0].info=(bit<64>)diftmp;
            swid.apply();
        }else {
            if ( hdr.ipv4.diffServ == 200 ){    // ja existe um pacote 
                hdr.ipv4.diffServ=20;
                hdr.coletor[0].setInvalid();
            }
        }
                
        //TODO: usar o encap para definir em quais switches será encapsulado e
        //em qual sera desencapsulado podendo utilizar o array e verificar o
        //tamanho
        /*
        if ( meta.encap == 1 ) { 
            encapsula 
        }else if ( meta.encap == 0 ) {
            hdr.ipv4.diffServ=20;
            hdr.coletor.setInvalid();
        }
        */

            
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/
control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply {
	    update_checksum(
	        hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	          hdr.ipv4.ihl,
              hdr.ipv4.diffServ,
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
        packet.emit(hdr.coletor);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch( MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;
