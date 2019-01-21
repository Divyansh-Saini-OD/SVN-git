package od.tdmatch.view.managedBeans;

import java.io.IOException;
import java.io.OutputStream;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

//import javax.faces.el.ValueBinding;

import javax.faces.event.ActionEvent;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;

import oracle.adf.model.binding.DCIteratorBinding;
import oracle.adf.view.rich.component.rich.data.RichTable;
import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.OperationBinding;

import oracle.jbo.ApplicationModule;

import oracle.jbo.Row;
import oracle.jbo.ViewCriteria;
import oracle.jbo.ViewCriteriaRow;
import oracle.jbo.ViewObject;

import oracle.jbo.uicli.binding.JUCtrlRangeBinding;

import org.apache.myfaces.trinidad.bean.ValueExpressionValueBinding;
import org.apache.poi.hssf.usermodel.HSSFCell;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;

public class InvWkBenchCommonBean {
    private boolean showAllVA = true;
    private DCBindingContainer bindingContainer;
        private String tableBindingName;
        private String attributeNames;
    private RichTable tableBinding;

    public InvWkBenchCommonBean() {
        super();
    }
    
    public void toggleQryPanel(){
        System.out.println("in toggleQryPanel");
    }
    public void executeVAEmpVendorSummaryVODirect(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("executeVAEmpVendorSummaryDirect");
        //  String abc=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pEmployeeId").toString();//"213305";//

        //   System.out.println("The Vendor Assistant selected is: "+abc);

          //   operation.getParamsMap().put("pEmployeeId", abc);
              operation.execute();
    }
    public void executeVAEmpVendorSummaryVO(){
        
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("executeVAEmpVendorSummary");
          String abc=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pEmployeeId").toString();//"213305";//

           System.out.println("The Vendor Assistant selected is: "+abc);

              operation.getParamsMap().put("pEmployeeId", abc);
              operation.execute();              
        
    }
    
