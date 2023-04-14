-- debug flags
draw_shapes = false

register('init', 'level', function ()
    restart_level(1)
end)

register('update', 'level', function()
    update_level()
    move_players()
    move_bullets()
    move_balls()
    move_pwup()
end)

register('draw', 'level', function()
    draw_players()
    draw_bullets()
    draw_balls()
    draw_pwup()
    draw_level()
end)


-------------
-- players
-------------
player_speed = 0.5
player_friction = 0.3
player_width = 8
player_height = 8
players = {}

function move_players()
    control_player(players[1], 0)
    local all_players_died = true

    for p in all(players) do
        -- dying animation
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

            collect_pwup(p)

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

end

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
        wpid = 1,
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

function draw_players()
    for p in all(players) do
        local m = p.pwups.respawn.v % 6
        local f = flr(p.firing.v / 5)

        local lspr = p.spr + f
        if (m < 3) spr(lspr, p.x, p.y)

        -- draw player shape
        if (draw_shapes) rect(p.x, p.y, p.x + p.w, p.y + p.h)
    end
end

-----------
-- pwups
-----------
pwups = {}

function add_pwup(x, y)
    -- 30% cahnce of dropping
    if (flr(rnd(11)) >= 3) return

    local wpid = (flr(rnd(#weapons) * 100) % #weapons) + 1
    local wp = weapons[wpid]

    add(pwups, {
        wpid = wpid,
        x = x,
        y = y,
        dy = 1,
        spr = wp.drop.spr,
        w = wp.drop.w,
        h = wp.drop.h
    })
end

function move_pwup(x, y)
    for pwup in all(pwups) do
        pwup.y = min(pwup.y + pwup.dy, screen_max_y - pwup.h)
    end
end

function draw_pwup()
    for pwup in all(pwups) do
        spr(pwup.spr, pwup.x, pwup.y)
    end
end

function collect_pwup(p)
    for k, pwup in pairs(pwups) do
        if (rect_rect_collide(p.x, p.y, p.w, p.h, pwup.x, pwup.y, pwup.w, pwup.h)) then
            p.wpid = pwup.wpid
            deli(pwups, k)
        end
    end
end

------------
-- bullets
------------
bullets = {}
weapons = {
    [1] =  {
        sprx = 0,
        spry = 8,
        sfx = 0,
        dx = 0,
        dy = 3,
        w = 5,
        h = 16,
        max_bullets = 1,
        drop = {
            spr = 54,
            w = 5,
            h = 4
        }
    },
    [2] =  {
        sprx = 0,
        spry = 8,
        sfx = 0,
        dx = 0,
        dy = 3,
        w = 5,
        h = 16,
        max_bullets = 2,
        drop = {
            spr = 48,
            w = 7,
            h = 4
        }
    }
}

function fire_bullet(p)
    local w = weapons[p.wpid]
    if (#bullets >= w.max_bullets) return

    -- enable firing animation
    p.firing = timer(0.5)

    add(bullets, {
        x = p.x + player_width/2 - w.w/2,
        y = p.y - player_height - 5,
        dx = w.dx,
        dy = w.dy,
        tp = p.wpid,
        w = w.w,
        h = w.h,
        p = p -- player
    })
    sfx(w.sfx)
end

function move_bullets()
    for i, b in pairs(bullets) do
        local b = bullets[i]
        b.x = b.x + b.dx
        b.y = b.y - b.dy

        -- remove bullet
        if (rect_is_offscreen(b.x, b.y, b.w, b.h)) deli(bullets, i)
    end
end

function draw_bullets()
    for b in all(bullets) do
        local w = weapons[b.tp]
        sspr(w.sprx, w.spry, w.w, w.h, b.x, b.y)

        -- draw bullet shape
        if (draw_shapes) rect(b.x, b.y, b.x + w.w, b.y + w.h)

        add_hud('w:'..b.x..', '..b.y..', '..b.dx..', '..b.dy)
    end
end

-----------
-- balls
-----------
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

function move_balls()
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

            add_pwup(b.x, b.y)

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
end

function draw_balls()
    for b in all(balls) do
        ball_sizes[b.szid].render(b.x, b.y)

        -- draw ball shape
        if (draw_shapes) circ(b.x,b.y, ball_sizes[b.szid].sz)

        -- add_hud('b:'..b.x..', '..b.y..', '..b.dx..', '..b.dy)
    end
    add_hud('#b: '.. #balls)
end

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

------------
-- level
------------
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

function draw_level()
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
end

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

function update_level()
    -- level timeout
    if (current_level_time.v <= 0) then
        for p in all (players) do
            p.lives = 0
        end
    end
end

function restart_level(lid)
    lid = lid or current_level
    log('restarting level ', lid)

    -- clean up level
    balls = {}
    pwups = {}

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
