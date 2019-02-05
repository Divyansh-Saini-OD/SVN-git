/*=======================================================================+
 |  Copyright (c) 1998 Oracle Corporation Redwood Shores, California, USA|
 |                            All rights reserved.                       |
 +=======================================================================+
 | FILENAME
 |   INVICAHB.pls
 |
 | DESCRIPTION
 |   PL/SQL body for package:  MTL_CATEGORIES_PKG
 |   This is ML table handler for MTL_CATEGORIES table. It is used by the
 |   Define Category Codes form.
 |
 | HISTORY
 |   23-DEC-98  anakas  Created
 |   09-JUN-02  Rathna Vuppala Bug: 2430879 , Added new column WEB_STATUS
 |                             for the iProcurement ENH
 |   08/10/02  anakas   Ehancement 2430813: added calls to maintain
 |                      DBi Item dimension STAR table.
 |   28-OCT-02  Rathna Vuppala Bug: 2645153 , Added new column
 |                         SUPPLIER_ENABLED_FLAG for the iProcurement ENH
 |   07-JAN-03  Rathna Vuppala Bug: 2718703 Replaced the ENI_ITEM_STAR_PKG
 |                             Calls with EXECUTE IMMIDIATE
 |   18-May-05  Lakshaman      R12: Business Events
 |   20-SEP-05  Swapnil        Bug: 4494727. Removed validations web_status
 |                             based on web_status
 |   02-Dec-05  Lakshaman      Bug: 4759298 Adding Load Row
 |   16-Dec-05  Lakshaman      Bug: 4889622 CATEGORY_SET_NAME column should
 |                             be referred from categories TL table and not
 |                             the B table.
 |   05-Jun-06  Lakshaman      Bug:5256760 call fnd_load_util to determine
 |                             owner
 |   01-Aug-16  Paddy Sanjeevi Retrofitted for R12.2.5
 *=======================================================================*/
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile(120.12.12010000.5=120.15.12020000.2)(120.5.12000000.5=120.9)(115.12=120.0):~PROD:~PATH:~FILE

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace package body MTL_CATEGORIES_PKG as
/* $Header: INVICAHB.pls 120.15.12020000.2 2012/08/22 01:56:45 zewhuang ship $ */

procedure INSERT_ROW (
  X_ROWID in out NOCOPY VARCHAR2,
  X_CATEGORY_ID in NUMBER,
  X_DESCRIPTION in VARCHAR2,
  X_STRUCTURE_ID in NUMBER,
  X_DISABLE_DATE in DATE,
  X_WEB_STATUS   in VARCHAR2,
  X_SUPPLIER_ENABLED_FLAG   in VARCHAR2,
  X_SEGMENT1 in VARCHAR2,
  X_SEGMENT2 in VARCHAR2,
  X_SEGMENT3 in VARCHAR2,
  X_SEGMENT4 in VARCHAR2,
  X_SEGMENT5 in VARCHAR2,
  X_SEGMENT6 in VARCHAR2,
  X_SEGMENT7 in VARCHAR2,
  X_SEGMENT8 in VARCHAR2,
  X_SEGMENT9 in VARCHAR2,
  X_SEGMENT10 in VARCHAR2,
  X_SEGMENT11 in VARCHAR2,
  X_SEGMENT12 in VARCHAR2,
  X_SEGMENT13 in VARCHAR2,
  X_SEGMENT14 in VARCHAR2,
  X_SEGMENT15 in VARCHAR2,
  X_SEGMENT16 in VARCHAR2,
  X_SEGMENT17 in VARCHAR2,
  X_SEGMENT18 in VARCHAR2,
  X_SEGMENT19 in VARCHAR2,
  X_SEGMENT20 in VARCHAR2,
  X_SUMMARY_FLAG in VARCHAR2,
  X_ENABLED_FLAG in VARCHAR2,
  X_START_DATE_ACTIVE in DATE,
  X_END_DATE_ACTIVE in DATE,
  X_ATTRIBUTE_CATEGORY in VARCHAR2,
  X_ATTRIBUTE1 in VARCHAR2,
  X_ATTRIBUTE2 in VARCHAR2,
  X_ATTRIBUTE3 in VARCHAR2,
  X_ATTRIBUTE4 in VARCHAR2,
  X_ATTRIBUTE5 in VARCHAR2,
  X_ATTRIBUTE6 in VARCHAR2,
  X_ATTRIBUTE7 in VARCHAR2,
  X_ATTRIBUTE8 in VARCHAR2,
  X_ATTRIBUTE9 in VARCHAR2,
  X_ATTRIBUTE10 in VARCHAR2,
  X_ATTRIBUTE11 in VARCHAR2,
  X_ATTRIBUTE12 in VARCHAR2,
  X_ATTRIBUTE13 in VARCHAR2,
  X_ATTRIBUTE14 in VARCHAR2,
  X_ATTRIBUTE15 in VARCHAR2,
  X_LAST_UPDATE_DATE in DATE,
  X_LAST_UPDATED_BY in NUMBER,
  X_CREATION_DATE in DATE,
  X_CREATED_BY in NUMBER,
  X_LAST_UPDATE_LOGIN in NUMBER
--  X_REQUEST_ID in NUMBER,
) is

  cursor C is
    select ROWID
    from  MTL_CATEGORIES_B
    where  CATEGORY_ID = X_CATEGORY_ID ;

