# cscs_alps_daint
How-to for GROMACS/PLUMED installation and submission on CSCS Alps Daint
This is a short summary to compile your own GROMACS version on CSCS Alps. We will (hopefully) get access to the pool of ca. 2700 NVIDIA Grace-Hopper (GH) nodes on Daint. Each GH chipset has 72 cores, 128GB RAM, and a H100 GPU with 96GB of memory. Keep in mind that these are massive nodes, as each one has four GH chipsets, in contrast to Piz-Daint, which feautured small nodes and good internode scaling. This has a few consequences
