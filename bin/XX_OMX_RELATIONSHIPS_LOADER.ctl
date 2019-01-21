-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name            : XX_OMX_RELATIONSHIPS_LOADER.ctl     		           |
-- | Description     : SQL Loader Routine to load relationships from flat  |
-- |                   file to table XX_OMX_RELATIONSHIPS                  |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version   Date         Author             Remarks                      |
-- |------- ----------- -----------------  --------------------------------|
-- |1.0     20-Oct-2014   Pooja Mehra         Initial Version              |
-- |2.0		02-Jul-2015	  Pooja Mehra		  Modifies the code to pick up |
-- |										  given file name in program   |
-- |										  parameter.                   |
-- +=======================================================================+

LOAD DATA
INFILE '$FILENAME'
APPEND INTO TABLE XXTPS.XX_OMX_RELATIONSHIPS
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS  
( 
   OMX_PARENT_ID
  ,OMX_CHILD_ID
  ,RELATIONSHIP_CODE "P"
)