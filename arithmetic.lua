local lpeg = require("lpeg")
local arith = {}
arith.expression = lpeg.P("??")

local space = lpeg.S(" \t")^0
local character = lpeg.R("az", "AZ")
local digit = lpeg.R("09")
local dot = lpeg.P(".")

local var = character * (character + digit)^0 * space
local termop = lpeg.S("+-") * space
local factorop = lpeg.S("*/") * space
local number = ((digit^-1 * dot * digit^1) + digit^1) * space
local open =  lpeg.P("(") * space
local close =  lpeg.P(")") * space


local expression, term, factor = lpeg.V"expression", lpeg.V"term", lpeg.V"factor"
local arithexp = lpeg.P({ expression,
	expression = term * (termop * term)^0,
	term = factor * (factorop * factor)^0,
	factor = var + number + open * expression * close
})

local test = lpeg.P("<=") + lpeg.P(">=") + lpeg.P("<") + lpeg.P(">") + lpeg.P("==") + lpeg.P("~=")
local booleanop = lpeg.P("and") + lpeg.P("or")
local condition = lpeg.P( arithexp * space * test * space * arithexp )
local compoundCondition = lpeg.P( (1-lpeg.S("{}"))^0 )

--arith.expression = arithexp / "vars.%0"
local function varreplace( str )
	str = str:gsub( "([a-zA-Z][a-zA-Z0-9]*)", "vars.%1")
	return str
end

arith.expression = arithexp / varreplace
arith.condition = compoundCondition / varreplace


local test = lpeg.match( arith.condition, "x < 5*3+y and q < y")
print(test)

return arith
