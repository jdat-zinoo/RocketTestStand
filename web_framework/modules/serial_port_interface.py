from abc import ABCMeta, abstractmethod


class SerialPortInterface:

    __metaclass__ = ABCMeta

    @abstractmethod
    def send(self, msg):
        pass

    @abstractmethod
    def read(self):
        pass