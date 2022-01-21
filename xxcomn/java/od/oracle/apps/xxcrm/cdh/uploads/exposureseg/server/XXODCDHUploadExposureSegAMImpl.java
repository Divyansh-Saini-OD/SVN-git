package od.oracle.apps.xxcrm.cdh.uploads.exposureseg.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import java.sql.CallableStatement;
import java.sql.SQLException;
import oracle.jdbc.OracleTypes;
import oracle.jbo.server.ApplicationModuleImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class XXODCDHUploadExposureSegAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XXODCDHUploadExposureSegAMImpl()
  {
  }

  public String runConcReqSet( String strUserId, 
                               String strRespId,
                               String strRespApplId, 
                               String strFileName)
  {
    String strReqId = "";
    CallableStatement cs1 = null;
    CallableStatement cs2 = null;
    try{
        cs1 = getOADBTransaction().getJdbcConnection().prepareCall("{call fnd_global.apps_initialize(?,?,?)}");

        cs1.setInt(1, Integer.parseInt(strUserId));
        cs1.setInt(2, Integer.parseInt(strRespId));
        cs1.setInt(3, Integer.parseInt(strRespApplId));

        cs1.execute();
    
        cs1.close();
    } catch (SQLException e)
    {
      strReqId = e.toString();
      e.printStackTrace();
      try{
          cs1.close();
      }catch (SQLException se){}
    }
    try{
        cs2 = getOADBTransaction().getJdbcConnection().prepareCall("{call XXOD_CDH_UPLOAD_EXPSEG_PKG.upload(?,?,?,?)}");

        cs2.registerOutParameter(1, OracleTypes.VARCHAR);
        cs2.registerOutParameter(2, OracleTypes.VARCHAR);
        cs2.registerOutParameter(3, OracleTypes.NUMBER);
        cs2.setString(4, strFileName);

        cs2.execute();
        Object obj = null;
        obj = cs2.getObject(3);
        if( obj != null) 
          strReqId = obj.toString();
        else
          strReqId = "Error in submitting request set";
        cs2.close();
    } catch (SQLException e)
    {
      strReqId = e.toString();
      e.printStackTrace();
      try{
          cs2.close();
      }catch (SQLException se1){}
    }

    return strReqId;
  }
  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxcrm.cdh.uploads.exposureseg.server", "XXODCDHUploadExposureSegAMLocal");
  }
}
