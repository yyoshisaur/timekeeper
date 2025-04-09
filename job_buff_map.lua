local map = {}

map.common = {}
map.common.focused = S{
    253, -- シグネット
    256, -- サンクション
    268, -- シギル
    512, -- イオニス
    602, -- 神符
    629, -- モグアンプ
    69, -- インビジ
    70, -- デオード
    71 -- スニーク
}
map.common.pinned = S{251}
map.debuff = {}
map.debuff.id = S{
      1,  2,  3,  4,  5,
      6,  7,  8,  9, 10,
     11, 12, 13, 14, 15,
     16, 17, 18, 19, 20,
     21, 22, 23, 28, 29,
     30, 31,
    128,129,130,131,132,
    133,134,135,136,137,
    138,139,140,141,142,
    144,145,146,147,148,
    149,156,167,168,174,
    175,177,186,192,193,
    194,223,404,540,557,
    558,559,560,561,562,
    563,564,565,566,567,
    572,630,631,632,633,
}
map.debuff.color = {red=144, green=64, blue=255}
map.debuff.focused = S{1,2,4,6,15,16,17,19,149,558,566,630,631,632,633}
map.debuff.pinned = S{}
map.switch_ability = T{
    [353] = S{354}, -- 八双
    [354] = S{353}, -- 星眼
    [358] = S{402}, -- 白のグリモア
    [359] = S{358}, -- 黒のグリモア
    [401] = S{359,402}, -- 白の補遺
    [402] = S{358,401}, -- 黒の補遺
    [417] = S{418}, -- ハートオブソラス
    [418] = S{417}, -- ハートオブミゼリ
    [420] = S{421}, -- 陽忍
    [421] = S{420}, -- 陰忍
    [628] = S{482}, -- ホバーショット
    [482] = S{628}, -- デコイショット
}
map.ability_charge = {
    ['BST'] = T{
        ['id'] = 102, -- ability recast id
        ['max'] = 3, -- max charge stock
        ['base_recast'] = 30 -- recast time
    },
    ['COR'] = T{
        ['id'] = 195, -- ability recast id
        ['max'] = 2, -- max charge stock
        ['base_recast'] = 60 -- recast time
    },
    ['SCH'] = T{
        ['id'] = 231, -- ability recast id
        ['max'] = 5, -- max charge stock
        ['base_recast'] = 240 -- recast time
    },
    ['id'] = S{102, 195, 231},
    ['get_charge'] = function (id, recast_time)
        local player = windower.ffxi.get_player()
        local used_charge = 0
        local charge_recast = 0
        if id == 102 then
            if player.main_job == 'BST' then
                local recast_per_charge = map.ability_charge['BST'].base_recast - 2*player.merits.sic_recast - 5
                if player.job_points['bst'] and player.job_points['bst'].jp_spent >= 100 then
                    recast_per_charge = recast_per_charge - 10
                end
                used_charge = math.ceil(recast_time/recast_per_charge)
                charge_recast = recast_time%recast_per_charge
            elseif player.sub_job == 'BST' then
                used_charge = math.ceil(recast_time/map.ability_charge['BST'].base_recast)
                charge_recast = recast_time%map.ability_charge['BST'].base_recast
            end
            return T{['id'] = 102, ['max'] = 3, ['used'] = used_charge, ['recast'] = charge_recast}
        elseif id == 195 then
            if player.main_job == 'COR' then
                local recast_per_charge = map.ability_charge['COR'].base_recast - 2*player.merits.quick_draw_recast
                if player.job_points['cor'] and player.job_points['cor'].jp_spent >= 550 then
                    recast_per_charge = recast_per_charge - 10
                end
                used_charge = math.ceil(recast_time/recast_per_charge)
                charge_recast = recast_time%recast_per_charge
            elseif player.sub_job == 'COR' then
                used_charge = math.ceil(recast_time/map.ability_charge['COR'].base_recast)
                charge_recast = recast_time%map.ability_charge['cor'].base_recast
            end
            
            return T{['id'] = 195, ['max'] = 2, ['used'] = used_charge, ['recast'] = charge_recast}
        elseif id == 231 then
            local max_charge = 0

            local function get_max_charge(level)
                if level < 30 then
                    return 1
                elseif level < 50 then
                    return 2
                elseif level < 70 then
                    return 3
                elseif level < 90 then
                    return 4
                else
                    return 5
                end
            end

            local function get_recast_per_charge(level, jp_spent)
                if level < 30 then
                    return map.ability_charge['SCH'].base_recast
                elseif level < 50 then
                    return 120
                elseif level < 70 then
                    return 80
                elseif level < 90 then
                    return 60
                elseif level == 99 and jp_spent < 550 then
                    return 48
                else
                    return 33
                end
            end

            if player.main_job == 'SCH' then
                max_charge = get_max_charge(player.main_job_level)
                recast_per_charge = get_recast_per_charge(player.main_job_level, player.job_points['sch'] and player.job_points['sch'].jp_spent or 0) 
            elseif player.sub_job == 'SCH' then
                max_charge = get_max_charge(player.sub_job_level)
                recast_per_charge = get_recast_per_charge(player.sub_job_level, 0)
            end
            used_charge = math.ceil(recast_time/recast_per_charge)
            charge_recast = recast_time%recast_per_charge
            return T{['id'] = 231, ['max'] = max_charge, ['used'] = used_charge, ['recast'] = charge_recast}
        end
    end
}

