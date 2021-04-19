#module GMSHreader
#=
Read GMSH files:

Supported MeshFormat 4, ASCII

Supported File Groups:
    - MeshFomrat
    - PhysicalNames
    - Entities
    - Nodes
    - Elements

GMSH Element Types:
1:  2-node line.
2:  3-node triangle.
3:  4-node quadrangle.
4:  4-node tetrahedron.
5:  8-node hexahedron.
6:  6-node prism.
7:  5-node pyramid.
8:  3-node second order line (2 nodes associated with the vertices and 1
    with the edge).
9:  6-node second order triangle (3 nodes associated with the vertices and 3
    with the edges).
10: 9-node second order quadrangle (4 nodes associated with the vertices,
    4 with the edges and 1 with the face).
11: 10-node second order tetrahedron (4 nodes associated with the vertices and
    6 with the edges).
12: 27-node second order hexahedron (8 nodes associated with the vertices,
    12 with the edges, 6 with the faces and 1 with the volume).
13: 18-node second order prism (6 nodes associated with the vertices,
    9 with the edges and 3 with the quadrangular faces).
14: 14-node second order pyramid (5 nodes associated with the vertices,
    8 with the edges and 1 with the quadrangular face).
15: 1-node point.
16: 8-node second order quadrangle (4 nodes associated with the vertices and
    4 with the edges).
17: 20-node second order hexahedron (8 nodes associated with the vertices and
    12 with the edges).
18: 15-node second order prism (6 nodes associated with the vertices and 9
    with the edges).
19: 13-node second order pyramid (5 nodes associated with the vertices
    and 8 with the edges).
20: 9-node third order incomplete triangle (3 nodes associated with the
    vertices, 6 with the edges)
21: 10-node third order triangle (3 nodes associated with the vertices,
    6 with the edges, 1 with the face)
22: 12-node fourth order incomplete triangle (3 nodes associated with the
    vertices, 9 with the edges)
23: 15-node fourth order triangle (3 nodes associated with the vertices,
    9 with the edges, 3 with the face)
24: 15-node fifth order incomplete triangle (3 nodes associated with the vertices,
    12 with the edges)
25: 21-node fifth order complete triangle (3 nodes associated with the vertices,
    12 with the edges, 6 with the face)
26: 4-node third order edge (2 nodes associated with the vertices, 2 internal
    to the edge)
27: 5-node fourth order edge (2 nodes associated with the vertices, 3 internal
    to the edge)
28: 6-node fifth order edge (2 nodes associated with the vertices, 4 internal
    to the edge)
29: 20-node third order tetrahedron (4 nodes associated with the vertices,
    12 with the edges, 4 with the faces)
30: 35-node fourth order tetrahedron (4 nodes associated with the vertices,
    18 with the edges, 12 with the faces, 1 in the volume)
31: 56-node fifth order tetrahedron (4 nodes associated with the vertices,
    24 with the edges, 24 with the faces, 4 in the volume)
92: 64-node third order hexahedron (8 nodes associated with the vertices,
    24 with the edges, 24 with the faces, 8 in the volume)
93: 125-node fourth order hexahedron (8 nodes associated with the vertices,
    36 with the edges, 54 with the faces, 27 in the volume)

@ 2019 Christian Schubert
mod by dominik.bueschgens jan 2021
=#
# using FEMMesh

#export readGMSH
#export GMSH

elementTypeID_NodeCount = [2,3,4,4,8,6,5,3,6,9,10,27,18,14,1,8,20,15,13,9,10,12,15,25,21,
                        4,5,6,20,35,56]

#ergänzen
elementType_TypeID = Dict([("L2", 1), ("Tri3", 2), ("Quad4", 3), ("Tet4", 4),
                    ("Hex8", 5), ("L3", 8), ("Tri6", 9), ("Quad9", 10), ("Tet10", 11),
                    ("Hex27", 12)])

gmsh_tag_type= Dict([("Point", 0), ("Curve", 1), ("Surface", 2), ("Volume", 3)])


struct GMSHFileInfo
    version_number::Float64
    file_type::Int
    data_size::Int
end

struct PhysicalEntity
    type::Int
    number::Int
    name::String
end

struct PhysicalEntities
    count::Int
    entities::Array{PhysicalEntity,1}
    PhysicalEntities() = new()
end

    
struct Point{T1<:Int, T2<:Real}
    pointTag::T1
    x::T2
    y::T2
    z::T2
    numPhysicalTags::T1
    physicalTag::Array{T1,1}
