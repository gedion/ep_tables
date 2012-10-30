exports.collectContentLineBreak = function(hook, context){
  var tvalue, breakLine;
  tvalue = context.tvalue;
  breakLine = true;
  if (tvalue && tvalue === 'tblBreak') {
    breakLine = false;
  }
  return breakLine;
};
exports.collectContentLineText = function(hook, context){
  var n, txt, elementName;
  n = context.node;
  txt = context.text;
  if (txt) {
    while (n) {
      if (n.tagName === 'TD') {
        elementName = n.getAttribute('name');
        if (elementName === 'tData') {
          break;
        } else {
          if (elementName === 'delimCell') {
            txt = '\uF134,\uF134';
            break;
          } else {
            if (elementName === 'payload') {
              txt = '{\uF134payload\uF134:[[\uF134';
              break;
            } else {
              if (elementName === 'bracketAndcomma') {
                txt = '\uF134]],\uF134tblId\uF134:\uF1341\uF134,\uF134tblClass\uF134:\uF134\uFFF9\uF134}';
                break;
              }
            }
          }
        }
      }
      n = n.parentNode;
    }
  }
  return txt;
};