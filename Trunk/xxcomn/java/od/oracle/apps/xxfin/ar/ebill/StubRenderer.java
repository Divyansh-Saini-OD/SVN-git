package od.oracle.apps.xxfin.ar.ebill;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;

import java.sql.Blob;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.Properties;

import oracle.apps.fnd.cp.request.CpContext;
import oracle.apps.fnd.cp.request.JavaConcurrentProgram;
import oracle.apps.fnd.util.NameValueType;
import oracle.apps.xdo.template.FOProcessor;

import oracle.jdbc.OracleTypes;
import oracle.jdbc.pool.OracleDataSource;

import oracle.sql.BLOB;


public class StubRenderer implements JavaConcurrentProgram {

    private Connection connection; // Database Connection Object
    private String gsConfigPath = "";

    public StubRenderer() {
    }
    
    // main is only used for testing; EBS will call runProgram (see below)
    public static void main(String[] args) {
        StubRenderer stubRenderer = new StubRenderer();
        
        try {
          OracleDataSource ods = new OracleDataSource();
          ods.setURL("jdbc:oracle:thin:apps/dev01apps@//choldbr18d-vip.na.odcorp.net:1531/GSIDEV01");
          stubRenderer.connection=ods.getConnection();
          stubRenderer.connection.setAutoCommit(true);
        } catch(SQLException ex) {
           ex.printStackTrace();
           System.out.println("Error Connecting to the Database\n" + ex.toString());
        }

        try {
           int nThreadID = 0;
           int nThreadCount = 2;

           stubRenderer.RenderStubs(nThreadID,nThreadCount);
           System.out.println("\nStub Rendering succeeded");
        }
        catch (Exception ex) {
            System.out.println("Stub Renderer thread failed\n" + ex.toString());
            ex.printStackTrace();
        }
        
        try {
           stubRenderer.connection.close();
        }
        catch(SQLException ex) {
           System.out.println("Error Closing Connection\n" + ex.toString());  // can't really do much here
           ex.printStackTrace();
        }
    }

    // This is the EBS concurrent program entry point
    public void runProgram(CpContext cpcontext) {
        connection = cpcontext.getJDBCConnection();

        gsConfigPath = cpcontext.getEnvStore().getEnv("XXFIN_TOP") + "/media/";

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
           RenderStubs(nThreadID,nThreadCount);
           System.out.println("\nStub rendering thread done.");
        }
        catch (Exception ex) {
            ex.printStackTrace();        
            System.out.println("\nStub rendering thread failed" + ex.toString());
        }

