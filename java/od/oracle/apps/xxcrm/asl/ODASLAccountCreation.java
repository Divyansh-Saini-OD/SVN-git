package od.oracle.apps.xxcrm.asl;

import oracle.jdbc.driver.OracleConnection;
import java.sql.ResultSet;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.Types;
import java.util.HashMap;

import od.oracle.apps.xxcrm.asl.util.ODASLLog;

public class ODASLAccountCreation
{
    public static String PARTY_ID = "PARTY_ID";
    public static String CONTACT_ID = "CONTACT_ID";
    public static String CONTACT_PARTY_ID = "CONTACT_PARTY_ID";
    public static String BILL_TO_SITE_ID= "BILL_TO_SITE_ID";
    public static String SHIP_TO_SITE_ID  = "SHIP_TO_SITE_ID";
    public static String RETURN_STATUS = "RETURN_STATUS";
    public static String ERROR_MESSAGE = "ERROR_MESSAGE";

    public static String getRequestId(OracleConnection conn, String tempRequestId)
    {
        String requestId = "";
        try
        {
            PreparedStatement statement = conn.prepareStatement("select request_id from XX_CDH_ACCOUNT_SETUP_REQ where attribute1 = ? and trunc(creation_date) = trunc(sysdate)");
            statement.setString(1, tempRequestId);
            ResultSet r = statement.executeQuery();
            while (r.next())
            {
                requestId = r.getString(1);
            }
            statement.close();
        }catch (Exception e)
        {
            requestId = "";
            ODASLLog.logToDatabase(conn, "XXCRM", "E1306_OfflineAccountCreation", "ODASLAccountCreation.java", "SFA", "getRequestId", "", "Exception: " + e.toString(), ODASLLog.LOG_SEV_MAJOR);
        }
        return requestId;
    }

    public static HashMap createEntities(OracleConnection conn,
            String orgName,String btcountry,
            String personTitle, String personFirstName, String personMiddleName, String personLastName,
            String btAddress1, String btAddress2, String btAddress3, String btAddress4,
            String btCity, String btCounty, String btState, String btPostalCode,
            String btAddressStyle, String btAddressPhonetic, String btAddressee,
            String btWCW,
            String stAddress1, String stAddress2, String stAddress3, String stAddress4,
            String stCity, String stCounty, String stState, String stPostalCode,String stcountry,
            String stAddressStyle, String stAddressPhonetic, String stAddressee,
            String stWCW,
            String phoneCountryCode, String phoneAreaCode, String phoneNumber, String phoneExtension)
    throws Exception
    {
        HashMap h = new HashMap();

        CallableStatement statement = conn.prepareCall("begin XX_ASL_ACC_CRT_UTIL_PKG.P_Create_Entities(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?); end;");
        statement.setString(1, orgName);
		statement.setString(2, btcountry);
        statement.setString(3, personTitle);
        statement.setString(4, personFirstName);
        statement.setString(5, personMiddleName);
        statement.setString(6, personLastName);
        statement.setString(7, btAddress1);
        statement.setString(8, btAddress2);
        statement.setString(9, btAddress3);
        statement.setString(10, btAddress4);
        statement.setString(11, btCity);
        statement.setString(12, btCounty);
        statement.setString(13, btState);
        statement.setString(14, btPostalCode);
        statement.setString(15, btAddressStyle);
        statement.setString(16, btAddressPhonetic);
        statement.setString(17, btAddressee);
        statement.setString(18, btWCW);
        statement.setString(19, stAddress1);
        statement.setString(20, stAddress2);
        statement.setString(21, stAddress3);
        statement.setString(22, stAddress4);
        statement.setString(23, stCity);
        statement.setString(24, stCounty);
        statement.setString(25, stState);
        statement.setString(26, stPostalCode);
		statement.setString(27, stcountry);
        statement.setString(28, stAddressStyle);
        statement.setString(29, stAddressPhonetic);
        statement.setString(30, stAddressee);
        statement.setString(31, stWCW);
        statement.setString(32, phoneCountryCode);
        statement.setString(33, phoneAreaCode);
        statement.setString(34, phoneNumber);
        statement.setString(35, phoneExtension);

        statement.registerOutParameter(36, Types.INTEGER);
        statement.registerOutParameter(37, Types.INTEGER);
        statement.registerOutParameter(38, Types.INTEGER);
        statement.registerOutParameter(39, Types.INTEGER);
        statement.registerOutParameter(40, Types.INTEGER);
        statement.registerOutParameter(41, Types.VARCHAR);
        statement.registerOutParameter(42, Types.VARCHAR);

        statement.execute();

        h.put(PARTY_ID, "" + statement.getInt(36));
        h.put(CONTACT_ID, "" + statement.getInt(37));
        h.put(CONTACT_PARTY_ID, "" + statement.getInt(38));
        h.put(BILL_TO_SITE_ID, "" + statement.getInt(39));
        h.put(SHIP_TO_SITE_ID, "" + statement.getInt(40));
        h.put(RETURN_STATUS, statement.getString(41));
        h.put(ERROR_MESSAGE, statement.getString(42));

        statement.close();
        return h;
    }

