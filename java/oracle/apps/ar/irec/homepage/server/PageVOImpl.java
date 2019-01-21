package oracle.apps.ar.irec.homepage.server;

/*===========================================================================+
 |      Copyright (c) 2000, 2014 Oracle Corporation, Redwood Shores, CA, USA |
 |                         All rights reserved.                              |
 +===========================================================================+
 |																			 |
 | Component Id: Stabilization project - Large Indirect customers(Defec#42651)|
 | Script Location: $XXCOMN_TOP/oracle/apps/ar/irec/homepage/server			 |
 |																			 |
 |  HISTORY                                                                  |
 | Date       Name       	  Version    Description						 |
 | -------    -----      	  -------    -----------						 |
 | 31-JUL-17  Sreedhar Mohan  1.0       Defec#42651 - Considered 12.2.5(120.4.12020000.2) code |
 |                                      version and added custom code        |
 +===========================================================================*/

import oracle.apps.ar.irec.framework.IROAViewObjectImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

public class PageVOImpl extends IROAViewObjectImpl
{

    public PageVOImpl()
    {
    }
	
	// Defect#42651 - At runtime, ODPageVOImpl is used, as substituted. To compile PageAMImpl successfully, where the initQuery
	// method with 4 parameters is invoked, modified this file.
    public void initQuery(String strCurrencyCode, String strCustomerId, String strSessionId, String strActiveSiteUseId)
    {
        //s = currencyCode
        //strCustomerId =  customerId
        //s2 = sessionId
			this.writeDiagnostics(this, "Custmized PageVOImpl.initQuery() strCurrencyCode="+ strCurrencyCode + ", strCustomerId=" + strCustomerId + ", strSessionId=" + strSessionId + ", strActiveSiteUseId=", 1);         
        OADBTransactionImpl trx = (OADBTransactionImpl)((OAApplicationModuleImpl)getApplicationModule()).getOADBTransaction();
        String strUserId = trx.getUserId()+"";
        setWhereClauseParams(null);
        setWhereClause(null);
        setWhereClauseParam(0, strUserId);
        setWhereClauseParam(1, strSessionId);
        setWhereClauseParam(2, strCurrencyCode);
        setWhereClauseParam(3, strUserId);
        setWhereClauseParam(4, strSessionId);
        setWhereClauseParam(5, strCurrencyCode);
        setWhereClauseParam(6, strUserId);
        setWhereClauseParam(7, strSessionId);
        setWhereClauseParam(8, strCurrencyCode);
        setWhereClauseParam(9, strUserId);
        setWhereClauseParam(10, strSessionId);
        setWhereClauseParam(11, strCurrencyCode);
        
        setWhereClauseParam(12, strCustomerId);
        setWhereClauseParam(13, strActiveSiteUseId);
        setWhereClauseParam(14, strSessionId);
        setWhereClauseParam(15, strCurrencyCode);
        
        setWhereClauseParam(16, strUserId);
        setWhereClauseParam(17, strSessionId);
        setWhereClauseParam(18, strCurrencyCode);

        setWhereClauseParam(19, strCurrencyCode);
        setWhereClauseParam(20, strCustomerId);
        executeQuery();
    }
    /*
    public void initQuery(String s, String s1, String s2)
    {
        setWhereClauseParams(null);
        setWhereClause(null);
        setWhereClauseParam(0, s1);
        setWhereClauseParam(1, s1);
        setWhereClauseParam(2, s2);
        setWhereClauseParam(3, s);
        setWhereClauseParam(4, s1);
        setWhereClauseParam(5, s1);
        setWhereClauseParam(6, s2);
        setWhereClauseParam(7, s);
        setWhereClauseParam(8, s1);
        setWhereClauseParam(9, s1);
        setWhereClauseParam(10, s2);
        setWhereClauseParam(11, s);
        setWhereClauseParam(12, s1);
        setWhereClauseParam(13, s1);
        setWhereClauseParam(14, s2);
        setWhereClauseParam(15, s);
        setWhereClauseParam(16, s1);
        setWhereClauseParam(17, null);
        setWhereClauseParam(18, s2);
        setWhereClauseParam(19, s);
        setWhereClauseParam(20, s1);
        setWhereClauseParam(21, s1);
        setWhereClauseParam(22, s2);
        setWhereClauseParam(23, s);
        setWhereClauseParam(24, s);
        setWhereClauseParam(25, s1);
        executeQuery();
    }
    */
    public static final String RCS_ID = "$Header: PageVOImpl.java 120.4.12020000.2 2012/07/22 02:44:11 rsinthre ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: PageVOImpl.java 120.4.12020000.2 2012/07/22 02:44:11 rsinthre ship $", "oracle.apps.ar.irec.accountDetails.homepage.server");

}
