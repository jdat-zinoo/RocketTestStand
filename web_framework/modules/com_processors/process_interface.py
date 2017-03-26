from abc import ABCMeta, abstractmethod


class ComProcessInterface:

    __metaclass__ = ABCMeta

    @abstractmethod
    def start(self, msg):
        pass

    @abstractmethod
    def process(self, msg):
        pass

    @abstractmethod
    def force_stop(self):
        pass

    @abstractmethod
    def get_name(self):
        pass
