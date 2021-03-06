#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <round_terminator>

#define VERSION "1.193"

//#define USE_CUSTOM_SOUNDS

/* Activates loggers, commands for debugging */
//#define DEBUG_TOOLS

#if defined DEBUG_TOOLS
	   /* debug results are stored in this file */
	#define DEBUG_FILE "csflags_debug.txt"
	   /* automatically generates debug log */
	#define DEBUG_MODE
#endif

#define ADMIN_CSFLAGS ADMIN_ADMIN

// =================================================
// In the following pevs, 
// my intention was not to abuse from memory
// by creating an array for each required property.
// But storing values in entities like this can be a
// pain for documentation.

// uniqueid is meant to fast check if its
// a csflags entity in think and touch forwards;
#define pev_csf_uniqueid pev_groupinfo

// stores the id of player who's taken the flag
#define pev_csf_flagowner pev_iuser2

// stores the id of player who's touching the flag
#define pev_csf_flagtoucher pev_playerclass

// stores the delay for capturing this specific flag
#define pev_flagcapture_delay pev_fuser1


// the entity id of the flag controlled by this trigger
#define pev_csf_flagent pev_iuser3

// the array id of the flag controlled by this trigger
#define pev_csf_flagid pev_iuser4

// the flag status of a flag controlled by this trigger
#define pev_csf_flagstatus pev_body

// the type (size) of hitbox of this trigger
#define pev_csf_hitbox pev_team

// the entity id of the trigger that controls this flag
#define pev_csf_trigger pev_iuser1

// a special delay control for this entity to think
#define pev_think_delay pev_button

#define MAX_CSFLAGS 5 // hard limit
#define TEAMSNUM 2 // hard limit - designed for cs

#define ID_TEAM_CT 1
#define ID_TEAM_T 0
#define CLASSNAME_CSFLAG "_csf"
#define CLASSNAME_TRIGGER_FLAG "_ftrigger"
#define CSFLAG_TYPEID 11122
#define TRIGGERFLAG_TYPEID 11144

// random taskid
#define TASKID_SCORE_UPDATE 27328
#define TASKID_SYNC_SCORE 723
#define TASKID_RESTART_COUNTER 724
#define TASKID_MAPEND 2938
#define TASKID_RADIORANGE 33
#define TASKID_HIDERADIOICON 34
#define TASKID_RESTORE_MP 1298
#define TASKID_HUDREPEAT 989
#define TASKID_CAPTUREDELAY 1020

#define INTERVAL_SCORE_UPDATE 10.0
#define INTERVAL_SYNCH 0.5

#define GAMESTATE_STOPPED 1
#define GAMESTATE_STARTED 1 << 1
#define GAMESTATE_WAIT 1 << 2
#define GAMESTATE_FORCEDEND 1 << 3
#define GAMESTATE_SHOWSCORE 1 << 4
#define GAMESTATE_MATCHOVER 1 << 5
#define GAMESTATE_HUDREPEAT 1 << 6

#define MODEL_FLAGS "models/mw2/domination_marker.mdl"
#define FILE_DOMCFG "/csflags/%s.cfg"
//#define SOUND_FLAGTAKEN "mw2/tdm_captured.wav"
//#define SOUND_OPPONENT_FLAGTAKEN "mw2/tdm_lost.wav"

#define CSFLAGS_ICON_NAME	"dmg_shock"
#define CSFLAGS_ICON_R	 	50
#define CSFLAGS_ICON_G	 	50
#define CSFLAGS_ICON_B	 	200

#define MAX_HITBOXES 3

#define HITBOX_ID_NORMAL 0
#define HITBOX_ID_LARGER 1
#define HITBOX_ID_LARGE 2

#define HITBOX_NORMAL {{-24.0, -24.0, -64.0}, {24.0, 24.0, 64.0}}
#define HITBOX_LARGER {{-60.0, -60.0, -80.0}, {60.0, 60.0, 80.0}}
#define HITBOX_LARGE {{-100.0, -100.0, -128.0}, {100.0, 100.0, 128.0}}

#define HITBOX_MAX 1
#define HITBOX_MIN 0

#define HUD_LINE_MAXSIZE 32
#define HUD_FLAGS_STRING_MAXSIZE HUD_LINE_MAXSIZE * MAX_CSFLAGS

#define MSG_HEADER "[Domination]"

#define MSG_FLAGSTATE_NOTIFY_OP "^4[Domination] ^1%s captured the ^4[%s]^1 flag for the %s^1"
#define MSG_FLAGSTATE_NOTIFY    "^4[Domination] ^3%s^1 captured the ^4[%s]^1 flag for the ^3%s^1"

#define MSG_COUNTER "CS Flags restarting in %d"
#define MSG_RESTARTED "CS Flags restarted!"
#define MSG_CONS_NOCFG "Could not start csflags because there's no cfg file or file contains no flags."
#define MSG_CONS_NOT_ENABLED "Could not start because CSFlags is not enabled."
#define MSG_TIME_OVER "Time is over. Waiting for a winner..."
#define MSG_CHANGEMAP_DELAY "CS Flags match is over, waiting for the next map."
#define HUD_TEAMWINNER "%s have won this match!"
#define HUD_TEAMWINS "%s win this flag round!"
#define HUD_BESTSCORE "^n^nBest scores in this match:"
#define TEAM_DESC_CT "U.S. Army Rangers"
#define TEAM_DESC_T "OpFor"

#define IFW_FLAGTAKEN "csf_flag_taken"
#define IFW_FLAGTAKEN2 "csf_flag_taken_2"
#define IFW_ROUNDWON "csf_round_won"
#define IFW_MATCHWON "csf_match_won"

#define MSG_RADIO_POINTSECURED "Area secure!"

/******************************************************************************************
 * The following function/values were taken from
 * VEN's CTF plugin
 */
 // private data deaths offset
#define OFFSET_DEATHS_32BIT 444
#define OFFSET_DEATHS_64BIT 493
// deaths offset linux difference
#define OFFSET_DEATHS_LINUXDIFF 5 

// determination of actual offsets
#if !defined PROCESSOR_TYPE // is automatic 32/64bit processor detection?
	#if cellbits == 32 // is the size of a cell are 32 bits?
		// then considering processor as 32bit
		#define OFFSET_DEATHS OFFSET_DEATHS_32BIT
		//not used in this version //#define OFFSET_MONEY OFFSET_MONEY_32BIT
	#else // in other case considering the size of a cell as 64 bits
		// and then considering processor as 64bit
		#define OFFSET_DEATHS OFFSET_DEATHS_64BIT
		//not used in this version //#define OFFSET_MONEY OFFSET_MONEY_64BIT
	#endif
#else // processor type specified by PROCESSOR_TYPE define
	#if PROCESSOR_TYPE == 0 // 32bit processor defined
		#define OFFSET_DEATHS OFFSET_DEATHS_32BIT
		//not used in this version //#define OFFSET_MONEY OFFSET_MONEY_32BIT
	#else // considering that 64bit processor defined
		#define OFFSET_DEATHS OFFSET_DEATHS_64BIT
		//not used in this version //#define OFFSET_MONEY OFFSET_MONEY_64BIT
	#endif
#endif


// marco to retrieve user deaths
#define CS_GET_USER_DEATHS_(%1) get_pdata_int(%1, OFFSET_DEATHS, OFFSET_DEATHS_LINUXDIFF)
/******************************************************************************************
*/

/** Names of dom areas */
new g_PlaceNames[MAX_CSFLAGS][16]

/** State of flas, i.e. flag taken, etc */
new g_FlagState[MAX_CSFLAGS] = {-1 ,...}

/** Score Counter for each player */
new Float:g_PlayerScore[33]

/** Score counter for each team */
new Float:g_TeamScore[TEAMSNUM]

/** Matches won by each team */
new g_TeamWins[TEAMSNUM]

/** Number of flags for the current map*/
new g_MapFlagsNum

/** Radio messages state */
new g_Radio[33]

/** mp time backup for swap */
new Float:g_OldMPTime

/** time to restart the match */
new Float:g_RestartTime

/** 
 * last team winner of a match
 * used to display info if a round restarts
 * when csflags match end info was being shown. 
 */
new g_LastWinner

new bool:g_MatchLastWin

/** Stores pcvar for max points before a team win */
new g_cvarMaxPoints

/** Stores pcvar for csflags enabled */
new g_cvarDomEnabled

/** Stores pcvar for the delay before map ends */
new g_cvarMapEndTime

/** Stores pcvar for the number of csflags matches wins required for a map switch */
new g_cvarMaxWins

/** Stores pcvar that defines if a map switch should take place if csflags wins are tied */
new g_cvarTieMatch

/** Stores pcvar that defines if a match is won when all flags are taken by a team */
new g_cvarAllFlagsWin

/** Stores pcvar that switches radio messages */
new g_cvarUseRadio

/** Stores pcvar that defines if map objectives should be removed */
new g_cvarRemoveDefObjectives

/** Stores pcvar that defines how much frags are added to players of csflags winning team */ 
new g_cvarWinFrags

/** Stores pcvar that defines how much frags are added to a player that captures a flag */
new g_cvarCaptureFrags

/** Stores pcvar that defines how much time it takes for a player to capture a flag */
new g_cvarCaptureDelay
new Float:g_CaptureDelay[33]
new gFlagIcon[] = "models/mw2/domination_marker_icon.mdl"
new gIcon
new g_Icon[1385]

public flag_runner(id, Float:num)
{
	g_CaptureDelay[id] = num
}

/** Stores pcvar that defines if players should respawn after match is over */
new g_cvarMatchRespawn

/** Stores pcvar that defines if players should freeze when a match is won */
new g_cvarFreeze

new g_cvarVoteStartCommand

new bool:g_VoteCmdExecuted = false

/** Stores the message id for score info */
new g_msgidScoreInfo

/** Stores the message id for icon display */
new g_msgidIcon

/** Stores the message id for the progress bar*/
new g_msgidProgress

/** Stores the message id for players 'say text' */
new g_msgidSayText

/** Stores the fakemeta touch forward registry */
new g_fwTouch

/** Stores the fakemeta think forward registry */
new g_fwThink

/** Stores the fakemeta player think foward registry */
new g_fwPThink


/** Stores the flag taken forward registry */
new g_ifw_FlagTaken
new g_ifw_FlagTaken2

/** Stores the round won forward registry */
new g_ifw_RoundWon

/** Stores the match won forward registry */
new g_ifw_MatchWon

