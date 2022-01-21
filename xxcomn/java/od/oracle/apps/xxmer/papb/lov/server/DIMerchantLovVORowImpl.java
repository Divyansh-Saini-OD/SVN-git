package od.oracle.apps.xxmer.papb.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class DIMerchantLovVORowImpl extends OAViewRowImpl 
{

  protected static final int DIMERCHANTNAME = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public DIMerchantLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DiMerchantName
   */
  public String getDiMerchantName()
  {
    return (String)getAttributeInternal(DIMERCHANTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DiMerchantName
   */
  public void setDiMerchantName(String value)
  {
    setAttributeInternal(DIMERCHANTNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DIMERCHANTNAME:
        return getDiMerchantName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DIMERCHANTNAME:
        setDiMerchantName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}