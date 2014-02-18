//= require jquery
//= require jquery_ujs
//= require jquery.ui.effect.all
//= require jquery.cookie
//= require highcharts
//= require chartkick
//= require graphing

// Load foundation
$(document).ready(function() { $(document).foundation(); });

// Make the alerts fade away
$(document).ready(function() {
    $('#global_alert').delay(5000).slideUp({duration: 1500});
});

// resize divs dynamically on load
//  wrap divs in .do_resize(X/Y)
//  identify div to match as .resize_to(X/Y)
//  identify div to change as .resize_from(X/Y)
//  where (X/Y) indicates if it should be width(X) or height(Y)
$(document).ready(function() {
    $('.do_resizeY').each(function() {
        var resize_height = $(this).find('.resize_toY').first().height();
        $(this).find('.resize_fromY').height(resize_height);
    });
    $('.do_resizeX').each(function() {
        var resize_width = $(this).find('.resize_toX').first().width();
        $(this).find('.resize_fromX').width(resize_width);
    });
});

// Poll for client update
//  All ajax updates should be done here
$(document).ready(function() {
    if(is_logged_in)
        setInterval(clientPoll, 30*1000); // every 30 seconds
});
function clientPoll() {
    var service_id = $('#service_id').val();
    var last_log_id = $('#last_log_id').val();
    if(service_id == undefined && controllerName == 'services' && actionName == 'index')
        service_id = 0;

    var url = '/client_update/poll.json?x=1';
    if(service_id != undefined)
        url += '&service_id='+service_id;
    if(last_log_id != undefined)
        url += '&last_log_id='+last_log_id;

    $.ajax({
        url: url
    }).done(function(data) {
        if(data)
            clientPollComplete(data);
    });
}
function clientPollComplete(data) {
    var this_service_id = $('#service_id').val();

    if(data.new_inbox && data.new_inbox > 0)
        $('#messages_link').addClass('new_messages');
    else
        $('#messages_link').removeClass("new_messages");
    if(data.daemon_running) {
        $('.top-bar .name').addClass('running');
        $('.top-bar .name').removeClass('not-running');
    } else {
        $('.top-bar .name').addClass('not-running');
        $('.top-bar .name').removeClass('running');
    }w
    if(data.service_list) {
        // Update title bar if we know about this service
        if(this_service_id != undefined && this_service_id in data.service_list)
            changeStatusClass($('header#titlebar'), status_class[data.service_list[this_service_id]]);

        // Update status classes and images for all known services
        $.each(data.service_list, function(service_id, status_code) {
            $('#overviewIcon'+service_id).attr('src',status_img[status_code]);
            changeStatusClass($('#service'+service_id), status_class[status_code]);
        });

        // Update service logs
        if(data.service_logs_html)
        {
            $.each(data.service_logs_html, function(index, log){
                $('#service_logs').prepend(log);
            });
        }

        // Update last service log id
        if(data.last_service_log_id)
            $('#last_log_id').val(data.last_service_log_id);

        // Update service uptime
        if(data.service_uptime)
            updateProgressBar('up_time', data.service_uptime);

        // Update team uptimes
        if(data.team_uptime)
            $.each(data.team_uptime, function(team_id, team_uptime) {
                if(team_id == null)
                    team_id = '';
                updateProgressBar('uptime'+team_id, team_uptime);
            });
    }
}
// Used by clientPollComplete
function changeStatusClass(selector, new_class) {
    // Remove the classes which we don't want
    $.each(status_class, function(status_name, status_class) {
        if(status_class != new_class)
            selector.removeClass(status_class);
    });

    // Don't continue if we already are of this class
    if(selector.hasClass(new_class))
        return;

    // Add the class
    selector.addClass(new_class);

    // Make sure to flash
    selector.addClass('flash');
}
// Used by clientPollComplete
function updateProgressBar(id, value) {
    $('#'+id+' .meter').animate({width:''+value+'%'}, 500);
    $('#'+id+' .text').html(''+value+'%');
}

// Used by Services#show
function toggleLogDebug(tag) {
    $(tag).parents('.service-log').find('.debug').toggle();
}

// Used by Services#edit
$(document).ready(function() {
    if(actionName == 'edit' || actionName=='update' || actionName == 'new' || actionName == 'create') {
        getServiceParams();
        $('#service_worker').change(getServiceParams);
    }
});
function getServiceParams()
{
    var service_id = $('#service_id').val();
    var speed = 500;
    var worker_name = $('#service_worker').val();
    var new_param_html = $('#params-'+worker_name);

    var fadeOut = function() {
        $('#service-params').animate({height: new_param_html.height()-40}, speed*2);
        var oldSpans = $('#service-params').children(':visible');
        if(oldSpans.length > 0)
            oldSpans.fadeOut(speed, fadeIn);
        else
            fadeIn();
    };

    var fadeIn = function() {
        new_param_html.fadeIn(speed);
    };

    // Do not fade in if already visible
    if(new_param_html.filter(':visible').length > 0)
    {
        new_param_html.show();
        return;
    }

    if(new_param_html.length <= 0)
    {
        $.ajax({
            url: service_id ? '/services/'+service_id+'/edit' : '/services/new',
            data: {worker_name: worker_name}
        }).done(function(data){
                $('#service-params').append(data);
                new_param_html = $('#params-'+worker_name);
                new_param_html.hide();
                fadeOut();
            });
    }
    else
        fadeOut();
}