/*=================================================================+
|               Copyright (c) 2000 Oracle Corporation              |
|                  Redwood Shores, California, USA                 |
|                       All rights reserved.                       |
+==================================================================+
| FILENAME                                                         |
|   oafcore510e.js                                                 |
|                                                                  |
| HISTORY                                                          |
|   21-JUN-02 rnarasim Created                                     |
|   25-SEP-02 hbyun    Added OnLovChoiceInit for messageLovChoice. |
|   22-OCT-02 hbyun    Added support for lovOnClickJS.             |
|   04-SEP-03 mbukhari Added ignoreWarnAboutChanges                |
|   29-SEP-03 akviswan Merged in richTextEditor.js                 |
|   06-OCT-03 aranka   Data Length Check for DataType CLOB         |
+==================================================================*/
/* $Header: oafcore510e.js 115.33 2003/09/05 12:00:30 nigoel noship $ */

//for enhancement 2752319
function checkSubmit(warnAboutChangesMesg)
{
  if (!isNavDirty())
    return true;
  return confirm(warnAboutChangesMesg);
} 

//function for bypassing the save model for selected beans
function ignoreWarnAboutChanges(url)
{
  document.location.href = url;
}

// Used for Long tips
function oaOpenWin(regCode, regAppId, baseAM, amUsg, transId, paramList)
{
  var url = "/OA_HTML/cabo/jsps/frameRedirect.jsp?";
  url += "redirect=/OA_HTML/OA.jsp&akRegionCode=" + regCode;
  url += "&akRegionApplicationId=" + regAppId + "&amUsageMode=" + amUsg;
  url += "&addBreadCrumb=S&baseAppMod=" + baseAM + "&transactionid=" + transId;
  url += paramList;
  openWindow(self, url, 'modal',{width:750, height:550, resizable:'yes'}, true); 
}

// Used for IM.
function oaOpenIMWin(IMCode,url)
{
  openWindow(self, url, IMCode,{width:200, height:400, resizable:'yes'}); 
}

// Used for LOV. Should be removed when we move to new UIX LOV
function lov(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, c, p)
{
  var url = "";
  var proxy = null;

  // lovRowNum
  if (a12 != null)
  {
    proxy = new TableProxy(a13);
    url += "&lovTableName=" + a13;
    url += "&lovRowNum=" + a12;
  }


  url += "&regionCode=" + a2;
  url += "&regionAppId=" + a3;
  url += "&lovBaseItemName=" + a4;
  url += "&lovLabel=" + a6;
  url += "&lovMainCriteria=" + escape(a7 + "::");

  if (a8)
    url += getCriteria(a4, a12, a14, proxy);
 

  var i = 0;
  for(paramName in c){
     var s = escape(paramName + "::") + getCriteria(c[paramName], a12, a14, proxy);
     url += "&CRITERIA" + i + "=" + s;
     i++;
  }

  i = 0;
  for(paramName in p){
     var s = escape(paramName + "::") + getCriteria(p[paramName], a12, a14,  proxy);
     url += "&PASSIVE_CRITERIA" + i + "=" + s;
     i++;
  }

  if (a9 != null)
    url += "&lovJS=" + a9;
  if (a10)
    url += "&flexLov=t";
  oaOpenWin(a0, a1, a5, "1", a11, url);
};

// Used for LOV. Should be removed when we move to new UIX LOV
// return LOV result
function putResult(formName, itemName, res)
{

  var item; 
  //var formName = "DefaultFormName";
  a9 = navigator.userAgent.toLowerCase();
  if(a9.indexOf("msie")!=-1)  
  { 
    item = document.getElementsByName(formName)[0][itemName];
  }
  else
  { 
    item = document.forms[formName][itemName];
  }

  if (item == 'undefined' || item == null){
    alert('LOV result ' + itemName + ' cannot be returned to base page.' + '\n' + 'It is either not rendered on the page or is not a form element.');
  }
  else if (item.type == 'select-one'){
    for (var i = 0; i < item.options.length; i++) {
      if (item.options[i].value == res){ 
         item.options[i].selected = true; break;
	}
     }
   }
   else 
    {
     // The res has decoded as it mayhave special chars
     item.value = res;
     }
     /// Fix for Bug 2608677 - hgandhi
     /// _unescape() was garbaging mutliByte chars like foriegn chars.

 
};

