/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             SAXParserElement.java                                  |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This Class handles name, code and value set of the ATP flow types      |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class object will be used in SAXParser.java                |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/06/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.xml;

import java.util.ArrayList;

/**
 * This class represents the Flow element of the XML docuemnt.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 */
public class SAXParserElement {

    /**
     * Header Information
     * 
     */
    public static final String RCS_ID = 
        "$Header: SAXParserElement.java  06/06/2007 Satis-Gnanmani$";

    private String Name;
    private String Code;
    private String Executable;
    private ArrayList<InputParamElement> inputlist;
    private ArrayList<OutputParamElement> outputlist;

    /**
     * 
     * @param name
     * @param code
     * @param executable
     * 
     */
    public SAXParserElement(String name, String code, String executable) {
        this.Name = name;
        this.Code = code;
        this.Executable = executable;
        inputlist = new ArrayList<InputParamElement>();
        outputlist = new ArrayList<OutputParamElement>();
    }

    /**
     * 
     */
    public SAXParserElement() {
        this.Name = null;
        this.Code = null;
        this.Executable = null;
        inputlist = new ArrayList<InputParamElement>();
        outputlist = new ArrayList<OutputParamElement>();
    }

    /**
     * 
     * @param name
     * 
     */
    public void setName(String name) {
        this.Name = name;
    }

    /**
     * 
     * @param code
     * 
     */
    public void setCode(String code) {
        this.Code = code;
    }

    /**
     * 
     * @param executable
     * 
     */
    public void setExecutable(String executable) {
        this.Executable = executable;
    }

    /**
     * 
     * @return
     * 
     */
    public String getName() {
        return Name;
    }

    /**
     * 
     * @return
     * 
     */
    public String getCode() {
        return Code;
    }

    /**
     * 
     * @return
     * 
     */
    public String getExecutable() {
        return Executable;
    }


    /**
     * 
     * @return
     * 
     */
    public ArrayList<InputParamElement> getInputlist() {
        return inputlist;
    }


    /**
     * 
     * @param inputlist
     * 
     */
    public void setInputlist(ArrayList<InputParamElement> inputlist) {
        this.inputlist = inputlist;
    }

    /**
     * 
     * @return
     * 
     */
    public ArrayList<OutputParamElement> getOutputlist() {
        return outputlist;
    }

    /**
     * 
     * @param outputlist
     * 
     */
    public void setOutputlist(ArrayList<OutputParamElement> outputlist) {
        this.outputlist = outputlist;
    }

    /**
     * @param inputparamelement
     */
    public void addInputElement(InputParamElement inputparamelement) {
        inputlist.add(inputparamelement);
    }

    /**
     * 
     * @param outputparamelement
     * 
     */
    public void addOutputElement(OutputParamElement outputparamelement) {
        outputlist.add(outputparamelement);
    }
}// End SAXParserElement Class
