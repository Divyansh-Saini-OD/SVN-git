/*===========================================================================+
 |                Office Depot - Project Simplify                            |
 |                            Office Depot                                   | 
 +===========================================================================+
 |  FILENAME                                                                 |
 |             XMLStatement.java                                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Burst Program for to Split the Files                                   |
 |                                                                           |
 |                                                                           |
 |Change Record:                                                             |
 |===============                                                            |
 |Version   Date          Author                      Remarks                |
 |=======   ==========   =============           ==========================  |
 |1.0       03 MAY 2007 Sambasiva  Reddy               Initial version       |
 |                       Wipro Technologies                                  |
 |                                                                           |
 |1.1       19 FEB 2008 Sambasiva  Reddy               Changed for Defect    |
 |                       Wipro Technologies            4737                  |
 |                                                                           |
 +===========================================================================*/

package oracle.apps.xxod;
import java.sql.SQLException;
import java.sql.Connection;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import oracle.jdbc.driver.OracleResultSet;
import oracle.jdbc.driver.OraclePreparedStatement;
import oracle.jdbc.driver.OracleCallableStatement;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.util.NameValueType;
import oracle.apps.fnd.util.ParameterList;
import oracle.apps.fnd.cp.request.CpContext;
import oracle.apps.fnd.cp.request.ReqCompletion;
import oracle.apps.fnd.cp.request.LogFile;
import oracle.apps.fnd.cp.request.JavaConcurrentProgram;
import oracle.apps.fnd.cp.request.RemoteFile;
import oracle.apps.xdo.XDOException;
import oracle.apps.xdo.oa.util.OADocumentProcessor;
import oracle.apps.xdo.batch.BurstingListener;
import oracle.apps.xdo.batch.DocumentProcessor;
import oracle.apps.xdo.batch.BurstingProcessorEngine;
import java.util.Properties;
import java.util.Vector;

public class XMLStatement implements JavaConcurrentProgram
{
    public String arg;
    public String arg1;
    public String arg2;
    public String arg3;
    private CpContext ccntxt;
    private LogFile lfile;
    private boolean debug = false; 
    private Connection mJConn;
    int count=0;

    public void runProgram(CpContext ctx)
    {
        lfile = ctx.getLogFile(); 
        lfile.writeln("XML Report Publisher",0);
        ccntxt = ctx;
        // get the JDBC connection object 

        mJConn = ctx.getJDBCConnection(); 

        // get parameter list object from CpContext 
        ParameterList lPara = ctx.getParameterList(); 

        //Getting Unix Tops 
        String l_cust_top = ctx.getEnvStore().getEnv("CUSTOM_TOP");
        //Added for the Defect 4737
        String l_applcsf  = ctx.getEnvStore().getEnv("APPLCSF");
        String l_applout  = ctx.getEnvStore().getEnv("APPLOUT");


        // get ReqCompletion object from CpContext 

        ReqCompletion lRC = ctx.getReqCompletion(); 
        lfile = ctx.getLogFile(); 
        while (lPara.hasMoreElements())
       {
            NameValueType aNVT = lPara.nextParameter();
            if (count==0 )
            {
                 count= count+1;
                 arg = aNVT.getValue();
                 lfile.writeln("Request Id :  "+arg,1);
             }
/*             else if(count==1)
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
*/ //The above code commented for the Defect 4737
      } // Takes the request id as parameter from console

/*      arg2 = arg1.toLowerCase();
      String path= "/app/ebs/at" + arg2 + "/" + arg2 + "comn/admin/out/" + arg1 + "_"+ arg3 +"/" + "o" + arg +".out";
      String ctl_file = "/app/ebs/at" + arg2 + "/" + arg2 + "cust/xxcomn/java/oracle/apps/xxod/XXARStatementBurst.xml";
      String dir_file = "/app/ebs/at" + arg2 + "/" + arg2 + "cust/xxcomn/java/oracle/apps/xxod/arstatements";
*///The above code commented for the Defect 4737

//Below code added for the Defect 4737
      String path= l_applcsf+"/"+ l_applout +"/" + "o" + arg +".out";
      String ctl_file = l_cust_top + "/xxcomn/java/oracle/apps/xxod/XXARStatementBurst.xml";
      String dir_file = l_cust_top + "/xxcomn/java/oracle/apps/xxod/arstatements";

        lfile.writeln("Output File Path   :  "+path,1);
        lfile.writeln("XML Control File   :  "+ctl_file,1);
        lfile.writeln("Output Directory   :  "+dir_file,1);

//Above code added for the Defect 4737

      try
      {
         DocumentProcessor dp=new DocumentProcessor (ctl_file,path,dir_file);
         lfile.writeln("Listener created ...",1); 
         Properties prop= new Properties();
         lfile.writeln("Properties set ...",1);
         prop.put("user-variable:CUSTTOP",l_cust_top);
         dp.setConfig(prop);
         lfile.writeln("Config set ...",1);
         dp.process();
         lfile.writeln("Bursting complete",1);
         ctx.getReqCompletion().setCompletion(ReqCompletion.NORMAL, "");
      }
      catch (Exception exc)
      {
          lfile.writeln("--SQLException  :  " +exc,1);
          exc.printStackTrace();
      }
    }
}