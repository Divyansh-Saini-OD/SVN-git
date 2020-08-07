package od.oracle.apps.xxfin.ap.pos.registration.webui;

/*===========================================================================+
 |                                                                           |
 +===========================================================================+
 |  HISTORY                                                                  |
 |  20-JAN-2016   MBOLLI    1.0   Initial Version - iSupplier                            |
+===========================================================================*/

import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.pos.registration.server.RegistrationVOImpl;
import oracle.apps.pos.registration.server.RegistrationVORowImpl;
import oracle.apps.pos.registration.webui.AdminRegCO;

public class ODAdminRegCO extends AdminRegCO {

    public ODAdminRegCO()
    {
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        OAApplicationModule am = oapagecontext.getApplicationModule(oawebbean);
        HashMap hashmap = new HashMap();
        
        // When this event fires don't do anything
        if("EmailUpdate".equals(oapagecontext.getParameter("event")))
        {            
            
            String supNum = null;
            RegistrationVOImpl regVO = (RegistrationVOImpl)am.findViewObject("RegistrationVO");
            if(regVO != null){
                RegistrationVORowImpl regRow = (RegistrationVORowImpl)regVO.getCurrentRow();
                if(regRow != null) {
                    supNum  = (String)regRow.getSupplierNumberDisplay();
                    regRow.setAttribute("RequestedUserName", "ISUP_"+supNum+"_");
                }
            }
           
            return;
        } else if (oapagecontext.getParameter("Register_Button") != null) {            
                //OADBTransaction oadbtransaction = oapagecontext.getApplicationModule(oawebbean).getOADBTransaction();
                

            
                 String reqUserName = null;
                 String supNum = null;
                 String userNameValid = null;
                 
                RegistrationVOImpl regVO = (RegistrationVOImpl)am.findViewObject("RegistrationVO");
                if(regVO != null){
                    RegistrationVORowImpl regRow = (RegistrationVORowImpl)regVO.getCurrentRow();
                    if(regRow != null) {
                        reqUserName = regRow.getRequestedUserName();
                        supNum  = (String)regRow.getSupplierNumberDisplay();
                    }
                }
                if (supNum != null) {
                    userNameValid = "ISUP_"+supNum+"_";
                }
                
               // oapagecontext.writeDiagnostics(this, "supNum is "+supNum, OAFwkConstants.STATEMENT);
               // oapagecontext.writeDiagnostics(this, "reqUserName is "+reqUserName, OAFwkConstants.STATEMENT);
               // oapagecontext.writeDiagnostics(this, "userNameValid is "+userNameValid, OAFwkConstants.STATEMENT);
            
                if(reqUserName == null || userNameValid == null || !(reqUserName.startsWith(userNameValid)) || !(reqUserName.equals(reqUserName.toUpperCase()))
                        || (userNameValid.equals(reqUserName))) {
                    MessageToken[] tokens = { new MessageToken("VALID_USER_NAME", userNameValid) };
                    OAException userNameException = new OAException("POS", "OD_POS_USER_NAME_INVALID", tokens);
                    oapagecontext.putDialogMessage(userNameException);
                    oapagecontext.forwardImmediatelyToCurrentPage(hashmap, true, "N");     
                    return;
                }
                
                
                OAViewObject tmpSASitesVO;
                tmpSASitesVO = (OAViewObject)oapagecontext.getApplicationModule(oawebbean).findViewObject("TempSASitesVO");
                int cnt = tmpSASitesVO.getFetchedRowCount();

                if (cnt <= 0) {
                   // oapagecontext.writeDiagnostics("pos.registration", "tmpSASitesVO - Throw error message "+cnt2, 4);
                    OAException oaexception1 = new OAException("POS", "OD_POS_NO_VENDOR_SITE");
                    oapagecontext.putDialogMessage(oaexception1);
                    oapagecontext.forwardImmediatelyToCurrentPage(hashmap, true, "N");
                    
                    return; 
                }
        }
        super.processFormRequest(oapagecontext,oawebbean);
    }
}
