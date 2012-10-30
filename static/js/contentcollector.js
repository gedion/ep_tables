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
          txt = txt.replace(/\\/g, '|');
          txt = txt.replace(/"/g, '\'');
          break;
        } else {
          if (elementName === 'delimCell') {
            txt = '","';
            break;
          } else {
            if (elementName === 'payload') {
              txt = '{"payload":[["';
              break;
            } else {
              if (elementName === 'bracketAndcomma') {
                txt = '"]],"tblId":"1","tblClass":"data-tables"}';
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