local obj = require"object"
local lang = require"language"

local Lsystem = obj.class()
function Lsystem:__init(grammar, axiom)
	axiom = lang.Sentence(axiom)
	self.sentence = axiom
	self.grammar = grammar
	self.axiom = axiom
end

function Lsystem:step(n)
	-- parse from left to right looking for a matching rule
	--for i = 1,# sentence do
	n = n or 1
	if n <= 1 then return self.sentence end

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
	self.sentence = sentence -- should not be necessary as rule:apply modifies sentence in place
	print(self.sentence)
	return self:step(n-1)
end

return Lsystem -- return functions as a module
