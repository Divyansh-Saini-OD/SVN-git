// Decompiled Using: FrontEnd Plus v2.03 and the JAD Engine
// Available From: http://www.reflections.ath.cx
// Decompiler options: packimports(3)
// Source File Name:   LeadEOImpl.java

package oracle.apps.asn.lead.schema.server;

import com.sun.java.util.collections.*;
import java.sql.SQLException;
import oracle.apps.asn.common.fwk.server.ASNConstants;
import oracle.apps.asn.common.fwk.server.ASNEntityImpl;
import oracle.apps.asn.common.schema.server.AccessEOImpl;
import oracle.apps.asn.common.schema.server.RelationshipEOImpl;
import oracle.apps.asn.opportunity.schema.server.*;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.server.*;
import oracle.apps.jtf.cac.schema.server.CacNoteContextsEOImpl;
import oracle.apps.jtf.cac.schema.server.CacNotesEOImpl;
import oracle.jbo.*;
import oracle.jbo.common.MetaObjectBase;
import oracle.jbo.common.NamedObjectImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.*;
import oracle.jdbc.OracleTypes;
import oracle.jdbc.driver.OracleCallableStatement;
import oracle.jdbc.driver.OraclePreparedStatement;
import oracle.sql.DATE;
import oracle.sql.NUMBER;


// Referenced classes of package oracle.apps.asn.lead.schema.server:
//            LeadAccessEOImpl, LeadContactEOImpl, LeadExpert, LeadLineEOImpl,
//            LeadLogEOImpl, LeadOpportunityEOImpl

public class LeadEOImpl extends ASNEntityImpl
{

    public LeadEOImpl()
    {
    }

    public static synchronized EntityDefImpl getDefinitionObject()
    {
        if(mDefinitionObject == null)
            mDefinitionObject = (OAEntityDefImpl)EntityDefImpl.findDefObject("oracle.apps.asn.lead.schema.server.LeadEO");
        return mDefinitionObject;
    }

    public Number getSalesLeadId()
    {
        return (Number)getAttributeInternal(0);
    }

    public void setSalesLeadId(Number number)
    {
        setAttributeInternal(0, number);
    }

    public Number getObjectVersionNumber()
    {
        return (Number)getAttributeInternal(32);
    }

    public void setObjectVersionNumber(Number number)
    {
        setAttributeInternal(32, number);
    }

    public Date getLastUpdateDate()
    {
        return (Date)getAttributeInternal(33);
    }

    public void setLastUpdateDate(Date date)
    {
        setAttributeInternal(33, date);
    }

    public Number getLastUpdatedBy()
    {
        return (Number)getAttributeInternal(34);
    }

    public void setLastUpdatedBy(Number number)
    {
        setAttributeInternal(34, number);
    }

    public Date getCreationDate()
    {
        return (Date)getAttributeInternal(35);
    }

    public void setCreationDate(Date date)
    {
        setAttributeInternal(35, date);
        setTruncCreationDate(new Date(getCreationDate().dateValue()));
    }

    public Number getCreatedBy()
    {
        return (Number)getAttributeInternal(36);
    }

    public void setCreatedBy(Number number)
    {
        setAttributeInternal(36, number);
    }

    public Number getLastUpdateLogin()
    {
        return (Number)getAttributeInternal(37);
    }

    public void setLastUpdateLogin(Number number)
    {
        setAttributeInternal(37, number);
    }

    public Number getRequestId()
    {
        return (Number)getAttributeInternal(38);
    }

    public void setRequestId(Number number)
    {
        setAttributeInternal(38, number);
    }

    public Number getProgramApplicationId()
    {
        return (Number)getAttributeInternal(39);
    }

    public void setProgramApplicationId(Number number)
    {
        setAttributeInternal(39, number);
    }

    public Number getProgramId()
    {
        return (Number)getAttributeInternal(40);
    }

    public void setProgramId(Number number)
    {
        setAttributeInternal(40, number);
    }

    public Date getProgramUpdateDate()
    {
        return (Date)getAttributeInternal(41);
    }

    public void setProgramUpdateDate(Date date)
    {
        setAttributeInternal(41, date);
    }

    public String getLeadNumber()
    {
        return (String)getAttributeInternal(1);
    }

    public void setLeadNumber(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(1, s);
    }

    public String getStatusCode()
    {
        return (String)getAttributeInternal(2);
    }