end

struct Curve{T1<:Int, T2<:Real}
    curveTag::T1
    xmin::T2
    ymin::T2
    zmin::T2
    xmax::T2
    ymax::T2
    zmax::T2
    numPhysicalTags::T1
    physicalTag::Array{T1,1}
    numBoundingPoints::T1
    pointTag::Array{T1,1}
end

struct Surface{T1<:Int, T2<:Real}
    surfaceTag::T1
    xmin::T2
    ymin::T2
    zmin::T2
    xmax::T2
    ymax::T2
    zmax::T2
    numPhysicalTags::T1
    physicalTag::Array{T1,1}
    numBoundingCurves::T1
    curveTag::Array{T1,1}
end

struct Volume{T1<:Int, T2<:Real}
    volumeTag::T1
    xmin::T2
    ymin::T2
    zmin::T2
    xmax::T2
    ymax::T2
    zmax::T2
    numPhysicalTags::T1
    physicalTag::Array{T1,1}
    numBoundingSurfaces::T1
    surfaceTag::Array{T1,1}
end

#Nun werden die structs zusammengefasst
    
struct MeshEntities
    points::Array{Point, 1}
    curves::Array{Curve, 1}
    surfaces::Array{Surface, 1}
    volumes::Array{Volume}
end

#leere structs für die Knoten, Linien Flächen, Volumina
    
mutable struct Nodes{T1<:Int, T2<:Real}
    num::Vector{T1}
    x::Vector{T2}
    y::Vector{T2}
    z::Vector{T2}
    noEntities::Vector{T1}
    entityTypeID::Vector{T1}
    entityTag::Vector{T1}
end

struct Element
    number::Int
    nodes::Array{Int,1}
end

#Fasst die Details der Elemente zusammen
    
struct ElementGroup
    entityTag::Int
    entityTypeID::Int
    elementTypes::Int
    count::Int
    elements::Array{Element,1}
end

#Fasst die Informationen/Structs des Meshs zusammen
    
struct GMSH
    info::GMSHFileInfo
    pyhysical_entities::PhysicalEntities
    mesh_entities::MeshEntities
    nodes::Nodes
    element_groups::Array{ElementGroup,1}
end

#    Hier klappt was nicht
#    filename = "t1.msh"
function readGMSH(filename::String)
    io = open(filename, "r")
    blockTypes, blocks = loopGMSHFileBlockSections(io)
    gmsh = evaluatGMSHBlockSections(blockTypes, blocks)

    return gmsh
end
#speichert den Inhalt der Code Linien

function loopGMSHFileBlockSections(io)

    blocks = String[]
    blockTypes = String[]
    iobuff = IOBuffer(UInt8[], read=true, write=true, append=true)

    for line in eachline(io)
        if line[1] =='$'

            if line[1:4] == "\$End"
                push!(blocks, read(iobuff,String))
            else
                push!(blockTypes, line)
            end

            flush(iobuff)
        else
            write(iobuff, line * "\n")
        end
    end

    return blockTypes, blocks
end

#Daten für die einzelnen Abschnitte 

function evaluatGMSHBlockSections(blockTypes::Array{String,1}, blocks)
    fileInfo=[]
    gmshPhysicalEntities=[]
    entities=[]
    nodes=[]
    elementGroups=[]

    for i=1:size(blockTypes,1)
        println(blockTypes[i])

        blockLines = split(blocks[i], "\n")
        blockLines = blockLines[blockLines .!= ""]

        if blockTypes[i] == "\$MeshFormat"
            fileInfo = evalMeshFormat(blockLines)
            println("File Version:",fileInfo.version_number)
            println("File Type:",fileInfo.file_type)
            println("Data Size:",fileInfo.data_size)

        elseif blockTypes[i] == "\$PhysicalNames"
            gmshPhysicalEntities = evalPhysicalNames(blockLines)
            println("physical names given")

        elseif blockTypes[i] == "\$Entities"
            entities = evalEntities(blockLines)

        elseif blockTypes[i] == "\$Nodes"
            nodes = evalNodesBlock(blockLines)

        elseif blockTypes[i] == "\$Elements"
            elementGroups = evalElementsBlock(blockLines)

        end
    end

    # hier eingefügt da wenn nicht belegt fehler - D
    if isempty(gmshPhysicalEntities)
        #@show gmshPhysicalEntities
        # hier eingefügt da 
        gmshPhysicalEntities = PhysicalEntities()
        #@show gmshPhysicalEntities
    end

    gmsh = GMSH(fileInfo, gmshPhysicalEntities, entities, nodes, elementGroups)

    return gmsh
