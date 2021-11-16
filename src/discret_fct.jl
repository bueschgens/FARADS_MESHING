
function mycross(a::Vector{T}, b::Vector{T}) where T<:Real
    r1 = a[2]*b[3] - a[3]*b[2]
    r2 = a[3]*b[1] - a[1]*b[3]
    r3 = a[1]*b[2] - a[2]*b[1]
    return [r1,r2,r3]
end

function mynorm(a::Vector{T}) where T<:Real
    n = sqrt(a[1]*a[1] + a[2]*a[2] + a[3]*a[3])
    return n
end

function get_com_and_area(x, y, z)
	n = 3
	s = zeros(4) # 1:x 2:y 3:z 4:area
	for i = 3 : n
		p = zeros(4) # 1:x 2:y 3:z 4:area
		p[1] = (y[i]-y[1])*(z[i]-z[2]) - (z[i]-z[1])*(y[i]-y[2])
		p[2] = (z[i]-z[1])*(x[i]-x[2]) - (x[i]-x[1])*(z[i]-z[2])
		p[3] = (x[i]-x[1])*(y[i]-y[2]) - (y[i]-y[1])*(x[i]-x[2])
		p[4] = sqrt(p[1]^2 + p[2]^2 + p[3]^2) / 2
		s[1] = s[1] + (x[1] + x[2] + x[i]) / 3 * p[4]
		s[2] = s[2] + (y[1] + y[2] + y[i]) / 3 * p[4]
		s[3] = s[3] + (z[1] + z[2] + z[i]) / 3 * p[4]
		s[4] = s[4] + p[4]
	end
	com = [(s[1] / s[4]) (s[2] / s[4]) (s[3] / s[4])]
	area = s[4]
	return com, area
end

function get_nvec(x, y, z)
	v1 = [x[1]; y[1]; z[1]] - [x[2]; y[2]; z[2]]
	v2 = [x[1]; y[1]; z[1]] - [x[3]; y[3]; z[3]]
	v0 = mycross(v1, v2)
	nvec_v = (v0 / mynorm(v0))
	return nvec_v
end

function discretisation(rect::Rectangle{T1}, seed::Vector{T2}) where {T1<:AbstractFloat, T2<:Integer}
	# create rectangle with triangle mesh
	# seed [dim1, dim2]
	# default: nvec pointing in pos direction of third axis
	dim0 = findall(x->x==0, rect.length)
	if size(dim0,1) != 1
		println("warning in mesh - rectangle user input")
	elseif dim0[1] == 1
		d1 = 2
		d2 = 3
		faktor_nvec = -1
	elseif dim0[1] == 2
		d1 = 1
		d2 = 3
		faktor_nvec = 1
	elseif dim0[1] == 3
		d1 = 1
		d2 = 2
		faktor_nvec = -1
	else
		println("warning in mesh - rectangle user input")
	end
	length_x = rect.length[d1]
	length_z = rect.length[d2]
	n_x = seed[d1]
	n_z = seed[d2]
	# coord vectors
	points_x = collect(0:(length_x/n_x):length_x)
	points_z = collect(0:(length_z/n_z):length_z)
	# nodes based on coords vectors
	n_nodes = size(points_x,1) * size(points_z,1)
	nodes = zeros(n_nodes,3)
	nodes[:,d1] = repeat(points_x,size(points_z,1))
	nodes[:,d2] = repeat(points_z, inner=size(points_x,1))
	# node offset with orig
	nodes[:,1] .+= rect.orig[1]
	nodes[:,2] .+= rect.orig[2]
	nodes[:,3] .+= rect.orig[3]
	# node array for creating elements
	nodes_vec = collect(T2, 1:n_nodes)
	nodes2D = reshape(nodes_vec, (size(points_x,1), size(points_z,1)))
	# elements
	n_elements = n_x * n_z * 2
	elements = zeros(T2, n_elements,3)
	ie = 0
	for iz = 1:n_z
		for ix = 1:n_x
			ie = ie + 1
			#first triagnle
			elements[ie,1] = nodes2D[ix,iz]
			elements[ie,2] = nodes2D[ix,iz+1]
			elements[ie,3] = nodes2D[ix+1,iz+1]
			ie = ie + 1
			#second triangle
			elements[ie,1] = nodes2D[ix,iz]
			elements[ie,3] = nodes2D[ix+1,iz]
			elements[ie,2] = nodes2D[ix+1,iz+1]
		end
	end
	# com area und nvec
	com = zeros(size(elements,1),3)
	area = zeros(size(elements,1))
	nvec = zeros(size(elements,1),3)
	for i = 1:size(elements,1)
		x = nodes[elements[i,:],1]
		y = nodes[elements[i,:],2]
		z = nodes[elements[i,:],3]
		com[i,:], area[i] = get_com_and_area(x, y, z)
		nvec[i,:] = get_nvec(x, y, z)
	end
	nvec = nvec .* faktor_nvec
    faces = Vector{Face{T1,T2}}(undef,1)
    faces[1] = Face(elements, com, nvec, area)
	if faktor_nvec == 1
		# needs swap on face
		reverse_node_numbers_of_elements!(faces[1])
	end
	return Part(nodes, faces)
