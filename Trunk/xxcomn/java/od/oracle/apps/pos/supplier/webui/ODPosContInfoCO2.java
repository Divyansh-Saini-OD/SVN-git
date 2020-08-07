package od.oracle.apps.xxfin.ap.pos.supplier.components.webui;


import oracle.apps.pos.supplier.components.webui.PosContInfoCO;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.*;


/**
 * Controller for Create contact page
 */
public class ODPosContInfoCO2 extends PosContInfoCO {
    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    /**
     * Layout and page setup logic for a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {

        //Calling super processrequest
        super.processRequest(pageContext, webBean);

        pageContext.writeDiagnostics(this, 
                                     "XXOD: ODPosContInfoCO processRequest Start ::: here", 
                                     1);

        //Getting handle to root am and oracle.apps.pos.supplier.components.server.PosContInfoAM
        OAApplicationModule am = pageContext.getRootApplicationModule();
        OAApplicationModule continfoAM = 
            (OAApplicationModule)am.findApplicationModule("oracle.apps.pos.supplier.components.server.PosContInfoAM");


        //getting handle to continfoVO
        OAViewObject continfoVO = 
            (OAViewObject)am.findViewObject("PosContInfoVO");

        pageContext.writeDiagnostics(this, "XXOD: ODPosContInfoCO Step 10.10***********", 
                                     1);


       // if (continfoVO != null) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: ODPosContInfoCO Step 10.20", 
                                         1);


            String s1 = pageContext.getParameter("PosPrfChgReq.ComingFrom");

            pageContext.writeDiagnostics(this, "XXOD: ODPosContInfoCO s1" + s1, 
                                         1);

            OAMessageTextInputBean msgb = 
                (OAMessageTextInputBean)webBean.findChildRecursive("PhExtn");
            String msg2 = msgb.getText(pageContext);
            pageContext.writeDiagnostics(this, "XXOD: msg2" + msg2, 1);

            if ("ByrAddCont".equals(s1)) {
                pageContext.writeDiagnostics(this, "XXOD: s1" + s1, 1);
                OADBTransaction oadb = am.getOADBTransaction();
                msgb.setValue(pageContext, 
                              oadb.getSequenceValue("TEST_S").toString());
                String msg3 = msgb.getText(pageContext);
                pageContext.writeDiagnostics(this, "XXOD: msg3" + msg3, 1);


            }


     //   }


        pageContext.writeDiagnostics(this, 
                                     "XXOD: ODPosContInfoCO processRequest End", 
                                     1);


    }


}
