<%-- =========================================================================+
 |      Copyright (c) 2000 Oracle Corporation, Redwood Shores, CA, USA        |
 |                         All rights reserved.                               |
 +============================================================================+
 | FILENAME                                                                   |
 |   AoljJdbcStatus.jsp                                                       |
 |                                                                            |
 | DESCRIPTION                                                                |
 |   AOL/J Database Connection Pool Status.                                   |
 |                                                                            |
 | NOTES                                                                      |
 |                                                                            |
 | DEPENDENCIES                                                               |
 |                                                                            |
 | Revision  New Dependencies Since R11i                                      |
 | --------  ---------------------------                                      |
 | 115.0     Pool.java 115.14                                                 |
 | 115.2     Pool.java 115.20                                                 |
 |           security/DBConnObj.java 115.23                                   |
 |           security/DBConnObjPool.java 115.12                               |
 |                                                                            |
 | HISTORY                                                                    |
 |                                                                            |
 | 11-FEB-2000  kjentoft  Created.                                            |
 | 20-FEB-2000  kjentoft  Changed so date is under page title.  This prevents |
 |                        the date from forcing scrolling on narrow windows.  |
 | 26-JUN-2002  RTSE      Added support for identifying rogue modules that    |
 |                        hog connections.                                    |
 +======================================================================== --%>
<%@ page import = "oracle.apps.fnd.common.FunctionManager" %>
<%@ page import = "oracle.apps.fnd.common.Pool" %>
<%@ page import = "oracle.apps.fnd.common.VersionInfo" %>
<%@ page import = "oracle.apps.fnd.common.WebRequestUtil" %>
<%@ page import = "oracle.apps.fnd.common.WebAppsContext" %>
<%@ page import = "oracle.apps.fnd.security.DBConnObj" %>
<%@ page import = "oracle.apps.fnd.security.DBConnObjPool" %>
<%@ page import = "oracle.apps.fnd.security.DbcoPoolEventCodes" %>
<%@ page import = "java.io.File" %>
<%@ page import = "java.text.DateFormat" %>
<%@ page import = "java.util.Date" %>
<%! public static final String RCS_ID = "$Header: AoljDbcPoolStatus.jsp 115.7 2002/06/27 17:59:37 rtse ship $"; %>
<%! public static final boolean RCS_ID_RECORDED =
    VersionInfo.recordClassVersion(RCS_ID, "oa_html.jsp.fnd"); %>
<%@page language="java" errorPage="AoljTestError.jsp"%>

<HTML>
<BODY bgcolor="#CCCCCC">
<!--Outer table containing toolbar and logo cells-->
<TABLE width=100% Cellpadding=0 Cellspacing=0 border=0>
  <TR>
  <TD height="30" nowrap align="left">
  <FONT style="Arial, Helvetica, Geneva, sans-serif" color="#336699" size="+2">
  <B><I>
  &nbsp;AOL/J Database Connection Pool Status
  </I></B></FONT>
  </TD>
  </TR><TR>
  <TD height="30" nowrap align="left">
  <FONT style="Arial, Helvetica, Geneva, sans-serif" color="#336699" size="+2">
  <B><I>
  <%=DateFormat.getDateTimeInstance(DateFormat.LONG, DateFormat.LONG).format(new Date(System.currentTimeMillis())).toString()%>&nbsp;
  </I></B></FONT>
  </TD>
  </TR>
</TABLE>

