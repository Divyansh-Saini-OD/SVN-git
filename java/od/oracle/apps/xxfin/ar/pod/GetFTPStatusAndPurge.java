package od.oracle.apps.xxfin.ar.ebill;

import com.jcraft.jsch.*;

import java.io.ByteArrayInputStream;

import java.io.ByteArrayOutputStream;

import oracle.jdbc.pool.OracleDataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.Blob;
import java.sql.ResultSet;
import java.io.IOException;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.File;

import java.io.OutputStream;

import java.util.Vector;

import oracle.jdbc.OracleTypes;

import oracle.apps.fnd.cp.request.CpContext;
import oracle.apps.fnd.cp.request.JavaConcurrentProgram;
import oracle.apps.fnd.cp.request.ReqCompletion;

public class GetFTPStatusAndPurge implements JavaConcurrentProgram
{
    private String gsConfigPath = "";
    private Connection gConnection = null;
    private ChannelSftp gSFTP = null;
    private Session gSession = null;
    private String gsSFTPUser = "Ebill584";
    private String gsSFTPRootPath = "/" + gsSFTPUser + "-sp:/";
    private String gsSFTPCurrentPath = "";
    private String gsHost=null;
    private int gnPort;
    private String gsUser=null;

    // main is only used for testing; EBS will call runProgram (see below)
    public static void main(String[] args) {
        GetFTPStatusAndPurge getFTPStatusAndPurge = new GetFTPStatusAndPurge();

        try {
          OracleDataSource ods = new OracleDataSource();
          ods.setURL("jdbc:oracle:thin:apps/dev01apps@//choldbr18d-vip.na.odcorp.net:1531/GSIDEV01");
          getFTPStatusAndPurge.gConnection=ods.getConnection();
          getFTPStatusAndPurge.gConnection.setAutoCommit(true);
        } catch(SQLException ex) {
           ex.printStackTrace();
           System.out.println("Error Connecting to the Database\n" + ex.toString());
        }

        getFTPStatusAndPurge.gsSFTPRootPath += "404/";

        try {
           getFTPStatusAndPurge.processPulls();
           getFTPStatusAndPurge.processPushes();
        }
        catch(Exception ex) {
           System.out.println("GetFTPStatusAndPurge ERROR\n" + ex.toString());
           ex.printStackTrace();
        }

        try {
           getFTPStatusAndPurge.gConnection.close();
        }
        catch(SQLException ex) {
           System.out.println("Error Closing Connection\n" + ex.toString());
           ex.printStackTrace();
        }
        finally {
           getFTPStatusAndPurge.closeSFTP();
        }
    }

    // This is the EBS concurrent program entry point
    public void runProgram(CpContext cpcontext)
    {
      gsConfigPath = cpcontext.getEnvStore().getEnv("XXFIN_TOP") + "/billing/";
      gConnection = cpcontext.getJDBCConnection();
      if (gConnection==null) {
        cpcontext.getReqCompletion().setCompletion(ReqCompletion.ERROR, "ERROR");
        System.out.println("Error: connection is null\n");
        return;
      }
      try {
        gConnection.setAutoCommit(true);
      }
      catch (SQLException ex) {
        cpcontext.getReqCompletion().setCompletion(ReqCompletion.ERROR, "ERROR");
        System.out.println("Error: Unable to setAutoCommit(true)\n" + ex.toString());
        ex.printStackTrace();
        return;
      }


      CallableStatement cs = null;
      try {
        cs = gConnection.prepareCall("BEGIN XX_AR_EBL_TRANSMISSION_PKG.GET_ORG_ID(?); END;");
        cs.registerOutParameter(1, OracleTypes.VARCHAR);
        cs.execute();
        String sOrgID = cs.getString(1);

        System.out.println("OrgID: " + sOrgID);
        gsSFTPRootPath += sOrgID + "/";
	  }
	  catch (Exception e) {
        cpcontext.getReqCompletion().setCompletion(ReqCompletion.ERROR, "ERROR");
        System.out.println("Error: Unable to get org_id\n" + e.toString());
        e.printStackTrace();
        return;
	  }
	  finally {
        if (cs!=null) try {cs.close();} catch (Exception ex) {};
	  }


      try {
        System.out.println("Processing pulls...");
        processPulls();
        System.out.println("\n\nProcessing pushes...");
        processPushes();
        cpcontext.getReqCompletion().setCompletion(ReqCompletion.NORMAL, "SUCCESS");
      }
      catch (Exception e) {
        try {
          cpcontext.getReqCompletion().setCompletion(ReqCompletion.ERROR, "ERROR");
        }
        catch(Exception ex) {System.out.println("Unable to set completion");};
        System.out.println("runProgram ERROR\n" + e.toString());
        e.printStackTrace();
      }
      finally {
        System.out.println("Closing SFTP");
        closeSFTP();
      }
    }



