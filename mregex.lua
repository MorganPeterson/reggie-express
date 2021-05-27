-- x/regex/ - matches all the text that matches the regular expression
-- y/regex/ - matches all the text that does not match the regular expression
-- g/regex/ - if the regex finds a match in the string then the whole string
--            is passed
-- v/regex/ - if the regex does not find a match in the string then the whole
--            string is passed along.

---- TOKEN -------------------------------------------------------------------
local token = {}

function token.element(char)
    return {
        type='element',
        char=char
    }
end

function token.wildcard()
    return {
        type='wildcard',
        char='.'
    }
end

function token.start()
    return {
        type='start',
        char='^'
    }
end

function token.the_end()
    return {
        type='end',
        char='$'
    }
end

function token.escape()
    return {
        type='escape',
        char='\\'
    }
end

function token.comma()
    return {
        type='comma',
        char=','
    }
end

function token.left_parenthesis()
    return {
        type='parenthesis',
        side='left',
        char='('
    }
end

function token.right_parenthesis()
    return {
        type='parenthesis',
        side='right',
        char=')'
    }
end

function token.left_brace()
    return {
        type='brace',
        side='left',
        char='{'
    }
end

function token.right_brace()
    return {
        type='brace',
        side='right',
        char='}'
    }
end

function token.left_bracket()
    return {
        type='bracket',
        side='left',
        char='['
    }
end

function token.right_bracket()
    return {
        type='brace',
        side='right',
        char=']'
    }
end

function token.asterisk()
    return {
        type='quantifier',
        quantity='zeroOrMore',
        char="*"
    }
end

function token.plus()
    return {
        type='quantifier',
        quantity='oneOrMore',
        char='+'
    }
end

function token.question_mark()
    return {
        type='quantifier',
        quantity='zeroOrOne',
        char='?'
    }
end

function token.vertical_bar()
    return {
        type='or',
        char='|'
    }
end

function token.circumflex()
    return {
        type='not',
        char='^'
    }
end

function token.dash()
    return {
        type='dash',
        char='-'
    }
end

-- END TOKEN =================================================================

-- PARSER --------------------------------------------------------------------
local function read_input(input)
    -- get the first character of a string
    return input:sub(1, 1)
end

local function input_advance(input)
    -- remove first character and return rest of string
    return input:sub(2)
end

local function create_result(...)
    -- varadic function returns a table of all args
    return {...}
end

local function handle_escapes(input, callback)
    local adv = input_advance(input)
    local next_char = read_input(adv)
    if next_char == 't' then
        return create_result(callback('\t'), input_advance(adv))
    else
        return create_result(callback(next_char), input_advance(adv))
    end
end

local function lit(ch, callback)
    -- checks if character (ch) is the first in a string
    return function(input)
        local r = read_input(input)
        if r == ch then
            -- handle escapes
            if ch == '\\' then
                return handle_escapes(input, callback)
            end
            return create_result(callback(ch), input_advance(input))
        else
            return create_result(nil, input)
        end
    end
end

local function parser_or(...)
    local vargs = {...}
    return function(input)
        for _, func in ipairs(vargs) do
            local result = func(input)
            if result[1] ~= nil then
                return result
            end
        end
        local r = read_input(input)
        return create_result(token.element(r), input_advance(input))
    end
end

local parser = parser_or(
    lit('.', token.wildcard),
    lit('\\', token.element),
    lit('(', token.left_parenthesis),
    lit(')', token.right_parenthesis),
    lit('{', token.left_brace),
    lit('}', token.right_brace),
    lit('[', token.left_bracket),
    lit(']', token.right_bracket),
    lit('^', token.circumflex),
    lit('$', token.the_end),
    lit('?', token.question_mark),
    lit('*', token.asterisk),
    lit('+', token.plus),
    lit('|', token.vertical_bar),
    lit('-', token.dash))

-- END PARSER ================================================================

-- LEXER ---------------------------------------------------------------------
local lexed = {}

local test = "^ab?c\\d.*ef^go\td"

for i = 1, #test do
    if i == 1 and test:sub(1,1) == '^' then
        lexed[i] = {token.start(), test:sub(2)}
        i = i + 1
    else
        lexed[i] = parser(test:sub(i))
    end
end

for k, v in ipairs(lexed) do
    for kk, vv in ipairs(v) do
        if kk == 1 then
            for kkk, vvv in pairs(vv) do
                print(kkk, vvv)
            end
        else
            print(kk, vv)
        end
    end
end
