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
  - 3.5 : 0000000000000011**0101000000000000**
  - 2.5 : 0000000000000010**0101000000000000**
  - 3.5 : 0000000000000100**1100000000000000**
