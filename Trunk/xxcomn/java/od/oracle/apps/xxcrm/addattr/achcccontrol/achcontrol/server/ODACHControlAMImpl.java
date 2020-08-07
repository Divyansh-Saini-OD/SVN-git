package od.oracle.apps.xxcrm.addattr.achcccontrol.achcontrol.server;

import java.sql.ResultSet;
import java.sql.SQLException;

import od.oracle.apps.xxcrm.addattr.achcccontrol.achcontrol.server.ODACHControlVOImpl;

import oracle.apps.fnd.common.AppsLog;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.domain.Number;

import oracle.jdbc.OracleCallableStatement;
 /*
  --  Copyright (c) 2015, by Office Depot., All Rights Reserved
  --
  -- Author: Sridevi Kondoju
  -- Component Id: E0255 CR1120
  -- Script Location:
             $CUSTOM_JAVA_TOP/od/oracle/apps/xxcrm/addattr/achcccontrol/achcontrol/server
  -- Description: 
  -- Package Usage       : 
  -- Name                  Type         Purpose
  -- --------------------  -----------  ------------------------------------------
   -- Notes:
   -- History:
   -- Name            Date         Version    Description
   -- -----           -----        -------    -----------
   -- Sridevi Kondoju 27-MAR-2015  1.0        Initial version
   -- Sridevi Kondoju 6-May-2015   2.0        ACH_BANK_CONTROL attribute group used
   -- Havish Kasina   16-FEB-2017  3.0        Closing the leaked connection/statement
  */
public class ODACHControlAMImpl extends OAApplicationModuleImpl {
    /**This is the default constructor (do not remove)
     */
    public ODACHControlAMImpl() {
    }

    /**Container's getter for ODACHControlVO1
     */
    public ODACHControlVOImpl getODACHControlVO1() {
        return (ODACHControlVOImpl)findViewObject("ODACHControlVO1");
    }

    /**Sample main for debugging Business Components code using the tester.
     */
    public static void main(String[] args) {
        launchTester("od.oracle.apps.xxcrm.addattr.achcccontrol.achcontrol.server", /* package name */
      "ODACHControlAMLocal" /* Configuration Name */);
    }

    public void commitChanges() {
        this.getOADBTransaction().commit();
    }

    public void rollbackChanges() {
        this.getOADBTransaction().rollback();
    }

    public void initCAVO(String custAcctId) {
        AppsLog myAppsLog = new AppsLog();
       myAppsLog.write("fnd.common.WebAppsContext","XXOD:  ODACHControlAM initCAVO End", 
                                     1);

        ODACHControlVOImpl objVO = this.getODACHControlVO1();
        objVO.setMaxFetchSize(-1);
        objVO.initQuery(custAcctId);
        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext", 
                            "XXOD: after VO Query" + 
                            objVO.getFetchedRowCount() + "************" + 
                            objVO.getRowCount(), 1);
        }

      	if (objVO.getRowCount() == 0) {
            addRow(custAcctId, objVO);
            ODACHControlVORowImpl  objVOrow = (ODACHControlVORowImpl)objVO.first();
            objVOrow.setLastUpdateDateDisp("");
            objVOrow.setInitialCExtAttr1("N");
        } else
        {
            ODACHControlVORowImpl  objVOrow = (ODACHControlVORowImpl)objVO.first();
            java.util.Date ts = objVOrow.getLastUpdateDate().getValue();
            java.text.SimpleDateFormat displayDateFormat = new java.text.SimpleDateFormat("dd-MMM-yyyy hh:mm:ss");
            String convertedDateString = displayDateFormat.format(ts);
            objVOrow.setLastUpdateDateDisp(convertedDateString);
            objVOrow.setInitialCExtAttr1(objVOrow.getCExtAttr1());
             myAppsLog.write("fnd.common.WebAppsContext",
                            "XXOD:objVOrow.getLastUpdateDate() "+objVOrow.getLastUpdateDate()+"*****"+objVOrow.getCExtAttr1(), 1);
        }
        

     myAppsLog.write("fnd.common.WebAppsContext","XXOD:  ODACHControlAM initCAVO End", 
                                     1);


    }


    public void addRow(String CustAccountId, ODACHControlVOImpl objVO) {
        AppsLog myAppsLog = new AppsLog();
        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext", 
                            "XXOD: ODACHControlAMImpl" + "Begin AddRow " + 
                            CustAccountId, 1);
        }

        String lqry = 
            "SELECT attr_group_id " + " FROM   ego_attr_groups_v" + " WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'" + 
            " AND    attr_group_name = 'ACH_BANK_CONTROL'";


        Number attrGrpID = this.execQuery(lqry);
        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext", 
                            "XXOD: ODACHControlAMImpl" + 
                            ":Attribute Group id:" + attrGrpID.toString(), 1);
        }
        objVO.setMaxFetchSize(0);
        OARow mainRow = (OARow)objVO.createRow();

        mainRow.setAttribute("CustAccountId", CustAccountId);
        mainRow.setAttribute("AttrGroupId", attrGrpID);

        objVO.insertRow(mainRow);
        mainRow.setNewRowState(mainRow.STATUS_INITIALIZED);

        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext", 
                            "XXOD: ODACHControlAMImpl" + "End AddRow " + 
                            CustAccountId, 1);
        }
    } //addRow


    /**
     * execQuery to return Number
     * Generic method to execute count(1) query
     * @param pQuery -Query string as parameter
     */
    public

    Number execQuery(String pQuery) {
        AppsLog myAppsLog = new AppsLog();
        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext", 
                            "XXOD: ODACHControlAMImpl" + ":Begin execQuery", 
                            1);
        }
        OracleCallableStatement ocs = null;
        ResultSet rs = null;
        OADBTransaction db = this.getOADBTransaction();
        String stmt = pQuery;
        Object obj = (Object)new String("NODATA");
        Number val = new Number(0);
        //utl.log("execQuery:"+ stmt);
        ocs = (OracleCallableStatement)db.createCallableStatement(stmt, 1);

        try {
            rs = ocs.executeQuery();
            if (rs.next()) {
                val = new Number(rs.getLong(1));
            }
            rs.close();
            ocs.close();
        } catch (SQLException e) {
            if (myAppsLog.isEnabled(1)) {
                myAppsLog.write("fnd.common.WebAppsContext", 
                                "XXOD: ODACHControlAMImpl" + 
                                "execQuery:Error:" + e.toString(), 1);
            }

        }
		finally
        {
           try{
                if(rs != null)
                   rs.close();
                if(ocs != null)
                   ocs.close();
              }
		   catch(Exception e){}
        }
        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext", 
                            "XXOD: ODACHControlAMImpl" + ":End execQuery", 1);
        }
        return val;
    } //execQuery
}
