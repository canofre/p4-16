P4_16

P4 Get

Modificacao do programa P4Calc disponibilizado nas documentacoes do git do P4.org, para testar a recuperacao das informacoes de statament_metadata.

Removidos os campos versao e o numero 4, mantendo o mesmo Ethertype 0x1234. Alteradas as opcoes de escolha para numeracao decimal. 

Adicionado um campo de resposta de 48 bits para testar as respostas de timestamp que possuem este tamanho e ajustadas as respostas do campos
menores (9,16,19.. bits) para serem convertidas para a resposta no campo de 32 bits.

O header do protocolo ficou montado como segue:

             0                1                  2              3
       +----------------+----------------+----------------+---------------+
       |      p         |       Op       |          res 32 bit
       +----------------+----------------+----------------+---------------+
                                          |                                
       +----------------+----------------+----------------+---------------+
                                  res48 - 48 bits                          |
       +----------------+----------------+----------------+---------------+
               
P is an ASCII Letter 'C' (0x64)
Op is an operation to Perform:
  '0' = ingress_port
  '1' = egress_port
  '2' = packet_lenght
  '3' = enq_timestamp
  '4' = enq_qdepth 
  '5' = ing_global_tmp
  '6' = eg_global_tmp 

The device receives a packet, performs the requested operation, fills in the result and sends the packet back out of the same port it came in on, while 
swapping the source and destination addresses.

If an unknown operation is specified or the header is not valid, the packet is dropped 

