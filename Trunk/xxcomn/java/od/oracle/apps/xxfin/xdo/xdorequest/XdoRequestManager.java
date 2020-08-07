// +======================================================================================+
// | Office Depot - Project Simplify                                                      |
// | Providge Consulting                                                                  |
// +======================================================================================+
// |  Class:         XdoRequestDataParam.java                                             |
// |  Description:   This class manages all the functions required by an XDO Request to   |
// |                 process the request, process xml data to a XML Template, and deliver |
// |                 the produced document through the Oracle XML Publisher Delivery      |
// |                 Manager APIs.                                                        |
// |                                                                                      |
// |  Change Record:                                                                      |
// |  ==========================                                                          |
// |Version   Date          Author             Remarks                                    |
// |=======   ===========   ================   ========================================== |
// |1.0       26-JUN-2007   BLooman            Initial version                            |
// |                                                                                      |
// +======================================================================================+
 
package od.oracle.apps.xxfin.xdo.xdorequest;

import java.io.*;
import java.util.Vector;
import com.sun.java.util.collections.Hashtable;
import javax.mail.MessagingException;
import java.sql.SQLException;
import java.sql.Connection;
import oracle.sql.BLOB;
import oracle.sql.CLOB;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
import oracle.apps.fnd.common.*;
import oracle.apps.xdo.oa.schema.server.Template;
import oracle.apps.xdo.oa.schema.server.TemplateHelper;
import oracle.apps.xdo.dataengine.DataTemplate;
import oracle.apps.xdo.dataengine.XMLPGEN;
import oracle.apps.xdo.XDOException;
import oracle.apps.xdo.delivery.*;
import oracle.apps.xdo.delivery.smtp.*;

public class XdoRequestManager {
  
  // ==============================================================================================
  // class properties
  // ==============================================================================================
  private AppsContext appsContext;  
  private boolean debugMode;
  
  // ==============================================================================================
  // class constructor - not generally needed since methods used are static
  // ==============================================================================================
  public XdoRequestManager(AppsContext appsContext, boolean debugMode) {
    this.appsContext = appsContext;
    this.debugMode = debugMode;
  }
  
  // ==============================================================================================
  // class constructor - not generally needed since methods used are static
  // ==============================================================================================
  public XdoRequestManager(AppsContext appsContext) {
    this(appsContext,false);
  }
  
  // ==============================================================================================
  // toggle debug mode
  // ==============================================================================================
  public void setDebugMode(boolean debugMode) {
    this.debugMode = debugMode;
  }
  
  // ==============================================================================================
  // function to print line to System.out if debug is on
  // ==============================================================================================
  private static void debugLine(String buffer) {
    if (buffer != null) {
      System.out.println(buffer);
    }
    else {
      System.out.println("");
    }
  }
  
  // ==============================================================================================
  // function for updating request status of XDO Request
  // ==============================================================================================
  public static void setRequestStatus(AppsContext appsContext, XdoRequest xdoRequest, 
      String status, boolean autonomousTransaction )      
    throws SQLException 
  {
    debugLine("public static void XdoRequestManager.setRequestStatus(AppsContext appsContext, XdoRequest xdoRequest, String status, boolean autonomousTransaction)");
    debugLine("  XDO Request ID         : " + xdoRequest.getXdoRequestId().intValue() );
    debugLine("  New Status             : " + status );
    debugLine("  Autonomous Transaction : " + autonomousTransaction );
    debugLine("  " );
    
    OracleCallableStatement sqlStmt = null;    
    try {
      Connection connection = appsContext.getJDBCConnection();
      // ==============================================================================================
      // call XDO Request API to update status, declare autonomous trx if requested
      // ==============================================================================================
      StringBuffer sqlSB = new StringBuffer();
      if (autonomousTransaction) {
        sqlSB.append("DECLARE ");
        sqlSB.append("  PRAGMA AUTONOMOUS_TRANSACTION; ");
      }
      sqlSB.append("BEGIN ");
      sqlSB.append("  XX_XDO_REQUESTS_API_PKG.update_request_status ");
      sqlSB.append("  ( p_xdo_request_id    => ?, ");
      sqlSB.append("    p_process_status    => ? ); ");
      if (autonomousTransaction) {
        sqlSB.append("  COMMIT; ");
        sqlSB.append("EXCEPTION");
        sqlSB.append("  WHEN OTHERS THEN ");
        sqlSB.append("    ROLLBACK; ");
        sqlSB.append("    RAISE; ");
      }
      sqlSB.append("END; ");
      
      sqlStmt = (OracleCallableStatement)connection.prepareCall(sqlSB.toString());
      sqlStmt.setNUMBER(1,xdoRequest.getXdoRequestId());
      sqlStmt.setString(2,status);      
      boolean returnValue = sqlStmt.execute();
      
      sqlStmt.close();
      sqlStmt = null;
    }
    catch(SQLException sqlException)
    { try { sqlStmt.close(); }
      catch(Exception e) { }
      finally { }
      throw sqlException;
    }
	finally {
	try {
	   if (sqlStmt!=null)
		 sqlStmt.close();
	   }
	catch(Exception e) {}
	}
  }
  
  // ==============================================================================================
  // function for updating request status of XDO Request and children (documents and destinations)
  // ==============================================================================================
  public static void setRequestStatusALL(AppsContext appsContext, XdoRequest xdoRequest, 
      String status, boolean autonomousTransaction )      
    throws SQLException 
  {
    debugLine("public static void setRequestStatusALL(AppsContext appsContext, XdoRequest xdoRequest, String status, boolean autonomousTransaction )");
    debugLine("  XDO Request ID         : " + xdoRequest.getXdoRequestId().intValue() );
    debugLine("  New Status             : " + status );
    debugLine("  Autonomous Transaction : " + autonomousTransaction );
    debugLine("  " );
    
    OracleCallableStatement sqlStmt = null;
    try {
      Connection connection = appsContext.getJDBCConnection();
      StringBuffer sqlSB = new StringBuffer();
      // ==============================================================================================
      // call XDO Request API to update status, declare autonomous trx if requested
      // ==============================================================================================
      if (autonomousTransaction) {
        sqlSB.append("DECLARE ");
        sqlSB.append("  PRAGMA AUTONOMOUS_TRANSACTION; ");
      }
      sqlSB.append("BEGIN ");
      sqlSB.append("  XX_XDO_REQUESTS_API_PKG.update_request_status_all ");
      sqlSB.append("  ( p_xdo_request_id    => ?, ");
      sqlSB.append("    p_process_status    => ? ); ");
      if (autonomousTransaction) {
        sqlSB.append("  COMMIT; ");
        sqlSB.append("EXCEPTION");
        sqlSB.append("  WHEN OTHERS THEN ");
        sqlSB.append("    ROLLBACK; ");
        sqlSB.append("    RAISE; ");
      }
      sqlSB.append("END; ");
      
      sqlStmt = (OracleCallableStatement)connection.prepareCall(sqlSB.toString());
      sqlStmt.setNUMBER(1,xdoRequest.getXdoRequestId());
      sqlStmt.setString(2,status);      
      boolean returnValue = sqlStmt.execute();
      
      sqlStmt.close();
      sqlStmt = null;
    }
    catch(SQLException sqlException)
    { try { sqlStmt.close(); }
      catch(Exception e) { }
      finally { }
      throw sqlException;
    }
	finally {
	try {
	   if (sqlStmt!=null)
		 sqlStmt.close();
	   }
	catch(Exception e) {}
	}
  }
  
