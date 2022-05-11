## Introdução

Aplicações para execução nas SmartNICs da netronome, modelo Agilio CX NFP-4000.

- [Monitoramento de link](./src/lmpp): realiza o envio de um pacote 
personalizado (probe) e recolhe informações de porta de entrada, porta
de saida e timestamp, pelo caminho que for definido no pacote inicial.
Utiliza a biblioteca scrapy para realizar a manipulação de pacotes.

- [Emcapsulamento de informação](./lm_embeded): TODO: realizar a 
captura de  informações no próprio pacote que está circulando, 
encapsulando as informações no incício do percurso e removendo antes 
de ser encaminhada ao fina. 

- [Exemplos](./exemplos): aplicações simples que exemplificam 
funcionamentos básicos como encaminhamento, registradores, 
recirculação.