// Used for LOV. Should be removed when we move to new UIX LOV
// retrieve LOV criteria
function getCriteria(c, row, formName, proxy)
{
  var a0;
  var a9;
  if (row == null)
  {
    a9 = navigator.userAgent.toLowerCase();
    if(a9.indexOf("msie")!=-1)  
    { 
      a0 = document.getElementsByName(formName)[0][c];
    }
    else
    { 
      a0 = document.forms[formName][c];
    }
    
  }
  else
    a0 = proxy.getFormElement(c, row);

 //// Fix for Bug 2239664
 if (a0 == null)
 {
    //a0 = document.getElementsByName(formName)[0][c];
    a9 = navigator.userAgent.toLowerCase();
    if(a9.indexOf("msie")!=-1)  
    { 
      a0 = document.getElementsByName(formName)[0][c];
    }
    else
    { 
      a0 = document.forms[formName][c];
    }
 }

  var a1;
  if (a0.type == 'select-one')
     a1 = a0[a0.selectedIndex].value;
  else
     a1 = a0.value;
  return escape(escape(a1));
};


// Used for LOV. Should be removed when we move to new UIX LOV
function lovClearValue(formElement)
{
  var retVal = true;
  if (formElement== 'undefined' || formElement == null){
    retVal = false;}
  else if (formElement.type == 'select-one') {
    formElement.selectedIndex= 0; }
  else if (formElement.type == 'checkbox') {
    formElement.checked = false; }
  else if (formElement.value == '') {
    retVal = false; }
  else { formElement.value = ''; }
    return retVal; 
};

// Used for intermedia advanced search
// c is the conditionPicklist object, cName is its name
// b is the between item object, bName is its name
// v is the value of the conditionPickList object.
// vName is the name of the value bean to which between item should be added at the end.
// fName is the form name
function aSOnChange(fName, cName, vName)
{
  var c; 
  var v;
  var b;
  var browser= navigator.userAgent.toLowerCase();
  var bName = vName + ":betweenCaseBean" ;
  if(browser.indexOf("msie")!=-1)  
  { 
    c = document.getElementsByName(fName)[0][cName];
    b = document.getElementsByName(fName)[0][bName];
  }
  else
  { 
    c= document.forms[fName][cName];
    b= document.forms[fName][bName];
  }

  if (c== 'undefined' || c== null){
    alert('Cannot find the item: ' + c);
  }

  // netscape 4.7 is not happy with getting c.value
  if (c.type == 'select-one')
     v = c[c.selectedIndex].value;
  else
     v = c.value;

 
  if (v == 'BETWEEN' && (b=='undefined' || b== null))
  {
   // if the value is "between" and the between item is not rendered, then submit the form
   // to render it.
   // the event parameters are not used in the code right now, will be used later.
   submitForm(fName,0,{'_FORMEVENT':'addBetweenField','betweenSourceName':vName}); 	
  }
  if (v != 'BETWEEN' && (b != null))
  {
   // if the value is NOT "between" and the between item IS rendered, then submit the form
   // to NOT render it.
   submitForm(fName,0,{'_FORMEVENT':'removeBetweenField','betweenSourceName':vName}); 	
  }
  return false;
};

////// UIX LOV BEAN RELATED METHODS
function getValue(formName, Table, rowNum, fieldName)
{
  if (Table != null)
  var proxy =  new TableProxy(Table);

  var value = '';
  if (rowNum == null)
  {
    a9 = navigator.userAgent.toLowerCase();
    if(a9.indexOf("msie")!=-1)  
    { 
     Element = document.getElementsByName(formName)[0][fieldName];
      }
    else
     {      
     Element = document.forms[formName][fieldName];
     }
     if (Element == null || Element == 'undefined')
       value = '';
     else if (Element.type == 'select-one')
       value = Element[Element.selectedIndex].value;
     else
       value = Element.value;   

    /// This should be done for criteria coming from CheckBox
    /// Fix for Bug 2624461 - hgandhi
    if (value == 'on')
    {
     /// Get both the true and false values     
     var check =  "CRITERIA"+"_"+fieldName;
     // fix for bug 3146000
     var checkform = document.forms[formName][check];
     if (checkform != null)
     {
      var checkBoxValue = checkform.value;      
      var trueFalseSeperator = checkBoxValue.indexOf(":");         
      if (Element.checked)
       value = checkBoxValue.substring(0, trueFalseSeperator);
      else
       value = checkBoxValue.substring(trueFalseSeperator+1);
      }
      else
      {
        if (!Element.checked)
          value = "off";
       }
    }       
   }
  else
  {
    var Element = proxy.getFormElement(fieldName, rowNum);   

    /// if criteria is outside the tables - check 
    if (Element == null)
    {
     a9 = navigator.userAgent.toLowerCase();
     if(a9.indexOf("msie")!=-1)  
     { 
      Element = document.getElementsByName(formName)[0][fieldName];
     }
     else
     { 
      Element = document.forms[formName][fieldName];
     }
     if (Element == null || Element == 'undefined')
       value = '';
     else if (Element.type == 'select-one')
       value = Element[Element.selectedIndex].value;
     else
       value = Element.value;  
       
     /// This should be done for criteria coming from CheckBox, 
     /// For Lovs Inside Table
     /// Fix for Bug 2624461 - hgandhi
     if (value == 'on')
     {
      var check =  "CRITERIA"+"_"+fieldName;
      var checkBoxValue = document.forms[formName][check].value; 
      var trueFalseSeperator = checkBoxValue.indexOf(":");         
      if (Element.checked)
       value = checkBoxValue.substring(0, trueFalseSeperator);
      else
       value = checkBoxValue.substring(trueFalseSeperator+1);       
      }
     } 
    else 
     {
      if (Element.type == 'select-one')
        value = Element[Element.selectedIndex].value;
      else
        value = Element.value;          
      //value = Elementvalue.value;
     }
  }

  // Need to check if the criteria is from Radiogroup  
  // Request for Enhancement - 3222368
  if (value == null)
  {
     var arrayLength = Element.length; 
     var arrayIndex = 0;
     if (arrayLength > 0)
     {  
       while (arrayIndex < arrayLength)
       {
        if (Element[arrayIndex].checked == true)
        {
          value = Element[arrayIndex].value;                    
         }
        arrayIndex++;
        }
      }   
    }    
   if (value == undefined)
   {
    value = ' ';
   }
   
   // Replace + with LOV_PLUS token, other wise we will loose + as the 
  // Browsers will replace + with ' '
  // for validations as well as when the user selects using the LOV window
  // Fix for bug 2515865
  value = checkForPlus(value);  
  return value ;
}

