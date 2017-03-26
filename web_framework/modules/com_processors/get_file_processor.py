from process_interface import ComProcessInterface
import config


class GetFileProcess(ComProcessInterface):

    def __init__(self, com_port, file_manager, web_socket_queue):
        self.com_port = com_port
        self.file_manager = file_manager
        self.web_socket_queue = web_socket_queue
        self.filename = ''
        self.file_buffer = ''
        self.download_active = False

    def process(self, msg):
        if self.download_active:
            if msg == str(config.EOF_CHAR):
                self.file_manager.save_file(self.filename, self.file_buffer)
                self.web_socket_queue.put({
                    'ch': 'filesystem_update',
                    'data': {
                        'type': 'download_finished',
                        'filename': self.filename
                    }
                })
                return None
            else:
                self.file_buffer += msg
                return self
        else:
            if str(msg).startswith('CAT error'):
                self.web_socket_queue.put({'ch': 'com_error', 'data': msg})
                return None
            else:
                self.download_active = True
                return self

    def get_name(self):
        return "CAT"

    def start(self, filename):
        self.com_port.send('CAT %s'%filename)
        self.filename = filename
        self.file_buffer = ''
        self.download_active = False
        return self

    def force_stop(self):
        self.file_buffer = ''