end

# könnte Probleme machen, "blockContent?", liest MeshFormat aus    
    
function evalMeshFormat(blockContent::Array{SubString{String},1})

    if size(blockContent,1) <= 1
        s = split(blockContent[1], " ")

        # println("GMSHFileInfo: ", s[1], "  ",  s[2], "  ", s[3])

        fileInfo = GMSHFileInfo(parse(Float64, s[1]), parse(Int64, s[2]), parse(Int64, s[3]))

    else
        @error "Uknown size of MeshFormat Block in GMSHreader!"
    end

    return fileInfo
end

# Liest PhysicalNames aus    

function evalPhysicalNames(blockContent::Array{SubString{String},1})

    count = parse(Int64,blockContent[1])
    entitiesBlock = blockContent[2:end]
    entities = Array{PhysicalEntity,1}(undef, size(entitiesBlock,1));

    for i = 1 : size(entitiesBlock,1)
        s = split(entitiesBlock[i], r" ")

        if size(s,1) > 3
            name = join(s[3:size(s,1)])
        else
            name = s[3];
        end

        entities[i] = PhysicalEntity(parse(UInt8, s[1]), parse(Int64, s[2]), name)
    end

    gmshPhysicalEntities = PhysicalEntities(parse(Int64, blockContent[1]) ,entities)
    return gmshPhysicalEntities
end

# liest Entities aus
    
function evalEntityBlock(BlockContent::Array{SubString{String},1}, type::Int64)
    #=
    Entity Block String eval:
    type:
    1: Point
    2: Curve
    3: Surface
    4: volume
    =#

    # @show type

    if type == gmsh_tag_type["Point"]
        Entity = Array{Point,1}(undef, size(BlockContent,1))
    elseif type == gmsh_tag_type["Curve"]
        Entity = Array{Curve,1}(undef, size(BlockContent,1))
    elseif type == gmsh_tag_type["Surface"]
        Entity = Array{Surface,1}(undef, size(BlockContent,1))
    elseif type == gmsh_tag_type["Volume"]
        Entity = Array{Volume,1}(undef, size(BlockContent,1))
    else
        @error "unknow type"
    end

    for i=1:1:size(BlockContent,1)
        s = split(BlockContent[i], " ")
        # @show s

        tag = parse(Int64, s[1])

        if type == gmsh_tag_type["Point"]
            x = parse(Float64, s[2])
            y = parse(Float64, s[3])
            z = parse(Float64, s[4])

            # 8 = Bug in GMSH Doku oder Implementierung für Points...
            # Doku:
            # http://gmsh.info/doc/texinfo/gmsh.html#MSH-file-format
            #=
            pointTag(int) X(double) Y(double) Z(double)
            numPhysicalTags(size_t) physicalTag(int) ...
            ...
            Allerdings sind x y z doppelt besetzt ...
            =#
        else
            xmin = parse(Float64, s[2])
            ymin = parse(Float64, s[3])
            zmin = parse(Float64, s[4])
            xmax = parse(Float64, s[5])
            ymax = parse(Float64, s[6])
            zmax = parse(Float64, s[7])
        end

        if type == gmsh_tag_type["Point"]
            # points ist etwas anders -> abfrage hier eingefügt D
            numPhysicalTags = parse(Int64, s[5])
            physicalTag = Array{Int,1}(undef, numPhysicalTags)
        else
            numPhysicalTags = parse(Int64, s[8])
            physicalTag = Array{Int,1}(undef, numPhysicalTags)
        end

        if numPhysicalTags > 0
            m = 1
            for k=9:1:(8+numPhysicalTags)
                physicalTag[m] = parse(Int64, s[k]) #bestimmt die Tags der Entities
                m += 1
            end
        end

        if type != gmsh_tag_type["Point"]
            numBoundingElements = parse(Int64, s[9+numPhysicalTags])
            boundingElementTag = Array{Int64,1}(undef, numBoundingElements)

            if numBoundingElements > 0
                m = 1
                for k=(10+numPhysicalTags):1:(9+numPhysicalTags+numBoundingElements) #liest die Grenzelemente für jede Entität aus
                    boundingElementTag[m] = parse(Int64, s[k])
                    m += 1
                end
            end
        end

        if type == gmsh_tag_type["Point"]
            Entity[i] = Point(tag, x, y, z, numPhysicalTags, physicalTag)
        elseif type == gmsh_tag_type["Curve"]
            Entity[i] = Curve(tag, xmin, ymin, zmin, xmax, ymax, zmax,
                        numPhysicalTags, physicalTag, numBoundingElements,
                        boundingElementTag)
        elseif type == gmsh_tag_type["Surface"]
            Entity[i] = Surface(tag, xmin, ymin, zmin, xmax, ymax, zmax,
                        numPhysicalTags, physicalTag, numBoundingElements,
                        boundingElementTag)

        elseif type == gmsh_tag_type["Volume"]
            Entity[i] = Volume(tag, xmin, ymin, zmin, xmax, ymax, zmax,
                        numPhysicalTags, physicalTag, numBoundingElements,
                        boundingElementTag)
        end
    end

    return Entity
