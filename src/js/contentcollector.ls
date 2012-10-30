exports.collectContentLineBreak = (hook, context) ->
  tvalue = context.tvalue
  breakLine = true
  breakLine = false if tvalue and tvalue is 'tblBreak'
  breakLine

exports.collectContentLineText = (hook, context) ->
  n = context.node
  txt = context.text
  if txt
    while n
      if n.tagName is 'TD'
        elementName = n.getAttribute 'name'
        if elementName is 'tData'
          txt = txt.replace //\\//g, '|'
          txt = txt.replace //"//g, '\''
          break
        else
          if elementName is 'delimCell'
            txt = '","'
            break
          else
            if elementName is 'payload'
              txt = '{"payload":[["'
              break
            else
              if elementName is 'bracketAndcomma'
                txt = '"]],"tblId":"1","tblClass":"data-tables"}'
                break
      n = n.parentNode
  txt