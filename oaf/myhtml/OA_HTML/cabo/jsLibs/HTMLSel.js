/*
** Copyright (c) Oracle Corporation 2002. All Rights Reserved.
**
*/


function _bi_getSelection(model)
{
  if(_bi_isDatabodySelected(model))
    return "d";
  if(model.ranges==null||model.ranges.length==0)
    return "";
  var selection="";
  var rows=new Array(model.nRows);
  var cols=new Array(model.nCols);
  var cells=new Array();
  var has_columns=false;
  var has_rows=false;
  for(var i=0;i<model.ranges.length;i++)
  {
    var range=model.ranges[i];
    if(range.startCol!=null&&range.startRow!=null)
      cells[cells.length]=range;
    else if(range.startRow!=null)
    {
      if(range.startRow>=0&&range.endRow<model.nRows)
      {
        has_rows=true;
        for(var r=range.startRow;r<=range.endRow;r++)
          rows[r]=true;
      }
      else
        selection=_bi_addRow(selection,range.startRow,range.endRow);
    }
    else if(range.startCol!=null)
    {
      if(range.startCol>=0&&range.endCol<model.nCols)
      {
        has_columns=true;
        for(var c=range.startCol;c<=range.endCol;c++)
          cols[c]=true;
      }
      else
        selection=_bi_addCol(selection,range.startCol,range.endCol);
    }
  }
  for(var i=0;i<cells.length;i++)
  {
    if(cells[i]==null)
      continue;
    var range=cells[i];
    var selected=false;
    if(has_columns)
    {
      selected=true;
      for(var c=range.startCol;selected==true&&c<=range.endCol;c++)
        selected=cols[c];
    }
    if(selected!=true)
    {
      if(has_rows)
      {
        selected=true;
        for(var r=range.startRow;selected==true&&r<=range.endRow;r++)
          selected=rows[r];
      }
      for(var n=0;selected!=true&&n<cells.length;n++)
      {
        if(i==n||cells[n]==null)
          continue;
        var range2=cells[n];
        if(range2.startCol<=range.startCol&&range2.endCol>=range.endCol
           &&range2.startRow<=range.startRow&&range2.endRow>=range.endRow)
          selected=true;
      }
    }
    if(selected==true)
      cells[i]=null;
  }
  if(has_columns)
  {
    for(var i=0;i<cols.length;i++)
    {
      for(;cols[i]!=true&&i<cols.length;i++);
      if(i<cols.length)
      {
        var start=i;
        for(;cols[i]==true&&i<cols.length;i++);
        var end=i-1;
        selection=_bi_addCol(selection,start,end);
      }
    }
  }
  if(has_rows)
  {
    for(var i=0;i<rows.length;i++)
    {
      for(;rows[i]!=true&&i<rows.length;i++);
      if(i<rows.length)
      {
        var start=i;
        for(;rows[i]==true&&i<rows.length;i++);
        var end=i-1;
        selection=_bi_addRow(selection,start,end);
      }
    }
  }
  
  for(var i=0;i<cells.length;i++)
  {
    if(cells[i]==null)
      continue;
    var range=cells[i];
    if(range.startCol==range.endCol&&range.startRow==range.endRow)
      selection+=('c'+range.startCol+'c'+range.startRow);
    else
      selection+=('g'+range.startCol+'g'+range.startRow+'g'+range.endCol+'g'+range.endRow);  
  }
  return selection;
}

function _bi_addCol(selection,start,end)
{
  if(start==end)
    selection+=('a'+start);
  else
    selection+=('e'+start+'e'+end);
  return selection;
}

function _bi_addRow(selection,start,end)
{
  if(start==end)
    selection+=('b'+start);
  else
    selection+=('f'+start+'f'+end);
  return selection;
}