map.sp = {}
map.sp.id = S{0, 254, 130, 131}
map.sp.name = T{
    ['WAR'] = {[0] = 'マイティストライク', [254] = 'ブラーゼンラッシュ'},
    ['MNK'] = {[0] = '百烈拳', [254] = 'インナーストレングス'},
    ['WHM'] = {[0] = '女神の祝福', [254] = '女神の羽衣'},
    ['BLM'] = {[0] = '魔力の泉', [254] = 'サテルソーサリー'},
    ['RDM'] = {[0] = '連続魔', [254] = 'スタイミー'},
    ['THF'] = {[0] = '絶対回避', [254] = 'ラーセニー'},
    ['PLD'] = {[0] = 'インビンシブル', [254] = 'インターヴィーン'},
    ['DRK'] = {[0] = 'ブラッドウェポン', [254] = 'ソールエンスレーヴ'},
    ['BST'] = {[0] = '使い魔', [254] = 'アンリーシュ'},
    ['BRD'] = {[0] = 'ソウルボイス', [254] = 'クラリオンコール'},
    ['RNG'] = {[0] = 'イーグルアイ', [254] = 'オーバーキル'},
    ['SAM'] = {[0] = '明鏡止水', [254] = '八重霞'},
    ['NIN'] = {[0] = '微塵がくれ', [254] = '身影'},
    ['DRG'] = {[0] = '竜剣', [254] = 'フライハイ'},
    ['SMN'] = {[0] = 'アストラルフロウ', [254] = 'アストラルパッセージ'},
    ['BLU'] = {[0] = 'アジュールロー', [254] = 'N.ウィズドム'},
    ['COR'] = {[0] = 'ワイルドカード', [254] = 'カットカード'},
    ['PUP'] = {[0] = 'オーバードライヴ', [254] = 'ヘディーアーテフィス'},
    ['DNC'] = {[0] = 'トランス', [254] = 'グランドパー'},
    ['SCH'] = {[0] = '連環計', [254] = 'カペルエミサリウス'},
    ['GEO'] = {[0] = 'ボルスター', [130] = 'ワイデンコンパス'},
    ['RUN'] = {[0] = 'E.スフォルツォ', [131] = 'オディリックサブタ'},
}
map.sch_arts = {}
map.sch_arts.id = T{
    ['Light Arts'] = 358,
    ['Dark Arts'] = 359,
    ['Addendum: White'] = 401,
    ['Addendum: Black'] = 402,
}