    public void processPulls() throws Exception{
        CallableStatement csCustDocs = null;
        ResultSet rsCustDocs = null;

        try {
            csCustDocs = gConnection.prepareCall("BEGIN XX_AR_EBL_TRANSMISSION_PKG.FTP_STAGED_PULL_ACCOUNTS(?); END;");
            csCustDocs.registerOutParameter(1, OracleTypes.CURSOR);
            csCustDocs.execute();
            rsCustDocs = (ResultSet)csCustDocs.getObject(1);
            while (rsCustDocs.next()) {
                String sAccountNumber = rsCustDocs.getString("account_number");
                String sAccountName = rsCustDocs.getString("account_name");

                System.out.println("\n\nChecking PULL: account #" + sAccountNumber + ": " + sAccountName);
                processAccountNumber(sAccountNumber);
            }
        }
        catch (Exception ex){
            ex.printStackTrace();
            throw new Exception("Error in processPulls\n" + ex.toString());
        }
        finally {
            if (rsCustDocs!=null) rsCustDocs.close();
            if (csCustDocs!=null) csCustDocs.close();
        }
    }

    public void processPushes() throws Exception{
        CallableStatement csCustDocs = null;
        ResultSet rsCustDocs = null;

        try {
            csCustDocs = gConnection.prepareCall("BEGIN XX_AR_EBL_TRANSMISSION_PKG.FTP_STAGED_PUSH_CUST_DOCS(?); END;");
            csCustDocs.registerOutParameter(1, OracleTypes.CURSOR);
            csCustDocs.execute();
            rsCustDocs = (ResultSet)csCustDocs.getObject(1);
            while (rsCustDocs.next()) {
                String sCustDocID = rsCustDocs.getString("customer_doc_id");
                String sAccountNumber = rsCustDocs.getString("account_number");
                String sAccountName = rsCustDocs.getString("account_name");

                System.out.println("\n\nChecking PUSH: cust_doc_id " + sCustDocID + " for account #" + sAccountNumber + ": " + sAccountName);
                processCustDoc(sCustDocID);
            }
        }
        catch (Exception ex){
            ex.printStackTrace();
            throw new Exception("Error in processPushes\n" + ex.toString());
        }
        finally {
            if (rsCustDocs!=null) rsCustDocs.close();
            if (csCustDocs!=null) csCustDocs.close();
        }
    }


