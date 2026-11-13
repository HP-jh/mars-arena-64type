extends RefCounted
class_name Personality64Types

## 64型人格原型定义
## 基于主导+辅助细分功能组合推导

# 引用16功能枚举
const F = preload("res://personality_64/cognitive_functions.gd").Function16

# 64型人格枚举（主导功能 x 4种辅助功能组合）
# 每种主导功能对应4种辅助功能，形成16x4=64种组合
enum Type64 {
	# Se主导型 (8种)
	SE_EXP_NE_DIV,    # Se探索 + Ne发散
	SE_EXP_NE_INT,    # Se探索 + Ne整合
	SE_EXP_NI_PRO,    # Se探索 + Ni预见
	SE_EXP_NI_SYN,    # Se探索 + Ni综合
	SE_ST_NE_DIV,     # Se稳定 + Ne发散
	SE_ST_NE_INT,     # Se稳定 + Ne整合
	SE_ST_NI_PRO,     # Se稳定 + Ni预见
	SE_ST_NI_SYN,     # Se稳定 + Ni综合
	
	# Si主导型 (8种)
	SI_REC_SE_EXP,    # Si回忆 + Se探索
	SI_REC_SE_ST,     # Si回忆 + Se稳定
	SI_REC_TE_EXE,    # Si回忆 + Te执行
	SI_REC_TE_EMP,    # Si回忆 + Te实证
	SI_HOM_SE_EXP,    # Si稳态 + Se探索
	SI_HOM_SE_ST,     # Si稳态 + Se稳定
	SI_HOM_TE_EXE,    # Si稳态 + Te执行
	SI_HOM_TE_EMP,    # Si稳态 + Te实证
	
	# Ne主导型 (8种)
	NE_DIV_SE_EXP,    # Ne发散 + Se探索
	NE_DIV_SE_ST,     # Ne发散 + Se稳定
	NE_DIV_SI_REC,    # Ne发散 + Si回忆
	NE_DIV_SI_HOM,    # Ne发散 + Si稳态
	NE_INT_SE_EXP,    # Ne整合 + Se探索
	NE_INT_SE_ST,     # Ne整合 + Se稳定
	NE_INT_SI_REC,    # Ne整合 + Si回忆
	NE_INT_SI_HOM,    # Ne整合 + Si稳态
	
	# Ni主导型 (8种)
	NI_PRO_SE_EXP,    # Ni预见 + Se探索
	NI_PRO_SE_ST,     # Ni预见 + Se稳定
	NI_PRO_SI_REC,    # Ni预见 + Si回忆
	NI_PRO_SI_HOM,    # Ni预见 + Si稳态
	NI_SYN_SE_EXP,    # Ni综合 + Se探索
	NI_SYN_SE_ST,     # Ni综合 + Se稳定
	NI_SYN_SI_REC,    # Ni综合 + Si回忆
	NI_SYN_SI_HOM,    # Ni综合 + Si稳态
	
	# Te主导型 (8种)
	TE_EXE_NE_DIV,    # Te执行 + Ne发散
	TE_EXE_NE_INT,    # Te执行 + Ne整合
	TE_EXE_NI_PRO,    # Te执行 + Ni预见
	TE_EXE_NI_SYN,    # Te执行 + Ni综合
	TE_EMP_NE_DIV,    # Te实证 + Ne发散
	TE_EMP_NE_INT,    # Te实证 + Ne整合
	TE_EMP_NI_PRO,    # Te实证 + Ni预见
	TE_EMP_NI_SYN,    # Te实证 + Ni综合
	
	# Ti主导型 (8种)
	TI_ANA_NE_DIV,    # Ti分析 + Ne发散
	TI_ANA_NE_INT,    # Ti分析 + Ne整合
	TI_ANA_NI_PRO,    # Ti分析 + Ni预见
	TI_ANA_NI_SYN,    # Ti分析 + Ni综合
	TI_PRE_NE_DIV,    # Ti精确 + Ne发散
	TI_PRE_NE_INT,    # Ti精确 + Ne整合
	TI_PRE_NI_PRO,    # Ti精确 + Ni预见
	TI_PRE_NI_SYN,    # Ti精确 + Ni综合
	