/** Stores the max players to avoid get_maxplayers calls */
new g_MaxPlayers

/** Stores the origin of triggers */
new Float:g_TriggerOrigin[MAX_CSFLAGS][3]

/** 
 *  Stores the size of triggers 
 *  current values are:
 *  HITBOX_NORMAL {{-24.0, -24.0, -64.0}, {24.0, 24.0, 64.0}}
 *  HITBOX_LARGER {{-60.0, -60.0, -80.0}, {60.0, 60.0, 80.0}}
 *  HITBOX_LARGE {{-100.0, -100.0, -128.0}, {100.0, 100.0, 128.0}}
 */
new Float:g_mmSize[3][2][3] = 
{
	HITBOX_NORMAL,
	HITBOX_LARGER,
	HITBOX_LARGE
}

/** Team name descriptions */ 
new g_Teams[2][] = {"Terrorists", "CTs"}

/** Default notify sounds */
new const g_NotifySound[3][2][] =
{
	{ "mw2/domination/cap_a.wav", "mw2/domination/cap_alpha.wav" },
	{ "mw2/domination/cap_b.wav", "mw2/domination/cap_bravo.wav" },
	{ "mw2/domination/cap_c.wav", "mw2/domination/cap_charlie.wav" }
}

new const g_NotifySound2[3][2][] =
{
	{ "mw2/domination/lost_a.wav", "mw2/domination/lost_alpha.wav" },
	{ "mw2/domination/lost_b.wav", "mw2/domination/lost_bravo.wav" },
	{ "mw2/domination/lost_c.wav", "mw2/domination/lost_charlie.wav" }
}

/** 
 * Current plugin state thats defined by several flags: 
 * GAMESTATE_STOPPED - csflags has been stopped
 * GAMESTATE_STARTED - csflgas has started
 * GAMESTATE_WAIT - time is over, csflags is waiting for a winner.
 * GAMESTATE_FORCEDEND = csflags should end anyway
 * GAMESTATE_SHOWSCORE - csflags is showing score
 * GAMESTATE_MATCHOVER - csflags match is over
 * GAMESTATE_HUDREPEAT - hud info has been interrupted by a round restart and should be displayed again.
 */
public g_CSFlagsState




/** Flags if score hud string must be rebuilt */
new bool:g_UpdateScoresHud

/** Flags if flags hud string must be rebuilt */
new bool:g_UpdateFlagsHud

/** 
  * Stores last score integer for a team so script will detect
  * when score hud must be updated.
  */
new g_LastTeamScore[2] = {-1, ...}

/** Hud score messages are not translated for optimization */
new const g_ScoreHeaderFormat[2][] =
{
	"OpFor: %d",
	"U.S. Army Rangers: %d"
}


#if defined DEBUG_TOOLS

new const debugHeader[] =
{
	"[CSFlags_Debug]"
}
new const debugLine[] = 
{
	"----------------------------------"
}
new debugMsg[160]
new Tabs[16] = {'^t', ...}
new lastFlagState = -1
#if defined DEBUG_FILE
new pDebugFile
#endif // DEBUG_FILE
#endif // DEBUG_TOOLS

/**
 * (amxmodx core forward.)
 * - Register all required events
 * - Registers all required cvars.
 * - Initializes messages ids
 * - Starts csflags match if :
 *    1) amx_csflags_enabled is set to 1;
 *    2) this maps has a config file for csflags.
 */
public plugin_init() 
{
	register_plugin("csflags", VERSION, "commonbullet")	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("event_game_commencing", 2, "1=Game_Commencing")
	register_concmd("amx_csflags_restart", "csflags_restart_cmd", ADMIN_CSFLAGS)
	register_concmd("amx_csflags_stop", "csflags_stop_cmd", ADMIN_CSFLAGS)
	
	register_dictionary("csflags.txt")
	
	g_cvarMaxWins = register_cvar("amx_csflags_max_wins", "3")
	g_cvarMaxPoints = register_cvar("amx_csflags_max_points", "100")
	g_cvarDomEnabled = register_cvar("amx_csflags_enabled", "1")
	g_cvarMapEndTime = register_cvar("amx_csflags_mapendtime", "0.5")
	g_cvarTieMatch = register_cvar("amx_csflags_tiematch", "0")
	g_cvarAllFlagsWin = register_cvar("amx_csflags_allflags_win", "1")
	g_cvarUseRadio = register_cvar("amx_csflags_useradio", "1")
	g_cvarRemoveDefObjectives = register_cvar("amx_csflags_remove_map_obj", "1")
	g_cvarWinFrags = register_cvar("amx_csflags_winfrags", "0")
	g_cvarCaptureFrags = register_cvar("amx_csflags_capturefrags", "0")
	g_cvarCaptureDelay = register_cvar("amx_csflags_capturedelay", "3")
	g_cvarMatchRespawn = register_cvar("amx_csflags_respawn", "0")
	g_cvarFreeze = register_cvar("amx_csflags_freeze", "0")
	g_cvarVoteStartCommand = register_cvar("amx_csflags_vote_startcmd", "")

	g_msgidProgress = get_user_msgid("BarTime2")
	g_msgidScoreInfo = get_user_msgid("ScoreInfo")
	g_msgidIcon = get_user_msgid("StatusIcon")
	g_msgidSayText = get_user_msgid("SayText")
	
	g_MaxPlayers = get_maxplayers()
	
	if(get_pcvar_num(g_cvarDomEnabled)) {
		if(load_config()) {
			csflags_init()
		}
	}
#if defined DEBUG_TOOLS
	register_concmd("csflags_trace_flags", "debug_flags")
	register_concmd("csflags_trace_gamestate", "debug_gamestate")
	
	new mapname[32]
	new msg[128]
	
	get_mapname(mapname, 31)
	
	open_debug_file()
	formatex(msg, 127, "***^nStarting Debug Section^nMap: %s^n***", mapname)
	debug_print(0, msg)
	close_debug_file()	
#endif
}


/**
 * (amxmodx core forward)
 * - Precaches flags model
 * - Precaches sounds
 */
public plugin_precache() 
{
	//if (get_pcvar_num(g_cvarDomEnabled))
	//{
	precache_model(MODEL_FLAGS)
	gIcon = precache_model(gFlagIcon)
	
	for ( new i=0; i<3; i++)
	{
		for ( new j=0; j<2; j++)
		{
			precache_sound(g_NotifySound[i][j])
			precache_sound(g_NotifySound2[i][j])
		}
	}
	//}
	
	//precache_sound(SOUND_FLAGTAKEN)
	//precache_sound(SOUND_OPPONENT_FLAGTAKEN)
	
}

/**
 *  This function is called at the very beginning of csflags match. It resets game state and
 *  initializes all required resources.
 *  - Sets the game state to GAMESTATE_STARTED
 *  - Removes the objetives if cvar has been properly set.
 *  - Register touch, think and player think forwards.
 *  - Register forwards to be used externally: flag taken, match won, round won.
 *  - Sets time interval to update scores hud.
 *  - Sets a hook mapend, it's 11.0, one second before map end counter.
 */
public csflags_init() 
{	
	g_CSFlagsState = 0
	g_CSFlagsState |= GAMESTATE_STARTED
	
	if(get_pcvar_num(g_cvarRemoveDefObjectives))
		remove_default_objectives()
		
	g_UpdateScoresHud = true
	g_UpdateFlagsHud = true
	
	set_task(INTERVAL_SCORE_UPDATE, "update_score", TASKID_SCORE_UPDATE, _, _, "b")
	
	g_fwTouch = register_forward(FM_Touch, "forward_touch")
	g_fwThink = register_forward(FM_Think, "flag_think")
	g_fwPThink = register_forward(FM_PlayerPreThink, "player_think")
	
	g_ifw_FlagTaken = CreateMultiForward(IFW_FLAGTAKEN, ET_IGNORE, FP_CELL)	// toucher
	g_ifw_FlagTaken2 = CreateMultiForward(IFW_FLAGTAKEN2, ET_IGNORE, FP_CELL)	// toucher
	g_ifw_MatchWon = CreateMultiForward(IFW_MATCHWON, ET_IGNORE, FP_CELL)	// team winner
	g_ifw_RoundWon = CreateMultiForward(IFW_ROUNDWON, ET_IGNORE, FP_CELL)	// team winner

	set_task(11.0, "set_mapend_mptimelimit", TASKID_MAPEND, _, _, "d", 1)
}

/**
 * Pauses a csflags match
 * @param pausescore If different from 0, it removes score hud.
 */
csflags_pause(pausescore = 0) 
{
	
	if(pausescore)
		remove_task(TASKID_SCORE_UPDATE)
}

/**
 * Resets a csflags match by cleaning pevs stored in flags and triggers entities.
 * @param wins if different from 0, it resets also the team wins.
 * @param players if different from 0, it resets also the players score.
 **/
csflags_reset(wins = 0, players = 0) 
{
	new flag

#if defined DEBUG_MODE
	open_debug_file()
	print_stack(0, "csflags_reset")
	printvar_cell(0, "wins", wins)
	printvar_cell(0, "players", players)
	close_debug_file()
#endif	
	while((flag = engfunc(EngFunc_FindEntityByString, flag, "classname", CLASSNAME_CSFLAG))) {
		
		set_pev(flag, pev_csf_flagstatus, 0)
		set_pev(flag, pev_csf_flagowner, 0)		
		
		if(task_exists(TASKID_CAPTUREDELAY + flag))
			remove_task(TASKID_CAPTUREDELAY + flag)

		set_pev(flag, pev_csf_flagtoucher, 0)
	}
	
	g_TeamScore[ID_TEAM_CT] = 0.0
	g_TeamScore[ID_TEAM_T] = 0.0
	
	g_LastTeamScore[ID_TEAM_CT] = -1
	g_LastTeamScore[ID_TEAM_T] = -1
	
	if(wins) {
		g_TeamWins[ID_TEAM_CT] = 0
		g_TeamWins[ID_TEAM_T] = 0
	}
	
	if(players) {
		for(new i = 1; i < 33; i++)
			g_PlayerScore[i] = 0.0
	}
	
	for(new i = 0; i < MAX_CSFLAGS; i++)
		g_FlagState[i] = -1	
}

/**
 *  Makes sure all forwards are properly registered, resets the score hud and removes
 *  GAME_STOPPED flag from csflags' status.
 */
