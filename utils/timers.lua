__timers = {}
function timer(v)  -- v in seconds
    add(__timers, {
        v = v * 30,
        m = v * 30
    })
    return __timers[#__timers]
end

function __move_timers()
    for t in all(__timers) do
        t.v = max(0, t.v - 1)
    end
end

-- register __move_timers if callback dependency is present
if (type(register) == 'function') then
    register('update', __move_timers)
end
