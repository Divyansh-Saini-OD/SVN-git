package od.tdmatch.view.managedBeans;

import java.io.Serializable;

import java.math.BigDecimal;

import java.util.HashMap;

import javax.el.ELContext;
import javax.el.ExpressionFactory;
import javax.el.ValueExpression;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;
import javax.faces.event.ActionEvent;
import javax.faces.event.ValueChangeEvent;

import od.tdmatch.view.utils.ADFUtils;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;
import oracle.adf.model.binding.DCIteratorBinding;
import oracle.adf.share.ADFContext;
import oracle.adf.view.rich.component.rich.RichPopup;
import oracle.adf.view.rich.component.rich.input.RichSelectBooleanCheckbox;
import oracle.adf.view.rich.component.rich.input.RichSelectOneChoice;
import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.OperationBinding;

import oracle.jbo.Key;
import oracle.jbo.Row;
import oracle.jbo.ViewObject;

import org.apache.myfaces.trinidad.event.SelectionEvent;
import org.apache.myfaces.trinidad.render.ExtendedRenderKitService;
import org.apache.myfaces.trinidad.util.Service;

public class InvoiceDetailsBean implements Serializable{
    @SuppressWarnings("compatibility:3115188679228246896")
    private static final long serialVersionUID = 1L;
    private RichSelectOneChoice qtyReason;
    private RichSelectOneChoice priceReason;
    private RichSelectBooleanCheckbox releaseholdSelect;
    private RichSelectBooleanCheckbox chargebackSelect;
    private RichPopup popup;
    private RichPopup deleteInvoicePopup;


