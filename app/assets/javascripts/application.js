//= require jquery
//= require jquery_ujs
//= require jquery.ui.effect.all
//= require formee
//= require jquery.timeago
//= require foundation

// Load the timeago plugin
$(document).ready(function() {
    $("time.timeago").timeago();
});

// Make the alerts fade away
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

