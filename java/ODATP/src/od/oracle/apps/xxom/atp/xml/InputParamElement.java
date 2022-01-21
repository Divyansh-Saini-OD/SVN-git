/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             InputParamElement.java                                            |
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
 * Represents the input element in the XML Document
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 **/
public class InputParamElement {

    /**
     * Header Information
     * 
     **/
    public static final String RCS_ID = 
        "$Header: InputParamElement.java  06/29/2007 Satis-Gnanmani$";

    String map;
    String parameter;
    String index;
    String type;
    String javatype;
    String paramValue;
    String required;


    /**
     * Construtor to initialized the Input Parameter Element with attributes
     * Map, parameter, index, type, javatype, paramValue and Required.
     * 
     * @param map Object type record variable name
     * @param parameter parameter of the to call pl/sql procedure
     * @param index index of the parameter
     * @param type Type of Pl/Sql parameter
     * @param javatype Java Map for the Pl/Sql type
     * @param paramValue Substitue Value for the parameter
     * @param required Flag determining if its a required parameter
     * 
     **/
    public InputParamElement(String map, String parameter, String index, 
                             String type, String javatype, String paramValue, 
                             String required) {
        this.map = map;
        this.parameter = parameter;
        this.index = index;
        this.type = type;
        this.javatype = javatype;
        this.paramValue = paramValue;
        this.required = required;
    }

    /**
     * @param map Member field in the ATPRecordType class
     **/
    public void setMap(String map) {
        this.map = map;
    }

    /**
     * @return map Member field in the ATPRecordType class
     **/
    public String getMap() {
        return map;
    }

    /**
     * @param parameter Parameter of the Pl/Sql Procedure
     **/
    public void setParameter(String parameter) {
        this.parameter = parameter;
    }

    /**
     * @return parameter Parameter of the Pl/Sql Procedure
     **/
    public String getParameter() {
        return parameter;
    }

    /**
     * @param index Index of the parameter in the Pl/Sql Procedure
     **/
    public void setIndex(String index) {
        this.index = index;
    }

    /**
     * @return index Index of the parameter in the Pl/Sql Procedure
     **/
    public String getIndex() {
        return index;
    }

    /**
     * @param type Type of the parameter in the Pl/Sql Procedure
     **/
    public void setType(String type) {
        this.type = type;
    }

    /**
     * @return type Type of the parameter in the Pl/Sql Procedure
     **/
    public String getType() {
        return type;
    }

    /**
     * @param javatype JavaType of the member field
     **/
    public void setJavatype(String javatype) {
        this.javatype = javatype;
    }

    /**
     * @return javatype Java Type of the member field
     **/
    public String getJavatype() {
        return javatype;
    }

    /**
     * @param paramValue Substitute value for the field
     **/
    public void setParamValue(String paramValue) {
        this.paramValue = paramValue;
    }

    /**
     * @return paramValue Substitute value for the fiels
     **/
    public String getParamValue() {
        return paramValue;
    }

    /**
     * @param required Parameter required flag
     **/
    public void setRequired(String required) {
        this.required = required;
    }

    /**
     * @return required Parameter required flag
     **/
    public String getRequired() {
        return required;
    }
}// End InputParamElement Class
