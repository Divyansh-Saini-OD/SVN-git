/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ConnectionParameters.java                                     |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Class to enable connection pooling for all the database                |
 |    The class uses the Oracle Call Interface for the same                  |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    05/29/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.pool;

/**
 * Provides Static properties for the Connection Pool class like the connection
 * parameters.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 */
public class ConnectionParameters {

    /**
     * Header Information
     * 
     */
    public static final String RCS_ID = 
        "$Header: ConnectionParameters.java  05/29/2007 Satis-Gnanmani$";

    /**
     * Database host URL
     * 
     */
    public static final String url = 
        "jdbc:oracle:oci:@choldbr18d.na.odcorp.net:1544:GSIDEV03";

    /**
     * UserName for the database connection
     * 
     */
    public static final String username = "apps";

    /**
     * Password for the database Connection
     * 
     */
    public static final String pwd = "appsp2p";

    /**
     * Port detail of the database
     * 
     */
    public static final String port = "1544";
}//End ConnectionParameters Class
