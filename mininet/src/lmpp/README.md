# Adaptação do exercício Link Monitoring do tutorial do p4lang 

## Introdução

Programa para testar a coleta de informações nas SmartNICs Agilio CX NFP-4000.
Inicialmente buscando as informações de portas de entrada e saida e o ID o dispositivo.


``` 
// Top-level probe header, indicates how many hops this probe
// packet has traversed so far. 
header probe_t {
    bit<8>  hop_cnt;
}

// The data added to the probe by each switch at each hop.
header probe_data_t {
    bit<1>  bos;
    bit<7>  swid;
    bit<8>  port_ig;
    bit<8>  port_eg;    
}

// Indicates the egress port the switch should send this probe
// packet out of. There is one of these headers for each hop.
// Add the op field.
header probe_fwd_t {
    bit<8>  egress_spec;
}
```



