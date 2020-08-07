// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3)
// Source File Name:   HrcOicImpPlanCO.java

package od.oracle.apps.xxcrm.cn.plancopy.webui;

import od.oracle.apps.xxcrm.cn.plancopy.server.HrcOicImpPlanAMImpl;
import java.io.PrintStream;
import java.io.Serializable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.cabo.ui.data.DataObject;
import oracle.jbo.Row;
import oracle.jbo.domain.BlobDomain;

public class HrcOicImpPlanCO extends OAControllerImpl
{

    public HrcOicImpPlanCO()
    {
    }

    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
        super.processRequest(pageContext, webBean);
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        am.invokeMethod("init");
        OAMessageStyledTextBean logTxt = (OAMessageStyledTextBean)webBean.findIndexedChildRecursive("LogText");
    }

    public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
    {
        super.processFormRequest(pageContext, webBean);
        if(pageContext.getParameter("Import") != null)
        {
            String fileFullName = pageContext.getParameter("ImpUpload");
            DataObject fileDataObject = pageContext.getNamedDataObject("ImpUpload");
            BlobDomain fileContent = (BlobDomain)fileDataObject.selectValue(null, fileFullName);
            System.out.println("Serialize *****************************");
            Serializable strParameters[] = {
                fileContent.toString()
            };
            System.out.println("Serialize After***************************");
            HrcOicImpPlanAMImpl myAM = (HrcOicImpPlanAMImpl)pageContext.getApplicationModule(webBean);
            System.out.println("Called *****************************");
            Integer reqId = (Integer)myAM.invokeMethod("getImpData", strParameters);
            System.out.println("The Request Id is: " + reqId);
            String parseReturn = "Your request has been submitted. Your request id is " + reqId;
            OAMessageStyledTextBean logTxt = (OAMessageStyledTextBean)webBean.findIndexedChildRecursive("LogText");
            logTxt.setText(pageContext, parseReturn);
            if(!"".equals(parseReturn))
            {
                OAViewObject vo = (OAViewObject)pageContext.getRootApplicationModule().findViewObject("LogPVO1");
                vo.first();
                Row row = vo.getCurrentRow();
                row.setAttribute("LogRender", Boolean.TRUE);
                logTxt.setText(parseReturn);
            }
        }
    }

    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header$", "%packagename%");

}
