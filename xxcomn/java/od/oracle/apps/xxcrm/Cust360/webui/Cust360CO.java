/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.Cust360.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.webui.beans.layout.OADefaultHideShowBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
//import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.OAFormattedTextBean;
import oracle.apps.fnd.framework.webui.beans.OARawTextBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.Types;
import java.sql.ResultSet;
import oracle.jdbc.driver.OracleCallableStatement;
import java.sql.Array;
import od.oracle.apps.xxcrm.Cust360.server.Cust360AMImpl;
import od.oracle.apps.xxcrm.Cust360.server.CustVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.CaseVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.PriceVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.LoyVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.FinChildVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.FinParentVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.PotentialVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.PotentialDetVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.CampVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.BackOrderVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.CustBillingInfoVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.PastDueInfoVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.TaxExemptVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.StatisticsVOImpl;
import oracle.apps.fnd.framework.OAException;
import oracle.jbo.Row;

/**
 * Controller for ...
 */
public class Cust360CO extends OAControllerImpl
{
  //public static Array ar;
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
    OATableBean tbl = (OATableBean)webBean.findChildRecursive("OrderReg");
    String CustID = pageContext.getParameter("CustID");
    String LoyID = pageContext.getParameter("LoyID");
    if ((CustID != null || LoyID != null) && pageContext.getParameter("DoNotRefresh") == null)
    {
      processdata(pageContext,webBean,CustID,LoyID);
    }
   // Cust360AMImpl custam = (Cust360AMImpl)pageContext.getRootApplicationModule();
  //  tbl.prepareForRendering(pageContext);
   // setTab(rs,custam);
   
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
    processdata(pageContext,webBean,null,null);
}

