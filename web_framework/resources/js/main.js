var dps = [];
var chart = {};
var live_data_points = [];


$( document ).ready(function() {

    chart = new CanvasJS.Chart('chartContainer', {
        zoomEnabled: true,
        title: {
            text: "Rocket data"
        },
        axisX: {
            labelAngle: 30
        },
        axisY: {
            includeZero: true
        },
        data: dps,
        legend: {
            horizontalAlign: "right", // left, center ,right
            verticalAlign: "top",  // top, center, bottom
            fontSize: 13,
            cursor: "pointer",
            itemclick: function (e) {
                if (typeof(e.dataSeries.visible) === "undefined" || e.dataSeries.visible) {
                    e.dataSeries.visible = false;
                } else {
                    e.dataSeries.visible = true;
                }
                chart.render();
            }
        }
    });


    // Test
    function testCallback(key, data) {
        console.log(key, data);
    }

    /*
        Available channels
        live_data
        launch_detected
        launch_data
        filesystem_update

        Available actions
        LIST
    */
//    ws_handler["register"](["live_data"], testCallback);
    ws_handler['register'](['filesystem_update'], filesystem_handler['ws_handler']);
    ws_handler['register'](['launch_detected'], graph_handler['rocket_detection_ws']);
    ws_handler['register'](['launch_data'], graph_handler['rocket_data_ws']);
    filesystem_handler['init']();
    graph_handler['init']();
    settings_handler['init']();
//    ws_handler["remove"]("test", testCallback);

    var active_nav = 'nav_filesystem';
    $('.btn-nav[data-nav_id="' + active_nav + '"]').addClass('active');
    filesystem_handler['open']();

    // Navigation over views
    $(".btn-nav").on("click", function() {
        $("#footer").css("padding-top", "0px");
        var selected = $(this);
        $('.btn-nav[data-nav_id="' + active_nav + '"]').removeClass('active');
        $('#' + active_nav).hide();
        selected.addClass('active');
        active_nav = selected.data('nav_id');
        $('#' + active_nav).show();
        switch(active_nav) {
            case 'nav_filesystem':
                filesystem_handler['open']();
                break;
            case 'nav_graph':
                graph_handler['open']();
        };
    });
});