    public static String getNextDocumentId(OracleConnection conn) throws Exception
    {
        String seqValue = "0";
        PreparedStatement stmt =conn.prepareStatement("select XX_CDH_ACCT_SETUP_DOCUMENTS_S.nextval from dual");
        ResultSet r = stmt.executeQuery();
        while (r.next())
        {
            seqValue = r.getString(1);
        }
        stmt.close();
        return seqValue;
    }


    public static String getNextRequestId(OracleConnection conn) throws Exception
    {
        String seqValue = "0";
        PreparedStatement stmt =conn.prepareStatement("select XX_CDH_ACCOUNT_SETUP_REQ_S.nextval from dual");
        ResultSet r = stmt.executeQuery();
        while (r.next())
        {
            seqValue = r.getString(1);
        }
        stmt.close();
        return seqValue;
    }
    public static void insertSetupDocument(OracleConnection conn,
        String accountRequestId,
        String documentId,
        String documentType,
        String documentName,
        String detail,
        String frequency,
        String indirect,
        String inclBackupEnv,
        String createdBy,
        java.sql.Timestamp creationDate,
        String deleteFlag,
        String lastUpdatedBy,
        java.sql.Timestamp lastUpdateDate) throws Exception
    {
        StringBuffer sql = new StringBuffer();
        sql.append("INSERT INTO XX_CDH_ACCT_SETUP_DOCUMENTS   ( ");
        sql.append("ACCOUNT_REQUEST_ID, DOCUMENT_ID, DOCUMENT_TYPE, DOCUMENT_NAME, ");
        sql.append("DETAIL, FREQUENCY, INDIRECT, INCL_BACKUP_INV, ");
        sql.append("CREATED_BY, CREATION_DATE, DELETE_FLAG, LAST_UPDATED_BY, LAST_UPDATE_DATE ) ");
        sql.append("VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");

        PreparedStatement stmt = conn.prepareStatement(sql.toString());
        stmt.setString(1, accountRequestId);
        stmt.setString(2, documentId);
        stmt.setString(3, documentType);
        stmt.setString(4, documentName);
        stmt.setString(5, detail);
        stmt.setString(6, frequency);
        stmt.setString(7, indirect);
        stmt.setString(8, inclBackupEnv);
        stmt.setString(9, createdBy);
        stmt.setTimestamp(10, creationDate);
        stmt.setString(11, deleteFlag);
        stmt.setString(12, lastUpdatedBy);
        stmt.setTimestamp(13, lastUpdateDate);
        stmt.executeQuery();
        stmt.close();
    }

