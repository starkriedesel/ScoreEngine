$(document).ready(function() {
    if(actionName == 'edit' || actionName=='update')
    {
        getServiceParams();
        $('#service_worker').change(getServiceParams);
    }
    if(actionName == 'index' || actionName == 'show')
    {
        setInterval(updateService, 30*1000);
    }
});

// Used by Services#index
function duplicate_service(service_id, team_id, service_name) {
    $('#duplicateModal #service_name').html("'"+service_name+"'");
    $('#duplicateModal #service_id').val(service_id);
    $('#duplicateModal #team_id').val(team_id);
    $("#duplicateModal").reveal();
}

// Used by Services#index and Services#show
function updateService() {
    var service_id = $('#service_id').val();
    var last_log_id = $('#last_log_id').val();
    var url = '';

    if(service_id) {
        if(! last_log_id) // There should always be both or neither
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

// Used by Services#index
function updateProgressBar(id, value) {
    $('#'+id+' .meter').animate({width:''+value+'%'}, 500);
    $('#'+id+' .text').html(''+value+'%');
}

// Used by Services#index and Services#show
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

// Used by Services#show
function toggleLogDebug(tag) {
    $(tag).parents('.service-log').find('.debug').toggle();
}

// Used by Services#edit
function getServiceParams()
{
    var service_id = $('#service_id').val();
    var speed = 500;
    var worker_name = $('#service_worker').val();
    var new_param_html = $('#params-'+worker_name);

    var fadeOut = function() {
        $('#service-params').animate({height: new_param_html.height()}, speed*2);
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