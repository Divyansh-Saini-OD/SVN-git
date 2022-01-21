package od.oracle.apps.xxfin.ar.ebill;

import java.io.BufferedOutputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;


//import java.sql.Types;
import java.sql.Blob;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.math.*; //Defect# 10388 AND Defect# 15119

import java.text.SimpleDateFormat;

//import java.util.Properties;
//import java.util.ResourceBundle;
//import java.util.Enumeration;
import java.util.ArrayList;

import java.util.HashSet;

import oracle.apps.fnd.cp.request.CpContext;
import oracle.apps.fnd.cp.request.JavaConcurrentProgram;
import oracle.apps.fnd.util.NameValueType;

import oracle.jdbc.OracleTypes;
import oracle.jdbc.pool.OracleDataSource;

import oracle.sql.BLOB;

import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.ClientAnchor;
import org.apache.poi.ss.usermodel.CreationHelper;
import org.apache.poi.ss.usermodel.DataFormat;
import org.apache.poi.ss.usermodel.Drawing;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.Footer;
import org.apache.poi.ss.usermodel.Hyperlink;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Picture;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.util.IOUtils;

//import org.apache.poi.ss.usermodel.contrib.*;

public class XLSRenderer implements JavaConcurrentProgram  {

    public enum DataType {VARCHAR2, NUMERIC, DATE}

    abstract class Aggregation {
        private String key_;
        private String label_;
        private String parentName_;
        private String headerForLabelCol_;
        private String headerForValueCol_;
        private String aggrFormat_;
        private DataType aggrDataType_;
        private boolean isGrand_;         // All final (non-group specific) totals are called grands for this purpose; For business purposes, "GRAND" is only the final total that matches the original function type
                                          // and any other requested final total is considered a SUB (i.e., function over the subtotals).  GRAND totals are always over all values, whereas SUBs are always over the subtotals.
                                          // For example, function AVG can include GRAND (for global average), as well as SUBAVG (for average of subtotals), SUBMIN, SUBCOUNT, SUBMAX SUBSUM (all over the subtotals).
        private boolean isOverSubtotals_;
        private boolean hasOutline_;
        private boolean shouldDisplayOnNewLine_;
        private int colDisplayLabel_;
        private int colDisplayValue_;
        private int colGroup_;
        private int colAggregate_;
        private int colDistinct_;
        private HashSet valueSet_;
        private ArrayList grandAggs_;
        private CellStyle cellStyleForValue_;

        public Aggregation() {shouldDisplayOnNewLine_=true; hasOutline_=false; label_=""; colDistinct_=-1;isGrand_=false;isOverSubtotals_=false;} // don't call directly; use aggConstructor
        public abstract String name();
        public abstract boolean validFunctionValue();
        public abstract String toString();
        public abstract Double toDouble();
        public abstract void add(String value);
        public abstract void add(Double value);
        public void clear() {addToGrands(); if (valueSet_!=null) valueSet_.clear();}
        public void add(String value, String distinct) {if (!valueSet_.contains(distinct)) {valueSet_.add(distinct); add(value);}}
        public boolean isGrand() {return isGrand_;}
        public boolean isOverSubtotals() {return isOverSubtotals_;}
        public boolean hasOutline() {return hasOutline_;}
        public boolean shouldDisplayOnNewLine() {return shouldDisplayOnNewLine_;}
        public int colDistinct() {return colDistinct_;}
        public int colDisplayLabel() {return colDisplayLabel_;}
        public int colDisplayValue() {return colDisplayValue_;}
        public int colGroup() {return colGroup_;}
        public int colAggregate() {return colAggregate_;}
        public String key() {return key_;};
        public String label() {return label_;}
        public String parentName() {return parentName_;}
        public String headerForLabelCol() {return headerForLabelCol_;}
        public String headerForValueCol() {return headerForValueCol_;}
        public DataType aggrDataType() {return aggrDataType_;}
        public String aggrFormat() {return aggrFormat_;}
        public CellStyle cellStyleForValue() {return cellStyleForValue_;}
        public void setKey(String key) {key_=key;}
        public void setParentName(String name) {parentName_=name;}
        public void setIsGrand(boolean isGrand) {isGrand_=isGrand;}
        public void setIsOverSubtotals(boolean isOverSubtotals) {isOverSubtotals_=isOverSubtotals;}
        public void setHasOutline(boolean has) {hasOutline_ = has;}
        public void setShouldDisplayOnNewLine(boolean should) {shouldDisplayOnNewLine_=should;}
        public void setColGroup(int col) {colGroup_ = col;}
        public void setColAggregate(int col) {colAggregate_ = col;}
        public void setColDistinct(int col) {colDistinct_ = col; valueSet_=new HashSet();}
        public void setColDisplayLabel(int col) {colDisplayLabel_ = col;}
        public void setColDisplayValue(int col) {colDisplayValue_ = col;}
        public void setHeaderForLabelCol(String header) {headerForLabelCol_=header;}
        public void setHeaderForValueCol(String header) {headerForValueCol_=header;}
        private void setAggrDataType(String dataType) {   // set through aggConstructor
            if (dataType==null || dataType.equals("VARCHAR2")) aggrDataType_=DataType.VARCHAR2;
            else if (dataType.equals("NUMERIC")) aggrDataType_=DataType.NUMERIC;
            else if (dataType.equals("DATE")) aggrDataType_=DataType.DATE;
            else aggrDataType_=DataType.VARCHAR2;
        }
        private void setAggrDataType(DataType dataType) {
            aggrDataType_=dataType;
        }
        public void setAggrFormat(String aggrFormat) {aggrFormat_=aggrFormat;}
        public void setCellStyleForValue(CellStyle cellStyle) {cellStyleForValue_=cellStyle;}
        public ArrayList grandAggs() {return grandAggs_;}
        public void addToGrands() {
            if (grandAggs_!=null) {
                for (int i=0; i<grandAggs_.size(); i++) {
                    Aggregation grandAgg = (Aggregation)grandAggs_.get(i);
                    if (grandAgg.key().equals("AVG")) {
                        AggregationAverage grandAvg = (AggregationAverage)grandAgg;
                        if (grandAvg.isOverSubtotals() || !key().equals("AVG"))
                            grandAvg.add(toString());
                        else {
                            grandAvg.addToSum(((AggregationAverage)this).sum());
                            grandAvg.addToCount(((AggregationAverage)this).count());
                        }
                    }
                    else if (grandAgg.key().equals("COUNT")) {
                        AggregationCount grandCount = (AggregationCount)grandAgg;
                        if (grandCount.isOverSubtotals() || !key().equals("COUNT") || grandCount.aggrDataType()!=DataType.NUMERIC) grandCount.add(toString());
                        else grandCount.add(toDouble());
                    }
                    else if (grandAgg.aggrDataType()!=DataType.NUMERIC) grandAgg.add(toString());
                    else grandAgg.add(toDouble());
                }
            }
        }
        public void setLabel(String label) {
            boolean bAddGrandTotal = false;
            if (!isGrand()) {bAddGrandTotal=true; if (label==null) label="GRANDAUTO"; else label+="||GRANDAUTO"; } // Add Grand Total automatically, unless suppressed with NOGRAND
            if (label!=null) {
                String[] saAggDef = label.split("\\|\\|");
                for (int i=0; i<saAggDef.length; i++) {
                    String[] saAggAtt = saAggDef[i].split("\\|");

                    if (!isGrand() && saAggDef[i].startsWith("GRAND")) {
                        if (!saAggDef[i].startsWith("GRANDAUTO") || bAddGrandTotal) {
                            if (grandAggs_==null) grandAggs_ = new ArrayList();
                            Aggregation agg = aggConstructor(key(),aggrDataType());
                            if (agg!=null) {
                                bAddGrandTotal = false;
                                agg.setIsGrand(true);
                                agg.setColAggregate(colAggregate());
                                agg.setColDisplayLabel(colGroup());
                                agg.setColDisplayValue(colDisplayValue());
                                agg.setAggrFormat(aggrFormat());
                                String sNewLabel = saAggDef[i].replace(saAggAtt[0],"");
                                if (sNewLabel.startsWith("|")) sNewLabel = sNewLabel.substring(1);
                                agg.setLabel(sNewLabel);
                                grandAggs_.add(0,agg);
                            }
                        }
                    }
                    else if (!isGrand() && saAggDef[i].startsWith("SUB")) {
                        if (grandAggs_==null) grandAggs_ = new ArrayList();
                        Aggregation agg = aggConstructor(saAggAtt[0].replace("SUB",""), aggrDataType());
                        if (agg!=null) {
                            agg.setIsGrand(true);
                            agg.setIsOverSubtotals(true);
                            agg.setParentName(name());
                            agg.setColAggregate(colAggregate());
                            agg.setColDisplayLabel(colGroup());
                            agg.setColDisplayValue(colDisplayValue());
                            agg.setAggrFormat(aggrFormat());
                            String sNewLabel = saAggDef[i].replace(saAggAtt[0],"");
                            if (sNewLabel.startsWith("|")) sNewLabel = sNewLabel.substring(1);
                            agg.setLabel(sNewLabel);
                            grandAggs_.add(agg);
                        }
                    }
                    else {
                        boolean bValueColSet = false;
                        for(int j=0; j<saAggAtt.length; j++) {
                            if (saAggAtt[j]!=null) {
                                if (saAggAtt[j].startsWith("NOGRAND")) bAddGrandTotal = false;
                                else if (saAggAtt[j].startsWith("OUTLINE")) setHasOutline(true);
                                else if (saAggAtt[j].startsWith("LABELCOL")) {
                                    setColDisplayLabel(Integer.parseInt(saAggAtt[j].replace("LABELCOL","").replace("=","").trim()));
                                    bValueColSet = true;
                                }
                                else if (saAggAtt[j].startsWith("VALUECOL")) setColDisplayValue(Integer.parseInt(saAggAtt[j].replace("VALUECOL","").replace("=","").trim()));
                                else if (saAggAtt[j].startsWith("DISTINCTCOL")) setColDistinct(Integer.parseInt(saAggAtt[j].replace("DISTINCTCOL","").replace("=","").trim()));
                                else if (saAggAtt[j].startsWith("VALUEHEADER")) setHeaderForValueCol(saAggAtt[j].replace("VALUEHEADER","").replace("=","").trim());
                                else if (saAggAtt[j].startsWith("LABELHEADER")) setHeaderForLabelCol(saAggAtt[j].replace("LABELHEADER","").replace("=","").trim());
                                else if (saAggAtt[j].startsWith("FORMAT")) setAggrFormat(saAggAtt[j].replace("FORMAT","").replace("=","").trim());
                                else if (saAggAtt[j].startsWith("NONEWROW")) setShouldDisplayOnNewLine(false);
                                else if (j==saAggAtt.length-1) {
                                    label_ = saAggAtt[j];
                                    if (!bValueColSet && label_.indexOf("&VALUE")>=0 && colDisplayLabel_!=colDisplayValue_) colDisplayValue_=colDisplayLabel_;
                                }
                            }
                        }
                    }
                }
            }
        }

