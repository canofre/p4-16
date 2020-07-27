#!/usr/bin/env python

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

###########################################################
# Cria todos os switches e adiciona dois hosts em cada um
for x in range(1,NUM_SW+1):
	sw=('s'+str(x))
	sw = net.addSwitch( sw )
	h1=('h'+str(x)+'1')
	h1 = net.addHost( h1 )
	h2=('h'+str(x)+'2')
	h2 = net.addHost( h2 )
	net.addLink( h1, 's'+str(x) ) 
	net.addLink( h2, 's'+str(x) ) 
	print ( 'sh ovs-ofctl add-flow  '+str(sw)+'  dl_type=0x806,nw_proto=1,action=flood')
	print ( 'sh ovs-ofctl add-flow '+str(sw)+' action=normal' )
	#######################################################

###########################################################
# Estabelece os links entre os switches 1 ao 15 em linha
for x in range(1,15):
	net.addLink('s'+str(x),'s'+str(x+1))

# Estabelece os links entre os switches 
# S16 - S1 || S16 - S3 || S3 - S14
net.addLink('s16','s1')
net.addLink('s16','s3')
net.addLink('s3','s14')

# do 16 ao 20
for x in range(16,20):
	#print (str(x)+'---'+str(x+1))
	net.addLink('s'+str(x),'s'+str(x+1))

# S18 - S21 || S21 - $22
net.addLink('s18','s21')
net.addLink('s21','s22')

#
for x in [4,21,26,27,28]:
	#print ('15---'+str(x))
	net.addLink('s15','s'+str(x))

# S13 - S25 || S10 - S23	
net.addLink('s13','s25')
net.addLink('s10','s23')
net.addLink('s23','s24')
net.addLink('s24','s25')
###########################################################


# Imprime as regras
net.start()


# print net.cmd( 'pingall' )
CLI( net )

#CLI( sh ovs-ofctl del-flows s5 )

net.stop()