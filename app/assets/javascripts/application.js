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
//= require_tree ./foundation/
//= require formee
//= require jquery.timeago

// resize divs dynamically on load
//  wrap divs in .do_resize(X/Y)
//  identify div to match as .resize_to(X/Y)
//  identify div to change as .resize_from(X/Y)
//  where (X/Y) indicates if it should be width(X) or height(Y)
$(function() {
    $('.do_resizeY').each(function() {
        var resize_height = $(this).find('.resize_toY').first().height();
        $(this).find('.resize_fromY').height(resize_height);
    });
    $('.do_resizeX').each(function() {
        var resize_width = $(this).find('.resize_toX').first().width();
        $(this).find('.resize_fromX').width(resize_width);
    });
});

$(function() {
    $('.optional').each(function (i,tag) {
        $(tag).find('.content').toggle($(tag).find('.optional_toggle').val() == '1');
    })
});

function toggle_optional(tag)
{
    var fieldset = $(tag).parents('.optional');
    var content = fieldset.find('.content');
    var toggle = fieldset.find('.optional_toggle');
    toggle.val(content.is(':visible') ? 0 : 1);
    content.toggle(400);
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

$(function() {
    getServiceParams();
    $('#service_worker').change(getServiceParams);
});

function toggleLogDebug(tag) {
    $(tag).parents('.service-log').find('.debug').toggle();
}

$(document).ready(function() {
    $("time.timeago").timeago();
});

function updateService() {
    var service_id = $('#service_id').val();
    var last_log_id = $('#last_log_id').val();
    var header_classes = ['off', 'error', 'running', 'down'];
    if(! service_id || ! last_log_id)
        return;
    $.ajax({
        url: '/services/'+service_id+'/newlogs/'+last_log_id+'.json'
    }).done(function(data) {
        // Change header colors
        for(i=0; i<header_classes.length; ++i)
            $('header#titlebar').removeClass(header_classes[i]);
        if($.inArray(data.header_class, header_classes) >= 0)
            $('header#titlebar').addClass(data.header_class);

        // Prepend HTML for logs to #service_log
        $('#service_logs').prepend(data.log_html);

        // Update the last log id
        if(data.last_log_id > 0)
            $('#last_log_id').val(data.last_log_id);

        // Update uptime
        //$('#up_time .meter').width(''+data.up_time+'%');
        $('#up_time .meter').animate({width:''+data.up_time+'%'}, 500)
        $('#up_time .text').html(''+data.up_time+'%')
    });
}