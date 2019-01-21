package od.oracle.apps.xxcrm.hz.account.customer.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODSiteUsageVORowImpl extends OAViewRowImpl 
{


  protected static final int SITEUSECODE = 0;
  protected static final int SITEUSE = 1;
  protected static final int PRIMARYFLAG = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODSiteUsageVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SiteUseCode
   */
  public String getSiteUseCode()
  {
    return (String)getAttributeInternal(SITEUSECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SiteUseCode
   */
  public void setSiteUseCode(String value)
  {
    setAttributeInternal(SITEUSECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SiteUse
   */
  public String getSiteUse()
  {
    return (String)getAttributeInternal(SITEUSE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SiteUse
   */
  public void setSiteUse(String value)
  {
    setAttributeInternal(SITEUSE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PrimaryFlag
   */
  public String getPrimaryFlag()
  {
    return (String)getAttributeInternal(PRIMARYFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PrimaryFlag
   */
  public void setPrimaryFlag(String value)
  {
    setAttributeInternal(PRIMARYFLAG, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SITEUSECODE:
        return getSiteUseCode();
      case SITEUSE:
        return getSiteUse();
      case PRIMARYFLAG:
        return getPrimaryFlag();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SITEUSECODE:
        setSiteUseCode((String)value);
        return;
      case SITEUSE:
        setSiteUse((String)value);
        return;
      case PRIMARYFLAG:
        setPrimaryFlag((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}