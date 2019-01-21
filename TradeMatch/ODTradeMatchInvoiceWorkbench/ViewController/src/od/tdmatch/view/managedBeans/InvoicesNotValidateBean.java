package od.tdmatch.view.managedBeans;

import java.io.IOException;
import java.io.OutputStream;
import java.io.Serializable;

import java.text.DateFormat;
import java.text.SimpleDateFormat;

import javax.el.ELContext;

import javax.el.ExpressionFactory;

import javax.el.ValueExpression;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

import javax.faces.event.ActionEvent;
import javax.faces.event.ValueChangeEvent;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;

import oracle.adf.model.binding.DCIteratorBinding;

import oracle.adf.view.rich.component.rich.output.RichOutputText;

import oracle.binding.OperationBinding;

import oracle.jbo.Row;
import oracle.jbo.ViewObject;

import org.apache.poi.hssf.usermodel.HSSFCell;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;

public class InvoicesNotValidateBean implements Serializable{
    Boolean load=false;
    private RichOutputText init;

    public InvoicesNotValidateBean() {
        super();
    }

    public String invoicesSearchAction() {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("invoiceSearchValidate");
       
        String result=null;
             result=(String) operation.execute();
             load=true;

             FacesMessage fm=new FacesMessage(result);
             fm.setSeverity(FacesMessage.SEVERITY_ERROR);
             FacesContext context=FacesContext.getCurrentInstance();
             if(result!=null)
             context.addMessage(null, fm);
        return null;
    }

