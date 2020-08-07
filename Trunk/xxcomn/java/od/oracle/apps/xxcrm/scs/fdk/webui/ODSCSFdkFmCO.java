/*===========================================================================+
  |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
  |                         All rights reserved.                              |
  +===========================================================================+
  |  HISTORY                                                                  |
  +===========================================================================*/
package od.oracle.apps.xxcrm.scs.fdk.webui;

import com.sun.java.util.collections.HashMap;

import java.io.Serializable;

import java.sql.CallableStatement;

import java.util.Date;

import od.oracle.apps.xxcrm.scs.fdk.server.*;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OADefaultListBean;
import oracle.apps.fnd.framework.webui.beans.form.OADefaultShuttleBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAListOfValuesBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASpacerRowBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAStackLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OARowLayoutBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OADialogPage;

import oracle.jbo.Row;
import oracle.jbo.domain.Number;
import oracle.jbo.server.*;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

/**
 * Controller for ...
 */
public class ODSCSFdkFmCO extends OAControllerImpl {
    public static final String RCS_ID = "$Header$";
    public static final boolean RCS_ID_RECORDED = 
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

    /**
     * Layout and page setup logic for a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {
        super.processRequest(pageContext, webBean);
     if (!pageContext.isBackNavigationFired(false))
     {
        TransactionUnitHelper.startTransactionUnit(pageContext, "fdbkCreateTxn");
        if (!pageContext.isFormSubmission()) {
            String ent = pageContext.getParameter("SCSReqFrmEntityId");
            String typ = pageContext.getParameter("SCSReqFrmEntitytype");
            // Serializable[] params = {ent,typ }; 

            // am.invokeMethod("crtFdkFm", params);


            //oracle.apps.fnd.framework.OAApplicationModule  am= (oracle.apps.fnd.framework.OAApplicationModule)pageContext.getApplicationModule(webBean);
            ODSCSDshbdAMImpl am = 
                (ODSCSDshbdAMImpl)pageContext.getApplicationModule(webBean);
            //Create the ViewObject
            String party = am.crtFdkFm(ent, typ, pageContext.getUserName());
            System.out.println(ent + typ + party);
                        String val = party;

                    Serializable[] params2 = { val };

                    am.invokeMethod("crtCnctVO", params2);
            OATableLayoutBean oatablelayoutbean1 = 
                (OATableLayoutBean)webBean.findChildRecursive("TBLRN");
            OATableLayoutBean oatablelayoutbean100 = 
                (OATableLayoutBean)webBean.findChildRecursive("TBLRN1");
            OATableLayoutBean oatablelayoutbean200 = 
                (OATableLayoutBean)webBean.findChildRecursive("TBLRN2");
            OATableLayoutBean oatablelayoutbean300 = 
                (OATableLayoutBean)webBean.findChildRecursive("TBLRN3");
            OATableLayoutBean oatablelayoutbean400 = 
                (OATableLayoutBean)webBean.findChildRecursive("TBLRN4");

            OASpacerRowBean spc = 
                (OASpacerRowBean)this.createWebBean(pageContext, 
                                                    OAMessageChoiceBean.SPACER_ROW_BEAN, 
                                                    null, "sp");
            OASpacerRowBean spc100 = 
                (OASpacerRowBean)this.createWebBean(pageContext, 
                                                    OAMessageChoiceBean.SPACER_ROW_BEAN, 
                                                    null, "sp100");
            OASpacerRowBean spc200 = 
                (OASpacerRowBean)this.createWebBean(pageContext, 
                                                    OAMessageChoiceBean.SPACER_ROW_BEAN, 
                                                    null, "sp200");
            OASpacerRowBean spc300 = 
                (OASpacerRowBean)this.createWebBean(pageContext, 
                                                    OAMessageChoiceBean.SPACER_ROW_BEAN, 
                                                    null, "sp300");
            OASpacerRowBean spc400 = 
                (OASpacerRowBean)this.createWebBean(pageContext, 
                                                    OAMessageChoiceBean.SPACER_ROW_BEAN, 
                                                    null, "sp400");
            spc.setCellHeight("10");
            spc100.setCellHeight("10");
            spc200.setCellHeight("10");
            spc300.setCellHeight("10");
            spc400.setCellHeight("10");

            oatablelayoutbean1.addIndexedChild(spc);
            oatablelayoutbean100.addIndexedChild(spc100);
            oatablelayoutbean200.addIndexedChild(spc200);
            oatablelayoutbean300.addIndexedChild(spc300);
            oatablelayoutbean400.addIndexedChild(spc400);

            //   ODSCSFdbkQstnVOImpl dVo = ( ODSCSFdbkQstnVOImpl)            am.getODSCSFdbkQstnVO();

            //        dVo.setMaxFetchSize(-1);
            //        dVo.executeQuery();

            OAViewObject vo3 = 
                (OAViewObject)am.findViewObject("ODSCSFdbkQstnVO");
            vo3.setWhereClause(null);
            vo3.setWhereClauseParam(0, typ);
            Row oaRow = (Row)vo3.first();
            while (oaRow != null) {
                String FdkCode = "";
                String FdkDesc = "";
                String FdkType = "";
                String FrmCode = "";
                String Required = "";
                String DefaultValue = "";
                String Layout = "";
                Number OraSeq = new Number(0);

                FdkCode = (String)(oaRow.getAttribute("FdkCode"));
                FdkDesc = (String)(oaRow.getAttribute("FdkCodeDesc"));
                FdkType = (String)(oaRow.getAttribute("FdkType"));
                FrmCode = (String)(oaRow.getAttribute("FrmCode"));
                OraSeq = (Number)(oaRow.getAttribute("OraSeq"));
                Required = (String)(oaRow.getAttribute("Required"));
                DefaultValue = (String)(oaRow.getAttribute("DefaultValue"));
                Layout = (String)(oaRow.getAttribute("Layout"));


                if (Layout.equals("ROW")) {

                    OARowLayoutBean rowLayoutBean = 
                        (OARowLayoutBean)webBean.findChildRecursive(FrmCode);
                    if (rowLayoutBean == null) {
                        OARowLayoutBean oarowLayoutBean = 
                            (OARowLayoutBean)this.createWebBean(pageContext, 
                                                                OAWebBeanConstants.ROW_LAYOUT_BEAN, 
                                                                null, FrmCode);

                        OASpacerRowBean sp = 
                            (OASpacerRowBean)this.createWebBean(pageContext, 
                                                                OAMessageChoiceBean.SPACER_ROW_BEAN, 
                                                                null, 
                                                                "sp1" + FdkCode);

                        if (OraSeq.longValue() < 100) {
                            oatablelayoutbean1.addIndexedChild(oarowLayoutBean);
                            //oatablelayoutbean1.addIndexedChild(sp);

                        } else if (OraSeq.longValue() < 200) {
                            oatablelayoutbean100.addIndexedChild(oarowLayoutBean);
                            oatablelayoutbean100.addIndexedChild(sp);
                        } else if (OraSeq.longValue() < 300) {
                            oatablelayoutbean200.addIndexedChild(oarowLayoutBean);
                            oatablelayoutbean200.addIndexedChild(sp);
                        } else if (OraSeq.longValue() < 400) {
                            oatablelayoutbean300.addIndexedChild(oarowLayoutBean);
                            oatablelayoutbean300.addIndexedChild(sp);
                        } else if (OraSeq.longValue() < 500) {
                            oatablelayoutbean400.addIndexedChild(oarowLayoutBean);
                            oatablelayoutbean400.addIndexedChild(sp);
                        }

                    }
                }

                if (FdkType.equals("DDWN")) {


                    Serializable[] params = { FdkCode, typ };
                    am.invokeMethod("crtVO", params);


                    OAMessageChoiceBean popList = 
                        (OAMessageChoiceBean)this.createWebBean(pageContext, 
                                                                OAMessageChoiceBean.MESSAGE_CHOICE_BEAN, 
                                                                null, FdkCode);
                    popList.setPickListViewObjectDefinitionName("od.oracle.apps.xxcrm.scs.fdk.server." + 
                                                                FdkCode + 
                                                                "VO");
                    popList.setListDisplayAttribute("Value");
                    popList.setListValueAttribute("Code");
                    if (FdkDesc != null && !FdkDesc.equals(""))
                        popList.setPrompt(FdkDesc);
                    if (DefaultValue != null && !DefaultValue.equals("")) {
                        popList.setSelectedValue(DefaultValue);
                    }
                    if (Required.equals("Y")) {
                        popList.setRequired("yes");

                    }
                    OASpacerRowBean sp = 
                        (OASpacerRowBean)this.createWebBean(pageContext, 
                                                            OAMessageChoiceBean.SPACER_ROW_BEAN, 
                                                            null, 
                                                            "sp" + FdkCode);

                    if (Layout.equals("ROW")) {

                        OARowLayoutBean rowLayoutBean = 
                            (OARowLayoutBean)webBean.findChildRecursive(FrmCode);
                        rowLayoutBean.addIndexedChild(popList);
                    } else {


                        if (OraSeq.longValue() < 100) {
                            oatablelayoutbean1.addIndexedChild(popList);
                            oatablelayoutbean1.addIndexedChild(sp);

                        } else if (OraSeq.longValue() < 200) {
                            oatablelayoutbean100.addIndexedChild(popList);
                            oatablelayoutbean100.addIndexedChild(sp);
                        } else if (OraSeq.longValue() < 300) {
                            oatablelayoutbean200.addIndexedChild(popList);
                            oatablelayoutbean200.addIndexedChild(sp);
                        } else if (OraSeq.longValue() < 400) {
                            oatablelayoutbean300.addIndexedChild(popList);
                            oatablelayoutbean300.addIndexedChild(sp);
                        } else if (OraSeq.longValue() < 500) {
                            oatablelayoutbean400.addIndexedChild(popList);
                            oatablelayoutbean400.addIndexedChild(sp);
                        }
                    }
                } else if (FdkType.equals("LOV")) {
                    OAMessageLovInputBean atLovInput = 
                        (OAMessageLovInputBean)createWebBean(pageContext, 
                                                             LOV_TEXT, null, 
                                                             FdkCode);
                    oatablelayoutbean1.addIndexedChild(atLovInput);
//                    OAListOfValuesBean lovb =     (OAListOfValuesBean)createWebBean(pageContext, 
//                                                          LIST_OF_VALUES_BEAN, 
//                                                          null, 
//                                                          FdkCode + "lovRG");
        
                    atLovInput.setAttributeValue(REGION_APPLICATION_ID, 
                                                 new Integer(280));
//                    lovb.setAttributeValue(REGION_APPLICATION_ID, 
//                                           new Integer(280));
                    if (Required.equals("Y")) {
                        atLovInput.setRequired("yes");
                    }

                    atLovInput.setLovRegion("/od/oracle/apps/xxcrm/scs/fdk/webui/ODSCSSrcLovRN", 
                                            0);
                    atLovInput.setUnvalidated(false);
                    atLovInput.setPrompt(FdkDesc);
                    atLovInput.addLovRelations(pageContext, FdkCode, 
                                               "PersonName", LOV_CRITERIA, 
                                               LOV_REQUIRED_YES);
                    atLovInput.addLovRelations(pageContext, FdkCode, 
                                               "PersonName", LOV_RESULT, 
                                               LOV_REQUIRED_YES);
                    atLovInput.addLovRelations(pageContext, "CustId", 
                                               "ContactId", LOV_CRITERIA, 
                                               LOV_REQUIRED_YES);
                    atLovInput.addLovRelations(pageContext, "CustId", 
                                               "ContactId", LOV_RESULT, 
                                               LOV_REQUIRED_YES);
                }

                else if (FdkType.equals("SHT")) {
                    OADefaultShuttleBean shuttle = 
                        (OADefaultShuttleBean)webBean.findIndexedChildRecursive(FrmCode);
                    Serializable[] params = { FdkCode, typ };
                    am.invokeMethod("crtVO", params);

                    OADefaultListBean list2 = 
                        (OADefaultListBean)webBean.findChildRecursive("LL" + 
                                                                      FrmCode);
                    list2.setListViewObjectDefinitionName("od.oracle.apps.xxcrm.scs.fdk.server." + 
                                                          FdkCode + "VO");
                    list2.setListCacheEnabled(false);
                    shuttle.setLeading(list2);

                    OAStackLayoutBean st = 
                        (OAStackLayoutBean)webBean.findChildRecursive("Cont" + 
                                                                      FrmCode);
                    st.setRendered(true);
                    OAHeaderBean hb = 
                        (OAHeaderBean)webBean.findChildRecursive("HDR" + 
                                                                 FrmCode);
                    hb.setText(FdkDesc);
                    if (Required.equals("Y")) {
                        shuttle.setRequired("yes");
                    }


                }

                else if (FdkType.equals("TXTINPT") || 
                         FdkType.equals("TXTAREA")) {
                    OAMessageTextInputBean oamessagetextinputbean = 
                        (OAMessageTextInputBean)createWebBean(pageContext, 
                                                              OAWebBeanConstants.MESSAGE_TEXT_INPUT_BEAN, 
                                                              null, FdkCode);
                    oamessagetextinputbean.setLabel(FdkDesc);
                    oamessagetextinputbean.setPrompt(FdkDesc);
                    if (DefaultValue != null && !DefaultValue.equals("")) {
                        oamessagetextinputbean.setText(DefaultValue);
                    }

                    if (Required.equals("Y")) {
                        oamessagetextinputbean.setRequired("yes");
                    }
                    OASpacerRowBean sp = 
                        (OASpacerRowBean)this.createWebBean(pageContext, 
                                                            OAMessageChoiceBean.SPACER_ROW_BEAN, 
                                                            null, 
                                                            "sp" + FdkCode);
                    if (FdkType.equals("TXTAREA")) {
                        oamessagetextinputbean.setRows(4);
                        oamessagetextinputbean.setColumns(100);
                    }
                    if (OraSeq.longValue() < 100) {
                        oatablelayoutbean1.addIndexedChild(oamessagetextinputbean);
                        oatablelayoutbean1.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 200) {
                        oatablelayoutbean100.addIndexedChild(oamessagetextinputbean);
                        oatablelayoutbean100.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 300) {
                        oatablelayoutbean200.addIndexedChild(oamessagetextinputbean);
                        oatablelayoutbean200.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 400) {
                        oatablelayoutbean300.addIndexedChild(oamessagetextinputbean);
                        oatablelayoutbean300.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 500) {
                        oatablelayoutbean400.addIndexedChild(oamessagetextinputbean);
                        oatablelayoutbean400.addIndexedChild(sp);
                    }
                } else if (FdkType.equals("DTINPT")) {

                    OAMessageDateFieldBean dtfld = 
                        (OAMessageDateFieldBean)createWebBean(pageContext, 
                                                              OAWebBeanConstants.MESSAGE_DATE_FIELD_BEAN, 
                                                              null, FdkCode);
                    dtfld.setLabel(FdkDesc);
                    dtfld.setPrompt(FdkDesc);

                    dtfld.setDataType("DATE");

                    /* Changes To Fix the QC#14636
                     * Modified By: Ivarada
                     * Begins
                     */