    private void processCustDoc(String sCustDocID) {
       PreparedStatement pstmt = null;
       String sLogFile = null;
       try {
           System.out.println("Retrieving FTP log file: " + sCustDocID + ".log");
           sLogFile = getLogFileViaSFTP(sCustDocID);
           System.out.println("=== FTP log for cust doc " + sCustDocID + " ===");
           System.out.println(sLogFile);
           System.out.println("=== End of log for cust doc " + sCustDocID + " ===");

           if (sLogFile.indexOf("Transfer Succeeded!")>0) {

               try {
                 pstmt = gConnection.prepareStatement ("UPDATE XX_AR_EBL_TRANSMISSION SET status='SENT', status_detail=?, transmission_dt=SYSDATE, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id WHERE customer_doc_id=? AND org_id=FND_GLOBAL.org_id AND status='STAGED'");
                 pstmt.setString(1, sLogFile.substring(0,java.lang.Math.min(4000,sLogFile.length())));
                 pstmt.setInt(2, Integer.parseInt(sCustDocID));
                 pstmt.execute();
               }
               catch (Exception updateEx) {
                 System.out.println("Files sent, but unable to update transmission status\n" + updateEx.toString());
               }
               if (pstmt!=null) pstmt.close();

               try {
                 purgeCustDocFiles(sCustDocID);
               }
               catch (Exception purgeEx){
                   System.out.println("Unable to purge\n" + purgeEx.toString());
               }
            }

            else throw new Exception("Log does not indicate success.");
       }
       catch (Exception ex) {
           ex.printStackTrace();
           System.out.println("  get PUSH Transmission Status Error\n" + ex.toString());
           try {
               System.out.println("  Setting ERROR status");
               pstmt = gConnection.prepareStatement ("UPDATE XX_AR_EBL_TRANSMISSION SET status='ERROR', status_detail=?, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id WHERE customer_doc_id=? AND org_id=FND_GLOBAL.org_id AND status='STAGED'");
               if (sLogFile!=null && sLogFile.length()>3700) sLogFile = sLogFile.substring(sLogFile.length()-3700);
               pstmt.setString(1, ex.toString().substring(0,java.lang.Math.min(297,ex.toString().length())) + "\n" + sLogFile);
               pstmt.setInt(2, Integer.parseInt(sCustDocID));
               pstmt.execute();
           }
           catch (Exception updateEx) {
               System.out.println("Error setting ERROR status " + updateEx.toString()); // need to proceed, but this will write to log
           }
           finally {
               if (pstmt!=null)
               try {pstmt.close();}
               catch(Exception finEx) {
                  System.out.println("Error closing PreparedStatement\n" + finEx.toString());
               }
           }
       }
    }


    private void processAccountNumber(String sAccountNumber) {
       CallableStatement cstmt = null;
       String sLogFile = null;
       int nFileCount = -1;
       try {
           System.out.println("Retrieving unmoved file count");
           nFileCount = getFileCount(sAccountNumber);
           System.out.println("  Unmoved file count = " + nFileCount);

           if (nFileCount==0) {

               try {
                 cstmt = gConnection.prepareCall("BEGIN XX_AR_EBL_TRANSMISSION_PKG.UPDATE_FTP_PUSH_STATUS(?,?,?); END;");
                 cstmt.setString(1,sAccountNumber);
                 cstmt.setString(2,"SENT");
                 cstmt.setString(3,"");
                 cstmt.execute();
               }
               catch (Exception updateEx) {
                 System.out.println("Files moved, but unable to update transmission status\n" + updateEx.toString());
               }
               if (cstmt!=null) cstmt.close();

               try {
                   loginToFTPHost();
                   gSFTP.rmdir(gsSFTPRootPath + "pull/" + sAccountNumber);
               }
               catch (Exception purgeEx){
                   System.out.println("Files moved, but unable to purge folder\n" + purgeEx.toString());
               }
            }

            else throw new Exception("Error: PULL files still found in staging folder.");
       }
       catch (Exception ex) {
           ex.printStackTrace();
           System.out.println("  PULL Transmission Status Error\n" + ex.toString());
           try {
               System.out.println("  Setting ERROR status");
               cstmt = gConnection.prepareCall("BEGIN XX_AR_EBL_TRANSMISSION_PKG.UPDATE_FTP_PUSH_STATUS(?,?,?); END;");
               cstmt.setString(1,sAccountNumber);
               cstmt.setString(2,"ERROR");
               if (nFileCount>=0) cstmt.setString(3,nFileCount + " files not moved to PULL folder");
               else cstmt.setString(3,"Unable to retrieve unmoved file count");
               cstmt.execute();
           }
           catch (Exception updateEx) {
               System.out.println("Error setting ERROR status " + updateEx.toString()); // need to proceed, but this will write to log
           }
           finally {
               if (cstmt!=null)
               try {cstmt.close();}
               catch(Exception finEx) {
                  System.out.println("Error closing CallableStatement\n" + finEx.toString());
               }
           }
       }
    }


