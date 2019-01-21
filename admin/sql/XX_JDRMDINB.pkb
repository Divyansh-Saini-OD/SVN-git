REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE

/*===================================================================*/
-- Copyright (c) Oracle Corporation 2002.  All rights reserved
--
-- JDRMDINB.pls - JDR MetaData services INternal Body
--
--
-- MODIFIED    (MM/DD/YY)
-- gnagaraj     03/28/05  - #(4137848) Avoid Subscript beyond count error when
--                           computing docID for /oracle/apps
-- enewman      08/05/04 -  #(3803543) Reduce SQL by cacheing document names
-- enewman      07/21/04  - #(3773619) Improve performance of getDocumentName
-- enewman      05/11/04  - #(3513280) XLIFF and customization views
-- enewman      03/26/04  - #(3480939) Refactor and criterion 
-- enewman      03/23/04  - #(3477218) XLIFF and customization views
-- enewman      03/01/04  - #(3258371) XLIFF and customization documents
-- enewman      02/19/04  - #(3456035) Modify "package" attribute if needed
-- enewman      02/19/04  - #(3455760) Do not rename old style to new style
-- enewman      02/18/04  - #(3403125) Remove the trailing forward slash
-- enewman      02/18/04  - #(3452725) Make sure new style overrides old style
-- enewman      02/17/04  - #(3450638) Fix refactor and old style customizations
-- enewman      02/17/04  - #(3260414) Fix views and exporting XLIFF document
-- enewman      02/17/04  - #(3234805) Check for forward slash in getDocumentID
-- enewman      02/04/04  -  Add refactor()
-- enewman      07/17/03  - #(3057405) Update repository version
-- enewman      06/16/03  - #(3007167) Fix query for xliff export
-- enewman      06/12/03  -  Reduce network traffic for exporting XLIFF
-- enewman      06/05/03  - #(2995144) Fix check for fetch completion
-- enewman      05/30/03  - #(2822216) Performance improvements
-- enewman      05/22/03  - #(2669626) Check for corrupt document sequence
-- enewman      05/16/03  -  Add exportXLIFFDocument
-- enewman      11/13/02  - #(2658784) Do not hardcode PACKAGE
-- kaalvare     10/07/02  - #(2602211) Performance enhancements
-- kaalvare     10/02/02  - #(2605120) Modify lockDocument procedure
-- enewman      09/26/02  - #(2586854) Increase maximum size of attribute to 32000
-- kaalvare     09/26/02  - Changed repos version due to customization changes
-- kaalvare     09/25/02  - #(2589190) Lock document during prepareDocForInsert
-- enewman      09/13/02  - #(2456503) Generate specific application for
--                           package file/document name conflicts
-- enewman      09/12/02  - #(2427369) Delete package documents more efficiently
-- kaalvare     08/28/02  -  Changed REPOS_VERSION
-- enewman      07/22/02  - #(2424399) Add support for xml version, encoding
-- enewman      07/18/02  -  Add getMinJRADVersion(), getRepositoryVersion()
-- enewman      06/19/02  - #(2424554) Add getVersion()
-- enewman      06/18/02  - #(2620444) Use sequence to get next document ID
-- enewman      06/14/02  - #(2417655) Remember path type when exporting
-- enewman      06/12/02  - #(2414317) Fix definition of NEWLINE
-- enewman      06/06/02  - #(2365869) Add support for "who" columns
-- enewman      06/06/02  -  Modifications to follow apps coding standards
-- enewman      05/31/02  -  Fix issue w/ null attribute values
-- enewman      05/28/02  -  Add initial support for "who"columns
-- enewman      05/24/02  -  Creating from cremdsapi.sql with modifications 
--                           for package file support
-- kaalvare     05/01/02  -  Add getDocumentIDs(), numArray, stringArray
-- cbarrow      04/01/02  -  Schema changes (remove PATH_LANGID, rename 
--                           ATL_LANGID to ATL_LANG)
-- enewman      03/29/02  -  Remove dependency on JDR_MDS_CHUNKS table
-- enewman      03/28/02  -  Creation.
--
--

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY jdr_mds_internal AS
/* $Header: JDRMDINB.pls 115.22 2005/04/08 06:25:47 nigoel noship $ */
  -----------------------------------------------------------------------------
  ---------------------------- PRIVATE VARIABLES ------------------------------
  -----------------------------------------------------------------------------

  -- This is used to verify that the repository API and JRAD java code are
  -- compatible.  When the repository API is updated, this constant should
  -- be modified to match the latest version of JRAD.  In addition, in the
  -- JRAD java code, CompatibleVersions.MIN_REPOS_VERSION may also need to 
  -- be modified. 
  REPOS_VERSION    CONSTANT VARCHAR2(32) := '9.0.5.2.0_459';


  -- This is used to verify that the repository API and JRAD java code are
  -- compatible.  This is the earliest JRAD version which is compatible
  -- with the repository.
  MIN_JRAD_VERSION CONSTANT VARCHAR2(32) := '9.0.3.5.0_226';

  -- NEWLINE character
  NEWLINE CONSTANT VARCHAR2(1) := '
