/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
package od.oracle.apps.xxfin.ap.idms.contactaddress.webui;

import java.io.Serializable;

import java.sql.Connection;

import java.sql.PreparedStatement;

import java.sql.ResultSet;

import java.util.Hashtable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.form.OAExportBean;

import oracle.jbo.Row;

/**
 * Controller for ...
 */
public class XXApSupplierContactsPGCO extends OAControllerImpl {
    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    /**
     * Layout and page setup logic for a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {
        super.processRequest(pageContext, webBean);
        OAApplicationModule mainAM = 
            (OAApplicationModule)pageContext.getApplicationModule(webBean);
        OAViewObject XxApVendorContactVO = 
            (OAViewObject)mainAM.findViewObject("XxVendorContactVO1");
        OASubmitButtonBean CreateT = 
            (OASubmitButtonBean)webBean.findChildRecursive("Create");
        CreateT.setDisabled(true);
        OAExportBean ExportT = 
            (OAExportBean)webBean.findChildRecursive("Export");
        ExportT.setDisabled(true);

        OASubmitButtonBean SaveT = 
            (OASubmitButtonBean)webBean.findChildRecursive("Save");
        SaveT.setDisabled(true);
        OASubmitButtonBean CancelT = 
            (OASubmitButtonBean)webBean.findChildRecursive("Cancel");
        CancelT.setDisabled(true);

        System.out.println("Responsibility ID" + 
                           pageContext.getResponsibilityId());
                           
        System.out.println("Responsibility Name" + 
                           pageContext.getResponsibilityName());
                           
        String respname = pageContext.getResponsibilityName();
        
        if("OD SCM Supplier Setup".equals(respname)) { 
       // if("System Administrator".equals(respname)) { 
            OAViewObject XxApSupplierLov = 
                (OAViewObject)mainAM.findViewObject("XxApSupplierLovVO1");
           String where = "1=1";
                where = where + " AND pay_site_flag = '" + "Y" + "'";
                XxApSupplierLov.setWhereClause(where);
            System.out.println("XxApSupplierLov query " +XxApSupplierLov.getQuery());
            }

        

    }

    /**
     * Procedure to handle form submissions for form elements in
     * a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processFormRequest(OAPageContext pageContext, 
                                   OAWebBean webBean) {
        super.processFormRequest(pageContext, webBean);

        OAApplicationModule mainAM = 
            (OAApplicationModule)pageContext.getApplicationModule(webBean);
        OAViewObject XxApVendorContactVO = 
            (OAViewObject)mainAM.findViewObject("XxVendorContactVO1");

        OAViewObject XxAddressTypeVO = 
            (OAViewObject)mainAM.findViewObject("XxApAddressTypeVO1");


        if (pageContext.isLovEvent()) {
            String lovInputSourceId = pageContext.getLovInputSourceId();
            System.out.println("lovInputSourceId " + lovInputSourceId);
            if("Address".equals(lovInputSourceId)) {  
                             System.out.println("Inside isLovEvent of Address");  
                             Hashtable lovResults = pageContext.getLovResultsFromSession(pageContext.getParameter(SOURCE_PARAM));  
                             if(lovResults!=null)  
                             {  
                                  String addtypeId =(String)lovResults.get("formAddrTypeId"); 
                                  System.out.println("formAddrTypeId:" + addtypeId);
                                 String rowReference = pageContext.getParameter(EVENT_SOURCE_ROW_REFERENCE);
                                 if (rowReference != null) {
                                     OARow currRow = 
                                         (OARow)mainAM.findRowByRef(rowReference);
                                     if (currRow != null) {
                                      System.out.println("inside row not null");                          
                                      currRow.setAttribute("AddrTypeId",addtypeId);  
                                  }
                                                         
                             }
                        }
            }
            
            if ("ContactType".equals(lovInputSourceId)) {
                System.out.println("Inside isLovEvent of Address ");
                Hashtable lovResults = 
                    pageContext.getLovResultsFromSession(pageContext.getParameter(SOURCE_PARAM));
                if (lovResults != null) {
                    String addressval = 
                        (String)lovResults.get("ContactType");
                    String addtypeId =(String)lovResults.get("formAddrTypeId"); 
                    System.out.println("Address value :" + addressval+"--------Type ID: "+addtypeId);
                    String rowReference = 
                        pageContext.getParameter(EVENT_SOURCE_ROW_REFERENCE);
                    if (rowReference != null) {
                        OARow currRow = 
                            (OARow)mainAM.findRowByRef(rowReference);
                        if (currRow != null) {
                            oracle.jbo.domain.Number attrValue = 
                                (oracle.jbo.domain.Number) currRow.getAttribute("AddrType");
                            System.out.println("Attribute Value -> " + 
                                               attrValue);
                            Integer seqnum = 0;
                            String Supplier = 
                                (String)pageContext.getParameter("Supplier");
                            try {
                                Connection conn = 
                                    pageContext.getApplicationModule(webBean).getOADBTransaction().getJdbcConnection();
                                String query = 
                                    "select NVL(MAX(SEQ_NO)+1,1) SEQ_NO from XX_AP_SUP_VENDOR_CONTACT where Key_Value_1=" + 
                                    Supplier + " AND ADDR_TYPE_ID = " + addtypeId;
                                PreparedStatement stmt = 
                                    conn.prepareStatement(query);
                                // String resultset = stmt.executeQuery().toString();
                                ResultSet resultset = stmt.executeQuery();
                                resultset.next();
                                System.out.println("Seq Number is " + 
                                                   resultset.getInt("SEQ_NO"));
                                seqnum = resultset.getInt("SEQ_NO");
                            } catch (Exception e) {
                                throw OAException.wrapperException(e);
                            }
                            Integer intObj = new Integer(seqnum);
                            if (seqnum > 1) {
                                try {
                                    Connection conn = 
                                        pageContext.getApplicationModule(webBean).getOADBTransaction().getJdbcConnection();
                                    String query = 
                                        "UPDATE XX_AP_SUP_VENDOR_CONTACT SET Primary_Addr_Ind = 'N' where Key_Value_1=" + 
                                        Supplier + " AND ADDR_TYPE_ID = " + 
                                        addtypeId + " AND SEQ_NO < " + seqnum;
                                    PreparedStatement stmt = 
                                        conn.prepareStatement(query);
                                    // String resultset = stmt.executeQuery().toString();
                                    stmt.executeUpdate();
                                    //   mainAM.getOADBTransaction().commit();
                                    System.out.println("inside try of update");
                                } catch (Exception e) {
                                    System.out.println("exception while updating primary add flag " + 
                                                       e);
                                    throw OAException.wrapperException(e);
                                }
                            }
                            Number snum = (Number)intObj;
                            currRow.setAttribute("SeqNo", snum);
                            currRow.setAttribute("AddrTypeId",addtypeId);  
                        }
                    }
                }
            }
        }

        OASubmitButtonBean CreateT = 
            (OASubmitButtonBean)webBean.findChildRecursive("Create");
        CreateT.setDisabled(true);
        OAExportBean ExportT = 
            (OAExportBean)webBean.findChildRecursive("Export");
        ExportT.setDisabled(true);

        OASubmitButtonBean SaveT = 
            (OASubmitButtonBean)webBean.findChildRecursive("Save");

        OASubmitButtonBean CancelT = 
            (OASubmitButtonBean)webBean.findChildRecursive("Cancel");
        CancelT.setDisabled(true);

        if (pageContext.getParameter("Save") != null) {
            try {
                CreateT.setDisabled(false);
                ExportT.setDisabled(false);

                CancelT.setDisabled(false);


                String Supplier = (String)pageContext.getParameter("Supplier");
                Serializable[] params = { Supplier };

                mainAM.invokeMethod("updateTelex", params);
                System.out.println("Supplier Number is:  " + Supplier);

                System.out.println("Save");
                mainAM.getOADBTransaction().commit();
                String where = "1=1";
                String addresstype = 
                    (String)pageContext.getParameter("Address");

                if (addresstype != null && !"".equals(addresstype)) {
                    where = where + " AND addr_type='" + addresstype + "'";

                }


                if (Supplier != null && !"".equals(Supplier)) {

                    where = where + " AND key_value_1='" + Supplier + "'";
                }

                XxApVendorContactVO.setWhereClause(where);
                System.out.println(where);

                XxApVendorContactVO.executeQuery();


                XxApVendorContactVO.first();
                for (int i = 0; i < XxApVendorContactVO.getRowCount(); i++) {
                    XxApVendorContactVO.getCurrentRow().setAttribute("DisableTrans", 
                                                                     Boolean.TRUE);
                    XxApVendorContactVO.next();
                }


                throw new OAException("Record(s) Saved Successfully", 
                                      OAException.CONFIRMATION);
            } catch (Exception e) {
                throw OAException.wrapperException(e);
            }


        }

        if (pageContext.getParameter("Cancel") != null) {
            CreateT.setDisabled(false);
            ExportT.setDisabled(false);
            // UpdateT.setDisabled(false);
            // DeleteT.setDisabled(false);
            SaveT.setDisabled(false);
            CancelT.setDisabled(false);
            System.out.println("Roll Back");
            mainAM.getOADBTransaction().rollback();
        }
        String where = "1=1";
        if (pageContext.getParameter("Go") != null) {

            CreateT.setDisabled(false);
            ExportT.setDisabled(false);
            // UpdateT.setDisabled(false);
            // DeleteT.setDisabled(false);
            SaveT.setDisabled(false);
            CancelT.setDisabled(false);
            String Supplier = (String)pageContext.getParameter("Supplier");
            //String SupplierName = (String)pageContext.getParameter("SuppNumber");
             String SupplierName = (String)pageContext.getParameter("SupplierNam");
            if ((Supplier == null && "".equals(Supplier)) ||(SupplierName == null && "".equals(SupplierName)) ) 
            {
                throw new OAException("Please provide either Supplier Number or Name", 
                                      OAException.ERROR);

            }
            try {
                String addresstype = 
                    (String)pageContext.getParameter("Address");
                
                //  where="addr_type=:1 AND attribute1 IS NULL OR attribute1 <> 'D' "; 
                // where="addr_type= '"+addresstype+"' AND attribute1 IS NULL OR attribute1 <> 'D' ";
                if (addresstype != null && !"".equals(addresstype)) {
                    where = where + " AND addr_type='" + addresstype + "'";

                }


                if (Supplier != null && !"".equals(Supplier)) {

                    where = where + " AND key_value_1='" + Supplier + "'";
                }
                // key_value_1=NVL(:2,key_value_1) AND 

                // where = where + "AND (attribute1 IS NULL OR attribute1 <> 'D')";
                XxApVendorContactVO.setWhereClause(where);
                System.out.println(where);
                //XxApVendorContactVO.setWhereClauseParam(0,null); 
                // XxApVendorContactVO.setWhereClauseParam(1,Supplier);
                XxApVendorContactVO.executeQuery();


                XxApVendorContactVO.first();
                for (int i = 0; i < XxApVendorContactVO.getRowCount(); i++) {
                    XxApVendorContactVO.getCurrentRow().setAttribute("DisableTrans", 
                                                                     Boolean.TRUE);
                    XxApVendorContactVO.next();
                }
            }

            catch (Exception e) {
                pageContext.writeDiagnostics(this, "e :" + e, 1);
                pageContext.writeDiagnostics(this, 
                                             "XxApVendorContactVO query :" + 
                                             XxApVendorContactVO.getQuery(), 
                                             1);
                System.out.println("XxApVendorContactVO query :" + 
                                   XxApVendorContactVO.getQuery());
                throw new OAException("Error Message " + e.getMessage());
            }
        }

        if (pageContext.getParameter("Create") != null) {
            CreateT.setDisabled(false);
            ExportT.setDisabled(false);
            // UpdateT.setDisabled(false);
            // DeleteT.setDisabled(false);
            SaveT.setDisabled(false);
            CancelT.setDisabled(false);

            String Supplier = (String)pageContext.getParameter("Supplier");


            XxApVendorContactVO.first();
            XxApVendorContactVO.previous();
            /*XxApSupTraitsVO.last();
          XxApSupTraitsVO.next(); */
            Row row = XxApVendorContactVO.createRow();
            XxApVendorContactVO.insertRow(row);
            Object HeaderID = 
                mainAM.getOADBTransaction().getSequenceValue("XX_AP_VENDOR_KEY_SEQ");
            row.setAttribute("AddrKey", HeaderID);
            row.setAttribute("KeyValue1", Supplier);
            //row.setAttribute("Attribute1",'A');
            row.setAttribute("Module", "SUPP");
            row.setAttribute("PrimaryAddrInd", 'Y');
            row.setAttribute("OdEmailIndFlg", 'N');
            row.setAttribute("EnableFlag", 'Y');
            row.setAttribute("AddrUpdateAllowed", Boolean.FALSE);

        }


        if ("update".equals(pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))) {
            CreateT.setDisabled(false);
            ExportT.setDisabled(false);
            // UpdateT.setDisabled(false);
            // DeleteT.setDisabled(false);
            SaveT.setDisabled(false);
            CancelT.setDisabled(false);
            String rowRef = 
                pageContext.getParameter(OAWebBeanConstants.EVENT_SOURCE_ROW_REFERENCE);
            Row row = mainAM.findRowByRef(rowRef);
            XxApVendorContactVO.setCurrentRow(row);
            XxApVendorContactVO.getCurrentRow().setAttribute("DisableTrans", 
                                                             Boolean.FALSE);
            // XxApVendorContactVO.getCurrentRow().setAttribute("Attribute1",'U');
            // throw new OAException("Record Updated Successfully",OAException.CONFIRMATION);
        }


        if (pageContext.getParameter("Clear") != null) { // retain AM
            pageContext.forwardImmediately("OA.jsp?page=/od/oracle/apps/xxfin/ap/idms/contactaddress/webui/XXApSupplierContactsPG", 
                                           null, 
                                           OAWebBeanConstants.KEEP_MENU_CONTEXT, 
                                           null, null, false, 
                                           OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
        }


    }

}
