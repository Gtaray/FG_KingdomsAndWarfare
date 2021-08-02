-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerOptions();
end

function registerOptions()
    -- Mark reaction uses when a unit makes a test out of their turn
    OptionsManager.registerOption2("MROT", true, "option_header_kw", "option_label_MROT", "option_entry_cycler", 
        { labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
    -- Print notification in chat if someone is rolling a test off-turn and they've used their reaction
    OptionsManager.registerOption2("DROT", true, "option_header_kw", "option_label_DROT", "option_entry_cycler", 
        { labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
end