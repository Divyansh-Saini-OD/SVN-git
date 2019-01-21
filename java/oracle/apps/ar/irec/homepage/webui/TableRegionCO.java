package oracle.apps.ar.irec.homepage.webui;


import oracle.apps.ar.irec.homepage.server.TemplateLocaleVOImpl;
import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.ar.irec.framework.webui.IROAControllerImpl;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAStaticStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.jdbc.OracleCallableStatement;
import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.OAApplicationModule;
import java.io.Serializable;

import oracle.cabo.ui.UIConstants;
import oracle.apps.fnd.framework.webui.beans.layout.OAHideShowHeaderBean ;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean ;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.table.OASortableHeaderBean;
import oracle.apps.fnd.framework.webui.beans.table.OAColumnBean;
import oracle.apps.ar.irec.homepage.server.PageAMImpl;
import oracle.apps.fnd.framework.webui.OAPartialPageRenderUtils;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean ; 
import oracle.apps.jtf.base.Logger;


/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1329
 -- Script Location: $XXCOMN_TOP/java/oracle/apps/ar/irec/homepage/webui
 -- Description: Considered R12 code and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 3-Aug-2016   1.0        Retrofitted for R12.2.5 Upgrade.
---------------------------------------------------------------------------*/


/*===========================================================================+
 |      Copyright (c) 2000, 2014 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 |       01-Jun  sjamall       Created. bugfix 1788881 : changing naming of  |
 |                             controller files to reflect change in layout  |
 |                             below this history you will find the history  |
 |                             of the ColumnOneCO.java file that this file   |
 |                             was copied from at the time of this message   |
 |  HISTORY OF ColumnOneCO.java                                              |                   |
 |       14-Aug-00  sjamall       Created.                                   |
 |       16-Mar-01  sjamall +  aizadpan  Comments added;                     |
 |       17-Jul-01  sjamall    bugfix 1881410                                |
 |       16-Nov-04   rsinthre  Bug # 4003517 - Support Personalization on    |
 |                             Home Page in all regions                      |
 |       05-Jan-05  rsinthre   Bug # 1922284 - Dispute Status region title   |
 |                             incorrect  
 |       12-Dec-07 avepati Bug 6622674 - JAVA CODE CHANGES FOR JDBC 11G ON MT|
 |       10-Jan-2010 nkanchan  bug 10432451 - ireceivables customer statement is not showing transaction details for all customer|
 |       18-Feb-2011 rsinthre  Bug 11769006 - ireceivable dispute status     |
 |                                       section should show only open items  |
 |      13-Jan-2012  parln  Bug 13557401- create data template for Customer   |
 |                         statement                                          |
 |       20-Feb-14  rsurimen   Bug 18260226 - Session Language Display in Locale Field |
 +===========================================================================*/

/**
 * this class shows the following hierarchy in the home page.
 * the hierarchy of Column One in Home Page:
		ARIHOMEPAGECOLUMNONE:Flow Layout:ColumnOneCO
			Discount Alerts
			Dispute Status
 * @author 	Mohammad Shoaib Jamall
 */
 
public class TableRegionCO extends IROAControllerImpl
{

  public static final String RCS_ID="$Header: TableRegionCO.java 120.11.12020000.3 2014/02/21 07:48:09 rsurimen ship $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "oracle.apps.ar.irec.homepage.webui");

  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    
	 //Added as part of R12 upgrade retrofit
     setXDOParameters(pageContext, webBean);

