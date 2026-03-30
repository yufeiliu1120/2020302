extends Resource
class_name EventResourceData

# ==========================================
# 基础信息 (用于多语言和后台识别)
# ==========================================
## 事件的唯一英文 ID（例如 "sea_storm", "royal_tax"），方便程序内部查找
@export var event_id: String = "unnamed_event" 

@export_group("本地化文本 (Localization)")
## 事件名称的翻译键（例如 "event_sea_storm_name"）
@export var event_name: String = "EVENT_NAME_KEY" 
## 事件描述的翻译键（例如 "event_sea_storm_desc"）
@export_multiline var event_description: String = "EVENT_DESC_KEY" 

# ==========================================
# 美术资产 (Visuals)
# ==========================================
@export_group("美术素材 (Artworks)")
## 图一中显示的细长预览图 (尺寸: 128x24)
@export var preview_image: Texture2D 
## 图二中显示的完整插图 (尺寸: 128x72)
@export var full_image: Texture2D 

# ==========================================
# 核心逻辑 (Logic)
# ==========================================
@export_group("事件逻辑 (Effect)")
## 挂载具体惩罚逻辑的脚本。
## 未来我们会规定这个脚本里必须包含一个 execute_effect() 函数。
@export var effect_script: Script