/// recursively check for the + and replace
function checkForPlus(value)
{
 if (value != null && (value.indexOf('+') >=0))
 {
   value = value.replace("+","LOV_PLUS"); 
   return checkForPlus(value);
  } 
 else 
  return value;  
}

function OnLovChoiceInit(params)
{
  params["searchText"] = ""; // Suppress searchText for LOV Choice.
  params["isLovChoice"] = "Y"; // Indicate that this is for LOV Choice.
  return OnLovInit(params);
}

function OnLovInit(params)
{
  ///// process Main criteria  
  var main = params["lovMainCriteria"];
  var rowNum = params["RowNum"];
  var lovTableName = params["lovTableName"]; 
  var formName = params["formName"];

  // Replace + with LOV_PLUS token, other wise we will loose + as the 
  // Browsers will replace + with ' '
  // for validations as well as when the user selects using the LOV window
  // Fix for bug 2515865
  var mainValue = params["searchText"];
  if (mainValue != null && mainValue != "" && mainValue.indexOf('+')>=0)
  {
   mainValue = checkForPlus(mainValue);
   params["searchText"] = mainValue; 
  }
  

  //// Process Normal criteria
  var criteria = params["Criteria"];
  if (criteria != null)
  {
    if ( criteria.indexOf('::') > 0)
    {
      var criteriaArray = criteria.split('::');
      for (var i = 0; i < criteriaArray.length; i++)
      { 
        var lovItemArray = criteriaArray[i].split(':');      
        var value = getValue(formName, lovTableName, rowNum, lovItemArray[0]); 
        //removed encoding for Bug 2533727
        params["CRITERIA"+i] = lovItemArray[1] +"::"+value; 
      }
    }
    //check for presence of : in order to take care of one criteria.
    else if ( criteria.indexOf(':') > 0)
    {
      var  lovItemArray = criteria.split(':');  
      var value = getValue(formName, lovTableName, rowNum, lovItemArray[0]);
      //removed encoding for Bug 2533727
      params["CRITERIA0"] = lovItemArray[1]+"::"+value;
    }    
   }

  /////////// Process Passive Criteria
  var Passivecriteria = params["PassiveCriteria"];
  if (Passivecriteria != null)
  {
    if ( Passivecriteria.indexOf('::') > 0)
    {
      var PassivecriteriaArray = Passivecriteria.split('::');
      for (var i = 0; i < PassivecriteriaArray.length; i++)
      { 
        var lovItemArray = PassivecriteriaArray[i].split(':');      
        var value = getValue(formName, lovTableName, rowNum, lovItemArray[0]); 
        //removed encoding for Bug 2533727
        params["PASSIVE_CRITERIA"+i] = lovItemArray[1] +"::"+value; 
      }
    }
    //check for presence of : in order to take care of one criteria.
    else if ( Passivecriteria.indexOf(':') > 0)
    {
      var  lovItemArray = Passivecriteria.split(':');  
      var value = getValue(formName, lovTableName, rowNum, lovItemArray[0]);
      //removed encoding for Bug 2533727
      params["PASSIVE_CRITERIA0"] = lovItemArray[1]+"::"+value;
    }    
   }  

  // If this is for LOV Input, and not for LOV Choice, execute lovOnClickJS.
  if (params["isLovChoice"] != "Y")
  {
    // Get the untransformed name in case LOV is within a table.
    var sourceParam = params["source"];
    var untransformedName = sourceParam;
    if (window["getTableElementName"])
    {
      untransformedName = getTableElementName(document.forms[formName][sourceParam]);
      if (untransformedName == null)
      {
        untransformedName = sourceParam;
      }
    }
    lovOnClickJSHiddenFieldName = "lovOnClickJSHiddenField" + untransformedName;
    lovOnClickJSHiddenFieldValue = document.forms[formName][lovOnClickJSHiddenFieldName].value;
    lovOnClickJSExecutedHiddenFieldName = "lovOnClickJSExecutedHiddenField" + untransformedName;
    lovOnClickJSExecutedHiddenFieldValue = document.forms[formName][lovOnClickJSExecutedHiddenFieldName].value;

    // If lovOnClickJS has not been executed, execute the JavaScript.
    if (lovOnClickJSExecutedHiddenFieldValue == "N")
    {
      eval(lovOnClickJSHiddenFieldValue);
    }
    // Reset the flag.
    document.forms[formName][lovOnClickJSExecutedHiddenFieldName].value = "N";
  }
  
  // If this is for LOV Input, and not for LOV Choice...
  if (params["isLovChoice"] != "Y")
  {
    // execute the autoclear for LOV input
    // note that this needs to be done after getting the criteria
    // and passive criteria.
    lovAutoClear (params, rowNum, formName);
  }

  return true;
}

