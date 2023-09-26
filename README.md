# Coevolutionary hotspots favor dispersal and fuel biodiversity in mutualistic landscapes under environmental changes

This README file was generated on 2023-22-09 by Leandro Giacobelli Cosmo

GENERAL INFORMATION

1. Title of Dataset: 

Cosmo_et_al_mutualistic_coevolution_mosaic

2. Author information:

Leandro G. Cosmo: Programa de Pós-Graduação em Ecologia, Departamento de Ecologia, Instituto de Biociências, Universidade de São Paulo - USP, São Paulo, SP, Brazil.

Julia N. Acquaviva: Departamento de Biologia Animal, Instituto de Biologia, Universidade Estadual de Campinas - UNICAMP, Campinas, SP, Brazil.
 
Paulo R. Guimarães Jr.: Departamento de Ecologia, Instituto de Biociências, Universidade de São Paulo - USP, São Paulo, SP, Brazil.

Mathias M. Pires: Departamento de Biologia Animal, Instituto de Biologia, Universidade Estadual de Campinas - UNICAMP, Campinas, SP, Brazil.

Corresponding author: Leandro G. Cosmo, E-Mail: legiacobelli@gmail.com

DATA & FILE OVERVIEW

1. File List: 

Data files:

main_simulation_results.csv

Scripts/Source functions:

main_functions_mosaic_space.jl\
main_functions_mosaic_networks.jl\
aux_functions.jl\
main_simulations_mosaic.jl\
main_simulations_networks.jl

DATA-SPECIFIC INFORMATION:

main_simulation_results.csv: full dataset containing the results of the numerical simulations used for the analyses in the main text.\The variables in the dataset correspond to: 

(1) simulation - ID of the simulation.\
(2) site - ID of the patch.\
(3) mi_class - Classification of the patch as a hotspot (h) or coldspots (c).\
(4) change_type - Type of climate change when present.\
(5) rich_plants - Average richness of plants within the patch (over the last 100 time steps).\
(6) rich_animals - Average richness of animals within the patch (over the last 100 time steps).\
(7) ext_ratio - Average rate of extinction within the patch (over the last 100 time steps).\
(8) mig_ratio - Average rate of colonization and dispersal within the patch (over the last 100 time steps).\
(9) indegree - Average number of colonizing populations within the patch (over the last 100 time steps).\
(10) outegree - Average number of outgoing populations from the patch that succesfull colonized/dispersed ti adjacent patches (over the last 100 time steps).\
(11) total_degree - The maximum theoretical indegree and outdegree of the patch (8 for all paches because of Moore neighborhood).\
(12) mi - Specific m value for the patch (strength of mutualisms as selective pressures).\
(13) n_sp - Number of species in the beginning of the simulation.\
(14) n_a - Number of animal species in the beginning of the simulation.\
(15) n_p - Number of plant species in the beginning of the simulation.\
(16) flow - Fraction of gene flow among populations.\
(17) alpha - Parameter that controls the shape of the trait matching function.\
(18) gvar - Parameter that controls the additive genetic variance.\
(19) rho - Parameter that controls the slope of species adaptive landscape.\
(20) prop_hot - Proportion of hotspots in the metacommunity.\
(21) climchange - Amount of directional climate change in the simulation.

main_functions.jl and aux_functions.jl: Julia functions used to run the model numerical simulations.\
main_simulations_mosaic.jl: script to reproduce the numerical simulations of the model used in the main text (figure 2 to figure 4c).\
main_simulations_network.jl: script to reproduce the numerical simulations and results of figure 4d in the main text.\

USAGE INSTRUCTIONS:

This code base is using the Julia Language and [DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/)
to make a reproducible scientific project named
> Cosmo_et_al_mutualistic_coevolution_mosaic

It is authored by Cosmo et al.

To (locally) reproduce this project, do the following:

0. Download this code base. Notice that raw data are typically not included in the
   git-history and may need to be downloaded independently.
1. Open a Julia console and do:
   ```
   julia> using Pkg
   julia> Pkg.add("DrWatson") # install globally, for using `quickactivate`
   julia> Pkg.activate("path/to/this/project")
   julia> Pkg.instantiate()
   ```

This will install all necessary packages for you to be able to run the scripts and
everything should work out of the box, including correctly finding local paths. 

After installing everything, run the script "model_simulations.jl" located at the "scripts" folder.
