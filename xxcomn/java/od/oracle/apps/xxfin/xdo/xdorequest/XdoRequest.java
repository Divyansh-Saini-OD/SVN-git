// +======================================================================================+
// | Office Depot - Project Simplify                                                      |
// | Providge Consulting                                                                  |
// +======================================================================================+
// |  Class:         XdoRequest.java                                                      |
// |  Description:   This class is an view/transfer object that represents an XDO Request |
// |                 for requests made through the Oracle XML Publisher APIS.             |
// |                                                                                      |
// |  Change Record:                                                                      |
// |  ==========================                                                          |
// |Version   Date          Author             Remarks                                    |
// |=======   ===========   ================   ========================================== |
// |1.0       26-JUN-2007   BLooman            Initial version                            |
// |                                                                                      |
// +======================================================================================+
 
package od.oracle.apps.xxfin.xdo.xdorequest; 
 
import oracle.sql.*; 
 
public class XdoRequest { 
 
  // ==============================================================================================
  // table and key information
  // ==============================================================================================
  public static final String TABLE_NAME = "XX_XDO_REQUESTS"; 
  public static final String PRIMARY_KEY = "XDO_REQUEST_ID"; 
  public static final String SEQUENCE_NAME = "XX_XDO_REQUEST_ID_SEQ"; 

  // ==============================================================================================
  // table columns
  // ==============================================================================================
  private oracle.sql.NUMBER xdoRequestId; 
  private oracle.sql.DATE xdoRequestDate; 
  private String xdoRequestName; 
  private oracle.sql.NUMBER xdoRequestGroupId; 
  private String languageCode; 
  private String sourceAppCode; 
  private String sourceName; 
  private oracle.sql.NUMBER daysToKeep; 
  private String processStatus; 
  private oracle.sql.DATE creationDate; 
  private oracle.sql.NUMBER createdBy; 
  private oracle.sql.DATE lastUpdateDate; 
  private oracle.sql.NUMBER lastUpdatedBy; 
  private oracle.sql.NUMBER lastUpdateLogin; 
  private oracle.sql.NUMBER programApplicationId; 
  private oracle.sql.NUMBER programId; 
  private oracle.sql.DATE programUpdateDate; 
  private oracle.sql.NUMBER requestId; 
    
  // ==============================================================================================
  // arrays for child view objects (XDO Request Documents and Destinations)
  // ==============================================================================================
  private XdoRequestDoc requestDocs[];
  private XdoRequestDest requestDests[];
  
  // ==============================================================================================
  // class constructor
  // ==============================================================================================
  protected XdoRequest() {
    requestDocs = null;
    requestDests = null;
  } 
  
  // ==============================================================================================
  // function to create an instance of this class
  // ==============================================================================================
  public static XdoRequest createInstance() { 
    XdoRequest newInstance = new XdoRequest();      
    return newInstance; 
  } 
   
  // ==============================================================================================
  // class column accessors
  // ==============================================================================================
  public oracle.sql.NUMBER getXdoRequestId() { return this.xdoRequestId; } 
  public void setXdoRequestId(oracle.sql.NUMBER xdoRequestId) { this.xdoRequestId = xdoRequestId; } 
  
  public oracle.sql.DATE getXdoRequestDate() { return this.xdoRequestDate; } 
  public void setXdoRequestDate(oracle.sql.DATE xdoRequestDate) { this.xdoRequestDate = xdoRequestDate; } 
  
  public String getXdoRequestName() { return this.xdoRequestName; } 
  public void setXdoRequestName(String xdoRequestName) { this.xdoRequestName = xdoRequestName; } 
  
  public oracle.sql.NUMBER getXdoRequestGroupId() { return this.xdoRequestGroupId; } 
  public void setXdoRequestGroupId(oracle.sql.NUMBER xdoRequestGroupId) { this.xdoRequestGroupId = xdoRequestGroupId; } 
  
  public String getLanguageCode() { return this.languageCode; } 
  public void setLanguageCode(String languageCode) { this.languageCode = languageCode; } 
  
  public String getSourceAppCode() { return this.sourceAppCode; } 
  public void setSourceAppCode(String sourceAppCode) { this.sourceAppCode = sourceAppCode; } 
  
  public String getSourceName() { return this.sourceName; } 
  public void setSourceName(String sourceName) { this.sourceName = sourceName; } 
  
  public oracle.sql.NUMBER getDaysToKeep() { return this.daysToKeep; } 
  public void setDaysToKeep(oracle.sql.NUMBER daysToKeep) { this.daysToKeep = daysToKeep; } 
  
  public String getProcessStatus() { return this.processStatus; } 
  public void setProcessStatus(String processStatus) { this.processStatus = processStatus; } 
  
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
  
  public oracle.sql.NUMBER getProgramApplicationId() { return this.programApplicationId; } 
  public void setProgramApplicationId(oracle.sql.NUMBER programApplicationId) { this.programApplicationId = programApplicationId; } 
  
  public oracle.sql.NUMBER getProgramId() { return this.programId; } 
  public void setProgramId(oracle.sql.NUMBER programId) { this.programId = programId; } 
  
  public oracle.sql.DATE getProgramUpdateDate() { return this.programUpdateDate; } 
  public void setProgramUpdateDate(oracle.sql.DATE programUpdateDate) { this.programUpdateDate = programUpdateDate; } 
  
  public oracle.sql.NUMBER getRequestId() { return this.requestId; } 
  public void setRequestId(oracle.sql.NUMBER requestId) { this.requestId = requestId; } 
  
  // ==============================================================================================
  // methods for getting and setting child Document view objects (class array)
  // ==============================================================================================
  public XdoRequestDoc[] getRequestDocs() { return this.requestDocs; } 
  public XdoRequestDoc getRequestDoc(int index) { return this.requestDocs[index]; } 
  public int getRequestDocCount() { return this.requestDocs.length; } 
  public void setRequestDocs(XdoRequestDoc[] requestDocs) { this.requestDocs = requestDocs; } 
   
  // ==============================================================================================
  // methods for getting and setting child Destination view objects (class array)
  // ==============================================================================================
  public XdoRequestDest[] getRequestDests() { return this.requestDests; } 
  public XdoRequestDest getRequestDest(int index) { return this.requestDests[index]; } 
  public int getRequestDestCount() { return this.requestDests.length; }  
  public void setRequestDests(XdoRequestDest[] requestDests) { this.requestDests = requestDests; } 
  
  // ==============================================================================================
  // method for returning the table name associated with this view object
  // ==============================================================================================
  public static String getTableName() { return TABLE_NAME; } 
}