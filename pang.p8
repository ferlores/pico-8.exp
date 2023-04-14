pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- pang
-- by ferlores

#include utilities.lua

-- debug flags
draw_shapes = false


default_mode = '__default'
current_mode = nil
__callbacks = {
    ['init'] = {
        [default_mode] = {}
    },
    ['update'] = {
        [default_mode] = {}
    },
    ['draw'] = {
        [default_mode] = {}
    },
    ['destroy'] = {
        [default_mode] = {}
    }
}


function register(cb, mode, f)
    if (type(mode) == 'function') then
        f = mode
        mode = default_mode
    end

    if (__callbacks[cb][mode] == nil) __callbacks[cb][mode] = {}
    add(__callbacks[cb][mode], f)
end

function switch_mode(mode)
    if (mode == current_mode) return

    current_mode = mode
    if (current_mode != nil) exec_table(__callbacks['init'][current_mode])
end

function _init()
    exec_table(__callbacks['init'][default_mode])
end

function _update()
    exec_table(__callbacks['update'][default_mode])
    if (current_mode != nil) exec_table(__callbacks['update'][current_mode])
end

function _draw()
    cls()
    exec_table(__callbacks['draw'][default_mode])
    if (current_mode != nil)  exec_table(__callbacks['draw'][current_mode])
end

function exec_table(t)
    for f in all(t) do
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

-- update_players
register('update', 'level', function ()
    control_player(players[1], 0)
    local all_players_died = true

    for p in all(players) do
        -- move_player
        if (p.dying != nil) then
            local radius = 5
            local progress = lerp(0, 3, 1 - p.dying.v/p.dying.m)

            p.x = p.dx + progress * radius
            p.y = p.dy + ((progress-1)^2 - 1) * radius

            if (p.dying.v > 0) all_players_died = false

            -- log(p.x,p.y,p.dx,p.dy, p.dying)
        else
            all_players_died = false
            p.x = mid(screen_min_x, p.x + p.dx, screen_max_x - player_width)
            p.y += p.dy

            p.dx *= (1 - p.friction)
            p.dy *= (1 - p.friction)

            if (is_player_hit_by_ball(p)) then
                if (p.pwups.respawn.v == 0) then
                    p.lives = max(0, p.lives - 1)  -- loose live
                    p.pwups.respawn = timer(1)
                end
            end

            if (p.lives == 0) then
                p.pwups.respawn = timer(1)
                p.dying = timer(0.75)

                -- dx has the initial position
                p.dx = p.x
                p.dy = p.y
            end
        end


    end

    if (all_players_died) then
        log('all players died')
        switch_mode('main_menu')
    end

end)

-- draw_players
register('draw', 'level', function ()
    for p in all(players) do
        local m = p.pwups.respawn.v % 6
        local f = flr(p.firing.v / 5)

        local lspr = p.spr + f
        if (m < 3) spr(lspr, p.x, p.y)

        -- draw player shape
        if (draw_shapes) rect(p.x, p.y, p.x + p.w, p.y + p.h)
    end
end)

function control_player(p, control)
    if (p.dying != nil) return
    if (btn(⬅️, control)) p.dx -= p.speed
    if (btn(➡️, control)) p.dx += p.speed
    if (btnp(❎, control)) fire_bullet(p)
end

function is_player_hit_by_ball(p)
    for b in all(balls) do
        if (rect_circ_collide(p.x, p.y, p.w, p.h, b.x, b.y, b.sz)) return true
    end
    return false
end

function add_player(x, y)
    add(players, {
        spr = 1,
        x = x,
        y = y or screen_max_y - player_height,
        dx = 0,
        dy = 0,
        speed = player_speed,
        friction = player_friction,
        weapon = 1,
        h = player_height,
        w = player_width,
        lives = 3,
        max_lives = 3,
        points = 0,
        pwups = {
            respawn = timer(0)
        },
        firing = timer(0),
        dying = nil
    })
end

-->8
-- bullets
max_bullets = 1
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

