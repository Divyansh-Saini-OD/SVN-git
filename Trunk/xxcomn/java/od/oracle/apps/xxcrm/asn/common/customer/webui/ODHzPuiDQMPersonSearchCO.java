/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
//package oracle.apps.ar.hz.components.search.webui;
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.table.OAHGridBean;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.jbo.Row;
import java.util.Hashtable;
import oracle.jbo.domain.Number;
import oracle.jbo.common.Diagnostic;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.ar.hz.components.util.server.HzPuiServerUtil;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.ar.hz.components.search.webui.HzPuiDQMSrchResultsCO;
import oracle.apps.fnd.framework.webui.OAHGridQueriedRowEnumerator;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageRadioButtonBean;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;
import oracle.apps.fnd.framework.webui.beans.table.OAHGridBean;

import java.util.Vector;
import java.io.Serializable;
import java.util.Enumeration;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.jbo.common.Diagnostic;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.beans.layout.OASeparatorBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASpacerBean;
import oracle.apps.fnd.framework.webui.beans.layout.OADefaultSingleColumnBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.webui.beans.nav.OATreeDefinitionBean;
import oracle.cabo.ui.action.FireAction;
import oracle.cabo.ui.collection.Parameter;
import oracle.apps.fnd.framework.mds.OAExpressionUtils;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.cabo.ui.data.BoundValue;

import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import oracle.jdbc.driver.OracleConnection;
import java.sql.SQLException;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OARow;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.driver.OracleTypes;
import java.math.BigDecimal;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.MessageToken;

import od.oracle.apps.xxcrm.asn.common.customer.webui.ODHzPuiDQMSrchResultsCO;
import oracle.apps.ar.hz.components.search.webui.*;

/**
 * Controller for ...
 */
public class ODHzPuiDQMPersonSearchCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header: ODHzPuiDQMPersonSearchCO.java 115.19 2004/12/17 00:33:00 tsli noship $";
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

    Diagnostic.println("Inside ODHzPuiDQMPersonSearchCO processRequest");

    String headerText = (String)pageContext.getParameter("HzPuiSearchHeaderText");

    Diagnostic.println("Header text: " + headerText);
    OADefaultSingleColumnBean headerBean = (OADefaultSingleColumnBean) webBean.findChildRecursive("header");

    if ((headerText != null) && (!headerText.equals("")))
    {
       headerBean.setText(headerBean, headerText);
    }

    OATreeDefinitionBean node1 =
      (OATreeDefinitionBean)webBean.findChildRecursive("nodeDef1");

    String showPersonLink = (String)pageContext.getParameter("HzPuiShowPersonLink");
    boolean hidePersonLink = false;

    if ((showPersonLink != null) && (showPersonLink.equals("N")))
      hidePersonLink = true;

    if (( node1 != null ) && (!hidePersonLink))
    {
       FireAction fireAction = new FireAction("HzPuiDQMPersonSearchResultsAction", true );
       Parameter[] params = new Parameter[4];
       params[0]=new Parameter();
       params[0].setKey("HzPuiEvent");
       params[0].setValue("PARTYDETAIL");

       params[1]=new Parameter();
       params[1].setKey("HzPuiPartyType");
       params[1].setValueBinding(
         (BoundValue)OAExpressionUtils.handleExpression(pageContext,
                    node1,
                    "${oa.encrypt.ODHzPuiDQMSrchResultsVO.PartyType}",
                    OAWebBeanConstants.PRIMARY_CLIENT_ACTION_ATTR,
                    java.lang.String.class));

       params[2]=new Parameter();
       params[2].setKey("HzPuiPartyName");
       params[2].setValueBinding(
         (BoundValue)OAExpressionUtils.handleExpression(pageContext,
                    node1,
                    "${oa.encrypt.ODHzPuiDQMSrchResultsVO.PartyName}",
                    OAWebBeanConstants.PRIMARY_CLIENT_ACTION_ATTR,
                    java.lang.String.class));

       params[3]=new Parameter();
       params[3].setKey("HzPuiPartyId");
       params[3].setValueBinding(
         (BoundValue)OAExpressionUtils.handleExpression(pageContext,
                    node1,
                    "${oa.encrypt.ODHzPuiDQMSrchResultsVO.PartyId}",
                    OAWebBeanConstants.PRIMARY_CLIENT_ACTION_ATTR,
                    java.lang.String.class));

       fireAction.setParameters(params);
       fireAction.setUnvalidated(true);

       node1.setAttributeValue(PRIMARY_CLIENT_ACTION_ATTR, fireAction);
       node1.setAttributeValue(WARN_ABOUT_CHANGES, Boolean.TRUE);
    }



    OATreeDefinitionBean node2 =
      (OATreeDefinitionBean)webBean.findChildRecursive("nodeDef2");

    if ( node2 != null )
    {
       FireAction fireAction = new FireAction("HzPuiDQMPersonSearchDetailAction", true );
       Parameter[] params = new Parameter[5];
       params[0]=new Parameter();
       params[0].setKey("HzPuiEvent");
       params[0].setValue("PARTYDETAIL");

       params[1]=new Parameter();
       params[1].setKey("HzPuiPartyType");
       params[1].setValueBinding(
         (BoundValue)OAExpressionUtils.handleExpression(pageContext,
                    node2,
                    "${oa.encrypt.HzPuiPersnSrchDtlVO.PartyType}",
                    OAWebBeanConstants.PRIMARY_CLIENT_ACTION_ATTR,
                    java.lang.String.class));

       params[2]=new Parameter();
       params[2].setKey("HzPuiPartyName");
       params[2].setValueBinding(
         (BoundValue)OAExpressionUtils.handleExpression(pageContext,
                    node2,
                    "${oa.encrypt.HzPuiPersnSrchDtlVO.PartyName}",
                    OAWebBeanConstants.PRIMARY_CLIENT_ACTION_ATTR,
                    java.lang.String.class));

       params[3]=new Parameter();
       params[3].setKey("HzPuiPersonPartyId");
       params[3].setValueBinding(
         (BoundValue)OAExpressionUtils.handleExpression(pageContext,
                    node2,
                    "${oa.encrypt.HzPuiPersnSrchDtlVO.PartyId}",
                    OAWebBeanConstants.PRIMARY_CLIENT_ACTION_ATTR,
                    java.lang.String.class));

       params[4]=new Parameter();
       params[4].setKey("HzPuiPartyId");
       params[4].setValueBinding(
         (BoundValue)OAExpressionUtils.handleExpression(pageContext,
                    node2,
                    "${oa.encrypt.HzPuiPersnSrchDtlVO.RelPartyId}",
                    OAWebBeanConstants.PRIMARY_CLIENT_ACTION_ATTR,
                    java.lang.String.class));

       fireAction.setParameters(params);
       fireAction.setUnvalidated(true);

       node2.setAttributeValue(PRIMARY_CLIENT_ACTION_ATTR, fireAction);
       node2.setAttributeValue(WARN_ABOUT_CHANGES, Boolean.TRUE);
    }



    OASubmitButtonBean submitButtonBean = null;
    //apply the following code only if the attribute is not passed. For a HGRID
    //The query tied to the hgrid get's automatically executed. So if we do not bind
    //all the variables it throws and exception. But if the search results compoenent
    //is used in the context of De Dupe then actual match rule parameter will be
    //passed.

    OAHGridBean hGrid = (OAHGridBean) webBean.findChildRecursive("HzPuiPersonSearchHGrid");
    if ( hGrid != null )
    {
         hGrid.setAutoQuery(false);
    }
    //If the component is used for De-Dupe identification
    if (( "DEDUPE".equals( pageContext.getParameter("HzPuiComponentUsage") ) ) ||
       ( "LOV".equals( pageContext.getParameter("HzPuiComponentUsage") ) ))
    {
         /* Hide separator */
         OASeparatorBean separatorBean = (OASeparatorBean) webBean.findChildRecursive("separator");
         separatorBean.setRendered(false);
         OASpacerBean spacerBean = (OASpacerBean) webBean.findChildRecursive("spacer");
         spacerBean.setWidth(0);

         OAMessageRadioButtonBean selector = (OAMessageRadioButtonBean) webBean.findChildRecursive("HzPuiPersonSelector");
         //For relationsship allow user to select the Contacts/Relationship
         if ( "RELATIONSHIP".equals( pageContext.getParameter("HzPuiDeDupePartyUsage") ) ) {
             hGrid.setAutoExpansionMaxLevels(1);
         }
         else {
             hGrid.setSelectionDisabledBindingAttr("DisableHgridFlag");
         }
         if ( selector != null )
         {
              selector.setRendered(true);
         }
         //Enable the "HzPuiSelectPersonButton" button and disable restof the buttons

         submitButtonBean = (OASubmitButtonBean)webBean.findIndexedChildRecursive("HzPuiSelectPersonButton");
         if( submitButtonBean != null)
         {
             submitButtonBean.setRendered(true);
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
         submitButtonBean = (OASubmitButtonBean)webBean.findIndexedChildRecursive("HzPuiCreate");
         if( submitButtonBean != null)
         {
             submitButtonBean.setRendered(false);
         }

         //Disable the Update Icon Column
         OALinkBean imgBean = (OALinkBean) webBean.findIndexedChildRecursive("Update");
         if( imgBean != null )
         {
             imgBean.setRendered(false);
         }
    }
    else
    {
         /* Disable header when doing search. For ATG */
         headerBean.setHeaderDisabled(true);

         OAMessageRadioButtonBean selector = (OAMessageRadioButtonBean) webBean.findChildRecursive("HzPuiPersonSelector");

         if ( selector != null )
         {
              selector.setRendered(false);
         }
    }
    Diagnostic.println("Inside processRequest - extended part");

        //The profile person dedupe prevention matchrule id
        String sMarkDuplicate = (String) pageContext.getProfile("HZ_MARK_DUPLICATES_ENABLED_FLAG");
        Diagnostic.println("HZ_MARK_DUPLICATES_ENABLED_FLAG = " + sMarkDuplicate );
        //If the mark duplicate is turned off
        if ( !"Y".equals( sMarkDuplicate ) )
        {
             Diagnostic.println("Inside  !'YES'.equals( sMarkDuplicate )" );
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
              Diagnostic.println("Inside !'YES'.equals( sDNBAccess )" );
              submitButtonBean = (OASubmitButtonBean)webBean.findIndexedChildRecursive("HzPuiPurchase");
              if( submitButtonBean != null)
              {
                 submitButtonBean.setRendered(false);
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

      OADBTransactionImpl txImpl = (OADBTransactionImpl) pageContext.getRootApplicationModule().getOADBTransaction();
      txImpl.putTransientValue("HzPuiRelatedOrg", pageContext.getParameter("HzPuiRelatedOrg"));
      txImpl.putTransientValue("HzPuiRelatedOrgId", pageContext.getParameter("HzPuiRelatedOrgId"));

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

    Diagnostic.println("Inside HzPuiDQMPersonSearchCO processFormRequest");

    boolean bRowFound = false;

    OAHGridBean hGrid = (OAHGridBean) webBean.findChildRecursive("HzPuiPersonSearchHGrid");

    if (pageContext.getParameter("HzPuiGoSearch") != null)
    {
        if ( hGrid != null )
        {
            Diagnostic.println("Inside HzPuiDQMPersonSearchCO hGrid Not Found");
            hGrid.clearCache(pageContext);
        }
        else
        {
             Diagnostic.println("Inside HzPuiDQMPersonSearchCO hGrid Found");
        }
    }

    if (pageContext.getParameter("HzPuiGoSearch") != null)
      goButtonPressed(pageContext, webBean);

    OADBTransactionImpl txImpl = (OADBTransactionImpl) pageContext.getRootApplicationModule().getOADBTransaction();
    txImpl.putTransientValue("HzPuiRelatedOrg", pageContext.getParameter("HzPuiRelatedOrg"));
    txImpl.putTransientValue("HzPuiRelatedOrgId", pageContext.getParameter("HzPuiRelatedOrgId"));

    //Check whether user opted to use the existing person.
    //If so make sure at least one of the person parties is seleted
    //before continuing
    if (pageContext.getParameter("HzPuiSelectPersonButton") != null)
    {
        OAHGridQueriedRowEnumerator enum1 = new OAHGridQueriedRowEnumerator(pageContext, hGrid);
        while (enum1.hasMoreElements())
        {
            Row row = (Row)enum1.nextElement();
            if (row != null)
            {
              String selectFlag = (String) row.getAttribute("SelectFlag");
              if ("Y".equals(selectFlag))
              {
                  //identify that the user had selected a row
                  bRowFound = true;
                  String sChildEntity = null;
                  String sPartyId = null;

                  //Set the partyId flag
                  Number nTempValue = (Number)row.getAttribute("PartyId");
                  if ( nTempValue != null )
                  {
                     sPartyId = nTempValue.toString();
                     Diagnostic.println("Value of Party Id - " + sPartyId);
                  }

                  try
                  {
                      sChildEntity = (String) row.getAttribute("RowSelected");
                  }
                  catch( Exception e){
                       Diagnostic.println("Couldn't find Row Selected Column. User selected a Person Party");
                  }
                  pageContext.putParameter("HzPuiSelectedPartyId", sPartyId);

                  //Check whether user have selected a person party or a relationship party
                  if ( "CHILD".equals(sChildEntity))
                  {
                       Diagnostic.println("User selected the Relationship Party");
                       pageContext.putParameter("HzPuiSelectedPartyType", "PARTY_RELATIONSHIP");
                  }
                  else
                  {
                       Diagnostic.println("User selected the Person Party");
                       pageContext.putParameter("HzPuiSelectedPartyType", "PERSON");
                  }
              }
            }
        }
        //Raise and exception is the user han't selected a row
        //Move the exception handling responsibility to the page
        //if (!bRowFound)
        //{
          //OAException e = new OAException("AR", "HZ_PUI_CLASS_SELECT_ERROR");
          //pageContext.putDialog/age(e);
        //}
    }
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
       sContextId = (String)am.invokeMethod("callDQMAPIdynamic", params, classes);

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

      Diagnostic.println("Inside  HzPuiDQMSrchResultsCO. No input error");

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
      Diagnostic.println("Inside  HzPuiDQMSrchResultsCO. Returned AM.callDQMApi");
      Diagnostic.println("Inside  HzPuiDQMSrchResultsCO. Before calling returnResults");
      returnResults(pageContext, webBean, sContextId, null);
    }
  }

  public static String getAppendedString(OADBTransaction tx, String input)
   {
    String inputStr = input;
    String outputStr = null;

    StringBuffer sqlStmt = new StringBuffer();

          sqlStmt.append(" Begin")
                 .append("  hz_dqm_search_util.add_transformation")
                 .append("(NVL(HZ_TRANS_PKG.wrorg_exact(")
                 .append(":1,")
                 .append("null, null,null), :2),'A8',")
                 .append("x_tx_str=>:3")
                 .append(");")
                 .append("  end;");

    Diagnostic.println("stmt: " + sqlStmt.toString());
    OracleCallableStatement cStmt = null;

    try
    {
       cStmt =  (OracleCallableStatement)tx.createCallableStatement(sqlStmt.toString(), 1);
       cStmt.setString(1,inputStr);
       cStmt.setString(2,inputStr);
       cStmt.registerOutParameter(3,OracleTypes.VARCHAR, 0, 500);

       cStmt.execute();
       outputStr = cStmt.getString(3);
    }
    catch(Exception e)
    {
      throw OAException.wrapperException(e);
    }

    finally
    {
      try
      {
        cStmt.close();
      }
      catch(Exception e)
      {
        throw OAException.wrapperException(e);
      }
    }

    return outputStr;
  }


  public StringBuffer getRestrictSql(OAPageContext pageContext)
  {
      Diagnostic.println("getRestrictSql (+)");

      StringBuffer extraClause = new StringBuffer();

      String sSearchPartyType =  pageContext.getParameter("HzPuiSearchPartyType");
/*
      if ("ORGANIZATION".equals(sSearchPartyType))
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

      String sInputWhereClause =  pageContext.getParameter("HzPuiDQMPerSearchExtraWhereClause");
      if (sInputWhereClause != null && !"".equals(sInputWhereClause))
      {
        if (extraClause.length() > 0)
            extraClause.append(" and ");
        extraClause.append(sInputWhereClause);
      }

      Diagnostic.println("restrictSql before org filter: " + extraClause.toString());
      // org filter

      if (!( "DEDUPE".equals( pageContext.getParameter("HzPuiComponentUsage") ) ))
      {
        String sOrgName = pageContext.getParameter("HzPuiRelatedOrg"); //"High Technology";
        Diagnostic.println("sOrgName = " + sOrgName);

        String sOrgId = pageContext.getParameter("HzPuiRelatedOrgId"); //"High Technology";
        Diagnostic.println("sOrgId = " + sOrgId);

        if (sOrgId != null && !"".equals(sOrgId))
        {
          if (extraClause.length() > 0)
            extraClause.append(" and ");

          extraClause.append(" PARTY_ID in ");
          extraClause.append("(select rltns.subject_id from hz_relationships rltns ");
          extraClause.append("where rltns.subject_type = 'PERSON' ");
          extraClause.append(" AND rltns.object_id = ");
          extraClause.append(sOrgId);
          extraClause.append(")");
        }
        else if (sOrgName != null && !"".equals(sOrgName))
        {
          OADBTransaction tx = (OADBTransaction) pageContext.getRootApplicationModule().getTransaction();
          String subString = getAppendedString(tx, sOrgName);

          if (subString != null && !"".equals(subString))
          {
            if (extraClause.length() > 0)
              extraClause.append(" and ");

            extraClause.append(" PARTY_ID in ");
            extraClause.append("(select rltns.subject_id from hz_relationships rltns ");
            extraClause.append("where rltns.subject_type = 'PERSON' ");
            extraClause.append(" AND rltns.object_id in ");

            extraClause.append("(select party_id from hz_staged_parties where contains(concat_col, '");
            extraClause.append(subString);
            extraClause.append(" AND ORGANIZATION')>0))");
          }
        }

        Diagnostic.println("extraClause after org filter = " + extraClause);
      }


      Diagnostic.println("restrictSql: " + extraClause.toString());
      Diagnostic.println("getRestrictSql (-)");
      return extraClause;

  }
  public void returnResults(OAPageContext pageContext, OAWebBean webBean, String sContextId, String sNewPartyId)
  {
    Vector params = new Vector(2);
    //Anirban added on 28-Mar-2008:starts
    String sInputWhereClause =  pageContext.getParameter("HzPuiDQMCustomVORestrictiveClause");

	if(sInputWhereClause==null)
       sInputWhereClause = "";

    pageContext.writeDiagnostics("returnResults API",  "Anirban 28Mar2008 HzPuiDQMCustomVORestrictiveClause is :" + sInputWhereClause , OAFwkConstants.STATEMENT);  
	
	pageContext.writeDiagnostics("returnResults API",  "Anirban 28Mar2008 DQM API CONTEXT ID is :" + sContextId , OAFwkConstants.STATEMENT);   

    StringBuffer extraClause = new StringBuffer(sInputWhereClause);
    //Anirban added on 28-Mar-2008:ends

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
    }
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

