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


arith.expression = arithexp / "vars.%0"
--arith.expression = lpeg.C(arithexp)

function read(fname)
	local f = io.open(fname)
	local content = f:read("*all")
	f:close()
	return content
end
print( lpeg.match(arith.expression, read("ArithTest.txt") ))

return arith
