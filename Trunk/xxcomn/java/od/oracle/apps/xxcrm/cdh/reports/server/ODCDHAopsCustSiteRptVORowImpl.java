package od.oracle.apps.xxcrm.cdh.reports.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODCDHAopsCustSiteRptVORowImpl extends OAViewRowImpl 
{


  protected static final int ACCOUNTNUMBER = 0;
  protected static final int ACCOUNTNAME = 1;
  protected static final int ADDRESS = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODCDHAopsCustSiteRptVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountName
   */
  public String getAccountName()
  {
    return (String)getAttributeInternal(ACCOUNTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountName
   */
  public void setAccountName(String value)
  {
    setAttributeInternal(ACCOUNTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address
   */
  public String getAddress()
  {
    return (String)getAttributeInternal(ADDRESS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address
   */
  public void setAddress(String value)
  {
    setAttributeInternal(ADDRESS, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case ACCOUNTNAME:
        return getAccountName();
      case ADDRESS:
        return getAddress();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case ACCOUNTNAME:
        setAccountName((String)value);
        return;
      case ADDRESS:
        setAddress((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}