    public void executeVendorMootDtVO(){
        
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("executeVendorMootDtVODrill");
        String mSuppName=null;
            if(AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppName")!=null)
             mSuppName=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppName").toString();
        String mSuppSite=null;
            if(AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppSite")!=null)
             mSuppSite=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppSite").toString();
        
            String pMoot = null;
            String pNrf = null;
            String pDisc=null;
            if (AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pMoot")!=null){
            pMoot=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pMoot").toString();
            }
            if (AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pNrf")!=null){
            pNrf=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pNrf").toString();
            }
            if (AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppSite")!=null){
            mSuppSite=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppSite").toString();
            }
            if (AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mDisc")!=null){
            pDisc=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mDisc").toString();
            }
            if(mSuppName!=null ||pMoot!=null||pNrf!=null||mSuppSite!=null||pDisc!=null){
                AdfFacesContext.getCurrentInstance().getPageFlowScope().put("fromsecond", "Y");
            }
            AdfFacesContext.getCurrentInstance().getPageFlowScope().put("pMoot", null);
            AdfFacesContext.getCurrentInstance().getPageFlowScope().put("pNrf", null);
            AdfFacesContext.getCurrentInstance().getPageFlowScope().put("mSuppSite", null);
            AdfFacesContext.getCurrentInstance().getPageFlowScope().put("mDisc", null);
            AdfFacesContext.getCurrentInstance().getPageFlowScope().put("mSuppName", null);
//        String vaName=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pVAName").toString();
    //           String bca = null;
           System.out.println("The Supplier selected is: "+mSuppName);
          // String name="toVA";
            operation.getParamsMap().put("pSupplierName", mSuppName);
            operation.getParamsMap().put("pSupplierSite", mSuppSite);
            operation.getParamsMap().put("pMoot", pMoot);
            operation.getParamsMap().put("pNrf", pNrf);
        operation.getParamsMap().put("pDisc", pDisc);
//              operation.getParamsMap().put("pVAName", vaName);
              operation.execute();
    }
    
    public void executeSupplerSiteVO(){
        
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("executeSupplerSiteVO");
          String abc=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppName").toString();
    //           String bca = null;
           System.out.println("(executeSupplerSiteVO) The Supplier selected is: "+abc);
          // String name="toVA";
              operation.getParamsMap().put("pSupplierName", abc);
              operation.execute();
    }
    
    public void invoiceDetails(){
        
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initInvoiceDetails");
        System.out.println("inside the method invoiceDetails");
         //  String abc="ABC";
          // String name="toVA";
        String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
        System.out.println("The invoiceNo selected is: "+invoiceNo);
              operation.getParamsMap().put("invoiceNum", invoiceNo);
              operation.execute();
        
    }
    
    public String EmpVendSearchAction() {
            // Add event code here...
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("EmpVendSearchAction");
    
            String result=null;
                 result=(String) operation.execute();
//                 load=true;
    
                 FacesMessage fm=new FacesMessage(result);
                 fm.setSeverity(FacesMessage.SEVERITY_ERROR);
                 FacesContext context=FacesContext.getCurrentInstance();
                 if(result!=null)
                 context.addMessage(null, fm);
            return null;
        }
    
    public String EmpVendSearchAction1() {
            // Add event code here...
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("EmpVendSearchAction1");
    
            String result=null;
                 result=(String) operation.execute();
    //                 load=true;
    
                 FacesMessage fm=new FacesMessage(result);
                 fm.setSeverity(FacesMessage.SEVERITY_ERROR);
                 FacesContext context=FacesContext.getCurrentInstance();
                 if(result!=null)
                 context.addMessage(null, fm);
            return null;
        }
    
    public void clearEmpVendSearch(ActionEvent actionEvent){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        System.out.println("Clear button is clicked");
        OperationBinding operation = bindings.getOperationBinding("clearEmpVendSearch");
        
              operation.execute();
        System.out.println("Clear button logic is executed");
              
    }


    public void doExport(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bc = getBindingContainer();
                //DCIteratorBinding booksIter = bc.findIteratorBinding("BooksViewIterator");
                JUCtrlRangeBinding tableBinding = 
                    (JUCtrlRangeBinding)bc.getControlBinding(getTableBindingName());

                DCIteratorBinding iter = tableBinding.getIteratorBinding();

                //String [] attributes = tableBinding.getAttributeNames();
                String[] attributes = 
                    commaSeparatedStringToStringArray(getAttributeNames());
                //String[] attributes = {"Title","AuthorsDisplayNames","PublishYear","PublisherName"};

        //        tableBinding.setRangeStart(0);
                //createXLS(iter, attributes, "ExcelExport.xls");
                
                //empIter.executeQuery();
    }
    private String[] commaSeparatedStringToStringArray(String aString) {
            String[] splittArray = null;
            if (aString != null || !aString.equalsIgnoreCase("")) {
                splittArray = aString.split(",");
                System.out.println(aString + " " + splittArray);
            }
            return splittArray;
        }

    public void setBindingContainer(DCBindingContainer bindingContainer) {
        this.bindingContainer = bindingContainer;
    }

    public DCBindingContainer getBindingContainer() {
        return bindingContainer;
    }

    public void setTableBindingName(String tableBindingName) {
        this.tableBindingName = tableBindingName;
    }

    public String getTableBindingName() {
        return tableBindingName;
    }

    public void setAttributeNames(String attributeNames) {
        this.attributeNames = attributeNames;
    }

    public String getAttributeNames() {
        return attributeNames;
    }

    public void setTableBinding(RichTable tableBinding) {
        this.tableBinding = tableBinding;
    }

    public RichTable getTableBinding() {
        return tableBinding;
    }
    public void generateExcel(FacesContext facesContext, OutputStream outputStream) throws IOException {
              try {
              
                                 
                                    HSSFWorkbook workbook = new HSSFWorkbook();
                                        HSSFSheet worksheet = workbook.createSheet("Worksheet");
                   
                                    DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
                                    DCIteratorBinding dcIteratorBindings = bindings.findIteratorBinding("VAInvoiceSummaryVO2Iterator");
                                    HSSFRow  excelrow = null;
                   
                                            // Get all the rows of a iterator
                                         //   long count = dcIteratorBindings.getEstimatedRowCount();
                                       // int total=Math.toIntExact(count);
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
                                                        cellA1.setCellValue("Invoice Count");
                                                        cellA1 = excelrow.createCell((short) 2);
                                                        cellA1.setCellValue("Invoice Amount $");
                                                        cellA1 = excelrow.createCell((short) 3);
                                                        cellA1.setCellValue("Invoice Lines On Hold $");
                                                        cellA1 = excelrow.createCell((short) 4);
                                                        cellA1.setCellValue("MOOT");
                                                        cellA1 = excelrow.createCell((short) 5);
                                                        cellA1.setCellValue("MOOT Amount $");
                                                        cellA1 = excelrow.createCell((short) 6);
                                                        cellA1.setCellValue("MOOT Hold Amt $");
                                                        cellA1 = excelrow.createCell((short) 7);
                                                        cellA1.setCellValue("NRF");
                                                        cellA1 = excelrow.createCell((short) 8);
                                                        cellA1.setCellValue("NRF Amount $");
                                                        
                                                            
                                                        
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
                                                       if(row.getAttribute("TotalInvCount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalInvCount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 2);
                                                       if(row.getAttribute("TotalInvAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalInvAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 3);
                                                       if(row.getAttribute("TotalLineAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalLineAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 4);
                                                       if(row.getAttribute("TotalMootCount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalMootCount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 5);
                                                       if(row.getAttribute("TotalMootInvAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalMootInvAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 6);
                                                       if(row.getAttribute("TotalMootLineAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalMootLineAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 7);
                                                       if(row.getAttribute("TotalNrfCount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalNrfCount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 8);
                                                       if(row.getAttribute("TotalNrfAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalNrfAmount").toString());
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
    public void generateExcelEmpSummary(FacesContext facesContext, OutputStream outputStream) throws IOException {
              try {
              
                                 
                                    HSSFWorkbook workbook = new HSSFWorkbook();
                                        HSSFSheet worksheet = workbook.createSheet("Worksheet");
                   
                                    DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
                                    DCIteratorBinding dcIteratorBindings = bindings.findIteratorBinding("VAEmpVendorSummaryVO3Iterator");
                                    HSSFRow  excelrow = null;
                   
                                            // Get all the rows of a iterator
                                         //   long count = dcIteratorBindings.getEstimatedRowCount();
                                       // int total=Math.toIntExact(count);
                                        int i = 0;
                                   Row row=null;
                  if(dcIteratorBindings==null)
                      dcIteratorBindings = bindings.findIteratorBinding("VAEmpVendorSummaryVO1Iterator");
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
                           cellA1.setCellValue("Invoice Count");
                           cellA1 = excelrow.createCell((short) 6);
                           cellA1.setCellValue("Invoice Amount $");
                           cellA1 = excelrow.createCell((short) 7);
                           cellA1.setCellValue("Invoice Lines On Hold $");
                           cellA1 = excelrow.createCell((short) 8);
                           cellA1.setCellValue("MOOT");
                           cellA1 = excelrow.createCell((short) 9);
                           cellA1.setCellValue("MOOT Amount $");
                           cellA1 = excelrow.createCell((short) 10);
                           cellA1.setCellValue("MOOT Hold Amount $");
                           cellA1 = excelrow.createCell((short) 11);
                           cellA1.setCellValue("NRF");
                           cellA1 = excelrow.createCell((short) 12);
                           cellA1.setCellValue("NRF Amount $");
                           
                               
                           
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
                          if(row.getAttribute("VendorName")!=null)
                              cellA1.setCellValue(row.getAttribute("VendorName").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 2);
                          if(row.getAttribute("Supplier")!=null)
                              cellA1.setCellValue(row.getAttribute("Supplier").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 3);
                          if(row.getAttribute("VendorSiteCode")!=null)
                              cellA1.setCellValue(row.getAttribute("VendorSiteCode").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 4);
                          if(row.getAttribute("Disc")!=null)
                              cellA1.setCellValue(row.getAttribute("Disc").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 5);
                          if(row.getAttribute("TotalInvCount")!=null)
                              cellA1.setCellValue(row.getAttribute("TotalInvCount").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 6);
                          if(row.getAttribute("TotalInvAmount")!=null)
                              cellA1.setCellValue(row.getAttribute("TotalInvAmount").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 7);
                          if(row.getAttribute("TotalLineAmount")!=null)
                              cellA1.setCellValue(row.getAttribute("TotalLineAmount").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 8);
                          if(row.getAttribute("TotalMootCount")!=null)
                              cellA1.setCellValue(row.getAttribute("TotalMootCount").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 9);
                          if(row.getAttribute("TotalMootInvAmount")!=null)
                              cellA1.setCellValue(row.getAttribute("TotalMootInvAmount").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 10);
                          if(row.getAttribute("TotalMootLineAmount")!=null)
                              cellA1.setCellValue(row.getAttribute("TotalMootLineAmount").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 11);
                          if(row.getAttribute("TotalNrfCount")!=null)
                              cellA1.setCellValue(row.getAttribute("TotalNrfCount").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 12);
                          if(row.getAttribute("TotalNrfAmount")!=null)
                              cellA1.setCellValue(row.getAttribute("TotalNrfAmount").toString());
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
                                                        cellA1.setCellValue("Invoice Count");
                                                        cellA1 = excelrow.createCell((short) 6);
                                                        cellA1.setCellValue("Invoice Amount $");
                                                        cellA1 = excelrow.createCell((short) 7);
                                                        cellA1.setCellValue("Invoice Lines On Hold $");
                                                        cellA1 = excelrow.createCell((short) 8);
                                                        cellA1.setCellValue("MOOT");
                                                        cellA1 = excelrow.createCell((short) 9);
                                                        cellA1.setCellValue("MOOT Amount $");
                                                        cellA1 = excelrow.createCell((short) 10);
                                                        cellA1.setCellValue("MOOT Hold Amount $");
                                                        cellA1 = excelrow.createCell((short) 11);
                                                        cellA1.setCellValue("NRF");
                                                        cellA1 = excelrow.createCell((short) 12);
                                                        cellA1.setCellValue("NRF Amount $");
                                                        
                                                            
                                                        
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
                                                       if(row.getAttribute("VendorName")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VendorName").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 2);
                                                       if(row.getAttribute("Supplier")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Supplier").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 3);
                                                       if(row.getAttribute("VendorSiteCode")!=null)
                                                           cellA1.setCellValue(row.getAttribute("VendorSiteCode").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 4);
                                                       if(row.getAttribute("Disc")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Disc").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 5);
                                                       if(row.getAttribute("TotalInvCount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalInvCount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 6);
                                                       if(row.getAttribute("TotalInvAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalInvAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 7);
                                                       if(row.getAttribute("TotalLineAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalLineAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 8);
                                                       if(row.getAttribute("TotalMootCount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalMootCount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 9);
                                                       if(row.getAttribute("TotalMootInvAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalMootInvAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 10);
                                                       if(row.getAttribute("TotalMootLineAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalMootLineAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 11);
                                                       if(row.getAttribute("TotalNrfCount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalNrfCount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 12);
                                                       if(row.getAttribute("TotalNrfAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("TotalNrfAmount").toString());
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
}
