package od.oracle.apps.xxmer.papb.server;
import oracle.apps.fnd.framework.server.OAEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.RowID;
import oracle.jbo.domain.Date;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class FndUserEOImpl extends OAEntityImpl 
{
  protected static final int USERID = 0;
  protected static final int EMPLOYEEID = 1;
  protected static final int ROWID = 2;
  protected static final int LASTUPDATEDATE = 3;
  protected static final int LASTUPDATEDBY = 4;
  protected static final int CREATIONDATE = 5;
  protected static final int CREATEDBY = 6;
  protected static final int LASTUPDATELOGIN = 7;


  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public FndUserEOImpl()
  {
  }

  /**
   * 
   * Retrieves the definition object for this instance class.
   */
  public static synchronized EntityDefImpl getDefinitionObject()
  {
    if (mDefinitionObject == null)
    {
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxmer.papb.server.FndUserEO");
    }
    return mDefinitionObject;
  }



  /**
   * 
   * Gets the attribute value for UserId, using the alias name UserId
   */
  public Number getUserId()
  {
    return (Number)getAttributeInternal(USERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for UserId
   */
  public void setUserId(Number value)
  {
    setAttributeInternal(USERID, value);
  }

  /**
   * 
   * Gets the attribute value for EmployeeId, using the alias name EmployeeId
   */
  public Number getEmployeeId()
  {
    return (Number)getAttributeInternal(EMPLOYEEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for EmployeeId
   */
  public void setEmployeeId(Number value)
  {
    setAttributeInternal(EMPLOYEEID, value);
  }

  /**
   * 
   * Gets the attribute value for RowID, using the alias name RowID
   */
  public RowID getRowID()
  {
    return (RowID)getAttributeInternal(ROWID);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case USERID:
        return getUserId();
      case EMPLOYEEID:
        return getEmployeeId();
      case ROWID:
        return getRowID();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case CREATIONDATE:
        return getCreationDate();
      case CREATEDBY:
        return getCreatedBy();
      case LASTUPDATELOGIN:
        return getLastUpdateLogin();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case USERID:
        setUserId((Number)value);
        return;
      case EMPLOYEEID:
        setEmployeeId((Number)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((Number)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case CREATEDBY:
        setCreatedBy((Number)value);
        return;
      case LASTUPDATELOGIN:
        setLastUpdateLogin((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for LastUpdateDate, using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdatedBy, using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CreationDate, using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for CreatedBy, using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateLogin, using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }
}