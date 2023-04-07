override = true
function log(msg)
    printh(msg, "log.txt", override, true)
    override = false
end

log("starting...")

function logTable(n, t, i)
    if (i==nil) i=0
    local idt = ident(i)

    log(idt..n..": {")
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

hud_enabled = true
hud_msgs = {}

function add_hud(msg)
    add(hud_msgs, msg)
end

function toggle_hud()
    hud_enabled = not hud_enabled
end

max_hud_msg = 5
function draw_hud()
    -- if (not hud_enabled) return
    local hud_pos = {2,2}

    for i=min(max_hud_msg, #hud_msgs) - 1, 0, -1 do
        local m = hud_msgs[#hud_msgs - i]
        print(m, hud_pos[1], hud_pos[2], 6)
        hud_pos[2] += 8
    end
    hud_msgs = {}
end
