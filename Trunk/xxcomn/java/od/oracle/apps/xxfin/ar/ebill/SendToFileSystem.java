package od.oracle.apps.xxfin.ar.ebill;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

import java.sql.Blob;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import od.oracle.apps.xxfin.ar.irec.statements.webui.StatementFile;

import oracle.apps.fnd.cp.request.CpContext;
import oracle.apps.fnd.cp.request.JavaConcurrentProgram;

import oracle.jdbc.OracleTypes;
import oracle.jdbc.pool.OracleDataSource;

public class SendToFileSystem implements JavaConcurrentProgram
{
    private Connection connection;
    private String gsRootPath = null;

    public SendToFileSystem() {
    }

    // main is only used for testing; EBS will call runProgram (see below)
    public static void main(String[] args) {
        SendToFileSystem sendToFileSystem = new SendToFileSystem();

        sendToFileSystem.gsRootPath = "C:\\Temp\\transmissions";

        try {
          OracleDataSource ods = new OracleDataSource();
          ods.setURL("jdbc:oracle:thin:apps/dev01apps@//choldbr18d-vip.na.odcorp.net:1531/GSIDEV01");
          sendToFileSystem.connection=ods.getConnection();
          sendToFileSystem.connection.setAutoCommit(true);
        } catch(SQLException ex) {
           ex.printStackTrace();
           System.out.println("Error Connecting to the Database\n" + ex.toString());
        }

        try {
           sendToFileSystem.writeFiles();
        }
        catch (Exception ex) {
            System.out.println("writeFiles failed\n" + ex.toString());
            ex.printStackTrace();
        }

        try {
           sendToFileSystem.connection.close();
        }
        catch(SQLException ex) {
           System.out.println("Error Closing Connection\n" + ex.toString());
           ex.printStackTrace();
        }
    }

    public void runProgram(CpContext cpcontext) {
      connection = cpcontext.getJDBCConnection();

//    gsRootPath = getConfigValue("ROOT_PATH");

      gsRootPath = cpcontext.getEnvStore().getEnv("XXFIN_DATA"); // "/app/ebs/ebilling/dev01"  //gsRootPath = "\/tmp\/ebl\/";
      if (gsRootPath==null || gsRootPath.length()<2) {
          cpcontext.getReqCompletion().setCompletion(2, "ERROR");
          System.out.println("Error: $XXFIN_DATA not set");
          return;
      }
      gsRootPath += "/ebills";

      if (connection==null) {
        cpcontext.getReqCompletion().setCompletion(2, "ERROR");
        System.out.println("Error: connection is null");
        return;
      }
      try {
        connection.setAutoCommit(true);
      }
      catch (SQLException ex) {
        cpcontext.getReqCompletion().setCompletion(2, "ERROR");
        System.out.println("Error: Unable to setAutoCommit(true)\n" + ex.toString());
        ex.printStackTrace();
        return;
      }
    
      try {
        writeFiles();
        //cpcontext.getReqCompletion().setCompletion(0, "SUCCESS");
      }
      catch (Exception e) {
        System.out.println("writeFiles failed");
        e.printStackTrace();
        cpcontext.getReqCompletion().setCompletion(2, "ERROR");
      }

      cpcontext.getReqCompletion().setCompletion(0, "SUCCESS");      
    }

/*
    private String getConfigValue(String sParam) throws Exception {
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        String sResult = "";
        try {
            pstmt = connection.prepareStatement("SELECT target_value1 FROM XX_FIN_TRANSLATEDEFINITION D JOIN XX_FIN_TRANSLATEVALUES V ON D.translate_id=V.translate_id WHERE D.translation_name=? AND V.source_value1=? AND V.source_value2=? AND V.enabled_flag='Y' AND TRUNC(SYSDATE) BETWEEN V.start_date_active AND NVL(V.end_date_active,SYSDATE)");
            pstmt.setString(1,"AR_EBL_CONFIG");
            pstmt.setString(2,"TRANSMIT_CD");
            pstmt.setString(3,sParam);

            rs = pstmt.executeQuery();

            if (rs.next()) {
                sResult = rs.getString("target_value1");
                System.out.println("Param " + sParam + " : " + sResult + "\n");
            }
            else {
                throw new Exception ("translation row not found");
            }
        }
        catch (Exception ex) {
            throw new Exception("Error querying translation param " + sParam + "\n" + ex.toString());
        }
        finally {
          if (rs!=null) rs.close();
          if (pstmt!=null) pstmt.close();
        }
        return sResult;
    }
*/

