package od.tdmatch.view.managedBeans;

import java.io.IOException;
import java.io.OutputStream;

import javax.faces.event.ActionEvent;
import java.io.Serializable;

import java.util.HashMap;

import javax.el.ELContext;

import javax.el.ExpressionFactory;

import javax.el.MethodExpression;

import javax.el.ValueExpression;

import javax.faces.application.FacesMessage;

import javax.faces.context.FacesContext;

import javax.faces.event.ValueChangeEvent;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;

import oracle.adf.model.binding.DCIteratorBinding;

import oracle.adf.view.rich.component.rich.input.RichSelectOneChoice;
import oracle.adf.view.rich.component.rich.output.RichOutputText;
import oracle.adf.view.rich.context.AdfFacesContext;
import oracle.adf.view.rich.event.QueryEvent;

import oracle.binding.OperationBinding;

import oracle.jbo.Row;
import oracle.jbo.ViewObject;

import org.apache.poi.hssf.usermodel.HSSFCell;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;

public class GeneralInquiryBean implements Serializable{
    
    Boolean massUpdateDisable=Boolean.FALSE;
    Boolean updateDisable=Boolean.FALSE;
    Boolean selectAll=Boolean.FALSE;
    Boolean load=false;
    private RichSelectOneChoice fromva;
    private RichSelectOneChoice tova;
    private RichOutputText init;

    public GeneralInquiryBean() {
        super();
    }

    @SuppressWarnings("unchecked")
    public void UpdateVAAction(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("updateSelectedVA");
       
              String result=null;
              result=(String)operation.execute();
        FacesMessage fm=null;
        if(result!=null && result.contains("Please")){
            fm=new FacesMessage(result);
        }
        else
         fm = new FacesMessage("Your changes have been successfully updated.");
                /**
                 * set the type of the message.
                 * Valid types: error, fatal,info,warning
                 */
                fm.setSeverity(FacesMessage.SEVERITY_INFO);
                FacesContext context = FacesContext.getCurrentInstance();
                context.addMessage(null, fm);
              
    }

    public void massUpdateVAAction(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("submitMassUpdate");
        HashMap map=new HashMap();
        map.put("fromva",getFromva().getValue());
        map.put("tova", getTova().getValue());
        operation.getParamsMap().put("param", map);
        operation.execute();
        FacesMessage fm = new FacesMessage("Your changes have been successfully updated.");
                /**
                 * set the type of the message.
                 * Valid types: error, fatal,info,warning
                 */
                fm.setSeverity(FacesMessage.SEVERITY_INFO);
                FacesContext context = FacesContext.getCurrentInstance();
                context.addMessage(null, fm);
    }
    
    public void createVendorUpdate(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initGeneralInquiry");
        operation.execute();
        load=false;
    }
    
    public void employeeValueChange(ValueChangeEvent valueChangeEvent){
        

         
    }

    public void setMassUpdateDisable(Boolean massUpdateDisable) {
        this.massUpdateDisable = massUpdateDisable;
    }

    public Boolean getMassUpdateDisable() {
        return massUpdateDisable;
    }

