package oracle.apps.ar.irec.accountDetails.cm.webui;
/*----------------------------------------------------------------------------
 -- Author: Vasu Raparla
 -- Component Id: E1293, E1327 and E2052
 -- Script Location: $CUSTOM_JAVA_TOP/oracle/apps/ar/irec/accountDetails/cm/webui
 -- Description: Considered R12 code version and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Vasu Raparla  18-Aug-2016  1.0        Retrofitted for R12.2.5 Upgrade.
---------------------------------------------------------------------------*/
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.*;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;

// Referenced classes of package oracle.apps.ar.irec.accountDetails.cm.webui:
//            CmLinesOrActivitiesCO

public class CmCO extends CmLinesOrActivitiesCO
{

    public CmCO()
    {
    }

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        oawebbean.addIndexedChild(createWebBean(oapagecontext, oawebbean, "Aridisplaytype"));
        if(addBPA(oapagecontext, oawebbean))
        {
            return;
        } else
        {
            OATableLayoutBean oatablelayoutbean = (OATableLayoutBean)createWebBean(oapagecontext, "TABLE_LAYOUT", null, null);
            oatablelayoutbean.setWidth("100%");
            oawebbean.addIndexedChild(oatablelayoutbean);
            OASpacerBean oaspacerbean = (OASpacerBean)createWebBean(oapagecontext, "SPACER", null, null);
            oaspacerbean.setWidth(10);
            oaspacerbean.setHeight(20);
            addRow(oapagecontext, oawebbean, oatablelayoutbean, "Aricmheader");
            addRow(oapagecontext, oawebbean, oatablelayoutbean, oaspacerbean);
            Object obj = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, null);
            oatablelayoutbean.addRowLayout(((oracle.cabo.ui.beans.layout.RowLayoutBean) (obj)));
            ((OARowLayoutBean) (obj)).addIndexedChild(createWebBean(oapagecontext, oawebbean, "Aricmdetailssummary"));
            addRow(oapagecontext, oawebbean, oatablelayoutbean, oaspacerbean);
            addRow(oapagecontext, oawebbean, oatablelayoutbean, "Aricmlinesoractivitieswrapper");
            obj = (OAMessageStyledTextBean)createWebBean(oapagecontext, "MESSAGE_TEXT", null, null);
            ((OAMessageStyledTextBean) (obj)).setStyleClass("OraInstructionText");
            ((OAMessageStyledTextBean) (obj)).setText(oapagecontext, oapagecontext.getMessage("AR", "ARI_CONTACT_HINT", null));
            addRow(oapagecontext, oawebbean, oatablelayoutbean, ((OAMessageStyledTextBean) (obj)));
            return;
        }
    }

    private boolean isOnAccountCreditMemo(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        if(oapagecontext.isLoggingEnabled(1))
            oapagecontext.writeDiagnostics(this, "Start isOnAccountCreditMemo", 1);
        Boolean boolean1 = (Boolean)oapagecontext.getApplicationModule(oawebbean).invokeMethod("isOnAccountCreditMemo");
        return boolean1.booleanValue();
    }

    private void addRow(OAPageContext oapagecontext, OAWebBean oawebbean, OATableLayoutBean oatablelayoutbean, String s)
    {
        OARowLayoutBean oarowlayoutbean = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, null);
        oatablelayoutbean.addRowLayout(oarowlayoutbean);
        OACellFormatBean oacellformatbean = (OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT", null, null);
        oarowlayoutbean.addIndexedChild(oacellformatbean);
        oacellformatbean.addIndexedChild(createWebBean(oapagecontext, oawebbean, s));
    }

    private void addRow(OAPageContext oapagecontext, OAWebBean oawebbean, OATableLayoutBean oatablelayoutbean, OASpacerBean oaspacerbean)
    {
        OARowLayoutBean oarowlayoutbean = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, null);
        oatablelayoutbean.addRowLayout(oarowlayoutbean);
        OACellFormatBean oacellformatbean = (OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT", null, null);
        oarowlayoutbean.addIndexedChild(oacellformatbean);
        oacellformatbean.addIndexedChild(oaspacerbean);
    }

    private void addRow(OAPageContext oapagecontext, OAWebBean oawebbean, OATableLayoutBean oatablelayoutbean, OAMessageStyledTextBean oamessagestyledtextbean)
    {
        OARowLayoutBean oarowlayoutbean = (OARowLayoutBean)createWebBean(oapagecontext, "ROW_LAYOUT", null, null);
        oatablelayoutbean.addRowLayout(oarowlayoutbean);
        OACellFormatBean oacellformatbean = (OACellFormatBean)createWebBean(oapagecontext, "CELL_FORMAT", null, null);
        oarowlayoutbean.addIndexedChild(oacellformatbean);
        oacellformatbean.addIndexedChild(oamessagestyledtextbean);
    }

    private void setPageHeader(OAPageContext oapagecontext, OAWebBean oawebbean, String s)
    {
        if(oapagecontext.isLoggingEnabled(1))
            oapagecontext.writeDiagnostics(this, "Start setPageHeader", 1);
        String s1 = (String)oapagecontext.getApplicationModule(oawebbean).invokeMethod("getCurTrxNumber");
        MessageToken amessagetoken[] = {
            new MessageToken("TRXID", s1)
        };
        OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
        oapagelayoutbean.setTitle(oapagecontext.getMessage("AR", s, amessagetoken));
    }

    public static String[] staticQueriesToInvoke()
    {
        String as[] = new String[0];
        return as;
    }

    public static String staticGetRegionID()
    {
        return "CM_LINES";
    }

    protected String[] queriesToInvoke()
    {
        return staticQueriesToInvoke();
    }

    protected String getRegionID()
    {
        return staticGetRegionID();
    }

    protected void setDefaultVisibility(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        setRendered(oapagecontext, oawebbean, true);
    }

    protected void setRendered(OAPageContext oapagecontext, OAWebBean oawebbean, boolean flag)
    {
        if(oapagecontext.isLoggingEnabled(1))
            oapagecontext.writeDiagnostics(this, "Start setRendered", 1);
        StringBuffer stringbuffer = null;
        stringbuffer = new StringBuffer("ARI_CM");
        StringBuffer stringbuffer1 = new StringBuffer(stringbuffer.toString());
        if(flag)
        {
            stringbuffer.append("_PAGE_HEADER");
            stringbuffer1.append("_PAGE_TITLE");
        } else
        {
            stringbuffer.append("ACTIVITIES_PAGE_HEADER");
            stringbuffer1.append("_ACTIVITIES_PAGE_TITLE");
        }
        setPageHeader(oapagecontext, oawebbean, stringbuffer.toString());
        OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
        oapagelayoutbean.setWindowTitle(oapagecontext.getMessage("AR", stringbuffer1.toString(), null));
        oapagecontext.resetMenuContext("ARIACCOUNT");
        if(!isPrintablePageMode(oapagecontext))
        {
            handleMenusAndCustomerBranding(oapagecontext, oawebbean);
            setContactUsURL(oapagecontext, oawebbean);
            appendParamstoTransactionListUrl(oapagecontext);
        }
    }
    // For R12 upgrade retrofit - renamed from addBPA
    private boolean addBPA_orig(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        String s = oapagecontext.getParameter("Irtransactiontype");
        String s1 = oapagecontext.getParameter("Aridisplaytype");
        if("CM".equals(s) && !"CM_ACTIVITIES".equals(s1))
        {
            oawebbean.addIndexedChild(createWebBean(oapagecontext, oawebbean, "BPAInvoice"));
            return true;
        } else
        {
            return false;
        }  
    }
    // Added for R12 upgrade retrofit
      // Added for OD Credit Memo Printable Page output
        private boolean addBPA(OAPageContext oapagecontext, OAWebBean oawebbean)
        {
            String s1 = oapagecontext.getParameter("Irtransactiontype");
            String s2 = oapagecontext.getParameter("Aridisplaytype");
            String s3 = oapagecontext.getParameter("ViewType");
            if("CM".equals(s1) && !"CM_ACTIVITIES".equals(s2) && "PRINT".equals(s3))
            {
                oawebbean.addIndexedChild(createWebBean(oapagecontext, oawebbean, "BPAInvoice"));
                return true;
            } else
            {
                return false;
            }
        }

    public static final String RCS_ID = "$Header: CmCO.java 120.12.12020000.2 2012/07/21 17:46:10 rsinthre ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: CmCO.java 120.12.12020000.2 2012/07/21 17:46:10 rsinthre ship $", "oracle.apps.ar.irec.accountDetails.cm.webui");

}