// UIX LOV Javascript callback for validation
function OnLovValidate(params)
{
  // note that "lovCriteriaHiddenField" is same as
  // OAMessageLovInputHelper.LOV_CRITERIA_HIDDEN_FIELD
  // There is a problem with LOV within tables - untested.
  var tId = params["source"];
  var uLId = params["source"];
  var rNum = null;
  var tName = null;
  var formName = document.getElementById(params['source']).form.name;
     
  // if LOV within table, get the untransformed name, 
  // and the LOV table name and row num
  if (window["getTableElementName"])
  {
    var origId = getTableElementName(document.forms[formName][uLId]);
    if (origId != 'undefined'  && origId != null)
    {
      uLId = origId;
      var tHF = "lovTableHiddenField" + uLId;
      tName = getValue (formName, null, null, tHF);
      rNum = getRowNum (tName, tId, uLId);
      // store the untransformedId and rowNum on the params object.
      params[tId+"untransformedId"] = uLId;
      params[tId+"rowNum"] = '' + rNum;
    }
  }

  // now get the hidden field and the criteria item Names
  var fName = "lovCriteriaHiddenField" + uLId; 
  var c = getValue (formName, null, null, fName);
  // The criteria paramNames will have the following naming convention:
  // OAMessageLovInputHelper.LOV_CRITERIA_DELIMITER + messageLovInputBeanId +   
  // <baseItemNameOfCriteria>
  // We follow this convention because we donot want to blow away any parameters
  // on the URL that have the criteriaItem names.
  // this list includes all criteria including lovInput. 
  if (c != null)
  {
    var cDelimiter = "LOV_C:" + uLId;
    if ( c.indexOf('::') > 0)
    {
      var cArray = c.split('::');
      for (var i = 0; i < cArray.length; i++)
      { 
        var value = getValue(formName, tName, rNum, cArray[i]); 
        var qName = cDelimiter + cArray[i]; //qName: Qualified name
        // Double escape is avoided as part of the fix for bug 2905804.
        // Now UIX takes care of the encoding (bug 2840795) so we don't need to.
        params[qName] = value;
      }
    }
    else
    {
      // just one parameter
      var value = getValue(formName, tName, rNum, c); 
      var qName = cDelimiter + c; //qName: Qualified name
      // Double escape is avoided as part of the fix for bug 2905804.
      // Now UIX takes care of the encoding (bug 2840795) so we don't need to.
      params[qName] = value;
    }
  }

  // now get the hidden field and the criteria item Names
  var passiveCriteriaHFName = "lovPassiveCriteriaHF" + uLId; 
  var passiveCriteria = getValue(formName, null, null, passiveCriteriaHFName);
  // The passive criteria paramNames will have the following naming convention:
  // OAMessageLovInputHelper.LOV_PASSIVE_CRITERIA_DELIMITER + 
  // messageLovInputBeanId + <baseItemNameOfCriteria>
  // We follow this convention because we donot want to blow away any parameters
  // on the URL that have the same criteriaItem names.
  // This list includes all passive criteria. 
  if (passiveCriteria != null)
  {
    var pcDelimiter = "LOV_PC:" + uLId;
    if (passiveCriteria.indexOf('::') > 0)
    {
      var pcArray = passiveCriteria.split('::');
      for (var i = 0; i < pcArray.length; i++)
      { 
        var value = getValue(formName, tName, rNum, pcArray[i]); 
        var qName = pcDelimiter + pcArray[i]; //qName: Qualified name
        // Double escape is avoided as part of the fix for bug 2905804.
        // Now UIX takes care of the encoding (bug 2840795) so we don't need to.
        params[qName] = value;
      }
    }
    else
    {
      // just one parameter
      var value = getValue(formName, tName, rNum, passiveCriteria); 
      var qName = pcDelimiter + passiveCriteria; //qName: Qualified name
      // Double escape is avoided as part of the fix for bug 2905804.
      // Now UIX takes care of the encoding (bug 2840795) so we don't need to.
      params[qName] = value;
    }
  }
  
  // Execute lovOnClick JavaScript.
  lovOnClickJSHiddenFieldName = "lovOnClickJSHiddenField" + uLId;
  lovOnClickJSHiddenFieldValue = document.forms[formName][lovOnClickJSHiddenFieldName].value;
  eval(lovOnClickJSHiddenFieldValue);
  // Set executed flag to Y.
  lovOnClickJSExecutedHiddenFieldName = "lovOnClickJSExecutedHiddenField" + uLId;
  document.forms[formName][lovOnClickJSExecutedHiddenFieldName].value = "Y";

  // Replace + with LOV_PLUS token, other wise we will loose + as the 
  // Browsers will replace + with ' '
  // for validations as well as when the user selects using the LOV window
  // Fix for bug 2515865
  var mainValue = params["searchText"];
  if (mainValue.indexOf('+')>0)
  {
   mainValue = mainValue.replace("+","LOV_PLUS");
   params["searchText"] = mainValue;   
  }

  if (document.forms[formName].evtSrcRowIdx != null)
  {
    params["evtSrcRowIdx"] = document.forms[formName].evtSrcRowIdx.value;
    params["evtSrcRowId"] = document.forms[formName].evtSrcRowId.value;
  }
  // we need to return true as per uix documentation
  return true;
}

