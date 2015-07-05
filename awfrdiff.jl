#########################################################################
#
# rdiff differentiation function
# copy from c:/Users/awf/.julia/v0.4/ReverseDiffSource
#
#########################################################################

#########################################################################
#
#   Expression to graph conversion
#
#########################################################################
#
###########  Parameterized type to ease AST exploration  ############
#  type ExH{H}
#    head::Symbol
#    args::Vector
#    typ::Any
#  end
#  toExH(ex::Expr) = ExH{ex.head}(ex.head, ex.args, ex.typ)
#  toExpr(ex::ExH) = Expr(ex.head, ex.args...)
#
#  typealias ExEqual    ExH{:(=)}
#  typealias ExDColon   ExH{:(::)}
#  typealias ExColon    ExH{:(:)}
#  typealias ExPEqual   ExH{:(+=)}
#  typealias ExMEqual   ExH{:(-=)}
#  typealias ExTEqual   ExH{:(*=)}
#  typealias ExTrans    ExH{symbol("'")}
#  typealias ExCall     ExH{:call}
#  typealias ExBlock    ExH{:block}
#  typealias ExLine     ExH{:line}
#  typealias ExVcat     ExH{:vcat}
#  typealias ExVect     ExH{:vect}
#  typealias ExCell1d   ExH{:cell1d}
#  typealias ExCell     ExH{:cell1d}
#  typealias ExFor      ExH{:for}
#  typealias ExRef      ExH{:ref}
#  typealias ExIf       ExH{:if}
#  typealias ExComp     ExH{:comparison}
#  typealias ExDot      ExH{:.}
#  typealias ExTuple    ExH{:tuple}
#  typealias ExReturn   ExH{:return}
#  typealias ExBody     ExH{:body}
#  typealias ExQuote    ExH{:QuoteNode}
#

