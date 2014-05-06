function knobify(selector) {
  var obj;
  if(selector === undefined)
    obj = $('.knob');
  else if(selector.constructor === String)
    obj = $(selector);
  else if(selector instanceof Object)
    obj = selector;
  else
    obj = $('.knob');
  if(obj.length == 0)
    return;
  if(! obj.hasClass('knob'))
    obj = obj.find('.knob');
  obj.knob({
    draw : function () {
        // "tron" case
        if(this.$.data('skin') == 'tron') {

            var a = this.angle(this.cv)  // Angle
                , sa = this.startAngle          // Previous start angle
                , sat = this.startAngle         // Start angle
                , ea                            // Previous end angle
                , eat = sat + a                 // End angle
                , r = true;

            this.g.lineWidth = this.lineWidth;

            this.o.cursor
                && (sat = eat - 0.3)
                && (eat = eat + 0.3);

            if (this.o.displayPrevious) {
                ea = this.startAngle + this.angle(this.value);
                this.o.cursor
                    && (sa = ea - 0.3)
                    && (ea = ea + 0.3);
                this.g.beginPath();
                this.g.strokeStyle = this.previousColor;
                this.g.arc(this.xy, this.xy, this.radius - this.lineWidth, sa, ea, false);
                this.g.stroke();
            }

            this.g.beginPath();
            this.g.strokeStyle = r ? this.o.fgColor : this.fgColor ;
            this.g.arc(this.xy, this.xy, this.radius - this.lineWidth, sat, eat, false);
            this.g.stroke();

            this.g.lineWidth = 2;
            this.g.beginPath();
            this.g.strokeStyle = this.o.fgColor;
            this.g.arc(this.xy, this.xy, this.radius - this.lineWidth + 1 + this.lineWidth * 2 / 3, 0, 2 * Math.PI, false);
            this.g.stroke();

            return false;
        }
    }
  });
  obj.each(function() {
    var icon = $(this).closest('.service').find('i');
    var color = '#000000';
    if(icon.length != 0) {
      color = icon.css('color');
    }
    $(this).trigger('configure', {fgColor: color});
    $(this).css('color', color);
  });
}