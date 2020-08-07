package od.oracle.apps.xxom.atp.flows;

import java.math.BigDecimal;

import java.sql.Date;
import java.sql.SQLException;

import od.oracle.apps.xxom.atp.ATPRecordType;
import od.oracle.apps.xxom.atp.PreProcess;
import od.oracle.apps.xxom.atp.pool.ConnectionPoolMgr;
import od.oracle.apps.xxom.atp.thread.ThreadPool;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.oci.OracleOCIConnection;


/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |                             Clearpath Consulting                             |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             AlternateSourcing.java                                               |
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
public class AlternateSourcing {

    public AlternateSourcing(ATPRecordType atprecin, ConnectionPoolMgr mgr) {
        cmgr = mgr;
        atprec = atprecin;
    }
    private OracleOCIConnection conn;
    private OracleCallableStatement oraclecallablestatement;
    private ConnectionPoolMgr cmgr;
    private ATPRecordType atprec;

    /**
     *
     * @throws SQLException
     */
    private void Connect() throws SQLException {
        try {
            conn = cmgr.getConnection();
        } catch (SQLException e) {
            e.printStackTrace();
            System.out.println("Exception in Preprocess GetConnection : " + 
                               e.getMessage());
        }

    }

    /**
     * @param conn1
     * @param atprec
     * @return
     * @throws SQLException
     */
    private OracleCallableStatement getCallableStatement(OracleOCIConnection conn1, 
                                                         ATPRecordType atprec) throws SQLException {
        oraclecallablestatement = 
                (OracleCallableStatement)conn1.prepareCall("BEGIN " + 
                                                           "XX_MSC_SOURCING_ALT_ATP_PKG.ALT_ORG_ATP( :1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13, :14, :15, :16, :17, :18,:19,:20,:21,:22,:23,:24); END ; ");
        if (atprec.getCustNumber() != null) {
            oraclecallablestatement.setString(1, atprec.getCustNumber());
        } else {
            oraclecallablestatement.setNull(1, 12);
        }
        if (atprec.getInventoryItemId() != null) {
            oraclecallablestatement.setBigDecimal(2, 
                                                  atprec.getInventoryItemId());
        } else {
            oraclecallablestatement.setNull(2, 2);
        }
        if (atprec.getQuantity() != null) {
            oraclecallablestatement.setBigDecimal(3, atprec.getQuantity());
        } else {
            oraclecallablestatement.setNull(3, 2);
        }
        if (atprec.getQuantityUOM() != null) {
            oraclecallablestatement.setString(4, atprec.getQuantityUOM());
        } else {
            oraclecallablestatement.setNull(4, 12);
        }
        if (atprec.getRequestedDate() != null) {
            oraclecallablestatement.setDate(5, atprec.getRequestedDate());
        } else {
            oraclecallablestatement.setNull(5, 91);
        }
        if (atprec.getCustShiptoLoc() != null) {
            oraclecallablestatement.setString(6, atprec.getCustShiptoLoc());
        } else {
            oraclecallablestatement.setNull(6, 12);
        }
        if (atprec.getShiptoLocPostalCode() != null) {
            oraclecallablestatement.setString(7, atprec.getShiptoLocPostalCode());
        } else {
            oraclecallablestatement.setNull(7, 12);
        }
        if (atprec.getShipMethod() != null) {
            oraclecallablestatement.setString(8, atprec.getShipMethod());
        } else {
            oraclecallablestatement.setNull(8, 12);
        }
        if (atprec.getAssignmentSetId() != null) {
            oraclecallablestatement.setBigDecimal(9, 
                                                  atprec.getAssignmentSetId());
        } else {
            oraclecallablestatement.setNull(9, 2);
        }
        if (atprec.getItemValOrg() != null) {
            oraclecallablestatement.setString(10, atprec.getItemValOrg());
        } else {
            oraclecallablestatement.setNull(10, 12);
        }
        if (atprec.getCategorySetId() != null) {
            oraclecallablestatement.setBigDecimal(11, 
                                                  atprec.getCategorySetId());
        } else {
            oraclecallablestatement.setNull(11, 12);
        }
        if (atprec.getItemPlanningCategory() != null) {
            oraclecallablestatement.setString(12, 
                                              atprec.getItemPlanningCategory());
        } else {
            oraclecallablestatement.setNull(12, 12);
        }
        if (atprec.getOrderType() != null) {
            oraclecallablestatement.setString(13, atprec.getOrderType());
        } else {
            oraclecallablestatement.setNull(13, 12);
        }
        if (atprec.getZoneId() != null) {
            oraclecallablestatement.setBigDecimal(14, atprec.getZoneId());
        } else {
            oraclecallablestatement.setNull(14, 12);
        }
        if (atprec.getCategorySetId() != null) {
            oraclecallablestatement.setBigDecimal(15, 
                                                  atprec.getCategorySetId());
        } else {
            oraclecallablestatement.setNull(15, 12);
        }
        if (atprec.getCategorySetId() != null) {
            oraclecallablestatement.setBigDecimal(16, 
                                                  atprec.getCategorySetId());
        } else {
            oraclecallablestatement.setNull(16, 12);
        }
        if (atprec.getCategorySetId() != null) {
            oraclecallablestatement.setBigDecimal(17, 
                                                  atprec.getCategorySetId());
        } else {
            oraclecallablestatement.setNull(17, 12);
        }
        oraclecallablestatement.registerOutParameter(18, 2);
        oraclecallablestatement.registerOutParameter(19, 2);
        oraclecallablestatement.registerOutParameter(20, 12);
        oraclecallablestatement.registerOutParameter(21, 2);
        oraclecallablestatement.registerOutParameter(22, 12);
        oraclecallablestatement.registerOutParameter(23, 12);
        oraclecallablestatement.registerOutParameter(24, 2);
        return oraclecallablestatement;
    }

