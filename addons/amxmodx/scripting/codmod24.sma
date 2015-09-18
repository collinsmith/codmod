#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <round_terminator>
#include <csdm>
#include <nvault>
#include <fun>
#include <fb_controller>
#include <xs>

enum (+= 5000)
{
	LEVEL_TASK = 10000,
	MODELSET_TASK,
	FAKEDELAY_TASK,
	OMA_TASK,
	CHARGE_TASK,
	LASTSTAND_TASK,
	UAVTERROR_TASK,
	UAVCOUNTER_TASK,
	AIRSTRIKE_TASK,
	FLASHBANG_TASK,
	EMPEFFECTS_TASK,
	EMPTEAM_TASK,
	NUKE_TASK,
	NUKEKILL_TASK,
	XPLOAD_TASK
}

new PluginName[]="Modern Warfare 2";
new PluginVersion[]="2.4";
new DominationVersion[] ="domination24.amxx";

#define ADMIN_MEMBERSHIP ADMIN_LEVEL_A
#define TEAM_SELECT_VGUI_MENU_ID 2
#define MAX_RANKS 70
#define MAX_CHAL 62
#define MAXLVL_CHAL 9
#define SHIELD 1337
#define PA_LOW  35.0
#define PA_HIGH 85.0

#define KEYS_MAINMENU 		MENU_KEY_2|MENU_KEY_4|MENU_KEY_9|MENU_KEY_0
#define KEYS_PRESTIGE 		MENU_KEY_1|MENU_KEY_2
#define KEYS_STATS 		MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_9|MENU_KEY_0
#define KEYS_CLASSES 		MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_9|MENU_KEY_0
#define KEYS_CLASSESCUSTOM 	MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_0
#define KEYS_CLASSESEDITOR 	MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_9|MENU_KEY_0
#define KEYS_EDITOR 		MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_9|MENU_KEY_0

#define KEYS_GUNMAIN 		MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_9|MENU_KEY_0
#define KEYS_GUNASS		MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_9|MENU_KEY_0
#define KEYS_GUNSMG 		MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_9|MENU_KEY_0
#define KEYS_GUNSHO 		MENU_KEY_1|MENU_KEY_2|MENU_KEY_9|MENU_KEY_0
#define KEYS_GUNSNI 		MENU_KEY_1|MENU_KEY_2|MENU_KEY_9|MENU_KEY_0
#define KEYS_GUNMAC 		MENU_KEY_1|MENU_KEY_9|MENU_KEY_0
#define KEYS_GUNSEC 		MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_9|MENU_KEY_0

#define KEYS_PERKS		MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_9|MENU_KEY_0
#define KEYS_EQUIPTMENT		MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_9|MENU_KEY_0

new gHudSyncInfo
new gmsgScreenFade, gmsgScreenShake, gmsgStatusText, gmsgServerName, gmsgBarTime, gmsgSetFOV, gmsgHostageAdd, gmsgHostageDel, gmsgHideWeapon, gmsgTextMsg
new g_MaxPlayers
new g_Friend[33]
new bool:g_Starting
new g_ModName[32]
new Float:g_MaxHealth[33]
new g_CurrentWeapon[33]
new g_CurrentSecondary[33]
enum { DOMINATION = 1, TDM }
new g_RandMode
new bool:g_RoundOwner
new g_szHostname[64]
new bool:g_FirstSpawn[33]
new bool:g_hasloaded[33]

const m_iClip = 51
const m_iClip_linuxoffset = 4

//Custom Models
new const gFragModel[2][] = 
{
	"models/mw2/v_frag.mdl",
	"models/mw2/w_frag.mdl"
}

new const gShieldModel[2][] =
{
	"models/mw2/v_riotshield.mdl",
	"models/mw2/p_riotshield.mdl" 
}

new gAirstrikeJet[] = "models/mw2/cod_airstrike.mdl";

new gPredatorName[] = "predator_missile";
new gPredatorRocket[] = "models/mw2/cod_predator.mdl";

//Sound Vars
new const gSoundRank[] = "mw2/levelup.wav";
new const gSoundBadge[] = "mw2/challenge_completed.wav";
new const gKillBonus[] = "mw2/kill_bonus.wav";
new const gPayback[] = "mw2/payback.wav";
new const gBulletImpact[] = "mw2/bullet_impact.wav";
new const gPlayerSpawn[] = "mw2/us_spawn.wav";
new const gItemSelected[] = "mw2/perk_selection.wav";
#define ROUND_SOUNDS 4
new const gRoundStart[ROUND_SOUNDS][] =
{
	"mw2/mw2_spawn.mp3",
	"mw2/mw2_spawn2.mp3",
	"mw2/mw2_spawn3.mp3",
	"mw2/mw2_spawn4.mp3"
}
new const gGrenadeEXP[] = "mw2/frag_explode.wav";
new const gTangoDown[][] = 
{
	"mw2/us_killed1.wav",
	"mw2/us_killed2.wav"
}
new const gVictory[] = "mw2/us_victory.wav";
new const gDefeat[] = "mw2/us_defeat.wav";

//Team Deathmatch Sounds
new const gModeSound[3][] = 
{
	"",	
	"mw2/us_domination_start.wav",	
	"mw2/us_tdm_start.wav"	
}
new const gWinning[] = "mw2/us_winning.wav";
new const gLosing[] = "mw2/us_losing.wav";
new const gHasLead[] = "mw2/us_has_lead.wav";
new const gLostLead[] = "mw2/us_lost_lead.wav";

//Domination
//new gDominationStart[] = "mw2/us_domination_start.wav";

//Perks
new gOneManArmy[] = "mw2/perk_oma.wav"

//Shield
new const gShieldBash[] = "mw2/bash.wav";
new const gShieldBashHit[] = "mw2/bash_hit.wav";

//Killstreaks
#define TOT_SOUNDS 3
#define TOT_KILLSTREAKS 6
enum { KS_GIVE = 0, KS_FRIEND, KS_ENEMY  }
new const gKillstreakSounds[TOT_KILLSTREAKS][TOT_SOUNDS][] =
{
	{ "mw2/killstreaks/uav_give.wav", "mw2/killstreaks/uav_friend.wav", "mw2/killstreaks/uav_enemy.wav" },
	{ "mw2/killstreaks/counter_give.wav", "mw2/killstreaks/counter_friend.wav", "mw2/killstreaks/counter_enemy.wav" },
	{ "mw2/killstreaks/air_give.wav", "mw2/killstreaks/air_friend.wav", "mw2/killstreaks/air_enemy.wav" },
	{ "mw2/killstreaks/predator_give.wav", "mw2/killstreaks/predator_friend.wav", "mw2/killstreaks/predator_enemy.wav" },
	{ "mw2/killstreaks/emp_give.wav", "mw2/killstreaks/emp_friend.wav", "mw2/killstreaks/emp_enemy.wav" },
	{ "mw2/killstreaks/nuke_give.wav", "mw2/killstreaks/nuke_friend.wav", "mw2/killstreaks/nuke_enemy.wav" }
}

new gUAVEffect[] = "mw2/killstreaks/uav_call.wav"
new gEMPEffect[] = "mw2/killstreaks/emp_effect.wav"
new gPredEffect[] = "weapons/rocket1.wav";

new const gAirFly[][] =
{
	"mw2/killstreaks/jet_fly1.wav",
	"mw2/killstreaks/jet_fly2.wav"
}

//Custom Model Stuff
#define MODELCHANGE_DELAY 0.5
enum { USA = 1, SAS }
new g_TeamRand
new Float:g_ModelsTargetTime, Float:g_RoundStartTime
new g_HasCustomModel[33], g_PlayerModel[33][32]
new const g_ArmyRanger[] = "mw2_ranger"
new const g_Spetsnaz[] = "mw2_spetsnaz"
new const g_SAS[] = "mw2_sas2"
new const g_Opfor[] = "mw2_opfor2"

//Assist Killer
enum { CURRENT_ASSIST = 0, PREVIOUS_ASSIST }
new g_AssistKiller[2][33]
new g_LastKiller[33]
new g_ComebackCounter[33]
new bool:g_FirstKill

//Team Deathmatch
enum { TERROR = 0, COUNTER }
new g_Score[2]
new bool:g_WasntBefore[2]
new bool:g_HasSaid

public Set_Scores(team, score)
	g_Score[team] = score

//Challenge and XP Vars
new bool:g_ShouldCheck[33]
new g_PlayerRank[33];
new g_Prestige[33];
new g_Experience[33];
enum { MARKSMAN = 0, ELITE }
new g_PlayerChallenges[33][2][31]
/*
Assault = HP
SMG = Speed
Other = AP
Pistol = ?
*/
enum { ASSAULT = 0, SMG, OTHER, PISTOL }
new g_ChallangeCounter[4][33]

enum { PRIMARY = 0, SECONDARY }
new const gChalLvls[2][MAXLVL_CHAL] = { {9,24,74,149,299,499,749,999, 999}, {9,24,49,74,99,299,499,999, 999} }
new const gChalHS[2][MAXLVL_CHAL] = { {4,14,29,74,149,249,349,499, 499}, {4,14,29,74,149,249,349, 499, 499} }
new const gChalXP[MAXLVL_CHAL] = {250,1000,2000,5000,10000,12500,15000,20000, 0}

new const gKSChalNum[MAXLVL_CHAL] = {4,9,24,49,99,249,499,999, 999}
new const gKSChalKills[MAXLVL_CHAL] = {9,24,74,149,299,499,749,999, 999}
new const gKSChalXP[MAXLVL_CHAL] = {1000,2500,5000,10000,15000,20000,25000,30000, 0}

enum { GUN_KILLS = 0, GUN_HEADSHOTS }
new g_GunStats[33][2][31]

//Class System
new g_Perk[33][3]
new g_Equiptment[33]
enum
{
	NONE = 0,
	CUSTOM1, CUSTOM2, CUSTOM3, CUSTOM4, CUSTOM5, CUSTOM6,
	GRENADIER, RECON, OVERWATCH, SNIPER, RIOT
}
new g_PlayerClass[33]
new g_CustomPerk[33][3][7]
new g_CustomEquiptment[33][7]
new g_CustomWeapon[2][33][7]
new g_EditingClass[33]
new bool:g_FakeDelay[33]
new bool:g_Stuck[33]

//Shield Stuff
new bool:g_HasShield[33]
new bool:g_Shielded[33]
new Float:g_LastPressedSkill[33];
new bool:IsChargeDelay[33];
new g_ShieldKiller

//Perks
enum { PRK1_MARAT = 0, PRK1_SLIGH, PRK1_SCAVE, PRK1_BLING, PRK1_ONEMA }
enum { PRK2_STOPP = 0, PRK2_LIGHT, PRK2_HARDL, PRK2_COLDB, PRK2_DANGE }
enum { PRK3_COMMA = 0, PRK3_STEAD, PRK3_SCRAM, PRK3_NINJA, PRK3_LASTS }

//Equiptment
enum { EQU_FRAG = 0, EQU_FLASH, EQU_STUN, EQU_SMTX }

//Slight of Hand (faster reloads)
#define RELOAD_RATIO 0.5
const NOCLIP_WPN_BS    = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
const SHOTGUNS_BS    = ((1<<CSW_M3)|(1<<CSW_XM1014))

const m_pPlayer = 41
const m_iId = 43
const m_flTimeWeaponIdle = 48
const m_fInReload = 54
const m_flNextAttack = 83

 stock const Float:g_fDelay[CSW_P90+1] = 
{
	0.00, 2.70, 0.00, 2.00, 0.00, 0.55,   0.00, 3.15, 3.30, 0.00, 4.50, 
	2.70, 3.50, 3.35, 2.45, 3.30,   2.70, 2.20, 2.50, 2.63, 4.70, 
	0.55, 3.05, 2.12, 3.50, 0.00,   2.20, 3.00, 2.45, 0.00, 3.40
}
 
stock const g_iReloadAnims[CSW_P90+1] = 
{
	-1,  5, -1, 3, -1,  6,   -1, 1, 1, -1, 14, 
	4,  2, 3,  1,  1,   13, 7, 4,  1,  3, 
	6, 11, 1,  3, -1,    4, 1, 1, -1,  1
}

//Steady Aim
new normalTrace[33]
	
//Semtex
new const g_BounceSounds[][] = {"weapons/grenade_hit1.wav", "weapons/grenade_hit2.wav", "weapons/grenade_hit3.wav", "weapons/he_bounce-1.wav"}
new const g_NadeModel[] = {"models/w_hegrenade.mdl"}

/*------------------------------------------------------------------------------------------------*/
//Killstreaks
/*------------------------------------------------------------------------------------------------*/

new const g_KillstreakName[TOT_KILLSTREAKS][]=
{
	"UAV",
	"Counter-UAV",
	"Precision Airstrike",
	"Predator Missile",
	"EMP",
	"Tactical Nuke" 
}

//Main
#define KILLS_UAV 3
#define KILLS_COU 5
#define KILLS_AIR 7
#define KILLS_PRED 9
#define KILLS_EMP 15
#define KILLS_NUKE 25
enum
{
	KS_UAV = 0,
	KS_COU,
	KS_AIR,
	KS_PRED,
	KS_EMP,
	KS_NUKE
}
new g_Kills[33]
new bool:g_HasKillstreak[33][TOT_KILLSTREAKS]
new g_NumKillstreaks[33][TOT_KILLSTREAKS]
new g_KillstreakKills[33][TOT_KILLSTREAKS]
new g_KillstreakChal[33][TOT_KILLSTREAKS]
new g_KillstreakChalKill[33][TOT_KILLSTREAKS]

//UAV and Counter-UAV
new Float: g_flLocation[33][3]
enum { NULL = 0, TEAM_T, TEAM_CT }
new bool:g_HasUAV[3]
new Float:g_UAVTimer[3]

//Airstrike
#define RADIUS 400
#define MAXBOMBS 10
new Float: g_flAirOrigin[33][3]
new Float: g_flAirAngles[33][3]
new g_CalledAirstrikes
new g_AirstrikeKiller
new gSpriteExplosion

//Predator
#define ROCKET_SPEED	500		// Rocket fly speed
#define REACTION_SPEED	0.0		// How fast the rocket should react
new const ROCKET_TRAIL[3] = {224, 224, 255}
enum
{
	rocket_entity,	// Entity index
	rocket_nreact,	// Next reaction
}
new g_UserRocket[33][2]
new bool:g_ispredator[33]
new g_Trail

//EMP
#define EMP_TIMER 30.0
new bool:g_isemped[3]
//new Float: g_EMPTimer[3]
new g_EMPCaller

//Nuke
new timer = 11;
new bool:g_CanNuke = true
new g_NukeKiller

//nVault Vars
new g_Vault;
new g_AuthID[33][35];

//Grab Global Vars
new bool: g_isalive[33]
new bool: g_isconnected[33]
new bool: g_canprestige[33]
new bool: g_isfalling[33]
new bool: g_hasdmged[33]
new bool: g_islaststand[33]
new bool: g_isflashed[33]

//PCvars
new g_pcvar_doublexp, bool:g_DoubleXP
new g_pcvar_playto, g_WinNumber
new g_pcvar_hostname
new g_pcvar_savetype, g_iSaveType

new const g_ChalNameKillstreaks[TOT_KILLSTREAKS][MAXLVL_CHAL][]=
{
	{ "Exposed I","Exposed II","Exposed III","Exposed IV","Exposed V","Exposed VI","Exposed VII","Exposed VIII", "Error"},
	{ "Interference I","Interference II","Interference III","Interference IV","Interference V","Interference VI","Interference VII","Interference VIII", "Error"},
	{ "Airstrike Veteran I","Airstrike Veteran II","Airstrike Veteran III","Airstrike Veteran IV","Airstrike Veteran V","Airstrike Veteran VI","Airstrike Veteran VII","Airstrike Veteran VIII", "Error"},
	{ "Air To Ground I","Air To Ground II","Air To Ground III","Air To Ground IV","Air To Ground V","Air To Ground VI","Air To Ground VII","Air To Ground VIII", "Error"},
	{ "Blackout I","Blackout II","Blackout III","Blackout IV","Blackout V","Blackout VI","Blackout VII","Blackout VIII", "Error"},
	{ "End Game I","End Game II","End Game III","End Game IV","End Game V","End Game VI","End Game VII","End Game VIII", "Error"}
}

new const g_ChalNameKillstreakKills[TOT_KILLSTREAKS][MAXLVL_CHAL][]=
{
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Carpet Bomber I","Carpet Bomber II","Carpet Bomber III","Carpet Bomber IV","Carpet Bomber V","Carpet Bomber VI","Carpet Bomber VII","Carpet Bomber VIII", "Error"},
	{ "Predator I","Predator II","Predator III","Predator IV","Predator V","Predator VI","Predator VII","Predator VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Tactical Nuke I","Tactical Nuke II","Tactical Nuke III","Tactical Nuke IV","Tactical Nuke V","Tactical Nuke VI","Tactical Nuke VII","Tactical Nuke VIII", "Error"}
}

new const g_ChallengeName[MAX_CHAL][MAXLVL_CHAL][]=
{
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "P228 Compact Marksman I","P228 Compact Marksman II","P228 Compact Marksman III","P228 Compact Marksman IV","P228 Compact Marksman V","P228 Compact Marksman VI","P228 Compact Marksman VII","P228 Compact Marksman VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Scout Marksman I","Scout Marksman II","Scout Marksman III","Scout Marksman IV","Scout Marksman V","Scout Marksman VI","Scout Marksman VII","Scout Marksman VIII", "Error"},
	{ "Master Chef I","Master Chef II","Master Chef III","Master Chef IV","Master Chef V","Master Chef VI","Master Chef VII","Master Chef VIII", "Error"},
	{ "XM1014 Marksman I","XM1014 Marksman II","XM1014 Marksman III","XM1014 Marksman IV","XM1014 Marksman V","XM1014 Marksman VI","XM1014 Marksman VII","XM1014 Marksman VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "MAC-10 Marksman I","MAC-10 Marksman II","MAC-10 Marksman III","MAC-10 Marksman IV","MAC-10 Marksman V","MAC-10 Marksman VI","MAC-10 Marksman VII","MAC-10 Marksman VIII", "Error"},
	{ "AUG Marksman I","AUG Marksman II","AUG Marksman III","AUG Marksman IV","AUG Marksman V","AUG Marksman VI","AUG Marksman VII","AUG Marksman VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Dual Berettas Marksman I","Dual Berettas Marksman II","Dual Berettas Marksman III","Dual Berettas Marksman IV","Dual Berettas Marksman V","Dual Berettas Marksman VI","Dual Berettas Marksman VII","Dual Berettas Marksman VIII", "Error"},
	{ "Fiveseven Marksman I","Fiveseven Marksman II","Fiveseven Marksman III","Fiveseven Marksman IV","Fiveseven Marksman V","Fiveseven Marksman VI","Fiveseven Marksman VII","Fiveseven Marksman VIII", "Error"},
	{ "UMP45 Marksman I","UMP45 Marksman II","UMP45 Marksman III","UMP45 Marksman IV","UMP45 Marksman V","UMP45 Marksman VI","UMP45 Marksman VII","UMP45 Marksman VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Galil Marksman I","Galil Marksman II","Galil Marksman III","Galil Marksman IV","Galil Marksman V","Galil Marksman VI","Galil Marksman VII","Galil Marksman VIII", "Error"},
	{ "FAMAS Marksman I","FAMAS Marksman II","FAMAS Marksman III","FAMAS Marksman IV","FAMAS Marksman V","FAMAS Marksman VI","FAMAS Marksman VII","FAMAS Marksman VIII", "Error"},
	{ "USP .45 Tactical Marksman I","USP .45 Tactical Marksman II","USP .45 Tactical Marksman III","USP .45 Tactical Marksman IV","USP .45 Tactical Marksman V","USP .45 Tactical Marksman VI","USP .45 Tactical Marksman VII","USP .45 Tactical Marksman VIII", "Error"},
	{ "Glock 18C Marksman I","Glock 18C Marksman II","Glock 18C Marksman III","Glock 18C Marksman IV","Glock 18C Marksman V","Glock 18C Marksman VI","Glock 18C Marksman VII","Glock 18C Marksman VIII", "Error"},
	{ "AWP Marksman I","AWP Marksman II","AWP Marksman III","AWP Marksman IV","AWP Marksman V","AWP Marksman VI","AWP Marksman VII","AWP Marksman VIII", "Error"},
	{ "MP5 Marksman I","MP5 Marksman II","MP5 Marksman III","MP5 Marksman IV","MP5 Marksman V","MP5 Marksman VI","MP5 Marksman VII","MP5 Marksman VIII", "Error"},
	{ "M249-SAW Marksman I","M249-SAW Marksman II","M249-SAW Marksman III","M249-SAW Marksman IV","M249-SAW Marksman V","M249-SAW Marksman VI","M249-SAW Marksman VII","M249-SAW Marksman VIII", "Error"},
	{ "M3 Marksman I","M3 Marksman II","M3 Marksman III","M3 Marksman IV","M3 Marksman V","M3 Marksman VI","M3 Marksman VII","M3 Marksman VIII", "Error"},
	{ "M4A1 Carbine Marksman I","M4A1 Carbine Marksman II","M4A1 Carbine Marksman III","M4A1 Carbine Marksman IV","M4A1 Carbine Marksman V","M4A1 Carbine Marksman VI","M4A1 Carbine Marksman VII","M4A1 Carbine Marksman VIII", "Error"},
	{ "TMP Marksman I","TMP Marksman II","TMP Marksman III","TMP Marksman IV","TMP Marksman V","TMP Marksman VI","TMP Marksman VII","TMP Marksman VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Desert Eagle .50 Marksman I","Desert Eagle .50 Marksman II","Desert Eagle .50 Marksman III","Desert Eagle .50 Marksman IV","Desert Eagle .50 Marksman V","Desert Eagle .50 Marksman VI","Desert Eagle .50 Marksman VII","Desert Eagle .50 Marksman VIII", "Error"},
	{ "SG-552 Commando Marksman I","SG-552 Commando Marksman II","SG-552 Commando Marksman III","SG-552 Commando Marksman IV","SG-552 Commando Marksman V","SG-552 Commando Marksman VI","SG-552 Commando Marksman VII","SG-552 Commando Marksman VIII", "Error"},
	{ "AK-47 Marksman I","AK-47 Marksman II","AK-47 Marksman III","AK-47 Marksman IV","AK-47 Marksman V","AK-47 Marksman VI","AK-47 Marksman VII","AK-47 Marksman VIII", "Error"},
	{ "Tactical Knife I","Tactical Knife II","Tactical Knife III","Tactical Knife IV","Tactical Knife V","Tactical Knife VI","Tactical Knife VII","Tactical Knife VIII", "Error"},
	{ "P90 Marksman I","P90 Marksman II","P90 Marksman III","P90 Marksman IV","P90 Marksman V","P90 Marksman VI","P90 Marksman VII","P90 Marksman VIII", "Error"},
	/*Expert Headshot Challenges*/
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "P228 Compact Expert I","P228 Compact Expert II","P228 Compact Expert III","P228 Compact Expert IV","P228 Compact Expert V","P228 Compact Expert VI","P228 Compact Expert VII","P228 Compact Expert VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Scout Expert I","Scout Expert II","Scout Expert III","Scout Expert IV","Scout Expert V","Scout Expert VI","Scout Expert VII","Scout Expert VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "XM1014 Expert I","XM1014 Expert II","XM1014 Expert III","XM1014 Expert IV","XM1014 Expert V","XM1014 Expert VI","XM1014 Expert VII","XM1014 Expert VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "MAC-10 Expert I","MAC-10 Expert II","MAC-10 Expert III","MAC-10 Expert IV","MAC-10 Expert V","MAC-10 Expert VI","MAC-10 Expert VII","MAC-10 Expert VIII", "Error"},
	{ "AUG Expert I","AUG Expert II","AUG Expert III","AUG Expert IV","AUG Expert V","AUG Expert VI","AUG Expert VII","AUG Expert VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Dual Berettas Expert I","Dual Berettas Expert II","Dual Berettas Expert III","Dual Berettas Expert IV","Dual Berettas Expert V","Dual Berettas Expert VI","Dual Berettas Expert VII","Dual Berettas Expert VIII", "Error"},
	{ "Fiveseven Expert I","Fiveseven Expert II","Fiveseven Expert III","Fiveseven Expert IV","Fiveseven Expert V","Fiveseven Expert VI","Fiveseven Expert VII","Fiveseven Expert VIII", "Error"},
	{ "UMP45 Expert I","UMP45 Expert II","UMP45 Expert III","UMP45 Expert IV","UMP45 Expert V","UMP45 Expert VI","UMP45 Expert VII","UMP45 Expert VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Galil Expert I","Galil Expert II","Galil Expert III","Galil Expert IV","Galil Expert V","Galil Expert VI","Galil Expert VII","Galil Expert VIII", "Error"},
	{ "FAMAS Expert I","FAMAS Expert II","FAMAS Expert III","FAMAS Expert IV","FAMAS Expert V","FAMAS Expert VI","FAMAS Expert VII","FAMAS Expert VIII", "Error"},
	{ "USP .45 Tactical Expert I","USP .45 Tactical Expert II","USP .45 Tactical Expert III","USP .45 Tactical Expert IV","USP .45 Tactical Expert V","USP .45 Tactical Expert VI","USP .45 Tactical Expert VII","USP .45 Tactical Expert VIII", "Error"},
	{ "Glock 18C Expert I","Glock 18C Expert II","Glock 18C Expert III","Glock 18C Expert IV","Glock 18C Expert V","Glock 18C Expert VI","Glock 18C Expert VII","Glock 18C Expert VIII", "Error"},
	{ "AWP Expert I","AWP Expert II","AWP Expert III","AWP Expert IV","AWP Expert V","AWP Expert VI","AWP Expert VII","AWP Expert VIII", "Error"},
	{ "MP5 Expert I","MP5 Expert II","MP5 Expert III","MP5 Expert IV","MP5 Expert V","MP5 Expert VI","MP5 Expert VII","MP5 Expert VIII", "Error"},
	{ "M249-SAW Expert I","M249-SAW Expert II","M249-SAW Expert III","M249-SAW Expert IV","M249-SAW Expert V","M249-SAW Expert VI","M249-SAW Expert VII","M249-SAW Expert VIII", "Error"},
	{ "M3 Expert I","M3 Expert II","M3 Expert III","M3 Expert IV","M3 Expert V","M3 Expert VI","M3 Expert VII","M3 Expert VIII", "Error"},
	{ "M4A1 Carbine Expert I","M4A1 Carbine Expert II","M4A1 Carbine Expert III","M4A1 Carbine Expert IV","M4A1 Carbine Expert V","M4A1 Carbine Expert VI","M4A1 Carbine Expert VII","M4A1 Carbine Expert VIII", "Error"},
	{ "TMP Expert I","TMP Expert II","TMP Expert III","TMP Expert IV","TMP Expert V","TMP Expert VI","TMP Expert VII","TMP Expert VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "Desert Eagle .50 Expert I","Desert Eagle .50 Expert II","Desert Eagle .50 Expert III","Desert Eagle .50 Expert IV","Desert Eagle .50 Expert V","Desert Eagle .50 Expert VI","Desert Eagle .50 Expert VII","Desert Eagle .50 Expert VIII", "Error"},
	{ "SG-552 Commando Expert I","SG-552 Commando Expert II","SG-552 Commando Expert III","SG-552 Commando Expert IV","SG-552 Commando Expert V","SG-552 Commando Expert VI","SG-552 Commando Expert VII","SG-552 Commando Expert VIII", "Error"},
	{ "AK-47 Expert I","AK-47 Expert II","AK-47 Expert III","AK-47 Expert IV","AK-47 Expert V","AK-47 Expert VI","AK-47 Expert VII","AK-47 Expert VIII", "Error"},
	{ "Error","Error","Error","Error","Error","Error","Error","Error", "Error"},
	{ "P90 Expert I","P90 Expert II","P90 Expert III","P90 Expert IV","P90 Expert V","P90 Expert VI","P90 Expert VII","P90 Expert VIII", "Error"}
}	

new const gGunName[31][]={ "", "P228 Compact", "", "Scout", "explosive weapon", "XM1014", "", "MAC-10", "AUG", "", "Dual Berettas", "Fiveseven", "UMP45", "",
			"Galil", "Famas", "USP", "Glock", "AWP", "MP5", "M249-SAW", "M3", "M4A1", "TMP", "", "", "Desert Eagle", "SG-552", "AK-47", "knife", "P90" }

new const gRankName[MAX_RANKS][] = 
{ 
	"Private I","Private II","Private III",
	"Pvt First Class I","Pvt First Class II","Pvt First Class III",
	"Specialist I","Specialist II","Specialist III",
	"Corporal I","Corporal II","Corporal III",
	"Sergeant I","Sergeant II","Sergeant III",
	"Staff Sergeant I","Staff Sergeant II","Staff Sergeant III",
	"Sgt First Class I","Sgt First Class II","Sgt First Class III",
	"Master Sergeant I","Master Sergeant II","Master Sergeant III",
	"First Sergeant I","First Sergeant II","First Sergeant III",
	"Sergeant Major I","Sergeant Major II","Sergeant Major III",
	"Comm. Sgt Major I","Comm. Sgt Major II","Comm. Sgt Major III",
	"2nd Lieutenant I","2nd Lieutenant II","2nd Lieutenant III",
	"1st Lieutenant I","1st Lieutenant II","1st Lieutenant III",
	"Captain I","Captain II","Captain III",
	"Major I","Major II","Major III",
	"Lieutenant Colonel I","Lieutenant Colonel II","Lieutenant Colonel III","Lieutenant Colonel IV",
	"Colonel I","Colonel II","Colonel III","Colonel IV",
	"Brigadier General I","Brigadier General II","Brigadier General III","Brigadier General IV",
	"Major General I","Major General II","Major General III","Major General IV",
	"Lieutenant General I","Lieutenant General II","Lieutenant General III","Lieutenant General IV",
	"General I","General II","General III","General IV",
	"Commander"
};

