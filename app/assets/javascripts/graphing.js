function loadGraph(section_id) {
    var graphSection = $('#'+section_id);
    if(graphSection.is(':visible')) {
        graphSection.slideUp(function() {
            $('#' + section_id + ' .graphArea')[0].innerHTML = 'Loading...';
        });
    } else {
        graphSection.slideDown();
        var graphArea = $('#'+section_id+' .graphArea');
        var area_id = graphArea.attr('id');
        var url = graphArea.data('graph-url');
        new Chartkick.LineChart(area_id, url, {});
    }
}