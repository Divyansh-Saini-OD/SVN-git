package com.od.external.view.conn;

import com.od.external.view.ebs.EBizUtil;

import java.sql.Connection;
import java.sql.SQLException;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;

import oracle.adf.share.logging.ADFLogger;

public class ConnectionProvider {
    private static ADFLogger _logger = ADFLogger.createADFLogger(ConnectionProvider.class);
    private static DataSource myDS = null;
    static {
    try {
    Context ctx = new InitialContext();
    myDS = (DataSource)ctx.lookup("jdbc/GSIODTRDS");
        _logger.severe("Datasource>>>>>>ConnectionProvider"+myDS);
        _logger.info("Datasource>>>>>>ConnectionProvider"+myDS);
    // your datasource jndi name as defined during configuration
    if (ctx != null)
    ctx.close();
    } catch (NamingException ne) {
    //ne.printStackTrace();//ideally you should log it
    throw new RuntimeException(ne);
    // means jndi setup is not correct or doesn't exist
    }
    }
    private ConnectionProvider() {
    }
    public static Connection getConnection()
    throws SQLException {
    if (myDS == null)
    throw new IllegalStateException("AppsDatasource is not  properly initialized or available");
    return myDS.getConnection();
    }
}