new const gRankXP[MAX_RANKS] =
{
	0,500,1700,
	3600,6200,9500,
	13500,18200,23600,
	29700,36500,44300,
	53100,62900,73700,
	85500,96300,112100,
	126900,142700,159500,
	177300,196100,215900,
	236700,258500,281300,
	305100,329900,355700,
	382700,410900,440300,
	470900,502700,535700,
	569900,605300,641900,
	679700,718700,758900,
	800300,842900,886700,
	931700,977900,1025300,1073900,
	1123700,1175000,1227800,1282100,
	1337900,1395200,1454000,1514300,
	1576100,1639400,1704200,1770500,
	1838300,1906700,1978400,2050700,
	2124500,2199800,2276800,2354900,
	2434700
};

public plugin_init()
{
	register_plugin(PluginName, PluginVersion, "Collin ^"Tirant^" Smith")
	register_cvar("mw2_version", PluginVersion, FCVAR_SPONLY|FCVAR_SERVER)
	set_cvar_string("mw2_version", PluginVersion)
	
	new ip[32]
	get_user_ip ( 0, ip, charsmax(ip), 1 ) 
	if (!contain(ip, "192.168.") && !equal(ip, "68.232.165.165"))
	{
		set_fail_state("You are hosting an illegal copy of MW2 mod, please purchase a copy to run this mod!");
		return plugin_end()
	}
	csdm_set_intromsg(0)
	
	register_clcmd("chooseteam", "clcmd_changeteam")
	register_clcmd("jointeam", "clcmd_changeteam")
	register_clcmd("drop", "clcmd_drop")
	
	register_clcmd("say", "cmdSay",0, "<target> ")
	register_clcmd("say_team", "cmdSay",0, "<target> ")
	
	register_concmd("cod_addxp","cmdGiveXP",ADMIN_CVAR," <name> <xp>")
	register_concmd("cod_addstats","cmdGiveStats",ADMIN_CVAR," <name> <csw> <headshot=1> <stats>")
	
	//Fakemeta Forwards
	register_forward(FM_GetGameDescription, "fw_GetGameDescription");
	register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue");
	register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged");
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_PlayerPreThink, "fw_Player_PreThink");
	register_forward(FM_TraceLine,"fw_Traceline_Post",1);
	register_forward(FM_Touch,"fw_Touch");
	register_forward(FM_EmitSound, "fw_EmitSnd");
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_StartFrame, "fw_StartFrame");
	
	//HAM Forwards
	RegisterHam(Ham_Spawn, "player", "ham_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "ham_TakeDamage")
	RegisterHam(Ham_Touch, "weapon_shield", "ham_WeaponCleaner_Post", 1)
	RegisterHam(Ham_Touch, "weaponbox", "ham_WeaponCleaner_Post", 1)
	RegisterHam(Ham_Think, "grenade", "ham_ThinkGrenade")
	new szWeapon[20];
	for (new i=CSW_P228;i<=CSW_P90;i++) 
	{         
		if (get_weaponname(i, szWeapon, charsmax(szWeapon)))
		RegisterHam(Ham_Weapon_PrimaryAttack, szWeapon, "ham_PrimaryAttack")
		if(!(NOCLIP_WPN_BS & (1<<i)) && get_weaponname(i, szWeapon, charsmax(szWeapon)))
		{
			if(!(SHOTGUNS_BS & (1<<i)))
				RegisterHam(Ham_Weapon_Reload, szWeapon, "ham_Reload_Post", 1)
		}
	}

	//Round Forwards
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	//Game Events
	register_event("CurWeapon","ev_CurWeapon","be","1=1")
	register_event("StatusValue", "setTeam", "be", "1=1");
	register_event("StatusValue", "on_ShowStatus", "be", "1=2", "2!0");
	register_event("StatusValue", "on_HideStatus", "be", "1=1", "2=0");
	register_event("AmmoX", "ev_AmmoX", "be", "1=1", "1=2", "1=3", "1=4", "1=5", "1=6", "1=7", "1=8", "1=9", "1=10")
	
	register_touch("grenade", "player", "touch_nade")
	
	//Message Forwards
	register_message(get_user_msgid("StatusValue"), "hook_StatusValue");
	register_message(get_user_msgid("TextMsg"), "hook_TextMessage")
	register_message(get_user_msgid("ShowMenu"), "message_show_menu")
	register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu")
	
	//Menus
	{
		//Main Menus
		register_menucmd(register_menuid("R0295"),KEYS_MAINMENU,"cod_menu_pushed")
		register_menucmd(register_menuid("E5150"),KEYS_PRESTIGE,"cod_prestige1_pushed")
		register_menucmd(register_menuid("F6150"),KEYS_PRESTIGE,"cod_prestige2_pushed")
		register_menucmd(register_menuid("R1095"),KEYS_STATS,"stats_menu_pushed")
		register_menucmd(register_menuid("A1234"),KEYS_CLASSES,"class_menu_pushed")
		register_menucmd(register_menuid("B5678"),KEYS_CLASSESCUSTOM,"classcustom_menu_pushed")
		register_menucmd(register_menuid("C91011"),KEYS_CLASSESEDITOR,"classeditor_menu_pushed")
		register_menucmd(register_menuid("D1213"),KEYS_EDITOR,"editor_menu_pushed")
		
		//Primary Weapons
		register_menucmd(register_menuid("G1029"),KEYS_GUNMAIN,"prim_weapons_pushed")
		register_menucmd(register_menuid("H3082"),KEYS_GUNASS,"prim_ass_pushed")
		register_menucmd(register_menuid("I0392"),KEYS_GUNSMG,"prim_smg_pushed")
		register_menucmd(register_menuid("J2058"),KEYS_GUNSHO,"prim_sho_pushed")
		register_menucmd(register_menuid("K3018"),KEYS_GUNSNI,"prim_sni_pushed")
		register_menucmd(register_menuid("L0281"),KEYS_GUNMAC,"prim_mac_pushed")
		register_menucmd(register_menuid("M1028"),KEYS_GUNSEC,"sec_weapons_pushed")
		
		//Perk Menus
		register_menucmd(register_menuid("N0193"),KEYS_PERKS,"cod_perks1_pushed")
		register_menucmd(register_menuid("O1024"),KEYS_PERKS,"cod_perks2_pushed")
		register_menucmd(register_menuid("P2759"),KEYS_PERKS,"cod_perks3_pushed")
		register_menucmd(register_menuid("Q8572"),KEYS_EQUIPTMENT,"cod_equipt_pushed")
	}
	
	//Blocks dead bodies
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET)
	
	//Sets game name
	formatex(g_ModName, charsmax(g_ModName), "%s", PluginName)
	
	//Fake Damage Killers
	g_ShieldKiller = create_entity("weapon_knife")
	g_AirstrikeKiller = create_entity("grenade")
	g_NukeKiller = create_entity("null")
	
	//Set Server Vars
	server_cmd("mp_freezetime 13")
	
	//MSG vars and other important vars
	g_MaxPlayers = get_maxplayers();
	gmsgStatusText = get_user_msgid("StatusText");
	gmsgScreenFade = get_user_msgid("ScreenFade");
	gmsgScreenShake = get_user_msgid ("ScreenShake");
	gmsgServerName = get_user_msgid("ServerName");
	gmsgBarTime = get_user_msgid("BarTime");
	gmsgSetFOV = get_user_msgid("SetFOV");
	gmsgHideWeapon = get_user_msgid("HideWeapon")
	gmsgTextMsg = get_user_msgid("TextMsg")
	gHudSyncInfo = CreateHudSyncObj();

	//UAV
	gmsgHostageAdd = get_user_msgid("HostagePos");
	gmsgHostageDel = get_user_msgid("HostageK");
	
	g_pcvar_hostname = get_cvar_pointer("hostname")
	
	set_task(2.5,"task_GameName");
	set_task(1.0,"task_HPRegenLoop",_,_,_,"b")
	set_task(2.5,"task_RadarScanner", UAVTERROR_TASK,_,_,"b")
	set_task(1.0,"task_DelayScanner")
	
	return PLUGIN_CONTINUE
}

public task_DelayScanner()
	set_task(2.5,"task_RadarScanner", UAVCOUNTER_TASK,_,_,"b")

public task_GameName()
{
	static szHostname[64]
	get_pcvar_string(g_pcvar_hostname, g_szHostname, 63 );
	formatex( szHostname, 63, "%s - %s", g_szHostname, (g_RandMode == TDM ? "Team Deathmatch" : "Domination") );
	set_pcvar_string( g_pcvar_hostname, szHostname );
	message_begin( MSG_BROADCAST, gmsgServerName );
	write_string( szHostname );
	message_end( );	
}

public plugin_precache()
{
	g_pcvar_doublexp = register_cvar("mw2_doublexp", "1")
	g_DoubleXP = get_pcvar_num(g_pcvar_doublexp) == 1 ? true : false
	g_pcvar_playto = register_cvar("mw2_winnumber", "10000")
	g_WinNumber = get_pcvar_num(g_pcvar_playto)
	g_pcvar_savetype = register_cvar("mw2_savetype", "1")
	g_iSaveType = get_pcvar_num(g_pcvar_savetype)
	
	g_TeamRand = random_num(1,3)
	if (g_TeamRand == 3) g_TeamRand = 1
	new szModel[64];
	switch (g_TeamRand)
	{
		case USA:
		{
			formatex(szModel, charsmax(szModel), "models/player/%s/%s.mdl", g_ArmyRanger, g_ArmyRanger );
			engfunc(EngFunc_PrecacheModel, szModel)
			formatex(szModel, charsmax(szModel), "models/player/%s/%s.mdl", g_Opfor, g_Opfor );
			engfunc(EngFunc_PrecacheModel, szModel)
		}
		case SAS:
		{
			formatex(szModel, charsmax(szModel), "models/player/%s/%s.mdl", g_SAS, g_SAS );
			engfunc(EngFunc_PrecacheModel, szModel)
			formatex(szModel, charsmax(szModel), "models/player/%s/%s.mdl", g_Spetsnaz, g_Spetsnaz );
			engfunc(EngFunc_PrecacheModel, szModel)
		}
	}
	
	g_RandMode = g_TeamRand
	if(g_RandMode == SAS)
	{
		server_cmd("amx_csflags_stop")
		server_cmd("amx_csflags_enabled 0")
		server_cmd("mp_timelimit 0")
	}
	else
	{
		server_cmd("mp_timelimit 15")
	}
	
	//Models
	for (new i=0; i< sizeof gFragModel; i++)
		precache_model(gFragModel[i]);
		
	for (new i=0; i< sizeof gShieldModel; i++)
		precache_model(gShieldModel[i]);	
	
	//Main Sounds
	precache_sound(gSoundRank);
	precache_sound(gItemSelected);
	precache_sound(gSoundBadge);
	precache_sound(gKillBonus);
	precache_sound(gPayback);	
	precache_sound(gBulletImpact);	
	precache_sound(gPlayerSpawn);	
	precache_sound(gGrenadeEXP);
	precache_sound(gVictory);
	precache_sound(gDefeat);
	
	for (new i=0; i< ROUND_SOUNDS; i++)
		precache_sound(gRoundStart[i]);	
	
	for (new i=0; i< sizeof gTangoDown; i++)
		precache_sound(gTangoDown[i])
	
	
	switch (g_RandMode)
	{
		case TDM:
		{
			//TDM Sounds
			//precache_sound(gTDMStart);
			precache_sound(gWinning);
			precache_sound(gLosing);
			precache_sound(gHasLead);
			precache_sound(gLostLead);
		}
		case DOMINATION:
		{
			//Domination
			//precache_sound(gDominationStart);	
		}
	}

	for (new i=1; i < 3; i++)
	{
		precache_sound(gModeSound[i])
	}
	
	//Perks
	precache_sound(gOneManArmy);
	
	//Shield
	precache_sound(gShieldBash);
	precache_sound(gShieldBashHit);
	
	//Killstreaks
	for (new i=0; i < TOT_KILLSTREAKS; i++)
	{
		precache_sound(gKillstreakSounds[i][KS_GIVE]);
		precache_sound(gKillstreakSounds[i][KS_FRIEND]);
		precache_sound(gKillstreakSounds[i][KS_ENEMY]);
	}
	
	//UAV Call Sound (sound effect)
	precache_sound(gUAVEffect);
	//Predator Emit Sound (sound effect)
	precache_sound(gPredEffect);
	//EMP Call Sound (sound effect)
	precache_sound(gEMPEffect);
	
	//Airstrike
	precache_model(gAirstrikeJet)
	gSpriteExplosion = precache_model("sprites/zerogxplode.spr") //bexplo
	for (new i=0; i< sizeof gAirFly; i++)
		precache_sound(gAirFly[i])
		
	//Predator
	precache_model(gPredatorRocket);
	g_Trail = precache_model("sprites/smoke.spr")
}

public plugin_end()
{
	remove_task(1+EMPTEAM_TASK)
	remove_task(2+EMPTEAM_TASK)
	
	nvault_close(g_Vault);
	
	return PLUGIN_HANDLED
}

public CMD_CoDMenu(id)
{
	new szMenuBody[256];
			
	new nLen = format( szMenuBody, 255, "\rMW2 Barracks:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \dHelp (Under Construction)"); //Make sure to enable the key again up top
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wStats");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \dChallenges (Under Construction)" ); //Make sure to enable the key again up top
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wClass Menu");
	if(g_canprestige[id])
		nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wEnter Prestige Mode");
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \dEnter Prestige Mode");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r0. \wClose" );
		
	show_menu(id,KEYS_MAINMENU,szMenuBody,-1,"R0295")
}

public cod_menu_pushed(id,key)
{
	switch(key)
	{
		//case 0: CMD_CoDHelpMenu(id)
		case 1: CMD_CoDStatsMenu(id)
		//case 2: CMD_CoDMenu(id)
		case 3: CMD_ClassMenu(id)
		case 8:
		{
			if(g_canprestige[id]) prestige_check(id)
			else CMD_CoDMenu(id)
		}
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public prestige_check(id)
{
	new szMenuBody[256];
			
	new nLen = format( szMenuBody, 255, "\rAre you sure you want to Prestige?^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wYes^n");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wNo^n");
		
	show_menu(id,KEYS_PRESTIGE,szMenuBody,-1,"E5150")
}

public cod_prestige1_pushed(id,key)
{
	switch(key)
	{
		case 0:
		{
			prestige_check2(id)
			client_cmd(id, "spk weapons/c4_plant.wav");
		}
		case 1: client_cmd(id, "spk misc/sheep.wav");
	}
	return PLUGIN_HANDLED;
}

public prestige_check2(id)
{
	new szMenuBody[256];
			
	new nLen = format( szMenuBody, 255, "\rThere is no going back...^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wProceed^n");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wTurn back^n");
		
	show_menu(id,KEYS_PRESTIGE,szMenuBody,-1,"F6150")
}

public cod_prestige2_pushed(id,key)
{
	switch(key)
	{
		case 0: prestige_player(id)
		case 1: client_cmd(id, "spk misc/sheep.wav");
	}
	return PLUGIN_HANDLED;
}

public prestige_player(id)
{
	if (g_canprestige[id] && g_Prestige[id] < 10)
	{
		g_Prestige[id]++
		reset_codstats(id)
		
		client_cmd(id, "spk weapons/c4_explode1.wav");
		client_print(id, print_chat, "[MW2] You have entered prestige mode!");
		
		new idname[35]
		get_user_name(id,idname,34)
		client_print(0, print_chat, "%s has entered Prestige Mode", idname);
		
		g_canprestige[id] = false
		check_level(id)
		SaveLevel(id)
	}
	else
	{
		client_print(id, print_chat, "[MW2] You cannot prestige anymore!");
		client_cmd(id, "spk buttons/button11.wav");
	}
}

public reset_codstats(id)
{
	g_Experience[id] = 0
	g_PlayerRank[id] = 0
	g_PlayerClass[id] = NONE
	
	if (is_user_alive(id))
		give_weapons(id)
		
	/*for ( new i=1; i<31; i++)
	{
		g_PlayerChallenges[id][MARKSMAN][i] = 0
		g_PlayerChallenges[id][ELITE][i] = 0
		g_GunStats[id][GUN_KILLS][i] = 0
		g_GunStats[id][GUN_HEADSHOTS][i] = 0
	}*/

	for ( new i=1; i<7; i++)
	{
		g_CustomPerk[id][0][i] = 0
		g_CustomPerk[id][1][i] = 0
		g_CustomPerk[id][2][i] = 0
		g_CustomEquiptment[id][i] = 0
		g_CustomWeapon[PRIMARY][id][i] = 0
		g_CustomWeapon[SECONDARY][id][i] = 0
	}
	
	/*for ( new i=0; i<4; i++)
	{
		g_ChallangeCounter[i][id] = 0
	}*/
}

public CMD_CoDStatsMenu(id)
{
	new szMenuBody[256];
			
	new nLen = format( szMenuBody, 255, "\rChallenges:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wSubmachine Guns");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wAssault Rifles");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wOther");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wPistols");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r5. \wKillstreaks");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack to Barracks");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_STATS,szMenuBody,-1,"R1095")
}

public stats_menu_pushed(id,key)
{
	switch(key)
	{
		case 0:
		{
			challenges_stats_smg(id)
			CMD_CoDStatsMenu(id)
		}
		case 1:
		{
			challenges_stats_ass(id)
			CMD_CoDStatsMenu(id)
		}
		case 2:
		{
			challenges_stats_snip(id)
			CMD_CoDStatsMenu(id)
		}
		case 3:
		{
			challenges_stats_pist(id)
			CMD_CoDStatsMenu(id)
		}
		case 4:
		{
			challenges_stats_killstreaks(id)
			CMD_CoDStatsMenu(id)
		}
		case 8:
		{
			//CMD_CoDStatsMenu(id)
			CMD_CoDMenu(id)
		}
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public challenges_stats_smg(id)
{
	new tempstring[164];
	new motd[2048];
	format(motd,2048,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b>Your Challenge Progress:</strong></b>")

	format(tempstring,100,"<br>MAC-10 Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_MAC10], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_MAC10]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"MAC-10 Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_MAC10], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_MAC10]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>TMP Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_TMP], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_TMP]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"TMP Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_TMP], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_TMP]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>UMP45 Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_UMP45], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_UMP45]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"UMP45 Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_UMP45], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_UMP45]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>MP5 Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_MP5NAVY], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_MP5NAVY]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"MP5 Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_MP5NAVY], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_MP5NAVY]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>P90 Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_P90], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_P90]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"P90 Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_P90], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_P90]]+1)
	add(motd,2048,tempstring);
	
	add(motd,2048,"</font></body></html>")
	
	show_motd(id,motd,"Challenge Progress: SMG");
}

public challenges_stats_ass(id)
{
	new tempstring[164];
	new motd[2048];
	format(motd,2048,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b>Your Challenge Progress:</strong></b>")
	
	format(tempstring,100,"<br>SIG-552 Commando Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_SG552], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_SG552]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"SIG-552 Commando Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_SG552], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_SG552]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>AUG Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_AUG], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_AUG]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"AUG Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_AUG], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_AUG]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>Galil Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_GALIL], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_GALIL]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"Galil Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_GALIL], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_GALIL]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>FAMAS Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_FAMAS], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_FAMAS]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"FAMAS Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_FAMAS], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_FAMAS]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>M4A1 Carbine Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_M4A1], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_M4A1]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"M4A1 Carbine Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_M4A1], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_M4A1]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>AK-47 Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_AK47], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_AK47]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"AK-47 Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_AK47], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_AK47]]+1)
	add(motd,2048,tempstring);
	
	add(motd,2048,"</font></body></html>")
	
	show_motd(id,motd,"Challenge Progress: Assault Rifle");
}

public challenges_stats_snip(id)
{
	new tempstring[164];
	new motd[2048];
	format(motd,2048,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b>Your Challenge Progress:</strong></b>")
	
	format(tempstring,100,"<br>Scout Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_SCOUT], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_SCOUT]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"Scout Expert - %d / %d<br>",g_GunStats[id][GUN_HEADSHOTS][CSW_SCOUT], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_SCOUT]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>AWP Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_AWP], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_AWP]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"AWP Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_AWP], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_AWP]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>M249-SAW Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_M249], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_M249]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"M249-SAW Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_M249], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_M249]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>XM1014 Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_XM1014], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_XM1014]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"XM1014 Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_XM1014], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_XM1014]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>M3 Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_M3], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_M3]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"M3 Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_M3], gChalHS[PRIMARY][g_PlayerChallenges[id][ELITE][CSW_M3]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>Master Chef - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_HEGRENADE], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_HEGRENADE]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>Tactical Knife - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_KNIFE], gChalLvls[PRIMARY][g_PlayerChallenges[id][MARKSMAN][CSW_KNIFE]]+1)
	add(motd,2048,tempstring);
	
	add(motd,2048,"</font></body></html>")
	
	show_motd(id,motd,"Challenge Progress: Other");
}

