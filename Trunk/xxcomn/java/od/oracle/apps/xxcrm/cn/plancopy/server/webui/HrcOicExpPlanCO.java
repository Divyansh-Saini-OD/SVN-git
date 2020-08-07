// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3)
// Source File Name:   HrcOicExpPlanCO.java

package od.oracle.apps.xxcrm.cn.plancopy.server.webui;

import od.oracle.apps.xxcrm.cn.plancopy.server.HrcOicExpPlanAMImpl;
import java.io.PrintStream;
import java.io.Serializable;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;
import oracle.apps.fnd.framework.webui.beans.message.*;
import oracle.jbo.Row;

public class HrcOicExpPlanCO extends OAControllerImpl
{

    public HrcOicExpPlanCO()
    {
    }

    public void processRequest(OAPageContext pageContext, OAWebBean webBean)
    {
        super.processRequest(pageContext, webBean);
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        am.invokeMethod("init");
        RichTextEditorBean logTxt = (RichTextEditorBean)webBean.findIndexedChildRecursive("LogText");
        logTxt.setRenderingMode(2);
        logTxt.setRenderedSwitchModeLink(false);
    }

    public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
    {
        super.processFormRequest(pageContext, webBean);
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        if("exportTypeChange".equals(pageContext.getParameter("event")))
        {
            String exportTypeCH = pageContext.getParameter("ExportTypeChoice");
            Serializable parameters[] = {
                exportTypeCH
            };
            am.invokeMethod("exportTypeChangeEvent", parameters);
        }
        if(pageContext.getParameter("Export") != null)
        {
            String exportTypeCH = pageContext.getParameter("ExportTypeChoice");
            String param1 = new String();
            String param2 = new String();
            String param3 = new String();
            String param4 = new String();
            if(pageContext.getParameter("name1") != null)
            {
                param1 = pageContext.getParameter("id1");
                param2 = pageContext.getParameter("id2");
                param3 = pageContext.getParameter("id3");
                param4 = pageContext.getParameter("id4");
            } else
            {
                param1 = pageContext.getParameter("id5");
                param2 = pageContext.getParameter("id6");
                param3 = pageContext.getParameter("id7");
                param4 = pageContext.getParameter("id8");
            }
            HrcOicExpPlanAMImpl logAM = (HrcOicExpPlanAMImpl)pageContext.getApplicationModule(webBean);
            String exportReturn = logAM.planexport(exportTypeCH, param1, param2, param3, param4);
            RichTextEditorBean logTxt = (RichTextEditorBean)webBean.findIndexedChildRecursive("LogText");
            if(!"".equals(exportReturn))
            {
                System.out.println("Export Return**********************************" + exportReturn);
                OAViewObject vo = (OAViewObject)pageContext.getRootApplicationModule().findViewObject("ExportPVO1");
                vo.first();
                Row row = vo.getCurrentRow();
                row.setAttribute("LogRender", Boolean.TRUE);
                logTxt.setText(exportReturn);
            }
        }
        if(pageContext.getParameter("Update") != null)
        {
            OAMessageCheckBoxBean chbox1 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox1");
            OAMessageCheckBoxBean chbox2 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox2");
            OAMessageCheckBoxBean chbox3 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox3");
            OAMessageCheckBoxBean chbox4 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox4");
            OAMessageCheckBoxBean chbox11 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox11");
            OAMessageCheckBoxBean chbox21 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox21");
            OAMessageCheckBoxBean chbox31 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox31");
            OAMessageCheckBoxBean chbox41 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox41");
            OAMessageLovInputBean txt1 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name1");
            OAMessageLovInputBean txt2 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name2");
            OAMessageLovInputBean txt3 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name3");
            OAMessageLovInputBean txt4 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name4");
            OAMessageLovInputBean txt5 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name5");
            OAMessageLovInputBean txt6 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name6");
            OAMessageLovInputBean txt7 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name7");
            OAMessageLovInputBean txt8 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name8");
            if("on".equals(pageContext.getParameter("checkBox1")))
            {
                txt1.setText(pageContext, "");
                chbox1.setValue(pageContext, "off");
            }
            if("on".equals(pageContext.getParameter("checkBox2")))
            {
                txt2.setText(pageContext, "");
                chbox2.setValue(pageContext, "off");
            }
            if("on".equals(pageContext.getParameter("checkBox3")))
            {
                txt3.setText(pageContext, "");
                chbox3.setValue(pageContext, "off");
            }
            if("on".equals(pageContext.getParameter("checkBox4")))
            {
                txt4.setText(pageContext, "");
                chbox4.setValue(pageContext, "off");
            }
            if("on".equals(pageContext.getParameter("checkBox11")))
            {
                txt5.setText(pageContext, "");
                chbox11.setValue(pageContext, "off");
            }
            if("on".equals(pageContext.getParameter("checkBox21")))
            {
                txt6.setText(pageContext, "");
                chbox21.setValue(pageContext, "off");
            }
            if("on".equals(pageContext.getParameter("checkBox31")))
            {
                txt7.setText(pageContext, "");
                chbox31.setValue(pageContext, "off");
            }
            if("on".equals(pageContext.getParameter("checkBox41")))
            {
                txt8.setText(pageContext, "");
                chbox41.setValue(pageContext, "off");
            }
            System.out.println("The text value is ****" + txt1.getText(pageContext));
            if(txt1.getText(pageContext) == null && txt2.getText(pageContext) != null)
            {
                txt1.setText(pageContext, txt2.getText(pageContext));
                txt2.setText(pageContext, "");
            }
            if(txt2.getText(pageContext) == null && txt3.getText(pageContext) != null)
            {
                txt2.setText(pageContext, txt3.getText(pageContext));
                txt3.setText(pageContext, "");
                if(txt1.getText(pageContext) == null && txt2.getText(pageContext) != null)
                {
                    txt1.setText(pageContext, txt2.getText(pageContext));
                    txt2.setText(pageContext, "");
                }
            }
            if(txt3.getText(pageContext) == null && txt4.getText(pageContext) != null)
            {
                txt3.setText(pageContext, txt4.getText(pageContext));
                txt4.setText(pageContext, "");
                if(txt2.getText(pageContext) == null && txt3.getText(pageContext) != null)
                {
                    txt2.setText(pageContext, txt3.getText(pageContext));
                    txt3.setText(pageContext, "");
                    if(txt1.getText(pageContext) == null && txt2.getText(pageContext) != null)
                    {
                        txt1.setText(pageContext, txt2.getText(pageContext));
                        txt2.setText(pageContext, "");
                    }
                }
            }
        }
        if(pageContext.getParameter("Restore") != null)
        {
            OAMessageCheckBoxBean chbox1 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox1");
            OAMessageCheckBoxBean chbox2 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox2");
            OAMessageCheckBoxBean chbox3 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox3");
            OAMessageCheckBoxBean chbox4 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox4");
            OAMessageCheckBoxBean chbox11 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox11");
            OAMessageCheckBoxBean chbox21 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox21");
            OAMessageCheckBoxBean chbox31 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox31");
            OAMessageCheckBoxBean chbox41 = (OAMessageCheckBoxBean)webBean.findIndexedChildRecursive("checkBox41");
            OAMessageLovInputBean txt1 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name1");
            OAMessageLovInputBean txt2 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name2");
            OAMessageLovInputBean txt3 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name3");
            OAMessageLovInputBean txt4 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name4");
            OAMessageLovInputBean txt5 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name5");
            OAMessageLovInputBean txt6 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name6");
            OAMessageLovInputBean txt7 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name7");
            OAMessageLovInputBean txt8 = (OAMessageLovInputBean)webBean.findIndexedChildRecursive("name8");
            OAFormValueBean fv1 = (OAFormValueBean)webBean.findIndexedChildRecursive("id1");
            OAFormValueBean fv2 = (OAFormValueBean)webBean.findIndexedChildRecursive("id2");
            OAFormValueBean fv3 = (OAFormValueBean)webBean.findIndexedChildRecursive("id3");
            OAFormValueBean fv4 = (OAFormValueBean)webBean.findIndexedChildRecursive("id4");
            OAFormValueBean fv5 = (OAFormValueBean)webBean.findIndexedChildRecursive("id5");
            OAFormValueBean fv6 = (OAFormValueBean)webBean.findIndexedChildRecursive("id6");
            OAFormValueBean fv7 = (OAFormValueBean)webBean.findIndexedChildRecursive("id7");
            OAFormValueBean fv8 = (OAFormValueBean)webBean.findIndexedChildRecursive("id8");
            txt1.setText(pageContext, "");
            chbox1.setValue(pageContext, "off");
            fv1.setText(pageContext, "");
            txt2.setText(pageContext, "");
            chbox2.setValue(pageContext, "off");
            fv2.setText(pageContext, "");
            txt3.setText(pageContext, "");
            chbox3.setValue(pageContext, "off");
            fv3.setText(pageContext, "");
            fv4.setText(pageContext, "");
            txt4.setText(pageContext, "");
            chbox4.setValue(pageContext, "off");
            fv5.setText(pageContext, "");
            txt5.setText(pageContext, "");
            chbox11.setValue(pageContext, "off");
            fv6.setText(pageContext, "");
            txt6.setText(pageContext, "");
            chbox21.setValue(pageContext, "off");
            fv7.setText(pageContext, "");
            txt7.setText(pageContext, "");
            chbox31.setValue(pageContext, "off");
            fv8.setText(pageContext, "");
            txt8.setText(pageContext, "");
            chbox41.setValue(pageContext, "off");
        }
    }

    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header$", "%packagename%");

}
