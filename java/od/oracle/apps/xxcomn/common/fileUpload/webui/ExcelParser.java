package od.oracle.apps.xxcomn.common.fileUpload.webui;

import java.io.*;
import java.io.InputStream;

import java.text.SimpleDateFormat;

import java.util.ArrayList;
import java.util.Collections;
import java.util.TimeZone;
import jxl.Cell;
import jxl.DateCell;
import jxl.Image;
import jxl.NumberCell;
import jxl.Sheet;
import jxl.Workbook;
import jxl.CellType;

public class ExcelParser {

  private Workbook m_wb;
  private Sheet m_sheet;
  private ArrayList m_ImgList;

  public ExcelParser(InputStream fis) throws Exception
  {
      m_wb = Workbook.getWorkbook(fis);      
  }

  public void setCurrentSheet(int nSheetNum) 
  {
    m_sheet = m_wb.getSheet(nSheetNum);    
    m_ImgList = new ArrayList();
    for (int i= 0; i < m_sheet.getNumberOfImages(); i++)
    {
      Image  image = m_sheet.getDrawing(i);
      m_ImgList.add(new Double(image.getRow()));
    }
    Collections.sort(m_ImgList);
  }

  public boolean retrieveAndSaveImage(String strFileName, int nImageIndex)
  {
    int x = m_sheet.getNumberOfImages();
    if ( (nImageIndex >= 0) && (nImageIndex < x) )
    {
     double dImageRow = ((Double)m_ImgList.get(nImageIndex)).doubleValue();
      for (int j=0; j < m_sheet.getNumberOfImages(); j++)
      {
         Image  img = m_sheet.getDrawing(j);
         if (Double.compare(dImageRow, img.getRow()) == 0 )
         {
            byte[] data = img.getImageData();
            try
            {
              FileOutputStream out = new FileOutputStream(strFileName);
              out.write(data);
              out.close();
            }
            catch (FileNotFoundException ex)
            {
              //ex.printStackTrace();
              return false;
            }
            catch(IOException ex)
            {
              //ex.printStackTrace();
              return false;
            }
            break;
         }
      }
      
      return true;
    }
    else 
      return false;
  }

  public int getNumRowsInCurrentSheet() 
  {
    return m_sheet.getRows();
  }
  
  public String getCellValue(String strCellNum, char cDataFormat) 
  {
    String value = "";
    Cell cell;
    try
    {
      cell = m_sheet.getCell(strCellNum);
      if (cell == null) 
      {
        return "";
      }
      if ( (cell.getType() == jxl.CellType.NUMBER)
        || (cell.getType() == jxl.CellType.NUMBER_FORMULA) )
      {
        NumberCell numCell = (NumberCell) cell;
        if (cDataFormat == 'F')
          value = Double.toString(numCell.getValue());
        else if (cDataFormat == 'N')
          value = Integer.toString((int)numCell.getValue());
        else
          value = trimSpaces(cell.getContents()); 
      }
      else if ( (cell.getType() == jxl.CellType.DATE) 
        || (cell.getType() == CellType.DATE_FORMULA) )
      {
        DateCell dateCell = (DateCell) cell;
        TimeZone gmtZone = TimeZone.getTimeZone("GMT");  
        SimpleDateFormat dateFormat = new SimpleDateFormat("MM/dd/yyyy");
        dateFormat.setTimeZone(gmtZone);
        value = dateFormat.format(dateCell.getDate());
       }
      else
        value = trimSpaces(cell.getContents()); 
    }
    catch (Exception e)
    {
      value = "";
    }
    return value;
  }
 
  public String getCellValue(int cellIdx, int rowIdx) 
  {
    String value = "";
    Cell cell;
    try
    {
      cell = m_sheet.getCell(cellIdx, rowIdx);
      if (cell == null) 
      {
        return "";
      }
      value = trimSpaces(cell.getContents()); 
    }
    catch (Exception e)
    {
      value = "";
    }
    return value;
  }

  public static String trimSpaces(String trimStr) 
  {
    if(trimStr == null)
      return null;

    StringBuffer sb = new StringBuffer(trimStr);
    for (int i = 0; i < sb.length(); i++) 
    {
      if ( sb.charAt(i) == '\u0009' || // Tab
        sb.charAt(i) == '\u2007' || // Figure 
        sb.charAt(i) == '\u00A0' || // No-break
        sb.charAt(i) == '\u202F'  // Narrow no-break  
      ) 
            sb.setCharAt(i, ' '); // set a normal space
    }

    // now trim regular spaces at the beginning and end
    trimStr = sb.toString().trim();        
    return trimStr;
  }
}