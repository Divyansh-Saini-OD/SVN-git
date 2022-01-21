package oracle.apps.ar.irec.accountDetails.inv.webui;

/*----------------------------------------------------------------------------
 -- Author: Sridevi K
 -- Component Id: E1356
 -- Script Location: $CUSTOM_JAVA_TOP/oracle/apps/ar/irec/accountDetails/inv/webui
 -- Description: Lines Summary Controller java file
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi K       2-Sep-2013   1.0       Retrofitted for R12 Upgrade.
                                            modified code for adding label 
											header for Arinestedregion2.

---------------------------------------------------------------------------*/

import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAStaticStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAFlowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;


public class LinesSummaryCO extends IROAControllerImpl {

    public static final String RCS_ID = 
        "$Header: LinesSummaryCO.java 120.2 2005/09/14 15:06:04 vgundlap noship $";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, 
                                       "oracle.apps.ar.irec.accountDetails.inv.webui");

    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {
        String s = null;
        s = "Step 10.10";
        pageContext.writeDiagnostics(this, 
                                     "XXOD: start oracle.apps.ar.irec.accountDetails.inv.webui.LinesSummaryCO.processRequest", 
                                     1);

        try {
            super.processRequest(pageContext, webBean);

            s = "Step 10.20";
            OATableLayoutBean webBeanLayout = 
                (OATableLayoutBean)createWebBean(pageContext, 
                                                 TABLE_LAYOUT_BEAN, null, 
                                                 null);
            webBeanLayout.setStyleClass("OraBGAccentDark");
            // Bugfix 2424727
            webBeanLayout.setWidth("100%");
            webBean.addIndexedChild(webBeanLayout);
            s = "Step 10.30";
            // add the first level header: Special Instructions.
            {
                OARowLayoutBean tableRow = 
                    (OARowLayoutBean)createWebBean(pageContext, 
                                                   ROW_LAYOUT_BEAN, null, 
                                                   null);
                webBeanLayout.addRowLayout(tableRow);
                tableRow.setStyleClass("OraTableColumnHeader");
                OACellFormatBean labelCell = 
                    (OACellFormatBean)createWebBean(pageContext, 
                                                    CELL_FORMAT_BEAN, null, 
                                                    null);
                tableRow.addIndexedChild(labelCell);
                labelCell.setColumnSpan(2);

                //
                s = "Step 10.40";
                
				
				/*Modified for R12 upgrade retrofit*/
				/*
				Commented below piece of because of exception
				java.lang.ClassCastException: oracle.apps.fnd.framework.webui.beans.layout.OAFlowLayoutBean 
				cannot be cast to oracle.cabo.ui.beans.message.MessageStyledTextBean

				
				
				OALabelBean label = (OALabelBean)createOIRLabel(pageContext, webBean, "Arinestedregion2");
                Object labelString = label.getLabel();

                OAMessageStyledTextBean header = (OAMessageStyledTextBean)createWebBean (pageContext, MESSAGE_STYLED_TEXT_BEAN, null, null);
                header.setText(pageContext, (null == labelString) ? "" : (String)labelString);
                header.setStyleClass("OraTableColumnHeader");
                s="Step 10.50";
                labelCell.addIndexedChild(header);
                */

                
                Object obj = 
                    (OAFlowLayoutBean)createWebBean(pageContext, webBean, 
                                                    "Arinestedregion2");
                OAStaticStyledTextBean oastaticstyledtextbean = 
                    (OAStaticStyledTextBean)createWebBean(pageContext, "LABEL", 
                                                          null, null);
                oastaticstyledtextbean.setText(((OAFlowLayoutBean)(obj)).getLabel());
                oastaticstyledtextbean.setRendered(((OAFlowLayoutBean)(obj)).isRendered());
                String s1 = oastaticstyledtextbean.getText();
                OAMessageStyledTextBean oamessagestyledtextbean = 
                    (OAMessageStyledTextBean)createWebBean(pageContext, 
                                                           "MESSAGE_TEXT", 
                                                           null, null);
                oamessagestyledtextbean.setText(pageContext, 
                                                null != s1 ? (String)s1 : "");
                oamessagestyledtextbean.setStyleClass("OraTableColumnHeader");
                labelCell.addIndexedChild(oamessagestyledtextbean);

			    /*End - Modified for R12 upgrade retrofit*/
            }
            s = "Step 10.60";

            {
                OARowLayoutBean tableRow = 
                    (OARowLayoutBean)createWebBean(pageContext, 
                                                   ROW_LAYOUT_BEAN, null, 
                                                   null);
                webBeanLayout.addRowLayout(tableRow);
                // special instructions and comments
                s = "Step 10.70";
                {
                    OACellFormatBean dataCell = 
                        (OACellFormatBean)createWebBean(pageContext, 
                                                        CELL_FORMAT_BEAN, null, 
                                                        null);
                    tableRow.addIndexedChild(dataCell);
                    // Bugfix 2424727
                    dataCell.setWidth("70%");

                    OAWebBean content = 
                        createWebBean(pageContext, webBean, "Arinestedregion2");
                    dataCell.addIndexedChild(content);
                    s = "Step 10.80";
                }
                {
                    OACellFormatBean dataCell = 
                        (OACellFormatBean)createWebBean(pageContext, 
                                                        CELL_FORMAT_BEAN, null, 
                                                        null);
                    tableRow.addIndexedChild(dataCell);

                    OAWebBean content = 
                        createWebBean(pageContext, webBean, "Arinestedregion1");
                    dataCell.addIndexedChild(content);
                    s = "Step 10.90";
                }
            }
            s = "Step 10.100";

            pageContext.writeDiagnostics(this, 
                                         "XXOD: end oracle.apps.ar.irec.accountDetails.inv.webui.LinesSummaryCO.processRequest", 
                                         1);

        } catch (Exception e) {
            pageContext.writeDiagnostics(this, 
                                         "XXOD: start oracle.apps.ar.irec.accountDetails.inv.webui.LinesSummaryCO.processRequest. Encountered error " + 
                                         s, 1);
            throw OAException.wrapperException(e);
        }

    }

}

