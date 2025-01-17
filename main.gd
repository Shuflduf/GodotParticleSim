extends Node2D

@export var playing: bool
@export var gravity: float
@export var particle_size: float
@export var smoothing_radius: float
@export var particle_spacing: float
@export_range(0.0, 1.0) var collision_damping: float
@export_range(2, 500) var num_particles: int
@export var bounds_size: Vector2

var particle_positions: Array[Vector2]
var particle_velocities: Array[Vector2]
var densities: Array[float]

func _ready() -> void:
    particle_positions.resize(num_particles)
    particle_velocities.resize(num_particles)

    var particles_per_row = int(sqrt(num_particles))
    @warning_ignore("integer_division")
    var particles_per_col = (num_particles - 1) / particles_per_row + 1
    var spacing = particle_size * 2 + particle_spacing

    for i in num_particles:
        var x = (i % particles_per_row - particles_per_row / 2.0 + 0.5) * spacing
        @warning_ignore("integer_division")
        var y = (i / particles_per_row - particles_per_col / 2.0 + 0.5) * spacing
        particle_positions[i] = Vector2(x, y)
        particle_velocities[i] = Vector2.ZERO


func _process(delta: float) -> void:
    if playing:
        for i in particle_positions.size():
            particle_velocities[i] += Vector2.DOWN * gravity * delta
            particle_positions[i] += particle_velocities[i] * delta
            resolve_collisions(i)
    else:
        _ready()

    queue_redraw()

func _draw() -> void:
    for i in particle_positions.size():
        draw_circle(particle_positions[i], particle_size, Color.LIGHT_BLUE)
    draw_rect(Rect2(-bounds_size.x / 2, -bounds_size.y / 2, bounds_size.x, bounds_size.y), Color.BLUE, false, 1.0)

func update_densities():
    for i in num_particles:
        densities[i] = calculate_density(particle_positions[i])

func resolve_collisions(index: int):
    var half_bounds_size = bounds_size / 2 - Vector2.ONE * particle_size
    if abs(particle_positions[index].x) > half_bounds_size.x:
        particle_positions[index].x = half_bounds_size.x * sign(particle_positions[index].x)
        particle_velocities[index].x *= -collision_damping
    if abs(particle_positions[index].y) > half_bounds_size.y:
        particle_positions[index].y = half_bounds_size.y * sign(particle_positions[index].y)
        particle_velocities[index].y *= -collision_damping

static func smoothing_kernel(radius: float, dst: float) -> float:
    if dst >= radius:
        return 0.0

    var volume = PI * pow(radius, 4) / 6
    return (radius - dst) * (radius - dst) / volume

static func smoothing_kernel_derivative(dst: float, radius: float) -> float:
    if dst >= radius:
        return 0
    var p_scale = -12 / (PI * pow(radius, 4))
    return (dst - radius) * p_scale

func calculate_density(point: Vector2) -> float:
    var density = 0.0
    const MASS = 1.0

    for pos in particle_positions:
        var dst = (pos - point).length()
        var influence = smoothing_kernel(smoothing_radius, dst)
        density += MASS * influence

    return density

func calculate_property_gradient(point: Vector2) -> Vector2:
    var property_gradient = Vector2.ZERO

    for i in particle_positions.size():
        var dst = (particle_positions[i] - point).length()
        var dir = (particle_positions[i] - point) / dst
        var slope = smoothing_kernel_derivative(dst, smoothing_radius)
        var density = densities[i]
        property_gradient += part
