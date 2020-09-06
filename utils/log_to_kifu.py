import shogi
from shogi import CSA
import os
import math
import re
import datetime
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('log')
parser.add_argument('--out_dir', default='.')
args = parser.parse_args()

KIFU_TO_SQUARE_NAMES = [
    '９一', '８一', '７一', '６一', '５一', '４一', '３一', '２一', '１一',
    '９二', '８二', '７二', '６二', '５二', '４二', '３二', '２二', '１二',
    '９三', '８三', '７三', '６三', '５三', '４三', '３三', '２三', '１三',
    '９四', '８四', '７四', '６四', '５四', '４四', '３四', '２四', '１四',
    '９五', '８五', '７五', '６五', '５五', '４五', '３五', '２五', '１五',
    '９六', '８六', '７六', '６六', '５六', '４六', '３六', '２六', '１六',
    '９七', '８七', '７七', '６七', '５七', '４七', '３七', '２七', '１七',
    '９八', '８八', '７八', '６八', '５八', '４八', '３八', '２八', '１八',
    '９九', '８九', '７九', '６九', '５九', '４九', '３九', '２九', '１九',
]

KIFU_FROM_SQUARE_NAMES = [
    '91', '81', '71', '61', '51', '41', '31', '21', '11',
    '92', '82', '72', '62', '52', '42', '32', '22', '12',
    '93', '83', '73', '63', '53', '43', '33', '23', '13',
    '94', '84', '74', '64', '54', '44', '34', '24', '14',
    '95', '85', '75', '65', '55', '45', '35', '25', '15',
    '96', '86', '76', '66', '56', '46', '36', '26', '16',
    '97', '87', '77', '67', '57', '47', '37', '27', '17',
    '98', '88', '78', '68', '58', '48', '38', '28', '18',
    '99', '89', '79', '69', '59', '49', '39', '29', '19',
]

def sec_to_time(sec):
    h, m_ = divmod(math.ceil(sec), 60*60)
    m, s = divmod(m_, 60)
    return h, m, s

def kifu_header(kifu, starttime, names):
    kifu.write('開始日時：' + starttime.strftime('%Y/%m/%d %H:%M:%S\n'))
    kifu.write('手合割：平手\n')
    kifu.write('先手：' + names[0] + '\n')
    kifu.write('後手：' + names[1] + '\n')
    kifu.write('手数----指手---------消費時間--\n')

def kifu_move(board, move_usi):
    move = shogi.Move.from_usi(move_usi)
    move_to = KIFU_TO_SQUARE_NAMES[move.to_square]
    if board.move_number >= 2:
        prev_move = board.move_stack[-1]
        if prev_move.to_square == move.to_square:
            move_to = "同　"
    if move.from_square is not None:
        move_piece = shogi.PIECE_JAPANESE_SYMBOLS[board.piece_type_at(move.from_square)]
        if move.promotion:
            return '{}{}成({})'.format(
                move_to,
                move_piece,
                KIFU_FROM_SQUARE_NAMES[move.from_square],
                )
        else:
            return '{}{}({})'.format(
                move_to,
                move_piece,
                KIFU_FROM_SQUARE_NAMES[move.from_square],
                )
    else:
        move_piece = shogi.PIECE_JAPANESE_SYMBOLS[move.drop_piece_type]
        return '{}{}打'.format(
            move_to,
            move_piece
            )

def kifu_pv(board, items, i):
    if board.turn == shogi.BLACK:
        move_str = ' ▲'
    else:
        move_str = ' △'
    move = shogi.Move.from_usi(items[i])
    if move.promotion and board.piece_type_at(move.from_square) > shogi.KING:
        # 強制的に成った駒を移動する場合、PVを打ち切り
        return ''
    move_str += kifu_move(board, items[i])

    if i < len(items) - 1:
        board.push_usi(items[i])
        next_move = kifu_pv(board, items, i + 1)
        board.pop()
        return move_str + next_move
    else:
        return move_str

