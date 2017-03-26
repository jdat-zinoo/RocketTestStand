import zmq
import random
import sys
import time

port = "5556"
context = zmq.Context()
socket = context.socket(zmq.PAIR)
socket.bind("tcp://*:%s" % port)

while True:
    socket.send("LIST")
    i = 0
    print 'test'
    while i < 100:
        msg = socket.recv()
        print msg
        i += 1
    time.sleep(1)