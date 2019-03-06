CREATE OR REPLACE
PROCEDURE      XX_CS_TEST_ENQUEUE  AS
enqueue_options dbms_aq.enqueue_options_t; 
indoc VARCHAR2(2000); 
indomdoc dbms_xmldom.domdocument; 
innode dbms_xmldom.domnode; 
myParser dbms_xmlparser.Parser; 
message_properties dbms_aq.message_properties_t; 
message_handle RAW(16); 
message sys.XMLTYPE; 

BEGIN 
 
  indoc := '<MOBILECAST>
              <ORDER_NUMBER>12345678</ORDER_NUMBER> 
              <SOURCE_CODE>M</SOURCE_CODE> 
              <STATUS_CODE>50</STATUS_CODE>
            </MOBILECAST>'; 
  myParser := dbms_xmlparser.newParser; 
  dbms_xmlparser.parseBuffer(myParser, indoc); 
  indomdoc := dbms_xmlparser.getDocument(myParser); 
  message := DBMS_XMLDOM.GETXMLTYPE(indomdoc); 
  dbms_aq.enqueue(queue_name => 'xx_cs_xml_queue', 
  enqueue_options => enqueue_options, 
  message_properties => message_properties, 
  payload => message, 
  msgid => message_handle); 
  COMMIT; 

END; 

/
EXIT;


