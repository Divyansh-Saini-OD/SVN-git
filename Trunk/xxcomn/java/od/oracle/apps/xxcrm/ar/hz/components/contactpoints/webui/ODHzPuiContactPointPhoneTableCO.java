/*===========================================================================+
  |                            Office Depot - Project Simplify                |
  |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
  +===========================================================================+
  |  FILENAME                                                                 |
  |             ODHzPuiContactPointPhoneTableCO.java                          |
  |                                                                           |
  |  DESCRIPTION                                                              |
  |    ODHzPuiContactPointPhoneTableCO.java                                   |
  |    includes the orginal code in seeded file                               |
  |    HzPuiContactPointPhoneTableCO.java file in its entirity along with some|
  |    custom modifications for making the phone table region as read only.   |
  |                                                                           |
  |                                                                           |
  |  NOTES                                                                    |
  |                                                                           |
  |                                                                           |
  |  DEPENDENCIES                                                             |
  |    None                                                                   |
  |                                                                           |
  |  HISTORY                                                                  |
  |                                                                           |
  |    14/12/2007   Anirban Chaudhuri  Created                                |
  +===========================================================================*/

package od.oracle.apps.xxcrm.ar.hz.components.contactpoints.webui;

import java.io.Serializable;
import java.util.Hashtable;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OASwitcherBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageRadioButtonBean;
import oracle.cabo.ui.beans.BaseWebBean;
import oracle.jbo.common.Diagnostic;

public class ODHzPuiContactPointPhoneTableCO extends OAControllerImpl
{

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        Diagnostic.println("Inside ODHzPuiContactPointPhoneTableCO processRequest");
        super.processRequest(oapagecontext, oawebbean);
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        OAMessageChoiceBean oamessagechoicebean = (OAMessageChoiceBean)oawebbean.findChildRecursive("HzPuiSelectedPhoneLineType");
        if(oamessagechoicebean != null)
            oamessagechoicebean.setRequiredIcon("no");
        
		oapagecontext.writeDiagnostics("anirban inside new CO", "anirban11dec: inside processRequest of the new CO: ODHzPuiContactPointPhoneTableCO: HzPuiCPPhoneTableEvent:  "+oapagecontext.getParameter("HzPuiCPPhoneTableEvent"), 1);

		oapagecontext.writeDiagnostics("anirban inside new CO", "anirban11dec: inside processRequest of the new CO: ODHzPuiContactPointPhoneTableCO: ReadOnlyModeDefect  "+oapagecontext.getParameter("ReadOnlyModeDefect"), 1);

        if("UPDATE".equals(oapagecontext.getParameter("HzPuiCPPhoneTableEvent")))
        {
            Diagnostic.println("Inside ODHzPuiContactPointPhoneTableCO. UPDATE event passed");
            String s = oapagecontext.getParameter("HzPuiOwnerTableName");
            String s1 = oapagecontext.getParameter("HzPuiOwnerTableId");
            oapagecontext.putTransactionValue("HzPuiOwnerTableName", s);
            oapagecontext.putTransactionValue("HzPuiOwnerTableId", s1);
            Diagnostic.println("pageContext HzPuiPhoneComponentMode = " + oapagecontext.getParameter("HzPuiPhoneComponentMode"));
            OAMessageRadioButtonBean oamessageradiobuttonbean = (OAMessageRadioButtonBean)oawebbean.findChildRecursive("singleSelection");
            OASwitcherBean oaswitcherbean = (OASwitcherBean)oawebbean.findChildRecursive("DeleteSwitcher");
            if("LOV".equals(oapagecontext.getParameter("HzPuiPhoneComponentMode")))
            {
                if(oamessageradiobuttonbean != null)
                    oamessageradiobuttonbean.setRendered(true);
                if(oaswitcherbean != null)
                    oaswitcherbean.setRendered(false);
            } else
            {
                if(oamessageradiobuttonbean != null)
                    oamessageradiobuttonbean.setRendered(false);
                if(oaswitcherbean != null)
                    oaswitcherbean.setRendered(true);
            }
            Serializable aserializable[] = {
                s, s1, "PHONE"
            };
            oaapplicationmodule.invokeMethod("initQuery", aserializable);
        }
        OAMessageChoiceBean oamessagechoicebean1 = (OAMessageChoiceBean)oawebbean.findIndexedChildRecursive("CpContactPointPurpose");
        if(oamessagechoicebean1 != null)
            oamessagechoicebean1.setRequiredIcon("no");

