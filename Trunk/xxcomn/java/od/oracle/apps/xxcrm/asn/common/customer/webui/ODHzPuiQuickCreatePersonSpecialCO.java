/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import java.io.Serializable;
import java.util.Hashtable;
import oracle.jbo.common.Diagnostic;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.jbo.Row;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.beans.OADescriptiveFlexBean;


/**
 * Controller for ...
 */
public class ODHzPuiQuickCreatePersonSpecialCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    /**
       * Layout and page setup logic for AK region.
       * @param pageContext the current OA page context
       * @param webBean the web bean corresponding to the AK region
       */
      public void processRequest(OAPageContext pageContext, OAWebBean webBean)
      {
        super.processRequest(pageContext, webBean);

        Hashtable params = new Hashtable();
           
        String sHzPuiRelationshipCode = pageContext.getParameter("HzPuiRelationshipCode");
        String sHzPuiRelationshipType = pageContext.getParameter("HzPuiRelationshipType");

        if (sHzPuiRelationshipCode == null)
          sHzPuiRelationshipCode = (String) pageContext.getTransactionValue("HzPuiRelationshipCode");

        if (sHzPuiRelationshipType == null)
          sHzPuiRelationshipType = (String) pageContext.getTransactionValue("HzPuiRelationshipType");

        if(sHzPuiRelationshipCode != null && sHzPuiRelationshipCode.length() > 0 )
        {
                  pageContext.putTransactionValue("HzPuiRelationshipCode", sHzPuiRelationshipCode);
                  params.put("HzPuiRelationshipCode", sHzPuiRelationshipCode) ;
                  if ( sHzPuiRelationshipType == null || sHzPuiRelationshipType.length() == 0 )
                  {
                     pageContext.putDialogMessage(
                             new OAException("AR",
                                     "HZ_PUI_INVALID_PARAMETERS",
                                     null,
                                     OAException.ERROR,
                                     null));
                     return;
                  }
                  else
                  {
                      params.put("HzPuiRelationshipType", sHzPuiRelationshipType) ;
                      pageContext.putTransactionValue("HzPuiRelationshipType", sHzPuiRelationshipType);

                      //If relationship code is passed in then hide the Role Drop Down
                      OAMessageChoiceBean roleLovBean = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("RoleChoice");
                      if ( roleLovBean != null )
                      {
                           roleLovBean.setRendered(false);
                      }

                      OASubmitButtonBean goButton = (OASubmitButtonBean) webBean.findIndexedChildRecursive("HzPuiRoleSelected");
                      if ( goButton != null )
                      {
                           goButton.setRendered(false); 
                      }
                  }     

        }

        //Get the generate Party Number profile, based on this profile
        //set the partynumber property.
        String sPartyProfile = (String) pageContext.getProfile("HZ_GENERATE_PARTY_NUMBER");
        Diagnostic.println("Inside HzPersonProfileCO. Generate Party Number - " + sPartyProfile );
        if ( sPartyProfile != null && sPartyProfile.equals("Y") )
        {
            //In the update mode make the PartyNumber a non updateable column
            OAWebBean regIdMssgTextBean = webBean.findIndexedChildRecursive("PartyNumber");
            if ( regIdMssgTextBean != null )
            {
                  ((OAWebBean) regIdMssgTextBean).setRendered(false); 
            }

            //In the update mode make the PartyNumber a non updateable column
            OAWebBean regIdOrgMssgTextBean = webBean.findIndexedChildRecursive("OrgPartyNumber");
            if ( regIdOrgMssgTextBean != null )
            {
                  ((OAWebBean) regIdOrgMssgTextBean).setRendered(false); 
            }
        }

        String sHzPuiPartyIndicator     = pageContext.getParameter("HzPuiPartyIndicator");
        String sHzPuiPerProfileObjectId = pageContext.getParameter("HzPuiPerProfileObjectId");

        Diagnostic.println("Inside HzPuiQuickCreatePersonSpecialCO. CREATE HzPuiPartyIndicator -" + sHzPuiPartyIndicator);

           // If only person is created, do not render org and job title fields
        if( "PERSON".equals(sHzPuiPartyIndicator) )
        {
                params.put("HzPuiPartyIndicator", sHzPuiPartyIndicator) ;
                Diagnostic.println("Inside HzPuiQuickCreatePersonSpecialCO.HzPuiPartyIndicator -" + sHzPuiPartyIndicator);
                OAMessageTextInputBean jobTitleMssgBean = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("JobTitle");
                if ( jobTitleMssgBean != null)
                {
                     jobTitleMssgBean.setRendered(false);
                }     

                OAMessageTextInputBean orgMssgTextBean = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("Organization");
                if ( orgMssgTextBean != null )
                {
                      orgMssgTextBean.setRendered(false);
                }                 

                OAWebBean regIdOrgMssgTextBean = webBean.findIndexedChildRecursive("OrgPartyNumber");
                if ( regIdOrgMssgTextBean != null )
                {
                  ((OAWebBean) regIdOrgMssgTextBean).setRendered(false); 
                }
            
                OAMessageChoiceBean roleLovBean = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("RoleChoice");
                if ( roleLovBean != null )
                {
                      roleLovBean.setRendered(false);
                }

                OASubmitButtonBean goButton = (OASubmitButtonBean) webBean.findIndexedChildRecursive("HzPuiRoleSelected");
                if ( goButton != null )
                {
                      goButton.setRendered(false); 
                }
        }
           
        //If the Object Id is passed in then hide the Oarganization Field
        if ( sHzPuiPerProfileObjectId != null && sHzPuiPerProfileObjectId.length() > 0)
        {            
                 params.put("HzPuiPerProfileObjectId", sHzPuiPerProfileObjectId) ; 
                 pageContext.putTransactionValue("HzPuiPerProfileObjectId", "sHzPuiPerProfileObjectId");
                 
                 OAMessageTextInputBean orgMssgTextBean = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("Organization");
                 if ( orgMssgTextBean != null )
                 {
                      orgMssgTextBean.setRendered(false);
                 }     

                 if( "PER_TO_PER".equals(sHzPuiPartyIndicator) )
                 {
                      params.put("HzPuiPartyIndicator", sHzPuiPartyIndicator) ;
                      Diagnostic.println("Inside HzPuiQuickCreatePersonSpecialCO.HzPuiPartyIndicator -" + sHzPuiPartyIndicator);
                      OAMessageTextInputBean jobTitleMssgBean = (OAMessageTextInputBean) webBean.findIndexedChildRecursive("JobTitle");
                      if ( jobTitleMssgBean != null)
                      {
                           jobTitleMssgBean.setRendered(false);
                      }     
                 }
        }

        String formEvent = pageContext.getParameter(FLEX_FORM_EVENT);

        if (formEvent == null)
        {
        if ("CREATE".equals(pageContext.getParameter("HzPuiPerProfileEvent")))
        {
           Diagnostic.println("Inside HzPuiQuickCreatePersonCO");

           OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);

           String [] attributelist = (String [] )am.invokeMethod("getAttributeList");
           Hashtable attributeHash = getDefaultAttrValue(pageContext, attributelist);
           
           
           try {
                 Serializable[] parameters =  {params, attributeHash};
                 Class[] classParams = {Class.forName("java.util.Hashtable"), Class.forName("java.util.Hashtable")};  
           
                 Diagnostic.println("Inside HzPuiQuickCreatePersonCO.createPersonProfile()");
                 String partyId  = (String)am.invokeMethod("createPersonProfileSpecial", parameters, classParams);
                 pageContext.putParameter("HzPuiAddressPartyId", partyId);
                 pageContext.putParameter("HzPuiOwnerTableId", partyId);
           }
           catch (ClassNotFoundException e)
           {
              Diagnostic.println("HzPuiQuickCreatePersonCO: class not found");
           }        
        }
        }

        // merge flex with parent's layout
        OADescriptiveFlexBean dffBn = (OADescriptiveFlexBean)webBean.findIndexedChildRecursive("personFlex");
        if(dffBn != null)
        {
          dffBn.mergeSegmentsWithParent(pageContext);
        }    
        //bug 5392171
        OADescriptiveFlexBean dffBnOrg = (OADescriptiveFlexBean)webBean.findIndexedChildRecursive("organizationFlex");
        if(dffBnOrg != null)
        {
          dffBnOrg.mergeSegmentsWithParent(pageContext);
        }    
      }

      public void processFormData(OAPageContext pageContext, OAWebBean webBean)
      {
        super.processFormData(pageContext, webBean);

        //Only do the refresh the first time. After the first pass, 'HzPuiPartyCreationMode' will have the
        //value relationship if the user is trying to create a relationship
        String sPartyCreationMode = (String)pageContext.getTransactionValue("HzPuiPartyCreationMode");
        OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);


        Diagnostic.println("Inside HzPuiQuickCreatePersonSpecialCO processFormData. sPartyCreationMode = " + sPartyCreationMode);
        if (  ( pageContext.getParameter("Organization") != null &&
                pageContext.getParameter("Organization").length() > 0) &&
              ( ! "RELATIONSHIP".equals( sPartyCreationMode )) )
        {
             //If the reltionship is not the ine the transaction 
             //then set it the first time.
             if ( pageContext.getParameter("Organization") != null &&
                  pageContext.getParameter("Organization").length() > 0)
             {
                 pageContext.putTransactionValue("HzPuiPartyCreationMode", "RELATIONSHIP");
             }
             Diagnostic.println("Inside HzPuiQuickCreatePersonSpecialCO processFormData. ORGANIZATION EXIST"); 
             am.invokeMethod("refreshWithFK");
        }

        // Set the person EO to dirty 

        OAViewObject vo = (OAViewObject) am.findViewObject("HzPuiPerQuickCreateProfileVO");
        OAViewObject emailVO = (OAViewObject) am.findViewObject("HzPuiPerQuickCreateEmailVO");
        OAViewObject phVO = (OAViewObject) am.findViewObject("HzPuiContactPointPhoneVO");  
        Row perRow = vo.getCurrentRow();
        Row emailRow = emailVO.getCurrentRow();
        Row phRow = phVO.getCurrentRow();
        
        String goFurther = "N";
        
        /*if(perRow.getAttribute("PersonFirstName")!=null || 
           perRow.getAttribute("PersonMiddleName")!=null ||
           perRow.getAttribute("PersonLastName")!=null ||
           emailRow.getAttribute("EmailAddress")!=null ||
           phRow.getAttribute("PhoneCountryCode")!=null ||
           phRow.getAttribute("PhoneAreaCode")!=null ||
           phRow.getAttribute("PhoneNumber")!=null ||
           phRow.getAttribute("PhoneExtension")!=null ){
               goFurther = "Y";
           }
        */
         String perFName = pageContext.getParameter("PersonFirstName");
         if("".equals(perFName))
             perFName = null;
         String perLName = pageContext.getParameter("PersonLastName");
           if("".equals(perLName))
               perLName = null;
         String perMName = pageContext.getParameter("PersonMiddleName");
           if("".equals(perMName))
               perMName = null;
         String email = pageContext.getParameter("EmailAddress");
           if("".equals(email))
               email = null; 
         String phCountCode = pageContext.getParameter("PerPhoneCountryCode");
           if("".equals(phCountCode))
               phCountCode = null; 
         String phAreaCode1 = pageContext.getParameter("PhoneAreaCode1");
           if("".equals(phAreaCode1))
               phAreaCode1 = null;         
         String phNum1 = pageContext.getParameter("PhoneNumber1");
           if("".equals(phNum1))
               phNum1 = null;        
         String phExt = pageContext.getParameter("PhoneExtension");
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
                  goFurther = "Y";
              }
        pageContext.putParameter("goFurther",goFurther);
        pageContext.writeDiagnostics("SMJ","SMJ goFurther:"+goFurther,OAFwkConstants.STATEMENT);
        //SMJ Code 
        if("Y".equals(goFurther)){
        Row row = vo.getCurrentRow();
        if (row != null)
          row.setNewRowState(Row.STATUS_NEW);    

        // Set the relationship EO to dirty 

        String sHzPuiPerProfileObjectId = pageContext.getParameter("HzPuiPerProfileObjectId");

        if ( sHzPuiPerProfileObjectId == null )
        {
          sHzPuiPerProfileObjectId = (String) pageContext.getTransactionValue("HzPuiPerProfileObjectId");
        }

        if ( sHzPuiPerProfileObjectId != null && sHzPuiPerProfileObjectId.length() > 0)
        {
          vo = (OAViewObject) am.findViewObject("HzPuiQuickCreateOrgCnctCpuiVO");
            
          row = vo.getCurrentRow();
          if (row != null)
            row.setNewRowState(Row.STATUS_NEW);  
        }
        }
      }

      /**
       * Procedure to handle form submissions for form elements in
       * AK region.
       * @param pageContext the current OA page context
       * @param webBean the web bean corresponding to the AK region
       */
      public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
      {
        super.processFormRequest(pageContext, webBean);
        String goFurther = pageContext.getParameter("goFurther");
        pageContext.writeDiagnostics("SMJ","SMJ goFurther:"+goFurther,OAFwkConstants.STATEMENT);
        //Check whether the user has clicked on the Role Lov
        if( pageContext.getParameter("HzPuiRoleSelected") != null )
        {
            String sRoleChoice = (String) pageContext.getParameter("RoleChoice");
            Diagnostic.println("Inside HzPuiQuickCreatePersonSpecialCO processFormRequest. RoleChoice - " + sRoleChoice); 
            if ( sRoleChoice != null )
            {
                 OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
                 Serializable[] parameters =  {sRoleChoice};
                 am.invokeMethod("refreshRelationShipType", parameters);
            }
        }
        
      }

      public Hashtable getDefaultAttrValue(OAPageContext pageContext, String [] attributeList)
      {
         Hashtable h = new Hashtable();
         for (int i=0; i < attributeList.length ; i++) 
         {
            String attrValue = pageContext.getParameter("HzPui"+attributeList[i]);
            Diagnostic.println("pageContext.getParameter(paramName) -" + attributeList[i] );    
            if (attrValue != null && attrValue.trim().length() >0 )
                h.put( attributeList[i], attrValue);
         }    
         return h;
      }



}