map.smn_favor = S{
    422,423,424,425,426,427,428,429,430,431,577,625
}
map.geo_buff = S{
    539,540,541,542,543,
    544,545,546,547,548,
    549,550,551,552,553,
    554,555,556,557,558,
    559,560,561,562,563,
    564,565,566,567,580
}

map.element_color = T{
    ['fire']      = {red=192, green=0, blue=0},
    ['ice']       = {red=0, green=192, blue=255},
    ['wind']      = {red=0, green=192, blue=0},
    ['earth']     = {red=255, green=192, blue=0},
    ['lightning'] = {red=192, green=0, blue=255},
    ['water']     = {red=96, green=96, blue=255},
    ['light']     = {red=192, green=192, blue=192},
    ['dark']      = {red=128, green=128, blue=128},
}
map.bar_element = {
    ['id'] = S{
        100, -- バファイ
        101, -- バブリザ
        102, -- バエアロ
        103, -- バストン
        104, -- バサンダ
        105, -- バウォタ
    },
    ['color'] = T{
        [100] = map.element_color.fire,
        [101] = map.element_color.ice,
        [102] = map.element_color.wind,
        [103] = map.element_color.earth,
        [104] = map.element_color.lightning,
        [105] = map.element_color.water,
    }
}

map.storm = {
    ['id'] = S{
        178, -- 熱波の陣
        179, -- 吹雪の陣
        180, -- 烈風の陣
        181, -- 砂塵の陣
        182, -- 疾雷の陣
        183, -- 豪雨の陣
        184, -- 極光の陣
        185, -- 妖霧の陣 
        589, -- 熱波の陣II
        590, -- 吹雪の陣II
        591, -- 烈風の陣II
        592, -- 砂塵の陣II
        593, -- 疾雷の陣II
        594, -- 豪雨の陣II
        595, -- 極光の陣II
        596, -- 妖霧の陣II
    },
    ['color'] = T{
        [178] = map.element_color.fire,
        [179] = map.element_color.ice,
        [180] = map.element_color.wind,
        [181] = map.element_color.earth,
        [182] = map.element_color.lightning,
        [183] = map.element_color.water,
        [184] = map.element_color.light,
        [185] = map.element_color.dark,
        [589] = map.element_color.fire,
        [590] = map.element_color.ice,
        [591] = map.element_color.wind,
        [592] = map.element_color.earth,
        [593] = map.element_color.lightning,
        [594] = map.element_color.water,
        [595] = map.element_color.light,
        [596] = map.element_color.dark,
    }
}

