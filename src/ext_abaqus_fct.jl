
struct SectionStruct
    type::String
    content::String
    n_lines::Int64
end

struct AbaqusStruct
    nodes::Array{Union{Int64,Float64},2}
    elems::Array{Int64,2}
    n_nodes::Int64
    n_elems::Int64
end

function importabaqus(filename::String)
    io = Base.open(filename, "r")
    sections = getSections(io)
    # @show size(sections)
    myAbaqus = evalSections(sections[1:2])
    return myAbaqus
end

function getSections(io)
    sections = SectionStruct[]
    iobuff = IOBuffer(UInt8[], read=true, write=true, append=true)

    found_nodes = false
    found_elems = false
    n_nodes = 0
    n_elems = 0

    for line in eachline(io)

        if found_nodes
            if line[1] == '*'
                push!(sections, SectionStruct("nodes", read(iobuff,String), n_nodes))
                flush(iobuff)
                found_nodes = false
            else
                n_nodes = n_nodes + 1
                write(iobuff, line)
                write(iobuff, "\n")
            end
        end

        if found_elems
            if line[1] == '*'
                push!(sections, SectionStruct("elems", read(iobuff,String), n_elems))
                flush(iobuff)
                found_elems = false
            else
                n_elems = n_elems + 1
                write(iobuff, line)
                write(iobuff, "\n")
            end
        end

        if length(line) >= 5
            if cmp(line[1:5], "*Node") == 0
                found_nodes = true
            end
        end
        if length(line) >= 8
            if cmp(line[1:8], "*Element") == 0
                found_elems = true
            end
        end
        
    end

    return sections
end

function evalSections(sections::Array{SectionStruct, 1})
    val_nodes = []
    val_elems = []
    n_nodes = 0
    n_elems = 0
    for (k, sec) in enumerate(sections)

        if cmp(sec.type, "nodes") == 0
            s = split(sec.content, r" |\n|,") # splits at space, new line and comma
            contentArr = s[s .!= ""]
            n_nodes = sec.n_lines
            val_nodes = Array{Union{Int64,Float64},2}(undef,n_nodes,4)
            for i = 1:n_nodes
                j = (i-1)*4 + 1
                val_nodes[i,1] = parse(Int64, contentArr[j]) #number
                val_nodes[i,2] = parse(Float64, contentArr[j+1]) #x
                val_nodes[i,3] = parse(Float64, contentArr[j+2]) #y
                val_nodes[i,4] = parse(Float64, contentArr[j+3]) #z
            end


        elseif cmp(sec.type, "elems") == 0
            s = split(sec.content, r" |\n|,") # splits at space, new line and comma
            contentArr = s[s .!= ""]
            n_elems = sec.n_lines
            val_elems = Array{Int64,2}(undef,n_elems,4)
            for i = 1:n_elems
                j = (i-1)*4 + 1
                val_elems[i,1] = parse(Int64, contentArr[j]) #number
                val_elems[i,2] = parse(Int64, contentArr[j+1]) #node1
                val_elems[i,3] = parse(Int64, contentArr[j+2]) #node2
                val_elems[i,4] = parse(Int64, contentArr[j+3]) #node3
            end

        end

    end

    return AbaqusStruct(val_nodes, val_elems, n_nodes, n_elems)
end