csflags_restart() 
{
	
#if defined DEBUG_MODE
	open_debug_file()
	print_stack(0, "csflags_restart")
	close_debug_file()
#endif
	if(!g_fwTouch)
		g_fwTouch = register_forward(FM_Touch, "forward_touch")
	if(!g_fwThink)
		g_fwThink = register_forward(FM_Think, "flag_think")
	if(!g_fwPThink)
		g_fwPThink = register_forward(FM_Think, "player_think")
		
	if(!g_ifw_FlagTaken)
		g_ifw_FlagTaken = CreateMultiForward(IFW_FLAGTAKEN, ET_IGNORE, FP_CELL)	// toucher
	if(!g_ifw_FlagTaken2)
		g_ifw_FlagTaken2 = CreateMultiForward(IFW_FLAGTAKEN2, ET_IGNORE, FP_CELL)	// toucher
	if(!g_ifw_MatchWon)
		g_ifw_MatchWon = CreateMultiForward(IFW_MATCHWON, ET_IGNORE, FP_CELL)	// team winner
	if(!g_ifw_RoundWon)
		g_ifw_RoundWon = CreateMultiForward(IFW_ROUNDWON, ET_IGNORE, FP_CELL)	// team winner
	
	g_UpdateScoresHud = true
	g_UpdateFlagsHud = true
	g_LastTeamScore[ID_TEAM_CT] = -1 
	g_LastTeamScore[ID_TEAM_T] = -1
	
	g_MatchLastWin = false
	
	if(!g_VoteCmdExecuted) {
		start_vote_cmd()
	}	
	
	if(!task_exists(TASKID_SCORE_UPDATE))
		set_task(INTERVAL_SCORE_UPDATE, "update_score", TASKID_SCORE_UPDATE, _, _, "b")
	
	
	g_CSFlagsState &= ~GAMESTATE_STOPPED
	
}

start_vote_cmd(Float:delay=6.0)
{
	new imminentWin
	new checkstr[2]
	
	get_pcvar_string(g_cvarVoteStartCommand, checkstr, 1)
	
	if(checkstr[0]) {
		imminentWin = get_pcvar_flags(g_cvarMaxWins) - 1
		
		if(imminentWin >= g_TeamWins[ID_TEAM_CT] || imminentWin >= g_TeamWins[ID_TEAM_T]) {
			g_VoteCmdExecuted = true
			set_task(delay, "exec_vote_cmd", 2121)
		}
	}
}

public exec_vote_cmd()
{
	new voteCommand[64]
	
	get_pcvar_string(g_cvarVoteStartCommand, voteCommand, 63)
	server_cmd(voteCommand)
}

/**
 *  This function is called by the command "amx_csflags_restart",
 *  forces game to reset, stop and start.
 */
