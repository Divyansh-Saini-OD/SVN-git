// Source File Name:   XXCSMPSOrderRequestFailureRptVOImpl.java

package od.oracle.apps.xxcrm.mps.reports.server;

import java.io.PrintStream;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

public class XXCSMPSOrderRequestFailureRptVOImpl extends OAViewObjectImpl {

    public XXCSMPSOrderRequestFailureRptVOImpl()
    {
    }

    public void initOrderReqFailure(String partyId, String serialNo, String fromDeliveryDate, String toDeliveryDate, String managedStatus, String activeStatus)
    {
        StringBuffer whereClause = new StringBuffer();
        setWhereClause(null);
        setWhereClauseParams(null);
        setWhereClauseParam(0,partyId);
        setWhereClauseParam(1,serialNo);
        setWhereClauseParam(2,fromDeliveryDate);
        setWhereClauseParam(3,toDeliveryDate);

        /*
        if(partyId != null && !"".equals(partyId))
        {
            if(whereClause.length() != 0)
                whereClause = whereClause.append(" AND ");
            whereClause = whereClause.append("PARTY_ID = " + partyId);
        }
        if(serialNo != null && !"".equals(serialNo))
        {
            if(whereClause.length() != 0)
                whereClause = whereClause.append(" AND ");
            whereClause = whereClause.append("SERIAL_NO = '" + serialNo + "'");
        }
        System.out.println("##### whereClause=" + whereClause);
        System.out.println("##### Length of whereClause String=" + whereClause.length());
        if(whereClause.length() != 0)
        {
            setWhereClause(whereClause.toString());
            executeQuery();
        } else
        {
            setWhereClause("1=2");
            executeQuery();
        }
        */
         if(managedStatus != null && !"".equals(managedStatus))
         {
             if(whereClause.length() != 0)
                 whereClause = whereClause.append(" AND ");
             whereClause = whereClause.append("MANAGEDSTATUS ='" + managedStatus + "'");
         }
         if(activeStatus != null && !"".equals(activeStatus))
         {
            if(whereClause.length() != 0)
                whereClause = whereClause.append(" AND ");
            whereClause = whereClause.append("ACTIVESTATUS ='" + activeStatus + "'");
         }
         if(whereClause.length() != 0)
         {
          setWhereClause(whereClause.toString());          
         }
        executeQuery();
        System.out.println("##### Query=" + getQuery());
        System.out.println("In VO rowcount=" + getRowCount());
    }
}
