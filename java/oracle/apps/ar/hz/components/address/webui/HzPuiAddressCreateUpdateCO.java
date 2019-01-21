/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |    08-JUL-2009    Ajai Singh      Bug 7620414 : Added code to handle the  |
 |                                   duplicacy of site use.                  |
 |    23-APR-2010    avjha           Bug #9480872 : Used setFlexContextCode() instead of|
 |                                   row.setAttribute("AddressStyle",addrStyle)         |
 |    07-JUL-2011    avjha           Bug #12553387 : Used resetAddressStyle() and commented redirection|
 |                                   incase of country change to avoid cursor movement on top of the page after refresh.|
|    30-NOV-2011     avjha          Bug #13445839 : Removed changes for bug #12553387 | 
|                                   and allowed redirection to happen incase of country change. | 
 |06-Dec-2011   swaggarw         Bug 13103848:Added code for real time address validation 
 |21-JUN-2012   swaggarw         Bug 13644244:Verify/revert button should not display in case of read only view 
 |29-JULY-2013     naresh         Bug  16898486 - retrieved parameter from POS code |
 +===========================================================================*/
 /*===========================================================================+
  |     OD Changes                                                            |
  +===========================================================================+
  |  HISTORY                                                                  |
  |    18-Oct-2016    H Jogiraju      Retrofitted for 12.2.5                  |
  +===========================================================================*/
package oracle.apps.ar.hz.components.address.webui;

import com.sun.java.util.collections.HashMap;

import java.io.Serializable;

import java.util.Hashtable;
import java.util.Vector;

import oracle.apps.ar.hz.components.base.webui.HzPuiBaseCO;
import oracle.apps.ar.hz.components.util.webui.HzPuiWebuiUtil;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OADescriptiveFlexBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;

import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAMessageComponentLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.OAFwkConstants;

import oracle.jbo.common.Diagnostic;
import oracle.jbo.domain.Number;

/**
 * Controller for ...
 */
public class HzPuiAddressCreateUpdateCO extends HzPuiBaseCO
{
  public static final String RCS_ID="$Header: HzPuiAddressCreateUpdateCO.java 120.49.12020000.3 2013/07/29 10:39:46 nbpujari ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.hz.components.address.webui");

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
Diagnostic.println("HzPuiAddressCreateUpdateCO.processRequest(ENTER)");
	/* Added against Bug#6787851*/
	if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
		pageContext.writeDiagnostics(this,"HzPuiAddressCreateUpdateCO.processRequest(ENTER)",OAFwkConstants.STATEMENT);
  super.processRequest(pageContext, webBean);
     String pHzPuiOrgCompositeExist=pageContext.getParameter("HzPuiOrgCompositeExist");
    String pHzPuiPersonCompositeExist=pageContext.getParameter("HzPuiPersonCompositeExist");
    String pHzPuiAddressEvent=pageContext.getParameter("HzPuiAddressEvent");
    String pHzPuiSiteUseType=pageContext.getParameter("HzPuiSiteUseType");
    String pHzPuiAddressExist=pageContext.getParameter("HzPuiAddressExist");
    String pHzPuiAddressLocationId=pageContext.getParameter("HzPuiAddressLocationId");
    String pHzPuiAddressPartySiteId=pageContext.getParameter("HzPuiAddressPartySiteId");
    String pHzPuiAddressPartyId=pageContext.getParameter("HzPuiAddressPartyId");
    String pHzPuiHidePartySiteUse=pageContext.getParameter("HzPuiHidePartySiteUse");
    String pHzPuiComposite=(String)pageContext.getTransactionTransientValue("HzPuiComposite");
    // the below  parameters will not be null when the flow is from nonHZ, in this case POS
    String posEVENT=pageContext.getParameter("PosEvent");
    String posHzPuiAddress1=pageContext.getParameter("HzPuiAddress1");
    String posHzPuiCountryName=pageContext.getParameter("HzPuiCountryName");
