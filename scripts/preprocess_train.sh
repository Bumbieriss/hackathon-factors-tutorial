#!/bin/bash

# exit if something wrong happens
set -e


# source env variables
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../.env


# Tokenize
echo "Tokenizing..."
cat $DATA/$TRAIN_PREFIX.$SRC_LANG | $MOSES/scripts/tokenizer/tokenizer.perl -a -l $SRC_LANG > $DATA/$TRAIN_PREFIX.tok.$SRC_LANG
cat $DATA/$TRAIN_PREFIX.$TGT_LANG | $MOSES/scripts/tokenizer/tokenizer.perl -a -l $TGT_LANG > $DATA/$TRAIN_PREFIX.tok.$TGT_LANG
TOK_SRC=$DATA/$TRAIN_PREFIX.tok.$SRC_LANG
TOK_TGT=$DATA/$TRAIN_PREFIX.tok.$TGT_LANG
FACT_SRC=$DATA/$TRAIN_PREFIX.tok.$SRC_LANG
FACT_TGT=$DATA/$TRAIN_PREFIX.tok.$TGT_LANG

sed -i $FACT_TGT -e 's/#/\&htg;/g' -e 's/:/\&cln;/g' -e 's/_/\&usc;/g' -e 's/|/\&ppe;/g' -e 's/\\/\&esc;/g'

# Add factors denoting POS information
if [ "$USE_SOURCE_POS_FACTORS" = true ] ; then
    echo "Escaping special characters before POS-tagging"
    sed -i $DATA/$TRAIN_PREFIX.tok.$SRC_LANG -e 's/|/¦/g'
    echo "Adding POS factors to source"
    SpacyTagger=( "en" "de" "fr" "pl" "da" "el" "nb" "nl" "pt" "ro" "it" "es" )
    if [[ " ${SpacyTagger[@]} " =~ " ${SRC_LANG} " ]] ; then
        echo "Downloading models..."
        python -m spacy download ${SRC_LANG}_core_news_sm
        
        python $SCRIPTS/factorise-tok-data-with-spacy.py $SRC_LANG $DATA/$TRAIN_PREFIX.tok.$SRC_LANG > $DATA/$TRAIN_PREFIX.tok.pfact.$SRC_LANG  $POS_FACTOR_PREFIX
    else
        python $SCRIPTS/download_stanza_resources.py $SRC_LANG
        python $SCRIPTS/factorise-tok-data-with-stanza.py $SRC_LANG $DATA/$TRAIN_PREFIX.tok.$SRC_LANG > $DATA/$TRAIN_PREFIX.tok.pfact.$SRC_LANG  $POS_FACTOR_PREFIX
    fi
    FACT_SRC=$DATA/$TRAIN_PREFIX.tok.pfact.$SRC_LANG
fi
if [ "$USE_TARGET_POS_FACTORS" = true ] ; then
    echo "Escaping special characters before POS-tagging"
    sed -i $DATA/$TRAIN_PREFIX.tok.$TGT_LANG -e 's/|/¦/g'
    echo "Adding POS factors to target"
    SpacyTagger=( "en" "de" "fr" "pl" "da" "el" "nb" "nl" "pt" "ro" "it" "es" )
<<<<<<< HEAD
    if [[ " ${SpacyTagger[@]} " =~ " ${SRC_LANG} " ]] ; then
        echo "Downloading models..."
        python -m spacy download ${TGT_LANG}_core_news_sm
        
=======
    if [[ " ${SpacyTagger[@]} " =~ " ${TGT_LANG} " ]] ; then