public csflags_restart_cmd(id, level, cid) 
{
	if(!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED
		
	if(!get_pcvar_num(g_cvarDomEnabled))
		console_print(id, "%L", id, "MSG_CONS_NOT_ENABLED")
	
	csflags_reset()
	csflags_stop(1)
	
	if(load_config())
		csflags_init()
	else 
		console_print(id, "%L", id, "MSG_CONS_NOCFG")
	
	return PLUGIN_HANDLED
}

/**
 *  This function is called by the command "amx_csflags_stop", and just stops
 *  the plugin.
 */
public csflags_stop_cmd(id, level, cid) 
{
	if(!cmd_access(id, level, cid, 0))
		return PLUGIN_HANDLED
	csflags_stop(1)
	return PLUGIN_HANDLED
}

/**
 * Stops the plugin.
 * @param remove if different from 0, removes all csflags specific entities.
 */
csflags_stop(remove) 
{
#if defined DEBUG_MODE
	open_debug_file()
	print_stack(0, "csflags_restart_cmd")
	printvar_cell(0, "remove", remove)
	close_debug_file()
#endif

	if(g_CSFlagsState & GAMESTATE_STARTED) {
		if(task_exists(TASKID_SCORE_UPDATE))
			remove_task(TASKID_SCORE_UPDATE)
		if(remove) {
			remove_all_ents(CLASSNAME_CSFLAG)
			remove_all_ents(CLASSNAME_TRIGGER_FLAG)
			g_MapFlagsNum = 0
		}
		g_CSFlagsState = GAMESTATE_STOPPED  | (g_CSFlagsState & GAMESTATE_SHOWSCORE)
		
		/*
		unregister_forward(FM_Touch, g_fwTouch)
		unregister_forward(FM_Think, g_fwThink)
		g_fwThink = 0
		g_fwTouch = 0
		
		DestroyForward(g_ifw_FlagTaken)
		DestroyForward(g_ifw_MatchWon)
		DestroyForward(g_ifw_RoundWon)
		
		g_ifw_FlagTaken = 0
		g_ifw_MatchWon = 0
		g_ifw_RoundWon = 0 
		*/
	}
}

/**
 *  Called to 'make' a team win a match.
 *  - Pauses the plugin.
 *  - Updates teams scores.
 *  - Cleans flags states
 *  - Makes sure to clean progress bars from users who were capturing flags.
 *  - Sets GAMESTATE_SCORE on.
 *  - Executes team won forward.
 *  
 *  @param team the team param is the actual team id - 1 so Ts = 0, CTs = 1
 */
team_win(team) 
{
	
	/* if this state has already been set, means
	 * something wrong is going on, so get off here
	 */	
	if(g_CSFlagsState & GAMESTATE_SHOWSCORE)
		return PLUGIN_CONTINUE

	/* makes it pause */
	csflags_pause(1)
	
	/* this is used to check if csflags 
	 * winning limit has been set in the cvar */
	new winlimit
	
	/* used as an iterator for map flags */
	new flag
	
	/* Adds a pont to the winner team */
	g_TeamWins[team]++
	

#if defined DEBUG_MODE
	debug_gamestate(0, "team_win(0-0)")
#endif	

	/* reset flags being captured, also resets
	 * status bars from players who were capturing the flag
	 */
	while((flag = engfunc(EngFunc_FindEntityByString, flag, "classname", CLASSNAME_CSFLAG))) {
		new toucher
		
		toucher = pev(flag, pev_csf_flagtoucher)
		if(toucher) {
			set_pev(flag, pev_csf_flagtoucher, 0)

			if(task_exists(TASKID_CAPTUREDELAY + flag))
				remove_task(TASKID_CAPTUREDELAY + flag)

			msg_csf_icon(toucher, false)
			msg_bar_progress(toucher, 100, true)
		}
	}
	
	/* updates plugin status */
	g_CSFlagsState |= GAMESTATE_SHOWSCORE
	
	/* executes "csf_round_won" forward */
	if(g_ifw_RoundWon) {
		new retval
		ExecuteForward(g_ifw_RoundWon, retval, team + 1)
	}		
	
	switch(team + 1)
	{
		case 1: TerminateRound( RoundEndType_TeamExtermination, TeamWinning_Terrorist, MapType_AutoDetect );
		case 2: TerminateRound( RoundEndType_TeamExtermination, TeamWinning_Ct, MapType_AutoDetect );
	}
	
	/* fetches current csflags winlimit value */
	winlimit = get_pcvar_num(g_cvarMaxWins)
	
	/* Checks if the gamestate was set to wait.
	 * Then a map_should_end call checks if map has max win limit
	 * and if it as been reached.
	 * If so csflags is stopped, lastwin is set to 1.
	 */
	if(g_CSFlagsState & GAMESTATE_WAIT) {
		if(map_should_end()) {
			set_task(11.0, "restore_mptimelimit", TASKID_RESTORE_MP)
			csflags_stop(1)
			g_MatchLastWin = true
		}
	}
	
	/* 
	 * The following code is run when plugin wasn't waiting for a winner
	 * but the win limit has been reached by a team. In that case csflags
	 * is stopped and lastwin variable is set to 1.
	 */
	if(winlimit && !g_MatchLastWin) {
		if(g_TeamWins[team] >= winlimit && !(g_CSFlagsState & GAMESTATE_WAIT)) {
			force_end()
			csflags_stop(1)
			g_MatchLastWin = true
		}
	}
	
	/*
	 * If it's the last win of the match
	 * the csflags state should be updated, and the match
	 * won forward executed.
	 */
	if(g_MatchLastWin) {
		
		g_CSFlagsState |= GAMESTATE_MATCHOVER
		
		if(g_ifw_MatchWon) {
			new retval
			ExecuteForward(g_ifw_MatchWon, retval, team + 1)
		}		
	}
	
	/* this variable is only used in win_hud_repeat
	 * Version 1.19 has correct a bug it would only
	 * be reset in that function.
	*/
	g_LastWinner = (team + 1)
	
	/*
	 * displayes the winning hud for the teams.
	 */
	show_win_hud(team)

#if defined DEBUG_MODE
	open_debug_file()
	print_stack(0, "team_win")
	printvar_cell(0, "team", team)
	printvar_cell(0, "lastwin", lastwin)
	printvar_cell(0, "winlimit", winlimit)
	printvar_cell(0, "g_TeamWins[team]", g_TeamWins[team])
	printvar_cell(0, "g_LastWinner", g_LastWinner)
	close_debug_file()
	
	debug_gamestate(0, "team_win(0-1)")
	
#endif

	/* moves players to spawn if that's been set*/
	if(get_pcvar_num(g_cvarMatchRespawn))
		move_to_spawn()
	
	return PLUGIN_CONTINUE
}

/**
 * Prints those messages in players HUD channels when csflags match has
 * been partially or totally won.
 * @param team teamid - 1, so Ts = 0, CTs = 1.
 * @param lastwin used as a last win flag - last win messages are different.
 */
show_win_hud(team)
{
	/* used to store text messages */
	new message[256]
	
	/* variables used in playes rank calculation */
	new Float:score[5]
	new bestplayer[5]
	new name[32]
	new Float:currentscore
	
	/* well known prelude to get_players core function*/
	new players[32]
	new playersnum
	
	/* shit names, here's a disambiguishing:
	 * count - numbers of players in the rank, max 5 */
	new count
	/* has nothing to do with ranking, is used for
	 * formatting strings */
	new len
	
	/* I don't want to comment this, it seems to be working. */
	if(get_playersnum()) {		
		get_players(players, playersnum)
		for(new i = 0; i < playersnum; i++) {			
			for(new p = 0; p < 5; p++) {
				currentscore = g_PlayerScore[players[i]]
				if(currentscore == 0.0)
					continue
				if(currentscore > score[p]) {
					for(new q = 4; q > p && q > 0; q--) {
						score[q] = score[q - 1]
						bestplayer[q] = bestplayer[q - 1]
					}				
					score[p] = currentscore
					bestplayer[p] = players[i]
					count++
					break
				}
			}
		}
		count = (count > 5) ? 5 : count
	}
	
	/* adds a message header */
	len = format(message, 100, "%s^n", MSG_HEADER)
	
	/*
	 * If it's the last win,the csflags winner is added the message
	 */
	 
	/* 
	 *   Is there an amxmodx problem when concatening language strings with LANG_PLAYER?
	 *   - At least for me the first time it's shown in english (LANG_SERVER ??).
	 *     I didn't see any bug reports related and I don't know if its a bug or something
	 *     weird going on my test server. If someone complains about this behavior I'll
	 *     have to make this a loop with players id - that seems to work.
	*/
	/*if(g_MatchLastWin) {
		// the team variable may be changed regardless the round winner.
		team = (g_TeamWins[ID_TEAM_CT] > g_TeamWins[ID_TEAM_T]) ? ID_TEAM_CT : ID_TEAM_T
		len += format(message[len], 255 - len, "%L" , LANG_PLAYER, "HUD_TEAMWINNER", g_Teams[team])
	}
	else
		len += format(message[len], 255 - len, "%L", LANG_PLAYER, "HUD_TEAMWINS", g_Teams[team])*/
	
	/* Adding the best scores */
	/*len += format(message[len], 255 - len, "%L^n", LANG_PLAYER, "HUD_BESTSCORE")
	
	for(new i = 0; i < count; i++) {
		get_user_name(bestplayer[i], name, 31)
		len += format(message[len], 255 - len, "^n%s - %d", name, floatround(g_PlayerScore[bestplayer[i]]))		
	}*/
	
	/* send'em to the hud */
	//set_hudmessage (255, 40, 20, 0.10, 0.30, 0, 0.1, 10.0, 0.0, 0.0, 3)
	//show_hudmessage(0, message)
	
	/* checks if it isn't a repeatition because
	 * the hud had been interrupted by a round restart
	 * - in that case it has already been run */
	if(!(g_CSFlagsState & GAMESTATE_HUDREPEAT)) {
		
		/* round will restart as long as
		 * it wasn't the last one
		 */
		if(!g_MatchLastWin) {
			g_RestartTime = 10.0
			set_task(1.0, "restart_counter", TASKID_RESTART_COUNTER, _, _, "b")
		}
	}
}

/**
 * The win hud messages can be abrutely interrupted if the round restarts.
 * This function has been designed to recover hud messages whenever it's
 * needed.
 */
public win_hud_repeat() 
{
#if defined DEBUG_MODE
	open_debug_file()
	print_stack(0, "win_hud_repeat")
	printvar_cell(0, "g_LastWinner", g_LastWinner)
	close_debug_file()
#endif

	/* last winner has been set in team_win function
	   with the unique purpose to be recovered here. */
	if(g_LastWinner) {
		
		/* repeat the hud message */
		show_win_hud(g_LastWinner)
		
		/* resets the last winner */
		g_LastWinner = 0
		
		/* removes hud repeat flag from game state */
		g_CSFlagsState &= ~GAMESTATE_HUDREPEAT

#if defined DEBUG_MODE
		lastFlagState = g_CSFlagsState
	
		open_debug_file()
		print_stack(0, "win_hud_repeat(1,0)")
		printvar_cell(0, "lastwin", lastwin)
		close_debug_file()
#endif
	}
}



/**
 * This counter function calls itself through a timer until it's
 * ready to restart the match.
 */
public restart_counter() 
{

#if defined DEBUG_MODE
	open_debug_file()
	print_stack(0, "restart_counter")
	printvar_float(0, "g_RestartTime", g_RestartTime)
	close_debug_file()
#endif

	/* not ready yet */
	if(g_RestartTime > 0.0) {
		client_print(0, print_center, "%L", LANG_PLAYER, "MSG_COUNTER", floatround(g_RestartTime))
		g_RestartTime -= 1.0
		return PLUGIN_CONTINUE
	}
	
	/* ready, restart it */
	remove_task(TASKID_RESTART_COUNTER)
	client_print(0, print_center, "%L", LANG_PLAYER, "MSG_RESTARTED")
	g_CSFlagsState &= ~GAMESTATE_SHOWSCORE

#if defined DEBUG_MODE
	lastFlagState = g_CSFlagsState
	debug_gamestate(0, "restart_counter")
#endif
	
	/* restores players speed */
	for(new i = 1; i <= g_MaxPlayers; i++) {
		if(is_user_connected(i) && is_user_alive(i)) {
			engfunc(EngFunc_SetClientMaxspeed, i, 250.0)
			set_pev(i, pev_maxspeed, 250.0)
		}
	}
	
	g_LastWinner = 0 // 1.19 version - trying to fix array index out of bounds
	csflags_reset()
	csflags_restart()
	return PLUGIN_CONTINUE
}

/**
 *  forwarded in the log event it resets all
 *  csflags parameters.
 */
public event_game_commencing() 
{
	if(g_CSFlagsState & GAMESTATE_STARTED)
		csflags_reset(1, 1) 
}

/**
 *  Hooked from hltv event.
 *  - Checks if csflags was showing win scores when the round has been restarted; if so
 *    hud is displayed again.
 *  - Gets rid of hostages.
 */
public event_round_start() 
{
	/* is it showing scores? */
	if(g_CSFlagsState & GAMESTATE_SHOWSCORE ) {
		
		/* set a hud messages being repeated in csflags status */
		g_CSFlagsState |= GAMESTATE_HUDREPEAT
		
		/* in order to avoid bugs, sets a delay before hud is repeated*/
		set_task(0.2, "win_hud_repeat", TASKID_HUDREPEAT)
		
#if defined DEBUG_MODE
		print_comment(0, "event_round_start calls win_hut_repeat", 0, true)
		lastFlagState = g_CSFlagsState
#endif
		
	}
	
	/* if it's a rescue map, hostages are back - take them for a walk */
	if(get_pcvar_num(g_cvarRemoveDefObjectives) && (g_CSFlagsState & GAMESTATE_STARTED)) {
		if(engfunc(EngFunc_FindEntityByString, 32, "classname", "hostage_entity"))
			set_task(0.3, "take_for_a_walk", 2222)		
	}
}


/**
 * While there should be a better way to
 * safely remove hostages, this is simple enough for this plugin.
 * This has been taken from an old BAILOPAN's CSDM version.
 */
public take_for_a_walk() 
{
	new hostage
	while((hostage = engfunc(EngFunc_FindEntityByString, hostage, "classname", "hostage_entity"))) {
		new Float:origin[3] = {8191.0, 8191.0, 8191.0}
		engfunc(EngFunc_SetOrigin, hostage, origin)
	}
}

/**
 * Utilitary - removes all entities with a specific class name,
 * @param classname name of class of the entities to be removed. 
 */
remove_all_ents(const classname[]) 
{
	new flag
	while((flag = engfunc(EngFunc_FindEntityByString, flag, "classname", classname)))
		engfunc(EngFunc_RemoveEntity, flag)
}

/**
 * Clears the radio for a user.
 * g_Radio global is used as a flag to avoid players to get spammed by radio messaged.
 */
public radio_clear(const id[1]) 
{
	g_Radio[id[0]] = 0
}

/**
 * Hides the radio icon for a player.
 */
public hide_radio_icon(const id[1]) 
{
	message_begin (MSG_ALL, 135)
	write_byte (0)
	write_byte (id[0])
	message_end ()
}

/**
 * This is called after the delay for capturing a flag has been consumed.
 * @param info a typical "set_task" target array with multiple params:
 *        0 -> the entity id of a flag
 *        1 -> then id of the toucher
 */
public flag_captured(const info[])
{
	new flag
	new toucher
	new flagid
	new team
	
	/* gets the flag ent id */
	flag = info[0]
	
	/* get the toucher id */
	toucher = info[1]
	
	/* the id (index for plugin global arrays) is stored
	   inside the flag, through the defined pev_csf_flagid */
	flagid = pev(flag, pev_csf_flagid)
	
	/* the team of the "toucher" player */
	team = get_user_team(toucher)
	new origin[3]
	pev(flag, pev_origin, origin)
	new player = -1
	while( ( player = engfunc( EngFunc_FindEntityInSphere, player, origin, 200.0 ) ) != 0 )
	{
		if( !is_user_alive( player ) ) continue;
		if(g_ifw_FlagTaken2) 
		{
			new retval
			ExecuteForward(g_ifw_FlagTaken2, retval, player)
		}
	}
	
	/* if toucher's team is not CT or T, get off */
	if(team != 1 && team != 2)
		return
	
	/* sets the new owner of a flag */
	set_pev(flag, pev_csf_flagowner, toucher)
	
	/* resets the flag toucher for that flag */
	set_pev(flag, pev_csf_flagtoucher, 0)
	
	/* updates the team who's oweing that flag */
	set_pev(flag, pev_csf_flagstatus, team)
	set_pev(g_Icon[flag], pev_csf_flagstatus, team)
	
	
	/* g_FlagsState global is used for faster score hud updating */
	g_FlagState[flagid] = team - 1				
	
	/* clears icon for the toucher */
	msg_csf_icon(toucher, false)
	
	/* clear the progress bar of the toucher */
	msg_bar_progress(toucher, 100, true)
	
	/* if player frags for capturing flags cvar has been set, add it */
	if(get_pcvar_num(g_cvarCaptureFrags))
		add_user_frags(toucher, get_pcvar_num(g_cvarCaptureFrags), team)
	
	/* sends chat and radio messages */
	notify_flag_taken(toucher, flagid)
	
	/* flags list to be updated in next hud refresh */
	g_UpdateFlagsHud = true
	
	/* should this match end if all flags has been taken (cvar setting)? */
	if(get_pcvar_num(g_cvarAllFlagsWin)) {
		new allflags = 1
		for(new i = 1; i < g_MapFlagsNum; i++) {
			if(g_FlagState[i] != g_FlagState[i -1]) {
				allflags = 0
				break
			}
		}
		if(allflags) {
			new wf
			wf = get_pcvar_num(g_cvarWinFrags)
			if(wf)	add_user_frags(0, wf, team)					
			team_win(team - 1)
		}
	}
}

/**
 * Player think forward. In this version it's only used
 * with a purpose: to prevent players from moving or attacking if
 * amx_csflags_freeze has been set to 1.
 * @param id entity id of a player.
 */
public player_think(id) 
{
	/* if csflags hasn't been started, ignore it */
	if(!(g_CSFlagsState & GAMESTATE_STARTED))
		return FMRES_IGNORED
	
	/* if it's not displaying score, ignore it */
	if(!(g_CSFlagsState & GAMESTATE_SHOWSCORE))
		return FMRES_IGNORED	
	
	/* if it's not the end of a match, ignore it */
	if(!(g_CSFlagsState & GAMESTATE_MATCHOVER)) {
		
		/* if user isn't alive, get off */
		if(is_user_alive(id)) {
			
			/* if freeze cvar is set, move on */
			if(get_pcvar_num(g_cvarFreeze)) {
				
				/* makes players freexe */
				engfunc(EngFunc_SetClientMaxspeed, id, 0.1)
				set_pev(id, pev_maxspeed, 0.1)
			}
			
			/* blocks attacks */
			set_pev(id, pev_button, (pev(id, pev_button) & ~IN_ATTACK) & ~IN_ATTACK2) 
		}
	}
	
	return FMRES_IGNORED
}

/**
 * Forward to update flags.
 * @param flag the flag entity
 */
public flag_think(flag) 
{	
	/* if game is showing scores or stopped, flags won't think */	
	if(g_CSFlagsState & (GAMESTATE_SHOWSCORE | GAMESTATE_STOPPED)) {
		
#if defined DEBUG_MODE
		if(lastFlagState != g_CSFlagsState) {
			
			open_debug_file()
			print_stack(0, "flag_think")
			printvar_cell(0, "g_CSFlagsState & GAMESTATE_SHOWSCORE", g_CSFlagsState & GAMESTATE_SHOWSCORE)
			printvar_cell(0, "g_CSFlagsState & GAMESTATE_STOPPED", g_CSFlagsState & GAMESTATE_STOPPED)
			close_debug_file()
			lastFlagState = g_CSFlagsState
		}
#endif

		return FMRES_IGNORED
	}
	
	/* pev_csf_uniqueid is used to fast check if it's a flag */
	if(pev(flag, pev_csf_uniqueid) != CSFLAG_TYPEID)
		return FMRES_IGNORED
	
	/* flags will delay to think with this artificial but efficient next think */
	if(pev(flag, pev_think_delay) < 4) {
		set_pev(flag, pev_think_delay, pev(flag, pev_think_delay) + 1)
		return FMRES_IGNORED
	}
	
	/* resets the delay counter */
	set_pev(flag, pev_think_delay, 0)
	
	/* this is thinking, variables are static so cells are previously allocated */
	static classname[32]
	static team
	static owner
	static toucher	
	
	/* now this actually checks if it is a csflag */
	pev(flag, pev_classname, classname, 31)
	if(!equal(classname, CLASSNAME_CSFLAG))
		return FMRES_IGNORED
		
	/* this enables to stop csflags by setting this cvar. (why here?) */
	if(!get_pcvar_flags(g_cvarDomEnabled))
		csflags_stop(0)	
	
	/* if there's a toucher, it should have been set in touch forward */
	toucher = pev(flag, pev_csf_flagtoucher)

	if(toucher) {
		/* if toucher has died or it's not touching that flag anymore */
		if(!is_user_alive(toucher) || !is_touching(toucher, flag)) {
			/* clears the capture delay for this flag */
			if(task_exists(TASKID_CAPTUREDELAY + flag)) {
				/* removes the task */
				remove_task(TASKID_CAPTUREDELAY + flag)
				/* resets the toucher*/
				set_pev(flag, pev_csf_flagtoucher, 0)
				/* resets icon */
				msg_csf_icon(toucher, false)
				/* resets progress bar */
				msg_bar_progress(toucher, 100, true)
			}
		}
		
	}
	/* gets the team who's owning that flag */
	team = pev(flag, pev_csf_flagstatus)
	
	/* if it's owned by a team */
	if(team) {	
		/* gets the player who has captured this flag */
		owner = pev(flag, pev_csf_flagowner)
		
		/* adds a score to flag owner if he/she exists (that player may have disconnected) */
		if(owner)
			g_PlayerScore[owner] += 0.1
		
		/* if team is ct or t (being checked to be more safe) */
		if(team == 1 || team == 2) {
			
			new curScore
			//fag
			/* adds a score for that team */
			g_TeamScore[team - 1] += 0.1
			
			curScore = floatround(g_TeamScore[team - 1])
			
			callfunc_begin("Set_Scores","codmod24.amxx")
			callfunc_push_int(team-1)
			callfunc_push_int(curScore)
			callfunc_end()
			
			if(g_LastTeamScore[team - 1] != curScore) {
				g_UpdateScoresHud = true
				g_LastTeamScore[team -1] = curScore
			}
			
			/* if max points has been reached */
			if(curScore >= floatround(get_pcvar_float(g_cvarMaxPoints))) {
				/* if it isn't tied */
				if(curScore != floatround(g_TeamScore[(team - 1) ^ 1])) {
					/* adds a frag to team as long as frags cvar has been set */
					new wf
					wf = get_pcvar_num(g_cvarWinFrags)
					if(wf)	add_user_frags(0, wf, team)
										
					/* set this team as the match winner */
					team_win(team - 1)
				}
			}				
		}
	}
	return FMRES_IGNORED
}

/**
 * Amxmodx core forward
 * This is used to make sure that:
 * - score slot for player disconnected is reset
 * - if that player owns a flag it's reset (owner only, it continues up being captured to that player's team)
 * - removes a capture delay task
 * @param id Player id.
 */
public client_disconnect(id) 
{
	new flag
	g_CaptureDelay[id] = 1.0
	
	/* loops all existing csflags */
	while((flag = engfunc(EngFunc_FindEntityByString, flag, "classname", CLASSNAME_CSFLAG))) {
		
		/* if this user is the one who captured that flag, it's cleaned */
		if(pev(flag, pev_csf_flagowner) == id)
			set_pev(flag, pev_csf_flagowner, 0)
		
		/* if this user is touching this flag, remove tasks */
		if(pev(flag, pev_csf_flagtoucher) == id) {

			if(task_exists(TASKID_CAPTUREDELAY + flag))
				remove_task(TASKID_CAPTUREDELAY + flag)
			/* resets toucher */
			set_pev(flag, pev_csf_flagtoucher, 0)
		}
	}
	/* resets that player' score */
	g_PlayerScore[id] = 0.0
}

public client_connect(id)
	g_CaptureDelay[id] = 1.0

/**
 * Check's if a player is touching a csflags. This is meant to be faster
 * than engine's FindEntitiesInSphere because it requires no loops - it takes
 * some advantages of those flags+triggers specificity.
 * @param playerid id of the player
 * @param flagent the csflag entity that's touching that flag.
 */
is_touching(playerid, flagent) 
{	
	/* this is called inside think forwards,
	   variables are static for best performance */
	static Float:pl_origin[3]
	static hitbox
	static flagid

	/* gets the hitbox of that csflag */
	hitbox = pev(flagent, pev_csf_hitbox)
	
	/* gets the origin of the testing player */
	pev(playerid, pev_origin, pl_origin)
	
	/* gets that flag index (for global variables) */
	flagid = pev(flagent, pev_csf_flagid)
	
	/* checks if a player is inside that box, a 17.0 margin is added */
	if( (pl_origin[0] + 17.0 >= (g_TriggerOrigin[flagid][0] + g_mmSize[hitbox][HITBOX_MIN][0]) &&
	      pl_origin[0] - 17.0 <= (g_TriggerOrigin[flagid][0] + g_mmSize[hitbox][HITBOX_MAX][0])) &&
	     (pl_origin[1] + 17.0 >= (g_TriggerOrigin[flagid][1] + g_mmSize[hitbox][HITBOX_MIN][1]) &&
	      pl_origin[1] - 17.0 <= (g_TriggerOrigin[flagid][1] + g_mmSize[hitbox][HITBOX_MAX][1])) &&
	     (pl_origin[2] + 17.0 >= (g_TriggerOrigin[flagid][2] + g_mmSize[hitbox][HITBOX_MIN][2]) &&
	      pl_origin[2] - 17.0 <= (g_TriggerOrigin[flagid][2] + g_mmSize[hitbox][HITBOX_MAX][2])))
		return 1
	
	return 0
}

/**
 * Touch forward.
 * @param ent1 toucher
 * @param ent2 touched
 */
public forward_touch(ent2, ent1) 
{
	
	/* static variables in this forwards for best performance */
	static toucher
	static classname[32]
	static team
	static flag
	
	/* checks entities consistency */
	if(!pev_valid(ent1) || !pev_valid(ent2))
		return FMRES_IGNORED
	
	/* if this is a csflag trigger and the user is alive */
	if(pev(ent2, pev_csf_uniqueid) == TRIGGERFLAG_TYPEID && is_user_alive(ent1)) {
		
		/* It's ignored in either cases:
		   - math is over
		   - score is being shown
		   - plugin has been stopped
		 */
		if(g_CSFlagsState & (GAMESTATE_SHOWSCORE | GAMESTATE_STOPPED | GAMESTATE_MATCHOVER))
			return FMRES_IGNORED		
		
		/* the first filter (uniqueid) was meant to discard non flag messages more quickly,
		 * now it's time to make sure this is actually a csflag trigger */
		pev(ent2, pev_classname, classname, 31)				
		if(!equal(classname, CLASSNAME_TRIGGER_FLAG))
			return FMRES_IGNORED
		
		/* checks if that player is in a valid team */
		team = get_user_team(ent1)
		if(team < 1 || team > 2)
			return FMRES_IGNORED
			
		/* gets the flag entity from the touched csflag trigger entity */
		flag = pev(ent2, pev_csf_flagent)
		if(!pev_valid(flag))
			return FMRES_IGNORED
		
		/* toucher stores the id of flag previous toucher */
		toucher = pev(flag, pev_csf_flagtoucher)
		
		/* was that being touched by someone? */
		if(toucher) {
			/* is that toucher someone else from the opposed team ? */
			if(toucher != ent1 && get_user_team(toucher) != team) {
				/* resets flag ownwer */
				set_pev(flag, pev_csf_flagtoucher, 0)

				/* if there was a capture in progress, remove it */
				if(task_exists(TASKID_CAPTUREDELAY + flag)) {
					remove_task(TASKID_CAPTUREDELAY + flag)
					msg_bar_progress(toucher, 100, true)
					msg_csf_icon(toucher, false)
				}
			}
		}
		
		/* it wasn't being touched */
		else if(pev(flag, pev_csf_flagstatus) != team) {
			
			/* avoids progress bar flicking - that's probably because
			 * dimensions covered by hitboxes differ's a bit from that
			 * one checked in is_touching function.
			 */
			if(!is_touching(ent1, flag))
				return FMRES_IGNORED
			
			/* updates that flag toucher */
			set_pev(flag, pev_csf_flagtoucher, ent1)
			
			/* displays capturing icon */
			msg_csf_icon(ent1, true)
			
			/* sets the delay for calling capture function */
			new info[2]
			info[0] = flag
			info[1] = ent1
			if(task_exists(TASKID_CAPTUREDELAY + flag))
				remove_task(TASKID_CAPTUREDELAY + flag)
			
			/* displays the progress bar */
			msg_bar_progress(ent1, 0)
			
			set_task((get_pcvar_float(g_cvarCaptureDelay)*g_CaptureDelay[ent1]),
				 "flag_captured", TASKID_CAPTUREDELAY + flag, info, 2)
		}
		
	}
	return FMRES_IGNORED
}

/** 
 * Displays or hides the capturing icon
 * @param id player id
 * @param show flag to show or hide that icon.
 */
msg_csf_icon(id, bool:show = true) 
{
	message_begin(MSG_ONE, g_msgidIcon, {0, 0, 0}, id)
	write_byte((show ? 1 << 1: 0))
	write_string(CSFLAGS_ICON_NAME)
	if (show) {
		write_byte(CSFLAGS_ICON_R)
		write_byte(CSFLAGS_ICON_G)
		write_byte(CSFLAGS_ICON_B)
	}
	message_end()
}

/**
 * Shows or hides the capturing progress bar.
 * @param id player id
 * @param pos current position of the progress bar
 * @param kill flag to show or hide the progress bar
 */
msg_bar_progress(id, pos, bool:kill = false)
{	
	message_begin(MSG_ONE, g_msgidProgress, {0, 0, 0}, id)
	write_short(kill? 0 : floatround(get_pcvar_num(g_cvarCaptureDelay)*g_CaptureDelay[id]))
	write_short(pos)
	message_end()
}

/** 
 * Notifies to the team that a flag has been taken
 * This consistis in a radio and chat message.
 * @param toucher id of the person who's captured that flag
 * @param flagid id of the captured flag
 */
notify_flag_taken(toucher, flagid) 
{
	new name[32]
	new toucherteam
	new sid[4]
	new team
	new id[1]
	new message[93]
	new message_op[93]
	
	g_Radio[toucher] = 1
	id[0] = toucher
	
	// avoid radio spam
	set_task(4.0, "radio_clear", TASKID_RADIORANGE, id, 1) 
	
	set_task(1.5, "hide_radio_icon", TASKID_HIDERADIOICON, id, 1)
	
	toucherteam = get_user_team(toucher)
	get_user_name(toucher, name, 31)
	
	num_to_str(toucher, sid, 3)
	format(message, 92,  MSG_FLAGSTATE_NOTIFY, name, g_PlaceNames[flagid], (toucherteam == 2) ? (TEAM_DESC_CT) : TEAM_DESC_T)//g_Teams[g_FlagState[flagid]])
	format(message_op, 92, MSG_FLAGSTATE_NOTIFY_OP, name, g_PlaceNames[flagid], (toucherteam == 2) ? (TEAM_DESC_CT) : TEAM_DESC_T)
	
	/*switch(toucherteam)
	{
		case 1: set_pev(flagid,pev_rendercolor,Float:{255.0,0.0,0.0})
		case 2: set_pev(flagid,pev_rendercolor,Float:{0.0,0.0,255.0})
	}*/
	
	if(g_ifw_FlagTaken) {
		new retval
		ExecuteForward(g_ifw_FlagTaken, retval, toucher)
	}
	
	new Mode
	if (equal(g_PlaceNames[flagid], "Alpha"))
		Mode = 0
	else if (equal(g_PlaceNames[flagid], "Bravo"))
		Mode = 1
	else if (equal(g_PlaceNames[flagid], "Charlie"))
		Mode = 2
		
	
	for(new i = 1; i <= g_MaxPlayers; i++) {

		if(!is_user_connected(i))
			continue

		team = get_user_team(i)

		if(get_pcvar_num(g_cvarUseRadio) && (team == 1 || team == 2)) {
			if(team == toucherteam) {
				/* This is sorta pointless with the chat message right after that gives more info.
				//TextMsg
				message_begin(MSG_ONE_UNRELIABLE, 77, _, i)
				if (is_running("czero")) {					
					write_byte (5)
					write_string (sid) 
					write_string ("#Game_radio_location")
					write_string (name)
					write_string (g_PlaceNames[flagid])				
				}
				else {
					write_byte (3)
					write_string ("#Game_radio")
					write_string (name)
				}
				write_string(MSG_RADIO_POINTSECURED)
				message_end()
				*/

				//BotVoice
				message_begin(MSG_ONE_UNRELIABLE, 135, _, i)
				write_byte(1)
				write_byte(toucher)
				message_end()

				client_cmd(i, "spk %s", g_NotifySound[Mode][random(2)])
				send_chat_msg(i, message)
			}
			else  {
				// If the flag had a team, opposite stole it play sound
				if((team - 1) == ((toucherteam - 1) ^ 1))
					client_cmd(i, "spk %s", g_NotifySound2[Mode][random(2)])
					//client_cmd(i, "spk %s", SOUND_OPPONENT_FLAGTAKEN)
				send_chat_msg(i, message_op)
			}			
			
		}
		
	}
}

send_chat_msg(id, msg[])
{
	if(!is_user_connected(id))
		return
	message_begin(MSG_ONE_UNRELIABLE, g_msgidSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()	
}

/*send_chat_msg(id, msg[])
{	
	if(!is_user_connected(id))
		return
	message_begin(MSG_ONE, g_msgidSayText, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()	
}*/

move_to_spawn()
{
	new ctspawn
	new tspawn
	new spawn
	new players[32]
	new playersnum
	new team
	new Float:vec[3]
	new bool:restore
	
	restore = (get_pcvar_num(g_cvarMatchRespawn) == 2)	
	get_players(players, playersnum)
	
	for(new i = 0; i < playersnum; i++) {
		spawn = 0
		
		if(players[i] && is_user_alive(players[i])) {
			team = get_user_team(players[i])
			switch(team) {
				case 1 : {
					if(tspawn == -1)
						continue
					tspawn = engfunc(EngFunc_FindEntityByString, 
							 tspawn,
							 "classname",
							 "info_player_deathmatch")
					spawn = tspawn
					if(!tspawn)
						tspawn = -1
				}
				case 2 : {
					if(ctspawn == -1)
						continue
					ctspawn = engfunc(EngFunc_FindEntityByString,
							  ctspawn,
							  "classname",
							  "info_player_start")
					spawn = ctspawn
					if(!ctspawn)
						ctspawn = -1
				}				
			}
			if(spawn) {
				
				pev(spawn, pev_origin, vec)
				engfunc(EngFunc_SetOrigin, players[i], vec)
				set_pev(players[i], pev_fixangle, 1)
				pev(spawn, pev_angles, vec)
				set_pev(players[i], pev_angles, vec)
				
				if(restore)
					set_pev(players[i], pev_health, 100.0)
			}
		}
		
	}	
	
}

public update_score() 
{	
	
	static headerCT[25]
	static headerT[25]
	
	static flagsTakenT[HUD_FLAGS_STRING_MAXSIZE]
	static flagsTakenCT[HUD_FLAGS_STRING_MAXSIZE]
	
	
	static scoreCT[25 + HUD_FLAGS_STRING_MAXSIZE]
	static scoreT[25 + HUD_FLAGS_STRING_MAXSIZE]
	
	new ind
	
	// updates scores
	if(g_UpdateScoresHud) {
		formatex(headerT, 30, g_ScoreHeaderFormat[ID_TEAM_T], floatround(g_TeamScore[ID_TEAM_T]))
		formatex(headerCT, 30, g_ScoreHeaderFormat[ID_TEAM_CT], floatround(g_TeamScore[ID_TEAM_CT]))
	}
	
	// updates flags list
	if(g_UpdateFlagsHud) {
		
		new flagsTakenCTLen
		new flagsTakenTLen
		flagsTakenT[0] = 0
		flagsTakenCT[0] = 0
		
		for(ind = 0; ind < MAX_CSFLAGS; ind++) {
			
			if(g_FlagState[ind] == 1) {
				flagsTakenCTLen += format(flagsTakenCT[flagsTakenCTLen], 
							    HUD_FLAGS_STRING_MAXSIZE - flagsTakenCTLen,
							    "^n%s", g_PlaceNames[ind])
			} 
			else if(g_FlagState[ind] == 0) {
				flagsTakenTLen += format(flagsTakenT[flagsTakenTLen], 
							   HUD_FLAGS_STRING_MAXSIZE - flagsTakenTLen,
							   "^n%s", g_PlaceNames[ind])
			}
			
		}
	}
	
	// only reformat if there was an update
	if(g_UpdateFlagsHud || g_UpdateScoresHud) {
		formatex(scoreCT, 24 + HUD_FLAGS_STRING_MAXSIZE, "%s%s", headerCT, flagsTakenCT)
		formatex(scoreT, 24 + HUD_FLAGS_STRING_MAXSIZE, "%s%s", headerT, flagsTakenT)
	}
	
	// clean updates
	g_UpdateFlagsHud = false
	g_UpdateScoresHud = false
	
	// send hud messages
	for(ind = 1; ind <= g_MaxPlayers; ind++) {
		if(is_user_connected(ind)) {
			if(is_user_alive(ind)) {	
				set_hudmessage(255, 0, 0, 0.3, 0.0, 0, 6.0, INTERVAL_SCORE_UPDATE, 0.1, 0.2, 3)
				show_hudmessage(ind, scoreT)
				set_hudmessage(ind, 0, 255, 0.6, 0.0, 0, 6.0, INTERVAL_SCORE_UPDATE, 0.1, 0.2, 4)
				show_hudmessage(ind, scoreCT)
			}
			else {
				set_hudmessage(255, 0, 0, 0.3, 0.17, 0, 6.0, INTERVAL_SCORE_UPDATE, 0.1, 0.2, 3)
				show_hudmessage(ind, scoreT)
				set_hudmessage(ind, 0, 255, 0.6, 0.17, 0, 6.0, INTERVAL_SCORE_UPDATE, 0.1, 0.2, 4)
				show_hudmessage(ind, scoreCT)
			}
		}			
	}
}

remove_default_objectives() 
{
	new objectives[6][] = {
		"func_bomb_target",
		"info_bomb_target",
		"info_hostage_rescue",
		"func_hostage_rescue",
		"func_vip_safetyzone",
		"func_escapezone"
	}
	for(new i = 0; i < 6; i++)
		remove_all_ents(objectives[i])
}
		
add_user_frags(id, value, team)
{
	/*
	 * Taken from VEN's CTF,
	 * modified to fit this plugin
	 */
	
	new Float:frags
	new players[32]
	new playersnum
	static const fnTeamFilter[3][] = { "", "TERRORIST", "CT" }
	
	if(id) {
		playersnum = 1
		players[0] = id
	}
	else {
		if(team > 0 && team < 2)
			get_players(players, playersnum, "e",  fnTeamFilter[team])
		
		/*new tstr[16]
		if(team == (ID_TEAM_T + 1))
			formatex(tstr, 15, "TERRORIST")
		else if(team == (ID_TEAM_CT + 1))
			formatex(tstr, 15, "CT")
		get_players(players, playersnum, "e",  tstr)*/
	}	
	
	for(new i = 0; i < playersnum; i++) {
		pev(players[i], pev_frags, frags)
		frags += value
		set_pev(players[i], pev_frags, frags)
		
		message_begin(MSG_ALL, g_msgidScoreInfo)
		write_byte(players[i])
		write_short(floatround(frags))
		write_short(CS_GET_USER_DEATHS_(players[i]))
		write_short(0)
		write_short(team)
		message_end()
	}	
	
}
		
load_config() 
{
	new file[72]
	
	if(get_configfile(file, 71)) {
		new numbers[5][6]
		new Float:origin[3]
		new Float:angle[3]
		new line[96]		
		new arg1[16]
		new arg2[80]
		new hitbox
		new count		
		new flag
		new trigger
		new filepointer
		
		filepointer = fopen(file, "r")
		
		while(fgets(filepointer, line, 95) && count < MAX_CSFLAGS) {
			if(!strlen(line) || line[0] == ';')
				continue
			parse(line, arg1, 15, arg2, 79)
			
			if(!strlen(arg2))
				continue
				
			if(strlen(arg1))
				copy(g_PlaceNames[count], 15, arg1)
			else
				formatex(g_PlaceNames[count], 15, "Flag[%d]", count)
			
			parse	(arg2, 
				numbers[0], 5,
				numbers[1], 5,
				numbers[2], 5,
				numbers[3], 5,
				numbers[4], 5)
				
			origin[0] = str_to_float(numbers[0])
			origin[1] = str_to_float(numbers[1])
			origin[2] = str_to_float(numbers[2])
			angle[1] = str_to_float(numbers[3])
			hitbox = str_to_num(numbers[4])
			engfunc(EngFunc_MakeVectors, angle)
			
			flag = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "cycler_sprite"))
			
			if(pev_valid(flag)) {
				engfunc(EngFunc_SetOrigin, flag, origin)				
				set_pev(flag, pev_model, MODEL_FLAGS)
				dllfunc(DLLFunc_Spawn, flag)
				set_pev(flag, pev_framerate, 1.0)
				set_pev(flag, pev_classname, CLASSNAME_CSFLAG)
				set_pev(flag, pev_angles, angle)
				set_pev(flag, pev_csf_uniqueid, CSFLAG_TYPEID)			
				set_pev(flag, pev_csf_flagid, count)
				set_pev(flag, pev_csf_hitbox, hitbox)
				trigger = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "trigger_multiple"))
				
				origin[2]+=136.0
				g_Icon[flag] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "cycler_sprite"))
				engfunc(EngFunc_SetOrigin, g_Icon[flag], origin)				
				set_pev(g_Icon[flag], pev_model, gFlagIcon)
				set_pev(g_Icon[flag], pev_framerate, 1.0)
				set_pev(g_Icon[flag], pev_classname, CLASSNAME_CSFLAG)
				dllfunc(DLLFunc_Spawn, g_Icon[flag])
				origin[2]-=136.0
				
				/*message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
				write_byte(TE_PLAYERATTACHMENT);
				write_byte(flag);			// entity
				write_coord(36);			// vertical offset ( attachment origin.z = player origin.z + vertical offset )
				write_short(gIcon);			// model index
				write_short(36000);			// (life * 10 )
				message_end();*/
				
				if(pev_valid(trigger)) {
					origin[2] += 48.0
					engfunc(EngFunc_SetOrigin, trigger, origin)					
					dllfunc(DLLFunc_Spawn, trigger)
					engfunc(EngFunc_SetSize, trigger, g_mmSize[hitbox][HITBOX_MIN], g_mmSize[hitbox][HITBOX_MAX])
					set_pev(trigger, pev_csf_uniqueid, TRIGGERFLAG_TYPEID)
					set_pev(trigger, pev_classname, CLASSNAME_TRIGGER_FLAG)
					set_pev(trigger, pev_csf_flagent, flag)
					set_pev(trigger, pev_csf_flagid, count)
					set_pev(flag, pev_csf_trigger, trigger)
					
					
					g_TriggerOrigin[count][0] = origin[0]
					g_TriggerOrigin[count][1] = origin[1]
					g_TriggerOrigin[count][2] = origin[2]					
				}
				else {
					fclose(filepointer)
					return 0
				}
				if(count < MAX_CSFLAGS)
					count++
			}
			else {
				fclose(filepointer)
				return 0
			}
			flag = 0
			trigger = 0			
		}
		fclose(filepointer)
		
		if(count) {
			g_MapFlagsNum = count
			return 1
		}
		else
			return 0
	}
	return 0
}

