#include <nfp.h>
#include <stdint.h>
#include <nfp/me.h>
#include <nfp/mem_atomic.h>
#include "pif_plugin.h"

__declspec(shared scope(global) export emem) uint32_t pacotes; 
__declspec(shared scope(global) export emem) uint32_t clonados;
__declspec(shared scope(global) export emem) uint32_t janela;
volatile __export __mem uint32_t lock = 0;

int pif_plugin_mutex(EXTRACTED_HEADERS_T *hdr, MATCH_DATA_T *meta){
    
    PIF_PLUGIN_ipv4_T *ipv4 = pif_plugin_hdr_get_ipv4(hdr);
    PIF_PLUGIN_apf_T *apf = pif_plugin_hdr_get_apf(hdr);

    __xwrite uint32_t reset = 0;
    __xread uint32_t xr;
    __xrw uint32_t xfer = 1;
    
    while (xfer == 1 ){
        mem_test_set(&xfer,(__mem40 void*)&lock,sizeof(xfer));
        if ( xfer == 0) { break; } //locked
        sleep(200);
    }

    mem_add32_imm(apf->latencia,(__mem40 void*)&latSoma);
    mem_incr32((__mem40 void*)&pacotes);
    mem_incr32((__mem40 void*)&janela);
    mem_read_atomic(&xr,(__mem40 void*)&janela,sizeof(xr));
    
    if (xr == 20000000){
        mem_incr32((__mem40 void*)&clonados);
        ipv4->diffServ = 200;
        mem_write_atomic(&reset,(__mem40 void*)&janela,sizeof(uint32_t));
    }
    xfer = 0;
    mem_write_atomic(&xfer,(__mem40 void*)&lock,sizeof(xfer));
    
    PIF_HEADER_SET_apf___pacotes(apf, pacotes);   
    PIF_HEADER_SET_apf___clonados(apf, clonados);   

    return PIF_PLUGIN_RETURN_FORWARD;
}
