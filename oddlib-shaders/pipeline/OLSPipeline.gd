extends ViewportContainer
# Still really early and lacks most of the functionnality.

func Setup():
	pass




# -------------

func AddBuffer(bufferName, bufferType = "Unspecified"):
	var vp = Viewport.new()
	vp.set_name(bufferName)
	add_child(vp)
	var bufInfo = {
		"Name":bufferName, "Type":bufferType,
		"Viewport":vp
	}
	_buffers[bufferName] = bufInfo
	vp.set_handle_input_locally(false)
	vp.set_update_mode(Viewport.UPDATE_ALWAYS)
	vp.set_keep_3d_linear(true)
	vp.set_hdr(false)
	return bufInfo

func AddPGBuffer(bufferName, lit=true, layerMask = null):
	var _buf = AddBuffer(bufferName, ("PGBuffer" if lit else "PGBufferUnshaded"))
	var _cam = AddRenderCam(bufferName+"-Camera", bufferName, layerMask)

func Add2DBuffer(_bufferName, _bufferMaterial, _bufferType="Generic 2D"): #TODO
	pass

func AddCombinerBuffer(bufferName, _combinedBuffers, _combinerTexture = null): #TODO
	# If texture == null; use alpha
	var _buf = Add2DBuffer(bufferName, null, "Combiner Buffer")

func AddRenderCam(cameraName, bufferName, _layerMask = null): #TODO
	var buf = GetBuffer(bufferName)
	var cam = Camera.new()
	cam.set_name(cameraName)
	buf["Viewport"].add_child(cam)
	
	var camInfo = {
		"Camera":cam, "BufferName":bufferName
	}
	_cameras[cameraName] = camInfo
	return camInfo

# Global Parameters for the shader
func AddParameter(parameterName, internalName, bufferName = null): # TODO
	var paramInfo = {
		"Name":parameterName, "InternalName":internalName,
		"BufferName":bufferName
	}
	_params[parameterName] = paramInfo
	return paramInfo
func SetParameter(parameterName, value):
	var p = _params[parameterName]
	var mat = get_material()
	mat.set_shader_param(p["InternalName"], value)

func AddParameterVPTexture(parameterName, internalName, vpTexBufferName, bufferName = null):
	AddParameter(parameterName, internalName, bufferName)
	SetParameterVPTexture(parameterName, vpTexBufferName)
func SetParameterVPTexture(parameterName, vpTexBufferName):
	SetParameter(parameterName, _buffers[vpTexBufferName]["Viewport"].get_texture())


func GetBuffer(bufferName):
	return _buffers[bufferName]
func GetCamera(cameraName):
	return _cameras[cameraName]

func DebugGetName():
	return "Unspecified"

func DebugGetDebugModes():
	return {"Normal View":[]}


# --------------------------

var _buffers = {}
var _cameras = {}
var _params = {}


func _ready():
	OddLib.Pipeline = self
	#set_material(get_material().duplicate())
	#get_material().setup_local_to_scene()
	set_stretch(true)
	Setup()
	
	# Needs a window resize signal to update the viewport hierarchy for some reason. TODO : Find a better way
	var windowSize = OS.get_window_size()
	_bootlegResizerSize = windowSize
	OS.set_window_size(windowSize - Vector2(1,1))
	_bootlegResizerTimer = 0.2
	#OS.set_borderless_window(true)
	#OS.set_window_fullscreen(true)
	#OS.call_deferred("set_window_size",windowSize)
	#call_deferred("set_size", Vector2(1.0,1.0), true)
	#call_deferred("Setup")

var _bootlegResizerTimer = 0.0
var _bootlegResizerSize = Vector2(64,64)
func _process(delta):
	if(_bootlegResizerTimer > 0.0):
		_bootlegResizerTimer -= delta
		if(_bootlegResizerTimer <= 0.0):
			OS.set_window_size(_bootlegResizerSize)