end

function reverse_nvec_of_faces!(part::Part; faces = 1:size(part.faces,1))
    # reverse nvec dir of face(s) f from part p
    for i in faces
        part.faces[i].nvec .*= (-1)
		# swapcols!(part.faces[i].elements, 2, 3)
		reverse_node_numbers_of_elements!(part.faces[i])
    end
end

function reverse_node_numbers_of_elements!(face::Face)
    # reverse node numbers of face
	# change element numbers col 2 with 3
	swapcols!(face.elements, 2, 3)
end

function swapcols!(X::AbstractMatrix, i::Integer, j::Integer)
	# in place column swap with 0 allocations
	# X = [1 4 7 10; 2 5 8 11; 3 6 9 12]
	# @show X
	# i = 2
	# j = 3
    @inbounds for k = 1:size(X,1)
        X[k,i], X[k,j] = X[k,j], X[k,i]
    end
	# @show X
end

function circle(r, o, phi)
	x = o[1] + r .* cosd(phi)
	y = o[2] + r .* sind(phi)
	return [x, y]
end

function discretisation(cyl::Cylinder{T1}, seed::Vector{T2}) where {T1<:AbstractFloat, T2<:Integer}
	# create cylinder with triangle mesh
	# seed [radius, circum, height]
    # default: nvec pointing out of cylinder
	n_r = seed[1]
	n_c = seed[2]
	n_l = seed[3]
	points_r = zeros(n_r+1,n_c,2)
	for k = 1:n_r
		r = ((cyl.d ./ 2) ./ n_r) .* (n_r + 1 - k)
		for i = 1:n_c
			phi = (360 ./ n_c) .* i
			points_r[k,i,:] = circle(r, cyl.orig[1:2], phi)
		end
	end
	for i = 1:n_c
		points_r[n_r+1,i,:] .= cyl.orig[1:2]
	end
	nodes_r = zeros(T2,(n_r+1),n_c,1)
	n = 0
	for i = 1:size(nodes_r,1)
		if i == (n_r + 1)
			n = n + 1
			nodes_r[i,:,1] .= n
		else
			for j = 1:size(nodes_r,2)
				n = n + 1
				nodes_r[i,j,1] = n
			end
		end
	end
	n_elem = ((n_r-1) .* n_c .* 2) + (1 .* n_c)
	elements_r = zeros(T2,n_elem,3)
	e = 0
	for i = 1:n_r
		if i == n_r
			for j = 1:n_c
				if j == n_c
					e = e + 1
					elements_r[e,1] = nodes_r[i,j,1]
					elements_r[e,2] = nodes_r[i+1,1,1]
					elements_r[e,3] = nodes_r[i,1,1]
				else
					e = e + 1
					elements_r[e,1] = nodes_r[i,j,1]
					elements_r[e,2] = nodes_r[i+1,1,1]
					elements_r[e,3] = nodes_r[i,j+1,1]
				end
			end
		else
			for j = 1:n_c
				if j == n_c
					e = e + 1
					elements_r[e,1] = nodes_r[i,j,1]
					elements_r[e,2] = nodes_r[i+1,j,1]
					elements_r[e,3] = nodes_r[i+1,1,1]
					e = e + 1
					elements_r[e,1] = nodes_r[i,j,1]
					elements_r[e,2] = nodes_r[i+1,1,1]
					elements_r[e,3] = nodes_r[i,1,1]
				else
					e = e + 1
					elements_r[e,1] = nodes_r[i,j,1]
					elements_r[e,2] = nodes_r[i+1,j,1]
					elements_r[e,3] = nodes_r[i+1,j+1,1]
					e = e + 1
					elements_r[e,1] = nodes_r[i,j,1]
					elements_r[e,2] = nodes_r[i+1,j+1,1]
					elements_r[e,3] = nodes_r[i,j+1,1]
				end
			end
		end
	end
	points_l = zeros((n_l+1),n_c,3)
	r = (cyl.d ./ 2)
	for k = 1:(n_l+1)
		z = ((cyl.h ./ n_l) .* (k-1)) + cyl.orig[3]
		points_l[k,:,3] .= z
		for i = 1:n_c
			phi = (360 ./ n_c) .* i
			points_l[k,i,1:2] = circle(r, cyl.orig, phi)
		end
	end
	nodes_l = zeros(T2,(n_l+1),n_c,1)
	n = 0
	for i = 1:size(nodes_l,1)
		for j = 1:size(nodes_l,2)
			n = n + 1
			nodes_l[i,j,1] = n
		end
	end
	n_elem = n_l .* n_c .* 2
	elements_l = zeros(T2,n_elem,3)
	e = 0
	for i = 1:n_l
		for j = 1:n_c
			if j == n_c
				e = e + 1
				elements_l[e,1] = nodes_l[i,j,1]
				elements_l[e,3] = nodes_l[i+1,j,1]
				elements_l[e,2] = nodes_l[i+1,1,1]
				e = e + 1
				elements_l[e,1] = nodes_l[i,j,1]
				elements_l[e,3] = nodes_l[i+1,1,1]
				elements_l[e,2] = nodes_l[i,1,1]
			else
				e = e + 1
				elements_l[e,1] = nodes_l[i,j,1]
				elements_l[e,3] = nodes_l[i+1,j,1]
				elements_l[e,2] = nodes_l[i+1,j+1,1]
				e = e + 1
				elements_l[e,1] = nodes_l[i,j,1]
				elements_l[e,3] = nodes_l[i+1,j+1,1]
				elements_l[e,2] = nodes_l[i,j+1,1]
			end
		end
	end
	coords_r = zeros((n_r*n_c)+1,3)
	n = 0
	for i = 1:size(nodes_r,1)
		if i == n_r+1
			n = n + 1
			coords_r[n,1] = points_r[i,1,1]
			coords_r[n,2] = points_r[i,1,2]
		else
			for j = 1:size(nodes_r,2)
				n = n + 1
				coords_r[n,1] = points_r[i,j,1]
				coords_r[n,2] = points_r[i,j,2]
			end
		end
	end
	coords_l = zeros((n_l+1)*n_c,3)
	n = 0
	for i = 1:size(nodes_l,1)
		for j = 1:size(nodes_l,2)
			n = n + 1
			coords_l[n,1] = points_l[i,j,1]
			coords_l[n,2] = points_l[i,j,2]
			coords_l[n,3] = points_l[i,j,3]
		end
	end
	n_elem = size(elements_r,1) *2 + size(elements_l,1)
	elements = zeros(T2,n_elem,3)
	elements[1:size(elements_r,1),:] = elements_r
	offset_e = size(elements_r,1)
	offset_n = size(coords_r,1) - n_c
	for i = 1:size(elements_l,1)
		copy_element = elements_l[i,:]
		for j = 1:3
			if copy_element[j] > n_c
				copy_element[j] = copy_element[j] .+ offset_n
			end
		end
		elements[offset_e+i,:] = copy_element
	end
	offset_e = size(elements_r,1) + size(elements_l,1)
	offset_n = size(coords_r,1) + size(coords_l ,1) - n_c - n_c
	for i = 1:size(elements_r,1)
		copy_element = elements_r[i,:]
		for j = 1:3
			if copy_element[j] > n_c
				copy_element[j] = copy_element[j] .+ offset_n
			else
				copy_element[j] = copy_element[j] .+ offset_n #-n_c
			end
		end
		elements[offset_e+i,:] = copy_element
	end
	n_nodes = size(coords_r,1) *2 + size(coords_l,1) - (2 * n_c)
	nodes = zeros(n_nodes,3)
	nodes[1:size(coords_r,1),1:2] = coords_r[:,1:2]
	nodes[1:size(coords_r,1),3] .= cyl.orig[3]
	i1 = size(coords_r,1) + 1
	i2 = size(coords_r,1) + size(coords_l,1) - n_c
	nodes[i1:i2,:] = coords_l[n_c+1:size(coords_l,1),:]
	i1 = i2 + 1
	i2 = i2 + size(coords_r,1) - n_c
	nodes[i1:i2,1:2] = coords_r[n_c+1:size(coords_r,1),1:2]
	nodes[i1:i2,3] .= cyl.orig[3] + cyl.h
	assignment = zeros(T2,3,2)
	assignment[1,:] = [1 size(elements_r,1)]
	assignment[2,:] = [size(elements_r,1)+1 size(elements_r,1)+size(elements_l,1)]
	assignment[3,:] = [size(elements_r,1)+size(elements_l,1)+1 size(elements,1)]
	com = zeros(size(elements,1),3)
	area = zeros(size(elements,1))
	nvec = zeros(size(elements,1),3)
	for i = 1:size(elements,1)
		x = nodes[elements[i,:],1]
		y = nodes[elements[i,:],2]
		z = nodes[elements[i,:],3]
		com[i,:], area[i] = get_com_and_area(x, y, z)
		nvec[i,:] = get_nvec(x, y, z)
	end
	nvec[assignment[3,1]:assignment[3,2],:] *= (-1)
    faces = Vector{Face{T1,T2}}(undef,3)
    for i = 1:3
        e1 = assignment[i,1]
        e2 = assignment[i,2]
        faces[i] = Face(elements[e1:e2,:], com[e1:e2,:], nvec[e1:e2,:], area[e1:e2])
    end
	return Part(nodes, faces)
