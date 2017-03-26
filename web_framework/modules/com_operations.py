import time
import multiprocessing

from com_processors.list_processor import ListProcess
from file_manager import FileManager
from modules.com_processors.delete_com_processor import DeleteComFileProcess
from modules.com_processors.delete_local_processor import DeleteLocalFileProcess
from modules.com_processors.get_file_processor import GetFileProcess
from modules.zmq_com_simulator import ZmqComSimulator
import config


class ComOperations(multiprocessing.Process):

    def __init__(self, input_queue, output_queue, debug=False):
        multiprocessing.Process.__init__(self)
        self.current_processor = None
        self.status_buffer = None
        self.last_send = time.time()
        self.input_queue = input_queue
        self.output_queue = output_queue
        self.launch_buffer = []
        self.debug = debug

    def run(self):
        self.com = ZmqComSimulator()
        self.file_manager = FileManager(self.input_queue)
        self.com_processors = {
            'LIST': ListProcess(self.com, self.file_manager, self.output_queue),
            'CAT': GetFileProcess(self.com, self.file_manager, self.output_queue),
            'DEL_COM': DeleteComFileProcess(self.com, self.file_manager, self.output_queue),
            'DEL_LOCAL': DeleteLocalFileProcess(self.file_manager, self.output_queue)
        }
        self.main_loop()

    def main_loop(self):
        while True:
            self.__clear_buffers()
            self.__process_status_messages()
            self.__process_input_queue()

    def __process_status_messages(self):
        msg = str(self.com.read())
        if msg.startswith('S'):
            self.status_buffer = msg[1:]
        elif msg.startswith('R'):
            self.__start_launch_subroutine(msg)

    def __start_launch_subroutine(self, first_value):
        self.output_queue.put({'ch': 'launch_detected', 'data': 'start'})
        msg = first_value
        while msg.startswith('R'):
            self.launch_buffer.append({'x':msg[1:5], 'y':msg[5:]})
            if len(self.launch_buffer) > 100:
                self.__clear_launch_buffer()
            msg = str(self.com.read())
        self.__clear_launch_buffer()
        self.output_queue.put({'ch': 'launch_detected', 'data': 'end'})

    def __clear_launch_buffer(self):
        self.output_queue.put({'ch': 'launch_data', 'data': self.launch_buffer})
        self.launch_buffer = []

    def __process_input_queue(self):
        if not self.input_queue.empty():
            command = self.input_queue.get()
            self.__initialise_processor(command['action'], command['args'])

    def __initialise_processor(self, action_name, args):
        self.current_processor = self.com_processors[action_name].start(args)
        while self.current_processor:
            msg = self.com.read()
            if msg == config.BREAK_TRANSFER_CHAR:
                self.current_processor.force_stop()
                self.current_processor = None
            elif self.__is_noise(msg):
                continue
            else:
                self.current_processor = self.current_processor.process(msg)

    def __clear_buffers(self):
        if time.time() - self.last_send >= config.SEND_EVERY:
            self.output_queue.put({'ch': 'live_data', 'data': {
                'status': self.status_buffer
            }})
            self.last_send = time.time()

    def __is_noise(self, msg):
        if str(msg).startswith('S') and len(msg) == 5:
            return True
        else:
            return False