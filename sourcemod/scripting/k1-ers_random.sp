#include <cstrike>
#include <sdkhooks>
#include <csgo_colors>
#include <clientprefs>
#include <k1_ers_core>

int g_iChanseToWin, g_iMaxChanse, g_iMaxWin, g_iClientWin[MAXPLAYERS+1], g_iMinClient;
ArrayList g_hArrayChanse;
char g_sLogFile[PLATFORM_MAX_PATH];
bool g_bLog;

public Plugin myinfo = 
{
    name = "[ERS] Random give skins",
    author = "K1NG",
    description = "http//projecttm.ru/",
    version = "1.3"
}

public void OnPluginStart()
{
    g_hArrayChanse = new ArrayList(3);
    HookEvent("cs_win_panel_match", EventCSWIN_Panel);
    LoadConfig();
}

public void LoadConfig()
{
    char szBuffer[1024]; 
    BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/k1-ers/modules/random.cfg");
	
	LoadTranslations("k1-ers_random.phrases");

    KeyValues hKeyValues = new KeyValues("K1-ERS_Random");

    if (!hKeyValues.ImportFromFile(szBuffer))
    {
        SetFailState("Не удалось открыть файл %s", szBuffer);
        return;
    }

    g_iChanseToWin = hKeyValues.GetNum("chanse_to_win", 0);
    g_iMinClient = hKeyValues.GetNum("min_client", 4);
    g_iMaxWin = hKeyValues.GetNum("max_win_on_client", 1);
    g_bLog = !!hKeyValues.GetNum("log", 1);
    if(g_bLog)
        BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/k1-ers.log")
    if(g_iChanseToWin < 0) g_iChanseToWin = 0;
    else if(g_iChanseToWin > 100) g_iChanseToWin = 100;

    if (hKeyValues.JumpToKey("chanse") && hKeyValues.GotoFirstSubKey(false))
    {
        g_hArrayChanse.Clear();

        char sIdSkin[10];
        char sTemp[64];
        char sInfo[2][32];
        int idx, iLen;
        do
        {
            hKeyValues.GetSectionName(sIdSkin, sizeof(sIdSkin));
            hKeyValues.GetString(NULL_STRING, sTemp, sizeof sTemp);
            iLen = ExplodeString(sTemp,"-",sInfo, sizeof(sInfo),sizeof (sInfo[]));
            for(int x = 0 ; x< iLen ;x++)
            {
                TrimString(sInfo[x]);
            }
            g_iMaxChanse += StringToInt(sInfo[0]);
            idx = g_hArrayChanse.Length;
            g_hArrayChanse.Push(StringToInt(sIdSkin));
            g_hArrayChanse.Set(idx, g_iMaxChanse, 1);
            if(iLen == 2 && StringToInt(sInfo[1]) > 0)
                g_hArrayChanse.Set(idx, StringToInt(sInfo[1]), 2);
            else
                g_hArrayChanse.Set(idx, -1, 2);

        } while (hKeyValues.GotoNextKey(false));
    }
    delete hKeyValues;
    if(g_bLog)
        BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/k1-ers.log")
}

public void EventCSWIN_Panel(Event event, const char[] name, bool dontBroadcast)
{
    if(GetClientCount(true) >= g_iMinClient)
    {
        for(int x = 1; x <= MaxClients; x++)
        {
            if(IsClientInGame(x) && !IsFakeClient(x)) 
            {
                g_iClientWin[x] = 0;
                GiveDropChanse(x);
            }
        }
    }   
}

public void GiveDropChanse(int iClient)
{
    if(GetRandomInt(1, 100) <= g_iChanseToWin && g_iClientWin[iClient] < g_iMaxWin)
    {
        g_iClientWin[iClient]++;
        int iRandomInt = GetRandomInt(1, g_iMaxChanse);
        int iResult = -1;
        for(int i = 0; i < g_hArrayChanse.Length; i++)
        {
            if(g_hArrayChanse.Get(i, 1) >= iRandomInt)
            {
                iResult = i;
                break;
            }
        }
        if(iResult != -1)
        {
            K1_ERS_GiveClientSkin(iClient, g_hArrayChanse.Get(iResult), g_hArrayChanse.Get(iResult, 2));
            if(g_bLog)
            {
                char szAuth[32];
                GetClientAuthId(iClient, AuthId_Engine, szAuth, sizeof szAuth, true);
                LogToFile(g_sLogFile, "%t", "Log_phrase", iClient, szAuth, g_hArrayChanse.Get(iResult), g_hArrayChanse.Get(iResult, 2));
            }
        }
        GiveDropChanse(iClient);
    }
}