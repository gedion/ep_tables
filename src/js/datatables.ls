_ = require 'ep_etherpad-lite/static/js/underscore'

if not (typeof require is 'undefined')
  Ace2Common = require 'ep_etherpad-lite/static/js/ace2_common' if typeof Ace2Common is 'undefined'
  if typeof Changeset is 'undefined' then Changeset = require 'ep_etherpad-lite/static/js/Changeset'

escapedJSON = ->
  ret = JSON.stringify it
    .replace /\\u(....)|\\(.)/g    (_, _1, _2) ->
        if _1
          String.fromCharCode parseInt _1, 16
        else
          "\\"+_1.charCodeAt(0)+\;
    .replace /"/g        '\uF134'
    .replace /\\(\d+);/g (_, _1) -> "\\"+String.fromCharCode(_1)
  #console.log ret
  #console.trace ret
  ret

fromEscapedJSON = ->
  ret = JSON.parse it.replace(/(\\|")/g, '\\$1').replace(/\uF134/g, '"')
  #console.log ret
  #console.trace \fromEscape
  ret

exports.aceInitialized = (hook, context) ->
  editorInfo = context.editorInfo
  editorInfo.ace_doDatatableOptions = (_ Datatables.doDatatableOptions).bind context

exports.acePostWriteDomLineHTML = (hook_name, {node}, cb) ->
  lineText = node.textContent
  if lineText and (lineText.indexOf '\uFFF9') isnt -1
    dtAttrs = if typeof exports.Datatables isnt 'undefined' then exports.Datatables.attributes else null
    dtAttrs = dtAttrs or ''
    code = fromEscapedJSON lineText
    DatatablesRenderer.render {}, node, code, dtAttrs
    exports.Datatables.attributes = null

exports.eejsBlock_scripts = (hook_name, args, cb) ->
  args.content = args.content + (require 'ep_etherpad-lite/node/eejs/').require 'ep_tables/templates/datatablesScripts.ejs'

exports.eejsBlock_editbarMenuLeft = (hook_name, args, cb) ->
  args.content = args.content + (require 'ep_etherpad-lite/node/eejs/').require 'ep_tables/templates/datatablesEditbarButtons.ejs'

exports.eejsBlock_styles = (hook_name, args, cb) ->
  args.content = ((require 'ep_etherpad-lite/node/eejs/').require 'ep_tables/templates/styles.ejs') + args.content

exports.aceAttribsToClasses = (hook, context) ->
  Datatables.attributes = null
  if context.key is 'tblProp'
    Datatables.attributes = context.value
    ['tblProp:' + context.value]

exports.aceStartLineAndCharForPoint = (hook, context) ->
  selStart = null
  try
    Datatables.context = context
    selStart = Datatables.getLineAndCharForPoint! if Datatables.isFocused!
  catch error
    top.console.log 'error ' + error
    top.console.log 'context rep' + Datatables.context.rep
  selStart

_stylesDisabled = false

enableStyles = ->
  return unless _stylesDisabled
  $(\#editbar)find('li[data-key]')each ->
    el = $ @
    key = el.data \keyOrig
    el.data(\key, key).attr('data-key', key)
  _stylesDisabled := false

disableStyles = ->
  return if _stylesDisabled
  # note that pad_editbar.js uses attr, so just clearing data('key') doesn't work
  $(\#editbar)find('li[data-key]')each ->
    el = $ @
    key = el.data \key
    el.data(\keyOrig, key)data(\key, null)attr('data-key', '')
  _stylesDisabled := true

exports.aceEndLineAndCharForPoint = (hook, context) ->
  selEndLine = null
  try
    Datatables.context = context
    if Datatables.isFocused!
      disableStyles!
      selEndLine = Datatables.getLineAndCharForPoint!
    else
      enableStyles!
  catch error
    top.console.log 'error ' + error
    top.console.log 'context rep' + Datatables.context.rep
  selEndLine

exports.aceKeyEvent = (hook, context) ->
  specialHandled = false
  try
    Datatables.context = context
    if Datatables.isFocused!
      evt = context.evt
      type = evt.type
      keyCode = evt.keyCode
      isTypeForSpecialKey = if Ace2Common.browser.msie or Ace2Common.browser.safari then type is 'keydown' else type is 'keypress'
      isTypeForCmdKey = if Ace2Common.browser.msie or Ace2Common.browser.safari then type is 'keydown' else type is 'keypress'
      which = evt.which
      if not specialHandled and isTypeForSpecialKey and keyCode is 9 and not (evt.metaKey or evt.ctrlKey)
        context.editorInfo.ace_fastIncorp 5
        evt.preventDefault!
        Datatables.performDocumentTableTabKey!
        specialHandled = true
      if not specialHandled and isTypeForSpecialKey and keyCode is 13
        context.editorInfo.ace_fastIncorp 5
        evt.preventDefault!
        Datatables.doReturnKey!
        specialHandled = true
      if not specialHandled and isTypeForSpecialKey and (keyCode is Datatables.vars.JS_KEY_CODE_DEL or keyCode is Datatables.vars.JS_KEY_CODE_BS or (String.fromCharCode which).toLowerCase! is 'h' and evt.ctrlKey)
        context.editorInfo.ace_fastIncorp 20
        evt.preventDefault!
        specialHandled = true
        Datatables.doDeleteKey! if Datatables.isCellDeleteOk keyCode
  catch
  specialHandled

class Datatables
    nodeText = ({childNodes}) ->
      excluded = do
        noscript: 'noscript'
        script: 'script'
      text = for el in childNodes
        if el.nodeType is 1 and el.tagName.toLowerCase! not of excluded
          nodeText el
        else if el.nodeType is 3
          el.data
      text.join ''
    @lastTblId = 0
    @defaults= {tblProps: {
        borderWidth: '1'
        cellAttrs: []
        width: '6'
        rowAttrs: {}
        colAttrs: []
        authors: {}
    }}
    @config= {}
    @vars= {
        OVERHEAD_LEN_PRE: '{\uF134payload\uF134:[[\uF134'.length
        OVERHEAD_LEN_MID: '\uF134,\uF134'.length
        OVERHEAD_LEN_ROW_START: '[\uF134'.length
        OVERHEAD_LEN_ROW_END: '\uF134],'.length
        JS_KEY_CODE_BS: 8
        JS_KEY_CODE_DEL: 46
        TBL_OPTIONS: [
          'addTbl'
          'addTblRowA'
          'addTblRowB'
          'addTblColL'
          'addTblColR'
          'delTbl'
          'delTblRow'
          'delTblCol'
          'delImg'
        ]
    }
    @context= null
    @isFocused = ->
      return false if not @context.rep.selStart or not @context.rep.selEnd
      line = @context.rep.lines.atIndex @context.rep.selStart.0
      if not line then return false
      currLineText = line.text or ''
      if (currLineText.indexOf '\uFFF9') is -1 then return false
      true
    @_getRowEndOffset = (rowStartOffset, tds) ->
      rowEndOffset = rowStartOffset + @vars.OVERHEAD_LEN_ROW_START
      i = 0
      len = tds.length
      while i < len
        overHeadLen = @vars.OVERHEAD_LEN_MID
        overHeadLen = @vars.OVERHEAD_LEN_ROW_END if i is len - 1
        rowEndOffset += tds[i].length + overHeadLen
        i++
      rowEndOffset
    @getFocusedTdInfo = (payload, colStart) ->
      payloadOffset = colStart - @vars.OVERHEAD_LEN_PRE
      rowStartOffset = 0
      payloadSum = 0
      rIndex = 0
      rLen = payload.length
      while rIndex < rLen
        tds = payload[rIndex]
        tIndex = 0
        tLen = tds.length
        while tIndex < tLen
          overHeadLen = @vars.OVERHEAD_LEN_MID
          overHeadLen = @vars.OVERHEAD_LEN_ROW_END if tIndex is tLen - 1
          payloadSum += tds[tIndex].length + overHeadLen
          if payloadSum >= payloadOffset
            tIndex++ if payloadSum is payloadOffset
            leftOverTdTxtLen = if payloadSum - payloadOffset is 0 then payload[rIndex][tIndex].length + @vars.OVERHEAD_LEN_MID else payloadSum - payloadOffset
            cellCaretPos = tds[tIndex].length - leftOverTdTxtLen - overHeadLen
            rowEndOffset = @_getRowEndOffset rowStartOffset, tds
            return {
              row: rIndex
              td: tIndex
              leftOverTdTxtLen: leftOverTdTxtLen
              rowStartOffset: rowStartOffset
              rowEndOffset: rowEndOffset
              cellStartOffset: payloadSum - tds[tIndex].length - overHeadLen
              cellEndOffset: payloadSum
              cellCaretPos: cellCaretPos
            }
          tIndex++
        rowStartOffset = payloadSum
        payloadSum += @vars.OVERHEAD_LEN_ROW_START
        rIndex++
    @printCaretPos = (start, end) ->
      top.console.log JSON.stringify start
      top.console.log JSON.stringify end
    @doDatatableOptions = (cmd, xByY) ->
      Datatables.context = this
      if typeof cmd is 'object' and cmd.tblPropertyChange
        Datatables.updateTableProperties cmd
      else
        switch cmd
        case Datatables.vars.TBL_OPTIONS.0
          Datatables.addTable xByY
        case Datatables.vars.TBL_OPTIONS.1
          Datatables.insertTblRow 'addA'
        case Datatables.vars.TBL_OPTIONS.2
          Datatables.insertTblRow 'addB'
        case Datatables.vars.TBL_OPTIONS.3
          Datatables.insertTblColumn 'addL'
        case Datatables.vars.TBL_OPTIONS.4
          Datatables.insertTblColumn 'addR'
        case Datatables.vars.TBL_OPTIONS.5
          Datatables.deleteTable!
        case Datatables.vars.TBL_OPTIONS.6
          Datatables.deleteTblRow!
        case Datatables.vars.TBL_OPTIONS.7
          Datatables.deleteTblColumn!
    @addTable = (tableObj) ->
      rep = @context.rep
      start = rep.selStart
      end = rep.selEnd
      line = rep.lines.atIndex rep.selStart.0
      hasMoreRows = null
      isRowAddition = null
      if tableObj
        hasMoreRows = tableObj.hasMoreRows
        isRowAddition = tableObj.isRowAddition
      if isRowAddition
        table = fromEscapedJSON tableObj.tblString
        insertTblRowBelow 0, table
        performDocApplyTblAttrToRow rep.selStart, JSON.stringify table.tblProperties
        return 
      if line
        currLineText = line.text
        if currLineText.indexOf('\uFFF9') isnt -1
          do
            rep.selStart.0 = rep.selStart.0 + 1
            currLineText = (rep.lines.atIndex rep.selStart.0).text
          while currLineText.indexOf('\uFFF9') isnt -1
          rep.selEnd.1 = rep.selStart.1 = currLineText.length
          @context.editorInfo.ace_doReturnKey!
          @context.editorInfo.ace_doReturnKey!
        else
          rep.selEnd.1 = rep.selStart.1 = currLineText.length
          @context.editorInfo.ace_doReturnKey!
      if not tableObj?
        authors = {}
        @insertTblRowBelow 3
        @performDocApplyTblAttrToRow rep.selStart, @createDefaultTblProperties!
        @insertTblRowBelow 3
        @performDocApplyTblAttrToRow rep.selStart, @createDefaultTblProperties authors
        @insertTblRowBelow 3
        @performDocApplyTblAttrToRow rep.selStart, @createDefaultTblProperties authors
        @context.editorInfo.ace_doReturnKey!
        @updateAuthorAndCaretPos rep.selStart.0 - 3
        return 
      xByYSelect = if typeof tableObj is 'object' then null else tableObj.split 'X'
      if xByYSelect? and xByYSelect.length is 3
        cols = parseInt xByYSelect.1
        rows = parseInt xByYSelect.2
        jsoStrTblProp = JSON.stringify @createDefaultTblProperties!
        authors = {}
        i = 0
        while i < rows
          @insertTblRowBelow cols
          if i is 0 then @performDocApplyTblAttrToRow rep.selStart, @createDefaultTblProperties! else @performDocApplyTblAttrToRow rep.selStart, @createDefaultTblProperties authors
          i++
        @updateAuthorAndCaretPos rep.selStart.0 - rows + 1
        return 
      newText
    @insertTblRow = (aboveOrBelow) ->
      func = 'insertTblRow()'
      rep = @context.rep
      try
        newText = ''
        currLineText = (rep.lines.atIndex rep.selStart.0).text
        payload = (fromEscapedJSON currLineText).payload
        currTdInfo = @getFocusedTdInfo payload, rep.selStart.1
        currRow = currTdInfo.row
        lastRowOffSet = 0
        start = []
        end = []
        start.0 = rep.selStart.0
        start.1 = rep.selStart.1
        end.0 = rep.selStart.0
        end.1 = rep.selStart.1
        if aboveOrBelow is 'addA'
          rep.selStart.0 = rep.selEnd.0 = rep.selStart.0 - 1
          @insertTblRowBelow payload.0.length
        else
          @insertTblRowBelow payload.0.length
        @context.editorInfo.ace_performDocApplyTblAttrToRow rep.selStart, @createDefaultTblProperties!
        @updateAuthorAndCaretPos rep.selStart.0
        updateEvenOddBgColor = true
        @sanitizeTblProperties rep.selStart, updateEvenOddBgColor
      catch
    @deleteTable = ->
      rep = @context.rep
      func = 'deleteTable()'
      start = rep.seStart
      end = rep.seEnd
      try
        line = rep.selStart.0 - 1
        numOfLinesAbove = 0
        numOfLinesBelow = 0
        while not (((rep.lines.atIndex line).text.indexOf '\uFFF9') is -1)
          numOfLinesAbove++
          line--
        line = rep.selEnd.0 + 1
        while not (((rep.lines.atIndex line).text.indexOf '\uFFF9') is -1)
          numOfLinesBelow++
          line++
        rep.selStart.1 = 0
        rep.selStart.0 = rep.selStart.0 - numOfLinesAbove
        rep.selEnd.0 = rep.selEnd.0 + numOfLinesBelow
        rep.selEnd.1 = (rep.lines.atIndex rep.selEnd.0).text.length
        @context.editorInfo.ace_performDocumentReplaceRange rep.selStart, rep.selEnd, ''
      catch
    @deleteTblRow = ->
      func = 'deleteTblRow()'
      rep = @context.rep
      try
        currLineText = (rep.lines.atIndex rep.selStart.0).text
        return  if (currLineText.indexOf '\uFFF9') is -1
        rep.selEnd.0 = rep.selStart.0 + 1
        rep.selStart.1 = 0
        rep.selEnd.1 = 0
        @context.editorInfo.ace_performDocumentReplaceRange rep.selStart, rep.selEnd, ''
        currLineText = (rep.lines.atIndex rep.selStart.0).text
        if (currLineText.indexOf '\uFFF9') is -1 then return 
        @updateAuthorAndCaretPos rep.selStart.0, 0, 0
        updateEvenOddBgColor = true
        @sanitizeTblProperties rep.selStart, updateEvenOddBgColor
      catch
    @updateTableProperties = (props) ->
      rep = @context.rep
      currTd = null
      if props.tblColWidth or props.tblSingleColBgColor or props.tblColVAlign
        currLine = rep.lines.atIndex rep.selStart.0
        currLineText = currLine.text
        tblJSONObj = fromEscapedJSON currLineText
        payload = tblJSONObj.payload
        currTdInfo = @getFocusedTdInfo payload, rep.selStart.1
        currTd = currTdInfo.td
      if props.tblWidth or props.tblHeight or props.tblBorderWidth or props.tblBorderColor or props.tblColWidth or props.tblSingleColBgColor or props.tblEvenRowBgColor or props.tblOddRowBgColor or props.tblColVAlign
        start = []
        start.0 = rep.selStart.0
        start.1 = rep.selStart.1
        numOfLinesAbove = @getTblAboveRowsFromCurFocus start
        tempStart = []
        tempStart.0 = start.0 - numOfLinesAbove
        tempStart.1 = start.1
        while tempStart.0 < rep.lines.length! and ((rep.lines.atIndex tempStart.0).text.indexOf '\uFFF9') isnt -1
          if props.tblEvenRowBgColor and tempStart.0 % 2 isnt 0
            tempStart.0 = tempStart.0 + 1
            continue
          else
            if props.tblOddRowBgColor and tempStart.0 % 2 is 0
              tempStart.0 = tempStart.0 + 1
              continue
          @updateTablePropertiesHelper props, tempStart, currTd
          tempStart.0 = tempStart.0 + 1
      else
        start = []
        start.0 = rep.selStart.0
        start.1 = rep.selStart.1
        @updateTablePropertiesHelper props, start, currTd
    @addCellAttr = (start, tblJSONObj, tblProperties, attrName, attrValue) ->
      rep = @context.rep
      payload = tblJSONObj.payload
      currTdInfo = @getFocusedTdInfo payload, start.1
      currRow = currTdInfo.row
      currTd = currTdInfo.td
      cellAttrs = tblProperties.cellAttrs
      row = cellAttrs[currRow]
      row = [] if not row? or typeof row is 'undefined'
      cell = row[currTd]
      if not cell? or typeof cell is 'undefined' then cell = {}
      if attrName is 'fontWeight' or attrName is 'fontStyle' or attrName is 'textDecoration' then attrValue = '' if cell[attrName] is attrValue else if cell[attrName] is attrValue then return false
      cell[attrName] = attrValue
      row[currTd] = cell
      cellAttrs[currRow] = row
      tblProperties.cellAttrs = cellAttrs
      tblProperties
    @addRowAttr = (tblJSONObj, tblProperties, attrName, attrValue) ->
      rep = @context.rep
      rowAttrs = tblProperties.rowAttrs
      if attrName is 'bgColor'
        payload = tblJSONObj.payload
        currTdInfo = @getFocusedTdInfo payload, rep.selStart.1
        currRow = currTdInfo.row
        singleRowAttrs = rowAttrs.singleRowAttrs
        singleRowAttrs = [] if not singleRowAttrs? or typeof singleRowAttrs is 'undefined'
        if not singleRowAttrs[currRow]? or typeof singleRowAttrs[currRow] is 'undefined' then singleRowAttrs[currRow] = {} else if singleRowAttrs[currRow][attrName] is attrValue then return false
        singleRowAttrs[currRow][attrName] = attrValue
        rowAttrs.singleRowAttrs = singleRowAttrs
      else
        return false if rowAttrs[attrName] is attrValue
        rowAttrs[attrName] = attrValue
      tblProperties.rowAttrs = rowAttrs
      tblProperties
    @addColumnAttr = (start, tblJSONObj, tblProperties, attrName, attrValue, currTd) ->
      payload = tblJSONObj.payload
      currTdInfo = @getFocusedTdInfo payload, start.1
      colAttrs = tblProperties.colAttrs
      colAttrs = [] if not colAttrs? or typeof colAttrs is 'undefined'
      if not colAttrs[currTd]? or typeof colAttrs[currTd] is 'undefined' then colAttrs[currTd] = {} else if colAttrs[currTd][attrName] is attrValue then return false
      colAttrs[currTd][attrName] = attrValue
      tblProperties.colAttrs = colAttrs
      tblProperties
    @updateTablePropertiesHelper = (props, start, currTd) ->
      rep = @context.rep
      lastTblPropertyUsed = 'updateTableProperties'
      start = start or rep.selStart
      return  if not start
      currLine = rep.lines.atIndex start.0
      currLineText = currLine.text
      if (currLineText.indexOf '\uFFF9') is -1 then return true
      (try
        tblJSONObj = fromEscapedJSON currLineText
        tblProperties = @getLineTableProperty start.0
        update = false
        if props.tblWidth or props.tblHeight or props.tblBorderWidth or props.tblBorderColor
          currAttrValue = tblProperties[props.attrName]
          if props.attrValue? and (typeof currAttrValue is 'undefined' or currAttrValue isnt props.attrValue)
            tblProperties[props.attrName] = props.attrValue
            update = true
        if props.tblCellFontWeight or props.tblCellFontStyle or props.tblCellTextDecoration
          tblProps = @addCellAttr start, tblJSONObj, tblProperties, props.attrName, props.attrValue
          if tblProps
            tblProperties = tblProps
            update = true
        if props.tblCellFontSize or props.tblCellBgColor or props.tblCellHeight or props.tblCellPadding or props.tblcellVAlign
          tblProps = @addCellAttr start, tblJSONObj, tblProperties, props.attrName, props.attrValue
          if tblProps
            tblProperties = tblProps
            update = true
        if props.tblEvenRowBgColor or props.tblOddRowBgColor
          tblProps = @addRowAttr tblJSONObj, tblProperties, props.attrName, props.attrValue
          if tblProps
            tblProperties = tblProps
            update = true
        if props.tblSingleRowBgColor or props.tblRowVAlign
          tblProps = @addRowAttr tblJSONObj, tblProperties, props.attrName, props.attrValue
          if tblProps
            tblProperties = tblProps
            update = true
        if props.tblColWidth or props.tblSingleColBgColor or props.tblColVAlign
          tblProps = @addColumnAttr start, tblJSONObj, tblProperties, props.attrName, props.attrValue, currTd
          if tblProps
            tblProperties = tblProps
            update = true
        if update then @updateTblPropInAPool -1, -1, tblProperties, start
      catch)
    @updateAuthorAndCaretPos = (magicDomLineNum, tblRowNum, tblColNum) ->
      rep = @context.rep
      rep.selStart.1 = rep.selEnd.1 = @vars.OVERHEAD_LEN_PRE
      rep.selStart.0 = rep.selEnd.0 = magicDomLineNum
      row = if typeof tblRowNum is 'undefined' or not tblRowNum? then 0 else tblRowNum
      col = if typeof tblColNum is 'undefined' or not tblRowNum? then 0 else tblColNum
      @updateTblPropInAPool row, col, null, rep.selStart
      rep.selStart.1 = rep.selEnd.1 = @vars.OVERHEAD_LEN_PRE
      @context.editorInfo.ace_performDocumentReplaceRange rep.selStart, rep.selEnd, ''
    @createDefaultTblProperties = (authors) ->
      rep = @context.rep
      defTblProp = {
        borderWidth: '1'
        cellAttrs: []
        width: '6'
        rowAttrs: {}
        colAttrs: []
        authors: {}
      }
      defTblProp.'authors' = authors if authors
      prevLine = rep.lines.atIndex rep.selEnd.0 - 1
      jsoTblProp = null
      if prevLine
        prevLineText = prevLine.text
        jsoTblProp = @getLineTableProperty rep.selStart.0 - 1 if not ((prevLineText.indexOf '\uFFF9') is -1)
      if not jsoTblProp
        nextLine = rep.lines.atIndex rep.selEnd.0 - 1
        if nextLine
          nextLineText = nextLine.text
          jsoTblProp = @getLineTableProperty rep.selStart.0 + 1 if not ((nextLineText.indexOf '\uFFF9') is -1)
      if jsoTblProp
        defTblProp.borderWidth = jsoTblProp.borderWidth
        defTblProp.borderColor = jsoTblProp.borderColor
        defTblProp.width = jsoTblProp.width
        defTblProp.height = jsoTblProp.height
        defTblProp.colAttrs = jsoTblProp.colAttrs
      jsoStrTblProp = JSON.stringify defTblProp
      jsoStrTblProp
    @performDocApplyTblAttrToRow = (start, jsoStrTblProp) ->
      tempStart = []
      tempEnd = []
      tempStart.0 = start.0
      tempEnd.0 = start.0
      tempStart.1 = 0
      tempEnd.1 = (@context.rep.lines.atIndex start.0).text.length
      @context.editorInfo.ace_performDocumentApplyAttributesToRange tempStart, tempEnd, [['tblProp', jsoStrTblProp]]
    @performDocumentTableTabKey = ->
      try
        context = @context
        rep = context.rep
        currLine = rep.lines.atIndex rep.selStart.0
        currLineText = currLine.text
        tblJSONObj = fromEscapedJSON currLineText
        payload = tblJSONObj.payload
        currTdInfo = @getFocusedTdInfo payload, rep.selStart.1
        leftOverTdTxtLen = currTdInfo.leftOverTdTxtLen
        currRow = currTdInfo.row
        currTd = currTdInfo.td
        if typeof payload[currRow][currTd + 1] is 'undefined'
          currRow += 1
          nextLine = rep.lines.atIndex rep.selStart.0 + 1
          nextLineText = nextLine.text
          updateEvenOddBgColor = false
          if not nextLineText? or nextLineText is '' or (nextLineText.indexOf '\uFFF9') is -1
            @insertTblRowBelow null, null
            @performDocApplyTblAttrToRow rep.selStart, @createDefaultTblProperties!
            rep.selEnd.1 = rep.selStart.1 = @vars.OVERHEAD_LEN_PRE
            updateEvenOddBgColor = true
          else
            currTd = -1
            rep.selStart.0 = rep.selEnd.0 = rep.selStart.0 + 1
            tblJSONObj = fromEscapedJSON nextLineText
            payload = tblJSONObj.payload
            leftOverTdTxtLen = payload.0.0.length
            rep.selEnd.1 = rep.selStart.1 = @vars.OVERHEAD_LEN_PRE + leftOverTdTxtLen
          context.editorInfo.ace_performDocumentReplaceRange rep.selStart, rep.selEnd, ''
          start = []
          start.0 = rep.selStart.0
          start.1 = rep.selStart.1
          @updateTblCellAuthor 0, 0, null, start, updateEvenOddBgColor
        else
          nextTdTxtLen = if typeof payload[currRow] is 'undefined' then -leftOverTdTxtLen else payload[currRow][currTd + 1].length
          payload = tblJSONObj.payload
          rep.selStart.1 = rep.selEnd.1 = rep.selEnd.1 + nextTdTxtLen + leftOverTdTxtLen
          context.editorInfo.ace_performDocumentReplaceRange rep.selStart, rep.selEnd, ''
          @updateTblPropInAPool currRow, currTd + 1, null, rep.selStart
      catch
    @getTdInfo = (payload, tdIndex) ->
      rep = @context.rep
      startOffset = @vars.OVERHEAD_LEN_PRE
      rowStartOffset = startOffset
      payloadSum = startOffset
      tds = payload.0
      tIndex = 0
      tLen = tds.length
      while tIndex < tLen
        overHeadLen = @vars.OVERHEAD_LEN_MID
        overHeadLen = @vars.OVERHEAD_LEN_ROW_END if tIndex is tLen - 1
        payloadSum += tds[tIndex].length + overHeadLen
        if tIndex >= tdIndex
          return {
            cellStartOffset: payloadSum - tds[tIndex].length - overHeadLen
            cellEndOffset: payloadSum
          }
        tIndex++
    @getNextTdInfo = (payload, currTdInfo) ->
      rep = @context.rep
      startOffset = currTdInfo.rowEndOffset
      rowStartOffset = startOffset
      payloadSum = startOffset
      tds = payload[currTdInfo.row]
      tIndex = 0
      tLen = tds.length
      while tIndex < tLen
        overHeadLen = @vars.OVERHEAD_LEN_MID
        overHeadLen = @vars.OVERHEAD_LEN_ROW_END if tIndex is tLen - 1
        payloadSum += tds[tIndex].length + overHeadLen
        if tIndex >= currTdInfo.td
          leftOverTdTxtLen = if payloadSum - startOffset is 0 then payload[currTdInfo.row + 1][tIndex].length + @vars.OVERHEAD_LEN_MID else payloadSum - startOffset
          rowEndOffset = @_getRowEndOffset rowStartOffset, tds
          tdInfo = {
            row: currTdInfo.row + 1
            td: tIndex
            leftOverTdTxtLen: leftOverTdTxtLen
            rowStartOffset: rowStartOffset
            rowEndOffset: rowEndOffset
            cellStartOffset: payloadSum - tds[tIndex].length - overHeadLen
            cellEndOffset: payloadSum
          }
          return tdInfo
        tIndex++
    @insertTblColumn = (leftOrRight, start, end) ->
      rep = @context.rep
      func = 'insertTblColumn()'
      try
        currLineText = (rep.lines.atIndex rep.selStart.0).text
        tblJSONObj = fromEscapedJSON currLineText
        payload = tblJSONObj.payload
        currTdInfo = @getFocusedTdInfo payload, rep.selStart.1
        currTd = currTdInfo.td
        start = []
        end = []
        start.0 = rep.selStart.0
        start.1 = rep.selStart.1
        end.0 = rep.selEnd.0
        end.1 = rep.selEnd.1
        currTd -= 1 if leftOrRight is 'addL'
        numOfLinesAbove = @getTblAboveRowsFromCurFocus start
        rep.selEnd.0 = rep.selStart.0 = rep.selStart.0 - numOfLinesAbove
        while rep.selStart.0 < rep.lines.length! and ((rep.lines.atIndex rep.selStart.0).text.indexOf '\uFFF9') isnt -1
          currLineText = (rep.lines.atIndex rep.selStart.0).text
          tblJSONObj = fromEscapedJSON currLineText
          payload = tblJSONObj.payload
          cellPos = (@getTdInfo payload, currTd).cellEndOffset
          newText = '\uF134 \uF134,'
          if currTd is payload.0.length - 1
            rep.selStart.1 = rep.selEnd.1 = cellPos - @vars.OVERHEAD_LEN_ROW_END + 1
            newText = ',\uF134 \uF134'
          else
            if currTd is -1 then rep.selStart.1 = rep.selEnd.1 = @vars.OVERHEAD_LEN_PRE - 1 else rep.selStart.1 = rep.selEnd.1 = cellPos - 1
          @context.editorInfo.ace_performDocumentReplaceRange rep.selStart, rep.selEnd, newText
          rep.selEnd.0 = rep.selStart.0 = rep.selStart.0 + 1
        rep.selStart = start
        rep.selEnd = end
        if leftOrRight is 'addL'
          rep.selStart.1 = rep.selEnd.1 = @vars.OVERHEAD_LEN_PRE
          rep.selStart.0 = rep.selEnd.0 = rep.selStart.0
          @updateTblPropInAPool 0, 0, null, rep.selStart
          rep.selStart.1 = rep.selEnd.1 = @vars.OVERHEAD_LEN_PRE
        currTd++
        updateEvenOddBgColor = false
        updateColAttrs = true
        @sanitizeTblProperties start, updateEvenOddBgColor, updateColAttrs, currTd, 'add'
        @context.editorInfo.ace_performDocumentReplaceRange rep.selStart, rep.selEnd, ''
      catch
    @deleteTblColumn = ->
      func = 'deleteTblColumn()'
      rep = @context.rep
      try
        currLineText = (rep.lines.atIndex rep.selStart.0).text
        tblJSONObj = fromEscapedJSON currLineText
        payload = tblJSONObj.payload
        deleteTable! if payload.0.length is 1
        currTdInfo = @getFocusedTdInfo payload, rep.selStart.1
        currTd = currTdInfo.td
        start = []
        end = []
        start.0 = rep.selStart.0
        start.1 = rep.selStart.1
        end.0 = rep.selEnd.0
        end.1 = rep.selEnd.1
        numOfLinesAbove = @getTblAboveRowsFromCurFocus start
        rep.selEnd.0 = rep.selStart.0 = rep.selStart.0 - numOfLinesAbove
        while rep.selStart.0 < rep.lines.length! and ((rep.lines.atIndex rep.selStart.0).text.indexOf '\uFFF9') isnt -1
          currLineText = (rep.lines.atIndex rep.selStart.0).text
          tblJSONObj = fromEscapedJSON currLineText
          payload = tblJSONObj.payload
          cellTdInfo = @getTdInfo payload, currTd
          newText = '\uF134 \uF134,'
          if currTd is payload.0.length - 1
            rep.selStart.1 = cellTdInfo.cellStartOffset - 2
            rep.selEnd.1 = cellTdInfo.cellEndOffset - 2
          else
            if currTd is 0
              rep.selStart.1 = @vars.OVERHEAD_LEN_PRE - 1
              rep.selEnd.1 = cellTdInfo.cellEndOffset - 1
            else
              rep.selStart.1 = cellTdInfo.cellStartOffset - 1
              rep.selEnd.1 = cellTdInfo.cellEndOffset - 1
          @context.editorInfo.ace_performDocumentReplaceRange rep.selStart, rep.selEnd, ''
          rep.selEnd.0 = rep.selStart.0 = rep.selStart.0 + 1
        rep.selStart = start
        rep.selEnd = end
        updateEvenOddBgColor = false
        updateColAttrs = true
        @sanitizeTblProperties start, updateEvenOddBgColor, updateColAttrs, currTd, 'del'
        @updateAuthorAndCaretPos rep.selStart.0, 0, 0
      catch
    @insertTblRowBelow = (numOfRows, table) ->
      context = @context
      rep = context.rep
      currLineText = (rep.lines.atIndex rep.selStart.0).text
      payload = [[]]
      if not numOfRows and numOfRows isnt 0
        tblPayload = (fromEscapedJSON currLineText).payload
        numOfRows = tblPayload.0.length
      tblRows = new Array numOfRows
      if not (numOfRows is 0)
        i = 0
        while i < tblRows.length
          tblRows[i] = ' '
          i++
      payload = [tblRows]
      if table then payload = table.payload
      tableObj = {
        payload: payload
        tblId: table?tblId ? @getNewTblId!
        tblClass: '\uFFF9'
        trClass: 'alst'
        tdClass: 'hide-el'
      }
      rep.selEnd.1 = rep.selStart.1 = currLineText.length
      @context.editorInfo.ace_inCallStackIfNecessary 'newline', @context.editorInfo.ace_doReturnKey
      context.editorInfo.ace_performDocumentReplaceRange rep.selStart, rep.selEnd, escapedJSON tableObj
    @getNewTblId = ->
        ++@lastTblId
    @doReturnKey = ->
      context = @context
      rep = context.rep
      start = rep.seStart
      end = rep.selEnd
      lastTblPropertyUsed = 'doTableReturnKey'
      currLine = rep.lines.atIndex rep.selStart.0
      currLineText = currLine.text
      if currLineText.indexOf('\uFFF9') isnt -1
        func = 'doTableReturnKey()'
        try
          currCarretPos = rep.selStart.1
          if (currLineText.substring currCarretPos - 1, currCarretPos + 2) is '\uF134,\uF134'
            return true
          else
            if (currLineText.substring currCarretPos - 2, currCarretPos + 1) is '\uF134,\uF134'
              return true
            else
              if currCarretPos < @vars.OVERHEAD_LEN_PRE then return true else if currCarretPos > currLineText.length then return true
          start = rep.selStart
          end = rep.selEnd
          newText = ' /r/n '
          start.1 = currCarretPos
          end.1 = currCarretPos
          (try
            jsonObj = fromEscapedJSON (currLineText.substring 0, start.1) + newText + currLineText.substring start.1
            payloadStr = escapedJSON jsonObj.payload
            return true if currCarretPos > payloadStr.length + @vars.OVERHEAD_LEN_PRE - 2
          catch error
            return true)
          context.editorInfo.ace_performDocumentReplaceRange start, end, newText
        catch
        true
    @isCellDeleteOk = (keyCode) ->
      {selStart:start}:rep = @context.rep
      {text:currLineText} = rep.lines.atIndex start.0
      return true if (currLineText.indexOf '\uFFF9') is -1
      isDeleteAccepted = false
      try
        tblJSONObj = fromEscapedJSON currLineText
        table = tblJSONObj.payload
        currTdInfo = @getFocusedTdInfo table, start.1
        cellEntryLen = table[currTdInfo.row][currTdInfo.td].length
        currCarretPos = start.1
        if (currLineText.substring currCarretPos - 1, currCarretPos + 2) is '\uF134,\uF134'
          return false
        else
          if (currLineText.substring currCarretPos - 2, currCarretPos + 1) is '\uF134,\uF134' then return false
        switch keyCode
        case @vars.JS_KEY_CODE_BS
          isDeleteAccepted = true if cellEntryLen > 1 and cellEntryLen > currTdInfo.leftOverTdTxtLen - @vars.OVERHEAD_LEN_MID
        case @vars.JS_KEY_CODE_DEL
          return false # still buggy and can corrupt table structure
          isDeleteAccepted = true if cellEntryLen > 0 and currTdInfo.leftOverTdTxtLen - @vars.OVERHEAD_LEN_MID > 0
        default
          isDeleteAccepted = true if cellEntryLen > 1 and cellEntryLen > currTdInfo.leftOverTdTxtLen - @vars.OVERHEAD_LEN_MID
      catch error
        isDeleteAccepted = false
      isDeleteAccepted
    @nodeTextPlain = (n) -> n.innerText or n.textContent or n.nodeValue or ''
    @toString = -> 'ep_tables'
    @getLineAndCharForPoint = ->
      context = @context
      point = context.point
      root = context.root
      if point.node is root
        if point.index is 0
          [0, 0]
        else
          N = @context.rep.lines.length!
          ln = @context.rep.lines.atIndex N - 1
          [N - 1, ln.text.length]
      else
        n = point.node
        col = 0
        col = point.index if (nodeText n) or point.index > 0
        parNode = void
        prevSib = void
        while (parNode = n.parentNode) isnt root
          if prevSib = n.previousSibling
            n = prevSib
            textLen = nodeText(n).length or @nodeTextPlain(n).length
            col += textLen
          else
            n = parNode
        if n.id is '' then console.debug 'BAD'
        if n.firstChild and context.editorInfo.ace_isBlockElement n.firstChild then col += 1
        lineEntry = @context.rep.lines.atKey n.id
        lineNum = @context.rep.lines.indexOfEntry lineEntry
        [lineNum, col]
    @doDeleteKey = ->
      context = @context
      evt = context.evt or {}
      handled = false
      rep = @context.rep
      editorInfo = context.editorInfo
      if rep.selStart
        if editorInfo.ace_isCaret!
          lineNum = editorInfo.ace_caretLine!
          col = editorInfo.ace_caretColumn!
          lineEntry = rep.lines.atIndex lineNum
          lineText = lineEntry.text
          lineMarker = lineEntry.lineMarker
          if /^ +$/.exec lineText.substring lineMarker, col
            col2 = col - lineMarker
            tabSize = ''.length
            toDelete = (col2 - 1) % tabSize + 1
            editorInfo.ace_performDocumentReplaceRange [lineNum, col - toDelete], [lineNum, col], ''
            handled = true
        if not handled
          if editorInfo.ace_isCaret!
            theLine = editorInfo.ace_caretLine!
            lineEntry = rep.lines.atIndex theLine
            if editorInfo.ace_caretColumn! <= lineEntry.lineMarker
              action = 'delete_newline'
              prevLineListType = if theLine > 0 then editorInfo.ace_getLineListType theLine - 1 else ''
              thisLineListType = editorInfo.ace_getLineListType theLine
              prevLineEntry = theLine > 0 and rep.lines.atIndex theLine - 1
              prevLineBlank = prevLineEntry and prevLineEntry.text.length is prevLineEntry.lineMarker
              if thisLineListType
                if prevLineBlank and not prevLineListType
                  editorInfo.ace_performDocumentReplaceRange [theLine - 1, prevLineEntry.text.length], [theLine, 0], ''
                else
                  editorInfo.ace_performDocumentReplaceRange [theLine, 0], [theLine, lineEntry.lineMarker], ''
              else
                if theLine > 0
                  editorInfo.ace_performDocumentReplaceRange [theLine - 1, prevLineEntry.text.length], [theLine, 0], ''
            else
              docChar = editorInfo.ace_caretDocChar!
              if docChar > 0
                if evt.metaKey or evt.ctrlKey or evt.altKey
                  deleteBackTo = docChar - 1
                  while deleteBackTo > lineEntry.lineMarker and editorInfo.ace_isWordChar rep.alltext.charAt deleteBackTo - 1
                    deleteBackTo--
                  editorInfo.ace_performDocumentReplaceCharRange deleteBackTo, docChar, ''
                else
                  returnKeyWitinTblOffset = 0
                  returnKeyWitinTblOffset = 4 if (lineText.substring col - 5, col) is '/r/n '
                  editorInfo.ace_performDocumentReplaceCharRange docChar - 1 - returnKeyWitinTblOffset, docChar, ''
          else
            editorInfo.ace_performDocumentReplaceRange rep.selStart, rep.selEnd, ''
      line = editorInfo.ace_caretLine!
      if line isnt -1 and (editorInfo.ace_renumberList line + 1) is null then editorInfo.ace_renumberList line
    @getLineTableProperty = (lineNum) ->
      rep = @context.rep
      aline = rep.alines[lineNum]
      if aline
        opIter = Changeset.opIterator aline
        if opIter.hasNext!
          tblJSString = Changeset.opAttributeValue opIter.next!, 'tblProp', rep.apool
          try
            return JSON.parse tblJSString
          catch error
            return @defaults.tblProps
      @defaults.tblProps
    @getCurrTblOddEvenRowBgColor = (startRowNum, currRowNum) ->
      rowBgColors = {
        oddBgColor: null
        evenBgColor: null
      }
      if not (startRowNum is currRowNum)
        jsoTblProp1 = @getLineTableProperty startRowNum
        jsoTblProp2 = @getLineTableProperty startRowNum + 1
        rowBgColors.evenBgColor = jsoTblProp1.'rowAttrs'.'evenBgColor' or jsoTblProp2.'rowAttrs'.'evenBgColor'
        rowBgColors.oddBgColor = jsoTblProp1.'rowAttrs'.'oddBgColor' or jsoTblProp2.'rowAttrs'.'oddBgColor'
      rowBgColors
    @getTblAboveRowsFromCurFocus = (start) ->
      rep = @context.rep
      numOfLinesAbove = 0
      line = start.0 - 1
      while not (((rep.lines.atIndex line).text.indexOf '\uFFF9') is -1)
        numOfLinesAbove++
        line--
      numOfLinesAbove
    @updateTableIndices = (tblProperties, currTd, addOrDel) ->
      cellAttrs = tblProperties.cellAttrs
      rIndex = 0
      rLen = cellAttrs.length
      while rIndex < rLen
        cellAttr = cellAttrs[rIndex]
        if addOrDel is 'add' then cellAttr.splice currTd, 0, null if cellAttr else cellAttr.splice currTd, 1 if cellAttr
        rIndex++
      colAttrs = tblProperties.colAttrs
      if addOrDel is 'add' then colAttrs.splice currTd, 0, null if colAttrs else colAttrs.splice currTd, 1 if colAttrs
      tblProperties
    @sanitizeTblProperties = (start, updateEvenOddBgColor, updateColAttrs, currTd, addOrDel) ->
      rep = @context.rep
      editorInfo = @context.editorInfo
      thisAuthor = editorInfo.ace_getAuthor!
      numOfLinesAbove = @getTblAboveRowsFromCurFocus start
      tempStart = []
      tempStart.0 = start.0 - numOfLinesAbove
      evenOddRowBgColors = {}
      updateEvenOddBgColor
      while tempStart.0 < rep.lines.length! and ((rep.lines.atIndex tempStart.0).text.indexOf '\uFFF9') isnt -1
        jsoTblProp = @getLineTableProperty tempStart.0
        update = false
        if tempStart.0 isnt start.0 and jsoTblProp.'authors' and jsoTblProp.'authors'[thisAuthor]
          delete jsoTblProp.'authors'[thisAuthor]
          update = true
        if updateColAttrs
          jsoTblProp = @updateTableIndices jsoTblProp, currTd, addOrDel
          update = true
        if tempStart.0 isnt start.0 and updateEvenOddBgColor
          delete jsoTblProp.'rowAttrs'.'oddBgColor'
          delete jsoTblProp.'rowAttrs'.'evenBgColor'
          update = true
        if update then @updateTblPropInAPool -1, -1, jsoTblProp, tempStart
        tempStart.0 = tempStart.0 + 1
    @updateTblPropInAPool = (row, td, jsoTblProp, start) ->
      try
        rep = @context.rep
        editorInfo = @context.editorInfo
        thisAuthor = editorInfo.ace_getAuthor!
        authorInfos = editorInfo.ace_getAuthorInfos!
        tblProps = void
        jsoTblProp = @getLineTableProperty start.0 if typeof jsoTblProp is 'undefined' or not jsoTblProp?
        if row isnt -1 and td isnt -1
          jsoTblProp.'authors'[thisAuthor] = {
            row: row
            cell: td
            colorId: authorInfos[thisAuthor].bgcolor
          }
        jsoStrTblProp = JSON.stringify jsoTblProp
        attrStart = []
        attrEnd = []
        attrStart.0 = start.0
        attrStart.1 = 0
        attrEnd.0 = start.0
        attrEnd.1 = (rep.lines.atIndex start.0).text.length
        editorInfo.ace_performDocumentApplyAttributesToRange attrStart, attrEnd, [['tblProp', jsoStrTblProp]]
      catch
    @updateTblCellAuthor = (row, td, tblProperties, start, updateEvenOddBgColor) ->
      try
        @updateTblPropInAPool row, td, tblProperties, start
        tempStart = []
        tempStart.0 = start.0
        tempStart.1 = start.1
        @sanitizeTblProperties tempStart, updateEvenOddBgColor

exports?Datatables = Datatables
