//= require jquery
//= require jquery_ujs
//= require jquery.ui.effect.all
//= require jquery.cookie

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
    $.ajax({
        url: '/client_update/poll.json'
    }).done(function(data) {
        if(data)
            clientPollComplete(data);
    });
}
function clientPollComplete(data) {

    if(data.new_inbox && data.new_inbox > 0) {
        $('#messages_link').addClass('new_messages');
    }
    if(data.daemon_running) {
        $('.top-bar .name').addClass('running');
        $('.top-bar .name').removeClass('not-running');
    } else {
        $('.top-bar .name').addClass('not-running');
        $('.top-bar .name').removeClass('running');
    }
}