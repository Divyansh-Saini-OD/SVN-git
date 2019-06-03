<!-- $Header: OAFrame.jsp 115.11 2005/03/30 04:52:18 atgops1 noship $ -->
<!-- Author : Kandasamy P Athimoolam -->
<!-- Created : 09/24/2003 -->
<%@ page
  language    = "java"
  errorPage   = "OAErrorPage.jsp"
  contentType = "text/html"
  import      = "java.io.File,
                java.util.StringTokenizer,
                oracle.cabo.ui.ServletRenderingContext,
                oracle.cabo.ui.beans.layout.FrameBorderLayoutBean,
                oracle.cabo.ui.beans.layout.FrameBean,
                oracle.apps.fnd.framework.webui.OAWebBeanConstants,
                oracle.apps.fnd.framework.server.OAUtility,
                oracle.apps.fnd.common.WebAppsContext,
                oracle.apps.fnd.framework.OAException,
                oracle.apps.fnd.security.HMAC,
                oracle.apps.fnd.framework.webui.URLMgr,
                oracle.apps.fnd.framework.webui.OAJSPHelper,
                oracle.apps.fnd.framework.webui.OAMACUtils,
                oracle.apps.fnd.common.WebRequestUtil,
                oracle.apps.fnd.framework.OACommonUtils;
"
%>

<html>
<head>
<%
  final String APPLICATION_JSP = "OA.jsp";
  final String FRAMEFUNCTIONS_DELIMETER = ":";
  final String ICX_SESSION_VALID = "VALID";

  // String dbcFile = System.getProperty("JTFDBCFILE");
  // WebAppsContext wac = new WebAppsContext(dbcFile);
  //Fix for bug 3589148: Do not pass the dbc parameter
  // String dbcName = request.getParameter("dbc");
  String transactionid = request.getParameter("transactionid");
  String sessionid = request.getParameter("sessionid");
  String frameSources = request.getParameter("OAFunc");
  String frameDimensions = request.getParameter(OAWebBeanConstants.FRAME_DIMENSIONS);

  StringBuffer baseUrl = new StringBuffer(50);
  baseUrl.append(request.getScheme()).append("://").append(
    request.getHeader("Host")).append("/OA_HTML/");

  StringBuffer parameters = new StringBuffer(100);
  // parameters.append("&dbc=").append(dbcName);
  parameters.append("&transactionid=").append(transactionid);
  parameters.append("&sessionid=").append(sessionid);
    
  ServletRenderingContext rContext = new ServletRenderingContext(pageContext);

%>

</head>

