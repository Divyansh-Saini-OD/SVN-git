package od.oracle.apps.xxcrm.scs.fdk.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODSCSFdbkRespVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODSCSFdbkRespVOImpl()
  {
  }
        public void initQuery(java.lang.String s)
    {
        oracle.apps.fnd.framework.server.OADBTransaction oadbtransaction = (oracle.apps.fnd.framework.server.OADBTransaction)getDBTransaction();
        setWhereClauseParams(null);
        if(s != null && !"".equals(s.trim()))
        {
          //  oracle.apps.fnd.common.MessageToken amessagetoken[] = {
          //      new MessageToken("IDNAME", s)
           // };
//            oracle.jbo.domain.Number number = oracle.apps.asn.common.schema.server.ASNUtil.stringToJboNumber(s, "ASN_CMMN_STR_TO_JBONUM_ERR", amessagetoken);
                   setWhereClauseParam(0, s);
            executeQuery();
        }}
}