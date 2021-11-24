import os
import argparse


def main():

    args = parse_user_args()

    input_file = os.path.realpath(args.input_file)
    output_file = os.path.realpath(args.output_file)
    lowercase_lemma = args.lowercase_lemma == "true"

    with open(input_file, 'r', encoding='utf-8') as f_in, \
         open(output_file, 'w', encoding='utf-8') as f_out:

        for sentence in f_in:
            factored_sentence = swap_lemmas(sentence.strip(), lowercase_lemma)
            f_out.write(factored_sentence + "\n")

    # TODO: add logging


def swap_lemmas(sentence, lowercase_lemma = False):
    '''
    Remove token surface forms from a POS-tagged factored data file leaving just lemmas. Lemmas are expected to be in the second position.
    '''

    tokens_in = sentence.split()
    tokens_out = []
    for token in tokens_in:
        token_factors = token.split('|')
        token_factors = token_factors[1:]
        if lowercase_lemma:
            token_factors[0] = token_factors[0].lower()
        tokens_out.append("|".join(token_factors))
    return " ".join(tokens_out)

def parse_user_args():
    parser = argparse.ArgumentParser(description="Remove token surface forms from a POS-tagged factored data file leaving just lemmas. Lemmas are expected to be in the second position.")
    parser.add_argument('-i', '--input_file', help="source file path", required=True)
    parser.add_argument('-o', '--output_file', help="output file path", required=True)
    parser.add_argument('-l', '--lowercase_lemma', help="Whether (true) or not (false) to lowercase lemma", required=True)
    return parser.parse_args()


if __name__ == "__main__":
    main()
