package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.webui;

import oracle.apps.ar.irec.accountDetails.pay.webui.QuickInfoCO;
import java.io.Serializable;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAMessageComponentLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.cabo.ui.UIConstants;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.cabo.ui.beans.message.MessageStyledTextBean;
import oracle.jbo.ApplicationModule;

public class ODQuickInfoCO extends QuickInfoCO
{

    public static final String RCS_ID = "$Header: QuickInfoCO.java 115.16 2006/11/20 14:36:37 abathini noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: QuickInfoCO.java 115.16 2006/11/20 14:36:37 abathini noship $", "oracle.apps.ar.irec.accountDetails.pay.webui");

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        //super.processRequest(oapagecontext, oawebbean);
        Boolean boolean1 = (Boolean)((OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("MultipleInvoicesPayListSummaryVO")).invokeMethod("isServiceChargeApplied");
        Boolean boolean2 = (Boolean)((OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("MultipleInvoicesPayListSummaryVO")).invokeMethod("isDiscountAvailable");
        String s = (String)((OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("DefaultPaymentInstrumentVO")).invokeMethod("paymentInstrumentType");
        ((OAApplicationModuleImpl)oapagecontext.getApplicationModule(oawebbean)).getOADBTransaction();
        if(boolean1 == Boolean.TRUE)
        {
            OAMessageStyledTextBean oamessagestyledtextbean = (OAMessageStyledTextBean)oawebbean.findIndexedChildRecursive("QPServiceChargeTip");
            oamessagestyledtextbean.setRendered(true);
        }
        /*if("BANK_ACCOUNT".equals(s))
        {
            OAMessageComponentLayoutBean oamessagecomponentlayoutbean = (OAMessageComponentLayoutBean)oawebbean.findIndexedChildRecursive("QuickPayBAMsgCompLayout");
            oamessagecomponentlayoutbean.setRendered(true);
        } else
        {
            OAMessageComponentLayoutBean oamessagecomponentlayoutbean1 = (OAMessageComponentLayoutBean)oawebbean.findIndexedChildRecursive("QuickPayCCMsgCompLayout");
            oamessagecomponentlayoutbean1.setRendered(true);
        }*/
        OAMessageStyledTextBean oamessagestyledtextbean1 = (OAMessageStyledTextBean)oawebbean.findIndexedChildRecursive("AccountExpired");
        Serializable aserializable[] = new Serializable[0];
        Boolean boolean3 = (Boolean)((OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("DefaultPaymentInstrumentVO")).invokeMethod("accountExpirationCheck", aserializable);
        if(boolean3 == Boolean.TRUE)
        {
            oamessagestyledtextbean1.setMessageType("error");
            oamessagestyledtextbean1.setText(oapagecontext, oapagecontext.getMessage("AR", "AR_IREC_CREDIT_CARD_EXPIRED", null));
            oamessagestyledtextbean1.setStyleClass("OraErrorText");
        } else
        {
            oamessagestyledtextbean1.setText(oapagecontext, "");
        }
        if(boolean2 == Boolean.TRUE)
        {
            OARowLayoutBean oarowlayoutbean = (OARowLayoutBean)oawebbean.findIndexedChildRecursive("DiscountAmtRow");
            oarowlayoutbean.setRendered(true);
        }
        if(boolean1 == Boolean.TRUE)
        {
            OARowLayoutBean oarowlayoutbean1 = (OARowLayoutBean)oawebbean.findIndexedChildRecursive("ServiceChargeRow");
            oarowlayoutbean1.setRendered(true);
        }
        String s1 = getActiveCustomerUseId(oapagecontext);
        if(!isNullString(s1))
        {
            OAMessageChoiceBean oamessagechoicebean = (OAMessageChoiceBean)oawebbean.findIndexedChildRecursive("CustomerSiteUse");
            oamessagechoicebean.setRendered(false);
            return;
        }
        String s2 = oapagecontext.getSessionId();
        String s3 = getActiveCustomerId(oapagecontext);
        OADBTransaction oadbtransaction = oapagecontext.getApplicationModule(oawebbean).getOADBTransaction();
        s1 = String.valueOf(oadbtransaction.getValue("CustomerSiteUseId"));
        if(isNullString(s1) || "-1".equals(s1))
        {
            Serializable aserializable1[] = {
                s2, s3
            };
            ((OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("CustSitesAccessVO")).invokeMethod("initQuery", aserializable1);
            return;
        } else
        {
            OAMessageChoiceBean oamessagechoicebean1 = (OAMessageChoiceBean)oawebbean.findIndexedChildRecursive("CustomerSiteUse");
            oamessagechoicebean1.setRendered(false);
            return;
        }
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
    }

    public ODQuickInfoCO()
    {
    }

}
