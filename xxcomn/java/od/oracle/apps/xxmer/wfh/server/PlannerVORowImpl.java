package od.oracle.apps.xxmer.wfh.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class PlannerVORowImpl extends OAViewRowImpl 
{


  protected static final int EMPLOYEEID = 0;
  protected static final int FIRSTNAME = 1;
  protected static final int LASTNAME = 2;
  protected static final int FULLNAME = 3;
  protected static final int SELECTED = 4;
  protected static final int DIRECTREPORTS = 5;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public PlannerVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeId
   */
  public Number getEmployeeId()
  {
    return (Number)getAttributeInternal(EMPLOYEEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeId
   */
  public void setEmployeeId(Number value)
  {
    setAttributeInternal(EMPLOYEEID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FirstName
   */
  public String getFirstName()
  {
    return (String)getAttributeInternal(FIRSTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FirstName
   */
  public void setFirstName(String value)
  {
    setAttributeInternal(FIRSTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LastName
   */
  public String getLastName()
  {
    return (String)getAttributeInternal(LASTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LastName
   */
  public void setLastName(String value)
  {
    setAttributeInternal(LASTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FullName
   */
  public String getFullName()
  {
    return (String)getAttributeInternal(FULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FullName
   */
  public void setFullName(String value)
  {
    setAttributeInternal(FULLNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Selected
   */
  public String getSelected()
  {
    return (String)getAttributeInternal(SELECTED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Selected
   */
  public void setSelected(String value)
  {
    setAttributeInternal(SELECTED, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEEID:
        return getEmployeeId();
      case FIRSTNAME:
        return getFirstName();
      case LASTNAME:
        return getLastName();
      case FULLNAME:
        return getFullName();
      case SELECTED:
        return getSelected();
      case DIRECTREPORTS:
        return getDirectReports();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEEID:
        setEmployeeId((Number)value);
        return;
      case FIRSTNAME:
        setFirstName((String)value);
        return;
      case LASTNAME:
        setLastName((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case SELECTED:
        setSelected((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link DirectReports
   */
  public oracle.jbo.RowIterator getDirectReports()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(DIRECTREPORTS);
  }


}