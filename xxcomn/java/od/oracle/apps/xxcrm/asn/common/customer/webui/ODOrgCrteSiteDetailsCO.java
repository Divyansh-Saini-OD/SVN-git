/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageRadioButtonBean;

import oracle.jbo.Row;
import oracle.jbo.domain.Number;

/**
 * Controller for ....
 */
public class ODOrgCrteSiteDetailsCO extends OAControllerImpl
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
    String partySiteId = null;
    String orgPartyId = null;
    String locId = null;
    String isNewPage = pageContext.getParameter("ODASNNewCrtePage");
    if(isNewPage!=null){
        
    }
    else{
       isNewPage="Y";
    }
      pageContext.writeDiagnostics("SMJ", "ODASNNewCrtePage:"+isNewPage, 2);  
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    OAApplicationModule nestedAM = (OAApplicationModule)am.findApplicationModule("HzPuiAddressAM");
    OAViewObjectImpl nestedVO = (OAViewObjectImpl)nestedAM.findViewObject("HzPuiPartySiteVO");
    OAViewObjectImpl locVO = (OAViewObjectImpl)nestedAM.findViewObject("HzPuiLocationVO");
      if(nestedVO!=null){
       if(nestedVO.getCurrentRow()!=null){
           if(nestedVO.getCurrentRow().getAttribute("PartySiteId")!=null)
               partySiteId = nestedVO.getCurrentRow().getAttribute("PartySiteId").toString();
           pageContext.writeDiagnostics("SMJ", "HzPuiPartySiteVO New PSI:"+partySiteId, 2); 
           if(nestedVO.getCurrentRow().getAttribute("PartyId")!=null)
               orgPartyId = nestedVO.getCurrentRow().getAttribute("PartyId").toString();   
           pageContext.writeDiagnostics("SMJ", "HzPuiPartySiteVO New PI:"+orgPartyId, 2); 
           pageContext.putParameter("HzPuiPerProfileObjectId", orgPartyId);
           pageContext.putParameter("ObjectId", orgPartyId);
           pageContext.putParameter("HzPuiAddressPartyId", orgPartyId);
           pageContext.putParameter("HzPuiAddressPartySiteId",  partySiteId);
           if(locVO!=null){
           if(locVO.getCurrentRow()!=null){
               locId = locVO.getCurrentRow().getAttribute("LocationId").toString();
               pageContext.putParameter("HzPuiAddressLocationId", locId);
               pageContext.putTransactionValue("HzPuiAddressLocationIdTXN", 
                                                       locId);
           }
           }
       }
       else {
           pageContext.writeDiagnostics("SMJ", "HzPuiPartySiteVO.currentRow is NULL", 2);  
       }
      }
      else{
          pageContext.writeDiagnostics("SMJ", "SMJ HzPuiPartySiteVO is NULL", 2);
      }
    /*
    OAViewObject vo = (OAViewObject)am.findViewObject("ODHzPartySitesExtVLVO");
    if("Y".equals(isNewPage)){
        pageContext.writeDiagnostics("SMJ", "ODASNNewCrtePage is Y", 2);
    if(vo!=null){
        Row row = null;
        if(row==null){
          pageContext.writeDiagnostics("SMJ", "ODHzPartySitesExtVLVO Create Row", 2);
          row = vo.createRow();
          row.setAttribute("AttrGroupId",new Number(161));
          row.setAttribute("PartySiteId",new Number(Integer.parseInt(partySiteId)));
          row.setAttribute("NExtAttr8",new Number(0));
          row.setNewRowState(Row.STATUS_INITIALIZED);
          vo.insertRow(row);
        }   
        else{
            pageContext.writeDiagnostics("SMJ", "ODHzPartySitesExtVLVO Do Nothing", 2);
    }
    }
    }
    else{
        Row row = vo.first();
        pageContext.writeDiagnostics("SMJ", "ODASNNewCrtePage is N", 2);
        pageContext.writeDiagnostics("SMJ", "PartySite:"+row.getAttribute("PartySiteId").toString(), 2);
        pageContext.writeDiagnostics("SMJ", "AttrGroupID:"+row.getAttribute("AttrGroupId").toString(), 2);
    }
    */
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
    String partySiteId = pageContext.getParameter("HzPuiExtEntityId");
    pageContext.writeDiagnostics("SMJ","partySiteId:"+partySiteId,OAFwkConstants.STATEMENT);
  }

}
