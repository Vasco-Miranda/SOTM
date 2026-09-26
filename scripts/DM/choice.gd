class_name Choice
extends Resource

# --- Core identification ---
@export var id: String
@export var text: String

# --- Context ---
@export var character: String = "" # Who the choice affects
@export var clue: String = "" # Clue related to the choice, optional

# --- Emotional impact ---
@export var stress_delta: float = 0.0
@export var confusion_delta: float = 0.0
@export var self_doubt_delta: float = 0.0

# --- Social impact ---
@export var affinity_delta: float = 0.0
@export var blame_delta: float = 0.0

# --- Cognitive impact ---
@export var clue_focus: float = 0.0 # Increases importance of a clue

# --- Behavioral metrics ---
@export var expected_time: float = 1.5 # Expected decision time, in seconds
@export var hesitation_weight: float = 0.5
@export var time_taken_weight: float = 0.0

# --- Optional tags for AI / Drama Manager ---
@export var tags: Array[String] = []
# Probe, deflect, empathetic, reassure, pressure, evidence, accusation, self-incriminate, flirt, family

# --- Conditions (optional gating) ---
@export var required_flags: Array[String] = []
@export var blocked_flags: Array[String] = []
