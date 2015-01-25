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
local fib = Lsystem( lang.Grammar(
	{ lang.Rule({"a"},{"b"}),
	lang.Rule({"b"},{"a","b"})} ), {"a"})

local turtle = Lsystem( lang.Grammar(
	{ lang.Rule({"MOVE"}, {"N","MOVE", "S"}),
	lang.Rule({"MOVE"}, {"E","MOVE", "W"})}
), {"MOVE"})

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
