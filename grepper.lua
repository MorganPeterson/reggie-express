local Aflag = 0
local Bflag = 0
local bflag = false
local xflag = false
local wflag = false
local eflag = false
local fflag = false
local gflag = true
local matchall = true

local optstr= "0123456789A:B:C:EFGHILPSRUVZabce:f:hilnoqrsuvwxy"
local pattern = ""
local opt_table = {}

function getopt(optstring, ...)
    local opts = { }
    local args = { ... }

    for optc, optv in optstring:gmatch"(%a)(:?)" do
        opts[optc] = { hasarg = optv == ":" }
    end

    return coroutine.wrap(function()
        local yield = coroutine.yield
        local i = 1

        while i <= #args do
            local arg = args[i]

            i = i + 1

            if arg == "--" then
                break
            elseif arg:sub(1, 1) == "-" then
                for j = 2, #arg do
                    local opt = arg:sub(j, j)

                    if opts[opt] then
                        if opts[opt].hasarg then
                            if j == #arg then
                                if args[i] then
                                    yield(opt, args[i])
                                    i = i + 1
                                elseif optstring:sub(1, 1) == ":" then
                                    yield(':', opt)
                                else
                                    yield('?', opt)
                                end
                            else
                                yield(opt, arg:sub(j + 1))
                            end

                            break
                        else
                            yield(opt, false)
                        end
                    else
                        yield('?', opt)
                    end
                end
            else
                yield(false, arg)
            end
        end

        for i = i, #args do
            yield(false, args[i])
        end
    end)
end

local function usage()
    io.stderr:write(
        string.format(
            "usage: mregex [-%s] [pattern] [file ...]\n", optstr))
    return 1
end

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

local lastopt = nil
local newarg = nil
local optindex = 1
local prevoptindex = 0
local need_pattern = true
local file_names = {}

for opt, arg in getopt(optstr, ...) do
    local opt_num = tonumber(opt)
    if opt_num and opt_num > -1 and opt_num < 10 then
        if newarg or tonumber(lastc) == nil then
            Aflag = 0
        end
        Bflag = (Aflag * 10) + opt_num
        Aflag = Bflag
    elseif opt == 'A' or opt == 'B' then
        local arg_num = tonumber(arg)
        if not arg_num or arg_num <= 0 then
            print(2, "context out of range")
            return
        end
        if opt == 'A' then
            Aflag = arg_num
        else
            Bflag = arg_num
        end
    elseif opt == 'b' then
        bflag = true
    elseif opt == 'C' then
        if not arg then
            Aflag = 2
            Bflag = 2
        else
            local arg_num = tonumber(arg)
            if not arg_num or arg_num <= 0 then
                print(2, "context out of range")
                return
            end
            Aflag = arg_num
            Bflag = arg_num
        end
    elseif opt == 'e' then
        add_patterns(arg)
        need_pattern = false
    elseif opt == 'E' then
        eflag = true
        fflag = false
        gflag = false
    elseif opt == 'f' then
        read_patterns(arg)
        need_pattern = false
    elseif opt == 'F' then
        eflag = false
        fflag = true
        gflag = false
    elseif opt == 'F' then
        eflag = false
        fflag = false
        gflag = true
    elseif opt == 'w' then
        wflag = true
    elseif opt == 'x' then
        xflag = true
    else
        if not opt and arg then
            if need_pattern then
                add_patterns(arg)
                need_pattern=false
            else
                table.insert(file_names, arg)
            end
        else
            return usage()
        end
    end
    lastopt = opt
    newarg = optindex ~= prevoptindex
    prevoptindex = optindex
    optindex = optindex + 1

end


local test = "^ab?c\\d.*ef^go\td\nabcd?ef$\n"
add_patterns(test)
need_pattern = false

if need_pattern then
    return usage()
end

print(pattern)