	# Fe主导型 (8种)
	FE_HAR_TE_EXE,    # Fe和谐 + Te执行
	FE_HAR_TE_EMP,    # Fe和谐 + Te实证
	FE_HAR_TI_ANA,    # Fe和谐 + Ti分析
	FE_HAR_TI_PRE,    # Fe和谐 + Ti精确
	FE_INF_TE_EXE,    # Fe影响 + Te执行
	FE_INF_TE_EMP,    # Fe影响 + Te实证
	FE_INF_TI_ANA,    # Fe影响 + Ti分析
	FE_INF_TI_PRE,    # Fe影响 + Ti精确
	
	# Fi主导型 (8种)
	FI_AUT_TE_EXE,    # Fi真实 + Te执行
	FI_AUT_TE_EMP,    # Fi真实 + Te实证
	FI_AUT_TI_ANA,    # Fi真实 + Ti分析
	FI_AUT_TI_PRE,    # Fi真实 + Ti精确
	FI_IND_TE_EXE,    # Fi个体 + Te执行
	FI_IND_TE_EMP,    # Fi个体 + Te实证
	FI_IND_TI_ANA,    # Fi个体 + Ti分析
	FI_IND_TI_PRE     # Fi个体 + Ti精确
}

# 人格类型代号
const TYPE_CODES := {
	Type64.SE_EXP_NE_DIV: "探险家",
	Type64.SE_EXP_NE_INT: "链接者",
	Type64.SE_EXP_NI_PRO: "先知",
	Type64.SE_EXP_NI_SYN: "洞察者",
	Type64.SE_ST_NE_DIV: "享乐家",
	Type64.SE_ST_NE_INT: "鉴赏家",
	Type64.SE_ST_NI_PRO: "守望者",
	Type64.SE_ST_NI_SYN: "守护者",
	
	Type64.SI_REC_SE_EXP: "记录者",
	Type64.SI_REC_SE_ST: "传承者",
	Type64.SI_REC_TE_EXE: "管理者",
	Type64.SI_REC_TE_EMP: "执行者",
	Type64.SI_HOM_SE_EXP: "实践者",
	Type64.SI_HOM_SE_ST: "稳定者",
	Type64.SI_HOM_TE_EXE: "组织者",
	Type64.SI_HOM_TE_EMP: "标准化师",
	
	Type64.NE_DIV_SE_EXP: "创新者",
	Type64.NE_DIV_SE_ST: "梦想家",
	Type64.NE_DIV_SI_REC: "联想者",
	Type64.NE_DIV_SI_HOM: "调和者",
	Type64.NE_INT_SE_EXP: "整合者",
	Type64.NE_INT_SE_ST: "桥梁者",
	Type64.NE_INT_SI_REC: "洞察整合者",
	Type64.NE_INT_SI_HOM: "系统思考者",
	
	Type64.NI_PRO_SE_EXP: "远见者",
	Type64.NI_PRO_SE_ST: "战略家",
	Type64.NI_PRO_SI_REC: "预言家",
	Type64.NI_PRO_SI_HOM: "规划者",
	Type64.NI_SYN_SE_EXP: "综合远见者",
	Type64.NI_SYN_SE_ST: "系统战略家",
	Type64.NI_SYN_SI_REC: "深度洞察者",
	Type64.NI_SYN_SI_HOM: "架构师",
	
	Type64.TE_EXE_NE_DIV: "指挥官",
	Type64.TE_EXE_NE_INT: "协调者",
	Type64.TE_EXE_NI_PRO: "决策者",
	Type64.TE_EXE_NI_SYN: "统帅",
	Type64.TE_EMP_NE_DIV: "优化者",
	Type64.TE_EMP_NE_INT: "系统工程师",
	Type64.TE_EMP_NI_PRO: "分析师",
	Type64.TE_EMP_NI_SYN: "架构工程师",
	
	Type64.TI_ANA_NE_DIV: "思考者",
	Type64.TI_ANA_NE_INT: "理论家",
	Type64.TI_ANA_NI_PRO: "哲学家",
	Type64.TI_ANA_NI_SYN: "逻辑学家",
	Type64.TI_PRE_NE_DIV: "精算师",
	Type64.TI_PRE_NE_INT: "概念工程师",
	Type64.TI_PRE_NI_PRO: "真理追求者",
	Type64.TI_PRE_NI_SYN: "系统分析家",
	
	Type64.FE_HAR_TE_EXE: "外交官",
	Type64.FE_HAR_TE_EMP: "调解者",
	Type64.FE_HAR_TI_ANA: "共情者",
	Type64.FE_HAR_TI_PRE: "咨询师",
	Type64.FE_INF_TE_EXE: "领导者",
	Type64.FE_INF_TE_EMP: "导师",
	Type64.FE_INF_TI_ANA: "启发者",
	Type64.FE_INF_TI_PRE: "精神领袖",
	
	Type64.FI_AUT_TE_EXE: "理想主义者",
	Type64.FI_AUT_TE_EMP: "价值实践者",
	Type64.FI_AUT_TI_ANA: "内省者",
	Type64.FI_AUT_TI_PRE: "道德家",
	Type64.FI_IND_TE_EXE: "自我实现者",
	Type64.FI_IND_TE_EMP: "个体实践者",
	Type64.FI_IND_TI_ANA: "探索者",
	Type64.FI_IND_TI_PRE: "身份追寻者"
}

