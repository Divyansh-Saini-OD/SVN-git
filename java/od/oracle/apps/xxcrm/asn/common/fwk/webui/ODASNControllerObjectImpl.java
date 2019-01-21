/*===========================================================================+
 |                       Office Depot - Project Simplify                     |
 |            			   Oracle NAC Consulting Organization         		       |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODASNControllerObjectImpl.java                                |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Parent level Controller for custom security access component   		     |
 |     					                                                             |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file contains methods that are inherited and used by        |
 |	  custom child level controllers          							                 |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    30/09/2007 Sami Begg     Created                                       |
 |    23/11/2007 Anirban Chaudhuri   Modified for site page security access  |
 |    22/04/2008 Jasmine Sujithra    ASNReqFrmSiteId to ASNReqFrmSiteAcsMd   |
 +===========================================================================*/
package od.oracle.apps.xxcrm.asn.common.fwk.webui;

import oracle.apps.asn.common.fwk.webui.ASNControllerObjectImpl;
import com.sun.java.util.collections.*;
import java.io.Serializable;
import java.util.Enumeration;
import java.util.StringTokenizer;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;
import oracle.apps.fnd.framework.webui.beans.nav.OABreadCrumbsBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.cabo.ui.BaseMutableUINode;
import oracle.cabo.ui.beans.nav.LinkBean;
import oracle.cabo.ui.collection.UINodeList;

public class ODASNControllerObjectImpl extends ASNControllerObjectImpl
{

    public String getAccessPrivilege(OAPageContext oapagecontext, String entity, String entityId)
    {
        String logger = "od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl.getAccessPrivilege";
        boolean lvl1 = oapagecontext.isLoggingEnabled(2);
        boolean lvl2 = oapagecontext.isLoggingEnabled(1);
        if(lvl1)
            oapagecontext.writeDiagnostics(logger, "Begin", 2);
        if(lvl2)
        {
            StringBuffer stringbuffer = new StringBuffer(30);
            stringbuffer.append(" entity = " + entity);
            stringbuffer.append(" entityId = " + entityId);
            oapagecontext.writeDiagnostics(logger, stringbuffer.toString(), 1);
        }
        OAApplicationModule oaapplicationmodule = oapagecontext.getRootApplicationModule();
        String accessPrivilege = "lOllOl11O";
        if(oaapplicationmodule != null)
        {
            String resourceId = getLoginResourceId(oaapplicationmodule, oapagecontext);
      			ArrayList adminGrpIds = getAdminGroupIds(oaapplicationmodule, oapagecontext);
            ArrayList mgrGrpIds = getManagerGroupIds(oaapplicationmodule, oapagecontext);
            String mgrFlag = isLoginResourceManager(oaapplicationmodule, oapagecontext) ? "Y" : "N";
            Serializable aserializable[] = { entity, entityId, resourceId, mgrGrpIds, adminGrpIds, mgrFlag };
            Class aclass[] = { java.lang.String.class, java.lang.String.class, java.lang.String.class, com.sun.java.util.collections.ArrayList.class, com.sun.java.util.collections.ArrayList.class, java.lang.String.class };
            accessPrivilege = (String)oaapplicationmodule.invokeMethod("getAccessPrivilege", aserializable, aclass);
        }
        if(lvl2)
        {
            StringBuffer stringbuffer1 = new StringBuffer(20);
            stringbuffer1.append(" accessType = ");
            stringbuffer1.append(accessPrivilege);
            oapagecontext.writeDiagnostics(logger, stringbuffer1.toString(), 1);
        }
        if(lvl1)
            oapagecontext.writeDiagnostics(logger, "End", 2);

        return accessPrivilege;
    }

    public String checkAccessPrivilege(OAPageContext oapagecontext, String entity, String entityId, boolean blockFlag)
    {
        return this.checkAccessPrivilege(oapagecontext, entity, entityId, blockFlag, true);
    }

