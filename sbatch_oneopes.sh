#!/bin/bash
#SBATCH --job-name=jobname
#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --gpus=4
#SBATCH --ntasks=8
#SBATCH --cpus-per-task 32
#SBATCH --account=s1274
#SBATCH --hint=nomultithread
#SBATCH --uenv=gromacs/2024:v1
#SBATCH --view=develop

# sourcing of GROMACS, PLUMED, and the wrapper location
# change youruser to you
source "/users/youruser/programs/plumed-2.9.1/sourceme.sh"
source "/users/youruser/programs/gromacs-2023/install/bin/GMXRC"
wrapper="/users/youruser/programs/mps-wrapper.sh"

# Grace-Hopper MPI-aware GPU, do not touch
export MPICH_GPU_SUPPORT_ENABLED=1
export FI_CXI_RX_MATCH_MODE=software
export GMX_GPU_DD_COMMS=true
export GMX_GPU_PME_PP_COMMS=true
export GMX_FORCE_UPDATE_DEFAULT_GPU=true
export GMX_ENABLE_DIRECT_GPU_COMM=1
export GMX_FORCE_GPU_AWARE_MPI=1

# GROMACS stuff
srun -n 8 ${wrapper} -- gmx_mpi mdrun -pin on -ntomp 32 -multidir dir1 dir2 dir3 dir4 dir5 dir6 dir7 [...]
exit;
