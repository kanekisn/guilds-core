public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max) 
{
	CreateNative("GC_GetDB", Native_GetDatabase);
	CreateNative("GC_GetDBDriver", Native_GetDBDriver);
	CreateNative("GC_IsPluginLoaded", Native_PluginLoaded);
	CreateNative("GC_IsClientLoaded", Native_ClientLoaded);
	CreateNative("GC_IsHasGuild", Native_IsClientValid);
	CreateNative("GC_CreateGuild", Native_CreateGuild); 
	CreateNative("GC_DeletePlayer", Native_DeletePlayer); 
	CreateNative("GC_DeleteGuild", Native_DeleteGuild); 
	CreateNative("GC_SetPermission", Native_SetPermission); 
	CreateNative("GC_SetGuild", Native_SetGuild);
	CreateNative("GC_SetScore", Native_SetScore); 
	CreateNative("GC_SetGolds", Native_SetGolds);
	CreateNative("GC_SetSlots", Native_SetSlots);
	CreateNative("GC_DataControl", Native_DataControl);
	CreateNative("GC_GetGuildsData", Native_GetGuildsData);
	CreateNative("GC_GetUserData", Native_GetUserData);
	CreateNative("GC_OpenMainMenu", Native_MainMenu);
	CreateNative("GC_OpenSettingsMenu", Native_SettingsMenu);
	CreateNative("GC_OpenGuildsListMenu", Native_GuildsList);
	CreateNative("GC_OpenInfoMenu", Native_InfoMenu);
	CreateNative("GC_OpenMyGuildMenu", Native_MyGuildMenu);
	CreateNative("GC_IsGuildUnique", Native_IsGuildUnique);
	CreateNative("GC_RegisterItem", Native_RegisterItem);
	CreateNative("GC_UnRegisterItem", Native_UnRegisterItem);
	CreateNative("GC_IsUniqueItem", Native_IsUniqueItem);

	g_hGFwd_OnClientLoaded = CreateGlobalForward("GC_OnClientLoaded", ET_Ignore, Param_Cell);
	g_hGFwd_OnPluginLoaded = CreateGlobalForward("GC_OnPluginLoaded", ET_Ignore);

	RegPluginLibrary("guilds");

	return APLRes_Success;
}

void OnPluginLoaded(){
	Call_StartForward(g_hGFwd_OnPluginLoaded);
	Call_Finish();
}

public int Native_GetDatabase(Handle hPlugin, int iNumParams)
{
	return view_as<int>(CloneHandle(g_hDatabase, hPlugin));
}

public int Native_GetDBDriver(Handle hPlugin, int iNumParams)
{
	if(g_sDBDriver[0] == 'm'){
		return true;
	}
	else{
		return false;
	}
}

public int Native_PluginLoaded(Handle hPlugin, int iNumParams)
{
	return bPlugin_Loaded;
}

public int Native_ClientLoaded(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidClient(iClient)) return bClientLoaded[iClient];
	return false;
}

public int Native_IsClientValid(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidClient(iClient) && ident[iClient].id_guild) return true;
	else return false;
}

public int Native_CreateGuild(Handle hPlugin, int iNumParams)
{
	char szBuffer[32], szBuffer2[64];
	int iClient = GetNativeCell(1);
	int iSlots 	= GetNativeCell(2);
	GetNativeString(3, szBuffer, sizeof(szBuffer)); 
	GetNativeString(4, szBuffer2, sizeof(szBuffer2));
	if(IsValidClient(iClient)){
		CreateGuild(iClient, iSlots, szBuffer, szBuffer2);
	}
}

public int Native_DeletePlayer(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidClient(iClient)) LeaveGuild(iClient);
}

public int Native_DeleteGuild(Handle hPlugin, int iNumParams)
{
	int iParams = GetNativeCell(1);
	int iType 	= GetNativeCell(2);
	if(iType == 1){
		if(IsValidClient(iParams)) DeleteGuild(iParams, iType);
	}
	else if(iType == 2){
		DeleteGuild(iParams, iType);
	}
}

public int Native_SetPermission(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iType 	= GetNativeCell(2);
	if(IsValidClient(iClient)) SetPermission(iClient, iType);
}	

public int Native_SetGuild(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iID		= GetNativeCell(2);
	if(IsValidClient(iClient)) SetGuild(iClient, iID);
}	

