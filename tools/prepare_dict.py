#!/usr/bin/env python3
# encoding: utf-8

import sys

# sys.argv[1]: e2e model unit file(lang_char.txt)
# sys.argv[2]: raw lexicon file
# sys.argv[3]: output lexicon file
# sys.argv[4]: bpemodel

unit_table = set()
with open(sys.argv[1], 'r', encoding='utf8') as fin:
    for line in fin:
        unit = line.split()[0]
        unit_table.add(unit)


def contains_oov(units):
    for unit in units:
        if unit not in unit_table:
            return True
    return False


bpemode = len(sys.argv) > 4
if bpemode:
    import sentencepiece as spm
    sp = spm.SentencePieceProcessor()
    sp.Load(sys.argv[4])

lexicon_table = set()
with open(sys.argv[2], 'r', encoding='utf8') as fin, \
        open(sys.argv[3], 'w', encoding='utf8') as fout:
    for line in fin:
        word = line.strip()
        if word == 'SIL' and not bpemode:  # `sil` might be a valid piece in bpemodel
            continue
        # each word only has one pronunciation for e2e system
        if word == '<SPOKEN_NOISE>' or word in lexicon_table:
            continue

        if bpemode:
            if word.encode('utf8').isalpha():
                pieces = sp.EncodeAsPieces(word)
            else:
                pieces = word
        else:
            # Optional, append ▁ in front of english word
            # we assume the model unit of our e2e system is char now.
            if word.encode('utf8').isalpha() and '▁' in unit_table:
                word = '▁' + word
            pieces = word  # word is a char list

        if contains_oov(pieces):
            print('Word {} contains oov unit, ignoring.'.format(word))
            continue
        fout.write('{} {}\n'.format(word, ' '.join(pieces)))
        lexicon_table.add(word)