public void processdata (OAPageContext pageContext, OAWebBean webBean, String CustID, String LoyID)
{
  Cust360AMImpl custam1 = (Cust360AMImpl)pageContext.getRootApplicationModule();
    if ("Y".equals(pageContext.getParameter("contactStrategySelect")))
    {
      custam1.findViewObject("PotentialV").first();
      while(custam1.findViewObject("PotentialV").hasNext())
      {
        if ("Y".equals(custam1.findViewObject("PotentialV").next().getAttribute("SelectionAttr")))
        {
          PotentialDetVOImpl potdetvo = (PotentialDetVOImpl)custam1.findViewObject("PotentialDetV");
          potdetvo.setWhereClauseParam(0,custam1.findViewObject("PotentialV").getCurrentRow().getAttribute("PartySiteId"));
          potdetvo.executeQuery();
          custam1.findViewObject("PotentialV").previous();
          break;
        }
      }
      
    }
    
    PotentialDetVOImpl potdetvo = (PotentialDetVOImpl)custam1.findViewObject("PotentialDetV");
    //potdetvo.executeQuery();
      
    if (pageContext.getParameter("Search") != null || CustID != null || LoyID != null)
    {
    OracleCallableStatement stmt = null;
    try
      {
         OADBTransaction trx = 
                pageContext.getRootApplicationModule().getOADBTransaction();
         stmt = 
             (OracleCallableStatement)trx.createCallableStatement("Begin " + "Cust360( " + 
                            "                           :1, " + 
                            "                           :2, " + 
                            "                           :3, " + 
                            "                           :4, " + 
                            "                           :5, " + 
                            "                           :6, " + 
                            "                           :7, " + 
                            "                           :8, " +
                            "                           :9, " +
                            "                           :10, " +
                            "                           :11, " +
                            "                           :12, " +
                            "                           :13, " +
                            "                           :14, " +
                            "                           :15, " +
                            "                           :16, " +
                            "                           :17, " +
                            "                           :18, " +
                            "                           :19, " +
                            "                           :20, " +
                            "                           :21, " +
                            "                           :22, " +
                            "                           :23, " +
                            "                           :24, " +
                            "                           :25, " +
                            "                           :26, " +
                            "                           :27, " +
                            "                           :28, " +
                            "                           :29, " +
                            "                           :30, " +
                            "                           :31, " +
                            "                           :32, " +
                            "                           :33, " +
                            "                           :34, " +
                            "                           :35, " +
                            "                           :36, " +
                            "                           :37, " +
                            "                           :38, " +
                            "                           :39, " +
                            "                           :40, " +
                            "                           :41, " +
                            "                           :42, " +
                            "                           :43, " +
                            "                           :44, " +
                            "                           :45, " +
                            "                           :46, " +
                            "                           :47,  " +
                            "                           :48,  " +
                            "                           :49,  " +
                            "                           :50,  " +
                            "                           :51,  " +
                            "                           :52,  " +
                            "                           :53,  " +
                            "                           :54, " +
                            "                           :55, " +
                            "                           :56, " +
                            "                           :57, " +
                            "                           :58,  " +
                            "                           :59,  " +
                            "                           :60,  " +
                            "                           :61,  " +
                            "                           :62,  " +
                            "                           :63,  " +
                            "                           :64,  " +
                            "                           :65,  " +
                            "                           :66,  " +
                            "                           :67,  " +
                            "                           :68,  " +
                            "                           :69,  " +
                            "                           :70,  " +
                            "                           :71  " +
                            "                            ); " + 
                            " end;", 1); 
            
             OAMessageTextInputBean AccountReference = (OAMessageTextInputBean)webBean.findChildRecursive("AccountReference");
             OAMessageTextInputBean LoyId = (OAMessageTextInputBean)webBean.findChildRecursive("LoyId");

             if (AccountReference.getValue(pageContext) == null && LoyId.getValue(pageContext) == null && CustID == null && LoyID == null) 
             throw new OAException("Both \"Account Reference\" and \"Loyalty Id\" Cannot Be NULL",OAException.ERROR);
             
             //OAMessageTextInputBean phnum = (OAMessageTextInputBean)webBean.findChildRecursive("phnum");
             OAFormattedTextBean CustInfoBusinessName = (OAFormattedTextBean)webBean.findChildRecursive("CustInfoBusinessName"); 
             OAFormattedTextBean CustInfoPrimaryPhone = (OAFormattedTextBean)webBean.findChildRecursive("CustInfoPrimaryPhone"); 
             OAFormattedTextBean CustInfoStreetAddress1 = (OAFormattedTextBean)webBean.findChildRecursive("CustInfoStreetAddress1"); 
             OAFormattedTextBean CustInfoStreetAddress2 = (OAFormattedTextBean)webBean.findChildRecursive("CustInfoStreetAddress2"); 
             OAFormattedTextBean CustInfoCity = (OAFormattedTextBean)webBean.findChildRecursive("CustInfoCity"); 
             OAFormattedTextBean CustInfoState = (OAFormattedTextBean)webBean.findChildRecursive("CustInfoState"); 
             OAFormattedTextBean CustomerType = (OAFormattedTextBean)webBean.findChildRecursive("CustomerType"); 

             OAFormattedTextBean FirstName = (OAFormattedTextBean)webBean.findChildRecursive("FirstName"); 
             OAFormattedTextBean LastName = (OAFormattedTextBean)webBean.findChildRecursive("LastName"); 
             OAFormattedTextBean InfoCompany = (OAFormattedTextBean)webBean.findChildRecursive("InfoCompany");
             OAFormattedTextBean Ad1 = (OAFormattedTextBean)webBean.findChildRecursive("Ad1"); 
             OAFormattedTextBean Ad2 = (OAFormattedTextBean)webBean.findChildRecursive("Ad2"); 
             OAFormattedTextBean City = (OAFormattedTextBean)webBean.findChildRecursive("City"); 
             OAFormattedTextBean State = (OAFormattedTextBean)webBean.findChildRecursive("State"); 
             OAFormattedTextBean Zip = (OAFormattedTextBean)webBean.findChildRecursive("Zip"); 
             OAFormattedTextBean Phone = (OAFormattedTextBean)webBean.findChildRecursive("Phone"); 
             OAFormattedTextBean Email = (OAFormattedTextBean)webBean.findChildRecursive("Email"); 
             OAFormattedTextBean MembershipType = (OAFormattedTextBean)webBean.findChildRecursive("MembershipType"); 
             OAFormattedTextBean MemberId = (OAFormattedTextBean)webBean.findChildRecursive("MemberId"); 
             OAFormattedTextBean EnrollmentType = (OAFormattedTextBean)webBean.findChildRecursive("EnrollmentType"); 
             OAFormattedTextBean InfoActivated = (OAFormattedTextBean)webBean.findChildRecursive("InfoActivated"); 
             OAFormattedTextBean SegmentId = (OAFormattedTextBean)webBean.findChildRecursive("SegmentId"); 


             OAFormattedTextBean osr = (OAFormattedTextBean)webBean.findChildRecursive("osr"); 
             OAFormattedTextBean ACity = (OAFormattedTextBean)webBean.findChildRecursive("ACity"); 
             OAFormattedTextBean AState = (OAFormattedTextBean)webBean.findChildRecursive("AState"); 
             OAFormattedTextBean ResourceName = (OAFormattedTextBean)webBean.findChildRecursive("ResourceName"); 
             OAFormattedTextBean RepId = (OAFormattedTextBean)webBean.findChildRecursive("RepId"); 
             OAFormattedTextBean RoleCode = (OAFormattedTextBean)webBean.findChildRecursive("RoleCode"); 
             OAFormattedTextBean StartDt = (OAFormattedTextBean)webBean.findChildRecursive("StartDt"); 
             OAFormattedTextBean CustAcctType = (OAFormattedTextBean)webBean.findChildRecursive("CustAcctType"); 
             OARawTextBean FinInfoLabel = (OARawTextBean)webBean.findChildRecursive("FinInfoLabel");

             OARawTextBean AbFlag = (OARawTextBean)webBean.findChildRecursive("AbFlag");
             OARawTextBean RA_TermDescription = (OARawTextBean)webBean.findChildRecursive("RA_TermDescription");
             OARawTextBean Terms = (OARawTextBean)webBean.findChildRecursive("Terms");
             OARawTextBean CollectorId = (OARawTextBean)webBean.findChildRecursive("CollectorId");
             OARawTextBean BillingFrequency = (OARawTextBean)webBean.findChildRecursive("BillingFrequency");
             OARawTextBean ExposureSegment = (OARawTextBean)webBean.findChildRecursive("ExposureSegment");

             FinInfoLabel.setValue(pageContext,"<font size=\"3\"><b><u>FINANCIAL PROFILE</u></b>  "); 
              //OAFormattedTextBean TotOrder = (OAFormattedTextBean)webBean.findChildRecursive("TotOrder"); 

               
            if (CustID != null)
            stmt.setString(1, CustID);
            else
             stmt.setString(1, (String)AccountReference.getValue(pageContext));
            if (LoyID != null)
             stmt.setString(2, LoyID);
            else
             stmt.setString(2, (String)LoyId.getValue(pageContext));
                        
            stmt.setString(3, null);

            stmt.setString(62, "N");
            stmt.setString(63,"");
            stmt.setString(64,"");
            stmt.setString(65,"");
            stmt.setString(66,"");
  

              stmt.registerOutParameter(4, Types.VARCHAR);
              stmt.registerOutParameter(5, Types.VARCHAR);
              stmt.registerOutParameter(6, Types.VARCHAR);
              stmt.registerOutParameter(7, Types.VARCHAR);
              stmt.registerOutParameter(8, Types.VARCHAR);
              stmt.registerOutParameter(9, Types.VARCHAR);
              stmt.registerOutParameter(10, Types.VARCHAR);
              stmt.registerOutParameter(11, Types.VARCHAR);
              stmt.registerOutParameter(12, Types.VARCHAR);
              stmt.registerOutParameter(13, Types.VARCHAR);
              stmt.registerOutParameter(14, Types.VARCHAR);
              stmt.registerOutParameter(15, Types.VARCHAR);
              stmt.registerOutParameter(16, Types.VARCHAR);
              stmt.registerOutParameter(17, Types.VARCHAR);
              stmt.registerOutParameter(18, Types.VARCHAR);
              stmt.registerOutParameter(19, Types.VARCHAR);
              stmt.registerOutParameter(20, Types.VARCHAR);
              stmt.registerOutParameter(21, Types.VARCHAR);
              stmt.registerOutParameter(22, Types.VARCHAR);
              stmt.registerOutParameter(23, Types.VARCHAR);
              stmt.registerOutParameter(24, Types.VARCHAR);
              stmt.registerOutParameter(25, Types.VARCHAR);
              stmt.registerOutParameter(26, Types.VARCHAR);
              stmt.registerOutParameter(27, Types.VARCHAR);
              stmt.registerOutParameter(28, Types.VARCHAR);
              stmt.registerOutParameter(29, Types.VARCHAR);
              stmt.registerOutParameter(30, Types.VARCHAR);
              stmt.registerOutParameter(31, Types.VARCHAR);
              stmt.registerOutParameter(32, Types.VARCHAR);
              stmt.registerOutParameter(33, Types.VARCHAR);
              stmt.registerOutParameter(34, Types.VARCHAR);
              stmt.registerOutParameter(35, Types.VARCHAR);
              stmt.registerOutParameter(36, Types.VARCHAR);
              stmt.registerOutParameter(37, Types.VARCHAR);
              stmt.registerOutParameter(38, Types.VARCHAR);
              stmt.registerOutParameter(39, Types.VARCHAR);
              stmt.registerOutParameter(40, Types.VARCHAR);
              stmt.registerOutParameter(41, Types.VARCHAR);
              stmt.registerOutParameter(42, Types.VARCHAR);
              stmt.registerOutParameter(43, Types.VARCHAR);

              stmt.registerOutParameter(44,Types.ARRAY,"XX_ORDER_DET_OBJ_TBL");
              stmt.registerOutParameter(45,Types.ARRAY,"XX_CASE_DET_OBJ_TBL");
              stmt.registerOutParameter(46,Types.ARRAY,"XX_PRICE_DET_OBJ_TBL");
              stmt.registerOutParameter(47,Types.ARRAY,"XX_LOY_DET_OBJ_TBL");
              stmt.registerOutParameter(48,Types.ARRAY,"XX_FIN_PARENT_OBJ_TBL");
              stmt.registerOutParameter(49,Types.ARRAY,"XX_FIN_CHILD_OBJ_TBL");
              stmt.registerOutParameter(50, Types.VARCHAR);
              stmt.registerOutParameter(51, Types.VARCHAR);
              stmt.registerOutParameter(52, Types.VARCHAR);
              stmt.registerOutParameter(53, Types.VARCHAR);
              stmt.registerOutParameter(54, Types.VARCHAR);
              stmt.registerOutParameter(55, Types.VARCHAR);
              stmt.registerOutParameter(56, Types.VARCHAR);
              stmt.registerOutParameter(57,Types.ARRAY,"XX_EMAIL_CAMP_OBJ_TBL");
              stmt.registerOutParameter(58,Types.ARRAY,"XX_BACK_ORDER_OBJ_TBL");
              stmt.registerOutParameter(59,Types.ARRAY,"XX_BILLING_INFO_OBJ_TBL");
              stmt.registerOutParameter(60,Types.ARRAY,"XX_PAST_DUE_OBJ_TBL");
              stmt.registerOutParameter(61,Types.ARRAY,"XX_TAX_EXEMPT_OBJ_TBL");
              stmt.registerOutParameter(67,Types.ARRAY,"XX_CUST_FROM_LOY_OBJ_TBL");
              stmt.registerOutParameter(68,Types.ARRAY,"XX_CUST_FROM_AOPS_OBJ_TBL");
              stmt.registerOutParameter(69,Types.ARRAY,"XX_CUST_FROM_CDH_OBJ_TBL");
              stmt.registerOutParameter(70,Types.ARRAY,"XX_CUST_BY_PHONE_OBJ_TBL");
              stmt.registerOutParameter(71,Types.ARRAY,"XX_CUST_INFO_META_OBJ_TBL");
              stmt.execute();
              Array ar = stmt.getArray(44);
              ResultSet rs = null;
              //rs = ar.getResultSet();


                 
      Cust360AMImpl custam = (Cust360AMImpl)pageContext.getRootApplicationModule();
      Row statr = null;
             Array custmetaAr = stmt.getArray(71);
             ResultSet custmetaRs = null;
             custmetaRs = custmetaAr.getResultSet();
              StatisticsVOImpl statvo = (StatisticsVOImpl)custam.findViewObject("StatisticsV");
              statvo.executeQuery();
             if(custmetaRs.next())
              {
                java.sql.Struct custmetajdbcStruct=(java.sql.Struct)custmetaRs.getObject(2);
                Object[] custmetaattrs = custmetajdbcStruct.getAttributes();
                if (custmetaattrs[0] != null && custmetaattrs[1] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Customer Information");
                    statr.setAttribute("DataSource",custmetaattrs[0].toString());
                    statr.setAttribute("DataTime", custmetaattrs[1].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[2] != null && custmetaattrs[3] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Customer Order Information");
                    statr.setAttribute("DataSource",custmetaattrs[2].toString());
                    statr.setAttribute("DataTime", custmetaattrs[3].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[4] != null && custmetaattrs[5] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Billing Information");
                    statr.setAttribute("DataSource",custmetaattrs[4].toString());
                    statr.setAttribute("DataTime", custmetaattrs[5].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[6] != null && custmetaattrs[7] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Billing Frequency Information");
                    statr.setAttribute("DataSource",custmetaattrs[6].toString());
                    statr.setAttribute("DataTime", custmetaattrs[7].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[8] != null && custmetaattrs[9] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Finance Information");
                    statr.setAttribute("DataSource",custmetaattrs[8].toString());
                    statr.setAttribute("DataTime", custmetaattrs[9].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[10] != null && custmetaattrs[11] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","PastDue Information");
                    statr.setAttribute("DataSource",custmetaattrs[10].toString());
                    statr.setAttribute("DataTime", custmetaattrs[11].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[12] != null && custmetaattrs[13] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Hierarchy Information");
                    statr.setAttribute("DataSource",custmetaattrs[12].toString());
                    statr.setAttribute("DataTime", custmetaattrs[13].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[14] != null && custmetaattrs[15] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Parent Account Information");
                    statr.setAttribute("DataSource",custmetaattrs[14].toString());
                    statr.setAttribute("DataTime", custmetaattrs[15].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[16] != null && custmetaattrs[17] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Rep Assignment Information");
                    statr.setAttribute("DataSource",custmetaattrs[16].toString());
                    statr.setAttribute("DataTime", custmetaattrs[17].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[18] != null && custmetaattrs[19] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Tax Exempt Information");
                    statr.setAttribute("DataSource",custmetaattrs[18].toString());
                    statr.setAttribute("DataTime", custmetaattrs[19].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[20] != null && custmetaattrs[21] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","TeraData Customer Information");
                    statr.setAttribute("DataSource",custmetaattrs[20].toString());
                    statr.setAttribute("DataTime", custmetaattrs[21].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[22] != null && custmetaattrs[23] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Loyalty Member Enrollment Information");
                    statr.setAttribute("DataSource",custmetaattrs[22].toString());
                    statr.setAttribute("DataTime", custmetaattrs[23].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[24] != null && custmetaattrs[25] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Loyalty Member Purchase Information");
                    statr.setAttribute("DataSource",custmetaattrs[24].toString());
                    statr.setAttribute("DataTime", custmetaattrs[25].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[26] != null && custmetaattrs[27] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","AOPS Contract Pricing Information");
                    statr.setAttribute("DataSource",custmetaattrs[26].toString());
                    statr.setAttribute("DataTime", custmetaattrs[27].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[28] != null && custmetaattrs[29] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","CDH Cust Order Information");
                    statr.setAttribute("DataSource",custmetaattrs[28].toString());
                    statr.setAttribute("DataTime", custmetaattrs[29].toString());

                    statvo.insertRow(statr);
                 }

                 if (custmetaattrs[30] != null && custmetaattrs[31] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Open Cases Information");
                    statr.setAttribute("DataSource",custmetaattrs[30].toString());
                    statr.setAttribute("DataTime", custmetaattrs[31].toString());

                    statvo.insertRow(statr);
                 }

              /*   if (custmetaattrs[32] != null && custmetaattrs[33] != null)
                {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","AOPS Contract Pricing Information");
                    statr.setAttribute("DataSource",custmetaattrs[32].toString());
                    statr.setAttribute("DataTime", custmetaattrs[33].toString());

                    statvo.insertRow(statr);
                 }*/
                
              }
              
              
              
              PotentialVOImpl potvo = (PotentialVOImpl)custam.findViewObject("PotentialV");
              potvo.setWhereClauseParam(0,(String)AccountReference.getValue(pageContext));
              potvo.executeQuery();

              setOrderTab(ar,custam,pageContext,webBean);
              
/*              Cust360PVOImpl pvo = (Cust360PVOImpl)custam.findViewObject("Cust360PVO");
              OARow prow = (OARow)pvo.first();
              prow.setAttribute("FinpRendered",Boolean.FALSE);
              setOrderTab(ar,custam,pageContext,webBean);
  */           

              // Billing Info Details

              Array bilAr = stmt.getArray(59);
              ResultSet bilRs = null;
              bilRs = bilAr.getResultSet();
              CustBillingInfoVOImpl bilvo = (CustBillingInfoVOImpl)custam.findViewObject("CustBillingInfoV");
              bilvo.executeQuery();
              while(bilRs.next())
              {
                Row bilr = bilvo.createRow();
                java.sql.Struct biljdbcStruct=(java.sql.Struct)bilRs.getObject(2);
                Object[] bilattrs = biljdbcStruct.getAttributes();
                if (bilattrs[0] != null)
                  bilr.setAttribute("REPORTING_LOC",bilattrs[0].toString());
                if (bilattrs[1] != null)
                  bilr.setAttribute("SALESPERSON_ID",bilattrs[1].toString());
                if (bilattrs[2] != null)
                  bilr.setAttribute("AR_FLAG",bilattrs[2].toString());
                if (bilattrs[3] != null)
                  bilr.setAttribute("BILL_TO_LIMIT",bilattrs[3].toString());
                if (bilattrs[4] != null)
                  bilr.setAttribute("BILL_TO_DOLLARS",bilattrs[4].toString());
                if (bilattrs[5] != null)
                  bilr.setAttribute("BILL_TO_DOLLAR_EXPIRE",bilattrs[5].toString());
                if (bilattrs[6] != null)
                  bilr.setAttribute("ORDER_LIMIT",bilattrs[6].toString());
                if (bilattrs[7] != null)
                  bilr.setAttribute("LINE_LIMIT",bilattrs[7].toString());
                if (bilattrs[8] != null)
                  bilr.setAttribute("ORDER_REST_IND",bilattrs[8].toString());
                if (bilattrs[9] != null)
                  bilr.setAttribute("ADDR_ORDER_REST_IND",bilattrs[9].toString());
               if (bilattrs[10] != null)
                  bilr.setAttribute("BACKORDER_ALLOW_FLAG",bilattrs[10].toString());
               if (bilattrs[11] != null)
                  bilr.setAttribute("FREIGHT_CHG_REQ_FLAG",bilattrs[11].toString());
               if (bilattrs[12] != null)
                  bilr.setAttribute("CONTRACT_CODE",bilattrs[12].toString());
               if (bilattrs[13] != null)
                  bilr.setAttribute("ADDR_CONTRACT_CODE",bilattrs[13].toString());
               if (bilattrs[14] != null)
                  bilr.setAttribute("PRODUCT_XREF_NBR",bilattrs[14].toString());
               if (bilattrs[15] != null)
                  bilr.setAttribute("PRICE_PLAN",bilattrs[15].toString());
               if (bilattrs[16] != null)
                  bilr.setAttribute("PRICE_PLAN_SEQ",bilattrs[16].toString());
               if (bilattrs[17] != null)
                  bilr.setAttribute("FILLER",bilattrs[17].toString());
                
                  bilvo.insertRow(bilr);

              }

              bilRs.close();


              //Tax Exempt Info

              Array taxAr = stmt.getArray(60);
              ResultSet taxRs = null;
              taxRs = taxAr.getResultSet();
              TaxExemptVOImpl taxvo = (TaxExemptVOImpl)custam.findViewObject("TaxExemptV");
              taxvo.executeQuery();
              while(taxRs.next())         
              {
                Row taxr = taxvo.createRow();
                java.sql.Struct taxjdbcStruct=(java.sql.Struct)taxRs.getObject(2);
                Object[] taxattrs = taxjdbcStruct.getAttributes();
                if (taxattrs[0] != null)
                  taxr.setAttribute("ADDRESS_SEQ",taxattrs[0].toString());
                if (taxattrs[1] != null)
                  taxr.setAttribute("ADDRESS_STATE",taxattrs[1].toString());
                if (taxattrs[2] != null)
                  taxr.setAttribute("COUNTRY_CODE",taxattrs[2].toString());
                if (taxattrs[3] != null)
                  taxr.setAttribute("TAX_CERTIF_NBR",taxattrs[3].toString());
                if (taxattrs[4] != null)
                  taxr.setAttribute("EXP_DATE",taxattrs[4].toString());
                if (taxattrs[5] != null)
                  taxr.setAttribute("GST_EXEMPT_COMMENT",taxattrs[5].toString());
                if (taxattrs[6] != null)
                  taxr.setAttribute("TAX_STATUS",taxattrs[6].toString());
                if (taxattrs[7] != null)
                  taxr.setAttribute("ADDR_SEQ_DENLET",taxattrs[7].toString());
                if (taxattrs[8] != null)
                  taxr.setAttribute("DENIAL_SEND_DATE",taxattrs[8].toString());
                if (taxattrs[9] != null)
                  taxr.setAttribute("LETTER_NOTIF",taxattrs[9].toString());
               if (taxattrs[10] != null)
                  taxr.setAttribute("FEDERAL_EXEMPT",taxattrs[10].toString());  
                  
                  taxvo.insertRow(taxr);

              }

              taxRs.close();

              //Past Due Info

              Array pdueAr = stmt.getArray(61);
              ResultSet pdueRs = null;
              pdueRs = pdueAr.getResultSet();
              PastDueInfoVOImpl pduevo = (PastDueInfoVOImpl)custam.findViewObject("PastDueInfoV");
              pduevo.executeQuery();
              while(pdueRs.next())
              
              {
                Row pduer = pduevo.createRow();
                java.sql.Struct pduejdbcStruct=(java.sql.Struct)pdueRs.getObject(2);
                Object[] pdueattrs = pduejdbcStruct.getAttributes();
                if (pdueattrs[0] != null)
                  pduer.setAttribute("DueDate",pdueattrs[0].toString());
                if (pdueattrs[1] != null)
                  pduer.setAttribute("AmountDueOriginal",pdueattrs[1].toString());
                if (pdueattrs[2] != null)
                  pduer.setAttribute("AmountDueRemaining",pdueattrs[2].toString());
                if (pdueattrs[3] != null)
                  pduer.setAttribute("AcctdAmoundDueRemaining",pdueattrs[3].toString());
                if (pdueattrs[4] != null)
                  pduer.setAttribute("AmountApplied",pdueattrs[4].toString());
                if (pdueattrs[5] != null)
                  pduer.setAttribute("AmountAdjusted",pdueattrs[5].toString());
                if (pdueattrs[6] != null)
                  pduer.setAttribute("AmountInDispute",pdueattrs[6].toString());
                if (pdueattrs[7] != null)
                  pduer.setAttribute("AmountCredited",pdueattrs[7].toString());
                if (pdueattrs[8] != null)
                  pduer.setAttribute("InCollection",pdueattrs[8].toString());
                if (pdueattrs[9] != null)
                  pduer.setAttribute("ActiveClaimFlag",pdueattrs[9].toString());
               if (pdueattrs[10] != null)
                  pduer.setAttribute("DiscountOriginal",pdueattrs[10].toString());
               if (pdueattrs[11] != null)
                  pduer.setAttribute("DiscountRemaining",pdueattrs[11].toString());  
              if (pdueattrs[12] != null)
                  pduer.setAttribute("DiscountTakenEarned",pdueattrs[12].toString());  
                  
                  pduevo.insertRow(pduer);

              }

              pdueRs.close();
              
              


              // Back Order Details

              Array backAr = stmt.getArray(58);
              ResultSet backRs = null;
              backRs = backAr.getResultSet();
              BackOrderVOImpl backvo = (BackOrderVOImpl)custam.findViewObject("BackOrderV");
              backvo.executeQuery();
              while(backRs.next())
              
              {
                Row bor = backvo.createRow();
                java.sql.Struct bojdbcStruct=(java.sql.Struct)backRs.getObject(2);
                Object[] battrs = bojdbcStruct.getAttributes();
                if (battrs[0] != null)
                  bor.setAttribute("OrderId",battrs[0].toString());
                if (battrs[1] != null)
                  bor.setAttribute("TotalOrderAmt",battrs[1].toString());
                if (battrs[2] != null)
                  bor.setAttribute("BackOrderQty",battrs[2].toString());
                if (battrs[3] != null)
                  bor.setAttribute("ItemId",battrs[3].toString());
                if (battrs[4] != null)
                  bor.setAttribute("UnitListPriceAmt",battrs[4].toString());
                if (battrs[5] != null)
                  bor.setAttribute("UnitOriginalPriceAmt",battrs[5].toString());
                if (battrs[6] != null)
                  bor.setAttribute("UnitPoCostAmt",battrs[6].toString());
                if (battrs[7] != null)
                  bor.setAttribute("UnitSellingPriceAmt",battrs[7].toString());
                  
                  backvo.insertRow(bor);

              }

              backRs.close();
              
  
              // Case Management Details

              Array caseAr = stmt.getArray(45);
              ResultSet caseRs = null;
              caseRs = caseAr.getResultSet();
              CaseVOImpl cavo = (CaseVOImpl)custam.findViewObject("CaseV");
              cavo.executeQuery();
              String cases_datasource,cases_fetchtime;
              while(caseRs.next())
              {
                Row car = cavo.createRow();
                java.sql.Struct cajdbcStruct=(java.sql.Struct)caseRs.getObject(2);
                Object[] cattrs = cajdbcStruct.getAttributes();
                if (cattrs[0] != null)
                  car.setAttribute("IncidentNumber",cattrs[0].toString());
                if (cattrs[1] != null)
                  car.setAttribute("PartyName",cattrs[1].toString());
                if (cattrs[2] != null)
                  car.setAttribute("Description",cattrs[2].toString());
                if (cattrs[3] != null)
                  car.setAttribute("IncidentDate",cattrs[3].toString());
                if (cattrs[4] != null)
                  car.setAttribute("CloseDate",cattrs[4].toString());
                if (cattrs[5] != null)
                  car.setAttribute("ResolvedDate",cattrs[5].toString());
                if (cattrs[6] != null)
                  car.setAttribute("Status",cattrs[6].toString());
                if (cattrs[7] != null)
                  car.setAttribute("CSR",cattrs[7].toString());
                if (cattrs[8] != null)
                  car.setAttribute("Sumary",cattrs[8].toString());
                if (cattrs[9] != null)
                  car.setAttribute("Creator",cattrs[9].toString());
                  
                  cavo.insertRow(car);

                   if (cattrs[10] != null && cattrs[11] != null)
                   {
                    statr = statvo.createRow();
                    statr.setAttribute("DataType","Open Cases Information");
                    statr.setAttribute("DataSource",cattrs[10].toString());
                    statr.setAttribute("DataTime", cattrs[11].toString());

                    statvo.insertRow(statr);
                  }
 
              }

              caseRs.close();

              // Contract Pricing Details

              Array priceAr = stmt.getArray(46);
              ResultSet priceRs = null;
              priceRs = priceAr.getResultSet();
              PriceVOImpl prvo = (PriceVOImpl)custam.findViewObject("PriceV");
              prvo.executeQuery();
              String contract_DataSource,contract_fetchTime;
              while(priceRs.next())
              {
                Row prr = prvo.createRow();
                java.sql.Struct prjdbcStruct=(java.sql.Struct)priceRs.getObject(2);
                Object[] prttrs = prjdbcStruct.getAttributes();
                if (prttrs[0] != null)
                  prr.setAttribute("ProductCode",prttrs[0].toString());
                if (prttrs[1] != null)
                  prr.setAttribute("ProductName",prttrs[1].toString());
                if (prttrs[2] != null)
                  prr.setAttribute("SkuPrice",prttrs[2].toString());
                if (prttrs[3] != null)
                  prr.setAttribute("ContractId",prttrs[3].toString());
                if (prttrs[4] != null)
                  prr.setAttribute("AddressSeq",prttrs[4].toString());
                  
                  prvo.insertRow(prr);

                   if (prttrs[5] != null && prttrs[6] != null)
                   {
                     statr = statvo.createRow();
                    statr.setAttribute("DataType","Open Cases Information");
                    statr.setAttribute("DataSource",prttrs[5].toString());
                    statr.setAttribute("DataTime", prttrs[6].toString());

                    statvo.insertRow(statr);
                   }
              }

              priceRs.close();

              // Loy Order Details

              Array loyAr = stmt.getArray(47);
              ResultSet loyRs = null;
              loyRs = loyAr.getResultSet();
              LoyVOImpl lvo = (LoyVOImpl)custam.findViewObject("LoyV");
              lvo.executeQuery();
              while(loyRs.next())
              {
                Row lr = lvo.createRow();
                java.sql.Struct ljdbcStruct=(java.sql.Struct)loyRs.getObject(2);
                Object[] ltrs = ljdbcStruct.getAttributes();
                if (ltrs[0] != null)
                  lr.setAttribute("wlrorderdt",ltrs[0].toString());
                if (ltrs[1] != null)
                  lr.setAttribute("wlrorderid",ltrs[1].toString());
                if (ltrs[2] != null)
                  lr.setAttribute("wlrpuramt",ltrs[2].toString());
                if (ltrs[3] != null)
                  lr.setAttribute("wlrcatrwd",ltrs[3].toString());
                  
                  lvo.insertRow(lr);
              }
              
              loyRs.close();

              // FIN Parent Details
              Array finpAr = stmt.getArray(48);
              ResultSet finpRs = null;
              finpRs = finpAr.getResultSet();
              FinParentVOImpl finpvo = (FinParentVOImpl)custam.findViewObject("FinParentV");
              finpvo.executeQuery();
              while(finpRs.next())
              {
                Row finpr = finpvo.createRow();
                java.sql.Struct finpjdbcStruct=(java.sql.Struct)finpRs.getObject(2);
                Object[] finprs = finpjdbcStruct.getAttributes();
                if (finprs[0] != null)
                  finpr.setAttribute("CustAccountId",finprs[0].toString());
                if (finprs[1] != null)
                  finpr.setAttribute("AccountName",finprs[1].toString());
                if (finprs[2] != null)
                  finpr.setAttribute("Status",finprs[2].toString());
         
                  finpvo.insertRow(finpr);
              }
              
              finpRs.close();

              // FIN Child Details

              Array fincAr = stmt.getArray(49);
              ResultSet fincRs = null;
              fincRs = fincAr.getResultSet();
              FinChildVOImpl fincvo = (FinChildVOImpl)custam.findViewObject("FinChildV");
              fincvo.executeQuery();
              while(fincRs.next())
              {
                Row fincr = fincvo.createRow();
                java.sql.Struct fincjdbcStruct=(java.sql.Struct)fincRs.getObject(2);
                Object[] fincrs = fincjdbcStruct.getAttributes();
                if (fincrs[0] != null)
                  fincr.setAttribute("CustAccountId",fincrs[0].toString());
                if (fincrs[1] != null)
                  fincr.setAttribute("AccountName",fincrs[1].toString());
                if (fincrs[2] != null)
                  fincr.setAttribute("Status",fincrs[2].toString());
         
                  fincvo.insertRow(fincr);
              }
              
              fincRs.close();


              // Email Campaign Details

              Array campAr = stmt.getArray(57);
              ResultSet campRs = null;
              campRs = campAr.getResultSet();
              CampVOImpl campvo = (CampVOImpl)custam.findViewObject("CampV");
              campvo.executeQuery();
              while(campRs.next())
              {
                Row campr = campvo.createRow();
                java.sql.Struct campjdbcStruct=(java.sql.Struct)campRs.getObject(2);
                Object[] camprs = campjdbcStruct.getAttributes();
                if (camprs[0] != null)
                  campr.setAttribute("OrgPartyNum",camprs[0].toString());
                if (camprs[1] != null)
                  campr.setAttribute("CustTypeCode",camprs[1].toString());
                if (camprs[2] != null)
                  campr.setAttribute("OrgName",camprs[2].toString());
                if (camprs[3] != null)
                  campr.setAttribute("PersonPartyNum",camprs[3].toString());
                if (camprs[4] != null)
                  campr.setAttribute("FirstName",camprs[4].toString());
                if (camprs[5] != null)
                  campr.setAttribute("LastName",camprs[5].toString());
                if (camprs[6] != null)
                  campr.setAttribute("EmailAdd",camprs[6].toString());
                if (camprs[7] != null)
                  campr.setAttribute("EmailCampDt",camprs[7].toString());
                if (camprs[8] != null)
                  campr.setAttribute("EmailCampSegCode",camprs[8].toString());
                if (camprs[8] != null)
                  campr.setAttribute("EmailCampZoneCode",camprs[9].toString());
                if (camprs[10] != null)
                  campr.setAttribute("TelCountryCd",camprs[10].toString());
                if (camprs[11] != null)
                  campr.setAttribute("TelAreaCd",camprs[11].toString());
                if (camprs[12] != null)
                  campr.setAttribute("TelNum",camprs[12].toString());
                if (camprs[13] != null)
                  campr.setAttribute("Msg",camprs[13].toString());
         
                  campvo.insertRow(campr);
              }
              
              campRs.close();

              
              CustInfoBusinessName.setValue(pageContext,"<font size=\"2\"><b>Business Name:</b>  " + nvl(stmt.getString(4)));
              CustInfoPrimaryPhone.setValue(pageContext,"<font size=\"2\"><b>Primary Phone:</b>  " + nvl(stmt.getString(5)));
              CustInfoStreetAddress1.setValue(pageContext,"<font size=\"2\"><b>Address1:</b>  " + nvl(stmt.getString(6)));
              CustInfoStreetAddress2.setValue(pageContext,"<font size=\"2\"><b>Address2:</b>  " + nvl(stmt.getString(7)));
              CustInfoCity.setValue(pageContext,"<font size=\"2\"><b>City:</b>  " + nvl(stmt.getString(8)));
              CustInfoState.setValue(pageContext,"<font size=\"2\"><b>State:</b>  " + nvl(stmt.getString(9)));

              FirstName.setValue(pageContext,"<font size=\"2\"><b>First Name:</b>  " + nvl(stmt.getString(14)));
              LastName.setValue(pageContext,"<font size=\"2\"><b>Last Name:</b>  " + nvl(stmt.getString(15)));
              InfoCompany.setValue(pageContext,"<font size=\"2\"><b>Company Info:</b>  " + nvl(stmt.getString(16)));
              Ad1.setValue(pageContext,"<font size=\"2\"><b>Address1:</b>  " + nvl(stmt.getString(17)));
              Ad2.setValue(pageContext,"<font size=\"2\"><b>Address2:</b>  " + nvl(stmt.getString(18)));
              City.setValue(pageContext,"<font size=\"2\"><b>City:</b>  " + nvl(stmt.getString(19)));
              State.setValue(pageContext,"<font size=\"2\"><b>State:</b>  " + nvl(stmt.getString(20)));
              Zip.setValue(pageContext,"<font size=\"2\"><b>Zip:</b>  " + nvl(stmt.getString(21)));
              Phone.setValue(pageContext,"<font size=\"2\"><b>Phone:</b>  " + nvl(stmt.getString(22)));
              Email.setValue(pageContext,"<font size=\"2\"><b>Email:</b>  " + nvl(stmt.getString(23)));
              MembershipType.setValue(pageContext,"<font size=\"2\"><b>Membership Type:</b>  " + nvl(stmt.getString(24)));
              MemberId.setValue(pageContext,"<font size=\"2\"><b>Member ID:</b>  " + nvl(stmt.getString(25)));
              EnrollmentType.setValue(pageContext,"<font size=\"2\"><b>Enrollment Type:</b>  " + nvl(stmt.getString(26)));
              InfoActivated.setValue(pageContext,"<font size=\"2\"><b>Activation Info:</b>  " + nvl(stmt.getString(27)));
              SegmentId.setValue(pageContext,"<font size=\"2\"><b>Segment ID:</b>  " + nvl(stmt.getString(28)));
              osr.setValue(pageContext,"<font size=\"2\"><b>Reference:</b>  " + nvl(stmt.getString(36)));
              ACity.setValue(pageContext,"<font size=\"2\"><b>City:</b>  " + nvl(stmt.getString(37)));
              AState.setValue(pageContext,"<font size=\"2\"><b>State:</b>  " + nvl(stmt.getString(38)));
              ResourceName.setValue(pageContext,"<font size=\"2\"><b>Resource Name:</b>  " + nvl(stmt.getString(39)));
              RepId.setValue(pageContext,"<font size=\"2\"><b>Sales Person ID:</b>  " + nvl(stmt.getString(40)));
              RoleCode.setValue(pageContext,"<font size=\"2\"><b>Role Code:</b>  " + nvl(stmt.getString(41)));
              StartDt.setValue(pageContext,"<font size=\"2\"><b>Start Date:</b>  " + nvl(stmt.getString(42)));
              CustAcctType.setValue(pageContext,"<font size=\"2\"><b>Customer Account Type:</b>  " + nvl(stmt.getString(43)));
              AbFlag.setValue(pageContext,"<font size=\"2\"><b>AB Flag:</b>  " + nvl(stmt.getString(50)));              
              RA_TermDescription.setValue(pageContext,"<font size=\"2\"><b>RA Term Description:</b>  " + nvl(stmt.getString(51)));
              Terms.setValue(pageContext,"<font size=\"2\"><b>Terms:</b>  " + nvl(stmt.getString(52)));
              CollectorId.setValue(pageContext,"<font size=\"2\"><b>Collector Id</b>  " + nvl(stmt.getString(53)));
              BillingFrequency.setValue(pageContext,"<font size=\"2\"><b>Billing Frequency:</b>  " + nvl(stmt.getString(54)));
              ExposureSegment.setValue(pageContext,"<font size=\"2\"><b>Exposure Segment:</b>  " + nvl(stmt.getString(55)));
              CustomerType.setValue(pageContext,"<font size=\"2\"><b>Customer Type:</b>  " + nvl(stmt.getString(56)));
      } 
    
      catch (Exception e) { 
      e.printStackTrace();
      throw new OAException(e.getMessage(),OAException.ERROR);
      }
    }
  }

public String nvl(String var) 
{
  if (var == null) return "";
  else
  return var;
}

public void setOrderTab(Array ar, Cust360AMImpl ami,OAPageContext pageContext, OAWebBean webBean)
{
 try
 {
 CustVOImpl cvo = null;
 ResultSet rst = null;
 OAFormattedTextBean TotOrder = (OAFormattedTextBean)webBean.findChildRecursive("TotOrder"); 
 if (ar != null)
 rst = ar.getResultSet();
  if (ami != null)
  {
  cvo = (CustVOImpl)ami.findViewObject("CustV");
              cvo.executeQuery();
 }
     float OrderTot = 0;      
     if (rst != null)   
     {
              while(rst.next())
              {
                Row r = cvo.createRow();
                java.sql.Struct jdbcStruct=(java.sql.Struct)rst.getObject(2);
                Object[] attrs = jdbcStruct.getAttributes();
                if (attrs[0] != null)
                  r.setAttribute("OrderNumber",attrs[0].toString());
                if (attrs[1] != null)
                  {
                  r.setAttribute("OrderTotal",attrs[1].toString());
                  float iorder = Float.valueOf(attrs[1].toString()).floatValue();
                  OrderTot = OrderTot + iorder;
                  }
                if (attrs[2] != null)
                  r.setAttribute("ShipToRef",attrs[2].toString());
                if (attrs[3] != null)
                  r.setAttribute("SalesRepId",attrs[3].toString());
                if (attrs[4] != null)
                  r.setAttribute("OrderedDate",attrs[4].toString());
                  cvo.insertRow(r);              
              }

              rst.close();
              double multiply = Math.pow(10, 2);
              TotOrder.setValue(pageContext,"<font size=\"3\"><b>Total Order Amount</b></font><font size=\"2\"><i> (Based On Latest 50 Orders) </i> <font size=\"4\"><b>:</b>   $" + Math.ceil(OrderTot*multiply)/multiply);
 }
 }
 catch (Exception e) { 
      e.printStackTrace();
      throw new OAException(e.getMessage(),OAException.ERROR);
      }

}
}
