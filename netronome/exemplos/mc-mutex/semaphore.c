#include <nfp.h>
#include <stdint.h>
#include <nfp/me.h>
#include <nfp/mem_atomic.h>
#include "pif_plugin.h"

/* To semaphore */
__declspec(emem export aligned(64)) int my_semaphore = 1;
__declspec(shared scope(global) export imem) uint32_t pacotes;
__declspec(shared scope(global) export imem) uint32_t clonados;
__declspec(shared scope(global) export imem) uint32_t janela;
//volatile __export __mem uint32_t janela = 0;


void semaphore_down(volatile __declspec(mem addr40) void * addr) {
	/* semaphore "DOWN" = claim = wait */
	unsigned int addr_hi, addr_lo;
	__declspec(read_write_reg) int xfer;
	SIGNAL_PAIR my_signal_pair;

	addr_hi = ((unsigned long long int)addr >> 8) & 0xff000000;
	addr_lo = (unsigned long long int)addr & 0xffffffff;
    
    do {
         xfer = 1;
         __asm {
             mem[test_subsat, xfer, addr_hi, <<8, addr_lo, 1], \
                 sig_done[my_signal_pair];
             ctx_arb[my_signal_pair]
         }
     } while (xfer == 0);
}

void semaphore_up(volatile __declspec(mem addr40) void * addr) {
    /* semaphore "UP" = release = signal */
    unsigned int addr_hi, addr_lo;
    __declspec(read_write_reg) int xfer;
     addr_hi = ((unsigned long long int)addr >> 8) & 0xff000000;
    addr_lo = (unsigned long long int)addr & 0xffffffff;

    __asm {
        mem[incr, --, addr_hi, <<8, addr_lo, 1];
    }
}

int pif_plugin_semaphore(EXTRACTED_HEADERS_T *hdr, MATCH_DATA_T *meta){
    
    PIF_PLUGIN_ipv4_T *ipv4 = pif_plugin_hdr_get_ipv4(hdr);
    PIF_PLUGIN_apf_T *apf = pif_plugin_hdr_get_apf(hdr);
    __xwrite uint32_t reset = 0;
    __xread uint32_t xr;

  
    semaphore_down(&my_semaphore);
    mem_incr32((__mem40 void*)&pacotes);
    mem_incr32((__mem40 void*)&janela);
    mem_read_atomic(&xr,(__mem40 void*)&janela,sizeof(xr));
    if (xr == 20000000 ){
        ipv4->diffServ = 200;
        mem_write_atomic(&reset,(__mem40 void*)&janela,sizeof(uint32_t));

        mem_incr32((__mem40 void*)&clonados);

    }
    PIF_HEADER_SET_apf___janela(apf, pacotes);   
    PIF_HEADER_SET_apf___janela(apf, janela);   
    PIF_HEADER_SET_apf___clonados(apf, clonados);   
    semaphore_up(&my_semaphore);

    

    return PIF_PLUGIN_RETURN_FORWARD;
}

int pif_plugin_semaphore2(EXTRACTED_HEADERS_T *hdr, MATCH_DATA_T *meta){
    
    PIF_PLUGIN_ipv4_T *ipv4 = pif_plugin_hdr_get_ipv4(hdr);
    PIF_PLUGIN_apf_T *apf = pif_plugin_hdr_get_apf(hdr);
    
    unsigned int i=1;
    mem_add32_imm(i,(__mem40 void*)&pacotes);
    PIF_HEADER_SET_apf___pacotes(apf, pacotes);   

    mem_add32_imm(i,(__mem40 void*)&janela);
  
    semaphore_down(&my_semaphore);
    if (janela == 20000000 ){
        janela =0;
    }
    //janela = janela+1;
    PIF_HEADER_SET_apf___janela(apf, janela);   
    semaphore_up(&my_semaphore);
    

    return PIF_PLUGIN_RETURN_FORWARD;
}