        public String displayLabel(String group) {
            if (group==null) group = "";
            String sDisplay = label();
            if (sDisplay==null || sDisplay.equals("")) {
               sDisplay = group + " " + name();
               if (colDisplayLabel()==colDisplayValue()) sDisplay += " " + toString();
            }
            else {
              sDisplay = sDisplay.replace("&GROUP",group);
              if (sDisplay.indexOf("&VALUE")>=0) sDisplay = sDisplay.replace("&VALUE",toString());
              else if (colDisplayLabel()==colDisplayValue()) sDisplay = sDisplay + " " + toString();
            }
            return sDisplay;
        }

        private Aggregation aggConstructor(String aggFunction, DataType aggDataType) {
            Aggregation agg = null;
            if (aggFunction.equals(AggregationSum.key)) {if (aggDataType==DataType.NUMERIC) agg = new AggregationSum();}
            else if (aggFunction.equals(AggregationCount.key)) agg = new AggregationCount();
            else if (aggFunction.equals(AggregationAverage.key)) {if (aggDataType==DataType.NUMERIC) agg = new AggregationAverage();}
            else if (aggFunction.equals(AggregationMax.key)) agg = new AggregationMax();
            else if (aggFunction.equals(AggregationMin.key)) agg = new AggregationMin();
            if (agg!=null) agg.setAggrDataType(aggDataType);
            return agg;
        }
    }
    class AggregationSum extends Aggregation {
        public static final String key = "SUM";
      private static final double PRECISION_MULTIPLIER = 10000.0; // 4 decimal places; //money doesn't work well in doubles because of rounding issues, so we store sums in long data //types as hundredths of pennies
        //private Long sum_;  //Defect 10388 AND Defect# 15119

        BigDecimal sum_ = new BigDecimal("0.00"); //Defect 10388 AND Defect# 15119

        public AggregationSum() {setKey(key);sum_=new BigDecimal("0.00");}
        public String name(){if (isOverSubtotals()) return "Sum of " + parentName() + "s"; else return "Sum";}
        public void clear() {super.clear();sum_= new BigDecimal("0.00");}
        public void add(String value) {
//          double bValue;
            BigDecimal bValue = new BigDecimal(value); 
          //try {dValue = Double.parseDouble(value);}
          //catch (Exception ex) {return;} // ignore if not numeric
          sum_ = sum_.add(bValue);
        }
        public void add(Double value) {

           //double bValue;
            BigDecimal bValue = new BigDecimal(value);
            sum_ = sum_.add(bValue);};  //Defect 10388 AND Defect# 15119
                  
        public boolean validFunctionValue() {return true;}; 
        public Double toDouble() {return sum_.doubleValue();}  //Defect 10388 AND Defect# 15119
        public String toString() {return sum_.toString();}
    }
    class AggregationCount extends Aggregation {
        public static final String key = "COUNT";
        private Long count_;

        public AggregationCount() {setKey(key); count_=(long)0;}
        public String name(){if (isOverSubtotals()) return "Count of " + parentName() + "s"; else return "Count";}
        public void clear() {super.clear();count_=(long)0;}
        public void add(String value) {count_ += 1;}
        public void add(Double value) {count_ += value.longValue();}
        public boolean validFunctionValue() {return true;};
        public Double toDouble() {return new Double(count_);}
        public String toString() {return count_.toString();};
    }
    class AggregationAverage extends Aggregation {
        public static final String key = "AVG";
        private AggregationCount count_;
        private AggregationSum sum_;
        public AggregationAverage() {setKey(key); count_= new AggregationCount(); sum_= new AggregationSum();};
        public String name(){if (isOverSubtotals()) return "Average of " + parentName() + "s"; else return "Average";};
        public void clear() {super.clear(); sum_.clear(); count_.clear();}
        public void add(String value) {
          double dValue;
          try {dValue = Double.parseDouble(value);}
          catch (Exception ex) {return;} // ignore if not numeric
          sum_.add(dValue); count_.add(value);
        }
        public void add(Double value) {sum_.add(value); count_.add(value);}
        public boolean validFunctionValue() {return count_.toDouble()!=0.0;};
        public Double toDouble() {
          Double count = count_.toDouble();
          if (count==0.0) return count;
          else return sum_.toDouble()/count;}
        public String toString() {
          if (validFunctionValue()) return toDouble().toString();
          else return "<undefined>";
        };
        public String displayLabel(String group) {
          String sDisplay = super.displayLabel(group);
          if (sDisplay!=null && sDisplay.indexOf("&SUM")>=0) {
           sDisplay = sDisplay.replace("&SUM",sum_.toString());
          }
          if (sDisplay!=null && sDisplay.indexOf("&COUNT")>=0) {
           sDisplay = sDisplay.replace("&COUNT",count_.toString());
          }
          return sDisplay;
        }
        public Double count() {return count_.toDouble();}
        public Double sum() {return sum_.toDouble();}
        public void addToCount(Double value) {count_.add(value);}
        public void addToSum(Double value) {sum_.add(value);}
    }
    class AggregationMax extends Aggregation {
        public static final String key = "MAX";
        private Double dMax_;
        private String sMax_;
        private boolean bNoValue;

