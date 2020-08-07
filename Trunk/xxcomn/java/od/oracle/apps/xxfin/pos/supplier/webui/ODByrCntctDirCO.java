package od.oracle.apps.xxfin.pos.supplier.webui;

/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: Defect30043
 -- Script Location: $CUSTOM_JAVA_TOP/od/oracle/apps/xxfin/pos/supplier/webui
 -- Description: Controller class for Contact Directory Page
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 22-May-2014  1.0        Extended controller for
 --                                         adding AddressName.
 -- Sridevi Kondoju 5-June-2014  2.0        modified for create supplier
 --                                         scenario - where no contacts
 --                                         exist Defect30374
---------------------------------------------------------------------------*/

import oracle.apps.pos.supplier.webui.ByrCntctDirCO;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.pos.supplier.webui.SupplierUtil;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;


/**
 * Controller for Contact Directory Page
 */
public class ODByrCntctDirCO extends ByrCntctDirCO {
    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    /**
     * Layout and page setup logic for a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {

        //Calling super processrequest
        super.processRequest(pageContext, webBean);

        pageContext.writeDiagnostics(this, 
                                     "XXOD: ODByrCntctDirCO processRequest Start ::: here", 
                                     1);

        //Getting handle to root am and PosAddrContAM
        OAApplicationModule am = pageContext.getRootApplicationModule();
        OAApplicationModule addrAM = 
            (OAApplicationModule)am.findApplicationModule("PosAddrContAM");


        //getting handle to contactsVO
        OAViewObject contactsVO = 
            (OAViewObject)am.findViewObject("ContactsVO");

        pageContext.writeDiagnostics(this, "XXOD: ODByrCntctDirCO Step 10.10", 
                                     1);

        //Logic for adding Site/address name dynamically to contact vo

        if (contactsVO != null) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: ODByrCntctDirCO Step 10.20", 
                                         1);
            try {
                String l_att = 
                    contactsVO.findAttributeDef("ODAddressName").toString();
                pageContext.writeDiagnostics(this, 
                                             "XXOD: ODByrCntctDirCO Step 10.30", 
                                             1);
            } catch (Exception exception) {
                contactsVO.addDynamicAttribute("ODAddressName"); //Adding ViewAttribute to VO
                pageContext.writeDiagnostics(this, 
                                             "XXOD: ODByrCntctDirCO Step 10.40", 
                                             1);
            }

            pageContext.writeDiagnostics(this, 
                                         "XXOD: ODByrCntctDirCO Step 10.50", 
                                         1);
            contactsVO.reset();

            pageContext.writeDiagnostics(this, 
                                         "XXOD: ODByrCntctDirCO Step 10.60", 
                                         1);


            while (contactsVO.hasNext()) {

                pageContext.writeDiagnostics(this, 
                                             "XXOD: ODByrCntctDirCO has next", 
                                             1);
                contactsVO.next();

                pageContext.writeDiagnostics(this, 
                                             "XXOD: ODByrCntctDirCO Step 10.70", 
                                             1);
                OARow contactsRow = (OARow)contactsVO.getCurrentRow();
                int i = contactsVO.getCurrentRowIndex();
                pageContext.writeDiagnostics(this, 
                                             "XXOD: ODByrCntctDirCO Step 10.80" + 
                                             i, 1);


                pageContext.writeDiagnostics(this, 
                                             "XXOD: contactVO " + i + " " + 
                                             contactsRow.getAttribute("PartyId") + 
                                             "  " + 
                                             contactsRow.getAttribute("PartyName"), 
                                             1);

                String contId = contactsRow.getAttribute("PartyId").toString();
                String suppId = SupplierUtil.getPartyIdStr(pageContext);

                pageContext.writeDiagnostics(this, "XXOD: ContId:" + contId, 
                                             1);

                pageContext.writeDiagnostics(this, "XXOD: suppId:" + suppId, 
                                             1);


                //Getting handle to PosAddrContVO

                OAViewObject addrVO = 
                    (OAViewObject)addrAM.findViewObject("PosAddrContVO");

                pageContext.writeDiagnostics(this, "XXOD: after find addrVO", 
                                             1);

                if (addrVO != null) {
                    pageContext.writeDiagnostics(this, 
                                                 "XXOD: addrVO not null::" + 
                                                 addrVO.getFetchedRowCount(), 
                                                 1);


                    String s3 = 
                        (new StringBuilder()).append("contact_req_id is null and contact_party_id = ").append(contId).append(" and supplierId = ").append(suppId).append(" and rownum = 1").toString();


                    addrVO.setWhereClause(s3);
                    addrVO.setWhereClauseParams(null);
                    addrVO.executeQuery();
                    pageContext.writeDiagnostics(this, 
                                                 "XXOD: addrVO not null::" + 
                                                 addrVO.getFetchedRowCount() + 
                                                 " " + addrVO.getQuery(), 1);


                    OARow addrRow = (OARow)addrVO.getRowAtRangeIndex(0);

                    String saddr = null;
                    if (addrRow != null) {
                        if (addrRow.getAttribute("AddressName") != null) {
                            saddr = 
                                    addrRow.getAttribute("AddressName").toString();
                        }
                    }


                    pageContext.writeDiagnostics(this, "XXOD: saddr" + saddr, 
                                                 1);

                    contactsRow.setAttribute("ODAddressName", saddr);


                } else {
                    pageContext.writeDiagnostics(this, "XXOD: addrVO  null", 
                                                 1);
                }


            }


            contactsVO.first();

            //Finally adding ViewAttribute and ViewInstance with MessageTextInput bean which we have created through personalization 

            pageContext.writeDiagnostics(this, 
                                         "XXOD: Finally adding ViewAttribute and ViewInstance with MessageTextInput bean", 
                                         1);
            OAMessageStyledTextBean mst = 
                (OAMessageStyledTextBean)webBean.findChildRecursive("ODAddressName");
            mst.setViewUsageName("ContactsVO");
            mst.setViewAttributeName("ODAddressName");

        }


        pageContext.writeDiagnostics(this, 
                                     "XXOD: ODByrCntctDirCO processRequest End", 
                                     1);


    }


}
