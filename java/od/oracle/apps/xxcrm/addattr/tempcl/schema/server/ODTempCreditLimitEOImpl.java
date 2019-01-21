 package od.oracle.apps.xxcrm.addattr.tempcl.schema.server;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;

import java.text.DateFormat;
import java.text.SimpleDateFormat;

import java.util.Calendar;

import od.oracle.apps.xxcrm.addattr.tempcl.schema.server.ODTempCrdLmtExpertEntity;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OARowValException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.server.OAEntityDefImpl;
import oracle.apps.fnd.framework.server.OAEntityImpl;

import oracle.jbo.AttributeList;
import oracle.jbo.Key;
import oracle.jbo.domain.Date;
//import java.util.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.TransactionEvent;

import oracle.jdbc.OracleCallableStatement;


/*
  --  Copyright (c) 2015, by Office Depot., All Rights Reserved
  --
  -- Author: Sridevi Kondoju
  -- Component Id: E0255 DEFECT34816
  -- Script Location:
             $CUSTOM_JAVA_TOP/od/oracle/apps/xxcrm/addattr/tempcl/schema/server
  -- Description: EO java file for XX_CDH_CUST_ACCT_EXT_B table. Used for
  --              Temporary Credit Limit
  -- Package Usage       : Unrestricted. Used for calling custom database package
  -- Name                  Type         Purpose
  -- --------------------  -----------  ------------------------------------------
  -- create               Void          Modified for initializing extension id.
  -- Notes:
  -- History:
  -- Name            Date         Version    Description
  -- -----           -----        -------    -----------
  -- Sridevi Kondoju 10-FEB-2016  1.0        Initial version
  --
  */

public class ODTempCreditLimitEOImpl extends OAEntityImpl {
    public static final int EXTENSIONID = 0;
    public static final int CUSTACCOUNTID = 1;
    public static final int ATTRGROUPID = 2;
    public static final int CREATEDBY = 3;
    public static final int CREATIONDATE = 4;
    public static final int LASTUPDATEDBY = 5;
    public static final int LASTUPDATEDATE = 6;
    public static final int LASTUPDATELOGIN = 7;
    public static final int CEXTATTR1 = 8;
    public static final int CEXTATTR2 = 9;
    public static final int CEXTATTR3 = 10;
    public static final int CEXTATTR4 = 11;
    public static final int CEXTATTR5 = 12;
    public static final int CEXTATTR6 = 13;
    public static final int CEXTATTR7 = 14;
    public static final int CEXTATTR8 = 15;
    public static final int CEXTATTR9 = 16;
    public static final int CEXTATTR10 = 17;
    public static final int CEXTATTR11 = 18;
    public static final int CEXTATTR12 = 19;
    public static final int CEXTATTR13 = 20;
    public static final int CEXTATTR14 = 21;
    public static final int CEXTATTR15 = 22;
    public static final int CEXTATTR16 = 23;
    public static final int CEXTATTR17 = 24;
    public static final int CEXTATTR18 = 25;
    public static final int CEXTATTR19 = 26;
    public static final int CEXTATTR20 = 27;
    public static final int NEXTATTR1 = 28;
    public static final int NEXTATTR2 = 29;
    public static final int NEXTATTR3 = 30;
    public static final int NEXTATTR4 = 31;
    public static final int NEXTATTR5 = 32;
    public static final int NEXTATTR6 = 33;
    public static final int NEXTATTR7 = 34;
    public static final int NEXTATTR8 = 35;
    public static final int NEXTATTR9 = 36;
    public static final int NEXTATTR10 = 37;
    public static final int NEXTATTR11 = 38;
    public static final int NEXTATTR12 = 39;
    public static final int NEXTATTR13 = 40;
    public static final int NEXTATTR14 = 41;
    public static final int NEXTATTR15 = 42;
    public static final int NEXTATTR16 = 43;
    public static final int NEXTATTR17 = 44;
    public static final int NEXTATTR18 = 45;
    public static final int NEXTATTR19 = 46;
    public static final int NEXTATTR20 = 47;
    public static final int DEXTATTR1 = 48;
    public static final int DEXTATTR2 = 49;
    public static final int DEXTATTR3 = 50;
    public static final int DEXTATTR4 = 51;
    public static final int DEXTATTR5 = 52;
    public static final int DEXTATTR6 = 53;
    public static final int DEXTATTR7 = 54;
    public static final int DEXTATTR8 = 55;
    public static final int DEXTATTR9 = 56;
    public static final int DEXTATTR10 = 57;


    private static OAEntityDefImpl mDefinitionObject;

    /**This is the default constructor (do not remove)
     */
    public ODTempCreditLimitEOImpl() {
    }


