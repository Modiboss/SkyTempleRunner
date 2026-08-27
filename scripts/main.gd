extends Node3D

var runner: Runner
var next_z := 0.0
var segments: Array[Node3D] = []
var rng := RandomNumberGenerator.new()
const SEGMENT_LENGTH := 28.0
const SEGMENTS_AHEAD := 10

func _ready():
    rng.randomize()
    _make_environment()
    _make_runner()
    for i in SEGMENTS_AHEAD:
        _make_segment(i * SEGMENT_LENGTH)

func _process(_delta):
    if not runner: return
    while next_z < runner.position.z + SEGMENTS_AHEAD * SEGMENT_LENGTH:
        _make_segment(next_z)
    for s in segments.duplicate():
        if s.position.z < runner.position.z - 60:
            segments.erase(s)
            s.queue_free()

func _make_environment():
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color("#68cbed")
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color("#d9f4ff")
    e.ambient_light_energy = 0.8
    env.environment = e
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50,-25,0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)

    var cam := Camera3D.new()
    cam.position = Vector3(0,4.2,-7.5)
    cam.current = true
    add_child(cam)

func _make_runner():
    runner = Runner.new()
    runner.position = Vector3(0,1,0)
    add_child(runner)

    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = .38
    capsule.height = 1.8
    shape.shape = capsule
    runner.add_child(shape)

    var mesh := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = .38
    capsule_mesh.height = 1.8
    mesh.mesh = capsule_mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#e94e43")
    mesh.material_override = mat
    runner.add_child(mesh)

func _make_segment(z:float):
    var root := Node3D.new()
    root.position.z = z
    add_child(root)
    segments.append(root)
    next_z = max(next_z, z + SEGMENT_LENGTH)

    var road := MeshInstance3D.new()
    var road_mesh := BoxMesh.new()
    road_mesh.size = Vector3(9,.25,SEGMENT_LENGTH)
    road.mesh = road_mesh
    road.position.y = -.15
    var road_mat := StandardMaterial3D.new()
    road_mat.albedo_color = Color("#3f4a51")
    road.material_override = road_mat
    root.add_child(road)

    for side in [-1,1]:
        _make_tree(root, side*6.2, 4)
        _make_pillar(root, side*5.2, 11)

    if rng.randf() < .75:
        _make_obstacle(root, [-1,0,1][rng.randi_range(0,2)], 8)
    if rng.randf() < .9:
        var lane := [-1,0,1][rng.randi_range(0,2)]
        for i in 5: _make_coin(root, lane, 3 + i*1.7)

func _make_tree(root,x,z):
    var trunk := MeshInstance3D.new()
    var b := BoxMesh.new(); b.size=Vector3(.35,2.4,.35); trunk.mesh=b
    trunk.position=Vector3(x,1.1,z)
    var tm:=StandardMaterial3D.new(); tm.albedo_color=Color("#704b32"); trunk.material_override=tm
    root.add_child(trunk)
    var crown:=MeshInstance3D.new()
    var s:=SphereMesh.new(); s.radius=1.4; s.height=2.8; crown.mesh=s
    crown.position=Vector3(x,2.7,z)
    var cm:=StandardMaterial3D.new(); cm.albedo_color=Color("#2d7b48"); crown.material_override=cm
    root.add_child(crown)

func _make_pillar(root,x,z):
    var p:=MeshInstance3D.new()
    var b:=BoxMesh.new(); b.size=Vector3(.8,3.5,.8); p.mesh=b
    p.position=Vector3(x,1.75,z)
    var m:=StandardMaterial3D.new(); m.albedo_color=Color("#c99b62"); p.material_override=m
    root.add_child(p)

func _make_obstacle(root,lane,z):
    var o:=StaticBody3D.new()
    o.position=Vector3(lane*2.4,.75,z)
    var cs:=CollisionShape3D.new()
    var sh:=BoxShape3D.new(); sh.size=Vector3(1.4,1.5,1.2); cs.shape=sh
    o.add_child(cs)
    var mesh:=MeshInstance3D.new()
    var box:=BoxMesh.new(); box.size=Vector3(1.4,1.5,1.2); mesh.mesh=box
    var m:=StandardMaterial3D.new(); m.albedo_color=Color("#c9543d"); mesh.material_override=m
    o.add_child(mesh); root.add_child(o)

func _make_coin(root,lane,z):
    var c:=Area3D.new()
    c.position=Vector3(lane*2.4,1.4,z)
    var cs:=CollisionShape3D.new()
    var sh:=SphereShape3D.new(); sh.radius=.32; cs.shape=sh
    c.add_child(cs)
    var mesh:=MeshInstance3D.new()
    var cyl:=CylinderMesh.new(); cyl.top_radius=.28; cyl.bottom_radius=.28; cyl.height=.08; mesh.mesh=cyl
    var m:=StandardMaterial3D.new(); m.albedo_color=Color("#ffd32f"); m.metallic=.55; mesh.material_override=m
    c.add_child(mesh)
    c.body_entered.connect(func(body):
        if body == runner: c.queue_free()
    )
    root.add_child(c)