begin

  insert into MTL_CATEGORIES_B (
    CATEGORY_ID,
    STRUCTURE_ID,
    DISABLE_DATE,
    WEB_STATUS,
    SUPPLIER_ENABLED_FLAG,
    SEGMENT1,
    SEGMENT2,
    SEGMENT3,
    SEGMENT4,
    SEGMENT5,
    SEGMENT6,
    SEGMENT7,
    SEGMENT8,
    SEGMENT9,
    SEGMENT10,
    SEGMENT11,
    SEGMENT12,
    SEGMENT13,
    SEGMENT14,
    SEGMENT15,
    SEGMENT16,
    SEGMENT17,
    SEGMENT18,
    SEGMENT19,
    SEGMENT20,
    SUMMARY_FLAG,
    ENABLED_FLAG,
    START_DATE_ACTIVE,
    END_DATE_ACTIVE,
    ATTRIBUTE_CATEGORY,
    ATTRIBUTE1,
    ATTRIBUTE2,
    ATTRIBUTE3,
    ATTRIBUTE4,
    ATTRIBUTE5,
    ATTRIBUTE6,
    ATTRIBUTE7,
    ATTRIBUTE8,
    ATTRIBUTE9,
    ATTRIBUTE10,
    ATTRIBUTE11,
    ATTRIBUTE12,
    ATTRIBUTE13,
    ATTRIBUTE14,
    ATTRIBUTE15,
--    WH_UPDATE_DATE,
--    TOTAL_PROD_ID,
--    REQUEST_ID,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY,
    CREATION_DATE,
    CREATED_BY,
    LAST_UPDATE_LOGIN
  ) values (
    X_CATEGORY_ID,
    X_STRUCTURE_ID,
    X_DISABLE_DATE,
    X_WEB_STATUS,
    X_SUPPLIER_ENABLED_FLAG,
    X_SEGMENT1,
    X_SEGMENT2,
    X_SEGMENT3,
    X_SEGMENT4,
    X_SEGMENT5,
    X_SEGMENT6,
    X_SEGMENT7,
    X_SEGMENT8,
    X_SEGMENT9,
    X_SEGMENT10,
    X_SEGMENT11,
    X_SEGMENT12,
    X_SEGMENT13,
    X_SEGMENT14,
    X_SEGMENT15,
    X_SEGMENT16,
    X_SEGMENT17,
    X_SEGMENT18,
    X_SEGMENT19,
    X_SEGMENT20,
    X_SUMMARY_FLAG,
    X_ENABLED_FLAG,
    X_START_DATE_ACTIVE,
    X_END_DATE_ACTIVE,
    X_ATTRIBUTE_CATEGORY,
    X_ATTRIBUTE1,
    X_ATTRIBUTE2,
    X_ATTRIBUTE3,
    X_ATTRIBUTE4,
    X_ATTRIBUTE5,
    X_ATTRIBUTE6,
    X_ATTRIBUTE7,
    X_ATTRIBUTE8,
    X_ATTRIBUTE9,
    X_ATTRIBUTE10,
    X_ATTRIBUTE11,
    X_ATTRIBUTE12,
    X_ATTRIBUTE13,
    X_ATTRIBUTE14,
    X_ATTRIBUTE15,
--    X_WH_UPDATE_DATE,
--    X_TOTAL_PROD_ID,
--    X_REQUEST_ID,
    X_LAST_UPDATE_DATE,
    X_LAST_UPDATED_BY,
    X_CREATION_DATE,
    X_CREATED_BY,
    X_LAST_UPDATE_LOGIN
  );

  insert into MTL_CATEGORIES_TL (
    CATEGORY_ID,
    LANGUAGE,
    SOURCE_LANG,
    DESCRIPTION,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY,
    CREATION_DATE,
    CREATED_BY,
    LAST_UPDATE_LOGIN
  ) select
    X_CATEGORY_ID,
    L.LANGUAGE_CODE,
    userenv('LANG'),
    X_DESCRIPTION,
    X_LAST_UPDATE_DATE,
    X_LAST_UPDATED_BY,
    X_CREATION_DATE,
    X_CREATED_BY,
    X_LAST_UPDATE_LOGIN
  from  FND_LANGUAGES  L
  where  L.INSTALLED_FLAG in ('I', 'B')
    and  not exists
         ( select NULL
           from  MTL_CATEGORIES_TL  T
           where  T.CATEGORY_ID = X_CATEGORY_ID
             and  T.LANGUAGE = L.LANGUAGE_CODE );

  open c;
  fetch c into X_ROWID;
  if (c%notfound) then
    close c;
    raise no_data_found;
  end if;
  close c;

  IF x_structure_id=201 THEN   -- Retrofitted for R12.2.5

     IF X_SEGMENT1='NA' and X_SEGMENT2='TRADE' THEN
        NULL;
     ELSE
       --R12: Raise Business Events and Call APIs
       BEGIN
        INV_ITEM_EVENTS_PVT.Raise_Events(
          p_event_name    => 'EGO_WF_WRAPPER_PVT.G_CAT_CATEGORY_CHANGE_EVENT'
         ,p_dml_type      => 'CREATE'
         ,p_category_id   =>  X_CATEGORY_ID);
       EXCEPTION
         WHEN OTHERS THEN
            NULL;
       END;

       --Call ICX APIs
       BEGIN
         INV_ITEM_EVENTS_PVT.Invoke_ICX_APIs(
           p_entity_type   => 'CATEGORY'
          ,p_dml_type      => 'CREATE'
          ,p_category_id   =>  X_CATEGORY_ID
          ,p_structure_id  =>  X_STRUCTURE_ID);
       EXCEPTION
          WHEN OTHERS THEN
             NULL;
       END;
       --R12: Business Event Enhancement:
     END IF;
  ELSE  --IF x_structure_id=201 THEN

       --R12: Raise Business Events and Call APIs
       BEGIN
        INV_ITEM_EVENTS_PVT.Raise_Events(
          p_event_name    => 'EGO_WF_WRAPPER_PVT.G_CAT_CATEGORY_CHANGE_EVENT'
         ,p_dml_type      => 'CREATE'
         ,p_category_id   =>  X_CATEGORY_ID);
       EXCEPTION
         WHEN OTHERS THEN
            NULL;
       END;

       --Call ICX APIs
       BEGIN
         INV_ITEM_EVENTS_PVT.Invoke_ICX_APIs(
           p_entity_type   => 'CATEGORY'
          ,p_dml_type      => 'CREATE'
          ,p_category_id   =>  X_CATEGORY_ID
          ,p_structure_id  =>  X_STRUCTURE_ID);
       EXCEPTION
          WHEN OTHERS THEN
             NULL;
       END;
       --R12: Business Event Enhancement:

  END IF;

end INSERT_ROW;

procedure LOCK_ROW (
  X_CATEGORY_ID in NUMBER,
  X_DESCRIPTION in VARCHAR2,
  X_STRUCTURE_ID in NUMBER,
  X_DISABLE_DATE in DATE,
  X_WEB_STATUS   in VARCHAR2,
  X_SUPPLIER_ENABLED_FLAG   in VARCHAR2,
  X_SEGMENT1 in VARCHAR2,
  X_SEGMENT2 in VARCHAR2,
  X_SEGMENT3 in VARCHAR2,
  X_SEGMENT4 in VARCHAR2,
  X_SEGMENT5 in VARCHAR2,
  X_SEGMENT6 in VARCHAR2,
  X_SEGMENT7 in VARCHAR2,
  X_SEGMENT8 in VARCHAR2,
  X_SEGMENT9 in VARCHAR2,
  X_SEGMENT10 in VARCHAR2,
  X_SEGMENT11 in VARCHAR2,
  X_SEGMENT12 in VARCHAR2,
  X_SEGMENT13 in VARCHAR2,
  X_SEGMENT14 in VARCHAR2,
  X_SEGMENT15 in VARCHAR2,
  X_SEGMENT16 in VARCHAR2,
  X_SEGMENT17 in VARCHAR2,
  X_SEGMENT18 in VARCHAR2,
  X_SEGMENT19 in VARCHAR2,
  X_SEGMENT20 in VARCHAR2,
  X_SUMMARY_FLAG in VARCHAR2,
  X_ENABLED_FLAG in VARCHAR2,
  X_START_DATE_ACTIVE in DATE,
  X_END_DATE_ACTIVE in DATE,
  X_ATTRIBUTE_CATEGORY in VARCHAR2,
  X_ATTRIBUTE1 in VARCHAR2,
  X_ATTRIBUTE2 in VARCHAR2,
  X_ATTRIBUTE3 in VARCHAR2,
  X_ATTRIBUTE4 in VARCHAR2,
  X_ATTRIBUTE5 in VARCHAR2,
  X_ATTRIBUTE6 in VARCHAR2,
  X_ATTRIBUTE7 in VARCHAR2,
  X_ATTRIBUTE8 in VARCHAR2,
  X_ATTRIBUTE9 in VARCHAR2,
  X_ATTRIBUTE10 in VARCHAR2,
  X_ATTRIBUTE11 in VARCHAR2,
  X_ATTRIBUTE12 in VARCHAR2,
  X_ATTRIBUTE13 in VARCHAR2,
  X_ATTRIBUTE14 in VARCHAR2,
  X_ATTRIBUTE15 in VARCHAR2
--  X_REQUEST_ID in NUMBER,
) is

  cursor c is
    select
      STRUCTURE_ID,
      DISABLE_DATE,
      WEB_STATUS,
      SUPPLIER_ENABLED_FLAG,
      SEGMENT1,
      SEGMENT2,
      SEGMENT3,
      SEGMENT4,
      SEGMENT5,
      SEGMENT6,
      SEGMENT7,
      SEGMENT8,
      SEGMENT9,
      SEGMENT10,
      SEGMENT11,
      SEGMENT12,
      SEGMENT13,
      SEGMENT14,
      SEGMENT15,
      SEGMENT16,
      SEGMENT17,
      SEGMENT18,
      SEGMENT19,
      SEGMENT20,
      SUMMARY_FLAG,
      ENABLED_FLAG,
      START_DATE_ACTIVE,
      END_DATE_ACTIVE,
      ATTRIBUTE_CATEGORY,
      ATTRIBUTE1,
      ATTRIBUTE2,
      ATTRIBUTE3,
      ATTRIBUTE4,
      ATTRIBUTE5,
      ATTRIBUTE6,
      ATTRIBUTE7,
      ATTRIBUTE8,
      ATTRIBUTE9,
      ATTRIBUTE10,
      ATTRIBUTE11,
      ATTRIBUTE12,
      ATTRIBUTE13,
      ATTRIBUTE14,
      ATTRIBUTE15
