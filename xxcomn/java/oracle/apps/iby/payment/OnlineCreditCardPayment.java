// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   OnlineCreditCardPayment.java

package oracle.apps.iby.payment;

import java.sql.Date;
import java.text.DateFormat;
import java.text.Format;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;
import java.util.Enumeration;
import java.util.Hashtable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.iby.bep.BEPUtils;
import oracle.apps.iby.database.PmtInstrDB;
import oracle.apps.iby.ecapp.Address;
import oracle.apps.iby.ecapp.BatchTrxn;
import oracle.apps.iby.ecapp.Bill;
import oracle.apps.iby.ecapp.CapResp;
import oracle.apps.iby.ecapp.CloseBatchResp;
import oracle.apps.iby.ecapp.Constants;
import oracle.apps.iby.ecapp.CoreCreditCardAuthResp;
import oracle.apps.iby.ecapp.CoreCreditCardBatch;
import oracle.apps.iby.ecapp.CoreCreditCardCapResp;
import oracle.apps.iby.ecapp.CoreCreditCardCapture;
import oracle.apps.iby.ecapp.CoreCreditCardCloseBatchResp;
import oracle.apps.iby.ecapp.CoreCreditCardCredit;
import oracle.apps.iby.ecapp.CoreCreditCardCreditResp;
import oracle.apps.iby.ecapp.CoreCreditCardQry;
import oracle.apps.iby.ecapp.CoreCreditCardReq;
import oracle.apps.iby.ecapp.CoreCreditCardRetResp;
import oracle.apps.iby.ecapp.CoreCreditCardReturn;
import oracle.apps.iby.ecapp.CoreCreditCardVoid;
import oracle.apps.iby.ecapp.CoreCreditCardVoidResp;
import oracle.apps.iby.ecapp.CreditCard;
import oracle.apps.iby.ecapp.CreditResp;
import oracle.apps.iby.ecapp.CreditTrxn;
import oracle.apps.iby.ecapp.InquireResp;
import oracle.apps.iby.ecapp.InquireResult;
import oracle.apps.iby.ecapp.PSResult;
import oracle.apps.iby.ecapp.PmtInstr;
import oracle.apps.iby.ecapp.PmtResponse;
import oracle.apps.iby.ecapp.Price;
import oracle.apps.iby.ecapp.QueryTrxn;
import oracle.apps.iby.ecapp.ReqResp;
import oracle.apps.iby.ecapp.Response;
import oracle.apps.iby.ecapp.RetResp;
import oracle.apps.iby.ecapp.ReturnTrxn;
import oracle.apps.iby.ecapp.Tangible;
import oracle.apps.iby.ecapp.Transaction;
import oracle.apps.iby.ecapp.User;
import oracle.apps.iby.ecapp.VoidResp;
import oracle.apps.iby.ecapp.VoidTrxn;
import oracle.apps.iby.exception.Log;
import oracle.apps.iby.exception.PSException;
import oracle.apps.iby.extend.ExtUtils;
import oracle.apps.iby.extend.TxnCustomizer;
import oracle.apps.iby.security.CryptoString;
import oracle.apps.iby.util.AddOnlyHashtable;
import oracle.apps.iby.util.HTMLPage;
import oracle.apps.iby.util.InputURL;
import oracle.apps.iby.util.ReadOnlyHashtable;
import oracle.apps.iby.util.bpsUtil;

// Referenced classes of package oracle.apps.iby.payment:
//            CreditCardPayment, BEPInfo, CreditCardProcessor, Payment, 
//            PaymentScheme, SET





// Modified 21-Jul-2010 for I0349 Defect #4180 to include PS2000 and RetCode in response for use in AMEX settlement





public class OnlineCreditCardPayment extends CreditCardPayment
{

    public OnlineCreditCardPayment(Transaction transaction, String s)
        throws PSException
    {
        ht = new Hashtable(10);
        inputUrl = new InputURL(ht);
        Log.debug("trying to put in " + transaction.getNLSLang());
        inputUrl.put("OapfNlsLang", transaction.getNLSLang());
        super.m_transaction = transaction;
        if(s.equals("CORE"))
        {
            creditCard = new CreditCardProcessor(inputUrl, transaction);
            return;
        } else
        {
            creditCard = new SET(inputUrl, transaction);
            return;
        }
    }

    protected void getPmtInstrInfo()
        throws PSException
    {
        CreditCard creditcard = (CreditCard)super.m_pmtInstr;
        if(creditcard.getId() != -99 && bpsUtil.isTrivial(creditcard.getCCNumber().getClearText()))
            PmtInstrDB.fillCreditCard(super.m_payer, creditcard);
    }

    protected void setPmtInstrInfo()
    {
        CreditCard creditcard = (CreditCard)super.m_pmtInstr;
        Date date = creditcard.getExpDate();
        Log.debug("got CC expiration date: " + date);
        inputUrl.put("OapfPmtInstrID", creditcard.getCCNumber());
        SimpleDateFormat simpledateformat = new SimpleDateFormat("MM/yy");
        String s = simpledateformat.format(date);
        Log.debug("after format: " + s);
        inputUrl.put("OapfPmtInstrExp", s);
        int i = ((CreditCard)super.m_pmtInstr).getId();
        Integer integer = new Integer(i);
        inputUrl.put("OapfPmtInstrDBID", integer.toString());
    }

    protected void setTangibleInfo()
    {
        NumberFormat numberformat = NumberFormat.getNumberInstance();
        numberformat.setGroupingUsed(false);
        numberformat.setMaximumFractionDigits(2);
        numberformat.setMinimumFractionDigits(2);
        Double double1 = super.m_tangible[0].getAmount();
        Log.debug("Setting tangible amount: " + double1);
        inputUrl.put("OapfPrice", numberformat.format(double1));
        Log.debug("Setting tangible currency: " + super.m_tangible[0].getCurrency());
        inputUrl.put("OapfCurr", super.m_tangible[0].getCurrency());
        String s = ((Bill)super.m_tangible[0]).getUserAccount();
        Log.debug("Setting tangible UserAcct: " + s);
        inputUrl.put("OapfUserAcct", s);
        String s1 = ((Bill)super.m_tangible[0]).getRefInfo();
        Log.debug("Setting tangible refinfo: " + s1);
        inputUrl.put("OapfRefInfo", s1);
        String s2 = ((Bill)super.m_tangible[0]).getMemo();
        Log.debug("Setting tangible memo: " + s2);
        inputUrl.put("OapfMemo", s2);
    }

