
function export_vtk(m; filename = "my_vtm_file", cdata1 = nothing, cdata2 = nothing)

    vtmfile = vtk_multiblock(filename)

    for ip = 1:size(m.elements2parts,1)

        # part nodes
        n1 = m.nodes2parts[ip,3]
        n2 = m.nodes2parts[ip,4]
        points = zeros(3,m.nodes2parts[ip,2])
        counter = 0
        for i = n1:n2
            counter = counter + 1
            points[:,counter] = m.nodes[i,:]
        end

        # loop through face cells
        fc1 = m.faces2parts[ip,3]
        fc2 = m.faces2parts[ip,4]
        for ifc = fc1:fc2
            celltype = VTKCellTypes.VTK_TRIANGLE
            cells = MeshCell[] # empty cells array for the face
            e1 = m.elements2faces[ifc,3]
            e2 = m.elements2faces[ifc,4]
            for ie = e1:e2
                inds = m.elements[ie,:]
                c = MeshCell(celltype, inds)
                push!(cells, c)
            end

            vtkfile = vtk_grid(vtmfile, points, cells)

            if !isnothing(cdata1)
                vtkfile["my_cell_data1", VTKCellData()] = cdata1[e1:e2,:]
            end

            if !isnothing(cdata2)
                vtkfile["my_cell_data2", VTKCellData()] = cdata2[e1:e2,:]
            end
            
            cdataip = ones(m.elements2faces[ifc,2]) * ip
            vtkfile["my_part_id", VTKCellData()] = cdataip
            cdataifc = ones(m.elements2faces[ifc,2]) * ifc
            vtkfile["my_face_id", VTKCellData()] = cdataifc
            
        end

    end

    outfiles = vtk_save(vtmfile)

    println("sucessful vtk write: ",filename)

end