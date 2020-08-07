/*===========================================================================+

 |                       Office Depot - Project Simplify                     |

 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |

 +===========================================================================+

 |  FILENAME                                                                 |

 |             ODASNOpptyLstCO.java                                          |

 |                                                                           |

 |  DESCRIPTION                                                              |

 |    Region Controller class for ASNOpptyQryRN.                             |

 |                                                                           |

 |  NOTES                                                                    |

 |                                                                           |

 |                                                                           |

 |  DEPENDENCIES                                                             |

 |    No dependencies.                                                       |

 |                                                                           |

 |  HISTORY                                                                  |

 |                                                                           |

 |   04-Mar-2008 V.Jayamohan   Created                                       |

 |   05-Jan-2010 Annapoorani Rajaguru   Modified QC 2264                     |
 |						    Adding Prospect/Customer column      |

 |                                                                           |

 +===========================================================================*/

package od.oracle.apps.xxcrm.asn.opportunity.webui;



import java.io.Serializable;

import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;

import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.OAApplicationModule;

import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;

import oracle.apps.fnd.framework.webui.OADataBoundValueViewObject;

import oracle.apps.fnd.framework.OAException;

import com.sun.java.util.collections.HashMap;

import com.sun.java.util.collections.ArrayList;



import oracle.apps.fnd.framework.OAFwkConstants;

import java.util.Dictionary;


import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

import oracle.apps.fnd.framework.OAViewObject;

//QC 2264 Annapoorani - Start
import oracle.apps.fnd.framework.OARow;
import java.sql.SQLException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
//QC 2264 Annapoorani - End

/**

 * Controller for ...

 */

public class ODASNOpptyLstCO extends ASNControllerObjectImpl

{

  public static final String RCS_ID="$Header: ASNOpptyLstCO.java 115.23.115200.2 2005/05/26 22:02:21 asahoo ship $";

  public static final boolean RCS_ID_RECORDED =

        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.asn.opportunity.webui");

  String proCust = null;//QC 2264 Annapoorani

