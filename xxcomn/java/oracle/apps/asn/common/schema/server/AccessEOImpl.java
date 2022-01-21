package oracle.apps.asn.common.schema.server;

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

// Referenced classes of package oracle.apps.asn.common.schema.server:
//            AccessExpert

public class AccessEOImpl extends ASNEntityImpl
{

    protected static final int ACCESSID = 0;
    protected static final int LASTUPDATEDATE = 1;
    protected static final int LASTUPDATEDBY = 2;
    protected static final int CREATIONDATE = 3;
    protected static final int CREATEDBY = 4;
    protected static final int LASTUPDATELOGIN = 5;
    protected static final int REQUESTID = 6;
    protected static final int PROGRAMAPPLICATIONID = 7;
    protected static final int PROGRAMID = 8;
    protected static final int PROGRAMUPDATEDATE = 9;
    protected static final int FREEZEFLAG = 10;
    protected static final int TEAMLEADERFLAG = 11;
    protected static final int CUSTOMERID = 12;
    protected static final int SALESFORCEID = 13;
    protected static final int ORGID = 14;
    protected static final int ATTRIBUTECATEGORY = 15;
    protected static final int ATTRIBUTE1 = 16;
    protected static final int ATTRIBUTE2 = 17;
    protected static final int ATTRIBUTE3 = 18;
    protected static final int ATTRIBUTE4 = 19;
    protected static final int ATTRIBUTE5 = 20;
    protected static final int ATTRIBUTE6 = 21;
    protected static final int ATTRIBUTE7 = 22;
    protected static final int ATTRIBUTE8 = 23;
    protected static final int ATTRIBUTE9 = 24;
    protected static final int ATTRIBUTE10 = 25;
    protected static final int ATTRIBUTE11 = 26;
    protected static final int ATTRIBUTE12 = 27;
    protected static final int ATTRIBUTE13 = 28;
    protected static final int ATTRIBUTE14 = 29;
    protected static final int ATTRIBUTE15 = 30;
    protected static final int SALESGROUPID = 31;
    protected static final int CREATEDBYTAPFLAG = 32;
    protected static final int OBJECTVERSIONNUMBER = 33;
    protected static final int PERSONID = 34;
    protected static final int PARTNERCUSTOMERID = 35;
    protected static final int PARTNERADDRESSID = 36;
    protected static final int PARTNERCONTPARTYID = 37;
    public static final String RCS_ID = "$Header: AccessEOImpl.java 115.15 2004/05/12 23:21:45 tinwang noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: AccessEOImpl.java 115.15 2004/05/12 23:21:45 tinwang noship $", "oracle.apps.asn.common.schema.server");
    private static OAEntityDefImpl mDefinitionObject;

    public AccessEOImpl()
    {
    }

    public static synchronized EntityDefImpl getDefinitionObject()
    {
        if(mDefinitionObject == null)
        {
            mDefinitionObject = (OAEntityDefImpl)EntityDefImpl.findDefObject("oracle.apps.asn.common.schema.server.AccessEO");
        }
        return mDefinitionObject;
    }

    public void create(AttributeList attributelist)
    {
        String s = "asn.common.schema.server.AccessEOImpl.create";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        try
        {
            if(flag)
            {
                oadbtransaction.writeDiagnostics(s, "begin", 2);
            }
            super.create(attributelist);
            setAttributeInternal(0, oadbtransaction.getSequenceValue("AS_ACCESSES_S"));
            setAttributeInternal(10, "N");
            setAttributeInternal(11, "Y");
            setAttributeInternal(32, "N");
            int i = oadbtransaction.getOrgId();
            if(i != -1)
            {
                setAttributeInternal(14, new Number(i));
            }
        }
        finally
        {
            if(flag)
            {
                oadbtransaction.writeDiagnostics(s, "end", 2);
            }
        }
    }

    protected Object getAttrInvokeAccessor(int i, AttributeDefImpl attributedefimpl)
        throws Exception
    {
        switch(i)
        {
        case 0: // '\0'
            return getAccessId();

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
            return getFreezeFlag();

        case 11: // '\013'
            return getTeamLeaderFlag();

        case 12: // '\f'
            return getCustomerId();

        case 13: // '\r'
            return getSalesforceId();

        case 14: // '\016'
            return getOrgId();

        case 15: // '\017'
            return getAttributeCategory();

        case 16: // '\020'
            return getAttribute1();

        case 17: // '\021'
            return getAttribute2();

        case 18: // '\022'
            return getAttribute3();

        case 19: // '\023'
            return getAttribute4();

        case 20: // '\024'
            return getAttribute5();

        case 21: // '\025'
            return getAttribute6();

        case 22: // '\026'
            return getAttribute7();

        case 23: // '\027'
            return getAttribute8();

        case 24: // '\030'
            return getAttribute9();

        case 25: // '\031'
            return getAttribute10();

        case 26: // '\032'
            return getAttribute11();

        case 27: // '\033'
            return getAttribute12();

        case 28: // '\034'
            return getAttribute13();

        case 29: // '\035'
            return getAttribute14();

        case 30: // '\036'
            return getAttribute15();

        case 31: // '\037'
            return getSalesGroupId();

        case 32: // ' '
            return getCreatedByTapFlag();

        case 33: // '!'
            return getObjectVersionNumber();

        case 34: // '"'
            return getPersonId();

        case 35: // '#'
            return getPartnerCustomerId();

        case 36: // '$'
            return getPartnerAddressId();

        case 37: // '%'
            return getPartnerContPartyId();
        }
        return super.getAttrInvokeAccessor(i, attributedefimpl);
    }

    protected void setAttrInvokeAccessor(int i, Object obj, AttributeDefImpl attributedefimpl)
        throws Exception
    {
        switch(i)
        {
        case 0: // '\0'
            setAccessId((Number)obj);
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
            setFreezeFlag((String)obj);
            return;

        case 11: // '\013'
            setTeamLeaderFlag((String)obj);
            return;

        case 12: // '\f'
            setCustomerId((Number)obj);
            return;

        case 13: // '\r'
            setSalesforceId((Number)obj);
            return;

        case 14: // '\016'
            setOrgId((Number)obj);
            return;

        case 15: // '\017'
            setAttributeCategory((String)obj);
            return;

        case 16: // '\020'
            setAttribute1((String)obj);
            return;

        case 17: // '\021'
            setAttribute2((String)obj);
            return;

        case 18: // '\022'
            setAttribute3((String)obj);
            return;

        case 19: // '\023'
            setAttribute4((String)obj);
            return;

        case 20: // '\024'
            setAttribute5((String)obj);
            return;

        case 21: // '\025'
            setAttribute6((String)obj);
            return;

        case 22: // '\026'
            setAttribute7((String)obj);
            return;

        case 23: // '\027'
            setAttribute8((String)obj);
            return;

        case 24: // '\030'
            setAttribute9((String)obj);
            return;

        case 25: // '\031'
            setAttribute10((String)obj);
            return;

        case 26: // '\032'
            setAttribute11((String)obj);
            return;

        case 27: // '\033'
            setAttribute12((String)obj);
            return;

        case 28: // '\034'
            setAttribute13((String)obj);
            return;

        case 29: // '\035'
            setAttribute14((String)obj);
            return;

        case 30: // '\036'
            setAttribute15((String)obj);
            return;

        case 31: // '\037'
            setSalesGroupId((Number)obj);
            return;

        case 32: // ' '
            setCreatedByTapFlag((String)obj);
            return;

        case 33: // '!'
            setObjectVersionNumber((Number)obj);
            return;

        case 34: // '"'
            setPersonId((Number)obj);
            return;

        case 35: // '#'
            setPartnerCustomerId((Number)obj);
            return;

        case 36: // '$'
            setPartnerAddressId((Number)obj);
            return;

        case 37: // '%'
            setPartnerContPartyId((Number)obj);
            return;
        }
        super.setAttrInvokeAccessor(i, obj, attributedefimpl);
    }

    protected void validateEntity()
    {
        String s = "asn.common.schema.server.AccessEOImpl.validateEntity";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(4);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        }
        super.validateEntity();
         // Commented for defect 5749 by Anitha.D
        /*AccessExpert accessexpert = (AccessExpert)oadbtransaction.getExpert(getDefinitionObject());
        Number number = getSalesforceId();
        Number number1 = getSalesGroupId();
        if((isAttributeChanged(13) || isAttributeChanged(31)) && !accessexpert.isResourceIdGroupIdValid(number, number1))
        {
            if(flag1)
            {
                StringBuffer stringbuffer = (new StringBuffer(100)).append("Invalid resourceId, groupId:").append("resourceId=").append(number).append(", groupId=").append(number1);
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                stringbuffer = null;
            }
            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_RSCGRP_INV_ERR");
        }*/
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    public Number getAccessId()
    {
        return (Number)getAttributeInternal(0);
    }

    public void setAccessId(Number number)
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

    public String getFreezeFlag()
    {
        return (String)getAttributeInternal(10);
    }

    public void setFreezeFlag(String s)
    {
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
            MessageToken amessagetoken[] = {
                new MessageToken("FLAGNAME", "FreezeFlag")
            };
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "FreezeFlag", s, "ASN", "ASN_CMMN_FLAG_INV_ERR", amessagetoken);
        } else
        {
            setAttributeInternal(10, s);
            return;
        }
    }

    public String getTeamLeaderFlag()
    {
        return (String)getAttributeInternal(11);
    }

    public void setTeamLeaderFlag(String s)
    {
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
            MessageToken amessagetoken[] = {
                new MessageToken("FLAGNAME", "TeamLeaderFlag")
            };
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "TeamLeaderFlag", s, "ASN", "ASN_CMMN_FLAG_INV_ERR", amessagetoken);
        } else
        {
            setAttributeInternal(11, s);
            return;
        }
    }

    public Number getCustomerId()
    {
        return (Number)getAttributeInternal(12);
    }

    public void setCustomerId(Number number)
    {
        setAttributeInternal(12, number);
    }

    public Number getSalesforceId()
    {
        return (Number)getAttributeInternal(13);
    }

    public void setSalesforceId(Number number)
    {
        OADBTransaction oadbtransaction = getOADBTransaction();
        AccessExpert accessexpert = (AccessExpert)oadbtransaction.getExpert(getDefinitionObject());
        if(number != null && !accessexpert.isResourceIdValid(number))
        {
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ResourceId", number, "ASN", "ASN_CMMN_RSC_INV_ERR");
        } else
        {
            setAttributeInternal(13, number);
            Number number1 = accessexpert.getEmployeeId(number);
            setPersonId(number1);
            return;
        }
    }

    public Number getOrgId()
    {
        return (Number)getAttributeInternal(14);
    }

    public void setOrgId(Number number)
    {
        setAttributeInternal(14, number);
    }

    public String getAttributeCategory()
    {
        return (String)getAttributeInternal(15);
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
        setAttributeInternal(15, s);
    }

    public String getAttribute1()
    {
        return (String)getAttributeInternal(16);
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
        setAttributeInternal(16, s);
    }

    public String getAttribute2()
    {
        return (String)getAttributeInternal(17);
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
        setAttributeInternal(17, s);
    }

    public String getAttribute3()
    {
        return (String)getAttributeInternal(18);
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
        setAttributeInternal(18, s);
    }

    public String getAttribute4()
    {
        return (String)getAttributeInternal(19);
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
        setAttributeInternal(19, s);
    }

    public String getAttribute5()
    {
        return (String)getAttributeInternal(20);
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
        setAttributeInternal(20, s);
    }

    public String getAttribute6()
    {
        return (String)getAttributeInternal(21);
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
        setAttributeInternal(21, s);
    }

    public String getAttribute7()
    {
        return (String)getAttributeInternal(22);
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
        setAttributeInternal(22, s);
    }

    public String getAttribute8()
    {
        return (String)getAttributeInternal(23);
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
        setAttributeInternal(23, s);
    }

    public String getAttribute9()
    {
        return (String)getAttributeInternal(24);
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
        setAttributeInternal(24, s);
    }

    public String getAttribute10()
    {
        return (String)getAttributeInternal(25);
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
        setAttributeInternal(25, s);
    }

    public String getAttribute11()
    {
        return (String)getAttributeInternal(26);
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
        setAttributeInternal(26, s);
    }

    public String getAttribute12()
    {
        return (String)getAttributeInternal(27);
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
        setAttributeInternal(27, s);
    }

    public String getAttribute13()
    {
        return (String)getAttributeInternal(28);
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
        setAttributeInternal(28, s);
    }

    public String getAttribute14()
    {
        return (String)getAttributeInternal(29);
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
        setAttributeInternal(29, s);
    }

    public String getAttribute15()
    {
        return (String)getAttributeInternal(30);
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
        setAttributeInternal(30, s);
    }

    public Number getSalesGroupId()
    {
        return (Number)getAttributeInternal(31);
    }

    public void setSalesGroupId(Number number)
    {
        setAttributeInternal(31, number);
    }

    public String getCreatedByTapFlag()
    {
        return (String)getAttributeInternal(32);
    }

    public void setCreatedByTapFlag(String s)
    {
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
            MessageToken amessagetoken[] = {
                new MessageToken("FLAGNAME", "CreatedByTapFlag")
            };
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CreatedByTapFlag", s, "ASN", "ASN_CMMN_FLAG_INV_ERR", amessagetoken);
        } else
        {
            setAttributeInternal(32, s);
            return;
        }
    }

    public Number getObjectVersionNumber()
    {
        return (Number)getAttributeInternal(33);
    }

    public void setObjectVersionNumber(Number number)
    {
        setAttributeInternal(33, number);
    }

    public Number getPersonId()
    {
        return (Number)getAttributeInternal(34);
    }

    public void setPersonId(Number number)
    {
        setAttributeInternal(34, number);
    }

    public Number getPartnerCustomerId()
    {
        return (Number)getAttributeInternal(35);
    }

    public void setPartnerCustomerId(Number number)
    {
        setAttributeInternal(35, number);
    }

    public Number getPartnerAddressId()
    {
        return (Number)getAttributeInternal(36);
    }

    public void setPartnerAddressId(Number number)
    {
        setAttributeInternal(36, number);
    }

    public Number getPartnerContPartyId()
    {
        return (Number)getAttributeInternal(37);
    }

    public void setPartnerContPartyId(Number number)
    {
        setAttributeInternal(37, number);
    }

    public static Key createPrimaryKey(Number number)
    {
        return new Key(new Object[] {
            number
        });
    }

}
