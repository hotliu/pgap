#!/usr/bin/env cwl-runner
label: taxonomy_check_16S
cwlVersion: v1.0
class: Workflow
requirements: 
    - class: SubworkflowFeatureRequirement    
inputs:
  Format_16S_rRNA___entry: File
  asn_cache: Directory
  blastdb_dir: Directory
  taxid: int
outputs:
  Taxonomic_consistency_check_based_on_16S_Analysis___report:
    type: File
    outputSource: Taxonomic_consistency_check_based_on_16S_Analysis/report
steps:
  Format_16S_rRNA:
    run: ../task_types/tt_format_rrnas_from_seq_entry.cwl
    in:
      entry: Format_16S_rRNA___entry
    out: [rna]
  # Get_16S_rRNA_BLASTdb_for_taxonomic_consistency_check:
  #  run: ../task_types/tt_const_blastdb.cwl
  #  out: [blastdb]
  Cache_Genomic_16S_Sequences:
    run: ../task_types/tt_cache_asnb_entries.cwl
    in:
      rna: Format_16S_rRNA/rna
      cache: asn_cache
      ifmt: 
        default: asnb-seq-entry
      taxid: taxid
    out: [ids_out, asn_cache]
  BLAST_against_16S_rRNA_db_for_taxonomic_consistency_check:
    run: ../task_types/tt_blastn_wnode.cwl
    in:
      ids_out: Cache_Genomic_16S_Sequences/ids_out
      blastdb_dir: blastdb_dir
      blastdb: 
        default: "blastdb"
      gilist: Cache_Genomic_16S_Sequences/ids_out
      evalue:
        default: 0.01
      max_target_seqs:
        default: 250
      word_size: 
        default: 12
      asn_cache: Cache_Genomic_16S_Sequences/asn_cache
      affinity: 
        default: subject
      max_batch_length:
        default: 50000
      soft_masking:
        default: true
    out: [blast_align]
  Consolidate_alignments_for_taxonomic_consistency_check:
    run: ../task_types/tt_align_merge_sas.cwl
    in:
      blastdb_dir: blastdb_dir
      blastdb: 
        default: "blastdb"
      blast_align: BLAST_against_16S_rRNA_db_for_taxonomic_consistency_check/blast_align
      asn_cache: Cache_Genomic_16S_Sequences/asn_cache
      allow_intersection: 
        default: true
      collated:
        default: true
      compart:
        default: true
      fill_gaps:
        default: false
      top_compartment_only:
        default: true
    out: [align]
  Well_covered_alignments_for_taxonomic_consistency_check:
    run: ../task_types/tt_align_filter_sa.cwl
    in:
      prosplign_align: ""
      align_full: ""
      align: Consolidate_alignments_for_taxonomic_consistency_check/align
      asn_cache: Cache_Genomic_16S_Sequences/asn_cache
      filter: 
        default: "pct_coverage >= 20"
      nogenbank:
        default: false
    out: [out_align]
  Pick_tops_for_taxonomic_consistency_check:
    run: ../task_types/tt_align_sort_sa.cwl
    in:
      align: Well_covered_alignments_for_taxonomic_consistency_check/out_align
      asn_cache: Cache_Genomic_16S_Sequences/asn_cache
      group: 
        default: 1
      k: 
        default: "query subject"
      top:
        default: 20
    out: [out_align]
  Taxonomic_consistency_check_based_on_16S_Analysis:
    run: ../task_types/tt_taxonomy_check_16S.cwl
    in: 
      blastdb_dir: blastdb_dir
      blastdb: 
        default: "blastdb"
      asn_cache: Cache_Genomic_16S_Sequences/asn_cache
      align: Pick_tops_for_taxonomic_consistency_check/out_align
    out: [report]