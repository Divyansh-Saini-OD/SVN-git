SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_GEN_XL_xml IS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_GEN_XL_XML.pks		               	       |
-- | Description :  OD Generate Excel from plslq                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       28-Feb-2012 Paddy Sanjeevi     Initial version           |
-- +===================================================================+


debug_flag BOOLEAN := TRUE  ;

PROCEDURE create_excel( p_directory IN VARCHAR2 DEFAULT NULL , 
			p_file_name IN VARCHAR2 DEFAULT NULL ) ;

PROCEDURE create_excel_apps ;

PROCEDURE create_style( p_style_name IN VARCHAR2 
                      , p_fontname IN VARCHAR2 DEFAULT NULL   
                      , p_fontcolor IN VARCHAR2 DEFAULT 'Black' 
                      , p_fontsize IN NUMBER DEFAULT null
                      , p_bold IN BOOLEAN DEFAULT FALSE 
                      , p_italic IN BOOLEAN DEFAULT FALSE 
                      , p_underline IN VARCHAR2 DEFAULT NULL 
                      , p_backcolor IN VARCHAR2 DEFAULT NULL );

PROCEDURE close_file ;

PROCEDURE create_worksheet( p_worksheet_name IN VARCHAR2 ) ;

PROCEDURE write_cell_num(p_row NUMBER , 
			 p_column NUMBER, 
			 p_worksheet_name IN VARCHAR2,  
			 p_value IN NUMBER , 
			 p_style IN VARCHAR2 DEFAULT NULL );

PROCEDURE write_cell_char(p_row NUMBER, 
			  p_column NUMBER, 
			  p_worksheet_name IN VARCHAR2,  
			  p_value IN VARCHAR2, 
			  p_style IN VARCHAR2 DEFAULT NULL  );

PROCEDURE write_cell_null(p_row NUMBER ,  p_column NUMBER , p_worksheet_name IN VARCHAR2, p_style IN VARCHAR2 );

PROCEDURE set_row_height( p_row IN NUMBER , 
			  p_height IN NUMBER, 
			  p_worksheet IN VARCHAR2  ) ;

PROCEDURE set_column_width( p_column IN NUMBER ,
			    p_width IN NUMBER , 
		            p_worksheet IN VARCHAR2  ) ;


END ;
/
