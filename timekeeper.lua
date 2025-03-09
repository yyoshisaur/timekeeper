_addon.name = 'timekeeper'
_addon.command = 'timekeeper'
_addon.author = 'yoshisaur'
_addon.version = '0.01'
_addon.commands = {'tk'}

require('luau')
require('pack')
local texts = require('texts')

local job_buff_map = require('job_buff_map')
-- Meiryo
local ability_text      = texts.new({pos={x=110,y=300},padding=1,bg={alpha=64},text={font='MS Gothic', size=10,stroke={width = 2,alpha=144}},flags={bold=true}})
local spell_text        = texts.new({pos={x=130,y=500},padding=1,bg={alpha=64},text={font='MS Gothic', size=10,stroke={width = 2,alpha=144}},flags={bold=true}})
local buff_text_1_16    = texts.new({pos={x=600,y=300},padding=1,bg={alpha=64},text={font='MS Gothic', size=8,stroke={width = 2,alpha=144}},flags={bold=true}})
local buff_text_17_32   = texts.new({pos={x=770,y=300},padding=1,bg={alpha=64},text={font='MS Gothic', size=8,stroke={width = 2,alpha=144}},flags={bold=true}})
local focused_buff_text = texts.new({pos={x=280,y=300},padding=1,bg={alpha=64},text={font='MS Gothic', size=10,stroke={width = 2,alpha=144}},flags={bold=true}})
local custom_timer_text = texts.new({pos={x=450,y=500},padding=1,bg={alpha=64},text={font='MS Gothic', size=10,stroke={width = 2,alpha=144}},flags={bold=true}})
local tick = 1/15
local update_time = os.clock()
local self_buff_1_16 = L{}
local self_buff_17_32 = L{}
local custom_timer = L{}
local vana_offset = 572662306+1009810800

function time_to_string(time)
    if time == nil then return '' end
    local m = time/60
    local s = time%60
    if time < 10 then
        return string.format('%.1f', time):text_color(192, 0, 0)
    elseif time < 30 then
        return string.format('%02d:%02d', m, s):text_color(255, 128, 0)
    elseif time < 60 then
        return string.format('%02d:%02d', m, s):text_color(255, 192, 0)
    else
        return string.format('%02d:%02d', m, s)
    end
end

function buff_to_colorize_text(buff_id, aka)
    local main_job = windower.ffxi.get_player().main_job
    local sub_job = windower.ffxi.get_player().sub_job
    local buff_name = res.buffs[buff_id].name
    if aka then
        buff_name = (job_buff_map.main[main_job].aka and job_buff_map.main[main_job].aka[buff_id]) and job_buff_map.main[main_job].aka[buff_id] or buff_name
        buff_name = (job_buff_map.sub[sub_job] and job_buff_map.sub[sub_job].aka and job_buff_map.sub[sub_job].aka[buff_id]) and job_buff_map.sub[sub_job].aka[buff_id] or buff_name
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

function update_ability_recast()
    local ability_recasts = windower.ffxi.get_ability_recasts()
    local main_job = windower.ffxi.get_player().main_job
    local sub_job = windower.ffxi.get_player().sub_job
    local recast_ability_text = L{}
    for i,v in pairs(ability_recasts) do
        if v > 0 then
            if job_buff_map.ability_charge.id:contains(i) then
                local charge = job_buff_map.ability_charge.get_charge(i, v)
                recast_ability_text:append(string.format('%s [%d/%d] %s', res.ability_recasts[i].ja, charge.max-charge.used, charge.max, time_to_string(charge.recast)))
            elseif job_buff_map.sp.id:contains(i) then
                recast_ability_text:append(string.format('%s %s', job_buff_map.sp.name[main_job][i], time_to_string(v)))
            else
                recast_ability_text:append(string.format('%s %s', res.ability_recasts[i].ja, time_to_string(v)))
            end
        end
    end
    ability_text:clear()
    if recast_ability_text.n > 0 then
        ability_text:append('◤ ABILITY RECAST ◥\n')
        ability_text:append(recast_ability_text:concat('\n'))
        ability_text:show()
    else
        ability_text:hide()
    end
end

function update_spell_recast()
    local spell_recasts = windower.ffxi.get_spell_recasts()
    local recast_spells_text = L{}
    for i,v in pairs(spell_recasts) do
        if v > 0 then
            recast_spells_text:append(string.format('%s %s', res.spells[i].ja, time_to_string(v/60)))
        end
    end
    spell_text:clear()
    if recast_spells_text.n > 0 then
        spell_text:append('◤ SPELL RECAST ◥\n')
        spell_text:append(recast_spells_text:concat('\n'))
        spell_text:show()
    else
        spell_text:hide()
    end
end

function calc_remained_buff_time(buff)
    if not job_buff_map.geo_buff:contains(buff.id) and not job_buff_map.smn_favor:contains(buff.id) then
        local remained_time = buff.duration - (os.time() - buff.update_time)
        return remained_time >= 0 and remained_time or nil
    end
    return nil
end

function update_self_buff(self_buff, buff_text)
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
                        string.format('%s%s', buff_to_colorize_text(buff.id, aka), (job_buff_map.geo_buff:contains(buff.id) and '[Geo]'or '')),
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