get_configfile(file[], len) 
{
	new map[36]
	
	get_mapname(map, 35)
	get_configsdir(file, len)
	format(file[strlen(file)], len - strlen(file), FILE_DOMCFG, map)
	
	return file_exists(file)
}

// map time functions


/**
 * This is called when a csflags match is over, it's meant
 * to shorten the map left time to an acceptable time - to
 * do the voting maps or whatever. This delay is defined in
 * "amx_csflags_mapendtime" cvar.
 */
public force_end() 
{

#if defined DEBUG_MODE
	open_debug_file()
	print_stack(0, "server_changelevel")
#endif

	new Float:mplimit	// stores the current mp_timelimit
	mplimit = get_cvar_float("mp_timelimit")
	
	// I don't remember why the number of players was relevant
	// it make some sense anyway.
	if (get_playersnum() && mplimit != 0.0) {

		new Float:newlimit
		
		// calculates the new limit
		newlimit = mplimit - float(get_timeleft() / 60) + get_pcvar_float(g_cvarMapEndTime)
		
		// flags game state so mp_timelimit can be recovered before the
		// level changes
		g_CSFlagsState |= GAMESTATE_FORCEDEND
		
		// stores the old mp_timelimit into the global 
		g_OldMPTime = mplimit
		
		// attempts to launch a voting system
		// (if it's been defined)
		start_vote_cmd(0.0)
		
		// sets the new mp_time limit
		server_cmd("mp_timelimit %f", newlimit)		
		client_print(0,print_chat,"%s %s", MSG_HEADER, "%L", LANG_PLAYER, "MSG_CHANGEMAP_DELAY")

#if defined DEBUG_MODE
		printvar_float(0, "mplimit", mplimit)
		printvar_float(0, "newlimit", newlimit)
		close_debug_file()
#endif

	}
}

