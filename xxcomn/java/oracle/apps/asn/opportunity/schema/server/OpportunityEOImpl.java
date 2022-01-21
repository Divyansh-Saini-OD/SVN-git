// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3)
// Source File Name:   OpportunityEOImpl.java

package oracle.apps.asn.opportunity.schema.server;

import com.sun.java.util.collections.AbstractList;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.Iterator;
import java.io.NotSerializableException;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Calendar;
import java.util.Date;
import java.util.Enumeration;
import java.util.Vector;
import oracle.apps.asn.common.fwk.server.ASNConstants;
import oracle.apps.asn.common.fwk.server.ASNEntityImpl;
import oracle.apps.asn.common.schema.server.AccessEOImpl;
import oracle.apps.asn.common.schema.server.RelationshipEOImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.OARowValException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAEntityDefImpl;
import oracle.apps.fnd.framework.server.OAEntityImpl;
import oracle.apps.fnd.framework.server.OAExceptionUtils;
import oracle.apps.fnd.wf.bes.BusinessEvent;
import oracle.apps.fnd.wf.bes.BusinessEventException;
import oracle.jbo.AttributeList;
import oracle.jbo.Key;
import oracle.jbo.Row;
import oracle.jbo.RowIterator;
import oracle.jbo.RowSet;
import oracle.jbo.common.MetaObjectBase;
import oracle.jbo.common.NamedObjectImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.server.DBTransaction;
import oracle.jbo.server.Entity;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.EntityImpl;
import oracle.jbo.server.TransactionEvent;
import oracle.jbo.server.ViewObjectImpl;
import oracle.jdbc.OracleTypes;
import oracle.jdbc.driver.OracleCallableStatement;
import oracle.jdbc.driver.OraclePreparedStatement;
import oracle.sql.DATE;
import oracle.sql.NUMBER;


// Referenced classes of package oracle.apps.asn.opportunity.schema.server:
//            MinMaxProbForMethIdStageIdVVORowImpl, OpportunityAccessEOImpl, OpportunityContactEOImpl, OpportunityExpert,
//            OpportunityLineEOImpl, OpportunityLineSalesCreditEOImpl

public class OpportunityEOImpl extends ASNEntityImpl
{

    public OpportunityEOImpl()
    {
    }

    public static synchronized EntityDefImpl getDefinitionObject()
    {
        if(mDefinitionObject == null)
            mDefinitionObject = (OAEntityDefImpl)EntityDefImpl.findDefObject("oracle.apps.asn.opportunity.schema.server.OpportunityEO");
        return mDefinitionObject;
    }

