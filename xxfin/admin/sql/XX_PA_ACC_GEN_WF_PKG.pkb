create or replace
PACKAGE BODY XX_PA_ACC_GEN_WF_PKG AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_PA_ACC_GEN_WF_PKG                                                        |
-- |  RICE ID 	 :       			                        			|
-- |  Description:  Package used for PO Account Generator Workflow customization              	|
-- |                                                           				        |        
-- |		    										|
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 2.0         06/29/2017   Avinash Baddam   Added procedures IS_AA_DIFF_FOR_PO_TYPE and      |
-- |					       IS_VA_DIFF_FOR_PO_TYPE                           |
-- +============================================================================================+

PROCEDURE GET_PROJECT_TYPE_CLASS_CODE (
		p_itemtype	IN  VARCHAR2,
		p_itemkey	IN  VARCHAR2,
		p_actid		IN  NUMBER,
		p_funcmode	IN  VARCHAR2,
		x_result	OUT nocopy VARCHAR2)
 AS
   ls_project_type              PA_PROJECT_TYPES_ALL.project_type%TYPE;
   ls_project_type_class_code   PA_PROJECT_TYPES_ALL.project_type_class_code%TYPE := '';
   ld_sysdate                   DATE := TRUNC(SYSDATE);
 BEGIN

-----------------------------------------------------------------------
-- Check the Workflow mode in which this function has been called. If
-- it is not in the RUN mode, then exit out of this function
-----------------------------------------------------------------------

 IF p_funcmode <> 'RUN'
 THEN
   x_result := NULL;
   RETURN;
 END IF;

---------------------------------------------------
-- Retrieve the project type
---------------------------------------------------

 ls_project_type :=
	wf_engine.GetItemAttrText
			(	itemtype	=> p_itemtype,
				itemkey		=> p_itemkey,
				aname		=> 'PROJECT_TYPE' );

-------------------------------------------
-- Select the project type class code
-------------------------------------------

  BEGIN
   SELECT project_type_class_code
     INTO ls_project_type_class_code
     FROM PA_PROJECT_TYPES_ALL
    WHERE project_type = ls_project_type
      AND ld_sysdate BETWEEN start_date_active and NVL(end_date_active,SYSDATE);
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

-----------------------------------------------------------------------
-- If the retrieval was successful, then set the appropriate item
-- attribute to the value retrieved. Otherwise, raise the appropriate
-- error message
-----------------------------------------------------------------------

  wf_engine.SetItemAttrText( itemtype	=> p_itemtype,
			     itemkey 	=> p_itemkey,
			     aname	=> 'XX_PROJ_TYPE_CLASS_CODE',
			     avalue	=> ls_project_type_class_code);

 x_result := 'COMPLETE:SUCCESS';

 EXCEPTION

-----------------------------------------------------------
-- Any other exception is raised to the calling program
-----------------------------------------------------------

   WHEN OTHERS THEN

    -- populate the error message wf attribute and return failure.
	wf_engine.SetItemAttrText
                ( itemtype=> p_itemtype,
                  itemkey => p_itemkey,
                  aname   => 'ERROR_MESSAGE',
                  avalue  => 'Unknown Error in XX_PA_ACC_GEN_WF_PKG.GET_PROJECT_TYPE_CLASS_CODE');

    -- Return a failure so that the abort generation End function is called

        x_result := 'COMPLETE:FAILURE';

	-- Record standard workflow debugging message
        wf_core.context( pkg_name	=> 'XX_PA_ACC_GEN_WF_PKG ',
			 proc_name	=> 'GET_PROJECT_TYPE_CLASS_CODE',
			 arg1		=>  'Unknown Error',
			 arg2		=>  null,
			 arg3		=>  null,
			 arg4		=>  null,
			 arg5		=>  null);

        RETURN;

 END GET_PROJECT_TYPE_CLASS_CODE;


-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------


PROCEDURE PA_LOCATION_LOOKUP (
		p_itemtype	IN  VARCHAR2,
		p_itemkey	IN  VARCHAR2,
		p_actid		IN  NUMBER,
		p_funcmode	IN  VARCHAR2,
		x_result	OUT NOCOPY VARCHAR2)
 AS
    NO_ATTRIBUTE_VAL                EXCEPTION;
    lc_attribute_name               VARCHAR2(30) := 'TASK_ID';
    l_attribute_val                 NUMBER;
    lc_segment_value	            VARCHAR2(25);
 BEGIN

