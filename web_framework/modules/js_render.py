import config
import json, os
from jsmin import jsmin


class JSRender(object):

    def __init__(self, js_registry, js_storage_dir, js_output_dir):
        self.buffer = {}
        self.__registry = {}
        self.js_registry = js_registry
        self.js_storage_dir = js_storage_dir
        self.js_output_dir = js_output_dir

    def render(self):
        self.__load_registry()
        self.__process_registry()
        self.__flush_buffer()

    def __load_registry(self):
        self.__registry = json.load(open(os.path.join(os.getcwd(), self.js_registry)))

    def __process_registry(self):
        for output_file, js_files in self.__registry.iteritems():
            self.__registry[output_file] = ""
            for js_file in js_files:
                js_string = open(os.path.join(os.getcwd(), self.js_storage_dir, js_file)).read()
                self.__registry[output_file] += jsmin(js_string, quote_chars="'\"`")

    def __create_output_dir(self):
        output_dir = os.path.join(os.getcwd(), self.js_output_dir)
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        return output_dir

    def __flush_buffer(self):
        output_dir = self.__create_output_dir()
        for filename, content in self.__registry.iteritems():
            with open(os.path.join(output_dir, filename), "wb") as f:
                f.write(content)
                f.flush()
                f.close()
        self.__registry = {}



def render():
    render_engine = JSRender(config.JS_REGISTER, config.JS_DIR, config.JS_OUTPUT)
    render_engine.render()
