/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ConnectionPoolMgr.java                                        |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Class to enable connection pooling for all the database                |
 |    The class uses the Oracle Call Interface for the same                  |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is called from AtpProcessControl.java                  |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    05/29/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.pool;

import java.io.FileInputStream;
import java.io.IOException;

import java.sql.SQLException;

import java.util.Properties;

import od.oracle.apps.xxom.atp.LogATP;

import oracle.jdbc.oci.OracleOCIConnection;
import oracle.jdbc.pool.OracleOCIConnectionPool;

/**
 * Class implements the Oracle OCI connection pooling.
 * Provides a singleton implementation.
 * 
 **/
public class ConnectionPoolMgr {

    /**
     * Header Information
     * 
     *
     **/
    public static final String RCS_ID = 
        "$Header: ConnectionPoolMgr.java  05/29/2007 Satis-Gnanmani$";

    /**
     * Class Instance.
     * 
     **/
    public static ConnectionPoolMgr cpoolInstance = null;

    /** 
     *  Singleton Implementation of the OCI connection Pool.
     *  This constructor is protected to enforce creation of
     *  only one instance of this class.
     *  
     **/
    protected ConnectionPoolMgr() {
    }

    /**
     * Get the instance of the Connection Pool Manager
     * 
     * @return cpoolInstance Instance of the Connection Pool Manager
     * 
     **/
    public static synchronized ConnectionPoolMgr getInstance() {
        if (cpoolInstance == null)
            cpoolInstance = new ConnectionPoolMgr();
        try {
            cpoolInstance.setConnectionParams();
            //System.out.println("UsrName : "+username+" Pwd : " + pwd+" URL : " + url +" Instance : "+cpoolInstance.cpool);
            cpoolInstance.cpool = new OracleOCIConnectionPool(username,pwd,url,null);
            cpoolInstance.cpool.setConnectionProperties(cpoolInstance.properties);
        } catch (SQLException e) {
            LogATP.printException(cpoolInstance.getClass().toString(),e.getCause(),e.getMessage(),e.getStackTrace());
            LogATP.printError("SQLException in Getting Connection Pool Manager Instance ", 71);
        }
        return cpoolInstance;
    }

    private static String port;
    private static String url;
    private static String username;
    private static String pwd;
    private static String url1;
    private Properties properties;
    private OracleOCIConnection conn;
    private OracleOCIConnectionPool cpool;

    /**
     * Get a Connection to the database.
     * 
     * @return conn - Oracle OCI Connection
     * @throws SQLException
     * 
     **/
    public OracleOCIConnection getConnection() throws SQLException {
        try {
            conn = (OracleOCIConnection)cpool.getConnection();
        } catch (SQLException e) {
            e.printStackTrace();
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(),e.getStackTrace());
            LogATP.printError("SQLException in Getting Connection ", 72);
        } catch (Exception e) {
            e.printStackTrace();
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(),e.getStackTrace());
            LogATP.printError("Exception in Getting Connection ", 73);
        }
        return conn;
    }

    /**
     * Release the connection to the database.
     * 
     * @throws SQLException
     * 
     **/
    public void releaseConnection() throws SQLException {
        try {
            conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(),e.getStackTrace());
            LogATP.printError("SQLException in Releasing Connection ", 74);
        }
    }

    /** 
     * Returns the Pool Size of the Connection Pool.
     * 
     * @throws SQLException
     * 
     **/
    public void getConnPoolSize() throws SQLException {
        try {
            cpool.getPoolSize();
        } catch (SQLException e) {
            e.printStackTrace();
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(),e.getStackTrace());
            LogATP.printError("SQLException in Getting Connection Size", 75);
        }
    }

    /** 
     * Returns the port used by the Connection Pool.
     * 
     * @return port
     * 
     **/
    public String getPort() {
        return port;
    }

    /** 
     * Returns the Obsolute url used by the connection pool.
     * 
     * @return url
     * 
     */
    public String getUrl() {
        return url;
    }

    /**
     * Get the Connection Properties
     * 
     * @return properties
     **/
    public Properties getProperties() {
        return properties;
    }

    /**
     * Hold - Pause the connection for futher use.
     * 
     * @param timeout
     * @throws InterruptedException
     **/
    public void holdConnectionPool(long timeout) throws SQLException, 
                                                        InterruptedException {
        try {
            cpool.wait(timeout);
        } /*catch (SQLException e) {
            System.out.println("Exceiption in Hold Connection Pool : " +
                               e.getMessage());
            e.printStackTrace();
        } */ catch (InterruptedException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(),e.getStackTrace());
            LogATP.printError("SQLException in Getting Connection Pool Manager Instance ", 71);
            e.printStackTrace();
        } catch (Exception e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(),e.getStackTrace());
            LogATP.printError("SQLException in Getting Connection Pool Manager Instance ", 71);
            e.printStackTrace();
        }

    }

    /**
     * Hold - Pause the connection for futher use.
     * 
     * @param timeout
     * @throws InterruptedException
     **/
    public void holdConnection(long timeout) throws InterruptedException {
        try {
            conn.wait(timeout);
        } catch (InterruptedException e) {
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(),e.getStackTrace());
            LogATP.printError("SQLException in Getting Connection Pool Manager Instance ", 71);
            e.printStackTrace();
        }
    }

    private void setConnectionParams() {
        port = ConnectionParameters.port;
        url = ConnectionParameters.url;
        username = ConnectionParameters.username;
        pwd = ConnectionParameters.pwd;
        url1 = System.getProperty("JDBC_URL");
    }

    private void setProperties() throws SQLException, IOException {
        try {
            properties = new Properties();
              try {
                 properties.load(new FileInputStream("C:\\jdev\\jdev\\mywork\\ODATP\\connection.properties"));
               } catch (IOException e) {
                   e.printStackTrace();
              }
/*
            properties.put(OracleOCIConnectionPool.CONNPOOL_MIN_LIMIT, 
                           Integer.toString(cpool.getMinLimit()));
            properties.put(OracleOCIConnectionPool.CONNPOOL_MAX_LIMIT, 
                           Integer.toString(cpool.getMaxLimit() * 2));
            if (cpool.getConnectionIncrement() > 0)
                properties.put(OracleOCIConnectionPool.CONNPOOL_INCREMENT, 
                               Integer.toString(cpool.getConnectionIncrement()));
            else
                properties.put(OracleOCIConnectionPool.CONNPOOL_INCREMENT, 
                               "1");*/
            cpool.setPoolConfig(properties);
        } catch (SQLException e) {
            e.printStackTrace();
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(),e.getStackTrace());
            LogATP.printError("SQLException in Getting Connection Pool Manager Instance ", 71);
        } catch (Exception e) {
            e.printStackTrace();
            LogATP.printException(this.getClass().toString(),e.getCause(),e.getMessage(),e.getStackTrace());
            LogATP.printError("SQLException in Getting Connection Pool Manager Instance ", 71);
        }
    }
}// End CoonectionPoolMgr Class