-----------------------------------------------------------------------
-- Check the Workflow mode in which this function has been called. If
-- it is not in the RUN mode, then exit out of this function
-----------------------------------------------------------------------

 IF p_funcmode <> 'RUN'
 THEN
   x_result := null;
   RETURN;
 END IF;

---------------------------------------------------
-- Retrieve the attribute value
---------------------------------------------------

 l_attribute_val :=
	wf_engine.GetItemAttrNumber
			(	itemtype	=> p_itemtype,
				itemkey		=> p_itemkey,
				aname		=> lc_attribute_name );

------------------------------------------------------------------------
-- Raise the appropriate exception if the attribute has not been set
------------------------------------------------------------------------

 IF l_attribute_val IS NULL
 THEN
   RAISE NO_ATTRIBUTE_VAL;
 END IF;


-------------------------------------------
-- Select the location segment from the table
-------------------------------------------

 SELECT NVL(T.attribute1,NVL(P.attribute1,'010000'))
 INTO   lc_segment_value
 FROM   PA_TASKS T
       ,PA_PROJECTS_ALL P
 WHERE  T.task_id = l_attribute_val
 AND    P.project_id = T.project_id;

-----------------------------------------------------------------------
-- If the retrieval was successful, then set the appropriate item
-- attribute to the value retrieved. Otherwise, raise the appropriate
-- error message
-----------------------------------------------------------------------

 wf_engine.SetItemAttrText( itemtype	=> p_itemtype,
			     itemkey 	=> p_itemkey,
			     aname	=> 'LOOKUP_SET_VALUE',
			     avalue	=> lc_segment_value);

 x_result := 'COMPLETE:SUCCESS';


 EXCEPTION

------------------------------------------------------------------
-- User defined exception raised when lookup type is not defined
------------------------------------------------------------------

   WHEN NO_ATTRIBUTE_VAL
   THEN
 	-- Record standard workflow debugging message
        wf_core.context( pkg_name	=> 'XX_PA_ACC_GEN_WF_PKG ',
			 proc_name	=> 'PA_LOCATION_LOOKUP',
			 arg1		=>  'No ' || lc_attribute_name,
			 arg2		=>  null,
			 arg3		=>  null,
			 arg4		=>  null,
			 arg5		=>  null);


	-- Error requires an error message to be set so that it can be
	-- displayed on the form.

        wf_engine.SetItemAttrText( itemtype     => p_itemtype,
                                   itemkey      => p_itemkey,
                                   aname        => 'ERROR_MESSAGE',
                                   avalue       => 'No ' || lc_attribute_name);


    -- Return a failure so that the abort generation End function is called

	x_result := 'COMPLETE:FAILURE';
	RETURN;

------------------------------------------------------------------------
-- If data is not found after the SELECT, it indicates that the
-- combination of the lookup type and lookup code has not been defined
------------------------------------------------------------------------

   WHEN NO_DATA_FOUND
   THEN
	-- Record standard workflow debugging message
        wf_core.context( pkg_name	=> 'XX_PA_ACC_GEN_WF_PKG ',
			 proc_name	=> 'PA_LOCATION_LOOKUP',
			 arg1		=>  'Location not found for ' || lc_attribute_name || ' ' || l_attribute_val,
			 arg2		=>  null,
			 arg3		=>  null,
			 arg4		=>  null,
			 arg5		=>  null);

	-- Error requires an error message to be set so that it can be
	-- displayed on the form.

	wf_engine.SetItemAttrText
                ( itemtype=> p_itemtype,
                  itemkey => p_itemkey,
                  aname   => 'ERROR_MESSAGE',
                  avalue  => 'Location not found for ' || lc_attribute_name || ' ' || l_attribute_val);


    -- Return a failure so that the abort generation End function is called

	x_result := 'COMPLETE:FAILURE';
	RETURN;

-----------------------------------------------------------
-- All other exceptions are raised to the calling program
-----------------------------------------------------------

   WHEN OTHERS
   THEN

