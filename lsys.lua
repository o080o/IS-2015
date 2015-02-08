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
	if n < 1 then return self.sentence end

	local sentence = self.sentence
	local newSentence = lang.Sentence()
	local i = 1
	while i<=#sentence do -- allow us to skip over replaced symbols by adjusting i
		local sym  = sentence[i]
		local matched = false
		for _,rule in pairs(self.grammar) do
			-- test if this rule could be applied here. returns nil if not.
			local applicable, n, successor = rule:apply(sentence, i)
			if applicable then
				matched = true
				i = i + n 
				for _, s in ipairs(successor) do
					table.insert( newSentence, s)
				end
				break -- only apply one rule for a certain position
			end
		end
		if not matched then -- apply the identity rule instead
			table.insert(newSentence, sym)
			i=i+1
		end
	end
	self.sentence = newSentence
	print(self.sentence)
	return self:step(n-1)
end

return Lsystem -- return functions as a module
