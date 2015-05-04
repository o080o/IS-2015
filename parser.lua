lpeg = require("lpeg")
arithmetic = require("arithmetic")
lang = require("language")
lsys = require("lsys")



local character = lpeg.R("az", "AZ") + lpeg.S("+-[]|/\\")
local digit = lpeg.R("09")
local space = lpeg.S(" \t")^0
local terminal = lpeg.C( character * (character + digit)^0 ) * space  -- captures

local open = lpeg.P("(") * space
local close = lpeg.P(")") * space
local curlyOpen = lpeg.P("{") * space
local curlyClose = lpeg.P("}") * space
local dot = lpeg.P(".")
local eq = lpeg.P("=>") * space
local nextline = lpeg.S("\n")
local newline = lpeg.P("\n")


local number = (( digit^-1 * dot * digit^1) + digit^1) / tonumber -- captures
local probability = open * number * space * close
local terminalList = lpeg.Ct( terminal^1 )

local var = lpeg.C(character * ( character + digit)^0) * space
local comma = lpeg.P(",") * space
local varList = var * (comma * var) ^0
local args = lpeg.Ct( open * varList * space * close )
local pTerminal = lpeg.Ct( lpeg.Cg(terminal, "terminal") * lpeg.Cg(args, "args") ) * space
local pTerminalList = lpeg.Ct( pTerminal^1 )

local expr = (arithmetic.expression) * space
local exprList = expr * (comma * expr)^0
local argExpr = lpeg.Ct( open * exprList * close )
local pExpression = lpeg.Ct( lpeg.Cg(terminal, "terminal") * lpeg.Cg(argExpr, "args")) * space
local pExpressionList = lpeg.Ct( (pExpression + terminal)^1 )


local condition = curlyOpen * (arithmetic.condition) * space * curlyClose


-- A B A -> A B
local predecessor = lpeg.Cg(pTerminalList, "ParametricPredecessor") + lpeg.Cg(terminalList, "SimplePredecessor")
local successor = lpeg.Cg(pExpressionList, "ParametricSuccessor") + lpeg.Cg(terminalList, "SimpleSuccessor")
--local predecessor = lpeg.Cg(terminalList, "SimplePredecessor")
--local successor = lpeg.Cg(terminalList, "SimpleSuccessor")
local prob = lpeg.Cg(probability, "Probability")^-1
local cond = lpeg.Cg(condition, "Condition")^-1
local rule= lpeg.Ct(  predecessor * cond * space * eq * prob * successor * newline)

local simpleRule= lpeg.Ct( lpeg.Cg(terminalList, "SimplePredecessor" ) * eq * lpeg.Cg(probability, "Probability")^-1 * lpeg.Cg(terminalList, "Successor") * newline)
local pRule = lpeg.Ct( lpeg.Cg(pTerminalList, "ParametricPredecessor") * eq * lpeg.Cg(probability, "Probability")^-1 * lpeg.Cg(pExpressionList, "Successor") * newline)
--local flRule
-- A(x,y) B(z,q) -> (.5) F(x,y) B(z,q+1)
--local flRule = terminal+ eq [probability] flTerminal+

local sentence = (pExpressionList + terminalList) * newline
--local rule = pRule + simpleRule
--local rule = simpleRule

local lsystem = lpeg.Ct( lpeg.Cg( sentence, "Axiom") * lpeg.Cg(lpeg.Ct( rule ^ 1 ),"Rules"))


local function parseSimpleRule(rule)
		local predMatch = rule.SimplePredecessor
		local  matchPredecessor
		if #predMatch > 1 then
			matchPredecessor = lang.Predecessor( predMatch )
		else
			matchPredecessor = lang.CFPredecessor( predMatch[1] )
		end
		local predecessor = predMatch
		local buildSuccessor = lang.Successor( rule.Successor )
		return lang.Rule( predecessor, matchPredecessor, buildSuccessor, rule.Probability)
end
local function parsePTerminal(pTerm)
		return {sym=pTerm.terminal, parameters=pTerm.args}
end
local function parseCondition( cond )
	print("Condition:", cond)
	local funcStr = "return function(vars) return "..cond..";end"
	local func
	if loadstring then
		func = assert( loadstring( funcStr ))()
	else
		func = assert( load( funcStr ))()
	end
	return func
end
local function parsePExpr( pExpr)
	if type( pExpr) == "string" then
		return pExpr
	else
		local pExprFuncs = {}
		for _,expr in ipairs(pExpr.args) do
			local funcStr = "return function(vars) return "..expr..";end"
			local func
			if loadstring then
				func = assert( loadstring(funcStr))()
			else
				func = assert( load(funcStr))()
			end
			table.insert(pExprFuncs, func)
		end

		return {sym = pExpr.terminal, calculate = function(params)
			local newParam = {}
			for i,func in ipairs(pExprFuncs) do
				table.insert(newParam, func(params))
			end
			return newParam
		end}
	end
