/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             SAXParser.java                                         |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This Class handles and parsest XML doceuments using a SAX parser       |
 |    according to the ATP flow types, Receives the flow type code and       |
 |    provides the package name associated with the ATP flow type            |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class object will be used in XMLDocumentHandler.java                |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/06/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.xml;

import java.io.IOException;

import java.util.ArrayList;
import java.util.HashMap;

import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 * This class implements the Simple API for XML parsing.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 */
public class SAXParser {

    /**
     * Header Information
     * 
     */
    public static final String RCS_ID = 
        "$Header: SAXParser.java  06/06/2007 Satis-Gnanmani$";

    private String vendorParserClass = "oracle.xml.parser.v2.SAXParser";
    private String xmlURI;
    private HashMap<String, SAXParserElement> hashmap;
    private XMLContentHandler saxparsercontenthandler;

    /**
     * Constructor to initialize the object of the Parser with the filename to 
     * parse.
     * 
     * @param filename XML file to parse
     * 
     */
    public SAXParser(String filename) {
        this.xmlURI = filename;
        hashmap = new HashMap<String, SAXParserElement>();
        saxparsercontenthandler = new XMLContentHandler(hashmap);
    }

    /**
     * Build the parse from the XML document
     * 
     * @throws SAXException
     * @throws IOException
     * 
     */
    public void build() throws SAXException, IOException {

        XMLReader reader = XMLReaderFactory.createXMLReader(vendorParserClass);

        reader.setContentHandler(saxparsercontenthandler);

        InputSource inputSource = 
            new InputSource(new java.io.FileInputStream(new java.io.File(xmlURI)));
        inputSource.setSystemId(xmlURI);

        reader.parse(inputSource);

    }

    /**
     * Get the Executable Procedure Name from the XML document
     * 
     * @param code Flow type code
     * @return executable Pl/Sql procedure to execute
     * 
     */
    public String getExecutable(String code) {
        if (hashmap.get(code) != null)
            return hashmap.get(code).getExecutable();
        else
            return null;
    }

    /**
     * @param code Flow Type code
     * @return name Name of the Flow type
     */
    public String getName(String code) {
        if (hashmap.get(code) != null)
            return hashmap.get(code).getName();
        else
            return null;
    }

    /**
     * Get the Input Element corresponding to the code code.
     * 
     * @param code Flow Type code
     * @return inputElement Input Element of the XML document
     * 
     */
    public ArrayList getInputElement(String code) {
        if (hashmap.get(code) != null)
            return hashmap.get(code).getInputlist();
        else
            return null;
    }

    /**
     * Get the Output Element corresponding to the code code.
     * 
     * @param code Flow type code
     * @return outputElement Output Element of the XML document
     * 
     */
    public ArrayList getOutputElement(String code) {
        if (hashmap.get(code) != null)
            return hashmap.get(code).getOutputlist();
        else
            return null;
    }

    /**
     * Get the SAX element corresponding to the code code.
     * 
     * @param code Flow Type code
     * @return saxParserElement SAX parse element to parse
     * 
     */
    public SAXParserElement getSaxParserElement(String code) {
        return hashmap.get(code);
    }

    /**
     * Get the HashMap
     * 
     * @return hashmap Hash Map of the element mappings
     */
    public HashMap getHashMap() {
        return hashmap;
    }
}