  /**

   * Layout and page setup logic for a region.

   * @param pageContext the current OA page context

   * @param webBean the web bean corresponding to the region

   */
   
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)

  {

    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.opportunity.webui.ODASNOpptyLstCO.processRequest";

    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

  

    if (isProcLogEnabled)

    {

      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

    }



    super.processRequest(pageContext, webBean);

    // Change the UI here.

    OAApplicationModule queryAM = (OAApplicationModule) pageContext.getApplicationModule(webBean);



    // Total actual amount

    OAMessageStyledTextBean damtBean = (OAMessageStyledTextBean) webBean.findIndexedChildRecursive("ASNOpptyLstAmt");

    if(damtBean != null)

      damtBean.setAttributeValue(CURRENCY_CODE, new OADataBoundValueViewObject(damtBean, "CurrencyCode"));

    

    // Total forecast actual amount

    OAMessageStyledTextBean frcstAmtBean = (OAMessageStyledTextBean) webBean.findIndexedChildRecursive("ASNOpptyLstDispFrcstAmt");

    if(frcstAmtBean != null)

      frcstAmtBean.setAttributeValue(CURRENCY_CODE, new OADataBoundValueViewObject(frcstAmtBean, "CurrencyCode"));



    // check whether query needs to be built

   if("Y".equals(pageContext.getParameter("ASNReqOpptyBldQry")))

    {

      // execute the query

      pageContext.putParameter("ASNReqSelectFirstRow", "Y");



      if (isStatLogEnabled)

      {

        StringBuffer buf = new StringBuffer(100);

        buf.append("Call to executeOpptyQuery");

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

      }

      executeOpptyQuery(pageContext,webBean);
      
      setProspectCust(pageContext, webBean);//QC 2264 Annapoorani

      // indicate that the lead detail is to be refreshed

      pageContext.putParameter("ASNReqNewSelectionFlag", "Y");

    }

        

    // set Oppty detail region integration parameters

 	  if(OAWebBeanConstants.SORT_EVENT.equals(pageContext.getParameter("event")))

    {

      if (isStatLogEnabled)

      {

        StringBuffer buf = new StringBuffer(100);

        buf.append("event = SORT_EVENT call to setFirstRowAsCurrentRow");

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

      }

      queryAM.invokeMethod("setFirstRowAsCurrentRow");

    }



    String leadId = (String)queryAM.invokeMethod("getSelectedOpptyId");

    if(leadId!=null)

    {

      // set the lead detail integration parameters

      if (isStatLogEnabled)

      {

        StringBuffer buf = new StringBuffer(100);

        buf.append("ASNReqOpptyId = ");

        buf.append(leadId);

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

      }

      pageContext.putParameter("ASNReqOpptyId", leadId);

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

    final String METHOD_NAME = "od.oracle.apps.xxcrm.asn.opportunity.webui.ODASNOpptyLstCO.processFromRequest";

    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

  

    if (isProcLogEnabled)

    {

      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

    }

    super.processFormRequest(pageContext, webBean);



    OAApplicationModule queryAM = (OAApplicationModule) pageContext.getApplicationModule(webBean);

    String pageEvent = pageContext.getParameter("ASNReqPgAct");



    // check whether table view object query needs to be re-built and queried

    if("Y".equals(pageContext.getParameter("ASNReqOpptyBldQry")))

    {

      // first row is to be selected

      pageContext.putParameter("ASNReqSelectFirstRow", "Y");



      // execute the query



      if (isStatLogEnabled)

      {

        StringBuffer buf = new StringBuffer(100);

        buf.append("Building query - call to resetQuery");

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

      }

      queryAM.invokeMethod("resetQuery");



      if (isStatLogEnabled)

      {

        StringBuffer buf = new StringBuffer(100);

        buf.append("call to executeOpptyQuery");

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

      }

      executeOpptyQuery(pageContext,webBean);

      setProspectCust(pageContext, webBean);//QC 2264 Annapoorani

      //// first row is to be selected

      // set Oppty detail region integration parameters

      String leadId = (String)queryAM.invokeMethod("getSelectedOpptyId");

      if(leadId!=null)

      {

        // set the Oppty detail integration parameters

        pageContext.putParameter("ASNReqOpptyId", leadId);



        pageContext.putParameter("ASNReqNewSelectionFlag", "Y");

        if (isStatLogEnabled)

        {

          StringBuffer buf = new StringBuffer(100);

          buf.append("ASNReqOpptyId");

          buf.append(leadId);

          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

        }



      }

    }

    // check whether table radio button is selected

    else if("OPPTYRDOBTNCHG".equals(pageEvent))

    {

      // set Oppty detail region integration parameters

      String leadId = (String)pageContext.getParameter("ASNReqEvtOpptyId");

      if(leadId!=null)

        {

          // set the lead detail integration parameters

          pageContext.putParameter("ASNReqOpptyId", leadId);

          pageContext.putParameter("ASNReqNewSelectionFlag", "Y");

          if (isStatLogEnabled)

          {

            StringBuffer buf = new StringBuffer(100);

            buf.append("Event =  OPPTYRDOBTNCHG");

            buf.append("ASNReqOpptyId");

            buf.append(leadId);

            pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

          }

        }

      }



    /*

     * Handle main event here.

     * i.e. Event that forwards to other detail page

     */

    else if(pageContext.getParameter("ASNOpptyLstFuLstButton")!=null)

    {

	    // check if it is manager UI

      if (isManagerUI(queryAM, pageContext))

	    {

	      // forward to the lead uwq manager page

        HashMap urlParams = new HashMap(2);

        if (isStatLogEnabled)

        {

          StringBuffer buf = new StringBuffer(100);

          buf.append("Event =  ASNOpptyLstFuLstButton for manager");

          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

        }

        urlParams.put("ASNReqFrmFuncName", "ASN_OPPTYUWQPG_MGR");

      

        pageContext.forwardImmediately("ASN_OPPTYUWQPG_MGR",

                                       OAWebBeanConstants.KEEP_MENU_CONTEXT,

                                       null,

                                       urlParams,

                                       false,

                                       OAWebBeanConstants.ADD_BREAD_CRUMB_YES

                                      );



	    }

	    else

	    {

        HashMap urlParams = new HashMap(2);

        if (isStatLogEnabled)

        {

          StringBuffer buf = new StringBuffer(100);

          buf.append("Event =  ASNOpptyLstFuLstButton for rep");

          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

        }

        urlParams.put("ASNReqFrmFuncName", "ASN_OPPTYUWQPG");

      

        pageContext.forwardImmediately("ASN_OPPTYUWQPG",

                                       OAWebBeanConstants.KEEP_MENU_CONTEXT,

                                       null,

                                       urlParams,

                                       false,

                                       OAWebBeanConstants.ADD_BREAD_CRUMB_YES

                                      );

      }

    }

    // create button clicked    

    if(pageContext.getParameter("ASNPageCrteButton") != null)

    {

      if (isStatLogEnabled)

      {

        StringBuffer buf = new StringBuffer(100);

        buf.append("event = ASNPageCrteButton");

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

      }

      pageContext.putParameter("ASNReqPgAct","CRTEOPPTY");

      this.processTargetURL(pageContext,null,null);

    }



    // opp detail link clicked

    if("OPPTYDET".equals(pageEvent))

    {

      if (isStatLogEnabled)

      {

        StringBuffer buf = new StringBuffer(100);

        buf.append("Event =  OPPTYDET");

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

      }

      HashMap urlParams = this.getFrmParamsFromEvtParams(pageContext);

      processTargetURL(pageContext,null,urlParams);

    }





    // customer detail link clicked

    if("CUSTDET".equals(pageEvent))

    {

      String setSession = pageContext.getParameter("ASNReqEvtSession");

      if (!("Y".equals(setSession)))

      {

        if (isStatLogEnabled)

        {

          StringBuffer buf = new StringBuffer(100);

          buf.append("Event =  CUSTDET");

          pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

        }

        HashMap urlParams = this.getFrmParamsFromEvtParams(pageContext);

        processTargetURL(pageContext,null, urlParams);

      }

    }



    // contact detail link clicked

    if("CTCTDET".equals(pageEvent))

    {

      if (isStatLogEnabled)

      {

        StringBuffer buf = new StringBuffer(100);

        buf.append("Event =  CTCTDET");

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

      }

      HashMap urlParams = this.getFrmParamsFromEvtParams(pageContext);

      processTargetURL(pageContext,null, urlParams);

    }

        

    if (isProcLogEnabled)

    {

      pageContext.writeDiagnostics(METHOD_NAME, "End", OAFwkConstants.PROCEDURE);

    }

 }

 

        

  public void executeOpptyQuery(OAPageContext pageContext, OAWebBean webBean)

  {



    final String METHOD_NAME = "asn.opportunity.webui.ASNOpptyLstCO.executeLeadsQuery";

    boolean isProcLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE);

    boolean isStatLogEnabled = pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT);

    if (isProcLogEnabled)

    {

      pageContext.writeDiagnostics(METHOD_NAME, "Begin", OAFwkConstants.PROCEDURE);

    }

    OAApplicationModule queryAM = (OAApplicationModule) pageContext.getApplicationModule(webBean);

    boolean selectFirstRow = "Y".equals(pageContext.getParameter("ASNReqSelectFirstRow"));

    Dictionary[] criteriaDicts = (Dictionary[])pageContext.getParameterObject("ASNOpptyQryCrtra");

    ArrayList renderdVwAttrs = (ArrayList)pageContext.getParameterObject("ASNOpptyQryVwAttrs");

    // sort information is directly retrieved from view object before building the query, if there is no

    // order by clause is available then sorting is done based on age

    // execute the query

    // As Dictionary object can not passed to AM method, it will be passed as HashMap  

    // object with Key - ASNOpptyQryCrtra 

    

    HashMap criteriaDictMap = new HashMap(2);

    criteriaDictMap.put("ASNOpptyQryCrtra", criteriaDicts);

    HashMap dshBdSrchParams = (HashMap)pageContext.getParameterObject("ASNReqDashSrchParams");

    // add miscellaneous criteria like login resource id, managerial flag etc..

    // check whether the login resource is a manager and pass ..

    HashMap miscSrchParams = new HashMap(6);



    // pass the parent group id(s) of managerial resource if available

    ArrayList mgrGrpIds = getManagerGroupIds(queryAM, pageContext);

    // pass the parent group id(s) of administrative resource if available

    ArrayList admnGrpIds = getAdminGroupIds(queryAM, pageContext);

    // get the group id(s) of standalone resource if available

    ArrayList stdAlnGrpIds = getStandaloneMemberGroupIds(queryAM, pageContext);

    String isManagerFlag = isLoginResourceManager(queryAM, pageContext)?"Y":"N";

    String resourceId = (String) getLoginResourceId(queryAM, pageContext);



    boolean errorFound = false; 

    //begin check for duplicate and required criteria

    if (!("DSHBDLNK".equals(pageContext.getParameter("ASNReqOpptyQrySrc")))&&(criteriaDicts!=null))

    {

      if (isStatLogEnabled)

      {

        StringBuffer buf = new StringBuffer(100);

        buf.append("begin check for duplicate and required criteria");

        buf.append("criteriaDicts = ");

        buf.append(criteriaDicts);       

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

      }

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

        if (!errorFound&&value instanceof String)

        {

          //if item already in the hashmap generate error

          if (criteria.containsKey(criteriaItemName)

              &&!("ASNOpptyLstAmt".equals(criteriaItemName))

              &&!("ASNOpptyLstWinProb".equals(criteriaItemName))

              &&!("ASNOpptyLstFrcstAmt".equals(criteriaItemName)))

          {

            errorFound = true;

            pageContext.putDialogMessage(new OAException("ASN","ASN_DUP_SRCH_CRITERIA"));

          }

          //populate the hashmap

          else

          {

            criteria.put(criteriaItemName,value);

          }

        }

        //if error already generated then just populate so required check can run

        else

        {

          criteria.put(criteriaItemName,value);

        }

      }//end loop

      //begin check for required fields

      //first check for manager

      if (!(criteria.containsKey("ASNOpptyLstNbr")))

      {

        /*Removing the logic specific to MANAGER

		if (isManagerUI(queryAM, pageContext))

        {

          if (!criteria.containsKey("ASNOpptyLstDateRange"))

          {

            errorFound = true;

            pageContext.putDialogMessage(new OAException("ASN","ASN_SRCH_REQ_PRD_CL_DATE"));

          }

          if (!criteria.containsKey("ASNOpptyLstStatMgr"))

          {

            errorFound = true;

            pageContext.putDialogMessage(new OAException("ASN","ASN_SRCH_REQ_STATUS"));

          }

        }

        //check required fields for rep

        else 

		*/



		if (!criteria.containsKey("ASNOpptyLstStCatgCode"))

        {

          errorFound = true;

          pageContext.putDialogMessage(new OAException("ASN","ASN_SRCH_REQ_STATUS_CATG"));

        }//end check for required fields

      }

      //check for manager's group

      if (criteria.containsKey("ASNOpptyLstSlsGrpId") && "Y".equals(isManagerFlag))

      {

        String groupId = (String)criteria.get("ASNOpptyLstSlsGrpId");

        //first check if id selected is in the group arrays if not found then 

        //check if using the validatation VO

        if (!((mgrGrpIds != null && mgrGrpIds.contains(groupId)) 

              ||(stdAlnGrpIds != null && stdAlnGrpIds.contains(groupId))

              ||(admnGrpIds != null  && admnGrpIds.contains(groupId))))

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

    }//end check for duplicate and required fields



    //if error is generated do not build query

    if (!errorFound) 

    {



      // pass the parent group id(s) of managerial resource if available

      miscSrchParams.put("ASNMgrGrpIds", mgrGrpIds);

      // pass the parent group id(s) of administrative resource if available

      miscSrchParams.put("ASNAdmnGrpIds", admnGrpIds);

      // pass the group id(s) of standalone resource if available

      miscSrchParams.put("ASNStdAlnMmbrGrpIds", stdAlnGrpIds);

      miscSrchParams.put("ASNManagerFlag", isManagerFlag );

      miscSrchParams.put("ASNLoginResourceId", resourceId);

	

	

      // check whether the login resource is a stand-alone member and pass

	    String stdAlnMmbrFlag = isStandaloneMember(queryAM, pageContext)?"Y":"N";

      miscSrchParams.put("ASNStdAlnMmbrFlag", stdAlnMmbrFlag);

  

      if (pageContext.getParameter("ASNReqAccessOverride") != null)

        miscSrchParams.put("ASNAccessOverride", pageContext.getParameter("ASNReqAccessOverride").trim());



      String sort = pageContext.getParameter("ASNReqOpptyDefaultSort");

      Boolean defaultSort = Boolean.TRUE;

      if("N".equals(sort))

      {

        defaultSort= Boolean.FALSE;

      }

      Serializable[] qryParams = { criteriaDictMap

                                 , renderdVwAttrs

                                 , dshBdSrchParams

                                 , miscSrchParams

                                 , defaultSort};

      Class[] classDef = { HashMap.class

                         , ArrayList.class

                         , HashMap.class

                         , HashMap.class

                         , Boolean.class };

      // execute the Oppty query

      if (isStatLogEnabled)

      {

        StringBuffer buf = new StringBuffer(100);

        buf.append("call to initOpptyQuery");

        buf.append("criteriaDictMap = ");

        buf.append(criteriaDictMap);       

        buf.append("renderdVwAttrs = ");

        buf.append(renderdVwAttrs);       

        buf.append("dshBdSrchParams = ");

        buf.append(dshBdSrchParams);       

        buf.append("miscSrchParams = ");

        buf.append(miscSrchParams);       

        buf.append("defaultSort = ");

        buf.append(defaultSort);       

        pageContext.writeDiagnostics(METHOD_NAME, buf.toString(), OAFwkConstants.STATEMENT);

      }

      queryAM.invokeMethod("initOpptyQuery", qryParams, classDef);

      // check whether the first row is to be selected in the table region

      if((selectFirstRow) && (pageContext.getSessionValue("ASNSsnUWQOpptyId") == null))

      {

        // set the first row as selected and get the first lead id

        queryAM.invokeMethod("setFirstRowAsCurrentRow");

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
         	OAViewObject vo1 = (OAViewObject)queryAM.findViewObject("OpptySearchVO1");
          
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

