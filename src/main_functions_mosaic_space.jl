#------------#
#-Migrations-#
#------------#

function migrate!(;z::AbstractArray, θ::AbstractArray, G::AbstractArray, sp_type::AbstractArray, snet::AbstractArray, mig::AbstractArray, migs::AbstractArray, mig_attempts::AbstractArray, mig_success::AbstractArray, flow::Float64, ρ::Float64, mi::Array{Float64}, time::Int)

    #Perform migrations, modify the array z at time t and return the ratio of migrations success/attempts

    fill!(mig, 0.0) #Resetting migrations
    fill!(migs, 0.0)

    @inbounds for s in 1:size(z,2) #Loop through all s species
        @inbounds for i in 1:size(z,1) #Loop through all i sites of species s

            if z[i,s,time]==0.0 #Skip iteration if there is no population of species s at site i
                continue
            end

            @inbounds for j in 1:size(G,2) #Loop through all sites j that can receive migrations from i
                if G[i,j]==0.0 #If site j cannot receive migration from i, skip iteration
                    continue
                end

                ksum=0.0 #Sum of potential mutualistic species that habit site j
                tm=0.0 #Variable to store cumulative trait matching with all mutualistic species that habit site j

                @inbounds for k in 1:size(z,2) #Loop through all other k species that may be at site j

                    if (k==s) || (z[j,k,time]==0.0) || sp_type[k]==sp_type[s] #Skip iteration if k=s, i.e. intraspecific interaction, or if there is no population of species k at site j
                        continue
                    end
        
                    tm=tm+(z[j,k,time]-z[i,s,time])^2 #Calculating cumulative trait matching of species s at site i with all other k mutualists at site j
                    ksum=ksum+1.0
                end

                meantm=ifelse(ksum>0.0, tm/ksum, 0.0)
                mut_suit=exp(-ρ*(mi[i]*meantm)) #Mean trait matching of pop i of species s at site j
                env_suit=exp(-ρ*((1.0-mi[i])*((θ[j,s,(time-1)]-z[i,s,time])^2)))
                env_suit2=exp(-ρ*(((θ[j,s,(time-1)]-z[i,s,time])^2))) #Environmental matching of pop i of species s at site j
                migs[i,j,s]=ifelse(meantm == 0.0, env_suit2, mut_suit*env_suit) #Environmental suitability of pop i of species s at site j

                mig_attempts[j,s,time]=mig_attempts[j,s,time]+1.0 #Quantifying attempts of migrations to site j from species s

                if migs[i,j,s] >= rand() #Migration trial

                    mig[i,j,s]=z[i,s,time] #If succesfull, add z value of pop i of species s to migrants to site j
                    snet[j,i,s,time]=1.0
                    mig_success[j,s,time]=mig_success[j,s,time]+1.0 #Updating sucessfull migration

                end
                
                if z[j,s,time]>0.0 && flow>0.0 #If there is already a population of species s at site j
                    mig[i,j,s]=flow*mig[i,j,s] #Population j will only receive a fraction (flow) of population i
                elseif z[j,s,time]>0.0 && flow==0.0
                    mig[i,j,s]=0.0
                end
                
            end
        end
    end

    genflow=dropdims(sum(mig, dims=1), dims=1) #Computing total gene flow to each site (column sums of mig array)
    n_pop=dropdims(sum(x->x>0.0, mig, dims=1), dims=1) #Computing total number of migrant populations to each site

    if flow==0.0

        for s in 1:size(genflow, 2)
            for j in 1:size(genflow, 1)
               
                if n_pop[j,s]>1.0
                    
                    @views id=findmax(migs[:,j,s])[2]
                    #@views id=findall(x->x>0.0, migs[:,j,s])
                    #id=sample(id)

                    genflow[j,s]=z[id,s,time]
                end
            end
        end
    end

    
    @inbounds for s in 1:size(z,2) #Loop to update trait values after migration
        @inbounds for i in 1:size(z,1)

            if genflow[i,s]>0.0 #Update trait value if migration occurred

                z[i,s,time]=ifelse(z[i,s,time]>0.0, (1.0-flow)*z[i,s,time] + genflow[i,s]/n_pop[i,s], genflow[i,s]/n_pop[i,s])

            else

                z[i,s,time]=ifelse(z[i,s,time]>0.0, z[i,s,time], genflow[i,s])
                
            end
        end
    end

    #return(success/attempts)

end

#-------------#
#-Extinctions-#
#-------------#