Diagnostic.println("pHzPuiOrgCompositeExist="+pHzPuiOrgCompositeExist);
Diagnostic.println("pHzPuiPersonCompositeExist="+pHzPuiPersonCompositeExist);
Diagnostic.println("pHzPuiAddressEvent="+pHzPuiAddressEvent);
Diagnostic.println("pHzPuiSiteUseType="+pHzPuiSiteUseType);
Diagnostic.println("pHzPuiAddressExist="+pHzPuiAddressExist);
Diagnostic.println("pHzPuiAddressLocationId="+pHzPuiAddressLocationId);
Diagnostic.println("pHzPuiAddressPartySiteId="+pHzPuiAddressPartySiteId);
Diagnostic.println("pHzPuiAddressPartyId="+pHzPuiAddressPartyId);
Diagnostic.println("pHzPuiHidePartySiteUse="+pHzPuiHidePartySiteUse);
Diagnostic.println("pHzPuiComposite="+pHzPuiComposite);
Diagnostic.println("posEVENT=> "+posEVENT);
Diagnostic.println("posHzPuiAddress1=> "+posHzPuiAddress1);
Diagnostic.println("posHzPuiCountryName=> "+posHzPuiCountryName);
	/* Added against Bug#6787851*/
	if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)){
		pageContext.writeDiagnostics(this,"pHzPuiOrgCompositeExist="+pHzPuiOrgCompositeExist,OAFwkConstants.STATEMENT);
		pageContext.writeDiagnostics(this,"pHzPuiPersonCompositeExist="+pHzPuiPersonCompositeExist,OAFwkConstants.STATEMENT);
		pageContext.writeDiagnostics(this,"pHzPuiAddressEvent="+pHzPuiAddressEvent,OAFwkConstants.STATEMENT);
		pageContext.writeDiagnostics(this,"pHzPuiSiteUseType="+pHzPuiSiteUseType,OAFwkConstants.STATEMENT);
		pageContext.writeDiagnostics(this,"pHzPuiAddressExist="+pHzPuiAddressExist,OAFwkConstants.STATEMENT);
		pageContext.writeDiagnostics(this,"pHzPuiAddressLocationId="+pHzPuiAddressLocationId,OAFwkConstants.STATEMENT);
		pageContext.writeDiagnostics(this,"pHzPuiAddressPartySiteId="+pHzPuiAddressPartySiteId,OAFwkConstants.STATEMENT);
		pageContext.writeDiagnostics(this,"pHzPuiAddressPartyId="+pHzPuiAddressPartyId,OAFwkConstants.STATEMENT);
		pageContext.writeDiagnostics(this,"pHzPuiHidePartySiteUse="+pHzPuiHidePartySiteUse,OAFwkConstants.STATEMENT);
		pageContext.writeDiagnostics(this,"pHzPuiComposite="+pHzPuiComposite,OAFwkConstants.STATEMENT);

	}
    //for renterant code into this CO
    if(isEmpty(pHzPuiAddressEvent))
    {
      pHzPuiAddressEvent=(String)pageContext.getTransactionValue("HzPuiAddressEvent");
Diagnostic.println(getLogStr("from txn pHzPuiAddressEvent",pHzPuiAddressEvent));
	/* Added against Bug#6787851*/
	if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
		pageContext.writeDiagnostics(this,getLogStr("from txn pHzPuiAddressEvent",pHzPuiAddressEvent),OAFwkConstants.STATEMENT);


    }//if isEmpty(HzPuiAddressEvent)


    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);

    //Address Suggestion
    am.invokeMethod("initSuggestionTransient");

    Boolean renderFlag =  Boolean.FALSE;
    Serializable[] suggParams =  { renderFlag };
    Class[] classSuggParams = { renderFlag.getClass()};
    am.invokeMethod("setSuggestionTransValue",suggParams,classSuggParams);

    String formEvent = pageContext.getParameter(FLEX_FORM_EVENT);
