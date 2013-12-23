//= require jquery
//= require jquery_ujs
//= require jquery.ui.effect.all
//= require jquery.cookie

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

$(document).ready(function() {
    if(is_logged_in && ! is_red_team) {
        checkMessages();
        setInterval(checkMessages, 30*1000);
    }
    setInterval(checkDaemonStatus, 30*1000);
});

function checkMessages() {
    $.ajax({
        url: '/messages.json'
    }).done(function(data) {
        if(data.inbox && data.inbox > 0) {
            $('#messages_link').addClass('new_messages');
        }
    });
}

function checkDaemonStatus() {
    $.ajax({
        url: '/daemon_status.json'
    }).done(function(data) {
        if(data.daemon_running) {
            $('.top-bar #text').addClass('running');
            $('.top-bar #text').removeClass('not-running');
        } else {
            $('.top-bar #text').addClass('not-running');
            $('.top-bar #text').removeClass('running');
        }
    });
}
