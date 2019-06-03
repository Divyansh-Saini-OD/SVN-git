package od.oracle.apps.xxmer.schema.wfh.server;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.AttributeList;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class PlannerHierarchyEOImpl extends OAEntityImpl 
{
  protected static final int PLANNERID = 0;
  protected static final int MANAGERID = 1;
  protected static final int ORGID = 2;
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
  public PlannerHierarchyEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxmer.schema.wfh.server.PlannerHierarchyEO");
    }
    return mDefinitionObject;
  }


  public static PlannerHierarchyEntityExpert getPlannerHierarchyEntityExpert(OADBTransaction txn) 
  {
    return (PlannerHierarchyEntityExpert)txn.getExpert(PlannerHierarchyEOImpl.getDefinitionObject());
  }

  /**
   * 
   * Add attribute defaulting logic in this method.
   */
  public void create(AttributeList attributeList)
  {
    super.create(attributeList);
  }

  /**
   * 
   * Add entity remove logic in this method.
   */
  public void remove()
  {
    // One validation rule applies here
    // 1) This PlannerId must be a leaf node in the PlannerHeirarchy table.
    //    Rule: must delete all children before parent.
    PlannerHierarchyEntityExpert expert = getPlannerHierarchyEntityExpert(getOADBTransaction());
    Number plannerId = getPlannerId();
    if (!expert.isLeafPlanner(plannerId)) 
    {
      throw new OAAttrValException(OAException.TYP_ENTITY_OBJECT,
                                 getEntityDef().getFullName(), // EO name
                                 getPrimaryKey(), // EO PK
                                 "PlannerId", // Attribute Name
                                 plannerId, // Attribute value
                                 "XXMER", // Message product short name
                                 "WFH_PLANNERID_NOT_LEAF");
    }
    super.remove();
  }

  /**
   * 
   * Add Entity validation code in this method.
   */
  protected void validateEntity()
  {
    super.validateEntity();
  }

  /**
   * 
   * Gets the attribute value for PlannerId, using the alias name PlannerId
   */
  public Number getPlannerId()
  {
    return (Number)getAttributeInternal(PLANNERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PlannerId
   */
  public void setPlannerId(Number value)
  {
    // Two validation rules apply here
    // 1) PlannerId must be unique in PlannerHeirarchy table (PK constraint).
    // 2) PlannerId must be a valid apps user (FK constraint).
    if (value != null) 
    {
      PlannerHierarchyEntityExpert expert = getPlannerHierarchyEntityExpert(getOADBTransaction());
      if (expert.isPlannerInHierarchy(value)) 
      {
        throw new OAAttrValException(OAException.TYP_ENTITY_OBJECT,
                                   getEntityDef().getFullName(), // EO name
                                   getPrimaryKey(), // EO PK
                                   "PlannerId", // Attribute Name
                                   value, // Attribute value
                                   "XXMER", // Message product short name
                                   "WFH_PLANNERID_ALREADY_EXISTS");
      }
      if (!expert.isPlannerIdValid(value)) 
      {
        throw new OAAttrValException(OAException.TYP_ENTITY_OBJECT,
                                   getEntityDef().getFullName(), // EO name
                                   getPrimaryKey(), // EO PK
                                   "PlannerId", // Attribute Name
                                   value, // Attribute value
                                   "XXMER", // Message product short name
                                   "WFH_PLANNERID_INVALID");
      }
    }
    setAttributeInternal(PLANNERID, value);
  }

  /**
   * 
   * Gets the attribute value for ManagerId, using the alias name ManagerId
   */
  public Number getManagerId()
  {
    return (Number)getAttributeInternal(MANAGERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ManagerId
   */
  public void setManagerId(Number value)
  {
    // One validation rule applies here
    // 1) ManagerId must be exist as a planner in the PlannerHeirarchy table.
    //    Rule: parents must exist before children.
    if (value != null) 
    {
      PlannerHierarchyEntityExpert expert = getPlannerHierarchyEntityExpert(getOADBTransaction());
      if (!expert.isManagerInHierarchy(value)) 
      {
        throw new OAAttrValException(OAException.TYP_ENTITY_OBJECT,
                                   getEntityDef().getFullName(), // EO name
                                   getPrimaryKey(), // EO PK
                                   "ManagerId", // Attribute Name
                                   value, // Attribute value
                                   "XXMER", // Message product short name
                                   "WFH_MANAGERID_INVALID");
      }
    }
    setAttributeInternal(MANAGERID, value);
  }

  /**
   * 
   * Gets the attribute value for OrgId, using the alias name OrgId
   */
  public Number getOrgId()
  {
    return (Number)getAttributeInternal(ORGID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for OrgId
   */
  public void setOrgId(Number value)
  {
    setAttributeInternal(ORGID, value);
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PLANNERID:
        return getPlannerId();
      case MANAGERID:
        return getManagerId();
      case ORGID:
        return getOrgId();
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
      case PLANNERID:
        setPlannerId((Number)value);
        return;
      case MANAGERID:
        setManagerId((Number)value);
        return;
      case ORGID:
        setOrgId((Number)value);
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
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number plannerId)
  {
    return new Key(new Object[] {plannerId});
  }


}