Diagnostic.println(getLogStr("formEvent",formEvent));
	/* Added against Bug#6787851*/
	if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
		pageContext.writeDiagnostics(this,getLogStr("formEvent",formEvent),OAFwkConstants.STATEMENT);

    if (formEvent == null)
    {
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
		pageContext.writeDiagnostics(this,"formEvent == null",OAFwkConstants.STATEMENT);

      String voName = "HzPuiLocationVO";
      Serializable[] voNameParams =  { voName };

      String isVoPreparedForExecution = (String)am.invokeMethod("isVoPreparedForExecution", voNameParams);
Diagnostic.println(getLogStr("isVoPreparedForExecution",isVoPreparedForExecution));
	/* Added against Bug#6787851*/
	if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
		pageContext.writeDiagnostics(this,getLogStr("isVoPreparedForExecution",isVoPreparedForExecution),OAFwkConstants.STATEMENT);

      //bug #6938905 - Generally isVoPreparedForExecution() is false as AM state is not retained when visiting/revisiting AddressCreateUpdate Region. Conditional statement has been modified to take care of the case when AM is retained. In such case Uptaking team needs to pass Parameter: HzPuiCheckForVOExecutionInBackButtonNav with Value: 'Y'.
      if(!"Y".equals(isVoPreparedForExecution) || (pageContext.getParameter("HzPuiCheckForVOExecutionInBackButtonNav") != null && "Y".equals(pageContext.getParameter("HzPuiCheckForVOExecutionInBackButtonNav")))) 
       // filter out the case of vo already isPreparedForExecution
       {
Diagnostic.println(getLogStr("pageContext.isBackNavigationFired(false)",String.valueOf(pageContext.isBackNavigationFired(false))));
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,getLogStr("pageContext.isBackNavigationFired(false)",String.valueOf(pageContext.isBackNavigationFired(false))),OAFwkConstants.STATEMENT);

         if(pageContext.isBackNavigationFired(false)
         && "CREATE".equals(pHzPuiAddressEvent))
          // BackButton clicked to create page,
          // and the record already commited.
          {
Diagnostic.println("calling pageContext.putDialogMessage(FND_STALE_DATA_ERROR)");
			/* Added against Bug#6787851*/
			if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
				pageContext.writeDiagnostics(this,"calling pageContext.putDialogMessage(FND_STALE_DATA_ERROR)",OAFwkConstants.STATEMENT);

              OAException msg = new OAException("FND_STALE_DATA_ERROR",OAException.ERROR);
              pageContext.putDialogMessage(msg);
          }
          else
          //back button wasnt fired in create flow
          {

            //Check whether a partyId is passed to the page
            //if yes then query the record for update or view
            if("UPDATE".equals(pHzPuiAddressEvent)
            || "READ_ONLY".equals(pHzPuiAddressEvent))
            {
Diagnostic.println("UPDATE or READ_ONLY equals pHzPuiAddressEvent");
			/* Added against Bug#6787851*/
			if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
				pageContext.writeDiagnostics(this,"UPDATE or READ_ONLY equals pHzPuiAddressEvent",OAFwkConstants.STATEMENT);

                pageContext.putTransactionValue("HzPuiAddressEvent", pHzPuiAddressEvent);

                if(pHzPuiAddressLocationId == null
                || "".equals(pHzPuiAddressLocationId))
                {
                  Serializable[] parameters =  { pHzPuiAddressPartySiteId };
                  pHzPuiAddressLocationId = (String) am.invokeMethod("getLocationIdFromPartySite", parameters);
Diagnostic.println("getLocationIdFromPartySite returned pHzPuiAddressLocationId="+pHzPuiAddressLocationId);
				/* Added against Bug#6787851*/
				if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
					pageContext.writeDiagnostics(this,"getLocationIdFromPartySite returned pHzPuiAddressLocationId="+pHzPuiAddressLocationId,OAFwkConstants.STATEMENT);

                }

                Serializable[] parameters =  { pHzPuiAddressLocationId, pHzPuiAddressPartySiteId };
                  am.invokeMethod("initQuery", parameters);
            }
            else
            if("CREATE".equals(pHzPuiAddressEvent))
            //If the partyId is not passed, assume it is a Create
            {
Diagnostic.println("CREATE equals pHzPuiAddressEvent");
				/* Added against Bug#6787851*/
				if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
					pageContext.writeDiagnostics(this,"CREATE equals pHzPuiAddressEvent",OAFwkConstants.STATEMENT);

              pageContext.putTransactionValue("HzPuiAddressEvent", "CREATE");
              pageContext.putTransactionTransientValue("HzPuiTrnSiteUseType",pHzPuiSiteUseType);
              if ( !"YES".equals(pHzPuiAddressExist))
              {
Diagnostic.println("!YES.equals(pHzPuiAddressExist)");
				/* Added against Bug#6787851*/
				if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
					pageContext.writeDiagnostics(this,"!YES.equals(pHzPuiAddressExist)",OAFwkConstants.STATEMENT);


                // set default value to view object
                String [] attributelist = (String [] )am.invokeMethod("getAttributeList");
                Hashtable attributeHash = HzPuiWebuiUtil.getDefaultAttrValue(pageContext, attributelist);

                //All parameters passed using invokeMethod() must be serializable.
                try {
                  Serializable[] parameters =  { pHzPuiAddressPartyId, attributeHash };
                  Class[] classParams = { Class.forName("java.lang.String"), Class.forName("java.util.Hashtable")};
                  String [] IDs = (String [] )am.invokeMethod("createAddress", parameters, classParams);
Diagnostic.println(getLogStr("IDs.length",String.valueOf(IDs.length)));
					/* Added against Bug#6787851*/
					if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
						pageContext.writeDiagnostics(this,getLogStr("IDs.length",String.valueOf(IDs.length)),OAFwkConstants.STATEMENT);

                  if(IDs.length >1)
                  {
Diagnostic.println(getLogStr("IDs[0]",IDs[0]));
Diagnostic.println(getLogStr("IDs[1]",IDs[1]));
					/* Added against Bug#6787851*/
					if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT)){
						pageContext.writeDiagnostics(this,getLogStr("IDs[0]",IDs[0]),OAFwkConstants.STATEMENT);
						pageContext.writeDiagnostics(this,getLogStr("IDs[1]",IDs[1]),OAFwkConstants.STATEMENT);
					}
                    pageContext.putTransactionTransientValue("HzPuiCreatedLocationId",IDs[0]);
                    pageContext.putTransactionTransientValue("HzPuiCreatedPartySiteId",IDs[1]);
                  }
                }
                catch (ClassNotFoundException e)
                {
                  Diagnostic.println("HzPuiAddressCreateUpdateCO: Vector class not found");
					/* Added against Bug#6787851*/
					if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
						pageContext.writeDiagnostics(this,"HzPuiAddressCreateUpdateCO: Vector class not found",OAFwkConstants.STATEMENT);

                }//trycatch

              }//if !"YES".equals(pHzPuiAddressExist)

              // set address create flag
              OAFormValueBean hiddenField = (OAFormValueBean)createWebBean(pageContext, HIDDEN_BEAN, null, "HzPuiAddressExist");
              hiddenField.setText(pageContext, "YES");
              webBean.addIndexedChild(hiddenField);
            }//if "CREATE".equals(pHzPuiAddressEvent)

          }//if isBackNavigationFired() && "CREATE".equals(pHzPuiAddressEvent)
       }//if !"Y".equals(isVOPreparedForExecution)
    }//if (formEvent == null)

    OAMessageChoiceBean choiceBean = (OAMessageChoiceBean)webBean.findIndexedChildRecursive("hzPartySiteStatus");
    if( choiceBean != null)
        choiceBean.setRequiredIcon("no");

      // when user create first address , make primaryFlag field non-updatable
    Serializable[] params2 =  { pHzPuiAddressPartyId, pHzPuiAddressPartySiteId };
    Integer rowCount = (Integer)am.invokeMethod("checkRecExist", params2);
