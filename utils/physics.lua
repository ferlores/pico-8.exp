
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
