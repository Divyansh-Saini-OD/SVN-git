package od.oracle.apps.xxmer.schema.server;
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

public class HoldBackQtyEOImpl extends OAEntityImpl 
{
  protected static final int ITEM = 0;
  protected static final int WAREHOUSELOCATION = 1;
  protected static final int HOLDQUANTITY = 2;
  protected static final int QUANTITYONHAND = 3;
  protected static final int STARTDATE = 4;
  protected static final int ENDDATE = 5;
  protected static final int ITEMTYPE = 6;
  protected static final int LASTUPDATEDATE = 7;
  protected static final int LASTUPDATEDBY = 8;
  protected static final int CREATIONDATE = 9;
  protected static final int CREATEDBY = 10;
  protected static final int LASTUPDATELOGIN = 11;















  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public HoldBackQtyEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxmer.schema.server.HoldBackQtyEO");
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
   * Gets the attribute value for Item, using the alias name Item
   */
  public String getItem()
  {
    return (String)getAttributeInternal(ITEM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Item
   */
  public void setItem(String value)
  {
    setAttributeInternal(ITEM, value);
  }

  /**
   * 
   * Gets the attribute value for WarehouseLocation, using the alias name WarehouseLocation
   */
  public String getWarehouseLocation()
  {
    return (String)getAttributeInternal(WarehouseLocation);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for WarehouseLocation
   */
  public void setWarehouseLocation(String value)
  {
    setAttributeInternal(WarehouseLocation, value);
  }

  /**
   * 
   * Gets the attribute value for HoldQuantity, using the alias name HoldQuantity
   */
  public Number getHoldQuantity()
  {
    return (Number)getAttributeInternal(HOLDQUANTITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for HoldQuantity
   */
  public void setHoldQuantity(Number value)
  {
    setAttributeInternal(HOLDQUANTITY, value);
  }

  /**
   * 
   * Gets the attribute value for QuantityOnHand, using the alias name QuantityOnHand
   */
  public Number getQuantityOnHand()
  {
    return (Number)getAttributeInternal(QUANTITYONHAND);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuantityOnHand
   */
  public void setQuantityOnHand(Number value)
  {
    setAttributeInternal(QUANTITYONHAND, value);
  }

  /**
   * 
   * Gets the attribute value for StartDate, using the alias name StartDate
   */
  public Date getStartDate()
  {
    return (Date)getAttributeInternal(STARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for StartDate
   */
  public void setStartDate(Date value)
  {
    setAttributeInternal(STARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for EndDate, using the alias name EndDate
   */
  public Date getEndDate()
  {
    return (Date)getAttributeInternal(ENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for EndDate
   */
  public void setEndDate(Date value)
  {
    setAttributeInternal(ENDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for ItemType, using the alias name ItemType
   */
  public String getItemType()
  {
    return (String)getAttributeInternal(ITEMTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ItemType
   */
  public void setItemType(String value)
  {
    setAttributeInternal(ITEMTYPE, value);
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
      case ITEM:
        return getItem();
      case WarehouseLocation:
        return getWarehouseLocation();
      case HOLDQUANTITY:
        return getHoldQuantity();
      case QUANTITYONHAND:
        return getQuantityOnHand();
      case STARTDATE:
        return getStartDate();
      case ENDDATE:
        return getEndDate();
      case ITEMTYPE:
        return getItemType();
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
      case ITEM:
        setItem((String)value);
        return;
      case WAREHOUSELOCATION:
        setWarehouseLocation((String)value);
        return;
      case HOLDQUANTITY:
        setHoldQuantity((Number)value);
        return;
      case QUANTITYONHAND:
        setQuantityOnHand((Number)value);
        return;
      case STARTDATE:
        setStartDate((Date)value);
        return;
      case ENDDATE:
        setEndDate((Date)value);
        return;
      case ITEMTYPE:
        setItemType((String)value);
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
  public static Key createPrimaryKey(String Item, String WarehouseLocation)
  {
    return new Key(new Object[] {Item, WarehouseLocation});
  }
















}