public int Native_SetScore(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iScore	= GetNativeCell(2);
	if(IsValidClient(iClient)) SetScore(iClient, iScore);
}	

public int Native_SetGolds(Handle hPlugin, int iNumParams)
{
	int iID = GetNativeCell(1);
	int iGolds	= GetNativeCell(2);
	SetGolds(iID, iGolds);
}	

public int Native_SetSlots(Handle hPlugin, int iNumParams)
{
	int iID 	= GetNativeCell(1);
	int iSlots	= GetNativeCell(2);
	if(iID) SetSlots(iID, iSlots);
}

public int Native_DataControl(Handle hPlugin, int iNumParams)
{
	int iType 	= GetNativeCell(1);
	int iParams = GetNativeCell(2);
	switch(iType){
		case 1:{LoadDataPlayer(iParams);}
		case 2:{SaveData(iParams);}
		case 3:{GlobalUpdateData();}
	}
}

public int Native_GetGuildsData(Handle hPlugin, int iNumParams)
{
	int iID = GetNativeCell(1);
	if(iID){
		int iData = GetNativeCell(3);
		Function fnCallback = GetNativeFunction(2);

		DataPack hPack = new DataPack(); 
		hPack.WriteCell(hPlugin);
		hPack.WriteFunction(fnCallback);
		hPack.WriteCell(iData); 
		hPack.WriteCell(iID);

		char szQuery[128];
		g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT `score`, `golds`, `slots`, `server_id` FROM `guilds` WHERE `id` = %i;", iID);
		g_hDatabase.Query(bdGetGuildsData, szQuery, hPack);
	}
	return 0;
}

DB_Callback(bdGetGuildsData)
{
	if(szError[0]){
	 	LogError("[Guilds Core] bdGetGuildsData Error: %s", szError);
		return;
	}

	DataPack hPack = view_as<DataPack>(data);
	hPack.Reset();

	Handle hPlugin = view_as<Handle>(hPack.ReadCell());
	Function fncCallback = hPack.ReadFunction();
	int iData = hPack.ReadCell();
	int iID = hPack.ReadCell();
	delete hPack;

	int iQData[GET_Guilds];
	if(hResults.FetchRow()) 
	{
		for(int i = 0; i <= 3; ++i) iQData[i] = hResults.FetchInt(i);
	}

	Call_StartFunction(hPlugin, fncCallback);
	Call_PushCell(iID);
	Call_PushArray(iQData, 5);
	Call_PushCell(iData);
	Call_Finish();
}

public int Native_GetUserData(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iType   = GetNativeCell(2);
	if(IsValidClient(iClient)){
		switch(iType){
			case 0:{return ident[iClient].score;}
			case 1:{return ident[iClient].id_guild;}
			case 2:{return ident[iClient].permissions;}
			case 3:{return ident[iClient].count;}
			default:{ThrowNativeError(SP_ERROR_NATIVE, "Несуществующий тип!");}
		}
	}
	return 0;
}

public int Native_MainMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidClient(iClient)){
		MainMenu(iClient);
	}
	return 0;
}

public int Native_MyGuildMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidClient(iClient) && ident[iClient].permissions != 3){
		MyGuild(iClient);
	}
	return 0;
}

public int Native_GuildsList(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidClient(iClient)){
		LoadGuildList(iClient);
	}
	return 0;
}

public int Native_SettingsMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidClient(iClient) && (!ident[iClient].permissions || ident[iClient].permissions == 1)){
		Settings(iClient);
	}
	return 0;
}

public int Native_InfoMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iGuild   = GetNativeCell(2);
	if(IsValidClient(iClient) && iGuild){
		ShowGuildInfo(iClient, iGuild);
	}
	return 0;
}

public int Native_IsGuildUnique(Handle hPlugin, int iNumParams)
{
	char szGuildName[MAX_NAME_LENGTH];
	GetNativeString(1, szGuildName, sizeof(szGuildName));

	int iData = GetNativeCell(3);
	Function fnCallback = GetNativeFunction(2);

	DataPack hPack = new DataPack(); 
	hPack.WriteCell(hPlugin);
	hPack.WriteFunction(fnCallback);
	hPack.WriteCell(iData); 

	char szQuery[215];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT `id` FROM `guilds` WHERE `name` = '%s';", szGuildName);
	g_hDatabase.Query(bdIGU, szQuery, hPack);
}