  // ==============================================================================================
  // function for updating request status of XDO Request Document
  // ==============================================================================================
  public static void setRequestDocStatus(AppsContext appsContext, XdoRequestDoc xdoRequestDoc, 
      String status, boolean autonomousTransaction )      
    throws SQLException 
  {
    debugLine("public static void setRequestDocStatus(AppsContext appsContext, XdoRequestDoc xdoRequestDoc, String status, boolean autonomousTransaction )");
    debugLine("  XDO Document ID        : " + xdoRequestDoc.getXdoDocumentId().intValue() );
    debugLine("  XDO Request ID         : " + xdoRequestDoc.getXdoRequestId().intValue() );
    debugLine("  New Status             : " + status );
    debugLine("  Autonomous Transaction : " + autonomousTransaction );
    debugLine("  " );
    
    OracleCallableStatement sqlStmt = null;
    try {
      Connection connection = appsContext.getJDBCConnection();
      StringBuffer sqlSB = new StringBuffer();
      // ==============================================================================================
      // call XDO Request API to update status, declare autonomous trx if requested
      // ==============================================================================================
      if (autonomousTransaction) {
        sqlSB.append("DECLARE ");
        sqlSB.append("  PRAGMA AUTONOMOUS_TRANSACTION; ");
      }
      sqlSB.append("BEGIN ");
      sqlSB.append("  XX_XDO_REQUESTS_API_PKG.update_request_doc_status ");
      sqlSB.append("  ( p_xdo_document_id   => ?, ");
      sqlSB.append("    p_process_status    => ? ); ");
      if (autonomousTransaction) {
        sqlSB.append("  COMMIT; ");
        sqlSB.append("EXCEPTION");
        sqlSB.append("  WHEN OTHERS THEN ");
        sqlSB.append("    ROLLBACK; ");
        sqlSB.append("    RAISE; ");
      }
      sqlSB.append("END; ");
      
      sqlStmt = (OracleCallableStatement)connection.prepareCall(sqlSB.toString());
      sqlStmt.setNUMBER(1,xdoRequestDoc.getXdoDocumentId());
      sqlStmt.setString(2,status);      
      boolean returnValue = sqlStmt.execute();
      
      sqlStmt.close();
      sqlStmt = null;
    }
    catch(SQLException sqlException)
    { try { sqlStmt.close(); }
      catch(Exception e) { }
      finally { }
      throw sqlException;
    }
	finally {
	try {
	   if (sqlStmt!=null)
		 sqlStmt.close();
	   }
	catch(Exception e) {}
	}
  }
  
  // ==============================================================================================
  // function for updating the request status of XDO Request Destination
  // ==============================================================================================
  public static void setRequestDestStatus(AppsContext appsContext, XdoRequestDest xdoRequestDest, 
      String status, boolean autonomousTransaction )      
    throws SQLException 
  {
    debugLine("public static void setRequestDestStatus(AppsContext appsContext, XdoRequestDest xdoRequestDest, String status, boolean autonomousTransaction )");
    debugLine("  XDO Destination ID     : " + xdoRequestDest.getXdoDestinationId().intValue() );
    debugLine("  XDO Request ID         : " + xdoRequestDest.getXdoRequestId().intValue() );
    debugLine("  New Status             : " + status );
    debugLine("  Autonomous Transaction : " + autonomousTransaction );
    debugLine("  " );
    
    OracleCallableStatement sqlStmt = null;
    try {
      Connection connection = appsContext.getJDBCConnection();
      // ==============================================================================================
      // call XDO Request API to update status, declare autonomous trx if requested
      // ==============================================================================================
      StringBuffer sqlSB = new StringBuffer();
      if (autonomousTransaction) {
        sqlSB.append("DECLARE ");
        sqlSB.append("  PRAGMA AUTONOMOUS_TRANSACTION; ");
      }
      sqlSB.append("BEGIN ");
      sqlSB.append("  XX_XDO_REQUESTS_API_PKG.update_request_dest_status ");
      sqlSB.append("  ( p_xdo_destination_id  => ?, ");
      sqlSB.append("    p_process_status      => ? ); ");
      if (autonomousTransaction) {
        sqlSB.append("  COMMIT; ");
        sqlSB.append("EXCEPTION");
        sqlSB.append("  WHEN OTHERS THEN ");
        sqlSB.append("    ROLLBACK; ");
        sqlSB.append("    RAISE; ");
      }
      sqlSB.append("END; ");
      
      sqlStmt = (OracleCallableStatement)connection.prepareCall(sqlSB.toString());
      sqlStmt.setNUMBER(1,xdoRequestDest.getXdoDestinationId());
      sqlStmt.setString(2,status);      
      boolean returnValue = sqlStmt.execute();
      
      sqlStmt.close();
      sqlStmt = null;
    }
    catch(SQLException sqlException)
    { try { sqlStmt.close(); }
      catch(Exception e) { }
      finally { }
      throw sqlException;
    }
	finally {
	try {
	   if (sqlStmt!=null)
		 sqlStmt.close();
	   }
	catch(Exception e) {}
	}
  }
  
  // ==============================================================================================
  // function for updating the document xml data column with data definition generated xml
  // ==============================================================================================
  public static void updateXMLData(AppsContext appsContext, XdoRequestDoc xdoRequestDoc, 
      CLOB xmlData, boolean autonomousTransaction )
    throws SQLException 
  {
    debugLine("public static void updateXMLData(AppsContext appsContext, XdoRequestDoc xdoRequestDoc, CLOB xmlData, boolean autonomousTransaction )");
    debugLine("  XDO Document ID        : " + xdoRequestDoc.getXdoDocumentId().intValue() );
    debugLine("  XDO Request ID         : " + xdoRequestDoc.getXdoRequestId().intValue() );
    debugLine("  Autonomous Transaction : " + autonomousTransaction );
    debugLine("  " );
    
    OracleCallableStatement sqlStmt = null;
    try {
      Connection connection = appsContext.getJDBCConnection();
      StringBuffer sqlSB = new StringBuffer();
      // ==============================================================================================
      // update document table with XML data, declare autonomous trx if requested
      // ==============================================================================================
      if (autonomousTransaction) {
        sqlSB.append("DECLARE ");
        sqlSB.append("  PRAGMA AUTONOMOUS_TRANSACTION; ");
      }
      sqlSB.append("BEGIN ");
      sqlSB.append("  UPDATE xx_xdo_request_docs ");
      sqlSB.append("     SET xml_data = ?, ");
      sqlSB.append("         process_status = ?, ");
      sqlSB.append("         last_updated_by = FND_GLOBAL.USER_ID, ");
      sqlSB.append("         last_update_date = SYSDATE, ");
      sqlSB.append("         last_update_login = FND_GLOBAL.LOGIN_ID ");
      sqlSB.append("   WHERE xdo_document_id = ?; " );
      if (autonomousTransaction) {
        sqlSB.append("  COMMIT; ");
        sqlSB.append("EXCEPTION");
        sqlSB.append("  WHEN OTHERS THEN ");
        sqlSB.append("    ROLLBACK; ");
        sqlSB.append("    RAISE; ");
      }
      sqlSB.append("END; ");
      sqlStmt = (OracleCallableStatement)connection.prepareCall(sqlSB.toString());
      
      // ==============================================================================================
      // set xml data (CLOB) and status to GENERATED for this Document Id
      // ==============================================================================================
      sqlStmt.setCLOB(1,xmlData);
      sqlStmt.setString(2,"GENERATED");
      sqlStmt.setNUMBER(3,xdoRequestDoc.getXdoDocumentId());
      boolean returnValue = sqlStmt.execute();
   
      sqlStmt.close();
      sqlStmt = null;
    }
    catch(SQLException sqlException)
    { try { sqlStmt.close(); }
      catch(Exception e) { }
      finally { }
      throw sqlException;
    }
	finally {
	try {
	   if (sqlStmt!=null)
		 sqlStmt.close();
	   }
	catch(Exception e) {}
	}
  }
  
