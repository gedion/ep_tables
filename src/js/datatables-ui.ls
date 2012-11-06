exports.aceInitInnerdocbodyHead = (hook_name, args, cb) ->
  args.iframeHTML.push '<link rel="stylesheet" type="text/css" href="../static/plugins/ep_tables/static/css/dataTables.css"/>'

exports.postAceInit = (hook, context) ->
  $.createTableMenu = (init) ->
    showTblPropPanel = ->
      if not $.tblPropDialog
        $.tblPropDialog = new YAHOO.widget.Dialog 'yui-tbl-prop-panel', {
          width: '600px'
          height: '450px'
          close: true
          visible: false
          zindex: 1001
          constraintoviewport: true
        }
        $.tblPropDialog.setBody $.getTblPropertiesHTML!
        $.tblPropDialog.render!
        $.alignMenu $.tblPropDialog, @id
        initTableProperties!
      $.tblPropDialog.show!
    createColorPicker = ->
      createOColorPicker = ->
        $.oColorPicker = new YAHOO.widget.ColorPicker 'color-picker-menu', {
          showhsvcontrols: false
          showrgbcontrols: false
          showwebsafe: false
          showhexsummary: false
          showhexcontrols: true
          images: {
            PICKER_THUMB: 'http://yui.yahooapis.com/2.9.0/build/colorpicker/assets/picker_thumb.png'
            HUE_THUMB: 'http://yui.yahooapis.com/2.9.0/build/colorpicker/assets/hue_thumb.png'
          }
        }
        $.oColorPicker.on 'rgbChange', colorPickerButtonClick
        $.colorPickerAligned = true
      handleColorPickerSubmit = -> colorPickerButtonClick $.oColorPicker.get 'hex'
      handleDialogCancel = -> @cancel!
      $.oColorPickerDialog = new YAHOO.widget.Dialog 'yui-picker-panel', {
        width: '500px'
        close: true
        visible: false
        zindex: 1002
        constraintoviewport: true
        buttons: [{
          text: 'Exit'
          handler: @handleDialogCancel
        }]
      }
      $.oColorPickerDialog.renderEvent.subscribe (-> createOColorPicker! if not $.oColorPicker)
      $.oColorPickerDialog.render!
      $.oColorPickerDialog.show!
    colorPickerButtonClick = (sColor) ->
      if typeof sColor is 'string' and sColor? and (sColor.indexOf '#') is -1
        sColor = '#' + sColor
      else
        if typeof sColor is 'object' then sColor = if not (@get 'hex')? then @get 'value' else '#' + @get 'hex'
      selParams = {
        borderWidth: null
        tblPropertyChange: true
      }
      switch $.tblfocusedProperty
      case 'tbl_border_color'
        selParams.tblBorderColor = true
        selParams.attrName = 'borderColor'
        $.borderColorPickerButton.set 'value', sColor
        ($ '#current-color').css 'backgroundColor', sColor
        ($ '#current-color').innerHTML = 'Current color is ' + sColor
      case 'tbl_cell_bg_color'
        selParams.tblCellBgColor = true
        selParams.attrName = 'bgColor'
        $.cellBgColorPickerButton.set 'value', sColor
        ($ '#current-cell-bg-color').css 'backgroundColor', sColor
        ($ '#current-cell-bg-color').innerHTML = 'Current color is ' + sColor
      case 'tbl_even_row_bg_color'
        selParams.tblEvenRowBgColor = true
        selParams.attrName = 'evenBgColor'
        $.evenRowBgColorPickerButton.set 'value', sColor
        ($ '#even-row-bg-color').css 'backgroundColor', sColor
        ($ '#even-row-bg-color').innerHTML = 'Current color is ' + sColor
      case 'tbl_odd_row_bg_color'
        selParams.tblOddRowBgColor = true
        selParams.attrName = 'oddBgColor'
        $.oddRowBgColorPickerButton.set 'value', sColor
        ($ '#odd-row-bg-color').css 'backgroundColor', sColor
        ($ '#odd-row-bg-color').innerHTML = 'Current color is ' + sColor
      case 'tbl_single_row_bg_color'
        selParams.tblSingleRowBgColor = true
        selParams.attrName = 'bgColor'
        $.singleRowBgColorPickerButton.set 'value', sColor
        ($ '#single-row-bg-color').css 'backgroundColor', sColor
        ($ '#single-row-bg-color').innerHTML = 'Current color is ' + sColor
      case 'tbl_single_col_bg_color'
        selParams.tblSingleColBgColor = true
        selParams.attrName = 'bgColor'
        $.singleColBgColorPickerButton.set 'value', sColor
        ($ '#single-col-bg-color').css 'backgroundColor', sColor
        ($ '#single-col-bg-color').innerHTML = 'Current color is ' + sColor
      selParams.attrValue = sColor
      context.ace.callWithAce ((ace) -> ace.ace_doDatatableOptions selParams), 'tblOptions', true
    top.templatesMenu.hide! if not (typeof top.templatesMenu is 'undefined')
    if $.tblContextMenu
      $.alignMenu $.tblContextMenu, 'tbl-menu'
      $.tblContextMenu.show!
      return 
    $.handleTableBorder = (selectValue) ->
      selParams = {
        tblBorderWidth: true
        attrName: 'borderWidth'
        attrValue: selectValue
        tblPropertyChange: true
      }
      context.ace.callWithAce ((ace) -> ace.ace_doDatatableOptions selParams), 'tblOptions', true
    $.getTblPropertiesHTML = ->
      '<span id=\'table_properties\'><span class=\'tbl-prop-menu-header\'></span><br><span id=\'tbl-prop-menu\'class=\'tbl-prop-menu\'>' + '<table class=\'left-tbl-props tbl-inline-block\'>' + '<tr><td class=\'tbl-prop-label-td\'><span class=\'tbl-prop-label\' style=\'padding-top: 8px;\'>Table border</span></td></tr>' + '<tr><td><span class=\'tbl-inline-block\' id=\'tbl_border_color\'> </span><span id=\'tbl_border_width\'class=\'tbl-inline-block tbl_border_width\'></span></td></tr>' + '<tr><td class=\'tbl-prop-label-td\'><span class=\'tbl-prop-label\'>Cell background color</span></td></tr><tr><td><span id=\'tbl_cell_bg_color\'></td></tr><tr><td></span></td></tr>' + '<tr><td class=\'tbl-prop-label-td\'><span class=\'tbl-prop-label\'>Even/Odd Row background color</span></td></tr>' + '\t<tr><td><span class=\'tbl-inline-block\' id=\'tbl_even_row_bg_color\'>Even   </span><span id=\'tbl_odd_row_bg_color\' class=\'tbl-inline-block\'>Odd</span></td></tr>' + '<tr><td class=\'tbl-prop-label-td\'><span class=\'tbl-prop-label\'>Single Row/Col background color</span></td></tr>' + '\t<tr><td><span class=\'tbl-inline-block\' id=\'tbl_single_row_bg_color\'>Single Row   </span><span id=\'tbl_single_col_bg_color\' class=\'tbl-inline-block\'>Single Col</span></td></tr>' + '<tr><td class=\'tbl-prop-label-td\'><span class=\'tbl-prop-label\'>Row/Col alignment</span></td></tr>' + '\t<tr><td><span class=\'tbl-inline-block\' id=\'tbl_row_v_align\'>Row align </span><span id=\'tbl_col_v_align\' class=\'tbl-inline-block\'>Col align</span></td></tr>' + '</table>' + '\t<span class=\' tbl-inline-block\'>' + '\t\t<span class=\'tbl-prop-label\' style=\'padding-top: 8px;\'>' + 'Dimensions(Inches) ' + '\t\t</span>  <span id=\'text_input_message\'></span>' + '\t\t<table class=\'tbl-prop-dim\'>' + '\t\t\t<tbody>' + '\t\t\t\t<tr>' + '\t\t\t\t\t<td>\t\t\t\t\t\t\t' + '\t\t\t\t\t\t<span class=\'tbl-prop-dim-label tbl-inline-block\'>' + '\t\t\t\t\t\t\t<label  >Table width</label>' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t\t<td class=\'td-spacer\'></td>' + '\t\t\t\t\t<td>' + '\t\t\t\t\t\t<span class=\' tbl-inline-block\'>' + '\t\t\t\t\t\t\t<input id=\'tbl_width\' type=\'text\' size=\'4\' class=\'text-input\' >' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t</tr>' + '\t\t\t\t<tr>' + '\t\t\t\t\t<td>\t\t\t\t\t\t\t' + '\t\t\t\t\t\t<span class=\'tbl-prop-dim-label tbl-inline-block\'>' + '\t\t\t\t\t\t\t<label  >Table height</label>' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t\t<td class=\'td-spacer\'></td>' + '\t\t\t\t\t<td>' + '\t\t\t\t\t\t<span class=\' tbl-inline-block\'>' + '\t\t\t\t\t\t\t<input id=\'tbl_height\' type=\'text\' size=\'4\' class=\'text-input\' >' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t</tr>' + '\t\t\t\t<tr>' + '\t\t\t\t\t<td>\t\t\t\t\t\t\t' + '\t\t\t\t\t\t<span class=\'tbl-prop-dim-label tbl-inline-block\'>' + '\t\t\t\t\t\t\t<label  >Column width</label>' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t\t<td class=\'td-spacer\'></td>' + '\t\t\t\t\t<td>' + '\t\t\t\t\t\t<span class=\' tbl-inline-block\'>' + '\t\t\t\t\t\t\t<input id=\'tbl_col_width\' type=\'text\' size=\'4\' class=\'text-input\' >' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t</tr>' + '\t\t\t\t<tr>' + '\t\t\t\t\t<td>\t' + '\t\t\t\t\t\t<span class=\'tbl-prop-dim-label tbl-inline-block\'>' + '\t\t\t\t\t\t\t<label  >Minimum row height</label>' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t\t<td class=\'td-spacer\'></td>' + '\t\t\t\t\t<td>' + '\t\t\t\t\t\t<span class=\' tbl-inline-block\'>' + '\t\t\t\t\t\t\t<input id=\'tbl_row_height\' type=\'text\' size=\'4\' class=\'text-input\' >' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t</tr>' + '\t\t\t\t<tr>' + '\t\t\t\t\t<td>' + '\t\t\t\t\t\t<span class=\'tbl-prop-dim-label tbl-inline-block\'>' + '\t\t\t\t\t\t\t<label >Cell padding</label>' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t\t<td class=\'td-spacer\'></td>' + '\t\t\t\t\t<td>' + '\t\t\t\t\t\t<span class=\' tbl-inline-block\'>' + '\t\t\t\t\t\t\t<input id=\'tbl_cell_padding\' type=\'text\' size=\'4\' class=\'text-input\'>' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t</tr>' + '\t\t\t</tbody>' + '\t\t</table>' + '\t\t<br> ' + '\t\t<span class=\'tbl-prop-label\' style=\'padding-top: 8px;\'>' + '\t\t\tFonts ' + '\t\t</span>' + '\t\t<table class=\'tbl-prop-dim\'>' + '\t\t\t\t<tr>' + '\t\t\t\t\t<td>' + '\t\t\t\t\t\t<span class=\'tbl-prop-dim-label tbl-inline-block\'>' + '\t\t\t\t\t\t\t<label >Cell font size</label>' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t\t<td class=\'select-font-spacer\'></td>' + '\t\t\t\t\t<td>' + '\t\t\t\t\t\t<span class=\' tbl-inline-block\'>' + '\t\t\t\t\t\t\t<input id=\'tbl_cell_font_size\' type=\'text\' size=\'4\' class=\'text-input\'>' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t</tr>' + '\t\t\t</tbody>' + '\t\t</table>' + '\t</span>' + '</span>' + '</span>' + '<span id=\'img_properties\'>' + '<span class=\'tbl-prop-menu-header\'></span><span id=\'img-prop-menu\'class=\'tbl-prop-menu\'>' + '<table class=\'left-tbl-props tbl-inline-block\'>' + '\t\t<caption><span class=\'tbl-prop-label\' style=\'padding-top: 8px;\'>' + '\t\t\tDimensions(Intches) ' + '\t\t</span></caption>' + '\t\t\t<tbody>' + '\t\t\t\t<tr>' + '\t\t\t\t\t<td>\t\t\t\t\t\t\t' + '\t\t\t\t\t\t<span class=\'tbl-prop-dim-label tbl-inline-block\'>' + '\t\t\t\t\t\t\t<label  >Image width</label>' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t\t<td class=\'td-spacer\'></td>' + '\t\t\t\t\t<td>' + '\t\t\t\t\t\t<span class=\' tbl-inline-block\'>' + '\t\t\t\t\t\t\t<input id=\'img_width\' type=\'text\' size=\'4\' class=\'text-input\' >' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t</tr>' + '\t\t\t\t<tr>' + '\t\t\t\t\t<td>\t\t\t\t\t\t\t' + '\t\t\t\t\t\t<span class=\'tbl-prop-dim-label tbl-inline-block\'>' + '\t\t\t\t\t\t\t<label  >Image height</label>' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t\t<td class=\'td-spacer\'></td>' + '\t\t\t\t\t<td>' + '\t\t\t\t\t\t<span class=\' tbl-inline-block\'>' + '\t\t\t\t\t\t\t<input id=\'img_height\' type=\'text\' size=\'4\' class=\'text-input\' >' + '\t\t\t\t\t\t</span>' + '\t\t\t\t\t</td>' + '\t\t\t\t</tr>' + '</table>' + '</span>' + '</span>'
    if typeof $.tblContextMenu is 'undefined'
      initTableProperties = ->
        colVAligns = [
          'Left'
          'Center'
          'Right'
        ]
        $.colVAlignsMenu = new YAHOO.widget.ContextMenu 'tbl_col_v_align_menu', {
          iframe: true
          zindex: 1003
          shadow: false
          position: 'dynamic'
          keepopen: true
          clicktohide: true
        }
        $.colVAlignsMenu.addItems colVAligns
        $.colVAlignsMenu.render document.body
        $.colVAlignsMenu.subscribe 'click', (p_sType, p_aArgs) ->
          oEvent = p_aArgs.0
          oMenuItem = p_aArgs.1
          if oMenuItem
            align = oMenuItem.cfg.getProperty 'text'
            selParams = {
              tblColVAlign: true
              attrName: 'colVAlign'
              attrValue: align
              tblPropertyChange: true
            }
            $.colVAlignsMenuButton.set 'value', selParams.attrValue
            ($ '#current-col-v-alignment').html align
            context.ace.callWithAce ((ace) -> ace.ace_doDatatableOptions selParams), 'tblOptions', true
        $.colVAlignsMenuButton = new YAHOO.widget.Button {
          disabled: false
          type: 'split'
          label: '<em id="current-col-v-alignment">Left</em>'
          container: 'tbl_col_v_align'
        }
        ($ '#tbl_col_v_align').click (->
          aligned = false
          $.alignMenu $.colVAlignsMenu, 'tbl_col_v_align' if not aligned
          if $.borderWidthsMenu then $.borderWidthsMenu.hide!
          if $.oColorPickerDialog then $.oColorPickerDialog.hide!
          $.colVAlignsMenu.show!
          vAlignValue = $.colVAlignsMenuButton.get 'value'
          if vAlignValue
            selParams = {
              tblColVAlign: true
              attrName: 'colVAlign'
              attrValue: vAlignValue
              tblPropertyChange: true
            }
            context.ace.callWithAce ((ace) -> ace.ace_doDatatableOptions selParams), 'tblOptions', true)
        rowVAligns = [
          'Top'
          'Center'
          'Bottom'
        ]
        $.rowVAlignsMenu = new YAHOO.widget.ContextMenu 'tbl_row_v_align_menu', {
          iframe: true
          zindex: 1003
          shadow: false
          position: 'dynamic'
          keepopen: true
          clicktohide: true
        }
        $.rowVAlignsMenu.addItems rowVAligns
        $.rowVAlignsMenu.render document.body
        $.rowVAlignsMenu.subscribe 'click', (p_sType, p_aArgs) ->
          oEvent = p_aArgs.0
          oMenuItem = p_aArgs.1
          if oMenuItem
            align = oMenuItem.cfg.getProperty 'text'
            selParams = {
              tblRowVAlign: true
              attrName: 'rowVAlign'
              attrValue: align
              tblPropertyChange: true
            }
            $.rowVAlignsMenuButton.set 'value', selParams.attrValue
            ($ '#current-v-alignment').html align
            context.ace.callWithAce ((ace) -> ace.ace_doDatatableOptions selParams), 'tblOptions', true
        $.rowVAlignsMenuButton = new YAHOO.widget.Button {
          disabled: false
          type: 'split'
          label: '<em id="current-v-alignment">Top</em>'
          container: 'tbl_row_v_align'
        }
        ($ '#tbl_row_v_align').click (->
          aligned = false
          $.alignMenu $.rowVAlignsMenu, 'tbl_row_v_align' if not aligned
          if $.borderWidthsMenu then $.borderWidthsMenu.hide!
          if $.oColorPickerDialog then $.oColorPickerDialog.hide!
          $.rowVAlignsMenu.show!
          vAlignValue = $.rowVAlignsMenuButton.get 'value'
          if vAlignValue
            selParams = {
              tblRowVAlign: true
              attrName: 'rowVAlign'
              attrValue: vAlignValue
              tblPropertyChange: true
            }
            context.ace.callWithAce ((ace) -> ace.ace_doDatatableOptions selParams), 'tblOptions', true)
        borderWidths = [
          '0px'
          '1px'
          '2px'
          '3px'
          '4px'
          '5px'
          '6px'
          '7px'
          '8px'
        ]
        $.borderWidthsMenu = new YAHOO.widget.ContextMenu 'tbl_border_width_menu', {
          iframe: true
          zindex: 1003
          shadow: false
          position: 'dynamic'
          keepopen: true
          clicktohide: true
        }
        $.borderWidthsMenu.addItems borderWidths
        $.borderWidthsMenu.render document.body
        $.borderWidthsMenu.subscribe 'click', (p_sType, p_aArgs) ->
          oEvent = p_aArgs.0
          oMenuItem = p_aArgs.1
          if oMenuItem
            borderReq = oMenuItem.cfg.getProperty 'text'
            selParams = {
              tblBorderWidth: true
              attrName: 'borderWidth'
              attrValue: borderReq.substring 0, borderReq.indexOf 'px'
              tblPropertyChange: true
            }
            $.borderWidthPickerButton.set 'value', selParams.attrValue
            ($ '#current-width').html borderReq
            context.ace.callWithAce ((ace) -> ace.ace_doDatatableOptions selParams), 'tblOptions', true
        $.borderWidthPickerButton = new YAHOO.widget.Button {
          disabled: false
          type: 'split'
          label: '<em id="current-width">1px</em>'
          container: 'tbl_border_width'
        }
        ($ '#tbl_border_width').click (->
          aligned = false
          $.alignMenu $.borderWidthsMenu, 'tbl_border_width' if not aligned
          if $.oColorPickerDialog then $.oColorPickerDialog.hide!
          if $.rowVAlignsMenu then $.rowVAlignsMenu.hide!
          $.borderWidthsMenu.show!
          widthValue = $.borderWidthPickerButton.get 'value'
          if widthValue
            selParams = {
              tblBorderWidth: true
              attrName: 'borderWidth'
              attrValue: widthValue
              tblPropertyChange: true
            }
            context.ace.callWithAce ((ace) -> ace.ace_doDatatableOptions selParams), 'tblOptions', true)
        $.tblfocusedProperty = ''
        ($ '#tbl_properties').click (->
          $.borderWidthsMenu.hide! if not (typeof $.borderWidthsMenu is 'undefined')
          if not (typeof $.oColorPickerDialog is 'undefined') then $.oColorPickerDialog.hide!
          if not (typeof $.rowVAlignsMenu is 'undefined') then $.rowVAlignsMenu.hide!)
        $.colorPickerAligned = false
        ($ '#tbl_border_color').click (->
          createColorPicker! if not $.colorPickerAligned
          $.alignMenu $.oColorPickerDialog, 'tbl_border_color'
          $.tblfocusedProperty = 'tbl_border_color'
          if $.rowVAlignsMenu then $.rowVAlignsMenu.hide!
          if $.borderWidthsMenu then $.borderWidthsMenu.hide!
          $.oColorPickerDialog.setHeader 'Please choose a color for: Table Border color'
          $.oColorPickerDialog.show!
          hexValue = $.borderColorPickerButton.get 'value'
          if hexValue then colorPickerButtonClick hexValue)
        $.borderColorPickerButton = new YAHOO.widget.Button {
          disabled: false
          type: 'split'
          label: '<em  class=\'color-picker-button\' id="current-color">Current color is #FFFFFF.</em>'
          container: 'tbl_border_color'
        }
        $.cellBgColorPickerButton = new YAHOO.widget.Button {
          disabled: false
          type: 'split'
          label: '<em class=\'color-picker-button\' id="current-cell-bg-color">Current color is #FFFFFF.</em>'
          container: 'tbl_cell_bg_color'
        }
        ($ '#tbl_cell_bg_color').click (->
          createColorPicker! if not $.colorPickerAligned
          $.alignMenu $.oColorPickerDialog, 'tbl_cell_bg_color'
          $.tblfocusedProperty = 'tbl_cell_bg_color'
          if $.rowVAlignsMenu then $.rowVAlignsMenu.hide!
          if $.borderWidthsMenu then $.borderWidthsMenu.hide!
          $.oColorPickerDialog.setHeader 'Please choose a color for: Cell Background color'
          $.oColorPickerDialog.show!
          hexValue = $.cellBgColorPickerButton.get 'value'
          if hexValue then colorPickerButtonClick hexValue)
        $.evenRowBgColorPickerButton = new YAHOO.widget.Button {
          disabled: false
          type: 'split'
          label: '<em class=\'color-picker-button\' id="even-row-bg-color">Current color is #FFFFFF.</em>'
          container: 'tbl_even_row_bg_color'
        }
        ($ '#tbl_even_row_bg_color').click (->
          createColorPicker! if not $.colorPickerAligned
          $.alignMenu $.oColorPickerDialog, 'tbl_even_row_bg_color'
          $.tblfocusedProperty = 'tbl_even_row_bg_color'
          if $.borderWidthsMenu then $.borderWidthsMenu.hide!
          if $.rowVAlignsMenu then $.rowVAlignsMenu.hide!
          $.oColorPickerDialog.setHeader 'Please choose a color for: Even Row Background color'
          $.oColorPickerDialog.show!
          hexValue = $.evenRowBgColorPickerButton.get 'value'
          if hexValue then colorPickerButtonClick hexValue)
        $.oddRowBgColorPickerButton = new YAHOO.widget.Button {
          disabled: false
          type: 'split'
          label: '<em class=\'color-picker-button\' id="odd-row-bg-color">Current color is #FFFFFF.</em>'
          container: 'tbl_odd_row_bg_color'
        }
        ($ '#tbl_odd_row_bg_color').click (->
          createColorPicker! if not $.colorPickerAligned
          $.alignMenu $.oColorPickerDialog, 'tbl_odd_row_bg_color'
          $.tblfocusedProperty = 'tbl_odd_row_bg_color'
          if $.rowVAlignsMenu then $.rowVAlignsMenu.hide!
          if $.borderWidthsMenu then $.borderWidthsMenu.hide!
          $.oColorPickerDialog.setHeader 'Please choose a color for: Odd Row Background color'
          $.oColorPickerDialog.show!
          hexValue = $.oddRowBgColorPickerButton.get 'value'
          if hexValue then colorPickerButtonClick hexValue)
        $.singleRowBgColorPickerButton = new YAHOO.widget.Button {
          disabled: false
          type: 'split'
          label: '<em class=\'color-picker-button\' id="single-row-bg-color">Current color is #FFFFFF.</em>'
          container: 'tbl_single_row_bg_color'
        }
        ($ '#tbl_single_row_bg_color').click (->
          createColorPicker! if not $.colorPickerAligned
          $.alignMenu $.oColorPickerDialog, 'tbl_single_row_bg_color'
          $.tblfocusedProperty = 'tbl_single_row_bg_color'
          if $.borderWidthsMenu then $.borderWidthsMenu.hide!
          if $.rowVAlignsMenu then $.rowVAlignsMenu.hide!
          $.oColorPickerDialog.setHeader 'Please choose a color for: Single Row Background color'
          $.oColorPickerDialog.show!
          hexValue = $.singleRowBgColorPickerButton.get 'value'
          if hexValue then colorPickerButtonClick hexValue)
        $.singleColBgColorPickerButton = new YAHOO.widget.Button {
          disabled: false
          type: 'split'
          label: '<em class=\'color-picker-button\' id="single-col-bg-color">Current color is #FFFFFF.</em>'
          container: 'tbl_single_col_bg_color'
        }
        ($ '#tbl_single_col_bg_color').click (->
          createColorPicker! if not $.colorPickerAligned
          $.alignMenu $.oColorPickerDialog, 'tbl_single_col_bg_color'
          $.tblfocusedProperty = 'tbl_single_col_bg_color'
          if $.rowVAlignsMenu then $.rowVAlignsMenu.hide!
          if $.borderWidthsMenu then $.borderWidthsMenu.hide!
          $.oColorPickerDialog.setHeader 'Please choose a color for: Single Column Background color'
          $.oColorPickerDialog.show!
          hexValue = $.singleColBgColorPickerButton.get 'value'
          if hexValue then colorPickerButtonClick hexValue)
        ($ '.text-input').change (->
          selParams = {tblPropertyChange: true}
          if @id is 'tbl_width'
            selParams.tblWidth = true
            selParams.attrName = 'width'
          else
            if @id is 'tbl_height'
              selParams.tblHeight = true
              selParams.attrName = 'height'
            else
              if @id is 'tbl_col_width'
                selParams.tblColWidth = true
                selParams.attrName = 'width'
              else
                if @id is 'tbl_row_height'
                  selParams.tblCellHeight = true
                  selParams.attrName = 'height'
                else
                  if @id is 'tbl_cell_padding'
                    selParams.tblCellPadding = true
                    selParams.attrName = 'padding'
                  else
                    if @id is 'tbl_cell_font_size'
                      selParams.tblCellFontSize = true
                      selParams.attrName = 'fontSize'
                    else
                      if @id is 'img_width'
                        selParams.imgWidth = true
                        selParams.attrName = 'width'
                      else
                        if @id is 'img_height'
                          selParams.imgHeight = true
                          selParams.attrName = 'height'
          selParams.attrValue = @value
          @value = ''
          ($ '#text_input_message').text 'Ok'
          ($ '#text_input_message').removeAttr 'style'
          ($ '#text_input_message').fadeOut 'slow'
          context.ace.callWithAce ((ace) -> ace.ace_doDatatableOptions selParams), 'tblOptions', true)
      matrixTable = '<table id=\'matrix_table\'class=\'matrix-table\'><caption></caption>    <tr value=1><td value=1> </td><td value=2> </td><td value=3> </td><td value=4> </td><td value=5> </td><td value=6> </td><td value=7> </td><td value=8> </td><td value=9> </td><td value=10> </td><td value=11> </td><td value=12> </td><td value=13> </td><td value=14> </td><td value=15> </td><td value=16> </td><td value=17> </td><td value=18> </td><td value=19> </td><td value=20> </td></tr>    <tr value=2 ><td value=1> </td><td value=2> </td><td value=3> </td><td value=4> </td><td value=5> </td><td value=6> </td><td value=7> </td><td value=8> </td><td value=9> </td><td value=10> </td><td value=11> </td><td value=12> </td><td value=13> </td><td value=14> </td><td value=15> </td><td value=16> </td><td value=17> </td><td value=18> </td><td value=19> </td><td value=20> </td></tr>    <tr value=3 ><td value=1> </td><td value=2> </td><td value=3> </td><td value=4> </td><td value=5> </td><td value=6> </td><td value=7> </td><td value=8> </td><td value=9> </td><td value=10> </td><td value=11> </td><td value=12> </td><td value=13> </td><td value=14> </td><td value=15> </td><td value=16> </td><td value=17> </td><td value=18> </td><td value=19> </td><td value=20> </td></tr>    <tr value=4><td value=1> </td><td value=2> </td><td value=3> </td><td value=4> </td><td value=5> </td><td value=6> </td><td value=7> </td><td value=8> </td><td value=9> </td><td value=10> </td><td value=11> </td><td value=12> </td><td value=13> </td><td value=14> </td><td value=15> </td><td value=16> </td><td value=17> </td><td value=18> </td><td value=19> </td><td value=20> </td></tr>    <tr value=5 ><td value=1> </td><td value=2> </td><td value=3> </td><td value=4> </td><td value=5> </td><td value=6> </td><td value=7> </td><td value=8> </td><td value=9> </td><td value=10> </td><td value=11> </td><td value=12> </td><td value=13> </td><td value=14> </td><td value=15> </td><td value=16> </td><td value=17> </td><td value=18> </td><td value=19> </td><td value=20> </td></tr>    <tr value=6><td value=1> </td><td value=2> </td><td value=3> </td><td value=4> </td><td value=5> </td><td value=6> </td><td value=7> </td><td value=8> </td><td value=9> </td><td value=10> </td><td value=11> </td><td value=12> </td><td value=13> </td><td value=14> </td><td value=15> </td><td value=16> </td><td value=17> </td><td value=18> </td><td value=19> </td><td value=20> </td></tr>    <tr value=7><td value=1> </td><td value=2> </td><td value=3> </td><td value=4> </td><td value=5> </td><td value=6> </td><td value=7> </td><td value=8> </td><td value=9> </td><td value=10> </td><td value=11> </td><td value=12> </td><td value=13> </td><td value=14> </td><td value=15> </td><td value=16> </td><td value=17> </td><td value=18> </td><td value=19> </td><td value=20> </td></tr>    <tr value=8><td value=1> </td><td value=2> </td><td value=3> </td><td value=4> </td><td value=5> </td><td value=6> </td><td value=7> </td><td value=8> </td><td value=9> </td><td value=10> </td><td value=11> </td><td value=12> </td><td value=13> </td><td value=14> </td><td value=15> </td><td value=16> </td><td value=17> </td><td value=18> </td><td value=19> </td><td value=20> </td></tr>    <tr value=9><td value=1> </td><td value=2> </td><td value=3> </td><td value=4> </td><td value=5> </td><td value=6> </td><td value=7> </td><td value=8> </td><td value=9> </td><td value=10> </td><td value=11> </td><td value=12> </td><td value=13> </td><td value=14> </td><td value=15> </td><td value=16> </td><td value=17> </td><td value=18> </td><td value=19> </td><td value=20> </td></tr>    <tr value=10><td height=10 value=1> </td><td value=2> </td><td value=3> </td><td value=4> </td><td value=5> </td><td value=6> </td><td value=7> </td><td value=8> </td><td value=9> </td><td value=10> </td><td value=11> </td><td value=12> </td><td value=13> </td><td value=14> </td><td value=15> </td><td value=16> </td><td value=17> </td><td value=18> </td><td value=19> </td><td value=20> </td></tr></table>'
      $.tblContextMenu = new YAHOO.widget.ContextMenu 'tbl_context_menu', {
        iframe: true
        zindex: 500
        shadow: false
        position: 'dynamic'
        keepopen: true
        clicktohide: true
      }
      $.tblContextMenu.addItems [
        [{
          text: 'Insert Table'
          submenu: {
            id: 'tbl_insert'
            itemData: ['<div id=\'select_matrix\'>0 X 0</div>']
          }
        }]
        [
          'Insert Row Above'
          'Insert Row Below'
          'Insert Column Right'
          'Insert Column Left'
        ]
        [
          'Delete Row'
          'Delete Column'
          'Delete Table'
        ]
      ]
      subMenus = $.tblContextMenu.getSubmenus!
      subMenus.0.setFooter matrixTable
      $.tblContextMenu.render document.body
      $.alignMenu = (menu, id, addX, addY, scrollY) ->
        region = YAHOO.util.Dom.getRegion id
        if typeof id is 'string' and (id is 'tbl-menu' or id is 'upload_image_cont')
          menu.cfg.setProperty 'xy', [region.left, region.bottom]
        else
          if typeof id is 'string' then menu.cfg.setProperty 'xy', [region.right, region.top] else menu.cfg.setProperty 'xy', [30 + addX, 36 + addY - scrollY]
      ($ 'table td').hover (->
        x = 0
        while x <= ($ this).index!
          y = 0
          while y <= ($ this).parent!.index!
            ((($ this).parent!.parent!.children!.eq y).children!.eq x).addClass 'selected'
            y++
          x++), -> ($ 'table td').removeClass 'selected'
      ($ 'table td').hover (->
        xVal = @getAttribute 'value'
        yVal = (($ this).closest 'tr').0.getAttribute 'value'
        ($ '#select_matrix').html xVal + ' X ' + yVal)
      ($ 'td', '#matrix_table').click ((e) ->
        context.ace.callWithAce ((ace) -> ace.ace_doDatatableOptions 'addTbl', 'addTblX' + ($ '#select_matrix').text!), 'tblOptions', true
        false)
      $.tblContextMenu.subscribe 'click', (p_sType, p_aArgs) ->
        oEvent = p_aArgs.0
        oMenuItem = p_aArgs.1
        if oMenuItem
          tblReq = oMenuItem.cfg.getProperty 'text'
          disabled = oMenuItem.cfg.getProperty 'disabled'
          return  if disabled
          id = ''
          switch tblReq
          case 'Insert Table'
            id = 'addTbl'
          case 'Insert Row Above'
            id = 'addTblRowA'
          case 'Insert Row Below'
            id = 'addTblRowB'
          case 'Insert Column Left'
            id = 'addTblColL'
          case 'Insert Column Right'
            id = 'addTblColR'
          case 'Delete Table'
            id = 'delTbl'
          case 'Delete Image'
            id = 'delImg'
          case 'Delete Row'
            id = 'delTblRow'
          case 'Delete Column'
            id = 'delTblCol'
          context.ace.callWithAce ((ace) -> ace.ace_doDatatableOptions id), 'tblOptions', true
          false
    if not init
      $.alignMenu $.tblContextMenu, 'tbl-menu'
      $.tblContextMenu.show!
  ($ '#tbl-menu').click $.createTableMenu
  YAHOO.util.Dom.addClass document.body, 'yui-skin-sam'
  ($ 'body').append $ '<div id="yui-picker-panel" class="yui-picker-panel">' + '<div class="hd">Please choose a color:</div>' + '<div class="bd">' + '\t<div class="yui-picker" id="color-picker-menu"></div>' + '</div>' + '<div class="ft"></div>' + '</div>'
  ($ 'body').append $ '<div id="yui-tbl-prop-panel" class="yui-picker-panel">' + '<div class="hd">Table/Image Properties</div>' + '<div class="bd">' + '\t<div class="yui-picker" id="tbl-props"></div>' + '</div>' + '<div class="ft"></div>' + '</div>'
  $.createTableMenu true
