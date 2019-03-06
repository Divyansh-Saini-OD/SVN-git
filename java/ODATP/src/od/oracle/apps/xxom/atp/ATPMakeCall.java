/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             AtpmakeCall.java                                              |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This class implements the Generic way of calling database              |
 |    PL/SQL packages and executing and retrieving the resut sets            |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class will be called from AtpProcessControl.java                     |
 |                                                                           |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/11/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp;

import java.io.IOException;

import java.sql.SQLException;

import od.oracle.apps.xxom.atp.pool.ConnectionPoolMgr;
import od.oracle.apps.xxom.atp.thread.ThreadBarrier;
import od.oracle.apps.xxom.atp.xml.XMLDocumentHandler;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.oci.OracleOCIConnection;

import org.xml.sax.SAXException;


/** 
 * Implements the execution of database PL/SQL procedure. The call
 * is constructed / executed dynamically. The variable - parameter mapping
 * and the PL/SQL procedure metadata is stored.
 * 
 * @author Satis-Gnanmani
 * @version 1.1
 * 
 **/
public class ATPMakeCall implements Runnable {

    /**
     * Header Information
     **/
    public static final String RCS_ID = 
        "$Header: AtpmakeCall.java  06/11/2007 Satis-Gnanmani$";

    private ATPRecordType atprec;
    private ATPResultSetType resultset;
    private OracleOCIConnection conn;
    private ConnectionPoolMgr cmgr;
    private XMLDocumentHandler xmlhandler;
    private OracleCallableStatement oraclecallablestatement;
    private ATPConstants atpconstants;
    private String code;
    private String[] inputParameters;
    private String[] outputParameters;
    private String[] inJavaTypes;
    private String[] outJavaTypes;
    private String[] inSqlTypes;
    private String[] outSqlTypes;
    private String[] inParamValues;
    private int[] parameterIndex;
    private int[] inputIndex;
    private int[] outputIndex;
    private ThreadBarrier barrier;


    /**
     * Constructs an instance of the ATPMakeCall with the data in the atprec 
     * object type, establishes a connection through the connection pool mgr
     * and after compeletion of the database call loads the result set object
     * type resultset and hits the barrier
     * 
     * @param atprec Object type with all necessary data
     * @param resultset Object type with all result set data
     * @param mgr The connection pool manager instance 
     * 
     **/
    public ATPMakeCall(ATPRecordType atprec, ATPResultSetType resultset, 
                ConnectionPoolMgr mgr, ThreadBarrier barrier) {
        this.cmgr = mgr;
        this.resultset = resultset;
        this.code = resultset.getCallName();
        this.atprec = new ATPRecordType();
        this.atprec = atprec;
        this.xmlhandler = new XMLDocumentHandler();
        this.barrier = barrier;
    }

    /**
     *  Executes entire process of connectiong to database, executing the 
     *  procedure call, retieving the result set data.
     *  
     **/
    public void run() {
        long start = System.currentTimeMillis();
        makecall();
        long stop = System.currentTimeMillis();
        System.out.println("Time for this execution is : " + 
                           Math.round((stop - start) * 0.001) + " Seconds");
        try {
            barrier.waitForRest();
        } catch (InterruptedException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
            notifyAll();
        }
    }

    /**
     * Returns the atprec object type which holds all the necessary data
     * 
     * @return atprec  Object type with all necessary data
     * 
     **/
    public ATPRecordType getAtprec() {
        return atprec;
    }

    /**
     * Returns the resultset object type which holds all the result set data
     * 
     * @return resultset  Object type with all result set data
     */
    public ATPResultSetType getResultset() {
        return resultset;
    }

    private String getPkgName() throws SAXException, IOException {
        return xmlhandler.getExecutable();
    }