    public String checkAccessPrivilege(OAPageContext oapagecontext, String entity, String entityId, boolean blockFlag, boolean currentEntityFlag)
    {
        String logger = "od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl.checkAccessPrivilege";
        boolean lvl1 = oapagecontext.isLoggingEnabled(2);
        boolean lvl2 = oapagecontext.isLoggingEnabled(1);

        //anirban22nov:Start
        OAPageLayoutBean oapagelayoutbean = oapagecontext.getPageLayoutBean();
        OABreadCrumbsBean oabreadcrumbsbean = (OABreadCrumbsBean)oapagelayoutbean.getBreadCrumbsLocator();
        if(oabreadcrumbsbean != null)
        {
          int j = oabreadcrumbsbean.getLinkCount();
          j--;
		  oapagecontext.writeDiagnostics(logger, "anirban22nov: value of j: "+j, 1);
          String s26 = oabreadcrumbsbean.getLinkDestination(j > 0 ? j - 1 : 0);
		  oapagecontext.writeDiagnostics(logger, "anirban22nov: value of s26: "+s26, 1);
          if(s26 != null)
          {
            oapagecontext.writeDiagnostics(logger, "anirban22nov: value of s26: "+s26, 1);
            oapagecontext.putParameter("previousLinkUrl",s26);
          }
         }
		//anirban22nov:End

        if(lvl1)
            oapagecontext.writeDiagnostics(logger, "Begin", 2);
        if(lvl2)
        {
            StringBuffer stringbuffer = new StringBuffer(40);
            stringbuffer.append(" entity = " + entity);
            stringbuffer.append(" entityId = " + entityId);
            stringbuffer.append(" blockOnNoAccess = " + blockFlag);
            stringbuffer.append(" currentEntity = " + currentEntityFlag);
            oapagecontext.writeDiagnostics(logger, stringbuffer.toString(), 1);
        }
        String asnParamId = null;
        String asnParamVal = null;
        if("CUST".equals(entity))
        {
            asnParamId = oapagecontext.getParameter("ASNReqFrmCustAcsMd");
            asnParamVal = "ASN_CMMN_CUSTOMER";
        } else
        if("LEAD".equals(entity))
        {
            asnParamId = oapagecontext.getParameter("ASNReqFrmLeadAcsMd");
            asnParamVal = "ASN_CMMN_LEAD";
        } else
        if("OPPTY".equals(entity))
        {
            asnParamId = oapagecontext.getParameter("ASNReqFrmOpptyAcsMd");
            asnParamVal = "ASN_CMMN_OPPTY";
        } else
        if("SITE".equals(entity))
        {
            /* Updated to use ASNReqFrmSiteAcsMd instead of ASNReqFrmSiteId */
            asnParamId = oapagecontext.getParameter("ASNReqFrmSiteAcsMd");
            asnParamVal = "ASN_CMMN_CUSTOMER";
        }
        if(lvl2)
        {
            StringBuffer stringbuffer1 = new StringBuffer(20);
            stringbuffer1.append(" accessType from request = ");
            stringbuffer1.append(asnParamId);
            oapagecontext.writeDiagnostics(logger, stringbuffer1.toString(), 1);
        }
        if(currentEntityFlag)
        {
            if("1OllOl11O".equals(asnParamId) || "101lOl11O".equals(asnParamId))
            {
                if(lvl1)
                    oapagecontext.writeDiagnostics(logger, "End", 2);
                return asnParamId;
            }
            if(blockFlag && "lOllOl11O".equals(asnParamId))
            {
                if(lvl2)
                    oapagecontext.writeDiagnostics(logger, "no access, throw error", 1);
                asnParamVal = oapagecontext.getMessage("ASN", asnParamVal, null);
                MessageToken amessagetoken[] = {
                    new MessageToken("OBJECTNAME", asnParamVal)
                };
                throw new OAException("ASN", "ASN_CMMN_NO_ACSS_ERR", amessagetoken,OAException.INFORMATION,null);
            }
        }
        asnParamId = null;
        asnParamId = this.getAccessPrivilege(oapagecontext, entity, entityId);
        if("CUST".equals(entity))
            oapagecontext.putParameter("ASNReqFrmCustAcsMd", asnParamId);
        else
        if("LEAD".equals(entity))
            oapagecontext.putParameter("ASNReqFrmLeadAcsMd", asnParamId);
        else
        if("OPPTY".equals(entity))
            oapagecontext.putParameter("ASNReqFrmOpptyAcsMd", asnParamId);
        else /* Updated to use ASNReqFrmSiteAcsMd instead of ASNReqFrmSiteId */
        if("SITE".equals(entity))
            oapagecontext.putParameter("ASNReqFrmSiteAcsMd", asnParamId);
        if(lvl2)
        {
            StringBuffer stringbuffer2 = new StringBuffer(20);
            stringbuffer2.append(" accessType from DB = ");
            stringbuffer2.append(asnParamId);
            oapagecontext.writeDiagnostics(logger, stringbuffer2.toString(), 1);
        }
        if(blockFlag && "lOllOl11O".equals(asnParamId))
        {
            String msgTok = oapagecontext.getMessage("ASN", asnParamVal, null);
            MessageToken amessagetoken1[] = {
                new MessageToken("OBJECTNAME", msgTok)
            };
            OAException oaexception = new OAException("ASN", "ASN_CMMN_NO_ACSS_ERR", amessagetoken1,OAException.INFORMATION,null);
            String returnUrl = oapagecontext.getParameter("ASNReqFrmReturnUrl");
            if(returnUrl != null && returnUrl.trim().length() > 0)
            {
                if(lvl2)
                {
                    StringBuffer stringbuffer4 = new StringBuffer(110);
                    stringbuffer4.append(" ASNReqFrmReturnUrl = ");
                    stringbuffer4.append(returnUrl);
                    oapagecontext.writeDiagnostics(logger, stringbuffer4.toString(), 1);
                }
                oapagecontext.removeParameter("retainAM");
                oapagecontext.removeParameter("addBreadCrumb");
                StringBuffer stringbuffer5 = new StringBuffer(100);
                stringbuffer5.append(returnUrl);
                if(returnUrl.indexOf("?") == -1)
                {
                    stringbuffer5.append("?ASNReqErrCode=ASN_CMMN_NO_ACSS_ERR&ASNReqErrToken=");
                    stringbuffer5.append(asnParamVal);
                    stringbuffer5.append("&ASNReqErrAppName=ASN");
                } else
                {
                    stringbuffer5.append("&ASNReqErrCode=ASN_CMMN_NO_ACSS_ERR&ASNReqErrToken=");
                    stringbuffer5.append(asnParamVal);
                    stringbuffer5.append("&ASNReqErrAppName=ASN");
                }
                try
                {
                    String redirectUrl = stringbuffer5.toString();
                    if(lvl2)
                    {
                        StringBuffer stringbuffer6 = new StringBuffer(120);
                        stringbuffer6.append(" Redirect URL = ");
                        stringbuffer6.append(redirectUrl);
                        oapagecontext.writeDiagnostics(logger, stringbuffer6.toString(), 1);
                    }
                    oapagecontext.sendRedirect(redirectUrl);
                }
                catch(Exception _ex)
                {
                    throw oaexception;
                }
            } else
            {
                throw oaexception;
            }
        }
        if(lvl2)
        {
            StringBuffer stringbuffer3 = new StringBuffer(20);
            stringbuffer3.append(" accessType = ");
            stringbuffer3.append(asnParamId);
            oapagecontext.writeDiagnostics(logger, stringbuffer3.toString(), 1);
        }
        if(lvl1)
            oapagecontext.writeDiagnostics(logger, "End", 2);

        return asnParamId;
    }

