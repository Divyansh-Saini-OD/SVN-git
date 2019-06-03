<%--=========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |       30-Nov-01  ipo      Created.                                   |
 +=========================================================================--%>

<%! public static final String RCS_ID = "$Header: frameRedirect.jsp 115.4 2002/08/16 11:28:58 appldev noship $"; %>


<html>
<head>
<script>
// Object containing information about the user agent
var _agent = new Object();


/**
 * Returnt rue if the agent is atLeast the specified agent type and version.
 */
function _atLeast(
  kind,
  version
  )
{  
  return (!kind    || (kind    == _agent.kind))    &&
         (!version || (version <= _agent.version));
}

/**
 * initialize information about the agent
 */
function _agentInit()
{
  // convert all characters to lowercase to simplify testing 
  var agentString = navigator.userAgent.toLowerCase();
    
  var version = parseFloat(navigator.appVersion);

  var isOpera = false;
  var isIE    = false;
  var isNav   = false;
  var kind    = "unknown";
  
  if (agentString.indexOf("msie") != -1)
  {
    isIE = true;
    
    // extract ie's version from the ie string
    var matches = agentString.match(/msie (.*);/);
    version = parseFloat(matches[1]);
    kind = "ie";
  }
  else if (agentString.indexOf("opera") != -1)
  {
    isOpera = true
    kind = "opera";
  }
  else if ((agentString.indexOf('mozilla')    != -1) &&
           (agentString.indexOf('spoofer')    == -1) &&
           (agentString.indexOf('compatible') == -1))
  {
    isNav = true;
    kind = "nn";
  }
  
  _agent.isIE = isIE;
  _agent.isNav = isNav;
  _agent.isOpera = isOpera;
  _agent.version = version
  _agent.kind = kind;
  
  _agent.atLeast = _atLeast;
}


_agentInit();

/**
 * Returns the object containing the dependent windows.
 */
function _getDependents(
  parentWindow,
  createIfNecessary
  )
{
  var depends;
  
  if (parentWindow)
  {
    depends = parentWindow["_dependents"];
    
    if (depends == (void 0))
    {
      if (createIfNecessary)
      {
        depends = new Object();
        parentWindow["_dependents"] = depends;
      }
    }
  }
  
  return depends;
}

/**
 * Get the named dependent
 */
function _getDependent(
  parentWindow,
  dependentName
  )
{
  var depends = _getDependents(parentWindow);
  var dependent;
  
  if (depends)
  {
    dependent = depends[dependentName];
  }
  
  return dependent;
}


/**
 * Sets the value of the named dependent
 */
function _setDependent(
  parentWindow,
  dependentName,
  dependentValue
  )
{
  var depends = _getDependents(parentWindow, true);
  
  if (depends)
  {
    depends[dependentName] = dependentValue;
  }
}


/**
 * Returns the dependent which is modal.
 */
function _getModalDependent(
  parentWindow
  )
{
  return _getDependent(parentWindow, "modalWindow");
}

/**
 * Returns the dependent which is modal and is still open.
 */
function _getValidModalDependent(
  parentWindow
  )
{
  var modalDependent = _getModalDependent(parentWindow);
  
  if (modalDependent)
  {
    if (modalDependent.closed)
    {
      _setDependent(parentWindow, "modalWindow", (void 0));
      modalDependent = (void 0);
    }
  }
  
  return modalDependent;
}


/**
 * Returns true if the passed in dependent is the modal dependent
 * of the parent window,
 */
function _isModalDependent(
  parentWindow,
  dependent
  )
{
  return (dependent == _getModalDependent(parentWindow));
}


/**
 * Called by the unloda handler of modal windows to call the event
 * handler and make sure that the parent window is updated appropriately
 * to show that no modal window is up anymore.
 */
function _checkUnload(
  event
  )
{  
  var parentWindow = top.opener;
    
  var unloader = _getDependent(parentWindow, self.name);
 
  if (_isModalDependent(parentWindow, self))
  {
    // remove the modal window
    _setDependent(parentWindow, "modalWindow", (void 0));

    parentWindow.onfocus = null;
    
    // release the ie mouse grab
    if (_agent.atLeast("ie", 4))
    {
      parentWindow.document.body.releaseCapture();
      parentWindow.document.body.style.filter = null;
    }
    
    // release the netscape mouse grab
    if (_agent.atLeast("nn"))
    {
      parentWindow.releaseEvents(Event.CLICK);
      
      // stop eating all of the mouse clicks
      parentWindow.onclick = null;
    }
  }
  
  if (unloader != (void 0))
  {        
    // remove our dependent info
    _setDependent(parentWindow, self.name, (void 0));
    
    // try the passed in event (netscape way first), then
    // try to get the event the IE way
    if (event == (void 0))
      event = self.event;
    
    // call the unloader with the unloading window and the event 
    unloader(top, event);
  }
}
</script>
</head>
<frameset rows="100%,*" border="0" onload="top.document.title = top.frames[0].document.title" onunload="_checkUnload(event)">
<%
  String redirectString = request.getParameter("redirect");
  
  if (redirectString != null)
  {
    out.println("<frame src=\"" + redirectString + "?" + request.getQueryString() + "\">");
  }
%>
</frameset>
</html>
