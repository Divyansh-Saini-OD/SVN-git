package od.oracle.apps.ar.hz.components.contactpoints.server;
import oracle.apps.ar.hz.components.contactpoints.server.HzPuiContactPointEmailTableVORowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.apps.ar.hz.components.util.server.HzPuiServerUtil;
import oracle.jdbc.OracleTypes;
import oracle.jdbc.OracleCallableStatement;
import java.sql.SQLException;
import oracle.jbo.common.Diagnostic;


//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class xxHzPuiContactPointEmailTableVORowImpl extends HzPuiContactPointEmailTableVORowImpl {


    public static final int MAXATTRCONST = oracle.jbo.server.ViewDefImpl.getMaxAttrConst("oracle.apps.ar.hz.components.contactpoints.server.HzPuiContactPointEmailTableVO");

    /**
     * 
     * This is the default constructor (do not remove)
     */
    public xxHzPuiContactPointEmailTableVORowImpl()
  {
  }

  /**
   * 
   * Gets HzPuiContactPointEmailEO entity object.
   */
  public oracle.apps.ar.hz.components.contactpoints.server.HzPuiContactPointEmailEOImpl getHzPuiContactPointEmailEO()
  {
    return (oracle.apps.ar.hz.components.contactpoints.server.HzPuiContactPointEmailEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for CONTACT_POINT_ID using the alias name ContactPointId
   */
  public Number getContactPointId()
  {
    return super.getContactPointId();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTACT_POINT_ID using the alias name ContactPointId
   */
  public void setContactPointId(Number value)
  {
    super.setContactPointId(value);
  }

  /**
   * 
   * Gets the attribute value for CONTACT_POINT_TYPE using the alias name ContactPointType
   */
  public String getContactPointType()
  {
    return super.getContactPointType();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTACT_POINT_TYPE using the alias name ContactPointType
   */
  public void setContactPointType(String value)
  {
    super.setContactPointType(value);
  }

  /**
   * 
   * Gets the attribute value for STATUS using the alias name Status
   */
  public String getStatus()
  {
    return super.getStatus();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for STATUS using the alias name Status
   */
  public void setStatus(String value)
  {
    super.setStatus(value);
  }

  /**
   * 
   * Gets the attribute value for OWNER_TABLE_NAME using the alias name OwnerTableName
   */
  public String getOwnerTableName()
  {
    return super.getOwnerTableName();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for OWNER_TABLE_NAME using the alias name OwnerTableName
   */
  public void setOwnerTableName(String value)
  {
    super.setOwnerTableName(value);
  }

  /**
   * 
   * Gets the attribute value for OWNER_TABLE_ID using the alias name OwnerTableId
   */
  public Number getOwnerTableId()
  {
    return super.getOwnerTableId();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for OWNER_TABLE_ID using the alias name OwnerTableId
   */
  public void setOwnerTableId(Number value)
  {
    super.setOwnerTableId(value);
  }

  /**
   * 
   * Gets the attribute value for PRIMARY_FLAG using the alias name PrimaryFlag
   */
  public String getPrimaryFlag()
  {
    return super.getPrimaryFlag();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PRIMARY_FLAG using the alias name PrimaryFlag
   */
  public void setPrimaryFlag(String value)
  {
    super.setPrimaryFlag(value);
  }

  /**
   * 
   * Gets the attribute value for EMAIL_FORMAT using the alias name EmailFormat
   */
  public String getEmailFormat()
  {
    return super.getEmailFormat();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EMAIL_FORMAT using the alias name EmailFormat
   */
  public void setEmailFormat(String value)
  {
    super.setEmailFormat(value);
  }

  /**
   * 
   * Gets the attribute value for EMAIL_ADDRESS using the alias name EmailAddress
   */
  public String getEmailAddress()
  {
    return super.getEmailAddress();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EMAIL_ADDRESS using the alias name EmailAddress
   */
  public void setEmailAddress(String value)
  {
    super.setEmailAddress(value);
  }

  /**
   * 
   * Gets the attribute value for CONTACT_POINT_PURPOSE using the alias name ContactPointPurpose
   */
  public String getContactPointPurpose()
  {
    return super.getContactPointPurpose();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONTACT_POINT_PURPOSE using the alias name ContactPointPurpose
   */
  public void setContactPointPurpose(String value)
  {
    super.setContactPointPurpose(value);
  }

  /**
   * 
   * Gets the attribute value for PRIMARY_BY_PURPOSE using the alias name PrimaryByPurpose
   */
  public String getPrimaryByPurpose()
  {
    return super.getPrimaryByPurpose();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PRIMARY_BY_PURPOSE using the alias name PrimaryByPurpose
   */
  public void setPrimaryByPurpose(String value)
  {
    super.setPrimaryByPurpose(value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Usage
   */
  public String getUsage()
  {
    return super.getUsage();
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Usage
   */
  public void setUsage(String value)
  {
    super.setUsage(value);
  }

  /**
   * 
   * Gets the attribute value for CREATION_DATE using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return super.getCreationDate();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CREATION_DATE using the alias name CreationDate
   */
  public void setCreationDate(Date value)
  {
    super.setCreationDate(value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return super.getLastUpdateDate();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    super.setLastUpdateDate(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE_CATEGORY using the alias name AttributeCategory
   */
  public String getAttributeCategory()
  {
    return super.getAttributeCategory();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE_CATEGORY using the alias name AttributeCategory
   */
  public void setAttributeCategory(String value)
  {
    super.setAttributeCategory(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE1 using the alias name Attribute1
   */
  public String getAttribute1()
  {
    return super.getAttribute1();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE1 using the alias name Attribute1
   */
  public void setAttribute1(String value)
  {
    super.setAttribute1(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE2 using the alias name Attribute2
   */
  public String getAttribute2()
  {
    return super.getAttribute2();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE2 using the alias name Attribute2
   */
  public void setAttribute2(String value)
  {
    super.setAttribute2(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE3 using the alias name Attribute3
   */
  public String getAttribute3()
  {
    return super.getAttribute3();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE3 using the alias name Attribute3
   */
  public void setAttribute3(String value)
  {
    super.setAttribute3(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE4 using the alias name Attribute4
   */
  public String getAttribute4()
  {
    return super.getAttribute4();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE4 using the alias name Attribute4
   */
  public void setAttribute4(String value)
  {
    super.setAttribute4(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE5 using the alias name Attribute5
   */
  public String getAttribute5()
  {
    return super.getAttribute5();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE5 using the alias name Attribute5
   */
  public void setAttribute5(String value)
  {
    super.setAttribute5(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE6 using the alias name Attribute6
   */
  public String getAttribute6()
  {
    return super.getAttribute6();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE6 using the alias name Attribute6
   */
  public void setAttribute6(String value)
  {
    super.setAttribute6(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE7 using the alias name Attribute7
   */
  public String getAttribute7()
  {
    return super.getAttribute7();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE7 using the alias name Attribute7
   */
  public void setAttribute7(String value)
  {
    super.setAttribute7(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE8 using the alias name Attribute8
   */
  public String getAttribute8()
  {
    return super.getAttribute8();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE8 using the alias name Attribute8
   */
  public void setAttribute8(String value)
  {
    super.setAttribute8(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE9 using the alias name Attribute9
   */
  public String getAttribute9()
  {
    return super.getAttribute9();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE9 using the alias name Attribute9
   */
  public void setAttribute9(String value)
  {
    super.setAttribute9(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE10 using the alias name Attribute10
   */
  public String getAttribute10()
  {
    return super.getAttribute10();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE10 using the alias name Attribute10
   */
  public void setAttribute10(String value)
  {
    super.setAttribute10(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE11 using the alias name Attribute11
   */
  public String getAttribute11()
  {
    return super.getAttribute11();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE11 using the alias name Attribute11
   */
  public void setAttribute11(String value)
  {
    super.setAttribute11(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE12 using the alias name Attribute12
   */
  public String getAttribute12()
  {
    return super.getAttribute12();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE12 using the alias name Attribute12
   */
  public void setAttribute12(String value)
  {
    super.setAttribute12(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE13 using the alias name Attribute13
   */
  public String getAttribute13()
  {
    return super.getAttribute13();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE13 using the alias name Attribute13
   */
  public void setAttribute13(String value)
  {
    super.setAttribute13(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE14 using the alias name Attribute14
   */
  public String getAttribute14()
  {
    return super.getAttribute14();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE14 using the alias name Attribute14
   */
  public void setAttribute14(String value)
  {
    super.setAttribute14(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE15 using the alias name Attribute15
   */
  public String getAttribute15()
  {
    return super.getAttribute15();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE15 using the alias name Attribute15
   */
  public void setAttribute15(String value)
  {
    super.setAttribute15(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE16 using the alias name Attribute16
   */
  public String getAttribute16()
  {
    return super.getAttribute16();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE16 using the alias name Attribute16
   */
  public void setAttribute16(String value)
  {
    super.setAttribute16(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE17 using the alias name Attribute17
   */
  public String getAttribute17()
  {
    return super.getAttribute17();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE17 using the alias name Attribute17
   */
  public void setAttribute17(String value)
  {
    super.setAttribute17(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE18 using the alias name Attribute18
   */
  public String getAttribute18()
  {
    return super.getAttribute18();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE18 using the alias name Attribute18
   */
  public void setAttribute18(String value)
  {
    super.setAttribute18(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE19 using the alias name Attribute19
   */
  public String getAttribute19()
  {
    return super.getAttribute19();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE19 using the alias name Attribute19
   */
  public void setAttribute19(String value)
  {
    super.setAttribute19(value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE20 using the alias name Attribute20
   */
  public String getAttribute20()
  {
    return super.getAttribute20();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE20 using the alias name Attribute20
   */
  public void setAttribute20(String value)
  {
    super.setAttribute20(value);
  }

  /**
   * 
   * Gets the attribute value for ACTUAL_CONTENT_SOURCE using the alias name ActualContentSource
   */
  public String getActualContentSource()
  {
    return super.getActualContentSource();
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ACTUAL_CONTENT_SOURCE using the alias name ActualContentSource
   */
  public void setActualContentSource(String value)
  {
    super.setActualContentSource(value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UpdateImage
   */
  public String getUpdateImage()
  {
    return super.getUpdateImage();
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UpdateImage
   */
  public void setUpdateImage(String value)
  {
    super.setUpdateImage(value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DeleteImage
   */
  public String getDeleteImage()
  {
    return super.getDeleteImage();
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DeleteImage
   */
  public void setDeleteImage(String value)
  {
    super.setDeleteImage(value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IsPrivilegeChecked
   */
  public String getIsPrivilegeChecked()
  {

    String IsPrivilegeChecked = (String)getAttributeInternal(ISPRIVILEGECHECKED);

    if (IsPrivilegeChecked == null)
    {
      OADBTransactionImpl tx = (OADBTransactionImpl)((OAApplicationModule)getApplicationModule()).getOADBTransaction();
      String[] param = new String[4], value = new String[2];

      // set IN or IN-OUT params, if any
      param[0] = "HZ_CONTACT_POINTS";
      param[1] = getActualContentSource(); 
      param[2] = getContactPointId().toString();
      param[3] = "";

      HzPuiServerUtil.getPrivilegeForPostQuery(tx, param, value);

      // get return
      String updateable = ("Y".equals(value[0])) ? 
                          "UpdateEnabled" : "UpdateDisabled";

      
      String removable = ("Y".equals(getDeleteEnabled(tx))) ? 
                          "DeleteEnabled" : "DeleteDisabled";

      this.populateAttribute(UPDATEIMAGE, updateable);
      this.populateAttribute(DELETEIMAGE, removable);

      IsPrivilegeChecked = "Y";
      this.populateAttribute(ISPRIVILEGECHECKED, IsPrivilegeChecked);
    }

    return IsPrivilegeChecked;  
  }


  /**
   * The method calls a pl/sql procedure to get privileges
   * for post query.
   */
  public String getDeleteEnabled(OADBTransactionImpl tx)
  {
      String sql = "begin " +
                   "  :1 := xx_od_hz_ui_util_pkg.check_row_deleteable(" +
                   "    p_entity_name   => :2, " +
                   "    p_data_source   => :3, " +
                   "    p_entity_pk1    => :4, " +
                   "    p_entity_pk2    => :5, " +
                   "    p_party_id      => :6); " +
                   "end; ";
      OracleCallableStatement cst = null;

      String val ="N";

      try {
        cst = (OracleCallableStatement)tx.createCallableStatement(sql, 1);

        // register types of OUT and IN-OUT params, if any
        cst.registerOutParameter(1, OracleTypes.VARCHAR, 0, 100);

        // set IN or IN-OUT params, if any
        cst.setString(2, "HZ_CONTACT_POINTS"); // entity name
        cst.setString(3, getActualContentSource()); // data source
        cst.setString(4, getContactPointId().toString()); // entity primary key
        cst.setString(5, ""); // entity primary key pt. 2
        if(getOwnerTableId()!=null)
          cst.setString(6,getOwnerTableId().toString());
        else
          cst.setString(6,"");

        cst.execute();

        // get return
        val = cst.getString(1);
        Diagnostic.println("value = " + val); 

        return val;
                   
      }
      catch (SQLException e)
      {
        e.printStackTrace();
      }
      finally
      {
        try
        {
          if ( cst != null ) cst.close();
          return val;
        }
        catch (SQLException e)
        {
          e.printStackTrace();
        }
      }
     return val;
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IsPrivilegeChecked
   */
  public void setIsPrivilegeChecked(String value)
  {
    super.setIsPrivilegeChecked(value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
        return super.getAttrInvokeAccessor(index, attrDef);
    }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {super.setAttrInvokeAccessor(index, value, attrDef);
        return;
    }
}