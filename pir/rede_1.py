from mininet.net import Mininet
from mininet.cli import CLI
net = Mininet() # net is a Mininet() object

#print net.cmd('mn -c')

# Cria N switches
# 16:1 - 16 Vermelho
# 09:17 -25 Azul
# 01:26		Amarelo escure
# 02:27 -28 Amarelo claro
NUM_SW=28

for x in range(1,NUM_SW+1):
	sw=('s'+str(x))
	sw = net.addSwitch( sw )

for x in range(1,NUM_SW+1):
	h1=('h'+str(x)+'1')
	h1 = net.addSwitch( h1 )
	h2=('h'+str(x)+'2')
	h2 = net.addSwitch( h2 )
	net.addLink( h1, 's'+str(x) ) 
	net.addLink( h2, 's'+str(x) ) 

# estabelece os links dos switches 1 ao 13 em linha
for x in range(1,13):
	print(x)
	net.addLink('s'+str(x),'s'+str(x+1))

net.addLink(s13,s15)
net.addLink(s14.s3)
net.addLink(s15,s16)
net.addLink(s15.s3)
net.addLink(s16.s4)
# Até aqui toda rede vermelha esta ok

net.start()

# print net.cmd( 'pingall' )
CLI( net )
