# Multiplicação e divsão de reais

# Intenção
- Realizar a multiplicação de números reais utilização a representação de ponto
fixo.

# Possibilidades

## Número real pelo scapu
- Passar o numero real pelo scapy, o que está apresentando erro nos tipos de 
campos do scapy

## Passar real já convertido
- passar o numero real já convertido em bit, tipo com 8 bits 3,5 (0011.0101) e
2,5 (0010.0101) assim 3.5x2.5=8.74 (1000.1100) 
- usando 64 bits, 32.32 (int.fração) a dúvida é se faz diferença ou se é regra
fazer scaling up com:
 - 16 bits pq é metade dos 32 da parte inteira, ou
 - 32 bits pq não faz diferença

- Representação com 32 bits pra facilitar verificação:
  - 0000000000000010**1000000000000000** > a = 2.5
  - 0000000000000011**1000000000000000** > b = 3.5
  - 0000000000000100**1100000000000000** > a*b = 8.5

## Resultados:
- tmp =(bit<32>)(((bit<64>)a  * (bit<64>)b) / (1 << 16)); :
  - 0000000000001000**1100000000000000** 
- tmp =(a  * b) / (1 << 16); : 0000000000000000**1100000000000000**
- tmp =(a  * b) / (1 << 8);  : 0000000011000000**0000000000000000**  
- bit<32> a2 = a << 16; & bit<32> b2 = b << 16; : zero em todas 
