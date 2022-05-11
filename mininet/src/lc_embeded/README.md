# Link Monitor Embeded - lm_embeded

A intenção cosiste em realizar o envio de um pacote para rede, onde os dados são 
encapsulados a partir do momento que entra no primeiro switch e desencapsulado
quando chega no switch final antes de ser entregue ao host.

Inicilamente a configuração realizada consiste em dois hosts interligados por
dois switches, sendo realizado o encapsulamento de um pacote no S1 e
desencapsulado no S2 antes de ser entregue ao destino.

Essa modificações são realizadas ainda de forma estática para o modelo criado,
sendo a intenção a modificação desse ambiente para ser utilizado de forma
dinâmica em uma rede cuja topolodia é desconhecida.


