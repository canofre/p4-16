/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;

/*********************************************************************
*********************** H E A D E R S  *******************************
*********************************************************************/

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

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
}

/*********************************************************************
*********************** P A R S E R  *********************************
*********************************************************************/

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

/* 
* Esse bloco e sequencia, sendo necessario que os elementos chamados
* estejam descritos antes da sua chamada
*/
control MyIngress(inout headers hdr,inout metadata meta,inout standard_metadata_t smt) {
        
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

/*********************************************************************
****************  E G R E S S   P R O C E S S I N G   ****************
*********************************************************************/

control MyEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t smt) {
    
    /* counter([TAMANHO], [TIPO]) [nome] */ 
    counter(2,CounterType.packets) pkt;
    

    /*Cria um registrador de 64 bits com duas posi��es*/
    register<bit<64>>(2) reg_tmp;  
    register<bit<64>>(2) portas;  

    bit<64> count_tmp;
    
    apply {  
        /* 
         * Incrementa o total de pacotes utilizando como indice os 
         * valores das portas de entrada e saida. Essa manipula��o 
         * atualiza tamb�m os valores dos contadores obtidos atrav�s 
         * com comando rtecli 
         */ 
        pkt.count((bit<32>)smt.ingress_port);
        pkt.count((bit<32>)smt.egress_port);

        /* 
         * Le o valor contido na posi��o indicada pela porta de 
         * entrada, armazeando na variavel count_tmp e incrementa 
         * esse contador, inserindo o valor atualizado no registrador.
         */         
        reg_tmp.read(count_tmp,(bit<32>)smt.ingress_port);
        count_tmp=count_tmp+1;        
        reg_tmp.write((bit<32>)smt.ingress_port,count_tmp);

        /* 
         * Le o valor contido na posi��o indicada pela porta de sa�da,
         * armazeando na variavel count_tmp e incrementa esse 
         * contador, inserindo o valor atualizado no registrador. 
         */         
        reg_tmp.read(count_tmp,(bit<32>)smt.egress_port);
        count_tmp=count_tmp+1;        
        reg_tmp.write((bit<32>)smt.egress_port,count_tmp);

        portas.write(0,(bit<64>)smt.ingress_port);
        portas.write(1,(bit<64>)smt.egress_port);

        /*
         * Com essa implementa��o dos registradores e poss�vel 
         * verificar as quantidades de pacotes enviados e recebidos 
         * em cada placa, conferindo com os contadores.
         */

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
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch( MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser() ) main;
