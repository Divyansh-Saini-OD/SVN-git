/**
+==================================================================================+
 |      Copyright (c) 2002 Oracle Corporation, Redwood Shores, CA, USA             |
 |                         All rights reserved.                                    |
 +=================================================================================+
 |  FILENAME                                                                       |
 |      ODContentPopUpMenu.java                                                      |
 |                                                                                 |
 |  DESCRIPTION                                                                    |
 |      This file encapsulates the Add Content popup menu for Functional Area/     |
 |                                     Add Portlets/Show Hide Portlets             |
 |  HISTORY                                                                        |
 |      February 24, 2005   nkishore   Initial Creation                            |
 +=================================================================================+
**/

package od.oracle.apps.xxcrm.bis.common;

import com.sun.java.util.collections.ArrayList;
import oracle.apps.bis.pmv.PMVException;
import oracle.apps.bis.pmv.common.PMVUtil;
import oracle.apps.bis.pmv.common.StringUtil;
import oracle.apps.fnd.common.WebAppsContext;
import oracle.apps.bis.msg.MessageLog;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import od.oracle.apps.xxcrm.bis.components.ODComponentPageHeaderFooter;
import oracle.apps.bis.components.ComponentLayout;

import oracle.apps.bis.common.functionarea.FunctionalArea;
import oracle.apps.bis.common.functionarea.PortletType;
import oracle.apps.bis.common.functionarea.PortletDefinition;
import oracle.apps.bis.common.functionarea.PortletsParametersMatcher;

import oracle.apps.jtf.cache.CacheManager;
import oracle.apps.jtf.cache.appsimpl.AppsCacheContext;
import oracle.apps.bis.common.*;



import java.sql.Connection;


public class ODContentPopUpMenu  {



  public static final String RCS_ID="$Header: ODContentPopUpMenu.java 115.3 2006/05/10 14:45:41 tmohata noship $";
  public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.bis.common");

  private WebAppsContext  m_Wac        =   null;
  private Connection      m_Conn        =   null;
  private StringBuffer    m_PopUpMenuHtml       =   null;
  private String          m_ShowHidePopUpMenuHtml  =  "";
  private MessageLog      m_PmvMsgLog           = null;
  private ArrayList       m_FunctionalAreas;
  private ArrayList       m_PortletTypes;
  private String          m_FuncArea;
  private String          m_PortletType;
  private ArrayList       m_PortletDefinitions;
  private String[]         m_Parameters;

  private static final String funcAreaSQL = "SELECT functional_area_id,short_name,name,decode(short_name,'BIS_UNN',2,1) ordercol FROM bis_functional_areas_vl f ORDER BY ordercol";


