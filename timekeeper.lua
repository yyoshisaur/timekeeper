_addon.name = 'timekeeper'
_addon.command = 'timekeeper'
_addon.author = 'yoshisaur'
_addon.version = '0.01'
_addon.commands = { 'tk' }

require('luau')
require('pack')
local texts                  = require('texts')

local job_buff_map           = require('job_buff_map')
-- Meiryo
local ability_box            = texts.new({ pos = { x = 200, y = 400 }, padding = 1, bg = { alpha = 64 }, text = { font = 'MS Gothic', size = 10, stroke = { width = 2, alpha = 144 } }, flags = { bold = true, draggable = false } })
local spell_box              = texts.new({ pos = { x = 200, y = 500 }, padding = 1, bg = { alpha = 64 }, text = { font = 'MS Gothic', size = 10, stroke = { width = 2, alpha = 144 } }, flags = { bold = true, draggable = false } })
local buff_box_1_16          = texts.new({ pos = { x = 500, y = 135 }, padding = 1, bg = { alpha = 64 }, text = { font = 'MS Gothic', size = 8, stroke = { width = 2, alpha = 144 } }, flags = { bold = true, draggable = false } })
local buff_box_17_32         = texts.new({ pos = { x = 670, y = 135 }, padding = 1, bg = { alpha = 64 }, text = { font = 'MS Gothic', size = 8, stroke = { width = 2, alpha = 144 } }, flags = { bold = true, draggable = false } })
local focused_buff_box       = texts.new({ pos = { x = 600, y = 135 }, padding = 1, bg = { alpha = 64 }, text = { font = 'MS Gothic', size = 10, stroke = { width = 2, alpha = 144 } }, flags = { bold = true, draggable = false } })
local custom_timer_box       = texts.new({ pos = { x = 450, y = 500 }, padding = 1, bg = { alpha = 64 }, text = { font = 'MS Gothic', size = 10, stroke = { width = 2, alpha = 144 } }, flags = { bold = true, draggable = false } })
local prerender_tick         = 1 / 10
local postrender_tick        = 1 / 5
local prerender_update_time  = os.clock()
local postrender_update_time = os.clock()
local self_buff_1_16         = L {}
local self_buff_17_32        = L {}
local custom_timer           = L {}
local vana_offset            = 572662306 + 1009810800
local on_zone_change         = false

local is_self_buff_active    = false

local bar_colors             = (function()
    local colors = L {}
    for i = 1, 10 do
        r = math.floor(255 * (1 - (i - 1) / 9))
        g = math.floor(255 * ((i - 1) / 9))
        b = 0
        colors:append({ red = r, green = g, blue = b })
    end
    return colors
end)()

local function hpp_to_text(hpp)
    local hpp_level = math.ceil(hpp / 10)
    hpp_level = hpp_level < 1 and 1 or hpp_level
    hpp_level = hpp_level > 10 and 10 or hpp_level
    return string.format('%3d', hpp):text_color(bar_colors[hpp_level].red, bar_colors[hpp_level].green,
        bar_colors[hpp_level].blue)
end

local function time_to_string(time)
    if time == nil then return '' end
    local m = time / 60
    local s = time % 60
    if time < 10 then
        return string.format('%.1f', time):text_color(192, 0, 0)
    elseif time < 30 then
        return string.format('%02d:%02d', m, s):text_color(255, 128, 0)
    elseif time < 60 then
        return string.format('%02d:%02d', m, s):text_color(255, 192, 0)
    elseif time < 3600 then
        return string.format('%02d:%02d', m, s)
    else
        return '--:--'
    end
end

local function buff_to_colorize_text(buff_id, aka)
    local main_job = windower.ffxi.get_player().main_job
    local sub_job = windower.ffxi.get_player().sub_job
    local buff_name = res.buffs[buff_id].name
    if aka then
        buff_name = (job_buff_map.main[main_job].aka and job_buff_map.main[main_job].aka[buff_id]) and
            job_buff_map.main[main_job].aka[buff_id] or buff_name
        buff_name = (job_buff_map.sub[sub_job] and job_buff_map.sub[sub_job].aka and job_buff_map.sub[sub_job].aka[buff_id]) and
            job_buff_map.sub[sub_job].aka[buff_id] or buff_name
    end
    if job_buff_map.debuff.id:contains(buff_id) then
        local c = job_buff_map.debuff.color
        return string.format('%s', buff_name):text_color(c.red, c.green, c.blue)
    elseif job_buff_map.rune.id:contains(buff_id) then
        local c = job_buff_map.rune.color[buff_id]
        return string.format('%s', buff_name):text_color(c.red, c.green, c.blue)
    elseif job_buff_map.maneuver.id:contains(buff_id) then
        local c = job_buff_map.maneuver.color[buff_id]
        return string.format('%s', buff_name):text_color(c.red, c.green, c.blue)
    elseif job_buff_map.storm.id:contains(buff_id) then
        local c = job_buff_map.storm.color[buff_id]
        return string.format('%s', buff_name):text_color(c.red, c.green, c.blue)
    elseif job_buff_map.bar_element.id:contains(buff_id) then
        local c = job_buff_map.bar_element.color[buff_id]
        return string.format('%s', buff_name):text_color(c.red, c.green, c.blue)
    else
        return string.format('%s', buff_name):text_color(255, 255, 255)
    end
