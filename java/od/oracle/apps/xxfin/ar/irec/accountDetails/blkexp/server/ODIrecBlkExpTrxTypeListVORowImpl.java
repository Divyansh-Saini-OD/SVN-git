package od.oracle.apps.xxfin.ar.irec.accountDetails.blkexp.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;

import oracle.jbo.server.AttributeDefImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class ODIrecBlkExpTrxTypeListVORowImpl extends OAViewRowImpl
{
  public static final int STATUSCODE = 0;
  public static final int DISPLAYEDFIELD = 1;

  /**This is the default constructor (do not remove)
   */
  public ODIrecBlkExpTrxTypeListVORowImpl()
  {
  }

  /**Gets the attribute value for the calculated attribute StatusCode
   */
  public String getStatusCode()
  {
    return (String) getAttributeInternal(STATUSCODE);
  }

  /**Sets <code>value</code> as the attribute value for the calculated attribute StatusCode
   */
  public void setStatusCode(String value)
  {
    setAttributeInternal(STATUSCODE, value);
  }

  /**Gets the attribute value for the calculated attribute DisplayedField
   */
  public String getDisplayedField()
  {
    return (String) getAttributeInternal(DISPLAYEDFIELD);
  }

  /**Sets <code>value</code> as the attribute value for the calculated attribute DisplayedField
   */
  public void setDisplayedField(String value)
  {
    setAttributeInternal(DISPLAYEDFIELD, value);
  }

  /**getAttrInvokeAccessor: generated method. Do not modify.
   */
  protected Object getAttrInvokeAccessor(int index, 
                                         AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
    {
    case STATUSCODE:
      return getStatusCode();
    case DISPLAYEDFIELD:
      return getDisplayedField();
    default:
      return super.getAttrInvokeAccessor(index, attrDef);
    }
  }

  /**setAttrInvokeAccessor: generated method. Do not modify.
   */
  protected void setAttrInvokeAccessor(int index, Object value, 
                                       AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
    {
    default:
      super.setAttrInvokeAccessor(index, value, attrDef);
      return;
    }
  }
}
