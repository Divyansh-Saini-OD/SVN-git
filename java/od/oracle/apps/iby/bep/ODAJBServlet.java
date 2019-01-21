package od.oracle.apps.iby.bep;

//  Importing the necessary java files

import AJBComm.CAFipayNetworkException;
import AJBComm.CAFipayTimeoutException;

import java.io.IOException;
import java.io.PrintWriter;

import java.lang.reflect.Method;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.sql.*;

import java.text.DateFormat;
import java.text.ParsePosition;
import java.text.SimpleDateFormat;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import oracle.apps.fnd.common.AppsContext;

import od.oracle.apps.iby.bep.struct.AJBResponseStruct;
import od.oracle.apps.iby.bep.struct.PurchCardAuthStruct;
import od.oracle.apps.iby.bep.AJBCommUtil;


/**
 * This Custom Servlet ODS acts like an interface between the Oracle iPayment
 * and AJB. When the ODS receives the authorization request from iPayment, it
 * formats the request into the AJB native format and requests that the AJB
 * perform an online authorization. When the AJB returns the authorization
 * result, then ODS will reformat the response into the iPayments native format.
 *
 * @author            FinTrack
 * @version           1.0   24-Sep-2007
 *                    1.1   26-Sep-2007
 *                    1.2   04-Oct-2007
 *                    1.3   05-Oct-2007
 *                    1.4   16-Oct-2007
 *                    1.5   01-Nov-2007
 *                    1.6   13-Nov-2007
 *                    1.7   14-Nov-2007 // changed the exception scenario for capture/return API
 *                    1.8   16-Nov-2007 // removed the unwanted comments
 *                    1.9   03-Dec-2007 // added the exception in sendAndReceive method
 *                    1.10  19-Dec-2007 // added the FailureMAP Exception method
 *                    1.11  11-Jan-2008 // added the condition part under the capture/return API
 *                    1.12  06-Feb-2008 // added the set Header value to the catch Exception block - defect 3431
 *                    1.13  07-Feb-2008 // changed the AJB exception format and remove the un-wanted comments - defect 3431
 *                    1.14  09-Apr-2008 // added *MOTO for field 31 - defect 5901
 *                    1.15  29-Apr-2008 // added the appscontext object inside the init() / replaced the string buffer insatiate of '+'
 *                    1.16  05-May-2008 // Defect #6580
 *                    1.17  04-Jun-2008 // comments return connection pool -- Capture/Return API
 *                    1.18  01-Jul-2008 // Defect #8476
 *                    1.19  13-Oct-2008 // Defect #11864 By Anitha.D
 *                    1.20  13-Apr-2010 // Defect #4586 Commented the Close Batch call
 *                    1.21  21-Jul-2010 // Defect #4180 Added PS2000 and RetCode to response for use in AMEX settlement
 *                                            (also required mod to CoreCreditCardAuthResp, AuthHandler, and OnlineCreditCardPayment to appear in ibyecapp servlet response)
 *                    1.30  29-OCT-2013 //Fixed avoiding a toupper on a null.
 **/
public class

