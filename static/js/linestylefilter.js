exports.disableAuthorColorsForThisLine = function(hook, context){
  var lineText, disableLineColors;
  lineText = context.text;
  disableLineColors = false;
  if (lineText && lineText.indexOf('data-tables') !== -1) {
    disableLineColors = true;
  }
  return disableLineColors;
};