    /**Retrieves the definition object for this instance class.
     */
    public static synchronized EntityDefImpl getDefinitionObject() {
        if (mDefinitionObject == null) {
            mDefinitionObject = 
                    (OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxcrm.addattr.tempcl.schema.server.ODTempCreditLimitEO");
        }
        return mDefinitionObject;
    }

    /**Add attribute defaulting logic in this method.
     */
    public void create(AttributeList attributeList) {
        OADBTransaction trxn = (OADBTransaction)getDBTransaction();
        Number extId = trxn.getSequenceValue("EGO_EXTFWK_S");
        this.setExtensionId(extId);
        super.create(attributeList);
    }

    /**Add entity remove logic in this method.
     */
    public void remove() {
        super.remove();
    }
  // Deriving Expert Entity
    public static ODTempCrdLmtExpertEntity getODTempCrdLmtExpertEntity(OADBTransaction txn) 
             { 
               return (ODTempCrdLmtExpertEntity)txn.getExpert(ODTempCreditLimitEOImpl.getDefinitionObject());
               
             }
    /**Add Entity validation code in this method.
     */
    protected void validateEntity() {
        super.validateEntity();
        //  System.out.println("Validate Entity");
        OADBTransaction txn = (OADBTransaction)getOADBTransaction();
        txn.writeDiagnostics("XXOD:TempCreditLimit:ValidateEntity:", "Begin", 
                             1);
                             
        Date stdate = getDExtAttr1();
        Date enddate = getDExtAttr2();
        Number acctId  = getCustAccountId();
        Number acctProfileId    = getNExtAttr4();
        Number acctProfileAmtId = getNExtAttr1();
        Number attrgrpid        = getAttrGroupId();
        Date sysdate = txn.getCurrentDBDate();
    if (getEntityState()==0)//insert
        {
        if ((stdate.dateValue()).before(sysdate.dateValue())) {
            txn.writeDiagnostics("XXOD:TempCreditLimit:ValidateEntity", 
                                 "startdt exception", 1);
            throw // Message product short name
                new OARowValException(OARowValException.TYP_ENTITY_OBJECT, 
                                      getEntityDef().getFullName(), 
                                      getPrimaryKey(), "FND", 
                                      "FWK_TBX_T_START_DATE_INVALID"); // Message name 
        }


        if ((enddate != null)&&((enddate.dateValue()).before(sysdate.dateValue()))) {
            txn.writeDiagnostics("XXOD:TempCreditLimit:ValidateEntity", "enddt exception", 1);

            throw // Message product short name
                new OARowValException(OARowValException.TYP_ENTITY_OBJECT, 
                                      getEntityDef().getFullName(), 
                                      getPrimaryKey(), "FND", 
                                      "FWK_TBX_T_END_DATE_INVALID"); // Message name 
        }

  


        txn.writeDiagnostics("XXOD:TempCreditLimit:ValidateEntity","validating endate" + enddate, 1);


        if ((enddate != null)&&((stdate.dateValue()).after(enddate.dateValue()))) {
            txn.writeDiagnostics("XXOD:TempCreditLimit:ValidateEntity", 
                                 "start and end exception", 1);

            throw // Message product short name
                new OARowValException(OARowValException.TYP_ENTITY_OBJECT, 
                                      getEntityDef().getFullName(), 
                                      getPrimaryKey(), "FND", 
                                      "FWK_TBX_T_END_DATE_START_DATE"); // Message name 
        }
       //  Validation to make sure only one temporary credit limit exists 
         /*  if ( ((stdate.dateValue()).compareTo(sysdate.dateValue()) > 0)) 
           {
                
                        ODTempCrdLmtExpertEntity expert = getODTempCrdLmtExpertEntity(getOADBTransaction());
                            txn.writeDiagnostics("XXOD:TempCreditLimit:ValidateEntity", 
                                                              "Entityexpert", 1);
                        if (!(expert.TmpClExists(acctId,acctProfileId,acctProfileAmtId,attrgrpid,stdate,enddate)))                                                 
                           
                             {
                             txn.writeDiagnostics("XXOD:TempCreditLimit:ValidateEntity", 
                                                              "TmpClExists:False", 1);  
                             }                            
                            else {
                                         System.out.println("In validateEO if");
                                         throw // Message product short name
                                             new OARowValException(OARowValException.TYP_ENTITY_OBJECT, 
                                                                   getEntityDef().getFullName(), 
                                                                   getPrimaryKey(), "XXCRM", 
                                                                   "XX_CRM_TEMP_CREDIT_LMT_EXISTS");    

                                     }
                                     
           } */ //Validate                     
                                     

    } //if getentitystatus=0
    else 
    {
        if ( ((stdate.dateValue()).compareTo(sysdate.dateValue()) <= 0)&&((enddate.dateValue()).compareTo(sysdate.dateValue()) != 0)
        ) 
        {
            txn.writeDiagnostics("XXOD:TempCreditLimit:ValidateEntity", "enddt exception in update", 1);


            throw // Message product short name
                new OARowValException(OARowValException.TYP_ENTITY_OBJECT, 
                                      getEntityDef().getFullName(), 
                                      getPrimaryKey(), "XXCRM", 
                                      "XX_CRM_TMP_CR_LMT_END_DATE_VAL"); // Message name 
        }
         if (((stdate.dateValue()).compareTo(sysdate.dateValue()) > 0)&&((enddate.dateValue()).before(stdate.dateValue()))
         ) 
         {
                    txn.writeDiagnostics("XXOD:TempCreditLimit:ValidateEntity","start and end exception in update", 1);

                                           throw // Message product short name
                                               new OARowValException(OARowValException.TYP_ENTITY_OBJECT, 
                                                                     getEntityDef().getFullName(), 
                                                                     getPrimaryKey(), "FND", 
                                                                     "FWK_TBX_T_END_DATE_START_DATE"); // Message name 
         }
        
    } //else getentitystatus<>0
     //  Validation to make sure only one temporary credit limit exists 
      txn.writeDiagnostics("XXOD:TempCreditLimit:ValidateEntity:", "End", 
                           1);
 
    }
    /**Add locking logic here.
     */
    public void lock() {
        super.lock();
    }

    /**Custom DML update/insert/delete logic here.
     */
    protected void doDML(int operation, TransactionEvent e) {

        this.getOADBTransaction().writeDiagnostics("XXOD:  ODTempCreditLimitEO:doDML", 
                                                   "**********************Start****************" + 
                                                   this.getAttrGroupId(), 
                                                   OAFwkConstants.STATEMENT);


        if (operation == DML_INSERT) {
            if (this.getOADBTransaction().isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                this.getOADBTransaction().writeDiagnostics("XXOD:  ODTempCreditLimitEO :doDML", 
                                                           "INSERT", 
                                                           OAFwkConstants.STATEMENT);
            }
        }
        if (operation == DML_UPDATE) {
            if (this.getOADBTransaction().isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                this.getOADBTransaction().writeDiagnostics("XXOD: ODTempCreditLimitEO:doDML", 
                                                           "UPDATE", 
                                                           OAFwkConstants.STATEMENT);
            }
        }

        if (operation == DML_DELETE) {
            if (this.getOADBTransaction().isLoggingEnabled(OAFwkConstants.STATEMENT)) {
                this.getOADBTransaction().writeDiagnostics("XXOD:  ODTempCreditLimitEO:doDML", 
                                                           "DELETE", 
                                                           OAFwkConstants.STATEMENT);
            }
        }


        super.doDML(operation, e);
        this.getOADBTransaction().writeDiagnostics("XXOD:  ODTempCreditLimitEO:doDML", 
                                                   "**********************End****************" + 
                                                   this.getAttrGroupId(), 
                                                   OAFwkConstants.STATEMENT);

    }

    /**Gets the attribute value for ExtensionId, using the alias name ExtensionId
     */
    public Number getExtensionId() {
        return (Number)getAttributeInternal(EXTENSIONID);
    }

    /**Sets <code>value</code> as the attribute value for ExtensionId
     */
    public void setExtensionId(Number value) {
        setAttributeInternal(EXTENSIONID, value);
    }

    /**Gets the attribute value for CustAccountId, using the alias name CustAccountId
     */
    public Number getCustAccountId() {
        return (Number)getAttributeInternal(CUSTACCOUNTID);
    }

    /**Sets <code>value</code> as the attribute value for CustAccountId
     */
    public void setCustAccountId(Number value) {
        setAttributeInternal(CUSTACCOUNTID, value);
    }

    /**Gets the attribute value for AttrGroupId, using the alias name AttrGroupId
     */
    public Number getAttrGroupId() {
        return (Number)getAttributeInternal(ATTRGROUPID);
    }

    /**Sets <code>value</code> as the attribute value for AttrGroupId
     */
    public void setAttrGroupId(Number value) {
        setAttributeInternal(ATTRGROUPID, value);
    }

    /**Gets the attribute value for CreatedBy, using the alias name CreatedBy
     */
    public Number getCreatedBy() {
        return (Number)getAttributeInternal(CREATEDBY);
    }

    /**Sets <code>value</code> as the attribute value for CreatedBy
     */
    public void setCreatedBy(Number value) {
        setAttributeInternal(CREATEDBY, value);
    }

    /**Gets the attribute value for CreationDate, using the alias name CreationDate
     */
    public Date getCreationDate() {
        return (Date)getAttributeInternal(CREATIONDATE);
    }

    /**Sets <code>value</code> as the attribute value for CreationDate
     */
    public void setCreationDate(Date value) {
        setAttributeInternal(CREATIONDATE, value);
    }

    /**Gets the attribute value for LastUpdatedBy, using the alias name LastUpdatedBy
     */
    public Number getLastUpdatedBy() {
        return (Number)getAttributeInternal(LASTUPDATEDBY);
    }

    /**Sets <code>value</code> as the attribute value for LastUpdatedBy
     */
    public void setLastUpdatedBy(Number value) {
        setAttributeInternal(LASTUPDATEDBY, value);
    }

    /**Gets the attribute value for LastUpdateDate, using the alias name LastUpdateDate
     */
    public Date getLastUpdateDate() {
        return (Date)getAttributeInternal(LASTUPDATEDATE);
    }

    /**Sets <code>value</code> as the attribute value for LastUpdateDate
     */
    public void setLastUpdateDate(Date value) {
        setAttributeInternal(LASTUPDATEDATE, value);
    }

    /**Gets the attribute value for LastUpdateLogin, using the alias name LastUpdateLogin
     */
    public Number getLastUpdateLogin() {
        return (Number)getAttributeInternal(LASTUPDATELOGIN);
    }

    /**Sets <code>value</code> as the attribute value for LastUpdateLogin
     */
    public void setLastUpdateLogin(Number value) {
        setAttributeInternal(LASTUPDATELOGIN, value);
    }

    /**Gets the attribute value for CExtAttr1, using the alias name CExtAttr1
     */
    public String getCExtAttr1() {
        return (String)getAttributeInternal(CEXTATTR1);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr1
     */
    public void setCExtAttr1(String value) {
        setAttributeInternal(CEXTATTR1, value);
    }

    /**Gets the attribute value for CExtAttr2, using the alias name CExtAttr2
     */
    public String getCExtAttr2() {
        return (String)getAttributeInternal(CEXTATTR2);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr2
     */
    public void setCExtAttr2(String value) {
        setAttributeInternal(CEXTATTR2, value);
    }

    /**Gets the attribute value for CExtAttr3, using the alias name CExtAttr3
     */
    public String getCExtAttr3() {
        return (String)getAttributeInternal(CEXTATTR3);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr3
     */
    public void setCExtAttr3(String value) {
        setAttributeInternal(CEXTATTR3, value);
    }

    /**Gets the attribute value for CExtAttr4, using the alias name CExtAttr4
     */
    public String getCExtAttr4() {
        return (String)getAttributeInternal(CEXTATTR4);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr4
     */
    public void setCExtAttr4(String value) {
        setAttributeInternal(CEXTATTR4, value);
    }

    /**Gets the attribute value for CExtAttr5, using the alias name CExtAttr5
     */
    public String getCExtAttr5() {
        return (String)getAttributeInternal(CEXTATTR5);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr5
     */
    public void setCExtAttr5(String value) {
        setAttributeInternal(CEXTATTR5, value);
    }

    /**Gets the attribute value for CExtAttr6, using the alias name CExtAttr6
     */
    public String getCExtAttr6() {
        return (String)getAttributeInternal(CEXTATTR6);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr6
     */
    public void setCExtAttr6(String value) {
        setAttributeInternal(CEXTATTR6, value);
    }

    /**Gets the attribute value for CExtAttr7, using the alias name CExtAttr7
     */
    public String getCExtAttr7() {
        return (String)getAttributeInternal(CEXTATTR7);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr7
     */
    public void setCExtAttr7(String value) {
        setAttributeInternal(CEXTATTR7, value);
    }

    /**Gets the attribute value for CExtAttr8, using the alias name CExtAttr8
     */
    public String getCExtAttr8() {
        return (String)getAttributeInternal(CEXTATTR8);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr8
     */
    public void setCExtAttr8(String value) {
        setAttributeInternal(CEXTATTR8, value);
    }

    /**Gets the attribute value for CExtAttr9, using the alias name CExtAttr9
     */
    public String getCExtAttr9() {
        return (String)getAttributeInternal(CEXTATTR9);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr9
     */
    public void setCExtAttr9(String value) {
        setAttributeInternal(CEXTATTR9, value);
    }

    /**Gets the attribute value for CExtAttr10, using the alias name CExtAttr10
     */
    public String getCExtAttr10() {
        return (String)getAttributeInternal(CEXTATTR10);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr10
     */
    public void setCExtAttr10(String value) {
        setAttributeInternal(CEXTATTR10, value);
    }

    /**Gets the attribute value for CExtAttr11, using the alias name CExtAttr11
     */
    public String getCExtAttr11() {
        return (String)getAttributeInternal(CEXTATTR11);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr11
     */
    public void setCExtAttr11(String value) {
        setAttributeInternal(CEXTATTR11, value);
    }

    /**Gets the attribute value for CExtAttr12, using the alias name CExtAttr12
     */
    public String getCExtAttr12() {
        return (String)getAttributeInternal(CEXTATTR12);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr12
     */
    public void setCExtAttr12(String value) {
        setAttributeInternal(CEXTATTR12, value);
    }

    /**Gets the attribute value for CExtAttr13, using the alias name CExtAttr13
     */
    public String getCExtAttr13() {
        return (String)getAttributeInternal(CEXTATTR13);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr13
     */
    public void setCExtAttr13(String value) {
        setAttributeInternal(CEXTATTR13, value);
    }

    /**Gets the attribute value for CExtAttr14, using the alias name CExtAttr14
     */
    public String getCExtAttr14() {
        return (String)getAttributeInternal(CEXTATTR14);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr14
     */
    public void setCExtAttr14(String value) {
        setAttributeInternal(CEXTATTR14, value);
    }

    /**Gets the attribute value for CExtAttr15, using the alias name CExtAttr15
     */
    public String getCExtAttr15() {
        return (String)getAttributeInternal(CEXTATTR15);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr15
     */
    public void setCExtAttr15(String value) {
        setAttributeInternal(CEXTATTR15, value);
    }

    /**Gets the attribute value for CExtAttr16, using the alias name CExtAttr16
     */
    public String getCExtAttr16() {
        return (String)getAttributeInternal(CEXTATTR16);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr16
     */
    public void setCExtAttr16(String value) {
        setAttributeInternal(CEXTATTR16, value);
    }

    /**Gets the attribute value for CExtAttr17, using the alias name CExtAttr17
     */
    public String getCExtAttr17() {
        return (String)getAttributeInternal(CEXTATTR17);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr17
     */
    public void setCExtAttr17(String value) {
        setAttributeInternal(CEXTATTR17, value);
    }

    /**Gets the attribute value for CExtAttr18, using the alias name CExtAttr18
     */
    public String getCExtAttr18() {
        return (String)getAttributeInternal(CEXTATTR18);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr18
     */
    public void setCExtAttr18(String value) {
        setAttributeInternal(CEXTATTR18, value);
    }

    /**Gets the attribute value for CExtAttr19, using the alias name CExtAttr19
     */
    public String getCExtAttr19() {
        return (String)getAttributeInternal(CEXTATTR19);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr19
     */
    public void setCExtAttr19(String value) {
        setAttributeInternal(CEXTATTR19, value);
    }

    /**Gets the attribute value for CExtAttr20, using the alias name CExtAttr20
     */
    public String getCExtAttr20() {
        return (String)getAttributeInternal(CEXTATTR20);
    }

    /**Sets <code>value</code> as the attribute value for CExtAttr20
     */
    public void setCExtAttr20(String value) {
        setAttributeInternal(CEXTATTR20, value);
    }

    /**Gets the attribute value for NExtAttr1, using the alias name NExtAttr1
     */
    public Number getNExtAttr1() {
        return (Number)getAttributeInternal(NEXTATTR1);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr1
     */
    public void setNExtAttr1(Number value) {
        setAttributeInternal(NEXTATTR1, value);
    }

    /**Gets the attribute value for NExtAttr2, using the alias name NExtAttr2
     */
    public Number getNExtAttr2() {
        return (Number)getAttributeInternal(NEXTATTR2);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr2
     */
    public void setNExtAttr2(Number value) {
        setAttributeInternal(NEXTATTR2, value);
    }

    /**Gets the attribute value for NExtAttr3, using the alias name NExtAttr3
     */
    public Number getNExtAttr3() {
        return (Number)getAttributeInternal(NEXTATTR3);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr3
     */
    public void setNExtAttr3(Number value) {
        setAttributeInternal(NEXTATTR3, value);
    }

    /**Gets the attribute value for NExtAttr4, using the alias name NExtAttr4
     */
    public Number getNExtAttr4() {
        return (Number)getAttributeInternal(NEXTATTR4);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr4
     */
    public void setNExtAttr4(Number value) {
        setAttributeInternal(NEXTATTR4, value);
    }

    /**Gets the attribute value for NExtAttr5, using the alias name NExtAttr5
     */
    public Number getNExtAttr5() {
        return (Number)getAttributeInternal(NEXTATTR5);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr5
     */
    public void setNExtAttr5(Number value) {
        setAttributeInternal(NEXTATTR5, value);
    }

    /**Gets the attribute value for NExtAttr6, using the alias name NExtAttr6
     */
    public Number getNExtAttr6() {
        return (Number)getAttributeInternal(NEXTATTR6);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr6
     */
    public void setNExtAttr6(Number value) {
        setAttributeInternal(NEXTATTR6, value);
    }

    /**Gets the attribute value for NExtAttr7, using the alias name NExtAttr7
     */
    public Number getNExtAttr7() {
        return (Number)getAttributeInternal(NEXTATTR7);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr7
     */
    public void setNExtAttr7(Number value) {
        setAttributeInternal(NEXTATTR7, value);
    }

    /**Gets the attribute value for NExtAttr8, using the alias name NExtAttr8
     */
    public Number getNExtAttr8() {
        return (Number)getAttributeInternal(NEXTATTR8);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr8
     */
    public void setNExtAttr8(Number value) {
        setAttributeInternal(NEXTATTR8, value);
    }

    /**Gets the attribute value for NExtAttr9, using the alias name NExtAttr9
     */
    public Number getNExtAttr9() {
        return (Number)getAttributeInternal(NEXTATTR9);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr9
     */
    public void setNExtAttr9(Number value) {
        setAttributeInternal(NEXTATTR9, value);
    }

    /**Gets the attribute value for NExtAttr10, using the alias name NExtAttr10
     */
    public Number getNExtAttr10() {
        return (Number)getAttributeInternal(NEXTATTR10);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr10
     */
    public void setNExtAttr10(Number value) {
        setAttributeInternal(NEXTATTR10, value);
    }

    /**Gets the attribute value for NExtAttr11, using the alias name NExtAttr11
     */
    public Number getNExtAttr11() {
        return (Number)getAttributeInternal(NEXTATTR11);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr11
     */
    public void setNExtAttr11(Number value) {
        setAttributeInternal(NEXTATTR11, value);
    }

    /**Gets the attribute value for NExtAttr12, using the alias name NExtAttr12
     */
    public Number getNExtAttr12() {
        return (Number)getAttributeInternal(NEXTATTR12);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr12
     */
    public void setNExtAttr12(Number value) {
        setAttributeInternal(NEXTATTR12, value);
    }

    /**Gets the attribute value for NExtAttr13, using the alias name NExtAttr13
     */
    public Number getNExtAttr13() {
        return (Number)getAttributeInternal(NEXTATTR13);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr13
     */
    public void setNExtAttr13(Number value) {
        setAttributeInternal(NEXTATTR13, value);
    }

    /**Gets the attribute value for NExtAttr14, using the alias name NExtAttr14
     */
    public Number getNExtAttr14() {
        return (Number)getAttributeInternal(NEXTATTR14);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr14
     */
    public void setNExtAttr14(Number value) {
        setAttributeInternal(NEXTATTR14, value);
    }

    /**Gets the attribute value for NExtAttr15, using the alias name NExtAttr15
     */
    public Number getNExtAttr15() {
        return (Number)getAttributeInternal(NEXTATTR15);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr15
     */
    public void setNExtAttr15(Number value) {
        setAttributeInternal(NEXTATTR15, value);
    }

    /**Gets the attribute value for NExtAttr16, using the alias name NExtAttr16
     */
    public Number getNExtAttr16() {
        return (Number)getAttributeInternal(NEXTATTR16);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr16
     */
    public void setNExtAttr16(Number value) {
        setAttributeInternal(NEXTATTR16, value);
    }

    /**Gets the attribute value for NExtAttr17, using the alias name NExtAttr17
     */
    public Number getNExtAttr17() {
        return (Number)getAttributeInternal(NEXTATTR17);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr17
     */
    public void setNExtAttr17(Number value) {
        setAttributeInternal(NEXTATTR17, value);
    }

    /**Gets the attribute value for NExtAttr18, using the alias name NExtAttr18
     */
    public Number getNExtAttr18() {
        return (Number)getAttributeInternal(NEXTATTR18);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr18
     */
    public void setNExtAttr18(Number value) {
        setAttributeInternal(NEXTATTR18, value);
    }

    /**Gets the attribute value for NExtAttr19, using the alias name NExtAttr19
     */
    public Number getNExtAttr19() {
        return (Number)getAttributeInternal(NEXTATTR19);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr19
     */
    public void setNExtAttr19(Number value) {
        setAttributeInternal(NEXTATTR19, value);
    }

    /**Gets the attribute value for NExtAttr20, using the alias name NExtAttr20
     */
    public Number getNExtAttr20() {
        return (Number)getAttributeInternal(NEXTATTR20);
    }

    /**Sets <code>value</code> as the attribute value for NExtAttr20
     */
    public void setNExtAttr20(Number value) {
        setAttributeInternal(NEXTATTR20, value);
    }

    /**Gets the attribute value for DExtAttr1, using the alias name DExtAttr1
     */
    public Date getDExtAttr1() {
        return (Date)getAttributeInternal(DEXTATTR1);
    }

    /**Sets <code>value</code> as the attribute value for DExtAttr1
     */
    public void setDExtAttr1(Date value) {
    
        setAttributeInternal(DEXTATTR1, value);
    }

    /**Gets the attribute value for DExtAttr2, using the alias name DExtAttr2
     */
    public Date getDExtAttr2() {
        return (Date)getAttributeInternal(DEXTATTR2);
    }

    /**Sets <code>value</code> as the attribute value for DExtAttr2
     */
   public void setDExtAttr2(Date value) {
        setAttributeInternal(DEXTATTR2,value );
    }

    /**Gets the attribute value for DExtAttr3, using the alias name DExtAttr3
     */
    public Date getDExtAttr3() {
        return (Date)getAttributeInternal(DEXTATTR3);
    }

    /**Sets <code>value</code> as the attribute value for DExtAttr3
     */
    public void setDExtAttr3(Date value) {
        setAttributeInternal(DEXTATTR3, value);
    }

    /**Gets the attribute value for DExtAttr4, using the alias name DExtAttr4
     */
    public Date getDExtAttr4() {
        return (Date)getAttributeInternal(DEXTATTR4);
    }

    /**Sets <code>value</code> as the attribute value for DExtAttr4
     */
    public void setDExtAttr4(Date value) {
        setAttributeInternal(DEXTATTR4, value);
    }

    /**Gets the attribute value for DExtAttr5, using the alias name DExtAttr5
     */
    public Date getDExtAttr5() {
        return (Date)getAttributeInternal(DEXTATTR5);
    }

    /**Sets <code>value</code> as the attribute value for DExtAttr5
     */
    public void setDExtAttr5(Date value) {
        setAttributeInternal(DEXTATTR5, value);
    }

    /**Gets the attribute value for DExtAttr6, using the alias name DExtAttr6
     */
    public Date getDExtAttr6() {
        return (Date)getAttributeInternal(DEXTATTR6);
    }

    /**Sets <code>value</code> as the attribute value for DExtAttr6
     */
    public void setDExtAttr6(Date value) {
        setAttributeInternal(DEXTATTR6, value);
    }

    /**Gets the attribute value for DExtAttr7, using the alias name DExtAttr7
     */
    public Date getDExtAttr7() {
        return (Date)getAttributeInternal(DEXTATTR7);
    }

    /**Sets <code>value</code> as the attribute value for DExtAttr7
     */
    public void setDExtAttr7(Date value) {
        setAttributeInternal(DEXTATTR7, value);
    }

    /**Gets the attribute value for DExtAttr8, using the alias name DExtAttr8
     */
    public Date getDExtAttr8() {
        return (Date)getAttributeInternal(DEXTATTR8);
    }

    /**Sets <code>value</code> as the attribute value for DExtAttr8
     */
    public void setDExtAttr8(Date value) {
        setAttributeInternal(DEXTATTR8, value);
    }

    /**Gets the attribute value for DExtAttr9, using the alias name DExtAttr9
     */
    public Date getDExtAttr9() {
        return (Date)getAttributeInternal(DEXTATTR9);
    }

    /**Sets <code>value</code> as the attribute value for DExtAttr9
     */
    public void setDExtAttr9(Date value) {
        setAttributeInternal(DEXTATTR9, value);
    }

    /**Gets the attribute value for DExtAttr10, using the alias name DExtAttr10
     */
    public Date getDExtAttr10() {
        return (Date)getAttributeInternal(DEXTATTR10);
    }

    /**Sets <code>value</code> as the attribute value for DExtAttr10
     */
    public void setDExtAttr10(Date value) {
        setAttributeInternal(DEXTATTR10, value);
    }

    /**getAttrInvokeAccessor: generated method. Do not modify.
     */
    protected Object getAttrInvokeAccessor(int index, 
                                           AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case EXTENSIONID:
            return getExtensionId();
        case CUSTACCOUNTID:
            return getCustAccountId();
        case ATTRGROUPID:
            return getAttrGroupId();
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
        case CEXTATTR1:
            return getCExtAttr1();
        case CEXTATTR2:
            return getCExtAttr2();
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
        case CEXTATTR20:
            return getCExtAttr20();
        case NEXTATTR1:
            return getNExtAttr1();
        case NEXTATTR2:
            return getNExtAttr2();
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
        case NEXTATTR20:
            return getNExtAttr20();
        case DEXTATTR1:
            return getDExtAttr1();
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
        case DEXTATTR10:
            return getDExtAttr10();
        default:
            return super.getAttrInvokeAccessor(index, attrDef);
        }
    }

    /**setAttrInvokeAccessor: generated method. Do not modify.
     */
    protected void setAttrInvokeAccessor(int index, Object value, 
                                         AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case EXTENSIONID:
            setExtensionId((Number)value);
            return;
        case CUSTACCOUNTID:
            setCustAccountId((Number)value);
            return;
        case ATTRGROUPID:
            setAttrGroupId((Number)value);
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
        case CEXTATTR1:
            setCExtAttr1((String)value);
            return;
        case CEXTATTR2:
            setCExtAttr2((String)value);
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
        case CEXTATTR20:
            setCExtAttr20((String)value);
            return;
        case NEXTATTR1:
            setNExtAttr1((Number)value);
            return;
        case NEXTATTR2:
            setNExtAttr2((Number)value);
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
        case NEXTATTR20:
            setNExtAttr20((Number)value);
            return;
        case DEXTATTR1:
            setDExtAttr1((Date)value);
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
        case DEXTATTR10:
            setDExtAttr10((Date)value);
            return;
        default:
            super.setAttrInvokeAccessor(index, value, attrDef);
            return;
        }
    }

   /* public String getDatetime(Date x_in) {
        String DATE_FORMAT_NOW = "yyyy-MM-dd";
        Calendar cal = Calendar.getInstance();
        SimpleDateFormat sdf = new SimpleDateFormat(DATE_FORMAT_NOW);
        return sdf.format(cal.getTime());
    } */

    protected void prepareForDML(int dml, TransactionEvent evt) {

        this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML", 
                                                   "Begin" + 
                                                   this.getExtensionId(), 
                                                   OAFwkConstants.STATEMENT);

        super.prepareForDML(dml, evt);
        
        OADBTransaction txn = (OADBTransaction)getOADBTransaction();
        
        Date stdate = getDExtAttr1();
        Date enddate = getDExtAttr2();
        Date sysdate = (Date)txn.getCurrentDBDate();
        Number acctId  = getCustAccountId();
        Number acctProfileId    = getNExtAttr4();
        Number acctProfileAmtId = getNExtAttr1();
        Number attrgrpid        = getAttrGroupId();
        Number extid =getExtensionId();
        
     
                
    if ((dml == DML_INSERT)) {
       
        // Formating dates
         if ((enddate.dateValue()).compareTo(sysdate.dateValue()) >= 0)
                   {
                    Date edate =getDatetime(enddate);
                    this.setDExtAttr2(edate);
                          txn.writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML:",  "DExtAttr2:"+edate, 1);
                    }
                    
        if ( ((stdate.dateValue()).compareTo(sysdate.dateValue()) == 0)) 
                    {
                        this.setDExtAttr1(sysdate);
                     }
            
            
            ODTempCrdLmtExpertEntity expert = getODTempCrdLmtExpertEntity(getOADBTransaction());
            txn.writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML:",  "Entityexpert", 1);
            
                 Date sdate = getDExtAttr1();
                 Date edate1 = getDExtAttr2();
          
          //Validation to make sure only one Active temporary credit limit exists 
            if (!(expert.TmpClExists(acctId, acctProfileId, acctProfileAmtId, 
                                     attrgrpid, sdate, edate1))) {
                 txn.writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML:", "TmpClExists:False", 1);
            } else {
                throw new OAException("Temporary credit limit exists for the entered date range.Press cancel to proceed.", OAException.ERROR);
               /* throw new OAException("Temporary credit limit exists between the given date range " + stdate.toString().substring(0,10) 
                + " and " +enddate.toString().substring(0,10), 
                                      OAException.ERROR);*/


            }


           if ( ((stdate.dateValue()).compareTo(sysdate.dateValue()) == 0)) 
            {
             // Call procedure to update Profile Amounts
            String validateQry = 
                " BEGIN   xx_cdh_tmp_crd_lmt_pkg.update_profile_amount (:1, :2, :3, :4, :5,:6); END;";

            OracleCallableStatement callableStatement = null;
            Connection conn;
            int ln_retcode = 0;
            String lc_errmsg = "";
            int ln_crlimit;
            this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML", 
                                                       "Step 10.10", 
                                                       OAFwkConstants.STATEMENT);

            try {
                conn = this.getOADBTransaction().getJdbcConnection();

                this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML", 
                                                           "Step 10.20", 
                                                           OAFwkConstants.STATEMENT);

                callableStatement = 
                        (OracleCallableStatement)conn.prepareCall(validateQry);

                this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML", 
                                                           "Step 10.30", 
                                                           OAFwkConstants.STATEMENT);


                callableStatement.registerOutParameter(1, Types.VARCHAR);
                callableStatement.registerOutParameter(2, Types.NUMERIC);
                callableStatement.setInt(3, getNExtAttr1().intValue());
                callableStatement.setInt(4, getNExtAttr2().intValue());
                callableStatement.registerOutParameter(5, Types.NUMERIC);
                callableStatement.setString(6, "INSERT");


                callableStatement.execute();

                lc_errmsg = callableStatement.getString(1);
                ln_retcode = callableStatement.getInt(2);
                ln_crlimit = callableStatement.getInt(5);

                this.getOADBTransaction().writeDiagnostics("XXOD: TempCredit Limit EO:prepareForDML", 
                                                           "Step 10.40", 
                                                           OAFwkConstants.STATEMENT);


                this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML", 
                                                           "Step 10.50 " + 
                                                           lc_errmsg + " " + 
                                                           ln_retcode + ":" + 
                                                           ln_crlimit, 
                                                           OAFwkConstants.STATEMENT);


                if (ln_retcode == 0) {
                    Number num = new Number(ln_crlimit);
                    this.setNExtAttr3(num);
                    this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML", 
                                                               lc_errmsg,
                                                               OAFwkConstants.STATEMENT);
                } else {
                    throw new OAException("Error while updating profile amount ."+lc_errmsg, OAException.ERROR);
                }

            } //try end
            catch (SQLException e) {

                this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML", 
                                                           "Step 10.60", 
                                                           OAFwkConstants.STATEMENT);

                throw new OAException("Error during SQL Operation");
            } finally {
            
                try {
                    if (callableStatement != null)
                        callableStatement.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
                
            }

            this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML Insert", 
                                                       "**********************End****************" + 
                                                       this.getAttrGroupId(), 
                                                       OAFwkConstants.STATEMENT);

        }
    }
        
        if (dml == DML_UPDATE) {
        
            if ((enddate.dateValue()).compareTo(sysdate.dateValue()) > 0)
                  { 
                     Date edate = getDatetime(enddate);
                     this.setDExtAttr2(edate);
                        }
                        
            if ((enddate.dateValue()).compareTo(sysdate.dateValue()) == 0) 
                 {
                //Setting Enddate with timestamp
                 this.setDExtAttr2(sysdate);
                  }
        
            ODTempCrdLmtExpertEntity expert = getODTempCrdLmtExpertEntity(getOADBTransaction());
            txn.writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML:", "Entityexpert", 1);

            Date sdate = getDExtAttr1();
            Date edate1 = getDExtAttr2();
            //Validation to make sure only one Active temporary credit limit exists 
            if (!(expert.TmpClExists(acctId, acctProfileId, acctProfileAmtId, 
                                     attrgrpid, sdate, edate1,extid))) {
                 txn.writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML:", "TmpClExists:False", 1);
            } else {
                throw new OAException("Temporary credit limit exists for the enetered date range.Press cancel to proceed.", OAException.ERROR);
            }
        
        if ((enddate.dateValue()).compareTo(sysdate.dateValue()) == 0) {
            //Call to the procedure to update Profile Amounts
            String validateQry = 
                " BEGIN   xx_cdh_tmp_crd_lmt_pkg.update_profile_amount (:1, :2, :3, :4, :5,:6); END;";

            OracleCallableStatement callableStatement = null;
            Connection conn;
            int ln_retcode = 0;
            String lc_errmsg = "";
            
            this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDMLUpdate", 
                                                       "Step 11.10", 
                                                       OAFwkConstants.STATEMENT);

            try {
                conn = this.getOADBTransaction().getJdbcConnection();

                this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDMLUpdate", 
                                                           "Step 11.20", 
                                                           OAFwkConstants.STATEMENT);

                callableStatement = 
                        (OracleCallableStatement)conn.prepareCall(validateQry);

                this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDMLUpdate", 
                                                           "Step 11.30", 
                                                           OAFwkConstants.STATEMENT);


                callableStatement.registerOutParameter(1, Types.VARCHAR);
                callableStatement.registerOutParameter(2, Types.NUMERIC);

                callableStatement.setInt(3, getNExtAttr1().intValue());
                callableStatement.setInt(4, getNExtAttr3().intValue());
                callableStatement.registerOutParameter(5, Types.NUMERIC);
                callableStatement.setString(6, "UPDATE");


                callableStatement.execute();

                lc_errmsg = callableStatement.getString(1);
                ln_retcode = callableStatement.getInt(2);
                

                this.getOADBTransaction().writeDiagnostics("XXOD: TempCredit Limit EO:prepareForDMLUpdate", 
                                                           "Step 11.40", 
                                                           OAFwkConstants.STATEMENT);


                this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDMLUpdate", 
                                                           "Step 11.50 " + 
                                                           lc_errmsg + " " + 
                                                           ln_retcode ,
                                                           OAFwkConstants.STATEMENT);


                if (ln_retcode == 0) {
                    //updating c_ext_attr3 when users updates an existing credit limit to sysdate 
                    this.setCExtAttr3("Y");
                    this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML", 
                                                               lc_errmsg,
                                                               OAFwkConstants.STATEMENT);
                } else {
                    throw new OAException("Error while updating profile amount."+lc_errmsg, OAException.ERROR);
                }

            } //try end
            catch (SQLException e) {

                this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDMLUpdate", 
                                                           "Step 11.60", 
                                                           OAFwkConstants.STATEMENT);

                throw new OAException("Error during SQL Operation");
            } finally {
            
                try {
                    if (callableStatement != null)
                        callableStatement.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
                
            }

            this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDMLUpdate", 
                                                       "**********************End****************" + 
                                                       this.getAttrGroupId(), 
                                                       OAFwkConstants.STATEMENT);

        }

        
        }
        this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:prepareForDML", 
                                                   "End" + 
                                                   this.getExtensionId(), 
                                                   OAFwkConstants.STATEMENT);
    }

public Date getDatetime(Date edate) {
    
    String validateQry =  " BEGIN   xx_cdh_tmp_crd_lmt_pkg.format_date (:1, :2, :3, :4, :5); END;";

    OracleCallableStatement callableStatement = null;
    Connection conn;
    int ln_retcode = 0;
    String lc_errmsg = "";
    Date ld_date =new Date();//null;
    Date endate;
    Timestamp ld_edate;

    this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:getDatetime", 
                                               "Begin ", 
                                               OAFwkConstants.STATEMENT);

    try {
          conn = this.getOADBTransaction().getJdbcConnection();

        this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:getDatetime", 
                                                   "Step 12.10", 
                                                   OAFwkConstants.STATEMENT);

        callableStatement = (OracleCallableStatement)conn.prepareCall(validateQry);

        callableStatement.setString(1, "INSERT");
        callableStatement.setString(2, edate.toString());
        callableStatement.registerOutParameter(3, Types.DATE);
        callableStatement.registerOutParameter(4, Types.VARCHAR);
        callableStatement.registerOutParameter(5, Types.NUMERIC);
        
         callableStatement.execute();

        lc_errmsg = callableStatement.getString(4);
        ln_retcode = callableStatement.getInt(5);
        ld_edate =   callableStatement.getTimestamp(3);  
     if (ln_retcode == 0) {
           endate = ld_date.toDate(ld_edate.toString());
            
        } else {
            throw new OAException(lc_errmsg, OAException.ERROR);
        }
        this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:getDatetime", 
                                                   "Return Date :"+endate, 
                                                   OAFwkConstants.STATEMENT);
        
        this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:getDatetime", 
                                                   "End", 
                                                   OAFwkConstants.STATEMENT);
       return endate;
       
    } //try end
    catch (SQLException e) {

        this.getOADBTransaction().writeDiagnostics("XXOD: TempCreditLimit EO:getDatetimL", 
                                                   "Step 10.100", 
                                                   OAFwkConstants.STATEMENT);

         throw new OAException("Error during SQL Operation");
    } finally {
    
        try {
            if (callableStatement != null)
                callableStatement.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
    }
    }

    /**Creates a Key object based on given key constituents
     */
    public static Key createPrimaryKey(Number extensionId) {
        return new Key(new Object[]{extensionId});
    }
    
   
}