<FORM TYPE=POST ACTION=AoljDbcPoolStatus.jsp>
<% 
pageBody:
{
  WebAppsContext currentWAC = null;
  FunctionManager currentFM = null;
  boolean isValidFunction = false;
  String sessionid = request.getParameter("sessionid");
  String dbc = request.getParameter("dbc");
  String mode = request.getParameter("mode");
  String statsOnlyButton = 
    "<input type=submit name=mode value=\"Statistics Only\">";
  String defineButton = 
    "<input type=submit name=mode value=\"Definitions\" label=\"Definitions\">";
  String configTipsButton = 
    "<input type=submit name=mode value=\"Configuration Tips\">";
  boolean define = false;
  boolean configTips = false;
  boolean statsOnly = false;
  boolean abandonedConnections = false;
  boolean closedConnections = false;
  boolean lockedConnections = false;
  if (mode != null) {
    //define = mode.equalsIgnoreCase("definitions");
    define = mode.equalsIgnoreCase("Configuration Tips");
    configTips = mode.equalsIgnoreCase("Configuration Tips");
    abandonedConnections = mode.equalsIgnoreCase("Abandoned Connections");
    closedConnections = mode.equalsIgnoreCase("Closed Connections");
    lockedConnections = mode.equalsIgnoreCase("Locked Connections");
  }
  if (!define && !configTips) statsOnly = true;
/*
  try{
    currentWAC = WebRequestUtil.validateContext(request,response);
  }catch(IOException ioe){
    throw ioe;
  }
  if(currentWAC == null)  // Session is not valid
  {
    %><p><b>ERROR:</b> Session is not valid!<% 
    break pageBody;
  }
  currentFM = new FunctionManager(currentWAC);
  isValidFunction = currentFM.testFunc("FND_AOLJ_POOL_STATUS");
  if(!isValidFunction)  // Function is not valid
  {
    %><p><b>ERROR:</b> Current user/responsibility does not have permission 
      to run this function.<%  
    currentWAC.freeWebAppsContext();
    currentWAC = null;
    break pageBody;
  }
*/
  DBConnObjPool dbcoPool = DBConnObjPool.getInstance();
  int[] poolStats = dbcoPool.getStatistics();
  DbcoPoolEventCodes eventCode = (DbcoPoolEventCodes)dbcoPool.getEventCodes();
  DateFormat dateFormat = 
      DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.LONG);
  Enumeration enum = null;
  Vector infoVector = new Vector();

  if(abandonedConnections)
  {
    %>
      <b>Abandoned Connections</b><p>
    <%

    enum = DBConnObjPool.getInstance().getAbandonedConnections();
  }
  else if(closedConnections)
  {
    %>
      <b>Closed Connections</b><p>
    <%

    enum = DBConnObjPool.getInstance().getClosedConnections();
  }
  else if(lockedConnections)
  {
    %>
      <b>Locked Connections</b><p>
      <i>(Entries in <font color=red><b>red</b></font> indicate that the
        borrowing thread has died.)</i>
      </font><p>
    <%

    enum = DBConnObjPool.getInstance().getLockedConnections();
  }

  if(abandonedConnections || closedConnections || lockedConnections)
  {
    %>

      <table>
      <tr>
        <td colspan=2 align=left>
        </td>
      </tr>

    <%

    while(enum != null && enum.hasMoreElements())
    {
      DBConnObj obj = (DBConnObj) enum.nextElement();
      Thread borrowingThread = obj.getBorrowingThread();
      String fontColor = "black";

      if(lockedConnections && borrowingThread != null &&
        !borrowingThread.isAlive())
      {
        fontColor = "red";
      }

      %>
        <tr valign=top>
          <th align=left>
          <font color=<%=fontColor%>>
          <%=DateFormat.getDateTimeInstance(DateFormat.LONG,DateFormat.LONG).format(new Date(obj.getTimeStamp())).toString()%>
          </font>
          </th>
          <td align=left>
          <font color=<%=fontColor%>>
          <pre>
          <%="\n["+obj.getConnection()+"]\n\n"+obj.getStackTrace()%>
          </pre>
          </font>
          </td>
        </tr>
      <%
    }

    %>

      </table>

    <%
  }
  else
  {

  %>
  <table>
  <tr>
      <td colspan=4 align=left>
         <% if(!statsOnly) { %><%=statsOnlyButton%>&nbsp;<% } %>
         <!-- <% if(!define) { %><%=defineButton%>&nbsp;<% } %> -->
         <% if(!configTips) { %><%=configTipsButton%>&nbsp;<% } %>
      </td>
  </tr>
  <tr valign=top>
      <th colspan=4 align=left> Pool Created: 
         <%= dateFormat.format(new Date(dbcoPool.getCreationTime())) %>
      </th>
  </tr>
  <!--                          -->
  <!-- Configuration Parameters -->
  <!--                          -->
  <tr valign=top>
      <th colspan=4 align=left>Configuration Parameters</th>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>FND_JDBC_MAX_CONNECTIONS:</td>
      <td align=left><%=dbcoPool.getMaxNumberObjects()%></td>
      <td><% if (define) { %>
             Maximum number of connections allowed in the pool.
          <% } if (configTips) { %>
             If the number of "request timed out" events is large, 
             this parameter may need to be increased.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>FND_JDBC_BUFFER_MIN:</td>
      <td align=left><%=dbcoPool.getBufferMin()%></td>
      <td><% if (define) { %>
             Minimum number of available connections that should be
             maintained by the pool maintenance thread.
          <% } if (configTips) { %>
             If the number of "buffer empty" events is large, this parameter
             may need to be increased.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>FND_JDBC_BUFFER_MAX:</td>
      <td align=left><%=dbcoPool.getBufferMax()%></td>
      <td><% if (define) { %>
             Maximum number of available connections that should be
             maintained by the pool maintenance thread.
             If a percent, the maximum is determined dynamically as
             a percent of the total pool size.
          <% } if (configTips) { %>
             If the number of "connection created by thread" events and 
             "connection destroyed by thread" events are both large,
             this parameter may need to be increased.  On the other hand, if
             no connections are being destroyed by the thread during times of
             low pool usage, this parameter may need to be decreased.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>FND_JDBC_BUFFER_DECAY_INTERVAL:</td>
      <td align=left><%=dbcoPool.getBufferDecayInterval()%></td>
      <td><% if (define) { %>
             How often, in seconds, the pool maintenance thread should check 
             if the number of available connections is greater than
             the buffer maximum.
          <% } if (configTips) { %>
             When the buffer size exceeds the buffer maximum, the excess
             connection decay rate will be equal to the ratio of
             the decay size to the decay interval.
             FND_JDBC_BUFFER_DECAY_INTERVAL can be decreased to increase this 
             decay rate.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>FND_JDBC_BUFFER_DECAY_SIZE:</td>
      <td align=left><%=dbcoPool.getBufferDecaySize()%></td>
      <td><% if (define) { %>
             Maximum number of available connections to remove
             during each decay interval. 
          <% } if (configTips) { %>
             When the buffer size exceeds the buffer maximum, the excess
             connection decay rate will be equal to the ratio of
             the decay size to the decay interval.
             FND_JDBC_BUFFER_DECAY_SIZE can be increased to increase this
             decay rate.
          <% } %>
          </td>
  </tr>
  <tr valign=top><td></td>
      <th align=right>FND_JDBC_USABLE_CHECK:</td>
      <td align=left><%=dbcoPool.getUsableCheck()%></td>
      <td><% if (define) { %>
             Indicates whether a simple PL/SQL query should
             be performed to check whether a connection is
             usable before giving the connection to the client.
          <% } if (configTips) { %>
             If the number of "not usable" events is 0, this parameter
             probably can be set to false.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>FND_JDBC_CONTEXT_CHECK:</td>
      <td align=left><%=dbcoPool.getContextCheck()%></td>
      <td><% if (define) { %>
             Indicates whether the AOL security context and NLS
             state should be obtained from the database server
             session instead of the java client when a connection
             is returned to the pool.
          <% } if (configTips) { %>
             If the number of "context mismatch" events is 0, this parameter
             probably can be set to false.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>FND_JDBC_PLSQL_RESET:</td>
      <td align=left><%=dbcoPool.getPlsqlReset()%></td>
      <td><% if (define) { %>
             Indicates whether a connection's PL/SQL state should be
             freed before the pool gives the connection to the client.
          <% } if (configTips) { %>
             This parameter should be set to true only if specifically
             instructed to do so in application or patch documentation.
          <% } %>
          </td>
  </tr>
  <!--                          -->
  <!--   Current Statistics     -->
  <!--                          -->
  <tr valign=top>
      <th colspan=4 align=left>Current Statistics</th>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>available connections:</td>
      <td align=left><%=poolStats[eventCode.NUMBER_AVAILABLE]%></td>
      <td><% if (define) { %>
             Number of connections currently available.
          <% } if (configTips) { %>
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>
        <a href="AoljDbcPoolStatus.jsp?mode=Locked+Connections">
          locked connections</a>:</td>
      <td align=left><%=poolStats[eventCode.NUMBER_LOCKED]%></td>
      <td><% if (define) { %>
             Number of connections currently locked.
          <% } if (configTips) { %>
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>connections currently being created:</td>
      <td align=left><%=poolStats[eventCode.BEING_CREATED]%></td>
      <td><% if (define) { %>
             Number of connections currently in the process of being created.
          <% } if (configTips) { %>
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>pool size counter:</td>
      <td align=left><%=poolStats[eventCode.POOL_SIZE]%></td>
      <td><% if (define) { %>
             Current total pool size.
          <% } if (configTips) { %>
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>clients waiting:</td>
      <td align=left><%=poolStats[eventCode.CLIENT_WAITING]%></td>
      <td><% if (define) { %>
             Number of clients currently waiting for a connection
             to become available.
          <% } if (configTips) { %>
          <% } %>
          </td>
  </tr>
  <!--                          -->
  <!--   Lifetime Statistics    -->
  <!--                          -->
  <tr valign=top>
      <th colspan=4 align=left>Lifetime Statistics</th>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>request:</td>
      <td align=left><%=poolStats[eventCode.REQUEST]%></td>
      <td><% if (define) { %>
             Total number of requests that have been made.
          <% } if (configTips) { %>
             Not affected by configuration parameters.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>request successful:</td>
      <td align=left><%=poolStats[eventCode.REQUEST_SUCCESSFUL]%></td>
      <td><% if (define) { %>
             Number of requests that were successful.
          <% } if (configTips) { %>
             If small compared to "request", either
             "request timed out" or "connection creation failed" will
             be large.  Steps should be taken to address whichever is
             the major cause of the request failures.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>request timed out:</td>
      <td align=left><%=poolStats[eventCode.REQUEST_TIMED_OUT]%></td>
      <td><% if (define) { %>
             Number of requests that failed because the request
             timed out.
          <% } if (configTips) { %>
             If this and "pool at maximum size" are both large,
             FND_MAX_JDBC_CONNECTIONS may need to be increased.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>connection creation failed:</td>
      <td align=left><%=poolStats[eventCode.CREATE_FAILED]%></td>
      <td><% if (define) { %>
             Number of requests that failed because the attempt to create a 
             connection failed.  
          <% } if (configTips) { %>
             "Connection creation failed" events occur when the dbc file is 
             misconfigured, if the database is down, or if the maximum number 
             of connections allowed by the database has been reached.  
             If large, the source of the failure should be researched and
             fixed.
             Not affected by configuration parameters.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>connection created:</td>
      <td align=left><%=poolStats[eventCode.CREATED]%></td>
      <td><% if (define) { %>
             Total number of connections that have been created.
          <% } if (configTips) { %>
             "Connection created" minus "connection destroyed" should be
             equal to "pool size counter".  Not affected by
             configuration parameters.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>connection created by thread:</td>
      <td align=left><%=poolStats[eventCode.CREATED_BY_THREAD]%></td>
      <td><% if (define) { %>
             Number of connections that have been created
             by the pool maintenance thread.
          <% } if (configTips) { %>
             If this and "connection destroyed by thread" are both 
             large, it could indicate that the thread is needlessly destroying
             and creating extra connections.  This can occur if 
             FND_JDBC_BUFFER_MIN and FND_JDBC_BUFFER_MAX are too close 
             together.  In this case, FND_JDBC_BUFFER_MAX may need to be 
             increased.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>connection creation by thread failed:</td>
      <td align=left><%=poolStats[eventCode.CREATE_FAILED_BY_THREAD]%></td>
      <td><% if (define) { %>
             Number of times an attempt to create a connection by the
             pool maintenance thread failed.
          <% } if (configTips) { %>
             Should be zero or very small.
             Not affected by configuration parameters.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>connection destroyed:</td>
      <td align=left><%=poolStats[eventCode.DESTROYED]%></td>
      <td><% if (define) { %>
             Total number of connections that have been destroyed.
          <% } if (configTips) { %>
             "Connection created" minus "connection destroyed" should be
             equal to "pool size counter".  Not affected by
             configuration parameters.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>connection destroyed by thread:</td>
      <td align=left><%=poolStats[eventCode.DESTROYED_BY_THREAD]%></td>
      <td><% if (define) { %>
             Number of connections that have been destroyed by the
             pool maintenance thread.
          <% } if (configTips) { %>
             If large, see "connection created by thread" for configuration
             information.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>
        <a href="AoljDbcPoolStatus.jsp?mode=Closed+Connections">
          closed connections</a>:</td>
      <td align=left><%=poolStats[eventCode.CLOSED_CONNECTION]%></td>
      <td><% if (define) { %>
             Number of locked connections that were destroyed because they 
             were closed by the client before they were returned to the pool.
          <% } if (configTips) { %>
             Should be zero or very small.
             If large, the source of the closed connections should be 
             researched.
             Not affected by configuration parameters.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>
        <a href="AoljDbcPoolStatus.jsp?mode=Abandoned+Connections">
          abandoned connections</a>:</td>
      <td align=left><%=poolStats[eventCode.ABANDONED]%></td>
      <td><% if (define) { %>
             Number of locked connections that were destroyed because they 
             were abandoned by the client.
          <% } if (configTips) { %>
             Should be zero or very small. If large, the source of the
             abandoned connections should be researched.
             Not affected by configuration parameters.  
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>removed available connection</td>
      <td align=left><%=poolStats[eventCode.AVAILABLE_REMOVED]%></td>
      <td><% if (define) { %>
             Number of available connections that were destroyed to 
             make space for a client request that did not match any of 
             the available connections.
          <% } if (configTips) { %>
             May be large if more than one database is being
             accessed.  If only one database is being used, 
             should be zero or small.  
             Not affected by configuration parameters.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>pool at maximum size:</td>
      <td align=left><%=poolStats[eventCode.MAXIMUM_LOCKED]%></td>
      <td><% if (define) { %>
             Number of times the pool was at maximum size and all connections
             were locked when a client made a request.
          <% } if (configTips) { %>
             If this and "request timed out" 
             are large, FND_JDBC_MAX_CONNECTIONS may need to be increased.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>buffer empty:</td>
      <td align=left><%=poolStats[eventCode.BUFFER_EMPTY]%></td>
      <td><% if (define) { %>
             Number of times the buffer was empty when a client made a 
             request and the pool was not yet at maximum size.
          <% } if (configTips) { %>
             When a "buffer empty" event occurs, the amount of time spent by 
             the client in getting the connection is larger than if the buffer 
             is not empty because a new connection has to be created.  
             If large, FND_JDBC_BUFFER_MIN may need to be 
             increased.
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>context mismatch:</td>
      <td align=left><%=poolStats[eventCode.CONTEXT_MISMATCH]%></td>
      <td><% if (define) { %>
             Number of times the java tier context did not match the 
             database server tier context when a connection was returned
             to the pool.
          <% } if (configTips) { %>
             If zero, FND_JDBC_CONTEXT_CHECK probably can be set to false.
             (Should always be zero when FND_JDBC_CONTEXT_CHECK is set to 
             false, since this check is not performed in that case.)
          <% } %>
          </td>
  </tr>
  <tr valign=top>
      <td></td>
      <th align=right>not usable:</td>
      <td align=left><%=poolStats[eventCode.CONNECTION_NOT_USABLE]%></td>
      <td><% if (define) { %>
             Number of times a connection selected from the pool was not
             usable.
          <% } if (configTips) { %>
             If zero, FND_JDBC_USABLE_CHECK probably can be
             set to false.
             (Should always be zero when FND_JDBC_USABLE_CHECK is set to 
             false, since this check is not performed in that case.)
          <% } %>
          </td>
  </tr>
  <!--                          -->
  <!--  Column Spacing Control  -->
  <!--                          -->
  <tr valign=top>
      <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp</td>
      <td></td>
      <td></td>
      <td></td>
  </tr>
  <tr valign=top>
      <td>&nbsp;</td>
      <td></td>
      <td></td>
      <td></td>
  </tr>
  </table>
  <%

  } // end else
} // end pageBody
%>
</FORM>
</BODY>
</HTML>
