/*
** Copyright (c) Oracle Corporation 2001. All Rights Reserved.
**
*/





function biNnShowtip(e,text,enc)
{
if (document.layers)
{
document.tooltip=new Layer(300);
document.tooltip.bgColor="lightyellow";
document.tooltip.document.open();
document.write("<html>");
if(enc!=null&&enc.length>0)
document.write("<head><meta http-equiv='content-type' content='text/html; charset="+enc+"'></head>");
document.write("<body><span class='OraBITooltipText'>"+text+"</span></body></html>");
document.tooltip.document.close();
document.tooltip.left=e.pageX+5;
document.tooltip.top=e.pageY+5;
document.tooltip.visibility="show";
} 
}

function biNnHidetip()
{
if (document.layers&&document.tooltip)
document.tooltip.visibility="hidden";
}

function biMzShowtip(e,text){
if (document.tooltipTimerID)
clearTimeout(document.tooltipTimerID);
var tooltip=document.getElementById("mzTooltip");
tooltip.innerHTML='<span class="OraBITooltipText">'+text+'</span>';
tooltip.style.left=e.pageX+5;
tooltip.style.top=e.pageY+5;
document.tooltipTimerID=setTimeout("document.getElementById('mzTooltip').style.visibility='visible'", 500); 
}
function biMzHidetip(){
if (document.tooltipTimerID)
{
clearTimeout(document.tooltipTimerID);
document.tooltipTimerID=null;
} 
document.getElementById("mzTooltip").style.visibility='hidden';
}

function bi_navOnChange(source, c1, c2, separatorIndex)
{
if(source==c1)
 {c2.selectedIndex=c1.selectedIndex;}
else
 {c1.selectedIndex=c2.selectedIndex}
}

function handleOperationChange(oper, swapName, source, target, dimNames, dimValues, edgeNames, edgeValues, tgtDimNames, tgtDimValues, tgtEdgeNames, swpDimNames, swpEdgeNames)
{
  var is_swap=(oper.options[oper.selectedIndex].value==swapName);
  source.swap=is_swap;
  var m=0;
  var sel=true;
  for(var i=0;i<dimValues.length;i++){
    var edge=dimValues[i].charAt(0);
    if(edge!='9'||is_swap){
      source.options[m++]=new Option(dimNames[i], dimValues[i], sel, sel);
      sel=false;
    }
  }
  if(is_swap){
    for(var j=0;j<edgeValues.length;j++){
      if(edgeNames[j].length>0)
        source.options[m++]=new Option(edgeNames[j], edgeValues[j], false, false);
    }
  }
  setChoiceListLength(m,source);
  source.selectedIndex=0;
  handleSourceSelectionChange(source, target, tgtDimNames, tgtDimValues, tgtEdgeNames, edgeValues, swpDimNames, dimValues, swpEdgeNames);
}
  
function handleSourceSelectionChange(source, target, tgtDimNames, tgtDimValues, tgtEdgeNames, edgeValues, swpDimNames, dimValues, swpEdgeNames)
{
  var ind=source.selectedIndex;
  var sel=true;
  var m=0;
  if (source.options.length>0)
  {
    if(!source.swap){
      var skip=false;
      var value=source.options[ind].value.substr(1);
      var edge=source.options[ind].value.charAt(0);
      for(var i=0;i<tgtDimValues.length;i++){
        if(value!=tgtDimValues[i].substr(1)){
          if(!skip){
            target.options[m++]=new Option(tgtDimNames[i], tgtDimValues[i], sel, sel);
            sel=false;
          }
          skip=false;
        }
        else{
          skip=!skip;
        }
      }
      for(var j=0;j<edgeValues.length;j++){
        if (edge!=edgeValues[j]){
          target.options[m++]=new Option(tgtEdgeNames[j], edgeValues[j], false, false);
        }
      }
    }
    else{
      var value=source.options[ind].value;
      if(value.length==1){
        for(var k=0;k<edgeValues.length;k++){
            if(swpEdgeNames[k].length>0&&value!=edgeValues[k]){
              target.options[m++]=new Option(swpEdgeNames[k], edgeValues[k], sel, sel);
            sel=false;
          }
        }
      }
      else{
        for(var n=0;n<dimValues.length;n++){
          if(dimValues[n]!=value){
            target.options[m++]=new Option(swpDimNames[n], dimValues[n].substring(1), sel, sel);
            sel=false;
          }
        }
      }
    }
  }
  setChoiceListLength(m,target);
  target.selectedIndex=0;
}
  
function setChoiceListLength(length, choice)
{
  while(length<choice.options.length){
    choice.options[(choice.options.length-1)]=null;
  }  
}

function populateChoice(choice, names, values, selectedValue)
{
  setChoiceListLength(names.length, choice);
  var selIndex = 0;
  for (var i=0; i < names.length; i++)
  {
    if (selectedValue == values[i]) selIndex = i;
    choice.options[i] = new Option(names[i], values[i], false, false);
  }
  choice.options.selectedIndex = selIndex;
}

var netscapeResizeScripts;
function setNetscapeResizeHandler()
{
  netscapeResizeScripts = new Array();
  window.onresize = handleNetscapeResize;
}

function handleNetscapeResize() {
  for(var i=0; i<netscapeResizeScripts.length; i++){
    eval(netscapeResizeScripts[i]); 
  }
}

function _bi_LOVSelect(c,text,value,multIndex)
{
  if(value!=(void 0)){
    var l=c.options.length;
    var index = -1;
    for (var i = 0; i < l; i++) {
      if (c.options[i].value == value) {
        index = i;
        break;
      }      
    }
    if (index != -1) {
      c.selectedIndex=index;
      c.BIpreviousIndex=index;
    }
    else {
      if (value.indexOf(";") != -1) {
        if (c.options[multIndex].value.indexOf(";") == -1) {
          for (var i = l; i > multIndex; i--) {
            c.options[i] = new Option(c.options[i-1].text,c.options[i-1].value,false,false);
          }
        }
        c.options[multIndex] = new Option(text, value, true, true);
        c.selectedIndex = multIndex;
        c.BIpreviousIndex = multIndex;
      }
      else {
        c.options[l]=new Option(c.options[l-1].text,c.options[l-1].value,false,false); 
        c.options[l-1]=new Option(text,value,true,true);
        c.selectedIndex=l-1;
        c.BIpreviousIndex=l-1;
      }
    }
    c.onchange(); // for components that want to submit whenever contents change
    if(c.biSubmitScript !=(void 0))// for components that only want to submit when the LOV submits
      eval(c.biSubmitScript);
  }
}