ODAJBServlet extends HttpServlet {

    private static String sIP; //IP address of AJB
    private static int iPort; //Port of AJB
    private static String sDBCFile; //Path of DBC file
    private static String sDBCValue;

    // Required number of AJB Response parameters
    private static final int MAXSIZE = 100; // Defect 2549

    private AppsContext dbfAppsContext;
    private Connection oConn;

    // Stored procedure for getting the invoice from the DB
    private static String sInvoiceQuery =
        "BEGIN xx_iby_settlement_pkg.xx_ar_invoice_ods(?,?,?,?); END;"; // defect 5901 -- added the 3rd parameter
    // Stored procedure for CloseBatch
   //  Commented for Defect #4586
   /* private static String sCloseBatchQuery =
        "BEGIN XX_IBY_SETTLEMENT_PKG.PMTCLOSEDATA(?,?,?,?,?,?,?,?,?); END;";*/
    // Stored procedure for Capture and Return
    private static String sCaptureReturnQuery =
        "BEGIN XX_IBY_SETTLEMENT_PKG.PRE_CAPTURE_CCRETUNRN(?,?,?,?,?,?,?,?,?,?); END;";

    /**
     * servlet init start
     * @param config
     * @see #getDBCFilePath()
     * @exception ServletException
     **/
    public

    void init(ServletConfig config) throws ServletException {
        super.init(config);
        try {

            //  Getting the IP Address from the Apache Server zone.properties file
            sIP = config.getInitParameter("AJBServerIP");
            //  Getting the Port from the Apache Server zone.properties file
            iPort = Integer.parseInt(config.getInitParameter("AJBServerPort"));
            //  Getting the dbc File path from the Apache Server zone.properties file
            sDBCFile = config.getInitParameter("DBC_FILE_PATH");
            sDBCValue = getDBCFilePath();

            try {
                if (oConn == null) {
                    //  Calling the DB configuration
                    dbfAppsContext = new AppsContext(sDBCValue);
                }

            } catch (Exception oEx) {
                System.err.println("Exception occured in getting the DB configuration");
                throw new Exception("Error while getting the DB configuration :" +
                                    oEx.getMessage());
            }

        } catch (Exception oEx) {
            System.err.println("Error in init :" + oEx.getMessage());
            oEx.printStackTrace();
        }
    }

    /**
     * servlet doGet
     * @see #doPost(request, response)
     * @exception ServletException,IOException
     **/
    public

    void doGet(HttpServletRequest request,
               HttpServletResponse response) throws ServletException,
                                                    IOException {
        doPost(request, response);
    }

    /**
     * servlet doPost
     * @see #getIPayAuthPurchaseResponse(oAJBResponseStruct,oCommonAuth, oResponse)
     * @see #getIPaySuccessVoiceResponse(oRequest,oResponse)
     * @see #getIPayFailureVoiceResponse(oRequest,oResponse)
     * @see #getCloseBatchResponse()
     * @exception ServletException,IOException
     **/
    public

    void doPost(HttpServletRequest request,
                HttpServletResponse response) throws ServletException,
                                                     IOException {
        response.setContentType("text/html");
        PrintWriter printwriter = response.getWriter();

        // Initializing AJBResponseStruct Object PurchCardAuthStruct Objects
        AJBResponseStruct oAJBResponseStruct = null;
        oAJBResponseStruct = new AJBResponseStruct();

        PurchCardAuthStruct oCommonAuth = null;
        oCommonAuth = new PurchCardAuthStruct();

        HashMap responseHashMap = null;
        responseHashMap = new HashMap();
        String sCommCard = null;

        HttpServletRequest oRequest = null;
        oRequest = request;

        HttpServletResponse oResponse = null;
        oResponse = response;


        //  Getting parameter values from IPayment and setting them into
        //  PurchCardAuthStruct object

        oCommonAuth.setAction(request.getParameter("OapfAction"));
        oCommonAuth.setOrderId(request.getParameter("OapfOrderId"));
        oCommonAuth.setAuthcode(request.getParameter("OapfAuthCode"));
        oCommonAuth.setPrice(request.getParameter("OapfPrice"));
        oCommonAuth.setCurrency(request.getParameter("OapfCurr"));
        oCommonAuth.setAuthType(request.getParameter("OapfAuthType"));
        oCommonAuth.setPmtInstrID(request.getParameter("OapfPmtInstrID"));
        oCommonAuth.setPmtInstrExp(request.getParameter("OapfPmtInstrExp"));
        oCommonAuth.setStoreId(request.getParameter("OapfStoreId"));
        oCommonAuth.setCustName(request.getParameter("OapfCustName"));
        oCommonAuth.setAddr1(request.getParameter("OapfAddr1"));
        oCommonAuth.setAddr2(request.getParameter("OapfAddr2"));
        oCommonAuth.setAddr3(request.getParameter("OapfAddr3"));
        oCommonAuth.setCity(request.getParameter("OapfCity"));
        oCommonAuth.setState(request.getParameter("OapfState"));
        oCommonAuth.setCountry(request.getParameter("OapfCntry"));
        oCommonAuth.setPostalCode(request.getParameter("OapfPostalCode"));
        oCommonAuth.setPhone(request.getParameter("OapfPhone"));
        oCommonAuth.setEmail(request.getParameter("OapfEmail"));
        oCommonAuth.setRetry(request.getParameter("OapfRetry"));
        oCommonAuth.setNlsLang(request.getParameter("OapfNlsLang"));


        // Checking for Purchase or Normal Authorization
        if ("oraauth".equals(request.getParameter("OapfAction"))) {
            printwriter.println(" Auth API ");

            try {

                sCommCard = request.getParameter("OapfCommCard");
                printwriter.println(" Commcard value :" + sCommCard);

                if (sCommCard != null) {
                    //  Checking for Purchasecard CommCard Value - U or P or B or C or F or G
                    if (sCommCard.equals("U") || sCommCard.equals("P") || sCommCard.equals("B") ||
                        sCommCard.equals("C") || sCommCard.equals("F") || sCommCard.equals("G")) {

                        printwriter.println(" Purchase Auth API ");

                        //  Getting additional parameter values from IPayment
                        //  and setting them into PurchCardAuthStruct object

                        oCommonAuth.setCommCard(request.getParameter("OapfCommCard"));
                        oCommonAuth.setPONum(request.getParameter("OapfPONum"));
                        oCommonAuth.setTaxAmount(request.getParameter("OapfTaxAmount"));
                        oCommonAuth.setShipToZip(request.getParameter("OapfShipToZip"));
                        oCommonAuth.setShipFromZip(request.getParameter("OapfShipFromZip"));

                        //  Calling the ODSServlet response method
                        getIPayAuthPurchaseResponse(oAJBResponseStruct,
                                                    oCommonAuth, oResponse);

                    }
                    else {
                        System.err.println(" ERROR: Unexpected CommCard type value: " + sCommCard + ". Exiting the servlet");
                        getFailureException("ERROR: Unexpected CommCard type value: " + sCommCard, oCommonAuth, oResponse);
                    }
                } else {
                    // Normal Authorization
                    printwriter.println(" Normal Auth API ");
                    // Calling the ODSServlet response method
                    getIPayAuthPurchaseResponse(oAJBResponseStruct,
                                                oCommonAuth, oResponse);

                }
            } catch (Exception oEx) {
                printwriter.println("Exception occured in Purchase or Normal Auth API "); //writes to iby.log
                System.err.println("Exception occured in Purchase or Normal Auth API "); //writes to error.log
                getFailureException("Exception occured in Purchase or Normal Auth API :" +
                                    oEx.getMessage(), oCommonAuth, oResponse);
                return;
            }
        }
        //  Checking for Voice Authorization
        else if ("oravoiceauth".equals(request.getParameter("OapfAction"))) {
            printwriter.println(" Voice Auth API");

            try {
                //  Calling the ODSServlet voice success response method
                responseHashMap.clear();
                responseHashMap =
                        getIPaySuccessVoiceResponse(oRequest, oResponse);
                printwriter.println("response voice value :" +
                                    responseHashMap);

                // Setting the Header for IPayment
                response.setHeader("OapfOrderId",
                                   (String)responseHashMap.get("OapfOrderId"));
                response.setHeader("OapfTrxnType", "2");
                response.setHeader("OapfStatus", "0000");
                response.setHeader("OapfAuthcode",
                                   (String)responseHashMap.get("OapfAuthCode"));
                response.setHeader("OapfTrxnDate",
                                   getDateTime()); //   Date format 'YYYYMMddHHmmss'
                response.setHeader("OapfPmtInstrType", "");
                response.setHeader("OapfErrLocation", "0");
                response.setHeader("OapfVendErrCode", "");
                response.setHeader("OapfVendErrmsg", "");
                response.setHeader("OapfAcquirer", "");
                response.setHeader("OapfRefcode", "");
                response.setHeader("OapfAVScode", "");
                response.setHeader("OapfAuxMsg", "");
                response.setHeader("OapfNlsLang",
                                   (String)responseHashMap.get("OapfNlsLang"));
            } catch (Exception oEx) {

                printwriter.println(" Exception occured in Voice Auth API ");
                System.err.println(" Exception occured in Voice Auth API ");

                //  Calling the ODSServlet voice Failure response method
                responseHashMap.clear();
                responseHashMap =
                        getIPayFailureVoiceResponse(oRequest, oResponse);
                printwriter.println("voice failure response value :" +
                                    responseHashMap);

                // Setting the Header for IPayment
                response.setHeader("OapfOrderId",
                                   (String)responseHashMap.get("OapfOrderId"));
                response.setHeader("OapfTrxnType", "2");
                response.setHeader("OapfStatus", "0005");
                response.setHeader("OapfAuthcode",
                                   (String)responseHashMap.get("OapfAuthCode"));
                response.setHeader("OapfTrxnDate",
                                   getDateTime()); //  Date format 'YYYYMMddHHmmss'
                response.setHeader("OapfPmtInstrType", "");
                response.setHeader("OapfErrLocation", "3");
                response.setHeader("OapfVendErrCode", "2");
                response.setHeader("OapfVendErrmsg", "Referral");
                response.setHeader("OapfAcquirer", "");
                response.setHeader("OapfRefcode", "");
                response.setHeader("OapfAVScode", "");
                response.setHeader("OapfAuxMsg", "");
                response.setHeader("OapfNlsLang",
                                   (String)responseHashMap.get("OapfNlsLang"));
                return;
            }
        }

        //  Checking for Capture
        else if ("oracapture".equals(request.getParameter("OapfAction"))) {

            printwriter.println(" Capture API ");
            HashMap oCaptureResponseMap = new HashMap();
            String sErrorMsgValue = null;
            String sRetCodeValue = null;
            String sReceiptRefValue = null;

            try {

                //  Calling the DB stored procedure
                oCaptureResponseMap =
                        getCaptureReturnResponse(oCommonAuth, oRequest,
                                                 oResponse);

                sRetCodeValue = (String)oCaptureResponseMap.get("RetCode");
                sReceiptRefValue =
                        (String)oCaptureResponseMap.get("ReceiptRef");

                if (sRetCodeValue.equals("0")) {
                    // Setting the Header for IPayment -- Success
                    printwriter.println(" Success - Capture API");
                    response.setHeader("OapfStatus", "0000");
                    response.setHeader("OapfTrxnType", "8");
                    response.setHeader("OapfTrxnDate", getSysDate());
                    printwriter.println(" successfully set the Header");
                } else if (sRetCodeValue.equals("1")) {
                    // Setting the Header for IPayment -- Failure
                    printwriter.println(" Failure - Capture API ");
                    response.setHeader("OapfStatus", "0005");
                    response.setHeader("OapfTrxnType",
                                       "8"); // Changed as per the mail 27-Nov-2007
                    response.setHeader("OapfTrxnDate", getSysDate());
                    response.setHeader("OapfErrLocation", "1");
                    response.setHeader("OapfVendErrCode", "1");

                    // Checking the ErrorMsg parameter value for null
                    if ((String)oCaptureResponseMap.get("ErrorMsg") !=
                        null) { // Added the if-else condition - validation for Error msg
                        sErrorMsgValue =
                                (String)oCaptureResponseMap.get("ErrorMsg");
                        response.setHeader("OapfVendErrmsg", sErrorMsgValue);
                    } else {
                        response.setHeader("OapfVendErrmsg", "");
                    }
                    printwriter.println(" successfully set the Header");
                } else {
                    sErrorMsgValue =
                            (String)oCaptureResponseMap.get("ErrorMsg");
                    // Setting the Header for IPayment -- Exception
                    printwriter.println(" Exception - Capture API ");
                    getCaptureException(sErrorMsgValue, oResponse,
                                        oCommonAuth);
                }

            } catch (Exception oEx) {
                printwriter.println("Exception occured in Capture API");
                System.err.println("Exception occured in Capture API");
                sErrorMsgValue = oEx.getMessage();
                getCaptureException(sErrorMsgValue, oResponse, oCommonAuth);
                return;
            }

        }
        //  Checking for Return
        else if ("orareturn".equals(request.getParameter("OapfAction"))) {

            printwriter.println(" Return API ");
            HashMap oReturnResponseMap = new HashMap();
            String sErrorMsgValue = null;
            String sRetCodeValue = null;
            String sReceiptRefValue = null;

            try {
                //  Calling the DB stored procedure
                oReturnResponseMap =
                        getCaptureReturnResponse(oCommonAuth, oRequest,
                                                 oResponse);
                sRetCodeValue = (String)oReturnResponseMap.get("RetCode");

                if (sRetCodeValue.equals("0")) {
                    // Setting the Header for IPayment -- Success
                    printwriter.println(" Success - Return API ");
                    response.setHeader("OapfStatus", "0000");
                    response.setHeader("OapfTrxnType",
                                       "5"); // Changed as per the mail 27-Nov-2007
                    response.setHeader("OapfTrxnDate", getSysDate());

                    // Checking the refcode parameter value for null
                    if ((String)oReturnResponseMap.get("ReceiptRef") !=
                        null) { // Added the if-else condition - validation for Receipt Ref
                        sReceiptRefValue =
                                (String)oReturnResponseMap.get("ReceiptRef");
                        response.setHeader("OapfRefcode", sReceiptRefValue);
                    } else {
                        response.setHeader("OapfRefcode", "");
                    }
                    printwriter.println(" successfully set the Header");
                } else if (sRetCodeValue.equals("1")) {
                    // Setting the Header for IPayment -- Failure
                    printwriter.println(" Failure - Return API ");
                    response.setHeader("OapfStatus", "0005");
                    response.setHeader("OapfTrxnType", "5");
                    response.setHeader("OapfTrxnDate", getSysDate());
                    response.setHeader("OapfErrLocation", "1");
                    response.setHeader("OapfVendErrCode", "2");

                    // Checking the ErrorMsg parameter value for null
                    if ((String)oReturnResponseMap.get("ErrorMsg") !=
                        null) { // Added the if-else condition - validation for Error msg
                        sErrorMsgValue =
                                (String)oReturnResponseMap.get("ErrorMsg");
                        response.setHeader("OapfVendErrmsg", sErrorMsgValue);
                    } else {
                        response.setHeader("OapfVendErrmsg", "");
                    }
                    printwriter.println(" successfully set the Header");
                } else {
                    sErrorMsgValue =
                            (String)oReturnResponseMap.get("ErrorMsg");
                    // Setting the Header for IPayment -- Exception
                    printwriter.println("Exception - Return API");
                    getReturnException(sErrorMsgValue, oResponse, oCommonAuth);
                }

            } catch (Exception oEx) {
                printwriter.println("Exception occured in Return API");
                System.err.println("Exception occured in Return API");
                sErrorMsgValue = oEx.getMessage();
                getReturnException(sErrorMsgValue, oResponse, oCommonAuth);
                return;
            }

        }
   //  Commented for Defect #4586 -- Starting
        // Checking for CloseBatch
    /*    else if ("oraPmtCloseBatch".equals(request.getParameter("OapfAction"))) {

            HashMap oCloseResponseMap = new HashMap();

            String sCloseBatchDate = null;
            String sCloseBatchCreditAmt = null;
            String sCloseBatchSalesAmt = null;
            String sCloseBatchTotal = null;
            String sCloseBatchCurr = null;
            String sCloseBatchNumTrxns = null;
            String sCloseBatchStoreId = null;
            String sCloseBatchVpsBatchId = null;
            String sCloseBatchGWBatchId = null;
            String sCloseBatchState = null;
            StringBuffer sCloseBuffer = new StringBuffer();
            String sCloseBatchFormat = null;

            try {
                //  Calling the DB stored procedure
                oCloseResponseMap = getCloseBatchResponse();

                sCloseBatchDate = (String)oCloseResponseMap.get("IbyDate");
                sCloseBatchCreditAmt =
                        (String)oCloseResponseMap.get("CreditAmt");
                sCloseBatchSalesAmt =
                        (String)oCloseResponseMap.get("SalesAmt");
                sCloseBatchTotal = (String)oCloseResponseMap.get("BatchTotal");
                sCloseBatchCurr = (String)oCloseResponseMap.get("BatchCurr");
                sCloseBatchNumTrxns =
                        (String)oCloseResponseMap.get("NumTrxns");
                sCloseBatchStoreId = oCommonAuth.getStoreId();
                sCloseBatchVpsBatchId =
                        (String)oCloseResponseMap.get("VpsBatchId");
                sCloseBatchGWBatchId =
                        (String)oCloseResponseMap.get("GWBatchId");
                sCloseBatchState = (String)oCloseResponseMap.get("State");

                response.setHeader("OapfStatus", "0000");
                response.setHeader("OapfBatchDate", sCloseBatchDate);
                response.setHeader("OapfCreditAmount", sCloseBatchCreditAmt);
                response.setHeader("OapfSalesAmount", sCloseBatchSalesAmt);
                response.setHeader("OapfBatchTotal", sCloseBatchTotal);
                response.setHeader("OapfCurr", sCloseBatchCurr);
                response.setHeader("OapfNumTrxns", sCloseBatchNumTrxns);
                response.setHeader("OapfStoreID", sCloseBatchStoreId);
                response.setHeader("OapfVpsBatchID", sCloseBatchVpsBatchId);
                response.setHeader("OapfGWBatchID", sCloseBatchGWBatchId);
                response.setHeader("OapfBatchState", sCloseBatchState);

                sCloseBuffer.append("<H2>Results</H2><BR>OapfStatus: 0000"); // replaced the string buffer insatiate of '+'
                sCloseBuffer.append("<BR>OapfBatchDate: ").append(sCloseBatchDate);
                sCloseBuffer.append("<BR>OapfCreditAmount: ").append(sCloseBatchCreditAmt);
                sCloseBuffer.append("<BR>OapfSalesAmount: ").append(sCloseBatchSalesAmt);
                sCloseBuffer.append("<BR>OapfBatchTotal: ").append(sCloseBatchTotal);
                sCloseBuffer.append("<BR>OapfCurr: ").append(sCloseBatchCurr);
                sCloseBuffer.append("<BR>OapfNumTrxns: ").append(sCloseBatchNumTrxns);
                sCloseBuffer.append("<BR>OapfStoreID: ").append(sCloseBatchStoreId);
                sCloseBuffer.append("<BR>OapfVpsBatchID: ").append(sCloseBatchVpsBatchId);
                sCloseBuffer.append("<BR>OapfGWBatchID: ").append(sCloseBatchGWBatchId);
                sCloseBuffer.append("<BR>OapfBatchState: ").append(sCloseBatchState);
                sCloseBuffer.append("<BR>");

                sCloseBatchFormat = sCloseBuffer.toString();
                printwriter.println(sCloseBatchFormat);

                /*
                printwriter.println("<H2>Results</H2><BR>OapfStatus: 0000" +
                                    "<BR>OapfBatchDate: " + sCloseBatchDate +
                                    "<BR>OapfCreditAmount: " +
                                    sCloseBatchCreditAmt +
                                    "<BR>OapfSalesAmount: " +
                                    sCloseBatchSalesAmt +
                                    "<BR>OapfBatchTotal: " + sCloseBatchTotal +
                                    "<BR>OapfCurr: " + sCloseBatchCurr +
                                    "<BR>OapfNumTrxns: " +
                                    sCloseBatchNumTrxns + "<BR>OapfStoreID: " +
                                    sCloseBatchStoreId +
                                    "<BR>OapfVpsBatchID: " +
                                    sCloseBatchVpsBatchId +
                                    "<BR>OapfGWBatchID: " +
                                    sCloseBatchGWBatchId +
                                    "<BR>OapfBatchState: " + sCloseBatchState +
                                    "<BR>");
            } catch (Exception oEx) {
                System.err.println("Exception occured in CloseBatch API");
                getDBCloseBatchException("Exception occured in CloseBatch API :" + oEx.getMessage(), oCommonAuth,
                                         oResponse);
                return;
            }
        }*/
   //  Commented for Defect #4586 -- Ending
    } // dopost


    /**
     * This method is getting the response from AJB and checking the success or
     * failure
     * @see #getAJBAuthRequestString(oCommonAuth,oResponse)
     * @see #getIPayResponse(oAJBResponseStruct, oCommonAuth,oResponse)
     * @see #getFailureMAPException(sAJBError,oCommonAuth,oResponse)
     * @return HashMap
     * @Exception Exception
     **/
    private

    HashMap getAuthResponse(AJBResponseStruct oAJBResponseStruct,
                            PurchCardAuthStruct oCommonAuth,
                            HttpServletResponse oResponse) throws Exception {

        PrintWriter printwriter = oResponse.getWriter();

        // Initializing the AJBCommUtil Object
        AJBCommUtil oComm = null;
        HashMap oAuthResponseMap = new HashMap();

        String sResponseStr = "";
        String sRequestStr = "";
        String sRequest = "";
        String sAJBError = "";

        try {

            try {

                printwriter.println(" Forming the Request String ");
                //  Building the AJB request string
                sRequestStr = getAJBAuthRequestString(oCommonAuth, oResponse);
                printwriter.println(" After forming the AJB Request string " +
                                    getAuthAccountValue(sRequestStr));


            } catch (Exception oEx) {
                System.err.println("Exception occured in parsing the AJB Response string");
                printwriter.println("Error message :" + oEx.getMessage());
                sAJBError = oEx.getMessage();
                throw new Exception("Exception occured in parsing the AJB Response string :" +
                                    oEx.getMessage());
            }

            try {

                // Calling the AJB Interface
                oComm =
                        new AJBCommUtil(getAJBServerIP(), getAJBServerPort(), sRequestStr,
                                        oResponse);

                // Getting response from AJB
                 sResponseStr = oComm.sendAndReceive();
                printwriter.println("Response from AJB =>" + getAuthAccountValue(sResponseStr));


            } catch (CAFipayTimeoutException toExc) {
                System.out.println("Timeout Exception :" + toExc.errorCode +
                                   " " + toExc.errorDesc);
                printwriter.println("Timeout Exception :" + toExc.errorCode +
                                    " " + toExc.errorDesc);
                sAJBError =
                        toExc.errorCode + ":" + toExc.errorDesc; // 1.13  07-Feb-2008
                throw new Exception("CAFIpay Timedout Exception :" +
                                    toExc.getMessage());

            } catch (CAFipayNetworkException netExc) {
                System.out.println("Network Exception :" + netExc.errorCode +
                                   " " + netExc.errorDesc);
                printwriter.println("Network Exception :" + netExc.errorCode +
                                    " " + netExc.errorDesc);
                sAJBError =
                        netExc.errorCode + ":" + netExc.errorDesc; // 1.13  07-Feb-2008
                throw new Exception("CAFIpay Network Exception :" +
                                    netExc.getMessage());
            } catch (Exception oEx) {
                printwriter.println("Error message :" + oEx.getMessage());
                sAJBError = oEx.getMessage();
                throw new Exception("CAFIpay Exception :" + oEx.getMessage());
            }

            try {
                // Parsing the AJB Response string
                parseAJBResponse(sResponseStr, oAJBResponseStruct, oCommonAuth,
                                 oResponse);
            } catch (Exception oEx) {
                printwriter.println(" Exception occured in Parsing the AJB Response ");
                System.err.println("  Exception occured in Parsing the AJB Response ");
                throw new Exception(oEx.getMessage());
            }

            try {
                // Checking the success or failure message from AJB
                oAuthResponseMap.clear();
                oAuthResponseMap =
                        getIPayResponse(oAJBResponseStruct, oCommonAuth,
                                        oResponse);
            } catch (Exception oEx) {
                printwriter.println(" Exception occured in get ipay response ");
                System.err.println("  Exception occured in get ipay response ");
                throw new Exception(oEx.getMessage());
            }

        } catch (Exception oEx) {
            printwriter.println(" Exception - No Response from AJB ");
            System.err.println(" Exception - No Response from AJB ");
            printwriter.println(" Getting Error from AJB : " + sAJBError);

            oAuthResponseMap.clear();
            // Calling the ODSServlet Failure/Exception response for IPayment
            oAuthResponseMap =
                    getFailureMAPException(sAJBError, oCommonAuth, oResponse); // Defect 2939
        }
        return oAuthResponseMap;
    }

    // Added for the Defect 11864 -- Starting
    private String getAuthAccountValue(String sAuthAccountId) throws Exception{
        String number = sAuthAccountId;
        String leftString = "";
        String RightString = "";
        String finalrequestString = "";
        try
        {
        for(int x=0;x<12;x++)
        {
            leftString = leftString + number.substring(0,number.indexOf(",")+1);
            number = number.substring(number.indexOf(",")+1);
        }
        number=number.substring(0,number.indexOf(","));
        RightString = sAuthAccountId.substring(sAuthAccountId.indexOf(number)+number.length(),sAuthAccountId.length());
        int len1 = number.length();
        String ccnumber = number.substring(0,4)+"********"+number.substring((len1 - 4),len1);
        finalrequestString = leftString+ccnumber+RightString;
        }
        catch (Exception oEx) {
             throw new Exception("Exception occured in forming the masked value in Servlet :" +
                                    oEx.getMessage());
        }
        return finalrequestString;
}
    // Added for the Defect 11864 -- Ending

    /**
     * This method is forming the Request string for AJB
     * @see #processInvoice(oCommonAuth, oResponse)
     * @see #getSysDate()
     * @see #getSysTime()
     * @return String
     * @Exception Exception
     **/
    private

    String getAJBAuthRequestString(PurchCardAuthStruct oCommonAuth,
                                   HttpServletResponse oResponse) throws Exception {

        String sInvoice = null;
        String sData = null;
        String sTokenEnabled = null;
        String sAJBRequestString = null;
        String sOrderId = oCommonAuth.getOrderId();

        StringBuffer oStringBuffer = new StringBuffer();
        PrintWriter printwriter = oResponse.getWriter();
        printwriter.println(" Executing method - getAJBAuthRequestString ");
        HashMap oProcessInvoiceMap = new HashMap(); // defect 5901

        try {

            if(!sOrderId.equals("ARI")) {
            // Getting the Invoice number from DB
            oProcessInvoiceMap.clear(); // defect 5901
            oProcessInvoiceMap =
                    processInvoice(oCommonAuth, oResponse); // defect 5901
            sInvoice =
                    (String)oProcessInvoiceMap.get("InvoiceValueOut"); // defect 5901
            sData = (String)oProcessInvoiceMap.get("DataOut"); // defect 5901
            sTokenEnabled = (String)oProcessInvoiceMap.get("TokenEnabled");
		    }

            printwriter.println(" Invoice number :" + sInvoice);
            printwriter.println(" Data value :" + sData);

            oStringBuffer.append("100,"); // Transaction Type
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(","); // Actioncode
            oStringBuffer.append("20,"); //  Timeout
            oStringBuffer.append("Credit,"); //  Debit Credit
            oStringBuffer.append(",");
            oStringBuffer.append(oCommonAuth.getStoreId() +
                                 ","); // Store Number
            oStringBuffer.append(oCommonAuth.getTerminalValue() +
                                 ","); // Terminal Number

            if (!sOrderId.equals("ARI")) {
               oStringBuffer.append("Sale,"); // TranType
		    } else {
				oStringBuffer.append("GetToken,"); // TranType
			}

            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(oCommonAuth.getPmtInstrID() +
                                 ","); //  AccountId
            oStringBuffer.append(oCommonAuth.formatDate() + ","); //  Exp Date
            oStringBuffer.append(","); //  Swipe
            oStringBuffer.append(oCommonAuth.getPriceValue() + ",");
            oStringBuffer.append(sInvoice + ","); //  Invoice
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(","); //  20th column
            
            if (sOrderId.equals("ARI")) {
                oStringBuffer.append("*Tokenization *LVT *forcebankfamily MPSCRD,"); // Amex - Added *forcebankfamily Added LVT
                                       }
            else if (sTokenEnabled != null && sTokenEnabled.equals("Y")) {
                oStringBuffer.append("*Tokenization *forcebankfamily MPSCRD,"); // Amex - Added *forcebankfamily Added LVT
                                                                         }
            else {
                            oStringBuffer.append(",");
                 }
            
            //  IxOption
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(","); // 30th column
            //oStringBuffer.append(","); // 31st column
            oStringBuffer.append(sData +
                                 ","); // 31st column added *MOTO for field 31 - defect 5901
            oStringBuffer.append(",");
            /*  LVT changes - Field 33 will always have instrument id
			
			if (!sOrderId.equals("ARI") && (sTokenEnabled != null && sTokenEnabled.equals("Y"))) {

            if (!sOrderId.equals("ARI") && (sTokenEnabled != null && sTokenEnabled.equals("Y"))) {
			   oStringBuffer.append(oCommonAuth.getPmtInstrID() + ","); //  Token
		    } else {
			   oStringBuffer.append(",");
            }
			*/
			oStringBuffer.append(oCommonAuth.getPmtInstrID() + ","); // LVT
            oStringBuffer.append(oCommonAuth.getOrderId() +
                                 ","); // tangible id
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(","); // AuthCode
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(","); // 40th column
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(getSysDate() + ","); //  SysDate
            oStringBuffer.append(getSysTime() + ","); //   SysTime
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(","); // 60th column
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(","); // 70th column
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(","); // 80th column
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(",");
            oStringBuffer.append(","); // 87th column

        } catch (Exception oEx) {
            printwriter.println(" Exception occured in forming the Request string for AJB");
            System.err.println(" Exception occured in forming the Request string for AJB");
            throw oEx;
        }

        sAJBRequestString = oStringBuffer.toString();
        return sAJBRequestString;
    }

   /**
     * getSysDate
     * @return String
     * @exception
     **/
    private

    String getSysDate() {

        DateFormat dateFormat = new SimpleDateFormat("MMddyyyy");
        Date date = new Date();
        return dateFormat.format(date);
    }

    /**
     * getSysTime
     * @return String
     * @exception
     **/
    private

    String getSysTime() {

        DateFormat dateFormat = new SimpleDateFormat("HHmmss");
        Date date = new Date();
        return dateFormat.format(date);
    }

    /**
     * getAJBServerIP
     * @return String
     * @exception
     **/
    private static

    String getAJBServerIP() {
        return sIP;
    }

    /**
     * getAJBServerPort
     * @return String
     * @exception
     **/
    private static

    int getAJBServerPort() {
        return iPort;
    }

    /**
     * getDBCFilePath
     * @return String
     * @exception
     **/
    private static

    String getDBCFilePath() {
        return sDBCFile;
    }

    /**
     * getIPayResponse
     * @see #getResAuxMsg(oAJBResponseStruct, oResponse)
     * @see #getAJBAction(Actioncode, oAJBResponseStruct,oResponse)
     * @return HashMap
     * @exception Exception
     **/
    private

    HashMap getIPayResponse(AJBResponseStruct oAJBResponseStruct,
                            PurchCardAuthStruct oCommonAuth,
                            HttpServletResponse oResponse) throws Exception {

        PrintWriter printwriter = oResponse.getWriter();
        HashMap oIPayResponseMap = new HashMap();
        String sPriceValue = null;
        String sTrxnDate = null;
        String sTrxnDateTime = null;
        String sVendErrMsg = null;
        String sAuxMsgValue = null;
        String sRefCodeValue = null;
        String sAuthCodeValue = null;
        String sCardType = null; // Defect 2549

        try {
            printwriter.println(" method - getIPayResponse()");

            sPriceValue = oCommonAuth.getPriceValue();
            printwriter.println(" Request Amount  :" + sPriceValue);
            printwriter.println(" Response Amount  :" +
                                oAJBResponseStruct.getIxAmount());

            sAuxMsgValue = getResAuxMsg(oAJBResponseStruct, oResponse);
            sVendErrMsg =
                    getAJBAction(oAJBResponseStruct.getIxActionCode(), oAJBResponseStruct,
                                 oResponse);
            sTrxnDate =
                    convertDateFormat(oAJBResponseStruct.getIxDate(), "mmddyyyy",
                                      "yyyymmdd");
            sTrxnDateTime = sTrxnDate + oAJBResponseStruct.getIxTime();
            sAuthCodeValue = oAJBResponseStruct.getIxAuthCode();
            sCardType = oAJBResponseStruct.getIxCardType(); // Defect 2549
            if (sCardType != null && !sCardType.equals(""))
            {
              sCardType = sCardType.toUpperCase(); // Defect #8476
            }

            // Checking for AJB success responses
            if ((oAJBResponseStruct.getIxActionCode().equals("0")) &&
                (sPriceValue.equals(oAJBResponseStruct.getIxAmount()))) {

                printwriter.println(" success IPAY Response ");

                printwriter.println("inside success AuthCode - AJB :" +
                                    oAJBResponseStruct.getIxAuthCode());
                printwriter.println("inside success - Authcode value :" +
                                    sAuthCodeValue);
                printwriter.println("inside success Vend Errmsg :" +
                                    sVendErrMsg);
                printwriter.println("inside success Receipt number : " +
                                    oAJBResponseStruct.getIxReceiptDisplay());
                printwriter.println("inside success store number : " +
                                    oAJBResponseStruct.getIxStoreNumber());
                printwriter.println("inside success Aux Message : " +
                                    sAuxMsgValue);
                printwriter.println("inside success oAJBResponseStruct.getPmtInstrType() : " +
                                    sCardType); // Defect 2549
                printwriter.println("inside success oAJBResponseStruct.getIxActionCode() : " +
                                    oAJBResponseStruct.getIxActionCode());
                printwriter.println("inside success sVendErrMsg : " +
                                    sVendErrMsg);
                printwriter.println("inside success oAJBResponseStruct.getIxBankNodeID() : " +
                                    oAJBResponseStruct.getIxBankNodeID());
                printwriter.println("inside success oCommonAuth.getNlsLang() : " +
                                    oCommonAuth.getNlsLang());
                printwriter.println("inside success OapfRefCode : " +
                                    oAJBResponseStruct.getIxRefNumber());
                printwriter.println("inside success OapfTrxnDateTime : " +
                                    sTrxnDateTime);

                try {

                    oIPayResponseMap.clear();
                    printwriter.println(" before setting to hashmap :" +
                                        oIPayResponseMap);

                    oIPayResponseMap.put("OapfOrderId",
                                         oCommonAuth.getOrderId());
                    oIPayResponseMap.put("OapfStatus", "0000");
                    oIPayResponseMap.put("OapfAuthCode", sAuthCodeValue);
                    oIPayResponseMap.put("OapfTrxnDate", sTrxnDateTime);
                    oIPayResponseMap.put("OapfErrLocation", "0");
                    oIPayResponseMap.put("OapfVendErrCode",
                                         oAJBResponseStruct.getIxActionCode());
                    oIPayResponseMap.put("OapfVendErrmsg", sVendErrMsg);
                    oIPayResponseMap.put("OapfAcquirer",
                                         oAJBResponseStruct.getIxBankNodeID());
                    oIPayResponseMap.put("OapfRefCode",
                                         oAJBResponseStruct.getIxRefNumber());
                    oIPayResponseMap.put("OapfAVSCode", "");
                    oIPayResponseMap.put("OapfAuxMsg", sAuxMsgValue);
                    oIPayResponseMap.put("OapfPmtInstrType",
                                         sCardType); // Defect 2549
                    oIPayResponseMap.put("OapfNlsLang",
                                         oCommonAuth.getNlsLang());


// Bushrod Start for I0349 Defect 4180
                    oIPayResponseMap.put("OapfODRetCode",oAJBResponseStruct.getIxRetCode());
                    oIPayResponseMap.put("OapfODPS2000", oAJBResponseStruct.getIxPS2000());
// Bushrod End for I0349 Defect 4180


                } catch (Exception oEx) {
                    // return error
                    printwriter.println(" Exception occured in success condition ");
                    System.err.println(" Exception occured in success condition ");
                    throw oEx;
                }
            }
            // Checking for AJB failure responses
            else if ((!oAJBResponseStruct.getIxActionCode().equals("0")) ||
                     (!oCommonAuth.getPriceValue().equals(oAJBResponseStruct.getIxAmount()))) {

                printwriter.println(" failure IPAY Response ");

                printwriter.println("inside the failure AuthCode - AJB :" +
                                    oAJBResponseStruct.getIxAuthCode());

                printwriter.println("inside the failure - AuthCode value  :" +
                                    sAuthCodeValue);
                printwriter.println("inside the failure Vend Errmsg :" +
                                    sVendErrMsg);
                printwriter.println("inside the failure Receipt number : " +
                                    oAJBResponseStruct.getIxReceiptDisplay());
                printwriter.println("inside the failure store number : " +
                                    oAJBResponseStruct.getIxStoreNumber());
                printwriter.println("inside the failure Aux Message : " +
                                    sAuxMsgValue);
                printwriter.println("inside the failure oAJBResponseStruct.getPmtInstrType() : " +
                                    sCardType); // Defect 2549
                printwriter.println("inside the failure oAJBResponseStruct.getIxActionCode() : " +
                                    oAJBResponseStruct.getIxActionCode());
                printwriter.println("inside the failure sVendErrMsg : " +
                                    sVendErrMsg);
                printwriter.println("inside the failure oAJBResponseStruct.getIxBankNodeID() : " +
                                    oAJBResponseStruct.getIxBankNodeID());
                printwriter.println("inside the failure oCommonAuth.getNlsLang() : " +
                                    oCommonAuth.getNlsLang());
                printwriter.println("inside the failure OapfRefCode : " +
                                    oAJBResponseStruct.getIxRefNumber());
                printwriter.println("inside the failure OapfTrxnDate : " +
                                    sTrxnDate);
                printwriter.println("inside the failure Aux Message : " +
                                    sAuxMsgValue);
                printwriter.println("Aux Message : " + sAuxMsgValue);

                sRefCodeValue = oAJBResponseStruct.getIxRefNumber().trim();
                printwriter.println("inside the failure OapfRefCode -- After trim : " +
                                    sRefCodeValue);

                try {

                    oIPayResponseMap.clear();
                    printwriter.println(" before setting to hashmap :" +
                                        oIPayResponseMap);

                    oIPayResponseMap.put("OapfOrderId",
                                         oCommonAuth.getOrderId());
                    oIPayResponseMap.put("OapfStatus", "0005");
                    oIPayResponseMap.put("OapfAuthCode", sAuthCodeValue);
                    oIPayResponseMap.put("OapfTrxnDate", sTrxnDateTime);
                    oIPayResponseMap.put("OapfErrLocation", "3");
                    oIPayResponseMap.put("OapfVendErrCode",
                                         oAJBResponseStruct.getIxActionCode());
                    oIPayResponseMap.put("OapfVendErrmsg", sVendErrMsg);
                    oIPayResponseMap.put("OapfAcquirer",
                                         oAJBResponseStruct.getIxBankNodeID());
                    oIPayResponseMap.put("OapfRefCode", sRefCodeValue);
                    oIPayResponseMap.put("OapfAVSCode", "");
                    oIPayResponseMap.put("OapfAuxMsg",
                                         oAJBResponseStruct.getIxReceiptDisplay());
                    oIPayResponseMap.put("OapfPmtInstrType",
                                         sCardType); // Defect 2549
                    oIPayResponseMap.put("OapfNlsLang",
                                         oCommonAuth.getNlsLang());

                } catch (Exception oEx) {
                    // return error
                    printwriter.println(" Exception occured in failure condition ");
                    System.err.println(" Exception occured in failure condition ");
                    throw oEx;
                }
            }
            printwriter.println(" Before sending hashmap to setheader : " +
                                oIPayResponseMap);
        } catch (Exception oEx) {
            printwriter.println(" Exception occured in AJB Response ");
            System.err.println(" Exception occured in AJB Response ");
            throw oEx;
        }
        return oIPayResponseMap;
    }

    /**
     * This method is creating the response message based on AJB Action code
     * @return String
     * @exception Exception
     **/
    private

    String getAJBAction(String sActionCode,
                        AJBResponseStruct oAJBResponseStruct,
                        HttpServletResponse oResponse) throws Exception {

        PrintWriter printwriter = oResponse.getWriter();
        String sCont = "." + oAJBResponseStruct.getIxIsoResp();
        String sActionStr = "";
        try {
            if (sActionCode.equals("0")) {
                sActionStr = "Authorized";
            } else if (sActionCode.equals("1")) {
                sActionStr = "Declined";
            } else if (sActionCode.equals("2")) {
                sActionStr = "Referral";
            } else if (sActionCode.equals("3")) {
                sActionStr = "Bank Down";
            } else if (sActionCode.equals("5")) {
                sActionStr = "Modem/Phone Line Issue";
            } else if (sActionCode.equals("6")) {
                sActionStr = "Report Error";
            } else if (sActionCode.equals("8")) {
                sActionStr = "Try Later";
            } else if (sActionCode.equals("10")) {
                sActionStr = "Timed out";
            } else if (sActionCode.equals("14")) {
                sActionStr = "Request not supported by the authorizer";
            }
        } catch (Exception oEx) {
            printwriter.println(" Exception occured in creating the response message based on AJB Action code ");
            System.err.println(" Exception occured in creating the response message based on AJB Action code ");
            throw new Exception("Exception occured in creating the response message based on AJB Action code");

        }
        return sActionStr + sCont;
    }

    /**
     * This method is parsing the AJB response
     * @return
     * @exception Exception
     **/
    private

    void parseAJBResponse(String sAJBResponse,
                          AJBResponseStruct oAJBResponseStruct,
                          PurchCardAuthStruct oCommonAuth,
                          HttpServletResponse oResponse) throws Exception {

        try {

            String[] sAJBResp =
            { "IxTransactionType", "", "", "IxActionCode", "IxTimeOut",
              "IxDebitCredit", "", "IxStoreNumber", "IxTerminalNumber",
              "IxTranType", "", "", "IxAccount", "IxExpDate", "IxSwipe",
              "IxAmount", "IxInvoice", "", "", "", "IxOptions", "", "", "",
              "IxIssueNumber", "", "", "", "", "", "IxMailOrderAVSData", "",
              "", "IxPosEchoField", "", "", "IxAuthCode", "IxReceiptDisplay",
              "IxCrMerchant", "IxDbMerchant", "IxDefaultTimeout", "",
              "IxRetCode", "IxPS2000", "IxRefNumber", "", "", "", "", "IxDate",
              "IxTime", "IxDepositData", "IxIsoResp", "IxBankNodeID",
              "IxAuthResponseTime", "", "", "", "", "", "", "", "", "", "", "",
              "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
              "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
              "", "IxCardType" }; // Defect 2549
            String sAJBParam = "";
            String sAJBElementValue;
            String sMethodName;
            String[] oParamVal;
            Class[] oParamType = new Class[] { String.class };
            int iCount = 0;

            ArrayList oArr =
                TokenizeAJBResponse(sAJBResponse, oCommonAuth, oResponse);
            for (int iCtr = 0; iCtr < MAXSIZE; iCtr++) {
                //the number of tokens & size of array should be SAME
                sAJBParam = sAJBResp[iCount];
                sAJBElementValue = (String)oArr.get(iCtr);
                oParamVal = new String[] { sAJBElementValue };
                sMethodName = "set" + sAJBParam;
                setAJBStructValue(oAJBResponseStruct, oParamType, sMethodName,
                                  oParamVal);
                iCount++;

            }

        } catch (Exception oEx) {
            System.err.println(" Exception occured in parsing the AJB response ");
            oEx.getMessage();
        }
    }

    /**
     * setAJBStructValue
     * @return
     * @exception Exception
     **/
    private

    void setAJBStructValue(Object oAJBStruct, Class[] oParamType,
                           String sMethodName,
                           Object[] oParamValue) throws Exception {
        try {
            Method oMethod;
            oMethod =
                    oAJBStruct.getClass().getDeclaredMethod(sMethodName, oParamType);
            oMethod.invoke(oAJBStruct, oParamValue);

        } catch (Exception oEx) {
            System.err.println(" Exception occured in set field method for AJB ");
            oEx.getMessage();
        }
    }

    /**
     * TokenizeAJBResponse - spliting the AJB response string
     * @return ArrayList
     * @exception Exception
     **/
    private

    ArrayList TokenizeAJBResponse(String sResponse,
                                  PurchCardAuthStruct oCommonAuth,
                                  HttpServletResponse oResponse) throws Exception {

        PrintWriter printwriter = oResponse.getWriter();
        ArrayList oReturnArr = new ArrayList();
        int iLen = sResponse.length();
        char cResp;
        String sValue = "";

        try {
            for (int iPos = 0; iPos < iLen; iPos++) {
                cResp = sResponse.charAt(iPos);

                if (cResp == ',') {
                    if (sValue.trim().length() == 0) {
                        oReturnArr.add(new String(" "));
                    } else {
                        oReturnArr.add(sValue);
                        sValue = "";
                    }
                } else {
                    sValue += cResp;
                }
            }
        } catch (Exception oEx) {
            printwriter.println(" Exception occured in  spliting the AJB response string");
            System.err.println(" Exception occured in  spliting the AJB response string");
            throw new Exception(oEx.getMessage());
        }
        return oReturnArr;
    }

    /**
     * Getting the date and time format
     * @return String
     * @exception
     **/

    String getDateTime() {
        DateFormat dateFormat = new SimpleDateFormat("yyyyMMddHHmmss");
        Date date = new Date();
        return dateFormat.format(date);
    }

    /**
     * Getting the Response Aux message
     * @return String
     * @exception Exception
     **/
    private

    String getResAuxMsg(AJBResponseStruct oAJBResponseStruct,
                        HttpServletResponse oResponse) throws Exception {
        PrintWriter printwriter = oResponse.getWriter();
        String sAuxMsgValue = null;
        String sReceiptValue = null;
        try {

            sReceiptValue = oAJBResponseStruct.getIxReceiptDisplay().trim();
            printwriter.println(" Receipt value :" + sReceiptValue);

            if (sReceiptValue != null) {
                sAuxMsgValue =
                        sReceiptValue + "_" + oAJBResponseStruct.getIxStoreNumber();
            } else {
                sAuxMsgValue = "_" + oAJBResponseStruct.getIxStoreNumber();
            }
        } catch (Exception oEx) {
            printwriter.println("Exception occured in getting sAuxMsgValue value");
            System.err.println("Exception occured in getting sAuxMsgValue value");
            throw new Exception("Exception occured in getting sAuxMsgValue value");
        }
        return sAuxMsgValue;
    }

    /**
     * Getting the invoice from the DB
     * @see #getOracleAppConnection()
     * @return String
     * @Exception Exception
     **/
    private HashMap processInvoice(PurchCardAuthStruct oCommonAuth,
                                   HttpServletResponse oResponse) throws SQLException,
                                                                         Exception {

        HashMap oProcessInvoiceMap = new HashMap();
        PrintWriter printwriter = oResponse.getWriter();
        // Initializing the CallableStatement Object
        CallableStatement sCallableStmt = null;
        // Initializing the Connection Object
        // Connection oConn = null; // updation 1.15
        String sInvoiceValueOut = null;
        String sDataOut = null;
        String sTokenEnabled = null;

        String sOrderId = oCommonAuth.getOrderId();
        printwriter.println("order Id   :" + sOrderId);
        printwriter.println("DBC File Path  :" + sDBCValue);

        try {

            // Calling the OracleDBConnection method
            oConn = getOracleAppConnection();

        } catch (Exception oEx) {
            System.err.println(" Exception occured in calling the Connection object ");
            printwriter.println("Exception occured in calling the Connection object ");
           // throw oEx;
            throw new Exception("Exception occured in calling the Connection object :" + oEx.getMessage());

        }

        try {

            printwriter.println("Query  :" + sInvoiceQuery);

            // Calling the preparecall method
            sCallableStmt = oConn.prepareCall(sInvoiceQuery);
            // Setting the input arguements for the stored proc
            sCallableStmt.setString(1, sOrderId);
            // Registering the output parameters for the stored proc
            sCallableStmt.registerOutParameter(2, Types.VARCHAR);
            sCallableStmt.registerOutParameter(3, Types.VARCHAR);
            sCallableStmt.registerOutParameter(4, Types.VARCHAR);

            // Executing the Statement
            sCallableStmt.execute();
            printwriter.println("Successfully Executed ");

            // Getting the output parameters for the stored proc
            sInvoiceValueOut = sCallableStmt.getString(2);
            printwriter.println(" Invoice value from DB  :" +
                                sInvoiceValueOut);

            sDataOut = sCallableStmt.getString(3);
            printwriter.println(" Data value from DB  :" + sDataOut);

            sTokenEnabled = sCallableStmt.getString(4);
            printwriter.println(" Data value from DB  :" + sTokenEnabled);

            //  Setting the value to hashmap
            oProcessInvoiceMap.clear();
            oProcessInvoiceMap.put("InvoiceValueOut", sInvoiceValueOut);
            oProcessInvoiceMap.put("DataOut", sDataOut);
            oProcessInvoiceMap.put("TokenEnabled", sTokenEnabled);

        } catch (Exception oEx) {
            printwriter.println(" Exception occured in calling the stored proc");
            System.err.println(" Exception occured in calling the stored proc");
            //throw oEx;
            throw new Exception(" Exception occured in calling the stored proc :" + oEx.getMessage());

        }

        finally {
            try {
                if (oConn != null) {
                    oConn.commit();
                }
            } catch (Exception oEx) {
                printwriter.println(" Exception occured in Connection ");
                System.err.println(" Exception occured in Connection ");
                oEx.printStackTrace();

                throw oEx;
            }
            try {
                if (sCallableStmt != null) {
                    sCallableStmt.close();
                    printwriter.println(" Before calling:process invoice() - Release Connection" +
                                        oConn);
                    dbfAppsContext.releaseExtraJDBCConnection(oConn); // updation 1.15
                    printwriter.println(" After calling:process invoice() - Release Connection" +
                                        oConn);
                }

            } catch (Exception oEx) {
                printwriter.println(" Exception occured in callable statement ");
                System.err.println(" Exception occured in callable statement ");
                oEx.printStackTrace();
            }
        }

        return oProcessInvoiceMap;
    }


    /**
     * convertDateFormat
     * @return String
     * @exception
     **/
    private static String convertDateFormat(String dateIn, String formatIn,
                                            String formatOut) {
        try {
            if ("now" == dateIn) {
                return (new SimpleDateFormat(formatOut).format(new Date()));
            } else {
                return (new SimpleDateFormat(formatOut)).format((new SimpleDateFormat(formatIn)).parse(dateIn,
                                                                                                       new ParsePosition(0)));
            }
        } catch (Exception oEx) {
            return "";
        }
    }


    /**
     * This method is construct the success voice response
     * @return HashMap
     * @exception Exception
     **/
    private HashMap getIPaySuccessVoiceResponse(HttpServletRequest oRequest,
                                                HttpServletResponse oResponse) throws Exception {
        PrintWriter printwriter = oResponse.getWriter();
        HashMap oIPaySuccessVoiceResponseMap = new HashMap();
        try {
            oIPaySuccessVoiceResponseMap.clear();
            printwriter.println("success response - voiceauth API");
            oIPaySuccessVoiceResponseMap.put("OapfOrderId",
                                             oRequest.getParameter("OapfOrderId"));
            oIPaySuccessVoiceResponseMap.put("OapfAuthCode",
                                             oRequest.getParameter("OapfAuthCode"));
            oIPaySuccessVoiceResponseMap.put("OapfNlsLang",
                                             oRequest.getParameter("OapfNlsLang"));

        } catch (Exception oEx) {
            // return error
            printwriter.println(" Exception occured in forming the successful voice response  ");
            System.err.println(" Exception occured in forming the successful voice response  ");
            throw new Exception("Exception occured in forming the successful voice response");
        }
        return oIPaySuccessVoiceResponseMap;
    }


    /**
     * This method is construct the failure voice response
     * @return HashMap
     * @exception IOException
     **/
    private

    HashMap getIPayFailureVoiceResponse(HttpServletRequest oRequest,
                                        HttpServletResponse oResponse) throws IOException {
        PrintWriter printwriter = oResponse.getWriter();
        HashMap oIPayFailureVoiceResponseMap = new HashMap();
        try {
            oIPayFailureVoiceResponseMap.clear();
            oIPayFailureVoiceResponseMap.put("OapfOrderId",
                                             oRequest.getParameter("OapfOrderId"));
            oIPayFailureVoiceResponseMap.put("OapfAuthCode",
                                             oRequest.getParameter("OapfAuthCode"));
            oIPayFailureVoiceResponseMap.put("OapfNlsLang",
                                             oRequest.getParameter("OapfNlsLang"));

        } catch (Exception oEx) {
            // return error
            printwriter.println(" Exception occured in forming the failure voice response ");
            System.err.println(" Exception occured in forming the failure voice response ");
            throw new IOException("Exception occured in forming the failure voice response");
        }
        return oIPayFailureVoiceResponseMap;
    }


    /**
     * This method is construct the set Header for the IPayment
     * @see #getAuthResponse(oAJBResponseStruct, oCommonAuth, oResponse)
     * @return
     * @exception Exception
     **/
    private

    void getIPayAuthPurchaseResponse(AJBResponseStruct oAJBResponseStruct,
                                     PurchCardAuthStruct oCommonAuth,
                                     HttpServletResponse oResponse) throws Exception {

        PrintWriter printwriter = oResponse.getWriter();

        HashMap responseHashMap = new HashMap();

        String sAVSCodeTrimValue = null;
        String sNlsLangTrimValue = null;
        String sAuthCodeTrimValue = null;
        String sPmtTypeTrimValue = null;

        try {

            printwriter.println(" Executing method - getIPayAuthPurchaseResponse ");

            // Calling the getAuthResponse
            responseHashMap.clear();
            responseHashMap =
                    getAuthResponse(oAJBResponseStruct, oCommonAuth, oResponse);
            printwriter.println("\n response value : \n" + responseHashMap);

            printwriter.println("OapfOrderId :" +
                                (String)responseHashMap.get("OapfOrderId"));
            printwriter.println("OapfStatus :" +
                                (String)responseHashMap.get("OapfStatus"));
            printwriter.println("OapfAuthcode :" +
                                (String)responseHashMap.get("OapfAuthCode"));
            printwriter.println("Aux Message :" +
                                (String)responseHashMap.get("OapfAuxMsg"));
            printwriter.println("OapfPmtInstrType :" +
                                (String)responseHashMap.get("OapfPmtInstrType"));
            printwriter.println("OapfVendErrCode :" +
                                (String)responseHashMap.get("OapfVendErrCode"));
            printwriter.println("OapfErrLocation :" +
                                (String)responseHashMap.get("OapfErrLocation"));
            printwriter.println("OapfVendErrmsg :" +
                                (String)responseHashMap.get("OapfVendErrmsg"));
            printwriter.println("OapfAcquirer :" +
                                (String)responseHashMap.get("OapfAcquirer"));
            printwriter.println("OapfRefcode :" +
                                (String)responseHashMap.get("OapfRefCode"));
            printwriter.println("OapfAVScode :" +
                                (String)responseHashMap.get("OapfAVSCode"));
            printwriter.println(" OapfNlsLang :" +
                                (String)responseHashMap.get("OapfNlsLang"));
            printwriter.println(" OapfTrxnDate :" +
                                (String)responseHashMap.get("OapfTrxnDate"));

            oResponse.setHeader("OapfOrderId",
                                (String)responseHashMap.get("OapfOrderId"));
            printwriter.println(" successfully after setting the header - OapfOrderId    :" +
                                (String)responseHashMap.get("OapfOrderId"));

            oResponse.setHeader("OapfTrxnType", "2");
            printwriter.println(" successfully after setting the header - OapfTrxnType   :" +
                                2);

            oResponse.setHeader("OapfStatus",
                                (String)responseHashMap.get("OapfStatus"));
            printwriter.println(" successfully after setting the header - OapfStatus     :" +
                                (String)responseHashMap.get("OapfStatus"));

            oResponse.setHeader("OapfTrxnDate",
                                (String)responseHashMap.get("OapfTrxnDate"));
            printwriter.println(" successfully after setting the header - OapfTrxnDate   :" +
                                (String)responseHashMap.get("OapfTrxnDate"));

            oResponse.setHeader("OapfErrLocation",
                                (String)responseHashMap.get("OapfErrLocation"));
            printwriter.println(" successfully after setting the header - OapfErrLocation    :" +
                                (String)responseHashMap.get("OapfErrLocation"));

            oResponse.setHeader("OapfVendErrCode",
                                (String)responseHashMap.get("OapfVendErrCode"));
            printwriter.println(" successfully after setting the header - OapfVendErrCode    :" +
                                (String)responseHashMap.get("OapfVendErrCode"));

            oResponse.setHeader("OapfVendErrmsg",
                                (String)responseHashMap.get("OapfVendErrmsg"));
            printwriter.println(" successfully after setting the header - OapfVendErrmsg     :" +
                                (String)responseHashMap.get("OapfVendErrmsg"));

            oResponse.setHeader("OapfAcquirer",
                                (String)responseHashMap.get("OapfAcquirer"));
            printwriter.println(" successfully after setting the header - OapfAcquirer       :" +
                                (String)responseHashMap.get("OapfAcquirer"));

            oResponse.setHeader("OapfRefcode",
                                (String)responseHashMap.get("OapfRefCode"));
            printwriter.println(" successfully after setting the header - OapfRefcode        :" +
                                (String)responseHashMap.get("OapfRefCode"));


// Bushrod Start for I0349 Defect 4180
            if ((String)responseHashMap.get("OapfODRetCode") != null) {
                String sOapfODRetCode = (String)responseHashMap.get("OapfODRetCode");
                oResponse.setHeader("OapfODRetCode", sOapfODRetCode.trim());
                printwriter.println(" successfully after setting the header IF- OapfODRetCode        :" +
                                    sOapfODRetCode.trim());
            } else {
                oResponse.setHeader("OapfODRetCode", "");
                printwriter.println(" successfully after setting the header ELSE- OapfODRetCode         :" +
                                    (String)responseHashMap.get("OapfODRetCode"));
            }

            if ((String)responseHashMap.get("OapfODPS2000") != null) {
                String sOapfODPS2000 = (String)responseHashMap.get("OapfODPS2000");
                oResponse.setHeader("OapfODPS2000", sOapfODPS2000.trim());
                printwriter.println(" successfully after setting the header IF- OapfODPS2000        :" +
                                    sOapfODPS2000.trim());
            } else {
                oResponse.setHeader("OapfODPS2000", "");
                printwriter.println(" successfully after setting the header ELSE- OapfODPS2000         :" +
                                    (String)responseHashMap.get("OapfODPS2000"));
            }
// Bushrod End for I0349 Defect 4180


            oResponse.setHeader("OapfAuxMsg",
                                (String)responseHashMap.get("OapfAuxMsg"));
            printwriter.println(" successfully after setting the header - OapfAuxMsg         :" +
                                (String)responseHashMap.get("OapfAuxMsg"));

            // Checking the OapfAVScode parameter value for null
            if ((String)responseHashMap.get("OapfAVSCode") != null) {
                sAVSCodeTrimValue = (String)responseHashMap.get("OapfAVSCode");
                oResponse.setHeader("OapfAVScode", sAVSCodeTrimValue.trim());
                printwriter.println(" successfully after setting the header IF- OapfAVScode       :" +
                                    sAVSCodeTrimValue.trim());
            } else {
                oResponse.setHeader("OapfAVScode", "");
                printwriter.println(" successfully after setting the header ELSE- OapfAVScode        :" +
                                    (String)responseHashMap.get("OapfAVSCode"));
            }

            // Checking the NlsLang parameter value for null
            if ((String)responseHashMap.get("OapfNlsLang") != null) {
                sNlsLangTrimValue = (String)responseHashMap.get("OapfNlsLang");
                oResponse.setHeader("OapfNlsLang", sNlsLangTrimValue.trim());
                printwriter.println(" successfully after setting the header - IF - OapfNlsLang        :" +
                                    sNlsLangTrimValue.trim());
            } else {
                oResponse.setHeader("OapfNlsLang", "");
                printwriter.println(" successfully after setting the header - ELSE -OapfNlsLang      :" +
                                    (String)responseHashMap.get("OapfNlsLang"));
            }

            // Checking the PmtInstrType parameter value for null
            if ((String)responseHashMap.get("OapfPmtInstrType") != null) {
                sPmtTypeTrimValue =
                        (String)responseHashMap.get("OapfPmtInstrType");
                oResponse.setHeader("OapfPmtInstrType",
                                    sPmtTypeTrimValue.trim());
                printwriter.println(" successfully after setting the header -IF- IxCardType      :" +
                                    sPmtTypeTrimValue.trim());
            } else {
                oResponse.setHeader("OapfPmtInstrType", "");
                printwriter.println(" successfully after setting the header -ELSE- IxCardType      :" +
                                    (String)responseHashMap.get("OapfPmtInstrType"));
            }

            // Checking the AuthCode parameter value for null
            if ((String)responseHashMap.get("OapfAuthCode") != null) {
                sAuthCodeTrimValue =
                        (String)responseHashMap.get("OapfAuthCode");
                oResponse.setHeader("OapfAuthcode", sAuthCodeTrimValue.trim());
                printwriter.println(" successfully after setting the header -IF- OapfAuthcode     :" +
                                    sAuthCodeTrimValue.trim());
            } else {
                oResponse.setHeader("OapfAuthcode", "");
                printwriter.println(" successfully after setting the header -ELSE- OapfAuthcode      :" +
                                    (String)responseHashMap.get("OapfAuthCode"));
            }
            printwriter.println("Successfully set the Header");
            return;
        } catch (Exception oEx) {
            printwriter.println(" Exception occured in set Header ");
            System.err.println(" Exception occured in set Header ");
            // throw oEx;
            getFailureException(" Exception occured in set Header :" +
                                oEx.getMessage(), oCommonAuth, oResponse);
            return;
        }
    }


    /**
     * This method is construct FailureException Header
     * @see #getSysDate()
     * @Exception IOException
     **/
    private

    void getFailureException(String sErrStr, PurchCardAuthStruct oCommonAuth,
                             HttpServletResponse oResponse) throws IOException {
        PrintWriter printwriter = oResponse.getWriter();
        try {
            printwriter.println("inside the try block - getFailureException()"); // 1.12  06-Feb-2008
            printwriter.println("Error message :" + sErrStr);

            oResponse.setHeader("OapfOrderId", oCommonAuth.getOrderId());
            oResponse.setHeader("OapfTrxnType", "2");
            oResponse.setHeader("OapfStatus", "0001");
            oResponse.setHeader("OapfAuthcode", "");
            oResponse.setHeader("OapfTrxnDate", getSysDate());
            oResponse.setHeader("OapfPmtInstrType", "");
            oResponse.setHeader("OapfErrLocation", "6");
            oResponse.setHeader("OapfVendErrCode", "");
            oResponse.setHeader("OapfVendErrmsg", sErrStr);
            oResponse.setHeader("OapfAcquirer", "");
            oResponse.setHeader("OapfRefcode", "");
            oResponse.setHeader("OapfAVScode", "");
            oResponse.setHeader("OapfAuxMsg", "");
            oResponse.setHeader("OapfN1sLang", oCommonAuth.getNlsLang());
            printwriter.println(" successfully set the Header ");
            return;
        } catch (Exception oEx) {
            System.err.println(" Exception occured in Failure Condition");
            printwriter.println("inside the catch Exception block - getFailureException()"); // 1.12  06-Feb-2008

            oResponse.setHeader("OapfOrderId", oCommonAuth.getOrderId());
            oResponse.setHeader("OapfTrxnType", "2");
            oResponse.setHeader("OapfStatus", "0001");
            oResponse.setHeader("OapfAuthcode", "");
            oResponse.setHeader("OapfTrxnDate", getSysDate());
            oResponse.setHeader("OapfPmtInstrType", "");
            oResponse.setHeader("OapfErrLocation", "6");
            oResponse.setHeader("OapfVendErrCode", "");
            oResponse.setHeader("OapfVendErrmsg", oEx.getMessage());
            oResponse.setHeader("OapfAcquirer", "");
            oResponse.setHeader("OapfRefcode", "");
            oResponse.setHeader("OapfAVScode", "");
            oResponse.setHeader("OapfAuxMsg", "");
            oResponse.setHeader("OapfN1sLang", oCommonAuth.getNlsLang());
            printwriter.println(" successfully set the Header ");
            return;
        }
    }


    /**
     * This method is construct FailureException Header
     * @see #getSysDate()
     * @Exception IOException
     **/
    private

    HashMap getFailureMAPException(String sErrStr,
                                   PurchCardAuthStruct oCommonAuth,
                                   HttpServletResponse oResponse) throws IOException {
        PrintWriter printwriter = oResponse.getWriter();
        HashMap oAJBFailureMap = new HashMap();

        try {
            printwriter.println("inside the try block - getFailureMapException()"); // 1.12  06-Feb-2008
            printwriter.println("Error message :" + sErrStr);
            oAJBFailureMap.clear(); // 1.13  07-Feb-2008
            oAJBFailureMap.put("OapfOrderId", oCommonAuth.getOrderId());
           // oAJBFailureMap.put("OapfStatus", "0001"); //5 //0001
            oAJBFailureMap.put("OapfStatus", "0005"); // Defect 6580
            oAJBFailureMap.put("OapfAuthCode", "");
            oAJBFailureMap.put("OapfTrxnDate", getSysDate());
            oAJBFailureMap.put("OapfPmtInstrType", "");
            oAJBFailureMap.put("OapfErrLocation", "6"); //3 //6
            oAJBFailureMap.put("OapfVendErrCode", "6"); // Defect 6580
            // oAJBFailureMap.put("OapfVendErrCode", "1");
            oAJBFailureMap.put("OapfVendErrmsg", sErrStr);
            oAJBFailureMap.put("OapfAcquirer", "");
            oAJBFailureMap.put("OapfRefCode", "");
            oAJBFailureMap.put("OapfAVSCode", "");
            oAJBFailureMap.put("OapfAuxMsg", "");
            oAJBFailureMap.put("OapfNlsLang", oCommonAuth.getNlsLang());
            printwriter.println(" successfully set the Header ");

        } catch (Exception oEx) {
            System.err.println(" Exception occured in Failure Condition");
            throw new IOException("Error while Failure Condition :" +
                                  oEx.getMessage());
        }
        return oAJBFailureMap;
    }


    /**
     * This method is executing the stored procedure
     * @see #getOracleAppConnection()
     * @return HashMap
     * @Exception Exception,SQLException
     **/
    private

    HashMap getCloseBatchResponse() throws SQLException, Exception {

        HashMap oCloseBatchResponseMap = new HashMap();
        // Initializing the Connection Object
        // Connection oConn = null; // updation 1.15
        CallableStatement sCallableStmt = null;

        String sIbyDate = null;
        String sCreditAmt = null;
        String sSalesAmt = null;
        String sBatchTotal = null;
        String sBatchCurr = null;
        String sNumTrxns = null;
        String sVpsBatchId = null;
        String sGWBatchId = null;
        String sState = null;

        try {
            // Calling the OracleDBConnection method
            oConn = getOracleAppConnection();
        } catch (Exception oEx) {
            System.err.println(" Exception occured in calling the getOracleAppConnection ");
            //throw oEx;
            throw new Exception(" Exception occured in calling the getOracleAppConnection :" + oEx.getMessage());
        }

   //  Commented for Defect #4586 -- Starting
/*        try {

            // Calling the preparecall method
            sCallableStmt = oConn.prepareCall(sCloseBatchQuery);

            // Registering the output parameters for the stored proc
            sCallableStmt.registerOutParameter(1, Types.VARCHAR);
            sCallableStmt.registerOutParameter(2, Types.VARCHAR);
            sCallableStmt.registerOutParameter(3, Types.VARCHAR);
            sCallableStmt.registerOutParameter(4, Types.VARCHAR);
            sCallableStmt.registerOutParameter(5, Types.VARCHAR);
            sCallableStmt.registerOutParameter(6, Types.VARCHAR);
            sCallableStmt.registerOutParameter(7, Types.VARCHAR);
            sCallableStmt.registerOutParameter(8, Types.VARCHAR);
            sCallableStmt.registerOutParameter(9, Types.VARCHAR);

            // Executing the stored procedure
            sCallableStmt.execute();

            // Getting the IbyDate output parameters for the stored proc
            sIbyDate = sCallableStmt.getString(1);

            // Getting the CreditAmt output parameters for the stored proc
            sCreditAmt = sCallableStmt.getString(2);

            // Getting the SalesAmt output parameters for the stored proc
            sSalesAmt = sCallableStmt.getString(3);

            // Getting the BatchTotal output parameters for the stored proc
            sBatchTotal = sCallableStmt.getString(4);

            // Getting the BatchCurrency output parameters for the stored proc
            sBatchCurr = sCallableStmt.getString(5);

            // Getting the NumberTrnx output parameters for the stored proc
            sNumTrxns = sCallableStmt.getString(6);

            // Getting the VpsBatchId output parameters for the stored proc
            sVpsBatchId = sCallableStmt.getString(7);

            // Getting the GEBatchId output parameters for the stored proc
            sGWBatchId = sCallableStmt.getString(8);

            // Getting the State output parameters for the stored proc
            sState = sCallableStmt.getString(9);

            //  Setting the value to hashmap

            oCloseBatchResponseMap.clear();
            oCloseBatchResponseMap.put("IbyDate", sIbyDate);
            oCloseBatchResponseMap.put("CreditAmt", sCreditAmt);
            oCloseBatchResponseMap.put("SalesAmt", sSalesAmt);
            oCloseBatchResponseMap.put("BatchTotal", sBatchTotal);
            oCloseBatchResponseMap.put("BatchCurr", sBatchCurr);
            oCloseBatchResponseMap.put("NumTrxns", sNumTrxns);
            oCloseBatchResponseMap.put("VpsBatchId", sVpsBatchId);
            oCloseBatchResponseMap.put("GWBatchId", sGWBatchId);
            oCloseBatchResponseMap.put("State", sState);


        } catch (Exception oEx) {
            System.err.println("Exception occured in calling the stored procedure");
            // throw oEx;
            throw new Exception("Exception occured in calling the stored procedure :" + oEx.getMessage());
        } */
        //  Commented for Defect #4586 -- Ending
        finally {
            try {
                if (oConn != null) {
                    oConn.commit();
                }
            } catch (Exception oEx) {
                System.err.println(" Exception occured in closing the Connection object ");
                oEx.printStackTrace();

                throw oEx;
            }
            try {
                if (sCallableStmt != null) {
                    sCallableStmt.close();
                    dbfAppsContext.releaseExtraJDBCConnection(oConn); // updation 1.15
                }

            } catch (Exception oEx) {
                System.err.println(" Exception occured in closing the callable statment ");
                oEx.printStackTrace();
            }
        }
        return oCloseBatchResponseMap;
    }


    /**
     * This method is construct FailureException Header
     * @Exception IOException
     **/
   //  Commented for Defect #4586 -- Starting
/*  private

    void getDBCloseBatchException(String sErrStr,
                                  PurchCardAuthStruct oCommonAuth,
                                  HttpServletResponse oResponse) throws IOException {

        PrintWriter printwriter = oResponse.getWriter();
        StringBuffer sCloseBufferExc = new StringBuffer();
        String sCloseBatchFormatExc;

        try {
            oResponse.setHeader("OapfStatus", "0008");
            oResponse.setHeader("OapfBatchDate", "");
            oResponse.setHeader("OapfCreditAmount", "0");
            oResponse.setHeader("OapfSalesAmount", "0");
            oResponse.setHeader("OapfBatchTotal", "0");
            oResponse.setHeader("OapfCurr", "USD");
            oResponse.setHeader("OapfNumTrxns", "0");
            oResponse.setHeader("OapfStoreID", oCommonAuth.getStoreId());
            oResponse.setHeader("OapfVpsBatchID", "");
            oResponse.setHeader("OapfGWBatchID", "");
            oResponse.setHeader("OapfBatchState", "6");
            oResponse.setHeader("OapfErrLocation", "1");
            oResponse.setHeader("OapfVendErrCode", "4");
            oResponse.setHeader("OapfVendErrmsg", sErrStr);


            sCloseBufferExc.append("<H2>Results</H2><BR>OapfStatus: 0008<BR>OapfBatchDate: "); // replaced the string buffer insatiate of '+'
            sCloseBufferExc.append("<BR>OapfCreditAmount: 0<BR>OapfSalesAmount: 0").append("<BR>OapfBatchTotal: 0<BR>OapfCurr: USD");
            sCloseBufferExc.append("<BR>OapfNumTrxns: 0<BR>OapfStoreID:").append(oCommonAuth.getStoreId());
            sCloseBufferExc.append(" <BR>OapfVpsBatchID: <BR>OapfGWBatchID: ").append("<BR>OapfBatchState: <BR>OapfErrLocation: ");
            sCloseBufferExc.append("<BR>OapfVendErrCode: ").append("<BR>OapfVendErrmsg: ");
            sCloseBufferExc.append(sErrStr).append("<BR>");

            sCloseBatchFormatExc = sCloseBufferExc.toString();
            printwriter.println(sCloseBatchFormatExc);

            /*
            printwriter.println("<H2>Results</H2><BR>OapfStatus: 0008<BR>OapfBatchDate: " +
                                "<BR>OapfCreditAmount: 0<BR>OapfSalesAmount: 0" +
                                "<BR>OapfBatchTotal: 0<BR>OapfCurr: USD" +
                                "<BR>OapfNumTrxns: 0<BR>OapfStoreID:" +
                                oCommonAuth.getStoreId() +
                                " <BR>OapfVpsBatchID: <BR>OapfGWBatchID: " +
                                "<BR>OapfBatchState: <BR>OapfErrLocation: " +
                                "<BR>OapfVendErrCode: " +
                                "<BR>OapfVendErrmsg: " + sErrStr + "<BR>");

            return;
        } catch (Exception oEx) {
            printwriter.println(" Exception occured in CloseBatch API ");
            System.err.println(" Exception occured in  CloseBatch API");
            getFailureException("Exception occured in CloseBatch API :" +
                                oEx.getMessage(), oCommonAuth, oResponse);
            return;
        }
    }
   //  Commented for Defect #4586 -- Starting
    /**
     * This method is construct OracleAppConnection
     * @Release Connection
     * @Exception SQLException,Exception
     **/
    private

    Connection getOracleAppConnection() throws SQLException, Exception {

        /*  // commented updation 1.15
        try {
            // Loading the Drivers
            Class.forName(sDriver);

        } catch (Exception oEx) {
            System.err.println("Exception occured in loading the drivers");
            throw new Exception("Error while loading the drivers " +
                                oEx.getMessage());
        }

*/
        try {
            //  Creating the Connection object
            oConn = dbfAppsContext.getJDBCConnection(this); // updation 1.15
        } catch (Exception oEx) {
            System.err.println("Exception occured in creating the Connection object");
            throw new Exception("Error while creating the Connection object :" +
                                oEx.getMessage());
        }
        return oConn;
    }

    /**
     * This method is executing the stored procedure
     * @see #getOracleAppConnection()
     * @return HashMap
     * @Exception Exception,SQLException
     **/
    private

    HashMap getCaptureReturnResponse(PurchCardAuthStruct oCommonAuth,
                                     HttpServletRequest oRequest,
                                     HttpServletResponse oResponse) throws SQLException,
                                                                           Exception {

        PrintWriter printwriter = oResponse.getWriter();
        HashMap oCaptureReturnResponseMap = new HashMap();
        // Initializing the Connection Object
        // Connection oConn = null; // updation 1.15
        CallableStatement sCallableStmt = null;

        String sAction = oCommonAuth.getAction();
        printwriter.println("Action value inside the stored proc :" + sAction);
        String sTrxnsId = oRequest.getParameter("OapfTransactionId");
        printwriter.println("Trxns id value inside the stored proc :" +
                            sTrxnsId);
        String sTrxnsRef = oRequest.getParameter("OapfTrxnRef");
        printwriter.println("Trxns Ref value inside the stored proc :" +
                            sTrxnsRef);
        String sCurrency = oCommonAuth.getCurrency();
        printwriter.println("Currency value inside the stored proc :" +
                            sCurrency);
        String sPrice = oCommonAuth.getPrice();
        printwriter.println("Price value inside the stored proc :" + sPrice);
        String sStoreId = oCommonAuth.getStoreId();
        printwriter.println("StoreId value inside the stored proc :" +
                            sStoreId);
        String sOrderId = oCommonAuth.getOrderId();
        printwriter.println("OrderId value inside the stored proc :" +
                            sOrderId);

        String sErrorMsg = null;
        String sRetCode = null;
        String sReceiptRef = null;

        try {
            // Calling the OracleDBConnection method
             oConn = getOracleAppConnection();
        } catch (Exception oEx) {
            System.err.println(" Exception occured in calling the getOracleAppConnection ");
          //  throw oEx;
           throw new Exception(" Exception occured in calling the getOracleAppConnection :" + oEx.getMessage());
        }

        try {

            // Calling the preparecall method
            sCallableStmt = oConn.prepareCall(sCaptureReturnQuery);

            //  Setting the input arguements for the stored proc
            sCallableStmt.setString(4, sAction);
            sCallableStmt.setString(5, sCurrency);
            sCallableStmt.setString(6, sPrice);
            sCallableStmt.setString(7, sStoreId);
            sCallableStmt.setString(8, sTrxnsId);
            sCallableStmt.setString(9, sTrxnsRef);
            sCallableStmt.setString(10, sOrderId);

            // Registering the output parameters for the stored proc
            sCallableStmt.registerOutParameter(1, Types.VARCHAR);
            sCallableStmt.registerOutParameter(2, Types.VARCHAR);
            sCallableStmt.registerOutParameter(3, Types.VARCHAR);

            // Executing the stored procedure
            sCallableStmt.execute();
            printwriter.println("successfully executed!!");

            // Getting the Error output parameters for the stored proc
            sErrorMsg = sCallableStmt.getString(1);
            printwriter.println("inside the CaptureReturnResponse() ***error msg :" +
                                sErrorMsg);

            // Getting the RetCode output parameters for the stored proc
            sRetCode = sCallableStmt.getString(2);
            printwriter.println("inside the CaptureReturnResponse() ***ret code :" +
                                sRetCode);

            // Getting the SalesAmt output parameters for the stored proc
            sReceiptRef = sCallableStmt.getString(3);
            printwriter.println("inside the CaptureReturnResponse() ***ReceiptRef :" +
                                sReceiptRef);

            //  Setting the value to hashmap
            oCaptureReturnResponseMap.clear();
            oCaptureReturnResponseMap.put("ErrorMsg", sErrorMsg);
            oCaptureReturnResponseMap.put("RetCode", sRetCode);
            oCaptureReturnResponseMap.put("ReceiptRef", sReceiptRef);

        } catch (Exception oEx) {
            System.err.println("Exception occured in calling the stored procedure");
           // throw oEx;
           throw new Exception("Exception occured in calling the stored procedure :" + oEx.getMessage());
        } finally {
            try {
                if (oConn != null) {
                    oConn.commit();
                }
            } catch (Exception oEx) {
                System.err.println(" Exception occured in closing the Connection object ");
                oEx.printStackTrace();
                throw oEx;
            }
            try {
                if (sCallableStmt != null) {
                    sCallableStmt.close();
                    // updation 1.17
               /*     printwriter.println(" Before calling:getCaptureReturnResponse() - Release Connection" +
                                        oConn);
                    dbfAppsContext.releaseExtraJDBCConnection(oConn); // updation 1.15
                    printwriter.println(" After calling:getCaptureReturnResponse() - Release Connection" +
                                        oConn);
              */
                }

            } catch (Exception oEx) {
                System.err.println(" Exception occured in closing the callable statment ");
                oEx.printStackTrace();
            }
        }
        printwriter.println("before sending to Capture/Return API" +
                            oCaptureReturnResponseMap);

        return oCaptureReturnResponseMap;
    }


    /**
     * This method is construct the CaptureException Header
     * @Exception Exception
     **/
    private

    void getCaptureException(String sErrStr, HttpServletResponse oResponse,
                             PurchCardAuthStruct oCommonAuth) throws IOException {
        PrintWriter printwriter = oResponse.getWriter();
        try {
            printwriter.println("inside the Capture Exception method");
            printwriter.println("Capture Exception Message =>" + sErrStr);
           // oResponse.setHeader("OapfStatus", "0002");
            oResponse.setHeader("OapfStatus", "0005"); // Defect 6580
            oResponse.setHeader("OapfTrxnType", "2");
            oResponse.setHeader("OapfTrxnDate", getSysDate());
            oResponse.setHeader("OapfErrLocation", "1");
            oResponse.setHeader("OapfVendErrCode", "1");
            oResponse.setHeader("OapfVendErrmsg", sErrStr);
            printwriter.println(" successfully set the Header");
            return;
        } catch (Exception oEx) {
            printwriter.println(" Exception occured in Capture API");
            System.err.println(" Exception occured in Capture API");
            getFailureException("Exception occured in Capture API :" +
                                oEx.getMessage(), oCommonAuth, oResponse);
            return;
        }
    }


    /**
     * This method is construct the ReturnException Header
     * @Exception Exception
     **/
    private

    void getReturnException(String sErrStr, HttpServletResponse oResponse,
                            PurchCardAuthStruct oCommonAuth) throws IOException {
        PrintWriter printwriter = oResponse.getWriter();
        try {
            printwriter.println(" inside the Return Exception method");
            printwriter.println("Return Exception Message =>" + sErrStr);
            // oResponse.setHeader("OapfStatus", "0002");
            oResponse.setHeader("OapfStatus", "0005"); // Defect 6580
            oResponse.setHeader("OapfTrxnType", "5");
            oResponse.setHeader("OapfTrxnDate", getSysDate());
            oResponse.setHeader("OapfErrLocation", "1");
            oResponse.setHeader("OapfVendErrCode", "2");
            oResponse.setHeader("OapfVendErrmsg", sErrStr);
            printwriter.println(" successfully set the Header");
            return;
        } catch (Exception oEx) {
            printwriter.println(" Exception occured in Return API");
            System.err.println(" Exception occured in Return API");
            getFailureException("Exception occured in Return API :" +
                                oEx.getMessage(), oCommonAuth, oResponse);
            return;
        }
    }

} // end of servlet
