# How-to for GROMACS/PLUMED installation and submission on CSCS Alps Daint
This is a short summary to compile your own GROMACS version on [CSCS Alps](https://www.cscs.ch/computers/alps). We will (hopefully) get access to the pool of ca. 2700 [NVIDIA Grace-Hopper](https://www.nvidia.com/en-us/data-center/grace-hopper-superchip/) (GH) nodes on Daint. Each GH chipset has 72 cores, 128GB RAM, and a H100 GPU with 96GB of memory. Keep in mind that these are massive nodes, as each one has four GH chipsets, in contrast to Piz-Daint, which feautured small nodes and good internode scaling. This has a few consequences
1. We cant (as for now) require just a fraction of a node. You have to require a full one, even if you plan to run only on one of the chipsets, and consequently will burn the full computational time you require even if you use only part of the machine.
2. The amount of cores and the GPU are overpowered for most unbiased MD simulations of small (<100k atoms) systems. It is very likely that in these cases the scaling is negative, with performance decreasing the moment you split the job on more than one chipset. For small sized jobs, or jobs with only one replica, baobab is still the best option.
3. As far as what we do now, it is highly unlikely that we will ever scale beyond one node, as the GH chipsets are so powerful that internode communication becomes a serius bottleneck. As such, countrary to Piz-Daint, most of our jobs here will be only single-node jobs.
Regarding our common types of simulations, the main take at home messages are
1. For standard OneOpes with 8 replicas and ca. 100/200k atoms boxes, a node is a good compromise and should outperform Baobab (at least in terms of stability). You can easily put two replicas per GH chipset, effectively giving half a GPU and 32 cores to each replica. More on this later on.
2. For small OneOpes runs (e.g. folding), Baobab will be a better choice, as the systems are so small that you can’t really benefit from GH chipsets. It might be that running all eight replicas on the same chipset might be the best choice, but this will leave three-quaters of the node empty. More testing on this in the future probably will be required if needed.
3. For unbiased simulations, test a few configurations and see how the system scales. Most likely, the best choice will be to run in parallel two or four simulations (2 GPUs or 1 GPU per sim, respectively) by using the multidir flag, but without exchanges. Also more on this later on.

It is likely that in the future we will compile a shared version of GROMACS and PLUMED for everyone to source. For the time being, if you need Daint you will likely need to compile your GROMACS and PLUMED versions. First, login to Daint (more info [here](https://confluence.cscs.ch/display/KB/Daint), for standard ssh you still jump through ela, the new address is daint.alps.cscs.ch). With respect to Piz-Daint and Baobab, here there is not the module load syntax anymore, but they use [`uenv`](https://confluence.cscs.ch/display/KB/uenv+user+environments) to set up the user environment. Basically, you have to create a container that holds your environments, check which environments are available, and pull the one you need. This needs to be done only once, then the environment remains available without having to pull it again. To create the container and pull GROMACS environment just run
```
uenv repo create
uenv image pull gromacs/2024:v1
```
The `gromacs/2024:v1` environment contains different *views*, basically a different flavour of the environment itself. In this case the GROMACS environment has three flavours
1. **--view=gromacs** loads an installation of GROMACS 2024.1
2. **--view=plumed** loads an installation of GROMACS 2022.5 patched with PLUMED 2.9.0
3. **--view=develop** loads the packages needed to install GROMACS related stuff (CUDA etc.) without loading any specific GROMACS.

A few details are outlined in the [uenv gromacs](https://eth-cscs.github.io/alps-uenv/uenv-gromacs/) page from CSCS, and [here](https://confluence.cscs.ch/display/KB/GROMACS).
To compile GROMACS it is better if we `salloc` to a debug node, so we don't cram the head node with our processes (and get kicked out), with the following
```
salloc --nodes=1 -t 00:30:00 --partition=debug
```
The `--partition=debig` gives us a maximum of half an hour to do things. More than sufficient to compile. Now, activate the develop view
```
uenv start gromacs/2024:v1 --view=develop
```
Notice that this is opening some kind of subshell. If you type exit you won’t exit the node but first only the environment in which you entered. The environment has its own shell with no memory of where you were before, the commands, the aliases, etc. Not the best, but for now that’s how it is.
At this point, while within the develop environment, you can install the GROMACS and/or PLUMED versions that you want. Here are the commands to get PLUMED 2.9.1 alongside GROMACS 2023.0 in `programs` directory in your home.
```
cd ~
mkdir programs
cd programs
wget https://github.com/plumed/plumed2/releases/download/v2.9.1/plumed-2.9.1.tgz
tar -xf plumed-2.9.1.tgz
cd plumed-2.9.1
mv ../plumed-2.9.1.tgz/ ./
./configure --enable-modules=all
make -j32
source sourceme.sh
cd ..
```
PLUMED should compile with MPI active. Then download and patch GROMACS 2023
```
wget https://ftp.gromacs.org/gromacs/gromacs-2023.tar.gz
tar -xf gromacs-2023.tar.gz
cd gromacs-2023
mv ../gromacs-2023.tar.gz/ ./
plumed patch -p
```
Select the GROMACS 2023 patch when prompted by PLUMED and install GROMACS
```
mkdir build_mpi install_mpi
cd build_mpi
cmake .. -DGMX_BUILD_OWN_FFTW=NO -DREGRESSIONTEST_DOWNLOAD=NO -DGMX_GPU=CUDA -DGMX_MPI=ON -DCMAKE_INSTALL_PREFIX=../install_mpi/ -DGMX_SIMD=ARM_NEON_ASIMD -DGMX_HWLOC=ON -DCMAKE_C_COMPILER=/user-environment/linux-sles15-neoverse_v2/gcc-12.3.0/gcc-12.3.0-yfdpfoi7qo4e7ub4l4isthtcfevf4zee/bin/gcc -DCMAKE_CXX_COMPILER=/user-environment/linux-sles15-neoverse_v2/gcc-12.3.0/gcc-12.3.0-yfdpfoi7qo4e7ub4l4isthtcfevf4zee/bin/g++
make -j32
make install
```
Note that C and C++ compiler are specified by hand because the environment fails to solve them alone. In case the compilation dies because the C/C++ compilators are not found, just provide those listed by
```
which gcc
which g++
```
to `-DCMAKE_C_COMPILER` and `-DCMAKE_CXX_COMPILER`, respectively.
At this point you should have a working GROMACS2023 patched with PLUMED2.9.1 installation, you can exit the environment and the debug node. These installations are now linked to the develop environment, so before sourcing their binaries we have to get into the GROMACS develop uenv.
The sbatch script to submit jobs is similar to that for Baobab/Piz-Daint but has a few more mandatory keywords. The max time is still capped at 24h. Consider also that you must i) define the environment that you need in the sbatch file or ii) submit the sbatch file from within the environment you intend to use. In general it is better to define the environment and its view in the sbatch file so to avoid mistakes and failed jobs. There are also other two details that are important
1. Despite the GH chipsets having 72 core each, the CSCS people [say](https://confluence.cscs.ch/display/KB/GROMACS#GROMACS-HowtoRun) that one should use max 64 of them or let some cores free to handle other background processes within the node. So, don’t require more than 64 cores per GH chipset.
2. One has to force CUDA-MPI aware parallelization within the node. This is achieved with a few lines in the sbatch file AND by adding a wrapper each time we call srun to run a job. One way to do this is to save a copy of the wrapper in a directory in your home folder alongside the other programs (`~/programs/mps-wrapper.sh`) and point at it in the sbatch file rather than copy-paste the wrapper in a new directory everytime I have to run a simulation, but you do you.

You can download a copy of the wrapper from [here](https://confluence.cscs.ch/display/KB/Oversubscription+of+GPU+cards#OversubscriptionofGPUcards-WrapperScript) or [here](https://eth-cscs.github.io/alps-uenv/uenv-gromacs/) or copy paste what I report here (hopefully this won't need updates, but in case it is not working visit the links for the official CSCS versions). Just create a file
```
touch ~/programs/mps-wrapper.sh
```
and paste inside this
```
#!/bin/bash
# Example mps-wrapper.sh usage:
# > srun [...] mps-wrapper.sh -- <cmd>

TEMP=$(getopt -o '' -- "$@")
eval set -- "$TEMP"

# Now go through all the options
while true; do
    case "$1" in
        --)
            shift
            break
            ;;
        *)
            echo "Internal error! $1"
            exit 1
            ;;
    esac
done

set -u

export CUDA_MPS_PIPE_DIRECTORY=/tmp/nvidia-mps
export CUDA_MPS_LOG_DIRECTORY=/tmp/nvidia-log
# Launch MPS from a single rank per node
if [ $SLURM_LOCALID -eq 0 ]; then
    CUDA_VISIBLE_DEVICES=0,1,2,3 nvidia-cuda-mps-control -d
fi
# Wait for MPS to start sleep 5
sleep 5

exec "$@"
```
Once you have it, remember to make it executable with
```
chmod +x mps-wrapper.sh
```
Here is an example of a sbatch file for a OneOpes run (just fix the sources and the wrapper position depending on your set-up)
```
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
source "/users/youruser/programs/gromacs-2023/install_mpi/bin/GMXRC"
wrapper="/users/youruser/programs/mps-wrapper.sh"
# Grace-Hopper MPI-aware GPU, do not touch
export MPICH_GPU_SUPPORT_ENABLED=1
export FI_CXI_RX_MATCH_MODE=software
export GMX_GPU_DD_COMMS=true
export GMX_GPU_PME_PP_COMMS=true
export GMX_FORCE_UPDATE_DEFAULT_GPU=true
export GMX_ENABLE_DIRECT_GPU_COMM=1
export GMX_FORCE_GPU_AWARE_MPI=1
srun -n 8 ${wrapper} -- gmx_mpi mdrun -pin on -ntomp 32 [...]
exit;
```
I am requiring a full node, 4 GPUs (all of them), 8 tasks (the 8 MPIs, one per replica in OneOpes) and I give 32 cores per replica (so that I have 64 per node, the max permitted). You can fine tune this, it might be that other combinations and repartitions of CPUs work well.
For an unbiased simulation, given the power of the GH nodes, using more than one chipset might be not optimal or just plain bad, if your system is not huge (> 1mln atoms), as the parallel efficiency decreases due to the presence of too many resources and the inter-chip communication. However, if you have more than one independent replica, you can run all of them in parallel. For example, with ca. 200k atoms in terms of total output of the node it is way better to run 4 independent replicas – one per chipset – rather than using a whole node for a system. In this case, a possible sbatch script is the following
```
#!/bin/bash
#SBATCH --job-name=jobname
#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --gpus=4
#SBATCH --ntasks=4
#SBATCH --cpus-per-task 64
#SBATCH --account=s1274
#SBATCH --hint=nomultithread
#SBATCH --uenv=gromacs/2024:v1
#SBATCH --view=develop
# sourcing of GROMACS, PLUMED, and the wrapper location
# change youruser to you
source "/users/youruser/programs/plumed-2.9.1/sourceme.sh"
source "/users/youruser/programs/gromacs-2023/install_mpi/bin/GMXRC"
wrapper="/users/youruser/programs/mps-wrapper.sh"
# Grace-Hopper MPI-aware GPU, do not touch
export MPICH_GPU_SUPPORT_ENABLED=1
export FI_CXI_RX_MATCH_MODE=software
export GMX_GPU_DD_COMMS=true
export GMX_GPU_PME_PP_COMMS=true
export GMX_FORCE_UPDATE_DEFAULT_GPU=true
export GMX_ENABLE_DIRECT_GPU_COMM=1
export GMX_FORCE_GPU_AWARE_MPI=1
srun -n 4 ${wrapper} -- gmx_mpi mdrun -pin on -ntomp 64 [...] -multidir
dir1 dir2 dir3 dir4
exit;
```
where the `-multidir` flag points at the different replica directories and there is no -hrex flag, so the replicas are not exchanging and are independent. In this way the whole node is used and you optimize the output for replicas of unbiased runs. There is further space for optimization, e.g. with
```
#SBATCH --gpus=4
#SBATCH --ntasks=8
#SBATCH --cpus-per-task 32
srun -n 8 ${wrapper} -- gmx_mpi mdrun -pin on -ntomp 32 -npme 1 [...] -multidir dir1 dir2 dir3 dir4
```
you should be able to run the same four simulations but with 2MPI processes per replica and 32OMP per process. This might work better but it is system dependent. Similarly, if the systems are large (>500k atoms), you might try to split one system on two GPUs and run two replicas per node. Given that the simulation time is quite limited, it is better to invest half an hour to fine tune the parameters of your sbatch file. You can do this “for free” if you request to run on the debug queue with the additional
```
#SBATCH --partition=debug
```
Here you can run only one job at a time for max 30min, but generally there is no waiting time and it should not count towards your total simulation time usage. Just test a few combinations of GPUs/MPI/OMP for your replicas on the debug queue and then submit to the normal queue (just take away the line specifying the debug partition).
