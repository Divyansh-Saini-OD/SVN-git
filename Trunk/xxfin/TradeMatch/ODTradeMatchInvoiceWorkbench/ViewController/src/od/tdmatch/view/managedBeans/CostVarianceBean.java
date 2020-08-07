package od.tdmatch.view.managedBeans;

import java.io.IOException;
import java.io.OutputStream;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;

import javax.el.ELContext;
import javax.el.ExpressionFactory;
import javax.el.ValueExpression;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

import javax.faces.event.ValueChangeEvent;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;

import oracle.adf.model.binding.DCIteratorBinding;

import oracle.adf.share.ADFContext;
import oracle.adf.view.rich.component.rich.input.RichInputDate;

import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.OperationBinding;

import oracle.jbo.Row;
import oracle.jbo.ViewObject;

import org.apache.poi.hssf.usermodel.HSSFCell;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;

public class CostVarianceBean {
    private RichInputDate answerDate;
    Boolean load=false;
    public CostVarianceBean() {
        super();
    }

    public String answerAction() {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("updateCostVariance");
        String result=null;
             result=(String) operation.execute();
        FacesMessage fm=new FacesMessage(result);
        fm.setSeverity(FacesMessage.SEVERITY_ERROR);
        FacesContext context=FacesContext.getCurrentInstance();
        if(result!=null && result.startsWith("Please"))
        context.addMessage(null, fm);
        else{
            result="Your changes have been successfully updated.";
            fm=new FacesMessage(result);
            fm.setSeverity(FacesMessage.SEVERITY_INFO);
            context.addMessage(null, fm);
        }
        return null;
    }

    public String costVarianceValidate() {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("costVarinceValidate");
         
        String result=null;
             result=(String) operation.execute();
             load=true;
       
             
             FacesMessage fm=new FacesMessage(result);
             fm.setSeverity(FacesMessage.SEVERITY_ERROR);
             FacesContext context=FacesContext.getCurrentInstance();
             if(result!=null && result.startsWith("Please"))
             context.addMessage(null, fm);
             
             
        
        return null;
    }

