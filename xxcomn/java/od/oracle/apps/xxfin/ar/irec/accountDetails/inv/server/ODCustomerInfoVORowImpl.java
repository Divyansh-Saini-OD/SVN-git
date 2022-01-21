package od.oracle.apps.xxfin.ar.irec.accountDetails.inv.server;
import oracle.apps.ar.irec.accountDetails.inv.server.CustomerInfoVORowImpl;

public class ODCustomerInfoVORowImpl extends CustomerInfoVORowImpl 
{

  protected static final int MAXATTRCONST = oracle.jbo.server.ViewDefImpl.getMaxAttrConst("oracle.apps.ar.irec.accountDetails.inv.server.CustomerInfoVO");
  protected static final int ORIGSYSTEMREFERENCE = MAXATTRCONST;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODCustomerInfoVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Origsystemreference
   */
  public String getOrigsystemreference()
  {
    return (String)getAttributeInternal(ORIGSYSTEMREFERENCE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Origsystemreference
   */
  public void setOrigsystemreference(String value)
  {
    setAttributeInternal(ORIGSYSTEMREFERENCE, value);
  }
}