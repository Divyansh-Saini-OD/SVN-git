package od.oracle.apps.xxfin.ar.ebill;

import com.jcraft.jsch.*;

import java.io.ByteArrayInputStream;

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

import oracle.jdbc.OracleTypes;

import oracle.apps.fnd.cp.request.CpContext;
import oracle.apps.fnd.cp.request.JavaConcurrentProgram;
import oracle.apps.fnd.cp.request.ReqCompletion;

public class SendToFTPHost implements JavaConcurrentProgram
{
    private String gsConfigPath = "";
    private Connection gConnection = null;
    private ChannelSftp gSFTP = null;
    private Session gSession = null;
    private String gsSFTPUser = "Ebill584";
    private String gsSFTPRootPath = "/" + gsSFTPUser + "-sp:/test/";
    private String gsSFTPCurrentPath = "";
    private String gsHost=null;
    private int gnPort;
    private String gsUser=null;

    // main is only used for testing; EBS will call runProgram (see below)
    public static void main(String[] args) {
        SendToFTPHost sendToFTPHost = new SendToFTPHost();

        try {
          OracleDataSource ods = new OracleDataSource();
          ods.setURL("jdbc:oracle:thin:apps/dev01apps@//choldbr18d-vip.na.odcorp.net:1531/GSIDEV01");
          sendToFTPHost.gConnection=ods.getConnection();
          sendToFTPHost.gConnection.setAutoCommit(true);
        } catch(SQLException ex) {
           ex.printStackTrace();
           System.out.println("Error Connecting to the Database\n" + ex.toString());
        }

        sendToFTPHost.gsSFTPRootPath += "404/";

        try {
           sendToFTPHost.ftpPaths();
           sendToFTPHost.setTooBigTransmissions();
           sendToFTPHost.ftpTransmissions();
        }
        catch(Exception ex) {
           System.out.println("writeFiles ERROR\n" + ex.toString());
           ex.printStackTrace();
        }
        /*  -- Removed closing the jdbc connection for defect 38745
        try {
           sendToFTPHost.gConnection.close();
        }
        catch(SQLException ex) {
           System.out.println("Error Closing Connection\n" + ex.toString());
           ex.printStackTrace();
        }*/ 
        finally {
           sendToFTPHost.closeSFTP();
        }
    }

