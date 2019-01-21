package od.oracle.apps.xxcrm.addattr.achcccontrol.creditauth.server;

import java.sql.ResultSet;

import java.sql.SQLException;

import oracle.apps.fnd.common.AppsLog;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.OARow;

import oracle.jbo.domain.Number;


import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jdbc.OracleCallableStatement;
 /*
  --  Copyright (c) 2015, by Office Depot., All Rights Reserved
  --
  -- Author: Sridevi Kondoju
  -- Component Id: E0255 CR1120
  -- Script Location:
             $CUSTOM_JAVA_TOP/od/oracle/apps/xxcrm/addattr/achcccontrol/creditauth/server
  -- Description: 
  -- Package Usage       : 
  -- Name                  Type         Purpose
  -- --------------------  -----------  ------------------------------------------
   -- Notes:
   -- History:
   -- Name            Date         Version    Description
   -- -----           -----        -------    -----------
   -- Sridevi Kondoju 27-MAR-2015  1.0        Initial version
   -- Sridevi Kondoju 21-MAY-2015  1.1        Modified for Defect#1312
   -- Havish Kasina   16-FEB-2017  1.2        Closing the leaked connection/statement
   --
  */
public class ODCreditAuthAMImpl extends OAApplicationModuleImpl {
    /**This is the default constructor (do not remove)
     */
    public ODCreditAuthAMImpl() {
    }

    /**Container's getter for ODCreditAuthVO1
     */
    public ODCreditAuthVOImpl getODCreditAuthVO1() {
        return (ODCreditAuthVOImpl)findViewObject("ODCreditAuthVO1");
    }

    /**Sample main for debugging Business Components code using the tester.
     */
    public static void main(String[] args) { /* package name */
        /* Configuration Name */launchTester("od.oracle.apps.xxcrm.addattr.achcccontrol.creditauth.server",
                                             "ODCreditAuthAMLocal");
    }

    public void commitChanges() {
        this.getOADBTransaction().commit();
    }

    public void rollbackChanges() {
        this.getOADBTransaction().rollback();
    }

    public void initCAVO(String custAcctId) {
        AppsLog myAppsLog = new AppsLog();


        myAppsLog.write("fnd.common.WebAppsContext","XXOD: initCAVO Start", 
                                     1);

        ODCreditAuthVOImpl objVO = this.getODCreditAuthVO1();
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
            ODCreditAuthVORowImpl  objVOrow = (ODCreditAuthVORowImpl)objVO.first();
            objVOrow.setLastUpdateDateDisp("");
            objVOrow.setInitialCExtAttr1("N");
        } else
        {
            ODCreditAuthVORowImpl  objVOrow = (ODCreditAuthVORowImpl)objVO.first();
            java.util.Date ts = objVOrow.getLastUpdateDate().getValue();
            java.text.SimpleDateFormat displayDateFormat = new java.text.SimpleDateFormat("dd-MMM-yyyy hh:mm:ss");
            String convertedDateString = displayDateFormat.format(ts);
            objVOrow.setLastUpdateDateDisp(convertedDateString);
            objVOrow.setInitialCExtAttr1(objVOrow.getCExtAttr1());
             myAppsLog.write("fnd.common.WebAppsContext",
                            "XXOD:objVOrow.getLastUpdateDate() "+objVOrow.getLastUpdateDate()+"*****"+objVOrow.getCExtAttr1(), 1);
        }
        

    myAppsLog.write("fnd.common.WebAppsContext","XXOD: initCAVO End", 
                                     1);


    }


    public void addRow(String CustAccountId, ODCreditAuthVOImpl objVO) {
        AppsLog myAppsLog = new AppsLog();
        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext",
                            "XXOD: ODCreditAuthAMImpl" + "Begin AddRow " +
                            CustAccountId, 1);
        }

        String lqry =
            "SELECT attr_group_id " + " FROM   ego_attr_groups_v" + " WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'" +
            " AND    attr_group_name = 'CREDIT_AUTH_GROUP'";


        Number attrGrpID = this.execQuery(lqry);
        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext",
                            "XXOD: ODCreditAuthAMImpl" +
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
                            "XXOD: ODCreditAuthAMImpl" + "End AddRow " +
                            CustAccountId, 1);
        }
    } //addRow



    public     Number execQuery(String pQuery) {
        AppsLog myAppsLog = new AppsLog();
        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext",
                            "XXOD: ODCreditAuthAMImpl" + ":Begin execQuery",
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
                                "XXOD: ODCreditAuthAMImpl" +
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
                            "XXOD: ODCreditAuthAMImpl" + ":End execQuery", 1);
        }
        return val;
    } //execQuery

}
