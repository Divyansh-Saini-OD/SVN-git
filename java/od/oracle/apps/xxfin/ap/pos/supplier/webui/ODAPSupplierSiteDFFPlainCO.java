/*===========================================================================+
 |  OFFICE DEPOT PROJECT SIMPLIFY - IT ERP - R12 UPGRADE                     |
 |  Rice ID: E3064                                                           |
 |  Rice Description: Supplier Site Additional Information                   |
 +===========================================================================+
 |  HISTORY                                                                  |
 |  09/06/2013  Sreedhar Mohan  - Created                                    |
 +===========================================================================*/
package od.oracle.apps.xxfin.ap.pos.supplier.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAViewObject;

import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;

import oracle.jbo.Row;
import oracle.jbo.domain.Number;

/**
 * Controller for ...
 */
public class ODAPSupplierSiteDFFPlainCO extends OAControllerImpl {
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

        String strVendorID = null;
        String strVendorSiteID = null;
        strVendorID = pageContext.getParameter("VendorId");
        strVendorSiteID = pageContext.getParameter("VendorSiteId");
        pageContext.writeDiagnostics(this, 
                                     "In ODAPSupplierSiteDFFPlainCO PR strVendorID: " + 
                                     strVendorID, 1);
        pageContext.writeDiagnostics(this, 
                                     "In ODAPSupplierSiteDFFPlainCO PR strVendorSiteID: " + 
                                     strVendorSiteID, 1);
        pageContext.writeDiagnostics(this, 
                                     "VendorSiteId: " + pageContext.getParameter("VendorSiteId"), 
                                     1);
        pageContext.writeDiagnostics(this, 
                                     "VendorId: " + pageContext.getParameter("VendorId"), 
                                     1);
        pageContext.writeDiagnostics(this, 
                                     "pVendorId: " + pageContext.getParameter("pVendorId"), 
                                     1);
        pageContext.writeDiagnostics(this, 
                                     "pVendorSiteId: " + pageContext.getParameter("pVendorSiteId"), 
                                     1);
        pageContext.writeDiagnostics(this, 
                                     "pVendorId: " + pageContext.getParameter("PosVendorId"), 
                                     1);
        pageContext.writeDiagnostics(this, 
                                     "pVendorSiteId: " + pageContext.getParameter("PosPartySiteId"), 
                                     1);
        pageContext.writeDiagnostics(this, 
                                     "SUrl: " + pageContext.getParameter("SUrl"), 
                                     1);

        if (strVendorID == null)
            strVendorID = "13749";
        if (strVendorSiteID == null)
            strVendorSiteID = "669127";
        //671150  831681 669126

        System.out.println("strVendorID: " + strVendorID);
        pageContext.putSessionValue("vendorID", strVendorID);

        String VS_KFF_ID1 = null;
        String VS_KFF_ID2 = null;
        String VS_KFF_ID3 = null;

        OAApplicationModule am = pageContext.getApplicationModule(webBean);

        OADBTransaction oadbtransaction = 
            (OADBTransaction)am.getOADBTransaction();
        oadbtransaction.putValue("vendorID", strVendorID);

        //Serializable vendorparams[] = {strVendorID};
        //System.out.println("--From DFFPlainCO; setting Vendor ID--");
        //am.invokeMethod("setVendorID", vendorparams);       

        OAViewObject odAddeddDtVO = 
            (OAViewObject)am.findViewObject("ODAddressDtVO1");
        odAddeddDtVO.setMaxFetchSize(-1);
        odAddeddDtVO.setWhereClause(null);
        odAddeddDtVO.setWhereClauseParam(0, strVendorSiteID);
        odAddeddDtVO.executeQuery();

        OAViewObject odSupplierVO1 = 
            (OAViewObject)am.findViewObject("ODSupplierVO1");
        odSupplierVO1.setMaxFetchSize(-1);
        odSupplierVO1.setWhereClause(null);
        odSupplierVO1.setWhereClauseParam(0, strVendorID);
        odSupplierVO1.executeQuery();

