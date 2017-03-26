from serial_port_interface import SerialPortInterface
import zmq


class ZmqComSimulator(SerialPortInterface):

    def __init__(self, port="5556"):
        context = zmq.Context.instance()
        self.socket = context.socket(zmq.PAIR)
        self.socket.bind("tcp://*:%s" % port)

    def read(self):
        return self.socket.recv()

    def send(self, msg):
        self.socket.send_string(msg)