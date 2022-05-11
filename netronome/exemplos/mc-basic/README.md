# P4 e C Sandbox
Exemplo basico de implementação de P4 com C Sandbox

## Descrição
- interconexão entre dois hosts com plancas da netrome, sendo um com o 
código P4 e outro utilizado com envio e recebimento de pacotes.
- testado somente com o envio de pacotes via sacpy para testar e 
demonstrar o funcionamento.
- topologia :
```
 H1-P0<-------->SERVER-P0
 H1-P1<-------->SERVER-P3
```
- Carregar o driver
```
./script/exec.sh car cSandox.nffw config.p4cfg
```
- Compilar e carregar
```
./script/exec.sh comp config.p4cfg
```

## Interfaces e script 
1. Verificar se as interfaces estão configuradas para uso com o driver da
Netronome e não para o dpdk, executando `nfp-dpdk-mg.sh ns`

2. Alterar para driver da netronome caso esteja para DPDK, executanto 
`nfp-dpdk-mg.sh [XX:XX.X] nfp`

3. Configurar rede conforme topologia.
```
ip link set [idt_interface] down
ip addr add 10.0.1.10/24 dev [idt_interface]
ip addr add 10.0.4.10/24 dev [idt_interface]
ip link set [idt_interface] up
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
1. Executar em H1 `./scripts/run.py s [pkts] [diffServ]` para enviar 
pacotes. A opção [diffServ] é o valor enviado neste campo.
2. Executar no sever `./scripts/reg.sh 8 regR1` para ver os valores. A
posição 0 recebe 10 e a posição 1 recebe 137 que foram definidos no fonte
**plugin.c**.