    protected void setPayerInfo()
    {
        Log.debug("setting payer info...");
        if(super.m_payer == null)
            Log.debug("m_payer is null!", 1);
        if(super.m_payer.getId() != null)
        {
            Log.debug("put OapfPayerId: " + super.m_payer.getId());
            inputUrl.put("OapfPayerId", super.m_payer.getId());
        }
    }

    protected void setPayeeInfo()
    {
        Log.debug("setting payee info...");
        if(super.m_transaction instanceof CoreCreditCardBatch)
        {
            inputUrl.put("OapfMerchantId", ((CoreCreditCardBatch)super.m_transaction).getPayeeId());
            inputUrl.put("OapfMerchStoreId", ((CoreCreditCardBatch)super.m_transaction).getPayeeId());
            return;
        } else
        {
            inputUrl.put("OapfMerchantId", super.m_payee.getId());
            inputUrl.put("OapfMerchStoreId", super.m_payee.getId());
            return;
        }
    }

    private void setTransactionId(int i)
    {
        Integer integer = new Integer(i);
        inputUrl.put("OapfTransactionId", integer.toString());
    }

    protected void handleBEPSuccess(PSResult psresult, HTMLPage htmlpage)
    {
        psresult.setStatus("0");
        Response response = (Response)psresult.getResult();
        java.util.Date date = getTime((String)htmlpage.httpHeader().get("OapfTrxnDate"));
        Date date1 = new Date(date.getTime());
        response.setTimestamp(date);
        Log.debug("handle bep success...");
        if(response instanceof CoreCreditCardAuthResp)
        {
            CoreCreditCardAuthResp corecreditcardauthresp = (CoreCreditCardAuthResp)response;
            corecreditcardauthresp.setRefCode((String)htmlpage.httpHeader().get("OapfRefcode"));
            corecreditcardauthresp.setTrxnDate(date1);
            corecreditcardauthresp.setTrxnType((String)htmlpage.httpHeader().get("OapfTrxnType"));
            corecreditcardauthresp.setinstrType((String)htmlpage.httpHeader().get("OapfPmtInstrType"));
            return;
        }
        if(response instanceof CoreCreditCardCapResp)
        {
            Log.debug("capture response...");
            CoreCreditCardCapResp corecreditcardcapresp = (CoreCreditCardCapResp)response;
            corecreditcardcapresp.setRefCode((String)htmlpage.httpHeader().get("OapfRefcode"));
            corecreditcardcapresp.setTrxnDate(date1);
            corecreditcardcapresp.setTrxnType((String)htmlpage.httpHeader().get("OapfTrxnType"));
            corecreditcardcapresp.setInstrType((String)htmlpage.httpHeader().get("OapfPmtInstrType"));
            return;
        }
        if(response instanceof CoreCreditCardVoidResp)
        {
            CoreCreditCardVoidResp corecreditcardvoidresp = (CoreCreditCardVoidResp)response;
            corecreditcardvoidresp.setRefCode((String)htmlpage.httpHeader().get("OapfRefcode"));
            corecreditcardvoidresp.setTrxnDate(date1);
            corecreditcardvoidresp.setTrxnType((String)htmlpage.httpHeader().get("OapfTrxnType"));
            corecreditcardvoidresp.setInstrType((String)htmlpage.httpHeader().get("OapfPmtInstrType"));
            return;
        }
        if(response instanceof CoreCreditCardRetResp)
        {
            CoreCreditCardRetResp corecreditcardretresp = (CoreCreditCardRetResp)response;
            corecreditcardretresp.setRefCode((String)htmlpage.httpHeader().get("OapfRefcode"));
            corecreditcardretresp.setTrxnDate(date1);
            corecreditcardretresp.setTrxnType((String)htmlpage.httpHeader().get("OapfTrxnType"));
            corecreditcardretresp.setInstrType((String)htmlpage.httpHeader().get("OapfPmtInstrType"));
            return;
        }
        if(response instanceof CoreCreditCardCreditResp)
        {
            CoreCreditCardCreditResp corecreditcardcreditresp = (CoreCreditCardCreditResp)response;
            corecreditcardcreditresp.setRefCode((String)htmlpage.httpHeader().get("OapfRefcode"));
            corecreditcardcreditresp.setTrxnDate(date1);
            corecreditcardcreditresp.setTrxnType((String)htmlpage.httpHeader().get("OapfTrxnType"));
            corecreditcardcreditresp.setInstrType((String)htmlpage.httpHeader().get("OapfPmtInstrType"));
            return;
        } else
        {
            Log.debug("ENCOUNTERED unknown response type!!!!", 1);
            return;
        }
    }

    private void handleAuthSuccessResponse(int i, HTMLPage htmlpage, CoreCreditCardAuthResp corecreditcardauthresp, InquireResult inquireresult)
    {
        corecreditcardauthresp.setAuthCode(bpsUtil.trim((String)htmlpage.httpHeader().get("OapfAuthcode-" + i)));
        corecreditcardauthresp.setAVSCode((String)htmlpage.httpHeader().get("OapfAVScode-" + i));
        corecreditcardauthresp.setinstrType((String)htmlpage.httpHeader().get("OapfPmtInstrType-" + i));
        corecreditcardauthresp.setAcquirer((String)htmlpage.httpHeader().get("OapfAcquirer-" + i));
        corecreditcardauthresp.setAuxMsg((String)htmlpage.httpHeader().get("OapfAuxMsg-" + i));
    }