    public String processAccessPrivilege(OAPageContext oapagecontext, String entity, String entityId)
    {
        String logger = "od.oracle.apps.xxcrm.asn.common.fwk.webui.ODASNControllerObjectImpl.processAccessPrivilege";
        boolean lvl1 = oapagecontext.isLoggingEnabled(2);
        boolean lvl2 = oapagecontext.isLoggingEnabled(1);
        if(lvl1)
            oapagecontext.writeDiagnostics(logger, "Begin", 2);
        if(lvl2)
        {
            StringBuffer stringbuffer = new StringBuffer(20);
            stringbuffer.append(" entity = " + entity);
            stringbuffer.append(" entityId = " + entityId);
            oapagecontext.writeDiagnostics(logger, stringbuffer.toString(), 1);
        }
        try
        {
            if(lvl1)
                oapagecontext.writeDiagnostics(logger, "End", 2);
            return this.checkAccessPrivilege(oapagecontext, entity, entityId, true, true);
        }
        catch(OAException oaexception)
        {
            if(lvl2)
            {
                StringBuffer stringbuffer1 = new StringBuffer(40);
                stringbuffer1.append(" Error Message = ");
                stringbuffer1.append(oaexception.getMessage());
                stringbuffer1.append(" Error Trace = ");
//                stringbuffer1.append(oaexception.getAllMessageStackTraces());
                oapagecontext.writeDiagnostics(logger, stringbuffer1.toString(), 1);
            }
            if(lvl1)
                oapagecontext.writeDiagnostics(logger, "End", 2);

            //anirban22Nov:Start
             OADialogPage oadialogpage = new OADialogPage(OAException.INFORMATION, oaexception, new OAException("Please click on the OK button to return back to the previous page.") , "", null);
             oadialogpage.setOkButtonItemName("OK");
			 oadialogpage.setOkButtonLabel("OK");
             String previousLinkUrl = oapagecontext.getParameter("previousLinkUrl");
			 oadialogpage.setOkButtonUrl(previousLinkUrl);
			 oapagecontext.redirectToDialogPage(oadialogpage);
			//anirban22Nov:End

            return "lOllOl11O";
        }
    }

