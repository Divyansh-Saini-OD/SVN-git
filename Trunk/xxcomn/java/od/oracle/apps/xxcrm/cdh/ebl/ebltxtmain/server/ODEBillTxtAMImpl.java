package od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.server;

import com.sun.java.util.collections.ArrayList;

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import java.text.ParseException;
import java.text.SimpleDateFormat;

import java.util.Calendar;

import od.oracle.apps.xxcrm.cdh.ebl.custdocs.server.ODEbillCustDocVOImpl;
import od.oracle.apps.xxcrm.cdh.ebl.custdocs.server.ODEbillCustDocVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillContactsVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.eblmain.server.ODEBillFileNameVORowImpl;
import od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.poplist.server.ODEBillConfigDetailsFieldNamesSumPVOImpl;
import od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.poplist.server.ODEBillDynSplitFieldsVOImpl;
//import od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.poplist.server.ODEBillSignIndiPVOImpl;
import od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.poplist.server.ODEbillNonDtlQuantityPVOImpl;
import od.oracle.apps.xxcrm.cdh.ebl.poplist.server.ODEBillCharYesNoImpl;
import od.oracle.apps.xxcrm.cdh.ebl.poplist.server.ODEBillComboPVOImpl;

import od.oracle.apps.xxcrm.cdh.ebl.poplist.server.ODEBillDelyMethodPVOImpl;
import od.oracle.apps.xxcrm.cdh.ebl.poplist.server.ODEBillDocTypePVOImpl;
import od.oracle.apps.xxcrm.cdh.ebl.poplist.server.ODEBillNumYesNoPVOImpl;

import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;
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
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

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
  -- +===========================================================================+
  -- | Name        :  ODEBillTxtAMImpl                                              |
  -- | Description :                                                             |
  -- | This is the Application Module Class for eBill Main Page                  |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author             Remarks                            |
  -- |======== =========== ================   ================================   |
  -- |1.0     1-Mar-2016  Sridevi Kondoju      Initial version                   |
  -- |1.1     21-SEP-2016 Vasu Raparla         Changes for Defect#39436          |
  -- |1.2     3-MAR-2017  Bhagwan Rao          Changes for Defect#38962,2302 and 39524 |
  -- |1.3     15-Jul-2017 Bhagwan Rao          Changes for Defect#40174          |
  -- |1.4     27-Jul-2017 Reddy Sekhar K       Code Added for #Defect 41307      |
  -- |1.5     21-Nov-2017 Reddy Sekhar K       Code Added for #Defect NAIT-22625 |
  -- |1.6     27-Jul-2017 Rafi Mohammed        Code added for #Defect NAIT-22703 |
  -- |1.7     27-Jul-2017 Rafi Mohammed        Code added for #Defect NAIT-27591 | 
  -- |1.8     08 Oct 2017 Reddy Sekhar K       Code added for #Defect #40174     |
  -- |1.9     09-May-2018 Reddy Sekhar K       Code Added for Defect# NAIT-29364 |
  -- |1.10    13-Jul-2018 Reddy Sekhar K       Code Added for Defect# NAIT-45279 |
  -- |1.11    25-Jul-2018 Reddy Sekhar K       Code Added for Defect# NAIT-52049 |
  -- |===========================================================================|
  -- | Subversion Info:                                                          |
  -- | $HeadURL: $                                                               |
  -- | $Rev:  $                                                                  |
  -- | $Date: $                                                                  |
  -- |                                                                           |
  -- +===========================================================================+
*/


//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODEBillTxtAMImpl extends OAApplicationModuleImpl {
    /**
     *
     * This is the default constructor (do not remove)
     */
    public ODEBillTxtAMImpl() {
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
        myAppsLog.write("ODEBillTxtAMImpl", "XXOD: initializeMain", 1);

        String newFlag = "FALSE";

        OAViewObject mainVO = 
            (OAViewObject)this.findViewObject("ODEBillMainVO");
        OAViewObject transVO = 
            (OAViewObject)this.findViewObject("ODEBillTransmissionVO");
        OAViewObject contactVO = 
            (OAViewObject)this.findViewObject("ODEBillContactsVO");
        OAViewObject fileParamVO = 
            (OAViewObject)this.findViewObject("ODEBillFileNameVO");

        OAViewObject concatenateHdrVO = null;
        OAViewObject concatenateDtlVO = null;
        OAViewObject concatenateTrlVO = null;

        OAViewObject configDetailsFieldNamesPVO = null;
        OAViewObject configDetailsFieldNamesSumPVO = null;
        OAViewObject configHdrFieldNamesPVO = null;
        OAViewObject configTrlFieldNamesPVO = null;

        mainVO.setWhereClause(null);
        mainVO.setWhereClause("cust_doc_id = " + custDocId);
        mainVO.executeQuery();

        transVO.setWhereClause(null);
        transVO.setWhereClause("cust_doc_id = " + custDocId);
        transVO.executeQuery();

        contactVO.setWhereClause(null);
        contactVO.setWhereClause("cust_doc_id = " + custDocId);
        contactVO.executeQuery();

        deleteEnableDisable();

        fileParamVO.setWhereClause(null);
        fileParamVO.setWhereClause("cust_doc_id = " + custDocId);
        fileParamVO.executeQuery();
         

        if (fileParamVO.getRowCount() == 0) {

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
            mainRow.setAttribute("FileNameExt", "TXT");
            mainRow.setAttribute("SummaryBill","N");
            mainVO.insertRow(mainRow);
            mainRow.setNewRowState(mainRow.STATUS_INITIALIZED);
            myAppsLog.write("ODEBillTxtAMImpl", "XXOD: New Record", 1);
            newFlag = "TRUE";
        } 
        /*
         else {
            OARow mainRow = (OARow)mainVO.first();
            if (mainRow != null)
                mainRow.setAttribute("FileNameExt", "TXT");
        }*/


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


        concatenateHdrVO = 
                (OAViewObject)this.findViewObject("ODEBillConcatenateHdrVO");
        concatenateHdrVO.setWhereClauseParams(null);
        concatenateHdrVO.setWhereClauseParam(0, custDocId);
        concatenateHdrVO.setMaxFetchSize(-1);
        concatenateHdrVO.executeQuery();


        concatenateDtlVO = 
                (OAViewObject)this.findViewObject("ODEBillConcatenateDtlVO");
        concatenateDtlVO.setWhereClauseParams(null);
        concatenateDtlVO.setWhereClauseParam(0, custDocId);
        concatenateDtlVO.setMaxFetchSize(-1);
        concatenateDtlVO.executeQuery();

        concatenateTrlVO = 
                (OAViewObject)this.findViewObject("ODEBillConcatenateTrlVO");
        concatenateTrlVO.setWhereClauseParams(null);
        concatenateTrlVO.setWhereClauseParam(0, custDocId);
        concatenateTrlVO.setMaxFetchSize(-1);
        concatenateTrlVO.executeQuery();

        OAViewObject splitVO = 
            (OAViewObject)this.findViewObject("ODEBillSplitVO");

        splitVO.setWhereClause(null);
        splitVO.setWhereClause(" cust_doc_id = " + custDocId);

        splitVO.executeQuery();

        splitVO.reset();

        while (splitVO.hasNext()) {

            OARow splitRow = (OARow)splitVO.next();

            String sSplit = "";
            sSplit = (String)splitRow.getAttribute("SplitType");

            if (("FP".equalsIgnoreCase(sSplit)) || 
                ("FL".equalsIgnoreCase(sSplit))) {
                splitRow.setAttribute("EnableFixedPosition", Boolean.FALSE);
                splitRow.setAttribute("EnableDelimiter", Boolean.TRUE);
            } else {
                splitRow.setAttribute("EnableFixedPosition", Boolean.TRUE);
                splitRow.setAttribute("EnableDelimiter", Boolean.FALSE);
            }

        }
        splitVO.reset();
        initTemplHdr(custDocId);
        initTemplTrl(custDocId);
        initTemplDtl(custDocId);

        ODEBillDynSplitFieldsVOImpl objVO = this.getODEBillDynSplitFieldsVO();
        objVO.initQuery(custDocId);


        //Used in configuration details tab for field name
        configDetailsFieldNamesPVO = 
                (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesPVO");
        configDetailsFieldNamesPVO.setWhereClause(null);
        configDetailsFieldNamesPVO.setWhereClause(" cust_doc_id is null or cust_doc_id = " + 
                                                  custDocId);
        configDetailsFieldNamesPVO.executeQuery();
        
        
        //Added by Bhagwan Rao 7 Jun 2017 for configuration summary details tab for field name
         configDetailsFieldNamesSumPVO = 
                 (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
         configDetailsFieldNamesSumPVO.setWhereClause(null);
         configDetailsFieldNamesSumPVO.setWhereClause(" cust_doc_id is null or cust_doc_id = " + 
                                                   custDocId);
         configDetailsFieldNamesSumPVO.executeQuery();

        configHdrFieldNamesPVO = 
                (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
        configHdrFieldNamesPVO.setWhereClause(null);
        configHdrFieldNamesPVO.setWhereClause(" cust_doc_id is null or cust_doc_id = " + 
                                              custDocId);
        configHdrFieldNamesPVO.executeQuery();


        configTrlFieldNamesPVO = 
                (OAViewObject)this.findViewObject("ODEBillConfigTrlFieldNamesPVO");
        configTrlFieldNamesPVO.setWhereClause(null);
        configTrlFieldNamesPVO.setWhereClause(" cust_doc_id is null or cust_doc_id = " + 
                                              custDocId);
        configTrlFieldNamesPVO.executeQuery();

        return newFlag;
    } //End of initializeMain()
    
    



    public void initTemplHdr(String custDocId) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", "XXOD: Inside initTemplHdr", 1);

        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();


        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        OAViewObject templHdrVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");

        templHdrVO.setWhereClause(null);
        templHdrVO.setWhereClause("cust_doc_id = " + custDocId);
        templHdrVO.setSortBy("Seq");//Added by Reddy Sekhar for #Defect NAIT-22625 0n 21 Nov 2017
        templHdrVO.executeQuery();


        if (templHdrVO.getRowCount() == 0) {
            myAppsLog.write("ODEBillTxtAMImpl", 
                            "XXOD: Inside initTemplHdr getRowCount 0", 1);
        } else {

            myAppsLog.write("ODEBillTxtAMImpl", 
                            "XXOD: Inside initTemplHdr getRowCount not 0", 1);


            OARow templHdrVOfirst = (OARow)templHdrVO.first();


            cmnVORow.setAttribute("IncludeLabelHdr", 
                                  templHdrVOfirst.getAttribute("IncludeLabel"));
                                  
//            //Added by Bhagwan Rao on 7 Jul 2017 for Defect #40174
             cmnVORow.setAttribute("AbsoluteValueHdrFlag", 
                                   templHdrVOfirst.getAttribute("AbsoluteFlag"));
                        String attr18=   (String)templHdrVOfirst.getAttribute("AbsoluteFlag");        

            cmnVORow.setAttribute("DebitCreditHdrFlag", 
                                  templHdrVOfirst.getAttribute("DcIndicator"));
                       String attr10=   (String)templHdrVOfirst.getAttribute("DcIndicator"); 
            
            //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----Start
            cmnVORow.setAttribute("DebCreTransientHdr", 
                                  templHdrVOfirst.getAttribute("DbCrSeperator"));
            //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----END
                                                      
            


        }


        RowSetIterator templHdrVOrsi = 
            templHdrVO.createRowSetIterator("rowsRSI");

        OAViewObject fieldsVO = 
            (OAViewObject)this.getODEBillConfigHdrFieldNamesPVO();
        RowSetIterator rsi = fieldsVO.createRowSetIterator("rowsRSI");


        templHdrVOrsi.reset();
        while (templHdrVOrsi.hasNext()) {
            Row templHdrVORow = templHdrVOrsi.next();


            rsi.reset();
            while (rsi.hasNext()) {
                Row fieldsVORow = rsi.next();


                if (templHdrVORow.getAttribute("FieldId").equals(fieldsVORow.getAttribute("FieldId"))) {

                    if ((Boolean)fieldsVORow.getAttribute("TranslationField"))
                        templHdrVORow.setAttribute("TranslationField", "Y1");
                    else
                        templHdrVORow.setAttribute("TranslationField", "N1");


                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "XXOD: fieldname:" + templHdrVORow.getAttribute("FieldId") + 
                                    ":::" + 
                                    templHdrVORow.getAttribute("IsConcatOrSplit").toString(), 
                                    1);

                }


                String sFieldIdSeq = "";
                sFieldIdSeq = 
                        templHdrVORow.getAttribute("FieldId").toString() + 
                        templHdrVORow.getAttribute("Seq");

                Boolean flag = validateConcatSplit(sFieldIdSeq, "HDR");

                if (!flag) {
                    templHdrVORow.setAttribute("IsUsedInConcatOrSplit", 
                                               Boolean.TRUE);
                    templHdrVORow.setAttribute("TranslationField", "N1");
                }


            }

            if (!((Boolean)PPRRow.getAttribute("Complete"))) {
                myAppsLog.write("ODEBillTxtAMImpl", 
                                "XXOD: Bill doc status not complete", 1);

            } else {
                myAppsLog.write("ODEBillTxtAMImpl", 
                                "XXOD: Bill doc status complete", 1);
                //templHdrVORow.setAttribute("TranslationField", "Y1");
                templHdrVORow.setAttribute("IsConcatOrSplit", Boolean.TRUE);
                templHdrVORow.setAttribute("IsUsedInConcatOrSplit", 
                                           Boolean.TRUE);
            }
        }


    }

    public void initTemplDtl(String custDocId) {
    
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", "XXOD: Inside initTemplDtl", 1);

        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();

        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
            
           
        //Added by Bhagwan 25 March 2017 
        OAViewObject FNPPRVO = (OAViewObject)this.getODEBillTemplDtlTxtFNPPRVO();
        OARow FNPPRROW = (OARow)FNPPRVO.first();
        
        OAViewObject ebillmainVO = 
                                       (OAViewObject)this.findViewObject("ODEBillMainVO");
                                    
                                       
        OARow mainrow = 
                             (OARow)ebillmainVO.first();                            
          
                             
        String sSummaryBill = (String)mainrow.getAttribute("SummaryBill");                              
       
       if("N".equals(sSummaryBill)) {
           handleTemplDtlTxtFNPPR();
       }                   
                                       

        templDtlVO.setWhereClause(null);
        templDtlVO.setWhereClause("cust_doc_id = " + custDocId);
        templDtlVO.setSortBy("Seq");//Added by Reddy Sekhar for #Defect NAIT-22625 0n 21 Nov 2017
        templDtlVO.executeQuery();


        if (templDtlVO.getRowCount() == 0) {
            myAppsLog.write("ODEBillTxtAMImpl", 
                            "XXOD: Inside initTemplDtl getRowCount 0", 1);
            
                            
        } else {

            myAppsLog.write("ODEBillTxtAMImpl", 
                            "XXOD: Inside initTemplDtl getRowCount not 0", 1);
                            
                        


            OARow templDtlVOfirst = (OARow)templDtlVO.first();

            cmnVORow.setAttribute("IncludeHdrLabelDtl", 
                                  templDtlVOfirst.getAttribute("IncludeHeader"));
            
            //Added by Bhagwan 25 March 2016
                          
            cmnVORow.setAttribute("RepeatTotalHdrLabelDtl", 
                                  templDtlVOfirst.getAttribute("RepeatTotalFlag"));
            
            cmnVORow.setAttribute("TaxUPFlag", 
                                   templDtlVOfirst.getAttribute("TaxUpFlag"));
                                  
            cmnVORow.setAttribute("FreightUPFlag", 
                                  templDtlVOfirst.getAttribute("FreightUpFlag"));
                                  
            cmnVORow.setAttribute("MiscUPFlag", 
                                  templDtlVOfirst.getAttribute("MiscUpFlag"));                  
                                  
            cmnVORow.setAttribute("TaxEPFlag", 
                                  templDtlVOfirst.getAttribute("TaxEpFlag"));  
            
            cmnVORow.setAttribute("FreightEPFlag", 
                                  templDtlVOfirst.getAttribute("FreightEpFlag"));
                                  
            cmnVORow.setAttribute("MiscEPFlag", 
                                  templDtlVOfirst.getAttribute("MiscEpFlag"));
            //Added by Bhagwan Rao on 7 Jul 2017 for Defect #40174
             cmnVORow.setAttribute("AbsoluteValueHdrFlag1", 
                                   templDtlVOfirst.getAttribute("AbsoluteFlag"));
			cmnVORow.setAttribute("DebitCreditDtlFlag", 
                                  templDtlVOfirst.getAttribute("DcIndicator"));
                       String attr10=   (String)templDtlVOfirst.getAttribute("DcIndicator");
                       
            //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----Start
            cmnVORow.setAttribute("DebCreTransient", 
                                  templDtlVOfirst.getAttribute("DbCrSeperator"));
            //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----END
    }

         

        RowSetIterator templDtlVOrsi = 
            templDtlVO.createRowSetIterator("rowsRSI");

        OAViewObject fieldsVO = 
            (OAViewObject)this.getODEBillConfigDetailsFieldNamesPVO();
        RowSetIterator rsi = fieldsVO.createRowSetIterator("rowsRSI");


        templDtlVOrsi.reset();
        while (templDtlVOrsi.hasNext()) {
            Row templDtlVORow = templDtlVOrsi.next();


            rsi.reset();
            while (rsi.hasNext()) {
                Row fieldsVORow = rsi.next();
                if (templDtlVORow.getAttribute("FieldId").equals(fieldsVORow.getAttribute("FieldId"))) {

                    if ((Boolean)fieldsVORow.getAttribute("TranslationField"))
                        templDtlVORow.setAttribute("TranslationField", "Y");
                    else
                        templDtlVORow.setAttribute("TranslationField", "N");

                }


                String sFieldIdSeq = "";
                sFieldIdSeq = 
                        templDtlVORow.getAttribute("FieldId").toString() + 
                        templDtlVORow.getAttribute("Seq");

                Boolean flag = validateConcatSplit(sFieldIdSeq, "DTL");

                if (!flag) {
                    templDtlVORow.setAttribute("IsUsedInConcatOrSplit", 
                                               Boolean.TRUE);
                    templDtlVORow.setAttribute("TranslationField", "N");
                }

            }

            if (!((Boolean)PPRRow.getAttribute("Complete"))) {
                myAppsLog.write("ODEBillTxtAMImpl", 
                                "XXOD: Bill doc status not complete", 1);
            } else {
                myAppsLog.write("ODEBillTxtAMImpl", 
                                "XXOD: Bill doc status complete", 1);
                templDtlVORow.setAttribute("IsConcatOrSplit", Boolean.TRUE);
                templDtlVORow.setAttribute("IsUsedInConcatOrSplit", 
                                           Boolean.TRUE);
            }
        }


    }


    public void initTemplTrl(String custDocId) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", "XXOD: Inside initTemplTrl", 1);

        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();

        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();


        OAViewObject templTrlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");

        templTrlVO.setWhereClause(null);
        templTrlVO.setWhereClause("cust_doc_id = " + custDocId);
        templTrlVO.setSortBy("Seq");//Added by Reddy Sekhar for #Defect NAIT-22625 0n 21 Nov 2017
        templTrlVO.executeQuery();


        if (templTrlVO.getRowCount() == 0) {
            myAppsLog.write("ODEBillTxtAMImpl", 
                            "XXOD: Inside initTemplTrl getRowCount 0", 1);
        } else {

            myAppsLog.write("ODEBillTxtAMImpl", 
                            "XXOD: Inside initTemplTrl getRowCount not 0", 1);


            OARow templTrlVOfirst = (OARow)templTrlVO.first();

            cmnVORow.setAttribute("IncludeLabelTrl", 
                                  templTrlVOfirst.getAttribute("IncludeLabel"));
            String s=(String)templTrlVOfirst.getAttribute("IncludeLabel");
            
                                  
            //Added by Bhagwan Rao on 7 Jul 2017 for Defect #40174
             cmnVORow.setAttribute("AbsoluteValueHdrFlag2", 
                                   templTrlVOfirst.getAttribute("AbsoluteFlag"));
            cmnVORow.setAttribute("DebitCreditTrlFlag", 
                      templTrlVOfirst.getAttribute("DcIndicator"));
            String attr10=   (String)templTrlVOfirst.getAttribute("DcIndicator");
                      
            
            String s1=(String)templTrlVOfirst.getAttribute("AbsoluteFlag");
            //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----Start
             cmnVORow.setAttribute("DebCreTransientTrl", 
                       templTrlVOfirst.getAttribute("DbCrSeperator"));
            //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----End
            

        }

        RowSetIterator templTrlVOrsi = 
            templTrlVO.createRowSetIterator("rowsRSI");

        OAViewObject fieldsVO = 
            (OAViewObject)this.getODEBillConfigTrlFieldNamesPVO();
        RowSetIterator rsi = fieldsVO.createRowSetIterator("rowsRSI");


        templTrlVOrsi.reset();
        while (templTrlVOrsi.hasNext()) {
            Row templTrlVORow = templTrlVOrsi.next();


            rsi.reset();
            while (rsi.hasNext()) {
                Row fieldsVORow = rsi.next();

                if (templTrlVORow.getAttribute("FieldId").equals(fieldsVORow.getAttribute("FieldId"))) {

                    if ((Boolean)fieldsVORow.getAttribute("TranslationField"))
                        templTrlVORow.setAttribute("TranslationField", "Y2");
                    else
                        templTrlVORow.setAttribute("TranslationField", "N2");


                }


                String sFieldIdSeq = "";
                sFieldIdSeq = 
                        templTrlVORow.getAttribute("FieldId").toString() + 
                        templTrlVORow.getAttribute("Seq");

                Boolean flag = validateConcatSplit(sFieldIdSeq, "TRL");

                if (!flag) {
                    templTrlVORow.setAttribute("IsUsedInConcatOrSplit", 
                                               Boolean.TRUE);
                    templTrlVORow.setAttribute("TranslationField", "N2");
                }


            }

            if (!((Boolean)PPRRow.getAttribute("Complete"))) {
                myAppsLog.write("ODEBillTxtAMImpl", 
                                "XXOD: Bill doc status not complete", 1);

            } else {
                myAppsLog.write("ODEBillTxtAMImpl", 
                                "XXOD: Bill doc status complete", 1);
                templTrlVORow.setAttribute("IsConcatOrSplit", Boolean.TRUE);
                //Added By Bhagwan Rao 19 Jun 2017 **Defect 42448**
                 templTrlVORow.setAttribute("IsUsedInConcatOrSplit", 
                                            Boolean.TRUE);
                templTrlVORow.setAttribute("TranslationField", "N2");
            }
        }


    }

    public void handleTrlLabelPPR(String sIncludeLabel) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleTrlLabelPPR" + sIncludeLabel, 1);


        OAViewObject templTrlTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");

        RowSetIterator rsi = templTrlTxtVO.createRowSetIterator("rowsRSI");

        // StringBuilder sFieldId = new StringBuilder();
        rsi.reset();

        while (rsi.hasNext()) {
            Row templRow = rsi.next();

            templRow.setAttribute("IncludeLabel", sIncludeLabel);

        }

        myAppsLog.write("ODEBillAMImpl", "XXOD:End handleTrlLabelPPR", 1);


    }


    public void handleHdrIncludeLabelPPR(String sIncludeLabel) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleHdrIncludeLabelPPR", 1);
        OAViewObject templHdrTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");

        RowSetIterator rsi = templHdrTxtVO.createRowSetIterator("rowsRSI");


        rsi.reset();

        while (rsi.hasNext()) {
            Row templRow = rsi.next();

            templRow.setAttribute("IncludeLabel", sIncludeLabel);

        }

        myAppsLog.write("ODEBillAMImpl", "XXOD:End handleHdrIncludeLabelPPR", 
                        1);


    }


    public void handleDtlIncludeLabelPPR(String sIncludeLabel) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleDtlIncludeLabelPPR", 1);
        OAViewObject templDtlTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");

        RowSetIterator rsi = templDtlTxtVO.createRowSetIterator("rowsRSI");


        rsi.reset();

        while (rsi.hasNext()) {
            Row templRow = rsi.next();

            templRow.setAttribute("IncludeHeader", sIncludeLabel);

        }

        myAppsLog.write("ODEBillAMImpl", "XXOD:End handleDtlIncludeLabelPPR", 
                        1);


    }

    //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----Start

 public void debitCreditSeparatorDetail(String dbValue) 
     {
             OAViewObject templDtlTxtVO = 
             (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
    RowSetIterator rowDtl = templDtlTxtVO.createRowSetIterator("rowsRSI");
    rowDtl.reset();
    while (rowDtl.hasNext()) {
             Row templRow = rowDtl.next();
             templRow.setAttribute("DbCrSeperator",dbValue);
                             }
     }
     
     public void debitCreditSeparatorHeader(String dbCrValue)
        {
          OAViewObject templHeaderlTxtVO = (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
           RowSetIterator rowHdr = templHeaderlTxtVO.createRowSetIterator("rowsRSIHdr");
            rowHdr.reset();
            while (rowHdr.hasNext()) {
                Row templHdrRow = rowHdr.next();
                templHdrRow.setAttribute("DbCrSeperator",dbCrValue);
                                     }
        }
        
     public void debitCreditSeparatorTrailer(String dbCrTrlValue) 
        {
        OAViewObject templTrailrTxtVO = (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");
        RowSetIterator rowTrl = templTrailrTxtVO.createRowSetIterator("rowsRSITrl");
        rowTrl.reset();
        while (rowTrl.hasNext()) {
                Row templTrlRow = rowTrl.next();
                templTrlRow.setAttribute("DbCrSeperator",dbCrTrlValue);
                                 }
        }
    ////Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----END

    public void handleDtlRepeatLabelPPR(String sRepeatLabel) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", "XXOD:Start  handleDtlRepeatLabelPPR", 
                        1);

        OAViewObject templDtlTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");

        RowSetIterator rsi = templDtlTxtVO.createRowSetIterator("rowsRSI");


        rsi.reset();

        while (rsi.hasNext()) {
            Row templRow = rsi.next();

            templRow.setAttribute("RepeatHeader", sRepeatLabel);

        }
        myAppsLog.write("ODEBillAMImpl", "XXOD:End handleDtlRepeatLabelPPR", 
                        1);


    }    
    
    
    //Added by Bhagwan 25 March 2017

    public void handleDtlRepeatTotalLabelPPR(String sRepeatTotalLabelDtl) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleDtlRepeatTotalLabelPPR", 1);

        OAViewObject templDtlTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
            

        RowSetIterator rsi = templDtlTxtVO.createRowSetIterator("rowsRSI");


        rsi.reset();

        while (rsi.hasNext()) {
            Row templRow = rsi.next();
            //RepeatHeader has to be changed with original attribute name
            templRow.setAttribute("RepeatTotalFlag",sRepeatTotalLabelDtl);

        }
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:End handleDtlRepeatTotalLabelPPR", 1);


    }
    
    //Added by Bhagwan Rao 7 Jul 2017 for Defect #40174
    public void handleDtlAbsoluteValueLabelPPR(String sAbsoluteValueLabelDtl, String custDocId ) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);

        OAViewObject templHdrTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
