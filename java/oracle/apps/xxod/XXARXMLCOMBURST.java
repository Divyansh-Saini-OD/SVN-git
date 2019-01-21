 /*==========================================================================+
 |                Office Depot - Project Simplify                            |
 |                            Office Depot                                   |
 +===========================================================================+
 |  FILENAME      : XXARXMLCOMBURST.java                                     |
 |                                                                           |
 |  DESCRIPTION   : Burs the XML file in order to our requirement            |
 |                                                                           |
 |                                                                           |
 |Change Record:                                                             |
 |===============                                                            |
 |Version   Date             Author                 Remarks                  |
 |=======   ==========      =============           =======================  |
 |1.0       05 APR 2009    Gokila Tamilselvam       Initial version          |
 |                         Wipro Technologies                                |
 |                                                                           |
 +===========================================================================*/
 package oracle.apps.xxod;
 import  java.sql.SQLException;
 import  java.sql.Connection;
 import  java.io.FileInputStream;
 import  java.io.FileOutputStream;
 import  java.io.InputStream;
 import  java.io.OutputStream;
 import  java.io.PrintWriter;
 import  java.io.StringWriter;
 import  oracle.jdbc.driver.OracleResultSet;
 import  oracle.jdbc.driver.OraclePreparedStatement;
 import  oracle.jdbc.driver.OracleCallableStatement;
 import  oracle.apps.fnd.common.VersionInfo;
 import  oracle.apps.fnd.util.NameValueType;
 import  oracle.apps.fnd.util.ParameterList;
 import  oracle.apps.fnd.cp.request.CpContext;
 import  oracle.apps.fnd.cp.request.ReqCompletion;
 import  oracle.apps.fnd.cp.request.LogFile;
 import  oracle.apps.fnd.cp.request.JavaConcurrentProgram;
 import  oracle.apps.fnd.cp.request.RemoteFile;
 import  oracle.apps.xdo.XDOException;
 import  oracle.apps.xdo.oa.util.OADocumentProcessor;
 import  oracle.apps.xdo.batch.BurstingListener;
 import  oracle.apps.xdo.batch.DocumentProcessor;
 import  oracle.apps.xdo.batch.BurstingProcessorEngine;
 import  java.util.Properties;
 import  java.util.Vector;

 public class XXARXMLCOMBURST implements JavaConcurrentProgram
 {
     public     String      l_req_id;
     public     String      l_burst_file;
     public     String      l_font_path;
     public     String      l_output_path;
     public     String      l_rtf_location;
     public     String      l_output_type;
     public     String      l_template_type;
     public     String      l_output_file_name;

     private    String gsConfigPath = "";
     private    CpContext   ccntxt;
     private    LogFile     lfile;
     private    boolean     debug               = false;
     private    Connection  mJConn;
     public     String      path;
                int         count               = 0;

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

         // get ReqCompletion object from CpContext

         ReqCompletion lRC = ctx.getReqCompletion();
         lfile             = ctx.getLogFile();
         while (lPara.hasMoreElements())
         {
            NameValueType aNVT = lPara.nextParameter();
            if (count == 0)
            {
                count         = count + 1;
                l_req_id      = aNVT.getValue();
                lfile.writeln("Request Id :  "+l_req_id,1);
            }
            else if (count == 1)
            {
                count                = count + 1;
                l_burst_file         = aNVT.getValue();
                lfile.writeln("Burst File :  "+l_burst_file,1);
            }
            else if (count == 2)
            {
                count                = count + 1;
                l_font_path        = aNVT.getValue();
                lfile.writeln("Font Path :  "+l_font_path,1);
            }
            else if (count == 3)
            {
                count                = count + 1;
                l_output_path        = aNVT.getValue();
                lfile.writeln("Output Path :  "+l_output_path,1);
            }
            else if (count == 4)
            {
                count                = count + 1;
                l_rtf_location       = aNVT.getValue();
                lfile.writeln("RTF Location :  "+l_rtf_location,1);
            }
            else if (count == 5)
            {
                count                = count + 1;
                l_output_type        = aNVT.getValue();
                lfile.writeln("Output Type :  "+l_output_type,1);
            }
            else if (count == 6)
            {
                count                = count + 1;
                l_template_type      = aNVT.getValue();
                lfile.writeln("Template Type :  "+l_template_type,1);
            }
            else if (count == 7)
            {
                count                = count + 1;
                l_output_file_name   = aNVT.getValue();
                lfile.writeln("Output File Name :  "+l_output_file_name,1);
            }
         }

         path                = l_applcsf+"/"+ l_applout +"/" + "o" + l_req_id +".out";

         lfile.writeln("Output File Path   :  "+path,1);
         lfile.writeln("XML Control File   :  "+l_cust_top + "/" + l_burst_file,1);
         lfile.writeln("Output Directory   :  "+l_output_path,1);

         try
         {
             DocumentProcessor dp=new DocumentProcessor ( l_cust_top + "/" + l_burst_file
                                                         ,path
                                                         ,l_output_path
                                                         );
             lfile.writeln("Listener created ...",1);
             Properties prop= new Properties();
             lfile.writeln("Properties set ...",1);

             prop.put("user-variable:OUTPUTPATH",l_output_path);
             prop.put("user-variable:OUTPUTTYPE",l_output_type);
             prop.put("user-variable:TEMPLATETYPE",l_template_type);
             prop.put("user-variable:RTFLOC",l_cust_top + "/" + l_rtf_location);
             prop.put("user-variable:FILENAME",l_output_file_name);
             prop.put("font.IDAutomationPOSTNET.normal.normal","truetype." + l_font_path + "/" + "IDAutomationPOSTNET.ttf");
             prop.put("font.IDAutomationOCRa.normal.normal","truetype." + l_font_path + "/" + "IDAutomationOCRa.ttf");

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