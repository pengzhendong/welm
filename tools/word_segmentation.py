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
    parser.add_argument('--normalize',
                        type=bool,
                        default=False,
                        help='whether to normalize the text')
    parser.add_argument('--vocab', help='input vocab file')
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
            open(args.clean_segmented_trans, 'w') as clean_segmented_trans:
        for line in trans:
            text = line.strip().upper()
            if args.normalize:
                text = normalizer.normalize(text)
            if len(text) == 0:
                continue

            words = list(jieba.cut(text, HMM=False))
            clean_words = []
            for word in words:
                if word == ' ':
                    continue
                if word in vocabs:
                    clean_words.append(word)
                else:
                    clean_words.append('<SPOKEN_NOISE>')
            clean_segmented_trans.write(' '.join(clean_words) + '\n')


if __name__ == '__main__':
    main()
