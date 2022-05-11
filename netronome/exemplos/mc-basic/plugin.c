#include <nfp.h>
#include <stdint.h>
#include <nfp/me.h>
#include "pif_plugin.h"
/* Biblioteca para funcoes de memoria e atomicidade*/
#include <nfp/mem_atomic.h>

/* Formas de declarar qual memoria sera utilziada */
/*
struct metricas {
    uint32_t count;
};
__declspec(shared scope(global) export emem) struct metricas  metricas;
*/
//__declspec(shared scope(global) export emem) uint32_t count;
//__declspec(shared emem export scope(global)) uint32_t count;
//__declspec(emem export scope(global)) uint32_t count;

int pif_plugin_ttlLoop(EXTRACTED_HEADERS_T *hdr, MATCH_DATA_T *meta){
    // Declara um ponteiro para o header p4
    PIF_PLUGIN_ipv4_T *ipv4;
    int i;
    // Inicializa um ponteiro para o header do P4 
    ipv4 = pif_plugin_hdr_get_ipv4(hdr);

    //Manupula os valores do header 
    ipv4->ttl = ipv4->diffServ;
    for (i=1;i<10;i++){
        ipv4->ttl++;
    }

    // Indica que o pacote deve ser dropado no processamento futuro
    //return PIF_PLUGIN_RETURN_DROP;
    // Permite que o pacote continue a ser processado
    return PIF_PLUGIN_RETURN_FORWARD;
}

int pif_plugin_metricas(EXTRACTED_HEADERS_T *hdr, MATCH_DATA_T *meta){
    
    PIF_PLUGIN_apf_T *apf = pif_plugin_hdr_get_apf(hdr);
    apf->transporte = apf->transporte +1;
    
    return PIF_PLUGIN_RETURN_FORWARD;
}