    private void writeFiles() throws Exception {
        CallableStatement csTransmissions = null;
        ResultSet rsTransmissions = null;

        int nTransmissionId;
        String sPath;
        String sStatus;
        String sTransmissionType;
        int nCount = 0;
        int nSucceeded = 0;

        System.out.println("Beginning writeFiles...");

        try {
            csTransmissions = connection.prepareCall("BEGIN XX_AR_EBL_TRANSMISSION_PKG.TRANSMISSIONS_TO_WRITE_TO_CD(?); END;");
            csTransmissions.registerOutParameter(1, OracleTypes.CURSOR);
            csTransmissions.execute();
            rsTransmissions = (ResultSet)csTransmissions.getObject(1);

            while(rsTransmissions.next()) {
                nTransmissionId = rsTransmissions.getInt("transmission_id");
                sPath = rsTransmissions.getString("path");
                sStatus = rsTransmissions.getString("status");
                sTransmissionType = rsTransmissions.getString("transmission_type");
                nCount++;

                try {
                  writeTransmission(nTransmissionId, sPath);
                  System.out.println("Transmission " + nTransmissionId + " written");
                  nSucceeded++;
                  try {
                      if (sStatus.equals("TOOBIG") && !sTransmissionType.equals("CD")) sStatus="SENTBYCD";
                      else sStatus="SENT";
                      updateTransmissionStatus(nTransmissionId, sStatus, "");
                  }
                  catch (Exception e2) {
                      System.out.println("Error updating transmission status\n" + e2.toString());
                  }
                }
                catch (Exception e) {
                    System.out.println("Transmission " + nTransmissionId + " write failed: " + e.toString());
                    try {
                      updateTransmissionStatus(nTransmissionId, "ERROR", e.toString());
                    }
                    catch (Exception e3){
                        System.out.println("Error updating transmission status\n" + e3.toString());
                    }
                }
                System.out.println();
            }
        }
        catch (Exception ex) {
            ex.printStackTrace();
            throw new Exception("Error in writeFiles\n" + ex.toString());
        }
        finally {
            if (rsTransmissions!=null) rsTransmissions.close();
            if (csTransmissions!=null) csTransmissions.close();
        }
        System.out.println(nSucceeded + " of " + nCount + " transmissions successfully written to " + gsRootPath);
    }


    private void updateTransmissionStatus(int nTransmissionId, String sStatus, String sStatusDetail) throws Exception {
       PreparedStatement pstmt = null;
       try {
         pstmt = connection.prepareStatement("UPDATE XX_AR_EBL_TRANSMISSION SET status=?, status_detail=?, transmission_dt=SYSDATE, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id WHERE transmission_id=?");
         pstmt.setString(1,sStatus);
         pstmt.setString(2,sStatusDetail.substring(0,java.lang.Math.min(4000,sStatusDetail.length())));
         pstmt.setInt(3,nTransmissionId);
         pstmt.execute();
         pstmt.close();
       }
       catch (Exception ex){
          if (pstmt!=null) pstmt.close();
          throw new Exception("Unable to update transmission status\n" + ex.toString());
       }
    }


    private void writeTransmission(int nTransmissionId, String sPath) throws Exception {
        CallableStatement csFiles = null;
        ResultSet rsFiles = null;
        int nFileId;
        int nFileCount = 0;
    
        System.out.println("Writting transmission #" + nTransmissionId);
        try {

            csFiles = connection.prepareCall("BEGIN XX_AR_EBL_TRANSMISSION_PKG.FILES_TO_WRITE_TO_CD(?,?); END;");
            csFiles.setInt(1,nTransmissionId);
            csFiles.registerOutParameter(2, OracleTypes.CURSOR);
            csFiles.execute();
            rsFiles = (ResultSet)csFiles.getObject(2);

            while(rsFiles.next()) {
                nFileId = rsFiles.getInt("file_id");
                StatementFile sf = GetStatementFile(nFileId);
                writeFile(sPath, sf);
                nFileCount++;
            }
        }
        catch (Exception ex) {
            throw new Exception("writeTransmission " + nTransmissionId + " failed\n" + ex.toString());
        }
        finally {
            if (rsFiles!=null) rsFiles.close();
            if (csFiles!=null) csFiles.close();
        }
        if (nFileCount==0) throw new Exception ("writeTransmission " + nTransmissionId + ": query found no files to write.");
    }

    private void writeFile(String sPath, StatementFile sf) throws Exception
    {
        char cCorrectSeparator = System.getProperty("file.separator").charAt(0);
        char cWrongSeparator = '/';
        if (cCorrectSeparator=='/') cWrongSeparator = '\\';
        String sCorrectSeparator = Character.toString(cCorrectSeparator);

        String sName = gsRootPath.replace(cWrongSeparator,cCorrectSeparator);
        sPath = sPath.replace(cWrongSeparator,cCorrectSeparator);

        if (!sName.endsWith(sCorrectSeparator)) sName += cCorrectSeparator;
        if (sPath.startsWith(sCorrectSeparator)) sPath = sPath.substring(1);
        sName += sPath;
        if (!sName.endsWith(sCorrectSeparator)) sName += cCorrectSeparator;

        File oFile = new File(sName);
        oFile.mkdirs();

        sName += sf.getFileName();

        try {
            FileOutputStream out = new FileOutputStream(sName);
            out.write(sf.getFileData());
            out.close();
            System.out.println("File " + sName + " written");
        } catch (IOException e) {
            throw new Exception("File write failed: "+ sName + "\n" + e.toString());
        }
    }

    private StatementFile GetStatementFile(int nFileId)
    {
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        byte[] baFile = null;
        Blob aBlob = null;
        String sFileName = null;
        try
        {
            pstmt = connection.prepareStatement("SELECT file_name,file_data FROM XX_AR_EBL_FILE WHERE file_id = ?");
            pstmt.setInt(1,nFileId);
            rs = pstmt.executeQuery();
            rs.next();

            try
            {
                // Get as a BLOB
                aBlob = rs.getBlob(2);
                baFile = aBlob.getBytes(1, (int) aBlob.length());
                sFileName = rs.getString(1);
            }
            catch(Exception ex)
            {
                // The driver could not handle this as a BLOB...
                // Fallback to default (and slower) byte[] handling
                baFile = rs.getBytes(2);
                sFileName = rs.getString(1);
            }
            rs.close();
            if (pstmt != null) pstmt.close();
        }
        catch(Exception ex)
        {
            try {if (pstmt != null) pstmt.close();}
            catch(Exception ex2) {};
        }
        return (new StatementFile(sFileName, baFile));
    }
}