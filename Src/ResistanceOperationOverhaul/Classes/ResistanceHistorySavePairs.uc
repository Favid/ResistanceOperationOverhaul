class ResistanceHistorySavePairs extends Object dependson(ResistanceOverhaulHelpers) config(ROOSaves);

struct ResistanceHistorySavePair
{
	var name Filename;
	var string DisplayName;
	var LadderSettings Settings;
};

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

	//`LOG("Saving name " $ NewName);
	
	for (i = 0; i < default.ResistanceSaves.Length; i++)
	{
		if (default.ResistanceSaves[i].DisplayName == NewName)
		{
			//`LOG("Name found, attempting to save in position " $ string(i));
			HSP = default.ResistanceSaves[i];

			default.ResistanceSaves[i].Settings = Settings;

			StaticSaveConfig();

			//`LOG("Save complete");

			return HSP.Filename;
		}
	}

	//`LOG("Name not found, making new save");

	HSP.Filename = name("ResistanceOp_" $ ++default.HistorySaveIndex);
	HSP.DisplayName = NewName;

	HSP.Settings = Settings;

	default.ResistanceSaves.AddItem(HSP);

	StaticSaveConfig();
	
	//`LOG("Save complete");

	return HSP.Filename;
}

static function LadderSettings GetFileSettings(name FileName)
{
	local int i;
	local LadderSettings LoadedSettings;

	//`log("=== Looking up file name:" @ FileName);

	for (i = 0; i < default.ResistanceSaves.Length; i++)
	{
		if (default.ResistanceSaves[i].Filename == FileName)
		{
			//`log("=== found ladder length:" @ i @ default.ResistanceSaves[i].LadderLength);
			LoadedSettings = default.ResistanceSaves[i].Settings;
			break;
		}
	}

	return LoadedSettings;
}