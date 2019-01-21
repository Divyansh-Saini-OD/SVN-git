package oracle.apps.ar.irec.accountDetails.inv.webui;

/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1327 and E2052
 -- Script Location: $CUSTOM_JAVA_TOP/oracle/apps/ar/irec/accountDetails/inv/webui
 -- Description: Considered R12 code version and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 27-Jul-2013  1.0        Retrofitted for R12 Upgrade.
 -- Vasu Raparla    18-Aug-2013  2.0        Retrofitted for R12.2.5 Upgrade.
---------------------------------------------------------------------------*/

import java.util.Dictionary;
import oracle.apps.ar.irec.accountDetails.SummaryTableCO;
import oracle.apps.ar.irec.framework.IROAViewObjectImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAAttachmentUtils;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageAttachmentLinkBean;
import oracle.bali.share.util.BooleanUtils;
import oracle.jbo.domain.Number;

public class SummaryCO extends SummaryTableCO
{

    public static final String RCS_ID = "$Header: SummaryCO.java 120.11 2011/08/05 10:26:59 rsinthre ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: SummaryCO.java 120.11 2011/08/05 10:26:59 rsinthre ship $", "oracle.apps.ar.irec.accountDetails.inv.webui");

    public SummaryCO()
    {
    }

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        boolean flag = isInternalCustomer(oapagecontext, oawebbean);
        oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean oatablelayoutbean = addTableLayoutAndReturnSummaryRegion(oapagecontext, oawebbean, "AR", "ARI_REMITTANCE_INST");
        addRow(oapagecontext, oatablelayoutbean, oawebbean, "Irtransaction");
        addRow(oapagecontext, oatablelayoutbean, oawebbean, "Aridate", "Arirelateddate");
        addRow(oapagecontext, oatablelayoutbean, oawebbean, "Irpurchaseorder");
        Object obj = ((IROAViewObjectImpl)oapagecontext.getApplicationModule(oawebbean).findViewObject("CountSalesOrdersVO")).getFirstObject("RowCount");
        if(null != obj && ((Number)obj).intValue() == 1)
        {
            addRow(oapagecontext, oatablelayoutbean, oawebbean, "Irsalesorder");
        } else
        {
            Object obj1 = ((IROAViewObjectImpl)oapagecontext.getApplicationModule(oawebbean).findViewObject("CountProjectsVO")).getFirstObject("RowCount");
            if(null != obj1 && ((Number)obj1).intValue() == 1)
            {
                addRow(oapagecontext, oatablelayoutbean, oawebbean, "Irproject");
            }
        }
        addRow(oapagecontext, oatablelayoutbean, oawebbean, "Irshipreference", "Arishipvia");
        addRow(oapagecontext, oatablelayoutbean, oawebbean, "Aricustnumber", "Arirelatednumber");

        /* Added for R12 upgrade retrofit */
        // Added By Raj Patel and Bushrod Thomas -- Also see required addition in irec/regions/ARIINVOICEDETAILS.xml
        // Extension : E1356_iRec_Personalizations and Defect 6035
        addRow(oapagecontext, oatablelayoutbean, oawebbean, "XXBillingID", "XXSPCStoreDateRegTrans");
        // End : E1356_iRec_Personalizations 
        /* End - Added for R12 upgrade retrofit */


        addRow(oapagecontext, oatablelayoutbean, oawebbean, "InvoiceAttachments");
        OAMessageAttachmentLinkBean oamessageattachmentlinkbean = (OAMessageAttachmentLinkBean)oawebbean.findChildRecursive("InvoiceAttachments");
        String s = oapagecontext.getProfile("OIR_DEFAULT_ATTACHMENT_CATEGORY");
        if(s == null || "".equals(s))
        {
            s = "MISC";
        }
        Integer ainteger[] = new Integer[1];
        ainteger[0] = OAAttachmentUtils.validateCategoryName(s, oapagecontext.getApplicationModule(oawebbean));
        Boolean aboolean[] = new Boolean[1];
        aboolean[0] = new Boolean(false);
        if(oamessageattachmentlinkbean != null)
        {
            oamessageattachmentlinkbean.setDefaultMiscCategoryEnabled(false);
            oamessageattachmentlinkbean.setDynamicCategoriesMap("RA_CUSTOMER_TRX", ainteger, aboolean);
            oamessageattachmentlinkbean.setAutoCommitEnabled(true);
        }
        if(oamessageattachmentlinkbean != null && flag)
        {
            oamessageattachmentlinkbean.setUpdateable(true);
        }
        String s1 = oapagecontext.getProfile("AR_BPA_ATTACH_UPDATE_ENABLED");
        boolean flag1 = isInternalCustomer(oapagecontext, oawebbean);
        if(oamessageattachmentlinkbean != null)
        {
            if("Y".equalsIgnoreCase(s1))
            {
                setAttchmentUpdatable(oamessageattachmentlinkbean, true, flag1);
            } else
            {
                setAttchmentUpdatable(oamessageattachmentlinkbean, false, flag1);
            }
        }
        String s2 = oapagecontext.getParameter("OARF");
        if(s2 != null && s2.equals("printable"))
        {
            OAWebBean oawebbean1 = oawebbean.findIndexedChildRecursive("InvoiceAttachments");
            if(oawebbean1 != null)
            {
                oawebbean1.setRendered(false);
            }
        }
    }

    public void setAttchmentUpdatable(OAMessageAttachmentLinkBean oamessageattachmentlinkbean, boolean flag, boolean flag1)
    {
        Boolean boolean1 = BooleanUtils.getBoolean(flag);
        Dictionary adictionary[] = oamessageattachmentlinkbean.getEntityMappings();
        if(adictionary != null)
        {
            int i = adictionary.length;
            for(int j = 0; j < i; j++)
            {
                Dictionary dictionary = adictionary[j];
                if(dictionary == null || dictionary.size() <= 0)
                {
                    continue;
                }
                dictionary.put("insertAllowed", boolean1);
                if(!flag1)
                {
                    boolean1 = new Boolean("false");
                }
                dictionary.put("updateAllowed", boolean1);
                dictionary.put("deleteAllowed", boolean1);
            }

        }
        oamessageattachmentlinkbean.setEntityMappings(adictionary);
    }

}