function _bi_setSelection(model, selection)
{
  if(selection.indexOf("d")!=-1)
  {
    model.databody=true;
    return;
  }
  var columns=selection.match(/a-?\d+/g);
  if(columns!=null)
  {
    for(var i=0;i<columns.length;i++)
    {
      var col=columns[i].substr(1)-0;
      _bi_setSelected(model, col, null, col, null);
    }
  }
  var colRanges=selection.match(/e-?\d+/g);
  if(colRanges!=null)
  {
    for(var i=0;i<colRanges.length-1;i+=2)
      _bi_setSelected(model, colRanges[i].substr(1)-0, null, colRanges[i+1].substr(1)-0, null);
  }
  var rows=selection.match(/b-?\d+/g);
  if(rows!=null)
  {
    for(var i=0;i<rows.length;i++)
    {
      var row=rows[i].substr(1)-0;
      _bi_setSelected(model, null, row, null, row);
    }
  }
  var rowRanges=selection.match(/f-?\d+/g);
  if(rowRanges!=null)
  {
    for(var i=0;i<rowRanges.length-1;i+=2)
      _bi_setSelected(model, null, rowRanges[i].substr(1)-0, null, rowRanges[i+1].substr(1)-0);
  }
  var cells=selection.match(/c-?\d+/g);
  if(cells!=null)
  {
    for(var i=0;i<cells.length-1;i+=2)
    {
      var col=cells[i].substr(1)-0;
      var row=cells[i+1].substr(1)-0;
      _bi_setSelected(model, col, row, col, row);
    }
  }
  var cellRanges=selection.match(/g-?\d+/g);
  if(cellRanges!=null)
  {
    for(var i=0;i<cellRanges.length-3;i+=4)
      _bi_setSelected(model, cellRanges[i].substr(1)-0, cellRanges[i+1].substr(1)-0, 
                  cellRanges[i+2].substr(1)-0, cellRanges[i+3].substr(1)-0);
  }
}
 

function _bi_updateSelection(model)
{
  var field = document.forms[model.form].elements[model.field];
  if(field!=null)
  {
     model.value=_bi_getSelection(model);
     field.value=model.value;
  }
  if(_bi_isDatabodySelected(model))
  {
    for(var r=0;r<model.nRows;r++)
      _bi_highliteRow(model, r);
    for(var c=0;c<model.nCols;c++)
      _bi_highliteBackground(_bi_getColumnGrabber(model, c), model.grabberSelColor);
    _bi_highliteBackground(_bi_getDatabodyGrabber(model), model.grabberSelColor);
    return;
  }
  if(model.ranges==null)
    return;
  for(var i=0;i<model.ranges.length;i++)
  {
    var range=model.ranges[i];
    if(range.startRow!=null&&range.startCol!=null)
    {
      for (var currRow=range.startRow;currRow<=range.endRow;currRow++)
        for (var currCol=range.startCol;currCol<=range.endCol;currCol++)
          _bi_highliteCell(model, currCol, currRow); 
    }
    else if(range.startRow!=null)
    {
      for (var currRow=range.startRow;currRow<=range.endRow;currRow++)
        _bi_highliteRow(model, currRow);
    }
    else if(range.startCol!=null)
    {
      for (var currCol=range.startCol;currCol<=range.endCol;currCol++)
        _bi_highliteColumn(model, currCol);
    }
  }
}

function _bi_getDatabodyCell(model, column, row)
{
  var cell=null;
  var colKey = column+"";
  var rowKey = row+"";

  if(model[colKey]!=null)
    cell=model[colKey][rowKey];
  if(cell==null)
  {
    cell=document.getElementById(model.prefix+"_c"+row+'_'+column);
    if(model[colKey]==null)
      model[colKey]=new Object();
    model[colKey][rowKey]=cell;
  }
  return cell;
}

function _bi_getColumnGrabber(model, column)
{
  var key="c"+column;
  var cell=model[key];
  if(cell==null)
  {
    cell=document.getElementById(model.prefix+"_e"+column);
    model[key]=cell;
  }
  return cell;
}

