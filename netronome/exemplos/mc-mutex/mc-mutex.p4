/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>
#define PKT_NORMAL 0x0

const bit<16> TYPE_IPV4 = 0x800;
const bit<8>  PROTO_UDP = 0x11;
const bit<8>  PROTO_APF = 0xFD;

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t; 
typedef bit<32> ip4Addr_t;
typedef bit<32> var_t;
typedef bit<64> time_t;

register<var_t>(4) regR1;

/*****************************************************************
*********************** H E A D E R S  ***************************
*****************************************************************/
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

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> lengthUdp;
    bit<16> checksum;
}

header apf_t{
    var_t pacotes;
    var_t clonados;
    var_t latencia;
    var_t latMedia;
}

header intrinsic_metadata_t {
    time_t ingress_global_timestamp;
    time_t current_global_timestamp;
}

struct metadata {
    bit<2> valido;
    bit<32> valor;
}

struct headers {
    ethernet_t  ethernet;
    ipv4_t      ipv4;
    udp_t       udp;
    apf_t       apf;
    intrinsic_metadata_t intrinsic_metadata;
}

// Funcoes de plugin.c
extern void mutex();

/*****************************************************************
********************** P A R S E R  ******************************
*****************************************************************/
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t smt) {

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
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
            PROTO_UDP: parse_udp;
            default: accept; 
        }
    }
    state parse_udp {
		packet.extract (hdr.udp);
        packet.extract(hdr.apf);
		transition accept;
	} 
}


/*****************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   ******
*****************************************************************/
control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*****************************************************************
**************  I N G R E S S   P R O C E S S I N G **************
*****************************************************************/
control MyIngress(inout headers hdr, 
                  inout metadata meta, 
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

/*****************************************************************
****************  E G R E S S   P R O C E S S I N G   ************
*****************************************************************/
control MyEgress(inout headers hdr, 
                 inout metadata meta, 
                 inout standard_metadata_t smt) {
    
    action latenciaGet(){
        //Latencia em nanosegundos
        time_t df = hdr.intrinsic_metadata.current_global_timestamp - 
            hdr.intrinsic_metadata.ingress_global_timestamp;
        hdr.apf.latencia = df[31:0];
    }

    apply {  
    
        if ( smt.instance_type == PKT_NORMAL ){
            //latenciaGet(); 
            mutex();   
            regR1.write(0,hdr.apf.pacotes); 
            regR1.write(1,hdr.apf.clonados); 
            if ( hdr.ipv4.diffServ  == 200 ){
                clone(CloneType.E2E,1);
                //regR1.write(2,hdr.apf.latencia); //soma 
                //regR1.write(3,hdr.apf.latMedia); //media 
            }
        }
        hdr.apf.setInvalid();
    }
}

/*********************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   ********************************************************************************/
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


/*********************************************************************
***********************  D E P A R S E R  ****************************
*********************************************************************/
control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.apf);

    }
}

/*********************************************************************
***********************  S W I T C H  ********************************
*********************************************************************/
V1Switch( 
    MyParser(), 
    MyVerifyChecksum(), 
    MyIngress(), 
    MyEgress(), 
    MyComputeChecksum(), 
    MyDeparser()
) main;