end

local function update_ability_recast()
    local ability_recasts = windower.ffxi.get_ability_recasts()
    local main_job = windower.ffxi.get_player().main_job
    local sub_job = windower.ffxi.get_player().sub_job
    local recast_ability_text = L {}
    local ability_dupe = L { 10 }
    for i, v in pairs(ability_recasts) do
        if not ability_dupe:contains(i) then
            if v > 0 then
                if job_buff_map.ability_charge.id:contains(i) then
                    local charge = job_buff_map.ability_charge.get_charge(i, v)
                    recast_ability_text:append(string.format('%s [%d/%d] %s', res.ability_recasts[i].ja,
                        charge.max - charge.used, charge.max, time_to_string(charge.recast)))
                elseif job_buff_map.sp.id:contains(i) then
                    recast_ability_text:append(string.format('%s %s', job_buff_map.sp.name[main_job][i],
                        time_to_string(v)))
                else
                    recast_ability_text:append(string.format('%s %s', res.ability_recasts[i].ja, time_to_string(v)))
                end
            end
        end
    end
    ability_box:clear()
    if recast_ability_text.n > 0 then
        ability_box:append('◤ ABILITY RECAST ◥\n')
        ability_box:append(recast_ability_text:concat('\n'))
        ability_box:show()
    else
        ability_box:hide()
    end
end

local function update_spell_recast()
    local spell_recasts = windower.ffxi.get_spell_recasts()
    local recast_spell_text = L {}
    for i, v in ipairs(spell_recasts) do
        if v > 0 then
            recast_spell_text:append(string.format('%s %s', res.spells[i].ja, time_to_string(v / 60)))
        end
    end
    spell_box:clear()
    if recast_spell_text.n > 0 then
        spell_box:append('◤ SPELL RECAST ◥\n')
        spell_box:append(recast_spell_text:concat('\n'))
        spell_box:show()
    else
        spell_box:hide()
    end
end

local function calc_remained_buff_time(buff)
    if not job_buff_map.geo_buff:contains(buff.id) and not job_buff_map.smn_favor:contains(buff.id) then
        local remained_time = buff.duration - (os.time() - buff.update_time)
        return remained_time >= 0 and remained_time or nil
    end
    return nil
end

local function update_self_buff(self_buff, buff_text)
    buff_text:clear()
    if self_buff.n > 0 then
        local b = L(windower.ffxi.get_player().buffs)
        buff_text:append(self_buff:map(function(buff)
            if buff.duration >= 0 or b:contains(buff.id) then
                local remained_time = calc_remained_buff_time(buff)
                local aka = false
                return
                    string.format('%3d %s %s',
                        buff.id,
                        string.format('%s%s', buff_to_colorize_text(buff.id, aka),
                            (job_buff_map.geo_buff:contains(buff.id) and '[Geo]' or '')),
                        time_to_string(remained_time))
            else
                return nil
            end
        end):concat('\n'))
        buff_text:show()
    else
        buff_text:hide()
    end
end

local function pinned_sch_grimoire(b_pinned)
    local b = L(windower.ffxi.get_player().buffs)
    local light_arts_t1 = job_buff_map.sch_arts.id['Light Arts']
    local light_arts_t2 = job_buff_map.sch_arts.id['Addendum: White']
    local dark_arts_t1 = job_buff_map.sch_arts.id['Dark Arts']
    local dark_arts_t2 = job_buff_map.sch_arts.id['Addendum: Black']
    return b_pinned:filter(function(buff)
        if light_arts_t1 == buff.id then
            if b:contains(light_arts_t2) then
                return false
            end
        elseif dark_arts_t1 == buff.id then
            if b:contains(dark_arts_t2) then
                return false
            end
        elseif light_arts_t2 == buff.id then
            if b:contains(dark_arts_t1) then
                return false
            elseif b:contains(dark_arts_t2) then
                return false
            end

            if not (b:contains(light_arts_t1) or b:contains(light_arts_t2)) then
                return false
            end
        elseif dark_arts_t2 == buff.id then
            if b:contains(light_arts_t1) then
                return false
            elseif b:contains(light_arts_t2) then
                return false
            end

            if not (b:contains(dark_arts_t1) or b:contains(dark_arts_t2)) then
                return false
            end
        end
        return true
    end)
