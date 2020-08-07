package od.tdmatch.view.managedBeans;

import java.io.IOException;
import java.io.OutputStream;

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

import oracle.binding.OperationBinding;

import oracle.jbo.Row;
import oracle.jbo.ViewObject;

import org.apache.poi.hssf.usermodel.HSSFCell;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;

public class MassReleaseHoldBean {
    
    String invoiceSum ="$ 0.00";
    String quantityHoldSum="$ 0.00";
    String priceHoldSum="$ 0.00";
    Boolean load=false;
    
    public MassReleaseHoldBean() {
        super();
    }

    public String massReleaseAction() {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("massReleaseValidate");
       
        String result=null;
             result=(String) operation.execute();
              
             
             FacesMessage fm=new FacesMessage(result);
             fm.setSeverity(FacesMessage.SEVERITY_ERROR);
             FacesContext context=FacesContext.getCurrentInstance();
             if(result!=null && result.startsWith("Please"))
             context.addMessage(null, fm);
             
             if(result!=null){
                 String sum[]=result.split(",");
                 invoiceSum="$ "+sum[0];
                 quantityHoldSum="$ "+sum[1];
                 priceHoldSum="$ "+sum[2];
             }
        load=true;
        return null;
    }

    public void setInvoiceSum(String invoiceSum) {
        this.invoiceSum = invoiceSum;
    }

    public String getInvoiceSum() {
        return invoiceSum;
    }

    public void setQuantityHoldSum(String quantityHoldSum) {
        this.quantityHoldSum = quantityHoldSum;
    }

    public String getQuantityHoldSum() {
        return quantityHoldSum;
    }

    public void setPriceHoldSum(String priceHoldSum) {
        this.priceHoldSum = priceHoldSum;
    }

    public String getPriceHoldSum() {
        return priceHoldSum;
    }
    
    public void initMassRelease(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initMassRelease");
       
        String result=null;
             result=(String) operation.execute();
             load=false;
     

    }
    
