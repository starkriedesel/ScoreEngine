//= require jquery.min
//= require jquery_ujs
//= require twitter/bootstrap
//= require underscore
//= require backbone
//= require jquery.knob
//= require AdminLTE
//= require knobify
//= require highcharts
//= require chartkick

//= require init
//= require models/team
//= require models/service
//= require models/graph_data
//= require views/overview.coffee
//= require views/menu.coffee
//= require views/service_details.coffee

/*$(function() {knobify();});

// Ajax Data
var teams = null;
var services = null;

// Service Details
var service_details_tab = null;
var service_details_messages = {};

// Templates
var templates = {
  'teamOverview': null,
  'serviceOverview': null,
  'serviceMenu': null,
  'serviceDetails': null
};

function loadTemplates() {
  $.each(templates, function(id, template) {
    var obj = $('#'+id+'Template');
    if(template === null && obj.length != 0)
      templates[id] = Handlebars.compile(obj.html());
  });
}

function statusNameToId(status_name) {
  var ret = null;
  $.each(status_names, function(id, name) {
    if(status_name == name)
      ret = id;
  });
  return ret;
}

function retrieveTeams(callback) {
  $.ajax({
    url: '/teams.json'
  }).done(function(data){
    var teams = {};

    for(var i=0; i<data.length; ++i) {
      var team = data[i];

      teams[team.id] = team;
    }

    callback(teams);
  });
}

function retrieveServices(callback) {
  $.ajax({
    url: '/services.json'
  }).done(function(data){
    var services = {};

    for(var i=0; i<data.length; ++i)
    {
      var service = data[i];
      services[service.id] = service;
    }

    callback(services);
  });
}

function servicesByTeam(services) {
  var services_by_team = {};
  $.each(services, function(id, service) {
    if(! services_by_team.hasOwnProperty(service.team_id))
        services_by_team[service.team_id] = [];
      services_by_team[service.team_id].push(service);
  });
  return services_by_team;
}

function getTeamName(team) {
  if(team === null)
    return team_id;
  if(team === undefined || team.name === undefined)
    return '?';
  else
    return team.name;
}

function serviceClass(service) {
  if(! service || ! service.on)
    return status_classes[-1];
  return status_classes[service.last_status];
}

function replaceServiceClass(obj, service) {
  $.each(status_classes, function(n,c) { if(service.last_status != n) obj.removeClass(c); });
  obj.addClass(serviceClass(service));
  knobify(obj);
}

function updateScoreboardServices() {
  retrieveTeams(function(_teams) {
    teams = _teams;

    $.each(teams, function(team_id, team) {
      if($('#serviceOverviewTeam'+team.id).length == 0)
        $('#serviceOverview').append(templates.teamOverview({team: team}));
    });

    retrieveServices(function(_services) {
      services = _services;
      var services_by_team = servicesByTeam(services);

      $.each(services_by_team, function(team_id, team_services) {
        $.each(team_services, function(i, service) {
          var team = teams[team_id] || {name: '?', id: team_id};
          service.percentage = Math.floor((service.run_logs / service.total_logs) * 100);

          // service overview
          var obj = $('#serviceMark'+service.id);
          if(obj.length == 0) {
            $('#serviceOverviewTeam'+team.id).append(templates.serviceOverview({service: service, team: team}));
            obj = $('#serviceMark'+service.id);
          }
          else {
            obj.find('input.knob').val(service.percentage).trigger('change');
          }
          replaceServiceClass(obj, service);

          // service menu
          obj = $('#serviceMenu'+service.id);
          if(obj.length == 0) {
            $('#serviceMenu ul').append(templates.serviceMenu({service: service, team: team}));
            obj = $('#serviceMenu'+service.id);
          }
          replaceServiceClass(obj, service);
        }); // each team_services
      }); // each team

      // service buttons
      $('#serviceOverview .service a').off('click').on('click',function() {
        var service_id = $(this).data('service-id');
        var service = services[service_id];
        $('#serviceDetails').html(templates.serviceDetails({service: service, team: teams[service.team_id]}));
        $('#serviceDetails').show();
        service_details_messages = {};

        $('#serviceDetails a[data-toggle="tab"]').off('shown.bs.tab').on('shown.bs.tab', function(e) {
          service_details_tab = $(e.target).attr('href');
          $(e.target.hash).parents('.row').find('.message').html('');
          loadGraph(e.target.hash);
        });
        $('#refreshGraphBtn').off('click').on('click',function() {
          loadGraph('#serviceDetails .graph-area:visible', true);
        });
        if(service_details_tab == null) {
          $('#serviceDetails a:first').tab('show');
        } else {
          $('#serviceDetails a[href='+service_details_tab+']').tab('show');
        }
      });

    }); // retrieveServices
  }); // retrieveTeams
};

function loadGraph(obj,reload) {
  if(obj.constructor === String)
    return loadGraph($(obj),reload);
  if(obj.length == 0)
    return;
  if(! obj.hasClass('graph-area'))
    return loadGraph(obj.find('.graph-area'),reload);

  if(obj.attr('id') !== undefined && service_details_messages.hasOwnProperty(obj.attr('id')))
    obj.parents('.row').find('.message').html(service_details_messages[obj.attr('id')]);

  if(reload !== true && obj.find('div').length > 0)
    return;

  // Give object a unique id (if it doesn't have one)
  if(obj.attr('id') === undefined)
    obj.attr('id', guid());

  // Get graph data
  $.ajax({
    url: obj.data('graph-url')
  }).done(function(data) {
    var graph_data = data.graph;
    var options = data.options;
    var type = obj.data('graph-type');

    if(type == 'pie') {
      // Use the right colors
      var status_colors = {'-1': 'grey', '0': 'green', '1': 'red', '2': 'orange', '3': 'orange'};
      var colors = [];
      if(options.statuses !== undefined)
        $.each(options.statuses, function(i, x) {
          colors.push(status_colors[x]);
        });
      new Chartkick.PieChart(obj[0], graph_data, {colors: colors});
    }
    else
      new Chartkick.LineChart(obj[0], graph_data, {});

    var intervalText = '';
    if(options.interval !== undefined)
      intervalText = (data.options.interval / 60) +' minute intervals';
    if(options.window != undefined)
      intervalText += ' (' + options.window + ' interval average)'
    obj.parents('.row').find('.message').html(intervalText);
    service_details_messages[obj.attr('id')] = intervalText;
  });
}

function guid() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
    return v.toString(16);
  });
}

$(loadTemplates);

$(updateScoreboardServices);

$(function(){
  $('#overview-change').on('click', function() {
    $('#serviceOverview').toggleClass('show-knob');
  });
});

$(function() {$('#serviceDetails').hide();});*/
