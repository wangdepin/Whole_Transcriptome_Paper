#!/bin/bash
#SBATCH --export=ALL # export all environment variables to the batch job
#SBATCH -D . # set working directory to .
#SBATCH -p mrcq # submit to the parallel queue
#SBATCH --time=15:00:00 # maximum walltime for the job
#SBATCH -A Research_Project-MRC148213 # research project to submit under
#SBATCH --nodes=1 # specify number of nodes
#SBATCH --ntasks-per-node=16 # specify number of processors per node
#SBATCH --mail-type=END # send email at job completion
#SBATCH --mail-user=sl693@exeter.ac.uk # email address
#SBATCH --output=All_Tg4510_Final.o
#SBATCH --error=All_Tg4510_Final.e

# 04/03/2020: Finalised alternative pipeline on whole transcriptome 12 samples
# 25/06/2021: RNA-Seq defined transcriptome using Stringtie and characterisation using gffcompare; Alignment of RNA-Seq reads to Iso-Seq & RNA-Seq defined transcriptome; Alternative splicing with SUPPA2; find human MAPT

#************************************* DEFINE GLOBAL VARIABLES
# setting names of directory outputs
Isoseq3_WKD=/gpfs/mrc0/projects/Research_Project-MRC148213/sl693/IsoSeq/Whole_Transcriptome/All_Tg4510/IsoSeq
PostIsoseq3_WKD=/gpfs/mrc0/projects/Research_Project-MRC148213/sl693/IsoSeq/Whole_Transcriptome/All_Tg4510/Post_IsoSeq
RNASeq_WKD=/gpfs/mrc0/projects/Research_Project-MRC148213/sl693/IsoSeq/Whole_Transcriptome/All_Tg4510/RNASeq
IsoRNASeq_WKD=/gpfs/mrc0/projects/Research_Project-MRC148213/sl693/IsoSeq/Whole_Transcriptome/All_Tg4510/IsovsRnaseq
ERCC=/gpfs/mrc0/projects/Research_Project-MRC148213/sl693/IsoSeq/Whole_Transcriptome/All_Tg4510/ERCC

#cd $Isoseq3_WKD; mkdir CCS LIMA REFINE CLUSTER MERGED_CLUSTER
#cd $PostIsoseq3_WKD; mkdir MAP TOFU SQANTI2 KALLISTO TAMA SQANTI_TAMA_FILTER RAREFACTION HUMANMAPT ALLRNASEQ
#cd $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME; mkdir KALLISTO
#cd $PostIsoseq3_WKD/SQANTI2; mkdir GENOME LNCRNA
#cd $PostIsoseq3_WKD/TAMA; mkdir GENOME LNCRNA
#cd $PostIsoseq3_WKD/SQANTI_TAMA_FILTER; mkdir GENOME LNCRNA
#cd $RNASeq_WKD; mkdir MAPPED
#cd $RNASeq_WKD; mkdir STRINGTIE KALLISTO SQANTI2


# sourcing functions script and input directories
FUNCTIONS=/gpfs/mrc0/projects/Research_Project-MRC148213/sl693/Scripts/Whole_Transcriptome_Paper/IsoSeq_Processing/Mouse
SAMPLES_LIST=$FUNCTIONS/All_Tg4510_Demultiplex.csv
source $FUNCTIONS/All_Tg4510_Functions.sh

REFERENCE=/gpfs/mrc0/projects/Research_Project-MRC148213/sl693/reference_2019
RNASeq_Filtered=/gpfs/mrc0/projects/Research_Project-MRC148213/sl693/RNASeq/all_filtered
SAMPLES_NAMES=(Q21 O18 L22 K18 O23 S23 S18 K17 M21 K23 Q20 K24)

module load Miniconda2/4.3.21
################################################################################################
echo "#*************************************  Isoseq3 [Function 1, 2, 3]"
echo "Already processed in batch (Mouse/All_Batch_Processing.sh)"

################################################################################################
echo "#************************************* Isoseq3 and Post_Isoseq3 [Function 4,5,6]"
# 4) merging_at_refine <input_flnc_bam_dir> <output_directory> <output_name> <samples.....>
merging_at_refine $Isoseq3_WKD/REFINE $Isoseq3_WKD/MERGED_CLUSTER WholeIsoSeq Q21 O18 L22 K18 O23 S23 S18 K17 M21 K23 Q20 K24
refine2fasta $Isoseq3_WKD/REFINE $Isoseq3_WKD/REFINE/fasta Q21 O18 L22 K18 O23 S23 S18 K17 M21 K23 Q20 K24