function fire_bullet(p)
    if (#bullets >= max_bullets) return

    -- enable firing animation
    p.firing = timer(0.5)

    local w = weapons[p.weapon]
    add(bullets, {
        x = p.x + player_width/2 - w.w/2,
        y = p.y - player_height - 5,
        dx = w.dx,
        dy = w.dy,
        tp = p.weapon,
        w = w.w,
        h = w.h,
        p = p -- player
    })
    sfx(w.sfx)
end

-- move_bullets
register('update', 'level', function ()
    for i, b in pairs(bullets) do
        local b = bullets[i]
        b.x = b.x + b.dx
        b.y = b.y - b.dy

        -- remove bullet
        if (rect_is_offscreen(b.x, b.y, b.w, b.h)) deli(bullets, i)
    end
end)

-- draw_bullets
register('draw', 'level', function ()
    for b in all(bullets) do
        local w = weapons[b.tp]
        sspr(w.sprx, w.spry, w.w, w.h, b.x, b.y)

        -- draw bullet shape
        if (draw_shapes) rect(b.x, b.y, b.x + w.w, b.y + w.h)

        add_hud('w:'..b.x..', '..b.y..', '..b.dx..', '..b.dy)
    end
end)

-->8
-- balls

balls = {}
ball_tp = {
    [1] =  {
        sfx = 0,
        dx = 0,
        dy = 0,
        w = 8,
        h = 8,
        bounce = 1
    }
}

ball_sizes = {}
-- add(ball_sizes, {
--     sz = 2,
--     render = function (x, y) spr(66, x, y) end,
-- })
add(ball_sizes, {
    sz = 2,
    render = function (x, y) spr(65, x-2, y-2) end,
})
add(ball_sizes, {
    sz = 4,
    render = function (x, y) spr(64, x-4, y-4) end,
})
add(ball_sizes, {
    sz = 6,
    render = function (x, y) sspr(0, 32, 8, 8, x-6, y-6, 12, 12) end,
})
add(ball_sizes, {
    sz = 8,
    render = function (x, y) sspr(0, 32, 8, 8, x-8, y-8, 16, 16) end,
})
add(ball_sizes, {
    sz = 12,
    render = function (x, y) sspr(0, 32, 8, 8, x-12, y-12, 24, 24) end,
})
add(ball_sizes, {
    sz = 16,
    render = function (x, y) sspr(0, 32, 8, 8, x-16, y-16, 32, 32) end
})
max_ball_size = ball_sizes[#ball_sizes].sz

-- move_ball
register('update', 'level', function()
    local gravity = 0.1
    for i, b in pairs(balls) do
        local btp = ball_tp[b.tpid]
        local newx = b.x + b.dx
        local newy = b.y + b.dy

        -- bounce y axis
        if (circ_is_offscreen(-1, newy, b.sz)) then
            b.dy = -btp.bounce * lerp(speed(45), speed(105), b.sz/max_ball_size)
        end

        -- bounce x axis
        if (circ_is_offscreen(newx, -1, b.sz)) then
            b.dx *= -btp.bounce
        end

        local bullet_id = is_hit_by_bullet(b)
        if (bullet_id != 0) then
            if (b.szid - 1 > 0) then
                add_ball(b.tpid, b.szid - 1, b.x, b.y, b.dx, b.dy)
                add_ball(b.tpid, b.szid - 1, b.x, b.y, -b.dx, b.dy)
            end

            bullets[bullet_id].p.points += (#ball_sizes + 1 - b.szid) * 50
            deli(bullets, bullet_id)
            deli(balls, i)
        else
            b.x += b.dx
            b.y += b.dy

            -- smaller balls move faster in the x axis
            b.dx = sgn(b.dx) * lerp(speed(25), speed(55), 1/b.sz)

            -- all balls are affected by gravity
            b.dy += gravity
        end
    end
end)

-- draw_ball
register('draw', 'level', function ()
    for b in all(balls) do
        ball_sizes[b.szid].render(b.x, b.y)

        -- draw ball shape
        if (draw_shapes) circ(b.x,b.y, ball_sizes[b.szid].sz)

        -- add_hud('b:'..b.x..', '..b.y..', '..b.dx..', '..b.dy)
    end
    add_hud('#b: '.. #balls)
end)

function is_hit_by_bullet(ball)
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        if (rect_circ_collide(b.x, b.y, b.w, b.h, ball.x, ball.y, ball.sz)) then
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

screen_min_x = 4
screen_max_x = 124
screen_min_y = 24
screen_max_y = 124

levels = {
    [1] = {
        balls = {
            [1] = {
                tpid = 1,
                szid = #ball_sizes - 1,
                x = screen_max_x/2,
                y= screen_min_y + 40
            }
        },
        time = 100,
    }
}
current_level_time = nil
current_level = nil
lives_spr = 14
lives_spr_w = 7

-- draw_scene
register('draw', 'level', function ()
    local p1 = players[1]
    local p2 = players[2]

    -- draw dashboard
    -- origin coordinates
    camera(-1, -1)
    if (p1) then
        spr(p1.spr, 2, 0)
        print(p1.points, 12, 2)
        draw_lives(-7, p1.h + 2, p1)
    end

    if (current_level_time.v >= 3 * 30 or current_level_time.v % 6 < 3) then
        print_centered('time: '.. flr(current_level_time.v / 30))
    end

    camera()

    for i = 0, 16 do
        if (i * 8 >= screen_min_y) then
            spr(61, screen_min_x - 4, i * 8)
            spr(61, screen_max_x, i * 8)
        end
        spr(60, i * 8, screen_min_y - 4)
        spr(60, i * 8, screen_max_y)
    end

    -- draw_hud()
end)

function draw_lives(x, y, p)
    local m = p.pwups.respawn.v % 6
    local lives, max_lives = p.lives, p.max_lives

    for i = 1, max_lives  do
        local lspr = lives_spr
        if (i > lives) lspr += 1

        if (m < 3) then
            spr(lspr, x + (i * (lives_spr_w + 2)), y)
        end
    end
end

register('update', 'level', function ()
    if (current_level_time.v <= 0) players[1].lives = 0
end)


register('init', 'level', function ()
    restart_level(1)
end)

function restart_level(lid)
    lid = lid or current_level
    log('restarting level ', lid)

    -- clean up level
    balls = {}

    for b in all (levels[lid].balls) do
        add_ball(b.tpid, b.szid, b.x, b.y)
    end

    current_level_time = timer(levels[lid].time)
    current_level = lid
end

function rect_is_offscreen(x, y, w, h)
    local res_x =
        x != -1 and --disable this coordinate
        ( x < screen_min_x or
        x + w > screen_max_x )

    local res_y =
        y != -1 and --disable this coordinate
        ( y < screen_min_y or
        y + h > screen_max_y )

    return res_x or res_y
end

function circ_is_offscreen(x, y, r)
    local res_x =
        x != -1 and --disable this coordinate
        ( x - r < screen_min_x or
        x + r > screen_max_x )

    local res_y =
        y != -1 and --disable this coordinate
        ( y - r < screen_min_y or
        y + r > screen_max_y )

    return res_x or res_y
end

-->8
-- menus
register('init', 'main_menu', function ()
    players = {}
end)


register('draw', 'main_menu', function()
    print_centered('pang', 50)
    print_centered('game over', 60)
    print_centered('press ❎ to start', 70)
end)

function print_centered(str, y)
    print(str, screen_max_x/2 - (#str * 2), y)
end

register('update', 'main_menu', function()
    if(btnp(❎, 0)) then
        add_player(screen_max_x/2 - player_width)
        switch_mode('level')
    end
end)

-->8
-- game

register('init', function ()
    switch_mode('main_menu')
end)

register('update', function ()
    _move_timers() -- always move timers
end)



-->8
-- physiscs

function lerp(a, b, p)
    return (b - a) * p + a
end

function rect_rect_collide(x1, y1, w1, h1, x2, y2, w2, h2)
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

function rect_circ_collide(x1, y1, w, h, x2, y2, r)
    local closest_x, closest_y = nil, nil  -- closest rect points to circ

    if (x2 < x1) then
        closest_x = x1 -- left edge is closest
    elseif (x2 > x1 + w) then
        closest_x = x1 + w -- right edge is closest
    else
        closest_x = x2 -- circle center is within the edges
    end

    if (y2 < y1) then
        closest_y = y1 -- left edge is closest
    elseif (y2 > y1 + h) then
        closest_y = y1 + h -- right edge is closest
    else
        closest_y = y2 -- circle center is within the edges
    end

    local dist_x = x2 - closest_x
    local dist_y = y2 - closest_y
    local distance = sqrt(dist_x^2 + dist_y^2)

    return distance <= r
end

function speed(pps)
    return pps/30
end

timers = {}
function timer(v)  -- v in seconds
    add(timers, {
        v = v * 30,
        m = v * 30
    })
    return timers[#timers]
end

function _move_timers()
    for t in all(timers) do
        t.v = max(0, t.v - 1)
    end
end

__gfx__
00000000000000000555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000760066007600660
00000000055555500057d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007e87788670077006
00000000005dd5000057d500055555500000000000000000000000000000000000000000000000000000000000000000000000000000000068ae888d6000000d
000000000557d550005dd5005557d5550000000000000000000000000000000000000000000000000000000000000000000000000000000068ee822660000006
00000000057ddd50005dd5005d7dddd500000000000000000000000000000000000000000000000000000000000000000000000000000000d8822026d0000006
0000000005dddd50005dd5005dddddd5000000000000000000000000000000000000000000000000000000000000000000000000000000000620026006000060
00000000945dd594945dd594945dd594000000000000000000000000000000000000000000000000000000000000000000000000000000000062260000600600
00000000445555444455554444555544000000000000000000000000000000000000000000000000000000000000000000000000000000000006600000066000
00400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000770077007700770
04440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007887788770077007
406040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000078e8888770000007
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007888882d7000000d
06000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007888882d7000000d
0060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068882d0060000d0
000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000682d0000600d00
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d0000006d000
06000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000760066007600660
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007e87788670077006
000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068ae888d6000000d
006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068ee822660000006
0600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d8822026d0000006
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000620026006000060
00060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000062260000600600
00600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006600000066000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777777700000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000766d766d766d00000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000766d766d766d00000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555555500000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777700000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d7600000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d7600000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000555500000000000000000000
009999000a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
099a9990a99900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99a99999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999949000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09994490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000008750097500a7500b7500c7500e75011750157501a7501f74023730247202e70009000080000800025700080000000000000000000000000000000000000000000000000000000000000000000000000
