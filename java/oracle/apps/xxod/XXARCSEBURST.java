/*==========================================================================================+
 |                Office Depot - Project Simplify                                           |
 |                            Office Depot                                                  | 
 +==========================================================================================+
 |  FILENAME                                                                                |
 |             XXARCSEBURST.java                                                            |
 |                                                                                          |
 |  DESCRIPTION                                                                             |
 |    Burst Program for to Split the Files                                                  |
 |                                                                                          |
 |                                                                                          |
 |Change Record:                                                                            |
 |===============                                                                           |
 |Version   Date             Author                      Remarks                            |
 |=======   ==========      =============           =======================                 |
 |1.0       05 NOV 2009    Saravanan/Vinay                Initial version                   |
 |                         Wipro Technologies                                               |
 |1.1       11-Aug-2010    Saravanan                 Defect#7397 - File System Change       |
 |                                                                                          |
 +==========================================================================================*/

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

public class XXARCSEBURST implements JavaConcurrentProgram
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
    public String path;
    public String ctl_file;
    public String dir_file;

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
        String l_applcsf  = ctx.getEnvStore().getEnv("APPLCSF");
        String l_applout  = ctx.getEnvStore().getEnv("APPLOUT");
        String l_finoutbound = ctx.getEnvStore().getEnv("XXFIN_DATA");


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
             else if(count==1)
             {
                  count= count+1;
                  arg1 = aNVT.getValue();
                  lfile.writeln("Customer Flag :"+arg1,2);
             }

      } 


    if (arg1.equals("Y"))
        {
        path= l_applcsf+"/"+ l_applout +"/" + "o" + arg +".out";
        ctl_file = l_cust_top + "/xxcomn/java/oracle/apps/xxod/XXARCSCUSTBURST.xml";
       // dir_file = l_cust_top + "/xxcomn/java/oracle/apps/xxod/arstatements";
          dir_file = l_finoutbound + "/outbound/arstatements/customer";
         }
      else
        {
        path= l_applcsf+"/"+ l_applout +"/" + "o" + arg +".out";
        ctl_file = l_cust_top + "/xxcomn/java/oracle/apps/xxod/XXARCSSITEBURST.xml";
       // dir_file = l_cust_top + "/xxcomn/java/oracle/apps/xxod/arstatements";
          dir_file = l_finoutbound + "/outbound/arstatements/custsite";
         }
 
    
        lfile.writeln("Output File Path   :  "+path,1);
        lfile.writeln("XML Control File   :  "+ctl_file,1);
        lfile.writeln("Output Directory   :  "+dir_file,1);

      try
      {
         DocumentProcessor dp=new DocumentProcessor (ctl_file,path,dir_file);
         lfile.writeln("Listener created ...",1); 
         Properties prop= new Properties();
         lfile.writeln("Properties set ...",1);
         prop.put("user-variable:CUSTTOP",l_cust_top);
         prop.put("user-variable:OUTPUTTOP",l_finoutbound);
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