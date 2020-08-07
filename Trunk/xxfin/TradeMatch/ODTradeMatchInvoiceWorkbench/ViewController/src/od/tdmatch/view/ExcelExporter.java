package od.tdmatch.view;

import java.io.FileOutputStream;
import java.io.IOException;

import java.io.OutputStream;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Locale;

import java.util.Map;

import javax.faces.context.ExternalContext;
import javax.faces.context.FacesContext;

import javax.faces.event.ActionEvent;
import javax.faces.model.SelectItem;

import javax.servlet.http.HttpServletResponse;

import oracle.adf.controller.v2.context.LifecycleContext;
import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;
import oracle.adf.model.binding.DCIteratorBinding;

import oracle.adf.model.binding.DCParameter;
import oracle.adf.share.ADFContext;

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

import oracle.jbo.uicli.binding.JUCtrlRangeBinding;

import org.apache.poi.hssf.usermodel.HSSFCell;
import org.apache.poi.hssf.usermodel.HSSFCellStyle;
import org.apache.poi.hssf.usermodel.HSSFDataFormat;
import org.apache.poi.hssf.usermodel.HSSFFont;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.hssf.util.HSSFColor;


public class ExcelExporter {


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

    public ExcelExporter() {
    }


    public String exportThisTableToExcel() {
        DCBindingContainer bc = getBindingContainer();
        this.containerName = bc.getName();
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
}

