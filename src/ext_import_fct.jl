
function import_tgrid(input, orig; deleteInterior = true, scaleFactor = 1)

    # use TgridReader to read msh file
    tgridmsh = TgridMeshImport(input)

    # convert nodeSection to nodes
    # blocks b together are all nodes
    nodes = []
    nodes2block = []
    blocknumber = 0
    for b = 1:size(tgridmsh.nodeSection,1)
        if !isnothing(tgridmsh.nodeSection[b].coords)
            n_nodes_block = size(tgridmsh.nodeSection[b].coords,1)
            bnodes = zeros(n_nodes_block, 3)
            for n = 1:n_nodes_block
                bnodes[n,:] = tgridmsh.nodeSection[b].coords[n,:]
            end
            blocknumber+=1
            if !isempty(nodes)
                old_length = size(nodes,1)
                nodes = vcat(nodes, bnodes)
                nodes2block = vcat(nodes2block,[blocknumber n_nodes_block old_length+1 size(nodes,1)])
            else
                nodes = bnodes
                nodes2block = [blocknumber n_nodes_block 1 size(nodes,1)]
            end
        end
    end

    # change orig 
    for i = 1:3
        nodes[:,i] .+= orig[i]
    end

    # scale mesh by changing nodes
    nodes .*= scaleFactor

    # get walls for import
    n_facesections = size(tgridmsh.faceSection,1)
    facesection_wall = Vector{Bool}(undef,n_facesections)
    for f = 1:n_facesections
        # show name of face with type: 2 -> interior; 3 -> wall
        # println("Face ", f, " -> ", tgridmsh.zone[f].name, " -> Type ", tgridmsh.faceSection[f].type)
        println("Face ", f, " -> Type ", tgridmsh.faceSection[f].type)
        iswall = any(x->x==3, tgridmsh.faceSection[f].type)
        isperiodic = any(x->x==18, tgridmsh.faceSection[f].type)
        # isinterior = any(x->x==2, tgridmsh.faceSection[f].type)
        if !isnothing(tgridmsh.faceSection[f].FaceTypes) && (iswall || isperiodic)
            facesection_wall[f] = true
        else
            facesection_wall[f] = false
        end
    end
    faces_all = collect(1:n_facesections)
    faces4import = faces_all[facesection_wall]

    # convert faceSection to Face
    faces = Vector{Face{Float64,Int64}}(undef,size(faces4import,1))
    facenumber = 0
    for f in faces4import
        n_elems_face = size(tgridmsh.faceSection[f].FaceTypes,1)
        felements = zeros(Int64, n_elems_face, 3)
        for e = 1:n_elems_face
            felements[e,:] = tgridmsh.faceSection[f].FaceTypes[e].nodeIDs
        end
        # calculate com area and nvec
        com = zeros(size(felements,1),3)
        area = zeros(size(felements,1))
        nvec = zeros(size(felements,1),3)
        for i = 1:size(felements,1)
            x = nodes[felements[i,:],1]
            y = nodes[felements[i,:],2]
            z = nodes[felements[i,:],3]
            com[i,:], area[i] = get_com_and_area(x, y, z)
            nvec[i,:] = get_nvec(x, y, z)
        end
        facenumber += 1
        faces[facenumber] = Face(felements, com, nvec, area)
        reverse_node_numbers_of_elements!(faces[facenumber])
    end

    # delete node block 1 of interior
    if deleteInterior
        nodesSurf = nodes[nodes2block[2,3]:end,:]
        # offset nodes of elements with subtracting last interior node
        offset = nodes2block[1,2]
        for i = 1:size(faces,1)
            faces[i].elements .-= offset
        end
    else
        println("mesh with interior")
        nodesSurf = nodes
        # not implemented yet...
    end

    return Part(nodesSurf, faces)
end


function import_abaqus(input, orig)
    # use abaqus reader to import .inp files
    # only heat transfer tri elements
    abaqus_raw = importabaqus(input)

    println("raw abaqus mesh imported with ", abaqus_raw.n_nodes, " nodes and ", abaqus_raw.n_elems, " elements")

    # convert abaqus nodes
    nodes = Array{Float64,2}(undef,abaqus_raw.n_nodes,3)
    nodes[:,:] = abaqus_raw.nodes[:,2:4]

    # change orig
    for i = 1:3
        nodes[:,i] .+= orig[i]
    end

    # put all elements into 1 face
    faces = Vector{Face{Float64,Int64}}(undef,1) #only 1 face
    n_elems_face = abaqus_raw.n_elems
    felements = zeros(Int64, n_elems_face, 3)
    felements[:,:] = abaqus_raw.elems[:,2:4]
    # calculate com area and nvec
    com = zeros(size(felements,1),3)
    area = zeros(size(felements,1))
    nvec = zeros(size(felements,1),3)
    for i = 1:size(felements,1)
        x = nodes[felements[i,:],1]
        y = nodes[felements[i,:],2]
        z = nodes[felements[i,:],3]
        com[i,:], area[i] = get_com_and_area(x, y, z)
        nvec[i,:] = get_nvec(x, y, z)
    end
    faces[1] = Face(felements, com, nvec, area)
    reverse_node_numbers_of_elements!(faces[1])

    return Part(nodes, faces)
end