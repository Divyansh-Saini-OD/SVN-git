/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.ar.irec.statements.webui;

import java.io.Serializable;

import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;

import od.oracle.apps.xxfin.ar.irec.statements.server.StatementsAMImpl;
import od.oracle.apps.xxfin.ar.irec.statements.server.StatementsVOImpl;

import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OABodyBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAQueryBean;

import oracle.cabo.ui.data.DataObject;

//import oracle.apps.fnd.framework.OAViewObject;
//import oracle.apps.fnd.framework.OAApplicationModule;

public class StatementsCO extends IROAControllerImpl // OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    OAWebBean body = pageContext.getRootWebBean();
    if (body instanceof OABodyBean)
    {
      ((OABodyBean)body).setBlockOnEverySubmit(true); // this makes sure you can't click a submit button again until first is processed
    }
  }

  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    OAQueryBean queryBean = (OAQueryBean)webBean.findIndexedChildRecursive("QueryRN");
    String idGo = queryBean.getGoButtonName();

    if (pageContext.getParameter(idGo) != null) {

//        String sCustomerId = "10090"; 
        String sCustomerId = pageContext.getDecryptedParameter("Ircustomerid");
//        String sSiteUseId = "3823";   
        String sSiteUseId = pageContext.getDecryptedParameter("Ircustomersiteuseid");

//    throw new OAException(sCustomerId + ":" + sSiteUseId, OAException.INFORMATION);

        try
        {
          Serializable aserializable[] = {sCustomerId, sSiteUseId};
          Class aclass[] = {Class.forName("java.lang.String"), Class.forName("java.lang.String")}; // "oracle.jbo.domain.Date"

//        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
          StatementsAMImpl am = (StatementsAMImpl)pageContext.getApplicationModule(webBean);

//        OAViewObject oaviewobject = (OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("StatementsVO1");
          StatementsVOImpl vo = (StatementsVOImpl)am.getStatementsVO1();
          vo.invokeMethod("initQuery", aserializable, aclass);
        }
        catch(ClassNotFoundException classnotfoundexception)
        {
          throw new OAException(classnotfoundexception.toString());
        }
    }

    if (pageContext.getParameter("btnZipAndDownload") != null)
    {
       StatementsAMImpl am = (StatementsAMImpl)pageContext.getApplicationModule(webBean);
       StatementsVOImpl vo = (StatementsVOImpl)am.getStatementsVO1();

       if (!vo.isExecuted()) throw new OAException("XXFIN", "AR_EBL_NO_FILES_SELECTED");

       String sSelectedFileIds = (String)am.invokeMethod("getSelectedFileIds");
       if (sSelectedFileIds.equals("")) throw new OAException("XXFIN", "AR_EBL_NO_FILES_SELECTED");
//       else throw new OAException("Selected File IDs: " + sSelectedFileIds, OAException.INFORMATION);

       Serializable[] parameters = {sSelectedFileIds};
       byte[] baFile = null;
       StatementFile sf = null;
       try {
          Class[] paramTypes = {Class.forName("java.lang.String")};
          sf = (StatementFile)am.invokeMethod("GetZippedFiles", parameters, paramTypes);
          baFile = sf.getFileData();
       }
       catch(ClassNotFoundException classnotfoundexception)
       {
          throw new OAException(classnotfoundexception.toString());
       }


       try
       {
         if (baFile.length==0) throw new Exception();
         DataObject dataobject = pageContext.getNamedDataObject("_SessionParameters");
         HttpServletResponse httpservletresponse = (HttpServletResponse)dataobject.selectValue(null, "HttpServletResponse");
         ServletOutputStream servletoutputstream = httpservletresponse.getOutputStream();

         httpservletresponse.setContentType(sf.getMimeType());

         httpservletresponse.setHeader("Content-Disposition","inline; filename=" + sf.getFileName() + " ");

         httpservletresponse.setContentLength(baFile.length);
         servletoutputstream.write(baFile, 0, baFile.length);
         servletoutputstream.flush();
         servletoutputstream.close();// *important* to ensure no more jsp output
       }
       catch(Exception ex)
       {
         try{pageContext.sendRedirect("/XXFIN_HTML/eBillingContactUsLinks.htm");}
         catch (Exception ee){}
       }
    }

    if (pageContext.getParameter("btnZipTogOneEmail") != null || pageContext.getParameter("btnNoCompOneEmail") != null)
    {
       String sEmailAddresses = pageContext.getParameter("inputEmailAddress");
       if (sEmailAddresses == null || sEmailAddresses.indexOf("@")<0 || sEmailAddresses.indexOf(".")<0)
          throw new OAException("XXFIN", "AR_EBL_INVALID_EMAIL_ADDRESS");

       String sRenameZipExtension = pageContext.getParameter("cbHideZipExtension");
       if (sRenameZipExtension != null && sRenameZipExtension.toLowerCase().equals("on")) sRenameZipExtension="Y";

       StatementsAMImpl am = (StatementsAMImpl)pageContext.getApplicationModule(webBean);
       StatementsVOImpl vo = (StatementsVOImpl)am.getStatementsVO1();
       if (!vo.isExecuted()) throw new OAException("XXFIN", "AR_EBL_NO_FILES_SELECTED");
       String sSelectedFileIds = (String)am.invokeMethod("getSelectedFileIds");
       if (sSelectedFileIds.equals("")) throw new OAException("XXFIN", "AR_EBL_NO_FILES_SELECTED");

       Serializable[] parameters = {sSelectedFileIds, sEmailAddresses, sRenameZipExtension};
       try {
          Class[] paramTypes = {Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String")};
          Boolean bSuccess = Boolean.TRUE;
          if (pageContext.getParameter("btnZipTogOneEmail") != null)
             bSuccess = (Boolean)am.invokeMethod("SendOneEmailZipped", parameters, paramTypes);
          else 
             bSuccess = (Boolean)am.invokeMethod("SendOneEmailNoCompression", parameters, paramTypes);          
            
          if (bSuccess==Boolean.FALSE) throw new OAException("XXFIN", "AR_EBL_UNABLE_TO_SEND_EMAIL");
       }
       catch(ClassNotFoundException classnotfoundexception)
       {
          throw new OAException(classnotfoundexception.toString());
       }
       am.invokeMethod("clearSelections");
       MessageToken[] tokens = null; // { new MessageToken("TOKEN", value) };
       throw new OAException("XXFIN", "AR_EBL_EMAIL_SENT", tokens, OAException.INFORMATION, null);
//       throw new OAException("eMail sent " + (new java.text.SimpleDateFormat("yyyy/MM/dd HH:mm:ss")).format(new java.util.Date()), OAException.INFORMATION);
    }
  }
}
