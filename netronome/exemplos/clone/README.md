# Exemplo de clonagem
Exemplo de implementação de clonagem utilizando SmartNics da netronome
e linguagem P4.

## Topologia

Interconexão entre dois hosts com plancas da netrome, sendo um com o código
P4 e outro utilizado com envio e recebimento de pacotes.

# Utilização
Testado somente com o envio de pacotes via sacpy para testar e demonstrar o 
funcionamento.

## Carregar o driver
Realizar o carregamento do driver e das configurações nas SmartNics no host
que receberá o código P4.

```
./script/exec.sh car clone.nffw basic.p4cfg
```

## Interfaces e script 
1. Verificar se as interfaces estão configuradas para uso com o driver da
Netronome e não para o dpdk, executando `nfp-dpdk-mg.sh ns`

2. Alterar para driver da netronome caso esteja para DPDK, executanto 
`nfp-dpdk-mg.sh [XX:XX.X] nfp`

3. Configurar rede conforme topologia.
```
ip addr add 10.0.1.10/24 dev [idt_interface]
ip addr add 10.0.4.10/24 dev [idt_interface]
ip addr show
```

4. Verificar as informações de rede no script `scripts/run.py`.
* Origen
    * ETH_SRC : nome da interface de origem 
    * IP_SRC : IP configurado na interface de origem
* Destino
    * ETH_DST : nome da interface de destino
    * IP_DST : IP configurado na interface de destino.

## Executar
Executar `./run.py s [opção]` para enviar ou receber pacotes

a) Envio de pacotes: `./run.py s numeroDePacotes opcao`.
Envia um pacote utilizando a biblioteca scapy, tendo como
base o endereço IP e o endereço MAC. O endereço MAC é obtido do nome da
interface. 

b) As opções são 10 para clonagem E2I e 20 para E2E, pacotes clonados com E2I
não necessitam ser recirculados e são contabilizados na posição 0 do 
registrador. Pacotes clonados com E2E são clonados e depois recirculados.

c) Recebimento de pacotes: `./run.py [rt|rs]`.

* `./run.py rt`: recebe pacores via tcpdum.
* `./run.py rs`: recebe os pacotes via biblioteca scapy, exibindo toda a 
extrutura do pacote recebido.

### Verificação

As opções foram verificadas com a contagem dos através de registradors, 
executando ```./script/run.sh 8 regCtrl```.
