package od.oracle.apps.xxfin.ap.pos.supplier.webui;

/*===========================================================================+
 |                                                                           |
 +===========================================================================+
 |  HISTORY                                                                  |
 |  02-JAN-2015   MBOLLI    1.0   Initial Version                            |
+===========================================================================*/
/* Red .....*/

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OASwitcherBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.pos.supplier.webui.BusClassCO;

public class ODBusClassCO extends BusClassCO {
    public ODBusClassCO() {
    }

    public static final String RCS_ID = "$Header: ODBusClassCO.java 12.0 2015/01/02 21:53:53 mbolli noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODBusClassCO.java 12.0 2015/01/02 21:53:53 mbolli noship $", "od.oracle.apps.xxfin.ap.pos.supplier.webui");
    
    public void processRequest(OAPageContext pageContext,
                                   OAWebBean webBean) {
        super.processRequest(pageContext, webBean);

        OAApplicationModule oam = pageContext.getApplicationModule(webBean) ;
        if (oam != null) {
        
            OAViewObject foreignMinVO=  (OAViewObject)oam.findViewObject("ODForeignMinorityTypeVO1") ;
            if ( foreignMinVO != null ) {
                 putLog(pageContext, webBean, "ODBusClassCO.PR() - ODForeignMinorityTypeVO already assigned to AM", 3);
            } else
            {
                putLog(pageContext, webBean, "ODBusClassCO.PR() - ODForeignMinorityTypeVO Not assigned to AM", 3);
                foreignMinVO = (OAViewObject)oam.createViewObject("ODForeignMinorityTypeVO1", "od.oracle.apps.xxfin.ap.pos.supplier.server.ODForeignMinorityTypeVO") ; 
            }        
            // Get the Swticher Region handle
            OASwitcherBean minoritySw = (OASwitcherBean)webBean.findIndexedChildRecursive("MinoryTypeRN");
                  //  (OASwitcherBean)createWebBean(pageContext, OAWebBeanConstants.SWITCHER_BEAN, null,"MinoryTypeRN");
            
            // Create a MessageChoice Bean and set its properties
            OAMessageChoiceBean foreignMinorityType = (OAMessageChoiceBean)createWebBean(pageContext, OAWebBeanConstants.MESSAGE_CHOICE_BEAN, null, "ForeignMinorityType");
            
            if(foreignMinorityType != null) {
                foreignMinorityType.setViewUsageName("BusClassVO1");
                foreignMinorityType.setViewAttributeName("ExtAttr1");
                foreignMinorityType.setDataType("VARCHAR2");
                foreignMinorityType.setPickListViewUsageName("ODForeignMinorityTypeVO1");
                foreignMinorityType.setListValueAttribute("LookupCode");
                foreignMinorityType.setListDisplayAttribute("Meaning" );
               // foreignMinorityType.setID("ForeignMinorityType");
            }
            
            // Add the newly created MsgssChoiceBn to the Switcher as the case.  
            if(minoritySw != null) {
                putLog(pageContext, webBean, "ODBusClassCO.PR() - Switch Case assigned", 3);
                minoritySw.setNamedChild(foreignMinorityType.getID(), foreignMinorityType );   
            } else {
                putLog(pageContext, webBean, "ODBusClassCO.PR() - Switcher Region is NULL", 3);
            }
         } // oam!= null  
         else {
             putLog(pageContext, webBean, "ODBusClassCO.PR() - OAM is NULL", 3);
         }
    }

    public void putLog(OAPageContext pageContext, OAWebBean webBean, Object o,
                       int i) {
        String msg = "";
        if (o != null) {
            msg = o.toString();
        }
        if(pageContext.isLoggingEnabled(i)) {
            pageContext.writeDiagnostics(this, msg, i);
        }
    }    
}
