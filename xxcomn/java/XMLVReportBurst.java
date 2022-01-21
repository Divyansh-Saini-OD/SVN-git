package od.oracle.apps.xxfin;

import java.sql.Connection;
import oracle.apps.fnd.cp.request.*;
import oracle.apps.fnd.util.NameValueType;
import oracle.apps.fnd.util.ParameterList;
import oracle.apps.xdo.batch.DocumentProcessor;
import java.util.Properties;
import java.util.Vector;

public class XMLVReportBurst implements JavaConcurrentProgram
{

    public XMLVReportBurst()
    {
        debug = false;
    }

    public void runProgram(CpContext cpcontext)
    {
        lfile = cpcontext.getLogFile();
        lfile.writeln("XML Report Publisher 5.0", 0);
        ccntxt = cpcontext;
        mJConn = cpcontext.getJDBCConnection();
        ParameterList parameterlist = cpcontext.getParameterList();
        ReqCompletion reqcompletion = cpcontext.getReqCompletion();
        lfile = cpcontext.getLogFile();
        while (parameterlist.hasMoreElements())
       {
            NameValueType aNVT = parameterlist.nextParameter();
            if (count==0 )
            {
                 count= count+1;
                 arg = aNVT.getValue();
                 lfile.writeln("Request Id :"+arg,1);
             }

             else if(count==1)
             {
                  count= count+1;
                  arg1 = aNVT.getValue();
                  lfile.writeln("Instance Name   :"+arg1,2);
             }
             else 
             {
                  arg3 = aNVT.getValue();
                  lfile.writeln("Web Host Name   :"+arg3,3);
             }
      }

        arg2 = arg1.toLowerCase();
        lfile.writeln("Lower Instance   :"+arg2,2);
        String path= "/app/ebs/at" + arg2 + "/" + arg2 + "comn/admin/out/" + arg1 + "_"+ arg3 +"/" + "o" + arg +".out";
        String ctl_file = "/app/ebs/at" + arg2 + "/" + arg2 + "cust/xxcomn/java/od/oracle/apps/xxfin/VendorInvoiceBurst.xml";
        String dir_file = "/app/ebs/at" + arg2 + "/" + arg2 + "cust/xxcomn/java/od/oracle/apps/xxfin";
        lfile.writeln("Ctl File   :"+ctl_file,2);
        lfile.writeln("Path       :"+path,2);
        lfile.writeln("Dir File   :"+dir_file,2);
        try
        {
            DocumentProcessor documentprocessor = new DocumentProcessor(ctl_file, path, dir_file);
            lfile.writeln("Listener created ...", 1);
            Properties prop= new Properties();
	    lfile.writeln("Properties set ...",1);
            prop.put("user-variable:INS_TOP","/app/ebs/at" + arg2 + "/" + arg2 + "cust/xxcomn/java/od/oracle/apps/xxfin");
            documentprocessor.setConfig(prop);
            lfile.writeln("Config set ...",1);
            documentprocessor.process();
            lfile.writeln("Bursting complete", 1);
            cpcontext.getReqCompletion().setCompletion(0, "");
        }
        catch(Exception exception)
        {
            exception.printStackTrace();
        }
    }

    public String arg;
    public String arg1;
    public String arg2;
    public String arg3;
    private CpContext ccntxt;
    private LogFile lfile;
    private boolean debug;
    private Connection mJConn;
    String ctl_file;
    String dir_file;
    String tmp_file;
    int count=0;
}