		if("ReadOnlyMode".equals((String)oapagecontext.getTransactionValue("ReadOnlyModeDefect")))
        {
         OASwitcherBean oaswitcherbean = (OASwitcherBean)oawebbean.findChildRecursive("DeleteSwitcher");
         if(oaswitcherbean != null)
                    oaswitcherbean.setRendered(false);
		 String s = oapagecontext.getParameter("HzPuiOwnerTableName");
         String s1 = oapagecontext.getParameter("HzPuiOwnerTableId");
         Serializable aserializable[] = {
                s, s1, "PHONE"
            };
         oaapplicationmodule.invokeMethod("initQuery", aserializable);
         oapagecontext.removeTransactionValue("ReadOnlyModeDefect");
		}
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        Diagnostic.println("Inside ODHzPuiContactPointPhoneTableCO processFormRequest");
        super.processFormRequest(oapagecontext, oawebbean);
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        if(oapagecontext.getParameter("HzPuiPhoneQCreateButton") != null)
        {
            String s = oapagecontext.getParameter("HzPuiOwnerTableName");
            Diagnostic.println("Inside ODHzPuiContactPointPhoneTableCO processFormRequest - HzPuiOwnerTableName " + s);
            if(s == null)
            {
                s = (String)oapagecontext.getTransactionValue("HzPuiOwnerTableName");
                Diagnostic.println("Inside ODHzPuiContactPointPhoneTableCO Gte value from transaction - HzPuiOwnerTableName " + s);
            }
            String s3 = oapagecontext.getParameter("HzPuiOwnerTableId");
            Diagnostic.println("Inside ODHzPuiContactPointPhoneTableCO processFormRequest - sHzPuiOwnerTableId " + s3);
            if(s3 == null)
            {
                s3 = (String)oapagecontext.getTransactionValue("HzPuiOwnerTableId");
                Diagnostic.println("Inside ODHzPuiContactPointPhoneTableCO Gte value from transaction - sHzPuiOwnerTableId " + s3);
            }
            String s6 = oapagecontext.getParameter("HzPuiPhoneLineType");
            Serializable aserializable1[] = {
                "PHONE", s, s3, s6
            };
            oaapplicationmodule.invokeMethod("createContactPoint", aserializable1);
        }
        if("DELETE".equals(oapagecontext.getParameter("HzPuiCPPhoneTableActionEvent")))
        {
            String s1 = oapagecontext.getParameter("HzPuiContactPointPhoneValue");
            String s4 = oapagecontext.getParameter("HzPuiContactPointPhoneId");
            MessageToken amessagetoken[] = {
                new MessageToken("CONTACT_POINT_VALUE", s1)
            };
            OAException oaexception = new OAException("AR", "HZ_PUI_REMOVE_PHONE_WARNING", amessagetoken);
            OADialogPage oadialogpage = new OADialogPage((byte)1, oaexception, null, "", "");
            String s7 = oapagecontext.getMessage("FND", "FND_DIALOG_YES", null);
            String s8 = oapagecontext.getMessage("FND", "FND_DIALOG_NO", null);
            oadialogpage.setOkButtonItemName("DeletePhoneYesButton");
            oadialogpage.setOkButtonToPost(true);
            oadialogpage.setNoButtonToPost(true);
            oadialogpage.setPostToCallingPage(true);
            oadialogpage.setOkButtonLabel(s7);
            oadialogpage.setNoButtonLabel(s8);
            Hashtable hashtable = new Hashtable(1);
            hashtable.put("HzPuiContactPointPhoneId", s4);
            hashtable.put("HzPuiContactPointPhoneValue", s1);
            hashtable.put("HzPuiResubmitFlag", "YES");
            oadialogpage.setFormParameters(hashtable);
            String s9 = oapagecontext.getParameter("HzPuiContactPointPhoneRegionRef");
            if(s9 != null && s9.length() > 0)
                oadialogpage.setHeaderNestedRegionRefName(s9);
            oapagecontext.redirectToDialogPage(oadialogpage);
        } else
        if(oapagecontext.getParameter("DeletePhoneYesButton") != null)
        {
            Diagnostic.println("Inside ODHzPuiContactPointPhoneTableCO processFormRequest. DeletedButtonYes");
            String s2 = oapagecontext.getParameter("HzPuiContactPointPhoneId");
            String s5 = oapagecontext.getParameter("HzPuiContactPointPhoneValue");
            Serializable aserializable[] = {
                s2, "PHONE"
            };
            if(s2 != null && s2.trim() != null)
            {
                oaapplicationmodule.invokeMethod("deleteContactPoint", aserializable);
                MessageToken amessagetoken1[] = {
                    new MessageToken("DISPLAY_VALUE", s5)
                };
                OAException oaexception1 = new OAException("AR", "HZ_PUI_REMOVE_CONFIRMATION", amessagetoken1, (byte)3, null);
                oapagecontext.putDialogMessage(oaexception1);
            }
        }
        Diagnostic.println("Inside ODHzPuiContactPointPhoneTableCO Before Exiting processFormRequest");
    }

    public ODHzPuiContactPointPhoneTableCO()
    {
    }

    public static final String RCS_ID = "$Header: ODHzPuiContactPointPhoneTableCO.java 115.14 2005/02/08 02:09:20 achaudhu noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODHzPuiContactPointPhoneTableCO.java 115.14 2005/02/08 02:09:20 jhuang noship $", "%packagename%");

}
