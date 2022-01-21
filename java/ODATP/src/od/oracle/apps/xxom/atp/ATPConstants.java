/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             AtpConstants.java                                             |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    Class to use all the constants that will be used in the                |
 |    atp java application.                                                  |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is called from AtpProcessControl.java,                 |
 |    and XMLDocumentHandler.java                                            |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    05/29/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp;

/**
 * Provides all the necessary Constants for the ATP application.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 **/
public class ATPConstants {

    public static final String RCS_ID = 
        "$Header: AtpConstants.java  05/29/2007 Satis-Gnanmani$";

    /**
     * Order Flow Code for Base Org ATP 
     **/
    public static final String BASE_VALUE = "BASE";

    /**
     * Order Flow Code for Alternate ATP
     **/
    public static final String ALT_VALUE = "ALT";

    /**
     * Order Flow code for XDock ATP 
     **/
    public static final String XDOCK_VALUE = "XDOCK";

    /**
     * Order Flow code for Substitute ATP
     **/
    public static final String SUB_VALUE = "SUB";

    /**
     * XML docuemnt element flow
     **/
    public static final String FLOW = "Flow";

    /**
     * XML docuemnt element name
     **/
    public static final String NAME = "Name";

    /**
     * XML docuemnt element code
     **/
    public static final String CODE = "Code";

    /**
     * XML docuemnt element executable
     **/
    public static final String EXECUTABLE = "Executable";

    /**
     * XML docuemnt element parametername
     **/
    public static final String PARAMETERNAME = "ParameterName";

    /**
     * XML docuemnt element input
     **/
    public static final String INPUT = "Input";

    /**
     * XML docuemnt element output
     **/
    public static final String OUTPUT = "Output";

    /**
     * XML docuemnt element map
     **/
    public static final String MAP = "Map";

    /**
     * XML docuemnt element parameter
     **/
    public static final String PARAMETER = "Parameter";

    /**
     * XML docuemnt element index
     **/
    public static final String INDEX = "Index";

    /**
     * XML docuemnt element type
     **/
    public static final String TYPE = "Type";

    /**
     * XML docuemnt element javatype
     **/
    public static final String JAVATYPE = "JavaType";

    /**
     * XML docuemnt element paramvalue
     **/
    public static final String PARAMVALUE = "ParamValue";

    /**
     * XML docuemnt element required
     **/
    public static final String REQUIRED = "Required";

    /**
     * The XML document file path and name.
     **/
    public static final String uri = 
        "C:\\jdev\\jdev\\mywork\\ODATP\\ODATPControl\\ODATP.xml";

    private static final int DATE = java.sql.Types.DATE;
    private static final int STRING = java.sql.Types.VARCHAR;
    private static final int BIGDECIMAL = java.sql.Types.NUMERIC;
    private static final int ARRAY = java.sql.Types.ARRAY;
    private static final int BOOLEAN = java.sql.Types.BOOLEAN;
    private static final int TIMESTAMP = java.sql.Types.TIMESTAMP;

    /**
     * This static method returns the value of the static variables corresponding to the
     * Input type string.
     * 
     * @param var
     * @return integer value of the Mapping Java type
     * @throws IllegalAccessException
     * @throws NoSuchFieldException
     * 
     **/
    public static int getIntValue(String var) throws IllegalAccessException, 
                                                     NoSuchFieldException {
        if ("BIGDECIMAL".equals(var))
            return BIGDECIMAL;
        else if ("STRING".equals(var))
            return STRING;
        else if ("DATE".equals(var))
            return DATE;
        else if ("ARRAY".equals(var))
            return ARRAY;
        else if ("BOOLEAN".equals(var))
            return BOOLEAN;
        else if ("TIMESTAMP".equals(var))
            return TIMESTAMP;
        else
            return 0;
    }
}// End ATPConstants Class
