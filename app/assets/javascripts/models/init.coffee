this.$_ = {}

# Use Handlebars.js
#$_.templateEngine = Handlebars.compile

# Use Underscore.js
_.templateSettings = {
  interpolate: /\{\{(.+?)\}\}/g
}
$_.templateEngine = _.template