--      WH_UPDATE_DATE,
--      TOTAL_PROD_ID,
--      REQUEST_ID,
    from  MTL_CATEGORIES_B
    where  CATEGORY_ID = X_CATEGORY_ID
    for update of CATEGORY_ID nowait;

  recinfo c%rowtype;

  cursor c1 is
    select
      DESCRIPTION,
      decode(LANGUAGE, userenv('LANG'), 'Y', 'N') BASELANG
    from  MTL_CATEGORIES_TL
    where  CATEGORY_ID = X_CATEGORY_ID
--    Commented out. All translation rows need to be locked.
--      and  userenv('LANG') in (LANGUAGE, SOURCE_LANG)
    for update of CATEGORY_ID nowait;

begin

  open c;
  fetch c into recinfo;
  if (c%notfound) then
    close c;
    fnd_message.set_name('FND', 'FORM_RECORD_DELETED');
    app_exception.raise_exception;
  end if;
  close c;

  if (    (recinfo.STRUCTURE_ID = X_STRUCTURE_ID)
      AND ((recinfo.DISABLE_DATE = X_DISABLE_DATE)
           OR ((recinfo.DISABLE_DATE is null) AND (X_DISABLE_DATE is null)))
--      AND ((recinfo.WEB_STATUS = X_WEB_STATUS)                                                    Bug: 4494727
--           OR ((recinfo.WEB_STATUS is null) AND (X_WEB_STATUS is null)))
      AND ((recinfo.SUPPLIER_ENABLED_FLAG = X_SUPPLIER_ENABLED_FLAG)
           OR ((recinfo.SUPPLIER_ENABLED_FLAG is null) AND (X_SUPPLIER_ENABLED_FLAG is null)))
      AND ((recinfo.SEGMENT1 = X_SEGMENT1)
           OR ((recinfo.SEGMENT1 is null) AND (X_SEGMENT1 is null)))
      AND ((recinfo.SEGMENT2 = X_SEGMENT2)
           OR ((recinfo.SEGMENT2 is null) AND (X_SEGMENT2 is null)))
      AND ((recinfo.SEGMENT3 = X_SEGMENT3)
           OR ((recinfo.SEGMENT3 is null) AND (X_SEGMENT3 is null)))
      AND ((recinfo.SEGMENT4 = X_SEGMENT4)
           OR ((recinfo.SEGMENT4 is null) AND (X_SEGMENT4 is null)))
      AND ((recinfo.SEGMENT5 = X_SEGMENT5)
           OR ((recinfo.SEGMENT5 is null) AND (X_SEGMENT5 is null)))
      AND ((recinfo.SEGMENT6 = X_SEGMENT6)
           OR ((recinfo.SEGMENT6 is null) AND (X_SEGMENT6 is null)))
      AND ((recinfo.SEGMENT7 = X_SEGMENT7)
           OR ((recinfo.SEGMENT7 is null) AND (X_SEGMENT7 is null)))
      AND ((recinfo.SEGMENT8 = X_SEGMENT8)
           OR ((recinfo.SEGMENT8 is null) AND (X_SEGMENT8 is null)))
      AND ((recinfo.SEGMENT9 = X_SEGMENT9)
           OR ((recinfo.SEGMENT9 is null) AND (X_SEGMENT9 is null)))
      AND ((recinfo.SEGMENT10 = X_SEGMENT10)
           OR ((recinfo.SEGMENT10 is null) AND (X_SEGMENT10 is null)))
      AND ((recinfo.SEGMENT11 = X_SEGMENT11)
           OR ((recinfo.SEGMENT11 is null) AND (X_SEGMENT11 is null)))
      AND ((recinfo.SEGMENT12 = X_SEGMENT12)
           OR ((recinfo.SEGMENT12 is null) AND (X_SEGMENT12 is null)))
      AND ((recinfo.SEGMENT13 = X_SEGMENT13)
           OR ((recinfo.SEGMENT13 is null) AND (X_SEGMENT13 is null)))
      AND ((recinfo.SEGMENT14 = X_SEGMENT14)
           OR ((recinfo.SEGMENT14 is null) AND (X_SEGMENT14 is null)))
      AND ((recinfo.SEGMENT15 = X_SEGMENT15)
           OR ((recinfo.SEGMENT15 is null) AND (X_SEGMENT15 is null)))
      AND ((recinfo.SEGMENT16 = X_SEGMENT16)
           OR ((recinfo.SEGMENT16 is null) AND (X_SEGMENT16 is null)))
      AND ((recinfo.SEGMENT17 = X_SEGMENT17)
           OR ((recinfo.SEGMENT17 is null) AND (X_SEGMENT17 is null)))
      AND ((recinfo.SEGMENT18 = X_SEGMENT18)
           OR ((recinfo.SEGMENT18 is null) AND (X_SEGMENT18 is null)))
      AND ((recinfo.SEGMENT19 = X_SEGMENT19)
           OR ((recinfo.SEGMENT19 is null) AND (X_SEGMENT19 is null)))
      AND ((recinfo.SEGMENT20 = X_SEGMENT20)
           OR ((recinfo.SEGMENT20 is null) AND (X_SEGMENT20 is null)))
      AND (recinfo.SUMMARY_FLAG = X_SUMMARY_FLAG)
      AND (recinfo.ENABLED_FLAG = X_ENABLED_FLAG)
      AND ((recinfo.START_DATE_ACTIVE = X_START_DATE_ACTIVE)
           OR ((recinfo.START_DATE_ACTIVE is null) AND (X_START_DATE_ACTIVE is null)))
      AND ((recinfo.END_DATE_ACTIVE = X_END_DATE_ACTIVE)
           OR ((recinfo.END_DATE_ACTIVE is null) AND (X_END_DATE_ACTIVE is null)))
      AND ((recinfo.ATTRIBUTE_CATEGORY = X_ATTRIBUTE_CATEGORY)
           OR ((recinfo.ATTRIBUTE_CATEGORY is null) AND (X_ATTRIBUTE_CATEGORY is null)))
      AND ((recinfo.ATTRIBUTE1 = X_ATTRIBUTE1)
           OR ((recinfo.ATTRIBUTE1 is null) AND (X_ATTRIBUTE1 is null)))
      AND ((recinfo.ATTRIBUTE2 = X_ATTRIBUTE2)
           OR ((recinfo.ATTRIBUTE2 is null) AND (X_ATTRIBUTE2 is null)))
      AND ((recinfo.ATTRIBUTE3 = X_ATTRIBUTE3)
           OR ((recinfo.ATTRIBUTE3 is null) AND (X_ATTRIBUTE3 is null)))
      AND ((recinfo.ATTRIBUTE4 = X_ATTRIBUTE4)
           OR ((recinfo.ATTRIBUTE4 is null) AND (X_ATTRIBUTE4 is null)))
      AND ((recinfo.ATTRIBUTE5 = X_ATTRIBUTE5)
           OR ((recinfo.ATTRIBUTE5 is null) AND (X_ATTRIBUTE5 is null)))
      AND ((recinfo.ATTRIBUTE6 = X_ATTRIBUTE6)
           OR ((recinfo.ATTRIBUTE6 is null) AND (X_ATTRIBUTE6 is null)))
      AND ((recinfo.ATTRIBUTE7 = X_ATTRIBUTE7)
           OR ((recinfo.ATTRIBUTE7 is null) AND (X_ATTRIBUTE7 is null)))
      AND ((recinfo.ATTRIBUTE8 = X_ATTRIBUTE8)
           OR ((recinfo.ATTRIBUTE8 is null) AND (X_ATTRIBUTE8 is null)))
      AND ((recinfo.ATTRIBUTE9 = X_ATTRIBUTE9)
           OR ((recinfo.ATTRIBUTE9 is null) AND (X_ATTRIBUTE9 is null)))
      AND ((recinfo.ATTRIBUTE10 = X_ATTRIBUTE10)
           OR ((recinfo.ATTRIBUTE10 is null) AND (X_ATTRIBUTE10 is null)))
      AND ((recinfo.ATTRIBUTE11 = X_ATTRIBUTE11)
           OR ((recinfo.ATTRIBUTE11 is null) AND (X_ATTRIBUTE11 is null)))
      AND ((recinfo.ATTRIBUTE12 = X_ATTRIBUTE12)
           OR ((recinfo.ATTRIBUTE12 is null) AND (X_ATTRIBUTE12 is null)))
      AND ((recinfo.ATTRIBUTE13 = X_ATTRIBUTE13)
           OR ((recinfo.ATTRIBUTE13 is null) AND (X_ATTRIBUTE13 is null)))
      AND ((recinfo.ATTRIBUTE14 = X_ATTRIBUTE14)
           OR ((recinfo.ATTRIBUTE14 is null) AND (X_ATTRIBUTE14 is null)))
      AND ((recinfo.ATTRIBUTE15 = X_ATTRIBUTE15)
           OR ((recinfo.ATTRIBUTE15 is null) AND (X_ATTRIBUTE15 is null)))
--      AND ((recinfo.WH_UPDATE_DATE = X_WH_UPDATE_DATE)
--           OR ((recinfo.WH_UPDATE_DATE is null) AND (X_WH_UPDATE_DATE is null)))
--      AND ((recinfo.TOTAL_PROD_ID = X_TOTAL_PROD_ID)
--           OR ((recinfo.TOTAL_PROD_ID is null) AND (X_TOTAL_PROD_ID is null)))
--      AND ((recinfo.REQUEST_ID = X_REQUEST_ID)
--           OR ((recinfo.REQUEST_ID is null) AND (X_REQUEST_ID is null)))
  ) then
    null;
  else
    fnd_message.set_name('FND', 'FORM_RECORD_CHANGED');
    app_exception.raise_exception;
  end if;

  for tlinfo in c1 loop
    if (tlinfo.BASELANG = 'Y') then
      if (    ((tlinfo.DESCRIPTION = X_DESCRIPTION)
               OR ((tlinfo.DESCRIPTION is null) AND (X_DESCRIPTION is null)))
      ) then
        null;
      else
        fnd_message.set_name('FND', 'FORM_RECORD_CHANGED');
        app_exception.raise_exception;
      end if;
    end if;
  end loop;

  return;