>>>>>>> ccd33e2e1d57f6e8d50e9cdbf8e106a63807ce2c
        python $SCRIPTS/factorise-tok-data-with-spacy.py $TGT_LANG $DATA/$TRAIN_PREFIX.tok.$TGT_LANG > $DATA/$TRAIN_PREFIX.tok.pfact.$TGT_LANG  $POS_FACTOR_PREFIX
    else
        python $SCRIPTS/download_stanza_resources.py $TGT_LANG
        python $SCRIPTS/factorise-tok-data-with-stanza.py $TGT_LANG $DATA/$TRAIN_PREFIX.tok.$TGT_LANG > $DATA/$TRAIN_PREFIX.tok.pfact.$TGT_LANG  $POS_FACTOR_PREFIX
    fi
    FACT_TGT=$DATA/$TRAIN_PREFIX.tok.pfact.$TGT_LANG
fi

# Escape special characters so that we can use factors in marian
echo "Escaping special characters..."
sed -i $FACT_SRC -e 's/#/\&htg;/g' -e 's/:/\&cln;/g' -e 's/_/\&usc;/g' -e 's/\\/\&esc;/g'
sed -i $FACT_TGT -e 's/#/\&htg;/g' -e 's/:/\&cln;/g' -e 's/_/\&usc;/g' -e 's/\\/\&esc;/g'


# Add factors denoting capitalization information
if [ "$USE_SOURCE_CAP_FACTORS" = true ] ; then
    echo "Adding capitalization factors to source"
    python $SCRIPTS/add_capitalization_factors.py --input_file $FACT_SRC --output_file $DATA/$TRAIN_PREFIX.tok.cfact.$SRC_LANG --factor_prefix $CAP_FACTOR_PREFIX
    # We remove the factors from the annotated data to apply BPE, and later we extend the factors to the subworded text
    cat $DATA/$TRAIN_PREFIX.tok.cfact.$SRC_LANG | sed -r "s/\|[^ ]+//g" > $DATA/$TRAIN_PREFIX.tok.nofact.$SRC_LANG
    TOK_SRC=$DATA/$TRAIN_PREFIX.tok.nofact.$SRC_LANG
    FACT_SRC=$DATA/$TRAIN_PREFIX.tok.cfact.$SRC_LANG
fi
if [ "$USE_TARGET_CAP_FACTORS" = true ] ; then
    echo "Adding capitalization factors to target"
    python $SCRIPTS/add_capitalization_factors.py --input_file $FACT_TGT --output_file $DATA/$TRAIN_PREFIX.tok.cfact.$TGT_LANG --factor_prefix $CAP_FACTOR_PREFIX
    cat $DATA/$TRAIN_PREFIX.tok.cfact.$TGT_LANG | sed -r "s/\|[^ ]+//g" > $DATA/$TRAIN_PREFIX.tok.nofact.$TGT_LANG
    TOK_TGT=$DATA/$TRAIN_PREFIX.tok.nofact.$TGT_LANG
    FACT_TGT=$DATA/$TRAIN_PREFIX.tok.cfact.$TGT_LANG
fi

#Swap tokens to lemmas if required.
if [ "$USE_SOURCE_LEMMAS" = true ] ; then
    echo "Swapping surface forms with lemmas in source"
    python $SCRIPTS/swap_lemmas.py --input_file $FACT_SRC --output_file $DATA/$TRAIN_PREFIX.tok.cfact.lemma.$SRC_LANG $USE_SOURCE_CAP_FACTORS
    cat $DATA/$TRAIN_PREFIX.tok.cfact.$SRC_LANG | sed -r "s/\|[^ ]+//g" > $DATA/$TRAIN_PREFIX.tok.nofact.lemma.$SRC_LANG
    TOK_SRC=$DATA/$TRAIN_PREFIX.tok.nofact.lemma.$SRC_LANG
    FACT_SRC=$DATA/$TRAIN_PREFIX.tok.cfact.lemma.$SRC_LANG
elif [ "$USE_SOURCE_POS_FACTORS" = true ] ; then
    echo "Removing lemmas in source"
    python $SCRIPTS/remove_lemmas.py --input_file $FACT_SRC --output_file $DATA/$TRAIN_PREFIX.tok.cfact.nolemma.$SRC_LANG
    FACT_SRC=$DATA/$TRAIN_PREFIX.tok.cfact.nolemma.$SRC_LANG
