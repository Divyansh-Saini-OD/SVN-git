/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             XMLDocumentHandler.java                                         |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This Class implements the methods to retrieve the  ATP flow types      |
 |    from the XML parser.
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class object will be used in AtpProcessControl.java                  |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/06/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.xml;

import java.io.IOException;

import java.util.ArrayList;

import java.util.Iterator;

import od.oracle.apps.xxom.atp.ATPConstants;

import org.xml.sax.SAXException;

/**
 * Class to implement the entire XML parsing and handling. This class implements
 * the document handling mechanisms required by other package to make subsequent 
 * database calls.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 * 
 */
public class XMLDocumentHandler {

    public static final String RCS_ID = 
        "$Header: XMLDocumentHandler.java  06/06/2007 Satis-Gnanmani$";

    /**
     * Provides a default constructor
     * 
     **/
    public XMLDocumentHandler() {
    }

    private SAXParser parser = null;
    private ArrayList inputlist = null;
    private ArrayList outputlist = null;
    private String code;


    /**
     * @param code
     * @throws SAXException
     * @throws IOException
     */
    public void setParser(String code) throws SAXException, IOException {
        this.code = code;
        this.parser = new SAXParser(ATPConstants.uri);
        parser.build();
        inputlist = parser.getInputElement(code);
        outputlist = parser.getOutputElement(code);
    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public String getExecutable() throws SAXException, IOException {
        return parser.getExecutable(this.code);
    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public int[] getInputIndex() throws SAXException, IOException {

        Iterator i = inputlist.iterator();
        int j = 0;
        int[] parameterindex = new int[inputlist.size()];
        while (i.hasNext()) {
            InputParamElement ipe = (InputParamElement)i.next();
            parameterindex[j] = new Integer(ipe.getIndex()).intValue();
            j++;
        }
        return parameterindex;
    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public String[] getInputJavaTypes() throws SAXException, IOException {
        String[] javatypes = new String[inputlist.size()];
        Iterator i = inputlist.iterator();
        int j = 0;
        while (i.hasNext()) {
            InputParamElement ipe = (InputParamElement)i.next();
            javatypes[j] = ipe.getJavatype();
            j++;
        }
        return javatypes;
    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public String[] getInputSqlTypes() throws SAXException, IOException {

        String[] sqltypes = new String[inputlist.size()];
        Iterator i = inputlist.iterator();
        int j = 0;
        while (i.hasNext()) {
            InputParamElement ipe = (InputParamElement)i.next();
            sqltypes[j] = ipe.getType();
            j++;
        }
        return sqltypes;
    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public String[] getInputSqlNames() throws SAXException, IOException {

        String[] sqlparams = new String[inputlist.size()];
        ;
        Iterator i = inputlist.iterator();
        int j = 0;
        while (i.hasNext()) {
            InputParamElement ipe = (InputParamElement)i.next();
            sqlparams[j] = ipe.getParameter();
            j++;
        }
        return sqlparams;
    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public String[] getInputJavaNames() throws SAXException, IOException {

        String[] javamap = new String[inputlist.size()];
        ;
        Iterator i = inputlist.iterator();
        int j = 0;
        while (i.hasNext()) {
            InputParamElement ipe = (InputParamElement)i.next();
            javamap[j] = ipe.getMap();
            j++;
        }
        return javamap;


    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public String[] getInputParamValues() throws SAXException, IOException {

        String[] javamap = new String[inputlist.size()];
        ;
        Iterator i = inputlist.iterator();
        int j = 0;
        while (i.hasNext()) {
            InputParamElement ipe = (InputParamElement)i.next();
            javamap[j] = ipe.getParamValue();
            j++;
        }
        return javamap;


    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public int[] getOutputIndex() throws SAXException, IOException {

        int parameterindex[] = new int[outputlist.size()];
        ;
        Iterator i = outputlist.iterator();
        int j = 0;
        while (i.hasNext()) {
            OutputParamElement ope = (OutputParamElement)i.next();
            parameterindex[j] = new Integer(ope.getIndex()).intValue();
            j++;
        }
        return parameterindex;
    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public String[] getOutputJavaTypes() throws SAXException, IOException {

        String[] javatypes = new String[outputlist.size()];
        Iterator i = outputlist.iterator();
        int j = 0;
        while (i.hasNext()) {
            OutputParamElement ope = (OutputParamElement)i.next();
            javatypes[j] = ope.getJavatype();
            j++;
        }
        return javatypes;
    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public String[] getOutputSqlTypes() throws SAXException, IOException {

        String[] sqltypes = new String[outputlist.size()];
        ;
        Iterator i = outputlist.iterator();
        int j = 0;
        while (i.hasNext()) {
            OutputParamElement ope = (OutputParamElement)i.next();
            sqltypes[j] = ope.getType();
            j++;
        }
        return sqltypes;
    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public String[] getOutputSqlNames() throws SAXException, IOException {

        String[] sqlparams = new String[outputlist.size()];
        ;
        Iterator i = outputlist.iterator();
        int j = 0;
        while (i.hasNext()) {
            OutputParamElement ope = (OutputParamElement)i.next();
            sqlparams[j] = ope.getParameter();
            j++;
        }
        return sqlparams;
    }

    /**
     * @return
     * @throws SAXException
     * @throws IOException
     */
    public String[] getOutputJavaNames() throws SAXException, IOException {

        String[] javamap = new String[outputlist.size()];
        ;
        Iterator i = outputlist.iterator();
        int j = 0;
        while (i.hasNext()) {
            OutputParamElement ope = (OutputParamElement)i.next();
            javamap[j] = ope.getMap();
            j++;
        }
        return javamap;
    }
}// End XMLDocumentHandler Class
