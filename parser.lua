lpeg = require("lpeg")
arithmetic = require("arithmetic")
lang = require("language")


local character = lpeg.R("az", "AZ")
local digit = lpeg.R("09")
local space = lpeg.S(" \t")^0
local terminal = lpeg.C( character * (character + digit)^0 ) * space  -- captures
local open = lpeg.P("(") * space
local close = lpeg.P(")") * space
local dot = lpeg.P(".")
local eq = lpeg.P("->") * space
local nextline = lpeg.S("\n")
local newline = lpeg.P("\n")


local number = (( digit^-1 * dot * digit^1) + digit^1) / tonumber -- captures
local probability = open * number * space * close
local terminalList = lpeg.Ct (terminal ^1)

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



-- A B A -> A B
local simpleRule = lpeg.Ct( lpeg.Cg(terminalList, "SimplePredecessor") * eq * lpeg.Cg(probability, "Probability")^-1 * lpeg.Cg(terminalList, "Successor") * newline)
local pRule = lpeg.Ct( lpeg.Cg(pTerminalList, "ParametricPredecessor") * eq * lpeg.Cg(probability, "Probability")^-1 * lpeg.Cg(pExpressionList, "Successor") * newline)
local flRule
-- A(x,y) B(z,q) -> (.5) F(x,y) B(z,q+1)
--local flRule = terminal+ eq [probability] flTerminal+

local rule = pRule + simpleRule

--local lsystem = (rule + space^1) ^1
local lsystem = lpeg.Ct( rule ^ 1 )
--local lsystem =  terminal * open * expr * (comma * expr)^0 * close
--local lsystem = terminalList
--local lsystem = simpleRule
local function parseSimpleRule(rule)
		local predMatch = rule.SimplePredecessor
		local predecessor
		if #predMatch > 1 then
			predecessor = lang.Predecessor( predMatch )
		else
			predecessor = lang.CFPredecessor( predMatch[1] )
		end
		local successor = lang.Successor( rule.Successor )
		return lang.Rule( predecessor, successor, rule.Probability)
end
local function parsePTerminal(pTerm)
		print(pTerm.terminal, ":", table.unpack(pTerm.args))
		return {sym=pTerm.terminal, parameters=pTerm.args}
end
local function parsePExpr( pExpr, varstring )
	if type( pExpr) == "string" then
		return pExpr
	else
		local pExprFuncs = {}
		for _,expr in ipairs(pExpr.args) do
			local func,err = load("return function(vars) return "..expr..";end")
			assert(func, err)
			func = func()
			table.insert(pExprFuncs, func)
		end

		print(pExpr.terminal, ":", table.unpack(pExpr.args))
		return {sym = pExpr.terminal, calculate = function(params)
			local newParam = {}
			print("Calcing..", params)
			for _,func in ipairs(pExprFuncs) do
				table.insert(newParam, func(params))
			end
			for k,v in ipairs(newParam) do print("::", k,v) end
			return newParam
		end}
	end
end
local function parsePRule(rule)
	predTerms = {}
	for _, pTerm in ipairs(rule.ParametricPredecessor) do
		table.insert(predTerms, parsePTerminal(pTerm))
		-- add all variables to a table to use when parsing PExpressions
	end
	succTerms = {}
	for _, pExpr in ipairs(rule.Successor) do
		table.insert(succTerms, parsePExpr(pExpr))
	end
	local predecessor = lang.PPredecessor(predTerms)
	local successor = lang.PSuccessor(succTerms)
	return lang.Rule( predecessor, successor, rule.Probability)
end
local function parse(input)
	local matches = lpeg.match(lsystem, input)
	print( matches)
	local rules, stochastic = {}, false
	for _,rule in pairs(matches) do
		if rule.Probability then stochastic = true end
		if rule.SimplePredecessor then
			table.insert(rules, parseSimpleRule(rule))
		elseif rule.ParametricPredecessor then
			table.insert(rules, parsePRule(rule))
		else error("unknown kind of rule was matched?") end
		print(rules[#rules])
	end
	local grammar 
	if stochastic then
		grammar = lang.StochasticGrammar( rules )
	else
		grammar = lang.Grammar( rules )
	end
	return grammar
end
local function read(fname)
	local f = io.open( fname )
	local content = f:read("*all")
	f:close()
	return content
end
local function parseFile(fname)
	return parse( read(fname) )
end

return {parse=parse, parseFile=parseFile }
