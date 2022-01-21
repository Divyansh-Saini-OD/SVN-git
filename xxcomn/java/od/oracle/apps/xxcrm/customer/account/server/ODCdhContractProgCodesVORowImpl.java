package od.oracle.apps.xxcrm.customer.account.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODCdhContractProgCodesVORowImpl extends OAViewRowImpl
{


  protected static final int PROGCODEID = 0;
  protected static final int CONTRACTTEMPLATEID = 1;
  protected static final int PROGRAMCODE = 2;
  protected static final int DISCOUNTRATE = 3;
  protected static final int EXCLUDEUNIVPRICING = 4;
  protected static final int LASTUPDATEDBY = 5;
  protected static final int CREATIONDATE = 6;
  protected static final int LASTUPDATELOGIN = 7;
  protected static final int CREATEDBY = 8;
  protected static final int LASTUPDATEDATE = 9;
  protected static final int PCDELETE = 10;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODCdhContractProgCodesVORowImpl()
  {
  }

  /**
   * 
   * Gets ODCdhContractProgCodesEO entity object.
   */
  public od.oracle.apps.xxcrm.customer.account.schema.server.ODCdhContractProgCodesEOImpl getODCdhContractProgCodesEO()
  {
    return (od.oracle.apps.xxcrm.customer.account.schema.server.ODCdhContractProgCodesEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for CONTRACT_TEMPLATE_ID using the alias name ContractTemplateId
   */
  public Number getContractTemplateId()
  {
    return (Number)getAttributeInternal(CONTRACTTEMPLATEID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTRACT_TEMPLATE_ID using the alias name ContractTemplateId
   */
  public void setContractTemplateId(Number value)
  {
    setAttributeInternal(CONTRACTTEMPLATEID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_CODE using the alias name ProgramCode
   */
  public String getProgramCode()
  {
    return (String)getAttributeInternal(PROGRAMCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_CODE using the alias name ProgramCode
   */
  public void setProgramCode(String value)
  {
    setAttributeInternal(PROGRAMCODE, value);
  }

  /**
   * 
   * Gets the attribute value for DISCOUNT_RATE using the alias name DiscountRate
   */
  public Number getDiscountRate()
  {
    return (Number)getAttributeInternal(DISCOUNTRATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DISCOUNT_RATE using the alias name DiscountRate
   */
  public void setDiscountRate(Number value)
  {
    setAttributeInternal(DISCOUNTRATE, value);
  }

  /**
   * 
   * Gets the attribute value for EXCLUDE_UNIV_PRICING using the alias name ExcludeUnivPricing
   */
  public String getExcludeUnivPricing()
  {
    return (String)getAttributeInternal(EXCLUDEUNIVPRICING);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EXCLUDE_UNIV_PRICING using the alias name ExcludeUnivPricing
   */
  public void setExcludeUnivPricing(String value)
  {
    setAttributeInternal(EXCLUDEUNIVPRICING, value);
  }



  /**
   * 
   * Gets the attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CREATION_DATE using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CREATION_DATE using the alias name CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }

  /**
   * 
   * Gets the attribute value for CREATED_BY using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CREATED_BY using the alias name CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PROGCODEID:
        return getProgCodeId();
      case CONTRACTTEMPLATEID:
        return getContractTemplateId();
      case PROGRAMCODE:
        return getProgramCode();
      case DISCOUNTRATE:
        return getDiscountRate();
      case EXCLUDEUNIVPRICING:
        return getExcludeUnivPricing();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case CREATIONDATE:
        return getCreationDate();
      case LASTUPDATELOGIN:
        return getLastUpdateLogin();
      case CREATEDBY:
        return getCreatedBy();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case PCDELETE:
        return getPCDelete();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PROGCODEID:
        setProgCodeId((Number)value);
        return;
      case CONTRACTTEMPLATEID:
        setContractTemplateId((Number)value);
        return;
      case PROGRAMCODE:
        setProgramCode((String)value);
        return;
      case DISCOUNTRATE:
        setDiscountRate((Number)value);
        return;
      case EXCLUDEUNIVPRICING:
        setExcludeUnivPricing((String)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((Number)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case LASTUPDATELOGIN:
        setLastUpdateLogin((Number)value);
        return;
      case CREATEDBY:
        setCreatedBy((Number)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case PCDELETE:
        setPCDelete((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PCDelete
   */
  public String getPCDelete()
  {
    return (String)getAttributeInternal(PCDELETE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PCDelete
   */
  public void setPCDelete(String value)
  {
    setAttributeInternal(PCDELETE, value);
  }

  /**
   * 
   * Gets the attribute value for PROG_CODE_ID using the alias name ProgCodeId
   */
  public Number getProgCodeId()
  {
    return (Number)getAttributeInternal(PROGCODEID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROG_CODE_ID using the alias name ProgCodeId
   */
  public void setProgCodeId(Number value)
  {
    setAttributeInternal(PROGCODEID, value);
  }
}
