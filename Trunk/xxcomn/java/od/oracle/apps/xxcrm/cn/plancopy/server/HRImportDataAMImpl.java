// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3)
// Source File Name:   HRImportDataAMImpl.java

package od.oracle.apps.xxcrm.cn.plancopy.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.jbo.server.ApplicationModuleImpl;

// Referenced classes of package od.oracle.apps.xxcrm.cn.plancopy.server:
//            UploadVOImpl

public class HRImportDataAMImpl extends OAApplicationModuleImpl
{

    public HRImportDataAMImpl()
    {
    }

    public UploadVOImpl getUploadVO1()
    {
        return (UploadVOImpl)findViewObject("UploadVO1");
    }

    public void test()
    {
        UploadVOImpl vo = getUploadVO1();
    }

    public static void main(String args[])
    {
        ApplicationModuleImpl.launchTester("od.oracle.apps.xxcrm.cn.plancopy.server", "HRImportDataAMLocal");
    }
}