function _bi_getRowGrabber(model, row)
{
  var key = "r"+row;
  var cell=model[key];
  if(cell==null)
  {
    cell=document.getElementById(model.prefix+"_f"+row);
    model[key]=cell;
  }
  return cell;
}

function _bi_getDatabodyGrabber(model)
{
  var cell=model["d"];
  if(cell==null)
  {
    cell=document.getElementById(model.prefix+"_d");
    model["d"]=cell;
  }
  return cell;
}

function _bi_changeColor(color, mode)
{
  var ret=color;
  var red=-1;
  var green=-1;
  var blue=-1;
  if(color.length==7&&color.charAt(0)=='#')
  {
    red=parseInt(color.substring(1,3), 16);
    green=parseInt(color.substring(3,5), 16);
    blue=parseInt(color.substring(5,7), 16);
  }
  else if(color.indexOf("rgb")==0)
  {
    var chnls=color.match(/\d+/g);
    if(chnls!=null&&chnls.length>2)
    {
      red=chnls[0]-0;
      green=chnls[1]-0;
      blue=chnls[2]-0;
    }
  }
  if(red>=0&&green>=0&&blue>=0)
  {
    if(mode==1)
    {
      red = 255-red;
      green = 255-green;
      blue = 255-blue;
    }
    else
    {
      var darkFactor=0.65;
      red=Math.round(red*darkFactor);
      green=Math.round(green*darkFactor);
      blue=Math.round(blue*darkFactor);
      if(blue<50&&red<50&&green<50)
      {
        blue+=75;
        red+=75;
      }
      else if(red+green<30)
        red+=75;
    }
    var r = red.toString(16).toUpperCase();
    if(r.length==1)
      r='0'+r;
    var g = green.toString(16).toUpperCase();
    if(g.length==1)
      g='0'+g;
    var b = blue.toString(16).toUpperCase();
    if(b.length==1)
      b='0'+b;
    ret='#'+r+g+b;
  }
  return ret;
}

function _bi_highliteCell(model, column, row)
{
  if(column<0||column>=model.nCols||row<0||row>=model.nRows)
    return;
  var cell=_bi_getDatabodyCell(model, column, row);
  if(cell!=null)
  {
    if(cell.savedColor==null)
    {
      if(cell.style!=null)
        cell.savedColor=cell.style.backgroundColor;
      if(cell.savedColor==null)
        cell.savedColor="";
    }
    var newColor=null;
    if(model.mode!=2&&cell.savedColor.length>0)
      newColor=_bi_changeColor(cell.savedColor, model.mode);
    if(newColor==null)
      newColor=model.cellSelColor;
    _bi_highliteBackground(cell, newColor);
  }
}

function _bi_unhighliteCell(model, column, row)
{
  var cell=_bi_getDatabodyCell(model, column, row);
  if(cell!=null)
    cell.style.backgroundColor=cell.savedColor;
}

function _bi_highliteColumn(model, column)
{
  if(column<0||column>=model.nCols)
    return;
  _bi_highliteBackground(_bi_getColumnGrabber(model, column), model.grabberSelColor);
  for(var r=0;r<model.nRows;r++)
    _bi_highliteCell(model, column, r, true);
}

function _bi_highliteRow(model, row)
{
  if(row<0||row>=model.nRows)
    return;
  _bi_highliteBackground(_bi_getRowGrabber(model, row), model.grabberSelColor);
  for(var c=0;c<model.nCols;c++)
    _bi_highliteCell(model, c, row, true);
}

function _bi_clearBackground(cell)
{
  if(cell!=null)
    cell.style.backgroundColor="";  
}

function _bi_highliteBackground(cell, color)
{
  if(cell!=null)
    cell.style.backgroundColor=color;  
}

