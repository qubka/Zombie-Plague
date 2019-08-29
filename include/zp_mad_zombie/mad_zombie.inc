
public SharedPlugin __pl_myfile =
{
	name = "madness",
	file = "zp_extraitem_madness.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

/**
 * @brief Checks if player is mad zombie.
 *
 * @param client            The client index.
 *
 * @return                  true if player is mad zombie.
 **/
native bool ZP_IsMadZombie(int client);
