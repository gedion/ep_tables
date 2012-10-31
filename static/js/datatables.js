var _, Ace2Common, Changeset, escapedJSON, fromEscapedJSON, Datatables;
_ = require('ep_etherpad-lite/static/js/underscore');
if (!(typeof require === 'undefined')) {
  if (typeof Ace2Common === 'undefined') {
    Ace2Common = require('ep_etherpad-lite/static/js/ace2_common');
  }
  if (typeof Changeset === 'undefined') {
    Changeset = require('ep_etherpad-lite/static/js/Changeset');
  }
}
escapedJSON = function(it){
  var ret;
  ret = JSON.stringify(it).replace(/\\u(....)|\\(.)/g, function(_, _1, _2){
    if (_1) {
      return String.fromCharCode(parseInt(_1, 16));
    } else {
      return "\\" + _1.charCodeAt(0) + ';';
    }
  }).replace(/"/g, '\uF134').replace(/\\(\d+);/g, function(_, _1){
    return "\\" + String.fromCharCode(_1);
  });
  return ret;
};
fromEscapedJSON = function(it){
  var ret;
  ret = JSON.parse(it.replace(/(\\|")/g, '\\$1').replace(/\uF134/g, '"'));
  return ret;
};
exports.aceInitialized = function(hook, context){
  var editorInfo;
  editorInfo = context.editorInfo;
  return editorInfo.ace_doDatatableOptions = _(Datatables.doDatatableOptions).bind(context);
};
exports.acePostWriteDomLineHTML = function(hook_name, arg$, cb){
  var node, children, i, element, lineText, ref$, dtAttrs, code, results$ = [];
  node = arg$.node;
  children = node.children;
  i = 0;
  while (i < children.length) {
    element = children[i++];
    if (element.className.indexOf('list') !== -1 || element.className.indexOf('tag') !== -1 || element.className.indexOf('url') !== -1) {
      continue;
    }
    lineText = (ref$ = element.innerText) != null
      ? ref$
      : element.textContent;
    if (lineText && lineText.indexOf('\uFFF9') !== -1) {
      dtAttrs = typeof exports.Datatables !== 'undefined' ? exports.Datatables.attributes : null;
      dtAttrs = dtAttrs || '';
      code = fromEscapedJSON(lineText);
      DatatablesRenderer.render({}, element, code, dtAttrs);
      results$.push(exports.Datatables.attributes = null);
    }
  }
  return results$;
};
exports.eejsBlock_scripts = function(hook_name, args, cb){
  return args.content = args.content + require('ep_etherpad-lite/node/eejs/').require('ep_tables/templates/datatablesScripts.ejs');
};
exports.eejsBlock_editbarMenuLeft = function(hook_name, args, cb){
  return args.content = args.content + require('ep_etherpad-lite/node/eejs/').require('ep_tables/templates/datatablesEditbarButtons.ejs');
};
exports.eejsBlock_styles = function(hook_name, args, cb){
  return args.content = require('ep_etherpad-lite/node/eejs/').require('ep_tables/templates/styles.ejs') + args.content;
};
exports.aceAttribsToClasses = function(hook, context){
  Datatables.attributes = null;
  if (context.key === 'tblProp') {
    Datatables.attributes = context.value;
    return ['tblProp:' + context.value];
  }
};
exports.aceStartLineAndCharForPoint = function(hook, context){
  var selStart, error;
  selStart = null;
  try {
    Datatables.context = context;
    if (Datatables.isFocused()) {
      selStart = Datatables.getLineAndCharForPoint();
    }
  } catch (e$) {
    error = e$;
    top.console.log('error ' + error);
    top.console.log('context rep' + Datatables.context.rep);
  }
  return selStart;
};
exports.aceEndLineAndCharForPoint = function(hook, context){
  var selEndLine, error;
  selEndLine = null;
  try {
    Datatables.context = context;
    if (Datatables.isFocused()) {
      selEndLine = Datatables.getLineAndCharForPoint();
    }
  } catch (e$) {
    error = e$;
    top.console.log('error ' + error);
    top.console.log('context rep' + Datatables.context.rep);
  }
  return selEndLine;
};
exports.aceKeyEvent = function(hook, context){
  var specialHandled, evt, type, keyCode, isTypeForSpecialKey, isTypeForCmdKey, which, e;
  specialHandled = false;
  try {
    Datatables.context = context;
    if (Datatables.isFocused()) {
      evt = context.evt;
      type = evt.type;
      keyCode = evt.keyCode;
      isTypeForSpecialKey = Ace2Common.browser.msie || Ace2Common.browser.safari
        ? type === 'keydown'
        : type === 'keypress';
      isTypeForCmdKey = Ace2Common.browser.msie || Ace2Common.browser.safari
        ? type === 'keydown'
        : type === 'keypress';
      which = evt.which;
      if (!specialHandled && isTypeForSpecialKey && keyCode === 9 && !(evt.metaKey || evt.ctrlKey)) {
        context.editorInfo.ace_fastIncorp(5);
        evt.preventDefault();
        Datatables.performDocumentTableTabKey();
        specialHandled = true;
      }
      if (!specialHandled && isTypeForSpecialKey && keyCode === 13) {
        context.editorInfo.ace_fastIncorp(5);
        evt.preventDefault();
        Datatables.doReturnKey();
        specialHandled = true;
      }
      if (!specialHandled && isTypeForSpecialKey && (keyCode === Datatables.vars.JS_KEY_CODE_DEL || keyCode === Datatables.vars.JS_KEY_CODE_BS || String.fromCharCode(which).toLowerCase() === 'h' && evt.ctrlKey)) {
        context.editorInfo.ace_fastIncorp(20);
        evt.preventDefault();
        specialHandled = true;
        if (Datatables.isCellDeleteOk(keyCode)) {
          Datatables.doDeleteKey();
        }
      }
    }
  } catch (e$) {
    e = e$;
  }
  return specialHandled;
};
Datatables = (function(){
  Datatables.displayName = 'Datatables';
  var nodeText, prototype = Datatables.prototype, constructor = Datatables;
  nodeText = function(n){
    var text, el, els, excluded, i, iLen;
    text = [];
    el = void 8;
    els = n.childNodes;
    excluded = {
      noscript: 'noscript',
      script: 'script'
    };
    i = 0;
    iLen = els.length;
    while (i < iLen) {
      el = els[i];
      if (el.nodeType === 1 && !(el.tagName.toLowerCase() in excluded)) {
        text.push(nodeText(el));
      } else if (el.nodeType === 3) {
        text.push(el.data);
      }
      i++;
    }
    return text.join('');
  };
  Datatables.defaults = {
    tblProps: {
      borderWidth: '1',
      cellAttrs: [],
      width: '6',
      rowAttrs: {},
      colAttrs: [],
      authors: {}
    }
  };
  Datatables.config = {};
  Datatables.vars = {
    OVERHEAD_LEN_PRE: '{\uF134payload\uF134:[[\uF134'.length,
    OVERHEAD_LEN_MID: '\uF134,\uF134'.length,
    OVERHEAD_LEN_ROW_START: '[\uF134'.length,
    OVERHEAD_LEN_ROW_END: '\uF134],'.length,
    JS_KEY_CODE_BS: 8,
    JS_KEY_CODE_DEL: 46,
    TBL_OPTIONS: ['addTbl', 'addTblRowA', 'addTblRowB', 'addTblColL', 'addTblColR', 'delTbl', 'delTblRow', 'delTblCol', 'delImg']
  };
  prototype.context = null;
  Datatables.isFocused = function(){
    var line, currLineText;
    if (!this.context.rep.selStart || !this.context.rep.selEnd) {
      return false;
    }
    line = this.context.rep.lines.atIndex(this.context.rep.selStart[0]);
    if (!line) {
      return false;
    }
    currLineText = line.text || '';
    if (currLineText.indexOf('\uFFF9') === -1) {
      return false;
    }
    return true;
  };
  Datatables._getRowEndOffset = function(rowStartOffset, tds){
    var rowEndOffset, i, len, overHeadLen;
    rowEndOffset = rowStartOffset + this.vars.OVERHEAD_LEN_ROW_START;
    i = 0;
    len = tds.length;
    while (i < len) {
      overHeadLen = this.vars.OVERHEAD_LEN_MID;
      if (i === len - 1) {
        overHeadLen = this.vars.OVERHEAD_LEN_ROW_END;
      }
      rowEndOffset += tds[i].length + overHeadLen;
      i++;
    }
    return rowEndOffset;
  };
  Datatables.getFocusedTdInfo = function(payload, colStart){
    var payloadOffset, rowStartOffset, payloadSum, rIndex, rLen, tds, tIndex, tLen, overHeadLen, leftOverTdTxtLen, cellCaretPos, rowEndOffset;
    payloadOffset = colStart - this.vars.OVERHEAD_LEN_PRE;
    rowStartOffset = 0;
    payloadSum = 0;
    rIndex = 0;
    rLen = payload.length;
    while (rIndex < rLen) {
      tds = payload[rIndex];
      tIndex = 0;
      tLen = tds.length;
      while (tIndex < tLen) {
        overHeadLen = this.vars.OVERHEAD_LEN_MID;
        if (tIndex === tLen - 1) {
          overHeadLen = this.vars.OVERHEAD_LEN_ROW_END;
        }
        payloadSum += tds[tIndex].length + overHeadLen;
        if (payloadSum >= payloadOffset) {
          if (payloadSum === payloadOffset) {
            tIndex++;
          }
          leftOverTdTxtLen = payloadSum - payloadOffset === 0
            ? payload[rIndex][tIndex].length + this.vars.OVERHEAD_LEN_MID
            : payloadSum - payloadOffset;
          cellCaretPos = tds[tIndex].length - leftOverTdTxtLen - overHeadLen;
          rowEndOffset = this._getRowEndOffset(rowStartOffset, tds);
          return {
            row: rIndex,
            td: tIndex,
            leftOverTdTxtLen: leftOverTdTxtLen,
            rowStartOffset: rowStartOffset,
            rowEndOffset: rowEndOffset,
            cellStartOffset: payloadSum - tds[tIndex].length - overHeadLen,
            cellEndOffset: payloadSum,
            cellCaretPos: cellCaretPos
          };
        }
        tIndex++;
      }
      rowStartOffset = payloadSum;
      payloadSum += this.vars.OVERHEAD_LEN_ROW_START;
      rIndex++;
    }
  };
  Datatables.printCaretPos = function(start, end){
    top.console.log(JSON.stringify(start));
    return top.console.log(JSON.stringify(end));
  };
  Datatables.doDatatableOptions = function(cmd, xByY){
    Datatables.context = this;
    if (typeof cmd === 'object' && cmd.tblPropertyChange) {
      return Datatables.updateTableProperties(cmd);
    } else {
      switch (cmd) {
      case Datatables.vars.TBL_OPTIONS[0]:
        return Datatables.addTable(xByY);
      case Datatables.vars.TBL_OPTIONS[1]:
        return Datatables.insertTblRow('addA');
      case Datatables.vars.TBL_OPTIONS[2]:
        return Datatables.insertTblRow('addB');
      case Datatables.vars.TBL_OPTIONS[3]:
        return Datatables.insertTblColumn('addL');
      case Datatables.vars.TBL_OPTIONS[4]:
        return Datatables.insertTblColumn('addR');
      case Datatables.vars.TBL_OPTIONS[5]:
        return Datatables.deleteTable();
      case Datatables.vars.TBL_OPTIONS[6]:
        return Datatables.deleteTblRow();
      case Datatables.vars.TBL_OPTIONS[7]:
        return Datatables.deleteTblColumn();
      }
    }
  };
  Datatables.addTable = function(tableObj){
    var rep, start, end, line, hasMoreRows, isRowAddition, table, currLineText, authors, xByYSelect, cols, rows, jsoStrTblProp, i;
    rep = this.context.rep;
    start = rep.selStart;
    end = rep.selEnd;
    line = rep.lines.atIndex(rep.selStart[0]);
    hasMoreRows = null;
    isRowAddition = null;
    if (tableObj) {
      hasMoreRows = tableObj.hasMoreRows;
      isRowAddition = tableObj.isRowAddition;
    }
    if (isRowAddition) {
      table = fromEscapedJSON(tableObj.tblString);
      insertTblRowBelow(0, table);
      performDocApplyTblAttrToRow(rep.selStart, JSON.stringify(table.tblProperties));
      return;
    }
    if (line) {
      currLineText = line.text;
      if (currLineText.indexOf('\uFFF9') !== -1) {
        do {
          rep.selStart[0] = rep.selStart[0] + 1;
          currLineText = rep.lines.atIndex(rep.selStart[0]).text;
        } while (currLineText.indexOf('\uFFF9') !== -1);
        rep.selEnd[1] = rep.selStart[1] = currLineText.length;
        this.context.editorInfo.ace_doReturnKey();
        this.context.editorInfo.ace_doReturnKey();
      } else {
        rep.selEnd[1] = rep.selStart[1] = currLineText.length;
        this.context.editorInfo.ace_doReturnKey();
      }
    }
    if (tableObj == null) {
      authors = {};
      this.insertTblRowBelow(3);
      this.performDocApplyTblAttrToRow(rep.selStart, this.createDefaultTblProperties());
      this.insertTblRowBelow(3);
      this.performDocApplyTblAttrToRow(rep.selStart, this.createDefaultTblProperties(authors));
      this.insertTblRowBelow(3);
      this.performDocApplyTblAttrToRow(rep.selStart, this.createDefaultTblProperties(authors));
      this.context.editorInfo.ace_doReturnKey();
      this.updateAuthorAndCaretPos(rep.selStart[0] - 3);
      return;
    }
    xByYSelect = typeof tableObj === 'object'
      ? null
      : tableObj.split('X');
    if (xByYSelect != null && xByYSelect.length === 3) {
      cols = parseInt(xByYSelect[1]);
      rows = parseInt(xByYSelect[2]);
      jsoStrTblProp = JSON.stringify(this.createDefaultTblProperties());
      authors = {};
      i = 0;
      while (i < rows) {
        this.insertTblRowBelow(cols);
        if (i === 0) {
          this.performDocApplyTblAttrToRow(rep.selStart, this.createDefaultTblProperties());
        } else {
          this.performDocApplyTblAttrToRow(rep.selStart, this.createDefaultTblProperties(authors));
        }
        i++;
      }
      this.updateAuthorAndCaretPos(rep.selStart[0] - rows + 1);
      return;
    }
    return newText;
  };
  Datatables.insertTblRow = function(aboveOrBelow){
    var func, rep, newText, currLineText, payload, currTdInfo, currRow, lastRowOffSet, start, end, updateEvenOddBgColor, e;
    func = 'insertTblRow()';
    rep = this.context.rep;
    try {
      newText = '';
      currLineText = rep.lines.atIndex(rep.selStart[0]).text;
      payload = fromEscapedJSON(currLineText).payload;
      currTdInfo = this.getFocusedTdInfo(payload, rep.selStart[1]);
      currRow = currTdInfo.row;
      lastRowOffSet = 0;
      start = [];
      end = [];
      start[0] = rep.selStart[0];
      start[1] = rep.selStart[1];
      end[0] = rep.selStart[0];
      end[1] = rep.selStart[1];
      if (aboveOrBelow === 'addA') {
        rep.selStart[0] = rep.selEnd[0] = rep.selStart[0] - 1;
        this.insertTblRowBelow(payload[0].length);
      } else {
        this.insertTblRowBelow(payload[0].length);
      }
      this.context.editorInfo.ace_performDocApplyTblAttrToRow(rep.selStart, this.createDefaultTblProperties());
      this.updateAuthorAndCaretPos(rep.selStart[0]);
      updateEvenOddBgColor = true;
      return this.sanitizeTblProperties(rep.selStart, updateEvenOddBgColor);
    } catch (e$) {
      return e = e$;
    }
  };
  Datatables.deleteTable = function(){
    var rep, func, start, end, line, numOfLinesAbove, numOfLinesBelow, e;
    rep = this.context.rep;
    func = 'deleteTable()';
    start = rep.seStart;
    end = rep.seEnd;
    try {
      line = rep.selStart[0] - 1;
      numOfLinesAbove = 0;
      numOfLinesBelow = 0;
      while (!(rep.lines.atIndex(line).text.indexOf('\uFFF9') === -1)) {
        numOfLinesAbove++;
        line--;
      }
      line = rep.selEnd[0] + 1;
      while (!(rep.lines.atIndex(line).text.indexOf('\uFFF9') === -1)) {
        numOfLinesBelow++;
        line++;
      }
      rep.selStart[1] = 0;
      rep.selStart[0] = rep.selStart[0] - numOfLinesAbove;
      rep.selEnd[0] = rep.selEnd[0] + numOfLinesBelow;
      rep.selEnd[1] = rep.lines.atIndex(rep.selEnd[0]).text.length;
      return this.context.editorInfo.ace_performDocumentReplaceRange(rep.selStart, rep.selEnd, '');
    } catch (e$) {
      return e = e$;
    }
  };
  Datatables.deleteTblRow = function(){
    var func, rep, currLineText, updateEvenOddBgColor, e;
    func = 'deleteTblRow()';
    rep = this.context.rep;
    try {
      currLineText = rep.lines.atIndex(rep.selStart[0]).text;
      if (currLineText.indexOf('\uFFF9') === -1) {
        return;
      }
      rep.selEnd[0] = rep.selStart[0] + 1;
      rep.selStart[1] = 0;
      rep.selEnd[1] = 0;
      this.context.editorInfo.ace_performDocumentReplaceRange(rep.selStart, rep.selEnd, '');
      currLineText = rep.lines.atIndex(rep.selStart[0]).text;
      if (currLineText.indexOf('\uFFF9') === -1) {
        return;
      }
      this.updateAuthorAndCaretPos(rep.selStart[0], 0, 0);
      updateEvenOddBgColor = true;
      return this.sanitizeTblProperties(rep.selStart, updateEvenOddBgColor);
    } catch (e$) {
      return e = e$;
    }
  };
  Datatables.updateTableProperties = function(props){
    var rep, currTd, currLine, currLineText, tblJSONObj, payload, currTdInfo, start, numOfLinesAbove, tempStart, results$ = [];
    rep = this.context.rep;
    currTd = null;
    if (props.tblColWidth || props.tblSingleColBgColor || props.tblColVAlign) {
      currLine = rep.lines.atIndex(rep.selStart[0]);
      currLineText = currLine.text;
      tblJSONObj = fromEscapedJSON(currLineText);
      payload = tblJSONObj.payload;
      currTdInfo = this.getFocusedTdInfo(payload, rep.selStart[1]);
      currTd = currTdInfo.td;
    }
    if (props.tblWidth || props.tblHeight || props.tblBorderWidth || props.tblBorderColor || props.tblColWidth || props.tblSingleColBgColor || props.tblEvenRowBgColor || props.tblOddRowBgColor || props.tblColVAlign) {
      start = [];
      start[0] = rep.selStart[0];
      start[1] = rep.selStart[1];
      numOfLinesAbove = this.getTblAboveRowsFromCurFocus(start);
      tempStart = [];
      tempStart[0] = start[0] - numOfLinesAbove;
      tempStart[1] = start[1];
      while (tempStart[0] < rep.lines.length() && rep.lines.atIndex(tempStart[0]).text.indexOf('\uFFF9') !== -1) {
        if (props.tblEvenRowBgColor && tempStart[0] % 2 !== 0) {
          tempStart[0] = tempStart[0] + 1;
          continue;
        } else {
          if (props.tblOddRowBgColor && tempStart[0] % 2 === 0) {
            tempStart[0] = tempStart[0] + 1;
            continue;
          }
        }
        this.updateTablePropertiesHelper(props, tempStart, currTd);
        results$.push(tempStart[0] = tempStart[0] + 1);
      }
      return results$;
    } else {
      start = [];
      start[0] = rep.selStart[0];
      start[1] = rep.selStart[1];
      return this.updateTablePropertiesHelper(props, start, currTd);
    }
  };
  Datatables.addCellAttr = function(start, tblJSONObj, tblProperties, attrName, attrValue){
    var rep, payload, currTdInfo, currRow, currTd, cellAttrs, row, cell;
    rep = this.context.rep;
    payload = tblJSONObj.payload;
    currTdInfo = this.getFocusedTdInfo(payload, start[1]);
    currRow = currTdInfo.row;
    currTd = currTdInfo.td;
    cellAttrs = tblProperties.cellAttrs;
    row = cellAttrs[currRow];
    if (row == null || typeof row === 'undefined') {
      row = [];
    }
    cell = row[currTd];
    if (cell == null || typeof cell === 'undefined') {
      cell = {};
    }
    if (attrName === 'fontWeight' || attrName === 'fontStyle' || attrName === 'textDecoration') {
      if (cell[attrName] === attrValue) {
        attrValue = '';
      }
    } else if (cell[attrName] === attrValue) {
      return false;
    }
    cell[attrName] = attrValue;
    row[currTd] = cell;
    cellAttrs[currRow] = row;
    tblProperties.cellAttrs = cellAttrs;
    return tblProperties;
  };
  Datatables.addRowAttr = function(tblJSONObj, tblProperties, attrName, attrValue){
    var rep, rowAttrs, payload, currTdInfo, currRow, singleRowAttrs;
    rep = this.context.rep;
    rowAttrs = tblProperties.rowAttrs;
    if (attrName === 'bgColor') {
      payload = tblJSONObj.payload;
      currTdInfo = this.getFocusedTdInfo(payload, rep.selStart[1]);
      currRow = currTdInfo.row;
      singleRowAttrs = rowAttrs.singleRowAttrs;
      if (singleRowAttrs == null || typeof singleRowAttrs === 'undefined') {
        singleRowAttrs = [];
      }
      if (singleRowAttrs[currRow] == null || typeof singleRowAttrs[currRow] === 'undefined') {
        singleRowAttrs[currRow] = {};
      } else if (singleRowAttrs[currRow][attrName] === attrValue) {
        return false;
      }
      singleRowAttrs[currRow][attrName] = attrValue;
      rowAttrs.singleRowAttrs = singleRowAttrs;
    } else {
      if (rowAttrs[attrName] === attrValue) {
        return false;
      }
      rowAttrs[attrName] = attrValue;
    }
    tblProperties.rowAttrs = rowAttrs;
    return tblProperties;
  };
  Datatables.addColumnAttr = function(start, tblJSONObj, tblProperties, attrName, attrValue, currTd){
    var payload, currTdInfo, colAttrs;
    payload = tblJSONObj.payload;
    currTdInfo = this.getFocusedTdInfo(payload, start[1]);
    colAttrs = tblProperties.colAttrs;
    if (colAttrs == null || typeof colAttrs === 'undefined') {
      colAttrs = [];
    }
    if (colAttrs[currTd] == null || typeof colAttrs[currTd] === 'undefined') {
      colAttrs[currTd] = {};
    } else if (colAttrs[currTd][attrName] === attrValue) {
      return false;
    }
    colAttrs[currTd][attrName] = attrValue;
    tblProperties.colAttrs = colAttrs;
    return tblProperties;
  };
  Datatables.updateTablePropertiesHelper = function(props, start, currTd){
    var rep, lastTblPropertyUsed, currLine, currLineText, tblJSONObj, tblProperties, update, currAttrValue, tblProps, e;
    rep = this.context.rep;
    lastTblPropertyUsed = 'updateTableProperties';
    start = start || rep.selStart;
    if (!start) {
      return;
    }
    currLine = rep.lines.atIndex(start[0]);
    currLineText = currLine.text;
    if (currLineText.indexOf('\uFFF9') === -1) {
      return true;
    }
    try {
      tblJSONObj = fromEscapedJSON(currLineText);
      tblProperties = this.getLineTableProperty(start[0]);
      update = false;
      if (props.tblWidth || props.tblHeight || props.tblBorderWidth || props.tblBorderColor) {
        currAttrValue = tblProperties[props.attrName];
        if (props.attrValue != null && (typeof currAttrValue === 'undefined' || currAttrValue !== props.attrValue)) {
          tblProperties[props.attrName] = props.attrValue;
          update = true;
        }
      }
      if (props.tblCellFontWeight || props.tblCellFontStyle || props.tblCellTextDecoration) {
        tblProps = this.addCellAttr(start, tblJSONObj, tblProperties, props.attrName, props.attrValue);
        if (tblProps) {
          tblProperties = tblProps;
          update = true;
        }
      }
      if (props.tblCellFontSize || props.tblCellBgColor || props.tblCellHeight || props.tblCellPadding || props.tblcellVAlign) {
        tblProps = this.addCellAttr(start, tblJSONObj, tblProperties, props.attrName, props.attrValue);
        if (tblProps) {
          tblProperties = tblProps;
          update = true;
        }
      }
      if (props.tblEvenRowBgColor || props.tblOddRowBgColor) {
        tblProps = this.addRowAttr(tblJSONObj, tblProperties, props.attrName, props.attrValue);
        if (tblProps) {
          tblProperties = tblProps;
          update = true;
        }
      }
      if (props.tblSingleRowBgColor || props.tblRowVAlign) {
        tblProps = this.addRowAttr(tblJSONObj, tblProperties, props.attrName, props.attrValue);
        if (tblProps) {
          tblProperties = tblProps;
          update = true;
        }
      }
      if (props.tblColWidth || props.tblSingleColBgColor || props.tblColVAlign) {
        tblProps = this.addColumnAttr(start, tblJSONObj, tblProperties, props.attrName, props.attrValue, currTd);
        if (tblProps) {
          tblProperties = tblProps;
          update = true;
        }
      }
      if (update) {
        return this.updateTblPropInAPool(-1, -1, tblProperties, start);
      }
    } catch (e$) {
      return e = e$;
    }
  };
  Datatables.updateAuthorAndCaretPos = function(magicDomLineNum, tblRowNum, tblColNum){
    var rep, row, col;
    rep = this.context.rep;
    rep.selStart[1] = rep.selEnd[1] = this.vars.OVERHEAD_LEN_PRE;
    rep.selStart[0] = rep.selEnd[0] = magicDomLineNum;
    row = typeof tblRowNum === 'undefined' || tblRowNum == null ? 0 : tblRowNum;
    col = typeof tblColNum === 'undefined' || tblRowNum == null ? 0 : tblColNum;
    this.updateTblPropInAPool(row, col, null, rep.selStart);
    rep.selStart[1] = rep.selEnd[1] = this.vars.OVERHEAD_LEN_PRE;
    return this.context.editorInfo.ace_performDocumentReplaceRange(rep.selStart, rep.selEnd, '');
  };
  Datatables.insertTblRowBelow = function(numOfRows, table){
    var rep, currLineText, payload, tblPayload, tblRows, i, tableObj;
    rep = this.rep;
    currLineText = rep.lines.atIndex(rep.selStart[0]).text;
    payload = [[]];
    if (!numOfRows && numOfRows !== 0) {
      tblPayload = fromEscapedJSON(currLineText).payload;
      numOfRows = tblPayload[0].length;
    }
    tblRows = new Array(numOfRows);
    if (!(numOfRows === 0)) {
      i = 0;
      while (i < tblRows.length) {
        tblRows[i] = ' ';
        i++;
      }
    }
    payload = [tblRows];
    if (table) {
      payload = table.payload;
    }
    tableObj = {
      payload: payload,
      tblId: 1,
      tblClass: '\uFFF9',
      trClass: 'alst',
      tdClass: 'hide-el'
    };
    rep.selEnd[1] = rep.selStart[1] = currLineText.length;
    this.context.editorInfo.ace_doReturnKey();
    return this.context.editorInfo.ace_performDocumentReplaceRange(rep.selStart, rep.selEnd, escapedJSON(tableObj));
  };
  Datatables.createDefaultTblProperties = function(authors){
    var rep, defTblProp, prevLine, jsoTblProp, prevLineText, nextLine, nextLineText, jsoStrTblProp;
    rep = this.context.rep;
    defTblProp = {
      borderWidth: '1',
      cellAttrs: [],
      width: '6',
      rowAttrs: {},
      colAttrs: [],
      authors: {}
    };
    if (authors) {
      defTblProp['authors'] = authors;
    }
    prevLine = rep.lines.atIndex(rep.selEnd[0] - 1);
    jsoTblProp = null;
    if (prevLine) {
      prevLineText = prevLine.text;
      if (!(prevLineText.indexOf('\uFFF9') === -1)) {
        jsoTblProp = this.getLineTableProperty(rep.selStart[0] - 1);
      }
    }
    if (!jsoTblProp) {
      nextLine = rep.lines.atIndex(rep.selEnd[0] - 1);
      if (nextLine) {
        nextLineText = nextLine.text;
        if (!(nextLineText.indexOf('\uFFF9') === -1)) {
          jsoTblProp = this.getLineTableProperty(rep.selStart[0] + 1);
        }
      }
    }
    if (jsoTblProp) {
      defTblProp.borderWidth = jsoTblProp.borderWidth;
      defTblProp.borderColor = jsoTblProp.borderColor;
      defTblProp.width = jsoTblProp.width;
      defTblProp.height = jsoTblProp.height;
      defTblProp.colAttrs = jsoTblProp.colAttrs;
    }
    jsoStrTblProp = JSON.stringify(defTblProp);
    return jsoStrTblProp;
  };
  Datatables.performDocApplyTblAttrToRow = function(start, jsoStrTblProp){
    var tempStart, tempEnd;
    tempStart = [];
    tempEnd = [];
    tempStart[0] = start[0];
    tempEnd[0] = start[0];
    tempStart[1] = 0;
    tempEnd[1] = this.context.rep.lines.atIndex(start[0]).text.length;
    return this.context.editorInfo.ace_performDocumentApplyAttributesToRange(tempStart, tempEnd, [['tblProp', jsoStrTblProp]]);
  };
  Datatables.performDocumentTableTabKey = function(){
    var context, rep, currLine, currLineText, tblJSONObj, payload, currTdInfo, leftOverTdTxtLen, currRow, currTd, nextLine, nextLineText, updateEvenOddBgColor, start, nextTdTxtLen, e;
    try {
      context = this.context;
      rep = context.rep;
      currLine = rep.lines.atIndex(rep.selStart[0]);
      currLineText = currLine.text;
      tblJSONObj = fromEscapedJSON(currLineText);
      payload = tblJSONObj.payload;
      currTdInfo = this.getFocusedTdInfo(payload, rep.selStart[1]);
      leftOverTdTxtLen = currTdInfo.leftOverTdTxtLen;
      currRow = currTdInfo.row;
      currTd = currTdInfo.td;
      if (typeof payload[currRow][currTd + 1] === 'undefined') {
        currRow += 1;
        nextLine = rep.lines.atIndex(rep.selStart[0] + 1);
        nextLineText = nextLine.text;
        updateEvenOddBgColor = false;
        if (nextLineText == null || nextLineText === '' || nextLineText.indexOf('\uFFF9') === -1) {
          this.insertTblRowBelow(null, null);
          this.performDocApplyTblAttrToRow(rep.selStart, this.createDefaultTblProperties());
          rep.selEnd[1] = rep.selStart[1] = this.vars.OVERHEAD_LEN_PRE;
          updateEvenOddBgColor = true;
        } else {
          currTd = -1;
          rep.selStart[0] = rep.selEnd[0] = rep.selStart[0] + 1;
          tblJSONObj = fromEscapedJSON(nextLineText);
          payload = tblJSONObj.payload;
          leftOverTdTxtLen = payload[0][0].length;
          rep.selEnd[1] = rep.selStart[1] = this.vars.OVERHEAD_LEN_PRE + leftOverTdTxtLen;
        }
        context.editorInfo.ace_performDocumentReplaceRange(rep.selStart, rep.selEnd, '');
        start = [];
        start[0] = rep.selStart[0];
        start[1] = rep.selStart[1];
        return this.updateTblCellAuthor(0, 0, null, start, updateEvenOddBgColor);
      } else {
        nextTdTxtLen = typeof payload[currRow] === 'undefined'
          ? -leftOverTdTxtLen
          : payload[currRow][currTd + 1].length;
        payload = tblJSONObj.payload;
        rep.selStart[1] = rep.selEnd[1] = rep.selEnd[1] + nextTdTxtLen + leftOverTdTxtLen;
        context.editorInfo.ace_performDocumentReplaceRange(rep.selStart, rep.selEnd, '');
        return this.updateTblPropInAPool(currRow, currTd + 1, null, rep.selStart);
      }
    } catch (e$) {
      return e = e$;
    }
  };
  Datatables.getTdInfo = function(payload, tdIndex){
    var rep, startOffset, rowStartOffset, payloadSum, tds, tIndex, tLen, overHeadLen;
    rep = this.context.rep;
    startOffset = this.vars.OVERHEAD_LEN_PRE;
    rowStartOffset = startOffset;
    payloadSum = startOffset;
    tds = payload[0];
    tIndex = 0;
    tLen = tds.length;
    while (tIndex < tLen) {
      overHeadLen = this.vars.OVERHEAD_LEN_MID;
      if (tIndex === tLen - 1) {
        overHeadLen = this.vars.OVERHEAD_LEN_ROW_END;
      }
      payloadSum += tds[tIndex].length + overHeadLen;
      if (tIndex >= tdIndex) {
        return {
          cellStartOffset: payloadSum - tds[tIndex].length - overHeadLen,
          cellEndOffset: payloadSum
        };
      }
      tIndex++;
    }
  };
  Datatables.getNextTdInfo = function(payload, currTdInfo){
    var rep, startOffset, rowStartOffset, payloadSum, tds, tIndex, tLen, overHeadLen, leftOverTdTxtLen, rowEndOffset, tdInfo;
    rep = this.context.rep;
    startOffset = currTdInfo.rowEndOffset;
    rowStartOffset = startOffset;
    payloadSum = startOffset;
    tds = payload[currTdInfo.row];
    tIndex = 0;
    tLen = tds.length;
    while (tIndex < tLen) {
      overHeadLen = this.vars.OVERHEAD_LEN_MID;
      if (tIndex === tLen - 1) {
        overHeadLen = this.vars.OVERHEAD_LEN_ROW_END;
      }
      payloadSum += tds[tIndex].length + overHeadLen;
      if (tIndex >= currTdInfo.td) {
        leftOverTdTxtLen = payloadSum - startOffset === 0
          ? payload[currTdInfo.row + 1][tIndex].length + this.vars.OVERHEAD_LEN_MID
          : payloadSum - startOffset;
        rowEndOffset = this._getRowEndOffset(rowStartOffset, tds);
        tdInfo = {
          row: currTdInfo.row + 1,
          td: tIndex,
          leftOverTdTxtLen: leftOverTdTxtLen,
          rowStartOffset: rowStartOffset,
          rowEndOffset: rowEndOffset,
          cellStartOffset: payloadSum - tds[tIndex].length - overHeadLen,
          cellEndOffset: payloadSum
        };
        return tdInfo;
      }
      tIndex++;
    }
  };
  Datatables.insertTblColumn = function(leftOrRight, start, end){
    var rep, func, currLineText, tblJSONObj, payload, currTdInfo, currTd, numOfLinesAbove, cellPos, newText, updateEvenOddBgColor, updateColAttrs, e;
    rep = this.context.rep;
    func = 'insertTblColumn()';
    try {
      currLineText = rep.lines.atIndex(rep.selStart[0]).text;
      tblJSONObj = fromEscapedJSON(currLineText);
      payload = tblJSONObj.payload;
      currTdInfo = this.getFocusedTdInfo(payload, rep.selStart[1]);
      currTd = currTdInfo.td;
      start = [];
      end = [];
      start[0] = rep.selStart[0];
      start[1] = rep.selStart[1];
      end[0] = rep.selEnd[0];
      end[1] = rep.selEnd[1];
      if (leftOrRight === 'addL') {
        currTd -= 1;
      }
      numOfLinesAbove = this.getTblAboveRowsFromCurFocus(start);
      rep.selEnd[0] = rep.selStart[0] = rep.selStart[0] - numOfLinesAbove;
      while (rep.selStart[0] < rep.lines.length() && rep.lines.atIndex(rep.selStart[0]).text.indexOf('\uFFF9') !== -1) {
        currLineText = rep.lines.atIndex(rep.selStart[0]).text;
        tblJSONObj = fromEscapedJSON(currLineText);
        payload = tblJSONObj.payload;
        cellPos = this.getTdInfo(payload, currTd).cellEndOffset;
        newText = '\uF134 \uF134,';
        if (currTd === payload[0].length - 1) {
          rep.selStart[1] = rep.selEnd[1] = cellPos - this.vars.OVERHEAD_LEN_ROW_END + 1;
          newText = ',\uF134 \uF134';
        } else {
          if (currTd === -1) {
            rep.selStart[1] = rep.selEnd[1] = this.vars.OVERHEAD_LEN_PRE - 1;
          } else {
            rep.selStart[1] = rep.selEnd[1] = cellPos - 1;
          }
        }
        this.context.editorInfo.ace_performDocumentReplaceRange(rep.selStart, rep.selEnd, newText);
        rep.selEnd[0] = rep.selStart[0] = rep.selStart[0] + 1;
      }
      rep.selStart = start;
      rep.selEnd = end;
      if (leftOrRight === 'addL') {
        rep.selStart[1] = rep.selEnd[1] = this.vars.OVERHEAD_LEN_PRE;
        rep.selStart[0] = rep.selEnd[0] = rep.selStart[0];
        this.updateTblPropInAPool(0, 0, null, rep.selStart);
        rep.selStart[1] = rep.selEnd[1] = this.vars.OVERHEAD_LEN_PRE;
      }
      currTd++;
      updateEvenOddBgColor = false;
      updateColAttrs = true;
      this.sanitizeTblProperties(start, updateEvenOddBgColor, updateColAttrs, currTd, 'add');
      return this.context.editorInfo.ace_performDocumentReplaceRange(rep.selStart, rep.selEnd, '');
    } catch (e$) {
      return e = e$;
    }
  };
  Datatables.deleteTblColumn = function(){
    var func, rep, currLineText, tblJSONObj, payload, currTdInfo, currTd, start, end, numOfLinesAbove, cellTdInfo, newText, updateEvenOddBgColor, updateColAttrs, e;
    func = 'deleteTblColumn()';
    rep = this.context.rep;
    try {
      currLineText = rep.lines.atIndex(rep.selStart[0]).text;
      tblJSONObj = fromEscapedJSON(currLineText);
      payload = tblJSONObj.payload;
      if (payload[0].length === 1) {
        deleteTable();
      }
      currTdInfo = this.getFocusedTdInfo(payload, rep.selStart[1]);
      currTd = currTdInfo.td;
      start = [];
      end = [];
      start[0] = rep.selStart[0];
      start[1] = rep.selStart[1];
      end[0] = rep.selEnd[0];
      end[1] = rep.selEnd[1];
      numOfLinesAbove = this.getTblAboveRowsFromCurFocus(start);
      rep.selEnd[0] = rep.selStart[0] = rep.selStart[0] - numOfLinesAbove;
      while (rep.selStart[0] < rep.lines.length() && rep.lines.atIndex(rep.selStart[0]).text.indexOf('\uFFF9') !== -1) {
        currLineText = rep.lines.atIndex(rep.selStart[0]).text;
        tblJSONObj = fromEscapedJSON(currLineText);
        payload = tblJSONObj.payload;
        cellTdInfo = this.getTdInfo(payload, currTd);
        newText = '\uF134 \uF134,';
        if (currTd === payload[0].length - 1) {
          rep.selStart[1] = cellTdInfo.cellStartOffset - 2;
          rep.selEnd[1] = cellTdInfo.cellEndOffset - 2;
        } else {
          if (currTd === 0) {
            rep.selStart[1] = this.vars.OVERHEAD_LEN_PRE - 1;
            rep.selEnd[1] = cellTdInfo.cellEndOffset - 1;
          } else {
            rep.selStart[1] = cellTdInfo.cellStartOffset - 1;
            rep.selEnd[1] = cellTdInfo.cellEndOffset - 1;
          }
        }
        this.context.editorInfo.ace_performDocumentReplaceRange(rep.selStart, rep.selEnd, '');
        rep.selEnd[0] = rep.selStart[0] = rep.selStart[0] + 1;
      }
      rep.selStart = start;
      rep.selEnd = end;
      updateEvenOddBgColor = false;
      updateColAttrs = true;
      this.sanitizeTblProperties(start, updateEvenOddBgColor, updateColAttrs, currTd, 'del');
      return this.updateAuthorAndCaretPos(rep.selStart[0], 0, 0);
    } catch (e$) {
      return e = e$;
    }
  };
  Datatables.insertTblRowBelow = function(numOfRows, table){
    var context, rep, currLineText, payload, tblPayload, tblRows, i, tableObj;
    context = this.context;
    rep = context.rep;
    currLineText = rep.lines.atIndex(rep.selStart[0]).text;
    payload = [[]];
    if (!numOfRows && numOfRows !== 0) {
      tblPayload = fromEscapedJSON(currLineText).payload;
      numOfRows = tblPayload[0].length;
    }
    tblRows = new Array(numOfRows);
    if (!(numOfRows === 0)) {
      i = 0;
      while (i < tblRows.length) {
        tblRows[i] = ' ';
        i++;
      }
    }
    payload = [tblRows];
    if (table) {
      payload = table.payload;
    }
    tableObj = {
      payload: payload,
      tblId: 1,
      tblClass: '\uFFF9',
      trClass: 'alst',
      tdClass: 'hide-el'
    };
    rep.selEnd[1] = rep.selStart[1] = currLineText.length;
    this.context.editorInfo.ace_inCallStackIfNecessary('newline', this.context.editorInfo.ace_doReturnKey);
    return context.editorInfo.ace_performDocumentReplaceRange(rep.selStart, rep.selEnd, escapedJSON(tableObj));
  };
  Datatables.doReturnKey = function(){
    var context, rep, start, end, lastTblPropertyUsed, currLine, currLineText, func, currCarretPos, newText, jsonObj, payloadStr, error, e;
    context = this.context;
    rep = context.rep;
    start = rep.seStart;
    end = rep.selEnd;
    lastTblPropertyUsed = 'doTableReturnKey';
    currLine = rep.lines.atIndex(rep.selStart[0]);
    currLineText = currLine.text;
    if (!(currLineText.indexOf('\uFFF9') === -1)) {
      func = 'doTableReturnKey()';
      try {
        currCarretPos = rep.selStart[1];
        if (currLineText.substring(currCarretPos - 1, currCarretPos + 2) === '\uF134,\uF134') {
          return true;
        } else {
          if (currLineText.substring(currCarretPos - 2, currCarretPos + 1) === '\uF134,\uF134') {
            return true;
          } else {
            if (currCarretPos < this.vars.OVERHEAD_LEN_PRE) {
              return true;
            } else if (currCarretPos > currLineText.length) {
              return true;
            }
          }
        }
        start = rep.selStart;
        end = rep.selEnd;
        newText = ' /r/n ';
        start[1] = currCarretPos;
        end[1] = currCarretPos;
        try {
          jsonObj = fromEscapedJSON(currLineText.substring(0, start[1]) + newText + currLineText.substring(start[1]));
          payloadStr = escapedJSON(jsonObj.payload);
          if (currCarretPos > payloadStr.length + this.vars.OVERHEAD_LEN_PRE - 2) {
            return true;
          }
        } catch (e$) {
          error = e$;
          return true;
        }
        context.editorInfo.ace_performDocumentReplaceRange(start, end, newText);
      } catch (e$) {
        e = e$;
      }
      return true;
    }
  };
  Datatables.isCellDeleteOk = function(keyCode){
    var context, rep, start, end, currLine, currLineText, isDeleteAccepted, tblJSONObj, table, currTdInfo, cellEntryLen, currCarretPos, error;
    context = this.context;
    rep = context.rep;
    start = rep.selStart;
    end = rep.selEnd;
    currLine = rep.lines.atIndex(rep.selStart[0]);
    currLineText = currLine.text;
    if (currLineText.indexOf('\uFFF9') === -1) {
      return true;
    }
    isDeleteAccepted = false;
    try {
      tblJSONObj = fromEscapedJSON(currLineText);
      table = tblJSONObj.payload;
      currTdInfo = this.getFocusedTdInfo(table, rep.selStart[1]);
      cellEntryLen = table[currTdInfo.row][currTdInfo.td].length;
      currCarretPos = rep.selStart[1];
      if (currLineText.substring(currCarretPos - 1, currCarretPos + 2) === '\uF134,\uF134') {
        return false;
      } else {
        if (currLineText.substring(currCarretPos - 2, currCarretPos + 1) === '\uF134,\uF134') {
          return false;
        }
      }
      switch (keyCode) {
      case this.vars.JS_KEY_CODE_BS:
        if (cellEntryLen !== 0 && cellEntryLen > currTdInfo.leftOverTdTxtLen - this.vars.OVERHEAD_LEN_MID) {
          isDeleteAccepted = true;
        }
        break;
      case this.vars.JS_KEY_CODE_DEL:
        return false;
        if (cellEntryLen !== 0 && currTdInfo.leftOverTdTxtLen - this.vars.OVERHEAD_LEN_MID > 0) {
          isDeleteAccepted = true;
        }
        break;
      default:
        if (cellEntryLen !== 0 && cellEntryLen > currTdInfo.leftOverTdTxtLen - this.vars.OVERHEAD_LEN_MID) {
          isDeleteAccepted = true;
        }
      }
    } catch (e$) {
      error = e$;
      isDeleteAccepted = false;
    }
    return isDeleteAccepted;
  };
  Datatables.nodeTextPlain = function(n){
    return n.innerText || n.textContent || n.nodeValue || '';
  };
  Datatables.toString = function(){
    return 'ep_tables';
  };
  Datatables.getLineAndCharForPoint = function(){
    var context, point, root, N, ln, n, col, parNode, prevSib, textLen, lineEntry, lineNum;
    context = this.context;
    point = context.point;
    root = context.root;
    if (point.node === root) {
      if (point.index === 0) {
        return [0, 0];
      } else {
        N = this.context.rep.lines.length();
        ln = this.context.rep.lines.atIndex(N - 1);
        return [N - 1, ln.text.length];
      }
    } else {
      n = point.node;
      col = 0;
      if (nodeText(n) || point.index > 0) {
        col = point.index;
      }
      parNode = void 8;
      prevSib = void 8;
      while (!((parNode = n.parentNode) === root)) {
        if (prevSib = n.previousSibling) {
          n = prevSib;
          textLen = nodeText(n).length === 0
            ? this.nodeTextPlain(n).length
            : nodeText(n).length;
          col += textLen;
        } else {
          n = parNode;
        }
      }
      if (n.id === '') {
        console.debug('BAD');
      }
      if (n.firstChild && context.editorInfo.ace_isBlockElement(n.firstChild)) {
        col += 1;
      }
      lineEntry = this.context.rep.lines.atKey(n.id);
      lineNum = this.context.rep.lines.indexOfEntry(lineEntry);
      return [lineNum, col];
    }
  };
  Datatables.doDeleteKey = function(){
    var context, evt, handled, rep, editorInfo, lineNum, col, lineEntry, lineText, lineMarker, col2, tabSize, toDelete, theLine, action, prevLineListType, thisLineListType, prevLineEntry, prevLineBlank, docChar, deleteBackTo, returnKeyWitinTblOffset, line;
    context = this.context;
    evt = context.evt || {};
    handled = false;
    rep = this.context.rep;
    editorInfo = context.editorInfo;
    if (rep.selStart) {
      if (editorInfo.ace_isCaret()) {
        lineNum = editorInfo.ace_caretLine();
        col = editorInfo.ace_caretColumn();
        lineEntry = rep.lines.atIndex(lineNum);
        lineText = lineEntry.text;
        lineMarker = lineEntry.lineMarker;
        if (/^ +$/.exec(lineText.substring(lineMarker, col))) {
          col2 = col - lineMarker;
          tabSize = ''.length;
          toDelete = (col2 - 1) % tabSize + 1;
          editorInfo.ace_performDocumentReplaceRange([lineNum, col - toDelete], [lineNum, col], '');
          handled = true;
        }
      }
      if (!handled) {
        if (editorInfo.ace_isCaret()) {
          theLine = editorInfo.ace_caretLine();
          lineEntry = rep.lines.atIndex(theLine);
          if (editorInfo.ace_caretColumn() <= lineEntry.lineMarker) {
            action = 'delete_newline';
            prevLineListType = theLine > 0 ? editorInfo.ace_getLineListType(theLine - 1) : '';
            thisLineListType = editorInfo.ace_getLineListType(theLine);
            prevLineEntry = theLine > 0 && rep.lines.atIndex(theLine - 1);
            prevLineBlank = prevLineEntry && prevLineEntry.text.length === prevLineEntry.lineMarker;
            if (thisLineListType) {
              if (prevLineBlank && !prevLineListType) {
                editorInfo.ace_performDocumentReplaceRange([theLine - 1, prevLineEntry.text.length], [theLine, 0], '');
              } else {
                editorInfo.ace_performDocumentReplaceRange([theLine, 0], [theLine, lineEntry.lineMarker], '');
              }
            } else {
              if (theLine > 0) {
                editorInfo.ace_performDocumentReplaceRange([theLine - 1, prevLineEntry.text.length], [theLine, 0], '');
              }
            }
          } else {
            docChar = editorInfo.ace_caretDocChar();
            if (docChar > 0) {
              if (evt.metaKey || evt.ctrlKey || evt.altKey) {
                deleteBackTo = docChar - 1;
                while (deleteBackTo > lineEntry.lineMarker && editorInfo.ace_isWordChar(rep.alltext.charAt(deleteBackTo - 1))) {
                  deleteBackTo--;
                }
                editorInfo.ace_performDocumentReplaceCharRange(deleteBackTo, docChar, '');
              } else {
                returnKeyWitinTblOffset = 0;
                if (lineText.substring(col - 5, col) === '/r/n ') {
                  returnKeyWitinTblOffset = 4;
                }
                editorInfo.ace_performDocumentReplaceCharRange(docChar - 1 - returnKeyWitinTblOffset, docChar, '');
              }
            }
          }
        } else {
          editorInfo.ace_performDocumentReplaceRange(rep.selStart, rep.selEnd, '');
        }
      }
    }
    line = editorInfo.ace_caretLine();
    if (line !== -1 && editorInfo.ace_renumberList(line + 1) === null) {
      return editorInfo.ace_renumberList(line);
    }
  };
  Datatables.getLineTableProperty = function(lineNum){
    var rep, aline, opIter, tblJSString, error;
    rep = this.context.rep;
    aline = rep.alines[lineNum];
    if (aline) {
      opIter = Changeset.opIterator(aline);
      if (opIter.hasNext()) {
        tblJSString = Changeset.opAttributeValue(opIter.next(), 'tblProp', rep.apool);
        try {
          return JSON.parse(tblJSString);
        } catch (e$) {
          error = e$;
          return this.defaults.tblProps;
        }
      }
    }
    return this.defaults.tblProps;
  };
  Datatables.getCurrTblOddEvenRowBgColor = function(startRowNum, currRowNum){
    var rowBgColors, jsoTblProp1, jsoTblProp2;
    rowBgColors = {
      oddBgColor: null,
      evenBgColor: null
    };
    if (!(startRowNum === currRowNum)) {
      jsoTblProp1 = this.getLineTableProperty(startRowNum);
      jsoTblProp2 = this.getLineTableProperty(startRowNum + 1);
      rowBgColors.evenBgColor = jsoTblProp1['rowAttrs']['evenBgColor'] || jsoTblProp2['rowAttrs']['evenBgColor'];
      rowBgColors.oddBgColor = jsoTblProp1['rowAttrs']['oddBgColor'] || jsoTblProp2['rowAttrs']['oddBgColor'];
    }
    return rowBgColors;
  };
  Datatables.getTblAboveRowsFromCurFocus = function(start){
    var rep, numOfLinesAbove, line;
    rep = this.context.rep;
    numOfLinesAbove = 0;
    line = start[0] - 1;
    while (!(rep.lines.atIndex(line).text.indexOf('\uFFF9') === -1)) {
      numOfLinesAbove++;
      line--;
    }
    return numOfLinesAbove;
  };
  Datatables.updateTableIndices = function(tblProperties, currTd, addOrDel){
    var cellAttrs, rIndex, rLen, cellAttr, colAttrs;
    cellAttrs = tblProperties.cellAttrs;
    rIndex = 0;
    rLen = cellAttrs.length;
    while (rIndex < rLen) {
      cellAttr = cellAttrs[rIndex];
      if (addOrDel === 'add') {
        if (cellAttr) {
          cellAttr.splice(currTd, 0, null);
        }
      } else {
        if (cellAttr) {
          cellAttr.splice(currTd, 1);
        }
      }
      rIndex++;
    }
    colAttrs = tblProperties.colAttrs;
    if (addOrDel === 'add') {
      if (colAttrs) {
        colAttrs.splice(currTd, 0, null);
      }
    } else {
      if (colAttrs) {
        colAttrs.splice(currTd, 1);
      }
    }
    return tblProperties;
  };
  Datatables.sanitizeTblProperties = function(start, updateEvenOddBgColor, updateColAttrs, currTd, addOrDel){
    var rep, editorInfo, thisAuthor, numOfLinesAbove, tempStart, evenOddRowBgColors, jsoTblProp, update, results$ = [];
    rep = this.context.rep;
    editorInfo = this.context.editorInfo;
    thisAuthor = editorInfo.ace_getAuthor();
    numOfLinesAbove = this.getTblAboveRowsFromCurFocus(start);
    tempStart = [];
    tempStart[0] = start[0] - numOfLinesAbove;
    evenOddRowBgColors = {};
    updateEvenOddBgColor;
    while (tempStart[0] < rep.lines.length() && rep.lines.atIndex(tempStart[0]).text.indexOf('\uFFF9') !== -1) {
      jsoTblProp = this.getLineTableProperty(tempStart[0]);
      update = false;
      if (tempStart[0] !== start[0] && jsoTblProp['authors'] && jsoTblProp['authors'][thisAuthor]) {
        delete jsoTblProp['authors'][thisAuthor];
        update = true;
      }
      if (updateColAttrs) {
        jsoTblProp = this.updateTableIndices(jsoTblProp, currTd, addOrDel);
        update = true;
      }
      if (tempStart[0] !== start[0] && updateEvenOddBgColor) {
        delete jsoTblProp['rowAttrs']['oddBgColor'];
        delete jsoTblProp['rowAttrs']['evenBgColor'];
        update = true;
      }
      if (update) {
        this.updateTblPropInAPool(-1, -1, jsoTblProp, tempStart);
      }
      results$.push(tempStart[0] = tempStart[0] + 1);
    }
    return results$;
  };
  Datatables.updateTblPropInAPool = function(row, td, jsoTblProp, start){
    var rep, editorInfo, thisAuthor, authorInfos, tblProps, jsoStrTblProp, attrStart, attrEnd, e;
    try {
      rep = this.context.rep;
      editorInfo = this.context.editorInfo;
      thisAuthor = editorInfo.ace_getAuthor();
      authorInfos = editorInfo.ace_getAuthorInfos();
      tblProps = void 8;
      if (typeof jsoTblProp === 'undefined' || jsoTblProp == null) {
        jsoTblProp = this.getLineTableProperty(start[0]);
      }
      if (row !== -1 && td !== -1) {
        jsoTblProp['authors'][thisAuthor] = {
          row: row,
          cell: td,
          colorId: authorInfos[thisAuthor].bgcolor
        };
      }
      jsoStrTblProp = JSON.stringify(jsoTblProp);
      attrStart = [];
      attrEnd = [];
      attrStart[0] = start[0];
      attrStart[1] = 0;
      attrEnd[0] = start[0];
      attrEnd[1] = rep.lines.atIndex(start[0]).text.length;
      return editorInfo.ace_performDocumentApplyAttributesToRange(attrStart, attrEnd, [['tblProp', jsoStrTblProp]]);
    } catch (e$) {
      return e = e$;
    }
  };
  Datatables.updateTblCellAuthor = function(row, td, tblProperties, start, updateEvenOddBgColor){
    var tempStart;
    try {
      this.updateTblPropInAPool(row, td, tblProperties, start);
      tempStart = [];
      tempStart[0] = start[0];
      tempStart[1] = start[1];
      return this.sanitizeTblProperties(tempStart, updateEvenOddBgColor);
    } catch (e$) {}
  };
  function Datatables(){}
  return Datatables;
}());
if (typeof exports != 'undefined' && exports !== null) {
  exports.Datatables = Datatables;
}