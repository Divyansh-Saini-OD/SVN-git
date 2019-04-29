package od.oracle.apps.xxcrm.cdh.ebl.server;

import com.sun.java.util.collections.ArrayList;

import java.io.Serializable;

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import java.text.SimpleDateFormat;

import java.util.Calendar;
import java.util.Iterator;

import od.oracle.apps.xxcrm.cdh.ebl.custdocs.server.ODEbillCustDocVOImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillConcatenateVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillContactsVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillEXLSwitcherVOImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillFileNameVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillNonStdVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillSplitVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillStdAggrDtlVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillTemplDtlVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.poplist.server.ODEBillCharYesNoImpl;
import od.oracle.apps.xxcrm.cdh.ebl.poplist.server.ODEBillComboPVOImpl;
import od.oracle.apps.xxcrm.cdh.ebl.poplist.server.ODEBillDelyMethodPVOImpl;
import od.oracle.apps.xxcrm.cdh.ebl.poplist.server.ODEBillDocTypePVOImpl;
import od.oracle.apps.xxcrm.cdh.ebl.poplist.server.ODEBillNumYesNoPVOImpl;
import od.oracle.apps.xxcrm.cdh.uploads.eblContacts.server.XxcrmEblContUploadsVOImpl;

import oracle.apps.fnd.common.AppsLog;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;


import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.Transaction;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;


/*
  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        :  ODEBillAMImpl                                              |
  -- | Description :                                                             |
  -- | This is the Application Module Class for eBill Main Page                  |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author             Remarks                            |
  -- |======== =========== ================   ================================   |
  -- |DRAFT 1A 15-JAN-2010 Devi Viswanathan   Initial draft version              |
  -- |1.0      21-SEP-2010 Gokila Tamilselvam Changes for Defect# 7491.          |
  -- |2.0      12-JUL-2012 Sreedhar Mohan     For 12.4 CR833- added CustDocType  |
  -- |                                        arg in initializeMain method       |
  -- |                                        -addDefaultFileNames method is     |
  -- |                                        modified to default file name to   |
  -- |                                        have invoice# or Cons. Bill#       |
  -- |2.0      24-JUL-2012 Sreedhar Mohan     12.4 CR833- Added 1 new method     |
  -- |                                        - downloadEbillContacts            |
  -- |3.0      7-Oct-2015  Sridevi Kondoju    Modified for MOD4B R2              |
  -- |4.0     19-Nov-2015  Sridevi Kondoju    Modified for MOD4B R3              |
  -- |4.1     19-Jan-2016  Sridevi Kondoju    Modified for MOD4B R3 Defect1978   |
  -- |4.2     19-Mar-2017  Bhagwan Rao        Modified for Defect38962 and 40015 |
  -- |4.3     27-Jul-2017  Reddy Sekhar K     Code Added for Defect#42321        | 
  -- |4.4     04-Dec-2017  Rafi Mohammed     Code Added for Defect#NAIT-21725    |
  -- |4.5     20-Mar-2018  Rafi Mohammed     Code Added for Defect#NAIT-33309    | 
  -- |4.6     08-Jun-2018  Rafi Mohammed     Code Added for Defect#NAIT-40588    |
 --  |4.7     15-Apr-2019 Rafi Mohammed      NAIT-91481 Rectify Billing Delivery Efficiency|
  -- |===========================================================================|
  -- | Subversion Info:                                                          |
  -- | $HeadURL: http://svn.na.odcorp.net/svn/od/common/branches/fix/xxcomn/java/od/oracle/apps/xxcrm/cdh/ebl/server/ODEBillAMImpl.java $                                                               |
  -- | $Rev: 180814 $                                                                   |
  -- | $Date: 2012-08-16 10:33:50 -0400 (Thu, 26 Sep 2012) $                                                                  |
  -- |                                                                           |
  -- +===========================================================================+
*/


//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODEBillAMImpl extends OAApplicationModuleImpl {
    /**
     *
     * This is the default constructor (do not remove)
     */
    public ODEBillAMImpl() {
    }

    /* Method to initialize all the VOs, set default values to attributes when the page is rendered.
   */

    public String initializeMain(String custDocId, String custAcctId, 
                                 String deliveryMethod, String directDoc, 
                                 String emailSubj, String emailStdMsg, 
                                 String emailSign, String emailStdDisc, 
                                 String emailSplInst, String ftpEmailSubj, 
                                 String ftpEmailCont, String ftpNotiFileTxt, 
                                 String ftpNotiEmailTxt, String logoFile, 
                                 String associateName, String CustDocType) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("fnd.common.WebAppsContext", "XXOD: initializeMain", 
                        1);

        ODUtil utl = new ODUtil(this);
        String newFlag = "FALSE";

        utl.log("Inside createUpdateMain: DocId" + custDocId + 
                " CustAcctId: " + custAcctId);
        utl.log("************Current Date:::::::::::" + getSysDate());

        OAViewObject mainVO = 
            (OAViewObject)this.findViewObject("ODEBillMainVO");
        OAViewObject transVO = 
            (OAViewObject)this.findViewObject("ODEBillTransmissionVO");
        OAViewObject contactVO = 
            (OAViewObject)this.findViewObject("ODEBillContactsVO");
        OAViewObject fileParamVO = 
            (OAViewObject)this.findViewObject("ODEBillFileNameVO");
        OAViewObject configHeadVO = 
            (OAViewObject)this.findViewObject("ODEBillTempHeaderVO");

        OAViewObject stdAggrDtlVO = null;
        OAViewObject nonStdVO = null;

        /*Start - MOD 4B R3 */
        OAViewObject concatenateVO = null;
        OAViewObject splitVO = null;

        OAViewObject subTotalFieldsVO = null;
        OAViewObject aggrFieldPVO = null;
        OAViewObject configDetailsFieldNamesPVO = null;
        /*End - MOD 4B R3 */

        mainVO.setWhereClause(null);
        mainVO.setWhereClause("cust_doc_id = " + custDocId);
        mainVO.executeQuery();

        transVO.setWhereClause(null);
        transVO.setWhereClause("cust_doc_id = " + custDocId);
        transVO.executeQuery();

        contactVO.setWhereClause(null);
        contactVO.setWhereClause("cust_doc_id = " + custDocId);
        contactVO.executeQuery();

        /*
     * Added for Defect# 11568
     *
     */
        myAppsLog.write("fnd.common.WebAppsContext", 
                        "XXOD: deleteEnableDisable", 1);
        deleteEnableDisable();
        //Code End for Defect# 11568
        fileParamVO.setWhereClause(null);
        fileParamVO.setWhereClause("cust_doc_id = " + custDocId);
        fileParamVO.executeQuery();

        myAppsLog.write("fnd.common.WebAppsContext", 
                        "Inside ODEBillAMImpl: initializeMain:" + 
                        fileParamVO.getRowCount(), 1);

        utl.log("Inside ODEBillAMImpl: initializeMain: " + 
                fileParamVO.getRowCount());

        if (fileParamVO.getRowCount() == 0) {

            myAppsLog.write("fnd.common.WebAppsContext", 
                            "Inside ODEBillAMImpl: addDefaultFileNames", 1);

            addDefaultFileNames(custDocId, directDoc, CustDocType);
        }

        if (mainVO.getRowCount() == 0) {
            mainVO.setMaxFetchSize(0);
            OARow mainRow = (OARow)mainVO.createRow();
            mainRow.setAttribute("CustDocId", custDocId);
            mainRow.setAttribute("CustAccountId", custAcctId);
            mainRow.setAttribute("FileSeqResetDate", getSysDate());
            mainRow.setAttribute("EbillAssociate", associateName);
            mainRow.setAttribute("MaxFileSize", new Number(10));
            mainRow.setAttribute("MaxTransmissionSize", new Number(10));
            mainRow.setAttribute("Attribute1", "CORE");
            //Added by Bhagwan Rao for Defect#38962 26March2017
            mainRow.setAttribute("SummaryBill", "N");
            if (deliveryMethod.equals("ePDF")) {
                mainRow.setAttribute("FileProcessingMethod", "03");
                mainRow.setAttribute("FileNameExt", "PDF");
            }
            if (deliveryMethod.equals("eXLS"))
                mainRow.setAttribute("FileNameExt", "XLS");
                
            if (deliveryMethod.equals("eTXT"))
                mainRow.setAttribute("FileNameExt", "TXT");
            mainVO.insertRow(mainRow);
            mainRow.setNewRowState(mainRow.STATUS_INITIALIZED);
            newFlag = "TRUE";
        }

        if (transVO.getRowCount() == 0) {
            transVO.setMaxFetchSize(0);
            OARow transRow = (OARow)transVO.createRow();
            transRow.setAttribute("CustDocId", custDocId);
            transVO.insertRow(transRow);
            transRow.setNewRowState(transRow.STATUS_INITIALIZED);
            defaultTrans(emailSubj, emailStdMsg, emailSign, emailStdDisc, 
                         emailSplInst, ftpEmailSubj, ftpEmailCont, 
                         ftpNotiFileTxt, ftpNotiEmailTxt);
        } else { //to initialize SplInstruction from  profile value as this column is  not stored in the db table
            OARow transRow = (OARow)transVO.first();
            if (transRow != null)
                transRow.setAttribute("EmailSplInstruction", emailSplInst);
        }

        if (deliveryMethod.equals("eXLS") || deliveryMethod.equals("eTXT")) {
            configHeadVO.setWhereClause(null);
            configHeadVO.setWhereClause("cust_doc_id = " + custDocId);
            configHeadVO.executeQuery();

            if (configHeadVO.getRowCount() == 0) {
                configHeadVO.setMaxFetchSize(0);
                OARow configRow = (OARow)configHeadVO.createRow();
                configRow.setAttribute("CustDocId", custDocId);
                if (deliveryMethod.equals("eXLS")) {
                    configRow.setAttribute("IncludeHeader", "Y");
                    configRow.setAttribute("LogoFileName", "OFFICEDEPOT");
                }
                if (deliveryMethod.equals("eTXT")) {
                    configRow.setAttribute("EbillFileCreationType", 
                                           "DELIMITED");
                    configRow.setAttribute("DelimiterChar", "|");
                    configRow.setAttribute("IncludeHeader", "N");
                    configRow.setAttribute("LogoFileName", null);
                }
                configHeadVO.insertRow(configRow);
                //          configRow.setNewRowState(configRow.STATUS_INITIALIZED);
            }
        }

        if (deliveryMethod.equals("eXLS")) {
            stdAggrDtlVO = 
                    (OAViewObject)this.findViewObject("ODEBillStdAggrDtlVO");
            stdAggrDtlVO.setWhereClause(null);
            stdAggrDtlVO.setWhereClause("cust_doc_id = " + custDocId);
            stdAggrDtlVO.executeQuery();


            /*Start - MOD 4B R3 */
            //Used in Subtotal tab for Change Field
            subTotalFieldsVO = 
                    (OAViewObject)this.findViewObject("ODEBillSubTotalFieldsVO");
            subTotalFieldsVO.setWhereClause(null);
            subTotalFieldsVO.setWhereClause(" cust_doc_id is null or cust_doc_id = " + 
                                            custDocId);
            subTotalFieldsVO.executeQuery();

            //Used in Subtotal for aggregatable field
            aggrFieldPVO = 
                    (OAViewObject)this.findViewObject("ODEBillAggrFieldPVO");
            aggrFieldPVO.setWhereClause(null);
            aggrFieldPVO.setWhereClause(" cust_doc_id is null or cust_doc_id = " + 
                                        custDocId);
            aggrFieldPVO.executeQuery();


            //Used in configuration details tab for field name
            configDetailsFieldNamesPVO = 
                    (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesPVO");
            configDetailsFieldNamesPVO.setWhereClause(null);
            configDetailsFieldNamesPVO.setWhereClause(" cust_doc_id is null or cust_doc_id = " + 
                                                      custDocId);
            configDetailsFieldNamesPVO.executeQuery();


            concatenateVO = 
                    (OAViewObject)this.findViewObject("ODEBillConcatenateVO");


            myAppsLog.write("XXOD:ODEBillAMImpl:", 
                            "XXOD:setting  concatenate vo ", 1);

            concatenateVO.setWhereClause(null);
            concatenateVO.setWhereClause("cust_doc_id = " + custDocId);


            myAppsLog.write("XXOD:ODEBillAMImpl:", 
                            "XXOD: concatenate vo " + concatenateVO.getQuery(), 
                            1);
            concatenateVO.executeQuery();


            splitVO = (OAViewObject)this.findViewObject("ODEBillSplitVO");

            splitVO.setWhereClause(null);
            splitVO.setWhereClause("cust_doc_id = " + custDocId);

            splitVO.executeQuery();

            splitVO.reset();

            while (splitVO.hasNext()) {

                OARow splitRow = (OARow)splitVO.next();

                String sSplit = "";
                sSplit = (String)splitRow.getAttribute("SplitType");

                if ("FP".equalsIgnoreCase(sSplit)) {
                    splitRow.setAttribute("EnableFixedPosition", 
                                          Boolean.FALSE);
                    splitRow.setAttribute("EnableDelimiter", Boolean.TRUE);
                } else {
                    splitRow.setAttribute("EnableFixedPosition", Boolean.TRUE);
                    splitRow.setAttribute("EnableDelimiter", Boolean.FALSE);
                }

            }
            splitVO.reset();
            /*End - MOD 4B R3 */


        }

        if (deliveryMethod.equals("eTXT")) {
            nonStdVO = (OAViewObject)this.findViewObject("ODEBillNonStdVO");
            nonStdVO.setWhereClause(null);
            nonStdVO.setWhereClause("cust_doc_id = " + custDocId);
            nonStdVO.executeQuery();
        }

        utl.log("End of createUpdateMain");
        return newFlag;
    } //End of initializeMain()

    //Rel 12.4 CR 833- eBill Ehnhancements

    public String downloadEbillContacts(String custDocId, String custAcctId, 
                                        String directory, 
                                        String file_name_with_ext) {
        CallableStatement cs2 = null;

        String strFileUploadId = "0";

        try {
            cs2 = 
getOADBTransaction().getJdbcConnection().prepareCall("{call XX_CRM_EBL_CONT_DOWNLOAD_PKG.DOWNLOAD_EBL_CONTACT(?,?,?,?,?,?)}");

            cs2.registerOutParameter(1, OracleTypes.VARCHAR);
            cs2.registerOutParameter(2, OracleTypes.VARCHAR);
            cs2.registerOutParameter(3, OracleTypes.VARCHAR);
            cs2.setString(4, custDocId);
            cs2.setString(5, custAcctId);
            cs2.setString(6, directory);
            cs2.setString(7, file_name_with_ext);

            cs2.execute();

            Object obj = null;
            obj = cs2.getObject(3);
            if (obj != null)
                strFileUploadId = obj.toString();
            else
                strFileUploadId = "0";
            cs2.close();

        } catch (SQLException e) {
            e.printStackTrace();
            try {
                cs2.close();
            } catch (SQLException se1) {
            }
        }
        return strFileUploadId;

    }
    //End of downloadEbillContacts

    //set default values to eMail attributes

    public void defaultEmail(String custDocId, String emailSubj, 
                             String emailStdMsg, String emailSign, 
                             String emailStdDisc, String emailSplInst) {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAMImpl: defaultEmail");
        //OAViewObject transVO = (OAViewObject) this.getODEBillTransmissionVO();
        OAViewObject transVO = 
            (OAViewObject)findViewObject("ODEBillTransmissionVO");
        OARow transRow = (OARow)transVO.first();
        //set default values to eMail attributes
        transRow.setAttribute("CustDocId", custDocId);
        transRow.setAttribute("EmailSubject", emailSubj);
        transRow.setAttribute("EmailStdMessage", emailStdMsg);
        transRow.setAttribute("EmailStdDisclaimer", emailStdDisc);
        transRow.setAttribute("EmailSignature", emailSign);
        transRow.setAttribute("EmailSplInstruction", emailSplInst);
        transRow.setAttribute("EmailLogoRequired", "Y");
        transRow.setAttribute("EmailLogoFileName", "OFFICEDEPOT");

    }

    //set default values to FTP attributes

    public void defaultFTP(String custDocId, String ftpEmailSubj, 
                           String ftpEmailCont, String ftpNotiFileTxt, 
                           String ftpNotiEmailTxt) {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAMImpl: defaultFTP");
        OAViewObject transVO = 
            (OAViewObject)findViewObject("ODEBillTransmissionVO");
        OARow transRow = (OARow)transVO.first();
        utl.log("Inside ODEBillAMImpl: defaultFTP: transRow:" + 
                transRow.getAttribute("CustDocId"));
        transRow.setAttribute("CustDocId", custDocId);
        transRow.setAttribute("FtpNotifyCustomer", "Y");
        transRow.setAttribute("FtpEmailSub", ftpEmailSubj);
        transRow.setAttribute("FtpEmailContent", ftpEmailCont);
        transRow.setAttribute("FtpSendZeroByteFile", "Y");
        transRow.setAttribute("FtpZeroByteFileText", ftpNotiFileTxt);
        transRow.setAttribute("FtpZeroByteNotificationTxt", ftpNotiEmailTxt);
    }


    //set Email attributes to null

    public void nullEmail() {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAMImpl: nullEmail");

        OAViewObject transVO = 
            (OAViewObject)findViewObject("ODEBillTransmissionVO");
        OARow transRow = (OARow)transVO.first();

        transRow.setAttribute("EmailSubject", null);
        transRow.setAttribute("EmailStdMessage", null);
        transRow.setAttribute("EmailCustomMessage", null);
        transRow.setAttribute("EmailStdDisclaimer", null);
        transRow.setAttribute("EmailSignature", null);
        transRow.setAttribute("EmailLogoRequired", null);
        transRow.setAttribute("EmailLogoFileName", null);
    }

    //set FTP attributes to null

    public void nullFTP() {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAMImpl: nullFTP");

        OAViewObject transVO = 
            (OAViewObject)findViewObject("ODEBillTransmissionVO");
        OARow transRow = (OARow)transVO.first();

        transRow.setAttribute("FtpDirection", null);
        transRow.setAttribute("FtpTransferType", null);
        transRow.setAttribute("FtpDestinationSite", null);
        transRow.setAttribute("FtpDestinationFolder", null);
        transRow.setAttribute("FtpUserName", null);
        transRow.setAttribute("FtpPassword", null);
        transRow.setAttribute("FtpPickupServer", null);
        transRow.setAttribute("FtpPickupFolder", null);
        transRow.setAttribute("FtpCustContactName", null);
        transRow.setAttribute("FtpCustContactEmail", null);
        transRow.setAttribute("FtpCustContactPhone", null);
        transRow.setAttribute("FtpNotifyCustomer", null);
        transRow.setAttribute("FtpCcEmails", null);
        transRow.setAttribute("FtpEmailSub", null);
        transRow.setAttribute("FtpEmailContent", null);
        transRow.setAttribute("FtpSendZeroByteFile", null);
        transRow.setAttribute("FtpZeroByteFileText", null);
        transRow.setAttribute("FtpZeroByteNotificationTxt", null);

    }

    //set CD attributes to null

    public void nullCD() {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAMImpl: nullCD");

        OAViewObject transVO = 
            (OAViewObject)findViewObject("ODEBillTransmissionVO");
        OARow transRow = (OARow)transVO.first();

        transRow.setAttribute("CdFileLocation", null);
        transRow.setAttribute("CdSendToAddress", null);
        transRow.setAttribute("Comments", null);

    }


    public void stdPPRHandle() {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAMImpl: stdPPRHandle");
        
        AppsLog myAppsLog = new AppsLog();                                    
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD: start stdPPRHandle", 
                        1);
                        
        OAViewObject mainVO = 
            (OAViewObject)this.findViewObject("ODEBillMainVO");
        OARow mainRow = (OARow)mainVO.first();
        String custDocId = null;
        String stdContLvl = null;
        if (mainRow != null) {
            stdContLvl = (String)mainRow.getAttribute("Attribute1");
            custDocId = mainRow.getAttribute("CustDocId").toString();
        }
        
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD: stdPPRHandle stdContLvl:"+stdContLvl, 
                        1);
        // deleteTemplVO();
        // populateStdVO(custDocId, stdContLvl);
        changeSelStdVO(custDocId, stdContLvl);

    } // End stdPPRHandle()

    public void deleteTemplVO() {
        ODUtil utl = new ODUtil(this);
        utl.log("********Inside deleteTemplVO");
        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
        OARow templDelRow = (OARow)templDtlVO.first();
        while (templDtlVO.getRowCount() > 0) {
            templDelRow.remove();
            templDelRow = (OARow)templDtlVO.next();
        }

    } //End deleteTemplVO(OAViewObject templDtlVO)


    public void populateStdVO(String custDocId, String StdCont) {
        ODUtil utl = new ODUtil(this);
        utl.log("********Inside ODEBillAM: populateStdVO: Level: " + StdCont);


        AppsLog myAppsLog = new AppsLog();                                    
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD: start populateStdVO StdCont:"+StdCont, 
                        1);
                        
        OAViewObject mainVO = (OAViewObject)this.findViewObject("ODEBillMainVO");
               OARow mainRow = (OARow)mainVO.getCurrentRow();                        
        mainRow.setAttribute("SummaryBill", "N");
        
        if (StdCont == null)
            StdCont = "CORE";

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");

        OAViewObject stdFieldsVO = this.getODEBillStdFieldsVO();
        stdFieldsVO.setWhereClause(null);
        //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - START
        stdFieldsVO.setOrderByClause("Field_name,include_in_core desc,include_in_detail desc");    
        //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - END
        stdFieldsVO.executeQuery();
        utl.log("********Inside ODEBillAM: stdFieldsVO: rowcount: " + 
                stdFieldsVO.getRowCount());
        OARow stdFieldRow = (OARow)stdFieldsVO.first();

        templDtlVO.last();
        templDtlVO.next();
        
       
        for (int i = 0; i < stdFieldsVO.getRowCount(); i++) {
            OARow templRow = (OARow)templDtlVO.createRow();
            templRow.setAttribute("CustDocId", custDocId);
            templRow.setAttribute("RecordType", "000");
            templRow.setAttribute("EblTemplId", 
                                  this.getOADBTransaction().getSequenceValue("XX_CDH_EBL_TEMPL_ID_S"));
            templRow.setAttribute("FieldId", 
                                  stdFieldRow.getAttribute("FieldId"));
            templRow.setAttribute("Label", 
                                  stdFieldRow.getAttribute("FieldName"));
            templRow.setAttribute("DataFormat", 
                                  stdFieldRow.getAttribute("DataFormat"));
            templRow.setAttribute("Attribute2", 
                                  stdFieldRow.getAttribute("IncludeInCore"));
            templRow.setAttribute("Attribute3", 
                                  stdFieldRow.getAttribute("IncludeInDetail"));
            templRow.setAttribute("Attribute20", "Y");
            templRow.setAttribute("Concatenate", "N");
            templRow.setAttribute("Split", "N");
	    templRow.setAttribute("RepeatTotalFlag", "N");

            if (stdFieldRow.getAttribute("IncludeInCore") != null)
             myAppsLog.write("ODEBillAMImpl:populateStdVO:", 
                             "XXOD:IncludeInCore:"+(String)stdFieldRow.getAttribute("IncludeInCore"), 
                             1);
            
            String value = "N";
            if (StdCont.equals("CORE"))
                value = (String)stdFieldRow.getAttribute("IncludeInCore");
            else if (StdCont.equals("DETAIL"))
                value = (String)stdFieldRow.getAttribute("IncludeInDetail");
            else
                value = "Y"; 
                
            if (value == null){
                myAppsLog.write("ODEBillAMImpl:populateStdVO:", 
                                "XXOD: value null..setting to N", 
                                1);
                value = "N";
            }

            templRow.setAttribute("Attribute1", value);
            
            //Start - Modified for Defect#1978 MOD4BR3
            String sDefaultSeq = null;
            if (stdFieldRow.getAttribute("DefaultSeq") != null)
               sDefaultSeq = stdFieldRow.getAttribute("DefaultSeq").toString();
            
            if ( (StdCont.equals("DETAIL")) &&(sDefaultSeq != null) && 
               (!"".equals(sDefaultSeq))) {
                templRow.setAttribute("Seq", sDefaultSeq);
                templRow.setAttribute("Attribute1", (String)stdFieldRow.getAttribute("IncludeInDetail"));
            }
            else 
                templRow.setAttribute("Seq", new Number((i + 1) * 10));
            //End  - Modified for Defect#1978 MOD4BR3


            templDtlVO.insertRow(templRow);
            stdFieldRow = (OARow)stdFieldsVO.next();
            templDtlVO.last();
            templDtlVO.next();

        }
        templDtlVO.first();
        utl.log("********End of ODEBillAM: populateStdVO: Level: " + StdCont);
    } // End populateStdVO( OAViewObject templDtlVO, String custDocId, String StdCont)
    


    public void changeSelStdVO(String custDocId, String StdCont) {
        ODUtil utl = new ODUtil(this);
        utl.log("********Inside ODEBillAM: changeSelStdVO: Level: " + StdCont);
        if (StdCont == null)
            StdCont = "CORE";

       //Added by Thilak for defect 41888
        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
        templDtlVO.setWhereClause(null);
        templDtlVO.setWhereClause("cust_doc_id = " + custDocId + " and target_value25 != 'C'");
        templDtlVO.executeQuery();
         if (templDtlVO.getRowCount() != 0) {
             OARow templDelRow = (OARow)templDtlVO.first();
                 for (int i = templDtlVO.getRowCount(); i != 0; i--) {
                     Number pkID=(Number)templDelRow.getAttribute("EblTemplId");
                     String p= pkID.stringValue();
                     deleteTemplDtlVO(p,custDocId);
                     templDelRow = (OARow)templDtlVO.next();
                 }
         }    
		 //Commented by Thilak for defect 41888
//        OAViewObject templDtlVO = 
//            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");  
//        
//        /* Start - Code added for Defect 1978 */
//        OARow templDelRow = (OARow)templDtlVO.first();
//        while (templDtlVO.getRowCount() > 0) {
//            templDelRow.remove();
//            templDelRow = (OARow)templDtlVO.next();            
//        }
   
        populateStdVO(custDocId, StdCont);
        getOADBTransaction().commit();
        OAViewObject templDtlStdVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
            templDtlStdVO.setWhereClause(null);
            templDtlStdVO.setWhereClause("cust_doc_id = " + custDocId);
            
        //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725- START
             templDtlVO.setOrderByClause("decode(attribute1,'Y',seq),label asc");
        //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - END
        
            templDtlStdVO.executeQuery();        
        /* End - Code added for Defect 1978 */
        
   /*  
    *  Commented for Defect1978.
       OARow templRow = (OARow)templDtlVO.last();

        for (int i = 0; i < templDtlVO.getRowCount(); i++) {
            if (templRow != null && 
                templRow.getAttribute("Attribute1") != null) {
                if (StdCont.equals("CORE")) {
                    if (!(templRow.getAttribute("Attribute1").equals(templRow.getAttribute("Attribute2"))))
                        templRow.setAttribute("Attribute1", 
                                              templRow.getAttribute("Attribute2"));
                                              
                                              
                                              
                                              
                                              
                } else if (StdCont.equals("DETAIL")) {
                    if (!(templRow.getAttribute("Attribute1").equals(templRow.getAttribute("Attribute3"))))
                        templRow.setAttribute("Attribute1", 
                                              templRow.getAttribute("Attribute3"));
                } else {
                    if (!(templRow.getAttribute("Attribute1").equals("Y")))
                        templRow.setAttribute("Attribute1", "Y");
                }
  
            }
            templRow = (OARow)templDtlVO.previous();
        } //End for(int i = 0; i < templDtlVO.getRowCount(); i++)
        templDtlVO.first();
        utl.log("********End of ODEBillAM: changeSelStdVO: Level: " + StdCont);
        
        */
        
    } // End changeSelStdVO( OAViewObject templDtlVO, String custDocId, String StdCont)
    
     public void deleteTemplSumVO(String eblTemplId, String custDocID) {

             ODUtil utl = new ODUtil(this);

             int eblTemplIdPara = Integer.parseInt(eblTemplId);
             int custDocIDPara = Integer.parseInt(custDocID);

             utl.log("Inside deleteField: eblTemplIdPara " + eblTemplId);
             OAViewObject templVO = (OAViewObject)this.getODEBillTemplDtlVO();
             templVO.setWhereClause(null);
             templVO.setWhereClause("cust_doc_id = " + custDocIDPara + " and target_value25 = 'N'");
             templVO.executeQuery();
             ODEBillTemplDtlVORowImpl templRow = null;
             
             int fetchedRowCount = templVO.getRowCount();
             RowSetIterator deleteIter = 
                 templVO.createRowSetIterator("deleteIter");

             if (fetchedRowCount > 0) {                    
                 deleteIter.setRangeStart(0);
                 deleteIter.setRangeSize(fetchedRowCount);

                 for (int i = 0; i < fetchedRowCount; i++) {
                     templRow = 
                             (ODEBillTemplDtlVORowImpl)deleteIter.getRowAtRangeIndex(i);
                         templRow.setAttribute("EblTemplId",eblTemplIdPara);
                         templRow.setAttribute("CustDocId",custDocIDPara);
                     utl.log("Before Remove eblTemplIdPara" + eblTemplIdPara);
                     templRow.remove();
                     utl.log("After Remove eblTemplIdPara" + eblTemplIdPara);
                     try {
                         getTransaction().setClearCacheOnCommit(false);
                         getTransaction().commit();
                     } catch (Exception e) {
                         throw new OAException(" DeleteTemplDtl Unexpected Exception:" + e.getMessage());
                     }
                     utl.log("After Commit eblTemplIdPara" + eblTemplIdPara);
                     break;
                 }
             }
             deleteIter.closeRowSetIterator();

         }    

         public void deleteTemplDtlVO(String eblTemplId, String custDocID) {

             ODUtil utl = new ODUtil(this);

             int eblTemplIdPara = Integer.parseInt(eblTemplId);
             int custDocIDPara = Integer.parseInt(custDocID);

             utl.log("Inside deleteField: eblTemplIdPara " + eblTemplId);
             OAViewObject templVO = (OAViewObject)this.getODEBillTemplDtlVO();
             templVO.setWhereClause(null);
             templVO.setWhereClause("cust_doc_id = " + custDocIDPara + " and target_value25 != 'C'");
             templVO.executeQuery();
             ODEBillTemplDtlVORowImpl templRow = null;
             
             int fetchedRowCount = templVO.getRowCount();
             RowSetIterator deleteIter = 
                 templVO.createRowSetIterator("deleteIter");

             if (fetchedRowCount > 0) {                    
                 deleteIter.setRangeStart(0);
                 deleteIter.setRangeSize(fetchedRowCount);

                 for (int i = 0; i < fetchedRowCount; i++) {
                     templRow = 
                             (ODEBillTemplDtlVORowImpl)deleteIter.getRowAtRangeIndex(i);
                         templRow.setAttribute("EblTemplId",eblTemplIdPara);
                         templRow.setAttribute("CustDocId",custDocIDPara);
                     utl.log("Before Templ Remove eblTemplIdPara" + eblTemplIdPara);
                     templRow.remove();
                     utl.log("After Templ Remove eblTemplIdPara" + eblTemplIdPara);
                     try {
                         getTransaction().setClearCacheOnCommit(false);
                         getTransaction().commit();
                     } catch (Exception e) {
                         throw new OAException(" DeleteTemplDtl Unexpected Exception:" + e.getMessage());
                     }
                     utl.log("After Commit Templ eblTemplIdPara" + eblTemplIdPara);
                     break;
                 }
             }
             deleteIter.closeRowSetIterator();

         }