    public void create(AttributeList attributelist)
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.create";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        try
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "begin", 2);
            super.create(attributelist);
            Number number = oadbtransaction.getSequenceValue("AS_LEADS_S");
            setAttributeInternal(0, number);
            setAttributeInternal(10, number.toString());
            setAttributeInternal(16, new Number(0));
            setAttributeInternal(47, new Number(0));
            setAttributeInternal(39, "TAP");
            int i = oadbtransaction.getOrgId();
            if(flag1)
            {
                StringBuffer stringbuffer = (new StringBuffer(20)).append("OrgId=").append(i);
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 1);
                stringbuffer = null;
            }
            if(i != -1)
                setAttributeInternal(22, new Number(i));
            Number number1 = null;
            try
            {
                number1 = new Number(oadbtransaction.getProfile("ASN_OPP_WIN_PROBABILITY"));
                if(flag1)
                {
                    StringBuffer stringbuffer1 = (new StringBuffer(30)).append("WinProbability=").append(number1);
                    oadbtransaction.writeDiagnostics(s, stringbuffer1.toString(), 1);
                    stringbuffer1 = null;
                }
            }
            catch(Exception _ex) { }
            if(number1 != null)
                setWinProbability(number1);
            String s1 = oadbtransaction.getProfile("ASN_OPP_SALES_CHANNEL");
            if(flag1)
            {
                StringBuffer stringbuffer2 = (new StringBuffer(60)).append("SalesChannel=").append(s1);
                oadbtransaction.writeDiagnostics(s, stringbuffer2.toString(), 1);
                stringbuffer2 = null;
            }
            setChannelCode(s1);
            String s2 = oadbtransaction.getProfile("ASN_OPP_STATUS");
            if(flag1)
            {
                StringBuffer stringbuffer3 = (new StringBuffer(60)).append("Status=").append(s2);
                oadbtransaction.writeDiagnostics(s, stringbuffer3.toString(), 1);
                stringbuffer3 = null;
            }
            if(s2 != null)
                setStatus(s2);
            oracle.jbo.domain.Date date = oadbtransaction.getCurrentDBDate();
            long l = 0L;
            try
            {
                String s3 = oadbtransaction.getProfile("ASN_OPP_CLOSING_DATE_DAYS");
                if(flag1)
                {
                    StringBuffer stringbuffer4 = (new StringBuffer(20)).append("CloseDateDays=").append(s3);
                    oadbtransaction.writeDiagnostics(s, stringbuffer4.toString(), 1);
                    stringbuffer4 = null;
                }
                long l1;
                if(s3 == null)
                    l1 = 30L;
                else
                    l1 = (new Number(s3)).longValue();
                date = new oracle.jbo.domain.Date(new Timestamp(date.timestampValue().getTime() + l1 * 24L * 60L * 60L * 1000L));
            }
            catch(Exception _ex) { }
            setDecisionDate(date);
            String s4 = oadbtransaction.getProfile("JTF_PROFILE_DEFAULT_CURRENCY");
            if(flag1)
            {
                StringBuffer stringbuffer5 = (new StringBuffer(20)).append("CurrencyCode=").append(s4);
                oadbtransaction.writeDiagnostics(s, stringbuffer5.toString(), 1);
                stringbuffer5 = null;
            }
            if(s4 != null)
                setCurrencyCode(s4);
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    public void remove()
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.remove";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(4);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        try
        {
            if(flag1)
                oadbtransaction.writeDiagnostics(s, "opportunity remove is not supported", 4);
            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_OPPTY_DEL_INV_ERR");
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    protected void validateEntity()
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.validateEntity";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        boolean flag2 = oadbtransaction.isLoggingEnabled(4);
        try
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "begin", 2);
            if(getCustomerId() == null)
            {
                if(flag2)
                    oadbtransaction.writeDiagnostics(s, "Mandatory attribute CustomerId is missing. ", 4);
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CustomerId", getCustomerId(), "ASN", "ASN_CMMN_CUST_MISS_ERR");
            }
            if(getTotalAmount() == null)
                setTotalAmount(new Number(0));
            if(getTotalRevenueOppForecastAmt() == null)
                setTotalRevenueOppForecastAmt(new Number(0));
            super.validateEntity();
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            oadbtransaction.writeDiagnostics(s, "Anirban 29Jan Modified: commented call to defaultAddressId()", OAFwkConstants.STATEMENT);
            //anirban
            //Comment code for defaulting primary identifying address in oppty
            /*if(isAttributeChanged(13) || isAttributeChanged(12))
            {
                Number number = getAddressId();
                Number number2 = getCustomerId();
                if(number == null && getEntityState() == 0)
                    defaultAddressId();
                else
                if(number != null && !opportunityexpert.isCustomerIdAddressIdValid(number2, number))
                {
                    if(flag2)
                        oadbtransaction.writeDiagnostics(s, "Cross validation between customer and address failed", 4);
                    throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_ADDR_INV_ERR");
                }
            }*/
            // end of code comment for defaulting primary identifying address in oppty
            if(isAttributeChanged(11) || isAttributeChanged(20))
            {
                boolean flag3 = opportunityexpert.isStatusOpen(getStatus());
                String s2 = getCloseReason();
                if(flag3)
                {
                    if(s2 != null)
                    {
                        if(flag2)
                            oadbtransaction.writeDiagnostics(s, "open status with close reason", 4);
                        throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_OPENSTS_CLSRSN_ERR");
                    }
                } else
                if(s2 == null)
                {
                    if(flag2)
                        oadbtransaction.writeDiagnostics(s, "closed status, no close reason", 4);
                    throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_CLSSTS_REQCLSRSN_ERR");
                }
            }
            if(getSalesMethodologyId() == null && getSalesStageId() != null)
            {
                if(flag2)
                    oadbtransaction.writeDiagnostics(s, "no sales methodology with sales stage", 4);
                throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_SLSSTG_REQMETH_ERR");
            }
            if(isAttributeChanged(40) || isAttributeChanged(14))
            {
                if(getSalesMethodologyId() != null && getSalesStageId() != null && !opportunityexpert.isSalesMethIdStageIdValid(getSalesMethodologyId(), getSalesStageId()))
                {
                    if(flag2)
                    {
                        StringBuffer stringbuffer = (new StringBuffer(50)).append("invalid sales methodology, sales stage:").append("SalesMethodologyId:").append(getSalesMethodologyId()).append("SalesStageId:").append(getSalesStageId());
                        oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                        stringbuffer = null;
                    }
                    throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_SLSMETHSTAGE_INV_ERR");
                }
                if(getSalesMethodologyId() != null && getSalesStageId() == null)
                {
                    Number number1 = opportunityexpert.getFirstSalesStageId(getSalesMethodologyId());
                    if(number1 != null)
                    {
                        if(flag1)
                        {
                            StringBuffer stringbuffer1 = new StringBuffer(50);
                            stringbuffer1.append("defaulting SalesStageId=").append(number1);
                            oadbtransaction.writeDiagnostics(s, stringbuffer1.toString(), 1);
                            stringbuffer1 = null;
                        }
                        setSalesStageId(number1);
                    }
                }
            }
            if(getEntityState() == 0)
                setLoginUserAsOwner();
            String s1 = opportunityexpert.getForecastRollupFlag(getStatus());
            String s3 = opportunityexpert.getWinLossIndicator(getStatus());
            if("Y".equals(s1))
            {
                boolean flag4 = false;
                if(isAttributeChanged(19))
                {
                    String s4 = oadbtransaction.getProfile("ASN_FRCST_DEFAULTING_TYPE");
                    if(flag1)
                    {
                        oadbtransaction.writeDiagnostics(s, "win probability is changed", 1);
                        StringBuffer stringbuffer2 = (new StringBuffer(25)).append("frcstDfltType=").append(s4);
                        oadbtransaction.writeDiagnostics(s, stringbuffer2.toString(), 1);
                        stringbuffer2 = null;
                    }
                    if(!"W".equals(s3))
                        if(!"W".equals(s4))
                        {
                            if(flag1)
                                oadbtransaction.writeDiagnostics(s, "current status is not won and defaulting type is not W", 1);
                            flag4 = true;
                        } else
                        {
                            Number number3 = (Number)getPostedAttribute(19);
                            Number number4 = getWinProbability();
                            if(!isInSameWinProbBucket(number3, number4))
                            {
                                if(flag1)
                                    oadbtransaction.writeDiagnostics(s, "current status is not won, defaulting type is W, win prob bucket change", 1);
                                flag4 = true;
                            }
                        }
                }
                if(isAttributeChanged(11))
                {
                    String s5 = (String)getPostedAttribute(11);
                    String s6 = opportunityexpert.getForecastRollupFlag(s5);
                    String s7 = opportunityexpert.getWinLossIndicator(s5);
                    if(s7 == null)
                        s7 = "N";
                    if(s3 == null)
                        s3 = "N";
                    if(flag1)
                    {
                        StringBuffer stringbuffer3 = (new StringBuffer(100)).append("status has changed:").append("new status:").append(getStatus()).append("new win loss ind:").append(s3).append("new frcst rollup flag:").append(s1).append("old status:").append(s5).append("old win loss ind:").append(s7).append("old frcst rollup flag:").append(s6);
                        oadbtransaction.writeDiagnostics(s, stringbuffer3.toString(), 1);
                        stringbuffer3 = null;
                    }
                    if(!s7.equals(s3) && ("W".equals(s7) || "W".equals(s3)) || "N".equals(s6))
                        flag4 = true;
                }
                if(flag4)
                    applySalesCreditDefaulting(s3, s1);
            }
            boolean flag5 = false;
            boolean flag6 = false;
            ArrayList arraylist = getTransactionListenersList();
            for(Iterator iterator = arraylist.iterator(); iterator.hasNext();)
            {
                Object obj = iterator.next();
                if(obj instanceof OpportunityAccessEOImpl)
                    flag5 = true;
                else
                if(obj instanceof OpportunityContactEOImpl)
                    flag6 = true;
            }

            if(flag5)
            {
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "start validating sales team", 1);
                RowIterator rowiterator = getOpportunityAccessEO();
                rowiterator.setRowValidation(false);
                int i = 0;
                Number number5 = null;
                Number number7 = null;
                HashMap hashmap1 = new HashMap(10);
                boolean flag7 = false;
                while(rowiterator.hasNext())
                {
                    OpportunityAccessEOImpl opportunityaccesseoimpl = (OpportunityAccessEOImpl)rowiterator.next();
                    if(opportunityaccesseoimpl.getPartnerCustomerId() == null && opportunityaccesseoimpl.getPartnerContPartyId() == null)
                    {
                        opportunityaccesseoimpl.getOpenFlag();
                        String s10 = opportunityaccesseoimpl.getOwnerFlag();
                        if("Y".equals(s10))
                        {
                            i++;
                            number5 = opportunityaccesseoimpl.getSalesforceId();
                            number7 = opportunityaccesseoimpl.getSalesGroupId();
                            if(!"Y".equals(opportunityaccesseoimpl.getTeamLeaderFlag()))
                                opportunityaccesseoimpl.setTeamLeaderFlag("Y");
                            if(!"Y".equals(opportunityaccesseoimpl.getFreezeFlag()))
                                opportunityaccesseoimpl.setFreezeFlag("Y");
                        }
                        Number number13 = opportunityaccesseoimpl.getSalesforceId();
                        Number number16 = opportunityaccesseoimpl.getSalesGroupId();
                        if(hashmap1.containsKey(number13))
                        {
                            ArrayList arraylist1 = (ArrayList)hashmap1.get(number13);
                            if(arraylist1.contains(number16))
                                flag7 = true;
                            else
                                arraylist1.add(number16);
                        } else
                        {
                            ArrayList arraylist2 = new ArrayList(5);
                            arraylist2.add(number16);
                            hashmap1.put(number13, arraylist2);
                        }
                        if(flag7)
                        {
                            if(flag2)
                                oadbtransaction.writeDiagnostics(s, "sales team resource and group not unique", 4);
                            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_ACSS_NOUNIQ_ERR");
                        }
                        if(i > 1)
                        {
                            if(flag2)
                                oadbtransaction.writeDiagnostics(s, "multiple owners on the sales team", 4);
                            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_MULTOWNER_ERR");
                        }
                    }
                }
                if(i == 0)
                {
                    if(flag2)
                        oadbtransaction.writeDiagnostics(s, "no owner on the sales team", 4);
                    throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_REQOWNER_ERR");
                }
                if(number5 != null)
                {
                    if(!number5.equals(getOwnerSalesforceId()))
                        setOwnerSalesforceId(number5);
                } else
                if(getOwnerSalesforceId() != null)
                    setOwnerSalesforceId(null);
                if(number7 != null)
                {
                    if(!number7.equals(getOwnerSalesGroupId()))
                        setOwnerSalesGroupId(number7);
                } else
                if(getOwnerSalesGroupId() != null)
                    setOwnerSalesGroupId(null);
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "done validating sales team", 1);
            }
            if(flag6)
            {
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "start validating contacts", 1);
                RowIterator rowiterator1 = getOpportunityContactEO();
                rowiterator1.setRowValidation(false);
                int j = 0;
                HashMap hashmap = new HashMap(10);
                while(rowiterator1.hasNext())
                {
                    OpportunityContactEOImpl opportunitycontacteoimpl = (OpportunityContactEOImpl)rowiterator1.next();
                    String s8 = opportunitycontacteoimpl.getPersonFirstName();
                    String s9 = opportunitycontacteoimpl.getPersonLastName();
                    if((s8 == null || "".equals(s8.trim())) && (s9 == null || "".equals(s9.trim())))
                    {
                        opportunitycontacteoimpl.remove();
                    } else
                    {
                        if("Y".equals(opportunitycontacteoimpl.getPrimaryContactFlag()) && ++j > 1)
                        {
                            if(flag2)
                                oadbtransaction.writeDiagnostics(s, "number of primary contacts > 1", 4);
                            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_MULTPRMCTCT_ERR");
                        }
                        Number number11 = opportunitycontacteoimpl.getContactPartyId();
                        if(hashmap.get(number11) != null)
                        {
                            if(flag2)
                                oadbtransaction.writeDiagnostics(s, "contact party Id is not unique", 4);
                            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_CMMN_CTCT_NOUNIQ_ERR");
                        }
                        hashmap.put(number11, number11);
                    }
                }
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "done validating contacts", 1);
            }
            RowIterator rowiterator2 = getOpportunityLineEO();
            rowiterator2.setRowValidation(false);
            RowIterator rowiterator3 = getOpportunityAccessEO();
            rowiterator3.setRowValidation(false);
            Number number6 = new Number(0);
            Number number8 = determineFrcstCreditTypeId();
            while(rowiterator2.hasNext())
            {
                OpportunityLineEOImpl opportunitylineeoimpl = (OpportunityLineEOImpl)rowiterator2.next();
                RowIterator rowiterator4 = opportunitylineeoimpl.getOpportunityLineSalesCreditEO();
                rowiterator4.setRowValidation(false);
                boolean flag8;
                for(flag8 = false; rowiterator4.hasNext() && !flag8;)
                {
                    OpportunityLineSalesCreditEOImpl opportunitylinesalescrediteoimpl = (OpportunityLineSalesCreditEOImpl)rowiterator4.next();
                    if(number8 != null && number8.equals(opportunitylinesalescrediteoimpl.getCreditTypeId()))
                        flag8 = true;
                }

                if(!flag8)
                    opportunitylineeoimpl.addForecastCredit();
                if(opportunitylineeoimpl.isTotalAmountChanged())
                    opportunitylineeoimpl.applySalesCreditDefaulting(s3, s1);
                rowiterator4.reset();
                while(rowiterator4.hasNext())
                {
                    OpportunityLineSalesCreditEOImpl opportunitylinesalescrediteoimpl1 = (OpportunityLineSalesCreditEOImpl)rowiterator4.next();
                    if(opportunitylinesalescrediteoimpl1.getEntityState() == 0)
                        opportunitylinesalescrediteoimpl1.applySalesCreditDefaulting(s3, s1);
                    if(number8 != null && number8.equals(opportunitylinesalescrediteoimpl1.getCreditTypeId()))
                    {
                        Number number14 = opportunitylinesalescrediteoimpl1.getOppForecastAmount();
                        if(number14 != null)
                            number6 = number6.add(number14);
                    }
                    Number number15 = opportunitylinesalescrediteoimpl1.getSalesforceId();
                    Number number17 = opportunitylinesalescrediteoimpl1.getSalesgroupId();
                    String s11 = opportunitylinesalescrediteoimpl1.getDefaultedFromOwnerFlag();
                    if("Y".equals(s11))
                    {
                        Number number19 = getOwnerSalesforceId();
                        Number number21 = getOwnerSalesGroupId();
                        if(number19 == null && number15 != null || number19 != null && !number19.equals(number15))
                            opportunitylinesalescrediteoimpl1.setSalesforceId(number19);
                        if(number21 == null && number17 != null || number21 != null && !number21.equals(number17))
                            opportunitylinesalescrediteoimpl1.setSalesgroupId(number21);
                    } else
                    {
                        OpportunityAccessEOImpl opportunityaccesseoimpl1 = findSalesTeamRecord(number15, number17);
                        if(opportunityaccesseoimpl1 != null)
                        {
                            if(!"Y".equals(opportunityaccesseoimpl1.getTeamLeaderFlag()))
                                opportunityaccesseoimpl1.setTeamLeaderFlag("Y");
                        } else
                        if(opportunitylinesalescrediteoimpl1.isSalesforceIdChanged() || opportunitylinesalescrediteoimpl1.isSalesgroupIdChanged())
                        {
                            OpportunityAccessEOImpl opportunityaccesseoimpl2 = (OpportunityAccessEOImpl)rowiterator3.createRow();
                            opportunityaccesseoimpl2.setSalesforceId(number15);
                            opportunityaccesseoimpl2.setSalesGroupId(number17);
                            opportunityaccesseoimpl2.setTeamLeaderFlag("Y");
                            rowiterator3.insertRow(opportunityaccesseoimpl2);
                        } else
                        {
                            throw new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_OPPTY_CRDTRCVR_ACSSMOD_ERR");
                        }
                    }
                }
            }
            if(!number6.equals(getTotalRevenueOppForecastAmt()))
                setTotalRevenueOppForecastAmt(number6);
            Number number9 = getSalesMethodologyId();
            Number number10 = getSalesStageId();
            Number number12 = getWinProbability();
            if((isAttributeChanged(40) || isAttributeChanged(14) || isAttributeChanged(19)) && number9 != null && number10 != null && number12 != null)
            {
                boolean flag9 = false;
                MinMaxProbForMethIdStageIdVVOImpl minmaxprobformethidstageidvvoimpl = opportunityexpert.getMinMaxWinProbability(number9, number10);
                if(minmaxprobformethidstageidvvoimpl.hasNext())
                {
                    MinMaxProbForMethIdStageIdVVORowImpl minmaxprobformethidstageidvvorowimpl = (MinMaxProbForMethIdStageIdVVORowImpl)minmaxprobformethidstageidvvoimpl.first();
                    Number number18 = minmaxprobformethidstageidvvorowimpl.getMinWinProbability();
                    Number number20 = minmaxprobformethidstageidvvorowimpl.getMaxWinProbability();
                    if(number12.compareTo(number18) >= 0 && number12.compareTo(number20) <= 0)
                        flag9 = true;
                    if(!flag9)
                    {
                        if(flag1)
                        {
                            StringBuffer stringbuffer4 = (new StringBuffer(100)).append("win probability should be between ").append(number18).append(" and ").append(number20).append(":WinProbability:").append(number12).append("SalesMethodologyId:").append(number9).append("SalesStageId:").append(number10);
                            oadbtransaction.writeDiagnostics(s, stringbuffer4.toString(), 1);
                        }
                        boolean flag10 = false;
                        Vector vector = oadbtransaction.getDialogMessages();
                        if(vector != null)
                        {
                            for(Enumeration enumeration = vector.elements(); !flag10 && enumeration.hasMoreElements();)
                            {
                                OAException oaexception = (OAException)enumeration.nextElement();
                                if((oaexception instanceof OARowValException) && "ASN_OPPTY_METHSTGPROB_INV_ERR".equals(oaexception.getMessageName()) && getPrimaryKey().equals(((OARowValException)oaexception).getRowKey()))
                                    flag10 = true;
                            }

                        }
                        if(!flag10)
                        {
                            if(flag1)
                                oadbtransaction.writeDiagnostics(s, "add win probability warning message", 1);
                            MessageToken amessagetoken[] = {
                                new MessageToken("LOWRANGE", number18.toString()), new MessageToken("HIGHRANGE", number20.toString())
                            };
                            OARowValException oarowvalexception = new OARowValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ASN", "ASN_OPPTY_METHSTGPROB_INV_ERR", amessagetoken, (byte)1, null, false);
                            oadbtransaction.putDialogMessage(oarowvalexception);
                            ArrayList arraylist3 = new ArrayList(1);
                            arraylist3.add(oarowvalexception);
                            oadbtransaction.putTransientValue("ASNTxnWarningMsg", arraylist3);
                        }
                    }
                }
            }
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    protected void prepareForDML(int i, TransactionEvent transactionevent)
    {
        String s = "asn.opportunity.schema.server.OpportuntiyEOImpl.prepareForDML";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        oadbtransaction.isLoggingEnabled(1);
        try
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "begin", 2);
            super.prepareForDML(i, transactionevent);
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    public void postChanges(TransactionEvent transactionevent)
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.postChanges";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        boolean flag2 = oadbtransaction.isLoggingEnabled(4);
        try
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "begin", 2);
            if(getEntityState() == 2)
                raisePreUpdateEvent();
            super.postChanges(transactionevent);
            if(getEntityState() == 0)
                raisePostCreateEvent();
            createSalesCycle();
            OracleCallableStatement oraclecallablestatement = null;
            try
            {
                StringBuffer stringbuffer = (new StringBuffer("begin ASN_SALES_PVT.Opp_Terr_Assignment")).append("(p_api_version_number => :1, p_init_msg_list => FND_API.G_TRUE,").append(" p_commit => FND_API.G_FALSE, p_lead_id => :2, x_lead_id => :3,").append(" x_return_status => :4, x_msg_count => :5, x_msg_data => :6); end;");
                oraclecallablestatement = (OracleCallableStatement)oadbtransaction.createCallableStatement(stringbuffer.toString(), 1);
                int i = 1;
                oraclecallablestatement.setInt(i++, 2);
                oraclecallablestatement.setNUMBER(i++, getLeadId());
                oraclecallablestatement.registerOutParameter(i++, 2);
                int j = i;
                oraclecallablestatement.registerOutParameter(i++, 12, 0, 1);
                oraclecallablestatement.registerOutParameter(i++, 4);
                oraclecallablestatement.registerOutParameter(i++, 12, 0, 2000);
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Calling ASN_SALES_PVT.Opp_Terr_Assignment", 1);
                oraclecallablestatement.execute();
                String s1 = oraclecallablestatement.getString(j);
                int k = oraclecallablestatement.getInt(j + 1);
                String s2 = oraclecallablestatement.getString(j + 2);
                if(flag1)
                {
                    StringBuffer stringbuffer2 = new StringBuffer(100);
                    stringbuffer2.append("ASN_SALES_PVT.Opp_Terr_Assignment Output:").append("xReturnStatus=").append(s1).append("xMsgCount=").append(k).append("xMsgData=").append(s2);
                    oadbtransaction.writeDiagnostics(s, stringbuffer2.toString(), 1);
                    stringbuffer2 = null;
                }
                OAExceptionUtils.checkErrors(oadbtransaction, k, s1, s2);
            }
            catch(Exception exception2)
            {
                if(flag2)
                {
                    StringBuffer stringbuffer1 = new StringBuffer(100);
                    stringbuffer1.append("exception while calling online TAP, ex=").append(exception2);
                    oadbtransaction.writeDiagnostics(s, stringbuffer1.toString(), 4);
                    stringbuffer1 = null;
                }
                throw OAException.wrapperException(exception2);
            }
            finally
            {
                if(oraclecallablestatement != null)
                    try
                    {
                        oraclecallablestatement.close();
                    }
                    catch(Exception _ex) { }
            }
            RowSet rowset = (RowSet)getOpportunityAccessEO();
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
        String s = "asn.opportunity.schema.server.LeadEOImpl.handlePostChangesError";
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
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.doDML";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        try
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "begin", 2);
            if(i == 2)
            {
                ArrayList arraylist = new ArrayList(10);
                for(Iterator iterator = OpportunityAccessEOImpl.getDefinitionObject().getAllEntityInstancesIterator(oadbtransaction); iterator.hasNext();)
                {
                    OpportunityAccessEOImpl opportunityaccesseoimpl = (OpportunityAccessEOImpl)iterator.next();
                    if(getLeadId().equals(opportunityaccesseoimpl.getLeadId()))
                        if(opportunityaccesseoimpl.getEntityState() == 3)
                            opportunityaccesseoimpl.postChanges(transactionevent);
                        else
                        if(opportunityaccesseoimpl.getEntityState() == 2)
                            arraylist.add(opportunityaccesseoimpl);
                }

                OpportunityAccessEOImpl opportunityaccesseoimpl1;
                for(Iterator iterator1 = arraylist.iterator(); iterator1.hasNext(); opportunityaccesseoimpl1.postChanges(transactionevent))
                    opportunityaccesseoimpl1 = (OpportunityAccessEOImpl)iterator1.next();

                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Done posting deleted access records", 1);
            }
            super.doDML(i, transactionevent);
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    protected Number determineFrcstCreditTypeId()
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.determineFrcstCreditTypeId";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(4);
        boolean flag1 = oadbtransaction.isLoggingEnabled(2);
        if(flag1)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        Number number = null;
        try
        {
            number = new Number(oadbtransaction.getProfile("ASN_FRCST_CREDIT_TYPE_ID"));
        }
        catch(Exception _ex)
        {
            if(flag)
            {
                StringBuffer stringbuffer = (new StringBuffer(50)).append("Invalid value for profile ASN_FRCST_CREDIT_TYPE_ID:").append(oadbtransaction.getProfile("ASN_FRCST_CREDIT_TYPE_ID"));
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                stringbuffer = null;
            }
        }
        if(flag1)
        {
            StringBuffer stringbuffer1 = (new StringBuffer(25)).append("return value=").append(number);
            oadbtransaction.writeDiagnostics(s, stringbuffer1.toString(), 2);
            stringbuffer1 = null;
            oadbtransaction.writeDiagnostics(s, "end", 2);
        }
        return number;
    }

    protected void applySalesCreditDefaulting()
    {
        applySalesCreditDefaulting(null, null);
    }

    protected void applySalesCreditDefaulting(String s, String s1)
    {
        String s2 = "asn.opportunity.schema.server.OpportunityEOImpl.applySalesCreditDefaulting";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        try
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s2, "begin", 2);
            RowIterator rowiterator = getOpportunityLineEO();
            rowiterator.setRowValidation(false);
            if(rowiterator.hasNext())
            {
                OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
                String s3 = getStatus();
                if(s == null)
                    s = opportunityexpert.getWinLossIndicator(s3);
                if(s1 == null)
                    s1 = opportunityexpert.getForecastRollupFlag(s3);
                OpportunityLineEOImpl opportunitylineeoimpl;
                for(; rowiterator.hasNext(); opportunitylineeoimpl.applySalesCreditDefaulting(s, s1))
                    opportunitylineeoimpl = (OpportunityLineEOImpl)rowiterator.next();

            }
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s2, "end", 2);
        }
    }

    protected Number determineLoginGroupId()
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.determineLoginGroupId";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(4);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        Number number = null;
        try
        {
            number = new Number(oadbtransaction.getValue("ASNSsnResourceGroupId"));
        }
        catch(Exception exception)
        {
            if(flag1)
            {
                StringBuffer stringbuffer1 = new StringBuffer(100);
                stringbuffer1.append("Exception while retreiving def group id from trxn, ge=").append(exception);
                oadbtransaction.writeDiagnostics(s, stringbuffer1.toString(), 4);
                stringbuffer1 = null;
            }
        }
        if(number == null)
        {
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            number = opportunityexpert.getDefaultResourceGroupId(determineLoginResourceId());
        }
        if(flag)
        {
            StringBuffer stringbuffer = (new StringBuffer(25)).append("Return Value=").append(number);
            oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 2);
            stringbuffer = null;
            oadbtransaction.writeDiagnostics(s, "end", 2);
        }
        return number;
    }

    protected Number determineLoginResourceId()
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.determineLoginResourceId";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        try
        {
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            int i = oadbtransaction.getUserId();
            Number number1 = opportunityexpert.getResourceId(new Number(i));
            if(flag)
            {
                StringBuffer stringbuffer = (new StringBuffer(25)).append("Return Value=").append(number1);
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 2);
                stringbuffer = null;
            }
            Number number = number1;
            return number;
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    public void setLoginUserAsOwner()
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.setLoginUserAsOwner";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(1);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        OpportunityAccessEOImpl opportunityaccesseoimpl = null;
        OpportunityAccessEOImpl opportunityaccesseoimpl1 = null;
        Number number = determineLoginResourceId();
        Number number1 = null;
        Number number2 = null;
        RowIterator rowiterator = getOpportunityAccessEO();
        rowiterator.setRowValidation(false);
        while(rowiterator.hasNext() && (opportunityaccesseoimpl == null || opportunityaccesseoimpl1 == null))
        {
            OpportunityAccessEOImpl opportunityaccesseoimpl2 = (OpportunityAccessEOImpl)rowiterator.next();
            number1 = opportunityaccesseoimpl2.getSalesforceId();
            if(opportunityaccesseoimpl == null && number1.equals(number))
                opportunityaccesseoimpl = opportunityaccesseoimpl2;
            if("Y".equals(opportunityaccesseoimpl2.getOwnerFlag()))
                opportunityaccesseoimpl1 = opportunityaccesseoimpl2;
        }
        if(opportunityaccesseoimpl == null)
        {
            if(flag1)
                oadbtransaction.writeDiagnostics(s, "adding login user to sales team", 1);
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            opportunityaccesseoimpl = (OpportunityAccessEOImpl)rowiterator.createRow();
            opportunityaccesseoimpl.setSalesforceId(number);
            Number number4 = determineLoginGroupId();
            if(number4 != null && !opportunityexpert.isResourceIdGroupIdValid(number, number4))
                opportunityaccesseoimpl.setSalesGroupId(null);
            else
                opportunityaccesseoimpl.setSalesGroupId(number4);
            opportunityaccesseoimpl.setFreezeFlag("Y");
        }
        if(opportunityaccesseoimpl1 == null && !"Y".equals(opportunityaccesseoimpl.getOwnerFlag()))
        {
            if(flag1)
                oadbtransaction.writeDiagnostics(s, "No owner in the sales team; Mark login user as owner.", 1);
            opportunityaccesseoimpl.setOwnerFlag("Y");
            opportunityaccesseoimpl1 = opportunityaccesseoimpl;
        }
        number1 = opportunityaccesseoimpl1.getSalesforceId();
        number2 = opportunityaccesseoimpl1.getSalesGroupId();
        Number number3 = getOwnerSalesforceId();
        Number number5 = getOwnerSalesGroupId();
        if(!number1.equals(number3))
            setOwnerSalesforceId(number1);
        if(number2 != null && !number2.equals(number5) || number2 == null && number5 != null)
            setOwnerSalesGroupId(number2);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "end", 2);
    }

    protected boolean isResourceOnSalesTeam(Number number)
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.isResourceOnSalesTeam";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        oadbtransaction.isLoggingEnabled(1);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "begin", 2);
            StringBuffer stringbuffer = (new StringBuffer(50)).append("Input Parameters: resourceId=").append(number);
            oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 2);
            stringbuffer = null;
        }
        boolean flag1 = false;
        RowIterator rowiterator = getOpportunityAccessEO();
        rowiterator.setRowValidation(false);
        while(rowiterator.hasNext() && !flag1)
        {
            OpportunityAccessEOImpl opportunityaccesseoimpl = (OpportunityAccessEOImpl)rowiterator.next();
            if(opportunityaccesseoimpl.getSalesforceId().equals(number))
                flag1 = true;
        }
        if(flag)
        {
            StringBuffer stringbuffer1 = (new StringBuffer(25)).append("Return Value=").append(flag1);
            oadbtransaction.writeDiagnostics(s, stringbuffer1.toString(), 2);
            stringbuffer1 = null;
            oadbtransaction.writeDiagnostics(s, "end", 2);
        }
        return flag1;
    }

    protected OpportunityAccessEOImpl findSalesTeamRecord(Number number, Number number1)
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.findSalesTeamRecord";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        oadbtransaction.isLoggingEnabled(1);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "begin", 2);
            StringBuffer stringbuffer = (new StringBuffer(50)).append("Input Parameters: resourceId=").append(number);
            oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 2);
            stringbuffer = null;
        }
        try
        {
            RowIterator rowiterator = getOpportunityAccessEO();
            rowiterator.setRowValidation(false);
            while(rowiterator.hasNext())
            {
                OpportunityAccessEOImpl opportunityaccesseoimpl2 = (OpportunityAccessEOImpl)rowiterator.next();
                Number number2 = opportunityaccesseoimpl2.getSalesforceId();
                Number number3 = opportunityaccesseoimpl2.getSalesGroupId();
                if(number2.equals(number) && (number3 == null && number1 == null || number3 != null && number3.equals(number1)))
                {
                    OpportunityAccessEOImpl opportunityaccesseoimpl = opportunityaccesseoimpl2;
                    return opportunityaccesseoimpl;
                }
            }
            OpportunityAccessEOImpl opportunityaccesseoimpl1 = null;
            return opportunityaccesseoimpl1;
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    protected boolean isResourceReceivingSalesCredits(Number number)
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.isResourceReceivingSalesCredits";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "begin", 2);
            StringBuffer stringbuffer = (new StringBuffer(50)).append("Input Parameters:").append("resourceId=").append(number);
            oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 2);
            stringbuffer = null;
        }
        if(number == null)
        {
            if(flag)
            {
                oadbtransaction.writeDiagnostics(s, "Return value=false", 2);
                oadbtransaction.writeDiagnostics(s, "end", 2);
            }
            return false;
        }
        RowIterator rowiterator = getOpportunityLineEO();
        rowiterator.setRowValidation(false);
        while(rowiterator.hasNext())
        {
            OpportunityLineEOImpl opportunitylineeoimpl = (OpportunityLineEOImpl)rowiterator.next();
            RowIterator rowiterator1 = opportunitylineeoimpl.getOpportunityLineSalesCreditEO();
            rowiterator1.setRowValidation(false);
            while(rowiterator1.hasNext())
            {
                OpportunityLineSalesCreditEOImpl opportunitylinesalescrediteoimpl = (OpportunityLineSalesCreditEOImpl)rowiterator1.next();
                if(number.equals(opportunitylinesalescrediteoimpl.getSalesforceId()))
                {
                    if(flag)
                    {
                        oadbtransaction.writeDiagnostics(s, "Return value=true", 2);
                        oadbtransaction.writeDiagnostics(s, "end", 2);
                    }
                    return true;
                }
            }
        }
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "Return value=false", 2);
            oadbtransaction.writeDiagnostics(s, "end", 2);
        }
        return false;
    }

    protected boolean isInSameWinProbBucket(Number number, Number number1)
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.isInSameWinProbBucket";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "begin", 2);
            StringBuffer stringbuffer = (new StringBuffer(50)).append("Input Parameters:").append("value1=").append(number).append(", value2=").append(number1);
            oadbtransaction.writeDiagnostics(s, "end", 2);
            stringbuffer = null;
        }
        boolean flag1 = true;
        if(number == null)
            number = new Number(0);
        if(number1 == null)
            number1 = new Number(0);
        if(number.compareTo(new Number(40)) < 0)
        {
            if(number1.compareTo(new Number(40)) >= 0)
                flag1 = false;
        } else
        if(number.compareTo(new Number(60)) < 0)
        {
            if(number1.compareTo(new Number(60)) >= 0 || number1.compareTo(new Number(40)) < 0)
                flag1 = false;
        } else
        if(number.compareTo(new Number(80)) < 0)
        {
            if(number1.compareTo(new Number(80)) >= 0 || number1.compareTo(new Number(60)) < 0)
                flag1 = false;
        } else
        if(number1.compareTo(new Number(80)) < 0)
            flag1 = false;
        if(flag)
        {
            StringBuffer stringbuffer1 = (new StringBuffer(25)).append("Return value=").append(flag1);
            oadbtransaction.writeDiagnostics(s, stringbuffer1.toString(), 2);
            stringbuffer1 = null;
            oadbtransaction.writeDiagnostics(s, "end", 2);
        }
        return flag1;
    }

    private boolean hasSalesCycle()
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.hasSalesCycle";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
            oadbtransaction.writeDiagnostics(s, "Entering hasSalesCycle", 2);
        RowSet rowset = (RowSet)getRelationshipEO();
        if(!rowset.isExecuted())
            rowset.executeQuery();
        rowset.setRowValidation(false);
        while(rowset.hasNext())
        {
            RelationshipEOImpl relationshipeoimpl = (RelationshipEOImpl)rowset.next();
            if("SALES_CYCLE".equals(relationshipeoimpl.getRelationshipTypeCode()))
                return true;
        }
        if(flag)
            oadbtransaction.writeDiagnostics(s, "Exiting hasSalesCycle", 2);
        return false;
    }

    public boolean isSalesCycleMissing()
    {
        String s = "asn.lead.schema.server.OpportunityEOImpl.isSalesCycleMissing";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        oadbtransaction.isLoggingEnabled(1);
        boolean flag1 = true;
        if(flag)
            oadbtransaction.writeDiagnostics(s, "begin", 2);
        Number number = getEntityState() != 0 ? (Number)getPostedAttribute(40) : null;
        flag1 = number != null && !hasSalesCycle();
        if(flag)
            oadbtransaction.writeDiagnostics(s, "end", 2);
        return flag1;
    }

    public boolean createSalesCycle()
    {
        String s = "asn.lead.schema.server.OpportunityEOImpl.createSalesCycle";
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
                    oraclecallablestatement.setNUMBER(j++, getLeadId());
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

    private void raisePreUpdateEvent()
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.raisePreUpdateEvent";
        OADBTransaction oadbtransaction = getOADBTransaction();
        java.sql.Connection connection = oadbtransaction.getJdbcConnection();
        String s1 = "oracle.apps.asn.opportunity.preupdate";
        String s2 = getLeadId().toString() + "_" + System.currentTimeMillis();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(4);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "begin", 2);
            StringBuffer stringbuffer = (new StringBuffer(75)).append("Input Parameters:").append("Event Name=").append(s1).append("Event Key = ").append(s2);
            oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 2);
            stringbuffer = null;
        }
        try
        {
            BusinessEvent businessevent = new BusinessEvent(s1, s2);
            businessevent.setData("Opportunity " + s2 + "updated");
            ArrayList arraylist = new ArrayList(1);
            arraylist.add(oadbtransaction);
            businessevent.setObject(arraylist);
            businessevent.setStringProperty("pLeadId", getLeadId().toString());
            java.sql.Connection connection1 = oadbtransaction.getJdbcConnection();
            businessevent.raise(connection1);
            ArrayList arraylist1 = (ArrayList)oadbtransaction.getTransientValue("AsnPreUpdateException");
            if(arraylist1 != null)
            {
                oadbtransaction.removeTransientValue("AsnPreUpdateException");
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Error  from bundled Exception", 4);
                OAException.raiseBundledOAException(arraylist1);
            }
        }
        catch(BusinessEventException businesseventexception)
        {
            if(flag1)
                oadbtransaction.writeDiagnostics(s, businesseventexception.getMessage(), 4);
            throw new OAException("ASN", "ASN_CMMN_INTERNAL_SYS_ERR", businesseventexception);
        }
        catch(NotSerializableException notserializableexception)
        {
            if(flag1)
                oadbtransaction.writeDiagnostics(s, notserializableexception.getMessage(), 4);
            throw new OAException("ASN", "ASN_CMMN_INTERNAL_SYS_ERR", notserializableexception);
        }
        if(flag)
            oadbtransaction.writeDiagnostics(s, "END", 2);
    }

    private void raisePostCreateEvent()
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.raisePostCreateEvent";
        OADBTransaction oadbtransaction = getOADBTransaction();
        java.sql.Connection connection = oadbtransaction.getJdbcConnection();
        String s1 = "oracle.apps.asn.opportunity.postcreate";
        String s2 = getLeadId().toString();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        boolean flag1 = oadbtransaction.isLoggingEnabled(4);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s, "begin", 2);
            StringBuffer stringbuffer = (new StringBuffer(75)).append("Input Parameters:").append("Event Name=").append(s1).append("Event Key = ").append(s2);
            oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 2);
            stringbuffer = null;
        }
        try
        {
            BusinessEvent businessevent = new BusinessEvent(s1, s2);
            businessevent.setData("Opportunity " + s2 + "created");
            ArrayList arraylist = new ArrayList(1);
            arraylist.add(oadbtransaction);
            businessevent.setObject(arraylist);
            businessevent.setStringProperty("pLeadId", getLeadId().toString());
            java.sql.Connection connection1 = oadbtransaction.getJdbcConnection();
            businessevent.raise(connection1);
            ArrayList arraylist1 = (ArrayList)oadbtransaction.getTransientValue("AsnPostCreateException");
            if(arraylist1 != null)
            {
                oadbtransaction.removeTransientValue("AsnPostCreateException");
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, "Error from bundled Exception", 4);
                OAException.raiseBundledOAException(arraylist1);
            }
        }
        catch(BusinessEventException businesseventexception)
        {
            if(flag1)
                oadbtransaction.writeDiagnostics(s, businesseventexception.getMessage(), 4);
            throw new OAException("ASN", "ASN_CMMN_INTERNAL_SYS_ERR", businesseventexception);
        }
        catch(NotSerializableException notserializableexception)
        {
            if(flag1)
                oadbtransaction.writeDiagnostics(s, notserializableexception.getMessage(), 4);
            throw new OAException("ASN", "ASN_CMMN_INTERNAL_SYS_ERR", notserializableexception);
        }
        if(flag)
            oadbtransaction.writeDiagnostics(s, "END", 2);
    }

    public Number getLeadId()
    {
        return (Number)getAttributeInternal(0);
    }

    public void setLeadId(Number number)
    {
        setAttributeInternal(0, number);
    }

    public oracle.jbo.domain.Date getLastUpdateDate()
    {
        return (oracle.jbo.domain.Date)getAttributeInternal(1);
    }

    public void setLastUpdateDate(oracle.jbo.domain.Date date)
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

    public oracle.jbo.domain.Date getCreationDate()
    {
        return (oracle.jbo.domain.Date)getAttributeInternal(3);
    }

    public void setCreationDate(oracle.jbo.domain.Date date)
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

    public oracle.jbo.domain.Date getProgramUpdateDate()
    {
        return (oracle.jbo.domain.Date)getAttributeInternal(9);
    }

    public void setProgramUpdateDate(oracle.jbo.domain.Date date)
    {
        setAttributeInternal(9, date);
    }

    public String getLeadNumber()
    {
        return (String)getAttributeInternal(10);
    }

    public void setLeadNumber(String s)
    {
        if(s != null)
            s = s.trim();
        setAttributeInternal(10, s);
    }

    public String getStatus()
    {
        return (String)getAttributeInternal(11);
    }

    public void setStatus(String s)
    {
        String s1 = "asn.opportunity.schema.server.OpportunityEOImpl.setStatus";
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        if(s != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!opportunityexpert.isStatusValid(s))
            {
                if(oadbtransaction.isLoggingEnabled(4))
                {
                    StringBuffer stringbuffer = (new StringBuffer(25)).append("Invalid value=").append(s);
                    oadbtransaction.writeDiagnostics(s1, stringbuffer.toString(), 4);
                    stringbuffer = null;
                }
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "Status", s, "ASN", "ASN_CMMN_STATUS_INV_ERR");
            }
            String s2 = null;
            if(opportunityexpert.isStatusOpen(s))
                s2 = "Y";
            else
                s2 = "N";
            setStatusOpenFlag(s2);
            RowIterator rowiterator = getOpportunityAccessEO();
            rowiterator.setRowValidation(false);
            while(rowiterator.hasNext())
            {
                OpportunityAccessEOImpl opportunityaccesseoimpl = (OpportunityAccessEOImpl)rowiterator.next();
                String s3 = opportunityaccesseoimpl.getOpenFlag();
                if(s3 == null)
                    s3 = "N";
                if(!s2.equals(s3))
                    opportunityaccesseoimpl.setOpenFlag(s2);
            }
            if(oadbtransaction.isLoggingEnabled(1))
                oadbtransaction.writeDiagnostics(s1, "Done populating denorm OpportunityAccessEO.OpenFlag", 1);
        }
        setAttributeInternal(11, s);
    }

    public Number getCustomerId()
    {
        return (Number)getAttributeInternal(12);
    }

    public void setCustomerId(Number number)
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.setCustomerId";
        OADBTransaction oadbtransaction = getOADBTransaction();
        OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
        if(!opportunityexpert.isCustomerIdValid(number))
        {
            if(oadbtransaction.isLoggingEnabled(4))
            {
                StringBuffer stringbuffer = (new StringBuffer(25)).append("Invalid value=").append(number);
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                stringbuffer = null;
            }
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CustomerId", number, "ASN", "ASN_CMMN_CUST_INV_ERR");
        }
        setAttributeInternal(12, number);
        RowIterator rowiterator = getOpportunityContactEO();
        rowiterator.setRowValidation(false);
        OpportunityContactEOImpl opportunitycontacteoimpl;
        for(; rowiterator.hasNext(); opportunitycontacteoimpl.setCustomerId(number))
            opportunitycontacteoimpl = (OpportunityContactEOImpl)rowiterator.next();

        RowIterator rowiterator1 = getOpportunityAccessEO();
        rowiterator1.setRowValidation(false);
        OpportunityAccessEOImpl opportunityaccesseoimpl;
        for(; rowiterator1.hasNext(); opportunityaccesseoimpl.setCustomerId(number))
            opportunityaccesseoimpl = (OpportunityAccessEOImpl)rowiterator1.next();

    }

    public Number getSalesStageId()
    {
        return (Number)getAttributeInternal(14);
    }

    public void setSalesStageId(Number number)
    {
        String s = "asn.opportunity.schema.server.OpportuntiyEOImpl.setSalesStageId";
        if(number != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!opportunityexpert.isSalesStageIdValid(number))
            {
                if(oadbtransaction.isLoggingEnabled(4))
                {
                    StringBuffer stringbuffer = (new StringBuffer(25)).append("Invalid value=").append(number);
                    oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                    stringbuffer = null;
                }
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "SalesStageId", number, "ASN", "ASN_CMMN_SLSSTAGE_INV_ERR");
            }
        }
        setAttributeInternal(14, number);
    }

    public String getChannelCode()
    {
        return (String)getAttributeInternal(15);
    }

    public void setChannelCode(String s)
    {
        String s1 = "asn.opportunity.schema.server.OpportunityEOImpl.setChannelCode";
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        if(s != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!opportunityexpert.isChannelCodeValid(s))
            {
                if(oadbtransaction.isLoggingEnabled(4))
                {
                    StringBuffer stringbuffer = (new StringBuffer(25)).append("Invalid value=").append(s);
                    oadbtransaction.writeDiagnostics(s1, stringbuffer.toString(), 4);
                    stringbuffer = null;
                }
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "ChannelCode", s, "ASN", "ASN_CMMN_SLSCHNL_INV_ERR");
            }
        }
        setAttributeInternal(15, s);
    }

    public Number getTotalAmount()
    {
        Number number = (Number)getAttributeInternal(16);
        if(number == null)
            number = new Number(0);
        return number;
    }

    public void setTotalAmount(Number number)
    {
        setAttributeInternal(16, number);
    }

    public String getCurrencyCode()
    {
        return (String)getAttributeInternal(17);
    }

    public void setCurrencyCode(String s)
    {
        String s1 = "asn.opportunity.schema.server.OpportunityEOImpl.setCurrencyCode";
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        if(s != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!opportunityexpert.isCurrencyCodeValid(s))
            {
                if(oadbtransaction.isLoggingEnabled(4))
                {
                    StringBuffer stringbuffer = (new StringBuffer(25)).append("Invalid value=").append(s);
                    oadbtransaction.writeDiagnostics(s1, stringbuffer.toString(), 4);
                    stringbuffer = null;
                }
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CurrencyCode", s, "ASN", "ASN_CMMN_CURR_INV_ERR");
            }
        }
        setAttributeInternal(17, s);
    }

    public oracle.jbo.domain.Date getDecisionDate()
    {
        return (oracle.jbo.domain.Date)getAttributeInternal(18);
    }

    public void setDecisionDate(oracle.jbo.domain.Date date)
    {
        if(date != null)
        {
            Timestamp timestamp = date.timestampValue();
            Calendar calendar = Calendar.getInstance();
            calendar.setTime(timestamp);
            calendar.set(11, 0);
            calendar.set(12, 0);
            calendar.set(13, 0);
            timestamp = new Timestamp(calendar.getTime().getTime());
            timestamp.setNanos(0);
            date = new oracle.jbo.domain.Date(timestamp);
        }
        setAttributeInternal(18, date);
    }

    public Number getWinProbability()
    {
        return (Number)getAttributeInternal(19);
    }

    public void setWinProbability(Number number)
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.setWinProbability";
        OADBTransaction oadbtransaction = getOADBTransaction();
        OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
        if(number != null && !opportunityexpert.isWinProbabilityValid(number))
        {
            if(oadbtransaction.isLoggingEnabled(4))
            {
                StringBuffer stringbuffer = (new StringBuffer(25)).append("Invalid value=").append(number);
                oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                stringbuffer = null;
            }
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "WinProbability", number, "ASN", "ASN_OPPTY_WINPROB_INV_ERR");
        } else
        {
            setAttributeInternal(19, number);
            return;
        }
    }

    public String getCloseReason()
    {
        return (String)getAttributeInternal(20);
    }

    public void setCloseReason(String s)
    {
        String s1 = "asn.opportunity.schema.server.OpportunityEOImpl.setCloseReason";
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        if(s != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!opportunityexpert.isCloseReasonValid(s))
            {
                if(oadbtransaction.isLoggingEnabled(4))
                {
                    StringBuffer stringbuffer = (new StringBuffer(25)).append("Invalid value=").append(s);
                    oadbtransaction.writeDiagnostics(s1, stringbuffer.toString(), 4);
                    stringbuffer = null;
                }
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "CloseReason", s, "ASN", "ASN_CMMN_CLSRSN_INV_ERR");
            }
        }
        setAttributeInternal(20, s);
    }

    public String getDescription()
    {
        return (String)getAttributeInternal(21);
    }

    public void setDescription(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(21, s);
    }

    public Number getOrgId()
    {
        return (Number)getAttributeInternal(22);
    }

    public void setOrgId(Number number)
    {
        setAttributeInternal(22, number);
    }

    public String getAttributeCategory()
    {
        return (String)getAttributeInternal(23);
    }

    public void setAttributeCategory(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(23, s);
    }

    public String getAttribute1()
    {
        return (String)getAttributeInternal(24);
    }

    public void setAttribute1(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(24, s);
    }

    public String getAttribute2()
    {
        return (String)getAttributeInternal(25);
    }

    public void setAttribute2(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(25, s);
    }

    public String getAttribute3()
    {
        return (String)getAttributeInternal(26);
    }

    public void setAttribute3(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(26, s);
    }

    public String getAttribute4()
    {
        return (String)getAttributeInternal(27);
    }

    public void setAttribute4(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(27, s);
    }

    public String getAttribute5()
    {
        return (String)getAttributeInternal(28);
    }

    public void setAttribute5(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(28, s);
    }

    public String getAttribute6()
    {
        return (String)getAttributeInternal(29);
    }

    public void setAttribute6(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(29, s);
    }

    public String getAttribute7()
    {
        return (String)getAttributeInternal(30);
    }

    public void setAttribute7(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(30, s);
    }

    public String getAttribute8()
    {
        return (String)getAttributeInternal(31);
    }

    public void setAttribute8(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(31, s);
    }

    public String getAttribute9()
    {
        return (String)getAttributeInternal(32);
    }

    public void setAttribute9(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(32, s);
    }

    public String getAttribute10()
    {
        return (String)getAttributeInternal(33);
    }

    public void setAttribute10(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(33, s);
    }

    public String getAttribute11()
    {
        return (String)getAttributeInternal(34);
    }

    public void setAttribute11(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(34, s);
    }

    public String getAttribute12()
    {
        return (String)getAttributeInternal(35);
    }

    public void setAttribute12(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(35, s);
    }

    public String getAttribute13()
    {
        return (String)getAttributeInternal(36);
    }

    public void setAttribute13(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(36, s);
    }

    public String getAttribute14()
    {
        return (String)getAttributeInternal(37);
    }

    public void setAttribute14(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(37, s);
    }

    public String getAttribute15()
    {
        return (String)getAttributeInternal(38);
    }

    public void setAttribute15(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(38, s);
    }

    public String getAutoAssignmentType()
    {
        return (String)getAttributeInternal(39);
    }

    public void setAutoAssignmentType(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(39, s);
    }

    public Number getSalesMethodologyId()
    {
        return (Number)getAttributeInternal(40);
    }

    public void setSalesMethodologyId(Number number)
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.setSalesMethodologyId";
        OADBTransaction oadbtransaction = getOADBTransaction();
        Number number1 = (Number)getPostedAttribute(40);
        if(getEntityState() != 0 && number1 != null)
        {
            if(oadbtransaction.isLoggingEnabled(4))
                oadbtransaction.writeDiagnostics(s, "sales methodology may not be changed if it is already saved to database", 4);
            throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "SalesMethodologyId", number, "ASN", "ASN_CMMN_SLSMETHUPD_INV_ERR");
        }
        if(number != null)
        {
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!opportunityexpert.isSalesMethodologyIdValid(number))
            {
                if(oadbtransaction.isLoggingEnabled(4))
                {
                    StringBuffer stringbuffer = (new StringBuffer(25)).append("Invalid value=").append(number);
                    oadbtransaction.writeDiagnostics(s, stringbuffer.toString(), 4);
                    stringbuffer = null;
                }
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "SalesMethodologyId", number, "ASN", "ASN_CMMN_SLSMETH_INV_ERR");
            }
        }
        setAttributeInternal(40, number);
    }

    public Number getOwnerSalesforceId()
    {
        return (Number)getAttributeInternal(41);
    }

    public void setOwnerSalesforceId(Number number)
    {
        setAttributeInternal(41, number);
    }

    public Number getOwnerSalesGroupId()
    {
        return (Number)getAttributeInternal(42);
    }

    public void setOwnerSalesGroupId(Number number)
    {
        setAttributeInternal(42, number);
    }

    protected Object getAttrInvokeAccessor(int i, AttributeDefImpl attributedefimpl)
        throws Exception
    {
        switch(i)
        {
        case 0: // '\0'
            return getLeadId();

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
            return getLeadNumber();

        case 11: // '\013'
            return getStatus();

        case 12: // '\f'
            return getCustomerId();

        case 13: // '\r'
            return getAddressId();

        case 14: // '\016'
            return getSalesStageId();

        case 15: // '\017'
            return getChannelCode();

        case 16: // '\020'
            return getTotalAmount();

        case 17: // '\021'
            return getCurrencyCode();

        case 18: // '\022'
            return getDecisionDate();

        case 19: // '\023'
            return getWinProbability();

        case 20: // '\024'
            return getCloseReason();

        case 21: // '\025'
            return getDescription();

        case 22: // '\026'
            return getOrgId();

        case 23: // '\027'
            return getAttributeCategory();

        case 24: // '\030'
            return getAttribute1();

        case 25: // '\031'
            return getAttribute2();

        case 26: // '\032'
            return getAttribute3();

        case 27: // '\033'
            return getAttribute4();

        case 28: // '\034'
            return getAttribute5();

        case 29: // '\035'
            return getAttribute6();

        case 30: // '\036'
            return getAttribute7();

        case 31: // '\037'
            return getAttribute8();

        case 32: // ' '
            return getAttribute9();

        case 33: // '!'
            return getAttribute10();

        case 34: // '"'
            return getAttribute11();

        case 35: // '#'
            return getAttribute12();

        case 36: // '$'
            return getAttribute13();

        case 37: // '%'
            return getAttribute14();

        case 38: // '&'
            return getAttribute15();

        case 39: // '\''
            return getAutoAssignmentType();

        case 40: // '('
            return getSalesMethodologyId();

        case 41: // ')'
            return getOwnerSalesforceId();

        case 42: // '*'
            return getOwnerSalesGroupId();

        case 43: // '+'
            return getObjectVersionNumber();

        case 44: // ','
            return getObjectTypeCode();

        case 45: // '-'
            return getSourcePromotionId();

        case 46: // '.'
            return getStatusOpenFlag();

        case 47: // '/'
            return getTotalRevenueOppForecastAmt();

        case 48: // '0'
            return getVehicleResponseCode();

        case 49: // '1'
            return getOpportunityLineEO();

        case 50: // '2'
            return getRelationshipEO();

        case 51: // '3'
            return getOpportunityContactEO();

        case 52: // '4'
            return getOpportunityAccessEO();
        }
        return super.getAttrInvokeAccessor(i, attributedefimpl);
    }

    protected void setAttrInvokeAccessor(int i, Object obj, AttributeDefImpl attributedefimpl)
        throws Exception
    {
        switch(i)
        {
        case 0: // '\0'
            setLeadId((Number)obj);
            return;

        case 1: // '\001'
            setLastUpdateDate((oracle.jbo.domain.Date)obj);
            return;

        case 2: // '\002'
            setLastUpdatedBy((Number)obj);
            return;

        case 3: // '\003'
            setCreationDate((oracle.jbo.domain.Date)obj);
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
            setProgramUpdateDate((oracle.jbo.domain.Date)obj);
            return;

        case 10: // '\n'
            setLeadNumber((String)obj);
            return;

        case 11: // '\013'
            setStatus((String)obj);
            return;

        case 12: // '\f'
            setCustomerId((Number)obj);
            return;

        case 13: // '\r'
            setAddressId((Number)obj);
            return;

        case 14: // '\016'
            setSalesStageId((Number)obj);
            return;

        case 15: // '\017'
            setChannelCode((String)obj);
            return;

        case 16: // '\020'
            setTotalAmount((Number)obj);
            return;

        case 17: // '\021'
            setCurrencyCode((String)obj);
            return;

        case 18: // '\022'
            setDecisionDate((oracle.jbo.domain.Date)obj);
            return;

        case 19: // '\023'
            setWinProbability((Number)obj);
            return;

        case 20: // '\024'
            setCloseReason((String)obj);
            return;

        case 21: // '\025'
            setDescription((String)obj);
            return;

        case 22: // '\026'
            setOrgId((Number)obj);
            return;

        case 23: // '\027'
            setAttributeCategory((String)obj);
            return;

        case 24: // '\030'
            setAttribute1((String)obj);
            return;

        case 25: // '\031'
            setAttribute2((String)obj);
            return;

        case 26: // '\032'
            setAttribute3((String)obj);
            return;

        case 27: // '\033'
            setAttribute4((String)obj);
            return;

        case 28: // '\034'
            setAttribute5((String)obj);
            return;

        case 29: // '\035'
            setAttribute6((String)obj);
            return;

        case 30: // '\036'
            setAttribute7((String)obj);
            return;

        case 31: // '\037'
            setAttribute8((String)obj);
            return;

        case 32: // ' '
            setAttribute9((String)obj);
            return;

        case 33: // '!'
            setAttribute10((String)obj);
            return;

        case 34: // '"'
            setAttribute11((String)obj);
            return;

        case 35: // '#'
            setAttribute12((String)obj);
            return;

        case 36: // '$'
            setAttribute13((String)obj);
            return;

        case 37: // '%'
            setAttribute14((String)obj);
            return;

        case 38: // '&'
            setAttribute15((String)obj);
            return;

        case 39: // '\''
            setAutoAssignmentType((String)obj);
            return;

        case 40: // '('
            setSalesMethodologyId((Number)obj);
            return;

        case 41: // ')'
            setOwnerSalesforceId((Number)obj);
            return;

        case 42: // '*'
            setOwnerSalesGroupId((Number)obj);
            return;

        case 43: // '+'
            setObjectVersionNumber((Number)obj);
            return;

        case 44: // ','
            setObjectTypeCode((String)obj);
            return;

        case 45: // '-'
            setSourcePromotionId((Number)obj);
            return;

        case 46: // '.'
            setStatusOpenFlag((String)obj);
            return;

        case 47: // '/'
            setTotalRevenueOppForecastAmt((Number)obj);
            return;

        case 48: // '0'
            setVehicleResponseCode((String)obj);
            return;
        }
        super.setAttrInvokeAccessor(i, obj, attributedefimpl);
    }

    public Number getObjectVersionNumber()
    {
        return (Number)getAttributeInternal(43);
    }

    public void setObjectVersionNumber(Number number)
    {
        setAttributeInternal(43, number);
    }

    public RowIterator getOpportunityLineEO()
    {
        return (RowIterator)getAttributeInternal(49);
    }

    public String getObjectTypeCode()
    {
        if(getAttributeInternal(44) == null)
            populateAttribute(44, "OPPORTUNITY");
        return (String)getAttributeInternal(44);
    }

    public RowIterator getRelationshipEO()
    {
        if(getObjectTypeCode() == null)
            populateAttribute(44, "OPPORTUNITY");
        return (RowIterator)getAttributeInternal(50);
    }

    public Number getSourcePromotionId()
    {
        return (Number)getAttributeInternal(45);
    }

    public void setSourcePromotionId(Number number)
    {
        setAttributeInternal(45, number);
    }

    public void setObjectTypeCode(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(44, s);
    }

    public RowIterator getOpportunityContactEO()
    {
        return (RowIterator)getAttributeInternal(51);
    }

    public RowIterator getOpportunityAccessEO()
    {
        return (RowIterator)getAttributeInternal(52);
    }

    public String getStatusOpenFlag()
    {
        String s = (String)getAttributeInternal(46);
        if(s == null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(opportunityexpert.isStatusOpen(getStatus()))
                s = "Y";
            else
                s = "N";
            populateAttribute(46, s);
        }
        return s;
    }

    public void setStatusOpenFlag(String s)
    {
        if(s != null)
        {
            s = s.trim();
            if("".equals(s))
                s = null;
        }
        setAttributeInternal(46, s);
    }

    public Number getAddressId()
    {
        return (Number)getAttributeInternal(13);
    }

    public void setAddressId(Number number)
    {
        setAttributeInternal(13, number);
    }

    public void defaultAddressId()
    {
        String s = "asn.opportunity.schema.server.OpportunityEOImpl.defaultAddressId";
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
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            Number number1 = opportunityexpert.getIdentifyingAddressId(number);
            if(number1 != null)
            {
                if(flag1)
                    oadbtransaction.writeDiagnostics(s, (new StringBuffer(200)).append("Default Address to identifying address of the customer at opportunity creation time. ").append("Identifying address for customer ").append(number).append(" = ").append(number1).toString(), 1);
                setAddressId(number1);
            }
        }
        finally
        {
            if(flag)
                oadbtransaction.writeDiagnostics(s, "end", 2);
        }
    }

    public Number getTotalRevenueOppForecastAmt()
    {
        return (Number)getAttributeInternal(47);
    }

    public void setTotalRevenueOppForecastAmt(Number number)
    {
        setAttributeInternal(47, number);
    }

    public String getVehicleResponseCode()
    {
        return (String)getAttributeInternal(48);
    }

    public void setVehicleResponseCode(String s)
    {
        s = s != null ? s.trim() : null;
        s = "".equals(s) ? null : s;
        if(s != null)
        {
            OADBTransaction oadbtransaction = getOADBTransaction();
            OpportunityExpert opportunityexpert = (OpportunityExpert)oadbtransaction.getExpert(getDefinitionObject());
            if(!opportunityexpert.isVehicleResponseCodeValid(s))
                throw new OAAttrValException(121, getEntityDef().getFullName(), getPrimaryKey(), "VehicleResponseCode", s, "ASN", "ASN_CMMN_VEHRESPCD_INV_ERR");
        }
        setAttributeInternal(48, s);
    }

    public static Key createPrimaryKey(Number number)
    {
        return new Key(new Object[] {
            number
        });
    }

    protected static final int LEADID = 0;
    protected static final int LASTUPDATEDATE = 1;
    protected static final int LASTUPDATEDBY = 2;
    protected static final int CREATIONDATE = 3;
    protected static final int CREATEDBY = 4;
    protected static final int LASTUPDATELOGIN = 5;
    protected static final int REQUESTID = 6;
    protected static final int PROGRAMAPPLICATIONID = 7;
    protected static final int PROGRAMID = 8;
    protected static final int PROGRAMUPDATEDATE = 9;
    protected static final int LEADNUMBER = 10;
    protected static final int STATUS = 11;
    protected static final int CUSTOMERID = 12;
    protected static final int ADDRESSID = 13;
    protected static final int SALESSTAGEID = 14;
    protected static final int CHANNELCODE = 15;
    protected static final int TOTALAMOUNT = 16;
    protected static final int CURRENCYCODE = 17;
    protected static final int DECISIONDATE = 18;
    protected static final int WINPROBABILITY = 19;
    protected static final int CLOSEREASON = 20;
    protected static final int DESCRIPTION = 21;
    protected static final int ORGID = 22;
    protected static final int ATTRIBUTECATEGORY = 23;
    protected static final int ATTRIBUTE1 = 24;
    protected static final int ATTRIBUTE2 = 25;
    protected static final int ATTRIBUTE3 = 26;
    protected static final int ATTRIBUTE4 = 27;
    protected static final int ATTRIBUTE5 = 28;
    protected static final int ATTRIBUTE6 = 29;
    protected static final int ATTRIBUTE7 = 30;
    protected static final int ATTRIBUTE8 = 31;
    protected static final int ATTRIBUTE9 = 32;
    protected static final int ATTRIBUTE10 = 33;
    protected static final int ATTRIBUTE11 = 34;
    protected static final int ATTRIBUTE12 = 35;
    protected static final int ATTRIBUTE13 = 36;
    protected static final int ATTRIBUTE14 = 37;
    protected static final int ATTRIBUTE15 = 38;
    protected static final int AUTOASSIGNMENTTYPE = 39;
    protected static final int SALESMETHODOLOGYID = 40;
    protected static final int OWNERSALESFORCEID = 41;
    protected static final int OWNERSALESGROUPID = 42;
    protected static final int OBJECTVERSIONNUMBER = 43;
    protected static final int OBJECTTYPECODE = 44;
    protected static final int SOURCEPROMOTIONID = 45;
    protected static final int STATUSOPENFLAG = 46;
    protected static final int TOTALREVENUEOPPFORECASTAMT = 47;
    protected static final int VEHICLERESPONSECODE = 48;
    protected static final int OPPORTUNITYLINEEO = 49;
    protected static final int RELATIONSHIPEO = 50;
    protected static final int OPPORTUNITYCONTACTEO = 51;
    protected static final int OPPORTUNITYACCESSEO = 52;
    public static final String RCS_ID = "$Header: OpportunityEOImpl.java 115.71.115200.3 2005/10/18 20:42:06 ujayaram ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: OpportunityEOImpl.java 115.71.115200.3 2005/10/18 20:42:06 ujayaram ship $", "oracle.apps.asn.opportunity.schema.server");
    private static OAEntityDefImpl mDefinitionObject;

}
