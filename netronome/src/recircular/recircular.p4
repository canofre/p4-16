/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> PORTA_REC = 13;

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


struct metadata {
    bit<8> num_r;    //numero de recirculacoes
}

struct headers {
    ethernet_t      ethernet;
    ipv4_t          ipv4;
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
        transition accept;
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
        mark_to_drop();
    }
    
    action ipv4_forward(macAddr_t dstAddr, bit<16> port,bit<8> num_r) {
       smt.ingress_port=1;
       smt.egress_spec = port;
       meta.num_r = num_r;
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
    
    register<bit<32>>(2) reg_tmp;    
    bit<32> c;

    apply {
    
        if ( meta.num_r > 0 ){            

            // O diffServ / tos inical e zero
            if ( hdr.ipv4.diffServ < 200 ){

                hdr.ipv4.diffServ=200+meta.num_r-1;            
                recirculate(meta);

            }else if ( hdr.ipv4.diffServ > 200 ){
                //smt.instance_type=0x3;
                hdr.ipv4.diffServ=hdr.ipv4.diffServ-1;
                recirculate(meta);
                
                // increnta com as recirculacoes
                reg_tmp.read(c,0);
                c=c+1;
                reg_tmp.write(0,c);

            }else if (hdr.ipv4.diffServ == 200 ) {   
                hdr.ipv4.diffServ=20;
            }
            
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

V1Switch( MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;