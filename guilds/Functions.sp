public Action Command_Guild(int iClient, int iArgs)
{
	MainMenu(iClient);
	return Plugin_Handled;
}

stock bool IsValidClient(int iClient, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= iClient <= MaxClients) || !IsClientInGame(iClient) || (IsFakeClient(iClient) && !bAllowBots) || IsClientSourceTV(iClient) || IsClientReplay(iClient) || (!bAllowDead && !IsPlayerAlive(iClient)))
	{
		return false;
	}
	return true;
} 

void Create_Arrays(){
	g_hArray_main     = new ArrayList(ByteCountToCells(64));
	g_hArray_myguild  = new ArrayList(ByteCountToCells(64));
	g_hArray_settings = new ArrayList(ByteCountToCells(64));
}

void Clean_Arrays(){
	Arrays_CategoriesGen(g_hArray_main);
	Arrays_CategoriesGen(g_hArray_myguild);
	Arrays_CategoriesGen(g_hArray_settings);
}

void Arrays_CategoriesGen(ArrayList hArray){
	int iSize = hArray.Length;
	if(iSize)
	{
		for(int i = 1; i < iSize; i+=2)
		{
			CloseHandle(view_as<Handle>(hArray.Get(i)));
		}
		hArray.Clear();
	}
}