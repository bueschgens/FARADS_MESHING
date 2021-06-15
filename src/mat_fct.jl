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