    protected void handleAuthResponse(CoreCreditCardAuthResp corecreditcardauthresp, HTMLPage htmlpage)
    {
        corecreditcardauthresp.setAuthCode(bpsUtil.trim((String)htmlpage.httpHeader().get("OapfAuthcode")));
        if((String)htmlpage.httpHeader().get("OapfAVScode") != null)
            corecreditcardauthresp.setAVSCode((String)htmlpage.httpHeader().get("OapfAVScode"));
        if((String)htmlpage.httpHeader().get("OapfCVV2Result") != null)
            corecreditcardauthresp.setCVV2Result((String)htmlpage.httpHeader().get("OapfCVV2Result"));
        if((String)htmlpage.httpHeader().get("OapfAcquirer") != null)
        {
            corecreditcardauthresp.setAcquirer((String)htmlpage.httpHeader().get("OapfAcquirer"));
            corecreditcardauthresp.setVpsBatchId((String)htmlpage.httpHeader().get("OapfVpsBatchId"));
        }
        corecreditcardauthresp.setAuxMsg((String)htmlpage.httpHeader().get("OapfAuxMsg"));

// Bushrod Start for I0349 Defect 4180
        if((String)htmlpage.httpHeader().get("OapfODRetCode") != null)
            corecreditcardauthresp.setODRetCode((String)htmlpage.httpHeader().get("OapfODRetCode"));
        if((String)htmlpage.httpHeader().get("OapfODPS2000") != null)
            corecreditcardauthresp.setODPS2000((String)htmlpage.httpHeader().get("OapfODPS2000"));
// Bushrod End for I0349 Defect 4180
    }

    protected void handleBEPError(PSResult psresult, HTMLPage htmlpage, String s)
    {
        psresult.setStatus("3");
        PSException psexception;
        if(s.equals("0004"))
        {
            String s1 = (String)htmlpage.httpHeader().get("OapfVendErrCode");
            if(s1 == null)
                s1 = "";
            psexception = new PSException("IBY_0004", "FIELD", s1);
        } else
        {
            psexception = new PSException("IBY_" + s);
        }
        psresult.setMMessage(psexception.getMMessage());
        Response response = (Response)psresult.getResult();
        response.setNLSLang((String)htmlpage.httpHeader().get("OapfNlsLang"));
        response.setErrorLocation((String)htmlpage.httpHeader().get("OapfErrLocation"));
        response.setBEPErrorCode((String)htmlpage.httpHeader().get("OapfVendErrCode"));
        response.setBEPErrorMsg((String)htmlpage.httpHeader().get("OapfVendErrmsg"));
    }

    public PSResult pay()
        throws PSException
    {
        getPmtInstrInfo();
        setPmtInstrInfo();
        setTangibleInfo();
        setPayeeInfo();
        setPayerInfo();
        CoreCreditCardReq corecreditcardreq = (CoreCreditCardReq)super.m_transaction;
        if(corecreditcardreq.getRetryFlag().equals("Y"))
            inputUrl.put("OapfRetry", "yes");
        else
            inputUrl.put("OapfRetry", "no");
        inputUrl.put("OapfTrxnRef", super.m_transaction.getTrxnRef());
        String s = corecreditcardreq.getAuthType();
        boolean flag = false;
        if(s.equals("AUTHANDCAPTURE"))
        {
            flag = true;
            s = "AUTHONLY";
        }
        inputUrl.put("OapfAuthType", s);
        mapInputUrl("oraauth", "ORAPMTREQ");
        setVoiceAuthInfo();
        putOptionalInfo();
        putAddress();
        mapVendorInfo();
        CreditCard creditcard = (CreditCard)super.m_pmtInstr;
        if(!bpsUtil.isTrivial(creditcard.getHolderEmail()))
            inputUrl.put("OapfEmail", creditcard.getHolderEmail());
        if(!bpsUtil.isTrivial(creditcard.getHolderPhoneNumber()))
            inputUrl.put("OapfPhone", creditcard.getHolderPhoneNumber());
        TxnCustomizer txncustomizer = ExtUtils.loadCustomizer("ibyextend.TxnCustomizer_" + super.m_bepInfo.getSuffix());
        ExtUtils.customizePre(txncustomizer, super.m_bepInfo.getSuffix(), new AddOnlyHashtable(ht));
        Log.debug("OnlineCCPaymnt::pay() Returning from customizePre()");
        HTMLPage htmlpage = creditCard.perform();
        Log.debug("After returning from creditcard.perform (authonly) ");
        ExtUtils.customizePost(txncustomizer, super.m_bepInfo.getSuffix(), new ReadOnlyHashtable(htmlpage.httpHeader()));
        Log.debug("OnlineCCPaymnt::pay() Returning from customizePost()");
        int i = Integer.parseInt((String)htmlpage.httpHeader().get("OapfTransactionId"));
        String s1 = (String)htmlpage.httpHeader().get("OapfNlsLang");
        CoreCreditCardAuthResp corecreditcardauthresp = new CoreCreditCardAuthResp(s1, i);
        PSResult psresult = new PSResult(corecreditcardauthresp);
        String s2 = (String)htmlpage.httpHeader().get("OapfStatus");
        Log.debug("OnlineCreditCardPayment: OapfStatus: " + s2);
        if(!CreditCardPayment.statusOK(s2))
        {
            handleBEPError(psresult, htmlpage, s2);
            return psresult;
        }
        if(!flag)
        {
            handleBEPSuccess(psresult, htmlpage);
            handleAuthResponse(corecreditcardauthresp, htmlpage);
            return psresult;
        }
        Log.debug("Starting the 'capture' part of 'AUTHANDCAPTURE' request!");
        inputUrl.remove("OapfAuthType");
        Double double1 = super.m_tangible[0].getPrice().getAmount();
        String s3 = super.m_tangible[0].getPrice().getCurrency();
        super.m_transaction = new CoreCreditCardCapture(s1, "ONLINE", null, i, s3, double1);
        htmlpage = captureZero();
        s2 = (String)htmlpage.httpHeader().get("OapfStatus");
        Log.debug("OnlineCreditCardPayment: OapfStatus: " + s2);
        if(CreditCardPayment.statusOK(s2))
            handleBEPSuccess(psresult, htmlpage);
        else
            handleBEPError(psresult, htmlpage, s2);
        return psresult;
    }

    public PSResult cancel()
        throws PSException
    {
        throw new PSException("IBY_41519");
    }