-- populate the error message wf attribute and return failure.

	wf_engine.SetItemAttrText
                ( itemtype=> p_itemtype,
                  itemkey => p_itemkey,
                  aname   => 'ERROR_MESSAGE',
                  avalue  => 'Unknown Error in XX_PA_ACC_GEN_WF_PKG.PA_LOCATION_LOOKUP');

    -- Return a failure so that the abort generation End function is called

        x_result := 'COMPLETE:FAILURE';

	-- Record standard workflow debugging message
        wf_core.context( pkg_name	=> 'XX_PA_ACC_GEN_WF_PKG ',
			 proc_name	=> 'PA_LOCATION_LOOKUP',
			 arg1		=>  'Unknown Error',
			 arg2		=>  null,
			 arg3		=>  null,
			 arg4		=>  null,
			 arg5		=>  null);

        RETURN;

 END PA_LOCATION_LOOKUP;

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

-- ASSIGN_TEXT_TO_NUMBER_ATT
--   Assign a text value to a number type item attribute
-- OUT
--   result - null
-- ACTIVITY ATTRIBUTES REFERENCED
--   ATTR         - Item attribute
--   DATE_VALUE   - date value
--   NUMBER_VALUE - number value
--   TEXT_VALUE   - text value
PROCEDURE ASSIGN_TEXT_TO_NUMBER_ATT(
   p_itemtype  IN VARCHAR2,
   p_itemkey   IN VARCHAR2,
   p_actid     IN NUMBER,
   p_funcmode  IN VARCHAR2,
   x_resultout OUT NOCOPY VARCHAR2)
IS
  ls_atype    varchar2(8);
  ls_asubtype varchar2(8);
  ls_aformat  varchar2(240);
  ls_aname    varchar2(30);
BEGIN
  -- Do nothing in cancel or timeout mode
  if (p_funcmode <> wf_engine.eng_run) then
    x_resultout := wf_engine.eng_null;
    return;
  end if;

  -- Get attribute info
  ls_aname := wf_engine.GetActivityAttrText(p_itemtype, p_itemkey, p_actid, 'XX_ATTR');
  wf_engine.GetItemAttrInfo(p_itemtype, ls_aname, ls_atype, ls_asubtype, ls_aformat);

  if (ls_atype = 'NUMBER') then
    wf_engine.SetItemAttrNumber(p_itemtype,p_itemkey,ls_aname,
    to_number(wf_engine.GetActivityAttrText(p_itemtype,p_itemkey,p_actid, 'XX_TEXT_VALUE')));
  end if;

  x_resultout := wf_engine.eng_completed||':'||wf_engine.eng_null;
exception
  when others then
    Wf_Core.Context('XX_PA_ACC_GEN_WF_PKG', 'ASSIGN_TEXT_TO_NUMBER_ATT', p_itemtype,
                    p_itemkey, to_char(p_actid), p_funcmode);
    raise;
END ASSIGN_TEXT_TO_NUMBER_ATT;

PROCEDURE IS_AA_DIFF_FOR_PO_TYPE (
		p_itemtype	IN  VARCHAR2,
		p_itemkey	IN  VARCHAR2,
		p_actid		IN  NUMBER,
		p_funcmode	IN  VARCHAR2,
		x_result	OUT nocopy VARCHAR2)
 AS
   lc_error_msg                 VARCHAR2(250);
   lc_header_att14		VARCHAR2(250);
   lc_attribute_category        po_headers_all.attribute_category%TYPE;
   ln_organization  hr_all_organization_units.organization_id%TYPE;
   ln_lob NUMBER := 0 ;

 BEGIN

-----------------------------------------------------------------------
-- Check the Workflow mode in which this function has been called. If
-- it is not in the RUN mode, then exit out of this function
-----------------------------------------------------------------------

 IF p_funcmode <> 'RUN'
 THEN
   x_result := NULL;
   RETURN;
 END IF;
/*
---------------------------------------------------
-- LOB change
---------------------------------------------------

ln_organization               :=
	wf_engine.GetItemAttrText
			(itemtype	=> p_itemtype,
			 itemkey	=> p_itemkey,
			 aname		=> 'DESTINATION_ORGANIZATION_ID' );
ln_lob := 0;

SELECT count(*)
  INTO ln_lob
  FROM xx_fin_translatedefinition xtd,
       xx_fin_translatevalues xtv
 WHERE xtd.translation_name = 'OD_INVENTORY_ORG_LOB' 
   AND xtd.translate_id     = xtv.translate_id 
   AND source_value2        = ln_organization;

IF ln_lob <> 0 THEN
	wf_engine.SetItemAttrText( itemtype     => p_itemtype,
								itemkey     => p_itemkey,
								aname       => 'XX_LOB_VALUE',
								avalue      => '40');  --diff account value will be provided later
    
END IF;

*/
 
