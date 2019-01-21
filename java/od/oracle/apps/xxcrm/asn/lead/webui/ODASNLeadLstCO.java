/*===========================================================================+
 |   Copyright (c) 2001, 2003 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |                                                                           |


 |   05-Jan-2010 Annapoorani Rajaguru   Modified QC 2264                     |
 |						    Adding Prospect/Customer column      |

 |                                                                           |

 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.lead.webui;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import java.io.Serializable;

import java.util.Dictionary;

import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.asn.common.fwk.webui.ASNUIConstants;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
//QC 2264 Annapoorani - Start
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.SQLException;
import oracle.jdbc.OracleCallableStatement;
import oracle.jbo.domain.Number;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OraclePreparedStatement;
//QC 2264 Annapoorani - Start

/**
 * Controller for ASNLeadLstRN
 */
public class ODASNLeadLstCO extends ASNControllerObjectImpl
{
  public static final String RCS_ID="$Header: ASNLeadLstCO.java 115.14.115200.2 2005/05/26 22:03:47 asahoo ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.asn.lead.webui");

  String proCust = null;//QC 2264 Annapoorani
  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    final String METHOD_NAME = "asn.lead.webui.ASNLeadLstCO.processRequest";
    

    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    
    super.processRequest(pageContext, webBean);
		// check whether query needs to be built
    OAApplicationModule queryAM = (OAApplicationModule) pageContext.getApplicationModule(webBean);


    OAMessageStyledTextBean budgetAmtBean = (OAMessageStyledTextBean) webBean.findIndexedChildRecursive("ASNLeadLstBdgtAmt");
    if(budgetAmtBean != null)
    {
      budgetAmtBean.setAttributeValue(OAWebBeanConstants.CURRENCY_CODE, new OADataBoundValueViewObject(budgetAmtBean, "CurrencyCode","LeadSearchVO")); 
    }

		if("Y".equals(pageContext.getParameter("ASNReqLeadBldQry")))
	  {    
        pageContext.putParameter("ASNReqSelectFirstRow", "Y");
		    // execute the query
	      executeLeadsQuery(pageContext, webBean);

      setProspectCust(pageContext, webBean);//QC 2264 Annapoorani

        
	      //indicate that the lead detail is to be refreshed
	      pageContext.putParameter("ASNReqNewSelectionFlag", "Y");

        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" ASNReqLeadBldQry = Y ");
          buf.append(" ASNReqSelectFirstRow = Y ");
          buf.append(" executeLeadsQuery method is called ");
          buf.append(" ASNReqNewSelectionFlag = Y ");
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
         }
         
		}

	 if(OAWebBeanConstants.SORT_EVENT.equals(pageContext.getParameter("event")))
      queryAM.invokeMethod("setLeadFirstRowAsSelected");

	// set lead detail region integration parameters
	String leadId = (String)queryAM.invokeMethod("getSelectedLeadId");
  if(leadId!=null)
   {
     // set the lead detail integration parameters
	    pageContext.putParameter("ASNReqLeadId", leadId);
      if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(100);
        buf.append("leadId = ");
        buf.append(leadId);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
    }

   if (isProcLogEnabled)
   {
     pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);

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

   final String METHOD_NAME = "asn.lead.webui.ASNLeadLstCO.processFormRequest";
   boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
   boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
   if (isProcLogEnabled)
   {
     pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
   }

   super.processFormRequest(pageContext, webBean);

   OAApplicationModule queryAM = (OAApplicationModule) pageContext.getApplicationModule(webBean);

   String asnFwkAct = pageContext.getParameter("ASNReqPgAct");

   if (isStatLogEnabled)
       {
          StringBuffer buf = new StringBuffer(100);
          buf.append("asnFwkAct = ");
          buf.append(asnFwkAct);
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }

	// check whether table view object query needs to be re-built and queried

	if("Y".equals(pageContext.getParameter("ASNReqLeadBldQry")))
  {
	  // execute the query
    // first row is to be selected
    pageContext.putParameter("ASNReqSelectFirstRow", "Y");
    queryAM.invokeMethod("resetQuery");
    executeLeadsQuery(pageContext,webBean);
      setProspectCust(pageContext, webBean);//QC 2264 Annapoorani
 // set lead detail region integration parameters
    String leadId = (String)queryAM.invokeMethod("getSelectedLeadId");
    if(leadId!=null)
     {
  	    // set the lead detail integration parameters
	      pageContext.putParameter("ASNReqLeadId", leadId);
	      pageContext.putParameter("ASNReqNewSelectionFlag", "Y");
    }

	 }

	 // check whether table radio button is selected
	 else if("LEADRDOBTNCHG".equals(asnFwkAct))
   {
    // set lead detail region integration parameters
    String leadId = (String)pageContext.getParameter("ASNReqEvtLeadId");
    if(leadId!=null)
     {
  	    // set the lead detail integration parameters
	      pageContext.putParameter("ASNReqLeadId", leadId);
	      pageContext.putParameter("ASNReqNewSelectionFlag", "Y");
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append("asnFwkAct = LEADRDOBTNCHG");
          buf.append("leadId = ");
          buf.append(leadId);
          buf.append("ASNReqNewSelectionFlag = Y");
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }
      }
	  }
    // handle drill-down events
    else if("CRTELEAD".equals(asnFwkAct))
      {
      pageContext.putParameter("ASNReqNewSelectionFlag", "Y");
      pageContext.putParameter("ASNReqPgAct", "CRTELEAD");

      if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append("asnFwkAct = CRTELEAD");
          buf.append("ASNReqNewSelectionFlag = Y");
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }
        
      this.processTargetURL(pageContext, null, null);
      }
    else if("LEADDET".equals(asnFwkAct))
    {
       String leadId = pageContext.getParameter("ASNReqEvtLeadId");
	    // get the required parameters for the target page
      HashMap urlParams = getFrmParamsFromEvtParams(pageContext);       
	    // set the necessary conditions
      HashMap conditions = new HashMap(2);
      if("Y".equals(pageContext.getTransactionValue("ASNTxnLeadRetainQry")))
      {
        conditions.put(ASNUIConstants.RETAIN_AM, "Y");
      }

      if (isStatLogEnabled)
       {
          StringBuffer buf = new StringBuffer(100);
          buf.append("asnFwkAct = LEADDET");
          buf.append("leadId = ");
          buf.append(leadId);
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
       }
        
	    // forward to the target page
      processTargetURL(pageContext, conditions, urlParams);
     }
     else if("CTCTDET".equals(asnFwkAct) || "CUSTDET".equals(asnFwkAct))
     {
	      // get the required parameters for the target page
        HashMap urlParams = getFrmParamsFromEvtParams(pageContext);       
	      // forward to the target page
         processTargetURL(pageContext, null, urlParams);
     }
    else if("CONVTOPPTY".equals(asnFwkAct))
     {
	      // get the lead id to be converted to opportunity
        String leadId = pageContext.getParameter("ASNReqEvtLeadId");
        String customerId = pageContext.getParameter("ASNReqEvtCustId");      
	      // get the access privilege for the lead
         String leadAcsMd = checkAccessPrivilege(pageContext,
                                                 ASNUIConstants.LEAD_ENTITY,
					                                       leadId,
                                                 false,
                                                  false);		
        if (isStatLogEnabled)
        {
          StringBuffer buf = new StringBuffer(200);
          buf.append(" asnFwkAct = CONVTOPPTY");
          buf.append(" leadId = ");
          buf.append(leadId);
          buf.append(" customerId = ");
          buf.append(customerId);
          buf.append(" leadAcsMd = ");
          buf.append(leadAcsMd);
          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
        }
        
        if(!ASNUIConstants.UPDATE_ACCESS.equals(leadAcsMd))
         {
           throw new OAException("ASN", "ASN_LEAD_CONV_NO_ACSS_ERR");
         }
         // convert the lead to opportunity
         String opptyId = (String)queryAM.invokeMethod("convertToOpportunity", new Serializable[] {leadId});
          if(opptyId!=null)
 	        {
	           this.doCommit(pageContext);
              pageContext.putParameter("ASNReqPgAct", "OPPTYDET");
              HashMap urlParams = new HashMap(3);
              urlParams.put("ASNReqFrmOpptyId", opptyId);
              urlParams.put("ASNReqFrmCustId", customerId);
              
              if (isStatLogEnabled)
               {
                 StringBuffer buf = new StringBuffer(100);
                 buf.append(" opptyId = ");
                 buf.append(opptyId);
                 buf.append(" customerId = ");
                 buf.append(customerId);
                 pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
              }

              this.processTargetURL(pageContext, null, urlParams);
          }
   }

   else if(pageContext.getParameter("ASNLeadLstFuLstButton")!=null)
   {
      HashMap urlParams = new HashMap(2);
      if (isManagerUI(queryAM, pageContext))
       {
         urlParams.put("ASNReqFrmFuncName", "ASN_LEADUWQPG_MGR");

         if (isStatLogEnabled)
          {
            StringBuffer buf = new StringBuffer(100);
            buf.append(" ASNLeadLstFuLstButton is not null ");
            buf.append(" isManagerUI = true ");
            pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
          }
              
         pageContext.forwardImmediately("ASN_LEADUWQPG_MGR",
                                     OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                     null,
                                     urlParams,
                                     false,
                                     OAWebBeanConstants.ADD_BREAD_CRUMB_YES
                                    );
       }
      else
       {

         if (isStatLogEnabled)
          {
            StringBuffer buf = new StringBuffer(100);
            buf.append(" ASNLeadLstFuLstButton is not null ");
            buf.append(" isManagerUI = false ");
            pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
          }
          
         urlParams.put("ASNReqFrmFuncName", "ASN_LEADUWQPG");
         pageContext.forwardImmediately("ASN_LEADUWQPG",
                                     OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                     null,
                                     urlParams,
                                     false,
                                     OAWebBeanConstants.ADD_BREAD_CRUMB_YES
                                    );
         
       }
    }

    

   if (isProcLogEnabled)
   {
     pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);

   }
 }