# 人格类型关键词
const TYPE_KEYWORDS := {
	Type64.SE_EXP_NE_DIV: ["冒险", "创新", "即兴", "灵活"],
	Type64.SE_EXP_NE_INT: ["探索", "连接", "发现", "好奇"],
	Type64.SE_EXP_NI_PRO: ["行动", "远见", "直觉", "果断"],
	Type64.SE_EXP_NI_SYN: ["实践", "洞察", "整合", "执行"],
	Type64.SE_ST_NE_DIV: ["享受", "创意", "自由", "乐观"],
	Type64.SE_ST_NE_INT: ["品味", "审美", "联系", "感知"],
	Type64.SE_ST_NI_PRO: ["安稳", "预见", "谨慎", "准备"],
	Type64.SE_ST_NI_SYN: ["守护", "深层", "稳定", "洞察"],
	
	Type64.SI_REC_SE_EXP: ["记忆", "体验", "对比", "学习"],
	Type64.SI_REC_SE_ST: ["传统", "延续", "稳定", "可靠"],
	Type64.SI_REC_TE_EXE: ["经验", "管理", "效率", "秩序"],
	Type64.SI_REC_TE_EMP: ["数据", "标准", "流程", "验证"],
	Type64.SI_HOM_SE_EXP: ["实践", "稳定", "行动", "务实"],
	Type64.SI_HOM_SE_ST: ["保守", "安稳", " routine", "可靠"],
	Type64.SI_HOM_TE_EXE: ["组织", "秩序", "程序", "管理"],
	Type64.SI_HOM_TE_EMP: ["标准化", "流程", "规范", "系统"],
	
	Type64.NE_DIV_SE_EXP: ["创意", "探索", "可能", "发散"],
	Type64.NE_DIV_SE_ST: ["想象", "梦想", "可能", "乐观"],
	Type64.NE_DIV_SI_REC: ["联想", "创意", "记忆", "连接"],
	Type64.NE_DIV_SI_HOM: ["调和", "创新", "平衡", "整合"],
	Type64.NE_INT_SE_EXP: ["整合", "发现", "联系", "模式"],
	Type64.NE_INT_SE_ST: ["桥梁", "连接", "稳定", "洞察"],
	Type64.NE_INT_SI_REC: ["深度联想", "洞察", "整合", "理解"],
	Type64.NE_INT_SI_HOM: ["系统思维", "整合", "平衡", "架构"],
	
	Type64.NI_PRO_SE_EXP: ["远见", "行动", "战略", "果断"],
	Type64.NI_PRO_SE_ST: ["战略", "规划", "预见", "稳健"],
	Type64.NI_PRO_SI_REC: ["预言", "历史", "洞察", "深度"],
	Type64.NI_PRO_SI_HOM: ["规划", "系统", "远见", "秩序"],
	Type64.NI_SYN_SE_EXP: ["综合", "行动", "洞察", "执行"],
	Type64.NI_SYN_SE_ST: ["系统战略", "深度", "稳定", "架构"],
	Type64.NI_SYN_SI_REC: ["深度洞察", "整合", "历史", "理解"],
	Type64.NI_SYN_SI_HOM: ["架构", "系统", "深度", "整合"],
	
	Type64.TE_EXE_NE_DIV: ["指挥", "效率", "创新", "决断"],
	Type64.TE_EXE_NE_INT: ["协调", "系统", "效率", "整合"],
	Type64.TE_EXE_NI_PRO: ["决策", "战略", "执行", "远见"],
	Type64.TE_EXE_NI_SYN: ["统帅", "系统", "战略", "执行"],
	Type64.TE_EMP_NE_DIV: ["优化", "数据", "创新", "效率"],
	Type64.TE_EMP_NE_INT: ["系统工程", "优化", "整合", "数据"],
	Type64.TE_EMP_NI_PRO: ["分析", "数据", "战略", "系统"],
	Type64.TE_EMP_NI_SYN: ["架构工程", "系统", "数据", "深度"],
	
	Type64.TI_ANA_NE_DIV: ["思考", "逻辑", "创意", "分析"],
	Type64.TI_ANA_NE_INT: ["理论", "框架", "整合", "深度"],
	Type64.TI_ANA_NI_PRO: ["哲学", "洞察", "逻辑", "远见"],
	Type64.TI_ANA_NI_SYN: ["逻辑学", "系统", "深度", "整合"],
	Type64.TI_PRE_NE_DIV: ["精算", "逻辑", "创意", "精确"],
	Type64.TI_PRE_NE_INT: ["概念工程", "精确", "整合", "系统"],
	Type64.TI_PRE_NI_PRO: ["真理", "深度", "逻辑", "洞察"],
	Type64.TI_PRE_NI_SYN: ["系统分析", "精确", "深度", "整合"],
	
	Type64.FE_HAR_TE_EXE: ["外交", "和谐", "效率", "领导"],
	Type64.FE_HAR_TE_EMP: ["调解", "和谐", "系统", "共情"],
	Type64.FE_HAR_TI_ANA: ["共情", "理解", "逻辑", "和谐"],
	Type64.FE_HAR_TI_PRE: ["咨询", "共情", "精确", "指导"],
	Type64.FE_INF_TE_EXE: ["领导", "影响", "效率", "魅力"],
	Type64.FE_INF_TE_EMP: ["导师", "引导", "系统", "启发"],
	Type64.FE_INF_TI_ANA: ["启发", "影响", "深度", "智慧"],
	Type64.FE_INF_TI_PRE: ["精神领袖", "价值观", "影响", "深度"],
	
	Type64.FI_AUT_TE_EXE: ["理想", "价值", "执行", "真实"],
	Type64.FI_AUT_TE_EMP: ["价值实践", "真实", "系统", "坚持"],
	Type64.FI_AUT_TI_ANA: ["内省", "价值", "逻辑", "深度"],
	Type64.FI_AUT_TI_PRE: ["道德", "价值", "精确", "坚持"],
	Type64.FI_IND_TE_EXE: ["自我实现", "个体", "执行", "独立"],
	Type64.FI_IND_TE_EMP: ["个体实践", "独立", "系统", "探索"],
	Type64.FI_IND_TI_ANA: ["探索", "自我", "深度", "理解"],
	Type64.FI_IND_TI_PRE: ["身份追寻", "个体", "深度", "真实"]
}

static func get_type_code(type_id: int) -> String:
	return TYPE_CODES.get(type_id, "未知类型")

static func get_type_keywords(type_id: int) -> Array:
	return TYPE_KEYWORDS.get(type_id, ["未知"])
