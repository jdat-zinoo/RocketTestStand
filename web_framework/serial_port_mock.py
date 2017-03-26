import random

import zmq
import config
import os
import time, datetime



class InputCommands(object):

    commands = {
        'LIST': 'list_command',
        'DEL': 'del_command',
        'CAT': 'cat_command',
        'TIME': 'time_command',
        'DEV_START': 'simulate_rocket_launch',
    }

    def __init__(self, mock_filesystem, send_message):
        self.mock_filesystem = mock_filesystem
        self.send_message = send_message
        self.time_diff = 0
        self.time_format = "%Y-%m-%d %H:%M:%S %w"

    def list_command(self):
        files = os.listdir(self.mock_filesystem)
        self.send_message('LIST ' + str(len(files)))
        for filename in files:
            stats = os.stat(os.path.join(self.mock_filesystem, filename))
            last_access = datetime.datetime.fromtimestamp(stats.st_atime).strftime("%Y.%m.%d. %H:%M:%S")
            self.send_message("%s %d %s"%(filename, stats.st_size, last_access))
        self.send_message(str(config.EOF_CHAR))

    def file_error_check(self, prefix, filename):
        path = os.path.join(self.mock_filesystem, filename)
        if filename == 'sd_error.txt':
            self.send_message(prefix + ' error: SD failed')
            return True
        elif os.path.isfile(path):
            return False
        else:
            self.send_message(prefix + ' error: no file')
            return True

    def del_command(self, filename):
        if not self.file_error_check('DEL', filename):
            os.remove(os.path.join(self.mock_filesystem, filename))
            self.send_message('DEL ' + filename + str(config.NEW_LINE_CHAR))

    def cat_command(self, filename):
        if not self.file_error_check('CAT', filename):
            full_file_path = os.path.join(self.mock_filesystem, filename)
            self.send_message('CAT ' + str(os.stat(full_file_path).st_size))
            lines = open(full_file_path).readlines()
            for line in lines:
                self.send_message(str(line))
            self.send_message(config.EOF_CHAR)

    def get_time_as_string(self):
        current_time = time.time() + self.time_diff
        return datetime.datetime.fromtimestamp(current_time).strftime(self.time_format)

    def time_command(self, param=None):
        if param == None:
            self.send_message(self.get_time_as_string())
        else:
            try:
                new_time = datetime.datetime.strptime(param, self.time_format)
                self.time_diff = time.mktime(new_time.timetuple()) - time.time()
                self.send_message(self.get_time_as_string())
            except ValueError, e:
                self.send_message('T error: incorrect date')

    def process_message(self, msg):
        commands = msg.split(' ', 1)
        callable_method = getattr(self, self.commands[commands[0]])
        if len(commands) == 2:
            callable_method(commands[1])
        else:
            callable_method()


class SerialPortMock(object):

    def __init__(self):
        self.context = zmq.Context()
        self.socket = self.context.socket(zmq.PAIR)
        self.socket.connect(config.SERIAL_PORT_MOCK_ADDRESS)
        self.input_cmd = InputCommands(os.path.join(os.getcwd(), 'mock_filesystem'), self.send_message)
        self.last_launch = time.time()
        self.launch_circle = 30

    def loop(self):
        while True:
            try:
                message = self.socket.recv(flags=zmq.NOBLOCK)
                self.input_cmd.process_message(message)
            except zmq.Again as e:
                self.send_message('S%04d' % (random.randint(0, 9999)))
                if self.launch_circle + self.last_launch <= time.time():
                    print 'Start'
                    for i in range(0, 10000):
                        self.send_message('R%04d%04d' % (i, random.randint(0, 9999)))
                        time.sleep(.001)
                    self.last_launch = time.time()

    def send_message(self, msg):
        self.socket.send(str(msg))


if __name__ == '__main__':
    serial_port_mock = SerialPortMock()
    serial_port_mock.loop()