    public void answerCodeValueChange(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        if(valueChangeEvent.getNewValue()!=null){
        DCBindingContainer dcb = (DCBindingContainer) evaluateEL("#{bindings}");
        DCIteratorBinding dciter =dcb.findIteratorBinding("CostVarianceVO1Iterator");

        ViewObject vo = dciter.getViewObject();
            
        int i = 0;
        Row row = dciter.getRowSetIterator().getCurrentRow();
        java.util.Date datetime=new java.util.Date();
        java.sql.Date currentDate=new java.sql.Date(datetime.getTime());
      //  row.setAttribute("AnswerDate", currentDate);
        AdfFacesContext.getCurrentInstance().addPartialTarget(getAnswerDate());
     
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

    public void setAnswerDate(RichInputDate answerDate) {
        this.answerDate = answerDate;
    }

    public RichInputDate getAnswerDate() {
        return answerDate;
    }
    public void initCostVariance(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initCostVariance");
     
              operation.execute();
              load=false;
        DateFormat dateFormat = new SimpleDateFormat("yyyy/MM/dd");
                            java.util.Date date = new java.util.Date();
                            String dateStr = dateFormat.format(date);
                 try{
                        java.util.Date date2 = dateFormat.parse(dateStr);
                            java.sql.Date sqldate = new java.sql.Date(date2.getTime());
                            oracle.jbo.domain.Date daTime = new  oracle.jbo.domain.Date(sqldate);
                            System.out.println("Current Date Time : jbo " + daTime);
                            ADFContext context= ADFContext.getCurrent();
                             AdfFacesContext.getCurrentInstance().getPageFlowScope().put("systemdate", daTime);  
                     
                        }catch(ParseException pe){
                            pe.printStackTrace();
                            
                            }
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
                                    DCIteratorBinding dcIteratorBindings = bindings.findIteratorBinding("CostVarianceVO1Iterator");
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
                           cellA1.setCellValue("SKU #");
                           cellA1 = excelrow.createCell((short) 1);
                           cellA1.setCellValue("SKU Desc");
                           cellA1 = excelrow.createCell((short) 2);
                           cellA1.setCellValue("Dept");
                           cellA1 = excelrow.createCell((short) 3);
                           cellA1.setCellValue("Supplier #");
                           cellA1 = excelrow.createCell((short) 4);
                           cellA1.setCellValue("Supplier Name");
                           cellA1 = excelrow.createCell((short) 5);
                           cellA1.setCellValue("Supplier Site");
                           cellA1 = excelrow.createCell((short) 6);
                           cellA1.setCellValue("Answer");
                           cellA1 = excelrow.createCell((short) 7);
                           cellA1.setCellValue("Answer Date");
                           cellA1 = excelrow.createCell((short) 8);
                           cellA1.setCellValue("PO #");
                           cellA1 = excelrow.createCell((short) 9);
                           cellA1.setCellValue("Location");
                           cellA1 = excelrow.createCell((short) 10);
                           cellA1.setCellValue("Invoice #");
                           cellA1 = excelrow.createCell((short) 11);
                           cellA1.setCellValue("Invoice Date");
                           cellA1 = excelrow.createCell((short) 12);
                           cellA1.setCellValue("PO Date");
                           cellA1 = excelrow.createCell((short) 13);
                           cellA1.setCellValue("PO Cost");
                           cellA1 = excelrow.createCell((short) 14);
                           cellA1.setCellValue("Invoice Cost");
                           cellA1 = excelrow.createCell((short) 15);
                           cellA1.setCellValue("Correct Cost");
                           cellA1 = excelrow.createCell((short) 16);
                           cellA1.setCellValue("Variance $");
                           cellA1 = excelrow.createCell((short) 17);
                           cellA1.setCellValue("Percentage %");
                           cellA1 = excelrow.createCell((short) 18);
                           cellA1.setCellValue("Quantity");
                           cellA1 = excelrow.createCell((short) 19);
                           cellA1.setCellValue("Merchant Name");
                           cellA1 = excelrow.createCell((short) 20);
                           cellA1.setCellValue("System Update Date");
                           cellA1 = excelrow.createCell((short) 21);
                           cellA1.setCellValue("Cost Effective Date");
                           cellA1 = excelrow.createCell((short) 22);
                           cellA1.setCellValue("FD");
                           cellA1 = excelrow.createCell((short) 23);
                           cellA1.setCellValue("DS");
                           cellA1 = excelrow.createCell((short) 24);
                           cellA1.setCellValue("Vendor Assistant");
                           cellA1 = excelrow.createCell((short) 25);
                           cellA1.setCellValue("Memo");
                           cellA1 = excelrow.createCell((short) 26);
                           cellA1.setCellValue("VPC");
                           cellA1 = excelrow.createCell((short) 27);
                           cellA1.setCellValue("Creation Date");
                           cellA1 = excelrow.createCell((short) 28);
                           cellA1.setCellValue("Invoice Status");
                               
                           
                          }
                          
                          //print data from second row in excel
                          ++i;
                          short j = 0;
                          
                          excelrow = worksheet.createRow((short)i);
                          
                          HSSFCell cellA1=null;
                          cellA1 = excelrow.createCell((short) 0);
                          if(row.getAttribute("Sku")!=null)
                              cellA1.setCellValue(row.getAttribute("Sku").toString());
                          else
                              cellA1.setCellValue("");  
                          cellA1 = excelrow.createCell((short) 1);
                          if(row.getAttribute("SkuDescription")!=null)
                              cellA1.setCellValue(row.getAttribute("SkuDescription").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 2);
                          if(row.getAttribute("Dept")!=null)
                              cellA1.setCellValue(row.getAttribute("Dept").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 3);
                          if(row.getAttribute("VendorNo")!=null)
                              cellA1.setCellValue(row.getAttribute("VendorNo").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 4);
                          if(row.getAttribute("VendorName")!=null)
                              cellA1.setCellValue(row.getAttribute("VendorName").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 5);
                          if(row.getAttribute("VendorSiteCode")!=null)
                              cellA1.setCellValue(row.getAttribute("VendorSiteCode").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 6);
                          if(row.getAttribute("AnswerCode")!=null)
                              cellA1.setCellValue(row.getAttribute("AnswerCode").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 7);
                          if(row.getAttribute("AnswerDate")!=null)
                              cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("AnswerDate")));
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 8);
                          if(row.getAttribute("PoNum")!=null)
                              cellA1.setCellValue(row.getAttribute("PoNum").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 9);
                          if(row.getAttribute("Location")!=null)
                              cellA1.setCellValue(row.getAttribute("Location").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 10);
                          if(row.getAttribute("InvoiceNum")!=null)
                              cellA1.setCellValue(row.getAttribute("InvoiceNum").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 11);
                          if(row.getAttribute("InvoiceDate")!=null)
                              cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("InvoiceDate")));
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 12);
                          if(row.getAttribute("PoDate")!=null)
                              cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("PoDate")));
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 13);
                          if(row.getAttribute("PoCost")!=null)
                              cellA1.setCellValue(row.getAttribute("PoCost").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 14);
                          if(row.getAttribute("InvoicePrice")!=null)
                              cellA1.setCellValue(row.getAttribute("InvoicePrice").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 15);
                          if(row.getAttribute("PayOtherCost")!=null)
                              cellA1.setCellValue(row.getAttribute("PayOtherCost").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 16);
                          if(row.getAttribute("VarianceAmt")!=null)
                              cellA1.setCellValue(row.getAttribute("VarianceAmt").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 17);
                          if(row.getAttribute("VariancePct")!=null)
                              cellA1.setCellValue(row.getAttribute("VariancePct").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 18);
                          if(row.getAttribute("Quantity")!=null)
                              cellA1.setCellValue(row.getAttribute("Quantity").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 19);
                          if(row.getAttribute("MerchantName")!=null)
                              cellA1.setCellValue(row.getAttribute("MerchantName").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 20);
                          if(row.getAttribute("SystemUpdateDate")!=null)
                              cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("SystemUpdateDate")));
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 21);
                          if(row.getAttribute("CostEffectiveDate")!=null)
                              cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("CostEffectiveDate")));
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 22);
                          if(row.getAttribute("PoType")!=null&&row.getAttribute("PoType").toString().contains("FrontDoor"))
                              cellA1.setCellValue("Y");
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 23);
                          if(row.getAttribute("PoType")!=null&& row.getAttribute("PoType").toString().contains("DropShip"))
                              cellA1.setCellValue("Y");
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 24);
                          if(row.getAttribute("VendorAsstName")!=null)
                              cellA1.setCellValue(row.getAttribute("VendorAsstName").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 25);
                          if(row.getAttribute("MemoComments")!=null)
                              cellA1.setCellValue(row.getAttribute("MemoComments").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 26);
                          if(row.getAttribute("Vpc")!=null)
                              cellA1.setCellValue(row.getAttribute("Vpc").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 27);
                          if(row.getAttribute("CreationDate")!=null)
                              cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("CreationDate")));
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 28);
                          if(row.getAttribute("InvoiceStatus")!=null)
                              cellA1.setCellValue(row.getAttribute("InvoiceStatus").toString());
                          else
                              cellA1.setCellValue("");                                                       cellA1 = excelrow.createCell((short) 22);
                          
                          
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
                                                        cellA1.setCellValue("SKU #");
                                                        cellA1 = excelrow.createCell((short) 1);
                                                        cellA1.setCellValue("SKU Desc");
                                                        cellA1 = excelrow.createCell((short) 2);
                                                        cellA1.setCellValue("Dept");
                                                        cellA1 = excelrow.createCell((short) 3);
                                                        cellA1.setCellValue("Supplier #");
                                                        cellA1 = excelrow.createCell((short) 4);
                                                        cellA1.setCellValue("Supplier Name");
                                                        cellA1 = excelrow.createCell((short) 5);
                                                        cellA1.setCellValue("Supplier Site");
                                                        cellA1 = excelrow.createCell((short) 6);
                                                        cellA1.setCellValue("Answer");
                                                        cellA1 = excelrow.createCell((short) 7);
                                                        cellA1.setCellValue("Answer Date");
                                                        cellA1 = excelrow.createCell((short) 8);
                                                        cellA1.setCellValue("PO #");
                                                        cellA1 = excelrow.createCell((short) 9);
                                                        cellA1.setCellValue("Location");
                                                        cellA1 = excelrow.createCell((short) 10);
                                                        cellA1.setCellValue("Invoice #");
                                                        cellA1 = excelrow.createCell((short) 11);
                                                        cellA1.setCellValue("Invoice Date");
                                                        cellA1 = excelrow.createCell((short) 12);
                                                        cellA1.setCellValue("PO Date");
                                                        cellA1 = excelrow.createCell((short) 13);
                                                        cellA1.setCellValue("PO Cost");
                                                        cellA1 = excelrow.createCell((short) 14);
                                                        cellA1.setCellValue("Invoice Cost");
                                                        cellA1 = excelrow.createCell((short) 15);
                                                        cellA1.setCellValue("Correct Cost");
                                                        cellA1 = excelrow.createCell((short) 16);
                                                        cellA1.setCellValue("Variance $");
                                                        cellA1 = excelrow.createCell((short) 17);
                                                        cellA1.setCellValue("Percentage %");
                                                        cellA1 = excelrow.createCell((short) 18);
                                                        cellA1.setCellValue("Quantity");
                                                        cellA1 = excelrow.createCell((short) 19);
                                                        cellA1.setCellValue("Merchant Name");
                                                        cellA1 = excelrow.createCell((short) 20);
                                                        cellA1.setCellValue("System Update Date");
                                                        cellA1 = excelrow.createCell((short) 21);
                                                        cellA1.setCellValue("Cost Effective Date");
                                                        cellA1 = excelrow.createCell((short) 22);
                                                        cellA1.setCellValue("FD");
                                                        cellA1 = excelrow.createCell((short) 23);
                                                        cellA1.setCellValue("DS");
                                                        cellA1 = excelrow.createCell((short) 24);
                                                        cellA1.setCellValue("Vendor Assistant");
                                                        cellA1 = excelrow.createCell((short) 25);
                                                        cellA1.setCellValue("Memo");
                                                        cellA1 = excelrow.createCell((short) 26);
                                                        cellA1.setCellValue("VPC");
                                                        cellA1 = excelrow.createCell((short) 27);
                                                        cellA1.setCellValue("Creation Date");
                                                        cellA1 = excelrow.createCell((short) 28);
                                                        cellA1.setCellValue("Invoice Status");
                                                            
                                                        
                                                    }
     
                                                    //print data from second row in excel
                                                    ++i;
                                                    short j = 0;
                                                    
                                                      excelrow = worksheet.createRow((short)i);
                                                    
                                                       HSSFCell cellA1=null;
                                                       cellA1 = excelrow.createCell((short) 0);
                                                       if(row.getAttribute("Sku")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Sku").toString());
                                                       else
                                                           cellA1.setCellValue("");  
                                                       cellA1 = excelrow.createCell((short) 1);
                                                       if(row.getAttribute("SkuDescription")!=null)
                                                           cellA1.setCellValue(row.getAttribute("SkuDescription").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 2);
                                                       if(row.getAttribute("Dept")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Dept").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 3);
                                                       if(row.getAttribute("VendorNo")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VendorNo").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 4);
                                                       if(row.getAttribute("VendorName")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VendorName").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 5);
                                                       if(row.getAttribute("VendorSiteCode")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VendorSiteCode").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 6);
                                                       if(row.getAttribute("AnswerCode")!=null)
                                                           cellA1.setCellValue(row.getAttribute("AnswerCode").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 7);
                                                       if(row.getAttribute("AnswerDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("AnswerDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 8);
                                                       if(row.getAttribute("PoNum")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PoNum").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 9);
                                                       if(row.getAttribute("Location")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Location").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 10);
                                                       if(row.getAttribute("InvoiceNum")!=null)
                                                           cellA1.setCellValue(row.getAttribute("InvoiceNum").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 11);
                                                       if(row.getAttribute("InvoiceDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("InvoiceDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 12);
                                                       if(row.getAttribute("PoDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("PoDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 13);
                                                       if(row.getAttribute("PoCost")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PoCost").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 14);
                                                       if(row.getAttribute("InvoicePrice")!=null)
                                                           cellA1.setCellValue(row.getAttribute("InvoicePrice").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 15);
                                                       if(row.getAttribute("PayOtherCost")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PayOtherCost").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 16);
                                                       if(row.getAttribute("VarianceAmt")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VarianceAmt").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 17);
                                                       if(row.getAttribute("VariancePct")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VariancePct").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 18);
                                                       if(row.getAttribute("Quantity")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Quantity").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 19);
                                                       if(row.getAttribute("MerchantName")!=null)
                                                           cellA1.setCellValue(row.getAttribute("MerchantName").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 20);
                                                       if(row.getAttribute("SystemUpdateDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("SystemUpdateDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 21);
                                                       if(row.getAttribute("CostEffectiveDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("CostEffectiveDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 22);
                                                       if(row.getAttribute("PoType")!=null&&row.getAttribute("PoType").toString().contains("FrontDoor"))
                                                           cellA1.setCellValue("Y");
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 23);
                                                       if(row.getAttribute("PoType")!=null&& row.getAttribute("PoType").toString().contains("DropShip"))
                                                           cellA1.setCellValue("Y");
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 24);
                                                       if(row.getAttribute("VendorAsstName")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VendorAsstName").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 25);
                                                       if(row.getAttribute("MemoComments")!=null)
                                                           cellA1.setCellValue(row.getAttribute("MemoComments").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 26);
                                                       if(row.getAttribute("Vpc")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Vpc").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 27);
                                                       if(row.getAttribute("CreationDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("CreationDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 28);
                                                       if(row.getAttribute("InvoiceStatus")!=null)
                                                           cellA1.setCellValue(row.getAttribute("InvoiceStatus").toString());
                                                       else
                                                           cellA1.setCellValue("");                                                       cellA1 = excelrow.createCell((short) 22);
                                                       
                                                   
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
