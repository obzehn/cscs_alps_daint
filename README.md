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
