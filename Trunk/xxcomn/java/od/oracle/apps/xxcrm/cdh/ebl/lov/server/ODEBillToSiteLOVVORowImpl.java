package od.oracle.apps.xxcrm.cdh.ebl.lov.server;
/* Subversion Info:
 * $HeadURL: http://svn.na.odcorp.net/svn/od/common/trunk/xxcomn/java/od/oracle/apps/xxcrm/cdh/ebl/lov/server/ODEBillToSiteLOVVORowImpl.java $
 * $Rev: 98363 $
 * $Date: 2010-04-08 01:52:49 -0400 (Thu, 08 Apr 2010) $
*/
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODEBillToSiteLOVVORowImpl extends OAViewRowImpl 
{
  protected static final int ORIGSYSTEMREFERENCE = 0;


  protected static final int CUSTACCOUNTID = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODEBillToSiteLOVVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OrigSystemReference
   */
  public String getOrigSystemReference()
  {
    return (String)getAttributeInternal(ORIGSYSTEMREFERENCE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OrigSystemReference
   */
  public void setOrigSystemReference(String value)
  {
    setAttributeInternal(ORIGSYSTEMREFERENCE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustAccountId
   */
  public Number getCustAccountId()
  {
    return (Number)getAttributeInternal(CUSTACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustAccountId
   */
  public void setCustAccountId(Number value)
  {
    setAttributeInternal(CUSTACCOUNTID, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ORIGSYSTEMREFERENCE:
        return getOrigSystemReference();
      case CUSTACCOUNTID:
        return getCustAccountId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ORIGSYSTEMREFERENCE:
        setOrigSystemReference((String)value);
        return;
      case CUSTACCOUNTID:
        setCustAccountId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}