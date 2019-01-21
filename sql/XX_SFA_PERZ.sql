/* Formatted on 2007/05/08 15:28 (Formatter Plus v4.8.5) */
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_SFA_PERZ.sql                                                      | 
-- | Description      : SQL Script to generate User-Personalization XML                      |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   27-Mar-2008       Sarah Justina    Initial draft version                      |              
-- +=========================================================================================+
------------------------------------------------------------------------------------------
--This procedure call generates XML for all the DSMs and Proxy Administrators under the 
-- Hierarchy of the input Person_ID. This generates either Lead/Opportunity/Customer 
-- Personlization Files.
------------------------------------------------------------------------------------------
begin
XX_SFA_PERZ_GEN_PKG.create_perz_main(&1,'&2','&3','&4');
end;
/
exit 0;

-- ************************************
-- *          END OF SCRIPT           *
-- ************************************