function pinned_sch_grimoire(b_pinned)
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

function update_focused_buff()
    local focued = L{}
    local pinned = L{}
    local main_job = windower.ffxi.get_player().main_job
    local sub_job = windower.ffxi.get_player().sub_job
    local b = L(windower.ffxi.get_player().buffs)

    focused_buff_text:clear()
    focused_buff_text:append('◤ FOCUSED BUFFS ◥\n')
    
    local b_1_32 = self_buff_1_16 + self_buff_17_32
    local b_pinned = L(job_buff_map.common.pinned:map(function(id) return {id = id, duration = 0, update_time = nil} end)) + 
                     L(job_buff_map.debuff.pinned:map(function(id) return {id = id, duration = 0, update_time = nil} end)) +
                     L(job_buff_map.main[main_job].pinned:map(function(id) return {id = id, duration = 0, update_time = nil} end)) +
                     (sub_job and L(job_buff_map.sub[sub_job].pinned:map(function(id) return {id = id, duration = 0, update_time = nil} end)) or L{})

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
                    '✔':text_color(0, 255, 192),
                    string.format('%s%s', buff_to_colorize_text(buff.id, aka), (job_buff_map.geo_buff:contains(buff.id) and '[Geo]'or '')),
                    time_to_string(remained_time))
        else
            return
                string.format('%s %s',
                    '✖':text_color(255, 0, 96),
                    string.format('%s%s', buff_to_colorize_text(buff.id, aka), (job_buff_map.geo_buff:contains(buff.id) and '[Geo]'or '')))
        end
    end)
    focused_buff_text:append(pinned:concat('\n'))

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
                        '❤':text_color(255, 128, 255),
                        string.format('%s%s', buff_to_colorize_text(buff.id, aka), (job_buff_map.geo_buff:contains(buff.id) and '[Geo]'or '')),
                        time_to_string(remained_time))
            else
                return nil
            end
        else
            return nil
        end
    end)
    focused_buff_text:append('\n')
    focused_buff_text:append(focued:concat('\n'))
    focused_buff_text:show()
end

function update_custom_timer()
    custom_timer_text:clear()
    custom_timer_text:append(custom_timer:map(function(timer)
        if timer.count_mode == 'down' then
            local remained_time = timer.count - (os.clock() - timer.update_time)
            if remained_time >= 0 then
                return string.format('%s %s', timer.name, time_to_string(remained_time))
            end
        elseif timer.count_mode == 'up' then
            local elapsed_time = os.clock() - timer.update_time
            if elapsed_time <= timer.count then
                return string.format('%s %s', timer.name, time_to_string(elapsed_time))
            end
        end
    end):concat('\n'))
    if custom_timer.n > 0 then
        custom_timer_text:show()
    else
        custom_timer_text:hide()
    end
end

function hide_all()
    ability_text:hide()
    spell_text:hide() 
    buff_text_1_16:hide()
    buff_text_17_32:hide()
    focused_buff_text:hide()
    custom_timer_text:hide()
end

windower.register_event('prerender', function()
    local current_time = os.clock()
    if current_time < update_time + tick then return end
    if not windower.ffxi.get_player() then hide_all() return end
    update_ability_recast()
    update_spell_recast()
    update_self_buff(self_buff_1_16, buff_text_1_16)
    update_self_buff(self_buff_17_32, buff_text_17_32)
    update_focused_buff()
    update_custom_timer()
    update_time = current_time
end)

local incoming_handler = {
    [0x037] = function(data)
        if not data then return end
        vana_offset = os.time() - (((data:unpack("I",0x41)*60 - data:unpack("I",0x3D)) % 0x100000000) / 60)
    end,
    [0x063] = function(data)
        if not data then return end
        if data:byte(0x05) == 0x09 then
            local b_1_16 = L{}
            local b_17_32 = L{}

            for n=1,32 do
                local buff_id = data:unpack('H', n*2+7)
                local buff_ts = data:unpack('I', n*4+69)

                if buff_ts == 0 then
                    break
                elseif buff_id ~= 255 and buff_ts ~= nil then
                    local duration = buff_ts/60 - os.time() + (vana_offset or 0)
                    if n <= 16 then
                        b_1_16:append({id = buff_id, duration = duration, update_time = os.time()})
                    else
                        b_17_32:append({id = buff_id, duration = duration, update_time = os.time()})
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
    local args = T{...}
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
            custom_timer:append({name = timer_name, count = timer_count, update_time = update_time, count_mode = count_mode})
        end        
    elseif command == 'remove' then
        local timer_name = windower.from_shift_jis(windower.convert_auto_trans(args[1]))
        custom_timer = custom_timer:filter(function(timer)
            return timer.name ~= timer_name
        end)
    else
        log('//bufftimers add [timer_name] [timer_count] [count_mode(up/down)]')
        log('//bufftimers remove [timer_name]')
    end
end)

incoming_handler[0x037](windower.packets.last_incoming(0x037))
incoming_handler[0x063](windower.packets.last_incoming(0x063))
