/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.iby.schema.webui;

import com.sun.java.util.collections.HashMap ;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/**
 * Controller for ...
 */
public class XxIbySettlement101DetailsCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    System.out.println("++XxIbySettlement101DetailsCO PR++");
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    
    String sReceiptNum1 = (String)pageContext.getParameter("ReceiptNum");
    System.out.println("sReceiptNum1: " + sReceiptNum1);
    if (sReceiptNum1 == null)
         sReceiptNum1 = "1108976#1108923508#XXO_3059490";
         
    String sStoreNum1 = (String)pageContext.getParameter("StoreNum");
    System.out.println("sStoreNum1: " + sStoreNum1);
    
    if (sStoreNum1 == null)
          sStoreNum1 = "000703";
          
    OAViewObject vo1 = (OAViewObject)am.findViewObject("XxIbyBatchTrxHistDetailsVO1");
    if (vo1 !=null)
    {
        vo1.setWhereClause(null);
        vo1.setWhereClauseParams(null);
        //vo1.setWhereClause("ixrecptnumber = :1 and ixstorenumber = :2");
        vo1.setWhereClause("IXRECEIPTNUMBER = :1");
        vo1.setWhereClauseParam(0, sReceiptNum1);
        //vo1.setWhereClauseParam(1, sStoreNum1);
        System.out.println("XxIbySettlement101DetailsCO vo.getQuery: " + vo1.getQuery());
        vo1.clearCache();
        vo1.executeQuery();    
        System.out.println("XxIbySettlement101DetailsCO vo.getRowCount: " + vo1.getRowCount());
        pageContext.putParameter("Ixreceiptnumber", sReceiptNum1);
        OARow row1 = (OARow)vo1.first();
        if (row1 != null) {
          pageContext.putParameter("Ixreceiptnumber", (String)row1.getAttribute("Ixreceiptnumber"));
          pageContext.putParameter("Ixipaymentbatchnumber", (String)row1.getAttribute("Ixipaymentbatchnumber"));
            String s1 = (String)row1.getAttribute("Ixreceiptnumber");
            String s2 = (String)row1.getAttribute("Ixipaymentbatchnumber");  
            
            System.out.println("In PR s1: " + s1);
            System.out.println("In PR s2: " + s2);
        }
    }    
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
    String s1 = (String)pageContext.getParameter("Ixreceiptnumber");
    String s2 = (String)pageContext.getParameter("Ixipaymentbatchnumber");    
    
    System.out.println("s1: " + s1);
    System.out.println("s2: " + s2);

    HashMap hashmap;
    hashmap = new HashMap();
    hashmap.put("Ixreceiptnumber", s1);
    hashmap.put("Ixipaymentbatchnumber", s2);
    
    String sEvent = (String)pageContext.getParameter("event");
    if ("show201Details".equalsIgnoreCase(sEvent)) {
    
        pageContext.setForwardURL("OA.jsp?page=/od/oracle/apps/xxfin/iby/schema/webui/XxIbySettlementDtlsPG",
                                  "",
                                  OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                  "",
                                  hashmap,
                                  true,
                                  OAWebBeanConstants.ADD_BREAD_CRUMB_YES,
                                  OAWebBeanConstants.IGNORE_MESSAGES);
    }
  }

}