#  s     : expression to convert
#  svars : vars set since the toplevel graph (helps separate globals / locals)
function awftograph(s, evalmod=Main, svars=Any[])

    explore(ex::Any)       = error("[awftograph] unmanaged type $ex ($(typeof(ex)))")
    explore(ex::Expr)      = explore(toExH(ex))
    explore(ex::ExH)       = error("[awftograph] unmanaged expr type $(ex.head) in ($ex)")

    explore(ex::ExLine)         = nothing     # remove line info
    explore(ex::LineNumberNode) = nothing     # remove line info
    explore(ex::QuoteNode)      = addnode!(g, NConst(ex.value))  # consider as constant

    explore(ex::ExReturn)  = explore(ex.args[1]) # focus on returned statement

    explore(ex::ExVcat)    = explore(Expr(:call, :vcat, ex.args...) )  # translate to vcat() call, and explore
    explore(ex::ExVect)    = explore(Expr(:call, :vcat, ex.args...) )  # translate to vcat() call, and explore
    explore(ex::ExCell1d)  = explore(Expr(:call, :(Base.cell_1d), ex.args...) )  # translate to cell_1d() call, and explore
    explore(ex::ExTrans)   = explore(Expr(:call, :transpose, ex.args[1]) )  # translate to transpose() and explore
    explore(ex::ExColon)   = explore(Expr(:call, :colon, ex.args...) )  # translate to colon() and explore
    explore(ex::ExTuple)   = explore(Expr(:call, :tuple, ex.args...) )  # translate to tuple() and explore

    explore(ex::ExPEqual)  = (args = ex.args ; explore( Expr(:(=), args[1], Expr(:call, :+, args[1], args[2])) ) )
    explore(ex::ExMEqual)  = (args = ex.args ; explore( Expr(:(=), args[1], Expr(:call, :-, args[1], args[2])) ) )
    explore(ex::ExTEqual)  = (args = ex.args ; explore( Expr(:(=), args[1], Expr(:call, :*, args[1], args[2])) ) )

    explore(ex::Real)      = addnode!(g, NConst(ex))

    explore(ex::ExBlock)   = map( explore, ex.args )[end]
    explore(ex::ExBody)    = map( explore, ex.args )[end]

    explore(ex::ExComp)    = addnode!(g, NComp(ex.args[2], [explore(ex.args[1]), explore(ex.args[3])]))

    # explore(ex::ExDot)     = addnode!(g, NDot(ex.args[2],     [ explore(ex.args[1]) ]))
    explore(ex::ExDot)     = explore(Expr(:call, :getfield, ex.args...))
    explore(ex::ExRef)     = explore(Expr(:call, :getindex, ex.args...))

    function explore(ex::Symbol)
        hassym(g.seti, ex)       && return getnode(g.seti, ex)
        hassym(g.exti, ex)       && return getnode(g.exti, ex)

        nn = addnode!(g, NExt(ex))    # create external node for this var
        g.exti[nn] = ex
        return nn
    end

    function explore(ex::ExCall)
        sf = ex.args[1]
        if sf == :getindex
            nv = explore(ex.args[2])
            ps = indexspec(nv, ex.args[3:end])
            return addnode!(g, NRef(:getidx, vcat([nv], ps)))

        elseif sf == :setindex!
            isa(ex.args[2], Symbol) ||
                error("[awftograph] setindex! only allowed on variables, $(ex.args[2]) found")

            nv  = explore(ex.args[2]) # node whose subpart is assigned
            ps  = indexspec(nv, ex.args[4:end])
            rhn = addnode!(g, NSRef(:setidx,
                                    [ nv,                               # var modified in pos #1
                                      explore(ex.args[3]),              # value affected in pos #2
                                      ps...] ))                         # dims

            rhn.precedence = filter(n -> nv in n.parents && n != rhn, g.nodes)
            g.seti[rhn] = ex.args[2]

            return rhn

        elseif sf == :getfield
            return addnode!(g, NDot(ex.args[3], [ explore(ex.args[2]) ]))

        elseif sf == :setfield!
            isa(ex.args[2], Symbol) ||
                error("[awftograph] setfield! only allowed on variables, $(ex.args[2]) found")

            nv  = explore(ex.args[2]) # node whose subpart is assigned
            rhn = addnode!(g, NSDot(ex.args[3],
                                    [ nv,                               # var modified in pos #1
                                      explore(ex.args[4])]))            # value affected in pos #2

            rhn.precedence = filter(n -> nv in n.parents && n != rhn, g.nodes)
            g.seti[rhn] = ex.args[2]

            return rhn

        else
            return addnode!(g, NCall(  :call,
                                        map(explore, ex.args[1:end]) ))
        end
    end

    function explore(ex::ExEqual)
        lhs = ex.args[1]

        if isSymbol(lhs)  # x = ....
            lhss = lhs

            # set before ? call explore
            if lhss in union(svars, collect(syms(g.seti)))
                vn = explore(lhss)
                rhn  = addnode!(g, NSRef(:setidx,
                                         [ vn,                     # var modified in pos #1
                                           explore(ex.args[2]) ])) # value affected in pos #2
                rhn.precedence = filter(n -> vn in n.parents && n != rhn, g.nodes)

            else # never set before ? assume it is created here
                rhn = explore(ex.args[2])

                # we test if RHS has already a symbol
                # if it does, to avoid loosing it, we create an NIn node
                if hasnode(g.seti, rhn)
                    rhn = addnode!(g, NIn(lhss, [rhn]))
                end
            end

        elseif isRef(lhs)   # x[i] = ....
            lhss = lhs.args[1]
            rhn = explore( Expr(:call, :setindex!, lhss, ex.args[2], lhs.args[2:end]...) )
            # vn = explore(lhss) # node whose subpart is assigned
            # rhn  = addnode!(g, NSRef(:setidx, [ vn,    # var modified in pos #1
            #                                     explore(ex.args[2]), # value in pos #2
            #                                     map(explore, lhs.args[2:end])] ))  # indexing starting at #3
            # rhn.precedence = filter(n -> vn in n.parents && n != rhn, g.nodes)

        elseif isDot(lhs)   # x.field = ....
            lhss = lhs.args[1]
            rhn = explore( Expr(:call, :setfield!, lhss, lhs.args[2], ex.args[2]) )

            # vn = explore(lhss) # node whose subpart is assigned
            # rhn  = addnode!(g, NSDot(lhs.args[2], [ vn, explore(ex.args[2])] ))
            # rhn.precedence = filter(n -> vn in n.parents && n != rhn, g.nodes)

        else
            error("[awftograph] $(toExpr(ex)) not allowed on LHS of assigment")
        end

        g.seti[rhn] = lhss

        return nothing
    end

    function explore(ex::ExFor)
        is = ex.args[1].args[1]
        isa(is, Symbol) ||
            error("[awftograph] for loop using several indexes : $is ")

        # explore the index range
        nir = explore(ex.args[1].args[2])

        # explore the for block as a separate graph
        nsvars = union(svars, collect(syms(g.seti)))
        g2 = awftograph(ex.args[2], evalmod, nsvars)

        # create "for" node
        nf = addnode!(g, NFor( Any[ is, g2 ] ))
        nf.parents = [nir]  # first parent is indexing range fo the loop

        # create onodes (node in parent graph) for each exti
        for (k, sym) in g2.exti.kv
            sym==is  && continue # loop index should be excluded
            pn = explore(sym)  # look in setmap, externals or create it
            g2.exto[pn] = sym
            push!(nf.parents, pn) # mark as parent of for loop
        end

        # create onodes and 'Nin' nodes for each seti
        #  will be restricted to variables that are defined in parent
        #   (others are assumed to be local to the loop)
        for (k, sym) in g2.seti.kv
            if sym in nsvars && sym != is # only for variables set in parent scope
                pn = explore(sym)                   # create node if needed
                rn = addnode!(g, NIn(sym, [nf]))    # exit node for this var in this graph
                g.seti[rn] = sym                    # signal we're setting the var
                g2.seto[rn] = sym

                append!(nf.precedence, filter(n -> pn in n.parents && n != nf, g.nodes))

                # create corresponding exti if it's not already done
                if !hassym(g2.exto, sym)
                    g2.exto[pn] = sym
                    push!(nf.parents, pn) # mark as parent of for loop
                end
            end
        end
    end

    #### translates ':' and 'end' special symbols in getindex / setindex!
    function indexspec(nv, as)
        p  = ExNode[]
        for (i,na) in enumerate(as)
            if length(as)==1 # single dimension
                ns = addgraph!(:( length(x) ), g,  Dict(:x => nv) )
            else # several dimensions
                ns = addgraph!(:( size(x, $i) ), g,  Dict(:x => nv) )
            end

            na==:(:) && (na = Expr(:(:), 1, :end) )  # replace (:) with (1:end)

            # explore the dimension expression
            nsvars = union(svars, collect(syms(g.seti)))
            ng = awftograph(na, evalmod, nsvars)

            # find mappings for onodes, including :end
            vmap = Dict()
            for (k, sym) in ng.exti.kv
                vmap[sym] = sym == :end ? ns : explore(sym)
            end

            nd = addgraph!(ng, g, vmap)
            push!(p, nd)
        end
        p
    end

    #  top level graph
    g = ExGraph()

    exitnode = explore(s)
    # exitnode = nothing if only variable assigments in expression
    #          = ExNode of last calc otherwise

    # id is 'nothing' for unnassigned last statement
    exitnode!=nothing && ( g.seti[exitnode] = nothing )

    # Resolve external symbols that are Functions, DataTypes or Modules
    # and turn them into constants
    for en in filter(n -> isa(n, NExt) & !in(n.main, svars) , keys(g.exti))
        if isdefined(evalmod, en.main)  # is it defined
            tv = evalmod.eval(en.main)
            isa(tv, TypeConstructor) && error("[awftograph] TypeConstructors not supported: $ex $(tv), use DataTypes")
            if isa(tv, DataType) || isa(tv, Module) || isa(tv, Function)
                delete!(g.exti, en)
                nc = addnode!(g, NConst( tv ))
                fusenodes(g, nc, en)
            end
        end
    end

    g