    public PSResult avoid()
        throws PSException
    {
        CoreCreditCardVoid corecreditcardvoid = (CoreCreditCardVoid)super.m_transaction;
        inputUrl.put("OapfTrxnRef", super.m_transaction.getTrxnRef());
        mapInputUrl("oravoid", "ORAPMTVOID");
        inputUrl.put("OapfTrxnType", corecreditcardvoid.getTrxnType());
        setPayeeInfo();
        mapVendorInfo();
        int i = corecreditcardvoid.getTID();
        setTransactionId(i);
        TxnCustomizer txncustomizer = ExtUtils.loadCustomizer("ibyextend.TxnCustomizer_" + super.m_bepInfo.getSuffix());
        ExtUtils.customizePre(txncustomizer, super.m_bepInfo.getSuffix(), new AddOnlyHashtable(ht));
        Log.debug("OnlineCCPaymnt::VOID() Returning from customizePre()");
        HTMLPage htmlpage = creditCard.perform();
        ExtUtils.customizePost(txncustomizer, super.m_bepInfo.getSuffix(), new ReadOnlyHashtable(htmlpage.httpHeader()));
        Log.debug("OnlineCCPaymnt::VOID() Returning from customizePost()");
        Log.debug("After returning from void in onlinecc ");
        String s = (String)htmlpage.httpHeader().get("OapfNlsLang");
        CoreCreditCardVoidResp corecreditcardvoidresp = new CoreCreditCardVoidResp(s, i);
        PSResult psresult = new PSResult(corecreditcardvoidresp);
        String s1 = (String)htmlpage.httpHeader().get("OapfStatus");
        Log.debug("OnlineCreditCardPayment: OapfStatus: " + s1);
        if(CreditCardPayment.statusOK(s1))
            handleBEPSuccess(psresult, htmlpage);
        else
            handleBEPError(psresult, htmlpage, s1);
        return psresult;
    }

    protected HTMLPage captureZero()
        throws PSException
    {
        CoreCreditCardCapture corecreditcardcapture = (CoreCreditCardCapture)super.m_transaction;
        inputUrl.put("OapfTrxnRef", super.m_transaction.getTrxnRef());
        mapInputUrl("oracapture", "ORAPMTCAPTURE");
        inputUrl.put("OapfPrice", corecreditcardcapture.getPrice().toString());
        inputUrl.put("OapfCurr", corecreditcardcapture.getCurr());
        setPayeeInfo();
        int i = corecreditcardcapture.getTID();
        setTransactionId(i);
        mapVendorInfo();
        Log.debug("Before calling capture in onlinecc ");
        TxnCustomizer txncustomizer = ExtUtils.loadCustomizer("ibyextend.TxnCustomizer_" + super.m_bepInfo.getSuffix());
        ExtUtils.customizePre(txncustomizer, super.m_bepInfo.getSuffix(), new AddOnlyHashtable(ht));
        Log.debug("OnlineCCPaymnt::capture() Returning from customizePre()");
        HTMLPage htmlpage = creditCard.perform();
        ExtUtils.customizePost(txncustomizer, super.m_bepInfo.getSuffix(), new ReadOnlyHashtable(htmlpage.httpHeader()));
        Log.debug("OnlineCCPaymnt::capture() Returning from customizePost()");
        return htmlpage;
    }

    public PSResult capture()
        throws PSException
    {
        HTMLPage htmlpage = captureZero();
        Log.debug("After returning from capture in onlinecc  ");
        int i = ((CoreCreditCardCapture)super.m_transaction).getTID();
        String s = (String)htmlpage.httpHeader().get("OapfNlsLang");
        CoreCreditCardCapResp corecreditcardcapresp = new CoreCreditCardCapResp(s, i);
        PSResult psresult = new PSResult(corecreditcardcapresp);
        String s1 = (String)htmlpage.httpHeader().get("OapfStatus");
        Log.debug("OnlineCreditCardPayment: OapfStatus: " + s1);
        if(CreditCardPayment.statusOK(s1))
            handleBEPSuccess(psresult, htmlpage);
        else
            handleBEPError(psresult, htmlpage, s1);
        return psresult;
    }

    public PSResult areturn()
        throws PSException
    {
        CoreCreditCardReturn corecreditcardreturn = (CoreCreditCardReturn)super.m_transaction;
        inputUrl.put("OapfTrxnRef", super.m_transaction.getTrxnRef());
        mapInputUrl("orareturn", "ORAPMTRETURN");
        inputUrl.put("OapfPrice", corecreditcardreturn.getPrice().toString());
        inputUrl.put("OapfCurr", corecreditcardreturn.getCurr());
        int i = corecreditcardreturn.getTID();
        setTransactionId(i);
        setPayeeInfo();
        inputUrl.put("OapfMerchUsername", corecreditcardreturn.getUserName());
        inputUrl.put("OapfMerchPassword", corecreditcardreturn.getPasswd());
        mapVendorInfo();
        TxnCustomizer txncustomizer = ExtUtils.loadCustomizer("ibyextend.TxnCustomizer_" + super.m_bepInfo.getSuffix());
        ExtUtils.customizePre(txncustomizer, super.m_bepInfo.getSuffix(), new AddOnlyHashtable(ht));
        Log.debug("OnlineCCPaymnt::RETURN() Returning from customizePre()");
        HTMLPage htmlpage = creditCard.perform();
        ExtUtils.customizePost(txncustomizer, super.m_bepInfo.getSuffix(), new ReadOnlyHashtable(htmlpage.httpHeader()));
        Log.debug("OnlineCCPaymnt::RETURN() Returning from customizePost()");
        Log.debug("After returning from return in onlinecc");
        String s = (String)htmlpage.httpHeader().get("OapfNlsLang");
        CoreCreditCardRetResp corecreditcardretresp = new CoreCreditCardRetResp(s, i);
        PSResult psresult = new PSResult(corecreditcardretresp);
        String s1 = (String)htmlpage.httpHeader().get("OapfStatus");
        Log.debug("OnlineCreditCardPayment: OapfStatus: " + s1);
        if(CreditCardPayment.statusOK(s1))
            handleBEPSuccess(psresult, htmlpage);
        else
            handleBEPError(psresult, htmlpage, s1);
        return psresult;
    }

