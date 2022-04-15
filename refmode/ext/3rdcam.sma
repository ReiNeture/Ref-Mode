
    #include <amxmodx>
    #include <fakemeta>

    new const g_sCamclass[] = "PlayerCamera";

    public plugin_init()
    {
        register_clcmd( "say /cam", "cmdCam" );
        register_forward( FM_Think, "Think_PlayerCamera" );
    }

    public cmdCam( id )
        Create_PlayerCamera( id );

    Create_PlayerCamera( id )
    {
        new iEnt; static const sClassname[] = "classname";
        while( ( iEnt = engfunc( EngFunc_FindEntityByString, iEnt, sClassname, g_sCamclass ) ) != 0 )
        {
            if( pev( iEnt, pev_owner) == id )
            {
                engfunc( EngFunc_SetView, id, iEnt );
                return;
            }
        }

        static const sInfo_target[] = "info_target";
        iEnt = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, sInfo_target ) )

        if( !iEnt )
            return;
        
        static const sCam_model[] = "models/w_usp.mdl";
        set_pev( iEnt, pev_classname, g_sCamclass );
        engfunc( EngFunc_SetModel, iEnt, sCam_model );

        set_pev( iEnt, pev_solid, SOLID_TRIGGER );
        set_pev( iEnt, pev_movetype, MOVETYPE_FLY );
        set_pev( iEnt, pev_owner, id );

        set_pev( iEnt, pev_rendermode, kRenderTransTexture );
        set_pev( iEnt, pev_renderamt, 0.0 );

        engfunc( EngFunc_SetView, id, iEnt );
        set_pev( iEnt, pev_nextthink, get_gametime() );
    }

    public Think_PlayerCamera( iEnt )
    {
        static sClassname[32];
        pev( iEnt, pev_classname, sClassname, sizeof sClassname - 1 );

        if( !equal( sClassname, g_sCamclass ) )
            return FMRES_IGNORED;

        static iOwner;
        iOwner = pev( iEnt, pev_owner );

        if( !is_user_alive( iOwner ) )
            return FMRES_IGNORED;

        static iButtons;
        iButtons = pev( iOwner, pev_button );

        if( iButtons & IN_USE )
        {
            engfunc( EngFunc_SetView, iOwner, iOwner );
            engfunc( EngFunc_RemoveEntity, iEnt );
            return FMRES_IGNORED;
        }

        static Float:fOrigin[3], Float:fAngle[3];
        pev( iOwner, pev_origin, fOrigin );
        pev( iOwner, pev_v_angle, fAngle );

        static Float:fVBack[3];
        angle_vector( fAngle, ANGLEVECTOR_FORWARD, fVBack );

        fOrigin[2] += 20.0;

        fOrigin[0] += ( -fVBack[0] * 150.0 );
        fOrigin[1] += ( -fVBack[1] * 150.0 );
        fOrigin[2] += ( -fVBack[2] * 150.0 );

        engfunc( EngFunc_SetOrigin, iEnt, fOrigin );

        set_pev( iEnt, pev_angles, fAngle );
        set_pev( iEnt, pev_nextthink, get_gametime() );

        return FMRES_HANDLED;
    }