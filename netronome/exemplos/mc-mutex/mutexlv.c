#include <nfp.h>
#include <mutexlv.h>
#include <stdint.h>
#include <nfp/me.h>
#include <nfp/mem_atomic.h>
#include "pif_plugin.h"

__declspec(shared scope(global) export emem) uint32_t pacotes; 
__declspec(shared scope(global) export emem) uint32_t clonados;
__declspec(shared scope(global) export emem) uint32_t janela;

/* Mutex */
typedef volatile __shared __gpr unsigned int MUTEXLV;
MUTEXLV lock=0;

int pif_plugin_mutex(EXTRACTED_HEADERS_T *hdr, MATCH_DATA_T *meta){
    
    PIF_PLUGIN_ipv4_T *ipv4 = pif_plugin_hdr_get_ipv4(hdr);
    PIF_PLUGIN_apf_T *apf = pif_plugin_hdr_get_apf(hdr);
    __xwrite uint32_t reset = 0;
    __xread uint32_t xr;

    MUTEXLV_lock(lock,1);

    mem_incr32((__mem40 void*)&pacotes);
    mem_incr32((__mem40 void*)&janela);
    mem_read_atomic(&xr,(__mem40 void*)&janela,sizeof(xr));
    if (xr == 20000000){
        mem_incr32((__mem40 void*)&clonados);
        ipv4->diffServ = 200;
        mem_write_atomic(&reset,(__mem40 void*)&janela,sizeof(uint32_t));
    }
    
    MUTEXLV_unlock(lock,1);
    
    apf->clonados = clonados;
    apf->pacotes=pacotes;
    
    return PIF_PLUGIN_RETURN_FORWARD;
}