  public ODContentPopUpMenu(WebAppsContext webAppsCntxt, String ppFnId,
                          String funcArea, String portletType, MessageLog PmvMsgLog) throws PMVException {

    m_Wac         = webAppsCntxt;
    m_Conn        = webAppsCntxt.getJDBCConnection();
    m_PmvMsgLog   = PmvMsgLog;
    m_FuncArea    = funcArea;
    m_PortletType = portletType;

    try{
       if(m_Wac != null) {
         String key = "DUMMY_KEY";  // Will pass a dummy (non-empty) string to the CacheManager so that it doesn't get
                                    // trapped in any emptyString checks. We donot need the key for any real purpose
         AppsCacheContext cctx = new AppsCacheContext(m_Wac);
         cctx.setCacheLoaderContext(Constants.MESSAGE_LOG, m_PmvMsgLog);
         cctx.setCacheLoaderContext(Constants.CONNECTION, m_Conn);
         //Get all funcAreas, portletTypes, portletDefinitions
         m_FunctionalAreas = (ArrayList) CacheManager.get(Constants.FUNCTIONAL_AREA_CACHE_NAME, Constants.BIS, key, cctx);
         m_PortletTypes = (ArrayList) CacheManager.get(Constants.PORTLET_TYPE_CACHE_NAME, Constants.BIS, key, cctx);
         m_PortletDefinitions = (ArrayList) CacheManager.get(Constants.PORTLET_DEFINITION_CACHE_NAME, Constants.BIS, key, cctx);
         //Get parameters for Parameter portlet
         String parameters = "";
         for(int i=0;i<m_PortletDefinitions.size();i++) {
           if(((PortletDefinition)m_PortletDefinitions.get(i)).getId().equals(ppFnId)) {
              parameters = ((PortletDefinition)m_PortletDefinitions.get(i)).getDimLevelShortNameString();
              // tmohata: Bug 5190902
              m_Parameters = FunctionalUtil.getParamArrayFromString(parameters);
              break;
           }
         }
         PortletsParametersMatcher matcher = new PortletsParametersMatcher();
         m_FunctionalAreas = matcher.buildHierarchy(m_FunctionalAreas, m_PortletTypes, m_PortletDefinitions, m_Parameters);
         if(StringUtil.emptyString(portletType))
            m_PortletType = ((PortletType)m_PortletTypes.get(0)).getId();
	    }
      }
    catch(Exception e) {}

    if(StringUtil.emptyString(m_FuncArea) || "0".equals(m_FuncArea)
       && m_FunctionalAreas!=null && m_FunctionalAreas.size()>0)
      m_FuncArea = ((FunctionalArea)m_FunctionalAreas.get(0)).getId();
    //buildPopUpMenu();
  }

  /**Add Content Enhancement--Build Pop Up Menu for Portlet Items in
    * Add Content Pop Up
   */
  public String getPortletItemsPopUpHtml(ArrayList portletDefinitions, String type, String allPortletIds, String selectedPortletIds)
  {
    StringBuffer html = new StringBuffer(500);
    boolean isAllPortlets = !StringUtil.emptyString(allPortletIds);
    //html.append("<div id=\"PrtlMenu\" class=\"PopUpMenu\" style=\"visibility:visible\" onmouseover=\"PrtlmenuMouseOver(event)\">\n");
    html.append("<table id=\"PrtlTbl\" summary=\"\" border=0 cellpadding=0 cellspacing=0>\n");
    //System.out.println("ContentPopUpMenu..6 getPortletItemsPopUpHtml:"+portletDefinitions);
    //System.out.println("ContentPopUpMenu..7 size:"+portletDefinitions.size());
    boolean isPortletsExist = false;
    if ( portletDefinitions != null ) {

      for(int i=0;i<portletDefinitions.size();i++)
      {
         PortletDefinition portlet = (PortletDefinition)portletDefinitions.get(i);
         String id = portlet.getId();
         String label = portlet.getLabel();
         boolean isChecked = false;
         if(!StringUtil.emptyString(selectedPortletIds))
         {
           if(StringUtil.indexOf(selectedPortletIds, id, true) >= 0)
            isChecked = true;
         }
         if(isAllPortlets && allPortletIds.indexOf(id+"~")<0)
         {
           html.append("<tr><td><a id=\"prtl").append(id).append("\" class=\"PopUpMenuItem\" title=\"");
           html.append(label).append("\" onMouseOver=\"miMovr(this)\" onMouseOut=\"miMout(this)\"");
           html.append(" onclick=\"checkBoxPrtlItemClick('").append(id).append("');\"><LABEL id=\"");
           html.append(id).append("lbl\" style=\"display:none\" for=\"").append(id).append("\">");
           html.append(label).append("</LABEL>");
           html.append("<INPUT TYPE=checkbox id=\"").append(id).append("\" value=\"").append(label).append("\"");;
           if(isChecked)
            {
              html.append(" checked");
            }
           html.append(" name=\"PortletCols\" onclick=\"checkBoxPrtlClickList(this);\" >&nbsp;&nbsp;");
           if(!StringUtil.emptyString(label) && label.length()>40)
              label = label.substring(0, 37) + "...";
           html.append(label);
           html.append("</a></td></tr>\n");
           isPortletsExist = true;
         }
      }
    }
    //if(portletDefinitions.size()==0){
    if(!isPortletsExist){
      html.append("<TD class=OraInstructionText nowrap>");
      html.append(PMVUtil.getMessage("NODATA", m_Wac));
      html.append("</TD>");
    }

    html.append("</table>");
    //html.append("</table></div>");

    return html.toString();
  }

