extends RefCounted
class_name CognitiveFunctions

## 荣格斯二代 16细分认知功能定义
## 基于荣格原始8个认知功能，每个分化为2个子形态

# 16细分认知功能枚举
enum Function16 {
	# 感觉功能 (Se) 分化
	SE_EXPLORATORY,      # Se-探索型：主动探索环境，寻求感官刺激
	SE_STABILIZING,      # Se-稳定型：维持现状，享受当下感官体验
	
	# 内倾感觉 (Si) 分化
	SI_RECOLLECTIVE,     # Si-回忆型：调取过去经验，对比历史数据
	SI_HOMEOSTATIC,      # Si-稳态型：维护内部稳定，遵循既定程序
	
	# 外倾直觉 (Ne) 分化
	NE_DIVERGENT,        # Ne-发散型：头脑风暴，多方向可能性探索
	NE_INTEGRATIVE,      # Ne-整合型：连接看似无关的概念，发现隐藏联系
	
	# 内倾直觉 (Ni) 分化
	NI_PROPHETIC,        # Ni-预见型：预见未来趋势，洞察本质
	NI_SYNTHESIZING,     # Ni-综合型：整合复杂信息，形成统一愿景
	
	# 外倾思考 (Te) 分化
	TE_EXECUTIVE,        # Te-执行型：组织资源，追求效率，建立秩序
	TE_EMPIRICAL,        # Te-实证型：依赖数据验证，标准化流程
	
	# 内倾思考 (Ti) 分化
	TI_ANALYTICAL,       # Ti-分析型：逻辑推理，构建内部框架
	TI_PRECISION,        # Ti-精确型：追求概念精确，消除逻辑矛盾
	
	# 外倾情感 (Fe) 分化
	FE_HARMONIZING,      # Fe-和谐型：维护群体和谐，照顾他人情感
	FE_INFLUENCING,      # Fe-影响型：引导群体情感，塑造氛围
	
	# 内倾情感 (Fi) 分化
	FI_AUTHENTICATING,   # Fi-真实型：追求内在真实，坚守个人价值观
	FI_INDIVIDUATING     # Fi-个体型：探索自我身份，深化情感体验
}

# 功能名称映射
const FUNCTION_NAMES := {
	Function16.SE_EXPLORATORY: "Se-探索",
	Function16.SE_STABILIZING: "Se-稳定",
	Function16.SI_RECOLLECTIVE: "Si-回忆",
	Function16.SI_HOMEOSTATIC: "Si-稳态",
	Function16.NE_DIVERGENT: "Ne-发散",
	Function16.NE_INTEGRATIVE: "Ne-整合",
	Function16.NI_PROPHETIC: "Ni-预见",
	Function16.NI_SYNTHESIZING: "Ni-综合",
	Function16.TE_EXECUTIVE: "Te-执行",
	Function16.TE_EMPIRICAL: "Te-实证",
	Function16.TI_ANALYTICAL: "Ti-分析",
	Function16.TI_PRECISION: "Ti-精确",
	Function16.FE_HARMONIZING: "Fe-和谐",
	Function16.FE_INFLUENCING: "Fe-影响",
	Function16.FI_AUTHENTICATING: "Fi-真实",
	Function16.FI_INDIVIDUATING: "Fi-个体"
}

# 功能分组（按原始8维）
const FUNCTION_GROUPS := {
	"Se": [Function16.SE_EXPLORATORY, Function16.SE_STABILIZING],
	"Si": [Function16.SI_RECOLLECTIVE, Function16.SI_HOMEOSTATIC],
	"Ne": [Function16.NE_DIVERGENT, Function16.NE_INTEGRATIVE],
	"Ni": [Function16.NI_PROPHETIC, Function16.NI_SYNTHESIZING],
	"Te": [Function16.TE_EXECUTIVE, Function16.TE_EMPIRICAL],
	"Ti": [Function16.TI_ANALYTICAL, Function16.TI_PRECISION],
	"Fe": [Function16.FE_HARMONIZING, Function16.FE_INFLUENCING],
	"Fi": [Function16.FI_AUTHENTICATING, Function16.FI_INDIVIDUATING]
}

# 功能描述
const FUNCTION_DESCRIPTIONS := {
	Function16.SE_EXPLORATORY: "主动探索环境，寻求新奇的感官体验，喜欢冒险和即时行动",
	Function16.SE_STABILIZING: "享受当下的感官体验，倾向于维持熟悉的环境和节奏",
	Function16.SI_RECOLLECTIVE: "调取过去经验和记忆，通过对比历史数据来指导当前决策",
	Function16.SI_HOMEOSTATIC: "维护内部稳定和秩序，遵循既定程序和传统方法",
	Function16.NE_DIVERGENT: "头脑风暴式思维，探索多种可能性，喜欢发散性思考",
	Function16.NE_INTEGRATIVE: "连接看似无关的概念，发现隐藏的联系和模式",
	Function16.NI_PROPHETIC: "预见未来趋势和结果，洞察事物本质，形成远见",
	Function16.NI_SYNTHESIZING: "整合复杂信息为统一愿景，形成深层洞察",
	Function16.TE_EXECUTIVE: "组织资源追求效率，建立秩序和标准，注重执行力",
	Function16.TE_EMPIRICAL: "依赖数据和实证验证，建立标准化流程和系统",
	Function16.TI_ANALYTICAL: "逻辑推理和分析，构建内部概念框架，追求理解",
	Function16.TI_PRECISION: "追求概念精确和逻辑一致，消除矛盾和模糊",
	Function16.FE_HARMONIZING: "维护群体和谐，照顾他人情感需求，促进团结",
	Function16.FE_INFLUENCING: "引导和影响群体情感，塑造氛围和价值观",
	Function16.FI_AUTHENTICATING: "追求内在真实，坚守个人价值观和道德准则",
	Function16.FI_INDIVIDUATING: "探索自我身份，深化个人情感体验和意义"
}

static func get_function_name(func_id: int) -> String:
	return FUNCTION_NAMES.get(func_id, "未知功能")

static func get_function_description(func_id: int) -> String:
	return FUNCTION_DESCRIPTIONS.get(func_id, "")

static func get_all_functions() -> Array:
	return FUNCTION_NAMES.keys()
