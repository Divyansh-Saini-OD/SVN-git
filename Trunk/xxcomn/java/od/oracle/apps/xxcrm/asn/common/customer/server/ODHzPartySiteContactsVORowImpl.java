/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODHzPartySiteContactsVORowImpl.java                              |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    View Object Row Implementation for the List of Contacts Available          |
 |    for a Party Site                                                       |
 |                                                                           |
 |  NOTES                                                                    |
 |         Used for the Add Site Contact Page                                |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |     No dependencies.                                                                      |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |   21-Sep-2007 Jasmine Sujithra   Created                                  |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.customer.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODHzPartySiteContactsVORowImpl extends OAViewRowImpl 
{


  protected static final int RELATIONSHIPID = 0;
  protected static final int RELPARTYID = 1;
  protected static final int SUBJECTID = 2;
  protected static final int PARTYID = 3;
  protected static final int PARTYNAME = 4;
  protected static final int CONTACTID = 5;
  protected static final int CONTACTNAME = 6;
  protected static final int KNOWNAS = 7;
  protected static final int PARTYNUMBER = 8;
  protected static final int ROLEMEANINGSINGULAR = 9;
  protected static final int JOBTITLE = 10;
  protected static final int JOBTITLECODE = 11;
  protected static final int DEPARTMENT = 12;
  protected static final int DEPARTMENTCODE = 13;
  protected static final int PRIMARYPHONE = 14;
  protected static final int PHONE = 15;
  protected static final int PRIMARYADDRESS = 16;
  protected static final int PRIMARYPHONECOUNTRYCODE = 17;
  protected static final int PRIMARYPHONEAREACODE = 18;
  protected static final int PRIMARYPHONENUMBER = 19;
  protected static final int PRIMARYPHONEEXTENSION = 20;
  protected static final int PRIMARYPHONELINETYPE = 21;
  protected static final int CONTACTRESTRICTION = 22;
  protected static final int EMAIL = 23;
  protected static final int RELGROUPCODE = 24;
  protected static final int ROLE = 25;
  protected static final int ADDRESS1 = 26;
  protected static final int ADDRESS2 = 27;
  protected static final int ADDRESS3 = 28;
  protected static final int ADDRESS4 = 29;
  protected static final int CITY = 30;
  protected static final int COUNTRY = 31;
  protected static final int STATE = 32;
  protected static final int POSTALCODE = 33;
  protected static final int PARTYTYPE = 34;
  protected static final int SUBJECTTYPE = 35;
  protected static final int OBJECTTYPE = 36;
  protected static final int STATUS = 37;
  protected static final int ORGCONTACTID = 38;
  protected static final int LOCATIONID = 39;
  protected static final int ACTUALCONTENTSOURCE = 40;
  protected static final int SELECTFLAG = 41;
  protected static final int ISFUNCTIONCALLED = 42;
  protected static final int DIRECTIONALFLAG = 43;
  protected static final int ENDDATE = 44;
  protected static final int PERSONFIRSTNAME = 45;
  protected static final int PERSONLASTNAME = 46;
  protected static final int STARTDATE = 47;
  protected static final int OBJECTID = 48;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODHzPartySiteContactsVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RelationshipId
   */
  public Number getRelationshipId()
  {
    return (Number)getAttributeInternal(RELATIONSHIPID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RelationshipId
   */
  public void setRelationshipId(Number value)
  {
    setAttributeInternal(RELATIONSHIPID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RelPartyId
   */
  public Number getRelPartyId()
  {
    return (Number)getAttributeInternal(RELPARTYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RelPartyId
   */
  public void setRelPartyId(Number value)
  {
    setAttributeInternal(RELPARTYID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SubjectId
   */
  public Number getSubjectId()
  {
    return (Number)getAttributeInternal(SUBJECTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SubjectId
   */
  public void setSubjectId(Number value)
  {
    setAttributeInternal(SUBJECTID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyId
   */
  public Number getPartyId()
  {
    return (Number)getAttributeInternal(PARTYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyId
   */
  public void setPartyId(Number value)
  {
    setAttributeInternal(PARTYID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyName
   */
  public String getPartyName()
  {
    return (String)getAttributeInternal(PARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyName
   */
  public void setPartyName(String value)
  {
    setAttributeInternal(PARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContactId
   */
  public Number getContactId()
  {
    return (Number)getAttributeInternal(CONTACTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContactId
   */
  public void setContactId(Number value)
  {
    setAttributeInternal(CONTACTID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContactName
   */
  public String getContactName()
  {
    return (String)getAttributeInternal(CONTACTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContactName
   */
  public void setContactName(String value)
  {
    setAttributeInternal(CONTACTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute KnownAs
   */
  public String getKnownAs()
  {
    return (String)getAttributeInternal(KNOWNAS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute KnownAs
   */
  public void setKnownAs(String value)
  {
    setAttributeInternal(KNOWNAS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyNumber
   */
  public String getPartyNumber()
  {
    return (String)getAttributeInternal(PARTYNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyNumber
   */
  public void setPartyNumber(String value)
  {
    setAttributeInternal(PARTYNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RoleMeaningSingular
   */
  public String getRoleMeaningSingular()
  {
    return (String)getAttributeInternal(ROLEMEANINGSINGULAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RoleMeaningSingular
   */
  public void setRoleMeaningSingular(String value)
  {
    setAttributeInternal(ROLEMEANINGSINGULAR, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute JobTitle
   */
  public String getJobTitle()
  {
    return (String)getAttributeInternal(JOBTITLE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute JobTitle
   */
  public void setJobTitle(String value)
  {
    setAttributeInternal(JOBTITLE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute JobTitleCode
   */
  public String getJobTitleCode()
  {
    return (String)getAttributeInternal(JOBTITLECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute JobTitleCode
   */
  public void setJobTitleCode(String value)
  {
    setAttributeInternal(JOBTITLECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Department
   */
  public String getDepartment()
  {
    return (String)getAttributeInternal(DEPARTMENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Department
   */
  public void setDepartment(String value)
  {
    setAttributeInternal(DEPARTMENT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DepartmentCode
   */
  public String getDepartmentCode()
  {
    return (String)getAttributeInternal(DEPARTMENTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DepartmentCode
   */
  public void setDepartmentCode(String value)
  {
    setAttributeInternal(DEPARTMENTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PrimaryPhone
   */
  public String getPrimaryPhone()
  {
    return (String)getAttributeInternal(PRIMARYPHONE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PrimaryPhone
   */
  public void setPrimaryPhone(String value)
  {
    setAttributeInternal(PRIMARYPHONE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Phone
   */
  public String getPhone()
  {
    return (String)getAttributeInternal(PHONE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Phone
   */
  public void setPhone(String value)
  {
    setAttributeInternal(PHONE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PrimaryAddress
   */
  public String getPrimaryAddress()
  {
    return (String)getAttributeInternal(PRIMARYADDRESS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PrimaryAddress
   */
  public void setPrimaryAddress(String value)
  {
    setAttributeInternal(PRIMARYADDRESS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PrimaryPhoneCountryCode
   */
  public String getPrimaryPhoneCountryCode()
  {
    return (String)getAttributeInternal(PRIMARYPHONECOUNTRYCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PrimaryPhoneCountryCode
   */
  public void setPrimaryPhoneCountryCode(String value)
  {
    setAttributeInternal(PRIMARYPHONECOUNTRYCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PrimaryPhoneAreaCode
   */
  public String getPrimaryPhoneAreaCode()
  {
    return (String)getAttributeInternal(PRIMARYPHONEAREACODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PrimaryPhoneAreaCode
   */
  public void setPrimaryPhoneAreaCode(String value)
  {
    setAttributeInternal(PRIMARYPHONEAREACODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PrimaryPhoneNumber
   */
  public String getPrimaryPhoneNumber()
  {
    return (String)getAttributeInternal(PRIMARYPHONENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PrimaryPhoneNumber
   */
  public void setPrimaryPhoneNumber(String value)
  {
    setAttributeInternal(PRIMARYPHONENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PrimaryPhoneExtension
   */
  public String getPrimaryPhoneExtension()
  {
    return (String)getAttributeInternal(PRIMARYPHONEEXTENSION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PrimaryPhoneExtension
   */
  public void setPrimaryPhoneExtension(String value)
  {
    setAttributeInternal(PRIMARYPHONEEXTENSION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PrimaryPhoneLineType
   */
  public String getPrimaryPhoneLineType()
  {
    return (String)getAttributeInternal(PRIMARYPHONELINETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PrimaryPhoneLineType
   */
  public void setPrimaryPhoneLineType(String value)
  {
    setAttributeInternal(PRIMARYPHONELINETYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContactRestriction
   */
  public String getContactRestriction()
  {
    return (String)getAttributeInternal(CONTACTRESTRICTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContactRestriction
   */
  public void setContactRestriction(String value)
  {
    setAttributeInternal(CONTACTRESTRICTION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Email
   */
  public String getEmail()
  {
    return (String)getAttributeInternal(EMAIL);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Email
   */
  public void setEmail(String value)
  {
    setAttributeInternal(EMAIL, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RelGroupCode
   */
  public String getRelGroupCode()
  {
    return (String)getAttributeInternal(RELGROUPCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RelGroupCode
   */
  public void setRelGroupCode(String value)
  {
    setAttributeInternal(RELGROUPCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Role
   */
  public String getRole()
  {
    return (String)getAttributeInternal(ROLE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Role
   */
  public void setRole(String value)
  {
    setAttributeInternal(ROLE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address1
   */
  public String getAddress1()
  {
    return (String)getAttributeInternal(ADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address1
   */
  public void setAddress1(String value)
  {
    setAttributeInternal(ADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address2
   */
  public String getAddress2()
  {
    return (String)getAttributeInternal(ADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address2
   */
  public void setAddress2(String value)
  {
    setAttributeInternal(ADDRESS2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address3
   */
  public String getAddress3()
  {
    return (String)getAttributeInternal(ADDRESS3);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address3
   */
  public void setAddress3(String value)
  {
    setAttributeInternal(ADDRESS3, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address4
   */
  public String getAddress4()
  {
    return (String)getAttributeInternal(ADDRESS4);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address4
   */
  public void setAddress4(String value)
  {
    setAttributeInternal(ADDRESS4, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute City
   */
  public String getCity()
  {
    return (String)getAttributeInternal(CITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute City
   */
  public void setCity(String value)
  {
    setAttributeInternal(CITY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Country
   */
  public String getCountry()
  {
    return (String)getAttributeInternal(COUNTRY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Country
   */
  public void setCountry(String value)
  {
    setAttributeInternal(COUNTRY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute State
   */
  public String getState()
  {
    return (String)getAttributeInternal(STATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute State
   */
  public void setState(String value)
  {
    setAttributeInternal(STATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PostalCode
   */
  public String getPostalCode()
  {
    return (String)getAttributeInternal(POSTALCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PostalCode
   */
  public void setPostalCode(String value)
  {
    setAttributeInternal(POSTALCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyType
   */
  public String getPartyType()
  {
    return (String)getAttributeInternal(PARTYTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyType
   */
  public void setPartyType(String value)
  {
    setAttributeInternal(PARTYTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SubjectType
   */
  public String getSubjectType()
  {
    return (String)getAttributeInternal(SUBJECTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SubjectType
   */
  public void setSubjectType(String value)
  {
    setAttributeInternal(SUBJECTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ObjectType
   */
  public String getObjectType()
  {
    return (String)getAttributeInternal(OBJECTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ObjectType
   */
  public void setObjectType(String value)
  {
    setAttributeInternal(OBJECTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Status
   */
  public String getStatus()
  {
    return (String)getAttributeInternal(STATUS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Status
   */
  public void setStatus(String value)
  {
    setAttributeInternal(STATUS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OrgContactId
   */
  public Number getOrgContactId()
  {
    return (Number)getAttributeInternal(ORGCONTACTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OrgContactId
   */
  public void setOrgContactId(Number value)
  {
    setAttributeInternal(ORGCONTACTID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LocationId
   */
  public Number getLocationId()
  {
    return (Number)getAttributeInternal(LOCATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LocationId
   */
  public void setLocationId(Number value)
  {
    setAttributeInternal(LOCATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ActualContentSource
   */
  public String getActualContentSource()
  {
    return (String)getAttributeInternal(ACTUALCONTENTSOURCE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ActualContentSource
   */
  public void setActualContentSource(String value)
  {
    setAttributeInternal(ACTUALCONTENTSOURCE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SelectFlag
   */
  public String getSelectFlag()
  {
    return (String)getAttributeInternal(SELECTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelectFlag
   */
  public void setSelectFlag(String value)
  {
    setAttributeInternal(SELECTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IsFunctionCalled
   */
  public String getIsFunctionCalled()
  {
    return (String)getAttributeInternal(ISFUNCTIONCALLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IsFunctionCalled
   */
  public void setIsFunctionCalled(String value)
  {
    setAttributeInternal(ISFUNCTIONCALLED, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case RELATIONSHIPID:
        return getRelationshipId();
      case RELPARTYID:
        return getRelPartyId();
      case SUBJECTID:
        return getSubjectId();
      case PARTYID:
        return getPartyId();
      case PARTYNAME:
        return getPartyName();
      case CONTACTID:
        return getContactId();
      case CONTACTNAME:
        return getContactName();
      case KNOWNAS:
        return getKnownAs();
      case PARTYNUMBER:
        return getPartyNumber();
      case ROLEMEANINGSINGULAR:
        return getRoleMeaningSingular();
      case JOBTITLE:
        return getJobTitle();
      case JOBTITLECODE:
        return getJobTitleCode();
      case DEPARTMENT:
        return getDepartment();
      case DEPARTMENTCODE:
        return getDepartmentCode();
      case PRIMARYPHONE:
        return getPrimaryPhone();
      case PHONE:
        return getPhone();
      case PRIMARYADDRESS:
        return getPrimaryAddress();
      case PRIMARYPHONECOUNTRYCODE:
        return getPrimaryPhoneCountryCode();
      case PRIMARYPHONEAREACODE:
        return getPrimaryPhoneAreaCode();
      case PRIMARYPHONENUMBER:
        return getPrimaryPhoneNumber();
      case PRIMARYPHONEEXTENSION:
        return getPrimaryPhoneExtension();
      case PRIMARYPHONELINETYPE:
        return getPrimaryPhoneLineType();
      case CONTACTRESTRICTION:
        return getContactRestriction();
      case EMAIL:
        return getEmail();
      case RELGROUPCODE:
        return getRelGroupCode();
      case ROLE:
        return getRole();
      case ADDRESS1:
        return getAddress1();
      case ADDRESS2:
        return getAddress2();
      case ADDRESS3:
        return getAddress3();
      case ADDRESS4:
        return getAddress4();
      case CITY:
        return getCity();
      case COUNTRY:
        return getCountry();
      case STATE:
        return getState();
      case POSTALCODE:
        return getPostalCode();
      case PARTYTYPE:
        return getPartyType();
      case SUBJECTTYPE:
        return getSubjectType();
      case OBJECTTYPE:
        return getObjectType();
      case STATUS:
        return getStatus();
      case ORGCONTACTID:
        return getOrgContactId();
      case LOCATIONID:
        return getLocationId();
      case ACTUALCONTENTSOURCE:
        return getActualContentSource();
      case SELECTFLAG:
        return getSelectFlag();
      case ISFUNCTIONCALLED:
        return getIsFunctionCalled();
      case DIRECTIONALFLAG:
        return getDirectionalFlag();
      case ENDDATE:
        return getEndDate();
      case PERSONFIRSTNAME:
        return getPersonFirstName();
      case PERSONLASTNAME:
        return getPersonLastName();
      case STARTDATE:
        return getStartDate();
      case OBJECTID:
        return getObjectId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case RELATIONSHIPID:
        setRelationshipId((Number)value);
        return;
      case RELPARTYID:
        setRelPartyId((Number)value);
        return;
      case SUBJECTID:
        setSubjectId((Number)value);
        return;
      case PARTYID:
        setPartyId((Number)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case CONTACTID:
        setContactId((Number)value);
        return;
      case CONTACTNAME:
        setContactName((String)value);
        return;
      case KNOWNAS:
        setKnownAs((String)value);
        return;
      case PARTYNUMBER:
        setPartyNumber((String)value);
        return;
      case ROLEMEANINGSINGULAR:
        setRoleMeaningSingular((String)value);
        return;
      case JOBTITLE:
        setJobTitle((String)value);
        return;
      case JOBTITLECODE:
        setJobTitleCode((String)value);
        return;
      case DEPARTMENT:
        setDepartment((String)value);
        return;
      case DEPARTMENTCODE:
        setDepartmentCode((String)value);
        return;
      case PRIMARYPHONE:
        setPrimaryPhone((String)value);
        return;
      case PHONE:
        setPhone((String)value);
        return;
      case PRIMARYADDRESS:
        setPrimaryAddress((String)value);
        return;
      case PRIMARYPHONECOUNTRYCODE:
        setPrimaryPhoneCountryCode((String)value);
        return;
      case PRIMARYPHONEAREACODE:
        setPrimaryPhoneAreaCode((String)value);
        return;
      case PRIMARYPHONENUMBER:
        setPrimaryPhoneNumber((String)value);
        return;
      case PRIMARYPHONEEXTENSION:
        setPrimaryPhoneExtension((String)value);
        return;
      case PRIMARYPHONELINETYPE:
        setPrimaryPhoneLineType((String)value);
        return;
      case CONTACTRESTRICTION:
        setContactRestriction((String)value);
        return;
      case EMAIL:
        setEmail((String)value);
        return;
      case RELGROUPCODE:
        setRelGroupCode((String)value);
        return;
      case ROLE:
        setRole((String)value);
        return;
      case ADDRESS1:
        setAddress1((String)value);
        return;
      case ADDRESS2:
        setAddress2((String)value);
        return;
      case ADDRESS3:
        setAddress3((String)value);
        return;
      case ADDRESS4:
        setAddress4((String)value);
        return;
      case CITY:
        setCity((String)value);
        return;
      case COUNTRY:
        setCountry((String)value);
        return;
      case STATE:
        setState((String)value);
        return;
      case POSTALCODE:
        setPostalCode((String)value);
        return;
      case PARTYTYPE:
        setPartyType((String)value);
        return;
      case SUBJECTTYPE:
        setSubjectType((String)value);
        return;
      case OBJECTTYPE:
        setObjectType((String)value);
        return;
      case STATUS:
        setStatus((String)value);
        return;
      case ORGCONTACTID:
        setOrgContactId((Number)value);
        return;
      case LOCATIONID:
        setLocationId((Number)value);
        return;
      case ACTUALCONTENTSOURCE:
        setActualContentSource((String)value);
        return;
      case SELECTFLAG:
        setSelectFlag((String)value);
        return;
      case ISFUNCTIONCALLED:
        setIsFunctionCalled((String)value);
        return;
      case DIRECTIONALFLAG:
        setDirectionalFlag((String)value);
        return;
      case ENDDATE:
        setEndDate((String)value);
        return;
      case PERSONFIRSTNAME:
        setPersonFirstName((String)value);
        return;
      case PERSONLASTNAME:
        setPersonLastName((String)value);
        return;
      case STARTDATE:
        setStartDate((Date)value);
        return;
      case OBJECTID:
        setObjectId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DirectionalFlag
   */
  public String getDirectionalFlag()
  {
    return (String)getAttributeInternal(DIRECTIONALFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DirectionalFlag
   */
  public void setDirectionalFlag(String value)
  {
    setAttributeInternal(DIRECTIONALFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EndDate
   */
  public String getEndDate()
  {
    return (String)getAttributeInternal(ENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EndDate
   */
  public void setEndDate(String value)
  {
    setAttributeInternal(ENDDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PersonFirstName
   */
  public String getPersonFirstName()
  {
    return (String)getAttributeInternal(PERSONFIRSTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PersonFirstName
   */
  public void setPersonFirstName(String value)
  {
    setAttributeInternal(PERSONFIRSTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PersonLastName
   */
  public String getPersonLastName()
  {
    return (String)getAttributeInternal(PERSONLASTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PersonLastName
   */
  public void setPersonLastName(String value)
  {
    setAttributeInternal(PERSONLASTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StartDate
   */
  public Date getStartDate()
  {
    return (Date)getAttributeInternal(STARTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StartDate
   */
  public void setStartDate(Date value)
  {
    setAttributeInternal(STARTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ObjectId
   */
  public Number getObjectId()
  {
    return (Number)getAttributeInternal(OBJECTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ObjectId
   */
  public void setObjectId(Number value)
  {
    setAttributeInternal(OBJECTID, value);
  }
}