  /**Add Content Enhancement--Build Pop Up Menu for Portlet Items without functional area
    * Currently not used--Put it for back up so that UI doesn't get reverted back.
    */
  private void buildPopUpMenuHtml() {

    StringBuffer popUpMenuBuffer = new StringBuffer(128);
    StringBuffer fullMenuBuffer = new StringBuffer(128);
    StringBuffer popUpSubMenuBuffer = new StringBuffer(128);
    int readingDirection = PMVUtil.getReadingDirectionForLocale(m_Wac.getCurrLangCode());

    long time = System.currentTimeMillis();
    popUpMenuBuffer.append("<link rel=\"stylesheet\" type=\"text/css\" href=\"/OA_HTML/bispopcss.css?").append(time).append("\">");
    popUpMenuBuffer.append("<link rel=\"stylesheet\" type=\"text/css\" href=\"/OA_HTML/bistablepopcss.css?").append(time).append("\">");
    popUpMenuBuffer.append("<script language=\"javascript\" src=\"/OA_HTML/bispopmn.js?").append(time).append("\"></script>");

    popUpMenuBuffer.append("<div id=\"FuncAreaMenu\"");
    popUpMenuBuffer.append(" class=\"PopUpMenu\" onmouseover=\"menuMouseOver(event)\" >");
    //popUpMenuBuffer.append(" class=\"viewPopUpMenu\" >");

    for (int ii=0; ii<m_FunctionalAreas.size(); ii++) {
         FunctionalArea funcArea = (FunctionalArea)m_FunctionalAreas.get(ii);
         String id = funcArea.getId();
         String meaning = funcArea.getName();
         popUpMenuBuffer.append("<a");
         if(!StringUtil.emptyString(id))
           popUpMenuBuffer.append(" id=\"FA").append(id).append("\"");
         popUpMenuBuffer.append(" class=\"PopUpMenuItem\" title=\"").append(meaning).append("\" onfocus=\"handleTablePopListDisplay('FuncAreaMenu'");
         popUpMenuBuffer.append(");\" onclick=\"FuncAreaClick(this);\"");
         popUpMenuBuffer.append(" onmouseout=\"unhighLightTableItem(this);\"");
         popUpMenuBuffer.append(" onmouseover=\"FuncAreaMouseOver(this);\" >");

         popUpMenuBuffer.append("<span class=\"PopUpMenuItemArrow\">&#9654;</span>&nbsp;&nbsp;");
         popUpMenuBuffer.append("<span class=\"PopUpMenuItemText\"><span>");
         //popUpMenuBuffer.append("<span><span>");
         if(!StringUtil.emptyString(meaning) && meaning.length()>30)
           meaning = meaning.substring(0, 37) + "...";
         popUpMenuBuffer.append(meaning).append("</span></span>");
         //popUpMenuBuffer.append("<span class=\"PopUpMenuItemArrow\">&#9654;</span>");

         popUpMenuBuffer.append("</a>");
    }

    popUpMenuBuffer.append("</div>");

    fullMenuBuffer.append(popUpMenuBuffer);
    m_PopUpMenuHtml = fullMenuBuffer;

  }

  public StringBuffer getPopUpMenuHtml()
  {
    return m_PopUpMenuHtml;
  }
  public ArrayList getFunctionalAreas()
  {
    return m_FunctionalAreas;
  }
  public ArrayList getPortletTypes()
  {
     return m_PortletTypes;
  }