function extinct!(;z::AbstractArray, ST::AbstractArray, ext_attempts::AbstractArray, ext_success::AbstractArray, time::Int)
    
    #Perform extinctions, modify the array z at time t and return the fraction of active populations that became extinct

    
    @inbounds for i in 1:size(z,2) #Loop through each i species
        @inbounds for k in 1:size(z,1) #Loop through each population of species i at site k

            if z[k,i,time]==0.0 #Skip iteration if there is no population of species i at site k
                continue
            end

            ext_attempts[k,i,time]=ext_attempts[k,i,time]+1.0 #Extinction attempt

            if (ST[k,i,time]) <= rand() #Population become extinct if trial is succesfull
                z[k,i,time]=0.0 #Setting population as extinct
                ext_success[k,i,time]=ext_success[k,i,time]+1.0 #If extinction sucesfull, add 1 to extinctions
            end

        end
    end

end

#--------------------------#
#-Networks of interactions-#
#--------------------------#

function interactions!(;z::Array{Float64}, sp_type::Array{String}, A::Array{Float64}, rich_p::Array{Float64}, rich_a::Array{Float64}, α::Float64, time::Int)
    
    fill!(A, 0.0) #Resetting interactions
    @views fill!(rich_p[time,:], 0.0)
    @views fill!(rich_a[time,:], 0.0)

    @inbounds for k in 1:size(z,1) #Loop through each k site
        @inbounds for i in 1:size(z,2) #Loop through each i species

            if z[k,i,time]==0.0 #If there is no population of species i at site k, skip iteration
                continue
            end

            if sp_type[i]=="p"
                rich_p[time,k]=rich_p[time,k]+1.0
            end

            if sp_type[i]=="a"
                rich_a[time,k]=rich_a[time,k]+1.0
            end

            @inbounds for j in 1:size(z,2) #Loop through all potential j partners of species i at site k

                if (i==j) || (z[k,j,time]==0.0) || sp_type[i]==sp_type[j] #Avoid intraspecific interactions, interactions of species of the same set, no populations of species j
                    continue
                end
                
                intprob=(exp(-α*(z[k,j,time]-z[k,i,time])^2))/2.0 #Probability of interaction with j and i at site k, proportional to trait matching
                                
                if intprob >= rand() #Interaction trial
                    A[i,j,k]=1.0
                end

                if A[i,j,k]==1.0 #If species i interact with j, force j to interact with i (symmetric interactions)
                    A[j,i,k]=1.0
                end

            end
        end    
            
    end

end

#---------------------------#
#-Evolution and coevolution-#
#---------------------------#

function evolve!(;z::Array{Float64}, A::Array{Float64}, Q::Array{Float64}, θ::Array{Float64}, mi::Array{Float64}, α::Float64, ρ::Float64, σ::Float64, time::Int)

    fill!(Q, 0.0) #Resetting Q-matrix

    @inbounds for k in 1:size(z,1)
        @inbounds for i in 1:size(z,2)
            
            if z[k,i,time]==0.0
                continue
            end

            @inbounds for j in 1:size(z,2)

                if (i==j) || (z[k,j,time]==0.0) || (A[i,j,k]==0.0)
                    continue
                end

                Q[i,j,k]=exp(-α*(z[k,j,time]-z[k,i,time])^2)

            end
        end
    end

    Q_sum=dropdims(sum(Q, dims=2), dims=2)
    
    @inbounds for k in 1:size(Q,3)
        @inbounds for j in 1:size(Q,2)
            @inbounds for i in 1:size(Q,1)
                Q[i,j,k]=ifelse(Q_sum[i,k]>0.0, Q[i,j,k]/Q_sum[i,k], 0.0)
                Q[i,j,k]=Q[i,j,k]*(z[k,j,time]-z[k,i,time])
            end
        end
    end

    mut=permutedims(dropdims(sum(Q, dims=2), dims=2), (2,1)) #Summing rows of matrix Q and transposing to be at the same order as z array

    @inbounds for i in 1:size(z,2)
        @inbounds for k in 1:size(z,1)

            if z[k,i,time]==0.0
                continue
            end

            z[k,i,(time+1)] = ifelse(mut[k,i]>0.0, z[k,i,time] + σ*ρ*(mi[k]*mut[k,i] + (1.0-mi[k])*(θ[k,i,time]-z[k,i,time])), z[k,i,time] + σ*ρ*(θ[k,i,time]-z[k,i,time]))
        end
    end
end

#---------------------------------------#
#-Initial populations and traits values-#
#---------------------------------------#

function init_pop!(;z::AbstractArray, time::Int)

    area=trunc(Int, sqrt(size(z,1)))

    @inbounds for i in 1:size(z,2)

        id=sample(1:size(z,1), area , replace=false)

        z[id,i,time].=rand(0.01:0.01:10.0, length(id))

    end
    
end

function random_z!(;z::AbstractArray, time::Int)

    @inbounds for i in 1:size(z,2)
        @inbounds for k in 1:size(z,1)

            if z[k,i,time] != 0.0
                z[k,i,time+1]=rand(0.01:0.01:10.0)
            end
        end
    end