end


function evalEntities(blockContent::Array{SubString{String},1})
    s = split(blockContent[1], " ")

    if size(s,1) == 4  #Liest die Anzahl der jeweiligen Entitäten aus
        numPoints = parse(Int64, s[1])
        numCurves = parse(Int64, s[2])
        numSurfaces = parse(Int64, s[3])
        numVolumes = parse(Int64, s[4])

        # hier hoch kopiert
        println("Points ", numPoints, " / Curves ", numCurves, " / Surfaces ", numSurfaces, " / Volumes ", numVolumes)

        numAllEntities = numPoints+numCurves+numSurfaces+numVolumes

        if size(blockContent,1) == (1+numAllEntities) #liest die jeweilige Gruppe Entitäten aus
            Points = evalEntityBlock(blockContent[2:(numPoints+1)],
                                        gmsh_tag_type["Point"])
            Curves = evalEntityBlock(blockContent[(numPoints+2):(numPoints+numCurves+1)],
                                        gmsh_tag_type["Curve"])
            Surfaces = evalEntityBlock(blockContent[(numPoints+numCurves+2):(numPoints+numCurves+numSurfaces+1)],
                                        gmsh_tag_type["Surface"])
            Volumes = evalEntityBlock(blockContent[(numPoints+numCurves+numSurfaces+2):(numPoints+numCurves+numSurfaces+numVolumes+1)],
                                        gmsh_tag_type["Volume"])

            entities = MeshEntities(Points, Curves, Surfaces, Volumes)
            
            return entities
        else
            @error "Wrong number of lines in entities block"
        end
        
        println(numPoints, numCurves, numSurfaces, numVolumes)

    else
        @error "Unknown size of first line in entities block"
    end

end

