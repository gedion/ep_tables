exports.disableAuthorColorsForThisLine = (hook, context) ->
  lineText = context.text
  disableLineColors = false
  disableLineColors = true if lineText and (lineText.indexOf 'data-tables') isnt -1
  disableLineColors