end LOCK_ROW;


procedure UPDATE_ROW
(
  X_CATEGORY_ID in NUMBER,
  X_DESCRIPTION in VARCHAR2,
  X_STRUCTURE_ID in NUMBER,
  X_DISABLE_DATE in DATE,
  X_WEB_STATUS   in VARCHAR2,
  X_SUPPLIER_ENABLED_FLAG   in VARCHAR2,
  X_SEGMENT1 in VARCHAR2,
  X_SEGMENT2 in VARCHAR2,
  X_SEGMENT3 in VARCHAR2,
  X_SEGMENT4 in VARCHAR2,
  X_SEGMENT5 in VARCHAR2,
  X_SEGMENT6 in VARCHAR2,
  X_SEGMENT7 in VARCHAR2,
  X_SEGMENT8 in VARCHAR2,
  X_SEGMENT9 in VARCHAR2,
  X_SEGMENT10 in VARCHAR2,
  X_SEGMENT11 in VARCHAR2,
  X_SEGMENT12 in VARCHAR2,
  X_SEGMENT13 in VARCHAR2,
  X_SEGMENT14 in VARCHAR2,
  X_SEGMENT15 in VARCHAR2,
  X_SEGMENT16 in VARCHAR2,
  X_SEGMENT17 in VARCHAR2,
  X_SEGMENT18 in VARCHAR2,
  X_SEGMENT19 in VARCHAR2,
  X_SEGMENT20 in VARCHAR2,
  X_SUMMARY_FLAG in VARCHAR2,
  X_ENABLED_FLAG in VARCHAR2,
  X_START_DATE_ACTIVE in DATE,
  X_END_DATE_ACTIVE in DATE,
  X_ATTRIBUTE_CATEGORY in VARCHAR2,
  X_ATTRIBUTE1 in VARCHAR2,
  X_ATTRIBUTE2 in VARCHAR2,
  X_ATTRIBUTE3 in VARCHAR2,
  X_ATTRIBUTE4 in VARCHAR2,
  X_ATTRIBUTE5 in VARCHAR2,
  X_ATTRIBUTE6 in VARCHAR2,
  X_ATTRIBUTE7 in VARCHAR2,
  X_ATTRIBUTE8 in VARCHAR2,
  X_ATTRIBUTE9 in VARCHAR2,
  X_ATTRIBUTE10 in VARCHAR2,
  X_ATTRIBUTE11 in VARCHAR2,
  X_ATTRIBUTE12 in VARCHAR2,
  X_ATTRIBUTE13 in VARCHAR2,
  X_ATTRIBUTE14 in VARCHAR2,
  X_ATTRIBUTE15 in VARCHAR2,
  X_LAST_UPDATE_DATE in DATE,
  X_LAST_UPDATED_BY in NUMBER,
  X_LAST_UPDATE_LOGIN in NUMBER
--  X_REQUEST_ID in NUMBER,
)
IS
   l_return_status            VARCHAR2(1);
   l_msg_count                NUMBER;
   l_msg_data                 VARCHAR2(2000);
BEGIN

  update MTL_CATEGORIES_B
  set
    STRUCTURE_ID = X_STRUCTURE_ID,
    DISABLE_DATE = X_DISABLE_DATE,
    WEB_STATUS   = X_WEB_STATUS,
    SUPPLIER_ENABLED_FLAG   = X_SUPPLIER_ENABLED_FLAG,
    SEGMENT1 = X_SEGMENT1,
    SEGMENT2 = X_SEGMENT2,
    SEGMENT3 = X_SEGMENT3,
    SEGMENT4 = X_SEGMENT4,
    SEGMENT5 = X_SEGMENT5,
    SEGMENT6 = X_SEGMENT6,
    SEGMENT7 = X_SEGMENT7,
    SEGMENT8 = X_SEGMENT8,
    SEGMENT9 = X_SEGMENT9,
    SEGMENT10 = X_SEGMENT10,
    SEGMENT11 = X_SEGMENT11,
    SEGMENT12 = X_SEGMENT12,
    SEGMENT13 = X_SEGMENT13,
    SEGMENT14 = X_SEGMENT14,
    SEGMENT15 = X_SEGMENT15,
    SEGMENT16 = X_SEGMENT16,
    SEGMENT17 = X_SEGMENT17,
    SEGMENT18 = X_SEGMENT18,
    SEGMENT19 = X_SEGMENT19,
    SEGMENT20 = X_SEGMENT20,
    SUMMARY_FLAG = X_SUMMARY_FLAG,
    ENABLED_FLAG = X_ENABLED_FLAG,
    START_DATE_ACTIVE = X_START_DATE_ACTIVE,
    END_DATE_ACTIVE = X_END_DATE_ACTIVE,
    ATTRIBUTE_CATEGORY = X_ATTRIBUTE_CATEGORY,
    ATTRIBUTE1 = X_ATTRIBUTE1,
    ATTRIBUTE2 = X_ATTRIBUTE2,
    ATTRIBUTE3 = X_ATTRIBUTE3,
    ATTRIBUTE4 = X_ATTRIBUTE4,
    ATTRIBUTE5 = X_ATTRIBUTE5,
    ATTRIBUTE6 = X_ATTRIBUTE6,
    ATTRIBUTE7 = X_ATTRIBUTE7,
    ATTRIBUTE8 = X_ATTRIBUTE8,
    ATTRIBUTE9 = X_ATTRIBUTE9,
    ATTRIBUTE10 = X_ATTRIBUTE10,
    ATTRIBUTE11 = X_ATTRIBUTE11,
    ATTRIBUTE12 = X_ATTRIBUTE12,
    ATTRIBUTE13 = X_ATTRIBUTE13,
    ATTRIBUTE14 = X_ATTRIBUTE14,
    ATTRIBUTE15 = X_ATTRIBUTE15,
