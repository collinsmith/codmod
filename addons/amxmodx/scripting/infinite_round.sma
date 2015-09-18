
   /* - - - - - - - - - - -

        AMX Mod X script.

          | Author  : Arkshine
          | Plugin  : Infinite Round
          | Version : v1.0.0

        (!) Support : http://forums.alliedmods.net/showthread.php?t=117782

        This plugin is free software; you can redistribute it and/or modify it
        under the terms of the GNU General Public License as published by the
        Free Software Foundation; either version 2 of the License, or (at
        your option) any later version.

        This plugin is distributed in the hope that it will be useful, but
        WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
        General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this plugin; if not, write to the Free Software Foundation,
        Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

        ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

        Description :
        - - - - - - -
            With this plugin the round never ends whatever the situation.
            It doesn't use bots like others plugins, it just blocks some CS functions.


        Requirement :
        - - - - - - -
            * CS 1.6 / CZ(?).
            * AMX Mod X 1.8.x or higher.
            * Orpheu 2.1 and higher.

            
        Command :
        - - - - - 
            * infiniteround_toggle <0|1> // Toggle the plugin state. Enable/disable properly the forward and memory patch.
            
            
        Changelog :
        - - - - - -
            v1.0.0 : [ 4 jan 2010 ]

                (+) Initial release.
                
        Notes :
        - - - -
            * It was not tested under CZ on windows, if someone could confirm it works, I will appreciate.
            * The next version I will probably add a feature to hide the timer or to synchronize it with mp_timelimit if value not > 99.
            * Such plugin is useful only in deathmatch environment where players respawn infinitely.

    - - - - - - - - - - - */

    #include <amxmodx>
    #include <amxmisc>
    #include <orpheu>
    #include <orpheu_memory>

    
    /* PLUGIN INFORMATIONS */
    
        #define PLUGIN_NAME     "Infinite Round"
        #define PLUGIN_VERSION  "1.0.0"
        #define PLUGIN_AUTHOR   "Arkshine"
        
    
    /* ORPHEU HOOK HANDLES */

        new OrpheuHook:handleHookCheckMapConditions;
        new OrpheuHook:handleHookCheckWinConditions;
        new OrpheuHook:handleHookHasRoundTimeExpired;


    /* CONSTANTS */

        new memoryIdentifierRoundTime[] = "roundTimeCheck";

        enum /* plugin state */
        {
            DISABLED = 0,
            ENABLED
        };


    /*  VARIABLES */

        new currentPluginState = ENABLED;
        new bool:isLinuxServer;


    public plugin_init()
    {
        register_plugin( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );
        register_cvar( "infiniteround_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );
        
        register_concmd( "infiniteround_toggle", "ConsoleCommand_TogglePlugin", ADMIN_RCON, "<0|1> - Toggle plugin state" );

        isLinuxServer = bool:is_linux_server();

        state disabled;
        EnableForwards();
    }


    /**
     *  Command to toggle the plugin state,
     *  then to enable/disable properly the forwards used.
     */
    public ConsoleCommand_TogglePlugin ( const player, const level, const cid )
    {
        if ( cmd_access( player, level, cid, 2 ) )
        {
            new newPluginState[ 2 ];
            read_argv( 1, newPluginState, charsmax( newPluginState ) );

            new statePluginWanted = clamp( str_to_num( newPluginState ), DISABLED, ENABLED );

            switch ( statePluginWanted )
            {
                case DISABLED : DisableForwards();
                case ENABLED  : EnableForwards();
            }

            new message[ 128 ];

            ( currentPluginState == statePluginWanted ) ?

                formatex( message, charsmax( message ), "%s", statePluginWanted ? "Plugin already enabled!" : "Plugin already disabled!" ) :
                formatex( message, charsmax( message ), "%s", statePluginWanted ? "Plugin is now enabled!"  : "Plugin is now disabled!"  );

            ( player ) ?

                console_print( player, message ) :
                server_print( message );

            currentPluginState = statePluginWanted;
        }

        return PLUGIN_HANDLED;
    }


    /**
     *  The plugin was disabled. A user has enabled the plugin with the command.
     *  Enable properly all the forwards and patch the memory for windows only.
     */
    public EnableForwards () <> {}
    public EnableForwards () <disabled>
    {
        handleHookCheckMapConditions = OrpheuRegisterHook( OrpheuGetFunction( "CheckMapConditions" , "CHalfLifeMultiplay" ), "CheckConditions" );
        handleHookCheckWinConditions = OrpheuRegisterHook( OrpheuGetFunction( "CheckWinConditions" , "CHalfLifeMultiplay" ), "CheckConditions" );

        if ( isLinuxServer )
        {
            handleHookHasRoundTimeExpired = OrpheuRegisterHook( OrpheuGetFunction( "HasRoundTimeExpired" , "CHalfLifeMultiplay" ), "CheckConditions" );
        }
        else
        {
            /*
                | Windows - CHalfLifeMultiplay::HasRoundTimeExpired() is somehow integrated in CHalfLifeMultiplay::Think(),
                | we must patch soem byte directly into this funtion to avoid the check. Ugly trick but no choice.
                | 0x90 = NOP = does nothing. Don't modify the values.
            */

            BytesToReplace( memoryIdentifierRoundTime, { 0x90, 0x90, 0x90 } );
        }

        state enabled;
    }


    /**
     *  The plugin was enabled. A user has disabled the plugin with the command.
     *  Disable properly all the forwards and patch the memory for windows only.
     */
    public DisableForwards () <> {}
    public DisableForwards () <enabled>
    {
        OrpheuUnregisterHook( handleHookCheckMapConditions );
        OrpheuUnregisterHook( handleHookCheckWinConditions );

        if ( isLinuxServer )
        {
            OrpheuUnregisterHook( handleHookHasRoundTimeExpired );
        }
        else
        {
            /*
                | Windows - We restore the original value.
                | We restart to reinitialize the game.
                | Don't modify the values.
            */

            BytesToReplace( memoryIdentifierRoundTime, { 0xF6, 0xC4, 0x41 } );
        }

        state disabled;
    }


    /**
     *  Block CHalfLifeMultiplay::CheckMapConditions() and CHalfLifeMultiplay::CheckWinConditions(),
     *  and CHalfLifeMultiplay::HasRoundTimeExpired() so the round won't stop whatever the situation.
     */
    public OrpheuHookReturn:CheckConditions () <> { return OrpheuIgnored; }
    public OrpheuHookReturn:CheckConditions () <enabled>
    {
        OrpheuSetReturn( false );
        return OrpheuSupercede;
    }


    /**
     *  Replace at a specific memory address a value byte by byte.
     *
     *  @param identifier       The name of the block that qualifies memory.
     *  @param bytes            The bytes we want to patch.
     */
    stock BytesToReplace ( identifier[], const bytes[], const bytesLength = sizeof bytes )
    {
        new address;
        OrpheuMemoryGet( identifier, address );

        for ( new i; i < bytesLength; i++)
        {
            OrpheuMemorySetAtAddress( address, "roundTimeCheck|dummy", 1, bytes[ i ], address );
            address++;
        }

        /* 
            | It needs to reiniatiliaze some things. 
        */
        server_cmd( "sv_restart 1" );
    }
