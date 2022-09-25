## WeLM

WeLM depens on:

1. [WeTextProcessing](https://github.com/wenet-e2e/WeTextProcessing): Text Normalization
2. [jieba](https://github.com/fxsjy/jieba): Chinese Word Segmentation
3. [SRILM](http://www.speech.sri.com/projects/srilm): N-Gram Language Model Training
4. Some tools of [Kaldi](https://github.com/kaldi-asr/kaldi): TLG Graph Building

### Usage

``` bash
$ bash run.sh --unit_file units.txt --text trans.txt
$ ls exp/lang
```
