#!/bin/bash

# RAREsim2 Complete Workflow Example
# This script demonstrates a full research pipeline for simulating rare variant data
# with stratified pruning (functional vs synonymous variants) and multiple scenarios.

# Simulation parameters
pop=NFE           # Population (NFE = Non-Finnish European)
nsim=10000        # Sample size for simulation
pcase=120         # Percentage of functional variants to keep (120%)
rep=3             # Random seed for reproducibility
ncase=5000        # Sample size for case/control extraction

# Set working directory to the parent data directory
# You can override this by passing a directory as the first argument
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${1:-$(dirname "$SCRIPT_DIR")/data}"

# Step 1: Create MAC bin estimates using target data stratified by functional status
# This calculates expected variants per MAC bin with 120% functional variants
python3 -m raresim calc \
    --mac ${DATA_DIR}/mac_bins.txt \
    -o MAC_bin_estimates_${nsim}_${pop}_${pcase}.txt \
    -N $nsim \
    --nvar_target_data ${DATA_DIR}/nvar_target.txt \
    --afs_target_data ${DATA_DIR}/afs_target.txt \
    --w_fun 1.2 \
    --w_syn 1.2 \
    --reg_size 19.029

# Calculate MAC bin estimates with 100% of variants (baseline)
python3 -m raresim calc \
    --mac ${DATA_DIR}/mac_bins.txt \
    -o MAC_bin_estimates_${nsim}_${pop}_100.txt \
    -N $nsim \
    --nvar_target_data ${DATA_DIR}/nvar_target.txt \
    --afs_target_data ${DATA_DIR}/afs_target.txt \
    --reg_size 19.029

# Step 2: Extract nsim individuals from the initial haplotype file
python3 -m raresim extract \
    -i ${DATA_DIR}/haplotypes.haps.gz \
    -o haplotypes_${nsim}.haps.gz \
    -n $((2*$nsim)) \
    --seed $rep

# Step 3: Prune functional and synonymous variants down to pcase% functional / 100% synonymous
# Remove rows of zeros using the -z flag
python3 -m raresim sim \
    -m haplotypes_${nsim}.haps-sample.gz \
    --functional_bins MAC_bin_estimates_${nsim}_${pop}_${pcase}_fun.txt \
    --synonymous_bins MAC_bin_estimates_${nsim}_${pop}_100_syn.txt \
    --stop_threshold 5 \
    -l ${DATA_DIR}/legend.legend \
    -L sim_${nsim}_${pcase}fun_100syn.legend \
    -H sim_${nsim}_${pcase}fun_100syn.haps.gz \
    -z


# Step 4: Extract power cases for the same direction of effect scenario
python3 -m raresim extract \
    -i sim_${nsim}_${pcase}fun_100syn.haps.gz \
    -o power_cases_same_${ncase}.haps.gz \
    -n $((2*$ncase)) \
    --seed $rep

# Step 5: Prune functional variants down to 100% in the entire sample (without -z flag)
# This creates a pruned-variants file that we'll use to mark protected variants
python3 -m raresim sim \
    -m sim_${nsim}_${pcase}fun_100syn.haps.gz \
    --f_only MAC_bin_estimates_${nsim}_${pop}_100_fun.txt \
    --stop_threshold 5 \
    -l sim_${nsim}_${pcase}fun_100syn.legend \
    -L sim_${nsim}_100fun_100syn_noz.legend \
    -H sim_${nsim}_100fun_100syn_noz.haps.gz

# Step 6: Prune functional variants down to 100% with -z flag (removes zero rows)
python3 -m raresim sim \
    -m sim_${nsim}_${pcase}fun_100syn.haps.gz \
    --f_only MAC_bin_estimates_${nsim}_${pop}_100_fun.txt \
    --stop_threshold 5 \
    -l sim_${nsim}_${pcase}fun_100syn.legend \
    -L sim_${nsim}_100fun_100syn.legend \
    -H sim_${nsim}_100fun_100syn.haps.gz \
    -z

# Step 7: Create protected legend file by marking previously pruned variants
# This adds a "protected" column to prevent re-pruning of already pruned variants
awk -F'\t' -v OFS='\t' 'NR==FNR {if (FNR > 1) ids[$1]=1; next} FNR==1 {print $0, "protected"; next} {print $0, ($1 in ids) ? 1 : 0}' \
sim_${nsim}_100fun_100syn_noz.legend-pruned-variants \
sim_${nsim}_${pcase}fun_100syn.legend > sim_${nsim}_${pcase}fun_100syn_protected.legend 


# Step 8: Extract type I error cases (and power cases for opposite direction scenario)
python3 -m raresim extract \
    -i sim_${nsim}_100fun_100syn.haps.gz \
    -o t1e_cases_${ncase}.haps.gz \
    -n $((2*$ncase)) \
    --seed $rep

# Step 9: Prune functional variants to 100% excluding previously pruned variants (without -z)
# Using --keep_protected to preserve variants marked as protected
# Using --verbose to show detailed pruning information
python3 -m raresim sim \
    -m sim_${nsim}_${pcase}fun_100syn.haps.gz \
    --f_only MAC_bin_estimates_${nsim}_${pop}_100_fun.txt \
    --stop_threshold 5 \
    -l sim_${nsim}_${pcase}fun_100syn_protected.legend \
    -L sim_${nsim}_opp_100fun_100syn_noz.legend \
    -H sim_${nsim}_opp_100fun_100syn_noz.haps.gz \
    --keep_protected \
    --verbose

# Step 10: Same as Step 9 but with -z flag to remove zero rows
python3 -m raresim sim \
    -m sim_${nsim}_${pcase}fun_100syn.haps.gz \
    --f_only MAC_bin_estimates_${nsim}_${pop}_100_fun.txt \
    --stop_threshold 5 \
    -l sim_${nsim}_${pcase}fun_100syn_protected.legend \
    -L sim_${nsim}_opp_100fun_100syn.legend \
    -H sim_${nsim}_opp_100fun_100syn.haps.gz \
    --keep_protected \
    --verbose \
    -z

# Step 11: Extract controls for the opposite direction of effect scenario
python3 -m raresim extract \
    -i sim_${nsim}_opp_100fun_100syn.haps.gz \
    -o controls_opp_${ncase}.haps.gz \
    -n $((2*$ncase)) \
    --seed $rep

# Output files summary:
# - power_cases_same_${ncase}.haps-sample.gz: Power cases for same direction of effect
# - t1e_cases_${ncase}.haps-sample.gz: Type I error cases (and power cases for opposite direction)
# - t1e_cases_${ncase}.haps-remainder.gz: Controls for same direction scenario
# - controls_opp_${ncase}.haps-remainder.gz: Controls for opposite direction scenario
