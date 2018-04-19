cwlVersion: v1.0
label: "Run tRNAScan, execution"
class: CommandLineTool
hints:
  DockerRequirement:
    dockerPull: ncbi/bacterial_trna:pgap4.4

requirements:
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(inputs.asn_cache)
        writable: False

#trnascan_wnode -X 20 -asn-cache sequence_cache -g gcode.othmito -tRNAscan tRNAscan-SE -taxid 243273 -B -C -Q -b -q
baseCommand: trnascan_wnode
arguments: [ -X, "20", -B, -C, -Q, -b, -q ]
inputs:
  asn_cache:
    type: Directory
    inputBinding:
      prefix: -asn-cache
  input_jobs:
    type: File
    inputBinding:
      prefix: -input-jobs
  gcode_othmito:
    type: string?
    default: /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/tRNAscan-SE/1.21-patched-4/lib/tRNAscan-SE/gcode.othmito
    inputBinding:
      prefix: -g
  binary:
    type: string?
    default: /panfs/pan1.be-md.ncbi.nlm.nih.gov/gpipe/ThirdParty/tRNAscan-SE/1.21-patched-4/arch/x86_64/bin/tRNAscan-SE
    inputBinding:
      prefix: -tRNAscan
  taxid:
    type: int
    inputBinding:
      prefix: -taxid
  output_dir:
    type: string?
    default: output
    inputBinding:
      prefix: -O
outputs:
  # asncache:
  #   type: Directory
  #   outputBinding:
  #     glob: $(inputs.asn_cache.basename)
  outdir:
    type: Directory
    outputBinding:
      glob: $(inputs.output_dir)
  
  