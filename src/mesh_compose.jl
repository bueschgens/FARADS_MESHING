function compose_mesh(parts::Vector{Part{T1,T2}}) where {T1<:AbstractFloat, T2<:Integer}
    # composes all parts into a mesh
    n_parts = size(parts,1)
    n_faces = 0
    n_nodes = 0
    n_elements = 0
    for i = 1:n_parts
        n_faces += size(parts[i].faces,1)
        n_nodes += size(parts[i].nodes,1)
        for j = 1:size(parts[i].faces,1)
            n_elements += size(parts[i].faces[j].elements,1)
        end
    end
    # println("n_parts = ", n_parts)
    # println("n_faces = ", n_faces)
    # println("n_nodes = ", n_nodes)
    # println("n_elements = ", n_elements)

    # create all Arrays
    nodes2parts = Array{T2,2}(undef,n_parts,4)
    counter = 0
    for i = 1:n_parts
        nodes2parts[i,1] = i                                # number of part
        nodes2parts[i,2] = size(parts[i].nodes,1)           # total number of nodes of part
        nodes2parts[i,3] = counter + 1                      # start node
        nodes2parts[i,4] = counter + size(parts[i].nodes,1) # end node
        counter += size(parts[i].nodes,1)
    end

    nodes = Array{T1,2}(undef,n_nodes,3)
    for i = 1:n_parts
        nodes[nodes2parts[i,3]:nodes2parts[i,4],:] = parts[i].nodes[:,:]
    end

    faces2parts = Array{T2,2}(undef,n_parts,4)
    counter = 0
    for i = 1:n_parts
        faces2parts[i,1] = i                                # number of part
        faces2parts[i,2] = size(parts[i].faces,1)           # total number of faces of part
        faces2parts[i,3] = counter + 1                      # start face
        faces2parts[i,4] = counter + size(parts[i].faces,1) # end face
        counter += size(parts[i].faces,1)
    end

    elements2faces = Array{T2,2}(undef,n_faces,4)
    counter_f = 0
    counter_e = 0
    for i = 1:n_parts
        for j = 1:faces2parts[i,2]
            counter_f += 1
            elements2faces[counter_f,1] = counter_f                                      # number of face
            elements2faces[counter_f,2] = size(parts[i].faces[j].elements,1)             # total number of elements of face
            elements2faces[counter_f,3] = counter_e + 1                                  # start element
            elements2faces[counter_f,4] = counter_e + size(parts[i].faces[j].elements,1) # end element
            counter_e += size(parts[i].faces[j].elements,1)
        end
    end

    elements2parts = Array{T2,2}(undef,n_parts,4)
    counter = 0
    for i = 1:n_parts
        elements2parts[i,1] = i                     # number of part
        elements2parts[i,3] = counter + 1           # start element   
        counter_sum = 0               
        for j = 1:faces2parts[i,2]
            #counter += size(parts[i].faces[j].elements,1)
            counter_sum += size(parts[i].faces[j].elements,1)
        end
        elements2parts[i,2] = counter_sum           # total number of elements of part                    
        elements2parts[i,4] = counter + counter_sum # end element
        counter += counter_sum
    end

    elements = Array{T2,2}(undef,n_elements,3)
    com = Array{T1,2}(undef,n_elements,3)
    nvec = Array{T1,2}(undef,n_elements,3)
    area = Array{T1,1}(undef,n_elements)
    elementstatus = Array{T2,2}(undef,n_elements,3)
    counter = 0
    for i = 1:n_parts
        for j = 1:faces2parts[i,2]
            counter += 1
            e1 = elements2faces[counter,3]
            e2 = elements2faces[counter,4]
            elements[e1:e2,:] = parts[i].faces[j].elements[:,:]
            com[e1:e2,:] = parts[i].faces[j].com[:,:]
            nvec[e1:e2,:] = parts[i].faces[j].nvec[:,:]
            area[e1:e2] = parts[i].faces[j].area[:]
            elementstatus[e1:e2,1] = collect(e1:e2) # element number
            elementstatus[e1:e2,2] .= 0 # ?? not used
            elementstatus[e1:e2,3] .= i # part number
        end
    end

    return Mesh3D(nodes, nodes2parts, elements, com , nvec , area , elements2parts, elements2faces, faces2parts, elementstatus)
