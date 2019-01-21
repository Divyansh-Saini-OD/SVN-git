SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY APPS.XX_OIC_XPATH_PKG AS
   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                Oracle NAIO Consulting Organization                |
   -- +===================================================================+
   -- | Name        : XX_OIC_XPATH_PKG.pkb                                     |
   -- | Description : Package to create an XPATH Simulation so as to      |
   -- |               handle XML data                                     |
   -- | Author      : Nageswara Rao                                       |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |Date      Version     Description                                  |
   -- |=======   ==========  =============                                |
   -- |01-Aug-07  1.0        This package is used to implement xpath      |
   -- |                      functionality for handling XML data          |
   -- |                                                                   |
   -- +===================================================================+

  ------------------------------------------------------------------------------
  --Function to normalize the string passed.
  ------------------------------------------------------------------------------
     FUNCTION cnc_normalizews_fnc(p_v CLOB)
     RETURN CLOB IS
        l_result CLOB;
        l_num1 number;
        l_num2 number;
     BEGIN
        l_num1   := INSTR(p_v,'<',1,2);
        l_num2   := INSTR(p_v,'>',1,1);
        l_result := SUBSTR(p_v,l_num2+1,l_num1-l_num2-1);
        WHILE(INSTR(l_result,'')>0)LOOP
           l_result := REPLACE(l_result,'','');
        END LOOP;
           l_result := REPLACE(l_result,';','&');
        RETURN l_result;
     END;

  ------------------------------------------------------------------------------
  --Function to select a node from a given xmldom document
  ------------------------------------------------------------------------------
     FUNCTION cnc_selectnod_fnc(p_doc   xmldom.DOMDocument,
                                p_xpath VARCHAR2
                               )
     RETURN xmldom.DOMNodeList IS
          l_getvalue   xmldom.DOMNodeList;
          l_tempNode   xmldom.DOMNode ;
     BEGIN
       l_tempNode := xmldom.makeNode(p_doc);
       l_getvalue := xslprocessor.selectNodes(l_tempNode,p_xpath);
       RETURN l_getvalue;
     END cnc_selectnod_fnc;

  ------------------------------------------------------------------------------
  --Function to select and print a given xmldom document
  ------------------------------------------------------------------------------
     FUNCTION cnc_selectAndPrint_fnc(p_doc                  xmldom.DOMDocument,
                                     p_xpath                VARCHAR2,
                                     p_normalizeWhitespace  BOOLEAN := TRUE)
     RETURN CLOB IS
        l_retval     CLOB;
        l_result     CLOB;
        l_curNode    xmldom.DOMNode;
        l_nodeType   NATURAL;
        l_range      CLOB;
        l_matches    xmldom.DOMNodeList;
     BEGIN
       IF p_xpath='/' THEN
          l_retval := 'a';
          xmldom.writeToClob(p_doc,l_retval);
       ELSE
          l_matches := xslprocessor.selectNodes(xmldom.makeNode(p_doc),p_xpath);
          FOR i IN 1..xmldom.getLength(l_matches)
          LOOP
              l_curNode := xmldom.item(l_matches,i-1);
              l_result := 'a';
              xmldom.writeToClob(l_curNode,l_result);
              l_nodeType := xmldom.getNodeType(l_curNode);
              IF l_nodeType NOT IN (xmldom.TEXT_NODE,xmldom.CDATA_SECTION_NODE)THEN
                  l_range  := RTRIM(RTRIM(l_result,chr(10)),chr(13));
                  l_retval := l_retval||l_range;
              ELSE
                  l_retval := l_retval||l_result;
              END IF;
          END LOOP;
       END IF;

       IF p_normalizeWhitespace THEN
          RETURN cnc_normalizews_fnc(l_retval);
       ELSE
          RETURN l_retval;
       END IF;

     END;

  ------------------------------------------------------------------------------
  -- Function to extract a string from a xml dom document within the particular
  -- given node
  ------------------------------------------------------------------------------
     FUNCTION cnc_extract_fnc(p_doc        xmldom.DOMDocument,
                              p_xpath      VARCHAR2  := '/',
                              p_normalize  BOOLEAN   := TRUE)
     RETURN VARCHAR2 IS
     BEGIN
       IF xmldom.isNull(p_doc) OR p_xpath IS NULL THEN
          RETURN NULL;
       END IF;
       RETURN cnc_selectAndPrint_fnc(p_doc,p_xpath,p_normalize);
     END cnc_extract_fnc;

  ------------------------------------------------------------------------------
  --Function to get the value of the xmldom node from  a xml dom document
  ------------------------------------------------------------------------------
     FUNCTION cnc_valueOf_fnc(p_node      xmldom.DOMNode,
                              p_xpath     VARCHAR2,
                              p_normalize BOOLEAN := FALSE)
     RETURN CLOB IS
     BEGIN
       IF xmldom.IsNull(p_node) OR p_xpath IS NULL THEN
          RETURN NULL;
       END IF;
       IF p_normalize THEN
          RETURN cnc_normalizews_fnc(xslprocessor.valueOf(p_node,p_xpath));
       ELSE
          RETURN xslprocessor.valueOf(p_node,p_xpath);
       END IF;
     END cnc_valueOf_fnc;

  ------------------------------------------------------------------------------
  --Function to get the length of the selected node
  ------------------------------------------------------------------------------
    FUNCTION cnc_test_fnc(p_doc xmldom.DOMDocument,p_xpath VARCHAR2)RETURN BOOLEAN IS
      BEGIN
       RETURN xmldom.getLength(cnc_selectnod_fnc(p_doc,'/self::node()['||p_xpath||']'))>0;
     END cnc_test_fnc;
 END XX_OIC_XPATH_PKG;
/