SET VERIFY OFF;
SET FEEDBACK 1;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XXCRM_RTF_TO_PLAIN_TEXT_POLICY.prc                  |
-- | Description      :I5000 configure SOLAR conversion tables             |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      14_Nov-2007 David Woods        Initial version                |
-- +=======================================================================+
--
-- Notes:
--
--   This is a one time setup.
--   After the preference and policy are created they persist in the database.
--
--   ctxsys.dr$preference - contains the preference
--   ctxsys.dr$index      - contains the policy name
--
begin
  --
  -- Drop the preference and policy if they already exist.
  --
  begin
    ctx_ddl.drop_preference ('xxcrm_rtf_auto_filter');
  exception
    when others then
      null;  -- ignore error if it didn't exist
  end;

  begin
    ctx_ddl.drop_policy ('xxcrm.xxcrm_rtf_to_plain_text_policy');
  exception
    when others then
      null;  -- ignore error if it didn't exist
  end;

  --
  -- AUTO_FILTER is a universal filter that filters most document formats,
  -- including PDF, MS Word, and RTF.
  -- Specifically, the 10gR2 database supports RTF version 1.0 through 1.7.
  -- Based on info from the web, RTF v 1.7 is the latest from the open source project.
  -- RTF v 1.8 was released with MS Word 2003 in April 2004.
  -- RTF v 1.9 was released with MS Word 2007 in January 2007.
  --
  ctx_ddl.create_preference ('xxcrm_rtf_auto_filter', 'AUTO_FILTER');

  --
  -- Create a policy.
  -- This procedure has several optional parameters.
  -- We only need to specify our AUTO_FILTER preference to convert RTF --> plain text.
  --
  ctx_ddl.create_policy ('xxcrm.xxcrm_rtf_to_plain_text_policy', 'xxcrm_rtf_auto_filter');
end;
/
