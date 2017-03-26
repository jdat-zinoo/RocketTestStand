settings_handler = {
    'init': function() {
        $('#get_com_time').on('click', function() {
            console.log($(this).value);
        });
        $('#send_com_time').on('click', function() {
            console.log($(this).value);
        });
    },
    'ws_get_time': function(ch, data) {

    }
};