  // ==============================================================================================
  // function for updating the document xml data column with data definition generated xml
  // ==============================================================================================
  public static void updateDocumentData(AppsContext appsContext, XdoRequestDoc xdoRequestDoc, 
      BLOB documentData, boolean autonomousTransaction )
    throws SQLException 
  {
    debugLine("public static void updateDocumentData(AppsContext appsContext, XdoRequestDoc xdoRequestDoc, BLOB documentData, boolean autonomousTransaction )");
    debugLine("  XDO Document ID        : " + xdoRequestDoc.getXdoDocumentId().intValue() );
    debugLine("  XDO Request ID         : " + xdoRequestDoc.getXdoRequestId().intValue() );
    debugLine("  Autonomous Transaction : " + autonomousTransaction );
    debugLine("  " );
    
    OracleCallableStatement sqlStmt = null;
    try {
      Connection connection = appsContext.getJDBCConnection();
      StringBuffer sqlSB = new StringBuffer();
      // ==============================================================================================
      // update document table with document data, declare autonomous trx if requested
      // ==============================================================================================
      if (autonomousTransaction) {
        sqlSB.append("DECLARE ");
        sqlSB.append("  PRAGMA AUTONOMOUS_TRANSACTION; ");
      }
      sqlSB.append("BEGIN ");
      sqlSB.append("  UPDATE xx_xdo_request_docs ");
      sqlSB.append("     SET document_data = ?, ");
      sqlSB.append("         process_status = ?, ");
      sqlSB.append("         last_updated_by = FND_GLOBAL.USER_ID, ");
      sqlSB.append("         last_update_date = SYSDATE, ");
      sqlSB.append("         last_update_login = FND_GLOBAL.LOGIN_ID ");
      sqlSB.append("   WHERE xdo_document_id = ?; " );
      if (autonomousTransaction) {
        sqlSB.append("  COMMIT; ");
        sqlSB.append("EXCEPTION");
        sqlSB.append("  WHEN OTHERS THEN ");
        sqlSB.append("    ROLLBACK; ");
        sqlSB.append("    RAISE; ");
      }
      sqlSB.append("END; ");
      sqlStmt = (OracleCallableStatement)connection.prepareCall(sqlSB.toString());
      
      // ==============================================================================================
      // set document data (BLOB) and status to GENERATED for this Document Id
      // ==============================================================================================
      sqlStmt.setBLOB(1,documentData);
      sqlStmt.setString(2,"GENERATED");
      sqlStmt.setNUMBER(3,xdoRequestDoc.getXdoDocumentId());
      boolean returnValue = sqlStmt.execute();
   
      sqlStmt.close();
      sqlStmt = null;
    }
    catch(SQLException sqlException)
    { try { sqlStmt.close(); }
      catch(Exception e) { }
      finally { }
      throw sqlException;
    }
	finally {
	try {
	   if (sqlStmt!=null)
		 sqlStmt.close();
	   }
	catch(Exception e) {}
	}
  }
  
  // ==============================================================================================
  // function that retrieves an array of XDO Requests for the given Request Group Id and Request Id
  // ==============================================================================================
  public static XdoRequest[] getRequests
    (AppsContext appsContext, int xdoRequestGroupId, int xdoRequestId)      
      throws SQLException, Exception
  {
    debugLine("public static XdoRequest[] getRequests (AppsContext appsContext, int xdoRequestGroupId, int xdoRequestId)");
    debugLine("  XDO Request Group ID : " + xdoRequestGroupId );
    debugLine("  XDO Request ID       : " + xdoRequestId );
    debugLine("  " );
    
    OraclePreparedStatement sqlStmt = null;
    OracleResultSet resultSet = null;
    try {
      Connection connection = appsContext.getJDBCConnection();
      // ==============================================================================================
      // query to retrieve all the request records for the given XDO Request Id
      // ==============================================================================================
      StringBuffer sqlSB = new StringBuffer();
      sqlSB.append("SELECT * ");
      sqlSB.append("  FROM xx_xdo_requests ");
      sqlSB.append(" WHERE process_status = 'PENDING' ");
      if (xdoRequestGroupId >= 0) {
        sqlSB.append("   AND xdo_request_group_id = " + xdoRequestGroupId + " " );
      }
      if (xdoRequestId >= 0) {
        sqlSB.append("   AND xdo_request_id = " + xdoRequestId + " " );
      }
      //sqlSB.append("   FOR UPDATE " );
      sqlStmt = (OraclePreparedStatement)connection.prepareStatement(sqlSB.toString());
      resultSet = (OracleResultSet)sqlStmt.executeQuery();
      
      Vector records = new Vector(5);
      XdoRequest request;
      
      // ==============================================================================================
      // loop through each row of the result set
      // ==============================================================================================
      for(; resultSet.next(); records.addElement(request) ) {
        // ==============================================================================================
        // create an instance of the XDO Request for each record found
        // ==============================================================================================
        request = XdoRequest.createInstance();
        
        // ==============================================================================================
        // set all the values in the XDO Request
        // ==============================================================================================
        request.setXdoRequestId(resultSet.getNUMBER("XDO_REQUEST_ID")); 
        request.setXdoRequestDate(resultSet.getDATE("XDO_REQUEST_DATE")); 
        request.setXdoRequestName(resultSet.getString("XDO_REQUEST_NAME")); 
        request.setXdoRequestGroupId(resultSet.getNUMBER("XDO_REQUEST_GROUP_ID")); 
        request.setLanguageCode(resultSet.getString("LANGUAGE_CODE")); 
        request.setSourceAppCode(resultSet.getString("SOURCE_APP_CODE")); 
        request.setSourceName(resultSet.getString("SOURCE_NAME")); 
        request.setDaysToKeep(resultSet.getNUMBER("DAYS_TO_KEEP")); 
        request.setProcessStatus(resultSet.getString("PROCESS_STATUS")); 
        request.setCreationDate(resultSet.getDATE("CREATION_DATE")); 
        request.setCreatedBy(resultSet.getNUMBER("CREATED_BY")); 
        request.setLastUpdateDate(resultSet.getDATE("LAST_UPDATE_DATE")); 
        request.setLastUpdatedBy(resultSet.getNUMBER("LAST_UPDATED_BY")); 
        request.setLastUpdateLogin(resultSet.getNUMBER("LAST_UPDATE_LOGIN")); 
        request.setProgramApplicationId(resultSet.getNUMBER("PROGRAM_APPLICATION_ID")); 
        request.setProgramId(resultSet.getNUMBER("PROGRAM_ID")); 
        request.setProgramUpdateDate(resultSet.getDATE("PROGRAM_UPDATE_DATE")); 
        request.setRequestId(resultSet.getNUMBER("REQUEST_ID"));
        
        debugLine("Retrieved Xdo Request:");
        debugLine("  Group Id = " + request.getXdoRequestGroupId().intValue() );
        debugLine("  Id = " + request.getXdoRequestId().intValue() );
        debugLine("  Name = " + request.getXdoRequestName() );
        debugLine("  " );
        
        request.setRequestDocs(XdoRequestManager.getRequestDocs
          (appsContext,request.getXdoRequestId().intValue()));
        request.setRequestDests(XdoRequestManager.getRequestDests
          (appsContext,request.getXdoRequestId().intValue()));
      }
      
      // ==============================================================================================
      // copy the objects in the vector to an array of XDO Requests
      // ==============================================================================================
      XdoRequest requests[] = null;
      if(records.size() > 0) {
        requests = new XdoRequest[records.size()];
        records.copyInto(requests);
      }
      
      resultSet.close();
      sqlStmt.close();
      resultSet = null;
      sqlStmt = null;
      
      return requests;
    }
    catch(SQLException sqlException)
    { try { resultSet.close(); }
      catch(Exception e) { }
      try { sqlStmt.close(); }
      catch(Exception e) { }
      finally { }
      throw sqlException;
    }
	finally {
	try {
	   if (sqlStmt!=null)
		 sqlStmt.close();
	   if (resultSet!=null)
		 resultSet.close();
	   }
	catch(Exception e) {}
	}
  }
  
  // ==============================================================================================
  // function that retrieves an array of XDO Requests for the given Request Group Id
  //   overloaded function that sets the request id = -1
  // ==============================================================================================
  public static XdoRequest[] getRequests(AppsContext appsContext, int xdoRequestGroupId)      
      throws SQLException, Exception
  { 
    debugLine("public static XdoRequest[] getRequests(AppsContext appsContext, int xdoRequestGroupId)");
    debugLine("  XDO Request Group ID : " + xdoRequestGroupId );
    debugLine("  " );
    
    return getRequests(appsContext, xdoRequestGroupId, -1);
  }
  
