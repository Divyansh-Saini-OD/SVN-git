// +======================================================================================+
// | Office Depot - Project Simplify                                                      |
// | Providge Consulting                                                                  |
// +======================================================================================+
// |  Class:         XdoRequestDataParam.java                                             |
// |  Description:   This class is an view/transfer object that represents an XDO Request |
// |                 document data template parameter for requests made through the       |
// |                 Oracle XML Publisher APIS.                                           |
// |                                                                                      |
// |  Change Record:                                                                      |
// |  ==========================                                                          |
// |Version   Date          Author             Remarks                                    |
// |=======   ===========   ================   ========================================== |
// |1.0       23-JUL-2007   BLooman            Initial version                            |
// |                                                                                      |
// +======================================================================================+
 
package od.oracle.apps.xxfin.xdo.xdorequest; 
 
import oracle.sql.*;
 
public class XdoRequestDataParam { 
 
  // ==============================================================================================
  // table and key information
  // ==============================================================================================
  public static final String TABLE_NAME = "XX_XDO_REQUEST_DATA_PARAMS"; 
  public static final String PRIMARY_KEY = "XDO_DATA_PARAM_ID"; 
  public static final String SEQUENCE_NAME = "XX_XDO_REQ_DATA_PARAM_ID_SEQ"; 
 
  // ==============================================================================================
  // table columns
  // ==============================================================================================
  private oracle.sql.NUMBER xdoDataParamId; 
  private oracle.sql.NUMBER xdoDocumentId; 
  private oracle.sql.NUMBER parameterNumber; 
  private String parameterName; 
  private String parameterValue; 
  private oracle.sql.DATE creationDate; 
  private oracle.sql.NUMBER createdBy; 
  private oracle.sql.DATE lastUpdateDate; 
  private oracle.sql.NUMBER lastUpdatedBy; 
  private oracle.sql.NUMBER lastUpdateLogin; 
  
  // ==============================================================================================
  // class constructor
  // ==============================================================================================
  protected XdoRequestDataParam() { } 
  
  // ==============================================================================================
  // function to create an instance of this class
  // ==============================================================================================
  public static XdoRequestDataParam createInstance() { 
    XdoRequestDataParam newInstance = new XdoRequestDataParam(); 
    return newInstance; 
  } 
   
  // ==============================================================================================
  // class column accessors
  // ==============================================================================================
  public oracle.sql.NUMBER getXdoDataParamId() { return this.xdoDataParamId; } 
  public void setXdoDataParamId(oracle.sql.NUMBER xdoDataParamId) { this.xdoDataParamId = xdoDataParamId; } 
  
  public oracle.sql.NUMBER getXdoDocumentId() { return this.xdoDocumentId; } 
  public void setXdoDocumentId(oracle.sql.NUMBER xdoDocumentId) { this.xdoDocumentId = xdoDocumentId; } 
  
  public oracle.sql.NUMBER getParameterNumber() { return this.parameterNumber; } 
  public void setParameterNumber(oracle.sql.NUMBER parameterNumber) { this.parameterNumber = parameterNumber; } 
  
  public String getParameterName() { return this.parameterName; } 
  public void setParameterName(String parameterName) { this.parameterName = parameterName; } 
  
  public String getParameterValue() { return this.parameterValue; } 
  public void setParameterValue(String parameterValue) { this.parameterValue = parameterValue; } 
  
  public oracle.sql.DATE getCreationDate() { return this.creationDate; } 
  public void setCreationDate(oracle.sql.DATE creationDate) { this.creationDate = creationDate; } 
  
  public oracle.sql.NUMBER getCreatedBy() { return this.createdBy; } 
  public void setCreatedBy(oracle.sql.NUMBER createdBy) { this.createdBy = createdBy; } 
  
  public oracle.sql.DATE getLastUpdateDate() { return this.lastUpdateDate; } 
  public void setLastUpdateDate(oracle.sql.DATE lastUpdateDate) { this.lastUpdateDate = lastUpdateDate; } 
  
  public oracle.sql.NUMBER getLastUpdatedBy() { return this.lastUpdatedBy; } 
  public void setLastUpdatedBy(oracle.sql.NUMBER lastUpdatedBy) { this.lastUpdatedBy = lastUpdatedBy; } 
  
  public oracle.sql.NUMBER getLastUpdateLogin() { return this.lastUpdateLogin; } 
  public void setLastUpdateLogin(oracle.sql.NUMBER lastUpdateLogin) { this.lastUpdateLogin = lastUpdateLogin; } 
  
  // ==============================================================================================
  // method for returning the table name associated with this view object
  // ==============================================================================================
  public static String getTableName() { return TABLE_NAME; }    
}