                    if (DefaultValue != null && !DefaultValue.equals(""))
                    {
                      if ("SYSDATE".equals(DefaultValue.toUpperCase()))
                      {
                        java.util.Date todaysDate = new java.util.Date();
                        dtfld.setValue(todaysDate);
                      }
                      else 
                      {
                       try
                       {
                        java.text.DateFormat dtfmt = new java.text.SimpleDateFormat("dd-MMM-yyyy");
                        java.util.Date defDate = dtfmt.parse(DefaultValue);
                        dtfld.setValue(defDate);  
                       } catch (java.text.ParseException eparse) 
                       {
                          eparse.printStackTrace();
                          OAException confirmMessage = 
                          new OAException(eparse.toString(), OAException.ERROR);
                          pageContext.putDialogMessage(confirmMessage);
                       }
                      }
                    } 

                    /* Changes To Fix the QC#14636
                     * Modified By: Ivarada
                     * Ends
                     */

                    OADBTransaction transaction = am.getOADBTransaction();
                    long sysdate = 
                        transaction.getCurrentDBDate().dateValue().getTime();

                    if (oaRow.getAttribute("MinRange") != null) {
                        try {
                            Number MinRange = new Number(0);
                            MinRange = (Number)oaRow.getAttribute("MinRange");
                            Date minDate = 
                                new Date(sysdate + (MinRange.longValue() * 
                                                    86400000));
                            dtfld.setMinValue(minDate);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }

                    }
                    if (oaRow.getAttribute("MaxRange") != null) {
                        try {
                            Number MaxRange = new Number(0);
                            MaxRange = (Number)oaRow.getAttribute("MaxRange");
                            //             System.out.println(MaxRange+" MinRange");
                            Date maxDate = 
                                new Date(sysdate + (MaxRange.longValue() * 
                                                    86400000));
                            dtfld.setMaxValue(maxDate);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                    if (Required.equals("Y")) {
                        dtfld.setRequired("yes");
                    }
                    OASpacerRowBean sp = 
                        (OASpacerRowBean)this.createWebBean(pageContext, 
                                                            OAMessageChoiceBean.SPACER_ROW_BEAN, 
                                                            null, 
                                                            "sp" + FdkCode);
                    if (OraSeq.longValue() < 100) {
                        oatablelayoutbean1.addIndexedChild(dtfld);
                        oatablelayoutbean1.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 200) {
                        oatablelayoutbean100.addIndexedChild(dtfld);
                        oatablelayoutbean100.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 300) {
                        oatablelayoutbean200.addIndexedChild(dtfld);
                        oatablelayoutbean200.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 400) {
                        oatablelayoutbean300.addIndexedChild(dtfld);
                        oatablelayoutbean300.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 500) {
                        oatablelayoutbean400.addIndexedChild(dtfld);
                        oatablelayoutbean400.addIndexedChild(sp);
                    }
                }

                else if (FdkType.equals("CHK")) {

                    OAMessageCheckBoxBean chfld = 
                        (OAMessageCheckBoxBean)createWebBean(pageContext, 
                                                             OAWebBeanConstants.MESSAGE_CHECKBOX_BEAN, 
                                                             null, FdkCode);
                    chfld.setLabel(FdkDesc);
                    chfld.setPrompt(FdkDesc);
                    if (Required.equals("Y")) {
                        chfld.setRequired("yes");
                    }
                    OASpacerRowBean sp = 
                        (OASpacerRowBean)this.createWebBean(pageContext, 
                                                            OAMessageChoiceBean.SPACER_ROW_BEAN, 
                                                            null, 
                                                            "sp" + FdkCode);

                    if (OraSeq.longValue() < 100) {
                        oatablelayoutbean1.addIndexedChild(chfld);
                        oatablelayoutbean1.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 200) {
                        oatablelayoutbean100.addIndexedChild(chfld);
                        oatablelayoutbean100.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 300) {
                        oatablelayoutbean200.addIndexedChild(chfld);
                        oatablelayoutbean200.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 400) {
                        oatablelayoutbean300.addIndexedChild(chfld);
                        oatablelayoutbean300.addIndexedChild(sp);
                    } else if (OraSeq.longValue() < 500) {
                        oatablelayoutbean400.addIndexedChild(chfld);
                        oatablelayoutbean400.addIndexedChild(sp);
                    }
                }
                oaRow = vo3.next();
            }