  // ==============================================================================================
  // function that retrieves an array of XDO Data Definition Params for the given Request Document Id
  // ==============================================================================================
  public static XdoRequestDataParam[] getRequestDataParams
    (AppsContext appsContext, int xdoDocumentId)      
      throws SQLException 
  {
    debugLine("public static XdoRequest[] getXdoRequestDatamParams (AppsContext appsContext, int xdoDocumentId)");
    debugLine("  XDO Document ID : " + xdoDocumentId );
    debugLine("  " );
    
    OraclePreparedStatement sqlStmt = null;
    OracleResultSet resultSet = null;
    try {
      Connection connection = appsContext.getJDBCConnection();
      // ==============================================================================================
      // query to retrieve all the data definition parameter records for the given XDO Request Id
      // ==============================================================================================
      StringBuffer sqlSB = new StringBuffer();
      sqlSB.append("SELECT * ");
      sqlSB.append("  FROM xx_xdo_request_data_params ");
      sqlSB.append(" WHERE xdo_document_id = " + xdoDocumentId + " " );
      sqlSB.append(" ORDER BY parameter_number " );
      //sqlSB.append("   FOR UPDATE " );
      sqlStmt = (OraclePreparedStatement)connection.prepareStatement(sqlSB.toString());
      resultSet = (OracleResultSet)sqlStmt.executeQuery();
      
      Vector records = new Vector(5);
      XdoRequestDataParam dataParameter;
      
      // ==============================================================================================
      // loop through each row of the result set
      // ==============================================================================================
      for(; resultSet.next(); records.addElement(dataParameter) ) {
        // ==============================================================================================
        // create an instance of the XDO Request Data Parameter for each record found
        // ==============================================================================================
        dataParameter = XdoRequestDataParam.createInstance();
        
        // ==============================================================================================
        // set all the values in the XDO Request Data Parameter
        // ==============================================================================================
        dataParameter.setXdoDataParamId(resultSet.getNUMBER("XDO_DATA_PARAM_ID")); 
        dataParameter.setXdoDocumentId(resultSet.getNUMBER("XDO_DOCUMENT_ID")); 
        dataParameter.setParameterNumber(resultSet.getNUMBER("PARAMETER_NUMBER")); 
        dataParameter.setParameterName(resultSet.getString("PARAMETER_NAME")); 
        dataParameter.setParameterValue(resultSet.getString("PARAMETER_VALUE")); 
        dataParameter.setCreationDate(resultSet.getDATE("CREATION_DATE")); 
        dataParameter.setCreatedBy(resultSet.getNUMBER("CREATED_BY")); 
        dataParameter.setLastUpdateDate(resultSet.getDATE("LAST_UPDATE_DATE")); 
        dataParameter.setLastUpdatedBy(resultSet.getNUMBER("LAST_UPDATED_BY")); 
        dataParameter.setLastUpdateLogin(resultSet.getNUMBER("LAST_UPDATE_LOGIN"));
        
        debugLine("Retrieved Template Data Parameter:");
        debugLine("  Name = " + dataParameter.getParameterName() );
        debugLine("  Value = " + dataParameter.getParameterValue() );
        debugLine("  " );
      }
      
      // ==============================================================================================
      // copy the objects in the vector to an array of XDO Request data parameters
      // ==============================================================================================
      XdoRequestDataParam dataParameters[] = null;
      if(records.size() > 0) {
        dataParameters = new XdoRequestDataParam[records.size()];
        records.copyInto(dataParameters);
      }
      
      resultSet.close();
      sqlStmt.close();
      resultSet = null;
      sqlStmt = null;
      
      return dataParameters;
    }
    catch(SQLException sqlException)
    { try { resultSet.close(); }
      catch(Exception e) { }
      try { sqlStmt.close(); }
      catch(Exception e) { }
      finally { }
      throw sqlException;
    }
	finally {
	try {
	   if (sqlStmt!=null)
		 sqlStmt.close();
	   if (resultSet!=null)
		 resultSet.close();
	   }
	catch(Exception e) {}
	}
  }
  
