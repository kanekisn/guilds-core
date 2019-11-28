public void Database_Callback(Database hDB, const char[] sError, any data)
{
	if(SQL_CheckConfig("guilds_core"))
	{
		if(!hDB){
			LogError("[Guilds] - Could not connect to the database MySQL(%s)", sError);
			return;
		}
	}

	else
	{
		char sSQLError[215];
		hDB = SQLite_UseDatabase("guilds_core", sSQLError, sizeof(sSQLError));
		if(!hDB)
		{
			LogError("[Guilds] - Could not connect to the database SQLite (%s)", sSQLError);
			return;
		}
	}

	g_hDatabase = hDB;
	g_hDatabase.SetCharset("utf8");
	
	DBDriver hDatabaseDriver = g_hDatabase.Driver;
	hDatabaseDriver.GetIdentifier(g_sDBDriver, sizeof(g_sDBDriver));
	
	if(g_sDBDriver[0] == 'm')
	{
		g_hDatabase.Query(bdGlobal, "CREATE TABLE IF NOT EXISTS `guilds` (\
									`id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,\
									`name` VARCHAR(64) NOT NULL default 'unknown',\
									`description` VARCHAR(64) NOT NULL default 'unknown',\
									`score` INTEGER NOT NULL default 0,\
									`golds` INTEGER NOT NULL default 0,\
									`slots` INTEGER NOT NULL default 0,\
									`server_id` INTEGER NOT NULL default 0) ENGINE = InnoDB CHARSET=utf8 COLLATE utf8_general_ci;");
	}			

	else if(g_sDBDriver[0] == 's')
	{		
		g_hDatabase.Query(bdGlobal, "CREATE TABLE IF NOT EXISTS `guilds` (\
									`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
									`name` VARCHAR(64) NOT NULL default 'unknown',\
									`description` VARCHAR(64) NOT NULL default 'unknown',\
									`score` INTEGER NOT NULL default 0,\
									`golds` INTEGER NOT NULL default 0,\
									`slots` INEGER NOT NULL default 0);");
	}
	g_hDatabase.Query(bdGlobal, "CREATE TABLE IF NOT EXISTS `users` (\
								`name` VARCHAR(64) NOT NULL default 'unknown',\
								`auth` VARCHAR(32) NOT NULL,\
								`score` INTEGER NOT NULL default 0,\
								`id_guild` INTEGER NOT NULL default 0,\
								`permissions` INTEGER NOT NULL default 3);");
}

void ServerID_Condition(){
	if(g_sDBDriver[0] == 'm')
	{
		if(!g_hDatabase) return;

		char szQuery[128];
		g_hDatabase.Format(szQuery, sizeof(szQuery), "INSERT INTO `guilds` (`server_id`) VALUES (%i);", g_iServer_ID);
		g_hDatabase.Query(bdGlobal, szQuery);
	}
}

void GetCountPlayers(int iClient)
{
	if(!g_hDatabase) return;

	char szQuery[128];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT COUNT(`auth`) FROM `users` WHERE `id_guild` = %i;", ident[iClient].id_guild);
	g_hDatabase.Query(bdGetCountPlayers, szQuery, GetClientUserId(iClient), DBPrio_High);
}

DB_Callback(bdGetCountPlayers)
{
	if(szError[0])
	{
		LogError("[Guilds_Core] GetCountPlayers fail: %s", szError);
		return;
	}

	int iClient = GetClientOfUserId(data);
	if(!iClient) return;

	if(hResults.FetchRow()) ident[iClient].count = hResults.FetchInt(0);
	else ident[iClient].count = 0;
}

void LoadDataPlayer(int iClient)
{
	if(!g_hDatabase) return;

	char szQuery[128];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT `name`, `id_guild`, `permissions`, `score` FROM `users` WHERE `auth` = '%s';", g_sAuthID[iClient]);
	g_hDatabase.Query(bdLoadDataPlayer, szQuery, GetClientUserId(iClient), DBPrio_High);
}