        OAViewObject suppSitesAllVO = 
            (OAViewObject)am.findViewObject("ODAPSupplierSitesAllVO1");
        suppSitesAllVO.setMaxFetchSize(-1);
        suppSitesAllVO.setWhereClause(null);
        suppSitesAllVO.setWhereClauseParam(0, strVendorSiteID);
        suppSitesAllVO.executeQuery();

        Row suppSitesAllVORow = suppSitesAllVO.first();
        if (suppSitesAllVORow != null) {
            VS_KFF_ID1 = (String)suppSitesAllVORow.getAttribute("Attribute10");
            VS_KFF_ID2 = (String)suppSitesAllVORow.getAttribute("Attribute11");
            VS_KFF_ID3 = (String)suppSitesAllVORow.getAttribute("Attribute12");
            suppSitesAllVORow.setAttribute("Attribute7", strVendorSiteID);
        }

        OAMessageChoiceBean relPSChoice = 
            (OAMessageChoiceBean)webBean.findChildRecursive("relPSChoice");
        relPSChoice.setPickListCacheEnabled(false);

        System.out.println("VS_KFF_ID1: " + VS_KFF_ID1);
        System.out.println("VS_KFF_ID2: " + VS_KFF_ID2);
        System.out.println("VS_KFF_ID3: " + VS_KFF_ID3);

        OAViewObject supplierSiteKFF1VO1 = 
            (OAViewObject)am.findViewObject("ODXXPOVendorSitesKff1VO1");
        OAViewObject supplierSiteKFF2VO1 = 
            (OAViewObject)am.findViewObject("ODXXPOVendorSitesKff2VO1");
        OAViewObject supplierSiteKFF3VO1 = 
            (OAViewObject)am.findViewObject("ODXXPOVendorSitesKff3VO1");

