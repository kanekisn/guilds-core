#if defined _guilds_included
    #endinput
#endif
#define _guilds_included

#define PL_VERSION "0"
#define PL_AUTHOR "Allen aka Kanekisn"

enum GC_Category
{
	MAIN,
	MYGUILD,
	SETTINGS,			
};

enum GET_Users
{
	SCORE_USER,
	ID_GUILD,
	PERMISSIONS,
	COUNT,
};

enum
{
	SCORE,
	GOLDS,
	SLOTS,
    SERVER_ID,
	GET_Guilds,
};

/**
 *	Called for get clone of DB
 *	-
 *	@noparams
 *	-
 *	@return DB
*/
native Database GC_GetDB();

/**
 *	Called for get DBDriver (sqlite, MySQL)
 *	-
 *	@noparams
 *	-
 *	@return true if mysql or false if sqlite
*/
native bool GC_GetDBDriver();

/**
 *	Check for get condtion of plugin
 *	-
 *	@noparams
 *	-
 *	@return true or false
*/
native bool GC_IsPluginLoaded();

/**
 *	Get client status
 *	-
 *	@params iClient - index of client
 *	-
 *	@return false if client is not in game
*/
native bool GC_IsClientLoaded(int iClient);

/**
 *	Check condition of client, if he has guild.
 *	-
 *	@params iClient - index of client
 *	-
 *	@return false if client hasn't guild
*/
native bool GC_IsHasGuild(int iClient);

/**
 *	Create guild
 *	-
 *	@params iClient 	        - index of client who has to be owner
 *          szGuildName         - name of guild(size 32)
 *          szGuildDesctiprion  - description of guild(size 64)
 *			iSlots		        - amount of players
 *	-
 *	@noreturn
*/
native void GC_CreateGuild(int iClient, int iSlots, const char[] szGuildName, const char[] szGuildDescription);

/**
 *	Delete player from guild
 *	-
 *	@params iClient 	- index of client
 *	-
 *	@noreturn
*/
native void GC_DeletePlayer(int iClient);

/**
 *	Delete guild
 *	-
 *	@params iType parametrs (1 - iClient or 2 - ID Guild)
 *  		iParams - arguments
 *	-
 *	@noreturn
*/
native void GC_DeleteGuild(int iParams, int iType);

/**
 *	Set permission for player
 *	-
 *	@params iType parametrs (0 owner, 1 captain, 2 member)
 *  		iClient - index of client
 *	-
 *	@noreturn
*/
native void GC_SetPermission(int iClient, int iType);

/**
 *	Set guild for player
 *	-
 *	@params iID 	- ID Guild
 *  		iClient - index of client
 *	-
 *	@noreturn
*/
native void GC_SetGuild(int iClient, int iID);

/**
 *	Set score for player
 *	-
 *	@params iScore 	- amount score
 *  		iClient - index of client
 *	-
 *	@noreturn
*/
native void GC_SetScore(int iClient, int iScore);

/**
 *	Set golds for guild
 *	-
 *	@params iGolds 	- amount golds
 *  		iID 	- index of client
 *	-
 *	@noreturn
*/
native void GC_SetGolds(int iID, int iGolds);

/**
 *	Set slots of guild
 *	-
 *	@params iSlots 	- amount slots
 *  		iID     - ID GUILD
 *	-
 *	@noreturn
*/
native void GC_SetSlots(int iID, int iSlots);

/**
 *	Data control
 *	-
 *	@params iType - 1. Load Data
 *  		        2. Save Data
 *	                3. Update data for all connected users(dont need iParams) 
 *	@noreturn
*/
native void GC_DataControl(int iType, int iParams);

/**
 *	Get guilds data
 *	-
 *	@params iID                   - ID Guild
 *          GetGuildsDataCallback - name of callback
 *          iData                 - any data for transfer to function
 *  -
 *	@noreturn
*/
native void GC_GetGuildsData(int iID, GetGuildsDataCallback callback, any iData = 0);

/**
 *	Callback of GetGuilds data
 *	-
 *	@params iID                   - ID Guild
 *          iData      			  - type data
 *          iDt                 - any data 
 *  -
 *	@noreturn
*/
typedef GetGuildsDataCallback = function void (int iID, int iDt[GET_Guilds], any iData);

/**
 *	Check unique of guild
 *	-
 *	@params szGuildName           - Guild name for check
 *          IsGuildUniqueCallback - name of callback
 *          iData                 - any data for transfer to function
 *  -
 *	@noreturn
*/
native void GC_IsGuildUnique(const char[] szGuildName, IsGuildUniqueCallback callback, any iData = 0);

/**
 *	Callback of IsGuildUnique
 *	-
 *	@params iID                   - ID Guild
 *          iData      			  - type data
 *          iDt                 - any data 
 *  -
 *	@noreturn
*/
typedef IsGuildUniqueCallback = function void (int iID, bool bIsUnique, any iData);

/**
 *	Get user data
 *	-
 *	@params iClient               - index of client
 *          GET_Users Type        - data type
 *  -
 *	@noreturn
*/
native int GC_GetUserData(int iClient, GET_Users Type);