Diagnostic.println(getLogStr("rowCount",rowCount));
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,getLogStr("rowCount",rowCount),OAFwkConstants.STATEMENT);

    int rCount = rowCount.intValue();
    if ( rCount == 0  )
    {
Diagnostic.println("Disabling the primary checkBox and Status Poplist");
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"Disabling the primary checkBox and Status Poplist",OAFwkConstants.STATEMENT);

       OAMessageCheckBoxBean primaryCheckBoxBean = (OAMessageCheckBoxBean)webBean.findChildRecursive("hzPartySitePrimary");
       if ( primaryCheckBoxBean != null )
       {
          primaryCheckBoxBean.setChecked(true);
          primaryCheckBoxBean.setAttributeValue(OAWebBeanConstants.DISABLED_ATTR, Boolean.TRUE);
       }
    }//if

    OATableBean tableBean =
       (OATableBean) webBean.findIndexedChildRecursive("HzPartySiteUseTable");
    if (tableBean != null)
    {
      if("Y".equals(pHzPuiHidePartySiteUse))
      {
Diagnostic.println("attempting to psUseBn.setRendered(false)");
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"attempting to psUseBn.setRendered(false)",OAFwkConstants.STATEMENT);

        OAWebBean psUseBn = webBean.findIndexedChildRecursive("PSUseRN");
        if(psUseBn!=null) psUseBn.setRendered(false);
      }else
      {
Diagnostic.println("setting HzPartySiteUseTable properties");
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"setting HzPartySiteUseTable properties",OAFwkConstants.STATEMENT);

        // enable row insertion
        tableBean.setInsertable(true);
        tableBean.setAutoInsertion(false);
        // prepare table properties
        tableBean.prepareForRendering(pageContext);
      }
    }

    pageContext.getRootApplicationModule().getOADBTransaction().putTransientValue("HzPuiAddressEvent", pHzPuiAddressEvent);
      /*
      Based on the parameters passed from the POS flow, it is considered that, when addressline1 and country field values
      are available,  address is already exists and needs to be updated.
      However, POS flow considers an address to be displayed in CREATE mode, even though assressline1 and country field values are passed
      In this Scenario posEvent parameter value will be passed  as 'CREATE' from posflow to HZ files
      so, if parameters HzPuiAddress1 and HzPuiCountryName are not null, flow is from non HZ and address has to be displayed in UPDATE mode in HZ code
      Parameters HzPuiAddress1 and HzPuiCountryName are used to identify flow is from HZ or nonHZ, in this case from POS(nonHZ)
      */
               
      String flow = null;
      if(posEVENT != null && posHzPuiAddress1 != null && posHzPuiCountryName != null){
          flow = "nonHZ";
      }
      Diagnostic.println(getLogStr("flow => ",flow));
      Serializable[] serialzedParameters={flow};
      
      String style = (String)am.invokeMethod("resetAddressStyle",serialzedParameters);
    
Diagnostic.println(getLogStr("style",style));
	/* Added against Bug#6787851*/
	if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
		pageContext.writeDiagnostics(this,getLogStr("style",style),OAFwkConstants.STATEMENT);

    //flex merge with parents
    OADescriptiveFlexBean dffBn = (OADescriptiveFlexBean)webBean.findIndexedChildRecursive("HzAddressStyleFlex");
    if(dffBn != null)
    {
      //bug 4927617: read only render mode and shut off client validation
      if("READ_ONLY".equals(pHzPuiAddressEvent))
      {
        dffBn.setReadOnly(true);
        dffBn.setCSSClass("OraDataText");
      }//if readonly
      if(pHzPuiOrgCompositeExist!=null
      || pHzPuiPersonCompositeExist!=null){
       dffBn.setAttributeValue(UNVALIDATED_ATTR,Boolean.TRUE);
      }//if

       if("CREATE".equals(pHzPuiAddressEvent))
       {
           dffBn.setFlexContextCode(pageContext, style);
       }

      dffBn.setContextListRendered(false);
      dffBn.mergeSegmentsWithParent(pageContext);
      dffBn.setAttributeValue(SERVER_UNVALIDATED_ATTR,Boolean.TRUE); //bug #8666862 - Placed after WebBeanMerge to enable LOV Validation
    }

    //show party site number if profile HZ_GENERATE_PARTY_SITE_NUMBER is N
    OAMessageTextInputBean psnBn = (OAMessageTextInputBean)webBean.findIndexedChildRecursive("hzPartySiteNumber");
    if(psnBn != null)
    {
      //bug 4926596
      String profileGenPartySiteNo=pageContext.getRootApplicationModule().
        getOADBTransaction().getProfile("HZ_GENERATE_PARTY_SITE_NUMBER");
Diagnostic.println(getLogStr("profileGenPartySiteNo",profileGenPartySiteNo));
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,getLogStr("profileGenPartySiteNo",profileGenPartySiteNo),OAFwkConstants.STATEMENT);

      //if event is update or read only =) bean profile independent,is read only
      //if event is create =) if profile is Y then hide else display input text
      if("UPDATE".equals(pHzPuiAddressEvent)
      || "READ_ONLY".equals(pHzPuiAddressEvent))
      {
Diagnostic.println("psnBn read only");
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"psnBn read only",OAFwkConstants.STATEMENT);

        psnBn.setRendered(true);
        psnBn.setReadOnly(true);
        psnBn.setCSSClass("OraDataText");
      }//if update or read only
      else
      if("CREATE".equals(pHzPuiAddressEvent))
      {
        if("N".equals(profileGenPartySiteNo))
        {
Diagnostic.println("psnBn updatable");
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"psnBn updatable",OAFwkConstants.STATEMENT);

          psnBn.setRendered(true);
          psnBn.setReadOnly(false);
        }
        else
        if(profileGenPartySiteNo==null || "Y".equals(profileGenPartySiteNo))
        {
Diagnostic.println("psnBn hidden");
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"psnBn hidden",OAFwkConstants.STATEMENT);

          psnBn.setRendered(false);
        }//ifelse
      }//ifelse create
    }//if psnBn!=null


    //bug 4927617: read only render mode
    if("READ_ONLY".equals(pHzPuiAddressEvent))
    {
Diagnostic.println("Making view only psDffBn and mcl");
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"Making view only psDffBn and mcl",OAFwkConstants.STATEMENT);

      OADescriptiveFlexBean psDffBn = (OADescriptiveFlexBean)webBean.findIndexedChildRecursive("partySiteInformation");
      if(psDffBn!=null)
      {
        psDffBn.setReadOnly(true);
      }//if psDffBn!=null

      OAMessageComponentLayoutBean mcl = (OAMessageComponentLayoutBean)webBean.findIndexedChildRecursive("AddressStyleRN");
      if(mcl!=null)
      {
        super.setReadOnly(pageContext,mcl);
      }//if mcl!=null
    }//if readonly

   // UI review Bug 4659831 (added on 17-May-2006) 
