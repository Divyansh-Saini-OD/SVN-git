package od.oracle.apps.xxcrm.mps.reports.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class XXCSMPSTopprinterRptVOImpl extends OAViewObjectImpl {
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XXCSMPSTopprinterRptVOImpl()
  {
  }
 public void initMPSTopPrinterRpt(String customerName, String ProgramType, String managedStatus, String activeStatus)
    {
        StringBuffer whereClause = new StringBuffer();
        setWhereClause(null);
        setWhereClauseParams(null);  
        setWhereClauseParam(0,customerName);
        setWhereClauseParam(1,ProgramType);
        System.out.println("##### Query=" + getQuery());
        if(managedStatus != null && !"".equals(managedStatus))
        {
            if(whereClause.length() != 0)
                whereClause = whereClause.append(" AND ");
            whereClause = whereClause.append(" MANAGED_STATUS ='" + managedStatus + "'");
        }
        if(activeStatus != null && !"".equals(activeStatus))
        {
           if(whereClause.length() != 0)
               whereClause = whereClause.append(" AND ");
           whereClause = whereClause.append(" ACTIVE_STATUS ='" + activeStatus + "'");
        }
        if(whereClause.length() != 0)
        {
         setWhereClause(whereClause.toString());          
        }         
        executeQuery();
        System.out.println("In VO rowcount=" + getRowCount());
    }   
  
}