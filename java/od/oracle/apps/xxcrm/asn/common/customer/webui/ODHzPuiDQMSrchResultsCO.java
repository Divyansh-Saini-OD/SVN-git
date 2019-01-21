/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import java.util.Vector;
import java.io.Serializable;
import java.util.Enumeration;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageRadioButtonBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.jbo.common.Diagnostic;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;
import oracle.apps.fnd.framework.webui.beans.layout.OADefaultSingleColumnBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASeparatorBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASpacerBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;

import oracle.apps.ar.hz.components.search.webui.*;
/**
 * Controller for ...
 */
public class ODHzPuiDQMSrchResultsCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: ODHzPuiDQMSrchResultsCO.java 115.24 2004/12/17 00:33:51 tsli noship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  private static final String ATTR_PARAM_PREFIX  = "MATCH_RULE_ATTR";
  private static final String SRCH_VO_NAME  = "ODHzPuiDQMSrchResultsVO";
  private static final int ATTR_PARAM_PREFIX_LEN = ATTR_PARAM_PREFIX.length();

  /**
   * Layout and page setup logic for AK region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {

    super.processRequest(pageContext, webBean);

    Diagnostic.println("Inside processRequest");

    String sHzPuiSearchComponentMode = (String)pageContext.getParameter("HzPuiSearchComponentMode");
    OADBTransactionImpl txImpl = (OADBTransactionImpl) pageContext.getRootApplicationModule().getOADBTransaction();
    txImpl.putTransientValue("HzPuiSearchComponentMode", pageContext.getParameter("sHzPuiSearchComponentMode"));
    txImpl.putTransientValue("HzPuiSearchAttributeVisited", "N");

    OASubmitButtonBean submitButtonBean = null;

    String headerText = (String)pageContext.getParameter("HzPuiSearchHeaderText");
    OADefaultSingleColumnBean headerBean = (OADefaultSingleColumnBean) webBean.findChildRecursive("header");
    if ((headerText != null) && (!headerText.equals("")))
    {
       headerBean.setText(headerBean, headerText);
    }

    String sSearchType = pageContext.getParameter("HzPuiSearchPartyType");
    OAMessageStyledTextBean certColumn = (OAMessageStyledTextBean)webBean.findIndexedChildRecursive("CertificationLevel");
    if (certColumn != null)
    {
      if ("PERSON".equals(sSearchType))
        certColumn.setRendered(false);
    }

    //The profile for displaying cert level
    String sCertStatus = (String) pageContext.getProfile("HZ_DISPLAY_CERT_LEVEL");
    Diagnostic.println("HZ_DISPLAY_CERT_LEVEL = " + sCertStatus );

    if ( ! "Y".equals( sCertStatus ) )
    {
        Diagnostic.println("Inside !'Y'.equals( sCertStatus )" );
        if( certColumn != null)
            certColumn.setRendered(false);
    }

    //If the component is used in the LOV Mode, then display the radio button.
    if (( "LOV".equals(sHzPuiSearchComponentMode) ) ||
       ( "DEDUPE".equals(sHzPuiSearchComponentMode) ))
    {
       /* Hide separator */
       OASeparatorBean separatorBean = (OASeparatorBean) webBean.findChildRecursive("separator");
       separatorBean.setRendered(false);
       OASpacerBean spacerBean = (OASpacerBean) webBean.findChildRecursive("spacer");
       spacerBean.setWidth(0);

       OAMessageRadioButtonBean selector = (OAMessageRadioButtonBean) webBean.findChildRecursive("HzPuiDqmOrgSS");
       if ( selector != null )
       {
          selector.setRendered(true);
       }

       OALinkBean nameLink = (OALinkBean) webBean.findChildRecursive("HzPuiPartyName1_link");
       if ( nameLink != null )
       {
          nameLink.setWarnAboutChanges(false);
       }

       submitButtonBean = (OASubmitButtonBean)webBean.findIndexedChildRecursive("HzPuiMarkDup");
       if( submitButtonBean != null)
       {
           submitButtonBean.setRendered(false);
       }

       submitButtonBean = (OASubmitButtonBean)webBean.findIndexedChildRecursive("HzPuiPurchase");
       if( submitButtonBean != null)
       {
           submitButtonBean.setRendered(false);
       }

       OALinkBean imageBean = (OALinkBean)webBean.findIndexedChildRecursive("Update");
       if( imageBean != null)
       {
           imageBean.setRendered(false);
       }

       if ( "DEDUPE".equals(sHzPuiSearchComponentMode) )
       {
            submitButtonBean = (OASubmitButtonBean)webBean.findIndexedChildRecursive("HzPuiCreate");
            if( submitButtonBean != null)
            {
              submitButtonBean.setRendered(false);
            }

            submitButtonBean = (OASubmitButtonBean)webBean.findIndexedChildRecursive("HzPuiSelectOrgButton");
            if( submitButtonBean != null)
            {
              submitButtonBean.setRendered(true);
            }
       }
    }
    else
    {
        /* Disable header when doing search. For ATG */
        headerBean.setHeaderDisabled(true);

        //In the stad search mode disable the selector
        //By default the selector is rendered=true in the xml file because
        //of OA was not rendering the selector correctly if it was not rendered by default.
        OAMessageRadioButtonBean selector = (OAMessageRadioButtonBean) webBean.findChildRecursive("HzPuiDqmOrgSS");
        if ( selector != null )
        {
            selector.setRendered(false);
        }
        //The profile person dedupe prevention matchrule id
        String sMarkDuplicate = (String) pageContext.getProfile("HZ_MARK_DUPLICATES_ENABLED_FLAG");
        Diagnostic.println("HZ_MARK_DUPLICATES_ENABLED_FLAG = " + sMarkDuplicate );
        //If the mark duplicate is turned off
        if ( !"Y".equals( sMarkDuplicate ) )
        {
             Diagnostic.println("Inside  !'Y'.equals( sMarkDuplicate )" );
             submitButtonBean = (OASubmitButtonBean)webBean.findIndexedChildRecursive("HzPuiMarkDup");
             if( submitButtonBean != null)
             {
                 submitButtonBean.setRendered(false);
             }
        }

        //The profile person dedupe prevention matchrule id
        String sDNBAccess = (String) pageContext.getProfile("HZ_DNB_ACCESS_ENABLED_FLAG");
        Diagnostic.println("HZ_DNB_ACCESS_ENABLED_FLAG = " + sDNBAccess );
        //If the mark duplicate is turned off
        if ( ! "Y".equals( sDNBAccess ) )
        {
              Diagnostic.println("Inside !'Y'.equals( sDNBAccess )" );
              submitButtonBean = (OASubmitButtonBean)webBean.findIndexedChildRecursive("HzPuiPurchase");
              if( submitButtonBean != null)
              {
                 submitButtonBean.setRendered(false);
              }
        }
    }

    // Case when search results should be displayed upon navigation
    // to the search results component:
    // If a new party Id is passed, as in the case when a party is created
    // from create button in search results component.
    Diagnostic.println("HzPuiSearchAutoQuery = " + pageContext.getParameter("HzPuiSearchAutoQuery"));
    String sNewPartyId = pageContext.getParameter("HzPuiNewPartyId");
    if (sNewPartyId != null)
        returnResults(pageContext, webBean, null, sNewPartyId);

    else if ("Y".equals(pageContext.getParameter("HzPuiSearchAutoQuery")))
    {
      HashMap paramHash = new HashMap(10);
      //Check for DQM specific search parameter
      checkForPartyParams( pageContext, webBean, paramHash );
      if(paramHash.size()!=0)
         goButtonPressed(pageContext, webBean);
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

    if (pageContext.getParameter("HzPuiGoSearch") != null)
      goButtonPressed(pageContext, webBean);
  }

  /**
   * Procedure to get all the Party Specific Parameters from the
   * pageContext and adds it to the HashMap. Calling class
   * can check the value of HashMap to figure out whether user
   * had entered any DQM(Party) specific search parameter.
   *
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   * @param paramHash stores DQM specific user entered search Params
   */
  public void checkForPartyParams( OAPageContext pageContext,
                                   OAWebBean webBean,
                                   HashMap paramHash )
  {
    String sSrchVal;
    String sAttrId;
    Enumeration e = pageContext.getParameterNames();
    while(e.hasMoreElements())
    {
      String pname = (String)e.nextElement();
      if(!pname.startsWith(ATTR_PARAM_PREFIX))
      {
        // ignore parameter with other prefix
        continue;
      }

      sSrchVal = pageContext.getParameter(pname);
      if(sSrchVal==null || sSrchVal.trim().length()==0)
      {
        // ignore parameter is value is empty
        continue;
      }

      Diagnostic.println("sSrchVal2: [" + sSrchVal + "]");
      sAttrId  = pname.substring(ATTR_PARAM_PREFIX_LEN);

      Integer intAttrId = null;
      try
      {
        //intMatchRuleAttrId = Integer.parseInt(sAttrId);
        intAttrId = new Integer(sAttrId);
      }
      catch(NumberFormatException ne)
      {
        continue;
      }

      //save the parameter to the HashMap
      paramHash.put(intAttrId, sSrchVal);

      //Put the search parameters into transaction cache
      Diagnostic.println("Adding to Transaction Cache: " + pname + " " + sSrchVal);
      pageContext.putTransactionValue(pname, sSrchVal);
    }

    //If we di not find any parameters in the pageContext
    //check whether they exist in the Transaction cache. The
    //Transaction cache value is
    if ((paramHash.size()==0) && (pageContext.getParameter("HzPuiGoSearch") == null))
    {
       int i ;
       Integer intAttrId = null;
       for (i = 1; i < 50; i++ )
       {
            Diagnostic.println("Checking transaction for Saved Search Parameters " + ATTR_PARAM_PREFIX + i);
            sSrchVal = (String)pageContext.getTransactionValue(ATTR_PARAM_PREFIX + i);
            if(sSrchVal==null || sSrchVal.trim().length()==0)
            {
                // ignore parameter is value is empty
                continue;
            }
            intAttrId = new Integer(i);
            //save the parameter to the HashMap
            paramHash.put(intAttrId, sSrchVal);
       }
    }
  }


 /**
   * Procedure to call the DQM api
   *
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the AK region
   * @param paramHash stores DQM specific user entered search Params
   * @param extraWhereClause passes the extra where clause for the DQM api
   */
  public String callDQMApi( OAPageContext pageContext,
                                   OAWebBean webBean,
                                   HashMap paramHash,
                                   StringBuffer restrictSql,
                                   StringBuffer extraWhereClause,
                                   Vector extraParams)
  {
    String sContextId = null;
    try
    {
       // get match rule ID from profile option value
    String srchType = pageContext.getParameter("HzPuiSearchType");
    String srchMode = pageContext.getParameter("HzPuiSearchMode");
    String sSimpleMatchRuleId = pageContext.getParameter("HzPuiSimpleMatchRuleId");
    String sAdvMatchRuleId = pageContext.getParameter("HzPuiAdvMatchRuleId");
    String sMatchRuleId = sSimpleMatchRuleId;
    if ("SIMPLEADV".equals(srchType) && "ADV".equals(srchMode))
      sMatchRuleId = sAdvMatchRuleId;

    Diagnostic.println("Srch results: sMatchRuleName = " + sMatchRuleId);

    if ( sMatchRuleId != null ) Diagnostic.println("MATCH RULE LENGTH - " + sMatchRuleId.length());
    if(sMatchRuleId==null)
    {
      //get the value from the database if not found in parameter list
      sMatchRuleId = pageContext.getProfile("HZ_RM_MATCH_RULE_ID");
    }

    String matchOption = pageContext.getParameter("HzPuiMatchOptionDisplay");
    Diagnostic.println("matchOption = " + matchOption);
    String partyType = pageContext.getParameter("HzPuiSearchPartyType");
       Serializable[] params = { paramHash, sMatchRuleId,
                                 matchOption,
                                 partyType,
                                 "N", restrictSql.toString(), extraWhereClause };
       Class[] classes =  { Class.forName("com.sun.java.util.collections.HashMap"),
                            Class.forName("java.lang.String"),
                            Class.forName("java.lang.String"),
                            Class.forName("java.lang.String"),
                            Class.forName("java.lang.String"),
                            Class.forName("java.lang.String"),
                            Class.forName("java.lang.StringBuffer")};
       OAApplicationModule am = pageContext.getApplicationModule(webBean);
       sContextId = (String)am.invokeMethod("callDQMSearch", params, classes);

    }
    catch(ClassNotFoundException ce)
    {
       pageContext.putDialogMessage(
         new OAException("AR","HZ_DL_CREATE_DUP_UNEXP_ERR",null,OAException.ERROR,null));
    }
    return sContextId;
  }

  public void goButtonPressed( OAPageContext pageContext, OAWebBean webBean)
  {
    HashMap paramHash = new HashMap(10);

    //Check for DQM specific search parameter
    checkForPartyParams( pageContext, webBean, paramHash );

    if ((paramHash.size()==0) && (pageContext.getParameter("HzPuiGoSearch") != null))
    {
      // prompt user for input
      pageContext.putDialogMessage(new OAException("AR",
                            "HZ_DL_CREATE_DUP_SRCH_NO_INPUT",
                            null,
                            OAException.INFORMATION,
                            null));
    }
    else
    {
      // put in party type information

      String sSearchPartyType =  pageContext.getParameter("HzPuiSearchPartyType");
      if ("ORGANIZATION".equals(sSearchPartyType))
        paramHash.put(new Integer(14), "ORGANIZATION");
      else if ("PERSON".equals(sSearchPartyType))
        paramHash.put(new Integer(14), "PERSON");

      //do the actuall DQM search
      String sContextId = callDQMApi( pageContext, webBean, paramHash, getRestrictSql(pageContext), null, null);
      Diagnostic.println("Inside  ODHzPuiDQMSrchResultsCO. Returned AM.callDQMApi");
      Diagnostic.println("Inside  ODHzPuiDQMSrchResultsCO. Before calling returnResults");
      returnResults(pageContext, webBean, sContextId, null);
    }
  }

  public StringBuffer getRestrictSql(OAPageContext pageContext)
  {
      Diagnostic.println("getRestrictSql (+)");

      StringBuffer extraClause = new StringBuffer();

      String sSearchPartyType =  pageContext.getParameter("HzPuiSearchPartyType");
/*      if ("ORGANIZATION".equals(sSearchPartyType))
          extraClause.append("party_id in (select party_id from hz_parties where party_type = 'ORGANIZATION')");
      else if ("PERSON".equals(sSearchPartyType))
          extraClause.append("party_id in (select party_id from hz_parties where party_type = 'PERSON')");
*/
      String sRelFilter = pageContext.getParameter("HzPuiRelationshipFilterDisplay");
      if (sRelFilter != null && !"".equals(sRelFilter))
      {
         if (extraClause.length() > 0)
             extraClause.append(" and ");
         extraClause.append("party_id in (select distinct r.subject_id from hz_relationships r, hz_relationship_types rt where r.subject_type in ('");
         if (sSearchPartyType == null)
             sSearchPartyType = "ORGANIZATION','PERSON";
         extraClause.append(sSearchPartyType);
         extraClause.append("') and rt.role = '");
         extraClause.append(sRelFilter);
         extraClause.append("' and r.relationship_type = rt.relationship_type and r.relationship_code = rt.forward_rel_code and r.subject_type = rt.subject_type and r.object_type = rt.object_type)");
      }

      String sClassFilter = pageContext.getParameter("HzPuiClassificationFilterDisplay");
      String sClassCategory = pageContext.getParameter("HzPuiClassCategoryFilter"); //"CUSTOMER_CATEGORY";
      String sClassCode = pageContext.getParameter("HzPuiClassCodeFilter"); //"High Technology";
      String sClassMeaning = pageContext.getParameter("HzPuiClassMeaningFilter"); //"High Technology";
      Diagnostic.println("sClassFilter = " + sClassFilter);
      Diagnostic.println("sClassCategory = " + sClassCategory);
      Diagnostic.println("sClassMeaning = " + sClassMeaning);
      Diagnostic.println("sClassCode = " + sClassCode);

      if (sClassCategory != null && !"".equals(sClassCategory))
      {
        if (extraClause.length() > 0)
            extraClause.append(" and ");
        extraClause.append("party_id in (select owner_table_id from hz_code_assignments where owner_table_name = 'HZ_PARTIES' and class_category = '");
        extraClause.append(sClassCategory);
        extraClause.append("' and class_code = '");
        extraClause.append(sClassCode);
        extraClause.append("')");
      }

      String sInputWhereClause =  pageContext.getParameter("HzPuiDQMOrgSearchExtraWhereClause");
      if (sInputWhereClause != null && !"".equals(sInputWhereClause))
      {
        if (extraClause.length() > 0)
            extraClause.append(" and ");
        extraClause.append(sInputWhereClause);
      }

      Diagnostic.println("restrictSql: " + extraClause.toString());
      Diagnostic.println("getRestrictSql (-)");
      return extraClause;
  }

  public void returnResults(OAPageContext pageContext, OAWebBean webBean, String sContextId, String sNewPartyId)
  {
    Vector params = new Vector(2);

    StringBuffer extraClause = new StringBuffer();
    Diagnostic.println("ContextId - " + sContextId);
    Diagnostic.println("sNewPartyId = " + sNewPartyId);
    if (sNewPartyId != null)
    {
      params.addElement(null);
      params.addElement(sNewPartyId);
    }
    else
    {
      Diagnostic.println("NEW matchoption = " + pageContext.getParameter("HzPuiMatchOptionDisplay"));
      params.addElement(sContextId);
      params.addElement(null);
//      extraClause = getRestrictSql(pageContext);
    }
    Diagnostic.println("extraClause = " + extraClause);
    //Execute the query.
    try {
        Serializable[] params2 = { null, extraClause, params };
        Class[] classes  =  {  Class.forName("java.lang.StringBuffer"),
                                  Class.forName("java.lang.StringBuffer"),
                                  Class.forName("java.util.Vector")};
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        am.invokeMethod("executeQuery", params2, classes);
    }
    catch(ClassNotFoundException ce)
    {
       ce.printStackTrace();
    }
  }



}
