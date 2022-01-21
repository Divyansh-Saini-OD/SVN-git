package od.oracle.apps.xxcrm.scs.fdk.schema.server;
import oracle.apps.fnd.framework.server.OAEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;
import oracle.jbo.AttributeList;

import oracle.apps.fnd.framework.server.OADBTransaction;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODSCSFdbkHdrStgEOImpl extends OAEntityImpl 
{
  protected static final int FDBKID = 0;
  protected static final int CUSTOMERACCOUNTID = 1;
  protected static final int ADDRESSID = 2;
  protected static final int PARTYSITEID = 3;
  protected static final int PARTYID = 4;
  protected static final int MASSAPPLYFLAG = 5;
  protected static final int CONTACTID = 6;
  protected static final int LASTUPDATEDEMP = 7;
  protected static final int SALESTERRITORYID = 8;
  protected static final int RESOURCEID = 9;
  protected static final int ROLEID = 10;
  protected static final int GROUPID = 11;
  protected static final int LANGUAGE = 12;
  protected static final int SOURCELANG = 13;
  protected static final int CREATEDBY = 14;
  protected static final int CREATIONDATE = 15;
  protected static final int LASTUPDATEDBY = 16;
  protected static final int LASTUPDATEDATE = 17;
  protected static final int LASTUPDATELOGIN = 18;
  protected static final int REQUESTID = 19;
  protected static final int PROGRAMAPPLICATIONID = 20;
  protected static final int PROGRAMID = 21;
  protected static final int PROGRAMUPDATEDATE = 22;
  protected static final int ATTRIBUTECATEGORY = 23;
  protected static final int ATTRIBUTE1 = 24;
  protected static final int ATTRIBUTE2 = 25;
  protected static final int ATTRIBUTE3 = 26;
  protected static final int ATTRIBUTE4 = 27;
  protected static final int ATTRIBUTE5 = 28;
  protected static final int ATTRIBUTE6 = 29;
  protected static final int ATTRIBUTE7 = 30;
  protected static final int ATTRIBUTE8 = 31;
  protected static final int ATTRIBUTE9 = 32;
  protected static final int ATTRIBUTE10 = 33;
  protected static final int ATTRIBUTE11 = 34;
  protected static final int ATTRIBUTE12 = 35;
  protected static final int ATTRIBUTE13 = 36;
  protected static final int ATTRIBUTE14 = 37;
  protected static final int ATTRIBUTE15 = 38;
  protected static final int ATTRIBUTE16 = 39;
  protected static final int ATTRIBUTE17 = 40;
  protected static final int ATTRIBUTE18 = 41;
  protected static final int ATTRIBUTE19 = 42;
  protected static final int ATTRIBUTE20 = 43;
  protected static final int ENTITYID = 44;
  protected static final int ENTITYTYPE = 45;






















  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODSCSFdbkHdrStgEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxcrm.scs.fdk.schema.server.ODSCSFdbkHdrStgEO");
    }
    return mDefinitionObject;
  }























  /**
   * 
   * Gets the attribute value for FdbkId, using the alias name FdbkId
   */
  public Number getFdbkId()
  {
    return (Number)getAttributeInternal(FDBKID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for FdbkId
   */
  public void setFdbkId(Number value)
  {
    setAttributeInternal(FDBKID, value);
  }

  /**
   * 
   * Gets the attribute value for CustomerAccountId, using the alias name CustomerAccountId
   */
  public Number getCustomerAccountId()
  {
    return (Number)getAttributeInternal(CUSTOMERACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CustomerAccountId
   */
  public void setCustomerAccountId(Number value)
  {
    setAttributeInternal(CUSTOMERACCOUNTID, value);
  }

  /**
   * 
   * Gets the attribute value for AddressId, using the alias name AddressId
   */
  public Number getAddressId()
  {
    return (Number)getAttributeInternal(ADDRESSID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AddressId
   */
  public void setAddressId(Number value)
  {
    setAttributeInternal(ADDRESSID, value);
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
   * Gets the attribute value for PartyId, using the alias name PartyId
   */
  public Number getPartyId()
  {
    return (Number)getAttributeInternal(PARTYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PartyId
   */
  public void setPartyId(Number value)
  {
    setAttributeInternal(PARTYID, value);
  }

  /**
   * 
   * Gets the attribute value for MassApplyFlag, using the alias name MassApplyFlag
   */
  public String getMassApplyFlag()
  {
    return (String)getAttributeInternal(MASSAPPLYFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for MassApplyFlag
   */
  public void setMassApplyFlag(String value)
  {
    setAttributeInternal(MASSAPPLYFLAG, value);
  }







  /**
   * 
   * Gets the attribute value for ContactId, using the alias name ContactId
   */
  public Number getContactId()
  {
    return (Number)getAttributeInternal(CONTACTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContactId
   */
  public void setContactId(Number value)
  {
    setAttributeInternal(CONTACTID, value);
  }



  /**
   * 
   * Gets the attribute value for LastUpdatedEmp, using the alias name LastUpdatedEmp
   */
  public String getLastUpdatedEmp()
  {
    return (String)getAttributeInternal(LASTUPDATEDEMP);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdatedEmp
   */
  public void setLastUpdatedEmp(String value)
  {
    setAttributeInternal(LASTUPDATEDEMP, value);
  }













  /**
   * 
   * Gets the attribute value for SalesTerritoryId, using the alias name SalesTerritoryId
   */
  public String getSalesTerritoryId()
  {
    return (String)getAttributeInternal(SALESTERRITORYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesTerritoryId
   */
  public void setSalesTerritoryId(String value)
  {
    setAttributeInternal(SALESTERRITORYID, value);
  }

  /**
   * 
   * Gets the attribute value for ResourceId, using the alias name ResourceId
   */
  public Number getResourceId()
  {
    return (Number)getAttributeInternal(RESOURCEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResourceId
   */
  public void setResourceId(Number value)
  {
    setAttributeInternal(RESOURCEID, value);
  }

  /**
   * 
   * Gets the attribute value for RoleId, using the alias name RoleId
   */
  public Number getRoleId()
  {
    return (Number)getAttributeInternal(ROLEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for RoleId
   */
  public void setRoleId(Number value)
  {
    setAttributeInternal(ROLEID, value);
  }

  /**
   * 
   * Gets the attribute value for GroupId, using the alias name GroupId
   */
  public Number getGroupId()
  {
    return (Number)getAttributeInternal(GROUPID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for GroupId
   */
  public void setGroupId(Number value)
  {
    setAttributeInternal(GROUPID, value);
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
   * Gets the attribute value for RequestId, using the alias name RequestId
   */
  public Number getRequestId()
  {
    return (Number)getAttributeInternal(REQUESTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for RequestId
   */
  public void setRequestId(Number value)
  {
    setAttributeInternal(REQUESTID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramApplicationId, using the alias name ProgramApplicationId
   */
  public Number getProgramApplicationId()
  {
    return (Number)getAttributeInternal(PROGRAMAPPLICATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramApplicationId
   */
  public void setProgramApplicationId(Number value)
  {
    setAttributeInternal(PROGRAMAPPLICATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramId, using the alias name ProgramId
   */
  public Number getProgramId()
  {
    return (Number)getAttributeInternal(PROGRAMID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramId
   */
  public void setProgramId(Number value)
  {
    setAttributeInternal(PROGRAMID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramUpdateDate, using the alias name ProgramUpdateDate
   */
  public Date getProgramUpdateDate()
  {
    return (Date)getAttributeInternal(PROGRAMUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramUpdateDate
   */
  public void setProgramUpdateDate(Date value)
  {
    setAttributeInternal(PROGRAMUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for AttributeCategory, using the alias name AttributeCategory
   */
  public String getAttributeCategory()
  {
    return (String)getAttributeInternal(ATTRIBUTECATEGORY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AttributeCategory
   */
  public void setAttributeCategory(String value)
  {
    setAttributeInternal(ATTRIBUTECATEGORY, value);
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
   * Gets the attribute value for Attribute6, using the alias name Attribute6
   */
  public String getAttribute6()
  {
    return (String)getAttributeInternal(ATTRIBUTE6);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute6
   */
  public void setAttribute6(String value)
  {
    setAttributeInternal(ATTRIBUTE6, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute7, using the alias name Attribute7
   */
  public String getAttribute7()
  {
    return (String)getAttributeInternal(ATTRIBUTE7);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute7
   */
  public void setAttribute7(String value)
  {
    setAttributeInternal(ATTRIBUTE7, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute8, using the alias name Attribute8
   */
  public String getAttribute8()
  {
    return (String)getAttributeInternal(ATTRIBUTE8);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute8
   */
  public void setAttribute8(String value)
  {
    setAttributeInternal(ATTRIBUTE8, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute9, using the alias name Attribute9
   */
  public String getAttribute9()
  {
    return (String)getAttributeInternal(ATTRIBUTE9);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute9
   */
  public void setAttribute9(String value)
  {
    setAttributeInternal(ATTRIBUTE9, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute10, using the alias name Attribute10
   */
  public String getAttribute10()
  {
    return (String)getAttributeInternal(ATTRIBUTE10);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute10
   */
  public void setAttribute10(String value)
  {
    setAttributeInternal(ATTRIBUTE10, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute11, using the alias name Attribute11
   */
  public String getAttribute11()
  {
    return (String)getAttributeInternal(ATTRIBUTE11);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute11
   */
  public void setAttribute11(String value)
  {
    setAttributeInternal(ATTRIBUTE11, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute12, using the alias name Attribute12
   */
  public String getAttribute12()
  {
    return (String)getAttributeInternal(ATTRIBUTE12);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute12
   */
  public void setAttribute12(String value)
  {
    setAttributeInternal(ATTRIBUTE12, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute13, using the alias name Attribute13
   */
  public String getAttribute13()
  {
    return (String)getAttributeInternal(ATTRIBUTE13);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute13
   */
  public void setAttribute13(String value)
  {
    setAttributeInternal(ATTRIBUTE13, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute14, using the alias name Attribute14
   */
  public String getAttribute14()
  {
    return (String)getAttributeInternal(ATTRIBUTE14);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute14
   */
  public void setAttribute14(String value)
  {
    setAttributeInternal(ATTRIBUTE14, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute15, using the alias name Attribute15
   */
  public String getAttribute15()
  {
    return (String)getAttributeInternal(ATTRIBUTE15);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute15
   */
  public void setAttribute15(String value)
  {
    setAttributeInternal(ATTRIBUTE15, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute16, using the alias name Attribute16
   */
  public String getAttribute16()
  {
    return (String)getAttributeInternal(ATTRIBUTE16);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute16
   */
  public void setAttribute16(String value)
  {
    setAttributeInternal(ATTRIBUTE16, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute17, using the alias name Attribute17
   */
  public String getAttribute17()
  {
    return (String)getAttributeInternal(ATTRIBUTE17);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute17
   */
  public void setAttribute17(String value)
  {
    setAttributeInternal(ATTRIBUTE17, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute18, using the alias name Attribute18
   */
  public String getAttribute18()
  {
    return (String)getAttributeInternal(ATTRIBUTE18);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute18
   */
  public void setAttribute18(String value)
  {
    setAttributeInternal(ATTRIBUTE18, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute19, using the alias name Attribute19
   */
  public String getAttribute19()
  {
    return (String)getAttributeInternal(ATTRIBUTE19);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute19
   */
  public void setAttribute19(String value)
  {
    setAttributeInternal(ATTRIBUTE19, value);
  }

  /**
   * 
   * Gets the attribute value for Attribute20, using the alias name Attribute20
   */
  public String getAttribute20()
  {
    return (String)getAttributeInternal(ATTRIBUTE20);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Attribute20
   */
  public void setAttribute20(String value)
  {
    setAttributeInternal(ATTRIBUTE20, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case FDBKID:
        return getFdbkId();
      case CUSTOMERACCOUNTID:
        return getCustomerAccountId();
      case ADDRESSID:
        return getAddressId();
      case PARTYSITEID:
        return getPartySiteId();
      case PARTYID:
        return getPartyId();
      case MASSAPPLYFLAG:
        return getMassApplyFlag();
      case CONTACTID:
        return getContactId();
      case LASTUPDATEDEMP:
        return getLastUpdatedEmp();
      case SALESTERRITORYID:
        return getSalesTerritoryId();
      case RESOURCEID:
        return getResourceId();
      case ROLEID:
        return getRoleId();
      case GROUPID:
        return getGroupId();
      case LANGUAGE:
        return getLanguage();
      case SOURCELANG:
        return getSourceLang();
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
      case REQUESTID:
        return getRequestId();
      case PROGRAMAPPLICATIONID:
        return getProgramApplicationId();
      case PROGRAMID:
        return getProgramId();
      case PROGRAMUPDATEDATE:
        return getProgramUpdateDate();
      case ATTRIBUTECATEGORY:
        return getAttributeCategory();
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
      case ATTRIBUTE6:
        return getAttribute6();
      case ATTRIBUTE7:
        return getAttribute7();
      case ATTRIBUTE8:
        return getAttribute8();
      case ATTRIBUTE9:
        return getAttribute9();
      case ATTRIBUTE10:
        return getAttribute10();
      case ATTRIBUTE11:
        return getAttribute11();
      case ATTRIBUTE12:
        return getAttribute12();
      case ATTRIBUTE13:
        return getAttribute13();
      case ATTRIBUTE14:
        return getAttribute14();
      case ATTRIBUTE15:
        return getAttribute15();
      case ATTRIBUTE16:
        return getAttribute16();
      case ATTRIBUTE17:
        return getAttribute17();
      case ATTRIBUTE18:
        return getAttribute18();
      case ATTRIBUTE19:
        return getAttribute19();
      case ATTRIBUTE20:
        return getAttribute20();
      case ENTITYID:
        return getEntityId();
      case ENTITYTYPE:
        return getEntityType();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case FDBKID:
        setFdbkId((Number)value);
        return;
      case CUSTOMERACCOUNTID:
        setCustomerAccountId((Number)value);
        return;
      case ADDRESSID:
        setAddressId((Number)value);
        return;
      case PARTYSITEID:
        setPartySiteId((Number)value);
        return;
      case PARTYID:
        setPartyId((Number)value);
        return;
      case MASSAPPLYFLAG:
        setMassApplyFlag((String)value);
        return;
      case CONTACTID:
        setContactId((Number)value);
        return;
      case LASTUPDATEDEMP:
        setLastUpdatedEmp((String)value);
        return;
      case SALESTERRITORYID:
        setSalesTerritoryId((String)value);
        return;
      case RESOURCEID:
        setResourceId((Number)value);
        return;
      case ROLEID:
        setRoleId((Number)value);
        return;
      case GROUPID:
        setGroupId((Number)value);
        return;
      case LANGUAGE:
        setLanguage((String)value);
        return;
      case SOURCELANG:
        setSourceLang((String)value);
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
      case REQUESTID:
        setRequestId((Number)value);
        return;
      case PROGRAMAPPLICATIONID:
        setProgramApplicationId((Number)value);
        return;
      case PROGRAMID:
        setProgramId((Number)value);
        return;
      case PROGRAMUPDATEDATE:
        setProgramUpdateDate((Date)value);
        return;
      case ATTRIBUTECATEGORY:
        setAttributeCategory((String)value);
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
      case ATTRIBUTE6:
        setAttribute6((String)value);
        return;
      case ATTRIBUTE7:
        setAttribute7((String)value);
        return;
      case ATTRIBUTE8:
        setAttribute8((String)value);
        return;
      case ATTRIBUTE9:
        setAttribute9((String)value);
        return;
      case ATTRIBUTE10:
        setAttribute10((String)value);
        return;
      case ATTRIBUTE11:
        setAttribute11((String)value);
        return;
      case ATTRIBUTE12:
        setAttribute12((String)value);
        return;
      case ATTRIBUTE13:
        setAttribute13((String)value);
        return;
      case ATTRIBUTE14:
        setAttribute14((String)value);
        return;
      case ATTRIBUTE15:
        setAttribute15((String)value);
        return;
      case ATTRIBUTE16:
        setAttribute16((String)value);
        return;
      case ATTRIBUTE17:
        setAttribute17((String)value);
        return;
      case ATTRIBUTE18:
        setAttribute18((String)value);
        return;
      case ATTRIBUTE19:
        setAttribute19((String)value);
        return;
      case ATTRIBUTE20:
        setAttribute20((String)value);
        return;
      case ENTITYID:
        setEntityId((Number)value);
        return;
      case ENTITYTYPE:
        setEntityType((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }


  /**
   * 
   * Add attribute defaulting logic in this method.
   */
  public void create(AttributeList attributeList)
  {
    super.create(attributeList);
    
    OADBTransaction transaction = getOADBTransaction();
    Number vFdkfmId = transaction.getSequenceValue("XXCS_FDBK_ID_S");
    setFdbkId(vFdkfmId);
  
    
  }


  /**
   * 
   * Gets the attribute value for EntityId, using the alias name EntityId
   */
  public Number getEntityId()
  {
    return (Number)getAttributeInternal(ENTITYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for EntityId
   */
  public void setEntityId(Number value)
  {
    setAttributeInternal(ENTITYID, value);
  }

  /**
   * 
   * Gets the attribute value for EntityType, using the alias name EntityType
   */
  public String getEntityType()
  {
    return (String)getAttributeInternal(ENTITYTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for EntityType
   */
  public void setEntityType(String value)
  {
    setAttributeInternal(ENTITYTYPE, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number fdbkId)
  {
    return new Key(new Object[] {fdbkId});
  }





















}