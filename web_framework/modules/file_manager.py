import os
import config


class FileManager(object):

    def __init__(self, com_queue):
        self.com_queue = com_queue
        self.storage = os.path.join(os.getcwd(), config.LOCAL_FILE_STORAGE)
        self.files_waiting_download = []
        self.files_available = []

    def check_missing_files(self, com_port_file_list):
        self.files_available = os.listdir(self.storage)
        com_port_file_names = [item[0] for item in com_port_file_list]
        self.files_waiting_download = list(set(com_port_file_names) - set(self.files_available))
        view = self.__add_to_file_view({}, self.files_available, 'available', com_port_file_names)
        view = self.__add_to_file_view(view, self.files_waiting_download, 'downloading', com_port_file_names)
        self.__download_missing()
        return view

    def __add_to_file_view(self, view, subject, status, com_port_file_list):
        for filename in subject:
            view[filename] = {
                'status': status,
                'com_storage': filename in com_port_file_list
            }
        return view

    def __download_missing(self):
        for missing_file in self.files_waiting_download:
            self.com_queue.put({'action': 'CAT', 'args': str(missing_file)})

    def save_file(self, filename, data):
        f_handler = open(os.path.join(self.storage, filename), 'wb')
        f_handler.write(data)
        f_handler.flush()
        f_handler.close()

    def delete_file(self, filename):
        f_path = os.path.join(self.storage, filename)
        if os.path.isfile(f_path):
            os.remove(f_path)
            return True
        else:
            return False