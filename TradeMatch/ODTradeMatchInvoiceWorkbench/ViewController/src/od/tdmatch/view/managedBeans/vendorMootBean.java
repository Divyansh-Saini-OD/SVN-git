package od.tdmatch.view.managedBeans;

import java.io.IOException;
import java.io.OutputStream;

import java.text.DateFormat;
import java.text.SimpleDateFormat;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import javax.faces.application.FacesMessage;
import javax.faces.component.UIComponent;
import javax.faces.context.ExternalContext;
import javax.faces.context.FacesContext;
import javax.faces.event.ActionEvent;

import javax.faces.model.SelectItem;

import javax.servlet.http.HttpServletResponse;

import od.tdmatch.view.ExcelExporter;

import oracle.adf.model.binding.DCBindingContainer;
import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCIteratorBinding;
import oracle.adf.share.ADFContext;

import oracle.binding.OperationBinding;

import oracle.jbo.AttributeDef;
import oracle.jbo.AttributeHints;
import oracle.jbo.LocaleContext;
import oracle.jbo.NavigatableRowIterator;
import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;
import oracle.jbo.ViewObject;
import oracle.jbo.common.DefLocaleContext;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

import org.apache.poi.hssf.usermodel.HSSFCell;
import org.apache.poi.hssf.usermodel.HSSFCellStyle;
import org.apache.poi.hssf.usermodel.HSSFDataFormat;
import org.apache.poi.hssf.usermodel.HSSFFont;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.hssf.util.HSSFColor;

//import org.apache.myfaces.trinidadinternal.taglib.listener.ResetActionListener;

