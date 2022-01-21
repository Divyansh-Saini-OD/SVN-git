package od.oracle.apps.xxcrm.mps.reports.webui;

import java.io.Serializable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

public class XXCSMPSOrderRequestFailureRptCO extends OAControllerImpl
{

    public XXCSMPSOrderRequestFailureRptCO()
    {
    }

    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
        super.processRequest(pageContext, webBean);
    }

    public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
    {
        super.processFormRequest(pageContext, webBean);
        OAApplicationModule mpsAVFAM = pageContext.getApplicationModule(webBean);
        if(pageContext.getParameter("Search") != null)
        {
            String partyId = pageContext.getParameter("PartyIDFV");
            String serialNo = pageContext.getParameter("SerialNo");
            String fromDeliveryDate = pageContext.getParameter("txtFromDelDt");
            String toDeliveryDate = pageContext.getParameter("txtToDelDt");
            String managedStatus = pageContext.getParameter("ManagedStatusInput");
            String activeStatus = pageContext.getParameter("ActiveStatusInput");
            Serializable params[] = {
                partyId, serialNo, fromDeliveryDate, toDeliveryDate, managedStatus, activeStatus
            };
            mpsAVFAM.invokeMethod("initOrderReqFailure", params);
        }
        if(pageContext.getParameter("Clear") != null)
            clear(pageContext, webBean, mpsAVFAM);
    }

    public void clear(OAPageContext pageContext, OAWebBean webBean, OAApplicationModule mpsAVFAM)
    {
        OAMessageLovInputBean parttyNameBean = (OAMessageLovInputBean)webBean.findChildRecursive("PartyName");
        OAMessageTextInputBean serialNoBean = (OAMessageTextInputBean)webBean.findChildRecursive("SerialNo");
        OAFormValueBean partyIdBean = (OAFormValueBean)webBean.findChildRecursive("PartyIDFV");
        if(parttyNameBean != null)
            parttyNameBean.setValue(pageContext, "");
        if(partyIdBean != null)
            partyIdBean.setValue(pageContext, "");
        if(serialNoBean != null)
            serialNoBean.setValue(pageContext, "");
        Serializable params[] = {
            "-1", "-1", null, null, null, null
        };
        mpsAVFAM.invokeMethod("initOrderReqFailure", params);
    }

    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header$", "%packagename%");

}
