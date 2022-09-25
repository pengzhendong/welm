## Kaldi

[Kaldi](https://github.com/kaldi-asr/kaldi) depens on [OpenFST](https://www.openfst.org/twiki/bin/view/FST/WebHome) <= [1.7.2](https://github.com/kaldi-asr/kaldi/pull/4096). You could build OpenFST from source, or install it manually.

### Build OpenFST

``` bash
$ cmake -B build -DCMAKE_BUILD_TYPE=Release
$ cmake --build build
```

### Build with Pre-install OpenFST

``` bash
$ fst_install_dir=$(dirname $(dirname $(which fstinfo)))
$ cmake -B build -DCMAKE_BUILD_TYPE=Release -DFST_INSTALL_DIR:PATH=$fst_install_dir
$ cmake --build build
```