  /** tmohata Show/Hide Content Enhancement
      * This is enclosed inside div tag so that is a pop up menu and will refresh on click
      */
  public static void buildShowHidePopUpMenu(StringBuffer popUpMenuBuffer, OAPageContext pageContext,
                                            ODComponentPageHeaderFooter pageHeaderFooter)
  {

    StringBuffer fullMenuBuffer = new StringBuffer(128);
    StringBuffer popUpSubMenuBuffer = new StringBuffer(128);
    int readingDirection = PMVUtil.getReadingDirectionForLocale(pageHeaderFooter.getWebAppsContext().getCurrLangCode());

    boolean hasParameterPortlet = !StringUtil.emptyString(pageHeaderFooter.getParameterPortletFunctionId());
    //ArrayList portlets = ComponentLayout.getAllPortletNamesInPositionOrder(pageContext, pageHeaderFooter);
    //
    ArrayList portlets = pageHeaderFooter.getPortletDefinitionsInPage();

    long time = System.currentTimeMillis();
    popUpMenuBuffer.append("<link rel=\"stylesheet\" type=\"text/css\" href=\"/OA_HTML/bispopcss.css?").append(time).append("\">");
    popUpMenuBuffer.append("<link rel=\"stylesheet\" type=\"text/css\" href=\"/OA_HTML/bistablepopcss.css?").append(time).append("\">");
    popUpMenuBuffer.append("<script language=\"javascript\" src=\"/OA_HTML/bispopmn.js?").append(time).append("\"></script>");

    popUpMenuBuffer.append("<div id=\"ShowHideMenu\"");
    popUpMenuBuffer.append(" class=\"PopUpMenu\" onmouseover=\"menuMouseOver(event)\" style=\"z-index:2;overflow-y:auto;\">");
    popUpMenuBuffer.append("<table id =\"SHOW_HIDE_MENU\" summary=\"\" border=0 cellpadding=0 cellspacing=0>");
    int start = (hasParameterPortlet)?1:0;  // Do not show parameter portlet in show/hide popup

    for (int ii=start; ii<portlets.size(); ii++)
    {
      PortletDefinition portlet = (PortletDefinition)portlets.get(ii);
      String fnId = portlet.getId();
      String userFuncName = portlet.getLabel();
      String dispFlag = portlet.getDisplayFlag();
      String id = "";
      if(StringUtil.emptyString(fnId))
         id = userFuncName;    //RSS Portlets
       else
         id = fnId;            //Other portlets
      if(!StringUtil.emptyString(userFuncName))
      {

         popUpMenuBuffer.append("<tr><td><a id=\"portlet_").append(id).append("\" class=\"PopUpMenuItem\" title=\"");
         popUpMenuBuffer.append(userFuncName).append("\" onMouseOver=\"miMovr(this)\" onfocus=\"miMovr(this);\" onMouseOut=\"miMout(this)\"");
         popUpMenuBuffer.append(" onclick=\"checkBoxShowHideItemClick('").append(id).append("');\"><LABEL id=\"");
         popUpMenuBuffer.append(id).append("lbl\" style=\"display:none\" for=\"").append(id).append("\">");
         popUpMenuBuffer.append(userFuncName).append("</LABEL>");
         popUpMenuBuffer.append("<INPUT TYPE=checkbox id=\"");
         popUpMenuBuffer.append(id).append("\" value=\"").append(userFuncName);
         popUpMenuBuffer.append("\" name=\"DisplayPortlets\"");
	       if("Y".equals(dispFlag))
            popUpMenuBuffer.append(" checked");
	       popUpMenuBuffer.append(" onclick=\"checkBoxShowHideClickList(this);\" >&nbsp;&nbsp;");
         if(!StringUtil.emptyString(userFuncName) && userFuncName.length()>30)
            userFuncName = userFuncName.substring(0, 27) + "...";
         popUpMenuBuffer.append(userFuncName);
         popUpMenuBuffer.append("</a></td></tr>\n");

      }
    }

    popUpMenuBuffer.append("</table></div>");
   }

    public String[] getParameters()
    {
      return m_Parameters;
    }
    public String getPortletType()
    {
      return m_PortletType;
    }
    public String getFunctionalArea()
    {
      return m_FuncArea;
    }

}


