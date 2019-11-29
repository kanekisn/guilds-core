void MainMenu(int iClient)
{
	Menu hMenu = new Menu(CMD_MenuHandler);
	hMenu.SetTitle("[Guilds Core] Menu of guilds:\n \n");

	if(ident[iClient].permissions == 3) hMenu.AddItem("a", "List of guilds");
	else hMenu.AddItem("b", "My guild");
	
	Menu_Generate(g_hTrie[0], hMenu);

	bIsExit[iClient] = false;

	hMenu.Display(iClient, 0);
}

public int CMD_MenuHandler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsValidClient(iClient)) return;

			char szInfo[32];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			if(szInfo[0] == 'a'){
				LoadGuildList(iClient);
			}
			else if(szInfo[0] == 'b'){
				MyGuild(iClient);
			}
			else{
				int iValue;
				g_hTrie[0].GetValue(szInfo, iValue);
				DataPack hPack = view_as<DataPack>(iValue);
				if(!hPack){
					PrintToChat(iClient, "item не зарегестрирован!");
					return;
				}
				hPack.Reset();
				Handle hPlugin = hPack.ReadCell();
				int iData = hPack.ReadCell();
				Function fncCallback = hPack.ReadFunction();

				Call_StartFunction(hPlugin, fncCallback);
				Call_PushCell(iClient);
				Call_PushCell(iData);
				Call_Finish();
			}
		}
		case MenuAction_End:    
		{
			delete hMenu;
		}
	}
}

void LoadGuildList(int iClient)
{
	if(!g_hDatabase) return;

	g_hDatabase.Query(bdLoadGuildList, "SELECT `id`, `name`, `score` FROM `guilds` ORDER BY `score` DESC;", GetClientUserId(iClient));
}

DB_Callback(bdLoadGuildList)
{
	if(szError[0])
	{
		LogError("[Guilds_Core] LoadGuildList fail: %s", szError);
		return;
	}
	
	int iClient = GetClientOfUserId(data);
	if(!iClient){
		return;
	}

	char szName[MAX_NAME_LENGTH], szBuffer[256], szID[16];

	Menu hMenu = new Menu(LoadGuildList_Handler);
	hMenu.SetTitle("[Guilds Core] List of Guilds:\n \n");

	int iCount = 0;

	while(hResults.FetchRow())
	{
		IntToString(hResults.FetchInt(0), szID, sizeof(szID));
		hResults.FetchString(1, szName, sizeof(szName));
		FormatEx(szBuffer, sizeof(szBuffer), "%s [%i]", szName, hResults.FetchInt(2));
		hMenu.AddItem(szID, szBuffer);
		iCount++;
	}

	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	if(iCount){
		DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	}
	else{
		delete hMenu;
		PrintToChat(iClient, "Гильдий нету!");
	}
}

public int LoadGuildList_Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsValidClient(iClient)) return;

			char szInfo[16];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			ShowGuildInfo(iClient, StringToInt(szInfo));
		}

		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				bIsExit[iClient] ? MyGuild(iClient) : MainMenu(iClient);
			}
		}

		case MenuAction_End:    
		{
			delete hMenu;
		}
	}
}

void ShowGuildInfo(int iClient, int iGuild)
{
	DataPack hPack = new DataPack();

	hPack.WriteCell(GetClientUserId(iClient));
	hPack.WriteCell(iGuild);

	GetCountPlayers(iClient);

	if(!g_hDatabase) return;
	char szBuffer[128];
	g_hDatabase.Format(szBuffer, sizeof(szBuffer), "SELECT `name`, `description`, `score`, `golds`, `slots` FROM `guilds` WHERE `id` = %i;", iGuild);
	g_hDatabase.Query(bdShowGuildInfo, szBuffer, hPack);
}

