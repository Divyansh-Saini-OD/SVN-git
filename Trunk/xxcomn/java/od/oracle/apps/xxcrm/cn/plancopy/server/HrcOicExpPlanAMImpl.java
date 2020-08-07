// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3)
// Source File Name:   HrcOicExpPlanAMImpl.java

package od.oracle.apps.xxcrm.cn.plancopy.server;

import java.io.PrintStream;
import java.io.Reader;
import java.sql.*;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.Row;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ApplicationModuleImpl;

// Referenced classes of package od.oracle.apps.xxcrm.cn.plancopy.server:
//            ExportPVOImpl, TransVOImpl

public class HrcOicExpPlanAMImpl extends OAApplicationModuleImpl
{

    public HrcOicExpPlanAMImpl()
    {
    }

    public static void main(String args[])
    {
        ApplicationModuleImpl.launchTester("od.oracle.apps.xxcrm.cn.plancopy.server", "HrcOicExpPlanAMLocal");
    }

    public void init()
    {
        OAViewObject vo = getExportPVO1();
        if(vo != null && vo.getFetchedRowCount() == 0)
        {
            vo.setMaxFetchSize(0);
            vo.executeQuery();
            vo.insertRow(vo.createRow());
            OARow row = (OARow)vo.first();
            row.setAttribute("RowKey", new Number(1));
            row.setAttribute("CompPlanRNRender", Boolean.TRUE);
            row.setAttribute("RateTableRNRender", Boolean.FALSE);
            row.setAttribute("LogRender", Boolean.FALSE);
        }
    }

    public void exportTypeChangeEvent(String exportTypeCH)
    {
        OAViewObject vo = getExportPVO1();
        OARow row = (OARow)vo.first();
        if(exportTypeCH.equals("Compensation Plans"))
        {
            row.setAttribute("CompPlanRNRender", Boolean.TRUE);
            row.setAttribute("RateTableRNRender", Boolean.FALSE);
        } else
        {
            row.setAttribute("CompPlanRNRender", Boolean.FALSE);
            row.setAttribute("RateTableRNRender", Boolean.TRUE);
        }
    }

    public String planexport(String var1, String var2, String var3, String var4, String var5)
    {
        OADBTransaction txn = getOADBTransaction();
        String slog = new String();
        if(var1.equals("Compensation Plans"))
            var1 = "PLANCOPY";
        else
            var1 = "RATECOPY";
        System.out.println("Parameters: ************************************" + var1);
        System.out.println("Parameters: ************************************" + var2);
        System.out.println("Parameters: ************************************" + var3);
        System.out.println("Parameters: ************************************" + var4);
        System.out.println("Parameters: ************************************" + var5);
        CallableStatement cs = txn.createCallableStatement("begin xx_oic_planrate_exp_pkg.cnc_export_prc(:1, :2, :3, :4, :5, :6, :7); end;", 10);
        try
        {
            cs.setString(1, var1);
            cs.setString(2, var2);
            cs.setString(3, var3);
            cs.setString(4, var4);
            cs.setString(5, var5);
            cs.registerOutParameter(6, 2005);
            cs.registerOutParameter(7, 2005);
            cs.execute();
            Clob my_clob = cs.getClob(6);
            Clob logClob = cs.getClob(7);
            Reader char_stream = my_clob.getCharacterStream();
            String sclob = new String();
            try
            {
                StringBuffer sb = new StringBuffer();
                char b[] = new char[16384];
                int n;
                while((n = char_stream.read(b)) > 0)
                    sb.append(b, 0, n);
                sclob = sb.toString();
            }
            catch(Exception e)
            {
                e.printStackTrace();
            }
            if(logClob != null)
            {
                Reader logStream = logClob.getCharacterStream();
                try
                {
                    StringBuffer sl = new StringBuffer();
                    char bl[] = new char[16384];
                    int l;
                    while((l = logStream.read(bl)) > 0)
                        sl.append(bl, 0, l);
                    slog = sl.toString();
                }
                catch(Exception e)
                {
                    e.printStackTrace();
                    String s1 = slog;
                    return s1;
                }
            }
            OAViewObject transVO = getTransVO1();
            if(!transVO.isPreparedForExecution())
                transVO.executeQuery();
            Row row = transVO.createRow();
            transVO.insertRow(row);
            row.setNewRowState((byte)-1);
            OARow row1 = (OARow)transVO.first();
            row1.setAttribute("RowKey", new Number(1));
            row1.setAttribute("XMLcontentAttr", "PlanCopy datafile");
            row1.setAttribute("FileAttr", sclob);
            cs.close();
            String s2 = slog;
            return s2;
        }
        catch(SQLException sqle)
        {
            sqle.getStackTrace();
        }
        String s = slog;
        return s;
    }

    public ExportPVOImpl getExportPVO1()
    {
        return (ExportPVOImpl)findViewObject("ExportPVO1");
    }

    public TransVOImpl getTransVO1()
    {
        return (TransVOImpl)findViewObject("TransVO1");
    }

    protected static final int BLKSIZ = 16384;
}
