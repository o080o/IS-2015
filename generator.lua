-- [a] is a List of a's
-- {a} is an unordered set of a's
-- (a,b,c,...) is a tuple
--
-- Symbol is Key
-- Sentence is [Symbol]
-- Rule is ( [Symbol], [Symbol] )
-- Grammar is [Rule]

local function printSentence( sentence )
	local s = {}
	for _,sym in ipairs(sentence) do
		table.insert(s, tostring(sym))
		table.insert(s, " ")
	end
	print( table.concat(s) )
end
-- function findTerminals( Grammar ) return {Symbol}
local function findTerminals(grammar)
	local nonterminals = {}
	for _,rule in pairs(grammar) do
		for _,sym in pairs(rule[1]) do
			nonterminals[sym] = true
			print("Nonterminal:", sym)
		end
	end
	return nonterminals
end

--function isSentential( [Symbol] sentence, {Symbol} nonterminals ) 
--return Boolean true if the sentence is a sentential form, false otherwise (if
--there are no non-terminal symbols in the sentence)
local function isSentential(sentence, nonterminals)
	local sentential = false
	for _,sym in pairs(sentence) do
		--print("terminal?", sym, nonterminals[sym])
		sentential = sentential or nonterminals[ sym ] 
	end
	return sentential
end

-- function applyRule( Rule, Sentence ) return Sentence
-- attempt to apply the given rule to the sentence
local function applyRule(rule, sentence)
	--printSentence(rule[1])
	--printSentence(sentence)
	-- find a place to match the rule 
	local matches = {}
	local curMatch = nil
	local i = 1
	local n = 1
	while n <= #sentence do
		local sym = sentence[n]
		if sym == rule[1][i] then
			if i == 1 then curMatch = n end
			if i == #rule[1] then
				table.insert(matches, curMatch)
				curMatch = nil
				i = 1
			end
		else
			n = curMatch or n
			curMatch = nil
			i = 1
		end
		n = n + 1 ; 
		if curMatch then i = i + 1 end
	end
	if #matches > 0 then
		--print("Success!!:", matches[1]) 
		-- pick a match (randomly?)
		-- for now just use the first match.
		local match = matches[1]

		-- make a copy of the sentence
		local newsentence = {}
		for k,sym in pairs( sentence ) do
			newsentence[k]=sym
		end
		-- remove the symbols we are replacing
		for _,sym in pairs( rule[1] ) do
			table.remove(newsentence, match)
		end
		-- add in the new symbols
		--for _,sym in ipairs( rule[2] ) do
		for i = #rule[2],1,-1 do 
			table.insert(newsentence, match, rule[2][i])
		end
		--printSentence(newsentence)
		return newsentence
	else
		return nil
	end
end


-- Generate a random sentence based on a grammar and starting non-terminal

local Gen = {} --create a new table to use as a namespace
--function Gen.generate( Grammar grammar, Symbol start, Int maxDepth ) return [Symbol] a possible
--sentence formed from the grammar with the given start symbol. No more than
--*maxDepth* rules are applied.
function Gen.generate(grammar, start, maxDepth, terminals)
	terminals = terminals or {}
	local nonterminals = findTerminals( grammar) -- find all the nonterminals
	for _,sym in pairs(terminals) do -- allow user to force symbols to act as terminals
		nonterminals[sym] = nil
	end
	local language = {}

	-- breadth-first expansion, limited by the maximum levels of recursion.
	local function step(grammar, sentence, nextSententials)
		if isSentential(sentence, nonterminals) then
			for _,rule in pairs(grammar) do
				table.insert(nextSententials, applyRule(rule, sentence))
			end
		else
			table.insert(language, sentence) -- this sentence has no more non-terminals, so add it to the generated language
			--print("!! Full Sentence !!:")
			--printSentence(sentence)
			--io.read("*l") -- readline to pause
		end
	end

	local sententials = { {start} }
	local generating = true
	local depth = 0
	while generating do
		depth = depth + 1
		--print("Sentences:")
		for _,sentence in pairs(sententials) do
			--printSentence(sentence)
		end
		--io.read("*l") -- readline to pause
		local nextSententials = {}
		-- Generate the next level of recursion
		for _,sentence in pairs(sententials) do
			--print("replacing:",_,sentence)
			step(grammar, sentence, nextSententials, language)
		end
		sententials = nextSententials
		if depth>maxDepth or #sententials <= 0 then
			generating = false
		end
	end
	print("\nLanguage:")
	for _,sentence in pairs(language) do
		printSentence(sentence)
	end
	return language

	--[[
	-- pick a rule, try to match it.
	local generating = true
	while generating do
		-- randomly test each rule
		shuffle( grammar )
		local matched = false
		for rule in ipairs(grammar) do
			local match = testRule(rule, sentence)
			if match then
				executeRule(rule, match, sentence)
				matched = true
				break
			end
		end

		-- search for non-terminals
		if foldl( sentence, function(s) if nonterminals[s] then return true else return false end end ) then
			generating = true
		else
			generating = false
		end

		assert( generating and not matched, "impossible grammar: can't reduce non-terminal" )
	end
	return sentence
	]]
end



-- some tests.
--

tdh = {
	{{"NAME"},{"TOM"}},
	{{"NAME"},{"DICK"}},
	{{"NAME"},{"HARRY"}},
	{{"SENTENCE"},{"NAME"}},
	{{"SENTENCE"},{"LIST", "END"}},
	{{"LIST"},{"NAME"}},
	{{"LIST"},{"NAME", ",", "LIST"}},
	{{",", "NAME", "END"},{"AND", "NAME"}},
}

turtle = {
	{{"MOVE"}, {"E", "MOVE", "W"}},
	{{"MOVE"}, {"N", "MOVE", "S"}},
	{{"MOVE"}, {}},
	{{"N","S"}, {"S", "N"}},
	{{"N","E"}, {"E", "N"}},
	{{"N","W"}, {"W", "N"}},
	{{"S","N"}, {"N", "S"}},
	{{"S","E"}, {"E", "S"}},
	{{"S","W"}, {"W", "S"}},
	{{"E","N"}, {"N", "E"}},
	{{"E","S"}, {"S", "E"}},
	{{"E","W"}, {"W", "E"}},
	{{"W","N"}, {"N", "W"}},
	{{"W","S"}, {"S", "W"}},
	{{"W","E"}, {"E", "W"}},
}
Gen.generate(tdh, "SENTENCE", 6)
Gen.generate(turtle, "MOVE", 5, {"N", "S", "E", "W"})

return Gen -- return functions as a module
