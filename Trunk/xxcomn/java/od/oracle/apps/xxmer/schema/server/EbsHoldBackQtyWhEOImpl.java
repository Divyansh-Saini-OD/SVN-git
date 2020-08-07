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

public class EbsHoldBackQtyWhEOImpl extends OAEntityImpl 
{
  protected static final int ITEM = 0;
  protected static final int WAREHOUSELOCATION = 1;
  protected static final int QUANTITYONHAND = 2;
  protected static final int LASTUPDATEDATE = 3;
  protected static final int LASTUPDATEDBY = 4;
  protected static final int CREATIONDATE = 5;
  protected static final int CREATEDBY = 6;
  protected static final int LASTUPDATELOGIN = 7;
  protected static final int ODHOLDBACKQTYEO = 8;


  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public EbsHoldBackQtyWhEOImpl()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: EbsHoldBackQtyWhEOImpl called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: EbsHoldBackQtyWhEOImpl exited");   
  
  }

  /**
   * 
   * Retrieves the definition object for this instance class.
   */
  public static synchronized EntityDefImpl getDefinitionObject()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: getDefinitionObject called");   
  
    if (mDefinitionObject == null)
    {
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxmer.schema.server.EbsHoldBackQtyWhEO");
    }
    System.out.println("EbsHoldBackQtyWhEOImpl: getDefinitionObject exited");   
    
    return mDefinitionObject;
  }



  /**
   * 
   * Add attribute defaulting logic in this method.
   */
  public void create(AttributeList attributeList)
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: create called");   
  
    super.create(attributeList);
    System.out.println("EbsHoldBackQtyWhEOImpl: create exited");   

  }

  /**
   * 
   * Add entity remove logic in this method.
   */
  public void remove()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: remove called");   
  
    super.remove();
    System.out.println("EbsHoldBackQtyWhEOImpl: remove exited");   

  }

  /**
   * 
   * Add Entity validation code in this method.
   */
  protected void validateEntity()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: validateEntity called");   
  
    super.validateEntity();
    System.out.println("EbsHoldBackQtyWhEOImpl: validateEntity exited");   

  }

  /**
   * 
   * Gets the attribute value for Item, using the alias name Item
   */
  public String getItem()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: getItem called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: getItem exited");   
  
    return (String)getAttributeInternal(ITEM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Item
   */
  public void setItem(String value)
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: setItem called");   
  
    setAttributeInternal(ITEM, value);
    System.out.println("EbsHoldBackQtyWhEOImpl: setItem exited");   

  }

  /**
   * 
   * Gets the attribute value for WarehouseLocation, using the alias name WarehouseLocation
   */
  public String getWarehouseLocation()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: getWarehouseLocation called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: getWarehouseLocation exited");   
  
    return (String)getAttributeInternal(WAREHOUSELOCATION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for WarehouseLocation
   */
  public void setWarehouseLocation(String value)
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: setWarehouseLocation called");   
  
    setAttributeInternal(WAREHOUSELOCATION, value);
    System.out.println("EbsHoldBackQtyWhEOImpl: setWarehouseLocation exited");   

  }

  /**
   * 
   * Gets the attribute value for QuantityOnHand, using the alias name QuantityOnHand
   */
  public Number getQuantityOnHand()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: getQuantityOnHand called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: getQuantityOnHand exited");   
  
    return (Number)getAttributeInternal(QUANTITYONHAND);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuantityOnHand
   */
  public void setQuantityOnHand(Number value)
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: setQuantityOnHand called");   
  
    setAttributeInternal(QUANTITYONHAND, value);
    System.out.println("EbsHoldBackQtyWhEOImpl: setQuantityOnHand exited");   

  }

  /**
   * 
   * Gets the attribute value for LastUpdateDate, using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: getLastUpdateDate called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: getLastUpdateDate exited");   

    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: setLastUpdateDate called");   
  
    setAttributeInternal(LASTUPDATEDATE, value);
    System.out.println("EbsHoldBackQtyWhEOImpl: setLastUpdateDate exited");   

  }

  /**
   * 
   * Gets the attribute value for LastUpdatedBy, using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: getLastUpdatedBy called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: getLastUpdatedBy exited");   

    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: setLastUpdatedBy called");   
  
    setAttributeInternal(LASTUPDATEDBY, value);
    System.out.println("EbsHoldBackQtyWhEOImpl: setLastUpdatedBy exited");   

  }

  /**
   * 
   * Gets the attribute value for CreationDate, using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: getCreationDate called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: getCreationDate exited");   
  
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreationDate
   */
  public void setCreationDate(Date value)
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: setCreationDate called");   
  
    setAttributeInternal(CREATIONDATE, value);
    System.out.println("EbsHoldBackQtyWhEOImpl: setCreationDate exited");   

  }

  /**
   * 
   * Gets the attribute value for CreatedBy, using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: getCreatedBy called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: getCreatedBy exited");   
  
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: setCreatedBy called");   
  
    setAttributeInternal(CREATEDBY, value);
    System.out.println("EbsHoldBackQtyWhEOImpl: setCreatedBy exited");   

  }

  /**
   * 
   * Gets the attribute value for LastUpdateLogin, using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: getLastUpdateLogin called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: getLastUpdateLogin exited");   

    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: setLastUpdateLogin called");   
  
    setAttributeInternal(LASTUPDATELOGIN, value);
    System.out.println("EbsHoldBackQtyWhEOImpl: setLastUpdateLogin exited");   

  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: getAttrInvokeAccessor called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: getAttrInvokeAccessor exited");   
  
    switch (index)
      {
      case ITEM:
        return getItem();
      case WAREHOUSELOCATION:
        return getWarehouseLocation();
      case QUANTITYONHAND:
        return getQuantityOnHand();
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
      case ODHOLDBACKQTYEO:
        return getOdHoldBackQtyEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: setAttrInvokeAccessor called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: setAttrInvokeAccessor exited");   
  
    switch (index)
      {
      case ITEM:
        setItem((String)value);
        return;
      case WAREHOUSELOCATION:
        setWarehouseLocation((String)value);
        return;
      case QUANTITYONHAND:
        setQuantityOnHand((Number)value);
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
   * Gets the associated entity OdHoldBackQtyEOImpl
   */
  public OdHoldBackQtyEOImpl getOdHoldBackQtyEO()
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: getOdHoldBackQtyEO called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: getOdHoldBackQtyEO exited");   
  
    return (OdHoldBackQtyEOImpl)getAttributeInternal(ODHOLDBACKQTYEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity OdHoldBackQtyEOImpl
   */
  public void setOdHoldBackQtyEO(OdHoldBackQtyEOImpl value)
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: setOdHoldBackQtyEO called");   
  
    setAttributeInternal(ODHOLDBACKQTYEO, value);
    System.out.println("EbsHoldBackQtyWhEOImpl: setOdHoldBackQtyEO exited");   

  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(String item, String warehouseLocation)
  {
    System.out.println("EbsHoldBackQtyWhEOImpl: createPrimaryKey called");   
    System.out.println("EbsHoldBackQtyWhEOImpl: createPrimaryKey exited");   
  
    return new Key(new Object[] {item, warehouseLocation});
  }


}