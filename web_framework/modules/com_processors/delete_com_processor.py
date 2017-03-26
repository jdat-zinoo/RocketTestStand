from process_interface import ComProcessInterface


class DeleteComFileProcess(ComProcessInterface):

    def __init__(self, com_port, file_manager, web_socket_queue):
        self.com_port = com_port
        self.file_manager = file_manager
        self.web_socket_queue = web_socket_queue
        self.filename = ''

    def process(self, msg):
        if str(msg).startswith('DEL error'):
            self.web_socket_queue.put({'ch': 'com_error', 'data': msg})
            return None
        else:
            self.web_socket_queue.put({
                'ch': 'filesystem_update',
                'data': {
                    'type': 'com_deleted',
                    'filename': self.filename
                }})
            return None

    def get_name(self):
        return "DEL_COM"

    def start(self, filename):
        self.com_port.send('DEL %s'%filename)
        self.filename = filename
        return self

    def force_stop(self):
        pass