--    WH_UPDATE_DATE = X_WH_UPDATE_DATE,
--    TOTAL_PROD_ID = X_TOTAL_PROD_ID,
--    REQUEST_ID = X_REQUEST_ID,
    LAST_UPDATE_DATE = X_LAST_UPDATE_DATE,
    LAST_UPDATED_BY = X_LAST_UPDATED_BY,
    LAST_UPDATE_LOGIN = X_LAST_UPDATE_LOGIN
  where
     CATEGORY_ID = X_CATEGORY_ID;

  if ( sql%notfound ) then
    raise no_data_found;
  end if;

  update MTL_CATEGORIES_TL
  set
    DESCRIPTION = X_DESCRIPTION,
    LAST_UPDATE_DATE = X_LAST_UPDATE_DATE,
    LAST_UPDATED_BY = X_LAST_UPDATED_BY,
    LAST_UPDATE_LOGIN = X_LAST_UPDATE_LOGIN,
    SOURCE_LANG = userenv('LANG')
  where
         CATEGORY_ID = X_CATEGORY_ID
     and userenv('LANG') in (LANGUAGE, SOURCE_LANG);

  if ( sql%notfound ) then
    raise no_data_found;
  end if;

   --Bug: 2718703 checking for ENI product before calling their package
   --
   -- Sync category segments with item record in STAR.
   --
   IF ( INV_Item_Util.g_Appl_Inst.ENI <> 0 ) THEN

     EXECUTE IMMEDIATE  
      ' BEGIN                                                           '||
      '    ENI_ITEMS_STAR_PKG.Update_Categories                         '||
      '    (                                                            '||
      '      p_api_version         =>  1.0                              '||
      '   ,  p_init_msg_list       =>  FND_API.g_TRUE                   '||
      '   ,  p_category_id         =>  :X_CATEGORY_ID                   '||
      '   ,  p_structure_id        =>  :X_STRUCTURE_ID                  '||
      '   ,  x_return_status       =>  :l_return_status                 '||
      '   ,  x_msg_count           =>  :l_msg_count                     '||
      '   ,  x_msg_data            =>  :l_msg_data                      '||
      '   );                                                            '||
      ' END;'
     USING IN X_CATEGORY_ID, IN X_STRUCTURE_ID, OUT l_return_Status, OUT l_msg_count, OUT l_msg_data;

     IF ( l_return_status = FND_API.g_RET_STS_ERROR ) THEN         
        FND_MESSAGE.Set_Encoded (l_msg_data);                       
        APP_EXCEPTION.Raise_Exception;                              
     ELSIF ( l_return_status = FND_API.g_RET_STS_UNEXP_ERROR ) THEN
        FND_MESSAGE.Set_Encoded (l_msg_data);                       
        APP_EXCEPTION.Raise_Exception;                               
     END IF;                                                       
   
   END IF; 

   IF x_structure_id=201 THEN   -- Retrofitted for R12.2.5


     IF X_segment1='NA' and X_segment2='TRADE' THEN
        NULL;
     ELSE
       --R12: Raise Business Events and Call APIs
       BEGIN
         INV_ITEM_EVENTS_PVT.Raise_Events(
            p_event_name    => 'EGO_WF_WRAPPER_PVT.G_CAT_CATEGORY_CHANGE_EVENT'
           ,p_dml_type      => 'UPDATE'
           ,p_category_id   =>  X_CATEGORY_ID);
       EXCEPTION
         WHEN OTHERS THEN
           NULL;
       END;

       --Call ICX APIs
       BEGIN
         INV_ITEM_EVENTS_PVT.Invoke_ICX_APIs(
           p_entity_type   => 'CATEGORY'
          ,p_dml_type      => 'UPDATE'
          ,p_category_id   => X_CATEGORY_ID
          ,p_structure_id  => X_STRUCTURE_ID);
       EXCEPTION
          WHEN OTHERS THEN
             NULL;
       END;
       --R12: Business Event Enhancement:
     END IF;
   ELSE   --IF x_structure_id=201 THEN

    --R12: Raise Business Events and Call APIs
    BEGIN
      INV_ITEM_EVENTS_PVT.Raise_Events(
          p_event_name    => 'EGO_WF_WRAPPER_PVT.G_CAT_CATEGORY_CHANGE_EVENT'
         ,p_dml_type      => 'UPDATE'
         ,p_category_id   =>  X_CATEGORY_ID);
    EXCEPTION
         WHEN OTHERS THEN
            NULL;
    END;

    --Call ICX APIs
    BEGIN
      INV_ITEM_EVENTS_PVT.Invoke_ICX_APIs(
           p_entity_type   => 'CATEGORY'
          ,p_dml_type      => 'UPDATE'
          ,p_category_id   => X_CATEGORY_ID
          ,p_structure_id  => X_STRUCTURE_ID);
    EXCEPTION
          WHEN OTHERS THEN
             NULL;
    END;
    --R12: Business Event Enhancement:
   END IF;

end UPDATE_ROW;

-- ----------------------------------------------------------------------
-- Deletion of categories is not supported.
-- ----------------------------------------------------------------------

procedure DELETE_ROW (
  X_CATEGORY_ID in NUMBER
) is
begin

/*
  fnd_message.set_name('INV', 'CANNOT_DELETE_RECORD');
  app_exception.raise_exception;
*/
  raise_application_error( -20000, 'CANNOT_DELETE_RECORD' );

-- This code is for future use when decided to validate
-- and delete categories.
/*
  delete from MTL_CATEGORIES_TL
  where  CATEGORY_ID = X_CATEGORY_ID ;

  if (sql%notfound) then
    raise no_data_found;
  end if;

  delete from MTL_CATEGORIES_B
  where  CATEGORY_ID = X_CATEGORY_ID ;

  if (sql%notfound) then
    raise no_data_found;
  end if;
*/

end DELETE_ROW;