end

#--------------------------------------#
#-Initial theta values for all patches-#
#--------------------------------------#

function theta_init!(;θ)
    theta_init=rand(0.01:0.01:10.0, size(θ,1), size(θ,2))
    @inbounds for t in 1:size(θ,3)
        @views θ[:,:,t].=theta_init
    end
end

#----------------#
#-Climate change-#
#----------------#

function clim_change!(;θ::AbstractArray, change::Float64, change_type::String, time::Int64)

    if change_type=="directional"

        @inbounds for j in 1:size(θ, 2)
            @inbounds for i in 1:size(θ, 1)
                θ[i,j,(time+1)]=θ[i,j,time]+change
            end
        end
    end

    if change_type=="periodic"
        @inbounds for j in 1:size(θ, 2)
            @inbounds for i in 1:size(θ, 1)
                θ[i,j,(time+1)]=θ[i,j,1]+(change*sin(0.05*(time+1)))
            end
        end
    end

end

#-------------------------------------#
#-Suitability and Mean trait matching-#
#-------------------------------------#

function suitability!(;z::Array{Float64}, θ::Array{Float64}, ST::Array{Float64}, A::Array{Float64}, ρ::Float64, mi::Array{Float64}, time::Int)

    if time>1
        time_θ=time-1
    else
        time_θ=time
    end

    @inbounds for k in 1:size(z,1) #Loop through each k site
        @inbounds for i in 1:size(z,2) #Loop through each species i at site k

            if z[k,i,time]==0.0 #Skip iteration if there is no population of species i at site k and set TM and ST as 0
                ST[k,i,time]=0.0
                continue
            end

            tm=0.0 #Quantifying cumulative trait matching
            jsum=0.0 #Quantifying number of interacting partners

            @inbounds for j in 1:size(z,2) #Loop through all j possible partners at site k
                if (i==j) || (z[k,j,time]==0.0) || (A[i,j,k]==0.0) #Skip intraspecific interactions, non-interacting species and absent of populations of j species
                    continue
                end

                tm=(z[k,j,time]-z[k,i,time])^2 #Calculating cumulative trait matching of species i at site k with all other j mutualists at site j
                jsum=jsum+1.0
            end

            meantm=ifelse(jsum>0.0, tm/jsum, 0.0)
            mut_suit=exp(-ρ*(mi[k]*meantm))
            env_suit=exp(-ρ*((1.0-mi[k])*((θ[k,i,time_θ]-z[k,i,time])^2)))
            env_suit2=exp(-ρ*(((θ[k,i,time_θ]-z[k,i,time])^2))) #Environmental matching of pop k of species i at site k
            ST[k,i,time]=ifelse(meantm == 0.0, env_suit2, mut_suit*env_suit) #Suitability
            
        end
    end
end

#---------------#
#-Main function-#
#---------------#

