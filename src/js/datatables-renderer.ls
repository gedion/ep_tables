DatatablesRenderer = {}
class DatatablesRenderer
  @render = (params, element, code, attributes) ->
    renderer = new DatatablesRenderer.Renderer
    element.innerHTML = renderer.getHtml code, attributes

  class @Renderer
      ->
      createDefaultTblProperties: (authors) ->
        {
          borderWidth: '1'
          cellAttrs: []
          width: '6'
          rowAttrs: {}
          colAttrs: []
          authors: {}
        }
      buildTabularData: (tblJSONObj, tblPropsJSString) ->
        htmlTbl = ''
        tblId = tblJSONObj.tblId
        tblClass = tblJSONObj.tblClass
        tdClass = tblJSONObj.tdClass
        trClass = tblJSONObj.trClass
        payload = tblJSONObj.payload
        tblProperties = {}
        try
          tblProperties = JSON.parse tblPropsJSString
        catch error
          tblProperties = @createDefaultTblProperties!
        rowAttrs = tblProperties.rowAttrs
        singleRowAttrs = rowAttrs.singleRowAttrs
        cellAttrs = tblProperties.cellAttrs
        colAttrs = tblProperties.colAttrs
        tblWidth = if typeof tblProperties is 'undefined' or not tblProperties? then '1' else tblProperties.width or '1'
        tblWidth = @getAttrInInch tblWidth
        tblHeight = if typeof tblProperties is 'undefined' or not tblProperties? then '.1' else tblProperties.height or '.1'
        tblHeight = @getAttrInInch tblHeight
        tblBorderWidth = if typeof tblProperties is 'undefined' or not tblProperties? then 0 else tblProperties.borderWidth or 0
        tblBorderColor = if typeof tblProperties is 'undefined' or not tblProperties? then '#000000' else tblProperties.borderColor or '#000000'
        currRow = tblProperties.currRowAuthorIdx
        currCell = tblProperties.currCellAuthorIdx
        authors = tblProperties.authors
        printViewTBlStyles = 'table-layout:fixed !important;border-collapse:collapse!important;font-family:Trebuchet MS!important;'
        printViewTblTDStyles = 'font-size: 1em!important;line-height: 1em!important;padding: 3px 7px 2px!important;word-wrap: break-word!important;'
        htmlTbl = '<table class=\'' + tblClass + '\' style=\'' + printViewTBlStyles + 'background-color:white;width:' + tblWidth + 'px!important;height:' + tblHeight + 'px!important; border-top: ' + tblBorderWidth + 'px solid ' + tblBorderColor + '!important;' + '\'><tbody>'
        borders = 'border-bottom:' + tblBorderWidth + 'px solid ' + tblBorderColor
        rowVAlign = if typeof rowAttrs is 'undefined' or not rowAttrs? then 'left' else rowAttrs.rowVAlign or 'left'
        rows = tblJSONObj.payload
        evenRowBgColor = if typeof rowAttrs is 'undefined' or not rowAttrs? then '#FFFFFF' else rowAttrs.evenBgColor or '#FFFFFF'
        oddRowBgColor = if typeof rowAttrs is 'undefined' or not rowAttrs? then null else rowAttrs.oddBgColor or null
        j = 0
        rl = rows.length
        while j < rl
          tds = rows[j]
          rowBgColor = oddRowBgColor
          rowBgColor = evenRowBgColor if not rowBgColor
          htmlTbl += '<tr style=\'vertical-align:' + rowVAlign + ';background-color:' + rowBgColor + '; ' + borders + '!important;\' class=\'' + trClass + '\'>'
          preHeader = ''
          if j is 0 then preHeader = '{\uF134payload\uF134:[[\uF134'
          htmlTbl += '<td  name=\'payload\' class=\'hide-el overhead\'>' + preHeader + '</td>'
          singleRowAttr = if typeof singleRowAttrs is 'undefined' or not singleRowAttrs? then null else singleRowAttrs[j]
          i = 0
          tl = tds.length
          while i < tl
            cellAttr = if typeof cellAttrs[j] is 'undefined' or not cellAttrs[j]? then null else cellAttrs[j][i]
            cellStyles = @getCellAttrs singleRowAttr, cellAttr, colAttrs[i], authors, i, j
            authorBorderColor = (@getCellAuthorColors authors, i, j, tblBorderWidth) + '!important;'
            borderTop = ''
            borderTop = ' border-top: 0px solid white !important;' if tblBorderWidth is 0
            colVAlign = if typeof colAttrs[i] is 'undefined' or not colAttrs[i]? then '' else 'align=\'' + colAttrs[i].colVAlign + '\'' or ''
            quoteAndComma = '\uF134,\uF134'
            cellDel = ''
            delimCell = '<td name=\'delimCell\' id=\'' + '\' class=\'hide-el overhead\'>' + quoteAndComma + '</td>'
            lastCellBorder = ''
            if i is tl - 1
              delimCell = ''
              lastCellBorder = 'border-right:' + tblBorderWidth + 'px solid ' + tblBorderColor + '!important;'
              quoteAndComma = ''
            if not ((tds[i].indexOf '/r/n') is -1)
              cellsWithBr = ''
              tdText = tds[i].split '/r/n'
              k = 0
              while k < tdText.length
                if k < tdText.length - 1
                  cellsWithBr += tdText[k] + "<span value='tblBreak'#{
                    if $.browser.msie and $.browser.version <= 7 then " contenteditable='false'" else ""
                  } class='hide-el'>/r/n</span><label class='tblBreak'></label>"
                else
                  cellsWithBr += tdText[k]
                k++
              htmlTbl += '<td  name=\'tData\' ' + colVAlign + ' style=\'' + printViewTblTDStyles + cellStyles + ' border-left:' + tblBorderWidth + 'px solid ' + tblBorderColor + authorBorderColor + borderTop + lastCellBorder + '\' >' + cellsWithBr + '<br value=\'tblBreak\'></td>' + delimCell
            else
              htmlTbl += '<td name=\'tData\' ' + colVAlign + ' style=\'' + printViewTblTDStyles + cellStyles + lastCellBorder + ' border-left:' + tblBorderWidth + 'px solid ' + tblBorderColor + authorBorderColor + borderTop + '\' >' + tds[i] + '' + '<br value=\'tblBreak\'></td>' + delimCell
            i++
          bracketAndcomma = '\uF134]],\uF134tblId\uF134:\uF134' + tblId + '\uF134,\uF134tblClass\uF134:\uF134\uFFF9\uF134}'
          htmlTbl += '<td name=\'bracketAndcomma\' class=\'  hide-el overhead\'>' + bracketAndcomma + '</td>'
          htmlTbl += '</tr>'
          j++
        htmlTbl += '</tbody></table>'
        htmlTbl
      getCellAuthorColors: (authors, cell, row, tblBorderWidth) ->
        cellBorderColor = null
        if typeof authors isnt 'undefined' and authors?
          for authorId of authors
            author = authors[authorId]
            cellBorderColor = author.colorId if typeof author isnt 'undefined' and author? and author.cell is cell and author.row is row
        borderWidth = if tblBorderWidth isnt 0 then tblBorderWidth else 1
        cellBorderColor = if not cellBorderColor? then '' else ';border:' + borderWidth + 'px solid ' + cellBorderColor
        cellBorderColor
      getCellAttrs: (singleRowAttr, cellAttr, colAttr, authors, cell, row) ->
        attrsJSO = {}
        colWidth = if typeof colAttr is 'undefined' or not colAttr? then '1' else colAttr.width or '1'
        attrsJSO.'width' = (@getAttrInInch colWidth) + 'px'
        cellBgColor = ''
        if typeof singleRowAttr isnt 'undefined' and singleRowAttr?
          bgColor = singleRowAttr.bgColor
          cellBgColor = bgColor if typeof bgColor isnt 'undefined' and bgColor? and bgColor isnt '#FFFFFF'
        if typeof colAttr isnt 'undefined' and colAttr?
          bgColor = colAttr.bgColor
          cellBgColor = bgColor if typeof bgColor isnt 'undefined' and bgColor? and bgColor isnt '#FFFFFF'
        cellBgColor = if typeof cellAttr is 'undefined' or not cellAttr? then cellBgColor else cellAttr.bgColor or cellBgColor
        attrsJSO.'background-color' = cellBgColor
        cellHeight = if typeof cellAttr is 'undefined' or not cellAttr? then '' else cellAttr.height or ''
        attrsJSO.'height' = (@getAttrInInch cellHeight) + 'px'
        cellPadding = if typeof cellAttr is 'undefined' or not cellAttr? then '' else cellAttr.padding or ''
        attrsJSO.'padding-top' = attrsJSO.'padding-bottom' = attrsJSO.'padding-left' = attrsJSO.'padding-right' = (@getAttrInInch cellPadding) + 'px'
        cellVAlign = if typeof cellAttr is 'undefined' or not cellAttr? then '' else cellAttr.vAlign or ''
        attrsJSO.'vertical-align' = cellVAlign
        cellFontSize = if typeof cellAttr is 'undefined' or not cellAttr? then '' else cellAttr.fontSize or ''
        attrsJSO.'font-size' = cellFontSize + 'px'
        cellFontWeight = if typeof cellAttr is 'undefined' or not cellAttr? then '' else cellAttr.fontWeight or ''
        attrsJSO.'font-weight' = cellFontWeight
        cellFontStyle = if typeof cellAttr is 'undefined' or not cellAttr? then '' else cellAttr.fontStyle or ''
        attrsJSO.'font-style' = cellFontStyle
        cellTextDecoration = if typeof cellAttr is 'undefined' or not cellAttr? then '' else cellAttr.textDecoration or ''
        attrsJSO.'text-decoration' = cellTextDecoration
        attrsString = ''
        [attrsString += attrName + ':' + attrsJSO[attrName] + ' !important;' if attrName and attrsJSO[attrName] isnt '' and attrsJSO[attrName] isnt 'NaNpx' and attrsJSO[attrName] isnt 'px' for attrName of attrsJSO]
        attrsString
      getAttrInInch: (attrValue) ->
        intAttrValue = 0
        intAttrValue = parseFloat attrValue
        attrValue = if isNaN intAttrValue then parseFloat attrValue else intAttrValue
        96 * attrValue - 1
      getHtml: (JSONCode, attributes) ->
        html = ''
        try
          html = @buildTabularData JSONCode, attributes
        catch
        html

exports?DatatablesRenderer = DatatablesRenderer