end

function information_mesh(mym)
    # print information on Mesh3D
	ne = size(mym.elements,1)
	nn  = size(mym.nodes,1)
	nf = size(mym.elements2faces,1)
	np = size(mym.elements2parts,1)
	println(typeof(mym)," has ",np," parts, ",nf," faces, ",ne," elements and ",nn," nodes")
end

function make_mesh_vector(mym::Mesh3D{T1, T2}) where {T1<:AbstractFloat, T2<:Integer}
	a = vec(mym.nodes)
	b = vec(mym.nodes2parts)
	c = vec(mym.elements)
	d = vec(mym.com)
	e = vec(mym.nvec)
	f = vec(mym.area)
	g = vec(mym.elements2parts)
	h = vec(mym.elements2faces)
	i = vec(mym.faces2parts)
	j = vec(mym.elementstatus)
	k = size(mym.elements,1)
	l = size(mym.nodes,1)
	m = size(mym.nodes2parts,1)
	return VecMesh3D(a, b, c, d, e, f, g, h, i, j, k, l, m)
end

function get_part_of_face(mym, face)
	# find part of current face
	if face > size(mym.elements2faces,1)
		println("Warning: Face number not available in Mesh")
		return 0
	end
	p = 0
	for j = 1: size(mym.faces2parts,1)
		if face >= mym.faces2parts[j,3] && face <= mym.faces2parts[j,4]
			p = j
			break
		end
	end
	return p
end

function get_mean_elem_size_of_face(mym, face)
    p = get_part_of_face(mym, face)
    n1 = mym.nodes2parts[p,3]
    n2 = mym.nodes2parts[p,4]
    nodes = mym.nodes[n1:n2,1:3]
    e1 = mym.elements2faces[face,3]
    e2 = mym.elements2faces[face,4]
    n_elem_face = mym.elements2faces[face,2]
    elemsize = Array{Float64,1}(undef,n_elem_face)
    counter = 0
    for i = e1:e2
        counter = counter + 1
        nodes1 = mym.elements[i,1]
        nodes2 = mym.elements[i,2]
        nodes3 = mym.elements[i,3]
        pointA = nodes[nodes1,:]
	    pointB = nodes[nodes2,:]
	    pointC = nodes[nodes3,:]
        edgeAB = [pointB[1]-pointA[1], pointB[2]-pointA[2], pointB[3]-pointA[3]]
        edgeAC = [pointC[1]-pointA[1], pointC[2]-pointA[2], pointC[3]-pointA[3]]
        edgeBC = [pointC[1]-pointB[1], pointC[2]-pointB[2], pointC[3]-pointB[3]]
        lengthAB = mynorm(edgeAB)
        lengthAC = mynorm(edgeAC)
        lengthBC = mynorm(edgeBC)
        elemsize[counter] = (lengthAB + lengthAC + lengthBC) / 3
    end
    elemsize_mean = sum(elemsize) / n_elem_face
    return elemsize_mean
end

function get_mean_elem_size_of_part(mym, part)
    f1 = mym.faces2parts[part,3]
    f2 = mym.faces2parts[part,4]
    n_faces = mym.faces2parts[part,2]
    elemsize = Array{Float64,1}(undef,n_faces)
    counter = 0
    for i = f1:f2
        counter = counter + 1
        elemsize[counter] = get_mean_elem_size_of_face(mym, i)
    end
    elemsize_mean = sum(elemsize) / n_faces
    return elemsize_mean
end