    /**
     * @param atprec
     * @param oraclecallablestatement
     * @return
     */
    private ATPRecordType executeStatement(ATPRecordType atprec, 
                                           OracleCallableStatement oraclecallablestatement) {
        try {
            oraclecallablestatement.execute();
            atprec.setBaseOrg(oraclecallablestatement.getString(13));
            atprec.setBaseOrgId(oraclecallablestatement.getBigDecimal(14));
            atprec.setInventoryItemId(oraclecallablestatement.getBigDecimal(15));
            atprec.setOrderFlowType(oraclecallablestatement.getString(16));
            atprec.setAtpTypeCode((String[])oraclecallablestatement.getPlsqlIndexTable(17));
            atprec.setAtpSequence((BigDecimal[])oraclecallablestatement.getPlsqlIndexTable(18));
            atprec.setAssignmentSetId(oraclecallablestatement.getBigDecimal(19));
            atprec.setItemValOrg(oraclecallablestatement.getString(20));
            atprec.setCategorySetId(oraclecallablestatement.getBigDecimal(21));
            atprec.setItemPlanningCategory(oraclecallablestatement.getString(22));
            atprec.setSrcItemFromXdock(oraclecallablestatement.getString(23));
            atprec.setZoneId(oraclecallablestatement.getBigDecimal(24));
            atprec.setForcedSubstitute(oraclecallablestatement.getString(25));
            atprec.setReturnStatus(oraclecallablestatement.getString(26));
            atprec.setErrorMessage(oraclecallablestatement.getString(27));
        } catch (SQLException e) {
            System.out.println(" SQL Exception in Executing Oracle Callable Statement - Pre Process : " + 
                               e.getMessage());
            atprec.setErrorCode(new BigDecimal(21));
            atprec.setErrorMessage("Could not Execute Pre-Process : SQL Exception");
        } catch (NullPointerException e) {
            System.out.println(" Null Pointer Exception in Executing Oracle Callable Statement - Pre Process : " + 
                               e.getMessage());
            atprec.setErrorCode(new BigDecimal(21));
            atprec.setErrorMessage("Could not Execute Pre-Process : Null Pointer Exception");
        } catch (Exception e) {
            System.out.println("Exception in Executing Oracle Callable Statement - Pre Process : " + 
                               e.getMessage());
            atprec.setErrorCode(new BigDecimal(21));
            atprec.setErrorMessage("Could not Execute Pre-Process : Exception");
        } finally {
            if (oraclecallablestatement != null)
                //oraclecallablestatement.close();
                oraclecallablestatement = null;
        }
        return atprec;
    }

    /**
     */
    private void callPreProcess(ATPRecordType atprec) {
        try {
            Connect();
            oraclecallablestatement = getCallableStatement(conn, atprec);
            atprec = executeStatement(atprec, oraclecallablestatement);
            printResults(atprec); // remove this line for deployment - debugging
        } catch (SQLException e) {
            System.out.println(" Pre Process could not be executed.");
            System.out.println(" SQL Exception in Executing Oracle Callable Statement - Pre Process : " + 
                               e.getMessage());
            atprec.setErrorCode(new BigDecimal(21));
            atprec.setErrorMessage("Could not Execute Pre-Process");
        }
    }

    /**
     * @param atprec
     */
    private void printResults(ATPRecordType atprec) {
        System.out.println("----------------------------------------------------------------------------------------------------------------");
        System.out.println("                            Results - Pre Process                                                               ");
        System.out.println("----------------------------------------------------------------------------------------------------------------");
        System.out.println("Base Org : " + atprec.getBaseOrg());
        System.out.println("Order Flow Type : " + atprec.getOrderFlowType());
        System.out.println("Order Flow Sequence : ");
        if (atprec.getAtpTypeCode().length != 0) {
            for (int i = 0; i < atprec.getAtpTypeCode().length; i++) {
                System.out.println("Sequence Code: " + 
                                   atprec.getAtpTypeCode()[i] + 
                                   ", Sequence Number : " + 
                                   atprec.getAtpSequence()[i]);
            }
        }
        System.out.println("Substitute Item : " + 
                           atprec.getForcedSubstitute());
        System.out.println("Return Status : " + atprec.getReturnStatus());
        System.out.println("Error Message : " + atprec.getErrorMessage());
        System.out.println("----------------------------------------------------------------------------------------------------------------");
    }

    public void run() {
        callPreProcess(atprec);
    }
}
