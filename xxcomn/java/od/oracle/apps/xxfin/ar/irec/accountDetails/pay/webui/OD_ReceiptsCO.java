package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.webui;
/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |                       Oracle Consulting                                   |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             OD_ReceiptsCO.java                                            |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This java file is custom for CR868                                     |
 |                                                                           |
 |                                                                           |
 |Change Record:                                                             |
 |===============                                                            |
 | Date         Author              Remarks                                  |
 | ==========   =============       =======================                  |
 | 1.0  01-Jun-2012  Suraj Charan        Initial                             |
 | 1.1  05-Nov-2012  Jay Gupta           Changed Conf Msg for verbage change |
 |                                       and added for PSTGB                 |
 | 1.2  18-Dec-2012  Suraj Charan   Defect# 21164                            |
 | 1.3  03-Apr-2013  Suraj Charan   Attachment sent as BLOB                  |
 | 1.4  26-Feb-2014  Sridevi K      Path for picking up rtf modified         |
 | 2.0  4-Mar-2015   Sridevi K      Modified for CR1120                      |
 | 2.1  22-Apr-2015  Sridevi K      Modified for Defect1080                  |
 | 2.2  10-May-2015  Sridevi K      Modified for PDF values                  |
 | 2.3  12-May-2015  Sridevi K      Modified for Defect#1269                 |
 | 1.1  17-FEB-2017  MBolli			Thread Leak 12.2.5 Upgrade - close all statements, resultsets |
 +============================================================================+*/
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;

import java.sql.SQLException;

import java.text.DateFormat;
import java.text.SimpleDateFormat;

import java.util.Calendar;
import java.util.Date;

import od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server.OD_ReceiptsVORowImpl;
import od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server.OD_PaymentPDFDirectoryVORowImpl;
import od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server.OD_InstanceVORowImpl;
import od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server.OD_CustomerNumberVORowImpl;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAFormattedTextBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.xdo.XDOException;
import oracle.apps.xdo.template.FOProcessor;
import oracle.apps.xdo.template.RTFProcessor;

import oracle.jdbc.OracleCallableStatement;

import oracle.xml.parser.v2.XMLNode;

import java.sql.Types;

import oracle.apps.fnd.framework.OAException;


////////////////////////
//For Print
import java.io.*;

import javax.print.*;
import javax.print.attribute.*;
import javax.print.attribute.standard.*;

import java.awt.print.PrinterException;
import java.awt.print.PrinterJob;
//////////////////////////////

public class OD_ReceiptsCO extends OAControllerImpl {

    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion("$Header$", "%packagename%");
    private static final int DEPTH = 4;
    private static final int APP_ID = 20035;
    private static final String APP_NAME = "AR";
    private static final String TEMPLATE_CODE = "OD_EPAY_TEMPLATE";
    private static final int BUFFER_SIZE = 32000;
    private String pdfFilePrint = null;