end

local function pet_info_to_string()
    local me = windower.ffxi.get_mob_by_target('me')
    if me and me.pet_index then
        local pet = windower.ffxi.get_mob_by_target('pet')
        if pet and pet.hpp then
            return string.format('%s %s %s %%', string.text_color('Ⓟ', 225, 196, 0), pet.name, hpp_to_text(pet.hpp))
        end
    end
end

local function update_focused_buff()
    local focued = L {}
    local pinned = L {}
    local main_job = windower.ffxi.get_player().main_job
    local sub_job = windower.ffxi.get_player().sub_job
    local b = L(windower.ffxi.get_player().buffs)

    -- focused_buff_box:clear()
    -- focused_buff_box:append('◤ FOCUSED BUFFS ◥\n')

    local pet_str = pet_info_to_string()
    -- if pet_str then
    --     focused_buff_box:append(string.format('%s\n', pet_str))
    -- end

    local b_1_32 = self_buff_1_16 + self_buff_17_32
    local b_pinned = L(job_buff_map.common.pinned:map(function(id) return { id = id, duration = 0, update_time = nil } end)) +
        L(job_buff_map.debuff.pinned:map(function(id) return { id = id, duration = 0, update_time = nil } end)) +
        L(job_buff_map.main[main_job].pinned:map(function(id) return { id = id, duration = 0, update_time = nil } end)) +
        (sub_job and L(job_buff_map.sub[sub_job].pinned:map(function(id) return { id = id, duration = 0, update_time = nil } end)) or L {})

    if main_job == 'SCH' or sub_job == 'SCH' then
        b_pinned = pinned_sch_grimoire(b_pinned)
    end

    for i, p in ipairs(b_pinned) do
        for _, b in ipairs(b_1_32) do
            if p.id == b.id then
                b_pinned[i].duration = b.duration
                b_pinned[i].update_time = b.update_time
            end
        end
    end

    pinned = b_pinned:map(function(buff)
        local aka = true
        if buff.update_time then
            local remained_time = calc_remained_buff_time(buff)
            return
                string.format('%s %s %s',
                    string.text_color('✔', 0, 255, 192),
                    string.format('%s%s', buff_to_colorize_text(buff.id, aka),
                        (job_buff_map.geo_buff:contains(buff.id) and '[Geo]' or '')),
                    time_to_string(remained_time))
        else
            return
                string.format('%s %s',
                    string.text_color('✖', 255, 0, 96),
                    string.format('%s%s', buff_to_colorize_text(buff.id, aka),
                        (job_buff_map.geo_buff:contains(buff.id) and '[Geo]' or '')))
        end
    end)
    -- focused_buff_box:append(pinned:concat('\n'))

    focued = b_1_32:map(function(buff)
        if job_buff_map.common.focused:contains(buff.id) or
            job_buff_map.debuff.focused:contains(buff.id) or
            job_buff_map.main[main_job].focused:contains(buff.id) or
            (job_buff_map.sub[sub_job] and job_buff_map.sub[sub_job].focused:contains(buff.id)) then
            if buff.duration >= 0 and b:contains(buff.id) then
                local remained_time = calc_remained_buff_time(buff)
                local aka = true
                return
                    string.format('%s %s %s',
                        string.text_color('❤', 255, 128, 255),
                        string.format('%s%s', buff_to_colorize_text(buff.id, aka),
                            (job_buff_map.geo_buff:contains(buff.id) and '[Geo]' or '')),
                        time_to_string(remained_time))
            else
                return nil
            end
        else
            return nil
        end
    end)
    -- focused_buff_box:append('\n')
    -- focused_buff_box:append(focued:concat('\n'))

    if pet_str or pinned or focued then
        focused_buff_box:clear()
        focused_buff_box:append('◤ FOCUSED BUFFS ◥')
        if pet_str then
            focused_buff_box:append('\n')
            focused_buff_box:append(string.format('%s', pet_str))
        end
        if pinned then
            focused_buff_box:append('\n')

            focused_buff_box:append(pinned:concat('\n'))
        end
        if focued then
            focused_buff_box:append('\n')
            focused_buff_box:append(focued:concat('\n'))
        end
        focused_buff_box:show()
    end
    -- focused_buff_box:show()
end

