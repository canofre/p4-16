from mininet.net import Mininet
from mininet.cli import CLI
net = Mininet() # net is a Mininet() object

h11 = net.addHost( 'h11' ) # h1 is a Host() object
h21 = net.addHost( 'h21' ) # h2 is a Host()

s1 = net.addSwitch( 's1' ) # s1 is a Switch() object

net.addLink( h11, s1 ) # creates a Link() object
net.addLink( h21, s1 )

net.start()
print h11.cmd( 'ping -c1', h21.IP() )
CLI( net )
net.stop()