# 5) run_map_cupcakecollapse <sample_prefix_input/output_name> <isoseq3_input_directory> <mapping_output_directory> <tofu_output_directory>
run_map_cupcakecollapse WholeIsoSeq $Isoseq3_WKD/MERGED_CLUSTER $PostIsoseq3_WKD/MAP $PostIsoseq3_WKD/TOFU

# 6) demux <input path read.stat file> <input path of samples file> <path of output>
demux $PostIsoseq3_WKD/TOFU/WholeIsoSeq.collapsed.read_stat.txt $SAMPLES_LIST $PostIsoseq3_WKD/TOFU/WholeIsoSeq.Demultiplexed_Abundance.txt

################################################################################################
echo "#************************************* RNAseq [Function 7, 8]"
### Processed as batches in All_Batch_Processing.sh
## 7) run_star <list_of_samples> <J20/Tg4510_input_directory> <output_dir>
#for i in "${SAMPLES_NAMES[@]}"; do run_star $i $RNASeq_Filtered $STAR_dir; done
## for number of RNA-Seq reads
#cd $RNASeq_WKD/MAPPED; for i in K17 K18 K23 K24 L22 M21 O18 O23 Q20 Q21 S18 S23; do echo "################## $i"; cat $i/$i.Log.final.out;done > Mapped_Results.txt

## 8) mouse_merge_fastq <RNASEQ_input_dir> <Kallisto_output_dir> <sample_prefix_output_name>
mouse_merge_fastq $RNASeq_Filtered $RNASeq_WKD/MAPPED WholeIsoSeq

################################################################################################
echo "#************************************* RNASeq & IsoSeq [Function 9]"
## 9) run_kallisto <sample_prefix_output_name> <input_tofu_fasta> <merged_fastq_input_dir> <output_dir>
run_kallisto WholeIsoSeq $PostIsoseq3_WKD/TOFU/WholeIsoSeq.collapsed.rep.fa $RNASeq_WKD/MAPPED $PostIsoseq3_WKD/KALLISTO

################################################################################################
echo "#************************************* SQANTI2 [Function 10]"
## 10) run_sqanti2 <input_tofu_prefix> <input_gtf> <input_tofu_dir> <input_RNASEQ_dir> <input_KALLISTO_file> <input_abundance> <output_dir> <mode=genome/noexp/lncrna>
run_sqanti2 WholeIsoSeq.collapsed WholeIsoSeq.collapsed.gff $PostIsoseq3_WKD/TOFU $RNASeq_WKD/MAPPED $PostIsoseq3_WKD/KALLISTO/WholeIsoSeq.mod.abundance.tsv $PostIsoseq3_WKD/TOFU/WholeIsoSeq.Demultiplexed_Abundance.txt $PostIsoseq3_WKD/SQANTI2/GENOME genome

run_sqanti2 WholeIsoSeq.collapsed WholeIsoSeq.collapsed.gff $PostIsoseq3_WKD/TOFU $RNASeq_WKD/MAPPED $PostIsoseq3_WKD/KALLISTO/WholeIsoSeq.mod.abundance.tsv $PostIsoseq3_WKD/TOFU/WholeIsoSeq.Demultiplexed_Abundance.txt $PostIsoseq3_WKD/SQANTI2/LNCRNA lncrna

################################################################################################
echo "#************************************* TAMA filter [Function 11,12]"
## 11) TAMA_remove_fragments <input_collapsed.filtered.gff> <input/output_prefix_name> <input/output_dir>
TAMA_remove_fragments $PostIsoseq3_WKD/SQANTI2/GENOME/WholeIsoSeq.collapsed_classification.filtered_lite.gtf WholeIsoSeq $PostIsoseq3_WKD/TAMA/GENOME
TAMA_remove_fragments $PostIsoseq3_WKD/SQANTI2/LNCRNA/WholeIsoSeq.collapsed_classification.filtered_lite.gtf WholeIsoSeq $PostIsoseq3_WKD/TAMA/LNCRNA