';

  -- Maximimum size of XML chunk
  MAX_CHUNK_SIZE CONSTANT INTEGER := 32000;

  -- Indentation for XML elements
  INDENT_SIZE    CONSTANT INTEGER := 3;

  -- Maximum rows to fetch with bulk bind
  ROWS_TO_FETCH  CONSTANT INTEGER := 1000;

  -- Exception raised when MAX_CHUNK_SIZE exceeded
  chunk_size_exceeded EXCEPTION;
  document_name_conflict EXCEPTION;
  corrupt_sequence  EXCEPTION;
  
  -- Cursor to  retrieve all of the components of a document
  CURSOR c_document_contents(docid NUMBER) IS
    SELECT 
      comp_seq,
      comp_element,
      comp_level,
      comp_grouping,
      comp_id,
      comp_ref,
      comp_extends,
      comp_use,
      att_name,
      att_value
    FROM 
      jdr_components, jdr_attributes
    WHERE 
      comp_docid = docid AND
      comp_docid = att_comp_docid(+) AND
      comp_seq = att_comp_seq(+)
    ORDER BY 
      comp_seq,
      att_comp_seq,
      att_seq;

  -- Cursor to retrieve all of the components of a package
  CURSOR c_package_contents(docid NUMBER) IS
    SELECT --+ RULE
      path_docid, 
      path_name,
      path_type,
      path_seq,
      path_owner_docid,
      comp_seq,
      comp_element,
      comp_level,
      comp_grouping,
      comp_id,
      comp_ref,
      comp_extends,
      comp_use,
      att_name,
      att_value
    FROM 
      jdr_paths, jdr_components, jdr_attributes
    WHERE 
      path_docid IN
        (SELECT 
           path_docid 
         FROM 
           jdr_paths
         START WITH 
           path_docid = docID
         CONNECT BY PRIOR 
           path_docid=path_owner_docid
        ) AND    
      path_docid = comp_docid(+) AND
      comp_docid = att_comp_docid(+) AND
      comp_seq = att_comp_seq(+)
    ORDER BY 
      path_seq,
      comp_seq,
      att_comp_seq,
      att_seq; 

   -- Cursor to retrieve XLIFF translations
   -- This query will retrieve the translations for a specified
   -- document (as well as sub-documents if it's a package file) and 
   -- specified language; and will retrieve the base language as well.
   CURSOR c_trans(docid jdr_paths.path_docid%TYPE, lang VARCHAR2) IS
    SELECT
      atl_comp_docid,
      atl_comp_ref,
      atl_name,
      atl_value
    FROM
      jdr_attributes_trans
    WHERE
      atl_comp_docid IN (SELECT path_docid FROM jdr_paths
                         START WITH path_docid = docID
                         CONNECT BY PRIOR path_docid=path_owner_docid) AND
      atl_lang = lang
    ORDER BY
      atl_comp_docid,
      atl_comp_ref;


  -- State needed for exportXML
  TYPE CharArray IS VARRAY(100) OF VARCHAR2(128);
  TYPE NumArray IS VARRAY(100) OF NUMBER;

 -- Types needed for bulk bind
  TYPE pathdocidtab IS TABLE OF jdr_paths.path_docid%TYPE;
  TYPE pathnametab IS TABLE OF jdr_paths.path_name%TYPE;
  TYPE pathtypetab IS TABLE OF jdr_paths.path_type%TYPE;
  TYPE pathseqtab IS TABLE OF jdr_paths.path_seq%TYPE;
  TYPE pathownertab IS TABLE OF jdr_paths.path_owner_docid%TYPE;
  TYPE compseqtab IS TABLE OF jdr_components.comp_seq%TYPE;
  TYPE compelementtab IS TABLE OF jdr_components.comp_element%TYPE;
  TYPE compleveltab IS TABLE OF jdr_components.comp_level%TYPE;
  TYPE compgroupingtab IS TABLE OF jdr_components.comp_grouping%TYPE;
  TYPE compidtab IS TABLE OF jdr_components.comp_id%TYPE;
  TYPE compreftab IS TABLE OF jdr_components.comp_ref%TYPE;
  TYPE compextendstab IS TABLE OF jdr_components.comp_extends%TYPE;
  TYPE compusetab IS TABLE OF jdr_components.comp_use%TYPE;
  TYPE attnametab IS TABLE OF jdr_attributes.att_name%TYPE;
  TYPE attvaluetab IS TABLE OF jdr_attributes.att_value%TYPE;
  TYPE varchar64tab IS TABLE OF VARCHAR2(64) INDEX BY BINARY_INTEGER;
  
  mStack         CharArray := NULL;
  mPackageNames  CharArray := NULL;
  mPackageStack  NumArray := NULL;
  mPackageLevel  INTEGER;
  mPreviousLevel jdr_components.comp_level%TYPE;
  mPreviousComp  jdr_components.comp_seq%TYPE;
  mPreviousDocID jdr_paths.path_docid%TYPE;
  mPreviousType  jdr_paths.path_type%TYPE;
  mPartialChunk  VARCHAR2(32000);
  mPartialXLIFFChunk  VARCHAR2(32000);
  mPathType      jdr_paths.path_type%TYPE;
  mIndex         INTEGER;
  mFormatted     INTEGER;
  mFetchComplete BOOLEAN;
  mPathIds       pathdocidtab;
  mPathNames     pathnametab;
  mPathTypes     pathtypetab;
  mPathSeqs      pathseqtab;
  mPathOwners    pathownertab;
  mCompSeqs      compseqtab;
  mCompElements  compelementtab;
  mCompLevels    compleveltab;
  mCompGroupings compgroupingtab;
  mCompIds       compidtab;
  mCompRefs      compreftab;
  mCompExtends   compextendstab;
  mCompUses      compusetab;
  mAttNames      attnametab;
  mAttValues     attvaluetab;

  -- #(3803543) This was added to reduce the number of SQL executions
  -- needed to get the document id for a given document name
  mPackageCache  varchar64tab;
  
  -- User-defined exceptions.
  -- Each of the following errors should correspond to an error in the 
  -- oracle.jrad.repos.api.DBAccess class.
  ERROR_BASE                    CONSTANT INTEGER := -20100;
  ERROR_DOCUMENT_NAME_CONFLICT  CONSTANT INTEGER := ERROR_BASE;
  ERROR_PACKAGE_NAME_CONFLICT   CONSTANT INTEGER := ERROR_BASE - 1;
  ERROR_CORRUPT_SEQUENCE        CONSTANT INTEGER := ERROR_BASE - 2;
  ERROR_INVALID_NAME            CONSTANT INTEGER := ERROR_BASE - 3;
  ERROR_INCONSISTENT_MAPPING    CONSTANT INTEGER := ERROR_BASE - 4;
  ERROR_ILLEGAL_MAPPING         CONSTANT INTEGER := ERROR_BASE - 5;
  
  -----------------------------------------------------------------------------
  ----------------------------- PRIVATE FUNCTIONS -----------------------------
  -----------------------------------------------------------------------------

  -- 
  -- Creates the XML for the specified attribute
  --
  PROCEDURE addAttribute(
    newxml IN OUT VARCHAR2,
    name          VARCHAR2,
    value         VARCHAR2) 
  IS
  BEGIN
    IF (name IS NOT NULL) THEN
      newxml := newxml || ' ' || name || '="' || value || '"';
    END IF;
  END;


  --
  -- Creates the XML for the new component
  --
  PROCEDURE addComponent(
    newxml IN OUT   VARCHAR2,
    compseq         jdr_components.comp_seq%TYPE,
    compelement     jdr_components.comp_element%TYPE,
    complevel       jdr_components.comp_level%TYPE,
    compgrouping    jdr_components.comp_grouping%TYPE,
    compid          jdr_components.comp_id%TYPE,
    compref         jdr_components.comp_ref%TYPE,
    compextends     jdr_components.comp_extends%TYPE,
    compuse         jdr_components.comp_use%TYPE,
    attname         jdr_attributes.att_name%TYPE,
    attvalue        jdr_attributes.att_value%TYPE,
    formatted       BOOLEAN DEFAULT TRUE) 
  IS
    adjLevel     INTEGER;
  BEGIN
    --
    -- If there is a grouping for this component, subtract one from the 
    -- level (as that's the actual starting level of the new component).
    --
    IF (compgrouping IS NOT NULL) THEN
      adjLevel := complevel - 1;
    ELSE
      adjLevel := complevel;
    END IF;

    -- End the previous component (assuming this is not the first component)
    IF (complevel <> 0) THEN            
      IF (adjLevel <= mPreviousLevel) THEN          
        -- The previous component has no children, so we can end the tag now
        newxml := newxml || '/>' || NEWLINE;
      ELSE
        -- There are potential children to come, so keep the tag open
        newxml := newxml || '>' || NEWLINE;
      END IF;            
    END IF;

    -- Check if we need to pop any components/groupings from the stack
    FOR i IN REVERSE  adjLevel+1..mPreviousLevel LOOP
      IF (formatted) THEN
        newxml := newxml || rpad(' ', (mPackageLevel+i-1)*INDENT_SIZE, ' ');
      END IF;
      newxml := newxml ||  '</' || mStack(i) || '>' || NEWLINE;
    END LOOP;

    -- Push the grouping (if it exists)
    IF (compgrouping IS NOT NULL) THEN
      mStack(complevel) := compgrouping;
      IF (formatted) THEN
        newxml := newxml || 
                  rpad(' ', (mPackageLevel+complevel-1)*INDENT_SIZE, ' ');
      END IF;
      newxml := newxml || '<' || compgrouping || '>' || NEWLINE;
    END IF;

    -- Add the element
    mStack(complevel+1) := compelement;
    IF (formatted) THEN
      newxml := newxml ||  
                rpad(' ', (mPackageLevel+complevel)*INDENT_SIZE, ' ');
    END IF;
    newxml := newxml || '<' || compelement;

    -- Add the flat attributes
    IF (compid IS NOT NULL) THEN
      newxml := newxml || ' id="' || compid || '"';
    END IF;

    IF (compref IS NOT NULL) THEN
      IF (compextends = 'Y') THEN
        newxml :=  newxml || ' extends="' || compref || '"';
       ELSE
       newxml := newxml || ' ref="' || compref || '"';
      END IF;
    END IF;

    IF (compuse IS NOT NULL) THEN
      newxml := newxml || ' use="' || compuse || '"';
    END IF;

    -- Add the 4th-normal attribute (if any) from the attributes table
    addAttribute(newxml, attname, attvalue);

    -- Update the state
    mPreviousLevel := complevel;
    mPreviousComp := compseq;
  END;


  --
  -- Add the XML to the current chunk and raise an exception if the 
  -- maximum size is exceeded.
  --
  PROCEDURE addXMLtoChunk(
    chunk  IN OUT   VARCHAR2,
    newxml          VARCHAR2)
  IS
  BEGIN
--    IF ((LENGTH(newxml) + LENGTH(chunk)) > MAX_CHUNK_SIZE) THEN
    IF ((LENGTHB(newxml) + LENGTHB(chunk)) > MAX_CHUNK_SIZE) THEN
      RAISE chunk_size_exceeded;
    ELSE
      chunk := chunk || newxml;
    END IF;
  END;


  --
  -- Create the XML header for the given document ID
  --
  FUNCTION addXMLHeader(
    docID         JDR_PATHS.PATH_DOCID%TYPE) RETURN VARCHAR2
  IS
    xml_version   jdr_paths.path_xml_version%TYPE;
    xml_encoding  jdr_paths.path_xml_encoding%TYPE;
  BEGIN
    -- Get the version and encoding
    SELECT
      path_xml_version, path_xml_encoding
    INTO
      xml_version, xml_encoding
    FROM
      jdr_paths
    WHERE
      path_docid = docID;

    -- ###
    -- ### #(2424399) Need to be able to retrieve XML_ENCODING and XML_VERSION 
    -- ### from the XML file
    -- ###
    IF (xml_encoding IS NULL) THEN
      xml_encoding := 'UTF-8';
    END IF;
    IF (xml_version IS NULL) THEN
      xml_version := '1.0';
    END IF;

    -- Return the xml header
    RETURN ('<?xml version=''' || xml_version || ''' encoding=''' ||
            xml_encoding || '''?>' || NEWLINE);
  END;


  --
  -- Retrieves the document id for the specified fully qualified path name.
  -- The pathname must begin with a '/' and should look something like:
  --   /oracle/apps/AK/mydocument
  --
  -- Parameters:
  --   fullPathName  - the fully qualified name of the document
  --
  --   allowChildDoc - a non-zero value indicates that "child" documents
  --                   are allowed, where child documents are documents
  --                   which exist as part of a package document
  --
  --   includePackage - a non-zero value indicates that, if this is a "child"
  --                    document and it allowChildDoc is TRUE, then the docid
  --                    of the package document will be returned; otherwise, 
  --                    the ID of the "child" document will be returned
  --
  -- Returns:
  --   Returns the ID of the path or -1 if no such path exists
  --   
  FUNCTION getDocumentID(
    fullPathName   VARCHAR2,
    allowChildDoc  BOOLEAN,
    includePackage BOOLEAN) RETURN NUMBER
  IS
    packageName   VARCHAR2(512);
    pName         JDR_PATHS.PATH_NAME%TYPE;
    pType         JDR_PATHS.PATH_TYPE%TYPE;
    pSeq          JDR_PATHS.PATH_SEQ%TYPE;
    ownerID       JDR_PATHS.PATH_OWNER_DOCID%TYPE := 0;
    docID         JDR_PATHS.PATH_DOCID%TYPE := -1;
    lastSlashPos  BINARY_INTEGER;
  BEGIN
    packageName := fullPathName;

    -- #(3403125) Remove the trailing forward slash
    IF (INSTR(packageName, '/', LENGTH(packageName)) > 0)  THEN
      packageName := SUBSTR(packageName, 1, LENGTH(packageName) - 1);
    END IF;

    -- Separate the leaf path name and package name
    lastSlashPos := INSTR(packageName, '/', -1);
    pName := SUBSTR(packageName, lastSlashPos + 1);
    packageName := SUBSTR(packageName, 1, lastSlashPos - 1);

    -- Get the id for the package
    ownerID := getDocumentID(packageName, 'PACKAGE');
    IF ownerID = -1 THEN
      RETURN (-1);
    END IF;

    -- Now get the ID for the document
    SELECT path_docid, path_type, path_seq
    INTO docID, pType, pSeq
    FROM jdr_paths
    WHERE path_name = pName AND path_owner_docid = ownerID;

    IF (pType = 'PACKAGE') THEN
      IF (pSeq = 0) THEN
        -- This is a package document
        RETURN (docID);
      END IF;
    ELSIF (pType = 'DOCUMENT') THEN
      IF (pSeq = -1) THEN
        -- This is a document which is not apart of a package document
        RETURN (docID);
      ELSIF (allowChildDoc) THEN
        --
        -- This is a child document, so we need to return either the
        -- ID of the package document, or the ID of the child document.
        --
        IF (includePackage) THEN
          RETURN (getPackageDocument(docID));
        ELSE
          RETURN (docID);
        END IF;
      END IF;
    END IF;

    RETURN (-1);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN (-1);
  END;


  -----------------------------------------------------------------------------
  ----------------------------- PUBLIC FUNCTIONS ------------------------------
  -----------------------------------------------------------------------------


  -- 
  -- Creates an entry in the jdr_paths table for the document or package.
  -- The full name of the document/package must be specified.  Any packages
  -- which do not already exist will be created as well.
  --
  -- Parameters:
  --   username     - user who is creating the document  
  --   fullPathName - the complete path name of the document or package
  --   docType      - either 'PACKAGE' or 'DOCUMENT' OR NULL
  --   xmlversion   - xml version 
  --   xmlencoding  - xml encoding
  --
  -- Returns:
  --   the ID of the created path
  --
  FUNCTION createPath(
    username     VARCHAR2,
    fullPathName VARCHAR2, 
    docType      VARCHAR2,
    xmlversion   VARCHAR2,
    xmlencoding  VARCHAR2) RETURN NUMBER
  IS
    CURSOR c(packageName VARCHAR2, ownerID NUMBER) IS
      SELECT path_docid
      FROM jdr_paths
      WHERE path_name = packageName AND
            path_owner_docid = ownerID AND
            path_seq = -1 AND
            path_type = 'PACKAGE';

    ownerID     jdr_paths.path_docid%TYPE := 0;
    newDocID    jdr_paths.path_docid%TYPE := 0;
    docID       jdr_paths.path_docid%TYPE := 0;
    pathSeq     jdr_paths.path_seq%TYPE := 0;
    packageName jdr_paths.path_name%TYPE;
    slashpos    INTEGER := 1;
    tempdoc     VARCHAR2(1024) := fullPathName;
  BEGIN

    -- Skip the first slash
    IF (INSTR(tempdoc, '/') <> 1) THEN
      RETURN (-1);
    ELSE
      tempdoc := SUBSTR(tempdoc, 2);
    END IF;

    -- #(3403125) Remove the trailing forward slash 
    IF (INSTR(tempdoc, '/', LENGTH(tempdoc)) > 0)  THEN
      tempdoc := SUBSTR(tempdoc, 1, LENGTH(tempdoc) - 1);
    END IF;  
    
    WHILE (slashpos <> 0) LOOP

      -- Search for the next slash
      slashpos := INSTR(tempdoc, '/');

      -- A null docType indicates that this path represents a directory.
      -- If so, do not create an entry for the package document or document.
      IF ((slashpos = 0) AND (docType IS NOT NULL)) THEN
        -- 
        -- There are no more slashes, which means that all that is left
        -- is the name of the package document (pathSeq = 0) or the name of
        -- the document (pathSeq=-1).
        --
        IF (docType = 'PACKAGE') THEN
          pathSeq := 0;
        ELSE
          pathSeq := -1;
        END IF;
        docID := createPath(username, 
                            tempdoc, 
                            ownerID, 
                            pathSeq, 
                            docType,
                            xmlversion,
                            xmlencoding);
      ELSE
        -- Get the package name
        IF (slashpos <> 0) THEN
          packageName := SUBSTR(tempdoc, 1, slashpos-1);
          tempdoc := SUBSTR(tempdoc, slashpos+1);
        ELSE
          -- This will happen if this is the last part of the path and the 
          -- path represents a directory (i.e. docType is null)
          packageName := tempdoc;
        END IF;
        
        -- Does this package already exist    
        OPEN c(packageName, ownerID);
        FETCH c INTO newDocID;

        -- Insert the package if it does not already exist
        IF c%NOTFOUND THEN
          newDocID := createPath(username, packageName, ownerID, -1, 'PACKAGE');
        END IF;
        CLOSE c;

        ownerID := newDocID;

        -- If this is the last part of the path (i.e. slashpos = 0), then
        -- this path represents a directory and we are done
        IF (slashpos = 0) THEN
          docID := ownerID;
        END IF;
        
      END IF;
    END LOOP;

    RETURN (docID);
  END;


  --
  -- Creates an entry in the jdr_paths document.
  --
  -- Parameters:
  --   username     - user who is creating the document  
  --   pathname     - the name of the document/package (not fully qualified)
  --   ownerID      - the ID of the owning package
  --   pathSeq      - sequence of the path 
  --   docType      - either 'DOCUMENT' or 'PACKAGE'
  --   xmlversion   - xml version, which can be null for "child" documents 
  --   xmlencoding  - xml encoding, which can be null for "child" documents

  --
  -- Returns:
  --   the ID of the created path
  --
  FUNCTION createPath(
    username    VARCHAR2,
    pathname    VARCHAR2,
    ownerID     JDR_PATHS.PATH_OWNER_DOCID%TYPE,
    pathSeq     JDR_PATHS.PATH_SEQ%TYPE,
    docType     VARCHAR2,
    xmlversion  VARCHAR2 DEFAULT NULL,
    xmlencoding VARCHAR2 DEFAULT NULL) RETURN NUMBER
  IS
    docID      JDR_PATHS.PATH_DOCID%TYPE;
  BEGIN
    -- Get the next document ID
    SELECT jdr_document_id_s.NEXTVAL INTO docID FROM DUAL;

    INSERT INTO jdr_paths
      (PATH_NAME, PATH_DOCID, PATH_OWNER_DOCID, PATH_TYPE, PATH_SEQ,
       PATH_XML_VERSION, PATH_XML_ENCODING,
       CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, 
       LAST_UPDATE_LOGIN)
    VALUES
      (pathname, docID, ownerID, docType, pathSeq,
       xmlversion, xmlencoding,
       username, SYSDATE, username, SYSDATE, username);
    
    RETURN (docID);
  EXCEPTION
    -- An exception can be caused by one of the following situations:
    -- (1) If the sequence JDR_DOCUMENT_ID_S is corrupt (i.e. the current value
    --     of the sequence is less than the maximum document ID)
    -- (2) We are trying to insert a document whose name matches an existing 
    --     package or vice versa.  For example, suppose we have a document 
    --     called:
    --       /demo/test/mydoc.xml
    --     and we try to create a document called:
    --       /demo/test.xml
    --     This will fail due to the unique index on (path_owner_docid, 
    --     path_name).
    --  (3) Two users are attempting to insert the same document at the same
    --      time
    WHEN DUP_VAL_ON_INDEX THEN
      -- If this exception was caused by (3), then the following select should
      -- now return the correct docid because the first user will have
      -- finished saving the document.
      DECLARE
        cnt   INTEGER;
      BEGIN        
        SELECT path_docid INTO docID
        FROM jdr_paths
        WHERE
          path_name = pathname AND
          path_owner_docid = ownerID AND
          path_type = docType AND
          path_seq = pathseq;
        RETURN (docID);
      EXCEPTION
        -- Since no data was found, we know this was caused by either (1) or
        -- or (2).  If the following query returns no rows, then this can only
        -- be explained by a corrupt sequence; otherwise, we are dealing with
        -- a name conflict.
        WHEN NO_DATA_FOUND THEN
          SELECT count(*) INTO cnt
          FROM jdr_paths
          WHERE
            path_name = pathname AND
            path_owner_docid = ownerID;

          IF (cnt = 0) THEN
            raise corrupt_sequence;
          ELSE
            raise document_name_conflict;
          END IF;
      END;            
  END;


  --
  -- Delete the document.
  --
  -- Parameters:
  --   docID  - ID of the document to delete 
  --   isDrop - should the document be dropped as well.  If TRUE, then the 
  --            document will be completely removed.  If FALSE, then only
  --            the contents of the document will be deleted, and the entry
  --            in the jdr_paths table will remain.
  --
  -- Notes:
  --   If the document is a package document, then the "child" documents will
  --   be deleted as well.
  --
  PROCEDURE deleteDocument(
    docID      JDR_PATHS.PATH_DOCID%TYPE,
    isDrop     BOOLEAN DEFAULT FALSE)
  IS
  BEGIN
    -- Delete the attributes of the document
    DELETE jdr_attributes WHERE att_comp_docid IN
      (SELECT path_docid FROM jdr_paths
       START WITH path_docid = docid
       CONNECT BY PRIOR path_docid=path_owner_docid);

    -- Delete the components of the document
    DELETE jdr_components WHERE comp_docid IN
      (SELECT path_docid FROM jdr_paths
       START WITH path_docid = docid
       CONNECT BY PRIOR path_docid=path_owner_docid);
       
    -- 
    -- If isDrop is TRUE, then delete the document from the jdr_paths
    -- table.  Otherwise, mark the path_seq to a special value (-2).  
    -- 
    -- We have to go through this complexity because:
    -- (1) When updating a document, we want to make sure that the 
    --     document ID is preserved.  As such, we can not simply remove
    --     the row from the jdr_paths table and create a new one later.
    --
    -- (2) However, there could be a scenario where a package document that 
    --     is originally in the package, is removed at some later time.  In 
    --     order to insure that these "dangling" packages get deleted
    --     properly, we mark the path_seq to -2, and, if after saving the
    --     document, the path_seq has not been changed to a postive integer,
    --     then we know the document should be removed.
    --     
    IF (isDrop) THEN
      DELETE jdr_paths where path_docid IN 
        (SELECT path_docid FROM jdr_paths
         START WITH path_docid = docid
         CONNECT BY PRIOR path_docid=path_owner_docid);        
    ELSE
        UPDATE jdr_paths SET path_seq = -2 
        WHERE path_seq > 0 AND path_docid IN
         (SELECT path_docid FROM jdr_paths
          START WITH path_docid = docid
          CONNECT BY PRIOR path_docid=path_owner_docid);
    END IF;

    -- ###
    -- ### Do we need to deal with references, translations or customizations.
    -- ###
  END;


  --
  -- Drops the document and the document's contents from the repository.
  -- If the document is a package document, the "child" documents of the
  -- package document will be dropped as well.
  --
  PROCEDURE dropDocument(
    docID      JDR_PATHS.PATH_DOCID%TYPE)
  IS
  BEGIN
    -- ###
    -- ### Should we allow the dropping of child documents and/or packages?
    -- ###
    jdr_mds_internal.deleteDocument(docID, TRUE); 
  END;


  --
  -- Export the XML for a "single" document and pass it back in 32k chunks.  
  -- This function will return XML chunks, with a maximum size of 32k.  
  --
  -- A "single" document is simply a document which is not a package document.
  -- See comments for exportDocumentAsXML for more information.
  --
  FUNCTION exportSingleDocument(
    docID              JDR_PATHS.PATH_DOCID%TYPE,
    iFormatted         INTEGER,
    exportFinished OUT INTEGER)  RETURN VARCHAR2
  IS
    chunk         VARCHAR2(32000);
    newxml        VARCHAR2(32000);
    formatted     BOOLEAN := (iFormatted = 1);
  BEGIN
    -- Assume that the document will fit in this 32k chunk
    exportFinished := 1;
    
    --
    -- This procedure returns the XML for the specified document.  Since the
    -- XML can be potentially large (greater than 32k) and since, for
    -- performance reasons, we do not want to return more than 32k at a time,
    -- this procedure may need to be called multiple times to retrieve the
    -- entire document.  As such, the "state" of the export is stored in
    -- package variables.
    --
    -- A non-null document indicates that the export process is just
    -- being started, so let's do the necessary initialization.
    --
    IF (docID IS NOT NULL) THEN
      -- Get the XML header 
      chunk := addXMLHeader(docID);

      -- Initialize the state of the export
      mPackageLevel := 0;
      mPreviousDocID := -1;
      mPreviousComp := -1;
      mPreviousLevel := -1;
      mPreviousType := NULL;
      mPartialChunk := '';
      mIndex := -1;
      mFetchComplete := FALSE;
      
      -- Verify that the cursor is closed
      IF (c_document_contents%ISOPEN) THEN
        -- ###
        -- ### Not sure what to do here, as the cursor should never be open
        -- ### For now, we'll just close it and cross our fingers
        -- ###
        CLOSE c_document_contents;
      END IF;

      -- And open the cursor that will retrieve the documents/packages
      OPEN c_document_contents(docID);

    ELSIF (mPartialChunk IS NULL) THEN
      -- We have finished exporting the document, just return NULL to 
      -- indicate that there is no more XML for this document
      RETURN (NULL);
    ELSE
      -- Get the leftovers (if any) from the previous call to this function
      chunk := mPartialChunk;
      mPartialChunk := '';
    END IF;

    newxml := NULL;
    IF (c_document_contents%ISOPEN) THEN
      <<get_components_loop>>
      LOOP
        --
        -- Retrieve the next set of rows if we are currently not in the
        -- middle of processing a fetched set or rows.
        --
        IF (mIndex = -1) THEN
          -- #(2995144) Check if there are any more rows to fetch
          IF (mFetchComplete) THEN
            CLOSE c_document_contents;          
            EXIT;
          END IF;
          
          -- Fetch the next set of rows
          FETCH c_document_contents BULK COLLECT 
          INTO mCompSeqs, mCompElements, mCompLevels, mCompGroupings, 
               mCompIds, mCompRefs, mCompExtends, mCompUses,
               mAttNames, mAttValues
          LIMIT ROWS_TO_FETCH;

          -- Since we are only fetching records if either (1) this is the first
          -- fetch or (2) the previous fetch did not retrieve all of the 
          -- records, then at least one row should always be fetched.  But
          -- checking just to make sure.
          IF (c_document_contents%ROWCOUNT = 0) THEN
            CLOSE c_document_contents;          
            EXIT;
          END IF;

          -- Check if all of the rows have been fetched.  If so, indicate that
          -- the fetch is complete so that another fetch is not made.
          IF (c_document_contents%NOTFOUND) THEN
            mFetchComplete := TRUE;
          END IF;

          mIndex := mCompSeqs.FIRST;
        END IF;

        <<add_components_loop>>
        WHILE (mIndex <= mCompSeqs.COUNT) LOOP    
          IF (mCompSeqs(mIndex) <> mPreviousComp) THEN

            -- We are starting a new component, so add the "previous" component
            addXMLtoChunk(chunk, newxml);
            newxml := NULL;

            -- And start building the new component
            addComponent(newxml, 
                         mCompSeqs(mIndex), mCompElements(mIndex),
                         mCompLevels(mIndex), mCompGroupings(mIndex),
                         mCompIds(mIndex), mCompRefs(mIndex), 
                         mCompExtends(mIndex), mCompUses(mIndex),
                         mAttNames(mIndex), mAttValues(mIndex),
                         formatted);
          ELSE
            --
            -- This is the same sequence of the previous row, which means
            -- it's only a new attribute, so just add the XML for the attribute
            --
            addAttribute(newxml, mAttNames(mIndex), mAttValues(mIndex));
          END IF;

          -- Increment the index to get the next row
          mIndex := mIndex + 1;
        END LOOP add_components_loop;

        -- We are not in the middle of processing a bulk fetch anymore
        mIndex := -1;

        -- Append any leftover XML
        addXMLtoChunk(chunk, newxml);
        newxml := NULL;
                
      END LOOP get_components_loop;

      --
      -- We have finished exporting the document.  The only task that remains
      -- it to end the previous component and to unwind the stack
      --
      newxml := NULL;
      
      -- End the previous element
      newxml := newxml || '/>' || NEWLINE;

      -- Unwind the document stack
      WHILE (mPreviousLevel > 0) LOOP
        IF (formatted) THEN
          newxml := newxml || 
                    rpad(' ', (mPreviousLevel-1)*INDENT_SIZE, ' ');
        END IF;
        newxml := newxml || '</' || mStack(mPreviousLevel) || '>' || NEWLINE;
        mPreviousLevel := mPreviousLevel - 1;
      END LOOP;
      addXMLtoChunk(chunk, newxml);
    END IF;

    --
    -- Return the current chunk, and set the mPartialChunk to NULL so that, 
    -- when entering this function again, we will know that we have finished
    -- processing the document.
    --
    mPartialChunk := NULL;
    RETURN (chunk);
    
  EXCEPTION
    WHEN chunk_size_exceeded THEN
      exportFinished := 0;
      mPartialChunk := newxml;
      RETURN (chunk);
  END;


  --
  -- Export the XML for a package document and pass it back in 32k chunks.  
  -- This function will return XML chunks, with a maximum size of 32k. 
  --
  -- See comments for exportDocumentAsXML for more information.
  --
  FUNCTION exportPackageDocument(
    docID              JDR_PATHS.PATH_DOCID%TYPE,
    iFormatted         INTEGER DEFAULT 1,
    exportFinished OUT INTEGER)  RETURN VARCHAR2
  IS
    chunk         VARCHAR2(32000);
    newxml        VARCHAR2(32000);
    formatted     BOOLEAN := (iFormatted = 1);
  BEGIN
    -- Assume that the document will fit in this 32k chunk
    exportFinished := 1;

    --
    -- This procedure returns the XML for the specified document.  Since the
    -- XML can be potentially large (greater than 32k) and since, for
    -- performance reasons, we do not want to return more than 32k at a time,
    -- this procedure may need to be called multiple times to retrieve the
    -- entire document.  As such, the "state" of the export is stored in
    -- package variables.
    --
    -- A non-null document indicates that the export process is just
    -- being started, so let's do the necessary initialization.
    --
    IF (docID IS NOT NULL) THEN
      chunk := addXMLHeader(docID);

      -- Initialize the state of the export
      mPackageLevel := 0;
      mPreviousDocID := -1;
      mPreviousComp := -1;
      mPreviousLevel := -1;
      mPreviousType := NULL;
      mPartialChunk := '';
      mIndex := -1;
      mFetchComplete := FALSE;
      
      -- Verify that the cursor is closed
      IF (c_package_contents%ISOPEN) THEN
        -- ###
        -- ### Not sure what to do here, as the cursor should never be open
        -- ### For now, we'll just close it and cross our fingers
        -- ###
        CLOSE c_package_contents;
      END IF;
      
      -- And open the cursor that will retrieve contents of the package
      OPEN c_package_contents(docID);

    ELSIF (mPartialChunk IS NULL) THEN
      -- We have finished exporting the document, just return NULL to 
      -- indicate that there is no more XML for this document
      RETURN (NULL);
    ELSE
      -- Get the leftovers (if any) from the previous call to this function
      chunk := mPartialChunk;
      mPartialChunk := '';
    END IF;

    newxml := NULL;
    IF (c_package_contents%ISOPEN) THEN
      <<get_documents_loop>>
      LOOP
        --
        -- Retrieve the next set of rows if we are currently not in the
        -- middle of processing a fetched set or rows.
        --
        IF (mIndex = -1) THEN
          -- #(2995144) Check if there are any more rows to fetch
          IF (mFetchComplete) THEN
            CLOSE c_package_contents;
            EXIT;
          END IF;

          -- Get the next set of rows
          FETCH c_package_contents BULK COLLECT 
          INTO mPathIds, mPathNames, mPathTypes, mPathSeqs, mPathOwners, 
               mCompSeqs, mCompElements, mCompLevels, mCompGroupings, 
               mCompIds, mCompRefs, mCompExtends, mCompUses,
               mAttNames, mAttValues
          LIMIT ROWS_TO_FETCH;

          -- Since we are only fetching records if either (1) this is the first
          -- fetch or (2) the previous fetch did not retrieve all of the 
          -- records, then at least one row should always be fetched.  But
          -- checking just to make sure.
          IF (c_package_contents%ROWCOUNT = 0) THEN
            CLOSE c_package_contents;
            EXIT;
          END IF;

          -- Check if all of the rows have been fetched.  If so, indicate that
          -- the fetch is complete so that another fetch is not made.
          IF (c_package_contents%NOTFOUND) THEN
            mFetchComplete := TRUE;
          END IF;

          mIndex := mPathIds.FIRST;
        END IF;

        <<get_documents_loop>>
        WHILE (mIndex <= mPathIds.COUNT) LOOP   
          IF (mPathIds(mIndex) = mPreviousDocID) THEN
            IF (mCompSeqs(mIndex) = mPreviousComp) THEN
              --
              -- If this is the same sequence of the previous row, then it's 
              -- only a new attribute, so just add the XML for the attribute
              --
              addAttribute(newxml, mAttNames(mIndex), mAttValues(mIndex));
            ELSE            
              --
              -- This is a different sequence from the previous row, which means 
              -- it's a different component, so add the XML for the new component
              --
              addComponent(newxml, 
                           mCompSeqs(mIndex), mCompElements(mIndex),
                           mCompLevels(mIndex), mCompGroupings(mIndex),
                           mCompIds(mIndex), mCompRefs(mIndex), 
                           mCompExtends(mIndex), mCompUses(mIndex),
                           mAttNames(mIndex), mAttValues(mIndex),
                           formatted);
            END IF;
          ELSE
            --
            -- This is a new document or package, which means we have to take 
            -- care of the following actions:
            --
            -- (1) Finish the previous document or package
            -- (2) Unwind the package stack if necessary
            -- (3) Reset the state for a new document
            --

            -- End the previous element
            IF (mPreviousType = 'DOCUMENT') THEN
              newxml := newxml || '/>' || NEWLINE;
            ELSIF (mPreviousType = 'PACKAGE') THEN
              newxml := newxml || '>' || NEWLINE;
            END IF;
          
            -- Unwind the document stack
            WHILE (mPreviousLevel > 0) LOOP
              IF (formatted) THEN
                newxml := newxml || 
                  rpad(' ', (mPackageLevel+mPreviousLevel-1)*INDENT_SIZE, ' ');
              END IF;
              newxml := newxml || '</' || mStack(mPreviousLevel) || '>' || NEWLINE;
              mPreviousLevel := mPreviousLevel - 1;
            END LOOP;

            -- Unwind the package stack
            IF (mPackageLevel > 0) THEN
              WHILE (mPathOwners(mIndex) <> mPackageStack(mPackageLevel)) LOOP
                IF (formatted) THEN
                  newxml := newxml || rpad(' ', (mPackageLevel-1)*INDENT_SIZE, ' ');
                END IF;
                newxml := newxml || '</package>' || NEWLINE;
                mPackageLevel := mPackageLevel - 1;
              END LOOP;
            END IF;

            -- Reset the state for this new document
            mPreviousDocID := mPathIds(mIndex);
            mPreviousComp := mCompSeqs(mIndex);
            mPreviousLevel := mCompLevels(mIndex);
            mPreviousType := mPathTypes(mIndex);
          
            IF (mPathTypes(mIndex) = 'DOCUMENT') THEN 
              -- If it's a document, add the first component
              addComponent(newxml, 
                           mCompSeqs(mIndex), mCompElements(mIndex),
                           mCompLevels(mIndex), mCompGroupings(mIndex),
                           mCompIds(mIndex), mCompRefs(mIndex), 
                           mCompExtends(mIndex), mCompUses(mIndex),
                           mAttNames(mIndex), mAttValues(mIndex),
                           formatted);
            ELSIF (mPathTypes(mIndex) = 'PACKAGE') THEN
              IF (mPathSeqs(mIndex) = 0) THEN
                --
                -- This is the first package of a package file.  As such, it
                -- does not have a packageName attribute.
                --
                newxml := newxml || '<' || mCompElements(mIndex);
              ELSE
                IF (formatted) THEN
                  newxml := newxml || rpad(' ', (mPackageLevel)*INDENT_SIZE, ' ');
                END IF;
                newxml := newxml || '<' || mCompElements(mIndex) || ' packageName="' || mPathNames(mIndex) || '"';            
              END IF;

              -- Add any attributes, although only the top-level package should
              -- have attributes.
              addAttribute(newxml, mAttNames(mIndex), mAttValues(mIndex));

              -- Add the package to the package stack
              mPackageLevel := mPackageLevel + 1;
              mPackageStack(mPackageLevel) := mPathIds(mIndex);
              mPackageNames(mPackageLevel) := mCompElements(mIndex);
            END IF;
          END IF;

          -- Increment the index to get the next row
          mIndex := mIndex + 1;
          
          -- Add the newxml to the chunk
          addXMLtoChunk(chunk, newxml);
          newxml := NULL;
          
        END LOOP add_documents_loop;

        -- We are not in the middle of processing a bulk fetch anymore
        mIndex := -1;

      END LOOP get_documents_loop;

      --
      -- We have finished exporting the document.  The only task that remains
      -- it to end the previous component and to unwind the document stack
      -- and package stack.
      --
      newxml := NULL;
      
      -- End the previous element
      IF (mPreviousType = 'DOCUMENT') THEN
        newxml := newxml || '/>' || NEWLINE;
      ELSIF (mPreviousType = 'PACKAGE') THEN
        newxml := newxml || '>' || NEWLINE;
      END IF;

      -- Unwind the document stack
      WHILE (mPreviousLevel > 0) LOOP
        IF (formatted) THEN
          newxml := newxml || 
            rpad(' ', (mPackageLevel+mPreviousLevel-1)*INDENT_SIZE, ' ');
        END IF;
        newxml := newxml || '</' || mStack(mPreviousLevel) || '>' || NEWLINE;
        mPreviousLevel := mPreviousLevel - 1;
      END LOOP;

      -- Unwind the package stack
      WHILE (mPackageLevel > 0) LOOP
        IF (formatted) THEN
           newxml := newxml || rpad(' ', (mPackageLevel-1)*INDENT_SIZE, ' ');
        END IF;
        newxml := newxml || '</' || mPackageNames(mPackageLevel) || '>' || NEWLINE;
        mPackageLevel := mPackageLevel - 1;
      END LOOP;
      addXMLtoChunk(chunk, newxml);
    END IF;
    
    --
    -- Return the current chunk, and set the mPartialChunk to NULL so that, 
    -- when entering this function again, we will know that we have finished
    -- processing the document.
    --
    mPartialChunk := NULL;
    RETURN (chunk);
    
  EXCEPTION
    WHEN chunk_size_exceeded THEN
      exportFinished := 0;
      mPartialChunk := newxml;
      RETURN (chunk);
  END;


  --
  -- This method has been deprecated.  Please use the function which
  -- has a return value which indicates whether or not the export is
  -- complete.
  --
  -- Export the XML for a document and pass it back in 32k chunks.  This
  -- function will return XML chunks, with a maximum size of 32k.  When
  -- the entire document has been exported, this function will return NULL.
  --
  -- Specifying a document name will initiate the export.  Thereafter, a NULL
  -- document name should be passed in until the export is complete.
  -- That is, to export an entire document, you should do:
  --
  -- firstChunk := jdr_mds_internal.exportDocumentAsXML('/oracle/apps/fnd/mydoc');
  -- LOOP
  --   nextChunk := jdr_mds_internal.exportDocumentAsXML(NULL);
  --   EXIT WHEN nextChunk IS NULL;
  -- END LOOP;
  --
  -- Parameters:
  --   fullName  - the fully qualifued name of the document.  however,
  --               after the first chunk of text is exported, a NULL value
  --               should be passed in.
  --
  --   formatted- a non-zero value indicates that the XML is formatted nicely
  --               (i.e. whether or not the elements are indented)
  --              
  --   allowChildDoc - a non-zero value indicates that "child" documents
  --                   can be exported, where child documents are documents
  --                   which exist as part of a package document
  --
  --   includePackage - a non-zero value indicates that, if this is a "child"
  --                    document and it allowChildDoc is TRUE, then the entire
  --                    package document should be exported; otherwise, only
  --                    the XML for the child document will be exported.
  --
  -- Returns:
  --   The exported XML, in 32k chunks.
  --
  FUNCTION exportDocumentAsXML(
    fullName           VARCHAR2,
    formatted          INTEGER DEFAULT 1,
    allowChildDoc      INTEGER DEFAULT 0,
    includePackage     INTEGER DEFAULT 0) RETURN VARCHAR2
  IS
    exportFinished     INTEGER;
  BEGIN
    return (exportDocumentAsXML(exportFinished, 
                                fullName,
                                formatted,
                                includePackage));
  END;
  

  --
  -- Export the XML for a document and pass it back in 32k chunks.  This
  -- function will return XML chunks, with a maximum size of 32k.  
  --
  -- Specifying a document name will initiate the export.  Thereafter, a NULL
  -- document name should be passed in until the export is complete.
  -- That is, to export an entire document, you should do:
  --
  -- firstChunk := jdr_mds_internal.exportDocumentAsXML(isDone,
  --                                                    '/oracle/apps/fnd/mydoc');
  -- WHILE (isDone = 0)
  --   nextChunk := jdr_mds_internal.exportDocumentAsXML(isDone, NULL);
  -- END LOOP;
  --
  -- Parameters:
  --   exportFinished - OUT parameter which indicates whether or not the export
  --                    is complete.  1 indicates the entire document is
  --                    exported, 0 indicates that there are more chunks
  --                    remaining.
  --
  --   fullName  - the fully qualifued name of the document.  however,
  --               after the first chunk of text is exported, a NULL value
  --               should be passed in.
  --
  --   formatted - a non-zero value indicates that the XML is formatted nicely
  --               (i.e. whether or not the elements are indented)
  --              
  --   allowChildDoc - a non-zero value indicates that "child" documents
  --                   can be exported, where child documents are documents
  --                   which exist as part of a package document
  --
  --   includePackage - a non-zero value indicates that, if this is a "child"
  --                    document and it allowChildDoc is TRUE, then the entire
  --                    package document should be exported; otherwise, only
  --                    the XML for the child document will be exported.
  --
  -- Returns:
  --   The exported XML, in 32k chunks.
  --  
  FUNCTION exportDocumentAsXML(
    exportFinished OUT INTEGER,
    fullName           VARCHAR2,
    formatted          INTEGER DEFAULT 1,
    allowChildDoc      INTEGER DEFAULT 0,
    includePackage     INTEGER DEFAULT 0) RETURN VARCHAR2
  IS
    docID          jdr_paths.path_docid%TYPE;  
  BEGIN
    --
    -- A non-null fullName indicates that this is the first time this function
    -- is being called for this document.  If so, we need to find the 
    -- document ID and start the export process.
    --
    IF (fullName IS NOT NULL) THEN
      mFormatted := formatted;
      
      docID := getDocumentID(fullName, allowChildDoc = 1, includePackage = 1);
      IF (docID = -1) THEN
        -- Unable to find the document
        -- ###
        -- ### Give error if unable to locate document
        -- ###
        RETURN (NULL);
      END IF;

      -- Determine if we're exporting a document or a package.
      --
      -- #(2417655) Save the path type in a package variable, so if/when we
      -- re-enter this procedure, we will know whether we are exporting
      -- a package or a document.
      SELECT path_type INTO mPathType FROM jdr_paths WHERE path_docid = docid;
      IF (mPathType = 'PACKAGE') THEN
        RETURN (exportPackageDocument(docID, mFormatted, exportFinished));
      ELSE
        RETURN (exportSingleDocument(docID, mFormatted, exportFinished));
      END IF;
    ELSE      
      IF (mPathType = 'PACKAGE') THEN
        RETURN (exportPackageDocument(null, mFormatted, exportFinished));
      ELSE
        RETURN (exportSingleDocument(null, mFormatted, exportFinished));
      END IF;
    END IF;
  END;


  --
  -- Export the translations in XLIFF format.  The document will be
  -- exported in 32k chunks.
  --
  FUNCTION exportXLIFFDocument(
    exportFinished  OUT INTEGER,
    document            VARCHAR2,
    language            VARCHAR2) RETURN VARCHAR2
  IS
    r_trans      c_trans%ROWTYPE;
    docID        jdr_paths.path_docid%TYPE;
    chunk        VARCHAR2(32000);
    newxml       VARCHAR2(32000);
    baseLanguage jdr_attributes.att_value%TYPE;
    compref      jdr_attributes_trans.atl_comp_ref%TYPE;
    source       jdr_attributes.att_value%TYPE;
    dotpos       INTEGER;
  BEGIN
      -- Assume that the document will fit in this 32k chunk
    exportFinished := 1;

    IF (document IS NOT NULL) THEN
      docID := getDocumentID(document, TRUE, FALSE);
      IF (docID = -1) THEN
        RETURN (NULL);
      END IF;

      -- Retrieve the base language.  This is the same query which is 
      -- executed in DBAccess.getBaseDevelopmentLanguage
      BEGIN
        SELECT att_value INTO baseLanguage FROM jdr_attributes
        WHERE att_comp_docid = docID AND
              att_name = 'xml:lang' AND  
              att_comp_seq = 0;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          baseLanguage := 'Unknown';
      END;

      -- Create the XLIFF document
      chunk := '<?xml version = ''1.0'' encoding = ''UTF-8''?>' || NEWLINE ||
               '<!--DBDRV: -->' || NEWLINE ||
               '<xliff version="1.0">' || NEWLINE ||
               lpad(' ', INDENT_SIZE) ||  '<file datatype="jdr" original="' ||
               substr(document, instr(document, '/', -1) + 1) ||
               '" source-language="' || baseLanguage || 
               '" target-language="' || language || '">' || NEWLINE ||
               lpad(' ', INDENT_SIZE*2) || '<body>' || NEWLINE;

      OPEN c_trans(docID, language);
    ELSE
      chunk := mPartialXLIFFChunk;
    END IF;

    LOOP
      -- Get each tranlsation
      FETCH c_trans INTO r_trans;
      IF (c_trans%NOTFOUND) THEN
        CLOSE c_trans;
        EXIT;
      END IF;

      -- component ref which equals "." indicates a top-level component
      IF (r_trans.atl_comp_ref = '.') THEN
        compref := jdr_mds_internal.getDocumentName(r_trans.atl_comp_docid);
      ELSIF (INSTR(r_trans.atl_comp_ref, ':') <> 1) THEN
        compref := jdr_mds_internal.getDocumentName(r_trans.atl_comp_docid) ||
                   '..' || r_trans.atl_comp_ref;
      ELSE
        -- #(3260414) Views need to be handled specially.  If the component
        -- reference is something like: :reg.region2, then the reference 
        -- should be: docname:reg..region2...id, not docname..:reg.region2...id
        dotpos := INSTR(r_trans.atl_comp_ref, '.');
        compref := jdr_mds_internal.getDocumentName(r_trans.atl_comp_docid); 
        IF (dotpos > 0) THEN
          compref := compref ||
                     SUBSTR(r_trans.atl_comp_ref, 1, dotpos - 1) || '..' || 
                     SUBSTR(r_trans.atl_comp_ref, dotpos + 1);  
        ELSE
          compref := compref || r_trans.atl_comp_ref;
        END IF;
      END IF;

      -- convert the /'s to .'s for XLIFF format
      compref := translate(compref, '/', '.');

      -- #(3477218) We need to be able to get the source for customization
      -- views.  Since this is more complicated non customization views, we
      -- are going to special case customization views.
      DECLARE
        viewID      VARCHAR2(255);
        viewCompRef VARCHAR2(255);
        startSeq    jdr_components.comp_seq%TYPE;
        endSeq      jdr_components.comp_seq%TYPE;
        startLevel  jdr_components.comp_level%TYPE;
      BEGIN      
        IF (INSTR(r_trans.atl_comp_ref, ':') <> 1) THEN
          -- This is not a translation for a customization view.
          --
          -- #(3258371) Get the source for customization documents as well.
          SELECT 
           source.att_value INTO source 
          FROM 
            jdr_components, jdr_attributes source, jdr_attributes custs 
          WHERE 
            source.att_comp_docid = r_trans.atl_comp_docid AND 
            comp_docid = r_trans.atl_comp_docid AND          
            custs.att_comp_docid = r_trans.atl_comp_docid AND 
            source.att_name = r_trans.atl_name AND 
            comp_seq = source.att_comp_seq AND 
            comp_seq = custs.att_comp_seq AND 
            (    
              ( 
                custs.att_name = r_trans.atl_name AND 
                ( 
                  comp_id = r_trans.atl_comp_ref OR 
                  (comp_seq=0 AND r_trans.atl_comp_ref='.') 
                ) 
              ) 
              OR 
              ( 
                custs.att_name IN ('element') AND 
                custs.att_value = r_trans.atl_comp_ref AND 
                comp_element IN ('view', 'modify', 'move', 'insert') 
              ) 
            );
        ELSE
          -- This is a translation for a customization view.  As such,
          -- we need to restrict the query to components contained within
          -- the customization view.  
          IF (dotpos = 0) THEN
            viewID := SUBSTR(r_trans.atl_comp_ref, 2);
            viewCompRef := NULL;
          ELSE
            viewID := SUBSTR(r_trans.atl_comp_ref, 2, dotpos - 2);          
            viewCompRef := SUBSTR(r_trans.atl_comp_ref, dotpos + 1);
          END IF;

          -- Get the starting sequence of the customization view
          SELECT comp_seq, comp_level INTO startSeq, startLevel
          FROM jdr_components
          WHERE comp_docid =  r_trans.atl_comp_docid AND
                comp_element = 'view' AND
                comp_id = viewID;

          -- and the ending sequence
          SELECT MAX(comp_seq) - 1 INTO endSeq
          FROM jdr_components
          WHERE comp_docid = r_trans.atl_comp_docid AND
                comp_seq > startSeq AND
                comp_level <= startLevel; 

          SELECT 
            DISTINCT source.att_value INTO source 
          FROM 
            jdr_components, jdr_attributes source, jdr_attributes custs 
          WHERE 
            source.att_comp_docid = r_trans.atl_comp_docid AND 
            comp_docid = r_trans.atl_comp_docid AND          
            custs.att_comp_docid = r_trans.atl_comp_docid AND 
            source.att_name = r_trans.atl_name AND 
            comp_seq = source.att_comp_seq AND 
            comp_seq = custs.att_comp_seq AND 
            comp_seq >= startSeq AND
            (comp_seq <= endSeq OR endSeq IS NULL) AND
            comp_element IN ('view', 'modify', 'move', 'insert') AND
            --
            -- Either the viewCompRef is not null, indicating that the reference
            -- is not a top level component, in which case there must be
            -- an element attribute matching the component reference; or the 
            -- viewCompRef is null, indicating the reference is a top level
            -- component, in which case there must not be an element attribute.
            --
            (
              (
                viewCompRef IS NOT NULL AND
                custs.att_name IN ('element') AND 
                custs.att_value = viewCompRef
              ) OR
              (
                viewCompRef IS NULL AND
                comp_element IN ('view', 'modify') AND 
                NOT EXISTS (SELECT att_name FROM jdr_attributes 
                            WHERE  att_comp_docid = r_trans.atl_comp_docid AND
                                   att_comp_seq = comp_seq AND
                                   att_name = 'element')
              )
            );
        END IF;
      EXCEPTION
        -- Set source to NULL it this is a dangling translation
        WHEN no_data_found THEN
          source := NULL;
      END; 
      
      -- add the translation
      newxml := lpad(' ', INDENT_SIZE*3) || 
                '<trans-unit id="' ||
                compref || '...' || r_trans.atl_name || '" ' ||
                'translate="yes">'  || NEWLINE ||
                lpad(' ', INDENT_SIZE*4) || '<source>' ||
                source || '</source>' || NEWLINE ||
                lpad(' ', INDENT_SIZE*4) || '<target>' ||
                r_trans.atl_value || '</target>' || NEWLINE ||
                lpad(' ', INDENT_SIZE*3) || '</trans-unit>' || NEWLINE;

      addXMLtoChunk(chunk, newxml);
    END LOOP;

    -- We are done, just need to add the closing tags
    newxml := lpad(' ', INDENT_SIZE*2) || '</body>' || NEWLINE ||
              lpad(' ', INDENT_SIZE) || '</file>' || NEWLINE ||
              '</xliff>' || NEWLINE;
    addXMLtoChunk(chunk, newxml);

    mPartialXLIFFChunk := NULL;
    RETURN (chunk);

  EXCEPTION
    WHEN chunk_size_exceeded THEN
      exportFinished := 0;
      mPartialXLIFFChunk := newxml;
      RETURN (chunk);
  END;

  
  --
  -- Retrieves the document id for the specified fully qualified path name.
  -- The pathname must begin with a '/' and should look something like:
  --   /oracle/apps/AK/mydocument
  --
  -- Parameters:
  --   fullPathName  - the fully qualified name of the document
  --   pathType      - the type of the document, either 'DOCUMENT' or 'PACKAGE'
  --                   if no type is specified, and there happens to be a path
  --                   of both 'DOCUMENT' and 'PACKAGE' (which is unlikely), 
  --                   then the id of the DOCUMENT will be returned
  --
  -- Returns:
  --   Returns the ID of the path or -1 if no such path exists
  --   
  FUNCTION getDocumentID(
    fullPathName VARCHAR2,
    pathType     VARCHAR2 DEFAULT NULL) RETURN NUMBER
  IS
    fullPath      VARCHAR2(512);
    cacheName     VARCHAR2(64);
    pathLevel     INTEGER;
    endIdx        INTEGER := -1;
    pathNames     pathnametab := pathnametab();
    docID         JDR_PATHS.PATH_DOCID%TYPE := -1;
    ownerID       JDR_PATHS.PATH_OWNER_DOCID%TYPE := 0;
    pType         JDR_PATHS.PATH_TYPE%TYPE;
    cachePackage  BOOLEAN := TRUE;
  BEGIN
    -- #(3234805) If the document does not start with a forward slash,
    -- then it's an invalid document name
    IF (INSTR(fullPathName, '/') <> 1) THEN
      RETURN (-1);
    END IF;

    -- Check if this is the root package
    IF ((fullPathName = '/') AND ((pathType IS NULL) OR (pathType = 'PACKAGE'))) THEN
      RETURN (0);
    END IF;

    -- #(3403125) Remove the trailing and first slash
    fullPath := substr(fullPathName, instr(fullPathName, '/') + 1);
    IF (INSTR(fullPath, '/', LENGTH(fullPath)) > 0)  THEN
      fullPath := SUBSTR(fullPath, 1, LENGTH(fullPath) - 1);
    END IF;

    -- Break up the document name into the individual packages
    WHILE (endIdx <> 0) LOOP
      endIdx := INSTR(fullPath, '/');
      pathNames.extend;
      IF endIdx = 0 THEN
        -- This is the leaf path name
        pathNames(pathNames.COUNT) := fullPath;
      ELSE
        -- Get the next package and remove it from the full path name
        pathNames(pathNames.COUNT)   := substr(fullPath, 1, endIdx - 1);
        fullPath := substr(fullPath, endIdx + 1);
      END IF;
    END LOOP;

    -- #(3803543) Check if there is a name in the cache.  We do this to
    -- reduce the amount of SQL.  This is specific to apps and the only 
    -- packages which are cached are:
    --   /oracle/apps/xxx and
    --   /oracle/apps/xxx/customizations
    -- For /oracle/apps/xxx, the key is 'xxx'.
    -- For /oracle/apps/xxx/customizations, the key is '/xxx'.
    -- bug #(4137848) Lookup cache only if path atleast 3 levels
    -- to Avoid Subscript beyond count error
    IF (pathNames.COUNT > 2) THEN
      -- If the path does not begin with /oracle/apps, then no need to check
      -- the cache.
      IF (pathNames(1) = 'oracle' and pathNames(2) = 'apps') THEN
        IF (pathNames.COUNT > 3) AND (pathNames(4) = 'customizations') THEN
          -- If this path is in the cache, then we no we will be able to skip 
          -- the /oracle/apps/xxx/customizations.  As such, we set the path
          -- level to 5, which is the level after customizations.
          pathLevel := 5;
          cacheName := '/'||pathNames(3);
        ELSE
          -- If this path is in the cache, then we no we will be able to skip 
          -- the /oracle/apps/xxx.  As such, we set the path level to 4, which 
          -- is the level after 'xxx'.
          pathLevel := 4;
          cacheName := pathNames(3);
        END IF;
         
        -- Now that we know the key, search the cache
        docID := mPackageCache.FIRST;
        WHILE docID IS NOT NULL LOOP
          IF (cacheName = mPackageCache(docID)) THEN
            cachePackage := FALSE;
            ownerID := docID;
            docID := NULL;
          ELSE
            docID := mPackageCache.NEXT(docID);  
          END IF;
        END LOOP;
      END IF;
    END IF;

    -- ownerID will be non-zero if part of the document is in the cache
    IF (ownerID = 0) THEN
      -- Since the document was not in the cache, we have to go through each
      -- of the packages
      pathLevel := 1;
    ELSIF (pathLevel > pathNames.COUNT) THEN
      RETURN (ownerID);
    END IF;

    -- Loop through the remaining packages, getting the child package, until
    -- we are at the leaf package
    LOOP
      SELECT path_docid, path_type
      INTO docID, pType
      FROM jdr_paths
      WHERE path_name = pathNames(pathLevel) AND path_owner_docid = ownerID;

      -- Check to see if the package should be cached
      IF (cachePackage) THEN
        IF (pathLevel = 1) THEN
          -- We only cache names beginning with /oracle/apps, so if the first
          -- name is not 'oracle', we should not cache the name
          IF (pathNames(1) <> 'oracle') THEN
            cachePackage := FALSE;
          END IF;
        ELSIF (pathLevel = 2) THEN
          -- We only cache names beginning with /oracle/apps, so if the second
          -- name is not 'apps', we should not cache the name        
          IF (pathNames(2) <> 'apps') THEN
            cachePackage := FALSE;
          END IF;
        ELSIF (pathLevel = 3) THEN
          -- Since the first two packages are /oracle/apps and since this is
          -- the third package, we should cache this value.
          mPackageCache(docID) := pathNames(3);
        ELSIF (pathLevel = 4) THEN
          -- We only cache names beginning with /oracle/apps/xxx/customizations, 
          -- so if the 4th name is not 'customizations', we should not cache 
          -- the name                
          IF (pathNames(4) = 'customizations') THEN
            -- This is a package of the form, /oracle/apps/xxx/customizations, 
            -- so cache this as '/xxx'
            mPackageCache(docID) := '/'||pathNames(3);          
          END IF;
          cachePackage := FALSE;
        ELSE
          -- We do not cache any packages more than 5 levels deep
          cachePackage := FALSE;
        END IF;
      END IF;

      -- Check if this is the leaf package
      IF (pathLevel = pathNames.COUNT) THEN
        IF (pathType IS NULL) OR (pathType = pType) THEN
          RETURN (docID);
        ELSE
          RETURN (-1);
        END IF;
      END IF;
      
      -- Get ready for the next package  
      ownerID := docID;
      pathLevel := pathLevel + 1;
    END LOOP;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN (-1);
  END;


  --
  -- Retrieves the document id for the specified attributes.  This is
  -- typically used when attempting to find the id of a path which is
  -- owned by a package document.
  --
  -- Note that this will return the docID which matches the specified 
  -- name, ownerID and docType (not pathSeq).  For the pathSeq, it will 
  -- update the database path_seq to the value specified in pathSeq.
  --
  -- Parameters:
  --   name          - the name of the document (not fully qualified)
  --   ownerID       - the ID of the owning package
  --   pathSeq       - the path sequence
  --   docType       - either 'DOCUMENT' or 'PACKAGE'
  --
  -- Returns:
  --   Returns the ID of the path or -1 if no such path exists
  --
  FUNCTION getDocumentID(
    name       VARCHAR2,
    ownerID    JDR_PATHS.PATH_OWNER_DOCID%TYPE,
    pathSeq    JDR_PATHS.PATH_SEQ%TYPE,
    docType    JDR_PATHS.PATH_TYPE%TYPE) RETURN NUMBER
  IS
    docid JDR_PATHS.PATH_OWNER_DOCID%TYPE;
    seq   JDR_PATHS.PATH_SEQ%TYPE;
  BEGIN
    -- Find the docid for the specified attributes
    SELECT  path_docid, path_seq INTO docid, seq
    FROM jdr_paths
    WHERE 
      path_name = name AND
      path_owner_docid = ownerID AND
      path_type = docType;

    -- If the sequence differs, then update it to the specified sequence
    IF (seq <> pathSeq) THEN      
      UPDATE jdr_paths SET path_seq = pathSeq
      WHERE
        path_docid = docid;
    END IF;

    RETURN (docid);

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN (-1);
  END;


  --
  -- For each document name, retrieve the corresponding document ID. 
  -- The document ID for docs[i] is in docIDs[i].  If no documentID
  -- exists for a docs[i], then docIDs[i] = -1.
  --
  PROCEDURE getDocumentIDs(docs   IN  jdr_stringArray,
                           docIDs OUT jdr_numArray)
  IS
    i NUMBER;
    ids jdr_numArray := jdr_numArray(null);
  BEGIN
    FOR i IN 1..docs.COUNT LOOP
      IF (i <> 1)
      THEN  
        ids.extend;
      END IF;
      ids(ids.COUNT) := getDocumentID(docs(i), 'DOCUMENT');
    END LOOP;
    docIDs := ids;
  END;              


  --
  -- Given the document id, find the fully qualified document name
  --
  -- Parameters:
  --   docID   - the ID of the document
  --
  -- Returns:
  --   the fully qualified document name
  --
  FUNCTION getDocumentName(
    docid NUMBER) RETURN VARCHAR2
  IS
    pathNames pathnametab;
    name      VARCHAR2(512) := '';
    i         INTEGER;
  BEGIN
    SELECT path_name BULK COLLECT INTO pathNames
    FROM jdr_paths
    START WITH path_docid = docid
    CONNECT BY PRIOR path_owner_docid = path_docid
    ORDER BY LEVEL DESC;

    FOR i IN 1..pathNames.COUNT LOOP
      name := name || '/' || pathNames(i);
    END LOOP;

    RETURN (name);
  END;


  --
  -- Given the document id of a child document, find the id for the
  -- owning package document.
  --
  -- Parameters:
  --   docID  - the ID of the child document
  --
  -- Returns:
  --   Returns the ID of the package document or -1 if not found
  --
  FUNCTION getPackageDocument(
    docID NUMBER) RETURN NUMBER
  IS
    pathSeq   jdr_paths.path_seq%TYPE := 0;
    ownerID   jdr_paths.path_owner_docid%TYPE;
    newDocid  jdr_paths.path_docid%TYPE := docID;    
  BEGIN
    LOOP
      -- Retrieve the parent of the previous document
      SELECT path_owner_docid, path_seq
      INTO ownerID, pathSeq
      FROM jdr_paths
      WHERE path_docid = newDocID;
      EXIT WHEN pathSeq <= 0;
      newDocID := ownerID;
    END LOOP;

    -- Makse sure that we have retrieved a package document
    IF (pathSeq = 0) THEN
      RETURN (newDocID);
    ELSE
      RETURN (-1);
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN (-1);
  END;
  

  --
  -- Gets the minimun version of JRAD with which the repository API is
  -- compatible.  That is, the actual JRAD version must be >= to the
  -- minimum version of JRAD in order for the repositroy API and java code to
  -- be compatible.
  --
  -- Returns:
  --   Returns the mimumum version of JRAD
  --   
  FUNCTION getMinJRADVersion RETURN VARCHAR2
  IS
  BEGIN
    RETURN (MIN_JRAD_VERSION);
  END;



  --
  -- Gets the version of the repository API.  This API version must >= to the 
  -- java constant CompatibleVersions.MIN_REPOS_VERSION.
  --
  -- Returns:
  --   Returns the version of the repository
  --   
  FUNCTION getRepositoryVersion RETURN VARCHAR2
  IS
  BEGIN
    RETURN (REPOS_VERSION);
  END;

  -- 
  -- Lock the document, given a valid docID.  Before updating/saving a document, 
  -- it needs to be locked to ensure that it is not updated simultaneously by  
  -- multipleusers.  If the document is already locked, we will continue to 
  -- attempt to lock the document for a user-specified number of seconds, or 
  -- MAX_SECONDS_TO_WAIT_FOR_LOCK by default, before giving up.   
  -- If, after that time, we have still not locked the document, a 
  -- "RESOURCE_BUSY" exception will be raised.
  --
  -- Parameters:
  --   docID   - ID of the document to lock
  --   attempts      - number of seconds to wait for a lock
  --
  PROCEDURE lockDocument(
    docID          JDR_PATHS.PATH_DOCID%TYPE,
    attempts       INTEGER DEFAULT MAX_SECONDS_TO_WAIT_FOR_LOCK
    )
  IS
    tmpdocID      JDR_PATHS.PATH_DOCID%TYPE;
    cont          BOOLEAN := TRUE;
    num_attempts  INTEGER := attempts;
    RESOURCE_BUSY EXCEPTION; 
    PRAGMA EXCEPTION_INIT(RESOURCE_BUSY, -54); 
  BEGIN
    WHILE (cont) LOOP	
      BEGIN
        SELECT path_docid INTO tmpdocID
        FROM jdr_paths
        WHERE path_docid = docID
        FOR UPDATE NOWAIT;

        cont := false;
      EXCEPTION
        WHEN RESOURCE_BUSY THEN
          num_attempts := num_attempts - 1;
          IF (num_attempts <= 0) THEN
            RAISE;
          END IF;
          SYS.DBMS_LOCK.SLEEP(1);
      END;
    END LOOP;
  END;    


  -- 
  -- Performs all steps that are necessary before a top-levle document is 
  -- saved/updated which includes:
  -- (1) If the document already exists, updates the "who" columns in
  --     JDR_PATHS and deletes the contents of the document
  -- (2) If the document does not exist yet, creates a new entry in the 
  --     JDR_PATHS table
  --
  -- Parameters:
  --   username     - user who is updating/inserting the document
  --   fullPathName - fully qualified name of the document/package file
  --   pathType     - 'DOCUMENT' for single document or 'PACKAGE' for package
  --                  file
  --   xmlversion   - xml version 
  --   xmlencoding  - xml encoding

  --
  -- Returns:
  --   Returns the ID of the document or -1 if an error occurred
  -- 
  FUNCTION prepareDocumentForInsert(
    username     VARCHAR2,
    fullPathName VARCHAR2,
    pathType     VARCHAR2,
    xmlversion   VARCHAR2,
    xmlencoding  VARCHAR2) RETURN NUMBER
  IS
    docID   jdr_paths.path_docid%TYPE;   
    pathSeq jdr_paths.path_seq%TYPE; 
  BEGIN

    -- Check if the document already exists
    docID := getDocumentID(fullPathName, pathType);

    IF (docID = -1) THEN
      BEGIN
        -- Document does not exist yet, so create it now
        docID := createPath(username, 
                            fullPathName, 
                            pathType, 
                            xmlversion, 
                            xmlencoding);
      EXCEPTION
        -- #(2669626) If the sequence, JDR_DOCUMENT_ID_S, is corrupt (which can
        -- happen if it gets reset), then createPath will raise a NO_DATA_FOUND
        -- exception.  
        WHEN corrupt_sequence THEN
          raise_application_error(ERROR_CORRUPT_SEQUENCE, NULL);
          
        -- #(2456503) If we were unable to create the path, it is likely due
        -- to an already existing document or package
        WHEN document_name_conflict THEN
          IF (pathType = 'DOCUMENT') THEN
            raise_application_error(ERROR_DOCUMENT_NAME_CONFLICT, NULL);
          ELSE
            raise_application_error(ERROR_PACKAGE_NAME_CONFLICT, NULL);              
          END IF;
      END;
    ELSE
      -- #(2456503) Make sure that the document/package file does not already
      -- conflict with a document/package which already exists.
      SELECT path_seq INTO pathSeq FROM jdr_paths WHERE path_docid = docID;

      -- If attempting to save a document, then the path which we retrieved 
      -- must be a top-level document (i.e. pathSeq  = -1).  If pathSeq > 0,
      -- this means that there is already a document of the same name inside a 
      -- package file; and if pathSeq = 0, this means that a package file of
      -- the same name already exists in the repository.
      IF ((pathType = 'DOCUMENT') AND (pathSeq <> -1)) THEN
        raise_application_error(ERROR_DOCUMENT_NAME_CONFLICT, NULL);
      END IF;

      -- If attempting to save a package file, then the path which we retrieved
      -- must be a package file.  If pathSeq = -1, then this means there is
      -- already a package (not a package file) of the same name; and
      -- if pathSeq > 0, this means there is already a package in a package file
      -- of the same name.
      IF ((pathType = 'PACKAGE') AND (pathSeq <> 0)) THEN
        raise_application_error(ERROR_PACKAGE_NAME_CONFLICT, NULL);        
      END IF;

      -- Lock the document
      lockDocument(docID);
      
      -- Document already exists, so update the "who" columns
      UPDATE jdr_paths 
      SET path_xml_version = xmlversion,
          path_xml_encoding = xmlencoding,
          last_updated_by = username, 
          last_update_date = SYSDATE, 
          last_update_login = username
      WHERE path_docid = docID;

      -- And delete the "old" contents of the document
      deleteDocument(docID, FALSE);
    END IF;

    RETURN (docID);
  END;


  -- 
  -- Performs all steps that are necessary before a package document is 
  -- saved/updated which includes:
  -- (1) If the document already exists, updates the "who" columns in
  --     JDR_PATHS
  -- (2) If the document does not exist yet, creates a new entry in the 
  --     JDR_PATHS table
  --
  -- Parameters:
  --   username     - user who is updating/inserting the document
  --   pathname     - name of the document/package
  --   ownerID      - ID of the owning package
  --   pathSeq      - path sequence
  --   pathType     - 'DOCUMENT' or 'PACKAGE'
  --
  -- Returns:
  --   Returns the ID of the document or -1 if an error occurred
  -- 
  FUNCTION prepareDocumentForInsert(
    username   VARCHAR2,
    pathname   VARCHAR2,
    ownerID    JDR_PATHS.PATH_OWNER_DOCID%TYPE,
    pathSeq    JDR_PATHS.PATH_SEQ%TYPE,
    pathType   JDR_PATHS.PATH_TYPE%TYPE) RETURN NUMBER
  IS
    docID  jdr_paths.path_docid%TYPE;    
  BEGIN

    -- Check if the document already exists
    docID := getDocumentID(pathname, ownerID, pathSeq, pathType);

    IF (docID = -1) THEN
      -- Document does not exist yet, so create it now
      docID := createPath(username, pathname, ownerID, pathSeq, pathType);
    ELSE
      -- Document already exists, so update the "who" columns    
      UPDATE jdr_paths 
      SET last_updated_by = username, 
          last_update_date = SYSDATE,
          last_update_login = username
      WHERE path_docid = docID;
    END IF;

    RETURN (docID);
  EXCEPTION
    WHEN corrupt_sequence THEN
      raise_application_error(ERROR_CORRUPT_SEQUENCE, NULL);
          
    WHEN document_name_conflict THEN
      raise_application_error(ERROR_PACKAGE_NAME_CONFLICT, NULL);              
  END;


  FUNCTION refactor(
    p_oldName      VARCHAR2,
    p_newName      VARCHAR2,
    p_translations INTEGER DEFAULT 1) RETURN INTEGER
  IS
    -- For each customized document which customizes the specified base 
    -- document, retrieves the attributes for the specified component ID.
    CURSOR c_attributes(fullName VARCHAR2, baseName VARCHAR2, compID VARCHAR2) IS
      SELECT att_comp_docid,
             att_comp_seq,
             att_seq,
             att_name
      FROM (SELECT path_docid
            FROM jdr_attributes, jdr_paths
            WHERE path_docid = att_comp_docid AND
                  path_name = baseName AND
                  att_comp_seq = 0 AND
                  att_name = 'customizes' AND
                  att_value = fullName) docids,
           jdr_attributes, jdr_components
      WHERE att_comp_docid = docids.path_docid AND
            att_comp_docid = comp_docid AND
            att_comp_seq = comp_seq AND
            att_name IN ('element', 'before', 'after', 'parent') AND
            att_value = compID AND
            comp_element IN ('view', 'modify', 'move', 'insert', 'criterion');

    -- For each customized document which customizes the specified base 
    -- document, retrieves the translations for the specified component ID.
    CURSOR c_translations(fullName VARCHAR2, baseName VARCHAR2, compID VARCHAR2) IS
      SELECT atl_comp_docid,
             atl_comp_ref
      FROM (SELECT path_docid
            FROM jdr_attributes, jdr_paths
            WHERE path_docid = att_comp_docid AND
                  path_name = baseName AND
                  att_comp_seq = 0 AND
                  att_name = 'customizes' AND
                  att_value = fullName) docids,
           jdr_attributes_trans
      WHERE atl_comp_docid = docids.path_docid AND
            (atl_comp_ref = compID OR atl_comp_ref like ':%.'||compID);

    -- Retrieve all of the customization documents which customize the 
    -- specified base document.
    CURSOR c_documents(fullName VARCHAR2, baseName VARCHAR2) IS
      SELECT path_docid, created_by, jdr_mds_internal.getDocumentName(path_docid)
      FROM jdr_attributes, jdr_paths
      WHERE path_docid = att_comp_docid AND
            path_name = baseName AND
            att_comp_seq = 0 AND
            att_name = 'customizes' AND
            att_value = fullName;

    oldDocName     VARCHAR2(512);
    newDocName     VARCHAR2(512);
    oldCustDocName VARCHAR2(512);
    newCustDocName VARCHAR2(512);
    oldBaseName    jdr_paths.path_name%TYPE;
    newBaseName    jdr_paths.path_name%TYPE;
    oldCompName    jdr_components.comp_id%TYPE;
    newCompName    jdr_components.comp_id%TYPE;
    docID          jdr_paths.path_docid%TYPE;
    ownerID        jdr_paths.path_docid%TYPE;
    attCompSeq     jdr_attributes.att_comp_seq%TYPE;
    attSeq         jdr_attributes.att_seq%TYPE;
    attName        jdr_attributes.att_name%TYPE;
    oldCompRef     jdr_attributes_trans.atl_comp_ref%TYPE;
    newCompRef     jdr_attributes_trans.atl_comp_ref%TYPE;
    username       jdr_paths.created_by%TYPE;
    oldPeriodPos   INTEGER;
    newPeriodPos   INTEGER;
    slashPos       INTEGER;
    custPos        INTEGER;
    pos1           INTEGER;
    pos2           INTEGER;
    changesMade    INTEGER := 0;
  BEGIN
    -- Perform some simple check on the document name
    IF ( (INSTR(p_oldName, '/') <> 1) OR (INSTR(p_newName, '/') <> 1) ) THEN
      raise_application_error(ERROR_INVALID_NAME, NULL);
    END IF;

    -- If the names contain a ".", it means that we are refactoring
    -- a component.  Otherwise, we are refactoring a document
    oldPeriodPos := INSTR(p_oldName, '.');
    newPeriodPos := INSTR(p_newName, '.');

    -- Make sure we are not trying to map a component to a document or
    -- vice versa
    IF ( ((oldPeriodPos = 0) AND (newPeriodPos > 0)) OR
         ((oldPeriodPos > 0) AND (newPeriodPos = 0)) ) THEN
      raise_application_error(ERROR_INCONSISTENT_MAPPING, NULL);
    END IF;
    
    IF (oldPeriodPos > 0) THEN
      -- Break up the old component name into the component ID, base name and
      -- document name
      slashPos := INSTR(p_oldName, '/', -1);
      oldCompName := SUBSTR(p_oldName, oldPeriodPos + 1);
      oldBaseName := SUBSTR(p_oldName, slashPos + 1, oldPeriodPos - slashPos - 1);
      oldDocName := SUBSTR(p_oldName, 1, oldPeriodPos - 1);
      
      -- Break up the new compoent name into the component ID, base name and
      -- document name
      slashPos := INSTR(p_newName, '/', -1);
      newCompName := SUBSTR(p_newName, newPeriodPos + 1);
      newBaseName := SUBSTR(p_newName, slashPos + 1, newPeriodPos - slashPos - 1);
      newDocName := SUBSTR(p_newName, 1, newPeriodPos - 1);

      -- We do not support both renaming a component and renaming a document
      -- with the same mapping, so throw an error if this is the case
      IF (oldDocName <> newDocName) THEN
        raise_application_error(ERROR_ILLEGAL_MAPPING, NULL);
      END IF;

      -- Make any necessary changes to the customization documents,
      -- replacing the old component name eith the new component name
      OPEN c_attributes(oldDocName, oldBaseName, oldCompName);
      LOOP
        FETCH c_attributes INTO docID, attCompSeq, attSeq, attName;
        IF (c_attributes%NOTFOUND) THEN
          CLOSE c_attributes;
          EXIT;
        END IF;
        
        UPDATE jdr_attributes SET att_value = newCompName
        WHERE att_comp_docid = docID AND
              att_comp_seq = attCompSeq AND
              att_seq = attSeq AND
              att_name = attName;        

        changesMade := changesMade + 1;
      END LOOP;

      -- Make any changes to translations, replacing the old component name
      -- with the new component name.
      IF (p_translations <> 0) THEN
        OPEN c_translations(oldDocName, oldBaseName, oldCompName);
        LOOP
          FETCH c_translations INTO docID, oldCompRef;
          IF (c_translations%NOTFOUND) THEN
            CLOSE c_translations;
            EXIT;
          END IF;

          -- For customization views, the reference is of the form:
          --  :theview.componentID
          IF (INSTR(oldCompRef, ':') = 1) THEN
            newCompRef := SUBSTR(oldCompRef, 1, INSTR(oldCompRef, '.')) || newCompName;
          ELSE
            newCompRef := newCompName;
          END IF;

          UPDATE jdr_attributes_trans SET atl_comp_ref = newCompRef 
          WHERE atl_comp_docid = docID AND
                atl_comp_ref = oldCompRef;
                
          changesMade := changesMade + 1;
        END LOOP;
      END IF;
    ELSE
      -- Since no component ID was specified, it means that we are dealing 
      -- with the refactoring of a document, as opposed to a component

      -- Get the new base name and document name
      newDocName := p_newName;
      oldDocName := p_oldName;
      oldBaseName := SUBSTR(p_oldName, INSTR(p_oldName, '/', -1) + 1);      
      newBaseName := SUBSTR(p_newName, INSTR(p_newName, '/', -1) + 1);

      -- Get each of the customization documents
      OPEN c_documents(oldDocName, oldBaseName);
      LOOP
        FETCH c_documents INTO docID, username, oldCustDocName;
        IF (c_documents%NOTFOUND) THEN
          CLOSE c_documents;
          EXIT;
        END IF;

        -- For each customization document, we need to rename the customization
        -- document and change the customizes attributes.  To rename the
        -- customization document, we first need to determine the new name of 
        -- the customization document.
        --
        -- #(3455760) Originally, we always used the new style naming for the
        -- customization documents.  That is, we would convert old style 
        -- customizations to the new naming style.  However, for consistency
        -- reasons, it was decided that it makes more sense to convert old
        -- style to old style and new style to new style.
        -- 
        -- For new style customizations, suppose the customization 
        -- document is:
        --   /oracle/apps/jrad/webui/customizations/site/tower/musicpage
        -- And the new base document is:
        --   /oracle/apps/newjrad/webui/musicpage
        -- Then the new customization document is:
        --   /oracle/apps/newjrad/webui/customizations/site/tower/musicpage
        -- which is combination of:
        -- (1) the path name of the new document +
        -- (2) "customizations" +
        -- (3) layer type and layer value of the customization document +
        -- (4) the base name of the new document
        --
        -- For old style customizations, suppose the customization document
        -- is:
        --   /oracle/apps/jrad/customizations/site/tower/webui/musicpage
        -- And the new base document is:
        --   /oracle/apps/newjrad/webui/musicpage
        -- Then the new customization document is:
        --   /oracle/apps/newjrad/customizations/site/tower/webui/musicpage
        -- which is a combination of:
        -- (1) The first three packages of the new document +
        -- (2) "customizations" +
        -- (3) layer type and layer value of the customization document +
        -- (4) the remaining portion of the new document (minus the first three)
        --
        -- To determine whether or not this is an old style document, we
        -- simply need to count the slashes after the customizes portion.  It's 
        -- an old style customizations if there are more than 3 slashes in the
        -- customizes portions, since new style customizations will have exactly 
        -- 3 slashes (one for the layer type, one for the layer value and one
        -- for the document name).
        custPos := INSTR(oldCustDocName, '/customizations');
        IF (INSTR(oldCustDocName, '/', custPos + 1, 4) <> 0) THEN
          -- This is an old style customization.  For the following, suppose
          -- that the old customization document is : 
          --   /oracle/apps/jrad/customizations/site/tower/webui/musicpage
          -- and that the new document name is:
          --   /oracle/apps/newjrad/webui/musicpage
          --
          -- (1) Get the first 3 packages of the new name.  
          --     /oracle/apps/newjrad/
          newCustDocName := SUBSTR(newDocName, 1, INSTR(newDocName, '/', 1, 4));

          -- (2) Add the customizations portion
          --     /oracle/apps/newjrad/customizations
          newCustDocName := newCustDocName || 'customizations';

          -- (3) Add the layer type and layer value
          --     /oracle/apps/newjrad/customizations/site/tower/
          pos1 := INSTR(oldCustDocName, '/', custpos + 1, 1);
          pos2 := INSTR(oldCustDocName, '/', custpos + 1, 3);          
          newCustDocName := newCustDocName ||
                            SUBSTR(oldCustDocName, pos1, pos2 - pos1 + 1);

          -- (4) Add the remaining portion of the new document
          --     /oracle/apps/newjrad/customizations/site/tower/webui/musicpage
          newCustDocName := newCustDocName ||
                            SUBSTR(newDocName, INSTR(newDocName, '/', 1, 4) + 1);
        ELSE
          -- This is an new style customization.  For the following, suppose
          -- that the old customization document is : 
          --   /oracle/apps/jrad/webui/customizations/site/tower/musicpage
          -- and that the new document name is:
          --   /oracle/apps/newjrad/webui/musicpage
          --
          -- (1) Get the first path name of the new document
          --     /oracle/apps/newjrad/webui/
          newCustDocName := SUBSTR(newDocName, 1, INSTR(newDocName, '/', -1));
          
          -- (2) Add the customizations portion
          --     /oracle/apps/newjrad/webui/customizations
          newCustDocName := newCustDocName || 'customizations';

          -- (3) Add the layer type and layer value
          --     /oracle/apps/newjrad/webui/customizations/site/tower/
          pos1 := INSTR(oldCustDocName, '/', custpos + 1, 1);
          pos2 := INSTR(oldCustDocName, '/', custpos + 1, 3);          
          newCustDocName := newCustDocName ||
                            SUBSTR(oldCustDocName, pos1, pos2 - pos1 + 1);
        
          -- (4) Add base name of the new document
          --     /oracle/apps/newjrad/webui/customizations/site/tower/musicpage
          newCustDocName := newCustDocName || newBaseName;
        END IF;

        -- Create the path for the new customized document.  If the path
        -- already exists, it will simply return the owner.
        ownerID := createPath(username, 
                              RTRIM(newCustDocName, newBaseName), '', '', '');
        IF (ownerID = -1) THEN
          raise_application_error(ERROR_INVALID_NAME, NULL);
        END IF;

        -- Update the path with the new base name and new owner ID
        BEGIN
          UPDATE jdr_paths 
          SET path_name = newBaseName,
              path_owner_docid = ownerID
          WHERE path_docid = docID;
        EXCEPTION
          -- This can happen if the customization already exists on the 
          -- refactored base document.  If so, do not attempt to overwrite
          -- the existing customization.
          WHEN DUP_VAL_ON_INDEX THEN
            GOTO end_loop;
        END;

        -- Make the necessary changes to the customization documents, replacing
        -- the customizes attribute with the new base document name.
        UPDATE jdr_attributes
        SET att_value = newDocName
        WHERE att_comp_docid = docID AND
              att_comp_seq = 0 AND
              att_name = 'customizes' AND
              att_value = oldDocName;

        -- #(3456035) Modify the package attribute if the document has been
        -- moved to a new package
        IF (RTRIM(p_oldName, oldBaseName) <> RTRIM(p_newName, newBaseName)) THEN
          UPDATE jdr_attributes
          SET att_value = REPLACE(newCustDocName, '/'||newBaseName)
          WHERE att_comp_docid = docID AND
                att_comp_seq = 0 AND
                att_name = 'package';
        END IF;
              
        changesMade := changesMade + 1;

        <<end_loop>>
        NULL;
      END LOOP;
    END IF;

    RETURN (changesMade);
  END;

  -- 
  -- Remove any dangling references of the document.  This is only necessary
  -- for package documents.  Here's a scenario where this is relevant.
  -- Suppose you have a package document FOO which has child documents A, B and 
  -- C.  Now suppose you are updating FOO, this time removing document C.  
  -- In order make sure that all references to C are destroyed, this needs to
  -- be called after saving FOO.
  -- 
  PROCEDURE removeDanglingReferences(
    docID      JDR_PATHS.PATH_DOCID%TYPE)
  IS
  BEGIN
    DELETE jdr_paths 
    WHERE path_seq=-2 AND path_docid IN 
      (SELECT path_docid FROM jdr_paths
       START WITH path_docid = docid
       CONNECT BY PRIOR path_docid=path_owner_docid);
  END;


BEGIN
  -- Initialize the stack for exporting XML
  mPackageStack := NumArray(NULL);
  mPackageStack.EXTEND(mPackageStack.LIMIT-1,1);

  mPackageNames := CharArray(NULL);
  mPackageNames.EXTEND(mPackageNames.LIMIT-1,1);

  mStack := CharArray(NULL);
  mStack.EXTEND(mStack.LIMIT-1,1);

END;
/

COMMIT;
EXIT;
