/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODCustAddrCreateUpdateCO.java                                 |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Page Controller for the Customer Create Address Page                   |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the displaying the Extensible Attributes                 |
 |             in the Create Address Page                                    |
 |  DEPENDENCIES                                                             |
 |    No dependencies.                                                       |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   14-Nov-2007 Jasmine Sujithra   Created                                  |
 |   23-Nov-2007 Jasmine Sujithra   Updated Entity Id to -99999              |
 |   24-Nov-2007 V Jayamohan        Calls autonamed API before page forward  |
 |   27-Nov-2007 Jasmine Sujithra   Removed call to autonamed on cancel      |
 |   27-Dec-2007 Jasmine Sujithra   Used HzPuiAddressPartySiteId             |
 |   03-Jul-2009 Anirban Chaudhuri  Fixed defect# 16097.                     |
 |   14-Jul-2009 Anirban Chaudhuri  Fixed minor issues for defect# 16097.    |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.webui;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.asn.common.customer.webui.CustAddrCreateUpdateCO;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.jbo.Row;


import oracle.sql.*;
import java.sql.SQLException;
import oracle.jdbc.OracleCallableStatement;
import java.sql.Connection;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.apps.fnd.framework.OAApplicationModule;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;

import java.util.Vector;
import oracle.apps.ar.hz.components.util.server.HzPuiServerUtil;
import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAPageButtonBarBean;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.cabo.ui.beans.layout.PageLayoutBean;

import oracle.apps.fnd.framework.webui.beans.OADescriptiveFlexBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;

import od.oracle.apps.xxcrm.asn.common.customer.server.ODPartySiteAccountCheckVOImpl;
import od.oracle.apps.xxcrm.asn.common.customer.server.ODPartySiteAccountCheckVORowImpl;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;


/**
 * Controller for ...
 */
