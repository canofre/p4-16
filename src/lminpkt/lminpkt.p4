/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_IPV6 = 0x86DD;

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t; 
typedef bit<32> ip4Addr_t;

const MAX_HOPS=10;

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

header coletor_t {
    bit<4>  hops;
    bit<4>  swid;
    bit<64> tmp;
}

struct metadata {
    /* empty */
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
                inout standard_metadata_t standard_metadata) {

    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            //TYPE_IPV4: parse_ipv4;
            TYPE_IPV4: parse_coletor;
            default: accept; 
        }
    }
    
    state_parse_coletor{
		packet.extract (hdr.coletor);
        transition select(hdr.coletor.last.hops){
            //TYPE_IPV4: parse_ipv4;
            TYPE_IPV4: parse_coletor;
            default: parse_coletor; 

    }
    state parse_ipv4 {
		// Extrai do pacote de entrada o tipo ipv4 para o headers hdr
		packet.extract (hdr.ipv4);
		// Termina a execucao do parser atual e passa para o proximo estado 
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

/* Esse bloco e sequencia, sendo necessario que os elementos chamados estejam
 * descritos antes da sua chamada
*/
control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    
    //Acao definida para a tabela ipv4
    action drop() {
        mark_to_drop(standard_metadata);
    }
    
    //Acao definida para a tabela ipv4
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    /* Indica que sera consultado o Ip destido via lpm e define as acoes 
     * possiveis. A defincao da acao a ser tomada e na tabela definiada nos 
     * arquivos JSON. Se existir uma correspondencia uma acao e definida
     * caso nao exista correspondencia uma ação default é realizada. Caso não
     * seja definida a ação default, nenhuma ação é realizada.
    */
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
/* Bloco de controle da saída do pacote. Esta diretamente ligado ao bloco
 * MyEgress pois as saídas do MyIngress são as entradas do MyEgress. 
 * No caso esse bloco não realiza nenhuma acao, apenas da sequencia ao fluxo
*/
control MyEgress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
     apply {  }
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
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch( MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;