        public AggregationMax() {setKey(key); bNoValue=true;}
        public String name(){if (isOverSubtotals()) return "Max of " + parentName() + "s"; else return "Max";}
        public void clear() {super.clear(); bNoValue=true;}
        public void add(String sValue) {
          if (sValue==null) return;
          if (aggrDataType()==DataType.NUMERIC) {
              double dValue;
              try {dValue = Double.parseDouble(sValue);}
              catch (Exception ex) {return;} // ignore if not numeric
              if (bNoValue) {bNoValue=false; dMax_=dValue;}
              else if (dValue>dMax_) dMax_=dValue;
          }
          else { // Dates are staged in canonical form "yyyy-MM-dd", so straight text comparison should work
              if (bNoValue) {bNoValue=false; sMax_=sValue;}
              else if (sMax_.compareToIgnoreCase(sValue)<0) sMax_=sValue;
          }
        }
        public void add(Double value) {
          if (bNoValue) {bNoValue=false; dMax_=value;}
          else if (value>dMax_) dMax_=value;
        }
        public boolean validFunctionValue() {return !bNoValue;};
        public Double toDouble() {if (bNoValue) return 0.0; else return dMax_;}
        public String toString() {
          if (validFunctionValue()) {
            if (aggrDataType()==DataType.NUMERIC) return dMax_.toString();
            else return sMax_;
          }
          else return "<not found>";
        };
    }
    class AggregationMin extends Aggregation {
        public static final String key = "MIN";
        private Double dMin_;
        private String sMin_;
        private boolean bNoValue;

        public AggregationMin() {setKey(key); bNoValue=true;};
        public String name(){if (isOverSubtotals()) return "Min of " + parentName() + "s"; else return "Min";}
        public void clear() {super.clear(); bNoValue=true;}
        public void add(String sValue) {
          if (sValue==null) return;
          if (aggrDataType()==DataType.NUMERIC) {
              double dValue;
              try {dValue = Double.parseDouble(sValue);}
              catch (Exception ex) {return;} // ignore if not numeric
              if (bNoValue) {bNoValue=false; dMin_=dValue;}
              else if (dValue<dMin_) dMin_=dValue;
          }
          else { // Dates are staged in canonical form "yyyy-MM-dd", so straight text comparison should work
              if (bNoValue) {bNoValue=false; sMin_=sValue;}
              else if (sMin_.compareToIgnoreCase(sValue)>0) sMin_=sValue;
          }
        }
        public void add(Double value) {
          if (bNoValue) {bNoValue=false; dMin_=value;}
          else if (value<dMin_) dMin_=value;
        }
        public boolean validFunctionValue() {return !bNoValue;};
        public Double toDouble() {if (bNoValue) return 0.0; else return dMin_;}
        public String toString() {
          if (validFunctionValue()) {
            if (aggrDataType()==DataType.NUMERIC) return dMin_.toString();
            else return sMin_;
          }
          else return "<not found>";
        };
    }
    class AggregationGroup {
        private int col_;
        private int startRow_;
        private String val_;
        private ArrayList aggregations_;

        public AggregationGroup() {aggregations_=null;};
        public int getCol() {return col_;}
        public int getStartRow() {return startRow_;}
        public String getVal() {return val_;}
        public ArrayList getAggregations() {return aggregations_;}
        public void setCol(int col) {col_=col;}
        public void setStartRow(int startRow) {startRow_=startRow;}
        public void setVal(String val) {val_=val;}
        public void addAggregation(Aggregation agg) {
            if (aggregations_==null) aggregations_ = new ArrayList();
            aggregations_.add(agg);
        }
    }

    private Connection connection; // Database Connection Object
    double m_nPrecisionMultiplier = 10000.0; // 5 decimal places; money doesn't work well in doubles because of rounding issues, so we store sums in long data types as hundredths of pennies
    private String gsXXFIN_TOP;
     
    public XLSRenderer() {
    }

    public static void main(String[] args) {
        XLSRenderer xlsRenderer = new XLSRenderer();

        try {
          OracleDataSource ods = new OracleDataSource();
          ods.setURL("jdbc:oracle:thin:apps/dev01apps@//choldbr18d-vip.na.odcorp.net:1531/GSIDEV01");
          xlsRenderer.connection=ods.getConnection();
          xlsRenderer.connection.setAutoCommit(true);
        } catch(SQLException ex) {
           ex.printStackTrace();
           System.out.println("Error Connecting to the Database\n" + ex.toString());
        }

        try {
           int nThreadID = 0;
           int nThreadCount = 2;

           xlsRenderer.RenderXLSFiles(nThreadID,nThreadCount);
           System.out.println("\nXLS file rendering succeeded");
        }
        catch (Exception ex) {
            System.out.println("XLS file rendering thread failed\n" + ex.toString());
            ex.printStackTrace();
        }

        try {
           xlsRenderer.connection.close();
        }
        catch(SQLException ex) {
           System.out.println("Error Closing Connection\n" + ex.toString());  // can't really do much here
           ex.printStackTrace();
        }
    }


    public void runProgram(CpContext cpcontext) {
        connection = cpcontext.getJDBCConnection();
        gsXXFIN_TOP = cpcontext.getEnvStore().getEnv("XXFIN_TOP");
        
        if (connection==null) {
          cpcontext.getReqCompletion().setCompletion(2, "ERROR");
          System.out.println("Error: connection is null\n");
          return;
        }
        try {
          connection.setAutoCommit(true);
        }
        catch (SQLException ex) {
            cpcontext.getReqCompletion().setCompletion(2, "ERROR");
            System.out.println("Error: Unable to setAutoCommit(true)\n" + ex.toString());
            ex.printStackTrace();
            return;
        }

        NameValueType parameter;
        int nThreadID = -1;
        int nThreadCount = -1;

        // ==============================================================================================
        // get parameter list from concurrent program
        // ==============================================================================================
        parameter = cpcontext.getParameterList().nextParameter();

        // ==============================================================================================
        // get next CP parameter (parameter1 = THREAD_ID)
        // ==============================================================================================
        if (parameter.getName().equals("THREAD_ID")) {
          if (parameter.getValue() != null && parameter.getValue() != "") {
            nThreadID = Integer.parseInt(parameter.getValue());
          }
        }
        else {
          System.out.println("Parameter THREAD_ID should be Parameter 1.");
        }

        parameter = cpcontext.getParameterList().nextParameter();

        // ==============================================================================================
        // get next CP parameter (parameter2 = THREAD_COUNT)
        // ==============================================================================================
        if (parameter.getName().equals("THREAD_COUNT")) {
          if (parameter.getValue() != null && parameter.getValue() != "") {
            nThreadCount = Integer.parseInt(parameter.getValue());
          }
        }
        else {
          System.out.println("Parameter THREAD_COUNT should be Parameter 2.");
        }

        System.out.println("  THREAD_ID     : " + nThreadID );
        System.out.println("  THREAD_COUNT  : " + nThreadCount );
        System.out.println("");

        if (nThreadID<1 || nThreadCount<1) {
            System.out.println("\nTHREAD_ID and THREAD_COUNT should be > 0");
            cpcontext.getReqCompletion().setCompletion(2, "ERROR");
            return;
        }
        if (nThreadID > nThreadCount) {
            System.out.println("\nTHREAD_ID should be less than or equal to THREAD_COUNT");
            cpcontext.getReqCompletion().setCompletion(2, "ERROR");
            return;
        }


        nThreadID--; // mod function needs zero based threadID

        try {
           RenderXLSFiles(nThreadID,nThreadCount);
           System.out.println("\nXLS file rendering thread done.");
        }
        catch (Exception ex) {
            ex.printStackTrace();
            System.out.println("\nXLS file rendering thread failed" + ex.toString());
        }

        try {
           connection.close();
        }
        catch(SQLException ex) {
           System.out.println("Error While Closing Connection .." + ex.toString());
           ex.printStackTrace();
           cpcontext.getReqCompletion().setCompletion(2, "ERROR");
           return;
        }

        cpcontext.getReqCompletion().setCompletion(0, "SUCCESS");
    }


