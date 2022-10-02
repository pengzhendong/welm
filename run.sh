#!/bin/bash

stage=0
stop_stage=4

unit_file=
text=
normalize=true
contains_utt=true
dir=exp

. tools/parse_options.sh || exit 1;

mkdir -p $dir

if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
  pip install -r requirements.txt
  if [ ! -d srilm/bin ]; then
    git submodule update --init
    make -C srilm SRILM=$(realpath srilm)
  fi
  if [ ! -d kaldi/build ]; then
    cmake -B kaldi/build -S kaldi -DCMAKE_BUILD_TYPE=Release
    cmake --build kaldi/build
  fi
fi

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
  mkdir -p $dir/dict
  python tools/prepare_dict.py $unit_file data/lexicon.txt $dir/dict/lexicon.txt
  awk '{print $1,99}' $dir/dict/lexicon.txt > $dir/word_seg_vocab.txt
fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
  echo 'Segmenting words for transcript ...'
  python tools/word_segmentation.py \
    --trans $text \
    --normalize $normalize \
    --contains_utt $contains_utt \
    --vocab $dir/word_seg_vocab.txt \
    --segmented_trans $dir/text \
    --clean_segmented_trans $dir/text.no_oov
fi

if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
  mkdir -p $dir/lm
  # Get unigram counts from acoustic training transcripts, and add one-count for each word in the lexicon.
  awk '{for(n=1;n<=NF;n++) print $n;}' $dir/text.no_oov | \
    cat - <(grep -w -v '!SIL' $dir/dict/lexicon.txt | awk '{print $1}') | \
    sort | uniq -c | sort -nr > $dir/lm/unigram.counts

  awk '{print $2}' $dir/lm/unigram.counts > $dir/lm/wordlist
  echo -e '<s>\n</s>' >> $dir/lm/wordlist

  heldout_sent=10000  # Comparable with kaldi_lm results.
  head -$heldout_sent $dir/text.no_oov > $dir/lm/heldout
  tail +$[$heldout_sent+1] $dir/text.no_oov > $dir/lm/train

  ngram-count -limit-vocab -unk -map-unk '<UNK>' -kndiscount -interpolate \
    -order 3 \
    -text $dir/lm/train \
    -vocab $dir/lm/wordlist \
    -lm $dir/lm/lm.arpa
  ngram -lm $dir/lm/lm.arpa -ppl $dir/lm/heldout
fi

if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
  cp $unit_file $dir/dict
  bash tools/fst/compile_lexicon_token_fst.sh $dir/dict $dir/lang
  bash tools/fst/make_tlg.sh $dir/lm $dir/lang
fi