  // ==============================================================================================
  // function that retrieves an array of XDO Request Documents for the given Request Group Id
  // ==============================================================================================
  public static XdoRequestDoc[] getRequestDocs(AppsContext appsContext, int xdoRequestId)      
    throws SQLException, Exception  
  {
    debugLine("public static XdoRequestDoc[] getRequestDocs(AppsContext appsContext, int xdoRequestId)");
    debugLine("  XDO Request ID : " + xdoRequestId );
    debugLine("  " );
    
    OraclePreparedStatement sqlStmt = null;
    OracleResultSet resultSet = null;
    try {
      Connection connection = appsContext.getJDBCConnection();
      // ==============================================================================================
      // query to retrieve all the document records for the given XDO Request Id
      // ==============================================================================================
      StringBuffer sqlSB = new StringBuffer();
      sqlSB.append("SELECT * ");
      sqlSB.append("  FROM xx_xdo_request_docs ");
      sqlSB.append(" WHERE xdo_request_id = " + xdoRequestId + " " );
      //sqlSB.append("   FOR UPDATE " );
      sqlStmt = (OraclePreparedStatement)connection.prepareStatement(sqlSB.toString());
      resultSet = (OracleResultSet)sqlStmt.executeQuery();
      
      Vector records = new Vector(3);
      XdoRequestDoc requestDoc;
      String xdoAppShortName;
      String xdoTemplateCode;
      String xdoDataAppName;
      String xdoDataDefCode;
      
      // ==============================================================================================
      // loop through each row of the result set
      // ==============================================================================================
      for(; resultSet.next(); records.addElement(requestDoc) ) {
        // ==============================================================================================
        // create an instance of the XDO Request Document for each record found
        // ==============================================================================================
        requestDoc = XdoRequestDoc.createInstance();
        
        // ==============================================================================================
        // set all the values in the XDO Request Document
        // ==============================================================================================
        requestDoc.setXdoDocumentId(resultSet.getNUMBER("XDO_DOCUMENT_ID")); 
        requestDoc.setXdoRequestId(resultSet.getNUMBER("XDO_REQUEST_ID")); 
        requestDoc.setXmlData(resultSet.getCLOB("XML_DATA"));
          
        xdoAppShortName = resultSet.getString("XDO_APP_SHORT_NAME");
        xdoTemplateCode = resultSet.getString("XDO_TEMPLATE_CODE");
        requestDoc.setXdoAppShortName(xdoAppShortName); 
        requestDoc.setXdoTemplateCode(xdoTemplateCode); 
          
        xdoDataAppName = resultSet.getString("XDO_DATA_APP_NAME");
        xdoDataDefCode = resultSet.getString("XDO_DATA_DEF_CODE");
        requestDoc.setXdoAppShortName(xdoDataAppName); 
        requestDoc.setXdoTemplateCode(xdoDataDefCode); 
          
        requestDoc.setSourceAppCode(resultSet.getString("SOURCE_APP_CODE")); 
        requestDoc.setSourceName(resultSet.getString("SOURCE_NAME")); 
        requestDoc.setSourceKey1(resultSet.getString("SOURCE_KEY1")); 
        requestDoc.setSourceKey2(resultSet.getString("SOURCE_KEY2")); 
        requestDoc.setSourceKey3(resultSet.getString("SOURCE_KEY3")); 
        requestDoc.setStoreDocumentFlag(resultSet.getString("STORE_DOCUMENT_FLAG")); 
        requestDoc.setDocumentData(resultSet.getBLOB("DOCUMENT_DATA")); 
        requestDoc.setDocumentFileName(resultSet.getString("DOCUMENT_FILE_NAME")); 
        requestDoc.setDocumentFileType(resultSet.getString("DOCUMENT_FILE_TYPE")); 
        requestDoc.setDocumentContentType(resultSet.getString("DOCUMENT_CONTENT_TYPE")); 
        requestDoc.setLanguageCode(resultSet.getString("LANGUAGE_CODE")); 
        requestDoc.setProcessStatus(resultSet.getString("PROCESS_STATUS")); 
        requestDoc.setCreationDate(resultSet.getDATE("CREATION_DATE")); 
        requestDoc.setCreatedBy(resultSet.getNUMBER("CREATED_BY")); 
        requestDoc.setLastUpdateDate(resultSet.getDATE("LAST_UPDATE_DATE")); 
        requestDoc.setLastUpdatedBy(resultSet.getNUMBER("LAST_UPDATED_BY")); 
        requestDoc.setLastUpdateLogin(resultSet.getNUMBER("LAST_UPDATE_LOGIN")); 
        requestDoc.setProgramApplicationId(resultSet.getNUMBER("PROGRAM_APPLICATION_ID")); 
        requestDoc.setProgramId(resultSet.getNUMBER("PROGRAM_ID")); 
        requestDoc.setProgramUpdateDate(resultSet.getDATE("PROGRAM_UPDATE_DATE")); 
        requestDoc.setRequestId(resultSet.getNUMBER("REQUEST_ID"));
        
        debugLine("Retrieved Xdo Template Document:");
        debugLine("  Document Id = " + requestDoc.getXdoDocumentId().intValue() );
        debugLine("  " );
        
        // ==============================================================================================
        // set the data template parameters for the given XDO Request document
        // ==============================================================================================
        requestDoc.setDataParameters(XdoRequestManager.getRequestDataParams
          (appsContext,requestDoc.getXdoDocumentId().intValue()));
        
        // ==============================================================================================
        // if the XML Publisher Template is defined, create an instance of the XDO Template
        // ==============================================================================================
        if (  xdoAppShortName != null && xdoAppShortName.length() > 0 
           && xdoTemplateCode != null && xdoTemplateCode.length() > 0 ) 
        {
          Template xdoTemplate = 
            TemplateHelper.getTemplate(appsContext,xdoAppShortName,xdoTemplateCode);
        
          requestDoc.setXdoTemplate(xdoTemplate);
        }
        
        // ==============================================================================================
        // if the XML Publisher Data Definition is defined, create an instance of the XDO Data Definition
        // ==============================================================================================
        if (  xdoDataAppName != null && xdoDataAppName.length() > 0 
           && xdoDataDefCode != null && xdoDataDefCode.length() > 0 ) 
        {
          // ==============================================================================================
          // create an instance of the Data Definition for the given connection, and set it on the document
          // ==============================================================================================
          DataTemplate xdoDataDefinition = new DataTemplate();
          xdoDataDefinition.setOracleConnection(connection);
          requestDoc.setXdoDataDefinition(xdoDataDefinition);
          
          // ==============================================================================================
          // create a Hashtable to store all the data definition parameters
          // ==============================================================================================
          Hashtable dataParams = new Hashtable();
          
          // ==============================================================================================
          // loop through the data parameters fetched and add them to the hashtable
          // ==============================================================================================
          for(int p=0;p<requestDoc.getDataParameterCount();p++) {
            dataParams.put
            ( requestDoc.getDataParameter(p).getParameterName(), 
              requestDoc.getDataParameter(p).getParameterValue() );
          }
          
          //CLOB xmlClob = xdoDataDefinition.getXML(xdoDataAppName,xdoDataDefCode, dataParams);
          
          // ==============================================================================================
          // define the XML data temporary file to write the process data definition to
          // ==============================================================================================
          String xmlDataFileName = 
            System.getProperty("java.io.tmpdir") + System.getProperty("file.separator") +
              "xx-xdo-xml-" + requestDoc.getXdoDocumentId().stringValue() + "-" +
                requestDoc.getXdoRequestId().stringValue() + "-tmp.xml";
                
          debugLine("Tmp Xml Data File= " + xmlDataFileName );
          
          // ==============================================================================================
          // try to process the XML data based on the XML Publisher data definition
          // ==============================================================================================
          try {
            xdoDataDefinition.writeXML(xdoDataAppName,xdoDataDefCode, dataParams, xmlDataFileName, "");
          }
          catch(Exception e) {
            throw new XDOException("Structure errors exist in the XML Data Definition.");
          }
          
          // ==============================================================================================
          // try to define and read the generated XML data file created
          // ==============================================================================================
          FileInputStream xmlDataFile;            
          try {
            xmlDataFile = new FileInputStream(xmlDataFileName);
          }
          catch(Exception e) {
            throw new XDOException("Unable to read the generated XML data file from the temp directory.");
          }
          
          // ==============================================================================================
          // create a byte array to store the XML data file contents
          // ==============================================================================================
          byte[] xmlBytes = new byte[xmlDataFile.available()];
           
          // ==============================================================================================
          // read all the content from the XML data file into the byte array, and create a string of the
          //   byte array
          // ==============================================================================================
          xmlDataFile.read(xmlBytes);
          
          // ==============================================================================================
          // for testing purposes, this will print the entire contents of the XML data file
          // ==============================================================================================
          if (false) {
            String xmlDebug = new String(xmlBytes,"UTF-8");
            System.out.println("XML");
            System.out.println("");
            System.out.print(xmlDebug);
            System.out.println("");
            System.out.println("");
          }

          // ==============================================================================================
          // create a temporary CLOB 
          // ==============================================================================================
          CLOB xmlClob = CLOB.createTemporary
            (appsContext.getJDBCConnection(), true, CLOB.DURATION_SESSION);
            
          // ==============================================================================================
          // get an OutputStream from the CLOB, and write the bytes to the CLOB
          // ==============================================================================================
          OutputStream xmlOut = xmlClob.getAsciiOutputStream();
          xmlOut.write(xmlBytes);
          
          // ==============================================================================================
          // write the XML data to the document record - removed for space considerations
          // ==============================================================================================
          // write CLOB xml data to xdo request document table for the given document id
          //if (xdoRequest.getRequestDoc(i).getStoreXmlFlag().equals("Y")) {
          //  XdoRequestManager.updateXmlData
          //    (appsContext,xdoRequest.getRequestDoc(i),xmlClob,true);
          //}
          
          // ==============================================================================================
          // set XML data as cached byte array on request document that can be accessed later
          // ==============================================================================================
          requestDoc.setCachedXmlDataBytes(xmlBytes);
          
          // ==============================================================================================
          // free temporary BLOB storage space
          // ==============================================================================================
          xmlClob.freeTemporary();
        }
      }
      
      // ==============================================================================================
      // copy the objects in the vector to an array of XDO Request documents
      // ==============================================================================================
      XdoRequestDoc requestDocs[] = null;
      if(records.size() > 0) {
        requestDocs = new XdoRequestDoc[records.size()];
        records.copyInto(requestDocs);
      }
      
      resultSet.close();
      sqlStmt.close();
      resultSet = null;
      sqlStmt = null;
      
      return requestDocs;
    }
    catch(SQLException sqlException)
    { try { resultSet.close(); }
      catch(Exception e) { }
      try { sqlStmt.close(); }
      catch(Exception e) { }
      finally { }
      throw sqlException;
    }
	finally {
	try {
	   if (sqlStmt!=null)
		 sqlStmt.close();
	   if (resultSet!=null)
		 resultSet.close();
	   }
	catch(Exception e) {}
	}
  }
  
  // ==============================================================================================
  // function that retrieves an array of XDO Request Destinations for the given Request Group Id
  // ==============================================================================================
  public static XdoRequestDest[] getRequestDests(AppsContext appsContext, int xdoRequestId)      
    throws SQLException 
  {
    debugLine("public static XdoRequestDest[] getRequestDests(AppsContext appsContext, int xdoRequestId)");
    debugLine("  XDO Request ID : " + xdoRequestId );
    debugLine("  " );
    
    OraclePreparedStatement sqlStmt = null;
    OracleResultSet resultSet = null;
    
    try {
      Connection connection = appsContext.getJDBCConnection();
      // ==============================================================================================
      // query to retrieve all the destination records for the given XDO Request Id
      // ==============================================================================================
      StringBuffer sqlSB = new StringBuffer();
      sqlSB.append("SELECT * ");
      sqlSB.append("  FROM xx_xdo_request_dests ");
      sqlSB.append(" WHERE xdo_request_id = " + xdoRequestId + " " );
      //sqlSB.append("   FOR UPDATE " );
      sqlStmt = (OraclePreparedStatement)connection.prepareStatement(sqlSB.toString());
      resultSet = (OracleResultSet)sqlStmt.executeQuery();
      
      Vector records = new Vector(3);
      XdoRequestDest requestDest;
      // ==============================================================================================
      // loop through each row of the result set
      // ==============================================================================================
      for(; resultSet.next(); records.addElement(requestDest) ) {
        // ==============================================================================================
        // create an instance of the XDO Request Destination for each record found
        // ==============================================================================================
        requestDest = XdoRequestDest.createInstance();
    
        // ==============================================================================================
        // set all the values in the XDO Request Destination
        // ==============================================================================================
        requestDest.setXdoDestinationId(resultSet.getNUMBER("XDO_DESTINATION_ID")); 
        requestDest.setXdoRequestId(resultSet.getNUMBER("XDO_REQUEST_ID")); 
        requestDest.setDeliveryMethod(resultSet.getString("DELIVERY_METHOD")); 
        requestDest.setDestination(resultSet.getString("DESTINATION")); 
        requestDest.setLanguageCode(resultSet.getString("LANGUAGE_CODE")); 
        requestDest.setSubjectMessage(resultSet.getString("SUBJECT_MESSAGE")); 
        requestDest.setBodyMessage(resultSet.getCLOB("BODY_MESSAGE")); 
        requestDest.setAttachDocumentsFlag(resultSet.getString("ATTACH_DOCUMENTS_FLAG")); 
        requestDest.setProcessStatus(resultSet.getString("PROCESS_STATUS")); 
        requestDest.setCreationDate(resultSet.getDATE("CREATION_DATE")); 
        requestDest.setCreatedBy(resultSet.getNUMBER("CREATED_BY")); 
        requestDest.setLastUpdateDate(resultSet.getDATE("LAST_UPDATE_DATE")); 
        requestDest.setLastUpdatedBy(resultSet.getNUMBER("LAST_UPDATED_BY")); 
        requestDest.setLastUpdateLogin(resultSet.getNUMBER("LAST_UPDATE_LOGIN")); 
        requestDest.setProgramApplicationId(resultSet.getNUMBER("PROGRAM_APPLICATION_ID")); 
        requestDest.setProgramId(resultSet.getNUMBER("PROGRAM_ID")); 
        requestDest.setProgramUpdateDate(resultSet.getDATE("PROGRAM_UPDATE_DATE")); 
        requestDest.setRequestId(resultSet.getNUMBER("REQUEST_ID"));
        
        debugLine("Retrieved Xdo Template Destination:");
        debugLine("  Destination Id = " + requestDest.getXdoDestinationId().intValue() );
        debugLine("  Delivery Mthd = " + requestDest.getDeliveryMethod() );
        debugLine("  Destination = " + requestDest.getDestination() );
        debugLine("  " );
      }

      // ==============================================================================================
      // copy the objects in the vector to an array of XDO Request destinations
      // ==============================================================================================
      XdoRequestDest requestDests[] = null;
      if(records.size() > 0) {
          requestDests = new XdoRequestDest[records.size()];
          records.copyInto(requestDests);
      }
      
      resultSet.close();
      sqlStmt.close();
      resultSet = null;
      sqlStmt = null;
      
      return requestDests;
    }
    catch(SQLException sqlException)
    { try { resultSet.close(); }
      catch(Exception e) { }
      try { sqlStmt.close(); }
      catch(Exception e) { }
      finally { }
      throw sqlException;
    }
	finally {
	try {
	   if (sqlStmt!=null)
		 sqlStmt.close();
	   if (resultSet!=null)
		 resultSet.close();
	   }
	catch(Exception e) {}
	}
  }
  