---------------------------------------------------
-- Retrieve the po category
---------------------------------------------------

 lc_header_att14 :=
	wf_engine.GetItemAttrText
			(itemtype	=> p_itemtype,
			 itemkey	=> p_itemkey,
			 aname		=> 'HEADER_ATT14' );
				
 IF SUBSTR(lc_header_att14,1,8) = 'DropShip' THEN
    wf_engine.SetItemAttrText( itemtype     => p_itemtype,
			       itemkey      => p_itemkey,
			       aname        => 'XX_ACCOUNT_VALUE',
			       avalue       => '22003000');
    x_result := WF_ENGINE.eng_completed || ':Y';
 ELSIF lc_header_att14 = 'Direct Import' THEN
    wf_engine.SetItemAttrText( itemtype     => p_itemtype,
			       itemkey      => p_itemkey,
			       aname        => 'XX_ACCOUNT_VALUE',
			       avalue       => '20103500');  --diff account value will be provided later
    x_result := WF_ENGINE.eng_completed || ':Y';  
 ELSIF lc_header_att14 IN ('FrontDoor DC','FrontDoor Retail','New Store','Non-Code','Replenishment','Trade') THEN 
    wf_engine.SetItemAttrText( itemtype     => p_itemtype,
			       itemkey      => p_itemkey,
			       aname        => 'XX_ACCOUNT_VALUE',
			       avalue       => '20103000');  --diff account value will be provided later
    x_result := WF_ENGINE.eng_completed || ':Y';  
 
 ELSE
    x_result := WF_ENGINE.eng_completed || ':N';
 END IF;    
 
 EXCEPTION

-----------------------------------------------------------
-- Any other exception is raised to the calling program
-----------------------------------------------------------

   WHEN OTHERS THEN
      lc_error_msg := SUBSTR(sqlerrm,1,250);
    -- populate the error message wf attribute and return failure.
	wf_engine.SetItemAttrText
                ( itemtype=> p_itemtype,
                  itemkey => p_itemkey,
                  aname   => 'ERROR_MESSAGE',
                  avalue  => lc_error_msg||' in XX_PA_ACC_GEN_WF_PKG.IS_AA_DIFF_FOR_PO_TYPE');

	-- Record standard workflow debugging message
        wf_core.context( pkg_name	=> 'XX_PA_ACC_GEN_WF_PKG ',
			 proc_name	=> 'IS_AA_DIFF_FOR_PO_TYPE',
			 arg1		=>  lc_error_msg,
			 arg2		=>  null,
			 arg3		=>  null,
			 arg4		=>  null,
			 arg5		=>  null);

        RAISE;

 END IS_AA_DIFF_FOR_PO_TYPE;
 
 PROCEDURE IS_VA_DIFF_FOR_PO_TYPE (
		p_itemtype	IN  VARCHAR2,
		p_itemkey	IN  VARCHAR2,
		p_actid		IN  NUMBER,
		p_funcmode	IN  VARCHAR2,
		x_result	OUT nocopy VARCHAR2)
 AS
   lc_error_msg                 VARCHAR2(250);
   lc_header_att14		VARCHAR2(250);
   lc_attribute_category        po_headers_all.attribute_category%TYPE;

 BEGIN

-----------------------------------------------------------------------
-- Check the Workflow mode in which this function has been called. If
-- it is not in the RUN mode, then exit out of this function
-----------------------------------------------------------------------

 IF p_funcmode <> 'RUN'
 THEN
   x_result := NULL;
   RETURN;
 END IF;

---------------------------------------------------
-- Retrieve the po category
---------------------------------------------------
 lc_header_att14 :=
	wf_engine.GetItemAttrText
			(itemtype	=> p_itemtype,
			 itemkey	=> p_itemkey,
			 aname		=> 'HEADER_ATT14' );
				
 IF SUBSTR(lc_header_att14,1,8) = 'DropShip' THEN
    wf_engine.SetItemAttrText( itemtype     => p_itemtype,
			       itemkey      => p_itemkey,
			       aname        => 'XX_ACCOUNT_VALUE',
			       avalue       => '51105000');
    x_result := WF_ENGINE.eng_completed || ':Y';
ELSIF lc_header_att14 IN ('FrontDoor DC','FrontDoor Retail','New Store','Non-Code','Replenishment','Trade') THEN 
	wf_engine.SetItemAttrText( itemtype     => p_itemtype,
			       itemkey      => p_itemkey,
			       aname        => 'XX_ACCOUNT_VALUE',
			       avalue       => '51104000');
    x_result := WF_ENGINE.eng_completed || ':Y';
 ELSE
    x_result := WF_ENGINE.eng_completed || ':N';
 END IF;    
 
 EXCEPTION