//Added by Bhagwan Rao 17 Jun 2017 for Defect # 42383
 public void concatenateSplitCBDisabled(String custDocId) {
     ODUtil utl = new ODUtil(this);
     String sInitialFlag = "N";
     utl.log("Inside ODEBillAMImpl: concatenateSplitCBDisabled for eXLS");
     
     AppsLog myAppsLog = new AppsLog();
     myAppsLog.write("fnd.common.WebAppsContext", 
                     "XXOD: Inside ODEBillAMImpl: concatenateSplitCBDisabled for eXLS", 
                     1);
     OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
     OARow PPRRow = (OARow)PPRVO.first();             


     OAViewObject templDtlVO = 
         (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
     templDtlVO.setWhereClause(null);
     templDtlVO.setWhereClause("cust_doc_id = " + custDocId);
     
     OAViewObject custDocVO = 
         (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
     String deliveryMethod = 
         custDocVO.first().getAttribute("DeliveryMethod").toString();
     if (deliveryMethod.equals("eXLS")) {
         myAppsLog.write("fnd.common.WebAppsContext", 
                         "XXOD: exls deliverymethod", 
                         1);
         OAViewObject concatVO = 
             (OAViewObject)this.findViewObject("ODEBillConcatFieldsPVO");
         concatVO.executeQuery();

         OAViewObject splitVO = 
             (OAViewObject)this.findViewObject("ODEBillSplitFieldsPVO");
         splitVO.executeQuery();

         if ("Y".equals(sInitialFlag)){
             myAppsLog.write("fnd.common.WebAppsContext", 
                             "XXOD: Initial", 
                             1);
             refreshTemplDtlVOOnChecking(templDtlVO, concatVO, splitVO);
         }
         else {
             myAppsLog.write("fnd.common.WebAppsContext", 
                             "XXOD: not initial", 
                             1);
             RowSetIterator rsi = 
                 templDtlVO.createRowSetIterator("rowsRSI");
             rsi.reset();
             while (rsi.hasNext()) {
                 Row templDtlRow = rsi.next();

                 String sConcat = null;
                 String sSplit = null;
                 String sSelect = null;


                 if (templDtlRow.getAttribute("Concatenate") != null)
                     sConcat = 
                             templDtlRow.getAttribute("Concatenate").toString();

                 if (templDtlRow.getAttribute("Split") != null)
                     sSplit = templDtlRow.getAttribute("Split").toString();

                 if (templDtlRow.getAttribute("Attribute1") != null)
                     sSelect = 
                             templDtlRow.getAttribute("Attribute1").toString();


                 if (("Y".equals(sConcat)) || ("Y".equals(sSplit))) {
                     templDtlRow.setAttribute("Attribute1", "Y");
                     templDtlRow.setAttribute("Attribute20", "N");                       
                 }

                 oracle.jbo.domain.Number nFieldId = null;
                 nFieldId = 
                         (oracle.jbo.domain.Number)templDtlRow.getAttribute("FieldId");
                 String sField = "" + nFieldId;
                 templDtlRow.setAttribute("ConcatFlag", Boolean.TRUE);
                 templDtlRow.setAttribute("SplitFlag", Boolean.TRUE);

                 if (!((Boolean)PPRRow.getAttribute("Complete"))) {

                     concatVO.reset();
                     while (concatVO.hasNext()) {
                         String sCode = null;
                         OARow concatVORow = (OARow)concatVO.next();
                         sCode = (String)concatVORow.getAttribute("Code");

                         if (sField.equals(sCode)) {
                             templDtlRow.setAttribute("ConcatFlag", 
                                                      Boolean.FALSE);
                             break;
                         }

                     }

                     splitVO.reset();
                     while (splitVO.hasNext()) {
                         String sCode = null;
                         OARow splitVORow = (OARow)splitVO.next();
                         sCode = (String)splitVORow.getAttribute("Code");

                         if (sField.equals(sCode)) {

                             templDtlRow.setAttribute("SplitFlag", 
                                                      Boolean.FALSE);
                             break;
                         }

                     }
                 } 

             }
         }
    
     }
 }
 
     public void populateTemplDtl(String custDocId) {
             ODUtil utl = new ODUtil(this);
             String sInitialFlag = "N";
             utl.log("Inside ODEBillAMImpl: populateTemplDtl for eXLS");
             
             AppsLog myAppsLog = new AppsLog();
             myAppsLog.write("fnd.common.WebAppsContext", 
                             "XXOD: Inside ODEBillAMImpl: populateTemplDtl for eXLS", 
                             1);

             OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
             OARow PPRRow = (OARow)PPRVO.first();             


             OAViewObject templDtlVO = 
                 (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
             templDtlVO.setWhereClause(null);
             templDtlVO.setWhereClause("cust_doc_id = " + custDocId);
             if (templDtlVO.getRowCount() == 0) {
                 myAppsLog.write("fnd.common.WebAppsContext", 
                                 "XXOD: row count 0", 
                                 1);
                 sInitialFlag = "Y"; //Added for MD4B R3 
                 populateStdVO(custDocId, "CORE");
                 getOADBTransaction().commit();
                 OAViewObject templDtlVO1 = 
                     (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
                     templDtlVO1.setWhereClause(null);
                     templDtlVO1.setWhereClause("cust_doc_id = " + custDocId);
                     templDtlVO1.executeQuery();                 
             }
      
             /* Start - MOD 4B R3 */
             //Based on transaltion setup for concatenate and split fields
             //for enabling or disabling conc/split fields in configuration details tab
             OAViewObject custDocVO = 
                 (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
             String deliveryMethod = 
                 custDocVO.first().getAttribute("DeliveryMethod").toString();
             if (deliveryMethod.equals("eXLS")) {
                 myAppsLog.write("fnd.common.WebAppsContext", 
                                 "XXOD: exls deliverymethod", 
                                 1);
                 OAViewObject concatVO = 
                     (OAViewObject)this.findViewObject("ODEBillConcatFieldsPVO");

                 concatVO.executeQuery();


                 OAViewObject splitVO = 
                     (OAViewObject)this.findViewObject("ODEBillSplitFieldsPVO");

                 splitVO.executeQuery();


                 if ("Y".equals(sInitialFlag)){
                     myAppsLog.write("fnd.common.WebAppsContext", 
                                     "XXOD: Initial", 
                                     1);
                     refreshTemplDtlVOOnChecking(templDtlVO, concatVO, splitVO);
                 }
                 else {
                     myAppsLog.write("fnd.common.WebAppsContext", 
                                     "XXOD: not initial", 
                                     1);
                     RowSetIterator rsi = 
                         templDtlVO.createRowSetIterator("rowsRSI");
                     rsi.reset();
                     while (rsi.hasNext()) {
                         Row templDtlRow = rsi.next();

                         String sConcat = null;
                         String sSplit = null;
                         String sSelect = null;


                         if (templDtlRow.getAttribute("Concatenate") != null)
                             sConcat = 
                                     templDtlRow.getAttribute("Concatenate").toString();

                         if (templDtlRow.getAttribute("Split") != null)
                             sSplit = templDtlRow.getAttribute("Split").toString();

                         if (templDtlRow.getAttribute("Attribute1") != null)
                             sSelect = 
                                     templDtlRow.getAttribute("Attribute1").toString();


                         if (("Y".equals(sConcat)) || ("Y".equals(sSplit))) {
                             templDtlRow.setAttribute("Attribute1", "Y");
                             templDtlRow.setAttribute("Attribute20", "N"); 
                             
                         }


                         oracle.jbo.domain.Number nFieldId = null;

                         nFieldId = 
                                 (oracle.jbo.domain.Number)templDtlRow.getAttribute("FieldId");
                         String sField = "" + nFieldId;
                         templDtlRow.setAttribute("ConcatFlag", Boolean.TRUE);
                         templDtlRow.setAttribute("SplitFlag", Boolean.TRUE);

                         if (!((Boolean)PPRRow.getAttribute("Complete"))) {

                             concatVO.reset();
                             while (concatVO.hasNext()) {
                                 String sCode = null;
                                 OARow concatVORow = (OARow)concatVO.next();
                                 sCode = (String)concatVORow.getAttribute("Code");

                                 if (sField.equals(sCode)) {
                                     templDtlRow.setAttribute("ConcatFlag", 
                                                              Boolean.FALSE);
                                     break;
                                 }


                             }

                             splitVO.reset();
                             while (splitVO.hasNext()) {
                                 String sCode = null;
                                 OARow splitVORow = (OARow)splitVO.next();
                                 sCode = (String)splitVORow.getAttribute("Code");

                                 if (sField.equals(sCode)) {

                                     templDtlRow.setAttribute("SplitFlag", 
                                                              Boolean.FALSE);
                                     break;
                                 }


                             }
                         } 


                     }
                 }
             }

           // } /* End - MOD 4B R3 */
     // }
      } // End populateTemplDtl()
      
       public void populateTemplSumDtl(String custDocId) {
               ODUtil utl = new ODUtil(this);
               String sInitialFlag = "N";
               utl.log("Inside ODEBillAMImpl: populateTemplDtl for eXLS");
               
               AppsLog myAppsLog = new AppsLog();
               myAppsLog.write("fnd.common.WebAppsContext", 
                               "XXOD: Inside ODEBillAMImpl: populateTemplDtl for eXLS", 
                               1);

               OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
               OARow PPRRow = (OARow)PPRVO.first();             

                OAViewObject mainVO = 
                    (OAViewObject)this.findViewObject("ODEBillMainVO");
                OARow mainRow = (OARow)mainVO.first();
                String stdContLvl = null;
                if (mainRow != null) {
                    stdContLvl = (String)mainRow.getAttribute("Attribute1");
                }

               OAViewObject templDtlVO = 
                   (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
               templDtlVO.setWhereClause(null);
               templDtlVO.setWhereClause("cust_doc_id = " + custDocId);
               if (templDtlVO.getRowCount() == 0) {
                   myAppsLog.write("fnd.common.WebAppsContext", 
                                   "XXOD: row count 0", 
                                   1);
                   sInitialFlag = "Y"; //Added for MD4B R3 
                   populateStdVO(custDocId, stdContLvl);
                   getOADBTransaction().commit();
                   OAViewObject templDtlVO1 = 
                       (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
                       templDtlVO1.setWhereClause(null);
                       templDtlVO1.setWhereClause("cust_doc_id = " + custDocId);
                       templDtlVO1.executeQuery();                 
               }
        
               /* Start - MOD 4B R3 */
               //Based on transaltion setup for concatenate and split fields
               //for enabling or disabling conc/split fields in configuration details tab
               OAViewObject custDocVO = 
                   (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
               String deliveryMethod = 
                   custDocVO.first().getAttribute("DeliveryMethod").toString();
               if (deliveryMethod.equals("eXLS")) {
                   myAppsLog.write("fnd.common.WebAppsContext", 
                                   "XXOD: exls deliverymethod", 
                                   1);
                   OAViewObject concatVO = 
                       (OAViewObject)this.findViewObject("ODEBillConcatFieldsPVO");

                   concatVO.executeQuery();


                   OAViewObject splitVO = 
                       (OAViewObject)this.findViewObject("ODEBillSplitFieldsPVO");

                   splitVO.executeQuery();


                   if ("Y".equals(sInitialFlag)){
                       myAppsLog.write("fnd.common.WebAppsContext", 
                                       "XXOD: Initial", 
                                       1);
                       refreshTemplDtlVOOnChecking(templDtlVO, concatVO, splitVO);
                   }
                   else {
                       myAppsLog.write("fnd.common.WebAppsContext", 
                                       "XXOD: not initial", 
                                       1);
                       RowSetIterator rsi = 
                           templDtlVO.createRowSetIterator("rowsRSI");
                       rsi.reset();
                       while (rsi.hasNext()) {
                           Row templDtlRow = rsi.next();

                           String sConcat = null;
                           String sSplit = null;
                           String sSelect = null;


                           if (templDtlRow.getAttribute("Concatenate") != null)
                               sConcat = 
                                       templDtlRow.getAttribute("Concatenate").toString();

                           if (templDtlRow.getAttribute("Split") != null)
                               sSplit = templDtlRow.getAttribute("Split").toString();

                           if (templDtlRow.getAttribute("Attribute1") != null)
                               sSelect = 
                                       templDtlRow.getAttribute("Attribute1").toString();


                           if (("Y".equals(sConcat)) || ("Y".equals(sSplit))) {
                               templDtlRow.setAttribute("Attribute1", "Y");
                               templDtlRow.setAttribute("Attribute20", "N"); 
                               
                           }


                           oracle.jbo.domain.Number nFieldId = null;

                           nFieldId = 
                                   (oracle.jbo.domain.Number)templDtlRow.getAttribute("FieldId");
                           String sField = "" + nFieldId;                          
                           templDtlRow.setAttribute("ConcatFlag", Boolean.TRUE);
                           templDtlRow.setAttribute("SplitFlag", Boolean.TRUE);

                           if (!((Boolean)PPRRow.getAttribute("Complete"))) {

                               concatVO.reset();
                               while (concatVO.hasNext()) {
                                   String sCode = null;
                                   OARow concatVORow = (OARow)concatVO.next();
                                   sCode = (String)concatVORow.getAttribute("Code");

                                   if (sField.equals(sCode)) {
                                       templDtlRow.setAttribute("ConcatFlag", 
                                                                Boolean.FALSE);
                                       break;
                                   }


                               }

                               splitVO.reset();
                               while (splitVO.hasNext()) {
                                   String sCode = null;
                                   OARow splitVORow = (OARow)splitVO.next();
                                   sCode = (String)splitVORow.getAttribute("Code");

                                   if (sField.equals(sCode)) {

                                       templDtlRow.setAttribute("SplitFlag", 
                                                                Boolean.FALSE);
                                       break;
                                   }


                               }
                           } 


                       }
                   }
               }

             // } /* End - MOD 4B R3 */
       // }
        } // End populateTemplSumDtl()

    public void handleSubTotalFieldAliasPPR(String sEnableExcelGrouping) {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAMImpl: handleSubTotalFieldAliasPPR");
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        if ("Y".equalsIgnoreCase(sEnableExcelGrouping)) {
            PPRRow.setAttribute("EnableXlsSubtotal", Boolean.TRUE);
        } else {
            PPRRow.setAttribute("EnableXlsSubtotal", Boolean.FALSE);
        }

    }
    
    //Added by Bhagwan Rao for Defect#38962 09Feb2017    
     public void handleDtlRepeatTotalLabelPPR(String sRepeatTotalLabel) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleDtlRepeatTotalLabelPPR", 1);

        OAViewObject templDtlTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
            
        RowSetIterator rsi = templDtlTxtVO.createRowSetIterator("rowsRSI");
        rsi.reset();

        while (rsi.hasNext()) {
            Row templRow = rsi.next();
            templRow.setAttribute("RepeatTotalFlag", sRepeatTotalLabel);
        }
        
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:End handleDtlRepeatTotalLabelPPR", 1);
    }
 
    //Added by Bhagwan Rao for Defect#38962 15Feb2017
    
     public void handleSummaryBillPPR(String sSummaryBill) {
      AppsLog myAppsLog = new AppsLog();
      myAppsLog.write("ODEBillTxtAMImpl", "XXOD:Start  handleSummaryBillPPR", 
                      1);

      OAViewObject ebillMainVO = 
          (OAViewObject)this.findViewObject("ODEBillMainVO");

      RowSetIterator rsi = ebillMainVO.createRowSetIterator("rowsRSI");


      rsi.reset();

      while (rsi.hasNext()) {
          Row ebillMainRow = rsi.next();
          //RepeatHeader has to be changed with original attribute name
          ebillMainRow.setAttribute("SummaryBill", sSummaryBill);

      }
      myAppsLog.write("ODEBillAMImpl", "XXOD:End handleSummaryBillPPR", 1);

     }

     
    public String handleTransPPR() {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAMImpl: handleTransPPR");
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        OAViewObject mainVO = (OAViewObject)this.getODEBillMainVO();
        OARow mainRow = (OARow)mainVO.first();

        String transmissionType = null;
        if (mainRow != null)
            transmissionType = 
                    (String)mainRow.getAttribute("EbillTransmissionType");

        utl.log("Inside ODEBillAMImpl: handleTransPPR: Transmission Type:" + 
                transmissionType);

        if ((transmissionType == null) || ("EMAIL".equals(transmissionType))) {
            PPRRow.setAttribute("Email", Boolean.TRUE);
            PPRRow.setAttribute("CD", Boolean.FALSE);
            PPRRow.setAttribute("FTP", Boolean.FALSE);
        } else if (("CD".equals(transmissionType))) {
            PPRRow.setAttribute("CD", Boolean.TRUE);
            PPRRow.setAttribute("Email", Boolean.FALSE);
            PPRRow.setAttribute("FTP", Boolean.FALSE);
        } else if (("FTP".equals(transmissionType))) {
            PPRRow.setAttribute("FTP", Boolean.TRUE);
            PPRRow.setAttribute("Email", Boolean.FALSE);
            PPRRow.setAttribute("CD", Boolean.FALSE);
        }
        utl.log("End of handleTransPPR");

        return transmissionType;
    } // End handleTransPPR()


    public void handleConfigHeaderConcatSplitPPR(String sConcatSplit) {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAMImpl: handleConfigHeaderConcatSplitPPR");
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("fnd.common.WebAppsContext", 
                        "XXOD: Start ODEBillAMImpl: handleConfigHeaderConcatSplitPPR", 
                        1);


        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");

        OAViewObject concatFieldsVO = 
            (OAViewObject)this.findViewObject("ODEBillConcatFieldsPVO");

        OAViewObject splitFieldsVO = 
            (OAViewObject)this.findViewObject("ODEBillSplitFieldsPVO");

        refreshTemplDtlVOOnChecking(templDtlVO, concatFieldsVO, splitFieldsVO);      
        renderConcatSplit(sConcatSplit);

        myAppsLog.write("fnd.common.WebAppsContext", 
                        "XXOD: End ODEBillAMImpl: handleConfigHeaderConcatSplitPPR", 
                        1);

    }

    //Defaulting values for transmission fields

    public void defaultTrans(String emailSubj, String emailStdMsg, 
                             String emailSign, String emailStdDisc, 
                             String emailSplInst, String ftpEmailSubj, 
                             String ftpEmailCont, String ftpNotiFileTxt, 
                             String ftpNotiEmailTxt) {

        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAMImpl: defaultTrans");

        OAViewObject mainVO = (OAViewObject)this.getODEBillMainVO();
        OARow mainRow = (OARow)mainVO.first();

        String transmissionType = null;
        String custDocId = null;

        if (mainRow != null) {
            transmissionType = 
                    (String)mainRow.getAttribute("EbillTransmissionType");
            custDocId = mainRow.getAttribute("CustDocId").toString();
        }

        utl.log("Inside ODEBillAMImpl: defaultTrans: Transmission Type:" + 
                transmissionType);

        if ((transmissionType == null) || ("EMAIL".equals(transmissionType))) {
            defaultEmail(custDocId, emailSubj, emailStdMsg, emailSign, 
                         emailStdDisc, emailSplInst);
            nullCD();
            nullFTP();

        } else if (("CD".equals(transmissionType))) {

            OAViewObject transVO = 
                (OAViewObject)findViewObject("ODEBillTransmissionVO");
            OARow transRow = (OARow)transVO.first();
            transRow.setAttribute("CustDocId", custDocId);
            nullEmail();
            nullFTP();
            deleteContacts();
        } else if (("FTP".equals(transmissionType))) {
            defaultFTP(custDocId, ftpEmailSubj, ftpEmailCont, ftpNotiFileTxt, 
                       ftpNotiEmailTxt);
            nullEmail();
            nullCD();
            deleteContacts();
        }
    }

    //Method to delete all the Contact details

    public void deleteContacts() {

        ODUtil utl = new ODUtil(this);
        utl.log("Inside AM: deleteContacts ");

        OAViewObject contactVO = (OAViewObject)this.getODEBillContactsVO();
        ODEBillContactsVORowImpl contactRow = null;

        int fetchedRowCount = contactVO.getFetchedRowCount();
        utl.log("Number of rows fetched" + fetchedRowCount);
        RowSetIterator deleteIter = 
            contactVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);
            for (int i = 0; i < fetchedRowCount; i++) {
                utl.log("Value of i" + i);
                contactRow = 
                        (ODEBillContactsVORowImpl)deleteIter.getRowAtRangeIndex(0);
                if (contactRow != null) {
                    contactRow.remove();
                }
            }
        }
        deleteIter.closeRowSetIterator();

    } // End deleteContactName(String eblDocContactId)


    public void handleCompressPPR() {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside handleCompresssPPR");
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        OAViewObject mainVO = (OAViewObject)this.getODEBillMainVO();
        OARow mainRow = (OARow)mainVO.first();

        OAViewObject custHeadVO = 
            (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
        OARow custHeadRow = (OARow)custHeadVO.first();

        String zipRequired = null;
        String docStatus = null;

        if (mainRow != null && custHeadRow != null && PPRRow != null) {
            zipRequired = (String)mainRow.getAttribute("ZipRequired");
            docStatus = (String)custHeadRow.getAttribute("Status");
            utl.log("Inside handleCompresssPPR: Status: " + docStatus);
            if ((zipRequired == null) || ("N".equals(zipRequired))) {
                PPRRow.setAttribute("Compress", Boolean.TRUE);
                mainRow.setAttribute("ZippingUtility", null);
                mainRow.setAttribute("ZipFileNameExt", null);
            } else if ("Y".equals(zipRequired)) {
                PPRRow.setAttribute("Compress", Boolean.FALSE);
                mainRow.setAttribute("ZippingUtility", "ZIP");

            }
            /*    if("Complete".equals(docStatus))
       {
         PPRRow.setAttribute("Compress", Boolean.TRUE );
       }
       */

        }
        utl.log("End of handleCompressPPR");

    } // End handleCompressPPR()

    public void handleDelimitedPPR() {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside handleDelimitedPPR");
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        OAViewObject templHdrVO = (OAViewObject)this.getODEBillTempHeaderVO();
        OARow templHdrRow = (OARow)templHdrVO.first();

        OAViewObject custHeadVO = 
            (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
        OARow custHeadRow = (OARow)custHeadVO.first();

        String fileCreationType = null;
        String docStatus = null;
        if (templHdrRow != null) {
            fileCreationType = 
                    (String)templHdrRow.getAttribute("EbillFileCreationType");
            docStatus = (String)custHeadRow.getAttribute("Status");
            utl.log("Inside handleDelimitedPPR:: docStatus ::" + docStatus);

            if ((fileCreationType == null) || 
                ("FIXED".equals(fileCreationType))) {
                PPRRow.setAttribute("FileCreationType", Boolean.TRUE);
                templHdrRow.setAttribute("DelimiterChar", null);
            } else if ("DELIMITED".equals(fileCreationType)) {
                PPRRow.setAttribute("FileCreationType", Boolean.FALSE);
            }
            if ("Complete".equals(docStatus))
                PPRRow.setAttribute("FileCreationType", Boolean.TRUE);
        }
        utl.log("End of handleDelimitedPPR");

    } // End handleDelimitedPPR()

    public void handleLogoReqPPR() {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside handleLogoReqPPR");
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        //   OAViewObject transmissionVO = (OAViewObject) this.getODEBillTransmissionVO();
        OAViewObject transmissionVO = 
            (OAViewObject)this.findViewObject("ODEBillTransmissionVO");
        OARow transmissionRow = (OARow)transmissionVO.first();

        OAViewObject custHeadVO = 
            (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
        OARow custHeadRow = (OARow)custHeadVO.first();

        String emailLogoRequired = null;
        String docStatus = null;
        if (transmissionRow != null) {
            emailLogoRequired = 
                    (String)transmissionRow.getAttribute("EmailLogoRequired");
            docStatus = (String)custHeadRow.getAttribute("Status");

            if ((emailLogoRequired == null) || 
                ("N".equals(emailLogoRequired))) {
                PPRRow.setAttribute("LogoReq", Boolean.TRUE);
                transmissionRow.setAttribute("EmailLogoFileName", null);
            } else if ("Y".equals(emailLogoRequired)) {
                PPRRow.setAttribute("LogoReq", Boolean.FALSE);
                transmissionRow.setAttribute("EmailLogoFileName", 
                                             "OFFICEDEPOT");
            }
            if ("Complete".equals(docStatus))
                PPRRow.setAttribute("LogoReq", Boolean.TRUE);
        }

        utl.log("End of handleLogoReqPPR");

    } // End handleLogoReqPPR()

    /*Method to handle FtpNotifyCustomer PPR  */

    public void handleNotifyCustPPR(String ftpEmailSubj, String ftpEmailCont) {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside handleNotifyCustPPR");
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        OAViewObject transmissionVO = 
            (OAViewObject)this.findViewObject("ODEBillTransmissionVO");
        OARow transmissionRow = (OARow)transmissionVO.first();

        OAViewObject custHeadVO = 
            (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
        OARow custHeadRow = (OARow)custHeadVO.first();

        String ftpNotifyCustomer = null;
        String docStatus = null;
        if (transmissionRow != null) {
            ftpNotifyCustomer = 
                    (String)transmissionRow.getAttribute("FtpNotifyCustomer");
            docStatus = (String)custHeadRow.getAttribute("Status");

            if ((ftpNotifyCustomer == null) || 
                ("N".equals(ftpNotifyCustomer))) {
                PPRRow.setAttribute("FtpNotifyCustomer", Boolean.TRUE);
                transmissionRow.setAttribute("FtpCustContactName", null);
                transmissionRow.setAttribute("FtpCustContactEmail", "");
                transmissionRow.setAttribute("FtpCustContactPhone", null);
                transmissionRow.setAttribute("FtpCcEmails", null);
                transmissionRow.setAttribute("FtpEmailSub", null);
                transmissionRow.setAttribute("FtpEmailContent", null);
            } else if ("Y".equals(ftpNotifyCustomer)) {
                PPRRow.setAttribute("FtpNotifyCustomer", Boolean.FALSE);
                // Added the below if condition for Defect# 7491
                if (transmissionRow.getAttribute("FtpEmailSub") == null) {
                    transmissionRow.setAttribute("FtpEmailSub", ftpEmailSubj);
                }
                if (transmissionRow.getAttribute("FtpEmailContent") == null) {
                    transmissionRow.setAttribute("FtpEmailContent", 
                                                 ftpEmailCont);
                }
                // End of changes for Defect# 7491
            }
            /* if("Complete".equals(docStatus))
         PPRRow.setAttribute("FtpNotifyCustomer", Boolean.TRUE);   */
        }

        utl.log("End of handleNotifyCustPPR");

    } // End handleNotifyCustPPR()


    /* Method to handle FtpSendZeroByteFile PPR  */

    public void handleSendZeroPPR(String ftpNotiFileTxt, 
                                  String ftpNotiEmailTxt) {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside handleSendZeroPPR");
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        OAViewObject transmissionVO = 
            (OAViewObject)this.findViewObject("ODEBillTransmissionVO");
        OARow transmissionRow = (OARow)transmissionVO.first();

        OAViewObject custHeadVO = 
            (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
        OARow custHeadRow = (OARow)custHeadVO.first();

        String ftpSendZeroByteFile = null;
        String docStatus = null;
        if (transmissionRow != null) {
            ftpSendZeroByteFile = 
                    (String)transmissionRow.getAttribute("FtpSendZeroByteFile");
            docStatus = (String)custHeadRow.getAttribute("Status");

            if ((ftpSendZeroByteFile == null) || 
                ("N".equals(ftpSendZeroByteFile))) {
                PPRRow.setAttribute("FtpSendZeroByteFile", Boolean.TRUE);
                transmissionRow.setAttribute("FtpZeroByteFileText", null);
                transmissionRow.setAttribute("FtpZeroByteNotificationTxt", 
                                             null);
            } else if ("Y".equals(ftpSendZeroByteFile)) {
                PPRRow.setAttribute("FtpSendZeroByteFile", Boolean.FALSE);

                // Added the below if condition for Defect# 7491
                if (transmissionRow.getAttribute("FtpZeroByteFileText") == 
                    null) {
                    transmissionRow.setAttribute("FtpZeroByteFileText", 
                                                 ftpNotiFileTxt);
                }
                if (transmissionRow.getAttribute("FtpZeroByteNotificationTxt") == 
                    null) {
                    transmissionRow.setAttribute("FtpZeroByteNotificationTxt", 
                                                 ftpNotiEmailTxt);
                }
                // End of changes for Defect# 7491

            }
            /*  if("Complete".equals(docStatus))
         PPRRow.setAttribute("FtpSendZeroByteFile", Boolean.TRUE);    */
        }

        utl.log("End of handleSendZeroPPR");

    } // End handleSendZeroPPR()


    /* Method to handle NSFieldChange PPR  */

    public void handleNSFieldChangePPR(String eblTemplId) {
        ODUtil utl = new ODUtil(this);
        try {
            utl.log("Inside handleNSFieldChangePPR: eblTemplId: " + 
                    eblTemplId);

            OAViewObject nonStdVO = 
                (OAViewObject)this.findViewObject("ODEBillNonStdVO");
            Number nEblTemplId = new Number(eblTemplId);
            OARow nonStdRow = 
                (OARow)nonStdVO.getFirstFilteredRow("EblTemplId", nEblTemplId);

            if (nonStdRow != null) {
                Number fieldId = (Number)nonStdRow.getAttribute("FieldId");
                utl.log("Inside handleNSFieldChangePPR: fieldId: " + fieldId);
                OAViewObject nsFieldVO = 
                    (OAViewObject)this.findViewObject("ODEBillNSFieldNamesPVO");
                if (nsFieldVO != null) {
                    utl.log("Inside handleNSFieldChangePPR: nsFieldVO: " + 
                            nsFieldVO);
                    OARow nsFieldRow = (OARow)nsFieldVO.first();
                    for (int i = 0; i < nsFieldVO.getRowCount(); i++) {
                        if (fieldId.equals(nsFieldRow.getAttribute("FieldId"))) {
                            utl.log("Inside handleNSFieldChangePPR: fieldId: " + 
                                    nsFieldRow.getAttribute("FieldName"));
                            nonStdRow.setAttribute("Label", 
                                                   nsFieldRow.getAttribute("FieldName"));
                            nonStdRow.setAttribute("DataFormat", 
                                                   nsFieldRow.getAttribute("DataFormat"));
                            break;
                        }
                        nsFieldRow = (OARow)nsFieldVO.next();
                    }
                }
            }

        } catch (SQLException sqlExce) {
            utl.log("SQLException in handleNSFieldChangePPR");
        }

        utl.log("End of handleNSFieldChangePPR");

    } // End handleNSFieldChangePPR()


    public void initPPRVO(String statusCode) {

        ODUtil utl = new ODUtil(this);
        utl.log("Inside initPPRVO: Status:" + statusCode);

        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();

        if (PPRVO != null) {
            if (PPRVO.getFetchedRowCount() == 0) {
                PPRVO.setMaxFetchSize(0);
                PPRVO.executeQuery();
                PPRVO.insertRow(PPRVO.createRow());
            }
            OARow PPRRow = (OARow)PPRVO.first();
            PPRRow.setAttribute("RowKey", new Number(1));
            if (statusCode.equals("COMPLETE")) {
                PPRRow.setAttribute("Complete", Boolean.TRUE);
                PPRRow.setAttribute("CompleteDelBtn", Boolean.FALSE);
                PPRRow.setAttribute("CSSClass", "OraDataText");

            } else {
                PPRRow.setAttribute("Complete", Boolean.FALSE);
                PPRRow.setAttribute("CompleteDelBtn", Boolean.TRUE);
            }
        }

        //handleTransPPR();
        utl.log("End of initPPRVO");
    } // End initPPRVO()
    
   public void handleconfigPPR(String deliveryMethod, String statusCode) {
            ODUtil utl = new ODUtil(this);
            utl.log("Inside handleconfigPPR, deliveryMethod: " + deliveryMethod + 
                    ":Status:" + statusCode);
            OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
            OARow PPRRow = (OARow)PPRVO.first();

            if ("eXLS".equals(deliveryMethod)) {
                PPRRow.setAttribute("Std", Boolean.TRUE);
                PPRRow.setAttribute("NonStd", Boolean.FALSE);
                PPRRow.setAttribute("FieldSelection", Boolean.FALSE);
            } else if ("eTXT".equals(deliveryMethod)) {
                PPRRow.setAttribute("Std", Boolean.FALSE);
                PPRRow.setAttribute("NonStd", Boolean.TRUE);
                PPRRow.setAttribute("FieldSelection", Boolean.TRUE);
            } else {
                PPRRow.setAttribute("Std", Boolean.FALSE);
                PPRRow.setAttribute("NonStd", Boolean.FALSE);
                PPRRow.setAttribute("FieldSelection", Boolean.TRUE);
            }
            if ("COMPLETE".equals(statusCode))
                PPRRow.setAttribute("FieldSelection", Boolean.FALSE);

            utl.log("End of handleconfigPPR");

        } // End handleconfigPPR()



    //Method to delete File Field Name

    public void deleteFileName(String eblFileNameId) {
        ODUtil utl = new ODUtil(this);

        int eblFileNameIdPara = Integer.parseInt(eblFileNameId);
        utl.log("Inside AM: DeleteFileName: eblFileNameIdPara: " + 
                eblFileNameIdPara);

        OAViewObject fileNameVO = (OAViewObject)this.getODEBillFileNameVO();
        ODEBillFileNameVORowImpl fileNameRow = null;

        int fetchedRowCount = fileNameVO.getFetchedRowCount();
        RowSetIterator deleteIter = 
            fileNameVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);
            for (int i = 0; i < fetchedRowCount; i++) {
                fileNameRow = 
                        (ODEBillFileNameVORowImpl)deleteIter.getRowAtRangeIndex(i);
                Number eblFileNameIdAttr = 
                    (Number)fileNameRow.getAttribute("EblFileNameId");

                if (eblFileNameIdAttr.compareTo(eblFileNameIdPara) == 0) {
                    fileNameRow.remove();
                    break;
                }
            }
        }
        deleteIter.closeRowSetIterator();

    } //End deleteFileName(String eblFileNameId)

    //Method to delete Contact Name selected

    public void deleteContactName(String eblDocContactId) {

        ODUtil utl = new ODUtil(this);

        int eblDocContactIdPara = Integer.parseInt(eblDocContactId);

        utl.log("Inside AM: deleteContactName: eblDocContactIdPara: " + 
                eblDocContactIdPara);

        OAViewObject contactVO = (OAViewObject)this.getODEBillContactsVO();
        ODEBillContactsVORowImpl contactRow = null;

        int fetchedRowCount = contactVO.getFetchedRowCount();
        RowSetIterator deleteIter = 
            contactVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);

            for (int i = 0; i < fetchedRowCount; i++) {
                contactRow = 
                        (ODEBillContactsVORowImpl)deleteIter.getRowAtRangeIndex(i);

                Number eblDocContactIdAttr = 
                    (Number)contactRow.getAttribute("EblDocContactId");

                if (eblDocContactIdAttr.compareTo(eblDocContactIdPara) == 0) {
                    contactRow.remove();
                    break;
                }
            }
        }

        deleteIter.closeRowSetIterator();
        deleteEnableDisable(); //Defcet # 11568

    } // End deleteContactName(String eblDocContactId)

    //Method to delete SubTotal field

    public void deleteSubTotal(String eblAggrId) {
        ODUtil utl = new ODUtil(this);

        int eblAggrIdPara = Integer.parseInt(eblAggrId);

        utl.log("Inside AM: deleteSubTotal: eblAggrIdPara: " + eblAggrIdPara);

        OAViewObject StdAggrDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillStdAggrDtlVO");
        ODEBillStdAggrDtlVORowImpl AggrDtlRow = null;

        int fetchedRowCount = StdAggrDtlVO.getFetchedRowCount();

        RowSetIterator deleteIter = 
            StdAggrDtlVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);

            for (int i = 0; i < fetchedRowCount; i++) {
                AggrDtlRow = 
                        (ODEBillStdAggrDtlVORowImpl)deleteIter.getRowAtRangeIndex(i);
                Number eblAggrIdAttr = 
                    (Number)AggrDtlRow.getAttribute("EblAggrId");

                if (eblAggrIdAttr.compareTo(eblAggrIdPara) == 0) {
                    AggrDtlRow.remove();
                    break;
                }
            }
        }
        deleteIter.closeRowSetIterator();
    } //End deleteSubTotal(String eblAggrId)


    /*Method to delete Non Standard Template Field */

    public void deleteNonStdRow(String eblTemplId) {

        ODUtil utl = new ODUtil(this);

        int eblTemplIdPara = Integer.parseInt(eblTemplId);

        utl.log("Inside deleteField: eblTemplIdPara " + eblTemplIdPara);
        OAViewObject nonStdVO = (OAViewObject)this.getODEBillNonStdVO();
        ODEBillNonStdVORowImpl nonStdRow = null;

        int fetchedRowCount = nonStdVO.getFetchedRowCount();
        RowSetIterator deleteIter = 
            nonStdVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);

            for (int i = 0; i < fetchedRowCount; i++) {
                nonStdRow = 
                        (ODEBillNonStdVORowImpl)deleteIter.getRowAtRangeIndex(i);
                Number eblTemplIdAttr = 
                    (Number)nonStdRow.getAttribute("EblTemplId");
                if (eblTemplIdAttr.compareTo(eblTemplIdPara) == 0) {
                    nonStdRow.remove();
                    break;
                }
            }
        }
        deleteIter.closeRowSetIterator();

    } // End deleteNonStdRow (String eblTemplId)

    public void addContact(String custDocId, String custAcctId, 
                           String siteUseCode) {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside addContact: DocId" + custDocId + " CustAcctId: " + 
                custAcctId);

        OADBTransaction transaction = this.getOADBTransaction();

        OAViewObject contactVO = (OAViewObject)this.getODEBillContactsVO();
        contactVO.last();
        contactVO.next();
        OARow contactRow = (OARow)contactVO.createRow();
        contactRow.setAttribute("CustDocId", custDocId);
        contactRow.setAttribute("Attribute1", custAcctId);
        contactRow.setAttribute("SiteUseCode", siteUseCode);
        contactRow.setAttribute("DeleteImageSwitch", "DeleteDisable");
        contactRow.setAttribute("EblDocContactId", 
                                transaction.getSequenceValue("XX_CDH_EBL_DOC_CONTACT_ID_S"));
        contactVO.insertRow(contactRow);
        contactRow.setNewRowState(contactRow.STATUS_INITIALIZED);
    } //End addContact(String custDocId, String custAcctId, String siteUseCode )

    /* Method to insert a new row for File Naming parameters when user clicks on Add Field button in File Name Parameter tab. */

    public void addFileName(String custDocId) {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside addFileName: DocId" + custDocId);
        Number seq = new Number(10);
        OADBTransaction transaction = this.getOADBTransaction();

        OAViewObject fileNameVO = (OAViewObject)this.getODEBillFileNameVO();
        OARow lastRow = (OARow)fileNameVO.last();
        if (lastRow != null) {
            seq = (Number)lastRow.getAttribute("FileNameOrderSeq");
            seq = new Number(seq.longValue() + 10);
        }
        fileNameVO.next();
        OARow fileNameRow = (OARow)fileNameVO.createRow();
        fileNameRow.setAttribute("EblFileNameId", 
                                 transaction.getSequenceValue("XX_CDH_EBL_FILE_NAME_ID_S"));
        fileNameRow.setAttribute("CustDocId", custDocId);
        fileNameRow.setAttribute("FileNameOrderSeq", seq);
        fileNameVO.insertRow(fileNameRow);
        fileNameRow.setNewRowState(fileNameRow.STATUS_INITIALIZED);
    } //End addFileName(String custDocId )


    /*Method to insert a default rows for File Naming parameters when user clicks on Add Field button.*/

    public void addDefaultFileNames(String custDocId, String directDoc, 
                                    String custDocType) {
        ODUtil utl = new ODUtil(this);
        AppsLog myAppsLog = new AppsLog();

        myAppsLog.write("fnd.common.WebAppsContext", 
                        "Inside ODEBillAMImpl: addDefaultFileNames" + 
                        "Inside addDefaultFileNames: DocId" + custDocId + 
                        " Direct doc: " + directDoc, 1);
        utl.log("Inside addDefaultFileNames: DocId" + custDocId + 
                " Direct doc: " + directDoc);

        OADBTransaction transaction = this.getOADBTransaction();

        OAViewObject fileNameVO = (OAViewObject)this.getODEBillFileNameVO();

        int seq = 0;

        fileNameVO.last();
        fileNameVO.next();
        seq = seq + 10;


        myAppsLog.write("fnd.common.WebAppsContext", "10.10 seq " + seq, 1);

        OARow fileNameRow1 = (OARow)fileNameVO.createRow();
        fileNameRow1.setAttribute("EblFileNameId", 
                                  transaction.getSequenceValue("XX_CDH_EBL_FILE_NAME_ID_S"));
        fileNameRow1.setAttribute("CustDocId", custDocId);
        fileNameRow1.setAttribute("FileNameOrderSeq", new Number(seq));
        fileNameRow1.setAttribute("FieldId", new Number(10003));
        fileNameVO.insertRow(fileNameRow1);


        fileNameVO.last();
        fileNameVO.next();
        seq = seq + 10;
        myAppsLog.write("fnd.common.WebAppsContext", "10.20 seq " + seq, 1);
        OARow fileNameRow2 = (OARow)fileNameVO.createRow();
        fileNameRow2.setAttribute("EblFileNameId", 
                                  transaction.getSequenceValue("XX_CDH_EBL_FILE_NAME_ID_S"));
        fileNameRow2.setAttribute("CustDocId", custDocId);
        fileNameRow2.setAttribute("FileNameOrderSeq", new Number(seq));
        fileNameRow2.setAttribute("FieldId", new Number(10118));
        fileNameVO.insertRow(fileNameRow2);

        if ("N".equals(directDoc)) {
            fileNameVO.last();
            fileNameVO.next();
            seq = seq + 10;
            myAppsLog.write("fnd.common.WebAppsContext", "10.30 seq " + seq, 
                            1);
            OARow fileNameRow4 = (OARow)fileNameVO.createRow();
            fileNameRow4.setAttribute("EblFileNameId", 
                                      transaction.getSequenceValue("XX_CDH_EBL_FILE_NAME_ID_S"));
            fileNameRow4.setAttribute("CustDocId", custDocId);
            fileNameRow4.setAttribute("FileNameOrderSeq", new Number(seq));
            fileNameRow4.setAttribute("FieldId", new Number(10032));
            fileNameVO.insertRow(fileNameRow4);
        }

        fileNameVO.last();
        fileNameVO.next();
        seq = seq + 10;
        myAppsLog.write("fnd.common.WebAppsContext", "10.40 seq " + seq, 1);
        OARow fileNameRow3 = (OARow)fileNameVO.createRow();
        fileNameRow3.setAttribute("EblFileNameId", 
                                  transaction.getSequenceValue("XX_CDH_EBL_FILE_NAME_ID_S"));
        fileNameRow3.setAttribute("CustDocId", custDocId);
        fileNameRow3.setAttribute("FileNameOrderSeq", new Number(seq));
        fileNameRow3.setAttribute("FieldId", new Number(10007));
        fileNameVO.insertRow(fileNameRow3);

        if ("Invoice".equals(custDocType)) {
            fileNameVO.last();
            fileNameVO.next();
            seq = seq + 10;
            myAppsLog.write("fnd.common.WebAppsContext", "10.50 seq " + seq, 
                            1);
            OARow fileNameRow5 = (OARow)fileNameVO.createRow();
            fileNameRow5.setAttribute("EblFileNameId", 
                                      transaction.getSequenceValue("XX_CDH_EBL_FILE_NAME_ID_S"));
            fileNameRow5.setAttribute("CustDocId", custDocId);
            fileNameRow5.setAttribute("FileNameOrderSeq", new Number(seq));
            fileNameRow5.setAttribute("FieldId", new Number(10023));
            fileNameVO.insertRow(fileNameRow5);
        } else if ("Consolidated Bill".equals(custDocType)) {
            fileNameVO.last();
            fileNameVO.next();
            seq = seq + 10;
            myAppsLog.write("fnd.common.WebAppsContext", "10.60 seq " + seq, 
                            1);
            OARow fileNameRow6 = (OARow)fileNameVO.createRow();
            fileNameRow6.setAttribute("EblFileNameId", 
                                      transaction.getSequenceValue("XX_CDH_EBL_FILE_NAME_ID_S"));
            fileNameRow6.setAttribute("CustDocId", custDocId);
            fileNameRow6.setAttribute("FileNameOrderSeq", new Number(seq));
            fileNameRow6.setAttribute("FieldId", new Number(10005));
            fileNameVO.insertRow(fileNameRow6);
        }

    } //End addFileName(String custDocId )

    //Method to insert a new row for Non Standard template when user clicks on Add Field button.

    public void addNonStdField(String custDocId) {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside addNonStdField: DocId" + custDocId);

        OADBTransaction transaction = this.getOADBTransaction();

        OAViewObject NonStdVO = (OAViewObject)this.getODEBillNonStdVO();
        NonStdVO.last();
        Number seq = new Number(10);
        OARow lastRow = (OARow)NonStdVO.last();
        if (lastRow != null) {
            seq = (Number)lastRow.getAttribute("Seq");
            seq = new Number(seq.longValue() + 10);
        }
        NonStdVO.next();
        OARow NonStdRow = (OARow)NonStdVO.createRow();
        NonStdRow.setAttribute("EblTemplId", 
                               transaction.getSequenceValue("XX_CDH_EBL_TEMPL_ID_S"));
        utl.log("Inside addNonStdField: EblTemplId" + 
                NonStdRow.getAttribute("EblTemplId"));
        NonStdRow.setAttribute("CustDocId", custDocId);
        NonStdRow.setAttribute("Seq", seq);
        NonStdVO.insertRow(NonStdRow);
        NonStdRow.setNewRowState(NonStdRow.STATUS_INITIALIZED);
    } //End addNonStdField(String custDocId )


    //Method to insert a new row for Sub total when user clicks on Add Sub Total button.

    public void addSubTotal(String custDocId, String enableSubtotal, 
                            String sMaxSubTotals) {

        AppsLog myAppsLog = new AppsLog();


        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAM:addSubTotal: custDocId" + custDocId);

        OADBTransaction transaction = this.getOADBTransaction();


        OAViewObject custDocVO = 
            (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
        String deliveryMethod = 
            custDocVO.first().getAttribute("DeliveryMethod").toString();


        OAViewObject stdAggrDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillStdAggrDtlVO");
        stdAggrDtlVO.last();

        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext", 
                            "XXOD: addSubTotal::" + stdAggrDtlVO.getRowCount(), 
                            1);
        }
        if ((deliveryMethod.equals("eXLS")) && ("Y".equals(enableSubtotal))) {

            int nSubTotal = 0;

            if ((!"".equals(sMaxSubTotals)) && (sMaxSubTotals != null))
                nSubTotal = Integer.parseInt(sMaxSubTotals);

            if (nSubTotal == 0)
                throw new OAException("XXCRM", 
                                      "XXOD_EBL_MAX_SUBTOTALS_NOTCONF");

            if (stdAggrDtlVO.getRowCount() < nSubTotal) {
                stdAggrDtlVO.next();
                OARow stdAggrDtlRow = (OARow)stdAggrDtlVO.createRow();
                stdAggrDtlRow.setAttribute("EblAggrId", 
                                           transaction.getSequenceValue("XX_CDH_EBL_AGGR_ID_S"));
                stdAggrDtlRow.setAttribute("CustDocId", custDocId);

                stdAggrDtlVO.insertRow(stdAggrDtlRow);
                stdAggrDtlRow.setNewRowState(stdAggrDtlRow.STATUS_INITIALIZED);

            } else {

                MessageToken[] tokens = 
                { new MessageToken("COUNT", sMaxSubTotals) };


                throw new OAException("XXCRM", "XXOD_EBL_MAX_SUBTOTALS", 
                                      tokens, OAException.ERROR, null);
            }
        } else {
            stdAggrDtlVO.next();
            OARow stdAggrDtlRow = (OARow)stdAggrDtlVO.createRow();
            stdAggrDtlRow.setAttribute("EblAggrId", 
                                       transaction.getSequenceValue("XX_CDH_EBL_AGGR_ID_S"));
            stdAggrDtlRow.setAttribute("CustDocId", custDocId);

            stdAggrDtlVO.insertRow(stdAggrDtlRow);
            stdAggrDtlRow.setNewRowState(stdAggrDtlRow.STATUS_INITIALIZED);
        }
    } //End addSubTotal(String custDocId)

    //Method to insert a new concatenate row 


    //Method to insert a new split row 

    public void addSplitRow(String custAccountId, String custDocId, 
                            String maxSplitRows) {

        AppsLog myAppsLog = new AppsLog();


        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAM:addSplitRow: custDocId" + custDocId);
        utl.log("Inside ODEBillAM:addSplitRow: custAccountId" + custAccountId);

        myAppsLog.write("fnd.common.WebAppsContext", 
                        "XXOD: custDocId::" + custDocId, 1);
        myAppsLog.write("fnd.common.WebAppsContext", 
                        "XXOD: custAccountId::" + custAccountId, 1);
        OADBTransaction transaction = this.getOADBTransaction();


        OAViewObject splitVO = 
            (OAViewObject)this.findViewObject("ODEBillSplitVO");
        splitVO.last();

        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext", 
                            "XXOD: addSplitRow::" + splitVO.getRowCount(), 1);
        }

        int nMaxSplitRows = 0;
        if ((!"".equals(maxSplitRows)) && (maxSplitRows != null))
            nMaxSplitRows = Integer.parseInt(maxSplitRows);

        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext", 
                            "XXOD: nMaxSplitRows::" + nMaxSplitRows, 1);
        }

        if (nMaxSplitRows == 0)
            throw new OAException("XXCRM", "XXOD_EBL_MAX_SPLIT_NOTCONF");    
        if (splitVO.getRowCount() < nMaxSplitRows) {
 
            OAViewObject dynSplitVO = 
                (OAViewObject)this.findViewObject("ODEBillDynSplitFieldsVO");
            
           /* int nCount = dynSplitVO.getRowCount();
            if (nCount == 0) {
                throw new OAException("XXCRM", "XXOD_EBL_SELSPLIT_DETAILS", 
                                      null, OAException.ERROR, null);
            }*/
            splitVO.next();
            OARow splitVORow = (OARow)splitVO.createRow();
            splitVORow.setAttribute("SplitFieldId", 
                                    transaction.getSequenceValue("XX_CDH_EBL_SPLIT_FIELDS_S"));
            splitVORow.setAttribute("CustDocId", custDocId);
            splitVORow.setAttribute("CustAccountId", custAccountId);

            splitVORow.setAttribute("EnableFixedPosition", Boolean.FALSE);
            splitVORow.setAttribute("EnableDelimiter", Boolean.TRUE);


            splitVO.insertRow(splitVORow);
            splitVORow.setNewRowState(splitVORow.STATUS_INITIALIZED);

        } else {
            MessageToken[] tokens = 
            { new MessageToken("COUNT", maxSplitRows) };


            throw new OAException("XXCRM", "XXOD_EBL_MAX_SPLITFIELDS", tokens, 
                                  OAException.ERROR, null);
        }


    } //End addSplit

    public void deleteSplit(String splitFieldId) {

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");


        ODUtil utl = new ODUtil(this);

        int splitFieldIdPara = Integer.parseInt(splitFieldId);

        utl.log("Inside AM: deleteConcat: splitFieldIdPara: " + 
                splitFieldIdPara);

        OAViewObject splitVO = 
            (OAViewObject)this.findViewObject("ODEBillSplitVO");
        ODEBillSplitVORowImpl splitVORow = null;

        int fetchedRowCount = splitVO.getFetchedRowCount();

        RowSetIterator deleteIter = splitVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);

            for (int i = 0; i < fetchedRowCount; i++) {
                splitVORow = 
                        (ODEBillSplitVORowImpl)deleteIter.getRowAtRangeIndex(i);
                Number splitFieldIdAttr = 
                    (Number)splitVORow.getAttribute("SplitFieldId");

                if (splitFieldIdAttr.compareTo(splitFieldIdPara) == 0) {

                    templDtlVO.reset();
                    while (templDtlVO.hasNext()) {

                        OARow templRow = (OARow)templDtlVO.next();
                        String sFieldId = "-1";
                        if (templRow.getAttribute("SplitFieldId") != null)
                            sFieldId = 
                                    templRow.getAttribute("SplitFieldId").toString();
                        if (splitFieldId.equals(sFieldId)) {

                            templRow.remove();
                        }

                    }

                    splitVORow.remove();
                    break;
                }
            }
        }
        deleteIter.closeRowSetIterator();


    } //End delete

    // For Delete

    public void deleteTrans(String pCustDocId) {
        OracleCallableStatement ocs = null;
        OADBTransaction db = this.getOADBTransaction();
        String s = 
            "BEGIN" + " XX_CDH_EBL_TEMPL_DTL_PKG.delete_all(p_cust_doc_id  => :1);" + 
            " END;";
        ocs = (OracleCallableStatement)db.createCallableStatement(s, 1);
        try {
            Number custDocId = new Number(pCustDocId);
            ocs.setNUMBER(1, custDocId);
            ocs.execute();
            ocs.close();
        } catch (SQLException e) {

            throw new OAException(e.toString(), OAException.ERROR);
        }
		finally {
			try {
				if (ocs != null)
					ocs.close();
			}
			catch(Exception exc) {  }
		}			
    } //End of deleteTrans(String pCustDocId)
    

    public void rollbackMain() {
        Transaction txn = 
            getTransaction(); // This small optimization ensures that we don't perform a rollback
        // if we don't have to.
        if (txn.isDirty()) {
            txn.rollback();
        }
    } // End rollbackMain()
	
	//Code Added for Defect# NAIT-40588 by Rafi - START
     public void commitData() {
         Transaction txn = 
             getTransaction();
             txn.commit();
    }
     
   public void displayRecheckOnSave(String custDocId) {
        ODUtil utl = new ODUtil(this);
        String sInitialFlag = "N";
        utl.log("Inside ODEBillAMImpl: displayRecheckOnSave for eXLS");
        
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("fnd.common.WebAppsContext", 
                        "XXOD: Inside ODEBillAMImpl: displayRecheckOnSave for eXLS", 
                        1);
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();             


        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
        templDtlVO.setWhereClause(null);
        templDtlVO.setWhereClause("cust_doc_id = " + custDocId);
        
        OAViewObject custDocVO = 
            (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
        String deliveryMethod = 
            custDocVO.first().getAttribute("DeliveryMethod").toString();
        if (deliveryMethod.equals("eXLS")) {
            myAppsLog.write("fnd.common.WebAppsContext", 
                            "XXOD: exls deliverymethod", 
                            1);
            OAViewObject concatVO = 
                (OAViewObject)this.findViewObject("ODEBillConcatFieldsPVO");
            concatVO.executeQuery();

            OAViewObject splitVO = 
                (OAViewObject)this.findViewObject("ODEBillSplitFieldsPVO");
            splitVO.executeQuery();

            if ("Y".equals(sInitialFlag)){
                myAppsLog.write("fnd.common.WebAppsContext", 
                                "XXOD: Initial", 
                                1);
                refreshTemplDtlVOOnChecking(templDtlVO, concatVO, splitVO);
            }
            else {
                myAppsLog.write("fnd.common.WebAppsContext", 
                                "XXOD: not initial", 
                                1);
                RowSetIterator rsi = 
                    templDtlVO.createRowSetIterator("rowsRSI");
                rsi.reset();
                while (rsi.hasNext()) {
                    Row templDtlRow = rsi.next();

                    String sConcat = null;
                    String sSplit = null;
                    String sSelect = null;


                    if (templDtlRow.getAttribute("Concatenate") != null)
                        sConcat = 
                                templDtlRow.getAttribute("Concatenate").toString();

                    if (templDtlRow.getAttribute("Split") != null)
                        sSplit = templDtlRow.getAttribute("Split").toString();

                    if (templDtlRow.getAttribute("Attribute1") != null)
                        sSelect = 
                                templDtlRow.getAttribute("Attribute1").toString();


                    if (("Y".equals(sConcat)) || ("Y".equals(sSplit))) {
                        templDtlRow.setAttribute("Attribute1", "Y");                      
                        if(templDtlRow.getAttribute("Attribute4")!=null)                        
                           templDtlRow.setAttribute("Attribute20", templDtlRow.getAttribute("Attribute4"));                        
                    }

                    oracle.jbo.domain.Number nFieldId = null;
                    nFieldId = 
                            (oracle.jbo.domain.Number)templDtlRow.getAttribute("FieldId");
                    String sField = "" + nFieldId;

                    templDtlRow.setAttribute("ConcatFlag", Boolean.TRUE);
                    templDtlRow.setAttribute("SplitFlag", Boolean.TRUE);

                    if (!((Boolean)PPRRow.getAttribute("Complete"))) {

                        concatVO.reset();
                        while (concatVO.hasNext()) {
                            String sCode = null;
                            OARow concatVORow = (OARow)concatVO.next();
                            sCode = (String)concatVORow.getAttribute("Code");

                            if (sField.equals(sCode)) {
                                templDtlRow.setAttribute("ConcatFlag", 
                                                         Boolean.FALSE);
                                break;
                            }

                        }

                        splitVO.reset();
                        while (splitVO.hasNext()) {
                            String sCode = null;
                            OARow splitVORow = (OARow)splitVO.next();
                            sCode = (String)splitVORow.getAttribute("Code");

                            if (sField.equals(sCode)) {

                                templDtlRow.setAttribute("SplitFlag", 
                                                         Boolean.FALSE);
                                break;
                            }

                        }
                    } 

                }
            }
       
        }
    }
    //Code Added for Defect# NAIT-40588 by Rafi - END
	

    // To validate eBill main details and save.
    
     //Added by Rafi on 20-Mar-2018 for wave3 defect NAIT-33309 - START
  
  //  public void applyMain(String deliveryMethod) {
   public void applyMain(String deliveryMethod,String sRepeatTotalLabelDtl) {
  
   //Added by Rafi on 20-Mar-2018 for wave3 defect NAIT-33309 - END
        
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", "XXOD:validateMain", 1);
        validateMain();

        myAppsLog.write("ODEBillAMImpl", "XXOD:validateTransmission", 1);
        validateTransmission();


        myAppsLog.write("ODEBillAMImpl", "XXOD:validateContacts", 1);
        validateContacts();

        myAppsLog.write("ODEBillAMImpl", "XXOD:validateFileName", 1);
        validateFileName();


        if ("eXLS".equals(deliveryMethod) || "eTXT".equals(deliveryMethod)) {

            myAppsLog.write("ODEBillAMImpl", "XXOD:validateTemplHeader", 1);
            validateTemplHeader();

            myAppsLog.write("ODEBillAMImpl", "XXOD:validateTemplDtl", 1);
            validateTemplDtl();
        }
        if ("eXLS".equals(deliveryMethod)) {
            myAppsLog.write("ODEBillAMImpl", "XXOD:validateAggrDtl", 1);
            validateAggrDtl();
        }

        myAppsLog.write("ODEBillAMImpl", "XXOD:Before committing", 1);
  
        //Added by Rafi on 20-Mar-2018 for wave3 defect NAIT-33309 - START
        if(!"".equals(sRepeatTotalLabelDtl)){
          if("eXLS".equalsIgnoreCase(sRepeatTotalLabelDtl)){
             handleDtlRepeatTotalLabelPPR(sRepeatTotalLabelDtl);
          }
        }
        //Added by Rafi on 20-Mar-2018 for wave3 defect NAIT-33309 - END
        try {
            getTransaction().setClearCacheOnCommit(false);
            getOADBTransaction().commit();
        } catch (Exception e) {
            throw new OAException("Unexpected Exception:" + e.getMessage());
        }

    } //End applyMain()

    public String getSysDate() {
        String DATE_FORMAT_NOW = "yyyy-MM-dd";
        Calendar cal = Calendar.getInstance();
        SimpleDateFormat sdf = new SimpleDateFormat(DATE_FORMAT_NOW);
        return sdf.format(cal.getTime());
    } //End getSysDate()

    /* Method to delete unchecked fields from standard template when the status is changed to complete */

    public void deleteUncheckedStdFields() {
        ODUtil utl = new ODUtil(this);
        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
        utl.log("Inside ODEBillAMImpl: deleteUncheckedStdFields: Rowcount:" + 
                templDtlVO.getRowCount());
        OARow templDelRow = (OARow)templDtlVO.first();

        for (int i = templDtlVO.getRowCount(); i != 0; i--) {
            utl.log("Inside ODEBillAMImpl: deleteUncheckedStdFields: i: " + i);
            String check = (String)templDelRow.getAttribute("Attribute1");
            if (!"Y".equals(check))
                templDelRow.remove();
            templDelRow = (OARow)templDtlVO.next();
        }

    }

    public String validateFinal(String custDocId, String custAccountId) {

        String returnStatus;
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAM: validateFinal: custDocId: " + custDocId + 
                ":custAccountId:" + custAccountId);

		OracleCallableStatement oraclecallablestatement = null;
		OracleCallableStatement errCall = null;
		ResultSet errRS = null;
        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            /* Calling validate_final procedure to validate the eBilling details for the cust doc id
         * and change to status to complete if the validation is successful */
            String s = 
                " BEGIN " + " :1 :=  XX_CDH_EBL_VALIDATE_PKG.VALIDATE_FINAL( p_cust_doc_id              =>:2" + 
                "                                              , p_cust_account_id          =>:3" + 
                "                                              , p_change_status            =>'COMPLETE');" + 
                " END; ";

             oraclecallablestatement = 
                (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(s, 
                                                                                     -1);
            oraclecallablestatement.registerOutParameter(1, Types.VARCHAR);
            oraclecallablestatement.setNUMBER(2, new Number(custDocId));
            oraclecallablestatement.setNUMBER(3, new Number(custAccountId));

            oraclecallablestatement.execute();
            returnStatus = oraclecallablestatement.getString(1);
            oraclecallablestatement.close();
            utl.log("Inside ODEBillAM: validateFinal: returnStatus: " + 
                    returnStatus);
            /* If the validation is successful and status is changed to complete */
            if (returnStatus.equals("TRUE")) {
                return "Success";
            }
            /* If the validation fails display the error details to the user and return failed status */
            if (returnStatus.equals("FALSE")) {
                String errorCodes = 
                    "SELECT error_code FROM xx_cdh_ebl_error WHERE cust_doc_id = " + 
                    custDocId;
                errCall = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(errorCodes, 
                                                                                         -1);
                errRS = (OracleResultSet)errCall.executeQuery();
                ArrayList exceptions = new ArrayList();
                utl.log("Inside ODEBillAM: validateFinal: rowcount: " + 
                        errRS.getFetchSize());
                while (errRS.next()) {
                    String errorCode = errRS.getString("error_code");
                    exceptions.add(new OAException("XXCRM", errorCode));
                } // End of While
                errRS.close();
                errCall.close();
                OAException.raiseBundledOAException(exceptions);
                return "Failed";
            } // End of If
            return "Failed";
        } // End of Try

        catch (SQLException sqlexception) {
            throw OAException.wrapperException(sqlexception);
        } catch (Exception exception) {
            throw OAException.wrapperException(exception);
        }
		finally {
			try {
				if (oraclecallablestatement != null)
					oraclecallablestatement.close();
				if (errRS != null)
					errRS.close();
				if (errCall != null)
					errCall.close();				
			}
			catch(Exception exc) {  }
		}
    } // end of Validation method

    //Deleting existing error codes from xx_cdh_ebl_error table

    public void deleteErrorCodes(String custDocId) {
        ODUtil utl = new ODUtil(this);
        utl.log("Deleting error codes for cust doc id: " + custDocId);
		OracleCallableStatement delCallStmt = null;
        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            String deleteErrorCodes = 
                " DELETE FROM xx_cdh_ebl_error WHERE cust_doc_id = " + 
                custDocId;
            delCallStmt = 
                (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(deleteErrorCodes, 
                                                                                    1);
           //Updated by Bhagwan Rao 3March2017
         
             delCallStmt.executeUpdate();
           
            delCallStmt.close();
        } // End of Try
        catch (SQLException sqlexception) {
            throw OAException.wrapperException(sqlexception);
        } catch (Exception exception) {
            throw OAException.wrapperException(exception);
        }
		finally {
			try {
				if (delCallStmt != null)
					delCallStmt.close();
			}
			catch(Exception exc) {  }
        }
    }

    /**
     *
     * Container's getter for ODEBillTransmissionVO
     */
    public OAViewObjectImpl getODEBillTransmissionVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillTransmissionVO");
    }

    public void requery() {

        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillAMImpl: requery: ");

        //   OAViewObject mainVO = (OAViewObject) this.findViewObject("ODEBillMainVO");
        //   OAViewObject transVO = (OAViewObject) this.findViewObject("ODEBillTransmissionVO");
        //   OAViewObject contactVO = (OAViewObject) this.findViewObject("ODEBillContactsVO");
        //   OAViewObject fileParamVO = (OAViewObject) this.findViewObject("ODEBillFileNameVO");
        //    OAViewObject configHeadVO = (OAViewObject) this.findViewObject("ODEBillTempHeaderVO");
        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
        //   OAViewObject stdAggrDtlVO = (OAViewObject) this.findViewObject("ODEBillStdAggrDtlVO");

        //   mainVO.executeQuery();
        //    transVO.executeQuery();
        //   contactVO.executeQuery();
        //   fileParamVO.executeQuery();
        //   configHeadVO.executeQuery();
        templDtlVO.executeQuery();

        //   stdAggrDtlVO.executeQuery();

    }
    
    public String getFieldName(String fieldId) {

        ODUtil utl = new ODUtil(this);
		ResultSet rs = null;
		OracleCallableStatement call = null;
        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            String stmt = 
                "SELECT field_name  FROM xx_cdh_ebilling_fields_v WHERE field_id = " + 
                fieldId;
            call = 
                (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(stmt, 
                                                                                     -1);
            rs = (OracleResultSet)call.executeQuery();
            utl.log("Inside ODEBillAM: getFieldName: rowcount: " + 
                    rs.getFetchSize());
            String fieldName = null;
            if (rs.next())
                fieldName = rs.getString("field_name");
            rs.close();
            call.close();
            return fieldName;
        } catch (SQLException e) {
            getOADBTransaction().rollback();
            throw new OAException(e.toString(), OAException.ERROR);
        }
		finally {
			try {
				if (rs != null)
					rs.close();
				if (call != null)
					call.close();				
			}
			catch(Exception exc) {  }
		}	

    }

    /* Added for M)D 4B R3 */

    public String getConcFieldName(String fieldId) {

        ODUtil utl = new ODUtil(this);
        String fieldName = "EMPTY";

		ResultSet rs = null;
		OracleCallableStatement call = null;
        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            String stmt = 
                "SELECT conc_field_label  FROM xx_cdh_ebl_concat_fields WHERE conc_field_id = " + 
                fieldId;
            call = 
                (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(stmt, 
                                                                                     -1);
            rs = (OracleResultSet)call.executeQuery();
            utl.log("Inside ODEBillAM: getConcFieldName: rowcount: " + 
                    rs.getFetchSize());

            if (rs.next())
                fieldName = rs.getString("conc_field_label");
            rs.close();
            call.close();

        } catch (SQLException e) {
            ;
            //getOADBTransaction().rollback();
            //throw new OAException(e.toString(), OAException.ERROR);
        }
		finally {
			try {
				if (rs != null)
					rs.close();
				if (call != null)
					call.close();				
			}
			catch(Exception exc) {  }
		}	
        return fieldName;
    }


    public String getSplitFieldName(String fieldId) {

        ODUtil utl = new ODUtil(this);
        String fieldName = "EMPTY";

		ResultSet rs = null;
		OracleCallableStatement call = null;
        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            String stmt = 
                "select substr (split_field1_label||split_field2_label||split_field3_label||split_field4_label||split_field4_label||split_field6_label,1,20) split_field_label\n" + 
                " from XX_CDH_EBL_split_fields WHERE split_field_id = " + 
                fieldId;
            call = 
                (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(stmt, 
                                                                                     -1);
            rs = (OracleResultSet)call.executeQuery();
            utl.log("Inside ODEBillAM: getConcFieldName: rowcount: " + 
                    rs.getFetchSize());

            if (rs.next())
                fieldName = rs.getString("split_field_label");
            rs.close();
            call.close();

        } catch (SQLException e) {
            ;
            //getOADBTransaction().rollback();
            //throw new OAException(e.toString(), OAException.ERROR);
        }
		finally {
			try {
				if (rs != null)
					rs.close();
				if (call != null)
					call.close();				
			}
			catch(Exception exc) {  }
        }
        return fieldName;
    }
    /*End - Added for M)D 4B R3*/

    /**
     *
     * Container's getter for ODEBillAggrFieldPVO
     */
    public OAViewObjectImpl getODEBillAggrFieldPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillAggrFieldPVO");
    }

    /* This method deletes the exisiting error codes for the cust_doc_id, calls the XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_MAIN
   * to valdiate the eBill main details and raise exception if any validation fails */

    protected void validateMain() {

        OADBTransactionImpl oadbtransactionimpl = 
            (OADBTransactionImpl)getDBTransaction();
        ODUtil utl = new ODUtil(oadbtransactionimpl);
        utl.log("Inside validateMain");

        String returnStatus;
        String custDocId = null;

		OracleCallableStatement deleteErrorCall = null;
		OracleCallableStatement ocs = null;
		OracleCallableStatement ops = null;
		ResultSet ors = null;
        try {
            OAViewObject mainVO = 
                (OAViewObject)this.findViewObject("ODEBillMainVO");
            OARow mainRow = (OARow)mainVO.first();

            if (mainRow != null) {
                utl.log("Inside validateMain: CustDocId :" + 
                        mainRow.getAttribute("CustDocId"));
                if (mainRow.getAttribute("CustDocId") != null)
                    custDocId = mainRow.getAttribute("CustDocId").toString();
            }

            //utl.log("Inside deleteErrorCodes: Deleting exisiting error codes");
            //deleteing errorcodes if any
            String deleteErrorCodes = 
                "delete xx_cdh_ebl_error where cust_doc_id = " + 
                mainRow.getAttribute("CustDocId");
            deleteErrorCall = 
                (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(deleteErrorCodes, 
                                                                                     -1);
            deleteErrorCall.execute();
            deleteErrorCall.close();
            Date fileSeqResetDate = null;
            if (mainRow.getAttribute("FileSeqResetDate") != null)
                fileSeqResetDate = 
                        (Date)mainRow.getAttribute("FileSeqResetDate");

            // utl.log("Inside deleteErrorCodes: calling XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_MAIN");
            //calling XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_MAIN procedure to validate eBill main details
            String s = 
                " BEGIN " + "   :1 :=  XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_MAIN( p_cust_doc_id         => :2  " + 
                "                                            ,  p_cust_account_id           => :3  " + 
                "                                            ,  p_ebill_transmission_type   => :4  " + 
                "                                            ,  p_ebill_associate           => :5  " + 
                "                                            ,  p_file_processing_method    => :6  " + 
                "                                            ,  p_file_name_ext             => :7  " + 
                "                                            ,  p_max_file_size             => :8  " + 
                "                                            ,  p_max_transmission_size     => :9  " + 
                "                                            ,  p_zip_required              => :10 " + 
                "                                            ,  p_zipping_utility           => :11 " + 
                "                                            ,  p_zip_file_name_ext         => :12 " + 
                "                                            ,  p_od_field_contact          => :13 " + 
                "                                            ,  p_od_field_contact_email    => :14 " + 
                "                                            ,  p_od_field_contact_phone    => :15 " + 
                "                                            ,  p_client_tech_contact       => :16 " + 
                "                                            ,  p_client_tech_contact_email => :17 " + 
                "                                            ,  p_client_tech_contact_phone => :18 " + 
                "                                            ,  p_file_name_seq_reset       => :19 " + 
                "                                            ,  p_file_next_seq_number      => :20 " + 
                "                                            ,  p_file_seq_reset_date       => :21 " + 
                "                                            ,  p_file_name_max_seq_number  => :22 " + 
                "                                            ,  p_attribute1                => :23 " + 
                "                                            ,  p_attribute2                => :24 " + 
                "                                            ,  p_attribute3                => :25 " + 
                "                                            ,  p_attribute4                => :26 " + 
                "                                            ,  p_attribute5                => :27 " + 
                "                                            ,  p_attribute6                => :28 " + 
                "                                            ,  p_attribute7                => :29 " + 
                "                                            ,  p_attribute8                => :30 " + 
                "                                            ,  p_attribute9                => :31 " + 
                "                                            ,  p_attribute10               => :32 " + 
                "                                            ,  p_attribute11               => :33 " + 
                "                                            ,  p_attribute12               => :34 " + 
                "                                            ,  p_attribute13               => :35 " + 
                "                                            ,  p_attribute14               => :36 " + 
                "                                            ,  p_attribute15               => :37 " + 
                "                                            ,  p_attribute16               => :38 " + 
                "                                            ,  p_attribute17               => :39 " + 
                "                                            ,  p_attribute18               => :40 " + 
                "                                            ,  p_attribute19               => :41 " + 
                "                                            ,  p_attribute20               => :42);" + 
                " END; ";

            ocs = 
                (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(s, 
                                                                                     -1);
            ocs.registerOutParameter(1, Types.VARCHAR);
            ocs.setNUMBER(2, (Number)mainRow.getAttribute("CustDocId"));
            ocs.setNUMBER(3, (Number)mainRow.getAttribute("CustAccountId"));
            ocs.setString(4, 
                          (String)mainRow.getAttribute("EbillTransmissionType"));
            ocs.setString(5, (String)mainRow.getAttribute("EbillAssociate"));
            ocs.setString(6, 
                          (String)mainRow.getAttribute("FileProcessingMethod"));
            ocs.setString(7, (String)mainRow.getAttribute("FileNameExt"));
            ocs.setNUMBER(8, (Number)mainRow.getAttribute("MaxFileSize"));
            ocs.setNUMBER(9, 
                          (Number)mainRow.getAttribute("MaxTransmissionSize"));
            ocs.setString(10, (String)mainRow.getAttribute("ZipRequired"));
            ocs.setString(11, (String)mainRow.getAttribute("ZippingUtility"));
            ocs.setString(12, (String)mainRow.getAttribute("ZipFileNameExt"));
            ocs.setString(13, (String)mainRow.getAttribute("OdFieldContact"));
            ocs.setString(14, 
                          (String)mainRow.getAttribute("OdFieldContactEmail"));
            ocs.setString(15, 
                          (String)mainRow.getAttribute("OdFieldContactPhone"));
            ocs.setString(16, 
                          (String)mainRow.getAttribute("ClientTechContact"));
            ocs.setString(17, 
                          (String)mainRow.getAttribute("ClientTechContactEmail"));
            ocs.setString(18, 
                          (String)mainRow.getAttribute("ClientTechContactPhone"));
            ocs.setString(19, 
                          (String)mainRow.getAttribute("FileNameSeqReset"));
            ocs.setNUMBER(20, 
                          (Number)mainRow.getAttribute("FileNextSeqNumber"));
            ocs.setDATE(21, fileSeqResetDate);
            ocs.setNUMBER(22, 
                          (Number)mainRow.getAttribute("FileNameMaxSeqNumber"));
            ocs.setString(23, (String)mainRow.getAttribute("Attribute1"));
            ocs.setString(24, (String)mainRow.getAttribute("Attribute2"));
            ocs.setString(25, (String)mainRow.getAttribute("Attribute3"));
            ocs.setString(26, (String)mainRow.getAttribute("Attribute4"));
            ocs.setString(27, (String)mainRow.getAttribute("Attribute5"));
            ocs.setString(28, (String)mainRow.getAttribute("Attribute6"));
            ocs.setString(29, (String)mainRow.getAttribute("Attribute7"));
            ocs.setString(30, (String)mainRow.getAttribute("Attribute8"));
            ocs.setString(31, (String)mainRow.getAttribute("Attribute9"));
            ocs.setString(32, (String)mainRow.getAttribute("Attribute10"));
            ocs.setString(33, (String)mainRow.getAttribute("Attribute11"));
            ocs.setString(34, (String)mainRow.getAttribute("Attribute12"));
            ocs.setString(35, (String)mainRow.getAttribute("Attribute13"));
            ocs.setString(36, (String)mainRow.getAttribute("Attribute14"));
            ocs.setString(37, (String)mainRow.getAttribute("Attribute15"));
            ocs.setString(38, (String)mainRow.getAttribute("Attribute16"));
            ocs.setString(39, (String)mainRow.getAttribute("Attribute17"));
            ocs.setString(40, (String)mainRow.getAttribute("Attribute18"));
            ocs.setString(41, (String)mainRow.getAttribute("Attribute19"));
            ocs.setString(42, (String)mainRow.getAttribute("Attribute20"));
            ocs.execute();
            returnStatus = ocs.getString(1);
            ocs.close();
            if (returnStatus.equals("FALSE")) {
                //Fetching the error codes
                String errorCodes = 
                    "SELECT error_code FROM xx_cdh_ebl_error WHERE cust_doc_id = " + 
                    custDocId;

                ops = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(errorCodes, 
                                                                                         1);
                ors = (ResultSet)ops.executeQuery();
                ArrayList exceptions = new ArrayList();
                while (ors.next()) {
                    String errorCode = ors.getString("error_code");
                    exceptions.add(new OAException("XXCRM", errorCode));
                }
                ors.close();
                ops.close();
                OAException.raiseBundledOAException(exceptions);
            }
        } catch (SQLException sqlexception) {
            throw OAException.wrapperException(sqlexception);
        } catch (Exception exception) {
            throw OAException.wrapperException(exception);
        }
		finally {
			try {
				if (deleteErrorCall != null)
					deleteErrorCall.close();
				if (ocs != null)
					ocs.close();
				if (ors != null)
					ors.close();
				if (ops != null)
					ops.close();				
			}
			catch(Exception exc) {  }
		}

    } // End validateMain()


    /*  This method call the xx_cdh_ebl_validate_pkg.validate_ebl_transmission PL/SQL procedure
   *  to validate transmission details */

    protected void validateTransmission() {
        String returnStatus;
        String custDocId = null;
		OracleCallableStatement ocs = null;
		OracleCallableStatement errCall = null;
		ResultSet errRS = null;
        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            ODUtil utl = new ODUtil(oadbtransactionimpl);

            utl.log("Inside validateTransmission");

            OAViewObject mainVO = 
                (OAViewObject)this.findViewObject("ODEBillMainVO");
            OARow mainRow = (OARow)mainVO.first();

            OAViewObject transmissionVO = 
                (OAViewObject)this.findViewObject("ODEBillTransmissionVO");
            OARow transRow = (OARow)transmissionVO.first();

            if (transRow != null)
                custDocId = transRow.getAttribute("CustDocId").toString();

            String s = 
                "BEGIN" + "   :1 :=  XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_TRANSMISSION(p_cust_doc_id  => " + 
                transRow.getAttribute("CustDocId") + 
                " ,p_transmission_type                  =>:2" + 
                " ,p_email_subject                      =>:3" + 
                " ,p_email_std_message                  =>:4" + 
                " ,p_email_custom_message               =>:5" + 
                " ,p_email_std_disclaimer               =>:6" + 
                " ,p_email_signature                    =>:7" + 
                " ,p_email_logo_required                =>:8" + 
                " ,p_email_logo_file_name               =>:9" + 
                " ,p_ftp_direction                      =>:10" + 
                " ,p_ftp_transfer_type                  =>:11" + 
                " ,p_ftp_destination_site               =>:12" + 
                " ,p_ftp_destination_folder             =>:13" + 
                " ,p_ftp_user_name                      =>:14" + 
                " ,p_ftp_password                       =>:15" + 
                " ,p_ftp_pickup_server                  =>:16" + 
                " ,p_ftp_pickup_folder                  =>:17" + 
                " ,p_ftp_cust_contact_name              =>:18" + 
                " ,p_ftp_cust_contact_email             =>:19" + 
                " ,p_ftp_cust_contact_phone             =>:20" + 
                " ,p_ftp_notify_customer                =>:21" + 
                " ,p_ftp_cc_emails                      =>:22" + 
                " ,p_ftp_email_sub                      =>:23" + 
                " ,p_ftp_email_content                  =>:24" + 
                " ,p_ftp_send_zero_byte_file            =>:25" + 
                " ,p_ftp_zero_byte_file_text            =>:26" + 
                " ,p_ftp_zero_byte_notif_txt            =>:27" + 
                " ,p_cd_file_location                   =>:28" + 
                " ,p_cd_send_to_address                 =>:29" + 
                " ,p_comments                           =>:30" + 
                " ,p_attribute1                         =>:31" + 
                " ,p_attribute2                         =>:32" + 
                " ,p_attribute3                         =>:33" + 
                " ,p_attribute4                         =>:34" + 
                " ,p_attribute5                         =>:35" + 
                " ,p_attribute6                         =>:36" + 
                " ,p_attribute7                         =>:37" + 
                " ,p_attribute8                         =>:38" + 
                " ,p_attribute9                         =>:39" + 
                " ,p_attribute10                        =>:40" + 
                " ,p_attribute11                        =>:41" + 
                " ,p_attribute12                        =>:42" + 
                " ,p_attribute13                        =>:43" + 
                " ,p_attribute14                        =>:44" + 
                " ,p_attribute15                        =>:45" + 
                " ,p_attribute16                        =>:46" + 
                " ,p_attribute17                        =>:47" + 
                " ,p_attribute18                        =>:48" + 
                " ,p_attribute19                        =>:49" + 
                " ,p_attribute20                        =>:50);" + " END;";

            ocs = 
                (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(s, 
                                                                                     -1);
            ocs.registerOutParameter(1, Types.VARCHAR);
            ocs.setString(2, 
                          (String)mainRow.getAttribute("EbillTransmissionType"));
            ocs.setString(3, (String)transRow.getAttribute("EmailSubject"));
            ocs.setString(4, (String)transRow.getAttribute("EmailStdMessage"));
            ocs.setString(5, 
                          (String)transRow.getAttribute("EmailCustomMessage"));
            ocs.setString(6, 
                          (String)transRow.getAttribute("EmailStdDisclaimer"));
            ocs.setString(7, (String)transRow.getAttribute("EmailSignature"));
            ocs.setString(8, 
                          (String)transRow.getAttribute("EmailLogoRequired"));
            ocs.setString(9, 
                          (String)transRow.getAttribute("EmailLogoFileName"));
            ocs.setString(10, (String)transRow.getAttribute("FtpDirection"));
            ocs.setString(11, 
                          (String)transRow.getAttribute("FtpTransferType"));
            ocs.setString(12, 
                          (String)transRow.getAttribute("FtpDestinationSite"));
            ocs.setString(13, 
                          (String)transRow.getAttribute("FtpDestinationFolder"));
            ocs.setString(14, (String)transRow.getAttribute("FtpUserName"));
            ocs.setString(15, (String)transRow.getAttribute("FtpPassword"));
            ocs.setString(16, 
                          (String)transRow.getAttribute("FtpPickupServer"));
            ocs.setString(17, 
                          (String)transRow.getAttribute("FtpPickupFolder"));
            ocs.setString(18, 
                          (String)transRow.getAttribute("FtpCustContactName"));
            ocs.setString(19, 
                          (String)transRow.getAttribute("FtpCustContactEmail"));
            ocs.setString(20, 
                          (String)transRow.getAttribute("FtpCustContactPhone"));
            ocs.setString(21, 
                          (String)transRow.getAttribute("FtpNotifyCustomer"));
            ocs.setString(22, (String)transRow.getAttribute("FtpCcEmails"));
            ocs.setString(23, (String)transRow.getAttribute("FtpEmailSub"));
            ocs.setString(24, 
                          (String)transRow.getAttribute("FtpEmailContent"));
            ocs.setString(25, 
                          (String)transRow.getAttribute("FtpSendZeroByteFile"));
            ocs.setString(26, 
                          (String)transRow.getAttribute("FtpZeroByteFileText"));
            ocs.setString(27, 
                          (String)transRow.getAttribute("FtpZeroByteNotificationTxt"));
            ocs.setString(28, (String)transRow.getAttribute("CdFileLocation"));
            ocs.setString(29, 
                          (String)transRow.getAttribute("CdSendToAddress"));
            ocs.setString(30, (String)transRow.getAttribute("Comments"));
            ocs.setString(31, (String)transRow.getAttribute("Attribute1"));
            ocs.setString(32, (String)transRow.getAttribute("Attribute2"));
            ocs.setString(33, (String)transRow.getAttribute("Attribute3"));
            ocs.setString(34, (String)transRow.getAttribute("Attribute4"));
            ocs.setString(35, (String)transRow.getAttribute("Attribute5"));
            ocs.setString(36, (String)transRow.getAttribute("Attribute6"));
            ocs.setString(37, (String)transRow.getAttribute("Attribute7"));
            ocs.setString(38, (String)transRow.getAttribute("Attribute8"));
            ocs.setString(39, (String)transRow.getAttribute("Attribute9"));
            ocs.setString(40, (String)transRow.getAttribute("Attribute10"));
            ocs.setString(41, (String)transRow.getAttribute("Attribute11"));
            ocs.setString(42, (String)transRow.getAttribute("Attribute12"));
            ocs.setString(43, (String)transRow.getAttribute("Attribute13"));
            ocs.setString(44, (String)transRow.getAttribute("Attribute14"));
            ocs.setString(45, (String)transRow.getAttribute("Attribute15"));
            ocs.setString(46, (String)transRow.getAttribute("Attribute16"));
            ocs.setString(47, (String)transRow.getAttribute("Attribute17"));
            ocs.setString(48, (String)transRow.getAttribute("Attribute18"));
            ocs.setString(49, (String)transRow.getAttribute("Attribute19"));
            ocs.setString(50, (String)transRow.getAttribute("Attribute20"));
            ocs.execute();
            returnStatus = ocs.getString(1);
            ocs.close();
            //  transRow = (OARow) transmissionVO.next();
            //    utl.log("Inside Validate TransmissionEO Entity: resultStatus: " + returnStatus );
            if (returnStatus.equals("FALSE")) {

                String errorCodes = 
                    "SELECT error_code FROM xx_cdh_ebl_error WHERE cust_doc_id = " + 
                    custDocId;
                errCall = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(errorCodes, 
                                                                                         -1);
                errRS = (OracleResultSet)errCall.executeQuery();


                ArrayList exceptions = new ArrayList();

                while (errRS.next()) {
                    String errorCode = errRS.getString("error_code");
                    exceptions.add(new OAException("XXCRM", 
                                                   errorCode)); // Message name

                }
                errRS.close();
                errCall.close();
                utl.log("End of validateTransmission");
                OAException.raiseBundledOAException(exceptions);
            } //if (returnStatus.equals("FALSE"))
        } catch (SQLException sqlexception) {
            throw OAException.wrapperException(sqlexception);
        } catch (Exception exception) {
            throw OAException.wrapperException(exception);
        }
		finally {
			try {
				if (ocs != null)
					ocs.close();
				if (errRS != null)
					errRS.close();
				if (errCall != null)
					errCall.close();				
			}
			catch(Exception exc) {  }
		}

    } // End validateTransmission()

    /*  This method call the xx_cdh_ebl_validate_pkg.validate_ebl_contacts PL/SQL procedure
   *  to validate contacts */

    protected void validateContacts() {
        String returnStatus;
        String returnFlag = "TRUE";
        String custDocId = null;
		OracleCallableStatement oraclecallablestatement = null;
		OracleCallableStatement errCall = null;
		ResultSet errRS = null;	

        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            ODUtil utl = new ODUtil(oadbtransactionimpl);

            utl.log("Inside validateContacts");

            OAViewObject custVO = 
                (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
            OARow custRow = (OARow)custVO.first();

            OAViewObject mainVO = 
                (OAViewObject)this.findViewObject("ODEBillMainVO");
            OARow mainRow = (OARow)mainVO.first();

            OAViewObject contactsVO = 
                (OAViewObject)this.findViewObject("ODEBillContactsVO");
            OARow contactsRow = (OARow)contactsVO.first();

            if (contactsRow != null)
                custDocId = contactsRow.getAttribute("CustDocId").toString();

            ArrayList exceptions = new ArrayList();

            for (int i = 0; i < contactsVO.getRowCount(); i++) {
                String s = 
                    " BEGIN " + "   :1 :=  XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_CONTACTS(p_cust_account_id    => :2" + 
                    "                                              ,  p_transmission_type         => :3 " + 
                    "                                              ,  p_paydoc_ind                => :4 " + 
                    "                                              ,  p_ebl_doc_contact_id        => :5 " + 
                    "                                              ,  p_cust_doc_id               => :6 " + 
                    "                                              ,  p_org_contact_id            => :7 " + 
                    "                                              ,  p_cust_acct_site_id         => :8 " + 
                    "                                              ,  p_attribute1                => :9 " + 
                    "                                              ,  p_attribute2                => :10 " + 
                    "                                              ,  p_attribute3                => :11 " + 
                    "                                              ,  p_attribute4                => :12 " + 
                    "                                              ,  p_attribute5                => :13 " + 
                    "                                              ,  p_attribute6                => :14 " + 
                    "                                              ,  p_attribute7                => :15 " + 
                    "                                              ,  p_attribute8                => :16 " + 
                    "                                              ,  p_attribute9                => :17 " + 
                    "                                              ,  p_attribute10               => :18 " + 
                    "                                              ,  p_attribute11               => :19 " + 
                    "                                              ,  p_attribute12               => :20 " + 
                    "                                              ,  p_attribute13               => :21 " + 
                    "                                              ,  p_attribute14               => :22 " + 
                    "                                              ,  p_attribute15               => :23 " + 
                    "                                              ,  p_attribute16               => :24 " + 
                    "                                              ,  p_attribute17               => :25 " + 
                    "                                              ,  p_attribute18               => :26 " + 
                    "                                              ,  p_attribute19               => :27 " + 
                    "                                              ,  p_attribute20               => :28);" + 
                    " END; ";

                oraclecallablestatement = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(s, 
                                                                                         -1);
                oraclecallablestatement.registerOutParameter(1, Types.VARCHAR);

                utl.log("Inside ValidateContact: CustAcctSiteId: " + 
                        contactsRow.getAttribute("CustAcctSiteId"));

                oraclecallablestatement.setNUMBER(2, 
                                                  (Number)mainRow.getAttribute("CustAccountId"));
                oraclecallablestatement.setString(3, 
                                                  (String)mainRow.getAttribute("EbillTransmissionType"));
                oraclecallablestatement.setString(4, 
                                                  (String)custRow.getAttribute("PayDocInd"));
                oraclecallablestatement.setNUMBER(5, 
                                                  (Number)contactsRow.getAttribute("EblDocContactId"));
                oraclecallablestatement.setNUMBER(6, 
                                                  (Number)contactsRow.getAttribute("CustDocId"));
                oraclecallablestatement.setNUMBER(7, 
                                                  (Number)contactsRow.getAttribute("OrgContactId"));
                oraclecallablestatement.setNUMBER(8, 
                                                  (Number)contactsRow.getAttribute("CustAcctSiteId"));
                oraclecallablestatement.setString(9, 
                                                  (String)contactsRow.getAttribute("Attribute1"));
                oraclecallablestatement.setString(10, 
                                                  (String)contactsRow.getAttribute("Attribute2"));
                oraclecallablestatement.setString(11, 
                                                  (String)contactsRow.getAttribute("Attribute3"));
                oraclecallablestatement.setString(12, 
                                                  (String)contactsRow.getAttribute("Attribute4"));
                oraclecallablestatement.setString(13, 
                                                  (String)contactsRow.getAttribute("Attribute5"));
                oraclecallablestatement.setString(14, 
                                                  (String)contactsRow.getAttribute("Attribute6"));
                oraclecallablestatement.setString(15, 
                                                  (String)contactsRow.getAttribute("Attribute7"));
                oraclecallablestatement.setString(16, 
                                                  (String)contactsRow.getAttribute("Attribute8"));
                oraclecallablestatement.setString(17, 
                                                  (String)contactsRow.getAttribute("Attribute9"));
                oraclecallablestatement.setString(18, 
                                                  (String)contactsRow.getAttribute("Attribute10"));
                oraclecallablestatement.setString(19, 
                                                  (String)contactsRow.getAttribute("Attribute11"));
                oraclecallablestatement.setString(20, 
                                                  (String)contactsRow.getAttribute("Attribute12"));
                oraclecallablestatement.setString(21, 
                                                  (String)contactsRow.getAttribute("Attribute13"));
                oraclecallablestatement.setString(22, 
                                                  (String)contactsRow.getAttribute("Attribute14"));
                oraclecallablestatement.setString(23, 
                                                  (String)contactsRow.getAttribute("Attribute15"));
                oraclecallablestatement.setString(24, 
                                                  (String)contactsRow.getAttribute("Attribute16"));
                oraclecallablestatement.setString(25, 
                                                  (String)contactsRow.getAttribute("Attribute17"));
                oraclecallablestatement.setString(26, 
                                                  (String)contactsRow.getAttribute("Attribute18"));
                oraclecallablestatement.setString(27, 
                                                  (String)contactsRow.getAttribute("Attribute19"));
                oraclecallablestatement.setString(28, 
                                                  (String)contactsRow.getAttribute("Attribute20"));
                oraclecallablestatement.execute();
                returnStatus = oraclecallablestatement.getString(1);
                oraclecallablestatement.close();
                if (returnStatus.equals("FALSE"))
                    returnFlag = "FALSE";
                contactsRow = (OARow)contactsVO.next();

            } //End for

            utl.log("Inside ValidateContact: returnFlag: " + returnFlag);
            if (returnFlag.equals("FALSE")) {
                String errorCodes = 
                    "SELECT error_code FROM xx_cdh_ebl_error WHERE cust_doc_id = " + 
                    custDocId;
                errCall = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(errorCodes, 
                                                                                         -1);
                errRS = (OracleResultSet)errCall.executeQuery();

                while (errRS.next()) {
                    String errorCode = errRS.getString("error_code");
                    exceptions.add(new OAException("XXCRM", errorCode));
                } //End while(errRS.next())
                errRS.close();
                errCall.close();
            } //End if (returnStatus.equals("FALSE"))

            utl.log("Inside validateContacts, before raiseBundledOAException");

            OAException.raiseBundledOAException(exceptions);

        } catch (SQLException sqlexception) {
            throw OAException.wrapperException(sqlexception);
        } catch (Exception exception) {
            throw OAException.wrapperException(exception);
        }
		finally {
			try {
				if (oraclecallablestatement != null)
					oraclecallablestatement.close();
				if (errRS != null)
					errRS.close();
				if (errCall != null)
					errCall.close();				
			}
			catch(Exception exc) {  }
		}
    } // end of validateContacts()


    /*  This method call the xx_cdh_ebl_validate_pkg.validate_ebl_file_name PL/SQL procedure
   *  to validate file name */

    protected void validateFileName() {
        String returnStatus = "TRUE";
        String returnFlag = "TRUE";
        String custDocId = null;
		OracleCallableStatement oraclecallablestatement = null;
		OracleCallableStatement errCall = null;
		ResultSet errRS = null;
        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            ODUtil utl = new ODUtil(oadbtransactionimpl);

            OAViewObject mainVO = 
                (OAViewObject)this.findViewObject("ODEBillMainVO");
            OARow mainRow = (OARow)mainVO.first();

            OAViewObject fileNameVO = 
                (OAViewObject)this.findViewObject("ODEBillFileNameVO");
            OARow fileNameRow = (OARow)fileNameVO.first();

            if (fileNameRow != null)
                custDocId = fileNameRow.getAttribute("CustDocId").toString();

            ArrayList exceptions = new ArrayList();
            for (int i = 0; i < fileNameVO.getRowCount(); i++) {

                Date fileSeqResetDate = null;
                if (mainRow.getAttribute("FileSeqResetDate") != null)
                    fileSeqResetDate = 
                            (Date)mainRow.getAttribute("FileSeqResetDate");

                String s = 
                    " BEGIN " + "   :1 :=  XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_FILE_NAME( p_ebl_file_name_id => :2" + 
                    "                                            ,  p_cust_doc_id               => :3 " + 
                    "                                            ,  p_file_name_order_seq       => :4" + 
                    "                                            ,  p_field_id                  => :5" + 
                    "                                            ,  p_constant_value            => :6" + 
                    "                                            ,  p_default_if_null           => :7" + 
                    "                                            ,  p_comments                  => :8" + 
                    "                                            ,  p_file_name_seq_reset       => :9" + 
                    "                                            ,  p_file_next_seq_number      => :10" + 
                    "                                            ,  p_file_seq_reset_date       => :11" + 
                    "                                            ,  p_file_name_max_seq_number  => :12" + 
                    "                                            ,  p_attribute1                => :13" + 
                    "                                            ,  p_attribute2                => :14" + 
                    "                                            ,  p_attribute3                => :15" + 
                    "                                            ,  p_attribute4                => :16" + 
                    "                                            ,  p_attribute5                => :17 " + 
                    "                                            ,  p_attribute6                => :18 " + 
                    "                                            ,  p_attribute7                => :19 " + 
                    "                                            ,  p_attribute8                => :20 " + 
                    "                                            ,  p_attribute9                => :21 " + 
                    "                                            ,  p_attribute10               => :22 " + 
                    "                                            ,  p_attribute11               => :23 " + 
                    "                                            ,  p_attribute12               => :24 " + 
                    "                                            ,  p_attribute13               => :25 " + 
                    "                                            ,  p_attribute14               => :26 " + 
                    "                                            ,  p_attribute15               => :27 " + 
                    "                                            ,  p_attribute16               => :28 " + 
                    "                                            ,  p_attribute17               => :29 " + 
                    "                                            ,  p_attribute18               => :30 " + 
                    "                                            ,  p_attribute19               => :31 " + 
                    "                                            ,  p_attribute20               => :32);" + 
                    " END; ";

                oraclecallablestatement = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(s, 
                                                                                         -1);
                oraclecallablestatement.registerOutParameter(1, Types.VARCHAR);
                oraclecallablestatement.setNUMBER(2, 
                                                  (Number)fileNameRow.getAttribute("EblFileNameId"));
                oraclecallablestatement.setNUMBER(3, 
                                                  (Number)fileNameRow.getAttribute("CustDocId"));
                oraclecallablestatement.setNUMBER(4, 
                                                  (Number)fileNameRow.getAttribute("FileNameOrderSeq"));
                oraclecallablestatement.setNUMBER(5, 
                                                  (Number)fileNameRow.getAttribute("FieldId"));
                oraclecallablestatement.setString(6, 
                                                  (String)fileNameRow.getAttribute("ConstantValue"));
                oraclecallablestatement.setString(7, 
                                                  (String)fileNameRow.getAttribute("DefaultIfNull"));
                oraclecallablestatement.setString(8, 
                                                  (String)fileNameRow.getAttribute("Comments"));
                oraclecallablestatement.setString(9, 
                                                  (String)mainRow.getAttribute("FileNameSeqReset"));
                oraclecallablestatement.setNUMBER(10, 
                                                  (Number)mainRow.getAttribute("FileNextSeqNumber"));
                oraclecallablestatement.setDATE(11, fileSeqResetDate);
                oraclecallablestatement.setNUMBER(12, 
                                                  (Number)mainRow.getAttribute("FileNameMaxSeqNumber"));
                oraclecallablestatement.setString(13, 
                                                  (String)fileNameRow.getAttribute("Attribute1"));
                oraclecallablestatement.setString(14, 
                                                  (String)fileNameRow.getAttribute("Attribute2"));
                oraclecallablestatement.setString(15, 
                                                  (String)fileNameRow.getAttribute("Attribute3"));
                oraclecallablestatement.setString(16, 
                                                  (String)fileNameRow.getAttribute("Attribute4"));
                oraclecallablestatement.setString(17, 
                                                  (String)fileNameRow.getAttribute("Attribute5"));
                oraclecallablestatement.setString(18, 
                                                  (String)fileNameRow.getAttribute("Attribute6"));
                oraclecallablestatement.setString(19, 
                                                  (String)fileNameRow.getAttribute("Attribute7"));
                oraclecallablestatement.setString(20, 
                                                  (String)fileNameRow.getAttribute("Attribute8"));
                oraclecallablestatement.setString(21, 
                                                  (String)fileNameRow.getAttribute("Attribute9"));
                oraclecallablestatement.setString(22, 
                                                  (String)fileNameRow.getAttribute("Attribute10"));
                oraclecallablestatement.setString(23, 
                                                  (String)fileNameRow.getAttribute("Attribute11"));
                oraclecallablestatement.setString(24, 
                                                  (String)fileNameRow.getAttribute("Attribute12"));
                oraclecallablestatement.setString(25, 
                                                  (String)fileNameRow.getAttribute("Attribute13"));
                oraclecallablestatement.setString(26, 
                                                  (String)fileNameRow.getAttribute("Attribute14"));
                oraclecallablestatement.setString(27, 
                                                  (String)fileNameRow.getAttribute("Attribute15"));
                oraclecallablestatement.setString(28, 
                                                  (String)fileNameRow.getAttribute("Attribute16"));
                oraclecallablestatement.setString(29, 
                                                  (String)fileNameRow.getAttribute("Attribute17"));
                oraclecallablestatement.setString(30, 
                                                  (String)fileNameRow.getAttribute("Attribute18"));
                oraclecallablestatement.setString(31, 
                                                  (String)fileNameRow.getAttribute("Attribute19"));
                oraclecallablestatement.setString(32, 
                                                  (String)fileNameRow.getAttribute("Attribute20"));
                oraclecallablestatement.execute();
                returnStatus = oraclecallablestatement.getString(1);
                oraclecallablestatement.close();
                if (returnStatus.equals("FALSE"))
                    returnFlag = "FALSE";
                fileNameRow = (OARow)fileNameVO.next();
            } //End For

            utl.log("Inside validateFileName Entity: returnFlag: " + 
                    returnFlag);
            if (returnFlag.equals("FALSE")) {
                String errorCodes = 
                    "SELECT error_code FROM xx_cdh_ebl_error WHERE cust_doc_id = " + 
                    custDocId;
                errCall = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(errorCodes, 
                                                                                         -1);
                errRS = (OracleResultSet)errCall.executeQuery();

                while (errRS.next()) {
                    utl.log("Inside validateFileName Entity: inside while: ");
                    String errorCode = errRS.getString("error_code");
                    utl.log("Inside validateFileName Entity: errorCode: " + 
                            errorCode);

                    exceptions.add(new OAException("XXCRM", errorCode));
                }

                errRS.close();
                errCall.close();

            }
            OAException.raiseBundledOAException(exceptions);

        } catch (SQLException sqlexception) {
            throw OAException.wrapperException(sqlexception);
        } catch (Exception exception) {
            throw OAException.wrapperException(exception);
        }
		finally {
			try {
				if (oraclecallablestatement != null)
					oraclecallablestatement.close();
				if (errRS != null)
					errRS.close();
				if (errCall != null)
					errCall.close();				
			}
			catch(Exception exc) {  }
		}	

    } //End of validate file name


    /*  This method calls the xx_cdh_ebl_validate_pkg.validate_ebl_templ_header PL/SQL procedure
   *  to validate template header detail */

    protected void validateTemplHeader() {
        String returnStatus = "TRUE";
        String returnFlag = "TRUE";
        String custDocId = null;
		OracleCallableStatement oraclecallablestatement = null;
		OracleCallableStatement errCall = null;
		ResultSet errRS = null;	
        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            ODUtil utl = new ODUtil(oadbtransactionimpl);
            utl.log("Inside validateTemplHeader");

            OAViewObject custHeadVO = 
                (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
            OARow custHeadRow = (OARow)custHeadVO.first();

            OAViewObject tempHeaderVO = 
                (OAViewObject)this.findViewObject("ODEBillTempHeaderVO");
            OARow tempHeaderRow = (OARow)tempHeaderVO.first();

            if (tempHeaderRow != null)
                custDocId = tempHeaderRow.getAttribute("CustDocId").toString();

            ArrayList exceptions = new ArrayList();
            for (int i = 0; i < tempHeaderVO.getRowCount(); i++) {
                String s = 
                    " BEGIN " + "   :1 :=  XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_TEMPL_HEADER(p_cust_account_id => :2 " + 
                    "                                            ,  p_cust_doc_id                  => :3 " + 
                    "                                            ,  p_ebill_file_creation_type     => :4 " + 
                    "                                            ,  p_delimiter_char               => :5 " + 
                    "                                            ,  p_line_feed_style              => :6 " + 
                    "                                            ,  p_include_header               => :7 " + 
                    "                                            ,  p_logo_file_name               => :8 " + 
                    "                                            ,  p_file_split_criteria          => :9 " + 
                    "                                            ,  p_file_split_value             => :10" + 
                    "                                            ,  p_attribute1                   => :11" + 
                    "                                            ,  p_attribute2                   => :12 " + 
                    "                                            ,  p_attribute3                   => :13 " + 
                    "                                            ,  p_attribute4                   => :14 " + 
                    "                                            ,  p_attribute5                   => :15 " + 
                    "                                            ,  p_attribute6                   => :16 " + 
                    "                                            ,  p_attribute7                   => :17 " + 
                    "                                            ,  p_attribute8                   => :18 " + 
                    "                                            ,  p_attribute9                   => :19 " + 
                    "                                            ,  p_attribute10                  => :20 " + 
                    "                                            ,  p_attribute11                  => :21 " + 
                    "                                            ,  p_attribute12                  => :22 " + 
                    "                                            ,  p_attribute13                  => :23 " + 
                    "                                            ,  p_attribute14                  => :24 " + 
                    "                                            ,  p_attribute15                  => :25 " + 
                    "                                            ,  p_attribute16                  => :26 " + 
                    "                                            ,  p_attribute17                  => :27 " + 
                    "                                            ,  p_attribute18                  => :28 " + 
                    "                                            ,  p_attribute19                  => :29 " + 
                    "                                            ,  p_attribute20                  => :30);" + 
                    " END; ";

                oraclecallablestatement = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(s, 
                                                                                         -1);
                oraclecallablestatement.registerOutParameter(1, Types.VARCHAR);
                oraclecallablestatement.setNUMBER(2, 
                                                  (Number)custHeadRow.getAttribute("CustAccountId"));
                oraclecallablestatement.setNUMBER(3, 
                                                  (Number)tempHeaderRow.getAttribute("CustDocId"));
                oraclecallablestatement.setString(4, 
                                                  (String)tempHeaderRow.getAttribute("EbillFileCreationType"));
                oraclecallablestatement.setString(5, 
                                                  (String)tempHeaderRow.getAttribute("DelimiterChar"));
                oraclecallablestatement.setString(6, 
                                                  (String)tempHeaderRow.getAttribute("LineFeedStyle"));
                oraclecallablestatement.setString(7, 
                                                  (String)tempHeaderRow.getAttribute("IncludeHeader"));
                oraclecallablestatement.setString(8, 
                                                  (String)tempHeaderRow.getAttribute("LogoFileName"));
                oraclecallablestatement.setString(9, 
                                                  (String)tempHeaderRow.getAttribute("FileSplitCriteria"));
                oraclecallablestatement.setNUMBER(10, 
                                                  (Number)tempHeaderRow.getAttribute("FileSplitValue"));
                oraclecallablestatement.setString(11, 
                                                  (String)tempHeaderRow.getAttribute("Attribute1"));
                oraclecallablestatement.setString(12, 
                                                  (String)tempHeaderRow.getAttribute("Attribute2"));
                oraclecallablestatement.setString(13, 
                                                  (String)tempHeaderRow.getAttribute("Attribute3"));
                oraclecallablestatement.setString(14, 
                                                  (String)tempHeaderRow.getAttribute("Attribute4"));
                oraclecallablestatement.setString(15, 
                                                  (String)tempHeaderRow.getAttribute("Attribute5"));
                oraclecallablestatement.setString(16, 
                                                  (String)tempHeaderRow.getAttribute("Attribute6"));
                oraclecallablestatement.setString(17, 
                                                  (String)tempHeaderRow.getAttribute("Attribute7"));
                oraclecallablestatement.setString(18, 
                                                  (String)tempHeaderRow.getAttribute("Attribute8"));
                oraclecallablestatement.setString(19, 
                                                  (String)tempHeaderRow.getAttribute("Attribute9"));
                oraclecallablestatement.setString(20, 
                                                  (String)tempHeaderRow.getAttribute("Attribute10"));
                oraclecallablestatement.setString(21, 
                                                  (String)tempHeaderRow.getAttribute("Attribute11"));
                oraclecallablestatement.setString(22, 
                                                  (String)tempHeaderRow.getAttribute("Attribute12"));
                oraclecallablestatement.setString(23, 
                                                  (String)tempHeaderRow.getAttribute("Attribute13"));
                oraclecallablestatement.setString(24, 
                                                  (String)tempHeaderRow.getAttribute("Attribute14"));
                oraclecallablestatement.setString(25, 
                                                  (String)tempHeaderRow.getAttribute("Attribute15"));
                oraclecallablestatement.setString(26, 
                                                  (String)tempHeaderRow.getAttribute("Attribute16"));
                oraclecallablestatement.setString(27, 
                                                  (String)tempHeaderRow.getAttribute("Attribute17"));
                oraclecallablestatement.setString(28, 
                                                  (String)tempHeaderRow.getAttribute("Attribute18"));
                oraclecallablestatement.setString(29, 
                                                  (String)tempHeaderRow.getAttribute("Attribute19"));
                oraclecallablestatement.setString(30, 
                                                  (String)tempHeaderRow.getAttribute("Attribute20"));
                oraclecallablestatement.execute();
                returnStatus = oraclecallablestatement.getString(1);
                if (returnStatus.equals("FALSE"))
                    returnFlag = "FALSE";
                oraclecallablestatement.close();
                tempHeaderRow = (OARow)tempHeaderVO.next();
            } //End for

            utl.log("Inside Validate TemplHeaderEO Entity: resultFlag: " + 
                    returnFlag);
            if (returnFlag.equals("FALSE")) {
                String errorCodes = 
                    "SELECT error_code FROM xx_cdh_ebl_error WHERE cust_doc_id = " + 
                    custDocId;
                errCall = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(errorCodes, 
                                                                                         -1);
                errRS = (OracleResultSet)errCall.executeQuery();

                while (errRS.next()) {
                    String errorCode = errRS.getString("error_code");
                    exceptions.add(new OAException("XXCRM", errorCode));

                }
                errRS.close();
                errCall.close();
            }
            OAException.raiseBundledOAException(exceptions);
        } catch (SQLException sqlexception) {
            throw OAException.wrapperException(sqlexception);
        } catch (Exception exception) {
            throw OAException.wrapperException(exception);
        }
		finally {
			try {
				if (oraclecallablestatement != null)
					oraclecallablestatement.close();
				if (errRS != null)
					errRS.close();
				if (errCall != null)
					errCall.close();				
			}
			catch(Exception exc) {  }
		}
    } //validateTemplHeader


    /*  This method call the xx_cdh_ebl_validate_pkg.validate_ebl_templ_dtl PL/SQL procedure
   *  to validate template detail */

    protected void validateTemplDtl() {
        String returnStatus = "TRUE";
        String returnFlag = "TRUE";
        String custDocId = null;
		OracleCallableStatement oraclecallablestatement = null;
		OracleCallableStatement errCall = null;
		ResultSet errRS = null;	

        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            ODUtil utl = new ODUtil(oadbtransactionimpl);

            utl.log("Inside validateTemplDtl");

            OAViewObject custHeadVO = 
                (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
            OARow custHeadRow = (OARow)custHeadVO.first();

            String deliveryMethod = null;
            if (custHeadRow != null)
                deliveryMethod = 
                        (String)custHeadRow.getAttribute("DeliveryMethod");

            OAViewObject custHeaderVO = 
                (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
            OARow custHeaderRow = (OARow)custHeaderVO.first();

            OAViewObject tempHeaderVO = 
                (OAViewObject)this.findViewObject("ODEBillTempHeaderVO");
            OARow tempHeaderRow = (OARow)tempHeaderVO.first();

            String fileCreationType = "FIXED";
            if (tempHeaderRow != null)
                fileCreationType = 
                        (String)tempHeaderRow.getAttribute("EbillFileCreationType");

            OAViewObject templDtlVO = null;
            OARow templDtlRow = null;

            if ("eXLS".equals(deliveryMethod))
                templDtlVO = 
                        (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
            if ("eTXT".equals(deliveryMethod))
                templDtlVO = 
                        (OAViewObject)this.findViewObject("ODEBillNonStdVO");


            ArrayList exceptions = new ArrayList();
            templDtlRow = (OARow)templDtlVO.first();

            if (templDtlRow != null)
                custDocId = templDtlRow.getAttribute("CustDocId").toString();

            for (int i = 0; i < templDtlVO.getRowCount(); i++) {
                String s = 
                    " BEGIN " + "   :1 :=  XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_TEMPL_DTL( p_cust_account_id => :2" + 
                    " ,p_ebill_file_creation_type=> :3" + 
                    " ,p_ebl_templ_id            => :4" + 
                    " ,p_cust_doc_id             => :5" + 
                    " ,p_record_type             => :6" + 
                    " ,p_seq                     => :7" + 
                    " ,p_field_id                => :8" + 
                    " ,p_label                   => :9" + 
                    " ,p_start_pos               => :10" + 
                    " ,p_field_len               => :11" + 
                    " ,p_data_format             => :12" + 
                    " ,p_string_fun              => :13" + 
                    " ,p_sort_order              => :14" + 
                    " ,p_sort_type               => :15" + 
                    " ,p_mandatory               => :16" + 
                    " ,p_seq_start_val           => :17" + 
                    " ,p_seq_inc_val             => :18" + 
                    " ,p_seq_reset_field         => :19" + 
                    " ,p_constant_value          => :20" + 
                    " ,p_alignment               => :21" + 
                    " ,p_padding_char            => :22" + 
                    " ,p_default_if_null         => :23" + 
                    " ,p_comments                => :24" + 
                    " ,p_attribute1              => :25" + 
                    " ,p_attribute2              => :26" + 
                    " ,p_attribute3              => :27" + 
                    " ,p_attribute4              => :28" + 
                    " ,p_attribute5              => :29" + 
                    " ,p_attribute6              => :30" + 
                    " ,p_attribute7              => :31" + 
                    " ,p_attribute8              => :32" + 
                    " ,p_attribute9              => :33" + 
                    " ,p_attribute10             => :34" + 
                    " ,p_attribute11             => :35" + 
                    " ,p_attribute12             => :36" + 
                    " ,p_attribute13             => :37" + 
                    " ,p_attribute14             => :38" + 
                    " ,p_attribute15             => :39" + 
                    " ,p_attribute16             => :40" + 
                    " ,p_attribute17             => :41" + 
                    " ,p_attribute18             => :42" + 
                    " ,p_attribute19             => :43" + 
                    " ,p_attribute20             => :44);" + " END;";
                oraclecallablestatement = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(s, 
                                                                                         -1);
                oraclecallablestatement.registerOutParameter(1, Types.VARCHAR);
                oraclecallablestatement.setNUMBER(2, 
                                                  (Number)custHeaderRow.getAttribute("CustAccountId"));
                oraclecallablestatement.setString(3, (String)fileCreationType);
                oraclecallablestatement.setNUMBER(4, 
                                                  (Number)templDtlRow.getAttribute("EblTemplId"));
                oraclecallablestatement.setNUMBER(5, 
                                                  (Number)templDtlRow.getAttribute("CustDocId"));
                oraclecallablestatement.setString(6, 
                                                  (String)templDtlRow.getAttribute("RecordType"));
                oraclecallablestatement.setNUMBER(7, 
                                                  (Number)templDtlRow.getAttribute("Seq"));
                oraclecallablestatement.setNUMBER(8, 
                                                  (Number)templDtlRow.getAttribute("FieldId"));
                oraclecallablestatement.setString(9, 
                                                  (String)templDtlRow.getAttribute("Label"));
                oraclecallablestatement.setNUMBER(10, 
                                                  (Number)templDtlRow.getAttribute("StartPos"));
                oraclecallablestatement.setNUMBER(11, 
                                                  (Number)templDtlRow.getAttribute("FieldLen"));
                oraclecallablestatement.setString(12, 
                                                  (String)templDtlRow.getAttribute("DataFormat"));
                oraclecallablestatement.setString(13, 
                                                  (String)templDtlRow.getAttribute("StringFun"));
                oraclecallablestatement.setNUMBER(14, 
                                                  (Number)templDtlRow.getAttribute("SortOrder"));
                oraclecallablestatement.setString(15, 
                                                  (String)templDtlRow.getAttribute("SortType"));
                oraclecallablestatement.setString(16, 
                                                  (String)templDtlRow.getAttribute("Mandatory"));
                oraclecallablestatement.setNUMBER(17, 
                                                  (Number)templDtlRow.getAttribute("SeqStartVal"));
                oraclecallablestatement.setNUMBER(18, 
                                                  (Number)templDtlRow.getAttribute("SeqIncVal"));
                oraclecallablestatement.setNUMBER(19, 
                                                  (Number)templDtlRow.getAttribute("SeqResetField"));
                oraclecallablestatement.setString(20, 
                                                  (String)templDtlRow.getAttribute("ConstantValue"));
                oraclecallablestatement.setString(21, 
                                                  (String)templDtlRow.getAttribute("Alignment"));
                oraclecallablestatement.setString(22, 
                                                  (String)templDtlRow.getAttribute("PaddingChar"));
                oraclecallablestatement.setString(23, 
                                                  (String)templDtlRow.getAttribute("DefaultIfNull"));
                oraclecallablestatement.setString(24, 
                                                  (String)templDtlRow.getAttribute("Comments"));
                oraclecallablestatement.setString(25, 
                                                  (String)templDtlRow.getAttribute("Attribute1"));
                oraclecallablestatement.setString(26, 
                                                  (String)templDtlRow.getAttribute("Attribute2"));
                oraclecallablestatement.setString(27, 
                                                  (String)templDtlRow.getAttribute("Attribute3"));
                oraclecallablestatement.setString(28, 
                                                  (String)templDtlRow.getAttribute("Attribute4"));
                oraclecallablestatement.setString(29, 
                                                  (String)templDtlRow.getAttribute("Attribute5"));
                oraclecallablestatement.setString(30, 
                                                  (String)templDtlRow.getAttribute("Attribute6"));
                oraclecallablestatement.setString(31, 
                                                  (String)templDtlRow.getAttribute("Attribute7"));
                oraclecallablestatement.setString(32, 
                                                  (String)templDtlRow.getAttribute("Attribute8"));
                oraclecallablestatement.setString(33, 
                                                  (String)templDtlRow.getAttribute("Attribute9"));
                oraclecallablestatement.setString(34, 
                                                  (String)templDtlRow.getAttribute("Attribute10"));
                oraclecallablestatement.setString(35, 
                                                  (String)templDtlRow.getAttribute("Attribute11"));
                oraclecallablestatement.setString(36, 
                                                  (String)templDtlRow.getAttribute("Attribute12"));
                oraclecallablestatement.setString(37, 
                                                  (String)templDtlRow.getAttribute("Attribute13"));
                oraclecallablestatement.setString(38, 
                                                  (String)templDtlRow.getAttribute("Attribute14"));
                oraclecallablestatement.setString(39, 
                                                  (String)templDtlRow.getAttribute("Attribute15"));
                oraclecallablestatement.setString(40, 
                                                  (String)templDtlRow.getAttribute("Attribute16"));
                oraclecallablestatement.setString(41, 
                                                  (String)templDtlRow.getAttribute("Attribute17"));
                oraclecallablestatement.setString(42, 
                                                  (String)templDtlRow.getAttribute("Attribute18"));
                oraclecallablestatement.setString(43, 
                                                  (String)templDtlRow.getAttribute("Attribute19"));
                oraclecallablestatement.setString(44, 
                                                  (String)templDtlRow.getAttribute("Attribute20"));
                oraclecallablestatement.execute();
                returnStatus = oraclecallablestatement.getString(1);
                if (returnStatus.equals("FALSE"))
                    returnFlag = "FALSE";
                oraclecallablestatement.close();
                templDtlRow = (OARow)templDtlVO.next();
            } //End for

            utl.log("Inside Validate TemplDtlEO Entity: resultFlag: " + 
                    returnFlag);
            if (returnFlag.equals("FALSE")) {
                String errorCodes = 
                    "SELECT error_code FROM xx_cdh_ebl_error WHERE cust_doc_id = " + 
                    custDocId;
                errCall = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(errorCodes, 
                                                                                         -1);
                errRS = (OracleResultSet)errCall.executeQuery();

                while (errRS.next()) {
                    String errorCode = errRS.getString("error_code");
                    exceptions.add(new OAException("XXCRM", errorCode));
                }
                errRS.close();
                errCall.close();
            } // if (returnStatus.equals("FALSE"))

            OAException.raiseBundledOAException(exceptions);

        } catch (SQLException sqlexception) {
            throw OAException.wrapperException(sqlexception);
        } catch (Exception exception) {
            throw OAException.wrapperException(exception);
        }
		finally {
			try {
				if (oraclecallablestatement != null)
					oraclecallablestatement.close();
				if (errRS != null)
					errRS.close();
				if (errCall != null)
					errCall.close();				
			}
			catch(Exception exc) {  }
		}
    } // End of validateTemplDtl()

    /*  This method calls the xx_cdh_ebl_validate_pkg.validate_ebl_std_aggr_dtl PL/SQL procedure
   *  to validate standard aggrigate detail */

    protected void validateAggrDtl() {
        String returnStatus = "TRUE";
        String returnFlag = "TRUE";
        String custDocId = null;
		OracleCallableStatement oraclecallablestatement = null;
		OracleCallableStatement errCall = null;
		ResultSet errRS = null;	

        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            ODUtil utl = new ODUtil(oadbtransactionimpl);
            utl.log("Inside validateAggrDtl");

            OAViewObject stdAggrDtlVO = 
                (OAViewObject)this.findViewObject("ODEBillStdAggrDtlVO");
            OARow stdAggrDtlRow = (OARow)stdAggrDtlVO.first();
            if (stdAggrDtlRow != null)
                custDocId = stdAggrDtlRow.getAttribute("CustDocId").toString();
            ArrayList exceptions = new ArrayList();
            for (int i = 0; i < stdAggrDtlVO.getRowCount(); i++) {
                String s = 
                    " BEGIN " + "   :1 :=  XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_STD_AGGR_DTL(p_ebl_aggr_id   => :2  " + 
                    "                                            ,  p_cust_doc_id               => :3  " + 
                    "                                            ,  p_aggr_fun                  => :4  " + 
                    "                                            ,  p_aggr_field_id             => :5  " + 
                    "                                            ,  p_change_field_id           => :6  " + 
                    "                                            ,  p_label_on_file             => :7  " + 
                    "                                            ,  p_attribute1                => :8 " + 
                    "                                            ,  p_attribute2                => :9 " + 
                    "                                            ,  p_attribute3                => :10" + 
                    "                                            ,  p_attribute4                => :11" + 
                    "                                            ,  p_attribute5                => :12 " + 
                    "                                            ,  p_attribute6                => :13 " + 
                    "                                            ,  p_attribute7                => :14 " + 
                    "                                            ,  p_attribute8                => :15 " + 
                    "                                            ,  p_attribute9                => :16 " + 
                    "                                            ,  p_attribute10               => :17 " + 
                    "                                            ,  p_attribute11               => :18 " + 
                    "                                            ,  p_attribute12               => :19 " + 
                    "                                            ,  p_attribute13               => :20 " + 
                    "                                            ,  p_attribute14               => :21 " + 
                    "                                            ,  p_attribute15               => :22 " + 
                    "                                            ,  p_attribute16               => :23 " + 
                    "                                            ,  p_attribute17               => :24 " + 
                    "                                            ,  p_attribute18               => :25 " + 
                    "                                            ,  p_attribute19               => :26 " + 
                    "                                            ,  p_attribute20               => :27);" + 
                    " END; ";

                oraclecallablestatement = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(s, 
                                                                                         -1);
                oraclecallablestatement.registerOutParameter(1, Types.VARCHAR);
                oraclecallablestatement.setNUMBER(2, 
                                                  (Number)stdAggrDtlRow.getAttribute("AggrFieldId"));
                oraclecallablestatement.setNUMBER(3, 
                                                  (Number)stdAggrDtlRow.getAttribute("CustDocId"));
                oraclecallablestatement.setString(4, 
                                                  (String)stdAggrDtlRow.getAttribute("AggrFun"));
                oraclecallablestatement.setNUMBER(5, 
                                                  (Number)stdAggrDtlRow.getAttribute("AggrFieldId"));
                oraclecallablestatement.setNUMBER(6, 
                                                  (Number)stdAggrDtlRow.getAttribute("ChangeFieldId"));
                oraclecallablestatement.setString(7, 
                                                  (String)stdAggrDtlRow.getAttribute("LabelOnFile"));
                oraclecallablestatement.setString(8, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute1"));
                oraclecallablestatement.setString(9, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute2"));
                oraclecallablestatement.setString(10, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute3"));
                oraclecallablestatement.setString(11, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute4"));
                oraclecallablestatement.setString(12, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute5"));
                oraclecallablestatement.setString(13, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute6"));
                oraclecallablestatement.setString(14, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute7"));
                oraclecallablestatement.setString(15, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute8"));
                oraclecallablestatement.setString(16, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute9"));
                oraclecallablestatement.setString(17, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute10"));
                oraclecallablestatement.setString(18, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute11"));
                oraclecallablestatement.setString(19, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute12"));
                oraclecallablestatement.setString(20, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute13"));
                oraclecallablestatement.setString(21, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute14"));
                oraclecallablestatement.setString(22, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute15"));
                oraclecallablestatement.setString(23, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute16"));
                oraclecallablestatement.setString(24, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute17"));
                oraclecallablestatement.setString(25, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute18"));
                oraclecallablestatement.setString(26, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute19"));
                oraclecallablestatement.setString(27, 
                                                  (String)stdAggrDtlRow.getAttribute("Attribute20"));
                oraclecallablestatement.execute();
                returnStatus = oraclecallablestatement.getString(1);
                if (returnStatus.equals("FALSE"))
                    returnFlag = "FALSE";
                oraclecallablestatement.close();
                stdAggrDtlRow = (OARow)stdAggrDtlVO.next();
            } //End for

            utl.log("Inside Validate StdAggrDtlEO Entity: resultFlag: " + 
                    returnFlag);
            if (returnFlag.equals("FALSE")) {
                String errorCodes = 
                    "SELECT error_code FROM xx_cdh_ebl_error WHERE cust_doc_id = " + 
                    custDocId;
                errCall = 
                    (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(errorCodes, 
                                                                                         -1);
                errRS = (OracleResultSet)errCall.executeQuery();

                while (errRS.next()) {
                    String errorCode = errRS.getString("error_code");
                    exceptions.add(new OAException("XXCRM", errorCode));
                }
                errRS.close();
                errCall.close();
            } // (returnStatus.equals("FALSE"))
            // stdAggrDtlRow = (OARow) stdAggrDtlVO.next();

            OAException.raiseBundledOAException(exceptions);

        } catch (SQLException sqlexception) {
            throw OAException.wrapperException(sqlexception);
        } catch (Exception exception) {
            throw OAException.wrapperException(exception);
        }
		finally {
			try {
				if (oraclecallablestatement != null)
					oraclecallablestatement.close();
				if (errRS != null)
					errRS.close();
				if (errCall != null)
					errCall.close();				
			}
			catch(Exception exc) {  }
        }

    } //End of validateAggrDtl

    public void deleteEnableDisable() {
        ODEBillContactsVORowImpl contactRow = null;
        OAViewObjectImpl contactVO = getODEBillContactsVO();
        int rowCount = contactVO.getRowCount();
        //    RowSetIterator checkIter = contactVO.createRowSetIterator("checkIter");

        if (rowCount > 1) {
            //      checkIter.setRangeStart(0);
            //      checkIter.setRangeSize(rowCount);
            for (contactRow = (ODEBillContactsVORowImpl)contactVO.first(); 
                 contactRow != null; 
                 contactRow = (ODEBillContactsVORowImpl)contactVO.next()) {
                //        contactRow = (ODEBillContactsVORowImpl) checkIter.getRowAtRangeIndex(0);
                if (contactRow != null) {
                    contactRow.setDeleteImageSwitch("DeleteContact");
                }
            }
        } else if (rowCount == 1) {
            contactRow = (ODEBillContactsVORowImpl)contactVO.first();
            contactRow.setDeleteImageSwitch("DeleteDisable");
        }
        //    checkIter.closeRowSetIterator();
    }

    /**
     *
     * Container's getter for ODEBillStdAggrDtlVO
     */
    public OAViewObjectImpl getODEBillStdAggrDtlVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillStdAggrDtlVO");
    }


    /**
     *
     * Container's getter for ODEBillAggrFunPVO
     */
    public OAViewObjectImpl getODEBillAggrFunPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillAggrFunPVO");
    }

    /**
     *
     * Container's getter for ODEBillAssociatePVO
     */
    public OAViewObjectImpl getODEBillAssociatePVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillAssociatePVO");
    }

    /**
     *
     * Container's getter for ODEBillCompUtilPVO
     */
    public OAViewObjectImpl getODEBillCompUtilPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillCompUtilPVO");
    }

    /**
     *
     * Container's getter for ODEBillDelimitCharPVO
     */
    public OAViewObjectImpl getODEBillDelimitCharPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillDelimitCharPVO");
    }

    /**
     *
     * Container's getter for ODEBillDocStatusPVO
     */
    public OAViewObjectImpl getODEBillDocStatusPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillDocStatusPVO");
    }

    /**
     *
     * Container's getter for ODEBillFTPDirectPVO
     */
    public OAViewObjectImpl getODEBillFTPDirectPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillFTPDirectPVO");
    }

    /**
     *
     * Container's getter for ODEBillFieldAlignPVO
     */
    public OAViewObjectImpl getODEBillFieldAlignPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillFieldAlignPVO");
    }

    /**
     *
     * Container's getter for ODEBillFieldPaddCharPVO
     */
    public OAViewObjectImpl getODEBillFieldPaddCharPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillFieldPaddCharPVO");
    }

    /**
     *
     * Container's getter for ODEBillFileCreatTypePVO
     */
    public OAViewObjectImpl getODEBillFileCreatTypePVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillFileCreatTypePVO");
    }

    /**
     *
     * Container's getter for ODEBillFileProcMtdPVO
     */
    public OAViewObjectImpl getODEBillFileProcMtdPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillFileProcMtdPVO");
    }

    /**
     *
     * Container's getter for ODEBillLogoFilePVO
     */
    public OAViewObjectImpl getODEBillLogoFilePVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillLogoFilePVO");
    }

    /**
     *
     * Container's getter for ODEBillRecordTypePVO
     */
    public OAViewObjectImpl getODEBillRecordTypePVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillRecordTypePVO");
    }

    /**
     *
     * Container's getter for ODEBillSortOrderPVO
     */
    public OAViewObjectImpl getODEBillSortOrderPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSortOrderPVO");
    }

    /**
     *
     * Container's getter for ODEBillStdContLvlPVO
     */
    public OAViewObjectImpl getODEBillStdContLvlPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillStdContLvlPVO");
    }

    /**
     *
     * Container's getter for ODEBillTransTypePVO
     */
    public OAViewObjectImpl getODEBillTransTypePVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillTransTypePVO");
    }

    /**
     *
     * Sample main for debugging Business Components code using the tester.
     */
    public static void main(String[] args) {
        launchTester("od.oracle.apps.xxcrm.cdh.ebl.server", "OAEBillAMLocal");
    }


    /**
     *
     * Container's getter for ODEBillFileSeqResetVO
     */
    public OAViewObjectImpl getODEBillFileSeqResetVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillFileSeqResetVO");
    }

    /**
     *
     * Container's getter for ODEBillFileFieldParamPVO
     */
    public OAViewObjectImpl getODEBillFileFieldParamPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillFileFieldParamPVO");
    }

    /**
     *
     * Container's getter for ODEBillDocSearchVO
     */
    public OAViewObjectImpl getODEBillDocSearchVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillDocSearchVO");
    }



    /**
     *
     * Container's getter for ODEbillCustDocVO
     */
    public ODEbillCustDocVOImpl getODEbillCustDocVO() {
        return (ODEbillCustDocVOImpl)findViewObject("ODEbillCustDocVO");
    }

    /**
     *
     * Container's getter for ODEBillDocTypePVO
     */
    public ODEBillDocTypePVOImpl getODEBillDocTypePVO() {
        return (ODEBillDocTypePVOImpl)findViewObject("ODEBillDocTypePVO");
    }

    /**
     *
     * Container's getter for ODEBillDelyMethodPVO
     */
    public ODEBillDelyMethodPVOImpl getODEBillDelyMethodPVO() {
        return (ODEBillDelyMethodPVOImpl)findViewObject("ODEBillDelyMethodPVO");
    }

    /**
     *
     * Container's getter for ODEBillComboPVO
     */
    public ODEBillComboPVOImpl getODEBillComboPVO() {
        return (ODEBillComboPVOImpl)findViewObject("ODEBillComboPVO");
    }

    /**
     *
     * Container's getter for ODEBillCharYesNo
     */
    public ODEBillCharYesNoImpl getODEBillCharYesNo() {
        return (ODEBillCharYesNoImpl)findViewObject("ODEBillCharYesNo");
    }

    /**
     *
     * Container's getter for ODEBillNSFieldNamesPVO
     */
    public OAViewObjectImpl getODEBillNSFieldNamesPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillNSFieldNamesPVO");
    }


    /**
     *
     * Container's getter for ODEBillNumYesNoPVO
     */
    public ODEBillNumYesNoPVOImpl getODEBillNumYesNoPVO() {
        return (ODEBillNumYesNoPVOImpl)findViewObject("ODEBillNumYesNoPVO");
    }


    /**
     *
     * Container's getter for ODEBillCustHeaderVO
     */
    public OAViewObjectImpl getODEBillCustHeaderVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillCustHeaderVO");
    }


    /**
     *
     * Container's getter for ODEBillStdFieldsVO
     */
    public OAViewObjectImpl getODEBillStdFieldsVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillStdFieldsVO");
    }

    /**
     *
     * Container's getter for ODEBillSortTypePVO
     */
    public OAViewObjectImpl getODEBillSortTypePVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSortTypePVO");
    }


    /**
     *
     * Container's getter for ODEBillSplitTypePVO
     */
    public OAViewObjectImpl getODEBillSplitTypePVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSplitTypePVO");
    }

    /**
     *
     * Container's getter for ODEBillNonStdVO
     */
    public OAViewObjectImpl getODEBillNonStdVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillNonStdVO");
    }

    /**
     *
     * Container's getter for ODEBillTempHeaderVO
     */
    public OAViewObjectImpl getODEBillTempHeaderVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillTempHeaderVO");
    }


    /**
     *
     * Container's getter for ODEBillContactsVO
     */
    public OAViewObjectImpl getODEBillContactsVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillContactsVO");
    }

    /**
     *
     * Container's getter for ODEBillFileNameVO
     */
    public OAViewObjectImpl getODEBillFileNameVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillFileNameVO");
    }


    /**
     *
     * Container's getter for ODEBillLineFeedPVO
     */
    public OAViewObjectImpl getODEBillLineFeedPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillLineFeedPVO");
    }

    /**
     *
     * Container's getter for XxcrmEblContUploadsView1
     */
    public XxcrmEblContUploadsVOImpl getXxcrmEblContUploadsVO() {
        return (XxcrmEblContUploadsVOImpl)findViewObject("od.oracle.apps.xxcrm.cdh.uploads.eblContacts.server.XxcrmEblContUploadsVO");
    }


    /**Container's getter for ODEBillSplitTabsByPVO
     */
    public OAViewObjectImpl getODEBillSplitTabsByPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSplitTabsByPVO");
    }

    /**Container's getter for ODEBillConcatenateVO
     */
    public OAViewObjectImpl getODEBillConcatenateVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillConcatenateVO");
    }

    /**Container's getter for ODEBillConcatFieldsPVO
     */
    public OAViewObjectImpl getODEBillConcatFieldsPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillConcatFieldsPVO");
    }

    /**Container's getter for ODEBillSplitFieldsPVO
     */
    public OAViewObjectImpl getODEBillSplitFieldsPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSplitFieldsPVO");
    }


    public void handleSplitTypePPR(String sSplitFieldId) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start handleSplitTypePPR " + sSplitFieldId, 1);

        OAViewObject splitVO = this.getODEBillSplitVO();
        splitVO.reset();
        while (splitVO.hasNext()) {

            OARow splitRow = (OARow)splitVO.next();

            String srowSplitFieldId = null;
            srowSplitFieldId = 
                    splitRow.getAttribute("SplitFieldId").toString();
            if (sSplitFieldId.equals(srowSplitFieldId)) {
                String sSplit = "";
                sSplit = (String)splitRow.getAttribute("SplitType");
                myAppsLog.write("ODEBillAMImpl", "XXOD:sSplit " + sSplit, 1);
                if ("FP".equalsIgnoreCase(sSplit)) {
                    splitRow.setAttribute("EnableFixedPosition", 
                                          Boolean.FALSE);
                    splitRow.setAttribute("EnableDelimiter", Boolean.TRUE);

                    splitRow.setAttribute("Delimiter", "");


                } else {
                    splitRow.setAttribute("EnableFixedPosition", Boolean.TRUE);
                    splitRow.setAttribute("EnableDelimiter", Boolean.FALSE);
                    splitRow.setAttribute("FixedPosition", "");


                }
            }
        }


    }

    /**Container's getter for ODEBillSplitVO
     */
    public OAViewObjectImpl getODEBillSplitVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSplitVO");
    }

    /**Container's getter for ODEBillSplitDelimiterByPVO
     */
    public OAViewObjectImpl getODEBillSplitDelimiterByPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSplitDelimiterByPVO");
    }


    public void refreshTemplDtlVOOnChecking(OAViewObject templDtlVO, 
                                            OAViewObject concatFieldsVO, 
                                            OAViewObject splitFieldsVO) {
         
        AppsLog myAppsLog = new AppsLog();                                    
        myAppsLog.write("fnd.common.WebAppsContext", 
                        "XXOD: start refreshTemplDtlVOOnChecking", 
                        1);
                        
        RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
        rsi.reset();
        while (rsi.hasNext()) {
            Row templDtlRow = rsi.next();
            String sConcat = null;
            String sSplit = null;
            String sSelect = null;

            if (templDtlRow.getAttribute("Concatenate") != null)
                sConcat = templDtlRow.getAttribute("Concatenate").toString();

            if (templDtlRow.getAttribute("Split") != null)
                sSplit = templDtlRow.getAttribute("Split").toString();

            if (templDtlRow.getAttribute("Attribute1") != null)
                sSelect = templDtlRow.getAttribute("Attribute1").toString();
          

            oracle.jbo.domain.Number nFieldId = null;

            nFieldId = 
                    (oracle.jbo.domain.Number)templDtlRow.getAttribute("FieldId");
            String sField = "" + nFieldId;
            templDtlRow.setAttribute("ConcatFlag", Boolean.TRUE);
            templDtlRow.setAttribute("SplitFlag", Boolean.TRUE);

            concatFieldsVO.reset();
            while (concatFieldsVO.hasNext()) {
                String sCode = null;
                OARow concatVORow = (OARow)concatFieldsVO.next();
                sCode = (String)concatVORow.getAttribute("Code");
                if (sField.equals(sCode)) {
                    templDtlRow.setAttribute("ConcatFlag", Boolean.FALSE);
                    break;
                }
            }

            splitFieldsVO.reset();
            while (splitFieldsVO.hasNext()) {
                String sCode = null;
                OARow splitVORow = (OARow)splitFieldsVO.next();
                sCode = (String)splitVORow.getAttribute("Code");
                if (sField.equals(sCode)) {
                    templDtlRow.setAttribute("SplitFlag", Boolean.FALSE);
                    break;
                }
            }
        }

        myAppsLog.write("fnd.common.WebAppsContext", 
                        "XXOD: end refreshTemplDtlVOOnChecking", 
                        1);
    }


    public void renderConcatSplit(String sConcatSplit) {
        //Logic for hiding region
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", "XXOD:sConcatSplit " + sConcatSplit, 
                        1);

        if ("Y".equalsIgnoreCase(sConcatSplit)) {
            PPRRow.setAttribute("ConcatSplit", Boolean.TRUE);
            PPRRow.setAttribute("ConcatSplitMsg", Boolean.FALSE);
        } else {
            PPRRow.setAttribute("ConcatSplit", Boolean.FALSE);
            PPRRow.setAttribute("ConcatSplitMsg", Boolean.TRUE);
        }
    }


    /**Container's getter for ODEBillDynConcFieldsVO
     */
    public OAViewObjectImpl getODEBillDynConcFieldsVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillDynConcFieldsVO");
    }

    /**Container's getter for ODEBillDynSplitFieldsVO
     */
    public OAViewObjectImpl getODEBillDynSplitFieldsVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillDynSplitFieldsVO");
    }

    /**Container's getter for ODEBillSubTotalFieldsVO
     */
    public OAViewObjectImpl getODEBillSubTotalFieldsVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSubTotalFieldsVO");
    }


    /**Container's getter for ODEBillConfigDetailsFieldNamesPVO
     */
    public OAViewObjectImpl getODEBillConfigDetailsFieldNamesPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillConfigDetailsFieldNamesPVO");
    }


    public void saveConcatenate(String custDocId, String custAccountId) {


        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", "XXOD:Start saveConcatenate ", 1);


        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");

        OAViewObject concVO = this.getODEBillConcatenateVO();

        //Logic for fetching concatenate field id into array
        java.util.ArrayList arrConcList = new java.util.ArrayList();
        concVO.reset();
        while (concVO.hasNext()) {
            OARow concRow = (OARow)concVO.next();
            myAppsLog.write("ODEBillAMImpl", 
                            "XXOD:saveConcatenate " + concRow.getAttribute("ConcFieldId").toString(), 
                            1);
            arrConcList.add(concRow.getAttribute("ConcFieldId").toString());
        }
        //End - Logic for fetching concatenate field id into array

        //For each concatenate row, logic to update/add row to configuration details
        concVO.reset();
        while (concVO.hasNext()) {


            OARow concRow = (OARow)concVO.next();


            String sConcField = null;
            sConcField = concRow.getAttribute("ConcFieldId").toString();
            String sFlag = 
                chkIfExistsInTemplDtlVO(templDtlVO, sConcField, "CONCAT");

            myAppsLog.write("ODEBillAMImpl", 
                            "XXOD:sConcField " + sConcField + " sFlag:" + 
                            sFlag, 1);

            if ("Y".equals(sFlag)) {
                updConcatRow(concRow, templDtlVO, sConcField);
            } else
                addConcatRow(concRow, custDocId, custAccountId, arrConcList);


        }
        //End -For each concatenate row, logic to update/add row to configuration details


       


    } // End saveConcatenate


    /* Logic for adding new row in concatenate VO*/

    public void addConcRow(String custAccountId, String custDocId, 
                           String maxConcRows) {


        AppsLog myAppsLog = new AppsLog();

        myAppsLog.write("fnd.common.WebAppsContext", 
                        "XXOD: Start addConcRow custDocId::" + custDocId, 1);
        myAppsLog.write("fnd.common.WebAppsContext", 
                        "XXOD: custAccountId::" + custAccountId, 1);
        OADBTransaction transaction = this.getOADBTransaction();


        OAViewObject concatenateVO = 
            (OAViewObject)this.findViewObject("ODEBillConcatenateVO");
        concatenateVO.last();


        int nMaxConcRows = 0;
        if ((!"".equals(maxConcRows)) && (maxConcRows != null))
            nMaxConcRows = Integer.parseInt(maxConcRows);

        if (myAppsLog.isEnabled(1)) {
            myAppsLog.write("fnd.common.WebAppsContext", 
                            "XXOD: maxConcRows::" + nMaxConcRows, 1);
        }

        if (nMaxConcRows == 0)
            throw new OAException("XXCRM", "XXOD_EBL_MAX_CONC_NOTCONF");

        if (concatenateVO.getRowCount() < nMaxConcRows) {

            OAViewObject dynConcVO = 
                (OAViewObject)this.findViewObject("ODEBillDynConcFieldsVO");
            
            /*int nCount = dynConcVO.getRowCount();
            if (nCount == 0) {
                throw new OAException("XXCRM", "XXOD_EBL_SELCONC_DETAILS", 
                                      null, OAException.ERROR, null);
            }*/

            concatenateVO.next();
            OARow concatenateVORow = (OARow)concatenateVO.createRow();
            concatenateVORow.setAttribute("ConcFieldId", 
                                          transaction.getSequenceValue("XX_CDH_EBL_CONCAT_FIELDS_S"));
            concatenateVORow.setAttribute("CustDocId", custDocId);
            concatenateVORow.setAttribute("CustAccountId", custAccountId);

            concatenateVO.insertRow(concatenateVORow);
            concatenateVORow.setNewRowState(concatenateVORow.STATUS_INITIALIZED);

        } else {

            MessageToken[] tokens = { new MessageToken("COUNT", maxConcRows) };


            throw new OAException("XXCRM", "XXOD_EBL_MAX_CONCFIELDS", tokens, 
                                  OAException.ERROR, null);
        }


    } //End addConcRow

    public void deleteConcat(String concFieldId) {

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");

        int concFieldIdPara = Integer.parseInt(concFieldId);


        OAViewObject concatenateVO = 
            (OAViewObject)this.findViewObject("ODEBillConcatenateVO");
        ODEBillConcatenateVORowImpl concatenateVORow = null;

        int fetchedRowCount = concatenateVO.getFetchedRowCount();

        RowSetIterator deleteIter = 
            concatenateVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);

            for (int i = 0; i < fetchedRowCount; i++) {
                concatenateVORow = 
                        (ODEBillConcatenateVORowImpl)deleteIter.getRowAtRangeIndex(i);
                Number concFieldIdAttr = 
                    (Number)concatenateVORow.getAttribute("ConcFieldId");

                if (concFieldIdAttr.compareTo(concFieldIdPara) == 0) {

                    templDtlVO.reset();
                    while (templDtlVO.hasNext()) {

                        OARow templRow = (OARow)templDtlVO.next();
                        String sFieldId = 
                            templRow.getAttribute("FieldId").toString();
                        if (concFieldId.equals(sFieldId)) {

                            templRow.remove();
                        }

                    }

                    concatenateVORow.remove();
                    templDtlVO.reset(); //for resetting pointer to first row
                    break;
                }
            }
        }
        deleteIter.closeRowSetIterator();


    } //End delete

    //Logic for adding concatenate row to  configuration details 

    public void addConcatRow(OARow concRow, String custDocId, 
                             String custAccountId, 
                             java.util.ArrayList arrConcList) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("addConcatRow:", 
                        "XXOD: adding concatenate row to  configuration details ", 
                        1);
        String sConcField1 = null;
        String sConcField2 = null;
        String sConcField3 = null;

        if (concRow.getAttribute("ConcBaseFieldId1") != null) {
            sConcField1 = concRow.getAttribute("ConcBaseFieldId1").toString();
        }

        if (concRow.getAttribute("ConcBaseFieldId2") != null) {
            sConcField2 = concRow.getAttribute("ConcBaseFieldId2").toString();
        }

        if (concRow.getAttribute("ConcBaseFieldId3") != null) {
            sConcField3 = concRow.getAttribute("ConcBaseFieldId3").toString();
        }

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");


