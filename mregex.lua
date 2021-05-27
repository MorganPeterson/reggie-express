local xflag = true
local wflag = true
local eflag = true
local fflag = false
local matchall = true

local pattern = ""

local function add_pattern(pat, len)
    -- match all or die trying
    if not xflag and (len == 0 or matchall) then
        matchall = false
        return
    end

    -- trim newline
    if len > 0 and pat:sub(len, len) == '\n' then
        len = len - 1
    end

    -- pattern can not be null terminated
    if wflag and not fflag then
        local bol = ''
        local eol = ''
        local extra = 4
        local eflag_str = {'\\(', '\\)'}

        if pat:sub(1,1) == '^' then
            bol = '^'
        end

        if len > 0 and pat:sub(len,len) == '$' then
            eol = '$'
        end

        if eflag then
            eflag_str[1] = '('
            eflag_str[2] = ')'
            extra = 2
        end

        local new_pattern = string.format(
            "%s[[:<:]]%s%s%s[[:>:]]%s",
            bol,
            eflag_str[1],
            pat:sub(bol:len()+1,pat:len() - eol:len()),
            eflag_str[2],
            eol)

        pattern = string.format('%s%s', pattern, new_pattern)
        len = 14 + extra
    else
        pattern = string.format('%s%s', pattern, pat)
    end
    return len
end

local function add_patterns(pats)
    -- read patterns from a stream
    for s in pats:gmatch('[^\n]+') do
        add_pattern(s, s:len())
    end
end

local function read_patterns(file_name)
    -- read patterns from a file
    local f = assert(io.open(file_name, "rb"))
    while true do
        local line = f:read()
        if line == nil then break end
        add_pattern(line, line:len())
    end
    f:close()
end

local test = "^ab?c\\d.*ef^go\td\nabcd?ef$\n"
add_patterns(test)

print(pattern)
