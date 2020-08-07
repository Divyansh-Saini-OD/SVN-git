package od.oracle.apps.ar.irec.accountDetails.webui;

import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
//import oracle.cabo.ui.beans.BaseWebBean;
//import oracle.cabo.ui.beans.layout.TableLayoutBean;

public class ODShipToAddressCO extends IROAControllerImpl
{
    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);

        OATableLayoutBean oatablelayoutbean = (OATableLayoutBean)createWebBean(oapagecontext, "TABLE_LAYOUT");
        oatablelayoutbean.setCellSpacing(0);
        oawebbean.addIndexedChild(oatablelayoutbean);
        OAMessageStyledTextBean oamessagestyledtextbean = (OAMessageStyledTextBean)createWebBean(oapagecontext, "MESSAGE_TEXT");
        oamessagestyledtextbean.setStyleClass("OraFieldText");
        oamessagestyledtextbean.setText(oapagecontext, oawebbean.getLabel());
        addOAMessageStyledTextBean(oatablelayoutbean, oamessagestyledtextbean);

        OAMessageStyledTextBean oamessagestyledtextbean1 = null;
        String sInterfaceHeaderContext = null;
        try {
          oamessagestyledtextbean1 = (OAMessageStyledTextBean)createWebBean(oapagecontext, oawebbean, "XXItem12");
          sInterfaceHeaderContext = getTextFromViewObject(oapagecontext, oawebbean, oamessagestyledtextbean1);
        }
        catch (Exception ex) {}

        if(sInterfaceHeaderContext==null || sInterfaceHeaderContext.equals("CONVERSION"))
          ShowFields(oapagecontext,oawebbean,oatablelayoutbean,0,6,"Item");
        else
          ShowFields(oapagecontext,oawebbean,oatablelayoutbean,1,4,"XXItem");
    }

    private void ShowFields(OAPageContext oapagecontext, OAWebBean oawebbean, OATableLayoutBean oatablelayoutbean, int iFrom, int iTo, String sId) {
        for(int i = iFrom; i < iTo; i++) {
            OAMessageStyledTextBean oamessagestyledtextbean1 = (OAMessageStyledTextBean)createWebBean(oapagecontext, oawebbean, sId + i);
            String s = getTextFromViewObject(oapagecontext, oawebbean, oamessagestyledtextbean1);
            if(s != null && s.trim().length() != 0) {
                oamessagestyledtextbean1.setStyleClass("OraDataText");
                addOAMessageStyledTextBean(oatablelayoutbean, oamessagestyledtextbean1);
            }
        }
        OAMessageStyledTextBean oamessagestyledtextbean2 = (OAMessageStyledTextBean)createWebBean(oapagecontext, oawebbean, sId + "11");
        String s1 = getTextFromViewObject(oapagecontext, oawebbean, oamessagestyledtextbean2);
        if(s1 != null && s1.trim().length() != 0) {
            oamessagestyledtextbean2.setStyleClass("OraDataText");
            addOAMessageStyledTextBean(oatablelayoutbean, oamessagestyledtextbean2);
        }
    }

    public ODShipToAddressCO()
    {
    }

    public static final String RCS_ID = "$Header: ODShipToAddressCO.java 115.12 2003/05/12 21:53:53 albowicz noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODShipToAddressCO.java 115.12 2003/05/12 21:53:53 albowicz noship $", "od.oracle.apps.ar.irec.accountDetails.webui");

}
