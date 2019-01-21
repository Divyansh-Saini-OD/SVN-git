// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3)
// Source File Name:   PlanCopyLovAMImpl.java

package od.oracle.apps.xxcrm.cn.plancopy.lov.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.jbo.server.ApplicationModuleImpl;

// Referenced classes of package od.oracle.apps.xxcrm.cn.plancopy.lov.server:
//            CompPlanVOImpl, RateTableVOImpl

public class PlanCopyLovAMImpl extends OAApplicationModuleImpl
{

    public PlanCopyLovAMImpl()
    {
    }

    public CompPlanVOImpl getCompPlanVO1()
    {
        return (CompPlanVOImpl)findViewObject("CompPlanVO1");
    }

    public RateTableVOImpl getRateTableVO1()
    {
        return (RateTableVOImpl)findViewObject("RateTableVO1");
    }

    public static void main(String args[])
    {
        ApplicationModuleImpl.launchTester("od.oracle.apps.xxcrm.cn.plancopy.lov.server", "PlanCopyLovAMLocal");
    }
}