-----------------------------------------------------------
-- Any other exception is raised to the calling program
-----------------------------------------------------------

   WHEN OTHERS THEN
      lc_error_msg := SUBSTR(sqlerrm,1,250);
    -- populate the error message wf attribute and return failure.
	wf_engine.SetItemAttrText
                ( itemtype=> p_itemtype,
                  itemkey => p_itemkey,
                  aname   => 'ERROR_MESSAGE',
                  avalue  => lc_error_msg||' in XX_PA_ACC_GEN_WF_PKG.IS_VA_DIFF_FOR_PO_TYPE');

	-- Record standard workflow debugging message
        wf_core.context( pkg_name	=> 'XX_PA_ACC_GEN_WF_PKG ',
			 proc_name	=> 'IS_VA_DIFF_FOR_PO_TYPE',
			 arg1		=>  lc_error_msg,
			 arg2		=>  null,
			 arg3		=>  null,
			 arg4		=>  null,
			 arg5		=>  null);

        RAISE;

 END IS_VA_DIFF_FOR_PO_TYPE; 
 
 PROCEDURE IS_LOB_OVERWRITE (
		p_itemtype	IN  VARCHAR2,
		p_itemkey	IN  VARCHAR2,
		p_actid		IN  NUMBER,
		p_funcmode	IN  VARCHAR2,
		x_result	OUT nocopy VARCHAR2)
 AS
   lc_error_msg                 VARCHAR2(250);
   ln_organization  hr_all_organization_units.organization_id%TYPE;
   lc_lob xx_fin_translatevalues.target_value1%TYPE;

 BEGIN

-----------------------------------------------------------------------
-- Check the Workflow mode in which this function has been called. If
-- it is not in the RUN mode, then exit out of this function
-----------------------------------------------------------------------

 IF p_funcmode <> 'RUN'
 THEN
   x_result := NULL;
   RETURN;
 END IF;
---------------------------------------------------
-- LOB change
---------------------------------------------------

ln_organization               :=
	wf_engine.GetItemAttrText
			(itemtype	=> p_itemtype,
			 itemkey	=> p_itemkey,
			 aname		=> 'DESTINATION_ORGANIZATION_ID' );
lc_lob := NULL;

BEGIN
SELECT target_value1
  INTO lc_lob
  FROM xx_fin_translatedefinition xtd,
       xx_fin_translatevalues xtv
 WHERE xtd.translation_name = 'OD_INVENTORY_ORG_LOB' 
   AND xtd.translate_id     = xtv.translate_id 
   AND source_value2        = ln_organization;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   x_result := WF_ENGINE.eng_completed || ':N';
END;   

IF lc_lob IS NOT NULL THEN
	wf_engine.SetItemAttrText( itemtype     => p_itemtype,
								itemkey     => p_itemkey,
								aname       => 'XX_LOB_VALUE',
								avalue      => lc_lob);  --diff account value will be provided later
    x_result := WF_ENGINE.eng_completed || ':Y';  

ELSE	
    x_result := WF_ENGINE.eng_completed || ':N';
END IF;
 
 
 EXCEPTION

-----------------------------------------------------------
-- Any other exception is raised to the calling program
-----------------------------------------------------------

   WHEN OTHERS THEN
      lc_error_msg := SUBSTR(sqlerrm,1,250);
    -- populate the error message wf attribute and return failure.
	wf_engine.SetItemAttrText
                ( itemtype=> p_itemtype,
                  itemkey => p_itemkey,
                  aname   => 'ERROR_MESSAGE',
                  avalue  => lc_error_msg||' in XX_PA_ACC_GEN_WF_PKG.IS_LOB_OVERWRITE');

	-- Record standard workflow debugging message
        wf_core.context( pkg_name	=> 'XX_PA_ACC_GEN_WF_PKG ',
			 proc_name	=> 'IS_LOB_OVERWRITE',
			 arg1		=>  lc_error_msg,
			 arg2		=>  null,
			 arg3		=>  null,
			 arg4		=>  null,
			 arg5		=>  null);

        RAISE;

 END IS_LOB_OVERWRITE;


END XX_PA_ACC_GEN_WF_PKG;

/
SHOW ERR