  // ==============================================================================================
  // function that gets a required profile value (throws an error if value is not found or empty)
  // ==============================================================================================
  private static String getRequiredProfile(AppsContext appsContext, String profileName) 
    throws XdoRequestException
  {
    return getProfile(appsContext, profileName, true); 
  }
  
  // ==============================================================================================
  // function that gets a profile value (does not have to be defined)
  // ==============================================================================================
  private static String getProfile(AppsContext appsContext, String profileName) 
    throws XdoRequestException
  {
    return getProfile(appsContext, profileName, false); 
  }
  
  // ==============================================================================================
  // function that gets a profile value
  // ==============================================================================================
  private static String getProfile(AppsContext appsContext, String profileName, boolean isRequired) 
    throws XdoRequestException
  {
    // ==============================================================================================
    // get the profile value for the given profile name
    // ==============================================================================================
    String profileValue = (new AppsProfileStore(appsContext)).getProfile(profileName);
    
    // ==============================================================================================
    // if parameter indicates required profile value, then raise an error is value is not defined
    // ==============================================================================================
    if (isRequired) {
      if (profileValue == null || profileValue == "") {
        ErrorStack errorstack = appsContext.getErrorStack();
        errorstack.addMessage("XXFIN", "XX_REQUIRED_PROFILE_VALUE");
        errorstack.addToken("PROFILE", profileName);
        throw new XdoRequestException(errorstack.nextMessage());
      }
    }
    
    // ==============================================================================================
    // return profile value
    // ==============================================================================================
    return profileValue;
  }
  
  // ==============================================================================================
  // function that processes the XDO request for an email destination through the XML Publisher 
  //   delivery manager APIs
  // ==============================================================================================
  private static void processEmailDestination(AppsContext appsContext, XdoRequest xdoRequest, int destNum)
    throws Exception
  {
    debugLine("private static void processEmailDestination(AppsContext appsContext, XdoRequest xdoRequest, int destNum)");
    debugLine("  XDO Request ID     : " + xdoRequest.getXdoRequestId().intValue() );
    debugLine("  Destination Index  : " + destNum );
    debugLine("  " );
    
    // ==============================================================================================
    // get the setup values from the custom XDO Profiles for Email
    // ==============================================================================================
    String smtpHost = getRequiredProfile(appsContext,"XX_XDO_SMTP_HOST");
    String smtpPort = getRequiredProfile(appsContext,"XX_XDO_SMTP_PORT");
    String smtpFrom = getRequiredProfile(appsContext,"XX_XDO_SMTP_FROM");
    
    debugLine("-XDO Email Profiles-");
    debugLine("  Host: " + smtpHost + "; ");
    debugLine("  Port: " + smtpPort + "; ");
    debugLine("  From: " + smtpFrom + "; ");
    debugLine("  " );
    
    // ==============================================================================================
    // update the status on the XDO Request Destination to SENDING
    // ==============================================================================================
    XdoRequestManager.setRequestDestStatus
      (appsContext,xdoRequest.getRequestDest(destNum),"SENDING",true);
    
    // ==============================================================================================
    // create an instance of the XML Publisher delivery manager and define all the Email setups
    // ==============================================================================================
    DeliveryManager dm = new DeliveryManager();
    DeliveryRequest req = dm.createRequest(DeliveryManager.TYPE_SMTP_EMAIL);
    req.addProperty(DeliveryPropertyDefinitions.SMTP_HOST, smtpHost );
    req.addProperty(DeliveryPropertyDefinitions.SMTP_PORT, smtpPort );
    req.addProperty(DeliveryPropertyDefinitions.SMTP_FROM, smtpFrom );
    
    // ==============================================================================================
    // set the email recipients based on the destination in the XDO Request destination record
    // ==============================================================================================
    req.addProperty(DeliveryPropertyDefinitions.SMTP_TO_RECIPIENTS, 
      xdoRequest.getRequestDest(destNum).getDestination() );
    
    // ==============================================================================================
    // set the email subject and body text based on the destination record subject and body text
    // ==============================================================================================
    req.addProperty(DeliveryPropertyDefinitions.SMTP_SUBJECT, 
      xdoRequest.getRequestDest(destNum).getSubjectMessage() );
    req.setDocument(xdoRequest.getRequestDest(destNum).getBodyMessage().getSubString(1,2000) , "UTF-8");
    
    // ==============================================================================================
    // create Attachment
    // ==============================================================================================
    Attachment attachDocs = new Attachment();
    
    // ==============================================================================================
    // loop through each of the XDO Request documents
    // ==============================================================================================
    for(int a = 0; a < xdoRequest.getRequestDocCount(); a++) {
      // ==============================================================================================
      // define the document file name for the email attachment
      // ==============================================================================================
      String tmpDocFileName = 
        new String(xdoRequest.getRequestDoc(a).getDocumentFileName() + "." +
          xdoRequest.getRequestDoc(a).getDocumentFileType() );

      // ==============================================================================================
      // if document record indicates to add attachments
      // ==============================================================================================
      if (xdoRequest.getRequestDest(destNum).getAttachDocumentsFlag().equals("Y") ) {
        // ==============================================================================================
        // add the document data as attachments to the email
        // ==============================================================================================
        attachDocs.addAttachment
        ( tmpDocFileName, // file name appears in the email
          xdoRequest.getRequestDoc(a).getDocumentContentType(), // content type
          (InputStream)xdoRequest.getRequestDoc(a).getCachedDocumentDataIS(true) ); // InputStream of content
        
        // ==============================================================================================
        // update the status of the XDO Request document to ATTACHED
        // ==============================================================================================
        XdoRequestManager.setRequestDocStatus
          (appsContext,xdoRequest.getRequestDoc(a),"ATTACHED",true);
      }      
    }
            
    // ==============================================================================================
    // add the attachments to the request
    // ==============================================================================================
    req.addProperty(DeliveryPropertyDefinitions.SMTP_ATTACHMENT, attachDocs);
    
    // ==============================================================================================
    // submit the request with the XML Publisher Delivery Manager
    // ==============================================================================================
    req.submit();
    req.close();
    
    // ==============================================================================================
    // update the status on the XDO Request Destination to SENT
    // ==============================================================================================
    XdoRequestManager.setRequestDestStatus
      (appsContext,xdoRequest.getRequestDest(destNum),"SENT",true);
  }
  
