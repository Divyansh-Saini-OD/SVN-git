/*
  -- +===========================================================================+
  -- |                  Office Depot - Project Simplify                          |
  -- |                         Office Depot                                      |
  -- +===========================================================================+
  -- | Name        :  ImcPerContPointsCO                                         |
  -- | Rice id     :  I2186                                                      |
  -- | Description :                                                             |
  -- | This is the controller for eBill update contacts page                     |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author               Remarks                          |
  -- |======== =========== ================     ================================ |
  -- |1.0      12-Feb-2014 Sridevi K            Modified for Defect28075         |
  -- |===========================================================================|
*/
// Source File Name:   ImcPerContPointsCO.java

package oracle.apps.imc.ocong.contactpoints.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.imc.ocong.util.webui.ImcUtilPkg;
import oracle.cabo.ui.data.DictionaryData;
import oracle.jbo.common.Diagnostic;

public class ImcPerContPointsCO extends OAControllerImpl
{

    public ImcPerContPointsCO()
    {
    }

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        ImcUtilPkg.debugPageContext(oapagecontext, "ImcPerContPointsCO -> ProcessRequest");
        String s = (String)oapagecontext.getTransactionValue("HzPuiSelectedPartyId");
        if(s != null && s.length() > 0)
            oapagecontext.putParameter("HzPuiSelectedPartyId", s);
        String s1 = oapagecontext.getParameter("ImcGenPartyId");
        if(s1 == null)
            s1 = oapagecontext.getParameter("ImcPartyId");
        Diagnostic.println((new StringBuilder()).append("ImcPerContPointsCO->processRequest. sImcPartyId = ").append(s1).toString());
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        String s2 = oapagecontext.getParameter("ImcGenPartyName");
        if(s2 == null)
            s2 = oapagecontext.getParameter("ImcPartyName");
        ImcUtilPkg.setPartyPageTitles(oapagecontext, (OAPageLayoutBean)oawebbean, "IMC_LIST_CONTACT_PTS_TITLE", s2);
        String s3 = oapagecontext.getParameter("ImcMainPartyId");
        Diagnostic.println((new StringBuilder()).append("ImcPerContPointsCO->processRequest. ImcMainPartyId = ").append(s3).toString());
        if("{@ImcMainPartyId}".equals(s3))
            s3 = oapagecontext.getParameter("HzPuiMainPartyId");
        if(s3 == null || s3.length() == 0)
        {
            s3 = (String)oapagecontext.getTransactionValue("HzPuiMainPartyId");
            oapagecontext.putParameter("HzPuiMainPartyId", s3);
        }
        if(s3 == null || s3.length() == 0)
        {
            oapagecontext.putParameter("HzPuiDisplayedPartyId", s1);
            oapagecontext.putParameter("HzPuiHighlightedId", s1);
            oapagecontext.putParameter("HzPuiPartyId", s1);
            s3 = s1;
        } else
        {
            oapagecontext.putParameter("HzPuiDisplayedPartyId", s3);
            oapagecontext.putParameter("HzPuiHighlightedId", s1);
            oapagecontext.putParameter("HzPuiPartyId", s3);
        }
        oapagecontext.putParameter("HzPuiCPPhoneTableEvent", "UPDATE");
        oapagecontext.putParameter("HzPuiCPEmailTableEvent", "UPDATE");
        oapagecontext.putParameter("HzPuiCPUrlTableEvent", "UPDATE");
        oapagecontext.putParameter("HzPuiOwnerTableName", "HZ_PARTIES");
        oapagecontext.putParameter("HzPuiOwnerTableId", s1);
        oapagecontext.putParameter("HzPuiPartyListEvent", "DISPLAY");
        DictionaryData dictionarydata = new DictionaryData();
        dictionarydata.put("ImcPartyId", s1);
        dictionarydata.put("ImcPartyName", s2);
        dictionarydata.put("ImcMainPartyId", s3);
        oapagecontext.setFunctionParameterDataObject(dictionarydata);
        if(s3 != null && !s3.equals(s1))
            ImcUtilPkg.contactSideNav(oapagecontext, oawebbean);
        ImcUtilPkg.getMessage(oapagecontext);
		/*Start - commented for R12 upgrade - Defect 28075*/
        //((OAPageLayoutBean)oawebbean).setBreadCrumbEnabled(false); 
		/*End - commented for R12 upgrade - Defect 28075*/
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        oapagecontext.putParameter("HzPuiContactPointPhoneRegionRef", "/oracle/apps/imc/ocong/root/webui/ImcHideSideNavDummy");
        oapagecontext.putParameter("HzPuiContactPointUrlRegionRef", "/oracle/apps/imc/ocong/root/webui/ImcHideSideNavDummy");
        oapagecontext.putParameter("HzPuiContactPointEmailRegionRef", "/oracle/apps/imc/ocong/root/webui/ImcHideSideNavDummy");
        oapagecontext.putParameter("HzPuiContactPointEdiRegionRef", "/oracle/apps/imc/ocong/root/webui/ImcHideSideNavDummy");
        ImcUtilPkg.debugPageContext(oapagecontext, "ImcPerContPointsCO -> ProcessFormRequest");
        Object obj = null;
        Object obj1 = null;
        String s5 = "IMC_NG_MAIN_MENU";
        HashMap hashmap = new HashMap(6);
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        String s6 = oapagecontext.getParameter("HzPuiSelectedPartyId");
        oapagecontext.putTransactionValue("HzPuiSelectedPartyId", s6);
        String s7 = oapagecontext.getParameter("HzPuiMainPartyId");
        oapagecontext.putTransactionValue("HzPuiMainPartyId", s7);
        Serializable aserializable[] = {
            s6
        };
        String s8 = (String)oaapplicationmodule.invokeMethod("getPartyNameFromId", aserializable);
        hashmap.put("ImcGenPartyId", s6);
        hashmap.put("ImcGenPartyName", s8);
        hashmap.put("HzPuiMainPartyId", s7);
        hashmap.put("ImcReturnFunction", "IMC_NG_PER_CONT_POINTS");
        String s9 = oapagecontext.getParameter("HzPuiCPEmailTableActionEvent");
        String s10 = oapagecontext.getParameter("HzPuiCPPhoneTableActionEvent");
        String s11 = oapagecontext.getParameter("HzPuiCPUrlTableActionEvent");
        if((s9 == null || s9.equals("")) && (s10 == null || s10.equals("")) && (s11 == null || s11.equals("")))
            hashmap.put("ImcCntctPointEvent", "CREATE");
        else
            hashmap.put("ImcCntctPointEvent", "UPDATE");
        if(oapagecontext.getParameter("hzPuiPartyListGoButton") != null)
        {
            if(s6 != null)
            {
                String s4 = "IMC_NG_PER_CONT_POINTS";
                oapagecontext.setForwardURL(s4, (byte)4, s5, hashmap, false, "N", (byte)99);
            }
        } else
        if(oapagecontext.getParameter("HzPuiPhoneCreateButton") != null || "UPDATE".equals(s10))
        {
            String s;
            if("UPDATE".equals(s10))
            {
                hashmap.put("ImcContactPointId", oapagecontext.getParameter("HzPuiContactPointPhoneId"));
                s = "IMC_NG_PER_UPDATE_PHONE";
            } else
            {
                hashmap.put("HzPuiPhoneLineType", oapagecontext.getParameter("HzPuiSelectedPhoneLineType"));
                s = "IMC_NG_PER_CREATE_PHONE";
            }
			/*Start - Modified for R12 upgrade - Defect 28075*/
            //oapagecontext.setForwardURL(s, (byte)0, "IMC_NG_MAIN_MENU", hashmap, false, "RS", (byte)99);
			oapagecontext.setForwardURL(s, (byte)0, "IMC_NG_MAIN_MENU", hashmap, false, "Y", (byte)99);
			/*End - Modified for R12 upgrade - Defect 28075*/
        } else
        if(oapagecontext.getParameter("HzPuiEmailCreateButton") != null || "UPDATE".equals(s9))
        {
            String s1;
            if("UPDATE".equals(s9))
            {
                hashmap.put("ImcContactPointId", oapagecontext.getParameter("HzPuiContactPointEmailId"));
                s1 = "IMC_NG_PER_UPDATE_EMAIL";
            } else
            {
                s1 = "IMC_NG_PER_CREATE_EMAIL";
            }
			/*Start - Modified for R12 upgrade - Defect 28075*/
            //oapagecontext.setForwardURL(s1, (byte)0, "IMC_NG_MAIN_MENU", hashmap, false, "RS", (byte)99);
			oapagecontext.setForwardURL(s1, (byte)0, "IMC_NG_MAIN_MENU", hashmap, false, "Y", (byte)99);
			/*End - Modified for R12 upgrade - Defect 28075*/
        } else
        if(oapagecontext.getParameter("HzPuiUrlCreateButton") != null || "UPDATE".equals(s11))
        {
            String s2;
            if("UPDATE".equals(s11))
            {
                hashmap.put("ImcContactPointId", oapagecontext.getParameter("HzPuiContactPointUrlId"));
                s2 = "IMC_NG_PER_UPDATE_URL";
            } else
            {
                s2 = "IMC_NG_PER_CREATE_URL";
            }
			/*Start - Modified for R12 upgrade - Defect 28075*/
            //oapagecontext.setForwardURL(s2, (byte)0, "IMC_NG_MAIN_MENU", hashmap, false, "RS", (byte)99);
		    oapagecontext.setForwardURL(s2, (byte)0, "IMC_NG_MAIN_MENU", hashmap, false, "Y", (byte)99);
			/*End - Modified for R12 upgrade - Defect 28075*/
        } else
        if(oapagecontext.getParameter("HzPuiEmailDomainCreateButton") != null)
        {
            String s3 = "IMC_NG_PER_CREATE_DOMAIN";
			/*Start - Modified for R12 upgrade - Defect 28075*/
            //oapagecontext.setForwardURL(s3, (byte)0, "IMC_NG_MAIN_MENU", hashmap, false, "RS", (byte)99);
			oapagecontext.setForwardURL(s3, (byte)0, "IMC_NG_MAIN_MENU", hashmap, false, "Y", (byte)99);
			/*End - Modified for R12 upgrade - Defect 28075*/
        }
    }

    public static final String RCS_ID = "$Header: ImcPerContPointsCO.java 120.7 2006/04/24 07:31:35 jgjoseph noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ImcPerContPointsCO.java 120.7 2006/04/24 07:31:35 jgjoseph noship $", "%packagename%");

}
