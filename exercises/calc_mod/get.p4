/* -*- P4_16 -*- */

/*
 * P4 Calculator
 *
 * This program implements a simple protocol. It can be carried over Ethernet
 * (Ethertype 0x1234).
 *
 * The Protocol header looks like this:
 *
 *        0                1                  2              3
 * +----------------+----------------+----------------+---------------+
 * |      P         |       4        |     Version    |     Op        |
 * +----------------+----------------+----------------+---------------+
 * |                              Result                              |
 * +----------------+----------------+----------------+---------------+
 *
 * P is an ASCII Letter 'P' (0x50)
 * 4 is an ASCII Letter '4' (0x34)
 * Version is currently 0.1 (0x01)
 * Op is an operation to Perform:
 *   '+' (0x2b) Result = OperandA + OperandB
 *   '-' (0x2d) Result = OperandA - OperandB
 *   '&' (0x26) Result = OperandA & OperandB
 *   '|' (0x7c) Result = OperandA | OperandB
 *   '^' (0x5e) Result = OperandA ^ OperandB
 *
 * The device receives a packet, performs the requested operation, fills in the 
 * result and sends the packet back out of the same port it came in on, while 
 * swapping the source and destination addresses.
 *
 * If an unknown operation is specified or the header is not valid, the packet
 * is dropped 
 */

#include <core.p4>
#include <v1model.p4>

/*
 * Define the headers the program will recognize
 */

/*
 * Standard Ethernet header 
 */
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

/*
 * This is a custom protocol header for the calculator. We'll use 
 * etherType 0x1234 for it (see parser)
 */
const bit<16> P4CALC_ETYPE = 0x1234;
const bit<8>  P4CALC_P     = 0x50;   // 'P'
const bit<8>  P4CALC_4     = 0x34;   // '4'
const bit<8>  P4CALC_VER   = 0x01;   // v0.1
const bit<8>  OP_0     = 0x30;   // '1'
const bit<8>  OP_1     = 0x31;   // '1'
const bit<8>  OP_2     = 0x32;   // '2'
const bit<8>  OP_3     = 0x33;   // '3'
const bit<8>  OP_4     = 0x34;   // '4'
const bit<8>  OP_5     = 0x35;   // '5' 
const bit<8>  OP_6     = 0x36;   // '6' 
const bit<8>  OP_7     = 0x37;   // '7' 
const bit<8>  OP_8     = 0x38;   // '8' 

/* TODO
 * fill p4calc_t header with P, four, ver, op, operand_a, operand_b, and res
 * entries based on above protocol header definition.
 */
header p4get_t {
    bit<8>  p;      // Letra P (0x50)
    bit<8>  four;   //    
    bit<8>  ver;    //
    bit<8>  op;     // 
//    bit<32> var1;   // valor 1   
//    bit<32> var2;   // valor 2
    bit<32> res;    // resultado
    //bit<48> resb;    // resultado

}

header smt_t {
    bit<7>  tmp;   //completar pacote multiplo de 8 pra compliar
    bit<9>  smt9b;      //ingress_port, egress_port, egress_spect
    bit<32> smt32b;     //instance_type,packet_lenght,enq_timestamp,deq_timedelta
    bit<48> smt48b;     //(in/egr)_global_timestamp;
}


/*
 * All headers, used in the program needs to be assembled into a single struct.
 * We only need to declare the type, but there is no need to instantiate it,
 * because it is done "by the architecture", i.e. outside of P4 functions
 */
struct headers {
    ethernet_t  ethernet;
    p4get_t     p4get;
    smt_t       smt_campos;        
}

/*
 * All metadata, globally used in the program, also  needs to be assembled 
 * into a single struct. As in the case of the headers, we only need to 
 * declare the type, but there is no need to instantiate it,
 * because it is done "by the architecture", i.e. outside of P4 functions
 */
 
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
            //P4CALC_ETYPE : check_p4calc;
            P4CALC_ETYPE : parse_p4get;
            default      : accept;
        }
    }
    
    state parse_p4get {
        packet.extract(hdr.p4get);
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
                  inout standard_metadata_t smt) {
    action send_back(bit<32> result) {
    //action send_back(bit<48> result) {
        /* TODO
         * - put the result back in hdr.p4calc.res
         * - swap MAC addresses in hdr.ethernet.dstAddr and
         *   hdr.ethernet.srcAddr using a temp variable
         * - Send the packet back to the port it came from
             by saving standard_metadata.ingress_port into
             standard_metadata.egress_spec
         */
        bit<48> tmp_mac;
        hdr.p4get.res = result;
        tmp_mac = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = hdr.ethernet.srcAddr; 
        hdr.ethernet.srcAddr = tmp_mac;
        //Diferenca entre egress_spect e egress_port?
        smt.egress_spec = smt.ingress_port;
        
  
    }
    
    // OP 0 
    action get_ingress_port() {
        //9 bits
        send_back((bit<32>)smt.ingress_port);
        //send_back((bit<48>)smt.ingress_port);
    }
    
    // OP 1
    action get_pkt_lenght() {
        //32 bits
        send_back(smt.packet_length);
        //send_back((bit<48>)smt.packet_length);
    }
    
    // OP 2
    action get_enq_timestamp() {
        //32 bits
        send_back(smt.enq_timestamp);
        //send_back((bit<48>)smt.enq_timestamp);
    }
    
    action operation_or() {
        //32 bits
        send_back(smt.packet_length);
        //send_back(smt.egress_global_timestamp);
    }

    action operation_xor() {
        send_back((bit<32>)smt.egress_port);
        //send_back(smt.ingress_global_timestamp);
    }

    action operation_drop() {
        mark_to_drop(smt);
    }
    
    table calculate {
        key = {
            hdr.p4get.op        : exact;
        }
        actions = {
            get_ingress_port;
            get_pkt_lenght;
            get_enq_timestamp;
            operation_or;
            operation_xor;
            operation_drop;
        }
        const default_action = operation_drop();
        const entries = {
            OP_0 : get_ingress_port();
            OP_1 : get_pkt_lenght();
            OP_2 : get_enq_timestamp();
            OP_3 : operation_or();
            OP_4 : operation_xor();
        }
    }
            
    apply {
        if (hdr.p4get.isValid()) {
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
        packet.emit(hdr.p4get);
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
