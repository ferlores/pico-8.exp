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
