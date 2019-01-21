// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   AuthHandler.java

package oracle.apps.iby.ecservlet;

import java.io.IOException;
import java.sql.Date;
import java.util.Hashtable;
import javax.servlet.http.HttpServletResponse;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.iby.database.PaymentDB;
import oracle.apps.iby.ecapp.*;
import oracle.apps.iby.ecapp.irisk.RiskResp;
import oracle.apps.iby.exception.Log;
import oracle.apps.iby.exception.PSException;

// Referenced classes of package oracle.apps.iby.ecservlet:
//            ECRequest, ECResponse, ECServletResponse, HashUtil





// Modified 21-Jul-2010 for I0349 Defect #4180 to include PS2000 and RetCode in response for use in AMEX settlement





public class AuthHandler
{

    public AuthHandler()
    {
    }

    public void respHandler(HttpServletResponse httpservletresponse, boolean flag, PSResult psresult, ECRequest ecrequest, String s, String s1)
        throws IOException, PSException
    {
        String s7 = new String("");
        int i = 0;
        int j = 0;
        String s8 = new String("");
        String s9 = new String("");
        String s10 = new String("");
        Hashtable hashtable = new Hashtable();
        HashUtil hashutil = new HashUtil(hashtable);
        String s11 = ecrequest.getString("OapfOrderId", true);
        Object obj;
        if(s1.equalsIgnoreCase("BANKACCOUNT"))
            obj = (AccXfrReqResp)psresult.getPmtResponse();
        else
            obj = (CoreCreditCardAuthResp)psresult.getPmtResponse();
        String s2 = psresult.getStatus();
        Log.consoleDebug("AuthService: status=" + s2);
        if(obj == null)
        {
            String s3 = psresult.getCode();
            String s5 = psresult.getCause();
            if(!flag)
                s2 = ECServletResponse.mapStatusCode(s3);
            hashutil.checkOptional("OapfStatus", s2);
            hashutil.checkOptional("OapfCode", s3);
            hashutil.checkOptional("OapfOrderId", s11);
            if(flag)
                hashutil.checkOptional("OapfCause", s5);
            else
                hashutil.checkOptional("OapfStatusMsg", s5);
        } else
        {
            String s12 = ((Response) (obj)).getErrLocation();
            String s13 = ((Response) (obj)).getBEPErrorCode();
            String s14 = ((Response) (obj)).getBEPErrorMsg();
            String s15 = ((Response) (obj)).getNLSLang();
            Date date = ((PmtResponse) (obj)).getEarliestSettlementDate();
            Date date1 = ((PmtResponse) (obj)).getScheduleDate();
            int k = ((PmtResponse) (obj)).getScheduleFlag();
            RiskResp riskresp = ((PmtResponse) (obj)).getRiskResp();
            int l = ((ReqResp) (obj)).getTID();
            String s16 = ((ReqResp) (obj)).getRefCode();
            if(s11 == null && l > 0)
                s11 = PaymentDB.getTangibleID(l);
            if(riskresp != null)
            {
                s7 = riskresp.getStatus();
                s8 = riskresp.getErrorCode();
                s9 = riskresp.getErrorMsg();
                s10 = riskresp.getAdditionalMsg();
                i = riskresp.getScore();
                j = riskresp.getThresholdVal();
            }
            hashutil.checkOptional("OapfTimestamp", ((Response) (obj)).getFormattedTimestamp());
            if(s2.equals("0") || s2.equals("0000"))
            {
                if(!flag)
                    hashutil.checkOptional("OapfStatus", "PMT-0000");
                else
                    hashutil.checkOptional("OapfStatus", s2);
                hashutil.checkOptional("OapfTransactionId", String.valueOf(l));
                hashutil.checkOptional("OapfRefcode", s16);
                hashutil.checkOptional("OapfOrderId", s11);
                hashutil.checkOptional("OapfNlsLang", s15);
                if(s.equalsIgnoreCase("OFFLINE"))
                {
                    if(date != null)
                        hashutil.checkOptional("OapfEarliestSettlementDate", date.toString());
                    if(date1 != null)
                        hashutil.checkOptional("OapfSchedDate", date1.toString());
                    hashutil.checkOptional("OapfSchedFlag", String.valueOf(k));
                }
                Log.debug("AuthService: riskResp: " + riskresp);
                if(riskresp != null)
                {
                    hashutil.checkOptional("OapfRiskStatus", s7);
                    Log.debug("AuthService: OapfRiskStatus: " + String.valueOf(s7));
                    if(!s7.equals("0"))
                    {
                        hashutil.checkOptional("OapfRiskErrorCode", s8);
                        hashutil.checkOptional("OapfRiskErrorMsg", s9);
                        hashutil.checkOptional("OapfRiskAdditionalErrorMsg", s10);
                    }
                    hashutil.checkOptional("OapfRiskScore", String.valueOf(i));
                    Log.debug("AuthService: OapfRiskScore: " + String.valueOf(i));
                    hashutil.checkOptional("OapfRiskThresholdVal", String.valueOf(j));
                    Log.debug("AuthService: OapfRiskThresholdVal: " + String.valueOf(j));
                    hashutil.checkOptional("OapfRiskyFlag", riskresp.isRisky() ? "YES" : "NO");
                }
            } else
            if(!s2.equals("0") && !s2.equals("0000"))
            {
                String s4 = psresult.getCode();
                String s6 = psresult.getCause();
                if(!flag)
                    s2 = ECServletResponse.mapStatusCode(s4);
                hashutil.checkOptional("OapfStatus", s2);
                hashutil.checkOptional("OapfCode", s4);
                if(flag)
                    hashutil.checkOptional("OapfCause", s6);
                else
                    hashutil.checkOptional("OapfStatusMsg", s6);
                hashutil.checkOptional("OapfTransactionId", String.valueOf(l));
                hashutil.checkOptional("OapfOrderId", s11);
                hashutil.checkOptional("OapfErrLocation", s12);
                hashutil.checkOptional("OapfVendErrCode", s13);
                hashutil.checkOptional("OapfVendErrmsg", s14);
                hashutil.checkOptional("OapfNlsLang", s15);
            }
            Log.debug("AuthService: checked common fields.");
            if(s1.equalsIgnoreCase("BANKACCOUNT"))
            {
                int i1 = ((AccXfrReqResp)obj).getPmtPrcSt();
                Date date2 = ((AccXfrReqResp)obj).getDtPmtPrc();
                Log.consoleDebug("AuthService: BankAccount response obtained");
                if(s2.equals("0"))
                {
                    hashutil.checkOptional("OapfPmtProcStatus", String.valueOf(i1));
                    if(date2 != null)
                        hashutil.checkOptional("OapfPmtProcDate", date2.toString());
                }
            } else
            {
                String s17 = ((CoreCreditCardAuthResp)obj).getTrxnType();
                Date date3 = ((CoreCreditCardAuthResp)obj).getTrxnDate();
                String s18 = ((CoreCreditCardAuthResp)obj).getAuthCode();
                String s19 = ((CoreCreditCardAuthResp)obj).getAVSCode();
                String s20 = ((CoreCreditCardAuthResp)obj).getCVV2Result();
                String s21 = ((CoreCreditCardAuthResp)obj).getAcquirer();
                String s22 = ((CoreCreditCardAuthResp)obj).getVpsBatchId();
                String s23 = ((CoreCreditCardAuthResp)obj).getAuxMsg();
                s1 = ((CoreCreditCardAuthResp)obj).getinstrType();
                if(s2.equals("0") || s2.equals("0000"))
                {
                    if(date3 != null)
                        hashutil.checkOptional("OapfTrxnDate", date3.toString());
                    hashutil.checkOptional("OapfTrxnType", s17);
                    hashutil.checkOptional("OapfAuthcode", s18);
                    if(!flag)
                        hashutil.checkOptional("OapfApprovalCode", s18);
                    hashutil.checkOptional("OapfAVScode", s19);
                    hashutil.checkOptional("OapfCVV2Result", s20);
                    hashutil.checkOptional("OapfPmtInstrType", s1);
                    hashutil.checkOptional("OapfAcquirer", s21);
                    hashutil.checkOptional("OapfVpsBatchId", s22);
                    hashutil.checkOptional("OapfAuxMsg", s23);

// Bushrod Start for I0349 Defect 4180
                    String sODPS2000  = ((CoreCreditCardAuthResp)obj).getODPS2000();
                    String sODRetCode = ((CoreCreditCardAuthResp)obj).getODRetCode();
                    hashutil.checkOptional("OapfODPS2000",sODPS2000);
                    hashutil.checkOptional("OapfODRetCode",sODRetCode);
// Bushrod End for I0349 Defect 4180

                } else
                if(!s2.equals("0") && !s2.equals("0000"))
                {
                    hashutil.checkOptional("OapfTrxnType", s17);
                    if(date3 != null)
                        hashutil.checkOptional("OapfTrxnDate", date3.toString());
                    hashutil.checkOptional("OapfPmtInstrType", s1);
                    hashutil.checkOptional("OapfAuxMsg", s23);
                }
            }
        }
        Log.consoleDebug("AuthService: response is generated.");
        ECServletResponse ecservletresponse = new ECServletResponse(httpservletresponse);
        ecservletresponse.setHeaders(hashtable);
        ecservletresponse.setBody(hashtable);
    }

    public static final String RCS_ID = "$Header: AuthHandler.java 115.22.1158.1 2002/07/20 16:11:35 appldev ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: AuthHandler.java 115.22.1158.1 2002/07/20 16:11:35 appldev ship $", "oracle.apps.iby.ecservlet");

}
