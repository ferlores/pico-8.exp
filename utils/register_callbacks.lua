__default_mode = '__default'
__current_mode = nil
__callbacks = {
    ['init'] = {
        [__default_mode] = {}
    },
    ['update'] = {
        [__default_mode] = {}
    },
    ['draw'] = {
        [__default_mode] = {}
    },
    ['destroy'] = {
        [__default_mode] = {}
    }
}


function register(cb, mode, f)
    if (type(mode) == 'function') then
        f = mode
        mode = __default_mode
    end

    if (__callbacks[cb][mode] == nil) __callbacks[cb][mode] = {}
    add(__callbacks[cb][mode], f)
end

function switch_mode(mode)
    if (mode == __current_mode) return

    __current_mode = mode
    if (__current_mode != nil) exec_table(__callbacks['init'][__current_mode])
end

function _init()
    exec_table(__callbacks['init'][__default_mode])
end

function _update()
    exec_table(__callbacks['update'][__default_mode])
    if (__current_mode != nil) exec_table(__callbacks['update'][__current_mode])
end

function _draw()
    cls()
    exec_table(__callbacks['draw'][__default_mode])
    if (__current_mode != nil)  exec_table(__callbacks['draw'][__current_mode])
end

function exec_table(t)
    for f in all(t) do
        f()
    end
end