## 12) TAMA_sqanti_filter <TAMA_remove_fragments.output> <sqanti_filtered_dir> <sqanti_output_txt> <sqanti_output_gtf> <sqanti_output_fasta> <output_prefix_name> <output_dir>
sqname=WholeIsoSeq.collapsed_classification.filtered_lite
TAMA_sqanti_filter $PostIsoseq3_WKD/TAMA/GENOME/WholeIsoSeq.bed $PostIsoseq3_WKD/SQANTI2/GENOME $sqname"_classification.txt" $sqname".gtf" $sqname".fasta" $sqname"_junctions.txt" WholeIsoSeq $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME

TAMA_sqanti_filter $PostIsoseq3_WKD/TAMA/LNCRNA/WholeIsoSeq.bed $PostIsoseq3_WKD/SQANTI2/LNCRNA $sqname"_classification.txt" $sqname".gtf" $sqname".fasta" $sqname"_junctions.txt" WholeIsoSeq $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/LNCRNA


source activate sqanti2_py3
SQ_Report=/gpfs/mrc0/projects/Research_Project-MRC148213/sl693/softwares/Post_Isoseq3/SQANTI2/utilities/SQANTI_report2.R
cd $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME; Rscript $SQ_Report WholeIsoSeq_sqantitamafiltered.classification.txt WholeIsoSeq_sqantitamafiltered.junction.txt $>> WholeIsoSeq_sqantitamafiltered.sq_qc.log
cd $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/LNCRNA; Rscript $SQ_Report WholeIsoSeq_sqantitamafiltered.classification.txt WholeIsoSeq_sqantitamafiltered.junction.txt $>> WholeIsoSeq_sqantitamafiltered.sq_qc.log

## 19) run_kallisto <sample_prefix_output_name> <input_tofu_fasta> <merged_fastq_input_dir> <output_dir>
# aligning RNA-Seq merged fasta sequence to Iso-Seq Defined transcriptome
# RNA-Seq merged fasta same as that generated from mouse_merge_fastq (function 5) using the same samples R1 and R2 merged
cd $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME/
cat $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME/WholeIsoSeq_sqantifiltered_tamafiltered_classification.fasta |sed -e '/^>/s/$/@/' -e 's/^>/#/'|tr '\n' ' '|sed 's/ //g'|sed 's/@/\n/g'|sed 's/#/\n>/g'|sed '/^$/d' > WholeIsoSeq_sqantifiltered_tamafiltered_classification_final.fasta
run_kallisto WholeIsoSeq $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME/WholeIsoSeq_sqantifiltered_tamafiltered_classification_final.fasta $RNASeq_WKD/MAPPED $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME/KALLISTO

################################################################################################
echo "#************************************* ERCC [Function 13]"
## 13) run_ERCC_analysis <sample_prefix_input/output_name> <isoseq3_input_directory>
run_ERCC_analysis WholeIsoSeq $Isoseq3_WKD/MERGED_CLUSTER $ERCC

################################################################################################
echo "#************************************* QC [Function 14,15,16]"
## 14) make_file_for_rarefaction <sample_name_prefix> <input_tofu_directory> <input_sqanti_tama_directory> <working_directory>
#make_file_for_rarefaction WholeIsoSeq $PostIsoseq3_WKD/TOFU $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME $PostIsoseq3_WKD/RAREFACTION

# CCS and LIMA stats
## 15) parse_stats_per_sample <input_ccs.bam_dir> <Input_LIMA_directory> <output_prefix_name>
parse_stats_per_sample $Isoseq3_WKD/CCS $Isoseq3_WKD/LIMA WholeIsoSeqAll

## 16) ccs_bam2fasta <sample_name> <input_ccs.bam_dir> <output_dir>
## lenghts <sample> <prefix.fasta> <input_dir> <output_dir>
mkdir $Isoseq3_WKD/CCS/Lengths $Isoseq3_WKD/CLUSTER/Lengths
for i in "${SAMPLES_NAMES[@]}"; do ccs_bam2fasta $i $Isoseq3_WKD/CCS $Isoseq3_WKD/CCS/Lengths; done
for i in "${SAMPLES_NAMES[@]}"; do lengths $i .clustered.hq.fasta $Isoseq3_WKD/CLUSTER $Isoseq3_WKD/CLUSTER/Lengths; done
lengths WholeIsoSeq .collapsed.rep.fa $PostIsoseq3_WKD/TOFU $PostIsoseq3_WKD/TOFU

