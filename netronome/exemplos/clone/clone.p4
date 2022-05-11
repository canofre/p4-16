/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

/* Tipo de pacote - standard_metadata.instance_type */
#define PKT_NORMAL 0x0
#define PKT_CLONE_I2I 0x1
#define PKT_CLONE_E2I 0x2
#define PKT_CLONE_I2E 0x8
#define PKT_CLONE_E2E 0x9
#define PKT_RECIRCULADO 0x3

const bit<16> TYPE_IPV4 = 0x800;
/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<48> macAddr_t; 
typedef bit<32> ip4Addr_t;
typedef bit<64> time_t;

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

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t      ethernet;
    ipv4_t          ipv4;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/
parser MyParser(packet_in packet, out headers hdr,
                inout metadata meta, inout standard_metadata_t smt) {

    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            default: accept; 
        }
    }
    
    state parse_ipv4 {
        packet.extract (hdr.ipv4);
        transition accept;
    } 
   
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/
control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G **********************
*************************************************************************/
control MyIngress(inout headers hdr, inout metadata meta, 
                    inout standard_metadata_t smt) {
    
    action drop() {
        mark_to_drop();
    }
    
    action ipv4_forward(macAddr_t dstAddr, bit<16> port) {
       smt.ingress_port=1;
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
        if ( hdr.ipv4.isValid() ){
            ipv4_lpm.apply();   
        }
    }
}

/*************************************************************************
*************  E G R E S S   P R O C E S S I N G   ***********************
*************************************************************************/
control MyEgress(inout headers hdr, inout metadata meta, 
                    inout standard_metadata_t smt) {
 
    register<bit<8>>(4) regCtrl;
    bit<8> c1; //E2I;
    bit<8> c2; //E2E;
    bit<8> c3; //REC;

    /* Clona o pacote do Eggress para o Ingress 
    * e incrementa o indice 0 do registrador 
    */
    action pktCloneE2I(){
        clone(CloneType.E2I,1);
        regCtrl.read(c1,0);
        regCtrl.write(0,c1+1);
    }

    /* Clona o pacote do Eggress para o Egress 
    * e incrementa o indice 1 do registrador 
    */
    action pktCloneE2E(){
        clone(CloneType.E2E,1);
        regCtrl.read(c2,1);
        regCtrl.write(1,c2+1);
    }

    /* Recircula um pacote e incrementa o 
    * indice 2 do registrador 
    */
    action pktRecircular(){
        recirculate(meta);
        regCtrl.read(c3,2);
        regCtrl.write(2,c3+1);
    }

    table pktAction {
        key = { hdr.ipv4.diffServ: exact; }
        actions = {
            pktCloneE2I;
            pktCloneE2E;
            NoAction();
        }
        const default_action = NoAction();
        const entries = {
            10 : pktCloneE2I();
            20 : pktCloneE2E();
        }
    }

    apply {
        if ( smt.instance_type == PKT_NORMAL ){ 
            pktAction.apply();
        }else if (smt.instance_type == PKT_CLONE_E2E ) {
            pktRecircular();
        }
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
