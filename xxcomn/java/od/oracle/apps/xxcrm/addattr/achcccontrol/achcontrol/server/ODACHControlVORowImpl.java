package od.oracle.apps.xxcrm.addattr.achcccontrol.achcontrol.server;

import od.oracle.apps.xxcrm.addattr.achcccontrol.schema.server.ODAchCCControlEOImpl;

import oracle.apps.fnd.framework.server.OAViewRowImpl;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.RowID;
import oracle.jbo.server.AttributeDefImpl;
 /*
  --  Copyright (c) 2015, by Office Depot., All Rights Reserved
  --
  -- Author: Sridevi Kondoju
  -- Component Id: E0255 CR1120
  -- Script Location:
             $CUSTOM_JAVA_TOP/od/oracle/apps/xxcrm/addattr/achcccontrol/achcontrol/server
  -- Description: 
  -- Package Usage       : 
  -- Name                  Type         Purpose
  -- --------------------  -----------  ------------------------------------------
   -- Notes:
   -- History:
   -- Name            Date         Version    Description
   -- -----           -----        -------    -----------
   -- Sridevi Kondoju 27-MAR-2015  1.0        Initial version
   --
  */
public class ODACHControlVORowImpl extends OAViewRowImpl {
    public static final int ATTRGROUPID = 0;
    public static final int CREATEDBY = 1;
    public static final int CREATIONDATE = 2;
    public static final int CUSTACCOUNTID = 3;
    public static final int CEXTATTR1 = 4;
    public static final int CEXTATTR10 = 5;
    public static final int CEXTATTR11 = 6;
    public static final int CEXTATTR12 = 7;
    public static final int CEXTATTR13 = 8;
    public static final int CEXTATTR14 = 9;
    public static final int CEXTATTR15 = 10;
    public static final int CEXTATTR16 = 11;
    public static final int CEXTATTR17 = 12;
    public static final int CEXTATTR18 = 13;
    public static final int CEXTATTR19 = 14;
    public static final int CEXTATTR2 = 15;
    public static final int CEXTATTR20 = 16;
    public static final int CEXTATTR3 = 17;
    public static final int CEXTATTR4 = 18;
    public static final int CEXTATTR5 = 19;
    public static final int CEXTATTR6 = 20;
    public static final int CEXTATTR7 = 21;
    public static final int CEXTATTR8 = 22;
    public static final int CEXTATTR9 = 23;
    public static final int DEXTATTR1 = 24;
    public static final int DEXTATTR10 = 25;
    public static final int DEXTATTR2 = 26;
    public static final int DEXTATTR3 = 27;
    public static final int DEXTATTR4 = 28;
    public static final int DEXTATTR5 = 29;
    public static final int DEXTATTR6 = 30;
    public static final int DEXTATTR7 = 31;
    public static final int DEXTATTR8 = 32;
    public static final int DEXTATTR9 = 33;
    public static final int EXTENSIONID = 34;
    public static final int LASTUPDATEDBY = 35;
    public static final int LASTUPDATEDATE = 36;
    public static final int LASTUPDATELOGIN = 37;
    public static final int NEXTATTR1 = 38;
    public static final int NEXTATTR10 = 39;
    public static final int NEXTATTR11 = 40;
    public static final int NEXTATTR12 = 41;
    public static final int NEXTATTR13 = 42;
    public static final int NEXTATTR14 = 43;
    public static final int NEXTATTR15 = 44;
    public static final int NEXTATTR16 = 45;
    public static final int NEXTATTR17 = 46;
    public static final int NEXTATTR18 = 47;
    public static final int NEXTATTR19 = 48;
    public static final int NEXTATTR2 = 49;
    public static final int NEXTATTR20 = 50;
    public static final int NEXTATTR3 = 51;
    public static final int NEXTATTR4 = 52;
    public static final int NEXTATTR5 = 53;
    public static final int NEXTATTR6 = 54;
    public static final int NEXTATTR7 = 55;
    public static final int NEXTATTR8 = 56;
    public static final int NEXTATTR9 = 57;
    public static final int ROWID = 58;
    public static final int LAST_UPDATED_BY_USER = 59;
    public static final int LASTUPDATEDATEDISP=60;
    public static final int INITIALCEXTATTR1=61;

    /**This is the default constructor (do not remove)
     */
    public ODACHControlVORowImpl() {
    }

    /**Gets ODAchCCControlEO entity object.
     */
    public ODAchCCControlEOImpl getODAchCCControlEO() {
        return (ODAchCCControlEOImpl)getEntity(0);
    }