    public OD_ReceiptsCO() {
    }

    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {
        super.processRequest(pageContext, webBean);
        String strConfPageTemplateUrl = pageContext.getProfile("XX_FIN_IREC_CONF_PAGE_TEMPLATE_URL");
        pageContext.writeDiagnostics(this, "##### ODPaymentPageButtonsCO PR strConfPageTemplateUrl:" + strConfPageTemplateUrl, 1);	
		
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
       
        OAButtonBean printButtonRN = 
            (OAButtonBean)webBean.findChildRecursive("ODPrint");
        pageContext.writeDiagnostics(this, 
                                     "##### ODPaymentPageButtonsCO PFR AFter Calling XX_AR_IREC_PAYMENTS   getSessionValue(XX_AR_IREC_PAY_STATUS)=" + 
                                     pageContext.getSessionValue("XX_AR_IREC_PAY_STATUS"), 
                                     1);
        pageContext.writeDiagnostics(this, 
                                     "##### WEBSERVICE_RECEIPT_NUMBER=" + pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER"), 
                                     1);
        pageContext.writeDiagnostics(this, 
                                     "##### XX_AR_IREC_PAY_CASH_RECEIPT_ID=" + 
                                     pageContext.getSessionValue("XX_AR_IREC_PAY_CASH_RECEIPT_ID"), 
                                     1);

        pageContext.writeDiagnostics(this, 
                                     "##### OD_CONFIRMEMAIL=" + pageContext.getSessionValue("OD_CONFIRMEMAIL"), 
                                     1);

        if ("S".equals(pageContext.getSessionValue("XX_AR_IREC_PAY_STATUS")) && 
            pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") != null && 
            !"".equals(pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER")))
         {
            pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER");
            pageContext.getSessionValue("XX_AR_IREC_PAY_CASH_RECEIPT_ID");

            Object objConfirmemail = 
                pageContext.getSessionValue("OD_CONFIRMEMAIL");
            String strConfirmemail = "";
            if (objConfirmemail != null) {
                strConfirmemail = objConfirmemail.toString();
                pageContext.writeDiagnostics(this, 
                                             "##### Confirmemail: " + strConfirmemail, 
                                             1);
            } else {
                Object objPrevSavedEmail = 
                    pageContext.getSessionValue("PREV_SAVED_CUSTOM_EMAIL_ADDRESS");
                if (objPrevSavedEmail != null) {
                    strConfirmemail = objPrevSavedEmail.toString();
                    pageContext.writeDiagnostics(this, 
                                                 "##### previously saved bank Confirmemail: " + strConfirmemail, 
                                                 1);
                }
                else {
                  //If no value found for previously saved bank account
                  //default value gets picked up from profile 
                  String sEmailFrom =   pageContext.getProfile("XX_AR_IREC_EMAIL_FROM");
                  pageContext.writeDiagnostics(this, 
                                                 "##### sEmailFrom: " + sEmailFrom, 
                                                 1);
                   strConfirmemail = sEmailFrom;
                   pageContext.writeDiagnostics(this, 
                                                 "##### default Confirmemail: " + strConfirmemail, 
                                                 1);
                }
                
            }


            if (printButtonRN != null && 
                pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") != 
                null && 
                !"".equals(pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER"))) {
                printButtonRN.setRendered(true);
            }
            OAFormattedTextBean emailText = 
                (OAFormattedTextBean)webBean.findChildRecursive("EmailText");
            OAViewObject receiptVO = 
                (OAViewObject)am.findViewObject("OD_ReceiptsVO");
            
			if(receiptVO != null) {
             pageContext.writeDiagnostics(this, "##### receiptVO is not null : ",1);
			receiptVO.setWhereClauseParam(0, pageContext.getSessionValue("XX_AR_IREC_PAY_CASH_RECEIPT_ID"));
			pageContext.writeDiagnostics(this, "##### receiptVO query : "+receiptVO.getQuery(),1);
            receiptVO.setMaxFetchSize(-1);
            receiptVO.executeQuery();
            }
			OD_ReceiptsVORowImpl receiptVORow = 
                (OD_ReceiptsVORowImpl)receiptVO.first();
				
            //Check if receiptVORow is null. This means, receipt is yet to be created before the 
			//confirmation page is getting loaded. So let's try requerying-
			int i=0;
            if(receiptVORow == null) {
			  while (receiptVORow == null && i < 32) {
                pageContext.writeDiagnostics(this, "##### receiptVORow is null : " + i, 1);
				
                try {
                    Thread.sleep(250);                 //1000 milliseconds is one second.
                } catch(InterruptedException ex) {
                    Thread.currentThread().interrupt();
                }			
				
				//10May2015 - Set Max Fetch size to -1
			    receiptVO.setMaxFetchSize(-1);
			    receiptVO.executeQuery();
                receiptVORow = (OD_ReceiptsVORowImpl)receiptVO.first();
			    i++;
			  }
            }			
            pageContext.writeDiagnostics(this, 
                                             "##### receiptVORow no of tries: " + 
                                             i, 1);
            Object objWebServiceReceiptNumber = 
                pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER");
            String strWebServiceReceiptNumber = "";
            if (objWebServiceReceiptNumber != null) {
                strWebServiceReceiptNumber = 
                        objWebServiceReceiptNumber.toString();
                pageContext.writeDiagnostics(this, 
                                             "##### WEBSERVICE_RECEIPT_NUMBER: " + 
                                             strWebServiceReceiptNumber, 1);
            }
			OD_PaymentPDFDirectoryVORowImpl receiptDirectoryVORow = null;
			String url = null;
			ByteArrayOutputStream outputStream = null;	
            ByteArrayInputStream inputStream = null;
            try {
                pageContext.writeDiagnostics(this, 
                                             "##### receiptVORow rowCount=" + 
                                             receiptVO.getRowCount(), 1);
                pageContext.writeDiagnostics(this, 
                                             "##### receiptVORow =" + receiptVORow, 
                                             1);
                if (receiptVORow != null)
                  receiptVORow.setPaymentNumber(strWebServiceReceiptNumber);

            
			pageContext.writeDiagnostics(this, 
                                             "##### getting date 1", 
                                             1);
			/*
            --10May2015 - Commented as it is throwing error
			java.sql.Date sqldate = null;
			
            if (receiptVORow != null)
			  receiptVORow.getCreationDate().dateValue();
            else				
              sqldate =  new java.sql.Date(Calendar.getInstance().getTimeInMillis());			
			
		
            Date date = new Date(sqldate.getTime());
            SimpleDateFormat formatDt = new SimpleDateFormat("dd-MMM-yyyy");
            String formattedDate = formatDt.format(date);
            java.sql.Date sqldateReceipt = null;
            if (receiptVORow != null){
			  receiptVORow.getReceiptDateDisp().dateValue();
			}
            else				{
              sqldateReceipt =  new java.sql.Date(Calendar.getInstance().getTimeInMillis());			
			}
			
            Date dateReceipt = new Date(sqldateReceipt.getTime());

            SimpleDateFormat formatDtReceipt = 
                new SimpleDateFormat("dd-MMM-yyyy");
			String formatdDateReceipt = formatDtReceipt.format(dateReceipt);
            */
            java.sql.Date sqldate = receiptVORow.getCreationDate().dateValue();
            Date date = new Date(sqldate.getTime());
            SimpleDateFormat formatDt = new SimpleDateFormat("dd-MMM-yyyy");
            String formattedDate = formatDt.format(date);
            java.sql.Date sqldateReceipt = 
                receiptVORow.getReceiptDateDisp().dateValue();
            Date dateReceipt = new Date(sqldateReceipt.getTime());
            SimpleDateFormat formatDtReceipt = 
                new SimpleDateFormat("dd-MMM-yyyy");
            String formatdDateReceipt = formatDtReceipt.format(dateReceipt);


            StringBuffer email = new StringBuffer();
            email.append("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\"> <HTML> <BODY> ");
            //Defect ID: 19186 Changes
            String strCustomerName = null;
			
            if (receiptVORow != null)	
              strCustomerName = receiptVORow.getCustomerName();
            else
              strCustomerName = "Customer ";

			pageContext.writeDiagnostics(this, 
                                             "##### strCustomerName"+strCustomerName, 
                                             1);

            email.append("<p font size=2>   Dear <b>" + strCustomerName + "</b>,");
            email.append("<br><br>");
            email.append(" This is to confirm your authorization for payment to Office Depot as noted below: <br>");

            String strMasedBankNumber = null;
			
            if (receiptVORow != null)	
              strMasedBankNumber = receiptVORow.getMaskedBankAccountNumber();
            else
              strMasedBankNumber = "XXXX ";

			pageContext.writeDiagnostics(this, 
                                             "##### strCustomerName"+strMasedBankNumber, 
                                             1);
           
            email.append("<br>Bank Account Number: <b>" +  strMasedBankNumber + 
                         "</b><br> Bank Confirmation Number: <b>" + 
                         pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") + 
                         "</b><br>Effective Date: <b>");

            String strAmountDisp = null;
			
            if (receiptVORow != null)	
              strAmountDisp = receiptVORow.getAmountDisp();
            else
              strAmountDisp = "XXXX ";
 
            email.append(formatdDateReceipt + "</b><br>Payment Amount: <b>$" + strAmountDisp + "</b>");
            email.append("<br>OD Payment Number: <b>" + receiptVORow.getReceiptNumber() + "</b><br>");
 
            if (receiptVORow != null)
              email.append("<br>User Id: <b>" + receiptVORow.getUserName() + "</b>");

            if (receiptVORow != null)
              email.append("<br>Date: <b>" + formattedDate + " " + receiptVORow.getCreationTime() + " EST</b>"); //sqldate
            else				
              email.append("<br>Date: <b>" + formattedDate + " " + new java.sql.Date(Calendar.getInstance().getTimeInMillis()) + " EST</b>"); //sqldate
			  
            email.append("<br></br><br/><br>The payment will be completed on the effective date or shortly" + 
                         " thereafter and will appear on your bank statement as: <b>OFCDEPOT ECHECK BILL MGMT.</b>");
            email.append("<br/><br><br><br/>Please print a copy of this receipt and retain for your records.</br>");
            //V1.1, Commented below for verbage change
            //email.append("<br><br><b>Thank you for your business. If you have any questions, please call "+receiptVORow.getCustomerCareNumber()+"</b> <br />");

            email.append("<br><br><br>Please allow 48 hours for the payment to reflect on your Office Depot account.</br>");
            email.append("<br>If this is your first time making an ACH/ECheck payment to Office Depot, and to ensure proper processing, please notify your bank and have Office Depot added as an authorized debitor.</br></br></br>");


            email.append("<br><br><br><b>Thank you for your continued business.</b></br></br></br>");

            //email.append("<br><br><b>Thank you for your business."+"</b> </br> </br>");

            //email.append("<br><br><br><br><b>***Please add Office Depot as a authorized debitor***"+"</b> </br></br></br></br>");


            email.append("</p></BODY> </HTML>");
            pageContext.writeDiagnostics(this, 
                                         "##### Confirmation: " + email.toString(), 
                                         1);
            emailText.setText(email.toString());
            outputStream = new ByteArrayOutputStream();
			
			//Commented to reduce the overload for getting the directory path		
			//use the Template Url from the profile value strConfPageTemplateUrl
			/*
            OAViewObject receiptDirectoryVO = 
                (OAViewObject)am.findViewObject("OD_PaymentPDFDirectoryVO");
            receiptDirectoryVO.executeQuery();
            receiptDirectoryVORow = 
                (OD_PaymentPDFDirectoryVORowImpl)receiptDirectoryVO.first();
            OAViewObject instanceVO = 
                (OAViewObject)am.findViewObject("OD_InstanceVO");
            instanceVO.executeQuery();
            OD_InstanceVORowImpl instanceVORow = 
                (OD_InstanceVORowImpl)instanceVO.first();
            if (instanceVORow.getName() != null) {
                if ("GSIDEV01".equals(instanceVORow.getName().toString())) {
                    url = "dev01";
                }

                if ("GSIDEV02".equals(instanceVORow.getName().toString())) {
                    url = "dev02";
                }

                if ("GSISIT01".equals(instanceVORow.getName().toString())) {
                    url = "sit01";
                }

                if ("GSISIT02".equals(instanceVORow.getName().toString())) {
                    url = "sit02";
                }

                if ("GSIUATGB".equals(instanceVORow.getName())) {
                    url = "uatgb";
                }

                if ("GSIPRFGB".equals(instanceVORow.getName())) {
                    url = "prfgb";
                }

                //V1.1, Added for PSTGB
                if ("GSIPSTGB".equals(instanceVORow.getName())) {
                    url = "pstgb";
                }

                if ("GSIPRDGB".equals(instanceVORow.getName())) {
                    url = "prdgb";
                }
            }
            pageContext.writeDiagnostics(this, 
                                         "##### Directory Path=" + receiptDirectoryVORow.getDirectoryPath(), 
                                         1);
										 
            */ //comment ended to reduce the overload for getting the directory path										 
            } catch (Exception ePayNullPointer) {
			    ePayNullPointer.printStackTrace();
                OAException msg2 = 
                    new OAException("Unable to derive the Conformation page. But, your payment is made and the Receipt Number is:" + 
                                    pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") + 
                                    ".", OAException.INFORMATION);
                pageContext.putDialogMessage(msg2);
                //return;
            }
            try {

                /* Start - R12 upgrade - Modified For defect 28500 */
                /*
                RTFProcessor rtfProcessor = new RTFProcessor("/app/ebs/atgsi"+url+"/gsi"+url+"cust/xxfin/xml/templates/" + "OD_EPAY_TEMPLATE.rtf");
                rtfProcessor.setOutput("/app/ebs/atgsi"+url+"/gsi"+url+"cust/xxfin/xml/templates/"+"OD_EPAY_TEMPLATE.xsl");
                */
                RTFProcessor rtfProcessor = 
                    //new RTFProcessor("/app/ebs/itgsi" + url + "/gsi" + url + 
                    //                 "cust/xxfin/xml/templates/" + 
                    //                 "OD_EPAY_TEMPLATE.rtf");
                    new RTFProcessor( strConfPageTemplateUrl + "OD_EPAY_TEMPLATE.rtf");
                    //rtfProcessor.setOutput("/app/ebs/itgsi" + url + "/gsi" + url + 
                    //                       "cust/xxfin/xml/templates/" + 
                    //                       "OD_EPAY_TEMPLATE.xsl");
                    rtfProcessor.setOutput( strConfPageTemplateUrl + "OD_EPAY_TEMPLATE.xsl");
                /* End - R12 upgrade - Modified For defect 28500 */

                rtfProcessor.process();
            } catch (Exception e) {
                pageContext.writeDiagnostics(this, 
                                             "### Error in RTFProcessor=" + e, 
                                             1);
            }
            try {
                if (receiptVO != null)
                   ((XMLNode)receiptVO.writeXML(4, 0L)).print(outputStream);
				   
                if ( outputStream != null) {
                  pageContext.writeDiagnostics(this, "### XML VO=" + outputStream.toString(), 1);
				  inputStream = new ByteArrayInputStream(outputStream.toByteArray());
                }
                XMLNode xmlNode = getEmpDataXML(pageContext, webBean, am);
                FOProcessor processor = new FOProcessor();
				
                if ( inputStream != null)
                  processor.setData(inputStream);
                DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd_HH:mm:ss");
                Calendar cal = Calendar.getInstance();
                pageContext.writeDiagnostics(this, "##### Directory Path=" + strConfPageTemplateUrl, 1);
                /* Start - R12 upgrade - Modified For defect 28500 */
                /*processor.setTemplate("/app/ebs/atgsi"+url+"/gsi"+url+"cust/xxfin/xml/templates/" + "/OD_EPAY_TEMPLATE.xsl"); */
                //processor.setTemplate("/app/ebs/itgsi" + url + "/gsi" + url + 
                //                      "cust/xxfin/xml/templates/" + 
                //                      "/OD_EPAY_TEMPLATE.xsl");
                processor.setTemplate(strConfPageTemplateUrl + "/OD_EPAY_TEMPLATE.xsl");
                /* End - R12 upgrade - Modified For defect 28500 */
                //processor.setOutput(receiptDirectoryVORow.getDirectoryPath() + 
                processor.setOutput(strConfPageTemplateUrl + 
                                    "/OD_EPAY_" + 
                                    pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") + "_" + 
                                    dateFormat.format(cal.getTime()) + ".pdf");
                pdfFilePrint = 
                        //receiptDirectoryVORow.getDirectoryPath() + "/OD_EPAY_" + 
                        strConfPageTemplateUrl + "/OD_EPAY_" + 
                        pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") + "_" + 
                        dateFormat.format(cal.getTime()) + ".pdf";
                pageContext.putSessionValue("pdfFilePrint", pdfFilePrint);
                processor.setOutputFormat((byte)1);
                processor.generate();
                pageContext.writeDiagnostics(this, 
                                             "##### receiptVORow.getCashReceiptId()=" + 
                                             //receiptVORow.getCashReceiptId(), 
                                             pageContext.getSessionValue("XX_AR_IREC_PAY_CASH_RECEIPT_ID"),
                                             1);
                OracleCallableStatement oraclecallablestatement = null;
                OADBTransaction oadbtransaction = am.getOADBTransaction();
                try {
                    File attachFile = 
                        new File(strConfPageTemplateUrl + 
                                 "/OD_EPAY_" + 
                                 pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") + "_" + 
                                 dateFormat.format(cal.getTime()) + ".pdf");
                    InputStream input = new FileInputStream(attachFile);
                    pageContext.writeDiagnostics(this, 
                                                 "##### Calling Attachment pkg XX_OD_IREC_RECEIPTS_ATTACH_PKG.attach_file", 
                                                 1);
                    //V1.3
                    String stmt = 
                        "begin XX_OD_IREC_RECEIPTS_ATTACH_PKG.attach_file(:1,:2,:3,:4,:5); end;";
                    oraclecallablestatement = 
                            (OracleCallableStatement)oadbtransaction.createCallableStatement(stmt, 
                                                                                             10);
                    oraclecallablestatement.setString(1, strConfirmemail);
                    oraclecallablestatement.setString(2, 
                                                      "OD_EPAY_" + pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") + 
                                                      "_" + 
                                                      dateFormat.format(cal.getTime()) + 
                                                      ".pdf");
                    oraclecallablestatement.setString(3, 
                                                      (String)pageContext.getSessionValue("XX_AR_IREC_PAY_CASH_RECEIPT_ID"));
                    oraclecallablestatement.setBinaryStream(4, input, 
                                                            (int)attachFile.length());
                    oraclecallablestatement.registerOutParameter(5, 
                                                                 Types.VARCHAR, 
                                                                 100);
                    oraclecallablestatement.execute();
                    String status = oraclecallablestatement.getString(5);
                    pageContext.writeDiagnostics(this, 
                                                 "##### After calling proc status=" + 
                                                 status, 1);
                    //To delete the file from file system after attachment.

                    try {
                        File file = 
                            new File(strConfPageTemplateUrl + 
                                     "/OD_EPAY_" + 
                                     pageContext.getSessionValue("WEBSERVICE_RECEIPT_NUMBER") + "_" + 
                                     dateFormat.format(cal.getTime()) + 
                                     ".pdf");
                        boolean success = file.delete();
                        pageContext.writeDiagnostics(this, 
                                                     "##### File Deletion Status=" + 
                                                     success, 1);
                        if (!success)
                            throw new IllegalArgumentException("Delete: deletion failed");
                    } catch (Exception e) {
                        pageContext.writeDiagnostics(this, 
                                                     "##### Error in Deleting File=" + 
                                                     e, 1);
                    }
                } catch (SQLException sqlexception) {
                    pageContext.writeDiagnostics(this, 
                                                 "##### Error in XX_OD_IREC_RECEIPTS_ATTACH_PKG=" + 
                                                 sqlexception, 1);
                } finally {
					try {
					 if (oraclecallablestatement != null)
						oraclecallablestatement.close();					
					} catch(Exception exc) {  }
				}	  
            } catch (XDOException e) {
                pageContext.writeDiagnostics(this, 
                                             "### Error in XDOException=" + e, 
                                             1);
            } catch (Exception e) {
                pageContext.writeDiagnostics(this, 
                                             "### Error in FOProcessor=" + e, 
                                             1);
            }
            pageContext.removeSessionValue("XX_AR_IREC_PAY_STATUS");
            pageContext.removeSessionValue("WEBSERVICE_RECEIPT_NUMBER");
            pageContext.removeSessionValue("XX_AR_IREC_PAY_CASH_RECEIPT_ID");
            pageContext.removeSessionValue("OD_CONFIRMEMAIL");
            pageContext.removeSessionValue("PREV_SAVED_CUSTOM_EMAIL_ADDRESS");
            pageContext.removeSessionValue("OD_CustomEmailAddress");

            
        }
        else {
            pageContext.removeSessionValue("XX_AR_IREC_PAY_STATUS");
            pageContext.removeSessionValue("WEBSERVICE_RECEIPT_NUMBER");
            pageContext.removeSessionValue("XX_AR_IREC_PAY_CASH_RECEIPT_ID");
            pageContext.removeSessionValue("OD_CONFIRMEMAIL");
            pageContext.removeSessionValue("PREV_SAVED_CUSTOM_EMAIL_ADDRESS");
            pageContext.removeSessionValue("OD_CustomEmailAddress");
         
        }

    }

    public void processFormRequest(OAPageContext pageContext, 
                                   OAWebBean webBean) {
        super.processFormRequest(pageContext, webBean);
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
    }

    public XMLNode getEmpDataXML(OAPageContext pageContext, OAWebBean webBean, 
                                 OAApplicationModule am) {
        OAViewObject vo = (OAViewObject)am.findViewObject("OD_ReceiptsVO");
        XMLNode xmlNode = (XMLNode)vo.writeXML(4, 0L);
        return xmlNode;
    }

}
