var graph_handler = {
    'current_type': 'line',
    'live_data_id': -1,
    'download_file': function(filename) {
        $.ajax({
            type: "GET",
            url: "static/files/" + filename,
            dataType: "text",
            success: function (data) { graph_handler.process_csv_file(filename, data); }
        });
    },
    'process_csv_file': function(filename, data) {
        var file_lines = data.split('\n');
        if (file_lines.length > 0) {
            var dataPoints = [];
            for(var i = 1; i < file_lines.length; i++) {
                var rowData = file_lines[i].split(',');
                if(rowData.length > 0) {
                    dataPoints.push({
                        x: i,
                        y: parseInt(rowData[1])
                    });
                }
            }
            dps.push({
                'type': graph_handler['current_type'],
                'showInLegend': true,
                'name': filename,
                'dataPoints': dataPoints
            });
        }
    },
    'add_file': function(filename) {
        var found = false;
        for (var i = 0; i < dps.length; i++) {
            if (dps[i]['name'] == filename) {
                found = true;
                break;
            }
        }
        if(!found) {
            graph_handler['download_file'](filename);
        }
    },
    'remove_file': function(filename) {
        for (var i = 0; i < dps.length; i++) {
            if (dps[i]['name'] == filename) {
                dps.splice(i, 1);
                break;
            }
        }
    },
    'init': function() {
        $('.js_chart_type').on('click', function() {
		    graph_handler['current_type'] = $(this).data('value');
		    for (var i = 0; i < dps.length; i++) {
			    dps[i].type = graph_handler['current_type'];
		    }
		    chart.render();
	    });
    },
    'open': function() {
        chart.render();
    },
    'rocket_launch_started': function() {
        live_data_points = [];
        if(graph_handler['live_data_id'] == -1) {
            graph_handler['live_data_id'] = dps.length;
        }
        dps[graph_handler['live_data_id']] = {
            'color': 'red',
            'type': graph_handler['current_type'],
            'showInLegend': true,
            'name': 'Live data',
            'dataPoints': live_data_points
        }
       $('.btn-nav[data-nav_id="nav_graph"]').trigger( "click" );
    },
    'rocket_launch_data': function(data) {
        for (var i = 0; i < data.length; i++) {
            live_data_points.push({
                x: parseInt(data[i]['x']),
                y: parseInt(data[i]['y'])
            });
        }
        chart.render();
    },
    'rocket_detection_ws': function(ch, data) {
        if(data == 'end') {
            console.log('end');
        } else if(data == 'start') {
            graph_handler['rocket_launch_started']();
        }
    },
    'rocket_data_ws': function(ch, data) {
        graph_handler['rocket_launch_data'](data);
    }
};