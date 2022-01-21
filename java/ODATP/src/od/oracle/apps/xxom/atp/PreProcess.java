/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             PreProcess.java                                               |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This class is the pre processing class used to retrieve all            |
 |    the derived attributes related to making the atp call                  |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class will be invoked AtpProcessControl.java                      |
 |                                                                           |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/06/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp;

import java.math.BigDecimal;

import java.sql.SQLException;

import od.oracle.apps.xxom.atp.pool.ConnectionPoolMgr;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import oracle.jdbc.oci.OracleOCIConnection;


/**
 * This Class executes the PreProcess step of the ATP process. It makes the
 * necessary cal to the Pl/Sql PreProcess API and retrieves the data.
 * 
 */
public class PreProcess {

    /**
     * Header Information
     **/
    public static final String RCS_ID = 
        "$Header: PreProcess.java  06/06/2007 Satis-Gnanmani$";

    /**
     * The default constructor to invoke the PreProcess. Requires the ATP 
     * object type record and connection pol manager instance to use to get 
     * database connections.
     * 
     * @param atprec ATP inquiry data object type
     * @param cmgr Connection pool manager Instance
     * 
     **/
    public PreProcess(ATPRecordType atprec, ConnectionPoolMgr cmgr) {
        this.cmgr = cmgr;
        this.atprec = atprec;
    }
    
    private OracleOCIConnection conn;
    private OracleCallableStatement oraclecallablestatement;
    private ConnectionPoolMgr cmgr;
    private ATPRecordType atprec;

    /**
     * Executes the PreProcess API in full and provides the results in the 
     * atprec object type.
     * 
     * @return atprec ATPRecordType object with all the PreProcess data 
     * 
     **/
    public ATPRecordType callPreProcess() {
        try {
            long start = System.currentTimeMillis();
            Connect();
            oraclecallablestatement = getCallableStatement(conn, atprec);
            atprec = executeStatement(atprec, oraclecallablestatement);
            LogATP.printPreProcessResults(atprec); // remove this line for deployment - debugging only
            long stop = System.currentTimeMillis();
            System.out.println("Time for PreProcess execution is : " + 
                               Math.round((stop - start) * 0.001) + 
                               " Seconds");
        } catch (SQLException e) {
            System.out.println(" Pre Process could not be executed.");
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
            atprec.setErrorCode(new BigDecimal(21));
            atprec.setErrorMessage("Could not Execute Pre-Process");
            atprec.setReturnStatus("E");
        }
        return atprec;
    }
    
    private void Connect() throws SQLException {
        try {
            conn = cmgr.getConnection();
        } catch (SQLException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
        }

    }

