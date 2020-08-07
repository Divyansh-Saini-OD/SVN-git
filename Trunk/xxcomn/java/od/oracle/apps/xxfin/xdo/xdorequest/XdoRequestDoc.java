// +======================================================================================+
// | Office Depot - Project Simplify                                                      |
// | Providge Consulting                                                                  |
// +======================================================================================+
// |  Class:         XdoRequestDoc.java                                                   |
// |  Description:   This class is an view/transfer object that represents an XDO Request |
// |                 document for requests made through the Oracle XML Publisher APIS.    |
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
import java.io.*;
import oracle.apps.xdo.dataengine.DataTemplate;
import oracle.apps.xdo.oa.schema.server.Template;
 
public class XdoRequestDoc { 
 
  // ==============================================================================================
  // table and key information
  // ==============================================================================================
  public static final String TABLE_NAME = "XX_XDO_REQUEST_DOCS"; 
  public static final String PRIMARY_KEY = "XDO_DOCUMENT_ID"; 
  public static final String SEQUENCE_NAME = "XX_XDO_REQUEST_DOC_ID_SEQ"; 
 
  // ==============================================================================================
  // table columns
  // ==============================================================================================
  private oracle.sql.NUMBER xdoRequestId; 
  private oracle.sql.NUMBER xdoDocumentId;
  private byte[] xmlCachedDataBytes;    // local cached xml data
  private oracle.sql.CLOB xmlData; 
  private String xdoDataAppName; 
  private String xdoDataDefCode;  
  private String xdoAppShortName; 
  private String xdoTemplateCode; 
  private String sourceAppCode; 
  private String sourceName; 
  private String sourceKey1; 
  private String sourceKey2; 
  private String sourceKey3; 
  private String storeDocumentFlag; 
  private oracle.sql.BLOB documentData;
  private ByteArrayInputStream CachedDocumentDataIS;    // local cached document data
  private String documentFileName; 
  private String documentFileType; 
  private String documentContentType; 
  private String languageCode; 
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
  // XML Publisher objects related to this view object
  // ==============================================================================================
  private DataTemplate xdoDataDefinition;
  private Template xdoTemplate;
  
  // ==============================================================================================
  // arrays for child view objects (XDO Request Document Data Parameters)
  // ==============================================================================================
  private XdoRequestDataParam dataParameters[];
  
  // ==============================================================================================
  // class constructor
  // ==============================================================================================
  protected XdoRequestDoc() { 
    xdoDataDefinition = null;
    xdoTemplate = null;
    dataParameters = null;
  } 
  
  // ==============================================================================================
  // function to create an instance of this class
  // ==============================================================================================
  public static XdoRequestDoc createInstance() { 
    XdoRequestDoc newInstance = new XdoRequestDoc(); 
    return newInstance; 
  } 
   
  // ==============================================================================================
  // class columns accessors
  // ==============================================================================================
  public oracle.sql.NUMBER getXdoDocumentId() { return this.xdoDocumentId; } 
  public void setXdoDocumentId(oracle.sql.NUMBER xdoDocumentId) { this.xdoDocumentId = xdoDocumentId; } 
  
  public oracle.sql.NUMBER getXdoRequestId() { return this.xdoRequestId; } 
  public void setXdoRequestId(oracle.sql.NUMBER xdoRequestId) { this.xdoRequestId = xdoRequestId; } 
  
  public byte[] getCachedXmlDataBytes() { return this.xmlCachedDataBytes; } 
  public void setCachedXmlDataBytes(byte[] xmlCachedDataBytes) { this.xmlCachedDataBytes = xmlCachedDataBytes; } 
  
  public oracle.sql.CLOB getXmlData() { return this.xmlData; } 
  public void setXmlData(oracle.sql.CLOB xmlData) { this.xmlData = xmlData; } 
    
  public Reader getCachedXmlReader() throws Exception {
    if(this.xmlCachedDataBytes != null && this.xmlCachedDataBytes.length > 0) {
      return (Reader)(new InputStreamReader((InputStream)(new ByteArrayInputStream(this.xmlCachedDataBytes))));
    }
    else {
      return (Reader)(this.xmlData.getCharacterStream());
    }
  }
  