fi
if [ "$USE_TARGET_LEMMAS" = true ] ; then
    echo "Swapping surface forms with lemmas in target"
    python $SCRIPTS/swap_lemmas.py --input_file $FACT_TGT --output_file $DATA/$TRAIN_PREFIX.tok.cfact.lemma.$TGT_LANG $USE_TARGET_CAP_FACTORS
    cat $DATA/$TRAIN_PREFIX.tok.cfact.lemma.$TGT_LANG | sed -r "s/\|[^ ]+//g" > $DATA/$TRAIN_PREFIX.tok.nofact.lemma.$TGT_LANG
    TOK_TGT=$DATA/$TRAIN_PREFIX.tok.nofact.lemma.$TGT_LANG
    FACT_TGT=$DATA/$TRAIN_PREFIX.tok.cfact.lemma.$TGT_LANG
elif [ "$USE_SOURCE_POS_FACTORS" = true ] ; then
    echo "Removing lemmas in target"
    python $SCRIPTS/remove_lemmas.py --input_file $FACT_TGT --output_file $DATA/$TRAIN_PREFIX.tok.cfact.nolemma.$TGT_LANG
    FACT_TGT=$DATA/$TRAIN_PREFIX.tok.cfact.nolemma.$TGT_LANG
fi

# Train BPE
echo "Training BPE..."
subword-nmt learn-joint-bpe-and-vocab --input $TOK_SRC $TOK_TGT -s 32000 -o $DATA/$SRC_LANG$TGT_LANG.bpe --write-vocabulary $DATA/vocab.bpe.$SRC_LANG $DATA/vocab.bpe.$TGT_LANG


# Apply BPE
echo "Applying BPE..."
subword-nmt apply-bpe -c $DATA/$SRC_LANG$TGT_LANG.bpe --vocabulary $DATA/vocab.bpe.$SRC_LANG --vocabulary-threshold 50 < $TOK_SRC > $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$SRC_LANG
subword-nmt apply-bpe -c $DATA/$SRC_LANG$TGT_LANG.bpe --vocabulary $DATA/vocab.bpe.$TGT_LANG --vocabulary-threshold 50 < $TOK_TGT > $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$TGT_LANG


# Extend BPE splits to factored corpus
echo "Applying BPE to factored corpus..."
python $SCRIPTS/transfer_factors_to_bpe.py --factored_corpus $FACT_SRC --bpe_corpus $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$SRC_LANG --output_file $DATA/$TRAIN_PREFIX.tok.cfact.bpe.$SRC_LANG
python $SCRIPTS/transfer_factors_to_bpe.py --factored_corpus $FACT_TGT --bpe_corpus $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$TGT_LANG --output_file $DATA/$TRAIN_PREFIX.tok.cfact.bpe.$TGT_LANG


# Create regular joint vocab
echo "Creating vocab..."
cat $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$SRC_LANG $DATA/$TRAIN_PREFIX.tok.nofact.bpe.$TGT_LANG | $MARIAN/marian-vocab > $DATA/vocab.$SRC_LANG$TGT_LANG.yml


# Create factored vocab
echo "Creating factored vocab..."
cat $DATA/vocab.$SRC_LANG$TGT_LANG.yml | sed 's/\"//g;s/:.*//g' > $DATA/vocab.$SRC_LANG$TGT_LANG.yml.tmp # makes the regular vocab only a token per line
$SCRIPTS/create_factored_vocab.sh -i $DATA/vocab.$SRC_LANG$TGT_LANG.yml.tmp -o $DATA/vocab.$SRC_LANG$TGT_LANG.fsv -p $FACTOR_PREFIX
rm $DATA/vocab.$SRC_LANG$TGT_LANG.yml.tmp

# Exit success
exit 0
