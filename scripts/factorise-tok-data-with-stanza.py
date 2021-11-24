# -*- coding: utf-8 -*-
import sys
import stanza

lang = sys.argv[1]
source = sys.argv[2]
factor_prefix = sys.argv[3]

BATCH_SIZE = 5000
config = {
    'use_gpu': False,
    'processors': 'tokenize,pos,lemma',
    'tokenize_pretokenized': True,
    'lang': lang,
    'pos_batch_size': BATCH_SIZE,
    'lemma_batch_size': BATCH_SIZE
}

tagset = {
    "ADJ" : 0,
    "ADP" : 1,
    "ADV" : 2,
    "AUX" : 3,
    "CCONJ" : 4,
    "DET" : 5,
    "INTJ" : 6,
    "NOUN" : 7,
    "NUM" : 8,
    "PART" : 9,
    "PRON" : 10,
    "PROPN" : 11,
    "PUNCT" : 12,
    "SCONJ" : 13,
    "SYM" : 14,
    "VERB" : 15,
    "X" : 16
}

def batch(iterable, n):
    l = len(iterable)
    for ndx in range(0, l, n):
        yield iterable[ndx:min(ndx + n, l)]

with open(source, 'r') as f:
    source = f.read()
    source = source.split('\n')

nlp = stanza.Pipeline(**config)
for index, lines in enumerate(batch(source, BATCH_SIZE)):
    lines = "\n".join(lines)
    doc = nlp(lines)
    for sentence in doc.sentences:
        out = []
        for tok in sentence.words:
           out.append(f'{tok.text}|{tok.lemma}|{factor_prefix}{tagset[tok.upos]}')
        print(f'{" ".join(out)}')