DB_Callback(bdLoadDataPlayer)
{
	if(szError[0])
	{
		LogError("[Guilds_Core] LoadDataPlayer fail: %s", szError);
		return;
	}

	int iClient = GetClientOfUserId(data);
	if(!iClient) return;

	if(hResults.FetchRow()){
		char szName[MAX_NAME_LENGTH], szNameCurrent[MAX_NAME_LENGTH];
		GetClientName(iClient, szNameCurrent, sizeof(szNameCurrent));
		hResults.FetchString(0, szName, sizeof(szName));
		ident[iClient].id_guild = hResults.FetchInt(1);
		ident[iClient].permissions = hResults.FetchInt(2);
		ident[iClient].score = hResults.FetchInt(3);
		if(!StrEqual(szNameCurrent, szName)){
			char szQuery[128];
			g_hDatabase.Format(szQuery, sizeof(szQuery), "UPDATE `users` SET `name` = '%s' WHERE `auth` = '%s';", szNameCurrent, g_sAuthID[iClient]);
			g_hDatabase.Query(bdGlobal, szQuery);
		}
		GetCountPlayers(iClient);
		bClientLoaded[iClient] = true;
		Call_StartForward(g_hGFwd_OnClientLoaded);
		Call_PushCell(iClient);
		Call_Finish();
	}
	else{
		CreatePlayer(iClient);
	}
}

void CreatePlayer(int iClient)
{
	char szQuery[252], szName[MAX_NAME_LENGTH];
	GetClientName(iClient, szName, sizeof(szName));
	g_hDatabase.Format(szQuery, sizeof(szQuery), "INSERT INTO `users` (`name`, `auth`, `id_guild`, `score`) VALUES ('%s', '%s', 0, 0);", szName, g_sAuthID[iClient]);
	g_hDatabase.Query(bdCreate, szQuery, GetClientUserId(iClient));
}

DB_Callback(bdCreate)
{
	if(szError[0])
	{
		LogError("[Guilds_Core] create player callback fail: %s", szError);
		return;
	}
	int iClient = GetClientOfUserId(data);
	if(!iClient) return;

	LoadDataPlayer(iClient);
}

void CreateGuild(int iClient, int iSlots, char[] szGuildName, char[] szGuildDescription)
{
	if(!g_hDatabase) return;

	DataPack hPack = new DataPack();
	hPack.WriteCell(GetClientUserId(iClient));
	hPack.WriteCell(iSlots);
	hPack.WriteString(szGuildName);
	hPack.WriteString(szGuildDescription);

	char szQuery[252];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT `id` FROM `guilds` WHERE `name` = '%s';", szGuildName);
	g_hDatabase.Query(bdCreateGuild, szQuery, hPack);
}

DB_Callback(bdCreateGuild)
{
	DataPack hPack = view_as<DataPack>(data);

	if(szError[0])
	{
		LogError("[Guilds_Core] bdCreateGuild fail: %s", szError);
		delete hPack;
		return;
	}
	hPack.Reset();

	int iClient = GetClientOfUserId(hPack.ReadCell());
	if(!iClient){
		delete hPack; 
		return;
	}

	int iSlots = hPack.ReadCell();
	char szGuildName[MAX_NAME_LENGTH], szGuildDescription[MAX_NAME_LENGTH];
	hPack.ReadString(szGuildName, sizeof(szGuildName));
	hPack.ReadString(szGuildDescription, sizeof(szGuildDescription));
	delete hPack;

	if(!hResults.FetchRow()){
		char szQuery1[128], szQuery[512];

		Transaction hTransaction =  new Transaction();

		g_hDatabase.Format(szQuery, sizeof(szQuery), "INSERT INTO `guilds` (`name`, `description`, `slots`) VALUES ('%s', '%s', %i);", szGuildName, szGuildDescription, iSlots);
		g_hDatabase.Format(szQuery1, sizeof(szQuery1), "SELECT `id` FROM `guilds` WHERE `name` = '%s';", szGuildName);
		hTransaction.AddQuery(szQuery);
		hTransaction.AddQuery(szQuery1);
		g_hDatabase.Execute(hTransaction, TransactionCG_Callback, TransactionError_Callback, GetClientUserId(iClient));
	}
}

public void TransactionCG_Callback(Database hDb, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	int iClient = GetClientOfUserId(data);
	if(!iClient) return;
	if(results[1].FetchRow()){
		char szQuery[128];
		g_hDatabase.Format(szQuery, sizeof(szQuery), "UPDATE `users` SET `id_guild` = %i, `permissions` = 0, `score` = 0 WHERE `auth` = '%s';", results[1].FetchInt(0), g_sAuthID[iClient]);
		g_hDatabase.Query(bdGlobal, szQuery);
		ident[iClient].id_guild = results[1].FetchInt(0), ident[iClient].permissions = 0;
	}
}