public void executeLeadsQuery(OAPageContext pageContext, OAWebBean webBean)

{
    final String METHOD_NAME = "asn.lead.webui.ASNLeadLstCO.executeLeadsQuery";
    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);
    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if (isProcLogEnabled)
    {
      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);
    }
    
    OAApplicationModule queryAM = (OAApplicationModule) pageContext.getApplicationModule(webBean);
    boolean selectFirstRow = "Y".equals(pageContext.getParameter("ASNReqSelectFirstRow"));

    Dictionary[] criteriaDicts = (Dictionary[])pageContext.getParameterObject("ASNReqLeadQryCrtra");

    ArrayList renderdVwAttrs = (ArrayList)pageContext.getParameterObject("ASNReqLeadQryVwAttrs");
    String resourceId = (String) getLoginResourceId(queryAM, pageContext);
    ArrayList stdAlnGrpIds = getStandaloneMemberGroupIds(queryAM, pageContext);
	  String managerFlag = isLoginResourceManager(queryAM, pageContext)?"Y":"N";
	  ArrayList mgrGrpIds = getManagerGroupIds(queryAM, pageContext); 
	  ArrayList admnGrpIds = getAdminGroupIds(queryAM, pageContext);
    
    /* Check for mandatory and duplicate rows */
    boolean errorFound = false;
    if (!("DSHBDLNK".equals(pageContext.getParameter("ASNReqLeadQrySrc"))) && (criteriaDicts!=null))
    {
      HashMap criteria = new HashMap(criteriaDicts.length+criteriaDicts.length);
      Dictionary criteriaDict = null;
      String criteriaItemName = null;
      Object value = null;

      //loop through and check for duplicate items for string items and build the hashmap
      for (int i = 0; i < criteriaDicts.length; i++)
       {
         criteriaDict = criteriaDicts[i];
         criteriaItemName = (String)criteriaDict.get(OAViewObject.CRITERIA_ITEM_NAME);
         value = criteriaDict.get(OAViewObject.CRITERIA_VALUE);
         //only string items are checked for duplicate values
         if (!errorFound && value instanceof String)
         {
           //item already in the hashmap generate error
           if (criteria.containsKey(criteriaItemName) && !("ASNLeadLstBdgtAmt".equals(criteriaItemName)))
            {
             errorFound = true;
             pageContext.putDialogMessage(new OAException("ASN","ASN_DUP_SRCH_CRITERIA"));
            }
           //populate the hashmap
           else
             criteria.put(criteriaItemName,value);
          }
           //if error already generated then just populate so required check can run
         else
           criteria.put(criteriaItemName,value);
      } //end loop

     // we dont have to check for required criteria, if lead number is specified
     if (!criteria.containsKey("ASNLeadLstNbr"))
     {
      //first check for manager required fields
      /*VJ: Commenting out to make the page to do the same validation for manager and rep
	  if (isManagerUI(queryAM, pageContext))
      {
        if (!criteria.containsKey("ASNLeadLstStatus"))
        {
          errorFound = true;
          pageContext.putDialogMessage(new OAException("ASN","ASN_SRCH_REQ_STATUS"));
        }
        if (!criteria.containsKey("ASNLeadLstAge"))
        {
          errorFound = true;
          pageContext.putDialogMessage(new OAException("ASN","ASN_SRCH_REQ_AGE"));
        }
      }
      //check required fields for rep
      else 
	  */
	  if (!criteria.containsKey("ASNLeadLstStsCtg"))
      {
         errorFound = true;
         pageContext.putDialogMessage(new OAException("ASN","ASN_SRCH_REQ_STATUS_CATG"));
      } //end check for required fields
    }

    if (criteria.containsKey("ASNLeadLstSlsGrpId") && "Y".equals(managerFlag))
      {
        String groupId = (String)criteria.get("ASNLeadLstSlsGrpId");
        //first check if id selected is in the group arrays if not found then 
        //check if using the validatation VO
        if (!((mgrGrpIds != null && mgrGrpIds.contains(groupId)) 
            ||(stdAlnGrpIds != null && stdAlnGrpIds.contains(groupId))
            ||(admnGrpIds != null && admnGrpIds.contains(groupId))))
         {             
          Serializable[] params = {groupId, resourceId};
          String grpId = (String)queryAM.invokeMethod("validateResourceGroupId", params);
          if (grpId == null || ("".equals(groupId.trim())))
           {
            errorFound = true;
            pageContext.putDialogMessage(new OAException("ASN","ASN_CMMN_SRCH_RSCGRP_INV_ERR"));         
          }
         }     
      }//end check for group ids
  } //end check for duplicate and required fields

    if (!errorFound)
    {
   /* sort information is directly retrieved from view object before building the query, if there is no
     order by clause is available then sorting is done based on age execute the query
     As Dictionary object can not passed to AM method, it will be passed as HashMap  
     object with Key - ASNOpptyQryCrtra */


    HashMap criteriaDictMap = new HashMap(2);  
    criteriaDictMap.put("ASNReqLeadQryCrtra", criteriaDicts);
    HashMap dshBdSrchParams = (HashMap)pageContext.getParameterObject("ASNReqDashSrchParams");   

   // add miscellaneous criteria like login resource id, managerial flag etc..
    HashMap miscSrchParams = new HashMap(8);
    miscSrchParams.put("ASNLoginResourceId", resourceId);

    // pass the group id(s) of the stand alone resource if available
    miscSrchParams.put("ASNStdAlnMmbrGrpIds", stdAlnGrpIds);

  // check whether the login resource is a manager and pass ..
	   miscSrchParams.put("ASNMgrFlag", managerFlag);
	
	// pass the parent group id(s) of managerial resource if available
	   miscSrchParams.put("ASNMgrGrpIds", mgrGrpIds);
	
	// pass the parent group id(s) of administrative resource if available
	   miscSrchParams.put("ASNAdmnGrpIds", admnGrpIds);
	
	// check whether the login resource is a stand-alone member and pass
	   String stdAlnMmbrFlag = isStandaloneMember(queryAM, pageContext)?"Y":"N";
	   miscSrchParams.put("ASNStdAlnMmbrFlag", stdAlnMmbrFlag); 

     String accessOverride = pageContext.getParameter("ASNReqAccessOverride");
     if(accessOverride!=null && !("".equals(accessOverride.trim())))
       miscSrchParams.put("ASNAccessOverride", accessOverride);
      
    String defaultSort = pageContext.getParameter("ASNReqDefaultSort");

     if (isStatLogEnabled)
      {
        StringBuffer buf = new StringBuffer(200);
        buf.append(" resourceId = ");
        buf.append(resourceId);
        buf.append(" managerFlag = ");
        buf.append(managerFlag);
        buf.append(" stdAlnMmbrFlag = ");
        buf.append(stdAlnMmbrFlag);
        buf.append(" accessOverride = ");
        buf.append(accessOverride);
        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);
      }
    
    Serializable[] qryParams = {criteriaDictMap, renderdVwAttrs, dshBdSrchParams, 
                                miscSrchParams, defaultSort };
    Class[] classDef = {HashMap.class, ArrayList.class, HashMap.class, HashMap.class, String.class};

    // execute the Leads query
    queryAM.invokeMethod("initLeadQuery", qryParams, classDef);

    String rowCount = (String)queryAM.invokeMethod("getLeadRowCount");
   // set the lead row count in transaction, so that it can be used in lead detail page
    if(rowCount!=null)
     {
       pageContext.putTransactionValue("ASNTxnLeadRowCount", rowCount);      
     }

  // check whether the first row is to be selected in the table region
   if((selectFirstRow) && (pageContext.getSessionValue("ASNSsnUwqLeadId") == null))
   {
      // set the first row as selected and get the first lead id
      queryAM.invokeMethod("setLeadFirstRowAsSelected");
    } 
  }


   if (isProcLogEnabled)
   {
     pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);

   }
   
 }

    //QC 2264 Annapoorani - Start