    private void closeSFTP() {
        if (gSFTP!=null) gSFTP.disconnect();
        if (gSession!=null) gSession.disconnect();
    }

    private void loginToFTPHost() throws Exception{
      if (gSFTP==null || gSession==null || gSFTP.isClosed() || !gSFTP.isConnected() || !gSession.isConnected()) {

        if (gsHost==null) getFTPConfig();

        JSch jsch=new JSch();
        jsch.addIdentity(gsSFTPUser,readFile(new File(gsConfigPath + "EBILLOpenSSH.ppk")),null,gsUser.getBytes());
        gSession = jsch.getSession(gsSFTPUser, gsHost, gnPort);
        gSession.setConfig("StrictHostKeyChecking","no");
        gSession.connect();

        Channel channel=gSession.openChannel("sftp");
        channel.connect();
        gSFTP=(ChannelSftp)channel;
        gsSFTPCurrentPath = "";
      }
   }

    public void getFTPConfig() throws Exception {
        CallableStatement csConfig = null;
        try {
           csConfig = gConnection.prepareCall("BEGIN XX_AR_EBL_TRANSMISSION_PKG.FTP_CONFIG(?,?,?); END;");
           csConfig.registerOutParameter(1, OracleTypes.VARCHAR);
           csConfig.registerOutParameter(2, OracleTypes.VARCHAR);
           csConfig.registerOutParameter(3, OracleTypes.VARCHAR);
           csConfig.execute();
           gsHost = csConfig.getString(1);
           gnPort = csConfig.getInt(2);
           gsUser = csConfig.getString(3);
        }
        catch (Exception ex){
           ex.printStackTrace();
           throw new Exception("Error getting ftp connection details in loginToFTPHost\n" + ex.toString());
        }
        finally {
           if (csConfig!=null) csConfig.close();
        }
    }

    public void purgeCustDocFiles(String sCustDocID) throws Exception {
        loginToFTPHost();

        String sLogPath = gsSFTPRootPath + "logs/";
        if (!gsSFTPCurrentPath.equals(sLogPath)) {
           gSFTP.cd(sLogPath);
           gsSFTPCurrentPath = sLogPath;
        }
        gSFTP.rm(sCustDocID + ".log");

        String sDocPath = gsSFTPRootPath + "push/" + sCustDocID;
        gSFTP.rm(sDocPath + "/*");
        gSFTP.rmdir(sDocPath);
    }

    public int getFileCount(String sAccountNumber) throws Exception {
        int nCount = 0;
        loginToFTPHost();

        Vector vv=gSFTP.ls(gsSFTPRootPath + "pull/" + sAccountNumber);
        nCount = vv.size()-2; // ls include "./" and "../" entries

/* Show files:
          for(int ii=0; ii<vv.size(); ii++){
            Object obj=vv.elementAt(ii);
            if(obj instanceof com.jcraft.jsch.ChannelSftp.LsEntry){
              System.out.println(((com.jcraft.jsch.ChannelSftp.LsEntry)obj).getLongname());
            }
          }
*/
        return nCount;
    }

    public String getLogFileViaSFTP(String sCustDocID) throws Exception {
        loginToFTPHost();

        String sLogPath = gsSFTPRootPath + "logs/";
        if (!gsSFTPCurrentPath.equals(sLogPath)) {
           gSFTP.cd(sLogPath);
           gsSFTPCurrentPath = sLogPath;
        }
        OutputStream osLogFile = new ByteArrayOutputStream();

        gSFTP.get(sCustDocID + ".log",osLogFile);

        return osLogFile.toString();
    }


    private static byte[] readFile(File file)  throws IOException {
      InputStream is = new FileInputStream(file);

      long length = file.length();

      if (length > Integer.MAX_VALUE) throw new IOException("Private Key file too large");

      byte[] bytes = new byte[(int)length];

      int offset = 0;
      int numRead = 0;
      while (offset < bytes.length && (numRead=is.read(bytes, offset, bytes.length-offset)) >= 0) offset += numRead;

      if (offset < bytes.length) throw new IOException("Could not completely read file "+file.getName());

      is.close();
      return bytes;
    }
}
