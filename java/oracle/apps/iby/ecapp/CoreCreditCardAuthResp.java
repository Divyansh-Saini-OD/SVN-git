// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   CoreCreditCardAuthResp.java

package oracle.apps.iby.ecapp;

import java.sql.Date;
import java.text.DateFormat;
import java.util.Hashtable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.util.dateFormat.OracleDateFormat;
import oracle.apps.iby.bep.BEPUtils;
import oracle.apps.iby.exception.Log;
import oracle.apps.iby.util.*;
import oracle.apps.jtf.util.FNDLookups;
import oracle.apps.jtf.util.GeneralPreference;

// Referenced classes of package oracle.apps.iby.ecapp:
//            ReqResp, Constants, PmtResponse, Response




// Modified 21-Jul-2010 for I0349 Defect #4180 to include PS2000 and RetCode in response for use in AMEX settlement




public class CoreCreditCardAuthResp extends ReqResp
{

    public CoreCreditCardAuthResp(String s, int i, String s1, String s2, Date date, String s3, String s4, 
            String s5, String s6, String s7)
    {
        m_authCode = "";
        m_cvv2Result = "";
        m_AVSCode = "";
        m_trxnType = "";
        m_instrType = "";
        m_vpsBtchId = "";
        m_auxMsg = "";
        m_acquirer = "";
        super.m_NLSLang = s;
        super.m_tid = i;
        m_authCode = s1;
        super.m_refCode = s2;
        m_trxnDate = date;
        m_trxnType = s3;
        m_instrType = s4;
        m_vpsBtchId = s5;
        m_auxMsg = s6;
    }

    public CoreCreditCardAuthResp(String s, int i)
    {
        m_authCode = "";
        m_cvv2Result = "";
        m_AVSCode = "";
        m_trxnType = "";
        m_instrType = "";
        m_vpsBtchId = "";
        m_auxMsg = "";
        m_acquirer = "";
        super.m_NLSLang = s;
        super.m_tid = i;
    }

    public String getAuthCode()
    {
        return m_authCode;
    }

    public String getCVV2Result()
    {
        return m_cvv2Result;
    }

    public String getAVSCode()
    {
        return m_AVSCode;
    }

    public Date getTrxnDate()
    {
        return m_trxnDate;
    }

    public String getTrxnType()
    {
        return m_trxnType;
    }

    public String getinstrType()
    {
        return m_instrType;
    }

    public String getInstrType()
    {
        return m_instrType;
    }

    public String getVpsBatchId()
    {
        return m_vpsBtchId;
    }

    public String getAuxMsg()
    {
        return m_auxMsg;
    }

    public String getAcquirer()
    {
        return m_acquirer;
    }

    public void setAuthCode(String s)
    {
        m_authCode = s;
    }

    public void setCVV2Result(String s)
    {
        m_cvv2Result = s;
    }

    public void setAVSCode(String s)
    {
        m_AVSCode = s;
    }

    public void setTrxnDate(Date date)
    {
        m_trxnDate = date;
    }

    public void setTrxnType(String s)
    {
        m_trxnType = s;
    }

    public void setinstrType(String s)
    {
        m_instrType = s;
    }

    public void setInstrType(String s)
    {
        m_instrType = s;
    }

    public void setVpsBatchId(String s)
    {
        m_vpsBtchId = s;
    }

    public void setAuxMsg(String s)
    {
        m_auxMsg = s;
    }

    public void setAcquirer(String s)
    {
        m_acquirer = s;
    }

// Bushrod Start for I0349 Defect 4180
    public String getODPS2000()
    {
        return m_ODPS2000;
    }
    public void setODPS2000(String s)
    {
        m_ODPS2000 = s;
    }
    public String getODRetCode()
    {
        return m_ODRetCode;
    }
    public void setODRetCode(String s)
    {
        m_ODRetCode = s;
    }
// Bushrod End for I0349 Defect 4180


