local obj = require"object"
local lang = require"language"

local Lsystem = obj.class()
function Lsystem:__init(grammar, axiom)
	axiom = lang.Sentence(axiom)
	self.sentence = axiom
	self.grammar = grammar
	self.axiom = axiom
end

function Lsystem:step()
	-- parse from left to right looking for a matching rule
	--for i = 1,# sentence do
	sentence = self.sentence
	local i = 1
	while i<=#sentence do -- allow us to continue looping while we add entries into the sentence table, instead of pairs() or for i... loops
		local sym  = sentence[i]
		for _,rule in pairs(self.grammar) do
			-- test if this rule could be applied here. returns nil if not.
			applied, i, sentence = rule:apply(sentence, i)
			if applied then break end -- only apply one rule for a certain position
		end
		i=i+1
	end
end

-- test data
local fibGrammar = lang.Grammar(
	{ lang.Rule({"a"},{"b"}),
	lang.Rule({"b"},{"a","b"})} )
local fib = Lsystem( fibGrammar, {"a"})

for _,rule in pairs(fibGrammar) do
	print(rule)
end


local turtleGrammar =  lang.StochasticGrammar(
	{ lang.Rule({"MOVE"}, {"N","MOVE", "S"}, .5),
	lang.Rule({"MOVE"}, {"E","MOVE", "W"}, .5),
	lang.Rule({"N","E"}, {"E", "N"}, .5),
	lang.Rule({"N","W"}, {"W", "N"}, .5),
	lang.Rule({"N","S"}, {"S", "N"}, .5),
	lang.Rule({"S","E"}, {"E", "S"}, .5),
	lang.Rule({"S","W"}, {"W", "S"}, .5),
	lang.Rule({"S","N"}, {"N", "S"}, .5),
	lang.Rule({"E","S"}, {"S", "E"}, .5),
	lang.Rule({"E","W"}, {"W", "E"}, .5),
	lang.Rule({"E","N"}, {"N", "E"}, .5),
	lang.Rule({"W","S"}, {"S", "W"}, .5),
	lang.Rule({"W","E"}, {"E", "W"}, .5),
	lang.Rule({"W","N"}, {"N", "W"}, .5)})
local turtle = Lsystem( turtleGrammar, {"MOVE"})
for _,rule in pairs(turtleGrammar) do
	print(rule)
end

local function exit()
	line = io.read("*l")
	return line == "q"
end
local function testSys(lsys)
print(lsys.axiom)
	while true do
		lsys:step()
		print(lsys.sentence)
		if  exit() then break end
	end
end

testSys(fib)
testSys(turtle)


	

return Lsystem -- return functions as a module