function coevo_metacom(;n_sp::Int, G::Array{Float64}, climchange::Float64, change_type::String, prop_hot::Float64, α::Float64, ρ::Float64, σ::Float64, flow::Float64, tmax::Int, sim::Int)
    
    #Initializing model

    n_hot=floor(Int, size(G,1)*prop_hot)
    n_cold=size(G,1)-n_hot
    m_val=vcat(rand(0.0:0.01:0.3, n_cold), rand(0.7:0.01:1.0, n_hot))
    mi=shuffle(m_val)

    if prop_hot == 0.0
        mi=rand(0.0:0.01:0.3, size(G,1))
    end

    n_p=Int(n_sp/2)
    n_a=Int(n_sp/2)
    sp_type=vcat(repeat(["p"], n_p), repeat(["a"], n_a))
    z=zeros(size(G,1), n_sp, tmax)
    ST=zeros(size(G,1), n_sp, tmax)
    A=zeros(size(z,2), size(z,2), size(z,1))
    Q=zeros(size(z,2), size(z,2), size(z,1))
    M=zeros(size(G,1), size(G,2), size(z,2))
    MS=zeros(size(G,1), size(G,2), size(z,2))
    S=zeros(size(G,1), size(G,2), size(z,2), tmax)
    theta=zeros(size(G,1), n_sp, tmax)
    ext_attempts=zeros(size(G,1), n_sp, tmax)
    ext_success=zeros(size(G,1), n_sp, tmax)
    mig_attempts=zeros(size(G,1), n_sp, tmax)
    mig_success=zeros(size(G,1), n_sp, tmax)
    rich_p=zeros(tmax, size(G,1))
    rich_a=zeros(tmax, size(G,1))

    theta_init!(θ=theta)
    init_pop!(z=z, time=1)
    interactions!(z=z, sp_type=sp_type, A=A, rich_p=rich_p, rich_a=rich_a, α=α, time=1)
    suitability!(z=z, θ=theta, ST=ST, A=A, ρ=ρ, mi=mi, time=1)

    for t in 1:(tmax-1)

        evolve!(z=z, A=A, Q=Q, θ=theta, α=α, mi=mi, ρ=ρ, σ=σ, time=t) #Evolution and coevolution
        migrate!(z=z, G=G, θ=theta, sp_type=sp_type, snet=S, mig=M, migs=MS, mig_attempts=mig_attempts, mig_success=mig_success, ρ=ρ, flow=flow, mi=mi, time=t+1) #Migrations
        interactions!(z=z, sp_type=sp_type, A=A, rich_p=rich_p, rich_a=rich_a, α=α, time=t+1) #Recalculating interactions after migrations
        suitability!(z=z, θ=theta, ST=ST, A=A, ρ=ρ, mi=mi, time=t+1) #Calculating suitability after migrations
        extinct!(z=z, ST=ST, ext_attempts=ext_attempts, ext_success=ext_success, time=t+1) #Extinctions
        interactions!(z=z, sp_type=sp_type, A=A, rich_p=rich_p, rich_a=rich_a, α=α, time=t+1) #Recalculating interactions after extinctions

        if climchange>0.0

            @views if all(x-> x==0.0, z[:,:,t])
                break
            end
        end

        clim_change!(θ=theta, change=climchange, change_type=change_type, time=t)

    end

    mi_class=[v>0.5 ? "h" : "c" for v in mi]

    ext_ratio=dropdims(sum(ext_success, dims=2), dims=2)./dropdims(sum(ext_attempts, dims=2), dims=2)
    ext_ratio=permutedims(ext_ratio, (2,1))
    mig_ratio=dropdims(sum(mig_success, dims=2), dims=2)./dropdims(sum(mig_attempts, dims=2), dims=2)
    mig_ratio=permutedims(mig_ratio, (2,1))

    ext_ratio=stack(DataFrame(ext_ratio, :auto))
    mig_ratio=stack(DataFrame(mig_ratio, :auto))

    results=DataFrame(rich_p, :auto)
    rich_animals=stack(DataFrame(rich_a, :auto))

    S2=dropdims(mean(S[:,:,:,(tmax-100):tmax], dims=4), dims=4)
    S3=dropdims(mean(S2, dims=3), dims=3)

    site_indegree=dropdims(sum(S3, dims=2), dims=2)
    site_outdegree=dropdims(sum(S3, dims=1), dims=1)
    total_degree=dropdims(sum(G, dims=2), dims=2)

    rename!(results, [(Symbol("x$i")=>Symbol("S$i")) for i in 1:size(G,1)])
    results[!, :time]=1:tmax
    results=stack(results)
    select!(results, [:time, :variable, :value])
    rename!(results, :variable=>:site,:value=>:rich_plants)
    results[!, :rich_animals]=rich_animals.value
    results[!, :ext_ratio]=ext_ratio.value
    results[!, :mig_ratio]=mig_ratio.value
    results[!,:indegree]=repeat(site_indegree, inner=tmax)
    results[!,:outdegree]=repeat(site_outdegree, inner=tmax)
    results[!,:total_degree]=repeat(total_degree, inner=tmax)
    results[!,:mi]=repeat(mi, inner=tmax)
    results[!,:mi_class]=repeat(mi_class, inner=tmax)

    @. results[!,:n_sp]=n_sp
    @. results[!,:n_a]=n_a
    @. results[!,:n_p]=n_p
    @. results[!,:flow]=flow
    @. results[!,:alpha]=α
    @. results[!,:gvar]=σ
    @. results[!,:rho]=ρ
    @. results[!,:prop_hot]=prop_hot
    @. results[!,:climchange]=climchange
    @. results[!,:change_type]=change_type
    @. results[!,:simulation]=sim

    subset!(results, :time => x -> x .>= 900)
    return(results)

end

function coevo_metacom_multisim(p)

    @unpack n_sp,prop_hot,G,climchange,change_type,α,ρ,σ,flow,tmax,nsim=p

    results_list=[DataFrame() for _ in 1:nsim]

    for n in 1:nsim
        results_list[n]=coevo_metacom(n_sp=n_sp, prop_hot=prop_hot, G=G, climchange=climchange, change_type=change_type, α=α, ρ=ρ, σ=σ, flow=flow, tmax=tmax, sim=n)
    end

    CSV.write(datadir("sims", "rich=$(n_sp)_clim=$(climchange)_type=$(change_type)_phot=$(prop_hot)_flow=$(flow)_a=$(α)_rho=$(ρ)_varg=$(σ).csv"), vcat(results_list...))

end