    public void employeeVLC(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
       // System.out.println("New Name : " + valueChangeEvent.getNewValue());  
       // valueChangeEvent.getComponent().processUpdates(FacesContext.getCurrentInstance()); 
        DCBindingContainer binding=(DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        DCIteratorBinding generalIter=binding.findIteratorBinding("GeneralInquiryQueryVO1Iterator");
        generalIter.getCurrentRow().setAttribute("EmployeeSelect", true);
        generalIter.getCurrentRow().getAttribute("EmployeeName");
        massUpdateDisable=Boolean.TRUE;
        updateDisable=Boolean.FALSE;
    }

    public void setUpdateDisable(Boolean updateDisable) {
        this.updateDisable = updateDisable;
    }

    public Boolean getUpdateDisable() {
        return updateDisable;
    }
    public void selectAllCheckBoxVCL(ValueChangeEvent valueChangeEvent) {
        if(valueChangeEvent.getNewValue()!=null){
    System.out.println("xdebug c1 : In selectAllChoiceBoxLN with value = "+
    valueChangeEvent.getNewValue());

    boolean isSelected = ((Boolean)valueChangeEvent.getNewValue()).booleanValue();
    DCBindingContainer dcb = (DCBindingContainer) evaluateEL("#{bindings}");
    DCIteratorBinding dciter =dcb.findIteratorBinding("GeneralInquiryQueryVO1Iterator");

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

    public void fromVAChange(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        updateDisable=Boolean.TRUE;

        
    }

    public void toVAChange(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        updateDisable=Boolean.TRUE;
    }
    
    public void customQueryListener(QueryEvent queryEvent) {
        massUpdateDisable=Boolean.FALSE;
        updateDisable=Boolean.FALSE;
        //selectAll=Boolean.TRUE;
        invokeEL("#{bindings.GeneralInquiryQueryVOCriteriaQuery.processQuery}", new Class[] { QueryEvent.class },
                             new Object[] { queryEvent });

        
    }
    public void searchAction(ActionEvent actionEvent){
        massUpdateDisable=Boolean.FALSE;
        updateDisable=Boolean.FALSE;
        selectAll=Boolean.FALSE;
    DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
    OperationBinding operation = bindings.getOperationBinding("generalInquirySearchValidate");
    
    String result=null;
         result=(String) operation.execute();
         load=true;
    }
    public static Object invokeEL(String el, Class[] paramTypes, Object[] params) {
            FacesContext facesContext = FacesContext.getCurrentInstance();
            ELContext elContext = facesContext.getELContext();
            ExpressionFactory expressionFactory = facesContext.getApplication().getExpressionFactory();
            MethodExpression exp = expressionFactory.createMethodExpression(elContext, el, Object.class, paramTypes);

            return exp.invoke(elContext, params);
        }

    public void setSelectAll(Boolean selectAll) {
        this.selectAll = selectAll;
    }

    public Boolean getSelectAll() {
        return selectAll;
    }
    
    public void clearGeneralInquiry(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("clearGeneralInquiry");
                       String result=(String)operation.execute();
    }
    public String DeptContactSearchAction() {
            // Add event code here...
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("DeptContactSearchAction");
    
            String result=null;
                 result=(String) operation.execute();

    
                 FacesMessage fm=new FacesMessage(result);
                 fm.setSeverity(FacesMessage.SEVERITY_ERROR);
                 FacesContext context=FacesContext.getCurrentInstance();
                 if(result!=null)
                 context.addMessage(null, fm);
            return null;
        }
    public void clearDeptContactSearch(ActionEvent actionEvent){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        System.out.println("Clear button is clicked");
        OperationBinding operation = bindings.getOperationBinding("clearDeptContactSearch");
        
              operation.execute();
        System.out.println("Clear button logic is executed");
              
    }

    public void setLoad(Boolean load) {
        this.load = load;
    }

    public Boolean getLoad() {
        return load;
    }

    public void setFromva(RichSelectOneChoice fromva) {
        this.fromva = fromva;
    }

    public RichSelectOneChoice getFromva() {
        return fromva;
    }

    public void setTova(RichSelectOneChoice tova) {
        this.tova = tova;
    }

    public RichSelectOneChoice getTova() {
        return tova;
    }

    public void setInit(RichOutputText init) {
        this.init = init;
    }

    public RichOutputText getInit() {
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initGeneralInquiry");
        operation.execute();
        load=false;
        selectAll=Boolean.FALSE;
        return init;
    }
    public void generateExcel(FacesContext facesContext, OutputStream outputStream) throws IOException {
              try {
              
                                 
                                    HSSFWorkbook workbook = new HSSFWorkbook();
                                        HSSFSheet worksheet = workbook.createSheet("Worksheet");
                   
                                    DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
                                    DCIteratorBinding dcIteratorBindings = bindings.findIteratorBinding("GeneralInquiryQueryVO1Iterator");
                                    HSSFRow  excelrow = null;
                   
                                           
                                        int i = 0;
                                   Row row=null;
                                   ViewObject vo=dcIteratorBindings.getViewObject();
                                    vo.reset();
                  if(!vo.hasNext()){
                      if(vo.getEstimatedRowCount()==1){
                          if(i==0)
                              row=(Row)vo.first();
                          else
                              row=vo.next();
                          //print header on first row in excel
                          if (i == 0) {
                           excelrow = (HSSFRow)worksheet.createRow((short)i);
                           short j = 0;
                          //
                           HSSFCell cellA1=null;
                           
                           cellA1 = excelrow.createCell((short) 0);
                           cellA1.setCellValue("Supplier #");
                           cellA1 = excelrow.createCell((short) 1);
                           cellA1.setCellValue("Supplier Name");
                           cellA1 = excelrow.createCell((short) 2);
                           cellA1.setCellValue("Supplier Site");
                           cellA1 = excelrow.createCell((short) 3);
                           cellA1.setCellValue("Terms");
                           cellA1 = excelrow.createCell((short) 4);
                           cellA1.setCellValue("Terms Date Basis");
                           cellA1 = excelrow.createCell((short) 5);
                           cellA1.setCellValue("Pay Method");
                           cellA1 = excelrow.createCell((short) 6);
                           cellA1.setCellValue("Pay Group");
                           cellA1 = excelrow.createCell((short) 7);
                           cellA1.setCellValue("Site Hold (Y/N)");
                           cellA1 = excelrow.createCell((short) 8);
                           cellA1.setCellValue("Site Payment Hold Reason");
                           cellA1 = excelrow.createCell((short) 9);
                           cellA1.setCellValue("Site Status");
                           cellA1 = excelrow.createCell((short) 10);
                           cellA1.setCellValue("Vendor Assistant");
                           cellA1 = excelrow.createCell((short) 11);
                           cellA1.setCellValue("Site Category");
                           cellA1 = excelrow.createCell((short) 12);
                           cellA1.setCellValue("Separate Remittance Advice");
                           
                               
                           
                          }
                          
                          //print data from second row in excel
                          ++i;
                          short j = 0;
                          
                          excelrow = worksheet.createRow((short)i);
                          
                          HSSFCell cellA1=null;
                          cellA1 = excelrow.createCell((short) 0);
                          if(row.getAttribute("SupplierNo")!=null)
                              cellA1.setCellValue(row.getAttribute("SupplierNo").toString());
                          else
                              cellA1.setCellValue("");  
                          cellA1 = excelrow.createCell((short) 1);
                          if(row.getAttribute("SupplierName")!=null)
                              cellA1.setCellValue(row.getAttribute("SupplierName").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 2);
                          if(row.getAttribute("SupplierSiteNo")!=null)
                              cellA1.setCellValue(row.getAttribute("SupplierSiteNo").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 3);
                          if(row.getAttribute("Terms")!=null)
                              cellA1.setCellValue(row.getAttribute("Terms").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 4);
                          if(row.getAttribute("TermsDateBasis")!=null)
                              cellA1.setCellValue(row.getAttribute("TermsDateBasis").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 5);
                          if(row.getAttribute("PayMethod")!=null)
                              cellA1.setCellValue(row.getAttribute("PayMethod").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 6);
                          if(row.getAttribute("PayGroup")!=null)
                              cellA1.setCellValue(row.getAttribute("PayGroup").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 7);
                          if(row.getAttribute("SiteHold")!=null)
                              cellA1.setCellValue(row.getAttribute("SiteHold").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 8);
                          if(row.getAttribute("SitePaymentHoldReason")!=null)
                              cellA1.setCellValue(row.getAttribute("SitePaymentHoldReason").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 9);
                          if(row.getAttribute("Status")!=null)
                              cellA1.setCellValue(row.getAttribute("Status").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 10);
                          if(row.getAttribute("VendorAssistant")!=null)
                              cellA1.setCellValue(row.getAttribute("VendorAssistant").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 11);
                          if(row.getAttribute("SiteCategory")!=null)
                              cellA1.setCellValue(row.getAttribute("SiteCategory").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 12);
                          if(row.getAttribute("RemitAdviceEmail")!=null)
                              cellA1.setCellValue(row.getAttribute("RemitAdviceEmail").toString());
                          else
                              cellA1.setCellValue("");
                          
                          worksheet.createFreezePane(0, 1, 0, 1);

                      }
                  }else{
                                                while (vo.hasNext()) {
                                                       if(i==0)
                                                           row=(Row)vo.first();
                                                       else
                                                           row=vo.next();
                                                    //print header on first row in excel
                                                    if (i == 0) {
                                                        excelrow = (HSSFRow)worksheet.createRow((short)i);
                                                        short j = 0;
    //
                                                        HSSFCell cellA1=null;
                                                        
                                                        cellA1 = excelrow.createCell((short) 0);
                                                        cellA1.setCellValue("Supplier #");
                                                        cellA1 = excelrow.createCell((short) 1);
                                                        cellA1.setCellValue("Supplier Name");
                                                        cellA1 = excelrow.createCell((short) 2);
                                                        cellA1.setCellValue("Supplier Site");
                                                        cellA1 = excelrow.createCell((short) 3);
                                                        cellA1.setCellValue("Terms");
                                                        cellA1 = excelrow.createCell((short) 4);
                                                        cellA1.setCellValue("Terms Date Basis");
                                                        cellA1 = excelrow.createCell((short) 5);
                                                        cellA1.setCellValue("Pay Method");
                                                        cellA1 = excelrow.createCell((short) 6);
                                                        cellA1.setCellValue("Pay Group");
                                                        cellA1 = excelrow.createCell((short) 7);
                                                        cellA1.setCellValue("Site Hold (Y/N)");
                                                        cellA1 = excelrow.createCell((short) 8);
                                                        cellA1.setCellValue("Site Payment Hold Reason");
                                                        cellA1 = excelrow.createCell((short) 9);
                                                        cellA1.setCellValue("Site Status");
                                                        cellA1 = excelrow.createCell((short) 10);
                                                        cellA1.setCellValue("Vendor Assistant");
                                                        cellA1 = excelrow.createCell((short) 11);
                                                        cellA1.setCellValue("Site Category");
                                                        cellA1 = excelrow.createCell((short) 12);
                                                        cellA1.setCellValue("Separate Remittance Advice");
                                                        
                                                            
                                                        
                                                    }
     
                                                    //print data from second row in excel
                                                    ++i;
                                                    short j = 0;
                                                    
                                                      excelrow = worksheet.createRow((short)i);
                                                    
                                                       HSSFCell cellA1=null;
                                                       cellA1 = excelrow.createCell((short) 0);
                                                       if(row.getAttribute("SupplierNo")!=null)
                                                           cellA1.setCellValue(row.getAttribute("SupplierNo").toString());
                                                       else
                                                           cellA1.setCellValue("");  
                                                       cellA1 = excelrow.createCell((short) 1);
                                                       if(row.getAttribute("SupplierName")!=null)
                                                           cellA1.setCellValue(row.getAttribute("SupplierName").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 2);
                                                       if(row.getAttribute("SupplierSiteNo")!=null)
                                                           cellA1.setCellValue(row.getAttribute("SupplierSiteNo").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 3);
                                                       if(row.getAttribute("Terms")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Terms").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 4);
                                                       if(row.getAttribute("TermsDateBasis")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TermsDateBasis").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 5);
                                                       if(row.getAttribute("PayMethod")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PayMethod").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 6);
                                                       if(row.getAttribute("PayGroup")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PayGroup").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 7);
                                                       if(row.getAttribute("SiteHold")!=null)
                                                           cellA1.setCellValue(row.getAttribute("SiteHold").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 8);
                                                       if(row.getAttribute("SitePaymentHoldReason")!=null)
                                                           cellA1.setCellValue(row.getAttribute("SitePaymentHoldReason").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 9);
                                                       if(row.getAttribute("Status")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Status").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 10);
                                                       if(row.getAttribute("VendorAssistant")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VendorAssistant").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 11);
                                                       if(row.getAttribute("SiteCategory")!=null)
                                                           cellA1.setCellValue(row.getAttribute("SiteCategory").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 12);
                                                       if(row.getAttribute("RemitAdviceEmail")!=null)
                                                           cellA1.setCellValue(row.getAttribute("RemitAdviceEmail").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       
                                                       worksheet.createFreezePane(0, 1, 0, 1);
                                                   } 
                  }
                  workbook.write(outputStream);
                  outputStream.flush();
                   
              }
                                                catch (Exception e) {
                                              e.printStackTrace();
                                                }
                                             
          }

    public void clearGeneralInquiry(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("clearGeneralInquiry");
                      String result=(String)operation.execute();
    }
}
