package od.oracle.apps.xxfin.ar.irec.homepage.server;

import oracle.apps.ar.irec.homepage.server.PageVOImpl;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;

public class ODPageVOImpl extends PageVOImpl
{

    public ODPageVOImpl()
    {
    }
    public void initQuery(String strCurrencyCode, String strCustomerId, String strSessionId, String strActiveSiteUseId)
    {
        //s = currencyCode
        //strCustomerId =  customerId
        //s2 = sessionId
        this.writeDiagnostics(this, "ODPageVOImpl.initQuery() strCurrencyCode="+ strCurrencyCode + ", strCustomerId=" + strCustomerId + ", strSessionId=" + strSessionId + ", strActiveSiteUseId=", 1); 
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

    public void initQuery(String s, String s1, String s2)
    {
        //s = currencyCode
        //s1 =  customerId
        //s2 = sessionId
        this.writeDiagnostics(this, "ODPageVOImpl.initQuery() s="+ s + ", s1=" + s1 + ", s2=" + s2, 1); 
        OADBTransactionImpl trx = (OADBTransactionImpl)((OAApplicationModuleImpl)getApplicationModule()).getOADBTransaction();
        String strUserId = trx.getUserId()+"";
        setWhereClauseParams(null);
        setWhereClause(null);
        setWhereClauseParam(0, strUserId);
        setWhereClauseParam(1, s1);
        setWhereClauseParam(2, s2);
        setWhereClauseParam(3, s);
        setWhereClauseParam(4, strUserId);
        setWhereClauseParam(5, s1);
        setWhereClauseParam(6, s2);
        setWhereClauseParam(7, s);
        setWhereClauseParam(8, strUserId);
        setWhereClauseParam(9, s1);
        setWhereClauseParam(10, s2);
        setWhereClauseParam(11, s);
        setWhereClauseParam(12, strUserId);
        setWhereClauseParam(13, s1);
        setWhereClauseParam(14, s2);
        setWhereClauseParam(15, s);
        setWhereClauseParam(16, s1);
        setWhereClauseParam(17, null);
        setWhereClauseParam(18, s2);
        setWhereClauseParam(19, s);
        setWhereClauseParam(20, strUserId);
        setWhereClauseParam(21, s1);
        setWhereClauseParam(22, s2);
        setWhereClauseParam(23, s);
        setWhereClauseParam(24, s);
        setWhereClauseParam(25, s1);
        executeQuery();
    }
	
}

