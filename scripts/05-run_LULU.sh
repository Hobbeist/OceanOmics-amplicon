#!/bin/bash

voyageID=
assay=
#..........................................................................................
usage()
{
          printf "Usage: $0 -v <voyageID>\t<string>\n\t\t\t -a <assay; use flag multiple times for multiple assays>\t<string>\n\n";
          exit 1;
}
while getopts v:a: flag
do

        case "${flag}" in
            v) voyageID=${OPTARG};;
            a) assay+=("$OPTARG");;
            *) usage;;
        esac
done
if [ "${voyageID}" == ""  ]; then usage; fi
#if [ "${assay}" == ""  ]; then usage; fi


for a in ${assay[@]}
  do
        eval "$(conda shell.bash hook)"
        conda activate pytaxonkit
        echo  "Running LULU on ${voyage} ${assay}"
        
        bash scripts/LULU/01-lulu_create_match_list.sh ${voyage} ${assay}
        
        Rscript scripts/LULU/02-LULU.R -v ${voyage} -a ${assay}

        # Activate amplicon conda environent for seqkit
        eval "$(conda shell.bash hook)"
        conda activate amplicon

 	    # Next we need to curate the fasta files from DADA2 to only include the ASVs output by LULU
        echo curating ${voyage} ${assay} fasta file

        cat 04-LULU/LULU_curated_counts_${voyage}_${assay}.csv | \
        cut -d "," -f1 | \
        sed 1,1d | \
        seqkit grep -f - 03-dada2/${voyage}_${assay}.fa -o 04-LULU/LULU_curated_fasta_${voyage}_${assay}.fa
done