    public PSResult credit()
        throws PSException
    {
        CoreCreditCardCredit corecreditcardcredit = (CoreCreditCardCredit)super.m_transaction;
        if(corecreditcardcredit.getRetryFlag().equals("Y"))
            inputUrl.put("OapfRetry", "yes");
        else
            inputUrl.put("OapfRetry", "no");
        inputUrl.put("OapfTrxnRef", super.m_transaction.getTrxnRef());
        getPmtInstrInfo();
        setPmtInstrInfo();
        setTangibleInfo();
        setPayeeInfo();
        setPayerInfo();
        inputUrl.put("OapfMerchUsername", corecreditcardcredit.getUserName());
        inputUrl.put("OapfMerchPassword", corecreditcardcredit.getPasswd());
        mapInputUrl("oracredit", "ORAPMTCREDIT");
        mapVendorInfo();
        TxnCustomizer txncustomizer = ExtUtils.loadCustomizer("ibyextend.TxnCustomizer_" + super.m_bepInfo.getSuffix());
        ExtUtils.customizePre(txncustomizer, super.m_bepInfo.getSuffix(), new AddOnlyHashtable(ht));
        Log.debug("OnlineCCPaymnt::credit() Returning from customizePre()");
        HTMLPage htmlpage = creditCard.perform();
        ExtUtils.customizePost(txncustomizer, super.m_bepInfo.getSuffix(), new ReadOnlyHashtable(htmlpage.httpHeader()));
        Log.debug("OnlineCCPaymnt::credit() Returning from customizePost()");
        Log.debug("after returning from credit in onlinecc ");
        int i = Integer.parseInt((String)htmlpage.httpHeader().get("OapfTransactionId"));
        String s = (String)htmlpage.httpHeader().get("OapfNlsLang");
        CoreCreditCardCreditResp corecreditcardcreditresp = new CoreCreditCardCreditResp(s, i);
        PSResult psresult = new PSResult(corecreditcardcreditresp);
        String s1 = (String)htmlpage.httpHeader().get("OapfStatus");
        Log.debug("OnlineCreditCardPayment: OapfStatus: " + s1);
        if(CreditCardPayment.statusOK(s1))
            handleBEPSuccess(psresult, htmlpage);
        else
            handleBEPError(psresult, htmlpage, s1);
        return psresult;
    }

    public PSResult queryBatch()
        throws PSException
    {
        inputUrl.put("OapfAction", "oraqrybatchstatus");
        inputUrl.put("OapfReqType", "ORAPMTQRYBATCHSTATUS");
        PSResult psresult = handleBatch();
        return psresult;
    }

    public PSResult closeBatch()
        throws PSException
    {
        inputUrl.put("OapfAction", "oraclosebatch");
        inputUrl.put("OapfReqType", "ORAPMTCLOSEBATCH");
        PSResult psresult = handleBatch();
        return psresult;
    }

    public PSResult handleBatch()
        throws PSException
    {
        CoreCreditCardBatch corecreditcardbatch = (CoreCreditCardBatch)super.m_transaction;
        if(corecreditcardbatch.getTerminalId() != null)
            inputUrl.put("OapfTerminalId", corecreditcardbatch.getTerminalId());
        inputUrl.put("OapfMerchBatchId", corecreditcardbatch.getMerchBatchId());
        Integer integer = new Integer(super.m_ecAppId);
        String s = integer.toString();
        inputUrl.put("OapfECAppId", s);
        setPayeeInfo();
        mapVendorInfo();
        Log.debug("Before calling perform  ");
        TxnCustomizer txncustomizer = ExtUtils.loadCustomizer("ibyextend.TxnCustomizer_" + super.m_bepInfo.getSuffix());
        ExtUtils.customizePre(txncustomizer, super.m_bepInfo.getSuffix(), new AddOnlyHashtable(ht));
        Log.debug("OnlineCCPaymnt::handleBatch() Returning from customizePre()");
        HTMLPage htmlpage = creditCard.perform();
        ExtUtils.customizePost(txncustomizer, super.m_bepInfo.getSuffix(), new ReadOnlyHashtable(htmlpage.httpHeader()));
        Log.debug("OnlineCCPaymnt::handleBatch() Returning from customizePost()");
        Log.debug("After returning from close or querybatch in onlinecc ");
        Hashtable hashtable = htmlpage.httpHeader();
        String s1;
        String s2;
        for(Enumeration enumeration = hashtable.keys(); enumeration.hasMoreElements(); Log.debug(s1 + "   =  " + s2))
        {
            s1 = (String)enumeration.nextElement();
            s2 = (String)hashtable.get(s1);
        }

        CoreCreditCardCloseBatchResp corecreditcardclosebatchresp = new CoreCreditCardCloseBatchResp();
        PSResult psresult = new PSResult(corecreditcardclosebatchresp);
        String s3 = (String)htmlpage.httpHeader().get("OapfStatus");
        Log.debug("OnlineCreditCardPayment: OapfStatus: " + s3);
        if(CreditCardPayment.statusOK(s3) || s3.equals("0006"))
        {
            psresult.setStatus("0");
            handleBatchSuccess(corecreditcardclosebatchresp, htmlpage);
        } else
        {
            handleBEPError(psresult, htmlpage, s3);
        }
        Date date = null;
        if((String)htmlpage.httpHeader().get("OapfBatchDate") != null)
        {
            java.util.Date date1 = getTime((String)htmlpage.httpHeader().get("OapfBatchDate"));
            date = new Date(date1.getTime());
            corecreditcardclosebatchresp.setBatchDate(date);
        }
        int i = -1;
        if(htmlpage.httpHeader().containsKey("OapfNumTrxns"))
            i = Integer.parseInt((String)htmlpage.httpHeader().get("OapfNumTrxns"));
        Log.debug("Number of trxns is : " + i);
        if(i > 0)
        {
            int ai[] = new int[i];
            String as[] = new String[i];
            Date adate[] = new Date[i];
            int ai1[] = new int[i];
            String as1[] = new String[i];
            String as2[] = new String[i];
            String as3[] = new String[i];
            String as4[] = new String[i];
            Log.debug("position 0");
            for(int j = 0; j < i; j++)
            {
                if(htmlpage.httpHeader().containsKey("OapfTransactionId-" + j))
                    ai[j] = Integer.parseInt((String)htmlpage.httpHeader().get("OapfTransactionId-" + j));
                if(htmlpage.httpHeader().containsKey("OapfStatus-" + j))
                    ai1[j] = Integer.parseInt((String)htmlpage.httpHeader().get("OapfStatus-" + j));
                else
                if(htmlpage.httpHeader().containsKey("OapfTrxnStatus-" + j))
                    ai1[j] = Integer.parseInt((String)htmlpage.httpHeader().get("OapfTrxnStatus-" + j));
                Log.debug("position 1");
                if(htmlpage.httpHeader().containsKey("OapfNlsLang-" + j))
                    as4[j] = (String)htmlpage.httpHeader().get("OapfNlsLang-" + j);
                else
                    as4[j] = (String)htmlpage.httpHeader().get("OapfNlsLang");
                Log.debug("position 2");
                if(ai1[j] == 0)
                {
                    as[j] = (String)htmlpage.httpHeader().get("OapfTrxnType-" + j);
                    if((String)htmlpage.httpHeader().get("OapfTrxnDate-" + j) != null)
                    {
                        java.util.Date date2 = getTime((String)htmlpage.httpHeader().get("OapfTrxnDate-" + j));
                        adate[j] = new Date(date2.getTime());
                    } else
                    {
                        adate[j] = date;
                    }
                } else
                if(htmlpage.httpHeader().containsKey("OapfErrLocation-" + j))
                {
                    as1[j] = (String)htmlpage.httpHeader().get("OapfErrLocation-" + j);
                    as3[j] = (String)htmlpage.httpHeader().get("OapfVendErrmsg-" + j);
                    as2[j] = (String)htmlpage.httpHeader().get("OapfVendErrCode-" + j);
                }
            }

            Log.debug("position 3");
            corecreditcardclosebatchresp.setNumTrxns(i);
            corecreditcardclosebatchresp.setTID(ai);
            corecreditcardclosebatchresp.setTrxnType(as);
            corecreditcardclosebatchresp.setTrxnDate(adate);
            corecreditcardclosebatchresp.setBatchErrorCode(as2);
            corecreditcardclosebatchresp.setBatchErrorMessage(as3);
            corecreditcardclosebatchresp.setBatchNLSLang(as4);
            corecreditcardclosebatchresp.setBatchErrorLocation(as1);
            corecreditcardclosebatchresp.setBatchStatus(ai1);
        }
        return psresult;
    }

