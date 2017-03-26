from process_interface import ComProcessInterface
import config


class ListProcess(ComProcessInterface):

    def __init__(self, com_port, file_manager, web_socket_queue):
        self.buffer = []
        self.first_line = None
        self.com_port = com_port
        self.file_manager = file_manager
        self.web_socket_queue = web_socket_queue

    def process(self, msg):
        print msg
        if not self.first_line:
            self.first_line = msg
        elif msg == str(config.EOF_CHAR):
            filesystem = self.file_manager.check_missing_files(self.buffer)
            self.web_socket_queue.put({'ch': 'filesystem_update', 'data': {'type': 'list', 'files':filesystem}})
            return None
        else:
            self.buffer.append(msg.split(' ', 2))
        return self

    def get_name(self):
        return "LIST"

    def start(self, __):
        self.buffer = []
        self.first_line = None
        self.com_port.send('LIST')
        return self

    def force_stop(self):
        pass