    public String updateAction(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("updateMassReleaseSelectRow");
         
              String result=(String)operation.execute();
        FacesMessage fm=null;
        if(result!=null && result.startsWith("Please"))
            fm = new FacesMessage(result);
        else
        
         fm = new FacesMessage("Your changes have been successfully updated.");
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

    boolean isSelected = ((Boolean)valueChangeEvent.getNewValue()).booleanValue();
    DCBindingContainer dcb = (DCBindingContainer) evaluateEL("#{bindings}");
    DCIteratorBinding dciter =dcb.findIteratorBinding("MassReleaseHoldVO1Iterator");

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
    
    public void clearMassRelease(ActionEvent actionEvent){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("clearMassReleaseHold");
        
              String result=(String)operation.execute();
              
    }

    public void setLoad(Boolean load) {
        this.load = load;
    }

    public Boolean getLoad() {
        return load;
    }
    public void generateExcel(FacesContext facesContext, OutputStream outputStream) throws IOException {
              try {
              
                                 
                                    HSSFWorkbook workbook = new HSSFWorkbook();
                                        HSSFSheet worksheet = workbook.createSheet("Worksheet");
                   
                                    DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
                                    DCIteratorBinding dcIteratorBindings = bindings.findIteratorBinding("MassReleaseHoldVO1Iterator");
                                    HSSFRow  excelrow = null;
                   
                                                                         int i = 0;
                                   Row row=null;
                                   ViewObject vo=dcIteratorBindings.getViewObject();
                                    vo.reset();
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
                                                        cellA1.setCellValue("Vendor Assistant");
                                                        cellA1 = excelrow.createCell((short) 1);
                                                        cellA1.setCellValue("Supplier Name");
                                                        cellA1 = excelrow.createCell((short) 2);
                                                        cellA1.setCellValue("Supplier #");
                                                        cellA1 = excelrow.createCell((short) 3);
                                                        cellA1.setCellValue("Supplier Site");
                                                        cellA1 = excelrow.createCell((short) 4);
                                                        cellA1.setCellValue("DISC");
                                                        cellA1 = excelrow.createCell((short) 5);
                                                        cellA1.setCellValue("Invoice #");
                                                        cellA1 = excelrow.createCell((short) 6);
                                                        cellA1.setCellValue("Voucher");
                                                        cellA1 = excelrow.createCell((short) 7);
                                                        cellA1.setCellValue("Invoice Date");
                                                        cellA1 = excelrow.createCell((short) 8);
                                                        cellA1.setCellValue("PO#");
                                                        cellA1 = excelrow.createCell((short) 9);
                                                        cellA1.setCellValue("Location");
                                                        cellA1 = excelrow.createCell((short) 10);
                                                        cellA1.setCellValue("Due Date");
                                                        cellA1 = excelrow.createCell((short) 11);
                                                        cellA1.setCellValue("Invoice Amount $");
                                                        cellA1 = excelrow.createCell((short) 12);
                                                        cellA1.setCellValue("Qty Hold Amt $");
                                                        cellA1 = excelrow.createCell((short) 13);
                                                        cellA1.setCellValue("Price Hold Amt $");
                                                        cellA1 = excelrow.createCell((short) 14);
                                                        cellA1.setCellValue("FD");
                                                        cellA1 = excelrow.createCell((short) 15);
                                                        cellA1.setCellValue("NC");
                                                        cellA1 = excelrow.createCell((short) 16);
                                                        cellA1.setCellValue("DS");
                                                        cellA1 = excelrow.createCell((short) 17);
                                                        cellA1.setCellValue("Freight Hold");
                                                        cellA1 = excelrow.createCell((short) 18);
                                                        cellA1.setCellValue("Qty Hold Reason Code");
                                                        cellA1 = excelrow.createCell((short) 19);
                                                        cellA1.setCellValue("Price Hold Reason Code");
                                                        
                                                            
                                                        
                                                    }
     
                                                    //print data from second row in excel
                                                    ++i;
                                                    short j = 0;
                                                    
                                                      excelrow = worksheet.createRow((short)i);
                                                    
                                                       HSSFCell cellA1=null;
                                                       cellA1 = excelrow.createCell((short) 0);
                                                       if(row.getAttribute("VendorAssistant")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VendorAssistant").toString());
                                                       else
                                                           cellA1.setCellValue("");  
                                                       cellA1 = excelrow.createCell((short) 1);
                                                       if(row.getAttribute("SupplierName")!=null)
                                                           cellA1.setCellValue(row.getAttribute("SupplierName").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 2);
                                                       if(row.getAttribute("SupplierNo")!=null)
                                                           cellA1.setCellValue(row.getAttribute("SupplierNo").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 3);
                                                       if(row.getAttribute("SupplierSite")!=null)
                                                           cellA1.setCellValue(row.getAttribute("SupplierSite").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 4);
                                                       if(row.getAttribute("Discount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Discount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 5);
                                                       if(row.getAttribute("InvoiceNum")!=null)
                                                           cellA1.setCellValue(row.getAttribute("InvoiceNum").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 6);
                                                       if(row.getAttribute("VoucherNum")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VoucherNum").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 7);
                                                       if(row.getAttribute("InvoiceDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("InvoiceDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 8);
                                                       if(row.getAttribute("PoNumber")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PoNumber").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 9);
                                                       if(row.getAttribute("Location")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Location").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 10);
                                                       if(row.getAttribute("DueDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("DueDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 11);
                                                       if(row.getAttribute("InvoiceAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("InvoiceAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 12);
                                                       if(row.getAttribute("QtyHoldAmt")!=null)
                                                           cellA1.setCellValue(row.getAttribute("QtyHoldAmt").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 13);
                                                       if(row.getAttribute("PriceHoldAmt")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PriceHoldAmt").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 14);
                                                       if(row.getAttribute("FrontDoorc")!=null)
                                                           cellA1.setCellValue(row.getAttribute("FrontDoorc").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 15);
                                                       if(row.getAttribute("NonCodec")!=null)
                                                           cellA1.setCellValue(row.getAttribute("NonCodec").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 16);
                                                       if(row.getAttribute("DropShipc")!=null)
                                                           cellA1.setCellValue(row.getAttribute("DropShipc").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 17);
                                                       if(row.getAttribute("FrtHold")!=null)
                                                           cellA1.setCellValue(row.getAttribute("FrtHold").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 18);
                                                       if(row.getAttribute("QtyHoldReason")!=null)
                                                           cellA1.setCellValue(row.getAttribute("QtyHoldReason").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 19);
                                                       if(row.getAttribute("PriceHoldReason")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PriceHoldReason").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                   
                                                       worksheet.createFreezePane(0, 1, 0, 1);
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
