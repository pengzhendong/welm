#!/bin/bash
# Copyright 2015       Yajie Miao    (Carnegie Mellon University)

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
# WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
# MERCHANTABLITY OR NON-INFRINGEMENT.
# See the Apache 2 License for the specific language governing permissions and
# limitations under the License.

# This script compiles the lexicon and CTC tokens into FSTs. FST compiling slightly differs between the
# phoneme and character-based lexicons.
set -eo pipefail
. tools/parse_options.sh

if [ $# -ne 2 ]; then
  echo "usage: tools/fst/compile_lexicon_token_fst.sh <dict-src-dir> <lang-dir>"
  echo "e.g.: tools/fst/compile_lexicon_token_fst.sh exp/dict exp/lang"
  echo "<dict-src-dir> should contain the following files:"
  echo "lexicon.txt units.txt"
  echo "options: "
  exit 1;
fi

srcdir=$1
dir=$2
mkdir -p $dir

[ -f path.sh ] && . ./path.sh

cp $srcdir/units.txt $dir

# Add probabilities to lexicon entries. There is in fact no point of doing this here since all the entries have 1.0.
# But make_lexicon_fst.pl requires a probabilistic version, so we just leave it as it is.
awk '$2="1.0\t"$2' $srcdir/lexicon.txt > $srcdir/lexiconp.txt

# Add disambiguation symbols to the lexicon. This is necessary for determinizing the composition of L.fst and G.fst.
# Without these symbols, determinization will fail.
ndisambig=`tools/fst/add_lex_disambig.pl $srcdir/lexiconp.txt $srcdir/lexiconp_disambig.txt`
ndisambig=$[$ndisambig+1]

( for n in `seq 0 $ndisambig`; do echo '#'$n; done ) > $srcdir/disambig.list

# Get the full list of CTC tokens used in FST. These tokens include <eps>, the blank <blk>,
# the actual model unit, and the disambiguation symbols.
awk '{print $1}' $srcdir/units.txt > $srcdir/units.list
(echo '<eps>';) | cat - $srcdir/units.list $srcdir/disambig.list | awk '{print $1 " " (NR-1)}' > $dir/tokens.txt

# ctc_token_fst_corrected is too big and too slow for chinese character modeling, so here use ctc_token_fst_compact
python tools/fst/ctc_token_fst_compact.py $dir/tokens.txt | \
  fstcompile --isymbols=$dir/tokens.txt --osymbols=$dir/tokens.txt --keep_isymbols=false --keep_osymbols=false | \
  fstarcsort --sort_type=olabel > $dir/T.fst || exit 1;

# Encode the words with indices. Will be used in lexicon and language model FST compiling.
awk '{print $1}' $srcdir/lexiconp.txt | sort | uniq | awk '
  BEGIN {print "<eps> 0";}
  {printf("%s %d\n", $1, NR);}
  END {printf("#0 %d\n", NR+1); printf("<s> %d\n", NR+2); printf("</s> %d\n", NR+3);}' > $dir/words.txt || exit 1;

# Now compile the lexicon FST. Depending on the size of your lexicon, it may take some time.
token_disambig_symbol=`grep \#0 $dir/tokens.txt | awk '{print $2}'`
word_disambig_symbol=`grep \#0 $dir/words.txt | awk '{print $2}'`

tools/fst/make_lexicon_fst.pl --pron-probs $srcdir/lexiconp_disambig.txt 0 "sil" '#'$ndisambig | \
  fstcompile --isymbols=$dir/tokens.txt --osymbols=$dir/words.txt \
  --keep_isymbols=false --keep_osymbols=false |   \
  fstaddselfloops  "echo $token_disambig_symbol |" "echo $word_disambig_symbol |" | \
  fstarcsort --sort_type=olabel > $dir/L.fst || exit 1;

echo "Lexicon and token FSTs compiling succeeded"
