// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3)
// Source File Name:   HrcOicImpPlanAMImpl.java

package od.oracle.apps.xxcrm.cn.plancopy.server;

import java.io.PrintStream;
import java.io.Reader;
import java.sql.Clob;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.*;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ApplicationModuleImpl;
import oracle.jdbc.OracleCallableStatement;
import oracle.sql.CLOB;

// Referenced classes of package od.oracle.apps.xxcrm.cn.plancopy.server:
//            UploadVOImpl

public class HrcOicImpPlanAMImpl extends OAApplicationModuleImpl
{

    public HrcOicImpPlanAMImpl()
    {
    }

    public UploadVOImpl getUploadVO1()
    {
        return (UploadVOImpl)findViewObject("UploadVO1");
    }

    public static void main(String args[])
    {
        ApplicationModuleImpl.launchTester("od.oracle.apps.xxcrm.cn.plancopy.server", "HrcOicImpPlanAMLocal");
    }

    public int getImpData(String strXMLData)
    {
        OADBTransaction txn = getOADBTransaction();
        OracleCallableStatement cs = (OracleCallableStatement)txn.createCallableStatement("begin xx_oic_planrate_imp_pkg.cnc_submit_planrate_prc(:1, :2, :3, :4); end;", 10);
        int seqNum = 0;
        int reqId = 0;
        try
        {
            java.sql.Connection conn = txn.getJdbcConnection();
            CLOB dataClob = CLOB.createTemporary(conn, false, 2);
            dataClob.putString(1L, strXMLData);
            cs.setClob(1, dataClob);
            cs.registerOutParameter(2, 4);
            cs.registerOutParameter(3, 4);
            cs.setString(4, "N");
            cs.execute();
            reqId = cs.getInt(2);
            seqNum = cs.getInt(3);
            System.out.println("Request Id in AM: " + reqId);
            System.out.println("Sequence Number" + seqNum);
            cs.close();
            int j = reqId;
            return j;
        }
        catch(Exception e)
        {
            e.getStackTrace();
            System.out.println(e);
            int i = reqId;
            return i;
        }
    }

    public String pollConc(int seqNum)
    {
        OADBTransaction txn = getOADBTransaction();
        OracleCallableStatement pollCs = (OracleCallableStatement)txn.createCallableStatement("begin xx_oic_planrate_imp_pkg.cnc_poll_log_prc(:1, :2); end;", 10);
        String sclob = new String();
        try
        {
            pollCs.setInt(1, seqNum);
            pollCs.registerOutParameter(2, 2005);
            pollCs.execute();
            Clob my_clob = pollCs.getClob(2);
            if(my_clob != null)
            {
                Reader char_stream = my_clob.getCharacterStream();
                try
                {
                    StringBuffer sb = new StringBuffer();
                    char b[] = new char[16384];
                    int n;
                    while((n = char_stream.read(b)) > 0)
                        sb.append(b, 0, n);
                    sclob = sb.toString();
                    String s3 = sclob;
                    return s3;
                }
                catch(Exception e)
                {
                    e.printStackTrace();
                }
                String s2 = sclob;
                return s2;
            } else
            {
                String s = sclob;
                return s;
            }
        }
        catch(Exception e)
        {
            e.getStackTrace();
        }
        String s1 = sclob;
        return s1;
    }

    public OAViewObjectImpl getLogPVO1()
    {
        return (OAViewObjectImpl)findViewObject("LogPVO1");
    }

    public void init()
    {
        OAViewObject vo = (OAViewObject)findViewObject("LogPVO1");
        if(vo != null && vo.getFetchedRowCount() == 0)
        {
            vo.setMaxFetchSize(0);
            vo.executeQuery();
            vo.insertRow(vo.createRow());
            OARow row = (OARow)vo.first();
            row.setAttribute("RowKey", new Number(1));
            row.setAttribute("LogRender", Boolean.FALSE);
        }
    }

    protected static final int BLKSIZ = 16384;
}
