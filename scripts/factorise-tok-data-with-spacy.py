# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals, print_function
import sys
import spacy
import re
from spacy.tokenizer import Tokenizer

lang = sys.argv[1]
fin = sys.argv[2]
factor_prefix = sys.argv[3]
model_dict = {"en": "en_core_web_sm",
              "da": "da_core_news_sm",
              "de": "de_core_news_sm",
              "el": "el_core_news_sm",
              "fr": "fr_core_news_sm",
              "nb": "nb_core_news_sm",
              "nl": "nl_core_news_sm",
              "pl": "pl_core_news_sm",
              "pt": "pt_core_news_sm",
              "ro": "ro_core_news_sm",
              "it": "it_core_news_sm",
              "es": "es_core_news_sm"}

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
    "X" : 16}

if lang in model_dict:
    nlp = spacy.load(model_dict[lang], disable=["parser", "ner"])
    nlp.tokenizer = Tokenizer(nlp.vocab, token_match=re.compile(r' ').match)

    with open(fin, "r", encoding="utf-8") as finI:
        for input_line in finI:
            doc = nlp(input_line.strip())
            formatted_tokens = []
            for token in doc:
                formatted_tokens.append(f'{token.text}|{token.lemma_}|{factor_prefix}{tagset[token.pos_]}')
            print(" ".join(formatted_tokens))