            //       am.getTransaction().commit();
        }
     }
     else 
     {
       if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, "fdbkCreateTxn", true))
        { 
         OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR); 
         pageContext.redirectToDialogPage(dialogPage); 
        }
    }

    }
    /**
     * Procedure to handle form submissions for form elements in
     * a region.
     * @param pageContext the current OA page context
     * @param webBean the web bean corresponding to the region
     */
    public void processFormRequest(OAPageContext pageContext, 
                                   OAWebBean webBean) {
        super.processFormRequest(pageContext, webBean);

        OAApplicationModule am = pageContext.getApplicationModule(webBean);

        // Pressing the "Apply" button means the transaction should be validated
        // and committed.
        if (pageContext.getParameter("Apply") != null) {


            OAViewObject vo3 = 
                (OAViewObject)am.findViewObject("ODSCSFdbkQstnVO");
            vo3.executeQuery();
            Row oaRow = (Row)vo3.first();
            Number Dependents = new Number(0);
            Double result = new Double(0);

            while (oaRow != null) {
                String FdkCode = "";
                String FdkType = "";
                String FrmCode = "";
                FdkCode = (String)(oaRow.getAttribute("FdkCode"));
                Dependents = (Number)(oaRow.getAttribute("Dependents"));
                FdkType = (String)(oaRow.getAttribute("FdkType"));
                FrmCode = (String)(oaRow.getAttribute("FrmCode"));
                if (FdkType.equals("SHT")) {
                    Number tempDependents = new Number(0);
                    OADefaultShuttleBean shuttle = 
                        (OADefaultShuttleBean)webBean.findIndexedChildRecursive(FrmCode);
                    String[] trailingItems = 
                        shuttle.getTrailingListOptionValues(pageContext, 
                                                            shuttle);
                    if (trailingItems != null)
                        for (int i = 0; i < trailingItems.length; i++)
                            if (trailingItems[i] != null) {
                                tempDependents = Dependents;
                            }
                    result = 
                            new Double(result.doubleValue() + tempDependents.doubleValue());
                } else if ((FdkType.equals("DTINPT"))) {
                    if (pageContext.getParameter(FdkCode) != null) {

                        String x = pageContext.getParameter(FdkCode);
                        if (x != null && !x.equals("")) {

                            Date dt = 
                                new Date(pageContext.getParameter(FdkCode));
                            if (dt != null && !dt.equals("")) {
                                result = 
                                        new Double(result.doubleValue() + Dependents.doubleValue());
                            }
                        }
                    }
                } else if ((FdkType.equals("LOV"))) {
                    if (pageContext.getParameter(FdkCode) != null) {


                        String val = pageContext.getParameter("CustId");

                        if (val != null && !val.equals(""))
                            result = 
                                    new Double(Dependents.doubleValue() + result.doubleValue());
                    }
                } else if ((FdkType.equals("CHK"))) {
                    if (pageContext.getParameter(FdkCode) != null) {


                        String val = pageContext.getParameter(FdkCode);
                        if (val != null && !val.equals("")) {

                            if (val.equals("on")) {
                                val = "Yes";
                                result = 
                                        new Double(Dependents.doubleValue() + result.doubleValue());
                            }
                        }
                    }
                } else if (pageContext.getParameter(FdkCode) != null) {


                    String value = pageContext.getParameter(FdkCode);

                    if (value != null && !value.equals(""))
                        result = 
                                new Double(Dependents.doubleValue() + result.doubleValue());
                }
                oaRow = vo3.next();


            }

            if (!result.equals(new Double(0))) {

                OAException confirmMessage = 
                    new OAException("One OR More Dependent Questions Not Answered", 
                                    OAException.ERROR);
                pageContext.putDialogMessage(confirmMessage);
            } else {
                OAViewObject vo = 
                    (OAViewObject)am.findViewObject("ODSCSFdbkHdrVO");
                vo.getCurrentRow();
                Number fmNum = 
                    (Number)vo.getCurrentRow().getAttribute("FdbkId");
                Number eNum = 
                    (Number)vo.getCurrentRow().getAttribute("EntityId");
                String eTyp = 
                    (String)vo.getCurrentRow().getAttribute("EntityType");

                //        System.out.println(fmNum+"fmNum" +eNum +"Eid");
                vo3.executeQuery();
                oaRow = (Row)vo3.first();
                while (oaRow != null) {
                    String FdkCode = "";
                    String FdkDesc = "";
                    String FdkType = "";
                    String FrmCode = "";
                    String FdkPickValue = "";
                    Number FdbkQstnId = new Number(0);
                    Number OraSeq = new Number(0);
                    FdkCode = (String)(oaRow.getAttribute("FdkCode"));
                    FdkDesc = (String)(oaRow.getAttribute("FdkCodeDesc"));
                    FdkType = (String)(oaRow.getAttribute("FdkType"));
                    FrmCode = (String)(oaRow.getAttribute("FrmCode"));
                    OraSeq = (Number)(oaRow.getAttribute("OraSeq"));
                    FdkPickValue = 
                            (String)(oaRow.getAttribute("FdkPickValue"));
                    FdbkQstnId = (Number)(oaRow.getAttribute("FdbkQstnId"));

                    //  System.out.println("\t" + FdkCode+"\t" + FdkDesc+"\t" + FdkType); 
                    if (FdkType.equals("SHT")) {
                        //System.out.println("FrmCode  " +FrmCode);
                        OADefaultShuttleBean shuttle = 
                            (OADefaultShuttleBean)webBean.findIndexedChildRecursive(FrmCode);
                        String[] trailingItems = 
                            shuttle.getTrailingListOptionValues(pageContext, 
                                                                shuttle);
                        if (trailingItems != null)
                            for (int i = 0; i < trailingItems.length; i++)
                                if (trailingItems[i] != null) {
                                    //  System.out.println(" "+fmNum+", "+FdkCode+", "+trailingItems[i].toString());
                                    Serializable[] params = 
                                    { fmNum + "", FdkCode, 
                                      trailingItems[i].toString(), 
                                      FdkPickValue };
                                    am.invokeMethod("crtFdkRes", params);
                                }
                    } else if ((FdkType.equals("DTINPT"))) {
                        if (pageContext.getParameter(FdkCode) != null) {

                            String x = pageContext.getParameter(FdkCode);
                            if (x != null && !x.equals("")) {

                                Date dt = 
                                    new Date(pageContext.getParameter(FdkCode));

                                //  System.out.println(" "+fmNum+", "+FdkCode+", "+dt);
                                if (dt != null && !dt.equals("")) {
                                    Serializable[] params = 
                                    { fmNum + "", FdkCode, dt.toString(), 
                                      FdkPickValue };

                                    am.invokeMethod("crtFdkRes", params);
                                }
                            }
                        }
                    } else if ((FdkType.equals("LOV"))) {
                        if (pageContext.getParameter(FdkCode) != null) {


                            String val = pageContext.getParameter("CustId");

                            //  System.out.println(" "+fmNum+", "+FdkCode+", "+val);
                            Serializable[] params = 
                            { fmNum + "", FdkCode, val.toString(), 
                              FdkPickValue };
                            if (val != null && !val.equals(""))
                                am.invokeMethod("crtFdkRes", params);
                        }
                    } else if ((FdkType.equals("CHK"))) {
                        if (pageContext.getParameter(FdkCode) != null) {


                            String val = pageContext.getParameter(FdkCode);
                            if (val != null && !val.equals("")) {
                                //System.out.println(" "+fmNum+", "+FdkCode+", "+val);

                                if (val.equals("on")) {
                                    val = "Yes";
                                    //  System.out.println(" "+fmNum+", "+FdkCode+", "+val);
                                    Serializable[] params = 
                                    { fmNum + "", FdkCode, val.toString(), 
                                      FdkPickValue };
                                    am.invokeMethod("crtFdkRes", params);
                                }
                            }
                        }
                    } else if (pageContext.getParameter(FdkCode) != null) {


                        String value = pageContext.getParameter(FdkCode);

                        //  System.out.println(" "+fmNum+", "+FdkCode+", "+value);
                        Serializable[] params = 
                        { fmNum + "", FdkCode, value, FdkPickValue };
                        if (value != null && !value.equals(""))
                            am.invokeMethod("crtFdkRes", params);
                    }
                    oaRow = vo3.next();

                }

                am.invokeMethod("apply", null);
                TransactionUnitHelper.endTransactionUnit(pageContext, "fdbkCreateTxn");
               // rec_committed = 1;
                String Error_message = "";

                HashMap parameters = new HashMap();


                //   ODCsDshbdAMImpl am= this.getApplicationModule(pageContext, webBean);
                CallableStatement stmt = null;

                try {
                    OADBTransaction trx = 
                        pageContext.getRootApplicationModule().getOADBTransaction();
                    stmt = 
trx.createCallableStatement("begin " + "XXSCS_CONT_STRATEGY_PKG.P_Feedback_Actions(                  " + 
                            "             P_Feedback_ID   => :1, " + 
                            "            X_Ret_Code      => :2,  " + 
                            "           X_Error_Msg     => :3); " + 
                            " commit; " + "end; ", 1);

                    stmt.setInt(1, Integer.parseInt(fmNum.toString()));
                    stmt.registerOutParameter(2, Types.VARCHAR);
                    stmt.registerOutParameter(3, Types.VARCHAR);
                    stmt.execute();

                    String status = stmt.getString(2);
                    String error = stmt.getString(3);
                    //  System.out.println(fmNum +" - "+status+  " s -"  +error+" ERROR " );
                    Error_message = Error_message + error + " status" + status;
                    System.out.println(Error_message);
                    // parameters.put("fASNReqFrmOpptyId",usage_exists+"");  
                } catch (SQLException sqlexception) {
                    System.out.println(sqlexception);
                    //ErrorUtil.handleFatalException(oadbtransaction, sqlexception, this);
                }

                //parameters.put("akRegionCode", "FNDCPREQUESTVIEWREGION");
                //String id = """2167951""";
                //parameters.put("requestID",id);
                //http://chileba06d.na.odcorp.net:8020/OA_HTML/OA.jsp?page=/od/oracle/apps/xxcrm/cs/custom/webui/ODCsCrteOptntyCrtPG&ASNReqFrmOpptyId=8283

                MessageToken[] tokens = { };
                OAException confirmMessage = 
                    new OAException(Error_message, OAException.ERROR);
                pageContext.putDialogMessage(confirmMessage);

                /*pageContext.putDialogMessage(confirmMessage1);
    pageContext.forwardImmediately("OA.jsp?page=/oracle/apps/asn/opportunity/webui/OpptyDetPG",
                                  null,
                                  OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                  null,
                                 parameters,
                                  true, // retain AM
                                  OAWebBeanConstants.ADD_BREAD_CRUMB_YES);




 */


                //  OAException confirmMessage = new OAException( "Feedback Entered Successfuly",   OAException.CONFIRMATION);    

                pageContext.putDialogMessage(confirmMessage);

                // parameters.put("ASNReqFrmOpptyId",pageContext.getParameter("ASNReqFrmOpptyId"));  
                parameters.put("ASNReqFrmOpptyId", eNum.toString());
                parameters.put("ASNReqFrmLeadId", eNum.toString());
                parameters.put("SCSReqFrmSrc", "CS");
                String URL = "";
                if (eTyp.equals("OPPORTUNITY")) {
                    URL = 
"OA.jsp?page=/oracle/apps/asn/opportunity/webui/OpptyDetPG";
                } else {
                    URL = "OA.jsp?page=/oracle/apps/asn/lead/webui/LeadDetPG";
                }
                //  System.out.println(URL);
                // retain AM
                    pageContext.forwardImmediately(URL, null, 
                                                   OAWebBeanConstants.KEEP_MENU_CONTEXT, 
                                                   null, parameters, true, 
                                                   OAWebBeanConstants.ADD_BREAD_CRUMB_NO);


            }
        }
        if (pageContext.getParameter("Cancel") != null) {
            am.invokeMethod("Cancel"); // Indicate complete.
            //TransactionUnitHelper.endTransactionUnit(pageContext, "empCreateTxn");

            // retain AM
                pageContext.forwardImmediately(pageContext.getRequestUrlForRedirect(), 
                                               null, 
                                               OAWebBeanConstants.KEEP_MENU_CONTEXT, 
                                               null, null, false, 
                                               OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
        }
    }
                           //       }

}
