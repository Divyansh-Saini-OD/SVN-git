package od.oracle.apps.xxcrm.poplist.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODOwnerTypePoplistVORowImpl extends OAViewRowImpl 
{


  protected static final int OWNERTYPECODE = 0;
  protected static final int OWNERTYPENAME = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODOwnerTypePoplistVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OwnerTypeCode
   */
  public String getOwnerTypeCode()
  {
    return (String)getAttributeInternal(OWNERTYPECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OwnerTypeCode
   */
  public void setOwnerTypeCode(String value)
  {
    setAttributeInternal(OWNERTYPECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OwnerTypeName
   */
  public String getOwnerTypeName()
  {
    return (String)getAttributeInternal(OWNERTYPENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OwnerTypeName
   */
  public void setOwnerTypeName(String value)
  {
    setAttributeInternal(OWNERTYPENAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case OWNERTYPECODE:
        return getOwnerTypeCode();
      case OWNERTYPENAME:
        return getOwnerTypeName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case OWNERTYPECODE:
        setOwnerTypeCode((String)value);
        return;
      case OWNERTYPENAME:
        setOwnerTypeName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}