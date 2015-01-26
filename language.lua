-- [a] is a List of a's
-- {a} is an unordered set of a's
-- (a,b,c,...) is a tuple
--
-- Symbol is Key
-- Sentence is [Symbol]
-- Rule is ( [Symbol], [Symbol] )
-- Grammar is [Rule]

local o = require("object")
local types = require("types") -- some generic data structures

local lang = {} -- module table

local Sentence = o.class()
lang.Sentence = Sentence -- export this object in the module

--constructor Sentence( [Symbol] symbols )
function Sentence:__init(symbols)
	for k,s in ipairs(symbols) do
		self[k] = s
	end
end
-- function Sentence:__tostring()
-- return String the entire sentence with a space between each symbol
function Sentence:__tostring()
	local s = {}
	for _,sym in ipairs(self) do -- loop over all symbols, compiling a list of strings
		table.insert(s, tostring(sym))
		table.insert(s, " ")
	end
	return table.concat(s) -- concatenate the produced list of strings
end
--function Sentence:isSentential( {Symbol} nonterminals ) 
--return Boolean true if the sentence is a sentential form, false otherwise (if
--there are no non-terminal symbols in the sentence)
function Sentence:isSentenial(nonterminals)
	local sentential = false
	for _,sym in pairs(self) do -- loop over all symbols, checking for any nonterminals
		sentential = sentential or nonterminals[ sym ] 
	end
	return sentential
end

local Rule = o.class()
lang.Rule = Rule --export the Rule object in the module

-- constructor Rule( [Symbol] predecessor, [Symbol] successor)
function Rule:__init(predecessor, successor, probability)
	assert(predecessor, "Rule constructor: No predecessor given")
	assert(successor, "Rule constructor: No sucessor given")
	self.predecessor = predecessor 
	self.successor = successor
	self.probability = probability -- may be nil for deterministic grammars
	self[1] = self.predecessor
	self[2] = self.successor
end
--function Rule:__tostring()
function Rule:__tostring()
	local s = {}
	for _,sym in pairs(self.predecessor) do
		table.insert(s, tostring(sym))
		table.insert(s, " ")
	end
	table.insert(s, "-> ")
	for _,sym in pairs(self.successor) do
		table.insert(s, tostring(sym))
		table.insert(s, " ")
	end
	return table.concat(s)
end
--function Rule:apply( Sentence s, Int pos)
--  modifies the sentence, *s*, in place by applying the rule at a given
--  position
-- 	return:
-- 		Boolean success -  true if the rule was applied
--		Int new_pos - the position in the new sentence of the last symbol added by the rule, or *pos* if the rule was not applied
-- 		Sentence new_s -  the new sentence, or *s* if the rule was not applied
function Rule:apply(s, pos)
	-- test if this rule can be applied
	local match = true
	local i = pos
	for _, sym in pairs(self.predecessor) do
		if s[i] ~= sym then 
			match = false
			break
		end
	end
	if match then
		for n=1,#self.predecessor do table.remove(s, pos) end -- remove the predecessor from the sentence
		for n=#self.successor, 1, -1 do table.insert(s, pos, self.successor[n]) end -- insert the successor into the sentence
		return true, pos + #self.successor - 1, s
	else
		return false, pos, s
	end
end


local Grammar = o.class()
lang.Grammar = Grammar

--constructor Grammar( [Rule] )
function Grammar:__init(rules)
	for k,v in pairs(rules) do
		self[k] = v
	end
end
-- function Grammar:nonTerminals() return {Symbol}
 function Grammar:nonTerminals()
	local nonterminals = {}
	for _,rule in pairs(self) do
		for _,sym in pairs(rule.predecessor) do
			nonterminals[sym] = true
		end
	end
	return nonterminals
end

--local StochasticGrammar = o.class(Grammar, o.autoGetter)
-- data StochasticGrammar = [Bucket]
local StochasticGrammar = o.class(Grammar)
lang.StochasticGrammar = StochasticGrammar

function StochasticGrammar:__init(rules)
	buckets = self:bucketize(rules)
	for _,bucket in pairs(buckets) do
		table.insert(self, bucket)
	end
	self:normalize()
end

--data Bucket = [Rule]
local Bucket = o.class()
function Bucket:__init(...)
	for _,rule in pairs( {...} ) do
		table.insert(self, rule)
	end
end
function Bucket:apply(sentence, i)
	--randomly pick a rule to apply
	local r = math.random()
	for _, rule in ipairs(self) do
		print("P:", rule, rule.probability, r)
		if (rule.probability or 0) <= r then
			return rule:apply(sentence, i)
		else
			r = r + (rule.probability or 0)
		end
	end
	print(r)
	error("no rule tested in Bucket:applyRule()")
	return sentence, i
end
--function normalize( Bucket )
-- normalizes the probabilities of all of the rules to add up to 100%. 
function Bucket:normalize()
	-- find the sum...
	local sum = 0
	for _,rule in ipairs(self) do
		sum = sum + (rule.probability or 0)
	end
	factor = 1/sum -- factor to scale each probability
	for _,rule in ipairs(self) do
		if rule.probability then rule.probability = rule.probability * factor 
		else rule.probability = 0 end
	end
end

--function StochasticGrammar:bucketize()
--groups all the individual rules in to buckets, where all the rules in a
--bucket have the same predecessor
--return [Bucket] a list of all the "buckets" in the grammar
function StochasticGrammar:bucketize(rules)
	local buckets = {}
	local testTree = types.LookupTree()
	local n = 1
	for _, rule in pairs(rules) do
		local val = testTree:get(rule.predecessor)
		if val then
			table.insert( buckets[val], rule)
		else
			local key = n
			n = n + 1 -- by using increasing integer keys, we will end up with a list of lists! == [[Rule]]
			testTree:set(rule.predecessor, key) -- put a unique table into the lookup tree, which will be used as a key into the the buckets table later
			buckets[key] = Bucket(rule)
		end
	end
	return buckets
end
-- normalize the probability of each bucket in the grammar
function StochasticGrammar:normalize()
	-- step 1. make a list for each unique predecessor, then normalize each
	for _, bucket in pairs(self) do
		bucket:normalize()
	end
end

-- some tests
--
lt = types.LookupTree()
print(":", lt:get({"a", "b", "c"}))
lt:set({"a", "b", "c"}, "HOORAY!")
print(":", lt:get({"a", "b", "c"}))
lt:set({"a", "b", "c"}, "Hoorah!")
print(":", lt:get({"a", "b", "c"}))

return lang -- return the module
