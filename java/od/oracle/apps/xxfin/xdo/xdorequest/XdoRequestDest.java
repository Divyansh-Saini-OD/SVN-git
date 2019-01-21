// +======================================================================================+
// | Office Depot - Project Simplify                                                      |
// | Providge Consulting                                                                  |
// +======================================================================================+
// |  Class:         XdoRequestDest.java                                                  |
// |  Description:   This class is an view/transfer object that represents an XDO Request |
// |                 destination for requests made through the Oracle XML Publisher APIS. |
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
 
public class XdoRequestDest { 
 
  // ==============================================================================================
  // table and key information
  // ==============================================================================================
  public static final String TABLE_NAME = "XX_XDO_REQUEST_DESTS"; 
  public static final String PRIMARY_KEY = "XDO_DESTINATION_ID"; 
  public static final String SEQUENCE_NAME = "XX_XDO_REQUEST_DEST_ID_SEQ"; 
 
  // ==============================================================================================
  // table columns
  // ==============================================================================================
  private oracle.sql.NUMBER xdoDestinationId; 
  private oracle.sql.NUMBER xdoRequestId; 
  private String deliveryMethod; 
  private String destination; 
  private String languageCode; 
  private String subjectMessage; 
  private oracle.sql.CLOB bodyMessage; 
  private String attachDocumentsFlag; 
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
  // class constructor
  // ==============================================================================================
  protected XdoRequestDest() { } 
  
  // ==============================================================================================
  // function to create an instance of this class
  // ==============================================================================================
  public static XdoRequestDest createInstance() { 
    XdoRequestDest newInstance = new XdoRequestDest(); 
    return newInstance; 
  } 
   
  // ==============================================================================================
  // class column accessors
  // ==============================================================================================
  public oracle.sql.NUMBER getXdoDestinationId() { return this.xdoDestinationId; } 
  public void setXdoDestinationId(oracle.sql.NUMBER xdoDestinationId) { this.xdoDestinationId = xdoDestinationId; } 
  
  public oracle.sql.NUMBER getXdoRequestId() { return this.xdoRequestId; } 
  public void setXdoRequestId(oracle.sql.NUMBER xdoRequestId) { this.xdoRequestId = xdoRequestId; } 
  
  public String getDeliveryMethod() { return this.deliveryMethod; } 
  public void setDeliveryMethod(String deliveryMethod) { this.deliveryMethod = deliveryMethod; } 
  
  public String getDestination() { return this.destination; } 
  public void setDestination(String destination) { this.destination = destination; } 
  
  public String getLanguageCode() { return this.languageCode; } 
  public void setLanguageCode(String languageCode) { this.languageCode = languageCode; } 
  
  public String getSubjectMessage() { return this.subjectMessage; } 
  public void setSubjectMessage(String subjectMessage) { this.subjectMessage = subjectMessage; } 
  
  public oracle.sql.CLOB getBodyMessage() { return this.bodyMessage; } 
  public void setBodyMessage(oracle.sql.CLOB bodyMessage) { this.bodyMessage = bodyMessage; } 
  
  public String getAttachDocumentsFlag() { return this.attachDocumentsFlag; } 
  public void setAttachDocumentsFlag(String attachDocumentsFlag) { this.attachDocumentsFlag = attachDocumentsFlag; } 
  
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
  // method for returning the table name associated with this view object
  // ==============================================================================================
  public static String getTableName() { return TABLE_NAME; } 
}