Diagnostic.println(getLogStr("isEmpty(pHzPuiComposite)",String.valueOf(isEmpty(pHzPuiComposite))));
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,getLogStr("isEmpty(pHzPuiComposite)",String.valueOf(isEmpty(pHzPuiComposite))),OAFwkConstants.STATEMENT);

    if(!isEmpty(pHzPuiComposite))
    {
      OAWebBean requiredBean=webBean.findIndexedChildRecursive("RequiredMsgRow");
      if(requiredBean!=null)
      {
        requiredBean.setRendered(true);
Diagnostic.println("display instruction text for composite usage");
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"display instruction text for composite usage",OAFwkConstants.STATEMENT);

      }//if
    }//if !isEmpty

  //bug 5264505
  OAWebBean geoCodeOverrideBean=webBean.findChildRecursive("hzGeoCodeOverride");
  if(geoCodeOverrideBean!=null)
  {
Diagnostic.println("Invoking AM.controlGeoOverrideRendering()");
	/* Added against Bug#6787851*/
	if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
		pageContext.writeDiagnostics(this,"Invoking AM.controlGeoOverrideRendering()",OAFwkConstants.STATEMENT);

    Boolean geoOverrideRendering=(Boolean)am.invokeMethod("controlGeoOverrideRendering");
Diagnostic.println("geoOverrideRendering="+geoOverrideRendering);
	/* Added against Bug#6787851*/
	if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
		pageContext.writeDiagnostics(this,"geoOverrideRendering="+geoOverrideRendering,OAFwkConstants.STATEMENT);

    geoCodeOverrideBean.setRendered(geoOverrideRendering.booleanValue());
  }


      //show trillum addressbutton if profile HZ_CPUI_REALTIME_ADDR_VAL is Y
   OASubmitButtonBean   verifybtn = (OASubmitButtonBean)webBean.findIndexedChildRecursive("HzPuiVerifyAddressButton");
   OASubmitButtonBean   revertbtn = (OASubmitButtonBean)webBean.findIndexedChildRecursive("HzPuiRevertAddressButton");
     String profileRealTimeAddrval=pageContext.getRootApplicationModule().getOADBTransaction().getProfile("HZ_CPUI_REALTIME_ADDR_VAL");
      Diagnostic.println(getLogStr("profileRealTimeAddrval",profileRealTimeAddrval));
                
      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                    pageContext.writeDiagnostics(this,getLogStr("profileRealTimeAddrval",profileRealTimeAddrval),OAFwkConstants.STATEMENT);
