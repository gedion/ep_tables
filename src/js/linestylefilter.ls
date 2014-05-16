exports.disableAuthorColorsForThisLine = (hook, context) ->
  lineText = context.text
  disableLineColors = false
  disableLineColors = true if lineText and (lineText.indexOf '\uFFF9') isnt -1
  disableLineColors