public void setProspectCust(OAPageContext pageContext, OAWebBean webBean)
	{
     OAApplicationModule queryAM = (OAApplicationModule) pageContext.getApplicationModule(webBean);
    OAViewObject vo1 = (OAViewObject)queryAM.findViewObject("LeadSearchVO");

	
	OARow row = (OARow) vo1.first();

        	for ( int i =0; i < vo1.getRowCount() ; i++)
          		{
          		OADBTransaction txn = (OADBTransaction) queryAM.getOADBTransaction();
		try 
                			{ 
                			Number custId = (Number)row.getAttribute("CustomerId");
                			OracleResultSet oracleresultset = null;
                			OraclePreparedStatement oraclepreparedstatement = null;
                			String qry = "SELECT decode(count(1),0,'Prospect','Customer') FROM hz_cust_accounts WHERE party_id = "+custId.toString();
                			oraclepreparedstatement = (OraclePreparedStatement)txn.createPreparedStatement(qry, 1);
                			oraclepreparedstatement.execute();
                			oracleresultset = (OracleResultSet)oraclepreparedstatement.getResultSet();
                  		if(oracleresultset.next())
                  			{
                  			proCust = oracleresultset.getString(1);
                  			}
                  		oracleresultset.close();
                  		oraclepreparedstatement.close();   
                  		}
		catch  (SQLException sqle) 
                			{ 
                			throw OAException.wrapperException(sqle);
                			}
		row.setAttribute("ProspectCust",proCust);       
          		if (vo1.hasNext()) row = (OARow) vo1.next();   
                        else vo1.first();
          		}
		    
		}
    //QC 2264 Annapoorani - End
}