    private HashMap getSpecificParameters(OAPageContext oapagecontext, String s)
    {
        String s1 = "asn.common.fwk.webui.getSpecificParameters";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        boolean flag1 = oapagecontext.isLoggingEnabled(1);
        if(flag)
            oapagecontext.writeDiagnostics(s1, "Begin", 2);
        if(flag1)
        {
            StringBuffer stringbuffer = new StringBuffer(10);
            stringbuffer.append(" prefix = ");
            stringbuffer.append(s);
            oapagecontext.writeDiagnostics(s1, stringbuffer.toString(), 1);
        }
        HashMap hashmap = new HashMap(25);
        Enumeration enumeration = oapagecontext.getParameterNames();
        Object obj = null;
        Object obj1 = null;
        while(enumeration.hasMoreElements())
        {
            String s2 = (String)enumeration.nextElement();
            if(s2 != null && s2.startsWith(s))
            {
                String s3 = oapagecontext.getParameter(s2);
                if(s3 != null && s3.trim().length() > 0)
                    hashmap.put(s2, s3);
            }
        }
        if(flag1)
        {
            StringBuffer stringbuffer1 = new StringBuffer(30);
            stringbuffer1.append(" specific params = ");
            stringbuffer1.append(hashmap == null ? "" : hashmap.toString());
            oapagecontext.writeDiagnostics(s1, stringbuffer1.toString(), 1);
        }
        if(flag)
            oapagecontext.writeDiagnostics(s1, "End", 2);
        return hashmap;
    }

    private ArrayList getSpecificParameterNames(OAPageContext oapagecontext, String s)
    {
        String s1 = "asn.common.fwk.webui.getSpecificParameterNames";
        boolean flag = oapagecontext.isLoggingEnabled(2);
        boolean flag1 = oapagecontext.isLoggingEnabled(1);
        if(flag)
            oapagecontext.writeDiagnostics(s1, "Begin", 2);
        if(flag1)
        {
            StringBuffer stringbuffer = new StringBuffer(10);
            stringbuffer.append(" prefix = ");
            stringbuffer.append(s);
            oapagecontext.writeDiagnostics(s1, stringbuffer.toString(), 1);
        }
        ArrayList arraylist = new ArrayList(25);
        Enumeration enumeration = oapagecontext.getParameterNames();
        Object obj = null;
        while(enumeration.hasMoreElements())
        {
            String s2 = (String)enumeration.nextElement();
            if(s2 != null && s2.startsWith(s))
                arraylist.add(s2);
        }
        if(flag1)
        {
            StringBuffer stringbuffer1 = new StringBuffer(30);
            stringbuffer1.append(" specific params = ");
            stringbuffer1.append(arraylist == null ? "" : arraylist.toString());
            oapagecontext.writeDiagnostics(s1, stringbuffer1.toString(), 1);
        }
        if(flag)
            oapagecontext.writeDiagnostics(s1, "End", 2);
        return arraylist;
    }