    public InvoiceDetailsBean() {
        super();
    }
    Boolean queryInv=Boolean.FALSE;
    Boolean queryPO=Boolean.FALSE;
    boolean queryAllInv=Boolean.FALSE;
    boolean queryAllPO=Boolean.FALSE;
    String init=null;
    BigDecimal invAmount=new BigDecimal(0);
    BigDecimal amount=new BigDecimal(0);
    BigDecimal reasonCode=new BigDecimal(0);
    BigDecimal linevariance=new BigDecimal(0);
    Boolean selectAll=Boolean.FALSE;
    public String invoiceDetails(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initInvoiceDetails");
        
       String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
        System.out.println("G.S AdfFacesContext.getCurrentInstance().getPageFlowScope().get(\"invoiceNo\").toString() "+AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo"));
              operation.getParamsMap().put("invoiceNum", invoiceNo);
              String result=(String)operation.execute();
        FacesMessage fm=new FacesMessage(result);
        fm.setSeverity(FacesMessage.SEVERITY_ERROR);
        FacesContext context=FacesContext.getCurrentInstance();
        if(result!=null && result.contains("Invoice")){
        context.addMessage(null, fm);
        AdfFacesContext.getCurrentInstance().getPageFlowScope().put("erroMessage", result);
                       
        return "Step5";
        }
        ADFContext.getCurrent().getRequestScope().put("refreshNeeded", Boolean.TRUE);
        return "Step4";
    }

    public void queryAllInvoice(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        if(valueChangeEvent.getNewValue()!=null){
            
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("queryAllInvoice");
             
           String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
                  operation.getParamsMap().put("queryAllInvoice", valueChangeEvent.getNewValue().toString());
            operation.getParamsMap().put("queryAllPO", queryPO.toString());
                  operation.execute();
        }
    }

    public void queryUnmatchPO(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        if(valueChangeEvent.getNewValue()!=null){
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("queryAllInvoice");
            
           operation.getParamsMap().put("queryAllInvoice", queryInv.toString());
           operation.getParamsMap().put("queryAllPO", valueChangeEvent.getNewValue().toString());
                  operation.execute();

        }
    }

    public void setQueryInv(Boolean queryInv) {
        this.queryInv = queryInv;
    }

    public Boolean getQueryInv() {
        return queryInv;
    }

    public void setQueryPO(Boolean queryPO) {
        this.queryPO = queryPO;
    }

    public Boolean getQueryPO() {
        return queryPO;
    }

    public void setQueryAllInv(boolean queryAllInv) {
        this.queryAllInv = queryAllInv;
    }

    public boolean isQueryAllInv() {
        return queryAllInv;
    }

    public void setQueryAllPO(boolean queryAllPO) {
        this.queryAllPO = queryAllPO;
    }

    public boolean isQueryAllPO() {
        return queryAllPO;
    }

    public void invoiceDetail(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("queryAllInvoice");
       
        String invoiceNo=(String)AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo");
              operation.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operation.getParamsMap().put("queryAllPO", queryPO.toString());
              operation.execute();

    }

    public void updateAction(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindingsvalidate = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operationsaveinvoice = bindings.getOperationBinding("saveInvoiceDetails");
         operationsaveinvoice.execute();
        OperationBinding operationinvoicetot = bindings.getOperationBinding("getInvoiceTot");
         invAmount=(BigDecimal)operationinvoicetot.execute();
          OperationBinding operationreasontot = bindings.getOperationBinding("getInvoiceReasonTot");
         reasonCode=(BigDecimal)operationreasontot.execute();

       
         if(invAmount!=null &&reasonCode!=null)
         amount=invAmount.add(reasonCode);
        BigDecimal invoiceamount=new BigDecimal(0);
        OperationBinding operationinvoiceamount = bindings.getOperationBinding("getInvoiceAmount");
         invoiceamount=(BigDecimal)operationinvoiceamount.execute();
         double amountdifference=0.0;
         if(amount!=null && invoiceamount!=null){
             amountdifference=invoiceamount.doubleValue()-amount.doubleValue();
             linevariance=new BigDecimal(amountdifference);
         }
         FacesMessage fm=new FacesMessage("Your Changes have been saved successfully.");
        fm.setSeverity(FacesMessage.SEVERITY_INFO);
        FacesContext context=FacesContext.getCurrentInstance();
        context.addMessage(null, fm);
        OperationBinding operationqueryall = bindings.getOperationBinding("queryAllInvoice");
                 operationqueryall.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operationqueryall.getParamsMap().put("queryAllPO", queryPO.toString());
              operationqueryall.execute();
        OperationBinding operationvalidate = bindingsvalidate.getOperationBinding("validateInvoice");
            String resultvalidate=null;
                       resultvalidate=(String)operationvalidate.execute();
           FacesMessage fmvalidate=null;
           if(resultvalidate!=null){
               fmvalidate=new FacesMessage(resultvalidate);
           fmvalidate.setSeverity(FacesMessage.SEVERITY_INFO);
                  context.addMessage(null, fmvalidate);
           return;
           }
           
           
        OperationBinding operation = bindings.getOperationBinding("updateInvoiceDetails");
                  String result=(String)operation.execute();
          if(result!=null)
            fm=new FacesMessage(result);
        else{
         fm = new FacesMessage("Your request for Chargeback/Release Hold have been successfully submitted.");
         
        }
                /**
                 * set the type of the message.
                 * Valid types: error, fatal,info,warning
                 */
                fm.setSeverity(FacesMessage.SEVERITY_INFO);
              
                context.addMessage(null, fm);
                queryInv=Boolean.FALSE;
                queryPO=Boolean.FALSE;
      
    }

    public void invLineSelection(SelectionEvent selectionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        DCIteratorBinding iter=bindings.findIteratorBinding("ApInvoiceLineVO1Iterator");
        String poLineId=iter.getViewObject().getCurrentRow().getAttribute("PoLineId").toString();
        OperationBinding operation = bindings.getOperationBinding("invLineSelection");
       
        
              operation.getParamsMap().put("poLineId", poLineId);
              operation.execute();
        
    }

    public void saveInvoice(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("saveInvoiceDetails");
         operation.execute();
          OperationBinding operationvalidate = bindings.getOperationBinding("validateInvoice");
              String result=null;
               result=(String)operationvalidate.execute();
        FacesMessage fm=null;
        if(result!=null){
            fm=new FacesMessage(result);
        fm.setSeverity(FacesMessage.SEVERITY_INFO);
        FacesContext context = FacesContext.getCurrentInstance();
        context.addMessage(null, fm);
      
        }
        OperationBinding operationinvoicetot = bindings.getOperationBinding("getInvoiceTot");
         invAmount=(BigDecimal)operationinvoicetot.execute();
         OperationBinding operationreasontot = bindings.getOperationBinding("getInvoiceReasonTot");
         reasonCode=(BigDecimal)operationreasontot.execute();

        if(invAmount!=null &&reasonCode!=null)
         amount=invAmount.add(reasonCode);
         
        BigDecimal invoiceamount=new BigDecimal(0);
        OperationBinding operationinvoiceamount = bindings.getOperationBinding("getInvoiceAmount");
         invoiceamount=(BigDecimal)operationinvoiceamount.execute();
         double amountdifference=0.0;
         if(amount!=null && invoiceamount!=null){
             amountdifference=invoiceamount.doubleValue()-amount.doubleValue();
             linevariance=new BigDecimal(amountdifference);
         }
         fm=new FacesMessage("Your Changes have been saved successfully.");
        fm.setSeverity(FacesMessage.SEVERITY_INFO);
        FacesContext context=FacesContext.getCurrentInstance();
        context.addMessage(null, fm);
        OperationBinding operationqueryall = bindings.getOperationBinding("queryAllInvoice");
                   operationqueryall.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operationqueryall.getParamsMap().put("queryAllPO", queryPO.toString());
              operationqueryall.execute();
        
    }

    public void setInit(String init) {
        this.init = init;
    }

    public String getInit() {
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operationin = bindings.getOperationBinding("init");
                 amount=(BigDecimal)operationin.execute();
        OperationBinding operation = bindings.getOperationBinding("queryAllInvoice");
                operation.getParamsMap().put("queryAllInvoice", null);
        operation.getParamsMap().put("queryAllPO", null);
              operation.execute();
        queryInv=Boolean.FALSE;
        queryPO=Boolean.FALSE;
        selectAll=Boolean.FALSE;
        invAmount=new BigDecimal(0);
        reasonCode=new BigDecimal(0);
        amount=new BigDecimal(0);
        linevariance=new BigDecimal(0);
        return init;
    }

    public void unassignUser(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("unassignUser");
           String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
              operation.getParamsMap().put("pInvoiceId", invoiceNo);
              operation.execute();
        FacesMessage fm=new FacesMessage("Invoice have been Unassigned successfully.");
        fm.setSeverity(FacesMessage.SEVERITY_INFO);
        FacesContext context=FacesContext.getCurrentInstance();
        context.addMessage(null, fm);
    }

    public void setInvAmount(BigDecimal invAmount) {
        this.invAmount = invAmount;
    }

    public BigDecimal getInvAmount() {
        return invAmount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setReasonCode(BigDecimal reasonCode) {
        this.reasonCode = reasonCode;
    }

    public BigDecimal getReasonCode() {
        return reasonCode;
    }

    public void addInvoiceLineHold(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("addInvoiceLineHold");
            String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
              operation.getParamsMap().put("lineLocationId", invoiceNo);
        operation.getParamsMap().put("invoiceId", invoiceNo);
        operation.getParamsMap().put("lineNo", invoiceNo);
        
         DCIteratorBinding iter=bindings.findIteratorBinding("ApInvoiceLineVO1Iterator");
        String poLineId=iter.getViewObject().getCurrentRow().getAttribute("PoLineId").toString();
    Row row=iter.getViewObject().getCurrentRow();
        
        
     Key key=iter.getViewObject().getCurrentRow().getKey();
              operation.execute();
        OperationBinding operationqueryall = bindings.getOperationBinding("queryAllInvoice");
                operationqueryall.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operationqueryall.getParamsMap().put("queryAllPO", queryPO.toString());
              operationqueryall.execute();
        
        iter.setCurrentRowWithKey(key.toStringFormat(true));
    }

    public void deleteInvoiceHold(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("deleteInvoiceLineHold");
            String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
              operation.getParamsMap().put("invoiceId", invoiceNo);
        operation.getParamsMap().put("lineLocationId", invoiceNo);
        operation.getParamsMap().put("lineNo", invoiceNo);
         DCIteratorBinding iter=bindings.findIteratorBinding("ApInvoiceLineVO1Iterator");
        String poLineId=iter.getViewObject().getCurrentRow().getAttribute("PoLineId").toString();
        DCIteratorBinding iterhold=bindings.findIteratorBinding("ApHoldsVO1Iterator");
        String holdLineId=(String)AdfFacesContext.getCurrentInstance().getPageFlowScope().get("holdLineId").toString();
        operation.getParamsMap().put("holdLineId", holdLineId);
        Row row=iter.getViewObject().getCurrentRow();
        Key key=iter.getViewObject().getCurrentRow().getKey();
              operation.execute();
        OperationBinding operationqueryall = bindings.getOperationBinding("queryAllInvoice");
                 operationqueryall.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operationqueryall.getParamsMap().put("queryAllPO", queryPO.toString());
              operationqueryall.execute();
        iter.setCurrentRowWithKey(key.toStringFormat(true));
              
    }

    public void setSelectAll(Boolean selectAll) {
        this.selectAll = selectAll;
    }

    public Boolean getSelectAll() {
        return selectAll;
    }
    
    public void selectAllCheckBoxVCL(ValueChangeEvent valueChangeEvent) {
        if(valueChangeEvent.getNewValue()!=null){
    System.out.println("xdebug c1 : In selectAllChoiceBoxLN with value = "+
    valueChangeEvent.getNewValue());

    boolean isSelected = ((Boolean)valueChangeEvent.getNewValue()).booleanValue();
    DCBindingContainer dcb = (DCBindingContainer) evaluateEL("#{bindings}");
    DCIteratorBinding dciter =dcb.findIteratorBinding("ApInvoiceLineVO1Iterator");

    ViewObject vo = dciter.getViewObject();
    int i = 0;
    Row row = null;
    vo.reset();
    while (vo.hasNext()) {
    if (i == 0)
    row = vo.first();
    else
    row = vo.next();
    System.out.println("xdebug c2: Changing row 2: " +
    row.getAttribute("EmployeeSelect"));

    if(isSelected)
    row.setAttribute("EmployeeSelect", true);
    else
    row.setAttribute("EmployeeSelect", false);
    i++;
    }
    if(vo.getEstimatedRowCount()==1 ){
      if(isSelected)  
    vo.first().setAttribute("EmployeeSelect", true);
      else
      vo.first().setAttribute("EmployeeSelect", false);
    
    }
    
        }
    }
    private static Object evaluateEL(String el) {
    FacesContext facesContext = FacesContext.getCurrentInstance();
    ELContext elContext = facesContext.getELContext();
    ExpressionFactory expressionFactory =
    facesContext.getApplication().getExpressionFactory();
    ValueExpression exp =
    expressionFactory.createValueExpression(elContext, el,
              Object.class);
    return exp.getValue(elContext);
    }
    public void massUpdate(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("massUpdateReason");
        HashMap map=new HashMap();
        
         operation.getParamsMap().put("qtyReason", "");
        operation.getParamsMap().put("priceReason", "");
        operation.getParamsMap().put("releaseholdSelect", releaseholdSelect.getValue());
        operation.getParamsMap().put("chargebackSelect", chargebackSelect.getValue());
        operation.execute();
         OperationBinding operationqueryall = bindings.getOperationBinding("queryAllInvoice");
        operationqueryall.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operationqueryall.getParamsMap().put("queryAllPO", queryPO.toString());
        operationqueryall.execute();
        selectAll=Boolean.FALSE;
        FacesMessage fm = new FacesMessage("Mass updated successfully.");
                /**
                 * set the type of the message.
                 * Valid types: error, fatal,info,warning
                 */
                fm.setSeverity(FacesMessage.SEVERITY_INFO);
                FacesContext context = FacesContext.getCurrentInstance();
                context.addMessage(null, fm);
    }

    public void setQtyReason(RichSelectOneChoice qtyReason) {
        this.qtyReason = qtyReason;
    }

    public RichSelectOneChoice getQtyReason() {
        return qtyReason;
    }

    public void setPriceReason(RichSelectOneChoice priceReason) {
        this.priceReason = priceReason;
    }

    public RichSelectOneChoice getPriceReason() {
        return priceReason;
    }

    public void setReleaseholdSelect(RichSelectBooleanCheckbox releaseholdSelect) {
        this.releaseholdSelect = releaseholdSelect;
    }

    public RichSelectBooleanCheckbox getReleaseholdSelect() {
        return releaseholdSelect;
    }

    public void setChargebackSelect(RichSelectBooleanCheckbox chargebackSelect) {
        this.chargebackSelect = chargebackSelect;
    }

    public RichSelectBooleanCheckbox getChargebackSelect() {
        return chargebackSelect;
    }

    public void buttonActionListener(ActionEvent actionEvent) {
        getPopup().hide();
    }
    

    public void setPopup(RichPopup popup) {
        this.popup = popup;
    }

    public RichPopup getPopup() {
        return popup;
    }

    public void cancelButton(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("cancelInvoice");
        HashMap map=new HashMap();
        String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
        String result=null;
         operation.getParamsMap().put("invoiceId", invoiceNo);
        result=(String)operation.execute();
        getPopup().hide();
        FacesMessage fm=new FacesMessage("Invoice cancel status : "+result);
        fm.setSeverity(FacesMessage.SEVERITY_INFO);
        FacesContext context=FacesContext.getCurrentInstance();
        context.addMessage(null, fm);
    }
    
    

    public void createLine(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("addInvoiceLine");
            String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
              operation.getParamsMap().put("invId", invoiceNo);
        operation.getParamsMap().put("userId", "");
        operation.getParamsMap().put("userName", "");
        
        DCIteratorBinding iter=bindings.findIteratorBinding("ApInvoiceLineVO1Iterator");
        Row row=iter.getViewObject().getCurrentRow();
        Key key=null;
         if(row!=null)
         key=iter.getViewObject().getCurrentRow().getKey();
              operation.execute();
        OperationBinding operationqueryall = bindings.getOperationBinding("queryAllInvoice");
                operationqueryall.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operationqueryall.getParamsMap().put("queryAllPO", queryPO.toString());
              operationqueryall.execute();
               if(row!=null)
               iter.setCurrentRowWithKey(key.toStringFormat(true));
    }

    public void deleteInvoiceLine(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("deleteInvoiceLine");
     
          String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
        String lineNum=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("lineNum").toString();
        String dtlLineId=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("dtlLineId").toString();
        
              operation.getParamsMap().put("invId", invoiceNo);
        operation.getParamsMap().put("lineNum", lineNum);
        operation.getParamsMap().put("dtlLineId", dtlLineId);
           FacesContext facesContext = FacesContext.getCurrentInstance();      
      String popupId = getDeleteInvoicePopup().getClientId(facesContext);
                      
                      
                      ExtendedRenderKitService extRenderKitSrvc =
                      Service.getRenderKitService(facesContext,
                                                  ExtendedRenderKitService.class);
                  extRenderKitSrvc.addScript(facesContext,
                                             "AdfPage.PAGE.findComponent('" +
                                             popupId + "').show();");
                  AdfFacesContext.getCurrentInstance().addPartialTarget(getDeleteInvoicePopup());
              
    }

    public void reasonCodeChange(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        valueChangeEvent.getComponent().processUpdates(FacesContext.getCurrentInstance());
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operationqueryall = bindings.getOperationBinding("queryAllInvoice");
                 operationqueryall.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operationqueryall.getParamsMap().put("queryAllPO", queryPO.toString());
         String dtlLineId=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("holdLineId").toString();
        OperationBinding operationreasoncode = bindings.getOperationBinding("reasonCodeChange");
        operationreasoncode.getParamsMap().put("holdLineId", dtlLineId);
        DCIteratorBinding iter=bindings.findIteratorBinding("ApInvoiceLineVO1Iterator");
          Row row=iter.getViewObject().getCurrentRow();
        Key key=iter.getViewObject().getCurrentRow().getKey();
        operationreasoncode.execute();
              operationqueryall.execute();
        iter.setCurrentRowWithKey(key.toStringFormat(true));
    }

    public void chargebackListener(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operationqueryall = bindings.getOperationBinding("queryAllInvoice");
                operationqueryall.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operationqueryall.getParamsMap().put("queryAllPO", queryPO.toString());
        DCIteratorBinding iter=bindings.findIteratorBinding("ApInvoiceLineVO1Iterator");
        Row row=iter.getViewObject().getCurrentRow();
        Key key=iter.getViewObject().getCurrentRow().getKey();

              operationqueryall.execute();
        iter.setCurrentRowWithKey(key.toStringFormat(true));
    }


    public void updateChargeback(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        valueChangeEvent.getComponent().processUpdates(FacesContext.getCurrentInstance());
        
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("updateChargeback");
        
             operation.getParamsMap().put("holdLookupCode", "");
              if(valueChangeEvent.getNewValue()!=null && valueChangeEvent.getNewValue().toString().equals("true"))
              operation.execute();
        OperationBinding operationqueryall = bindings.getOperationBinding("queryAllInvoice");
              operationqueryall.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operationqueryall.getParamsMap().put("queryAllPO", queryPO.toString());
      
              operationqueryall.execute();
              
    }

    public void getFreightChargeback(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        valueChangeEvent.getComponent().processUpdates(FacesContext.getCurrentInstance());
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("getFreightChargeback");
        operation.execute();
        OperationBinding operationqueryall = bindings.getOperationBinding("queryAllInvoice");
               operationqueryall.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operationqueryall.getParamsMap().put("queryAllPO", queryPO.toString());
        operationqueryall.execute();
    }

    public void setLinevariance(BigDecimal linevariance) {
        this.linevariance = linevariance;
    }

    public BigDecimal getLinevariance() {
        return linevariance;
    }


    public void setDeleteInvoicePopup(RichPopup deleteInvoicePopup) {
        this.deleteInvoicePopup = deleteInvoicePopup;
    }

    public RichPopup getDeleteInvoicePopup() {
        return deleteInvoicePopup;
    }

    public void deleteInvLine(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("deleteInvoiceLine");
       
          String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
        String lineNum=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("lineNum").toString();
        String dtlLineId=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("dtlLineId").toString();
        
              operation.getParamsMap().put("invId", invoiceNo);
        operation.getParamsMap().put("lineNum", lineNum);
        operation.getParamsMap().put("dtlLineId", dtlLineId);
      
              operation.execute();
         OperationBinding operationqueryall = bindings.getOperationBinding("queryAllInvoice");
                 operationqueryall.getParamsMap().put("queryAllInvoice", queryInv.toString());
        operationqueryall.getParamsMap().put("queryAllPO", queryPO.toString());
              operationqueryall.execute();
              getDeleteInvoicePopup().hide();
    }

    public void buttonDeleteLine(ActionEvent actionEvent) {
        // Add event code here...
        getDeleteInvoicePopup().hide();
    }

    public String backToMootsScreen() {

        OperationBinding operation =ADFUtils.findOperation("unassignUser");
           String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
              operation.getParamsMap().put("pInvoiceId", invoiceNo);
              operation.execute();
        return "return3";
    }
}
