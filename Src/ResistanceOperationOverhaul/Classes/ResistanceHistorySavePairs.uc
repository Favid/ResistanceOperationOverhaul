class ResistanceHistorySavePairs extends Object config(ROOSaves);

var config array<ResistanceHistorySavePair> ResistanceSaves;
var config int HistorySaveIndex;

static function int GetHistory(out array<name> filenames, out array<string> displaynames)
{
	local ResistanceHistorySavePair HSP;
	local int i;

	foreach default.ResistanceSaves(HSP)
	{
		filenames.AddItem(HSP.Filename);
		displaynames.AddItem(HSP.DisplayName);
		i++;
	}

	return i;
}

// returns new file name
static function name SaveHistory(string NewName, LadderSettings Settings)
{
	local int i;
	local ResistanceHistorySavePair HSP;

	`LOG("Saving name " $ NewName, class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);
	
	for (i = 0; i < default.ResistanceSaves.Length; i++)
	{
		if (default.ResistanceSaves[i].DisplayName == NewName)
		{
			`LOG("Name found, attempting to save in position " $ string(i), class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);
			HSP = default.ResistanceSaves[i];

			default.ResistanceSaves[i].Settings = Settings;

			StaticSaveConfig();

			`LOG("Save complete", class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);

			return HSP.Filename;
		}
	}

	`LOG("Name not found, making new save", class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);

	HSP.Filename = name("ResistanceOp_" $ ++default.HistorySaveIndex);
	HSP.DisplayName = NewName;

	HSP.Settings = Settings;

	default.ResistanceSaves.AddItem(HSP);

	StaticSaveConfig();
	
	`LOG("Save complete", class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);

	return HSP.Filename;
}

static function LadderSettings GetFileSettings(name FileName)
{
	local int i;
	local LadderSettings LoadedSettings;

	`LOG("Looking up file name:" @ FileName, class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);

	for (i = 0; i < default.ResistanceSaves.Length; i++)
	{
		if (default.ResistanceSaves[i].Filename == FileName)
		{
			`LOG("Settings found", class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);
			LoadedSettings = default.ResistanceSaves[i].Settings;
			break;
		}
	}

	return LoadedSettings;
}