    private OracleCallableStatement getCallableStatement(OracleOCIConnection conn1, 
                                                         ATPRecordType atprec) throws SQLException {
        oraclecallablestatement = 
                (OracleCallableStatement)conn1.prepareCall("BEGIN " + 
                                                           "XX_MSC_ATP_WRAPPER_PKG.Call_ATP_PRE_PROCESS ( :1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18,:19,:20,:21,:22,:23,:24,:25,:26,:27,:28,:29,:30); END ; ");
        if (atprec.getItemNumber() != null) {
            oraclecallablestatement.setString(1, atprec.getItemNumber());
        } else {
            oraclecallablestatement.setNull(1, 12);
        }
        if (atprec.getQuantity() != null) {
            oraclecallablestatement.setBigDecimal(2, atprec.getQuantity());
        } else {
            oraclecallablestatement.setNull(2, 12);
        }
        if (atprec.getQuantityUOM() != null) {
            oraclecallablestatement.setString(3, atprec.getQuantityUOM());
        } else {
            oraclecallablestatement.setNull(3, 12);
        }
        if (atprec.getCustNumber() != null) {
            oraclecallablestatement.setString(4, atprec.getCustNumber());
        } else {
            oraclecallablestatement.setNull(4, 12);
        }
        if (atprec.getCustShiptoLoc() != null) {
            oraclecallablestatement.setString(5, atprec.getCustShiptoLoc());
        } else {
            oraclecallablestatement.setNull(5, 12);
        }
        if (atprec.getShiptoLocPostalCode() != null) {
            oraclecallablestatement.setString(6, atprec.getShiptoLocPostalCode());
        } else {
            oraclecallablestatement.setNull(6, 12);
        }
        if (atprec.getCurrentDate() != null) {
            oraclecallablestatement.setDate(7, atprec.getCurrentDate());
        } else {
            oraclecallablestatement.setNull(7, 91);
        }
        if (atprec.getTimezoneCode() != null) {
            oraclecallablestatement.setString(8, atprec.getTimezoneCode());
        } else {
            oraclecallablestatement.setNull(8, 12);
        }
        if (atprec.getRequestedDate() != null) {
            oraclecallablestatement.setDate(9, atprec.getRequestedDate());
        } else {
            oraclecallablestatement.setNull(9, 91);
        }
        if (atprec.getOrderType() != null) {
            oraclecallablestatement.setString(10, atprec.getOrderType());
        } else {
            oraclecallablestatement.setNull(10, 12);
        }
        if (atprec.getShipMethod() != null) {
            oraclecallablestatement.setString(11, atprec.getShipMethod());
        } else {
            oraclecallablestatement.setNull(11, 12);
        }
        if (atprec.getShipFromOrg() != null) {
            oraclecallablestatement.setString(12, atprec.getShipFromOrg());
        } else {
            oraclecallablestatement.setNull(12, 12);
        }
        if (atprec.getOperatingUnit() != null) {
            oraclecallablestatement.setBigDecimal(13, 
                                                  atprec.getOperatingUnit());
        } else {
            oraclecallablestatement.setNull(13, 12);
        }
        oraclecallablestatement.registerOutParameter(14, 12);
        oraclecallablestatement.registerOutParameter(15, 2);
        oraclecallablestatement.registerOutParameter(16, 2);
        oraclecallablestatement.registerOutParameter(17, 12);
        oraclecallablestatement.registerIndexTableOutParameter(18, 200, 
                                                               OracleTypes.VARCHAR, 
                                                               240);
        oraclecallablestatement.registerIndexTableOutParameter(19, 200, 
                                                               OracleTypes.NUMBER, 
                                                               200);
        oraclecallablestatement.registerOutParameter(20, 2);
        oraclecallablestatement.registerOutParameter(21, 12);
        oraclecallablestatement.registerOutParameter(22, 2);
        oraclecallablestatement.registerOutParameter(23, 12);
        oraclecallablestatement.registerOutParameter(24, 2);
        oraclecallablestatement.registerOutParameter(25, 12);
        oraclecallablestatement.registerOutParameter(26, 2);
        oraclecallablestatement.registerOutParameter(27, 12);
        oraclecallablestatement.registerOutParameter(28, 2);
        oraclecallablestatement.registerOutParameter(29, 12);
        oraclecallablestatement.registerOutParameter(30, 12);
        return oraclecallablestatement;
    }

    private ATPRecordType executeStatement(ATPRecordType atprec, 
                                           OracleCallableStatement oraclecallablestatement) {
        try {
            oraclecallablestatement.execute();
            atprec.setBaseOrg(oraclecallablestatement.getString(14));
            atprec.setBaseOrgId(oraclecallablestatement.getBigDecimal(15));
            atprec.setInventoryItemId(oraclecallablestatement.getBigDecimal(16));
            atprec.setOrderFlowType(oraclecallablestatement.getString(17));
            atprec.setAtpTypeCode((String[])oraclecallablestatement.getPlsqlIndexTable(18));
            atprec.setAtpSequence((BigDecimal[])oraclecallablestatement.getPlsqlIndexTable(19));
            atprec.setAssignmentSetId(oraclecallablestatement.getBigDecimal(20));
            atprec.setItemValOrg(oraclecallablestatement.getString(21));
            atprec.setCategorySetId(oraclecallablestatement.getBigDecimal(22));
            atprec.setItemPlanningCategory(oraclecallablestatement.getString(23));
            atprec.setZoneId(oraclecallablestatement.getBigDecimal(24));
            atprec.setForcedSubstitute(oraclecallablestatement.getString(25));
            atprec.setXrefItemId(oraclecallablestatement.getBigDecimal(26));
            atprec.setPickupFlag(oraclecallablestatement.getString(27));
            atprec.setSessionId(oraclecallablestatement.getBigDecimal(28));
            atprec.setReturnStatus(oraclecallablestatement.getString(29));
            atprec.setErrorMessage(oraclecallablestatement.getString(30));
        } catch (SQLException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
            atprec.setErrorCode(new BigDecimal(21));
            atprec.setErrorMessage("Could not Execute Pre-Process : SQL Exception");
        } catch (NullPointerException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
            atprec.setErrorCode(new BigDecimal(21));
            atprec.setErrorMessage("Could not Execute Pre-Process : Null Pointer Exception");
        } catch (Exception e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(), e.getStackTrace()); e.printStackTrace(); e.printStackTrace(); e.printStackTrace();
            atprec.setErrorCode(new BigDecimal(21));
            atprec.setErrorMessage("Could not Execute Pre-Process : Exception");
        } finally {
            if (oraclecallablestatement != null)
                //oraclecallablestatement.close();
                oraclecallablestatement = null;
        }
        return atprec;
    }
}
