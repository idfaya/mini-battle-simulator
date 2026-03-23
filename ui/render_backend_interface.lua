---
--- 渲染后端抽象接口
--- 定义所有渲染后端必须实现的接口
--- 支持多种渲染后端：Console、Web、Unity、GUI等
---

---@class RenderBackendInterface
local RenderBackendInterface = {}

-- ==================== 渲染上下文 ====================

---@class RenderContext
---@field width number 渲染区域宽度
---@field height number 渲染区域高度
---@field backend string 后端类型标识
---@field config table 后端配置

-- ==================== 生命周期接口 ====================

--- 初始化渲染后端
---@param config table 配置参数
---@return boolean 是否初始化成功
function RenderBackendInterface:Init(config)
    error("RenderBackendInterface:Init must be implemented by subclass")
end

--- 清理渲染后端资源
function RenderBackendInterface:Shutdown()
    error("RenderBackendInterface:Shutdown must be implemented by subclass")
end

--- 开始一帧渲染
function RenderBackendInterface:BeginFrame()
    error("RenderBackendInterface:BeginFrame must be implemented by subclass")
end

--- 结束一帧渲染并呈现
function RenderBackendInterface:EndFrame()
    error("RenderBackendInterface:EndFrame must be implemented by subclass")
end

-- ==================== 基础绘制接口 ====================

--- 清屏/清除画布
function RenderBackendInterface:Clear()
    error("RenderBackendInterface:Clear must be implemented by subclass")
end

--- 设置绘制颜色
---@param color table {r, g, b, a} 或字符串颜色名
function RenderBackendInterface:SetColor(color)
    error("RenderBackendInterface:SetColor must be implemented by subclass")
end

--- 重置绘制颜色为默认
function RenderBackendInterface:ResetColor()
    error("RenderBackendInterface:ResetColor must be implemented by subclass")
end

--- 设置字体样式
---@param font table {name, size, bold, italic}
function RenderBackendInterface:SetFont(font)
    -- 可选实现，不是所有后端都支持
end

-- ==================== 文本渲染接口 ====================

--- 在指定位置绘制文本
---@param x number X坐标
---@param y number Y坐标
---@param text string 文本内容
---@param align string 对齐方式 "left"|"center"|"right"
function RenderBackendInterface:DrawText(x, y, text, align)
    align = align or "left"
    error("RenderBackendInterface:DrawText must be implemented by subclass")
end

--- 测量文本尺寸
---@param text string 文本内容
---@return number width 文本宽度
---@return number height 文本高度
function RenderBackendInterface:MeasureText(text)
    error("RenderBackendInterface:MeasureText must be implemented by subclass")
end

--- 绘制富文本（带颜色/样式的文本）
---@param x number X坐标
---@param y number Y坐标
---@param richText table 富文本片段数组 {text, color, style}
function RenderBackendInterface:DrawRichText(x, y, richText)
    -- 默认实现：逐个绘制文本片段
    local currentX = x
    for _, segment in ipairs(richText) do
        if segment.color then
            self:SetColor(segment.color)
        end
        self:DrawText(currentX, y, segment.text)
        local w, _ = self:MeasureText(segment.text)
        currentX = currentX + w
        if segment.color then
            self:ResetColor()
        end
    end
end

-- ==================== 图形绘制接口 ====================

--- 绘制矩形边框
---@param x number X坐标
---@param y number Y坐标
---@param width number 宽度
---@param height number 高度
---@param style string 样式 "single"|"double"|"thick"
function RenderBackendInterface:DrawRect(x, y, width, height, style)
    style = style or "single"
    error("RenderBackendInterface:DrawRect must be implemented by subclass")
end

--- 绘制填充矩形
---@param x number X坐标
---@param y number Y坐标
---@param width number 宽度
---@param height number 高度
function RenderBackendInterface:FillRect(x, y, width, height)
    error("RenderBackendInterface:FillRect must be implemented by subclass")
end

--- 绘制水平线
---@param x number 起始X
---@param y number Y坐标
---@param width number 长度
---@param char string 使用的字符（Console后端）
function RenderBackendInterface:DrawHorizontalLine(x, y, width, char)
    error("RenderBackendInterface:DrawHorizontalLine must be implemented by subclass")
end

--- 绘制垂直线
---@param x number X坐标
---@param y number 起始Y
---@param height number 长度
---@param char string 使用的字符（Console后端）
function RenderBackendInterface:DrawVerticalLine(x, y, height, char)
    error("RenderBackendInterface:DrawVerticalLine must be implemented by subclass")
end

--- 绘制进度条
---@param x number X坐标
---@param y number Y坐标
---@param width number 宽度
---@param progress number 进度 0-1
---@param filledColor table 填充颜色
---@param emptyColor table 空槽颜色
function RenderBackendInterface:DrawProgressBar(x, y, width, progress, filledColor, emptyColor)
    error("RenderBackendInterface:DrawProgressBar must be implemented by subclass")
end

-- ==================== 图像/精灵接口（可选）====================

--- 绘制图像
---@param x number X坐标
---@param y number Y坐标
---@param imageId string 图像标识
---@param width number 目标宽度（可选）
---@param height number 目标高度（可选）
function RenderBackendInterface:DrawImage(x, y, imageId, width, height)
    -- 可选实现，Console后端可能不支持
end

--- 绘制精灵/图标
---@param x number X坐标
---@param y number Y坐标
---@param spriteId string 精灵标识
---@param color table 着色（可选）
function RenderBackendInterface:DrawSprite(x, y, spriteId, color)
    -- 可选实现
end

-- ==================== 高级功能接口 ====================

--- 设置裁剪区域
---@param x number X坐标
---@param y number Y坐标
---@param width number 宽度
---@param height number 高度
function RenderBackendInterface:SetClipRect(x, y, width, height)
    -- 可选实现
end

--- 清除裁剪区域
function RenderBackendInterface:ClearClipRect()
    -- 可选实现
end

--- 设置透明度
---@param alpha number 透明度 0-1
function RenderBackendInterface:SetAlpha(alpha)
    -- 可选实现
end

--- 执行动画（如果后端支持）
---@param animation table 动画定义
---@param onComplete function 完成回调
function RenderBackendInterface:PlayAnimation(animation, onComplete)
    --