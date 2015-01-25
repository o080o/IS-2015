-- [a] is a List of a's
-- {a} is an unordered set of a's
-- (a,b,c,...) is a tuple
--
-- Symbol is Key
-- Sentence is [Symbol]
-- Rule is ( [Symbol], [Symbol] )
-- Grammar is [Rule]

local o = require("object")

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
function Rule:__init(predecessor, successor)
	assert(predecessor, "Rule constructor: No predecessor given")
	assert(successor, "Rule constructor: No sucessor given")
	self.predecessor = predecessor 
	self.successor = successor
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

local StochasticGrammar = o.lazyClass(Grammar)
lang.StochasticGrammar = StochasticGrammar

function StochasticGrammar.__init(rules)
	self:super(rules)
	self:normalize()
end

function StochasticGrammar:lazyBuckets(self)
	buckets = self:bucketize()
	self.buckets = buckets
	return buckets
end

local LookupTreeMT = {}
local LookupTree = o.class(LookupTreeMT)
function LookUpTreeMT:__index(key)
	-- use "value" a special value that will *not* be affected by this
	-- metamethod.
	if key == "value" then
		return nil
	else
	-- put a new tree into this blank index
	self[key] = LookupTree()
	return self[key]
	end
end

function LookupTree:get(list, n)
	n = n or 1
	if n > #list then
		return self.value
	else
		self[list[n]]:get(list, (n) + 1)
	end
end
function LookupTree:set(list, value, n)
	n = n or 1
	if n > #list then
		self.value = value
	else
		self[list[n]]:set(list, (n) + 1, value)
	end
end

--function normalize( [Rule])
-- normalizes the probabilities of all of the rules to add up to 100%. 
local function normalizeRules(rules)
	-- find the sum...
	for _,rule in pairs(rules) do
		sum = sum + (rule.probability or 0)
	end
	factor = 1/sum -- factor to scale each probability
	for _,rule in pairs(rules) do
		if rule.probability then rule.probability = rule.probability * factor 
		else rule.probability = 0 end
	end
end

function StochasticGrammar:bucketize()
	local buckets = {}
	local testTree = LookupTree()
	local n = 1
	for _, rule in pairs(self.rules) do
		local val = testTree:get(rule.predecessor)
		if val then
			table.insert( bucket[val], rule)
		else
			local key = n
			n = n + 1 -- by using increasing integer keys, we will end up with a list of lists! == [[Rule]]
			testTree:set(rule.predecessor, key) -- put a unique table into the lookup tree, which will be used as a key into the the buckets table later
			buckets[key] = {rule}
		end
	end
end
function StochasticGrammar:normalize()
	-- step 1. make a list for each unique predecessor, then normalize each
	for _, bucket in pairs(self.buckets) do
		normalizeRules(bucket)
	end
end

return lang -- return the module