    /**Gets the attribute value for ATTR_GROUP_ID using the alias name AttrGroupId
     */
    public Number getAttrGroupId() {
        return (Number) getAttributeInternal(ATTRGROUPID);
    }

    /**Sets <code>value</code> as attribute value for ATTR_GROUP_ID using the alias name AttrGroupId
     */
    public void setAttrGroupId(Number value) {
        setAttributeInternal(ATTRGROUPID, value);
    }

    /**Gets the attribute value for CREATED_BY using the alias name CreatedBy
     */
    public Number getCreatedBy() {
        return (Number) getAttributeInternal(CREATEDBY);
    }

    /**Sets <code>value</code> as attribute value for CREATED_BY using the alias name CreatedBy
     */
    public void setCreatedBy(Number value) {
        setAttributeInternal(CREATEDBY, value);
    }

    /**Gets the attribute value for CREATION_DATE using the alias name CreationDate
     */
    public Date getCreationDate() {
        return (Date) getAttributeInternal(CREATIONDATE);
    }

    /**Sets <code>value</code> as attribute value for CREATION_DATE using the alias name CreationDate
     */
    public void setCreationDate(Date value) {
        setAttributeInternal(CREATIONDATE, value);
    }

    /**Gets the attribute value for CUST_ACCOUNT_ID using the alias name CustAccountId
     */
    public Number getCustAccountId() {
        return (Number) getAttributeInternal(CUSTACCOUNTID);
    }

    /**Sets <code>value</code> as attribute value for CUST_ACCOUNT_ID using the alias name CustAccountId
     */
    public void setCustAccountId(Number value) {
        setAttributeInternal(CUSTACCOUNTID, value);
    }

