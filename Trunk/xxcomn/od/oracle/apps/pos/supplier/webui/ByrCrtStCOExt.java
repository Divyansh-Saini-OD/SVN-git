package od.oracle.apps.pos.supplier.webui;

import java.sql.SQLException;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.pos.supplier.webui.ByrCrtStCO;

import oracle.jdbc.OracleCallableStatement;

public class ByrCrtStCOExt extends ByrCrtStCO {
    public ByrCrtStCOExt() {
    }
    public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)  
    {  
     super.processFormRequest(pageContext, webBean);  
     OAApplicationModule am = pageContext.getApplicationModule(webBean);  
        
        if(pageContext.getParameter("applyBtn") != null)
        {
            OADBTransaction oadbtransaction =
            (OADBTransaction)((OAApplicationModuleImpl)am).getDBTransaction();
            String callSQLPackage = "begin XXOD_CUSTOM_TOL_PKG.UPDATE_TOLERANCE_DATA(:1); commit;" + " end;";
        OracleCallableStatement oraclecallablestatement = (OracleCallableStatement)oadbtransaction.createCallableStatement(callSQLPackage,1);
            try
            {
                 String s = (String)pageContext.getSessionValue("PosVendorId");
                  // Set IN Parameters                
                  
                  oraclecallablestatement.setString(1,s);                                
                              
                  oraclecallablestatement.execute();
              
                       
             }catch(SQLException sqle)
             {
                throw new OAException("Exception Block"+sqle);
             }
        }
    }
}
