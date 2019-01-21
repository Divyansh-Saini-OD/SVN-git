package od.oracle.apps.xxfin.ar.irec.accountDetails.webui;

/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |                       Oracle Consulting Organization                |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             OD_AllDebitTrxResultsCO                                           |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This java file is extended from AllDebitTrxResultsCO                      |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 |Change Record:                                                             |
 |===============                                                            |
 | Date         Author                Remarks                                |
 | ==========   =============         =======================                |
 | 08-Oct-2013  Suraj Charan         Created for the Defect #25448           |
 |                                                                           |
 +===========================================================================+*/

import oracle.apps.ar.irec.accountDetails.server.AccountDetailsAMImpl;
import oracle.apps.ar.irec.accountDetails.server.AllDebTrxTableVORowImpl;
import oracle.apps.ar.irec.accountDetails.webui.AllDebitTrxResultsCO;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.jbo.RowSetIterator;

public class OD_AllDebitTrxResultsCO extends AllDebitTrxResultsCO {
    public static final String RCS_ID="$Header$";
    public static final boolean RCS_ID_RECORDED =
          VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    /**
     * Layout and page setup logic for a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
     super.processRequest(pageContext, webBean);
     if(pageContext.getSessionValue("ClearTransaction") != null && !"".equals(pageContext.getSessionValue("ClearTransaction"))) {
         if("TRUE".equals(pageContext.getSessionValue("ClearTransaction"))){
             pageContext.writeDiagnostics(this,"##### Inside PR TrxListClear is TRUE",1);
             OAApplicationModule am = (AccountDetailsAMImpl)pageContext.getApplicationModule(webBean);
             unCheckAllTrxFlag(pageContext, am);
             
         }
     }
        pageContext.writeDiagnostics(this,"##### EVENT="+pageContext.getParameter(EVENT_PARAM),1);
    }
    public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
    {
    super.processFormRequest(pageContext, webBean);
    }
    
    public void unCheckAllTrxFlag(OAPageContext pageContext,OAApplicationModule am)
    {
        pageContext.writeDiagnostics(this,"##### Inside PR unCheckAllTrxFlag",1);
        OAViewObject vo = (OAViewObject)am.findViewObject("AllDebTrxTableVO");
        if(vo != null)
        {
          OARow oarow = null;
            try{
               RowSetIterator rowsetiterator = vo.createRowSetIterator("iter");
               rowsetiterator.reset();
               while(rowsetiterator.hasNext()) 
               {
                pageContext.writeDiagnostics(this,"##### Inside rowsetiterator",1);
                OAViewRowImpl oaviewrowimpl = (AllDebTrxTableVORowImpl)rowsetiterator.next();
                if(oaviewrowimpl.getAttribute("SelectedFlag")!= null){
                    pageContext.writeDiagnostics(this,"##### Inside SelectedFlag",1);
                    String flag = oaviewrowimpl.getAttribute("SelectedFlag").toString();
                    if("Y".equals(flag)){
                        pageContext.writeDiagnostics(this,"##### Setting N to SelectedFlag",1);
                        oaviewrowimpl.setAttribute("SelectedFlag","N")    ;
                    }
               }
            }
            }
            catch(Exception e){
                pageContext.writeDiagnostics(this,"##### Inside rowsetiterator Error="+e,1); 
            }
        }
    }
}
