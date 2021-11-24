import os
import argparse


def main():

    args = parse_user_args()

    input_file = os.path.realpath(args.input_file)
    output_file = os.path.realpath(args.output_file)

    with open(input_file, 'r', encoding='utf-8') as f_in, \
         open(output_file, 'w', encoding='utf-8') as f_out:

        for sentence in f_in:
            factored_sentence = remove_lemmas(sentence.strip())
            f_out.write(factored_sentence + "\n")

    # TODO: add logging


def remove_lemmas(sentence):
    '''
    Removes lemmas from a POS-tagged factored data file. Lemmas are expected to be in the second position.
    '''

    tokens_in = sentence.split()
    tokens_out = []
    for token in tokens_in:
        token_factors = token.split('|')
        del(token_factors[1])
        tokens_out.append("|".join(token_factors))
    return " ".join(tokens_out)

def parse_user_args():
    parser = argparse.ArgumentParser(description="Removes lemmas from a POS-tagged factored data file. Lemmas are expected to be in the second position.")
    parser.add_argument('-i', '--input_file', help="source file path", required=True)
    parser.add_argument('-o', '--output_file', help="output file path", required=True)
    return parser.parse_args()


if __name__ == "__main__":
    main()
