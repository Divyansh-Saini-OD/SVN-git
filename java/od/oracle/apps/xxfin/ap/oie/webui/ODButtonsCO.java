package od.oracle.apps.xxfin.ap.oie.webui;


import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.jbo.Row;
import oracle.jbo.ViewObject;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.ap.oie.webui.ButtonsCO;
import oracle.apps.ap.oie.webui.NavigationUtility;



public class ODButtonsCO extends ButtonsCO
{
    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
       super.processRequest(oapagecontext,oawebbean);

       disableSubmitIfMissingReceipts(oapagecontext,oawebbean);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        if(oapagecontext.getParameter("OIESubmit") != null)
        {
            OAApplicationModule oam = oapagecontext.getApplicationModule(oawebbean);
            if(NavigationUtility.isOIERequestStale(oapagecontext))
            {
                try
                {
                    oam.invokeMethod("validateHeader");
                }
                catch(OAException oaexception)
                {
                    oapagecontext.putDialogMessage(oaexception);
                    NavigationUtility.forwardToPage(oapagecontext, "GeneralInformationPG", null);
                }
                try
                {
                    String s3 = null;
                    Serializable aserializable2[] = {
                        Boolean.FALSE, Boolean.TRUE
                    };
                    Class aclass2[] = {
                        java.lang.Boolean.class, java.lang.Boolean.class
                    };
                    s3 = (String)oam.invokeMethod("validateReportLines", aserializable2, aclass2);
                }
                catch(OAException _ex)
                {
                    HashMap hashmap = new HashMap();
                    hashmap.put("ButtonLink", null);
                    NavigationUtility.forwardToPage(oapagecontext, "CashAndOtherLinesPG", hashmap);
                }
            }
            forceSave(oapagecontext);

            ViewObject voExpenseReportHeaders = oam.findViewObject("ExpenseReportHeadersVO");
            voExpenseReportHeaders.executeQuery();
            Row rowExpenseReportHeaders = voExpenseReportHeaders.first();
            String sMissingReceipts = (String)rowExpenseReportHeaders.getAttribute("sMissingReceipts");

            if ("Y".equals(sMissingReceipts)) {
               OASubmitButtonBean oasubmitbuttonbean = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("OIESubmit");
               oasubmitbuttonbean.setDisabled(true);
               return;
            }
        }

        super.processFormRequest(oapagecontext,oawebbean);

        disableSubmitIfMissingReceipts(oapagecontext,oawebbean);
    }

    public void disableSubmitIfMissingReceipts(OAPageContext oapagecontext, OAWebBean oawebbean) {

      String pageName = NavigationUtility.getCurrentPage(oapagecontext);
      if("FinalReviewPG".equals(pageName)) {

        OAApplicationModule oam = oapagecontext.getApplicationModule(oawebbean);
        ViewObject voExpenseReportHeaders = oam.findViewObject("ExpenseReportHeadersVO");
        voExpenseReportHeaders.executeQuery();
        Row rowExpenseReportHeaders = voExpenseReportHeaders.first();
        String sMissingReceipts = (String)rowExpenseReportHeaders.getAttribute("sMissingReceipts");

        OASubmitButtonBean oasubmitbuttonbean = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("OIESubmit");
        if ("Y".equals(sMissingReceipts)) {
          oasubmitbuttonbean.setDisabled(true);
//        oasubmitbuttonbean.setRendered(true); // alternative
        }
        else {
          oasubmitbuttonbean.setDisabled(false);
        }
      }
    }

    public void forceSave(OAPageContext oapagecontext) {
      Serializable aserializable1[] = {
        null, Boolean.FALSE
      };
      Class aclass1[] = {
        java.lang.String.class, java.lang.Boolean.class
      };
      OAApplicationModule oaapplicationmodule = oapagecontext.getRootApplicationModule();
      oaapplicationmodule.invokeMethod("saveExpenseReport", aserializable1, aclass1);
      MessageToken amessagetoken[] = {
        new MessageToken("INVOICENUM", (String)oaapplicationmodule.invokeMethod("getInvoiceNum")), new MessageToken("REPORTTOTAL", (String)oaapplicationmodule.invokeMethod("getReportTotal"))
      };
      OAException oaexception2 = new OAException("SQLAP", "OIE_EXP_REPORT_SAVE", amessagetoken, (byte)2, null);
      oaexception2.setApplicationModule(oaapplicationmodule);
      oapagecontext.putDialogMessage(oaexception2);
      oapagecontext.putParameter("ButtonLink", "ValidateForSave");
    }

    public ODButtonsCO()
    {
    }
}