/**
 * Change level forward
 */
public server_changelevel(map[]) 
{
	
#if defined DEBUG_MODE
	open_debug_file()
	print_stack(0, "server_changelevel")
#endif
	
	// checks if one of these situations is true so an previously saved mp_timelimit must be restored:
	// 1) the match was over, it's been given some delay but now it's time to go
	// 2) there wasn't a winner, now it came up
	if((g_CSFlagsState & GAMESTATE_FORCEDEND || g_CSFlagsState & GAMESTATE_WAIT) && g_OldMPTime) {
		
		if (get_cvar_num("mp_timelimit") == get_pcvar_num(g_cvarMapEndTime)) {
			// restores the original value
			server_cmd("mp_timelimit %d", g_OldMPTime)

#if defined DEBUG_MODE
		print_comment(0, "setting mp_timelimit to g_OldMPTime", 1)
#endif
			 
			
		}
	}
#if defined DEBUG_MODE
	close_debug_file()
#endif
}

/**
 *  Checks if game end should be delayed because csflags match isn't over.
 *  This is called when it's missing 11 seconds to change level process.
 *  The amxmodx count down starts at 10, so that's why it's 11. 
 */
public set_mapend_mptimelimit() 
{	
#if defined DEBUG_MODE
	open_debug_file()
	print_stack(0, "set_mapend_mplimit")
#endif
	
	// confusing part; if statement was nested like that so
	// I could still have debug messages
	//
	// here's the first "if" description in the order statements are placed:
	// 1) csflags must have been started --> ok
	// 2) any of these case are true: 
	//    a) level being forced to end because of csflags match is over
	//    b) csflags match over
	//    c) csflags match is delaying the map time because it's waiting for a winner
	// 3) there are players (why am I checking this?)
	// 4) OldMPTime must not be set, added in 1.93
	// 5) the server has a level time limit --> would this function get called if not?
	// 6) what? why would that be disabled now?
	if( (g_CSFlagsState & GAMESTATE_STARTED) &&
	    !(g_CSFlagsState & (GAMESTATE_FORCEDEND | GAMESTATE_MATCHOVER | GAMESTATE_WAIT)) &&
	     get_playersnum() &&
	     g_OldMPTime == 0.0 &&
	     get_cvar_float("mp_timelimit") != 0.0 &&
	     get_pcvar_num(g_cvarDomEnabled)) {		
	 	
		// it doesn't allow tied matches
		if(!get_pcvar_num(g_cvarTieMatch)) {			
			
			// checks csflags match isn't over
			if(!map_should_end()) {
				
				// flags it to wait
				g_CSFlagsState |= GAMESTATE_WAIT
				
				// stores the current mp_timelimit
				g_OldMPTime = get_cvar_float("mp_timelimit")
				
				// set time limit to infinite
				server_cmd("mp_timelimit 0")
				
				// removing this task
				remove_task(TASKID_MAPEND) // <-- added in 1.93
				
				// attempts to launch a voting system
				// (if it's been defined)
				start_vote_cmd(0.0)

#if defined DEBUG_MODE
				print_comment(0, "waiting for a winner", 1)
				print_comment(0, "mp_timelimit = 0, gamestate |= GAMESTATE_WAIT", 1)
				printvar_float(0, "g_OldMPTime", g_OldMPTime)
#endif

				client_print(0, print_chat, "%L %L", LANG_PLAYER, "MSG_HEADER", LANG_PLAYER, "MSG_TIME_OVER")
			
			}

#if defined DEBUG_MODE
			else
				print_comment(0, "map_should_end returned 1, won't mess with time")
#endif
		}

#if defined DEBUG_MODE
		else
			print_comment(0, "Tie match enabled, won't mess with time", 1) 
#endif

	}

#if defined DEBUG_MODE
	else {
		print_comment(0, "At least one of these statements failed:", 1)
		printvar_cell(0, "g_CSFlagsState & GAMESTATE_STARTED", g_CSFlagsState & GAMESTATE_STARTED)
		printvar_cell(0, "!(g_CSFlagsState & GAMESTATE_FORCEDEND", !(g_CSFlagsState & GAMESTATE_FORCEDEND))
		printvar_cell(0, "!(g_CSFlagsState & GAMESTATE_MATCHOVER)", !(g_CSFlagsState & GAMESTATE_MATCHOVER))
		printvar_cell(0, "!(g_CSFlagsState & GAMESTATE_WAIT)", !(g_CSFlagsState & GAMESTATE_WAIT))
		printvar_cell(0, "get_playersnum()", get_playersnum())
		printvar_cell(0, "get_cvar_float(^"mp_timelimit^") != 0.0", get_cvar_float("mp_timelimit") != 0.0)
		printvar_cell(0, "get_playersnum()", get_playersnum())
		printvar_cell(0, "get_pcvar_num(g_cvarDomEnabled)", get_pcvar_num(g_cvarDomEnabled))
		
	}
	close_debug_file()
#endif
}

