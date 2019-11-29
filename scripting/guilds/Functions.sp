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

void Create_Trie(){
	for(int i = 0; i < 3; ++i){g_hTrie[i] = new StringMap();}
}

void Clean_Trie(){
	for(int i = 0; i < 3; ++i){hTrie_CategoriesGen(g_hTrie[i]);}
}

void hTrie_CategoriesGen(StringMap hTrie){
	StringMapSnapshot hTrieSnapshot = hTrie.Snapshot();
    char szKey[32];
    int iSize = hTrieSnapshot.Length;
    if(iSize){
		int iValue;
		for(int i = 0; i < iSize; ++i)
   		{
       		hTrieSnapshot.GetKey(i, szKey, sizeof(szKey));
      	 	hTrie.GetValue(szKey, iValue);
			if(iValue) CloseHandle(view_as<Handle>(iValue));
			else hTrie.Remove(szKey);
    	}
	}
}

void Native_RegisterItemGen(StringMap hTrie, const char[] szItem, DataPack hPack){
	int iValue;
	if(hTrie.GetValue(szItem, iValue)) hTrie.SetValue(szItem, hPack);
	else ThrowNativeError(SP_ERROR_NATIVE, "Ключ -> %s не найден в конфиге!", szItem);
}

void Native_UnRegisterItemGen(StringMap hTrie, const char[] szItem){
	int iValue;
	if(hTrie.GetValue(szItem, iValue))
	{
		if(iValue){
			CloseHandle(view_as<Handle>(iValue));
			hTrie.Remove(szItem);
		}
		else{
			hTrie.Remove(szItem);
		}
	}
	else{
		ThrowNativeError(SP_ERROR_NATIVE, "Не удалось найти item!");
	}
}

bool Native_IsUniqueItemGen(StringMap hTrie, const char[] szItem){
	int iValue;
	if(hTrie.GetValue(szItem, iValue))
	{
		if(iValue) return false;
		else return true;
	}

	else{
		ThrowNativeError(SP_ERROR_NATIVE, "Не удалось найти item!");
	}
	return false;
}

void Menu_Generate(StringMap hTrie, Menu hMenu){
	StringMapSnapshot hTrieSnapshot = hTrie.Snapshot();
    char szKey[32];
    int iSize = hTrieSnapshot.Length;
    if(iSize){
		for(int i = 0; i < iSize; ++i)
   		{
       		hTrieSnapshot.GetKey(i, szKey, sizeof(szKey));
      	 	hMenu.AddItem(szKey, szKey);
    	}
	}
}