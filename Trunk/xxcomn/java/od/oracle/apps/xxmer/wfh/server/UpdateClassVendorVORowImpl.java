package od.oracle.apps.xxmer.wfh.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class UpdateClassVendorVORowImpl extends OAViewRowImpl 
{
  protected static final int ORGID = 0;


  protected static final int MERCHCLASSID = 1;
  protected static final int VENDORSITEID = 2;
  protected static final int PLANNERID = 3;
  protected static final int MERCHCLASSDESCRIPTION = 4;
  protected static final int VENDORDESCRIPTION = 5;
  protected static final int PLANNERNAME = 6;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public UpdateClassVendorVORowImpl()
  {
  }

  /**
   * 
   * Gets ClassVendorEO entity object.
   */
  public od.oracle.apps.xxmer.schema.wfh.server.ClassVendorEOImpl getClassVendorEO()
  {
    return (od.oracle.apps.xxmer.schema.wfh.server.ClassVendorEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for ORG_ID using the alias name OrgId
   */
  public Number getOrgId()
  {
    return (Number)getAttributeInternal(ORGID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ORG_ID using the alias name OrgId
   */
  public void setOrgId(Number value)
  {
    setAttributeInternal(ORGID, value);
  }

  /**
   * 
   * Gets the attribute value for MERCH_CLASS_ID using the alias name MerchClassId
   */
  public Number getMerchClassId()
  {
    return (Number)getAttributeInternal(MERCHCLASSID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for MERCH_CLASS_ID using the alias name MerchClassId
   */
  public void setMerchClassId(Number value)
  {
    setAttributeInternal(MERCHCLASSID, value);
  }

  /**
   * 
   * Gets the attribute value for VENDOR_SITE_ID using the alias name VendorSiteId
   */
  public Number getVendorSiteId()
  {
    return (Number)getAttributeInternal(VENDORSITEID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for VENDOR_SITE_ID using the alias name VendorSiteId
   */
  public void setVendorSiteId(Number value)
  {
    setAttributeInternal(VENDORSITEID, value);
  }

  /**
   * 
   * Gets the attribute value for PLANNER_ID using the alias name PlannerId
   */
  public Number getPlannerId()
  {
    return (Number)getAttributeInternal(PLANNERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PLANNER_ID using the alias name PlannerId
   */
  public void setPlannerId(Number value)
  {
    setAttributeInternal(PLANNERID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MerchClassDescription
   */
  public String getMerchClassDescription()
  {
    return (String)getAttributeInternal(MERCHCLASSDESCRIPTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MerchClassDescription
   */
  public void setMerchClassDescription(String value)
  {
    setAttributeInternal(MERCHCLASSDESCRIPTION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorDescription
   */
  public String getVendorDescription()
  {
    return (String)getAttributeInternal(VENDORDESCRIPTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorDescription
   */
  public void setVendorDescription(String value)
  {
    setAttributeInternal(VENDORDESCRIPTION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PlannerName
   */
  public String getPlannerName()
  {
    return (String)getAttributeInternal(PLANNERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PlannerName
   */
  public void setPlannerName(String value)
  {
    setAttributeInternal(PLANNERNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ORGID:
        return getOrgId();
      case MERCHCLASSID:
        return getMerchClassId();
      case VENDORSITEID:
        return getVendorSiteId();
      case PLANNERID:
        return getPlannerId();
      case MERCHCLASSDESCRIPTION:
        return getMerchClassDescription();
      case VENDORDESCRIPTION:
        return getVendorDescription();
      case PLANNERNAME:
        return getPlannerName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ORGID:
        setOrgId((Number)value);
        return;
      case MERCHCLASSID:
        setMerchClassId((Number)value);
        return;
      case VENDORSITEID:
        setVendorSiteId((Number)value);
        return;
      case PLANNERID:
        setPlannerId((Number)value);
        return;
      case MERCHCLASSDESCRIPTION:
        setMerchClassDescription((String)value);
        return;
      case VENDORDESCRIPTION:
        setVendorDescription((String)value);
        return;
      case PLANNERNAME:
        setPlannerName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}