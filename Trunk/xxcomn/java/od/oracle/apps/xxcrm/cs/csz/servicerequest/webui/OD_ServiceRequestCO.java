/*===========================================================================+
 |      		      Office Depot - TDS Parts                               |
 |                Oracle Consulting Organization, Redwood Shores, CA, USA    |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             OD_ServiceRequestCO.java                                      |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Class to get the TDS Parts from the database.                          |
 |    Also used for validation upon submission.                              |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |  HISTORY                                                                  |
 | Ver  Date       Name           Revision Description                       |
 | ===  =========  ============== ===========================================|
 | 1.0  09-SEP-11  Suraj Charan   Initial.                                   |
 | 1.1  06-Oct-12  Jay Gupta      Added condition for OD_QTY_GTR_INV_QTY msg |                                                                            |
 | 1.2  27-FEB-13  Suraj Charan   Added back navigation code                 |                                                                            |
 | 1.3  28-FEB-13  Suraj Charan   Enable complete flag for R and Y           |                                                             |
 +===========================================================================*/

package od.oracle.apps.xxcrm.cs.csz.servicerequest.webui;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import java.sql.SQLException;
import java.sql.Types;

import od.oracle.apps.xxcrm.cs.csz.servicerequest.server.OD_ServiceRequestAMImpl;
import od.oracle.apps.xxcrm.cs.csz.servicerequest.server.OD_ServiceRequestDetailsVOImpl;
import od.oracle.apps.xxcrm.cs.csz.servicerequest.server.OD_ServiceRequestDetailsVORowImpl;
import od.oracle.apps.xxcrm.cs.csz.servicerequest.server.OD_ServiceRequestMasterVOImpl;
import od.oracle.apps.xxcrm.cs.csz.servicerequest.server.OD_ServiceRequestMasterVORowImpl;
import od.oracle.apps.xxcrm.cs.csz.servicerequest.server.OD_ServiceRequestRcvQtyVOImpl;
import od.oracle.apps.xxcrm.cs.csz.servicerequest.server.OD_ServiceRequestRcvQtyVORowImpl;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OABodyBean;
import oracle.apps.fnd.framework.webui.beans.OAStaticStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAHeaderBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageCheckBoxBean;
import oracle.apps.fnd.framework.webui.OADialogPage;

import oracle.cabo.style.CSSStyle;

import oracle.jbo.RowSetIterator;
import oracle.jbo.domain.Number;

import oracle.jdbc.OracleCallableStatement;
/**
 * Controller for ...
 */
