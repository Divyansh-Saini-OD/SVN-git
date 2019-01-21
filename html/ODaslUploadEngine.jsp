<%@ page contentType="text/html;charset=windows-1252"%>
<!-- imports for apache commons -->
<%@ page language="java" import="java.io.*" %>
<%@ page language="java" import="java.util.*" %>
<%@ page language="java" import="java.util.NoSuchElementException" %>
<%@ page language="java" import="org.apache.commons.fileupload.servlet.*" %>
<%@ page language="java" import="org.apache.commons.fileupload.*" %>
<%@ page language="java" import="org.apache.commons.fileupload.util.*" %>
<%@ page language="java" import="org.apache.commons.fileupload.disk.*" %>
<%@ page language="java" import="java.sql.*" %>
<%@ page language="java" import="oracle.jdbc.driver.*" %>
<%@ page language="java" import="java.util.StringTokenizer" %>
<%@ page language="java" import="java.math.*" %>
<%@ page language="java" import="java.util.*" %>

<%@ include file="ODasljtfincl.jsp" %>
<%@ page import="oracle.apps.fnd.sso.SSOManager" %>
<%@ page import="oracle.apps.fnd.sso.Utils" %>
<%@ page import="oracle.apps.ibe.tcav2.Email" %>
<%@ page import="oracle.apps.ibe.tcav2.Person" %>
<%@ page import="oracle.apps.ibe.tcav2.PartyManager" %>
<%@ page import="oracle.apps.ibe.tcav2.PersonManager" %>
<%@ page import="oracle.apps.ibe.um.UserManager" %>
<%@ page import="oracle.apps.jtf.security.base.SecurityManager" %>
<%@ page import="oracle.apps.fnd.common.WebAppsContext"%>
<%@ page import="oracle.apps.fnd.security.crypto.CryptoContext"%>
<%@ page import="oracle.apps.jtf.base.session.SessionManager"%>
<%@ page import="oracle.apps.ibe.util.RequestCtx"%>
<%@ page import="oracle.apps.ibe.util.Session" %>
<%@ page import="od.oracle.apps.xxcrm.asl.util.ODASLLog" %>
<%@ page import="od.oracle.apps.xxcrm.asl.util.ODASLUtil" %>
<%@ page import="od.oracle.apps.xxcrm.asl.ODASLAccountCreation" %>

<%  
StringBuffer htmlDebug = new StringBuffer();
//Do we log what we can?
boolean debugEnabled = false;
//Do we trace the SQL Session if needed
boolean sqlTraceEnabled = false;
//Declare variable for DB logging using the common logging routines
String _appName = "XXCRM";
String _progType = "E1306_OfflineAccountCreation";
String _progName = "ODaslUploadEngine.jsp";
String _moduleName = "SFA";

long filesize = 0;
String filename = "nothing";
String param = "empty";
String param1 = "empty";
String ismulti = "--";
String content = "empty";
String responseString = "";
String errorString = "";
boolean insertDocs = false;
int ac=0;
String user = "";

//java.sql.Connection connection = null;
OracleConnection connection = null;
java.sql.Statement statement = null;

boolean isMultipart = ServletFileUpload.isMultipartContent(request);