    /**Gets the attribute value for C_EXT_ATTR1 using the alias name CExtAttr1
     */
    public String getCExtAttr1() {
        return (String) getAttributeInternal(CEXTATTR1);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR1 using the alias name CExtAttr1
     */
    public void setCExtAttr1(String value) {
        setAttributeInternal(CEXTATTR1, value);
    }

    /**Gets the attribute value for C_EXT_ATTR10 using the alias name CExtAttr10
     */
    public String getCExtAttr10() {
        return (String) getAttributeInternal(CEXTATTR10);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR10 using the alias name CExtAttr10
     */
    public void setCExtAttr10(String value) {
        setAttributeInternal(CEXTATTR10, value);
    }

    /**Gets the attribute value for C_EXT_ATTR11 using the alias name CExtAttr11
     */
    public String getCExtAttr11() {
        return (String) getAttributeInternal(CEXTATTR11);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR11 using the alias name CExtAttr11
     */
    public void setCExtAttr11(String value) {
        setAttributeInternal(CEXTATTR11, value);
    }

    /**Gets the attribute value for C_EXT_ATTR12 using the alias name CExtAttr12
     */
    public String getCExtAttr12() {
        return (String) getAttributeInternal(CEXTATTR12);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR12 using the alias name CExtAttr12
     */
    public void setCExtAttr12(String value) {
        setAttributeInternal(CEXTATTR12, value);
    }

    /**Gets the attribute value for C_EXT_ATTR13 using the alias name CExtAttr13
     */
    public String getCExtAttr13() {
        return (String) getAttributeInternal(CEXTATTR13);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR13 using the alias name CExtAttr13
     */
    public void setCExtAttr13(String value) {
        setAttributeInternal(CEXTATTR13, value);
    }

    /**Gets the attribute value for C_EXT_ATTR14 using the alias name CExtAttr14
     */
    public String getCExtAttr14() {
        return (String) getAttributeInternal(CEXTATTR14);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR14 using the alias name CExtAttr14
     */
    public void setCExtAttr14(String value) {
        setAttributeInternal(CEXTATTR14, value);
    }

    /**Gets the attribute value for C_EXT_ATTR15 using the alias name CExtAttr15
     */
    public String getCExtAttr15() {
        return (String) getAttributeInternal(CEXTATTR15);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR15 using the alias name CExtAttr15
     */
    public void setCExtAttr15(String value) {
        setAttributeInternal(CEXTATTR15, value);
    }

    /**Gets the attribute value for C_EXT_ATTR16 using the alias name CExtAttr16
     */
    public String getCExtAttr16() {
        return (String) getAttributeInternal(CEXTATTR16);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR16 using the alias name CExtAttr16
     */
    public void setCExtAttr16(String value) {
        setAttributeInternal(CEXTATTR16, value);
    }

    /**Gets the attribute value for C_EXT_ATTR17 using the alias name CExtAttr17
     */
    public String getCExtAttr17() {
        return (String) getAttributeInternal(CEXTATTR17);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR17 using the alias name CExtAttr17
     */
    public void setCExtAttr17(String value) {
        setAttributeInternal(CEXTATTR17, value);
    }

    /**Gets the attribute value for C_EXT_ATTR18 using the alias name CExtAttr18
     */
    public String getCExtAttr18() {
        return (String) getAttributeInternal(CEXTATTR18);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR18 using the alias name CExtAttr18
     */
    public void setCExtAttr18(String value) {
        setAttributeInternal(CEXTATTR18, value);
    }

    /**Gets the attribute value for C_EXT_ATTR19 using the alias name CExtAttr19
     */
    public String getCExtAttr19() {
        return (String) getAttributeInternal(CEXTATTR19);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR19 using the alias name CExtAttr19
     */
    public void setCExtAttr19(String value) {
        setAttributeInternal(CEXTATTR19, value);
    }

    /**Gets the attribute value for C_EXT_ATTR2 using the alias name CExtAttr2
     */
    public String getCExtAttr2() {
        return (String) getAttributeInternal(CEXTATTR2);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR2 using the alias name CExtAttr2
     */
    public void setCExtAttr2(String value) {
        setAttributeInternal(CEXTATTR2, value);
    }

    /**Gets the attribute value for C_EXT_ATTR20 using the alias name CExtAttr20
     */
    public String getCExtAttr20() {
        return (String) getAttributeInternal(CEXTATTR20);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR20 using the alias name CExtAttr20
     */
    public void setCExtAttr20(String value) {
        setAttributeInternal(CEXTATTR20, value);
    }

    /**Gets the attribute value for C_EXT_ATTR3 using the alias name CExtAttr3
     */
    public String getCExtAttr3() {
        return (String) getAttributeInternal(CEXTATTR3);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR3 using the alias name CExtAttr3
     */
    public void setCExtAttr3(String value) {
        setAttributeInternal(CEXTATTR3, value);
    }

    /**Gets the attribute value for C_EXT_ATTR4 using the alias name CExtAttr4
     */
    public String getCExtAttr4() {
        return (String) getAttributeInternal(CEXTATTR4);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR4 using the alias name CExtAttr4
     */
    public void setCExtAttr4(String value) {
        setAttributeInternal(CEXTATTR4, value);
    }

    /**Gets the attribute value for C_EXT_ATTR5 using the alias name CExtAttr5
     */
    public String getCExtAttr5() {
        return (String) getAttributeInternal(CEXTATTR5);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR5 using the alias name CExtAttr5
     */
    public void setCExtAttr5(String value) {
        setAttributeInternal(CEXTATTR5, value);
    }

    /**Gets the attribute value for C_EXT_ATTR6 using the alias name CExtAttr6
     */
    public String getCExtAttr6() {
        return (String) getAttributeInternal(CEXTATTR6);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR6 using the alias name CExtAttr6
     */
    public void setCExtAttr6(String value) {
        setAttributeInternal(CEXTATTR6, value);
    }

    /**Gets the attribute value for C_EXT_ATTR7 using the alias name CExtAttr7
     */
    public String getCExtAttr7() {
        return (String) getAttributeInternal(CEXTATTR7);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR7 using the alias name CExtAttr7
     */
    public void setCExtAttr7(String value) {
        setAttributeInternal(CEXTATTR7, value);
    }

    /**Gets the attribute value for C_EXT_ATTR8 using the alias name CExtAttr8
     */
    public String getCExtAttr8() {
        return (String) getAttributeInternal(CEXTATTR8);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR8 using the alias name CExtAttr8
     */
    public void setCExtAttr8(String value) {
        setAttributeInternal(CEXTATTR8, value);
    }

    /**Gets the attribute value for C_EXT_ATTR9 using the alias name CExtAttr9
     */
    public String getCExtAttr9() {
        return (String) getAttributeInternal(CEXTATTR9);
    }

    /**Sets <code>value</code> as attribute value for C_EXT_ATTR9 using the alias name CExtAttr9
     */
    public void setCExtAttr9(String value) {
        setAttributeInternal(CEXTATTR9, value);
    }

    /**Gets the attribute value for D_EXT_ATTR1 using the alias name DExtAttr1
     */
    public Date getDExtAttr1() {
        return (Date) getAttributeInternal(DEXTATTR1);
    }

    /**Sets <code>value</code> as attribute value for D_EXT_ATTR1 using the alias name DExtAttr1
     */
    public void setDExtAttr1(Date value) {
        setAttributeInternal(DEXTATTR1, value);
    }

    /**Gets the attribute value for D_EXT_ATTR10 using the alias name DExtAttr10
     */
    public Date getDExtAttr10() {
        return (Date) getAttributeInternal(DEXTATTR10);
    }

    /**Sets <code>value</code> as attribute value for D_EXT_ATTR10 using the alias name DExtAttr10
     */
    public void setDExtAttr10(Date value) {
        setAttributeInternal(DEXTATTR10, value);
    }

    /**Gets the attribute value for D_EXT_ATTR2 using the alias name DExtAttr2
     */
    public Date getDExtAttr2() {
        return (Date) getAttributeInternal(DEXTATTR2);
    }

    /**Sets <code>value</code> as attribute value for D_EXT_ATTR2 using the alias name DExtAttr2
     */
    public void setDExtAttr2(Date value) {
        setAttributeInternal(DEXTATTR2, value);
    }

    /**Gets the attribute value for D_EXT_ATTR3 using the alias name DExtAttr3
     */
    public Date getDExtAttr3() {
        return (Date) getAttributeInternal(DEXTATTR3);
    }

    /**Sets <code>value</code> as attribute value for D_EXT_ATTR3 using the alias name DExtAttr3
     */
    public void setDExtAttr3(Date value) {
        setAttributeInternal(DEXTATTR3, value);
    }

    /**Gets the attribute value for D_EXT_ATTR4 using the alias name DExtAttr4
     */
    public Date getDExtAttr4() {
        return (Date) getAttributeInternal(DEXTATTR4);
    }

    /**Sets <code>value</code> as attribute value for D_EXT_ATTR4 using the alias name DExtAttr4
     */
    public void setDExtAttr4(Date value) {
        setAttributeInternal(DEXTATTR4, value);
    }

    /**Gets the attribute value for D_EXT_ATTR5 using the alias name DExtAttr5
     */
    public Date getDExtAttr5() {
        return (Date) getAttributeInternal(DEXTATTR5);
    }

    /**Sets <code>value</code> as attribute value for D_EXT_ATTR5 using the alias name DExtAttr5
     */
    public void setDExtAttr5(Date value) {
        setAttributeInternal(DEXTATTR5, value);
    }

    /**Gets the attribute value for D_EXT_ATTR6 using the alias name DExtAttr6
     */
    public Date getDExtAttr6() {
        return (Date) getAttributeInternal(DEXTATTR6);
    }

    /**Sets <code>value</code> as attribute value for D_EXT_ATTR6 using the alias name DExtAttr6
     */
    public void setDExtAttr6(Date value) {
        setAttributeInternal(DEXTATTR6, value);
    }

    /**Gets the attribute value for D_EXT_ATTR7 using the alias name DExtAttr7
     */
    public Date getDExtAttr7() {
        return (Date) getAttributeInternal(DEXTATTR7);
    }

    /**Sets <code>value</code> as attribute value for D_EXT_ATTR7 using the alias name DExtAttr7
     */
    public void setDExtAttr7(Date value) {
        setAttributeInternal(DEXTATTR7, value);
    }

    /**Gets the attribute value for D_EXT_ATTR8 using the alias name DExtAttr8
     */
    public Date getDExtAttr8() {
        return (Date) getAttributeInternal(DEXTATTR8);
    }

    /**Sets <code>value</code> as attribute value for D_EXT_ATTR8 using the alias name DExtAttr8
     */
    public void setDExtAttr8(Date value) {
        setAttributeInternal(DEXTATTR8, value);
    }

    /**Gets the attribute value for D_EXT_ATTR9 using the alias name DExtAttr9
     */
    public Date getDExtAttr9() {
        return (Date) getAttributeInternal(DEXTATTR9);
    }

    /**Sets <code>value</code> as attribute value for D_EXT_ATTR9 using the alias name DExtAttr9
     */
    public void setDExtAttr9(Date value) {
        setAttributeInternal(DEXTATTR9, value);
    }

    /**Gets the attribute value for EXTENSION_ID using the alias name ExtensionId
     */
    public Number getExtensionId() {
        return (Number) getAttributeInternal(EXTENSIONID);
    }

    /**Sets <code>value</code> as attribute value for EXTENSION_ID using the alias name ExtensionId
     */
    public void setExtensionId(Number value) {
        setAttributeInternal(EXTENSIONID, value);
    }

    /**Gets the attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
     */
    public Number getLastUpdatedBy() {
        return (Number) getAttributeInternal(LASTUPDATEDBY);
    }

    /**Sets <code>value</code> as attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
     */
    public void setLastUpdatedBy(Number value) {
        setAttributeInternal(LASTUPDATEDBY, value);
    }

    /**Gets the attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
     */
    public Date getLastUpdateDate() {
        return (Date) getAttributeInternal(LASTUPDATEDATE);
    }

    /**Sets <code>value</code> as attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
     */
    public void setLastUpdateDate(Date value) {
        setAttributeInternal(LASTUPDATEDATE, value);
    }

    /**Gets the attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
     */
    public Number getLastUpdateLogin() {
        return (Number) getAttributeInternal(LASTUPDATELOGIN);
    }

    /**Sets <code>value</code> as attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
     */
    public void setLastUpdateLogin(Number value) {
        setAttributeInternal(LASTUPDATELOGIN, value);
    }

    /**Gets the attribute value for N_EXT_ATTR1 using the alias name NExtAttr1
     */
    public Number getNExtAttr1() {
        return (Number) getAttributeInternal(NEXTATTR1);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR1 using the alias name NExtAttr1
     */
    public void setNExtAttr1(Number value) {
        setAttributeInternal(NEXTATTR1, value);
    }

    /**Gets the attribute value for N_EXT_ATTR10 using the alias name NExtAttr10
     */
    public Number getNExtAttr10() {
        return (Number) getAttributeInternal(NEXTATTR10);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR10 using the alias name NExtAttr10
     */
    public void setNExtAttr10(Number value) {
        setAttributeInternal(NEXTATTR10, value);
    }

    /**Gets the attribute value for N_EXT_ATTR11 using the alias name NExtAttr11
     */
    public Number getNExtAttr11() {
        return (Number) getAttributeInternal(NEXTATTR11);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR11 using the alias name NExtAttr11
     */
    public void setNExtAttr11(Number value) {
        setAttributeInternal(NEXTATTR11, value);
    }

    /**Gets the attribute value for N_EXT_ATTR12 using the alias name NExtAttr12
     */
    public Number getNExtAttr12() {
        return (Number) getAttributeInternal(NEXTATTR12);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR12 using the alias name NExtAttr12
     */
    public void setNExtAttr12(Number value) {
        setAttributeInternal(NEXTATTR12, value);
    }

    /**Gets the attribute value for N_EXT_ATTR13 using the alias name NExtAttr13
     */
    public Number getNExtAttr13() {
        return (Number) getAttributeInternal(NEXTATTR13);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR13 using the alias name NExtAttr13
     */
    public void setNExtAttr13(Number value) {
        setAttributeInternal(NEXTATTR13, value);
    }

    /**Gets the attribute value for N_EXT_ATTR14 using the alias name NExtAttr14
     */
    public Number getNExtAttr14() {
        return (Number) getAttributeInternal(NEXTATTR14);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR14 using the alias name NExtAttr14
     */
    public void setNExtAttr14(Number value) {
        setAttributeInternal(NEXTATTR14, value);
    }

    /**Gets the attribute value for N_EXT_ATTR15 using the alias name NExtAttr15
     */
    public Number getNExtAttr15() {
        return (Number) getAttributeInternal(NEXTATTR15);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR15 using the alias name NExtAttr15
     */
    public void setNExtAttr15(Number value) {
        setAttributeInternal(NEXTATTR15, value);
    }

    /**Gets the attribute value for N_EXT_ATTR16 using the alias name NExtAttr16
     */
    public Number getNExtAttr16() {
        return (Number) getAttributeInternal(NEXTATTR16);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR16 using the alias name NExtAttr16
     */
    public void setNExtAttr16(Number value) {
        setAttributeInternal(NEXTATTR16, value);
    }

    /**Gets the attribute value for N_EXT_ATTR17 using the alias name NExtAttr17
     */
    public Number getNExtAttr17() {
        return (Number) getAttributeInternal(NEXTATTR17);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR17 using the alias name NExtAttr17
     */
    public void setNExtAttr17(Number value) {
        setAttributeInternal(NEXTATTR17, value);
    }

    /**Gets the attribute value for N_EXT_ATTR18 using the alias name NExtAttr18
     */
    public Number getNExtAttr18() {
        return (Number) getAttributeInternal(NEXTATTR18);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR18 using the alias name NExtAttr18
     */
    public void setNExtAttr18(Number value) {
        setAttributeInternal(NEXTATTR18, value);
    }

    /**Gets the attribute value for N_EXT_ATTR19 using the alias name NExtAttr19
     */
    public Number getNExtAttr19() {
        return (Number) getAttributeInternal(NEXTATTR19);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR19 using the alias name NExtAttr19
     */
    public void setNExtAttr19(Number value) {
        setAttributeInternal(NEXTATTR19, value);
    }

    /**Gets the attribute value for N_EXT_ATTR2 using the alias name NExtAttr2
     */
    public Number getNExtAttr2() {
        return (Number) getAttributeInternal(NEXTATTR2);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR2 using the alias name NExtAttr2
     */
    public void setNExtAttr2(Number value) {
        setAttributeInternal(NEXTATTR2, value);
    }

    /**Gets the attribute value for N_EXT_ATTR20 using the alias name NExtAttr20
     */
    public Number getNExtAttr20() {
        return (Number) getAttributeInternal(NEXTATTR20);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR20 using the alias name NExtAttr20
     */
    public void setNExtAttr20(Number value) {
        setAttributeInternal(NEXTATTR20, value);
    }

    /**Gets the attribute value for N_EXT_ATTR3 using the alias name NExtAttr3
     */
    public Number getNExtAttr3() {
        return (Number) getAttributeInternal(NEXTATTR3);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR3 using the alias name NExtAttr3
     */
    public void setNExtAttr3(Number value) {
        setAttributeInternal(NEXTATTR3, value);
    }

    /**Gets the attribute value for N_EXT_ATTR4 using the alias name NExtAttr4
     */
    public Number getNExtAttr4() {
        return (Number) getAttributeInternal(NEXTATTR4);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR4 using the alias name NExtAttr4
     */
    public void setNExtAttr4(Number value) {
        setAttributeInternal(NEXTATTR4, value);
    }

    /**Gets the attribute value for N_EXT_ATTR5 using the alias name NExtAttr5
     */
    public Number getNExtAttr5() {
        return (Number) getAttributeInternal(NEXTATTR5);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR5 using the alias name NExtAttr5
     */
    public void setNExtAttr5(Number value) {
        setAttributeInternal(NEXTATTR5, value);
    }

    /**Gets the attribute value for N_EXT_ATTR6 using the alias name NExtAttr6
     */
    public Number getNExtAttr6() {
        return (Number) getAttributeInternal(NEXTATTR6);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR6 using the alias name NExtAttr6
     */
    public void setNExtAttr6(Number value) {
        setAttributeInternal(NEXTATTR6, value);
    }

    /**Gets the attribute value for N_EXT_ATTR7 using the alias name NExtAttr7
     */
    public Number getNExtAttr7() {
        return (Number) getAttributeInternal(NEXTATTR7);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR7 using the alias name NExtAttr7
     */
    public void setNExtAttr7(Number value) {
        setAttributeInternal(NEXTATTR7, value);
    }

    /**Gets the attribute value for N_EXT_ATTR8 using the alias name NExtAttr8
     */
    public Number getNExtAttr8() {
        return (Number) getAttributeInternal(NEXTATTR8);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR8 using the alias name NExtAttr8
     */
    public void setNExtAttr8(Number value) {
        setAttributeInternal(NEXTATTR8, value);
    }

    /**Gets the attribute value for N_EXT_ATTR9 using the alias name NExtAttr9
     */
    public Number getNExtAttr9() {
        return (Number) getAttributeInternal(NEXTATTR9);
    }

    /**Sets <code>value</code> as attribute value for N_EXT_ATTR9 using the alias name NExtAttr9
     */
    public void setNExtAttr9(Number value) {
        setAttributeInternal(NEXTATTR9, value);
    }

    /**Gets the attribute value for ROWID using the alias name RowID
     */
    public RowID getRowID() {
        return (RowID) getAttributeInternal(ROWID);
    }

    /**getAttrInvokeAccessor: generated method. Do not modify.
     */
    protected Object getAttrInvokeAccessor(int index, 
                                           AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case ATTRGROUPID:
            return getAttrGroupId();
        case CREATEDBY:
            return getCreatedBy();
        case CREATIONDATE:
            return getCreationDate();
        case CUSTACCOUNTID:
            return getCustAccountId();
        case CEXTATTR1:
            return getCExtAttr1();
        case CEXTATTR10:
            return getCExtAttr10();
        case CEXTATTR11:
            return getCExtAttr11();
        case CEXTATTR12:
            return getCExtAttr12();
        case CEXTATTR13:
            return getCExtAttr13();
        case CEXTATTR14:
            return getCExtAttr14();
        case CEXTATTR15:
            return getCExtAttr15();
        case CEXTATTR16:
            return getCExtAttr16();
        case CEXTATTR17:
            return getCExtAttr17();
        case CEXTATTR18:
            return getCExtAttr18();
        case CEXTATTR19:
            return getCExtAttr19();
        case CEXTATTR2:
            return getCExtAttr2();
        case CEXTATTR20:
            return getCExtAttr20();
        case CEXTATTR3:
            return getCExtAttr3();
        case CEXTATTR4:
            return getCExtAttr4();
        case CEXTATTR5:
            return getCExtAttr5();
        case CEXTATTR6:
            return getCExtAttr6();
        case CEXTATTR7:
            return getCExtAttr7();
        case CEXTATTR8:
            return getCExtAttr8();
        case CEXTATTR9:
            return getCExtAttr9();
        case DEXTATTR1:
            return getDExtAttr1();
        case DEXTATTR10:
            return getDExtAttr10();
        case DEXTATTR2:
            return getDExtAttr2();
        case DEXTATTR3:
            return getDExtAttr3();
        case DEXTATTR4:
            return getDExtAttr4();
        case DEXTATTR5:
            return getDExtAttr5();
        case DEXTATTR6:
            return getDExtAttr6();
        case DEXTATTR7:
            return getDExtAttr7();
        case DEXTATTR8:
            return getDExtAttr8();
        case DEXTATTR9:
            return getDExtAttr9();
        case EXTENSIONID:
            return getExtensionId();
        case LASTUPDATEDBY:
            return getLastUpdatedBy();
        case LASTUPDATEDATE:
            return getLastUpdateDate();
        case LASTUPDATELOGIN:
            return getLastUpdateLogin();
        case NEXTATTR1:
            return getNExtAttr1();
        case NEXTATTR10:
            return getNExtAttr10();
        case NEXTATTR11:
            return getNExtAttr11();
        case NEXTATTR12:
            return getNExtAttr12();
        case NEXTATTR13:
            return getNExtAttr13();
        case NEXTATTR14:
            return getNExtAttr14();
        case NEXTATTR15:
            return getNExtAttr15();
        case NEXTATTR16:
            return getNExtAttr16();
        case NEXTATTR17:
            return getNExtAttr17();
        case NEXTATTR18:
            return getNExtAttr18();
        case NEXTATTR19:
            return getNExtAttr19();
        case NEXTATTR2:
            return getNExtAttr2();
        case NEXTATTR20:
            return getNExtAttr20();
        case NEXTATTR3:
            return getNExtAttr3();
        case NEXTATTR4:
            return getNExtAttr4();
        case NEXTATTR5:
            return getNExtAttr5();
        case NEXTATTR6:
            return getNExtAttr6();
        case NEXTATTR7:
            return getNExtAttr7();
        case NEXTATTR8:
            return getNExtAttr8();
        case NEXTATTR9:
            return getNExtAttr9();
        case ROWID:
            return getRowID();
        case LAST_UPDATED_BY_USER:
            return getLAST_UPDATED_BY_USER();
        default:
            return super.getAttrInvokeAccessor(index, attrDef);
        }
    }

    /**setAttrInvokeAccessor: generated method. Do not modify.
     */
    protected void setAttrInvokeAccessor(int index, Object value, 
                                         AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case ATTRGROUPID:
            setAttrGroupId((Number)value);
            return;
        case CREATEDBY:
            setCreatedBy((Number)value);
            return;
        case CREATIONDATE:
            setCreationDate((Date)value);
            return;
        case CUSTACCOUNTID:
            setCustAccountId((Number)value);
            return;
        case CEXTATTR1:
            setCExtAttr1((String)value);
            return;
        case CEXTATTR10:
            setCExtAttr10((String)value);
            return;
        case CEXTATTR11:
            setCExtAttr11((String)value);
            return;
        case CEXTATTR12:
            setCExtAttr12((String)value);
            return;
        case CEXTATTR13:
            setCExtAttr13((String)value);
            return;
        case CEXTATTR14:
            setCExtAttr14((String)value);
            return;
        case CEXTATTR15:
            setCExtAttr15((String)value);
            return;
        case CEXTATTR16:
            setCExtAttr16((String)value);
            return;
        case CEXTATTR17:
            setCExtAttr17((String)value);
            return;
        case CEXTATTR18:
            setCExtAttr18((String)value);
            return;
        case CEXTATTR19:
            setCExtAttr19((String)value);
            return;
        case CEXTATTR2:
            setCExtAttr2((String)value);
            return;
        case CEXTATTR20:
            setCExtAttr20((String)value);
            return;
        case CEXTATTR3:
            setCExtAttr3((String)value);
            return;
        case CEXTATTR4:
            setCExtAttr4((String)value);
            return;
        case CEXTATTR5:
            setCExtAttr5((String)value);
            return;
        case CEXTATTR6:
            setCExtAttr6((String)value);
            return;
        case CEXTATTR7:
            setCExtAttr7((String)value);
            return;
        case CEXTATTR8:
            setCExtAttr8((String)value);
            return;
        case CEXTATTR9:
            setCExtAttr9((String)value);
            return;
        case DEXTATTR1:
            setDExtAttr1((Date)value);
            return;
        case DEXTATTR10:
            setDExtAttr10((Date)value);
            return;
        case DEXTATTR2:
            setDExtAttr2((Date)value);
            return;
        case DEXTATTR3:
            setDExtAttr3((Date)value);
            return;
        case DEXTATTR4:
            setDExtAttr4((Date)value);
            return;
        case DEXTATTR5:
            setDExtAttr5((Date)value);
            return;
        case DEXTATTR6:
            setDExtAttr6((Date)value);
            return;
        case DEXTATTR7:
            setDExtAttr7((Date)value);
            return;
        case DEXTATTR8:
            setDExtAttr8((Date)value);
            return;
        case DEXTATTR9:
            setDExtAttr9((Date)value);
            return;
        case EXTENSIONID:
            setExtensionId((Number)value);
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
        case NEXTATTR1:
            setNExtAttr1((Number)value);
            return;
        case NEXTATTR10:
            setNExtAttr10((Number)value);
            return;
        case NEXTATTR11:
            setNExtAttr11((Number)value);
            return;
        case NEXTATTR12:
            setNExtAttr12((Number)value);
            return;
        case NEXTATTR13:
            setNExtAttr13((Number)value);
            return;
        case NEXTATTR14:
            setNExtAttr14((Number)value);
            return;
        case NEXTATTR15:
            setNExtAttr15((Number)value);
            return;
        case NEXTATTR16:
            setNExtAttr16((Number)value);
            return;
        case NEXTATTR17:
            setNExtAttr17((Number)value);
            return;
        case NEXTATTR18:
            setNExtAttr18((Number)value);
            return;
        case NEXTATTR19:
            setNExtAttr19((Number)value);
            return;
        case NEXTATTR2:
            setNExtAttr2((Number)value);
            return;
        case NEXTATTR20:
            setNExtAttr20((Number)value);
            return;
        case NEXTATTR3:
            setNExtAttr3((Number)value);
            return;
        case NEXTATTR4:
            setNExtAttr4((Number)value);
            return;
        case NEXTATTR5:
            setNExtAttr5((Number)value);
            return;
        case NEXTATTR6:
            setNExtAttr6((Number)value);
            return;
        case NEXTATTR7:
            setNExtAttr7((Number)value);
            return;
        case NEXTATTR8:
            setNExtAttr8((Number)value);
            return;
        case NEXTATTR9:
            setNExtAttr9((Number)value);
            return;
        default:
            super.setAttrInvokeAccessor(index, value, attrDef);
            return;
        }
    }

    /**Gets the attribute value for the calculated attribute LAST_UPDATED_BY_USER
     */
    public String getLAST_UPDATED_BY_USER() {
        return (String) getAttributeInternal(LAST_UPDATED_BY_USER);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute LAST_UPDATED_BY_USER
     */
    public void setLAST_UPDATED_BY_USER(String value) {
        setAttributeInternal(LAST_UPDATED_BY_USER, value);
    }

		  /**Gets the attribute value for the calculated attribute LastUpdateDateDisp
     */
    public String getLastUpdateDateDisp() {
        return (String) getAttributeInternal(LASTUPDATEDATEDISP);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute LastUpdateDateDisp
     */
    public void setLastUpdateDateDisp(String value) {
        setAttributeInternal(LASTUPDATEDATEDISP, value);
    }

 /**Gets the attribute value for the calculated attribute InitialCExtAttr1
     */
    public String getInitialCExtAttr1() {
        return (String) getAttributeInternal(INITIALCEXTATTR1);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute InitialCExtAttr1
     */
    public void setInitialCExtAttr1(String value) {
        setAttributeInternal(INITIALCEXTATTR1, value);
    }
}
