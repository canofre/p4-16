/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;

/*****************************************************************
*********************** H E A D E R S  ***************************
*****************************************************************/
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t; 
typedef bit<32> ip4Addr_t;

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
    ethernet_t  ethernet;
    ipv4_t      ipv4;
}


/* Faz com que o registrador não serja armazenado em cache */
#pragma netro no_lookup_caching
register<bit<8>>(2) regR1;

/*********************************************************************
************************ P A R S E R  ********************************
*********************************************************************/
parser MyParser(packet_in packet, out headers hdr,
                inout metadata meta, inout standard_metadata_t smt) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
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

/*********************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   **********
*********************************************************************/
control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}

/*********************************************************************
**************  I N G R E S S   P R O C E S S I N G ******************
*********************************************************************/
control MyIngress(inout headers hdr, inout metadata meta, 
                  inout standard_metadata_t smt) {
    action drop() {
        mark_to_drop();
    }
    
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        smt.egress_spec = (bit<16>)port;
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

/*********************************************************************
****************  E G R E S S   P R O C E S S I N G   ****************
*********************************************************************/
control MyEgress(inout headers hdr, 
                 inout metadata meta, 
                 inout standard_metadata_t smt) {
    bit<8> a;

    /* Clona o pacote e incrementa o contador de clone */
    action cloneAndCount(){
        bit<8> b;
        hdr.ipv4.diffServ = 200;
        clone(CloneType.E2E,1);
        hdr.ipv4.diffServ = 0;
        regR1.read(b,1);
        regR1.write(1,b+1);
    }

    apply { 
        
        /* If para evitar pacotes enviados pelo SO */
        if ( hdr.ethernet.etherType == TYPE_IPV4  ){
            /* Clona a cada 5 pacotes, exceto para já clonados */
            regR1.read(a,0);
            a=a+1;
            if ( a >= 5 && hdr.ipv4.diffServ !=200) {
                cloneAndCount();
                a=0;               
            } 
            regR1.write(0,a);
        }
    }
}   

/*********************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   ***********
*********************************************************************/
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