    private void handleBatchSuccess(CoreCreditCardCloseBatchResp corecreditcardclosebatchresp, HTMLPage htmlpage)
    {
        Log.debug("handleBatchSuccess: 01");
        String s = (String)htmlpage.httpHeader().get("OapfCreditAmount");
        if(s != null)
        {
            double d = Double.valueOf(s).doubleValue();
            corecreditcardclosebatchresp.setCreditAmount(d);
        }
        String s1 = (String)htmlpage.httpHeader().get("OapfSalesAmount");
        if(s1 != null)
        {
            double d1 = Double.valueOf(s1).doubleValue();
            corecreditcardclosebatchresp.setSalesAmount(d1);
        }
        String s2 = (String)htmlpage.httpHeader().get("OapfBatchTotal");
        if(s2 != null)
        {
            double d2 = Double.valueOf(s2).doubleValue();
            corecreditcardclosebatchresp.setBatchTotal(d2);
        }
        Log.debug("handleBatchSuccess: 02");
        corecreditcardclosebatchresp.setMerchBatchId((String)htmlpage.httpHeader().get("OapfMerchBatchId"));
        Log.debug("handleBatchSuccess: 03");
        corecreditcardclosebatchresp.setBatchState((String)htmlpage.httpHeader().get("OapfBatchState"));
        Log.debug("handleBatchSuccess: 04");
        Log.debug("handleBatchSuccess: 05");
        corecreditcardclosebatchresp.setPayeeId(inputUrl.get("OapfMerchantId"));
        corecreditcardclosebatchresp.setVPSBatchId((String)htmlpage.httpHeader().get("OapfVpsBatchID"));
        corecreditcardclosebatchresp.setGWBatchId((String)htmlpage.httpHeader().get("OapfGWBatchID"));
        corecreditcardclosebatchresp.setCurr((String)htmlpage.httpHeader().get("OapfCurr"));
    }

    public PSResult inquire()
        throws PSException
    {
        CoreCreditCardQry corecreditcardqry = (CoreCreditCardQry)super.m_transaction;
        mapInputUrl("oraqrytxstatus", "ORAPMTQRYTXSTATUS");
        setPayeeInfo();
        int i = corecreditcardqry.getTID();
        setTransactionId(i);
        mapVendorInfo();
        if(!corecreditcardqry.getHistory())
            inputUrl.put("OapfHistoryFlag", "no");
        TxnCustomizer txncustomizer = ExtUtils.loadCustomizer("ibyextend.TxnCustomizer_" + super.m_bepInfo.getSuffix());
        ExtUtils.customizePre(txncustomizer, super.m_bepInfo.getSuffix(), new AddOnlyHashtable(ht));
        Log.debug("OnlineCCPaymnt::inquire() Returning from customizePre()");
        HTMLPage htmlpage = creditCard.perform();
        ExtUtils.customizePost(txncustomizer, super.m_bepInfo.getSuffix(), new ReadOnlyHashtable(htmlpage.httpHeader()));
        Log.debug("OnlineCCPaymnt::inquire() Returning from customizePost()");
        PSResult psresult = processInquireResponse(htmlpage, i);
        return psresult;
    }

