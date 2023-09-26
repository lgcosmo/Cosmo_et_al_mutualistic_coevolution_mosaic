#This script runs the numerical simulations that return the results used to build Figures 2 to 4c of the manuscript

#The function coevo_metacom take as input several parameters and return a dataframe containing the variables used in the main text
#The model parameters are:
#n_sp - Initial species richness of the metacommunity
#climchange  - Amount of directional climate change at each time step
#change_type - "directional" is the only option for now
#prop_hot - Proportion of hotspots in the metacommunity
#α - Sensitivity to trait matching of mutualistic coevolution
#ρ - Sensitivity of species adaptive landscape/suitability to changes in trait values
#σ - Additive genetic variance
#flow - Total fraction of gene flow that each patch can receive from neighbours
#tmax - Maximum simulation time
#sim - Variable to identify the simulation

#Loading initial packages
using Distributed
using DrWatson
#Setting up number of parallel processor threads for simulations
addprocs(12)
#Loading required packages within each thread
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using DrWatson
@everywhere @quickactivate "coevomut_mosaic"

@everywhere begin

    using CSV
    using Distributions
    using DataFrames
    using Statistics
    using LinearAlgebra
    using Random
    using RCall

    include(srcdir("main_functions_mosaic_space.jl"))
    include(srcdir("aux_functions.jl"))

    G=moore_neighborhood(n_patches=100, n=10, periodic=true) #Creating transition matrix for dispersal

    hot_settings=[0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]

    par_dict1=Dict(:n_sp=>32,:prop_hot=>hot_settings,:G=>G,:climchange=>0.0, :change_type=>"directional", :α=>0.1,:ρ=>0.1, :σ=>1.0, :flow=>0.05,:tmax=>1000, :nsim=>100)
    p_list1=dict_list(par_dict1)

    par_dict2=Dict(:n_sp=>32,:prop_hot=>hot_settings,:G=>G,:climchange=>0.25, :change_type=>"directional", :α=>0.1,:ρ=>0.1, :σ=>1.0, :flow=>0.05,:tmax=>1000, :nsim=>100)
    p_list2=dict_list(par_dict2)

end
#Running simulations
pmap(coevo_metacom_multisim, p_list1)
pmap(coevo_metacom_multisim, p_list2)