//		OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();                
//        OARow cmnVORow = (OARow)cmnVO.first();
            
 OAViewObject PPRVO = (OAViewObject)this.findViewObject("ODEBillPPRVO");
 OARow PPRRow = (OARow)PPRVO.first();
 
     if ((sAbsoluteValueLabelDtl == null) || ("N".equals(sAbsoluteValueLabelDtl))) {
         PPRRow.setAttribute("AbsoluteValueFlag", Boolean.TRUE);
         OAViewObject templConfigHdrAVFNPVO = 
             (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
         templConfigHdrAVFNPVO.setWhereClause(null);
         templConfigHdrAVFNPVO.setWhereClause("field_name != 'Account Number' and cust_doc_id is null ");
         templConfigHdrAVFNPVO.executeQuery();
         
         
         
         OAViewObject templConfigHdrAVFNPVO1 = 
             (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
         templConfigHdrAVFNPVO1.setWhereClause(null);
         templConfigHdrAVFNPVO1.setWhereClause("field_name != 'Account Number' and cust_doc_id is null ");
         templConfigHdrAVFNPVO1.executeQuery();
     }
     else {
         PPRRow.setAttribute("AbsoluteValueFlag", Boolean.FALSE);
         OAViewObject templConfigHdrAVFNPVO = 
             (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
         templConfigHdrAVFNPVO.setWhereClause(null);
         templConfigHdrAVFNPVO.setWhereClause("cust_doc_id is null ");                
         templConfigHdrAVFNPVO.executeQuery();
         
         OAViewObject templConfigHdrAVFNPVO1 = 
             (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
         templConfigHdrAVFNPVO1.setWhereClause(null);
         templConfigHdrAVFNPVO1.setWhereClause("field_name != 'Account Number' and cust_doc_id is null ");
         templConfigHdrAVFNPVO1.executeQuery();
         
     }
 

        RowSetIterator rsi = templHdrTxtVO.createRowSetIterator("rowsRSI");


        rsi.reset();
          
        while (rsi.hasNext()) {
            Row templRow = rsi.next();
            //RepeatHeader has to be changed with original attribute name
            templRow.setAttribute("Attribute18",sAbsoluteValueLabelDtl);
			//templRow.setAttribute("Attribute10",sDebitCreditHdrLabel);
//            cmnVORow.setAttribute("AbsoluteValueHdrFlag", 
//                                  templRow.getAttribute("Attribute18"));
                       
//            cmnVORow.setAttribute("DebitCreditHdrFlag",
//                                 templRow.getAttribute("Attribute10"));

        }
        
 


    }
   
    //Added by Bhagwan Rao 7 Jul 2017 for Defect #40174
        public void handleDtlAbsoluteValueLabelPPR1(String sAbsoluteValueLabelDtl, String custDocId, String sDebitCreditDtlLabel) {
         
            AppsLog myAppsLog = new AppsLog();
            myAppsLog.write("ODEBillAMImpl", 
                            "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);

            OAViewObject templDtlTxtVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
                
                    OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
            OARow cmnVORow = (OARow)cmnVO.first();

            RowSetIterator rsi = templDtlTxtVO.createRowSetIterator("rowsRSI");


            rsi.reset();

            while (rsi.hasNext()) {
                Row templRow = rsi.next();
                //RepeatHeader has to be changed with original attribute name
//                templRow.setAttribute("Attribute18",sAbsoluteValueLabelDtl);
//                            templRow.setAttribute("Attribute10",sDebitCreditDtlLabel);
//                cmnVORow.setAttribute("AbsoluteValueHdrFlag1", 
//                                      templRow.getAttribute("Attribute18"));
//                                                                      
//                            cmnVORow.setAttribute("DebitCreditDtlFlag",
//                                     templRow.getAttribute("Attribute10")); 

            }
            myAppsLog.write("ODEBillTxtAMImpl", 
                            "XXOD:End handleDtlAbsoluteValueLabelPPR", 1);
           String custDocId1=custDocId;
            //handleCompressPPR2(custDocId1);

        }
    
    public void  handleDebitCreditLabelHdrPPR(String sAbsoluteValueLabelDtl) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);

        OAViewObject templHdrTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
            

        RowSetIterator rsi = templHdrTxtVO.createRowSetIterator("rowsRSI");

        
        rsi.reset();

        while (rsi.hasNext()) {
            Row templRow = rsi.next();
            //RepeatHeader has to be changed with original attribute name
            templRow.setAttribute("Attribute10",sAbsoluteValueLabelDtl);

        }
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:End handleDtlAbsoluteValueLabelPPR", 1);
    
    //handleCompressPPR1();


    }
//Added by Bhagwan 31 Jul 2017 defect #40174
     public void  handleDebitCreditLabelTrlPPR(String sAbsoluteValueLabelDtl) {
         AppsLog myAppsLog = new AppsLog();
         myAppsLog.write("ODEBillAMImpl", 
                         "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);

         OAViewObject templTrlTxtVO = 
             (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");
             

         RowSetIterator rsi = templTrlTxtVO.createRowSetIterator("rowsRSI");

         
         rsi.reset();

         while (rsi.hasNext()) {
             Row templRow = rsi.next();
             //RepeatHeader has to be changed with original attribute name
             templRow.setAttribute("Attribute10",sAbsoluteValueLabelDtl);

         }
         myAppsLog.write("ODEBillTxtAMImpl", 
                         "XXOD:End handleDtlAbsoluteValueLabelPPR", 1);
     
     //handleCompressPPR1();


     }
     //Added by Bhagwan Rao 12 Jul 2017 Defect #40174
     public void  handleDebitCreditLabelDtlPPR(String sAbsoluteValueLabelDtl) {
         AppsLog myAppsLog = new AppsLog();
         myAppsLog.write("ODEBillAMImpl", 
                         "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);

         OAViewObject templDtlTxtVO = 
             (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
             

         RowSetIterator rsi = templDtlTxtVO.createRowSetIterator("rowsRSI");


         rsi.reset();

         while (rsi.hasNext()) {
             Row templRow = rsi.next();
             //RepeatHeader has to be changed with original attribute name
             templRow.setAttribute("Attribute10",sAbsoluteValueLabelDtl);

         }
         myAppsLog.write("ODEBillTxtAMImpl", 
                         "XXOD:End handleDtlAbsoluteValueLabelPPR", 1);
     
     //handleCompressPPR1();


     }
    //Added by Bhagwan Rao 12 Jul 2017 Defect #40174
     public void  handleSignPosLabelHdrPPR(String sAbsoluteValueLabelDtl) {
         AppsLog myAppsLog = new AppsLog();
         myAppsLog.write("ODEBillAMImpl", 
                         "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);

         OAViewObject templHdrTxtVO = 
             (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
             

         RowSetIterator rsi = templHdrTxtVO.createRowSetIterator("rowsRSI");


         rsi.reset();

         while (rsi.hasNext()) {
             Row templRow = rsi.next();
             //RepeatHeader has to be changed with original attribute name
             templRow.setAttribute("Attribute11",sAbsoluteValueLabelDtl);

         }
         myAppsLog.write("ODEBillTxtAMImpl", 
                         "XXOD:End handleDtlAbsoluteValueLabelPPR", 1);
     
     //handleCompressPPR1();


     }
    
    
    public void handleCompressPPR1(String sAbsoluteValueLabelDtl, String custDocId,String sDebitCreditHdrLabel )    
    {
    
    
        OAViewObject templHdrTxtVO = 
                   (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
        //              OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        //        OARow cmnVORow = (OARow)cmnVO.first();
                   
        OAViewObject PPRVO = (OAViewObject)this.findViewObject("ODEBillPPRVO");
        OARow PPRRow = (OARow)PPRVO.first();
        
        
        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();
        
        //OAViewObject mainVO = (OAViewObject)this.getODEBillMainVO();
        OARow mainRow = (OARow)templHdrTxtVO.first();

        OAViewObject custHeadVO = 
            (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
        OARow custHeadRow = (OARow)custHeadVO.first();
        
        
        String absValueRequired=null;
        String attr10=null;
        String attr18=null;
        
        if (mainRow != null && custHeadRow != null && PPRRow != null) {
            sAbsoluteValueLabelDtl = (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag");
            sDebitCreditHdrLabel = (String)cmnVORow.getAttribute("DebitCreditHdrFlag");
            
            
            if ((sAbsoluteValueLabelDtl == null) || ("N".equals(sAbsoluteValueLabelDtl))) {
                PPRRow.setAttribute("AbsoluteValueFlag", Boolean.TRUE);
                cmnVORow.setAttribute("DebitCreditHdrFlag",null);
                //mainRow.setAttribute("Attribute10", cmnVORow.getAttribute("DebitCreditHdrFlag"));
                
                String cmn=(String)cmnVORow.getAttribute("DebitCreditHdrFlag");
                
                
                            

                
                RowSetIterator rsi = templHdrTxtVO.createRowSetIterator("rowsRSI");


                rsi.reset();
                  
                while (rsi.hasNext()) {
                    Row templRow = rsi.next();
                    //RepeatHeader has to be changed with original attribute name
                    templRow.setAttribute("AbsoluteFlag",sAbsoluteValueLabelDtl);
                    templRow.setAttribute("DcIndicator",cmn);
//                    cmnVORow.setAttribute("AbsoluteValueHdrFlag", 
//                                          templRow.getAttribute("Attribute18"));                                
//                    cmnVORow.setAttribute("DebitCreditHdrFlag",
//                                         templRow.getAttribute("Attribute10"));
                               
                }
 OAViewObject templConfigHdrAVFNPVO = 
                     (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
                templConfigHdrAVFNPVO.setMaxFetchSize(-1); 
                templConfigHdrAVFNPVO.clearCache();
                 templConfigHdrAVFNPVO.setWhereClause(null);
                //templConfigHdrAVFNPVO.setWhereClause("cust_doc_id = " + custDocId + " and field_name != 'Account Number'  ");
                // templConfigHdrAVFNPVO.setWhereClause( "field_name != 'Account Number'  "+ " and cust_doc_id = " + custDocId + " or cust_doc_id is null");
                  //templConfigHdrAVFNPVO.setWhereClause( "field_name!= 'Sign'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                   templConfigHdrAVFNPVO.setWhereClause( "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 08 Oct 2017 for the defect #40174
                 //templConfigHdrAVFNPVO.setWhereClause("field_name != 'Account Number'  ");
                 
 ///and cust_doc_id is null
                 templConfigHdrAVFNPVO.executeQuery(); 
                
                
            }
            else {
            
                PPRRow.setAttribute("AbsoluteValueFlag", Boolean.FALSE);
                sAbsoluteValueLabelDtl = (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag");
                sDebitCreditHdrLabel = (String)cmnVORow.getAttribute("DebitCreditHdrFlag");
                
                OAViewObject templConfigHdrAVFNPVO = 
                                    (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
                               templConfigHdrAVFNPVO.setMaxFetchSize(-1); 
                               templConfigHdrAVFNPVO.clearCache();
                                templConfigHdrAVFNPVO.setWhereClause(null);
                               //templConfigHdrAVFNPVO.setWhereClause("cust_doc_id = " + custDocId + " and field_name != 'Account Number'  ");
                               // templConfigHdrAVFNPVO.setWhereClause( "field_name != 'Account Number'  "+ " and cust_doc_id = " + custDocId + " or cust_doc_id is null");
                //templConfigHdrAVFNPVO.setWhereClause( "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                //templConfigHdrAVFNPVO.setWhereClause("field_name != 'Account Number'  ");
                                 templConfigHdrAVFNPVO.setWhereClause( "field_name = 'Sign'  "+" or (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                
                ///and cust_doc_id is null
                                templConfigHdrAVFNPVO.executeQuery(); 
                
//                OAViewObject templConfigHdrAVFNPVO = 
//                                    (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
//                                templConfigHdrAVFNPVO.setWhereClause(null);
//                             //   templConfigHdrAVFNPVO.setWhereClause("cust_doc_id is null ");
//                                templConfigHdrAVFNPVO.executeQuery();
                
                //mainRow.setAttribute("Attribute18",sAbsoluteValueLabelDtl);
                //mainRow.setAttribute("Attribute10",sDebitCreditHdrLabel);
//                OAViewObject templConfigHdrAVFNPVO = 
//                    (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
//                templConfigHdrAVFNPVO.setWhereClause(null);
//                templConfigHdrAVFNPVO.setWhereClause("cust_doc_id is null ");                
//                templConfigHdrAVFNPVO.executeQuery();
                
//                cmnVORow.setAttribute("AbsoluteValueHdrFlag", 
//                                      mainRow.getAttribute("Attribute18"));                                
//                cmnVORow.setAttribute("DebitCreditHdrFlag",
//                                     mainRow.getAttribute("Attribute10"));
//                OAViewObject templConfigHdrAVFNPVO1 = 
//                    (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
//                templConfigHdrAVFNPVO1.setWhereClause(null);
//                templConfigHdrAVFNPVO1.setWhereClause("field_name != 'Account Number' and cust_doc_id is null ");
//                templConfigHdrAVFNPVO1.executeQuery();
                
                RowSetIterator rsi = templHdrTxtVO.createRowSetIterator("rowsRSI");


                rsi.reset();
                  
                while (rsi.hasNext()) {
                    Row templRow = rsi.next();
                    //RepeatHeader has to be changed with original attribute name
                    templRow.setAttribute("AbsoluteFlag",sAbsoluteValueLabelDtl);
                    if(sDebitCreditHdrLabel==null  ||  sDebitCreditHdrLabel!=null)
                    {
                        templRow.setAttribute("DcIndicator",null);
                        String sDebitCreditHdrLabel1 = (String)cmnVORow.getAttribute("DebitCreditHdrFlag");
                        
                    templRow.setAttribute("DcIndicator",sDebitCreditHdrLabel1);
                    }
                
                cmnVORow.setAttribute("AbsoluteValueHdrFlag", 
                                      mainRow.getAttribute("AbsoluteFlag"));                                
                cmnVORow.setAttribute("DebitCreditHdrFlag",
                                     mainRow.getAttribute("DcIndicator"));
                
            }
        

            }    
        }
        
        
        else
        
        {
           
    
 
                absValueRequired = (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag");
               
                attr10=(String)cmnVORow.getAttribute("DebitCreditHdrFlag"); 
                                                          
              
           
            //  absValue = (Boolean)  cmnVORow.getAttribute("AbsoluteValueHdrFlag");
               //  absValueRequired="N";
               // docStatus = (String)custHeadRow.getAttribute("Status");
               // utl.log("Inside handleCompresssPPR1: Status: " + docStatus);
                if ((absValueRequired == null) || ("N".equals(absValueRequired))) {
                    PPRRow.setAttribute("AbsoluteValueFlag", Boolean.TRUE);
                    cmnVORow.setAttribute("AbsoluteValueHdrFlag", 
                                          absValueRequired);                                
                    cmnVORow.setAttribute("DebitCreditHdrFlag",
                                         null);
                               attr18=   (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag");        
                             
                                    attr10=(String)cmnVORow.getAttribute("DebitCreditHdrFlag");
                             //  attr10=   (String)mainRow.getAttribute("Attribute10");        
                                         

//                    OAViewObject templConfigHdrAVFNPVO = 
//                        (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
//                    templConfigHdrAVFNPVO.clearCache();
//                   // templConfigHdrAVFNPVO.setPickListCacheEnabled
//                   
//                    templConfigHdrAVFNPVO.setWhereClause(null);
//                    templConfigHdrAVFNPVO.setWhereClause("field_name != 'Account Number' and cust_doc_id is null ");
//                    templConfigHdrAVFNPVO.executeQuery();


 OAViewObject templConfigHdrAVFNPVO = 
                     (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
                templConfigHdrAVFNPVO.setMaxFetchSize(-1); 
                templConfigHdrAVFNPVO.clearCache();
                 templConfigHdrAVFNPVO.setWhereClause(null); //and cust_doc_id is null or cust_doc_id=117522866
                    //templConfigHdrAVFNPVO.setWhereClause( "field_name != 'Sign'  "+" and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                     templConfigHdrAVFNPVO.setWhereClause( "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 08 Oct 2017 for the defect #40174
                // templConfigHdrAVFNPVO.setWhereClause("field_name != 'Account Number' and cust_doc_id is null ");
                    templConfigHdrAVFNPVO.executeQuery();  
//                    OAViewObject templConfigHdrAVFNPVO1 = 
//                        (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
//                    templConfigHdrAVFNPVO1.setWhereClause(null);
//                    templConfigHdrAVFNPVO1.setWhereClause("field_name != 'Account Number' and cust_doc_id is null ");
//                    templConfigHdrAVFNPVO1.executeQuery();
                
// OAViewObject templConfigHdrAVFNPVO = 
//                     (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
//                 templConfigHdrAVFNPVO.setWhereClause(null);
//                 templConfigHdrAVFNPVO.setWhereClause("field_name != 'Account Number'  ");
// ///and cust_doc_id is null
//                 templConfigHdrAVFNPVO.executeQuery();
                                    

                } else if ("Y".equals(absValueRequired)) {
                
                    PPRRow.setAttribute("AbsoluteValueFlag", Boolean.FALSE);
                  
                  cmnVORow.setAttribute("AbsoluteValueHdrFlag", 
                                       absValueRequired);
                    cmnVORow.setAttribute("DebitCreditHdrFlag", 
                                         attr10);   
                                         
//                    OAViewObject templConfigHdrAVFNPVO = 
//                                        (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
//                                   templConfigHdrAVFNPVO.setMaxFetchSize(-1); 
//                                   templConfigHdrAVFNPVO.clearCache();
//                                    templConfigHdrAVFNPVO.setWhereClause(null); //and cust_doc_id is null or cust_doc_id=117522866
//                                       templConfigHdrAVFNPVO.setWhereClause( "(cust_doc_id is null or cust_doc_id = " + custDocId + ")");

 OAViewObject templConfigHdrAVFNPVO = 
                     (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
                templConfigHdrAVFNPVO.setMaxFetchSize(-1); 
                templConfigHdrAVFNPVO.clearCache();
                 templConfigHdrAVFNPVO.setWhereClause(null);
                //templConfigHdrAVFNPVO.setWhereClause("cust_doc_id = " + custDocId + " and field_name != 'Account Number'  ");
                // templConfigHdrAVFNPVO.setWhereClause( "field_name != 'Account Number'  "+ " and cust_doc_id = " + custDocId + " or cust_doc_id is null");
            templConfigHdrAVFNPVO.setWhereClause( "field_name = 'Sign'  "+" or (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                    
                 //templConfigHdrAVFNPVO.setWhereClause("field_name != 'Account Number'  ");
                 
 ///and cust_doc_id is null
                 templConfigHdrAVFNPVO.executeQuery(); 
                    
                    handleDtlAbsoluteValueLabelUpdatePPR( absValueRequired, attr10, custDocId);
                    
//                    OAViewObject templConfigHdrAVFNPVO = 
//                        (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
//                    templConfigHdrAVFNPVO.setWhereClause(null);
//                    templConfigHdrAVFNPVO.setWhereClause("cust_doc_id is null ");                
//                    templConfigHdrAVFNPVO.executeQuery();
                    
//                    OAViewObject templConfigHdrAVFNPVO1 = 
//                        (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
//                    templConfigHdrAVFNPVO1.setWhereClause(null);
//                    templConfigHdrAVFNPVO1.setWhereClause("field_name != 'Account Number' and cust_doc_id is null ");
//                    templConfigHdrAVFNPVO1.executeQuery();
                }                 
       }
     
    }
    public void handleCompressPPR2(String sAbsoluteValueLblDtl, String custDocId,String sDebitCreditDtlLabel)    
    {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside handleCompresssPPR2");
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        OAViewObject templDtlTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
            
            //OARow templDtlTXTRow=(OARow)templDtlTxtVO.first();
            
        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
       OARow cmnVORow = (OARow)cmnVO.first();
        
	                            
        OARow mainRow = (OARow)templDtlTxtVO.first();

        OAViewObject custHeadVO = 
            (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
        OARow custHeadRow = (OARow)custHeadVO.first();
        
        
        String absValueRequired = null;
        Boolean absValue;
        String docStatus = null;
        String attr10=null;
        String attr18=null;
       

        if (mainRow != null && custHeadRow != null && PPRRow != null) {
        
        
        sAbsoluteValueLblDtl = (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag1");
        sDebitCreditDtlLabel = (String)cmnVORow.getAttribute("DebitCreditDtlFlag");
         
        
          
                   
       //  absValue = (Boolean)  cmnVORow.getAttribute("AbsoluteValueHdrFlag");
            docStatus = (String)custHeadRow.getAttribute("Status");
            utl.log("Inside handleCompresssPPR2: Status: " + docStatus);
            if ((sAbsoluteValueLblDtl == null) || ("N".equals(sAbsoluteValueLblDtl))) {
                PPRRow.setAttribute("AbsoluteValueFlag1", Boolean.TRUE);
                //mainRow.setAttribute("Attribute10",null);
                 cmnVORow.setAttribute("DebitCreditDtlFlag",null);
                String cmn=(String)cmnVORow.getAttribute("DebitCreditDtlFlag");
                                
                
                

//                OAViewObject templConfigHdrAVFNPVO = 
//                    (OAViewObject)this.findViewObject("ODEBillConfigHdrFieldNamesPVO");
//                templConfigHdrAVFNPVO.setWhereClause(null);
//                templConfigHdrAVFNPVO.setWhereClause("field_name != 'Account Number' and cust_doc_id is null ");
//                templConfigHdrAVFNPVO.executeQuery();
                
                
//                OAViewObject templConfigHdrAVFNPVO1 = 
//                                    (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
//                                templConfigHdrAVFNPVO1.setWhereClause(null);
//                                templConfigHdrAVFNPVO1.setWhereClause("field_name != 'Account Number' and cust_doc_id is null ");
//                                templConfigHdrAVFNPVO1.executeQuery();
                                
                RowSetIterator rsi = templDtlTxtVO.createRowSetIterator("rowsRSI");
                                rsi.reset();
                                  
                                while (rsi.hasNext()) {
                                  
                                    Row templRow = rsi.next();
                                    //RepeatHeader has to be changed with original attribute name
                                    templRow.setAttribute("AbsoluteFlag",sAbsoluteValueLblDtl);
                                    templRow.setAttribute("DcIndicator",cmn);
                                               
                                }
                OAViewObject templConfigDtlAVFNPVO = 
                                    (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesPVO");
                               templConfigDtlAVFNPVO.setMaxFetchSize(-1); 
                               templConfigDtlAVFNPVO.clearCache();
                                templConfigDtlAVFNPVO.setWhereClause(null);
                            
                                //templConfigDtlAVFNPVO.setWhereClause( "field_name != 'Sign'  "+" and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                 //templConfigDtlAVFNPVO.setWhereClause( "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 08 Oct 2017 for the defect #40174
                                 // templConfigDtlAVFNPVO.setWhereClause( "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator' and FIELD_ID!='10109'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Field Id condition Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and Defect#52049
                                  templConfigDtlAVFNPVO.setWhereClause("field_name not in (SELECT val.source_value2 FROM xx_fin_translatedefinition def,xx_fin_translatevalues val WHERE def.translate_id = val.translate_id AND def.translation_name = 'XX_CDH_EBL_TXT_SP_DETAILS' )" +
                                             "and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and added code 25-07-2018 for the Defect#52049
                ///and cust_doc_id is null
                                templConfigDtlAVFNPVO.executeQuery(); 
                                
                OAViewObject templConfigDtlAVSumFNPVO = 
                                    (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
                               templConfigDtlAVSumFNPVO.setMaxFetchSize(-1); 
                               templConfigDtlAVSumFNPVO.clearCache();
                                templConfigDtlAVSumFNPVO.setWhereClause(null);
                            
                               // templConfigDtlAVSumFNPVO.setWhereClause( "field_name != 'Sign'  "+" and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                //templConfigDtlAVSumFNPVO.setWhereClause(  "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 08 Oct 2017 for the defect #40174
                                 //templConfigDtlAVSumFNPVO.setWhereClause(  "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator' and FIELD_ID!='10109'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Field Id condition Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and Defect#52049
                                  
                                  templConfigDtlAVSumFNPVO.setWhereClause("field_name not in (SELECT val.source_value2 FROM xx_fin_translatedefinition def,xx_fin_translatevalues val WHERE def.translate_id = val.translate_id AND def.translation_name = 'XX_CDH_EBL_TXT_SP_DETAILS' )" +
                                             "and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and added code 25-07-2018 for the Defect#52049
                ///and cust_doc_id is null
                                templConfigDtlAVSumFNPVO.executeQuery(); 
//                                cmnVORow.setAttribute("AbsoluteValueHdrFlag1", 
//                                                      mainRow.getAttribute("Attribute18"));                                
//                                cmnVORow.setAttribute("DebitCreditDtlFlag",
//                                                     mainRow.getAttribute("Attribute10"));                
                                
            } else 
            {
            
                PPRRow.setAttribute("AbsoluteValueFlag1", Boolean.FALSE);
                sAbsoluteValueLblDtl = (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag1");
                sDebitCreditDtlLabel = (String)cmnVORow.getAttribute("DebitCreditDtlFlag");
                
                
               
//                mainRow.setAttribute("Attribute18",sAbsoluteValueLblDtl);
//                mainRow.setAttribute("Attribute10",sDebitCreditDtlLabel);
               

                OAViewObject templConfigDtlAVFNPVO = 
                                     (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesPVO");
                                templConfigDtlAVFNPVO.setMaxFetchSize(-1); 
                                templConfigDtlAVFNPVO.clearCache();
                                 templConfigDtlAVFNPVO.setWhereClause(null);
                                 //templConfigDtlAVFNPVO.setWhereClause( "field_name = 'Sign'  "+" or (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                  //templConfigDtlAVFNPVO.setWhereClause( "FIELD_ID!='10109'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added Field Id condition by Reddy Sekhar K on 13 July 2018 for the defect #45279 
                                  // templConfigDtlAVFNPVO.setWhereClause( "FIELD_ID!='10109'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Field Id condition Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and Defect#52049
                                   templConfigDtlAVFNPVO.setWhereClause( "field_name not in (SELECT val.source_value2 FROM xx_fin_translatedefinition def,xx_fin_translatevalues val WHERE def.translate_id = val.translate_id AND def.translation_name = 'XX_CDH_EBL_TXT_SP_DETAILS' and val.source_value3='Y')" +
                                             "and (cust_doc_id is null or cust_doc_id = " + custDocId + ")"); //Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and added code 25-07-2018 for the Defect#52049
                                 
                 ///and cust_doc_id is null
                                 templConfigDtlAVFNPVO.executeQuery(); 
            
                OAViewObject templConfigDtlSumAVFNPVO = 
                                     (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
                                templConfigDtlSumAVFNPVO.setMaxFetchSize(-1); 
                                templConfigDtlSumAVFNPVO.clearCache();
                                 templConfigDtlSumAVFNPVO.setWhereClause(null);
                                // templConfigDtlSumAVFNPVO.setWhereClause( "field_name = 'Sign'  "+" or (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                 //templConfigDtlSumAVFNPVO.setWhereClause( "FIELD_ID!='10109'"+" and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Field Id condition Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and Defect#52049
                                  templConfigDtlSumAVFNPVO.setWhereClause( "field_name not in (SELECT val.source_value2 FROM xx_fin_translatedefinition def,xx_fin_translatevalues val WHERE def.translate_id = val.translate_id AND def.translation_name = 'XX_CDH_EBL_TXT_SP_DETAILS' and val.source_value3='Y')" +
                                             "and (cust_doc_id is null or cust_doc_id = " + custDocId + ")"); //Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and added code 25-07-2018 for the Defect#52049
                
                 ///and cust_doc_id is null
                                 templConfigDtlSumAVFNPVO.executeQuery(); 
                

                                
                RowSetIterator rsi = templDtlTxtVO.createRowSetIterator("rowsRSI");


                               rsi.reset();
                                 
                               while (rsi.hasNext()) {
                               
                                   Row templRow = rsi.next();
                                   //RepeatHeader has to be changed with original attribute name
                                   templRow.setAttribute("AbsoluteFlag",sAbsoluteValueLblDtl);
                                   templRow.setAttribute("DcIndicator",sDebitCreditDtlLabel);                              
                               
                           }
            }
            
    }
        
    else 
        {
        
            
                            absValueRequired = (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag1");
                           
                            attr10=(String)cmnVORow.getAttribute("DebitCreditDtlFlag"); 
                                                                      
                          
                       
                        //  absValue = (Boolean)  cmnVORow.getAttribute("AbsoluteValueHdrFlag");
                           //  absValueRequired="N";
                           // docStatus = (String)custHeadRow.getAttribute("Status");
                           // utl.log("Inside handleCompresssPPR1: Status: " + docStatus);
                            if ((absValueRequired == null) || ("N".equals(absValueRequired))) {
                                PPRRow.setAttribute("AbsoluteValueFlag1", Boolean.TRUE);
                                cmnVORow.setAttribute("AbsoluteValueHdrFlag1", 
                                                      absValueRequired);                                
                                cmnVORow.setAttribute("DebitCreditDtlFlag",
                                                     null);
                                           attr18=   (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag1");        
                                         
                                                attr10=(String)cmnVORow.getAttribute("DebitCreditDtlFlag");
                                         //  attr10=   (String)mainRow.getAttribute("Attribute10");        
                                                     
                                                     
                                                     
                                OAViewObject templConfigDtlAVFNPVO = 
                                                    (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesPVO");
                                               templConfigDtlAVFNPVO.setMaxFetchSize(-1); 
                                               templConfigDtlAVFNPVO.clearCache();
                                                templConfigDtlAVFNPVO.setWhereClause(null);
                                            
                                                //templConfigDtlAVFNPVO.setWhereClause( "field_name != 'Sign'  "+" and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                                // templConfigDtlAVFNPVO.setWhereClause( "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 08 Oct 2017 for the defect #40174
                                                // templConfigDtlAVFNPVO.setWhereClause( "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator' and FIELD_ID!='10109'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Field Id condition Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and Defect#52049
                                                  
                                                 templConfigDtlAVFNPVO.setWhereClause( "field_name not in (SELECT val.source_value2 FROM xx_fin_translatedefinition def,xx_fin_translatevalues val WHERE def.translate_id = val.translate_id AND def.translation_name = 'XX_CDH_EBL_TXT_SP_DETAILS' )" +
                                                                                 "and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and added code 25-07-2018 for the Defect#52049
                                ///and cust_doc_id is null
                                                templConfigDtlAVFNPVO.executeQuery(); 
                                                
                                OAViewObject templConfigDtlAVSumFNPVO = 
                                                    (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
                                               templConfigDtlAVSumFNPVO.setMaxFetchSize(-1); 
                                               templConfigDtlAVSumFNPVO.clearCache();
                                                templConfigDtlAVSumFNPVO.setWhereClause(null);
                                            
                                               // templConfigDtlAVSumFNPVO.setWhereClause( "field_name != 'Sign'  "+" and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                                //templConfigDtlAVSumFNPVO.setWhereClause( "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 08 Oct 2017 for the defect #40174
                                                 //templConfigDtlAVSumFNPVO.setWhereClause( "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator' and FIELD_ID!='10109' "+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Field Id condition Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and Defect#52049
                                                  
                                                  templConfigDtlAVSumFNPVO.setWhereClause( "field_name not in (SELECT val.source_value2 FROM xx_fin_translatedefinition def,xx_fin_translatevalues val WHERE def.translate_id = val.translate_id AND def.translation_name = 'XX_CDH_EBL_TXT_SP_DETAILS' )" +
                                             "and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and added code 25-07-2018 for the Defect#52049
                                ///and cust_doc_id is null
                                                templConfigDtlAVSumFNPVO.executeQuery(); 
//                            
//                                

                            } else if ("Y".equals(absValueRequired)) {
                            
                                PPRRow.setAttribute("AbsoluteValueFlag1", Boolean.FALSE);
                              
                              cmnVORow.setAttribute("AbsoluteValueHdrFlag1", 
                                                   absValueRequired);
                                cmnVORow.setAttribute("DebitCreditDtlFlag", 
                                                     attr10);                   
                                
                                handleDtlAbsoluteValueLabelUpdatePPR2( absValueRequired, attr10, custDocId);
                                
                                OAViewObject templConfigDtlAVFNPVO = 
                                                     (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesPVO");
                                                templConfigDtlAVFNPVO.setMaxFetchSize(-1); 
                                                templConfigDtlAVFNPVO.clearCache();
                                                 templConfigDtlAVFNPVO.setWhereClause(null);
                                                 //templConfigDtlAVFNPVO.setWhereClause( "field_name = 'Sign'  "+" or (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                                  //templConfigDtlAVFNPVO.setWhereClause( "FIELD_ID!='10109'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Field Id condition Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and Defect#52049
                                                   templConfigDtlAVFNPVO.setWhereClause( "field_name not in (SELECT val.source_value2 FROM xx_fin_translatedefinition def,xx_fin_translatevalues val WHERE def.translate_id = val.translate_id AND def.translation_name = 'XX_CDH_EBL_TXT_SP_DETAILS' and val.source_value3=Y')" +
                                             "and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and added code 25-07-2018 for the Defect#52049
                                 ///and cust_doc_id is null
                                                 templConfigDtlAVFNPVO.executeQuery(); 
                                
                                OAViewObject templConfigDtlSumAVFNPVO = 
                                                     (OAViewObject)this.findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
                                                templConfigDtlSumAVFNPVO.setMaxFetchSize(-1); 
                                                templConfigDtlSumAVFNPVO.clearCache();
                                                 templConfigDtlSumAVFNPVO.setWhereClause(null);
                                                 //templConfigDtlSumAVFNPVO.setWhereClause( "field_name = 'Sign'  "+" or (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                                  //templConfigDtlSumAVFNPVO.setWhereClause( "FIELD_ID!='10109'"+" and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Field Id condition Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and Defect#52049
                                                   templConfigDtlSumAVFNPVO.setWhereClause("field_name not in (SELECT val.source_value2 FROM xx_fin_translatedefinition def,xx_fin_translatevalues val WHERE def.translate_id = val.translate_id AND def.translation_name = 'XX_CDH_EBL_TXT_SP_DETAILS' and val.source_value3='Y')" +
                                             "and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 13 July 2018 for the Defect#45279 and added code 25-07-2018 for the Defect#52049
                                 ///and cust_doc_id is null
                                                 templConfigDtlSumAVFNPVO.executeQuery(); 
                            
                            }		
        }
        utl.log("End of handleCompressPPR");
    }
    //Added by Bhagwan Rao 7 Jul 2017 for Defect #40174
    private void handleDtlAbsoluteValueLabelUpdatePPR1(String absValueRequired, 
                                                            
                                                            String attr10, String custDocId1) {
                AppsLog myAppsLog = new AppsLog();
                myAppsLog.write("ODEBillAMImpl", 
                                "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);

                OAViewObject templHdrTxtVO = 
                    (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
                    
                            OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
                OARow cmnVORow = (OARow)cmnVO.first();
                RowSetIterator rsi = templHdrTxtVO.createRowSetIterator("rowsRSI");


                rsi.reset();
                  
                while (rsi.hasNext()) {
                    Row templRow = rsi.next();
                    //RepeatHeader has to be changed with original attribute name
                    templRow.setAttribute("Attribute18",absValueRequired);
                    templRow.setAttribute("Attribute10",attr10);
                                     cmnVORow.setAttribute("AbsoluteValueHdrFlag", 
                                          templRow.getAttribute("Attribute18"));
                               
                    cmnVORow.setAttribute("DebitCreditHdrFlag",
                                         templRow.getAttribute("Attribute10"));
                }
                myAppsLog.write("ODEBillTxtAMImpl", 
                                "XXOD:End handleDtlAbsoluteValueLabelPPR", 1);
            }
    
    //Added by Bhagwan Rao 7 Jul 2017 for Defect #40174
    public void handleDtlAbsoluteValueLabelPPR2(String sAbsoluteValueLabelDtl,  String custDocId, String sDebitCreditTrlLabel) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);

        OAViewObject templTrlTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");
            
        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first(); 

        RowSetIterator rsi = templTrlTxtVO.createRowSetIterator("rowsRSI");


        rsi.reset();

        while (rsi.hasNext()) {
            Row templRow = rsi.next();
            //RepeatHeader has to be changed with original attribute name
            templRow.setAttribute("Attribute18",sAbsoluteValueLabelDtl);
            
			templRow.setAttribute("Attribute10",sDebitCreditTrlLabel);
            cmnVORow.setAttribute("AbsoluteValueHdrFlag2",
                      templRow.getAttribute("Attribute18"));
                                                      
            cmnVORow.setAttribute("DebitCreditTrlFlag",
                     templRow.getAttribute("Attribute10")); 

        }
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:End handleDtlAbsoluteValueLabelPPR", 1);
       // handleCompressPPR3(custDocId);
    }
    
    public void handleCompressPPR3(String sAbsoluteValueLabelDtl,String custDocId, String sDebitCreditTrlLabel)    
    {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside handleCompresssPPR3");
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        OAViewObject templTrlTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");
            
            OARow templTrlTXTRow=(OARow)templTrlTxtVO.first();
            
        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();
        
        
        
        
    //        templHdrTXTRow.setAttribute("Attribute11",
    //                              cmnVORow.getAttribute("SignPosHdr"));
                              
        OARow mainRow = (OARow)templTrlTxtVO.first();

        OAViewObject custHeadVO = 
            (OAViewObject)this.findViewObject("ODEBillCustHeaderVO");
        OARow custHeadRow = (OARow)custHeadVO.first();
        
        
        

        String absValueRequired = null;
		String attr10=null;
        String attr18=null;
       // Boolean absValue;
        String docStatus = null;

        if (mainRow != null && custHeadRow != null && PPRRow != null) {
        
        
                sAbsoluteValueLabelDtl = (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag2");
                            sDebitCreditTrlLabel = (String)cmnVORow.getAttribute("DebitCreditTrlFlag");
                            
                            
                            
                if ((sAbsoluteValueLabelDtl == null) || ("N".equals(sAbsoluteValueLabelDtl))) {
                                PPRRow.setAttribute("AbsoluteValueFlag2", Boolean.TRUE);
                                cmnVORow.setAttribute("DebitCreditTrlFlag",null);
                                                String cmn=(String)cmnVORow.getAttribute("DebitCreditTrlFlag");
                                                                
                                                
                                
                               // mainRow.setAttribute("Attribute10",null);
                                
                                
                              
                                 OAViewObject templConfigTrlAVFNPVO = 
                                                     (OAViewObject)this.findViewObject("ODEBillConfigTrlFieldNamesPVO");
                                                templConfigTrlAVFNPVO.setMaxFetchSize(-1); 
                                                templConfigTrlAVFNPVO.clearCache();
                                                 templConfigTrlAVFNPVO.setWhereClause(null);
                                             
                                                 //templConfigTrlAVFNPVO.setWhereClause( "field_name != 'Sign'  "+" and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                                  templConfigTrlAVFNPVO.setWhereClause( "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 08 Oct 2017 for the defect #40174
                                                
                                                 
                                 ///and cust_doc_id is null
                                                 templConfigTrlAVFNPVO.executeQuery(); 
                                
                                RowSetIterator rsi = templTrlTxtVO.createRowSetIterator("rowsRSI");


                                rsi.reset();
                                  
                                while (rsi.hasNext()) {
                                    Row templRow = rsi.next();
                                    //RepeatHeader has to be changed with original attribute name
                                    templRow.setAttribute("AbsoluteFlag",sAbsoluteValueLabelDtl);
                                    templRow.setAttribute("DcIndicator",cmn);
                                               
                                }
//                                cmnVORow.setAttribute("AbsoluteValueHdrFlag2", 
//                                                      mainRow.getAttribute("Attribute18"));                                
//                                cmnVORow.setAttribute("DebitCreditTrlFlag",
//                                                     mainRow.getAttribute("Attribute10"));
                            }
                            else {
                            
                            
                                PPRRow.setAttribute("AbsoluteValueFlag2", Boolean.FALSE);
                                
                                sAbsoluteValueLabelDtl = (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag2");
                                sDebitCreditTrlLabel = (String)cmnVORow.getAttribute("DebitCreditTrlFlag");
                                            
                                
                              //  mainRow.setAttribute("Attribute18",sAbsoluteValueLabelDtl);
                              //  mainRow.setAttribute("Attribute10",sDebitCreditTrlLabel);
//                                
                            OAViewObject templConfigTrlAVFNPVO = 
                                     (OAViewObject)this.findViewObject("ODEBillConfigTrlFieldNamesPVO");
                                templConfigTrlAVFNPVO.setMaxFetchSize(-1); 
                                templConfigTrlAVFNPVO.clearCache();
                                 templConfigTrlAVFNPVO.setWhereClause(null);
                                 templConfigTrlAVFNPVO.setWhereClause( "field_name = 'Sign'  "+" or (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                 
                                 
                 ///and cust_doc_id is null
                                 templConfigTrlAVFNPVO.executeQuery(); 
                                
                                RowSetIterator rsi = templTrlTxtVO.createRowSetIterator("rowsRSI");


                                rsi.reset();
                                  
                                while (rsi.hasNext()) {
                                
                                    Row templRow = rsi.next();
                                    //RepeatHeader has to be changed with original attribute name
                                    templRow.setAttribute("AbsoluteFlag",sAbsoluteValueLabelDtl);
                                    templRow.setAttribute("DcIndicator",sDebitCreditTrlLabel);
                                
                                
                            }
                        

                            }    
                        }
                else
                        
                        {
                           
                    
                 
                                absValueRequired = (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag2");
                               
                                attr10=(String)cmnVORow.getAttribute("DebitCreditTrlFlag"); 
                                                                          
                              
                           
                            //  absValue = (Boolean)  cmnVORow.getAttribute("AbsoluteValueHdrFlag");
                               //  absValueRequired="N";
                               // docStatus = (String)custHeadRow.getAttribute("Status");
                               // utl.log("Inside handleCompresssPPR1: Status: " + docStatus);
                                if ((absValueRequired == null) || ("N".equals(absValueRequired))) {
                                    PPRRow.setAttribute("AbsoluteValueFlag2", Boolean.TRUE);
                                    cmnVORow.setAttribute("AbsoluteValueHdrFlag2", 
                                                          absValueRequired);                                
                                    cmnVORow.setAttribute("DebitCreditTrlFlag",
                                                         null);
                                               attr18=   (String)cmnVORow.getAttribute("AbsoluteValueHdrFlag2");        
                                             
                                                    attr10=(String)cmnVORow.getAttribute("DebitCreditTrlFlag");
                                             //  attr10=   (String)mainRow.getAttribute("Attribute10");        
                                                         

                                    OAViewObject templConfigTrlAVFNPVO = 
                                                         (OAViewObject)this.findViewObject("ODEBillConfigTrlFieldNamesPVO");
                                                    templConfigTrlAVFNPVO.setMaxFetchSize(-1); 
                                                    templConfigTrlAVFNPVO.clearCache();
                                                     templConfigTrlAVFNPVO.setWhereClause(null);
                                                 
                                                     //templConfigTrlAVFNPVO.setWhereClause( "field_name != 'Sign'  "+" and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                                      templConfigTrlAVFNPVO.setWhereClause( "field_name!= 'Sign' and field_name!= 'Debit/Credit Indicator'"+ " and (cust_doc_id is null or cust_doc_id = " + custDocId + ")");//Added by Reddy Sekhar K on 08 Oct 2017 for the defect #40174
                                                    
                                                     
                                     ///and cust_doc_id is null
                                                     templConfigTrlAVFNPVO.executeQuery(); 
                                                    

                                } else if ("Y".equals(absValueRequired)) {
                                
                                    PPRRow.setAttribute("AbsoluteValueFlag2", Boolean.FALSE);
                                  
                                  cmnVORow.setAttribute("AbsoluteValueHdrFlag2", 
                                                       absValueRequired);
                                    cmnVORow.setAttribute("DebitCreditTrlFlag", 
                                                         attr10);                   
                                    
                                    handleDtlAbsoluteValueLabelUpdatePPR4( absValueRequired, attr10, custDocId);
                                
                                    OAViewObject templConfigTrlAVFNPVO = 
                                                                        (OAViewObject)this.findViewObject("ODEBillConfigTrlFieldNamesPVO");
                                                                   templConfigTrlAVFNPVO.setMaxFetchSize(-1); 
                                                                   templConfigTrlAVFNPVO.clearCache();
                                                                    templConfigTrlAVFNPVO.setWhereClause(null);
                                                                    templConfigTrlAVFNPVO.setWhereClause( "field_name = 'Sign'  "+" or (cust_doc_id is null or cust_doc_id = " + custDocId + ")");
                                                                    
                                                                    
                                                    ///and cust_doc_id is null
                                                                    templConfigTrlAVFNPVO.executeQuery();
                                }                 
                       }        

                            
        
            //  utl.log("End of handleCompressPPR3");
        }
      
   // }

      //Added by Bhagwan 25 Feb 2017 
      
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
       
       //Added by Bhagwan 25 March 2016 
       
        public void handleNonQtyPPR(String sNonDtlQty)  {
        try
        {
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
             ebillMainRow.setAttribute("NondtQuantity", new oracle.jbo.domain.Number(sNonDtlQty));
         }
         
         
         myAppsLog.write("ODEBillAMImpl", "XXOD:End handleSummaryBillPPR", 1);
        }
        catch(SQLException e) {
            e.printStackTrace();
        }
        catch(Exception e) {
            e.printStackTrace();
        }
        }
    //bg041v 16 Feb 2016

        public void handleTaxLabelPPR() {
            AppsLog myAppsLog = new AppsLog();
            myAppsLog.write("ODEBillTxtAMImpl", "XXOD:Start handleTaxLabelPPR", 1);

            OAViewObject templDtlVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
                
            OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
                    OARow cmnVORow = (OARow)cmnVO.first();

            RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
            rsi.reset();

            while (rsi.hasNext()) {
                Row templRow = rsi.next(); 
              
                templRow.setAttribute("TaxUpFlag", cmnVORow.getAttribute("TaxUPFlag"));

            }
            myAppsLog.write("ODEBillTxtAMImpl", "XXOD:End handleTaxLabelPPR", 1);

        }
        
        //Added by Bhagwan 25 Feb 2017 

        public void handleFreightLabelPPR() {
            AppsLog myAppsLog = new AppsLog();
            myAppsLog.write("ODEBillAMImpl", "XXOD:Start handleFreightLabelPPR", 1);

            OAViewObject templDtlVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
                
            OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
                    OARow cmnVORow = (OARow)cmnVO.first();

            RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
            rsi.reset();

            while (rsi.hasNext()) {
                Row templRow = rsi.next();  
                
                templRow.setAttribute("FreightUpFlag", cmnVORow.getAttribute("FreightUPFlag"));

            }
            myAppsLog.write("ODEBillAMImpl", "XXOD:End handleFreightLabelPPR", 1);

        }
        
        
        //Added by Bhagwan 25 Feb 2017 

        public void handleMiscLabelPPR() {
            AppsLog myAppsLog = new AppsLog();
            myAppsLog.write("ODEBillAMImpl", "XXOD:Start handleMiscLabelPPR", 1);

            OAViewObject templDtlVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
                
            OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
                    OARow cmnVORow = (OARow)cmnVO.first();

            RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
            rsi.reset();

            while (rsi.hasNext()) {
                Row templRow = rsi.next(); 
                templRow.setAttribute("MiscUpFlag", cmnVORow.getAttribute("MiscUPFlag"));

            }
            myAppsLog.write("ODEBillAMImpl", "XXOD:End handleMiscLabelPPR", 1);

        }

        //Added by Bhagwan 25 March 2017 

        public void handleTaxEPLabelPPR() {
            AppsLog myAppsLog = new AppsLog();
            myAppsLog.write("ODEBillAMImpl", "XXOD:Start handleTaxEPLabelPPR", 1);

            OAViewObject templDtlVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
                
            OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
                    OARow cmnVORow = (OARow)cmnVO.first();

            RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
            rsi.reset();

            while (rsi.hasNext()) {
                Row templRow = rsi.next();                      
                templRow.setAttribute("TaxEpFlag", cmnVORow.getAttribute("TaxEPFlag"));
                

            }
            myAppsLog.write("ODEBillAMImpl", "XXOD:End handleTaxEPLabelPPR", 1);

        }
        
        //Added by Bhagwan 25 Feb 2017 

        public void handleFreightEpLabelPPR( ) {
            AppsLog myAppsLog = new AppsLog();
            myAppsLog.write("ODEBillAMImpl", "XXOD:Start handleFreightEpLabelPPR", 1);

            OAViewObject templDtlVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
                
            OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
                    OARow cmnVORow = (OARow)cmnVO.first();

            RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
            rsi.reset();

            while (rsi.hasNext()) {
                Row templRow = rsi.next();                      
                templRow.setAttribute("FreightEpFlag", cmnVORow.getAttribute("FreightEPFlag") );

            }
            myAppsLog.write("ODEBillAMImpl", "XXOD:End handleFreightEpLabelPPR", 1);

        }
        
        //Added by Bhagwan 25 Feb 2017

        public void handleMiscEPLabelPPR( ) {
            AppsLog myAppsLog = new AppsLog();
            myAppsLog.write("ODEBillAMImpl", "XXOD:Start handleMiscEPLabelPPR", 1);

            OAViewObject templDtlVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
                
            OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
                    OARow cmnVORow = (OARow)cmnVO.first();

            RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
            rsi.reset();

            while (rsi.hasNext()) {
                Row templRow = rsi.next();                      
                templRow.setAttribute("MiscEpFlag", cmnVORow.getAttribute("MiscEPFlag") );

            }
            myAppsLog.write("ODEBillAMImpl", "XXOD:End handleMiscEPLabelPPR", 1);

        }  //end of handling tax, freight and misc totals... 3March2017
        
        
        
        

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
        utl.log("Inside ODEBillTxtAMImpl: defaultEmail");
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
        utl.log("Inside ODEBillTxtAMImpl: defaultFTP");
        OAViewObject transVO = 
            (OAViewObject)findViewObject("ODEBillTransmissionVO");
        OARow transRow = (OARow)transVO.first();
        utl.log("Inside ODEBillTxtAMImpl: defaultFTP: transRow:" + 
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
        utl.log("Inside ODEBillTxtAMImpl: nullEmail");

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
        utl.log("Inside ODEBillTxtAMImpl: nullFTP");

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
        utl.log("Inside ODEBillTxtAMImpl: nullCD");

        OAViewObject transVO = 
            (OAViewObject)findViewObject("ODEBillTransmissionVO");
        OARow transRow = (OARow)transVO.first();

        transRow.setAttribute("CdFileLocation", null);
        transRow.setAttribute("CdSendToAddress", null);
        transRow.setAttribute("Comments", null);

    }


    public void stdPPRHandle() {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillTxtAMImpl: stdPPRHandle");

        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", "XXOD: start stdPPRHandle", 1);

        OAViewObject mainVO = 
            (OAViewObject)this.findViewObject("ODEBillMainVO");
        OARow mainRow = (OARow)mainVO.first();
        String custDocId = null;
        String stdContLvl = null;
        if (mainRow != null) {
            stdContLvl = (String)mainRow.getAttribute("Attribute1");
            custDocId = mainRow.getAttribute("CustDocId").toString();
        }

        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD: stdPPRHandle stdContLvl:" + stdContLvl, 1);
        // deleteTemplVO();
        // populateStdVO(custDocId, stdContLvl);
        //        changeSelStdVO(custDocId, stdContLvl);

    } // End stdPPRHandle()

    public void deleteTemplVO() {
        ODUtil utl = new ODUtil(this);
        utl.log("********Inside deleteTemplVO");
        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
        OARow templDelRow = (OARow)templDtlVO.first();
        while (templDtlVO.getRowCount() > 0) {
            templDelRow.remove();
            templDelRow = (OARow)templDtlVO.next();
        }

    } //End deleteTemplVO(OAViewObject templDtlVO)

    public void handleSubTotalFieldAliasPPR(String sEnableExcelGrouping) {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillTxtAMImpl: handleSubTotalFieldAliasPPR");
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        if ("Y".equalsIgnoreCase(sEnableExcelGrouping)) {
            PPRRow.setAttribute("EnableXlsSubtotal", Boolean.TRUE);
        } else {
            PPRRow.setAttribute("EnableXlsSubtotal", Boolean.FALSE);
        }

    }

    public String handleTransPPR() {
        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillTxtAMImpl: handleTransPPR");
        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        OAViewObject mainVO = (OAViewObject)this.getODEBillMainVO();
        OARow mainRow = (OARow)mainVO.first();

        String transmissionType = null;
        if (mainRow != null)
            transmissionType = 
                    (String)mainRow.getAttribute("EbillTransmissionType");

        utl.log("Inside ODEBillTxtAMImpl: handleTransPPR: Transmission Type:" + 
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

    //Defaulting values for transmission fields

    public void defaultTrans(String emailSubj, String emailStdMsg, 
                             String emailSign, String emailStdDisc, 
                             String emailSplInst, String ftpEmailSubj, 
                             String ftpEmailCont, String ftpNotiFileTxt, 
                             String ftpNotiEmailTxt) {

        ODUtil utl = new ODUtil(this);
        utl.log("Inside ODEBillTxtAMImpl: defaultTrans");

        OAViewObject mainVO = (OAViewObject)this.getODEBillMainVO();
        OARow mainRow = (OARow)mainVO.first();

        String transmissionType = null;
        String custDocId = null;

        if (mainRow != null) {
            transmissionType = 
                    (String)mainRow.getAttribute("EbillTransmissionType");
            custDocId = mainRow.getAttribute("CustDocId").toString();
        }

        utl.log("Inside ODEBillTxtAMImpl: defaultTrans: Transmission Type:" + 
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


    public void initCommonVO() {

        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();

        if (cmnVO != null) {
            if (cmnVO.getRowCount() == 0) {
                cmnVO.setMaxFetchSize(-1);
                cmnVO.executeQuery();
                cmnVO.insertRow(cmnVO.createRow());
            }
            OARow cmnVORow = (OARow)cmnVO.first();
            cmnVORow.setAttribute("RowKey", new Number(1));

            cmnVORow.setAttribute("IncludeLabelTrl", "Y");


        }


    } // End initCoVO()

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
                        "Inside ODEBillTxtAMImpl: addDefaultFileNames" + 
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
       // fileNameRow1.setAttribute("FieldId", new Number(20032)); //new Number(10003));
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
        //fileNameRow2.setAttribute("FieldId", new Number(20032)); //new Number(10118));
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
            //fileNameRow4.setAttribute("FieldId", new Number(20032));  //new Number(10032));
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
        //fileNameRow3.setAttribute("FieldId", new Number(20036)); //new Number(10007));
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
            //fileNameRow5.setAttribute("FieldId", new Number(20032)); //new Number(10023));
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
            //fileNameRow6.setAttribute("FieldId", new Number(20034)); //new Number(10005));
             fileNameRow6.setAttribute("FieldId", new Number(10005));
            fileNameVO.insertRow(fileNameRow6);
        }

    } //End addFileName(String custDocId )

    //Method to insert a new row for Non Standard template when user clicks on Add Field button.

    public void addDtlField(String custDocId) {
        OADBTransaction transaction = this.getOADBTransaction();
        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();

        OAViewObject DtlVO = (OAViewObject)this.getODEBillTemplDtlTxtVO();
        DtlVO.last();
        DtlVO.next();
        OARow DtlRow = (OARow)DtlVO.createRow();
        DtlRow.setAttribute("EblTemplId", 
                            transaction.getSequenceValue("XX_CDH_EBL_TEMPL_DTL_TXT_S"));
        DtlRow.setAttribute("CustDocId", custDocId);
        String sSeq = getSequence("CONCAT", "DTL");
        DtlRow.setAttribute("Seq", sSeq);

        DtlRow.setAttribute("IncludeHeader", 
                            cmnVORow.getAttribute("IncludeHdrLabelDtl"));
        //   DtlRow.setAttribute("RepeatHeader", 
        //                     cmnVORow.getAttribute("RepeatHdrLabelDtl"));
         DtlRow.setAttribute("Rownumber",1);//Added by Reddy Sekhar on 27 Jul 2017 #Defect 41307
        DtlRow.setAttribute("Attribute20", "Y");
        
        // Bhagwan 29-MAR-2017
         DtlRow.setAttribute("RepeatTotalFlag", 
                             cmnVORow.getAttribute("RepeatTotalHdrLabelDtl"));
        DtlRow.setAttribute("TaxUpFlag", 
                               cmnVORow.getAttribute("TaxUPFlag"));
                              
        DtlRow.setAttribute("FreightUpFlag", 
                              cmnVORow.getAttribute("FreightUPFlag"));
                              
        DtlRow.setAttribute("MiscUpFlag", 
                              cmnVORow.getAttribute("MiscUPFlag"));                  
                              
        DtlRow.setAttribute("TaxEpFlag", 
                              cmnVORow.getAttribute("TaxEPFlag"));  
        
        DtlRow.setAttribute("FreightEpFlag", 
                              cmnVORow.getAttribute("FreightEPFlag"));
                              
        DtlRow.setAttribute("MiscEpFlag", 
                              cmnVORow.getAttribute("MiscEPFlag"));
//        //Added by Bhagwan Rao  added on 7 Jul 2017 for Defect #40174                      
//        DtlRow.setAttribute("Attribute18", 
//                              cmnVORow.getAttribute("AbsoluteValueHdrFlag1"));                    
                              
       
        
		//Added by Bhagwan Rao  added on 27 Jul 2017 for Defect #40174                      
         DtlRow.setAttribute("AbsoluteFlag", 
                               cmnVORow.getAttribute("AbsoluteValueHdrFlag1")); 
                               
         DtlRow.setAttribute("DcIndicator", 
                               cmnVORow.getAttribute("DebitCreditDtlFlag"));

        //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----Start                              
                DtlRow.setAttribute("DbCrSeperator", cmnVORow.getAttribute("DebCreTransient"));
                //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----END

        DtlVO.insertRow(DtlRow);
        DtlRow.setNewRowState(DtlRow.STATUS_INITIALIZED);
        

    } //End addNonStdField(String custDocId )

     /**
      * execQuery to return Number
      * Generic method to execute count(1) query
      * @param pQuery -Query string as parameter
      */
     //Added by Bhagwan on 29-MAR-2017
     public Number execQuery(String pQuery)
     {
         ODUtil utl = new ODUtil(this);
         utl.log("execQuery :Begin execQuery");
         OracleCallableStatement ocs=null;
         ResultSet rs;
         OADBTransaction db=this.getOADBTransaction();
         String stmt = pQuery;
         Object obj = (Object)new String("NODATA");
         Number val=new Number(0);
         ocs = (OracleCallableStatement)db.createCallableStatement(stmt,1);

         try
         {
           rs = ocs.executeQuery();
           if (rs.next())
           {
             val = new Number(rs.getLong(1));
           }
           rs.close();
           ocs.close();
         }
         catch(SQLException e)
         {
           utl.log("execQuery:Error:"+ e.toString());
         }
         utl.log("execQuery :End execQuery");
         return val;
     }//execQuery
     
    public void addHdrField(String custDocId) {
        OADBTransaction transaction = this.getOADBTransaction();


        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();


        OAViewObject HdrVO = (OAViewObject)this.getODEBillTemplHdrTxtVO();
        HdrVO.last();
        String sSeq = getSequence("CONCAT", "HDR");

        HdrVO.next();
        OARow HdrRow = (OARow)HdrVO.createRow();


        HdrRow.setAttribute("CustDocId", custDocId);
        HdrRow.setAttribute("RecordType", "LINE");
        HdrRow.setAttribute("EblTemplhdrId", 
                            this.getOADBTransaction().getSequenceValue("XX_CDH_EBL_TEMPL_HDR_TXT_S"));
        HdrRow.setAttribute("Attribute20", "Y");
        HdrRow.setAttribute("Seq", sSeq);
        HdrRow.setAttribute("Rownumber", 1);

        HdrRow.setAttribute("IncludeLabel", 
                            cmnVORow.getAttribute("IncludeLabelHdr"));
                            
        //Added by Bhagwan Rao  added on 7 Jul 2017 for Defect #40174                      
        HdrRow.setAttribute("AbsoluteFlag", 
                              cmnVORow.getAttribute("AbsoluteValueHdrFlag")); 
                              
        HdrRow.setAttribute("DcIndicator", 
                              cmnVORow.getAttribute("DebitCreditHdrFlag")); 
        //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----Start                              
        HdrRow.setAttribute("DbCrSeperator", cmnVORow.getAttribute("DebCreTransientHdr"));
        //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----END                                  
                              
                                    

        HdrVO.insertRow(HdrRow);

        HdrRow.setNewRowState(HdrRow.STATUS_INITIALIZED);
    }


    public void addTrlField(String custDocId) {
        AppsLog myAppsLog = new AppsLog();

        myAppsLog.write("ODEBillTxtAMImpl", "addTrlField Start", 1);

        OADBTransaction transaction = this.getOADBTransaction();


        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();


        OAViewObject TrlVO = (OAViewObject)this.getODEBillTemplTrlTxtVO();
        TrlVO.last();
		
        TrlVO.next();
        OARow TrlRow = (OARow)TrlVO.createRow();

        myAppsLog.write("ODEBillTxtAMImpl", "addTrlField 10.10", 1);
        TrlRow.setAttribute("CustDocId", custDocId);
        TrlRow.setAttribute("RecordType", "LINE");

        myAppsLog.write("ODEBillTxtAMImpl", "addTrlField 10.20", 1);
        TrlRow.setAttribute("EblTempltrlId", 
                            this.getOADBTransaction().getSequenceValue("XX_CDH_EBL_TEMPL_TRL_TXT_S"));


        myAppsLog.write("ODEBillTxtAMImpl", "addTrlField 10.30", 1);
        TrlRow.setAttribute("Attribute20", "Y");
        String sSeq = getSequence("CONCAT", "TRL");


        TrlRow.setAttribute("Seq", sSeq);
        TrlRow.setAttribute("Rownumber", 1);
        TrlRow.setAttribute("IncludeLabel", 
                            cmnVORow.getAttribute("IncludeLabelTrl"));
        //Added by Bhagwan Rao  added on 7 Jul 2017 for Defect #40174                      
        TrlRow.setAttribute("AbsoluteFlag", 
                              cmnVORow.getAttribute("AbsoluteValueHdrFlag2")); 
                              
        TrlRow.setAttribute("DcIndicator", 
                              cmnVORow.getAttribute("DebitCreditTrlFlag"));
        //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----Start
        TrlRow.setAttribute("DbCrSeperator", 
                              cmnVORow.getAttribute("DebCreTransientTrl"));
        //Added by Reddy Sekhar for the Defect# NAIT-29364 on 09 May 2018-----END
        myAppsLog.write("ODEBillTxtAMImpl", "addTrlField Before Insert", 1);

        TrlVO.insertRow(TrlRow);

        myAppsLog.write("ODEBillTxtAMImpl", "addTrlField after insert row", 1);
        TrlRow.setNewRowState(TrlRow.STATUS_INITIALIZED);

        myAppsLog.write("ODEBillTxtAMImpl", "addTrlField End", 1);
    }


    //Method to insert a new split row 

    public void addSplitRow(String custAccountId, String custDocId) {


        AppsLog myAppsLog = new AppsLog();

        OADBTransaction transaction = this.getOADBTransaction();


        OAViewObject splitVO = 
            (OAViewObject)this.findViewObject("ODEBillSplitVO");
        splitVO.last();
        splitVO.next();
        OARow splitVORow = (OARow)splitVO.createRow();
        splitVORow.setAttribute("SplitFieldId", 
                                transaction.getSequenceValue("XX_CDH_EBL_TEMPL_TXT_S"));
        //XX_CDH_EBL_SPLIT_FIELDS_TXT_S
        splitVORow.setAttribute("CustDocId", custDocId);
        splitVORow.setAttribute("CustAccountId", custAccountId);

        splitVO.insertRow(splitVORow);
        splitVORow.setNewRowState(splitVORow.STATUS_INITIALIZED);
    }
    //End addSplit

    public void deleteConfHdr(String pkId) {

        int pkIdPara = Integer.parseInt(pkId);
        OAViewObject confHdrVO = (OAViewObject)this.getODEBillTemplHdrTxtVO();
        ODEBillTemplHdrTxtVORowImpl confHdrVORow = null;
        int fetchedRowCount = confHdrVO.getFetchedRowCount();
        RowSetIterator deleteIter = 
            confHdrVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);
            for (int i = 0; i < fetchedRowCount; i++) {
                confHdrVORow = 
                        (ODEBillTemplHdrTxtVORowImpl)deleteIter.getRowAtRangeIndex(i);
                Number EblTemplhdrIdAttr = 
                    (Number)confHdrVORow.getAttribute("EblTemplhdrId");
                if (EblTemplhdrIdAttr.compareTo(pkIdPara) == 0) {
                    confHdrVORow.remove();
                    confHdrVO.reset();
                    break;
                }
            }
        }
        deleteIter.closeRowSetIterator();
    }

    public void deleteConfDtl(String pkId) {

        int pkIdPara = Integer.parseInt(pkId);
        OAViewObject confDtlVO = (OAViewObject)this.getODEBillTemplDtlTxtVO();
        ODEBillTemplDtlTxtVORowImpl confDtlVORow = null;
        int fetchedRowCount = confDtlVO.getFetchedRowCount();
        RowSetIterator deleteIter = 
            confDtlVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);
            for (int i = 0; i < fetchedRowCount; i++) {
                confDtlVORow = 
                        (ODEBillTemplDtlTxtVORowImpl)deleteIter.getRowAtRangeIndex(i);
                Number EblTempldtlIdAttr = 
                    (Number)confDtlVORow.getAttribute("EblTemplId");
                if (EblTempldtlIdAttr.compareTo(pkIdPara) == 0) {
                    confDtlVORow.remove();
                    confDtlVO.reset();
                    break;
                }
            }
        }
        deleteIter.closeRowSetIterator();
    }

    public void deleteConfTrl(String pkId) {

        int pkIdPara = Integer.parseInt(pkId);
        OAViewObject confTrlVO = (OAViewObject)this.getODEBillTemplTrlTxtVO();
        ODEBillTemplTrlTxtVORowImpl confTrlVORow = null;
        int fetchedRowCount = confTrlVO.getFetchedRowCount();
        RowSetIterator deleteIter = 
            confTrlVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);
            for (int i = 0; i < fetchedRowCount; i++) {
                confTrlVORow = 
                        (ODEBillTemplTrlTxtVORowImpl)deleteIter.getRowAtRangeIndex(i);
                Number EblTempltrlIdAttr = 
                    (Number)confTrlVORow.getAttribute("EblTempltrlId");
                if (EblTempltrlIdAttr.compareTo(pkIdPara) == 0) {
                    confTrlVORow.remove();
                    confTrlVO.reset();
                    break;
                }
            }
        }
        deleteIter.closeRowSetIterator();
    }

    public void deleteSplit(String splitFieldId) {

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");


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
				if (ocs != null) { ocs.close(); }
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

    // To validate eBill main details and save.

    public void applyMain(String deliveryMethod) {


        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:validateMain", 1);
        validateMain();

        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:validateTransmission", 1);
        validateTransmission();


        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:validateContacts", 1);
        validateContacts();

        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:validateFileName", 1);
        validateFileName();

        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:validateTemplDtl", 1);
        validateTemplDtl();

        try {
            getTransaction().setClearCacheOnCommit(false);
            getTransaction().commit();
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
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
        utl.log("Inside ODEBillTxtAMImpl: deleteUncheckedStdFields: Rowcount:" + 
                templDtlVO.getRowCount());
        OARow templDelRow = (OARow)templDtlVO.first();

        for (int i = templDtlVO.getRowCount(); i != 0; i--) {
            utl.log("Inside ODEBillTxtAMImpl: deleteUncheckedStdFields: i: " + 
                    i);
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
                " BEGIN " + " :1 :=  XX_CDH_EBL_VALIDATE_TXT_PKG.VALIDATE_FINAL( p_cust_doc_id              =>:2" + 
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
				if (oraclecallablestatement != null) {  oraclecallablestatement.close(); }
				if (errRS != null) {  errRS.close(); }
				if (errCall != null) {  errCall.close(); }
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
            //Updated by Bhagwan on 2Feb2017
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
        utl.log("Inside ODEBillTxtAMImpl: requery: ");

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
        templDtlVO.executeQuery();
    }

    public String getFieldName(String pkId, String type) {

        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD: getFieldName pkId:" + pkId + "   type:" + type, 
                        1);

		OracleCallableStatement call = null;
		ResultSet rs = null;
        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            String stmt = "";

            if ("HDR".equals(type))
                stmt = 
"SELECT label FROM XX_CDH_EBL_TEMPL_HDR_TXT WHERE ebl_templhdr_id = " + pkId;
            else if ("DTL".equals(type))
                stmt = 
"SELECT label FROM XX_CDH_EBL_TEMPL_DTL_TXT WHERE ebl_templ_id = " + pkId;
            else if ("TRL".equals(type))
                stmt = 
"SELECT label FROM XX_CDH_EBL_TEMPL_TRL_TXT WHERE ebl_templtrl_id = " + pkId;

            call = 
                (OracleCallableStatement)oadbtransactionimpl.createCallableStatement(stmt, 
                                                                                     -1);
            rs = (OracleResultSet)call.executeQuery();

            String fieldName = null;
            if (rs.next())
                fieldName = rs.getString("label");
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


    public String getFieldName(String fieldId) {
        String fieldName = "EMPTY";
        OAViewObject fieldsVO = 
            (OAViewObject)this.getODEBillFileFieldParamPVO();
        //(OAViewObject)this.getODEBillConfigHdrFieldNamesPVO();
        RowSetIterator rsi = fieldsVO.createRowSetIterator("rowsRSI");
        rsi.reset();
        while (rsi.hasNext()) {
            Row fieldsVORow = rsi.next();
            if (fieldId.equals(fieldsVORow.getAttribute("FieldId"))) {
                if (fieldsVORow.getAttribute("FieldName") != null)
                    fieldName = 
                            fieldsVORow.getAttribute("FieldName").toString();
            }
        }
        return fieldName;
    }


    /* Added for M)D 4B R3 */

    public String getConcFieldName(String fieldId) {

        ODUtil utl = new ODUtil(this);
        String fieldName = "EMPTY";
		OracleCallableStatement call = null;
		ResultSet rs = null;
        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            String stmt = 
                "SELECT conc_field_label FROM xx_cdh_ebl_concat_fields_txt WHERE conc_field_id = " + 
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
		OracleCallableStatement call = null;
		ResultSet rs = null;
        try {
            OADBTransactionImpl oadbtransactionimpl = 
                (OADBTransactionImpl)getDBTransaction();
            String stmt = 
                "select substr (split_field1_label||split_field2_label||split_field3_label||split_field4_label||split_field4_label||split_field6_label,1,20) split_field_label\n" + 
                " from XX_CDH_EBL_split_fields_txt WHERE split_field_id = " + 
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
    
    public OAViewObjectImpl getODEBillAggrFieldPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillAggrFieldPVO");
    } */
    protected

    /* This method deletes the exisiting error codes for the cust_doc_id, calls the XX_CDH_EBL_VALIDATE_PKG.VALIDATE_EBL_MAIN
   * to valdiate the eBill main details and raise exception if any validation fails */

    void validateMain() {

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
               //Commented by Bhagwan 3Feb2016
               // oraclecallablestatement.execute();
                oraclecallablestatement.executeUpdate();
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
                (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
            OARow tempHeaderRow = (OARow)tempHeaderVO.first();


            OAViewObject templDtlVO = null;
            OARow templDtlRow = null;

            templDtlVO = 
                    (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");


            ArrayList exceptions = new ArrayList();
            templDtlRow = (OARow)templDtlVO.first();

            if (templDtlRow != null)
                custDocId = templDtlRow.getAttribute("CustDocId").toString();

            for (int i = 0; i < templDtlVO.getRowCount(); i++) {
                String s = 
                    " BEGIN " + "   :1 :=  XX_CDH_EBL_VALIDATE_TXT_PKG.VALIDATE_EBL_TEMPL_DTL( p_cust_account_id => :2" + 
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
                oraclecallablestatement.setString(3, "");
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
     * Container's getter for ODEBillAggrFunPVO

    public OAViewObjectImpl getODEBillAggrFunPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillAggrFunPVO");
    } */

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
     * Container's getter for ODEBillNonStdVO
     */
    /*
	public OAViewObjectImpl getODEBillNonStdVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillNonStdVO");
    }
*/


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


    /**Container's getter for ODEBillConcatenateVO
     */
    public OAViewObjectImpl getODEBillConcatenateDtlVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillConcatenateDtlVO");
    }

    /**Container's getter for ODEBillConcatFieldsPVO
     */
    public OAViewObjectImpl getODEBillConcatFieldsPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillConcatFieldsPVO");
    }

    /**Container's getter for ODEBillSplitFieldsPVO
     */
    public

    OAViewObjectImpl getODEBillSplitFieldsPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSplitFieldsPVO");
    }


    public void handleSplitTypePPR(String sSplitFieldId) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", 
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
                myAppsLog.write("ODEBillTxtAMImpl", "XXOD:sSplit " + sSplit, 
                                1);
                if (("FP".equalsIgnoreCase(sSplit)) || 
                    ("FL".equalsIgnoreCase(sSplit))) {
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


    public OAViewObjectImpl getODEBillSplitVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSplitVO");
    }


    public OAViewObjectImpl getODEBillSplitDelimiterByPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSplitDelimiterByPVO");
    }


    public void refreshTemplDtlVOOnChecking(OAViewObject templDtlVO, 
                                            OAViewObject concatFieldsVO, 
                                            OAViewObject splitFieldsVO) {

        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("fnd.common.WebAppsContext", 
                        "XXOD: start refreshTemplDtlVOOnChecking", 1);

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
                        "XXOD: end refreshTemplDtlVOOnChecking", 1);
    }


    public void renderConcatSplit(String sConcatSplit) {
        //Logic for hiding region

        OAViewObject PPRVO = (OAViewObject)this.getODEBillPPRVO();
        OARow PPRRow = (OARow)PPRVO.first();

        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:sConcatSplit " + sConcatSplit, 1);

        if ("Y".equalsIgnoreCase(sConcatSplit)) {
            PPRRow.setAttribute("ConcatSplit", Boolean.TRUE);
            PPRRow.setAttribute("ConcatSplitMsg", Boolean.FALSE);
        } else {
            PPRRow.setAttribute("ConcatSplit", Boolean.FALSE);
            PPRRow.setAttribute("ConcatSplitMsg", Boolean.TRUE);
        }
    }


    /**Container's getter for ODEBillSubTotalFieldsVO
     */
    public void saveConcatenate(String custDocId, String custAccountId) {


        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:Start saveConcatenate ", 1);


        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");

        OAViewObject concVO = this.getODEBillConcatenateDtlVO();

        //Logic for fetching concatenate field id into array
        java.util.ArrayList arrConcList = new java.util.ArrayList();
        concVO.reset();
        while (concVO.hasNext()) {
            OARow concRow = (OARow)concVO.next();
            myAppsLog.write("ODEBillTxtAMImpl", 
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

            myAppsLog.write("ODEBillTxtAMImpl", 
                            "XXOD:sConcField " + sConcField + " sFlag:" + 
                            sFlag, 1);

            if ("Y".equals(sFlag)) {
                updConcatRow(concRow, templDtlVO, sConcField);
            } else
                addConcatRow(concRow, custDocId, custAccountId, arrConcList, 
                             "DTL");


        }
        //End -For each concatenate row, logic to update/add row to configuration details


        //Logic for Handling Hdr Concatenate VO
        OAViewObject templHdrVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");

        OAViewObject concHdrVO = this.getODEBillConcatenateHdrVO();

        //Logic for fetching concatenate field id into array
        java.util.ArrayList arrConcHdrList = new java.util.ArrayList();
        concHdrVO.reset();
        while (concHdrVO.hasNext()) {
            OARow concHdrRow = (OARow)concHdrVO.next();
            arrConcHdrList.add(concHdrRow.getAttribute("ConcFieldId").toString());
        }
        //End - Logic for fetching concatenate field id into array

        //For each concatenate row, logic to update/add row to configuration details
        concHdrVO.reset();
        while (concHdrVO.hasNext()) {


            OARow concHdrRow = (OARow)concHdrVO.next();


            String sConcHdrField = null;
            sConcHdrField = concHdrRow.getAttribute("ConcFieldId").toString();
            String sHdrFlag = 
                chkIfExistsInTemplDtlVO(templHdrVO, sConcHdrField, "CONCAT");

            myAppsLog.write("ODEBillTxtAMImpl", 
                            "XXOD:sConcHdrField " + sConcHdrField + 
                            " sHdrFlag:" + sHdrFlag, 1);

            if ("Y".equals(sHdrFlag)) {
                updConcatRow(concHdrRow, templHdrVO, sConcHdrField);
            } else
                addConcatRow(concHdrRow, custDocId, custAccountId, 
                             arrConcHdrList, "HDR");


        }
        //End -For each concatenate row, logic to update/add row to configuration details
        //Logic for Handling Hdr Concatenate VO


        //Logic for Handling Trl Concatenate VO
        OAViewObject templTrlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");

        OAViewObject concTrlVO = this.getODEBillConcatenateTrlVO();

        //Logic for fetching concatenate field id into array
        java.util.ArrayList arrConcTrlList = new java.util.ArrayList();
        concTrlVO.reset();
        while (concTrlVO.hasNext()) {
            OARow concTrlRow = (OARow)concTrlVO.next();
            arrConcTrlList.add(concTrlRow.getAttribute("ConcFieldId").toString());
        }
        //End - Logic for fetching concatenate field id into array

        //For each concatenate row, logic to update/add row to configuration details
        concTrlVO.reset();
        while (concTrlVO.hasNext()) {


            OARow concTrlRow = (OARow)concTrlVO.next();


            String sConcTrlField = null;
            sConcTrlField = concTrlRow.getAttribute("ConcFieldId").toString();
            String sTrlFlag = 
                chkIfExistsInTemplDtlVO(templTrlVO, sConcTrlField, "CONCAT");

            myAppsLog.write("ODEBillTxtAMImpl", 
                            "XXOD:sConcTrlField " + sConcTrlField + 
                            " sTrlFlag:" + sTrlFlag, 1);

            if ("Y".equals(sTrlFlag)) {
                updConcatRow(concTrlRow, templTrlVO, sConcTrlField);
            } else
                addConcatRow(concTrlRow, custDocId, custAccountId, 
                             arrConcTrlList, "TRL");


        }
        //End -For each concatenate row, logic to update/add row to configuration details
        //Logic for Handling Trl Concatenate VO

    } // End saveConcatenate


    /* Logic for adding new row in concatenate VO*/

    public void addConcRowDtl(String custAccountId, String custDocId) {


        AppsLog myAppsLog = new AppsLog();

        OADBTransaction transaction = this.getOADBTransaction();


        OAViewObject concatenateVO = 
            (OAViewObject)this.findViewObject("ODEBillConcatenateDtlVO");
        concatenateVO.last();


        concatenateVO.next();
        OARow concatenateVORow = (OARow)concatenateVO.createRow();
        concatenateVORow.setAttribute("ConcFieldId", 
                                      transaction.getSequenceValue("XX_CDH_EBL_TEMPL_TXT_S")); //XX_CDH_EBL_CONCAT_FIELDS_TXT_S
        concatenateVORow.setAttribute("CustDocId", custDocId);
        concatenateVORow.setAttribute("CustAccountId", custAccountId);
        concatenateVORow.setAttribute("Tab", "D");


        concatenateVO.insertRow(concatenateVORow);
        concatenateVORow.setNewRowState(concatenateVORow.STATUS_INITIALIZED);


    } //End addConcRow


    /* Logic for adding new row in concatenate VO*/

    public void addConcRowHdr(String custAccountId, String custDocId) {


        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:addConcRowHdr start", 1);

        OADBTransaction transaction = this.getOADBTransaction();


        OAViewObject concatenateVO = 
            (OAViewObject)this.findViewObject("ODEBillConcatenateHdrVO");
        concatenateVO.last();


        concatenateVO.next();
        OARow concatenateVORow = (OARow)concatenateVO.createRow();
        concatenateVORow.setAttribute("ConcFieldId", 
                                      transaction.getSequenceValue("XX_CDH_EBL_TEMPL_TXT_S")); //XX_CDH_EBL_CONCAT_FIELDS_TXT_S
        concatenateVORow.setAttribute("CustDocId", custDocId);
        concatenateVORow.setAttribute("CustAccountId", custAccountId);
        concatenateVORow.setAttribute("Tab", "H");

        concatenateVO.insertRow(concatenateVORow);
        concatenateVORow.setNewRowState(concatenateVORow.STATUS_INITIALIZED);

        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:addConcRowHdr end", 1);

    } //End addConcRow


    /* Logic for adding new row in concatenate VO*/

    public void addConcRowTrl(String custAccountId, String custDocId) {


        AppsLog myAppsLog = new AppsLog();

        OADBTransaction transaction = this.getOADBTransaction();


        OAViewObject concatenateVO = 
            (OAViewObject)this.findViewObject("ODEBillConcatenateTrlVO");
        concatenateVO.last();


        concatenateVO.next();
        OARow concatenateVORow = (OARow)concatenateVO.createRow();
        concatenateVORow.setAttribute("ConcFieldId", 
                                      transaction.getSequenceValue("XX_CDH_EBL_TEMPL_TXT_S")); //XX_CDH_EBL_CONCAT_FIELDS_TXT_S
        concatenateVORow.setAttribute("CustDocId", custDocId);
        concatenateVORow.setAttribute("CustAccountId", custAccountId);
        concatenateVORow.setAttribute("Tab", "T");

        concatenateVO.insertRow(concatenateVORow);
        concatenateVORow.setNewRowState(concatenateVORow.STATUS_INITIALIZED);


    } //End addConcRow

    public void deleteConcatHdr(String concFieldId) {

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");

        int concFieldIdPara = Integer.parseInt(concFieldId);


        OAViewObject concatenateVO = 
            (OAViewObject)this.findViewObject("ODEBillConcatenateHdrVO");
        ODEBillConcatenateHdrVORowImpl concatenateVORow = null;

        int fetchedRowCount = concatenateVO.getFetchedRowCount();

        RowSetIterator deleteIter = 
            concatenateVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);

            for (int i = 0; i < fetchedRowCount; i++) {
                concatenateVORow = 
                        (ODEBillConcatenateHdrVORowImpl)deleteIter.getRowAtRangeIndex(i);
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


    public void deleteConcatDtl(String concFieldId) {

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");

        int concFieldIdPara = Integer.parseInt(concFieldId);


        OAViewObject concatenateVO = 
            (OAViewObject)this.findViewObject("ODEBillConcatenateDtlVO");
        ODEBillConcatenateDtlVORowImpl concatenateVORow = null;

        int fetchedRowCount = concatenateVO.getFetchedRowCount();

        RowSetIterator deleteIter = 
            concatenateVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);

            for (int i = 0; i < fetchedRowCount; i++) {
                concatenateVORow = 
                        (ODEBillConcatenateDtlVORowImpl)deleteIter.getRowAtRangeIndex(i);
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


    public void deleteConcatTrl(String concFieldId) {

        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");

        int concFieldIdPara = Integer.parseInt(concFieldId);


        OAViewObject concatenateVO = 
            (OAViewObject)this.findViewObject("ODEBillConcatenateTrlVO");
        ODEBillConcatenateTrlVORowImpl concatenateVORow = null;

        int fetchedRowCount = concatenateVO.getFetchedRowCount();

        RowSetIterator deleteIter = 
            concatenateVO.createRowSetIterator("deleteIter");

        if (fetchedRowCount > 0) {
            deleteIter.setRangeStart(0);
            deleteIter.setRangeSize(fetchedRowCount);

            for (int i = 0; i < fetchedRowCount; i++) {
                concatenateVORow = 
                        (ODEBillConcatenateTrlVORowImpl)deleteIter.getRowAtRangeIndex(i);
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
                             java.util.ArrayList arrConcList, String sType) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("addConcatRow:", 
                        "XXOD: adding concatenate row to  configuration details ", 
                        1);
        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();

        if (sType.equals("DTL")) {
            OAViewObject templDtlVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
            //templDtlVO.reset();

            templDtlVO.last();
            templDtlVO.next();

            OARow templRow = (OARow)templDtlVO.createRow();
            templRow.setAttribute("CustDocId", custDocId);
            //templRow.setAttribute("CustAccountId", custAccountId);
            templRow.setAttribute("RecordType", "LINE");
            templRow.setAttribute("EblTemplId", 
                                  this.getOADBTransaction().getSequenceValue("XX_CDH_EBL_TEMPL_DTL_TXT_S"));
            templRow.setAttribute("FieldId", 
                                  concRow.getAttribute("ConcFieldId"));
            templRow.setAttribute("Label", 
                                  concRow.getAttribute("ConcFieldLabel"));
            templRow.setAttribute("Attribute1", "Y");
            templRow.setAttribute("Attribute20", "Y");
            
            //  templRow.setAttribute("IncludeHeader", "Y");
            //  templRow.setAttribute("RepeatHeader", "Y");
             templRow.setAttribute("Rownumber",1);//Added by Reddy Sekhar on 07 Jul 2017 #Defect 41307
            String sSeq = getSequence("CONCAT", "DTL");
            templRow.setAttribute("Seq", sSeq);
            templRow.setAttribute("IncludeHeader", 
                                  cmnVORow.getAttribute("IncludeHdrLabelDtl"));
            templRow.setAttribute("AbsoluteFlag", cmnVORow.getAttribute("AbsoluteValueHdrFlag1") );
                        
            templRow.setAttribute("DcIndicator", cmnVORow.getAttribute("DebitCreditDtlFlag") );
            //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---Start
            templRow.setAttribute("DbCrSeperator", cmnVORow.getAttribute("DebCreTransient") );
            //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---End
            templDtlVO.last();
        } else if (sType.equals("HDR")) {

            OAViewObject HdrVO = (OAViewObject)this.getODEBillTemplHdrTxtVO();
            HdrVO.last();
            HdrVO.next();
            OARow HdrRow = (OARow)HdrVO.createRow();


            HdrRow.setAttribute("CustDocId", custDocId);
            HdrRow.setAttribute("RecordType", "LINE");
            HdrRow.setAttribute("EblTemplhdrId", 
                                this.getOADBTransaction().getSequenceValue("XX_CDH_EBL_TEMPL_HDR_TXT_S"));
            HdrRow.setAttribute("Attribute20", "Y");

            String sSeq = getSequence("CONCAT", "HDR");

            HdrRow.setAttribute("Seq", sSeq);
            HdrRow.setAttribute("Rownumber", 1);

            HdrRow.setAttribute("IncludeLabel", 
                                cmnVORow.getAttribute("IncludeLabelHdr"));
                                
            HdrRow.setAttribute("AbsoluteFlag", cmnVORow.getAttribute("AbsoluteValueHdrFlag") );
                        
            HdrRow.setAttribute("DcIndicator", cmnVORow.getAttribute("DebitCreditHdrFlag") );

            HdrRow.setAttribute("FieldId", 
                                concRow.getAttribute("ConcFieldId"));
            HdrRow.setAttribute("Label", 
                                concRow.getAttribute("ConcFieldLabel"));
            //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---Start
            HdrRow.setAttribute("DbCrSeperator", 
                                cmnVORow.getAttribute("DebCreTransientHdr"));
            //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---Start
            
            HdrVO.insertRow(HdrRow);
        } else if (sType.equals("TRL")) {

            OAViewObject TrlVO = (OAViewObject)this.getODEBillTemplTrlTxtVO();
            TrlVO.last();
            TrlVO.next();
            OARow TrlRow = (OARow)TrlVO.createRow();

            TrlRow.setAttribute("CustDocId", custDocId);
            TrlRow.setAttribute("RecordType", "LINE");

            TrlRow.setAttribute("EblTempltrlId", 
                                this.getOADBTransaction().getSequenceValue("XX_CDH_EBL_TEMPL_TRL_TXT_S"));


            TrlRow.setAttribute("Attribute20", "Y");

            String sSeq = getSequence("CONCAT", "TRL");
            TrlRow.setAttribute("Seq", sSeq);
            TrlRow.setAttribute("Rownumber", 1);
            TrlRow.setAttribute("IncludeLabel", 
                                cmnVORow.getAttribute("IncludeLabelTrl"));
            TrlRow.setAttribute("AbsoluteFlag", cmnVORow.getAttribute("AbsoluteValueHdrFlag2") );
                        
            TrlRow.setAttribute("DcIndicator", cmnVORow.getAttribute("DebitCreditTrlFlag") );
            TrlRow.setAttribute("FieldId", 
                                concRow.getAttribute("ConcFieldId"));
            TrlRow.setAttribute("Label", 
                                concRow.getAttribute("ConcFieldLabel"));
            //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---Start
            TrlRow.setAttribute("DbCrSeperator", cmnVORow.getAttribute("DebCreTransientTrl") );
            //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---End


            TrlVO.insertRow(TrlRow);
        }


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
        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:Start saveSplit ", 1);


        java.util.ArrayList arrSplitList = new java.util.ArrayList();


        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");

        OAViewObject splitVO = this.getODEBillSplitVO();
        splitVO.reset();

        while (splitVO.hasNext()) {
            OARow splitRow = (OARow)splitVO.next();
            arrSplitList.add(splitRow.getAttribute("SplitFieldId").toString());
            
        }
        myAppsLog.write("ODEBillTxtAMImpl", 
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
                
            myAppsLog.write("ODEBillTxtAMImpl", 
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


            myAppsLog.write("ODEBillTxtAMImpl", 
                            "***XXOD:sSplitField1Label " + sSplitField1Label, 
                            1);

            myAppsLog.write("ODEBillTxtAMImpl", 
                            "***XXOD:sSplitField2Label " + sSplitField2Label, 
                            1);

            myAppsLog.write("ODEBillTxtAMImpl", 
                            "***XXOD:sSplitField3Label " + sSplitField3Label, 
                            1);

            myAppsLog.write("ODEBillTxtAMImpl", 
                            "***XXOD:sSplitField4Label " + sSplitField4Label, 
                            1);
            myAppsLog.write("ODEBillTxtAMImpl", 
                            "***XXOD:sSplitField5Label " + sSplitField5Label, 
                            1);

            myAppsLog.write("ODEBillTxtAMImpl", 
                            "***XXOD:sSplitField6Label " + sSplitField6Label, 
                            1);


            //if split field id already exists in configuration details
            if ("Y".equals(sFlag)) {

                myAppsLog.write("ODEBillTxtAMImpl", 
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

                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sBaseFieldId:" + sBaseFieldId, 1);


                    //if basefiedl id is not null then that will be split row
                    if ((sBaseFieldId != null) && (!"".equals(sBaseFieldId))) {

                        myAppsLog.write("ODEBillTxtAMImpl", 
                                        "***XXOD:Is split row ", 1);

                        if (templRow.getAttribute("SplitFieldId") != null)
                            sFieldId = 
                                    templRow.getAttribute("SplitFieldId").toString();

                        if (templRow.getAttribute("Label") != null)
                            sLabel = templRow.getAttribute("Label").toString();

                        myAppsLog.write("ODEBillTxtAMImpl", 
                                        "***XXOD:******** sLabel" + sLabel, 1);

                        if (templRow.getAttribute("FieldId") != null)
                            sDetailFieldId = 
                                    templRow.getAttribute("FieldId").toString();

                        //if it is split row matching to splitvo
                        //Logic for removing SPLIT ROWs from Configuration Details
                        if (sSplitField.equals(sFieldId)) {
                            //If basefiedl id is not matching row shoudl be removed
                            if (!sBaseFieldId.equals(sSplitBaseField)) {
                                myAppsLog.write("ODEBillTxtAMImpl", 
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
                                    myAppsLog.write("ODEBillTxtAMImpl", 
                                                    "***XXOD:sLabel" + sLabel + 
                                                    " not matching.Removing row from config details ", 
                                                    1);
                                    templRow.remove();
                                }


                                //Start - For adding / updating configuration details split row
                                if ((sSplitField1Label != null) && 
                                    (!"".equals(sSplitField1Label))) {
                                    if (sLabel.equals(sSplitField1Label)) {
                                        myAppsLog.write("ODEBillTxtAMImpl:Label1:", 
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
                                        myAppsLog.write("ODEBillTxtAMImpl:Label2:", 
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
                                        myAppsLog.write("ODEBillTxtAMImpl:Label3:", 
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
                                        myAppsLog.write("ODEBillTxtAMImpl:Label4:", 
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
                                        myAppsLog.write("ODEBillTxtAMImpl:Label5:", 
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
                                        myAppsLog.write("ODEBillTxtAMImpl:Label6:", 
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
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField1Label" + 
                                    sSplitField1Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField1Label, arrSplitList);
                }

                if ((sSplitField2Label != null) && 
                    (!"".equals(sSplitField2Label)) && 
                    (!arrSplitLabel.contains(sSplitField2Label))) {
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField2Label" + 
                                    sSplitField2Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField2Label, arrSplitList);
                }

                if ((sSplitField3Label != null) && 
                    (!"".equals(sSplitField3Label)) && 
                    (!arrSplitLabel.contains(sSplitField3Label))) {
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField3Label" + 
                                    sSplitField3Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField3Label, arrSplitList);
                }

                if ((sSplitField4Label != null) && 
                    (!"".equals(sSplitField4Label)) && 
                    (!arrSplitLabel.contains(sSplitField4Label))) {
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField4Label" + 
                                    sSplitField4Label + " adding as new row", 
                                    1);

                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField4Label, arrSplitList);
                }

                if ((sSplitField5Label != null) && 
                    (!"".equals(sSplitField5Label)) && 
                    (!arrSplitLabel.contains(sSplitField5Label))) {

                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField5Label" + 
                                    sSplitField5Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField5Label, arrSplitList);
                }

                if ((sSplitField6Label != null) && 
                    (!"".equals(sSplitField6Label)) && 
                    (!arrSplitLabel.contains(sSplitField6Label))) {

                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField6Label" + 
                                    sSplitField6Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField6Label, arrSplitList);
                }
            }

            //For New Split Field Id - Logic for adding rows into Configuration Details
            if ("N".equals(sFlag)) {

                myAppsLog.write("ODEBillTxtAMImpl", 
                                "***XXOD:sSplitField ID not existing", 1);


                if ((sSplitField1Label != null) && 
                    (!"".equals(sSplitField1Label))) {
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField1Label" + 
                                    sSplitField1Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField1Label, arrSplitList);
                }

                if ((sSplitField2Label != null) && 
                    (!"".equals(sSplitField2Label))) {
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField2Label" + 
                                    sSplitField2Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField2Label, arrSplitList);
                }

                if ((sSplitField3Label != null) && 
                    (!"".equals(sSplitField3Label))) {
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField3Label" + 
                                    sSplitField3Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField3Label, arrSplitList);
                }

                if ((sSplitField4Label != null) && 
                    (!"".equals(sSplitField4Label))) {
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField4Label" + 
                                    sSplitField4Label + " adding as new row", 
                                    1);

                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField4Label, arrSplitList);
                }

                if ((sSplitField5Label != null) && 
                    (!"".equals(sSplitField5Label))) {

                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField5Label" + 
                                    sSplitField5Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField5Label, arrSplitList);
                }

                if ((sSplitField6Label != null) && 
                    (!"".equals(sSplitField6Label))) {

                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "***XXOD:sSplitField6Label" + 
                                    sSplitField6Label + " adding as new row", 
                                    1);
                    addSplitRow(splitRow, custDocId, custAccountId, 
                                sSplitField6Label, arrSplitList);
                }
            }


        }


        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:End saveSplit ", 1);
    } // End saveSplit


    public void addSplitRow(OARow splitRow, String custDocId, 
                            String custAccountId, String sSplitFieldLabel, 
                            java.util.ArrayList arrSplitList) {

        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD: ****************addSplitRow", 1);


        OAViewObject templDtlVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
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
        templRow.setAttribute("RecordType", "LINE");
        templRow.setAttribute("EblTemplId", 
                              this.getOADBTransaction().getSequenceValue("XX_CDH_EBL_TEMPL_DTL_TXT_S"));


        templRow.setAttribute("FieldId", 
                              this.getOADBTransaction().getSequenceValue("XX_CDH_EBL_TEMPL_TXT_S")); //XX_CDH_EBL_SPLIT_FIELDS_TXT_S"));


        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:****new row splitfieldid" + splitRow.getAttribute("SplitFieldId"), 
                        1);

        templRow.setAttribute("SplitFieldId", 
                              splitRow.getAttribute("SplitFieldId"));

        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:****templ new row splitfieldid" + 
                        templRow.getAttribute("SplitFieldId"), 1);

        templRow.setAttribute("Label", sSplitFieldLabel);

        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:****new row splitbasefieldid" + 
                        splitRow.getAttribute("SplitBaseFieldId"), 1);

        templRow.setAttribute("BaseFieldId", 
                              splitRow.getAttribute("SplitBaseFieldId"));
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:****after basefieldid splitfieldid" + 
                        templRow.getAttribute("SplitFieldId"), 1);

        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:****after basefieldid" + templRow.getAttribute("BaseFieldId"), 
                        1);


        templRow.setAttribute("Attribute2", "N");
        templRow.setAttribute("Attribute3", "N");
        templRow.setAttribute("Attribute20", "Y");
        templRow.setAttribute("Rownumber",1);//Added by Reddy Sekhar on 27 Jul 2017 #Defect 41307
        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();
        templRow.setAttribute("IncludeHeader", 
                              cmnVORow.getAttribute("IncludeHdrLabelDtl"));
        templRow.setAttribute("AbsoluteFlag", cmnVORow.getAttribute("AbsoluteValueHdrFlag1") );
                    
        templRow.setAttribute("DcIndicator", cmnVORow.getAttribute("DebitCreditDtlFlag") );
        //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---Start
        templRow.setAttribute("DbCrSeperator", cmnVORow.getAttribute("DebCreTransient") );
        //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---End
        // templRow.setAttribute("RepeatHeader", 
        //                     cmnVORow.getAttribute("RepeatHdrLabelDtl"));

        //templRow.setAttribute("Seq", new Number((i++) * 40));
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:****before getsequence splitfieldid" + 
                        templRow.getAttribute("SplitFieldId"), 1);

        String sSeq = getSequence("SPLIT", "SPLIT");

        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:****after getsequence splitfieldid" + 
                        templRow.getAttribute("SplitFieldId"), 1);
        templRow.setAttribute("Seq", sSeq);

        templRow.setAttribute("Attribute1", "Y");
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:****before row splitfieldid" + 
                        templRow.getAttribute("SplitFieldId"), 1);

        templDtlVO.insertRow(templRow);

        templDtlVO.last();

        templDtlVO.next();

        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD: End****************addSplitRow", 1);

    }


    public String getSequence(String sConfigType, String sType) {

        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", "XXOD: getSequence:" + sConfigType, 
                        1);

        StringBuffer sSeqNum = new StringBuffer();

        OAViewObject templDtlVO = null;
        if ("HDR".equals(sType)) {
            templDtlVO = 
                    (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
        } else if ("DTL".equals(sType)) {
            templDtlVO = 
                    (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
        } else if ("TRL".equals(sType)) {
            templDtlVO = 
                    (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");
        }

        if ("SPLIT".equals(sConfigType))
            templDtlVO = 
                    (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");


        int nSeqMax = 0;


        RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
        rsi.reset();

        while (rsi.hasNext()) {
            Row templDtlRow = rsi.next();
            if (nSeqMax < 
                Integer.parseInt(templDtlRow.getAttribute("Seq").toString()))
                nSeqMax = 
                        Integer.parseInt(templDtlRow.getAttribute("Seq").toString());


        }


        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD: getSequence:sSeqMax" + nSeqMax, 1);

        if ("CONCAT".equals(sConfigType))
            sSeqNum.append(nSeqMax + 10);
        else
            sSeqNum.append(nSeqMax + 10);


        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD: getSequence:sSeqNum" + sSeqNum, 1);

        return sSeqNum.toString();

    }

    private String chkIfExistsInTemplDtlVO(OAViewObject templDtlVO, 
                                           String sFieldId, String sType) {
        String sFlag = "N";


        RowSetIterator rsi = templDtlVO.createRowSetIterator("rowsRSI");
        rsi.reset();


        if ("CONCAT".equals(sType)) {

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


    /**Sample main for debugging Business Components code using the tester.
     */
    public static void main(String[] args) { /* package name */
        /* Configuration Name */launchTester("od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.server", 
                                             "ODEBillTxtAMLocal");
    }

    /**Container's getter for ODEBillTxtHdrFieldsVO
     */
    public OAViewObjectImpl getODEBillTxtHdrFieldsVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillTxtHdrFieldsVO");
    }


    /**Container's getter for ODEBillTxtDtlFieldsVO
     */
    public OAViewObjectImpl getODEBillTxtDtlFieldsVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillTxtDtlFieldsVO");
    }


    /**Container's getter for ODEBillTxtTrlFieldsVO
     */
    public OAViewObjectImpl getODEBillTxtTrlFieldsVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillTxtTrlFieldsVO");
    }


    /**Container's getter for ODEBillConfigDetailsFieldNamesPVO
     */
    public OAViewObjectImpl getODEBillConfigDetailsFieldNamesPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillConfigDetailsFieldNamesPVO");
    }


    /**Container's getter for ODEBillConfigTrlFieldNamesPVO
     */
    public OAViewObjectImpl getODEBillConfigTrlFieldNamesPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillConfigTrlFieldNamesPVO");
    }

    /**Container's getter for ODEBillConfigHdrFieldNamesPVO
     */
    public OAViewObjectImpl getODEBillConfigHdrFieldNamesPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillConfigHdrFieldNamesPVO");
    }


    /**Container's getter for ODEBillConcatenateVO1
     */
    public OAViewObjectImpl getODEBillConcatenateHdrVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillConcatenateHdrVO");
    }

    /**Container's getter for ODEBillConcatenateVO2
     */
    public OAViewObjectImpl getODEBillConcatenateTrlVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillConcatenateTrlVO");
    }


    public void copyToLabel(String fieldId, String pkId, String sTab) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:Start copyToLabel" + pkId + " " + fieldId + " " + 
                        sTab, 1);

        if ("HDR".equals(sTab)) {
            OAViewObject templVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
            RowSetIterator rsi = templVO.createRowSetIterator("rowsRSI");
            rsi.reset();
            while (rsi.hasNext()) {
                Row templRow = rsi.next();


                String sPkId = 
                    templRow.getAttribute("EblTemplhdrId").toString();
                String sFieldId = templRow.getAttribute("FieldId").toString();

                myAppsLog.write("ODEBillTxtAMImpl", "XXOD:sFieldId" + sFieldId, 
                                1);
                String sFieldName = "";
                if (pkId.equals(sPkId)) {


                    OAViewObject fieldsVO = 
                        (OAViewObject)this.getODEBillConfigHdrFieldNamesPVO();
                    RowSetIterator fieldsVOrsi = 
                        fieldsVO.createRowSetIterator("rowsRSI");


                    while (fieldsVOrsi.hasNext()) {
                        Row fieldsVORow = fieldsVOrsi.next();

                        if (sFieldId.equals(fieldsVORow.getAttribute("FieldId"))) {

                            Boolean sFlag = Boolean.FALSE;
                            sFlag = 
                                    (Boolean)fieldsVORow.getAttribute("TranslationField");

                            templRow.setAttribute("NewRow", "EDITED");

                            if (!sFlag) {
                                templRow.setAttribute("NewRow", "ERROR");
                                throw new OAException("XXCRM", 
                                                      "XXOD_EBL_NOTALLOWED");
                            }

                            sFieldName = 
                                    fieldsVORow.getAttribute("FieldName").toString();
                            break;
                        }

                    }
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "XXOD: sFieldName" + sFieldName, 1);
                    if ((sFieldName != null) && !("".equals(sFieldName))) {
                        //if (templRow.getAttribute("Label") == null){
                        templRow.setAttribute("Label", sFieldName);
                        //  }

                    }
                    break;
                }

            }
        } else if ("DTL".equals(sTab)) {
            OAViewObject templVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
            RowSetIterator rsi = templVO.createRowSetIterator("rowsRSI");
            rsi.reset();
            while (rsi.hasNext()) {
                Row templRow = rsi.next();


                String sPkId = templRow.getAttribute("EblTemplId").toString();
                String sFieldId = templRow.getAttribute("FieldId").toString();

                myAppsLog.write("ODEBillTxtAMImpl", "XXOD:sFieldId" + sFieldId, 
                                1);
                String sFieldName = "";
                if (pkId.equals(sPkId)) {


                    OAViewObject fieldsVO = 
                        (OAViewObject)this.getODEBillConfigDetailsFieldNamesPVO();
                    RowSetIterator fieldsVOrsi = 
                        fieldsVO.createRowSetIterator("rowsRSI");


                    while (fieldsVOrsi.hasNext()) {
                        Row fieldsVORow = fieldsVOrsi.next();

                        if (sFieldId.equals(fieldsVORow.getAttribute("FieldId"))) {
                            Boolean sFlag = Boolean.FALSE;
                            sFlag = (Boolean)fieldsVORow.getAttribute("TranslationField");

                            templRow.setAttribute("NewRow", "EDITED");

                            if (!sFlag) {
                                templRow.setAttribute("NewRow", "ERROR");
                                throw new OAException("XXCRM", 
                                                      "XXOD_EBL_NOTALLOWED");
                            }

                            String sRecType = 
                                templRow.getAttribute("RecordType").toString();
                            String sFieldRecType = "";

                            if (fieldsVORow.getAttribute("RecordType") != null)
                                sFieldRecType = 
                                        fieldsVORow.getAttribute("RecordType").toString();
                                        
                            sFieldName = 
                                    fieldsVORow.getAttribute("FieldName").toString();
                                    
                            if (("HDR".equals(sRecType)) && 
                                ("LINE".equals(sFieldRecType))) {
                                templRow.setAttribute("NewRow", "SUPPERROR");
                                MessageToken[] tokens = 
                                            { new MessageToken("FIELD", sFieldName) };
                                            
                                myAppsLog.write("ODEBillTxtAMImpl", "XXOD:XXOD_EBL_NOTSUPPORTED Error sFieldName" + sFieldName, 
                                                1);
                                throw new OAException("XXCRM", "XXOD_EBL_NOTSUPPORTED", tokens, 
                                                                OAException.ERROR, null);
                                                                
                            }


                           
                            break;
                        }

                    }
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "XXOD: sFieldName" + sFieldName, 1);
                    if ((sFieldName != null) && !("".equals(sFieldName))) {
                        //if (templRow.getAttribute("Label") == null){
                        templRow.setAttribute("Label", sFieldName);
                        //  }

                    }
                    break;
                }

            }
        } else if ("TRL".equals(sTab)) {
            OAViewObject templVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");
            RowSetIterator rsi = templVO.createRowSetIterator("rowsRSI");
            rsi.reset();
            while (rsi.hasNext()) {
                Row templRow = rsi.next();


                String sPkId = 
                    templRow.getAttribute("EblTempltrlId").toString();
                String sFieldId = templRow.getAttribute("FieldId").toString();

                myAppsLog.write("ODEBillTxtAMImpl", "XXOD:sFieldId" + sFieldId, 
                                1);
                String sFieldName = "";
                if (pkId.equals(sPkId)) {


                    OAViewObject fieldsVO = 
                        (OAViewObject)this.getODEBillConfigTrlFieldNamesPVO();
                    RowSetIterator fieldsVOrsi = 
                        fieldsVO.createRowSetIterator("rowsRSI");


                    while (fieldsVOrsi.hasNext()) {
                        Row fieldsVORow = fieldsVOrsi.next();

                        if (sFieldId.equals(fieldsVORow.getAttribute("FieldId"))) {


                            Boolean sFlag = Boolean.FALSE;
                            sFlag = 
                                    (Boolean)fieldsVORow.getAttribute("TranslationField");

                            templRow.setAttribute("NewRow", "EDITED");

                            if (!sFlag) {
                                templRow.setAttribute("NewRow", "ERROR");
                                throw new OAException("XXCRM", 
                                                      "XXOD_EBL_NOTALLOWED");
                            }


                            sFieldName = 
                                    fieldsVORow.getAttribute("FieldName").toString();
                            break;
                        }

                    }
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "XXOD: sFieldName" + sFieldName, 1);
                    if ((sFieldName != null) && !("".equals(sFieldName))) {
                        //if (templRow.getAttribute("Label") == null){
                        templRow.setAttribute("Label", sFieldName);
                        //  }

                    }
                    break;
                }

            }
        }

        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:End copyToLabel", 1);
    }
    
    public void copyToLabel1(String fieldId, String pkId, String sTab) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:Start copyToLabel" + pkId + " " + fieldId + " " + 
                        sTab, 1);

        if ("HDR".equals(sTab)) {
            OAViewObject templVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
            RowSetIterator rsi = templVO.createRowSetIterator("rowsRSI");
            rsi.reset();
            while (rsi.hasNext()) {
                Row templRow = rsi.next();


                String sPkId = 
                    templRow.getAttribute("EblTemplhdrId").toString();
                String sFieldId = templRow.getAttribute("FieldId").toString();

                myAppsLog.write("ODEBillTxtAMImpl", "XXOD:sFieldId" + sFieldId, 
                                1);
                String sFieldName = "";
                if (pkId.equals(sPkId)) {


                   // OAViewObject fieldsVO = 
                   //     (OAViewObject)this.getODEBillConfigHdrFieldNamesPVO();
                    OAViewObject fieldsVO = 
                                          (OAViewObject)this.getODEBillConfigDetailsFieldNamesSumPVO();
                    RowSetIterator fieldsVOrsi = 
                        fieldsVO.createRowSetIterator("rowsRSI");


                    while (fieldsVOrsi.hasNext()) {
                        Row fieldsVORow = fieldsVOrsi.next();

                        if (sFieldId.equals(fieldsVORow.getAttribute("FieldId"))) {

                            Boolean sFlag = Boolean.FALSE;
                            sFlag = 
                                    (Boolean)fieldsVORow.getAttribute("TranslationField");

                            templRow.setAttribute("NewRow", "EDITED");

                            if (!sFlag) {
                                templRow.setAttribute("NewRow", "ERROR");
                                throw new OAException("XXCRM", 
                                                      "XXOD_EBL_NOTALLOWED");
                            }

                            sFieldName = 
                                    fieldsVORow.getAttribute("FieldName").toString();
                            break;
                        }

                    }
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "XXOD: sFieldName" + sFieldName, 1);
                    if ((sFieldName != null) && !("".equals(sFieldName))) {
                        templRow.setAttribute("Label", sFieldName);

                    }
                    break;
                }

            }
        } else if ("DTL".equals(sTab)) {
            OAViewObject templVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
            RowSetIterator rsi = templVO.createRowSetIterator("rowsRSI");
            rsi.reset();
            while (rsi.hasNext()) {
                Row templRow = rsi.next();


                String sPkId = templRow.getAttribute("EblTemplId").toString();
                String sFieldId = templRow.getAttribute("FieldId").toString();

                myAppsLog.write("ODEBillTxtAMImpl", "XXOD:sFieldId" + sFieldId, 
                                1);
                String sFieldName = "";
                if (pkId.equals(sPkId)) {


                    OAViewObject fieldsVO = 
                        (OAViewObject)this.getODEBillConfigDetailsFieldNamesSumPVO();
                    RowSetIterator fieldsVOrsi = 
                        fieldsVO.createRowSetIterator("rowsRSI");


                    while (fieldsVOrsi.hasNext()) {
                        Row fieldsVORow = fieldsVOrsi.next();

                        if (sFieldId.equals(fieldsVORow.getAttribute("FieldId"))) {
                            Boolean sFlag = Boolean.FALSE;
                            sFlag = (Boolean)fieldsVORow.getAttribute("TranslationField");

                            templRow.setAttribute("NewRow", "EDITED");

                            if (!sFlag) {
                                templRow.setAttribute("NewRow", "ERROR");
                                throw new OAException("XXCRM", 
                                                      "XXOD_EBL_NOTALLOWED");
                            }

                            String sRecType = 
                                templRow.getAttribute("RecordType").toString();
                            String sFieldRecType = "";

                            if (fieldsVORow.getAttribute("RecordType") != null)
                                sFieldRecType = 
                                        fieldsVORow.getAttribute("RecordType").toString();
                                        
                            sFieldName = 
                                    fieldsVORow.getAttribute("FieldName").toString();
                                    
                            if (("HDR".equals(sRecType)) && 
                                ("LINE".equals(sFieldRecType))) {
                                templRow.setAttribute("NewRow", "SUPPERROR");
                                MessageToken[] tokens = 
                                            { new MessageToken("FIELD", sFieldName) };
                                            
                                myAppsLog.write("ODEBillTxtAMImpl", "XXOD:XXOD_EBL_NOTSUPPORTED Error sFieldName" + sFieldName, 
                                                1);
                                throw new OAException("XXCRM", "XXOD_EBL_NOTSUPPORTED", tokens, 
                                                                OAException.ERROR, null);
                                                                
                            }


                           
                            break;
                        }

                    }
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "XXOD: sFieldName" + sFieldName, 1);
                    if ((sFieldName != null) && !("".equals(sFieldName))) {
                        templRow.setAttribute("Label", sFieldName);

                    }
                    break;
                }

            }
        } else if ("TRL".equals(sTab)) {
            OAViewObject templVO = 
                (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");
            RowSetIterator rsi = templVO.createRowSetIterator("rowsRSI");
            rsi.reset();
            while (rsi.hasNext()) {
                Row templRow = rsi.next();


                String sPkId = 
                    templRow.getAttribute("EblTempltrlId").toString();
                String sFieldId = templRow.getAttribute("FieldId").toString();

                myAppsLog.write("ODEBillTxtAMImpl", "XXOD:sFieldId" + sFieldId, 
                                1);
                String sFieldName = "";
                if (pkId.equals(sPkId)) {


                    OAViewObject fieldsVO = 
                        (OAViewObject)this.getODEBillConfigTrlFieldNamesPVO();
                    RowSetIterator fieldsVOrsi = 
                        fieldsVO.createRowSetIterator("rowsRSI");


                    while (fieldsVOrsi.hasNext()) {
                        Row fieldsVORow = fieldsVOrsi.next();

                        if (sFieldId.equals(fieldsVORow.getAttribute("FieldId"))) {


                            Boolean sFlag = Boolean.FALSE;
                            sFlag = 
                                    (Boolean)fieldsVORow.getAttribute("TranslationField");

                            templRow.setAttribute("NewRow", "EDITED");

                            if (!sFlag) {
                                templRow.setAttribute("NewRow", "ERROR");
                                throw new OAException("XXCRM", 
                                                      "XXOD_EBL_NOTALLOWED");
                            }


                            sFieldName = 
                                    fieldsVORow.getAttribute("FieldName").toString();
                            break;
                        }

                    }
                    myAppsLog.write("ODEBillTxtAMImpl", 
                                    "XXOD: sFieldName" + sFieldName, 1);
                    if ((sFieldName != null) && !("".equals(sFieldName))) {
                        templRow.setAttribute("Label", sFieldName);

                    }
                    break;
                }

            }
        }

        myAppsLog.write("ODEBillTxtAMImpl", "XXOD:End copyToLabel", 1);
    }
    
    

    /**Container's getter for ODEBillSortTypePVO
     */
    public OAViewObjectImpl getODEBillSortTypePVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSortTypePVO");
    }

    public Boolean validateConcatSplit(String sFieldId, String sTab) {

        Boolean flag = Boolean.TRUE;


        ArrayList arrConcList = new ArrayList();
        ArrayList arrSplitList = new ArrayList();
        OAViewObject concatVO = null;

        //Logic for fetching Concatenate VO Fields into an Array
        if ("HDR".equals(sTab))
            concatVO = 
                    (OAViewObject)this.findViewObject("ODEBillConcatenateHdrVO");
        else if ("DTL".equals(sTab))
            concatVO = 
                    (OAViewObject)this.findViewObject("ODEBillConcatenateDtlVO");
        else if ("TRL".equals(sTab))
            concatVO = 
                    (OAViewObject)this.findViewObject("ODEBillConcatenateTrlVO");


        concatVO.reset();
        while (concatVO.hasNext()) {
            OARow concatRow = (OARow)concatVO.next();
            if (concatRow.getAttribute("ConcBaseFieldId1") != null) {
                String sField = 
                    concatRow.getAttribute("ConcBaseFieldId1").toString();
                    
                if (concatRow.getAttribute("Seq1") != null)
                    sField = sField + concatRow.getAttribute("Seq1");
                    
                arrConcList.add(sField);
            }

            if (concatRow.getAttribute("ConcBaseFieldId2") != null) {
                String sField = 
                    concatRow.getAttribute("ConcBaseFieldId2").toString();
                
                if (concatRow.getAttribute("Seq2") != null)
                    sField = sField + concatRow.getAttribute("Seq2");
                
                arrConcList.add(sField);
            }

            if (concatRow.getAttribute("ConcBaseFieldId3") != null) {
                String sField = 
                    concatRow.getAttribute("ConcBaseFieldId3").toString();
                if (concatRow.getAttribute("Seq3") != null)
                    sField = sField + concatRow.getAttribute("Seq3");

                arrConcList.add(sField);
            }


            if (concatRow.getAttribute("ConcBaseFieldId4") != null) {
                String sField = 
                    concatRow.getAttribute("ConcBaseFieldId4").toString();
                if (concatRow.getAttribute("Seq4") != null)
                    sField = sField + concatRow.getAttribute("Seq4");

                arrConcList.add(sField);
            }

            if (concatRow.getAttribute("ConcBaseFieldId5") != null) {
                String sField = 
                    concatRow.getAttribute("ConcBaseFieldId5").toString();
                if (concatRow.getAttribute("Seq5") != null)
                    sField = sField + concatRow.getAttribute("Seq5");

                arrConcList.add(sField);
            }

            if (concatRow.getAttribute("ConcBaseFieldId6") != null) {
                String sField = 
                    concatRow.getAttribute("ConcBaseFieldId6").toString();
                if (concatRow.getAttribute("Seq6") != null)
                    sField = sField + concatRow.getAttribute("Seq6");

                arrConcList.add(sField);
            }

        }
        //Logic for handling Concatenate VO Fields into an Array


        //Logic forfetching Split VO Fields into an Array
        OAViewObject splitVO = null;
        if ("DTL".equals(sTab)) {
            splitVO = (OAViewObject)this.findViewObject("ODEBillSplitVO");
            splitVO.reset();
            while (splitVO.hasNext()) {
                OARow splitRow = (OARow)splitVO.next();
                if (splitRow.getAttribute("SplitBaseFieldId") != null)
                    arrSplitList.add(splitRow.getAttribute("SplitBaseFieldId").toString());

            }
        }
        //Logic for handling Concatenate VO Fields into an Array 


        if ((arrConcList != null) && arrConcList.contains(sFieldId)) {
            flag = Boolean.FALSE;
        }

        if ((arrSplitList != null) && arrSplitList.contains(sFieldId)) {
            flag = Boolean.FALSE;

        }

        return flag;
    }

    /**Container's getter for ODEBillDynSplitFieldsVO
     */
    public ODEBillDynSplitFieldsVOImpl getODEBillDynSplitFieldsVO() {
        return (ODEBillDynSplitFieldsVOImpl)findViewObject("ODEBillDynSplitFieldsVO");
    }


    /**Container's getter for ODEBillMainVO
     */
    public OAViewObjectImpl getODEBillMainVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillMainVO");
    }


    /**Container's getter for ODEBillConfigDetailsFieldNamesSumPVO
     */
    public ODEBillConfigDetailsFieldNamesSumPVOImpl getODEBillConfigDetailsFieldNamesSumPVO() {
        return (ODEBillConfigDetailsFieldNamesSumPVOImpl)findViewObject("ODEBillConfigDetailsFieldNamesSumPVO");
    }

    /**Container's getter for ODEbillNonDtlQuantityPVO
     */
    public ODEbillNonDtlQuantityPVOImpl getODEbillNonDtlQuantityPVO() {
        return (ODEbillNonDtlQuantityPVOImpl)findViewObject("ODEbillNonDtlQuantityPVO");
    }


    /**Container's getter for ODEBillTemplDtlTxtFNPPRVO
     */
    public ODEBillTemplDtlTxtFNPPRVOImpl getODEBillTemplDtlTxtFNPPRVO() {
        return (ODEBillTemplDtlTxtFNPPRVOImpl)findViewObject("ODEBillTemplDtlTxtFNPPRVO");
    }

    public void handleTemplDtlTxtFNPPR() {
    
        int val1= 10;
               Number val= new Number(val1);
               OAViewObject vo=(OAViewObject)this.findViewObject("ODEBillTemplDtlTxtFNPPRVO");
               
               if(vo!=null) {
                   if(vo.getFetchedRowCount()==0) {
                       vo.setMaxFetchSize(0);
                       vo.executeQuery();
                       vo.insertRow(vo.createRow());
                       
                       OARow row=(OARow)vo.first();
                       row.setAttribute("RowKey", val);
                       row.setAttribute("DummyAttr", Boolean.FALSE);
                       row.setAttribute("DummyAttr2", Boolean.TRUE);
                       row.setAttribute("SumBill", Boolean.FALSE);
                   }           
               }       

    }
    
    public void handleTemplDtlTxtFNPPR1() {
    
        int val1= 10;
               Number val= new Number(val1);
               OAViewObject vo=(OAViewObject)this.findViewObject("ODEBillTemplDtlTxtFNPPRVO");
               
               if(vo!=null) {
                   if(vo.getFetchedRowCount()==0) {
                       vo.setMaxFetchSize(0);
                       vo.executeQuery();
                       vo.insertRow(vo.createRow());
                       
                       OARow row=(OARow)vo.first();
                       row.setAttribute("RowKey", val);
                       row.setAttribute("DummyAttr", Boolean.TRUE);
                       row.setAttribute("DummyAttr2", Boolean.FALSE);
                   }           
               }       

    }
    
    public void handleTemplDtlTxtFNPPR2() {
    
        int val1= 10;
               Number val= new Number(val1);
               OAViewObject vo=(OAViewObject)this.findViewObject("ODEBillTemplDtlTxtFNPPRVO");
               
               if(vo!=null) {
                   if(vo.getFetchedRowCount()==0) {
                       vo.setMaxFetchSize(0);
                       vo.executeQuery();
                       vo.insertRow(vo.createRow());
                       
                       OARow row=(OARow)vo.first();
                       row.setAttribute("RowKey", val);
                       row.setAttribute("DummyAttr", Boolean.TRUE);
                       row.setAttribute("DummyAttr2", Boolean.FALSE);
                   }           
               }       

    }

    /**Container's getter for ODEbillDataFmtPVO
     */
    public OAViewObjectImpl getODEbillDataFmtPVO() {
        return (OAViewObjectImpl)findViewObject("ODEbillDataFmtPVO");
    }

    /**Container's getter for ODEBillSignIndiPVO
     */
//    public ODEBillSignIndiPVOImpl getODEBillSignIndiPVO() {
//        return (ODEBillSignIndiPVOImpl)findViewObject("ODEBillSignIndiPVO");
//    }
 

    /**Container's getter for ODEBillSignIndiPVO
     */
    public OAViewObjectImpl getODEBillSignIndiPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSignIndiPVO");
    }

    /**Container's getter for ODEBillDebitCreditSignIndiPVO
     */
    public OAViewObjectImpl getODEBillDebitCreditSignIndiPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillDebitCreditSignIndiPVO");
    }

    /**Container's getter for ODEBillTxtCommonVO
     */
    public ODEBillTxtCommonVOImpl getODEBillTxtCommonVO() {
        return (ODEBillTxtCommonVOImpl)findViewObject("ODEBillTxtCommonVO");
    }

    /**Container's getter for ODEBillSignPosPVO
     */
    public OAViewObjectImpl getODEBillSignPosPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillSignPosPVO");
    }

    private void handleDtlAbsoluteValueLabelUpdatePPR(String absValueRequired, 
                                                    
                                                    String attr10, String custDocId1) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);

        OAViewObject templHdrTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
            
		OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();

        RowSetIterator rsi = templHdrTxtVO.createRowSetIterator("rowsRSI");


        rsi.reset();
          
        while (rsi.hasNext()) {
            Row templRow = rsi.next();
            //RepeatHeader has to be changed with original attribute name
            templRow.setAttribute("AbsoluteFlag",absValueRequired);
            templRow.setAttribute("DcIndicator",attr10);
			cmnVORow.setAttribute("AbsoluteValueHdrFlag", 
                                  templRow.getAttribute("AbsoluteFlag"));
                       
            cmnVORow.setAttribute("DebitCreditHdrFlag",
                                 templRow.getAttribute("DcIndicator"));
        }
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:End handleDtlAbsoluteValueLabelPPR", 1);
    }
    

//        private void handleDtlAbsoluteValueLabelUpdatePPR1(String absValueRequired, 
//                                                        
//                                                        String attr10, String custDocId1) {
//            AppsLog myAppsLog = new AppsLog();
//            myAppsLog.write("ODEBillAMImpl", 
//                            "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);
//
//            OAViewObject templHdrTxtVO = 
//                (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
//                
//			OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
//            OARow cmnVORow = (OARow)cmnVO.first();
//            RowSetIterator rsi = templHdrTxtVO.createRowSetIterator("rowsRSI");
//
//
//            rsi.reset();
//              System.out.println("The abs value hdr"+ absValueRequired);
//            while (rsi.hasNext()) {
//                Row templRow = rsi.next();
//                //RepeatHeader has to be changed with original attribute name
//                templRow.setAttribute("Attribute18",absValueRequired);
//                templRow.setAttribute("Attribute10",attr10);
//				 cmnVORow.setAttribute("AbsoluteValueHdrFlag", 
//                                      templRow.getAttribute("Attribute18"));
//                           
//                cmnVORow.setAttribute("DebitCreditHdrFlag",
//                                     templRow.getAttribute("Attribute10"));
//            }
//            myAppsLog.write("ODEBillTxtAMImpl", 
//                            "XXOD:End handleDtlAbsoluteValueLabelPPR", 1);
//        }
private void handleDtlAbsoluteValueLabelUpdatePPR4(String absValueRequired, 
                                                    
                                                    String attr10, String custDocId1) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);

        OAViewObject templTrlTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");
            
                    OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();
        RowSetIterator rsi = templTrlTxtVO.createRowSetIterator("rowsRSI");


        rsi.reset();
          
        while (rsi.hasNext()) {
            Row templRow = rsi.next();
            //RepeatHeader has to be changed with original attribute name
            templRow.setAttribute("AbsoluteFlag",absValueRequired);
            templRow.setAttribute("DcIndicator",attr10);
                             cmnVORow.setAttribute("AbsoluteValueHdrFlag2", 
                                  templRow.getAttribute("AbsoluteFlag"));
                       
            cmnVORow.setAttribute("DebitCreditTrlFlag",
                                 templRow.getAttribute("DcIndicator"));
        }
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:End handleDtlAbsoluteValueLabelPPR4", 1);
    }
private void handleDtlAbsoluteValueLabelUpdatePPR5(String absValueRequired, 
                                                    
                                                    String attr10, String custDocId1) {
        AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleDtlAbsoluteValueLabelPPR", 1);

        OAViewObject templTrlTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");
            
                    OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
        OARow cmnVORow = (OARow)cmnVO.first();
        RowSetIterator rsi = templTrlTxtVO.createRowSetIterator("rowsRSI");


        rsi.reset();
          
        while (rsi.hasNext()) {
            Row templRow = rsi.next();
            //RepeatHeader has to be changed with original attribute name
            templRow.setAttribute("Attribute18",absValueRequired);
            templRow.setAttribute("Attribute10",attr10);
                             cmnVORow.setAttribute("AbsoluteValueHdrFlag2", 
                                  templRow.getAttribute("Attribute18"));
                       
            cmnVORow.setAttribute("DebitCreditTrlFlag",
                                 templRow.getAttribute("Attribute10"));
        }
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:End handleDtlAbsoluteValueLabelPPR4", 1);
    }
	
	private void handleDtlAbsoluteValueLabelUpdatePPR2(String absValueRequired,
											String attr10, String custDocId1) {
		AppsLog myAppsLog = new AppsLog();
        myAppsLog.write("ODEBillAMImpl", 
                        "XXOD:Start  handleDtlAbsoluteValueLabelUpdatePPR2", 1);
						
		OAViewObject templDtlTxtVO = 
            (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
           
//        OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
//        OARow cmnVORow = (OARow)cmnVO.first(); 

        RowSetIterator rsi = templDtlTxtVO.createRowSetIterator("rowsRSI");


        rsi.reset();
          
        while (rsi.hasNext()) {
            Row templRow = rsi.next();
            //RepeatHeader has to be changed with original attribute name
            templRow.setAttribute("AbsoluteFlag",absValueRequired);
            templRow.setAttribute("DcIndicator",attr10);
//            cmnVORow.setAttribute("AbsoluteValueHdrFlag1", 
//                                  templRow.getAttribute("Attribute18"));
//                       
//            cmnVORow.setAttribute("DebitCreditDtlFlag",
//                                 templRow.getAttribute("Attribute10"));
            //getOADBTransaction().commit();
        }
        myAppsLog.write("ODEBillTxtAMImpl", 
                        "XXOD:End handleDtlAbsoluteValueLabelUpdatePPR2", 1);
		}				
						
						
//  Added by Reddy Sekhar K on 27th Jul 2017 for the defect #42321     
       public void dataFormatMethod() 
       {
           OAViewObject tempHdrVO= (OAViewObject)this.findViewObject("ODEBillTemplHdrTxtVO");
                    RowSetIterator tempHdrVOrsi = 
                         tempHdrVO.createRowSetIterator("rowsRSI");
                     OAViewObject switcherVO= (OAViewObject)this.findViewObject("ODEBillSwitcherVO");
                     RowSetIterator swithceriter = switcherVO.createRowSetIterator("rowsRSII");
                    tempHdrVOrsi.reset();
                     while (tempHdrVOrsi.hasNext()) {
                         Row tempHdrVOVORow = tempHdrVOrsi.next();
                         swithceriter.reset();
                         while (swithceriter.hasNext()) {
                             Row switcherVORow = swithceriter.next();
                             if (tempHdrVOVORow.getAttribute("FieldId").equals(switcherVORow.getAttribute("Code"))) 
                             {                                                     
                                 tempHdrVOVORow.setAttribute("Labelmethodhdr","case1");                                                                                    
                             }
                     
                     }
                     }
                      OAViewObject tempDtlVO1= (OAViewObject)this.findViewObject("ODEBillTemplDtlTxtVO");
                      RowSetIterator tempDtlVOrsi =  tempDtlVO1.createRowSetIterator("rowsRSI");
                      OAViewObject switcherDtlVO= (OAViewObject)this.findViewObject("ODEBillSwitcherVO");
                      switcherDtlVO.clearCache();
                      switcherDtlVO.executeQuery();
                      RowSetIterator swithceriterDtl = switcherDtlVO.createRowSetIterator("rowsRSII");
                      tempDtlVOrsi.reset();
                      while (tempDtlVOrsi.hasNext()) {
                          Row tempDtlVORow = tempDtlVOrsi.next();
                          swithceriterDtl.reset();
                          while (swithceriterDtl.hasNext()) {
                              Row switcherDtlVORow = swithceriterDtl.next();
                              if (tempDtlVORow.getAttribute("FieldId").equals(switcherDtlVORow.getAttribute("Code"))) 
                              {                                                   
                                  tempDtlVORow.setAttribute("Labelmethodline","case3");                                                                        
                              }
                         
                   //    Added for Defect# NAIT-22703 on 04-Jan-2018 - START  
                      //Code added by Rafi Mohammed on 09-Feb-2018 for Wave3 UAT Defect(NAIT-27591) - START
                        String  unitp=tempDtlVORow.getAttribute("FieldId").toString();
                      //Code added by Rafi Mohammed on 09-Feb-2018 for Wave3 UAT Defect(NAIT-27591) - END
                        if("10069".equalsIgnoreCase(unitp))
                       {
                         
                        tempDtlVORow.setAttribute("Labelmethodline","case7");
                          }
                       //Added for Defect# NAIT-22703 by Rafi on 04-Jan-2018 - END                            
                                                         
                   }
                         
                      }
                         OAViewObject tempTlrVO= (OAViewObject)this.findViewObject("ODEBillTemplTrlTxtVO");
                               RowSetIterator tempTrlVOrsi = 
                                   tempTlrVO.createRowSetIterator("rowsRSI");
                               OAViewObject switcherTrlVO= (OAViewObject)this.findViewObject("ODEBillSwitcherVO");
                               switcherTrlVO.clearCache();
                               switcherTrlVO.executeQuery();
                               RowSetIterator swithcerTrlIter = switcherTrlVO.createRowSetIterator("rowsRSII");
                               tempTrlVOrsi.reset();
                               while (tempTrlVOrsi.hasNext()) {
                                   Row tempTrlVORow = tempTrlVOrsi.next();
                                   swithcerTrlIter.reset();
                                   while (swithcerTrlIter.hasNext()) {
                                       Row switcherTrlVORow = swithcerTrlIter.next();
                                       if (tempTrlVORow.getAttribute("FieldId").equals(switcherTrlVORow.getAttribute("Code"))) 
                                       {   
                                           //tempTrlVORow.setAttribute("DataFormat",null);
                                           tempTrlVORow.setAttribute("Labelmethodtrl","case5");
                                           //tempTrlVORow.setAttribute("DataFormat","9999990.00");
                                      
                                       }
                                       }
                               }
            // Code Ended by Reddy Sekhar K on 27th Jul 2017 for the defect #42321
            
       }
             //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---Start
             public void rendered(String dbCrPrValue) {
                OAViewObject objprocess=(OAViewObject)this.findViewObject("ODEBillPPRVO");
                OARow firstRowProcess=(OARow)objprocess.first();
                    OAViewObject cmnVO = (OAViewObject)this.getODEBillTxtCommonVO();
                           OARow cmnVORow = (OARow)cmnVO.first();
                           String DebCreTransientValue=null;
                  if("Y".equals(dbCrPrValue))
                {
                    cmnVORow.setAttribute("DebCreTransient",null);
                    cmnVORow.setAttribute("DebCreTransientHdr",null);
                    cmnVORow.setAttribute("DebCreTransientTrl",null);
                    firstRowProcess.setAttribute("debitCreditRendered", Boolean.FALSE); 
                    debitCreditSeparatorHeader(DebCreTransientValue);
                    debitCreditSeparatorDetail(DebCreTransientValue);
                    debitCreditSeparatorTrailer(DebCreTransientValue);
                }
                else {
                    firstRowProcess.setAttribute("debitCreditRendered", Boolean.TRUE);
                    }
                }
             //Added By Reddy Sekhar K on 09 May 2018 for the Defect# NAIT-29364---End  
             public void parentDocIdTXT(){
                 //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----Start 
                  OAViewObject parentDocDis=(OAViewObject)this.findViewObject("ODEBillPPRVO");
                          OARow firstRowProcess1=(OARow)parentDocDis.first();
                           OAViewObject payDocVO = (OAViewObject)this.findViewObject("ODEBillPayDocVO"); 
                                     int payDocVOCount=payDocVO.getRowCount();
                                        if(payDocVOCount>=1)
                                        {                                       
                                           firstRowProcess1.setAttribute("parentDocIDDisabled",Boolean.TRUE); 
                                        }
                                       else{
                                       OAViewObject infoDocVO = (OAViewObject) this.findViewObject("ODEBillDocExceptionVO"); 
                                              int infoDocVOCount=infoDocVO.getRowCount();
                                              if(infoDocVOCount>=1) {
                                                   firstRowProcess1.setAttribute("parentDocIDDisabled", Boolean.TRUE); 
                                              }
                                              
                                       }
                                           
                 //Added By Reddy Sekhar K on 22 June 2018 for the Defect# NAIT-27146-----End
                 
             }

    /**Container's getter for ODEBillSwitcherVO
     */
//    public ODEBillSwitcherVOImpl getODEBillSwitcherVO() {
//        return (ODEBillSwitcherVOImpl)findViewObject("ODEBillSwitcherVO");
//    }


    /**Container's getter for ODEBillDataFmtPVO
     */
    public OAViewObjectImpl getODEBillDataFmtPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillDataFmtPVO");
    }

    /**Container's getter for ODEBillRecordTypeExDistPVO1
     */
    public OAViewObjectImpl getODEBillRecordTypeExDistPVO1() {
        return (OAViewObjectImpl)findViewObject("ODEBillRecordTypeExDistPVO1");
    }

    /**Container's getter for ODEBillRecordTypeExDistPVO
     */
    public OAViewObjectImpl getODEBillRecordTypeExDistPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillRecordTypeExDistPVO");
    }


    /**Container's getter for ODEBillSwitcherVO
     */
    public ODEBillSwitcherVOImpl getODEBillSwitcherVO() {
        return (ODEBillSwitcherVOImpl)findViewObject("ODEBillSwitcherVO");
    }

    /**Container's getter for ODEBillDataFmtTxtPVO
     */
    public OAViewObjectImpl getODEBillDataFmtTxtPVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillDataFmtTxtPVO");
    }

    /**Container's getter for ODEBillDebitCreditSepartor
     */
    public OAViewObjectImpl getODEBillDebitCreditSepartor() {
        return (OAViewObjectImpl)findViewObject("ODEBillDebitCreditSepartor");
    }

    /**Container's getter for ODEBillTemplDtlTxtVO
     */
    public ODEBillTemplDtlTxtVOImpl getODEBillTemplDtlTxtVO() {
        return (ODEBillTemplDtlTxtVOImpl)findViewObject("ODEBillTemplDtlTxtVO");
    }

    /**Container's getter for ODEBillTemplHdrTxtVO
     */
    public ODEBillTemplHdrTxtVOImpl getODEBillTemplHdrTxtVO() {
        return (ODEBillTemplHdrTxtVOImpl)findViewObject("ODEBillTemplHdrTxtVO");
    }

    /**Container's getter for ODEBillTemplTrlTxtVO
     */
    public ODEBillTemplTrlTxtVOImpl getODEBillTemplTrlTxtVO() {
        return (ODEBillTemplTrlTxtVOImpl)findViewObject("ODEBillTemplTrlTxtVO");
    }

    /**Container's getter for ODEBillParentCustDocId
     */
    public OAViewObjectImpl getODEBillParentCustDocId() {
        return (OAViewObjectImpl)findViewObject("ODEBillParentCustDocId");
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

    /**Container's getter for ODEBillPPRVO
     */
    public OAViewObjectImpl getODEBillPPRVO() {
        return (OAViewObjectImpl)findViewObject("ODEBillPPRVO");
    }
} // End class ODEBillTxtAMImpl