  // ==============================================================================================
  // function that writes the document to the tmp directory, and attachs the files before delivery
  // ==============================================================================================
  private static void addDocumentFiles
    (DeliveryRequest req, XdoRequest xdoRequest, int docNum)
    throws Exception
  {
    debugLine("private static void addDocumentFiles(DeliveryRequest req, XdoRequest xdoRequest, int docNum)");
    debugLine("  XDO Request ID   : " + xdoRequest.getXdoRequestId().intValue() );
    debugLine("  Document Index   : " + docNum );
    debugLine("  " );
    
    // ==============================================================================================
    // set the content mime type of the document 
    // ==============================================================================================
    req.addProperty(DeliveryPropertyDefinitions.IPP_DOCUMENT_FORMAT,
      xdoRequest.getRequestDoc(docNum).getDocumentContentType() );
    
    // ==============================================================================================
    // define the temporary file name and location
    // ==============================================================================================
    String tmpDocFileName = xdoRequest.getRequestDoc(docNum).getDocumentFileName() + "." +
        xdoRequest.getRequestDoc(docNum).getDocumentFileType();
    
    debugLine("Tmp Dir= " + System.getProperty("java.io.tmpdir") );
    debugLine("Doc Name= " + tmpDocFileName );
    
    // ==============================================================================================
    // define a File with the temporary file name and location
    // ==============================================================================================
    File tmpFile = 
      File.createTempFile("xx-xdo-" + xdoRequest.getRequestDoc(docNum).getDocumentFileName(),
        "." + xdoRequest.getRequestDoc(docNum).getDocumentFileType() );
    tmpFile.deleteOnExit();
    
    // ==============================================================================================
    // define temporary file streams for document
    // ==============================================================================================
    ByteArrayInputStream docInputStream = xdoRequest.getRequestDoc(docNum).getCachedDocumentDataIS(true);
    FileOutputStream tmpDoc = new FileOutputStream(tmpFile);
    
    // ==============================================================================================
    // read from the document stream and write to the temporary file
    // ==============================================================================================
    int docByte;
    int docLength = 0;
    while ((docByte = docInputStream.read()) != -1) {
      tmpDoc.write(docByte);
      docLength++;
    }
    
    debugLine("Doc Size: " + docLength );
    debugLine("Attach Tmp Doc: " + tmpFile.getAbsolutePath() );

    // ==============================================================================================
    // set the document to the temporary file
    // ==============================================================================================
    req.setDocument( tmpFile.getAbsolutePath() );
    
    debugLine("  Document added successfully.");
    debugLine("");
  }
  
  // ==============================================================================================
  // function that processes the XDO request for an printer destination through the XML Publisher 
  //   delivery manager APIs
  // ==============================================================================================
  private static void processPrinterDestination
    (AppsContext appsContext, XdoRequest xdoRequest, int destNum) 
    throws Exception
  {
    debugLine("private static void processPrinterDestination(AppsContext appsContext, XdoRequest xdoRequest, int destNum)");
    debugLine("  XDO Request ID     : " + xdoRequest.getXdoRequestId().intValue() );
    debugLine("  Destination Index  : " + destNum );
    debugLine("  " );
    
    // ==============================================================================================
    // get the setup values from the custom XDO Profiles for Printing
    // ==============================================================================================
    String ippHost = getRequiredProfile(appsContext,"XX_XDO_IPP_HOST");
    String ippPort = getRequiredProfile(appsContext,"XX_XDO_IPP_PORT");
      
    debugLine("-XDO Printer Profiles-");
    debugLine("  Host: " + ippHost + "; ");
    debugLine("  Port: " + ippPort + "; ");
    debugLine("  " );
    
    // ==============================================================================================
    // update the status on the XDO Request Destination to SENDING
    // ==============================================================================================
    XdoRequestManager.setRequestDestStatus
      (appsContext,xdoRequest.getRequestDest(destNum),"SENDING",true);
      
    // ==============================================================================================
    // create an instance of the XML Publisher delivery manager and define all the Printer setups
    // ==============================================================================================
    DeliveryManager dm = new DeliveryManager();
    DeliveryRequest req = dm.createRequest(DeliveryManager.TYPE_IPP_PRINTER);
    req.addProperty(DeliveryPropertyDefinitions.IPP_HOST, ippHost );
    req.addProperty(DeliveryPropertyDefinitions.IPP_PORT, ippPort );
    
    // ==============================================================================================
    // set the printer name based on the destination in the XDO Request destination record
    // ==============================================================================================
    req.addProperty(DeliveryPropertyDefinitions.IPP_PRINTER_NAME,
      xdoRequest.getRequestDest(destNum).getDestination() );
    
    debugLine("Destination= " + 
      xdoRequest.getRequestDest(destNum).getDestination() );
    
    // ==============================================================================================
    // add the document[s]
    // ==============================================================================================
    for(int a = 0; a < xdoRequest.getRequestDocCount(); a++) {
      addDocumentFiles(req, xdoRequest, a);
    }
    
    // ==============================================================================================
    // submit the request with the XML Publisher Delivery Manager
    // ==============================================================================================
    req.submit();
    req.close();
    
    // ==============================================================================================
    // update the status on the XDO Request Destination to SENT
    // ==============================================================================================
    XdoRequestManager.setRequestDestStatus
      (appsContext,xdoRequest.getRequestDest(destNum),"SENT",true);
  }

  // ==============================================================================================
  // function that processes the XDO request for an fax destination through the XML Publisher 
  //   delivery manager APIs
  // ==============================================================================================
  private static void processFaxDestination
    (AppsContext appsContext, XdoRequest xdoRequest, int destNum) 
    throws Exception
  {
    debugLine("private static void processFaxDestination(AppsContext appsContext, XdoRequest xdoRequest, int destNum)");
    debugLine("  XDO Request ID     : " + xdoRequest.getXdoRequestId().intValue() );
    debugLine("  Destination Index  : " + destNum );
    debugLine("  " );
    
    // ==============================================================================================
    // get the setup values from the custom XDO Profiles for Fax
    // ==============================================================================================
    String faxHost = getRequiredProfile(appsContext,"XX_XDO_FAX_HOST");    
    String faxPort = getRequiredProfile(appsContext,"XX_XDO_FAX_PORT");    
    String faxPrinter = getRequiredProfile(appsContext,"XX_XDO_FAX_PRINTER");
    
    debugLine("-XDO Fax Profiles-");
    debugLine("  Host: " + faxHost + "; ");
    debugLine("  Port: " + faxPort + "; ");
    debugLine("  Printer: " + faxPrinter + "; ");
    debugLine("  " );
    
    // ==============================================================================================
    // update the status on the XDO Request Destination to SENDING
    // ==============================================================================================
    XdoRequestManager.setRequestDestStatus
      (appsContext,xdoRequest.getRequestDest(destNum),"SENDING",true);
      
    // ==============================================================================================
    // create an instance of the XML Publisher delivery manager and define all the Fax setups
    // ==============================================================================================
    DeliveryManager dm = new DeliveryManager();
    DeliveryRequest req = dm.createRequest(DeliveryManager.TYPE_IPP_FAX);
    req.addProperty(DeliveryPropertyDefinitions.IPP_HOST, faxHost );
    req.addProperty(DeliveryPropertyDefinitions.IPP_PORT, faxPort );
    req.addProperty(DeliveryPropertyDefinitions.IPP_PRINTER_NAME, faxPrinter );
    
    // ==============================================================================================
    // set the fax number based on the destination in the XDO Request destination record
    // ==============================================================================================
    req.addProperty(DeliveryPropertyDefinitions.IPP_PHONE_NUMBER,
      xdoRequest.getRequestDest(destNum).getDestination() );
    
    debugLine("Destination= " + 
      xdoRequest.getRequestDest(destNum).getDestination() );
    
    // ==============================================================================================
    // add the document[s]        
    // ==============================================================================================
    for(int a = 0; a < xdoRequest.getRequestDocCount(); a++) {
      addDocumentFiles(req, xdoRequest, a);
    }
    
    // ==============================================================================================
    // submit the request with the XML Publisher Delivery Manager
    // ==============================================================================================
    req.submit();
    req.close();
    
    // ==============================================================================================
    // update the status on the XDO Request Destination to SENT
    // ==============================================================================================
    XdoRequestManager.setRequestDestStatus
      (appsContext,xdoRequest.getRequestDest(destNum),"SENT",true);
  }
  
