extends Node

## ParticleFactory - Utility for spawning reusable particle effects
## Creates hit sparks, death explosions, and other visual feedback

class_name ParticleFactory

# Particle colors
const COLORS = {
	"hit": Color(1.0, 0.9, 0.5, 1.0),       # Yellow/gold hit spark
	"fire": Color(1.0, 0.5, 0.1, 1.0),      # Orange fire
	"ice": Color(0.5, 0.8, 1.0, 1.0),       # Light blue ice
	"lightning": Color(0.8, 0.7, 1.0, 1.0), # Purple lightning
	"nature": Color(0.5, 1.0, 0.5, 1.0),    # Green nature
	"death": Color(0.8, 0.2, 0.2, 1.0),     # Red death
	"xp": Color(0.2, 1.0, 0.4, 1.0),        # Green XP
}

static func spawn_hit_particles(parent: Node, position: Vector2, count: int = 5, color: Color = COLORS.hit) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = count
	particles.lifetime = 0.3
	particles.explosiveness = 1.0
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3(0, 200, 0)
	material.scale_min = 1.0
	material.scale_max = 2.0
	material.color = color
	
	particles.process_material = material
	
	# Add to parent and auto-remove
	parent.add_child(particles)
	particles.finished.connect(particles.queue_free)
	
	return particles

static func spawn_death_particles(parent: Node, position: Vector2, scale_mult: float = 1.0) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 12
	particles.lifetime = 0.5
	particles.explosiveness = 1.0
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 8.0 * scale_mult
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 150.0
	material.gravity = Vector3(0, 300, 0)
	material.scale_min = 2.0 * scale_mult
	material.scale_max = 4.0 * scale_mult
	material.color = COLORS.death
	
	# Fade out
	var color_ramp = Gradient.new()
	color_ramp.add_point(0.0, COLORS.death)
	color_ramp.add_point(1.0, Color(COLORS.death.r, COLORS.death.g, COLORS.death.b, 0.0))
	material.color_ramp = color_ramp
	
	particles.process_material = material
	
	parent.add_child(particles)
	particles.finished.connect(particles.queue_free)
	
	return particles

static func spawn_xp_glow(parent: Node, position: Vector2) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = false
	particles.amount = 3
	particles.lifetime = 1.0
	particles.preprocess = 0.5
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.direction = Vector3(0, -1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 20.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 1.0
	material.scale_max = 2.0
	material.color = COLORS.xp
	
	# Fade out
	var color_ramp = Gradient.new()
	color_ramp.add_point(0.0, Color(COLORS.xp.r, COLORS.xp.g, COLORS.xp.b, 0.5))
	color_ramp.add_point(1.0, Color(COLORS.xp.r, COLORS.xp.g, COLORS.xp.b, 0.0))
	material.color_ramp = color_ramp
	
	particles.process_material = material
	
	parent.add_child(particles)
	
	return particles

static func spawn_weapon_trail(parent: Node, color: Color = COLORS.fire) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = false
	particles.amount = 8
	particles.lifetime = 0.3
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.direction = Vector3(0, 0, 0)
	material.spread = 0.0
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3.ZERO
	material.scale_min = 1.5
	material.scale_max = 3.0
	material.color = color
	
	# Fade out
	var color_ramp = Gradient.new()
	color_ramp.add_point(0.0, color)
	color_ramp.add_point(1.0, Color(color.r, color.g, color.b, 0.0))
	material.color_ramp = color_ramp
	
	# Size curve - shrink over time
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0, 1))
	scale_curve.add_point(Vector2(1, 0.2))
	material.scale_curve = scale_curve
	
	particles.process_material = material
	
	parent.add_child(particles)
	
	return particles
