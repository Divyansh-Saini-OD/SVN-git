/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cs.csz.sendmail.webui;

import java.io.Serializable;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Connection;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.jdbc.OracleTypes;
//import oracle.jbo.domain.BlobDomain;
//import oracle.jbo.domain.Number;
//import oracle.sql.BLOB;
/**
 * Controller for ...
 */
public class SendMailCO extends OAControllerImpl
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

    //code for passing parameters
    Serializable[]param = new Serializable[8];
    //System.out.println("Class: " + pageContext.getParameterObject("Attachment").getClass());
    param[0] = "" + pageContext.getParameter("txtFrom");
    param[1] = "" + pageContext.getParameter("txtTo");
    param[2] = "" + pageContext.getParameter("txtCC");
    param[3] = "" + pageContext.getParameter("txtBcc");
    param[4] = "" + pageContext.getParameter("txtSubject");
    param[5] = "" + pageContext.getParameter("txtMessage");
    param[6] = "" + pageContext.getParameter("txtAction");
    param[7] = "" + pageContext.getParameter("hdnIncidentNo");
    //param[7] = "" + pageContext.getParameterObject("Attachment");

    //btnSubmit is the item id for submit button
    if (pageContext.getParameter("btnSubmit") != null) 
    {
      int nReturn = 0;
      //System.out.println("return_code: " + (pageContext.getApplicationModule(webBean).invokeMethod("processMail", param)).toString());
      processMail( pageContext.getParameter("txtFrom"),
                   pageContext.getParameter("txtTo"),
                   pageContext.getParameter("txtCC"),
                   pageContext.getParameter("txtBcc"),
                   pageContext.getParameter("txtSubject"),
                   pageContext.getParameter("txtMessage"),
                   pageContext.getParameter("txtAction"),
                   pageContext.getParameter("hdnIncidentNo"),
                   webBean,
                   pageContext
                 );
      //nReturn = Integer.parseInt((pageContext.getApplicationModule(webBean).invokeMethod("processMail", param)).toString());
      
      System.out.println("return_code: " + nReturn);
      //strReturn is the return value for the method runConcReqSet in <xx>AMImpl.java
      if (nReturn == 0 ) {
       pageContext.redirectImmediately("OA.jsp?page=/od/oracle/apps/xxcrm/cs/csz/sendmail/webui/ConfirmPage");       
      } else
      {
        OAException msg1 = new OAException("There was an error in processing your mail. Please contact the System Administrator.", OAException.ERROR);
      }
    }

    
  }
  public int processMail( 
    String  strSender, 
    String  strRecipient,
    String  strCc, 		
    String  strBcc, 		
    String  strSubject,
    String  strMessage,
    String  strAction,
    String  hdnIncidentNo,
    OAWebBean webBean,
    OAPageContext pageContext
  )
  {

    int returnCode = 0;
    System.out.println("strSender: " + strSender + ", strRecipient:" + strRecipient );
    Connection conn = null;
    CallableStatement cs2 = null;
    
 try{
        conn = pageContext.getApplicationModule(webBean).getOADBTransaction().getJdbcConnection();
        cs2 = conn.prepareCall("{call XX_CS_MESG_PKG.send_email(?,?,?,?,?,?,?,?,?)}");
        cs2.setString(1, strSender);
        cs2.setString(2, strRecipient);
        cs2.setString(3, strCc);
        cs2.setString(4, strBcc);
        cs2.setString(5, strSubject);
        cs2.setString(6, strMessage);
        cs2.setString(7, strAction);
         cs2.setString(8, hdnIncidentNo);
        cs2.registerOutParameter(9, OracleTypes.NUMBER);
 
        cs2.execute();
  
        Object obj = null;
        obj = cs2.getObject(9);
        if( obj != null) 
          returnCode = ((Integer)obj).intValue();
        else
          returnCode = 0;
        cs2.close();
         
    } catch (SQLException e)
    {
        returnCode = 0;
        e.printStackTrace();
        try{
            cs2.close();
        }catch (SQLException se1){}
      } 
	  /*finally
      {
        if(conn != null)
        {
          try
          {
            conn.close();
            cs2.close();
          }catch(Exception e){}
        }
      }*/
	 finally {
			try {
				if (cs2!=null)
				cs2.close();
				}
             catch(Exception e) {}
	}

    return returnCode;
    
  }  

}