procedure ADD_LANGUAGE
is
begin

  delete from MTL_CATEGORIES_TL T
  where  not exists
         ( select NULL
           from  MTL_CATEGORIES_B  B
           where  B.CATEGORY_ID = T.CATEGORY_ID
         );

  update MTL_CATEGORIES_TL T set (
      DESCRIPTION
    ) = ( select
      B.DESCRIPTION
    from  MTL_CATEGORIES_TL  B
    where  B.CATEGORY_ID = T.CATEGORY_ID
      and  B.LANGUAGE = T.SOURCE_LANG )
  where (
      T.CATEGORY_ID,
      T.LANGUAGE
  ) in ( select
      SUBT.CATEGORY_ID,
      SUBT.LANGUAGE
    from  MTL_CATEGORIES_TL  SUBB,
          MTL_CATEGORIES_TL  SUBT
    where  SUBB.CATEGORY_ID = SUBT.CATEGORY_ID
      and  SUBB.LANGUAGE = SUBT.SOURCE_LANG
      and  ( SUBB.DESCRIPTION <> SUBT.DESCRIPTION
           or ( SUBB.DESCRIPTION is null     and SUBT.DESCRIPTION is not null )
           or ( SUBB.DESCRIPTION is not null and SUBT.DESCRIPTION is null ) )
    );

  insert into MTL_CATEGORIES_TL (
    CREATED_BY,
    LAST_UPDATE_LOGIN,
    CATEGORY_ID,
    DESCRIPTION,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY,
    CREATION_DATE,
    LANGUAGE,
    SOURCE_LANG
  ) select 
    B.CREATED_BY,
    B.LAST_UPDATE_LOGIN,
    B.CATEGORY_ID,
    B.DESCRIPTION,
    B.LAST_UPDATE_DATE,
    B.LAST_UPDATED_BY,
    B.CREATION_DATE,
    L.LANGUAGE_CODE,
    B.SOURCE_LANG
  from  MTL_CATEGORIES_TL  B,
        FND_LANGUAGES      L
  where  L.INSTALLED_FLAG in ('I', 'B')
    and  B.LANGUAGE = userenv('LANG')
    and  not exists
         ( select NULL
           from  MTL_CATEGORIES_TL  T
           where  T.CATEGORY_ID = B.CATEGORY_ID
             and  T.LANGUAGE = L.LANGUAGE_CODE );

end ADD_LANGUAGE;


-- ----------------------------------------------------------------------
-- PROCEDURE:  Translate_Row        PUBLIC
--
-- PARAMETERS:
--  x_<developer key>
--  x_<translated columns>
--  x_owner             user owning the row (SEED or other)
--
-- COMMENT:
--  Called from the FNDLOAD config file in 'NLS' mode to upload
--  translations.
-- ----------------------------------------------------------------------

PROCEDURE Translate_Row
(
   x_category_name              IN  VARCHAR2
,  x_structure_code             IN  VARCHAR2 --Bug 6975120
,  x_description                IN  VARCHAR2
,  x_owner                      IN  VARCHAR2
,  x_upload_to_functional_area  IN  VARCHAR2
,  x_application_short_name     IN  VARCHAR2
)
IS
f_luby    number;  -- entity owner in file
l_category_id     NUMBER;
l_structure_id    NUMBER;

BEGIN 
     -- Translate owner to file_last_updated_by
     f_luby := fnd_load_util.owner_id(x_owner);

    -- **********************************
    -- Get the correct structure based on the parameter passed in
    -- upload_to_product_rpt. If it is "Y", then the structure
    -- should be the structure of the default category set of
    -- product reporting functional area. Else it will be the 
    -- structure of the downloaded category
    -- **********************************

    BEGIN

      IF x_upload_to_functional_area <> '-1' THEN
         SELECT B.STRUCTURE_ID
           INTO l_structure_id
           FROM MTL_DEFAULT_CATEGORY_SETS A,
                MTL_CATEGORY_SETS_B B
          WHERE FUNCTIONAL_AREA_ID = (select lookup_code from mfg_lookups
                                     where lookup_type = 'MTL_FUNCTIONAL_AREAS'                         and upper(meaning) = upper(x_upload_to_functional_area))
            AND A.CATEGORY_SET_ID = B.CATEGORY_SET_ID;
      ELSE 
         SELECT ID_FLEX_NUM
         INTO l_structure_id
         FROM FND_ID_FLEX_STRUCTURES
        WHERE APPLICATION_ID = (select application_id from fnd_application
                                 where application_short_name = 
                                       x_application_short_name)
          AND ID_FLEX_CODE = 'MCAT'
          AND ID_FLEX_STRUCTURE_CODE = x_structure_code; /* Bug 6975120
	  Replacing x_structure_name with x_structure_code 
          AND LANGUAGE = 'US';  -- userenv('LANG');     Bug 6859576 */
      END IF;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       fnd_message.set_name('FND','GENERIC-INTERNAL ERROR');
       fnd_message.set_token('ROUTINE','Category Migration');
       IF x_upload_to_functional_area = 'Y' THEN
         fnd_message.set_token('REASON','Default category set for ' || x_upload_to_functional_area || ' functional area does not exist');
       ELSE
         fnd_message.set_token('REASON','Flex structure does not exist');
       END IF;
       app_exception.raise_exception;
    END;

   -- find out the category_id based on the structure_id and the concat segments
   BEGIN
      SELECT category_id
        INTO l_category_id
        FROM mtl_categories_kfv
       WHERE structure_id = l_structure_id
         AND concatenated_segments = x_category_name;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       fnd_message.set_name('FND','GENERIC-INTERNAL ERROR');
       fnd_message.set_token('ROUTINE','Category Migration');
       fnd_message.set_token('REASON','Category does not exist');
       app_exception.raise_exception;
    END;

  UPDATE mtl_categories_tl
    SET description       = NVL(x_description, description)
      , last_update_date  = SYSDATE
      , last_updated_by   = f_luby
      , last_update_login = 0
      , source_lang       = userenv('LANG')
    WHERE category_id = l_category_id
      AND userenv('LANG') IN (language, source_lang);

  IF ( SQL%NOTFOUND ) THEN
     RAISE no_data_found;
  END IF;

END Translate_Row;

-- ----------------------------------------------------------------------
-- PROCEDURE:  Load_Row        PUBLIC
--
-- PARAMETERS:
--  x_<developer key>
--  x_<columns>
--  x_owner             user owning the row (SEED or other)
--
-- COMMENT:
--  Called from the FNDLOAD config file to upload Categories
-- ----------------------------------------------------------------------

