CREATE OR REPLACE PACKAGE XX_JTF_LOAD_TERRALIGN_DATA AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                Oracle NAIO Consulting Organization                             |
-- +================================================================================+
-- | Name       : XX_JTF_LOAD_TERRALIGN_DATA.pks                                    |
-- |                                                                                |
-- | Rice ID    : I0405_Territories_Terralign_Inbound_Interface                     |
-- | Description: Package specification to extract the data from                    |
-- |              XX_JTF_TERR_QUAL_TLIGN_INT table and popuplate the following      |
-- |              a) XX_JTF_TERRITORIES_INT                                         |
-- |              b) XX_JTF_TERR_QUALIFIERS_INT tables                              |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                 Remarks                           |
-- |========  ===========  =============          ===============================   |
-- |DRAFT 1A  12-OCT-2007  Mohan Kalyanasundaram  Initial draft version             |
-- |DRAFT 1B  07-JAN-2007  Hema Chikkanna         Incorporated changes as per OD    |
-- |                                              standards                         |
-- +================================================================================+


PROCEDURE jtf_tlign_load_main ( 
                                x_errbuf      OUT NOCOPY VARCHAR2
                               ,x_retcode     OUT NOCOPY NUMBER
                              );  
                              
                              
                              
END XX_JTF_LOAD_TERRALIGN_DATA;
/

SHOW ERRORS

EXIT;
                             
