SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE APPS.XX_OIC_XPATH_PKG AUTHID CURRENT_USER AS
   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                Oracle NAIO Consulting Organization                |
   -- +===================================================================+
   -- | Name        : XX_OIC_XPATH_PKG.pks                                     |
   -- | Description : Package to create an XPATH Simulation so as to      |
   -- |               handle XML data                                     |
   -- | Author      : Nageswara Rao                                       |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |Date      Version     Description                                  |
   -- |=======   ==========  =============                                |
   -- |01-Aug-07   1.0       This package is used to implement xpath      |
   -- |                      functionality for handling XML data          |
   -- |                                                                   |
   -- +===================================================================+

 ------------------------------------------------------------------------------
  -- Function to extract a string from a xml dom document within the particular
  -- given node
  ------------------------------------------------------------------------------
       FUNCTION cnc_extract_fnc
        (p_doc         xmldom.DOMDocument,
         p_xpath       VARCHAR2 := '/',
         p_normalize   BOOLEAN  := TRUE
        )
         RETURN VARCHAR2;

       FUNCTION cnc_test_fnc
        (p_doc         xmldom.DOMDocument,
         p_xpath       VARCHAR2
        )
         RETURN BOOLEAN;

  ------------------------------------------------------------------------------
  --Function to select a node from a given xmldom document
  ------------------------------------------------------------------------------
       FUNCTION cnc_selectnod_fnc
        (p_doc         xmldom.DOMDocument,
         p_xpath       VARCHAR2
        )
         RETURN xmldom.DOMNodeList;

  ------------------------------------------------------------------------------
  --Function to normalize the string passed.
  ------------------------------------------------------------------------------
       FUNCTION cnc_normalizews_fnc(p_v CLOB)
         RETURN CLOB;

  ------------------------------------------------------------------------------
  --Function to get the value of the xmldom node from  a xml dom document
  ------------------------------------------------------------------------------
       FUNCTION cnc_valueOf_fnc
        (p_node       xmldom.DOMNode,
         p_xpath      VARCHAR2,
         p_normalize  BOOLEAN  :=FALSE
        )
         RETURN CLOB;

END XX_OIC_XPATH_PKG;
/