    private void getInputParameters() throws SAXException, IOException {
        try {
            inputIndex = this.xmlhandler.getInputIndex();
            inputParameters = this.xmlhandler.getInputJavaNames();
            inJavaTypes = this.xmlhandler.getInputJavaTypes();
            inSqlTypes = this.xmlhandler.getInputSqlNames();
            inParamValues = this.xmlhandler.getInputParamValues();
        } catch (SAXException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (IOException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        }
    }

    private void getOutputParameters() throws SAXException, IOException {
        try {
            outputIndex = this.xmlhandler.getOutputIndex();
            outputParameters = this.xmlhandler.getOutputJavaNames();
            outJavaTypes = this.xmlhandler.getOutputJavaTypes();
            outSqlTypes = this.xmlhandler.getOutputSqlNames();
        } catch (SAXException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (IOException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        }
    }

    private void prepareStatement(int[] paramindex, 
                                  String pkgName) throws SQLException {
        try {
            StringBuffer stringbuffer = new StringBuffer(1000);
            stringbuffer.append("BEGIN ");
            stringbuffer.append(pkgName);
            stringbuffer.append("(");
            for (int i = 0; i < paramindex.length - 1; i++) {
                stringbuffer.append(":" + paramindex[i] + ", ");
            }
            stringbuffer.append(":" + paramindex.length);
            stringbuffer.append(");");
            stringbuffer.append("END;");
            this.oraclecallablestatement = 
                    (OracleCallableStatement)this.conn.prepareCall(stringbuffer.toString());
        } catch (SQLException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        }
    }

    private void setInputParameters(int[] paramindex, String[] inParams, 
                                    String[] inParamValues) throws SQLException, 
                                                                   IllegalAccessException, 
                                                                   NoSuchFieldException {
        try {
            for (int i = 0; i < paramindex.length; i++) { /*get(atprec)*/
                if (inParamValues[i] == null) {
                    oraclecallablestatement.setObject(paramindex[i], 
                                                      atprec.getClass().getField(inParams[i]).get(atprec)); //
                } else {
                    oraclecallablestatement.setObject(paramindex[i], 
                                                      inParamValues[i]);
                }
            }
        } catch (SQLException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (IllegalAccessException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (NoSuchFieldException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        }
    }

    private void registerOutputParameters(int[] paramindex, 
                                          String[] outjavaTypes) throws SQLException, 
                                                                        IllegalAccessException, 
                                                                        NoSuchFieldException {
        try {
            for (int i = 0; i < paramindex.length; i++) {
                oraclecallablestatement.registerOutParameter(paramindex[i], 
                                                             atpconstants.getIntValue(outjavaTypes[i]));
            }
        } catch (SQLException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (NoSuchFieldException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        }
    }

    private void getValues(int[] paramindex, 
                           String[] outParams) throws NoSuchFieldException, 
                                                      IllegalAccessException, 
                                                      SQLException {
        try {
            for (int i = 0; i < paramindex.length; i++) {
                this.resultset.getClass().getField(outParams[i]).set(resultset, 
                                                                     oraclecallablestatement.getObject(paramindex[i]));
            }
        } catch (IllegalAccessException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (SQLException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (NoSuchFieldException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } // End getValues.

    }

    private void executeStatement() throws SQLException {
        try {
            oraclecallablestatement.execute();
        } catch (SQLException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } finally {
            if (conn != null) {
                conn.close();
                conn = null;
            }
        }
    }

    private void prepareCall() throws SAXException, IOException, SQLException, 
                                      IllegalAccessException, 
                                      NoSuchFieldException {
        try {
            xmlhandler.setParser(code);
            String packageName = this.getPkgName();
            getInputParameters();
            getOutputParameters();
            int x = 0;
            int length = inputIndex.length + outputIndex.length;
            parameterIndex = new int[length];
            for (int j = 0; j < parameterIndex.length; j++) {
                if (j < inputIndex.length)
                    parameterIndex[j] = inputIndex[j];
                else {
                    parameterIndex[j] = outputIndex[x];
                    x++;
                }
            } //End For.
            conn = cmgr.getConnection();
            prepareStatement(parameterIndex, packageName);
            setInputParameters(inputIndex, inputParameters, inParamValues);
            registerOutputParameters(outputIndex, outJavaTypes);
            executeStatement();
            getValues(outputIndex, outputParameters);
        } catch (IllegalAccessException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (SAXException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (SQLException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (IOException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (NoSuchFieldException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        }
    }

    private void makecall() {
        try {
            prepareCall();
        } catch (IllegalAccessException e) {
            System.out.println("Illegal Exception in makecall: " + 
                               e.getMessage());
        } catch (SAXException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (SQLException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (IOException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        } catch (NoSuchFieldException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        }
    }
}

