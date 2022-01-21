package oracle.apps.ar.irec.accountDetails.inv.webui;
/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1293, E1327, E2052, E1356
 -- Script Location: $CUSTOM_JAVA_TOP/oracle/apps/ar/irec/accountDetails/inv/webui
 -- Description: Considered R12 code version and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 27-Jul-2013  1.0        Retrofitted for R12 Upgrade.
 -- Sridevi Kondoju 2-Sep-2013   2.0        updated for RICE E1356
 -- Vasu Raparla    18-Aug-2016  3.0        Retrofitted for R12.2.5 Upgrade.
---------------------------------------------------------------------------*/
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.*;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;

//
//  The only customization to this class is an override of addBPA method to get the OD Invoice Printable Page output (an enhancement of E1293)
//

// Referenced classes of package oracle.apps.ar.irec.accountDetails.inv.webui:
//            LinesOrActivitiesCO, LineItemsCO

public class InvoiceCO extends LinesOrActivitiesCO
{

    public InvoiceCO()
    {
    }

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        if(oapagecontext.isLoggingEnabled(2))
         oapagecontext.writeDiagnostics(this, "processRequest+++++", 2);
        if(addBPA(oapagecontext, oawebbean))
            return;
        if(oapagecontext.isLoggingEnabled(2))
            oapagecontext.writeDiagnostics(this, "After ADD BPA", 2);
            