DB_Callback(bdShowGuildInfo)
{
	DataPack hPack = view_as<DataPack>(data);
	if(szError[0])
	{
		LogError("[Guilds_Core] bdShowGuildInfo fail: %s", szError);
		delete hPack;
		return;
	}

	hPack.Reset();
	
	int iClient = GetClientOfUserId(hPack.ReadCell());
	if(!iClient){
		delete hPack;
		return;
	}
	int iGuild = hPack.ReadCell();
	delete hPack;

	if(hResults.FetchRow())
	{
		int iSlots = hResults.FetchInt(4);
		char szName[32], szGuildDesc[64], szData[16];
		IntToString(iGuild, szData, sizeof(szData));
		hResults.FetchString(0, szName, sizeof(szName));
		hResults.FetchString(1, szGuildDesc, sizeof(szGuildDesc));
		Menu hMenu = new Menu(bdShowGuildInfo_Handler);

		if(!iSlots)
		{ 
			hMenu.SetTitle("[%s]\nScore :[%i]\nGolds :[%i]\nPlayers[%i]", szName, hResults.FetchInt(2), hResults.FetchInt(3), hResults.FetchInt(4), ident[iClient].count);
		}

		else{ 
			hMenu.SetTitle("[%s]\nScore :[%i]\nGolds :[%i]\nPlayers[%i/%i]", szName, hResults.FetchInt(2), hResults.FetchInt(3), hResults.FetchInt(4), ident[iClient].count, iSlots);
		}

		PrintToChat(iClient, "Description: %s", szGuildDesc);

		hMenu.AddItem(szData, "Members");


		hMenu.ExitBackButton = true;
		hMenu.ExitButton = true;

		DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	}
}	

public int bdShowGuildInfo_Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char szInfo[16];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));

			if(!IsValidClient(iClient)){ 
				return;
			}
			ShowPlayers(iClient, StringToInt(szInfo));
		}

		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				LoadGuildList(iClient);
			}
		}

		case MenuAction_End:    
		{
			delete hMenu;
		}
	}
}

void ShowPlayers(int iClient, int iGuild)
{
	if(!g_hDatabase) return;

	DataPack hPack = new DataPack();
	hPack.WriteCell(GetClientUserId(iClient));
	hPack.WriteCell(iGuild);

	char szBuffer[128];
	g_hDatabase.Format(szBuffer, sizeof(szBuffer), "SELECT `name`, `score`, `permissions` FROM `users` WHERE `id_guild` = %i;", iGuild);
	g_hDatabase.Query(bdShowPlayers, szBuffer, hPack);
}

DB_Callback(bdShowPlayers)
{
	DataPack hPack = view_as<DataPack>(data);
	if(szError[0])
	{
		LogError("[Guilds_Core] bdShowPlayers fail: %s", szError);
		delete hPack;
		return;
	}

	hPack.Reset();
	
	int iClient = GetClientOfUserId(hPack.ReadCell());
	
	if(!iClient){
		delete hPack; 
		return;
	}
	int iGuild = hPack.ReadCell();

	delete hPack;

	Menu hMenu = new Menu(bdShowPlayers_Handler);
	hMenu.SetTitle("[GC] Players\n \n");

	char szName[MAX_NAME_LENGTH];
	char szBuffer[512];
	char szID[16];

	while(hResults.FetchRow()){
		hResults.FetchString(0, szName, sizeof(szName));
		switch(hResults.FetchInt(2)){
			case 0:{FormatEx(szBuffer, sizeof(szBuffer), "%s - [S:%i]/[Owner]", szName, hResults.FetchInt(1));}
			case 1:{FormatEx(szBuffer, sizeof(szBuffer), "%s - [S:%i]/[Captain]", szName, hResults.FetchInt(1));}
			case 2:{FormatEx(szBuffer, sizeof(szBuffer), "%s - [S:%i]/[Member]", szName, hResults.FetchInt(1));}
		}
		hMenu.AddItem("", szBuffer, ITEMDRAW_DISABLED);
	}

	IntToString(iGuild, szID, sizeof(szID));

	hMenu.AddItem(szID, "back to menu");

	hMenu.ExitBackButton = false;
	hMenu.ExitButton = true;

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int bdShowPlayers_Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char szInfo[16];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			int iGuild = StringToInt(szInfo);
			if(iGuild == ident[iClient].id_guild){
				MyGuild(iClient);
			}

			else{
				ShowGuildInfo(iClient, StringToInt(szInfo));
			}
		}

		case MenuAction_End:    
		{
			delete hMenu;
		}
	}
}

void MyGuild(int iClient)
{
	if(!g_hDatabase) return;
	if(!IsValidClient(iClient)) return;
	char szQuery[128];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT `description`, `name`, `score`, `golds`, `slots` FROM `guilds` WHERE `id` = %i;", ident[iClient].id_guild);
	g_hDatabase.Query(bdShowMyGuild, szQuery, GetClientUserId(iClient));
}