    private PSResult processInquireResponse(HTMLPage htmlpage, int i)
    {
        String s = (String)htmlpage.httpHeader().get("OapfNlsLang");
        InquireResp inquireresp = new InquireResp(s);
        PSResult psresult = new PSResult(inquireresp);
        String s1 = (String)htmlpage.httpHeader().get("OapfStatus");
        Log.debug("OnlineCreditCardPayment: OapfStatus: " + s1);
        if(!CreditCardPayment.statusOK(s1))
        {
            handleBEPError(psresult, htmlpage, s1);
        } else
        {
            psresult.setStatus("0");
            int j = Integer.parseInt((String)htmlpage.httpHeader().get("OapfNumTrxns"));
            Log.debug("numTrxns: " + j);
            for(int k = 0; k < j; k++)
            {
                String s2 = (String)htmlpage.httpHeader().get("OapfTrxnType-" + k);
                Log.debug("index: " + k + " trxntyp: " + s2);
                int l = Integer.parseInt((String)htmlpage.httpHeader().get("OapfTrxnType-" + k));
                Log.debug("trxnType: " + l);
                String s3 = (String)htmlpage.httpHeader().get("OapfStatus-" + k);
                Log.debug("currentOapfStatus: " + s3);
                InquireResult inquireresult = new InquireResult();
                switch(l)
                {
                case 2: // '\002'
                case 3: // '\003'
                    CoreCreditCardAuthResp corecreditcardauthresp = new CoreCreditCardAuthResp(s, i);
                    if(CreditCardPayment.statusOK(s3) || isOffline(s3))
                    {
                        handleAuthSuccessResponse(k, htmlpage, corecreditcardauthresp, inquireresult);
                        mapCommonFieldsforInquiry(k, htmlpage, corecreditcardauthresp, inquireresult);
                    } else
                    {
                        mapFailureResponse(k, htmlpage, corecreditcardauthresp, inquireresult);
                    }
                    inquireresp.addInquireResult(inquireresult);
                    break;

                case 8: // '\b'
                case 9: // '\t'
                    CoreCreditCardCapResp corecreditcardcapresp = new CoreCreditCardCapResp(s, i);
                    if(CreditCardPayment.statusOK(s3) || isOffline(s3))
                        mapCommonFieldsforInquiry(k, htmlpage, corecreditcardcapresp, inquireresult);
                    else
                        mapFailureResponse(k, htmlpage, corecreditcardcapresp, inquireresult);
                    inquireresp.addInquireResult(inquireresult);
                    break;

                case 5: // '\005'
                case 10: // '\n'
                    CoreCreditCardRetResp corecreditcardretresp = new CoreCreditCardRetResp(s, i);
                    if(CreditCardPayment.statusOK(s3) || isOffline(s3))
                        mapCommonFieldsforInquiry(k, htmlpage, corecreditcardretresp, inquireresult);
                    else
                        mapFailureResponse(k, htmlpage, corecreditcardretresp, inquireresult);
                    inquireresp.addInquireResult(inquireresult);
                    break;

                case 11: // '\013'
                    CoreCreditCardCreditResp corecreditcardcreditresp = new CoreCreditCardCreditResp(s, i);
                    if(CreditCardPayment.statusOK(s3) || isOffline(s3))
                        mapCommonFieldsforInquiry(k, htmlpage, corecreditcardcreditresp, inquireresult);
                    else
                        mapFailureResponse(k, htmlpage, corecreditcardcreditresp, inquireresult);
                    inquireresp.addInquireResult(inquireresult);
                    break;

                case 4: // '\004'
                case 7: // '\007'
                case 13: // '\r'
                case 14: // '\016'
                case 17: // '\021'
                case 18: // '\022'
                    CoreCreditCardVoidResp corecreditcardvoidresp = new CoreCreditCardVoidResp(s, i);
                    if(CreditCardPayment.statusOK(s3) || isOffline(s3))
                        mapCommonFieldsforInquiry(k, htmlpage, corecreditcardvoidresp, inquireresult);
                    else
                        mapFailureResponse(k, htmlpage, corecreditcardvoidresp, inquireresult);
                    inquireresp.addInquireResult(inquireresult);
                    break;

                case 6: // '\006'
                case 12: // '\f'
                case 15: // '\017'
                case 16: // '\020'
                default:
                    Log.debug("WARNING: Unexpected operation code: " + l + " returned from BEP in OnlineCreditCardPayment->" + "processInquireResponse, and is ignored");
                    break;
                }
            }

        }
        Log.debug("Just before returning from processInquire ");
        return psresult;
    }

    private void mapCommonFieldsforInquiry(int i, HTMLPage htmlpage, PmtResponse pmtresponse, InquireResult inquireresult)
    {
        Log.debug("enter->mapCommonFieldsforInquiry");
        String s = (String)htmlpage.httpHeader().get("OapfPmtInstrType-" + i);
        inquireresult.setPmtResponse(pmtresponse);
        if(htmlpage.httpHeader().containsKey("OapfStatus-" + i))
            inquireresult.setQryStatus(Integer.parseInt((String)htmlpage.httpHeader().get("OapfStatus-" + i)));
        Log.debug("position 1");
        if(htmlpage.httpHeader().containsKey("OapfPrice-" + i))
        {
            Double double1 = Double.valueOf((String)htmlpage.httpHeader().get("OapfPrice-" + i));
            inquireresult.setQryPrice(double1);
        }
        Log.debug("position 2");
        if(htmlpage.httpHeader().containsKey("OapfCurr-" + i))
            inquireresult.setQryCurr((String)htmlpage.httpHeader().get("OapfCurr-" + i));
        Log.debug("position 3");
        Log.debug("before getting utilDate");
        java.util.Date date = getTime((String)htmlpage.httpHeader().get("OapfTrxnDate-" + i));
        Log.debug("Obtained utilDate:" + date.getTime());
        Log.debug("Obtained utilDate:" + date);
        Date date1 = new Date(date.getTime());
        Log.debug("position 4");
        if(pmtresponse instanceof CoreCreditCardAuthResp)
        {
            CoreCreditCardAuthResp corecreditcardauthresp = (CoreCreditCardAuthResp)pmtresponse;
            if(htmlpage.httpHeader().containsKey("OapfRefcode-" + i))
                corecreditcardauthresp.setRefCode((String)htmlpage.httpHeader().get("OapfRefcode-" + i));
            if(htmlpage.httpHeader().containsKey("OapfTrxnType-" + i))
                corecreditcardauthresp.setTrxnType((String)htmlpage.httpHeader().get("OapfTrxnType-" + i));
            if(!bpsUtil.isTrivial(s))
                corecreditcardauthresp.setInstrType(s);
            corecreditcardauthresp.setTrxnDate(date1);
            return;
        }
        if(pmtresponse instanceof CoreCreditCardCapResp)
        {
            CoreCreditCardCapResp corecreditcardcapresp = (CoreCreditCardCapResp)pmtresponse;
            if(htmlpage.httpHeader().containsKey("OapfRefcode-" + i))
                corecreditcardcapresp.setRefCode((String)htmlpage.httpHeader().get("OapfRefcode-" + i));
            if(htmlpage.httpHeader().containsKey("OapfTrxnType-" + i))
                corecreditcardcapresp.setTrxnType((String)htmlpage.httpHeader().get("OapfTrxnType-" + i));
            if(!bpsUtil.isTrivial(s))
                corecreditcardcapresp.setInstrType(s);
            corecreditcardcapresp.setTrxnDate(date1);
            return;
        }
        if(pmtresponse instanceof CoreCreditCardRetResp)
        {
            CoreCreditCardRetResp corecreditcardretresp = (CoreCreditCardRetResp)pmtresponse;
            if(htmlpage.httpHeader().containsKey("OapfRefcode-" + i))
                corecreditcardretresp.setRefCode((String)htmlpage.httpHeader().get("OapfRefcode-" + i));
            if(htmlpage.httpHeader().containsKey("OapfTrxnType-" + i))
                corecreditcardretresp.setTrxnType((String)htmlpage.httpHeader().get("OapfTrxnType-" + i));
            if(!bpsUtil.isTrivial(s))
                corecreditcardretresp.setInstrType(s);
            corecreditcardretresp.setTrxnDate(date1);
            return;
        }
        if(pmtresponse instanceof CoreCreditCardCreditResp)
        {
            CoreCreditCardCreditResp corecreditcardcreditresp = (CoreCreditCardCreditResp)pmtresponse;
            if(htmlpage.httpHeader().containsKey("OapfRefcode-" + i))
                corecreditcardcreditresp.setRefCode((String)htmlpage.httpHeader().get("OapfRefcode-" + i));
            if(htmlpage.httpHeader().containsKey("OapfTrxnType-" + i))
                corecreditcardcreditresp.setTrxnType((String)htmlpage.httpHeader().get("OapfTrxnType-" + i));
            if(!bpsUtil.isTrivial(s))
                corecreditcardcreditresp.setInstrType(s);
            corecreditcardcreditresp.setTrxnDate(date1);
            return;
        }
        if(pmtresponse instanceof CoreCreditCardVoidResp)
        {
            CoreCreditCardVoidResp corecreditcardvoidresp = (CoreCreditCardVoidResp)pmtresponse;
            if(htmlpage.httpHeader().containsKey("OapfRefcode-" + i))
                corecreditcardvoidresp.setRefCode((String)htmlpage.httpHeader().get("OapfRefcode-" + i));
            if(htmlpage.httpHeader().containsKey("OapfTrxnType-" + i))
                corecreditcardvoidresp.setTrxnType((String)htmlpage.httpHeader().get("OapfTrxnType-" + i));
            if(!bpsUtil.isTrivial(s))
                corecreditcardvoidresp.setInstrType(s);
            corecreditcardvoidresp.setTrxnDate(date1);
            return;
        } else
        {
            return;
        }
    }

