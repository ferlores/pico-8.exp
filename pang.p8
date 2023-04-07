pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- pang
-- by ferlores

#include utilities.lua

__init, __update, __draw = {}, {}, {}
function register(cb, f)
    if (cb == 'init') add(__init, f)
    if (cb == 'update') add(__update, f)
    if (cb == 'draw') add(__draw, f)
end

function _init()
    for f in all(__init) do
        f()
    end
end

function _update()
    for f in all(__update) do
        f()
    end
end

function _draw()
    cls()
    for f in all(__draw) do
        f()
    end
end

-->8
-- player
player_speed = 0.5
player_friction = 0.3
player_width = 8
player_height = 8
players = {}

-- add_players
register('init', function ()
    add(players, {
        spr = 1,
        x = screen_max/2 - player_width,
        y = screen_max - player_height,
        dx = 0,
        dy = 0,
        speed = player_speed,
        friction = player_friction,
        weapon = 1,
        h = player_height,
        w = player_width,
        lifes = 3
    })
end)

-- move_players
register('update', function ()
    control_player(players[1], 0)

    for p in all(players) do
        p.x = mid(screen_min, p.x + p.dx, screen_max - player_width)
        p.y += p.dy

        p.dx *= (1 - p.friction)
        p.dy *= (1 - p.friction)

        add_hud('p:'..p.x..', '..p.y..', '..p.dx..', '..p.dy)
    end
end)

-- draw_players
register('draw', function ()
    for p in all(players) do
        spr(p.spr, p.x, p.y)
    end
end)

function control_player(p, control)
    if (btn(⬅️, control)) p.dx -= p.speed
    if (btn(➡️, control)) p.dx += p.speed
    if (btnp(❎, control)) add_bullet(p)
end

function loose_life(p)
    p.lifes -= 1

    log('life lost')
    -- if (p.lifes = 0) then
        -- game_over()
    -- else
        -- restart_level()
    -- end
end

-->8
-- bullets
max_bullets = 2
bullets = {}
weapons = {
    [1] =  {
        sprx = 0,
        spry = 8,
        sfx = 0,
        dx = 0,
        dy = 3,
        w = 5,
        h = 16
    }
}