void SaveData(int iClient)
{
	if(!g_hDatabase) return;

	char szQuery[512], szName[MAX_NAME_LENGTH];
	GetClientName(iClient, szName, sizeof(szName));
	g_hDatabase.Format(szQuery, sizeof(szQuery), "UPDATE `users` SET `name` = '%s', `id_guild` = %i, `score` = %i, `permissions` = %i WHERE `auth` = '%s';", szName, ident[iClient].id_guild, ident[iClient].score, ident[iClient].permissions, g_sAuthID[iClient]);
	g_hDatabase.Query(bdGlobal, szQuery);
}

void GlobalUpdateData(){
	for(int i = 1; i <= MaxClients; i++){
		if(IsValidClient(i))
			LoadDataPlayer(i);
	}
}

void DeleteGuild(int iParams, int iType){
	if(iType == 1)
	{
		Transaction hTransaction = new Transaction();
		char szQuery_1[128], szQuery_2[128];

		g_hDatabase.Format(szQuery_1, sizeof(szQuery_1), "DELETE FROM `guilds` WHERE `id` = %i;", ident[iParams].id_guild);
		g_hDatabase.Format(szQuery_2, sizeof(szQuery_2), "UPDATE `users` SET `id_guild` = 0, `score` = 0, `permissions` = 3 WHERE `id_guild` = %i;", ident[iParams].id_guild);
		hTransaction.AddQuery(szQuery_2);
		hTransaction.AddQuery(szQuery_1);
		g_hDatabase.Execute(hTransaction, TransactionSuccess_Callback, TransactionError_Callback, GetClientUserId(iParams));
	}
	else if(iType == 2)
	{
		Transaction hTransaction = new Transaction();
		char szQuery_1[128], szQuery_2[128];

		g_hDatabase.Format(szQuery_1, sizeof(szQuery_1), "DELETE FROM `guilds` WHERE `id` = %i;", iParams);
		g_hDatabase.Format(szQuery_2, sizeof(szQuery_2), "UPDATE `users` SET `id_guild` = 0, `score` = 0, `permissions` = 3 WHERE `id_guild` = %i;", iParams);
		hTransaction.AddQuery(szQuery_2);
		hTransaction.AddQuery(szQuery_1);
		g_hDatabase.Execute(hTransaction, TransactionSuccess2_Callback, TransactionError_Callback);
	}
}

public void TransactionSuccess_Callback(Database hDb, any data, int numQueries, Handle[] results, any[] queryData){
	int iClient = GetClientOfUserId(data);
	if(!iClient) return;
	GlobalUpdateData();

	PrintToChat(iClient, "Гильдия успешно удалена!");
}

public void TransactionSuccess2_Callback(Database hDb, any data, int numQueries, Handle[] results, any[] queryData){
	GlobalUpdateData();
}

public void TransactionError_Callback(Database hDb, any data, int numQueries, const char[] error, int failIndex, any[] queryData){
	if(error[0])
	{
		LogError("[Guilds Core] Transaction Error: %s", error);
		return;
	}
}

void LeaveGuild(int iClient){
	if(!ident[iClient].permissions){
			DeleteGuild(iClient, 1);
		}
	PrintToChat(iClient, "Вы покинули гильдию!");
}

void SetPermission(int iClient, int iType){
	ident[iClient].permissions = iType;
}

void SetGuild(int iClient, int iID){
	ident[iClient].id_guild = iID, ident[iClient].score = 0, ident[iClient].permissions = 2;
}

void SetScore(int iClient, int iScore){
	ident[iClient].score = iScore;
}

void SetGolds(int iID, int iGolds){
	char szQuery[128];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "UPDATE `guilds` SET `golds` = %i WHERE `id` = %i;", iGolds, iID);
	g_hDatabase.Query(bdGlobal, szQuery);
}

void SetSlots(int iID, int iSlots){
	char szQuery[128];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "UPDATE `guilds` SET `slots` = %i WHERE `id` = %i;", iSlots, iID);
	g_hDatabase.Query(bdGlobal, szQuery);
}

DB_Callback(bdGlobal)
{
	if(szError[0])
	{
		LogError("[Guilds_Core] Global callback fail: %s", szError);
		return;
	}

	bPlugin_Loaded = true;
}
