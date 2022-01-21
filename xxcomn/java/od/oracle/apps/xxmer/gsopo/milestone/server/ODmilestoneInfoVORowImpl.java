package od.oracle.apps.xxmer.gsopo.milestone.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODmilestoneInfoVORowImpl extends OAViewRowImpl 
{










  protected static final int POMILESTONEID = 0;
  protected static final int POHEADERID = 1;
  protected static final int MILESTONENAME = 2;
  protected static final int MILESTONEDATE = 3;
  protected static final int MILESTONEATTACHMENT = 4;
  protected static final int REMARKS = 5;
  protected static final int ATTRIBUTE1 = 6;
  protected static final int ATTRIBUTE2 = 7;
  protected static final int ATTRIBUTE3 = 8;
  protected static final int ATTRIBUTE4 = 9;
  protected static final int ATTRIBUTE5 = 10;
  protected static final int ATTRIBUTE6 = 11;
  protected static final int ATTRIBUTE7 = 12;
  protected static final int ATTRIBUTE8 = 13;
  protected static final int ATTRIBUTE9 = 14;
  protected static final int ATTRIBUTE10 = 15;
  protected static final int CREATIONDATE = 16;
  protected static final int CREATEDBY = 17;
  protected static final int LASTUPDATEDATE = 18;
  protected static final int LASTUPDATEDBY = 19;
  protected static final int LASTUPDATELOGIN = 20;
  protected static final int MILESTONE_NAME_B = 21;
  protected static final int MILESTONE_DATE_B = 22;
  protected static final int MILESTONE_REMARKS_B = 23;
  protected static final int MILESTONE_UPDATE_B = 24;
  protected static final int UPDATESWITCHER = 25;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODmilestoneInfoVORowImpl()
  {
  }










































  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case POMILESTONEID:
        return getPoMilestoneId();
      case POHEADERID:
        return getPoHeaderId();
      case MILESTONENAME:
        return getMilestoneName();
      case MILESTONEDATE:
        return getMilestoneDate();
      case MILESTONEATTACHMENT:
        return getMilestoneAttachment();
      case REMARKS:
        return getRemarks();
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
      case CREATIONDATE:
        return getCreationDate();
      case CREATEDBY:
        return getCreatedBy();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case LASTUPDATELOGIN:
        return getLastUpdateLogin();
      case MILESTONE_NAME_B:
        return getmilestone_name_b();
      case MILESTONE_DATE_B:
        return getmilestone_date_b();
      case MILESTONE_REMARKS_B:
        return getmilestone_remarks_b();
      case MILESTONE_UPDATE_B:
        return getmilestone_update_b();
      case UPDATESWITCHER:
        return getUpdateSwitcher();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case POMILESTONEID:
        setPoMilestoneId((Number)value);
        return;
      case POHEADERID:
        setPoHeaderId((Number)value);
        return;
      case MILESTONENAME:
        setMilestoneName((String)value);
        return;
      case MILESTONEDATE:
        setMilestoneDate((Date)value);
        return;
      case MILESTONEATTACHMENT:
        setMilestoneAttachment((String)value);
        return;
      case REMARKS:
        setRemarks((String)value);
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
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case CREATEDBY:
        setCreatedBy((String)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((String)value);
        return;
      case LASTUPDATELOGIN:
        setLastUpdateLogin((Number)value);
        return;
      case MILESTONE_NAME_B:
        setmilestone_name_b((Boolean)value);
        return;
      case MILESTONE_DATE_B:
        setmilestone_date_b((Boolean)value);
        return;
      case MILESTONE_REMARKS_B:
        setmilestone_remarks_b((Boolean)value);
        return;
      case MILESTONE_UPDATE_B:
        setmilestone_update_b((Boolean)value);
        return;
      case UPDATESWITCHER:
        setUpdateSwitcher((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets ODMilestoneInfoEO entity object.
   */
  public od.oracle.apps.xxmer.gsopo.milestone.schema.server.ODMilestoneInfoEOImpl getODMilestoneInfoEO()
  {
    return (od.oracle.apps.xxmer.gsopo.milestone.schema.server.ODMilestoneInfoEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PoMilestoneId
   */
  public Number getPoMilestoneId()
  {
    return (Number)getAttributeInternal(POMILESTONEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PoMilestoneId
   */
  public void setPoMilestoneId(Number value)
  {
    setAttributeInternal(POMILESTONEID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PoHeaderId
   */
  public Number getPoHeaderId()
  {
    return (Number)getAttributeInternal(POHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PoHeaderId
   */
  public void setPoHeaderId(Number value)
  {
    setAttributeInternal(POHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MilestoneName
   */
  public String getMilestoneName()
  {
    return (String)getAttributeInternal(MILESTONENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MilestoneName
   */
  public void setMilestoneName(String value)
  {
    setAttributeInternal(MILESTONENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MilestoneDate
   */
  public Date getMilestoneDate()
  {
    return (Date)getAttributeInternal(MILESTONEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MilestoneDate
   */
  public void setMilestoneDate(Date value)
  {
    setAttributeInternal(MILESTONEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MilestoneAttachment
   */
  public String getMilestoneAttachment()
  {
    return (String)getAttributeInternal(MILESTONEATTACHMENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MilestoneAttachment
   */
  public void setMilestoneAttachment(String value)
  {
    setAttributeInternal(MILESTONEATTACHMENT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Remarks
   */
  public String getRemarks()
  {
    return (String)getAttributeInternal(REMARKS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Remarks
   */
  public void setRemarks(String value)
  {
    setAttributeInternal(REMARKS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute1
   */
  public String getAttribute1()
  {
    return (String)getAttributeInternal(ATTRIBUTE1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute1
   */
  public void setAttribute1(String value)
  {
    setAttributeInternal(ATTRIBUTE1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute2
   */
  public String getAttribute2()
  {
    return (String)getAttributeInternal(ATTRIBUTE2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute2
   */
  public void setAttribute2(String value)
  {
    setAttributeInternal(ATTRIBUTE2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute3
   */
  public String getAttribute3()
  {
    return (String)getAttributeInternal(ATTRIBUTE3);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute3
   */
  public void setAttribute3(String value)
  {
    setAttributeInternal(ATTRIBUTE3, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute4
   */
  public String getAttribute4()
  {
    return (String)getAttributeInternal(ATTRIBUTE4);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute4
   */
  public void setAttribute4(String value)
  {
    setAttributeInternal(ATTRIBUTE4, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute5
   */
  public String getAttribute5()
  {
    return (String)getAttributeInternal(ATTRIBUTE5);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute5
   */
  public void setAttribute5(String value)
  {
    setAttributeInternal(ATTRIBUTE5, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute6
   */
  public String getAttribute6()
  {
    return (String)getAttributeInternal(ATTRIBUTE6);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute6
   */
  public void setAttribute6(String value)
  {
    setAttributeInternal(ATTRIBUTE6, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute7
   */
  public String getAttribute7()
  {
    return (String)getAttributeInternal(ATTRIBUTE7);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute7
   */
  public void setAttribute7(String value)
  {
    setAttributeInternal(ATTRIBUTE7, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute8
   */
  public String getAttribute8()
  {
    return (String)getAttributeInternal(ATTRIBUTE8);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute8
   */
  public void setAttribute8(String value)
  {
    setAttributeInternal(ATTRIBUTE8, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute9
   */
  public String getAttribute9()
  {
    return (String)getAttributeInternal(ATTRIBUTE9);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute9
   */
  public void setAttribute9(String value)
  {
    setAttributeInternal(ATTRIBUTE9, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute10
   */
  public String getAttribute10()
  {
    return (String)getAttributeInternal(ATTRIBUTE10);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute10
   */
  public void setAttribute10(String value)
  {
    setAttributeInternal(ATTRIBUTE10, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CreatedBy
   */
  public String getCreatedBy()
  {
    return (String)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CreatedBy
   */
  public void setCreatedBy(String value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LastUpdatedBy
   */
  public String getLastUpdatedBy()
  {
    return (String)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LastUpdatedBy
   */
  public void setLastUpdatedBy(String value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute milestone_name_b
   */
  public Boolean getmilestone_name_b()
  {
    return (Boolean)getAttributeInternal(MILESTONE_NAME_B);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute milestone_name_b
   */
  public void setmilestone_name_b(Boolean value)
  {
    setAttributeInternal(MILESTONE_NAME_B, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute milestone_date_b
   */
  public Boolean getmilestone_date_b()
  {
    return (Boolean)getAttributeInternal(MILESTONE_DATE_B);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute milestone_date_b
   */
  public void setmilestone_date_b(Boolean value)
  {
    setAttributeInternal(MILESTONE_DATE_B, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute milestone_remarks_b
   */
  public Boolean getmilestone_remarks_b()
  {
    return (Boolean)getAttributeInternal(MILESTONE_REMARKS_B);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute milestone_remarks_b
   */
  public void setmilestone_remarks_b(Boolean value)
  {
    setAttributeInternal(MILESTONE_REMARKS_B, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute milestone_update_b
   */
  public Boolean getmilestone_update_b()
  {
    return (Boolean)getAttributeInternal(MILESTONE_UPDATE_B);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute milestone_update_b
   */
  public void setmilestone_update_b(Boolean value)
  {
    setAttributeInternal(MILESTONE_UPDATE_B, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UpdateSwitcher
   */
  public String getUpdateSwitcher()
  {
    return (String)getAttributeInternal(UPDATESWITCHER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UpdateSwitcher
   */
  public void setUpdateSwitcher(String value)
  {
    setAttributeInternal(UPDATESWITCHER, value);
  }

















































































































































}