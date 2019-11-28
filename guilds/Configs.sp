void KV_Core(){
	char sPath[PLATFORM_MAX_PATH];

	KeyValues kvc = new KeyValues("Guilds_Core");
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/guilds/core.ini");

	if(!kvc.ImportFromFile(sPath))
	{
		LogError("(%s) is not found", sPath);
	}
	kvc.Rewind();
	
	char szComands[128], szBuffer[8][16];

	kvc.GetString("commands", szComands, sizeof(szComands));
	int iCount = ExplodeString(szComands, ";", szBuffer, 8, 16);
	for (int i; i < iCount; i++) RegConsoleCmd(szBuffer[i], Command_Guild);
	g_iServer_ID = kvc.GetNum("server_id");

	CloseHandle(kvc);
	ServerID_Condition();
}

void KV_Modules(){
	char sPath[PLATFORM_MAX_PATH];

	KeyValues kv = new KeyValues("Guilds_Core");
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/guilds/modules.ini");

	if(!kv.ImportFromFile(sPath))
	{
		LogError("(%s) is not found", sPath);
	}

	CategoryGenerate("Menu_Main", kv, g_hArray_main);
	CategoryGenerate("Menu_Guild", kv, g_hArray_myguild);
	CategoryGenerate("Menu_Settings", kv, g_hArray_settings);

	CloseHandle(kv);
}

void CategoryGenerate(const char[] szKv, KeyValues hKv, ArrayList hArray){
	hKv.Rewind();
	if(hKv.JumpToKey(szKv))
	{
		hKv.GotoFirstSubKey();
		do
		{
			char szItem[32];
			hKv.GetString("item", szItem, sizeof(szItem));
			if(szItem[0]){
				hArray.PushString(szItem);
				hArray.Push(0);
			}
		}
		while(hKv.GotoNextKey());
	}
}