public class vendorMootBean {
    Boolean load=false;
    public vendorMootBean() {
        super();
    }
    public String vendMootSearchAction() {
            // Add event code here...
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("vendMootSearchAction");
    
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
    public void clearVendMootSearch(ActionEvent actionEvent){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        System.out.println("Clear button is clicked");
        OperationBinding operation = bindings.getOperationBinding("clearVendMootSearch");
        
              operation.execute();
        System.out.println("Clear button logic is executed");
              
    }
    
    public String vendMootDshipSearchAction() {
            // Add event code here...
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("vendMootDshipSearchAction");
    
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
    public void clearVendMootDShipSearch(ActionEvent actionEvent){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        System.out.println("Clear button is clicked");
        OperationBinding operation = bindings.getOperationBinding("clearVendMootDShipSearch");
        
              operation.execute();
        System.out.println("Clear button logic is executed");
        /*UIComponent myForm = actionEvent.getComponent();
        oracle.adf.view.rich.util.ResetUtils.reset(myForm);*/
        /*ResetActionListener ral = new ResetActionListener();
        ral.processAction(actionEvent);*/
              
    }
    private String tableBindingName;
    private String defaultAttributeNames;
    private String[] allAttributeNames;
    private String[] allAttributeLabels;
    private String[] attributes;
    private String filename = "ExcelExport.xls";
    //  private JUCtrlRangeBinding tableBinding;
    private String containerName;
    private boolean pivot = false;
    private String dataSetType="range";
    private long numberOfRows;
    private long startRow;
    private long endRow;

   


    public String exportThisTableToExcel() {
    //    DCBindingContainer bc = getBindingContainer();
    //    this.containerName = bc.getName();
    //        JUCtrlRangeBinding tableBinding =
    //            (JUCtrlRangeBinding)bc.getControlBinding(getTableBindingName());

      //  DCIteratorBinding iter = tableBinding.getIteratorBinding();
      DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
      DCIteratorBinding iter=bindings.findIteratorBinding("VendMootDtVO1Iterator");
        numberOfRows=iter.getEstimatedRowCount();
        //String [] attributes = tableBinding.getAttributeNames();
        // default selected attributes:
        
      //  attributes = commaSeparatedStringToStringArray(getDefaultAttributeNames());
        RowSetIterator rsi = iter.getRowSetIterator();
                 attributes = rsi.getRowAtRangeIndex(0).getAttributeNames();
        allAttributeNames = rsi.getRowAtRangeIndex(0).getAttributeNames();
        allAttributeLabels = rsi.getRowAtRangeIndex(0).getAttributeNames();
     //   allAttributeNames = (String[])tableBinding.getAttributeNames().clone();
       // allAttributeLabels = (String[])tableBinding.getAttributeNames().clone();
    //* show item labels instead of item names in Shuttle
         AttributeDef[] attr = iter.getAttributeDefs(allAttributeNames);
        for (int i=0;i<allAttributeNames.length;i++) {
            AttributeHints hints = attr[i].getUIHelper();
            String label = hints.getLabel(getLocaleContext());

          allAttributeLabels[i]= label;   
        }
     
        return "dialog:ExcelPopup";
    }

    public String doExport() {


      //  DCBindingContainer bc = prepareBindingContainer(this.containerName);
       // JUCtrlRangeBinding tableBinding = 
         //   (JUCtrlRangeBinding)bc.getControlBinding(getTableBindingName());

      //  DCIteratorBinding iter = tableBinding.getIteratorBinding();
      DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
      DCIteratorBinding iter=bindings.findIteratorBinding("VendMootDtVO1Iterator");
      //  DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
       // DCIteratorBinding iter=bindings.findIteratorBinding("VendMootDtVO1Iterator");
          numberOfRows=iter.getEstimatedRowCount();
          //String [] attributes = tableBinding.getAttributeNames();
          // default selected attributes:
        //  attributes = commaSeparatedStringToStringArray(getDefaultAttributeNames());
          RowSetIterator rsi = iter.getRowSetIterator();
                   allAttributeNames = rsi.getRowAtRangeIndex(0).getAttributeNames();
        attributes = rsi.getRowAtRangeIndex(0).getAttributeNames();
      //  attributes = commaSeparatedStringToStringArray(attributes);
          allAttributeLabels = rsi.getRowAtRangeIndex(0).getAttributeNames();
        //   allAttributeNames = (String[])tableBinding.getAttributeNames().clone();
         // allAttributeLabels = (String[])tableBinding.getAttributeNames().clone();
        //* show item labels instead of item names in Shuttle
           AttributeDef[] attr = iter.getAttributeDefs(allAttributeNames);
          for (int i=0;i<allAttributeNames.length;i++) {
              AttributeHints hints = attr[i].getUIHelper();
              String label = hints.getLabel(getLocaleContext());

            allAttributeLabels[i]= label;   
          }

        // export all rows or just the ones starting with the current range
         NavigatableRowIterator naviter=  iter.getNavigatableRowIterator();
        int originalRangeStart = iter.getRangeStart();
        int originalRangeIndex = iter.getCurrentRowIndexInRange();
        int originalIndex = naviter.getCurrentRowIndex();
        long maxrowcount = iter.getEstimatedRowCount(); 
        String currentRowKey = iter.getCurrentRowKeyString();
        if (getDataSetType()==null) {setDataSetType("range");}
        if (getDataSetType().equalsIgnoreCase("all")) {
            naviter.setRangeStart(0);
            naviter.first();
        }
        else if (getDataSetType().equalsIgnoreCase("specialrange")) {
            maxrowcount= getEndRow() - getStartRow()+1;            
            naviter.scrollRange((int)getStartRow()-1);
            naviter.setCurrentRowAtRangeIndex(0);
        }
        else { // current range only
            naviter.setRangeStart(originalRangeStart);
            naviter.setCurrentRowAtRangeIndex(0);
            maxrowcount = naviter.getRangeSize();
        }

      //  AttributeDef[] attr = iter.getAttributeDefs(getAttributes());
        createXLS((RowSetIterator)naviter, 
                (AttributeDef[])iter.getAttributeDefs(getAttributes()), getAttributes(), getFilename(), maxrowcount);
        iter.setRangeStart(originalRangeStart);
        iter.setCurrentRowIndexInRange(originalIndex);
        iter.setCurrentRowWithKey(currentRowKey);
        return "";
    }


    public void createXLS(RowSetIterator iter, AttributeDef[] attr,String[] attributes, 
                          String filename, long maxrowcount) {

        ExternalContext ectx = 
            FacesContext.getCurrentInstance().getExternalContext();
        HttpServletResponse response = (HttpServletResponse)ectx.getResponse();
        try {
            OutputStream out = response.getOutputStream();
            response.setContentType("application/vnd.ms-excel");
            response.setHeader("Content-disposition", 
                               "attachment; filename=" + filename);
            HSSFWorkbook workbook = createWorkbook(iter, attr, attributes, maxrowcount);
            workbook.write(out);
            out.flush();
            out.close();
            FacesContext.getCurrentInstance().responseComplete();

        } catch (IOException ex) {
            ex.printStackTrace();
        }
    }


    private HSSFWorkbook createWorkbook(RowSetIterator iter, AttributeDef[] attr,
                                        String[] attributes, long maxrowcount) throws IOException {
        // see: http://www.onjava.com/pub/a/onjava/2003/04/16/poi_excel.html         
        // http://jakarta.apache.org/poi/hssf/how-to.html
        // http://www.regdeveloper.co.uk/2006/01/27/poi_tutorial/page2.html
        // http://www.brainbell.com/tutorials/ms-office/excel/Create_Excel_Spreadsheets_Using_Other_Environments.htm
        HSSFWorkbook wb = new HSSFWorkbook();
        HSSFSheet sheet = wb.createSheet("AMISLibrary1");

        int idx = 0; // rows index
        HSSFRow row = sheet.createRow((short)idx);
    //        ViewObject vo = iter.getViewObject();
        //A font style of bold for column headings is configured as follows:

        HSSFFont boldFont = wb.createFont();
        boldFont.setColor(HSSFColor.YELLOW.index);
        boldFont.setBoldweight(HSSFFont.BOLDWEIGHT_BOLD);
        boldFont.setFontHeightInPoints((short)18);
        HSSFCellStyle boldStyle = wb.createCellStyle();
        boldStyle.setFont(boldFont);
        boldStyle.setFillBackgroundColor(HSSFColor.CORNFLOWER_BLUE.index);
        HSSFCellStyle style = wb.createCellStyle();
        style.setDataFormat(HSSFDataFormat.getBuiltinFormat("($#,##0_);[Red]($#,##0)"));
        style.setFillBackgroundColor(HSSFColor.AQUA.index);
        style.setFillPattern(HSSFCellStyle.BIG_SPOTS);


        /******************************** Creating headers ************************************/
        //attr = iter.getAttributeDefs(attributes);
        for (int i = 0; i < attr.length; i++) {
            AttributeHints hints = attr[i].getUIHelper();
            String label = hints.getLabel(getLocaleContext());
            row.createCell((short)i).setCellValue((String)label);
            row.getCell((short)i).setCellStyle(boldStyle);
        }
        idx++;

        /******************************* Creating first row **************************************/
        Row fr = iter.getCurrentRow();
        long rowcount =1;
        row = sheet.createRow((short)idx);
        /******************************** Creating cells *************************************/
        for (int j = 0; j < attributes.length; j++) {
            HSSFCell cell = row.createCell((short)j);
            //cell.setCellStyle(style);
            Object value = fr.getAttribute(attributes[j]);
            setConvertedCellValue(wb, cell, value);
        }
        idx++;

         
        /******************************** Creating rows ****************************************/
         while (iter.hasNext() && ++rowcount<= maxrowcount) {
             //if (++rowcount> maxrowcount) break;
            Row r = iter.next();
            row = sheet.createRow((short)idx);
            /******************************** Creating cels *************************************/
            for (int j = 0; j < attributes.length; j++) {
                HSSFCell cell = row.createCell((short)j);
                Object value = r.getAttribute(attributes[j]);
                setConvertedCellValue(wb, cell, value);
            }
            idx++;
        }

        return wb;
    }


    private void setConvertedCellValue(HSSFWorkbook wb, HSSFCell cell, 
                                       Object value) {

        if (value instanceof Number) {
            Number number = (Number)value;
            cell.setCellType(HSSFCell.CELL_TYPE_NUMERIC);
            cell.setCellValue((Double)number.getValue());
        }

        if (value instanceof Date) {
            Date adfdate = (Date)value;
            java.util.Date date = adfdate.getValue();
            HSSFCellStyle cellStyle = wb.createCellStyle();
            cellStyle.setDataFormat(HSSFDataFormat.getBuiltinFormat("m/d/yy"));
            cell.setCellType(HSSFCell.CELL_TYPE_NUMERIC);
            cell.setCellValue((java.util.Date)date);
            cell.setCellStyle(cellStyle);

        }

        if (value instanceof String) {
            String string = (String)value;
            cell.setCellType(HSSFCell.CELL_TYPE_STRING);
            cell.setCellValue((String)string);
        }
    }

    private LocaleContext getLocaleContext() {
        Locale locale = 
            FacesContext.getCurrentInstance().getViewRoot().getLocale();
        LocaleContext lc = new DefLocaleContext(locale);
        return lc;
    }

    private String[] commaSeparatedStringToStringArray(String aString) {
        String[] splittArray = null;
        if (aString != null || !aString.equalsIgnoreCase("")) {
            splittArray = aString.split(",");
            System.out.println(aString + " " + splittArray);
        }
        return splittArray;
    }


    public DCBindingContainer getBindingContainer() {
        FacesContext ctx = FacesContext.getCurrentInstance();
        javax.faces.el.ValueBinding binding = 
            ctx.getApplication().createValueBinding("#{bindings}");
        DCBindingContainer bc = (DCBindingContainer)binding.getValue(ctx);
        return bc;
    }

    public void setTableBindingName(String tableBindingName) {
        this.tableBindingName = tableBindingName;
    }

    public String getTableBindingName() {
        return tableBindingName;
    }


    public void setFilename(String filename) {
        this.filename = filename;
    }

    public String getFilename() {
        return filename;
    }

    private void setAllAttributeNames(String[] allAttributeNames) {
        this.allAttributeNames = allAttributeNames;
    }

    private String[] getAllAttributeNames() {
        return allAttributeNames;
    }

    public List getSiAllAttributes() {
        return getSelectItems(allAttributeLabels, allAttributeNames);
    }

    private List getSelectItems(String[] labels, String[] values) {
        List items = new ArrayList();
        for (int i = 0; i < labels.length; i++) {
            SelectItem item = new SelectItem(values[i], labels[i] ,values[i]+" label:"+labels[i]);
            items.add(item);
        }
        return items;
    }

    public void setAttributes(String[] attributes) {
        this.attributes = attributes;
    }

    public String[] getAttributes() {
        return attributes;
    }

    public void setPivot(boolean pivot) {
        this.pivot = pivot;
    }

    public boolean isPivot() {
        return pivot;
    }

    public void setDataSetType(String dataSetType) {
        this.dataSetType = dataSetType;
    }

    public String getDataSetType() {
        return dataSetType;
    }


    /**
     * Retrieve the BindingContext object for the current session.
     */
    public BindingContext getBindingContext() {
        Map sessionScope = null;

        // When the ADFBindingFilter is missing, the Web environment is not
        // initialized so getEnvironment throws.
        try {
            sessionScope = ADFContext.getCurrent().getSessionScope();
        } catch (UnsupportedOperationException ex) {
            return null;
        }

        // The sessionScope should had been created by the binding filter. 
        // If it's not it mean we are not dealing with a databound page.
        if (sessionScope == null) {
            return null;
        }
        return (BindingContext)sessionScope.get(BindingContext.CONTEXT_ID);
    }

    public DCBindingContainer prepareBindingContainer(String containerName) {
        BindingContext bc = getBindingContext();
        DCBindingContainer container = bc.findBindingContainer(containerName);
        if (container != null) {
            container.refresh(DCBindingContainer.PREPARE_MODEL);
        } else {
            System.out.println("BindingContainer " + container.getName() + 
                               " not found");
        }
        return container;
    }


    public void setNumberOfRows(long numberOfRows) {
        this.numberOfRows = numberOfRows;
    }

    public long getNumberOfRows() {
        return numberOfRows;
    }

    public void setStartRow(long startRow) {
        this.startRow = startRow;
    }

    public long getStartRow() {
        return startRow;
    }

    public void setEndRow(long endRow) {
        this.endRow = endRow;
    }

    public long getEndRow() {
        return endRow;
    }

    public void setAllAttributeLabels(String[] allAttributeLabels) {
        this.allAttributeLabels = allAttributeLabels;
    }

    public String[] getAllAttributeLabels() {
        return allAttributeLabels;
    }

    public void setDefaultAttributeNames(String defaultAttributeNames) {
        this.defaultAttributeNames = defaultAttributeNames;
    }

    public String getDefaultAttributeNames() {
        return defaultAttributeNames;
    }

    public void doExcelExport(ActionEvent actionEvent) {
        // Add event code here...
        //  DCBindingContainer bc = prepareBindingContainer(this.containerName);
         // JUCtrlRangeBinding tableBinding = 
           //   (JUCtrlRangeBinding)bc.getControlBinding(getTableBindingName());

        //  DCIteratorBinding iter = tableBinding.getIteratorBinding();
        // Added GL Date as part of Jira# NAIT-29712
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        DCIteratorBinding iter=bindings.findIteratorBinding("VendMootDtVO1Iterator");
        //  DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
         // DCIteratorBinding iter=bindings.findIteratorBinding("VendMootDtVO1Iterator");
            numberOfRows=iter.getEstimatedRowCount();
            //String [] attributes = tableBinding.getAttributeNames();
            // default selected attributes:
          //  attributes = commaSeparatedStringToStringArray(getDefaultAttributeNames());
            RowSetIterator rsi = iter.getRowSetIterator();
                     allAttributeNames = rsi.getRowAtRangeIndex(0).getAttributeNames();
          attributes = rsi.getRowAtRangeIndex(0).getAttributeNames();
        //  attributes = commaSeparatedStringToStringArray(attributes);
            allAttributeLabels = rsi.getRowAtRangeIndex(0).getAttributeNames();
          //   allAttributeNames = (String[])tableBinding.getAttributeNames().clone();
           // allAttributeLabels = (String[])tableBinding.getAttributeNames().clone();
          //* show item labels instead of item names in Shuttle
             AttributeDef[] attr = iter.getAttributeDefs(allAttributeNames);
            for (int i=0;i<allAttributeNames.length;i++) {
                AttributeHints hints = attr[i].getUIHelper();
                String label = hints.getLabel(getLocaleContext());

              allAttributeLabels[i]= label;   
            }

          // export all rows or just the ones starting with the current range
           NavigatableRowIterator naviter=  iter.getNavigatableRowIterator();
          int originalRangeStart = iter.getRangeStart();
          int originalRangeIndex = iter.getCurrentRowIndexInRange();
          int originalIndex = naviter.getCurrentRowIndex();
          long maxrowcount = iter.getEstimatedRowCount(); 
          String currentRowKey = iter.getCurrentRowKeyString();
          if (getDataSetType()==null) {setDataSetType("range");}
          if (getDataSetType().equalsIgnoreCase("all")) {
              naviter.setRangeStart(0);
              naviter.first();
          }
          else if (getDataSetType().equalsIgnoreCase("specialrange")) {
              maxrowcount= getEndRow() - getStartRow()+1;            
              naviter.scrollRange((int)getStartRow()-1);
              naviter.setCurrentRowAtRangeIndex(0);
          }
          else { // current range only
              naviter.setRangeStart(originalRangeStart);
              naviter.setCurrentRowAtRangeIndex(0);
              maxrowcount = naviter.getRangeSize();
          }

        //  AttributeDef[] attr = iter.getAttributeDefs(getAttributes());
          createXLS((RowSetIterator)naviter, 
                  (AttributeDef[])iter.getAttributeDefs(getAttributes()), getAttributes(), getFilename(), maxrowcount);
          iter.setRangeStart(originalRangeStart);
          iter.setCurrentRowIndexInRange(originalIndex);
          iter.setCurrentRowWithKey(currentRowKey);
        // return "";
    }
    
    public void generateExcel(FacesContext facesContext, OutputStream outputStream) throws IOException {
              try {
              
                                 
                                    HSSFWorkbook workbook = new HSSFWorkbook();
                                        HSSFSheet worksheet = workbook.createSheet("Worksheet");
                   
                                    DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
                                    DCIteratorBinding dcIteratorBindings = bindings.findIteratorBinding("VendMootDtVO1Iterator");
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
                           cellA1.setCellValue("GL Date");
                           cellA1 = excelrow.createCell((short) 9);
                           cellA1.setCellValue("PO#");
                           cellA1 = excelrow.createCell((short) 10);
                           cellA1.setCellValue("Location");
                           cellA1 = excelrow.createCell((short) 11);
                           cellA1.setCellValue("Due Date");
                           cellA1 = excelrow.createCell((short) 12);
                           cellA1.setCellValue("Invoice Amount $");
                           cellA1 = excelrow.createCell((short) 13);
                           cellA1.setCellValue("Qty Hold Amt $");
                           cellA1 = excelrow.createCell((short) 14);
                           cellA1.setCellValue("Price Hold Amt $");
                           cellA1 = excelrow.createCell((short) 15);
                           cellA1.setCellValue("FD");
                           cellA1 = excelrow.createCell((short) 16);
                           cellA1.setCellValue("NC");
                           cellA1 = excelrow.createCell((short) 17);
                           cellA1.setCellValue("Freight Hold");
                               
                           
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
                          if(row.getAttribute("GlDate")!=null)
                              cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("GlDate")));
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 9);
                          if(row.getAttribute("PoNumber")!=null)
                              cellA1.setCellValue(row.getAttribute("PoNumber").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 10);
                          if(row.getAttribute("Location")!=null)
                              cellA1.setCellValue(row.getAttribute("Location").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 11);
                          if(row.getAttribute("DueDate")!=null)
                              cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("DueDate")));
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 12);
                          if(row.getAttribute("InvoiceAmount")!=null)
                              cellA1.setCellValue(row.getAttribute("InvoiceAmount").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 13);
                          if(row.getAttribute("QtyHoldAmt")!=null)
                              cellA1.setCellValue(row.getAttribute("QtyHoldAmt").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 14);
                          if(row.getAttribute("PriceHoldAmt")!=null)
                              cellA1.setCellValue(row.getAttribute("PriceHoldAmt").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 15);
                          if(row.getAttribute("FrontDoorc")!=null)
                              cellA1.setCellValue(row.getAttribute("FrontDoorc").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 16);
                          if(row.getAttribute("NonCodec")!=null)
                              cellA1.setCellValue(row.getAttribute("NonCodec").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 17);
                          if(row.getAttribute("FrtHold")!=null)
                              cellA1.setCellValue(row.getAttribute("FrtHold").toString());
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
                                                        cellA1.setCellValue("Invoice #");
                                                        cellA1 = excelrow.createCell((short) 6);
                                                        cellA1.setCellValue("Voucher");
                                                        cellA1 = excelrow.createCell((short) 7);
                                                        cellA1.setCellValue("Invoice Date");
                                                        cellA1 = excelrow.createCell((short) 8);
                                                        cellA1.setCellValue("GL Date");
                                                        cellA1 = excelrow.createCell((short) 9);
                                                        cellA1.setCellValue("PO#");
                                                        cellA1 = excelrow.createCell((short) 10);
                                                        cellA1.setCellValue("Location");
                                                        cellA1 = excelrow.createCell((short) 11);
                                                        cellA1.setCellValue("Due Date");
                                                        cellA1 = excelrow.createCell((short) 12);
                                                        cellA1.setCellValue("Invoice Amount $");
                                                        cellA1 = excelrow.createCell((short) 13);
                                                        cellA1.setCellValue("Qty Hold Amt $");
                                                        cellA1 = excelrow.createCell((short) 14);
                                                        cellA1.setCellValue("Price Hold Amt $");
                                                        cellA1 = excelrow.createCell((short) 15);
                                                        cellA1.setCellValue("FD");
                                                        cellA1 = excelrow.createCell((short) 16);
                                                        cellA1.setCellValue("NC");
                                                        cellA1 = excelrow.createCell((short) 17);
                                                        cellA1.setCellValue("Freight Hold");
                                                            
                                                        
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
                                                       if(row.getAttribute("GlDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("GlDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 9);
                                                       if(row.getAttribute("PoNumber")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PoNumber").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 10);
                                                       if(row.getAttribute("Location")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Location").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 11);
                                                       if(row.getAttribute("DueDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("DueDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 12);
                                                       if(row.getAttribute("InvoiceAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("InvoiceAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 13);
                                                       if(row.getAttribute("QtyHoldAmt")!=null)
                                                           cellA1.setCellValue(row.getAttribute("QtyHoldAmt").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 14);
                                                       if(row.getAttribute("PriceHoldAmt")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PriceHoldAmt").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 15);
                                                       if(row.getAttribute("FrontDoorc")!=null)
                                                           cellA1.setCellValue(row.getAttribute("FrontDoorc").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 16);
                                                       if(row.getAttribute("NonCodec")!=null)
                                                           cellA1.setCellValue(row.getAttribute("NonCodec").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 17);
                                                       if(row.getAttribute("FrtHold")!=null)
                                                           cellA1.setCellValue(row.getAttribute("FrtHold").toString());
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
    
    public void generateExcelDropship(FacesContext facesContext, OutputStream outputStream) throws IOException {
              try {
              
                                 
                                    HSSFWorkbook workbook = new HSSFWorkbook();
                                        HSSFSheet worksheet = workbook.createSheet("Worksheet");
                   
                                    DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
                                    DCIteratorBinding dcIteratorBindings = bindings.findIteratorBinding("VendMootDtVO2Iterator");
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
                           cellA1.setCellValue("GL Date");
                           cellA1 = excelrow.createCell((short) 9);
                           cellA1.setCellValue("PO#");
                           cellA1 = excelrow.createCell((short) 10);
                           cellA1.setCellValue("Location");
                           cellA1 = excelrow.createCell((short) 11);
                           cellA1.setCellValue("Due Date");
                           cellA1 = excelrow.createCell((short) 12);
                           cellA1.setCellValue("Invoice Amount $");
                           cellA1 = excelrow.createCell((short) 13);
                           cellA1.setCellValue("Qty Hold Amt $");
                           cellA1 = excelrow.createCell((short) 14);
                           cellA1.setCellValue("Price Hold Amt $");
                           cellA1 = excelrow.createCell((short) 15);
                           cellA1.setCellValue("FD");
                           cellA1 = excelrow.createCell((short) 16);
                           cellA1.setCellValue("NC");
                           cellA1 = excelrow.createCell((short) 17);
                           cellA1.setCellValue("Freight Hold");
                               
                           
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
                          if(row.getAttribute("GlDate")!=null)
                              cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("GlDate")));
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 9);
                          if(row.getAttribute("PoNumber")!=null)
                              cellA1.setCellValue(row.getAttribute("PoNumber").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 10);
                          if(row.getAttribute("Location")!=null)
                              cellA1.setCellValue(row.getAttribute("Location").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 11);
                          if(row.getAttribute("DueDate")!=null)
                              cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("DueDate")));
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 12);
                          if(row.getAttribute("InvoiceAmount")!=null)
                              cellA1.setCellValue(row.getAttribute("InvoiceAmount").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 13);
                          if(row.getAttribute("QtyHoldAmt")!=null)
                              cellA1.setCellValue(row.getAttribute("QtyHoldAmt").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 14);
                          if(row.getAttribute("PriceHoldAmt")!=null)
                              cellA1.setCellValue(row.getAttribute("PriceHoldAmt").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 15);
                          if(row.getAttribute("FrontDoorc")!=null)
                              cellA1.setCellValue(row.getAttribute("FrontDoorc").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 16);
                          if(row.getAttribute("NonCodec")!=null)
                              cellA1.setCellValue(row.getAttribute("NonCodec").toString());
                          else
                              cellA1.setCellValue("");
                          cellA1 = excelrow.createCell((short) 17);
                          if(row.getAttribute("FrtHold")!=null)
                              cellA1.setCellValue(row.getAttribute("FrtHold").toString());
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
                                                        cellA1.setCellValue("Invoice #");
                                                        cellA1 = excelrow.createCell((short) 6);
                                                        cellA1.setCellValue("Voucher");
                                                        cellA1 = excelrow.createCell((short) 7);
                                                        cellA1.setCellValue("Invoice Date");
                                                        cellA1 = excelrow.createCell((short) 8);
                                                        cellA1.setCellValue("GL Date");
                                                        cellA1 = excelrow.createCell((short) 9);
                                                        cellA1.setCellValue("PO#");
                                                        cellA1 = excelrow.createCell((short) 10);
                                                        cellA1.setCellValue("Location");
                                                        cellA1 = excelrow.createCell((short) 11);
                                                        cellA1.setCellValue("Due Date");
                                                        cellA1 = excelrow.createCell((short) 12);
                                                        cellA1.setCellValue("Invoice Amount $");
                                                        cellA1 = excelrow.createCell((short) 13);
                                                        cellA1.setCellValue("Qty Hold Amt $");
                                                        cellA1 = excelrow.createCell((short) 14);
                                                        cellA1.setCellValue("Price Hold Amt $");
                                                        cellA1 = excelrow.createCell((short) 15);
                                                        cellA1.setCellValue("FD");
                                                        cellA1 = excelrow.createCell((short) 16);
                                                        cellA1.setCellValue("NC");
                                                        cellA1 = excelrow.createCell((short) 17);
                                                        cellA1.setCellValue("Freight Hold");
                                                            
                                                        
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
                                                       if(row.getAttribute("GlDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("GlDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 9);
                                                       if(row.getAttribute("PoNumber")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PoNumber").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 10);
                                                       if(row.getAttribute("Location")!=null)
                                                           cellA1.setCellValue(row.getAttribute("Location").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 11);
                                                       if(row.getAttribute("DueDate")!=null)
                                                           cellA1.setCellValue(getSimpleDate((oracle.jbo.domain.Date)row.getAttribute("DueDate")));
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 12);
                                                       if(row.getAttribute("InvoiceAmount")!=null)
                                                           cellA1.setCellValue(row.getAttribute("InvoiceAmount").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 13);
                                                       if(row.getAttribute("QtyHoldAmt")!=null)
                                                           cellA1.setCellValue(row.getAttribute("QtyHoldAmt").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 14);
                                                       if(row.getAttribute("PriceHoldAmt")!=null)
                                                           cellA1.setCellValue(row.getAttribute("PriceHoldAmt").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 15);
                                                       if(row.getAttribute("FrontDoorc")!=null)
                                                           cellA1.setCellValue(row.getAttribute("FrontDoorc").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 16);
                                                       if(row.getAttribute("NonCodec")!=null)
                                                           cellA1.setCellValue(row.getAttribute("NonCodec").toString());
                                                       else
                                                           cellA1.setCellValue("");
                                                       cellA1 = excelrow.createCell((short) 17);
                                                       if(row.getAttribute("FrtHold")!=null)
                                                           cellA1.setCellValue(row.getAttribute("FrtHold").toString());
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