<%
  String[] frameFuncs = new String[3];
  StringTokenizer funcTokens =
    new StringTokenizer(frameSources, FRAMEFUNCTIONS_DELIMETER);

  int funcCount = funcTokens.countTokens();
  for(int i=0; i < funcCount;  i++ )
  {
    frameFuncs[i] = funcTokens.nextToken();
  }  

  // Determine the width of the start frame and height of the top frame.
  String[] frameDims = {"20%", "175"};
  if( frameDimensions != null && !"".equals(frameDimensions) )
  {
    StringTokenizer frameDimTokens =
      new StringTokenizer(frameDimensions, FRAMEFUNCTIONS_DELIMETER);

    int dimCount = frameDimTokens.countTokens();
    for(int i=0; i < dimCount;  i++ )
    {
      frameDims[i] = frameDimTokens.nextToken().toLowerCase();
      frameDims[i] = (frameDims[i].indexOf("p") != -1) ?
                      frameDims[i].replace('p', '%') :
                      frameDims[i];
    }
  }

  // Start MAC change
  WebAppsContext ctx = null;
  HMAC hmac = null;

  if (OAMACUtils.isMacEnabled(request) || OAMACUtils.isMacLiteEnabled(request))
  {
  
    ctx = OAUtility.getWebAppsContext(OAUtility.getDbcName());

    String sessionStatus =
      WebRequestUtil.validateContext(request, response, ctx);

    if ( ! ICX_SESSION_VALID.equals(sessionStatus) )
    {
      // Redirect to login page and do not proceed further.
      return;
    }
    else if (sessionStatus == null) // Unexpected error occurred.
    {
      // Get the error stack and throw exception if error stack is not empty.
      OAException oaException =
        OACommonUtils.processAOLJErrorStack(ctx.getErrorStack());
      if (oaException != null)
        throw oaException;
    }

    hmac = new HMAC(HMAC.HMAC_MD5);
    hmac.setKey(ctx.getMacKey());
    boolean check = URLMgr.processIncomingURL(request, hmac);

    if(check == false)
      throw new OAException("FND", "FND_INSUFF_PRIVILEGES");

    ctx.freeWebAppsContext();
  }
  // End MAC change

  FrameBorderLayoutBean frameBorderLayout = new FrameBorderLayoutBean();
  
  FrameBean topFrame = new FrameBean();
  topFrame.setName(OAWebBeanConstants.TOPFRAME_NAME);
  topFrame.setHeight(frameDims[1]);
  if( frameFuncs[0] != null )
  {
    // top frame should just have the header
    if (OAMACUtils.isMacEnabled(request) || OAMACUtils.isMacLiteEnabled(request))
    {
      topFrame.setSource(
        URLMgr.processOutgoingURL(
        (new StringBuffer(baseUrl.toString()).append(APPLICATION_JSP).append(
          "?OAFunc=").append(frameFuncs[0]).append(parameters.toString()).append(
          '&').append(OAWebBeanConstants.OA_PAGELAYOUT_RENDER_STYLE).append(
          "=").append(OAWebBeanConstants.PAGELAYOUT_HEADER_ONLY)).toString()
        , hmac) );
    }
    else
    {
      topFrame.setSource(
        (new StringBuffer(baseUrl.toString()).append(APPLICATION_JSP).append(
          "?OAFunc=").append(frameFuncs[0]).append(parameters.toString()).append(
          '&').append(OAWebBeanConstants.OA_PAGELAYOUT_RENDER_STYLE).append(
          "=").append(OAWebBeanConstants.PAGELAYOUT_HEADER_ONLY)).toString() );
    }
  }
  
  FrameBean startFrame = new FrameBean();
  startFrame.setName(OAWebBeanConstants.STARTFRAME_NAME);
  startFrame.setWidth(frameDims[0]);
  if( frameFuncs[1] != null )
  {
    if (OAMACUtils.isMacEnabled(request) || OAMACUtils.isMacLiteEnabled(request))
    {
      startFrame.setSource(
        URLMgr.processOutgoingURL(
        (new StringBuffer(baseUrl.toString()).append(APPLICATION_JSP).append(
          "?OAFunc=").append(frameFuncs[1]).append(parameters.toString())).toString()
        , hmac) );
    }
    else
    {
      startFrame.setSource(
        (new StringBuffer(baseUrl.toString()).append(APPLICATION_JSP).append(
          "?OAFunc=").append(frameFuncs[1]).append(parameters.toString())).toString() );
    }
  }
  
  FrameBean centerFrame = new FrameBean();
  centerFrame.setName(OAWebBeanConstants.CENTERFRAME_NAME);
  if( frameFuncs[2] != null )
  {
    // center/content frame should not contain the header
    if (OAMACUtils.isMacEnabled(request) || OAMACUtils.isMacLiteEnabled(request))
    {
      centerFrame.setSource(
        URLMgr.processOutgoingURL(
        (new StringBuffer(baseUrl.toString()).append(APPLICATION_JSP).append(
          "?OAFunc=").append(frameFuncs[2]).append(parameters.toString()).append(
          '&').append(OAWebBeanConstants.OA_PAGELAYOUT_RENDER_STYLE).append(
          "=").append(OAWebBeanConstants.PAGELAYOUT_NO_HEADER)).toString()
        , hmac) );
    }
    else
    {
      centerFrame.setSource(
        (new StringBuffer(baseUrl.toString()).append(APPLICATION_JSP).append(
          "?OAFunc=").append(frameFuncs[2]).append(parameters.toString()).append(
          '&').append(OAWebBeanConstants.OA_PAGELAYOUT_RENDER_STYLE).append(
          "=").append(OAWebBeanConstants.PAGELAYOUT_NO_HEADER)).toString() );
    }
  }
  
  frameBorderLayout.setCenter(centerFrame);
  frameBorderLayout.setStart(startFrame);

  frameBorderLayout.setTop(topFrame);  

  frameBorderLayout.render(rContext);
  
%>
</html>