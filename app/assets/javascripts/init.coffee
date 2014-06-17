this.$_ = {}

# Use Handlebars.js
#$_.templateEngine = Handlebars.compile

# Use Underscore.js
_.templateSettings = {
  interpolate: /\{\{(.+?)\}\}/g
}
$_.templateEngine = _.template

@guid = () ->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
    r = Math.random()*16|0
    v = if (c == 'x') then r else (r&0x3|0x8)
    return v.toString(16)

$ () ->
  $_.teamList.fetch()
  $_.serviceList.fetch()