        cpcontext.getReqCompletion().setCompletion(0, "SUCCESS");
    }


    /*
    // To Merge PDFs:

    FileInputStream[] inputStreams = new FileInputStream[2];

    inputStreams[0] = new FileInputStream("catalog.pdf");
    inputStreams[1] = new  FileInputStream("catalog2.pdf");

    FileOutputStream  outputStream = new FileOutputStream("catalog3.pdf");

    PDFDocMerger pdfMerger =  new PDFDocMerger(inputStreams, outputStream);

    //To add page numbering, specify the page numbering coordinates and the page numbering font:
    //
    //pdfMerger.setPageNumberCoordinates(300, 20);
    //pdfMerger.setPageNumberFontInfo("Courier", 10);
    //
    //  Set the page numbering value with the setPageNumberValue(int initialValue, int startPageIndex) method. 
    //    The initialValue specifies the initial value of page numbering. 
    //    The startPageIndex specifies the page number from which numbering should start
    //
    //pdfMerger.setPageNumberValue(1, 1); 

    pdfMerger.process();
    */


    private byte[] GetTemplate() throws Exception {
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        Blob blob = null;
        byte[] ba = null;

        try {
            pstmt = connection.prepareStatement ("select file_data from xdo_lobs where lob_code=? and lob_type=?");
//          pstmt.setString(1,"IDAutomationOCRa");
            pstmt.setString(1,"XXAREBLREM");
//          pstmt.setString(2,"TEMPLATE_SOURCE");
//          pstmt.setString(2,"TRUETYPE_FONT");
            pstmt.setString(2,"TEMPLATE");
            rs = pstmt.executeQuery();
            rs.next();
            blob = rs.getBlob("file_data");

            ba = blob.getBytes(1,(int)blob.length());
/*
        // Write template to file:
            FileOutputStream fout = new FileOutputStream("template.rtf");
            fout.write(blob.getBytes(1,(int)blob.length()));
            fout.close();
            System.out.println("template written");
*/
        }
        catch (Exception ex) {
            ex.printStackTrace();        
            throw new Exception("Error reading file_data from xdo_lobs where lob_code='XXAREBLREM' and lob_type='TEMPLATE' for FO processing\n"+ex.toString());
        }
        finally {
            try {rs.close();} catch (Exception ex) {}
            try {pstmt.close();} catch (Exception ex) {}
        }
        return ba;
    }

    private void RenderStubs(int nThreadID, int nThreadCount) throws Exception{
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        Blob blob = null;

        ByteArrayInputStream isTemplate = null;

        // Get the file rows that need to be rendered
        CallableStatement csFiles = null;
        ResultSet rsFiles = null;
        try {
            csFiles = connection.prepareCall("BEGIN XX_AR_EBL_RENDER_STUB_PKG.STUBS_TO_RENDER(?,?,?); END;");
            csFiles.setInt(1,nThreadID);
            csFiles.setInt(2,nThreadCount);
            csFiles.registerOutParameter(3, OracleTypes.CURSOR);
            csFiles.execute();
            rsFiles = (ResultSet)csFiles.getObject(3);
            while (rsFiles.next()) {
                if (isTemplate==null) isTemplate = new ByteArrayInputStream(GetTemplate());
                else isTemplate.reset();

                int nFileID = rsFiles.getInt("file_id");
                System.out.println("Rendering stub file_id " + nFileID);
                try {
                    RenderStub(nFileID, isTemplate);
                }
                catch (Exception renderEx) {
                    renderEx.printStackTrace();
                    System.out.println("  RenderStubs Error\n" + renderEx.toString());
                    pstmt = null;

                    try {
                        System.out.println("  Setting RENDER_ERROR status");
                        pstmt = connection.prepareStatement ("update XX_AR_EBL_FILE SET file_data=?, status='RENDER_ERROR', status_detail=?, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id WHERE file_id = ?");
                        pstmt.setBlob(1, (Blob)null);
                        pstmt.setString(2,renderEx.toString());
                        pstmt.setInt(3, nFileID);
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
            throw new Exception("Error in RenderStubs\n" + ex.toString());
        }
        finally {
            if (rsFiles!=null) rsFiles.close();
            if (csFiles!=null) csFiles.close();
        }
    }

     private void RenderStub(int nFileID, InputStream isTemplate) throws Exception {
        PreparedStatement pstmt = null;
        CallableStatement csXML = null;
        ResultSet rsFiles = null;

        ByteArrayOutputStream baosDest = new ByteArrayOutputStream();

        try {
            csXML = connection.prepareCall("BEGIN XX_AR_EBL_RENDER_STUB_PKG.GET_STUB_XML(?,?); END;");
            csXML.setInt(1,nFileID);
            csXML.registerOutParameter(2, OracleTypes.CLOB);
            csXML.execute();

            InputStream isXML = csXML.getClob(2).getAsciiStream();


            baosDest = new ByteArrayOutputStream();

            FOProcessor processor = new FOProcessor();

            Properties prop = new Properties();
////        prop.put("fo-pdf-font-mapping","XXFIN_AR_BILLS"); // API doesn't read xdo tables, so this won't work.
//                                                               Also, doesn't see possible to have FOProcessor read font blob from xdo_lobs table the way BI Pub does
//                                                               So, we will deploy fonts via file migration and reference them with full path via config prop
//          prop.put("pdf-security","true");
//          prop.put("pdf-open-password","welcome");
            prop.put("font.IDAutomationOCRa.normal.normal","truetype." + gsConfigPath + "IDAutomationOCRa.ttf");
            processor.setConfig(prop);
//          processor.setConfig(gsConfigPath + "xdo_XXAREBLREM.cfg"); // it is possible to give font paths in cfg, but full path is needed which is tough across instances without env vars.
                                                                      // could also just put the font files in the default font path under jre, but admins would have to do it.

            processor.setData(isXML);
//            processor.setTemplate("template.xsl");

            processor.setTemplate(isTemplate);
            processor.setOutput(baosDest);
//            processor.setOutput("/home/u250648/stub.pdf");
//            processor.setOutput("stub" + nFileID + ".pdf");
            processor.setOutputFormat(FOProcessor.FORMAT_PDF);
            processor.generate();

            byte[] ba = baosDest.toByteArray();
            ByteArrayInputStream bais = new ByteArrayInputStream(ba);

            BLOB blob = BLOB.createTemporary(connection,true,BLOB.DURATION_SESSION);

            java.io.OutputStream os = blob.getBinaryOutputStream();
            os.write(ba);
            os.flush();
            os.close();

            pstmt = connection.prepareStatement ("update XX_AR_EBL_FILE SET file_data=?, status='RENDERED', file_type='PDF', status_detail=null, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id WHERE file_id = ?");
            pstmt.setBlob(1, blob);
            pstmt.setInt(2, nFileID);
            pstmt.execute();

/*
 // create file
            FileOutputStream fout = new FileOutputStream("stub" + nFileID + ".pdf");
            fout.write(ba);
            fout.close();
            System.out.println("Stub file written");
*/
        }
        catch (Exception stubEx) {
            throw new Exception("Error in RenderStub\n" + stubEx.toString());
        }
        finally {
            if (pstmt!=null) pstmt.close();
            if (rsFiles!=null) rsFiles.close();
            if (csXML!=null) csXML.close();
            if (baosDest!=null) baosDest.close();
        }
     }
}
