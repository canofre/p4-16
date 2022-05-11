# Tratamento te concorrencia

Ambas somente funcionam com a adição das opções ```-u 1 -A 5``` no 
momento da complitação. 

## Implementação de MUTEX

Exemplo de duas implementações de mutex

1. mutex.c : implementação de mutex por conta própria
2. mutexlc.c : implementação de mutex com a biblioteca mutexlv.h


O uso do mutex implica em uma perda de dezempenho de aparentemente 
90%, visto que em uma execução do MoonGen com 120 segundos são 
enviados 1.7 bilhões de pacotes, ao passo que com o uso do mutex se 
aproxima dos 180 milhões.


## Semaphore

O arquivo semaphore.c codifica a este tipo de bloqueio, conforme 
demonstrado no artigo **The Joy of Micro-C**. Porém, apresnta um 
desempenho inferior ainda ao mutex, transferindo certa de 100 milhões
de pacotes no período de 120 segunfos.