    public void setStatusCode(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        String s1 = getEntityState() != 0 ? (String)getPostedAttribute(2) : null;
        if(s != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            if("CONVERTED_TO_OPPORTUNITY".equals(s1) && !s.equals(s1))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "StatusCode", s, "ASN", "ASN_LEAD_CONVUPD_INV_ERR");
            if(!leadexpert.isStatusValid(s))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "StatusCode", s, "ASN", "ASN_CMMN_STATUS_INV_ERR");
            if("CONVERTED_TO_OPPORTUNITY".equals(s) && !isAttributeChanged(9))
                setAttributeInternal(9, "CONVERTED_TO_OPPORTUNITY");
        }
        String s2 = getStatusCode();
        setAttributeInternal(2, s);
        if(!s.equals(s2))
        {
            OADBTransaction oadbtransaction1 = getOADBTransaction();
            LeadExpert leadexpert1 = (LeadExpert)oadbtransaction1.getExpert(getDefinitionObject());
            String s3 = leadexpert1.isStatusOpen(s) ? "Y" : "N";
            if(!s3.equals(getStatusOpenFlag()))
            {
                setStatusOpenFlag(s3);
                RowIterator rowiterator = getLeadAccessEO();
                rowiterator.setRowValidation(false);
                LeadAccessEOImpl leadaccesseoimpl;
                for(; rowiterator.hasNext(); leadaccesseoimpl.setOpenFlag(s3))
                {
                    leadaccesseoimpl = (LeadAccessEOImpl)rowiterator.next();
                    String s4 = leadaccesseoimpl.getOpenFlag();
                    if(s4 == null)
                        s4 = "N";
                    if(s3.equals(s4))
                        break;
                }

            }
        }
    }

    public Number getCustomerId()
    {
        return (Number)getAttributeInternal(3);
    }

    public void setCustomerId(Number number)
    {
        if(number != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!leadexpert.isCustomerValid(number))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CustomerId", number, "ASN", "ASN_CMMN_CUST_INV_ERR");
        }
        setAttributeInternal(3, number);
        RowIterator rowiterator = getLeadContactEO();
        rowiterator.setRowValidation(false);
        LeadContactEOImpl leadcontacteoimpl;
        for(; rowiterator.hasNext(); leadcontacteoimpl.setCustomerId(number))
            leadcontacteoimpl = (LeadContactEOImpl)rowiterator.next();

        RowIterator rowiterator1 = getLeadAccessEO();
        rowiterator1.setRowValidation(false);
        LeadAccessEOImpl leadaccesseoimpl;
        for(; rowiterator1.hasNext(); leadaccesseoimpl.setCustomerId(number))
            leadaccesseoimpl = (LeadAccessEOImpl)rowiterator1.next();

    }

    public String getCurrencyCode()
    {
        return (String)getAttributeInternal(5);
    }

    public void setCurrencyCode(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        if(s != null)
        {
            s = s.trim();
            OADBTransaction oadbtransaction = getOADBTransaction();
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!leadexpert.isCurrencyValid(s))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CurrencyCode", s, "ASN", "ASN_CMMN_CURR_INV_ERR");
        }
        setAttributeInternal(5, s);
    }

    public String getDescription()
    {
        return (String)getAttributeInternal(6);
    }

    public void setDescription(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(6, s);
    }

    public Number getSourcePromotionId()
    {
        return (Number)getAttributeInternal(7);
    }

    public void setSourcePromotionId(Number number)
    {
        setAttributeInternal(7, number);
    }

    public String getChannelCode()
    {
        return (String)getAttributeInternal(8);
    }

    public void setChannelCode(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        if(s != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!leadexpert.isChannelValid(s))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ChannelCode", s, "ASN", "ASN_CMMN_SLSCHNL_INV_ERR");
        }
        setAttributeInternal(8, s);
    }

    public String getCloseReason()
    {
        return (String)getAttributeInternal(9);
    }

    public void setCloseReason(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        if(s != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!leadexpert.isCloseReasonValid(s))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CloseReason", s, "ASN", "ASN_CMMN_CLSRSN_INV_ERR");
        }
        setAttributeInternal(9, s);
    }

    public Number getLeadRankId()
    {
        return (Number)getAttributeInternal(10);
    }

    public void setLeadRankId(Number number)
    {
        if(number != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!leadexpert.isRankValid(number))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "LeadRankId", number, "ASN", "ASN_LEAD_RANK_INV_ERR");
        }
        Number number1 = getLeadRankId();
        setAttributeInternal(10, number);
        if(number != null && !number.equals(number1) || number1 != null && !number1.equals(number))
        {
            OADBTransaction oadbtransaction1 = getOADBTransaction();
            LeadExpert leadexpert1 = (LeadExpert)oadbtransaction1.getExpert(getDefinitionObject());
            Number number2 = number != null ? leadexpert1.getLeadRankScore(number) : null;
            setLeadRankScore(number2);
        }
    }

    public String getLeadRankInd()
    {
        return (String)getAttributeInternal(11);
    }

    public void setLeadRankInd(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(11, s);
    }

    public Number getTotalAmount()
    {
        return (Number)getAttributeInternal(12);
    }

    public void setTotalAmount(Number number)
    {
        setAttributeInternal(12, number);
    }

    public Number getAssignToSalesforceId()
    {
        return (Number)getAttributeInternal(15);
    }

    public void setAssignToSalesforceId(Number number)
    {
        setAttributeInternal(15, number);
    }

    public Number getAssignSalesGroupId()
    {
        return (Number)getAttributeInternal(16);
    }

    public void setAssignSalesGroupId(Number number)
    {
        setAttributeInternal(16, number);
    }

    public Number getPrimaryContactPartyId()
    {
        return (Number)getAttributeInternal(18);
    }

    public void setPrimaryContactPartyId(Number number)
    {
        OADBTransaction oadbtransaction = getOADBTransaction();
        if(number != null)
        {
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!leadexpert.isContactPartyValid(number))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "PrimaryContactPartyId", number, "ASN", "ASN_CMMN_CTCT_INV_ERR");
        }
        setAttributeInternal(18, number);
    }

    public Number getPrimaryContactPhoneId()
    {
        return (Number)getAttributeInternal(20);
    }

    public void setPrimaryContactPhoneId(Number number)
    {
        setAttributeInternal(20, number);
    }

    public String getImportFlag()
    {
        return (String)getAttributeInternal(21);
    }

    public void setImportFlag(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        if(s != null && !"Y".equals(s) && !"N".equals(s))
        {
            MessageToken amessagetoken[] = {
                new MessageToken("FLAGNAME", "ImportFlag")
            };
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ImportFlag", s, "ASN", "ASN_CMMN_FLAG_INV_ERR", amessagetoken);
        } else
        {
            setAttributeInternal(21, s);
            return;
        }
    }

    public String getQualifiedFlag()
    {
        return (String)getAttributeInternal(22);
    }

    public void setQualifiedFlag(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        if(s != null && !"Y".equals(s) && !"N".equals(s))
        {
            MessageToken amessagetoken[] = {
                new MessageToken("FLAGNAME", "QualifiedFlag")
            };
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "QualifiedFlag", s, "ASN", "ASN_CMMN_FLAG_INV_ERR", amessagetoken);
        } else
        {
            setAttributeInternal(22, s);
            return;
        }
    }

    public Date getLeadEngineRunDate()
    {
        return (Date)getAttributeInternal(23);
    }

    public void setLeadEngineRunDate(Date date)
    {
        setAttributeInternal(23, date);
    }

    public String getAutoAssignmentType()
    {
        return (String)getAttributeInternal(24);
    }

    public void setAutoAssignmentType(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(24, s);
    }

    public String getSourceSystem()
    {
        return (String)getAttributeInternal(25);
    }

    public void setSourceSystem(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(25, s);
    }

    public String getObjectTypeCode()
    {
        String s = (String)getAttributeInternal(26);
        if(s == null)
        {
            s = "LEAD";
            populateAttribute(26, s);
        }
        return s;
    }

    public String getAttributeCategory()
    {
        return (String)getAttributeInternal(42);
    }

    public void setAttributeCategory(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(42, s);
    }

    public String getAttribute1()
    {
        return (String)getAttributeInternal(43);
    }

    public void setAttribute1(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(43, s);
    }

    public String getAttribute2()
    {
        return (String)getAttributeInternal(44);
    }

    public void setAttribute2(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(44, s);
    }

    public String getAttribute3()
    {
        return (String)getAttributeInternal(45);
    }

    public void setAttribute3(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(45, s);
    }

    public String getAttribute4()
    {
        return (String)getAttributeInternal(46);
    }

    public void setAttribute4(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(46, s);
    }

    public String getAttribute5()
    {
        return (String)getAttributeInternal(47);
    }

    public void setAttribute5(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(47, s);
    }

    public String getAttribute6()
    {
        return (String)getAttributeInternal(48);
    }

    public void setAttribute6(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(48, s);
    }

    public String getAttribute7()
    {
        return (String)getAttributeInternal(49);
    }

    public void setAttribute7(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(49, s);
    }

    public String getAttribute8()
    {
        return (String)getAttributeInternal(50);
    }

    public void setAttribute8(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(50, s);
    }

    public String getAttribute9()
    {
        return (String)getAttributeInternal(51);
    }

    public void setAttribute9(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(51, s);
    }

    public String getAttribute10()
    {
        return (String)getAttributeInternal(52);
    }

    public void setAttribute10(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(52, s);
    }

    public String getAttribute11()
    {
        return (String)getAttributeInternal(53);
    }

    public void setAttribute11(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(53, s);
    }

    public String getAttribute12()
    {
        return (String)getAttributeInternal(54);
    }

    public void setAttribute12(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(54, s);
    }

    public String getAttribute13()
    {
        return (String)getAttributeInternal(55);
    }

    public void setAttribute13(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(55, s);
    }

    public String getAttribute14()
    {
        return (String)getAttributeInternal(56);
    }

    public void setAttribute14(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(56, s);
    }

    public String getAttribute15()
    {
        return (String)getAttributeInternal(57);
    }

    public void setAttribute15(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        setAttributeInternal(57, s);
    }

    protected Object getAttrInvokeAccessor(int i, AttributeDefImpl attributedefimpl)
        throws Exception
    {
        switch(i)
        {
        case 0: // '\0'
            return getSalesLeadId();

        case 1: // '\001'
            return getLeadNumber();

        case 2: // '\002'
            return getStatusCode();

        case 3: // '\003'
            return getCustomerId();

        case 4: // '\004'
            return getAddressId();

        case 5: // '\005'
            return getCurrencyCode();

        case 6: // '\006'
            return getDescription();

        case 7: // '\007'
            return getSourcePromotionId();

        case 8: // '\b'
            return getChannelCode();

        case 9: // '\t'
            return getCloseReason();

        case 10: // '\n'
            return getLeadRankId();

        case 11: // '\013'
            return getLeadRankInd();

        case 12: // '\f'
            return getTotalAmount();

        case 13: // '\r'
            return getSalesStageId();

        case 14: // '\016'
            return getSalesMethodologyId();

        case 15: // '\017'
            return getAssignToSalesforceId();

        case 16: // '\020'
            return getAssignSalesGroupId();

        case 17: // '\021'
            return getAssignToPersonId();

        case 18: // '\022'
            return getPrimaryContactPartyId();

        case 19: // '\023'
            return getPrimaryCntPersonPartyId();

        case 20: // '\024'
            return getPrimaryContactPhoneId();

        case 21: // '\025'
            return getImportFlag();

        case 22: // '\026'
            return getQualifiedFlag();

        case 23: // '\027'
            return getLeadEngineRunDate();

        case 24: // '\030'
            return getAutoAssignmentType();

        case 25: // '\031'
            return getSourceSystem();

        case 26: // '\032'
            return getObjectTypeCode();

        case 27: // '\033'
            return getLeadRankScore();

        case 28: // '\034'
            return getStatusOpenFlag();

        case 29: // '\035'
            return getAcceptFlag();

        case 30: // '\036'
            return getTruncCreationDate();

        case 31: // '\037'
            return getCountry();

        case 32: // ' '
            return getObjectVersionNumber();

        case 33: // '!'
            return getLastUpdateDate();

        case 34: // '"'
            return getLastUpdatedBy();

        case 35: // '#'
            return getCreationDate();

        case 36: // '$'
            return getCreatedBy();

        case 37: // '%'
            return getLastUpdateLogin();

        case 38: // '&'
            return getRequestId();

        case 39: // '\''
            return getProgramApplicationId();

        case 40: // '('
            return getProgramId();

        case 41: // ')'
            return getProgramUpdateDate();

        case 42: // '*'
            return getAttributeCategory();

        case 43: // '+'
            return getAttribute1();

        case 44: // ','
            return getAttribute2();

        case 45: // '-'
            return getAttribute3();

        case 46: // '.'
            return getAttribute4();

        case 47: // '/'
            return getAttribute5();

        case 48: // '0'
            return getAttribute6();

        case 49: // '1'
            return getAttribute7();

        case 50: // '2'
            return getAttribute8();

        case 51: // '3'
            return getAttribute9();

        case 52: // '4'
            return getAttribute10();

        case 53: // '5'
            return getAttribute11();

        case 54: // '6'
            return getAttribute12();

        case 55: // '7'
            return getAttribute13();

        case 56: // '8'
            return getAttribute14();

        case 57: // '9'
            return getAttribute15();

        case 58: // ':'
            return getVehicleResponseCode();

        case 59: // ';'
            return getBudgetAmount();

        case 60: // '<'
            return getLeadLineEO();

        case 61: // '='
            return getLeadContactEO();

        case 62: // '>'
            return getLeadLogEO();

        case 63: // '?'
            return getLeadOpportunityEO();

        case 64: // '@'
            return getLeadAccessEO();

        case 65: // 'A'
            return getRelationshipEO();
        }
        return super.getAttrInvokeAccessor(i, attributedefimpl);
    }

    protected void setAttrInvokeAccessor(int i, Object obj, AttributeDefImpl attributedefimpl)
        throws Exception
    {
        switch(i)
        {
        case 0: // '\0'
            setSalesLeadId((Number)obj);
            return;

        case 1: // '\001'
            setLeadNumber((String)obj);
            return;

        case 2: // '\002'
            setStatusCode((String)obj);
            return;

        case 3: // '\003'
            setCustomerId((Number)obj);
            return;

        case 4: // '\004'
            setAddressId((Number)obj);
            return;

        case 5: // '\005'
            setCurrencyCode((String)obj);
            return;

        case 6: // '\006'
            setDescription((String)obj);
            return;

        case 7: // '\007'
            setSourcePromotionId((Number)obj);
            return;

        case 8: // '\b'
            setChannelCode((String)obj);
            return;

        case 9: // '\t'
            setCloseReason((String)obj);
            return;

        case 10: // '\n'
            setLeadRankId((Number)obj);
            return;

        case 11: // '\013'
            setLeadRankInd((String)obj);
            return;

        case 12: // '\f'
            setTotalAmount((Number)obj);
            return;

        case 13: // '\r'
            setSalesStageId((Number)obj);
            return;

        case 14: // '\016'
            setSalesMethodologyId((Number)obj);
            return;

        case 15: // '\017'
            setAssignToSalesforceId((Number)obj);
            return;

        case 16: // '\020'
            setAssignSalesGroupId((Number)obj);
            return;

        case 17: // '\021'
            setAssignToPersonId((Number)obj);
            return;

        case 18: // '\022'
            setPrimaryContactPartyId((Number)obj);
            return;

        case 19: // '\023'
            setPrimaryCntPersonPartyId((Number)obj);
            return;

        case 20: // '\024'
            setPrimaryContactPhoneId((Number)obj);
            return;

        case 21: // '\025'
            setImportFlag((String)obj);
            return;

        case 22: // '\026'
            setQualifiedFlag((String)obj);
            return;

        case 23: // '\027'
            setLeadEngineRunDate((Date)obj);
            return;

        case 24: // '\030'
            setAutoAssignmentType((String)obj);
            return;

        case 25: // '\031'
            setSourceSystem((String)obj);
            return;

        case 26: // '\032'
            setObjectTypeCode((String)obj);
            return;

        case 27: // '\033'
            setLeadRankScore((Number)obj);
            return;

        case 28: // '\034'
            setStatusOpenFlag((String)obj);
            return;

        case 29: // '\035'
            setAcceptFlag((String)obj);
            return;

        case 30: // '\036'
            setTruncCreationDate((Date)obj);
            return;

        case 31: // '\037'
            setCountry((String)obj);
            return;

        case 32: // ' '
            setObjectVersionNumber((Number)obj);
            return;

        case 33: // '!'
            setLastUpdateDate((Date)obj);
            return;

        case 34: // '"'
            setLastUpdatedBy((Number)obj);
            return;

        case 35: // '#'
            setCreationDate((Date)obj);
            return;

        case 36: // '$'
            setCreatedBy((Number)obj);
            return;

        case 37: // '%'
            setLastUpdateLogin((Number)obj);
            return;

        case 38: // '&'
            setRequestId((Number)obj);
            return;

        case 39: // '\''
            setProgramApplicationId((Number)obj);
            return;

        case 40: // '('
            setProgramId((Number)obj);
            return;

        case 41: // ')'
            setProgramUpdateDate((Date)obj);
            return;

        case 42: // '*'
            setAttributeCategory((String)obj);
            return;

        case 43: // '+'
            setAttribute1((String)obj);
            return;

        case 44: // ','
            setAttribute2((String)obj);
            return;

        case 45: // '-'
            setAttribute3((String)obj);
            return;

        case 46: // '.'
            setAttribute4((String)obj);
            return;

        case 47: // '/'
            setAttribute5((String)obj);
            return;

        case 48: // '0'
            setAttribute6((String)obj);
            return;

        case 49: // '1'
            setAttribute7((String)obj);
            return;

        case 50: // '2'
            setAttribute8((String)obj);
            return;

        case 51: // '3'
            setAttribute9((String)obj);
            return;

        case 52: // '4'
            setAttribute10((String)obj);
            return;

        case 53: // '5'
            setAttribute11((String)obj);
            return;

        case 54: // '6'
            setAttribute12((String)obj);
            return;

        case 55: // '7'
            setAttribute13((String)obj);
            return;

        case 56: // '8'
            setAttribute14((String)obj);
            return;

        case 57: // '9'
            setAttribute15((String)obj);
            return;

        case 58: // ':'
            setVehicleResponseCode((String)obj);
            return;

        case 59: // ';'
            setBudgetAmount((Number)obj);
            return;
        }
        super.setAttrInvokeAccessor(i, obj, attributedefimpl);
    }

    public void create(AttributeList attributelist)
    {
        String s = "asn.lead.scheam.server.LeadEOImpl.create";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        super.create(attributelist);
        Number number = oadbtransaction.getSequenceValue("AS_SALES_LEADS_S");
        setAttributeInternal(0, number);
        setLeadNumber(number.stringValue());
        String s1 = oadbtransaction.getProfile("ASN_DEFAULT_LEAD_STATUS");
        if(s1 != null)
            setStatusCode(s1);
        String s2 = oadbtransaction.getProfile("JTF_PROFILE_DEFAULT_CURRENCY");
        if(s2 != null)
            setCurrencyCode(s2);
        setTotalAmount(new Number(0));
        if(getTruncCreationDate() == null)
            setTruncCreationDate(new Date(getCreationDate().dateValue()));
        setAttributeInternal(24, "TAP");
        setAttributeInternal(25, "USER");
        setAttributeInternal(11, "N");
        setAttributeInternal(21, "N");
        setAttributeInternal(22, "N");
        setAttributeInternal(29, "N");
        setAttributeInternal(26, "LEAD");
        if(flag)
            oadbtransaction.writeDiagnostics(s, "end", 2);
    }

    public void remove()
    {
        String s = "asn.lead.schema.server.LeadEOImpl.remove";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        try
        {
            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_LEAD_DEL_INV_ERR");
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    protected void validateEntity()
    {
        String s = "asn.lead.schema.server.LeadEOImpl.validateEntity";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        boolean flag2 = oadbtransaction.isLoggingEnabled(4);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        try
        {
            if(getCustomerId() == null)
            {
                if(flag2)
                    oadbtransaction.writeDiagnostics(s, "Mandatory attribute CustomerId is missing. ", 4);
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CustomerId", getCustomerId(), "ASN", "ASN_CMMN_CUST_MISS_ERR");
            }
            super.validateEntity();
            if(getAcceptFlag() == null || "".equals(getAcceptFlag().trim()))
                setAttributeInternal(29, "N");
            if(getEntityState() == 2)
            {
                String s1 = (String)getPostedAttribute(2);
                if("CONVERTED_TO_OPPORTUNITY".equals(s1))
                {
                    if(flag2)
                        oadbtransaction.writeDiagnostics(s, "The lead cannot be updated if it has been already converted to opportunity. ", 4);
                    throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_LEAD_CONVUPD_INV_ERR");
                }
            }
            if(getTruncCreationDate() == null)
                setTruncCreationDate(new Date(getCreationDate().dateValue()));
            if(getTotalAmount() == null)
                setTotalAmount(new Number(0));
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            oadbtransaction.writeDiagnostics(s, "Anirban 29Jan Modified: commented call to defaultAddressId()", OAFwkConstants.STATEMENT);
            //Jeevan
            //Comment code for defaulting primary identifying address in lead
            /*if(isAttributeChanged(4) || isAttributeChanged(3))
            {
                Number number = getAddressId();
                Number number1 = getCustomerId();
                if(number == null && getEntityState() == 0)
                    defaultAddressId();
                else
                if(number != null && !leadexpert.areCustomerAndAddressValid(number1, number))
                {
                    if(flag2)
                        oadbtransaction.writeDiagnostics(s, "Cross validation between customer and address failed", 4);
                    throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_ADDR_INV_ERR");
                }
            }
            */
            //end of code comment for defaulting primary identifying address in lead
            boolean flag3 = false;
            boolean flag4 = false;
            ArrayList arraylist = getTransactionListenersList();
            for(Iterator iterator = arraylist.iterator(); !flag3 && iterator.hasNext();)
            {
                Object obj = iterator.next();
                if(obj instanceof LeadAccessEOImpl)
                    flag3 = true;
                else
                if(obj instanceof LeadContactEOImpl)
                    flag4 = true;
            }

            if(flag4)
            {
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Validating Primary Contact...", 1);
                RowIterator rowiterator = getLeadContactEO();
                rowiterator.setRowValidation(false);
                LeadContactEOImpl leadcontacteoimpl = null;
                LeadContactEOImpl leadcontacteoimpl1 = null;
                Object obj1 = null;
                Object obj2 = null;
                while(rowiterator.hasNext())
                {
                    LeadContactEOImpl leadcontacteoimpl2 = (LeadContactEOImpl)rowiterator.next();
                    String s2 = leadcontacteoimpl2.getPersonFirstName();
                    String s3 = leadcontacteoimpl2.getPersonLastName();
                    if((s2 == null || "".equals(s2.trim())) && (s3 == null || "".equals(s3.trim())))
                    {
                        if(flag1)
                        {
                            String s4 = (new StringBuffer(150)).append("PersonFirstName and PersonLastName of LeadContactEO with ContactPartyId ").append(leadcontacteoimpl2.getContactPartyId()).append(" are both NULL. Remove this contact. ").toString();
                            oadbtransaction.writeDiagnostics(s, s4, 1);
                        }
                        leadcontacteoimpl2.remove();
                    }
                }
                Number number4 = getPrimaryContactPartyId();
                int i = 0;
                HashSet hashset = new HashSet();
                rowiterator = getLeadContactEO();
                rowiterator.setRowValidation(false);
                while(rowiterator.hasNext())
                {
                    LeadContactEOImpl leadcontacteoimpl3 = (LeadContactEOImpl)rowiterator.next();
                    Number number8 = leadcontacteoimpl3.getContactPartyId();
                    if(hashset.contains(number8))
                    {
                        if(flag2)
                            oadbtransaction.writeDiagnostics(s, "The lead has one or more contacts with the same contact party ID", 4);
                        throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_CTCT_NOUNIQ_ERR");
                    }
                    hashset.add(number8);
                    if("Y".equals(leadcontacteoimpl3.getPrimaryContactFlag()))
                    {
                        if(++i > 1)
                        {
                            if(flag2)
                                oadbtransaction.writeDiagnostics(s, "The lead has more than one primary contacts", 4);
                            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_MULTPRMCTCT_ERR");
                        }
                        leadcontacteoimpl1 = leadcontacteoimpl3;
                    }
                    if(number8.equals(number4))
                        leadcontacteoimpl = leadcontacteoimpl3;
                }
                if(leadcontacteoimpl1 != null && !leadcontacteoimpl1.equals(leadcontacteoimpl))
                {
                    setPrimaryContactPartyId(leadcontacteoimpl1.getContactPartyId());
                    Number number7 = leadcontacteoimpl1.getContactPointPhoneId();
                    if((new Number(-1)).equals(number7))
                        number7 = null;
                    setPrimaryContactPhoneId(number7);
                    setPrimaryCntPersonPartyId(leadcontacteoimpl1.getContactPersonPartyId());
                } else
                if(leadcontacteoimpl1 == null && number4 != null)
                {
                    setPrimaryContactPartyId(null);
                    setPrimaryContactPhoneId(null);
                    setPrimaryCntPersonPartyId(null);
                }
                number4 = getPrimaryContactPartyId();
            }
            if(flag1)
                oadbtransaction.writeDiagnostics(s, "Validating Owner and Owner Sales Group", 1);
            Number number2 = getAssignToSalesforceId();
            Number number3 = getAssignSalesGroupId();
            RowIterator rowiterator1 = getLeadAccessEO();
            rowiterator1.setRowValidation(false);
            LeadAccessEOImpl leadaccesseoimpl = null;
            LeadAccessEOImpl leadaccesseoimpl1 = null;
            LeadAccessEOImpl leadaccesseoimpl2 = null;
            Number number5 = getLoginUserResourceId();
            Number number6 = getDefaultLoginUserGroupId();
            int j = 0;
            HashMap hashmap = new HashMap();
            boolean flag5 = false;
            while(rowiterator1.hasNext())
            {
                LeadAccessEOImpl leadaccesseoimpl3 = (LeadAccessEOImpl)rowiterator1.next();
                Number number11 = leadaccesseoimpl3.getSalesforceId();
                Number number13 = leadaccesseoimpl3.getSalesGroupId();
                boolean flag7 = leadaccesseoimpl3.getPartnerCustomerId() == null && leadaccesseoimpl3.getPartnerContPartyId() == null;
                if(flag7)
                {
                    if(hashmap.containsKey(number11))
                    {
                        ArrayList arraylist1 = (ArrayList)hashmap.get(number11);
                        if(arraylist1.contains(number13))
                            flag5 = true;
                        else
                            arraylist1.add(number13);
                    } else
                    {
                        ArrayList arraylist2 = new ArrayList(5);
                        arraylist2.add(number13);
                        hashmap.put(number11, arraylist2);
                    }
                    if("Y".equals(leadaccesseoimpl3.getOwnerFlag()))
                    {
                        j++;
                        leadaccesseoimpl1 = leadaccesseoimpl3;
                    }
                    if(flag3)
                    {
                        if(flag5)
                        {
                            if(flag2)
                                oadbtransaction.writeDiagnostics(s, "The lead sales team has duplicate resources. ", 4);
                            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_ACSS_NOUNIQ_ERR");
                        }
                        if(j > 1)
                        {
                            if(flag2)
                                oadbtransaction.writeDiagnostics(s, "The lead has multiple owners. ", 4);
                            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_MULTOWNER_ERR");
                        }
                    }
                    if(number11.equals(number2) && (number13 != null && number13.equals(number3) || number13 == null && number3 == null))
                        leadaccesseoimpl = leadaccesseoimpl3;
                    if(leadaccesseoimpl2 == null && number11.equals(number5))
                        leadaccesseoimpl2 = leadaccesseoimpl3;
                }
            }
            if(getEntityState() == 0)
            {
                if(leadaccesseoimpl2 == null)
                {
                    rowiterator1.insertRow(rowiterator1.createRow());
                    leadaccesseoimpl2 = (LeadAccessEOImpl)rowiterator1.getCurrentRow();
                    leadaccesseoimpl2.setSalesforceId(number5);
                    leadaccesseoimpl2.setSalesGroupId(number6);
                    flag3 = true;
                }
                if(leadaccesseoimpl1 == null && !"Y".equals(leadaccesseoimpl2.getOwnerFlag()))
                {
                    leadaccesseoimpl2.setOwnerFlag("Y");
                    leadaccesseoimpl1 = leadaccesseoimpl2;
                    flag3 = true;
                }
                if(!"Y".equals(leadaccesseoimpl2.getFreezeFlag()))
                {
                    leadaccesseoimpl2.setFreezeFlag("Y");
                    flag3 = true;
                }
            }
            if(flag3)
                if(leadaccesseoimpl1 == null)
                {
                    if(number2 != null)
                    {
                        setAssignToSalesforceId(null);
                        setAssignSalesGroupId(null);
                        setAssignToPersonId(null);
                    }
                } else
                if(!leadaccesseoimpl1.equals(leadaccesseoimpl))
                {
                    setAssignToSalesforceId(leadaccesseoimpl1.getSalesforceId());
                    setAssignSalesGroupId(leadaccesseoimpl1.getSalesGroupId());
                    setAssignToPersonId(leadaccesseoimpl1.getPersonId());
                }
            if(flag1)
                oadbtransaction.writeDiagnostics(s, "Validating SalesStageId and SalesMethodologyId", 1);
            Number number9 = getSalesStageId();
            Number number12 = getSalesMethodologyId();
            if(number12 == null && number9 != null)
            {
                if(flag2)
                    oadbtransaction.writeDiagnostics(s, "Sales stage cannot be specified without a sales methodology", 4);
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "SalesStageId", number9, "ASN", "ASN_CMMN_SLSSTG_REQMETH_ERR");
            }
            if(number12 != null)
                if(number9 != null)
                {
                    if(!leadexpert.areSalesMethodologyAndStageValid(number12, number9))
                    {
                        if(flag2)
                            oadbtransaction.writeDiagnostics(s, "Cross validation between sales methodology and sales stage failed", 4);
                        throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_SLSMETHSTAGE_INV_ERR");
                    }
                } else
                {
                    Number number10 = leadexpert.getFirstApplicableSalesStage(number12);
                    if(number10 != null)
                        setAttributeInternal(13, number10);
                }
            if(!isInvalid() && (isAttributeChanged(9) || isAttributeChanged(2)))
            {
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Validating CloseReason and StatusCode", 1);
                boolean flag6 = leadexpert.isStatusOpen(getStatusCode());
                String s5 = getCloseReason();
                if(flag6 && s5 != null && !"".equals(s5.trim()))
                {
                    if(flag2)
                        oadbtransaction.writeDiagnostics(s, "Close reason should not be specified with when status is open", 4);
                    throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CloseReason", s5, "ASN", "ASN_CMMN_OPENSTS_CLSRSN_ERR");
                }
                if(!flag6 && (s5 == null || "".equals(s5.trim())))
                {
                    if(flag2)
                        oadbtransaction.writeDiagnostics(s, "Close reason is required when status is closed", 4);
                    throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CloseReason", s5, "ASN", "ASN_CMMN_CLSSTS_REQCLSRSN_ERR");
                }
            }
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    public void postChanges(TransactionEvent transactionevent)
    {
        String s = "asn.lead.schema.server.LeadEOImpl.postChanges";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        boolean flag2 = oadbtransaction.isLoggingEnabled(4);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        byte byte0 = getEntityState();
        if(getObjectTypeCode() == null)
            populateAttribute(26, "LEAD");
        if(isAttributeValueChanged(2) || isAttributeValueChanged(15) || isAttributeValueChanged(16) || isAttributeValueChanged(10) || isAttributeValueChanged(22))
        {
            RowIterator rowiterator = getLeadLogEO();
            rowiterator.setRowValidation(false);
            rowiterator.insertRow(rowiterator.createRow());
            LeadLogEOImpl leadlogeoimpl = (LeadLogEOImpl)rowiterator.getCurrentRow();
            if(byte0 == 0)
            {
                if(getLeadRankId() != null && getLeadEngineRunDate() == null)
                    leadlogeoimpl.setManualRankFlag("Y");
            } else
            if(byte0 == 2 && isAttributeChanged(10))
                leadlogeoimpl.setManualRankFlag("Y");
            if(flag1)
                oadbtransaction.writeDiagnostics(s, "Inserted log entry", 1);
        }
        super.postChanges(transactionevent);
        try
        {
            createSalesCycle();
            Number number = getLoginUserResourceId();
            Number number1 = getDefaultLoginUserGroupId();
            if(byte0 == 0)
            {
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Running Post Lead Create Process", 1);
                String s1 = (new StringBuffer(800)).append("BEGIN ASN_SALES_PVT.Lead_Process_After_Create(").append("  P_Api_Version_Number     => 2.0").append(", P_Init_Msg_List          => FND_API.G_TRUE").append(", p_Commit                 => FND_API.G_FALSE").append(", p_Validation_Level       => FND_API.G_VALID_LEVEL_NONE").append(", P_Identity_Salesforce_Id => :1").append(", P_Salesgroup_id          => :2").append(", P_Sales_Lead_Id          => :3").append(", X_Return_Status          => :4").append(", X_Msg_Count              => :5").append(", X_Msg_Data               => :6); END; ").toString();
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "PLSQL = " + s1, 1);
                OracleCallableStatement oraclecallablestatement = null;
                Object obj = null;
                boolean flag3 = false;
                String s5 = "";
                try
                {
                    oraclecallablestatement = (OracleCallableStatement)oadbtransaction.createCallableStatement(s1, 1);
                    int k = 1;
                    oraclecallablestatement.setNUMBER(k++, number);
                    oraclecallablestatement.setNUMBER(k++, number1);
                    oraclecallablestatement.setNUMBER(k++, getSalesLeadId());
                    int i1 = k;
                    oraclecallablestatement.registerOutParameter(k++, 12, 0, 1);
                    oraclecallablestatement.registerOutParameter(k++, 2);
                    oraclecallablestatement.registerOutParameter(k, 12, 0, 2000);
                    oraclecallablestatement.execute();
                    String s3 = oraclecallablestatement.getString(i1++);
                    int i = oraclecallablestatement.getInt(i1++);
                    String s6 = oraclecallablestatement.getString(i1++);
                    OAExceptionUtils.checkErrors(oadbtransaction, i, s3, s6);
                }
                catch(Exception exception3)
                {
                    throw OAException.wrapperException(exception3);
                }
                finally
                {
                    try
                    {
                        oraclecallablestatement.close();
                    }
                    catch(SQLException sqlexception)
                    {
                        throw OAException.wrapperException(sqlexception);
                    }
                }
            } else
            if(byte0 == 2)
            {
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Running Post Lead Update Process", 1);
                String s2 = (new StringBuffer(800)).append("BEGIN ASN_SALES_PVT.Lead_Process_After_Update(").append("  P_Api_Version_Number     => 2.0").append(", P_Init_Msg_List          => FND_API.G_TRUE").append(", p_Commit                 => FND_API.G_FALSE").append(", p_Validation_Level       => FND_API.G_VALID_LEVEL_NONE").append(", P_Identity_Salesforce_Id => :1").append(", P_Salesgroup_id          => :2").append(", P_Sales_Lead_Id          => :3").append(", X_Return_Status          => :4").append(", X_Msg_Count              => :5").append(", X_Msg_Data               => :6); END; ").toString();
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "PLSQL = " + s2, 1);
                OracleCallableStatement oraclecallablestatement1 = null;
                String s4 = null;
                boolean flag4 = false;
                String s7 = "";
                try
                {
                    oraclecallablestatement1 = (OracleCallableStatement)oadbtransaction.createCallableStatement(s2, 1);
                    int l = 1;
                    oraclecallablestatement1.setNUMBER(l++, number);
                    oraclecallablestatement1.setNUMBER(l++, number1);
                    oraclecallablestatement1.setNUMBER(l++, getSalesLeadId());
                    int j1 = l;
                    oraclecallablestatement1.registerOutParameter(l++, 12, 0, 1);
                    oraclecallablestatement1.registerOutParameter(l++, 2);
                    oraclecallablestatement1.registerOutParameter(l, 12, 0, 2000);
                    oraclecallablestatement1.execute();
                    s4 = oraclecallablestatement1.getString(j1++);
                    int j = oraclecallablestatement1.getInt(j1++);
                    String s8 = oraclecallablestatement1.getString(j1);
                    OAExceptionUtils.checkErrors(oadbtransaction, j, s4, s8);
                }
                catch(Exception exception4)
                {
                    OAException oaexception = OAException.wrapperException(exception4);
                    if("W".equals(s4))
                    {
                        if(flag2)
                        {
                            Throwable athrowable[] = oaexception.getExceptions();
                            if(athrowable != null && athrowable.length > 0)
                            {
                                for(int k1 = 0; k1 < athrowable.length; k1++)
                                {
                                    OAException oaexception1 = (OAException)athrowable[k1];
                                    oadbtransaction.writeDiagnostics(s, "Warning: " + oaexception1.getMessage(), 4);
                                }

                            }
                        }
                    } else
                    {
                        throw oaexception;
                    }
                }
                finally
                {
                    try
                    {
                        oraclecallablestatement1.close();
                    }
                    catch(SQLException sqlexception1)
                    {
                        throw OAException.wrapperException(sqlexception1);
                    }
                }
            }
            refresh(0);
            RowSet rowset = (RowSet)getLeadAccessEO();
            rowset.setRowValidation(false);
            ViewObjectImpl viewobjectimpl = (ViewObjectImpl)rowset.getViewObject();
            viewobjectimpl.clearCache();
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
     }

    protected void handlePostChangesError()
    {
        String s = "asn.lead.schema.server.LeadEOImpl.handlePostChangesError";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        oadbtransaction.isLoggingEnabled(1);
        oadbtransaction.isLoggingEnabled(4);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        try
        {
            super.handlePostChangesError();
            RowSet rowset = (RowSet)getRelationshipEO();
            ViewObjectImpl viewobjectimpl = (ViewObjectImpl)rowset.getViewObject();
            viewobjectimpl.clearCache();
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    protected void doDML(int i, TransactionEvent transactionevent)
    {
        String s = "asn.lead.schema.server.LeadEOImpl.doDML";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        try
        {
            if(i == 2)
            {
                ArrayList arraylist = new ArrayList();
                for(Iterator iterator = LeadAccessEOImpl.getDefinitionObject().getAllEntityInstancesIterator(oadbtransaction); iterator.hasNext();)
                {
                    LeadAccessEOImpl leadaccesseoimpl = (LeadAccessEOImpl)iterator.next();
                    if(getSalesLeadId().equals(leadaccesseoimpl.getSalesLeadId()))
                        if(leadaccesseoimpl.getEntityState() == 3)
                            leadaccesseoimpl.postChanges(transactionevent);
                        else
                        if(leadaccesseoimpl.getEntityState() == 2)
                            arraylist.add(leadaccesseoimpl);
                }

                LeadAccessEOImpl leadaccesseoimpl1;
                for(Iterator iterator1 = arraylist.iterator(); iterator1.hasNext(); leadaccesseoimpl1.postChanges(transactionevent))
                    leadaccesseoimpl1 = (LeadAccessEOImpl)iterator1.next();

            }
            super.doDML(i, transactionevent);
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    public RowIterator getLeadLineEO()
    {
        return (RowIterator)getAttributeInternal(60);
    }

    public RowIterator getLeadContactEO()
    {
        return (RowIterator)getAttributeInternal(61);
    }

    public RowIterator getLeadLogEO()
    {
        return (RowIterator)getAttributeInternal(62);
    }

    public RowIterator getLeadAccessEO()
    {
        return (RowIterator)getAttributeInternal(64);
    }

    public Number getSalesStageId()
    {
        return (Number)getAttributeInternal(13);
    }

    public void setSalesStageId(Number number)
    {
        if(number != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!leadexpert.isSalesStageValid(number))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "SalesStageId", number, "ASN", "ASN_CMMN_SLSSTAGE_INV_ERR");
        }
        setAttributeInternal(13, number);
    }

    public Number getSalesMethodologyId()
    {
        return (Number)getAttributeInternal(14);
    }

    public void setSalesMethodologyId(Number number)
    {
        Number number1 = getEntityState() != 0 ? (Number)getPostedAttribute(14) : null;
        if(number1 != null && !number1.equals(number))
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "SalesMethodologyId", number, "ASN", "ASN_CMMN_SLSMETHUPD_INV_ERR");
        if(number != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!leadexpert.isSalesMethodologyValid(number))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "SalesMethodologyId", number, "ASN", "ASN_CMMN_SLSMETH_INV_ERR");
        }
        setAttributeInternal(14, number);
    }

    public void setObjectTypeCode(String s)
    {
        setAttributeInternal(26, s);
    }

    public Number convertLeadToOpportunity()
    {
        String s = "asn.lead.schema.server.LeadEOImpl.convertLeadToOpportunity";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        boolean flag2 = oadbtransaction.isLoggingEnabled(4);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "Begin", 2);
        OpportunityEOImpl opportunityeoimpl = null;
        try
        {
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            String s1 = getStatusCode();
            if("CONVERTED_TO_OPPORTUNITY".equals(s1))
            {
                if(flag2)
                    oadbtransaction.writeDiagnostics(s, "The lead may not be converted to opportunity because it's already converted to an opportunity", 4);
                throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_LEAD_CONV_CONVSTS_ERR");
            }
            if(!leadexpert.isStatusOpen(s1))
            {
                if(flag2)
                    oadbtransaction.writeDiagnostics(s, "The lead may not be converted to an opportunity because it is at a closed status. ", 4);
                throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_LEAD_CONV_CLSSTS_ERR");
            }
            createSalesCycle();
            int i = oadbtransaction.getValidationThreshold();
            for(int j = 0; j < i; j++)
                oadbtransaction.validate();

            oadbtransaction.postChanges();
            String s2 = getStatusCode();
            if("CONVERTED_TO_OPPORTUNITY".equals(s2))
            {
                Number number = getLeadOpportunityEO().getOpportunityId();
                return number;
            }
            opportunityeoimpl = (OpportunityEOImpl)oadbtransaction.createEntityInstance(OpportunityEOImpl.getDefinitionObject(), null);
            if(opportunityeoimpl != null)
            {
                opportunityeoimpl.setCustomerId(getCustomerId());
                opportunityeoimpl.setAddressId(getAddressId());
                opportunityeoimpl.setChannelCode(getChannelCode());
                opportunityeoimpl.setCurrencyCode(getCurrencyCode());
                String s3 = getDescription();
                if(s3 != null && s3.length() >= 240)
                    s3 = s3.substring(0, 240);
                opportunityeoimpl.setDescription(s3);
                opportunityeoimpl.setSourcePromotionId(getSourcePromotionId());
                opportunityeoimpl.setSalesMethodologyId(getSalesMethodologyId());
                Number number1 = getSalesStageId();
                String s4 = leadexpert.getSalesStageApplicability(number1);
                if("BOTH".equals(s4))
                    opportunityeoimpl.setSalesStageId(number1);
                opportunityeoimpl.setAttribute1(getAttribute1());
                opportunityeoimpl.setAttribute2(getAttribute2());
                opportunityeoimpl.setAttribute3(getAttribute3());
                opportunityeoimpl.setAttribute4(getAttribute4());
                opportunityeoimpl.setAttribute5(getAttribute5());
                opportunityeoimpl.setAttribute6(getAttribute6());
                opportunityeoimpl.setAttribute7(getAttribute7());
                opportunityeoimpl.setAttribute8(getAttribute8());
                opportunityeoimpl.setAttribute9(getAttribute9());
                opportunityeoimpl.setAttribute10(getAttribute10());
                opportunityeoimpl.setAttribute11(getAttribute11());
                opportunityeoimpl.setAttribute12(getAttribute12());
                opportunityeoimpl.setAttribute13(getAttribute13());
                opportunityeoimpl.setAttribute14(getAttribute14());
                opportunityeoimpl.setAttribute15(getAttribute15());
                opportunityeoimpl.setAttributeCategory(getAttributeCategory());
                opportunityeoimpl.setVehicleResponseCode(getVehicleResponseCode());
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Copying sales team to opportunity", 1);
                RowIterator rowiterator = opportunityeoimpl.getOpportunityAccessEO();
                rowiterator.setRowValidation(false);
                RowSet rowset = (RowSet)getLeadAccessEO();
                rowset.setRowValidation(false);
                LeadAccessEOImpl leadaccesseoimpl;
                OpportunityAccessEOImpl opportunityaccesseoimpl;
                for(; rowset.hasNext(); opportunityaccesseoimpl.setAttributeCategory(leadaccesseoimpl.getAttributeCategory()))
                {
                    leadaccesseoimpl = (LeadAccessEOImpl)rowset.next();
                    rowiterator.insertRow(rowiterator.createRow());
                    opportunityaccesseoimpl = (OpportunityAccessEOImpl)rowiterator.getCurrentRow();
                    opportunityaccesseoimpl.setCustomerId(leadaccesseoimpl.getCustomerId());
                    opportunityaccesseoimpl.setSalesforceId(leadaccesseoimpl.getSalesforceId());
                    opportunityaccesseoimpl.setSalesGroupId(leadaccesseoimpl.getSalesGroupId());
                    opportunityaccesseoimpl.setFreezeFlag(leadaccesseoimpl.getFreezeFlag());
                    opportunityaccesseoimpl.setCreatedByTapFlag(leadaccesseoimpl.getCreatedByTapFlag());
                    opportunityaccesseoimpl.setTeamLeaderFlag(leadaccesseoimpl.getTeamLeaderFlag());
                    opportunityaccesseoimpl.setOwnerFlag("N");
                    opportunityaccesseoimpl.setPartnerCustomerId(leadaccesseoimpl.getPartnerCustomerId());
                    opportunityaccesseoimpl.setPartnerAddressId(leadaccesseoimpl.getPartnerAddressId());
                    opportunityaccesseoimpl.setPartnerContPartyId(leadaccesseoimpl.getPartnerContPartyId());
                    opportunityaccesseoimpl.setAttribute1(leadaccesseoimpl.getAttribute1());
                    opportunityaccesseoimpl.setAttribute2(leadaccesseoimpl.getAttribute2());
                    opportunityaccesseoimpl.setAttribute3(leadaccesseoimpl.getAttribute3());
                    opportunityaccesseoimpl.setAttribute4(leadaccesseoimpl.getAttribute4());
                    opportunityaccesseoimpl.setAttribute5(leadaccesseoimpl.getAttribute5());
                    opportunityaccesseoimpl.setAttribute6(leadaccesseoimpl.getAttribute6());
                    opportunityaccesseoimpl.setAttribute7(leadaccesseoimpl.getAttribute7());
                    opportunityaccesseoimpl.setAttribute8(leadaccesseoimpl.getAttribute8());
                    opportunityaccesseoimpl.setAttribute9(leadaccesseoimpl.getAttribute9());
                    opportunityaccesseoimpl.setAttribute10(leadaccesseoimpl.getAttribute10());
                    opportunityaccesseoimpl.setAttribute11(leadaccesseoimpl.getAttribute11());
                    opportunityaccesseoimpl.setAttribute12(leadaccesseoimpl.getAttribute12());
                    opportunityaccesseoimpl.setAttribute13(leadaccesseoimpl.getAttribute13());
                    opportunityaccesseoimpl.setAttribute14(leadaccesseoimpl.getAttribute14());
                    opportunityaccesseoimpl.setAttribute15(leadaccesseoimpl.getAttribute15());
                }

                opportunityeoimpl.setLoginUserAsOwner();
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Copying lead lines to opportunity", 1);
                RowIterator rowiterator1 = opportunityeoimpl.getOpportunityLineEO();
                RowIterator rowiterator2 = getLeadLineEO();
                rowiterator1.setRowValidation(false);
                rowiterator2.setRowValidation(false);
                OpportunityLineEOImpl opportunitylineeoimpl;
                for(; rowiterator2.hasNext(); rowiterator1.insertRow(opportunitylineeoimpl))
                {
                    LeadLineEOImpl leadlineeoimpl = (LeadLineEOImpl)rowiterator2.next();
                    leadlineeoimpl.getSalesLeadLineId();
                    opportunitylineeoimpl = (OpportunityLineEOImpl)rowiterator1.createRow();
                    opportunitylineeoimpl.setProductCategoryId(leadlineeoimpl.getCategoryId());
                    opportunitylineeoimpl.setProductCatSetId(leadlineeoimpl.getCategorySetId());
                    if(leadlineeoimpl.getInventoryItemId() != null)
                    {
                        opportunitylineeoimpl.setInventoryItemId(leadlineeoimpl.getInventoryItemId());
                        opportunitylineeoimpl.setOrganizationId(leadlineeoimpl.getOrganizationId());
                        opportunitylineeoimpl.setUomCode(leadlineeoimpl.getUomCode());
                    }
                    opportunitylineeoimpl.setQuantity(leadlineeoimpl.getQuantity());
                    opportunitylineeoimpl.setTotalAmount(leadlineeoimpl.getBudgetAmount());
                    opportunitylineeoimpl.setAttribute1(leadlineeoimpl.getAttribute1());
                    opportunitylineeoimpl.setAttribute2(leadlineeoimpl.getAttribute2());
                    opportunitylineeoimpl.setAttribute3(leadlineeoimpl.getAttribute3());
                    opportunitylineeoimpl.setAttribute4(leadlineeoimpl.getAttribute4());
                    opportunitylineeoimpl.setAttribute5(leadlineeoimpl.getAttribute5());
                    opportunitylineeoimpl.setAttribute6(leadlineeoimpl.getAttribute6());
                    opportunitylineeoimpl.setAttribute7(leadlineeoimpl.getAttribute7());
                    opportunitylineeoimpl.setAttribute8(leadlineeoimpl.getAttribute8());
                    opportunitylineeoimpl.setAttribute9(leadlineeoimpl.getAttribute9());
                    opportunitylineeoimpl.setAttribute10(leadlineeoimpl.getAttribute10());
                    opportunitylineeoimpl.setAttribute11(leadlineeoimpl.getAttribute11());
                    opportunitylineeoimpl.setAttribute12(leadlineeoimpl.getAttribute12());
                    opportunitylineeoimpl.setAttribute13(leadlineeoimpl.getAttribute13());
                    opportunitylineeoimpl.setAttribute14(leadlineeoimpl.getAttribute14());
                    opportunitylineeoimpl.setAttribute15(leadlineeoimpl.getAttribute15());
                    opportunitylineeoimpl.setAttributeCategory(leadlineeoimpl.getAttributeCategory());
                }

                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Copying contacts to opportunity", 1);
                RowIterator rowiterator3 = opportunityeoimpl.getOpportunityContactEO();
                RowIterator rowiterator4 = getLeadContactEO();
                rowiterator3.setRowValidation(false);
                rowiterator4.setRowValidation(false);
                OpportunityContactEOImpl opportunitycontacteoimpl;
                for(; rowiterator4.hasNext(); rowiterator3.insertRow(opportunitycontacteoimpl))
                {
                    LeadContactEOImpl leadcontacteoimpl = (LeadContactEOImpl)rowiterator4.next();
                    opportunitycontacteoimpl = (OpportunityContactEOImpl)rowiterator3.createRow();
                    opportunitycontacteoimpl.setCustomerId(leadcontacteoimpl.getCustomerId());
                    opportunitycontacteoimpl.setContactPartyId(leadcontacteoimpl.getContactPartyId());
                    opportunitycontacteoimpl.setPrimaryContactFlag(leadcontacteoimpl.getPrimaryContactFlag());
                    opportunitycontacteoimpl.setRank(leadcontacteoimpl.getContactRoleCode());
                    opportunitycontacteoimpl.setAttribute1(leadcontacteoimpl.getAttribute1());
                    opportunitycontacteoimpl.setAttribute2(leadcontacteoimpl.getAttribute2());
                    opportunitycontacteoimpl.setAttribute3(leadcontacteoimpl.getAttribute3());
                    opportunitycontacteoimpl.setAttribute4(leadcontacteoimpl.getAttribute4());
                    opportunitycontacteoimpl.setAttribute5(leadcontacteoimpl.getAttribute5());
                    opportunitycontacteoimpl.setAttribute6(leadcontacteoimpl.getAttribute6());
                    opportunitycontacteoimpl.setAttribute7(leadcontacteoimpl.getAttribute7());
                    opportunitycontacteoimpl.setAttribute8(leadcontacteoimpl.getAttribute8());
                    opportunitycontacteoimpl.setAttribute9(leadcontacteoimpl.getAttribute9());
                    opportunitycontacteoimpl.setAttribute10(leadcontacteoimpl.getAttribute10());
                    opportunitycontacteoimpl.setAttribute11(leadcontacteoimpl.getAttribute11());
                    opportunitycontacteoimpl.setAttribute12(leadcontacteoimpl.getAttribute12());
                    opportunitycontacteoimpl.setAttribute13(leadcontacteoimpl.getAttribute13());
                    opportunitycontacteoimpl.setAttribute14(leadcontacteoimpl.getAttribute14());
                    opportunitycontacteoimpl.setAttribute15(leadcontacteoimpl.getAttribute15());
                    opportunitycontacteoimpl.setAttributeCategory(leadcontacteoimpl.getAttributeCategory());
                }

                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Copying sales cycle to opportunity", 1);
                RowIterator rowiterator5 = opportunityeoimpl.getRelationshipEO();
                rowiterator5.setRowValidation(false);
                RowSet rowset1 = (RowSet)getRelationshipEO();
                rowset1.setRowValidation(false);
                if(!rowset1.isExecuted())
                    rowset1.executeQuery();
                while(rowset1.hasNext())
                {
                    RelationshipEOImpl relationshipeoimpl = (RelationshipEOImpl)rowset1.next();
                    if("SALES_CYCLE".equals(relationshipeoimpl.getRelationshipTypeCode()))
                    {
                        rowiterator5.insertRow(rowiterator5.createRow());
                        RelationshipEOImpl relationshipeoimpl1 = (RelationshipEOImpl)rowiterator5.getCurrentRow();
                        relationshipeoimpl1.setRelatedObjectId(relationshipeoimpl.getRelatedObjectId());
                        relationshipeoimpl1.setRelatedObjectTypeCode(relationshipeoimpl.getRelatedObjectTypeCode());
                        relationshipeoimpl1.setRelationshipTypeCode(relationshipeoimpl.getRelationshipTypeCode());
                        relationshipeoimpl1.setAttribute1(relationshipeoimpl.getAttribute1());
                        relationshipeoimpl1.setAttribute2(relationshipeoimpl.getAttribute2());
                        relationshipeoimpl1.setAttribute3(relationshipeoimpl.getAttribute3());
                        relationshipeoimpl1.setAttribute4(relationshipeoimpl.getAttribute4());
                        relationshipeoimpl1.setAttribute5(relationshipeoimpl.getAttribute5());
                        relationshipeoimpl1.setAttribute6(relationshipeoimpl.getAttribute6());
                        relationshipeoimpl1.setAttribute7(relationshipeoimpl.getAttribute7());
                        relationshipeoimpl1.setAttribute8(relationshipeoimpl.getAttribute8());
                        relationshipeoimpl1.setAttribute9(relationshipeoimpl.getAttribute9());
                        relationshipeoimpl1.setAttribute10(relationshipeoimpl.getAttribute10());
                        relationshipeoimpl1.setAttribute11(relationshipeoimpl.getAttribute11());
                        relationshipeoimpl1.setAttribute12(relationshipeoimpl.getAttribute12());
                        relationshipeoimpl1.setAttribute13(relationshipeoimpl.getAttribute13());
                        relationshipeoimpl1.setAttribute14(relationshipeoimpl.getAttribute14());
                        relationshipeoimpl1.setAttribute15(relationshipeoimpl.getAttribute15());
                        relationshipeoimpl1.setAttributeCategory(relationshipeoimpl.getAttributeCategory());
                    }
                }
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Creating lead to opportunity interaction data", 1);
                LeadOpportunityEOImpl leadopportunityeoimpl = (LeadOpportunityEOImpl)oadbtransaction.createEntityInstance(LeadOpportunityEOImpl.getDefinitionObject(), null);
                leadopportunityeoimpl.setSalesLeadId(getSalesLeadId());
                leadopportunityeoimpl.setOpportunityId(opportunityeoimpl.getLeadId());
                for(int k = 0; k < i; k++)
                    oadbtransaction.validate();

                oadbtransaction.postChanges();
                Number anumber[] = leadexpert.getNoteIds(getSalesLeadId());
                if(anumber != null && anumber.length > 0)
                {
                    for(int l = 0; l < anumber.length; l++)
                    {
                        Number number2 = anumber[l];
                        CacNotesEOImpl cacnoteseoimpl = (CacNotesEOImpl)oadbtransaction.findByPrimaryKey(CacNotesEOImpl.getDefinitionObject(), new Key(new Object[] {
                            number2
                        }));
                        if(cacnoteseoimpl != null)
                        {
                            for(RowIterator rowiterator6 = cacnoteseoimpl.getCacNoteContextsEO(); rowiterator6.hasNext();)
                            {
                                CacNoteContextsEOImpl cacnotecontextseoimpl = (CacNoteContextsEOImpl)rowiterator6.next();
                                if("LEAD".equals(cacnotecontextseoimpl.getNoteContextType()))
                                {
                                    CacNoteContextsEOImpl cacnotecontextseoimpl1 = (CacNoteContextsEOImpl)rowiterator6.createRow();
                                    cacnotecontextseoimpl1.setNoteContextId(oadbtransaction.getSequenceValue("JTF_NOTES_S"));
                                    cacnotecontextseoimpl1.setNoteContextType("OPPORTUNITY");
                                    cacnotecontextseoimpl1.setNoteContextTypeId(opportunityeoimpl.getLeadId());
                                    cacnotecontextseoimpl1.insertRow();
                                }
                            }

                        }
                    }

                }
                setStatusCode("CONVERTED_TO_OPPORTUNITY");
                String as[] = new String[1];
                as[0] = new String(getSalesLeadId().toString());
                boolean flag3 = OAAttachmentServerUtils.attachmentExists((OAApplicationModule)oadbtransaction.getRootApplicationModule(), "AS_LEAD_ATTCH", as);
                if(flag3)
                    copyAttachmentsFromLeadToOppty(getSalesLeadId().toString(), opportunityeoimpl.getLeadId().toString());
            }
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
        if(opportunityeoimpl == null)
            return null;
        else
            return opportunityeoimpl.getLeadId();
    }

    public void runLeadEngines()
    {
        String s = "asn.lead.schema.server.LeadEOImpl.runLeadEngines";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        boolean flag2 = oadbtransaction.isLoggingEnabled(4);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        try
        {
            if("CONVERTED_TO_OPPORTUNITY".equals(getStatusCode()))
            {
                if(flag2)
                    oadbtransaction.writeDiagnostics(s, (new StringBuffer(200)).append("Lead engines may not run on the lead ").append("because the lead has been converted to an opportunity. ").toString(), 4);
                throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_LEAD_CONVUPD_INV_ERR");
            }
            validateEntity();
            super.postChanges(new TransactionEvent(oadbtransaction));
            Number number = getLoginUserResourceId();
            Number number1 = getDefaultLoginUserGroupId();
            if(flag1)
                oadbtransaction.writeDiagnostics(s, "Running lead engines", 1);
            String s1 = (new StringBuffer(800)).append("BEGIN AS_SALES_LEADS_PUB.Run_Lead_Engines(").append("  P_Api_Version_Number     => 2.0").append(", P_Init_Msg_List          => FND_API.G_TRUE").append(", p_Commit                 => FND_API.G_FALSE").append(", p_Validation_Level       => FND_API.G_VALID_LEVEL_NONE").append(", P_Admin_Group_Id         => NULL").append(", P_Identity_Salesforce_Id => :1").append(", P_Salesgroup_id          => :2").append(", P_Sales_Lead_Id          => :3").append(", X_Sales_Team_Flag        => :4").append(", X_Return_Status          => :5").append(", X_Msg_Count              => :6").append(", X_Msg_Data               => :7); END; ").toString();
            if(flag1)
                oadbtransaction.writeDiagnostics(s, "PLSQL = " + s1, 1);
            OracleCallableStatement oraclecallablestatement = null;
            Object obj = null;
            boolean flag3 = false;
            String s3 = "";
            try
            {
                oraclecallablestatement = (OracleCallableStatement)oadbtransaction.createCallableStatement(s1, 1);
                int j = 1;
                oraclecallablestatement.setNUMBER(j++, number);
                oraclecallablestatement.setNUMBER(j++, number1);
                oraclecallablestatement.setNUMBER(j++, getSalesLeadId());
                oraclecallablestatement.registerOutParameter(j++, 12, 0, 1);
                int k = j;
                oraclecallablestatement.registerOutParameter(j++, 12, 0, 1);
                oraclecallablestatement.registerOutParameter(j++, 2);
                oraclecallablestatement.registerOutParameter(j, 12, 0, 2000);
                oraclecallablestatement.execute();
                String s2 = oraclecallablestatement.getString(k++);
                int i = oraclecallablestatement.getInt(k++);
                String s4 = oraclecallablestatement.getString(k++);
                OAExceptionUtils.checkErrors(oadbtransaction, i, s2, s4);
                refresh(0);
            }
            catch(Exception exception2)
            {
                throw OAException.wrapperException(exception2);
            }
            finally
            {
                try
                {
                    oraclecallablestatement.close();
                }
                catch(SQLException sqlexception)
                {
                    throw OAException.wrapperException(sqlexception);
                }
            }
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    private boolean hasSalesCycle()
    {
        String s = "asn.lead.schema.server.LeadEOImpl.hasSalesCycle";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        boolean flag1 = false;
        RowSet rowset = (RowSet)getRelationshipEO();
        if(!rowset.isExecuted())
            rowset.executeQuery();
        rowset.setRowValidation(false);
        while(rowset.hasNext())
        {
            RelationshipEOImpl relationshipeoimpl = (RelationshipEOImpl)rowset.next();
            if("SALES_CYCLE".equals(relationshipeoimpl.getRelationshipTypeCode()))
            {
                flag1 = true;
                break;
            }
        }
        if(flag)
            oadbtransaction.writeDiagnostics(s, "end", 2);
        return flag1;
    }

    public boolean isSalesCycleMissing()
    {
        String s = "asn.lead.schema.server.LeadEOImpl.isSalesCycleMissing";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        oadbtransaction.isLoggingEnabled(1);
        boolean flag1 = true;
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        Number number = getEntityState() != 0 ? (Number)getPostedAttribute(14) : null;
        flag1 = number != null && !hasSalesCycle();
        if(flag)
            oadbtransaction.writeDiagnostics(s, "end", 2);
        return flag1;
    }

    public boolean createSalesCycle()
    {
        String s = "asn.lead.schema.server.LeadEOImpl.createSalesCycle";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        boolean flag2 = oadbtransaction.isLoggingEnabled(4);
        boolean flag3 = false;
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        try
        {
            if(getSalesMethodologyId() != null && !hasSalesCycle())
            {
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Creating sales cycle", 1);
                String s1 = (new StringBuffer(800)).append("BEGIN ASN_METHODOLOGY_PVT.Create_Sales_Meth_Data(").append("  p_api_version_number   => 1.0").append(", p_init_msg_list        => FND_API.G_TRUE").append(", p_commit               => FND_API.G_FALSE").append(", p_object_type_code     => :1").append(", p_object_id            => :2").append(", p_sales_methodology_id => :3").append(", x_return_status        => :4").append(", x_msg_count            => :5").append(", x_msg_data             => :6); END;").toString();
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "PLSQL = " + s1, 1);
                OracleCallableStatement oraclecallablestatement = null;
                Object obj = null;
                boolean flag4 = false;
                String s3 = "";
                try
                {
                    oraclecallablestatement = (OracleCallableStatement)oadbtransaction.createCallableStatement(s1, 1);
                    int j = 1;
                    oraclecallablestatement.setString(j++, getObjectTypeCode());
                    oraclecallablestatement.setNUMBER(j++, getSalesLeadId());
                    oraclecallablestatement.setNUMBER(j++, getSalesMethodologyId());
                    int k = j;
                    oraclecallablestatement.registerOutParameter(j++, 12, 0, 1);
                    oraclecallablestatement.registerOutParameter(j++, 2);
                    oraclecallablestatement.registerOutParameter(j, 12, 0, 2000);
                    if(flag1)
                        oadbtransaction.writeDiagnostics(s, "postChanges: Calling ASN_METHODOLOGY_PVT.Create_Sales_Meth_Data", 1);
                    oraclecallablestatement.execute();
                    if(flag1)
                        oadbtransaction.writeDiagnostics(s, "postChanges: End calling ASN_METHODOLOGY_PVT.Create_Sales_Meth_Data", 1);
                    String s2 = oraclecallablestatement.getString(k++);
                    int i = oraclecallablestatement.getInt(k++);
                    String s4 = oraclecallablestatement.getString(k++);
                    OAExceptionUtils.checkErrors(oadbtransaction, i, s2, s4);
                    flag3 = hasSalesCycle();
                    if(flag3 && flag1)
                        oadbtransaction.writeDiagnostics(s, "Sales cycle transactional data has been successfully created. ", 1);
                }
                catch(Exception exception2)
                {
                    if(flag2)
                    {
                        StringBuffer stringbuffer = new StringBuffer(100);
                        stringbuffer.append("Exception while creating sales meth, ex=").append(exception2);
                        oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                        stringbuffer = null;
                    }
                    throw OAException.wrapperException(exception2);
                }
                finally
                {
                    try
                    {
                        oraclecallablestatement.close();
                    }
                    catch(SQLException sqlexception)
                    {
                        throw OAException.wrapperException(sqlexception);
                    }
                }
            } else
            if(flag1)
                oadbtransaction.writeDiagnostics(s, "Sales methodology is not specified or sales cycle already exists. ", 1);
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
        return flag3;
    }

    private void copyAttachmentsFromLeadToOppty(String s, String s1)
    {
        String s2 = "asn.lead.schema.server.LeadEOImpl.copyAttachmentsFromLeadToOppty";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        boolean flag2 = oadbtransaction.isLoggingEnabled(4);
        if(flag)
        {
            StringBuffer stringbuffer = (new StringBuffer(50)).append("begin").append("input parameters ").append(" lead id = ").append(s).append(" opportunity id = ").append(s1);
            oadbtransaction.writeDiagnostics(s2, stringbuffer.toString(), 2);
            stringbuffer = null;
        }
        try
        {
            if(s != null && s1 != null)
            {
                if(flag1)
                    oadbtransaction.writeDiagnostics(s2, "Copying the attachment", 1);
                String s3 = (new StringBuffer(800)).append("BEGIN fnd_attached_documents2_pkg.copy_attachments(").append("  X_from_entity_name   => :1 ").append(", X_from_pk1_value     => :2 ").append(", X_to_entity_name     => :3 ").append(", X_to_pk1_value       => :4 ").append(", X_created_by         => :5 ); END;").toString();
                if(flag1)
                    oadbtransaction.writeDiagnostics(s2, "PLSQL = " + s3, 1);
                OracleCallableStatement oraclecallablestatement = null;
                try
                {
                    oraclecallablestatement = (OracleCallableStatement)oadbtransaction.createCallableStatement(s3, 1);
                    oraclecallablestatement.setString(1, "AS_LEAD_ATTCH");
                    oraclecallablestatement.setString(2, s);
                    oraclecallablestatement.setString(3, "AS_OPPORTUNITY_ATTCH");
                    oraclecallablestatement.setString(4, s1);
                    oraclecallablestatement.setInt(5, oadbtransaction.getUserId());
                    if(flag1)
                        oadbtransaction.writeDiagnostics(s2, "postChanges: fnd_attached_documents2_pkg.copy_attachments", 1);
                    oraclecallablestatement.execute();
                    if(flag1)
                        oadbtransaction.writeDiagnostics(s2, "postChanges: fnd_attached_documents2_pkg.copy_attachments", 1);
                }
                catch(Exception exception2)
                {
                    if(flag2)
                    {
                        StringBuffer stringbuffer1 = new StringBuffer(100);
                        stringbuffer1.append("Exception while copying the attachments, ex=").append(exception2);
                        oadbtransaction.writeDiagnostics(s2, stringbuffer1.toString(), 4);
                        stringbuffer1 = null;
                    }
                    throw OAException.wrapperException(exception2);
                }
                finally
                {
                    try
                    {
                        oraclecallablestatement.close();
                    }
                    catch(SQLException sqlexception)
                    {
                        throw OAException.wrapperException(sqlexception);
                    }
                }
            }
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s2, "end", 2);
        }
    }

    private Number getLoginUserResourceId()
    {
        OADBTransaction oadbtransaction = getOADBTransaction();
        LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
        Number number = leadexpert.getResourceId(new Number(oadbtransaction.getUserId()));
        return number;
    }

    private Number getDefaultLoginUserGroupId()
    {
        String s = "asn.lead.schema.server.LeadEOImpl.getDefaultLoginUserGroupId";
        OADBTransaction oadbtransaction = (OADBTransaction)getDBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(4);
        Number number = null;
        try
        {
            number = new Number(oadbtransaction.getValue("ASNSsnResourceGroupId"));
        }
        catch(Exception exception)
        {
            if(flag)
            {
                StringBuffer stringbuffer = new StringBuffer(100);
                stringbuffer.append("Exception while retreiving def group id from trxn, ge=").append(exception);
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                stringbuffer = null;
            }
        }
        if(number == null)
        {
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            number = leadexpert.getDefaultResourceGroupId(getLoginUserResourceId());
        }
        return number;
    }

    private boolean isAttributeValueChanged(int i)
    {
        boolean flag = false;
        byte byte0 = getEntityState();
        if(isAttributeChanged(i))
        {
            Object obj = byte0 != 0 ? getPostedAttribute(i) : null;
            Object obj1 = getAttributeInternal(i);
            if(obj != null && !obj.equals(obj1) || obj1 != null && !obj1.equals(obj))
                flag = true;
        }
        return flag;
    }

    public RowIterator getRelationshipEO()
    {
        return (RowIterator)getAttributeInternal(65);
    }

    public LeadOpportunityEOImpl getLeadOpportunityEO()
    {
        return (LeadOpportunityEOImpl)getAttributeInternal(63);
    }

    public void setLeadOpportunityEO(LeadOpportunityEOImpl leadopportunityeoimpl)
    {
        setAttributeInternal(63, leadopportunityeoimpl);
    }

    public Number getLeadRankScore()
    {
        return (Number)getAttributeInternal(27);
    }

    public void setLeadRankScore(Number number)
    {
        setAttributeInternal(27, number);
    }

    public String getStatusOpenFlag()
    {
        return (String)getAttributeInternal(28);
    }

    public void setStatusOpenFlag(String s)
    {
        setAttributeInternal(28, s);
    }

    public String getAcceptFlag()
    {
        return (String)getAttributeInternal(29);
    }

    public void setAcceptFlag(String s)
    {
        s = s != null ? s.trim() : "N";
        s = "".equals(s) ? "N" : s;
        if(s != null && !"Y".equals(s) && !"N".equals(s))
        {
            MessageToken amessagetoken[] = {
                new MessageToken("FLAGNAME", "AcceptFlag")
            };
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "AcceptFlag", s, "ASN", "ASN_CMMN_FLAG_INV_ERR", amessagetoken);
        } else
        {
            setAttributeInternal(29, s);
            return;
        }
    }

    public Number getPrimaryCntPersonPartyId()
    {
        return (Number)getAttributeInternal(19);
    }

    public void setPrimaryCntPersonPartyId(Number number)
    {
        setAttributeInternal(19, number);
    }

    public Date getTruncCreationDate()
    {
        return (Date)getAttributeInternal(30);
    }

    public void setTruncCreationDate(Date date)
    {
        setAttributeInternal(30, date);
    }

    public Number getAddressId()
    {
        return (Number)getAttributeInternal(4);
    }

    public void setAddressId(Number number)
    {
        Number number1 = getAddressId();
        setAttributeInternal(4, number);
        if(number != null && !number.equals(number1) || number1 != null && !number1.equals(number))
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            String s = number != null ? leadexpert.getCountry(number) : null;
            setCountry(s);
        }
    }

    public String getCountry()
    {
        return (String)getAttributeInternal(31);
    }

    public void setCountry(String s)
    {
        setAttributeInternal(31, s);
    }

    public void defaultAddressId()
    {
        String s = "asn.lead.schema.server.LeadEOImpl.defaultAddressId";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        try
        {
            Number number = getCustomerId();
            if(number == null)
            {
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Customer ID is not set yet. Returns.", 1);
                return;
            }
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            Number number1 = leadexpert.getIdentifyingAddressId(number);
            if(number1 != null)
            {
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, (new StringBuffer(200)).append("Default Address to identifying address of the customer at lead creation time. ").append("Identifying address for customer ").append(number).append(" = ").append(number1).toString(), 1);
                setAddressId(number1);
            }
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    public Number getAssignToPersonId()
    {
        return (Number)getAttributeInternal(17);
    }

    public void setAssignToPersonId(Number number)
    {
        setAttributeInternal(17, number);
    }

    public String getVehicleResponseCode()
    {
        return (String)getAttributeInternal(58);
    }

    public void setVehicleResponseCode(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        if(s != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            LeadExpert leadexpert = (LeadExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!leadexpert.isVehicleResponseCodeValid(s))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "VehicleResponseCode", s, "ASN", "ASN_CMMN_VEHRESPCD_INV_ERR");
        }
        setAttributeInternal(58, s);
    }

    public Number getBudgetAmount()
    {
        return (Number)getAttributeInternal(59);
    }

    public void setBudgetAmount(Number number)
    {
        setAttributeInternal(59, number);
    }

    public static Key createPrimaryKey(Number number)
    {
        return new Key(new Object[] {
            number
        });
    }

    protected static final int SALESLEADID = 0;
    protected static final int LEADNUMBER = 1;
    protected static final int STATUSCODE = 2;
    protected static final int CUSTOMERID = 3;
    protected static final int ADDRESSID = 4;
    protected static final int CURRENCYCODE = 5;
    protected static final int DESCRIPTION = 6;
    protected static final int SOURCEPROMOTIONID = 7;
    protected static final int CHANNELCODE = 8;
    protected static final int CLOSEREASON = 9;
    protected static final int LEADRANKID = 10;
    protected static final int LEADRANKIND = 11;
    protected static final int TOTALAMOUNT = 12;
    protected static final int SALESSTAGEID = 13;
    protected static final int SALESMETHODOLOGYID = 14;
    protected static final int ASSIGNTOSALESFORCEID = 15;
    protected static final int ASSIGNSALESGROUPID = 16;
    protected static final int ASSIGNTOPERSONID = 17;
    protected static final int PRIMARYCONTACTPARTYID = 18;
    protected static final int PRIMARYCNTPERSONPARTYID = 19;
    protected static final int PRIMARYCONTACTPHONEID = 20;
    protected static final int IMPORTFLAG = 21;
    protected static final int QUALIFIEDFLAG = 22;
    protected static final int LEADENGINERUNDATE = 23;
    protected static final int AUTOASSIGNMENTTYPE = 24;
    protected static final int SOURCESYSTEM = 25;
    protected static final int OBJECTTYPECODE = 26;
    protected static final int LEADRANKSCORE = 27;
    protected static final int STATUSOPENFLAG = 28;
    protected static final int ACCEPTFLAG = 29;
    protected static final int TRUNCCREATIONDATE = 30;
    protected static final int COUNTRY = 31;
    protected static final int OBJECTVERSIONNUMBER = 32;
    protected static final int LASTUPDATEDATE = 33;
    protected static final int LASTUPDATEDBY = 34;
    protected static final int CREATIONDATE = 35;
    protected static final int CREATEDBY = 36;
    protected static final int LASTUPDATELOGIN = 37;
    protected static final int REQUESTID = 38;
    protected static final int PROGRAMAPPLICATIONID = 39;
    protected static final int PROGRAMID = 40;
    protected static final int PROGRAMUPDATEDATE = 41;
    protected static final int ATTRIBUTECATEGORY = 42;
    protected static final int ATTRIBUTE1 = 43;
    protected static final int ATTRIBUTE2 = 44;
    protected static final int ATTRIBUTE3 = 45;
    protected static final int ATTRIBUTE4 = 46;
    protected static final int ATTRIBUTE5 = 47;
    protected static final int ATTRIBUTE6 = 48;
    protected static final int ATTRIBUTE7 = 49;
    protected static final int ATTRIBUTE8 = 50;
    protected static final int ATTRIBUTE9 = 51;
    protected static final int ATTRIBUTE10 = 52;
    protected static final int ATTRIBUTE11 = 53;
    protected static final int ATTRIBUTE12 = 54;
    protected static final int ATTRIBUTE13 = 55;
    protected static final int ATTRIBUTE14 = 56;
    protected static final int ATTRIBUTE15 = 57;
    protected static final int VEHICLERESPONSECODE = 58;
    protected static final int BUDGETAMOUNT = 59;
    protected static final int LEADLINEEO = 60;
    protected static final int LEADCONTACTEO = 61;
    protected static final int LEADLOGEO = 62;
    protected static final int LEADOPPORTUNITYEO = 63;
    protected static final int LEADACCESSEO = 64;
    protected static final int RELATIONSHIPEO = 65;
    public static final String RCS_ID = "$Header: LeadEOImpl.java 115.80.115200.2 2005/10/17 20:35:54 appldev ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: LeadEOImpl.java 115.80.115200.2 2005/10/17 20:35:54 appldev ship $", "oracle.apps.asn.lead.schema.server");
    private static final String LEAD_OPP_LINK_STATUS = "CONVERTED_TO_OPPORTUNITY";
    private static OAEntityDefImpl mDefinitionObject;

}
