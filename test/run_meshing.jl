
using FARADS_GEOM
using FARADS_MESHING

c1 = Cylinder(1.0, 2.0, [0.0,0.0,0.0])
c2 = Cylinder(0.5, 2.0, [0.0,0.0,0.0])

p1 = discretisation(c1, [5,20,30])
reverse_nvec_of_faces!(p1)
delete_face_of_part!(p1, 3)
delete_face_of_part!(p1, 1)

p2 = discretisation(c2, [5,15,30])
delete_face_of_part!(p2, 3)
delete_face_of_part!(p2, 1)

m = compose_mesh([p1, p2])
information_mesh(m)