function _bi_unhighliteAll(model)
{
  if(_bi_isDatabodySelected(model))
  {
    _bi_clearBackground(_bi_getDatabodyGrabber(model));
    for(var col=0;col<model.nCols;col++)
      _bi_clearBackground(_bi_getColumnGrabber(model, col));
    for(var r=0;r<model.nRows;r++)
    {
      _bi_clearBackground(_bi_getRowGrabber(model, r));
      for(var c=0;c<model.nCols;c++)
        _bi_unhighliteCell(model, c, r);
    }
  }
  else if(model.ranges!=null)
  {
    for(var i=0;i<model.ranges.length;i++)
    {
      var range=model.ranges[i];
      if(range.startCol!=null&&range.startRow!=null)
      {
        for(var c=range.startCol;c<=range.endCol;c++)
          for(var r=range.startRow;r<=range.endRow;r++)
            _bi_unhighliteCell(model, c, r);
      }
      else if(range.startRow!=null)
      {
        for(var r=range.startRow;r<=range.endRow;r++)
        {
          if(r<0||r>=model.nRows)
            continue;
          _bi_clearBackground(_bi_getRowGrabber(model, r));
          for(var c=0;c<model.nCols;c++)
            _bi_unhighliteCell(model, c, r);
        }
      }
      else if(range.startCol!=null)
      {
        for(var c=range.startCol;c<=range.endCol;c++)
        {
          if(c<0||c>=model.nCols)
            continue;
          _bi_clearBackground(_bi_getColumnGrabber(model, c));
          for(var r=0;r<model.nRows;r++)
            _bi_unhighliteCell(model, c, r);  
        }
      }
    }
  }
}


function _bi_setSelected(model, startCol, startRow, endCol, endRow)
{
  if(model.ranges==null)
    model.ranges=new Array();
  var range=new Object();
  range.startCol=startCol;
  range.startRow=startRow;
  range.endCol=endCol;
  range.endRow=endRow;
  model.ranges[model.ranges.length]=range;
}


function _bi_removeLastSelection(model)
{
  var removed=null;
  if(model.ranges!=null&&model.ranges.length>0)
  {
    removed=model.ranges[model.ranges.length-1];  
    if(model.ranges.length==1)
      model.ranges=null;
    else
      model.ranges=model.ranges.slice(0, model.ranges.length-1);  
  }
  else
    model.ranges=null;
  return removed;
}

function _bi_setDatabodySelected(model)
{
  model.databody=true;
}

function _bi_isDatabodySelected(model)
{
  return (model.databody==true);
}

function _bi_clearAllSelected(model)
{
  model.databody=null; 
  model.ranges=null;
}

function _bi_isLeftButton(event)
{
  var left;
  if(document.all)
    left=(window.event.button==1);
  else
    left=(event.button==0);  
  return left;
}

function _bi_isCtrlKeyPressed(event)
{
  var ctrl;
  if(document.all)
    ctrl=window.event.ctrlKey;
  else
    ctrl=event.ctrlKey;  
  return ctrl;
}

function _bi_isShiftKeyPressed(event)
{
  var shift;
  if(document.all)
    shift=window.event.shiftKey;
  else
    shift=event.shiftKey;  
  return shift;
}
function _bi_isTabKeyPressed(event)
{
  var charCode;
  if(document.all)
    charCode=window.event.keyCode;
  else
    charCode=event.keyCode;  
  if(charCode==9)
    return true;
  return false;
}

