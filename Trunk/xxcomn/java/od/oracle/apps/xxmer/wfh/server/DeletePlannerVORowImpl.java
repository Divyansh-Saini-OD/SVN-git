package od.oracle.apps.xxmer.wfh.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class DeletePlannerVORowImpl extends OAViewRowImpl 
{
  protected static final int PLANNERID = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public DeletePlannerVORowImpl()
  {
  }

  /**
   * 
   * Gets PlannerHierarchyEO entity object.
   */
  public od.oracle.apps.xxmer.schema.wfh.server.PlannerHierarchyEOImpl getPlannerHierarchyEO()
  {
    return (od.oracle.apps.xxmer.schema.wfh.server.PlannerHierarchyEOImpl)getEntity(0);
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PLANNERID:
        return getPlannerId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PLANNERID:
        setPlannerId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}