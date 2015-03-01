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

-- function lang.string( String ) return [String] a list of characters in the
-- string. Useful to convert a string into a list of symbols to create
-- grammars, sentences, etc.
function lang.string( str )
	list = {}
	for c in str:gmatch(".") do
		table.insert( list, c )
	end
	return list
end

local Sentence = o.class()
lang.Sentence = Sentence -- export this object in the module

--constructor Sentence( [Symbol] symbols )
function Sentence:__init(symbols)
	symbols = symbols or {}
	if type(symbols) == "string" then symbols=lang.string(symbols) end
	for k,s in ipairs(symbols) do
		self[k] = s
	end
end
-- function Sentence:read( {Function (Int, Symbol)} alphabet )
-- read through the sentence, for each symbol calling the associated function
-- in the alphabet table
function Sentence:read(alphabet)
	for i,sym in ipairs(self) do
		if alphabet[sym] then alphabet[sym]() end
	end
end
--function Sentence:append( Sentence )
-- append the given sentence to the end of this sentence
function Sentence:append( sentence )  
	for _, sym in ipairs(sentence) do
		table.insert( self, sym)
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
function Sentence:isSentential(nonterminals)
	local sentential = false
	for _,sym in ipairs(self) do -- loop over all symbols, checking for any nonterminals
		sentential = sentential or nonterminals[ sym ] 
	end
	return sentential
end

local ParSentence = o.class(Sentence)
lang.ParSentence = ParSentence
function ParSentence:__tostring()
	local s = {}
	for i=1,#self do
		local sym, par = self[i], self.parameters[i]
		table.insert(s, tostring(sym))
		if par then
			table.insert(s, "(")
			for _,val in ipairs(par) do
				table.insert(s, tostring(val))
				table.insert(s, ",")
			end
			table.insert(s, ")")
		end
		table.insert(s, " ")
	end
	return table.concat(s) -- concatenate the produced list of strings
end
function ParSentence:__init(...)
	Sentence.__init(self,...)
	self.parameters = {}
end
function ParSentence:read(alphabet)
	local params = self.parameters
	for i,sym in ipairs(self) do
		if params[i] then
			if unpack then -- test for lua 5.1/5.2 versions
				if alphabet[sym] then alphabet[sym](unpack(params[i])) end
			else
				if alphabet[sym] then alphabet[sym](table.unpack(params[i])) end
			end
		else
			if alphabet[sym] then alphabet[sym]() end
		end
	end
