/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxcrm.Cust360.webui;

import oracle.apps.fnd.common.VersionInfo;
import java.util.HashMap;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import od.oracle.apps.xxcrm.Cust360.server.Cust360AMImpl;
import od.oracle.apps.xxcrm.Cust360.server.AopsSearchVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.CdhSearchVOImpl;
import od.oracle.apps.xxcrm.Cust360.server.LoySearchImpl;
import od.oracle.apps.xxcrm.Cust360.server.SearchByPhoneVOImpl;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.driver.OracleCallableStatement;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import java.sql.Types;
import java.sql.ResultSet;
import java.sql.Array;
import oracle.jbo.Row;

/**
 * Controller for ...
 */
public class CustSearchCO extends OAControllerImpl
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
    super.processRequest(pageContext, webBean);
    
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


    if (pageContext.getParameter("Search") != null)
    {
    Cust360AMImpl custam = (Cust360AMImpl)pageContext.getRootApplicationModule();
    String custName, pareacode,pprefix,pnumber;
    
    OAMessageTextInputBean CustNameV = (OAMessageTextInputBean)webBean.findChildRecursive("CustNameV");
    OAMessageTextInputBean PhoneAreaCodeV = (OAMessageTextInputBean)webBean.findChildRecursive("PhoneNumV");
    OAMessageTextInputBean PhonePrefixV = (OAMessageTextInputBean)webBean.findChildRecursive("PhoneNumV2");
    OAMessageTextInputBean PhoneNumberV = (OAMessageTextInputBean)webBean.findChildRecursive("PhoneNumV3");

    custName     = (String)CustNameV.getValue(pageContext);
    pareacode    = (String)PhoneAreaCodeV.getValue(pageContext);
    pprefix      = (String)PhonePrefixV.getValue(pageContext);
    pnumber      = (String)PhoneNumberV.getValue(pageContext);

    try
      {
         OADBTransaction trx = 
                pageContext.getRootApplicationModule().getOADBTransaction();
         OracleCallableStatement stmt = null;
         stmt = 
             (OracleCallableStatement)trx.createCallableStatement("Begin " + "custSearch360( " + 
                            "                           :1, " + 
                            "                           :2, " +
                            "                           :3, " +
                            "                           :4, " +
                            "                           :5, " +
                            "                           :6, " +
                            "                           :7, " +
                            "                           :8  " +
                            "                            ); " + 
                             " end;", 1); 

           stmt.setString(1, custName);
           stmt.setString(2, pareacode);
           stmt.setString(3, pprefix);
           stmt.setString(4, pnumber);
           stmt.registerOutParameter(5,Types.ARRAY,"XX_CUST_FROM_LOY_OBJ_TBL");
           stmt.registerOutParameter(6,Types.ARRAY,"XX_CUST_FROM_AOPS_OBJ_TBL");
           stmt.registerOutParameter(7,Types.ARRAY,"XX_CUST_FROM_CDH_OBJ_TBL");
           stmt.registerOutParameter(8,Types.ARRAY,"XX_CUST_BY_PHONE_OBJ_TBL");
           stmt.execute();

              Array loyAr = stmt.getArray(5);
              ResultSet loyRs = null;
              loyRs = loyAr.getResultSet();
              LoySearchImpl loyvo = (LoySearchImpl)custam.findViewObject("LoySearchV");
              loyvo.executeQuery();
              while(loyRs.next())
              {
                Row loyr = loyvo.createRow();
                java.sql.Struct loyjdbcStruct=(java.sql.Struct)loyRs.getObject(2);
                Object[] loyattrs = loyjdbcStruct.getAttributes();
                if (loyattrs[0] != null)
                  loyr.setAttribute("MemberId",loyattrs[0].toString());
                if (loyattrs[1] != null)
                  loyr.setAttribute("FirstName",loyattrs[1].toString());
                if (loyattrs[2] != null)
                  loyr.setAttribute("LastName",loyattrs[2].toString());
                if (loyattrs[3] != null)
                  loyr.setAttribute("Company",loyattrs[3].toString());
                if (loyattrs[4] != null)
                  loyr.setAttribute("Address1",loyattrs[4].toString());
                if (loyattrs[5] != null)
                  loyr.setAttribute("Address2",loyattrs[5].toString());
                if (loyattrs[6] != null)
                  loyr.setAttribute("City",loyattrs[6].toString());
                if (loyattrs[7] != null)
                  loyr.setAttribute("State",loyattrs[7].toString());
                if (loyattrs[8] != null)
                  loyr.setAttribute("ZipCode",loyattrs[8].toString());
                if (loyattrs[9] != null)
                  loyr.setAttribute("Country",loyattrs[9].toString());
                if (loyattrs[10] != null)
                  loyr.setAttribute("Phone",loyattrs[10].toString());
                if (loyattrs[11] != null)
                  loyr.setAttribute("Email",loyattrs[11].toString());
                if (loyattrs[12] != null)
                  loyr.setAttribute("AddedDate",loyattrs[12].toString());
                if (loyattrs[13] != null)
                  loyr.setAttribute("ActivatedDate",loyattrs[13].toString());

                  loyvo.insertRow(loyr);

              }

              loyRs.close();


              Array aopsAr = stmt.getArray(6);
              ResultSet aopsRs = null;
              aopsRs = aopsAr.getResultSet();
              AopsSearchVOImpl aopsvo = (AopsSearchVOImpl)custam.findViewObject("AopsSearchV");
              aopsvo.executeQuery();
              while(aopsRs.next())
              {
                Row aopsr = aopsvo.createRow();
                java.sql.Struct aopsjdbcStruct=(java.sql.Struct)aopsRs.getObject(2);
                Object[] aopsattrs = aopsjdbcStruct.getAttributes();
                if (aopsattrs[0] != null)
                  aopsr.setAttribute("CustomerID",aopsattrs[0].toString());
                if (aopsattrs[1] != null)
                  aopsr.setAttribute("BusinessName",aopsattrs[1].toString());
                if (aopsattrs[2] != null)
                  aopsr.setAttribute("StreetAddress1",aopsattrs[2].toString());
                if (aopsattrs[3] != null)
                  aopsr.setAttribute("StreetAddress2",aopsattrs[3].toString());
                if (aopsattrs[4] != null)
                  aopsr.setAttribute("City",aopsattrs[4].toString());
                if (aopsattrs[5] != null)
                  aopsr.setAttribute("State",aopsattrs[5].toString());
                if (aopsattrs[6] != null)
                  aopsr.setAttribute("Province",aopsattrs[6].toString());
                if (aopsattrs[7] != null)
                  aopsr.setAttribute("ZipCode",aopsattrs[7].toString());
                if (aopsattrs[8] != null)
                  aopsr.setAttribute("Country",aopsattrs[8].toString());

                  aopsvo.insertRow(aopsr);

              }

              aopsRs.close();


              Array cdhAr = stmt.getArray(7);
              ResultSet cdhRs = null;
              cdhRs = cdhAr.getResultSet();
              CdhSearchVOImpl cdhvo = (CdhSearchVOImpl)custam.findViewObject("CdhSearchV");
              cdhvo.executeQuery();
              
              while(cdhRs.next())
              {
                Row cdhr = cdhvo.createRow();
                java.sql.Struct cdhjdbcStruct=(java.sql.Struct)cdhRs.getObject(2);
                Object[] cdhattrs = cdhjdbcStruct.getAttributes();
                if (cdhattrs[0] != null)
                  cdhr.setAttribute("CustomerID",cdhattrs[0].toString());
                if (cdhattrs[1] != null)
                  cdhr.setAttribute("BusinessName",cdhattrs[1].toString());
                if (cdhattrs[2] != null)
                  cdhr.setAttribute("StreetAddress1",cdhattrs[2].toString());
                if (cdhattrs[3] != null)
                  cdhr.setAttribute("StreetAddress2",cdhattrs[3].toString());
                if (cdhattrs[4] != null)
                  cdhr.setAttribute("City",cdhattrs[4].toString());
                if (cdhattrs[5] != null)
                  cdhr.setAttribute("State",cdhattrs[5].toString());
                if (cdhattrs[6] != null)
                  cdhr.setAttribute("Province",cdhattrs[6].toString());
                if (cdhattrs[7] != null)
                  cdhr.setAttribute("ZipCode",cdhattrs[7].toString());
                if (cdhattrs[8] != null)
                  cdhr.setAttribute("Country",cdhattrs[8].toString());

                  cdhvo.insertRow(cdhr);

              }

              cdhRs.close();

              Array phoneAr = stmt.getArray(8);
              ResultSet phoneRs = null;
              phoneRs = phoneAr.getResultSet();
              SearchByPhoneVOImpl phonevo = (SearchByPhoneVOImpl)custam.findViewObject("SearchByPhoneV");
              phonevo.executeQuery();
              while(phoneRs.next())
              {
                Row phoner = phonevo.createRow();
                java.sql.Struct phonejdbcStruct=(java.sql.Struct)phoneRs.getObject(2);
                Object[] phoneattrs = phonejdbcStruct.getAttributes();
                if (phoneattrs[0] != null)
                  phoner.setAttribute("CustomerID",phoneattrs[0].toString());
                if (phoneattrs[1] != null)
                  phoner.setAttribute("BusinessName",phoneattrs[1].toString());
                if (phoneattrs[2] != null)
                  phoner.setAttribute("StreetAddress1",phoneattrs[2].toString());
                if (phoneattrs[3] != null)
                  phoner.setAttribute("StreetAddress2",phoneattrs[3].toString());
                if (phoneattrs[4] != null)
                  phoner.setAttribute("City",phoneattrs[4].toString());
                if (phoneattrs[5] != null)
                  phoner.setAttribute("State",phoneattrs[5].toString());
                if (phoneattrs[6] != null)
                  phoner.setAttribute("Province",phoneattrs[6].toString());
                if (phoneattrs[7] != null)
                  phoner.setAttribute("ZipCode",phoneattrs[7].toString());
                if (phoneattrs[8] != null)
                  phoner.setAttribute("Country",phoneattrs[8].toString());

                  phonevo.insertRow(phoner);

              }

              phoneRs.close();
            
      } catch (Exception e) { e.printStackTrace(); }
    }
  }

}
