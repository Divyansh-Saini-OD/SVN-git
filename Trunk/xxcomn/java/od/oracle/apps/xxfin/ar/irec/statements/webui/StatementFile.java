package od.oracle.apps.xxfin.ar.irec.statements.webui;

import java.io.Serializable;

public class StatementFile implements Serializable
{
  private String ms_fileName;
  private byte[] mba_fileData;

  public StatementFile()
  {
  }

  public StatementFile(String sFileName, byte[] baFileData)
  {
    setFileName(sFileName);
    setFileData(baFileData);
  }

  public String getFileName()
  {
    return ms_fileName;  
  }

  public String getMimeType()
  {
    String sFN = ms_fileName.toUpperCase();
    
    if (sFN.endsWith(".PDF")) return "application/pdf";
    else if (sFN.endsWith(".XLS")) return "application/vnd.ms-excel";
    else if (sFN.endsWith(".ZIP")) return "application/zip";

    else return "text/plain";
  }

  public byte[] getFileData() 
  {
    return mba_fileData;
  }

  public void setFileName(String sFileName)
  {
    ms_fileName = sFileName;
  }

  public void setFileData(byte[] baFileData) 
  {
    mba_fileData = baFileData;
  }
}