    // This is the EBS concurrent program entry point
    public void runProgram(CpContext cpcontext)
    {
      gsConfigPath = cpcontext.getEnvStore().getEnv("XXFIN_TOP") + "/billing/";
	  System.out.println("Set gsConfigPath\n");
      gConnection = cpcontext.getJDBCConnection();
	  System.out.println("Set gConnection\n");
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
		System.out.println("gsSFTPRootPath: "+gsSFTPRootPath);
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
        System.out.println("Sending paths file");
        ftpPaths();
        System.out.println("Flagging oversize transmissions");
        setTooBigTransmissions();
        System.out.println("Sending files to OD SFTP host");
        ftpTransmissions();
        System.out.println("Setting completion status");
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


    public void setTooBigTransmissions() throws Exception{
        CallableStatement cs = null;

        try {
            cs = gConnection.prepareCall ("BEGIN XX_AR_EBL_TRANSMISSION_PKG.SET_TOOBIG_TRANSMISSIONS_FTP; END;");
            cs.execute();
            gConnection.commit();
        }
        catch (Exception ex) {
            ex.printStackTrace();
            throw new Exception("Error in setTooBigTransmissions\n"+ex.toString());
        }
        finally {
           if (cs != null) cs.close();
        }
    }


    public void ftpPaths() throws Exception{
        CallableStatement csPaths = null;
        ResultSet rsPaths = null;
        StringBuilder sbPaths = new StringBuilder();
        String sOrg = null;

        try {
            csPaths = gConnection.prepareCall("BEGIN XX_AR_EBL_TRANSMISSION_PKG.FTP_PATHS(?,?); END;");
            csPaths.registerOutParameter(1, OracleTypes.CURSOR);
            csPaths.registerOutParameter(2, OracleTypes.VARCHAR);
            csPaths.execute();
            rsPaths = (ResultSet)csPaths.getObject(1);
            sOrg = csPaths.getString(2);
			System.out.println("rsPaths: "+rsPaths);
			System.out.println("sOrg: "+sOrg);
            while (rsPaths.next()) {
                sbPaths.append(rsPaths.getString("line") + "\r\n");
				System.out.println("In ftppaths while loop"+rsPaths.getString("line"));
            }
        }
        catch (Exception ex){
            ex.printStackTrace();
            throw new Exception("Error in ftpPaths\n" + ex.toString());
        }
        finally {
            if (rsPaths!=null) rsPaths.close();
            if (csPaths!=null) csPaths.close();
        }

        InputStream isPaths = new ByteArrayInputStream(sbPaths.toString().getBytes());
        
		System.out.println("Before calling loginToFTPHost");
        loginToFTPHost();
		System.out.println("ftpPaths - 1 : "+gsSFTPRootPath);
        gSFTP.cd(gsSFTPRootPath);
		System.out.println("ftpPaths - 2");
        gSFTP.put(isPaths,"paths.txt",ChannelSftp.OVERWRITE);
		System.out.println("ftpPaths - 3");
        gsSFTPCurrentPath = gsSFTPRootPath;
		System.out.println("ftpPaths - 5");
    }


    public void ftpTransmissions() throws Exception{
        CallableStatement csTransmissions = null;
        ResultSet rsTransmissions = null;

        try {
            csTransmissions = gConnection.prepareCall("BEGIN XX_AR_EBL_TRANSMISSION_PKG.TRANSMISSIONS_TO_FTP(?); END;");
            csTransmissions.registerOutParameter(1, OracleTypes.CURSOR);
            csTransmissions.execute();
            rsTransmissions = (ResultSet)csTransmissions.getObject(1);
            while (rsTransmissions.next()) {
                int nTransmissionID   = rsTransmissions.getInt("transmission_id");
                String sFTPDirection  = rsTransmissions.getString("ftp_direction");
                String sAccountNumber = rsTransmissions.getString("account_number");
                String sCustDocID     = rsTransmissions.getString("cust_doc_id");

                System.out.println("FTPing Transmission_id " + nTransmissionID);
                try {
                    if (!sFTPDirection.equals("push") && !sFTPDirection.equals("pull")) {throw new Exception("Error: unknown ftp direction" + sFTPDirection);}
                    ftpTransmission(nTransmissionID, sFTPDirection, sAccountNumber, sCustDocID);
                }
                catch (Exception trxEx) {
                    trxEx.printStackTrace();
                    System.out.println("  ftpTransmissions Error\n" + trxEx.toString());
                    PreparedStatement pstmt = null;
                    try {
                        System.out.println("  Setting ERROR status");
                        pstmt = gConnection.prepareStatement ("UPDATE XX_AR_EBL_TRANSMISSION SET status=?, status_detail=?, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id WHERE transmission_id=?");
                        pstmt.setString(1,"ERROR");
                        pstmt.setString(2,trxEx.toString());
                        pstmt.setInt(3, nTransmissionID);
                        pstmt.execute();
                    }
                    catch (Exception updateEx) {
                        System.out.println("Error setting ERROR status " + trxEx.toString()); // need to proceed, but this will write to log
                    }
                    finally {
                        if (pstmt!=null) pstmt.close();
                    }
                }
            }
        }
        catch (Exception ex){
            ex.printStackTrace();
            throw new Exception("Error in ftpTransmissions\n" + ex.toString());
        }
        finally {
            if (rsTransmissions!=null) rsTransmissions.close();
            if (csTransmissions!=null) csTransmissions.close();
        }
    }


    private void ftpTransmission(int nTransmissionID, String sFTPDirection, String sAccountNumber, String sCustDocID) throws Exception {
       PreparedStatement pstmt = null;
       CallableStatement csFiles = null;
       ResultSet rsFiles = null;

       try {
           csFiles = gConnection.prepareCall("BEGIN XX_AR_EBL_TRANSMISSION_PKG.FILES_TO_FTP(?,?); END;");
           csFiles.setInt(1,nTransmissionID);
           csFiles.registerOutParameter(2, OracleTypes.CURSOR);
           csFiles.execute();
           rsFiles = (ResultSet)csFiles.getObject(2);

           while (rsFiles.next()) {
               int nFileID = rsFiles.getInt("file_id");
               String sFileName = rsFiles.getString("file_name");
               Blob blob = rsFiles.getBlob("file_data");

               writeFile(sFileName, blob.getBinaryStream(), sFTPDirection, sAccountNumber, sCustDocID);
           }
           try {
             pstmt = gConnection.prepareStatement ("UPDATE XX_AR_EBL_TRANSMISSION SET status=?, status_detail=?, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id WHERE transmission_id=?");
             pstmt.setString(1,"STAGED");
             pstmt.setString(2,null);
             pstmt.setInt(3, nTransmissionID);
             pstmt.execute();
           }
           catch (Exception updateEx) {
               throw new Exception("Files SFTP'd, but unable to update transmission status\n" + updateEx.toString());
           }
           finally {
               pstmt.close();
           }
       }
       catch (Exception trxEx) {
           trxEx.printStackTrace();
           throw new Exception("Error in ftpTransmission\n" + trxEx.toString());
       }
       finally {
           if (rsFiles!=null) rsFiles.close();
           if (csFiles!=null) csFiles.close();
       }
    }

    private void closeSFTP() {
        if (gSFTP!=null) gSFTP.disconnect();
        if (gSession!=null) gSession.disconnect();
    }

    private void loginToFTPHost() throws Exception{
      if (gSFTP==null || gSession==null || gSFTP.isClosed() || !gSFTP.isConnected() || !gSession.isConnected()) {

        if (gsHost==null) getFTPConfig();
		System.out.println("Called get FTPConfig");

        JSch jsch=new JSch();
        jsch.addIdentity(gsSFTPUser,readFile(new File(gsConfigPath + "EBILLOpenSSH.ppk")),null,gsUser.getBytes());
        gSession = jsch.getSession(gsSFTPUser, gsHost, gnPort);
		System.out.println("gSession");
        gSession.setConfig("StrictHostKeyChecking","no");
        gSession.connect();

        Channel channel=gSession.openChannel("sftp");
        channel.connect();
        gSFTP=(ChannelSftp)channel;
		System.out.println("gSFTP");
        gsSFTPCurrentPath = "";
		System.out.println("loginToFTPHost Successful.");
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
		   System.out.println("gsHost: "+gsHost);
		   System.out.println("gnPort: "+gnPort);
		   System.out.println("gsUser: "+gsUser);
        }
        catch (Exception ex){
           ex.printStackTrace();
           throw new Exception("Error getting ftp connection details in loginToFTPHost\n" + ex.toString());
        }
        finally {
           if (csConfig!=null) csConfig.close();
        }
    }

    public void writeFile(String sFilename, InputStream bsFile, String sFTPDirection, String sAccountNumber, String sCustDocID) throws Exception {
        loginToFTPHost();

        if (sFTPDirection.equals("push")) {
            String sDestPath = gsSFTPRootPath + "push/" + sCustDocID;

            if (!gsSFTPCurrentPath.equals(sDestPath)) {
              gSFTP.cd(gsSFTPRootPath + sFTPDirection);
              try {
                 gSFTP.cd(sCustDocID);
              }
              catch(Exception ex) {
                 gSFTP.mkdir(sCustDocID);
                 try {
                   gSFTP.cd(sCustDocID);
                 }
                 catch(Exception ex2) {
                   throw new Exception("ERROR in writeFile; unable to cd to " + sDestPath + "/n"+ex2.toString());
                 }
              }
              gsSFTPCurrentPath = sDestPath;
            }
        }
        else {
           String sDestPath = gsSFTPRootPath + "pull/" + sAccountNumber;
           if (!gsSFTPCurrentPath.equals(sDestPath)) {
             gSFTP.cd(gsSFTPRootPath + sFTPDirection);
             try {
                gSFTP.cd(sAccountNumber);
             }
             catch(Exception ex) {
                gSFTP.mkdir(sAccountNumber);
                try {
                  gSFTP.cd(sAccountNumber);
                }
                catch(Exception ex2) {
                  throw new Exception("ERROR in writeFile; unable to cd to " + gsSFTPRootPath + "pull/" + sAccountNumber + "/n"+ex2.toString());
                }
             }
           }
        }

        gSFTP.put(bsFile,sFilename,ChannelSftp.OVERWRITE);
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