        if (VS_KFF_ID1 == null) {
            VS_KFF_ID1 = 
                    am.getOADBTransaction().getSequenceValue("XX_PO_VENDOR_SITES_KFF_S").stringValue();
            if (!supplierSiteKFF1VO1.isPreparedForExecution()) {
                supplierSiteKFF1VO1.setWhereClause(null);
                supplierSiteKFF1VO1.setWhereClauseParams(null);
                supplierSiteKFF1VO1.setWhereClauseParam(0, VS_KFF_ID1);
                supplierSiteKFF1VO1.executeQuery();
            }
            Row kff1NewRow = supplierSiteKFF1VO1.createRow();
            if (kff1NewRow != null) {
                kff1NewRow.setAttribute("VsKffId", VS_KFF_ID1);
                suppSitesAllVORow.setAttribute("Attribute10", VS_KFF_ID1);
                try {
                    kff1NewRow.setAttribute("StructureId", new Number("101"));
                } catch (Exception e) {
                    e.printStackTrace();
                }
                kff1NewRow.setAttribute("EnabledFlag", "Y");
                kff1NewRow.setAttribute("SummaryFlag", "N");
                System.out.println("from create row VS_KFF_ID1: " + 
                                   VS_KFF_ID1);
                kff1NewRow.setNewRowState(Row.STATUS_INITIALIZED);
                supplierSiteKFF1VO1.insertRow(kff1NewRow);
            }
        } else {
            supplierSiteKFF1VO1.setMaxFetchSize(-1);
            supplierSiteKFF1VO1.setWhereClause(null);
            supplierSiteKFF1VO1.setWhereClauseParams(null);
            supplierSiteKFF1VO1.setWhereClauseParam(0, VS_KFF_ID1);
            //System.out.println("query: " + supplierSiteKFF1VO1.getQuery() );
            supplierSiteKFF1VO1.executeQuery();

        }
        if (VS_KFF_ID2 == null) {
            VS_KFF_ID2 = 
                    am.getOADBTransaction().getSequenceValue("XX_PO_VENDOR_SITES_KFF_S").stringValue();

            if (!supplierSiteKFF2VO1.isPreparedForExecution()) {
                supplierSiteKFF2VO1.setWhereClause(null);
                supplierSiteKFF2VO1.setWhereClauseParams(null);
                supplierSiteKFF2VO1.setWhereClauseParam(0, VS_KFF_ID2);
                supplierSiteKFF2VO1.executeQuery();
            }
            Row kff2NewRow = supplierSiteKFF2VO1.createRow();
            if (kff2NewRow != null) {
                kff2NewRow.setAttribute("VsKffId", VS_KFF_ID2);
                suppSitesAllVORow.setAttribute("Attribute11", VS_KFF_ID2);
                kff2NewRow.setAttribute("EnabledFlag", "Y");
                kff2NewRow.setAttribute("SummaryFlag", "N");
                try {
                    kff2NewRow.setAttribute("StructureId", 
                                            new Number("50350"));
                } catch (Exception e) {
                    e.printStackTrace();
                }
                System.out.println("from create row VS_KFF_ID2: " + 
                                   VS_KFF_ID2);
                kff2NewRow.setNewRowState(Row.STATUS_INITIALIZED);
                supplierSiteKFF2VO1.insertRow(kff2NewRow);
            }
        } else {
            supplierSiteKFF2VO1.setMaxFetchSize(-1);
            supplierSiteKFF2VO1.setWhereClause(null);
            supplierSiteKFF2VO1.setWhereClauseParams(null);
            supplierSiteKFF2VO1.setWhereClauseParam(0, VS_KFF_ID2);
            //System.out.println("query: " + supplierSiteKFF2VO1.getQuery() );
            supplierSiteKFF2VO1.executeQuery();

        }
        OAMessageChoiceBean venRTVChoice = 
            (OAMessageChoiceBean)webBean.findChildRecursive("chSegment58");
        venRTVChoice.setPickListCacheEnabled(false);