DB_Callback(bdShowMyGuild)
{
	if(szError[0])
	{
		LogError("[Guilds_Core] bdShowMyGuildfail: %s", szError);
		return;
	}

	int iClient = GetClientOfUserId(data);
	if(!iClient) return;

	if(hResults.FetchRow())
	{
		int iSlots = hResults.FetchInt(4);
		char szGuild[MAX_NAME_LENGTH], szName[MAX_NAME_LENGTH];
		hResults.FetchString(0, szGuild, sizeof(szGuild));
		hResults.FetchString(1, szName, sizeof(szName));

		Menu hMenu = new Menu(bdShowMyGuild_Handler);

		if(iSlots){
			hMenu.SetTitle("[GC] My Guild -> %s\nPlayers %i/%i\nScore: %i\nGolds: %i\nYour score: %i", szName, ident[iClient].count, iSlots, hResults.FetchInt(2), hResults.FetchInt(3), hResults.FetchInt(4), ident[iClient].score);
		}

		else{
			hMenu.SetTitle("[GC] My Guild -> %s\nPlayers %i\nScore: %i\nGolds: %i\nYour score: %i", szName, ident[iClient].count, hResults.FetchInt(2), hResults.FetchInt(3), hResults.FetchInt(4), ident[iClient].score);
		}

		PrintToChat(iClient, "Description: %s", szGuild);
		if(!ident[iClient].permissions || ident[iClient].permissions == 1)
		{
			hMenu.AddItem("1", "Settings");
		}

		hMenu.AddItem("2", "Players");
		hMenu.AddItem("3", "List of Guilds");

		Menu_Generate(g_hTrie[1], hMenu);

		hMenu.AddItem("4", "Leave from guild");

		bIsExit[iClient] = true;
		hMenu.ExitBackButton = true;
		hMenu.ExitButton = true;

		DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	}
}

public int bdShowMyGuild_Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsValidClient(iClient)) return; 
			char szInfo[5];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			switch(szInfo[0]){
				case'1':{Settings(iClient);}
				case'2':{
					ShowPlayers(iClient, ident[iClient].id_guild);
					}
				case'3':{
					LoadGuildList(iClient);
					}
				case'4':{LeaveGuild(iClient);}
				default:{
					int iValue;
					g_hTrie[1].GetValue(szInfo, iValue);
					DataPack hPack = view_as<DataPack>(iValue);
					if(!hPack){
						PrintToChat(iClient, "item не зарегестрирован!");
						return;
					}
					hPack.Reset();
					Handle hPlugin = hPack.ReadCell();
					int iData = hPack.ReadCell();
					Function fncCallback = hPack.ReadFunction();

					Call_StartFunction(hPlugin, fncCallback);
					Call_PushCell(iClient);
					Call_PushCell(iData);
					Call_Finish();
				}
			}
		}

		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				if(!IsValidClient(iClient)) return;
				MainMenu(iClient);
			}
		}

		case MenuAction_End:    
		{
			delete hMenu;
		}
	}
}

void Settings(int iClient)
{
	Menu hMenu = new Menu(Settings_Handler);

	hMenu.SetTitle("Settings of Guild:\n \n");
	!ident[iClient].permissions ? hMenu.AddItem("a", "Delete this guild") : hMenu.AddItem("a", "Delete this guild", ITEMDRAW_DISABLED);

	Menu_Generate(g_hTrie[1], hMenu);

	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int Settings_Handler(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsValidClient(iClient)) return; 
			char szInfo[5];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo));
			
			if(szInfo[0] == 'a'){
				DeleteGuild(iClient, 1);
			}
			else
			{
				int iValue;
				g_hTrie[2].GetValue(szInfo, iValue);
				DataPack hPack = view_as<DataPack>(iValue);
				if(!hPack){
					PrintToChat(iClient, "item не зарегестрирован!");
					return;
				}
				hPack.Reset();
				Handle hPlugin = hPack.ReadCell();
				int iData = hPack.ReadCell();
				Function fncCallback = hPack.ReadFunction();

				Call_StartFunction(hPlugin, fncCallback);
				Call_PushCell(iClient);
				Call_PushCell(iData);
				Call_Finish();
			}
		}

		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				if(!IsValidClient(iClient)) return;
				MyGuild(iClient);
			}
		}

		case MenuAction_End:    
		{
			delete hMenu;
		}
	}
}