public class OD_ServiceRequestCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    String srNumber = null;
    String wohdrTxt = null;
    String qhdrTxt = null;
    String qTxt = null;
    String woTxt = null;
    String detailTxt = null;

    StringBuffer where = new StringBuffer();
    OAApplicationModule tdsAM = pageContext.getApplicationModule(webBean);
    OAHeaderBean wohdrBean = (OAHeaderBean)webBean.findChildRecursive("SearchResultsHDR");
    OAHeaderBean quotehdrBean = (OAHeaderBean)webBean.findChildRecursive("QuoteHdr");
    OAStaticStyledTextBean quoteBean = (OAStaticStyledTextBean)webBean.findChildRecursive("QuotationNumber");
    OAStaticStyledTextBean workOrdBean = (OAStaticStyledTextBean)webBean.findChildRecursive("WorkOrder");
    OAMessageCheckBoxBean recShipFlagBean = (OAMessageCheckBoxBean)webBean.findChildRecursive("ReceivedShipmentFlag");
    OAHeaderBean instHdr = (OAHeaderBean)webBean.findChildRecursive("Inst");
    OAHeaderBean msgHdr = (OAHeaderBean)webBean.findChildRecursive("Inst2");
    OAViewObject SrVO = (OAViewObject)tdsAM.findViewObject("OD_ServiceRequestMasterVO");
    OAViewObject SrDtlVO = (OAViewObject)tdsAM.findViewObject("OD_ServiceRequestDetailsVO");

    srNumber = pageContext.getParameter("SRNumber");
    //V1.2 Code added for Back Navigation
    if (pageContext.isBackNavigationFired(true))
    pageContext.redirectToDialogPage(new OADialogPage(NAVIGATION_ERROR));

     if (srNumber!=null){
      wohdrTxt = wohdrBean.getText(pageContext);
      qhdrTxt = quotehdrBean.getText(pageContext);
      qTxt = "Quotation Number:";
      woTxt = "Work Order:";
      wohdrBean.setText(pageContext,wohdrTxt+' '+srNumber);
      CSSStyle customCss = new CSSStyle();
      customCss.setProperty("color", "#336699");
      customCss.setProperty("font-family","Arial");
      customCss.setProperty("font-size","13pt");
      customCss.setProperty("font-weight","bold");
      where.append(" REQUEST_NUMBER ='"+srNumber+"'");
      SrVO.setWhereClause(where.toString());
      SrVO.executeQuery();
      OD_ServiceRequestMasterVORowImpl srVORow = (OD_ServiceRequestMasterVORowImpl)SrVO.first();
      if(SrVO.getRowCount()==0)
      throw new OAException("XXCRM","NO_DATA_FOUND",null,OAException.ERROR,null);

      if(!"".equals(srVORow.getQuoteNumber()) && srVORow.getQuoteNumber()!=null)
      quotehdrBean.setText(pageContext,qhdrTxt+' '+srVORow.getQuoteNumber());

      detailTxt = instHdr.getText(pageContext);
      instHdr.setText(pageContext,detailTxt+" "+srVORow.getExchangePrice());
////// Enable Items based on the complete flag
      RowSetIterator hdrIter  = SrVO.findRowSetIterator("hdrIter");
      String hdtItemNo = null;
      String hdrReqNo = null;
      String dtlItemNo = null;
      String dtlReqNo = null;
      if(hdrIter!=null)
      {
        hdrIter.closeRowSetIterator();
      }
      hdrIter=SrVO.createRowSetIterator("hdrIter");
      int fetchedRowCount=SrVO.getRowCount();
      ArrayList exceptionList = new ArrayList();
      if(fetchedRowCount>0)
      {

      hdrIter.setRangeStart(0);
      hdrIter.setRangeSize(fetchedRowCount);
      for (int count = 0; count < fetchedRowCount; count++)
      {
       srVORow=(OD_ServiceRequestMasterVORowImpl)hdrIter.getRowAtRangeIndex(count);
       // Added Date: 03-JAN-2012
       //
       int defValue = 0, totRecQty = 0;
       if(srVORow.getTotReceivedQty() != null){
       totRecQty = srVORow.getTotReceivedQty().intValue();
       }

       if((totRecQty == defValue || srVORow.getTotReceivedQty() == null) && ("N".equals(srVORow.getReceivedShipmentFlag()) ||  srVORow.getReceivedShipmentFlag() == null)  ){

       //For Testing below if block
//       if(srVORow.getReceivedShipmentFlag() == null){
//       srVORow.setRecptFlag("Y");}else if("N".equals(srVORow.getReceivedShipmentFlag())){srVORow.setRecptFlag("Y");}

        if(srVORow.getRecptFlag() == null || "N".equals(srVORow.getRecptFlag())){
//        All the flag should be read only (users can be only read data and
//        use close/save button).

        srVORow.setNotUsedQty(Boolean.TRUE);
        srVORow.setNotUsed(Boolean.TRUE);
        srVORow.setReceivedShipment(Boolean.TRUE);
        srVORow.setReceivedShipmentRender(Boolean.TRUE);//Added as per Raj Date:23-Aug-2012
        srVORow.setReceive_Quantity(Boolean.TRUE);
        srVORow.setComplete(Boolean.TRUE);
        srVORow.setFreightCarrier(Boolean.TRUE);
        srVORow.setTracking_Number(Boolean.TRUE);

        }
        else if("Y".equals(srVORow.getRecptFlag())){
//        if(!"N".equals(srVORow.getReceivedShipmentFlag()) && !"R".equals(srVORow.getReceivedShipmentFlag()) ){
//        Enable received flag and qty.
        srVORow.setReceivedShipmentRender(Boolean.TRUE);
        srVORow.setReceivedShipment(Boolean.FALSE);
        srVORow.setReceive_Quantity(Boolean.FALSE);
        }
       }
    // Jay }
        if(srVORow.getReceivedQuantity() !=null && ("R".equals(srVORow.getReceivedShipmentFlag())) ){
        //When page is loaded if recevied quantity is null the below items are read-only.
          srVORow.setReceivedShipment(Boolean.TRUE);
          srVORow.setReceive_Quantity(Boolean.TRUE);

          srVORow.setNotUsed(Boolean.FALSE);
          srVORow.setNotUsedQty(Boolean.TRUE);
          srVORow.setTracking_Number(Boolean.FALSE);
          srVORow.setFreightCarrier(Boolean.FALSE);
          srVORow.setComplete(Boolean.FALSE);
          srVORow.setReceivedShipment(Boolean.TRUE);
          srVORow.setReceivedShipmentRender(Boolean.TRUE);
          srVORow.setReceive_Quantity(Boolean.TRUE);
        }
        else{
        srVORow.setCore_Flag(Boolean.FALSE);
        srVORow.setNotUsed(Boolean.TRUE);
        srVORow.setNotUsedQty(Boolean.TRUE);
        srVORow.setTracking_Number(Boolean.TRUE);
        srVORow.setFreightCarrier(Boolean.TRUE);
        srVORow.setComplete(Boolean.TRUE);
        srVORow.setFreightCarrier(Boolean.TRUE);
        }

        if("R".equals(srVORow.getReceivedShipmentFlag()))
        {
          srVORow.setReceive_Quantity(Boolean.TRUE);
          srVORow.setReceivedShipmentRender(Boolean.FALSE);
        }
        //Modified Date: 02-JAN-2012
        // To enable Received Shipment Column when Y
//        if("Y".equals(srVORow.getRecptFlag()))
//        {
//          srVORow.setReceivedShipmentRender(Boolean.TRUE);
//          srVORow.setReceivedShipment(Boolean.FALSE);
//        }

        if("Y".equals(srVORow.getCoreFlag()))
          srVORow.setCore_Flag(Boolean.TRUE);
        else
         srVORow.setCore_Flag(Boolean.FALSE);

       //////After fwdImmediately of submit button

       if("Submit".equals(pageContext.getParameter("EVENT"))){
          MessageToken[] tokens = { new MessageToken("ITEM_NUMBER", srVORow.getItemNumber()) };
          if(srVORow.getReceivedQuantity()==null){
//            exceptionList.add(new OAException("XXCRM","OD_RECEIVED_QUANTITY_NULL",tokens,OAException.ERROR,null));
          }
          if("N".equals(srVORow.getReceivedShipmentFlag()) || srVORow.getReceivedShipmentFlag()==null )
//            exceptionList.add(new OAException("XXCRM","OD_RCV_SHPMT_FLAG",tokens,OAException.ERROR,null));

        if(srVORow.getReceivedQuantity()!=null && "R".equals(srVORow.getReceivedShipmentFlag())){
        srVORow.setNotUsed(Boolean.FALSE);
        srVORow.setNotUsedQty(Boolean.TRUE);
        srVORow.setTracking_Number(Boolean.FALSE);
        srVORow.setFreightCarrier(Boolean.FALSE);
        srVORow.setComplete(Boolean.FALSE);
        srVORow.setReceivedShipment(Boolean.TRUE);
        srVORow.setReceive_Quantity(Boolean.TRUE);
        }
        /*
         if(srVORow.getExcessQuantity()!=null){
         hdrVORow.setAttribute2(null);
         if(srVORow.getAttribute1()==null)
         exceptionList.add(new OAException("XXCRM","OD_TRACKING_NUMBER_NULL",tokens,OAException.ERROR,null));
         throw new OAException("XXCRM","OD_TRACKING_NUMBER_NULL",tokens,OAException.ERROR,null);
         pageContext.putDialogMessage(new OAException("XXCRM","OD_NOT_USED_QTY",null,OAException.INFORMATION,null));
         }
         */

         if("Y".equals(srVORow.getSalesFlag())){
         OADBTransaction txn=tdsAM.getOADBTransaction();
         oracle.jbo.domain.Date sysDate = txn.getCurrentDBDate();
         srVORow.setCompletionDate(sysDate);
         }

//         if(srVORow.getQuantity().intValue() > 1 && srVORow.getExcessQuantity() ==null && "Y".equals(srVORow.getSalesFlag()) ) // &&(!"Y".equals(srVORow.getExcessFlag())) )
//         {
//           srVORow.setNotUsedQty(Boolean.FALSE);
//           if(srVORow.getExcessQuantity()==null && "Y".equals(srVORow.getSalesFlag()))
//            exceptionList.add(new OAException("XXCRM","EXCESS_QTY_NULL",tokens,OAException.INFORMATION,null));
//         }
       }
       //////Endof fwd Immediately of Submt buton
       //////Start fwd Immediately of Complete
       if("Complete".equals(pageContext.getParameter("EVENT"))){
        if("Y".equals(srVORow.getSalesFlag())){
         srVORow.setComplete(Boolean.TRUE);
        }
       }
       ////// End of fwd Immediate of Complete
        int qty = 0, tRQty = 0;
        if(srVORow.getQuantity()!=null)
        qty = Integer.parseInt(srVORow.getQuantity().toString());
        if(srVORow.getTotReceivedQty()!=null)
        tRQty = Integer.parseInt(srVORow.getTotReceivedQty().toString());
//        if(tRQty >= qty){// Changed on 30-Aug-2012

        if((tRQty == qty) && ("R".equals(srVORow.getReceivedShipmentFlag())) ){
        srVORow.setComplete(Boolean.FALSE);
        srVORow.setReceivedShipment(Boolean.TRUE);//Fix on 18-Jul-2012
        srVORow.setReceive_Quantity(Boolean.TRUE);//Fix on 18-Jul-2012
        }
        else{
        srVORow.setComplete(Boolean.TRUE);
        }
        //V1.3 added condition if the receivedshipmentflag is Y
        if("R".equals(srVORow.getReceivedShipmentFlag()) || "Y".equals(srVORow.getReceivedShipmentFlag()))
        {
          srVORow.setComplete(Boolean.FALSE);
        }
	  }//end of for loop
    OAException.raiseBundledOAException(exceptionList);
	}
  if("Submit".equals(pageContext.getParameter("EVENT"))){
        tdsAM.invokeMethod("apply");
        OracleCallableStatement oraclecallablestatement = null;
        OADBTransaction oadbtransaction = tdsAM.getOADBTransaction();
        String status = null;
        String msg = null;
        try
        {

            String stmt = "begin XX_CS_TDS_PARTS_UI.MAIN_PROC(:1,:2,:3); end;";
            oraclecallablestatement = (OracleCallableStatement)oadbtransaction.createCallableStatement(stmt, 10);
            oraclecallablestatement.setString(1,srNumber);
            oraclecallablestatement.registerOutParameter(2,Types.VARCHAR);
            oraclecallablestatement.registerOutParameter(3,Types.VARCHAR);
            oraclecallablestatement.execute();
            status = oraclecallablestatement.getString(2);
            msg = oraclecallablestatement.getString(3);
//            if(!"E".equals(status))
            pageContext.forwardImmediately("OA.jsp?OAFunc=OD_CSZ_SR_DB_FN&OASF=OD_CSZ_SR_DB_FN&OAHP=CSZ_SR_T2_AGENT_HOME_PAGE&OAPB=CSZ_SR_BRAND&addBreadCrumb=RP",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
        }catch(SQLException sqlexception)
        {
        }
		finally {
               try {
				   if (oraclecallablestatement!=null)
				     oraclecallablestatement.close();
				   }
               catch(Exception e) {
               }
		}
     }
    }
    /*
    if("TRUE".equals(pageContext.getParameter("Value")))
    {
      instHdr.setRendered(true);
    }
    */
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
    com.sun.java.util.collections.HashMap  addParams = new com.sun.java.util.collections.HashMap(1);
    OAApplicationModule tdsAM = pageContext.getApplicationModule(webBean);
    OAApplicationModule am=pageContext.getApplicationModule(webBean);
    OAViewObject SrVO = (OAViewObject)tdsAM.findViewObject("OD_ServiceRequestMasterVO");
    OAViewObject SrDtlVO = (OAViewObject)tdsAM.findViewObject("OD_ServiceRequestDetailsVO");
    OAHeaderBean msgHdr = (OAHeaderBean)webBean.findChildRecursive("Inst2");

    if("NotUsedQty".equals(pageContext.getParameter(EVENT_PARAM)))
      handleEvent(pageContext, webBean, tdsAM,"NotUsedQty");
    if("ReceivedQty".equals(pageContext.getParameter(EVENT_PARAM)))
      handleEvent(pageContext, webBean, tdsAM,"ReceivedQty");
    if("NotUsedFlag".equals(pageContext.getParameter(EVENT_PARAM)))
      handleEvent(pageContext, webBean, tdsAM,"NotUsedFlag");
    if("ReceivedShipment".equals(pageContext.getParameter(EVENT_PARAM)))
      handleEvent(pageContext, webBean, tdsAM,"ReceivedShipment");
    if("Complete".equals(pageContext.getParameter(EVENT_PARAM)))
      handleEvent(pageContext, webBean, tdsAM,"Complete");

    if(pageContext.getParameter("SubmitBtn")!=null)
    {

//    OAViewObject.isDirty()
//    SrVO.is
    if (tdsAM.getTransaction().isDirty())
    {
      handleEvent(pageContext, webBean, tdsAM,"NotUsedQty");
      handleEvent(pageContext, webBean, tdsAM,"ReceivedQty");
      handleEvent(pageContext, webBean, tdsAM,"AccumulateTRQ");
      handleEvent(pageContext, webBean, tdsAM,"Submit");
//      OD_ServiceRequestAMImpl amObj=(OD_ServiceRequestAMImpl)tdsAM;
      tdsAM.invokeMethod("apply");
//      amObj.invokeMethod("apply");
    }
    else
    {
      pageContext.forwardImmediately("OA.jsp?OAFunc=OD_CSZ_SR_DB_FN&OASF=OD_CSZ_SR_DB_FN&OAHP=CSZ_SR_T2_AGENT_HOME_PAGE&OAPB=CSZ_SR_BRAND&addBreadCrumb=RP",
                                      null,
                                      OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                      null,
                                      null,
                                      true, // retain AM
                                      OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
    }

    }
  }

  public void handleEvent(OAPageContext pageContext, OAWebBean webBean, OAApplicationModule tdsAM,String eventName)
  {
    OD_ServiceRequestAMImpl amObj=(OD_ServiceRequestAMImpl)tdsAM;
    OAViewObject hdrVO = (OAViewObject)tdsAM.findViewObject("OD_ServiceRequestMasterVO");
    OD_ServiceRequestMasterVORowImpl hdrVORow=null;
    RowSetIterator hdrIter  = hdrVO.findRowSetIterator("hdrIter");
    OAViewObject dtlVO = (OAViewObject)tdsAM.findViewObject("OD_ServiceRequestDetailsVO");
    OD_ServiceRequestDetailsVORowImpl dtlVORow=null;
    OAViewObject recQtyVO = (OAViewObject)tdsAM.findViewObject("OD_ServiceRequestRcvQtyVO1");
    OD_ServiceRequestRcvQtyVORowImpl reqQtyVORow = null;
    RowSetIterator dtlter  = dtlVO.findRowSetIterator("dtlter");
    String hdtItemNo = null;
    String hdrReqNo = null;
    String dtlItemNo = null;
    String dtlReqNo = null;
    int totRecQty = 0;
    if(hdrIter!=null)
    {
      hdrIter.closeRowSetIterator();
    }
    if(dtlter!=null)
    {
      dtlter.closeRowSetIterator();
    }

    hdrIter=hdrVO.createRowSetIterator("hdrIter");
    dtlter=dtlVO.createRowSetIterator("dtlter");
    int fetchedRowCount=hdrVO.getRowCount();
    int dtlfetchedRowCount=dtlVO.getRowCount();
    if(fetchedRowCount>0)
    {
      hdrIter.setRangeStart(0);
      hdrIter.setRangeSize(fetchedRowCount);
      ArrayList exceptionList = new ArrayList();// code added: 18-Jul02012
      for (int count = 0; count < fetchedRowCount; count++)
      {
       hdrVORow=(OD_ServiceRequestMasterVORowImpl)hdrIter.getRowAtRangeIndex(count);
       hdtItemNo = hdrVORow.getItemNumber();
       hdrReqNo = hdrVORow.getRequestNumber();
       oracle.jbo.domain.Number qty = null;
       oracle.jbo.domain.Number excessQty = null;
       if(hdrVORow.getQuantity()!=null)
       qty = hdrVORow.getQuantity();
       else
       qty = new oracle.jbo.domain.Number(0);
//       if("ReceivedShipment".equals(eventName))
       if("Complete".equals(eventName)){
        if("Y".equals(hdrVORow.getSalesFlag())){//Attribute2())){
         if(hdrVORow.getExcessQuantity()==null && (Boolean.FALSE.equals(hdrVORow.getComplete()))){
//         hdrVORow.setAttribute2(null);
//         throw new OAException("XXCRM","OD_NOT_USED_QTY",null,OAException.INFORMATION,null);
//         pageContext.putDialogMessage(new OAException("XXCRM","OD_NOT_USED_QTY",null,OAException.INFORMATION,null));
         }
         if(!"Y".equals(hdrVORow.getExcessFlag()) && (Boolean.FALSE.equals(hdrVORow.getComplete()))){
//         hdrVORow.setAttribute2(null);
//         throw new OAException("XXCRM","OD_NOT_USED_FLG",null,OAException.INFORMATION,null);
         pageContext.putDialogMessage(new OAException("XXCRM","OD_NOT_USED_FLG",null,OAException.INFORMATION,null));
         }
         //Date: 25-JAN-2011  Code Added for Excess Quantity at Complete Flag.
         MessageToken[] tokens = { new MessageToken("ITEM_NUMBER", hdrVORow.getItemNumber()) };
         if(hdrVORow.getQuantity().intValue() > 1 && hdrVORow.getExcessQuantity() ==null && "Y".equals(hdrVORow.getSalesFlag()) ) // &&(!"Y".equals(srVORow.getExcessFlag())) )
         {
           hdrVORow.setNotUsedQty(Boolean.FALSE);
           if(hdrVORow.getExcessQuantity()==null && "Y".equals(hdrVORow.getSalesFlag()))
            pageContext.putDialogMessage(new OAException("XXCRM","EXCESS_QTY_NULL",tokens,OAException.INFORMATION,null));
         }

         /*
         hdrVORow.setComplete(Boolean.TRUE);
         if(hdrVORow.getQuantity().intValue() > 1 && hdrVORow.getExcessQuantity()==null)
         {
           hdrVORow.setNotUsedQty(Boolean.FALSE);
         }
         else if(hdrVORow.getQuantity().intValue() == 1)
         {
           hdrVORow.setExcessQuantity(new Number(1));
         }
          */
        }
        /*
         com.sun.java.util.collections.HashMap  completeParams = new com.sun.java.util.collections.HashMap(1);
         completeParams.put("EVENT","Complete");
         pageContext.forwardImmediatelyToCurrentPage(completeParams,true,null);
         */
       }
       // New Validation as per Document: 18-Jul-2012
      // Jay if("Submit".equals(eventName))

       if("Submit".equals(eventName))// && "N".equals(hdrVORow.getRecptFlag()))
       {
         if(!"Y".equals(hdrVORow.getSalesFlag()) || !"Y".equals(hdrVORow.getExcessFlag()) )
         {
         /*
         if(!"Y".equals(hdrVORow.getSalesFlag())){
           MessageToken[] tokens = { new MessageToken("ITEM_NUMBER", hdrVORow.getItemNumber()) };
           exceptionList.add(new OAException("XXCRM","OD_CHECK_COMPLETE_FLAG",tokens,OAException.ERROR,null));
         }
         else if(!"Y".equals(hdrVORow.getExcessFlag()))
         {
           MessageToken[] tokens = { new MessageToken("ITEM_NUMBER", hdrVORow.getItemNumber()) };
           exceptionList.add(new OAException("XXCRM","OD_CHECK_USED_FLAG",tokens,OAException.ERROR,null));
         }
         */

         if(!"Y".equals(hdrVORow.getSalesFlag()) &&("R".equals(hdrVORow.getReceivedShipmentFlag()))){//Added for Testing
           MessageToken[] tokens = { new MessageToken("ITEM_NUMBER", hdrVORow.getItemNumber()) };
           exceptionList.add(new OAException("XXCRM","OD_CHECK_NOTUSED_COMPLETE_FLAG",tokens,OAException.ERROR,null));
         }
         }

       }

       if("NotUsedFlag".equals(eventName)) //|| "Complete".equals(eventName) ||"ReceivedShipment".equals(eventName))
        {


         if("Y".equals(hdrVORow.getExcessFlag())){
           hdrVORow.setSalesFlag("Y");
          /*
           if(hdrVORow.getQuantity().intValue() > 1)
           {
             hdrVORow.setNotUsedQty(Boolean.FALSE);
           }
           if(hdrVORow.getQuantity().intValue() > 1 && hdrVORow.getExcessQuantity() ==null && "Y".equals(hdrVORow.getSalesFlag()))
           {
             hdrVORow.setNotUsedQty(Boolean.FALSE);
           }
          */
             if(hdrVORow.getQuantity().intValue() > 1 && hdrVORow.getExcessQuantity()==null)
             {
               hdrVORow.setNotUsedQty(Boolean.FALSE);
             }
             else if(hdrVORow.getQuantity().intValue() == 1)
             {
               hdrVORow.setExcessQuantity(new Number(1));
               hdrVORow.setNotUsedQty(Boolean.TRUE);
             }
         }
         if(!"Y".equals(hdrVORow.getExcessFlag())){
             hdrVORow.setNotUsedQty(Boolean.TRUE);
//             if(hdrVORow.getQuantity().intValue() == 1)
             hdrVORow.setExcessQuantity(null);
         }
        }
       if("NotUsedQty".equals(eventName)){
       if(hdrVORow.getExcessQuantity()!=null){
       excessQty = hdrVORow.getExcessQuantity();
//       if(excessQty.doubleValue()> qty.doubleValue())
//       throw new OAException("XXCRM","OD_EXCESS_QTY_GTR_QTY",null,OAException.ERROR,null);
       }
      }

       if("ReceivedQty".equals(eventName)){
       recQtyVO.setWhereClause("SEGMENT1='"+hdrReqNo+"' AND ATTRIBUTE2 ='"+hdtItemNo+"'");
       recQtyVO.executeQuery();
       reqQtyVORow = (OD_ServiceRequestRcvQtyVORowImpl)recQtyVO.first();

       Number recQty = null;
       Number qtY = null;
       Number qtyRec = null;
       Number qtyTDS = null;
       if(reqQtyVORow !=null){

         if(hdrVORow.getReceivedQuantity()!=null)
           recQty = new Number(hdrVORow.getReceivedQuantity());//number
         else
           recQty = new Number(0);
         if(hdrVORow.getQuantity()!=null)
           qtyTDS = new Number(hdrVORow.getQuantity());
         if(reqQtyVORow.getQuantity()!=null)
           qtY= reqQtyVORow.getQuantity();
         else
           qtY = new Number(0);
         if(reqQtyVORow.getQuantityReceived()!=null)
           qtyRec = reqQtyVORow.getQuantityReceived();
         else
           qtyRec = new Number(0);
         if(hdrVORow.getReceivedQuantity()!=null){// && !"R".equals(hdrVORow.getReceivedShipmentFlag())){
         // To Check received qty is less than equal to ordered quantity.
         // Modified Date: 03-JAN-2012
         int totreqQty = 0;
         if(hdrVORow.getTotReceivedQty() != null)
         totreqQty = hdrVORow.getTotReceivedQty().intValue();
//         if(recQty.intValue()+totreqQty  > (qtY.intValue()-qtyRec.intValue()) ) {
//         if(recQty.intValue()  > (qtY.intValue()-qtyRec.intValue()) ) {

//         if(totreqQty < qtyTDS.intValue()){
//         if(hdrVORow.getTotReceivedQty() ==  null){
         if(recQty.intValue()  > (qtyTDS.intValue()) ) {
//         if(recQty.intValue()  > (qtY.intValue()-qtyRec.intValue()) ) {
         //System.out.println("##### Before Error 1....");
         throw new OAException("XXCRM","OD_QTY_GTR_INV_QTY",null,OAException.ERROR,null);
         }
//         }

//         if("Y".equals(hdrVORow.getReceivedShipmentFlag())){
//         if(qtyTDS.intValue() !=recQty.intValue() ){
         // V1.1, Added below condition to check for (recQty.intValue()+totreqQty> (qtyTDS.intValue())
		 // only in case of Partial receipt

		 if (qtyTDS.intValue() > totreqQty ) // V1.1, added
		 {
            if(recQty.intValue()+totreqQty  > (qtyTDS.intValue()) )
            {//System.out.println("##### Before Error 2....");
               throw new OAException("XXCRM","OD_QTY_GTR_INV_QTY",null,OAException.ERROR,null);
            }
     }  // V1.1, Added
//         }
//         }

         }
       }
       else {//throw new OAException("Purchase Order:"+hdrReqNo+"does not exists.",OAException.ERROR);
       MessageToken[] tokens = { new MessageToken("SR_NUMBER", hdrReqNo) };
       throw new OAException("XXCRM","OD_SR_NUMBER_NULL",tokens,OAException.ERROR,null);
       }

      }
      if("AccumulateTRQ".equals(eventName)){
        if(hdrVORow.getReceivedQuantity()!= null){
        if(hdrVORow.getTotReceivedQty() !=  null){
        if("Y".equals(hdrVORow.getReceivedShipmentFlag())){
//        System.out.println("##### AccumulateTRQ 2 getQuantity="+hdrVORow.getQuantity().intValue()+" getReceivedQuantity()="+hdrVORow.getReceivedQuantity().intValue()+" getTotReceivedQty="+hdrVORow.getTotReceivedQty().intValue());
//        if(hdrVORow.getQuantity().intValue() < hdrVORow.getReceivedQuantity().intValue() ){//commented for testing
//        if(hdrVORow.getReceivedQuantity().intValue() < hdrVORow.getQuantity().intValue()){
        totRecQty = Integer.parseInt(hdrVORow.getTotReceivedQty().toString()) + Integer.parseInt(hdrVORow.getReceivedQuantity().toString());
        hdrVORow.setTotReceivedQty(new Number(totRecQty));
//        }
        }
        }
        else{
        hdrVORow.setTotReceivedQty(hdrVORow.getReceivedQuantity());
        }
        }
        totRecQty =0;
      }
        }// End of For Loop

        hdrIter.closeRowSetIterator();
        OAException.raiseBundledOAException(exceptionList);//code added 18-Jul-2012
       if("Submit".equals(eventName))
       {
         com.sun.java.util.collections.HashMap  submitParams = new com.sun.java.util.collections.HashMap(1);
         submitParams.put("EVENT","Submit");
         pageContext.forwardImmediatelyToCurrentPage(submitParams,true,null);
       }
    }hdrIter.closeRowSetIterator();

  }

}