/**
 * Analyzes if there's a reason a map should end or not.
 * This functions doesn't consider the tie match configuration
 * in cvar for making the assertion.
 * @return 0 for negative, 1 for affirmative.
 */
map_should_end() 
{
	new maxwins = get_pcvar_num(g_cvarMaxWins)
	
	new tscore = g_TeamWins[ID_TEAM_T]
	new ctscore = g_TeamWins[ID_TEAM_CT]
	
	// 1) max wins must be a relevant condition (cvar)
	// 2) max wins must have been reached
	// 3) match must not be tied
	if((maxwins) ? (maxwins > ctscore && maxwins > tscore) || tscore == ctscore : tscore == ctscore)
		return 0
		
	return 1
}

public restore_mptimelimit() 
{
#if defined DEBUG_MODE
	open_debug_file()
	print_stack(0, "restore_mplimit")
	printvar_float(0, "g_OldMPTime", g_OldMPTime)
	printvar_cell(0, "get_cvar_num(^"mp_timelimit^")", get_cvar_num("mp_timelimit"))
	close_debug_file()
#endif

	g_CSFlagsState = GAMESTATE_STOPPED	
	if (get_cvar_num("mp_timelimit") == 0)
		server_cmd("mp_timelimit %f", g_OldMPTime)
}


