/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             OutputParamElement.java                                            |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |                                                                           |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/29/2007 Sathish Gnanamani   Initial Creation                        |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.xml;


/**
 * Represents the Output Element of the XML document. 
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 **/
public class OutputParamElement {

    /**
     * Header Information
     * 
     **/
    public static final String RCS_ID = 
        "$Header: OutputParamElement.java  06/29/2007 Satis-Gnanmani$";

    String map;
    String parameter;
    String index;
    String type;
    String javatype;


    /**
     * Constructor to invoke the output element object with the attributes
     * Map, Parameter, Index, Type, JavaType, Required.
     * 
     * @param map Object Type variable to map the parameter with
     * @param parameter Parameter of the Pl/Sql procedure to call
     * @param index Index of the Parameter
     * @param type Type of the Pl/Sql parameter
     * @param javatype Java type to map with the Pl/Sql type
     * 
     **/
    public OutputParamElement(String map, String parameter, String index, 
                              String type, String javatype) {
        this.map = map;
        this.parameter = parameter;
        this.index = index;
        this.type = type;
        this.javatype = javatype;
    }

    /**
     * @param map Mapping Java member field of class ATPRecordType
     **/
    public void setMap(String map) {
        this.map = map;
    }

    /**
     * @return map Mapping Java member field of class ATPRecordType
     **/
    public String getMap() {
        return map;
    }

    /**
     * @param parameter Parameter of the PL/SQL procedure
     **/
    public void setParameter(String parameter) {
        this.parameter = parameter;
    }

    /**
     * @return parameter Parameter of the PL/SQL procedure
     **/
    public String getParameter() {
        return parameter;
    }

    /**
     * @param index Index of the Pl/sql Procedure Parameter
     **/
    public void setIndex(String index) {
        this.index = index;
    }

    /**
     * @return index Index of the Pl/sql Procedure Parameter
     **/
    public String getIndex() {
        return index;
    }

    /**
     * @param type Type of the Pl/Sql procedure parameter
     **/
    public void setType(String type) {
        this.type = type;
    }

    /**
     * @return type Type of the Pl/Sql procedure parameter
     **/
    public String getType() {
        return type;
    }

    /**
     * @param javatype Java type of the member field
     **/
    public void setJavatype(String javatype) {
        this.javatype = javatype;
    }

    /**
     * @return javaType Java type of the member field
     **/
    public String getJavatype() {
        return javatype;
    }
}
