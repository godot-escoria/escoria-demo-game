extends ESCMigration

func migrate():
	self._savegame.globals["test"] = "testc"