function evalNodesBlock(blockContent::Array{SubString{String},1})
    println("evalNodes");
    #=
        size(blockContent[2:end]) - numEntities == numNodes
        that means that each Node is exclusive to its entity no double entities for nodes!
    =#

    # erste zeile gibt Informationen
    s = split(blockContent[1], " ")
    numEntities = parse(Int64, s[1]) #Anzahl Entitäten
    numNodes = parse(Int64, s[2]) #Anzahl Knoten

    println("numEntities: ", numEntities)
    println("numNodes: ", numNodes)

    x = zeros(Real, numNodes)
    y = zeros(Real, numNodes)
    z = zeros(Real, numNodes)
    nodenum = zeros(Int64, numNodes)
    nenteties = zeros(Int64, numNodes)
    ckecked = falses(numNodes)
    entityTags = zeros(Int64, numNodes)
    entityTypeIDs = zeros(Int64, numNodes)

    offset = 2;
    ni = 1 # node id for counting
    for i = 1:numEntities

        # aufbau
        # entity title
        # all node numbers 
        # all coords

        # entity title
        si = split(blockContent[offset], " ")

        #@show si

        entityTag = parse(Int64, si[1]) #Art
        entityTypeID = parse(Int64, si[2]) #Nummer der Art
        # si[3] = 0 -> no parametric coordinates
        numEntityNodes = parse(Int64, si[end]) #Anzahl Knoten

        # block with all node numbers of entity
        blockNodesNum = blockContent[(offset+1):(offset+numEntityNodes)]
        #@show blockNodesNum
        #println("Nodes in entity: ", i, ", ", size(blockNodesNum, 1))#wie viele Knoten in welcher Entität
        #println("Size blockNodes: ", size(blockNodesNum))
        println("Node entity ", i, " has ", size(blockNodesNum,1), " nodes")

        # block with all node coords of entity
        blockNodesCoords = blockContent[(offset+1+numEntityNodes):(offset+numEntityNodes+numEntityNodes)]
        #@show blockNodesCoords

        # nodenumber der entity lesen
        # da ni hier und unten, hier oben nur hilfsgröße bzw hilfscounter
        ni_temp = ni
        for si in blockNodesNum #Wie bitte, was?
            #@show si
            sj = split(si, " ")
            #@show sj
            node = parse(Int64, sj[1])

            #@show node

            if ckecked[ni_temp]
                @warn "dual cells checked, should not happen"
            else
                ckecked[ni_temp] = true
            end

            nodenum[ni_temp] = node #Gibt die zugehörigen Koordinaten pro Knoten aus

            # x[ni] = parse(Float64, sj[2])
            # y[ni] = parse(Float64, sj[3])
            # z[ni]= parse(Float64, sj[4])
            nenteties[ni_temp] += 1
            entityTypeIDs[ni_temp] = entityTypeID
            entityTags[ni_temp] = entityTag

            ni_temp += 1
        end

        # get coords - new here
        for si in blockNodesCoords #Wie bitte, was?
            #@show si
            sj = split(si, " ")
            #@show sj

            x[ni] = parse(Float64, sj[1])
            y[ni] = parse(Float64, sj[2])
            z[ni]= parse(Float64, sj[3])

            #@show z[ni]

            ni += 1
        end

        #offset = offset + numEntityNodes + 1
        offset = offset + numEntityNodes + numEntityNodes + 1
    end

    p = sortperm(nodenum)

    nodes = Nodes(nodenum[p], x[p], y[p], z[p], nenteties[p], entityTypeIDs[p], #Gibt die Knoten aus
                    entityTags[p])

    # @show size(nodenum)
    # @show size(x)
    # @show size(y)
    # @show size(z)
    # @show size(nenteties)
    # @show size(entityTypeIDs)
    # @show size(entityTags)

    return nodes
end


function evalElementLine(blockContent::SubString{String}, elementTypeID::Int) #Bin mir nicht sicher
    s = split(blockContent, " ")
    s = s[s .!= ""]

    no_nodes =  elementTypeID_NodeCount[elementTypeID]
    number = parse(Int64, s[1])

    if no_nodes == size(s[2:end],1)
        nodes = Array{Int,1}(undef, no_nodes)

        for i = 1:no_nodes
            nodes[i] = parse(Int64,s[i+1])
        end

        element = Element(number, nodes) #ordnet Elementen ihre Nummer und ihre Knoten zu
        return element
    else
        @error "Element Type Node Count not equal Found Nodes"
    end

end


function evalElementBlock(blockContent::Array{SubString{String},1},entityTag::Int,
                     entityTypeID::Int, numEntityElements::Int, elementTypeID::Int64)

    elements = Array{Element, 1}(undef, numEntityElements)

    for i=1:1:numEntityElements
        elements[i] = evalElementLine(blockContent[i], elementTypeID) #Gibt Elemente aus mit Art des Elements und weiteren daten
    end

    elementGroup = ElementGroup(entityTag, entityTypeID, elementTypeID,
                                                numEntityElements, elements)

    return elementGroup
end


function evalElementsBlock(blockContent::Array{SubString{String},1})
    println("evalElements");

    s = split(blockContent[1], " ")
    numEntities = parse(Int64, s[1])
    numElements = parse(Int64, s[2])

    println("numEntities: ", numEntities)
    println("numElements: ", numElements)

    elementGroups = Array{ElementGroup,1}(undef, numEntities)

    offset = 2;
    for i = 1:numEntities

        si = split(blockContent[offset], " ")
        entityTag = parse(Int64, si[1])
        entityTypeID = parse(Int64, si[2])
        elementTypeID = parse(Int64, si[3])
        numEntityElements = parse(Int64, si[end])

        println("Elements entity ", i, " has ", numEntityElements, " elements")

        elementGroups[i] = evalElementBlock(blockContent[offset+1:offset+numEntityElements], #Entities mit Elementen
                            entityTag, entityTypeID, numEntityElements, elementTypeID)

        offset = offset + numEntityElements + 1
    end

    return elementGroups

end


#end
