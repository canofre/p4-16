from mininet.net import Mininet
from mininet.cli import CLI

net = Mininet() # net is a Mininet() object
h1 = net.addHost( 'SP_h1' ) # h1 is a Host() object
h2 = net.addHost( 'SP_h2' ) # h2 is a Host()

SP1 = net.addSwitch( 'SP1' ) # s1 is a Switch() object

net.addLink( h1, SP1 ) # creates a Link() object
net.addLink( h2, SP1 )
net.start()

print h1.cmd( 'ping -c1', h2.IP() )
CLI( net )
net.stop() 