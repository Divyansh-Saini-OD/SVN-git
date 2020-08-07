package od.oracle.apps.xxcrm.cs.csz.servicerequest.schema.server;
import oracle.apps.fnd.framework.server.OAEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.RowID;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class OD_ServiceRequestDetailEOImpl extends OAEntityImpl 
{
  protected static final int REQUESTNUMBER = 0;
  protected static final int STOREID = 1;
  protected static final int LINENUMBER = 2;
  protected static final int ITEMNUMBER = 3;
  protected static final int ITEMDESCRIPTION = 4;
  protected static final int RMSSKU = 5;
  protected static final int QUANTITY = 6;
  protected static final int ITEMCATEGORY = 7;
  protected static final int PURCHASEPRICE = 8;
  protected static final int SELLINGPRICE = 9;
  protected static final int EXCHANGEPRICE = 10;
  protected static final int COREFLAG = 11;
  protected static final int UOM = 12;
  protected static final int SCHEDULEDATE = 13;
  protected static final int CREATIONDATE = 14;
  protected static final int CREATEDBY = 15;
  protected static final int LASTUDATEDATE = 16;
  protected static final int LASTUPDATEDBY = 17;
  protected static final int ATTRIBUTE1 = 18;
  protected static final int ATTRIBUTE2 = 19;
  protected static final int ATTRIBUTE3 = 20;
  protected static final int ATTRIBUTE4 = 21;
  protected static final int ATTRIBUTE5 = 22;
  protected static final int SALESFLAG = 23;
  protected static final int MANUFACTURER = 24;
  protected static final int MODEL = 25;
  protected static final int SERIALNUMBER = 26;
  protected static final int PROBLEMDESCR = 27;
  protected static final int SPECIALINSTR = 28;
  protected static final int INVENTORYITEMID = 29;
  protected static final int STORENUMBER = 30;
  protected static final int QUOTENUMBER = 31;
  protected static final int EXPIREDATE = 32;
  protected static final int EXCESSQUANTITY = 33;
  protected static final int EXCESSFLAG = 34;
  protected static final int RECEIVEDQUANTITY = 35;
  protected static final int RECEIVEDSHIPMENTFLAG = 36;
  protected static final int COMPLETIONDATE = 37;
  protected static final int ROWID = 38;

  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public OD_ServiceRequestDetailEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxcrm.cs.csz.servicerequest.schema.server.OD_ServiceRequestDetailEO");
    }
    return mDefinitionObject;
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