if((verifybtn!=null)&&(revertbtn!=null)){
//  Bug 13644244 code change start
  if("READ_ONLY".equals(pHzPuiAddressEvent))
  {    verifybtn.setRendered(false);
    revertbtn.setRendered(false);
  } //  Bug 13644244 code change End
  else   if("UPDATE".equals(pHzPuiAddressEvent)  || "CREATE".equals(pHzPuiAddressEvent))
      {
      if(( profileRealTimeAddrval==null) ||( profileRealTimeAddrval.equals("N")))               
   {
    verifybtn.setRendered(false);
    revertbtn.setRendered(false);
   }else if ( profileRealTimeAddrval.equals("Y"))
   {
       verifybtn.setRendered(true);
       revertbtn.setRendered(true);
   }
   }
}
 
 //HzPuiSuggestionflow true when suggestions rendered 
  if((pageContext.getParameter("HzMessage")!= null) && (pageContext.getParameter("HzPuiSuggestionFlow")!= null))
  { 
        if ("FALSE".equals(pageContext.getParameter("HzPuiSuggestionFlow")))
           { 
     if(pageContext.getParameter("HzMessage").equals("CONFIRM"))
       {
         throw new OAException(pageContext.getParameter("HzMessagevalue"),OAException.CONFIRMATION);}
     else  if(pageContext.getParameter("HzMessage").equals("WARNING"))
       {     throw new OAException(pageContext.getParameter("HzMessagevalue"),OAException.WARNING);}
        
           }
           }
    Diagnostic.println("HzPuiAddressCreateUpdateCO.processRequest(EXIT)");
            /* Added against Bug#6787851*/
            if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
                    pageContext.writeDiagnostics(this,"HzPuiAddressCreateUpdateCO.processRequest(EXIT)",OAFwkConstants.STATEMENT);




  }//processRequest




  /**
   * Procedure to handle form submissions for form elements in
   * AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
Diagnostic.println("HzPuiAddressCreateUpdateCO.processFormRequest(ENTER)");
	/* Added against Bug#6787851*/
	if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
		pageContext.writeDiagnostics(this,"HzPuiAddressCreateUpdateCO.processFormRequest(ENTER)",OAFwkConstants.STATEMENT);
     super.processFormRequest(pageContext, webBean);
    String HzPuiSuggestionFlow ="FALSE";
    OAApplicationModule am = (OAApplicationModule)pageContext.getApplicationModule(webBean);

      String processFurther = pageContext.getParameter("processFurther");
      if(processFurther == null || ("".equals(processFurther))){
          processFurther = "Y";
      }
      pageContext.writeDiagnostics(METHOD_NAME,"SMJ processFurther:"+processFurther,OAFwkConstants.STATEMENT);
      if("Y".equals(processFurther)){
    // get location id from server utility if exist
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

    if ("YES".equals(pageContext.getParameter( "HzPuiAddressExist")))
    {
        Diagnostic.println("locaiton , PartySite vo already been created " );
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"locaiton , PartySite vo already been created ",OAFwkConstants.STATEMENT);

        pageContext.putParameter("HzPuiAddressExist", "YES");
        //pageContext.putParameter("HzPuiLocationId", locationId);
        //pageContext.putParameter("HzPuiPartySiteId", partySiteId);
    }

    OATableBean tableBean =
       (OATableBean) webBean.findIndexedChildRecursive("hzPartySiteUseTable");
    if(tableBean!=null){
    if ((tableBean!=null)&&(tableBean.getName(pageContext).equals(pageContext.getParameter(SOURCE_PARAM))) &&
    (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM))))
    {
      am.invokeMethod("addPartySiteUses");
    }
    }
    else
    if (pageContext.getParameter("HzPuiPartySiteUseDeleteYes") != null)
    {
        String partySiteUseId = pageContext.getParameter("HzPuiPartySiteUseId");

        Diagnostic.println("get HzPartySiteUseDelete event , partySiteUseId = " + partySiteUseId);
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"get HzPartySiteUseDelete event , partySiteUseId = " + partySiteUseId,OAFwkConstants.STATEMENT);

      if ( partySiteUseId != null && partySiteUseId.trim()!= null )
      {

        Serializable[] parameters =  { partySiteUseId };
        boolean deleted = ((Boolean)am.invokeMethod("deletePartySiteUses", parameters)).booleanValue();

        if (deleted)
        {

        // get the site use type meaning from database
        String hzPuiPartySiteUseType = pageContext.getParameter("HzPuiPartySiteUseType");

        String siteUseTypeMeaning = "";
        if (hzPuiPartySiteUseType != null && hzPuiPartySiteUseType.trim().length() > 0)
        {
          Serializable[] parameters2 =  { hzPuiPartySiteUseType };
          siteUseTypeMeaning = (String) am.invokeMethod("getSiteUseMeanFromType", parameters2);
        }

        MessageToken[] tokens = { new MessageToken("DISPLAY_VALUE", siteUseTypeMeaning) };
        OAException message = new OAException("AR", "HZ_PUI_REMOVE_CONFIRMATION", tokens,
                                            OAException.CONFIRMATION, null);
        pageContext.putDialogMessage(message);
        }
        else
        {
          OAException staleMsg = new OAException("FND","FND_STALE_DATA_ERROR");
          pageContext.putDialogMessage(staleMsg);
        }

      }
    }
    if ("HzPartySiteUseDelete".equals(pageContext.getParameter("HzPuiPsuEvent")))
    {
      // The user has clicked a "Delete" icon so we want to display a "Warning"
      // dialog asking if she really wants to delete the PO.  Note that we
      // configure the dialog so that pressing the "Yes" button submits to
      // this page so we can handle the action in this processFormRequest( ) method.
      String hzPuiPartySiteUseId = pageContext.getParameter("HzPuiPartySiteUseId");
      String hzPuiPartySiteUseType = pageContext.getParameter("HzPuiPartySiteUseType");

      // when use want to remove the row they just add, the site use type is not in
      // form submit value, need get this from VO
      if ( hzPuiPartySiteUseType == null || hzPuiPartySiteUseType.length() ==0 || hzPuiPartySiteUseType.trim() == null )
      {
        Serializable[] parameters =  { hzPuiPartySiteUseId };
        hzPuiPartySiteUseType = (String) am.invokeMethod("getSiteUseTypeFromVO", parameters);
      }

      // get the site use type meaning from database, set it to the token

      Serializable[] parameters2 =  { hzPuiPartySiteUseType };
      String siteUseTypeMeaning = (String) am.invokeMethod("getSiteUseMeanFromType", parameters2);
      MessageToken[] tokens = { new MessageToken("SITE_USE_TYPE", siteUseTypeMeaning) };
      OAException mainMessage = new OAException("AR", "HZ_PUI_REMOVE_SITE_USE_WARNING", tokens);

      // Note that even though we're going to make our Yes/No buttons submit a
      // form, we still need some non-null value in the constructor's Yes/No
      // URL parameters for the buttons to render, so we just pass empty
      // Strings for this.

      OADialogPage dialogPage = new OADialogPage(OAException.WARNING,
                                                 mainMessage,
                                                 null,
                                                 "",
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

     if (hzPuiPartySiteUseType != null && hzPuiPartySiteUseType.trim().length() > 0)
       formParams.put("HzPuiPartySiteUseType", hzPuiPartySiteUseType);
     else return;

     formParams.put("HzPuiResubmitFlag", "YES");

     if (  pageContext.getParameter("HzPuiOrgCompositeExist") != null )
       formParams.put("HzPuiOrgCompositeExist", pageContext.getParameter("HzPuiOrgCompositeExist"));

     if (  pageContext.getParameter("HzPuiPersonCompositeExist") != null )
       formParams.put("HzPuiPersonCompositeExist", pageContext.getParameter("HzPuiPersonCompositeExist"));

     dialogPage.setFormParameters(formParams);

          //Following code is added to fix the problem of loosing context
          //when rendering a Dialog page
          String sRegionRefName = (String) pageContext.getParameter("HzPuiAddressRegionRef");
          if ( sRegionRefName != null && sRegionRefName.length() > 0 )
               dialogPage.setHeaderNestedRegionRefName(sRegionRefName);
          else dialogPage.setReuseMenu(false);

     pageContext.redirectToDialogPage(dialogPage);

    }
    else if ("HzPuiPopulateSuggestion".equals(pageContext.getParameter(EVENT_PARAM)))
    {
      OAMessageChoiceBean addrSuggPoplist = (OAMessageChoiceBean)webBean.findChildRecursive("addrSuggestionPoplist");
        HashMap params =new HashMap();
      String key = addrSuggPoplist.getSelectionValue(pageContext);
      if (key != null)
      {
        Serializable[] paramPopKey =  { key };
        am.invokeMethod("populateAddressSuggestion", paramPopKey);
      }
        HzPuiSuggestionFlow ="TRUE";
        params.put("HzPuiSuggestionFlow",HzPuiSuggestionFlow); 
      pageContext.setForwardURLToCurrentPage(params,
                                               true, // retain the AM
                                               pageContext.getBreadCrumbValue(),
                                               IGNORE_MESSAGES);
    }
    else if ("HzPuiAddressPrimaryCheck".equals(pageContext.getParameter(EVENT_PARAM)))
    {
    // Catch the fireAction event from identifying address falg
      Diagnostic.println("HZPUI: EVENT_PARAM = HzPuiAddressPrimaryCheck");
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"HZPUI: EVENT_PARAM = HzPuiAddressPrimaryCheck",OAFwkConstants.STATEMENT);

      // The user has checked the identifying flag checkbox, we want to display
      // an alert so that she can acknowlege to uncheck the current primary.
      String primaryFlag = (String)am.invokeMethod("getPartySiteVOPrimaryFlagValue");
      if("Y".equals(primaryFlag))
      {
        String primaryAddress = (String)(am.invokeMethod("getPrimaryAddress"));

        if ( primaryAddress != null && primaryAddress.trim().length() > 0 )
        {
          // configure the dialog so that pressing the "Yes" button submits to
          // this page so we can handle the action in this processFormRequest( ) method.
          MessageToken[] messageTokens = { new MessageToken("ADDRESS", primaryAddress) };
          OAException mainMessage =
            new OAException(
                "AR", "HZ_PUI_SET_PRIMARYADDR_WARNING", messageTokens);

          // Note that even though we're going to make our Yes/No buttons submit a
          // form, we still need some non-null value in the constructor's Yes/No
          // URL parameters for the buttons to render, so we just pass empty
          // Strings for this.

          OADialogPage dialogPage = new OADialogPage(OAException.WARNING,
                                                     mainMessage,
                                                     null,
                                                     "",
                                                     "");

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

          java.util.Hashtable formParams = new java.util.Hashtable(9);

          formParams.put("HzPuiAddressExist", "YES");
          //formParams.put(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX+"Country" , pageContext.getParameter(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX +"Country"));
          //formParams.put(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX+"CountryName" , pageContext.getParameter(HzPuiAddressFormatCO.ATTRIBUTE_PREFIX +"CountryName"));
          //pageContext.putParameter("HzPuiLocationId", locationId);
          //pageContext.putParameter("HzPuiPartySiteId", partySiteId);

          formParams.put("HzPuiResubmitFlag", "YES");

          if (  pageContext.getParameter("HzPuiOrgCompositeExist") != null )
            formParams.put("HzPuiOrgCompositeExist", pageContext.getParameter("HzPuiOrgCompositeExist"));

          if (  pageContext.getParameter("HzPuiPersonCompositeExist") != null )
            formParams.put("HzPuiPersonCompositeExist", pageContext.getParameter("HzPuiPersonCompositeExist"));

          dialogPage.setFormParameters(formParams);
          //Following code is added to fix the problem of loosing context
          //when rendering a Dialog page
          String sRegionRefName = (String) pageContext.getParameter("HzPuiAddressRegionRef");
          if ( sRegionRefName != null && sRegionRefName.length() > 0 )
               dialogPage.setHeaderNestedRegionRefName(sRegionRefName);
          else dialogPage.setReuseMenu(false);
          pageContext.redirectToDialogPage(dialogPage);
        }
      }
    }
    else if (pageContext.getParameter("HzPuiSetPrimaryAddressNoButton") != null)
    {
      Diagnostic.println("HZPUI: HzPuiSetPrimaryAddressNoButton is not null");
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"HZPUI: HzPuiSetPrimaryAddressNoButton is not null",OAFwkConstants.STATEMENT);

      am.invokeMethod("unsetPartySiteVOPrimaryFlag");
    }
    else if(pageContext.isLovEvent()&&"HzFlexCountry".equals(pageContext.getLovInputSourceId()))
    //else if(pageContext.getParameter("HzCountryGoButton")!=null)
    {
            pageContext.setForwardURLToCurrentPage(null,
                                               true, // retain the AM
                                               pageContext.getBreadCrumbValue(),
                                               IGNORE_MESSAGES);
    }else if (pageContext.getParameter("HzPuiVerifyAddressButton") != null )
     {   
      	String Address[] = (String[])am.invokeMethod("validateTrillumAddress");
        	String trillumaddress = Address[1];
	  	HashMap params =new HashMap();
	  
		String messagevalue = null;
                String messagetype = null;
		Serializable[] exceptionmsgparam = { "RESET","RESET"};
        	Class[] exceptionmsgclassparam={"RESET".getClass(),"RESET".getClass()};
            
        
      	     
                 	Boolean populateFlag  = Boolean.TRUE;
	 		Serializable[] validaddrValue = { Address[1],populateFlag };
         		Class[] validaddrclassParams = {Address[1].getClass(),populateFlag.getClass()};
         		am.invokeMethod("populateTrillumAddressValue", validaddrValue,validaddrclassParams);
         		messagevalue =(String)am.invokeMethod("getExceptionMessage");
         		messagetype =(String)am.invokeMethod("getMessageType");
        		if((messagevalue!=null)&&(messagetype.equals("CONFIRMATION"))) {
		           am.invokeMethod("setExceptionMessage",exceptionmsgparam,exceptionmsgclassparam);
          			params.put("HzMessage","CONFIRM");
            		params.put("HzMessagevalue",messagevalue);
			 }else if((messagevalue!=null)&&(messagetype.equals("WARNING"))) {
		           am.invokeMethod("setExceptionMessage",exceptionmsgparam,exceptionmsgclassparam);
          			params.put("HzMessage","WARNING");
            		params.put("HzMessagevalue",messagevalue);
			 }

                 params.put("HzPuiSuggestionFlow",HzPuiSuggestionFlow);       			
	 	pageContext.setForwardURLToCurrentPage( params,
                   true,
                   pageContext.getBreadCrumbValue(),
                   IGNORE_MESSAGES);
      }else if (pageContext.getParameter("HzPuiRevertAddressButton") != null )
     {
	    	HashMap params =new HashMap();
	    	Boolean populateFlag  = Boolean.FALSE;
		 Serializable[] validaddrValue = { "abc",populateFlag };
         	Class[] validaddrclassParams = {"abc".getClass(),populateFlag.getClass()};
         	am.invokeMethod("populateTrillumAddressValue", validaddrValue,validaddrclassParams);
         	 params.put("HzMessage","NOMSG");
	    params.put("HzPuiSuggestionFlow",HzPuiSuggestionFlow);
         	pageContext.setForwardURLToCurrentPage( params,
                   true,
                   pageContext.getBreadCrumbValue(),
                   IGNORE_MESSAGES);
      
	}


      /*Added against bug 7620414: START*/
      String HzPuiValidateDuplicateSiteUse=(String)pageContext.getParameter("HzPuiValidateDuplicateSiteUse");
      if(!isEmpty(HzPuiValidateDuplicateSiteUse) && HzPuiValidateDuplicateSiteUse.equalsIgnoreCase("Y"))
      {
       if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
               pageContext.writeDiagnostics(this,"Calling checkDuplicateSiteUse() method to check the duplicate site use",OAFwkConstants.STATEMENT);
       am.invokeMethod("checkDuplicateSiteUse");
      }
      /*Added against bug 7620414: END*/
      
Diagnostic.println("HzPuiAddressCreateUpdateCO.processFormRequest(EXIT)");
		/* Added against Bug#6787851*/
		if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
			pageContext.writeDiagnostics(this,"HzPuiAddressCreateUpdateCO.processFormRequest(EXIT)",OAFwkConstants.STATEMENT);
  
      } //end of processFurther
  }//processFormRequest

  public void processFormData(OAPageContext pageContext, OAWebBean webBean)
  {
Diagnostic.println("HzPuiAddressCreateUpdateCO.processFormData()");
	/* Added against Bug#6787851*/
	if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
		pageContext.writeDiagnostics(this,"HzPuiAddressCreateUpdateCO.processFormData()",OAFwkConstants.STATEMENT);

    super.processFormData(pageContext, webBean);
  }//processFormData

  protected void customProcessFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
  }

  public void validateInputParameters(OAPageContext pageContext, OAWebBean webBean)
  {
  }

  protected void customProcessRequest(OAPageContext pageContext, OAWebBean webBean)
  {
  }


}//class