end
function ParSentence:append( sentence )  
	local len = #self
	for i, sym in ipairs(sentence) do
		table.insert( self, sym)
		if sentence.parameters then
			self.parameters[#self] = sentence.parameters[i]
		end
	end
	--for pos, par in pairs(sentence.parameters) do
		--self.parameters[pos + len] = par
	--end
end

local Rule = o.class()
lang.Rule = Rule

--function Rule:__init(Sentence, Function, Function, Number)
function Rule:__init(predecessor, matchPredecessor, buildSuccessor, probability)
	self.predecessor = predecessor
	self.matchPredecessor = matchPredecessor
	self.buildSuccessor = buildSuccessor
	self.probability = probability
end
function Rule:apply(sentence, pos)
	if lang.print and self.matchPredecessor(sentence, pos) > 0 then
		local n, newSentence = self.buildSuccessor( self.matchPredecessor(sentence, pos) )
		print(self , "in: ["..pos..","..n.."]",  sentence)
		print("", "|-", newSentence)
	end
	return self.buildSuccessor( self.matchPredecessor( sentence, pos) )
end
function Rule:__tostring()
	s = {}
	table.insert(s,"(")
	for _,sym in ipairs(self.predecessor) do
		table.insert(s, tostring(sym) )
		table.insert(s, ",")
	end
	table.insert(s,")  ")
	table.insert(s, tostring( self.matchPredecessor ) )
	table.insert(s, " -> ")
	if self.probability then 
		table.insert(s, "(")
		table.insert(s, tostring(self.probability))
		table.insert(s, ")")
	end
	table.insert(s, tostring( self.buildSuccessor ) )
	return table.concat(s)
end

-- implement a simple Function class to implement callable objects that can
-- have __tostring functions.
-- This class can easily be inherited
local Function = o.class()
function Function:__call(...)
	return self.call(...) --self.call can't be directly in the metatble, as its shared between all instances of Function
end
-- return a function to match a parametric predecessor
--function lang.PPredecessor(terminals)
lang.PPredecessor = o.class(Function)
function lang.PPredecessor:__init(terminals)
	self.terminals = terminals
	self.call =  function(sentence, pos)
		local n, parameters = 0, {}
		for i=1,#terminals do
			if sentence[pos+i-1] == terminals[i].sym then
				n=n+1
				for j,varname in ipairs(terminals[i].parameters) do
					if sentence.parameters and sentence.parameters[pos+i-1] then
						parameters[varname] = sentence.parameters[pos+i-1][j]
						if not parameters[varname] then
							print("::", terminals[i].sym, varname)
							print("unable to match all parameters")
							return 0
						end
					else
						error("sentence has no parameters to match")
					end
					-- A(x,y) ==> {x= A.param[1], y= A.param[2]}
				end
			else
				return 0
			end
		end
		return n, parameters
	end
end
function lang.PPredecessor:__tostring()
	local s = {}
	for _,term in ipairs(self.terminals) do
		table.insert(s, tostring(term.sym))
		table.insert(s,"(")
		for _,varname in ipairs(term.parameters) do
			table.insert(s, tostring(varname))
			table.insert(s, ",")
		end
		table.insert(s,")")
	end
	return table.concat(s)
end


lang.PSuccessor = o.class(Function)
function lang.PSuccessor:__init(terminals)
	self.terminals = terminals -- save for tostring function
	self.call = function(n, parameters)
		if not n or n<=0 then return  end
		parameters = parameters or {}
		local newSentence = ParSentence()
		local newParameters = newSentence.parameters
		for _,successor in ipairs(terminals) do
			local newParam
			if type(successor) == "table" and successor.sym then
				newParam = successor.calculate(parameters)
				table.insert(newSentence, successor.sym)
			else table.insert(newSentence, successor) end
			newParameters[#newSentence] = newParam
		end
		return n, newSentence
	end
end
function lang.PSuccessor:__tostring()
	local s = {}
	for _,term in ipairs(self.terminals) do
		if type(term) == "table" and term.sym then
			table.insert(s,tostring(term.sym))
			table.insert(s,"(...)")
		else
			table.insert(s, tostring(term))
		end
		table.insert(s, " ")
	end
	return table.concat(s)
end

lang.Predecessor = o.class(Function)
function lang.Predecessor:__init(terminals)
	self.terminals = terminals -- save for tostring function
	self.call = function(sentence, pos)
		local n=0
		for i=1, #terminals do
			if sentence[pos+i-1] == terminals[i] then
				n=n+1
			else 
				return 0
			end
		end
		return n
	end
end
function lang.Predecessor:__tostring()
	local s = {}
	for _, sym in ipairs( self.terminals) do
		table.insert(s, sym)
		table.insert(s, " ")
	end
	return table.concat(s)
end

lang.CFPredecessor = o.class(Function)
function lang.CFPredecessor:__init(terminal)
	self.terminal = terminal
	self.call = function(sentence, pos)
		local n=0
		if sentence[pos] == terminal then n= 1 end
		return n
	end
end
function lang.CFPredecessor:__tostring()
	return tostring(self.terminal)
end

lang.Successor = o.class(Function)
function lang.Successor:__init(terminals)
	self.terminals = terminals
	self.call = function(n)
		return n, terminals
	end
end
function lang.Successor:__tostring()
	local s = {}
	for _, sym in ipairs( self.terminals) do
		table.insert(s, sym)
		table.insert(s, " ")
	end
	return table.concat(s)
end

--[[
local Rule = o.class()
lang.Rule = Rule --export the Rule object in the module

-- constructor Rule( [Symbol] predecessor, [Symbol] successor)
function Rule:__init(predecessor, successor, probability)
	assert(predecessor, "Rule constructor: No predecessor given")
	assert(successor, "Rule constructor: No successor given")
	self.predecessor = predecessor 
	self.successor = successor
	self.probability = probability -- may be nil for deterministic grammars
	self[1] = self.predecessor
	self[2] = self.successor
end
--function Rule:__tostring()
function Rule:__tostring()
	local s = {}
	table.insert(s, tostring(self.predecessor))
	table.insert(s, " ")
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
	local i = self:match(s, pos)
	if i then
		local successor = self:rewrite(s, pos)
		if successor then return true, i, successor
	else
		return false, 0, nil
	end
end
function Rule:match(s, pos)
	if s[pos] == self.predecessor then return 1 else return nil end
end
function Rule:rewrite(s, pos)
		return self.successor
end

CSRule = o.class(Rule)
lang.CSRule = CSRule
function CSRule:__init(predecessor, successor, probability)
	self.predecessor = predecessor
	self.successor = successor
	self.probability = probability
end
function CSRule:__tostring()
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
function CSRule:match(s, pos)
	local match = true
	local i = pos
	for _, sym in pairs(self.predecessor) do
		if s[i] ~= sym then 
			match = false
			break
		end
		i = i + 1
	end
	if match then return #self.predecessor
	else return nil end
end

-- quick table-constructor class that makes {symbol=..., calculate=...}
local ParSym = o.class()
lang.ParSym = ParSym
function ParSym:__init(symbol, func)
	self.symbol = symbol
	self.calculate = func
end

local ParRule = o.class(Rule)
lang.ParRule = ParRule
function ParRule:__tostring()
	local s = {}
	table.insert(s,self.predecessor)
	table.insert(s," -> ")

	for sym in ipairs( self.successor ) do
		if type(sym) == "table" and sym.symbol then
			table.insert(s, tostring(sym.symbol ))
		else
			table.insert(s, tostring(sym))
		end
		table.insert(s, " ")
	end
end
function ParRule:rewrite(s, pos)
		local newSentence = ParSentence()
		local newParameters = sentence.parameters
		local params = s.parameters[pos] --starting parameter
		for successor in ipairs(self.successor) do
			-- make a new parameterization of the symbols
			local newParam = successor.calculate(params) -- new parameter
			if type(successor) == "table" and sym.symbol then
				table.insert(newSentence, successor.sym)
			else table.insert(newSentence, successor)
			table.insert(newParameters, newParam)
		end
		return sentence
end
local CSParRule = o.class(CSRule)
function CSParRule:__tostring()
	local s = {}
	for sym in ipairs( self.predecessor ) do
		table.insert(s, tostring(sym))
		table.insert(s, " ")
	end
	table.insert(s," -> ")

	for sym in ipairs( self.successor ) do
		if type(sym) == "table" and sym.symbol then
			table.insert(s, tostring(sym.symbol ))
		else
			table.insert(s, tostring(sym))
		end
		table.insert(s, " ")
	end
end
function CSParRule:rewrite(s, pos)
		local newSentence = ParSentence()
		local newParameters = sentence.parameters
		local params = {} -- starting parameters
		for i = 1, #self.predecessor do
			params[i] = s.parameters[i+pos-1]
		end
		for successor in ipairs(self.successor) do
			-- make a new parameterization of the symbols
			local newParam
			if type(successor) == "table" and sym.symbol then
				newParam = successor.calculate(params) -- new parameter
				table.insert(newSentence, successor.sym)
			else table.insert(newSentence, successor)
			table.insert(newParameters, newParam)
		end
		return sentence
	end

local FLRule = o.class(Rule)
lang.FLRule = FLRule
function FLRule:__tostring()
	return tostring(self.predecessor) .. " -> f(...)"
end
function FLRule:rewrite(s, pos)
	predecessorParam = s.parameters[pos]
	local sentence, parameters = self.successor(predecessorParam)
	sentence.parameters = parameters
	return sentence
end

local CSFLRule = o.class(CSRule)
lang.CSFLRule = CSFLRule
function CSFLRule:__tostring()
	local s = {}
	for _,sym in ipairs( self.predecessor) do
		table.insert(s, tostring(sym) )
	end
	table.insert(s, " -> f(...)")
	return table.concat(s)
end
function CSFLRule:rewrite(s, pos)
	local predecessorParams = {}
	for i,v in ipairs( self.predecessor ) do
		predecessorParams[i] = s.parameters[pos + i - 1] 
	end
	local sentence, parameters = self.successor(predecessorParams)
	sentence.parameters = parameters
	return sentence
end
--]]


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
	local sum = 0
	for _, rule in ipairs(self) do
		if r <= sum + (rule.probability or 0) then
			return rule:apply(sentence, i)
		else
			sum = sum + (rule.probability or 0)
		end
	end
	return false, i, sentence
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
	if factor > 1 then factor = 1 end
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

return lang -- return the module
