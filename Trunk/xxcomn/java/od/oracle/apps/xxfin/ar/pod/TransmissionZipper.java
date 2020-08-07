package od.oracle.apps.xxfin.ar.ebill;

import java.io.BufferedOutputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import java.sql.Blob;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.text.SimpleDateFormat;

import java.util.ArrayList;
import java.util.Date;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import oracle.apps.fnd.cp.request.JavaConcurrentProgram;
import oracle.apps.fnd.cp.request.CpContext;
import oracle.apps.fnd.util.NameValueType;

import oracle.jdbc.OracleTypes;
import oracle.jdbc.pool.OracleDataSource;

import oracle.sql.BLOB;


public class TransmissionZipper implements JavaConcurrentProgram {

    private Connection connection; // Database Connection Object

    public TransmissionZipper() {
    }

    public void runProgram(CpContext cpcontext) {
        connection = cpcontext.getJDBCConnection();
        if (connection==null) {
          cpcontext.getReqCompletion().setCompletion(2, "ERROR");
          System.out.println("Error: connection is null\n");
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

        NameValueType parameter;
        int nThreadID = -1;
        int nThreadCount = -1;
        
        // ==============================================================================================
        // get parameter list from concurrent program
        // ==============================================================================================
        parameter = cpcontext.getParameterList().nextParameter();
          
        // ==============================================================================================
        // get next CP parameter (parameter1 = THREAD_ID)
        // ==============================================================================================
        if (parameter.getName().equals("THREAD_ID")) {
          if (parameter.getValue() != null && parameter.getValue() != "") {
            nThreadID = Integer.parseInt(parameter.getValue());
          }
        }
        else {
          System.out.println("Parameter THREAD_ID should be Parameter 1.");
        }

        parameter = cpcontext.getParameterList().nextParameter();

        // ==============================================================================================
        // get next CP parameter (parameter2 = THREAD_COUNT)
        // ==============================================================================================
        if (parameter.getName().equals("THREAD_COUNT")) {
          if (parameter.getValue() != null && parameter.getValue() != "") {
            nThreadCount = Integer.parseInt(parameter.getValue());
          }
        }
        else {
          System.out.println("Parameter THREAD_COUNT should be Parameter 2.");
        }

        System.out.println("  THREAD_ID     : " + nThreadID );
        System.out.println("  THREAD_COUNT  : " + nThreadCount );
        System.out.println("");

        if (nThreadID<1 || nThreadCount<1) {
            System.out.println("\nTHREAD_ID and THREAD_COUNT should be > 0");
            cpcontext.getReqCompletion().setCompletion(2, "ERROR");
            return;
        }
        if (nThreadID > nThreadCount) {
            System.out.println("\nTHREAD_ID should be less than or equal to THREAD_COUNT");
            cpcontext.getReqCompletion().setCompletion(2, "ERROR");
            return;
        }

        
        nThreadID--; // mod function needs zero based threadID

        try {
           ZipTransmissions(nThreadID,nThreadCount);
           System.out.println("\nZip succeeded");
        }
        catch (Exception ex) {
            System.out.println("Zip thread failed\n" + ex.toString());
            ex.printStackTrace();
        }

        try {
           connection.close();
        }
        catch(SQLException ex) {
           System.out.println("Error While Closing Connection .." + ex.toString());
           ex.printStackTrace();
           cpcontext.getReqCompletion().setCompletion(2, "ERROR");
           return;
        }

        cpcontext.getReqCompletion().setCompletion(0, "SUCCESS");
    }


    private void ZipTransmissions(int nThreadID, int nThreadCount) throws Exception{
        CallableStatement csTransmissions = null;
        ResultSet rsTransmissions = null;

        try {
            csTransmissions = connection.prepareCall("BEGIN XX_AR_EBL_RENDER_ZIP_PKG.TRANSMISSIONS_TO_ZIP(?,?,?); END;");
            csTransmissions.setInt(1,nThreadID);
            csTransmissions.setInt(2,nThreadCount);
            csTransmissions.registerOutParameter(3, OracleTypes.CURSOR);
            csTransmissions.execute();
            rsTransmissions = (ResultSet)csTransmissions.getObject(3);
            while (rsTransmissions.next()) {
                int nTransmissionID = rsTransmissions.getInt("transmission_id");
                System.out.println("Zipping Transmission_id " + nTransmissionID);
                try {
                    ZipFiles(nTransmissionID);
                }
                catch (Exception zipEx) {
                    zipEx.printStackTrace();
                    System.out.println("  ZipFiles Error\n" + zipEx.toString());
                    PreparedStatement pstmt = null;
                    try {
                        System.out.println("  Setting RENDER_ERROR status");
                        pstmt = connection.prepareStatement ("update XX_AR_EBL_FILE SET file_data=?, status='RENDER_ERROR', status_detail=?, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id WHERE transmission_id=? AND file_type='ZIP'");
                        pstmt.setBlob(1, (Blob)null);
                        pstmt.setString(2,zipEx.toString());
                        pstmt.setInt(3, nTransmissionID);
                        pstmt.execute();
                    }
                    catch (Exception updateEx) {
                        System.out.println("Error setting RENDER_ERROR status " + updateEx.toString()); // need to proceed, but this will write to log
                    }
                    finally {
                        if (pstmt!=null) pstmt.close();                        
                    }
                }
            }
        }
        catch (Exception ex){
            ex.printStackTrace();
            throw new Exception("Error in ZipTransmissions\n" + ex.toString());
        }
        finally {
            if (rsTransmissions!=null) rsTransmissions.close();
            if (csTransmissions!=null) csTransmissions.close();
        }
    }

     private void ZipFiles(int nTransmissionID) throws Exception {
        PreparedStatement pstmt = null;
        CallableStatement csFiles = null;
        ResultSet rsFiles = null;

        ByteArrayOutputStream baosDest = new ByteArrayOutputStream();
        ZipOutputStream zosOut = new ZipOutputStream(new BufferedOutputStream(baosDest));

        try {
            csFiles = connection.prepareCall("BEGIN XX_AR_EBL_RENDER_ZIP_PKG.FILES_TO_ZIP(?,?); END;");
            csFiles.setInt(1,nTransmissionID);
            csFiles.registerOutParameter(2, OracleTypes.CURSOR);
            csFiles.execute();
            rsFiles = (ResultSet)csFiles.getObject(2);

            baosDest = new ByteArrayOutputStream();
            zosOut = new ZipOutputStream(new BufferedOutputStream(baosDest));

            while (rsFiles.next()) {
                int nFileID = rsFiles.getInt("file_id");
                String sFileName = rsFiles.getString("file_name");
                Blob blob = rsFiles.getBlob("file_data");
                System.out.println("Adding file_id " + nFileID + ": " + sFileName);

                ZipEntry entry = new ZipEntry(sFileName);
                zosOut.putNextEntry(entry);
                zosOut.write(blob.getBytes((long)1,(int) blob.length()));
                zosOut.closeEntry();
            }
            zosOut.close();

            byte[] ba = baosDest.toByteArray();
            ByteArrayInputStream bais = new ByteArrayInputStream(ba);

            BLOB blob = BLOB.createTemporary(connection,true,BLOB.DURATION_SESSION);

            java.io.OutputStream os = blob.getBinaryOutputStream();
            os.write(ba);
            os.flush();
            os.close();

            pstmt = connection.prepareStatement ("update XX_AR_EBL_FILE SET file_data=?, status='RENDERED', last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id WHERE transmission_id=? AND file_type='ZIP'");
            pstmt.setBlob(1, blob);
            pstmt.setInt(2, nTransmissionID);
            pstmt.execute();

/*
            FileOutputStream fout = new FileOutputStream("transmission" + nTransmissionID + ".zip");
            fout.write(ba);
            fout.close();
            System.out.println("Zip file written");
*/
        }
        catch (Exception zipEx) {
            throw new Exception("Error in ZipFiles\n" + zipEx.toString());
        }
        finally {
            if (pstmt!=null) pstmt.close();
            if (rsFiles!=null) rsFiles.close();
            if (csFiles!=null) csFiles.close();
            if (baosDest!=null) baosDest.close();
            if (zosOut!=null) zosOut.close();
        }
     }
}
