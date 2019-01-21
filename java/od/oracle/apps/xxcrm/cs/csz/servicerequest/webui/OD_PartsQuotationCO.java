/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.cs.csz.servicerequest.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import od.oracle.apps.xxcrm.cs.csz.servicerequest.server.OD_PartsQuotationURLVORowImpl;
import od.oracle.apps.xxcrm.cs.csz.servicerequest.server.OD_PartsQuotationAuthKeyVORowImpl;
import od.oracle.apps.xxcrm.cs.csz.servicerequest.lov.server.OD_PartsQuotationLocationLOVVOImpl;
import od.oracle.apps.xxcrm.cs.csz.servicerequest.lov.server.OD_PartsQuotationLocationLOVVORowImpl;
import od.oracle.apps.xxcrm.cs.csz.servicerequest.server.OD_PartsQuotationAMImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;
/**
 * Controller for ...
 */
public class OD_PartsQuotationCO extends OAControllerImpl
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
    OAApplicationModule partQtAM = pageContext.getApplicationModule(webBean);
    partQtAM.invokeMethod("createPartsQuotation");
    String uId = String.valueOf(pageContext.getUserId());
    String uName = pageContext.getUserName();
    Serializable[] uid = {uName};    
    partQtAM.invokeMethod("invokeLocation",uid); 
    OAViewObject locVO = (OAViewObject)partQtAM.findViewObject("OD_PartsQuotationLocationVO");
    OAApplicationModule am=pageContext.getApplicationModule(webBean);   
    OD_PartsQuotationAMImpl amObj=(OD_PartsQuotationAMImpl)am;
    OD_PartsQuotationLocationLOVVOImpl vo= amObj.getOD_PartsQuotationLocationLOVVO();
    OD_PartsQuotationLocationLOVVORowImpl voRow=(OD_PartsQuotationLocationLOVVORowImpl)vo.getCurrentRow();
    if(voRow != null){
    if(voRow.getLocationNumber() != null && !"".equals(voRow.getLocationNumber())){
    String loc = voRow.getLocationNumber();
    OAMessageLovInputBean locBean = (OAMessageLovInputBean)webBean.findChildRecursive("Location");
    locBean.setValue(pageContext,loc);
    }
    }
    if("submit".equals(pageContext.getParameter("submit")))
    {
      OAButtonBean submitBtn = (OAButtonBean)webBean.findChildRecursive("Submit");
      submitBtn.setDestination(pageContext.getParameter("url"));
      submitBtn.setTargetFrame("_blank");
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
    OAApplicationModule partQtAM = pageContext.getApplicationModule(webBean);

    OAViewObject urlVO = (OAViewObject)partQtAM.findViewObject("OD_PartsQuotationURLVO");
    OAViewObject authKeyVO = (OAViewObject)partQtAM.findViewObject("OD_PartsQuotationAuthKeyVO");    
    urlVO.executeQuery();
    if(urlVO.getRowCount() == 0 )
    {
     urlVO.setWhereClause(null); 
    }
    OD_PartsQuotationURLVORowImpl urlVORow = (OD_PartsQuotationURLVORowImpl)urlVO.first();
    OD_PartsQuotationAuthKeyVORowImpl authKeyVORow = (OD_PartsQuotationAuthKeyVORowImpl)authKeyVO.first();

    OADBTransaction transaction = partQtAM.getOADBTransaction();
    String srSeq = transaction.getSequenceValue("XX_CS_TDS_REQ_NO_S").toString();    
    if(pageContext.getParameter("Submit") != null)
//    if("submit".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      String url = urlVORow.getUrl();
      StringBuffer buildURL = new StringBuffer();
      String location = null;
      if(pageContext.getParameter("Location") != null){
      location = pageContext.getParameter("Location");
      if(buildURL.length()!=0)
      buildURL = buildURL.append("&");
//      buildURL = buildURL.append("SRNUMBER="+location.concat(srSeq));
//      buildURL = buildURL.append("&STORENUMBER="+location);
      //encrypting the parameter values
      buildURL = buildURL.append("SRNUMBER="+pageContext.encrypt(location.concat(srSeq)));
      buildURL = buildURL.append("&STORENUMBER="+pageContext.encrypt(location)); 
      }
      if(pageContext.getParameter("OrderingAssociate")!=null &&!"".equals(pageContext.getParameter("OrderingAssociate")))
      {
      String associate = pageContext.getParameter("OrderingAssociate");
      if(buildURL.length()!=0)
      buildURL = buildURL.append("&");      
//      buildURL = buildURL.append("ASSOCIATE="+associate);
      //encrypting the parameter values
      buildURL = buildURL.append("ASSOCIATE="+pageContext.encrypt(associate));
      }
      if(authKeyVORow.getAuthKey()!=null)
      {
      String authKey = authKeyVORow.getAuthKey(); 
      if(buildURL.length()!=0)
      buildURL = buildURL.append("&");      
//      buildURL = buildURL.append("AUTHKEY="+authKey);
      //encrypting the parameter values
      buildURL = buildURL.append("AUTHKEY="+pageContext.encrypt(authKey));      
      }
      if(pageContext.getParameter("Manufacturer")!=null &&!"".equals(pageContext.getParameter("Manufacturer")))
      {
      String manufacturer = pageContext.getParameter("Manufacturer"); 
      if(buildURL.length()!=0)
      buildURL = buildURL.append("&");      
//      buildURL = buildURL.append("ODMANUFACTURER="+manufacturer);  
      //encrypting the parameter values
      buildURL = buildURL.append("ODMANUFACTURER="+pageContext.encrypt(manufacturer));      
      }
      else
      {
      if(buildURL.length()!=0)
      buildURL = buildURL.append("&");      
//      buildURL = buildURL.append("ODMANUFACTURER=NA"); 
      buildURL = buildURL.append("ODMANUFACTURER="+pageContext.encrypt("NA"));      
      }
      
      if(pageContext.getParameter("Model")!=null  &&!"".equals(pageContext.getParameter("Model")))
      {
      String model = pageContext.getParameter("Model"); 
      if(buildURL.length()!=0)
      buildURL = buildURL.append("&");      
//      buildURL = buildURL.append("ODMODEL="+model); 
      //encrypting the parameter values
      buildURL = buildURL.append("ODMODEL="+pageContext.encrypt(model));      
      }   
      else
      {
      if(buildURL.length()!=0)
      buildURL = buildURL.append("&");      
//      buildURL = buildURL.append("ODMODEL=NA");
      //encrypting the parameter values
      buildURL = buildURL.append("ODMODEL="+pageContext.encrypt("NA"));      
      }      
      if(pageContext.getParameter("SerialNumber")!=null  &&!"".equals(pageContext.getParameter("SerialNumber")))
      {
      String serNumber = pageContext.getParameter("SerialNumber"); 
      if(buildURL.length()!=0)
      buildURL = buildURL.append("&");      
//      buildURL = buildURL.append("ODSERIAL="+serNumber);
      //encrypting the parameter values
      buildURL = buildURL.append("ODSERIAL="+pageContext.encrypt(serNumber));      
      }
      else
      {
      if(buildURL.length()!=0)
      buildURL = buildURL.append("&");      
//      buildURL = buildURL.append("ODSERIAL=NA");
      //encrypting the parameter values
      buildURL = buildURL.append("ODSERIAL="+pageContext.encrypt("NA"));      
      }      

      String quoteURL = url+buildURL;
      String uID = String.valueOf(pageContext.getUserId());
      System.out.println("### quoteURL="+quoteURL);
      
      Serializable[] params = {location.concat(srSeq).toString(),uID};
      partQtAM.invokeMethod("setSeqUid",params);
      partQtAM.invokeMethod("apply");
      pageContext.forwardImmediately(quoteURL
      , null
      , OAWebBeanConstants.KEEP_MENU_CONTEXT
      , null
      , null
      , true
      , OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

    }
  }

}
