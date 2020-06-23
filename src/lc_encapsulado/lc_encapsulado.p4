/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#define MAX_HOPS 10

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_IPV6 = 0x86DD;

typedef bit<9>  egressSpec_t;
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
    bit<8>    diffserv;
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

/*Necessario inicializar o hops coletor com zero*/
header coletor_t {
    bit<1>  bos;
    bit<7>  swid;
    bit<64> info;
}

struct metadata {
    /* empty */
    bit<32> cont;
}

struct headers {
    ethernet_t          ethernet;
    ipv4_t              ipv4;
    coletor_t[MAX_HOPS] coletor;
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
            //TYPE_IPV4: parse_coletor;
            TYPE_IPV4: parse_ipv4;
            default: accept; 
        }
    }
    
    state parse_ipv4 {
		packet.extract (hdr.ipv4);
		transition parse_coletor;
	} 

    //Necessario inicializar o coletor com 1 no pacote
    state parse_coletor{
		packet.extract (hdr.coletor.next);
        //verify(hdp.coletor.
        transition select(hdr.coletor.last.bos){
            0: parse_coletor;
            default: accept;
        }
	//	transition parse_ipv4;
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
        // Acao realizada caso nao seja encontrada correspondencia na tabela.
        default_action = NoAction();
    }

    apply {
        // Executa/aplica/chama a tabela ipv4_lpm se dor um ipv4 valido
        if ( hdr.ipv4.isValid() ){
            ipv4_lpm.apply();   
        }
    }
}

/*******************************************************************************
****************  E G R E S S   P R O C E S S I N G   **************************
*******************************************************************************/
control MyEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t smt) {
    
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
         if (hdr.coletor[0].isValid()){
            hdr.coletor[0].bos = 0;
            hdr.coletor.push_front(1);
            hdr.coletor[0].setValid();
            hdr.coletor[0].bos = 1;
            hdr.coletor[0].info=(bit<64>)diftmp;
        }else{
            hdr.coletor[0].setValid();
            hdr.coletor[0].bos = 1;
            hdr.coletor[0].info=(bit<64>)diftmp;
        }
        swid.apply();
    }

//    apply{}
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/
/* Bloco para verificação do hash do pacote. Utiliza a função update_checksum
 * definida em v1model.
*/
control MyComputeChecksum(inout headers hdr, inout metadata meta) {
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
// Remonta e despacha o pacote
control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        // Escreve os cabeçalhos no pacote de saída
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.coletor);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch( MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;