end
local function parsePRule(rule)
	local predTerms = {}
	local predecessor = {}
	for _, pTerm in ipairs(rule.ParametricPredecessor) do
		local term =parsePTerminal(pTerm)
		table.insert(predTerms, term)
		table.insert(predecessor, term.sym)
		-- add all variables to a table to use when parsing PExpressions
	end
	succTerms = {}
	for _, pExpr in ipairs(rule.Successor) do
		table.insert(succTerms, parsePExpr(pExpr))
	end
	local matchPredecessor = lang.PPredecessor(predTerms)
	local buildSuccessor = lang.PSuccessor(succTerms)
	return lang.Rule( predecessor, matchPredecessor, buildSuccessor, rule.Probability)
end

local function parseParametricPredecessor(predecessor, condition)
	local predTerms = {}
	local predecessor2 = {}
	for _, pTerm in ipairs(predecessor) do
		local term = parsePTerminal(pTerm)
		table.insert(predTerms, term)
		table.insert(predecessor2, term.sym)
		-- add all variables to a table to use when parsing PExpressions
	end
	return lang.PPredecessor(predTerms, condition), predecessor2
end
local function parseParametricSuccessor(successor)
	succTerms = {}
	for _, pExpr in ipairs(successor) do
		table.insert(succTerms, parsePExpr(pExpr))
	end
	return lang.PSuccessor(succTerms)
end
local function parseSimpleSuccessor(successor)
	return lang.Successor( successor )
end
local function parseSimplePredecessor(predecessor)
	local  matchPredecessor
	if #predecessor > 1 then
		matchPredecessor = lang.Predecessor( predecessor )
	else
		matchPredecessor = lang.CFPredecessor( predecessor[1] )
	end
	return matchPredecessor, predecessor
end

-- used to parse axiom sentence
local function parseSentence(s)
	local sentence = lang.ParSentence()
	for i, sym in ipairs(s) do
		if type(sym) == "string" then
			table.insert(sentence, sym)
		else
			for k,v in pairs(sym) do
			end
			local terminal = parsePExpr(sym)
			table.insert(sentence, terminal.sym)
			sentence.parameters[#sentence] = terminal.calculate({})
		end
	end
	return sentence
end
local function parse(input)
--local simpleRule = lpeg.Ct( lpeg.Cg(terminalList, "SimplePredecessor") * eq * lpeg.Cg(probability, "Probability")^-1 * lpeg.Cg(terminalList, "Successor") * newline)
	--local simpleRule = lpeg.Ct( lpeg.Cg(terminalList, "SimplePredecessor") * eq * lpeg.Cg(terminalList, "Successor") * newline )

	local matches = lpeg.match(lsystem, input)
	assert(matches, "Invalid Syntax: (no lsystem found)")
	local rules, stochastic = {}, false
	local axiom = parseSentence(matches.Axiom)
	for _,rule in pairs(matches.Rules) do
		local matchPredecessor, buildSuccessor, condition

		if rule.Probability then stochastic = true end
		if rule.Condition then condition = parseCondition( rule.Condition ) end

		if rule.SimplePredecessor then
			matchPredecessor, predecessor = parseSimplePredecessor( rule.SimplePredecessor )
		elseif rule.ParametricPredecessor then
			matchPredecessor, predecessor = parseParametricPredecessor( rule.ParametricPredecessor, condition )
		else
			error("unknown type of rule was matched?")
		end

		if rule.SimpleSuccessor then
			buildSuccessor = parseSimpleSuccessor( rule.SimpleSuccessor )
		elseif rule.ParametricSuccessor then
			buildSuccessor = parseParametricSuccessor( rule.ParametricSuccessor )
		else
			error("unknown type of rule was matched?")
		end
		
		local newRule = lang.Rule( predecessor, matchPredecessor, buildSuccessor, rule.Probability, condition)
		table.insert( rules, newRule )
		print("Rule:", newRule)
	end
	local grammar 
	if stochastic then
		grammar = lang.StochasticGrammar( rules )
	else
		grammar = lang.Grammar( rules )
	end
	local system = lsys(grammar, axiom)
	print(system.axiom)
	return system
end
local function read(fname)
	local f,err = io.open( fname )
	assert(f,err)
	local content = f:read("*all")
	f:close()
	return content
end
local function parseFile(fname)
	return parse( read(fname) )
end

return {parse=parse, parseFile=parseFile }
