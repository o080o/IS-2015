local lang = require"language"
local Lsystem = require("lsys")

local systems = {}

local fig1_25_grammar = lang.Grammar({
	lang.Rule({"A"}, lang.string( "[&FL!A]/////'[&FL!A]///////'[&FL!A]")),
	lang.Rule({"F"}, lang.string("S/////F")),
	lang.Rule({"S"}, lang.string("FL"))
})
systems.fig1_25 = Lsystem( fig1_25_grammar, {"A"})

local fig1_26_grammar = lang.Grammar({
	lang.Rule({"plant"}, { "internode", "+", "[", "plant", "+", "flower", "]", "-", "-", "/", "/",
		"[","-","-","leaf","]","internode","[","+","+","leaf","]","-",
		"[","plant","flower","]","+","+","plant","flower"}),
	lang.Rule({"internode"}, {"F", "seg", "[","/","/","&","&","leaf","]","[","/","/","^","^","leaf","]","F","seg"}),
	lang.Rule({"seg"}, {"seg","F","seg"})
})
systems.fig1_26 = Lsystem( fig1_26_grammar, {"plant"})


return systems