/**
 *	Open main menu
 *	-
 *	@params iClient               - index of client
 *  -
 *	@noreturn
*/
native void GC_OpenMainMenu(int iClient);

/**
 *	Open settings menu
 *	-
 *	@params iClient               - index of client
 *  -
 *	@noreturn
*/
native void GC_OpenSettingsMenu(int iClient);

/**
 *	Open guilds menu
 *	-
 *	@params iClient               - index of client
 *  -
 *	@noreturn
*/
native void GC_OpenGuildsListMenu(int iClient);

/**
 *	Open info menu
 *	-
 *	@params iClient               - index of client
 *          iGuild        		  - id guild
 *  -
 *	@noreturn
*/
native void GC_OpenInfoMenu(int iClient, int iGuild);

/**
 *	Open my guild menu
 *	-
 *	@params iClient               - index of client
 *  -
 *	@noreturn
*/
native void GC_OpenMyGuildMenu(int iClient);

/**
 *	Register item to menu
 *	-
 *	@params szItem  		 	  - unqiue item name
 *			GC_Category menu 	  - category of menu
 *			RegisterItem callback -	callback when user selected
 *			iData				  -	any data for transfer to callback
 *  -
 *	@noreturn
*/
native void GC_RegisterItem(const char[] szItem, GC_Category menu, RegisterItem callback, any iData = 0);

/**
 *	Callback of register item
 *	-
 *	@params iClient  		 	  - index of user who selected item
 *			iData 	  			  - any data
 *  -
 *	@noreturn
*/
typedef RegisterItem = function int (int iClient, any iData);

/**
 *	Check item for unique
 *	-
 *	@params szItem  		 	  - item name
 *			GC_Category 	  	  - category name
 *  -
 *	@return true if unique or false is not
*/
native bool GC_IsUniqueItem(const char[] szItem, GC_Category menu);

/**
 *	Unregister item
 *	-
 *	@params szItem  		 	  - item name
 *			GC_Category 	  	  - category name
 *  -
 *	@noreturn
*/
native void GC_UnRegisterItem(const char[] szItem, GC_Category menu);

/**
 *	Called when client has loaded
 *	-
 *	@params szItem  		 	  - item name
 *  -
 *	@noreturn
*/
forward void GC_OnClientLoaded(int iClient);

/**
 *	Called when core has loaded
 *	-
 *	@noparams
 *  -
 *	@noreturn
*/
forward void GC_OnPluginLoaded();

/**
 *	Get path to the main config folder of the guilds
 *	-
 *	@param buffer			Buffer to store the path in
 *	@param size				Max buffer length
 *	@param file				File to retrieve the path for
 *	-
 *	@noreturn
*/
stock void GC_GetCfgFile(char[] buffer, int size, const char[] file)
{
	BuildPath(Path_SM, buffer, size, "data/guilds/%s", file);
}

/**
 *	Register item to shop menu
 *	-
 *	@params szItem  		 	  - unqiue item name
 *			RegisterShopItem callback -	callback when user selected
 *			iData				  -	any data for transfer to callback
 *  -
 *	@noreturn
*/
native void GC_RegisterShopItem(const char[] szItem, RegisterShopItem callback, any iData = 0);

/**
 *	Callback of register item shop
 *	-
 *	@params iClient  		 	  - index of user who selected item
 *			iData 	  			  - any data
 *  -
 *	@noreturn
*/
typedef RegisterShopItem = function int (int iClient, any iData);

public SharedPlugin __pl_guilds = 
{
	name = "guilds",
	file = "guilds_core.smx",

	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_guilds_SetNTVOptional()
{
	MarkNativeAsOptional("GC_GetDB");
	MarkNativeAsOptional("GC_GetDBDriver");
	MarkNativeAsOptional("GC_IsPluginLoaded");
	MarkNativeAsOptional("GC_IsClientLoaded");
	MarkNativeAsOptional("GC_IsHasGuild");
	MarkNativeAsOptional("GC_CreateGuild"; 
	MarkNativeAsOptional("GC_DeletePlayer"); 
	MarkNativeAsOptional("GC_DeleteGuild"); 
	MarkNativeAsOptional("GC_SetPermission"); 
	MarkNativeAsOptional("GC_SetGuild");
	MarkNativeAsOptional("GC_SetScore"); 
	MarkNativeAsOptional("GC_SetGolds");
	MarkNativeAsOptional("GC_SetSlots");
	MarkNativeAsOptional("GC_DataControl");
	MarkNativeAsOptional("GC_GetGuildsData");
	MarkNativeAsOptional("GC_GetUserData");
	MarkNativeAsOptional("GC_OpenMainMenu");
	MarkNativeAsOptional("GC_OpenSettingsMenu");
	MarkNativeAsOptional("GC_OpenGuildsListMenu");
	MarkNativeAsOptional("GC_OpenInfoMenu");
	MarkNativeAsOptional("GC_OpenMyGuildMenu");
	MarkNativeAsOptional("GC_IsGuildUnique");
	MarkNativeAsOptional("GC_RegisterItem");
	MarkNativeAsOptional("GC_UnRegisterItem");
	MarkNativeAsOptional("GC_RegisterShopItem");
}
#endif