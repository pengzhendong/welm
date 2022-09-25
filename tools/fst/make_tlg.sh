#!/bin/bash
#

if [ -f path.sh ]; then . path.sh; fi

lm_dir=$1
lang_dir=$2

arpa_lm=${lm_dir}/lm.arpa
[ ! -f $arpa_lm ] && echo No such file $arpa_lm && exit 1;

# Compile the language model to FST
cat $arpa_lm | \
  grep -v '<s> <s>' | \
  grep -v '</s> <s>' | \
  grep -v '</s> </s>' | \
  grep -v -i '<unk>' | \
  grep -v -i '<spoken_noise>' | \
  arpa2fst --read-symbol-table=$lang_dir/words.txt --keep-symbols=true - | \
      fstprint | \
      tools/fst/eps2disambig.pl | \
      tools/fst/s2eps.pl | \
      fstcompile --isymbols=$lang_dir/words.txt --osymbols=$lang_dir/words.txt | \
      fstrmepsilon | \
      fstarcsort --sort_type=ilabel > $lang_dir/G.fst
echo "Checking how stochastic G is (the first of these numbers should be small):"
fstisstochastic $lang_dir/G.fst

# Compose the token, lexicon and language-model FST into the final decoding graph
fsttablecompose $lang_dir/L.fst $lang_dir/G.fst | \
  fstdeterminizestar | \
  fstminimizeencoded | \
  fstarcsort --sort_type=ilabel > $lang_dir/LG.fst
fsttablecompose $lang_dir/T.fst $lang_dir/LG.fst > $lang_dir/TLG.fst
echo "Composing decoding graph TLG.fst succeeded"