end





##########  function version   ##############

function awfrdiff(f::Function, sig0::Tuple; order::Int=1, evalmod=Main, debug=false, allorders=true)
    display("HELLO")
    sig = map( typeof, sig0 )
    fs = methods(f, sig)
    length(fs) == 0 && error("no function '$f' found for signature $sig")
    length(fs) > 1  && error("several functions $f found for signature $sig")  # is that possible ?

    fdef  = fs[1].func.code
    fcode = Base.uncompressed_ast(fdef)
    fargs = fcode.args[1]  # function parameters

    cargs = [ (fargs[i], sig0[i]) for i in 1:length(sig0) ]
    dex = awfrdiff(fcode.args[3]; order=order, evalmod=evalmod, debug=debug,
                allorders=allorders, cargs...)

    # Note : new function is created in the same module as original function
    myf = fdef.module.eval( :( $(Expr(:tuple, fargs...)) -> $dex ) )
end


######### expression version   ################
# TODO : break this huge function in smaller blocks

function awfrdiff(ex; outsym=nothing, order::Int=1, evalmod=Main, debug=false, allorders=true, params...)

    length(params) >= 1 || error("There should be at least one parameter specified, none found")

    order <= 1 ||
    length(params) == 1 || error("Only one param allowed for order >= 2")

    order <= 1 ||
    isa(params[1][2], Vector) ||
    isa(params[1][2], Real)   || error("Param should be a real or vector for order >= 2")

    paramsym    = Symbol[ e[1] for e in params]
    paramvalues = [ e[2] for e in params]
    parval      = Dict(zip(paramsym, paramvalues))

    g = awftograph(ex, evalmod)

    hassym(g.seti, outsym) ||
    error("can't find output var $( outsym==nothing ? "" : outsym)")

    # reduce to variable of interest
    g.seti = NSMap([getnode(g.seti, outsym)], [ outsym ])

    g |> splitnary! |> prune! |> simplify!
    calc!(g, params=parval, emod=evalmod)

    ov = getnode(g.seti, outsym).val
    isa(ov, Real) || error("output var should be a Real, $(typeof(ov)) found")

    voi = Any[ outsym ]

    if order == 1
        dg = reversegraph(g, getnode(g.seti, outsym), paramsym)
        append!(g.nodes, dg.nodes)

        for p in paramsym
            nn = getnode(dg.seti, dprefix(p))  # find the exit node of deriv of p
            ns = newvar("_dv")
            g.seti[nn] = ns
            push!(voi, ns)
        end

        g |> splitnary! |> prune! |> simplify!

    elseif order > 1 && isa(paramvalues[1], Real)
        for i in 1:order
            dg = reversegraph(g, getnode(g.seti, voi[i]), paramsym)
            append!(g.nodes, dg.nodes)
            nn = collect(nodes(dg.seti))[1]  # only a single node produced
            ns = newvar("_dv")
            g.seti[nn] = ns
            push!(voi, ns)

            g |> splitnary! |> prune! |> simplify!

            calc!(g, params=parval, emod=evalmod)
        end

    elseif order > 1 && isa(paramvalues[1], Vector)
        # do first order as usual
        dg = reversegraph(g, getnode(g.seti, outsym), paramsym)
        append!(g.nodes, dg.nodes)
        ns = newvar(:_dv)
        g.seti[ collect(nodes(dg.seti))[1] ] = ns
        push!(voi, ns)

        g |> splitnary! |> prune! |> simplify!

        # now order 2 to n
        for i in 2:order
            # launch derivation on a single value of the preceding
            #   derivation vector
            no = getnode(g.seti, voi[i])
            si = newvar(:_idx)
            ni = addnode!(g, NExt(si))
            ns = addnode!(g, NRef(:getidx, [ no, ni ]))

            calc!(g, params=Dict(zip([paramsym; si], [paramvalues; 1])), emod=evalmod)
            dg = reversegraph(g, ns, paramsym)

            #### We will now wrap dg in a loop scanning all the elements of 'no'
            # first create ext nodes to make dg a complete subgraph
            dg2 = ExNode[]
            nmap = Dict()
            for n in dg.nodes  # n = dg.nodes[2]
                for (j, np) in enumerate(n.parents)  # j,np = 1, n.parents[1]
                    if haskey(nmap, np) # already remapped
                        n.parents[j] = nmap[np]

                    elseif np == ni # it's the loop index
                        nn = NExt(si)
                        push!(dg2, nn)
                        dg.exti[nn] = si
                        n.parents[j] = nn
                        nmap[np] = nn

                    elseif np == ns # it's the selected element of the deriv vector
                        # create 'no' ref if needed
                        if !haskey(nmap, no)
                            sn = newvar()
                            nn = NExt(sn)
                            push!(dg2, nn)
                            dg.exti[nn] = sn
                            dg.exto[no] = sn
                            nmap[no] = nn
                        end

                        nn = NRef(:getidx, [ nmap[no], nmap[ni] ])
                        push!(dg2, nn)
                        nmap[ns] = nn

                    elseif !(np in dg.nodes) # it's not in dg (but in g)
                        sn = newvar()
                        nn = NExt(sn)
                        push!(dg2, nn)
                        dg.exti[nn] = sn
                        dg.exto[np] = sn
                        n.parents[j] = nn
                        nmap[np] = nn

                    end
                end

                # update onodes in for loops
                if isa(n, NFor)
                    g2 = n.main[2]
                    for (o,s) in g2.exto
                        if haskey(nmap, o)
                            g2.exto[ nmap[o] ] = s  # replace
                        end
                    end
                end
            end
            append!(dg.nodes, dg2)
            # dg |> prune! |> simplify!

            # create for loop node
            nf = addnode!(g, NFor(Any[ si, dg ] ) )

            # create param size node
            nsz = addgraph!( :( length( x ) ), g,  Dict( :x => getnode(g.exti, paramsym[1]) ) )

            # create (n-1)th derivative size node
            ndsz = addgraph!( :( sz ^ $(i-1) ), g, Dict( :sz => nsz ) )

            # create index range node
            nid = addgraph!( :( 1:dsz ),  g,  Dict( :dsz => ndsz ) )
            push!(nf.parents, nid)

            # pass size node inside subgraph
            sst = newvar()
            inst = addnode!(dg, NExt(sst))
            dg.exti[inst] = sst
            dg.exto[nsz]  = sst
            push!(nf.parents, nsz)

            # create result node (alloc in parent graph)
            nsa = addgraph!( :( zeros( $( Expr(:tuple, [:sz for j in 1:i]...) ) ) ),
                            g,  Dict( :sz => nsz ) )
            ssa = newvar()
            insa = addnode!(dg, NExt(ssa))
            dg.exti[insa] = ssa
            dg.exto[nsa]  = ssa
            push!(nf.parents, nsa)

            # create result node update (in subgraph)
            nres = addgraph!( :( res[ ((sidx-1)*st+1):(sidx*st) ] = dx ; res ), dg,
                              Dict(:res  => insa,
                                          :sidx => nmap[ni],
                                          :st   => inst,
                                          :dx   => collect(dg.seti)[1][1] ) )
            dg.seti = NSMap([nres], [ssa])

            # create exit node for result
            nex = addnode!(g, NIn(ssa, [nf]))
            dg.seto = NSMap([nex], [ssa])

            # update parents of for loop
            append!( nf.parents, setdiff(collect( nodes(dg.exto)), nf.parents[2:end]) )

            ns = newvar(:_dv)
            g.seti[nex] = ns
            push!(voi, ns)

            g |> splitnary! |> prune! |> simplify!
        end

    end

    if !allorders  # only keep the last derivative
        voi = [voi[end]]
    end

    if length(voi) > 1  # create tuple if multiple variables
        voin = map( s -> getnode(g.seti, s), voi )
        nf = addnode!(g, NConst(tuple))
        exitnode = addnode!(g, NCall(:call, [nf, voin...]))
    else
        exitnode = getnode(g.seti, voi[1])
    end
    g.seti = NSMap( [exitnode], [nothing])  # make this the only exitnode of interest

    g |> splitnary! |> prune! |> simplify!

    resetvar()
    debug ? g : tocode(g)
end