function add_bullet(p)
    if (#bullets >= max_bullets) return

    local w = weapons[p.weapon]
    add(bullets, {
        x = p.x,
        y = p.y - player_height,
        dx = w.dx,
        dy = w.dy,
        tp = p.weapon,
        w = w.w,
        h = w.h
    })
    sfx(w.sfx)
end

-- move_bullets
register('update', function ()
    for i, b in pairs(bullets) do
        local b = bullets[i]
        b.x = b.x + b.dx
        b.y = b.y - b.dy

        -- remove bullet
        if (is_offscreen(b.x, b.y, b.w, b.h)) deli(bullets, i)
    end
end)

-- draw_bullets
register('draw', function ()
    for b in all(bullets) do
        local w = weapons[b.tp]
        sspr(w.sprx, w.spry, w.w, w.h, b.x, b.y)
        add_hud('w:'..b.x..', '..b.y..', '..b.dx..', '..b.dy)
    end
end)

-->8
-- balls

balls = {}
ball_tp = {
    [1] =  {
        sfx = 0,
        dx = 1,
        dy = 0,
        w = 8,
        h = 8,
        bounce = 1
    }
}

ball_sizes = {
    [1] = {
        sz = 2,
        render = function (x, y) spr(66, x, y) end,
    },
    [2] = {
        sz = 4,
        render = function (x, y) spr(65, x, y) end,
    },
    [3] = {
        sz = 8,
        render = function (x, y) spr(64, x, y) end,
    },
    [4] = {
        sz = 12,
        render = function (x, y) sspr(0, 32, 8, 8, x, y, 12, 12) end,
    },
    [5] = {
        sz = 16,
        render = function (x, y) sspr(0, 32, 8, 8, x, y, 16, 16) end,
    },
    [6] = {
        sz = 24,
        render = function (x, y) sspr(0, 32, 8, 8, x, y, 24, 24) end,
    },
    [7] = {
        sz = 32,
        render = function (x, y) sspr(0, 32, 8, 8, x, y, 32, 32) end
    },
}
max_ball_size = ball_sizes[#ball_sizes].sz

-- move_ball
register('update', function()
    local gravity = 0.1
    for i, b in pairs(balls) do
        local btp = ball_tp[b.tpid]
        local newx = b.x + b.dx
        local newy = b.y + b.dy

        -- y axis
        if (is_offscreen(1, newy, b.sz, b.sz)) then
            b.dy = -btp.bounce * lerp(1.5, 4, b.sz/max_ball_size)
        end

        -- x axis
        if (is_offscreen(newx, 1, b.sz, b.sz)) then
            b.dx *= -btp.bounce
        end

        local pid = is_hit_by_player(b)
        if (pid != 0) then
            loose_life(players[pid])
        end

        local bullet_id = is_hit_by_bullet(b)
        if (bullet_id != 0) then
            if (b.szid - 1 > 0) then
                add_ball(b.tpid, b.szid - 1, b.x, b.y, b.dx, b.dy)
                add_ball(b.tpid, b.szid - 1, b.x, b.y, -b.dx, b.dy)
            end

            deli(bullets, bullet_id)
            deli(balls, i)
        else
            b.x += b.dx
            b.y += b.dy
            b.dy += gravity
        end
    end
end)

-- draw_ball
register("draw", function ()
    for b in all(balls) do
        ball_sizes[b.szid].render(b.x, b.y)
        -- add_hud('b:'..b.x..', '..b.y..', '..b.dx..', '..b.dy)
    end
    add_hud('#b: '.. #balls)
end)

function is_hit_by_bullet(ball)
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        if (rect_collide(b.x, b.y, b.w, b.h, ball.x, ball.y, ball.sz, ball.sz)) then
            return i
        end
    end
    return 0
end

function is_hit_by_player(ball)
    for i = #players, 1, -1 do
        local p = players[i]
        if (rect_collide(p.x, p.y, p.w, p.h, ball.x, ball.y, ball.sz, ball.sz)) then
            return i
        end
    end
    return 0
end

function add_ball(tpid, szid, x, y, dx, dy)
    local bt = ball_tp[tpid]
    add(balls, {
        tpid = tpid,
        x = x,
        y = y,
        dx = dx or bt.dx,
        dy = dy or bt.dy,
        szid = szid,
        sz = ball_sizes[szid].sz
    })
end

-->8
-- level

screen_min = 1
screen_max = 127

levels = {
    [1] = {
        balls = {
            [1] = {
                tpid = 1,
                sz = 7,
                x = screen_max/2 - 16,
                y= 5
            }
        }
    }
}

current_level = 1

-- draw_scene
register('draw', function ()
    rect(0,0,127,127,15)
    draw_hud()
end)

function restart_level(lid)
    lid = lid or current_level
    log('restarting level '..lid)

    -- clean up level
    balls = {}

    for b in all (levels[lid].balls) do
        add_ball(b.tpid, b.sz, b.x, b.y)
    end
end

function is_offscreen(x, y, w, h)
    local res_x =
        x < screen_min or
        x + w > screen_max

    local res_y =
        y < screen_min or
        y + h > screen_max

    -- if (res_x) log('is_offscreen X: '..x..", "..w)
    -- if (res_y) log('is_offscreen Y: '..y..", "..h)

    return res_x or res_y
end

-->8
-- game

register('init', function()
    restart_level()
end)


-- is_playing = false
-- register('update', function()
--     if ()
-- end)



-->8
-- collision

function lerp(min, max, p)
    return (max-min) * p + min
end

function rect_collide(x1, y1, w1, h1, x2, y2, w2, h2)
    local overlap_x, overlap_y = false, false
    -- x axis
    if (x1 + w1 >= x2 and x1 <= x2 + w2) then
        -- log ('X collide '..x1..','..w1..','..x2..','..w2)
        overlap_x = true
    end

    -- y axis
    if (y1 + h1 >= y2 and y1 <= y2 + h2) then
        -- log ('Y collide '..y1..','..h1..','..y2..','..h2)
        overlap_y = true
    end

    return overlap_x and overlap_y
end

__gfx__
00000000000000007700007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000055555507078880700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005dd5007088880702222e00005557000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000055dd550088008800022e000000570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005dddd50000760000022e000000570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005ddd65070600607002e2000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000445d65447066660704222400004554000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000495555497700007704020400004004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40604000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006555556600000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006555556600000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005566655500000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005566655500000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006555d56600000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000655dd56600000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005566655500000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005566655500000000000000000000000000000000000000000000000000000000
009999000a900000a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
099a9990a99900009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99a99999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09994490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000a750097500a7500b7500c7500e75011750157501a7501f74023730247202e70009000080000800008000080000000000000000000000000000000000000000000000000000000000000000000000000
