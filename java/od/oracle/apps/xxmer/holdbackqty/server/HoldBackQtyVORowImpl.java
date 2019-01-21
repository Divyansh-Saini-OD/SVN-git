package od.oracle.apps.xxmer.holdbackqty.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class HoldBackQtyVORowImpl extends OAViewRowImpl 
{
  protected static final int ITEM = 0;
  protected static final int WAREHOUSELOCATION = 1;
  protected static final int HOLDQUANTITY = 2;
  protected static final int STARTDATE = 3;
  protected static final int ENDDATE = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public HoldBackQtyVORowImpl()
  {
    System.out.println("HoldBackQtyVORowImpl: HoldBackQtyVORowImpl called");   
    System.out.println("HoldBackQtyVORowImpl: HoldBackQtyVORowImpl exited");   
  
  }

  /**
   * 
   * Gets OdHoldBackQtyEO entity object.
   */
  public od.oracle.apps.xxmer.schema.server.OdHoldBackQtyEOImpl getOdHoldBackQtyEO()
  {
    System.out.println("HoldBackQtyVORowImpl: getOdHoldBackQtyEO called");   
    System.out.println("HoldBackQtyVORowImpl: getOdHoldBackQtyEO exited");   
  
    return (od.oracle.apps.xxmer.schema.server.OdHoldBackQtyEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for ITEM using the alias name Item
   */
  public String getItem()
  {
    System.out.println("HoldBackQtyVORowImpl: getItem called");   
    System.out.println("HoldBackQtyVORowImpl: getItem exited");   
  
    return (String)getAttributeInternal(ITEM);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ITEM using the alias name Item
   */
  public void setItem(String value)
  {
    System.out.println("HoldBackQtyVORowImpl: setItem called");   
  
    setAttributeInternal(ITEM, value);
    System.out.println("HoldBackQtyVORowImpl: setItem exited");   
    
  }

  /**
   * 
   * Gets the attribute value for WAREHOUSE_LOCATION using the alias name WarehouseLocation
   */
  public String getWarehouseLocation()
  {
    System.out.println("HoldBackQtyVORowImpl: getWarehouseLocation called");   
    System.out.println("HoldBackQtyVORowImpl: getWarehouseLocation exited");   
  
    return (String)getAttributeInternal(WAREHOUSELOCATION);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for WAREHOUSE_LOCATION using the alias name WarehouseLocation
   */
  public void setWarehouseLocation(String value)
  {
    System.out.println("HoldBackQtyVORowImpl: setWarehouseLocation called");   
  
    setAttributeInternal(WAREHOUSELOCATION, value);
    System.out.println("HoldBackQtyVORowImpl: setWarehouseLocation exited");   

  }

  /**
   * 
   * Gets the attribute value for HOLD_QUANTITY using the alias name HoldQuantity
   */
  public Number getHoldQuantity()
  {
    System.out.println("HoldBackQtyVORowImpl: getHoldQuantity called");   
    System.out.println("HoldBackQtyVORowImpl: getHoldQuantity exited");   
  
    return (Number)getAttributeInternal(HOLDQUANTITY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for HOLD_QUANTITY using the alias name HoldQuantity
   */
  public void setHoldQuantity(Number value)
  {
    System.out.println("HoldBackQtyVORowImpl: setHoldQuantity called");   
  
    setAttributeInternal(HOLDQUANTITY, value);
    System.out.println("HoldBackQtyVORowImpl: setHoldQuantity exited");   

  }

  /**
   * 
   * Gets the attribute value for START_DATE using the alias name StartDate
   */
  public Date getStartDate()
  {
    System.out.println("HoldBackQtyVORowImpl: getStartDate called");   
    System.out.println("HoldBackQtyVORowImpl: getStartDate exited");   
  
    return (Date)getAttributeInternal(STARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for START_DATE using the alias name StartDate
   */
  public void setStartDate(Date value)
  {
    System.out.println("HoldBackQtyVORowImpl: setStartDate called");   
  
    setAttributeInternal(STARTDATE, value);
    System.out.println("HoldBackQtyVORowImpl: setStartDate exited");   

  }

  /**
   * 
   * Gets the attribute value for END_DATE using the alias name EndDate
   */
  public Date getEndDate()
  {
    System.out.println("HoldBackQtyVORowImpl: getEndDate called");   
    System.out.println("HoldBackQtyVORowImpl: getEndDate exited");   
  
    return (Date)getAttributeInternal(ENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for END_DATE using the alias name EndDate
   */
  public void setEndDate(Date value)
  {
    System.out.println("HoldBackQtyVORowImpl: setEndDate called");   
  
    setAttributeInternal(ENDDATE, value);
    System.out.println("HoldBackQtyVORowImpl: setEndDate exited");   
    
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    System.out.println("HoldBackQtyVORowImpl: getAttrInvokeAccessor called");   
    System.out.println("HoldBackQtyVORowImpl: getAttrInvokeAccessor exited");   
  
    switch (index)
      {
      case ITEM:
        return getItem();
      case WAREHOUSELOCATION:
        return getWarehouseLocation();
      case HOLDQUANTITY:
        return getHoldQuantity();
      case STARTDATE:
        return getStartDate();
      case ENDDATE:
        return getEndDate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    System.out.println("HoldBackQtyVORowImpl: setAttrInvokeAccessor called");   
    System.out.println("HoldBackQtyVORowImpl: setAttrInvokeAccessor exited");   
  
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
      case STARTDATE:
        setStartDate((Date)value);
        return;
      case ENDDATE:
        setEndDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}