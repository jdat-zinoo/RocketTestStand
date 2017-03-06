import json
import config
import sass
import modules.js_render as js_render
import tornado.ioloop
import tornado.web
import tornado.autoreload
import tornado.template
import tornado.websocket
import fnmatch
import os


class MainHandler(tornado.web.RequestHandler):
    def get(self):
        views = json.load(open(os.path.join(os.getcwd(), config.VIEW_REGISTRY)))
        self.render("main.html", views=views, websocket_url="ws://localhost:8888/ws")


class WSHandler(tornado.websocket.WebSocketHandler):
    def open(self):
        self.write_message(json.dumps({'key': 'test', 'data': 'connected'}))

    def on_message(self, message):
        obj = json.loads(message)
        print obj
        print 'Incoming message:', obj['key'], obj['data']
        self.write_message(json.dumps({'key': 'test', 'data': obj['data']}))

    def on_close(self):
        print 'Connection was closed...'

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


if __name__ == "__main__":
    sass.compile(dirname=(config.SASS_DIR, config.SASS_OUTPUT_DIR), source_comments=True)
    js_render.render()
    app = make_app()
    app.listen(8888)
    tornado.autoreload.start()
    for root, dirnames, filenames in os.walk('resources'):
        for filename in fnmatch.filter(filenames, '*'):
            print filename
            tornado.autoreload.watch(os.path.join(root, filename))
    tornado.ioloop.IOLoop.current().start()