local function update_custom_timer()
    custom_timer_box:clear()

    local custom_timer_text = L {}
    for timer in custom_timer:it() do
        if timer.count_mode == 'down' then
            local remained_time = timer.count - (os.clock() - timer.update_time)
            if remained_time >= 0 then
                custom_timer_text:append(string.format('%s %s', timer.name, time_to_string(remained_time)))
            end
        elseif timer.count_mode == 'up' then
            local elapsed_time = os.clock() - timer.update_time
            if elapsed_time <= timer.count then
                custom_timer_text:append(string.format('%s %s', timer.name, time_to_string(elapsed_time)))
            end
        end
    end
    if custom_timer_text.n > 0 then
        custom_timer_box:append(custom_timer_text:concat('\n'))
        custom_timer_box:show()
    else
        custom_timer_box:hide()
    end
end

local function hide_all()
    ability_box:hide()
    spell_box:hide()
    buff_box_1_16:hide()
    buff_box_17_32:hide()
    focused_buff_box:hide()
    custom_timer_box:hide()
end

windower.register_event('prerender', function()
    local current_time = os.clock()
    local player = windower.ffxi.get_player()
    if current_time < prerender_update_time + prerender_tick then return end
    if on_zone_change or not player or player.status == 4 then
        hide_all()
        return
    end
    update_ability_recast()
    update_spell_recast()
    if is_self_buff_active then
        update_self_buff(self_buff_1_16, buff_box_1_16)
        update_self_buff(self_buff_17_32, buff_box_17_32)
    end
    prerender_update_time = current_time
end)

windower.register_event('postrender', function()
    local current_time = os.clock()
    local player = windower.ffxi.get_player()
    if current_time < postrender_update_time + postrender_tick then return end
    if on_zone_change or not player or player.status == 4 then
        hide_all()
        return
    end
    update_focused_buff()
    update_custom_timer()
    postrender_update_time = current_time
end)

local incoming_handler = {
    [0x0A] = function(data)
        on_zone_change = false
    end,
    [0x0B] = function(data)
        on_zone_change = true
    end,
    [0x037] = function(data)
        if not data then return end
        vana_offset = os.time() - (((data:unpack("I", 0x41) * 60 - data:unpack("I", 0x3D)) % 0x100000000) / 60)
    end,
    [0x063] = function(data)
        if not data then return end
        if data:byte(0x05) == 0x09 then
            local b_1_16 = L {}
            local b_17_32 = L {}

            for n = 1, 32 do
                local buff_id = data:unpack('H', n * 2 + 7)
                local buff_ts = data:unpack('I', n * 4 + 69)

                if buff_ts == 0 then
                    break
                elseif buff_id ~= 255 and buff_ts ~= nil then
                    local duration = buff_ts / 60 - os.time() + (vana_offset or 0)
                    if n <= 16 then
                        b_1_16:append({ id = buff_id, duration = duration, update_time = os.time() })
                    else
                        b_17_32:append({ id = buff_id, duration = duration, update_time = os.time() })
                    end
                end
            end

            self_buff_1_16 = b_1_16
            self_buff_17_32 = b_17_32
        end
    end,
}

windower.register_event('incoming chunk', function(id, data)
    if incoming_handler[id] then
        incoming_handler[id](data)
    end
end)

windower.register_event('addon command', function(command, ...)
    local args = T { ... }
    if command == 'add' then
        local timer_name = windower.from_shift_jis(windower.convert_auto_trans(args[1]))
        local timer_count = tonumber(args[2])
        local update_time = os.clock()
        local count_mode = args[3] or 'down'

        local timer_exists = false
        custom_timer = custom_timer:map(function(timer)
            if timer.name == timer_name then
                timer_exists = true
                timer.count = timer_count
                timer.update_time = update_time
                timer.count_mode = count_mode
            end
            return timer
        end)

        if not timer_exists then
            custom_timer:append({
                name = timer_name,
                count = timer_count,
                update_time = update_time,
                count_mode =
                    count_mode
            })
        end
    elseif command == 'remove' then
        local timer_name = windower.from_shift_jis(windower.convert_auto_trans(args[1]))
        custom_timer = custom_timer:filter(function(timer)
            return timer.name ~= timer_name
        end)
    elseif command == 'selfbuff' then
        is_self_buff_active = not is_self_buff_active
        log('Self Buff: ', is_self_buff_active)
    else
        log('//tk add [timer_name] [timer_count] [count_mode(up/down)]')
        log('//tk remove [timer_name]')
        log('//tk selfbuff')
    end
end)

incoming_handler[0x037](windower.packets.last_incoming(0x037))
incoming_handler[0x063](windower.packets.last_incoming(0x063))