    private void RenderXLSFiles(int nThreadID, int nThreadCount) throws Exception {
        CallableStatement csFiles = null;
        ResultSet rsFiles = null;
        try {
            csFiles = connection.prepareCall("BEGIN dbms_application_info.set_client_info(404); XX_AR_EBL_RENDER_XLS_PKG.XLS_FILES_TO_RENDER(?,?,?); END;"); // Get the file rows that need to be rendered
            csFiles.setInt(1,nThreadID);
            csFiles.setInt(2,nThreadCount);
            csFiles.registerOutParameter(3, OracleTypes.CURSOR);
            csFiles.execute();
            rsFiles = (ResultSet)csFiles.getObject(3);
            while (rsFiles.next()) {

                int nFileID = rsFiles.getInt("file_id");
                String sInvoiceType = rsFiles.getString("invoice_type");
                System.out.println("Rendering XLS file_id " + nFileID);
                try {
                    RenderXLSFile(nFileID, sInvoiceType);
                    System.out.println("eBill file_id #" + nFileID + " rendered");
                }
                catch (Exception renderEx) {
                    renderEx.printStackTrace();
                    System.out.println("eBill file_id #" + nFileID + " rendering failed\n" + renderEx.toString());
                    renderEx.printStackTrace();

                    PreparedStatement pstmt = null;
                    boolean pStatusUpdateSuccessful = false;
                    try {
                        System.out.println("  Setting RENDER_ERROR status");
                        pstmt = connection.prepareStatement ("update XX_AR_EBL_FILE SET file_data=?, status='RENDER_ERROR', status_detail=?, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id WHERE file_id = ?");
                        pstmt.setBlob(1, (Blob)null);
                        pstmt.setString(2,renderEx.toString());
                        pstmt.setInt(3, nFileID);
                        pstmt.execute();

                        pStatusUpdateSuccessful = true;
                    }
                    catch (Exception updateEx) {  // need to proceed, but this will write to log
                        System.out.println("Error setting XX_AR_EBLFILE status to RENDER_ERROR for file_id=" + nFileID + "; XX_AR_EBL_COMMON_UTIL_PKG.UPDATE_DATA_EXTRACT_STATUS not called; XLS render for this file_id will be retried automatically on next run, if no action is taken.).  ERROR message: " + updateEx.toString());
                    }
                    finally {
                        if (pstmt!=null) pstmt.close();
                    }

                    if (pStatusUpdateSuccessful) {
                        CallableStatement cstmt = null;
                        try {
                            cstmt = connection.prepareCall("BEGIN XX_AR_EBL_COMMON_UTIL_PKG.UPDATE_DATA_EXTRACT_STATUS(?,?); END;");
                            cstmt.setInt(1,nFileID);
                            cstmt.setString(2,sInvoiceType);
                            cstmt.execute();
                        }
                        catch (Exception ex) {  // need to proceed, but this will write to log
                            System.out.println("ERROR: XLS rendering failed for file_id " + nFileID + " and XX_AR_EBL_FILE status was set to RENDER_ERROR.  However, XX_AR_EBL_COMMON_UTIL_PKG.UPDATE_DATA_EXTRACT_STATUS failed: " + ex.toString());
                        }
                        finally {
                            if (cstmt!=null) cstmt.close();
                        }
                    }
                }
            }
        }
        catch (Exception ex){
            ex.printStackTrace();
            throw new Exception("Error in RenderXLSFiles\n" + ex.toString());
        }
        finally {
            if (rsFiles!=null) rsFiles.close();
            if (csFiles!=null) csFiles.close();
        }
    }

    private void RenderXLSFile(int nFileID, String sInvoiceType) throws SQLException, IOException, Exception {
        Workbook wb = new HSSFWorkbook();
        Sheet s = wb.createSheet();
        wb.setSheetName(0,"eBill");
        DataFormat df = wb.createDataFormat();
        SimpleDateFormat canonicalDateFormat = new SimpleDateFormat("yyyy-MM-dd");

        // This style is used for all non-text (i.e., NUMERIC and DATE) header labels
        CellStyle headerCellStyle = wb.createCellStyle();
//        Font headerFont = wb.createFont();
//        headerCellStyle.setFont(headerFont);
//        headerCellStyle.setBorderBottom(CellStyle.BORDER_MEDIUM);
        headerCellStyle.setBorderBottom(CellStyle.BORDER_THIN);
        headerCellStyle.setDataFormat(df.getFormat("text"));
        headerCellStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
        headerCellStyle.setFillPattern(CellStyle.SOLID_FOREGROUND);
        headerCellStyle.setAlignment(CellStyle.ALIGN_RIGHT);

        // This style is used for all text header labels
        CellStyle headerTextCellStyle = wb.createCellStyle();
        headerTextCellStyle.setBorderBottom(CellStyle.BORDER_THIN);
        headerTextCellStyle.setDataFormat(df.getFormat("text"));
        headerTextCellStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
        headerTextCellStyle.setFillPattern(CellStyle.SOLID_FOREGROUND);
        headerTextCellStyle.setAlignment(CellStyle.ALIGN_LEFT);

        CellStyle aggLabelStyle = wb.createCellStyle();

        aggLabelStyle.setBorderLeft(CellStyle.BORDER_THIN);
        aggLabelStyle.setBorderRight(CellStyle.BORDER_THIN);
        aggLabelStyle.setLeftBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
        aggLabelStyle.setRightBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
        aggLabelStyle.setBorderTop(CellStyle.BORDER_MEDIUM);
        aggLabelStyle.setBorderBottom(CellStyle.BORDER_MEDIUM);
        aggLabelStyle.setTopBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
        aggLabelStyle.setBottomBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());

        Font aggFont = wb.createFont();
        aggFont.setBoldweight(Font.BOLDWEIGHT_BOLD);
//        aggLabelStyle.setDataFormat(df.getFormat("text")); // don't do this; leave generic so counts, etc, will be interpreted correctly
        aggLabelStyle.setFont(aggFont);

        Row rHeaderRow = null;
        int nFirstDataRow;
        int nNextDataRow = 0;
        int nColumnCount = 0;
        ArrayList alAggregationGroups= new ArrayList();
        ArrayList alsCellStyle       = new ArrayList();
        DataType[] dtaColumnDataType = new DataType[256]; // 256 is current max cols for the Excel versions we are generating
        AggregationGroup[] aAggregationGroups;
        boolean bIncludeHeader = false; // this means show the column labels; the other header attributes (e.g., billing_for, billing_period, etc) are hidden if the logo path is null
        Row r = null;
        Cell c = null;

