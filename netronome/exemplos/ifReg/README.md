# Execução de if com registradores
Documentação e referências [neste repsitório](https://github.com/canofre/alfarrabios/blob/master/mestrado/nfp/registradores.md).

## Execução

A cada 5 pacotes enviados é realizada a clonagem de um pacote do 
Egress para o Egress. A verificação pode ser realizada tanto pela 
exibição dos valores armazenados nos registradores, com ```./scripts/reg.sh 8 regR1``` 
como pela vefificação dos valores registrados nos contadores da placa.

Os arquivos de configuração utilizam uma comunicação com outro host 
(configFisica.p4cfg) ou as interfaces virtuais do host (configVirtual.p4cfg)

O envio de pacotes é realizado com o comando ```./scripts/run.py s 1 1``` que envia um pacote por vez.
