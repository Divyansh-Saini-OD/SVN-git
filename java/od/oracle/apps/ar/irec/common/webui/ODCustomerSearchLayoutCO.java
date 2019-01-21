// Source File Name:   ODCustomerSearchLayoutCO.java

package od.oracle.apps.ar.irec.common.webui;

import java.util.StringTokenizer;
import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.ar.irec.common.webui.CustomerSearchLayoutCO;

public class ODCustomerSearchLayoutCO extends CustomerSearchLayoutCO
{

    public ODCustomerSearchLayoutCO()
    {
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        if(oapagecontext.isLoggingEnabled(1))
            oapagecontext.writeDiagnostics(this, "Start processFormRequest", 1);
        String s = oapagecontext.getParameter("IrSearchKeyword");
        String s1 = oapagecontext.getParameter("IrSearchTypePoplist");
        String s2 = oapagecontext.getParameter("event");
        if(oapagecontext.getParameter("Icxgocontrol") == null || "show".equals(s2) || "hide".equals(s2) || "goto".equals(s2))
        {
            s = oapagecontext.getParameter("SearchKeyword");
            s1 = oapagecontext.getParameter("SearchTypePoplist");
        }
        if(!"show".equals(s2) && !"hide".equals(s2) && !"goto".equals(s2) && !"sort".equals(s2) && null != oapagecontext.getParameter("Icxgocontrol"))
        {
            String s3 = oapagecontext.getProfile("OIR_MINIMUM_CHAR_SEARCH");
            MessageToken amessagetoken[] = {
                new MessageToken("CHARACTERS", s3)
            };
            String s4 = oapagecontext.getMessage("AR", "ARI_MIN_CHAR_SEARCH", amessagetoken);
            if(s == null || "".equals(s))
            {
                if(s3 != null && !"0".equals(s3))
                    throw new OAException(s4, (byte)1);
                s = "*";
            } else
            if(s3 != null && !"0".equals(s3) && s.length() < Integer.parseInt(s3))
                throw new OAException(s4, (byte)1);
                    
            if(isInternalCustomer(oapagecontext, oawebbean)){
                if(s1 != null && !"".equals(s1) && s != null && (s.indexOf('*') != -1 || s.indexOf('%') != -1))    
                  throw new OAException("XXFIN", "XXFIN_TRX_WILDCARD_NOT_ALLOWED");
                if(!isValidKeyWord(s))
                  throw new OAException("AR", "ARI_CUST_EMPTY_SEARCH_ERROR");
            }
            if(isExternalCustomer(oapagecontext, oawebbean)){
                if(!"CUSTOMER_NAME".equals(s1) && s1 != null && !"".equals(s1) && s != null && (s.indexOf('*') != -1 || s.indexOf('%') != -1))    
                   throw new OAException("XXFIN", "XXFIN_TRX_WILDCARD_NOT_ALLOWED");
                
                if(!"CUSTOMER_NAME".equals(s1) && !isValidKeyWord(s))
                  throw new OAException("AR", "ARI_CUST_EMPTY_SEARCH_ERROR");
            }            
        }
        super.processFormRequest(oapagecontext, oawebbean);

    }

    public static final String RCS_ID = "$Header: CustomerSearchLayoutCO.java 120.13.12020000.4 2015/01/13 02:36:17 ssiddams ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: CustomerSearchLayoutCO.java 120.13.12020000.4 2015/01/13 02:36:17 ssiddams ship $", "oracle.apps.ar.irec.common.webui");

}
