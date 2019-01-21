/*
  -- +===========================================================================+
  -- |                  Office Depot - Project Simplify                          |
  -- |                         Office Depot                                      |
  -- +===========================================================================+
  -- | Name        :  ImcPerContPointsCO                                         |
  -- | Rice id     :  I2186                                                      |
  -- | Description :                                                             |
  -- | This is the controller for eBill update contacts email page               |
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

package oracle.apps.imc.ocong.contactpoints.webui;

import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.*;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.imc.ocong.util.webui.ImcUtilPkg;
import oracle.cabo.ui.data.DictionaryData;
import oracle.jbo.common.Diagnostic;

public class ImcOrgContPointsCreateCO extends OAControllerImpl
{

    public ImcOrgContPointsCreateCO()
    {
    }

    public void processRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processRequest(oapagecontext, oawebbean);
        ImcUtilPkg.debugPageContext(oapagecontext, "ImcOrgContPointsCreateCO -> ProcessRequest");
        if("CREATE".equals(oapagecontext.getParameter("ImcCntctPointEvent")) && oapagecontext.isBackNavigationFired(false))
        {
            OADialogPage oadialogpage = new OADialogPage((byte)3);
            oadialogpage.setHeaderNestedRegionRefName("/oracle/apps/imc/ocong/root/webui/ImcHideSideNavDummy");
            oapagecontext.redirectToDialogPage(oadialogpage);
        }
        String s = oapagecontext.getParameter("ImcGenPartyId");
        if(s == null)
            s = oapagecontext.getParameter("ImcPartyId");
        String s1 = oapagecontext.getParameter("ImcGenPartyName");
        if(s1 == null)
            s1 = oapagecontext.getParameter("ImcPartyName");
        Diagnostic.println((new StringBuilder()).append("ImcOrgContPointsCreateCO->processRequest. ImcCntctPointEvent = ").append(oapagecontext.getParameter("ImcCntctPointEvent")).toString());
        if("CREATE".equals(oapagecontext.getParameter("ImcCntctPointEvent")))
        {
            oapagecontext.putParameter("HzPuiOwnerTableName", "HZ_PARTIES");
            oapagecontext.putParameter("HzPuiOwnerTableId", s);
            oapagecontext.putParameter("HzPuiCntctPointEvent", "CREATE");
            oapagecontext.putTransactionTransientValue("ImcCntctPointEvent", "CREATE");
        } else
        if("UPDATE".equals(oapagecontext.getParameter("ImcCntctPointEvent")))
        {
            oapagecontext.putParameter("HzPuiCntctPointEvent", "UPDATE");
            oapagecontext.putParameter("HzPuiContactPointId", oapagecontext.getParameter("ImcContactPointId"));
            oapagecontext.putTransactionTransientValue("ImcCntctPointEvent", "UPDATE");
        }
        Diagnostic.println((new StringBuilder()).append("ImcOrgContPointsCreateCO->processRequest. sImcPartyId = ").append(s).toString());
        DictionaryData dictionarydata = new DictionaryData();
        dictionarydata.put("ImcPartyId", s);
        dictionarydata.put("ImcPartyName", s1);
        oapagecontext.setFunctionParameterDataObject(dictionarydata);
        oapagecontext.getPageLayoutBean().prepareForRendering(oapagecontext);
        oapagecontext.getPageLayoutBean().setStart(null);
        ImcUtilPkg.getMessage(oapagecontext);
    }

    public void processFormRequest(OAPageContext oapagecontext, OAWebBean oawebbean)
    {
        super.processFormRequest(oapagecontext, oawebbean);
        ImcUtilPkg.debugPageContext(oapagecontext, "ImcOrgContPointsCreateCO -> ProcessFormRequest");
        String s = oapagecontext.getParameter("ImcGenPartyId");
        String s1 = oapagecontext.getParameter("ImcGenPartyName");
        String s2 = oapagecontext.getParameter("ImcReturnFunction");
        Diagnostic.println((new StringBuilder()).append("ImcOrgContPointsCreateCO->processFormRequest. sImcPartyId = ").append(s).toString());
        OAApplicationModule oaapplicationmodule = oapagecontext.getApplicationModule(oawebbean);
        HashMap hashmap = new HashMap();
        hashmap.put("ImcGenPartyId", s);
        hashmap.put("ImcGenPartyName", s1);
        if(oapagecontext.getParameter("IMCAPPLYBUTTON") != null || oapagecontext.getParameter("IMCCREAEANOTHERBUTTON") != null)
        {
            String s3 = oapagecontext.getParameter("ImcCntctPointEvent");
            if(s3 == null || s3.length() == 0)
                s3 = (String)oapagecontext.getTransactionTransientValue("ImcCntctPointEvent");
            if("CREATE".equals(s3))
                ImcUtilPkg.putConfirmationMessage(oapagecontext, "IMC_NG_CF_CP_CREATE", null);
            else
            if("UPDATE".equals(s3))
                ImcUtilPkg.putConfirmationMessage(oapagecontext, "IMC_NG_CF_CP_UPDATE", null);
        }
        if(oapagecontext.getParameter("IMCAPPLYBUTTON") != null || oapagecontext.getParameter("IMCCANCELBUTTON") != null)
        {
            if(oapagecontext.getParameter("IMCAPPLYBUTTON") != null)
            {
                Diagnostic.println("Inside ImcOrgContPointsCreateCO.processFormRequest. IMCAPPLYBUTTON Cliked");
                oaapplicationmodule.invokeMethod("commitTransaction");
            }
			/*Start - Modified for R12 upgrade - Defect 28075*/
            //oapagecontext.setForwardURL(s2, (byte)0, "IMC_NG_MAIN_MENU", hashmap, false, "N", (byte)99);
			oapagecontext.setForwardURL(s2, (byte)0, "IMC_NG_MAIN_MENU", hashmap, false, "Y", (byte)99);
			/*End - Modified for R12 upgrade - Defect 28075*/
        } else
        if(oapagecontext.getParameter("IMCCREAEANOTHERBUTTON") != null)
        {
            Diagnostic.println("Inside ImcOrgContPointsCreateCO.processFormRequest. IMCCREAEANOTHERBUTTON Cliked");
            oaapplicationmodule.invokeMethod("commitTransaction");
            hashmap.put("HzPuiContactPointChanged", "NO");
            hashmap.put("EmHzPuiContactPointChanged", "NO");
            hashmap.put("UrlHzPuiContactPointChanged", "NO");
			/*Start - Modified for R12 upgrade - Defect 28075*/
            //oapagecontext.setForwardURLToCurrentPage(hashmap, false, "N", (byte)99);
			oapagecontext.setForwardURLToCurrentPage(hashmap, false, "Y", (byte)99);
			/*End - Modified for R12 upgrade - Defect 28075*/
        }
    }

    public static final String RCS_ID = "$Header: ImcOrgContPointsCreateCO.java 120.3 2005/11/17 21:57:37 vnama noship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ImcOrgContPointsCreateCO.java 120.3 2005/11/17 21:57:37 vnama noship $", "%packagename%");

}