	 //Commented as part of R12.2.5 upgrade retrofit  
     /*	
    OAPageLayoutBean pageBean = pageContext.getPageLayoutBean() ;
    OAHideShowHeaderBean downloadStatementHideShowBean = (OAHideShowHeaderBean) pageBean.findChildRecursive("AriStatementDownloadRN");    

    if(downloadStatementHideShowBean.isDisclosed(pageContext)) 
    initializeDownloadStmt(pageContext,webBean);  
    */
  }

  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
      pageContext.writeDiagnostics(this, "start processFormRequest", OAFwkConstants.PROCEDURE);
    super.processFormRequest(pageContext, webBean);
    
    //Bug 8221702
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    String pageEvent = pageContext.getParameter("event") ;
    String templateCode = pageContext.getParameter("TemplateCode");
    String customerId =  getActiveCustomerId(pageContext);  
    if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
      pageContext.writeDiagnostics(this, "pageEvent "+pageEvent+" templateCode "+templateCode+" customerId "+customerId, OAFwkConstants.STATEMENT); 
    String sLang = null;
    if("TemplateChange".equals(pageEvent))
    {
    templateCode = pageContext.getParameter("TemplateCode");
   // Bug # 18260226 - Session Language Display in Locale Field
    sLang=pageContext.getCurrentLanguage();
     ((TemplateLocaleVOImpl)am.findViewObject("TemplateLocaleVO")).initQuery(sLang,templateCode);     
    }
    if("downloadXML".equals(pageEvent))
    {
      if(customerId != null && !"-1".equals(customerId) && !"".equals(customerId))
        downloadXMLFile(pageContext, webBean, "AR", templateCode);
      else
       throw new OAException("AR","ARI_SELECT_CUST_FOR_STMT");      
    }
    
    // Modified for bug # 11769006
    if("showAllDisp".equals(pageEvent))
      showDisputes(pageContext, webBean);
          
    String event = pageContext.getParameter("StatementDownload");
    
    //bug 10432451 - nkanchan
    if (event != null) {
     if(customerId != null && !"-1".equals(customerId) && !"".equals(customerId))
      exportXDOData(pageContext, webBean, "AR", templateCode);
     else
      throw new OAException("AR","ARI_SELECT_CUST_FOR_STMT");
    }
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
      pageContext.writeDiagnostics(this, "end processFormRequest", OAFwkConstants.PROCEDURE);
  }


    public void processFormData(OAPageContext pageContext, OAWebBean webBean)
    {
      if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "start processFormData", OAFwkConstants.PROCEDURE);
      super.processFormData(pageContext, webBean);
      OAPageLayoutBean pageBean = pageContext.getPageLayoutBean() ;      
      String eventName = pageContext.getParameter(UIConstants.EVENT_PARAM);
      String sourceName = pageContext.getParameter(UIConstants.SOURCE_PARAM);
      
      if (UIConstants.SHOW_EVENT.equals(eventName) && "AriStatementDownloadRN".equals(sourceName))
      {
        initializeDownloadStmt(pageContext,webBean);    
      }

      if ( (UIConstants.SHOW_EVENT.equals(eventName) && "DiscountAlertsHideShowReg".equals(sourceName))
          || ( "discFilterChanged".equals(eventName) )   ){
          initializeDiscountsQuery(pageContext,webBean) ;
          showDiscounts(pageContext, webBean);
      }

      //bug 11769006
      OAHideShowHeaderBean dispHideShowBean = (OAHideShowHeaderBean) pageBean.findChildRecursive("DisputeStatusHideShowReg");
      if( (UIConstants.SHOW_EVENT.equals(eventName) && "DisputeStatusHideShowReg".equals(sourceName))
              || (dispHideShowBean.isDisclosed(pageContext) && !"showAllDisp".equals(eventName)))
      {    
        showDisputes(pageContext, webBean);
        setDisputeAmountAndLabel(pageContext, webBean);
      }                
        
      String selectedCurrencyCode = pageContext.getParameter("AriCurrency");
      String currentCurrencyCode = getActiveCurrencyCode(pageContext);
      if ("currCodeChanged".equals(eventName))
      {
        //add the regions whose items need to be refreshed as Partial Targets
        //using the API in the OAPartialPageRenderUtils
         OAPartialPageRenderUtils.addPartialTargets(pageContext,"amtCurrCode,Aridisputestatus,Aridiscountalerts");        
         if (!(currentCurrencyCode.equals(selectedCurrencyCode)))
        {
          if (!(isNullString(selectedCurrencyCode)))
          {
            // this method is being used to set Active Currency Code.
            getActiveCurrencyCode (pageContext, selectedCurrencyCode);
            setDisputeAmountAndLabel(pageContext, webBean);      
          }
        }
      }
      
      if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "end processFormData", OAFwkConstants.PROCEDURE);
    }

   protected void showDiscounts(OAPageContext pageContext, OAWebBean webBean)
  {
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
      pageContext.writeDiagnostics(this, "start showDiscounts", OAFwkConstants.PROCEDURE);

    String [] sResults = getDiscountCustomization(pageContext, webBean);
    String sRenderRegion = "Y";
    String sCustomOutput = "";
    sRenderRegion        = (sResults[0]==null?"Y":sResults[0]);
    sCustomOutput        = (sResults[1]==null?"":sResults[1]);
    if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
    {
      pageContext.writeDiagnostics(this, "sRenderRegion = " + sRenderRegion, OAFwkConstants.STATEMENT);
      pageContext.writeDiagnostics(this, "sCustomOutput = " + sCustomOutput, OAFwkConstants.STATEMENT);
    }
    //Bug 4238403 - Removed getRowCount and using appropriate methods
    OAViewObject discAlertsVO= (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("DiscountAlertsVO");
    discAlertsVO.reset();
    boolean discountAlertExists = discAlertsVO.hasNext();
    
    if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
        pageContext.writeDiagnostics(this, "discountAlertExists = " + discountAlertExists, OAFwkConstants.STATEMENT);

    OAStaticStyledTextBean customizedDiscountMessage = (OAStaticStyledTextBean)webBean.findIndexedChildRecursive("AriCustomizedDiscountMessage");

    //Bug # 1927110 - Render the regions based on the SPEL binding,
    //depending on whether discounts exist or not.
    OAViewObject vo = (OAViewObject)((pageContext.getApplicationModule(webBean)).findViewObject("DiscountAlertsPVO"));
    OARow row = (OARow)vo.first();

    //A new row has to be introduced.
    if (row == null)
    {
      vo.insertRow(vo.createRow());
      // Set the primary key value for this single-row VO.
      row = (OARow)vo.first();
      row.setAttribute("RowKey", new Number(1));
    }

    if (sRenderRegion.equals("Y")) {

      if (discountAlertExists) {

        //Render the Discounts table true,and hide the "No Discounts" message region
        row.setAttribute("DT_DISCOUNTS_RENDER", Boolean.TRUE);
        row.setAttribute("DT_NODISCOUNTS_RENDER", Boolean.FALSE);
        
        customizedDiscountMessage.setRendered(false);

      } else {
        //Render the "No Discounts" message region true,and hide the Discounts table region
        row.setAttribute("DT_DISCOUNTS_RENDER", Boolean.FALSE);
        row.setAttribute("DT_NODISCOUNTS_RENDER", Boolean.TRUE);
        
        customizedDiscountMessage.setRendered(false);
      }
    } else {
        //Hide both the "No Discounts" message and Discounts table regions
        row.setAttribute("DT_DISCOUNTS_RENDER", Boolean.FALSE);
        row.setAttribute("DT_NODISCOUNTS_RENDER", Boolean.FALSE);
        
        customizedDiscountMessage.setText(sCustomOutput);
        customizedDiscountMessage.setRendered(true);

    }
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "end showDiscounts", OAFwkConstants.PROCEDURE);
  }

  protected String [] getDiscountCustomization(OAPageContext pageContext, OAWebBean webBean)
  {
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "start getCustomization", OAFwkConstants.PROCEDURE);

    OAApplicationModuleImpl rootAM = (OAApplicationModuleImpl) pageContext.getRootApplicationModule();
    OADBTransaction tx = (OADBTransaction) rootAM.getDBTransaction();

    String sql = "BEGIN ari_config.get_discount_customization(:1,:2,:3,:4,:5); END;";

    String sCustomerId        = getActiveCustomerId(pageContext);
    String sCustomerSiteUseId = getActiveCustomerUseId(pageContext);
    String sLanguage          = tx.getCurrentLanguage();
    String sRenderRegion      = "";
    String sCustomOutput      = "";

    // Create the callable statement
    // Bug Fix - 1887440
    //     Perf Team - Use OracleCallableStatement
    OracleCallableStatement callStmt = (OracleCallableStatement)tx.createCallableStatement(sql, 1);

    try
    {
      callStmt.setString(1,sCustomerId);
      callStmt.setString(2,sCustomerSiteUseId);
      callStmt.setString(3, sLanguage);

      // Bug Fix - 1887440
      //     Perf Team - Use OracleCallableStatement
      callStmt.registerOutParameter(4, java.sql.Types.VARCHAR, 0, 2);
      callStmt.registerOutParameter(5, java.sql.Types.VARCHAR, 0, 2000 );

      callStmt.execute();

      //Get in-out and out variables (x == null ? "":x)
      sRenderRegion = (callStmt.getString(4) == null ? "":callStmt.getString(4));
      sCustomOutput = (callStmt.getString(5) == null ? "":callStmt.getString(5));

    }
    catch(Exception e)
    {
      try
      {
        if(Logger.isEnabled(Logger.EXCEPTION))
          Logger.out(e, OAFwkConstants.EXCEPTION, Class.forName("oracle.apps.ar.irec.homepage.webui.DiscountAlertsCO"));
      }
      catch(ClassNotFoundException cnfE){}
      if (pageContext.isLoggingEnabled(OAFwkConstants.EXCEPTION))
      {
        pageContext.writeDiagnostics(this, "sRenderRegion = " + sRenderRegion, OAFwkConstants.EXCEPTION);
        pageContext.writeDiagnostics(this, "sCustomOutput = " + sCustomOutput, OAFwkConstants.EXCEPTION);
      }
      throw OAException.wrapperException(e);
    }
    finally
    {
      try
      {
        callStmt.close();
      }
      catch(Exception e)
      {
        throw OAException.wrapperException(e);
      }
    }

    String [] sResult = new String [] { sRenderRegion,sCustomOutput};
    if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "end getCustomization", OAFwkConstants.PROCEDURE);
    return sResult;
  }

 


  protected void initializeDiscountsQuery(OAPageContext pageContext, OAWebBean webBean)
  {
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    String currCode = null;
    String custId = null;
    String custUseId = null;
    String filterCode = null ;

    try
    {
      getActiveCurrencyCode(pageContext, pageContext.getParameter( CURRENCY_CODE_KEY ));
      currCode = getActiveCurrencyCode(pageContext);
      custId = getActiveCustomerId(pageContext);
      custUseId = getActiveCustomerUseId(pageContext);
    }
    catch(OAException e)
    {
      OADialogPage dialogPage = new OADialogPage();
      dialogPage.setDescriptionMessage(new OAException("AR", "ARI_ACCESS_DENIED"));
      pageContext.redirectToDialogPage(dialogPage);
    }

    filterCode = (String) pageContext.getParameter("DiscountAlertFilter");
    if(filterCode==null)
    {
      OAMessageChoiceBean discFilter = (OAMessageChoiceBean) webBean.findIndexedChildRecursive("DiscountAlertFilter");
      filterCode = (String) discFilter.getValue(pageContext);
    }

    Serializable [] params = { currCode,
                                custId,
                                custUseId,
                                filterCode};
                                
    am.invokeMethod("initDiscountAlertsQuery", params);
   
  }


    protected void showDisputes(OAPageContext pageContext, OAWebBean webBean)
    {
      if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
        pageContext.writeDiagnostics(this, "start showDisputes", OAFwkConstants.PROCEDURE);

      String [] sResults = getCustomization(pageContext, webBean);
      String sRenderRegion = "Y";
      String sCustomOutput = "";
      sRenderRegion        = (sResults[0]==null?"Y":sResults[0]);
      sCustomOutput        = (sResults[1]==null?"":sResults[1]);
      if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
      {
        pageContext.writeDiagnostics(this, "sRenderRegion = " + sRenderRegion, OAFwkConstants.STATEMENT);
        pageContext.writeDiagnostics(this, "sCustomOutput = " + sCustomOutput, OAFwkConstants.STATEMENT);
      }
      
      String showAllDisputes = pageContext.getParameter("ShowAllDisputes");
     
      OAStaticStyledTextBean customizedDisputeMessage = (OAStaticStyledTextBean)webBean.findIndexedChildRecursive("AriCustomizedDisputeMessage");

      //Bug # 1927110 - Render the regions based on the SPEL binding,
      //depending on whether disputes exist or not.
      OAViewObject vo = (OAViewObject)((pageContext.getApplicationModule(webBean)).findViewObject("DisputeStatusPVO"));
      OARow row = (OARow)vo.first();

      //A new row has to be introduced.
      if (row == null)
      {
        vo.insertRow(vo.createRow());
        // Set the primary key value for this single-row VO.
        row = (OARow)vo.first();
        row.setAttribute("RowKey", new Number(1));
      }

      if (sRenderRegion.equals("Y")) {
        /* Bug : 1922284 */
        String sCustomerId        = getActiveCustomerId(pageContext);
        String sCustomerSiteUseId = getActiveCustomerUseId(pageContext);
        String sCurrencyCode      =  (String)getActiveCurrencyCode(pageContext);
        Serializable [] params = {sCustomerId, sCustomerSiteUseId, sCurrencyCode, showAllDisputes};
      ((PageAMImpl)pageContext.getApplicationModule(webBean)).invokeMethod("executeCRDisputeStatusVO", params);
    //      PageAMImpl pageAM         = (PageAMImpl)pageContext.getApplicationModule(webBean);
    //      pageAM.executeCRDisputeStatusVO(sCustomerId, sCustomerSiteUseId, sCurrencyCode);
        //Bug 4238403 - Removed getRowCount and using appropriate methods
        OAViewObject disputeStatusVO = (OAViewObject)pageContext.getApplicationModule(webBean).findViewObject("CRDisputeStatusVO");
        disputeStatusVO.reset();
        boolean disputeRequestExists = disputeStatusVO.hasNext();
        if (pageContext.isLoggingEnabled(OAFwkConstants.STATEMENT))
            pageContext.writeDiagnostics(this, "disputeRequestExists = " + disputeRequestExists, OAFwkConstants.STATEMENT);

        if (disputeRequestExists) 
        {
          //Render the Disputes table true,and hide the "No Disputes" message region
          row.setAttribute("DS_DISPUTES_RENDER", Boolean.TRUE);
          row.setAttribute("DS_NODISPUTES_RENDER", Boolean.FALSE);        
          customizedDisputeMessage.setRendered(false);

        } else {
          //Render the "No Disputes" message region true,and hide the Disputes table region        row.setAttribute("DS_DISPUTES_RENDER", Boolean.FALSE);
          row.setAttribute("DS_DISPUTES_RENDER", Boolean.FALSE);
          row.setAttribute("DS_NODISPUTES_RENDER", Boolean.TRUE); 
          customizedDisputeMessage.setRendered(false);
        }
      } else {
          //Hide both the "No Disputes" message and Disputes table regions
          row.setAttribute("DS_DISPUTES_RENDER", Boolean.FALSE);
          row.setAttribute("DS_NODISPUTES_RENDER", Boolean.FALSE); 
          customizedDisputeMessage.setText(sCustomOutput);
          customizedDisputeMessage.setRendered(true);
      }
      if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
         pageContext.writeDiagnostics(this, "end showDisputes", OAFwkConstants.PROCEDURE);
    }

      protected String [] getCustomization(OAPageContext pageContext, OAWebBean webBean) 
      {
        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
            pageContext.writeDiagnostics(this, "start getCustomization", OAFwkConstants.PROCEDURE);
            
        OAApplicationModuleImpl rootAM = (OAApplicationModuleImpl) pageContext.getRootApplicationModule();
        OADBTransaction tx = (OADBTransaction) rootAM.getDBTransaction();

        String sql = "BEGIN ari_config.get_dispute_customization(:1,:2,:3,:4,:5); END;";

        String sCustomerId        = getActiveCustomerId(pageContext);
        String sCustomerSiteUseId = getActiveCustomerUseId(pageContext);
        String sLanguage          = tx.getCurrentLanguage();
        String sRenderRegion      = "";
        String sCustomOutput      = "";

        // Create the callable statement
        OracleCallableStatement callStmt = (OracleCallableStatement)tx.createCallableStatement(sql, 1);

        try
        {
          callStmt.setString(1,sCustomerId);
          callStmt.setString(2,sCustomerSiteUseId);
          callStmt.setString(3, sLanguage);      
          callStmt.registerOutParameter(4, java.sql.Types.VARCHAR, 0, 2);
          callStmt.registerOutParameter(5, java.sql.Types.VARCHAR, 0, 2000 );
          callStmt.execute();

          //Get in-out and out variables (x == null ? "":x)
          sRenderRegion = (callStmt.getString(4) == null ? "":callStmt.getString(4));
          sCustomOutput = (callStmt.getString(5) == null ? "":callStmt.getString(5));

        } catch(Exception e) {
          try
          {
            if(Logger.isEnabled(Logger.EXCEPTION))
              Logger.out(e, OAFwkConstants.EXCEPTION, Class.forName("oracle.apps.ar.irec.homepage.webui.DisputeStatusCO"));
          }
          catch(ClassNotFoundException cnfE){}
          if (pageContext.isLoggingEnabled(OAFwkConstants.EXCEPTION))
          {
            pageContext.writeDiagnostics(this, "sRenderRegion = " + sRenderRegion, OAFwkConstants.EXCEPTION);
            pageContext.writeDiagnostics(this, "sCustomOutput = " + sCustomOutput, OAFwkConstants.EXCEPTION);
          }
          throw OAException.wrapperException(e);
        } finally {
          try {
            callStmt.close();
          } catch(Exception e) {
            throw OAException.wrapperException(e);
          }
        }
        String [] sResult = new String [] { sRenderRegion,sCustomOutput};
        if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
          pageContext.writeDiagnostics(this, "end getCustomization", OAFwkConstants.PROCEDURE);
        return sResult;
      }
      protected void setDisputeAmountAndLabel(OAPageContext pageContext, OAWebBean webBean)
     {
      if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(this, "start setDisputeAmountAndLabel", OAFwkConstants.PROCEDURE);
      // Get the Header bean of the Amount Column
      OASortableHeaderBean amtHeader = (OASortableHeaderBean)webBean.findChildRecursive("AridisputeamountHeader");

      // get bean for Dispute Amount Column
      OAMessageStyledTextBean disputeAmount =
        (OAMessageStyledTextBean)webBean.findIndexedChildRecursive("Aridisputeamount");
      String sCurrencyCode = (String)getActiveCurrencyCode(pageContext);
      OAColumnBean disputeAmountCol = (OAColumnBean) webBean.findIndexedChildRecursive("Aridisputeamountcol");
      if(null != disputeAmountCol)
        disputeAmountCol.setAttributeValue(CURRENCY_CODE , sCurrencyCode); 
      
      // modify label of Amount column to be like 'Dispute Amount (USD)'.
      // label is obtained from message dictionary.
      MessageToken [] tokens =
        { new MessageToken ("CURRENCY_CODE", getActiveCurrencyCodeMeaning(pageContext))};
      String amountHeader =
        pageContext.getMessage("AR", "ARIDISPUTEAMOUNTWITHCURRENCY", tokens);
      if(null != amtHeader)
        amtHeader.setPrompt(amountHeader);
      if(null != disputeAmount)
      {
        disputeAmount.setPrompt(amountHeader);
        disputeAmount.setCurrencyCode(sCurrencyCode);
      }
      if (pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
              pageContext.writeDiagnostics(this, "end setDisputeAmountAndLabel", OAFwkConstants.PROCEDURE);
    }
    
  protected void initializeDownloadStmt(OAPageContext pageContext, OAWebBean webBean)
  {
    if(pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
      pageContext.writeDiagnostics(this, "start initializeDownloadStmt", OAFwkConstants.PROCEDURE);
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    String currCode = null;
    String custId = null;
    String custUseId = null;

    try
    {
      getActiveCurrencyCode(pageContext, pageContext.getParameter( CURRENCY_CODE_KEY ));
      currCode = getActiveCurrencyCode(pageContext);
      custId = getActiveCustomerId(pageContext);
      custUseId = getActiveCustomerUseId(pageContext);
    }
    catch(OAException e)
    {
      OADialogPage dialogPage = new OADialogPage();
      dialogPage.setDescriptionMessage(new OAException("AR", "ARI_ACCESS_DENIED"));
      pageContext.redirectToDialogPage(dialogPage);
    }

    Serializable [] params = { currCode,
                                custId,
                                custUseId };
     //Bug #13557401 removing this call to VO as its taken care through data template.                            
    //OAViewObject custStmtVO = (OAViewObject)am.findViewObject("CustomerStatementVO");
    //custStmtVO.invokeMethod("initQuery", params);
    
    if(pageContext.isLoggingEnabled(OAFwkConstants.PROCEDURE))
      pageContext.writeDiagnostics(this, "end initializeDownloadStmt", OAFwkConstants.PROCEDURE);
   
  }
  
  
    //Added as part of R12 upgrade retrofit

    public void setXDOParameters(OAPageContext oapagecontext, 
                                 OAWebBean oawebbean) {
        try {
            Class class1 = 
                Class.forName("oracle.apps.xdo.oa.common.DocumentHelper");
            class1.getField("DATA_SOURCE_TYPE_BLOB");
            oapagecontext.putParameter("p_DataSource", "BlobDomain");
            oapagecontext.putParameter("p_DataSourceCode", "ARI_CUST_STMT");
            oapagecontext.putParameter("p_DataSourceAppsShortName", "AR");
            oapagecontext.putParameter("p_XDORegionHeight", "25%");
            if (oapagecontext.getCurrentLanguage() != null && 
                !"-1".equals(oapagecontext.getCurrentLanguage()))
                oapagecontext.putTransientSessionValue("Language", 
                                                       oapagecontext.getCurrentLanguage());
            OASubmitButtonBean oasubmitbuttonbean = 
                (OASubmitButtonBean)oapagecontext.getPageLayoutBean().findChildRecursive("Go");
            if (oasubmitbuttonbean != null)
                oasubmitbuttonbean.setRendered(false);
            OASubmitButtonBean oasubmitbuttonbean1 = 
                (OASubmitButtonBean)oapagecontext.getPageLayoutBean().findChildRecursive("Export");
            if (oasubmitbuttonbean1 != null) {
                oasubmitbuttonbean1.setRendered(true);
                oasubmitbuttonbean1.setText("Download");
                return;
            }
        } catch (Exception exception) {
            throw OAException.wrapperException(exception);
        }
    }
  
}