public class ODCustAddrCreateUpdateCO extends ASNControllerObjectImpl
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
    String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCustAddrCreateUpdateCO.processRequest";
    boolean flag = pageContext.isLoggingEnabled(2);
        if(flag)
            pageContext.writeDiagnostics(s, "Begin", 2);
        String addressEvent = pageContext.getParameter("HzPuiAddressEvent");    
        String sPartysiteId =   pageContext.getParameter("HzPuiCreatedPartySiteId");
        String asnreqselsiteid = pageContext.getParameter("ASNReqSelSiteId");
        String asnreqfrmsiteid = pageContext.getParameter("ASNReqFrmSiteId");
        String hzpuipartysiteid = pageContext.getParameter("HzPuiAddressPartySiteId");
        pageContext.writeDiagnostics(s, "HzPuiCreatedPartySiteId : " +sPartysiteId, 2);
        pageContext.writeDiagnostics(s, "ASNReqSelSiteId : " +asnreqselsiteid, 2);
        pageContext.writeDiagnostics(s, "ASNReqFrmSiteId : " +asnreqfrmsiteid, 2);
        pageContext.writeDiagnostics(s, "HzPuiAddressPartySiteId : " +hzpuipartysiteid, 2);
        pageContext.writeDiagnostics(s, "HzPuiAddressEvent : " +addressEvent, 2);

        if (addressEvent.equalsIgnoreCase("CREATE") )
        {
           pageContext.writeDiagnostics(s, "Inside Create HzPuiAddressEvent : " +addressEvent, 2);
          sPartysiteId = "-22222"; //dummy value
        }else if (sPartysiteId == null)
        {
          pageContext.writeDiagnostics(s, "Inside Else Part HzPuiAddressEvent : " +addressEvent, 2);
          sPartysiteId = hzpuipartysiteid;
          if (sPartysiteId == null)
          {
              sPartysiteId = "-22222"; //dummy value
    
          }
        }
    pageContext.writeDiagnostics(s, "HzPuiCreatedPartySiteId : "+sPartysiteId , 2);
    pageContext.putParameter("HzPuiExtEntityId", sPartysiteId); 
    pageContext.putParameter("HzPuiExtMode", "UPDATE");
    
   // pageContext.putParameter("HzPuiExtEntityId", "-99999");
    pageContext.putParameter("HzPuiExtAMPath", "CustAddrCreateUpdateAM");
    pageContext.putParameter("ODSiteAttributeGroup", "Y");
        
        
        super.processRequest(pageContext, webBean);
        retainContextParameters(pageContext);
        ((OAPageLayoutBean)webBean).setBreadCrumbEnabled(false);
        String s1 = pageContext.getParameter("ASNReqFromAddrSelPage");
        if(s1 != null)
        {
            OAPageButtonBarBean oapagebuttonbarbean = (OAPageButtonBarBean)pageContext.getPageLayoutBean().getPageButtons();
            OASubmitButtonBean oasubmitbuttonbean = (OASubmitButtonBean)oapagebuttonbarbean.findIndexedChildRecursive("ASNPageSvCrteAnotherBtn");
            oasubmitbuttonbean.setRendered(false);
        }
        pageContext.getParameter("ASNReqFrmCustId");
        String s2 = pageContext.getParameter("ASNReqFrmCustName");
        String s3 = pageContext.getParameter("HzPuiAddressEvent");
        if(s3 != null && s3.equals("UPDATE"))
        {
            OAPageButtonBarBean oapagebuttonbarbean1 = (OAPageButtonBarBean)pageContext.getPageLayoutBean().getPageButtons();
            OASubmitButtonBean oasubmitbuttonbean1 = (OASubmitButtonBean)oapagebuttonbarbean1.findIndexedChildRecursive("ASNPageSvCrteAnotherBtn");
            oasubmitbuttonbean1.setRendered(false);
            MessageToken amessagetoken1[] = {
                new MessageToken("PARTYNAME", s2)
            };
            String s5 = pageContext.getMessage("ASN", "ASN_TCA_UPDT_ADDR_TITLE", amessagetoken1);
            ((OAPageLayoutBean)webBean).setTitle(s5);
            pageContext.putParameter("ASNReqFrmSiteId",asnreqfrmsiteid); 
        } else
        if(s3 != null && s3.equals("CREATE"))
        {
            MessageToken amessagetoken[] = {
                new MessageToken("PARTYNAME", s2)
            };
            String s4 = pageContext.getMessage("ASN", "ASN_TCA_CRTE_ADDR_TITLE", amessagetoken);
            ((OAPageLayoutBean)webBean).setTitle(s4);
        }


        // Anirban starts the fix for the defect#16097 .

		pageContext.writeDiagnostics(s, "Anirban 3rd July'09 : XX_ASN_ALLOW_VPD_ADDR_UPDATE profile value is :: "+pageContext.getProfile("XX_ASN_ALLOW_VPD_ADDR_UPDATE"), 1);

        if ("Y".equals(pageContext.getProfile("XX_ASN_ALLOW_VPD_ADDR_UPDATE")))
       {
        String checkPartySiteId = sPartysiteId;

		OAApplicationModule am = pageContext.getApplicationModule(webBean);

		OAViewObject ODPartySiteAccountCheckVO = (OAViewObject)am.findViewObject("ODPartySiteAccountCheckVO");
        if ( ODPartySiteAccountCheckVO == null )
	        ODPartySiteAccountCheckVO = (OAViewObject)am.createViewObject("ODPartySiteAccountCheckVO","od.oracle.apps.xxcrm.asn.common.customer.server.ODPartySiteAccountCheckVO");

        if(ODPartySiteAccountCheckVO == null)
        {
	     pageContext.writeDiagnostics(s, "Anirban: ODPartySiteAccountCheckVO is still NULL",  OAFwkConstants.STATEMENT);
	     pageContext.writeDiagnostics(s, "Anirban: checkPartySiteId is : "+checkPartySiteId,  OAFwkConstants.STATEMENT);
	    }

        if ( ODPartySiteAccountCheckVO != null )
	    {
         ODPartySiteAccountCheckVO.setWhereClause(null);
	     ODPartySiteAccountCheckVO.setWhereClauseParams(null);
         ODPartySiteAccountCheckVO.setWhereClauseParam(0, checkPartySiteId);
         ODPartySiteAccountCheckVO.executeQuery();
	     pageContext.writeDiagnostics(s, "Anirban: checkPartySiteId is : "+checkPartySiteId,  OAFwkConstants.STATEMENT);
	    }

		ODPartySiteAccountCheckVORowImpl rowban = (ODPartySiteAccountCheckVORowImpl)ODPartySiteAccountCheckVO.first();

        if(rowban == null)
        {
	     pageContext.writeDiagnostics(s, "Anirban: rowban is NULL",  OAFwkConstants.STATEMENT);
	    }

        if (rowban != null)
        {
         pageContext.writeDiagnostics(METHOD_NAME, "Anirban: inside rowban != null ",  OAFwkConstants.STATEMENT);
         if (rowban.getCustAcctSiteId() != null)
         {
          pageContext.writeDiagnostics(METHOD_NAME, "Anirban: rowban.getCustAcctSiteId() IS NOT NULL !!!",  OAFwkConstants.STATEMENT);

          if(s3 != null && s3.equals("UPDATE"))
	      {

           OADescriptiveFlexBean hzAddressStyleFlex = (OADescriptiveFlexBean)webBean.findChildRecursive("HzAddressStyleFlex");
		   if(hzAddressStyleFlex!=null)
	       {
            hzAddressStyleFlex.setReadOnly(true);
	       }
		   else
	       {
            pageContext.writeDiagnostics(s, "Anirban 3rd July'09 : hzAddressStyleFlex is NULL.", 1);
	       }
		

		   OADescriptiveFlexBean partySiteInformation = (OADescriptiveFlexBean)webBean.findChildRecursive("partySiteInformation");
		   if(hzAddressStyleFlex!=null)
	       {
            partySiteInformation.setReadOnly(true);
	       }
		   else
	       {
            pageContext.writeDiagnostics(s, "Anirban 3rd July'09 : partySiteInformation is NULL.", 1);
	       }

		   OAMessageChoiceBean addrSuggestionPoplist = (OAMessageChoiceBean)webBean.findChildRecursive("addrSuggestionPoplist");
		   if(addrSuggestionPoplist!=null)
	       {
            addrSuggestionPoplist.setReadOnly(true);
	       }
		   else
	       {
            pageContext.writeDiagnostics(s, "Anirban 3rd July'09 : addrSuggestionPoplist is NULL.", 1);
	       }

		   OAMessageLovInputBean hzFlexCountry = (OAMessageLovInputBean)webBean.findChildRecursive("HzFlexCountry");
		   if(hzFlexCountry!=null)
	       {
            hzFlexCountry.setReadOnly(true);
	       }
		   else
	       {
            pageContext.writeDiagnostics(s, "Anirban 3rd July'09 : hzFlexCountry is NULL.", 1);
	       }

		   OAMessageTextInputBean hzAddressee = (OAMessageTextInputBean)webBean.findChildRecursive("hzAddressee");
		   if(hzAddressee!=null)
	       {
            hzAddressee.setReadOnly(true);
	       }
		   else
	       {
            pageContext.writeDiagnostics(s, "Anirban 3rd July'09 : hzAddressee is NULL.", 1);
	       }

		   OALinkBean enabledRemoveIcon = (OALinkBean)webBean.findChildRecursive("EnabledRemoveIcon");
		   if(enabledRemoveIcon!=null)
	       {
            enabledRemoveIcon.setRendered(false);
	       }
		   else
	       {
            pageContext.writeDiagnostics(s, "Anirban 3rd July'09 : enabledRemoveIcon is NULL.", 1);
	       }

		   OAMessageChoiceBean updatable = (OAMessageChoiceBean)webBean.findChildRecursive("Updatable");
		   if(updatable!=null)
	       {
            updatable.setReadOnly(true);
	       }
		   else
	       {
            pageContext.writeDiagnostics(s, "Anirban 3rd July'09 : updatable is NULL.", 1);
	       }

		   OAMessageChoiceBean hzPartySiteStatus = (OAMessageChoiceBean)webBean.findChildRecursive("hzPartySiteStatus");
		   if(hzPartySiteStatus!=null)
	       {
            hzPartySiteStatus.setDisabled(true);
	       }
		   else
	       {
            pageContext.writeDiagnostics(s, "Anirban 14th July'09 : hzPartySiteStatus is NULL.", 1);
	       }

		   OAMessageCheckBoxBean hzPartySitePrimary = (OAMessageCheckBoxBean)webBean.findChildRecursive("hzPartySitePrimary");
		   if(hzPartySitePrimary!=null)
	       {
            hzPartySitePrimary.setDisabled(true);
	       }
		   else
	       {
            pageContext.writeDiagnostics(s, "Anirban 14th July'09 : hzPartySitePrimary is NULL.", 1);
	       }

	      }		//if(s3 != null && s3.equals("UPDATE"))          
         }     // if (rowban.getCustAcctSiteId() != null)    
        }      // if (rowban != null)        
       }//if ("Y".equals(pageContext.getProfile("XX_ASN_ALLOW_VPD_ADDR_UPDATE")))

		// Anirban ends the fix for the defect#16097 .



        if(flag)
            pageContext.writeDiagnostics(s, "End", 2);

  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
        String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCustAddrCreateUpdateCO.processFormRequest";
        boolean flag = pageContext.isLoggingEnabled(2);
        if(flag)
            pageContext.writeDiagnostics(s, "Begin", 2);
        super.processFormRequest(pageContext, webBean);
        String s1 = pageContext.getParameter("ASNReqFrmCustId");
        String s2 = pageContext.getParameter("ASNReqFrmCustName");
        String s3 = pageContext.getParameter("ASNReqFromAddrSelPage");
        pageContext.writeDiagnostics(s, "ASNReqFrmCustId : "+ s1, 2);
        pageContext.writeDiagnostics(s, "ASNReqFrmCustName : "+ s2, 2);
        pageContext.writeDiagnostics(s, "ASNReqFromAddrSelPage : "+ s3, 2);
        
        OAApplicationModule oaapplicationmodule = pageContext.getApplicationModule(webBean);
        HashMap hashmap = new HashMap();

		if(pageContext.getParameter("ASNPageApyBtn") != null)
        {

            if(s3 != null)
            {
                String s4 = null;
                String s5 = null;
                Object obj = null;
                String s7 = null;
                Vector vector = HzPuiServerUtil.getPartySites(pageContext.getApplicationModule(webBean).getOADBTransaction());
                if(vector != null)
                {
                    HashMap hashmap1 = (HashMap)vector.elementAt(vector.size() - 1);
                    s4 = hashmap1.get("PartySiteId").toString();
                    s5 = hashmap1.get("LocationId").toString();
                    s7 = hashmap1.get("Status").toString();
                }
                //doCommit(pageContext);
                oaapplicationmodule.getTransaction().commit();
                if(s7 != null && s7.equals("A"))
                {
                    pageContext.putParameter("ASNReqSelPartySiteId", s4);
                    pageContext.putParameter("ASNReqSelLocationId", s5);
                    Serializable aserializable[] = {
                        s4, s5
                    };
                    String s6 = (String)oaapplicationmodule.invokeMethod("getAddress", aserializable);
                    pageContext.putParameter("ASNReqSelAddress", s6);
                    
                    pageContext.writeDiagnostics(s, "ASNReqSelPartySiteId : "+ s4, 2);
                    pageContext.writeDiagnostics(s, "ASNReqSelLocationId : "+ s5, 2);
                    pageContext.writeDiagnostics(s, "ASNReqSelAddress : "+ s6, 2);
                }
                getWinnerResource(pageContext,webBean);
                processTargetURL(pageContext, null, null);
            } else
            {
                //doCommit(pageContext);
                oaapplicationmodule.getTransaction().commit();
                getWinnerResource(pageContext,webBean);
                processTargetURL(pageContext, null, null);
            }


        } else
        if(pageContext.getParameter("ASNPageSvCrteAnotherBtn") != null)
        {
            //doCommit(pageContext);
            oaapplicationmodule.getTransaction().commit();
            pageContext.removeParameter("HzPuiAddressExist");
            pageContext.removeParameter("HzPuiOrgCompositeExist");
            pageContext.removeParameter("hzCountry");
            hashmap.put("ASNReqFrmCustName", s2);
            hashmap.put("ASNReqFrmCustId", s1);
            hashmap.put("HzPuiAddressPartyId", s1);
            hashmap.put("HzPuiAddressEvent", "CREATE");
            hashmap.put("HzPuiPartySiteId", null);
            hashmap.put("HzPuiLocationId", null);
            hashmap.put("HzPuiPartySiteUseId", null);
            getWinnerResource(pageContext,webBean);
            pageContext.forwardImmediatelyToCurrentPage(hashmap, false, "S");
        } else
        if(pageContext.getParameter("ASNPageCnclBtn") != null)
        {
            //callAutoNamedApi(pageContext,webBean);
            processTargetURL(pageContext, null, null);
        }
        if(flag)
            pageContext.writeDiagnostics(s, "End", 2);

  }


    private void callAutoNamedApi(OAPageContext pageContext, OAWebBean webBean, int resourceId,int roleId, int groupId, String fullAccFlag)
         {
     String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCustAddrCreateUpdateCO.callAutoNamedApi";
         boolean flag = pageContext.isLoggingEnabled(2);
         if(flag)
             pageContext.writeDiagnostics(s, "Begin", 2);
        String HzPuiCreatedPartySiteId = null;
        String mode = pageContext.getParameter("HzPuiAddressEvent");
        if("CREATE".equals(mode))
            HzPuiCreatedPartySiteId =(String)pageContext.getTransactionTransientValue("HzPuiCreatedPartySiteId");
        else if("UPDATE".equals(mode))
            HzPuiCreatedPartySiteId =pageContext.getParameter("ASNReqFrmSiteId");
        pageContext.writeDiagnostics(s, "callAutoNamedApi Mode :"+mode+" HzPuiCreatedPartySiteId : " +HzPuiCreatedPartySiteId , 2);
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
             objStmt.setInt(5,resourceId);
             objStmt.setInt(6,roleId);
             objStmt.setInt(7,groupId);
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
        
    private void getWinnerResource(OAPageContext pageContext, OAWebBean webBean)
         {
     String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCustAddrCreateUpdateCO.getWinnerResource";
         boolean flag = pageContext.isLoggingEnabled(2);
         if(flag)
             pageContext.writeDiagnostics(s, "Begin", 2);
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        String HzPuiCreatedPartySiteId = null;
        int assignedCount = 0;
        String mode = pageContext.getParameter("HzPuiAddressEvent");
        if("CREATE".equals(mode))
             HzPuiCreatedPartySiteId =(String)pageContext.getTransactionTransientValue("HzPuiCreatedPartySiteId");
        else if("UPDATE".equals(mode)){
             HzPuiCreatedPartySiteId =pageContext.getParameter("ASNReqFrmSiteId"); 
             assignedCount = this.isPartySiteAssigned(pageContext,webBean,Integer.parseInt(HzPuiCreatedPartySiteId));
        }
        pageContext.writeDiagnostics(s, "getWinnerResource Mode :"+mode+" HzPuiCreatedPartySiteId : " +HzPuiCreatedPartySiteId , 2);
        if(assignedCount==0){
        StringBuffer hardQry = new StringBuffer();

         hardQry.append("begin XX_TM_TERRITORY_UTIL_PKG.TERR_RULE_BASED_WINNER_LOOKUP(p_party_site_id => :1,p_org_type    => :2,");
         hardQry.append("p_division    => :3,");
         hardQry.append("p_nam_terr_id=> :4,p_resource_id => :5,p_role_id => :6,p_group_id => :7,p_full_access_flag => :8, x_return_status => :9,x_message_data => :10); end;");        
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
             objStmt.setInt(1,Integer.parseInt(HzPuiCreatedPartySiteId));
             objStmt.setString(2,"PROSPECT");
             objStmt.setString(3,"BSD");
             objStmt.registerOutParameter(4,Types.NUMERIC);
             objStmt.registerOutParameter(5,Types.NUMERIC);
             objStmt.registerOutParameter(6,Types.NUMERIC);
             objStmt.registerOutParameter(7,Types.NUMERIC);
             objStmt.registerOutParameter(8,Types.VARCHAR);
             objStmt.registerOutParameter(9,Types.VARCHAR);
             objStmt.registerOutParameter(10,Types.VARCHAR);
             
             objStmt.execute();
             pageContext.writeDiagnostics(s, "After Execute" , 2);

             errCode = objStmt.getString(9);
             errMsg = objStmt.getString(10);
             pageContext.writeDiagnostics(s, "errCode:"+errCode , 2);
             pageContext.writeDiagnostics(s, "errMsg:"+errMsg , 2);
             if(!"S".equals(errCode)){    
                 throw new OAException("The system has encountered an unexpected error while retrieving Rule-based Winners:"+errMsg);
             }
             else{
                 namedTerrId = new Number(objStmt.getInt(4));
                 resourceId = new Number(objStmt.getInt(5));
                 roleId = new Number(objStmt.getInt(6));
                 groupId = new Number(objStmt.getInt(7));
                 fullAccFlag = objStmt.getString(8);
                 callAutoNamedApi(pageContext,webBean,resourceId.intValue(),roleId.intValue(),groupId.intValue(),fullAccFlag);
             }
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
        }
        if(flag)
             pageContext.writeDiagnostics(s, "End", 2);
         }
         
    private int isPartySiteAssigned(OAPageContext pageContext, OAWebBean webBean,int partySiteId)
      {
        String s = "od.oracle.apps.xxcrm.asn.common.customer.webui.ODCustAddrCreateUpdateCO.isPartySiteAssigned";
        pageContext.writeDiagnostics(s, "Begin" , 2);
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        OADBTransaction transaction =  am.getOADBTransaction();
        Connection objConn = transaction.getJdbcConnection();
        StringBuffer objBuff = new StringBuffer();
        objBuff.append(" SELECT COUNT(TERR_ENT.ENTITY_ID) FROM XX_TM_NAM_TERR_DEFN TERR, XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT, XX_TM_NAM_TERR_RSC_DTLS TERR_RSC ");
        objBuff.append(" WHERE TERR.NAMED_ACCT_TERR_ID   = TERR_ENT.NAMED_ACCT_TERR_ID AND TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID AND TERR_ENT.ENTITY_ID = :1 AND ");
        objBuff.append(" sysdate between NVL (TERR.start_date_active,SYSDATE-1) AND NVL (TERR.end_date_active,SYSDATE+1) AND ");
        objBuff.append(" sysdate between NVL (TERR_ENT.start_date_active,SYSDATE-1) AND NVL (TERR_ENT.end_date_active,SYSDATE+1) AND ");
        objBuff.append(" sysdate between NVL (TERR_RSC.start_date_active,SYSDATE-1) AND NVL (TERR_RSC.end_date_active,SYSDATE+1) ");
        objBuff.append(" AND NVL(TERR.status , 'A') = 'A' AND NVL(TERR_ENT.status , 'A') = 'A' AND NVL(TERR_RSC.status , 'A') = 'A' ");
        String sqlQuery = objBuff.toString();
        PreparedStatement objStmt = null;
        int count = 0;
        ResultSet objRs = null;
        try
        {
          objStmt = objConn.prepareStatement(sqlQuery);
          objStmt.setInt(1,partySiteId);
          objRs = objStmt.executeQuery();
          while(objRs.next()){
            count = objRs.getInt(1);
            pageContext.writeDiagnostics(s, "count:"+count , 2);
          }
         
        } catch (SQLException sqle)
        {
            pageContext.writeDiagnostics(s, "Error during Execute:"+sqle.getMessage()+sqle.getStackTrace() , 2);
            sqle.printStackTrace(System.err);
            throw new OAException("The system has encountered an unexpected error while checking if Party Site is pre-assigned. Error Message:"+sqle.getMessage());
        } // end of try-catch
        finally
        {
          try
          {
            objRs.close();
            objStmt.close();
          } catch (SQLException sqle)
          {
              sqle.printStackTrace(System.err);
          } // end of try-catch
        } // end of finally
        pageContext.writeDiagnostics(s, "End" , 2);
        return count;
      }
        


}
