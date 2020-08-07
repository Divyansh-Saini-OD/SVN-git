/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODOrgCreateCO.java                                            |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Page Controller for the Create Organization Page                       |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the displaying the Site Extensible Attributes            |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   14-Nov-2007 Jasmine Sujithra   Created                                  |
 |   23-Nov-2007 Jasmine Sujithra   Updated Entity Id to -99999              |
 |   24-Nov-2007 V Jayamohan        Calls autonamed API before page forward  |
 |   30-Nov-2007 Jasmine Sujithra   Changed to custom AM ODOrgCreateAM       |
 |   23-Sep-2008 Sarah Justina      Fixed the Party Duplication QC #11358    |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.asn.common.customer.webui.OrgCreateCO;
import com.sun.java.util.collections.HashMap;
import java.io.Serializable;

import java.sql.CallableStatement;

import java.util.Vector;
import oracle.apps.ar.hz.components.util.server.HzPuiServerUtil;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OABodyBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.cabo.ui.beans.BodyBean;
import oracle.cabo.ui.beans.layout.PageLayoutBean;
import oracle.sql.*;
import java.sql.SQLException;
import oracle.jdbc.OracleCallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.beans.OAStaticStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageRadioButtonBean;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

import oracle.jbo.Row;
import oracle.jbo.domain.Number;

/**
 * Controller for ...
 */
