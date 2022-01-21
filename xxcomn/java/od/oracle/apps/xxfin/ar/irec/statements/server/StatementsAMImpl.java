package od.oracle.apps.xxfin.ar.irec.statements.server;

/*===========================================================================+
 |      Copyright (c) 2001 Oracle Corporation, Redwood Shores, CA, USA       |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 | 1.1  17-FEB-2017   MBolli  Thread Leak 12.2.5 Upgrade - close all statements, resultsets |
 +===========================================================================*/
 
 
import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;

import java.sql.Blob;
import java.sql.ResultSet;
import java.sql.Types;
import java.sql.CallableStatement;

import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import od.oracle.apps.xxfin.ar.irec.statements.webui.StatementFile;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewRowImpl;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleTypes;

import oracle.sql.BLOB;


public class StatementsAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public StatementsAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxfin.ar.irec.statements.server", "StatementsAMLocal");
  }

  /**
   * 
   * Container's getter for StatementsVO1
   */
  public StatementsVOImpl getStatementsVO1()
  {
    return (StatementsVOImpl)findViewObject("StatementsVO1");
  }

  public String getSelectedFileIds()
  {
      String sSelectedFileIds = "";
      
      StatementsVOImpl statementsvoimpl = getStatementsVO1();
      statementsvoimpl.reset();

      if(statementsvoimpl.hasNext())
      {
          while(statementsvoimpl.hasNext()) 
          {
              OAViewRowImpl statementsvorowimpl = (OAViewRowImpl)statementsvoimpl.next();

              if("Y".equals(String.valueOf(statementsvorowimpl.getAttribute("SelectedFlag"))))
              {
//                  statementsvorowimpl.remove();
                  if (sSelectedFileIds.length()>0) sSelectedFileIds += ",";
                  sSelectedFileIds += String.valueOf(statementsvorowimpl.getAttribute("file_id"));
              }
          }
//          getTransaction().commit();
      }
      return sSelectedFileIds;
  }

  public StatementFile GetStatementFile(String sFileId)
  {
    OADBTransaction txn = getOADBTransaction();
    CallableStatement s = null;
    ResultSet rs = null;
    byte[] baFile = null;
    Blob aBlob = null;
    String sFileName = null;

    try
    {
      s = txn.createCallableStatement("BEGIN XX_AR_EBL_TRANSMISSION_PKG.GET_FILE_DATA_CURSOR(?,?); END;",1);

      s.setInt(1,Integer.parseInt(sFileId));
      s.registerOutParameter(2, OracleTypes.CURSOR); 
      s.execute();

      rs = (ResultSet) s.getObject(2);
      rs.next();

      try
      {
        // Get as a BLOB
        aBlob = rs.getBlob(2);
        baFile = aBlob.getBytes(1, (int) aBlob.length());
        sFileName = rs.getString(1);
      }
      catch(Exception ex)
      {
        // The driver could not handle this as a BLOB...
        // Fallback to default (and slower) byte[] handling
        baFile = rs.getBytes(2);
        sFileName = rs.getString(1);
      }
      rs.close();
      if (s != null) s.close();
    }
    catch(Exception ex)
    {
      try {
		  if (rs != null) rs.close();
		  if (s != null) s.close();}
      catch(Exception ex2) {};
    }
    return (new StatementFile(sFileName, baFile));
  }

  public StatementFile GetZippedFiles(String sFileIdList)
  {
      String[] saFileId = sFileIdList.split(",");

      ByteArrayOutputStream dest = new ByteArrayOutputStream();
      ZipOutputStream out = new ZipOutputStream(new BufferedOutputStream(dest));

      for (int i=0; i<saFileId.length; i++)
      {
          StatementFile sf = GetStatementFile(saFileId[i]);

          byte[] baFile = sf.getFileData();
          if (baFile != null) {
              ZipEntry entry = new ZipEntry(sf.getFileName());
              try {
                  out.putNextEntry(entry);
                  out.write(baFile);
                  out.closeEntry();
              }
              catch (Exception ex) {
                  System.out.println("Error adding zip entry-- file_id="+ saFileId[i] +'\n'+ex.toString());
                  ex.printStackTrace();
              }
          }
      }
      try {out.close();} catch (Exception ex) {
         System.out.println("Error closing zip "+'\n'+ex.toString());
         ex.printStackTrace();
      }
      return (new StatementFile("eBills.zip", dest.toByteArray()));
  }

  public void clearSelections()
  {
      StatementsVOImpl statementsvoimpl = getStatementsVO1();
      statementsvoimpl.reset();

      if(statementsvoimpl.hasNext())
      {
          while(statementsvoimpl.hasNext())
          {
              OAViewRowImpl statementsvorowimpl = (OAViewRowImpl)statementsvoimpl.next();

              if("Y".equals(String.valueOf(statementsvorowimpl.getAttribute("SelectedFlag"))))
              {
                  statementsvorowimpl.setAttribute("SelectedFlag","N");
              }
          }
//          getTransaction().commit();
      }
  }

  public Boolean SendOneEmailNoCompression(String sSelectedFileIds, String sEmailAddresses, String sRenameZipExtension) 
  {
      Boolean bSuccess = Boolean.TRUE;
      OracleCallableStatement sqlStmt = null;
      try
      {
         OADBTransaction txn = getOADBTransaction();
         sqlStmt = (OracleCallableStatement)txn.createCallableStatement("CALL XX_AR_EBL_TRANSMISSION_PKG.SEND_ONE_EMAIL(?,?,?,?)", 1);
         sqlStmt.setString(1,sSelectedFileIds);
         sqlStmt.setString(2,sEmailAddresses);
         sqlStmt.setString(3,sRenameZipExtension);
         sqlStmt.registerOutParameter(4, Types.VARCHAR);
         sqlStmt.execute();
         if (sqlStmt != null) {
            String sSuccess = sqlStmt.getString(4);
            if (sSuccess!=null && !sSuccess.equals("")) bSuccess = Boolean.FALSE;
            sqlStmt.close();
         }
      }
      catch (Exception ex) 
      {
         bSuccess = Boolean.FALSE;
         try {if (sqlStmt != null) sqlStmt.close();}
         catch(Exception ex2) {} // handle in PL/SQL
      }

      return bSuccess;
  }

  public Boolean SendOneEmailZipped(String sSelectedFileIds, String sEmailAddresses, String sRenameZipExtension) 
  {
      Boolean bSuccess = Boolean.TRUE;

      StatementFile sf = GetZippedFiles(sSelectedFileIds);
      int nFileId = Integer.parseInt("-" + (new java.text.SimpleDateFormat("mmss")).format(new java.util.Date()).toString());
      PutFileInTmpTbl(nFileId, sf);

      OracleCallableStatement sqlStmt = null;
      try
      {
         OADBTransaction txn = getOADBTransaction();
         sqlStmt = (OracleCallableStatement)txn.createCallableStatement("CALL XX_AR_EBL_TRANSMISSION_PKG.SEND_ONE_EMAIL(?,?,?,?)", 1);
         sqlStmt.setInt(1,nFileId);
         sqlStmt.setString(2,sEmailAddresses);
         sqlStmt.setString(3,sRenameZipExtension);
         sqlStmt.registerOutParameter(4, Types.VARCHAR);
         sqlStmt.execute();
         txn.commit(); // will delete tmp table entry
         if (sqlStmt != null) {
            String sSuccess = sqlStmt.getString(4);
            if (sSuccess!=null && !sSuccess.equals("")) bSuccess = Boolean.FALSE;
            sqlStmt.close();
         }
      }
      catch (Exception ex) 
      {
         bSuccess = Boolean.FALSE;
         try {if (sqlStmt != null) sqlStmt.close();}
         catch(Exception ex2) {} // handle in PL/SQL
      }
      return bSuccess;
  }

  public void PutFileInTmpTbl(int fileId, StatementFile sf) 
  {
      OADBTransaction txn = getOADBTransaction();
      OraclePreparedStatement pstmt = null;
      byte[] ba = sf.getFileData();

      try {
          BLOB blob = BLOB.createTemporary(txn.getJdbcConnection(),true,BLOB.DURATION_SESSION);

          java.io.OutputStream os = blob.getBinaryOutputStream();
          os.write(ba);
          os.flush();
          os.close();
          
          pstmt = (OraclePreparedStatement)txn.createPreparedStatement("insert into XX_AR_EBL_FILE_GT (file_id, file_name, file_data) values (?, ?, ?)",0);
          pstmt.setInt(1, fileId);
          pstmt.setString(2,sf.getFileName());
          pstmt.setBlob(3, blob);
          pstmt.execute();
      }
      catch (Exception ex) {
          System.out.println("Error inserting tmp tbl file "+'\n'+ex.toString());
          ex.printStackTrace();
          throw new OAException("XXFIN", "AR_EBL_UNABLE_TO_SEND_EMAIL");
      }
      finally {
         try {
          pstmt.close();
         }
         catch (Exception ex) {}
      }
   }
}