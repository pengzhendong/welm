#!/bin/bash

stage=0
stop_stage=4

use_bpe=false

unit_file=
bpe_model=

text=
normalize=true
contains_utt=true
dir=exp

. tools/parse_options.sh || exit 1;

mkdir -p $dir

if [ $contains_utt == true ]; then
  cut -f2- -d " " $text > $dir/text
  text=$dir/text
fi

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
. path.sh || exit 1;

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
  if [ $use_bpe == true ] && [ ! $bpe_model ]; then
    echo "WARING: It's not recommended to train the bpe model here."
    echo "Please use the pretrained bpe model which generate the unit file."
    mkdir $dir/bpe
    nbpe=5000
    bpemode=unigram
    model_prefix=$dir/bpe/$bpemode$nbpe
    
    python tools/spm_train.py \
      --input=$text \
      --vocab_size=$nbpe \
      --model_type=$bpemode \
      --model_prefix=$model_prefix \
      --input_sentence_size=100000000
    bpe_model=$model_prefix.model
  fi

  mkdir -p $dir/dict
  cat data/*_lexicon.txt > $dir/lexicon.txt
  python tools/prepare_dict.py \
    $unit_file \
    $dir/lexicon.txt \
    $dir/dict/lexicon.txt \
    $bpe_model
  awk '{print $1,99}' $dir/dict/lexicon.txt > $dir/word_seg_vocab.txt
fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
  echo 'Segmenting words for transcript ...'
  python tools/word_segmentation.py \
    --trans $text \
    --normalize $normalize \
    --vocab $dir/word_seg_vocab.txt \
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
