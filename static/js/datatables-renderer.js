var DatatablesRenderer;
if (typeof DatatablesRenderer === 'undefined') {
  DatatablesRenderer = function(){
    var dRenderer;
    dRenderer = {
      render: function(params, element, attributes){
        var renderer, code;
        renderer = new DatatablesRenderer.Renderer;
        if (element.innerText) {
          code = element.innerText;
        } else {
          code = element.textContent;
        }
        return element.innerHTML = renderer.getHtml(code, attributes);
      }
    };
    dRenderer.Renderer = function(){};
    dRenderer.Renderer.prototype = {
      createDefaultTblProperties: function(authors){
        return {
          borderWidth: '1',
          cellAttrs: [],
          width: '6',
          rowAttrs: {},
          colAttrs: [],
          authors: {}
        };
      },
      buildTabularData: function(tblJSONObj, tblPropsJSString){
        var htmlTbl, tblId, tblClass, tdClass, trClass, payload, tblProperties, error, rowAttrs, singleRowAttrs, cellAttrs, colAttrs, tblWidth, tblHeight, tblBorderWidth, tblBorderColor, currRow, currCell, authors, printViewTBlStyles, printViewTblTDStyles, borders, rowVAlign, rows, evenRowBgColor, oddRowBgColor, j, rl, tds, rowBgColor, preHeader, singleRowAttr, i, tl, cellAttr, cellStyles, authorBorderColor, borderTop, colVAlign, quoteAndComma, cellDel, delimCell, lastCellBorder, cellsWithBr, tdText, k, bracketAndcomma;
        htmlTbl = '';
        tblId = tblJSONObj.tblId;
        tblClass = tblJSONObj.tblClass;
        tdClass = tblJSONObj.tdClass;
        trClass = tblJSONObj.trClass;
        payload = tblJSONObj.payload;
        tblProperties = {};
        try {
          tblProperties = JSON.parse(tblPropsJSString);
        } catch (e$) {
          error = e$;
          tblProperties = this.createDefaultTblProperties();
        }
        rowAttrs = tblProperties.rowAttrs;
        singleRowAttrs = rowAttrs.singleRowAttrs;
        cellAttrs = tblProperties.cellAttrs;
        colAttrs = tblProperties.colAttrs;
        tblWidth = typeof tblProperties === 'undefined' || tblProperties == null
          ? '1'
          : tblProperties.width || '1';
        tblWidth = this.getAttrInInch(tblWidth);
        tblHeight = typeof tblProperties === 'undefined' || tblProperties == null
          ? '.1'
          : tblProperties.height || '.1';
        tblHeight = this.getAttrInInch(tblHeight);
        tblBorderWidth = typeof tblProperties === 'undefined' || tblProperties == null
          ? 0
          : tblProperties.borderWidth || 0;
        tblBorderColor = typeof tblProperties === 'undefined' || tblProperties == null
          ? '#000000'
          : tblProperties.borderColor || '#000000';
        currRow = tblProperties.currRowAuthorIdx;
        currCell = tblProperties.currCellAuthorIdx;
        authors = tblProperties.authors;
        printViewTBlStyles = 'table-layout:fixed !important;border-collapse:collapse!important;font-family:Trebuchet MS!important;';
        printViewTblTDStyles = 'font-size: 1em!important;line-height: 1em!important;padding: 3px 7px 2px!important;word-wrap: break-word!important;';
        htmlTbl = '<table class=\'' + tblClass + '\' style=\'' + printViewTBlStyles + 'background-color:white;width:' + tblWidth + 'px!important;height:' + tblHeight + 'px!important; border-top: ' + tblBorderWidth + 'px solid ' + tblBorderColor + '!important;' + '\'><tbody>';
        borders = 'border-bottom:' + tblBorderWidth + 'px solid ' + tblBorderColor;
        rowVAlign = typeof rowAttrs === 'undefined' || rowAttrs == null
          ? 'left'
          : rowAttrs.rowVAlign || 'left';
        rows = tblJSONObj.payload;
        evenRowBgColor = typeof rowAttrs === 'undefined' || rowAttrs == null
          ? '#FFFFFF'
          : rowAttrs.evenBgColor || '#FFFFFF';
        oddRowBgColor = typeof rowAttrs === 'undefined' || rowAttrs == null
          ? null
          : rowAttrs.oddBgColor || null;
        j = 0;
        rl = rows.length;
        while (j < rl) {
          tds = rows[j];
          rowBgColor = oddRowBgColor;
          if (!rowBgColor) {
            rowBgColor = evenRowBgColor;
          }
          htmlTbl += '<tr style=\'vertical-align:' + rowVAlign + ';background-color:' + rowBgColor + '; ' + borders + '!important;\' class=\'' + trClass + '\'>';
          preHeader = '';
          if (j === 0) {
            preHeader = '{\uF134payload\uF134:[[\uF134';
          }
          htmlTbl += '<td  name=\'payload\' class=\'hide-el overhead\'>' + preHeader + '</td>';
          singleRowAttr = typeof singleRowAttrs === 'undefined' || singleRowAttrs == null
            ? null
            : singleRowAttrs[j];
          i = 0;
          tl = tds.length;
          while (i < tl) {
            cellAttr = typeof cellAttrs[j] === 'undefined' || cellAttrs[j] == null
              ? null
              : cellAttrs[j][i];
            cellStyles = this.getCellAttrs(singleRowAttr, cellAttr, colAttrs[i], authors, i, j);
            authorBorderColor = this.getCellAuthorColors(authors, i, j, tblBorderWidth) + '!important;';
            borderTop = '';
            if (tblBorderWidth === 0) {
              borderTop = ' border-top: 0px solid white !important;';
            }
            colVAlign = typeof colAttrs[i] === 'undefined' || colAttrs[i] == null
              ? ''
              : 'align=\'' + colAttrs[i].colVAlign + '\'' || '';
            quoteAndComma = '\uF134,\uF134';
            cellDel = '';
            delimCell = '<td name=\'delimCell\' id=\'' + '\' class=\'hide-el overhead\'>' + quoteAndComma + '</td>';
            lastCellBorder = '';
            if (i === tl - 1) {
              delimCell = '';
              lastCellBorder = 'border-right:' + tblBorderWidth + 'px solid ' + tblBorderColor + '!important;';
              quoteAndComma = '';
            }
            if (!(tds[i].indexOf('/r/n') === -1)) {
              cellsWithBr = '';
              tdText = tds[i].split('/r/n');
              k = 0;
              while (k < tdText.length) {
                if (k < tdText.length - 1) {
                  cellsWithBr += tdText[k] + '<label value=\'tblBreak\' class=\'hide-el\'>/r/n</label><label class=\'tblBreak\'></label>';
                } else {
                  cellsWithBr += tdText[k];
                }
                k++;
              }
              htmlTbl += '<td  name=\'tData\' ' + colVAlign + ' style=\'' + printViewTblTDStyles + cellStyles + ' border-left:' + tblBorderWidth + 'px solid ' + tblBorderColor + authorBorderColor + borderTop + lastCellBorder + '\' >' + cellsWithBr + '<br value=\'tblBreak\'></td>' + delimCell;
            } else {
              htmlTbl += '<td name=\'tData\' ' + colVAlign + ' style=\'' + printViewTblTDStyles + cellStyles + lastCellBorder + ' border-left:' + tblBorderWidth + 'px solid ' + tblBorderColor + authorBorderColor + borderTop + '\' >' + tds[i] + '' + '<br value=\'tblBreak\'></td>' + delimCell;
            }
            i++;
          }
          bracketAndcomma = '\uF134]],\uF134tblId\uF134:\uF1341\uF134,\uF134tblClass\uF134:\uF134\uFFF9\uF134}';
          htmlTbl += '<td name=\'bracketAndcomma\' class=\'  hide-el overhead\'>' + bracketAndcomma + '</td>';
          htmlTbl += '</tr>';
          j++;
        }
        htmlTbl += '</tbody></table>';
        return htmlTbl;
      },
      getCellAuthorColors: function(authors, cell, row, tblBorderWidth){
        var cellBorderColor, authorId, author, borderWidth;
        cellBorderColor = null;
        if (typeof authors !== 'undefined' && authors != null) {
          for (authorId in authors) {
            author = authors[authorId];
            if (typeof author !== 'undefined' && author != null && author.cell === cell && author.row === row) {
              cellBorderColor = author.colorId;
            }
          }
        }
        borderWidth = tblBorderWidth !== 0 ? tblBorderWidth : 1;
        cellBorderColor = cellBorderColor == null
          ? ''
          : ';border:' + borderWidth + 'px solid ' + cellBorderColor;
        return cellBorderColor;
      },
      getCellAttrs: function(singleRowAttr, cellAttr, colAttr, authors, cell, row){
        var attrsJSO, colWidth, cellBgColor, bgColor, cellHeight, cellPadding, cellVAlign, cellFontSize, cellFontWeight, cellFontStyle, cellTextDecoration, attrsString, attrName;
        attrsJSO = {};
        colWidth = typeof colAttr === 'undefined' || colAttr == null
          ? '1'
          : colAttr.width || '1';
        attrsJSO['width'] = this.getAttrInInch(colWidth) + 'px';
        cellBgColor = '';
        if (typeof singleRowAttr !== 'undefined' && singleRowAttr != null) {
          bgColor = singleRowAttr.bgColor;
          if (typeof bgColor !== 'undefined' && bgColor != null && bgColor !== '#FFFFFF') {
            cellBgColor = bgColor;
          }
        }
        if (typeof colAttr !== 'undefined' && colAttr != null) {
          bgColor = colAttr.bgColor;
          if (typeof bgColor !== 'undefined' && bgColor != null && bgColor !== '#FFFFFF') {
            cellBgColor = bgColor;
          }
        }
        cellBgColor = typeof cellAttr === 'undefined' || cellAttr == null
          ? cellBgColor
          : cellAttr.bgColor || cellBgColor;
        attrsJSO['background-color'] = cellBgColor;
        cellHeight = typeof cellAttr === 'undefined' || cellAttr == null
          ? ''
          : cellAttr.height || '';
        attrsJSO['height'] = this.getAttrInInch(cellHeight) + 'px';
        cellPadding = typeof cellAttr === 'undefined' || cellAttr == null
          ? ''
          : cellAttr.padding || '';
        attrsJSO['padding-top'] = attrsJSO['padding-bottom'] = attrsJSO['padding-left'] = attrsJSO['padding-right'] = this.getAttrInInch(cellPadding) + 'px';
        cellVAlign = typeof cellAttr === 'undefined' || cellAttr == null
          ? ''
          : cellAttr.vAlign || '';
        attrsJSO['vertical-align'] = cellVAlign;
        cellFontSize = typeof cellAttr === 'undefined' || cellAttr == null
          ? ''
          : cellAttr.fontSize || '';
        attrsJSO['font-size'] = cellFontSize + 'px';
        cellFontWeight = typeof cellAttr === 'undefined' || cellAttr == null
          ? ''
          : cellAttr.fontWeight || '';
        attrsJSO['font-weight'] = cellFontWeight;
        cellFontStyle = typeof cellAttr === 'undefined' || cellAttr == null
          ? ''
          : cellAttr.fontStyle || '';
        attrsJSO['font-style'] = cellFontStyle;
        cellTextDecoration = typeof cellAttr === 'undefined' || cellAttr == null
          ? ''
          : cellAttr.textDecoration || '';
        attrsJSO['text-decoration'] = cellTextDecoration;
        attrsString = '';
        for (attrName in attrsJSO) {
          if (attrName && attrsJSO[attrName] !== '' && attrsJSO[attrName] !== 'NaNpx' && attrsJSO[attrName] !== 'px') {
            attrsString += attrName + ':' + attrsJSO[attrName] + ' !important;';
          }
        }
        return attrsString;
      },
      getAttrInInch: function(attrValue){
        var intAttrValue;
        intAttrValue = 0;
        intAttrValue = parseFloat(attrValue);
        attrValue = isNaN(intAttrValue) ? parseFloat(attrValue) : intAttrValue;
        return 96 * attrValue - 1;
      },
      getHtml: function(code, attributes){
        var JSONCode, html, e;
        JSONCode = '';
        html = '';
        try {
          JSONCode = JSON.parse(code.replace(/(\\|")/g, '\\$1').replace(/\uF134/g, '"'));
          html = this.buildTabularData(JSONCode, attributes);
        } catch (e$) {
          e = e$;
        }
        return html;
      }
    };
    return dRenderer;
  }();
}
if (typeof exports !== 'undefined') {
  exports.DatatablesRenderer = DatatablesRenderer;
} else {
  null;
}