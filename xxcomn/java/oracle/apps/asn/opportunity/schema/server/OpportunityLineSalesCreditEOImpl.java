package oracle.apps.asn.opportunity.schema.server;

import oracle.apps.asn.common.fwk.server.ASNEntityImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.server.*;
import oracle.jbo.AttributeList;
import oracle.jbo.Key;
import oracle.jbo.common.MetaObjectBase;
import oracle.jbo.common.NamedObjectImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.*;
import oracle.sql.NUMBER;

// Referenced classes of package oracle.apps.asn.opportunity.schema.server:
//            OpportunityEOImpl, OpportunityExpert, OpportunityLineEOImpl

public class OpportunityLineSalesCreditEOImpl extends ASNEntityImpl
{

    protected static final int SALESCREDITID = 0;
    protected static final int LASTUPDATEDATE = 1;
    protected static final int LASTUPDATEDBY = 2;
    protected static final int CREATIONDATE = 3;
    protected static final int CREATEDBY = 4;
    protected static final int LASTUPDATELOGIN = 5;
    protected static final int REQUESTID = 6;
    protected static final int PROGRAMAPPLICATIONID = 7;
    protected static final int PROGRAMID = 8;
    protected static final int PROGRAMUPDATEDATE = 9;
    protected static final int LEADID = 10;
    protected static final int LEADLINEID = 11;
    protected static final int SALESFORCEID = 12;
    protected static final int SALESGROUPID = 13;
    protected static final int ATTRIBUTECATEGORY = 14;
    protected static final int ATTRIBUTE1 = 15;
    protected static final int ATTRIBUTE2 = 16;
    protected static final int ATTRIBUTE3 = 17;
    protected static final int ATTRIBUTE4 = 18;
    protected static final int ATTRIBUTE5 = 19;
    protected static final int ATTRIBUTE6 = 20;
    protected static final int ATTRIBUTE7 = 21;
    protected static final int ATTRIBUTE8 = 22;
    protected static final int ATTRIBUTE9 = 23;
    protected static final int ATTRIBUTE10 = 24;
    protected static final int ATTRIBUTE11 = 25;
    protected static final int ATTRIBUTE12 = 26;
    protected static final int ATTRIBUTE13 = 27;
    protected static final int ATTRIBUTE14 = 28;
    protected static final int ATTRIBUTE15 = 29;
    protected static final int CREDITTYPEID = 30;
    protected static final int CREDITPERCENT = 31;
    protected static final int CREDITAMOUNT = 32;
    protected static final int OPPWORSTFORECASTAMOUNT = 33;
    protected static final int OPPFORECASTAMOUNT = 34;
    protected static final int OPPBESTFORECASTAMOUNT = 35;
    protected static final int OBJECTVERSIONNUMBER = 36;
    protected static final int PERSONID = 37;
    protected static final int DEFAULTEDFROMOWNERFLAG = 38;
    protected static final int OPPORTUNITYLINEEO = 39;
    public static final String RCS_ID = "$Header: OpportunityLineSalesCreditEOImpl.java 115.18 2005/03/14 23:21:59 ujayar" +
"am ship $"
;
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: OpportunityLineSalesCreditEOImpl.java 115.18 2005/03/14 23:21:59 ujayar" +
"am ship $"
, "oracle.apps.asn.opportunity.schema.server");
    private static OAEntityDefImpl mDefinitionObject;

    public OpportunityLineSalesCreditEOImpl()
    {
    }

    public static synchronized EntityDefImpl getDefinitionObject()
    {
        if(mDefinitionObject == null)
        {
            mDefinitionObject = (OAEntityDefImpl)EntityDefImpl.findDefObject("oracle.apps.asn.opportunity.schema.server.OpportunityLineSalesCreditEO");
        }
        return mDefinitionObject;
    }

    public Number getSalesCreditId()
    {
        return (Number)getAttributeInternal(0);
    }

    public void setSalesCreditId(Number number)
    {
        setAttributeInternal(0, number);
    }

    public Date getLastUpdateDate()
    {
        return (Date)getAttributeInternal(1);
    }

    public void setLastUpdateDate(Date date)
    {
        setAttributeInternal(1, date);
    }

    public Number getLastUpdatedBy()
    {
        return (Number)getAttributeInternal(2);
    }

    public void setLastUpdatedBy(Number number)
    {
        setAttributeInternal(2, number);
    }

    public Date getCreationDate()
    {
        return (Date)getAttributeInternal(3);
    }

    public void setCreationDate(Date date)
    {
        setAttributeInternal(3, date);
    }

    public Number getCreatedBy()
    {
        return (Number)getAttributeInternal(4);
    }

    public void setCreatedBy(Number number)
    {
        setAttributeInternal(4, number);
    }

    public Number getLastUpdateLogin()
    {
        return (Number)getAttributeInternal(5);
    }

    public void setLastUpdateLogin(Number number)
    {
        setAttributeInternal(5, number);
    }

    public Number getRequestId()
    {
        return (Number)getAttributeInternal(6);
    }

    public void setRequestId(Number number)
    {
        setAttributeInternal(6, number);
    }

    public Number getProgramApplicationId()
    {
        return (Number)getAttributeInternal(7);
    }

    public void setProgramApplicationId(Number number)
    {
        setAttributeInternal(7, number);
    }

    public Number getProgramId()
    {
        return (Number)getAttributeInternal(8);
    }

    public void setProgramId(Number number)
    {
        setAttributeInternal(8, number);
    }

    public Date getProgramUpdateDate()
    {
        return (Date)getAttributeInternal(9);
    }

    public void setProgramUpdateDate(Date date)
    {
        setAttributeInternal(9, date);
    }

    public Number getLeadId()
    {
        return (Number)getAttributeInternal(10);
    }

    public void setLeadId(Number number)
    {
        setAttributeInternal(10, number);
    }

    public Number getLeadLineId()
    {
        return (Number)getAttributeInternal(11);
    }

    public void setLeadLineId(Number number)
    {
        setAttributeInternal(11, number);
    }

    public Number getSalesforceId()
    {
        return (Number)getAttributeInternal(12);
    }

    public void setSalesforceId(Number number)
    {
        String s = "asn.opportunity.schema.server.OpportunityLineSalesCreditEOImpl.setSalesforceId";
        OADBTransaction oadbtransaction = getOADBTransaction();
        OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(OpportunityEOImpl.getDefinitionObject());
        if(!opportunityexpert.isResourceIdValid(number))
        {
            if(oadbtransaction.isLoggingEnabled(4))
            {
                StringBuffer stringbuffer = (new StringBuffer(100)).append("invalid SalesforceId: ").append(number);
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                stringbuffer = null;
            }
            /*
            Commented by Vasan for defect 5749.
            Ignore this validation as resource Id is picked from custom view.(not from AS_ACCESS_ALL)
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "SalesforceId", number, "ASN", "ASN_CMMN_RSC_INV_ERR");
            */
        } else
        {
            setAttributeInternal(12, number);
            Number number1 = opportunityexpert.getEmployeeId(number);
            setPersonId(number1);
            return;
        }
    }

    public Number getSalesgroupId()
    {
        return (Number)getAttributeInternal(13);
    }

    public void setSalesgroupId(Number number)
    {
        setAttributeInternal(13, number);
    }

    public String getAttributeCategory()
    {
        return (String)getAttributeInternal(14);
    }

    public void setAttributeCategory(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(14, s);
    }

    public String getAttribute1()
    {
        return (String)getAttributeInternal(15);
    }

    public void setAttribute1(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(15, s);
    }

    public String getAttribute2()
    {
        return (String)getAttributeInternal(16);
    }

    public void setAttribute2(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(16, s);
    }

    public String getAttribute3()
    {
        return (String)getAttributeInternal(17);
    }

    public void setAttribute3(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(17, s);
    }

    public String getAttribute4()
    {
        return (String)getAttributeInternal(18);
    }

    public void setAttribute4(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(18, s);
    }

    public String getAttribute5()
    {
        return (String)getAttributeInternal(19);
    }

    public void setAttribute5(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(19, s);
    }

    public String getAttribute6()
    {
        return (String)getAttributeInternal(20);
    }

    public void setAttribute6(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(20, s);
    }

    public String getAttribute7()
    {
        return (String)getAttributeInternal(21);
    }

    public void setAttribute7(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(21, s);
    }

    public String getAttribute8()
    {
        return (String)getAttributeInternal(22);
    }

    public void setAttribute8(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(22, s);
    }

    public String getAttribute9()
    {
        return (String)getAttributeInternal(23);
    }

    public void setAttribute9(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(23, s);
    }

    public String getAttribute10()
    {
        return (String)getAttributeInternal(24);
    }

    public void setAttribute10(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(24, s);
    }

    public String getAttribute11()
    {
        return (String)getAttributeInternal(25);
    }

    public void setAttribute11(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(25, s);
    }

    public String getAttribute12()
    {
        return (String)getAttributeInternal(26);
    }

    public void setAttribute12(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(26, s);
    }

    public String getAttribute13()
    {
        return (String)getAttributeInternal(27);
    }

    public void setAttribute13(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(27, s);
    }

    public String getAttribute14()
    {
        return (String)getAttributeInternal(28);
    }

    public void setAttribute14(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(28, s);
    }

    public String getAttribute15()
    {
        return (String)getAttributeInternal(29);
    }

    public void setAttribute15(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        setAttributeInternal(29, s);
    }

    public Number getCreditTypeId()
    {
        return (Number)getAttributeInternal(30);
    }

    public void setCreditTypeId(Number number)
    {
        String s = "asn.opportunity.schema.server.OpportunityLineSalesCreditEOImpl.setCreditTypeId";
        OADBTransaction oadbtransaction = getOADBTransaction();
        OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(OpportunityEOImpl.getDefinitionObject());
        if(!opportunityexpert.isSalesCreditTypeIdValid(number))
        {
            if(oadbtransaction.isLoggingEnabled(4))
            {
                StringBuffer stringbuffer = (new StringBuffer(25)).append("invalid CreditTypeId:").append(number);
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                stringbuffer = null;
            }
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CreditTypeId", number, "ASN", "ASN_OPPTY_SLSCRDTTYPE_INV_ERR");
        } else
        {
            setAttributeInternal(30, number);
            return;
        }
    }

    public Number getCreditPercent()
    {
        return (Number)getAttributeInternal(31);
    }

    public void setCreditPercent(Number number)
    {
        String s = "asn.opportunity.schema.server.OpportunityLineSalesCreditEOImpl.setCreditPercent";
        OADBTransaction oadbtransaction = getOADBTransaction();
        if(number == null || number.compareTo(new Number(0)) <= 0)
        {
            if(oadbtransaction.isLoggingEnabled(4))
            {
                StringBuffer stringbuffer = (new StringBuffer(25)).append("invalid CreditPercent:").append(number);
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                stringbuffer = null;
            }
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CreditPercent", number, "ASN", "ASN_OPPTY_SLSCRDTPCT_INV_ERR");
        }
        setAttributeInternal(31, number);
        Number number1 = getOpportunityLineEO().getTotalAmount();
        if(number1 == null)
        {
            number1 = new Number(0);
        }
        Number number2 = number1.multiply(number).divide(new Number(100));
        if(oadbtransaction.isLoggingEnabled(1))
        {
            StringBuffer stringbuffer1 = (new StringBuffer(25)).append("setting new CreditAmount:").append(number2);
            oadbtransaction.writeDiagnostics(s, stringbuffer1.toString(), 1);
            stringbuffer1 = null;
        }
        setCreditAmount(number2);
    }

    public Number getCreditAmount()
    {
        return (Number)getAttributeInternal(32);
    }

    public void setCreditAmount(Number number)
    {
        setAttributeInternal(32, number);
    }

    public Number getOppWorstForecastAmount()
    {
        return (Number)getAttributeInternal(33);
    }

    public void setOppWorstForecastAmount(Number number)
    {
        if(number == null)
        {
            number = new Number(0);
        }
        setAttributeInternal(33, number);
    }

    public Number getOppForecastAmount()
    {
        return (Number)getAttributeInternal(34);
    }

    public void setOppForecastAmount(Number number)
    {
        String s = "asn.opportunity.schema.server.OpportunityLineSalesCreditEOImpl.setOppForecastAmo" +
"unt"
;
        OADBTransaction oadbtransaction = getOADBTransaction();
        oadbtransaction.isLoggingEnabled(1);
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        }
        if(number == null)
        {
            number = new Number(0);
        }
        setAttributeInternal(34, number);
    }

    public Number getOppBestForecastAmount()
    {
        return (Number)getAttributeInternal(35);
    }

    public void setOppBestForecastAmount(Number number)
    {
        if(number == null)
        {
            number = new Number(0);
        }
        setAttributeInternal(35, number);
    }

    public Number getObjectVersionNumber()
    {
        return (Number)getAttributeInternal(36);
    }

    public void setObjectVersionNumber(Number number)
    {
        setAttributeInternal(36, number);
    }

    protected Object getAttrInvokeAccessor(int i, AttributeDefImpl attributedefimpl)
        throws Exception
    {
        switch(i)
        {
        case 0: // '\0'
            return getSalesCreditId();

        case 1: // '\001'
            return getLastUpdateDate();

        case 2: // '\002'
            return getLastUpdatedBy();

        case 3: // '\003'
            return getCreationDate();

        case 4: // '\004'
            return getCreatedBy();

        case 5: // '\005'
            return getLastUpdateLogin();

        case 6: // '\006'
            return getRequestId();

        case 7: // '\007'
            return getProgramApplicationId();

        case 8: // '\b'
            return getProgramId();

        case 9: // '\t'
            return getProgramUpdateDate();

        case 10: // '\n'
            return getLeadId();

        case 11: // '\013'
            return getLeadLineId();

        case 12: // '\f'
            return getSalesforceId();

        case 13: // '\r'
            return getSalesgroupId();

        case 14: // '\016'
            return getAttributeCategory();

        case 15: // '\017'
            return getAttribute1();

        case 16: // '\020'
            return getAttribute2();

        case 17: // '\021'
            return getAttribute3();

        case 18: // '\022'
            return getAttribute4();

        case 19: // '\023'
            return getAttribute5();

        case 20: // '\024'
            return getAttribute6();

        case 21: // '\025'
            return getAttribute7();

        case 22: // '\026'
            return getAttribute8();

        case 23: // '\027'
            return getAttribute9();

        case 24: // '\030'
            return getAttribute10();

        case 25: // '\031'
            return getAttribute11();

        case 26: // '\032'
            return getAttribute12();

        case 27: // '\033'
            return getAttribute13();

        case 28: // '\034'
            return getAttribute14();

        case 29: // '\035'
            return getAttribute15();

        case 30: // '\036'
            return getCreditTypeId();

        case 31: // '\037'
            return getCreditPercent();

        case 32: // ' '
            return getCreditAmount();

        case 33: // '!'
            return getOppWorstForecastAmount();

        case 34: // '"'
            return getOppForecastAmount();

        case 35: // '#'
            return getOppBestForecastAmount();

        case 36: // '$'
            return getObjectVersionNumber();

        case 37: // '%'
            return getPersonId();

        case 38: // '&'
            return getDefaultedFromOwnerFlag();

        case 39: // '\''
            return getOpportunityLineEO();
        }
        return super.getAttrInvokeAccessor(i, attributedefimpl);
    }

    protected void setAttrInvokeAccessor(int i, Object obj, AttributeDefImpl attributedefimpl)
        throws Exception
    {
        switch(i)
        {
        case 0: // '\0'
            setSalesCreditId((Number)obj);
            return;

        case 1: // '\001'
            setLastUpdateDate((Date)obj);
            return;

        case 2: // '\002'
            setLastUpdatedBy((Number)obj);
            return;

        case 3: // '\003'
            setCreationDate((Date)obj);
            return;

        case 4: // '\004'
            setCreatedBy((Number)obj);
            return;

        case 5: // '\005'
            setLastUpdateLogin((Number)obj);
            return;

        case 6: // '\006'
            setRequestId((Number)obj);
            return;

        case 7: // '\007'
            setProgramApplicationId((Number)obj);
            return;

        case 8: // '\b'
            setProgramId((Number)obj);
            return;

        case 9: // '\t'
            setProgramUpdateDate((Date)obj);
            return;

        case 10: // '\n'
            setLeadId((Number)obj);
            return;

        case 11: // '\013'
            setLeadLineId((Number)obj);
            return;

        case 12: // '\f'
            setSalesforceId((Number)obj);
            return;

        case 13: // '\r'
            setSalesgroupId((Number)obj);
            return;

        case 14: // '\016'
            setAttributeCategory((String)obj);
            return;

        case 15: // '\017'
            setAttribute1((String)obj);
            return;

        case 16: // '\020'
            setAttribute2((String)obj);
            return;

        case 17: // '\021'
            setAttribute3((String)obj);
            return;

        case 18: // '\022'
            setAttribute4((String)obj);
            return;

        case 19: // '\023'
            setAttribute5((String)obj);
            return;

        case 20: // '\024'
            setAttribute6((String)obj);
            return;

        case 21: // '\025'
            setAttribute7((String)obj);
            return;

        case 22: // '\026'
            setAttribute8((String)obj);
            return;

        case 23: // '\027'
            setAttribute9((String)obj);
            return;

        case 24: // '\030'
            setAttribute10((String)obj);
            return;

        case 25: // '\031'
            setAttribute11((String)obj);
            return;

        case 26: // '\032'
            setAttribute12((String)obj);
            return;

        case 27: // '\033'
            setAttribute13((String)obj);
            return;

        case 28: // '\034'
            setAttribute14((String)obj);
            return;

        case 29: // '\035'
            setAttribute15((String)obj);
            return;

        case 30: // '\036'
            setCreditTypeId((Number)obj);
            return;

        case 31: // '\037'
            setCreditPercent((Number)obj);
            return;

        case 32: // ' '
            setCreditAmount((Number)obj);
            return;

        case 33: // '!'
            setOppWorstForecastAmount((Number)obj);
            return;

        case 34: // '"'
            setOppForecastAmount((Number)obj);
            return;

        case 35: // '#'
            setOppBestForecastAmount((Number)obj);
            return;

        case 36: // '$'
            setObjectVersionNumber((Number)obj);
            return;

        case 37: // '%'
            setPersonId((Number)obj);
            return;

        case 38: // '&'
            setDefaultedFromOwnerFlag((String)obj);
            return;
        }
        super.setAttrInvokeAccessor(i, obj, attributedefimpl);
    }

    public void create(AttributeList attributelist)
    {
        String s = "asn.opportunity.schema.server.OpportunityLineSalesCreditEOImpl.create";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        try
        {
            if(flag)
            {
                oadbtransaction.writeDiagnostics(s, "begin", 2);
            }
            super.create(attributelist);
            Number number = oadbtransaction.getSequenceValue("AS_SALES_CREDITS_S");
            setAttributeInternal(0, number);
            setAttributeInternal(10, getOpportunityLineEO().getLeadId());
            setAttributeInternal(32, new Number(0));
            setAttributeInternal(31, new Number(0));
            setAttributeInternal(35, new Number(0));
            setAttributeInternal(34, new Number(0));
            setAttributeInternal(33, new Number(0));
            setAttributeInternal(38, "N");
        }
        finally
        {
            if(flag)
            {
                oadbtransaction.writeDiagnostics(s, "end", 2);
            }
        }
    }

    public void remove()
    {
        String s = "asn.opportunity.schema.server.OpportunityLineSalesCreditEOImpl.remove";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        oadbtransaction.isLoggingEnabled(1);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        }
        super.remove();
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    protected void validateEntity()
    {
        String s = "asn.opportunity.schema.server.OpportunityLineSalesCreditEOImpl.validateEntity";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        oadbtransaction.isLoggingEnabled(1);
        boolean flag1 = oadbtransaction.isLoggingEnabled(4);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        }
        super.validateEntity();
        /*
        OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(OpportunityEOImpl.getDefinitionObject());
        if((isAttributeChanged(12) || isAttributeChanged(13)) && getSalesgroupId() != null && !opportunityexpert.isResourceIdGroupIdValid(getSalesforceId(), getSalesgroupId()))
        {
            if(flag1)
            {
                StringBuffer stringbuffer = (new StringBuffer(25)).append("invalid SalesforceId, SalesgroupId");
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                stringbuffer = null;
            }
            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_RSCGRP_INV_ERR");
        }
        */
        OpportunityLineEOImpl opportunitylineeoimpl = getOpportunityLineEO();
        if(isAttributeChanged(31) || isAttributeChanged(32) || opportunitylineeoimpl.isAttributeChanged(15))
        {
            Number number = opportunitylineeoimpl.getTotalAmount();
            if(number == null)
            {
                number = new Number(0);
            }
            Number number1 = getCreditPercent().multiply(number).divide(new Number(100));
            if(!number1.equals(getCreditAmount()))
            {
                if(flag1)
                {
                    StringBuffer stringbuffer1 = (new StringBuffer(100)).append("CreditAmount not consistent with calculated credit amount,").append("calculated credit amount:").append(number1).append("CreditAmount:").append(getCreditAmount());
                    oadbtransaction.writeDiagnostics(s, stringbuffer1.toString(), 4);
                    stringbuffer1 = null;
                }
                throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_OPPTY_SLSCRDTAMT_INV_ERR");
            }
        }

        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    protected void applySalesCreditDefaulting(String s, String s1)
    {
        String s2 = "asn.opportunity.schema.server.OpportunityLineSalesCreditEOImpl.applySalesCreditD" +
"efaulting"
;
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        try
        {
            if(flag)
            {
                oadbtransaction.writeDiagnostics(s2, "begin", 2);
                StringBuffer stringbuffer = (new StringBuffer(100)).append("Input parameters:").append("winLossInd=").append(s).append(", frcstRollupFlag=").append(s1);
                oadbtransaction.writeDiagnostics(s2, stringbuffer.toString(), 2);
                stringbuffer = null;
            }
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(OpportunityEOImpl.getDefinitionObject());
            OpportunityLineEOImpl opportunitylineeoimpl = getOpportunityLineEO();
            OpportunityEOImpl opportunityeoimpl = opportunitylineeoimpl.getOpportunityEO();
            String s3 = opportunityeoimpl.getStatus();
            if(s == null)
            {
                s = opportunityexpert.getWinLossIndicator(s3);
                if(flag1)
                {
                    StringBuffer stringbuffer1 = (new StringBuffer(25)).append("winLossInd=").append(s);
                    oadbtransaction.writeDiagnostics(s2, stringbuffer1.toString(), 1);
                    stringbuffer1 = null;
                }
            }
            if(s1 == null)
            {
                s1 = opportunityexpert.getForecastRollupFlag(s3);
                if(flag1)
                {
                    StringBuffer stringbuffer2 = (new StringBuffer(25)).append("frcstRollupFlag=").append(s1);
                    oadbtransaction.writeDiagnostics(s2, stringbuffer2.toString(), 1);
                    stringbuffer2 = null;
                }
            }
            if(!"Y".equals(s1))
            {
                return;
            }
            Number number = opportunityeoimpl.getWinProbability();
            if(number == null)
            {
                number = new Number(0);
            }
            Number number1 = opportunitylineeoimpl.getTotalAmount();
            if(number1 == null)
            {
                number1 = new Number(0);
            }
            Number number2 = number1.multiply(getCreditPercent()).divide(new Number(100));
            String s4 = oadbtransaction.getProfile("ASN_FRCST_DEFAULTING_TYPE");
            Number number3 = null;
            Number number4 = null;
            Number number5 = null;
            if(flag1)
            {
                StringBuffer stringbuffer3 = new StringBuffer(50);
                stringbuffer3.append("frcstDefaultingType=").append(s4);
                oadbtransaction.writeDiagnostics(s2, stringbuffer3.toString(), 1);
                stringbuffer3 = null;
            }
            if(!"W".equals(s4))
            {
                if("W".equals(s))
                {
                    number3 = number2;
                    number4 = number2;
                    number5 = number2;
                } else
                {
                    number3 = number2;
                    number4 = number2.multiply(number).divide(new Number(100));
                    number5 = new Number(0);
                }
            } else
            if("W".equals(s) || number.compareTo(new Number(80)) >= 0)
            {
                number3 = number2;
                number4 = number2;
                number5 = number2;
            } else
            if(number.compareTo(new Number(60)) >= 0)
            {
                number3 = number2;
                number4 = number2;
                number5 = new Number(0);
            } else
            if(number.compareTo(new Number(40)) >= 0)
            {
                number3 = number2;
                number4 = new Number(0);
                number5 = new Number(0);
            } else
            {
                number3 = new Number(0);
                number4 = new Number(0);
                number5 = new Number(0);
            }
            if(!number3.equals(getOppBestForecastAmount()))
            {
                setOppBestForecastAmount(number3);
            }
            if(!number4.equals(getOppForecastAmount()))
            {
                setOppForecastAmount(number4);
            }
            if(!number5.equals(getOppWorstForecastAmount()))
            {
                setOppWorstForecastAmount(number5);
            }
        }
        finally
        {
            if(flag)
            {
                oadbtransaction.writeDiagnostics(s2, "end", 2);
            }
        }
    }

    boolean isSalesforceIdChanged()
    {
        return isAttributeChanged(12);
    }

    boolean isSalesgroupIdChanged()
    {
        return isAttributeChanged(13);
    }

    public OpportunityLineEOImpl getOpportunityLineEO()
    {
        return (OpportunityLineEOImpl)getAttributeInternal(39);
    }

    public void setOpportunityLineEO(OpportunityLineEOImpl opportunitylineeoimpl)
    {
        setAttributeInternal(39, opportunitylineeoimpl);
    }

    public Number getPersonId()
    {
        return (Number)getAttributeInternal(37);
    }

    public void setPersonId(Number number)
    {
        setAttributeInternal(37, number);
    }

    public String getDefaultedFromOwnerFlag()
    {
        String s = (String)getAttributeInternal(38);
        s = s != null ? s : "N";
        return s;
    }

    public void setDefaultedFromOwnerFlag(String s)
    {
        String s1 = "asn.opportunity.schema.server.OpportunityAccessEOImpl.setDefaultedFromOwnerFlag";
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
            {
                s = null;
            }
        }
        if(s != null && !"Y".equals(s) && !"N".equals(s))
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            if(oadbtransaction.isLoggingEnabled(4))
            {
                StringBuffer stringbuffer = (new StringBuffer(25)).append("invalid value=").append(s);
                oadbtransaction.writeDiagnostics(s1, stringbuffer.toString(), 4);
                stringbuffer = null;
            }
            MessageToken amessagetoken[] = {
                new MessageToken("FLAGNAME", "DefaultedFromOwnerFlag")
            };
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "DefaultedFromOwner", s, "ASN", "ASN_CMMN_FLAG_INV_ERR", amessagetoken);
        } else
        {
            setAttributeInternal(38, s);
            return;
        }
    }

    public static Key createPrimaryKey(Number number)
    {
        return new Key(new Object[] {
            number
        });
    }

}