def kifu_line(kifu, board, move_usi, sec, sec_sum, info):

    m, s = divmod(math.ceil(sec), 60)
    h_sum, m_sum, s_sum = sec_to_time(sec_sum)

    if move_usi == 'resign':
        move_str = '投了        '
    elif move_usi == 'win':
        move_str = '入玉宣言    '
    elif move_usi == 'draw':
        move_str = '持将棋      '
    else:
        board.push_usi(move_usi)
        if board.is_fourfold_repetition():
            board.pop()
            move_str = '千日手      '
        else:
            board.pop()
            if move_usi[1:2] == '*':
                padding = '    '
            elif move_usi[-1] == '+':
                padding = ''
            else:
                padding = '  '
            move_str = kifu_move(board, move_usi) + padding

    kifu.write('{:>4} {}      ({:>2}:{:02}/{:02}:{:02}:{:02})\n'.format(
        board.move_number,
        move_str,
        m, s,
        h_sum, m_sum, s_sum))

    if info is not None:
        items = info.split(' ')
        comment = '**対局'
        i = 1
        while i < len(items):
            if items[i] == 'time':
                i += 1
                m, s = divmod(int(items[i]) / 1000, 60)
                s_str = '{:.1f}'.format(s)
                if s_str[1:2] == '.':
                    s_str = '0' + s_str
                comment += ' 時間 {:>02}:{}'.format(int(m), s_str)
            elif items[i] == 'depth':
                i += 1
                comment += ' 深さ {}'.format(items[i])
            elif items[i] == 'nodes':
                i += 1
                comment += ' ノード数 {}'.format(items[i])
            elif items[i] == 'nps':
                i += 1
                comment += ' NPS {}'.format(items[i])
            elif items[i] == 'hashfull':
                i += 1
                comment += ' ハッシュ {}%'.format(int(items[i])/10)
            elif items[i] == 'score':
                i += 1
                if items[i] == 'cp':
                    i += 1
                    comment += ' 評価値 {}'.format(items[i] if board.turn == shogi.BLACK else -int(items[i]))
                elif items[i] == 'mate':
                    i += 1
                    if items[i][0:1] == '+':
                        comment += ' +詰' if board.turn == shogi.BLACK else ' -詰'
                    else:
                        comment += ' -詰' if board.turn == shogi.BLACK else ' +詰'
                    comment += str(items[i][1:])
            elif items[i] == 'pv':
                i += 1
                comment += kifu_pv(board, items, i)
            else:
                i += 1
        kifu.write(comment + '\n')


ptn_datetime = re.compile(r'^([\d\-T:]+)\.')
ptn_name1 = re.compile(r'^ +Name\+:(.*)$')
ptn_name2 = re.compile(r'^ +Name\-:(.*)$')
ptn_newgame = re.compile(r'^ +usinewgame$')
ptn_info = re.compile(r'^ +(info .*score .*)$')
ptn_move = re.compile(r'^ +([+-]\d{4}..),T(\d+)$')
ptn_resign = re.compile(r'^ +%TORYO,T(\d+)$')

with open(args.log) as f:
    for line in f.readlines():
        # 時刻
        m = ptn_datetime.search(line)
        if m:
            starttime = datetime.datetime.strptime(m.groups()[0], '%Y-%m-%dT%H:%M:%S')
            continue
        # JST
        starttime += datetime.timedelta(hours=9)

        # Name
        m = ptn_name1.search(line)
        if m:
            name1 = m.groups()[0]
            continue
        m = ptn_name2.search(line)
        if m:
            name2 = m.groups()[0]
            continue

        # 開始
        if ptn_newgame.search(line):
            # kif open
            filename = starttime.strftime('%Y%m%d_%H%M%S') + '_' + name1 + '_vs_' + name2 + '.kif'
            kifu = open(os.path.join(args.out_dir, filename), 'w')

            kifu_header(kifu, starttime, (name1, name2))
            board = shogi.Board()
            sec_sum = 0
            info = None
            continue

        # info
        m = ptn_info.search(line)
        if m:
            info = m.groups()[0]
            continue

        # move
        m = ptn_move.search(line)
        if m:
            csa_move = m.groups()[0]
            _, move_usi = CSA.Parser.parse_move_str(csa_move, board)
            sec = int(m.groups()[1])
            sec_sum += sec
            kifu_line(kifu, board, move_usi, sec, sec_sum, info)
            board.push_usi(move_usi)
            info = None
            continue

        # 投了
        m = ptn_resign.search(line)
        if m:
            sec = int(m.groups()[0])
            sec_sum += sec
            kifu_line(kifu, board, 'resign', sec, sec_sum, info)
            kifu.close()
            continue