public class ODOrgCreateCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
  {
	      String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgCreateCO.processRequest";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        String sPartysiteId =   oapagecontext.getParameter("HzPuiCreatedPartySiteId");
        String asnreqselsiteid = oapagecontext.getParameter("ASNReqSelSiteId");
        String asnreqfrmsiteid = oapagecontext.getParameter("ASNReqFrmSiteId");
        oapagecontext.writeDiagnostics(s, "HzPuiCreatedPartySiteId : " +sPartysiteId, 2);
        oapagecontext.writeDiagnostics(s, "ASNReqSelSiteId : " +asnreqselsiteid, 2);
        oapagecontext.writeDiagnostics(s, "ASNReqFrmSiteId : " +asnreqfrmsiteid, 2);
        String terrValue = oapagecontext.getParameter("terrRadioGroup");
        oapagecontext.writeDiagnostics(s, "terrRadioGroup : " +terrValue, 2);
        if (sPartysiteId == null)
        {
            sPartysiteId = "-22222"; //dummy value

        }
        oapagecontext.putParameter("HzPuiExtEntityId", sPartysiteId);
        oapagecontext.putParameter("HzPuiExtAMPath", "ODOrgCreateAM");
        oapagecontext.putParameter("ODSiteAttributeGroup", "Y");

        super.processRequest(oapagecontext, oawebbean);
        OAWebBean oawebbean1 = oapagecontext.getRootWebBean();
        if(oawebbean1 != null && (oawebbean1 instanceof OABodyBean))
            ((OABodyBean)oawebbean1).setBlockOnEverySubmit(true);
        String s1 = oapagecontext.getParameter("ASNReqFromLOVPage");
        if(s1 != null)
        {
            OAPageButtonBarBean oapagebuttonbarbean = (OAPageButtonBarBean)oapagecontext.getPageLayoutBean().getPageButtons();
            OASubmitButtonBean oasubmitbuttonbean = (OASubmitButtonBean)oapagebuttonbarbean.findIndexedChildRecursive("ASNPageSvAddMoreDetBtn");
            oasubmitbuttonbean.setRendered(false);
            OASubmitButtonBean oasubmitbuttonbean1 = (OASubmitButtonBean)oapagebuttonbarbean.findIndexedChildRecursive("ASNPageApyCrteAnotherBtn");
            oasubmitbuttonbean1.setRendered(false);
        }
        if(isSubFlow(oapagecontext))
        {
            ((OAPageLayoutBean)oawebbean).setBreadCrumbEnabled(false);
            retainContextParameters(oapagecontext);
        }
      OAApplicationModule am = oapagecontext.getApplicationModule(oawebbean);
      OAMessageRadioButtonBean terrButton = (OAMessageRadioButtonBean)oawebbean.findChildRecursive("ApplyTerrRules");
      terrButton.setName("terrRadioGroup");
      terrButton.setValue("ApplyTerrRules");
      OAMessageRadioButtonBean hardAssgnButton = (OAMessageRadioButtonBean)oawebbean.findChildRecursive("HardAssign");
      hardAssgnButton.setName("terrRadioGroup");
      hardAssgnButton.setValue("HardAssign");
      OAViewObject pvo = (OAViewObject)am.findViewObject("ODTerrRulesPVO");
      if(pvo!=null){
          Row row = pvo.getCurrentRow();
          if(row==null){
              oapagecontext.writeDiagnostics(s, "SMJ PVO Create", 2);
              row = pvo.createRow();
              row.setAttribute("DisableProspect",Boolean.TRUE);
              row.setNewRowState(Row.STATUS_INITIALIZED);
              pvo.setCurrentRow(row);
              oapagecontext.writeDiagnostics(s, "SMJ PVO Row Value:"+row.getAttribute("DisableProspect"), 2);
          }
          else{
             oapagecontext.writeDiagnostics(s, "SMJ PVO Row is NULL", 2);  
          }
      }
      else{
          oapagecontext.writeDiagnostics(s, "SMJ PVO is NULL", 2);     
      }
      if(("ApplyTerrRules".equals(terrValue))||(terrValue==null)){
        terrButton.setSelected(true);
        hardAssgnButton.setSelected(false);
        Row pvoRow = pvo.getCurrentRow();
        if(pvoRow!=null){
            pvoRow.setAttribute("DisableProspect",Boolean.TRUE);
            pvoRow.setNewRowState(Row.STATUS_INITIALIZED);
        }
      }
      else{
          terrButton.setSelected(false);
          hardAssgnButton.setSelected(true); 
          Row pvoRow = pvo.getCurrentRow();
          if(pvoRow!=null){
              pvoRow.setAttribute("DisableProspect",Boolean.FALSE);
              pvoRow.setNewRowState(Row.STATUS_INITIALIZED);
          }
      }
      String hideAll = oapagecontext.getParameter("HideAll");
      String showAll = oapagecontext.getParameter("ShowAll");
      oapagecontext.writeDiagnostics(s, "HideAll : " +hideAll, 2);
      oapagecontext.writeDiagnostics(s, "showAll : " +showAll, 2);
      if("Y".equals(hideAll)){
         OAStackLayoutBean orgStack = (OAStackLayoutBean)oawebbean.findChildRecursive("OrgCreateCompositeRN");
         orgStack.setRendered(false);
         OAStackLayoutBean hiddenStack1 = (OAStackLayoutBean)oawebbean.findChildRecursive("ASNReqEvtRN");
         hiddenStack1.setRendered(false);
         OAStackLayoutBean hiddenStack2 = (OAStackLayoutBean)oawebbean.findChildRecursive("ASNReqCtxtRN");
         hiddenStack2.setRendered(false);
         OAPageButtonBarBean buttonBean = (OAPageButtonBarBean)oawebbean.findChildRecursive("ASNPageButtonRN");
         buttonBean.setRendered(false);
         String warningResName = oapagecontext.getParameter("WarningResName");
         MessageToken[] msgToken = {new MessageToken("RESOURCE_NAME",warningResName)};
         String warnText =oapagecontext.getMessage("XXCRM","XX_CRM_PROSPECT_NO_ACCESS",msgToken);
         OAHeaderBean headerRN = (OAHeaderBean)oawebbean.findChildRecursive("HeaderRN");
         headerRN.setRendered(true);
         OAStaticStyledTextBean warnBean = (OAStaticStyledTextBean)oawebbean.findChildRecursive("WarningText");
         warnBean.setText(oapagecontext,warnText);
         warnBean.setCSSClass("OraFieldText");
      }
      if("Y".equals(showAll)){
         OAStackLayoutBean orgStack = (OAStackLayoutBean)oawebbean.findChildRecursive("OrgCreateCompositeRN");
         orgStack.setRendered(true);
         OAStackLayoutBean hiddenStack1 = (OAStackLayoutBean)oawebbean.findChildRecursive("ASNReqEvtRN");
         hiddenStack1.setRendered(true);
         OAStackLayoutBean hiddenStack2 = (OAStackLayoutBean)oawebbean.findChildRecursive("ASNReqCtxtRN");
         hiddenStack2.setRendered(true);
         OAPageButtonBarBean buttonBean = (OAPageButtonBarBean)oawebbean.findChildRecursive("ASNPageButtonRN");
         buttonBean.setRendered(true);
         OAHeaderBean headerRN = (OAHeaderBean)oawebbean.findChildRecursive("HeaderRN");
         headerRN.setRendered(false);
      }
      String isNewPage = oapagecontext.getParameter("ODASNNewCrtePage");
      if(isNewPage!=null){          
      }
      else{
         isNewPage="Y";
      }
      /*OAMessageTextInputBean oamessagetextinputbean = (OAMessageTextInputBean)oawebbean.findChildRecursive("PartyAttribute13");
      if(oamessagetextinputbean != null)
          oamessagetextinputbean.setValue(oapagecontext,"PROSPECT");
      */
        
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);

  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
  {
     String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgCreateCO.processFormRequest";
     boolean flag = oapagecontext.isLoggingEnabled(2);
     if(flag)
        oapagecontext.writeDiagnostics(s, "Begin", 2);
      super.processFormRequest(oapagecontext, oawebbean);
      String processFurther = "Y";
      String relPartyId = null;
      String relId = null;
      String objPartyId = null;
      String subPartyId = null;
      String event = oapagecontext.getParameter("event");
      OAApplicationModule am = oapagecontext.getApplicationModule(oawebbean);
      
      String sicCode = oapagecontext.getParameter("SicCodeHidden");
      String wcw = oapagecontext.getParameter("ODWcw");
      String noSiteAssoc = oapagecontext.getParameter("NoSiteAssoc");
      oapagecontext.writeDiagnostics(s, "SMJ Values from PageContext", OAFwkConstants.STATEMENT);
      oapagecontext.writeDiagnostics(s, "SMJ ODWcw:"+wcw, OAFwkConstants.STATEMENT);
      oapagecontext.writeDiagnostics(s, "SMJ SicCodeHidden:"+sicCode, OAFwkConstants.STATEMENT);
      oapagecontext.writeDiagnostics(s, "SMJ NoSiteAssoc:"+noSiteAssoc, OAFwkConstants.STATEMENT);
      if(sicCode!=null && (!"".equals(sicCode)))
          oapagecontext.putTransactionValue("SicCode",sicCode);
      if(wcw!=null && (!"".equals(wcw)))
          oapagecontext.putTransactionValue("Wcw",wcw);
      if(noSiteAssoc!=null && (!"".equals(noSiteAssoc)))
          oapagecontext.putTransactionValue("NoSiteAssoc",noSiteAssoc);    
      if(wcw==null || "".equals(wcw)){
        if(oapagecontext.getTransactionValue("Wcw")!=null)
          wcw = oapagecontext.getTransactionValue("Wcw").toString();
      }
      if(sicCode==null || "".equals(sicCode)){
        if(oapagecontext.getTransactionValue("SicCode")!=null)
          sicCode = oapagecontext.getTransactionValue("SicCode").toString();
      }
      if(noSiteAssoc==null || "".equals(noSiteAssoc)){
        if(oapagecontext.getTransactionValue("NoSiteAssoc")!=null)
          noSiteAssoc = oapagecontext.getTransactionValue("NoSiteAssoc").toString();
      }
      oapagecontext.writeDiagnostics(s, "SMJ Values from Transaction", OAFwkConstants.STATEMENT);
      oapagecontext.writeDiagnostics(s, "SMJ ODWcw:"+wcw, OAFwkConstants.STATEMENT);
      oapagecontext.writeDiagnostics(s, "SMJ SicCodeHidden:"+sicCode, OAFwkConstants.STATEMENT);
      String hardAssign = oapagecontext.getParameter("terrRadioGroup");
       if (oapagecontext.isLovEvent() || "disableProspect".equals(event) ||
           "lovPrepare".equals(event)) {
            processFurther = "N";
            oapagecontext.putParameter("processFurther","N");
            if("disableProspect".equals(event)){
                OAViewObject pvo = (OAViewObject)am.findViewObject("ODTerrRulesPVO");
                Row pvoRow = pvo.getCurrentRow();
                if(pvoRow!=null){
                      if("HardAssign".equals(hardAssign))
                        pvoRow.setAttribute("DisableProspect",Boolean.FALSE);
                      else if("ApplyTerrRules".equals(hardAssign))
                        pvoRow.setAttribute("DisableProspect",Boolean.TRUE);
                      pvoRow.setNewRowState(Row.STATUS_INITIALIZED);
                }
            }
       }
        oapagecontext.writeDiagnostics(s, "SMJ HardAssign Value:"+hardAssign, OAFwkConstants.STATEMENT);
      /* Code to suppress Contact validation when contact Info is wiped out.
       if(oapagecontext.getParameter("ASNPageSvAddMoreDetBtn") != null || 
         oapagecontext.getParameter("ASNPageApyCrteAnotherBtn") != null || 
         oapagecontext.getParameter("ASNPageApyBtn") != null){
          oapagecontext.putTransactionValue("ASNCommitDataClicked","Y");
      }
      */
       oapagecontext.writeDiagnostics(s, "SMJ Lov Event:"+oapagecontext.isLovEvent(), OAFwkConstants.STATEMENT);
      oapagecontext.writeDiagnostics(s, "SMJ Event:"+event, OAFwkConstants.STATEMENT);
      if(oapagecontext.getParameter("ASNPageCnclBtn") == null &&
         oapagecontext.getParameter("YesBtn") == null &&
         oapagecontext.getParameter("NoBtn") == null &&
         (!oapagecontext.isLovEvent()) &&
          (!"disableProspect".equals(event)) &&
          (!"lovPrepare".equals(event))
         ){
          OAApplicationModule nestedAM = (OAApplicationModule)am.findApplicationModule("HzPuiAddressAM");
          OAViewObjectImpl locVO = (OAViewObjectImpl)nestedAM.findViewObject("HzPuiLocationVO");
          if(locVO!=null){
          if(locVO.getCurrentRow()!=null){
              String postalCode = null;
              String stateCode = null;
              String cityCode = null;
              if(locVO.getCurrentRow().getAttribute("PostalCode")!=null)
                postalCode = locVO.getCurrentRow().getAttribute("PostalCode").toString();
              if(locVO.getCurrentRow().getAttribute("State")!=null)  
                stateCode = locVO.getCurrentRow().getAttribute("State").toString();
              if(locVO.getCurrentRow().getAttribute("City")!=null)   
                cityCode = locVO.getCurrentRow().getAttribute("City").toString();
              if(postalCode !=null && ("".equals(postalCode)))
                    postalCode = null;
              if(stateCode !=null && ("".equals(stateCode)))
                    stateCode = null;
              if(cityCode !=null && ("".equals(cityCode)))
                    cityCode = null;
              if(postalCode == null ||
                 stateCode == null ||
                 cityCode == null){
                     processFurther = "N";
                     throw new OAException("XXCRM","XX_CRM_078_PARTY_ADDR_REQUIRED");
                     
                 }
          }
          }
        if("HardAssign".equals(hardAssign)){
            oapagecontext.writeDiagnostics(s, "SMJ In HardAssign", OAFwkConstants.STATEMENT);
            String resourceId = oapagecontext.getParameter("GeneralRepId");
            String roleId = oapagecontext.getParameter("GenRoleId");
            String groupId = oapagecontext.getParameter("GenGroupId");
            if(resourceId ==null || "".equals(resourceId)){
                oapagecontext.writeDiagnostics(s, "SMJ Resource ID is NULL", OAFwkConstants.STATEMENT);
                processFurther = "N";
                //oapagecontext.putParameter("terrRadioGroup",hardAssign);
                throw new OAException("XXCRM","XX_CRM_079_TERR_OVERRIDE_RES");
            }
            else {
                oapagecontext.writeDiagnostics(s, "SMJ Resource ID is not NULL", OAFwkConstants.STATEMENT);
            }
        }
        String phCountryCode = oapagecontext.getParameter("OrgPhoneCountryCode");
        String phAreaCode = oapagecontext.getParameter("PhoneAreaCode");
        String phNum = oapagecontext.getParameter("PhoneNumber");
        if((phCountryCode==null ||"".equals(phCountryCode))|| (phAreaCode == null || "".equals(phAreaCode)) || (phNum ==null || "".equals(phNum))){
            processFurther = "N";
            //oapagecontext.putParameter("terrRadioGroup",hardAssign);
            throw new OAException("XXCRM","XX_CRM_080_PARTY_PH_REQD");
        }
        String perFName = oapagecontext.getParameter("PersonFirstName");
        if("".equals(perFName))
            perFName = null;
        String perLName = oapagecontext.getParameter("PersonLastName");
          if("".equals(perLName))
              perLName = null;
        String perMName = oapagecontext.getParameter("PersonMiddleName");
          if("".equals(perMName))
              perMName = null;
        String email = oapagecontext.getParameter("EmailAddress");
          if("".equals(email))
              email = null; 
        String phCountCode = oapagecontext.getParameter("PerPhoneCountryCode");
          if("".equals(phCountCode))
              phCountCode = null; 
        String phAreaCode1 = oapagecontext.getParameter("PhoneAreaCode1");
          if("".equals(phAreaCode1))
              phAreaCode1 = null;         
        String phNum1 = oapagecontext.getParameter("PhoneNumber1");
          if("".equals(phNum1))
              phNum1 = null;        
        String phExt = oapagecontext.getParameter("PhoneExtension");
          if("".equals(phExt))
              phExt = null;          
          if(perFName !=null || 
             perLName !=null ||
             perMName !=null ||
             email!=null ||
             phCountCode!=null ||
             phAreaCode1!=null ||
             phNum1!=null ||
             phExt!=null ){
                     if((perFName ==null || "".equals(perFName))||(perLName ==null || "".equals(perLName))
                     || (phCountCode ==null || "".equals(phCountCode)) ||(phAreaCode1 ==null || "".equals(phAreaCode1))
                     || (phNum1 ==null || "".equals(phNum1))){
                         processFurther = "N";
                         throw new OAException("XXCRM","XX_CRM_081_PARTY_CONT_REQD"); 
                     }
                     /*if(phCountCode!=null ||
                        phAreaCode1!=null ||
                        phNum1!=null){
                            if(phCountCode == null || "".equals(phCountCode) ||phAreaCode1 == null || "".equals(phAreaCode1) || phNum1==null || "".equals(phNum1)){
                                processFurther = "N";
                                throw new OAException("Please enter the Contact Phone Country Code, Area Code and the Phone Number."); 
                            }
                        }
                        */
             }
      }
        if("Y".equals(processFurther)){
        oapagecontext.putParameter("ASNReqFrmFuncName", "ASN_ORGCREATEPG");
        HashMap hashmap = new HashMap();
        String s1 = oapagecontext.getParameter("ASNReqFromLOVPage");
        String s2 = null;
        String s3 = null;
        String s4 = null;
        OAApplicationModule oaapplicationmodule = oapagecontext.getRootApplicationModule();
        if(oapagecontext.getParameter("ASNPageCnclBtn") != null)
        {
            if(oapagecontext.getParameter("ASNReqFromLOVPage") != null)
            {
                oapagecontext.releaseRootApplicationModule();
                HashMap hashmap1 = new HashMap();
                hashmap1.put("AM", "Y");
                processTargetURL(oapagecontext, hashmap1, null);
            } else
            {
			    processTargetURL(oapagecontext, null, null);				
            }
        } else
        if(oapagecontext.getParameter("ASNPageSvAddMoreDetBtn") != null || oapagecontext.getParameter("ASNPageApyCrteAnotherBtn") != null || oapagecontext.getParameter("ASNPageApyBtn") != null)
        {
            if(oapagecontext.getParameter("ASNPageSvAddMoreDetBtn") != null)
                s2 = "SaveAddMoreDetails";
            else
            if(oapagecontext.getParameter("ASNPageApyCrteAnotherBtn") != null)
            {
                s2 = "ApplyCreateAnother";
                oapagecontext.removeParameter("HzPuiOrgCompositeExist");
                oapagecontext.removeParameter("HzPuiAddressExist");
            } else
            if(oapagecontext.getParameter("ASNPageApyBtn") != null)
                s2 = "Apply";
                
            oapagecontext.putParameter("ODASNSourceButtonClicked",s2);
            String s5 = oapagecontext.getProfile("HZ_DQM_ENABLED_FLAG");
            String orgPartyId = null;
            String pSiteId = null;
            OAApplicationModule nestedAM = (OAApplicationModule)am.findApplicationModule("HzPuiAddressAM");
            OAViewObjectImpl nestedVO = (OAViewObjectImpl)nestedAM.findViewObject("HzPuiPartySiteVO");
            if(nestedVO!=null){
             if(nestedVO.getCurrentRow()!=null){
                 orgPartyId = nestedVO.getCurrentRow().getAttribute("PartyId").toString();   
                 oapagecontext.writeDiagnostics("SMJ", "orgParty:"+orgPartyId, 2); 
                 pSiteId = nestedVO.getCurrentRow().getAttribute("PartySiteId").toString();
                 oapagecontext.writeDiagnostics("SMJ", "pSiteId:"+pSiteId, 2);
             }
            } 
            String redo = oapagecontext.getParameter("RedoNotes");
            if(redo==null || "".equals(redo)){
                redo = "Y";
            }
            if("Y".equals(redo)){
            String longNotes = oapagecontext.getParameter("ASNNotesNewText");
            if(longNotes!=null && (!"".equals(longNotes))){
            oapagecontext.writeDiagnostics("SMJ", "longNotes:"+longNotes, 2); 
            OAApplicationModule notesAM = (OAApplicationModule)am.findApplicationModule("ASNNotesAM");
            OAViewObjectImpl notesVO = (OAViewObjectImpl)notesAM.findViewObject("ASNNotesVO1");
            am.getOADBTransaction().putValue("CacNotesSourceCode","PARTY");
            am.getOADBTransaction().putValue("CacNotesSourceId",orgPartyId);
            Row notesRow = notesVO.createRow();
            notesRow.setAttribute("EnteredDate",am.getOADBTransaction().getCurrentDBDate());
            notesRow.setAttribute("EnteredByName",am.getOADBTransaction().getUserName());
            notesRow.setAttribute("AllNotesText",longNotes);
            notesRow.setAttribute("Notes",longNotes);
            notesRow.setNewRowState(Row.STATUS_NEW);
            notesVO.insertRow(notesRow);
            }
            else{
                oapagecontext.writeDiagnostics("SMJ", "longNotes IS NULL", 2);
            }
            /*
            OAViewObject vo = (OAViewObject)am.findViewObject("ODHzPartySitesExtVLVO");
                if(vo!=null){
                    Row row = null;
                    if(row==null){
                      oapagecontext.writeDiagnostics("SMJ", "ODHzPartySitesExtVLVO Create Row", 2);
                      row = vo.createRow();
                      row.setAttribute("AttrGroupId",new Number(161));
                      row.setAttribute("PartySiteId",new Number(Integer.parseInt(pSiteId)));
                      row.setAttribute("NExtAttr8",new Number(0));
                      if(wcw!=null && (!"".equals(wcw)))
                          row.setAttribute("NExtAttr8",new Number(Integer.parseInt(wcw)));
                      row.setAttribute("CExtAttr10",sicCode);
                      row.setNewRowState(Row.STATUS_NEW);
                      vo.insertRow(row);
                    }   
                    else{
                        oapagecontext.writeDiagnostics("SMJ", "ODHzPartySitesExtVLVO Do Nothing", 2);
                }
                }*/
                }
            
            if("ApplyTerrRules".equals(hardAssign)){
            this.getWinnerResource(oapagecontext,oawebbean,s2);
            }
            if("N".equals(s5))
            {
                oapagecontext.writeDiagnostics(s, "SMJ Log: B4 HzPuiServerUtil", OAFwkConstants.STATEMENT);
                Vector vector = HzPuiServerUtil.getOrgProfileQuickEx(oapagecontext.getApplicationModule(oawebbean).getOADBTransaction());
                oapagecontext.writeDiagnostics(s, "SMJ Log: After HzPuiServerUtil", OAFwkConstants.STATEMENT);
                if(vector != null)
                {
                    HashMap hashmap2 = (HashMap)vector.elementAt(0);
                    StringBuffer stringbuffer = new StringBuffer();
                    stringbuffer.append(hashmap2.get("PartyId"));
                    StringBuffer stringbuffer1 = new StringBuffer();
                    stringbuffer1.append(hashmap2.get("OrganizationName"));
                    s3 = stringbuffer.toString();
                    s4 = stringbuffer1.toString();
                }
                Vector tempData1 = HzPuiServerUtil.getContactRelRecord((oapagecontext.getApplicationModule(oawebbean)).getOADBTransaction());
                if (tempData1 != null) {
                   if (flag) {
                              oapagecontext.writeDiagnostics(s, 
                                                             "SMJ contact Vector Found = " + 
                                                             tempData1.toString(), 
                                                             OAFwkConstants.STATEMENT);
                  }
                  HashMap hTemp = (HashMap)tempData1.elementAt(0);
                  if(hTemp!=null){
                     relPartyId = hTemp.get("RelationshipPartyId").toString();
                     relId = hTemp.get("PartyRelationshipId").toString();
                     objPartyId = hTemp.get("ObjectId").toString();
                     subPartyId = hTemp.get("SubjectId").toString();
                     if (flag) {
                        StringBuffer buf = new StringBuffer();
                        buf.append("SMJ relPartyId = ");
                        buf.append(relPartyId);
                        buf.append("SMJ relId = ");
                        buf.append(relId);
                        buf.append("SMJ objPartyId = ");
                        buf.append(objPartyId);
                        buf.append("SMJ subPartyId = ");
                        buf.append(subPartyId);
                        oapagecontext.writeDiagnostics(s, 
                                                       buf.toString(), 
                                                       OAFwkConstants.STATEMENT);
                        }
                  }
                }
                String partySiteId = null;
                /*
                OAApplicationModule nestedAM = (OAApplicationModule)am.findApplicationModule("HzPuiAddressAM");
                OAViewObjectImpl nestedVO = (OAViewObjectImpl)nestedAM.findViewObject("HzPuiPartySiteVO");
                */
                  if(nestedVO!=null){
                   if(nestedVO.getCurrentRow()!=null){
                    partySiteId = nestedVO.getCurrentRow().getAttribute("PartySiteId").toString();
                   }
                  }                
                Serializable aserializable[] = {
                    s3
                };
                oaapplicationmodule.invokeMethod("commitTransaction", aserializable);
                Serializable[] params1 = {partySiteId,relId,wcw,sicCode,noSiteAssoc};
                am.invokeMethod("insertRecords",params1);
                if(s2.equals("SaveAddMoreDetails"))
                {
                    hashmap.put("ASNReqFrmFuncName", "ASN_ORGUPDATEPG");
                    hashmap.put("ASNReqFrmCustId", s3);
                    hashmap.put("ASNReqFrmCustName", s4);
                    if(!isSubFlow(oapagecontext))
                    {
                        OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
                        OABreadCrumbsBean oabreadcrumbsbean = (OABreadCrumbsBean)oapagelayoutbean.getBreadCrumbsLocator();
                        if(oabreadcrumbsbean != null)
                        {
                            int i = oabreadcrumbsbean.getLinkCount();
                            oabreadcrumbsbean.removeLink(oapagecontext, i - 1);
                        }
                    }
                    oaapplicationmodule.getTransaction().commit();
                    if("HardAssign".equals(hardAssign))
                      callHardAssignApi(oapagecontext,oawebbean);
                    else
                      callAutoNamedApi(oapagecontext,oawebbean);
                    oapagecontext.forwardImmediately("ASN_ORGUPDATEPG", (byte)0, null, hashmap, false, "Y");
                } else
                if(s2.equals("ApplyCreateAnother"))
                {
                    oapagecontext.putParameter("ASNReqPgAct", "REFRESH");
                    oaapplicationmodule.getTransaction().commit();
                    if("HardAssign".equals(hardAssign))
                      callHardAssignApi(oapagecontext,oawebbean);
                    else
                      callAutoNamedApi(oapagecontext,oawebbean);
                    HashMap hashmap4 = new HashMap();
                    hashmap4.put("ShowAll","Y");
                    hashmap4.put("HideAll","N");
                    hashmap4.put("HzPuiPersonCompositeExist", "NO");
					
                    oapagecontext.releaseAllRootApplicationModules();
                    
                    //processTargetURL(oapagecontext, null, null);
                    oapagecontext.forwardImmediately("ASN_ORGCREATEPG",
                         OAWebBeanConstants.KEEP_MENU_CONTEXT ,
                         null,
                         hashmap4,
                         false,
                         OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);

                } else
                if(s2.equals("Apply"))
                    if(oapagecontext.getParameter("ASNReqFromLOVPage") != null)
                    {
                        oapagecontext.putParameter("ASNReqSelCustId", s3);
                        oapagecontext.putParameter("ASNReqSelCustName", s4);
                        HashMap hashmap3 = new HashMap();
                        hashmap3.put("AM", "Y");
                        hashmap3.put("ASNReqFrmFuncName", "OD_ASN_CUSTOMER_SEARCHPG");
                        oaapplicationmodule.getTransaction().commit();
                        if("HardAssign".equals(hardAssign))
                          callHardAssignApi(oapagecontext,oawebbean);
                        else
                          callAutoNamedApi(oapagecontext,oawebbean);
                        //processTargetURL(oapagecontext, hashmap3, null);
                         oapagecontext.forwardImmediately("OD_ASN_CUSTOMER_SEARCHPG",
                              OAWebBeanConstants.KEEP_MENU_CONTEXT ,
                              null,
                              hashmap3,
                              false,
                              OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);
                    } else
                    {
                        oaapplicationmodule.getTransaction().commit();
                        if("HardAssign".equals(hardAssign))
                          callHardAssignApi(oapagecontext,oawebbean);
                        else
                          callAutoNamedApi(oapagecontext,oawebbean);
                        HashMap hashmap3 = new HashMap();
                        hashmap3.put("ASNReqFrmFuncName", "OD_ASN_CUSTOMER_SEARCHPG");
                        //processTargetURL(oapagecontext, hashmap3, null);
                         oapagecontext.forwardImmediately("OD_ASN_CUSTOMER_SEARCHPG",
                              OAWebBeanConstants.KEEP_MENU_CONTEXT ,
                              null,
                              hashmap3,
                              false,
                              OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);
                    }
            } else
            {
                String s6 = oapagecontext.getProfile("HZ_ORG_DUP_PREV_MATCHRULE");
                hashmap.put("HzPuiSimpleMatchRuleId", s6);
                hashmap.put("HzPuiSearchPartyType", "ORGANIZATION");
                hashmap.put("HzPuiSearchAutoQuery", "Y");
                hashmap.put("HzPuiMatchOption", "Y");
                hashmap.put("HzPuiSearchComponentMode", "LOV");
                hashmap.put("HzPuiAddressEvent", "CREATE");
                if(oapagecontext.getParameter("ASNReqFromLOVPage") != null)
                    hashmap.put("ASNReqFromLOVPage", s1);
                hashmap.put("ASNReqFrmFuncName", "ASN_ORGWARNINGPG");
                hashmap.put("ASNReqFrmButtonClicked", s2);
                hashmap.put("HardAssign", hardAssign);
                String resourceId = oapagecontext.getParameter("GeneralRepId");
                String roleId = oapagecontext.getParameter("GenRoleId");
                String groupId = oapagecontext.getParameter("GenGroupId");
                hashmap.put("GeneralRepId",resourceId);
                hashmap.put("GenRoleId",roleId);
                hashmap.put("GenGroupId",groupId);
                String winResourceId = oapagecontext.getParameter("WinnerResId");
                String winRoleId = oapagecontext.getParameter("WinnerRoleId");
                String winGroupId = oapagecontext.getParameter("WinnerGroupId");
                String fullAccFlag = oapagecontext.getParameter("WinnerAccFlag");
                hashmap.put("WinnerResId",winResourceId);
                hashmap.put("WinnerRoleId",winRoleId);
                hashmap.put("WinnerGroupId",winGroupId);
                hashmap.put("WinnerAccFlag",fullAccFlag); 
                hashmap.put("SicCode",sicCode);
                hashmap.put("Wcw",wcw);
                hashmap.put("NoSiteAssoc",noSiteAssoc);
                
                //oaapplicationmodule.getTransaction().commit();

                /*******************************************************************
                 * SJUSTINA 23-SEP-08*******Start of AutonamedCall Shift************
                 * Moved the following Autonamed Call to the Custom ASN Warning Page
                 *******************************************************************/

                //callAutoNamedApi(oapagecontext,oawebbean);

                /*******************************************************************
                 * SJUSTINA 23-SEP-08*******End of AutonamedCall Shift**************
                 *******************************************************************/
            
                oapagecontext.forwardImmediately("ASN_ORGWARNINGPG", (byte)0, null, hashmap, true, "S");
            }
        }
        else if(oapagecontext.getParameter("YesBtn")!=null){
            String sourceButton = oapagecontext.getParameter("ODASNSourceButtonClicked");
            if("ApplyCreateAnother".equals(sourceButton))
            {
                oapagecontext.removeParameter("HzPuiOrgCompositeExist");
                oapagecontext.removeParameter("HzPuiAddressExist");
            } 
            String dqmEnabled = oapagecontext.getProfile("HZ_DQM_ENABLED_FLAG");
            if("N".equals(dqmEnabled))
            {
                oapagecontext.writeDiagnostics(s, "SMJ Log: B4 HzPuiServerUtil", OAFwkConstants.STATEMENT);
                Vector vector = HzPuiServerUtil.getOrgProfileQuickEx(oapagecontext.getApplicationModule(oawebbean).getOADBTransaction());
                oapagecontext.writeDiagnostics(s, "SMJ Log: After HzPuiServerUtil", OAFwkConstants.STATEMENT);
                if(vector != null)
                {
                    HashMap hashmap2 = (HashMap)vector.elementAt(0);
                    StringBuffer stringbuffer = new StringBuffer();
                    stringbuffer.append(hashmap2.get("PartyId"));
                    StringBuffer stringbuffer1 = new StringBuffer();
                    stringbuffer1.append(hashmap2.get("OrganizationName"));
                    s3 = stringbuffer.toString();
                    s4 = stringbuffer1.toString();
                }
                Vector tempData1 = HzPuiServerUtil.getContactRelRecord((oapagecontext.getApplicationModule(oawebbean)).getOADBTransaction());
                if (tempData1 != null) {
                   if (flag) {
                              oapagecontext.writeDiagnostics(s, 
                                                             "SMJ contact Vector Found = " + 
                                                             tempData1.toString(), 
                                                             OAFwkConstants.STATEMENT);
                  }
                  HashMap hTemp = (HashMap)tempData1.elementAt(0);
                  if(hTemp!=null){
                     relPartyId = hTemp.get("RelationshipPartyId").toString();
                     relId = hTemp.get("PartyRelationshipId").toString();
                     objPartyId = hTemp.get("ObjectId").toString();
                     subPartyId = hTemp.get("SubjectId").toString();
                     if (flag) {
                        StringBuffer buf = new StringBuffer();
                        buf.append("SMJ relPartyId = ");
                        buf.append(relPartyId);
                        buf.append("SMJ relId = ");
                        buf.append(relId);
                        buf.append("SMJ objPartyId = ");
                        buf.append(objPartyId);
                        buf.append("SMJ subPartyId = ");
                        buf.append(subPartyId);
                        oapagecontext.writeDiagnostics(s, 
                                                       buf.toString(), 
                                                       OAFwkConstants.STATEMENT);
                        }
                  }
                }
                String partySiteId = null;
                OAApplicationModule nestedAM = (OAApplicationModule)am.findApplicationModule("HzPuiAddressAM");
                OAViewObjectImpl nestedVO = (OAViewObjectImpl)nestedAM.findViewObject("HzPuiPartySiteVO");
                  if(nestedVO!=null){
                   if(nestedVO.getCurrentRow()!=null){
                    partySiteId = nestedVO.getCurrentRow().getAttribute("PartySiteId").toString();
                   }
                  }
                Serializable aserializable[] = {
                    s3
                };
                
                oaapplicationmodule.invokeMethod("commitTransaction", aserializable);
                Serializable[] params1 = {partySiteId,relId,wcw,sicCode,noSiteAssoc};
                am.invokeMethod("insertRecords",params1);
                if(sourceButton.equals("SaveAddMoreDetails"))
                {
                    hashmap.put("ASNReqFrmFuncName", "ASN_ORGUPDATEPG");
                    hashmap.put("ASNReqFrmCustId", s3);
                    hashmap.put("ASNReqFrmCustName", s4);
                    if(!isSubFlow(oapagecontext))
                    {
                        OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
                        OABreadCrumbsBean oabreadcrumbsbean = (OABreadCrumbsBean)oapagelayoutbean.getBreadCrumbsLocator();
                        if(oabreadcrumbsbean != null)
                        {
                            int i = oabreadcrumbsbean.getLinkCount();
                            oabreadcrumbsbean.removeLink(oapagecontext, i - 1);
                        }
                    }
                    oaapplicationmodule.getTransaction().commit();
                    if("HardAssign".equals(hardAssign))
                      callHardAssignApi(oapagecontext,oawebbean);
                    else
                      callAutoNamedApi(oapagecontext,oawebbean);
                    oapagecontext.forwardImmediately("ASN_ORGUPDATEPG", (byte)0, null, hashmap, false, "Y");
                } else
                if(sourceButton.equals("ApplyCreateAnother"))
                {
                    oapagecontext.putParameter("ASNReqPgAct", "REFRESH");
                    oaapplicationmodule.getTransaction().commit();
                    if("HardAssign".equals(hardAssign))
                      callHardAssignApi(oapagecontext,oawebbean);
                    else
                      callAutoNamedApi(oapagecontext,oawebbean);
                    HashMap hashmap4 = new HashMap();
                    hashmap4.put("ShowAll","Y");
                    hashmap4.put("HideAll","N");
					
                    //processTargetURL(oapagecontext, hashmap4, null);
                    oapagecontext.forwardImmediately("ASN_ORGCREATEPG",
                         OAWebBeanConstants.KEEP_MENU_CONTEXT ,
                         null,
                         hashmap4,
                         false,
                         OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);

                } else
                if(sourceButton.equals("Apply"))
                    if(oapagecontext.getParameter("ASNReqFromLOVPage") != null)
                    {
                        oapagecontext.putParameter("ASNReqSelCustId", s3);
                        oapagecontext.putParameter("ASNReqSelCustName", s4);
                        HashMap hashmap3 = new HashMap();
                        hashmap3.put("AM", "Y");
                        hashmap3.put("ASNReqFrmFuncName", "OD_ASN_CUSTOMER_SEARCHPG");
                        oaapplicationmodule.getTransaction().commit();
                        if("HardAssign".equals(hardAssign))
                          callHardAssignApi(oapagecontext,oawebbean);
                        else
                          callAutoNamedApi(oapagecontext,oawebbean);
                        //processTargetURL(oapagecontext, hashmap3, null);
                         oapagecontext.forwardImmediately("OD_ASN_CUSTOMER_SEARCHPG",
                              OAWebBeanConstants.KEEP_MENU_CONTEXT ,
                              null,
                              hashmap3,
                              false,
                              OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);
                    } else
                    {
                        oaapplicationmodule.getTransaction().commit();
                        if("HardAssign".equals(hardAssign))
                          callHardAssignApi(oapagecontext,oawebbean);
                        else
                          callAutoNamedApi(oapagecontext,oawebbean);
                        HashMap hashmap3 = new HashMap();
                        hashmap3.put("AM", "Y");
                        hashmap3.put("ASNReqFrmFuncName", "OD_ASN_CUSTOMER_SEARCHPG");
                        //processTargetURL(oapagecontext, hashmap3, null);
                         oapagecontext.forwardImmediately("OD_ASN_CUSTOMER_SEARCHPG",
                              OAWebBeanConstants.KEEP_MENU_CONTEXT ,
                              null,
                              hashmap3,
                              false,
                              OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);
                    }
            } else
            {
                String s6 = oapagecontext.getProfile("HZ_ORG_DUP_PREV_MATCHRULE");
                hashmap.put("HzPuiSimpleMatchRuleId", s6);
                hashmap.put("HzPuiSearchPartyType", "ORGANIZATION");
                hashmap.put("HzPuiSearchAutoQuery", "Y");
                hashmap.put("HzPuiMatchOption", "Y");
                hashmap.put("HzPuiSearchComponentMode", "LOV");
                hashmap.put("HzPuiAddressEvent", "CREATE");
                if(oapagecontext.getParameter("ASNReqFromLOVPage") != null)
                    hashmap.put("ASNReqFromLOVPage", s1);
                hashmap.put("ASNReqFrmFuncName", "ASN_ORGWARNINGPG");
                hashmap.put("ASNReqFrmButtonClicked", sourceButton);
                hashmap.put("HardAssign", hardAssign);
                String resourceId = oapagecontext.getParameter("GeneralRepId");
                String roleId = oapagecontext.getParameter("GenRoleId");
                String groupId = oapagecontext.getParameter("GenGroupId");
                hashmap.put("GeneralRepId",resourceId);
                hashmap.put("GenRoleId",roleId);
                hashmap.put("GenGroupId",groupId);
                String winResourceId = oapagecontext.getParameter("WinnerResId");
                String winRoleId = oapagecontext.getParameter("WinnerRoleId");
                String winGroupId = oapagecontext.getParameter("WinnerGroupId");
                String fullAccFlag = oapagecontext.getParameter("WinnerAccFlag");
                hashmap.put("WinnerResId",winResourceId);
                hashmap.put("WinnerRoleId",winRoleId);
                hashmap.put("WinnerGroupId",winGroupId);  
                hashmap.put("WinnerAccFlag",fullAccFlag); 
                hashmap.put("Wcw",wcw); 
                hashmap.put("SicCode",sicCode); 
                hashmap.put("NoSiteAssoc",noSiteAssoc);
                oapagecontext.forwardImmediately("ASN_ORGWARNINGPG", (byte)0, null, hashmap, true, "S");
            }
        }
        else if(oapagecontext.getParameter("NoBtn")!=null){
            HashMap params = new HashMap();
            params.put("ShowAll","Y");
            params.put("HideAll","N");
            params.put("HzPuiOrgCompositeExist","YES");
            params.put("HzPuiPersonCompositeExist","YES");
            params.put("ODASNNewCrtePage","N");
			
            oapagecontext.forwardImmediatelyToCurrentPage(params,true,OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);
        }
        }
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);


  }

    public void processFormData(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        String s = "asn.common.customer.webui.ODOrgCreateCO.processFormData";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        if(flag)
            oapagecontext.writeDiagnostics(s, "Begin", 2);
        oapagecontext.putParameter("HzPuiAddressEvent", "CREATE");
        if(flag)
            oapagecontext.writeDiagnostics(s, "End", 2);
    }

        
    private void callHardAssignApi(OAPageContext pageContext, OAWebBean webBean)
         {
     String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgCreateCO.callHardAssignApi";
         boolean flag = pageContext.isLoggingEnabled(2);
         if(flag)
             pageContext.writeDiagnostics(s, "Begin", 2);
        String HzPuiCreatedPartySiteId = (String)pageContext.getTransactionTransientValue("HzPuiCreatedPartySiteId");
        pageContext.writeDiagnostics(s, "HzPuiCreatedPartySiteId : " +HzPuiCreatedPartySiteId , 2);
        String resourceId = pageContext.getParameter("GeneralRepId");
        String roleId = pageContext.getParameter("GenRoleId");
        String groupId = pageContext.getParameter("GenGroupId");
        pageContext.writeDiagnostics(s, "GeneralRepId : " +resourceId , 2);
        pageContext.writeDiagnostics(s, "GenRoleId : " +roleId , 2);
        pageContext.writeDiagnostics(s, "GenGroupId : " +groupId , 2);
        StringBuffer hardQry = new StringBuffer();

         hardQry.append("BEGIN XX_JTF_RS_NAMED_ACC_TERR_PUB.Create_Territory(p_api_version_number => :1");
         hardQry.append(",p_status => :2");
         hardQry.append(",p_source_terr_id => :3,p_resource_id => :4,p_role_id => :5");
         hardQry.append(",p_group_id  => :6 ,p_entity_type => :7,p_entity_id => :8");
         hardQry.append(",p_source_entity_id => :9,p_terr_asgnmnt_source     => :10");
         hardQry.append(",x_error_code => :11,x_error_message => :12); end;");        
        String appDtsQry = hardQry.toString();
        pageContext.writeDiagnostics(s, "appDtsQry : " +appDtsQry , 2);
        OADBTransaction transaction =  pageContext.getApplicationModule(webBean).getOADBTransaction();
        Connection objConn = transaction.getJdbcConnection();
        //OracleCallableStatement objStmt = null;
        CallableStatement objStmt = null;
        String errCode = null;
        String errMsg = null;
         try{
             pageContext.writeDiagnostics(s, "B4 Call" , 2);
             objStmt = objConn.prepareCall(appDtsQry);
             objStmt.setDouble(1,1.0);
             objStmt.setString(2,"A");
             objStmt.setInt(3,-1);
             objStmt.setInt(4,Integer.parseInt(resourceId));
             objStmt.setInt(5,Integer.parseInt(roleId));
             objStmt.setInt(6,Integer.parseInt(groupId));
             objStmt.setString(7,"PARTY_SITE");
             objStmt.setInt(8,Integer.parseInt(HzPuiCreatedPartySiteId));
             objStmt.setInt(9,-1);
             objStmt.setString(10,"Territory Override");
             objStmt.registerOutParameter(11,Types.VARCHAR);
             objStmt.registerOutParameter(12,Types.VARCHAR);
             
             objStmt.execute();
             pageContext.writeDiagnostics(s, "After Execute" , 2);

             errCode = objStmt.getString(11);
             errMsg = objStmt.getString(12);
             pageContext.writeDiagnostics(s, "errCode:"+errCode , 2);
             pageContext.writeDiagnostics(s, "errMsg:"+errMsg , 2);
             doCommit(pageContext);
             if(!"S".equals(errCode)){
                 throw new OAException("The system has encountered an unexpected error during Hard Assignment:"+errMsg);
             }
         }
         catch(SQLException e){
             pageContext.writeDiagnostics(s, "Error during Execute:"+e.getMessage()+e.getStackTrace() , 2);
             e.printStackTrace(System.err);
             throw new OAException("The system has encountered an unexpected error during Hard Assignment. The signature could have changed.");
         }
         finally{
           try {
               if(objStmt!=null) 
                   objStmt.close();
               }
           catch(SQLException e){
               e.printStackTrace(System.err);
           }
         }
        if(flag)
             pageContext.writeDiagnostics(s, "End", 2);

         }
         
    private void callAutoNamedApi(OAPageContext pageContext, OAWebBean webBean)
         {
     String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgCreateCO.callAutoNamedApi";
         boolean flag = pageContext.isLoggingEnabled(2);
         if(flag)
             pageContext.writeDiagnostics(s, "Begin", 2);
        String HzPuiCreatedPartySiteId = (String)pageContext.getTransactionTransientValue("HzPuiCreatedPartySiteId");
        pageContext.writeDiagnostics(s, "HzPuiCreatedPartySiteId : " +HzPuiCreatedPartySiteId , 2);
        String resourceId = pageContext.getParameter("WinnerResId");
        String roleId = pageContext.getParameter("WinnerRoleId");
        String groupId = pageContext.getParameter("WinnerGroupId");
        String fullAccFlag = pageContext.getParameter("WinnerAccFlag");
        pageContext.writeDiagnostics(s, "WinnerResId : " +resourceId , 2);
        pageContext.writeDiagnostics(s, "WinnerRoleId : " +roleId , 2);
        pageContext.writeDiagnostics(s, "WinnerGroupId : " +groupId , 2);
        pageContext.writeDiagnostics(s, "WinnerAccFlag : " +fullAccFlag , 2);
        StringBuffer hardQry = new StringBuffer();

         hardQry.append("BEGIN XX_JTF_RS_NAMED_ACC_TERR_PUB.Create_Territory(p_api_version_number => :1");
         hardQry.append(",p_status => :2, p_full_access_flag => :3");
         hardQry.append(",p_source_terr_id => :4,p_resource_id => :5,p_role_id => :6");
         hardQry.append(",p_group_id  => :7 ,p_entity_type => :8,p_entity_id => :9");
         hardQry.append(",p_source_entity_id => :10,p_terr_asgnmnt_source     => :11");
         hardQry.append(",x_error_code => :12,x_error_message => :13); end;");        
        String appDtsQry = hardQry.toString();
        pageContext.writeDiagnostics(s, "appDtsQry : " +appDtsQry , 2);
        OADBTransaction transaction =  pageContext.getApplicationModule(webBean).getOADBTransaction();
        Connection objConn = transaction.getJdbcConnection();
        //OracleCallableStatement objStmt = null;
        CallableStatement objStmt = null;
        String errCode = null;
        String errMsg = null;
         try{
             pageContext.writeDiagnostics(s, "B4 Call" , 2);
             objStmt = objConn.prepareCall(appDtsQry);
             objStmt.setDouble(1,1.0);
             objStmt.setString(2,"A");
             objStmt.setString(3,fullAccFlag);
             objStmt.setInt(4,-1);
             objStmt.setInt(5,Integer.parseInt(resourceId));
             objStmt.setInt(6,Integer.parseInt(roleId));
             objStmt.setInt(7,Integer.parseInt(groupId));
             objStmt.setString(8,"PARTY_SITE");
             objStmt.setInt(9,Integer.parseInt(HzPuiCreatedPartySiteId));
             objStmt.setInt(10,-1);
             objStmt.setString(11,"Rule Based Assignment - Online");
             objStmt.registerOutParameter(12,Types.VARCHAR);
             objStmt.registerOutParameter(13,Types.VARCHAR);
             
             objStmt.execute();
             pageContext.writeDiagnostics(s, "After Execute" , 2);

             errCode = objStmt.getString(12);
             errMsg = objStmt.getString(13);
             pageContext.writeDiagnostics(s, "errCode:"+errCode , 2);
             pageContext.writeDiagnostics(s, "errMsg:"+errMsg , 2);
             doCommit(pageContext);
             if(!"S".equals(errCode)){
                 throw new OAException("The system has encountered an unexpected error during Autonamed Assignment:"+errMsg);
             }
         }
         catch(SQLException e){
             pageContext.writeDiagnostics(s, "Error during Execute:"+e.getMessage()+e.getStackTrace() , 2);
             e.printStackTrace(System.err);
             throw new OAException("The system has encountered an unexpected error during Autonamed Assignment. The signature could have changed.");
         }
         finally{
           try {
               if(objStmt!=null) 
                   objStmt.close();
               }
           catch(SQLException e){
               e.printStackTrace(System.err);
           }
         }
        if(flag)
             pageContext.writeDiagnostics(s, "End", 2);

         }
         
    private void getWinnerResource(OAPageContext pageContext, OAWebBean webBean,String sourceButton)
         {
     String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODOrgCreateCO.getWinnerResource";
         boolean flag = pageContext.isLoggingEnabled(2);
         if(flag)
             pageContext.writeDiagnostics(s, "Begin", 2);
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
		
        String postalCode = null;
        Number wcw = new Number(0);
        String sicCode = null;
        OAApplicationModule nestedAM = (OAApplicationModule)am.findApplicationModule("HzPuiAddressAM");
        OAViewObjectImpl nestedVO = (OAViewObjectImpl)nestedAM.findViewObject("HzPuiLocationVO");
        if(nestedVO!=null){
            Row row = nestedVO.getCurrentRow();
            if(row!=null){
            postalCode = row.getAttribute("PostalCode").toString();
            }
        }
        sicCode = pageContext.getParameter("SicCodeHidden");
        wcw = new Number(Integer.parseInt(pageContext.getParameter("ODWcw")));
        StringBuffer hardQry = new StringBuffer();

         hardQry.append("begin XX_TM_TERRITORY_UTIL_PKG.TERR_RULE_BASED_WINNER_LOOKUP(p_org_type => :1,p_od_wcw => :2,p_sic_code => :3,");
         hardQry.append("p_postal_code => :4,p_division    => :5,");
         hardQry.append("p_nam_terr_id=> :6,p_resource_id => :7,p_role_id => :8,p_group_id => :9,p_full_access_flag => :10, x_return_status => :11,x_message_data => :12); end;");        
        String appDtsQry = hardQry.toString();
        pageContext.writeDiagnostics(s, "appDtsQry : " +appDtsQry , 2);
        OADBTransaction transaction =  pageContext.getApplicationModule(webBean).getOADBTransaction();
        Connection objConn = transaction.getJdbcConnection();
        CallableStatement objStmt = null;
        String errCode = null;
        String errMsg = null;
        Number namedTerrId = new Number(0);
        Number resourceId = new Number(0);
        Number roleId = new Number(0);
        Number groupId = new Number(0);
        String fullAccFlag = null;
         try{
             pageContext.writeDiagnostics(s, "B4 Call" , 2);
             objStmt = objConn.prepareCall(appDtsQry);
             objStmt.setString(1,"PROSPECT");
             objStmt.setInt(2,wcw.intValue());
             objStmt.setString(3,sicCode);
             objStmt.setString(4,postalCode);
             objStmt.setString(5,"BSD");
             objStmt.registerOutParameter(6,Types.NUMERIC);
             objStmt.registerOutParameter(7,Types.NUMERIC);
             objStmt.registerOutParameter(8,Types.NUMERIC);
             objStmt.registerOutParameter(9,Types.NUMERIC);
             objStmt.registerOutParameter(10,Types.VARCHAR);
             objStmt.registerOutParameter(11,Types.VARCHAR);
             objStmt.registerOutParameter(12,Types.VARCHAR);
             
             objStmt.execute();
             pageContext.writeDiagnostics(s, "After Execute" , 2);

             errCode = objStmt.getString(11);
             errMsg = objStmt.getString(12);
             pageContext.writeDiagnostics(s, "errCode:"+errCode , 2);
             pageContext.writeDiagnostics(s, "errMsg:"+errMsg , 2);
             if(!"S".equals(errCode)){    
                 throw new OAException("The system has encountered an unexpected error while retrieving Rule-based Winners:"+errMsg);
             }
             else{
                 namedTerrId = new Number(objStmt.getInt(6));
                 resourceId = new Number(objStmt.getInt(7));
                 roleId = new Number(objStmt.getInt(8));
                 groupId = new Number(objStmt.getInt(9));
                 fullAccFlag = objStmt.getString(10);
                 /*
                 resourceId = new Number(100023067);
                 roleId = new Number(10024);
                 groupId = new Number(100000420);
                 fullAccFlag = "Y";
                 */
                 
                 int loggedInResId = this.getLoginResourceId(pageContext,webBean);
                 pageContext.putParameter("WinnerResId",resourceId);
                 pageContext.putParameter("WinnerRoleId",roleId);
                 pageContext.putParameter("WinnerGroupId",groupId);
                 pageContext.putParameter("WinnerAccFlag",fullAccFlag);
                 if(resourceId.compareTo(loggedInResId)!=0){
                 pageContext.writeDiagnostics(s, "Reached Dialog Page" , 2);
                 String resName = this.getResourceName(pageContext,webBean,resourceId.intValue());
                 HashMap params = new HashMap();
                 params.put("WarningResName",resName);
                 params.put("HideAll","Y");
                 params.put("ShowAll","N");
                 params.put("WinnerResId",resourceId);
                 params.put("WinnerRoleId",roleId);
                 params.put("WinnerGroupId",groupId);
                 params.put("WinnerAccFlag",fullAccFlag);
                 params.put("ODASNSourceButtonClicked",sourceButton);
                 params.put("RedoNotes","N");
				 
                 pageContext.forwardImmediatelyToCurrentPage(params,true,OAWebBeanConstants.ADD_BREAD_CRUMB_SAVE);
                 /*
                 MessageToken[] msgToken = {new MessageToken("RESOURCE_NAME",resName)};
                 OAException custmainMessage = new OAException(pageContext.getMessage("XXCRM","XX_CRM_PROSPECT_NO_ACCESS",msgToken));
                 OADialogPage custdialogPage = new OADialogPage(OAException.WARNING,custmainMessage,null,"","");

                 custdialogPage.setOkButtonItemName("ProspCrteYesButton");
                 custdialogPage.setOkButtonToPost(true);
                 custdialogPage.setNoButtonToPost(true);
                 custdialogPage.setPostToCallingPage(true);
                 custdialogPage.setRetainAMValue(true);

                 String yes = pageContext.getMessage("FND", "FND_DIALOG_YES", null);
                 String no = pageContext.getMessage("FND", "FND_DIALOG_NO", null);

                 custdialogPage.setOkButtonLabel(yes);
                 custdialogPage.setNoButtonLabel(no);

                 pageContext.redirectToDialogPage(custdialogPage);  
                 */
                 }
                 else{
                     pageContext.writeDiagnostics(s, "Did not Reach Dialog Page" , 2);   
                 }
             }
             //doCommit(pageContext);
         }
         catch(SQLException e){
             pageContext.writeDiagnostics(s, "Error during Execute:"+e.getMessage()+e.getStackTrace() , 2);
               e.printStackTrace(System.err);
             throw new OAException("The system has encountered an unexpected error while retrieving Rule-based Winners. The signature could have changed.");
         }
         finally{
           try {
               if(objStmt!=null) 
                   objStmt.close();
               }
           catch(SQLException e){
               e.printStackTrace(System.err);
           }
         }
        if(flag)
             pageContext.writeDiagnostics(s, "End", 2);
         }
         
    private String getResourceName(OAPageContext pageContext,OAWebBean webBean,int resourceId)
    {
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      Connection objConn = am.getOADBTransaction().getJdbcConnection();
      StringBuffer objBuff = new StringBuffer();
      String resourceName = null;
      objBuff.append("  SELECT RESOURCE_NAME FROM JTF_RS_RESOURCE_EXTNS_VL WHERE RESOURCE_ID=:1");
      String sqlQuery = objBuff.toString();
      PreparedStatement objStmt = null;
      ResultSet objRs = null;
      try
      {
        objStmt = objConn.prepareStatement(sqlQuery);
        objStmt.setInt(1,resourceId);
        objRs = objStmt.executeQuery();
        while(objRs.next())
          resourceName = objRs.getString(1);
      } catch (SQLException sqle)
      {
        //test if we should log errors
          pageContext.writeDiagnostics
            ("ODOrgCreateCO : getResourceName",
             "Unable to get Resource Name from Resource ID",
             2);
          pageContext.writeDiagnostics
            ("ODOrgCreateCO : getResourceName",
             "Returned error message is:" + sqle.getMessage(),
             2);
        resourceName = null;
      } // end of try-catch
      finally
      {
        try
        {
          objRs.close();
          objStmt.close();
        } catch (SQLException sqle)
        {
          pageContext.writeDiagnostics
            ("ODOrgCreateCO : getResourceName",
             "Unable to close statement",
             2);
        } // end of try-catch
      } // end of finally

      return resourceName;
    }

    private int getLoginResourceId(OAPageContext pageContext,OAWebBean webBean)
    {
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      Connection objConn = am.getOADBTransaction().getJdbcConnection();
      StringBuffer objBuff = new StringBuffer();
      int resourceId = -1;
      objBuff.append("  SELECT R.RESOURCE_ID FROM JTF_RS_RESOURCE_EXTNS R WHERE R.USER_ID = FND_GLOBAL.USER_ID");
      String sqlQuery = objBuff.toString();
      PreparedStatement objStmt = null;
      ResultSet objRs = null;
      try
      {
        objStmt = objConn.prepareStatement(sqlQuery);
        objRs = objStmt.executeQuery();
        while(objRs.next())
          resourceId = objRs.getInt(1);
      } catch (SQLException sqle)
      {
        //test if we should log errors
          pageContext.writeDiagnostics
            ("ODOrgCreateCO : getLoginResourceId",
             "Unable to get Resource ID from Logged in User ID",
             2);
          pageContext.writeDiagnostics
            ("ODOrgCreateCO : getLoginResourceId",
             "Returned error message is:" + sqle.getMessage(),
             2);
        resourceId = -1;
      } // end of try-catch
      finally
      {
        try
        {
          objRs.close();
          objStmt.close();
        } catch (SQLException sqle)
        {
          pageContext.writeDiagnostics
            ("ODOrgCreateCO : getLoginResourceId",
             "Unable to close statement",
             2);
        } // end of try-catch
      } // end of finally

      return resourceId;
    }

}