    public static void insertSetupRequest(OracleConnection conn,
        String requestId,
        String status,
        java.sql.Timestamp statusTransitionDate,
        String btSiteId,
        String stSiteId,
        String createdBy,
        java.sql.Timestamp creationDate,
        String lastUpdatedBy,
        java.sql.Timestamp lastUpdateDate,
        String lastUpdateLogin,
        String partyId,
        String poValidated,
        String releaseValidated,
        String departmentValidated,
        String desktopValidated,
        String poHeader,
        String releaseHeader,
        String departmentHeader,
        String desktopHeader,
        String aFax,
        String freightCharge,
        String faxOrder,
        String substitutions,
        String backOrders,
        String deliveryDocumentType,
        String printInvoice,
        String displayBackOrder,
        String renamePackingList,
        String displayPurchaseOrder,
        String displayPaymentMethod,
        String displayPrices,
        String procurementCard,
        String paymentMethod,
        String apContact,
        String offlineCreatedFlag,
        String attributeCategory,
        String attribute1,
        String deleteFlag) throws Exception
    {
        StringBuffer sql = new StringBuffer();
        sql.append("INSERT INTO XX_CDH_ACCOUNT_SETUP_REQ ( ");
        sql.append("REQUEST_ID, STATUS, STATUS_TRANSITION_DATE, BILL_TO_SITE_ID, ");
        sql.append("SHIP_TO_SITE_ID, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, ");
        sql.append("LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, PARTY_ID, PO_VALIDATED, ");
        sql.append("RELEASE_VALIDATED, DEPARTMENT_VALIDATED, DESKTOP_VALIDATED, PO_HEADER, ");
        sql.append("RELEASE_HEADER, DEPARTMENT_HEADER, DESKTOP_HEADER, AFAX, ");
        sql.append("FREIGHT_CHARGE, FAX_ORDER, SUBSTITUTIONS, BACK_ORDERS, ");
        sql.append("DELIVERY_DOCUMENT_TYPE, PRINT_INVOICE, DISPLAY_BACK_ORDER, RENAME_PACKING_LIST, ");
        sql.append("DISPLAY_PURCHASE_ORDER, DISPLAY_PAYMENT_METHOD, DISPLAY_PRICES, PROCUREMENT_CARD, ");
        sql.append("PAYMENT_METHOD, AP_CONTACT, OFFLINE_CREATED_FLAG, ATTRIBUTE_CATEGORY, ");
        sql.append("ATTRIBUTE1, DELETE_FLAG )" );
        sql.append("VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");

        PreparedStatement stmt = conn.prepareStatement(sql.toString());
        stmt.setString(1, requestId);
        stmt.setString(2, status);
        stmt.setTimestamp(3, statusTransitionDate);
        stmt.setString(4, btSiteId);
        stmt.setString(5, stSiteId);
        stmt.setString(6, createdBy);
        stmt.setTimestamp(7, creationDate);
        stmt.setString(8, lastUpdatedBy);
        stmt.setTimestamp(9, lastUpdateDate);
        stmt.setString(10, lastUpdateLogin);
        stmt.setString(11, partyId);
        stmt.setString(12, poValidated);
        stmt.setString(13, releaseValidated);
        stmt.setString(14, departmentValidated);
        stmt.setString(15, desktopValidated);
        stmt.setString(16, poHeader);
        stmt.setString(17, releaseHeader);
        stmt.setString(18, departmentHeader);
        stmt.setString(19, desktopHeader);
        stmt.setString(20, aFax);
        stmt.setString(21, freightCharge);
        stmt.setString(22, faxOrder);
        stmt.setString(23, substitutions);
        stmt.setString(24, backOrders);
        stmt.setString(25, deliveryDocumentType);
        stmt.setString(26, printInvoice);
        stmt.setString(27, displayBackOrder);
        stmt.setString(28, renamePackingList);
        stmt.setString(29, displayPurchaseOrder);
        stmt.setString(30, displayPaymentMethod);
        stmt.setString(31, displayPrices);
        stmt.setString(32, procurementCard);
        stmt.setString(33, paymentMethod);
        stmt.setString(34, apContact);
        stmt.setString(35, offlineCreatedFlag);
        stmt.setString(36, attributeCategory);
        stmt.setString(37, attribute1);
        stmt.setString(38, deleteFlag);

        stmt.executeQuery();
        stmt.close();
    }

    public static void updateRequest(OracleConnection conn, String requestId, String comments) throws Exception
    {
        PreparedStatement stmt = conn.prepareStatement("update XX_CDH_ACCOUNT_SETUP_REQ set COMMENTS = COMMENTS|| ? WHERE REQUEST_ID = ?");
        stmt.setString(1, comments);
        stmt.setString(2, requestId);
        ResultSet r = stmt.executeQuery();
        stmt.close();
    }
}

