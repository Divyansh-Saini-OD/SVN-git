/*
 --  Copyright (c) 2005, by Office Depot., All Rights Reserved
 --
 -- Author: Sridevi Kondoju
 -- Component Id: E1356 CR1120
 -- Script Location:
            $CUSTOM_JAVA_TOP/od/oracle/apps/xxfin/ar/irec/accountDetails/pay/webui
 -- Description: Helper class used in custom controller classes (ODPaymentFormCO) for calling custom
 --              database package
 -- Package Usage       : Unrestricted. Used for calling custom database package
 -- Name                  Type         Purpose
 -- --------------------  -----------  ------------------------------------------
 --
 -- Notes:
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 25-MAR-2015  1.0        Initial version
 -- Sridevi Kondoju 10-MAY-2015  1.1        Added Email validation method
 --
 */
package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.webui;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAPageContext;
import java.util.regex.*;

/**
 * Helper class for custom controller  
 */
public class ODPaymentHelper {
    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");


    String ccflag = null;
    String achflag = null;
    String custAcctId = null;

    /**
     * Constructor method
     */
    public ODPaymentHelper() {
    }

    /**
     * Overloading constructor method with parameters
     * @param sourceEvent source corresponding to page
     */
    public ODPaymentHelper(String custAcctId) {
        this.ccflag = "N";
        this.achflag = "N";
        this.custAcctId = custAcctId;


    }

    /**
     * Call to database procedure for validating federal taxid format
     * @param pageContext the current OA page context
     * @param am application module of page
     */
    public void get_achccattributes(OAPageContext pageContext, 
                                    OAApplicationModule am) {

        int xcustAcctId = 0;
        CallableStatement cs = null;

        pageContext.writeDiagnostics(this, "custAcctId" + this.custAcctId, 1);


        try {

            pageContext.writeDiagnostics(this, 
                                         "Getting handle to OADB transaction and callable statement", 
                                         1);
            OADBTransaction oadbtransaction = 
                (OADBTransaction)am.getOADBTransaction();
            cs = 
 oadbtransaction.getJdbcConnection().prepareCall("{call xx_cdh_extn_achcccontrol_pkg.get_irec_achcc_attribs(:1,:2,:3)}");


            pageContext.writeDiagnostics(this, 
                                         "After prepare call to DB procedure", 
                                         1);


            if (custAcctId != null) {
                xcustAcctId = Integer.parseInt(custAcctId);
            }


            cs.setInt(1, xcustAcctId);
            cs.registerOutParameter(2, Types.VARCHAR);
            cs.registerOutParameter(3, Types.VARCHAR);

            pageContext.writeDiagnostics(this, 
                                         "Before executing prepare call statement", 
                                         1);
            cs.execute();

            pageContext.writeDiagnostics(this, 
                                         "After executing prepare call statement ", 
                                         1);

            achflag = cs.getString(2);
            ccflag = cs.getString(3);


            cs.close();
        } catch (SQLException sqlexception) {
            throw OAException.wrapperException(sqlexception);
        } finally {
            try {
                cs.close();
            } catch (Exception e) {
                throw OAException.wrapperException(e);
            }
        }

    }

    /**
     * Get method for CC flag
     */
    public String getCCFlag() {

        return this.ccflag;
    }

    /**
     * Get method for ACH flag
     */
    public String getACHFlag() {

        return this.achflag;
    }


    /** isEmailValid: Validate email address using Java reg ex. 
     * This method checks if the input string is a valid email address. 
     * @param email String. Email address to validate 
     * @return boolean: true if email address is valid, false otherwise. 
     */
    public static boolean isEmailValid(String email) {
        boolean isValid = false;

        /*
        Email format: A valid email address will have following format:
        [\w\.-]+: Begins with word characters, (may include periods and hypens).
        @: It must have a '@' symbol after initial characters.
        ([\w\-]+\.)+: '@' must follow by more alphanumeric characters (may include hypens.).
        This part must also have a "." to separate domain and subdomain names.
        [A-Z]{2,4}$ : Must end with two to four alaphabets.
        (This will allow domain names with 2, 3 and 4 characters e.g pa, com, net, wxyz)
        */

        String expression = "^\\w+([\\.-]?\\w+)*@\\w+([\\.-]?\\w+)*(\\.\\w{2,3})+$";
        CharSequence inputStr = email;
        Pattern pattern = 
            Pattern.compile(expression, Pattern.CASE_INSENSITIVE);
        Matcher matcher = pattern.matcher(inputStr);
        if (matcher.matches()) {
            isValid = true;
        }
        return isValid;
    }
}