end

function delete_face_of_part!(part::Part, face::T2) where T2<:Integer
	# delete face of part
	if face > size(part.faces,1)
		println("Warning: Face number not available in Part")
		return 0
	end
	deleteat!(part.faces, face)
end

function join_parts(parts::Vector{Part{T1, T2}}) where {T1<:AbstractFloat, T2<:Integer}
	# join parts
	n_nodes = 0
	n_faces = 0
	for p in parts
		n_nodes += size(p.nodes,1)
		n_faces += size(p.faces,1)
	end
	nodes = Matrix{T1}(undef,n_nodes,3)
	faces = Vector{Face{T1,T2}}(undef,n_faces)
	n1 = 0
	f1 = 0
	offset = 0
	for p in parts
		n2 = n1 + size(p.nodes,1)
		n1 += 1
		nodes[n1:n2,:] = p.nodes[:,:]
		n1 = n2
		f2 = f1 + size(p.faces,1)
		f1 += 1
		faces[f1:f2] = p.faces[:]
		# TO DO: here only copied as ref
		# changes old part as well
		# makes old part unusable
		for f = f1:f2
			faces[f].elements[:,:] .+= offset
		end
		f1 = f2
		offset += size(p.nodes,1)
	end
	return Part(nodes, faces)
end

function join_faces_of_part(part::Part{T1, T2}, newfaces::Vector{Vector{T2}}) where {T1<:AbstractFloat, T2<:Integer}
	# join faces of part
	# add face2 to face1 and delete face 1 afterwards
	n_newfaces = size(newfaces,1)
	faces = Vector{Face{T1,T2}}(undef,n_newfaces)
	for i = 1:n_newfaces
		println("join faces ", newfaces[i])
		n_elements_nf = 0
		for j in newfaces[i]
			n_elements_nf += size(part.faces[j].elements,1)
		end
		elements = zeros(T2, n_elements_nf, 3)
		com = zeros(n_elements_nf, 3)
		nvec = zeros(n_elements_nf, 3)
		area = zeros(n_elements_nf)
		e1 = 0
		e2 = 0
		for j in newfaces[i]
			e1 = e2 + 1
			e2 += size(part.faces[j].elements,1)
			elements[e1:e2,:] = part.faces[j].elements[:,:]
			com[e1:e2,:] = part.faces[j].com[:,:]
			nvec[e1:e2,:] = part.faces[j].nvec[:,:]
			area[e1:e2] = part.faces[j].area[:]
		end
		faces[i] = Face(elements, com, nvec, area)
	end
	return Part(part.nodes, faces)
