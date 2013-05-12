// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require foundation
//= require formee
//= require jquery.timeago

$(document).ready(function() {
    $('#global_alert').delay(5000).animate({opacity: 0}, 1500, 'swing')
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

$(document).ready(function() {
    $('.optional').each(function (i,tag) {
        $(tag).find('.content').toggle($(tag).find('.optional_toggle').val() == '1');
    })
});

function perform_optional(tag, action)
{
    var fieldset = $(tag).parents('.optional');
    var content = fieldset.find('.content');
    var toggle = fieldset.find('.optional_toggle');
    if(action == 'toggle')
    {
        var state = perform_optional(tag, 'get');
        perform_optional(tag, state ? 'hide' : 'show');
        return ! state;
    }
    else if(action == 'show' || action == 'hide')
    {
        var new_sate = action == 'show';
        toggle.val(new_sate ? 0 : 1);
        if(new_sate)
            content.show(400);
        else
            content.hide(400);
        return new_sate;
    }
    else
        return content.is(':visible') ? true : false;
}

function toggle_optional(tag)
{
    perform_optional(tag, 'toggle');
}

function get_optional_state(tag)
{
    return perform_optional(tag, 'get');
}

function show_optional(tag)
{
    perform_optional(tag, 'show');
}

function hide_optional(tag)
{
    perform_optional(tag, 'hide');
}

function getServiceParams()
{
    var service_id = $('#service_id').val();
    var speed = 500;
    var worker_name = $('#service_worker').val();
    var new_param_html = $('#params-'+worker_name);
    var old_div_height = $('#service-params').height();

    var fadeOut = function() {
        $('#service-params').animate({height: new_param_html.height()}, speed*2);
        var oldSpans = $('#service-params').children(':visible');
        if(oldSpans.length > 0)
            oldSpans.fadeOut(speed, fadeIn);
        else
            fadeIn();
    }

    var fadeIn = function() {
        new_param_html.fadeIn(speed);
    };

    // Do not fade in if already visible
    if(new_param_html.filter(':visible').length > 0)
    {
        var oldSpans = $('#service-params').children(':visible').hide();
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

    return 1;
}

$(document).ready(function() {
    getServiceParams();
    $('#service_worker').change(getServiceParams);
});

function toggleLogDebug(tag) {
    $(tag).parents('.service-log').find('.debug').toggle();
}

$(document).ready(function() {
    $("time.timeago").timeago();
});

function changeStatusClass(selector, classname) {
    var header_classes = ['off', 'error', 'running', 'down'];
    var highlight_colors = ['#d8d8d8','#E8C48F','#CFE9AF','#CC473E']
    var n = $.inArray(classname, header_classes);
    if(n<0)
    alert("BAD CLASS");
    if(n < 0 || selector.hasClass(classname))
        return;
    header_classes.splice(n,1);
    for(i=0; i<header_classes.length; ++i)
        selector.removeClass(header_classes[i]);
    selector.addClass(classname);
    selector.children('a').effect("highlight",{color: highlight_colors[n]},1000);
}

function updateProgressBar(id, value) {
    $('#'+id+' .meter').animate({width:''+value+'%'}, 500);
    $('#'+id+' .text').html(''+value+'%');
}

function updateService() {
    var service_id = $('#service_id').val();
    var last_log_id = $('#last_log_id').val();
    var url = '';

    if(service_id) {
        if(! last_log_id)
            return;
        url = '/services/'+service_id+'/status/'+last_log_id+'.json';
    }
    else {
        url = '/services/status.json';
    }

    $.ajax({
        url: url
    }).done(function(data) {

        // Only for Services#show page
        if(service_id) {
            // Change header colors
            changeStatusClass($('header#titlebar'), data.header_class);

            // Prepend HTML for logs to #service_log
            $('#service_logs').prepend(data.log_html);

            // Update the last log id
            if(data.last_log_id > 0)
                $('#last_log_id').val(data.last_log_id);

            // Update uptime
            updateProgressBar('up_time', data.uptime)

        // Only for Services#index page
        } else {
            // Update Team Uptimes
            for(var i=0; i<data.team_uptime.length; i++) {
                if(data.team_uptime[i].id == null)
                    team_id = '';
                else
                    team_id = data.team_uptime[i].id;
                updateProgressBar('uptime'+team_id, data.team_uptime[i].uptime);
            }
        }

        // Update Service List
        for(var i=0; i<data.service_list.length; i++) {
            changeStatusClass($('#service'+data.service_list[i].id), data.service_list[i].status_class);
        }
    });
}