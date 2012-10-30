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
          break
        else
          if elementName is 'delimCell'
            txt = '\uF134,\uF134'
            break
          else
            if elementName is 'payload'
              txt = '{\uF134payload\uF134:[[\uF134'
              break
            else
              if elementName is 'bracketAndcomma'
                txt = '\uF134]],\uF134tblId\uF134:\uF1341\uF134,\uF134tblClass\uF134:\uF134data-tables\uF134}'
                break
      n = n.parentNode
  txt
