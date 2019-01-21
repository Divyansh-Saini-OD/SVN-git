/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
/*===========================================================================+
 |      		       Office Depot - Project Simplify                       |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODHzPuiDQMSrchResultsCO.java                                  |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |             Controller for the sales customer search results region.      |                                |                                                                           |
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is called from ODHzPuiDQMSrchResults.xml               |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    21/09/2007 Anirban Chaudhuri   Created                                 |
 |    07/03/2008 Anirban Chaudhuri   Fixed QC item# 4217                     |
 +===========================================================================*/

package od.oracle.apps.xxcrm.ar.custsrch.hz.components.search.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import com.sun.java.util.collections.HashMap;
import java.lang.*;
import java.io.Serializable;
import java.util.Enumeration;
import java.util.Vector;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.*;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageRadioButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.nav.OALinkBean;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.cabo.ui.beans.layout.HeaderBean;
import oracle.cabo.ui.beans.layout.SpacerBean;
import oracle.jbo.common.Diagnostic;
import oracle.apps.fnd.framework.OAFwkConstants;
import java.math.BigDecimal;

/**
 * Controller for ...
 */
public class ODHzPuiDQMSrchResultsCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  private static final String ATTR_PARAM_PREFIX = "MATCH_RULE_ATTR";
  private static final String SRCH_VO_NAME = "ODHzPuiDQMSrchResultsVO1";
  private static final int ATTR_PARAM_PREFIX_LEN = "MATCH_RULE_ATTR".length();
  
  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
  {
    super.processRequest(oapagecontext, oawebbean);
    boolean isStatLogEnabled = oapagecontext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    Diagnostic.println("Inside processRequest");
    if(isStatLogEnabled)
    {
      oapagecontext.writeDiagnostics(this,  "ODCO: Begin processRequest", OAFwkConstants.STATEMENT);
    }
        String s = oapagecontext.getParameter("HzPuiSearchComponentMode");
        OADBTransactionImpl oadbtransactionimpl = (OADBTransactionImpl)oapagecontext.getRootApplicationModule().getOADBTransaction();
        oadbtransactionimpl.putTransientValue("HzPuiSearchComponentMode", oapagecontext.getParameter("sHzPuiSearchComponentMode"));
        oadbtransactionimpl.putTransientValue("HzPuiSearchAttributeVisited", "N");
        Object obj = null;
        String s1 = oapagecontext.getParameter("HzPuiSearchHeaderText");
        OADefaultSingleColumnBean oadefaultsinglecolumnbean = (OADefaultSingleColumnBean)oawebbean.findChildRecursive("header");
        if(s1 != null && !s1.equals(""))
        {
            HeaderBean.setText(oadefaultsinglecolumnbean, s1);
        }
        String s2 = oapagecontext.getParameter("HzPuiSearchPartyType");
        OAMessageStyledTextBean oamessagestyledtextbean = (OAMessageStyledTextBean)oawebbean.findIndexedChildRecursive("CertificationLevel");
        if(oamessagestyledtextbean != null && "PERSON".equals(s2))
        {
            oamessagestyledtextbean.setRendered(false);
        }
        String s3 = oapagecontext.getProfile("HZ_DISPLAY_CERT_LEVEL");
        Diagnostic.println("HZ_DISPLAY_CERT_LEVEL = " + s3);
        if(!"Y".equals(s3))
        {
            Diagnostic.println("Inside !'Y'.equals( sCertStatus )");
            if(oamessagestyledtextbean != null)
            {
                oamessagestyledtextbean.setRendered(false);
            }
        }
        if("LOV".equals(s) || "DEDUPE".equals(s))
        {
            OASeparatorBean oaseparatorbean = (OASeparatorBean)oawebbean.findChildRecursive("separator");
            oaseparatorbean.setRendered(false);
            OASpacerBean oaspacerbean = (OASpacerBean)oawebbean.findChildRecursive("spacer");
            oaspacerbean.setWidth(0);
            OAMessageRadioButtonBean oamessageradiobuttonbean1 = (OAMessageRadioButtonBean)oawebbean.findChildRecursive("HzPuiDqmOrgSS");
            if(oamessageradiobuttonbean1 != null)
            {
                oamessageradiobuttonbean1.setRendered(true);
            }
            OALinkBean oalinkbean = (OALinkBean)oawebbean.findChildRecursive("HzPuiPartyName1_link");
            if(oalinkbean != null)
            {
                oalinkbean.setWarnAboutChanges(false);
            }
            OASubmitButtonBean oasubmitbuttonbean = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("HzPuiMarkDup");
            if(oasubmitbuttonbean != null)
            {
                oasubmitbuttonbean.setRendered(false);
            }
            oasubmitbuttonbean = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("HzPuiPurchase");
            if(oasubmitbuttonbean != null)
            {
                oasubmitbuttonbean.setRendered(false);
            }
            OALinkBean oalinkbean1 = (OALinkBean)oawebbean.findIndexedChildRecursive("Update");
            if(oalinkbean1 != null)
            {
                oalinkbean1.setRendered(false);
            }
            if("DEDUPE".equals(s))
            {
                OASubmitButtonBean oasubmitbuttonbean1 = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("HzPuiCreate");
                if(oasubmitbuttonbean1 != null)
                {
                    oasubmitbuttonbean1.setRendered(false);
                }
                oasubmitbuttonbean1 = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("HzPuiSelectOrgButton");
                if(oasubmitbuttonbean1 != null)
                {
                    oasubmitbuttonbean1.setRendered(true);
                }
            }
        } else
        {
            oadefaultsinglecolumnbean.setHeaderDisabled(true);
            OAMessageRadioButtonBean oamessageradiobuttonbean = (OAMessageRadioButtonBean)oawebbean.findChildRecursive("HzPuiDqmOrgSS");
            if(oamessageradiobuttonbean != null)
            {
                oamessageradiobuttonbean.setRendered(false);
            }
            String s5 = oapagecontext.getProfile("HZ_MARK_DUPLICATES_ENABLED_FLAG");
            Diagnostic.println("HZ_MARK_DUPLICATES_ENABLED_FLAG = " + s5);
            if(!"Y".equals(s5))
            {
                Diagnostic.println("Inside  !'Y'.equals( sMarkDuplicate )");
                OASubmitButtonBean oasubmitbuttonbean2 = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("HzPuiMarkDup");
                if(oasubmitbuttonbean2 != null)
                {
                    oasubmitbuttonbean2.setRendered(false);
                }
            }
            String s6 = oapagecontext.getProfile("HZ_DNB_ACCESS_ENABLED_FLAG");
            Diagnostic.println("HZ_DNB_ACCESS_ENABLED_FLAG = " + s6);
            if(!"Y".equals(s6))
            {
                Diagnostic.println("Inside !'Y'.equals( sDNBAccess )");
                OASubmitButtonBean oasubmitbuttonbean3 = (OASubmitButtonBean)oawebbean.findIndexedChildRecursive("HzPuiPurchase");
                if(oasubmitbuttonbean3 != null)
                {
                    oasubmitbuttonbean3.setRendered(false);
                }
            }
        }
        Diagnostic.println("HzPuiSearchAutoQuery = " + oapagecontext.getParameter("HzPuiSearchAutoQuery"));
        String s4 = oapagecontext.getParameter("HzPuiNewPartyId");
       /* if(s4 != null)
        {
            returnResults(oapagecontext, oawebbean, null, s4, null);
            return;
        }*/

		oapagecontext.putParameter("HzPuiSearchAutoQuery","N");
		oapagecontext.writeDiagnostics(this,  "ODCO: ANIRBAN HzPuiSearchAutoQuery value is: "+oapagecontext.getParameter("HzPuiSearchAutoQuery"), OAFwkConstants.STATEMENT);
        if("Y".equals(oapagecontext.getParameter("HzPuiSearchAutoQuery")))
        {
            HashMap hashmap = new HashMap(10);
            checkForPartyParams(oapagecontext, oawebbean, hashmap);
            if(hashmap.size() != 0)
            {
				oapagecontext.writeDiagnostics(this,  "ODCO: ANIRBAN inside hashmap.size() != 0", OAFwkConstants.STATEMENT);
                goButtonPressed(oapagecontext, oawebbean);
            }
        }


        try
	   {
        OAQueryBean oaQueryBean = (OAQueryBean)oawebbean.findChildRecursive("QueryRN");
		Vector vectorBan = new Vector(3);
        StringBuffer stringbufferBan = new StringBuffer();
		Serializable aserializableBan[] = {
                null, stringbufferBan, vectorBan
            };
            Class aclassBan[] = {
                Class.forName("java.lang.StringBuffer"), Class.forName("java.lang.StringBuffer"), Class.forName("java.util.Vector")
            };
            OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
            if(isStatLogEnabled)
            {
               oapagecontext.writeDiagnostics(this,  "ODCO: ANIRBAN calling defaultViewExecution", OAFwkConstants.STATEMENT);
            }
            oaapplicationmodule.invokeMethod("defaultViewExecution",aserializableBan,aclassBan);
        }
		catch(ClassNotFoundException _ex)
        {
           oapagecontext.writeDiagnostics(this,  "ODCO: ANIRBAN calling defaultViewExecution", OAFwkConstants.STATEMENT);
           oapagecontext.putDialogMessage(new OAException("AR", "HZ_DL_CREATE_DUP_UNEXP_ERR", null, (byte)0, null));
        }


        if(isStatLogEnabled)
        {
          oapagecontext.writeDiagnostics(this,  "ODCO: End processRequest", OAFwkConstants.STATEMENT);
        }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
  {
    super.processFormRequest(oapagecontext, oawebbean);
    boolean isStatLogEnabled = oapagecontext.isLoggingEnabled(OAFwkConstants.STATEMENT);
    if(isStatLogEnabled)
    {
      oapagecontext.writeDiagnostics(this,  "ODCO: In processFormRequest", OAFwkConstants.STATEMENT);
    }
        
    if(oapagecontext.getParameter("HzPuiGoSearch") != null)
    {
      goButtonPressed(oapagecontext, oawebbean);
    } 
  }

 public void checkForPartyParams(OAPageContext oapagecontext, OAWebBean oawebbean, HashMap hashmap)
    {
       boolean isStatLogEnabled = oapagecontext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        if(isStatLogEnabled)
        {
          oapagecontext.writeDiagnostics(this,  "ODCO: In checkForPartyParams", OAFwkConstants.STATEMENT);
        }
        
        Enumeration enumeration1 = oapagecontext.getDataObjectNames();
        while(enumeration1.hasMoreElements()) 
        {
            String strNew = (String)enumeration1.nextElement();
            if(isStatLogEnabled)
            {
              oapagecontext.writeDiagnostics(this,  "ODCO: In checkForPartyParams strNew - "+strNew, OAFwkConstants.STATEMENT);
            }
        }
        
        Enumeration enumeration = oapagecontext.getParameterNames();
        while(enumeration.hasMoreElements()) 
        {
            String s3 = (String)enumeration.nextElement();
         
            if(!s3.startsWith("MATCH_RULE_ATTR"))
            {
                continue;
            }
            String s = oapagecontext.getParameter(s3);
          
            if(s == null || s.trim().length() == 0)
            {
                continue;
            }
            Diagnostic.println("sSrchVal2: [" + s + "]");
            if(isStatLogEnabled)
            {
              oapagecontext.writeDiagnostics(this,  "ODCO: In checkForPartyParams s - "+s, OAFwkConstants.STATEMENT);
            }
            String s2 = s3.substring(ATTR_PARAM_PREFIX_LEN);
            String str1 = s3.valueOf(ATTR_PARAM_PREFIX);
            boolean bmatch = s3.matches("Name");
            
            if(isStatLogEnabled)
            {
              oapagecontext.writeDiagnostics(this,  "ODCO: In checkForPartyParams s2 - "+s2, OAFwkConstants.STATEMENT);
              oapagecontext.writeDiagnostics(this,  "ODCO: In checkForPartyParams str1 - "+str1, OAFwkConstants.STATEMENT);
              oapagecontext.writeDiagnostics(this,  "ODCO: In checkForPartyParams bmatch - "+bmatch, OAFwkConstants.STATEMENT);
            }
            Integer integer = null;
            try
            {
                integer = new Integer(s2);
            }
            catch(NumberFormatException _ex)
            {
                continue;
            }
            hashmap.put(integer, s);
            Diagnostic.println("Adding to Transaction Cache: " + s3 + " " + s);
            oapagecontext.putTransactionValue(s3, s);
        }
        if(hashmap.size() == 0 && oapagecontext.getParameter("HzPuiGoSearch") == null)
        {
            Object obj = null;
            for(int i = 1; i < 50; i++)
            {
                Diagnostic.println("Checking transaction for Saved Search Parameters MATCH_RULE_ATTR" + i);
                String s1 = (String)oapagecontext.getTransactionValue("MATCH_RULE_ATTR" + i);
                if(s1 != null && s1.trim().length() != 0)
                {
                    Integer integer1 = new Integer(i);
                    hashmap.put(integer1, s1);
                }
            }

        }
    }

    public String callDQMApi(OAPageContext oapagecontext, OAWebBean oawebbean, HashMap hashmap, StringBuffer stringbuffer, StringBuffer stringbuffer1, Vector vector)
    {
        String s = null;
        boolean isStatLogEnabled = oapagecontext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        if(isStatLogEnabled)
        {
          oapagecontext.writeDiagnostics(this,  "ODCO: In callDQMApi", OAFwkConstants.STATEMENT);
        }
        try
        {
            String s1 = oapagecontext.getParameter("HzPuiSearchType");
            String s2 = oapagecontext.getParameter("HzPuiSearchMode");
            String s3 = oapagecontext.getParameter("HzPuiSimpleMatchRuleId");
            String s4 = oapagecontext.getParameter("HzPuiAdvMatchRuleId");
            String s5 = s3;
            if("SIMPLEADV".equals(s1) && "ADV".equals(s2))
            {
                s5 = s4;
            }
            Diagnostic.println("Srch results: sMatchRuleName = " + s5);
            if(isStatLogEnabled)
            {
               oapagecontext.writeDiagnostics(this,  "ODCO: In callDQMApi sMatchRuleName - "+s5, OAFwkConstants.STATEMENT);
            }
            if(s5 != null)
            {
                Diagnostic.println("MATCH RULE LENGTH - " + s5.length());
            }
            if(s5 == null)
            {
                s5 = oapagecontext.getProfile("HZ_RM_MATCH_RULE_ID");
            }
			oapagecontext.writeDiagnostics(this,  "ODCO: In callDQMApi ANIRBAN Match Rule Id is  - "+s5, OAFwkConstants.STATEMENT);
            String s6 = oapagecontext.getParameter("HzPuiMatchOptionDisplay");
            Diagnostic.println("matchOption = " + s6);
            if(isStatLogEnabled)
            {
             oapagecontext.writeDiagnostics(this,  "ODCO: In callDQMApi matchOption - "+s6, OAFwkConstants.STATEMENT);
            }
            String s7 = oapagecontext.getParameter("HzPuiSearchPartyType");
            Serializable aserializable[] = {
                hashmap, s5, s6, s7, "N", stringbuffer.toString(), stringbuffer1
            };
            Class aclass[] = {
                Class.forName("com.sun.java.util.collections.HashMap"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.StringBuffer")
            };
            OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
            s = (String)oaapplicationmodule.invokeMethod("callDQMSearch", aserializable, aclass);
            if(isStatLogEnabled)
            {
             oapagecontext.writeDiagnostics(this,  "ODCO: After callDQMSearch s - "+s, OAFwkConstants.STATEMENT);
            }
        }
        catch(ClassNotFoundException _ex)
        {
            oapagecontext.putDialogMessage(new OAException("AR", "HZ_DL_CREATE_DUP_UNEXP_ERR", null, (byte)0, null));
        }
        return s;
    }

	public int callDQMApiCount(OAPageContext oapagecontext, OAWebBean oawebbean, HashMap hashmap, StringBuffer stringbuffer, StringBuffer stringbuffer1, Vector vector)
    {
        String s = null;
		Integer countInt = null;
        boolean isStatLogEnabled = oapagecontext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        if(isStatLogEnabled)
        {
          oapagecontext.writeDiagnostics(this,  "ODCO: In callDQMApi", OAFwkConstants.STATEMENT);
        }
        try
        {
            String s1 = oapagecontext.getParameter("HzPuiSearchType");
            String s2 = oapagecontext.getParameter("HzPuiSearchMode");
            String s3 = oapagecontext.getParameter("HzPuiSimpleMatchRuleId");
            String s4 = oapagecontext.getParameter("HzPuiAdvMatchRuleId");
            String s5 = s3;
            if("SIMPLEADV".equals(s1) && "ADV".equals(s2))
            {
                s5 = s4;
            }
            Diagnostic.println("Srch results: sMatchRuleName = " + s5);
            if(isStatLogEnabled)
            {
               oapagecontext.writeDiagnostics(this,  "ODCO: In callDQMApi sMatchRuleName - "+s5, OAFwkConstants.STATEMENT);
            }
            if(s5 != null)
            {
                Diagnostic.println("MATCH RULE LENGTH - " + s5.length());
            }
            if(s5 == null)
            {
                s5 = oapagecontext.getProfile("HZ_RM_MATCH_RULE_ID");
            }
			oapagecontext.writeDiagnostics(this,  "ODCO: In callDQMApi ANIRBAN Match Rule Id is  - "+s5, OAFwkConstants.STATEMENT);
            String s6 = oapagecontext.getParameter("HzPuiMatchOptionDisplay");
            Diagnostic.println("matchOption = " + s6);
            if(isStatLogEnabled)
            {
             oapagecontext.writeDiagnostics(this,  "ODCO: In callDQMApi matchOption - "+s6, OAFwkConstants.STATEMENT);
            }
            String s7 = oapagecontext.getParameter("HzPuiSearchPartyType");
            Serializable aserializable[] = {
                hashmap, s5, s6, s7, "N", stringbuffer.toString(), stringbuffer1
            };
            Class aclass[] = {
                Class.forName("com.sun.java.util.collections.HashMap"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.StringBuffer")
            };
            OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
            countInt = (Integer)oaapplicationmodule.invokeMethod("callDQMSearchCount", aserializable, aclass);
            if(isStatLogEnabled)
            {
             oapagecontext.writeDiagnostics(this,  "ODCO: After callDQMSearch s - "+s, OAFwkConstants.STATEMENT);
            }
        }
        catch(ClassNotFoundException _ex)
        {
            oapagecontext.putDialogMessage(new OAException("AR", "HZ_DL_CREATE_DUP_UNEXP_ERR", null, (byte)0, null));
        }
        return (countInt.intValue());
    }

    public String callPartySiteDQMApi(OAPageContext oapagecontext, OAWebBean oawebbean, HashMap hashmap, StringBuffer stringbuffer, StringBuffer stringbuffer1, Vector vector)
    {
        String s = null;
        boolean isStatLogEnabled = oapagecontext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        if(isStatLogEnabled)
        {
          oapagecontext.writeDiagnostics(this,  "ODCO: In callPartySiteDQMApi", OAFwkConstants.STATEMENT);
        }
        try
        {
            String s1 = oapagecontext.getParameter("HzPuiSearchType");
            String s2 = oapagecontext.getParameter("HzPuiSearchMode");
            String s3 = oapagecontext.getParameter("HzPuiSimpleMatchRuleId");
            String s4 = oapagecontext.getParameter("HzPuiAdvMatchRuleId");
            String s5 = s3;
            if("SIMPLEADV".equals(s1) && "ADV".equals(s2))
            {
                s5 = s4;
            }
            Diagnostic.println("Srch results: sMatchRuleName = " + s5);
            if(isStatLogEnabled)
            {
              oapagecontext.writeDiagnostics(this,  "ODCO: In callPartySiteDQMApi sMatchRuleName - "+s5, OAFwkConstants.STATEMENT);
            }
            if(s5 != null)
            {
                Diagnostic.println("MATCH RULE LENGTH - " + s5.length());
            }
            if(s5 == null)
            {
                s5 = oapagecontext.getProfile("HZ_RM_MATCH_RULE_ID");
            }
            String s6 = oapagecontext.getParameter("HzPuiMatchOptionDisplay");
            Diagnostic.println("matchOption = " + s6);
            String s7 = oapagecontext.getParameter("HzPuiSearchPartyType");
            Serializable aserializable[] = {
                hashmap, s5, s6, s7, "N", stringbuffer.toString(), stringbuffer1
            };
            Class aclass[] = {
                Class.forName("com.sun.java.util.collections.HashMap"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.StringBuffer")
            };
            OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
            s = (String)oaapplicationmodule.invokeMethod("callPartySiteDQMSearch", aserializable, aclass);
            if(isStatLogEnabled)
            {
              oapagecontext.writeDiagnostics(this,  "ODCO: In callPartySiteDQMApi s - "+s, OAFwkConstants.STATEMENT);
            }
        }
        catch(ClassNotFoundException _ex)
        {
            oapagecontext.putDialogMessage(new OAException("AR", "HZ_DL_CREATE_DUP_UNEXP_ERR", null, (byte)0, null));
        }
        return s;
    }

    public String callDynamicDQMApi(OAPageContext oapagecontext, OAWebBean oawebbean, HashMap hashmap, StringBuffer stringbuffer, StringBuffer stringbuffer1, Vector vector)
    {
        String s = null;
        boolean isStatLogEnabled = oapagecontext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        if(isStatLogEnabled)
        {
          oapagecontext.writeDiagnostics(this,  "ODCO: In callDQMApi", OAFwkConstants.STATEMENT);
        }
        try
        {
            String s1 = oapagecontext.getParameter("HzPuiSearchType");
            String s2 = oapagecontext.getParameter("HzPuiSearchMode");
            String s3 = oapagecontext.getParameter("HzPuiSimpleMatchRuleId");
            String s4 = oapagecontext.getParameter("HzPuiAdvMatchRuleId");
            String s5 = s3;
            if("SIMPLEADV".equals(s1) && "ADV".equals(s2))
            {
                s5 = s4;
            }
            Diagnostic.println("Srch results: sMatchRuleName = " + s5);
            if(isStatLogEnabled)
            {
               oapagecontext.writeDiagnostics(this,  "ODCO: In callDQMApi sMatchRuleName - "+s5, OAFwkConstants.STATEMENT);
            }
            if(s5 != null)
            {
                Diagnostic.println("MATCH RULE LENGTH - " + s5.length());
            }
            if(s5 == null)
            {
                s5 = oapagecontext.getProfile("HZ_RM_MATCH_RULE_ID");
            }
            String s6 = oapagecontext.getParameter("HzPuiMatchOptionDisplay");
            Diagnostic.println("matchOption = " + s6);
            if(isStatLogEnabled)
            {
             oapagecontext.writeDiagnostics(this,  "ODCO: In callDQMApi matchOption - "+s6, OAFwkConstants.STATEMENT);
            }
            String s7 = oapagecontext.getParameter("HzPuiSearchPartyType");
            Serializable aserializable[] = {
                hashmap, s5, s6, s7, "N", stringbuffer.toString(), stringbuffer1
            };
            Class aclass[] = {
                Class.forName("com.sun.java.util.collections.HashMap"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.String"), Class.forName("java.lang.StringBuffer")
            };
            OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
            s = (String)oaapplicationmodule.invokeMethod("callDQMAPIdynamic", aserializable, aclass);
            if(isStatLogEnabled)
            {
             oapagecontext.writeDiagnostics(this,  "ODCO: After callDQMSearch s - "+s, OAFwkConstants.STATEMENT);
            }
        }
        catch(ClassNotFoundException _ex)
        {
            oapagecontext.putDialogMessage(new OAException("AR", "HZ_DL_CREATE_DUP_UNEXP_ERR", null, (byte)0, null));
        }
        return s;
    }
 
    public void goButtonPressed(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        HashMap hashmap = new HashMap(50);
		String s2 = oapagecontext.getParameter("HzPuiSearchMode");
        checkForPartyParams(oapagecontext, oawebbean, hashmap);
        boolean isStatLogEnabled = oapagecontext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        if(isStatLogEnabled)
        {
          oapagecontext.writeDiagnostics(this,  "ODCO: In goButtonPressed: value of s2 is: "+s2, OAFwkConstants.STATEMENT);
        }
        if(hashmap.size() == 0 && oapagecontext.getParameter("HzPuiGoSearch") != null)
        {
            oapagecontext.putDialogMessage(new OAException("AR", "HZ_DL_CREATE_DUP_SRCH_NO_INPUT", null, (byte)2, null));
            return;
        }
        String s = oapagecontext.getParameter("HzPuiSearchPartyType");
        if("ORGANIZATION".equals(s))
        {
            hashmap.put(new Integer(14), "ORGANIZATION");
        } else
        if("PERSON".equals(s))
        {
            hashmap.put(new Integer(14), "PERSON");
        }
		
		String sDynamicOuter = null;
		String s1Outer = null;

        String sPartyApiSimple = null;

		String sPartyApiAdv = null;
		String sDynamic = null;

		int count = 0;

        if("ADV".equals(s2))
        {
         sPartyApiAdv= callDQMApi(oapagecontext, oawebbean, hashmap, getRestrictSql(oapagecontext), null, null);
		 oapagecontext.writeDiagnostics(this,  "ODCO: In ANIRBAN goButtonPressed 11/9/07 callDQMApi sPartyApiAdv - "+sPartyApiAdv, OAFwkConstants.STATEMENT);
		 //Anirban fixed ASN issue#216: starts
		 //count = callDQMApiCount(oapagecontext, oawebbean, hashmap, getRestrictSql(oapagecontext), null, null);
		 count = ((Integer)oapagecontext.getTransactionValue("callDQMApiCount")).intValue();
		 oapagecontext.writeDiagnostics(this,  "ODCO: In ANIRBAN goButtonPressed 3 jan 08 callDQMApiCount count - "+count, OAFwkConstants.STATEMENT);
		 oapagecontext.removeTransactionValue("callDQMApiCount");
		 //Anirban fixed ASN issue#216: ends
         
		 //Anirban fix for ASN QC Issue on 6 Mar 08: starts
         if(count > 0)
		 {
		  sDynamic = callDynamicDQMApi(oapagecontext, oawebbean, hashmap, getRestrictSql(oapagecontext), null, null);
		 }
         //Anirban fix for ASN QC Issue on 6 Mar 08: ends

		 oapagecontext.writeDiagnostics(this,  "ODCO: In ANIRBAN goButtonPressed 11/9/07 callDynamicDQMApi sDynamic - "+sDynamic, OAFwkConstants.STATEMENT);		 
        }
		else
		{
         sPartyApiSimple= callDQMApi(oapagecontext, oawebbean, hashmap, getRestrictSql(oapagecontext), null, null);
		 oapagecontext.writeDiagnostics(this,  "ODCO: In ANIRBAN goButtonPressed 11/9/07 callDQMApi sPartyApiSimple - "+sPartyApiSimple, OAFwkConstants.STATEMENT);
		 //Anirban fixed ASN issue#216: starts
		 oapagecontext.removeTransactionValue("callDQMApiCount");
		 oapagecontext.writeDiagnostics(this,  "ODCO: In ANIRBAN SIMPLE SRCH goButtonPressed 3 jan 08 - "+(Integer)oapagecontext.getTransactionValue("callDQMApiCount"), OAFwkConstants.STATEMENT);
		 //Anirban fixed ASN issue#216: ends
		}

		/*if (sDynamic==null)
		{
		 sPartyApiSimple= callDQMApi(oapagecontext, oawebbean, hashmap, getRestrictSql(oapagecontext), null, null);
		 oapagecontext.writeDiagnostics(this,  "ODCO: In ANIRBAN goButtonPressed 11/9/07 callDQMApi sPartyApiSimple - "+sPartyApiSimple, OAFwkConstants.STATEMENT);
		}*/
		          
        Diagnostic.println("OD: Inside  ODHzPuiDQMSrchResultsCO. Before calling returnResults");
        
        if(isStatLogEnabled)
        {
          oapagecontext.writeDiagnostics(this,  "ODCO: In ANIRBAN goButtonPressed returnResults callDQMApi sPartyApiSimple - "+sPartyApiSimple, OAFwkConstants.STATEMENT);
          oapagecontext.writeDiagnostics(this,  "ODCO: In ANIRBAN goButtonPressed returnResults callDynamicDQMApi sDynamic - "+sDynamic, OAFwkConstants.STATEMENT);
        }

		if ((sPartyApiSimple == null)||("".equals(sPartyApiSimple)))
		{
			sPartyApiSimple = "1";
		}
		if ((sDynamic == null)||("".equals(sDynamic)))
		{
			sDynamic = "1";
		}
		if ((sPartyApiAdv == null)||("".equals(sPartyApiAdv)))
		{
			sPartyApiAdv = "1";
		}

        //Anirban fix for ASN QC Issue on 6 Mar 08: starts

		/*if ((sDynamicOuter == null)||("".equals(sDynamicOuter)))
		{
			sDynamicOuter = "1";
		}
		if ((s1Outer == null)||("".equals(s1Outer)))
		{
			s1Outer = "1";
		}

        if(count==0)
		{
         sDynamicOuter = sDynamic;
		 s1Outer = sPartyApiAdv;
		 sDynamic = "1";
         sPartyApiAdv =  "1";
		}*/

		if(("ADV".equals(s2)) && (count==0))
		{
         sDynamic = "1";
		 sPartyApiSimple = sPartyApiAdv;
         sPartyApiAdv =  "1";
		}

        //Anirban fix for ASN QC Issue on 6 Mar 08: ends

		String extraRestrictiveSQL = oapagecontext.getParameter("HzPuiDQMOrgSearchExtraWhereClause");

		oapagecontext.writeDiagnostics(this,  "ODCO: In ANIRBAN goButtonPressed 25/10/07 extraRestrictiveSQL - "+extraRestrictiveSQL, OAFwkConstants.STATEMENT);

        returnResults(oapagecontext, oawebbean, sPartyApiSimple, sDynamic, sPartyApiAdv, sDynamicOuter, s1Outer, extraRestrictiveSQL, null);         
    }

    public StringBuffer getRestrictSql(OAPageContext oapagecontext)
    {
        Diagnostic.println("getRestrictSql (+)");
        StringBuffer stringbuffer = new StringBuffer();
        String s = oapagecontext.getParameter("HzPuiSearchPartyType");
        String s1 = oapagecontext.getParameter("HzPuiRelationshipFilterDisplay");
        if(s1 != null && !"".equals(s1))
        {
            if(stringbuffer.length() > 0)
            {
                stringbuffer.append(" and ");
            }
            stringbuffer.append("party_id in (select distinct r.subject_id from hz_relationships r, hz_relationsh" +
            "ip_types rt where r.subject_type in ('"
            );
            if(s == null)
            {
                s = "ORGANIZATION','PERSON";
            }
            stringbuffer.append(s);
            stringbuffer.append("') and rt.role = '");
            stringbuffer.append(s1);
            stringbuffer.append("' and r.relationship_type = rt.relationship_type and r.relationship_code = rt.fo" +
            "rward_rel_code and r.subject_type = rt.subject_type and r.object_type = rt.objec" +
            "t_type)"
            );
        }
        String s2 = oapagecontext.getParameter("HzPuiClassificationFilterDisplay");
        String s3 = oapagecontext.getParameter("HzPuiClassCategoryFilter");
        String s4 = oapagecontext.getParameter("HzPuiClassCodeFilter");
        String s5 = oapagecontext.getParameter("HzPuiClassMeaningFilter");
        Diagnostic.println("sClassFilter = " + s2);
        Diagnostic.println("sClassCategory = " + s3);
        Diagnostic.println("sClassMeaning = " + s5);
        Diagnostic.println("sClassCode = " + s4);
        if(s3 != null && !"".equals(s3))
        {
            if(stringbuffer.length() > 0)
            {
                stringbuffer.append(" and ");
            }
            stringbuffer.append("party_id in (select owner_table_id from hz_code_assignments where owner_table_na" +
            "me = 'HZ_PARTIES' and class_category = '"
            );
            stringbuffer.append(s3);
            stringbuffer.append("' and class_code = '");
            stringbuffer.append(s4);
            stringbuffer.append("')");
        }
        String s6 = null;//oapagecontext.getParameter("HzPuiDQMOrgSearchExtraWhereClause");
        if(s6 != null && !"".equals(s6))
        {
            if(stringbuffer.length() > 0)
            {
                stringbuffer.append(" and ");
            }
            stringbuffer.append(s6);
        }
        Diagnostic.println("restrictSql: " + stringbuffer.toString());
        Diagnostic.println("getRestrictSql (-)");
        return stringbuffer;
    }

  /*   public void returnResults(OAPageContext oapagecontext, OAWebBean oawebbean, String s, String s1)
    {
        Vector vector = new Vector(2);
        StringBuffer stringbuffer = new StringBuffer();
        boolean isStatLogEnabled = oapagecontext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        if(isStatLogEnabled)
        {
          oapagecontext.writeDiagnostics(this,  "ODCO: In returnResult 2 var - ContextId - " + s, OAFwkConstants.STATEMENT);
          oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults 2 var sNewPartyId = " + s1, OAFwkConstants.STATEMENT);

        } 
        Diagnostic.println("OD: ContextId - " + s);
        Diagnostic.println("OD: sNewPartyId = " + s1);
        
        if(s1 != null)
        {
            vector.addElement(null);
            vector.addElement(s1);
        } else
        {
            Diagnostic.println("NEW matchoption = " + oapagecontext.getParameter("HzPuiMatchOptionDisplay"));
            vector.addElement(s);
            vector.addElement(null);
        }
        Diagnostic.println("extraClause = " + stringbuffer);
        try
        {
            Serializable aserializable[] = {
                null, stringbuffer, vector
            };
            Class aclass[] = {
                Class.forName("java.lang.StringBuffer"), Class.forName("java.lang.StringBuffer"), Class.forName("java.util.Vector")
            };
            OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
            oaapplicationmodule.invokeMethod("executeQuery", aserializable, aclass);
            return;
        }
        catch(ClassNotFoundException classnotfoundexception)
        {
            classnotfoundexception.printStackTrace();
        }
    }
    
    public void returnResults(OAPageContext oapagecontext, OAWebBean oawebbean, String s, String s1, String s2, String s3)
    {
        Vector vector = new Vector(4);
        StringBuffer stringbuffer = new StringBuffer();
        boolean isStatLogEnabled = oapagecontext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        if(isStatLogEnabled)
        {
          oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults", OAFwkConstants.STATEMENT);
          oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults ContextId - "+s, OAFwkConstants.STATEMENT);
          oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults sNewPartyId - "+s1, OAFwkConstants.STATEMENT);
          oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults PartySiteContextId - "+s2, OAFwkConstants.STATEMENT);
          oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults sNewPartySiteId - "+s3, OAFwkConstants.STATEMENT);
        }
        Diagnostic.println("OD: ContextId - " + s);
        Diagnostic.println("OD: sNewPartyId = " + s1);
        Diagnostic.println("OD: PartySiteContextId - " + s2);
        Diagnostic.println("OD: sNewPartySiteId = " + s3);
        BigDecimal bValS = new BigDecimal(s);
         BigDecimal bValS2 = new BigDecimal(s2);
        if(s1 != null)
        {
            vector.addElement(null);
            vector.addElement(s1);
        } else
        {
            Diagnostic.println("NEW matchoption = " + oapagecontext.getParameter("HzPuiMatchOptionDisplay"));
            vector.addElement(bValS);
            vector.addElement(null);
        }
        if(s3 != null)
        {
            vector.addElement(null);
            vector.addElement(s3);
        } else
        {
            Diagnostic.println("NEW matchoption = " + oapagecontext.getParameter("HzPuiMatchOptionDisplay"));
            vector.addElement(bValS2);
            vector.addElement(null);
        }
        Diagnostic.println("extraClause = " + stringbuffer);
        oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults extraClause = " + stringbuffer, OAFwkConstants.STATEMENT);
        try
        {
            Serializable aserializable[] = {
                null, stringbuffer, vector
            };
            Class aclass[] = {
                Class.forName("java.lang.StringBuffer"), Class.forName("java.lang.StringBuffer"), Class.forName("java.util.Vector")
            };
            OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
            if(isStatLogEnabled)
            {
               oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults calling executeQuery", OAFwkConstants.STATEMENT);
            }
            oaapplicationmodule.invokeMethod("executeQuery", aserializable, aclass);
            return;
        }
        catch(ClassNotFoundException classnotfoundexception)
        {
            classnotfoundexception.printStackTrace();
        }
    }*/


     //method being called for the object E0802
     public void returnResults(OAPageContext oapagecontext, OAWebBean oawebbean, String s1, String s2, String s11, String sDynamicOuter, String s1Outer, String extraRestrictiveSQL, String s3)
    {
        Vector vector = new Vector(3);
        StringBuffer stringbuffer = new StringBuffer();
        boolean isStatLogEnabled = oapagecontext.isLoggingEnabled(OAFwkConstants.STATEMENT);
        if(isStatLogEnabled)
        {
          oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults NEW  ", OAFwkConstants.STATEMENT);
          oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults ContextId NEW - "+s1, OAFwkConstants.STATEMENT);
          oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults sNewPartyId NEW - "+s2, OAFwkConstants.STATEMENT);
        }
        //s2 is sDynamic..party site dqm api call..in case of ADV search
		//s1 is for SIMPLE search only....plain dqm api call
		//s11 is the plain dqm api call in case of ADV search
		vector.addElement(s2);
		vector.addElement(s11);
        vector.addElement(s1);
		//vector.addElement(sDynamicOuter);
		//vector.addElement(s1Outer);
		
    
        Diagnostic.println("extraClause = " + stringbuffer);
        oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults extraClause = " + stringbuffer, OAFwkConstants.STATEMENT);
        try
        {
            Serializable aserializable[] = {
                null, stringbuffer, vector, extraRestrictiveSQL
            };
            Class aclass[] = {
                Class.forName("java.lang.StringBuffer"), Class.forName("java.lang.StringBuffer"), Class.forName("java.util.Vector"), Class.forName("java.lang.String")
            };
            OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
            if(isStatLogEnabled)
            {
               oapagecontext.writeDiagnostics(this,  "ODCO: In returnResults calling executeQuery", OAFwkConstants.STATEMENT);
            }
            oaapplicationmodule.invokeMethod("executeQuery", aserializable, aclass);
            return;
        }
        catch(ClassNotFoundException classnotfoundexception)
        {
            classnotfoundexception.printStackTrace();
        }
    } 
}