DB_Callback(bdIGU)
{
	if(szError[0])
	{
		LogError("[bdIGU] Global callback fail: %s", szError);
		return;
	}

	DataPack hPack = view_as<DataPack>(data);
	hPack.Reset();

	Handle hPlugin = view_as<Handle>(hPack.ReadCell());
	Function fncCallback = hPack.ReadFunction();
	int iData = hPack.ReadCell();
	delete hPack;
	
	int iID;
	bool bU = true;

	if(hResults.FetchRow()){
		iID = hResults.FetchInt(0);
		bU = false;
	}

	Call_StartFunction(hPlugin, fncCallback);
	Call_PushCell(iID);
	Call_PushCell(view_as<int>(bU));
	Call_PushCell(iData);
	Call_Finish();
}

public int Native_IsUniqueItem(Handle hPlugin, int iNumParams)
{
	char szItem[32];
	GetNativeString(1, szItem, sizeof(szItem));
	int iCategoryID = GetNativeCell(2);
	switch(iCategoryID){
		case 0:{Native_IsUniqueItemGen(g_hArray_main, szItem);}
		case 1:{Native_IsUniqueItemGen(g_hArray_myguild, szItem);}
		case 2:{Native_IsUniqueItemGen(g_hArray_settings, szItem);}
		default:{
			ThrowNativeError(SP_ERROR_NATIVE, "Несуществующая категория!");
			return false;
		}
	}
	return 0;
}

int Native_IsUniqueItemGen(ArrayList hArray, const char[] szItem){
	if(hArray.FindString(szItem) != -1)
	{
		int index = hArray.FindString(szItem);
		if(hArray.Get(++index)) return false; 
		else return true;
	}
	else{
		return true;
	}
}

public int Native_UnRegisterItem(Handle hPlugin, int iNumParams)
{
	char szItem[32];
	GetNativeString(1, szItem, sizeof(szItem));
	int iCategoryID = GetNativeCell(2);
	switch(iCategoryID){
		case 0:{Native_UnRegisterItemGen(g_hArray_main, szItem);}
		case 1:{Native_UnRegisterItemGen(g_hArray_myguild, szItem);}
		case 2:{Native_UnRegisterItemGen(g_hArray_settings, szItem);}
		default:{ThrowNativeError(SP_ERROR_NATIVE, "Несуществующая категория!");}
	}
}

void Native_UnRegisterItemGen(ArrayList hArray, const char[] szItem){
	if(hArray.FindString(szItem) != 1)
	{
		int index = hArray.FindString(szItem);
		hArray.Erase(index);
		++index;
		if(hArray.Get(index)){
			CloseHandle(view_as<Handle>(hArray.Get(index)));
			hArray.Erase(index);
		}
		else{
			hArray.Erase(index);
		}
	}
	else{
		ThrowNativeError(SP_ERROR_NATIVE, "Не удалось найти item!");
	}
}

public int Native_RegisterItem(Handle hPlugin, int iNumParams)
{
	char szItem[32];
	GetNativeString(1, szItem, sizeof(szItem));
	int iCategoryID = GetNativeCell(2);
	Function fnCallback = GetNativeFunction(3);
	int iData = GetNativeCell(4);

	DataPack hPack = new DataPack();
	hPack.WriteCell(hPlugin);
	hPack.WriteCell(iData);
	hPack.WriteFunction(fnCallback);

	switch(iCategoryID){
		case 0:{Native_RegisterItemGen(g_hArray_main, szItem, hPack);}
		case 1:{Native_RegisterItemGen(g_hArray_myguild, szItem, hPack);}
		case 2:{Native_RegisterItemGen(g_hArray_settings, szItem, hPack);}
		default:{ThrowNativeError(SP_ERROR_NATIVE, "Несуществующая категория!");}
	}
}

void Native_RegisterItemGen(ArrayList hArray, const char[] szItem, DataPack hPack){
	if(hArray.FindString(szItem) != -1){
		int index = hArray.FindString(szItem);
		for(int i = 0; i < 10; ++i) PrintToServer("%i", index);
		hArray.Set(++index, hPack);
		for(int i = 0; i < 10; ++i) PrintToServer("%i", index);
	}
	else ThrowNativeError(SP_ERROR_NATIVE, "Ключ -> %s не найден в конфиге!", szItem);
}


