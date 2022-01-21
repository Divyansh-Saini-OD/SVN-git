create or replace package body XX_SP_FND_RESPONSIBILITY_PKG as

procedure UPDATE_ROW (
  X_RESPONSIBILITY_ID in NUMBER,
  X_APPLICATION_ID in NUMBER,
  X_WEB_HOST_NAME in VARCHAR2,
  X_WEB_AGENT_NAME in VARCHAR2,
  X_DATA_GROUP_APPLICATION_ID in NUMBER,
  X_DATA_GROUP_ID in NUMBER,
  X_MENU_ID in NUMBER,
  X_START_DATE in DATE,
  X_END_DATE in DATE,
  X_GROUP_APPLICATION_ID in NUMBER,
  X_REQUEST_GROUP_ID in NUMBER,
  X_VERSION in VARCHAR2,
  X_RESPONSIBILITY_KEY in VARCHAR2,
  X_RESPONSIBILITY_NAME in VARCHAR2,
  X_DESCRIPTION in VARCHAR2,
  X_LAST_UPDATE_DATE in DATE,
  X_LAST_UPDATED_BY in NUMBER,
  X_LAST_UPDATE_LOGIN in NUMBER
) is
begin
	FND_RESPONSIBILITY_PKG.UPDATE_ROW (
  X_RESPONSIBILITY_ID => X_RESPONSIBILITY_ID,
  X_APPLICATION_ID => X_APPLICATION_ID,
  X_WEB_HOST_NAME => X_WEB_HOST_NAME,
  X_WEB_AGENT_NAME => X_WEB_AGENT_NAME,
  X_DATA_GROUP_APPLICATION_ID => X_DATA_GROUP_APPLICATION_ID,
  X_DATA_GROUP_ID => X_DATA_GROUP_ID,
  X_MENU_ID => X_MENU_ID,
  X_START_DATE => X_START_DATE,
  X_END_DATE => X_END_DATE,
  X_GROUP_APPLICATION_ID => X_GROUP_APPLICATION_ID,
  X_REQUEST_GROUP_ID => X_REQUEST_GROUP_ID,
  X_VERSION => X_VERSION,
  X_RESPONSIBILITY_KEY => X_RESPONSIBILITY_KEY,
  X_RESPONSIBILITY_NAME => X_RESPONSIBILITY_NAME,
  X_DESCRIPTION => X_DESCRIPTION,
  X_LAST_UPDATE_DATE => X_LAST_UPDATE_DATE,
  X_LAST_UPDATED_BY => X_LAST_UPDATED_BY,
  X_LAST_UPDATE_LOGIN => X_LAST_UPDATE_LOGIN);

end UPDATE_ROW;

procedure INSERT_ROW (
  X_ROWID in out nocopy VARCHAR2,
  X_RESPONSIBILITY_ID in NUMBER,
  X_APPLICATION_ID in NUMBER,
  X_WEB_HOST_NAME in VARCHAR2,
  X_WEB_AGENT_NAME in VARCHAR2,
  X_DATA_GROUP_APPLICATION_ID in NUMBER,
  X_DATA_GROUP_ID in NUMBER,
  X_MENU_ID in NUMBER,
  X_START_DATE in DATE,
  X_END_DATE in DATE,
  X_GROUP_APPLICATION_ID in NUMBER,
  X_REQUEST_GROUP_ID in NUMBER,
  X_VERSION in VARCHAR2,
  X_RESPONSIBILITY_KEY in VARCHAR2,
  X_RESPONSIBILITY_NAME in VARCHAR2,
  X_DESCRIPTION in VARCHAR2,
  X_CREATION_DATE in DATE,
  X_CREATED_BY in NUMBER,
  X_LAST_UPDATE_DATE in DATE,
  X_LAST_UPDATED_BY in NUMBER,
  X_LAST_UPDATE_LOGIN in NUMBER
) is
 
begin

FND_RESPONSIBILITY_PKG.INSERT_ROW (
  X_ROWID => X_ROWID,
  X_RESPONSIBILITY_ID => X_RESPONSIBILITY_ID,
  X_APPLICATION_ID => X_APPLICATION_ID,
  X_WEB_HOST_NAME => X_WEB_HOST_NAME,
  X_WEB_AGENT_NAME => X_WEB_AGENT_NAME,
  X_DATA_GROUP_APPLICATION_ID => X_DATA_GROUP_APPLICATION_ID,
  X_DATA_GROUP_ID => X_DATA_GROUP_ID,
  X_MENU_ID => X_MENU_ID,
  X_START_DATE => X_START_DATE,
  X_END_DATE => X_END_DATE,
  X_GROUP_APPLICATION_ID => X_GROUP_APPLICATION_ID,
  X_REQUEST_GROUP_ID => X_REQUEST_GROUP_ID,
  X_VERSION => X_VERSION,
  X_RESPONSIBILITY_KEY => X_RESPONSIBILITY_KEY,
  X_RESPONSIBILITY_NAME => X_RESPONSIBILITY_NAME,
  X_DESCRIPTION => X_DESCRIPTION,
  X_CREATION_DATE => X_CREATION_DATE,
  X_CREATED_BY => X_CREATED_BY,
  X_LAST_UPDATE_DATE => X_LAST_UPDATE_DATE,
  X_LAST_UPDATED_BY => X_LAST_UPDATED_BY,
  X_LAST_UPDATE_LOGIN => X_LAST_UPDATE_LOGIN);


end INSERT_ROW;

end XX_SP_FND_RESPONSIBILITY_PKG;
/