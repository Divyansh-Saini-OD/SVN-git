// Source File Name:   XXCSMPSOrderRequestFailureRptAMImpl.java

package od.oracle.apps.xxcrm.mps.reports.server;

import java.io.PrintStream;
import od.oracle.apps.xxcrm.mps.reports.lov.server.XXCSMPSPartyNameVOImpl;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.jbo.server.ApplicationModuleImpl;

// Referenced classes of package od.oracle.apps.xxcrm.mps.reports.server:
//            XXCSMPSOrderRequestFailureRptVOImpl

public class XXCSMPSOrderRequestFailureRptAMImpl extends OAApplicationModuleImpl
{

    public XXCSMPSOrderRequestFailureRptAMImpl()
    {
    }

    public XXCSMPSOrderRequestFailureRptVOImpl getXXCSMPSOrderRequestFailureRptVO()
    {
        return (XXCSMPSOrderRequestFailureRptVOImpl)findViewObject("XXCSMPSOrderRequestFailureRptVO");
    }

    public static void main(String args[])
    {
        ApplicationModuleImpl.launchTester("od.oracle.apps.xxcrm.mps.reports.server", "XXCSMPSOrderRequestFailureRptAMLocal");
    }

    public XXCSMPSPartyNameVOImpl getXXCSMPSPartyNameVO()
    {
        return (XXCSMPSPartyNameVOImpl)findViewObject("XXCSMPSPartyNameVO");
    }

    public void initOrderReqFailure(String partyId, String serialNo, String fromDeliveryDate, String toDeliveryDate, String managedStatus, String activeStatus)
    {
        System.out.println("##### in AM initOrderReqFailure partyId=" + partyId + " serialNo=" + serialNo);
        XXCSMPSOrderRequestFailureRptVOImpl mpsOrdReqFailureO = getXXCSMPSOrderRequestFailureRptVO();
        mpsOrdReqFailureO.initOrderReqFailure(partyId, serialNo, fromDeliveryDate, toDeliveryDate , managedStatus, activeStatus);
    }
}