################################################################################################
echo "#************************************* RNA-Seq defined transcriptome [Function 17,18,19]"
## 17) run_stringtie <input_reference_gtf> <input_mapped_dir> <output_stringtie_dir> <output_prefix>
run_stringtie $REFERENCE/gencode.vM22.annotation.gtf $RNASeq_WKD/MAPPED $RNASeq_WKD/STRINGTIE rnaseq_stringtie_merged

## 18) run_sqanti2 <input_tofu_prefix> <input_gtf> <input_tofu_dir> <input_RNASEQ_dir> <input_KALLISTO_file> <input_abundance> <output_dir> <mode=genome/rnaseq/lncrna>
run_sqanti2 rnaseq_stringtie_merged_final rnaseq_stringtie_merged_final.gtf $RNASeq_WKD/STRINGTIE $RNASeq_WKD/MAPPED NA NA $RNASeq_WKD/SQANTI2 rnaseq

## 19) run_kallisto <sample_prefix_output_name> <input_tofu_fasta> <merged_fastq_input_dir> <output_dir>
# aligning RNA-Seq merged fasta sequence to RNA-Seq defined transcriptome
# RNA-Seq merged fasta same as that generated from mouse_merge_fastq (function 5) using the same samples R1 and R2 merged
run_kallisto WholeIsoSeq $RNASeq_WKD/SQANTI2/rnaseq_stringtie_merged_final_classification.filtered_lite.fasta $RNASeq_WKD/MAPPED $RNASeq_WKD/KALLISTO
run_kallisto WholeIsoSeq $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME/WholeIsoSeq_sqantifiltered_tamafiltered_classification.fasta $RNASeq_WKD/MAPPED $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME/KALLISTO

## 20) run_longshort_gffcompare <longread_gtf> <shortread_gtf> <output_dir> <output_name>
run_longshort_gffcompare $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME/WholeIsoSeq_sqantitamafiltered.classification.gtf $RNASeq_WKD/SQANTI2/rnaseq_stringtie_merged_final_classification.filtered_lite.gtf $RNASeq_WKD/GFF_COMP long_short_transcripts

run_tama_merge $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME/WholeIsoSeq_sqantitamafiltered.classification.gtf $RNASeq_WKD/SQANTI2/rnaseq_stringtie_merged_final_classification.filtered_lite.gtf WholeIsoSeq RNASeq $IsoRNASeq_WKD/TAMA RNA2IsoSeq

################################################################################################
echo "#************************************* Iso-Seq vs RNA-Seq defined transcriptome [Function 21]"
# run_counts_isoseqrnaseqtranscriptome <alignmentgtf> <fwd_rnaseq> <rev_rnaseq> <output_name> <output_dir>
# Alignment of RNA-Seq reads to Iso-Seq defined transcriptome
run_counts_isoseqrnaseqtranscriptome $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME/WholeIsoSeq_sqantitamafiltered.final.classification.gtf $RNASeq_WKD/MAPPED/WholeIsoSeq_R1.fq $RNASeq_WKD/MAPPED/WholeIsoSeq_R2.fq RNA2IsoSeq $IsoRNASeq_WKD/IsoSeq_Def

# Alignment of RNA-Seq reads to RNA-Seq defined transcriptome
run_counts_isoseqrnaseqtranscriptome $RNASeq_WKD/SQANTI2/rnaseq_stringtie_merged_final_classification.filtered_lite.gtf $RNASeq_WKD/MAPPED/WholeIsoSeq_R1.fq $RNASeq_WKD/MAPPED/WholeIsoSeq_R2.fq RNA2RNASeq $IsoRNASeq_WKD/RNASeq_Def RNA2IsoSeq

################################################################################################
echo "#************************************* Alternative Splicing [Function 22]"
# run_suppa2 <input_gtf> <input_class> <output_dir> <output_name>
run_suppa2 $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME/WholeIsoSeq_sqantitamafiltered.classification.gtf $PostIsoseq3_WKD/SQANTI_TAMA_FILTER/GENOME/WholeIsoSeq_sqantitamafiltered.classification.txt $PostIsoseq3_WKD/SUPPA WholeIsoSeq

################################################################################################
echo "#************************************* Find human MAPT [Function 23]"
# find_humanMAPT <cluster_dir> <output_dir> <merged_cluster.fa>
find_humanMAPT $Isoseq3_WKD/CLUSTER $PostIsoseq3_WKD/HUMANMAPT $Isoseq3_WKD/MERGED_CLUSTER/WholeIsoSeq.clustered.hq.fasta
