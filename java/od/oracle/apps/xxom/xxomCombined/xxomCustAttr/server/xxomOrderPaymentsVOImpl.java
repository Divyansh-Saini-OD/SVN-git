package od.oracle.apps.xxom.xxomCombined.xxomCustAttr.server;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class xxomOrderPaymentsVOImpl extends OAViewObjectImpl
{
  /**This is the default constructor (do not remove)
   */
  public xxomOrderPaymentsVOImpl()
  {
  }
  
  public void initQuery(String HeaderId)
  {
     if ((HeaderId != null) && 
         (!("".equals(HeaderId.trim()))))
     {

       // Do the following conversion for type consistency.
       Number OrdNum = null;
   
       try
       {
         OrdNum = new Number(HeaderId);
       } 
       catch(Exception e) 
       {
         throw new OAException("ONT", "FWK_TBX_INVALID_EMP_NUMBER");
       }
       setWhereClause("HEADER_ID = :1");
       setWhereClauseParams(null); // Always reset
       setWhereClauseParam(0, OrdNum);
       executeQuery();
   
     }
   } // end initQuery()
}