    public String updateAction() {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("updateSelectedRows");
      
              operation.execute();
        FacesMessage fm = new FacesMessage("Your changes have been successfully updated.");
                /**
                 * set the type of the message.
                 * Valid types: error, fatal,info,warning
                 */
                fm.setSeverity(FacesMessage.SEVERITY_INFO);
                FacesContext context = FacesContext.getCurrentInstance();
                context.addMessage(null, fm);
        return null;
    }
    public void selectAllCheckBoxVCL(ValueChangeEvent valueChangeEvent) {

    System.out.println("xdebug c1 : In selectAllChoiceBoxLN with value = "+
    valueChangeEvent.getNewValue());
    if(valueChangeEvent.getNewValue()!=null){
    boolean isSelected = ((Boolean)valueChangeEvent.getNewValue()).booleanValue();
    DCBindingContainer dcb = (DCBindingContainer) evaluateEL("#{bindings}");
    DCIteratorBinding dciter =dcb.findIteratorBinding("InvoicesNotValidatedVO1Iterator");

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
    if(vo.getEstimatedRowCount()==1){
        row = vo.first();
        if(isSelected)
        row.setAttribute("EmployeeSelect", true);
        else
        row.setAttribute("EmployeeSelect", false);
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

    public void selectAllAction(ActionEvent actionEvent) {
        // Add event code here...
    }
    public void clearInvoice(ActionEvent actionEvent){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("clearInvoiceValidate");
        
              operation.execute();
              
    }
    public void initInvoiceValidated(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initInvoiceNotValidated");
       
              operation.execute();
              load=false;
    }

    public void setLoad(Boolean load) {
        this.load = load;
    }

    public Boolean getLoad() {
        return load;
    }

    public void setInit(RichOutputText init) {
        this.init = init;
    }

    public RichOutputText getInit() {
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initInvoiceNotValidated");
       
              operation.execute();
              load=false;
        return init;
    }
    public void generateExcel(FacesContext facesContext, OutputStream outputStream) throws IOException {
              try {
              
                                 
                                    HSSFWorkbook workbook = new HSSFWorkbook();
                                        HSSFSheet worksheet = workbook.createSheet("Worksheet");
                   
                                    DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
                                    DCIteratorBinding dcIteratorBindings = bindings.findIteratorBinding("InvoicesNotValidatedVO1Iterator");
                                    HSSFRow  excelrow = null;
                   
                                                                                  int i = 0;
                                   Row row=null;
                                   ViewObject vo=dcIteratorBindings.getViewObject();
                                    vo.reset();
                  if(!vo.hasNext()){
                      if(vo.getEstimatedRowCount()==1){
                          row=(Row)vo.first();
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
                              cellA1.setCellValue("DISC");
                              cellA1 = excelrow.createCell((short) 4);
                              cellA1.setCellValue("Invoice #");
                              cellA1 = excelrow.createCell((short) 5);
                              cellA1.setCellValue("Invoice Date");
                              cellA1 = excelrow.createCell((short) 6);
                              cellA1.setCellValue("Invoice Amount $");
                              cellA1 = excelrow.createCell((short) 7);
                              cellA1.setCellValue("PO #");
                              cellA1 = excelrow.createCell((short) 8);
                              cellA1.setCellValue("Location");
                              cellA1 = excelrow.createCell((short) 9);
                              cellA1.setCellValue("Payment Terms");
                              cellA1 = excelrow.createCell((short) 10);
                              cellA1.setCellValue("Terms Date");
                              cellA1 = excelrow.createCell((short) 11);
                              cellA1.setCellValue("Discount Due Date");
                              cellA1 = excelrow.createCell((short) 12);
                              cellA1.setCellValue("GL Date");
                              cellA1 = excelrow.createCell((short) 13);
                              cellA1.setCellValue("Currency");
                              cellA1 = excelrow.createCell((short) 14);
                              cellA1.setCellValue("Payment Method");
                              cellA1 = excelrow.createCell((short) 15);
                              cellA1.setCellValue("Pay Group");
                              cellA1 = excelrow.createCell((short) 16);
                              cellA1.setCellValue("Invoice Source");
                              cellA1 = excelrow.createCell((short) 17);
                              cellA1.setCellValue("PO Type");
                              cellA1 = excelrow.createCell((short) 18);
                              cellA1.setCellValue("Vendor Assistant");
                                  
                              
                          }
                          
                          //print data from second row in excel
                          ++i;
                          short j = 0;
                          
                            excelrow = worksheet.createRow((short)i);
                          
                             HSSFCell cellA1=null;
                             cellA1 = excelrow.createCell((short) 0);
                             if(row.getAttribute("VendorNo")!=null)
                                 cellA1.setCellValue(row.getAttribute("VendorNo").toString());
                             else
                                 cellA1.setCellValue("");  
                             cellA1 = excelrow.createCell((short) 1);
                             if(row.getAttribute("VendorName")!=null)
                                 cellA1.setCellValue(row.getAttribute("VendorName").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 2);
                             if(row.getAttribute("Site")!=null)
                                 cellA1.setCellValue(row.getAttribute("Site").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 3);
                             if(row.getAttribute("Discount")!=null)
                                 cellA1.setCellValue(row.getAttribute("Discount").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 4);
                             if(row.getAttribute("InvoiceNum")!=null)
                                 cellA1.setCellValue(row.getAttribute("InvoiceNum").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 5);
                             if(row.getAttribute("InvoiceDate")!=null)
                                 cellA1.setCellValue(row.getAttribute("InvoiceDate").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 6);
                             if(row.getAttribute("InvoiceAmount")!=null)
                                 cellA1.setCellValue(row.getAttribute("InvoiceAmount").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 7);
                             if(row.getAttribute("PoNumber")!=null)
                                 cellA1.setCellValue(row.getAttribute("PoNumber").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 8);
                             if(row.getAttribute("Sitelocation")!=null)
                                 cellA1.setCellValue(row.getAttribute("Sitelocation").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 9);
                             if(row.getAttribute("PaymenrTerms")!=null)
                                 cellA1.setCellValue(row.getAttribute("PaymenrTerms").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 10);
                             if(row.getAttribute("TermsDate")!=null)
                                 cellA1.setCellValue(row.getAttribute("TermsDate").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 11);
                             if(row.getAttribute("DiscountDueDate")!=null)
                                 cellA1.setCellValue(row.getAttribute("DiscountDueDate").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 12);
                             if(row.getAttribute("GlDate")!=null)
                                 cellA1.setCellValue(row.getAttribute("GlDate").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 13);
                             if(row.getAttribute("Currency")!=null)
                                 cellA1.setCellValue(row.getAttribute("Currency").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 14);
                             if(row.getAttribute("PaymentMethodCode")!=null)
                                 cellA1.setCellValue(row.getAttribute("PaymentMethodCode").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 15);
                             if(row.getAttribute("PayGroupLookupCode")!=null)
                                 cellA1.setCellValue(row.getAttribute("PayGroupLookupCode").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 16);
                             if(row.getAttribute("Source")!=null)
                                 cellA1.setCellValue(row.getAttribute("Source").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 17);
                             if(row.getAttribute("PoType")!=null)
                                 cellA1.setCellValue(row.getAttribute("PoType").toString());
                             else
                                 cellA1.setCellValue("");
                             cellA1 = excelrow.createCell((short) 18);
                             if(row.getAttribute("TargetValue1")!=null)
                                 cellA1.setCellValue(row.getAttribute("TargetValue1").toString());
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
                                                        cellA1.setCellValue("DISC");
                                                        cellA1 = excelrow.createCell((short) 4);
                                                        cellA1.setCellValue("Invoice #");
                                                        cellA1 = excelrow.createCell((short) 5);
                                                        cellA1.setCellValue("Invoice Date");
                                                        cellA1 = excelrow.createCell((short) 6);
                                                        cellA1.setCellValue("Invoice Amount $");
                                                        cellA1 = excelrow.createCell((short) 7);
                                                        cellA1.setCellValue("PO #");
                                                        cellA1 = excelrow.createCell((short) 8);
                                                        cellA1.setCellValue("Location");
                                                        cellA1 = excelrow.createCell((short) 9);
                                                        cellA1.setCellValue("Payment Terms");
                                                        cellA1 = excelrow.createCell((short) 10);
                                                        cellA1.setCellValue("Terms Date");
                                                        cellA1 = excelrow.createCell((short) 11);
                                                        cellA1.setCellValue("Discount Due Date");
                                                        cellA1 = excelrow.createCell((short) 12);
                                                        cellA1.setCellValue("GL Date");
                                                        cellA1 = excelrow.createCell((short) 13);
                                                        cellA1.setCellValue("Currency");
                                                        cellA1 = excelrow.createCell((short) 14);
                                                        cellA1.setCellValue("Payment Method");
                                                        cellA1 = excelrow.createCell((short) 15);
                                                        cellA1.setCellValue("Pay Group");
                                                        cellA1 = excelrow.createCell((short) 16);
                                                        cellA1.setCellValue("Invoice Source");
                                                        cellA1 = excelrow.createCell((short) 17);
                                                        cellA1.setCellValue("PO Type");
                                                        cellA1 = excelrow.createCell((short) 18);
                                                        cellA1.setCellValue("Vendor Assistant");
                                                            
                                                        
                                                    }
     
                                                    //print data from second row in excel
                                                    ++i;
                                                    short j = 0;
                                                    
                                                      excelrow = worksheet.createRow((short)i);
                                                    
                                                       HSSFCell cellA1=null;
                                                       cellA1 = excelrow.createCell((short) 0);
                                                       if(row.getAttribute("VendorNo")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VendorNo").toString());
                                                       else
                                                           cellA1.setCellValue("");  
                                                       cellA1 = excelrow.createCell((short) 1);
                                                       if(row.getAttribute("VendorName")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VendorName").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 2);
                                                       if(row.getAttribute("Site")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Site").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 3);
                                                       if(row.getAttribute("Discount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Discount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 4);
                                                       if(row.getAttribute("InvoiceNum")!=null)
                                                           cellA1.setCellValue(row.getAttribute("InvoiceNum").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 5);
                                                       if(row.getAttribute("InvoiceDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("InvoiceDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 6);
                                                       if(row.getAttribute("InvoiceAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("InvoiceAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 7);
                                                       if(row.getAttribute("PoNumber")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PoNumber").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 8);
                                                       if(row.getAttribute("Sitelocation")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Sitelocation").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 9);
                                                       if(row.getAttribute("PaymenrTerms")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PaymenrTerms").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 10);
                                                       if(row.getAttribute("TermsDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("TermsDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 11);
                                                       if(row.getAttribute("DiscountDueDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("DiscountDueDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 12);
                                                       if(row.getAttribute("GlDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("GlDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 13);
                                                       if(row.getAttribute("Currency")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Currency").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 14);
                                                       if(row.getAttribute("PaymentMethodCode")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PaymentMethodCode").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 15);
                                                       if(row.getAttribute("PayGroupLookupCode")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PayGroupLookupCode").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 16);
                                                       if(row.getAttribute("Source")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Source").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 17);
                                                       if(row.getAttribute("PoType")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PoType").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 18);
                                                       if(row.getAttribute("TargetValue1")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TargetValue1").toString());
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
    public String getSimpleDate( oracle.jbo.domain.Date date){
        DateFormat dateFormat = new SimpleDateFormat("MM-dd-yyyy");
        java.util.Date invoiceUtilDate=convertDomainDateToUtilDate(date);
        String datetimeinvfrom=null;
        if(invoiceUtilDate!=null)
         datetimeinvfrom = dateFormat.format(invoiceUtilDate);
        return datetimeinvfrom;
    }
    public static java.util.Date convertDomainDateToUtilDate(oracle.jbo.domain.Date domainDate) {
    java.util.Date date = null;
    if (domainDate != null) {
    java.sql.Date sqldate = domainDate.dateValue();
    date = new java.util.Date(sqldate.getTime());
    }
    return date;
    }
}