        CallableStatement cstmt = connection.prepareCall("BEGIN XX_AR_EBL_RENDER_XLS_PKG.XLS_FILE_HEADER(?,?,?,?,?,?,?,?,?,?,?,?,?,?); END;");
        cstmt.setInt(1,nFileID); // cstmt.setInt("p_file_id",nFileID);
        cstmt.registerOutParameter(2, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_cell_total_due", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(3, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_description", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(4, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_cell_cons_bill_number", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(5, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_cell_billing_period", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(6, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_cell_pay_terms", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(7, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_cell_due_date", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(8, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_billing_for", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(9, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_billing_id", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(10, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_aops_id", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(11, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_include_header", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(12, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_logo_hyperlink_url", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(13, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_logo_alt_text", OracleTypes.VARCHAR);
        cstmt.registerOutParameter(14, OracleTypes.VARCHAR); // cstmt.registerOutParameter("x_logo_path", OracleTypes.VARCHAR);
        cstmt.execute();

        String sLogoPath = cstmt.getString(14); // cstmt.getString("x_logo_path");
        String sLogoHyperlink = null;
        String sLogoHyperlinkLabel = null;
        String sWarnings = "";
        CellStyle cellStyle;

//sLogoPath = null; // for debugging
//sLogoPath = "C:\\xxfin_release\\html\\logo_officedepot.jpg"; // for debugging

        if (sLogoPath!=null) {
            if (gsXXFIN_TOP!=null) sLogoPath = sLogoPath.replace("$XXFIN_TOP",gsXXFIN_TOP);

            nNextDataRow = 5;

            r = s.createRow(0);
            c = r.createCell(2);
            c.setCellValue(cstmt.getString(8)); // c.setCellValue(cstmt.getString("x_billing_for"));
            c = r.createCell(3);
            c.setCellValue(cstmt.getString(5)); // c.setCellValue(cstmt.getString("x_cell_billing_period"));

            r = s.createRow(1);
            c = r.createCell(2);
            c.setCellValue(cstmt.getString(10)); // c.setCellValue(cstmt.getString("x_aops_id"));
            c = r.createCell(3);
            c.setCellValue(cstmt.getString(6)); // c.setCellValue(cstmt.getString("x_cell_pay_terms"));

            r = s.createRow(2);
            c = r.createCell(2);
            c.setCellValue(cstmt.getString(9)); // c.setCellValue(cstmt.getString("x_billing_id"));
            c = r.createCell(3);
            c.setCellValue(cstmt.getString(7)); // c.setCellValue(cstmt.getString("x_cell_due_date"));

            r = s.createRow(3);
            c = r.createCell(0);
            c.setCellValue(cstmt.getString(3)); // sBillDescription = cstmt.getString("x_description"); // tried setting cell value after column autosize so it can span cols A & B, but result not better
            c = r.createCell(2);
            c.setCellValue(cstmt.getString(4)); // c.setCellValue(cstmt.getString("x_cell_cons_bill_number"));
            c = r.createCell(3);
            c.setCellValue(cstmt.getString(2)); // c.setCellValue(cstmt.getString("x_cell_total_due"));

//            sLogoHyperlink = rset.getString("X_LOGO_HYPERLINK_URL"); // Hyperlinks on images not currently supported by POI (v3.6)
//            sLogoHyperlinkLabel = rset.getString("X_LOGO_ALT_TEXT");
        }
        String sIncludeHeader = cstmt.getString(11); // String sIncludeHeader = cstmt.getString("x_include_header");
//sIncludeHeader = "Y"; // for debugging
        if (sIncludeHeader!=null && sIncludeHeader.equals("Y")) {
          bIncludeHeader = true;
        }
        cstmt.close();


        PreparedStatement pstmt=null;
        ResultSet rset=null;
        // get display columns, and header labels
        try {
          cstmt = connection.prepareCall("BEGIN XX_AR_EBL_RENDER_XLS_PKG.XLS_FILE_COLS(?,?); END;");
          cstmt.setInt(1,nFileID);
          cstmt.registerOutParameter(2, OracleTypes.CURSOR);
          cstmt.execute();
          rset = (ResultSet)cstmt.getObject(2);

          if (bIncludeHeader) {
            r = s.createRow(nNextDataRow++); // Header
            rHeaderRow = r;
          }
          while(rset.next()) {
                String sDataType = rset.getString("data_type");
                if (bIncludeHeader) {
                    c = r.createCell(nColumnCount);
                    c.setCellValue(rset.getString("header")); // header
                    if (sDataType!=null && (sDataType.equals("NUMERIC") || sDataType.equals("DATE")))
                      c.setCellStyle(headerCellStyle);
                    else
                      c.setCellStyle(headerTextCellStyle);
 //                 if (rset.getInt("width")<0) s.autoSizeColumn(c.getColumnIndex()); // non-text columns don't consistently autosize, so this option would autosize based on header alone
                }

                cellStyle = wb.createCellStyle();
                String sCellFormat = rset.getString("format");
                if (sCellFormat!=null) cellStyle.setDataFormat(df.getFormat(sCellFormat));
/*
                String sAlign = rset.getString("align");
                if (sAlign!=null) {
                  sAlign = sAlign.toLowerCase();
                  if (sAlign.equals("center")) cellStyle.setAlignment(CellStyle.ALIGN_CENTER);
                  else if (sAlign.equals("right")) cellStyle.setAlignment(CellStyle.ALIGN_RIGHT);
                  else if (sAlign.equals("left")) cellStyle.setAlignment(CellStyle.ALIGN_LEFT);
                }
*/
                if (sDataType!=null && (sDataType.equals("NUMERIC") || sDataType.equals("DATE"))) {
                  cellStyle.setAlignment(CellStyle.ALIGN_RIGHT);
                  if (sDataType.equals("DATE")) dtaColumnDataType[nColumnCount] = DataType.DATE;
                  else dtaColumnDataType[nColumnCount] = DataType.NUMERIC;
                }
                else {
                  cellStyle.setAlignment(CellStyle.ALIGN_LEFT);
                  dtaColumnDataType[nColumnCount] = DataType.VARCHAR2;
                }

//              Font font = wb.createFont();
//              cellStyle.setFont(font);
                cellStyle.setBorderLeft(CellStyle.BORDER_THIN);
                cellStyle.setBorderRight(CellStyle.BORDER_THIN);
                cellStyle.setBorderTop(CellStyle.BORDER_THIN);
                cellStyle.setBorderBottom(CellStyle.BORDER_THIN);
                cellStyle.setLeftBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
                cellStyle.setRightBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
                cellStyle.setTopBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
                cellStyle.setBottomBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());

                alsCellStyle.add(cellStyle);

                nColumnCount++;
          }

        } catch(SQLException ex) {
           ex.printStackTrace();
           throw new Exception("Error in display columns query\n" + ex.toString());
        } finally {
           if (rset != null) rset.close();
           if (cstmt != null) cstmt.close();
        }

        nFirstDataRow = nNextDataRow;


        try {         // get group by columns
          cstmt = connection.prepareCall("BEGIN XX_AR_EBL_RENDER_XLS_PKG.XLS_FILE_AGGS(?,?); END;");
          cstmt.setInt(1,nFileID);
          cstmt.registerOutParameter(2, OracleTypes.CURSOR);
          cstmt.execute();
          rset = (ResultSet)cstmt.getObject(2);

          aAggregationGroups = new AggregationGroup[nColumnCount+1];
          while(rset.next()) {
            try {
                String sAggregationFunction = rset.getString("aggr_fun");
                String sAggrDataType = rset.getString("aggr_data_type");

                Aggregation agg = aggConstructor(sAggregationFunction, sAggrDataType);
                if (agg==null) {
                    if (sWarnings.length()>0) sWarnings+="\n";
                    String sMsg = "Aggregation function " + sAggregationFunction + " unknown or not allowed on field data type " + sAggrDataType;
                    sWarnings += sMsg;
                    System.out.println(sMsg); // Not a show stopper
                    continue;
                }
                int nGroupCol = rset.getInt("group_col");
                agg.setColGroup(nGroupCol);
                int nAggrCol = rset.getInt("aggr_col");
                agg.setColAggregate(nAggrCol);
                agg.setColDisplayLabel(nGroupCol);
                agg.setColDisplayValue(nAggrCol);
                agg.setAggrFormat(rset.getString("aggr_format"));
                agg.setLabel(rset.getString("agg_label")); // set Label last as it can override other properties

                cellStyle = null;
                String sAggrFormat = agg.aggrFormat();
                if (sAggrFormat!=null && agg.colDisplayValue()!=agg.colDisplayLabel() && !sAggregationFunction.equals("COUNT") && (agg.aggrDataType()==DataType.NUMERIC || agg.aggrDataType()==DataType.DATE)) {
                    cellStyle = wb.createCellStyle();
                    if (agg.aggrFormat()!=null) cellStyle.setDataFormat(df.getFormat(sAggrFormat));
                    cellStyle.setFont(aggFont);
                    
                    cellStyle.setBorderLeft(CellStyle.BORDER_THIN);
                    cellStyle.setBorderRight(CellStyle.BORDER_THIN);
                    cellStyle.setLeftBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
                    cellStyle.setRightBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
                    cellStyle.setBorderTop(CellStyle.BORDER_MEDIUM);
                    cellStyle.setBorderBottom(CellStyle.BORDER_MEDIUM);
                    cellStyle.setTopBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
                    cellStyle.setBottomBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
                    
                    agg.setCellStyleForValue(cellStyle);
                }
                ArrayList grandAggs = agg.grandAggs();
                for (int i=0; grandAggs!=null && i<grandAggs.size(); i++) {
                    Aggregation grandAgg = (Aggregation)grandAggs.get(i);
                    if (grandAgg.aggrFormat()!=null && grandAgg.colDisplayValue()!=grandAgg.colDisplayLabel() && !grandAgg.key().equals("COUNT") && (grandAgg.aggrDataType()==DataType.NUMERIC || grandAgg.aggrDataType()==DataType.DATE)) {
                        if (cellStyle!=null && sAggrFormat.equals(grandAgg.aggrFormat()))
                            grandAgg.setCellStyleForValue(cellStyle);
                        else {
                            cellStyle = wb.createCellStyle();
                            sAggrFormat = grandAgg.aggrFormat();
                            if (grandAgg.aggrFormat()!=null) cellStyle.setDataFormat(df.getFormat(sAggrFormat));
                            cellStyle.setFont(aggFont);
                            grandAgg.setCellStyleForValue(cellStyle);
                        }
                    }
                }

                if (aAggregationGroups[nGroupCol]==null) {
                    AggregationGroup aggregationGroup = new AggregationGroup();
                    aggregationGroup.setCol(nGroupCol);
                    aggregationGroup.setStartRow(nNextDataRow);
                    aAggregationGroups[nGroupCol] = aggregationGroup;
                    alAggregationGroups.add(aggregationGroup); // maintains original order for proper grouping/output
                }
                aAggregationGroups[nGroupCol].addAggregation(agg);

/*
                    CellStyle aggCellStyle = wb.createCellStyle();
    //                if (sCellFormat!=null) aggCellStyle.setDataFormat(df.getFormat(sCellFormat));
                    aggCellStyle.setBorderLeft(CellStyle.BORDER_THIN);
                    aggCellStyle.setBorderRight(CellStyle.BORDER_THIN);
                    aggCellStyle.setLeftBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
                    aggCellStyle.setRightBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
    //  if (p_file_id==2) {
                    aggCellStyle.setBorderTop(CellStyle.BORDER_MEDIUM);
                    aggCellStyle.setBorderBottom(CellStyle.BORDER_MEDIUM);
                    aggCellStyle.setTopBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
                    aggCellStyle.setBottomBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
    //  }
                    aggCellStyle.setFont(aggFont);
                    alsSumCellStyles.add(aggCellStyle);
*/
            }
            catch (Exception ex) {
                if (sWarnings.length()>0) sWarnings+="\n";
                sWarnings += "Invalid aggregation attributes.";
                System.out.println("Invalid aggregation attributes."); // Not a show stopper
            }
          }
        }
        catch(SQLException ex) {
            ex.printStackTrace();
            throw new Exception("Error in group by columns query\n" + ex.toString());
        } finally {
            if (rset != null) rset.close();
            if (cstmt != null) cstmt.close();
        }

        aAggregationGroups = new AggregationGroup[alAggregationGroups.size()]; // now compress and order the sparse array
        int nMaxCol = nColumnCount; // nMaxCol is how many columns to autosize (in case aggregations are displayed to the right of staged fields)
        for (int i=0; i<alAggregationGroups.size(); i++) {
            AggregationGroup ag = (AggregationGroup)alAggregationGroups.get(i);
            aAggregationGroups[i] = ag;
            ArrayList alAggs = ag.getAggregations();
            for (int j=0; j<alAggs.size(); j++) {
                Aggregation agg = (Aggregation)alAggs.get(j);
                nMaxCol = Math.max(nMaxCol, setAggColHeaders(agg, rHeaderRow, nColumnCount, headerCellStyle));
                ArrayList grandAggs = agg.grandAggs();
                if (grandAggs!=null)
                    for (int k=0; k<grandAggs.size(); k++)
                        nMaxCol = Math.max(nMaxCol, setAggColHeaders((Aggregation)grandAggs.get(k), rHeaderRow, nColumnCount, headerCellStyle));
            }
        }

        StringBuilder sbSortColumns= new StringBuilder();
        try {         // get sort order
          cstmt = connection.prepareCall("BEGIN XX_AR_EBL_RENDER_XLS_PKG.XLS_FILE_SORT_COLS(?,?); END;");
          cstmt.setInt(1,nFileID);
          cstmt.registerOutParameter(2, OracleTypes.CURSOR);
          cstmt.execute();
          rset = (ResultSet)cstmt.getObject(2);

          String sSortType;
          String sDataType;
          while(rset.next()) {
              sDataType = rset.getString("data_type");
              if (sDataType!=null && sDataType.equals("NUMERIC")) {
                sbSortColumns.append(",TO_NUMBER(COLUMN");
                sbSortColumns.append(rset.getInt("column_number"));
                sbSortColumns.append(")");
              }
              else {
                sbSortColumns.append(",COLUMN");
                sbSortColumns.append(rset.getInt("column_number"));
              }
              sSortType = rset.getString("sort_type");
              if (sSortType!=null && sSortType.equals("DESC")) sbSortColumns.append(" DESC");
          }
        } catch(SQLException ex) {
          ex.printStackTrace();
          throw new Exception("Error in sort order query\n" + ex.toString());
        } finally {
           if (rset != null) rset.close();
           if (cstmt != null) cstmt.close();
        }
         //added the DISTINCT Clause in the SELECT statement for Defect# to remove duplicate from EXCEL Sheet output
        StringBuilder sbSQL = new StringBuilder("select distinct * from ( SELECT ");
        for (int i=1; i<=nColumnCount; i++) {
          sbSQL.append("COLUMN");
          sbSQL.append(i);
          sbSQL.append(",");
        }
        sbSQL.append("rec_type FROM XX_AR_EBL_XLS_STG WHERE file_id=? AND rec_order<>0 ORDER BY ");
        String sSortColumns = sbSortColumns.toString();
        if (sSortColumns.equals(""))
           sbSQL.append("consolidated_bill_number, customer_trx_id, rec_order, trx_line_number");
        else {
           sbSQL.append(sSortColumns.substring(1));
           sbSQL.append(", rec_order, trx_line_number");
        }
        
        sbSQL.append(')');
        
        try {         // get staged bill data
          pstmt = connection.prepareStatement(sbSQL.toString());
          pstmt.setInt(1,nFileID);
          rset = pstmt.executeQuery();

          String sColVal;
          int nRowNumber = 0;
          while(rset.next()) {
              nRowNumber++;
              String sRecType = rset.getString("rec_type");

              if (nRowNumber == 1) {
                  for(int i=0; i<aAggregationGroups.length; i++) {
                      sColVal = rset.getString(aAggregationGroups[i].getCol());
                      if (sColVal!=null) sColVal=sColVal.trim();
                      aAggregationGroups[i].setVal(sColVal);
                  }
              }
              else {
                  int nFirstChangedGroup = firstChangedGroup(rset, aAggregationGroups); // highest precedence group change forces change to all lower groups
                  if (nFirstChangedGroup >= 0) {
                      nNextDataRow = outputAndClearSubtotals(s, nNextDataRow, nColumnCount, aAggregationGroups, nFirstChangedGroup, aggLabelStyle, canonicalDateFormat);

                      for(int i=nFirstChangedGroup; i<aAggregationGroups.length; i++) {
                          sColVal = rset.getString(aAggregationGroups[i].getCol());
                          if (sColVal!=null) sColVal=sColVal.trim();
                          aAggregationGroups[i].setVal(sColVal);
                      }
                  }
              }

//              if (sRecType.equals("DT")) {                          DT rec_type restriction commented for defect 7310
                  for (int i=0; i<aAggregationGroups.length; i++) {
                      AggregationGroup ag = aAggregationGroups[i];
                      ArrayList alAggregations = ag.getAggregations();
                      for (int j=0; j<alAggregations.size(); j++) {
                          Aggregation agg = (Aggregation)alAggregations.get(j);
                          String sAggVal = rset.getString(agg.colAggregate());
                          int colDistinct = agg.colDistinct();
                          if (colDistinct>0) agg.add(sAggVal, rset.getString(colDistinct)); // means only add if the "distinct col" val hasn't been seen before for current group
                          else agg.add(sAggVal);
                      }
                  }
//              }

              r = s.createRow(nNextDataRow++);
              for (int i=0; i<nColumnCount; i++) {
                  c = r.createCell(i);
                  c.setCellStyle((CellStyle)alsCellStyle.get(i));
                  sColVal = rset.getString(i+1);
                  if (sColVal!=null) sColVal = sColVal.trim();

                  if (dtaColumnDataType[i]==DataType.DATE) {
                      try {
                          c.setCellValue(canonicalDateFormat.parse(sColVal)); // SimpleDateFormat df1 = new SimpleDateFormat(c.getCellStyle().getDataFormatString());
                          //System.out.println(c.getCellStyle().getDataFormatString() + "    " + df1.parse(rset.getString(i+1)));
                      }
                      catch (Exception e) {
                          try {
                              c.setCellValue(Double.parseDouble(sColVal));  //c.setCellValue(Double.parseDouble(sVal.replace("$","").replace(",","")));
                          }
                          catch (Exception e2){
                              c.setCellValue(sColVal);
                          }
                      }
                  }
                  else if (dtaColumnDataType[i]==DataType.NUMERIC) {
                      try {
                          c.setCellValue(Double.parseDouble(sColVal));  //c.setCellValue(Double.parseDouble(sVal.replace("$","").replace(",","")));
                      }
                      catch (Exception e2){
                          c.setCellValue(sColVal);
                      }
                  }
                  else { // dtaColumnDataType[i] == DataType.VARCHAR2 // (((CellStyle)alsCellStyle.get(i)).getDataFormatString().equals("@")) c.setCellValue(sColVal);  // text
                      c.setCellValue(sColVal);
                  }
              }
          }
          nNextDataRow = outputAndClearSubtotals(s, nNextDataRow, nColumnCount, aAggregationGroups, 0, aggLabelStyle, canonicalDateFormat);
          outputGrandTotals(s, nNextDataRow, nColumnCount, aAggregationGroups, aggLabelStyle, canonicalDateFormat);
        }
        catch(Exception ex) {
            ex.printStackTrace();
            throw new Exception("Error in bill data query, aggregation, or output\n" + ex.toString());
        } finally {
              if (rset != null) rset.close();
              if(pstmt != null) pstmt.close();
        }

//        CellStyle bottomCellStyle = wb.createCellStyle();
//        bottomCellStyle.setBorderTop(CellStyle.BORDER_THIN);
//        bottomCellStyle.setTopBorderColor(IndexedColors.GREY_25_PERCENT.getIndex());
//        r = s.createRow(nNextDataRow+2);
//        for (int i=0; i<nColumnCount; i++) r.createCell(i).setCellStyle(bottomCellStyle);


        System.setProperty("java.awt.headless", "true"); // only need to do this if graphical environment is not available
        for (int i=0; i<=nMaxCol; i++) {
//         int w = (Integer)alnColWidths.get(i);
//         if (w == 0)
           s.autoSizeColumn(i);
           Double w = new Double(s.getColumnWidth(i));
//System.out.println("column " + i + " width = " + w);
           w = w * 1.24;  // without the graphical environment, autosize on server is undersizing the columns
           s.setColumnWidth(i,w.intValue());
//         else if (w>0)
//           s.setColumnWidth(i,w);
        }

//      s.getRow(8).getCell(3).setCellFormula("SUM(D6:D8)");


        s.setDisplayGridlines(false);

        if (sLogoPath!=null) {
           try {
//            s.getRow(3).getCell(0).setCellValue(sBillDescription); // better to set description prior to autosize so full text will not be hidden if it takes more than 2 cell widths
            insertGraphic(wb, s, sLogoPath, sLogoHyperlink, sLogoHyperlinkLabel); // "brand.png" // "/home/u250648/brand.png"
//          insertGraphic(wb, s, "C:\\xxfin_release\\html\\logo_officedepot.png", "http://www.officedepot.com", "Office Depot"); // "brand.png" // "/home/u250648/brand.png"
           }
          catch (Exception ex) {
            if (sWarnings.length()>0) sWarnings+="\n";
            sWarnings += "Unable to include logo " + ex.toString();
            System.out.println("Warning: Unable to insertGraphic for eBill file_id "+ nFileID +'\n'+ex.toString()); // Not a show stopper
          }
        }

        if (bIncludeHeader) {
          s.createFreezePane( 0, nFirstDataRow, 0, nFirstDataRow );
          wb.setRepeatingRowsAndColumns( 0, -1, -1, 0, nFirstDataRow-1 );
        }

        Footer footer = s.getFooter();
//      footer.setCenter("Page " + HSSFFooter.page() + " of " + HSSFFooter.numPages());
        footer.setCenter("Page &P of &N");

        s.setHorizontallyCenter(true);

/*
        try {
          FileOutputStream out = new FileOutputStream("workbook" + nFileID + ".xls");
          wb.write(out);
          out.close();
          System.out.println("File Written");
        }
        catch (Exception e) {throw new Exception("Error writing output to filesystem for file_id " + nFileID + '\n' + e.toString());}
*/

        ByteArrayOutputStream out = new ByteArrayOutputStream();

        try {
          wb.write(out);
          out.close();
        }
        catch (Exception ex) {throw new Exception("Error writing output to ByteArrayOutputStream for file_id " + nFileID + '\n' + ex.toString());}

        byte[] ba = out.toByteArray();

/* // This commented out block works on my desktop, but with the class versions on our EBS linux server, the blob insert gives:
   //     java.sql.SQLException: ORA-01460: unimplemented or unreasonable conversion requested
   // The blob.getBinaryOutputStream() below is a workaround, but this method has been deprecated so it should be replaced with the commented out block when possible.

        ByteArrayInputStream bais = new ByteArrayInputStream(ba);
        PreparedStatement pstmt = null;
        try {
            pstmt = connection.prepareStatement ("INSERT INTO XX_AR_EBL_FILE (file_id, file_data) VALUES (?, ?)");
            pstmt.setInt(1, p_file_id);
            pstmt.setBinaryStream(2, bais, (int) ba.length);
            pstmt.execute();
        }
        catch (Exception ex) {
            System.out.println("Error inserting: " + ex.toString());
            bais.reset();
            pstmt = connection.prepareStatement ("UPDATE XX_AR_EBL_FILE SET file_data = ? WHERE file_id = ?");
            pstmt.setBinaryStream(1, bais, (int) ba.length);
            pstmt.setInt(2, p_file_id);
            pstmt.execute();
        }
        finally {
           if (pstmt!=null) try {pstmt.close();} catch (Exception e) {System.out.println("Error closing sql statement "+ p_file_id +'\n'+e.toString());};
           if (bais!=null) try {bais.close();} catch (Exception e) {System.out.println("Error closing bais "+ p_file_id +'\n'+e.toString());};
        }
*/

        BLOB blob = BLOB.createTemporary(connection,true,BLOB.DURATION_SESSION);
        OutputStream os = blob.getBinaryOutputStream();
        os.write(ba);
        os.flush();
        os.close();

        try {
            pstmt = connection.prepareStatement ("UPDATE XX_AR_EBL_FILE SET file_data=?, status=?, status_detail=?, last_updated_by=fnd_global.user_id, last_update_date=SYSDATE, last_update_login=fnd_global.login_id  WHERE file_id = ?");
            pstmt.setBlob(1, blob);
            pstmt.setString(2,"RENDERED");
            pstmt.setString(3,sWarnings);
            pstmt.setInt(4, nFileID);

            int nUpdateCount=pstmt.executeUpdate();
            if (nUpdateCount<1) throw new SQLException("Unable to update blob for file_id " + nFileID);
            else if (nUpdateCount>1) throw new SQLException("Too many rows updated for file_id " + nFileID);
            else System.out.println("Blob update successful");
        }
        catch (Exception ex) {
            throw new Exception("Error updating XX_AR_EBL_FILE for file_id " + nFileID + ": " + ex.toString());
        }
        finally {
            if (pstmt!=null) pstmt.close();
        }

        try {
            cstmt = connection.prepareCall("BEGIN XX_AR_EBL_COMMON_UTIL_PKG.UPDATE_BILL_STATUS_eXLS(?,?); END;");
            cstmt.setInt(1,nFileID);
            cstmt.setString(2,sInvoiceType);
            cstmt.execute();
        }
        catch (Exception ex) { // throwing this new exception should cause calling procedure to set the _FILE status to error, but if that also fails, the status will remain as RENDERED.
            String sMsg = "ERROR: XLS rendering was successful for file_id " + nFileID + " and file_data blob was updated.  However, XX_AR_EBL_COMMON_UTIL_PKG.UPDATE_BILL_STATUS_eXLS failed: " + ex.toString();
            System.out.println(sMsg);
            throw new Exception(sMsg);
        }
        finally {
            if (cstmt!=null) cstmt.close();
        }
    }

    private int[] arrayListToIntArray(ArrayList al) {
        int[] ia = new int[al.size()];
        for (int i=0; i<al.size(); i++) ia[i] = (Integer)al.get(i);
        return ia;
    }


    private int setAggColHeaders(Aggregation agg, Row rowHeader, int nDisplayCols, CellStyle headerCellStyle) {
        int nMaxCol = nDisplayCols;
        if (agg.shouldDisplayOnNewLine()==false && (agg.colDisplayLabel()<=nDisplayCols || agg.colDisplayValue()<=nDisplayCols))
            agg.setShouldDisplayOnNewLine(true);
        if (rowHeader!=null) {
            Cell c;
            int nValueCol = agg.colDisplayValue()-1;
            if (nValueCol>=nDisplayCols) {
                c = rowHeader.getCell(nValueCol);
                if (c==null) c = rowHeader.createCell(nValueCol);
                c.setCellStyle(headerCellStyle);
                c.setCellValue(agg.headerForValueCol());

                nMaxCol = nValueCol;
            }

            int nLabelCol = agg.colDisplayLabel()-1;
            if (nLabelCol!=nValueCol && nLabelCol>=nDisplayCols) {
                c = rowHeader.getCell(nLabelCol);
                if (c==null) c = rowHeader.createCell(nLabelCol);
                c.setCellStyle(headerCellStyle);
                c.setCellValue(agg.headerForLabelCol());

                if (nLabelCol>nMaxCol) nMaxCol = nLabelCol;
            }
        }
        return nMaxCol;
    }

    private int firstChangedGroup(ResultSet rset, AggregationGroup[] aAggregationGroups) throws Exception {
       int nFirstChangedGroup = -1;
       for (int i=0; i<aAggregationGroups.length && nFirstChangedGroup<0; i++) {
           AggregationGroup ag = aAggregationGroups[i];
           String v1 = rset.getString(ag.getCol());
           String v2 = ag.getVal();
           if ((v1!=null && v2!=null && v2.equals(v1.trim())) || (v1==null && v2==null)); // do nothing (logic is easier to consider this way)
           else nFirstChangedGroup = i; // this will be set when the values are different, including the case when only one is null
       }
       return nFirstChangedGroup;
    }


    private int outputAndClearSubtotals(Sheet sheet, int nStartDataOnRow, int nDisplayColumns, AggregationGroup[] aAggregationGroups, int nFirstChangedGroup, CellStyle aggLabelStyle, SimpleDateFormat canonicalDateFormat) {
        Row r;
        Cell c;
        int lastDataRow = nStartDataOnRow-1;
        int i = aAggregationGroups.length-1;
        while (i >= nFirstChangedGroup) {
            AggregationGroup oAggregationGroup = aAggregationGroups[i];
            ArrayList alAggregations = oAggregationGroup.getAggregations();
            for (int j=0; j<alAggregations.size(); j++) {
                Aggregation agg = (Aggregation)alAggregations.get(j);

                if (agg.shouldDisplayOnNewLine()) {
                    r = sheet.createRow(nStartDataOnRow);
                    if (agg.hasOutline()) sheet.groupRow(oAggregationGroup.getStartRow(), nStartDataOnRow-1);

                    nStartDataOnRow++;
                    
                    for (int nCol=0; nCol<Math.max(nDisplayColumns, Math.max(agg.colDisplayLabel(), agg.colDisplayValue())); nCol++) {
                        c = r.createCell(nCol);
                        c.setCellStyle(aggLabelStyle);
                   }
                }
                else {
                    r = sheet.getRow(lastDataRow);
                    if (agg.hasOutline()) sheet.groupRow(oAggregationGroup.getStartRow(), lastDataRow-1);
                }

                c = r.getCell(agg.colDisplayLabel()-1);
                if (c==null) c = r.createCell(agg.colDisplayLabel()-1);
                c.setCellValue(agg.displayLabel(oAggregationGroup.getVal()));
                c.setCellStyle(aggLabelStyle);

                if (agg.colDisplayLabel()!=agg.colDisplayValue()) {
                    c = r.getCell(agg.colDisplayValue()-1);
                    if (c==null) c = r.createCell(agg.colDisplayValue()-1);
                    if (agg.cellStyleForValue()==null) c.setCellStyle(aggLabelStyle);
                    else c.setCellStyle(agg.cellStyleForValue());

                    if (agg.aggrDataType()==DataType.NUMERIC) c.setCellValue(Math.round(agg.toDouble()*100.0)/100.0); // Show max of 2 decimals per defect 7311
                    else if (agg.aggrDataType()==DataType.DATE) {
                        try {
                            c.setCellValue(canonicalDateFormat.parse(agg.toString()));
                        }
                        catch (Exception ex) {
                            c.setCellValue(agg.toString());
                        }
                    }
                    else c.setCellValue(agg.toString());
                }
                agg.clear();
            }
            i -= 1;
        }

        for (i=aAggregationGroups.length-1; i >= nFirstChangedGroup; i--)
            aAggregationGroups[i].setStartRow(nStartDataOnRow);

        return nStartDataOnRow;
    }


 private void outputGrandTotals(Sheet sheet, int nStartDataOnRow, int nDisplayColumns, AggregationGroup[] aAggregationGroups, CellStyle aggLabelStyle, SimpleDateFormat canonicalDateFormat) {
     Row r;
     Cell c;
     int i = aAggregationGroups.length-1;
     while (i >= 0) {
         AggregationGroup ag = aAggregationGroups[i];
         ArrayList alAggregations = ag.getAggregations();

         for (int j=0; j<alAggregations.size(); j++) {
           Aggregation agg = (Aggregation)alAggregations.get(j);
             ArrayList grandAggs = agg.grandAggs();
             if (grandAggs!=null) {
                 for (int k=0; k<grandAggs.size(); k++) {
                     Aggregation grandAgg = (Aggregation)grandAggs.get(k);

                     r = sheet.createRow(nStartDataOnRow++);

                     for (int nCol=0; nCol<Math.max(nDisplayColumns, Math.max(grandAgg.colDisplayLabel(), grandAgg.colDisplayValue())); nCol++) {
                         c = r.createCell(nCol);
                         c.setCellStyle(aggLabelStyle);
                     }

                     c = r.getCell(grandAgg.colDisplayLabel()-1);
                     if (c==null) c = r.createCell(grandAgg.colDisplayLabel()-1);
                     if (grandAgg.isOverSubtotals()) c.setCellValue(grandAgg.displayLabel("ALL GROUPS"));
                     else c.setCellValue(grandAgg.displayLabel("ALL VALUES"));

                     if (grandAgg.colDisplayLabel()!=grandAgg.colDisplayValue()) {
                         c = r.getCell(grandAgg.colDisplayValue()-1);
                         if (c==null) c = r.createCell(grandAgg.colDisplayValue()-1);
                         if (grandAgg.cellStyleForValue()==null) c.setCellStyle(aggLabelStyle);
                         else c.setCellStyle(grandAgg.cellStyleForValue());

                         if (grandAgg.aggrDataType()==DataType.NUMERIC) c.setCellValue(Math.round(grandAgg.toDouble()*100.0)/100.0); // Show max of 2 decimals per defect 7311
                         else if (grandAgg.aggrDataType()==DataType.DATE) {
                             try {
                                 c.setCellValue(canonicalDateFormat.parse(grandAgg.toString()));
                             }
                             catch (Exception ex) {
                                 c.setCellValue(grandAgg.toString());
                             }
                         }
                         else c.setCellValue(grandAgg.toString());
                     }
                 }
             }
         }
         i -= 1;
     }
 }


    private void insertGraphic(Workbook oWB, Sheet oSheet, String sFilename, String sHyperlink, String sLabel) throws Exception {
        int pictureIdx = 0;

        InputStream is = new FileInputStream(sFilename);
        byte[] bytes = IOUtils.toByteArray(is);

        String sLowerFilename = sFilename.toLowerCase();
        if (sLowerFilename.endsWith(".png"))
          pictureIdx = oWB.addPicture(bytes, Workbook.PICTURE_TYPE_PNG);
        else if (sLowerFilename.endsWith(".jpg"))
          pictureIdx = oWB.addPicture(bytes, Workbook.PICTURE_TYPE_JPEG);
        else {
          is.close();
          throw new Exception("File extension unsupported for image " + sFilename);
        }
        is.close();

        CreationHelper helper = oWB.getCreationHelper();

        // Create the drawing patriarch.  This is the top level container for all shapes.
        Drawing drawing = oSheet.createDrawingPatriarch();

        //add a picture shape
        ClientAnchor anchor = helper.createClientAnchor();
        //set top-left corner of the picture,
        //subsequent call of Picture#resize() will operate relative to it
        anchor.setCol1(0);
        anchor.setRow1(0);
        Picture pict = drawing.createPicture(anchor, pictureIdx);

        //auto-size picture relative to its top-left corner
        pict.resize();

/* In Excel you can select an image, right click it and set a Hyperlink,
 * but it doesn't seem to be possible to add a hyperlink to an image with POI v3.6.
 * We can add the hyperlink to a cell, but if the image obscures the cell it won't allow click through.
 *  Revisit this if & when we get a POI upgrade.

        if (sHyperlink!=
        ) {
           CreationHelper createHelper = oWB.getCreationHelper();
           Hyperlink link = createHelper.createHyperlink(Hyperlink.LINK_URL);
           link.setAddress(sHyperlink);
           //if (sLabel!=null) link.setLabel(sLabel); // why doesn't this set the ScreenTip?
           oSheet.getRow(0).createCell(1).setHyperlink(link);
        }
*/
    }

     private Aggregation aggConstructor(String aggFunction, String aggDataType) {
         Aggregation agg = null;
         if (aggFunction.equals(AggregationSum.key)) {if (aggDataType!=null && aggDataType.equals("NUMERIC")) agg = new AggregationSum();}
         else if (aggFunction.equals(AggregationCount.key)) agg = new AggregationCount();
         else if (aggFunction.equals(AggregationAverage.key)) {if (aggDataType!=null & aggDataType.equals("NUMERIC")) agg = new AggregationAverage();}
         else if (aggFunction.equals(AggregationMax.key)) agg = new AggregationMax();
         else if (aggFunction.equals(AggregationMin.key)) agg = new AggregationMin();
         if (agg!=null) agg.setAggrDataType(aggDataType);
         return agg;
     }
}