    private HashMap getFrmParamsFromCtxtParams(OAPageContext oapagecontext)
    {
        return populateSpecificParameters(oapagecontext, "ASNReqCtxt", "ASNReqFrm", true, false);
    }

    private void setFrmParamsToCtxtParams(OAPageContext oapagecontext)
    {
        populateSpecificParameters(oapagecontext, "ASNReqFrm", "ASNReqCtxt", false, true);
    }

    private HashMap populateSpecificParameters(OAPageContext oapagecontext, String s, String s1, boolean flag, boolean flag1)
    {
        String s2 = "asn.common.fwk.webui.populateSpecificParameters";
        boolean flag2 = oapagecontext.isLoggingEnabled(2);
        boolean flag3 = oapagecontext.isLoggingEnabled(1);
        if(flag2)
            oapagecontext.writeDiagnostics(s2, "Begin", 2);
        if(flag3)
        {
            StringBuffer stringbuffer = new StringBuffer(30);
            stringbuffer.append(" fromParamType = ");
            stringbuffer.append(s);
            stringbuffer.append(" toParamType = ");
            stringbuffer.append(s1);
            stringbuffer.append(" returnParams = ");
            stringbuffer.append(flag);
            stringbuffer.append(" setPageContext = ");
            stringbuffer.append(flag1);
            oapagecontext.writeDiagnostics(s2, stringbuffer.toString(), 1);
        }
        HashMap hashmap = getSpecificParameters(oapagecontext, s);
        HashMap hashmap1 = null;
        if(hashmap != null && !hashmap.isEmpty())
        {
            if(flag3)
            {
                StringBuffer stringbuffer1 = new StringBuffer(40);
                stringbuffer1.append(" fromParams = ");
                stringbuffer1.append(hashmap.toString());
                oapagecontext.writeDiagnostics(s2, stringbuffer1.toString(), 1);
            }
            if(flag)
                hashmap1 = new HashMap((int)Math.ceil((double)hashmap.size() * 1.25D));
            Set set = hashmap.keySet();
            Object obj = null;
            Object obj1 = null;
            Object obj2 = null;
            Object obj3 = null;
            if(set != null)
            {
                Iterator iterator = set.iterator();
                int i = s.length();
                boolean flag4 = false;
                while(iterator.hasNext())
                {
                    String s3 = (String)iterator.next();
                    String s4 = (String)hashmap.get(s3);
                    if(s3 != null)
                    {
                        int j = s3.length();
                        if(j > i)
                        {
                            String s5 = s3.substring(i, j);
                            s5 = s1 + s5;
                            if(s4 != null && s4.trim().length() > 0)
                            {
                                if(flag)
                                    hashmap1.put(s5, s4);
                                if(flag1)
                                    oapagecontext.putParameter(s5, s4);
                            }
                        }
                    }
                }
            }
        }
        if(flag3)
        {
            StringBuffer stringbuffer2 = new StringBuffer(40);
            stringbuffer2.append(" toParams = ");
            stringbuffer2.append(hashmap1 == null ? "" : hashmap1.toString());
            oapagecontext.writeDiagnostics(s2, stringbuffer2.toString(), 1);
        }
        if(flag2)
            oapagecontext.writeDiagnostics(s2, "End", 2);
        return hashmap1;
    }

    private HashMap getNameValueMapFromURL(String s)
    {
        if(s == null)
            return null;
        int i = s.indexOf('?');
        String s1 = s;
        if(i != -1)
            s1 = s.substring(i + 1);
        StringTokenizer stringtokenizer = new StringTokenizer(s1, "&");
        HashMap hashmap = new HashMap(25);
        byte byte0 = -1;
        Object obj = null;
        Object obj1 = null;
        Object obj2 = null;
        while(stringtokenizer.hasMoreElements())
        {
            String s4 = (String)stringtokenizer.nextElement();
            int j = s4.indexOf('=');
            if(j != -1)
            {
                String s2 = s4.substring(0, j);
                String s3 = s4.substring(j + 1);
                hashmap.put(s2, s3);
            }
        }
        if(hashmap.isEmpty())
            return null;
        else
            return hashmap;
    }

  public ODASNControllerObjectImpl()
  {
  }

}