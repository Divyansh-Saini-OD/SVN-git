/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODHzPartySitesExtTLEOImpl.java                                |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Entity Object Implementation for HZ_PARTY_SITES_EXT_TL Translatable    |
 |    Table                                                                  |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Add Site Contact Page                                |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |     No dependencies.                                                      |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   21-Sep-2007 Jasmine Sujithra   Created                                  |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.server;
import oracle.apps.fnd.framework.server.OAEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.AttributeList;
import oracle.jbo.server.TransactionEvent;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODHzPartySitesExtTLEOImpl extends OAEntityImpl 
{
  protected static final int EXTENSIONID = 0;
  protected static final int PARTYSITEID = 1;
  protected static final int ATTRGROUPID = 2;
  protected static final int SOURCELANG = 3;
  protected static final int LANGUAGE = 4;
  protected static final int CREATEDBY = 5;
  protected static final int CREATIONDATE = 6;
  protected static final int LASTUPDATEDBY = 7;
  protected static final int LASTUPDATEDATE = 8;
  protected static final int LASTUPDATELOGIN = 9;
  protected static final int TLEXTATTR1 = 10;
  protected static final int TLEXTATTR2 = 11;
  protected static final int TLEXTATTR3 = 12;
  protected static final int TLEXTATTR4 = 13;
  protected static final int TLEXTATTR5 = 14;
  protected static final int TLEXTATTR6 = 15;
  protected static final int TLEXTATTR7 = 16;
  protected static final int TLEXTATTR8 = 17;
  protected static final int TLEXTATTR9 = 18;
  protected static final int TLEXTATTR10 = 19;
  protected static final int TLEXTATTR11 = 20;
  protected static final int TLEXTATTR12 = 21;
  protected static final int TLEXTATTR13 = 22;
  protected static final int TLEXTATTR14 = 23;
  protected static final int TLEXTATTR15 = 24;
  protected static final int TLEXTATTR16 = 25;
  protected static final int TLEXTATTR17 = 26;
  protected static final int TLEXTATTR18 = 27;
  protected static final int TLEXTATTR19 = 28;
  protected static final int TLEXTATTR20 = 29;
  protected static final int ODHZPARTYSITESEXTVLEO = 30;











  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODHzPartySitesExtTLEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxcrm.asn.common.customer.server.ODHzPartySitesExtTLEO");
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
   * Add locking logic here.
   */
  public void lock()
  {
    super.lock();
  }

  /**
   * 
   * Custom DML update/insert/delete logic here.
   */
  protected void doDML(int operation, TransactionEvent e)
  {
    super.doDML(operation, e);
  }

  /**
   * 
   * Gets the attribute value for ExtensionId, using the alias name ExtensionId
   */
  public Number getExtensionId()
  {
    return (Number)getAttributeInternal(EXTENSIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ExtensionId
   */
  public void setExtensionId(Number value)
  {
    setAttributeInternal(EXTENSIONID, value);
  }

  /**
   * 
   * Gets the attribute value for PartySiteId, using the alias name PartySiteId
   */
  public Number getPartySiteId()
  {
    return (Number)getAttributeInternal(PARTYSITEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PartySiteId
   */
  public void setPartySiteId(Number value)
  {
    setAttributeInternal(PARTYSITEID, value);
  }

  /**
   * 
   * Gets the attribute value for AttrGroupId, using the alias name AttrGroupId
   */
  public Number getAttrGroupId()
  {
    return (Number)getAttributeInternal(ATTRGROUPID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AttrGroupId
   */
  public void setAttrGroupId(Number value)
  {
    setAttributeInternal(ATTRGROUPID, value);
  }

  /**
   * 
   * Gets the attribute value for SourceLang, using the alias name SourceLang
   */
  public String getSourceLang()
  {
    return (String)getAttributeInternal(SOURCELANG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SourceLang
   */
  public void setSourceLang(String value)
  {
    setAttributeInternal(SOURCELANG, value);
  }

  /**
   * 
   * Gets the attribute value for Language, using the alias name Language
   */
  public String getLanguage()
  {
    return (String)getAttributeInternal(LANGUAGE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Language
   */
  public void setLanguage(String value)
  {
    setAttributeInternal(LANGUAGE, value);
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

  /**
   * 
   * Gets the attribute value for TlExtAttr1, using the alias name TlExtAttr1
   */
  public String getTlExtAttr1()
  {
    return (String)getAttributeInternal(TLEXTATTR1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr1
   */
  public void setTlExtAttr1(String value)
  {
    setAttributeInternal(TLEXTATTR1, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr2, using the alias name TlExtAttr2
   */
  public String getTlExtAttr2()
  {
    return (String)getAttributeInternal(TLEXTATTR2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr2
   */
  public void setTlExtAttr2(String value)
  {
    setAttributeInternal(TLEXTATTR2, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr3, using the alias name TlExtAttr3
   */
  public String getTlExtAttr3()
  {
    return (String)getAttributeInternal(TLEXTATTR3);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr3
   */
  public void setTlExtAttr3(String value)
  {
    setAttributeInternal(TLEXTATTR3, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr4, using the alias name TlExtAttr4
   */
  public String getTlExtAttr4()
  {
    return (String)getAttributeInternal(TLEXTATTR4);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr4
   */
  public void setTlExtAttr4(String value)
  {
    setAttributeInternal(TLEXTATTR4, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr5, using the alias name TlExtAttr5
   */
  public String getTlExtAttr5()
  {
    return (String)getAttributeInternal(TLEXTATTR5);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr5
   */
  public void setTlExtAttr5(String value)
  {
    setAttributeInternal(TLEXTATTR5, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr6, using the alias name TlExtAttr6
   */
  public String getTlExtAttr6()
  {
    return (String)getAttributeInternal(TLEXTATTR6);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr6
   */
  public void setTlExtAttr6(String value)
  {
    setAttributeInternal(TLEXTATTR6, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr7, using the alias name TlExtAttr7
   */
  public String getTlExtAttr7()
  {
    return (String)getAttributeInternal(TLEXTATTR7);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr7
   */
  public void setTlExtAttr7(String value)
  {
    setAttributeInternal(TLEXTATTR7, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr8, using the alias name TlExtAttr8
   */
  public String getTlExtAttr8()
  {
    return (String)getAttributeInternal(TLEXTATTR8);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr8
   */
  public void setTlExtAttr8(String value)
  {
    setAttributeInternal(TLEXTATTR8, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr9, using the alias name TlExtAttr9
   */
  public String getTlExtAttr9()
  {
    return (String)getAttributeInternal(TLEXTATTR9);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr9
   */
  public void setTlExtAttr9(String value)
  {
    setAttributeInternal(TLEXTATTR9, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr10, using the alias name TlExtAttr10
   */
  public String getTlExtAttr10()
  {
    return (String)getAttributeInternal(TLEXTATTR10);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr10
   */
  public void setTlExtAttr10(String value)
  {
    setAttributeInternal(TLEXTATTR10, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr11, using the alias name TlExtAttr11
   */
  public String getTlExtAttr11()
  {
    return (String)getAttributeInternal(TLEXTATTR11);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr11
   */
  public void setTlExtAttr11(String value)
  {
    setAttributeInternal(TLEXTATTR11, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr12, using the alias name TlExtAttr12
   */
  public String getTlExtAttr12()
  {
    return (String)getAttributeInternal(TLEXTATTR12);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr12
   */
  public void setTlExtAttr12(String value)
  {
    setAttributeInternal(TLEXTATTR12, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr13, using the alias name TlExtAttr13
   */
  public String getTlExtAttr13()
  {
    return (String)getAttributeInternal(TLEXTATTR13);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr13
   */
  public void setTlExtAttr13(String value)
  {
    setAttributeInternal(TLEXTATTR13, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr14, using the alias name TlExtAttr14
   */
  public String getTlExtAttr14()
  {
    return (String)getAttributeInternal(TLEXTATTR14);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr14
   */
  public void setTlExtAttr14(String value)
  {
    setAttributeInternal(TLEXTATTR14, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr15, using the alias name TlExtAttr15
   */
  public String getTlExtAttr15()
  {
    return (String)getAttributeInternal(TLEXTATTR15);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr15
   */
  public void setTlExtAttr15(String value)
  {
    setAttributeInternal(TLEXTATTR15, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr16, using the alias name TlExtAttr16
   */
  public String getTlExtAttr16()
  {
    return (String)getAttributeInternal(TLEXTATTR16);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr16
   */
  public void setTlExtAttr16(String value)
  {
    setAttributeInternal(TLEXTATTR16, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr17, using the alias name TlExtAttr17
   */
  public String getTlExtAttr17()
  {
    return (String)getAttributeInternal(TLEXTATTR17);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr17
   */
  public void setTlExtAttr17(String value)
  {
    setAttributeInternal(TLEXTATTR17, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr18, using the alias name TlExtAttr18
   */
  public String getTlExtAttr18()
  {
    return (String)getAttributeInternal(TLEXTATTR18);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr18
   */
  public void setTlExtAttr18(String value)
  {
    setAttributeInternal(TLEXTATTR18, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr19, using the alias name TlExtAttr19
   */
  public String getTlExtAttr19()
  {
    return (String)getAttributeInternal(TLEXTATTR19);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr19
   */
  public void setTlExtAttr19(String value)
  {
    setAttributeInternal(TLEXTATTR19, value);
  }

  /**
   * 
   * Gets the attribute value for TlExtAttr20, using the alias name TlExtAttr20
   */
  public String getTlExtAttr20()
  {
    return (String)getAttributeInternal(TLEXTATTR20);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TlExtAttr20
   */
  public void setTlExtAttr20(String value)
  {
    setAttributeInternal(TLEXTATTR20, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EXTENSIONID:
        return getExtensionId();
      case PARTYSITEID:
        return getPartySiteId();
      case ATTRGROUPID:
        return getAttrGroupId();
      case SOURCELANG:
        return getSourceLang();
      case LANGUAGE:
        return getLanguage();
      case CREATEDBY:
        return getCreatedBy();
      case CREATIONDATE:
        return getCreationDate();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case LASTUPDATELOGIN:
        return getLastUpdateLogin();
      case TLEXTATTR1:
        return getTlExtAttr1();
      case TLEXTATTR2:
        return getTlExtAttr2();
      case TLEXTATTR3:
        return getTlExtAttr3();
      case TLEXTATTR4:
        return getTlExtAttr4();
      case TLEXTATTR5:
        return getTlExtAttr5();
      case TLEXTATTR6:
        return getTlExtAttr6();
      case TLEXTATTR7:
        return getTlExtAttr7();
      case TLEXTATTR8:
        return getTlExtAttr8();
      case TLEXTATTR9:
        return getTlExtAttr9();
      case TLEXTATTR10:
        return getTlExtAttr10();
      case TLEXTATTR11:
        return getTlExtAttr11();
      case TLEXTATTR12:
        return getTlExtAttr12();
      case TLEXTATTR13:
        return getTlExtAttr13();
      case TLEXTATTR14:
        return getTlExtAttr14();
      case TLEXTATTR15:
        return getTlExtAttr15();
      case TLEXTATTR16:
        return getTlExtAttr16();
      case TLEXTATTR17:
        return getTlExtAttr17();
      case TLEXTATTR18:
        return getTlExtAttr18();
      case TLEXTATTR19:
        return getTlExtAttr19();
      case TLEXTATTR20:
        return getTlExtAttr20();
      case ODHZPARTYSITESEXTVLEO:
        return getODHzPartySitesExtVlEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EXTENSIONID:
        setExtensionId((Number)value);
        return;
      case PARTYSITEID:
        setPartySiteId((Number)value);
        return;
      case ATTRGROUPID:
        setAttrGroupId((Number)value);
        return;
      case SOURCELANG:
        setSourceLang((String)value);
        return;
      case LANGUAGE:
        setLanguage((String)value);
        return;
      case CREATEDBY:
        setCreatedBy((Number)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((Number)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case LASTUPDATELOGIN:
        setLastUpdateLogin((Number)value);
        return;
      case TLEXTATTR1:
        setTlExtAttr1((String)value);
        return;
      case TLEXTATTR2:
        setTlExtAttr2((String)value);
        return;
      case TLEXTATTR3:
        setTlExtAttr3((String)value);
        return;
      case TLEXTATTR4:
        setTlExtAttr4((String)value);
        return;
      case TLEXTATTR5:
        setTlExtAttr5((String)value);
        return;
      case TLEXTATTR6:
        setTlExtAttr6((String)value);
        return;
      case TLEXTATTR7:
        setTlExtAttr7((String)value);
        return;
      case TLEXTATTR8:
        setTlExtAttr8((String)value);
        return;
      case TLEXTATTR9:
        setTlExtAttr9((String)value);
        return;
      case TLEXTATTR10:
        setTlExtAttr10((String)value);
        return;
      case TLEXTATTR11:
        setTlExtAttr11((String)value);
        return;
      case TLEXTATTR12:
        setTlExtAttr12((String)value);
        return;
      case TLEXTATTR13:
        setTlExtAttr13((String)value);
        return;
      case TLEXTATTR14:
        setTlExtAttr14((String)value);
        return;
      case TLEXTATTR15:
        setTlExtAttr15((String)value);
        return;
      case TLEXTATTR16:
        setTlExtAttr16((String)value);
        return;
      case TLEXTATTR17:
        setTlExtAttr17((String)value);
        return;
      case TLEXTATTR18:
        setTlExtAttr18((String)value);
        return;
      case TLEXTATTR19:
        setTlExtAttr19((String)value);
        return;
      case TLEXTATTR20:
        setTlExtAttr20((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }


  /**
   * 
   * Gets the associated entity ODHzPartySitesExtVlEOImpl
   */
  public ODHzPartySitesExtVlEOImpl getODHzPartySitesExtVlEO()
  {
    return (ODHzPartySitesExtVlEOImpl)getAttributeInternal(ODHZPARTYSITESEXTVLEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity ODHzPartySitesExtVlEOImpl
   */
  public void setODHzPartySitesExtVlEO(ODHzPartySitesExtVlEOImpl value)
  {
    setAttributeInternal(ODHZPARTYSITESEXTVLEO, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number extensionId)
  {
    return new Key(new Object[] {extensionId});
  }














}