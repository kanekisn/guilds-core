#include <sourcemod>
#include <guilds>

#pragma newdecls required

enum struct Users {
  int count;
  int score;
  int id_guild;
  int permissions;
}

int 	  g_iServer_ID;

Handle 	  g_hGFwd_OnClientLoaded,
		  g_hGFwd_OnPluginLoaded;

StringMap g_hTrie[3];

Database  g_hDatabase = null;

char      g_sAuthID[MAXPLAYERS+1][32], 
		  g_sDBDriver[16];

Users     ident[MAXPLAYERS+1];

bool      bPlugin_Loaded, 
		  bClientLoaded[MAXPLAYERS+1],
		  bIsExit[MAXPLAYERS+1] = false;

#define DB_Callback(%0)     public void %0(Database hDatabase, DBResultSet hResults, const char[] szError, any data)

#include "guilds/Database.sp"
#include "guilds/Functions.sp"
#include "guilds/Configs.sp"
#include "guilds/API.sp"
#include "guilds/Menus.sp"

public void OnPluginStart()
{
	Create_Trie();
	Database.Connect(Database_Callback, "guilds_core");
	ServerID_Condition();
}

public void OnConfigsExecuted()
{
	KV_Modules();
	KV_Core();
	OnPluginLoaded();
}

public void OnClientPostAdminCheck(int iClient)
{
	if(!IsFakeClient(iClient)){
		GetClientAuthId(iClient, AuthId_Engine, g_sAuthID[iClient], sizeof(g_sAuthID));
		LoadDataPlayer(iClient); 
	}
}

public void OnMapEnd()
{
	Clean_Trie();
}

public void OnClientDisconnect(int iClient)
{
	if(!IsFakeClient(iClient)){
		SaveData(iClient);
	}
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++){
		if(IsValidClient(i)) SaveData(i);
	}
}