map.rune = {
    ['id'] =S{
        523, -- イグニス
        524, -- ゲールス
        525, -- フラブラ
        526, -- テッルス
        527, -- スルポール
        528, -- ウンダ
        529, -- ルックス
        530, -- テネブレイ
    },
    ['color'] = T{
        [523] = map.element_color.fire,
        [524] = map.element_color.ice,
        [525] = map.element_color.wind,
        [526] = map.element_color.earth,
        [527] = map.element_color.lightning,
        [528] = map.element_color.water,
        [529] = map.element_color.light,
        [530] = map.element_color.dark,
    }
}
map.maneuver = {
    ['id'] = S{
        300, -- ファイアマニューバ
        301, -- アイスマニューバ
        302, -- ウィンドマニューバ
        303, -- アースマニューバ
        304, -- サンダーマニューバ
        305, -- ウォーターマニューバ
        306, -- ライトマニューバ
        307, -- ダークマニューバ
    },
    ['color'] = T{
        [300] = map.element_color.fire,
        [301] = map.element_color.ice,
        [302] = map.element_color.wind,
        [303] = map.element_color.earth,
        [304] = map.element_color.lightning,
        [305] = map.element_color.water,
        [306] = map.element_color.light,
        [307] = map.element_color.dark,
    }
}
map.main = {
    ['WAR'] = {
        focused = L{
            68, -- ウォークライ
            460, -- ブラッドレイジ 
        },
        pinned = L{
            56, -- バーサク
            57, -- ディフェンダー
            58, -- アグレッサー
        },
    },
    ['MNK'] = {
        focused = L{
            46, -- 百烈拳
            45, -- ためる
            61, -- かまえる
            341, -- 無想無念
            406, -- 猫足立ち
            491, -- インナーストレングス
        },
        pinned = L{
            461, -- インピタス
            59, -- 集中
            60, -- 回避
        },
    },
    ['WHM'] = {
        focused = L{
            453, -- 女神の愛撫
            459, -- 女神の愛撫
            477, -- 女神の聖域
            492, -- 女神の羽衣
        },
        pinned = L{
            417, -- ハートオブソラス
            418, -- ハートオブミゼリ
        },
    },
    ['BLM'] = {
        focused = L{
            47, -- 魔力の泉
            437, -- マナウォール
            493, -- サテルソーサリー
            178, -- 熱波の陣
            179, -- 吹雪の陣
            180, -- 烈風の陣
            181, -- 砂塵の陣
            182, -- 疾雷の陣
            183, -- 豪雨の陣
            184, -- 極光の陣
            185, -- 妖霧の陣 
            589, -- 熱波の陣II
            590, -- 吹雪の陣II
            591, -- 烈風の陣II
            592, -- 砂塵の陣II
            593, -- 疾雷の陣II
            594, -- 豪雨の陣II
            595, -- 極光の陣II
            596, -- 妖霧の陣II
        },
        pinned = L{
            79, -- 精霊の印
        },
    },
    ['RDM'] = {
        focused = L{
            48, -- 連続魔
            230, -- クイックマジック
            494, -- スタイミー
        },
        pinned = L{
            419, -- コンポージャー
            454, -- サボトゥール
        },
    },
    ['THF'] = {
        focused = L{
            49, -- 絶対回避
            65, -- 不意打ち
            87, -- だまし討ち
        },
        pinned = L{
 
                },
    },
    ['PLD'] = {
        focused = L{
            274, -- エンライト
            50, -- インビンシブル
            74, -- ホーリーサークル
            114, -- かばう
            438, -- 神聖の印
            478, -- パリセード
        },
        pinned = L{
            621, -- マジェスティ
            403, -- リアクト
            116, -- ファランクス
            289, -- 敵対心アップ
            62, -- センチネル
            623, -- ランパート
        },
        aka = T{
            [289] = 'クルセード',
        }
    },
    ['DRK'] = {
        focused = L{
            173, -- ドレッドスパイク
            51, -- ブラッドウェポン
            63, -- 暗黒
            75, -- アルケインサークル
            345, -- ダークシール
            439, -- ネザーヴォイド
            479, -- レッドデリリアム
            480, -- レッドデリリアム
            497, -- ソールエンスレーヴ
            80, -- STRアップ
            81, -- DEXアップ
            82, -- VITアップ
            83, -- AGIアップ
            84, -- INTアップ
            85, -- MNDアップ
            86, -- CHRアップ
            90, -- 命中率アップ
        },
        pinned = L{
            64, -- ラストリゾート
            88, -- HPmaxアップ
            288, -- エンダーク
        },
        aka = T{
            [88] = 'ドレイン',
            [479] = 'レッドデリリアム',
            [480] = '▲レッドデリリアム'
        }
    },
    ['BST'] = {
        focused = L{},
        pinned = L{
            349, -- K.インスティンクト
            498 -- アンリーシュ
        },
    },
    ['BRD'] = {
        focused = L{
            52, -- ソウルボイス
            499, -- クラリオンコール
            },
        pinned = L{
            347, -- ナイチンゲール
            348, -- トルバドゥール
            231, -- マルカート
            409, -- ピアニッシモ
        },
    },
    ['RNG'] = {
        focused = L{
            77, -- カモフラージュ
            500, -- オーバーキル
        },
        pinned = L{
            371, -- ベロシティショット
            628, -- ホバーショット
            482, -- デコイショット
            433, -- ダブルショット
            72, -- 狙い撃ち
        },
    },
    ['SAM'] = {
        focused = L{
            54, -- 明鏡止水
            117, -- 護摩の守護円
            67, -- 心眼
            408, -- 石火之機
            440, -- 先義後利
            483, -- 葉隠
            501, -- 八重霞
        },
        pinned = L{
            353, -- 八双
            354, -- 星眼
        },
    },
    ['NIN'] = {
        focused = L{
            352, -- 散華
            441, -- 二重
            484, -- 一隻眼
            502, -- 身影
        },
        pinned = L{
            420, -- 陽忍
            421, -- 陰忍
        },
    },
    ['DRG'] = {
        focused = L{
            126, -- 竜剣
            118, -- エンシェントサークル
            503, -- フライハイ
        },
        pinned = L{},
    },
    ['SMN'] = {
        focused = L{
            583, -- アポジー
        },
        pinned = L{
            431, -- 神獣の加護
            55, -- アストラルフロウ
            504, -- アストラルパッセージ
        },
    },
    ['BLU'] = {
        focused = L{
            33, -- ヘイスト
            39, -- アクアベール
            604, -- マイティガード
            91, -- 攻撃力アップ
            93, -- 防御力アップ
            163, -- アジュールロー
            164, -- ブルーチェーン
            165, -- ブルーバースト
            355, -- コンバージェンス
            457, -- エフラックス
            505, -- N.ウィズドム
        },
        pinned = L{
            356, -- ディフュージョン
            485, -- ノートリアスナレッジ
        },
    },
    ['COR'] = {
        focused = L{
            357, -- スネークアイ
            601, -- クルケッドカード
            309, -- バスト
            308, -- ダブルアップチャンス
            310, -- ファイターズロール
            311, -- モンクスロール
            312, -- ヒーラーズロール
            313, -- ウィザーズロール
            314, -- ワーロックスロール
            315, -- ローグズロール
            316, -- ガランツロール
            317, -- カオスロール
            318, -- ビーストロール
            319, -- コーラルロール
            320, -- ハンターズロール
            321, -- サムライロール
            322, -- ニンジャロール
            323, -- ドラケンロール
            324, -- エボカーズロール
            325, -- メガスズロール
            326, -- コルセアズロール
            327, -- パペットロール
            328, -- ダンサーロール
            329, -- スカラーロール
            330, -- ボルターズロール
            331, -- キャスターズロール
            332, -- コアサーズロール
            333, -- ブリッツァロール
            334, -- タクティックロール
            335, -- アライズロール
            336, -- マイザーロール
            337, -- コンパニオンロール
            338, -- カウンターロール
            339, -- ナチュラリストロール
            600, -- ルーニストロール
        },
        pinned = L{
            467, -- トリプルショット
        },
    },
    ['PUP'] = {
        focused = L{
            299, -- オーバーロード
            300, -- ファイアマニューバ
            301, -- アイスマニューバ
            302, -- ウィンドマニューバ
            303, -- アースマニューバ
            304, -- サンダーマニューバ
            305, -- ウォーターマニューバ
            306, -- ライトマニューバ
            307, -- ダークマニューバ
        },
        pinned = L{
            166, -- オーバードライヴ
        },
    },
    ['DNC'] = {
        focused = L{
            442, -- プレスト
            443, -- C.フラリッシュ
            468, -- S.フラリッシュ
            472, -- T.フラリッシュ
            376, -- トランス
            507, -- グランドパー
            368, -- ドレインサンバ
            369, -- アスピルサンバ
            370, -- ヘイストサンバ
            381, -- フィニシングムーブ1
            382, -- フィニシングムーブ2
            383, -- フィニシングムーブ3
            384, -- フィニシングムーブ4
            385, -- フィニシングムーブ5
            588, -- フィニシングムーブ(5+)
            582, -- コントラダンス
        },
        pinned = L{
            410, -- 剣の舞い
            411, -- 扇の舞い
        },
    },
    ['SCH'] = {
        focused = L{
            377, -- 連環計
            187, -- 机上演習:蓄積中
            188, -- 机上演習:蓄積完了
            416, -- 大悟徹底
            360, -- 簡素清貧の章
            361, -- 勤倹小心の章
            362, -- 電光石火の章
            363, -- 疾風迅雷の章
            364, -- 意気昂然の章
            365, -- 気炎万丈の章
            366, -- 女神降臨の章
            367, -- 精霊光来の章
            412, -- 不惜身命の章
            413, -- 一心精進の章
            414, -- 天衣無縫の章
            415, -- 無憂無風の章
            469, -- 令狸執鼠の章
            470, -- 震天動地の章
            178, -- 熱波の陣
            179, -- 吹雪の陣
            180, -- 烈風の陣
            181, -- 砂塵の陣
            182, -- 疾雷の陣
            183, -- 豪雨の陣
            184, -- 極光の陣
            185, -- 妖霧の陣 
            589, -- 熱波の陣II
            590, -- 吹雪の陣II
            591, -- 烈風の陣II
            592, -- 砂塵の陣II
            593, -- 疾雷の陣II
            594, -- 豪雨の陣II
            595, -- 極光の陣II
            596, -- 妖霧の陣II
        },
        pinned = L{
            358, -- 白のグリモア
            401, -- 白の補遺
            359, -- 黒のグリモア
            402, -- 黒の補遺
        },
    },
    ['GEO'] = {
        focused = L{
            539,540,541,542,543,
            544,545,546,547,548,
            549,550,551,552,553,
            554,555,556,557,558,
            559,560,561,562,563,
            564,565,566,567,580,
            569, -- グローリーブレイズ
        },
        pinned = L{
            612, -- コルア展開
            513, -- ボルスター
            508, -- ワイデンコンパス
        },
    },
    ['RUN'] = {
        focused = L{
            37, -- ストンスキン
            100, -- バファイ
            101, -- バブリザ
            102, -- バエアロ
            103, -- バストン
            104, -- バサンダ
            105, -- バウォタ
            106, -- バスリプル
            107, -- バポイズン
            108, -- バパライズ
            109, -- バブライン
            110, -- バサイレス
            111, -- バブレイク
            112, -- バウィルス
            286, -- バアムネジア
            34, -- ブレイズスパイク
            35, -- アイススパイク
            38, -- ショックスパイク
            432, -- マルチアタック
            523, -- イグニス
            524, -- ゲールス
            525, -- フラブラ
            526, -- テッルス
            527, -- スルポール
            528, -- ウンダ
            529, -- ルックス
            530, -- テネブレイ
            522, -- E.スフォルツォ
            534, -- エンボルド
            533, -- フルーグ
            537, -- リエモン
            538, -- ワンフォアオール
            570, -- バットゥタ
        },
        pinned = L{
            568, -- 特殊攻撃回避率アップ
            116, -- ファランクス
            39, -- アクアベール
            289, -- 敵対心アップ
            531, -- ヴァレション
            535, -- ヴァリエンス
            574, -- ファストキャスト
        },
        aka = T{
            [289] = 'クルセード',
            [568] = 'フォイル',
            [432] = 'ストライ',
        }
    },
}
map.sub = {
    ['WAR'] = {
        focused = L{
            68, -- ウォークライ
        },
        pinned = L{
            56, -- バーサク
            57, -- ディフェンダー
            58, -- アグレッサー
        },
    },
    ['MNK'] = {
        focused = L{
            59, -- 集中
            60, -- 回避
            61, -- かまえる
        },
        pinned = L{},
    },
    ['WHM'] = {
        focused = L{},
        pinned = L{},
    },
    ['BLM'] = {
        focused = L{},
        pinned = L{
            79, -- 精霊の印
        },
    },
    ['RDM'] = {
        focused = L{},
        pinned = L{},
    },
    ['THF'] = {
        focused = L{
            65, -- 不意打ち
            87, -- だまし討ち
        },
        pinned = L{},
    },
    ['PLD'] = {
        focused = L{
            74, -- ホーリーサークル
        },
        pinned = L{
            62, -- センチネル
        },
    },
    ['DRK'] = {
        focused = L{
            75, -- アルケインサークル
        },
        pinned = L{
            64, -- ラストリゾート
        },
    },
    ['BST'] = {
        focused = L{},
        pinned = L{},
    },
    ['BRD'] = {
        focused = L{},
        pinned = L{},
    },
    ['RNG'] = {
        focused = L{
            77, -- カモフラージュ
        },
        pinned = L{
            72, -- 狙い撃ち
        },
    },
    ['SAM'] = {
        focused = L{
            54, -- 明鏡止水
            67, -- 心眼
            354, -- 星眼
            408, -- 石火之機
        },
        pinned = L{
            353, -- 八双
        },
    },
    ['NIN'] = {
        focused = L{},
        pinned = L{},
    },
    ['DRG'] = {
        focused = L{},
        pinned = L{},
    },
    ['SMN'] = {
        focused = L{},
        pinned = L{},
    },
    ['BLU'] = {
        focused = L{
            93, -- 防御力アップ
        },
        pinned = L{},
    },
    ['COR'] = {
        focused = L{
            309, -- バスト
            308, -- ダブルアップチャンス
            310, -- ファイターズロール
            311, -- モンクスロール
            312, -- ヒーラーズロール
            313, -- ウィザーズロール
            314, -- ワーロックスロール
            315, -- ローグズロール
            316, -- ガランツロール
            317, -- カオスロール
            318, -- ビーストロール
            319, -- コーラルロール
            320, -- ハンターズロール
            321, -- サムライロール
            322, -- ニンジャロール
            323, -- ドラケンロール
            324, -- エボカーズロール
            325, -- メガスズロール
            326, -- コルセアズロール
            327, -- パペットロール
            328, -- ダンサーロール
            329, -- スカラーロール
            330, -- ボルターズロール
            331, -- キャスターズロール
            332, -- コアサーズロール
            333, -- ブリッツァロール
            334, -- タクティックロール
            335, -- アライズロール
            336, -- マイザーロール
            337, -- コンパニオンロール
            338, -- カウンターロール
            339, -- ナチュラリストロール
            600, -- ルーニストロール
        },
        pinned = L{},
    },
    ['PUP'] = {
        focused = L{},
        pinned = L{},
    },
    ['DNC'] = {
        focused = L{
            368, -- ドレインサンバ
            369, -- アスピルサンバ
            370, -- ヘイストサンバ
            381, -- フィニシングムーブ1
            382, -- フィニシングムーブ2
            383, -- フィニシングムーブ3
            384, -- フィニシングムーブ4
            385, -- フィニシングムーブ5
            588, -- フィニシングムーブ(5+)
        },
        pinned = L{},
    },
    ['SCH'] = {
        focused = L{
            187, -- 机上演習:蓄積中
            188, -- 机上演習:蓄積完了
            360, -- 簡素清貧の章
            361, -- 勤倹小心の章
            362, -- 電光石火の章
            363, -- 疾風迅雷の章
            364, -- 意気昂然の章
            365, -- 気炎万丈の章
            366, -- 女神降臨の章
            367, -- 精霊光来の章
        },
        pinned = L{
            358, -- 白のグリモア
            401, -- 白の補遺
            359, -- 黒のグリモア
            402, -- 黒の補遺
        },
    },
    ['GEO'] = {
        focused = L{
            539,540,541,542,543,
            544,545,546,547,548,
            549,550,551,552,553,
            554,555,556,557,558,
            559,560,561,562,563,
            564,565,566,567,580,
        },
        pinned = L{
            612, -- コルア展開
        },
    },
    ['RUN'] = {
        focused = L{
            523, -- イグニス
            524, -- ゲールス
            525, -- フラブラ
            526, -- テッルス
            527, -- スルポール
            528, -- ウンダ
            529, -- ルックス
            530, -- テネブレイ
            531, -- ヴァレション
            535, -- ヴァリエンス
            533, -- フルーグ
        },
        pinned = L{},
    },
}
return map