function _bi_handleMouseMove(event, model) 
{
  if (model == null)
    return;
  if(window.event.button!=1)
  {
    model.mouseDown = false;
  }
}
function _bi_handleMouseDown(event, model, row, col) {
  if (model == null)
    return;
  if(!_bi_isLeftButton(event))
    return;
  var is_shift=_bi_isShiftKeyPressed(event)&&!(row==-1&&col==-1);
  var is_ctrl=_bi_isCtrlKeyPressed(event)&&!(row==-1&&col==-1);
  if(!is_ctrl&&!is_shift)
    _bi_unselectAll(model);
  if(_bi_isDatabodySelected(model))
    return;
  model.mouseDown=true;
  if(is_shift)
  {
    if(model.selStartRow==null||
      (model.selStartRow<0&&row>=0))
      model.selStartRow=0;
    if(model.selStartCol==null||
      (model.selStartCol<0&&col>=0))
      model.selStartCol=0;
    _bi_changeRange(model, row, col);
  }
  else
  {
    model.selStartRow = row;
    model.selStartCol = col;
    model.selEndRow = row;
    model.selEndCol = col;
    _bi_unhighliteAll(model);
    if(row>=0&&col>=0)
      _bi_setSelected(model, col, row, col, row);
    else if(col>=0)
      _bi_setSelected(model, col, null, col, null);
    else if(row>=0)
      _bi_setSelected(model, null, row, null, row);
    else if(!_bi_isDatabodySelected(model))
      _bi_setDatabodySelected(model);
    _bi_updateSelection(model);
  }
}
function _bi_handleKeyUp(event, model, row, col) {
  if (model == null)
    return;
  if(!_bi_isTabKeyPressed(event))
    return;
  _bi_unselectAll(model);
  model.selStartRow = row;
  model.selStartCol = col;
  model.selEndRow = row;
  model.selEndCol = col;
  _bi_unhighliteAll(model);
  _bi_setSelected(model, col, row, col, row);
  _bi_updateSelection(model);
}

function _bi_handleMouseDrag(event, model, row, col) 
{
  if (model == null)
    return;
  if(model.mouseDown==true)
  {
    if(row==-1&&model.selStartRow>=0)
      row=0;
    else if(col==-1&&model.selStartCol>=0)
      col=0;
    _bi_changeRange(model, row, col);
  }
}
function _bi_changeRange(model, row, col)
{
  if((model.selStartRow>=0&&row!=model.selEndRow)||
     (model.selStartCol>=0&&col!=model.selEndCol)) 
  {
    _bi_unhighliteAll(model);
    _bi_removeLastSelection(model);
    model.selEndRow = row;
    model.selEndCol = col;
    _bi_selectRange(model);
    _bi_updateSelection(model);
  }
}
function _bi_selectRange(model) 
{
  var startRow=model.selStartRow;
  var startCol=model.selStartCol;
  var endRow=model.selEndRow;
  var endCol=model.selEndCol;
  if (model.selStartRow>model.selEndRow)
  {
    startRow=model.selEndRow;
    endRow=model.selStartRow;
  }
  if (model.selStartCol>model.selEndCol)
  {
    startCol=model.selEndCol;
    endCol=model.selStartCol;
  }
  if(model.selEndCol>=0&&model.selEndRow>=0&&
     model.selStartCol>=0&&model.selStartRow>=0)
    _bi_setSelected(model, startCol, startRow, endCol, endRow);
  else if(model.selStartCol>=0&&model.selEndCol>=0)
    _bi_setSelected(model, startCol, null, endCol, null);
  else if(model.selStartRow>=0&&model.selEndRow>=0)
    _bi_setSelected(model, null, startRow, null, endRow);
}
function _bi_unselectAll(model)
{
  if (model == null)
    return;
  _bi_unhighliteAll(model);
  _bi_clearAllSelected(model);
  _bi_updateSelection(model);
}
function _bi_delayedUpdate()
{
  var obj=event.srcElement;
  if(obj.model!=(void 0)&&obj.model.value!=obj.value)
  {
    _bi_unhighliteAll(obj.model);
    _bi_clearAllSelected(obj.model);
    _bi_setSelection(obj.model, obj.value);
    _bi_updateSelection(obj.model);
  }
}
function _bi_initSelection(model,form,field,nRows,nCols,prefix,sellC,gsellC,mode)
{
  model.nRows=nRows;
  model.nCols=nCols;
  model.prefix=prefix;
  model.cellSelColor=sellC;
  model.grabberSelColor=gsellC;
  model.form=form;
  model.field=field;
  model.mode=mode;
  var hidden=document.forms[form].elements[field];
  _bi_setSelection(model, hidden.value);
  _bi_updateSelection(model);
  hidden.model=model;
  hidden.onpropertychange=_bi_delayedUpdate;
}
