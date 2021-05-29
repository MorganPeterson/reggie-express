local bit = require("bit")

local UTFMax = 4 -- max bytes per rune
local RuneMax = 0x10FFF -- max rune value

local Bit1 = 7
local BitX = 6
local Bit2 = 5
local Bit3 = 4
local Bit4 = 3
local Bit5 = 2

local Tx = bit.bxor((bit.lshift(1, (BitX + 1))-1), 0xFF)
local T2 = bit.bxor((bit.lshift(1, (Bit2 + 1))-1), 0xFF)
local T3 = bit.bxor((bit.lshift(1, (Bit3 + 1))-1), 0xFF)
local T4 = bit.bxor((bit.lshift(1, (Bit4 + 1))-1), 0xFF)
local T5 = bit.bxor((bit.lshift(1, (Bit5 + 1))-1), 0xFF)
local Rune1 = bit.lshift(1, (Bit1+0*BitX))-1
local Rune2 = bit.lshift(1, (Bit2+1*BitX))-1
local Rune3 = bit.lshift(1, (Bit3+2*BitX))-1
local Rune4 = bit.lshift(1, (Bit4+3*BitX))-1

local MaskX = bit.lshift(1, BitX)-1
local TestX = bit.bxor(MaskX, 0xFF)

local runeError = "byte not valid"
local char_pattern = "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*"

local function char_to_rune(char)
    local c = char:byte(1)
    -- one character sequence
    if c < Tx then
        return {rune=c, length=1}
    end

    -- two character sequence
    local c1 = bit.bxor(char:byte(2), Tx)
    if bit.band(c1, TestX) ~= 0 then
        return nil, runeError, 21
    end

    if c < T3 then
        if c < T2 then
            return nil, runeError, 22
        end
        local l = bit.band(bit.bor(bit.lshift(c, BitX), c1), Rune2)
        if l <= Rune1 then
            return nil, runeError, 23
        end
        return {rune=l, length=2}
    end

    local c2 = bit.bxor(char:byte(3), Tx)
    if bit.band(c2, TestX) ~= 0 then
        return nil, runeError, 31
    end

    if c < T4 then
        local l = bit.band(
            bit.bor(
                bit.lshift(
                    bit.bor(
                        bit.lshift(c, BitX),c1),BitX), c2), Rune3)
        if l <= Rune2 then
            return nil, runeError, 32
        end
        return {rune=l, length=3}
    end

    if UTFMax >= 4 then
        local c3 = bit.bxor(char:byte(4), Tx)
        if bit.band(c3, TestX) then
            return nil, runeError, 41
        end

        if c < T5 then
            local l = bit.band(
                bit.bor(
                    bit.lshift(
                        bit.bor(
                            bit.lshift(
                                bit.bor(
                                    bit.lshift(c, BitX)
                                , c1)
                            , BitX)
                        , c2)
                    , BitX)
                , c3), Rune4)
            if l <= Rune3 then
                return nil, runeError, 42
            end
            if l > RuneMax then
                return nil, runeError, 43
            end
            return {rune=l, length=4}
        end
    end
    return nil, runeError, 1
end

local LISTSIZE = 10
local BIGLISTSIZE = 25 * LISTSIZE
local NSUBEXP = 32
local NSTACK = 20
local LEXDONE = false
local YYRUNE = 0

local RUNE = 0177
local OPERATOR = 0200 -- Bitmask of all operators
local START = 0200 -- Start, used for marker on stack
local RBRA = 0201 -- Right bracket, )
local LBRA= 0202 -- Left bracket, (
local OR = 0203 -- Alternation, |
local CAT = 0204 -- Concatentation, implicit operator
local STAR = 0205 -- Closure, *
local PLUS = 0206 -- a+ == aa*
local QUEST = 0207 -- a? == a|nothing, i.e. 0 or 1 a's
local ANY = 0300 -- Any character except newline, .
local ANYNL = 0301 -- Any character including newline, .
local NOP = 0302 -- No operation, internal use only
local BOL = 0303 -- Beginning of line, ^
local EOL = 0304 -- End of line, $
local CCLASS = 0305 -- Character class, []
local NCCLASS = 0306 -- Negated character class, []
local END = 0377 -- Terminate: match found

local lexer_table = {}
table.insert(lexer_table, 0, END)
lexer_table['*'] = STAR
lexer_table['?'] = QUEST
lexer_table['+'] = PLUS
lexer_table['|'] = OR
lexer_table['('] = LBRA
lexer_table[')'] = RBRA
lexer_table['^'] = BOL
lexer_table['$'] = EOL
lexer_table['['] = bldcclass

local function nextc(exprp)
    if LEXDONE then
        return true, nil
    end
    
    local val, msg, err = char_to_rune(exprp)
    if err then
        io.stderr:write(string.format("[%s] %s\n", err, msg))
        return true, nil
    end
    
    if val.rune == string.byte('\\') then
        val, msg, err = char_to_rune(exprp)
        if err then
            io.stderr:write(string.format("[%s] %s\n", err, msg))
            return true, nil
        end
        return true, val.rune
    end

    if val.rune == 0 then
        LEXDONE = true, val.rune
    end
    return false, val.rune
end

local function lexer(rune, literal, dot_type)
    lexer_table['.'] = dot_type
    local quoted, new_rune = nextc(rune)
    
    if literal or quoted then
        if new_rune == 0 then
            return END
        end
        return RUNE
    end

    local rune_type = lexer_table[rune]
    if not rune_type then
        return RUNE
    else
        return rune_type
    end
end

local testStr = "是四艘国王级战列舰的第二艘舰"
local testChar1 = testStr:sub(1,3)
local testChar2 = '+'

print(lexer(testChar2, false, '.'))
