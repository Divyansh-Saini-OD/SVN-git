package od.oracle.apps.xxcrm.errorhandler.schema;
import oracle.apps.fnd.framework.server.OAEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.RowID;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ErrorResolutionEOImpl extends OAEntityImpl 
{
  protected static final int RESOLUTIONID = 0;
  protected static final int APPLICATIONID = 1;
  protected static final int LANGUAGECODE = 2;
  protected static final int MESSAGENAME = 3;
  protected static final int RESOLUTIONSTEP1 = 4;
  protected static final int RESOLUTIONSTEP2 = 5;
  protected static final int RESOLUTIONSTEP3 = 6;
  protected static final int RESOLUTIONSTEP4 = 7;
  protected static final int RESOLUTIONSTEP5 = 8;
  protected static final int RESOLUTIONSTEP6 = 9;
  protected static final int RESOLUTIONSTEP7 = 10;
  protected static final int RESOLUTIONSTEP8 = 11;
  protected static final int RESOLUTIONSTEP9 = 12;
  protected static final int RESOLUTIONSTEP10 = 13;
  protected static final int RESOLUTIONSTEP11 = 14;
  protected static final int RESOLUTIONSTEP12 = 15;
  protected static final int RESOLUTIONSTEP13 = 16;
  protected static final int RESOLUTIONSTEP14 = 17;
  protected static final int RESOLUTIONSTEP15 = 18;
  protected static final int STARTDATE = 19;
  protected static final int ENDDATE = 20;
  protected static final int CREATEDBY = 21;
  protected static final int CREATIONDATE = 22;
  protected static final int LASTUPDATEDATE = 23;
  protected static final int LASTUPDATEDBY = 24;
  protected static final int LASTUPDATELOGIN = 25;
  protected static final int EMAIL = 26;
  protected static final int ROWID = 27;


  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ErrorResolutionEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxcrm.errorhandler.schema.ErrorResolutionEO");
    }
    return mDefinitionObject;
  }



  /**
   * 
   * Gets the attribute value for ResolutionId, using the alias name ResolutionId
   */
  public Number getResolutionId()
  {
    return (Number)getAttributeInternal(RESOLUTIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionId
   */
  public void setResolutionId(Number value)
  {
    setAttributeInternal(RESOLUTIONID, value);
  }

  /**
   * 
   * Gets the attribute value for ApplicationId, using the alias name ApplicationId
   */
  public Number getApplicationId()
  {
    return (Number)getAttributeInternal(APPLICATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApplicationId
   */
  public void setApplicationId(Number value)
  {
    setAttributeInternal(APPLICATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for LanguageCode, using the alias name LanguageCode
   */
  public String getLanguageCode()
  {
    return (String)getAttributeInternal(LANGUAGECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LanguageCode
   */
  public void setLanguageCode(String value)
  {
    setAttributeInternal(LANGUAGECODE, value);
  }

  /**
   * 
   * Gets the attribute value for MessageName, using the alias name MessageName
   */
  public String getMessageName()
  {
    return (String)getAttributeInternal(MESSAGENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for MessageName
   */
  public void setMessageName(String value)
  {
    setAttributeInternal(MESSAGENAME, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep1, using the alias name ResolutionStep1
   */
  public String getResolutionStep1()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep1
   */
  public void setResolutionStep1(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP1, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep2, using the alias name ResolutionStep2
   */
  public String getResolutionStep2()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep2
   */
  public void setResolutionStep2(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP2, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep3, using the alias name ResolutionStep3
   */
  public String getResolutionStep3()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP3);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep3
   */
  public void setResolutionStep3(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP3, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep4, using the alias name ResolutionStep4
   */
  public String getResolutionStep4()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP4);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep4
   */
  public void setResolutionStep4(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP4, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep5, using the alias name ResolutionStep5
   */
  public String getResolutionStep5()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP5);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep5
   */
  public void setResolutionStep5(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP5, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep6, using the alias name ResolutionStep6
   */
  public String getResolutionStep6()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP6);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep6
   */
  public void setResolutionStep6(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP6, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep7, using the alias name ResolutionStep7
   */
  public String getResolutionStep7()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP7);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep7
   */
  public void setResolutionStep7(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP7, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep8, using the alias name ResolutionStep8
   */
  public String getResolutionStep8()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP8);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep8
   */
  public void setResolutionStep8(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP8, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep9, using the alias name ResolutionStep9
   */
  public String getResolutionStep9()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP9);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep9
   */
  public void setResolutionStep9(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP9, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep10, using the alias name ResolutionStep10
   */
  public String getResolutionStep10()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP10);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep10
   */
  public void setResolutionStep10(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP10, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep11, using the alias name ResolutionStep11
   */
  public String getResolutionStep11()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP11);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep11
   */
  public void setResolutionStep11(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP11, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep12, using the alias name ResolutionStep12
   */
  public String getResolutionStep12()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP12);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep12
   */
  public void setResolutionStep12(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP12, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep13, using the alias name ResolutionStep13
   */
  public String getResolutionStep13()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP13);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep13
   */
  public void setResolutionStep13(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP13, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep14, using the alias name ResolutionStep14
   */
  public String getResolutionStep14()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP14);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep14
   */
  public void setResolutionStep14(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP14, value);
  }

  /**
   * 
   * Gets the attribute value for ResolutionStep15, using the alias name ResolutionStep15
   */
  public String getResolutionStep15()
  {
    return (String)getAttributeInternal(RESOLUTIONSTEP15);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ResolutionStep15
   */
  public void setResolutionStep15(String value)
  {
    setAttributeInternal(RESOLUTIONSTEP15, value);
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
      case RESOLUTIONID:
        return getResolutionId();
      case APPLICATIONID:
        return getApplicationId();
      case LANGUAGECODE:
        return getLanguageCode();
      case MESSAGENAME:
        return getMessageName();
      case RESOLUTIONSTEP1:
        return getResolutionStep1();
      case RESOLUTIONSTEP2:
        return getResolutionStep2();
      case RESOLUTIONSTEP3:
        return getResolutionStep3();
      case RESOLUTIONSTEP4:
        return getResolutionStep4();
      case RESOLUTIONSTEP5:
        return getResolutionStep5();
      case RESOLUTIONSTEP6:
        return getResolutionStep6();
      case RESOLUTIONSTEP7:
        return getResolutionStep7();
      case RESOLUTIONSTEP8:
        return getResolutionStep8();
      case RESOLUTIONSTEP9:
        return getResolutionStep9();
      case RESOLUTIONSTEP10:
        return getResolutionStep10();
      case RESOLUTIONSTEP11:
        return getResolutionStep11();
      case RESOLUTIONSTEP12:
        return getResolutionStep12();
      case RESOLUTIONSTEP13:
        return getResolutionStep13();
      case RESOLUTIONSTEP14:
        return getResolutionStep14();
      case RESOLUTIONSTEP15:
        return getResolutionStep15();
      case STARTDATE:
        return getStartDate();
      case ENDDATE:
        return getEndDate();
      case CREATEDBY:
        return getCreatedBy();
      case CREATIONDATE:
        return getCreationDate();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case LASTUPDATELOGIN:
        return getLastUpdateLogin();
      case EMAIL:
        return getEmail();
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
      case RESOLUTIONID:
        setResolutionId((Number)value);
        return;
      case APPLICATIONID:
        setApplicationId((Number)value);
        return;
      case LANGUAGECODE:
        setLanguageCode((String)value);
        return;
      case MESSAGENAME:
        setMessageName((String)value);
        return;
      case RESOLUTIONSTEP1:
        setResolutionStep1((String)value);
        return;
      case RESOLUTIONSTEP2:
        setResolutionStep2((String)value);
        return;
      case RESOLUTIONSTEP3:
        setResolutionStep3((String)value);
        return;
      case RESOLUTIONSTEP4:
        setResolutionStep4((String)value);
        return;
      case RESOLUTIONSTEP5:
        setResolutionStep5((String)value);
        return;
      case RESOLUTIONSTEP6:
        setResolutionStep6((String)value);
        return;
      case RESOLUTIONSTEP7:
        setResolutionStep7((String)value);
        return;
      case RESOLUTIONSTEP8:
        setResolutionStep8((String)value);
        return;
      case RESOLUTIONSTEP9:
        setResolutionStep9((String)value);
        return;
      case RESOLUTIONSTEP10:
        setResolutionStep10((String)value);
        return;
      case RESOLUTIONSTEP11:
        setResolutionStep11((String)value);
        return;
      case RESOLUTIONSTEP12:
        setResolutionStep12((String)value);
        return;
      case RESOLUTIONSTEP13:
        setResolutionStep13((String)value);
        return;
      case RESOLUTIONSTEP14:
        setResolutionStep14((String)value);
        return;
      case RESOLUTIONSTEP15:
        setResolutionStep15((String)value);
        return;
      case STARTDATE:
        setStartDate((Date)value);
        return;
      case ENDDATE:
        setEndDate((Date)value);
        return;
      case CREATEDBY:
        setCreatedBy((Number)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((Number)value);
        return;
      case LASTUPDATELOGIN:
        setLastUpdateLogin((Number)value);
        return;
      case EMAIL:
        setEmail((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for Email, using the alias name Email
   */
  public String getEmail()
  {
    return (String)getAttributeInternal(EMAIL);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Email
   */
  public void setEmail(String value)
  {
    setAttributeInternal(EMAIL, value);
  }
}