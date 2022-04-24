extends ViewportContainer
# TODO params
# TODO redo pi and aquarelle in this
# TODO Auto debug mode
# TODO stop render
# TODO add PG fixed buffer
# todo note: texelfetch
# TODO Refresh

func Setup():
	pass

var _envPGBufferLit = preload("res://oddlib-shaders/pipeline/PGBufferLit-Environement.tres")


func DebugGetName():
	return "Unspecified"
func DebugGetDebugModes():
	return {"Normal View":[]}

func OnRefresh():
	pass




# -------------

func AddBuffer(bufferName, bufferParams = null):
	var vp = Viewport.new()
	vp.set_name(bufferName)
	add_child(vp)
	
	_sizeChangedNodes.append(vp)
	
	var bufferType = _Get(bufferParams, "BufferType", "Unspecified")
	var unshaded = _Get(bufferParams, "Unshaded", false)
	vp.set_debug_draw((Viewport.DEBUG_DRAW_UNSHADED if unshaded else Viewport.DEBUG_DRAW_DISABLED))
	
	var bufInfo = {
		"Name":bufferName, "BufferType":bufferType,
		"Viewport":vp, "MaterialNode": _Get(bufferParams, "MaterialNode", null),
	}
	
	_buffers[bufferName] = bufInfo
	vp.set_handle_input_locally(false)
	vp.set_update_mode(Viewport.UPDATE_ALWAYS)
	vp.set_keep_3d_linear(true)
	vp.set_hdr(false)
	vp.set_transparent_background(true)
	#vp.set_size_override(true, Vector2(1980, 1080))
	vp.set_size_override(true, get_size())
	return bufInfo

func AddPGBuffer(bufferName, lit=true, bufferParams = null, camParams = null):
	if(bufferParams == null):
		bufferParams = {}
	bufferParams["BufferType"] = _Get(bufferParams, "BufferType", ("PGBuffer" if lit else "PGBufferUnshaded"))
	bufferParams["Unshaded"] = !lit
	
	if(camParams == null):
		camParams = {}
	camParams["Environment"] = _envPGBufferLit
	
	var _buf = AddBuffer(bufferName, bufferParams)
	var _cam = AddRenderCam(bufferName+"-Camera", bufferName, camParams)

func Add2DBuffer(bufferName, bufferMaterial, _bufferType="Generic 2D"): #TODO
	var controlNode = ColorRect.new()
	var buf = AddBuffer(bufferName, {"MaterialNode":controlNode})
	buf["Viewport"].add_child(controlNode)
	_sizeChangedNodes.append(controlNode)
	controlNode.set_material(bufferMaterial)

func AddCombinerBuffer(bufferName, _combinedBuffers, _combinerTexture = null): #TODO
	# If texture == null; use alpha
	var _buf = Add2DBuffer(bufferName, null, "Combiner Buffer")

func AddRenderCam(cameraName, bufferName, camParams = null): #TODO
	var buf = GetBuffer(bufferName)
	var cam = Camera.new()
	cam.set_name(cameraName)
	buf["Viewport"].add_child(cam)
	
	var fov = _Get(camParams, "FOV", 70)
	cam.set_fov(fov)
	
	var cullMask = _Get(camParams, "CullMask", 0xFFFFF)
	cam.set_cull_mask(cullMask)
	
	var environment = _Get(camParams, "Environment", null)
	if(environment != null):
		cam.set_environment(environment)
	
	var camInfo = {
		"Camera":cam, "BufferName":bufferName,
		"FOV":fov, "CullMask":cullMask,
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
	var targetNode = p["BufferName"]
	if(targetNode == null):
		targetNode = self
	else:
		targetNode = _buffers[targetNode]["MaterialNode"]
		if(targetNode == null):
			print("OddLib Shaders : SetParameter : targetNode is null ("+str(parameterName)+", "+str(value)+")")
			return
	var mat = targetNode.get_material()
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

func MoveCameras(globalTransform):
	for cName in _cameras:
		_cameras[cName]["Camera"].set_global_transform(globalTransform)



# ------------------------------------------------------------------------------
# Refresh

signal OnRefreshOpportunity
signal OnForceRefresh
var _timeSinceLastRefresh = 0.0
var _timeSinceLastForceRefresh = 0.0
var _refreshOpportunityTargetTime = -1.0
var _refreshForceTargetTime = -1.0


func SetRefreshOpportunityFreq(newFreq = -1):
	if(newFreq <= 0.0):
		_refreshOpportunityTargetTime = -1.0
	_refreshOpportunityTargetTime = 1.0/newFreq
func SetForceRefreshFreq(newFreq = -1):
	if(newFreq <= 0.0):
		_refreshForceTargetTime = -1.0
	_refreshForceTargetTime = 1.0/newFreq

func RegisterModel(m):
	var e1 = connect("OnRefreshOpportunity", m, "OnRefreshOpportunity")
	var e2 = connect("OnForceRefresh", m, "OnForceRefresh")
	if(e1 || e2):
		print("OLSPipeline : Register model didn't manage to connect the signals.")

func RefreshOpportunity():
	OnRefreshOpportunity()
	emit_signal("OnRefreshOpportunity")

func OnRefreshOpportunity():
	pass
func OnForceRefresh():
	pass

func ForceRefresh():
	OnForceRefresh()
	emit_signal("OnForceRefresh")

func _RefreshProcess(delta):
	if(_refreshOpportunityTargetTime > 0 or _refreshForceTargetTime > 0):
		_timeSinceLastRefresh += delta
		_timeSinceLastForceRefresh += delta
	
	if(_refreshForceTargetTime > 0):
		if(_timeSinceLastForceRefresh >= _refreshForceTargetTime):
			_timeSinceLastRefresh = 0.0
			_timeSinceLastForceRefresh = 0.0
			ForceRefresh()
	
	if(_refreshOpportunityTargetTime > 0):
		if(_timeSinceLastRefresh >= _refreshOpportunityTargetTime):
			_timeSinceLastRefresh = 0.0
			RefreshOpportunity()

# --------------------------

var _buffers = {}
var _cameras = {}
var _params = {}

var _sizeChangedNodes = []


func _Get(dict, param, default):
	if(dict != null and dict.has(param)):
		return dict[param]
	return default

#func _init():
#	OddLib.Pipeline = self

func OnSizeChanged():
	var screenSize = get_tree().get_root().get_size()
	for n in _sizeChangedNodes:
		n.set_size(screenSize)

func _ready():
	var err = get_tree().get_root().connect("size_changed", self, "OnSizeChanged")
	if(err):
		print("OLSPipeline : Couldn't connect to OnSizeChanged.")
	set_stretch(true)
	
	Setup()
	
	OnSizeChanged()

func _process(delta):
	_RefreshProcess(delta)