    public void seedDisplayPairs()
    {
        if(!bpsUtil.isTrivial(m_authCode))
            addDisplayPair(new NameValuePair("AUTHCODE", m_authCode));
        if(!bpsUtil.isTrivial(m_AVSCode))
            addDisplayPair(new NameValuePair("AVSCODE", m_AVSCode));
        try
        {
            OracleDateFormat oracledateformat = new OracleDateFormat(GeneralPreference.getDefaultDateFormat());
            if(m_trxnDate != null)
                addDisplayPair(new NameValuePair("TRXNDATE", oracledateformat.format(m_trxnDate)));
        }
        catch(Exception _ex) { }
        if(!bpsUtil.isTrivial(m_trxnType))
            try
            {
                Hashtable hashtable = FNDLookups.getFNDValues(0, "IBY_TRXNTYPES");
                addDisplayPair(new NameValuePair("TRXNTYPE", (String)hashtable.get(m_trxnType)));
            }
            catch(Exception exception)
            {
                Log.debug(exception);
            }
        if(!bpsUtil.isTrivial(m_instrType))
            addDisplayPair(new NameValuePair("CARDTYPE", m_instrType));
        if(!bpsUtil.isTrivial(m_vpsBtchId))
            addDisplayPair(new NameValuePair("VPSBATCHID", m_vpsBtchId));
        if(!bpsUtil.isTrivial(m_auxMsg))
            addDisplayPair(new NameValuePair("AUXMSG", m_auxMsg));
        if(!bpsUtil.isTrivial(m_acquirer))
            addDisplayPair(new NameValuePair("ACQUIRER", m_acquirer));
        super.seedDisplayPairs();
    }

    public String toString()
    {
        String s = "CoreCreditCardAuthResp{";
        s = s + super.toString();
        s = s + "authCode:=" + m_authCode + "CVV2Result:=" + m_cvv2Result + ",AVSCode:=" + m_AVSCode + ",trxnDate:=" + m_trxnDate + ",trxnType:=" + m_trxnType + ",instrType:=" + m_instrType + ",vpsBatchId:=" + m_vpsBtchId + ",auxMsg:=" + m_auxMsg + ",acquirer:=" + m_acquirer + "}";
        return s;
    }

    public void flatten(Hashtable hashtable, int i)
    {
        if(i != 2)
            return;
        super.flatten(hashtable, i);
        if(!hashtable.containsKey("OapfTrxnDate") && m_trxnDate != null)
            hashtable.put("OapfTrxnDate", PmtResponse.s_txndate_formater.format(m_trxnDate));
        flatAdd(hashtable, "OapfAuthcode", m_authCode);
        flatAdd(hashtable, "OapfCVV2Result", m_cvv2Result);
        flatAdd(hashtable, "OapfAVScode", m_AVSCode);
        flatAdd(hashtable, "OapfTrxnType", m_trxnType);
        flatAdd(hashtable, "OapfPmtInstrType", m_instrType);
        flatAdd(hashtable, "OapfVpsBatchID", m_vpsBtchId);
        flatAdd(hashtable, "OapfAuxMsg", m_auxMsg);
        flatAdd(hashtable, "OapfAcquirer", m_acquirer);
    }

    public boolean supportsType(int i)
    {
        return i == 2;
    }

    public static final String RCS_ID = "$Header: CoreCreditCardAuthResp.java 115.17 2003/04/28 21:58:23 jleybovi ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: CoreCreditCardAuthResp.java 115.17 2003/04/28 21:58:23 jleybovi ship $", "oracle.apps.iby.ecapp");
    protected String m_authCode;
    protected String m_cvv2Result;
    protected String m_AVSCode;
    protected String m_trxnType;
    protected String m_instrType;
    protected String m_vpsBtchId;
    protected String m_auxMsg;
    protected String m_acquirer;
    protected Date m_trxnDate;

    protected String m_ODPS2000;  // Bushrod added for I0349 Defect 4180
    protected String m_ODRetCode; // Bushrod added for I0349 Defect 4180
}
