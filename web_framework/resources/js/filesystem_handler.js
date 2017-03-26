var filesystem_handler = {
    'activated_checkboxes': [],
    'templates': {
        'new_file': '<tr data-filename="{{ filename }}"> \
                <td>{{ filename }}</td> \
                <td class="status_msg">{{ status }}</td> \
                <td class="add_to_graph">{{ &add_to_graph_btn }}</td> \
                <td class="local_file_actions">{{ &buttons }}</td> \
                <td class="com_file_actions">{{ &com_status }}</td> \
            </tr>',
        'buttons': '<div class="btn-group"> \
                <a type="button" class="btn btn-success" href="/static/files/{{ filename }}" download="{{filename}}">Download</a> \
                <button type="button" class="btn btn-success dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"> \
                    <span class="caret"></span> \
                    <span class="sr-only">Toggle Dropdown</span> \
                </button> \
                <ul class="dropdown-menu"> \
                    <li><a href="#" data-delete_filename="{{ filename }}">Delete file</a></li> \
                </ul> \
            </div>',
        'graph_check_box': '<label class="switch"> \
                <input data-draw_file="{{ filename }}" type="checkbox" {{ selected }}> \
                <div class="slider round"></div> \
            </label>'
    },
    'new_file': function(filename, attributes) {
        var file_data = {
            'filename': filename,
            'status': attributes.status,
            'add_to_graph_btn': function() {
                if(attributes.status == 'available') {
                    data = {
                        'selected': $.inArray(filename, filesystem_handler['activated_checkboxes']) > -1 ? 'checked' : '',
                        'filename': filename
                    }
                    return Mustache.render(filesystem_handler['templates']['graph_check_box'], data)
                } else {
                    return '&nbsp;'
                }
            },
            'com_status': function() {
                if(attributes.com_storage) {
                    return '<button data-com_delete="'+filename+'" class="btn btn-danger">Delete from Propeller</button>'
                } else {
                    return '&nbsp;'
                }
            },
            'buttons': function() {
                if(attributes.status == 'available') {
                    return Mustache.render(filesystem_handler['templates']['buttons'], {'filename': filename});
                } else {
                    return '&nbsp;'
                }
            }
        }
        $('#file_table').append(Mustache.render(filesystem_handler['templates']['new_file'], file_data));
    },
    'add_buttons': function(filename) {
        $('tr[data-filename="' + filename + '"] td.local_file_actions')
        .html(Mustache.render(filesystem_handler['templates']['buttons'], {'filename': filename}));
        $('tr[data-filename="' + filename + '"] td.status_msg').text('available');
        data = {
            'selected': $.inArray(filename, filesystem_handler['activated_checkboxes']) > -1 ? 'checked' : '',
            'filename': filename
        }
        $('tr[data-filename="' + filename + '"] td.add_to_graph')
        .html(Mustache.render(filesystem_handler['templates']['graph_check_box'], {'selected': data}));
    },
    'remove_file_if_empty': function(filename) {
        var has_local = $('tr[data-filename="' + filename + '"] td.local_file_actions').text();
        var has_com = $('tr[data-filename="' + filename + '"] td.com_file_actions').text();
        if(!has_local.trim() && !has_com.trim()) {
            $('tr[data-filename="' + filename + '"]').remove();
        }
    },
    'remove_com_button': function(filename) {
        $('tr[data-filename="' + filename + '"] td.com_file_actions').html('&nbsp;');
        filesystem_handler.remove_file_if_empty(filename);
    },
    'remove_local_button': function(filename) {
        $('tr[data-filename="' + filename + '"] td.local_file_actions').html('&nbsp;');
        $('tr[data-filename="' + filename + '"] td.status_msg').text('COM only');
        filesystem_handler.remove_file_if_empty(filename);
    },
    'init': function() {
        $(document).on('click', 'a[data-delete_filename]', function() {
            ws_handler["send_msg"]("DEL_LOCAL", $(this).data('delete_filename'));
        });
        $(document).on('click', 'button[data-com_delete]', function() {
            ws_handler["send_msg"]("DEL_COM", $(this).data('com_delete'));
        });
        $(document).on('click', 'input[data-draw_file]', function() {
            draw_file = $(this).data('draw_file');
            in_array = $.inArray(draw_file, filesystem_handler['activated_checkboxes']);
            if(in_array == -1) {
                filesystem_handler['activated_checkboxes'].push(draw_file);
                console.log('test');
                graph_handler['add_file'](draw_file);
            } else {
                filesystem_handler['activated_checkboxes'].splice(draw_file, 1);
                console.log('removing');
                graph_handler['remove_file'](draw_file);
            }
        });
    },
    'open': function() {
        $('#file_table').find("tr:gt(0)").remove();
        ws_handler["send_msg"]("LIST", null);
    },
    'ws_handler': function(ch, data) {
        switch (data.type) {
            case 'list':
                console.log(data);
                $.each(data.files, function(filename, data) {
                    filesystem_handler['new_file'](filename, data);
                });
                break;
            case 'download_finished':
                filesystem_handler.add_buttons(data['filename']);
                break;
            case 'local_deleted':
                filesystem_handler.remove_local_button(data['filename']);
                break;
            case 'com_deleted':
                filesystem_handler.remove_com_button(data['filename']);
                break;
        };
    }
};