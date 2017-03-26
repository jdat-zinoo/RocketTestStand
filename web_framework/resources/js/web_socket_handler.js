var ws = new WebSocket(websocket_url);
var ws_handler = {
    "outbox_buffer": [],
    "status": ws.CLOSED,
    "callbacks": {},
    "unique_filter": function(value, index, self) {
        return self.indexOf(value) === index;
    },
    "register": function(keys, callback) {
        for (var i=0; i < keys.length; i++) {
            if (keys[i] in ws_handler["callbacks"]) {
                ws_handler["callbacks"][keys[i]].push(callback);
            } else {
                ws_handler["callbacks"][keys[i]] = [callback]
            }
            var unique = ws_handler["callbacks"][keys[i]].filter(ws_handler["unique_filter"]);
            ws_handler["callbacks"][keys[i]] = unique;
        }
    },
    "remove": function(key, callback) {
        if(key in ws_handler["callbacks"]) {
            var index = ws_handler["callbacks"][key].indexOf(callback);
            if (index > -1) {
                ws_handler["callbacks"][key].splice(index, 1);
            }
        };
    },
    "new_msg": function(evt) {
        obj = JSON.parse(evt.data);
        if(obj['ch'] in ws_handler["callbacks"]) {
            for (var i=0; i < ws_handler["callbacks"][obj['ch']].length; i++) {
                ws_handler["callbacks"][obj['ch']][i](obj['ch'], obj['data']);
            }
        };
    },
    "send_msg": function(key, data) {
        var msg = JSON.stringify({
            "action": key,
            "args": data
        });
        if (ws_handler["status"] == ws.OPEN) {
            ws.send(msg);
        } else {
            ws_handler["outbox_buffer"].push(msg);
        }
    },
    "onclose": function(evt) {
        ws_handler["status"] = ws.CLOSED;
    },
    "onopen": function(evt) {
        ws_handler["status"] = ws.OPEN;
        for (var i=0; i < ws_handler["outbox_buffer"].length; i++) {
            ws.send(ws_handler["outbox_buffer"][i]);
        }
        ws_handler["outbox_buffer"] = [];
    }
}

ws.onclose = ws_handler["onclose"];
ws.onopen = ws_handler["onopen"];
ws.onmessage = ws_handler["new_msg"];
