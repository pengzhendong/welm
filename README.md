## WeLM

WeLM depens on:

1. [WeTextProcessing](https://github.com/wenet-e2e/WeTextProcessing): Text Normalization
2. [jieba](https://github.com/fxsjy/jieba): Chinese Word Segmentation
3. [SentencePiece ](https://github.com/google/sentencepiece): English subword units Byte-Pair-Encoding (BPE)
4. [SRILM](http://www.speech.sri.com/projects/srilm): N-Gram Language Model Training
5. Some tools of [Kaldi](https://github.com/kaldi-asr/kaldi): TLG Graph Building

### Usage

1. Prepare the acoustic model's unit file `units.txt`.

``` bash
$ wget https://path/to/aishell2/20210618_u2pp_conformer_libtorch.tar.gz
$ tar -xf 20210618_u2pp_conformer_libtorch.tar.gz
```

2. Prepare transcript file `trans.txt`.

``` bash
$ head -n1 trans.txt
BAC009S0002W0122 而对楼市成交抑制作用最大的限购
```

3. Build the FST.


``` bash
$ bash run.sh --unit_file units.txt --text trans.txt
$ ls exp/lang
```