// ---------------------------------------------------------------------------------------
// Debug tools

#if defined DEBUG_TOOLS

#define DEBUG_LINE 160

#define PRINT_MSG1(%1,%2,%3) format(debugMsg, 127, %2, %3); debug_print(%1, debugMsg)
#define PRINT_MSG2(%1,%2,%3,%4) format(debugMsg, 127, %2, %3, %4); debug_print(%1, debugMsg)
#define PRINT_MSG3(%1,%2,%3,%4,%5) format(debugMsg, 127, %2, %3, %4, %5); debug_print(%1, debugMsg)



public debug_gamestate(id, stack[])
{
	open_debug_file()
	
	if(stack[0]) 
		print_stack(id, stack)
	else
		print_stack(id)
	
	print_debug_cmd(id, "Game State tracing")
	
	PRINT_MSG1(id, "GAMESTATE_STARTED: %d", g_CSFlagsState & GAMESTATE_STARTED ? 1 : 0)
	PRINT_MSG1(id, "GAMESTATE_FORCEDEND: %d", g_CSFlagsState & GAMESTATE_FORCEDEND ? 1 : 0)
	PRINT_MSG1(id, "GAMESTATE_HUDREPEAT: %d", g_CSFlagsState & GAMESTATE_HUDREPEAT ? 1 : 0)
	PRINT_MSG1(id, "GAMESTATE_MATCHOVER: %d", g_CSFlagsState & GAMESTATE_MATCHOVER ? 1 : 0)
	PRINT_MSG1(id, "GAMESTATE_SHOWSCORE: %d", g_CSFlagsState & GAMESTATE_SHOWSCORE ? 1 : 0)
	PRINT_MSG1(id, "GAMESTATE_STOPPED: %d", g_CSFlagsState & GAMESTATE_STOPPED ? 1 : 0)
	PRINT_MSG1(id, "GAMESTATE_WAIT: %d", g_CSFlagsState & GAMESTATE_WAIT ? 1 : 0)
	
	close_debug_file()
}


open_debug_file()
{
#if defined DEBUG_FILE
	if(!pDebugFile)
		pDebugFile = fopen(DEBUG_FILE, "a+")
#endif
}
close_debug_file() {
#if defined DEBUG_FILE
	if(pDebugFile) {
		fclose(pDebugFile)
		pDebugFile = 0
	}
#endif
}
	

public debug_flags(id, stack[])
{
	new flag
	new trigger
	new Float:vector[3]
	new count
	
	open_debug_file()
	
	if(!stack[0]) 
		print_stack(id, stack)
	else
		print_stack(id)
	
	print_debug_cmd(id, "Flags Tracing")
	
	while((flag = engfunc(EngFunc_FindEntityByString, flag, "classname", CLASSNAME_CSFLAG))) {
		
		PRINT_MSG2(id, "***^nflagent: %d, flagid: %d", flag, pev(flag, pev_csf_flagid))
		PRINT_MSG1(id, "Flag name: %s", g_PlaceNames[pev(flag, pev_csf_flagid)])
		
		pev(flag, pev_origin, vector)
		PRINT_MSG3(id, "Origin: %f %f %f", vector[0], vector[1], vector[2])
		
		pev(flag, pev_angles, vector)
		PRINT_MSG3(id, "Angles: %f %f %f", vector[0], vector[1], vector[2])
		
		PRINT_MSG1(id, "Hitbox: %d", pev(flag, pev_csf_hitbox))
		PRINT_MSG1(id, "Owner: %d", pev(flag, pev_csf_flagowner))
		PRINT_MSG1(id, "Toucher: %d", pev(flag, pev_csf_flagtoucher))
		PRINT_MSG1(id, "Status: %d", pev(flag, pev_csf_flagstatus))
		PRINT_MSG1(id, "typeid: %d", pev(flag, pev_csf_uniqueid))	
		
		trigger = pev(flag, pev_csf_trigger)
		PRINT_MSG1(id, "Flag trigger:", trigger)
		
		if(pev_valid(trigger)) {
			pev(trigger, pev_origin, vector)
			PRINT_MSG3(id, "^tOrigin: %f %f %f", vector[0], vector[1], vector[2])
			
			pev(trigger, pev_maxs, vector)
			PRINT_MSG3(id, "^tMaxs(size): %f %f %f", vector[0], vector[1], vector[2])
			
			pev(trigger, pev_mins, vector)
			PRINT_MSG3(id, "^tMins(size): %f %f %f", vector[0], vector[1], vector[2])			
			
			PRINT_MSG1(id, "^tflagid(ref): %d", pev(trigger, pev_csf_flagid))
			PRINT_MSG1(id, "^tflagent(ref): %d", pev(trigger, pev_csf_flagent))
			PRINT_MSG1(id, "^ttypeid: %d", pev(trigger, pev_csf_uniqueid))			
		}
		else
			debug_print(id, "^t[invalid trigger entity]")
		
		count++
		
	}
	
	PRINT_MSG1(id, "--- Found %d flags", count)
	
	close_debug_file()
}

debug_print(id, const msg[])
{
	if(id)
		console_print(id, msg)
	else
		server_print(msg)
	
#if defined DEBUG_FILE
	if(pDebugFile) {
		fputs(pDebugFile, msg)
		fputs(pDebugFile, "^n")
	}
#endif // DEBUG_FILE
}

print_debug_cmd(id, cmd[])
{
	PRINT_MSG3(id, "%s^n%s CMD: %s", debugLine, debugHeader, cmd)
}

print_stack(id, stack[] = "Unknown", bool:opendfile = false)
{
	if(opendfile)
		open_debug_file()
	
	PRINT_MSG2(id, "^n%s Stack on %s", debugHeader, stack)
	
	if(opendfile)
		close_debug_file()
}

stock printvar_cell(id, const varname[], value)
{
	PRINT_MSG2(id, "^t[cell] %s = %d", varname, value)
}

stock printvar_float(id, const varname[], Float:value)
{
	PRINT_MSG2(id, "^t[float] %s = %f", varname, value)
}

stock printvar_string(id, const varname[], const value[])
{
	PRINT_MSG2(id, "^t[string] %s = %s", varname, value)
}

stock printvar_cell_array(id, const varname[], const array[], length)
{
	PRINT_MSG1(id, "^t[array] %s", varname)
	for(new i; i < length; i++)
		PRINT_MSG2(id, "^t^t[%d] = %d", array[i])  
}

stock printvar_float_array(id, const varname[], const Float:array[], length)
{
	PRINT_MSG1(id, "^t[array] %s", varname)
	for(new i; i < length; i++)
		PRINT_MSG2(id, "^t^t[%d] = %f", array[i])  
}

stock printvar_string_array(id, const varname[], const array[][], length)
{
	PRINT_MSG1(id, "^t[array] %s", varname)
	for(new i; i < length; i++)
		PRINT_MSG2(id, "^t^t[%d] = %s", array[i])  
}

stock print_comment(id, const comment[], tabnum = 0, bool:opendfile = false)
{
	new fmt[180]
	
	new len
	
	// why am I doing this?
	if(tabnum >= 16)
		tabnum = 15
	
	len = format(fmt, tabnum, Tabs)
	len += format(fmt, 179, "** %s", comment)
	
	if(opendfile)
		open_debug_file()
	
	debug_print(id, fmt)
	
	if(opendfile)
		close_debug_file()
}

#endif // DEBUG_TOOLS
