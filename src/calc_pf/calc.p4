/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

/*
 * This is a custom protocol header for the calculator. We'll use 
 * etherType 0x1234 for it (see parser)
 */
const bit<16> P4CALC_ETYPE  = 0x1234;
const bit<8>  P4CALC_P      = 0x50;   // 'P'
const bit<8>  P4CALC_4      = 0x34;   // '4'
const bit<8>  P4CALC_VER    = 0x01;   // v0.1
const bit<8>  P4CALC_ADD    = 0x2b;   // '+'
const bit<8>  P4CALC_SUB    = 0x2d;   // '-'
const bit<8>  P4CALC_MULT   = 0x2a;   // '*'
const bit<8>  P4CALC_DIV    = 0x2f;   // '/'

header p4calc_t {
    bit<8>  p;      // Letra P (0x50)
    bit<8>  four;   //    
    bit<8>  ver;    //
    bit<8>  op;     // 
    bit<32> var1;   // valor 1   
    bit<32> var2;   // valor 2
    bit<32> res;    // resultado
} 

struct headers {
    ethernet_t   ethernet;
    p4calc_t     p4calc;
}

struct metadata {
    /* In our case it is empty */
}

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {    
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            P4CALC_ETYPE : check_p4calc;
            default      : accept;
        }
    }
    
    state check_p4calc {
        /* TODO: just uncomment the following parse block */
        // O que faz o lookahead
        // Acho que verifica o cabecalho do cacote 
        transition select(packet.lookahead<p4calc_t>().p,
        packet.lookahead<p4calc_t>().four,
        packet.lookahead<p4calc_t>().ver) {
            (P4CALC_P, P4CALC_4, P4CALC_VER) : parse_p4calc;
            default                          : accept;
        }
        
    }
    
    state parse_p4calc {
        packet.extract(hdr.p4calc);
        transition accept;
    }
}

/*************************************************************************
 ************   C H E C K S U M    V E R I F I C A T I O N   *************
 *************************************************************************/
control MyVerifyChecksum(inout headers hdr,
                         inout metadata meta) {
    apply { }
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    bit<32> tmp;
	//			  |       |       |       |      |
	bit<32> a = 0b00000000000000101000000000000000; //2.5
    bit<32> b = 0b00000000000000111000000000000000; //3.5
	
    action send_back(bit<32> result) {
        bit<48> tmp_mac;
        hdr.p4calc.res = result;
        hdr.p4calc.p=0x51;
        tmp_mac = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = hdr.ethernet.srcAddr; 
        hdr.ethernet.srcAddr = tmp_mac;
        //Diferenca entre egress_spect e egress_port?
        standard_metadata.egress_spec = standard_metadata.ingress_port;
        
  
    }
    
    action operation_add() {
        tmp = hdr.p4calc.var1 + hdr.p4calc.var2;
        send_back(tmp);
    }
    
    action operation_sub() {
        tmp = hdr.p4calc.var1 - hdr.p4calc.var2;
        send_back(tmp);
    }
    
    action operation_mult() {
		//Sem scaling up
        tmp =(a  * b) / (1 << 8);
		
		//Com scaling up - sempre ZERO
		//bit<32> a2 = a << 8;
		//bit<32> b2 = b << 8;
        //hdr.p4calc.var1 = a2;
        //hdr.p4calc.var2 = b2;
        //tmp =(bit<32>) ( ((bit<64>)a2  * (bit<64>)b2)  / (1 << 16));
        //tmp =(a2  * b2);

        send_back(tmp);
    }
    
    action operation_div() {
        tmp = 0b00000000000000110101000000000000;
		//tmp = ((a/b )*(1 << 16));
        send_back(tmp);
    }

    action operation_drop() {
        mark_to_drop(standard_metadata);
    }

    
    table calculate {
        key = {
            hdr.p4calc.op        : exact;
        }
        actions = {
            operation_add;
            operation_sub;
            operation_mult;
            operation_div;
            operation_drop;
        }
        const default_action = operation_drop();
        const entries = {
            P4CALC_ADD  : operation_add();
            P4CALC_SUB  : operation_sub();
            P4CALC_MULT : operation_mult();
            P4CALC_DIV  : operation_div();
            
        }
    }
            
    apply {
        if (hdr.p4calc.isValid()) {
            calculate.apply();
        } else {
            operation_drop();
        }
    }
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}

/*************************************************************************
 *************   C H E C K S U M    C O M P U T A T I O N   **************
 *************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

/*************************************************************************
 ***********************  D E P A R S E R  *******************************
 *************************************************************************/
control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.p4calc);
    }
}

/*************************************************************************
 ***********************  S W I T T C H **********************************
 *************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
