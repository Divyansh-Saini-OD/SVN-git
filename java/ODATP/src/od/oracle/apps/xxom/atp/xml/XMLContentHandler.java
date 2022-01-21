/*===========================================================================+
 |      		 Office Depot - Project Simplify                     |
 |              Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             XmlContentHandler.java                                    |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |    This class is used for handling the XML document data and              |
 |    passing it on to the XML Parser.                                       |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is called from SAXParser.java                   |
 |                                                                           |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    06/06/2007 Sathish Gnanamani   Created                                 |
 |                                                                           |
 +===========================================================================*/
package od.oracle.apps.xxom.atp.xml;

import java.util.HashMap;

import od.oracle.apps.xxom.atp.ATPConstants;

import org.xml.sax.Attributes;
import org.xml.sax.ContentHandler;
import org.xml.sax.Locator;
import org.xml.sax.SAXException;

/**
 * This class implements the XML content handler to parse a XML document.
 * 
 * @author Satis-Gnanmani
 * @version 1.2
 */
class XMLContentHandler implements ContentHandler {

    /**
     * Header Information
     * 
     */
    public static final String RCS_ID = 
        "$Header: XmlContentHandler.java  06/06/2007 Satis-Gnanmani$";

    HashMap<String, SAXParserElement> hashmap;
    private SAXParserElement saxparserelement;


    /**
     * default Constructor
     * 
     */
    public XMLContentHandler() {
        hashmap = new HashMap<String, SAXParserElement>();
    }

    /**
     * Constructor with HashMap assignemnt
     * 
     * @param hashmap
     */
    public XMLContentHandler(HashMap<String, SAXParserElement> hashmap) {
        this.hashmap = hashmap;
    }

    /**
     * 
     * 
     * @param uri
     * @param localName
     * @param qName
     * @param atts
     * @throws SAXException
     */
    public void startElement(String uri, String localName, String qName, 
                             Attributes atts) throws SAXException {

        if (ATPConstants.FLOW.equals(qName)) {
            saxparserelement = 
                    new SAXParserElement(atts.getValue(ATPConstants.NAME), 
                                         atts.getValue(ATPConstants.CODE), 
                                         atts.getValue(ATPConstants.EXECUTABLE));
        }

        if (ATPConstants.INPUT.equals(qName)) {
            InputParamElement inputparamelement = 
                new InputParamElement(atts.getValue(ATPConstants.MAP), 
                                      atts.getValue(ATPConstants.PARAMETER), 
                                      atts.getValue(ATPConstants.INDEX), 
                                      atts.getValue(ATPConstants.TYPE), 
                                      atts.getValue(ATPConstants.JAVATYPE), 
                                      atts.getValue(ATPConstants.PARAMVALUE), 
                                      atts.getValue(ATPConstants.REQUIRED));
            saxparserelement.addInputElement(inputparamelement);
        }

        if (ATPConstants.OUTPUT.equals(qName)) {
            OutputParamElement outputparamelement = 
                new OutputParamElement(atts.getValue(ATPConstants.MAP), 
                                       atts.getValue(ATPConstants.PARAMETER), 
                                       atts.getValue(ATPConstants.INDEX), 
                                       atts.getValue(ATPConstants.TYPE), 
                                       atts.getValue(ATPConstants.JAVATYPE));
            saxparserelement.addOutputElement(outputparamelement);
        }

    }

    /**
     * @throws SAXException
     */
    public void endDocument() throws SAXException {
    }

    /**
     * @param locator
     */
    public void setDocumentLocator(Locator locator) {
    }

    /**
     * @param ch
     * @param start
     * @param length
     * @throws SAXException
     */
    public void characters(char[] ch, int start, 
                           int length) throws SAXException {
    }

    /**
     * @param uri
     * @param localName
     * @param qName
     * @throws SAXException
     */
    public void endElement(String uri, String localName, 
                           String qName) throws SAXException {
        if (ATPConstants.FLOW.equals(qName)) {
            hashmap.put(saxparserelement.getCode(), saxparserelement);
        }

    }

    /**
     * @param prefix
     * @throws SAXException
     */
    public void endPrefixMapping(String prefix) throws SAXException {
    }

    /**
     * @param ch
     * @param start
     * @param length
     * @throws SAXException
     */
    public void ignorableWhitespace(char[] ch, int start, 
                                    int length) throws SAXException {
    }

    /**
     * @param target
     * @param data
     * @throws SAXException
     */
    public void processingInstruction(String target, 
                                      String data) throws SAXException {
    }

    /**
     * @param name
     * @throws SAXException
     */
    public void skippedEntity(String name) throws SAXException {
    }

    /**
     * @throws SAXException
     */
    public void startDocument() throws SAXException {
    }

    /**
     * @param prefix
     * @param uri
     * @throws SAXException
     */
    public void startPrefixMapping(String prefix, 
                                   String uri) throws SAXException {
    }

}
