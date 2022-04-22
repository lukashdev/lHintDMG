#include <sourcemod>
#include <clientprefs>

#pragma newdecls required
#pragma semicolon 1
#pragma tabsize 0

#define PLUGIN_AUTHOR "lukash"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_NAME "lHintDMG"
#define PLUGIN_DESCRIPTION "Pokazuje w hincie zadany dmg i część ciała w którą trafiono"
#define PLUGIN_URL "https://steamcommunity.com/id/lukasz11772/"

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

Handle COOKIE_Hide;

bool bHide[MAXPLAYERS + 1] =  false;

ConVar cv_VipFlag;
ConVar cv_Grenades;

public void OnPluginStart()
{
    RegConsoleCmd("sm_hidedmg", CMD_Hide);
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
    cv_VipFlag = CreateConVar("hint_flag", "o", "Jaką flage musi posiadać gracz aby widzieć | \"\" = Dla każdego");
    cv_Grenades = CreateConVar("hint_grenades", "1", "Czy uwzględniać granaty?");
    COOKIE_Hide = RegClientCookie("dmh_hide", "Zapisuje wybór gracza czy włączyć/wyłączyć pokazywanie dmg", CookieAccess_Private);
    AutoExecConfig(true, "HintDmg");
}

public Action CMD_Hide(int client, int args)
{
    if(!IsVIP(client))
        return;
    if(bHide[client])
    {
        bHide[client] = false;
        PrintHintText(client, "Zastosowano zmiany\nUkrywanie wyłączone");
    }
    else 
    {
        bHide[client] = true;
        PrintHintText(client, "Zastosowano zmiany\nUkrywanie włączone");
    }
}

public Action Event_PlayerHurt(Handle event, char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    if(!IsValidClient(client) || !IsValidClient(attacker) || attacker == client || !IsVIP(attacker) || bHide[attacker])
        return Plugin_Continue;

    char sWeapon[32];
    GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
    if(!cv_Grenades.BoolValue && (StrEqual(sWeapon, "weapon_smokegrenade") || StrEqual(sWeapon, "weapon_hegrenade") || StrEqual(sWeapon, "weapon_flashbang"), StrEqual(sWeapon, "weapon_molotov"), StrEqual(sWeapon, "weapon_incgrenade"), StrEqual(sWeapon, "weapon_decoy")))
        return Plugin_Continue;

    char sBuffer[256], sHitgroup[32];
    int iHitgroup = GetEventInt(event, "Hitgroup");
    int iDMG = GetEventInt(event, "dmg_health");
    int iHealth = GetEventInt(event, "health");

    if(iHitgroup <= 0)         Format(sHitgroup, sizeof(sHitgroup), "Ciało");
    else if(iHitgroup == 1)    Format(sHitgroup, sizeof(sHitgroup), "Głowa");
    else if(iHitgroup == 2)    Format(sHitgroup, sizeof(sHitgroup), "Klatka piersiowa");
    else if(iHitgroup == 3)    Format(sHitgroup, sizeof(sHitgroup), "Brzuch");
    else if(iHitgroup == 4)    Format(sHitgroup, sizeof(sHitgroup), "Lewa ręka");
    else if(iHitgroup == 5)    Format(sHitgroup, sizeof(sHitgroup), "Prawa ręka");
    else if(iHitgroup == 6)    Format(sHitgroup, sizeof(sHitgroup), "Lewa noga");
    else if(iHitgroup == 7)    Format(sHitgroup, sizeof(sHitgroup), "Prawa noga");
    else                       Format(sHitgroup, sizeof(sHitgroup), "Ciało");

    if(GetClientHealth(client) >= 0)
        Format(sBuffer, sizeof(sBuffer), "Trafiłeś przeciwnika!");
    else
        Format(sBuffer, sizeof(sBuffer), "<font color='#8f0101'><b>Cios śmiertelny!</b></font>");
    Format(sBuffer, sizeof(sBuffer), "%s\nZadany DMG : <font color='#8f0101'><b>%i</b></font>", sBuffer, iDMG);
    Format(sBuffer, sizeof(sBuffer), "%s\nTrafiony w : <font color='#8f0101'><b>%s</b></font>", sBuffer, sHitgroup);
    Format(sBuffer, sizeof(sBuffer), "%s\n%i<font color='#8f0101'><b> > </b></font>%i", sBuffer, iHealth+iDMG, iHealth);
    PrintHintText(attacker, sBuffer);
    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    bHide[client] = false;
    char sBuffer[8];
    GetClientCookie(client, COOKIE_Hide, sBuffer, sizeof(sBuffer));
    if(StrEqual(sBuffer, "1"))
        bHide[client] = true;
}

public void OnClientDisconnect(int client)
{
    if(bHide[client])
        SetClientCookie(client, COOKIE_Hide, "1");
    else
        SetClientCookie(client, COOKIE_Hide, "0");
}

bool IsVIP(int client)
{
    char sFlag[10];
	cv_VipFlag.GetString(sFlag, sizeof(sFlag));
    if(StrEqual(sFlag, "") || strlen(sFlag) <= 0)
        return true;
    if(GetUserFlagBits(client) & ReadFlagString(sFlag) || GetUserFlagBits(client) & ADMFLAG_ROOT)
        return true;
    return false;
}

bool IsValidClient(int client) 
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	if (IsFakeClient(client))return false;
	if (IsClientSourceTV(client))return false;
	return IsClientInGame(client);
}