package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.webui;

import java.text.DateFormat;
import java.text.SimpleDateFormat;

import java.util.Date;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAWebBeanFactory;
import oracle.apps.fnd.framework.webui.beans.OABodyBean;
import oracle.apps.fnd.framework.webui.beans.OARawTextBean;
import oracle.apps.fnd.framework.webui.beans.OAScriptBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.beans.nav.OAButtonBean;

/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |                                                                           |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODNewCCPayPageCO.java                                         |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This java file is for including payframe (eProtect)                    |
 |                                                                           |
 |  RICE  E1294                                                              |
 |Change Record:                                                             |
 |===============                                                            |
 | Date         Author              Remarks                                  |
 | ==========   =============       =======================                  |
 | 18-Oct-2016  Sridevi K           Initial Version                          |
 | 30-Nov-2016  Sridevi K           Updated for defect 40262                 |
 |                                  iRec P2Pe Switching between ACH and CC   |
 |                                  pay frame not loading correctly          |
 | 28-Aug-2017  Madhu Bolli         payframe-client.min.js taking directly from vantiv site |
 +============================================================================+*/
 
public class ODNewCCPayPageCO extends OAControllerImpl {

    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean) {

        super.processRequest(oapagecontext, oawebbean);
        
        oapagecontext.writeDiagnostics(this, "XXOD: start processRequest", 
                                       1);
                                       
       OAScriptBean scriptBean = null;
        String str = null;
        final OAWebBeanFactory fac = oapagecontext.getWebBeanFactory();
               
        scriptBean = 
                (OAScriptBean)fac.createWebBean(oapagecontext, SCRIPT_BEAN);
        scriptBean.setSource(oapagecontext.getAppsHtmlDirectory() + 
                             "jquery.min.js");
        oawebbean.addIndexedChild(scriptBean);

        scriptBean = (OAScriptBean)fac.createWebBean(oapagecontext, SCRIPT_BEAN);
        scriptBean.setSource(oapagecontext.getAppsHtmlDirectory() + "jquery.xml2json.js");
        oawebbean.addIndexedChild(scriptBean);
        
        
        DateFormat dateFormat = new SimpleDateFormat("yyyyMMdd");
        Date date = new Date();
        String todaysDateFormat = dateFormat.format(date);
      
        String vantivPayFrameURL = oapagecontext.getProfile("XX_OD_IREC_PAYPAGE_URL");
      
        scriptBean = (OAScriptBean)fac.createWebBean(oapagecontext, SCRIPT_BEAN);
        scriptBean.setSource(vantivPayFrameURL+"?d="+todaysDateFormat);
        
      
        scriptBean = (OAScriptBean)fac.createWebBean(oapagecontext, SCRIPT_BEAN);
        scriptBean.setSource(oapagecontext.getAppsHtmlDirectory() + "payframe-form.js");
        oawebbean.addIndexedChild(scriptBean);

       String sErrMsg = "";
       sErrMsg =  oapagecontext.getMessage("XXFIN", "XXOD_AR_IREC_PAYCC_LOADERR_MSG", null);
       oapagecontext.writeDiagnostics(this, "XXOD: sErrMsg"+sErrMsg, 1);

		
        String sPayHtml = 
       "<style> .hidecss {  display: none; } "+
       "label {  "+
       " font-family:Tahoma,Arial,Helvetica,Geneva,sans-serif; "+
       " font-size:small; "+
       " color:#3c3c3c; "+
       " font-weight:normal; "+
       " float: left; "+
       " width: 215px; "+
       "margin-right: 5px; "+
       "text-align: right; "+
       "         }  "+
       "#ODCardHolder { "+
       " font-family:Tahoma,Arial,Helvetica,Geneva,sans-serif; "+
       " font-size:small; "+
       " color:#3c3c3c; "+
       " background-color:#ffffff "+
       " }           "+
       "</style>" +
        "<table width='100%'><tr><td colspan='2'>"+
         "<div id='a_x100' style='display: none;'> <span class='alertsuccess' style='font-family:Tahoma,Arial,Helvetica,Geneva,sans-serif;font-size:small;font-weight: bold;color:#24C81C;margin-bottom:0px;margin-top:5px;margin-left:4px;padding-left:25px'>   </span> </div>"+
         "</td></tr>" +
         "<tr><td colspan='2'>"+
          "<div id='a_x200' style='display: none;'> <span class='alerterror' style='font-family:Tahoma,Arial,Helvetica,Geneva,sans-serif;font-size:11px;color:#AD0E25;font-weight: normal;margin-bottom:0px;margin-top:5px;margin-left:4px;padding-left:25px'>   </span>"+
          "</td></tr>"+
          "<tr><td colspan='2'>"+
          "<div id='a_x300' > <span class='alerterror' style='font-family:Tahoma,Arial,Helvetica,Geneva,sans-serif;font-size:11px;color:#AD0E25;font-weight: normal;margin-bottom:0px;margin-top:5px;margin-left:4px;padding-left:25px'>"+
          sErrMsg + " </span>"+
          "</td></tr>"+

         "</table>"+ 
         "<table width='700px' > "+
         "<tr> <td colspan='2'>"+
         "<div id='CardHolderFrame'> "+
"  <div class='carHolderDiv'> "+
 "   <div class='HolderDiv'> "+
  "    <label for='accountHolder'> "+
   "       <span id='accountHolderLabelBefore'></span> "+
    "      <span id='accountHolderLabelText'>Card Holder Name</span> "+
     "     <span id='accountHolderLabelAfter'></span> "+
     " </label>  "+
     " <input type='text' id='ODCardHolder'  name='ODCardHolder' required='true' maxlength='255' size='20' autocomplete='off' /> "+
    "</div> "+
  "</div> "+
        "</td> </tr> "+
        "</table>"+
        "<div id='payframecheckout' width='100%'>"+
        "<table width='700px' > "+
        "<tr> <td colspan='2'> <div id='payframe' width='100%'  > </div> "+
		"<div id='submitdiv' style='margin-left: 215px; display: none;'><input type='submit' id='submitId' title='Validate Card' value='Validate Card' size='20' /> </div></td> </tr> "+
        "<tr > <td><!--Paypage Registration ID--></td> " +
        "<td> <span style='display: none;'><input type='text' id='paypageRegistrationId' name='paypageRegistrationId' readOnly='true' value='0'/></span> </td>" +
        "</tr> " +
        "<tr class='hidecss'> <td>Bin</td> " +
        "<td><input type='text' id='bin' name='bin' readOnly='true' value=''/> </td> </tr> " +
        "</table> " +
        "</div> "+
        "<br/> " +
        "<table class='hidecss' border='1'> " +
        "<tr>" +
        "<td>Paypage ID</td> " +
        "<td><input type='text' id='request$paypageId' name='request$paypageId' value='S88Z46fLaW8WH2Ta' disabled/></td>" +
        "<td>Merchant Txn ID</td> " + 
        "<td><input type='hidden' id='request$merchantTxnId' name='request$merchantTxnId' value='987012'/></td>" +
        "</tr> " +
        "<tr> <td>Order ID</td> <td><input type='text' id='request$orderId' name='request$orderId' value='order_123'/></td> " +
        "<td>Report Group</td> <td><input type='text' id='request$reportGroup' name='request$reportGroup' value='*merchant1500' disabled/></td> </tr>" +
        "<tr> <td>JS Timeout</td> <td><input type='text' id='request$timeout' name='request$timeout' value='15000' disabled/></td> </tr> </table>" +
        "<table class='hidecss'> <tr> <td>Response Code</td> <td><input type='text' id='response$code' name='response$code' readOnly='true'/></td> <td>ResponseTime</td> " +
        "<td><input type='text' id='response$responseTime' name='response$responseTime' readOnly='true'/></td> </tr>" +
        "<tr> <td>Response Message</td> <td colspan='3'><input type='text' id='response$message' name='response$message' readOnly='true' size='100'/></td> </tr> " +
        "<tr> <td>&nbsp;</td> <td> </tr> <tr> <td>Vantiv Txn ID</td> <td><input type='text' id='response$litleTxnId' name='response$litleTxnId' readOnly='true'/></td> " +
        "<td>Merchant Txn ID</td> <td><input type='text' id='response$merchantTxnId' name='response$merchantTxnId' readOnly='true'/></td> </tr>" +
        "<tr> <td>Order ID</td> <td><input type='text' id='response$orderId' name='response$orderId' readOnly='true'/></td> <td>Report Group</td>" +
        "<td><input type='text' id='response$reportGroup' name='response$reportGroup' readOnly='true'/></td> </tr> <tr> <td>Type</td> " +
        "<td><input type='text' id='response$type' name='response$type' readOnly='true'/></td> </tr> <tr> <td>Expiration Month</td> " +
        "<td><input type='text' id='response$expMonth' name='response$expMonth' readOnly='true'/></td>" +
        "<td>Expiration Year</td> <td><input type='text' id='response$expYear' name='response$expYear' readOnly='true'/></td> </tr>" +
        "<tr> <td>&nbsp;</td> <td> </tr> <tr> <td>First Six</td> <td><input type='text' id='response$firstSix'name='response$firstSix' readOnly='true'/></td> " +
        "<td>Last Four</td> <td><input type='text' id='response$lastFour'name='response$lastFour' readOnly='true'/></td> </tr> " +
        "<tr> <td>Timeout Message</td> <td><input type='text' id='timeoutMessage' name='timeoutMessage' readOnly='true'/></td> </tr> " +
        "<tr> <td>Expected Results</td> <td colspan='3'> " +
        "<textarea id='expectedResults' name='expectedResults' rows='5' cols='100' readOnly='true'> CC Num - Token Generated (with simulator) 410000&#48;00000001 - 1111222&#50;33330001 5123456&#55;89012007 - 1112333&#51;44442007 3783102&#48;3312332 - 11134444&#53;552332 601100&#48;990190005 - 1114555&#53;66660005 </textarea></td> </tr> <tr> <td>Encrypted Card</td> " +
        "<td colspan='3'><textarea id='base64enc' name='base64enc' rows='5' cols='100' readOnly='true'></textarea></td> </tr>" +
        "</table>";
		

        OARawTextBean oarawtextbean = 
            (OARawTextBean)oawebbean.findChildRecursive("xPayframe");
      
        if (oarawtextbean != null)
            oarawtextbean.setText(sPayHtml);
        
		
	oapagecontext.writeDiagnostics(this, "XXOD: oarawtextbean.getText" +oarawtextbean.getText(), 
                                       1);
       
    
		
        OAMessageTextInputBean oamessagetextinputbean = (OAMessageTextInputBean)oawebbean.findIndexedChildRecursive("XXOD_PAYCC_MSGS");
        String sPayCCMsg = oapagecontext.getMessage("XXFIN", "XXOD_AR_IREC_PAYCC_MSG", null);
        
        if (oamessagetextinputbean!=null)
          oamessagetextinputbean.setText(sPayCCMsg);
        
        
        oapagecontext.writeDiagnostics(this, "XXOD: sPayCCMsg"+sPayCCMsg, 
                                       1);



        oapagecontext.writeDiagnostics(this, "XXOD: end processRequest", 
                                       1);

    }


         public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean) {
             oapagecontext.writeDiagnostics(this, "XXOD: start processFormRequest", 
                                            1);
                                            
             super.processFormRequest(oapagecontext, oawebbean);
             
             oapagecontext.writeDiagnostics(this, "XXOD: end processFormRequest", 
                                            1);
             
         }

}