function OnLovSelect(lovWin, field, event)
{
  // If table proxy is present, get the untransformedName and rowNum.
  var untransformedName = null;
  var rowNum = null;
  if (window["getTableElementName"])
  {
    untransformedName = getTableElementName(field);
    rowNum = getTableRow(field);
  }

  var lovAutoClearJSName = null;
  var lovAutoClearJS = null;
  if (untransformedName != null && rowNum != null) 
  {
    // If the field is within a table...
    lovAutoClearJSName = 'LOC' + untransformedName;
    lovAutoClearJS = lovAutoClearJSName + '(' + rowNum + ');';
  }
  else // If the field is not within a table...
  {
    lovAutoClearJSName = 'LOC' + field.name;
    lovAutoClearJS = lovAutoClearJSName + '();';
  }

  if (window[lovAutoClearJSName] != null)
  {
    eval(lovAutoClearJS);
  }

  return true;

  /*
  // Get the untransformed name in case LOV is within a table.
  var untransformedName = getTableElementName(field);
  if (untransformedName == null)
  {
    untransformedName = field.name;
  }

  // Execute the LOV JavaScript.
  JSHiddenFieldName = "lovJSHiddenField" + untransformedName;
  JSHiddenFieldValue = document.forms[0][JSHiddenFieldName].value;
  eval(JSHiddenFieldValue);

  return true;
   */
}

// Utility method to find the row num given the transformed
// and untransformed id.
function getRowNum (tName, tId, uId)
{
  var rNum = null;
  var p = new TableProxy(tName); 
  var rCount = p.getLength(); 
  for(var i=0; i<rCount; i++)
  {
    var field = p.getFormElement(uId , i);
    if (field != null)
    {
      if (field.id == tId)
      {
        rNum = i;   
        break;
      }
    }
  }
  return rNum;
}

function _LovSelectReturn(a0, a1)
{
  var proxy = new TableProxy(a0);
  var row = proxy.getSelectedRow();
  var selectUrl = null;

  if ( row >= 0 ) {
    var tempVal = proxy.getFormElement(a1,row).value;
	var tempResult = _escapeCarriageReturn(tempVal);
    selectUrl = new Function(tempResult);
	selectUrl.apply(this);
  } 
}

