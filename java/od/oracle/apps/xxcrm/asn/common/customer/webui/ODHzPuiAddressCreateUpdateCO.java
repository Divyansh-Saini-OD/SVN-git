/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODHzPuiAddressCreateUpdateCO.java                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Controller Object for the Address Create Update Region.                |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Customization on the Create Contact Page             |
 |         and Create Update Contact Address Page. It initialises the        |
 |         Party Site pop list and handles the Change Site event             |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    27-Sep-2007 Jasmine Sujithra   Created                                 |
 |    15-Oct-2008 Mohan Kalyanasundaram Modified for clearing sitelist cache |
 |    21-Oct-2016 Hanmanth Jogiraju  Retrofitted for 12.2.5 (Def 39738)      |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAException;
import java.io.Serializable;
import oracle.apps.fnd.common.MessageToken;
import java.util.Hashtable;
import oracle.apps.ar.hz.components.util.webui.HzPuiWebuiUtil;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.beans.OADescriptiveFlexBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.jbo.common.Diagnostic;

import oracle.apps.fnd.framework.OAFwkConstants;


/**
  * Controller for ...
  */
public class ODHzPuiAddressCreateUpdateCO extends OAControllerImpl {
    public static final String RCS_ID = "$Header: /home/cvs/repository/Office_Depot/SRC/CRM/E1307_SiteLevel_Attributes_ASN/3.\040Source\040Code\040&\040Install\040Files/E1307D_SiteLevel_Attributes_(LeadOpp_CreateUpdate)/ODHzPuiAddressCreateUpdateCO.java,v 1.2 2007/10/11 20:59:39 jsujithra Exp $";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    /**
    * Layout and page setup logic for a region.
    * @param pageContext the current OA page context
    * @param webBean the web bean corresponding to the region
    */
    public void processRequest(OAPageContext pageContext, OAWebBean webBean) 
    {
        final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODHzPuiAddressCreateUpdateCO.processRequest";

        boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
        boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        
        if (isProcLogEnabled) 
        {
          pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
        }
        

        super.processRequest(pageContext, webBean);
//Mohan disabling the cache for sitelist item so the requery can take place 10/15/2008
        OAMessageChoiceBean omcBean = (OAMessageChoiceBean)webBean.findChildRecursive("siteList");
        if (omcBean != null) 
        {
          omcBean.setPickListCacheEnabled(false);
        }


        /* Get the Customer and Site Id */
        OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
        String partyIdTemp = pageContext.getParameter("ASNReqFrmCustId");
        pageContext.putParameter("HzPuiAddressPartyId", partyIdTemp);

        String partySiteIdConst = pageContext.getParameter("ASNReqFrmSiteId");
        pageContext.writeDiagnostics(METHOD_NAME, "ASNReqFrmSiteId : "+partySiteIdConst , OAFwkConstants.PROCEDURE);
        if (partySiteIdConst == null) 
        {
          partySiteIdConst = (String)pageContext.getTransactionValue("ASNReqFrmSiteIdTXN");
          pageContext.writeDiagnostics(METHOD_NAME, "ASNReqFrmSiteIdTXN : "+partySiteIdConst , OAFwkConstants.PROCEDURE); 
        }
        
        if (partySiteIdConst == null) 
        {
            Serializable aserializable[] = { partyIdTemp };
            partySiteIdConst = 
                    (String)am.invokeMethod("getPartySiteId", aserializable);
            pageContext.writeDiagnostics(METHOD_NAME, "Party Site Id from am.getPartySiteId  : "+partySiteIdConst , OAFwkConstants.PROCEDURE); 
            //pageContext.putParameter("ASNReqFrmSiteId","259784");
            pageContext.putParameter("ASNReqFrmSiteId", partySiteIdConst);
             pageContext.putTransactionValue("ASNReqFrmSiteIdTXN", 
                                                 partySiteIdConst);
        }

        /* Initialize the Party Site Pop List */
        OAViewObject partysitelistvo = 
            (OAViewObject)am.findViewObject("ODPartySiteListVO");

        if (partysitelistvo == null) 
        {
            MessageToken[] token = 
            { new MessageToken("OBJECT_NAME", "ODPartySiteListVO") };
            throw new OAException("AK", "FWK_TBX_OBJECT_NOT_FOUND", token);
        }

        Serializable[] params = { partyIdTemp };
        partysitelistvo.invokeMethod("initQuery", params);

        //Address Suggestion   
        am.invokeMethod("initSuggestionTransient");

        Boolean renderFlag = Boolean.FALSE;
        Serializable[] suggParams = { renderFlag };
        Class[] classSuggParams = { renderFlag.getClass() };
        am.invokeMethod("setSuggestionTransValue", suggParams, 
                        classSuggParams);
        String formEvent = pageContext.getParameter(FLEX_FORM_EVENT);        

        if (formEvent == null) 
        {
           
            //Check whether a partyId is passed to the page
            //if yes then query the record for update or view
            if ("UPDATE".equals(pageContext.getParameter("HzPuiAddressEvent"))) 
            {
                
                String locationId = pageContext.getParameter("HzPuiAddressLocationId");
                String partySiteId =  pageContext.getParameter("HzPuiAddressPartySiteId");

                if (locationId == null || locationId.trim() == null) 
                {
                    Serializable[] parameters = { partySiteId };
                    locationId =  (String)am.invokeMethod("getLocationIdFromPartySite", 
                                                    parameters);
                }
                //All parameters passed using invokeMethod() must be serializable.
                Serializable[] parameters = { locationId, partySiteId };

                am.invokeMethod("initQuery", parameters);
            } else if ("CREATE".equals(pageContext.getParameter("HzPuiAddressEvent")))
            //If the partyId is not passed, assume it is a Create
            {
                
                pageContext.putTransactionValue("HzPuiAddressEvent", "CREATE");
                Diagnostic.println("Calling create");
                pageContext.putTransactionTransientValue("HzPuiTrnSiteUseType", pageContext.getParameter("HzPuiSiteUseType"));
                Diagnostic.println("HzPuiAddressExist =" + pageContext.getParameter("HzPuiAddressExist"));
                if (!"YES".equals(pageContext.getParameter("HzPuiAddressExist"))) 
                {
                    String partyId = pageContext.getParameter("HzPuiAddressPartyId");

                    // set default value to view object
                    String[] attributelist =  (String[])am.invokeMethod("getAttributeList");
                    Hashtable attributeHash =  HzPuiWebuiUtil.getDefaultAttrValue(pageContext, attributelist);

                    //All parameters passed using invokeMethod() must be serializable.
                    try 
                    {
                        Serializable[] parameters = { partyId, attributeHash };
                        Class[] classParams = 
                        { Class.forName("java.lang.String"), 
                          Class.forName("java.util.Hashtable") };
                        String[] IDs = 
                            (String[])am.invokeMethod("createAddress", 
                                                      parameters, classParams);
                        if (IDs.length > 1) 
                        {
                            pageContext.putTransactionTransientValue("HzPuiCreatedLocationId", 
                                                                     IDs[0]);
                            pageContext.putTransactionTransientValue("HzPuiCreatedPartySiteId", 
                                                                     IDs[1]);
                        }
                       
                    } catch (ClassNotFoundException e) 
                    {
                        Diagnostic.println("HzPuiAddressCreateUpdateCO: Vector class not found");
                    }

                }

                // set address create flag
                OAFormValueBean hiddenField = (OAFormValueBean)createWebBean(pageContext, HIDDEN_BEAN, 
                                                   null, "HzPuiAddressExist");
                hiddenField.setText(pageContext, "YES");
                webBean.addIndexedChild(hiddenField);
            }

            /* Added Code for Custom Create Contact */

            String locationIdTemp = pageContext.getParameter("HzPuiAddressLocationId");
            String partySiteIdTemp = pageContext.getParameter("ASNReqFrmSiteId");
           
            pageContext.writeDiagnostics(METHOD_NAME, "2nd ASNReqFrmSiteId : "+partySiteIdTemp , OAFwkConstants.PROCEDURE); 
            if (partySiteIdTemp == null) 
            {
               partySiteIdTemp = (String)pageContext.getTransactionValue("ASNReqFrmSiteIdTXN");
               pageContext.writeDiagnostics(METHOD_NAME, "2nd ASNReqFrmSiteIdTXN : "+partySiteIdTemp , OAFwkConstants.PROCEDURE); 
            }
            else
            {
               pageContext.putTransactionValue("ASNReqFrmSiteIdTXN", 
                                                 partySiteIdTemp);
            }
            
            if (partySiteIdTemp == null) 
            {
                pageContext.writeDiagnostics(METHOD_NAME, "partySiteIdTemp is null " , OAFwkConstants.PROCEDURE); 
                OAMessageChoiceBean oamessagechoicebean = (OAMessageChoiceBean)webBean.findChildRecursive("siteList");
                if (oamessagechoicebean != null) 
                {
                   
                    if (oamessagechoicebean.getSelectionValue(pageContext) == null) 
                    {
                       pageContext.writeDiagnostics(METHOD_NAME, "Setting selected Index to 0 " , OAFwkConstants.PROCEDURE); 
                        oamessagechoicebean.setSelectedIndex(0);
                        partySiteIdTemp = oamessagechoicebean.getSelectionValue(pageContext);
                        pageContext.putParameter("ASNReqFrmSiteId",   partySiteIdTemp);
                    } else 
                    {
                       
                        partySiteIdTemp = oamessagechoicebean.getSelectionValue(pageContext);
                        pageContext.putParameter("ASNReqFrmSiteId",  partySiteIdTemp);
                        pageContext.putTransactionValue("ASNReqFrmSiteIdTXN", 
                                                 partySiteIdTemp);
                    }
                }
            }
            else
            {
                pageContext.putParameter("ASNReqFrmSiteId",  partySiteIdTemp);
                pageContext.putTransactionValue("ASNReqFrmSiteIdTXN", partySiteIdTemp);              
            }

             OAMessageChoiceBean oamessagechoicebean = (OAMessageChoiceBean)webBean.findChildRecursive("siteList");
             if (oamessagechoicebean != null) 
             {
                   
                    if (oamessagechoicebean.getSelectionValue(pageContext) == null) 
                    {
                          Serializable aserializable[] = { partySiteIdTemp };
                          String index =  (String)am.invokeMethod("getPartySiteIndex", aserializable);
                          pageContext.writeDiagnostics(METHOD_NAME, "Setting selected Index to :  "+index , OAFwkConstants.PROCEDURE); 
                          int rowindex = Integer.parseInt(index);
                          oamessagechoicebean.setSelectedIndex(rowindex);                          
                    }
             }

            pageContext.putParameter("HzPuiAddressPartySiteId",  partySiteIdTemp);


            // if (locationIdTemp == null || locationIdTemp.trim() == null )
            //{
            Serializable[] parametersLocTemp = { partySiteIdTemp };
            locationIdTemp = (String)am.invokeMethod("getLocationIdFromPartySite", parametersLocTemp);
            pageContext.putParameter("HzPuiAddressLocationId", locationIdTemp);
            pageContext.putTransactionValue("HzPuiAddressLocationIdTXN", 
                                            locationIdTemp);
            pageContext.putTransactionValue("ASNTxnSelLocationId", 
                                            locationIdTemp);

            //}
           
            //All parameters passed using invokeMethod() must be serializable.
            Serializable[] parametersTemp = { locationIdTemp, partySiteIdTemp };

            am.invokeMethod("initQuery", parametersTemp);
            //       OAFormValueBean hiddenFieldTemp = (OAFormValueBean)createWebBean(pageContext, HIDDEN_BEAN, null, "HzPuiAddressExist");
            // hiddenFieldTemp.setText(pageContext, "YES");
            //webBean.addIndexedChild(hiddenFieldTemp);  

            //End of Custom Code
        }


        OAMessageChoiceBean choiceBean = 
            (OAMessageChoiceBean)webBean.findIndexedChildRecursive("hzPartySiteStatus");
        if (choiceBean != null)
            choiceBean.setRequiredIcon("no");

        // when user create first address , make primaryFlag field non-updatable
        String partyId = pageContext.getParameter("HzPuiAddressPartyId");
        String partySiteId = pageContext.getParameter("HzPuiAddressPartySiteId");
        Serializable[] params2 = { partyId, partySiteId };
        Integer rowCount = (Integer)am.invokeMethod("checkRecExist", params2);
        int rCount = rowCount.intValue();     
       
        Diagnostic.println("Inside HzPuiAddressCreateUpdateCO.processRequest(). checkRecExist returned - " + 
                           rowCount);
        if (rCount == 0) 
        {
            Diagnostic.println("Disabling the primary checkBox and Status Poplist");
            OAMessageCheckBoxBean primaryCheckBoxBean = 
                (OAMessageCheckBoxBean)webBean.findChildRecursive("hzPartySitePrimary");
            if (primaryCheckBoxBean != null) 
            {
                primaryCheckBoxBean.setChecked(true);
                primaryCheckBoxBean.setAttributeValue(OAWebBeanConstants.DISABLED_ATTR, 
                                                      Boolean.TRUE);
            }

            if (choiceBean != null) 
            {
                choiceBean.setDisabled(true);
            }
        }

        OATableBean tableBean =  (OATableBean)webBean.findIndexedChildRecursive("hzPartySiteUseTable");

        if (tableBean != null) 
        {
            // enable row insertion
            tableBean.setInsertable(false);
            tableBean.setAutoInsertion(false);
            // prepare table properties     
            tableBean.prepareForRendering(pageContext);
        }

        //resetAddressStyle
        //pageContext.getPageLayoutBean().prepareForRendering(pageContext);
         String flow = "nonHZ";
         Serializable[] serialzedParameters={flow};
         String style = (String)am.invokeMethod("resetAddressStyle",serialzedParameters);
        
        //flex merge with parents
        OADescriptiveFlexBean dffBn = (OADescriptiveFlexBean)webBean.findIndexedChildRecursive("HzAddressStyleFlex");
        if (dffBn != null) 
        {
            //dffBn.processFlex(pageContext);
            //if(dffBn.getIndexedChildCount()>0)
            //{
            //String id = dffBn.getIndexedChild(0).getNodeID();
            //String name = dffBn.getIndexedChild(0).getLocalName();
            //}
           
            dffBn.setContextListRendered(false);
            dffBn.mergeSegmentsWithParent(pageContext);
        }
        
        Diagnostic.println("Inside HzPuiAddressCreateUpdateCO - process request (-)");
        if (isStatLogEnabled) 
        {
          pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.STATEMENT);
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
        final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODHzPuiAddressCreateUpdateCO.processFormRequest";

        boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
        boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        
        if (isProcLogEnabled) 
        {
          pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
        }
        

        super.processFormRequest(pageContext, webBean);

        OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
        String pageevent = pageContext.getParameter("event");
        String locationIdValue = "";
        String partySiteIdValue = "";

        if ("CHANGE_SITE_PPR".equals(pageevent)) {
            pageContext.writeDiagnostics(METHOD_NAME, "Within CHANGE_SITE_PPR", 
                                         2);
            OAMessageChoiceBean oamessagechoicebean = 
                (OAMessageChoiceBean)webBean.findChildRecursive("siteList");
            if (oamessagechoicebean != null) {
                partySiteIdValue = 
                        oamessagechoicebean.getSelectionValue(pageContext);
                pageContext.writeDiagnostics(METHOD_NAME, "Site Value is :", 
                                             2);
                pageContext.writeDiagnostics(METHOD_NAME, partySiteIdValue, 2);


                pageContext.putParameter("ASNReqFrmSiteId", partySiteIdValue);
                 pageContext.putTransactionValue("ASNReqFrmSiteIdTXN", 
                                                 partySiteIdValue);
                Serializable[] parameters = { partySiteIdValue };
                locationIdValue = 
                        (String)am.invokeMethod("getLocationIdFromPartySite", 
                                                parameters);
                pageContext.putParameter("HzPuiAddressLocationId", 
                                         locationIdValue);
                pageContext.putTransactionValue("HzPuiAddressLocationIdTXN", 
                                                locationIdValue);
                pageContext.putTransactionValue("ASNTxnSelLocationId", 
                                                locationIdValue);

            }
          
            //All parameters passed using invokeMethod() must be serializable.
            Serializable[] parameters = { locationIdValue, partySiteIdValue };

            am.invokeMethod("initQuery", parameters);


            //resetAddressStyle
            //pageContext.getPageLayoutBean().prepareForRendering(pageContext);
            String flow = "nonHZ";
            Serializable[] serialzedParameters={flow};            
            String style = (String)am.invokeMethod("resetAddressStyle",serialzedParameters);
         
            pageContext.setForwardURLToCurrentPage(null, true, pageContext.getBreadCrumbValue(), (byte)0);

            //flex merge with parents
            OADescriptiveFlexBean dffBn = 
                (OADescriptiveFlexBean)webBean.findIndexedChildRecursive("HzAddressStyleFlex");
            if (dffBn != null) {
                //dffBn.processFlex(pageContext);
                //if(dffBn.getIndexedChildCount()>0)
                //{
                //String id = dffBn.getIndexedChild(0).getNodeID();
                //String name = dffBn.getIndexedChild(0).getLocalName();
                //}
                
                dffBn.setContextListRendered(false);
                dffBn.mergeSegmentsWithParent(pageContext);
            } 


        }
       
        String locationId = locationIdValue;
        String partySiteId = partySiteIdValue;

        /* // get location id from server utility if exist
     Vector locationStuff = (Vector)am.invokeMethod("getLocations", null);
     String locationId = null;
     if ( locationStuff != null )
     {
       HashMap locationRec = (HashMap)locationStuff.elementAt(0);
       Number locationId_n = (Number) locationRec.get("LocationId");
       locationId = locationId_n.toString();
       if ("CREATE".equals(pageContext.getTransactionValue("HzPuiAddressEvent")))
       {
         //OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);
         Serializable[] paramSiteUseType =  { (String)pageContext.getTransactionTransientValue("HzPuiTrnSiteUseType") };
         am.invokeMethod("changePartySiteEntityState", paramSiteUseType);
       }
     }

     // get party site id from server utility if exist
     Vector partySiteStuff = (Vector)am.invokeMethod("getPartySites", null);
     String partySiteId = null;
     if ( partySiteStuff != null )
     {
       HashMap partySiteRec = (HashMap)partySiteStuff.elementAt(0);
       Number partySiteId_n = (Number) partySiteRec.get("PartySiteId");
       partySiteId = partySiteId_n.toString();
     }
 */
        if ("YES".equals(pageContext.getParameter("HzPuiAddressExist"))) {
            Diagnostic.println("locaiton , PartySite vo already been created ");
            pageContext.putParameter("HzPuiAddressExist", "YES");
            //pageContext.putParameter("HzPuiLocationId", locationId);                
            //pageContext.putParameter("HzPuiPartySiteId", partySiteId);        
        }

        OATableBean tableBean =  (OATableBean)webBean.findIndexedChildRecursive("hzPartySiteUseTable");

        if ((tableBean != null) && 
            (tableBean.getName(pageContext).equals(pageContext.getParameter(SOURCE_PARAM))) && 
            (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))) 
        {
              am.invokeMethod("addPartySiteUses");
        } else if (pageContext.getParameter("HzPuiPartySiteUseDeleteYes") !=  null) 
        {
            String partySiteUseId =   pageContext.getParameter("HzPuiPartySiteUseId");

            Diagnostic.println("get HzPartySiteUseDelete event , partySiteUseId = " +  partySiteUseId);

            if (partySiteUseId != null && partySiteUseId.trim() != null) {

                Serializable[] parameters = { partySiteUseId };
                am.invokeMethod("deletePartySiteUses", parameters);

                // get the site use type meaning from database
                String hzPuiPartySiteUseType =  pageContext.getParameter("HzPuiPartySiteUseType");

                String siteUseTypeMeaning = "";
                if (hzPuiPartySiteUseType != null && 
                    hzPuiPartySiteUseType.trim().length() > 0) {
                    Serializable[] parameters2 = { hzPuiPartySiteUseType };
                    siteUseTypeMeaning =  (String)am.invokeMethod("getSiteUseMeanFromType",parameters2);
                }

                MessageToken[] tokens = 
                { new MessageToken("DISPLAY_VALUE", siteUseTypeMeaning) };
                OAException message = 
                    new OAException("AR", "HZ_PUI_REMOVE_CONFIRMATION", tokens, 
                                    OAException.CONFIRMATION, null);
                pageContext.putDialogMessage(message);

            }
        }
        if ("HzPartySiteUseDelete".equals(pageContext.getParameter("HzPuiPsuEvent"))) {
            // The user has clicked a "Delete" icon so we want to display a "Warning"
            // dialog asking if she really wants to delete the PO.  Note that we 
            // configure the dialog so that pressing the "Yes" button submits to 
            // this page so we can handle the action in this processFormRequest( ) method.
            String hzPuiPartySiteUseId = pageContext.getParameter("HzPuiPartySiteUseId");
            String hzPuiPartySiteUseType = pageContext.getParameter("HzPuiPartySiteUseType");

            // when use want to remove the row they just add, the site use type is not in 
            // form submit value, need get this from VO
            if (hzPuiPartySiteUseType == null || 
                hzPuiPartySiteUseType.length() == 0 || 
                hzPuiPartySiteUseType.trim() == null) {
                Serializable[] parameters = { hzPuiPartySiteUseId };
                hzPuiPartySiteUseType = (String)am.invokeMethod("getSiteUseTypeFromVO", 
                                                parameters);
            }

            // get the site use type meaning from database, set it to the token

            Serializable[] parameters2 = { hzPuiPartySiteUseType };
            String siteUseTypeMeaning =  (String)am.invokeMethod("getSiteUseMeanFromType", parameters2);
            MessageToken[] tokens = 
            { new MessageToken("SITE_USE_TYPE", siteUseTypeMeaning) };
            OAException mainMessage =  new OAException("AR", "HZ_PUI_REMOVE_SITE_USE_WARNING", 
                                tokens);

            // Note that even though we're going to make our Yes/No buttons submit a
            // form, we still need some non-null value in the constructor's Yes/No  
            // URL parameters for the buttons to render, so we just pass empty 
            // Strings for this.

            OADialogPage dialogPage = 
                new OADialogPage(OAException.WARNING, mainMessage, null, "", 
                                 "");

            // Always use Message Dictionary for any Strings you want to display.

            String yes = pageContext.getMessage("FND", "FND_DIALOG_YES", null);
            String no = pageContext.getMessage("FND", "FND_DIALOG_NO", null);

            // We set this value so the code that handles this button press is 
            // descriptive.

            dialogPage.setOkButtonItemName("HzPuiPartySiteUseDeleteYes");

            // The following configures the Yes/No buttons to be submit buttons,
            // and makes sure that we handle the form submit in the originating
            // page (the "Purchase Orders" summary) so we can handle the "Yes"
            // button selection in this controller.

            dialogPage.setOkButtonToPost(true);
            dialogPage.setNoButtonToPost(true);
            dialogPage.setPostToCallingPage(true);

            // Now set our Yes/No labels instead of the default OK/Cancel.

            dialogPage.setOkButtonLabel(yes);
            dialogPage.setNoButtonLabel(no);

            // We need to keep hold of the poHeaderId, and the OADialogPage gives us a
            // convenient means of doing this.  Note that the use of the Hashtable is
            // really more appropriate for passing multiple parameters, but we've used
            // it here for illustration purposes.  See the OADialogPage javadoc for an
            // alternative when dealing with a single parameter.

            java.util.Hashtable formParams = new java.util.Hashtable(9);
            //     Hashtable formParams = getPageContextParameter(pageContext);     
            formParams.put("HzPuiPartySiteUseId", hzPuiPartySiteUseId);
            formParams.put("HzPuiAddressExist", "YES");
            //formParams.put(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX+"Country" , pageContext.getParameter(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX +"Country"));           
            //formParams.put(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX+"CountryName" , pageContext.getParameter(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX +"CountryName"));                
            //pageContext.putParameter("HzPuiLocationId", locationId);                
            //pageContext.putParameter("HzPuiPartySiteId", partySiteId);        

            if (hzPuiPartySiteUseType != null && 
                hzPuiPartySiteUseType.trim().length() > 0)
                formParams.put("HzPuiPartySiteUseType", hzPuiPartySiteUseType);
            else
                return;

            formParams.put("HzPuiResubmitFlag", "YES");

            if (pageContext.getParameter("HzPuiOrgCompositeExist") != null)
                formParams.put("HzPuiOrgCompositeExist", pageContext.getParameter("HzPuiOrgCompositeExist"));

            if (pageContext.getParameter("HzPuiPersonCompositeExist") != null)
                formParams.put("HzPuiPersonCompositeExist",pageContext.getParameter("HzPuiPersonCompositeExist"));

            dialogPage.setFormParameters(formParams);

            //Following code is added to fix the problem of loosing context 
            //when rendering a Dialog page
            String sRegionRefName = 
                (String)pageContext.getParameter("HzPuiAddressRegionRef");
            if (sRegionRefName != null && sRegionRefName.length() > 0)
                dialogPage.setHeaderNestedRegionRefName(sRegionRefName);
            else
                dialogPage.setReuseMenu(false);

            pageContext.redirectToDialogPage(dialogPage);

        } else if ("HzPuiPopulateSuggestion".equals(pageContext.getParameter(EVENT_PARAM))) 
        {
            OAMessageChoiceBean addrSuggPoplist = 
                (OAMessageChoiceBean)webBean.findChildRecursive("addrSuggestionPoplist");
            String key = addrSuggPoplist.getSelectionValue(pageContext);
            if (key != null) {
                Serializable[] paramPopKey = { key };
                am.invokeMethod("populateAddressSuggestion", paramPopKey);
            } // retain the AM
                pageContext.setForwardURLToCurrentPage(null, true, 
                                                       pageContext.getBreadCrumbValue(), 
                                                       IGNORE_MESSAGES);
        } else if ("HzPuiAddressPrimaryCheck".equals(pageContext.getParameter(EVENT_PARAM))) 
        {
            // Catch the fireAction event from identifying address falg
            Diagnostic.println("HZPUI: EVENT_PARAM = HzPuiAddressPrimaryCheck");

            // The user has checked the identifying flag checkbox, we want to display
            // an alert so that she can acknowlege to uncheck the current primary.
            String primaryFlag = 
                (String)am.invokeMethod("getPartySiteVOPrimaryFlagValue");
            if ("Y".equals(primaryFlag)) 
            {
                String primaryAddress = (String)(am.invokeMethod("getPrimaryAddress"));

                if (primaryAddress != null &&  primaryAddress.trim().length() > 0) 
                {
                    // configure the dialog so that pressing the "Yes" button submits to
                    // this page so we can handle the action in this processFormRequest( ) method.
                    MessageToken[] messageTokens = { new MessageToken("ADDRESS", primaryAddress) };
                    OAException mainMessage = new OAException("AR", "HZ_PUI_SET_PRIMARYADDR_WARNING", 
                                        messageTokens);

                    // Note that even though we're going to make our Yes/No buttons submit a
                    // form, we still need some non-null value in the constructor's Yes/No
                    // URL parameters for the buttons to render, so we just pass empty
                    // Strings for this.

                    OADialogPage dialogPage = new OADialogPage(OAException.WARNING, mainMessage, 
                                         null, "", "");

                    // Always use Message Dictionary for any Strings you want to display.

                    String yes = pageContext.getMessage("FND", "FND_DIALOG_YES", null);
                    String no = pageContext.getMessage("FND", "FND_DIALOG_NO", null);

                    // We set this value so the code that handles this button press is
                    // descriptive.

                    dialogPage.setOkButtonItemName("HzPuiSetPrimaryAddressYesButton");
                    dialogPage.setNoButtonItemName("HzPuiSetPrimaryAddressNoButton");

                    // The following configures the Yes/No buttons to be submit buttons,
                    // and makes sure that we handle the form submit in the originating
                    // page so we can handle the "Yes" button selection in this controller.

                    dialogPage.setOkButtonToPost(true);
                    dialogPage.setNoButtonToPost(true);
                    dialogPage.setPostToCallingPage(true);

                    // Now set our Yes/No labels instead of the default OK/Cancel.

                    dialogPage.setOkButtonLabel(yes);
                    dialogPage.setNoButtonLabel(no);

                    java.util.Hashtable formParams = 
                        new java.util.Hashtable(9);

                    formParams.put("HzPuiAddressExist", "YES");
                    //formParams.put(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX+"Country" , pageContext.getParameter(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX +"Country"));           
                    //formParams.put(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX+"CountryName" , pageContext.getParameter(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX +"CountryName"));                
                    //pageContext.putParameter("HzPuiLocationId", locationId);                
                    //pageContext.putParameter("HzPuiPartySiteId", partySiteId);           

                    formParams.put("HzPuiResubmitFlag", "YES");

                    if (pageContext.getParameter("HzPuiOrgCompositeExist") !=null)
                        formParams.put("HzPuiOrgCompositeExist",  pageContext.getParameter("HzPuiOrgCompositeExist"));

                    if (pageContext.getParameter("HzPuiPersonCompositeExist") != null)
                        formParams.put("HzPuiPersonCompositeExist", pageContext.getParameter("HzPuiPersonCompositeExist"));

                    dialogPage.setFormParameters(formParams);
                    //Following code is added to fix the problem of loosing context 
                    //when rendering a Dialog page
                    String sRegionRefName = (String)pageContext.getParameter("HzPuiAddressRegionRef");
                    if (sRegionRefName != null && sRegionRefName.length() > 0)
                        dialogPage.setHeaderNestedRegionRefName(sRegionRefName);
                    else
                        dialogPage.setReuseMenu(false);
                    pageContext.redirectToDialogPage(dialogPage);
                }
            }
        } else if (pageContext.getParameter("HzPuiSetPrimaryAddressNoButton") != null) {
            Diagnostic.println("HZPUI: HzPuiSetPrimaryAddressNoButton is not null");

            am.invokeMethod("unsetPartySiteVOPrimaryFlag");
        } else if (pageContext.isLovEvent() && "HzFlexCountry".equals(pageContext.getLovInputSourceId()))
        //else if(pageContext.getParameter("HzCountryGoButton")!=null)
        { // retain the AM
                pageContext.setForwardURLToCurrentPage(null, true, 
                                                       pageContext.getBreadCrumbValue(), 
                                                       IGNORE_MESSAGES);
        }

      if (isStatLogEnabled) 
      {
        pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.STATEMENT);
      }
    }

}
