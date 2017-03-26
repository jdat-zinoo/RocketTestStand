from process_interface import ComProcessInterface


class DeleteLocalFileProcess(ComProcessInterface):

    def __init__(self, file_manager, web_socket_queue):
        self.file_manager = file_manager
        self.web_socket_queue = web_socket_queue

    def process(self, msg):
        pass

    def get_name(self):
        return "DEL_LOCAL"

    def start(self, filename):
        if self.file_manager.delete_file(filename):
            self.web_socket_queue.put({
                'ch': 'filesystem_update',
                'data': {
                    'type': 'local_deleted',
                    'filename': filename
                }})
        return None

    def force_stop(self):
        pass