  // ==============================================================================================
  // function that processes the XDO request
  // ==============================================================================================
  public static void processRequest(AppsContext appsContext, XdoRequest xdoRequest) 
    throws Exception
  {
    debugLine("public static void processRequest(AppsContext appsContext, XdoRequest xdoRequest)");
    debugLine("  XDO Request ID     : " + xdoRequest.getXdoRequestId().intValue() );
    debugLine("  " );
    
    // ==============================================================================================
    // set the status on the XDO Request to PROCESSING
    // ==============================================================================================
    XdoRequestManager.setRequestStatus(appsContext,xdoRequest,"PROCESSING",true);
    
    String isoLanguage = "";
    String isoTerritory = "";
    
    // ==============================================================================================
    // loop through each of the XDO request documents, and process the template
    // ==============================================================================================
    for(int i = 0; i < xdoRequest.getRequestDocCount(); i++) {
      Template xdoTemplate = xdoRequest.getRequestDoc(i).getXdoTemplate();
      
      debugLine("  Template App: " + xdoTemplate.getAppName() );
      debugLine("  Template Code: " + xdoTemplate.getCode() );
      debugLine("  Template Name: " + xdoTemplate.getName() );
      debugLine("  Default Language: " + xdoTemplate.getDefaultLanguage() );
      debugLine("  Default Territory: " + xdoTemplate.getDefaultTerritory() );
      debugLine("  " );

      OraclePreparedStatement sqlStmt = null;
      OracleResultSet resultSet = null;

      try {
        Connection connection = appsContext.getJDBCConnection();
        // ==============================================================================================
        // query to retrieve the language and territory
        // ==============================================================================================
        StringBuffer sqlSB = new StringBuffer();
        sqlSB.append("SELECT LOWER(iso_language) iso_language, ");
        sqlSB.append("       iso_territory ");
        sqlSB.append("  FROM fnd_languages ");
        sqlSB.append(" WHERE language_code = '" + xdoRequest.getRequestDoc(i).getLanguageCode() + "'" );

        sqlStmt = (OraclePreparedStatement)connection.prepareStatement(sqlSB.toString());
        resultSet = (OracleResultSet)sqlStmt.executeQuery();
      
        // ==============================================================================================
        // loop through each row of the result set  - should only be one anyhow
        // ==============================================================================================
        while(resultSet.next()) {
          isoLanguage = resultSet.getString("ISO_LANGUAGE"); 
          isoTerritory = resultSet.getString("ISO_TERRITORY"); 
        }
      
        resultSet.close();
        sqlStmt.close();
        resultSet = null;
        sqlStmt = null;
      }
      catch(SQLException sqlException)
      { try { resultSet.close(); }
        catch(Exception e) { }
        try { sqlStmt.close(); }
        catch(Exception e) { }
        finally { }
        throw sqlException;
      }
	  finally {
	  try {
	   if (sqlStmt!=null)
		 sqlStmt.close();
	   if (resultSet!=null)
		 resultSet.close();
	   }
		catch(Exception e) {}
	}
      debugLine(" Language Values: " );
      debugLine("  ISO Language: " + isoLanguage );
      debugLine("  ISO Territory: " + isoTerritory );
      debugLine("  " );

      if (isoLanguage == null) {
        isoLanguage = xdoTemplate.getDefaultLanguage();
      }

      if (isoTerritory == null) {
        isoTerritory = xdoTemplate.getDefaultTerritory();
      }
    
      // ==============================================================================================
      // create temporary BLOB storage space for new document
      // ==============================================================================================
      BLOB tempBLOB = BLOB.createTemporary
        (appsContext.getJDBCConnection(), true, BLOB.DURATION_SESSION);
      
      // ==============================================================================================
      // process the XML Publisher template using the given XML data
      // ==============================================================================================
      debugLine("  Processing the XML template [TemplateHelper.processTemplate]... " );
      TemplateHelper.processTemplate
      ( appsContext, 
        xdoTemplate.getAppName(),
        xdoTemplate.getCode(),
        isoLanguage,
        isoTerritory,
        xdoRequest.getRequestDoc(i).getCachedXmlReader(),
        TemplateHelper.OUTPUT_TYPE_PDF,   //xdoRequest.getRequestDoc(i).getTemplateOutputType(),
        null,    //xdoRequest.getRequestDoc(i).getTemplateProperties(),
        tempBLOB.getBinaryOutputStream() );
        
      debugLine(" Document has been successfully generated. ");
      debugLine("   BLOB length: " + tempBLOB.length() );    
      
      // ==============================================================================================
      // write BLOB document data to xdo request table for the given xdo document
      // ==============================================================================================
      if (xdoRequest.getRequestDoc(i).getStoreDocumentFlag().equals("Y")) {
        XdoRequestManager.updateDocumentData
          (appsContext,xdoRequest.getRequestDoc(i),tempBLOB,true );
      }
              
      // ==============================================================================================
      // copy the BLOB document data to a local inputstream on the Xdo document class so 
      //   that it can be attached later during the document delivery without refetching
      //   or locking the record     
      // ==============================================================================================
      byte[] tempBytes = tempBLOB.getBytes(1L,(int)tempBLOB.length());        
      debugLine("ByteArray length: " + tempBytes.length );        
      ByteArrayInputStream docInputStream = new ByteArrayInputStream(tempBytes);
      xdoRequest.getRequestDoc(i).setCachedDocumentDataIS( docInputStream );
      
      // ==============================================================================================
      // free temporary BLOB storage space
      // ==============================================================================================
      tempBLOB.freeTemporary();
    }
    
    String deliveryMethod;
    
    for(int j = 0; j < xdoRequest.getRequestDestCount(); j++) {
      deliveryMethod = xdoRequest.getRequestDest(j).getDeliveryMethod();
      
      // ==============================================================================================
      // process the email delivery destinations
      // ==============================================================================================
      if (deliveryMethod.equalsIgnoreCase("EMAIL") ) {
        processEmailDestination(appsContext, xdoRequest, j);
      }
      // ==============================================================================================
      // process the printer delivery destinations
      // ==============================================================================================
      else if (deliveryMethod.equalsIgnoreCase("PRINTER") ) {
        processPrinterDestination(appsContext, xdoRequest, j);
      }
      // ==============================================================================================
      // process the fax delivery destinations
      // ==============================================================================================
      else if (deliveryMethod.equalsIgnoreCase("FAX") ) {
        processFaxDestination(appsContext, xdoRequest, j);
      }
    }
    
    // ==============================================================================================
    // set the status of all the XDO Request records (request, docs, and dests) to COMPLETED
    // ==============================================================================================
    XdoRequestManager.setRequestStatusALL(appsContext,xdoRequest,"COMPLETED",true);
  }
  
  // ==============================================================================================
  // function that processes the XDO request (based on the given request group id and request id)
  // ==============================================================================================
  public static void processRequests(AppsContext appsContext, int xdoRequestGroupId, int xdoRequestId) 
    throws Exception
  {
    debugLine("public static void processRequests(AppsContext appsContext, int xdoRequestGroupId, int xdoRequestId)");
    debugLine("  XDO Request Group ID : " + xdoRequestGroupId );
    debugLine("  XDO Request ID       : " + xdoRequestId );
    debugLine("  " );
    
    // ==============================================================================================
    // get the XDO Request[s] from the given parameters
    // ==============================================================================================
    XdoRequest[] requests = 
      XdoRequestManager.getRequests(appsContext,xdoRequestGroupId,xdoRequestId);
    
    // ==============================================================================================
    // loop through the XDO Requests and process each one
    // ==============================================================================================
    if (requests.length > 0) {
      for(int i = 0; i < requests.length; i++) {
        XdoRequestManager.processRequest(appsContext,requests[i]);
      }
    }
  }
  
  // ==============================================================================================
  // function that processes the XDO request (based on the given request id)
  // ==============================================================================================
  public static void processRequest(AppsContext appsContext, int xdoRequestId) 
    throws Exception
  {
    debugLine("public static void processRequest(AppsContext appsContext, int xdoRequestId)");
    debugLine("  XDO Request ID       : " + xdoRequestId );
    debugLine("  " );
    
    // ==============================================================================================
    // process the XDO Request
    // ==============================================================================================
    processRequests(appsContext, -1, xdoRequestId);
  }
  
}