        oapagecontext.writeDiagnostics(this, "XXOD: step 1", 1);  
        OATableLayoutBean oatablelayoutbean = (OATableLayoutBean)createWebBean(oapagecontext, "TABLE_LAYOUT", null, null);
        oatablelayoutbean.setWidth("100%");
        oawebbean.addIndexedChild(oatablelayoutbean);
        OASpacerBean oaspacerbean = (OASpacerBean)createWebBean(oapagecontext, "SPACER", null, null);
        oaspacerbean.setWidth(10);
        oaspacerbean.setHeight(10);
        OARowLayoutBean oarowlayoutbean = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, null);
        oatablelayoutbean.addRowLayout(oarowlayoutbean);
        OACellFormatBean oacellformatbean = (OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT", null, null);
        oarowlayoutbean.addIndexedChild(oacellformatbean);
        // invoice header region..
        oacellformatbean.addIndexedChild(createWebBean(oapagecontext, oawebbean, "Arinestedregion1"));
        oarowlayoutbean = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, null);
        oatablelayoutbean.addRowLayout(oarowlayoutbean);
        oacellformatbean = (OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT", null, null);
        oarowlayoutbean.addIndexedChild(oacellformatbean);
        oacellformatbean.addIndexedChild(oaspacerbean);
        
        oarowlayoutbean = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, null);
        oatablelayoutbean.addRowLayout(oarowlayoutbean);
        oarowlayoutbean.addIndexedChild(createWebBean(oapagecontext, oawebbean, "Irterms"));
        oapagecontext.writeDiagnostics(this, "XXOD: step 2", 1);
        
        oarowlayoutbean = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, null);
        oatablelayoutbean.addRowLayout(oarowlayoutbean);
        oacellformatbean = (OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT", null, null);
        oarowlayoutbean.addIndexedChild(oacellformatbean);
        oacellformatbean.addIndexedChild(createWebBean(oapagecontext, oawebbean, "Arinestedregion2"));
        
        oapagecontext.writeDiagnostics(this, "XXOD: step 3", 1);
        
        oarowlayoutbean = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, null);
        oatablelayoutbean.addRowLayout(oarowlayoutbean);
        oacellformatbean = (OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT", null, null);
        oarowlayoutbean.addIndexedChild(oacellformatbean);
        oapagecontext.writeDiagnostics(this, "XXOD: step 4", 1);

        
        OAStyledTextBean oastyledtextbean = (OAStyledTextBean)createWebBean(oapagecontext, "TEXT", null, null);
        oastyledtextbean.setStyleClass("OraInstructionText");
        
        oastyledtextbean.setText(oapagecontext, oapagecontext.getMessage("AR", "ARI_INVOICE_TERMS", null));
        oacellformatbean.addIndexedChild(oastyledtextbean);
        oapagecontext.writeDiagnostics(this, "XXOD: step 5", 1);
        oarowlayoutbean = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, null);
        oatablelayoutbean.addRowLayout(oarowlayoutbean);
        oacellformatbean = (OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT", null, null);
        oarowlayoutbean.addIndexedChild(oacellformatbean);
        oacellformatbean.addIndexedChild(oaspacerbean);
        oapagecontext.writeDiagnostics(this, "XXOD: addbpa false completed", 1);
        
        if(oapagecontext.isLoggingEnabled(2))
            oapagecontext.writeDiagnostics(this, "processRequest----", 2);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
    }

    private void setPageHeader(OAPageContext oapagecontext, OAWebBean oawebbean, String s)
    {
        OAMessageStyledTextBean oamessagestyledtextbean = (OAMessageStyledTextBean)createWebBean(oapagecontext, oawebbean, "Irtransaction");
        String s1 = getTextFromViewObject(oapagecontext, oawebbean, oamessagestyledtextbean);
        MessageToken amessagetoken[] = {
            new MessageToken("TRXID", s1.toString())
        };
        OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
        oapagelayoutbean.setTitle(oapagecontext.getMessage("AR", s, amessagetoken));
    }

    protected String[] queriesToInvoke()
    {
        String as[] = new String[0];
        return as;
    }

    protected String getRegionID()
    {
        return LineItemsCO.staticGetRegionID();
    }

    protected void setDefaultVisibility(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        boolean flag = true;
        String s = oapagecontext.getParameter(LinesOrActivitiesCO.getSubmitTypeName());
        if("INVOICE_ACTIVITIES".equals(s))
            flag = false;
        setRendered(oapagecontext, oawebbean, flag);
    }

    protected void setRendered(OAPageContext oapagecontext, OAWebBean oawebbean, boolean flag)
    {
        String s = oapagecontext.getParameter("Irtransactiontype");
        String s1 = null;
        if("INV".equals(s))
            s1 = "ARI_INV";
        else
        if("DM".equals(s))
            s1 = "ARI_DM";
        else
        if("DEP".equals(s))
            s1 = "ARI_DEP";
        else
        if("CB".equals(s))
            s1 = "ARI_CB";
        else
        if("GUAR".equals(s))
            s1 = "ARI_GUAR";
        if(flag)
            s1 = (new StringBuilder()).append(s1).append("_PAGE_HEADER").toString();
        else
            s1 = (new StringBuilder()).append(s1).append("ACTIVITIES_PAGE_HEADER").toString();
        setPageHeader(oapagecontext, oawebbean, s1);
    }
    
    // Added for OD Invoice Printable Page output
       private boolean addBPA(OAPageContext oapagecontext, OAWebBean oawebbean)
       {
                   oapagecontext.writeDiagnostics(this, "XXOD: start OD addBPA", 1);

           String s1 = oapagecontext.getParameter("Irtransactiontype");
           String s2 = oapagecontext.getParameter(LinesOrActivitiesCO.getSubmitTypeName());
           String s3 = oapagecontext.getParameter("ViewType");

                   oapagecontext.writeDiagnostics(this, "XXOD: s1:"+s1+" s2:"+s2+" s3:"+s3, 1);
           
           
                   if("INV".equals(s1) && !"INVOICE_ACTIVITIES".equals(s2) && "PRINT".equals(s3))
           {
               oawebbean.addIndexedChild(createWebBean(oapagecontext, oawebbean, "BPAInvoice"));
                           oapagecontext.writeDiagnostics(this, "XXOD: addbpa TRUE", 1);
                           oapagecontext.writeDiagnostics(this, "XXOD: end OD addBPA", 1);
               return true;
           } else
           {
                           oapagecontext.writeDiagnostics(this, "XXOD: addbpa FALSE", 1);
                           oapagecontext.writeDiagnostics(this, "XXOD: end OD addBPA", 1);
               return false;
           }
                   
                   
       }

    private boolean addBPA_orig(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        if(oapagecontext.isLoggingEnabled(2))
            oapagecontext.writeDiagnostics(this, "addBPA+++++", 2);
        String s = oapagecontext.getParameter("Irtransactiontype");
        oapagecontext.writeDiagnostics(this, "XXOD: s:"+ s, 1);
        if(oapagecontext.isLoggingEnabled(2))
            oapagecontext.writeDiagnostics(this, (new StringBuilder()).append("type-->").append(s).toString(), 2);
        String s1 = oapagecontext.getParameter(LinesOrActivitiesCO.getSubmitTypeName());
        oapagecontext.writeDiagnostics(this, "XXOD: s1:"+ s1, 1);
        if(oapagecontext.isLoggingEnabled(2))
            oapagecontext.writeDiagnostics(this, (new StringBuilder()).append("viewType-->").append(s1).toString(), 2);
        if(("INV".equals(s) || "DM".equals(s) || "DEP".equals(s) || "CB".equals(s) || "GUAR".equals(s)) && !"INVOICE_ACTIVITIES".equals(s1))
        {
            oapagecontext.writeDiagnostics(this, "XXOD: before createwebbean BPAInvoice", 1);
            
            oawebbean.addIndexedChild(createWebBean(oapagecontext, oawebbean, "BPAInvoice"));
            
            oapagecontext.writeDiagnostics(this, "XXOD: after createwebbean BPAInvoice", 1);
            return true;
        } else
        {  
        oapagecontext.writeDiagnostics(this, "XXOD: addBPA returns false", 1);
            return false;
        }
    }

    public static final String RCS_ID = "$Header: InvoiceCO.java 120.6.12020000.2 2014/12/10 14:24:35 ssiddams ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: InvoiceCO.java 120.6.12020000.2 2014/12/10 14:24:35 ssiddams ship $", "oracle.apps.ar.irec.accountDetails.inv.webui");

}