PROCEDURE Load_Row
(
   x_CATEGORY_NAME          IN    MTL_CATEGORIES_KFV.CONCATENATED_SEGMENTS%TYPE
  ,x_STRUCTURE_CODE         IN    FND_ID_FLEX_STRUCTURES.ID_FLEX_STRUCTURE_CODE%TYPE  --BUG 6975120
  ,X_SEGMENT1               IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT2               IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT3               IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT4               IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT5               IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT6               IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT7               IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT8               IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT9               IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT10              IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT11              IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT12              IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT13              IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT14              IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT15              IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT16              IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT17              IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT18              IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT19              IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SEGMENT20              IN    MTL_CATEGORIES_B.SEGMENT1%TYPE
  ,X_SUMMARY_FLAG           IN    MTL_CATEGORIES_B.SUMMARY_FLAG%TYPE 
  ,X_ENABLED_FLAG           IN    MTL_CATEGORIES_B.ENABLED_FLAG%TYPE   
  ,X_START_DATE_ACTIVE      IN    MTL_CATEGORIES_B.START_DATE_ACTIVE%TYPE
  ,X_END_DATE_ACTIVE        IN    MTL_CATEGORIES_B.END_DATE_ACTIVE%TYPE  
  ,X_DISABLE_DATE           IN    MTL_CATEGORIES_B.DISABLE_DATE%TYPE     
  ,X_CATEGORY_SET_ID        IN    MTL_CATEGORY_SETS_B.CATEGORY_SET_ID%TYPE
  ,X_CATEGORY_SET_NAME      IN    MTL_CATEGORY_SETS_TL.CATEGORY_SET_NAME%TYPE
  ,X_OWNER                  IN    VARCHAR2
  ,X_LAST_UPDATE_DATE       IN    MTL_CATEGORIES_B.LAST_UPDATE_DATE%TYPE
  ,X_DESCRIPTION            IN    MTL_CATEGORIES_TL.DESCRIPTION%TYPE     
  ,X_APPLICATION_SHORT_NAME IN    VARCHAR2
  ,X_UPLOAD_TO_FUNCTIONAL_AREA  IN    VARCHAR2
) IS

    l_category_set_id  MTL_CATEGORY_SETS_B.CATEGORY_SET_ID%TYPE;
    l_structure_id     MTL_CATEGORY_SETS_B.STRUCTURE_ID%TYPE;
    l_category_id      MTL_CATEGORIES_B.CATEGORY_ID%TYPE;
    l_category_rec     INV_ITEM_CATEGORY_PUB.CATEGORY_REC_TYPE;
    l_new_catg_id      NUMBER;
    l_category_set_name MTL_CATEGORY_SETS_TL.CATEGORY_SET_NAME%TYPE := X_CATEGORY_SET_NAME ;
    l_return_status     VARCHAR2(1);
    l_errorcode         VARCHAR2(10);
    l_msg_count         NUMBER;
    l_msg_data          VARCHAR2(2000);
    l_messages          VARCHAR2(32000) :='';
    l_segment_array     FND_FLEX_EXT.SegmentArray;
    l_n_segments        NUMBER := 0 ;
    l_delim             VARCHAR2(10);
    l_success           BOOLEAN;
    l_concat_segs       VARCHAR2(2000) ;
    l_flex_status       NUMBER;
    err_text            VARCHAR2(2000);

    CURSOR get_segments(l_structure_id NUMBER) is
       SELECT application_column_name,rownum
       FROM   fnd_id_flex_segments
       WHERE  application_id = (select application_id from fnd_application
                                 where application_short_name = 
                                         x_application_short_name)
         AND  id_flex_code = 'MCAT'
         AND  id_flex_num  = l_structure_id
         AND  enabled_flag = 'Y'
       ORDER BY segment_num ASC;

    /*CURSOR get_category_id(cp_structure_id      NUMBER
                          ,cp_concatenated_segs VARCHAR2) IS
     SELECT CATEGORY_ID 
     FROM MTL_CATEGORIES_B_KFV
     WHERE structure_id          = cp_structure_id 
     AND   CONCATENATED_SEGMENTS = cp_concatenated_segs;*/

  begin  

     l_return_status := FND_API.G_RET_STS_SUCCESS;

    -- **********************************
    -- Get the correct structure based on the parameter passed in
    -- upload_to_functional_area. If the later is passed as an argument,
    -- then the structure should be the structure of the default 
    -- category set of the functional area passed. Else it will be the 
    -- structure of the downloaded category 
    -- **********************************

    BEGIN

      IF x_upload_to_functional_area <> '-1' THEN
         SELECT A.CATEGORY_SET_ID, B.STRUCTURE_ID
           INTO l_category_set_id, l_structure_id
           FROM MTL_DEFAULT_CATEGORY_SETS A, 
                MTL_CATEGORY_SETS B
          WHERE FUNCTIONAL_AREA_ID = (select lookup_code from mfg_lookups
                                     where lookup_type = 'MTL_FUNCTIONAL_AREAS'
                        and upper(meaning) = upper(x_upload_to_functional_area))
            AND A.CATEGORY_SET_ID = B.CATEGORY_SET_ID;
      ELSE
         SELECT ID_FLEX_NUM
           INTO l_structure_id
           FROM FND_ID_FLEX_STRUCTURES
          WHERE APPLICATION_ID = (select application_id from fnd_application
                                   where application_short_name =
                                         x_application_short_name)
            AND ID_FLEX_CODE = 'MCAT'
            AND ID_FLEX_STRUCTURE_CODE = x_structure_code;
	    /*Bug 6975120 Replacing the x_structure_name with x_structure_code
            AND LANGUAGE = userenv('LANG'); */
	    
       END IF;

    EXCEPTION 
     WHEN NO_DATA_FOUND THEN
       fnd_message.set_name('FND','GENERIC-INTERNAL ERROR');
       fnd_message.set_token('ROUTINE','Category Migration');
       if x_upload_to_functional_area = '-1' then
          fnd_message.set_token('REASON','Default category set for ' || x_upload_to_functional_area || ' does not exist ');
       else
          fnd_message.set_token('REASON','Flex structure does not exist ');
       end if;
       app_exception.raise_exception; 
    END;

    -- IF (l_category_set_id IS NOT NULL)
    -- THEN
      -- Initialize the recrod 
      l_category_rec.STRUCTURE_ID        := l_structure_id ;
      l_category_rec.SEGMENT1            := null;
      l_category_rec.SEGMENT2            := null; 
      l_category_rec.SEGMENT3            := null;
      l_category_rec.SEGMENT4            := null;
      l_category_rec.SEGMENT5            := null;
      l_category_rec.SEGMENT6            := null;
      l_category_rec.SEGMENT7            := null;
      l_category_rec.SEGMENT8            := null;
      l_category_rec.SEGMENT9            := null;
      l_category_rec.SEGMENT10           := null;
      l_category_rec.SEGMENT11           := null;
      l_category_rec.SEGMENT12           := null;
      l_category_rec.SEGMENT13           := null;
      l_category_rec.SEGMENT14           := null;
      l_category_rec.SEGMENT15           := null;
      l_category_rec.SEGMENT16           := null;
      l_category_rec.SEGMENT17           := null;
      l_category_rec.SEGMENT18           := null;
      l_category_rec.SEGMENT19           := null;
      l_category_rec.SEGMENT20           := null;
      l_category_rec.SUMMARY_FLAG        := X_SUMMARY_FLAG ;
      l_category_rec.ENABLED_FLAG        := X_ENABLED_FLAG ;
      l_category_rec.START_DATE_ACTIVE   := X_START_DATE_ACTIVE ;
      l_category_rec.END_DATE_ACTIVE     := X_END_DATE_ACTIVE ;
      l_category_rec.DISABLE_DATE        := X_DISABLE_DATE ; 
      l_category_rec.DESCRIPTION         := X_DESCRIPTION  ;

      l_category_rec.WEB_STATUS          := null;     -- Bug #8463906, to avoid saving  chr(0)  into web_status
      l_category_rec.SUPPLIER_ENABLED_FLAG  := null;     -- Bug #8463906, to avoid saving  chr(0)  into SUPPLIER_ENABLED_FLAG

      -- Looping through the enabled segments in the target instance
      -- and setting the values for only those segments those are enabled

      FOR c_segments in get_segments(l_structure_id) LOOP
        l_n_segments := c_segments.rownum;
        IF c_segments.application_column_name = 'SEGMENT1' THEN 
           l_category_rec.SEGMENT1 := X_SEGMENT1; 
           l_segment_array(c_segments.rownum):= X_SEGMENT1;
        ELSIF c_segments.application_column_name = 'SEGMENT2' THEN 
           l_category_rec.SEGMENT2 := X_SEGMENT2; 
           l_segment_array(c_segments.rownum):= X_SEGMENT2;
        ELSIF c_segments.application_column_name = 'SEGMENT3' THEN 
           l_category_rec.SEGMENT3 := X_SEGMENT3; 
           l_segment_array(c_segments.rownum):= X_SEGMENT3;
        ELSIF c_segments.application_column_name = 'SEGMENT4' THEN 
           l_category_rec.SEGMENT4 := X_SEGMENT4; 
           l_segment_array(c_segments.rownum):= X_SEGMENT4;
        ELSIF c_segments.application_column_name = 'SEGMENT5' THEN 
           l_category_rec.SEGMENT5 := X_SEGMENT5; 
           l_segment_array(c_segments.rownum):= X_SEGMENT5;
        ELSIF c_segments.application_column_name = 'SEGMENT6' THEN 
           l_category_rec.SEGMENT6 := X_SEGMENT6; 
           l_segment_array(c_segments.rownum):= X_SEGMENT6;
        ELSIF c_segments.application_column_name = 'SEGMENT7' THEN 
           l_category_rec.SEGMENT7 := X_SEGMENT7; 
           l_segment_array(c_segments.rownum):= X_SEGMENT7;
        ELSIF c_segments.application_column_name = 'SEGMENT8' THEN 
           l_category_rec.SEGMENT8 := X_SEGMENT8; 
           l_segment_array(c_segments.rownum):= X_SEGMENT8;
        ELSIF c_segments.application_column_name = 'SEGMENT9' THEN 
           l_category_rec.SEGMENT9 := X_SEGMENT9; 
           l_segment_array(c_segments.rownum):= X_SEGMENT9;
        ELSIF c_segments.application_column_name = 'SEGMENT10' THEN 
           l_category_rec.SEGMENT10 := X_SEGMENT10; 
           l_segment_array(c_segments.rownum):= X_SEGMENT10;
        ELSIF c_segments.application_column_name = 'SEGMENT11' THEN 
           l_category_rec.SEGMENT11 := X_SEGMENT11; 
           l_segment_array(c_segments.rownum):= X_SEGMENT11;
        ELSIF c_segments.application_column_name = 'SEGMENT12' THEN 
           l_category_rec.SEGMENT12 := X_SEGMENT12; 
           l_segment_array(c_segments.rownum):= X_SEGMENT12;
        ELSIF c_segments.application_column_name = 'SEGMENT13' THEN 
           l_category_rec.SEGMENT13 := X_SEGMENT13; 
           l_segment_array(c_segments.rownum):= X_SEGMENT13;
        ELSIF c_segments.application_column_name = 'SEGMENT14' THEN 
           l_category_rec.SEGMENT14 := X_SEGMENT14; 
           l_segment_array(c_segments.rownum):= X_SEGMENT14;
        ELSIF c_segments.application_column_name = 'SEGMENT15' THEN 
           l_category_rec.SEGMENT15 := X_SEGMENT15; 
           l_segment_array(c_segments.rownum):= X_SEGMENT15;
        ELSIF c_segments.application_column_name = 'SEGMENT16' THEN 
           l_category_rec.SEGMENT16 := X_SEGMENT16; 
           l_segment_array(c_segments.rownum):= X_SEGMENT16;
        ELSIF c_segments.application_column_name = 'SEGMENT17' THEN 
           l_category_rec.SEGMENT17 := X_SEGMENT17; 
           l_segment_array(c_segments.rownum):= X_SEGMENT17;
        ELSIF c_segments.application_column_name = 'SEGMENT18' THEN 
           l_category_rec.SEGMENT18 := X_SEGMENT18; 
           l_segment_array(c_segments.rownum):= X_SEGMENT18;
        ELSIF c_segments.application_column_name = 'SEGMENT19' THEN 
           l_category_rec.SEGMENT19 := X_SEGMENT19; 
           l_segment_array(c_segments.rownum):= X_SEGMENT19;
        ELSIF c_segments.application_column_name = 'SEGMENT20' THEN 
           l_category_rec.SEGMENT20 := X_SEGMENT20; 
           l_segment_array(c_segments.rownum):= X_SEGMENT20;
        END IF;
      END LOOP; -- loop to get all the enabled segments in the target inst.

      l_delim       := fnd_flex_ext.get_delimiter('INV','MCAT',l_structure_id);

      l_concat_segs := fnd_flex_ext.concatenate_segments(l_n_segments,
			      				 l_segment_array,
							 l_delim);
      l_success  :=   fnd_flex_keyval.validate_segs(
				operation        => 'FIND_COMBINATION',
                                appl_short_name  => 'INV',
                                key_flex_code    => 'MCAT',
                                structure_number => l_structure_id,
                                concat_segments  => l_concat_segs);   
   
      IF (NOT l_success ) THEN

       -- First check if the category is disabled as of sysdate
       -- If it is, then ignore creating the category
       IF ((X_DISABLE_DATE is null OR X_DISABLE_DATE <> '') OR
           (X_DISABLE_DATE is not null AND X_DISABLE_DATE >  SYSDATE)) THEN

          -- Create a Category record
         INV_ITEM_CATEGORY_PUB.Create_Category (
                P_API_VERSION     => 1.0,
                P_INIT_MSG_LIST   => FND_API.G_FALSE,
                P_COMMIT          => FND_API.G_FALSE,
                X_RETURN_STATUS   => l_return_status ,
                X_ERRORCODE       => l_errorcode,
                X_MSG_COUNT       => l_msg_count ,
                X_MSG_DATA        => l_msg_data ,
                P_CATEGORY_REC    => l_category_rec,
                X_CATEGORY_ID     => l_new_catg_id ) ;

       ELSE
         FND_MESSAGE.SET_NAME('FND','GENERIC-INTERNAL ERROR');
         FND_MESSAGE.SET_TOKEN('ROUTINE','Category Migration');
         FND_MESSAGE.SET_TOKEN('REASON','Disabled category cannot be created');
       END IF; -- IF (DISABLE_DATE > SYSDATE) THEN  

     ELSE

        --Bug 7659277 
          --There is a chance that mtl_categories_b_kfv is not
          --prepared before this code runs.
          --hence using INVPUOPI.mtl_pr_parse_flex_name to get 
          --the category id.
        /*OPEN get_category_id(l_structure_id,l_concat_segs);
        FETCH get_category_id INTO l_category_id;
        CLOSE get_category_id;*/
        l_flex_status := INVPUOPI.mtl_pr_parse_flex_name (
                            0,
                            'MCAT',
                            l_concat_segs,
                            l_category_id,
                            X_CATEGORY_SET_ID,
                            err_text,
                            l_structure_id); /*Added l_structure_id for bug 8288281*/
        IF(l_flex_status <> 0)
        THEN
          FND_MESSAGE.SET_NAME('FND','GENERIC-INTERNAL ERROR');
          FND_MESSAGE.SET_TOKEN('ROUTINE','Category Migration');
          FND_MESSAGE.SET_TOKEN('REASON','Category to be updated not found.');
          RAISE fnd_api.g_EXC_UNEXPECTED_ERROR;
        END IF;


        l_category_rec.CATEGORY_ID       := l_category_id ;

        INV_ITEM_CATEGORY_PUB.Update_Category (
                P_API_VERSION => 1.0,
                P_INIT_MSG_LIST  => FND_API.G_FALSE,
                P_COMMIT         => FND_API.G_FALSE,
                X_RETURN_STATUS  => l_return_status,
                X_ERRORCODE      => l_errorcode,
                X_MSG_COUNT      => l_msg_count,
                X_MSG_DATA       => l_msg_data,
                P_CATEGORY_REC   => l_category_rec  );

    END IF;
    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS)
    THEN
      FND_MSG_PUB.COUNT_AND_GET (
                   p_encoded  => 'F'
                 , p_count    => l_msg_count
                 , p_data     => l_msg_data);
      FOR K IN 1 .. l_msg_count LOOP
        l_messages := l_messages || fnd_msg_pub.get( p_msg_index => k, p_encoded => 'F') || ';';
      END LOOP;
      FND_MESSAGE.SET_NAME('FND','GENERIC-INTERNAL ERROR');
      FND_MESSAGE.SET_TOKEN('ROUTINE','Category Migration');
      FND_MESSAGE.SET_TOKEN('REASON',l_messages);
      APP_EXCEPTION.RAISE_EXCEPTION;
    END IF;
 --  END IF;
 END Load_Row;

end MTL_CATEGORIES_PKG;
/

--  show errors package body MTL_CATEGORIES_PKG

commit;
 exit;
