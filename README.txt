Commands:
pressing m opens classes menu
/class
/menu
/barracks
/stats or /mystats
/killstreak or /ks (executes killstreak command, highest to lowest)

Admin Commands:
cod_addxp <name> <amount>
cod_addstats <name> <csw> <headshot=1> <stats>

CVARS:
mw2_savetype "1" //Save method 0 - IP // 1 - Steam ID
mw2_doublexp "0" //Turns on/off double XP, needs change in amxx.cfg
mw2_winnumber "10000" //Number to win Team deathmatch

//Copy these to amxx.cfg as is, don't fuck with this
//Orpheu, no end rounds
infiniteround_toggle 1

//Domination
amx_csflags_enabled 1
amx_csflags_max_wins 1
amx_csflags_max_points 200
amx_csflags_tiematch 0
amx_csflags_allflags_win 0
amx_csflags_mapendtime 0
amx_csflags_remove_map_obj 1
amx_csflags_capturefrags 0
amx_csflags_winfrags 0
amx_csflags_respawn 0
amx_csflags_capturedelay 15
amx_csflags_freeze 0

//FB Controller (no team flashes, also for detecting nades/timers)
frc_enable 1
frc_sound 1
frc_adminchat 0
frc_block_team_flash 1
frc_block_self_flash 0
frc_block_special_flash 0
frc_flasher_punish 0
frc_bug_fix 0
frc_color_mode 1
frc_red_color 255
frc_green_color 255
frc_blue_color 255
frc_dynamic_light 1