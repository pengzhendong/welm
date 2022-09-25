# Copyright (c) 2022 Zhendong Peng (pzd17@tsinghua.org.cn)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import jieba
from tn.chinese.normalizer import Normalizer


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--trans', help='input transcript')
    parser.add_argument('--normalize', type=bool, default=False,
                        help='whether to normalize the text')
    parser.add_argument('--contains_utt', type=bool, default=False,
                        help='whether the first column is utterance id')
    parser.add_argument('--vocab', help='input vocab file')
    parser.add_argument('--segmented_trans',
                        help='output segmented transcript')
    parser.add_argument('--clean_segmented_trans',
                        help='output segmented transcript without oov')
    args = parser.parse_args()

    if args.normalize:
        normalizer = Normalizer()

    vocabs = set()
    with open(args.vocab) as fin:
        for line in fin:
            vocabs.add(line.strip().split()[0])

    jieba.set_dictionary(args.vocab)
    with open(args.trans) as trans, \
            open(args.segmented_trans, 'w') as segmented_trans, \
            open(args.clean_segmented_trans, 'w') as clean_segmented_trans:
        for line in trans:
            line = line.strip()

            if args.contains_utt:
                arr = line.split()
                if len(arr) < 2:
                    continue
                text = arr[1]
            else:
                text = line

            if args.normalize:
                text = normalizer.normalize(text)

            if len(text) == 0:
                continue

            words = list(jieba.cut(text, HMM=False))
            segmented_trans.write(' '.join(words) + '\n')

            words = [word if word in vocabs else '<SPOKEN_NOISE>' for word in words]
            clean_segmented_trans.write(' '.join(words) + '\n')


if __name__ == '__main__':
    main()
