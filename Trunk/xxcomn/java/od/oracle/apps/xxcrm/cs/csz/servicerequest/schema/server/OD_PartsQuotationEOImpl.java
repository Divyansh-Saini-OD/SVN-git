package od.oracle.apps.xxcrm.cs.csz.servicerequest.schema.server;
import oracle.apps.fnd.framework.server.OAEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.AttributeList;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.RowID;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class OD_PartsQuotationEOImpl extends OAEntityImpl 
{
  protected static final int REQUESTNUMBER = 0;
  protected static final int STORENUMBER = 1;
  protected static final int CREATIONDATE = 2;
  protected static final int CREATEDBY = 3;
  protected static final int ROWID = 4;


  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public OD_PartsQuotationEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxcrm.cs.csz.servicerequest.schema.server.OD_PartsQuotationEO");
    }
    return mDefinitionObject;
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
    super.remove();
  }



  public void setLastUpdateLogin(oracle.jbo.domain.Number n)
  {

  }
  public void setLastUpdatedBy(String n)
  {

  }

  public void setLastUpdateDate(oracle.jbo.domain.Date n)
  {

  }  
 

  public void setCreatedBy(oracle.jbo.domain.Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }
  public void setLastUpdatedBy(oracle.jbo.domain.Number value)
  {
//    setAttributeInternal(LASTUPDATEDBY, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case REQUESTNUMBER:
        return getRequestNumber();
      case STORENUMBER:
        return getStoreNumber();
      case CREATIONDATE:
        return getCreationDate();
      case CREATEDBY:
        return getCreatedBy();
      case ROWID:
        return getRowID();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case REQUESTNUMBER:
        setRequestNumber((String)value);
        return;
      case STORENUMBER:
        setStoreNumber((String)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case CREATEDBY:
        setCreatedBy((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for RequestNumber, using the alias name RequestNumber
   */
  public String getRequestNumber()
  {
    return (String)getAttributeInternal(REQUESTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for RequestNumber
   */
  public void setRequestNumber(String value)
  {
    setAttributeInternal(REQUESTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for StoreNumber, using the alias name StoreNumber
   */
  public String getStoreNumber()
  {
    return (String)getAttributeInternal(STORENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for StoreNumber
   */
  public void setStoreNumber(String value)
  {
    setAttributeInternal(STORENUMBER, value);
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
  public String getCreatedBy()
  {
    return (String)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreatedBy
   */
  public void setCreatedBy(String value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for RowID, using the alias name RowID
   */
  public RowID getRowID()
  {
    return (RowID)getAttributeInternal(ROWID);
  }
}