  public String getXdoDataAppName() { return this.xdoDataAppName; } 
  public void setXdoDataAppName(String xdoDataAppName) { this.xdoDataAppName = xdoDataAppName; } 
  
  public String getXdoDataDefCode() { return this.xdoDataDefCode; } 
  public void setXdoDataDefCode(String xdoDataDefCode) { this.xdoDataDefCode = xdoDataDefCode; } 
  
  public String getXdoAppShortName() { return this.xdoAppShortName; } 
  public void setXdoAppShortName(String xdoAppShortName) { this.xdoAppShortName = xdoAppShortName; } 
  
  public String getXdoTemplateCode() { return this.xdoTemplateCode; } 
  public void setXdoTemplateCode(String xdoTemplateCode) { this.xdoTemplateCode = xdoTemplateCode; } 
  
  public String getSourceAppCode() { return this.sourceAppCode; } 
  public void setSourceAppCode(String sourceAppCode) { this.sourceAppCode = sourceAppCode; } 
  
  public String getSourceName() { return this.sourceName; } 
  public void setSourceName(String sourceName) { this.sourceName = sourceName; } 
  
  public String getSourceKey1() { return this.sourceKey1; } 
  public void setSourceKey1(String sourceKey1) { this.sourceKey1 = sourceKey1; } 
  
  public String getSourceKey2() { return this.sourceKey2; } 
  public void setSourceKey2(String sourceKey2) { this.sourceKey2 = sourceKey2; } 
  
  public String getSourceKey3() { return this.sourceKey3; } 
  public void setSourceKey3(String sourceKey3) { this.sourceKey3 = sourceKey3; } 
  
  public String getStoreDocumentFlag() { return this.storeDocumentFlag; } 
  public void setStoreDocumentFlag(String storeDocumentFlag) { this.storeDocumentFlag = storeDocumentFlag; } 
  
  public oracle.sql.BLOB getDocumentData() { return this.documentData; } 
  public void setDocumentData(oracle.sql.BLOB documentData) { this.documentData = documentData; } 
  
  public ByteArrayInputStream getCachedDocumentDataIS(boolean reset) { 
    // position pointer at beginning of InputStream
    if (reset) {
      this.CachedDocumentDataIS.reset();
    }
    return this.CachedDocumentDataIS; 
  } 
  public void setCachedDocumentDataIS(ByteArrayInputStream CachedDocumentDataIS) { this.CachedDocumentDataIS = CachedDocumentDataIS; } 
  
  public String getDocumentFileName() { return this.documentFileName; } 
  public void setDocumentFileName(String documentFileName) { this.documentFileName = documentFileName; } 
  
  public String getDocumentFileType() { return this.documentFileType; } 
  public void setDocumentFileType(String documentFileType) { this.documentFileType = documentFileType; } 
  
  public String getDocumentContentType() { return this.documentContentType; } 
  public void setDocumentContentType(String documentContentType) { this.documentContentType = documentContentType; } 
  
  public String getLanguageCode() { return this.languageCode; } 
  public void setLanguageCode(String languageCode) { this.languageCode = languageCode; } 
  
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
   
  public Template getXdoTemplate() { return this.xdoTemplate; }  
  public void setXdoTemplate(Template xdoTemplate) { this.xdoTemplate = xdoTemplate; } 
   
  public DataTemplate getXdoDataDefinition() { return this.xdoDataDefinition; }  
  public void setXdoDataDefinition(DataTemplate xdoDataDefinition) { this.xdoDataDefinition = xdoDataDefinition; } 
  
  // ==============================================================================================
  // methods for getting and setting child Data Parameter view objects (class array)
  // ==============================================================================================
  public XdoRequestDataParam[] getDataParameters() { return this.dataParameters; } 
  public XdoRequestDataParam getDataParameter(int index) { return this.dataParameters[index]; } 
  public int getDataParameterCount()
  { 
    if(this.dataParameters != null) {
      return this.dataParameters.length;
    }
    else {
      return 0;
    }
  } 
  public void setDataParameters(XdoRequestDataParam[] dataParameters) { this.dataParameters = dataParameters; } 
   
  // ==============================================================================================
  // method for returning the table name associated with this view object
  // ==============================================================================================
  public static String getTableName() { return TABLE_NAME; } 
}