if (isMultipart) 
{
    ServletFileUpload upload = new ServletFileUpload();
    FileItemIterator iter = upload.getItemIterator(request);
    if (iter.hasNext())
    {
        FileItemStream item = iter.next();
        param = item.getFieldName();
        if (!item.isFormField()) 
        {
            try
            {
                filename = item.getName();
                InputStream uploadedStream = item.openStream();
                ac = uploadedStream.available();
                byte[] b = new byte[ac];
                filesize = ac;
                uploadedStream.read(b);
                content = new String(b);
            } catch (Exception exc)
            {
                System.out.print(exc);
                filename=exc.toString();
                responseString=responseString + "no-temp-id,E,, Error in send_data read - too many characters;";
                htmlDebug.append(exc.toString());
            }

            //excel variables            
            String temp_acct_id = "";
            String temp_doc_id = "";
            String temp_prop_id = "";
            String temp_addr_id = "";
            String username = "";
            String password = "";
            String responsibility = "";
            //XX_SOL_CDH_ACCOUNT_SETUP_REQ variables
            String REQUEST_ID = "";
            String STATUS = "";
            String REQUEST_CREATION_DATE = "";
            String STATUS_TRANSITION_DATE = "";
            String ACCOUNT_NUMBER = "";  
            String CUST_ACCOUNT_ID = ""; 
            String ACCOUNT_CREATION_SYSTEM = "";
            String BILL_TO_SITE_ID = ""; 
            String SHIP_TO_SITE_ID = ""; 
            String CREATED_BY = "";                         //shared
            String CREATION_DATE = "";                      //shared
            String LAST_UPDATED_BY = "";                    //shared
            String LAST_UPDATE_DATE = "";                   //shared
            String LAST_UPDATE_LOGIN = "";                  //shared
            String PARTY_ID = "";        
            String PO_VALIDATED = "";  
            String RELEASE_VALIDATED = "";
            String DEPARTMENT_VALIDATED = "";
            String DESKTOP_VALIDATED = "";
            String PO_HEADER = "";     
            String RELEASE_HEADER = "";
            String DEPARTMENT_HEADER = "";
            String DESKTOP_HEADER = "";
            String AFAX = "";          
            String FREIGHT_CHARGE = "";
            String FAX_ORDER = "";     
            String SUBSTITUTIONS = ""; 
            String BACK_ORDERS = "";   
            String DELIVERY_DOCUMENT_TYPE = "";
            String PRINT_INVOICE = "";  
            String DISPLAY_BACK_ORDER = "";
            String RENAME_PACKING_LIST = "";
            String DISPLAY_PURCHASE_ORDER = "";
            String DISPLAY_PAYMENT_METHOD = "";
            String DISPLAY_PRICES = ""; 
            String PROCUREMENT_CARD = "";
            String PAYMENT_METHOD = "";
            String AP_CONTACT = "";    
            String COMMENTS = "";                                
            String OrganizationName = "";
            String Country = "";
            String PhoneCountryCode = "";
            String PhoneAreaCode = "";
            String PhoneNumber = "";
            String Extension = "";
            String Prefix = "";
            String FirstName = "";
            String MiddleName = "";
            String LastName = "";
            // Address api call variables
            String addr_type = "";
            String country = "";
            String p_org_name = "";
            String p_person_title = "";
            String p_person_first_name = "";
            String p_person_middle_name = "";
            String p_person_last_name = "";
            String p_bt_address1 = "";
            String p_bt_address2 = "";
            String p_bt_address3 = "";
            String p_bt_address4 = "";
            String p_bt_city = "";
            String p_bt_county = "";
            String p_bt_state = "";
            String p_bt_postal_code = "";
			String p_bt_country = "";
            String p_bt_address_style = "";
            String p_bt_address_lines_phonetic = "";
            String p_bt_addressee = "";
            String p_st_address1 = "";
            String p_st_address2 = "";
            String p_st_address3 = "";
            String p_st_address4 = "";
            String p_st_city = "";
            String p_st_county = "";
            String p_st_state = "";
            String p_st_postal_code = "";
			String p_st_country = "";
            String p_st_address_style = "";
            String p_st_address_lines_phonetic = "";
            String p_st_addressee = "";
            String p_phone_ccode = "";                
            String p_phone_acode = "";                
            String p_phone_number = "";               
            String p_phone_ext = "";                  
            String x_return_status = "";
            int x_msg_count = 0;
            String x_msg_data = "";
            //XX_CDH_ACCT_SETUP_DOCUMENTS variables
            String ACCOUNT_REQUEST_ID = "";
            String DOCUMENT_ID = "";     
            String DOCUMENT_TYPE = ""; 
            String DOCUMENT_NAME = ""; 
            String DETAIL = "";         
            String FREQUENCY = "";     
            String INDIRECT = "";       
            String INCL_BACKUP_INV = "";
            //XX_CDH_ACCT_SETUP_DOC_PROPERTY variables
            String DOC_PROPERTY_ID = ""; 
            String PROPERTY_TYPE = ""; 
            String PROPERTY_VALUE = "";
            String sorts = "";
            String totals = "";
            String pgbrks = "";

            //OD WCW attributes
            String p_bt_od_wcw = "";
            String p_st_od_wcw = "";

            try
            { 
                //Get the User Name
                int uid = content.indexOf("id=");
                String uids = content.substring(uid+3,content.length());
                int uidsc = uids.indexOf(";");
                username = uids.substring(0, uidsc).trim();        
                //Get Password
                int pwd = content.indexOf("pwd=");
                String pwds = content.substring(pwd+4,content.length());
                int pwdsc = pwds.indexOf(";");
                password = pwds.substring(0, pwdsc).trim();        
                //Decrypt Password
                password = ODASLUtil.decryptPassword(password);
                int rsp = content.indexOf("rsp=");
                String rsps = content.substring(rsp+4,content.length());
                int rspsc = rsps.indexOf(";");
                responsibility = rsps.substring(0, rspsc).trim();        

                //int ustatus= 
                //Login the user based on provided credentials
                Session.login(request, response, username, password ,null);

                Object lockx = new Object();
                TransactionScope.begin(lockx);
                connection = (OracleConnection) TransactionScope.getConnection();

                try 
                {
                    username = ODASLUtil.getUserId(connection, username);
                } catch (SQLException sqle)
                {
                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "SQL Exception Getting user_id for: " + username + "..." + sqle.toString(), ODASLLog.LOG_SEV_MAJOR);
                }

                int iAppid = ODASLUtil.getApplicationId(connection, responsibility);
                int iRespid = ODASLUtil.getResponsibilityId(connection, responsibility);
                            
                ODASLUtil.appsInit(connection, username, new Integer(iRespid).toString(), new Integer(iAppid).toString());
                if (debugEnabled)
                {
                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "AppsInited for User/Resp/App: " + username + "|" + iRespid + "|" + iAppid, ODASLLog.LOG_SEV_MINOR);
                }
                
                //Check for Logging and SQL Trace
                debugEnabled = ODASLUtil.isOfflineLogEnabled(connection);
                if (debugEnabled)
                {
                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Debug Enabled", ODASLLog.LOG_SEV_MINOR);
                }
                sqlTraceEnabled = ODASLUtil.isOfflineSQLTraceEnabled(connection);
                //Enabled tracing if it was turned on for debugging on this instance
                if (sqlTraceEnabled)
                {
                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Trace Enabled", ODASLLog.LOG_SEV_MINOR);                
                    ODASLUtil.enableSQLTrace(connection);
                }
                if (debugEnabled)
                {
                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Begin", ODASLLog.LOG_SEV_MINOR);
                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "User: " + username, ODASLLog.LOG_SEV_MINOR);
                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Responsibility Key: " + responsibility, ODASLLog.LOG_SEV_MINOR);
                }
                if (debugEnabled)
                {
                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "User id: " + username, ODASLLog.LOG_SEV_MINOR);
                }

                StringTokenizer  strtok  = new StringTokenizer(content, ",");

                while (strtok.hasMoreTokens())
                {
                    String tok = strtok.nextToken().replaceAll("\"", "");
                    if (tok.equals("Account.csv")) 
                    {
                        if (debugEnabled)
                        {
                            ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Token 1: Accounts.csv", ODASLLog.LOG_SEV_MINOR);
                        }
                        insertDocs = false;
                        temp_acct_id            = strtok.nextToken().replaceAll("\"", "");     
                        STATUS                  = strtok.nextToken().replaceAll("\"", "");     
                        REQUEST_CREATION_DATE   = strtok.nextToken().replaceAll("\"", "");     
                        STATUS_TRANSITION_DATE  = " sysdate ";
                        ACCOUNT_NUMBER          = ""; // from BPEL process
                        CUST_ACCOUNT_ID         = ""; // from BPEL process
                        ACCOUNT_CREATION_SYSTEM = ""; // from BPEL process
                        BILL_TO_SITE_ID         = "null"; // pick up from api
                        SHIP_TO_SITE_ID         = "null"; // pick up from api
                        CREATED_BY              = username;
                        CREATION_DATE           = " sysdate ";
                        LAST_UPDATED_BY         = username;
                        LAST_UPDATE_DATE        = " sysdate ";
                        LAST_UPDATE_LOGIN       = username;
                        PARTY_ID                = "null"; // pick up from api
                        PO_VALIDATED            = strtok.nextToken().replaceAll("\"", "");
                        RELEASE_VALIDATED       = strtok.nextToken().replaceAll("\"", "");
                        DEPARTMENT_VALIDATED    = strtok.nextToken().replaceAll("\"", "");
                        DESKTOP_VALIDATED       = strtok.nextToken().replaceAll("\"", "");  
                        PO_HEADER               = strtok.nextToken().replaceAll("\"", "");
                        RELEASE_HEADER          = strtok.nextToken().replaceAll("\"", "");
                        DEPARTMENT_HEADER       = strtok.nextToken().replaceAll("\"", "");
                        DESKTOP_HEADER          = strtok.nextToken().replaceAll("\"", "");
                        AFAX                    = strtok.nextToken().replaceAll("\"", "");
                        FREIGHT_CHARGE          = strtok.nextToken().replaceAll("\"", "");
                        FAX_ORDER               = strtok.nextToken().replaceAll("\"", "");
                        SUBSTITUTIONS           = strtok.nextToken().replaceAll("\"", "");
                        BACK_ORDERS             = strtok.nextToken().replaceAll("\"", "");
                        DELIVERY_DOCUMENT_TYPE  = strtok.nextToken().replaceAll("\"", "");
                        PRINT_INVOICE           = strtok.nextToken().replaceAll("\"", "");
                        DISPLAY_BACK_ORDER      = strtok.nextToken().replaceAll("\"", "");
                        RENAME_PACKING_LIST     = strtok.nextToken().replaceAll("\"", "");
                        DISPLAY_PURCHASE_ORDER  = strtok.nextToken().replaceAll("\"", "");
                        DISPLAY_PAYMENT_METHOD  = strtok.nextToken().replaceAll("\"", "");
                        DISPLAY_PRICES          = strtok.nextToken().replaceAll("\"", "");
                        PROCUREMENT_CARD        = strtok.nextToken().replaceAll("\"", "");
                        PAYMENT_METHOD          = strtok.nextToken().replaceAll("\"", "");
                        AP_CONTACT              = "null"; // pick up from api
                        //COMMENTS                = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                        OrganizationName        = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                        Country                 = strtok.nextToken().replaceAll("\"", "");
                        PhoneCountryCode        = strtok.nextToken().replaceAll("\"", "");  
                        PhoneAreaCode           = strtok.nextToken().replaceAll("\"", "");
                        PhoneNumber             = strtok.nextToken().replaceAll("\"", "");
                        Extension               = strtok.nextToken().replaceAll("\"", "");
                        Prefix                  = strtok.nextToken().replaceAll("\"", "");
                        FirstName               = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                        MiddleName              = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                        LastName                = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                        p_org_name = OrganizationName;
                        p_person_title = Prefix;
                        p_person_first_name = FirstName;
                        p_person_middle_name = MiddleName;
                        p_person_last_name = LastName;
                        p_phone_ccode = PhoneCountryCode;               
                        p_phone_acode = PhoneAreaCode;               
                        p_phone_number = PhoneNumber;              
                        p_phone_ext = Extension;                 

                        //Address and api calls go here
                        tok = strtok.nextToken().replaceAll("\"", "");
                        if (tok.equals("Address.csv")) 
                        {
                            if (debugEnabled)
                            {
                                ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Token 2: Address.csv", ODASLLog.LOG_SEV_MINOR);
                            }
                            temp_addr_id = strtok.nextToken().replaceAll("\"", "");
                            addr_type = strtok.nextToken().replaceAll("\"", ""); 
                            p_bt_country = strtok.nextToken().replaceAll("\"", ""); 
                            p_bt_address1 = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                            p_bt_address2 = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                            p_bt_address3 = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                            p_bt_address4 = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                            p_bt_city = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                            p_bt_county = strtok.nextToken().replaceAll("\"", "");
                            p_bt_state = strtok.nextToken().replaceAll("\"", "");
                            p_bt_postal_code = strtok.nextToken().replaceAll("\"", "");
                            p_bt_address_style = strtok.nextToken().replaceAll("\"", "");
                            p_bt_address_lines_phonetic = strtok.nextToken().replaceAll("\"", "");
                            p_bt_addressee = strtok.nextToken().replaceAll("\"", "");
                            p_bt_od_wcw = strtok.nextToken().replaceAll("\"", "");
                        }
                        tok = strtok.nextToken().replaceAll("\"", "");
                        if (tok.equals("Address.csv")) 
                        {
                            if (debugEnabled)
                            {
                                ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Token 3: Address.csv", ODASLLog.LOG_SEV_MINOR);
                            }
                            temp_addr_id = strtok.nextToken().replaceAll("\"", "");
                            addr_type = strtok.nextToken().replaceAll("\"", ""); 
                            p_st_country = strtok.nextToken().replaceAll("\"", ""); 
                            p_st_address1 = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                            p_st_address2 = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                            p_st_address3 = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                            p_st_address4 = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                            p_st_city = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");
                            p_st_county = strtok.nextToken().replaceAll("\"", "");
                            p_st_state = strtok.nextToken().replaceAll("\"", "");
                            p_st_postal_code = strtok.nextToken().replaceAll("\"", "");
                            p_st_address_style = strtok.nextToken().replaceAll("\"", "");
                            p_st_address_lines_phonetic = strtok.nextToken().replaceAll("\"", "");
                            p_st_addressee = strtok.nextToken().replaceAll("\"", "");
                            p_st_od_wcw = strtok.nextToken().replaceAll("\"", "");
                        }
                        try 
                        {
                            

                            String existingRequestId = ODASLAccountCreation.getRequestId(connection, temp_acct_id);
                            if (debugEnabled)
                            {
                                ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "ReqId|TempRequest Id is: " + existingRequestId + "|" + temp_acct_id, ODASLLog.LOG_SEV_MINOR);
                            }
                            
                            if ("".equals(existingRequestId))
                            {
                                if (debugEnabled)
                                {
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Calling XX_ASL_ACC_CRT_UTIL_PKG.P_Create_Entities", ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Org, Person: " + p_org_name + "|" + p_person_title + "|" + p_person_first_name + "|" + p_person_middle_name + "|" + p_person_last_name, ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Bill To: " + p_bt_address1 + "|" + p_bt_address2 + "|" + p_bt_address3 + "|" + p_bt_address4, ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Bill To: " + p_bt_city + "|" + p_bt_county + "|" + p_bt_state + "|" + p_bt_postal_code, ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Bill To: " + p_st_address1 + "|" + p_st_address2 + "|" + p_st_address3 + "|" + p_st_address4, ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Bill To: " + p_st_city + "|" + p_st_county + "|" + p_st_state + "|" + p_st_postal_code, ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "WCW: B/S: " + p_bt_od_wcw + "|" + p_st_od_wcw, ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Phone: " + p_phone_ccode + "|" + p_phone_acode + "|" + p_phone_number + "|" + p_phone_ext, ODASLLog.LOG_SEV_MINOR);
                                }
								//change to add the country in the call - Prabha
                                HashMap h = ODASLAccountCreation.createEntities(connection, p_org_name,p_bt_country, p_person_title, p_person_first_name, p_person_middle_name, p_person_last_name, p_bt_address1, p_bt_address2, p_bt_address3, p_bt_address4, p_bt_city, p_bt_county, p_bt_state, p_bt_postal_code, p_bt_address_style, p_bt_address_lines_phonetic, p_bt_addressee, p_bt_od_wcw, p_st_address1, p_st_address2, p_st_address3, p_st_address4, p_st_city, p_st_county, p_st_state, p_st_postal_code,p_st_country, p_st_address_style, p_st_address_lines_phonetic, p_st_addressee, p_st_od_wcw, p_phone_ccode, p_phone_acode, p_phone_number, p_phone_ext);
                                try { PARTY_ID = h.get(ODASLAccountCreation.PARTY_ID).toString(); } catch (Exception e) { PARTY_ID = "0"; }
                                try { AP_CONTACT = h.get(ODASLAccountCreation.CONTACT_ID).toString();  } catch (Exception e) { AP_CONTACT = "0"; }
                                try { BILL_TO_SITE_ID = h.get(ODASLAccountCreation.BILL_TO_SITE_ID).toString(); } catch (Exception e) { BILL_TO_SITE_ID = "0"; }
                                try { SHIP_TO_SITE_ID = h.get(ODASLAccountCreation.SHIP_TO_SITE_ID).toString();  } catch (Exception e) { SHIP_TO_SITE_ID = "0"; }

                                int iPARTY_ID = Integer.parseInt(PARTY_ID);
                                int iAP_CONTACT = Integer.parseInt(AP_CONTACT);                
                                int iBILL_TO_SITE_ID = Integer.parseInt(BILL_TO_SITE_ID);
                                int iSHIP_TO_SITE_ID = Integer.parseInt(SHIP_TO_SITE_ID);
                                try { x_return_status = h.get(ODASLAccountCreation.RETURN_STATUS).toString();   } catch (Exception e) { x_return_status = ""; }
                                try { x_msg_data = h.get(ODASLAccountCreation.ERROR_MESSAGE).toString();  } catch (Exception e) { x_msg_data = ""; }

                                if (debugEnabled)
                                {
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "XX_ASL_ACC_CRT_UTIL_PKG.P_Create_Entities Done", ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "PartyId: " + iPARTY_ID, ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "ApContact: " + iAP_CONTACT, ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "BillTo: " + iBILL_TO_SITE_ID, ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "ShipTo: " + iSHIP_TO_SITE_ID, ODASLLog.LOG_SEV_MINOR);
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Status|Message: " + x_return_status + "|" + x_msg_data, ODASLLog.LOG_SEV_MINOR);
                                }

                                REQUEST_ID = ODASLAccountCreation.getNextRequestId(connection);
                                if (debugEnabled)
                                {
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "New Request Id: " + REQUEST_ID, ODASLLog.LOG_SEV_MINOR);
                                }
  
                                if (iPARTY_ID != 0)
                                {
                                    ODASLAccountCreation.insertSetupRequest(connection, REQUEST_ID, STATUS, new java.sql.Timestamp(System.currentTimeMillis()), BILL_TO_SITE_ID, SHIP_TO_SITE_ID, CREATED_BY, new java.sql.Timestamp(System.currentTimeMillis()), LAST_UPDATED_BY, new java.sql.Timestamp(System.currentTimeMillis()), LAST_UPDATE_LOGIN, PARTY_ID, PO_VALIDATED, RELEASE_VALIDATED, DEPARTMENT_VALIDATED, DESKTOP_VALIDATED, PO_HEADER, RELEASE_HEADER, DEPARTMENT_HEADER, DESKTOP_HEADER, AFAX, FREIGHT_CHARGE, FAX_ORDER, SUBSTITUTIONS, BACK_ORDERS, DELIVERY_DOCUMENT_TYPE, PRINT_INVOICE, DISPLAY_BACK_ORDER, RENAME_PACKING_LIST, DISPLAY_PURCHASE_ORDER, DISPLAY_PAYMENT_METHOD, DISPLAY_PRICES, PROCUREMENT_CARD, PAYMENT_METHOD, AP_CONTACT, "Y", "ASL", temp_acct_id, "N");
                                    connection.commit();
                                    if (debugEnabled)
                                    {
                                        ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Insert Completed.", ODASLLog.LOG_SEV_MINOR);
                                    }
                                    insertDocs = true;
                                    responseString = responseString + temp_acct_id + ",S," + REQUEST_ID + ",;";
                                } 
                                else 
                                {
                                    responseString=responseString + temp_acct_id + ",E,," + x_return_status + ";";                   
                                }
                            } 
                            else 
                            {
                                responseString=responseString + temp_acct_id + ",U," + existingRequestId + ", Uploaded Already;";
                            }// endif for checking tempid / ASL
                        } catch (SQLException sqle)
                        {
                            ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "SQL Exception: "  + sqle.toString(), ODASLLog.LOG_SEV_MAJOR);
                            filename=sqle.toString();
                            responseString=responseString + temp_acct_id + ",E," + ", Error in Account Insert;";                   
                        } catch (Exception exc)
                        {
                            ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Generic Exception: "  + exc.toString(), ODASLLog.LOG_SEV_MAJOR);
                            filename=exc.toString();
                            responseString=responseString + temp_acct_id + ",E," + ", Error in Account Insert;";                                   
                        }
                    } 
                    else
                    {
                        if (tok.equals("Comments.csv")) 
                        {
                            if (debugEnabled)
                            {
                                ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Token 4: Comments.csv", ODASLLog.LOG_SEV_MINOR);
                            }
                                 
                            temp_acct_id = strtok.nextToken().replaceAll("\"", "");     
                            String next = strtok.nextToken().replaceAll("\"", "");
                            COMMENTS = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"").replaceAll("'","");
                            if (!next.equals("n"))
                            {
                                REQUEST_ID = next;     
                                responseString = responseString + temp_acct_id + ",S," + REQUEST_ID + ", Appended Comments;";
                            } //else REQUEST_ID = REQUEST_ID                
                
                            try 
                            {
                                if (debugEnabled)
                                {
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Updating Commnets" + COMMENTS, ODASLLog.LOG_SEV_MINOR);
                                }
                                ODASLAccountCreation.updateRequest(connection, REQUEST_ID, COMMENTS);
                                connection.commit();
                            } catch (SQLException sqle)
                            {
                                ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Updating Commnets" + COMMENTS, ODASLLog.LOG_SEV_MAJOR);
                                filename=sqle.toString();
                                responseString=responseString + temp_acct_id + ",E," + ", Error in Comments Update;";                   
                            } 
                        } 
                        else 
                        {
                            if (tok.equals("Document.csv")) 
                            {
                                if (debugEnabled)
                                {
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Token 5. Document.csv", ODASLLog.LOG_SEV_MINOR);
                                }
                            
                                String temp_req_id = "";
                                try 
                                {
                                    if (strtok.hasMoreTokens()) {temp_acct_id     = strtok.nextToken().replaceAll("\"", ""); }
                                    if (strtok.hasMoreTokens()) {temp_doc_id      = strtok.nextToken().replaceAll("\"", ""); }
                                    if (strtok.hasMoreTokens()) {temp_req_id      = strtok.nextToken().replaceAll("\"", ""); }
                                    if (strtok.hasMoreTokens()) {DOCUMENT_TYPE    = strtok.nextToken().replaceAll("\"", "");}
                                    if (strtok.hasMoreTokens()) {DOCUMENT_NAME    = strtok.nextToken().replaceAll("\"", "").replaceAll("%21",",").replaceAll("%22","\"");}
                                    if (strtok.hasMoreTokens()) {DETAIL           = strtok.nextToken().replaceAll("\"", "");}
                                    if (strtok.hasMoreTokens()) {FREQUENCY        = strtok.nextToken().replaceAll("\"", "");}
                                    if (strtok.hasMoreTokens()) {INDIRECT         = strtok.nextToken().replaceAll("\"", "");}
                                    if (strtok.hasMoreTokens()) {INCL_BACKUP_INV  = strtok.nextToken().replaceAll("\"", "");}
                                    if (strtok.hasMoreTokens()) {sorts            = strtok.nextToken().replaceAll("\"", ""); }
                                    if (strtok.hasMoreTokens()) {totals           = strtok.nextToken().replaceAll("\"", "");}
                                    if (strtok.hasMoreTokens()) {pgbrks           = strtok.nextToken().replaceAll("\"", "");}
                                    if (!temp_req_id.equals("n"))
                                    {
                                        REQUEST_ID = temp_req_id;
                                        CREATED_BY              = username;
                                        CREATION_DATE           = " sysdate ";
                                        LAST_UPDATED_BY         = username;
                                        LAST_UPDATE_DATE        = " sysdate ";
                                        LAST_UPDATE_LOGIN       = username;
                                    }
                                    if (!DOCUMENT_NAME.equals("<-dd->")) 
                                    {
                                        //statement = connection.createStatement();
                    
                                        /*
                                        String seq = "select XXCRM.XX_CDH_ACCT_SETUP_DOCUMENTS_S.nextval from dual";
                                        ResultSet results = statement.executeQuery(seq);
                                        results.next();
                                        DOCUMENT_ID = results.getString(1);
                                        */
                                        DOCUMENT_ID = ODASLAccountCreation.getNextDocumentId(connection);
                                        if (debugEnabled)
                                        {
                                            ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Document Id: " + DOCUMENT_ID, ODASLLog.LOG_SEV_MINOR);
                                        }
                                        ODASLAccountCreation.insertSetupDocument(connection, REQUEST_ID, DOCUMENT_ID, DOCUMENT_TYPE, DOCUMENT_NAME, DETAIL, FREQUENCY, INDIRECT, INCL_BACKUP_INV, CREATED_BY, new java.sql.Timestamp(System.currentTimeMillis()), "N", LAST_UPDATED_BY, new java.sql.Timestamp(System.currentTimeMillis()));
                                        if (debugEnabled)
                                        {
                                            ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Document inserted." + DOCUMENT_ID, ODASLLog.LOG_SEV_MINOR);
                                        }
                                        connection.commit();
                                    } // end <-dd->
                                } catch (SQLException sqle)
                                {
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "SQL Exception inserting in XX_CDH_ACCT_SETUP_DOCUMENTS: " + sqle.toString(), ODASLLog.LOG_SEV_MEDIUM);
                                    filename=sqle.toString();
                                    user = REQUEST_ID;
                                    responseString=responseString + temp_acct_id + ",E," + ", Error in Document Insert;";
                                } catch (NoSuchElementException nse)
                                {
                                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "NoSuchElement Exception for XX_CDH_ACCT_SETUP_DOCUMENTS: " + nse.toString(), ODASLLog.LOG_SEV_MEDIUM);
                                    filename=nse.toString();
                                    responseString=responseString + temp_acct_id + ",E," + ", Error in Document Properties;";                   
                                }
                            }
                        }
                    }
                }
                if (debugEnabled)
                {
                    ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Response: " + responseString, ODASLLog.LOG_SEV_MINOR);
                }                
                connection.commit();
                TransactionScope.releaseConnection(connection);
            } catch (NoSuchElementException nse)
            {
                ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "NoSuchElement Exception for main section: " + nse.toString(), ODASLLog.LOG_SEV_MAJOR);
            } catch (SQLException sqle2) 
            {
                ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "SQL Exception in main code: " + sqle2.toString(), ODASLLog.LOG_SEV_MAJOR);
                responseString=responseString + temp_acct_id + ",E," + ", Error in Insert;";                       
            }
        }
    } 
    else 
    {
        if (debugEnabled)
        {
            ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "No More Tokens", ODASLLog.LOG_SEV_MEDIUM);
        }
        param = "none";
    }
}         
else 
{
    ismulti = "false";
    if (debugEnabled)
    {
        ODASLLog.logToDatabase(connection, _appName, _progType, _progName, _moduleName, "JSP", "", "Not a multipart request.", ODASLLog.LOG_SEV_MEDIUM);
    }
}
%>
<html> <head>
    <meta http-equiv="Content-Type" content="text/html; charset=windows-1252"/>
    <title>ODaslUpdateEngine</title>
  </head>
  <body> 
    <P> filename: <%=filename%>    
    REQUEST_ID_STRING: <%=responseString%>
    SQL: <jsp:expression>param</jsp:expression>
    </P> 
  </body>
</html>
