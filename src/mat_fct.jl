function convert_mesh_mat2struct(matmodel)
    # convert dict from mat load to own struct
    a = matmodel["nodes"]
    b = matmodel["nodes2parts"]
    c = matmodel["elements"]
    d = matmodel["com"]
    e = matmodel["nvec"]
    f = matmodel["area"]
    g = matmodel["elements2parts"]
    h = matmodel["elements2faces"]
    i = matmodel["faces2parts"]
    j = matmodel["elementstatus"]
    return Mesh3D(a, b, c, d, e, f, g, h, i, j)
end



function convert_MatlabMesh_to_Mesh3D(m_mat_old)
    # convert matlab mesh old (dict after load) to own struct (Mesh3D)

    # nodes
    nodes_mat = m_mat_old["Nodes"]["coords"]
    n_parts = size(nodes_mat,2)
    nodes2parts = zeros(Int64,n_parts,4)
    n_nodes = 0
    for i = 1:n_parts
        nodes2parts[i,1] = i
        nodes2parts[i,2] = size(nodes_mat[i],1)
        nodes2parts[i,3] = n_nodes + 1
        n_nodes = n_nodes + nodes2parts[i,2]
        nodes2parts[i,4] = n_nodes
    end
    # print_array(nodes2parts)

    nodes = zeros(Float64,nodes2parts[end,4],3)
    for i = 1:n_parts
        n1 = nodes2parts[i,3]
        n2 = nodes2parts[i,4]
        nodes[n1:n2,:] = nodes_mat[i]
    end
    # @show size(nodes)

    # elements
    elem_mat = m_mat_old["Face"]["nodes"]
    # @show size(elem_mat)
    n_faces = size(elem_mat,2)
    elements2faces = zeros(Int64,n_faces,4)
    n_elements = 0
    for i = 1:n_faces
        elements2faces[i,1] = i
        elements2faces[i,2] = size(elem_mat[i],1)
        elements2faces[i,3] = n_elements + 1
        n_elements = n_elements + elements2faces[i,2]
        elements2faces[i,4] = n_elements
    end
    # print_array(elements2faces)

    elements = zeros(Int64,elements2faces[end,4],3)
    com_mat = m_mat_old["Face"]["com"]
    com = zeros(Float64,elements2faces[end,4],3)
    nvec_mat = m_mat_old["Face"]["n_vec"]
    nvec = zeros(Float64,elements2faces[end,4],3)
    area_mat = m_mat_old["Face"]["area"]
    area = Vector{Float64}(undef,elements2faces[end,4])
    for i = 1:n_faces
        e1 = elements2faces[i,3]
        e2 = elements2faces[i,4]
        elements[e1:e2,:] = Int.(elem_mat[i])
        com[e1:e2,:] = com_mat[i]
        nvec[e1:e2,:] = nvec_mat[i]
        area[e1:e2] = area_mat[i]
    end
    # @show size(elements)
    # @show elements[end,:]
    # @show size(com)
    # @show com[end,:]
    # @show size(nvec)
    # @show nvec[end,:]
    # @show size(area)
    # @show area[end,:]

    zuordnung_mat = m_mat_old["Zuordnung"]
    faces2parts = zeros(Int64,n_parts,4)
    for i = 1:n_parts
        faces2parts[i,1] = i
        faces2parts[i,2] = zuordnung_mat["nFaces"][i]
        faces2parts[i,3] = zuordnung_mat["FaceStart"][i]
        faces2parts[i,4] = zuordnung_mat["FaceEnd"][i]
    end
    # print_array(faces2parts)

    elements2parts = zeros(Int64,n_parts,4)
    n_elements = 0
    for i = 1:n_parts
        elements2parts[i,1] = i
        f1 = faces2parts[i,3]
        f2 = faces2parts[i,4]
        n_elem_part = 0
        for j = f1:f2
            n_elem_part += elements2faces[j,2]
        end
        elements2parts[i,2] = n_elem_part
        elements2parts[i,3] = n_elements + 1
        n_elements = n_elements + n_elem_part
        elements2parts[i,4] = n_elements
    end
    # print_array(elements2parts)

    elementstatus = zeros(Int64,n_elements,3)
    for i = 1:n_elements
        elementstatus[i,1] = i
    end
    for i = 1:n_parts
        e1 = elements2parts[i,3]
        e2 = elements2parts[i,4]
        elementstatus[e1:e2,3] .= i
    end
    # @show size(elementstatus)
    # @show elementstatus[end,:]

    a = nodes
    b = nodes2parts
    c = elements
    d = com
    e = nvec
    f = area
    g = elements2parts
    h = elements2faces
    i = faces2parts
    j = elementstatus
    return Mesh3D(a, b, c, d, e, f, g, h, i, j)
end