end

function debug_element_node_numbering(part::Part)
	# debug part for element nodes numbering
	n_faces = size(part.faces,1)

	wrong = Matrix(undef, 0, 2) # for storing wrong elements of part [face, element]

	for i = 1:n_faces

		n_elem_face = size(part.faces[i].elements,1)

		for j = 1:n_elem_face
			
			nodes1 = part.faces[i].elements[j,1]
			nodes2 = part.faces[i].elements[j,2]
			nodes3 = part.faces[i].elements[j,3]
			
			pointA = part.nodes[nodes1,:]
			pointB = part.nodes[nodes2,:]
			pointC = part.nodes[nodes3,:]

			v0 = pointA
			v1 = pointC
			v2 = pointB

			dir = part.faces[i].nvec[j,:]
			dir .*= (-1)

			EPSILON = 1E-10
			edge1 = [v1[1]-v0[1], v1[2]-v0[2], v1[3]-v0[3]]
			edge2 = [v2[1]-v0[1], v2[2]-v0[2], v2[3]-v0[3]]
			pvec = [(dir[2]*edge2[3]) - (dir[3]*edge2[2]),
							 (dir[3]*edge2[1]) - (dir[1]*edge2[3]),
							 (dir[1]*edge2[2]) - (dir[2]*edge2[1])]
			det = edge1[1]*pvec[1] + edge1[2]*pvec[2] + edge1[3]*pvec[3]

			if det < EPSILON
				# println("checking element ", j, " of part ", i)
				# println("        no intersection: det < EPSILON")
				wrong = vcat(wrong, [i j])
			else
				# println("        intersection possible")
			end

		end

    end

	n_wrongs = size(wrong,1)
	if n_wrongs == 0
		println("debug check found no wrong elements")
	else
		println("debug check found ", n_wrongs, " wrong elements")
	end
end