#!/usr/bin/env cwl-runner

label: "PGAP Pipeline"
cwlVersion: v1.0
class: Workflow
doc: PGAP pipeline for external usage, powered via containers

requirements:
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  #
  # User specific input
  #
  entries: File?
  seq_submit: File?
  taxid: int
  gc_assm_name: string
  locus_tag_prefix: string?
  dbname: string?
  report_usage: boolean

  #
  # User independent, static input
  #
  blast_rules_db:
    type: string
    default: blast_rules_db
  scatter_gather_nchunks:
    type: string
    default: '1'
  supplemental_data:
    type: Directory
    default:
      class: Directory
      location: input

steps:
  ping_start:
    run: progs/pinger.cwl
    in:
      report_usage: report_usage
      state:
        default: "start"
      workflow:
        default: "pgap"
      instring: gc_assm_name
    out: [stdout, outstring]

  passdata:
    in:
      data: supplemental_data
    run:
      class: CommandLineTool
      #requirements:
      #  InitialWorkDirRequirement:
      #    listing:
      #      - entry: $(inputs.data)
      #        writable: False
      baseCommand: [cp, -ar]
      inputs:
        data:
          type: Directory
          inputBinding:
            position: 1
        destination:
          type: string
          default: .
          inputBinding:
            position: 2
      outputs:
        16s_blastdb_dir:
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/16S_rRNA
        23s_blastdb_dir:
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/23S_rRNA
        5s_model_path:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/RF00001.cm
        AntiFamLib:
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/AntiFamLib
        asn2pas_xsl:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/asn2pas.xsl
        blast_rules_db_dir:
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/uniColl_path/blast_dir
        CDDdata: # ${GP_HOME}/third-party/data/CDD/cdd - this is rpsblastdb
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/CDD
        CDDdata2: # ${GP_HOME}/third-party/data/cdd_add
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/cdd_add
        defline_cleanup_rules: # defline_cleanup_rules # ${GP_HOME}/etc/product_rules.prt
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/product_rules.prt
        gene_master_ini:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/gene_master.ini
        genemark_path:
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/GeneMark
        hmm_path:
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/uniColl_path/real_hmms
        hmms_tab:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/uniColl_path/real_hmms.tab
        naming_blast_db: # NamingDatabase
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/uniColl_path/blast_dir # this one might have created problems for assign_cluster, let's try this:
        naming_hmms_combined: # ${GP_HOME}/third-party/data/BacterialPipeline/uniColl/ver-3.2/naming_hmms_combined.mft
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/uniColl_path/naming_hmms
        naming_hmms_tab:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/uniColl_path/naming_hmms.tab
        naming_sqlite: # /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/home/badrazat/local-install/2018-05-17/third-party/data/BacterialPipeline/uniColl/ver-3.2/naming.sqlite
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/uniColl_path/naming.sqlite
        rfam_amendments:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/rfam-amendments.xml
        rfam_model_path:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/Rfam.selected1.cm
        rfam_stockholm:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/Rfam.seed
        selenoproteins: # /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/home/badrazat/local-install/2018-05-17/third-party/data/BacterialPipeline/Selenoproteins/selenoproteins, it's blastdb
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/selenoproteins
        taxon_db:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/uniColl_path/taxonomy.sqlite3
        thresholds:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/thresholds.xml
        uniColl_cache:
          type: Directory
          outputBinding:
            glob: $(inputs.data.basename)/uniColl_path/cache
        univ_prot_xml:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/uniColl_path/universal.xml
        val_res_den_xml:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/validation-results.xml
        wp_hashes:
          type: File
          outputBinding:
            glob: $(inputs.data.basename)/uniColl_path/wp-hashes.sqlite
    out:
      - 16s_blastdb_dir
      - 23s_blastdb_dir
      - 5s_model_path
      - AntiFamLib
      - asn2pas_xsl
      - blast_rules_db_dir
      - CDDdata2
      - CDDdata
      - defline_cleanup_rules
      - gene_master_ini
      - genemark_path
      - hmm_path
      - hmms_tab
      - naming_blast_db
      - naming_hmms_combined
      - naming_hmms_tab
      - naming_sqlite
      - rfam_amendments
      - rfam_model_path
      - rfam_stockholm
      - selenoproteins
      - taxon_db
      - thresholds
      - uniColl_cache
      - univ_prot_xml
      - val_res_den_xml
      - wp_hashes

  genomic_source: # PLANE
    run: genomic_source/wf_genomic_source_asn.cwl
    in:
      entries: entries
      seq_submit: seq_submit
      # taxid: taxid
      gc_assm_name: ping_start/outstring
      taxon_db: passdata/taxon_db
    out: [gencoll_asn, seqid_list, stats_report, asncache, ids_out, submit_block_template]

  #
  #  Pseudo plane "default 1"
  #
  Prepare_Unannotated_Sequences: # ORIGINAL TASK NAME: Prepare Unannotated Sequences # default 1
    label: "Prepare Unannotated Sequences"
    run: bacterial_prepare_unannotated.cwl
    in:
      asn_cache: genomic_source/asncache
      gc_assembly: genomic_source/gencoll_asn
      ids: genomic_source/seqid_list
      submit_block: genomic_source/submit_block_template
      taxon_db: passdata/taxon_db
    out: [master_desc, sequences]

  Cache_Entrez_Gene: # ORIGINAL TASK NAME: Cache Entrez Gene # default 1
    label: "Cache Entrez Gene"
    run: cache_entrez_gene.cwl
    in:
      asn_cache: [genomic_source/asncache, passdata/uniColl_cache]
      egene_ini: passdata/gene_master_ini
      input: Prepare_Unannotated_Sequences/sequences
    out: [prok_entrez_gene_stuff]

  Create_Genomic_BLASTdb: # default 1
   label: "Create Genomic BLASTdb" # default 1
   run: progs/gp_makeblastdb.cwl
   in:
       ids: genomic_source/ids_out
       title:
           default: 'BLASTdb  created by GPipe'
       asn_cache:
         source: [ genomic_source/asncache ]
         linkMerge: merge_flattened
       dbtype:
           default: 'nucl'
   out: [blastdb]
  #
  # end of pseudo plane "default 1"
  #
  bacterial_ncrna: # PLANE
    run: bacterial_ncrna/wf_gcmsearch.cwl
    in:
      asn_cache: genomic_source/asncache
      seqids: genomic_source/seqid_list
      model_path: passdata/rfam_model_path
      rfam_amendments: passdata/rfam_amendments
      rfam_stockholm: passdata/rfam_stockholm
      taxon_db: passdata/taxon_db
    out: [annots]

  bacterial_mobile_elem: # PLANE
    run: bacterial_mobile_elem/wf_bacterial_mobile_elem.cwl
    in:
      asn_cache: genomic_source/asncache
      seqids: genomic_source/seqid_list
    out: [annots]

  bacterial_noncoding: # PLANE
    run: bacterial_noncoding/wf_bacterial_noncoding.cwl
    in:
      asn_cache: genomic_source/asncache
      seqids: genomic_source/seqid_list
      16s_blastdb_dir: passdata/16s_blastdb_dir
      23s_blastdb_dir: passdata/23s_blastdb_dir
      model_path: passdata/5s_model_path
      rfam_amendments: passdata/rfam_amendments
      rfam_stockholm: passdata/rfam_stockholm
      taxon_db: passdata/taxon_db
    out: [ annotations_5s, annotations_16s, annotations_23s ]

  bacterial_trna: # PLANE
    run: bacterial_trna/wf_trnascan.cwl
    in:
      asn_cache: genomic_source/asncache
      seqids: genomic_source/seqid_list
      taxid: taxid
      taxon_db: passdata/taxon_db
      scatter_gather_nchunks: scatter_gather_nchunks
    out: [annots]

  bacterial_annot: # PLANE
    run: bacterial_annot/wf_bacterial_annot_pass1.cwl
    in:
      asn_cache: genomic_source/asncache
      inseq: Prepare_Unannotated_Sequences/sequences
      hmm_path: passdata/hmm_path
      hmms_tab: passdata/hmms_tab
      scatter_gather_nchunks: scatter_gather_nchunks
      uniColl_cache: passdata/uniColl_cache
      trna_annots: bacterial_trna/annots
      ncrna_annots: bacterial_ncrna/annots
      nogenbank:
        default: true
      Execute_CRISPRs_annots: bacterial_mobile_elem/annots
      Generate_16S_rRNA_Annotation_annotation: bacterial_noncoding/annotations_16s
      Generate_23S_rRNA_Annotation_annotation: bacterial_noncoding/annotations_23s
      Post_process_CMsearch_annotations_annots_5S: bacterial_noncoding/annotations_5s
      genemark_path: passdata/genemark_path
      thresholds: passdata/thresholds
    out: [lds2,seqids,proteins, aligns, annotation, out_hmm_params, outseqs, prot_ids]

  spurious_annot_1: # PLANE
    run: spurious_annot/wf_spurious_annot_pass1.cwl
    in:
      Extract_ORF_Proteins_proteins: bacterial_annot/proteins
      Extract_ORF_Proteins_seqids: bacterial_annot/seqids
      Extract_ORF_Proteins_lds2: bacterial_annot/lds2
      AntiFamLib: passdata/AntiFamLib
      sequence_cache: genomic_source/asncache
      scatter_gather_nchunks: scatter_gather_nchunks
    out: [AntiFam_tainted_proteins_I___oseqids]

  bacterial_annot_2: # PLANE
    run: bacterial_annot/wf_bacterial_annot_pass2.cwl
    in:
        lds2: bacterial_annot/lds2
        proteins: bacterial_annot/proteins
        prot_ids_A: bacterial_annot/seqids
        prot_ids_B1: bacterial_annot/prot_ids
        prot_ids_B2: spurious_annot_1/AntiFam_tainted_proteins_I___oseqids
        blast_rules_db_dir: passdata/blast_rules_db_dir
        blast_rules_db: blast_rules_db
        identification_db_dir: passdata/naming_blast_db
        annotation: bacterial_annot/outseqs
        sequence_cache: genomic_source/asncache
        unicoll_cache: passdata/uniColl_cache
        scatter_gather_nchunks: scatter_gather_nchunks
    out: [aligns] #   label: "goes to protein_alignment/Seed Search Compartments/compartments"

  protein_alignment: # PLANE
    run: protein_alignment/wf_protein_alignment.cwl
    in:
      asn_cache: genomic_source/asncache
      uniColl_asn_cache: passdata/uniColl_cache
      naming_sqlite: passdata/naming_sqlite
      blastdb_dir: Create_Genomic_BLASTdb/blastdb
      taxid: taxid
      tax_sql_file: passdata/taxon_db
      gc_assembly: genomic_source/gencoll_asn
      compartments: bacterial_annot_2/aligns
    out: [universal_clusters, align, align_non_match]

  bacterial_annot_3:
    run: bacterial_annot/wf_bacterial_annot_pass3.cwl
    in:
        uniColl_cache: passdata/uniColl_cache
        sequence_cache: genomic_source/asncache
        hmm_aligns: bacterial_annot/aligns
        scatter_gather_nchunks: scatter_gather_nchunks
        prot_aligns: protein_alignment/align  # label: "Filter Protein Alignments I/align"
        annotation: bacterial_annot/annotation
        raw_seqs: Prepare_Unannotated_Sequences/sequences
        thresholds: passdata/thresholds
        naming_sqlite: passdata/naming_sqlite
        hmm_params: bacterial_annot/out_hmm_params # Run GeneMark Training/hmm_params (EXTERNAL, put to input/
        selenoproteins: passdata/selenoproteins
        naming_hmms_combined: passdata/naming_hmms_combined
        hmms_tab: passdata/naming_hmms_tab
        wp_hashes: passdata/wp_hashes
        taxon_db: passdata/taxon_db
        genemark_path: passdata/genemark_path
    out:
        - id: Find_Best_Evidence_Alignments_aligns
        - id: Run_GeneMark_Post_models
        - id: Extract_Model_Proteins_seqids
        - id: Extract_Model_Proteins_lds2
        - id: Extract_Model_Proteins_proteins
        - id: Search_Naming_HMMs_hmm_hits
        - id: Assign_Naming_HMM_to_Proteins_assignments
        - id: Name_by_WPs_names

  spurious_annot_2:
    run: spurious_annot/wf_spurious_annot_pass2.cwl
    in:
      Extract_Model_Proteins_proteins: bacterial_annot_3/Extract_Model_Proteins_proteins
      Extract_Model_Proteins_seqids: bacterial_annot_3/Extract_Model_Proteins_seqids
      Extract_Model_Proteins_lds2: bacterial_annot_3/Extract_Model_Proteins_lds2
      AntiFamLib: passdata/AntiFamLib
      sequence_cache: genomic_source/asncache
      scatter_gather_nchunks: scatter_gather_nchunks
      Run_GeneMark_models: bacterial_annot_3/Run_GeneMark_Post_models
    out:
      - AntiFam_tainted_proteins___oseqids
      - Good_AntiFam_filtered_annotations_out
      - Good_AntiFam_filtered_proteins_output

  bacterial_annot_4:
    run: bacterial_annot/wf_bacterial_annot_pass4.cwl
    in:
        lds2: bacterial_annot_3/Extract_Model_Proteins_lds2
        proteins: bacterial_annot_3/Extract_Model_Proteins_proteins
        annotation: spurious_annot_2/Good_AntiFam_filtered_annotations_out
        Good_AntiFam_filtered_proteins_gilist: spurious_annot_2/Good_AntiFam_filtered_proteins_output
        sequence_cache: genomic_source/asncache
        uniColl_cache: passdata/uniColl_cache
        naming_blast_db: passdata/naming_blast_db
        naming_sqlite: passdata/naming_sqlite
        hmm_assignments:  bacterial_annot_3/Assign_Naming_HMM_to_Proteins_assignments
        wp_assignments:  bacterial_annot_3/Name_by_WPs_names
        Extract_Model_Proteins_prot_ids: bacterial_annot_3/Extract_Model_Proteins_seqids
        CDDdata: passdata/CDDdata
        CDDdata2: passdata/CDDdata2
        thresholds: passdata/thresholds
        defline_cleanup_rules: passdata/defline_cleanup_rules
        blast_rules_db_dir: passdata/blast_rules_db_dir
        blast_rules_db: blast_rules_db
        identification_db_dir: passdata/naming_blast_db
        scatter_gather_nchunks: scatter_gather_nchunks
    out:
        - id: out_annotation
  # #
  # # Pseudo plane default 2, we do not need that for new submissions in off-NCBI environment
  # #
  # # Preserve_Annotations: # Pseudo plane default 2
   # # run: task_types/tt_preserve_annot.cwl
   # # in:
     # # asn_cache:
        # # source: [genomic_source/asncache]
        # # linkMerge: merge_flattened
     # # input_annotation: bacterial_annot/annotation
     # # rfam_amendments: rfam_amendments
     # # no_ncRNA:
       # # default: true
   # # out: [annotations]
  # # preserve_annot_markup: # Pseudo plane default 2
    # # # uncharted territory!!!
    # # run: preserve_annot_markup.cwl # Preserve Product Accessions
    # # in:
      # # #seq_cache: genobacterial_prepare_unannotated/asncache
      # # #unicoll_cache: uniColl_cache
      # # input_annotation: Preserve_Annotations/annotations
      # # asn_cache: [genomic_source/asncache, uniColl_cache]
      # # egene_ini: gene_master_ini
      # # gc_assembly: genomic_source/gencoll_asn
      # # input: Preserve_Annotations/annotations
      # # prok_entrez_gene_stuff: Cache_Entrez_Gene/prok_entrez_gene_stuff
    # # out: [annotations]

  # #
  # # End of Pseudo plane default 2
  # #
  # # This step takes input from bacterial_annot 4/Bacterial Annot Filter, see GP-23942
  # # Status:
    # # tasktype coded, input/output matches
    # # application not coded
  # ###############################################
  # # AMR plane is for later stages skipping
  # ###############################################
  Add_Locus_Tags:
    run: progs/add_locus_tags.cwl
    in:
        input: bacterial_annot_4/out_annotation
        locus_tag_prefix: locus_tag_prefix
        dbname: dbname
    out: [output]

  #
  # Pseudo plane default 3
  #

  #
  #  Final_Bacterial_Package task
  #
  Final_Bacterial_Package_asn_cleanup:
    run: progs/asn_cleanup.cwl
    in:
      inp_annotation: Add_Locus_Tags/output # production
      serial:
        default: binary
    out: [annotation]

  Final_Bacterial_Package_final_bact_asn:
    run: progs/final_bact_asn.cwl
    in:
      annotation:
        source: [Final_Bacterial_Package_asn_cleanup/annotation]
        linkMerge: merge_flattened
      asn_cache: genomic_source/asncache
      gc_assembly: genomic_source/gencoll_asn # gc_create_from_sequences
      master_desc: Prepare_Unannotated_Sequences/master_desc
      submit_block_template: 
        source: [genomic_source/submit_block_template]
        linkMerge: merge_flattened
      it:
        default: true
      submission_mode_genbank:
        default: true
      nogenbank:
        default: true

    out: [outfull]
  Final_Bacterial_Package_dumb_down_as_required:
    run: progs/dumb_down_as_required.cwl
    in:
      annotation:  Final_Bacterial_Package_final_bact_asn/outfull
      asn_cache:
        source: [genomic_source/asncache]
        linkMerge: merge_flattened
      max_x_ratio:
        default: 0.1
      max_x_run:
        default: 3
      partial_cov_threshold:
        default: 65
      partial_len_threshold:
        default: 30
      drop_partial_in_the_middle:
        default: true
      submission_mode_genbank:
        default: true
      nogenbank:
        default: true
      it:
        default: true
    out: [outent]
  Final_Bacterial_Package_ent2sqn:
    run: progs/ent2sqn.cwl
    in:
      annotation: Final_Bacterial_Package_dumb_down_as_required/outent
      asn_cache:
        source: [genomic_source/asncache]
        linkMerge: merge_flattened
      gc_assembly: genomic_source/gencoll_asn # gc_create_from_sequences
      submit_block_template: 
        source: [genomic_source/submit_block_template]
        linkMerge: merge_flattened
      it:
        default: true
    out: [output]
  Final_Bacterial_Package_sqn2gbent:
    run: progs/sqn2gbent.cwl
    in:
      input: Final_Bacterial_Package_ent2sqn/output
      it:
        default: true
    out: [output]
  Generate_Annotation_Reports_gff:
    run: progs/gp_annot_format.cwl
    in:
        input: Final_Bacterial_Package_dumb_down_as_required/outent
        ifmt:
            default: seq-entry
        t:
            default: true
        ofmt:
            default: gff3
        exclude_external:
            default: true
    out: [output]
  Generate_Annotation_Reports_gbk:
    run: progs/asn2flat.cwl
    in:
        input: Final_Bacterial_Package_sqn2gbent/output
        no_external:
            default: true
        type:
            default: seq-entry
        mode:
            default: entrez
        style:
            default: master
        gbload:
            default: true
    out: [output]
  Generate_Annotation_Reports_nuc_fasta:
    run: progs/asn2fasta.cwl
    in:
        i: Final_Bacterial_Package_sqn2gbent/output
        type:
            default: seq-entry
        nuc_fasta_name:
            default: annot.fna
    out: [nuc_fasta]
  Generate_Annotation_Reports_prot_fasta:
    run: progs/asn2fasta.cwl
    in:
            i: Final_Bacterial_Package_sqn2gbent/output
            type:
                default: seq-entry
            prot_fasta_name:
                default: annot.faa
    out: [prot_fasta]
  Final_Bacterial_Package_std_validation:
    run: progs/std_validation.cwl
    in:
      annotation: Final_Bacterial_Package_dumb_down_as_required/outent
      asn_cache:
        source: [genomic_source/asncache]
      exclude_asndisc_codes: #
        default: ['OVERLAPPING_CDS']
      inent: Final_Bacterial_Package_dumb_down_as_required/outent
      ingb: Final_Bacterial_Package_sqn2gbent/output
      insqn: Final_Bacterial_Package_ent2sqn/output
      master_desc:
        source: [Prepare_Unannotated_Sequences/master_desc]
        linkMerge: merge_flattened
      submit_block_template:
        source: [genomic_source/submit_block_template]
        linkMerge: merge_flattened
      it:
        default: true
      submission_mode_genbank:
        default: true
      nogenbank:
        default: true
    out:
      - id: outdisc
      - id: outdiscxml
      - id: outmetamaster
      - id: outval
  Final_Bacterial_Package_val_stats: # TESTED (unit test)
    run: progs/val_stats.cwl
    in:
      annot_val: Final_Bacterial_Package_std_validation/outval
      c_toolkit:
        default: true
    out: [output, xml]
  #
  #  end of Final_Bacterial_Package task
  #

  #### we do not need this
  # Prepare_Init_Refseq_Molecules:
  #  run: progs/

  #
  #  Validate_Annotation task
  #

  Validate_Annotation_bact_univ_prot_stats:
    run: progs/bact_univ_prot_stats.cwl
    in:
      annot_request_id:
        default: -1 # this is dummy annot_request_id
      hmm_search: bacterial_annot_3/Search_Naming_HMMs_hmm_hits
      hmm_search_proteins: bacterial_annot_3/Run_GeneMark_Post_models
      input:  Final_Bacterial_Package_final_bact_asn/outfull
      univ_prot_xml:  passdata/univ_prot_xml
      val_res_den_xml:  passdata/val_res_den_xml
      it:
        default: true
    out: [bact_univ_prot_stats_old_xml, var_bact_univ_prot_details_xml, var_bact_univ_prot_stats_xml]

  Validate_Annotation_proc_annot_stats:
    run: progs/proc_annot_stats.cwl
    in:
      input: Final_Bacterial_Package_dumb_down_as_required/outent
      max_unannotated_region:
        default: 5000
      univ_prot_xml:  passdata/univ_prot_xml
      val_res_den_xml:  passdata/val_res_den_xml
      it:
        default: true
    out:
      - id: var_proc_annot_stats_xml
      - id: var_proc_annot_details_xml
  Validate_Annotation_xsltproc_asnvalidate:
    run: progs/xsltproc.cwl
    in:
      xml: Final_Bacterial_Package_val_stats/xml
      xslt: passdata/asn2pas_xsl
      output_name:
        default: 'var_proc_annot_stats.val.xml'
    out: [output]
  Validate_Annotation_xsltproc_asndisc:
    run: progs/xsltproc.cwl
    in:
      xml: Final_Bacterial_Package_std_validation/outdiscxml
      xslt: passdata/asn2pas_xsl
      output_name:
        default: 'var_proc_annot_stats.disc.xml'
    out: [output]
  Validate_Annotation_collect_annot_stats: # TESTED (unit test)
    run: progs/collect_annot_stats.cwl
    in:
      input:
        source:
            - Validate_Annotation_bact_univ_prot_stats/var_bact_univ_prot_stats_xml
            - Validate_Annotation_proc_annot_stats/var_proc_annot_stats_xml
            - Validate_Annotation_xsltproc_asndisc/output
            - Validate_Annotation_xsltproc_asnvalidate/output
        linkMerge: merge_flattened
      output_name:
        default: proc_annot_stats.xml
    out: [output]
  Validate_Annotation_collect_annot_details:
    run: progs/collect_annot_stats.cwl
    in:
      input:
        source:
            - Validate_Annotation_bact_univ_prot_stats/var_bact_univ_prot_details_xml
            - Validate_Annotation_proc_annot_stats/var_proc_annot_details_xml
        linkMerge: merge_flattened
      output_name:
        default: proc_annot_details.xml
    out: [output]

  ping_stop:
    run: progs/pinger.cwl
    in:
      report_usage: report_usage
      state:
        default: "stop"
      workflow:
        default: "pgap"
      # Note: the input on the following line should be the same as all of the outputs
      # for this workflow, so we ensure this is the final step.
      infile:
        - Final_Bacterial_Package_sqn2gbent/output
        - Generate_Annotation_Reports_gff/output
        - Generate_Annotation_Reports_gbk/output
        - Generate_Annotation_Reports_nuc_fasta/nuc_fasta
        - Generate_Annotation_Reports_prot_fasta/prot_fasta
    out: [stdout]

  #
  #  end of Validate_Annotation task
  #

  #
  # End of Pseudo plane default 3
  #

  ###############################################
  # taxonomy plane is for later stages skipping
  ###############################################

  #
  # Pseudo plane default 4
  #

  # task: Generate Annotation Reports
  #
  # Generate_Annotation_Reports_pgaap_prepare_review:
    # run: progs/pgaap_prepare_review.cwl
  # Generate_Annotation_Reports_lds2_indexer:
    # run: progs/lds2_indexer.cwl
  #
  # comparisons only for pre-existing annotation, one of the next phases
  #
  # # Generate_Annotation_Reports_comparison_format_curr_comparison:
    # # run: progs/comparison_format.cwl
  # # Generate_Annotation_Reports_comparison_format_prev_comparison:
    # # run: progs/comparison_format.cwl
  # # Generate_Annotation_Reports_comparison_format_prev_assm_comparison:
    # # run: progs/comparison_format.cwl
  # # Generate_Annotation_Reports_comparison_format_ref_comparison:
    # # run: progs/comparison_format.cwl
  # Generate_Annotation_Reports_bact_asn_stats:
    # run: progs/bact_asn_stats.cwl
    # in:
      # input_annotation: Final_Bacterial_Package_dumb_down_as_required/outent
      # it:
        # default: true
    # out: [output,  xml_output]
  # Generate_Annotation_Reports_val_format:
    # run: progs/val_format.cwl
  # Generate_Annotation_Reports_gbproject:
    # run: progs/gbproject.cwl
  # Generate_Annotation_Reports_asn2nucleotide_fasta:
    # run: progs/asn2fasta.cwl
  # Generate_Annotation_Reports_asn2all_protein_fasta:
    # run: progs/asn2fasta.cwl
  # Generate_Annotation_Reports_asn2protein_fasta:
    # run: progs/asn2fasta.cwl
  # Generate_Annotation_Reports_asn2flat:
    # run: progs/asn2flat.cwl
  # Generate_Annotation_Reports_format_rrnas:
    # run: progs/format_rrnas.cwl
  # Generate_Annotation_Reports_asn2rrna_fa:
    # run: progs/asn2fasta.cwl
  # Generate_Annotation_Reports_gp_annot_format:
    # run: progs/gp_annot_format.cwl
  # end of task: Generate Annotation Reports
  #

  #
  # End of Pseudo plane default 4
  #

outputs:
  gbent:
    type: File
    outputSource: Final_Bacterial_Package_sqn2gbent/output
  gff:
    type: File
    outputSource:  Generate_Annotation_Reports_gff/output
  gbk:
    type: File
    outputSource:  Generate_Annotation_Reports_gbk/output
  nucleotide_fasta:
    type: File?
    outputSource: Generate_Annotation_Reports_nuc_fasta/nuc_fasta
  protein_fasta:
    type: File?
    outputSource: Generate_Annotation_Reports_prot_fasta/prot_fasta