//        int i = templDtlVO.getRowCount();

        templDtlVO.reset();
        while (templDtlVO.hasNext()) {

            OARow templRow = (OARow)templDtlVO.next();
            String sFieldId = "-1";
            if (templRow.getAttribute("FieldId") != null)
                sFieldId = templRow.getAttribute("FieldId").toString();

            if ((sConcField1 != null) && !("".equals(sConcField1))) {
                if ((sFieldId.equals(sConcField1)) && 
                    ("Y".equals(templRow.getAttribute("Attribute20")))) {

                    templRow.setAttribute("Attribute20", "N"); 
                }
            }

            if ((sConcField2 != null) && !("".equals(sConcField2))) {
                if ((sFieldId.equals(sConcField1)) && 
                    ("Y".equals(templRow.getAttribute("Attribute20")))) {

                    templRow.setAttribute("Attribute20", "N"); 
                }
            }

            if ((sConcField3 != null) && !("".equals(sConcField3))) {
                if ((sFieldId.equals(sConcField2)) && 
                    ("Y".equals(templRow.getAttribute("Attribute20")))) {

                    templRow.setAttribute("Attribute20", "N"); 
                }
            }
        }

        templDtlVO.last();
        templDtlVO.next();

        OARow templRow = (OARow)templDtlVO.createRow();
        templRow.setAttribute("CustDocId", custDocId);
        // templRow.setAttribute("CustAccountId", custAccountId);
        templRow.setAttribute("RecordType", "000");
        templRow.setAttribute("EblTemplId", 
                              this.getOADBTransaction().getSequenceValue("XX_CDH_EBL_TEMPL_ID_S"));
        templRow.setAttribute("FieldId", concRow.getAttribute("ConcFieldId"));
        templRow.setAttribute("Label", concRow.getAttribute("ConcFieldLabel"));
        // templRow.setAttribute("DataFormat", 
        //                      "VARCHAR2");
        templRow.setAttribute("Attribute2", "N");
        templRow.setAttribute("Attribute3", "N");
        templRow.setAttribute("Attribute20", "Y");

        //templRow.setAttribute("Seq", new Number((i++) * 30));
        String sSeq = getSequence("CONCAT", custDocId, arrConcList);


        myAppsLog.write("addConcatRow:", "XXOD:sSeq " + sSeq, 1);

        templRow.setAttribute("Seq", sSeq);

        templRow.setAttribute("Attribute1", "Y");


        templDtlVO.insertRow(templRow);

        templDtlVO.last();
    }

    /* For updating concatenate row in configuration details */

    public void updConcatRow(OARow concRow, OAViewObject templDtlVO, 
                             String sFieldId) {

        RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
        rsi.reset();


        while (rsi.hasNext()) {
            Row templDtlRow = rsi.next();
            String sTemplFieldId = 
                templDtlRow.getAttribute("FieldId").toString();

            if (sFieldId.equals(sTemplFieldId)) {

                templDtlRow.setAttribute("Label", 
                                         concRow.getAttribute("ConcFieldLabel"));

                break;

            }
        }

    }

    /* For saving split row in configuration details */

    public void saveSplit(String custDocId, String custAccountId) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", "XXOD:Start saveSplit ", 1);


        java.util.ArrayList arrSplitList = new java.util.ArrayList();


        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");

        OAViewObject splitVO = this.getODEBillSplitVO();
        splitVO.reset();

        while (splitVO.hasNext()) {
            OARow splitRow = (OARow)splitVO.next();
            arrSplitList.add(splitRow.getAttribute("SplitFieldId").toString());
        }
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:arrSplitList " + arrSplitList.size(), 1);

        splitVO.reset();
        while (splitVO.hasNext()) {

            OARow splitRow = (OARow)splitVO.next();
            //For adding rows in templ details
            String sSplitField = null;
            String sSplitBaseField = null;

            java.util.ArrayList arrSplitLabel = new java.util.ArrayList();
            java.util.ArrayList arrSplitId = new java.util.ArrayList();


            sSplitField = splitRow.getAttribute("SplitFieldId").toString();


            sSplitBaseField = 
                    splitRow.getAttribute("SplitBaseFieldId").toString();


            String sFlag = 
                chkIfExistsInTemplDtlVO(templDtlVO, sSplitField, "SPLIT");
            myAppsLog.write("ODEBillAMImpl", 
                            "***XXOD:sSplitField " + sSplitField + ":sFlag:" + 
                            sFlag, 1);


            String sSplitField1Label = null;
            String sSplitField2Label = null;
            String sSplitField3Label = null;
            String sSplitField4Label = null;
            String sSplitField5Label = null;
            String sSplitField6Label = null;

            if (splitRow.getAttribute("SplitField1Label") != null)
                sSplitField1Label = 
                        splitRow.getAttribute("SplitField1Label").toString();

            if (splitRow.getAttribute("SplitField2Label") != null)
                sSplitField2Label = 
                        splitRow.getAttribute("SplitField2Label").toString();

            if (splitRow.getAttribute("SplitField3Label") != null)
                sSplitField3Label = 
                        splitRow.getAttribute("SplitField3Label").toString();


            if (splitRow.getAttribute("SplitField4Label") != null)
                sSplitField4Label = 
                        splitRow.getAttribute("SplitField4Label").toString();

            if (splitRow.getAttribute("SplitField5Label") != null)
                sSplitField5Label = 
                        splitRow.getAttribute("SplitField5Label").toString();


            if (splitRow.getAttribute("SplitField6Label") != null)
                sSplitField6Label = 
                        splitRow.getAttribute("SplitField6Label").toString();


            myAppsLog.write("ODEBillAMImpl", 
                            "***XXOD:sSplitField1Label " + sSplitField1Label, 
                            1);

            myAppsLog.write("ODEBillAMImpl", 
                            "***XXOD:sSplitField2Label " + sSplitField2Label, 
                            1);

            myAppsLog.write("ODEBillAMImpl", 
                            "***XXOD:sSplitField3Label " + sSplitField3Label, 
                            1);

            myAppsLog.write("ODEBillAMImpl", 
                            "***XXOD:sSplitField4Label " + sSplitField4Label, 
                            1);
            myAppsLog.write("ODEBillAMImpl", 
                            "***XXOD:sSplitField5Label " + sSplitField5Label, 
                            1);

            myAppsLog.write("ODEBillAMImpl", 
                            "***XXOD:sSplitField6Label " + sSplitField6Label, 
                            1);


            //if split field id already exists in configuration details
            if ("Y".equals(sFlag)) {

                myAppsLog.write("ODEBillAMImpl", 
                                "***XXOD:sSplitField ID already existing", 1);


                RowSetIterator rsi = 
                    templDtlVO.createRowSetIterator("rowsRSI");
                rsi.reset();

                while (rsi.hasNext()) {
                    Row templRow = rsi.next();

                    String sBaseFieldId = "";
                    String sFieldId = "-1";
                    String sLabel = null;
                    String sDetailFieldId = "";


                    if (templRow.getAttribute("BaseFieldId") != null)
                        sBaseFieldId = 
                                templRow.getAttribute("BaseFieldId").toString();

                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sBaseFieldId:" + sBaseFieldId, 1);


                    //if basefiedl id is not null then that will be split row
                    if ((sBaseFieldId != null) && (!"".equals(sBaseFieldId))) {

                        myAppsLog.write("ODEBillAMImpl", 
                                        "***XXOD:Is split row ", 1);

                        if (templRow.getAttribute("SplitFieldId") != null)
                            sFieldId = 
                                    templRow.getAttribute("SplitFieldId").toString();

                        if (templRow.getAttribute("Label") != null)
                            sLabel = templRow.getAttribute("Label").toString();

                        myAppsLog.write("ODEBillAMImpl", 
                                        "***XXOD:******** sLabel" + sLabel, 1);

                        if (templRow.getAttribute("FieldId") != null)
                            sDetailFieldId = 
                                    templRow.getAttribute("FieldId").toString();

                        //if it is split row matching to splitvo
                        //Logic for removing SPLIT ROWs from Configuration Details 
                        if (sSplitField.equals(sFieldId)) {
                            //If basefiedl id is not matching row shoudl be removed
                            if (!sBaseFieldId.equals(sSplitBaseField)) {
                                myAppsLog.write("ODEBillAMImpl", 
                                                "***XXOD:Base Field Id not same. Removing row from config details. sLabel" + 
                                                sLabel, 1);
                                templRow.remove();
                            } else {
                                //If basefiedl id is matching 
                                //label in details is not matching to any current split label
                                //then that should be removed


                                if ((!sLabel.equals(sSplitField1Label)) && 
                                    (!sLabel.equals(sSplitField2Label)) && 
                                    (!sLabel.equals(sSplitField3Label)) && 
                                    (!sLabel.equals(sSplitField4Label)) && 
                                    (!sLabel.equals(sSplitField5Label)) && 
                                    (!sLabel.equals(sSplitField6Label))) {
                                    myAppsLog.write("ODEBillAMImpl", 
                                                    "***XXOD:sLabel" + sLabel + 
                                                    " not matching.Removing row from config details ", 
                                                    1);
                                    templRow.remove();
                                }


                                //Start - For adding / updating configuration details split row
                                if ((sSplitField1Label != null) && 
                                    (!"".equals(sSplitField1Label))) {
                                    if (sLabel.equals(sSplitField1Label)) {
                                        myAppsLog.write("ODEBillAMImpl:Label1:", 
                                                        "***XXOD:sLabel" + 
                                                        sLabel + 
                                                        " add to arrlist for updating ", 
                                                        1);
                                        arrSplitLabel.add(sSplitField1Label);
                                        arrSplitId.add(sDetailFieldId);
                                    }

                                }

                                if ((sSplitField2Label != null) && 
                                    (!"".equals(sSplitField2Label))) {
                                    if (sLabel.equals(sSplitField2Label)) {
                                        myAppsLog.write("ODEBillAMImpl:Label2:", 
                                                        "***XXOD:sLabel" + 
                                                        sLabel + 
                                                        " add to arrlist for updating ", 
                                                        1);
                                        arrSplitLabel.add(sSplitField2Label);
                                        arrSplitId.add(sDetailFieldId);
                                    }

                                }


                                if ((sSplitField3Label != null) && 
                                    (!"".equals(sSplitField3Label))) {
                                    if (sLabel.equals(sSplitField3Label)) {
                                        myAppsLog.write("ODEBillAMImpl:Label3:", 
                                                        "***XXOD:sLabel" + 
                                                        sLabel + 
                                                        " add to arrlist for updating ", 
                                                        1);
                                        arrSplitLabel.add(sSplitField3Label);
                                        arrSplitId.add(sDetailFieldId);
                                    }

                                }

                                if ((sSplitField4Label != null) && 
                                    (!"".equals(sSplitField4Label))) {
                                    if (sLabel.equals(sSplitField4Label)) {
                                        myAppsLog.write("ODEBillAMImpl:Label4:", 
                                                        "***XXOD:sLabel" + 
                                                        sLabel + 
                                                        " add to arrlist for updating ", 
                                                        1);
                                        arrSplitLabel.add(sSplitField4Label);
                                        arrSplitId.add(sDetailFieldId);
                                    }

                                }


                                if ((sSplitField5Label != null) && 
                                    (!"".equals(sSplitField5Label))) {
                                    if (sLabel.equals(sSplitField5Label)) {
                                        myAppsLog.write("ODEBillAMImpl:Label5:", 
                                                        "***XXOD:sLabel" + 
                                                        sLabel + 
                                                        " add to arrlist for updating ", 
                                                        1);
                                        arrSplitLabel.add(sSplitField5Label);
                                        arrSplitId.add(sDetailFieldId);
                                    }

                                }

                                if ((sSplitField6Label != null) && 
                                    (!"".equals(sSplitField6Label))) {
                                    if (sLabel.equals(sSplitField6Label)) {
                                        myAppsLog.write("ODEBillAMImpl:Label6:", 
                                                        "***XXOD:sLabel" + 
                                                        sLabel + 
                                                        " add to arrlist for updating ", 
                                                        1);
                                        arrSplitLabel.add(sSplitField6Label);
                                        arrSplitId.add(sDetailFieldId);
                                    }


                                }
                                //updSplitRow(arrSplitLabel, arrSplitId);


                                //End - For adding / updating configuration details split row                  

                            }
                        }

                    }
                }

                //If any labels not updated to be added

                if ((sSplitField1Label != null) && 
                    (!"".equals(sSplitField1Label)) && 
                    (!arrSplitLabel.contains(sSplitField1Label))) {
                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField1Label" + 
                                    sSplitField1Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField1Label, arrSplitList);
                }

                if ((sSplitField2Label != null) && 
                    (!"".equals(sSplitField2Label)) && 
                    (!arrSplitLabel.contains(sSplitField2Label))) {
                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField2Label" + 
                                    sSplitField2Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField2Label, arrSplitList);
                }

                if ((sSplitField3Label != null) && 
                    (!"".equals(sSplitField3Label)) && 
                    (!arrSplitLabel.contains(sSplitField3Label))) {
                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField3Label" + 
                                    sSplitField3Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField3Label, arrSplitList);
                }

                if ((sSplitField4Label != null) && 
                    (!"".equals(sSplitField4Label)) && 
                    (!arrSplitLabel.contains(sSplitField4Label))) {
                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField4Label" + 
                                    sSplitField4Label + " adding as new row", 
                                    1);

                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField4Label, arrSplitList);
                }

                if ((sSplitField5Label != null) && 
                    (!"".equals(sSplitField5Label)) && 
                    (!arrSplitLabel.contains(sSplitField5Label))) {

                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField5Label" + 
                                    sSplitField5Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField5Label, arrSplitList);
                }

                if ((sSplitField6Label != null) && 
                    (!"".equals(sSplitField6Label)) && 
                    (!arrSplitLabel.contains(sSplitField6Label))) {

                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField6Label" + 
                                    sSplitField6Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField6Label, arrSplitList);
                }
            }

            //For New Split Field Id - Logic for adding rows into Configuration Details    
            if ("N".equals(sFlag)) {

                myAppsLog.write("ODEBillAMImpl", 
                                "***XXOD:sSplitField ID not existing", 1);


                if ((sSplitField1Label != null) && 
                    (!"".equals(sSplitField1Label))) {
                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField1Label" + 
                                    sSplitField1Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField1Label, arrSplitList);
                }

                if ((sSplitField2Label != null) && 
                    (!"".equals(sSplitField2Label))) {
                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField2Label" + 
                                    sSplitField2Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField2Label, arrSplitList);
                }

                if ((sSplitField3Label != null) && 
                    (!"".equals(sSplitField3Label))) {
                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField3Label" + 
                                    sSplitField3Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField3Label, arrSplitList);
                }

                if ((sSplitField4Label != null) && 
                    (!"".equals(sSplitField4Label))) {
                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField4Label" + 
                                    sSplitField4Label + " adding as new row", 
                                    1);

                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField4Label, arrSplitList);
                }

                if ((sSplitField5Label != null) && 
                    (!"".equals(sSplitField5Label))) {

                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField5Label" + 
                                    sSplitField5Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField5Label, arrSplitList);
                }

                if ((sSplitField6Label != null) && 
                    (!"".equals(sSplitField6Label))) {

                    myAppsLog.write("ODEBillAMImpl", 
                                    "***XXOD:sSplitField6Label" + 
                                    sSplitField6Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField6Label, arrSplitList);
                }
            }


        }


       
        myAppsLog.write("ODEBillAMImpl", "XXOD:End saveSplit ", 1);
    } // End saveSplit


    public void addSplitRow(OARow splitRow, String custDocId, 
                            String custAccountId, String sSplitFieldLabel, 
                            java.util.ArrayList arrSplitList) {

        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD: ****************addSplitRow", 1);
                        

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
       // int i = templDtlVO.getRowCount();
        
        

        templDtlVO.reset();
        while (templDtlVO.hasNext()) {

            OARow templRow = (OARow)templDtlVO.next();
            String sFieldId = "-1";
            if (templRow.getAttribute("FieldId") != null)
                sFieldId = templRow.getAttribute("FieldId").toString();

            if ((sFieldId.equals(splitRow.getAttribute("SplitBaseFieldId"))) && 
                ("Y".equals(templRow.getAttribute("Attribute20")))) {

                templRow.setAttribute("Attribute20", "N"); 
            }
        }

        templDtlVO.last();
        templDtlVO.next();
        OARow templRow = (OARow)templDtlVO.createRow();
        templRow.setAttribute("CustDocId", custDocId);
        templRow.setAttribute("RecordType", "000");
        templRow.setAttribute("EblTemplId", 
                              this.getOADBTransaction().getSequenceValue("XX_CDH_EBL_TEMPL_ID_S"));


        templRow.setAttribute("FieldId", 
                              this.getOADBTransaction().getSequenceValue("XX_CDH_EBL_SPLIT_FIELDS_S"));
                              
        
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:****new row splitfieldid"+splitRow.getAttribute("SplitFieldId"), 1);
                        
        templRow.setAttribute("SplitFieldId", 
                              splitRow.getAttribute("SplitFieldId"));
                              
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:****templ new row splitfieldid"+templRow.getAttribute("SplitFieldId"), 1);

        templRow.setAttribute("Label", sSplitFieldLabel);

        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:****new row splitbasefieldid"+splitRow.getAttribute("SplitBaseFieldId"), 1);
                        
        templRow.setAttribute("BaseFieldId", 
                              splitRow.getAttribute("SplitBaseFieldId"));
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:****after basefieldid splitfieldid"+templRow.getAttribute("SplitFieldId"), 1);
                        
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:****after basefieldid"+templRow.getAttribute("BaseFieldId"), 1);
                        

        templRow.setAttribute("Attribute2", "N");
        templRow.setAttribute("Attribute3", "N");
        templRow.setAttribute("Attribute20", "Y");

        //templRow.setAttribute("Seq", new Number((i++) * 40));
         myAppsLog.write("ODEBillAMImpl", 
                         "XXOD:****before getsequence splitfieldid"+templRow.getAttribute("SplitFieldId"), 1);
                         
        String sSeq = getSequence("SPLIT", custDocId, arrSplitList);
        
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:****after getsequence splitfieldid"+templRow.getAttribute("SplitFieldId"), 1);
        templRow.setAttribute("Seq", sSeq);

        templRow.setAttribute("Attribute1", "Y");
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:****before row splitfieldid"+templRow.getAttribute("SplitFieldId"), 1);
        
        templDtlVO.insertRow(templRow);

        templDtlVO.last();
   
        templDtlVO.next();
        
        
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD: End****************addSplitRow"+templDtlVO.getRowCount(), 1);

    }


    public String getSequence(String sConfigType, String sCustDocId, 
                              java.util.ArrayList arrList) {

        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD: getSequence:" + sConfigType + ":sCustDocId:" + 
                        sCustDocId, 1);

        StringBuffer sSeqNum = new StringBuffer();

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
        int nSeqMax = 0;


        if ("CONCAT".equals(sConfigType)) {

            Iterator itList = arrList.iterator();
            while (itList.hasNext()) {

                String sConcField = (String)itList.next();

                myAppsLog.write("ODEBillAMImpl", 
                                "XXOD: sConcField" + sConcField, 1);

                RowSetIterator rsi = 
                    templDtlVO.createRowSetIterator("rowsRSI");
                rsi.reset();

                while (rsi.hasNext()) {
                    Row templDtlRow = rsi.next();
                    String sTemplFieldId = 
                        templDtlRow.getAttribute("FieldId").toString();

                    if (sConcField.equals(sTemplFieldId)) {
                        if (nSeqMax == 0)
                            nSeqMax = 
                                    Integer.parseInt(templDtlRow.getAttribute("Seq").toString());
                        else {
                            if (nSeqMax < 
                                Integer.parseInt(templDtlRow.getAttribute("Seq").toString()))
                                nSeqMax = 
                                        Integer.parseInt(templDtlRow.getAttribute("Seq").toString());
                        }
                        break;

                    }
                }

            }


        } else {
            Iterator itList = arrList.iterator();


            while (itList.hasNext()) {
                String sSplitField = null;
                sSplitField = (String)itList.next();
                myAppsLog.write("ODEBillAMImpl", 
                                "XXOD: sSplitField:" + sSplitField, 1);
                
                
                templDtlVO.reset();
                while (templDtlVO.hasNext()) {
                    OARow templDtlRow = (OARow)templDtlVO.next();
                    
                    String sFieldId = "-1";
                    if (templDtlRow.getAttribute("FieldId") != null)
                        sFieldId = 
                                templDtlRow.getAttribute("FieldId").toString();

                    String sTemplFieldId = "-1";
                    if (templDtlRow.getAttribute("SplitFieldId") != null)
                        sTemplFieldId = 
                                templDtlRow.getAttribute("SplitFieldId").toString();

                   
                    String sBaseFieldId = "-1";
                    if (templDtlRow.getAttribute("BaseFieldId") != null)
                        sBaseFieldId = 
                                templDtlRow.getAttribute("BaseFieldId").toString();


                    myAppsLog.write("ODEBillAMImpl", 
                                    "XXOD: " + sFieldId+"::"+sBaseFieldId+"::"+sTemplFieldId, 1);
                    myAppsLog.write("ODEBillAMImpl", 
                                    "XXOD:****templ new row splitfieldid"+templDtlRow.getAttribute("SplitFieldId"), 1);

                    if (sSplitField.equals(sTemplFieldId)) {
                        myAppsLog.write("ODEBillAMImpl", 
                                        "XXOD: sSplitField matches" + 
                                        templDtlRow.getAttribute("Seq").toString(), 
                                        1);
                        if (nSeqMax < 
                            Integer.parseInt(templDtlRow.getAttribute("Seq").toString())) {
                            nSeqMax = 
                                    Integer.parseInt(templDtlRow.getAttribute("Seq").toString());
                        }


                    }
                }
                templDtlVO.reset();

            }
        }


        myAppsLog.write("ODEBillAMImpl", "XXOD: getSequence:sSeqMax" + nSeqMax, 
                        1);

        if (nSeqMax == 0) {
            if ("CONCAT".equals(sConfigType))
                sSeqNum.append(4000);
            else
                sSeqNum.append(5000);
        } else {
            if ("CONCAT".equals(sConfigType))
                sSeqNum.append(nSeqMax + 10);
            else
                sSeqNum.append(nSeqMax + 10);

        }


        myAppsLog.write("ODEBillAMImpl", "XXOD: getSequence:sSeqNum" + sSeqNum, 
                        1);

        return sSeqNum.toString();
    }

    private String chkIfExistsInTemplDtlVO(OAViewObject templDtlVO, 
                                           String sFieldId, 
                                           String sSplitType) {
        String sFlag = "N";


        RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
        rsi.reset();


        if ("CONCAT".equals(sSplitType)) {

            while (rsi.hasNext()) {
                Row templDtlRow = rsi.next();
                String sTemplFieldId = 
                    templDtlRow.getAttribute("FieldId").toString();

                if (sFieldId.equals(sTemplFieldId)) {
                    sFlag = "Y";
                    break;

                }
            }
        } else {
            while (rsi.hasNext()) {
                Row templDtlRow = rsi.next();
                String sTemplFieldId = "-1";
                if (templDtlRow.getAttribute("SplitFieldId") != null)
                    sTemplFieldId = 
                            templDtlRow.getAttribute("SplitFieldId").toString();

                if (sFieldId.equals(sTemplFieldId)) {
                    sFlag = "Y";
                    break;

                }
            }
        }


        return sFlag;

    }

    public void handleConcFieldsLOVUpdPPR() {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start handleConcFieldsLOVUpdPPR", 1);


        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
        RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");


        StringBuilder sFieldId = new StringBuilder();
        rsi.reset();

        while (rsi.hasNext()) {
            Row templRow = rsi.next();

            String sConcat = null;
            String sSelect = null;
            if (templRow.getAttribute("Concatenate") != null)
                sConcat = templRow.getAttribute("Concatenate").toString();

            if (templRow.getAttribute("Attribute1") != null)
                sSelect = templRow.getAttribute("Attribute1").toString();

            if (("Y".equals(sSelect)) && ("Y".equals(sConcat)))
                if (sFieldId == null || sFieldId.toString().equals(""))
                    sFieldId.append(templRow.getAttribute("FieldId").toString());
                else {
                    sFieldId.append(",");
                    sFieldId.append(templRow.getAttribute("FieldId").toString());
                }
        }


        OAViewObject dynamicConcFieldsVO = 
            (OAViewObject)this.findViewObject("ODEBillDynConcFieldsVO");

        if (dynamicConcFieldsVO != null) {
            dynamicConcFieldsVO.setWhereClause(" 1 = 2 ");

            if (!sFieldId.toString().equals(""))
                dynamicConcFieldsVO.setWhereClause(" CODE in (" + sFieldId + 
                                                   ")");

            dynamicConcFieldsVO.setMaxFetchSize(-1);
            dynamicConcFieldsVO.executeQuery();
        }


        myAppsLog.write("ODEBillAMImpl", "XXOD:sFieldId" + sFieldId, 1);


    }


    public void handleSplitFieldsLOVUpdPPR() {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start handleSplitFieldsLOVUpdPPR", 1);


        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");

        RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");

        StringBuilder sFieldId = new StringBuilder();
        rsi.reset();

        while (rsi.hasNext()) {
            Row templRow = rsi.next();

            String sSplit = null;
            String sSelect = null;
            if (templRow.getAttribute("Split") != null)
                sSplit = templRow.getAttribute("Split").toString();

            if (templRow.getAttribute("Attribute1") != null)
                sSelect = templRow.getAttribute("Attribute1").toString();


            if (("Y".equals(sSelect)) && ("Y".equals(sSplit)))
                if (sFieldId == null || sFieldId.toString().equals(""))
                    sFieldId.append(templRow.getAttribute("FieldId").toString());
                else {
                    sFieldId.append(",");
                    sFieldId.append(templRow.getAttribute("FieldId").toString());
                }
        }


        OAViewObject dynamicSplitFieldsVO = 
            (OAViewObject)this.findViewObject("ODEBillDynSplitFieldsVO");

        if (dynamicSplitFieldsVO != null) {
            dynamicSplitFieldsVO.setWhereClause(" 1 = 2 ");

            if (!sFieldId.toString().equals(""))
                dynamicSplitFieldsVO.setWhereClause(" CODE in (" + sFieldId + 
                                                    ")");

            dynamicSplitFieldsVO.setMaxFetchSize(-1);
            dynamicSplitFieldsVO.executeQuery();
        }


        myAppsLog.write("ODEBillAMImpl", "XXOD:sFieldId" + sFieldId, 1);


    }

    public void handleSubTotalLOVUpdPPR() {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", "XXOD:Start handleSubTotalLOVUpdPPR", 
                        1);
        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");

        RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");

        StringBuilder sFieldId = new StringBuilder();
        String sCustDocId = "";

        rsi.reset();

        while (rsi.hasNext()) {
            Row templRow = rsi.next();
            sCustDocId = templRow.getAttribute("CustDocId").toString();

            String sConcat = null;
            String sSelect = null;
            String sSplit = null;

            if (templRow.getAttribute("Concatenate") != null)
                sConcat = templRow.getAttribute("Concatenate").toString();

            if (templRow.getAttribute("Split") != null)
                sSplit = templRow.getAttribute("Split").toString();

            if (templRow.getAttribute("Attribute1") != null)
                sSelect = templRow.getAttribute("Attribute1").toString();

            if (("Y".equals(sSelect)) && ("Y".equals(sConcat)))
                if (sFieldId == null || sFieldId.toString().equals(""))
                    sFieldId.append(templRow.getAttribute("FieldId").toString());
                else {
                    sFieldId.append(",");
                    sFieldId.append(templRow.getAttribute("FieldId").toString());
                }

            if (("Y".equals(sSelect)) && ("Y".equals(sSplit)))
                if (sFieldId == null || sFieldId.toString().equals(""))
                    sFieldId.append(templRow.getAttribute("FieldId").toString());
                else {
                    sFieldId.append(",");
                    sFieldId.append(templRow.getAttribute("FieldId").toString());
                }


        }


        myAppsLog.write("ODEBillAMImpl", "XXOD:sCustDocId" + sCustDocId, 1);

        OAViewObject subTotalFieldsVO = 
            (OAViewObject)this.findViewObject("ODEBillSubTotalFieldsVO");

        if (!sFieldId.toString().equals("")) {
            subTotalFieldsVO.setWhereClause(null);
            subTotalFieldsVO.setWhereClause(" (cust_doc_id is null or cust_doc_id = " + 
                                            sCustDocId + 
                                            ") AND field_id not in (" + 
                                            sFieldId + ")");
        }

        subTotalFieldsVO.setMaxFetchSize(-1);
        subTotalFieldsVO.executeQuery();

        OAViewObject aggrFieldPVO = 
            (OAViewObject)this.findViewObject("ODEBillAggrFieldPVO");

        if (!sFieldId.toString().equals("")) {
            aggrFieldPVO.setWhereClause(null);
            aggrFieldPVO.setWhereClause(" (cust_doc_id is null or cust_doc_id = " + 
                                        sCustDocId + 
                                        ") AND field_id not in (" + sFieldId + 
                                        ")");
        }

        aggrFieldPVO.setMaxFetchSize(-1);
        aggrFieldPVO.executeQuery();


        myAppsLog.write("ODEBillAMImpl", "XXOD:sFieldId" + sFieldId, 1);


    }
    /* Used for saving Concatenate */

    /**Container's getter for ODEBillTemplDtlVO
     */
    public OAViewObjectImpl getODEBillTemplDtlVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillTemplDtlVO");
    }

    /**Container's getter for ODEBillMainVO
     */
    public OAViewObjectImpl getODEBillMainVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillMainVO");
    }


    /**Container's getter for ODEBillDataXlsFmtPVO
     */
    public OAViewObjectImpl getODEBillDataXlsFmtPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillDataXlsFmtPVO");
    }

    /**Container's getter for ODEBillEXLSwitcherVO
     */
    public ODEBillEXLSwitcherVOImpl getODEBillEXLSwitcherVO() {
        return (ODEBillEXLSwitcherVOImpl)findViewObject("ODEBillEXLSwitcherVO");
    }

    //The below code by Reddy Sekhar K on 27th Jul 2017 for the defect #42321
        public void  dataFormatMethod()
        {
        OAViewObject tempDtlVO= (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");
    
             RowSetIterator templDtlVOrsi =
             tempDtlVO.createRowSetIterator("rowsRSI");
             OAViewObject switcherXLVO= (OAViewObject)this.findViewObject("ODEBillEXLSwitcherVO");
             switcherXLVO.clearCache();
             switcherXLVO.executeQuery();
             RowSetIterator swithceriter = switcherXLVO.createRowSetIterator("rowsRSII");
             templDtlVOrsi.reset();
             while (templDtlVOrsi.hasNext()) {
                 Row templDtlVORow = templDtlVOrsi.next();
                 swithceriter.reset();
                 while (swithceriter.hasNext()) {
                     Row switcherXLVORow = swithceriter.next();
                     if (templDtlVORow.getAttribute("Label").equals(switcherXLVORow.getAttribute("Meaning")))
                     {
                         templDtlVORow.setAttribute("Xlslabelmethod","switch1");
                                         }
    
    
             }
             }
        }
    //The code completed by Reddy Sekhar K on 27th Jul 2017 for the defect #42321

 //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - START
      public void handleSelectOnSummaryCehck() {
                    
          OAViewObject templDtlVO = 
              (OAViewObject)this.findViewObject("ODEBillTemplDtlVO");     
          RowSetIterator templDtlVOrsi =
          templDtlVO.createRowSetIterator("rowsRSI");
          
          while (templDtlVOrsi.hasNext()) {
              Row templDtlVORow = templDtlVOrsi.next();                  
              templDtlVORow.setAttribute("Attribute1","N");                         
          }
         templDtlVO.closeRowSetIterator();
     }
     //Code added by Rafi on 04-Dec-2017 for wave3 Defect#NAIT-21725 - END 
     
      //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start 
     public void parentDocIdDisabled() 
     {
         
          OAViewObject parentDocDis=(OAViewObject)this.findViewObject("ODEBillPPRVO");
                  OARow firstRowProcess1=(OARow)parentDocDis.first();
                   OAViewObject payDocVO = (OAViewObject)this.findViewObject("ODEBillPayDocVO"); 
                             int payDocVOCount=payDocVO.getRowCount();
                                if(payDocVOCount>=1)
                                {
                                firstRowProcess1.setAttribute("parentDocIDDisabled",Boolean.TRUE); 
                                }
                               else{
                               OAViewObject infoDocVO = (OAViewObject)this.findViewObject("ODEBillDocExceptionVO"); 
                                      int infoDocVOCount=infoDocVO.getRowCount();
                                      if(infoDocVOCount>=1) {
                                           firstRowProcess1.setAttribute("parentDocIDDisabled", Boolean.TRUE); 
                                      }
                                       }
     }
    //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End
    
     //Code added by Rafi for NAIT-91481 Rectify Billing Delivery Efficiency - START
     public String getBCFlag(String CustAccountId)
     {
        ODUtil utl = new ODUtil(this);
        utl.log("execQuery :Begin execQuery");
        String atribute6QryPF1 = "SELECT Attribute6 FROM hz_customer_profiles "
        + " WHERE CUST_ACCOUNT_ID = " +CustAccountId 
         +" AND site_use_id is null";
        OracleCallableStatement ocs=null;
        ResultSet rs=null;
        OADBTransaction db=this.getOADBTransaction();
        String stmt = atribute6QryPF1;
        String rattr6PF=null;
        //utl.log("execQuery:"+ stmt);
        ocs = (OracleCallableStatement)db.createCallableStatement(stmt,1);

        try
        {
          rs = ocs.executeQuery();
          if (rs.next())
          {
            rattr6PF = rs.getString(1);
          }
          rs.close();
          ocs.close();
        }
        catch(SQLException e)
        {
          utl.log("execQuery:Error:"+ e.toString());
        }
            finally
          {
             try{
                  if(rs != null)
                     rs.close();
                  if(ocs != null)
                     ocs.close();
                }
                     catch(Exception e){}
          }
        utl.log("execQuery :End execQuery");
        return rattr6PF;
     }
    //Code added by Rafi for NAIT-91481 Rectify Billing Delivery Efficiency - END
    /**Container's getter for ODEBillParentCustDocId
     */
    public OAViewObjectImpl getODEBillParentCustDocId() {
        return (OAViewObjectImpl)findViewObject("ODEBillParentCustDocId");
    }

    /**Container's getter for ODEBillPPRVO
     */
    public OAViewObjectImpl getODEBillPPRVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillPPRVO");
    }

    /**Container's getter for ODEBillDocExceptionVO
     */
    public OAViewObjectImpl getODEBillDocExceptionVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillDocExceptionVO");
    }

    /**Container's getter for ODEBillPayDocVO
     */
    public OAViewObjectImpl getODEBillPayDocVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillPayDocVO");
    }
} // End class ODEBillAMImpl