// uLId : messageLovInputId
// rNum: rowNum
// oCS: on change string
// function to apply autoclear for LOV.
function lovAutoClear(params, rNum, fN)
{
  var uLId = params["source"];
  
  // if LOV within table, get the untransformed id, 
  // and the LOV table name and row num
  if (window["getTableElementName"])
  {
     var origId = getTableElementName(document.forms[fN][uLId]);
    if (origId != 'undefined'  && origId != null)
    {
      uLId = origId;
    }
  }

  // find if autoclear should be executed
  // get the hidden bean value for autoclear
  // if it is N, then donot execute.
  var e = true;
  var hFN = "lovAutoClearHF" + uLId;
  var v = getValue (fN, null, null, hFN);
  if (v != null && v != 'undefined')
  {
    if (v == 'N')
	e = false; 
  }
  if (e)
  {  
   var oCS = "LOC" + uLId + "(";
   if (rNum != null && rNum == 'undefined')
   {
     oCS = oCS + rNum;
   }
   oCS = oCS + "); ";
   eval (oCS);
  }
}

function _escapeCarriageReturn(a0)
{
  var tempChar;
  for ( i=0; i < a0.length; i++ )
  {
   	if ( a0.charAt(i) == '\n' || a0.charAt(i) == '\r' )
	{
      tempChar = tempChar + escape(a0.charAt(i));
	}
	else
	{
	  if ( i > 0 )
        tempChar = tempChar + a0.charAt(i);
	  else
	    tempChar = a0.charAt(i);
	}
  }
  return tempChar;
}

//Used to return [123] (123) <123> 123- as -123 and 123+ as 123for currency validater
function currval(a0)
{
  s1 = a0.charAt(0);
  s2 = a0.charAt(a0.length-1);
  if((s1=="<" && s2==">")||(s1=="(" && s2==")")||(s1=="[" && s2=="]"))
    return "-"+a0.substring(1,a0.length-1);
  else if(s2=="-")
    return "-"+a0.substring(0,a0.length-1);
  else if(s2=="+")
    return a0.substring(0,a0.length-1);
  else
    return a0;
}

