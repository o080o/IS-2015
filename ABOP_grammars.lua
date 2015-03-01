local lang = require"language"
local Lsystem = require("lsys")

local systems = {}

local fig1_25_grammar = lang.Grammar({
	lang.Rule("A", lang.string( "[&FL!A]/////'[&FL!A]///////'[&FL!A]")),
	lang.Rule("F", lang.string("S/////F")),
	lang.Rule("S", lang.string("FL"))
})
systems.fig1_25 = Lsystem( fig1_25_grammar, {"A"})

local fig1_26_grammar = lang.Grammar({
	lang.Rule("plant", { "internode", "+", "[", "plant", "+", "flower", "]", "-", "-", "/", "/",
		"[","-","-","leaf","]","internode","[","+","+","leaf","]","-",
		"[","plant","flower","]","+","+","plant","flower"}),
	lang.Rule("internode", {"F", "seg", "[","/","/","&","&","leaf","]","[","/","/","^","^","leaf","]","F","seg"}),
	lang.Rule("seg", {"seg","F","seg"})
})
systems.fig1_26 = Lsystem( fig1_26_grammar, {"plant"})

--[[
systems.fig1_31_b_grammar = lang.Grammar({
	lang.CSRule(lang.string("000"), lang.string("010"))
	lang.CSRule(lang.string("001"), lang.string("01[-F1F1]0"))
	lang.CSRule(lang.string("010"), lang.string("010"))
	lang.CSRule(lang.string("011"), lang.string("011"))
	lang.CSRule(lang.string("100"), lang.string("100"))
	lang.CSRule(lang.string("101"), lang.string("11F11"))
	lang.CSRule(lang.string("110"), lang.string("110"))
	lang.CSRule(lang.string("111"), lang.string("101"))
--]]

local cstest_grammar = lang.Grammar({
	lang.CSRule(lang.string("ba"), lang.string("bb")),
	lang.CSRule(lang.string("b"), lang.string("a"))
})
systems.cstest = Lsystem( cstest_grammar, lang.string("baaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))

local ST = 3.9
local CT = .4
local HC = 900
local fig1_35_grammar = lang.Grammar({
	lang.ParRule("F", function(s,t,c) return t==1 and s>=6 end, {lang.ParSym("F", function(s,t,c) return {s/3*2, 2, c} end), lang.ParSym("f", function(...)return 1 end), lang.ParSym("F", function(s,t,c) return s/3, 1, c end)}),
	lang.ParRule("F", function(s,t,c) return t==2 and s>=6 end, {lang.ParSym("F", function(s,t,c) return {s/3, 2, c} end), lang.ParSym("f", function(...)return 1 end), lang.ParSym("F", function(s,t,c) return s/3*2, 1, c end)}),
	lang.CSParRule(lang.string("FF"), function(s1, s2) local s,t,c = table.unpack(s2); return s>ST or c>CT end,
		{lang.ParSym("F", function(s1,s2) local s,t,c = table.unpack(s2); local h,i,k = table.unpack s1;return {s+.1, t, c+.025*(k+r-3*c)} end)}),
	lang.CSParRule(lang.string("FF"), function(s1, s2) local s,t,c = table.unpack(s2); return not(s>ST or c>CT) end,
		{lang.ParSym("F", function(...) return {0,0,HC} end), 
		"~",
		lang.ParSym("H", function(...) return {1} end)}),
	lang.ParRule("H", function(s) return s<3 end, {ParSym("H", function(s) return {s*1.1} end)})

})



return systems