    private void mapFailureResponse(int i, HTMLPage htmlpage, PmtResponse pmtresponse, InquireResult inquireresult)
    {
        inquireresult.setPmtResponse(pmtresponse);
        if(htmlpage.httpHeader().containsKey("OapfErrLocation-" + i))
        {
            pmtresponse.setErrorLocation((String)htmlpage.httpHeader().get("OapfErrLocation-" + i));
            pmtresponse.setBEPErrorCode((String)htmlpage.httpHeader().get("OapfVendCode-" + i));
            pmtresponse.setBEPErrorMsg((String)htmlpage.httpHeader().get("OapfVendErrmsg-" + i));
        }
    }

    protected void mapInputUrl(String s, String s1)
    {
        inputUrl.put("OapfAction", s);
        inputUrl.put("OapfOrderId", super.m_tangible[0].getId());
        Integer integer = new Integer(super.m_ecAppId);
        inputUrl.put("OapfECAppId", integer.toString());
        inputUrl.put("OapfReqType", s1);
    }

    protected void putAddress()
    {
        if(((CreditCard)super.m_pmtInstr).getHolderAddress() != null)
        {
            Address address = ((CreditCard)super.m_pmtInstr).getHolderAddress();
            inputUrl.put("OapfCustName", ((CreditCard)super.m_pmtInstr).getHolderName());
            inputUrl.put("OapfAddr1", address.getStreet1());
            inputUrl.put("OapfAddr2", address.getStreet2());
            if(address.getStreet3() != null)
                inputUrl.put("OapfAddr3", address.getStreet3());
            inputUrl.put("OapfCity", address.getCity());
            inputUrl.put("OapfCnty", address.getCounty());
            inputUrl.put("OapfState", address.getState());
            inputUrl.put("OapfCntry", address.getCountry());
            inputUrl.put("OapfPostalCode", address.getPostalCode());
        }
    }

    protected void mapVendorInfo()
    {
        inputUrl.put("OapfVendorId", (new Integer(super.m_bepInfo.getId())).toString());
        inputUrl.put("OapfKey", super.m_bepInfo.getVendorKey());
        Log.debug("The url in onlinecreditcardpayment is  " + super.m_bepInfo.getUrl());
        inputUrl.put("OapfVendorUrl", super.m_bepInfo.getUrl());
        inputUrl.put("OapfVendorSuffix", super.m_bepInfo.getSuffix());
        inputUrl.put("OapfVPSUsername", super.m_bepInfo.getUserName());
        inputUrl.put("OapfVPSPassword", super.m_bepInfo.getPassword());
        inputUrl.put("OapfPmtType", super.m_bepInfo.getPaymentMethod());
        inputUrl.put("OapfStoreId", super.m_bepInfo.getVendorKey());
        if(super.m_bepInfo.getPaymentScheme().equals("SET"))
        {
            inputUrl.put("OapfSecurity", "2");
            inputUrl.put("OapfSetNoInit", "1");
        }
    }

    protected void setVoiceAuthInfo()
    {
        CoreCreditCardReq corecreditcardreq = (CoreCreditCardReq)super.m_transaction;
        if(corecreditcardreq.isVoiceAuth() && corecreditcardreq.getAuthCode() != null)
        {
            inputUrl.put("OapfAction", "oravoiceauth");
            inputUrl.put("OapfAuthCode", corecreditcardreq.getAuthCode());
        }
    }

    private static java.util.Date getTime(String s)
    {
        return CreditCardProcessor.getTime(s);
    }

    private boolean isOffline(String s)
    {
        return s.equals("11");
    }

    protected void putOptionalInfo()
    {
        CreditCard creditcard = (CreditCard)super.m_pmtInstr;
        if(creditcard.getCVV2Val() != null)
            inputUrl.put("OapfCVV2", creditcard.getCVV2Val());
    }

    public InputURL getInputURL()
    {
        return inputUrl;
    }

    public static final String RCS_ID = "$Header: OnlineCreditCardPayment.java 115.62 2003/05/01 20:12:10 jleybovi ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: OnlineCreditCardPayment.java 115.62 2003/05/01 20:12:10 jleybovi ship $", "oracle.apps.iby.payment");
    PaymentScheme creditCard;
    protected InputURL inputUrl;
    protected Hashtable ht;

}