// ----- BEGIN: APIs for Rich Text Editor (Owner: Anil Ranka) -----
    function RichTextEditorProxy(formName,beanId, mode, maxLength, flag) 
    {
        this.formName = formName;
        this.beanId = beanId + "_IFRAME";
        this.dataBeanId = beanId;
        this.mode = mode;
        this.maxLength  = maxLength;
        this.isIEBrowser = flag;
    }

    RichTextEditorProxy.prototype.onMouseOver = _onMouseOver;
    RichTextEditorProxy.prototype.onMouseOut = _onMouseOut;
    RichTextEditorProxy.prototype.onMouseDown = _onMouseDown;
    RichTextEditorProxy.prototype.onMouseUp = _onMouseUp;
    RichTextEditorProxy.prototype.createHyperlink = _createHyperlink;
    RichTextEditorProxy.prototype.execHTMLCommand = _execHTMLCommand;
    RichTextEditorProxy.prototype.getField = _getField;
    RichTextEditorProxy.prototype.setFontBarDropdown = _setFontBarDropdown;
    RichTextEditorProxy.prototype.insertHTMLTag = _insertHTMLTag;
    RichTextEditorProxy.prototype.setContentOnBlur = _setContentOnBlur;
    RichTextEditorProxy.prototype.insertText = _insertText;
    RichTextEditorProxy.prototype.insertImageTag = _insertImageTag;
    RichTextEditorProxy.prototype.setValue = _setValue;
    RichTextEditorProxy.prototype.setHref = _setHref;
    RichTextEditorProxy.prototype.viewHtmlSource = _viewHtmlSource;
    RichTextEditorProxy.prototype.disableFontDropDowns = _disableFontDropDowns;
    RichTextEditorProxy.prototype.checkRTEDataLength = _checkRTEDataLength ;


    function _onMouseOver() 
    {
        var toEl = getReal(window.event.toElement, "className", "buttonBar");
        var fromEl = getReal(window.event.fromElement, "className", "buttonBar");
        if (toEl == fromEl) return;
        var el = toEl;

        var cDisabled = el.getAttribute("cDisabled");
        cDisabled = (cDisabled != null); 

        if (el.className == "buttonBar")
        el.onselectstart = new Function("return false");

        if ((el.className == "buttonBar") && !cDisabled) 
        {
            makeRaised(el);
        }
    }

    function _onMouseOut() 
    {
        var toEl = getReal(window.event.toElement, "className", "buttonBar");
        var fromEl = getReal(window.event.fromElement, "className", "buttonBar");
        if (toEl == fromEl) return;
        var el = fromEl;
        var PressedEx = el.getAttribute("PressedEx");
        var cDisabled = el.getAttribute("cDisabled");
        cDisabled = (cDisabled != null); 

        var cToggle = el.getAttribute("cToggle");
        toggle_disabled = (cToggle != null); 

        if (cToggle && el.value || PressedEx == true) 
        {
            makePressed(el);
        }
        else if ((el.className == "buttonBar") && !cDisabled) 
        {
            makeFlat(el);
        }
    }

    function _onMouseDown() 
    {
        el = getReal(window.event.srcElement, "className", "buttonBar");
        var cDisabled = el.getAttribute("cDisabled");                       
        cDisabled = (cDisabled != null); 
        if ((el.className == "buttonBar") && !cDisabled) 
        {
            makePressed(el)
        }
    }

    function _onMouseUp() 
    {
        el = getReal(window.event.srcElement, "className", "buttonBar");
        var cDisabled = el.getAttribute("cDisabled");                       
        cDisabled = (cDisabled != null); 
        if ((el.className == "buttonBar") && !cDisabled) 
        {
            makeRaised(el);
        }
    }

    function getReal(el, type, value) 
    {
        temp = el;
        while ((temp != null) && (temp.tagName != "BODY")) 
        {
            if (eval("temp." + type) == value) 
            {
                el = temp;
                return el;
            }
                temp = temp.parentElement;
        }
        return el;
    }

    function makeFlat(el) 
    {
        with (el.style) 
        {
            background = "";
            border = "0px solid";
            padding      = "2px";
        }
    }

    function makeRaised(el) 
    {
        with (el.style) 
        {
            borderLeft   = "1px solid #ffffff";
            borderRight  = "1px solid #555533";
            borderTop    = "1px solid #ffffff";
            borderBottom = "1px solid #555533";
            padding      = "1px";
        }
    }

    function makePressed(el) 
    {
        with (el.style) 
        {
            borderLeft   = "1px solid #555533";
            borderRight  = "1px solid #ffffff";
            borderTop    = "1px solid #555533";
            borderBottom = "1px solid #ffffff";
            paddingTop    = "2px";
            paddingLeft   = "2px";
            paddingBottom = "0px";
            paddingRight  = "0px";
        }
    }

    function _createHyperlink(promptStr)
    {
        if (this.mode == "TEXT_MODE")
            return;
        frames[this.beanId].focus();

        var  selection =  frames[this.beanId].document.selection.type;
        var parent;
        if ( selection == "Control")
        {
            parent = frames[this.beanId].document.selection.createRange().item(0);
        }
        else
        {
           parent = frames[this.beanId].document.selection.createRange().parentElement();
        }

        var anchor = getNode("A", parent);
        var link = prompt(promptStr, anchor ? anchor.href : "http://");
        if (link && link != "http://") 
        {
            if (frames[this.beanId].document.selection.type == "None") 
            {
                var range = frames[this.beanId].document.selection.createRange();
                range.pasteHTML('<A HREF="' + link + '"></A>');
                range.select();
            }
            else 
            {
                this.execHTMLCommand("CreateLink",link);
            }
        }
    }


    function getNode(tagName, start)
    {
        while (start && start.tagName != tagName) 
        {
            start = start.parentElement;
        }
        return start;
    }


    function _execHTMLCommand(HTMLCommand) 
    {
        if (this.mode == "TEXT_MODE")
            return;
        frames[this.beanId].focus();
        frames[this.beanId].document.execCommand(HTMLCommand,false, arguments[1]);
        frames[this.beanId].focus();
    }

    function _setFontBarDropdown(dropDownName, dropDownType) 
    {
        var obj = this.getField(dropDownName);
        this.execHTMLCommand(dropDownType,obj.options[obj.selectedIndex].value);
    }


    function _insertHTMLTag(tagString)
    {
        if (this.mode == "TEXT_MODE")
            return;
        frames[this.beanId].focus();
        var range = frames[this.beanId].document.selection.createRange();
        range.collapse(false);
        range.pasteHTML(tagString);
        range.select();
        frames[this.beanId].focus();
    }

    function _insertText(value)
    {
        if(this.isIEBrowser)
        {
            if (this.mode == "TEXT_MODE")
                return;
             frames[this.beanId].focus();
            var range = frames[this.beanId].document.selection.createRange();
            range.collapse(false);
            range.pasteHTML(value);
            range.select();
            frames[this.beanId].focus();
        }
        else
        {
            var node = this.getField(this.dataBeanId);
            node.value = node.value + " " + value;  
        }
    }



    function
    _getField( p_strObjName)
    {
//        var obj = eval("document.forms[0].elements['"+p_strObjName+"']");
        var obj = eval("document.forms[this.formName].elements['"+p_strObjName+"']");
        return obj;
    }

    function _setContentOnBlur()
    {
//        var l_objElements = document.forms[0].elements;
//        alert('sam');
        this.checkRTEDataLength ();

        var l_objElements = document.forms[this.formName].elements;
        for (i = 0 ; i< l_objElements.length ; i++)
        {
            var elemName = l_objElements[i].name;
            if ( elemName.indexOf(this.dataBeanId) != -1)
            {
                var contentField = l_objElements[i];
                if (frames[this.beanId] != undefined )
                {
                    if ( this.mode == "TEXT_MODE" )
                        contentField.value = frames[this.beanId].document.body.innerText;
                     else
                        contentField.value = frames[this.beanId].document.body.innerHTML;
                }
            }
        }
        return;
    }

    function _insertImageTag(imageSrc)
    {
        if (this.mode == "TEXT_MODE")
            return;
        frames[this.beanId].focus();
        if (frames[this.beanId].document.selection.type != "None") 
        {
            var parent = frames[this.beanId].document.selection.createRange().parentElement();
        }
        var parent = frames[this.beanId].document.selection.createRange().parentElement();
        var image = getNode("IMG", parent);
        if (imageSrc && imageSrc != "http://") 
        {
            if (frames[this.beanId].document.selection.type == "None") 
            {
                var range = frames[this.beanId].document.selection.createRange();
                range.pasteHTML('<IMG SRC="' + imageSrc + '">');
                range.select();
            }
            else 
            {
                this.execHTMLCommand("insertImage", imageSrc);
            }
        }
    }

    function _setValue(data)
    {
        if(this.isIEBrowser)
        {
             frames[this.beanId].focus();
            if (this.mode == "TEXT_MODE")
                frames[this.beanId].document.body.innerText  = data;
            else
                frames[this.beanId].document.body.innerHTML= data;
            frames[this.beanId].focus();
        }
        else
        {
            var node = this.getField(this.dataBeanId);
            node.value = data;  
        }
    }

    function _setHref(url)
    {   
        if (this.mode == "TEXT_MODE")
            return;
        frames[this.beanId].focus();
        if (frames[this.beanId].document.selection.type == "None") 
        {
            var range = frames[this.beanId].document.selection.createRange();
            range.pasteHTML('<A HREF="' + url + '"></A>');
            range.select();
        }
        else 
        {
            this.execHTMLCommand("CreateLink",url);
        }
    }

    function _viewHtmlSource(mode)
    {
    //alert('calling viewsource');
        if (mode) 
        {
             this.disableFontDropDowns(true);
            this.mode = "TEXT_MODE";
            frames[this.beanId].document.body.innerText = frames[this.beanId].document.body.innerHTML;
        }
        else 
        {
            this.disableFontDropDowns(false);
            this.mode = "RICH_TEXT_MODE";
            frames[this.beanId].document.body.innerHTML = frames[this.beanId].document.body.innerText;
        }
        frames[this.beanId].focus();
    }


    function _disableFontDropDowns(flag)
    {
        var fontDD = this.getField(this.dataBeanId + 'fontFamily');
        if ( fontDD != null ) fontDD.disabled=  flag;

        var fontColorDD = this.getField(this.dataBeanId + 'fontColor');
        if ( fontColorDD != null ) fontColorDD.disabled=  flag;

        var fontWeightDD = this.getField(this.dataBeanId + 'fontWeight');
        if ( fontWeightDD != null ) fontWeightDD.disabled=  flag;

    }


function _checkRTEDataLength ()
{
    if ( this.maxLength == -1 )  //DataType is CLOB
        return true;
        
    if (this.mode == "TEXT_MODE") 
        data = frames[this.beanId].document.body.innerText;
    else 
        data = frames[this.beanId].document.body.innerHTML;

    dataLength = data.length;
    if (dataLength > this.maxLength)
    {
        if (this.mode == "TEXT_MODE") 
            frames[this.beanId].document.body.innerText = data.substr(0, this.maxLength);
        else 
            frames[this.beanId].document.body.innerHTML = data.substr(0, this.maxLength);
        return false;
    }

    if (dataLength < this.maxLength)
        return true;

    if (dataLength == this.maxLength)
        return true;

    return false;
}

// ----- END: APIs for Rich Text Editor (Owner: Anil Ranka) -----