public challenges_stats_pist(id)
{
	new tempstring[164];
	new motd[2048];
	format(motd,2048,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b>Your Challenge Progress:</strong></b>")
	
	format(tempstring,100,"<br>Glock 18C Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_GLOCK18], gChalLvls[SECONDARY][g_PlayerChallenges[id][MARKSMAN][CSW_GLOCK18]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"Glock 18C Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_GLOCK18], gChalHS[SECONDARY][g_PlayerChallenges[id][ELITE][CSW_GLOCK18]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>USP .45 Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_USP], gChalLvls[SECONDARY][g_PlayerChallenges[id][MARKSMAN][CSW_USP]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"USP .45 Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_USP], gChalHS[SECONDARY][g_PlayerChallenges[id][ELITE][CSW_USP]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>P228 Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_P228], gChalLvls[SECONDARY][g_PlayerChallenges[id][MARKSMAN][CSW_P228]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"P228 Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_P228], gChalHS[SECONDARY][g_PlayerChallenges[id][ELITE][CSW_P228]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>Deagle Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_DEAGLE], gChalLvls[SECONDARY][g_PlayerChallenges[id][MARKSMAN][CSW_DEAGLE]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"Deagle Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_DEAGLE], gChalHS[SECONDARY][g_PlayerChallenges[id][ELITE][CSW_DEAGLE]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>Fiveseven Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_FIVESEVEN], gChalLvls[SECONDARY][g_PlayerChallenges[id][MARKSMAN][CSW_FIVESEVEN]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"Fiveseven Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_FIVESEVEN], gChalHS[SECONDARY][g_PlayerChallenges[id][ELITE][CSW_FIVESEVEN]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>Elites Marksman - %d / %d<br>", g_GunStats[id][GUN_KILLS][CSW_ELITE], gChalLvls[SECONDARY][g_PlayerChallenges[id][MARKSMAN][CSW_ELITE]]+1)
	add(motd,2048,tempstring);
	format(tempstring,100,"Elites Expert - %d / %d<br>", g_GunStats[id][GUN_HEADSHOTS][CSW_ELITE], gChalHS[SECONDARY][g_PlayerChallenges[id][ELITE][CSW_ELITE]]+1)
	add(motd,2048,tempstring);
	
	add(motd,2048,"</font></body></html>")
	
	show_motd(id,motd,"Challenge Progress: Pistols");
}

public challenges_stats_killstreaks(id)
{
	new tempstring[164];
	new motd[2048];
	format(motd,2048,"<html><body bgcolor=^"#474642^"><font size=^"2^" face=^"verdana^" color=^"FFFFFF^"><strong><b>Your Challenge Progress:</strong></b><br>")
	
	format(tempstring,100,"<br>%s - %d / %d<br>", g_ChalNameKillstreaks[KS_UAV][g_KillstreakChal[id][KS_UAV]], g_NumKillstreaks[id][KS_UAV], gKSChalNum[g_KillstreakChal[id][KS_UAV]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>%s - %d / %d<br>", g_ChalNameKillstreaks[KS_COU][g_KillstreakChal[id][KS_COU]], g_NumKillstreaks[id][KS_COU], gKSChalNum[g_KillstreakChal[id][KS_COU]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>%s - %d / %d<br>", g_ChalNameKillstreaks[KS_AIR][g_KillstreakChal[id][KS_AIR]], g_NumKillstreaks[id][KS_AIR], gKSChalNum[g_KillstreakChal[id][KS_AIR]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>%s - %d / %d<br>", g_ChalNameKillstreaks[KS_PRED][g_KillstreakChal[id][KS_PRED]], g_NumKillstreaks[id][KS_PRED], gKSChalNum[g_KillstreakChal[id][KS_PRED]]+1)
	add(motd,2048,tempstring);

	format(tempstring,100,"<br>%s - %d / %d<br>", g_ChalNameKillstreaks[KS_EMP][g_KillstreakChal[id][KS_EMP]], g_NumKillstreaks[id][KS_EMP], gKSChalNum[g_KillstreakChal[id][KS_EMP]]+1)
	add(motd,2048,tempstring);

	format(tempstring,100,"<br>%s - %d / %d<br>", g_ChalNameKillstreaks[KS_NUKE][g_KillstreakChal[id][KS_NUKE]], g_NumKillstreaks[id][KS_NUKE], gKSChalNum[g_KillstreakChal[id][KS_NUKE]]+1)
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br><br>----Killstreak Kills----<br>")
	add(motd,2048,tempstring);
	
	format(tempstring,100,"<br>%s - %d / %d<br>", g_ChalNameKillstreakKills[KS_AIR][g_KillstreakChalKill[id][KS_AIR]], g_KillstreakKills[id][KS_AIR], gKSChalKills[g_KillstreakChalKill[id][KS_AIR]]+1)
	add(motd,2048,tempstring);

	format(tempstring,100,"<br>%s - %d / %d<br>", g_ChalNameKillstreakKills[KS_PRED][g_KillstreakChalKill[id][KS_PRED]], g_KillstreakKills[id][KS_PRED], gKSChalKills[g_KillstreakChalKill[id][KS_PRED]]+1)
	add(motd,2048,tempstring);

	format(tempstring,100,"<br>%s - %d / %d<br>", g_ChalNameKillstreakKills[KS_NUKE][g_KillstreakChalKill[id][KS_NUKE]], g_KillstreakKills[id][KS_NUKE], gKSChalKills[g_KillstreakChalKill[id][KS_NUKE]]+1)
	add(motd,2048,tempstring);
	
	add(motd,2048,"</font></body></html>")
	
	show_motd(id,motd,"Challenge Progress: Killstreaks");
}

public CMD_ClassMenu(id)
{
	new szMenuBody[2048];
			
	new nLen = format( szMenuBody, 2047, "\rClasses:^n" );
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r1. \wGrenadier");// (AUG + Fiveseven + Semtex)
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n    [\yScavenger\w] [\yStopping Power\w] [\yCommando\w]");
	
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r2. \wFirst Recon");// (UMP45 + Deagle + Stun)
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n    [\yFlag Runner\w] [\yLightweight\w] [\yNinja\w]");
	
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r3. \wOverwatch" );// (M3 + Deagle + Frag)
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n    [\ySlight of Hand\w] [\yDanger Close\w] [\yScrambler\w]");
	
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r4. \wScout Sniper");// (Scout + USP + Frag)
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n    [\yFlak Jacket\w] [\yCold-Blooded\w] [\yScrambler\w]");
		
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r5. \wRiot Control");// (Riot Shield)
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n    [\yFlag Runner\w] [\yHardline\w] [\yCommando\w]");
		
	if (g_PlayerRank[id] > 3)
		nLen += format( szMenuBody[nLen], 2047-nLen, "^n^n\r6. \wCustom Classes");
	else
		nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r6. \wCustom Classes [\rRank 5\w]");
		
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n^n\r9. \wBack");
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_CLASSES,szMenuBody,-1,"A1234")	
}

public class_menu_pushed(id,key)
{
	switch(key)
	{
		case 0..4:
		{
			if (g_isalive[id] && g_PlayerClass[id] && g_Perk[id][0] == PRK1_ONEMA && !task_exists(id+OMA_TASK))
			{
				g_PlayerClass[id] = key+7
				ManageBar(id, 6);
				set_task(5.0, "Perk_ClassChanger", id+OMA_TASK)
				client_cmd(id, "spk %s", gOneManArmy);
				strip_user_weapons(id)		
			}
			else if (!g_isalive[id] || g_PlayerClass[id])
			{
				g_PlayerClass[id] = key+7
				client_print(id, print_center, "Your class will be loaded the next time you spawn.");
			}
			else
			{
				g_PlayerClass[id] = key+7
				give_weapons(id)
			}
		}
		case 5:
		{
			if (g_PlayerRank[id] > 3)
				CMD_ClassMenuCustom(id)
			else
				CMD_ClassMenu(id)
		}
		case 8: CMD_CoDMenu(id)
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED
}

public Perk_ClassChanger(taskid)
{
	taskid-=OMA_TASK;
	if (g_isalive[taskid] && g_PlayerClass[taskid])
	{
		g_Shielded[taskid] = false
		g_HasShield[taskid] = false
		give_weapons(taskid)
		ManageBar(taskid, 0);
	}
}

public CMD_ClassMenuCustom(id)
{
	new szMenuBody[2048];
		
	new nLen = format( szMenuBody, 2047, "\rCustom Classes:^n" );

	new csw
	new wpnid[2][7], wpnname[2][7][32]
	new perkname[3][7][16], equname[7][15]
	
	new totalclasses = (g_Prestige[id]+1)/2
	totalclasses+=2
	if (access(id, ADMIN_MEMBERSHIP)) totalclasses = 7
	
	for ( new i=1; i<totalclasses; i++)
	{
		wpnid[PRIMARY][i] = g_CustomWeapon[PRIMARY][id][i]
		if (wpnid[PRIMARY][i])
		{
			if (wpnid[PRIMARY][i] == SHIELD)
			{
				wpnname[PRIMARY][i] = "Riot Shield"
			}
			else
			{
				csw = wpnid[PRIMARY][i]
				get_weaponname(csw,wpnname[PRIMARY][i],charsmax(wpnname))
				replace_all(wpnname[PRIMARY][i], charsmax(wpnname), "weapon_", "")
				strtoupper(wpnname[PRIMARY][i])
			}
		}
		else
			wpnname[PRIMARY][i] = "None"
	
		wpnid[SECONDARY][i] = g_CustomWeapon[SECONDARY][id][i]
		if (wpnid[SECONDARY][i])
		{
			if (wpnid[PRIMARY][i] == SHIELD)
			{
				wpnname[SECONDARY][i] = "-None Allowed-"
			}
			else
			{
				csw = wpnid[SECONDARY][i]
				get_weaponname(csw,wpnname[SECONDARY][i],charsmax(wpnname[]))
				replace_all(wpnname[SECONDARY][i] , charsmax(wpnname), "weapon_", "")
				strtoupper(wpnname[SECONDARY][i])
			}
		}
		else
			wpnname[SECONDARY][i] = "None"
			
		perkname[0][i] = "ERROR"
		perkname[1][i] = "ERROR"
		perkname[2][i] = "ERROR"
		switch (g_CustomPerk[id][0][i])
		{
			case PRK1_MARAT: perkname[0][i] = "Flag Runner"
			case PRK1_SLIGH: perkname[0][i] = "Slight of Hand"
			case PRK1_SCAVE: perkname[0][i] = "Scavenger"
			case PRK1_BLING: perkname[0][i] = "Flak Jacket"
			case PRK1_ONEMA: perkname[0][i] = "One Man Army"
		}

		switch (g_CustomPerk[id][1][i])
		{
			case PRK2_STOPP: perkname[1][i] = "Stopping Power"
			case PRK2_LIGHT: perkname[1][i] = "Lightweight"
			case PRK2_HARDL: perkname[1][i] = "Hardline"
			case PRK2_COLDB: perkname[1][i] = "Cold-Blooded"
			case PRK2_DANGE: perkname[1][i] = "Danger Close"
		}
		
		switch (g_CustomPerk[id][2][i])
		{
			case PRK3_COMMA: perkname[2][i] = "Commando"
			case PRK3_STEAD: perkname[2][i] = "Steady Aim"
			case PRK3_SCRAM: perkname[2][i] = "Scrambler"
			case PRK3_NINJA: perkname[2][i] = "Ninja"
			case PRK3_LASTS: perkname[2][i] = "Last Stand"
		}
		
		if (wpnid[SECONDARY][i] == SHIELD)
		{
			equname[i] = "-None Allowed-"
		}
		else
		{
			switch (g_CustomEquiptment[id][i])
			{
				case EQU_FRAG: equname[i] = "Frag"
				case EQU_FLASH: equname[i] = "Flash"
				case EQU_STUN: equname[i] = "Stun"
				case EQU_SMTX: equname[i] = "Semtex"
			}
		}
		
		nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r%d. \w%s|%s|%s", i, wpnname[PRIMARY][i], wpnname[SECONDARY][i], equname[i]);
		nLen += format( szMenuBody[nLen], 2047-nLen, "^n    [\y%s\w][\y%s\w][\y%s\w]", perkname[0][i], perkname[1][i], perkname[2][i]);
	}
	
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n^n\r7. \wRegular Classes");
	
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n^n\r8. \wEdit Classes");
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n^n\r0. \wExit" );
		
	show_menu(id,KEYS_CLASSESCUSTOM,szMenuBody,-1,"B5678")
}

public classcustom_menu_pushed(id, key)
{
	new totalclasses = (g_Prestige[id]+1)/2
	if (access(id, ADMIN_MEMBERSHIP)) totalclasses = 5
	switch(key)
	{
		case 0..5:
		{
			if (key<=totalclasses)
			{
				if (g_isalive[id] && g_PlayerClass[id] && g_Perk[id][0] == PRK1_ONEMA && !task_exists(id+OMA_TASK))
				{
					g_PlayerClass[id] = key+1
					ManageBar(id, 6);
					set_task(5.0, "Perk_ClassChanger", id+OMA_TASK)
					client_cmd(id, "spk %s", gOneManArmy);
					strip_user_weapons(id)		
				}
				else if (!g_isalive[id] || g_PlayerClass[id])
				{
					g_PlayerClass[id] = key+1
					client_print(id, print_center, "Your class will be loaded the next time you spawn.");
				}
				else
				{
					g_PlayerClass[id] = key+1
					give_weapons(id)
				}
			}
		}
		case 6:
		{
			CMD_ClassMenu(id)
		}
		case 7:
		{
			CMD_ClassMenuEditor(id)
		}
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED
}

public CMD_ClassMenuEditor(id)
{
	new szMenuBody[2048];
	
	new nLen = format( szMenuBody, 2047, "\rSelect a class to edit:^n" );

	new csw
	new wpnid[2][7], wpnname[2][7][32]
	new perkname[3][7][32], equname[7][32]
	
	new totalclasses = (g_Prestige[id]+1)/2
	totalclasses+=2
	if (access(id, ADMIN_MEMBERSHIP)) totalclasses = 7
	
	for (new i=1; i<totalclasses; i++)
	{
		wpnid[PRIMARY][i] = g_CustomWeapon[PRIMARY][id][i]
		if (wpnid[PRIMARY][i])
		{
			if (wpnid[PRIMARY][i] == SHIELD)
			{
				wpnname[PRIMARY][i] = "Riot Shield"
				client_print(id, print_center, "You can't use a secondary weapon or equiptment with this primary");
			}
			else
			{
				csw = wpnid[PRIMARY][i]
				get_weaponname(csw,wpnname[PRIMARY][i],31)
				replace_all(wpnname[PRIMARY][i], 31, "weapon_", "")
				strtoupper(wpnname[PRIMARY][i])
			}
		}
		else
			wpnname[PRIMARY][i] = "-None-"
	
		wpnid[SECONDARY][i] = g_CustomWeapon[SECONDARY][id][i]
		if (wpnid[SECONDARY][i])
		{
			if (wpnid[PRIMARY][i] == SHIELD)
			{
				wpnname[SECONDARY][i] = "-None-"
			}
			else
			{
				csw = wpnid[SECONDARY][i]
				get_weaponname(csw,wpnname[SECONDARY][i],31)
				replace_all(wpnname[SECONDARY][i] , 31, "weapon_", "")
				strtoupper(wpnname[SECONDARY][i])
			}
		}
		else
			wpnname[SECONDARY][i] = "-None-"

		perkname[0][i] = "ERROR"
		perkname[1][i] = "ERROR"
		perkname[2][i] = "ERROR"
		switch (g_CustomPerk[id][0][i])
		{
			case PRK1_MARAT: perkname[0][i] = "Flag Runner"
			case PRK1_SLIGH: perkname[0][i] = "Slight of Hand"
			case PRK1_SCAVE: perkname[0][i] = "Scavenger"
			case PRK1_BLING: perkname[0][i] = "Flak Jacket"
			case PRK1_ONEMA: perkname[0][i] = "One Man Army"
		}
		
		switch (g_CustomPerk[id][1][i])
		{
			case PRK2_STOPP: perkname[1][i] = "Stopping Power"
			case PRK2_LIGHT: perkname[1][i] = "Lightweight"
			case PRK2_HARDL: perkname[1][i] = "Hardline"
			case PRK2_COLDB: perkname[1][i] = "Cold-Blooded"
			case PRK2_DANGE: perkname[1][i] = "Danger Close"
		}
		
		switch (g_CustomPerk[id][2][i])
		{
			case PRK3_COMMA: perkname[2][i] = "Commando"
			case PRK3_STEAD: perkname[2][i] = "Steady Aim"
			case PRK3_SCRAM: perkname[2][i] = "Scrambler"
			case PRK3_NINJA: perkname[2][i] = "Ninja"
			case PRK3_LASTS: perkname[2][i] = "Last Stand"
		}
		
		if (wpnid[SECONDARY][i] == SHIELD)
		{
			equname[i] = "-None-"
		}
		else
		{
			switch (g_CustomEquiptment[id][i])
			{
				case EQU_FRAG: equname[i] = "Frag"
				case EQU_FLASH: equname[i] = "Flash"
				case EQU_STUN: equname[i] = "Stun"
				case EQU_SMTX: equname[i] = "Semtex"
			}
		}
		
		nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r%d. \w%s|%s|%s", i, wpnname[PRIMARY][i], wpnname[SECONDARY][i], equname[i]);// (%s + %s + %s)" wpnname[PRIMARY][i], wpnname[SECONDARY][i], equname[i]
		nLen += format( szMenuBody[nLen], 2047-nLen, "^n    [\y%s\w][\y%s\w][\y%s\w]", perkname[0][i], perkname[1][i], perkname[2][i]);
	}
	
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n^n\r9. \wBack");
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_CLASSESEDITOR,szMenuBody,-1,"C91011")	
}

public classeditor_menu_pushed(id, key)
{
	new totalclasses = (g_Prestige[id]+1)/2
	if (access(id, ADMIN_MEMBERSHIP)) totalclasses = 5
	switch(key)
	{
		case 0..5:
		{
			if (key<=totalclasses)
			{
				CMD_ClassEditor(id, (key+1))
			}
		}
		case 8:
		{
			CMD_ClassMenuCustom(id)
		}
		case 9: return PLUGIN_HANDLED
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public CMD_ClassEditor(id, class)
{
	g_EditingClass[id] = class

	new csw
	new wpnid[2]
	new wpnname[2][32], perkname[3][32], equname[32]
	
	wpnid[0] = g_CustomWeapon[PRIMARY][id][class]
	if (wpnid[PRIMARY])
	{
		if (wpnid[PRIMARY] == SHIELD)
		{
			wpnname[PRIMARY] = "Riot Shield"
		}
		else
		{
			csw = wpnid[PRIMARY]
			get_weaponname(csw,wpnname[PRIMARY],31)
			replace_all(wpnname[PRIMARY], 31, "weapon_", "")
			strtoupper(wpnname[PRIMARY])
		}
	}
	else
		wpnname[PRIMARY] = "None"

	wpnid[1] = g_CustomWeapon[SECONDARY][id][class]
	if (wpnid[SECONDARY])
	{
		if (wpnid[PRIMARY] == SHIELD)
		{
			wpnname[SECONDARY] = "-None Allowed-"
		}
		else
		{
			csw = wpnid[SECONDARY]
			get_weaponname(csw,wpnname[SECONDARY],31)
			replace_all(wpnname[SECONDARY] , 31, "weapon_", "")
			strtoupper(wpnname[SECONDARY])
		}
	}
	else
		wpnname[SECONDARY] = "None"
	
	perkname[0] = "ERROR"
	perkname[1] = "ERROR"
	perkname[2] = "ERROR"
	switch (g_CustomPerk[id][0][class])
	{
		case PRK1_MARAT: perkname[0] = "Flag Runner"
		case PRK1_SLIGH: perkname[0] = "Slight of Hand"
		case PRK1_SCAVE: perkname[0] = "Scavenger"
		case PRK1_BLING: perkname[0] = "Flak Jacket"
		case PRK1_ONEMA: perkname[0] = "One Man Army"
	}
	
	switch (g_CustomPerk[id][1][class])
	{
		case PRK2_STOPP: perkname[1] = "Stopping Power"
		case PRK2_LIGHT: perkname[1] = "Lightweight"
		case PRK2_HARDL: perkname[1] = "Hardline"
		case PRK2_COLDB: perkname[1] = "Cold-Blooded"
		case PRK2_DANGE: perkname[1] = "Danger Close"
	}
	
	switch (g_CustomPerk[id][2][class])
	{
		case PRK3_COMMA: perkname[2] = "Commando"
		case PRK3_STEAD: perkname[2] = "Steady Aim"
		case PRK3_SCRAM: perkname[2] = "Scrambler"
		case PRK3_NINJA: perkname[2] = "Ninja"
		case PRK3_LASTS: perkname[2] = "Last Stand"
	}
	
	if (wpnid[SECONDARY] == SHIELD)
	{
		equname = "-None Allowed-"
	}
	else
	{
		switch (g_CustomEquiptment[id][class])
		{
			case EQU_FRAG: equname = "Frag"
			case EQU_FLASH: equname = "Flash"
			case EQU_STUN: equname = "Stun"
			case EQU_SMTX: equname = "Semtex"
		}
	}
	
	new szMenuBody[2048];
	new nLen = format( szMenuBody, 2047, "\rCreate-A-Class:^n");
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\rWeapons:" );
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r    1. \wPrimary: \y%s", wpnname[PRIMARY] );
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r    2. \wSecondary: \y%s", wpnname[SECONDARY] );
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r    3. \wEquiptment: \y%s", equname );
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n^n\rPerks:" );
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r    4. \wPerk 1: \y%s", perkname[0]);
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r    5. \wPerk 2: \y%s", perkname[1]);
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r    6. \wPerk 3: \y%s", perkname[2]);
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n^n\r9. \wBack" );
	nLen += format( szMenuBody[nLen], 2047-nLen, "^n\r0. \wExit" );
	
	show_menu(id,KEYS_EDITOR,szMenuBody,-1,"D1213")	
}

public editor_menu_pushed(id,key)
{
	switch(key)
	{
		case 0:prim_weapons_menu(id)
		case 1:sec_weapons_menu(id)
		case 2:CMD_CoDEquipt(id)
		case 3:CMD_CoDPerks1(id)
		case 4:CMD_CoDPerks2(id)
		case 5:CMD_CoDPerks3(id)
		case 8:CMD_ClassMenuEditor(id)
		case 9: return PLUGIN_HANDLED
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED
}

public CMD_CoDPerks1(id)
{
	new szMenuBody[256];
			
	new nLen = format( szMenuBody, 255, "\rPerk 1:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wFlag Runner \y[Capture flags faster]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wSlight of Hand \y[Faster Reloading]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wScavenger \y[+Ammo]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wFlak Jacket \y[Extra Armor]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r5. \wOne Man Army \y[Change classes at any time]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_PERKS,szMenuBody,-1,"N0193")
}

public cod_perks1_pushed(id,key)
{
	switch(key)
	{
		case 0:
		{
			client_print(id, print_chat, "[MW2] Your first perk is now Flag Runner")
			g_CustomPerk[id][0][g_EditingClass[id]] = PRK1_MARAT
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 1:
		{
			client_print(id, print_chat, "[MW2] Your first perk is now Slight of Hand")
			g_CustomPerk[id][0][g_EditingClass[id]] = PRK1_SLIGH
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 2:
		{
			client_print(id, print_chat, "[MW2] Your first perk is now Scavenger")
			g_CustomPerk[id][0][g_EditingClass[id]] = PRK1_SCAVE
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 3:
		{
			client_print(id, print_chat, "[MW2] Your first perk is now Flak Jacket")
			g_CustomPerk[id][0][g_EditingClass[id]] = PRK1_BLING
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 4:
		{
			client_print(id, print_chat, "[MW2] Your first perk is now One Man Army")
			g_CustomPerk[id][0][g_EditingClass[id]] = PRK1_ONEMA
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 8:
		{
			CMD_ClassEditor(id, g_EditingClass[id])
			return PLUGIN_HANDLED
		}
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public CMD_CoDPerks2(id)
{
	new szMenuBody[256];
				
	new nLen = format( szMenuBody, 255, "\rPerk 2:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wStopping Power \y[+Damage]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wLightweight \y[Speed Boost]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wHardline \y[-1 Killstreaks]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wCold-Blooded \y[Invisible on RADAR]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r5. \wDanger Close \y[+Explosive Damage]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_PERKS,szMenuBody,-1,"O1024")
}

public cod_perks2_pushed(id,key)
{
	switch(key)
	{
		case 0:
		{
			client_print(id, print_chat, "[MW2] Your second perk is now Stopping Power")
			g_CustomPerk[id][1][g_EditingClass[id]] = PRK2_STOPP
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 1:
		{
			client_print(id, print_chat, "[MW2] Your second perk is now Lightweight")
			g_CustomPerk[id][1][g_EditingClass[id]] = PRK2_LIGHT
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 2:
		{
			client_print(id, print_chat, "[MW2] Your second perk is now Hardline")
			g_CustomPerk[id][1][g_EditingClass[id]] = PRK2_HARDL
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 3:
		{
			client_print(id, print_chat, "[MW2] Your second perk is now Cold-Blooded")
			g_CustomPerk[id][1][g_EditingClass[id]] = PRK2_COLDB
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 4:
		{
			client_print(id, print_chat, "[MW2] Your second perk is now Danger Close")
			g_CustomPerk[id][1][g_EditingClass[id]] = PRK2_DANGE
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 8:
		{
			CMD_ClassEditor(id, g_EditingClass[id])
			return PLUGIN_HANDLED
		}
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public CMD_CoDPerks3(id)
{
	new szMenuBody[256];
				
	new nLen = format( szMenuBody, 255, "\rPerk 3:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wCommando \y[+Melee Distance and No Fall Dmg]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wSteady Aim \y[-Recoil]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wScrambler \y[Bullet Evasion]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wNinja \y[Silent Footsteps + Invisibility]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r5. \wLast Stand \y[Pull out pistol before dieing]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_PERKS,szMenuBody,-1,"P2759")
}

public cod_perks3_pushed(id,key)
{
	switch(key)
	{
		case 0:
		{
			client_print(id, print_chat, "[MW2] Your third perk is now Commando")
			g_CustomPerk[id][2][g_EditingClass[id]] = PRK3_COMMA
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 1:
		{
			client_print(id, print_chat, "[MW2] Your third perk is now Steady Aim")
			g_CustomPerk[id][2][g_EditingClass[id]] = PRK3_STEAD
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 2:
		{
			client_print(id, print_chat, "[MW2] Your third perk is now Scrambler")
			g_CustomPerk[id][2][g_EditingClass[id]] = PRK3_SCRAM
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 3:
		{
			client_print(id, print_chat, "[MW2] Your third perk is now Ninja")
			g_CustomPerk[id][2][g_EditingClass[id]] = PRK3_NINJA
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 4:
		{
			client_print(id, print_chat, "[MW2] Your third perk is now Last Stand")
			g_CustomPerk[id][2][g_EditingClass[id]] = PRK3_LASTS
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 8:
		{
			CMD_ClassEditor(id, g_EditingClass[id])
			return PLUGIN_HANDLED
		}
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public CMD_CoDEquipt(id)
{
	new szMenuBody[256];
				
	new nLen = format( szMenuBody, 255, "\rEquiptment:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wFrag Grenade");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wFlashbang Grenade");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wStun Grenade");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wSemtex Grenade");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_EQUIPTMENT,szMenuBody,-1,"Q8572")
}

public cod_equipt_pushed(id,key)
{
	switch(key)
	{
		case 0:
		{
			g_CustomEquiptment[id][g_EditingClass[id]] = EQU_FRAG
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 1:
		{
			g_CustomEquiptment[id][g_EditingClass[id]] = EQU_FLASH
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 2:
		{
			g_CustomEquiptment[id][g_EditingClass[id]] = EQU_STUN
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 3:
		{
			g_CustomEquiptment[id][g_EditingClass[id]] = EQU_SMTX
			CMD_ClassEditor(id, g_EditingClass[id])
		}
		case 8:
		{
			CMD_ClassEditor(id, g_EditingClass[id])
			return PLUGIN_HANDLED
		}
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public prim_weapons_menu(id)
{
	new szMenuBody[256];
				
	new nLen = format( szMenuBody, 255, "\rPrimary Weapons:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wAssault Rifles" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wSMGs" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wShotguns" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wSniper Rifles" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r5. \wMachine Guns" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r6. \wRiot Shield" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_GUNMAIN,szMenuBody,-1,"G1029")
}

public prim_weapons_pushed(id,key)
{
	switch(key)
	{
		case 0: prim_ass_menu(id)
		case 1: prim_smg_menu(id)
		case 2: prim_sho_menu(id)
		case 3: prim_sni_menu(id)
		case 4: prim_mac_menu(id)
		case 5:
		{
			g_CustomWeapon[0][id][g_EditingClass[id]] = SHIELD
			g_CustomWeapon[1][id][g_EditingClass[id]] = 0
			CMD_ClassEditor(id, g_EditingClass[id])
			SaveLevel(id)
		}
		case 8: CMD_ClassEditor(id, g_EditingClass[id])
		case 9: return PLUGIN_HANDLED
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public prim_ass_menu(id)
{
	new szMenuBody[256];
				
	new nLen = format( szMenuBody, 255, "\rAssault Rifles:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wSG-552 Commando" );
	if (g_PlayerRank[id] > 13)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wIMI Galil" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wIMI Galil [\rRank 15\w]");
	if (g_PlayerRank[id] > 25)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wSteyr AUG A1" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wSteyr AUG A1 [\rRank 27\w]");
	if (g_PlayerRank[id] > 36)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wM4A1 Carbine" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wM4A1 Carbine [\rRank 38\w]");
	if (g_PlayerRank[id] > 48)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r5. \wFamas" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r5. \wFamas [\rRank 50\w]");
	if (g_PlayerRank[id] > 59)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r6. \wAK-47 Kalashnikov" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r6. \wAK-47 Kalashnikov [\rRank 61\w]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_GUNASS,szMenuBody,-1,"H3082")
}

public prim_ass_pushed(id,key)
{
	switch(key)
	{
		case 0:
		{
			g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_SG552
			CMD_ClassEditor(id, g_EditingClass[id])
			SaveLevel(id)
		}
		case 1: 
		{
			if (g_PlayerRank[id] > 13)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_GALIL
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_ass_menu(id)
		}
		case 2:
		{
			if (g_PlayerRank[id] > 25)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_AUG
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_ass_menu(id)
		}
		case 3:
		{
			if (g_PlayerRank[id] > 36)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_M4A1
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_ass_menu(id)
		}
		case 4:
		{
			if (g_PlayerRank[id] > 48)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_FAMAS
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_ass_menu(id)
		}
		case 5:
		{
			if (g_PlayerRank[id] > 59)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_AK47
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_ass_menu(id)
		}
		case 8: prim_weapons_menu(id)
		case 9: return PLUGIN_HANDLED
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public prim_smg_menu(id)
{
	new szMenuBody[256];
				
	new nLen = format( szMenuBody, 255, "\rSMGs:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wIngram MAC-10" );
	if (g_PlayerRank[id] > 8)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wSchmidt TMP" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wSchmidt TMP [\rRank 10\w]");
	if (g_PlayerRank[id] > 20)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wMP5 Navy" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wMP5 Navy [\rRank 22\w]");
	if (g_PlayerRank[id] > 30)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wUMP 45" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wUMP 45 [\rRank 32\w]");
	if (g_PlayerRank[id] > 53)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r5. \wES P90" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r5. \wES P90 [\rRank 55\w]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_GUNSMG,szMenuBody,-1,"I0392")
}

public prim_smg_pushed(id,key)
{
	switch(key)
	{
		case 0:
		{
			g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_MAC10
			CMD_ClassEditor(id, g_EditingClass[id])
			SaveLevel(id)
		}
		case 1:
		{
			if (g_PlayerRank[id] > 8)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_TMP
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_smg_menu(id)
		}
		case 2:
		{
			if (g_PlayerRank[id] > 20)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_MP5NAVY
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_smg_menu(id)
		}
		case 3: 
		{
			if (g_PlayerRank[id] > 30)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_UMP45
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_smg_menu(id)
		}
		case 4: 
		{
			if (g_PlayerRank[id] > 53)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_P90
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_smg_menu(id)
		}
		case 8:prim_weapons_menu(id)
		case 9: return PLUGIN_HANDLED
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public prim_sho_menu(id)
{
	new szMenuBody[256];
				
	new nLen = format( szMenuBody, 255, "\rShotguns:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wM3 Super 90" );
	if (g_PlayerRank[id] > 18)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wXM1014 M4" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wXM1014 M4 [\rRank 20\w]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_GUNSHO,szMenuBody,-1,"J2058")
}

public prim_sho_pushed(id,key)
{
	switch(key)
	{
		case 0: 
		{
			g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_M3
			CMD_ClassEditor(id, g_EditingClass[id])
			SaveLevel(id)
		}
		case 1: 
		{
			if (g_PlayerRank[id] > 18)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_XM1014
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_sho_menu(id)
		}
		case 8: prim_weapons_menu(id)
		case 9: return PLUGIN_HANDLED
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public prim_sni_menu(id)
{
	new szMenuBody[256];
				
	new nLen = format( szMenuBody, 255, "\rSniper Rifles:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wSchmidt Scout" );
	if (g_PlayerRank[id] > 58)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wAWP Magnum Sniper" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wAWP Magnum Sniper [\rRank 60\w]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_GUNSNI,szMenuBody,-1,"K3018")
}

public prim_sni_pushed(id,key)
{
	switch(key)
	{
		case 0: 
		{
			g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_SCOUT
			CMD_ClassEditor(id, g_EditingClass[id])
			SaveLevel(id)
		}
		case 1: 
		{
			if (g_PlayerRank[id] > 58)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_AWP
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_sni_menu(id)
		}
		case 8: prim_weapons_menu(id)
		case 9: return PLUGIN_HANDLED
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public prim_mac_menu(id)
{
	new szMenuBody[256];
				
	new nLen = format( szMenuBody, 255, "\rMachine Guns:^n" );
	if (g_PlayerRank[id] > 15)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wM249-SAW" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wM249-SAW [\rRank 17\w]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_GUNMAC,szMenuBody,-1,"L0281")
}

public prim_mac_pushed(id,key)
{
	switch(key)
	{
		case 0:
		{
			if (g_PlayerRank[id] > 15)
			{
				g_CustomWeapon[0][id][g_EditingClass[id]] = CSW_M249
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				prim_mac_menu(id)
		}
		case 8: prim_weapons_menu(id)
		case 9: return PLUGIN_HANDLED
	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public sec_weapons_menu(id)
{
	new szMenuBody[256];
				
	new nLen = format( szMenuBody, 255, "\rSecondary Weapons:^n" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r1. \wGlock 18C" );
	if (g_PlayerRank[id] > 5)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wUSP .45 ACP Tactical" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r2. \wUSP .45 ACP Tactical [\rRank 7\w]");
	if (g_PlayerRank[id] > 11)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wP228 Compact" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r3. \wP228 Compact [\rRank 13\w]");
	if (g_PlayerRank[id] > 23)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wFiveseven" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r4. \wFiveseven [\rRank 25\w]");
	if (g_PlayerRank[id] > 29)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r5. \wDual Berettas" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r5. \wDual Berettas [\rRank 31\w]");
	if (g_PlayerRank[id] > 41)
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r6. \wDesert Eagle .50 AE" );
	else
		nLen += format( szMenuBody[nLen], 255-nLen, "^n\r6. \wDesert Eagle .50 AE [\rRank 43\w]");
	nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\r9. \wBack" );
	nLen += format( szMenuBody[nLen], 255-nLen, "^n\r0. \wExit" );
		
	show_menu(id,KEYS_GUNSEC,szMenuBody,-1,"M1028")
}

public sec_weapons_pushed(id,key)
{
	switch(key)
	{
		case 0:
		{
			g_CustomWeapon[1][id][g_EditingClass[id]] = CSW_GLOCK18
			CMD_ClassEditor(id, g_EditingClass[id])
			SaveLevel(id)
		}
		case 1: 
		{
			if (g_PlayerRank[id] > 5)
			{
				g_CustomWeapon[1][id][g_EditingClass[id]] = CSW_USP
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				sec_weapons_menu(id)
		}
		case 2:
		{
			if (g_PlayerRank[id] > 11)
			{
				g_CustomWeapon[1][id][g_EditingClass[id]] = CSW_P228
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				sec_weapons_menu(id)
		}
		case 3:
		{
			if (g_PlayerRank[id] > 11)
			{
				g_CustomWeapon[1][id][g_EditingClass[id]] = CSW_FIVESEVEN
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				sec_weapons_menu(id)
		}
		case 4:
		{
			if (g_PlayerRank[id] > 29)
			{
				g_CustomWeapon[1][id][g_EditingClass[id]] = CSW_ELITE
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				sec_weapons_menu(id)
		}
		case 5:
		{
			if (g_PlayerRank[id] > 41)
			{
				g_CustomWeapon[1][id][g_EditingClass[id]] = CSW_DEAGLE
				CMD_ClassEditor(id, g_EditingClass[id])
				SaveLevel(id)
			}
			else
				sec_weapons_menu(id)
		}
		case 8: CMD_ClassEditor(id, g_EditingClass[id])
		case 9: return PLUGIN_HANDLED

	}
	client_cmd(id, "spk %s", gItemSelected);
	return PLUGIN_HANDLED;
}

public give_weapons(id)
{
	if (!g_isalive[id]) return;
	
	switch(g_PlayerClass[id])
	{
		case GRENADIER:
		{
			strip_user_weapons(id);
			give_item(id, "weapon_knife");

			give_item(id, "weapon_aug");
			cs_set_user_bpammo(id,CSW_AUG,90)
			
			give_item(id, "weapon_fiveseven");
			cs_set_user_bpammo(id,CSW_FIVESEVEN,20)
			g_CurrentSecondary[id] = CSW_FIVESEVEN
			
			g_Equiptment[id] = EQU_SMTX
			give_item(id, "weapon_hegrenade");
			
			g_Perk[id][0] = PRK1_SCAVE
			g_Perk[id][1] = PRK2_STOPP
			g_Perk[id][2] = PRK3_COMMA
		}
		case RECON:
		{
			strip_user_weapons(id);
			give_item(id, "weapon_knife");
			
			give_item(id, "weapon_ump45");
			cs_set_user_bpammo(id,CSW_UMP45,50)
			
			give_item(id, "weapon_deagle");
			cs_set_user_bpammo(id,CSW_DEAGLE,14)
			g_CurrentSecondary[id] = CSW_DEAGLE
			
			g_Equiptment[id] = EQU_STUN
			give_item(id, "weapon_flashbang");
			
			g_Perk[id][0] = PRK1_MARAT
			g_Perk[id][1] = PRK2_LIGHT
			g_Perk[id][2] = PRK3_NINJA
		}
		case OVERWATCH:
		{
			strip_user_weapons(id);
			give_item(id, "weapon_knife");
			
			give_item(id, "weapon_m3");
			cs_set_user_bpammo(id,CSW_M3,24)
			
			give_item(id, "weapon_deagle");
			cs_set_user_bpammo(id,CSW_DEAGLE,14)
			g_CurrentSecondary[id] = CSW_DEAGLE
			
			g_Equiptment[id] = EQU_FRAG
			give_item(id, "weapon_hegrenade");
			
			g_Perk[id][0] = PRK1_SLIGH
			g_Perk[id][1] = PRK2_DANGE
			g_Perk[id][2] = PRK3_SCRAM
		}
		case SNIPER:
		{
			strip_user_weapons(id);
			give_item(id, "weapon_knife");
			give_item(id, "weapon_scout");
			cs_set_user_bpammo(id,CSW_SCOUT,20)
			
			give_item(id, "weapon_usp");
			cs_set_user_bpammo(id,CSW_USP,24)
			g_CurrentSecondary[id] = CSW_USP

			g_Equiptment[id] = EQU_FRAG
			give_item(id, "weapon_hegrenade");
			
			g_Perk[id][0] = PRK1_BLING
			g_Perk[id][1] = PRK2_COLDB
			g_Perk[id][2] = PRK3_SCRAM
		}
		case RIOT:
		{
			g_HasShield[id] = true
			g_Shielded[id] = false
			strip_user_weapons(id);
			give_item(id, "weapon_knife");
			g_CurrentSecondary[id] = CSW_KNIFE
			
			give_item(id, "weapon_shield");
			
			entity_set_string( id , EV_SZ_viewmodel , gShieldModel[0] )  
			entity_set_string( id , EV_SZ_weaponmodel , gShieldModel[1] )  
			
			g_Perk[id][0] = PRK1_MARAT
			g_Perk[id][1] = PRK2_HARDL
			g_Perk[id][2] = PRK3_COMMA
		}
		case CUSTOM1..CUSTOM6:
		{
			new ClassNumber = g_PlayerClass[id]
		
			if (g_CustomWeapon[PRIMARY][id][ClassNumber] == SHIELD)
			{
				give_item(id, "weapon_shield");
				g_CurrentSecondary[id] = CSW_KNIFE
				g_HasShield[id] = true
				g_Shielded[id] = false
				
				entity_set_string( id , EV_SZ_viewmodel , gShieldModel[0] )  
				entity_set_string( id , EV_SZ_weaponmodel , gShieldModel[1] )  
			}
			else
			{
				new weapon[32], csw
				
				csw = g_CustomWeapon[PRIMARY][id][ClassNumber]
				if (csw != 0)
				{
					get_weaponname(csw,weapon,31)
					give_item(id,weapon)
					cs_set_user_bpammo(id,csw,60)
				}
		
				csw = g_CustomWeapon[SECONDARY][id][ClassNumber]
				if (csw != 0)
				{
					get_weaponname(csw,weapon,31)
					give_item(id,weapon)
					cs_set_user_bpammo(id,csw,40)
					g_CurrentSecondary[id] = csw
				}
		
				switch (g_CustomEquiptment[id][ClassNumber])
				{
					case EQU_FRAG: give_item(id,"weapon_hegrenade");
					case EQU_FLASH: give_item(id,"weapon_flashbang"), cs_set_user_bpammo(id,CSW_FLASHBANG,2);
					case EQU_STUN: give_item(id,"weapon_flashbang"), cs_set_user_bpammo(id,CSW_FLASHBANG,2);
					case EQU_SMTX: give_item(id,"weapon_hegrenade");
				}
			}
			g_Perk[id][0] = g_CustomPerk[id][0][ClassNumber]
			g_Perk[id][1] = g_CustomPerk[id][1][ClassNumber]
			g_Perk[id][2] = g_CustomPerk[id][2][ClassNumber]
			g_Equiptment[id] = g_CustomEquiptment[id][ClassNumber]	
		}
	}
	
	if (g_Perk[id][0] == PRK1_MARAT)
	{
		callfunc_begin("flag_runner",DominationVersion)
		callfunc_push_int(id)
		callfunc_push_float(0.5)
		callfunc_end()
	}
	else
	{
		callfunc_begin("flag_runner",DominationVersion)
		callfunc_push_int(id)
		callfunc_push_float(1.0)
		callfunc_end()
	}
	
	if (g_Perk[id][1] == PRK2_HARDL)
		g_Kills[id] = 1
		
	if (g_Perk[id][2] == PRK3_NINJA)
		set_user_footsteps(id, 1)
	else
		set_user_footsteps(id, 0)
}
/*-----------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------*/

public plugin_cfg()
{
	g_Vault = nvault_open( "mw2_data" );
	
	if ( g_Vault == INVALID_HANDLE )
		set_fail_state( "Error opening Modern Warfare 2 nVault, file does not exist!" );
}

public fw_GetGameDescription()
{
	forward_return(FMV_STRING, g_ModName)
	return FMRES_SUPERCEDE;
}

public event_round_start()
{
	g_Starting = true
	g_RoundOwner = false
	g_CanNuke = true
	
	arrayset(g_Kills, 0, 33)
	arrayset(g_AssistKiller[CURRENT_ASSIST], 0, 33)
	arrayset(g_AssistKiller[PREVIOUS_ASSIST], 0, 33)
	arrayset(g_LastKiller, 0, 33)
	arrayset(g_ComebackCounter, 0, 33)
	arrayset(g_Score, 0, 2)
	arrayset(g_WasntBefore, 0, 2)
	g_FirstKill = false
	g_HasSaid = false
	
	g_RoundStartTime = get_gametime()
}

public logevent_round_start()
{
	g_Starting = false
	
	client_cmd(0, "mp3 stop");
	switch(g_RandMode)
	{
		case TDM:
		{
			update_tdm_hud()
			set_hudmessage(255, 255, 0, -1.0, 0.45, 2, 3.0, 5.0, 0.1, 0.2, 1)
			show_hudmessage(0, "Team Deathmatch^n^nEliminate the enemy players!");
		}
		case DOMINATION:
		{
			set_hudmessage(255, 255, 0, -1.0, 0.45, 2, 3.0, 5.0, 0.1, 0.2, 1)
			show_hudmessage(0, "Domination^n^nCapture the flags and defend them!");
		}
	}
	client_cmd(0, "spk %s", gModeSound[g_RandMode]);	
}

public logevent_round_end()
{
	new players[32], num;
	get_players(players, num, "ach");
	for ( new i = 0; i < num; i++)
	{
		check_challenges(players[i])
	}
	client_print(0, print_chat, "[MW2] Checking for earned challanges now...");
	
	//server_cmd("mp_freezetime 4")
}

public client_connect(id)
{
	g_isalive[id] = false
	g_isconnected[id] = true
	g_canprestige[id] = false
	g_PlayerClass[id] = NONE
	g_ShouldCheck[id] = false
	g_AssistKiller[PREVIOUS_ASSIST][id] = 0
	g_AssistKiller[CURRENT_ASSIST][id] = 0
	g_LastKiller[id] = 0
	g_ComebackCounter[id] = 0
	g_CurrentWeapon[id] = 0
	g_HasShield[id] = false
	g_Shielded[id] = false
	g_FakeDelay[id] = false
	g_Stuck[id] = false
	normalTrace[id] = 0
	g_isfalling[id] = false
	g_islaststand[id] = false
	g_Kills[id] = 0
	g_isflashed[id] = false
	g_FirstSpawn[id] = true
	g_hasloaded[id] = false
	
	g_ispredator[id] = false
	g_UserRocket[id][rocket_entity] = -1
	g_UserRocket[id][rocket_nreact] = 0
	
	/*for ( new i=1; i<7; i++)
	{
		g_CustomWeapon[PRIMARY][id][i] = CSW_SG552
		g_CustomWeapon[SECONDARY][id][i] = CSW_P228
	}*/
	
	for (new i=0; i<TOT_KILLSTREAKS; i++)
		g_HasKillstreak[id][i] = false
	
	/*for ( new i=1; i<31; i++)
	{
		g_GunStats[id][GUN_KILLS][i] = 0
		g_GunStats[id][GUN_HEADSHOTS][i] = 0
	}*/

	/*for ( new i=1; i<7; i++)
	{
		g_CustomPerk[id][0][i] = 0
		g_CustomPerk[id][1][i] = 0
		g_CustomPerk[id][2][i] = 0
		g_CustomEquiptment[id][i] = 0
		g_CustomWeapon[PRIMARY][id][i] = 0
		g_CustomWeapon[SECONDARY][id][i] = 0
	}*/
	
	/*for ( new i=0; i<4; i++)
	{
		g_ChallangeCounter[i][id] = 0
	}*/
	
	if (!is_user_bot(id))
		get_load_key(id)
}

public client_disconnect(id)
{
	SaveLevel(id)
	
	g_isalive[id] = false
	g_isconnected[id] = false
	g_canprestige[id] = false
	g_PlayerClass[id] = NONE
	g_ShouldCheck[id] = false
	g_AssistKiller[PREVIOUS_ASSIST][id] = 0
	g_AssistKiller[CURRENT_ASSIST][id] = 0
	g_LastKiller[id] = 0
	g_ComebackCounter[id] = 0
	g_CurrentWeapon[id] = 0
	g_HasShield[id] = false
	g_Shielded[id] = false
	g_FakeDelay[id] = false
	g_Stuck[id] = false
	normalTrace[id] = 0
	g_isfalling[id] = false
	g_islaststand[id] = false
	g_Kills[id] = 0
	g_isflashed[id] = false
	g_FirstSpawn[id] = false
	g_hasloaded[id] = true
	
	g_ispredator[id] = false
	g_UserRocket[id][rocket_entity] = -1
	g_UserRocket[id][rocket_nreact] = 0
	
	for (new i=0; i<TOT_KILLSTREAKS; i++)
		g_HasKillstreak[id][i] = false
	
	remove_task(id+LEVEL_TASK );
	remove_task(id+MODELSET_TASK);
	remove_task(id+FAKEDELAY_TASK);
	remove_task(id+OMA_TASK);
	remove_task(id+CHARGE_TASK);
	remove_task(id+LASTSTAND_TASK);
	remove_task(id+AIRSTRIKE_TASK);
	remove_task(id+FLASHBANG_TASK);
	remove_task(id+EMPEFFECTS_TASK);
	remove_task(id+NUKE_TASK);
	remove_task(id+XPLOAD_TASK);
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	g_isalive[victim] = false
	
	remove_task(victim+OMA_TASK);
	remove_task(victim+CHARGE_TASK);
	remove_task(victim+LASTSTAND_TASK);
	remove_task(victim+FLASHBANG_TASK);
	
	g_HasShield[victim] = false
	g_Shielded[victim] = false
	g_FakeDelay[victim] = false
	g_Stuck[victim] = false
	g_isflashed[victim] = false
		
	if((victim != killer) && (get_user_team(killer) != get_user_team(victim)))
	{
		g_Kills[killer]++;	

		switch(g_Kills[killer])
		{
			case KILLS_UAV: cmdGiveKillstreak(killer, KS_UAV)
			case KILLS_COU: cmdGiveKillstreak(killer, KS_COU)
			case KILLS_AIR: cmdGiveKillstreak(killer, KS_AIR)
			case KILLS_PRED: cmdGiveKillstreak(killer, KS_PRED)
			case KILLS_EMP: cmdGiveKillstreak(killer, KS_EMP)
			case KILLS_NUKE: cmdGiveKillstreak(killer, KS_NUKE)
		}

		if (g_RandMode == TDM && g_Score[TERROR] < g_WinNumber && g_Score[COUNTER] < g_WinNumber)
		{
			switch (cs_get_user_team(killer))
			{
				case CS_TEAM_T:g_Score[TERROR] += 100
				case CS_TEAM_CT:g_Score[COUNTER] += 100
			}
			update_tdm_hud()
		}
	}
	
	g_GunStats[killer][GUN_KILLS][wpnindex]+=2
	if ( hitplace == HIT_HEAD) g_GunStats[killer][GUN_HEADSHOTS][wpnindex]+=2
	
	new killpts = 50;
	//if (g_DoubleXP) killpts *= 2
	new killbonus = 0
	
	//if ( get_distance(killer, victim) > 2500 ) killpts +=50 longshot
	
	if (victim != killer)
	{
		new szKillBonuses[64]
		new nLen
	
		if (!g_FirstKill)
		{
			g_FirstKill = true
			nLen += format( szKillBonuses[nLen], 63-nLen, "First Blood!^n" );
			killpts += 100
			killbonus = 1
		}
		if ( hitplace == 1 )
		{
			nLen += format( szKillBonuses[nLen], 63-nLen, "Headshot^n" );
			killpts += 50
			killbonus = 1
		}
		if ( g_LastKiller[killer] == victim )
		{
			g_LastKiller[killer] = 0
			nLen += format( szKillBonuses[nLen], 63-nLen, "Payback!^n" );
			killpts += 50
			killbonus = 1
			client_cmd(victim, "spk %s", gPayback);
		}
		if (g_Kills[victim]+1 == KILLS_UAV || g_Kills[victim]+1 == KILLS_COU || g_Kills[victim]+1 == KILLS_AIR || g_Kills[victim]+1 == KILLS_EMP || g_Kills[victim]+1 == KILLS_NUKE)
		{
			nLen += format( szKillBonuses[nLen], 63-nLen, "Buzzkill!^n" );
			killpts += 50
			killbonus = 1
		}
		if ( wpnindex == CSW_KNIFE )
		{
			nLen += format( szKillBonuses[nLen], 63-nLen, "Assassination!^n" );
			killpts += 200
			killbonus = 1
		}
		if ( g_ComebackCounter[killer] > 2 )
		{
			if (g_ComebackCounter[killer] > 2)
			{
				nLen += format( szKillBonuses[nLen], 63-nLen, "Comeback!^n" );
				killpts += 50
				killbonus = 1
				
				if (g_ComebackCounter[killer] > 4) killpts += 50
				if (g_ComebackCounter[killer] > 6) killpts += 50
				
				g_ComebackCounter[killer] = 0
			}
		}
		if ( g_AssistKiller[PREVIOUS_ASSIST][victim] && g_AssistKiller[PREVIOUS_ASSIST][victim] != killer )
		{
			new killpts2 = 20
			if (g_DoubleXP) killpts2 *= 4
			g_Experience[g_AssistKiller[PREVIOUS_ASSIST][victim]] += killpts2;
			set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2)
			show_hudmessage(g_AssistKiller[PREVIOUS_ASSIST][victim], "Assist!^n+%dXP", killpts2);
			client_cmd(g_AssistKiller[PREVIOUS_ASSIST][victim], "spk %s", gKillBonus);
		}
		
		//Final Modifiers
		if (g_DoubleXP) killpts *= 4
		g_Experience[killer] += killpts;
		
		nLen += format( szKillBonuses[nLen], 63-nLen, "+%dXP", killpts);
		if(killbonus == 1) client_cmd(killer, "spk %s", gKillBonus);
	
		set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2)
		show_hudmessage(killer, szKillBonuses);
		
		switch (random_num(1, 2))
		{
			case 1:
			{
				client_cmd(killer, "spk %s",  gTangoDown[random(sizeof (gTangoDown)-1)]);
			}
		}
		
		//Set last to not fuck up the checks
		g_Kills[victim] = 0;
		g_AssistKiller[0][victim] = 0
		g_AssistKiller[1][victim] = 0
		g_LastKiller[victim] = killer
		g_ComebackCounter[victim] += 1
		
		
		check_challenges(killer);
		DisplayHUD(killer);
	}
}

bool:is_ranked_higher(rank1, rank2)
{
	return (rank1 > rank2) ? true : false;
}

public check_level(id)
{
	if (id > g_MaxPlayers)
		id-=LEVEL_TASK
		
	new prevrank;
	
	prevrank = g_PlayerRank[id];
	new newrank, counter;
	
	for (counter = 0; counter < MAX_RANKS; counter++)
	{
		if ( g_Experience[id] >= gRankXP[counter] )
		{
			newrank = counter;
		}
		else break;
	}
	
	g_PlayerRank[id] = newrank;
	
	if ( is_ranked_higher(newrank, prevrank) )
	{
		new idname[35]
		get_user_name(id,idname,34)
		client_print(0, print_chat, "%s has ranked up and is now a %s", idname, gRankName[newrank]);
		set_hudmessage(255, 255, 255, -1.0, 0.30, 2, 5.0, 4.0, 0.02, 0.02, 4)
		show_hudmessage(id, "You've been promoted!^n%s", gRankName[newrank]);
		client_cmd(id, "spk %s", gSoundRank);
		SaveLevel(id)
		if ( g_PlayerRank[ id] == 4 )
			client_print(id, print_chat, "[MW2] You've unlocked your custom class, type /class to create it!");
		else if ( ( g_PlayerRank[ id ] == ( MAX_RANKS-1 ) ) && ( g_Prestige[ id ] < 10 ) )
		{
			g_canprestige[id] = true
			client_print(id, print_chat, "[MW2] Prestige mode has now been unlocked!");
		}
		else if ( ( g_PlayerRank[ id ] == ( MAX_RANKS-1 ) ) && ( g_Prestige[ id ] == 10 ) )
		{
			client_print(id, print_chat, "[MW2] Congratulations! You are 10th Prestige Rank 70!");
		}
	}
	else if ( newrank != prevrank && !is_ranked_higher(newrank, prevrank) )
	{
		client_print(id, print_chat, "[MW2] You have been demoted to the rank of %s", gRankName[newrank]);
	}
	DisplayHUD(id)
	
	return PLUGIN_CONTINUE
}

public check_level_silent(id)
{
	if (id > g_MaxPlayers)
		id-=LEVEL_TASK
		
	new newrank, counter;
	
	for (counter = 0; counter < MAX_RANKS; counter++)
	{
		if ( g_Experience[id] >= gRankXP[counter] )
		{
			newrank = counter;
		}
		else
			break;
	}
	
	g_PlayerRank[id] = newrank;
	
	if (g_Experience[id] >= gRankXP[69])
		g_canprestige[id] = true
	
	return PLUGIN_CONTINUE	
}

public check_challenges(id)
{
	new bool:badgegained=false;
	
	set_hudmessage(255, 255, 255, -1.0, 0.30, 2, 3.0, 4.0, 0.02, 0.02, 4)
	
	new CurGunLevel, check_pistol, i = g_CurrentWeapon[id]
	//for( new i=0;i<31;i++ )
	{
		check_pistol = (i == CSW_GLOCK18 || i == CSW_USP || i == CSW_P228 || i == CSW_DEAGLE || i == CSW_FIVESEVEN || i == CSW_ELITE) ? SECONDARY : PRIMARY
		CurGunLevel = g_PlayerChallenges[id][MARKSMAN][i]
		if (CurGunLevel < 8 && g_GunStats[id][GUN_KILLS][i] > gChalLvls[check_pistol][CurGunLevel])
		{
			g_PlayerChallenges[id][MARKSMAN][i]++
			show_hudmessage(id, "%s^nGet %d kills with a %s^n+%dXP", g_ChallengeName[i][CurGunLevel], gChalLvls[check_pistol][CurGunLevel]+1, gGunName[i], gChalXP[CurGunLevel]);
			client_print(id, print_chat, "[MW2] You have completed the %s (%d Kills, +%dXP) challange",  g_ChallengeName[i][CurGunLevel],  gChalLvls[check_pistol][CurGunLevel]+1, gChalXP[CurGunLevel])
			g_Experience[id]+=gChalXP[CurGunLevel]
			badgegained=true;
		}
		CurGunLevel = g_PlayerChallenges[id][ELITE][i]
		if (CurGunLevel < 8 && i != CSW_KNIFE && i != CSW_HEGRENADE && g_GunStats[id][GUN_HEADSHOTS][i] > gChalHS[check_pistol][CurGunLevel])
		{ 
			g_PlayerChallenges[id][ELITE][i]++
			show_hudmessage(id, "%s^nGet %d headshots with a %s^n+%dXP", g_ChallengeName[i+31][CurGunLevel], gChalHS[check_pistol][CurGunLevel]+1, gGunName[i], gChalXP[CurGunLevel]);
			client_print(id, print_chat, "[MW2] You have completed the %s (%d HS, +%dXP) challange",  g_ChallengeName[i+31][CurGunLevel],  gChalHS[check_pistol][CurGunLevel]+1, gChalXP[CurGunLevel])
			g_Experience[id]+=gChalXP[CurGunLevel]
			badgegained=true;
		}
	}

	if (badgegained)
	{
		if (i == CSW_SG552 || i==CSW_AUG || i==CSW_FAMAS || i==CSW_GALIL || i== CSW_AK47 || i==CSW_M4A1 )
			g_ChallangeCounter[ASSAULT][id]++
		else if (i == CSW_MAC10 || i==CSW_TMP || i==CSW_MP5NAVY || i==CSW_UMP45 || i== CSW_P90 )
			g_ChallangeCounter[SMG][id]++
		else if (i == CSW_AWP || i==CSW_SCOUT || i==CSW_M249 || i==CSW_XM1014 || i== CSW_M3 )
			g_ChallangeCounter[OTHER][id]++
		else if (check_pistol)
			g_ChallangeCounter[PISTOL][id]++
					
		client_cmd(id, "spk %s", gSoundBadge);
		SaveLevel(id);
		set_task(5.0, "check_level", id+LEVEL_TASK)
	}
	else
		check_level(id);

	return PLUGIN_HANDLED
}

public check_challenges_silent(id)
{
	new chal_level, elite_level, counter, counter2, check_pistol
	
	for( new i=0;i<31;i++ )
	{
		check_pistol = (i == CSW_GLOCK18 || i == CSW_USP || i == CSW_P228 || i == CSW_DEAGLE || i == CSW_FIVESEVEN || i == CSW_ELITE) ? SECONDARY : PRIMARY
		//Checks all marksman challenges
		for (counter = 0; counter < MAXLVL_CHAL-1; counter++)
		{
			if ( g_GunStats[id][GUN_KILLS][i] > gChalLvls[check_pistol][counter] )
				chal_level = counter;
			else
				break;
		}
		
		g_PlayerChallenges[id][MARKSMAN][i] = chal_level;
	}
	
	for( new i=0;i<31;i++ )
	{
		check_pistol = (i == CSW_GLOCK18 || i == CSW_USP || i == CSW_P228 || i == CSW_DEAGLE || i == CSW_FIVESEVEN || i == CSW_ELITE) ? SECONDARY : PRIMARY
		//Checks all elite challenges
		for (counter2 = 0; counter2 < MAXLVL_CHAL-1; counter2++)
		{
			if ( g_GunStats[id][GUN_HEADSHOTS][i] > gChalHS[check_pistol][counter2] )
				elite_level = counter2
			else
				break;
		}
		
		g_PlayerChallenges[id][ELITE][i] = elite_level;
	}
	SaveLevel(id);
			
	return PLUGIN_HANDLED
}

public check_killstreaks(id, killstreak, mode)
{
	new bool:badgegained=false;
	
	set_hudmessage(255, 255, 255, -1.0, 0.30, 2, 3.0, 4.0, 0.02, 0.02, 4)
	
	new CurChalLevel
	if (mode == 0)
	{
		CurChalLevel = g_KillstreakChal[id][killstreak]
		if (CurChalLevel < 8)
		{
			if ( g_NumKillstreaks[id][killstreak] > gKSChalNum[CurChalLevel] )
			{
				g_KillstreakChal[id][killstreak]++
				show_hudmessage(id, "%s^nCall in %d %s's^n+%dXP", g_ChalNameKillstreaks[killstreak][CurChalLevel], gKSChalNum[CurChalLevel]+1, g_KillstreakName[killstreak], gKSChalXP[CurChalLevel]);
				client_print(id, print_chat, "[MW2] You have completed the %s (Call in %d %s's, +%dXP) challange",  g_ChalNameKillstreaks[killstreak][CurChalLevel],  gKSChalNum[CurChalLevel]+1, g_KillstreakName[killstreak], gKSChalXP[CurChalLevel])
				g_Experience[id]+=gKSChalXP[CurChalLevel]
				badgegained=true;
			}
		}
	}
	else
	{
		CurChalLevel = g_KillstreakChalKill[id][killstreak]
		if (CurChalLevel < 8)
		{
			if ( g_KillstreakKills[id][killstreak] > gKSChalKills[CurChalLevel] )
			{
				g_KillstreakChalKill[id][killstreak]++
				show_hudmessage(id, "%s^nGet %d kills with a %s^n+%dXP", g_ChalNameKillstreakKills[killstreak][CurChalLevel], gKSChalKills[CurChalLevel]+1, g_KillstreakName[killstreak], gKSChalXP[CurChalLevel]);
				client_print(id, print_chat, "[MW2] You have completed the %s (%d Kills, +%dXP) challange",  g_ChalNameKillstreakKills[killstreak][CurChalLevel],  gKSChalKills[CurChalLevel]+1, gKSChalXP[CurChalLevel])
				g_Experience[id]+=gKSChalXP[CurChalLevel]
				badgegained=true;
			}
		}
	}

	if (badgegained)
	{
		client_cmd(id, "spk %s", gSoundBadge);
		SaveLevel(id);
		set_task(5.0, "check_level", id+LEVEL_TASK)
	}
	else
		check_level(id);

	return PLUGIN_HANDLED
}

public check_killstreaks_silent(id)
{
	new counter, counter2
	for( new i=0;i<TOT_KILLSTREAKS;i++ )
	{
		//Checks all CALLS for the streaks
		for (counter = 0; counter < MAXLVL_CHAL-1; counter++)
		{
			if ( g_NumKillstreaks[id][i] > gKSChalNum[counter] )
				g_KillstreakChal[id][i] = counter
			else
				break;
		}
	}
	
	
	for( new i=0;i<TOT_KILLSTREAKS;i++ )
	{
		//Checks all KILLS for the streaks
		for (counter2 = 0; counter2 < MAXLVL_CHAL-1; counter2++)
		{
			if ( g_NumKillstreaks[id][i] > gKSChalKills[counter2] )
				g_KillstreakChalKill[id][i] = counter2;
			else
				break;
		}
	}
}

enum radiotext_msgarg 
{
	RADIOTEXT_MSGARG_PRINTDEST = 1,
	RADIOTEXT_MSGARG_CALLERID,
	RADIOTEXT_MSGARG_TEXTTYPE,
	RADIOTEXT_MSGARG_CALLERNAME,
	RADIOTEXT_MSGARG_RADIOTYPE,
}

public hook_TextMessage(const MsgId, const MsgDest, const MsgEntity)
{
	static Message[192]
	get_msg_arg_string(2, Message, 191)
	
	set_hudmessage(0, 255, 0, -1.0, 0.40, 2, 5.0, 8.0, 0.02, 0.02, 1)
	
	if (equal(Message, "#Fire_in_the_hole"))
	{
		if (get_msg_args() != 5 || get_msg_argtype(RADIOTEXT_MSGARG_RADIOTYPE) != ARG_STRING)
			return PLUGIN_CONTINUE
	
		static arg[32]
		get_msg_arg_string(RADIOTEXT_MSGARG_RADIOTYPE, arg, sizeof arg - 1)
		if (!equal(arg, "#Fire_in_the_hole"))
			return PLUGIN_CONTINUE
	
		get_msg_arg_string(RADIOTEXT_MSGARG_CALLERID, arg, sizeof arg - 1)
		new caller = str_to_num(arg)
		if (!g_isalive[caller])
			return PLUGIN_CONTINUE
	}
	
	if (equal(Message, "#Terrorists_Win"))
	{
		g_RoundOwner = true
		new Players[32]
		new playerCount, i, player
		get_players(Players, playerCount, "c")
		for (i=0; i<playerCount; i++)
		{
			player = Players[i]
			if (cs_get_user_team(player) == CS_TEAM_T)
			{
				new XPReward = g_DoubleXP ? 2000 : 1000
				switch(g_TeamRand)
				{
					case USA: show_hudmessage(player, "Victory!^n^nOpFor: %d^nRangers: %d^nMatch Bonus +%dXP", g_Score[0] , g_Score[1], XPReward)
					case SAS: show_hudmessage(player, "Victory!^n^nSpetsnaz: %d^nSAS: %d^nMatch Bonus +%dXP", g_Score[0] , g_Score[1], XPReward)
				}
				set_msg_arg_string(2, "")
				g_Experience[player] += XPReward
				client_cmd(player, "spk %s", gVictory);
			}
			if (cs_get_user_team(player) == CS_TEAM_CT)
			{
				new XPReward = g_DoubleXP ? 1000 : 500
				switch(g_TeamRand)
				{
					case USA: show_hudmessage(player, "Defeat!^n^nOpFor: %d^nRangers: %d^nMatch Bonus +%dXP", g_Score[0] , g_Score[1], XPReward)
					case SAS: show_hudmessage(player, "Defeat!^n^nSpetsnaz: %d^nSAS: %d^nMatch Bonus +%dXP", g_Score[0] , g_Score[1], XPReward)
				}
				set_msg_arg_string(2, "")
				g_Experience[player] += XPReward
				client_cmd(player, "spk %s", gDefeat);
			}
		}
	}
	if (equal(Message, "#CTs_Win"))
	{
		g_RoundOwner = true
		new Players[32]
		new playerCount, i, player
		get_players(Players, playerCount, "c")
		for (i=0; i<playerCount; i++)
		{
			player = Players[i]
			if (cs_get_user_team(player) == CS_TEAM_CT)
			{
				new XPReward = g_DoubleXP ? 2000 : 1000
				switch(g_TeamRand)
				{
					case USA: show_hudmessage(player, "Victory!^n^nOpFor: %d^nRangers: %d^nMatch Bonus +%dXP", g_Score[0] , g_Score[1], XPReward)
					case SAS: show_hudmessage(player, "Victory!^n^nSpetsnaz: %d^nSAS: %d^nMatch Bonus +%dXP", g_Score[0] , g_Score[1], XPReward)
				}
				set_msg_arg_string(2, "")
				g_Experience[player] += XPReward
				client_cmd(player, "spk %s", gVictory);
			}
			if (cs_get_user_team(player) == CS_TEAM_T)
			{
				new XPReward = g_DoubleXP ? 1000 : 500
				switch(g_TeamRand)
				{
					case USA: show_hudmessage(player, "Defeat!^n^nOpFor: %d^nRangers: %d^nMatch Bonus +%dXP", g_Score[0] , g_Score[1], XPReward)
					case SAS: show_hudmessage(player, "Defeat!^n^nSpetsnaz: %d^nSAS: %d^nMatch Bonus +%dXP", g_Score[0] , g_Score[1], XPReward)
				}
				set_msg_arg_string(2, "")
				g_Experience[player] += XPReward
				client_cmd(player, "spk %s", gDefeat);
			}
		}
	}
	return PLUGIN_HANDLED
}

public hook_StatusValue()
{
	set_msg_block(gmsgStatusText, BLOCK_SET);
}

public setTeam(id)
{
	g_Friend[id] = read_data(2)
}

public on_ShowStatus(id) //called when id looks at someone
{
	new name[32], pid = read_data(2);
	new pidrank = g_PlayerRank[pid]+1;
	
	get_user_name(pid, name, 31);
	new color1 = 0, color2 = 0;
	
	if (get_user_team(pid) == 1)
		color1 = 255;
	else
		color2 = 255;
	
	new Float:height=0.35
	
	if (g_Friend[id] == 1)
	{
		set_hudmessage(color1, 50, color2, -1.0, height, 1, 0.01, 3.0, 0.01, 0.01);
		ShowSyncHudMsg(id, gHudSyncInfo, "[%d] %s", pidrank, name);
	} 
	else if (g_Friend[id] != 1 && g_Perk[pid][1] != PRK2_COLDB)
	{
		set_hudmessage(color1, 50, color2, -1.0, height, 1, 0.01, 3.0, 0.01, 0.01);
		ShowSyncHudMsg(id, gHudSyncInfo, "%s", name);
	}
	DisplayHUD(id);
}

public on_HideStatus(id)
{
	ClearSyncHud(id, gHudSyncInfo);
	
	DisplayHUD(id);
}

public DisplayHUD(id)
{
	if ( !g_isalive[id] ) return;
	
	static HUD[64];
	
	new rank = g_PlayerRank[id];
	new nextrank = rank+1;
	//if (nextrank > 69) nextrank = 69
	
	//if (g_Experience[id]>gRankXP[nextrank])
	//	check_level(id)
	
	new rankxp
	if (g_Experience[id]>=gRankXP[69])
	{
		g_Experience[id] = gRankXP[69]
		rankxp = gRankXP[69]
	}
	 else rankxp = gRankXP[nextrank]
	
	formatex(HUD, charsmax(HUD), "[MW2] %d/%d (%d) %s (%d)", g_Experience[id], rankxp, (rankxp-g_Experience[id]), gRankName[rank], g_PlayerRank[id]+1);
	
	message_begin(MSG_ONE_UNRELIABLE, gmsgStatusText, _, id);
	write_byte(0);
	write_string(HUD);
	message_end();
}

public ham_WeaponCleaner_Post(ent)
	call_think(ent)

public ham_PlayerSpawn_Post(id)
{
	if (is_user_alive(id))
	{
		g_isalive[id] = true
		g_HasShield[id] = false
		g_Shielded[id] = false
		g_FakeDelay[id] = false
		g_Stuck[id] = false
		g_islaststand[id] = false
		
		if (g_Starting)
		{
			g_FirstSpawn[id] = false
			client_cmd(id, "mp3 play sound/%s", gRoundStart[random(sizeof gRoundStart)]);
		}
		else if (!g_Starting && g_FirstSpawn[id])
		{
			g_FirstSpawn[id] = false
			client_cmd(id, "spk %s", gModeSound[g_RandMode])	
		}
		else client_cmd(id, "spk %s", gPlayerSpawn)
		
		if (g_ShouldCheck[id])
			check_level(id)
		else
		{
			g_ShouldCheck[id] = true
			
			check_level_silent(id)
			//check_challenges_silent(id)
			//check_killstreaks_silent(id)
		}
		
		strip_user_weapons(id)
		give_item(id,"weapon_knife")
		
		if (is_user_bot(id))
		{
			g_PlayerClass[id] = random_num(GRENADIER, SNIPER)
		}
		
		if (!g_PlayerClass[id])
		{
			if (g_PlayerRank[id] > 3)
				CMD_ClassMenuCustom(id)
			else
				CMD_ClassMenu(id)
		}
		else
			give_weapons(id)
		
		if (g_EMPCaller && get_user_team(id) != g_EMPCaller)
			task_SetEMPEffects(id)
		
		g_MaxHealth[id] = float(clamp((g_ChallangeCounter[ASSAULT][id]+100), 100, 175))
		if(access(id, ADMIN_MEMBERSHIP))
			g_MaxHealth[id]+=25.0
		set_user_health(id,floatround(g_MaxHealth[id]))
		
		give_item(id, "item_assaultsuit");
		new armor = (g_ChallangeCounter[OTHER][id]*3)+ (g_Perk[id][0] == PRK1_BLING ? 50 : 0)
		cs_set_user_armor(id, armor, CS_ARMOR_VESTHELM);
		
		DisplayHUD(id)
		
		if (g_Perk[id][0] == PRK1_MARAT)
		{
			callfunc_begin("flag_runner",DominationVersion)
			callfunc_push_int(id)
			callfunc_push_float(0.5)
			callfunc_end()
		}
		else
		{
			callfunc_begin("flag_runner",DominationVersion)
			callfunc_push_int(id)
			callfunc_push_float(1.0)
			callfunc_end()
		}
		
		remove_task(id + MODELSET_TASK)

		switch(g_TeamRand)
		{
			case USA:
			{
				switch(cs_get_user_team(id))
				{
					case CS_TEAM_CT: copy(g_PlayerModel[id], charsmax(g_PlayerModel[]), g_ArmyRanger)
					case CS_TEAM_T: copy(g_PlayerModel[id], charsmax(g_PlayerModel[]), g_Opfor)
				}
			}
			case SAS:
			{
				switch(cs_get_user_team(id))
				{
					case CS_TEAM_CT: copy(g_PlayerModel[id], charsmax(g_PlayerModel[]), g_SAS)
					case CS_TEAM_T: copy(g_PlayerModel[id], charsmax(g_PlayerModel[]), g_Spetsnaz)
				}
			}
		}
		new currentmodel[32]
		fm_get_user_model(id, currentmodel, charsmax(currentmodel))
		if (!equal(currentmodel, g_PlayerModel[id]))
		{
			if (get_gametime() - g_RoundStartTime < 5.0)
				set_task(5.0 * MODELCHANGE_DELAY, "fm_user_model_update", id + MODELSET_TASK)
			else
				fm_user_model_update(id + MODELSET_TASK)
		}
	}
	return HAM_HANDLED
}

public fw_SetClientKeyValue(id, const infobuffer[], const key[])
{   
	if (g_HasCustomModel[id] && equal(key, "model"))
		return FMRES_SUPERCEDE
	return FMRES_IGNORED
}

public fw_ClientUserInfoChanged(id)
{
	if (!g_HasCustomModel[id])
		return FMRES_IGNORED
	static currentmodel[32]
	fm_get_user_model(id, currentmodel, charsmax(currentmodel))
	if (!equal(currentmodel, g_PlayerModel[id]) && !task_exists(id + MODELSET_TASK))
		fm_set_user_model(id + MODELSET_TASK)
	return FMRES_IGNORED
}

public fm_user_model_update(taskid)
{
	static Float:current_time
	current_time = get_gametime()
	
	if (current_time - g_ModelsTargetTime >= MODELCHANGE_DELAY)
	{
		fm_set_user_model(taskid)
		g_ModelsTargetTime = current_time
	}
	else
	{
		set_task((g_ModelsTargetTime + MODELCHANGE_DELAY) - current_time, "fm_set_user_model", taskid)
		g_ModelsTargetTime = g_ModelsTargetTime + MODELCHANGE_DELAY
	}
}

public fm_set_user_model(player)
{
	player -= MODELSET_TASK
	engfunc(EngFunc_SetClientKeyValue, player, engfunc(EngFunc_GetInfoKeyBuffer, player), "model", g_PlayerModel[player])
	g_HasCustomModel[player] = true
}

stock fm_get_user_model(player, model[], len)
{
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, player), "model", model, len)
}

stock fm_reset_user_model(player)
{
	g_HasCustomModel[player] = false
	dllfunc(DLLFunc_ClientUserInfoChanged, player, engfunc(EngFunc_GetInfoKeyBuffer, player))
}

public touch_nade(nade, id) 
{
	if (!is_nade_bounce(nade) || is_nade_excluded(nade))
		return

	static owner
	owner = entity_get_edict(nade, EV_ENT_owner)
	if (g_Equiptment[owner] == EQU_SMTX)
	{
		entity_set_edict(nade, EV_ENT_aiment, id)
		entity_set_int(nade, EV_INT_movetype, MOVETYPE_FOLLOW)
		entity_set_int(nade, EV_INT_sequence, 0)
		g_Stuck[id] = true

		set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2)
		if (get_user_team(owner) == get_user_team(id))
			show_hudmessage(owner, "Stuck^nYou've stuck your teammate with a semtex grenade");
		else
			show_hudmessage(owner, "Stuck^nStick an enemy with a semtex grenade");

		client_cmd(id, "spk %s", gPayback);
	}	
}

public fw_EmitSnd(nade, channel, sound[]) 
{
	if (is_nade_bounce(nade)) 
	{
		static owner
		owner = entity_get_edict(nade, EV_ENT_owner)
		if (g_Equiptment[owner] == EQU_SMTX)
		{
			for (new i = 0; i < sizeof g_BounceSounds; ++i) 
			{
				if (equal(sound, g_BounceSounds[i]) && !is_nade_excluded(nade)) 
				{
					entity_set_int(nade, EV_INT_movetype, MOVETYPE_NONE)
					entity_set_int(nade, EV_INT_sequence, 0)
					break
				}
			}
		}
	}
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity)) 
		return FMRES_IGNORED

	if(!equali(model, g_NadeModel)) 
		return FMRES_IGNORED

	new className[33]
	entity_get_string(entity, EV_SZ_classname, className, 32)

	if(equal(className, "grenade"))
	{
		entity_set_model(entity, gFragModel[1])
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

stock bool:is_nade_bounce(nade) 
{
	return entity_get_int(nade, EV_INT_movetype) == MOVETYPE_BOUNCE
}

stock bool:is_nade_excluded(nade) 
{
	static owner
	owner = entity_get_edict(nade, EV_ENT_owner)
	if (g_Equiptment[owner] != EQU_SMTX)
		return false
		
	new model[32]
	entity_get_string(nade, EV_SZ_model, model, 31)
	if (equal(model, g_NadeModel))
		return true

	return false
}

public ham_ThinkGrenade(entity)
{
	if (!is_valid_ent(entity)) return HAM_IGNORED;
	
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Check if it's time to go off
	if (dmgtime > get_gametime())
		return HAM_IGNORED;
	
	engfunc(EngFunc_EmitSound, entity, CHAN_WEAPON, gGrenadeEXP, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	set_pev(entity, pev_flTimeStepSound, 0)
	return HAM_IGNORED;
}

public ham_TakeDamage(victim, useless, attacker, Float:damage, damagebits)
{
	if (g_RoundOwner) return HAM_SUPERCEDE

	if (!is_user_connected(attacker) || !is_user_alive(victim)) return HAM_HANDLED
	
	if (damagebits & (1<<24))
	{
		switch (g_Equiptment[attacker])
		{
			case EQU_SMTX:
			{
				if (g_Stuck[victim]) damage*=99.0
			}
			case EQU_FRAG: damage*=1.25
		}
		
	}
	
	new bool:TeamKill
	if (get_user_team(attacker) == get_user_team(victim)) TeamKill = true
	
	if (!TeamKill && damage>0.0)
	{
		g_AssistKiller[PREVIOUS_ASSIST][victim]=g_AssistKiller[CURRENT_ASSIST][victim]
		g_AssistKiller[CURRENT_ASSIST][victim]=attacker
	}
	
	if ( is_user_alive(attacker) &&  !TeamKill )
	{
		client_cmd(attacker, "spk %s", gBulletImpact);
		set_hudmessage(255, 255, 255, -1.0, -1.0, 0, 0.1, 0.4, 0.02, 0.02, 1);
		show_hudmessage(attacker, "x");
	}

	if ( is_user_alive(victim) &&  !TeamKill && !g_isflashed[victim] )
	{
		message_begin( MSG_ONE_UNRELIABLE , gmsgScreenFade , {0,0,0} , victim );
		write_short( 1<<12 );
		write_short( 1<<12 );
		write_short( 1<<12 );
		write_byte( 175 );
		write_byte( 0 );
		write_byte( 0 );
		write_byte( 150 );
		message_end();
	}
	
	if (g_Perk[victim][2] == PRK3_SCRAM)
	{
		switch (random_num(1,7))
		{
			case 1: return HAM_SUPERCEDE
		}
	}
	
	if (g_CurrentWeapon[attacker] == CSW_KNIFE)
	{
		if (g_HasShield[attacker]) 
			emit_sound(attacker, CHAN_WEAPON, gShieldBashHit, 1.0, ATTN_NORM, 0, PITCH_NORM);
		else if (g_Perk[attacker][2] != PRK3_COMMA)
			damage *= 2.5
	}
	
	if (g_Perk[attacker][1] == PRK2_STOPP)
		damage += 10.0
		
	if (g_Perk[attacker][1] == PRK2_DANGE && damagebits & (1<<24))
		damage *= 1.5

	if (g_Perk[victim][2] == PRK3_LASTS)
	{
		if(g_isalive[victim]
		&& damage >= float(get_user_health(victim))
		&&  !g_islaststand[victim]
		&& g_CurrentWeapon[attacker] != CSW_KNIFE
		&& !g_Stuck[victim])
		{
			task_LastStand(victim)
			new parm[5]
			parm[0] = victim
			parm[1] = useless
			parm[2] = attacker
			parm[3] = floatround(damage)
			parm[4] = damagebits
			set_task(5.0, "reDamage", victim+LASTSTAND_TASK, parm, 5)
			
			set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2)
			show_hudmessage(victim, "Last Stand^nKill The Enemy Before You Bleed Out")
			
			return HAM_HANDLED
		}
	}
	SetHamParamFloat(4, damage)
	return HAM_HANDLED
}

public reDamage(parm[])
	Ham_ExecDamageB(parm[0], parm[1], parm[2], 255, HIT_GENERIC, parm[4])

public task_LastStand(id)
{
	g_islaststand[id] = true
	
	set_pev(id, pev_sequence, 2)
	set_pev(id, pev_health, 255.0)
	
	message_begin(MSG_ONE, gmsgSetFOV, _, id)
	write_byte(135) // fov angle
	message_end()
	
	ev_CurWeapon(id)	
}

public ham_PrimaryAttack(wpnid)
{
	new classname[32]
	entity_get_string(wpnid, EV_SZ_classname, classname, 31)
	if(equal(classname, "weapon_knife") || equal(classname, "weapon_hegrenade") || equal(classname, "weapon_flashbang") || equal(classname, "weapon_smokegrenade")) return HAM_HANDLED
	
	if(get_pdata_int(wpnid,m_iClip,m_iClip_linuxoffset))
	{
		static Float:start[3], Float:dest[3] , Float:viewOffset[3], Float:path[3]
        
		new id = pev(wpnid,pev_owner)
        
		pev(id,pev_origin,start);
		pev(id,pev_view_ofs,viewOffset);
		xs_vec_add(start,viewOffset,start);

		pev(id,pev_v_angle,path);
		engfunc(EngFunc_MakeVectors,path);
		global_get(glb_v_forward,path);

		xs_vec_mul_scalar(path,9999.0,dest);
		xs_vec_add(start,dest,dest);
            
		engfunc(EngFunc_TraceLine,start,dest,0,id,0);
        
		if(get_tr2(0,TR_iHitgroup) == 8)
		{
			new ent, bodypart
			get_user_aiming (id,ent,bodypart)
			
			if (g_Shielded[ent] && get_user_team(ent) != get_user_team(id))
			{
				new attackpoints = 5
				set_hudmessage(240, 240, 0, random_float(0.45, 0.55), random_float(0.35, 0.45), 0, 0.1, 0.4, 0.02, 0.02, 1);
				show_hudmessage(ent, "+%dXP", attackpoints);
				g_Experience[ent] += attackpoints
				
				check_level(ent)
				//SaveLevel(ent)
				//DisplayHUD(ent)
			}
		}
	}
	
	return HAM_HANDLED
}

public ham_Reload_Post(iEnt)
{    
	if( get_pdata_int(iEnt, m_fInReload, 4) )
	{
		new id = get_pdata_cbase(iEnt, m_pPlayer, 4)
		if(g_Perk[id][0] == PRK1_SLIGH)
		{
			new Float:fDelay = g_fDelay[get_pdata_int(iEnt, m_iId, 4)] * RELOAD_RATIO
			set_pdata_float(id, m_flNextAttack, fDelay, 5)
			//set_pev(id, pev_animtime, fDelay) //---------------------------------------------------------------------------------------------------------------
			set_pdata_float(iEnt, m_flTimeWeaponIdle, fDelay, 4)
			set_pev(id, pev_frame, 200.0)
		}
	}
}

public ev_AmmoX(id)
{
	if (g_Perk[id][0] == PRK1_SCAVE)
		set_pdata_int(id, 376 + read_data(1), 180, 5)
} 

public fw_Traceline_Post(Float:v1[3],Float:v2[3],noMonsters,id,ptr)
{
	if(!is_valid_ent(id))
		return FMRES_IGNORED;
		
	if(!is_user_connected(id))
		return FMRES_IGNORED;

	// grab normal trace
	if(!normalTrace[id])
	{
		normalTrace[id] = ptr;
		return FMRES_IGNORED;
	}

	// ignore normal trace
	else if(ptr == normalTrace[id])
		return FMRES_IGNORED;

	if(!g_isalive[id] || g_Perk[id][2] != PRK3_STEAD)
		return FMRES_IGNORED;

	new weapon = get_user_weapon(id);

	if(weapon == CSW_HEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_SMOKEGRENADE || weapon == CSW_C4 || weapon == CSW_KNIFE || weapon == CSW_M3 || weapon == CSW_XM1014)
		return FMRES_IGNORED;

	// get crosshair aim
	static Float:aim[3];
	get_aim(id,v1,aim);
	
	// do another trace to this spot
	new trace = create_tr2();
	engfunc(EngFunc_TraceLine,v1,aim,noMonsters,id,trace);
	
	// copy ints
	set_tr2(ptr,TR_AllSolid,get_tr2(trace,TR_AllSolid));
	set_tr2(ptr,TR_StartSolid,get_tr2(trace,TR_StartSolid));
	set_tr2(ptr,TR_InOpen,get_tr2(trace,TR_InOpen));
	set_tr2(ptr,TR_InWater,get_tr2(trace,TR_InWater));
	set_tr2(ptr,TR_pHit,get_tr2(trace,TR_pHit));
	set_tr2(ptr,TR_iHitgroup,get_tr2(trace,TR_iHitgroup));

	// copy floats
	get_tr2(trace,TR_flFraction,aim[0]);
	set_tr2(ptr,TR_flFraction,aim[0]);
	get_tr2(trace,TR_flPlaneDist,aim[0]);
	set_tr2(ptr,TR_flPlaneDist,aim[0]);
	
	// copy vecs
	get_tr2(trace,TR_vecEndPos,aim);
	set_tr2(ptr,TR_vecEndPos,aim);
	get_tr2(trace,TR_vecPlaneNormal,aim);
	set_tr2(ptr,TR_vecPlaneNormal,aim);

	// get rid of new trace
	free_tr2(trace);

	return FMRES_IGNORED;
}

get_aim(id,Float:source[3],Float:ret[3])
{
	static Float:vAngle[3], Float:pAngle[3], Float:dir[3], Float:temp[3];

	// get aiming direction from forward global based on view angle and punch angle
	pev(id,pev_v_angle,vAngle);
	pev(id,pev_punchangle,pAngle);
	xs_vec_add(vAngle,pAngle,temp);
	engfunc(EngFunc_MakeVectors,temp);
	global_get(glb_v_forward,dir);
	
	/* vecEnd = vecSrc + vecDir * flDistance; */
	xs_vec_mul_scalar(dir,8192.0,temp);
	xs_vec_add(source,temp,ret);
}

public client_PreThink(id) 
{
	if(g_Perk[id][2] == PRK3_COMMA && g_isalive[id] && g_isconnected[id]) 
	{
		if(entity_get_float(id, EV_FL_flFallVelocity) >= 350.0)  //fall velocity
		{
			g_isfalling[id] = true;
		} 
		else 
		{
			g_isfalling[id] = false;
		}
	}
}

public client_PostThink(id) 
{
	if(g_Perk[id][2] == PRK3_COMMA && g_isalive[id] && g_isconnected[id]) 
	{
		if(g_isfalling[id]) 
		{
			entity_set_int(id, EV_INT_watertype, -3);
		}
	}
}

public fw_Player_PreThink( id )
{
	if (!g_isalive[id] || !g_isconnected[id]) return FMRES_HANDLED
	
	pev(id, pev_origin, g_flLocation[id])
	
	new button = pev(id, pev_button)            // buttons in current frame
	new oldbutton = pev(id, pev_oldbuttons)    // buttons in previous frame

	if(g_CurrentWeapon[id] == CSW_KNIFE && button & IN_ATTACK)
	{
		if (!g_HasShield[id])
		{
			button = (button & ~IN_ATTACK ) | IN_ATTACK2;
			set_pev(id, pev_button, button);
		}
		new target, body
		get_user_aiming(id, target, body, 350)
		if (is_user_alive(target) && get_user_team(target) != get_user_team(id) && g_Perk[id][2] == PRK3_COMMA)
		{
			cmdPlayerBash(id, 1000, 1.0)
			return FMRES_HANDLED
		}
		else if (is_user_alive(target) && get_user_team(target) != get_user_team(id) && g_Shielded[id])
		{
			cmdPlayerBash(id, 250, 0.3)
			return FMRES_HANDLED
		}
	}
	else if (g_CurrentWeapon[id] == CSW_KNIFE && g_HasShield[id] && !g_FakeDelay[id] && button & IN_ATTACK2 && oldbutton & IN_ATTACK2)
	{
		button = (button & ~IN_ATTACK2 ) | IN_RELOAD;
		set_pev(id, pev_button, button);
	}
	else if (g_CurrentWeapon[id] == CSW_KNIFE && g_HasShield[id] && !g_FakeDelay[id] && button & IN_ATTACK2 && !(oldbutton & IN_ATTACK2))
	{
		g_FakeDelay[id] = true
		remove_task(id+FAKEDELAY_TASK)
		set_task(0.3, "End_FakeDelay", id+FAKEDELAY_TASK);
		g_Shielded[id] = g_Shielded[id] ? false : true
		if (g_Shielded[id]) client_print(id, print_center, "SHIELDED")
		else client_print(id, print_center, "--------")
	}

	return FMRES_IGNORED
}

public cmdPlayerBash(id, speed, Float:time)
{
	static Float:cdown;
	cdown = 1.0;

	if (get_gametime() - g_LastPressedSkill[id] <= cdown) 
	{
		return PLUGIN_HANDLED;
	}
	else if ( get_gametime() - g_LastPressedSkill[id] >= cdown )
	{
		g_LastPressedSkill[id] = get_gametime()
	}
	if (g_HasShield[id]) emit_sound(id, CHAN_WEAPON, gShieldBash, 1.0, ATTN_NORM, 0, PITCH_NORM);
	static Float: velocity[3];
	velocity_by_aim(id, speed, velocity);
	set_pev(id, pev_velocity, velocity);
	set_pev(id, pev_gravity, 2.0)
	IsChargeDelay[id] = true;
	g_hasdmged[id] = false
	set_task( time, "Task_Charge", id+CHARGE_TASK);
	
	return PLUGIN_CONTINUE;
}

public Task_Charge(taskid)
{
	taskid -= CHARGE_TASK;
	set_pev(taskid, pev_gravity, 1.0)
	IsChargeDelay[taskid] = false;
}

public fw_StartFrame()
{
	// Declare static variables
	static Float:gtime
	static ctime
	static nreact
	static id
	
	// Declare rocket information variables
	static rocket, Float:Vel[3], Float:Angles[3]
	
	// Get data
	gtime = get_gametime()
	ctime = floatround(gtime*1000)
	floatround((gtime+REACTION_SPEED)*1000)
	
	// Cycle through all players
	for(id = 1; id < 33; id++)
	{
		if(!is_user_alive(id) && !g_ispredator[id]) continue
		
		// The delay time hasn't been reached yet
		if(g_UserRocket[id][rocket_nreact] > ctime) continue
		g_UserRocket[id][rocket_nreact] = nreact
		
		// Get the rocket entity
		rocket = g_UserRocket[id][rocket_entity]
		if(rocket != -1 && pev_valid(rocket))
		{
			// Get player's aim and update rocket's aim
			velocity_by_aim(id, ROCKET_SPEED, Vel)
			set_pev(rocket, pev_velocity, Vel)
					
			// Reformat velocity to angles
			vector_to_angle(Vel, Angles)
					
			// Do some calculations so the view of the rocket looks fine
			Angles[0] = 360-Angles[0]
			set_pev(rocket, pev_angles, Angles)
			Angles[0] *= -1
			set_pev(rocket, pev_v_angle, Angles)
			
			//entity_get_vector(id,EV_VEC_angles,Angles)
			//entity_set_vector(rocket, EV_VEC_angles,Angles)
		}
	}
	return FMRES_IGNORED
}

public fw_Touch(id,target)
{
	if (is_valid_ent(id))
	{
		// Valid entity, check if it's a rocket
		static classname[32]
		pev(id, pev_classname, classname, 31)
		
		if(equal(classname, gPredatorName))
		{
			// RPG Rocket, get origin
			new Float:fOrigin[3]
			pev(id, pev_origin, fOrigin)
				
			// Explosion
			engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, fOrigin, 0)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, fOrigin[0])
			engfunc(EngFunc_WriteCoord, fOrigin[1])
			engfunc(EngFunc_WriteCoord, fOrigin[2])
			write_short(gSpriteExplosion)
			write_byte(30)
			write_byte(15)
			write_byte(0)
			message_end()
				
			// Create damage impact on rocket's location
			new attacker = pev(id, pev_owner)
			//new bool:pattacked[33]
			new player = -1
			while( ( player = engfunc( EngFunc_FindEntityInSphere, player, fOrigin, 500.0 ) ) != 0 && (get_user_team(player) != get_user_team(attacker) || player == attacker))
			{
				if( is_user_alive(player) )
				{
					Ham_ExecDamageB(player, g_AirstrikeKiller, attacker, 250, HIT_GENERIC, DMG_GENERIC)
					//pattacked[player] = true

					g_KillstreakKills[attacker][KS_PRED]++
					check_killstreaks(attacker, KS_PRED, 1)
					
					g_Kills[attacker]++
					g_Kills[player] = 0
					
					if (g_RandMode == TDM && g_Score[TERROR] < g_WinNumber && g_Score[COUNTER] < g_WinNumber)
					{
						switch (cs_get_user_team(attacker))
						{
							case CS_TEAM_T:g_Score[TERROR] += 100
							case CS_TEAM_CT:g_Score[COUNTER] += 100
						}
						update_tdm_hud()
					}
				}
			}
				
			if(pev_valid(target))
			{
				// Check if the touched entity is breakable, if so, break it :)
				pev(target, pev_classname, classname, 31)
				if(equal(classname, "func_breakable"))
					dllfunc(DLLFunc_Use, id, target)
			}
				
			// Kill the rocket and reset data
			set_pev(id, pev_flags, FL_KILLME)
			remove_entity(id)
			g_UserRocket[attacker][rocket_entity] = -1
			
			engfunc(EngFunc_SetView, attacker, attacker)
			g_ispredator[attacker] = false
			//set_task(1.0, "task_StopSound", attacker)
		}
		else if (is_valid_ent(target))
		{
			if (is_user_alive(id) && is_user_alive(target))
			{
				if ( IsChargeDelay[id] && !g_hasdmged[id] && !g_HasShield[target]) 
				{
					if(g_Shielded[id] && g_Perk[id][2] == PRK3_COMMA)
					{
						Ham_ExecDamageB(target, g_ShieldKiller, id, 65, HIT_GENERIC, DMG_GENERIC)
						g_hasdmged[id] = true
					}
					else if (g_Shielded[id])
					{
						Ham_ExecDamageB(target, g_ShieldKiller, id, 75, HIT_GENERIC, DMG_GENERIC)
						g_hasdmged[id] = true	
					}
					else
					{
						Ham_ExecDamageB(target, g_ShieldKiller, id, 100, HIT_GENERIC, DMG_GENERIC)
						g_hasdmged[id] = true				
					}
					if (!is_user_alive(target))
					{
						g_GunStats[id][GUN_KILLS][CSW_KNIFE]++
						g_Kills[target] = 0
					}
				}
			}
		}
	}
} 

public task_StopSound(id)
	client_cmd(id, "stopsound")

public End_FakeDelay(taskid)
{
	if (taskid > g_MaxPlayers)
		taskid-=FAKEDELAY_TASK
		
	g_FakeDelay[taskid] = false
}

public fw_CmdStart( id, uc_handle, randseed )
{
	new Float:fmove, Float:smove;
	get_uc(uc_handle, UC_ForwardMove, fmove);
	get_uc(uc_handle, UC_SideMove, smove );

	new Float:maxspeed;
	pev(id, pev_maxspeed, maxspeed);
	new Float:walkspeed = (maxspeed * 0.52); 
	fmove = floatabs( fmove );
	smove = floatabs( smove );
    
	if (g_Perk[id][2] == PRK3_NINJA && is_user_alive(id))
	{
		if (fmove == 0.0 && smove == 0.0 && g_CurrentWeapon[id] == CSW_KNIFE)
			set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, 51)
		else if(fmove <= walkspeed && smove <= walkspeed)
			set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, 168)
		else
			set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, 255)
	}
}

update_tdm_hud()
{
	new Players[32]
	new playerCount, i, player
	
	set_hudmessage(255, 255, 255, -1.0, 0.05, 0, 6.0, 240.0, 0.1, 0.1, 3)
	new message[101]
	
	if (g_Score[TERROR] == 6600 && !g_HasSaid)
	{
		get_players(Players, playerCount, "c")
		for (i=0; i<playerCount; i++)
		{
			player = Players[i]
			
			if (cs_get_user_team(player) == CS_TEAM_T) client_cmd(player, "spk %s", gWinning);
			else if (cs_get_user_team(player) == CS_TEAM_CT) client_cmd(player, "spk %s", gLosing);
			g_HasSaid = true
		}
	}
	
	if (g_Score[COUNTER] == 6600 && !g_HasSaid)
	{
		get_players(Players, playerCount, "c")
		for (i=0; i<playerCount; i++)
		{
			player = Players[i]
			if (cs_get_user_team(player) == CS_TEAM_CT) client_cmd(player, "spk %s", gWinning);
			else if (cs_get_user_team(player) == CS_TEAM_T) client_cmd(player, "spk %s", gLosing);
			g_HasSaid = true
		}
	}
	
	if (g_Score[TERROR] > g_Score[COUNTER] && !g_WasntBefore[TERROR])
	{
		g_WasntBefore[TERROR] = true
		g_WasntBefore[COUNTER] = false
		get_players(Players, playerCount, "c")
		for (i=0; i<playerCount; i++)
		{
			player = Players[i]
			if (cs_get_user_team(player) == CS_TEAM_T) client_cmd(player, "spk %s", gHasLead);
			else if (cs_get_user_team(player) == CS_TEAM_CT) client_cmd(player, "spk %s", gLostLead);
		}
	}
	
	if (g_Score[TERROR] < g_Score[COUNTER] && !g_WasntBefore[COUNTER])
	{
		g_WasntBefore[COUNTER] = true
		g_WasntBefore[TERROR] = false
		get_players(Players, playerCount, "c")
		for (i=0; i<playerCount; i++)
		{
			player = Players[i]
			if (cs_get_user_team(player) == CS_TEAM_CT) client_cmd(player, "spk %s", gHasLead);
			else if (cs_get_user_team(player) == CS_TEAM_T) client_cmd(player, "spk %s", gLostLead);
		}
	}
	
	switch(g_TeamRand)
	{
		case USA: format(message, 100, "OpFor: %d | U.S. Army Rangers: %d", g_Score[TERROR] , g_Score[COUNTER])
		case SAS: format(message, 100, "Spetsnaz: %d | S.A.S.: %d", g_Score[TERROR] , g_Score[COUNTER])
	}
	show_hudmessage(0, "%s", message)
	
	if ( g_Score[TERROR] == g_WinNumber)
		TerminateRound( RoundEndType_TeamExtermination, TeamWinning_Terrorist, MapType_AutoDetect );
	if ( g_Score[COUNTER] == g_WinNumber)
		TerminateRound( RoundEndType_TeamExtermination, TeamWinning_Ct, MapType_AutoDetect );
}

public csf_flag_taken(id)
{
	if ( get_playersnum() < 4 ) return;

	set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2)
	show_hudmessage(id, "Position Secure!^n+150");
	g_Experience[id] += 150;
	DisplayHUD(id);
}

public csf_flag_taken_2(id)
{
	if ( get_playersnum() < 4 ) return;

	set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2)
	show_hudmessage(id, "Position Secure!^n+100");
	g_Experience[id] += 100;
	DisplayHUD(id);
}

public message_show_menu(msgid, dest, id) 
{
	if (!(!get_user_team(id) && !is_user_bot(id)/* && !access(id, ADMIN_IMMUNITY)*/))//
		return PLUGIN_CONTINUE

	static team_select[] = "#Team_Select"
	static menu_text_code[sizeof team_select]
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1)
	if (!equal(menu_text_code, team_select))
		return PLUGIN_CONTINUE

	static param_menu_msgid[2]
	param_menu_msgid[0] = msgid
	set_task(0.1, "task_force_team_join", id, param_menu_msgid, sizeof param_menu_msgid)

	return PLUGIN_HANDLED
}

public message_vgui_menu(msgid, dest, id) 
{
	if (get_msg_arg_int(1) != TEAM_SELECT_VGUI_MENU_ID || !(!get_user_team(id) && !is_user_bot(id)/* && !access(id, ADMIN_IMMUNITY)*/))// 
		return PLUGIN_CONTINUE
		
	static param_menu_msgid[2]
	param_menu_msgid[0] = msgid
	set_task(0.1, "task_force_team_join", id, param_menu_msgid, sizeof param_menu_msgid)

	return PLUGIN_HANDLED
}

public task_force_team_join(menu_msgid[], id) 
{
	if (get_user_team(id))
		return

	static msg_block
	msg_block = get_msg_block(menu_msgid[0])
	set_msg_block(menu_msgid[0], BLOCK_SET)
	engclient_cmd(id, "jointeam", "5")
	engclient_cmd(id, "joinclass", "5")
	set_msg_block(menu_msgid[0], msg_block)
}

public clcmd_changeteam(id)
{
	if (g_PlayerRank[id] > 3)
		CMD_ClassMenuCustom(id)
	else
		CMD_ClassMenu(id)
	return PLUGIN_HANDLED
}

public clcmd_drop(id)
	return PLUGIN_HANDLED

public task_HPRegenLoop()
{
	new players[32], num
	get_players(players, num, "ac")
			
	static player
	new NewHP
	for (new i = 0; i < num; i++)
	{
		player = players[i]

		if(g_isalive[player] && !g_islaststand[player]) 
		{
			if (get_user_health(player)<g_MaxHealth[player])
			{
				NewHP = get_user_health(player)
				NewHP += 3
			
				if(NewHP >= g_MaxHealth[player]) 
					NewHP = floatround(g_MaxHealth[player])
				set_user_health(player,NewHP)
			}
			else
			{
				set_user_health(player,floatround(g_MaxHealth[player]))
			}
		}
	}
}

public ev_CurWeapon(id)
{
	g_CurrentWeapon[id] = read_data(2)
	
	switch(g_CurrentWeapon[id])
	{
		case CSW_HEGRENADE: entity_set_string( id , EV_SZ_viewmodel , gFragModel[0] ) 
		case CSW_KNIFE:
		{
			if (g_HasShield[id])
			{
				entity_set_string( id , EV_SZ_viewmodel , gShieldModel[0] )  
				entity_set_string( id , EV_SZ_weaponmodel , gShieldModel[1] )  
			}
		}
	}
	
	if (!g_Starting && !g_HasShield[id])
	{
		new Float:AddSpeed = 240.0 + float(clamp((g_ChallangeCounter[SMG][id]/2)*2, 0, 75))
		if (g_Perk[id][1] == PRK2_LIGHT)
			AddSpeed+=50.0
		set_user_maxspeed(id, AddSpeed)
	}
	
	if (g_isalive[id] && g_islaststand[id] && g_Perk[id][2] == PRK3_LASTS)
	{
		if (g_CurrentWeapon[id] != g_CurrentSecondary[id])
		{
			new weapName[33]
			get_weaponname(g_CurrentSecondary[id], weapName, 32)
			client_cmd(id, weapName)
		}
		set_user_maxspeed(id, 1.0)
	}
}

public fw_FRC_preflash(flasher, flashed, flashbang, amount)
{
	switch (g_Equiptment[flasher])
	{
		case EQU_STUN:
		{
			set_FRC_duration(flashed, 4)
			set_FRC_holdtime(flashed, 1)
		
			new Float:fadetime = 4.0
			new fade = clamp(floatround(fadetime * float(1<<12)), 0, 0xFFFF);
			
			remove_task(flashed+FLASHBANG_TASK)
			set_task(fadetime, "task_EndFlash", flashed+FLASHBANG_TASK)
			g_isflashed[flashed] = true
				
			new Float:fVec[3];
			fVec[0] = random_float(PA_LOW , PA_HIGH);
			fVec[1] = random_float(PA_LOW , PA_HIGH);
			fVec[2] = random_float(PA_LOW , PA_HIGH);
			entity_set_vector(flashed , EV_VEC_punchangle , fVec);
			message_begin(MSG_ONE , gmsgScreenShake , {0,0,0} ,flashed)
			write_short( 1<<14 );
			write_short( fade );
			write_short( 1<<14 );
			message_end();
			
			client_cmd(flasher, "spk %s", gBulletImpact);
			set_hudmessage(255, 255, 255, -1.0, -1.0, 0, 0.1, 0.4, 0.02, 0.02, 1);
			show_hudmessage(flasher, "x");
		}
		case EQU_FLASH:
		{
			//set_FRC_duration(flashed, 70)
			set_FRC_holdtime(flashed, 40)
			
			remove_task(flashed+FLASHBANG_TASK)
			set_task(6.0, "task_EndFlash", flashed+FLASHBANG_TASK)
			g_isflashed[flashed] = true
		
			client_cmd(flasher, "spk %s", gBulletImpact);
			set_hudmessage(255, 255, 255, -1.0, -1.0, 0, 0.1, 0.4, 0.02, 0.02, 1);
			show_hudmessage(flasher, "x");
		}
	}

}

public task_EndFlash(id)
{
	id-=FLASHBANG_TASK
	g_isflashed[id] = false
}

public cmdSay(id)
{
	new arg[64], arg1[31], arg2[32]
	read_args(arg1, charsmax(arg1));
	remove_quotes(arg1);
	read_args(arg,63)
	remove_quotes(arg)
	strtok(arg,arg1,255,arg2,255,' ',1)
	trim(arg2)
	
	if(arg1[0] == '/')
	{
		if (equali(arg1, "/loadbyip") == 1 && !g_hasloaded[id])
		{
			get_user_ip(id, g_AuthID[id], charsmax(g_AuthID[]));
			LoadLevel(id);
			get_user_authid(id, g_AuthID[id], charsmax(g_AuthID[]));
			SaveLevel(id);
			g_hasloaded[id] = true
			
			if (g_isalive[id])
				ExecuteHamB(Ham_CS_RoundRespawn, id)
				
			client_print(id, print_chat, "[MW2] Checkpoint loaded, Steam ID XP overwritten");
		}
		else if (equali(arg1, "/savebyip") == 1)
		{
			get_user_ip(id, g_AuthID[id], charsmax(g_AuthID[]));
			SaveLevel(id);
			get_user_authid(id, g_AuthID[id], charsmax(g_AuthID[]));
				
			client_print(id, print_chat, "[MW2] Checkpoint created, type /loadbyip in the future to load this checkpoint");
		}
		else if (equali(arg1, "/class") == 1 || equali(arg1, "/changeclass") == 1 || equali(arg1, "/classmenu") == 1)
		{
			CMD_ClassMenu(id)
			return PLUGIN_HANDLED
		}
		else if (equali(arg1, "/codstats") == 1 || equali(arg1, "/stats") == 1 || equali(arg1, "/mystats") == 1)
		{
			CMD_CoDStatsMenu(id)
			//return PLUGIN_HANDLED
		}
		else if (equali(arg1, "/barracks") == 1 || equali(arg1, "/menu") == 1 || equali(arg1, "/codmenu") == 1)
		{
			CMD_CoDMenu(id)
			//return PLUGIN_HANDLED
		}
		else if (equali(arg1, "/tirant") == 1 && access(id, ADMIN_CVAR))
		{
			for ( new i=0; i<TOT_KILLSTREAKS ; i++)
			{
				g_HasKillstreak[id][i] = true
			}
			return PLUGIN_HANDLED
		}
		else if (equali(arg1, "/predator") == 1 && access(id, ADMIN_CVAR))
		{
			cmdGiveKillstreak(id, KS_PRED)
			return PLUGIN_HANDLED
		}
		else if (equali(arg1, "/airstrike") == 1 && access(id, ADMIN_CVAR))
		{
			cmdGiveKillstreak(id, KS_AIR)
			return PLUGIN_HANDLED
		}
		else if (equali(arg1, "/killstreak") == 1 || equali(arg1, "killstreak") == 1 || equali(arg1, "/ks") == 1)
		{
			if (!g_isalive[id]) return PLUGIN_HANDLED
			
			new TeamEMP = cs_get_user_team(id) == CS_TEAM_T ? TEAM_T : TEAM_CT
			if (g_isemped[TeamEMP])
			{
				client_print(id, print_center, "Killstreaks are unavailable during an EMP")
				return PLUGIN_HANDLED
			}
			
			if (g_HasKillstreak[id][KS_NUKE] && g_CanNuke)
			{
				g_CanNuke = false
				g_HasKillstreak[id][KS_NUKE] = false
				cmdCallNuke(id)
				return PLUGIN_HANDLED
			}
			if (g_HasKillstreak[id][KS_EMP])
			{
				g_HasKillstreak[id][KS_EMP] = false
				cmdCallEMP(id)
				return PLUGIN_HANDLED
			}
			if (g_HasKillstreak[id][KS_PRED])
			{
				g_HasKillstreak[id][KS_PRED] = false
				cmdCallPredator(id)
				return PLUGIN_HANDLED
			}
			if (g_HasKillstreak[id][KS_AIR])
			{
				if (g_CalledAirstrikes > 2)
				{
					client_print(id, print_center, "Airspace is too crowded!") //announced to self
					return PLUGIN_HANDLED
				}
				cmdCallAir(id)
				return PLUGIN_HANDLED
			}
			if (g_HasKillstreak[id][KS_COU])
			{
				g_HasKillstreak[id][KS_COU] = false
				cmdCallCOU(id)
				return PLUGIN_HANDLED
			}
			if (g_HasKillstreak[id][KS_UAV])
			{
				g_HasKillstreak[id][KS_UAV] = false
				cmdCallUAV(id)
				return PLUGIN_HANDLED
			}
		}
	}
	return PLUGIN_CONTINUE
}

public cmdGiveXP(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
		
	new target[32],points[21]
    	read_argv(1,target,31)
    	read_argv(2,points,20)
	new player = cmd_target(id,target,8)
    	if(!player) return PLUGIN_HANDLED 
	
	new player_name[32]
     	get_user_name(player,player_name,31)
	new crednum = str_to_num(points)
	g_Experience[player]+=crednum
	check_level(player)
	SaveLevel(player)
	//DisplayHUD(player);
	client_print(id,print_console,"[MW2] You have given %i XP to %s",crednum,player_name)
	
	return PLUGIN_CONTINUE
}

public cmdGiveStats(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
	
	new Arg1[32],Arg2[4], Arg3[4], Arg4[4]
	read_argv(1, Arg1, 31)
	read_argv(2, Arg2, 3)
	read_argv(3, Arg3, 3)
	read_argv(4, Arg4, 3)

	new player = cmd_target(id, Arg1, 0)
    	if(!player) return PLUGIN_HANDLED 
	
	new iCSW = str_to_num(Arg2)
	if (iCSW>30 || iCSW<1)
	{
		client_print(id,print_console,"[MW2] Invalid CSW entered")
		return PLUGIN_HANDLED;
	}
	
	new iMode = str_to_num(Arg3)
	if (iMode>1 || iMode<0)
	{
		client_print(id,print_console,"[MW2] Invalid mode entered")
		return PLUGIN_HANDLED;
	}
	
	new iStats = str_to_num(Arg4)
	if (iStats<0)
	{
		client_print(id,print_console,"[MW2] You cannot enter negative amounts")
		return PLUGIN_HANDLED;
	}
	
	g_GunStats[player][iMode][iCSW]+=iStats
	if (iMode) g_GunStats[player][0][iCSW]+=iStats
	
	SaveLevel(id)
	check_challenges(id)
	
	new szPlayerName[32]
     	get_user_name(player,szPlayerName,31)
	client_print(id,print_console,"[MW2] Player: %s | %s | %d | +%d",szPlayerName, gGunName[iCSW], iMode == 0 ? "Kills" : "Headshots", iStats)
	client_print(player, print_chat,"[MW2] %s | %d | +%d", gGunName[iCSW], iMode == 0 ? "Kills" : "Headshots", iStats)
	
	return PLUGIN_CONTINUE
}

public cmdGiveKillstreak(id, killstreak)
{
	g_HasKillstreak[id][killstreak] = true
	client_cmd(id, "spk %s", gKillstreakSounds[killstreak][KS_GIVE])
	
	set_hudmessage(255, 255, 255, -1.0, 0.30, 2, 3.0, 4.0, 0.02, 0.02, 4)
	switch(killstreak)
	{
		case KS_UAV:
		{
			client_cmd(id, "spk %s", gUAVEffect)
			show_hudmessage(id, "%s^nType /killstreak to use it!", g_KillstreakName[killstreak])
		}
		case KS_COU: show_hudmessage(id, "%s^nType /killstreak to use it!", g_KillstreakName[killstreak])	
		case KS_AIR: show_hudmessage(id, "%s^nType /killstreak and aim where you want it!", g_KillstreakName[killstreak])	
		case KS_PRED: show_hudmessage(id, "%s^nType /killstreak and control the missile!^n(Use your mouse to aim it)", g_KillstreakName[killstreak])	
		case KS_EMP:
		{
			client_cmd(id, "spk %s", gEMPEffect);
			show_hudmessage(id, "%s^nType /killstreak to use it!", g_KillstreakName[killstreak])	
		}
		case KS_NUKE: show_hudmessage(id, "%s^nType /killstreak to use it!", g_KillstreakName[killstreak])
	}
}

public cmdCallUAV(id)
{
	switch(cs_get_user_team(id))
	{
		case CS_TEAM_T:
		{
			g_HasUAV[TEAM_T] = true
			
			if (g_UAVTimer[TEAM_T]>get_gametime()) g_UAVTimer[TEAM_T]+=20.0
			else g_UAVTimer[TEAM_T] = get_gametime()+20.0
		}
		case CS_TEAM_CT:
		{
			g_HasUAV[TEAM_CT] = true
			
			if (g_UAVTimer[TEAM_CT]>get_gametime()) g_UAVTimer[TEAM_CT]+=20.0
			else g_UAVTimer[TEAM_CT] = get_gametime()+20.0
		}
	}
	
	g_NumKillstreaks[id][KS_UAV]++
	check_killstreaks(id, KS_UAV, 0)
	
	set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2)
	show_hudmessage(id, "+100");
	g_Experience[id] += 100;
	check_level(id)
	
	new playername[35]
	get_user_name(id,playername,34)
	client_print(0, print_chat, "%s called in by %s", g_KillstreakName[KS_UAV], playername);
	
	new Players[32]
	new playerCount, i
	get_players(Players, playerCount, "c")
	for (i=0; i<playerCount; i++)
	{ 
		if (get_user_team(Players[i]) == get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_UAV][KS_FRIEND])
		else if (get_user_team(Players[i]) != get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_UAV][KS_ENEMY])
	}
	return PLUGIN_HANDLED
}

public cmdCallCOU(id)
{
	switch (cs_get_user_team(id))
	{
		case CS_TEAM_T: g_HasUAV[TEAM_CT] = false
		case CS_TEAM_CT: g_HasUAV[TEAM_T] = false
	}
	
	g_NumKillstreaks[id][KS_COU]++
	check_killstreaks(id, KS_COU, 0)
	
	set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2)
	show_hudmessage(id, "+100");
	g_Experience[id] += 100;
	check_level(id)
	
	new playername[35]
	get_user_name(id,playername,34)
	client_print(0, print_chat, "%s called in by %s", g_KillstreakName[KS_COU], playername);
	
	new Players[32]
	new playerCount, i
	get_players(Players, playerCount, "c")
	for (i=0; i<playerCount; i++)
	{ 
		if (get_user_team(Players[i]) == get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_COU][KS_FRIEND])
		else if (get_user_team(Players[i]) != get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_COU][KS_ENEMY])
	}
	return PLUGIN_HANDLED
}

public cmdCallAir(id)
{
	new iOrigin[3]
	get_user_origin(id, iOrigin, 3)
	IVecFVec(iOrigin, g_flAirOrigin[id])
	
	if (engfunc(EngFunc_PointContents,iOrigin) == CONTENTS_SKY)
	{
		client_print(id,print_center,"You can't call in an airstrike there!")
		return PLUGIN_HANDLED
	}

	g_HasKillstreak[id][KS_AIR] = false
	g_NumKillstreaks[id][KS_AIR]++
	check_killstreaks(id, KS_AIR, 0)
	
	entity_get_vector(id,EV_VEC_angles,g_flAirAngles[id])
	g_flAirAngles[id][0]*=0
	
	set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2)
	show_hudmessage(id, "+200");
	g_Experience[id] += 200;
	check_level(id)
	
	new playername[35]
	get_user_name(id,playername,34)
	client_print(0, print_chat, "%s called in by %s", g_KillstreakName[KS_AIR], playername);
	
	new Players[32]
	new playerCount, i
	get_players(Players, playerCount, "c")
	for (i=0; i<playerCount; i++)
	{ 
		if (get_user_team(Players[i]) == get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_AIR][KS_FRIEND])
		else if (get_user_team(Players[i]) != get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_AIR][KS_ENEMY])
	}
	
	g_CalledAirstrikes++
	set_task(15.0, "task_ResetStrike")
	set_task(7.0, "task_SpawnJet", id+AIRSTRIKE_TASK)
	set_task(7.7, "task_Bombing", id+AIRSTRIKE_TASK)
	set_task(8.0, "task_SpawnJet", id+AIRSTRIKE_TASK)
	set_task(9.0, "task_Bombing", id+AIRSTRIKE_TASK)
	set_task(9.0, "task_SpawnJet", id+AIRSTRIKE_TASK)
	set_task(10.0, "task_Bombing", id+AIRSTRIKE_TASK)
	
	return PLUGIN_HANDLED
}

public task_ResetStrike()
	g_CalledAirstrikes--
	
public task_SpawnJet(taskid)
{
	taskid-=AIRSTRIKE_TASK
	
	new ent = create_entity("info_target")

	entity_set_model(ent, gAirstrikeJet)
	entity_set_origin(ent, g_flAirOrigin[taskid])
	entity_set_vector(ent, EV_VEC_angles,g_flAirAngles[taskid])
	entity_set_int(ent, EV_INT_solid,SOLID_NOT)
	entity_set_int(ent, EV_INT_movetype,MOVETYPE_FLY)
	entity_set_float(ent, EV_FL_framerate,7.5) //5.0
	entity_set_edict(ent,EV_ENT_owner,taskid)
	
	new player = -1
	while( ( player = engfunc( EngFunc_FindEntityInSphere, player, g_flAirOrigin[taskid], 2500.0 ) ) != 0 )
	{
		if( is_user_alive(player) )
			client_cmd(player, "spk %s", gAirFly[random(sizeof (gAirFly)-1)]);
	}

	set_task(1.0, "task_RemoveJet", ent) //1.5
}

public task_RemoveJet(ent)
	remove_entity(ent)
	
public task_Bombing(taskid)
{
	taskid-=AIRSTRIKE_TASK
	
	new Float:randomlocation[3]
	new randomx, randomy
           
	for (new i=0; i<MAXBOMBS; i++)
	{
		randomx = random_num(-RADIUS,RADIUS)
		randomy = random_num(-RADIUS,RADIUS)
                
		randomlocation[0] = g_flAirOrigin[taskid][0]+1*randomx
		randomlocation[1] = g_flAirOrigin[taskid][1]+1*randomy
		randomlocation[2] = g_flAirOrigin[taskid][2]+25
                
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(3) // TE_EXPLOSION
		engfunc(EngFunc_WriteCoord, randomlocation[0])
		engfunc(EngFunc_WriteCoord, randomlocation[1]) 
		engfunc(EngFunc_WriteCoord, randomlocation[2]) 
		write_short(gSpriteExplosion)
		write_byte(40)
		write_byte(15)
		write_byte(0)
		message_end()
	}
	
	new bool:pattacked[33]
	new player = -1;
	while( ( player = engfunc( EngFunc_FindEntityInSphere, player, g_flAirOrigin[taskid], 450.0 ) ) != 0 )
	{
		if( is_user_alive(player) && get_user_team(player) != get_user_team(taskid))
		{
			Ham_ExecDamageB(player, g_AirstrikeKiller, taskid, 100, HIT_GENERIC, DMG_GENERIC)
			pattacked[player] = true
			if (!is_user_alive(player) && pattacked[player])
			{
				g_KillstreakKills[taskid][KS_AIR]++
				check_killstreaks(taskid, KS_AIR, 1)
				g_Kills[taskid]++
				g_Kills[player] = 0
				
				if ( g_RandMode == TDM && g_Score[TERROR] < g_WinNumber && g_Score[COUNTER] < g_WinNumber)
				{
					switch (cs_get_user_team(taskid))
					{
						case CS_TEAM_T:g_Score[TERROR] += 100
						case CS_TEAM_CT:g_Score[COUNTER] += 100
					}
					update_tdm_hud()
				}
			}
		}
	}
	return PLUGIN_HANDLED
}

public cmdCallPredator(id)
{
	g_NumKillstreaks[id][KS_PRED]++
	check_killstreaks(id, KS_PRED, 0)
	
	new playername[35]
	get_user_name(id,playername,34)
	client_print(0, print_chat, "%s called in by %s", g_KillstreakName[KS_PRED], playername);
	
	new Players[32]
	new playerCount, i
	get_players(Players, playerCount, "c")
	for (i=0; i<playerCount; i++)
	{ 
		if (get_user_team(Players[i]) == get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_PRED][KS_FRIEND])
		else if (get_user_team(Players[i]) != get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_PRED][KS_ENEMY])
	}

	task_Predator(id)
}

public task_Predator(id)
{
	new rocket = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!rocket) return PLUGIN_CONTINUE
	
	// Strings
	set_pev(rocket, pev_classname, gPredatorName)
	engfunc(EngFunc_SetModel, rocket, gPredatorRocket)
	
	// Integer
	set_pev(rocket, pev_owner, id)
	set_pev(rocket, pev_movetype, MOVETYPE_FLY)
	set_pev(rocket, pev_solid, SOLID_BBOX)
	
	// Floats
	set_pev(rocket, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(rocket, pev_maxs, Float:{1.0, 1.0, 1.0})
	
	// Calculate start position and view of the rocket
	new Float:fAim[3], Float:fAngles[3], Float:fOrigin[3]
	velocity_by_aim(id, 64, fAim)
	vector_to_angle(fAim, fAngles)
	pev(id, pev_origin, fOrigin)
	
	fOrigin[0] += fAim[0]
	fOrigin[1] += fAim[1]
	fOrigin[2] += fAim[2]
	
	// Set the origin and view
	set_pev(rocket, pev_origin, fOrigin)
	set_pev(rocket, pev_angles, fAngles)

	// Play fire sound
	//emit_sound(rocket, CHAN_VOICE, gPredEffect, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	//Sets Users Viewmode to the rocket
	engfunc(EngFunc_SetView, id, rocket)
	g_ispredator[id] = true
	
	// Calculate rocket flight speed
	new Float:fVel[3]
	velocity_by_aim(id, ROCKET_SPEED, fVel)	
	set_pev(rocket, pev_velocity, fVel)
	
	// Keep some information about the rocket
	g_UserRocket[id][rocket_entity] = rocket
	g_UserRocket[id][rocket_nreact] = floatround((get_gametime()+REACTION_SPEED)*1000)
	
	// Add trail
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)	// Temp entity type
	write_short(rocket)		// entity
	write_short(g_Trail)	// sprite index
	write_byte(50)	// life time in 0.1's
	write_byte(5)	// line width in 0.1's
	write_byte(ROCKET_TRAIL[0])	// red (RGB)
	write_byte(ROCKET_TRAIL[1])	// green (RGB)
	write_byte(ROCKET_TRAIL[2])	// blue (RGB)
	write_byte(255)	// brightness 0 invisible, 255 visible
	message_end()
	
	return PLUGIN_CONTINUE	
}

public cmdCallEMP(id)
{
	switch(cs_get_user_team(id))
	{
		case CS_TEAM_T:
		{
			g_isemped[TEAM_CT] = true
					
			//if (g_EMPTimer[TEAM_CT]>get_gametime()) g_EMPTimer[TEAM_CT]+=EMP_TIMER
			//else g_EMPTimer[TEAM_CT] = get_gametime()+EMP_TIMER
			
			set_task(EMP_TIMER, "task_RemoveEMP", TEAM_CT+EMPTEAM_TASK)
		}
		case CS_TEAM_CT:
		{
			g_isemped[TEAM_T] = true
					
			//if (g_EMPTimer[TEAM_T]>get_gametime()) g_EMPTimer[TEAM_T]+=EMP_TIMER
			//else g_EMPTimer[TEAM_T] = get_gametime()+EMP_TIMER
			
			set_task(EMP_TIMER, "task_RemoveEMP", TEAM_T+EMPTEAM_TASK)
		}
	}
	
	g_EMPCaller = get_user_team(id)
	g_NumKillstreaks[id][KS_EMP]++
	check_killstreaks(id, KS_EMP, 0)
	
	set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2)
	show_hudmessage(id, "+450");
	g_Experience[id] += 450;
	check_level(id)
	
	new idname[35]
	get_user_name(id,idname,34)
	client_print(0, print_chat, "%s called in by %s", g_KillstreakName[KS_EMP], idname);
	
	client_cmd(0, "spk %s", gEMPEffect);
	
	new Players[32]
	new playerCount, i
	get_players(Players, playerCount, "c")
	for (i=0; i<playerCount; i++)
	{ 
		if (get_user_team(Players[i]) == get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_EMP][KS_FRIEND])
		else if (get_user_team(Players[i]) != get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_EMP][KS_ENEMY])
		task_SetEMPEffects(Players[i])
	}
}

public task_SetEMPEffects(id)
{
	if (g_EMPCaller && get_user_team(id) != g_EMPCaller)
	{
		message_begin(MSG_ONE, gmsgHideWeapon, _, id)
		write_byte(72)
		message_end()
		
		new Float:fadetime, Float:holdtime
		fadetime = EMP_TIMER
		holdtime = EMP_TIMER
			
		new fade, hold;
		fade = clamp(floatround(fadetime * float(1<<12)), 0, 0xFFFF);
		hold = clamp(floatround(holdtime * float(1<<12)), 0, 0xFFFF);
			
		message_begin(MSG_ONE,gmsgScreenFade,{0,0,0},id) 
		write_short( fade ) 
		write_short( hold )
		write_short( 1<<12 )
		write_byte( 255 ) 
		write_byte( 255 ) 
		write_byte( 255 ) 
		write_byte( 75 ) 
		message_end()
	}
	else
	{
		message_begin(MSG_ONE,gmsgScreenFade,{0,0,0},id) 
		write_short( 1<<12 ) 
		write_short( 1<<10 )
		write_short( 1<<12 )
		write_byte( 255 ) 
		write_byte( 255 ) 
		write_byte( 255 ) 
		write_byte( 195 ) 
		message_end()	
	}
}

public task_RemoveEMP(taskteam)
{
	taskteam-=EMPTEAM_TASK
	
	g_isemped[taskteam] = false
	g_EMPCaller = 0
	
	message_begin(MSG_BROADCAST, gmsgHideWeapon)
	write_byte(0)
	message_end()
	
	message_begin(MSG_BROADCAST,gmsgScreenFade) 
	write_short( 1<<12 ) 
	write_short( 1<<10 )
	write_short( 1<<12 )
	write_byte( 255 ) 
	write_byte( 255 ) 
	write_byte( 255 ) 
	write_byte( 0 ) 
	message_end()	
}

public cmdCallNuke(id)
{
	g_NumKillstreaks[id][KS_NUKE]++
	check_killstreaks(id, KS_NUKE, 0)
	
	set_hudmessage(240, 240, 0, -1.0, 0.40, 0, 0.1, 2.5, 0.02, 0.02, 2)
	show_hudmessage(id, "+1000");
	g_Experience[id] += 1000;
	check_level(id)
	
	new idname[35]
	get_user_name(id,idname,34)
	client_print(0, print_chat, "%s called in by %s", g_KillstreakName[KS_NUKE], idname);
	
	set_task(1.0, "task_Countdown", id+NUKE_TASK,_,_,"a", 11);
	set_task(1.0, "task_NukeSounds", id+NUKEKILL_TASK);


}

public task_NukeSounds(id)
{
	id-=NUKEKILL_TASK
	
	new Players[32]
	new playerCount, i
	get_players(Players, playerCount, "c")
	for (i=0; i<playerCount; i++)
	{ 
		if (get_user_team(Players[i]) == get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_NUKE][KS_FRIEND])
		else if (get_user_team(Players[i]) != get_user_team(id)) client_cmd(Players[i], "spk %s", gKillstreakSounds[KS_NUKE][KS_ENEMY])
	}
}

public task_Countdown(id)
{
	id-=NUKE_TASK
	timer --
	set_hudmessage(255, 0, 0, -1.0, 0.45, 0, 0.0, 1.0, 0.1, 0.2, 1)
	show_hudmessage(0, "%d:%02d", timer/60, timer%60)
	
	if(timer < 1)
	{
		timer = 11
		
		new Float:fadetime, Float:holdtime
		fadetime = 10.0
		holdtime = 3.0
			
		new fade, hold
		fade = clamp(floatround(fadetime * float(1<<12)), 0, 0xFFFF);
		hold = clamp(floatround(holdtime * float(1<<12)), 0, 0xFFFF);
			
		message_begin(MSG_ALL,gmsgScreenFade,{0,0,0},id) 
		write_short( fade ) 
		write_short( hold )
		write_short( 0x0000 )
		write_byte( 255 ) 
		write_byte( 255 ) 
		write_byte( 255 ) 
		write_byte( 195 ) 
		message_end()	
		
		remove_task(id+NUKE_TASK)
		
		set_task(1.0, "task_NukeKillDelay", id+NUKEKILL_TASK)
		set_task(3.0, "task_NukeWinDelay", id+NUKEKILL_TASK)
	}
}  

public task_NukeKillDelay(id)
{
	id-=NUKEKILL_TASK
	
	new Float: flOrigin
	pev(id, pev_origin, flOrigin)
	
	new player = -1, pattacked[33]
	while( ( player = engfunc( EngFunc_FindEntityInSphere, player, flOrigin, 8192.0 ) ) != 0)
	{
		if (get_user_team(player) != get_user_team(id))
		{
			if( is_user_alive(player))
			{
				Ham_ExecDamageB(player, g_NukeKiller, id, 1000, HIT_GENERIC, DMG_GENERIC)
				pattacked[player] = true
			}
				
			if( !is_user_alive(player))
			{
				if (pattacked[player])
				{
					g_Kills[player] = 0
					g_KillstreakKills[id][KS_NUKE]++
					check_killstreaks(id, KS_NUKE, 1)
				}
			}
		}
	}
	check_level(id)
	
	switch(cs_get_user_team(id))
	{
		case CS_TEAM_T:
		{
			message_begin( MSG_BROADCAST, gmsgTextMsg );
			write_byte( 1 );
			write_string( "#Terrorists_Win" );
			message_end( );	
		}
		case CS_TEAM_CT:
		{
			message_begin( MSG_BROADCAST, gmsgTextMsg );
			write_byte( 1 );
			write_string( "#CTs_Win" );
			message_end( );	
		}
	}
}

public task_NukeWinDelay(id)
{
	id-=NUKEKILL_TASK
	
	switch(cs_get_user_team(id))
	{
		case CS_TEAM_T: TerminateRound( RoundEndType_TeamExtermination, TeamWinning_Terrorist, MapType_AutoDetect );
		case CS_TEAM_CT: TerminateRound( RoundEndType_TeamExtermination, TeamWinning_Ct, MapType_AutoDetect );
	}
}

/*------------------------------------------------------------------------------------------------*/

stock Ham_ExecDamageB(victim, inflictor, attacker, damage, hitgroup, bits)
{
	damage*=1.0
	set_pdata_int(victim, 75, hitgroup, 5)
	ExecuteHamB(Ham_TakeDamage, victim, inflictor, attacker, damage, bits)
} 

public task_RadarScanner(taskid)
{
	if ( get_playersnum() > 24 ) return;
	
	new CsTeams:teamid
	switch(taskid)
	{
		case UAVTERROR_TASK:
		{
			if ( !g_HasUAV[TEAM_T] || g_isemped[0] || g_UAVTimer[TEAM_T] < get_gametime() ) return;
			teamid = CS_TEAM_T
		}
		case UAVCOUNTER_TASK:
		{
			if ( !g_HasUAV[TEAM_CT] || g_isemped[1] || g_UAVTimer[TEAM_CT] < get_gametime() ) return;
			teamid = CS_TEAM_CT
		}
	}
	
	new Players[32]
	new playerCount, id
	get_players(Players, playerCount, "ac")
	for (new x=0; x<playerCount; x++)
	{
		id = Players[x]
		if (g_isalive[id] && cs_get_user_team(id) == teamid)
		{
			for( new enemy=0; enemy<=g_MaxPlayers; enemy++ )
			{
				if( get_user_team(id) != get_user_team(enemy) && g_isalive[enemy] && g_Perk[enemy][1] != PRK2_COLDB)
				{
					message_begin(MSG_ONE_UNRELIABLE, gmsgHostageAdd, {0,0,0}, id)
					write_byte(id)
					write_byte(enemy)		
					engfunc(EngFunc_WriteCoord, g_flLocation[enemy][0]);
					engfunc(EngFunc_WriteCoord, g_flLocation[enemy][1]);
					engfunc(EngFunc_WriteCoord, g_flLocation[enemy][2]);
					message_end()
				
					message_begin(MSG_ONE_UNRELIABLE, gmsgHostageDel, {0,0,0}, id)
					write_byte(enemy)
					message_end()
				}
			}
		}
	}
}

ManageBar(id, bartime)
{
	message_begin(MSG_ONE_UNRELIABLE, gmsgBarTime, _, id);
	write_short(bartime);
	message_end();
}

public get_load_key(id)
{
	switch(g_iSaveType)
	{
		case 0:
		{
			get_user_ip(id, g_AuthID[id], charsmax(g_AuthID[]));
			return 1;
		}
		case 1:
		{
			new szAuthID[35]
			get_user_authid(id, szAuthID, charsmax(szAuthID));
			if ( equal(szAuthID[9], "PENDING") || szAuthID[0] == '^0' ) 
			{
				// Try to get a vaild key again in 5 seconds
				set_task(5.0, "get_load_key", id+XPLOAD_TASK);
				return 0;
			}
			else
			{
				format(g_AuthID[id], charsmax(g_AuthID[]), szAuthID)
				LoadLevel(id);
				return 1;
			}
		}
	}
	return 0;
}

LoadLevel(id)
{
	new szData[1024];
	new szKey[64];
	
	new chal[31][2][3], stats[31][2][8]

	//Base Mod Saves
	formatex( szKey , 63 , "%s-MAIN", g_AuthID[id]);
	formatex( szData , 1023, "%i %i %i %i %i %i", g_Prestige[id], g_Experience[id], g_ChallangeCounter[ASSAULT][id],
	g_ChallangeCounter[SMG][id], g_ChallangeCounter[OTHER][id], g_ChallangeCounter[PISTOL][id]);
	
	nvault_get(g_Vault, szKey, szData, 1023) 
	
	new pres[32], exp[32], cou[4][4]
	parse(szData, pres, 31, exp, 31, cou[ASSAULT], 3, cou[SMG], 3, cou[OTHER], 3, cou[PISTOL], 3) 
	
	g_Prestige[id]				 = str_to_num(pres)
	g_Experience[id]			 = str_to_num(exp)
	g_ChallangeCounter[ASSAULT][id]		 = str_to_num(cou[ASSAULT])
	g_ChallangeCounter[SMG][id]		 = str_to_num(cou[SMG])
	g_ChallangeCounter[OTHER][id]		 = str_to_num(cou[OTHER])
	g_ChallangeCounter[PISTOL][id]		 = str_to_num(cou[PISTOL])

	/*----------------------------------------------------------------------------------------*/
	
	formatex( szKey , 63 , "%s-Classes", g_AuthID[id]);
	formatex( szData , 1023, "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i", 
	g_CustomPerk[id][0][CUSTOM1], g_CustomPerk[id][1][CUSTOM1], g_CustomPerk[id][2][CUSTOM1], g_CustomEquiptment[id][CUSTOM1], g_CustomWeapon[PRIMARY][id][CUSTOM1], g_CustomWeapon[SECONDARY][id][CUSTOM1],
	g_CustomPerk[id][0][CUSTOM2], g_CustomPerk[id][1][CUSTOM2], g_CustomPerk[id][2][CUSTOM2], g_CustomEquiptment[id][CUSTOM2], g_CustomWeapon[PRIMARY][id][CUSTOM2], g_CustomWeapon[SECONDARY][id][CUSTOM2],
	g_CustomPerk[id][0][CUSTOM3], g_CustomPerk[id][1][CUSTOM3], g_CustomPerk[id][2][CUSTOM3], g_CustomEquiptment[id][CUSTOM3], g_CustomWeapon[PRIMARY][id][CUSTOM3], g_CustomWeapon[SECONDARY][id][CUSTOM3],
	g_CustomPerk[id][0][CUSTOM4], g_CustomPerk[id][1][CUSTOM4], g_CustomPerk[id][2][CUSTOM4], g_CustomEquiptment[id][CUSTOM4], g_CustomWeapon[PRIMARY][id][CUSTOM4], g_CustomWeapon[SECONDARY][id][CUSTOM4],
	g_CustomPerk[id][0][CUSTOM5], g_CustomPerk[id][1][CUSTOM5], g_CustomPerk[id][2][CUSTOM5], g_CustomEquiptment[id][CUSTOM5], g_CustomWeapon[PRIMARY][id][CUSTOM5], g_CustomWeapon[SECONDARY][id][CUSTOM5],
	g_CustomPerk[id][0][CUSTOM6], g_CustomPerk[id][1][CUSTOM6], g_CustomPerk[id][2][CUSTOM6], g_CustomEquiptment[id][CUSTOM6], g_CustomWeapon[PRIMARY][id][CUSTOM6], g_CustomWeapon[SECONDARY][id][CUSTOM6]);

	nvault_get(g_Vault, szKey, szData, 1023) 
	
	new cperk[3][7][4], equi[7][2], wep[2][7][5]
	parse(szData, 	cperk[0][CUSTOM1], 3, cperk[1][CUSTOM1], 3, cperk[2][CUSTOM1], 3, equi[CUSTOM1], 1, wep[0][CUSTOM1], 4, wep[1][CUSTOM1], 4,
			cperk[0][CUSTOM2], 3, cperk[1][CUSTOM2], 3, cperk[2][CUSTOM2], 3, equi[CUSTOM2], 1, wep[0][CUSTOM2], 4, wep[1][CUSTOM2], 4,
			cperk[0][CUSTOM3], 3, cperk[1][CUSTOM3], 3, cperk[2][CUSTOM3], 3, equi[CUSTOM3], 1, wep[0][CUSTOM3], 4, wep[1][CUSTOM3], 4,
			cperk[0][CUSTOM4], 3, cperk[1][CUSTOM4], 3, cperk[2][CUSTOM4], 3, equi[CUSTOM4], 1, wep[0][CUSTOM4], 4, wep[1][CUSTOM4], 4,
			cperk[0][CUSTOM5], 3, cperk[1][CUSTOM5], 3, cperk[2][CUSTOM5], 3, equi[CUSTOM5], 1, wep[0][CUSTOM5], 4, wep[1][CUSTOM5], 4,
			cperk[0][CUSTOM6], 3, cperk[1][CUSTOM6], 3, cperk[2][CUSTOM6], 3, equi[CUSTOM6], 1, wep[0][CUSTOM6], 4, wep[1][CUSTOM6], 4); 
	
	g_CustomPerk[id][0][CUSTOM1] 		= str_to_num(cperk[0][CUSTOM1])
	g_CustomPerk[id][1][CUSTOM1] 		= str_to_num(cperk[1][CUSTOM1])
	g_CustomPerk[id][2][CUSTOM1] 		= str_to_num(cperk[2][CUSTOM1])
	g_CustomEquiptment[id][CUSTOM1] 		= str_to_num(equi[CUSTOM1])
	g_CustomWeapon[PRIMARY][id][CUSTOM1] 	= str_to_num(wep[0][CUSTOM1])
	g_CustomWeapon[SECONDARY][id][CUSTOM1]	= str_to_num(wep[1][CUSTOM1])
	
	g_CustomPerk[id][0][CUSTOM2] 		= str_to_num(cperk[0][CUSTOM2])
	g_CustomPerk[id][1][CUSTOM2] 		= str_to_num(cperk[1][CUSTOM2])
	g_CustomPerk[id][2][CUSTOM2] 		= str_to_num(cperk[2][CUSTOM2])
	g_CustomEquiptment[id][CUSTOM2] 		= str_to_num(equi[CUSTOM2])
	g_CustomWeapon[PRIMARY][id][CUSTOM2] 	= str_to_num(wep[0][CUSTOM2])
	g_CustomWeapon[SECONDARY][id][CUSTOM2]	= str_to_num(wep[1][CUSTOM2])
	
	g_CustomPerk[id][0][CUSTOM3] 		= str_to_num(cperk[0][CUSTOM3])
	g_CustomPerk[id][1][CUSTOM3] 		= str_to_num(cperk[1][CUSTOM3])
	g_CustomPerk[id][2][CUSTOM3] 		= str_to_num(cperk[2][CUSTOM3])
	g_CustomEquiptment[id][CUSTOM3]	 	= str_to_num(equi[CUSTOM3])
	g_CustomWeapon[PRIMARY][id][CUSTOM3] 	= str_to_num(wep[0][CUSTOM3])
	g_CustomWeapon[SECONDARY][id][CUSTOM3]	= str_to_num(wep[1][CUSTOM3])
	
	g_CustomPerk[id][0][CUSTOM4] 		= str_to_num(cperk[0][CUSTOM4])
	g_CustomPerk[id][1][CUSTOM4] 		= str_to_num(cperk[1][CUSTOM4])
	g_CustomPerk[id][2][CUSTOM4] 		= str_to_num(cperk[2][CUSTOM4])
	g_CustomEquiptment[id][CUSTOM4] 		= str_to_num(equi[CUSTOM4])
	g_CustomWeapon[PRIMARY][id][CUSTOM4] 	= str_to_num(wep[0][CUSTOM4])
	g_CustomWeapon[SECONDARY][id][CUSTOM4]	= str_to_num(wep[1][CUSTOM4])
	
	g_CustomPerk[id][0][CUSTOM5]		= str_to_num(cperk[0][CUSTOM5])
	g_CustomPerk[id][1][CUSTOM5] 		= str_to_num(cperk[1][CUSTOM5])
	g_CustomPerk[id][2][CUSTOM5] 		= str_to_num(cperk[2][CUSTOM5])
	g_CustomEquiptment[id][CUSTOM5] 		= str_to_num(equi[CUSTOM5])
	g_CustomWeapon[PRIMARY][id][CUSTOM5] 	= str_to_num(wep[0][CUSTOM5])
	g_CustomWeapon[SECONDARY][id][CUSTOM5]	= str_to_num(wep[1][CUSTOM5])
	
	g_CustomPerk[id][0][CUSTOM6]		= str_to_num(cperk[0][CUSTOM6])
	g_CustomPerk[id][1][CUSTOM6] 		= str_to_num(cperk[1][CUSTOM6])
	g_CustomPerk[id][2][CUSTOM6] 		= str_to_num(cperk[2][CUSTOM6])
	g_CustomEquiptment[id][CUSTOM6] 		= str_to_num(equi[CUSTOM6])
	g_CustomWeapon[PRIMARY][id][CUSTOM6] 	= str_to_num(wep[0][CUSTOM6])
	g_CustomWeapon[SECONDARY][id][CUSTOM6]	= str_to_num(wep[1][CUSTOM6])
	
	/*----------------------------------------------------------------------------------------*/
	
	//Weapon Challange Save
	formatex(szKey,63,"%s-ID-WepChal-1",g_AuthID[id])
	formatex( szData , 1023, "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
	g_PlayerChallenges[id][MARKSMAN][1], g_PlayerChallenges[id][ELITE][1], g_GunStats[id][GUN_KILLS][1], g_GunStats[id][GUN_HEADSHOTS][1],
	g_PlayerChallenges[id][MARKSMAN][2], g_PlayerChallenges[id][ELITE][2], g_GunStats[id][GUN_KILLS][2], g_GunStats[id][GUN_HEADSHOTS][2],
	g_PlayerChallenges[id][MARKSMAN][3], g_PlayerChallenges[id][ELITE][3], g_GunStats[id][GUN_KILLS][3], g_GunStats[id][GUN_HEADSHOTS][3],
	g_PlayerChallenges[id][MARKSMAN][4], g_PlayerChallenges[id][ELITE][4], g_GunStats[id][GUN_KILLS][4], g_GunStats[id][GUN_HEADSHOTS][4],
	g_PlayerChallenges[id][MARKSMAN][5], g_PlayerChallenges[id][ELITE][5], g_GunStats[id][GUN_KILLS][5], g_GunStats[id][GUN_HEADSHOTS][5],
	g_PlayerChallenges[id][MARKSMAN][6], g_PlayerChallenges[id][ELITE][6], g_GunStats[id][GUN_KILLS][6], g_GunStats[id][GUN_HEADSHOTS][6],
	g_PlayerChallenges[id][MARKSMAN][7], g_PlayerChallenges[id][ELITE][7], g_GunStats[id][GUN_KILLS][7], g_GunStats[id][GUN_HEADSHOTS][7],
	g_PlayerChallenges[id][MARKSMAN][8], g_PlayerChallenges[id][ELITE][8], g_GunStats[id][GUN_KILLS][8], g_GunStats[id][GUN_HEADSHOTS][8],
	g_PlayerChallenges[id][MARKSMAN][9], g_PlayerChallenges[id][ELITE][9], g_GunStats[id][GUN_KILLS][9], g_GunStats[id][GUN_HEADSHOTS][9],
	g_PlayerChallenges[id][MARKSMAN][10], g_PlayerChallenges[id][ELITE][10], g_GunStats[id][GUN_KILLS][10], g_GunStats[id][GUN_HEADSHOTS][10]);
	
	nvault_get(g_Vault, szKey, szData, 1023);
	
	parse(szData, 	chal[1][0], 2, chal[1][1], 2, stats[1][0], 7, stats[1][1], 7,
			chal[2][0], 2, chal[2][1], 2, stats[2][0], 7, stats[2][1], 7,
			chal[3][0], 2, chal[3][1], 2, stats[3][0], 7, stats[3][1], 7,
			chal[4][0], 2, chal[4][1], 2, stats[4][0], 7, stats[4][1], 7,
			chal[5][0], 2, chal[5][1], 2, stats[5][0], 7, stats[5][1], 7,
			chal[6][0], 2, chal[6][1], 2, stats[6][0], 7, stats[6][1], 7,
			chal[7][0], 2, chal[7][1], 2, stats[7][0], 7, stats[7][1], 7,
			chal[8][0], 2, chal[8][1], 2, stats[8][0], 7, stats[8][1], 7,
			chal[9][0], 2, chal[9][1], 2, stats[9][0], 7, stats[9][1], 7,
			chal[10][0], 2, chal[10][1], 2, stats[10][0], 7, stats[10][1], 7);
	
	g_PlayerChallenges[id][MARKSMAN][1]	 = str_to_num(chal[1][0])
	g_PlayerChallenges[id][ELITE][1]	 = str_to_num(chal[1][1])
	g_GunStats[id][GUN_KILLS][1]		 = str_to_num(stats[1][0])
	g_GunStats[id][GUN_HEADSHOTS][1]	 = str_to_num(stats[1][1])
	
	g_PlayerChallenges[id][MARKSMAN][2]	 = str_to_num(chal[2][0])
	g_PlayerChallenges[id][ELITE][2]	 = str_to_num(chal[2][1])
	g_GunStats[id][GUN_KILLS][2]		 = str_to_num(stats[2][0])
	g_GunStats[id][GUN_HEADSHOTS][2]	 = str_to_num(stats[2][1])
	
	g_PlayerChallenges[id][MARKSMAN][3]	 = str_to_num(chal[3][0])
	g_PlayerChallenges[id][ELITE][3]	 = str_to_num(chal[3][1])
	g_GunStats[id][GUN_KILLS][3]		 = str_to_num(stats[3][0])
	g_GunStats[id][GUN_HEADSHOTS][3]	 = str_to_num(stats[3][1])
	
	g_PlayerChallenges[id][MARKSMAN][4]	 = str_to_num(chal[4][0])
	g_PlayerChallenges[id][ELITE][4]	 = str_to_num(chal[4][1])
	g_GunStats[id][GUN_KILLS][4]		 = str_to_num(stats[4][0])
	g_GunStats[id][GUN_HEADSHOTS][4]	 = str_to_num(stats[4][1])
	
	g_PlayerChallenges[id][MARKSMAN][5]	 = str_to_num(chal[5][0])
	g_PlayerChallenges[id][ELITE][5]	 = str_to_num(chal[5][1])
	g_GunStats[id][GUN_KILLS][5]		 = str_to_num(stats[5][0])
	g_GunStats[id][GUN_HEADSHOTS][5]	 = str_to_num(stats[5][1])
	
	g_PlayerChallenges[id][MARKSMAN][6]	 = str_to_num(chal[6][0])
	g_PlayerChallenges[id][ELITE][6]	 = str_to_num(chal[6][1])
	g_GunStats[id][GUN_KILLS][6]		 = str_to_num(stats[6][0])
	g_GunStats[id][GUN_HEADSHOTS][6]	 = str_to_num(stats[6][1])
	
	g_PlayerChallenges[id][MARKSMAN][7]	 = str_to_num(chal[7][0])
	g_PlayerChallenges[id][ELITE][7]	 = str_to_num(chal[7][1])
	g_GunStats[id][GUN_KILLS][7]		 = str_to_num(stats[7][0])
	g_GunStats[id][GUN_HEADSHOTS][7]	 = str_to_num(stats[7][1])
	
	g_PlayerChallenges[id][MARKSMAN][8]	 = str_to_num(chal[8][0])
	g_PlayerChallenges[id][ELITE][8]	 = str_to_num(chal[8][1])
	g_GunStats[id][GUN_KILLS][8]		 = str_to_num(stats[8][0])
	g_GunStats[id][GUN_HEADSHOTS][8]	 = str_to_num(stats[8][1])
	
	g_PlayerChallenges[id][MARKSMAN][9]	 = str_to_num(chal[9][0])
	g_PlayerChallenges[id][ELITE][9]	 = str_to_num(chal[9][1])
	g_GunStats[id][GUN_KILLS][9]		 = str_to_num(stats[9][0])
	g_GunStats[id][GUN_HEADSHOTS][9]	 = str_to_num(stats[9][1])
	
	g_PlayerChallenges[id][MARKSMAN][10]	 = str_to_num(chal[10][0])
	g_PlayerChallenges[id][ELITE][10]	 = str_to_num(chal[10][1])
	g_GunStats[id][GUN_KILLS][10]		 = str_to_num(stats[10][0])
	g_GunStats[id][GUN_HEADSHOTS][10]	 = str_to_num(stats[10][1])
		
	/*----------------------------------------------------------------------------------------*/
		
	formatex(szKey,63,"%s-ID-WepChal-2",g_AuthID[id])
	formatex( szData , 1023, "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
	g_PlayerChallenges[id][MARKSMAN][11], g_PlayerChallenges[id][ELITE][11], g_GunStats[id][GUN_KILLS][11], g_GunStats[id][GUN_HEADSHOTS][11],
	g_PlayerChallenges[id][MARKSMAN][12], g_PlayerChallenges[id][ELITE][12], g_GunStats[id][GUN_KILLS][12], g_GunStats[id][GUN_HEADSHOTS][12],
	g_PlayerChallenges[id][MARKSMAN][13], g_PlayerChallenges[id][ELITE][13], g_GunStats[id][GUN_KILLS][13], g_GunStats[id][GUN_HEADSHOTS][13],
	g_PlayerChallenges[id][MARKSMAN][14], g_PlayerChallenges[id][ELITE][14], g_GunStats[id][GUN_KILLS][14], g_GunStats[id][GUN_HEADSHOTS][14],
	g_PlayerChallenges[id][MARKSMAN][15], g_PlayerChallenges[id][ELITE][15], g_GunStats[id][GUN_KILLS][15], g_GunStats[id][GUN_HEADSHOTS][15],
	g_PlayerChallenges[id][MARKSMAN][16], g_PlayerChallenges[id][ELITE][16], g_GunStats[id][GUN_KILLS][16], g_GunStats[id][GUN_HEADSHOTS][16],
	g_PlayerChallenges[id][MARKSMAN][17], g_PlayerChallenges[id][ELITE][17], g_GunStats[id][GUN_KILLS][17], g_GunStats[id][GUN_HEADSHOTS][17],
	g_PlayerChallenges[id][MARKSMAN][18], g_PlayerChallenges[id][ELITE][18], g_GunStats[id][GUN_KILLS][18], g_GunStats[id][GUN_HEADSHOTS][18],
	g_PlayerChallenges[id][MARKSMAN][19], g_PlayerChallenges[id][ELITE][19], g_GunStats[id][GUN_KILLS][19], g_GunStats[id][GUN_HEADSHOTS][19],
	g_PlayerChallenges[id][MARKSMAN][20], g_PlayerChallenges[id][ELITE][20], g_GunStats[id][GUN_KILLS][20], g_GunStats[id][GUN_HEADSHOTS][20]);

	nvault_get(g_Vault, szKey, szData, 1023);
	 
	parse(szData, 	chal[11][0], 2, chal[11][1], 2, stats[11][0], 7, stats[11][1], 7,
			chal[12][0], 2, chal[12][1], 2, stats[12][0], 7, stats[12][1], 7,
			chal[13][0], 2, chal[13][1], 2, stats[13][0], 7, stats[13][1], 7,
			chal[14][0], 2, chal[14][1], 2, stats[14][0], 7, stats[14][1], 7,
			chal[15][0], 2, chal[15][1], 2, stats[15][0], 7, stats[15][1], 7,
			chal[16][0], 2, chal[16][1], 2, stats[16][0], 7, stats[16][1], 7,
			chal[17][0], 2, chal[17][1], 2, stats[17][0], 7, stats[17][1], 7,
			chal[18][0], 2, chal[18][1], 2, stats[18][0], 7, stats[18][1], 7,
			chal[19][0], 2, chal[19][1], 2, stats[19][0], 7, stats[19][1], 7,
			chal[20][0], 2, chal[20][1], 2, stats[20][0], 7, stats[20][1], 7);
			
	g_PlayerChallenges[id][MARKSMAN][11]	 = str_to_num(chal[11][0])
	g_PlayerChallenges[id][ELITE][11]	 = str_to_num(chal[11][1])
	g_GunStats[id][GUN_KILLS][11]		 = str_to_num(stats[11][0])
	g_GunStats[id][GUN_HEADSHOTS][11]	 = str_to_num(stats[11][1])
	
	g_PlayerChallenges[id][MARKSMAN][12]	 = str_to_num(chal[12][0])
	g_PlayerChallenges[id][ELITE][12]	 = str_to_num(chal[12][1])
	g_GunStats[id][GUN_KILLS][12]		 = str_to_num(stats[12][0])
	g_GunStats[id][GUN_HEADSHOTS][12]	 = str_to_num(stats[12][1])
	
	g_PlayerChallenges[id][MARKSMAN][13]	 = str_to_num(chal[13][0])
	g_PlayerChallenges[id][ELITE][13]	 = str_to_num(chal[13][1])
	g_GunStats[id][GUN_KILLS][13]		 = str_to_num(stats[13][0])
	g_GunStats[id][GUN_HEADSHOTS][13]	 = str_to_num(stats[13][1])
	
	g_PlayerChallenges[id][MARKSMAN][14]	 = str_to_num(chal[14][0])
	g_PlayerChallenges[id][ELITE][14]	 = str_to_num(chal[14][1])
	g_GunStats[id][GUN_KILLS][14]		 = str_to_num(stats[14][0])
	g_GunStats[id][GUN_HEADSHOTS][14]	 = str_to_num(stats[14][1])
	
	g_PlayerChallenges[id][MARKSMAN][15] 	 = str_to_num(chal[15][0])
	g_PlayerChallenges[id][ELITE][15]	 = str_to_num(chal[15][1])
	g_GunStats[id][GUN_KILLS][15]		 = str_to_num(stats[15][0])
	g_GunStats[id][GUN_HEADSHOTS][15]	 = str_to_num(stats[15][1])
	
	g_PlayerChallenges[id][MARKSMAN][16]	 = str_to_num(chal[16][0])
	g_PlayerChallenges[id][ELITE][16]	 = str_to_num(chal[16][1])
	g_GunStats[id][GUN_KILLS][16]		 = str_to_num(stats[16][0])
	g_GunStats[id][GUN_HEADSHOTS][16]	 = str_to_num(stats[16][1])
	
	g_PlayerChallenges[id][MARKSMAN][17]	 = str_to_num(chal[17][0])
	g_PlayerChallenges[id][ELITE][17]	 = str_to_num(chal[17][1])
	g_GunStats[id][GUN_KILLS][17]		 = str_to_num(stats[17][0])
	g_GunStats[id][GUN_HEADSHOTS][17]	 = str_to_num(stats[17][1])
	
	g_PlayerChallenges[id][MARKSMAN][18]	 = str_to_num(chal[18][0])
	g_PlayerChallenges[id][ELITE][18]	 = str_to_num(chal[18][1])
	g_GunStats[id][GUN_KILLS][18]		 = str_to_num(stats[18][0])
	g_GunStats[id][GUN_HEADSHOTS][18]	 = str_to_num(stats[18][1])
	
	g_PlayerChallenges[id][MARKSMAN][19]	 = str_to_num(chal[19][0])
	g_PlayerChallenges[id][ELITE][19]	 = str_to_num(chal[19][1])
	g_GunStats[id][GUN_KILLS][19]		 = str_to_num(stats[19][0])
	g_GunStats[id][GUN_HEADSHOTS][19]	 = str_to_num(stats[19][1])
	
	g_PlayerChallenges[id][MARKSMAN][20]	 = str_to_num(chal[20][0])
	g_PlayerChallenges[id][ELITE][20]	 = str_to_num(chal[20][1])
	g_GunStats[id][GUN_KILLS][20]		 = str_to_num(stats[20][0])
	g_GunStats[id][GUN_HEADSHOTS][20]	 = str_to_num(stats[20][1])
	
	/*----------------------------------------------------------------------------------------*/
	
	formatex(szKey,63,"%s-ID-WepChal-3",g_AuthID[id])
	formatex( szData , 1023, "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
	g_PlayerChallenges[id][MARKSMAN][21], g_PlayerChallenges[id][ELITE][21], g_GunStats[id][GUN_KILLS][21], g_GunStats[id][GUN_HEADSHOTS][21],
	g_PlayerChallenges[id][MARKSMAN][22], g_PlayerChallenges[id][ELITE][22], g_GunStats[id][GUN_KILLS][22], g_GunStats[id][GUN_HEADSHOTS][22],
	g_PlayerChallenges[id][MARKSMAN][23], g_PlayerChallenges[id][ELITE][23], g_GunStats[id][GUN_KILLS][23], g_GunStats[id][GUN_HEADSHOTS][23],
	g_PlayerChallenges[id][MARKSMAN][24], g_PlayerChallenges[id][ELITE][24], g_GunStats[id][GUN_KILLS][24], g_GunStats[id][GUN_HEADSHOTS][24],
	g_PlayerChallenges[id][MARKSMAN][25], g_PlayerChallenges[id][ELITE][25], g_GunStats[id][GUN_KILLS][25], g_GunStats[id][GUN_HEADSHOTS][25],
	g_PlayerChallenges[id][MARKSMAN][26], g_PlayerChallenges[id][ELITE][26], g_GunStats[id][GUN_KILLS][26], g_GunStats[id][GUN_HEADSHOTS][26],
	g_PlayerChallenges[id][MARKSMAN][27], g_PlayerChallenges[id][ELITE][27], g_GunStats[id][GUN_KILLS][27], g_GunStats[id][GUN_HEADSHOTS][27],
	g_PlayerChallenges[id][MARKSMAN][28], g_PlayerChallenges[id][ELITE][28], g_GunStats[id][GUN_KILLS][28], g_GunStats[id][GUN_HEADSHOTS][28],
	g_PlayerChallenges[id][MARKSMAN][29], g_PlayerChallenges[id][ELITE][29], g_GunStats[id][GUN_KILLS][29], g_GunStats[id][GUN_HEADSHOTS][29],
	g_PlayerChallenges[id][MARKSMAN][30], g_PlayerChallenges[id][ELITE][30], g_GunStats[id][GUN_KILLS][30], g_GunStats[id][GUN_HEADSHOTS][30]);

	nvault_get(g_Vault, szKey, szData, 1023);
	 
	parse(szData, 	chal[21][0], 2, chal[21][1], 2, stats[21][0], 7, stats[21][1], 7,
			chal[22][0], 2, chal[22][1], 2, stats[22][0], 7, stats[22][1], 7,
			chal[23][0], 2, chal[23][1], 2, stats[23][0], 7, stats[23][1], 7,
			chal[24][0], 2, chal[24][1], 2, stats[24][0], 7, stats[24][1], 7,
			chal[25][0], 2, chal[25][1], 2, stats[25][0], 7, stats[25][1], 7,
			chal[26][0], 2, chal[26][1], 2, stats[26][0], 7, stats[26][1], 7,
			chal[27][0], 2, chal[27][1], 2, stats[27][0], 7, stats[27][1], 7,
			chal[28][0], 2, chal[28][1], 2, stats[28][0], 7, stats[28][1], 7,
			chal[29][0], 2, chal[29][1], 2, stats[29][0], 7, stats[29][1], 7,
			chal[30][0], 2, chal[30][1], 2, stats[30][0], 7, stats[30][1], 7);
			
	g_PlayerChallenges[id][MARKSMAN][21]	 = str_to_num(chal[21][0])
	g_PlayerChallenges[id][ELITE][21]	 = str_to_num(chal[21][1])
	g_GunStats[id][GUN_KILLS][21]		 = str_to_num(stats[21][0])
	g_GunStats[id][GUN_HEADSHOTS][21]	 = str_to_num(stats[21][1])
	
	g_PlayerChallenges[id][MARKSMAN][22]	 = str_to_num(chal[22][0])
	g_PlayerChallenges[id][ELITE][22]	 = str_to_num(chal[22][1])
	g_GunStats[id][GUN_KILLS][22]		 = str_to_num(stats[22][0])
	g_GunStats[id][GUN_HEADSHOTS][22]	 = str_to_num(stats[22][1])
	
	g_PlayerChallenges[id][MARKSMAN][23]	 = str_to_num(chal[23][0])
	g_PlayerChallenges[id][ELITE][23]	 = str_to_num(chal[23][1])
	g_GunStats[id][GUN_KILLS][23]		 = str_to_num(stats[23][0])
	g_GunStats[id][GUN_HEADSHOTS][23]	 = str_to_num(stats[23][1])
	
	g_PlayerChallenges[id][MARKSMAN][24]	 = str_to_num(chal[24][0])
	g_PlayerChallenges[id][ELITE][24]	 = str_to_num(chal[24][1])
	g_GunStats[id][GUN_KILLS][24]		 = str_to_num(stats[24][0])
	g_GunStats[id][GUN_HEADSHOTS][24]	 = str_to_num(stats[24][1])
	
	g_PlayerChallenges[id][MARKSMAN][25]	 = str_to_num(chal[25][0])
	g_PlayerChallenges[id][ELITE][25]	 = str_to_num(chal[25][1])
	g_GunStats[id][GUN_KILLS][25]		 = str_to_num(stats[25][0])
	g_GunStats[id][GUN_HEADSHOTS][25]	 = str_to_num(stats[25][1])
	
	g_PlayerChallenges[id][MARKSMAN][26]	 = str_to_num(chal[26][0])
	g_PlayerChallenges[id][ELITE][26]	 = str_to_num(chal[26][1])
	g_GunStats[id][GUN_KILLS][26]		 = str_to_num(stats[26][0])
	g_GunStats[id][GUN_HEADSHOTS][26]	 = str_to_num(stats[26][1])
	
	g_PlayerChallenges[id][MARKSMAN][27]	 = str_to_num(chal[27][0])
	g_PlayerChallenges[id][ELITE][27]	 = str_to_num(chal[27][1])
	g_GunStats[id][GUN_KILLS][27]		 = str_to_num(stats[27][0])
	g_GunStats[id][GUN_HEADSHOTS][27]	 = str_to_num(stats[27][1])
	
	g_PlayerChallenges[id][MARKSMAN][28]	 = str_to_num(chal[28][0])
	g_PlayerChallenges[id][ELITE][28]	 = str_to_num(chal[28][1])
	g_GunStats[id][GUN_KILLS][28]		 = str_to_num(stats[28][0])
	g_GunStats[id][GUN_HEADSHOTS][28]	 = str_to_num(stats[28][1])
	
	g_PlayerChallenges[id][MARKSMAN][29]	 = str_to_num(chal[29][0])
	g_PlayerChallenges[id][ELITE][29]	 = str_to_num(chal[29][1])
	g_GunStats[id][GUN_KILLS][29]		 = str_to_num(stats[29][0])
	g_GunStats[id][GUN_HEADSHOTS][29]	 = str_to_num(stats[29][1])
	
	g_PlayerChallenges[id][MARKSMAN][30]	 = str_to_num(chal[30][0])
	g_PlayerChallenges[id][ELITE][30]	 = str_to_num(chal[30][1])
	g_GunStats[id][GUN_KILLS][30]		 = str_to_num(stats[30][0])
	g_GunStats[id][GUN_HEADSHOTS][30]	 = str_to_num(stats[30][1])
	
	/*----------------------------------------------------------------------------------------*/

	//Killstreaks Counter
	formatex( szKey , 63 , "%s-KILLSTREAKS", g_AuthID[id]);
	formatex( szData , 1023, "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i", 
	g_NumKillstreaks[id][KS_UAV], g_NumKillstreaks[id][KS_COU], g_NumKillstreaks[id][KS_AIR], g_NumKillstreaks[id][KS_PRED], g_NumKillstreaks[id][KS_EMP], g_NumKillstreaks[id][KS_NUKE],
	g_KillstreakKills[id][KS_AIR], g_KillstreakKills[id][KS_PRED], g_KillstreakKills[id][KS_NUKE],
	g_KillstreakChal[id][KS_UAV], g_KillstreakChal[id][KS_COU], g_KillstreakChal[id][KS_AIR], g_KillstreakChal[id][KS_PRED], g_KillstreakChal[id][KS_EMP], g_KillstreakChal[id][KS_NUKE],
	g_KillstreakChalKill[id][KS_AIR], g_KillstreakChalKill[id][KS_PRED], g_KillstreakChalKill[id][KS_NUKE]);
	
	nvault_get(g_Vault, szKey, szData, 1023) 
	
	new kscou[TOT_KILLSTREAKS][10], kskills[TOT_KILLSTREAKS][10], kschal[TOT_KILLSTREAKS][10], kschal2[TOT_KILLSTREAKS][10]
	parse(szData, 	kscou[KS_UAV], 9, kscou[KS_COU], 9, kscou[KS_AIR], 9, kscou[KS_PRED], 9, kscou[KS_EMP], 9, kscou[KS_NUKE], 9,
							         kskills[KS_AIR], 9, kskills[KS_PRED], 9, 	     	     kskills[KS_NUKE], 9,
			kschal[KS_UAV], 9, kschal[KS_COU], 9, kschal[KS_AIR], 9, kschal[KS_PRED], 9, kschal[KS_EMP], 9, kschal[KS_NUKE], 9,
							         kschal2[KS_AIR], 9, kschal2[KS_PRED], 9, 	     	     kschal2[KS_NUKE], 9) 
	
	g_NumKillstreaks[id][KS_UAV]	 	= str_to_num(kscou[KS_UAV])
	g_NumKillstreaks[id][KS_COU]	 	= str_to_num(kscou[KS_COU])
	g_NumKillstreaks[id][KS_AIR]	 	= str_to_num(kscou[KS_AIR])
	g_NumKillstreaks[id][KS_PRED]	 	= str_to_num(kscou[KS_PRED])
	g_NumKillstreaks[id][KS_EMP]	 	= str_to_num(kscou[KS_EMP])
	g_NumKillstreaks[id][KS_NUKE]	 	= str_to_num(kscou[KS_NUKE])
	g_KillstreakKills[id][KS_AIR]	 	= str_to_num(kskills[KS_AIR])
	g_KillstreakKills[id][KS_PRED]	 	= str_to_num(kskills[KS_PRED])
	g_KillstreakKills[id][KS_NUKE]	 	= str_to_num(kskills[KS_NUKE])
	
	g_KillstreakChal[id][KS_UAV]	 	= str_to_num(kschal[KS_UAV])
	g_KillstreakChal[id][KS_COU]	 	= str_to_num(kschal[KS_COU])
	g_KillstreakChal[id][KS_AIR]	 	= str_to_num(kschal[KS_AIR])
	g_KillstreakChal[id][KS_PRED]	 	= str_to_num(kschal[KS_PRED])
	g_KillstreakChal[id][KS_EMP]	 	= str_to_num(kschal[KS_EMP])
	g_KillstreakChal[id][KS_NUKE]		= str_to_num(kschal[KS_NUKE])
	g_KillstreakChalKill[id][KS_AIR]	= str_to_num(kschal2[KS_AIR])
	g_KillstreakChalKill[id][KS_PRED]	= str_to_num(kschal2[KS_PRED])
	g_KillstreakChalKill[id][KS_NUKE]	= str_to_num(kschal2[KS_NUKE])
	
	/*----------------------------------------------------------------------------------------*/
	
	check_level_silent(id)
	//check_challenges_silent(id)
	//check_killstreaks_silent(id)
}

SaveLevel(id)
{ 
    	if(equal(g_AuthID[id],"") || equal(g_AuthID[id],"STEAM_ID_PENDING")) 
		return PLUGIN_HANDLED
		
	new szKey[64];
	new szData[1024];

	//Base Mod Saves
	formatex( szKey , 63 , "%s-MAIN", g_AuthID[id]);
	formatex( szData , 1023, "%i %i %i %i %i %i", 
	g_Prestige[id], g_Experience[id], g_ChallangeCounter[ASSAULT][id], g_ChallangeCounter[SMG][id], g_ChallangeCounter[OTHER][id], g_ChallangeCounter[PISTOL][id]);

	nvault_set( g_Vault , szKey , szData );

	/*----------------------------------------------------------------------------------------*/
	
	formatex( szKey , 63 , "%s-Classes", g_AuthID[id]);
	formatex( szData , 1023, "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i", 
	g_CustomPerk[id][0][CUSTOM1], g_CustomPerk[id][1][CUSTOM1], g_CustomPerk[id][2][CUSTOM1], g_CustomEquiptment[id][CUSTOM1], g_CustomWeapon[PRIMARY][id][CUSTOM1], g_CustomWeapon[SECONDARY][id][CUSTOM1],
	g_CustomPerk[id][0][CUSTOM2], g_CustomPerk[id][1][CUSTOM2], g_CustomPerk[id][2][CUSTOM2], g_CustomEquiptment[id][CUSTOM2], g_CustomWeapon[PRIMARY][id][CUSTOM2], g_CustomWeapon[SECONDARY][id][CUSTOM2],
	g_CustomPerk[id][0][CUSTOM3], g_CustomPerk[id][1][CUSTOM3], g_CustomPerk[id][2][CUSTOM3], g_CustomEquiptment[id][CUSTOM3], g_CustomWeapon[PRIMARY][id][CUSTOM3], g_CustomWeapon[SECONDARY][id][CUSTOM3],
	g_CustomPerk[id][0][CUSTOM4], g_CustomPerk[id][1][CUSTOM4], g_CustomPerk[id][2][CUSTOM4], g_CustomEquiptment[id][CUSTOM4], g_CustomWeapon[PRIMARY][id][CUSTOM4], g_CustomWeapon[SECONDARY][id][CUSTOM4],
	g_CustomPerk[id][0][CUSTOM5], g_CustomPerk[id][1][CUSTOM5], g_CustomPerk[id][2][CUSTOM5], g_CustomEquiptment[id][CUSTOM5], g_CustomWeapon[PRIMARY][id][CUSTOM5], g_CustomWeapon[SECONDARY][id][CUSTOM5],
	g_CustomPerk[id][0][CUSTOM6], g_CustomPerk[id][1][CUSTOM6], g_CustomPerk[id][2][CUSTOM6], g_CustomEquiptment[id][CUSTOM6], g_CustomWeapon[PRIMARY][id][CUSTOM6], g_CustomWeapon[SECONDARY][id][CUSTOM6]);

	nvault_set( g_Vault , szKey , szData );
	
	/*----------------------------------------------------------------------------------------*/
	
	//Weapon Challange Save
	formatex(szKey,63,"%s-ID-WepChal-1",g_AuthID[id])
	formatex( szData , 1023, "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
	g_PlayerChallenges[id][MARKSMAN][1], g_PlayerChallenges[id][ELITE][1], g_GunStats[id][GUN_KILLS][1], g_GunStats[id][GUN_HEADSHOTS][1],
	g_PlayerChallenges[id][MARKSMAN][2], g_PlayerChallenges[id][ELITE][2], g_GunStats[id][GUN_KILLS][2], g_GunStats[id][GUN_HEADSHOTS][2],
	g_PlayerChallenges[id][MARKSMAN][3], g_PlayerChallenges[id][ELITE][3], g_GunStats[id][GUN_KILLS][3], g_GunStats[id][GUN_HEADSHOTS][3],
	g_PlayerChallenges[id][MARKSMAN][4], g_PlayerChallenges[id][ELITE][4], g_GunStats[id][GUN_KILLS][4], g_GunStats[id][GUN_HEADSHOTS][4],
	g_PlayerChallenges[id][MARKSMAN][5], g_PlayerChallenges[id][ELITE][5], g_GunStats[id][GUN_KILLS][5], g_GunStats[id][GUN_HEADSHOTS][5],
	g_PlayerChallenges[id][MARKSMAN][6], g_PlayerChallenges[id][ELITE][6], g_GunStats[id][GUN_KILLS][6], g_GunStats[id][GUN_HEADSHOTS][6],
	g_PlayerChallenges[id][MARKSMAN][7], g_PlayerChallenges[id][ELITE][7], g_GunStats[id][GUN_KILLS][7], g_GunStats[id][GUN_HEADSHOTS][7],
	g_PlayerChallenges[id][MARKSMAN][8], g_PlayerChallenges[id][ELITE][8], g_GunStats[id][GUN_KILLS][8], g_GunStats[id][GUN_HEADSHOTS][8],
	g_PlayerChallenges[id][MARKSMAN][9], g_PlayerChallenges[id][ELITE][9], g_GunStats[id][GUN_KILLS][9], g_GunStats[id][GUN_HEADSHOTS][9],
	g_PlayerChallenges[id][MARKSMAN][10], g_PlayerChallenges[id][ELITE][10], g_GunStats[id][GUN_KILLS][10], g_GunStats[id][GUN_HEADSHOTS][10]);
	
	nvault_set( g_Vault , szKey , szData );
	
	/*----------------------------------------------------------------------------------------*/
	
	formatex(szKey,63,"%s-ID-WepChal-2",g_AuthID[id])
	formatex( szData , 1023, "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
	g_PlayerChallenges[id][MARKSMAN][11], g_PlayerChallenges[id][ELITE][11], g_GunStats[id][GUN_KILLS][11], g_GunStats[id][GUN_HEADSHOTS][11],
	g_PlayerChallenges[id][MARKSMAN][12], g_PlayerChallenges[id][ELITE][12], g_GunStats[id][GUN_KILLS][12], g_GunStats[id][GUN_HEADSHOTS][12],
	g_PlayerChallenges[id][MARKSMAN][13], g_PlayerChallenges[id][ELITE][13], g_GunStats[id][GUN_KILLS][13], g_GunStats[id][GUN_HEADSHOTS][13],
	g_PlayerChallenges[id][MARKSMAN][14], g_PlayerChallenges[id][ELITE][14], g_GunStats[id][GUN_KILLS][14], g_GunStats[id][GUN_HEADSHOTS][14],
	g_PlayerChallenges[id][MARKSMAN][15], g_PlayerChallenges[id][ELITE][15], g_GunStats[id][GUN_KILLS][15], g_GunStats[id][GUN_HEADSHOTS][15],
	g_PlayerChallenges[id][MARKSMAN][16], g_PlayerChallenges[id][ELITE][16], g_GunStats[id][GUN_KILLS][16], g_GunStats[id][GUN_HEADSHOTS][16],
	g_PlayerChallenges[id][MARKSMAN][17], g_PlayerChallenges[id][ELITE][17], g_GunStats[id][GUN_KILLS][17], g_GunStats[id][GUN_HEADSHOTS][17],
	g_PlayerChallenges[id][MARKSMAN][18], g_PlayerChallenges[id][ELITE][18], g_GunStats[id][GUN_KILLS][18], g_GunStats[id][GUN_HEADSHOTS][18],
	g_PlayerChallenges[id][MARKSMAN][19], g_PlayerChallenges[id][ELITE][19], g_GunStats[id][GUN_KILLS][19], g_GunStats[id][GUN_HEADSHOTS][19],
	g_PlayerChallenges[id][MARKSMAN][20], g_PlayerChallenges[id][ELITE][20], g_GunStats[id][GUN_KILLS][20], g_GunStats[id][GUN_HEADSHOTS][20]);
	
	nvault_set( g_Vault , szKey , szData );
	 
	 /*----------------------------------------------------------------------------------------*/
	 
	formatex(szKey,63,"%s-ID-WepChal-3",g_AuthID[id])
	formatex( szData , 1023, "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
	g_PlayerChallenges[id][MARKSMAN][21], g_PlayerChallenges[id][ELITE][21], g_GunStats[id][GUN_KILLS][21], g_GunStats[id][GUN_HEADSHOTS][21],
	g_PlayerChallenges[id][MARKSMAN][22], g_PlayerChallenges[id][ELITE][22], g_GunStats[id][GUN_KILLS][22], g_GunStats[id][GUN_HEADSHOTS][22],
	g_PlayerChallenges[id][MARKSMAN][23], g_PlayerChallenges[id][ELITE][23], g_GunStats[id][GUN_KILLS][23], g_GunStats[id][GUN_HEADSHOTS][23],
	g_PlayerChallenges[id][MARKSMAN][24], g_PlayerChallenges[id][ELITE][24], g_GunStats[id][GUN_KILLS][24], g_GunStats[id][GUN_HEADSHOTS][24],
	g_PlayerChallenges[id][MARKSMAN][25], g_PlayerChallenges[id][ELITE][25], g_GunStats[id][GUN_KILLS][25], g_GunStats[id][GUN_HEADSHOTS][25],
	g_PlayerChallenges[id][MARKSMAN][26], g_PlayerChallenges[id][ELITE][26], g_GunStats[id][GUN_KILLS][26], g_GunStats[id][GUN_HEADSHOTS][26],
	g_PlayerChallenges[id][MARKSMAN][27], g_PlayerChallenges[id][ELITE][27], g_GunStats[id][GUN_KILLS][27], g_GunStats[id][GUN_HEADSHOTS][27],
	g_PlayerChallenges[id][MARKSMAN][28], g_PlayerChallenges[id][ELITE][28], g_GunStats[id][GUN_KILLS][28], g_GunStats[id][GUN_HEADSHOTS][28],
	g_PlayerChallenges[id][MARKSMAN][29], g_PlayerChallenges[id][ELITE][29], g_GunStats[id][GUN_KILLS][29], g_GunStats[id][GUN_HEADSHOTS][29],
	g_PlayerChallenges[id][MARKSMAN][30], g_PlayerChallenges[id][ELITE][30], g_GunStats[id][GUN_KILLS][30], g_GunStats[id][GUN_HEADSHOTS][30]);
	
	nvault_set( g_Vault , szKey , szData );
	
	/*----------------------------------------------------------------------------------------*/
	
	//Killstreaks Counter
	formatex( szKey , 63 , "%s-KILLSTREAKS", g_AuthID[id]);
	formatex( szData , 1023, "%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i", 
	g_NumKillstreaks[id][KS_UAV], g_NumKillstreaks[id][KS_COU], g_NumKillstreaks[id][KS_AIR], g_NumKillstreaks[id][KS_PRED], g_NumKillstreaks[id][KS_EMP], g_NumKillstreaks[id][KS_NUKE],
	g_KillstreakKills[id][KS_AIR], g_KillstreakKills[id][KS_PRED], g_KillstreakKills[id][KS_NUKE],
	g_KillstreakChal[id][KS_UAV], g_KillstreakChal[id][KS_COU], g_KillstreakChal[id][KS_AIR], g_KillstreakChal[id][KS_PRED], g_KillstreakChal[id][KS_EMP], g_KillstreakChal[id][KS_NUKE],
	g_KillstreakChalKill[id][KS_AIR], g_KillstreakChalKill[id][KS_PRED], g_KillstreakChalKill[id][KS_NUKE]);
	
	nvault_set( g_Vault , szKey , szData );
	 
	return PLUGIN_CONTINUE
}
