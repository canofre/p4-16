# Aplicações de exemplo
Aplicações para documentar o funcionamento básico de algumas implementações, 
com a documentação necessária para entendimento.

## Exempĺos

Exemplos de aplicações para execução nas SmartNICs da netronome, modelo Agilio CX NFP-4000.

- [Encaminhamento simples](./basic): realiza o encaminhamento simples de pacotes.
  funcionalidades da netronome, tal como uma documentação/tutorial.
    
- [Registradores](./registrador): demonstra a implementação de registradores e
contadores, com envio de pacotes via scapy/python e análise dos valores com um 
script shell que obtem as informações através do `rtecli`

- [Recirculação](./recircular): uso da primitiva recirculate() através da
  recirculação de um pacote tantas vezes quando for indicado na tabela de regras.


