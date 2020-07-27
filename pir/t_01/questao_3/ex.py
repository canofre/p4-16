#!/usr/bin/env python
from mininet.net import Mininet
from mininet.cli import CLI

def mininet():
	net = Mininet() # net is a Mininet() object

	h11 = net.addHost( 'h11' ) # h1 is a Host() object
	h12 = net.addHost( 'h12' ) # h2 is a h2ost()
	h21 = net.addHost( 'h21' ) # h1 is a Host() object
	h22 = net.addHost( 'h22' ) # h2 is a h2ost()

	s1 = net.addSwitch( 's1' ) # s1 is a Switch() object
	s2 = net.addSwitch( 's2' ) # s1 is a Switch() object

	net.addLink( h11, s1 ) 
	net.addLink( h12, s1 )
	net.addLink( h21, s2 ) 
	net.addLink( h22, s2 )
	net.addLink( s1, s2 )

	net.start()
	print h11.cmd( 'ping -c1', h21.IP() )
	CLI( net )
	net.stop()



def minfor():
	net = Mininet() # net is a Mininet() object
	for x in range(1,4):
		sw=('s'+str(x))
		sw = net.addSwitch( sw )
		h1=('h'+str(x)+'1')
		h1 = net.addHost( h1 )
		h2=('h'+str(x)+'2')
		h2 = net.addHost( h2 )
		net.addLink( h1, 's'+str(x) ) 
		net.addLink( h2, 's'+str(x) ) 

	for x in range(1,3):
		net.addLink('s'+str(x),'s'+str(x+1))
		#net.addLink('s1','s2')
		#net.addLink('s2','s3')

	net.start()
	#print h11.cmd( 'ping -c1', h21.IP() )
	CLI( net )
	net.stop()


def teste():
	#do 1 ao 15
	for x in range(1,15):
		print (str(x)+'---'+str(x+1))

	# S16 - S1
	# S16 - S3
	# S3 - S14
	# do 16 ao 20
	for x in range(16,20):
		print (str(x)+'---'+str(x+1))

	# S18 - S21
	# S21 - $22

	#do 23 ao 25
	for x in [4,21,26,27,28]:
		print ('15---'+str(x))

	# S13 - S25
	# S10 - S23	


	#do 23 ao 25
	for x in range(23,25):
		print (str(x)+'---'+str(x+1))

minfor()