        if (VS_KFF_ID3 == null) {
            VS_KFF_ID3 = 
                    am.getOADBTransaction().getSequenceValue("XX_PO_VENDOR_SITES_KFF_S").stringValue();
            if (!supplierSiteKFF3VO1.isPreparedForExecution()) {
                supplierSiteKFF3VO1.setWhereClause(null);
                supplierSiteKFF3VO1.setWhereClauseParams(null);
                supplierSiteKFF3VO1.setWhereClauseParam(0, VS_KFF_ID3);
                supplierSiteKFF3VO1.executeQuery();
            }
            Row kff3NewRow = supplierSiteKFF3VO1.createRow();
            if (kff3NewRow != null) {
                kff3NewRow.setAttribute("VsKffId", VS_KFF_ID3);
                suppSitesAllVORow.setAttribute("Attribute12", VS_KFF_ID3);
                kff3NewRow.setAttribute("EnabledFlag", "Y");
                kff3NewRow.setAttribute("SummaryFlag", "N");
                kff3NewRow.setAttribute("Segment46","0.00");
                try {
                    kff3NewRow.setAttribute("StructureId", 
                                            new Number("50351"));
                } catch (Exception e) {
                    e.printStackTrace();
                }
                System.out.println("from create row VS_KFF_ID3: " + 
                                   VS_KFF_ID3);
                kff3NewRow.setNewRowState(Row.STATUS_INITIALIZED);
                supplierSiteKFF3VO1.insertRow(kff3NewRow);
            }
        } else {
            supplierSiteKFF3VO1.setMaxFetchSize(-1);
            supplierSiteKFF3VO1.setWhereClause(null);
            supplierSiteKFF3VO1.setWhereClauseParams(null);
            supplierSiteKFF3VO1.setWhereClauseParam(0, VS_KFF_ID3);
            //System.out.println("query: " + supplierSiteKFF3VO1.getQuery() );
            supplierSiteKFF3VO1.executeQuery();

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
        OAApplicationModule am = pageContext.getApplicationModule(webBean);

        OAViewObject suppSitesAllVO = 
            (OAViewObject)am.findViewObject("ODAPSupplierSitesAllVO1");
        Row row1 = suppSitesAllVO.first();


        String relPSChoiceVal = null;
        if (pageContext.getParameter("relPSChoice") != null)
            relPSChoiceVal = (String)pageContext.getParameter("relPSChoice");
        System.out.println("In PFR relPSChoice: " + relPSChoiceVal);

        if (row1 != null) {
            System.out.println("PFR Attribute8: " + 
                               row1.getAttribute("Attribute8"));
            System.out.println("PFR Attribute13: " + 
                               row1.getAttribute("Attribute13"));
            row1.setAttribute("Attribute13", relPSChoiceVal);
            System.out.println("PFR After.. Attribute13: " + 
                               row1.getAttribute("Attribute13"));
        }
        if (pageContext.getParameter("btnSubmit") != null) {
            System.out.println("In btnSubmit");
            am.getOADBTransaction().commit();
            OAException msg1 = 
                new OAException("Supplier Site Additional Information" + 
                                " saved successfully!", 
                                OAException.CONFIRMATION);
            pageContext.putDialogMessage(msg1);
        }

        OAViewObject odAddeddDtVO = 
            (OAViewObject)am.findViewObject("ODAddressDtVO1");

        Row addressDtVORow1 = odAddeddDtVO.first();
        Number PartyId = null;
        String PartySiteName = "";

        if (addressDtVORow1 != null) {
            PartyId = (Number)addressDtVORow1.getAttribute("PartyId");
            PartySiteName = 
                    (String)addressDtVORow1.getAttribute("PartySiteName");
        }
        String s2 = pageContext.getParameter("event");
        if ("cancel".equals(s2)) {
            System.out.println("In Cancel");

            HashMap hashmap = new HashMap();

            hashmap = new HashMap();

            if (row1 != null) {

                hashmap.put("PosPartyId", PartyId);
                hashmap.put("supplier_id", row1.getAttribute("VendorId"));
                hashmap.put("PosPartySiteId", 
                            row1.getAttribute("PartySiteId"));
                hashmap.put("PosAddressName", PartySiteName);
                hashmap.put("PosSupplierName", 
                            row1.getAttribute("VendorName"));
                hashmap.put("PosSupplierNumber", 
                            row1.getAttribute("Segment1"));
                hashmap.put("BackFromSiteFlex", "Y");
                hashmap.put("OA_SubTabIdx", null);
            }

            pageContext.setForwardURL("POS_HT_SP_B_MNG_ST", (byte)5, 
                                      pageContext.getHomePageMenuName(), 
                                      hashmap, true, "Y", (byte)0);
            return;
        }
        if ("returnToMngSites".equals(s2)) {
            System.out.println("In Cancel");

            HashMap hashmap1 = new HashMap();

            hashmap1 = new HashMap();

            if (row1 != null) {

                hashmap1.put("PosPartyId", PartyId);
                hashmap1.put("supplier_id", row1.getAttribute("VendorId"));
                hashmap1.put("PosPartySiteId", 
                             row1.getAttribute("PartySiteId"));
                hashmap1.put("PosAddressName", PartySiteName);
                hashmap1.put("PosSupplierName", 
                             row1.getAttribute("VendorName"));
                hashmap1.put("PosSupplierNumber", 
                             row1.getAttribute("Segment1"));
                hashmap1.put("BackFromSiteFlex", "Y");
                hashmap1.put("OA_SubTabIdx", null);
            }

            pageContext.setForwardURL("POS_HT_SP_B_MNG_ST", (byte)5, 
                                      pageContext.getHomePageMenuName(), 
                                      hashmap1, true, "Y", (byte)0);
            return;
        }
    }

}
