# 練習問題
簡易版`timers`

テキストベースでもよい

# TODO

## カスタムタイマー
* 追加/削除
* カウントアップ/カウントダウン

## バフタイマー
* ピン止め
* ホワイトリスト/ブラックリスト
* デバフの色付け
* 風水/召喚加護/マニューバ/ルーン
* 別名
* アビリティのリキャストもピン止め（バフと同一の扱い）

## リキャストタイマー
- 戦術魔導書のチャージ
    - レベル・ギフト
    
            Lv10 1 240s
            Lv30 2 120s
            Lv50 3 80s
            Lv70 4 60s
            Lv90 5 48s
            G550 5 33s
- しじさせろのチャージ
    - メリポ・ギフト
            
            メリポ -10s, -2s/メリポ
            G550 -5s
            装備 -5s (グレティブリーチズ etc)
- クイックドロー
    - メリポ・ギフト
    
            メリポ -10s, -2s/メリポ
            G550 -10s

## 参考文献
[チャージの計算(discordリンク)](https://discord.com/channels/338590234235371531/501099968539525126/1275888648230801449)

```lua
bit = require('bit')
require('luau')
packets = require('packets')

ability_recast = L{
    {ctype='unsigned short',    label='Duration',       --[[fn=div+{1}]]},            -- 00 -- base recast
    {ctype='unsigned char',     label='Recast Percent'},                        -- 02 -- X/60 CDR
    {ctype='unsigned char',     label='Recast',         --[[fn=arecast]]},            -- 03 -- JA Recast ID
    {ctype='signed short',      label='Recast Modifier'},                       -- 04    in seconds, for charges
    {ctype='unsigned short',    label='_unknown2'}                              -- 06 -- just padding
}

-- Ability timers
packets.raw_fields.incoming[0x119] = L{
    {ref=ability_recast,                                    count=0x1F},        -- 04
    {ctype='unsigned int',      label='Mount Recast'},                          -- beeg number TODO
    {ctype='unsigned int',      label='Mount Recast ID'},                       -- beeg number + 4 TODO
}
function get_max_charge_data()
    player = windower.ffxi.get_player()
    --use player info to calculate max charges for stuff here
    return {
        [102] = 0, -- Sic/Ready TODO
        [195] = 2, -- Quick Draw TODO
        [233] = 0, -- Stratagems TODO
    }
end
local base_times = {
    [102] = 90, -- Sic/Ready
    [195] = 120, -- Quick Draw
    [233] = 240, -- Stratagems
}
function get_base_time(recast_id)
    return base_times[recast_id]
end

function get_ability_charge_info()
    local packet = windower.packets.last_incoming(0x119)
    if not packet then return 0 end
    local charge_data = get_max_charge_data()
    p = packets.parse('incoming', packet)
    local ability_timers = nil
    for index = 1, 0x1F do
        local recast_id = p['Recast '..index]
        local max_charges = charge_data[recast_id]
        if max_charges and max_charges == 0 then
            charge_data[recast_id] = {max=0, current=0, time_to_full=0, time_to_next=0, time_per_charge=0}
        elseif max_charges then
            local base_recast = get_base_time(recast_id) + p['Recast Modifier '..index]
            local recast_reduction_percent = bit.band(p['Recast Percent '..index], 0x3F) * 0.016666668
            local charge_time_total = base_recast * (1 - recast_reduction_percent)
            local charge_time_per_charge = charge_time_total / max_charges
            if not ability_timers then
                ability_timers = ability_timers or windower.ffxi.get_ability_recasts()
            end
            local charges = math.floor((charge_time_total - math.ceil(ability_timers[recast_id])) / charge_time_per_charge)
            local time_to_next_charge = math.ceil(ability_timers[recast_id]) % charge_time_per_charge -- TODO maybe make this more accurate rather than using ceil and modulo only
            if  (time_to_next_charge == 0 or time_to_next_charge ~= time_to_next_charge --[[NaN]]) and ability_timers[recast_id] > 0 then
                time_to_next_charge = charge_time_per_charge
            end
            charge_data[recast_id] = {max=max_charges, current=charges, time_to_full=ability_timers[recast_id], time_to_next=time_to_next_charge, time_per_charge=charge_time_per_charge}
        end
    end
    return charge_data
end

table.vprint(get_ability_charge_info())
```