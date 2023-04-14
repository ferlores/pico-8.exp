function log(...)
    local args = {...}
    local msg = ''

    for v in all(args) do
        if (type(v) == 'table') then
            log_to_file(msg)
            logTable(v)
            msg = ''
        else
            msg = msg..' '..v
        end
    end

    log_to_file(msg)
end

__override = true
function log_to_file(msg)
    printh(msg, 'log.txt', __override, true)
    __override = false
end

function logTable(n, t, i)
    if (i == nil) i=0
    if (t == nil) then
        t = n
        n = ''
    else
        n = n..': '
    end

    local idt = ident(i)

    log(idt..n.."{")
    for k,v in pairs(t) do
        if (type(v) == "table") then
            logTable(k, v, i+2)
        else
            if (k != nil or v!= nil) log(ident(i+2)..k..': '..tostr(v)..',')
        end
    end
    log(idt.."}")
end

function ident(n)
    local s = ""
    for i=0,n do
        s = s.." "
    end
    return s
end

__hud_msgs = {}

function add_hud(msg)
    add(__hud_msgs, msg)
end

__max_hud_msg = 5
function draw_hud()
    local hud_pos = {10,30}

    for i=min(__max_hud_msg, #__hud_msgs) - 1, 0, -1 do
        local m = __hud_msgs[#__hud_msgs - i]
        print(m, hud_pos[1], hud_pos[2], 6)
        hud_pos[2] += 8
    end
    __hud_msgs = {}
end

log("starting...")