public void setCreatedBy(String n)
{

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
   * Gets the attribute value for StoreId, using the alias name StoreId
   */
  public Number getStoreId()
  {
    return (Number)getAttributeInternal(STOREID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for StoreId
   */
  public void setStoreId(Number value)
  {
    setAttributeInternal(STOREID, value);
  }

  /**
   * 
   * Gets the attribute value for LineNumber, using the alias name LineNumber
   */
  public Number getLineNumber()
  {
    return (Number)getAttributeInternal(LINENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LineNumber
   */
  public void setLineNumber(Number value)
  {
    setAttributeInternal(LINENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ItemNumber, using the alias name ItemNumber
   */
  public String getItemNumber()
  {
    return (String)getAttributeInternal(ITEMNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ItemNumber
   */
  public void setItemNumber(String value)
  {
    setAttributeInternal(ITEMNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ItemDescription, using the alias name ItemDescription
   */
  public String getItemDescription()
  {
    return (String)getAttributeInternal(ITEMDESCRIPTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ItemDescription
   */
  public void setItemDescription(String value)
  {
    setAttributeInternal(ITEMDESCRIPTION, value);
  }

  /**
   * 
   * Gets the attribute value for RmsSku, using the alias name RmsSku
   */
  public String getRmsSku()
  {
    return (String)getAttributeInternal(RMSSKU);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for RmsSku
   */
  public void setRmsSku(String value)
  {
    setAttributeInternal(RMSSKU, value);
  }

  /**
   * 
   * Gets the attribute value for Quantity, using the alias name Quantity
   */
  public Number getQuantity()
  {
    return (Number)getAttributeInternal(QUANTITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Quantity
   */
  public void setQuantity(Number value)
  {
    setAttributeInternal(QUANTITY, value);
  }

  /**
   * 
   * Gets the attribute value for ItemCategory, using the alias name ItemCategory
   */
  public String getItemCategory()
  {
    return (String)getAttributeInternal(ITEMCATEGORY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ItemCategory
   */
  public void setItemCategory(String value)
  {
    setAttributeInternal(ITEMCATEGORY, value);
  }

  /**
   * 
   * Gets the attribute value for PurchasePrice, using the alias name PurchasePrice
   */
  public Number getPurchasePrice()
  {
    return (Number)getAttributeInternal(PURCHASEPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PurchasePrice
   */
  public void setPurchasePrice(Number value)
  {
    setAttributeInternal(PURCHASEPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for SellingPrice, using the alias name SellingPrice
   */
  public Number getSellingPrice()
  {
    return (Number)getAttributeInternal(SELLINGPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SellingPrice
   */
  public void setSellingPrice(Number value)
  {
    setAttributeInternal(SELLINGPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for ExchangePrice, using the alias name ExchangePrice
   */
  public Number getExchangePrice()
  {
    return (Number)getAttributeInternal(EXCHANGEPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ExchangePrice
   */
  public void setExchangePrice(Number value)
  {
    setAttributeInternal(EXCHANGEPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for CoreFlag, using the alias name CoreFlag
   */
  public String getCoreFlag()
  {
    return (String)getAttributeInternal(COREFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CoreFlag
   */
  public void setCoreFlag(String value)
  {
    setAttributeInternal(COREFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for Uom, using the alias name Uom
   */
  public String getUom()
  {
    return (String)getAttributeInternal(UOM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Uom
   */
  public void setUom(String value)
  {
    setAttributeInternal(UOM, value);
  }

  /**
   * 
   * Gets the attribute value for ScheduleDate, using the alias name ScheduleDate
   */
  public Date getScheduleDate()
  {
    return (Date)getAttributeInternal(SCHEDULEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ScheduleDate
   */
  public void setScheduleDate(Date value)
  {
    setAttributeInternal(SCHEDULEDATE, value);
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
  public void setCreatedBy(oracle.jbo.domain.Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LastUdateDate, using the alias name LastUdateDate
   */
  public Date getLastUdateDate()
  {
    return (Date)getAttributeInternal(LASTUDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUdateDate
   */
  public void setLastUdateDate(Date value)
  {
    setAttributeInternal(LASTUDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdatedBy, using the alias name LastUpdatedBy
   */
  public String getLastUpdatedBy()
  {
    return (String)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdatedBy
   */
  public void setLastUpdatedBy(oracle.jbo.domain.Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute1, using the alias name Attribute1
   */
  public String getAttribute1()
  {
    return (String)getAttributeInternal(ATTRIBUTE1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute1
   */
  public void setAttribute1(String value)
  {
    setAttributeInternal(ATTRIBUTE1, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute2, using the alias name Attribute2
   */
  public String getAttribute2()
  {
    return (String)getAttributeInternal(ATTRIBUTE2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute2
   */
  public void setAttribute2(String value)
  {
    setAttributeInternal(ATTRIBUTE2, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute3, using the alias name Attribute3
   */
  public String getAttribute3()
  {
    return (String)getAttributeInternal(ATTRIBUTE3);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute3
   */
  public void setAttribute3(String value)
  {
    setAttributeInternal(ATTRIBUTE3, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute4, using the alias name Attribute4
   */
  public String getAttribute4()
  {
    return (String)getAttributeInternal(ATTRIBUTE4);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute4
   */
  public void setAttribute4(String value)
  {
    setAttributeInternal(ATTRIBUTE4, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute5, using the alias name Attribute5
   */
  public String getAttribute5()
  {
    return (String)getAttributeInternal(ATTRIBUTE5);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute5
   */
  public void setAttribute5(String value)
  {
    setAttributeInternal(ATTRIBUTE5, value);
  }

  /**
   * 
   * Gets the attribute value for SalesFlag, using the alias name SalesFlag
   */
  public String getSalesFlag()
  {
    return (String)getAttributeInternal(SALESFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesFlag
   */
  public void setSalesFlag(String value)
  {
    setAttributeInternal(SALESFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for Manufacturer, using the alias name Manufacturer
   */
  public String getManufacturer()
  {
    return (String)getAttributeInternal(MANUFACTURER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Manufacturer
   */
  public void setManufacturer(String value)
  {
    setAttributeInternal(MANUFACTURER, value);
  }

  /**
   * 
   * Gets the attribute value for Model, using the alias name Model
   */
  public String getModel()
  {
    return (String)getAttributeInternal(MODEL);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Model
   */
  public void setModel(String value)
  {
    setAttributeInternal(MODEL, value);
  }

  /**
   * 
   * Gets the attribute value for SerialNumber, using the alias name SerialNumber
   */
  public String getSerialNumber()
  {
    return (String)getAttributeInternal(SERIALNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SerialNumber
   */
  public void setSerialNumber(String value)
  {
    setAttributeInternal(SERIALNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ProblemDescr, using the alias name ProblemDescr
   */
  public String getProblemDescr()
  {
    return (String)getAttributeInternal(PROBLEMDESCR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProblemDescr
   */
  public void setProblemDescr(String value)
  {
    setAttributeInternal(PROBLEMDESCR, value);
  }

  /**
   * 
   * Gets the attribute value for SpecialInstr, using the alias name SpecialInstr
   */
  public String getSpecialInstr()
  {
    return (String)getAttributeInternal(SPECIALINSTR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpecialInstr
   */
  public void setSpecialInstr(String value)
  {
    setAttributeInternal(SPECIALINSTR, value);
  }

  /**
   * 
   * Gets the attribute value for InventoryItemId, using the alias name InventoryItemId
   */
  public Number getInventoryItemId()
  {
    return (Number)getAttributeInternal(INVENTORYITEMID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InventoryItemId
   */
  public void setInventoryItemId(Number value)
  {
    setAttributeInternal(INVENTORYITEMID, value);
  }

  /**
   * 
   * Gets the attribute value for StoreNumber, using the alias name StoreNumber
   */
  public Number getStoreNumber()
  {
    return (Number)getAttributeInternal(STORENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for StoreNumber
   */
  public void setStoreNumber(Number value)
  {
    setAttributeInternal(STORENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for QuoteNumber, using the alias name QuoteNumber
   */
  public String getQuoteNumber()
  {
    return (String)getAttributeInternal(QUOTENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for QuoteNumber
   */
  public void setQuoteNumber(String value)
  {
    setAttributeInternal(QUOTENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ExpireDate, using the alias name ExpireDate
   */
  public Date getExpireDate()
  {
    return (Date)getAttributeInternal(EXPIREDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ExpireDate
   */
  public void setExpireDate(Date value)
  {
    setAttributeInternal(EXPIREDATE, value);
  }

  /**
   * 
   * Gets the attribute value for ExcessQuantity, using the alias name ExcessQuantity
   */
  public Number getExcessQuantity()
  {
    return (Number)getAttributeInternal(EXCESSQUANTITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ExcessQuantity
   */
  public void setExcessQuantity(Number value)
  {
    setAttributeInternal(EXCESSQUANTITY, value);
  }

  /**
   * 
   * Gets the attribute value for ExcessFlag, using the alias name ExcessFlag
   */
  public String getExcessFlag()
  {
    return (String)getAttributeInternal(EXCESSFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ExcessFlag
   */
  public void setExcessFlag(String value)
  {
    setAttributeInternal(EXCESSFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for ReceivedQuantity, using the alias name ReceivedQuantity
   */
  public Number getReceivedQuantity()
  {
    return (Number)getAttributeInternal(RECEIVEDQUANTITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ReceivedQuantity
   */
  public void setReceivedQuantity(Number value)
  {
    setAttributeInternal(RECEIVEDQUANTITY, value);
  }

  /**
   * 
   * Gets the attribute value for ReceivedShipmentFlag, using the alias name ReceivedShipmentFlag
   */
  public String getReceivedShipmentFlag()
  {
    return (String)getAttributeInternal(RECEIVEDSHIPMENTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ReceivedShipmentFlag
   */
  public void setReceivedShipmentFlag(String value)
  {
    setAttributeInternal(RECEIVEDSHIPMENTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for CompletionDate, using the alias name CompletionDate
   */
  public Date getCompletionDate()
  {
    return (Date)getAttributeInternal(COMPLETIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CompletionDate
   */
  public void setCompletionDate(Date value)
  {
    setAttributeInternal(COMPLETIONDATE, value);
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
      case REQUESTNUMBER:
        return getRequestNumber();
      case STOREID:
        return getStoreId();
      case LINENUMBER:
        return getLineNumber();
      case ITEMNUMBER:
        return getItemNumber();
      case ITEMDESCRIPTION:
        return getItemDescription();
      case RMSSKU:
        return getRmsSku();
      case QUANTITY:
        return getQuantity();
      case ITEMCATEGORY:
        return getItemCategory();
      case PURCHASEPRICE:
        return getPurchasePrice();
      case SELLINGPRICE:
        return getSellingPrice();
      case EXCHANGEPRICE:
        return getExchangePrice();
      case COREFLAG:
        return getCoreFlag();
      case UOM:
        return getUom();
      case SCHEDULEDATE:
        return getScheduleDate();
      case CREATIONDATE:
        return getCreationDate();
      case CREATEDBY:
        return getCreatedBy();
      case LASTUDATEDATE:
        return getLastUdateDate();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case ATTRIBUTE1:
        return getAttribute1();
      case ATTRIBUTE2:
        return getAttribute2();
      case ATTRIBUTE3:
        return getAttribute3();
      case ATTRIBUTE4:
        return getAttribute4();
      case ATTRIBUTE5:
        return getAttribute5();
      case SALESFLAG:
        return getSalesFlag();
      case MANUFACTURER:
        return getManufacturer();
      case MODEL:
        return getModel();
      case SERIALNUMBER:
        return getSerialNumber();
      case PROBLEMDESCR:
        return getProblemDescr();
      case SPECIALINSTR:
        return getSpecialInstr();
      case INVENTORYITEMID:
        return getInventoryItemId();
      case STORENUMBER:
        return getStoreNumber();
      case QUOTENUMBER:
        return getQuoteNumber();
      case EXPIREDATE:
        return getExpireDate();
      case EXCESSQUANTITY:
        return getExcessQuantity();
      case EXCESSFLAG:
        return getExcessFlag();
      case RECEIVEDQUANTITY:
        return getReceivedQuantity();
      case RECEIVEDSHIPMENTFLAG:
        return getReceivedShipmentFlag();
      case COMPLETIONDATE:
        return getCompletionDate();
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
      case STOREID:
        setStoreId((Number)value);
        return;
      case LINENUMBER:
        setLineNumber((Number)value);
        return;
      case ITEMNUMBER:
        setItemNumber((String)value);
        return;
      case ITEMDESCRIPTION:
        setItemDescription((String)value);
        return;
      case RMSSKU:
        setRmsSku((String)value);
        return;
      case QUANTITY:
        setQuantity((Number)value);
        return;
      case ITEMCATEGORY:
        setItemCategory((String)value);
        return;
      case PURCHASEPRICE:
        setPurchasePrice((Number)value);
        return;
      case SELLINGPRICE:
        setSellingPrice((Number)value);
        return;
      case EXCHANGEPRICE:
        setExchangePrice((Number)value);
        return;
      case COREFLAG:
        setCoreFlag((String)value);
        return;
      case UOM:
        setUom((String)value);
        return;
      case SCHEDULEDATE:
        setScheduleDate((Date)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case CREATEDBY:
        setCreatedBy((String)value);
        return;
      case LASTUDATEDATE:
        setLastUdateDate((Date)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((String)value);
        return;
      case ATTRIBUTE1:
        setAttribute1((String)value);
        return;
      case ATTRIBUTE2:
        setAttribute2((String)value);
        return;
      case ATTRIBUTE3:
        setAttribute3((String)value);
        return;
      case ATTRIBUTE4:
        setAttribute4((String)value);
        return;
      case ATTRIBUTE5:
        setAttribute5((String)value);
        return;
      case SALESFLAG:
        setSalesFlag((String)value);
        return;
      case MANUFACTURER:
        setManufacturer((String)value);
        return;
      case MODEL:
        setModel((String)value);
        return;
      case SERIALNUMBER:
        setSerialNumber((String)value);
        return;
      case PROBLEMDESCR:
        setProblemDescr((String)value);
        return;
      case SPECIALINSTR:
        setSpecialInstr((String)value);
        return;
      case INVENTORYITEMID:
        setInventoryItemId((Number)value);
        return;
      case STORENUMBER:
        setStoreNumber((Number)value);
        return;
      case QUOTENUMBER:
        setQuoteNumber((String)value);
        return;
      case EXPIREDATE:
        setExpireDate((Date)value);
        return;
      case EXCESSQUANTITY:
        setExcessQuantity((Number)value);
        return;
      case EXCESSFLAG:
        setExcessFlag((String)value);
        return;
      case RECEIVEDQUANTITY:
        setReceivedQuantity((Number)value);
        return;
      case RECEIVEDSHIPMENTFLAG:
        setReceivedShipmentFlag((String)value);
        return;
      case COMPLETIONDATE:
        setCompletionDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}