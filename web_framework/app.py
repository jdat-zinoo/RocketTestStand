import Queue
import json
import multiprocessing

import sys
import uuid

import config
import sass
import modules.js_render as js_render
import tornado.ioloop
import tornado.web
import tornado.autoreload
import tornado.template
import tornado.websocket
from multiprocessing import Queue
import fnmatch
import os

from modules.com_operations import ComOperations

clients = {}
outbox_queue = Queue()
inbox_queue = Queue()


class MainHandler(tornado.web.RequestHandler):
    def get(self):
        views = json.load(open(os.path.join(os.getcwd(), config.VIEW_REGISTRY)))
        self.render("main.html", views=views, websocket_url="ws://localhost:8888/ws")


class WSHandler(tornado.websocket.WebSocketHandler):
    def open(self):
        self.uid = uuid.uuid4()
        clients[self.uid] = self

    def on_message(self, message):
        obj = json.loads(message)
        print obj
        outbox_queue.put(obj)

    def on_close(self):
        del clients[self.uid]

settings = {
    "static_path": os.path.join(os.path.dirname(__file__), "static"),
    "template_path": os.path.join(os.getcwd(), config.TEMPLATE_BASE_DIR)
}


def make_app():
    return tornado.web.Application([
        (r"/", MainHandler),
        (r'/ws', WSHandler),
        (r"/(favicon\.png)", tornado.web.StaticFileHandler, dict(path=settings['static_path'])),
    ], **settings)


def send_to_all():
    while not inbox_queue.empty():
        msg = json.dumps(inbox_queue.get())
        for client in clients.values():
            client.write_message(msg)

if __name__ == "__main__":
    com_manager = ComOperations(outbox_queue, inbox_queue, config.DEBUG)
    com_manager.start()
    app = make_app()
    app.listen(8888)
    if config.DEBUG:
        sass.compile(dirname=(config.SASS_DIR, config.SASS_OUTPUT_DIR), source_comments=True)
        js_render.render()
        tornado.autoreload.start()
        for root, dirnames, filenames in os.walk('resources'):
            for filename in fnmatch.filter(filenames, '*'):
                print filename
                tornado.autoreload.watch(os.path.join(root, filename))
    tornado.ioloop.PeriodicCallback(send_to_all, 500).start()
    tornado.ioloop.IOLoop.current().start()